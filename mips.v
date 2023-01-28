`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:15:46 10/27/2022 
// Design Name: 
// Module Name:    mips 
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

module mycpu_top(
	input clk,
	input resetn,
	input [5:0] ext_int,

	output inst_sram_en,
	output [3:0] inst_sram_wen,
	output [31:0] inst_sram_addr,
	output [31:0] inst_sram_wdata,
	input [31:0] inst_sram_rdata,

	output data_sram_en,
	output [3:0] data_sram_wen,
	output [31:0] data_sram_addr,
	output [31:0] data_sram_wdata,
	input [31:0] data_sram_rdata,

	output [31:0] debug_wb_pc,
	output [3:0] debug_wb_rf_wen,
	output [4:0] debug_wb_rf_wnum,
	output [31:0] debug_wb_rf_wdata
);

	assign inst_sram_en = 1;
	assign inst_sram_wen = 0;
	assign inst_sram_wdata = 32'b0;
	 
	wire [31:0] EPC, VAddr;
	wire EXL;
	wire [4:0] ExcCode;
	wire BD;
	wire require;
	wire [4:0] CP0Addr;
	wire [31:0] CP0RD, CP0WD, backPC;
	wire CP0We, back;
	
	
	CPU cpu(
			.clk(clk),
			.reset(~resetn),
			.respon(require),     			// 命名的专业性

			.inst_sram_addr(inst_sram_addr),
			.inst_sram_rdata(inst_sram_rdata),

			.data_sram_en(data_sram_en),
			.data_sram_wen(data_sram_wen),
			.data_sram_addr(data_sram_addr),
			.data_sram_wdata(data_sram_wdata),
			.data_sram_rdata(data_sram_rdata),

			.debug_wb_pc(debug_wb_pc),
			.debug_wb_rf_wen(debug_wb_rf_wen),
			.debug_wb_rf_wnum(debug_wb_rf_wnum),
			.debug_wb_rf_wdata(debug_wb_rf_wdata),
			
			.EXL(EXL),
			.ExcCodeOut(ExcCode),
			.BD(BD),
			.EPC(EPC),
			.VAddr(VAddr),
			.back(back),
			.backPC(backPC),
			.CP0Addr(CP0Addr),
			.CP0RD(CP0RD),
			.CP0WD(CP0WD),
			.CP0We(CP0We)
		);
	
	CP0 cp0(
			.clk(clk),
			.reset(~resetn),
			.en(CP0We),
			.CP0ADD(CP0Addr),
			.CP0In(CP0WD),
			.CP0Out(CP0RD),
			.EXLSet(EXL),
			.VPC(EPC),				// i, pc of victim inst
			.VAddr(VAddr),			// i, BadVAddr
			.BDIn(BD),
			.ExcCodeIn(ExcCode),
			.HWInt(ext_int),
			.EXLClr(back),
			.EPCOut(backPC),
			.Req(require)
		);
	
endmodule
