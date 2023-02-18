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
	input E_valid, M_valid, W_valid,
	output reg [3:0] ALURAW1, ALURAW2,
	output reg [3:0] beqRAW1, beqRAW2,
	output reg stopD
    );
	
	always@(*) begin
		if(M_valid && linkM && A1E == A3M && A3M != 0) begin
			ALURAW1 = `LAddrM_ALUAB;
		end
		else if(A1E == A3M && M_valid && MemToRegM && A3M != 0) begin
			ALURAW1 = `MOutM_ALUAB;
		end
		else if(A1E == A3M && M_valid && HLToRegM && A1E != 0)  begin
			ALURAW1 = `HLM_ALUAB;
		end
		else if(A1E == A3M && M_valid && CP0ToRegM && A1E != 0) begin // 考虑一下M级lw指令到E级ALU指令之间的转发和阻塞问题
			ALURAW1 = `CP0M_ALUAB;
		end
		else if(A1E == A3M && M_valid && RegWriteM && A1E != 0) begin
			ALURAW1 = `ALUM_ALUAB;
		end
		else if(A1E == A3W && W_valid && RegWriteW && A1E != 0) begin
			ALURAW1 = `wdW_ALUAB;
		end
		else ALURAW1 = `none;
		
		if(M_valid && linkM && A2E == A3M && A3M != 0) begin
			ALURAW2 = `LAddrM_ALUAB;
		end
		else if(A2E == A3M && M_valid && MemToRegM && A3M != 0) begin
			ALURAW2 = `MOutM_ALUAB;
		end
		else if(A2E == A3M && M_valid && HLToRegM && A2E != 0)  begin
			ALURAW2 = `HLM_ALUAB;
		end
		else if(A2E == A3M && M_valid && CP0ToRegM && A2E != 0) begin
			ALURAW2 = `CP0M_ALUAB;
		end
		else if(A2E == A3M && M_valid && RegWriteM && A2E != 0) begin
			ALURAW2 = `ALUM_ALUAB;
		end
		else if(A2E == A3W && W_valid && RegWriteW && A2E != 0) begin
			ALURAW2 = `wdW_ALUAB;
		end
		else ALURAW2 = `none;
	end
	
	always@(*) begin
		if((branchD || nbranchD) && (A1D == A3E || A2D == A3E) && (E_valid && RegWriteE && !HLToRegE) && A3E != 0) begin
			stopD = 1;			
		end
		else if((branchD || nbranchD) && (A1D == A3M || A2D == A3M) && MemToRegM == 1 && A3M != 0) begin
			stopD = 1;			
		end
		else if((Return || gez_br || gz_br || lez_br || lz_br) && (A1D == A3E && A3E != 0) && E_valid && RegWriteE && !HLToRegE) begin
			stopD = 1;			
		end
		else if((Return || gez_br || gz_br || lez_br || lz_br) && (A1D == A3M && A3M != 0) && MemToRegM == 1) begin
			stopD = 1;			
		end
		else if((backD == 1) && ((E_valid && CP0WeE && rdE == 5'b01110) || (M_valid && CP0WeM && rdM == 5'b01110)))begin
			stopD = 1;			
		end
		// else if(A1D == A3E && MemToRegE == 1 && A3E != 0) begin
		// 	stopD = 1;			
		// end
		// else if(A2D == A3E && MemToRegE == 1 && A3E != 0 && MemWriteD == 0) begin
		// 	stopD = 1;			
		// end
		else if((busy == 1 || (startE && E_valid)) && (startD || immWriteD || HLToRegD)) begin
			stopD = 1;			
		end
		else begin
			stopD = 0;			
		end
	end
	
	always@(*) begin
		if(E_valid && HLToRegE == 1 && A1D == A3E && A3E != 0) begin
			beqRAW1 = `HLE_rdD;
		end
		else if(M_valid && linkM == 1 && A1D == A3M && A3M != 0) begin
			beqRAW1 = `LAddrM_rdD;
		end
		else if(M_valid && HLToRegM == 1 && A1D == A3M && A3M != 0) begin
			beqRAW1 = `HLM_rdD;
		end
		else if(M_valid && CP0ToRegM == 1 && A1D == A3M && A3M != 0) begin
			beqRAW1 = `CP0M_rdD;
		end
		else if(M_valid && RegWriteM == 1 && A1D == A3M && A3M != 0) begin
			beqRAW1 = `ALUM_rdD;
		end
		else if(W_valid && RegWriteW && A1D == A3W && A3W != 0) begin
			beqRAW1 = `wdW_rdD;
		end
		else begin
			beqRAW1 = `none;
		end
		
		if(E_valid && HLToRegE == 1 && A2D == A3E && A3E != 0) begin
			beqRAW2 = `HLE_rdD;
		end
		else if(M_valid && linkM == 1 && A2D == A3M && A3M != 0) begin
			beqRAW2 = `LAddrM_rdD;
		end
		else if(M_valid && HLToRegM == 1 && A2D == A3M && A3M != 0) begin
			beqRAW2 = `HLM_rdD;
		end
		else if(M_valid && CP0ToRegM == 1 && A2D == A3M && A3M != 0) begin
			beqRAW2 = `CP0M_rdD;
		end
		else if(M_valid && RegWriteM == 1 && A2D == A3M && A3M != 0) begin
			beqRAW2 = `ALUM_rdD;
		end
		else if(W_valid && RegWriteW && A2D == A3W && A3W != 0) begin
			beqRAW2 = `wdW_rdD;
		end
		else begin
			beqRAW2 = `none;
		end
	end
endmodule
