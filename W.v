`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:34:55 11/10/2022 
// Design Name: 
// Module Name:    W 
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
module W(
	input clk,
	input linkM,
	input respon,
	input RegWriteM,
	input MemOrALUM,
	input [2:0] MemOutSelM,
	input [31:0] linkAddrM,
	input [31:0] ALUoutM,
	input [31:0] CP0OutM,
	input [31:0] pcM,
	input [4:0] A3M,
	input [31:0] HIM,
	input [31:0] LOM,
	input HLToRegM,
	input HIReadM,
	input CP0ToRegM,
	output linkW,
	output RegWriteW,
	output MemOrALUW,
	output [2:0] MemOutSelW,
	output [31:0] linkAddrW,
	output [31:0] ALUoutW,
	output [31:0] CP0OutW,
	output [31:0] pcW,
	output [4:0] A3W,
	output [31:0] HIW,
	output [31:0] LOW,
	output HLToRegW,
	output HIReadW,
	output CP0ToRegW
    );

	reg r_link, r_RegWrite, r_MemOrALU;
	reg [2:0] r_MemOutSel;
	reg [4:0] r_A3;
	reg [31:0] r_linkAddr, r_ALUout, r_CP0Out, r_pc;
	reg [31:0] r_HI, r_LO;
	reg r_HLToReg, r_HIRead, r_CP0ToReg;
	
	always@(posedge clk) begin
		if(respon) begin
			r_RegWrite <= 0;
		end
		else begin
			r_RegWrite <= RegWriteM;
		end
		r_link <= linkM;
		r_MemOrALU <= MemOrALUM;
		r_MemOutSel <= MemOutSelM;
		r_linkAddr <= linkAddrM;
		r_ALUout <= ALUoutM;
		//r_MemOut <= MemOutM;
		r_CP0Out <= CP0OutM;
		r_pc <= pcM;
		r_A3 <= A3M;
		r_HI <= HIM;
		r_LO <= LOM;
		r_HLToReg <= HLToRegM;
		r_HIRead <= HIReadM;
		r_CP0ToReg <= CP0ToRegM;
	end
	
	assign linkW = r_link;
	assign RegWriteW = r_RegWrite;
	assign MemOrALUW = r_MemOrALU;
	assign MemOutSelW = r_MemOutSel;
	assign linkAddrW = r_linkAddr;
	assign ALUoutW = r_ALUout;
	//assign MemOutW = r_MemOut;
	assign CP0OutW = r_CP0Out;
	assign pcW = r_pc;
	assign A3W = r_A3;
	assign HIW = r_HI;
	assign LOW = r_LO;
	assign HLToRegW = r_HLToReg;
	assign HIReadW = r_HIRead;
	assign CP0ToRegW = r_CP0ToReg;
	
endmodule
