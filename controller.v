`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:07:37 10/28/2022 
// Design Name: 
// Module Name:    controller1 
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

module controller(
	input [5:0] op,
	input [5:0] func,
	input [4:0] rs,
	input [4:0] rt,
	input [4:0] rd,
	output RegWrite,
	output MemWrite,
	output MemOrALU,			// 为grf wd 端口提供内存读出数据还是ALU计算结果，默认(0)为内存读出数据
	output IorR,				// 为ALU_B 提供立即数或寄存器保存值，默认(0)为立即数
	output RorSa,
	output branch,
	output nbranch,
	output gez_br,
	output gz_br,
	output lez_br,
	output lz_br,
	output jump,
	output link,
	output Return,
	output [3:0] ALUop,
	output overJudge,
	output [1:0] Ext,
	output [1:0] A3From,
	output [2:0] MemOutSel,
	output [1:0] MemInSel,
	output start,
	output [1:0] MDop,
	output MDsign,
	output immWrite,
	output HIWrite,
	output HLToReg,
	output HIRead,
	output CP0We,
	output CP0ToReg,
	output undefine,
	output call,
	output breakPoint,
	output back
	);
	 
	wire addi, addiu, lui, sub, subu, add, addu, slt, sltu, slti, sltiu;
	wire lw, lh, lhu, lb, lbu, sw, sh, sb; 
	wire beq, bne, j, jal, jr, bgez, bgtz, blez, bltz, bgezal, bltzal, jalr;
	wire AND, OR, andi, ori, NOR, XOR, xori; 
	wire sllv, sll, srav, sra, srlv, srl;
	wire mult, multu, div, divu, mflo, mfhi, mtlo, mthi;
	wire mfc0, mtc0, eret, syscall, BREAK, nop;
	
	assign nop = (op == 6'b000000 && func == 6'b000000 && rd == 5'b00000) ? 1 : 0;

	assign beq = (op == 6'b000100) ? 1 : 0;
	assign bne = (op == 6'b000101) ? 1 : 0;
	assign j =   (op == 6'b000010) ? 1 : 0;
	assign jal = (op == 6'b000011) ? 1 : 0;
	assign jr = (op == 6'b000000 && func == 6'b001000) ? 1 : 0;
	assign jalr = (op == 6'b000000 && func == 6'b001001) ? 1 : 0;
	assign bgez = (op == 6'b000001 && rt == 5'b00001) ? 1 : 0;
	assign bgtz = (op == 6'b000111) ? 1 : 0;
	assign blez = (op == 6'b000110) ? 1 : 0;
	assign bltz = (op == 6'b000001 && rt == 5'b00000) ? 1 : 0;
	assign bgezal = (op == 6'b000001 && rt == 5'b10001) ? 1 : 0;
	assign bltzal = (op == 6'b000001 && rt == 5'b10000) ? 1 : 0;
	
	
	assign lui = (op == 6'b001111) ? 1 : 0;
	assign sub = (op == 6'b000000 && func == 6'b100010) ? 1 : 0;
	assign subu = (op == 6'b000000 && func == 6'b100011) ? 1 : 0;
	assign add = (op == 6'b000000 && func == 6'b100000) ? 1 : 0;
	assign addu = (op == 6'b000000 && func == 6'b100001) ? 1 : 0;
	
	assign AND = (op == 6'b000000 && func == 6'b100100) ? 1 : 0;
	assign OR = (op == 6'b000000 && func == 6'b100101) ? 1 : 0;
	assign andi = (op == 6'b001100) ? 1 : 0;
	assign ori = (op == 6'b001101) ? 1 : 0;
	assign NOR = (op == 6'b000000 && func == 6'b100111) ? 1 : 0;
	assign XOR = (op == 6'b000000 && func == 6'b100110) ? 1 : 0;
	assign xori = (op == 6'b001110) ? 1 : 0;

	assign slt = (op == 6'b000000 && func == 6'b101010) ? 1 : 0;
	assign sltu = (op == 6'b000000 && func == 6'b101011) ? 1 : 0;
	assign slti = (op == 6'b001010) ? 1 : 0;
	assign sltiu = (op == 6'b001011) ? 1 : 0;
	assign addi = (op == 6'b001000) ? 1 : 0;
	assign addiu = (op == 6'b001001) ? 1 : 0;
	
	assign lw  = (op == 6'b100011) ? 1 : 0;
	assign sw  = (op == 6'b101011) ? 1 : 0;
	assign lh  = (op == 6'b100001) ? 1 : 0;
	assign lhu = (op == 6'b100101) ? 1 : 0;
	assign lb  = (op == 6'b100000) ? 1 : 0;
	assign lbu = (op == 6'b100100) ? 1 : 0;
	assign sb  = (op == 6'b101000) ? 1 : 0;
	assign sh  = (op == 6'b101001) ? 1 : 0;
	

	assign mult = (op == 6'b000000 && func == 6'b011000) ? 1 : 0;
	assign multu = (op == 6'b000000 && func == 6'b011001) ? 1 : 0;
	assign div = (op == 6'b000000 && func == 6'b011010) ? 1 : 0;
	assign divu = (op == 6'b000000 && func == 6'b011011) ? 1 : 0;
	assign mflo = (op == 6'b000000 && func == 6'b010010) ? 1 : 0;
	assign mfhi = (op == 6'b000000 && func == 6'b010000) ? 1 : 0;
	assign mtlo = (op == 6'b000000 && func == 6'b010011) ? 1 : 0;
	assign mthi = (op == 6'b000000 && func == 6'b010001) ? 1 : 0;

	assign mfc0 = (op == 6'b010000 && rs == 5'b00000) ? 1 : 0;
	assign mtc0 = (op == 6'b010000 && rs == 5'b00100) ? 1 : 0;
	assign eret = (op == 6'b010000 && func == 6'b011000) ? 1 : 0;
	assign syscall = (op == 6'b000000 && func == 6'b001100) ? 1 : 0;
	assign BREAK = (op == 6'b000000 && func == 6'b001101) ? 1 : 0;

	assign sllv = (op == 6'b000000 && func == 6'b000100) ? 1 : 0;
	assign sll = (op == 6'b000000 && func == 6'b000000 && rd != 5'b00000) ? 1 : 0;
	assign srav = (op == 6'b000000 && func == 6'b000111) ? 1 : 0;
	assign sra = (op == 6'b000000 && func == 6'b000011) ? 1 : 0;
	assign srlv = (op == 6'b000000 && func == 6'b000110) ? 1 : 0;
	assign srl = (op == 6'b000000 && func == 6'b000010) ? 1 : 0;
	

	assign call = syscall;
	assign breakPoint = BREAK;
	assign undefine = (nop | ori | lw | sw | beq | lui | sub | subu | add | addu | j | jal | jr | jalr | AND | OR | NOR | XOR | xori | slt | sltu | slti | sltiu | addi | addiu |
	bgez | bgtz | blez | bltz | bgezal | bltzal | sllv | sll | srav | sra | srlv | srl | andi | lh | lhu | lb | lbu | sb | sh | bne | mult | multu | div | divu | mflo | mfhi |
	mtlo | mthi | mfc0 | mtc0 | eret | syscall | BREAK) ? 0 : 1; 
	
	assign RegWrite = (lw | lui | ori | add | addu | sub | subu | slt | sltu | slti | sltiu | AND | OR | NOR | XOR | xori | andi | addi | addiu |
	lh | lhu | lb | lbu | mfhi | mflo | mfc0 |sllv | sll | srav | sra | srlv | srl | jal | jalr | bgezal | bltzal) ? 1 : 0;

	assign MemWrite = (sw | sb | sh) ? 1 : 0;
	
	assign MemInSel = 	(sw) ? `fullWord :
						(sh) ? `halfWord :
						(sb) ? `quatWord : 2'b11;

	assign MemOutSel = 	(lw)  ? `MemOut_fullWord :
						(lh)  ? `MemOut_half_signExt :
						(lhu) ? `MemOut_half_zeroExt :
						(lb)  ? `MemOut_quat_signExt : 
						(lbu) ? `MemOut_quat_zeroExt : 3'b111;
	
	assign MemOrALU = (sub | subu | add | addu | ori | lui | AND | OR | NOR | XOR | xori | slt | sltu | slti | sltiu | andi | addiu | addi | sllv | sll | srav | sra | srlv | srl) ? 1 : 0;
	
	assign IorR = (sub | subu | add | addu | slt | sltu | AND | OR | NOR | XOR | mult | multu | div | divu | sllv | sll | srav | sra | srlv | srl) ? 1 : 0;
	assign RorSa= (sll | sra | srl) ? 1 : 0;
	
	assign branch = (beq) ? 1 : 0;
	assign nbranch = (bne) ? 1 : 0;
	assign gez_br = (bgez | bgezal) ? 1 : 0;
	assign gz_br  = (bgtz) ? 1 : 0;
	assign lez_br = (blez) ? 1 : 0;
	assign lz_br  = (bltz | bltzal) ? 1 : 0;
	assign jump = (j | jal)   ? 1 : 0;
	assign link = (jal | bgezal | bltzal | jalr) ? 1 : 0;
	assign Return = (jr | jalr) ? 1 : 0;

	assign ALUop =  (add | addu | sw | lw | addi | addiu | sb | sh | lb | lh | lhu | lbu) ? `aluAdd :
					(sub | subu)		? `aluSub :
					(ori | lui | OR)    ? `aluOr :
					(AND | andi)		? `aluAnd :
					(sllv | sll)		? `aluSL :
					(srav | sra)		? `aluASR :
					(srlv | srl)		? `aluSR :
					(NOR)				? `aluNOR :
					(XOR | xori)		? `aluXOR :
					(slt | slti)        ? `aluSlt :
					(sltu | sltiu) 		? `aluSltu : 4'b1111;

	assign overJudge = (addu | addiu | subu) ? 0 : 1;
	assign Ext = 	(ori | andi | xori) 	  	? 2'b00 : //zeroExt
					(lui)     			? 2'b01 : //atHigh
					(lw | sw | addi | addiu | lb | lbu | lh | lhu | sb | sh | slti | sltiu) ? 2'b10 :	//signExt
																			2'b11;
	assign A3From = (lw | ori | lui | addi | addiu | andi | xori | lb | lbu | lh | lhu | mfc0 | slti | sltiu)	? 2'b00 : //rt
					(add | addu | sub | subu | slt | sltu | OR | AND | NOR | XOR | mfhi | mflo | sllv | sll | srav | sra | srlv | srl | jalr)  ? 2'b01 :  //rd
					(jal | bgezal | bltzal)					  						? 2'b10 : //31
																				2'b11; //0
	assign immWrite = (mtlo | mthi) ? 1 : 0;
	assign HIWrite = mthi;
	assign MDop = (mult | multu) ? 2'b01 :
					  (div | divu) ? 2'b10 : 0;
	assign MDsign = (multu | divu) ? 0 : 1;
					  
	assign start = (mult | multu | div | divu) ? 1 : 0;
	assign HLToReg = (mfhi | mflo) ? 1 : 0;
	assign HIRead = (mfhi) ? 1 : 0;
	assign CP0We = (mtc0) ? 1 : 0;
	assign CP0ToReg = (mfc0) ? 1 : 0;
	assign back = (eret) ? 1 : 0;
	
endmodule
