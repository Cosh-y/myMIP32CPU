`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:37:44 10/27/2022 
// Design Name: 
// Module Name:    GRF 
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
module GRF(
	input wire clk,
	input wire reset,
	input wire RegWrite,
	input wire [4:0] RegAddr1,
	input wire [4:0] RegAddr2,
	input wire [4:0] RegAddr3,
	input wire [31:0] wd,
	output wire [31:0] RegData1,
	output wire [31:0] RegData2
    );
	 
	 reg [31:0] grf [0:31];
	 integer i;
	 
	 /*always@ (posedge clk) begin
		if(reset) begin
			for(i=0;i<32;i=i+1) begin
				grf[i] <= 0;
			end
		end	
	 end*/
	 
	 always@ (posedge clk) begin
		if(reset) begin
			for(i=0;i<32;i=i+1) begin
				grf[i] <= 0;
			end
		end
		else if(RegWrite == 1 && reset == 0 && RegAddr3 != 0) begin
			grf[RegAddr3] <= wd;
		end
	 end
	 
	assign RegData1 = (RegAddr1 == 0) ? 0 : grf[RegAddr1];
	assign RegData2 = (RegAddr2 == 0) ? 0 : grf[RegAddr2];

endmodule
