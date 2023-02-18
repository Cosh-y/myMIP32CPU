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
	
	//inst sram-like 
    output reg    inst_req     ,
    output        inst_wr      ,
    output [1 :0] inst_size    ,
    output [31:0] inst_addr    ,
	output [3:0]  inst_wstrb   ,
    output [31:0] inst_wdata   ,
    input  [31:0] inst_rdata   ,
    input         inst_addr_ok ,
    input         inst_data_ok ,		

	//data sram_like
	output reg    data_req     ,
    output        data_wr      ,
    output [1 :0] data_size    ,
    output [31:0] data_addr    ,
	output [3:0]  data_wstrb   ,
    output [31:0] data_wdata   ,
    input  [31:0] data_rdata   ,
    input         data_addr_ok ,
    input         data_data_ok ,

	output [31:0] debug_wb_pc		,
	output [3:0]  debug_wb_rf_wen   ,
	output [4:0]  debug_wb_rf_wnum  ,
	output [31:0] debug_wb_rf_wdata ,
	
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
	wire [31:0] nextPC;
	reg [31:0] pc;
	reg F_valid;
	wire validin = 1; // 初始流水级的有效信号
	wire F_allowin, F_ready_go, F_to_D_valid;
	wire D_allowin;
	reg F_save_valid;
	reg F_cancel;
	always@(posedge clk) begin
		if(reset) begin
			F_cancel <= 0;
		end
		else if(respon && !inst_req) begin
			F_cancel <= 1;
		end
		else if(F_cancel && inst_data_ok)  begin
			F_cancel <= 0;
		end
	end

	assign F_allowin = !F_valid || F_ready_go && D_allowin || respon || reset;
	assign F_ready_go = (inst_data_ok || F_save_valid) && !F_cancel;				// F级的任务是取指，取到了有效的指令就可以流向D级了	
	assign F_to_D_valid = F_valid && F_ready_go;
/******				pre-F				  ******/
	reg s_backD, s_jump, s_branch, s_eq, s_nbranch, s_gez_br, s_greater_eq_zero, s_lz_br, s_gz_br, s_greater_zero, s_lez_br, s_Return, s_BD;
	reg [31:0] s_signExt, s_DInst, s_realRd1;
	// 用一组触发器保存跳转控制信号，以在跳转指令离开D级且延迟槽指令仍在F级未被读取的情况下正确跳转
	always@(posedge clk) begin
		if(backD || jump || branch || nbranch || gez_br || lz_br || gz_br || lez_br || Return) begin
			s_backD 		  <= backD;
			s_jump 			  <= jump;
			s_branch 		  <= branch;
			s_eq		 	  <= eq;
			s_nbranch 		  <= nbranch;
			s_gez_br 		  <= gez_br;
			s_greater_eq_zero <= greater_eq_zero;
			s_lz_br 		  <= lz_br;
			s_gz_br 		  <= gz_br;
			s_greater_zero 	  <= greater_zero;
			s_lez_br 		  <= lez_br;
			s_Return 		  <= Return;
			s_signExt 		  <= signExt;
			s_DInst 		  <= DInst;
			s_realRd1 		  <= realRd1;
			if(!backD) s_BD   <= 1;
		end
		else if(validin && F_allowin) begin
			s_backD 		  <= 0;
			s_jump 			  <= 0;
			s_branch 		  <= 0;
			s_eq		 	  <= 0;
			s_nbranch 		  <= 0;
			s_gez_br 		  <= 0;
			s_greater_eq_zero <= 0;
			s_lz_br 		  <= 0;
			s_gz_br 		  <= 0;
			s_greater_zero 	  <= 0;
			s_lez_br 		  <= 0;
			s_Return 		  <= 0;
			s_signExt 		  <= 0;
			s_DInst 		  <= 0;
			s_realRd1		  <= 0;
			s_BD 			  <= 0;
		end
	end
/******                F                  ******/
// F级寄存器包括PC和inst_req, F级内部的主要器件为inst_ram, 
// inst_ram输出的addr_ok与data_ok信号参与F级与D级两级流水线寄存器的控制
	wire [4:0] ExcCodeF, ExcCodeD, ExcCodeE, ExcCodeM;
	wire EXLF, EXLD, EXLE, EXLM;
	wire BDD, BDE, BDM;
	
	wire [31:0] DInst;
	wire [31:0] realRd1, realRd2, signExt;
	wire eq, greater_eq_zero, greater_zero;
	wire branch, nbranch, gez_br, gz_br, lez_br, lz_br, jump, linkD, Return, backD;
	always@(posedge clk) begin
		if(reset || respon) begin
			F_valid <= 1;
		end
		else if(F_allowin) begin
			F_valid <= validin;
		end

		if(validin && F_allowin) begin
			if(reset) begin
				pc <= 32'hBFC00000;
			end
			else if(respon) begin
				pc <= 32'hBFC00380;
			end
			else if(backD || s_backD) begin
				pc <= backPC + 4;
			end
			else if(jump  ) begin
				pc <= {pc[31:28], DInst[25:0], 2'b00};
			end
			else if(s_jump) begin
				pc <= {pc[31:28], s_DInst[25:0], 2'b00};
			end
			else if((branch && eq) || (!eq && nbranch)		  ) begin
				pc <= pc + (signExt << 2);
			end
			else if((s_branch && s_eq) || (!s_eq && s_nbranch)) begin
				pc <= pc + (s_signExt << 2);
			end
			else if((gez_br && greater_eq_zero) || (!greater_eq_zero && lz_br)		  ) begin
				pc <= pc + (signExt << 2);
			end
			else if((s_gez_br && s_greater_eq_zero) || (!s_greater_eq_zero && s_lz_br)) begin
				pc <= pc + (s_signExt << 2);
			end
			else if((gz_br && greater_zero) || (!greater_zero && lez_br)		) begin
				pc <= pc + (signExt << 2);
			end
			else if((s_gz_br && s_greater_zero) || (!s_greater_zero && s_lez_br)) begin
				pc <= pc + (s_signExt << 2);
			end
			else if(Return  ) begin
				pc <= realRd1;
			end
			else if(s_Return) begin
				pc <= s_realRd1;
			end
			else begin
				pc <= pc + 4;
			end
		end
	end
	
	// 在CPU内进行虚拟地址到物理地址的转换，inst_sram_addr传出物理地址
	assign inst_addr = (backD || s_backD) ? (backPC & 32'h1fffffff) : (pc & 32'h1fffffff);
	assign inst_wr   = 0;
	assign inst_wstrb = 4'b0000;
	assign inst_size = 2'b10;
	assign inst_wdata = 0;
	always@(posedge clk) begin
		if(reset || respon) begin			// 重置时发出请求
			inst_req <= 1;
		end
		else if(inst_addr_ok) begin			// 请求已被接收，停止请求
			inst_req <= 0;
		end
		else if(validin && F_allowin) begin	// 允许下一条指令进入F级，发出请求
			inst_req <= 1;
		end
	end
	
	assign EXLF = (inst_addr[1:0] != 0) ? 1 : 0; 	// 本质上，这里判断虚拟地址有效性，用物理地址做等价判断
	assign ExcCodeF = (EXLF) ? 5'b00100 : 0;

	reg [31:0] F_save_inst;
	always@(posedge clk) begin
		if(reset || respon || F_to_D_valid && D_allowin) begin
			F_save_valid <= 0;
		end
		else if(inst_data_ok && !F_cancel) begin
			F_save_inst <= inst_rdata;
			F_save_valid <= 1;
		end
	end

	reg [31:0] r_pc, r_inst;   
	reg [4:0] r_ExcCode;
	reg r_sel, r_BD;
	reg D_valid;
	wire E_allowin, D_ready_go, D_to_E_valid;
	assign D_allowin = !D_valid || D_ready_go && E_allowin;
	assign D_ready_go = !stopD;
	assign D_to_E_valid = D_valid && D_ready_go;
/*****              D reg                 ******/
	always@(posedge clk) begin
		if(reset || respon) begin
			D_valid <= 0;
		end
		else if(D_allowin) begin
			D_valid <= F_to_D_valid;
		end

		if(F_to_D_valid && D_allowin) begin
			r_pc <= (backD || s_backD) ? backPC : pc; //这里在cpu里继续传递的pc是虚拟地址
			r_sel <= EXLF;
			r_ExcCode <= ExcCodeF;
			r_inst <= (inst_data_ok) ? inst_rdata : F_save_inst;
			if(branch | nbranch | jump | Return | gez_br | gz_br | lez_br | lz_br | s_BD) begin
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
	
	// reg [31:0] keepInst;
	// reg keepStopD, keepRespon, keepReset;
	// wire [31:0] normalInst, preInst, DInst;
	
	// assign normalInst = inst_rdata;											// 不考虑reset, respon, stopD下读出的指令
	// always@(posedge clk) begin												// 保存上一个周期
	// 	keepInst <= DInst;													// 的指令
	// 	keepStopD <= stopD;													// 与控制信号以决定本周期应该运行哪条指令
	// end
	
	// assign preInst = (keepStopD == 1) ? keepInst : normalInst;
	assign DInst = (!D_valid) ? 0 : r_inst; 		// 最终需要解码即CPU上将运行的指令机器码
	
	assign imm = DInst[15:0];
	assign rs  = DInst[25:21];
	assign rt  = DInst[20:16];
	assign rd  = DInst[15:11];
	assign sa  = DInst[10: 6];
	assign op  = DInst[31:26];
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
	wire W_valid, RegWriteW;
	wire [4:0] A3W;
	GRF grf(
			  .clk(clk),
			  .reset(reset),
			  .RegWrite(RegWriteW & W_valid),
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
	
	wire [31:0] ALUoutM, linkAddrM, MemOutM;
	assign realRd1 = (beqRAW1 == `none) 	? rd1D :
					(beqRAW1 == `ALUM_rdD) 	? ALUoutM:
					(beqRAW1 == `LAddrM_rdD) ? linkAddrM:
					(beqRAW1 == `HLE_rdD) 	? HLE:
					(beqRAW1 == `HLM_rdD) 	? HLM: 
					(beqRAW1 == `CP0M_rdD) 	? CP0OutM :
					(beqRAW1 == `wdW_rdD) 	? wdW : 0;

	assign realRd2 = (beqRAW2 == `none) 	? rd2D :
					(beqRAW2 == `ALUM_rdD) 	? ALUoutM:
					(beqRAW2 == `LAddrM_rdD) ? linkAddrM:
					(beqRAW2 == `HLE_rdD) 	? HLE:
					(beqRAW2 == `HLM_rdD) 	? HLM: 
					(beqRAW2 == `CP0M_rdD) 	? CP0OutM :
					(beqRAW2 == `wdW_rdD) 	? wdW : 0;

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
	
	wire E_valid;
	wire M_allowin, E_ready_go, E_to_M_valid;
	assign E_allowin = !E_valid || E_ready_go && M_allowin;
	assign E_ready_go = 1;
	assign E_to_M_valid = E_valid && E_ready_go;

	E eReg(
			.clk(clk),
			.reset(reset),
			.respon(respon),
			.E_allowin(E_allowin),
			.D_to_E_valid(D_to_E_valid),
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
			.rd1D(realRd1),
			.rd2D(realRd2),
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
			.E_valid(E_valid),
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
	wire M_valid;

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
					 .E_valid(E_valid),
					 .M_valid(M_valid),
					 .W_valid(W_valid),
					 .ALURAW1(ALURAW1),
					 .ALURAW2(ALURAW2),
					 .beqRAW1(beqRAW1),
					 .beqRAW2(beqRAW2),
					 .stopD(stopD)
					);
					
					
/******                    E                  ******/
	wire [31:0] RtoA, A, RtoB, B, ALUoutE, LOE, HIE;
	wire over;
	
	assign RtoA = (ALURAW1 == `none) ? rd1E :
				  (ALURAW1 == `ALUM_ALUAB) ? ALUoutM :
				  (ALURAW1 == `wdW_ALUAB) ? wdW :
				  (ALURAW1 == `LAddrM_ALUAB) ? linkAddrM :
				  (ALURAW1 == `HLM_ALUAB) ? HLM : 
				  (ALURAW1 == `CP0M_ALUAB) ? CP0OutM : 
				  (ALURAW1 == `MOutM_ALUAB) ? MemOutM : 0;
	assign A = (RorSaE == 0) ? RtoA : {27'b0, saE};

	assign RtoB = (ALURAW2 == `none) ? rd2E :
				  (ALURAW2 == `ALUM_ALUAB) ? ALUoutM :
				  (ALURAW2 == `wdW_ALUAB) ? wdW :
				  (ALURAW2 == `LAddrM_ALUAB) ? linkAddrM :
				  (ALURAW2 == `HLM_ALUAB) ? HLM : 
				  (ALURAW2 == `CP0M_ALUAB) ? CP0OutM :
				  (ALURAW2 == `MOutM_ALUAB) ? MemOutM : 0;
	assign B = (IorRE == 0) ? IE : RtoB;
	
	ALU alu(
			  .A(A),
			  .B(B),
			  .ALUop(ALUopE),
			  .overJudge(overJudgeE & E_valid),
			  .out(ALUoutE),
			  .over(over)
			 );
			 
	wire in_valid, out_valid;
	wire [31:0] out_res0, out_res1;
	reg [31:0] HI, LO;
	wire out_ready = 1;
	assign in_valid = (E_valid && startE && ~respon);
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
	
	/****   HI,LO 寄存器写入逻辑       ****/
	always@(posedge clk) begin
		if(out_valid) begin
			HI <= out_res1;
			LO <= out_res0;
		end
		else if(E_valid && immWriteE && ~respon) begin
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
	assign MemToRegE = (E_valid && RegWriteE && !MemOrALUE && !linkE && !CP0ToRegE && !HLToRegE ) ? 1: 0; 
	wire outOfDiv, AdEL, AdES;
	assign AdEL = 	(MemToRegE == 1 && MemOutSelE == `MemOut_fullWord && ALUoutE[1:0] != 2'b00) ? 1 :
					(MemToRegE == 1 && (MemOutSelE == `MemOut_half_signExt || MemOutSelE == `MemOut_half_zeroExt) && ALUoutE[0] != 0) ? 1 : 0; 
					// (MemToRegE == 1 && over == 1) ? 1 :
					// (MemToRegE == 1 && outOfDiv == 1) ? 1 : 0;
					  
	assign AdES = 	(preMemWriteE == 1 && MemInSelE == `fullWord && ALUoutE[1:0] != 2'b00) ? 1 :
					(preMemWriteE == 1 && MemInSelE == `halfWord && ALUoutE[0] != 0) ? 1 : 0;
					// (preMemWriteE == 1 && over == 1) ? 1 :
					// (preMemWriteE == 1 && outOfDiv == 1) ? 1 : 0;
	assign MemWriteE = (!EXLE && preMemWriteE && E_valid) ? 1 : 0;
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

	wire W_allowin, M_ready_go, M_to_W_valid;
	assign M_allowin = !M_valid || M_ready_go && W_allowin;
	assign M_ready_go = (MemWriteM || MemToRegM) ? data_data_ok : 1;
	assign M_to_W_valid = M_valid && M_ready_go;
	//
	M mReg(
			.clk(clk),
			.reset(reset),
			.respon(respon),
			.M_allowin(M_allowin),
			.E_to_M_valid(E_to_M_valid),
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
			.M_valid(M_valid),
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
	
	assign EXL = EXLM & M_valid;
	assign ExcCodeOut = ExcCodeM;
	assign BD = BDM;
	assign EPC = pcM;
	assign VAddr = (pcM[1:0] == 2'b00) ? ALUoutM : pcM;
	assign CP0Addr = rdM;
	assign CP0WD = preData;				// readData2, GPR[rt]
	assign CP0We = CP0WeM & M_valid;
	assign back = backM & M_valid;
		
	
	assign CP0OutM = CP0RD;				//mfc0 -> GPR[rt]
	assign MemOutM = data_rdata;  
	assign MemWriteM = (M_valid && preMemWriteM == 1 && respon == 0) ? 1 : 0;
	// output
	assign data_addr = (ALUoutM & 32'h1fffffff); // 这里又进行了虚拟地址到物理地址的固定映射
	always@(posedge clk) begin
		if(reset || respon) begin
			data_req <= 0;
		end
		else if(E_to_M_valid && M_allowin && (MemWriteE || MemToRegE)) begin
			data_req <= 1;
			// preData <= (W_valid && RegWriteW && A2M == A3W && A2M != 0) ? wdW : rd2M;
		end
		else if(data_addr_ok) begin
			data_req <= 0;
		end
	end

	assign preData = rd2M;
	assign data_wdata = (MemInSelM == `fullWord) ? preData :
						(MemInSelM == `halfWord) ? {preData[15:0], preData[15:0]} :
						(MemInSelM == `quatWord) ? {preData[7:0],preData[7:0],preData[7:0],preData[7:0]} : 0;
	
	assign data_wstrb = (MemWriteM == 0) ? 4'b0000 :
						(MemInSelM == `fullWord) ? 4'b1111 :
						(MemInSelM == `halfWord && ALUoutM[1] == 0) ? 4'b0011 :
						(MemInSelM == `halfWord && ALUoutM[1] == 1) ? 4'b1100 :
						(MemInSelM == `quatWord && ALUoutM[1:0] == 2'b00) ? 4'b0001 :
						(MemInSelM == `quatWord && ALUoutM[1:0] == 2'b01) ? 4'b0010 :
						(MemInSelM == `quatWord && ALUoutM[1:0] == 2'b10) ? 4'b0100 :
						(MemInSelM == `quatWord && ALUoutM[1:0] == 2'b11) ? 4'b1000 : 0;

	assign data_wr = |data_wstrb;
	assign data_size = (MemInSelM == `fullWord || MemOutSelM == `MemOut_fullWord) ? 2'b10 :
					   (MemInSelM == `halfWord || MemOutSelM == `MemOut_half_signExt || MemOutSelM == `MemOut_half_zeroExt) ? 2'b01 :
					   (MemInSelM == `quatWord || MemOutSelM == `MemOut_quat_signExt || MemOutSelM == `MemOut_quat_zeroExt) ? 2'b00 : 0;					  
	assign MemToRegM = (M_valid && RegWriteM == 1 && MemOrALUM == 0 && linkM == 0 && CP0ToRegM == 0 && HLToRegM == 0) ? 1 : 0;
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

	wire W_ready_go;
	assign W_ready_go = 1;
	assign W_allowin = !W_valid || W_ready_go;
	W wReg(
			.clk(clk),
			.reset(reset),
			.respon(respon),
			.W_allowin(W_allowin),
			.M_to_W_valid(M_to_W_valid),
			.linkM(linkM),
			.RegWriteM(RegWriteM),
			.MemOrALUM(MemOrALUM),
			.MemOutM(MemOutM),
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
			.W_valid(W_valid),
			.linkW(linkW),
			.RegWriteW(RegWriteW),
			.MemOrALUW(MemOrALUW),
			.MemOutW(MemOutW),
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
	assign debug_wb_rf_wen = {4{RegWriteW & W_valid}};
	assign debug_wb_rf_wnum = A3W;
endmodule
