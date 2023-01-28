`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:20:29 12/01/2022 
// Design Name: 
// Module Name:    CPU 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`include "macro.v"

module CPU(
	input clk,
	input reset,
	input respon,
	
	output [31:0] inst_sram_addr,		
	input [31:0] inst_sram_rdata,		

	output data_sram_en,		
	output [3:0] data_sram_wen,			
	output [31:0] data_sram_addr,
	output [31:0] data_sram_wdata,
	input [31:0] data_sram_rdata,		 
	
	output [31:0] debug_wb_pc,
	output [3:0] debug_wb_rf_wen,
	output [4:0] debug_wb_rf_wnum,
	output [31:0] debug_wb_rf_wdata,
	
	output EXL,
	output [4:0] ExcCodeOut,
	output BD,
	output [31:0] EPC,
	output [31:0] VAddr,
	output back,
	input [31:0] backPC,
	output [4:0] CP0Addr,
	input [31:0] CP0RD,
	output [31:0] CP0WD,
	output CP0We
);

	wire stopF, stopD;
/******             F               ******/
	wire [4:0] ExcCodeF, ExcCodeD, ExcCodeE, ExcCodeM;
	wire EXLF, EXLD, EXLE, EXLM;
	wire BDD, BDE, BDM;
	reg [31:0] pc, r_pc;   
	reg [4:0] r_ExcCode;
	reg r_sel, r_BD;
	wire [31:0] instr, realRd1, realRd2, signExt;
	wire eq, greater_eq_zero, greater_zero;
	wire branch, nbranch, gez_br, gz_br, lez_br, lz_br, jump, linkD, Return, backD;
	always@(posedge clk) begin
		if(reset) begin
			pc <= 32'hBFC00000;
		end
		else if(respon) begin
			pc <= 32'hBFC00380;
		end
		else if(stopF) begin
			pc <= pc;
		end
		else begin
			if(backD == 1) begin
				pc <= backPC + 4;
			end
			else if(jump == 1) begin
				pc <= {pc[31:28], DInst[25:0], 2'b00};
			end
			else if((branch == 1 && eq == 1) || (eq == 0 && nbranch == 1)) begin
				pc <= pc + (signExt << 2);
			end
			else if((gez_br == 1 && greater_eq_zero == 1) || (greater_eq_zero == 0 && lz_br == 1)) begin
				pc <= pc + (signExt << 2);
			end
			else if((gz_br == 1 && greater_zero == 1) || (greater_zero == 0 && lez_br == 1)) begin
				pc <= pc + (signExt << 2);
			end
			// else if(linkD == 1) begin
			// 	pc <= {pc[31:28], DInst[25:0], 2'b00};
			// end
			else if(Return == 1) begin
				pc <= realRd1;
			end
			else begin
				pc <= pc + 4;
			end
		end
	end
	
	// 在CPU内进行虚拟地址到物理地址的转换，inst_sram_addr传出物理地址
	assign inst_sram_addr = (backD == 1) ? 
							((backPC >= 32'h80000000 && backPC <= 32'h9FFFFFFF) ? (backPC - 32'h80000000) : (backPC - 32'hA0000000)) :
							((pc >= 32'h80000000 && pc <= 32'h9FFFFFFF) ? (pc - 32'h80000000) : (pc - 32'hA0000000)) ;
	assign EXLF = (inst_sram_addr[1:0] != 0) ? 1 : 0; 	// 本质上，这里判断虚拟地址有效性，用物理地址做等价判断
	assign ExcCodeF = (EXLF) ? 5'b00100 : 0;
	
/*****              D reg                 ******/
	always@(posedge clk) begin
		if(reset == 1) begin
			r_pc <= 0;
			r_sel <= 0;
			r_ExcCode <= 0;
			r_BD <= 0;
		end
		else if(respon == 1) begin
			r_pc <= 0;
			r_sel <= 0;
			r_ExcCode <= 0;
			r_BD <= 0;
		end
		else if(stopD == 1) begin
			r_pc <= r_pc;
			r_sel <= r_sel;
			r_ExcCode <= r_ExcCode;
			r_BD <= r_BD;
		end
		else begin
			r_pc <= (backD == 1) ? backPC : pc; //这里在cpu里继续传递的pc是虚拟地址
			r_sel <= EXLF;
			r_ExcCode <= ExcCodeF;
			if(branch | nbranch | jump | Return | gez_br | gz_br | lez_br | lz_br) begin
				r_BD <= 1;
			end
			else r_BD <= 0;
		end
	end
	
	
/******               D                   ******/
	wire [5:0] op, func;
	wire RegWriteD, MemWriteD, MemOrALUD, IorRD, RorSaD;
	wire [3:0] beqRAW1, beqRAW2;
	wire [1:0] Ext, A3From, MemInSelD;
	wire [2:0] MemOutSelD;
	wire overJudgeD;			// ALU是否需要判断溢出，1则需要
	wire [3:0] ALUopD;
	wire [15:0] imm;
	wire [31:0] ZeroExt, atHigh, linkAddrD, ID, pcD, rd1D, rd2D;
	wire [4:0] rs, rt, rd, sa, A3D;
	wire startD, immWriteD, HIWriteD, HLToRegD, HIReadD;
	wire [1:0] MDopD;
	wire MDsignD;
	wire [31:0] HLE, HLM;
	wire CP0WeD, CP0ToRegD, undefine, call, breakPoint;
	
	reg [31:0] keepInst;
	reg keepStopD, keepRespon, keepReset;
	wire [31:0] normalInst, preInst, DInst;
	
	assign normalInst = inst_sram_rdata;									// 不考虑reset, respon, stopD下读出的指令
	always@(posedge clk) begin												// 保存上一个周期
		keepInst <= DInst;													// 的指令
		keepStopD <= stopD;													// 与控制信号
		keepRespon <= respon;												// 以决定本周期应该运行什么指令
		keepReset <= reset;
	end
	
	assign preInst = (keepStopD == 1) ? keepInst : normalInst;
	assign DInst = (keepRespon == 1 || keepReset == 1) ? 0 : preInst; 		// 最终需要解码即CPU上将运行的指令机器码
	
	assign imm = DInst[15:0];
	assign rs = DInst[25:21];
	assign rt = DInst[20:16];
	assign rd = DInst[15:11];
	assign sa = DInst[10: 6];
	assign op = DInst[31:26];
	assign func = DInst[5:0];
	assign BDD = r_BD;
	assign signExt = {{16{imm[15]}},imm};
	assign ZeroExt = {16'h0000, imm};
	assign atHigh = {imm, 16'h0000};
	assign linkAddrD = pc + 4;												// 延迟槽中指令pc + 4，也就是延迟槽指令的下一条
	assign A3D = 	(A3From == 2'b00) ? rt :
					(A3From == 2'b01) ? rd : 
					(A3From == 2'b10) ? 5'h1f : 0;
	controller Ctrl(
					.op(op),
					.func(func),
					.rs(rs),
					.rt(rt),
					.rd(rd),
					.RegWrite(RegWriteD),
					.MemWrite(MemWriteD),
					.MemOrALU(MemOrALUD),
					.IorR(IorRD),
					.RorSa(RorSaD),
					.branch(branch),
					.nbranch(nbranch),
					.gez_br(gez_br),
					.gz_br(gz_br),
					.lez_br(lez_br),
					.lz_br(lz_br),
					.jump(jump),
					.link(linkD),
					.Return(Return),
					.ALUop(ALUopD),
					.overJudge(overJudgeD),
					.Ext(Ext),
					.A3From(A3From),
					.MemOutSel(MemOutSelD),
					.MemInSel(MemInSelD),
					.start(startD),
					.immWrite(immWriteD),
					.HIWrite(HIWriteD),
					.MDop(MDopD),
					.MDsign(MDsignD),
					.HLToReg(HLToRegD),
					.HIRead(HIReadD),
					.CP0We(CP0WeD),
					.CP0ToReg(CP0ToRegD),
					.undefine(undefine),
					.call(call),
					.breakPoint(breakPoint),
					.back(backD)
					);
	
	assign EXLD = (r_sel == 1) ? 1 :
					(call | breakPoint | undefine) ? 1 : 0;
	assign ExcCodeD = (r_sel == 1) ? r_ExcCode : 
						(call == 1) ? 5'b01000 : 
						(breakPoint == 1) ? 5'b01001 :
						(undefine == 1) ? 5'b01010 : 0;
	
	wire [31:0] pcW, wdW, CP0OutM, CP0OutW;
	wire RegWriteW;
	wire [4:0] A3W;
	GRF grf(
			  .clk(clk),
			  .reset(reset),
			  .RegWrite(RegWriteW),
			  .RegAddr1(rs),
			  .RegAddr2(rt),
			  .RegAddr3(A3W),
			  .wd(wdW),
			  .RegData1(rd1D),
			  .RegData2(rd2D)
			 );
	assign pcD = r_pc;
	assign ID = (Ext == 2'b00) ? ZeroExt :
				(Ext == 2'b01) ? atHigh  :
				(Ext == 2'b10) ? signExt : 0;
	//wire [31:0] realRd1, realRd2; 锟斤拷F锟斤拷锟斤拷锟斤拷
	wire [31:0] ALUoutM, linkAddrM;
	assign realRd1 = (beqRAW1 == `none) ? rd1D :
						  (beqRAW1 == `ALUM_rdD) ? ALUoutM:
						  (beqRAW1 == `LAddrM_rdD) ? linkAddrM:
						  (beqRAW1 == `HLE_rdD) ? HLE:
						  (beqRAW1 == `HLM_rdD) ? HLM: 
						  (beqRAW1 == `CP0M_rdD) ? CP0OutM : 0;
	assign realRd2 = (beqRAW2 == `none) ? rd2D :
						  (beqRAW2 == `ALUM_rdD) ? ALUoutM:
						  (beqRAW2 == `LAddrM_rdD) ? linkAddrM:
						  (beqRAW2 == `HLE_rdD) ? HLE:
						  (beqRAW2 == `HLM_rdD) ? HLM: 
						  (beqRAW2 == `CP0M_rdD) ? CP0OutM : 0;
	assign eq = (realRd1 == realRd2) ? 1 : 0;
	assign greater_eq_zero = (realRd1[31] == 0) ? 1 : 0;
	assign greater_zero = (realRd1[31] == 0 && realRd1 > 0) ? 1 : 0; 
	
/******                 E reg                    ******/
	wire linkE, RegWriteE, MemWriteE, preMemWriteE, MemOrALUE, IorRE, RorSaE;
	wire flushE;
	wire [3:0] ALUopE;
	wire overJudgeE;
	wire [2:0] MemOutSelE;
	wire [1:0] MemInSelE;
	wire [31:0] linkAddrE, IE, rd1E, rd2E, pcE;
	wire [4:0] A1E, A2E, A3E, saE;
	wire startE, immWriteE, HIWriteE, HLToRegE, HIReadE;
	wire [1:0] MDopE;
	wire MDsignE;
	wire busy, in_ready;
	wire selE;
	wire [4:0] defaultExcCodeE;
	wire CP0WeE, CP0WeM, CP0ToRegE, backE;
	wire [4:0] rdE, rdM;
	
	E eReg(
			.clk(clk),
			.flush(flushE),
			.respon(respon),
			.linkD(linkD),
			.RegWriteD(RegWriteD),
			.MemWriteD(MemWriteD),
			.MemOrALUD(MemOrALUD),
			.IorRD(IorRD),
			.RorSaD(RorSaD),
			.MemOutSelD(MemOutSelD),
			.MemInSelD(MemInSelD),
			.ALUopD(ALUopD),
			.overJudgeD(overJudgeD),
			.linkAddrD(linkAddrD),
			.ID(ID),
			.rd1D(rd1D),
			.rd2D(rd2D),
			.pcD(pcD),
			.A1D(rs),
			.A2D(rt),
			.rdD(rd),
			.saD(sa),
			.A3D(A3D),
			.startD(startD),
			.immWriteD(immWriteD),
			.HIWriteD(HIWriteD),
			.HLToRegD(HLToRegD),
			.HIReadD(HIReadD),
			.MDopD(MDopD),
			.MDsignD(MDsignD),
			.EXLD(EXLD),
			.ExcCodeD(ExcCodeD),
			.BDD(BDD),
			.CP0WeD(CP0WeD),
			.CP0ToRegD(CP0ToRegD),
			.backD(backD),
			.linkE(linkE),
			.RegWriteE(RegWriteE),
			.MemWriteE(preMemWriteE),
			.MemOrALUE(MemOrALUE),
			.IorRE(IorRE),
			.RorSaE(RorSaE),
			.MemOutSelE(MemOutSelE),
			.MemInSelE(MemInSelE),
			.ALUopE(ALUopE),
			.overJudgeE(overJudgeE),
			.linkAddrE(linkAddrE),
			.IE(IE),
			.rd1E(rd1E),
			.rd2E(rd2E),
			.pcE(pcE),
			.A1E(A1E),
			.A2E(A2E),
			.rdE(rdE),
			.saE(saE),
			.A3E(A3E),
			.startE(startE),
			.immWriteE(immWriteE),
			.HIWriteE(HIWriteE),
			.HLToRegE(HLToRegE),
			.HIReadE(HIReadE),
			.MDopE(MDopE),
			.MDsignE(MDsignE),
			.selE(selE),
			.defaultExcCodeE(defaultExcCodeE),
			.BDE(BDE),
			.CP0WeE(CP0WeE),
			.CP0ToRegE(CP0ToRegE),
			.backE(backE)
		);
		  
		  
/******                   conflict                    ******/
	wire MemToRegE, MemToRegM;
	wire [3:0] ALURAW1, ALURAW2;
	wire linkM, RegWriteM, MemWriteM, MemOrALUM, HLToRegM, CP0ToRegM;
	wire [4:0] A3M;
	
	conflict cft(
					 .A1D(rs),
					 .A2D(rt),
					 .A1E(A1E),
					 .A2E(A2E),
					 .A3E(A3E),
					 .A3M(A3M),
					 .A3W(A3W),
					 .rdE(rdE),
					 .rdM(rdM),
					 .MemWriteD(MemWriteD),
					 .RegWriteE(RegWriteE),
					 .RegWriteM(RegWriteM),
					 .MemToRegE(MemToRegE),
					 .MemToRegM(MemToRegM),
					 .RegWriteW(RegWriteW),
					 .linkM(linkM),
					 .branchD(branch),
					 .nbranchD(nbranch),
					 .gez_br(gez_br),
					 .gz_br(gz_br),
					 .lez_br(lez_br),
					 .lz_br(lz_br),
					 .Return(Return),
					 .backD(backD),
					 .HLToRegD(HLToRegD),
					 .HLToRegE(HLToRegE),
					 .HLToRegM(HLToRegM),
					 .CP0ToRegM(CP0ToRegM),
					 .CP0WeE(CP0WeE),
					 .CP0WeM(CP0WeM),
					 .busy(busy),
					 .startE(startE),
					 .startD(startD),
					 .immWriteD(immWriteD),
					 .ALURAW1(ALURAW1),
					 .ALURAW2(ALURAW2),
					 .beqRAW1(beqRAW1),
					 .beqRAW2(beqRAW2),
					 .stopF(stopF),
					 .stopD(stopD),
					 .flushE(flushE)
					);
					
					
/******                    E                  ******/
	wire [31:0] RtoA, A, RtoB, B, ALUoutE, LOE, HIE;
	wire over;
	
	assign RtoA = (ALURAW1 == `none) ? rd1E :
				  (ALURAW1 == `ALUM_ALUAB) ? ALUoutM :
				  (ALURAW1 == `wdW_ALUAB) ? wdW :
				  (ALURAW1 == `LAddrM_ALUAB) ? linkAddrM :
				  (ALURAW1 == `HLM_ALUAB) ? HLM : 
				  (ALURAW1 == `CP0M_ALUAB) ? CP0OutM : 0;
	assign A = (RorSaE == 0) ? RtoA : {27'b0, saE};

	assign RtoB = (ALURAW2 == `none) ? rd2E :
				  (ALURAW2 == `ALUM_ALUAB) ? ALUoutM :
				  (ALURAW2 == `wdW_ALUAB) ? wdW :
				  (ALURAW2 == `LAddrM_ALUAB) ? linkAddrM :
				  (ALURAW2 == `HLM_ALUAB) ? HLM : 
				  (ALURAW2 == `CP0M_ALUAB) ? CP0OutM : 0;
	assign B = (IorRE == 0) ? IE : RtoB;
	
	ALU alu(
			  .A(A),
			  .B(B),
			  .ALUop(ALUopE),
			  .overJudge(overJudgeE),
			  .out(ALUoutE),
			  .over(over)
			 );
			 
	/*MD md(
			.clk(clk),
			.reset(reset),
			.operand1(A),
			.operand2(B),
			.op(MDopE),
			.immWrite(immWriteE),
			.HIWrite(HIWriteE),
			.start(startE),
			.respon(respon),
			.busy(busy),
			.LO(LOE),
			.HI(HIE)
			);*/
	wire in_valid, out_valid;
	wire [31:0] out_res0, out_res1;
	reg [31:0] HI, LO;
	wire out_ready = 1;
	assign in_valid = (startE && ~respon);
	MulDivUnit MulDivUnit(
		 .clk(clk),
		 .reset(reset),
		 .in_src0(A),
		 .in_src1(B),
		 .in_op(MDopE),
		 .in_sign(MDsignE),
		 .in_ready(in_ready),
		 .in_valid(in_valid),
		 .out_ready(out_ready),
		 .out_valid(out_valid),
		 .out_res0(out_res0),  //LO
		 .out_res1(out_res1)	  //HI
	);
	assign busy = ~in_ready;
	
	/****   HI,LO 锟斤拷锟斤拷锟斤拷  ****/
	always@(posedge clk) begin
		if(out_valid) begin
			HI <= out_res1;
			LO <= out_res0;
		end
		else if(immWriteE && ~respon) begin
			if(HIWriteE) begin
				HI <= A;  //operand1, rs
				LO <= LO;
			end
			else begin
				HI <= HI;
				LO <= A;
			end
		end
		else begin
			HI <= HI;
			LO <= LO;
		end
	end
	
	assign HIE = HI;
	assign LOE = LO;
	assign HLE = (HIReadE == 1) ? HIE : LOE;
	assign MemToRegE = (RegWriteE == 1 && MemOrALUE == 0 && linkE == 0 && CP0ToRegE == 0 && HLToRegE == 0) ? 1: 0; 
	wire outOfDiv, AdEL, AdES;
	assign outOfDiv = ~((ALUoutE >= 0 && ALUoutE <= 32'h2fff) || (ALUoutE >= 32'h7f00 && ALUoutE <= 32'h7f0b) || (ALUoutE >= 32'h7f10 && ALUoutE <= 32'h7f1b) || (ALUoutE >= 32'h7f20 && ALUoutE <= 32'h7f23));
	assign AdEL = 	(MemToRegE == 1 && MemOutSelE == `MemOut_fullWord && ALUoutE[1:0] != 2'b00) ? 1 :
					(MemToRegE == 1 && (MemOutSelE == `MemOut_half_signExt || MemOutSelE == `MemOut_half_zeroExt) && ALUoutE[0] != 0) ? 1 : 0;
					// (MemToRegE == 1 && (MemOutSelE == `quatWord || MemOutSelE == `halfWord) && ALUoutE >= 32'h00007f00 && ALUoutE <= 32'h00007f0b) ? 1 :
					// (MemToRegE == 1 && (MemOutSelE == `quatWord || MemOutSelE == `halfWord) && ALUoutE >= 32'h00007f10 && ALUoutE <= 32'h00007f1b) ? 1 : 
					// (MemToRegE == 1 && over == 1) ? 1 :
					// (MemToRegE == 1 && outOfDiv == 1) ? 1 : 0;
					  
	assign AdES = 	(preMemWriteE == 1 && MemInSelE == `fullWord && ALUoutE[1:0] != 2'b00) ? 1 :
					(preMemWriteE == 1 && MemInSelE == `halfWord && ALUoutE[0] != 0) ? 1 : 0;
					// (preMemWriteE == 1 && (MemInSelE == `quatWord || MemInSelE == `halfWord) && ALUoutE >= 32'h00007f00 && ALUoutE <= 32'h00007f0b) ? 1 :
					// (preMemWriteE == 1 && (MemInSelE == `quatWord || MemInSelE == `halfWord) && ALUoutE >= 32'h00007f10 && ALUoutE <= 32'h00007f1b) ? 1 :
					// (preMemWriteE == 1 && over == 1) ? 1 :
					// (preMemWriteE == 1 && ((ALUoutE >= 32'h7f08 && ALUoutE <= 32'h7f0b) || (ALUoutE >= 32'h7f18 && ALUoutE <= 32'h7f1b))) ? 1 :
					// (preMemWriteE == 1 && outOfDiv == 1) ? 1 : 0;
	assign MemWriteE = (EXLE == 0 && preMemWriteE == 1) ? 1 : 0;
	assign EXLE =   (selE == 1) ? 1 :
			  		(AdES == 1) ? 1 :
			  		(AdEL == 1) ? 1 :
					(over == 1) ? 1 : 0;
					  
	assign ExcCodeE = 	(selE == 1) ? defaultExcCodeE :
						(AdEL == 1) ? 5'b00100 :
						(AdES == 1) ? 5'b00101 :
						(over == 1) ? 5'b01100 : 0;
	
/******                    M reg                  ******/
	
	wire [4:0] A2M;
	wire [31:0] rd2M, pcM; //锟斤拷锟斤拷锟截讹拷锟斤拷ALUoutM锟斤拷linkAddrM锟斤拷cft锟斤拷锟斤拷锟斤拷
	wire preMemWriteM;
	wire [2:0] MemOutSelM;
	wire [1:0] MemInSelM;
	wire HIReadM;
	wire [31:0] HIM, LOM;
	wire backM;
	//
	M mReg(
			.clk(clk),
			.respon(respon),
			.linkE(linkE),
			.RegWriteE(RegWriteE),
			.MemWriteE(MemWriteE),
			.MemOrALUE(MemOrALUE),
			.MemOutSelE(MemOutSelE),
			.MemInSelE(MemInSelE),
			.linkAddrE(linkAddrE),
			.ALUoutE(ALUoutE),
			.rd2E(RtoB),			//readData2, GPR[rt]
			.pcE(pcE),
			.A2E(A2E),
			.rdE(rdE),
			.A3E(A3E),
			.HIE(HIE),
			.LOE(LOE),
			.HLToRegE(HLToRegE),
			.HIReadE(HIReadE),
			.EXLE(EXLE),
			.ExcCodeE(ExcCodeE),
			.BDE(BDE),
			.CP0WeE(CP0WeE),
			.CP0ToRegE(CP0ToRegE),
			.backE(backE),
			.linkM(linkM),
			.RegWriteM(RegWriteM),
			.MemWriteM(preMemWriteM),
			.MemOrALUM(MemOrALUM),
			.MemOutSelM(MemOutSelM),
			.MemInSelM(MemInSelM),
			.linkAddrM(linkAddrM),
			.ALUoutM(ALUoutM),
			.rd2M(rd2M),
			.pcM(pcM),
			.A2M(A2M),
			.rdM(rdM),
			.A3M(A3M),
			.HIM(HIM),
			.LOM(LOM),
			.HLToRegM(HLToRegM),
			.HIReadM(HIReadM),
			.EXLM(EXLM),
			.ExcCodeM(ExcCodeM),
			.BDM(BDM),
			.CP0WeM(CP0WeM),
			.CP0ToRegM(CP0ToRegM),
			.backM(backM)
		);
			
			
/******                     M                   ******/

	wire [31:0] preData;
	
	assign EXL = EXLM;
	assign ExcCodeOut = ExcCodeM;
	assign BD = BDM;
	assign EPC = pcM;
	assign VAddr = (pcM[1:0] == 2'b00) ? ALUoutM : pcM;
	assign CP0Addr = rdM;
	assign CP0WD = preData;				// readData2, GPR[rt]
	assign CP0We = CP0WeM;
	assign back = backM;
		
	
	assign CP0OutM = CP0RD;				//mfc0 -> GPR[rt]
	assign MemOutW = data_sram_rdata;  
	assign data_sram_en = 1;			//这里暂时不知道这个信号是干什么的 
	assign MemWriteM = (preMemWriteM == 1 && respon == 0) ? 1 : 0;
	// output
	assign data_sram_addr = (ALUoutM >= 32'h80000000 && ALUoutM <= 32'h9FFFFFFF) ? // 这里又进行了虚拟地址到物理地址的固定映射
							(ALUoutM - 32'h80000000) : (ALUoutM - 32'hA0000000) ;
	assign preData = (RegWriteW && A2M == A3W && A2M != 0) ? wdW : rd2M;
	assign data_sram_wdata =(MemInSelM == `fullWord) ? preData :
							(MemInSelM == `halfWord && ALUoutM[1] == 0) ? {preData[15:0], preData[15:0]} :
							(MemInSelM == `halfWord && ALUoutM[1] == 1) ? {preData[15:0], preData[15:0]} :
							(MemInSelM == `quatWord && ALUoutM[1:0] == 2'b00) ? {preData[7:0],preData[7:0],preData[7:0],preData[7:0]} :
							(MemInSelM == `quatWord && ALUoutM[1:0] == 2'b01) ? {preData[7:0],preData[7:0],preData[7:0],preData[7:0]} :
							(MemInSelM == `quatWord && ALUoutM[1:0] == 2'b10) ? {preData[7:0],preData[7:0],preData[7:0],preData[7:0]} :
							(MemInSelM == `quatWord && ALUoutM[1:0] == 2'b11) ? {preData[7:0],preData[7:0],preData[7:0],preData[7:0]} : 0;
	
	assign data_sram_wen =  (MemWriteM == 0) ? 4'b0000 :
							(MemInSelM == `fullWord) ? 4'b1111 :
							(MemInSelM == `halfWord && ALUoutM[1] == 0) ? 4'b0011 :
							(MemInSelM == `halfWord && ALUoutM[1] == 1) ? 4'b1100 :
							(MemInSelM == `quatWord && ALUoutM[1:0] == 2'b00) ? 4'b0001 :
							(MemInSelM == `quatWord && ALUoutM[1:0] == 2'b01) ? 4'b0010 :
							(MemInSelM == `quatWord && ALUoutM[1:0] == 2'b10) ? 4'b0100 :
							(MemInSelM == `quatWord && ALUoutM[1:0] == 2'b11) ? 4'b1000 : 0;
								  
	// assign m_inst_addr = pcM;
	// assign macroscopic_pc = pcM;
	assign MemToRegM = (RegWriteM == 1 && MemOrALUM == 0 && linkM == 0 && CP0ToRegM == 0 && HLToRegM == 0) ? 1 : 0;
	assign HLM = (HIReadM == 1) ? HIM : LOM;
	
	
/******                   W Reg                  ******/
	wire linkW, MemOrALUW;
	wire [2:0] MemOutSelW;
	wire [31:0] linkAddrW, ALUoutW, MemOutW;
	wire [15:0] MemOutHalf;
	wire [7:0] MemOutQuat;
	wire [31:0] HIW, LOW;
	wire HLToRegW, HIReadW;
	wire CP0ToRegW;
	W wReg(
			.clk(clk),
			.linkM(linkM),
			.respon(respon),
			.RegWriteM(RegWriteM),
			.MemOrALUM(MemOrALUM),
			.MemOutSelM(MemOutSelM),
			.linkAddrM(linkAddrM),
			.ALUoutM(ALUoutM),
			.CP0OutM(CP0OutM),
			.pcM(pcM),
			.A3M(A3M),
			.HIM(HIM),
			.LOM(LOM),
			.HLToRegM(HLToRegM),
			.HIReadM(HIReadM),
			.CP0ToRegM(CP0ToRegM),
			.linkW(linkW),
			.RegWriteW(RegWriteW),
			.MemOrALUW(MemOrALUW),
			.MemOutSelW(MemOutSelW),
			.linkAddrW(linkAddrW),
			.ALUoutW(ALUoutW),
			.CP0OutW(CP0OutW),
			.pcW(pcW),
			.A3W(A3W),
			.HIW(HIW),
			.LOW(LOW),
			.HLToRegW(HLToRegW),
			.HIReadW(HIReadW),
			.CP0ToRegW(CP0ToRegW)
			);
			
			
/******                  W                      ******/
	wire [31:0] loadOrCal;
	assign MemOutHalf = (ALUoutW[1] == 0) ? MemOutW[15:0] : MemOutW[31:16];
	assign MemOutQuat = (ALUoutW[1:0] == 2'b00) ? MemOutW[7:0] :
						(ALUoutW[1:0] == 2'b01) ? MemOutW[15:8]:
						(ALUoutW[1:0] == 2'b10) ? MemOutW[23:16]: MemOutW[31:24]; //ALUoutW means m_data_addrW
							  
	assign loadOrCal = 	(MemOrALUW == 1) ? ALUoutW :
						(MemOutSelW == `MemOut_fullWord) ? MemOutW :
						(MemOutSelW == `MemOut_half_signExt) ? {{16{MemOutHalf[15]}}, MemOutHalf} :
						(MemOutSelW == `MemOut_half_zeroExt) ? {16'b0, MemOutHalf} :
						(MemOutSelW == `MemOut_quat_signExt) ? {{24{MemOutQuat[7]}}, MemOutQuat} :
						(MemOutSelW == `MemOut_quat_zeroExt) ? {24'b0, MemOutQuat} : 0;
						
	assign wdW = (linkW == 1) ? linkAddrW :
					(CP0ToRegW == 1) ? CP0OutW :
					(HLToRegW == 1 && HIReadW == 1) ? HIW :
					(HLToRegW == 1 && HIReadW == 0) ? LOW : loadOrCal;
	
	assign debug_wb_pc = pcW;
	assign debug_wb_rf_wdata = wdW;
	assign debug_wb_rf_wen = {4{RegWriteW}};
	assign debug_wb_rf_wnum = A3W;
endmodule
