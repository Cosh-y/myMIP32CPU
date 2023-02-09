`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:03:05 11/10/2022 
// Design Name: 
// Module Name:    E 
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
module E(
	input clk,
	input reset,
	input respon,
	input E_allowin,
	input D_to_E_valid,
	input linkD,
	input RegWriteD,
	input MemWriteD,
	input MemOrALUD,
	input IorRD,
	input RorSaD,
	input [2:0] MemOutSelD,
	input [1:0] MemInSelD,
	input [3:0] ALUopD,
	input overJudgeD,
	input [31:0] linkAddrD,
	input [31:0] ID,
	input [31:0] rd1D,
	input [31:0] rd2D,
	input [31:0] pcD,
	input [4:0] A1D,
	input [4:0] A2D,
	input [4:0] rdD,
	input [4:0] saD,
	input [4:0] A3D,
	input startD,
	input immWriteD,
	input HIWriteD,
	input HLToRegD,
	input HIReadD,
	input [1:0] MDopD,
	input MDsignD,
	input EXLD,
	input [4:0] ExcCodeD,
	input BDD,
	input CP0WeD,
	input CP0ToRegD,
	input backD,
	output reg E_valid,
	output linkE,
	output RegWriteE,
	output MemWriteE,
	output MemOrALUE,
	output IorRE,
	output RorSaE,
	output [2:0] MemOutSelE,
	output [1:0] MemInSelE,
	output [3:0] ALUopE,
	output overJudgeE,
	output [31:0] linkAddrE,
	output [31:0] IE,
	output [31:0] rd1E,
	output [31:0] rd2E,
	output [31:0] pcE,
	output [4:0] A1E,
	output [4:0] A2E,
	output [4:0] rdE,
	output [4:0] saE,
	output [4:0] A3E,
	output startE,
	output immWriteE,
	output HIWriteE,
	output HLToRegE,
	output HIReadE,
	output [1:0] MDopE,
	output MDsignE,
	output selE,
	output [4:0] defaultExcCodeE,
	output BDE,
	output CP0WeE,
	output CP0ToRegE,
	output backE
    );
	
	reg r_link, r_RegWrite, r_MemWrite, r_MemOrALU, r_IorR, r_RorSa;
	reg [2:0] r_MemOutSel;
	reg [1:0] r_MemInSel;
	reg [3:0] r_ALUop;
	reg r_overJudge;
	reg [31:0] r_linkAddr, r_I, r_rd1, r_rd2, r_pc;
	reg [4:0] r_A1, r_A2, r_A3, r_rd, r_sa;
	reg r_start, r_immWrite, r_HIWrite, r_HLToReg, r_HIRead;
	reg [1:0] r_MDop;
	reg r_MDsign;
	reg r_sel, r_BD, r_CP0We, r_CP0ToReg, r_back;
	reg [4:0] r_ExcCode;

	always@(posedge clk) begin
		if(reset || respon) begin
			E_valid <= 0;
		end
		else if(E_allowin) begin
			E_valid <= D_to_E_valid;
		end

		if(D_to_E_valid && E_allowin) begin
			r_link <= linkD;
			r_ALUop <= ALUopD;
			r_overJudge <= overJudgeD;
			r_RegWrite <= RegWriteD;
			r_MemWrite <= MemWriteD;
			r_A1 <= A1D;
			r_A2 <= A2D;
			r_rd <= rdD;
			r_sa <= saD;
			r_A3 <= A3D;
			r_HLToReg <= HLToRegD;
			r_immWrite <= immWriteD;
			r_start <= startD;
			r_sel <= EXLD;
			r_ExcCode <= ExcCodeD;
			r_CP0We <= CP0WeD;
			r_CP0ToReg <= CP0ToRegD;
			r_back <= backD;
			r_MemOrALU <= MemOrALUD;
			r_IorR <= IorRD;
			r_RorSa <= RorSaD;
			r_linkAddr <= linkAddrD;
			r_I <= ID;
			r_rd1 <= rd1D;
			r_rd2 <= rd2D;
			r_MemOutSel <= MemOutSelD;
			r_MemInSel <= MemInSelD;
			r_HIWrite <= HIWriteD;
			r_HIRead <= HIReadD;
			r_MDop <= MDopD;
			r_MDsign <= MDsignD;
		end

		r_pc <= pcD;
		r_BD <= BDD;
	end
	
	assign linkE = r_link;
	assign RegWriteE = r_RegWrite;
	assign MemWriteE = r_MemWrite;
	assign MemOrALUE = r_MemOrALU;
	assign IorRE = r_IorR;
	assign RorSaE = r_RorSa;
	assign MemOutSelE = r_MemOutSel;
	assign MemInSelE = r_MemInSel;
	assign ALUopE = r_ALUop;
	assign overJudgeE = r_overJudge;
	assign linkAddrE = r_linkAddr;
	assign IE = r_I;
	assign rd1E = r_rd1;
	assign rd2E = r_rd2;
	assign pcE = r_pc;
	assign A1E = r_A1;
	assign A2E = r_A2;
	assign rdE = r_rd;
	assign saE = r_sa;
	assign A3E = r_A3;
	assign startE = r_start;
	assign immWriteE = r_immWrite;
	assign HIWriteE = r_HIWrite;
	assign HLToRegE = r_HLToReg;
	assign HIReadE = r_HIRead;
	assign MDopE = r_MDop;
	assign MDsignE = r_MDsign;
	assign selE = r_sel;
	assign defaultExcCodeE = r_ExcCode;
	assign BDE = r_BD;
	assign CP0WeE = r_CP0We;
	assign CP0ToRegE = r_CP0ToReg;
	assign backE = r_back;
	
endmodule
