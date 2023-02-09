`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:23:33 11/10/2022 
// Design Name: 
// Module Name:    M 
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
module M(
	input clk,
	input reset,
	input respon,
	input M_allowin,
	input E_to_M_valid,
	input linkE,
	input RegWriteE,
	input MemWriteE,
	input MemOrALUE,
	input [2:0] MemOutSelE,
	input [1:0] MemInSelE,
	input [31:0] linkAddrE,
	input [31:0] ALUoutE,
	input [31:0] rd2E,
	input [31:0] pcE,
	input [4:0] A2E,
	input [4:0] rdE,
	input [4:0] A3E,
	input [31:0] HIE,
	input [31:0] LOE,
	input HLToRegE,
	input HIReadE,
	input EXLE,
	input [4:0] ExcCodeE,
	input BDE,
	input CP0WeE,
	input CP0ToRegE,
	input backE,
	output reg M_valid,
	output linkM,
	output RegWriteM,
	output MemWriteM,
	output MemOrALUM,
	output [2:0] MemOutSelM,
	output [1:0] MemInSelM,
	output [31:0] linkAddrM,
	output [31:0] ALUoutM,
	output [31:0] rd2M,
	output [31:0] pcM,
	output [4:0] A2M,
	output [4:0] rdM,
	output [4:0] A3M,
	output [31:0] HIM,
	output [31:0] LOM,
	output HLToRegM,
	output HIReadM,
	output EXLM,
	output [4:0] ExcCodeM,
	output BDM,
	output CP0WeM,
	output CP0ToRegM,
	output backM
    );
	
	reg r_link, r_RegWrite, r_MemWrite, r_MemOrALU;
	reg [2:0] r_MemOutSel;
	reg [1:0] r_MemInSel;
	reg [31:0] r_linkAddr, r_ALUout, r_rd2, r_pc;
	reg [4:0] r_A2, r_A3, r_rd;
	reg [31:0] r_HI, r_LO;
	reg r_HLToReg, r_HIRead;
	reg r_exl, r_BD, r_CP0We, r_CP0ToReg, r_back;
	reg [4:0] r_ExcCode;
	 
	always@(posedge clk) begin
		if(reset || respon) begin
			M_valid <= 0;
		end
		else if(M_allowin) begin
			M_valid <= E_to_M_valid;
		end

		if(E_to_M_valid && M_allowin) begin
			r_link <= linkE;
			r_RegWrite <= RegWriteE;
			r_MemWrite <= MemWriteE;
			r_MemOrALU <= MemOrALUE;
			r_MemOutSel <= MemOutSelE;
			r_MemInSel <= MemInSelE;
			r_linkAddr <= linkAddrE;
			r_ALUout <= ALUoutE;
			r_rd2 <= rd2E;
			r_A2 <= A2E;
			r_rd <= rdE;
			r_A3 <= A3E;
			r_HI <= HIE;
			r_LO <= LOE;
			r_HLToReg <= HLToRegE;
			r_HIRead <= HIReadE;
			r_exl <= EXLE;
			r_ExcCode <= ExcCodeE;
			r_CP0We <= CP0WeE;
			r_CP0ToReg <= CP0ToRegE;
			r_back <= backE;
		end

		r_pc <= pcE;
		r_BD <= BDE;
	end
	
	assign linkM = r_link;
	assign RegWriteM = r_RegWrite;
	assign MemWriteM = r_MemWrite;
	assign MemOrALUM = r_MemOrALU;
	assign MemOutSelM = r_MemOutSel;
	assign MemInSelM = r_MemInSel;
	assign linkAddrM = r_linkAddr;
	assign ALUoutM = r_ALUout;
	assign rd2M = r_rd2;
	assign pcM = r_pc;
	assign A2M = r_A2;
	assign rdM = r_rd;
	assign A3M = r_A3;
	assign HIM = r_HI;
	assign LOM = r_LO;
	assign HLToRegM = r_HLToReg;
	assign HIReadM = r_HIRead;
	assign EXLM = r_exl;
	assign ExcCodeM = r_ExcCode;
	assign BDM = r_BD;
	assign CP0WeM = r_CP0We;
	assign CP0ToRegM = r_CP0ToReg;
	assign backM = r_back;
	
endmodule
