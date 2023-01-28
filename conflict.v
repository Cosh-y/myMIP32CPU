`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    07:55:58 11/11/2022 
// Design Name: 
// Module Name:    conflict 
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

module conflict(
	input [4:0] A1D, A2D, A1E, A2E, A3E, A3M, A3W, rdE, rdM,
	input MemWriteD, RegWriteE, RegWriteM, MemToRegE, MemToRegM, RegWriteW,
	input linkM, branchD, nbranchD, gez_br, gz_br, lez_br, lz_br, Return, backD,
	input HLToRegD, HLToRegE, HLToRegM, CP0ToRegM, CP0WeE, CP0WeM,
	input busy, startE, startD, immWriteD,
	output reg [3:0] ALURAW1, ALURAW2,
	output reg [3:0] beqRAW1, beqRAW2,
	output reg stopF, stopD, flushE
    );
	
	always@(*) begin
		if(linkM == 1 && A1E == A3M && A3M != 0) begin
			ALURAW1 = `LAddrM_ALUAB;
		end
		else if(A1E == A3M && HLToRegM == 1 && A1E != 0) begin
			ALURAW1 = `HLM_ALUAB;
		end
		else if(A1E == A3M && CP0ToRegM == 1 && A1E != 0) begin
			ALURAW1 = `CP0M_ALUAB;
		end
		else if(A1E == A3M && RegWriteM == 1 && A1E != 0) begin
			ALURAW1 = `ALUM_ALUAB;
		end
		else if(A1E == A3W && RegWriteW == 1 && A1E != 0) begin
			ALURAW1 = `wdW_ALUAB;
		end
		else ALURAW1 = `none;
		
		if(linkM == 1 && A2E == A3M && A3M != 0) begin
			ALURAW2 = `LAddrM_ALUAB;
		end
		else if(A2E == A3M && HLToRegM == 1 && A2E != 0) begin
			ALURAW2 = `HLM_ALUAB;
		end
		else if(A2E == A3M && CP0ToRegM == 1 && A2E != 0) begin
			ALURAW2 = `CP0M_ALUAB;
		end
		else if(A2E == A3M && RegWriteM == 1 && A2E != 0) begin
			ALURAW2 = `ALUM_ALUAB;
		end
		else if(A2E == A3W && RegWriteW == 1 && A2E != 0) begin
			ALURAW2 = `wdW_ALUAB;
		end
		else ALURAW2 = `none;
	end
	
	always@(*) begin
		if((branchD == 1 || nbranchD == 1) && (A1D == A3E || A2D == A3E) && (RegWriteE == 1 && HLToRegE == 0) && A3E != 0) begin
			stopD = 1;
			stopF = 1;
			flushE = 1;
		end
		else if((branchD == 1 || nbranchD == 1) && (A1D == A3M || A2D == A3M) && MemToRegM == 1 && A3M != 0) begin
			stopD = 1;
			stopF = 1;
			flushE = 1;
		end
		else if((Return == 1 || gez_br || gz_br || lez_br || lz_br) && (A1D == A3E && A3E != 0) && RegWriteE == 1 && HLToRegE == 0) begin
			stopD = 1;
			stopF = 1;
			flushE = 1;
		end
		else if((Return == 1 || gez_br || gz_br || lez_br || lz_br) && (A1D == A3M && A3M != 0) && MemToRegM == 1) begin
			stopD = 1;
			stopF = 1;
			flushE = 1;
		end
		else if((backD == 1) && ((CP0WeE == 1 && rdE == 5'b01110) || (CP0WeM == 1 && rdM == 5'b01110)))begin
			stopD = 1;
			stopF = 1;
			flushE = 1;
		end
		else if(A1D == A3E && MemToRegE == 1 && A3E != 0) begin
			stopD = 1;
			stopF = 1;
			flushE = 1;
		end
		else if(A2D == A3E && MemToRegE == 1 && A3E != 0 && MemWriteD == 0) begin
			stopD = 1;
			stopF = 1;
			flushE = 1;
		end
		else if((busy == 1 || startE == 1) && (startD || immWriteD || HLToRegD)) begin
			stopD = 1;
			stopF = 1;
			flushE = 1;
		end
		else begin
			stopD = 0;
			stopF = 0;
			flushE = 0;
		end
	end
	
	always@(*) begin
		if(HLToRegE == 1 && A1D == A3E && A3E != 0) begin
			beqRAW1 = `HLE_rdD;
		end
		else if(linkM == 1 && A1D == A3M && A3M != 0) begin
			beqRAW1 = `LAddrM_rdD;
		end
		else if(HLToRegM == 1 && A1D == A3M && A3M != 0) begin
			beqRAW1 = `HLM_rdD;
		end
		else if(CP0ToRegM == 1 && A1D == A3M && A3M != 0) begin
			beqRAW1 = `CP0M_rdD;
		end
		else if(RegWriteM == 1 && A1D == A3M && A3M != 0) begin
			beqRAW1 = `ALUM_rdD;
		end
		else begin
			beqRAW1 = `none;
		end
		
		if(HLToRegE == 1 && A2D == A3E && A3E != 0) begin
			beqRAW2 = `HLE_rdD;
		end
		else if(linkM == 1 && A2D == A3M && A3M != 0) begin
			beqRAW2 = `LAddrM_rdD;
		end
		else if(HLToRegM == 1 && A2D == A3M && A3M != 0) begin
			beqRAW2 = `HLM_rdD;
		end
		else if(CP0ToRegM == 1 && A2D == A3M && A3M != 0) begin
			beqRAW2 = `CP0M_rdD;
		end
		else if(RegWriteM == 1 && A2D == A3M && A3M != 0) begin
			beqRAW2 = `ALUM_rdD;
		end
		else begin
			beqRAW2 = `none;
		end
	end
endmodule
