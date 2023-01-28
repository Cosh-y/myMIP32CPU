`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:04:33 10/28/2022 
// Design Name: 
// Module Name:    ALU 
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

module ALU(
	input [31:0] A,
	input [31:0] B,
	input [3:0] ALUop,
	input overJudge,
	output [31:0] out,
	output over
    );
	
	wire [32:0] Ae, Be, sum, sub;
	wire [31:0] sltRes, sltuRes, asr;
	assign sltRes = ($signed(A) < $signed(B)) ? 1 : 0;
	assign sltuRes = (A < B) ? 1 : 0;
	assign asr = $signed(B) >>> A[4:0];
	
	assign out= (ALUop == `aluAdd) ? (A + B) :
				(ALUop == `aluSub) ? (A - B) :
				(ALUop == `aluOr) ? (A | B) :
				(ALUop == `aluAnd) ? (A & B) :
				(ALUop == `aluSL) ? (B << A[4:0]) :
				(ALUop == `aluSR) ? (B >> A[4:0]) :
				(ALUop == `aluASR) ? asr :
				(ALUop == `aluNOR) ? ~(A | B) :
				(ALUop == `aluXOR) ? A ^ B :
				(ALUop == `aluSlt) ? sltRes :
				(ALUop == `aluSltu) ? sltuRes : 0;
	
	assign Ae = {A[31], A};
	assign Be = {B[31], B};
	assign sum = Ae + Be;
	assign sub = Ae - Be;
	assign over =   (overJudge == 0) ? 0 :
					(ALUop == `aluAdd && sum[31] != sum[32]) ? 1 :
					(ALUop == `aluSub && sub[31] != sub[32]) ? 1 : 0;
endmodule
