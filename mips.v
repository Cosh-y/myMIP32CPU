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
	input [5:0] ext_int,
	
	input aclk,
	input aresetn,

	output [3:0] arid	,
	output [31:0] araddr,
	output [3:0] arlen	,
	output [2:0] arsize	,
	output [1:0] arburst,
	output [1:0] arlock	,
	output [3:0] arcache,
	output [2:0] arprot	,
	output 		 arvalid,
	input 		 arready,

	input [3:0]  rid	,
	input [31:0] rdata  ,
	input [1:0]  rresp  ,
	input 		 rlast	,
	input 		 rvalid ,
	output 		 rready ,

	output [3:0] awid	,
	output [31:0] awaddr,
	output [3:0] awlen	,
	output [2:0] awsize	,
	output [1:0] awburst,
	output [1:0] awlock	,
	output [3:0] awcache,
	output [2:0] awprot ,
	output 		 awvalid,
	input 		 awready,

	output [3:0] wid	,
	output [31:0] wdata	,
	output [3:0] wstrb	,
	output 		 wlast	,
	output 		 wvalid ,
	input 		 wready ,

	input [3:0] bid		,
	input [1:0] bresp	,
	input 		bvalid  ,
	output 		bready  ,

	output [31:0] debug_wb_pc		,
	output  [3:0] debug_wb_rf_wen	,
	output  [4:0] debug_wb_rf_wnum	,
	output [31:0] debug_wb_rf_wdata
);

	wire        cpu_inst_req     ;
    wire        cpu_inst_wr      ;
    wire [1 :0] cpu_inst_size    ;
    wire [31:0] cpu_inst_addr    ;
    wire [31:0] cpu_inst_wdata   ;
    wire [31:0] cpu_inst_rdata   ;
    wire        cpu_inst_addr_ok ;
    wire        cpu_inst_data_ok ;

	wire        cpu_data_req     ;
    wire        cpu_data_wr      ;
    wire [1 :0] cpu_data_size    ;
    wire [31:0] cpu_data_addr    ;
    wire [31:0] cpu_data_wdata   ;
    wire [31:0] cpu_data_rdata   ;
    wire        cpu_data_addr_ok ;
    wire        cpu_data_data_ok ;

	cpu_axi_interface cpu_axi_interface(
		.clk		  (aclk				),
		.resetn	 	  (aresetn			),

		.inst_req     (cpu_inst_req     ),
		.inst_wr      (cpu_inst_wr      ),
		.inst_size    (cpu_inst_size    ),
		.inst_addr    (cpu_inst_addr    ),
		.inst_wdata   (cpu_inst_wdata   ),
		.inst_rdata   (cpu_inst_rdata   ),
		.inst_addr_ok (cpu_inst_addr_ok ),
		.inst_data_ok (cpu_inst_data_ok ),
		
		//data sram-like 
		.data_req     (cpu_data_req     ),
		.data_wr      (cpu_data_wr      ),
		.data_size    (cpu_data_size    ),
		.data_addr    (cpu_data_addr    ),
		.data_wdata   (cpu_data_wdata   ),
		.data_rdata   (cpu_data_rdata   ),
		.data_addr_ok (cpu_data_addr_ok ),
		.data_data_ok (cpu_data_data_ok ),

		//axi
		//ar
		.arid         (arid    ),
		.araddr       (araddr  ),
		.arlen        (arlen   ),
		.arsize       (arsize  ),
		.arburst      (arburst ),
		.arlock       (arlock  ),
		.arcache      (arcache ),
		.arprot       (arprot  ),
		.arvalid      (arvalid ),
		.arready      (arready ),
		//r           
		.rid          (rid     ),
		.rdata        (rdata   ),
		.rresp        (rresp   ),
		.rlast        (rlast   ),
		.rvalid       (rvalid  ),
		.rready       (rready  ),
		//aw          
		.awid         (awid    ),
		.awaddr       (awaddr  ),
		.awlen        (awlen   ),
		.awsize       (awsize  ),
		.awburst      (awburst ),
		.awlock       (awlock  ),
		.awcache      (awcache ),
		.awprot       (awprot  ),
		.awvalid      (awvalid ),
		.awready      (awready ),
		//w          
		.wid          (wid     ),
		.wdata        (wdata   ),
		.wstrb        (wstrb   ),
		.wlast        (wlast   ),
		.wvalid       (wvalid  ),
		.wready       (wready  ),
		//b           
		.bid          (bid     ),
		.bresp        (bresp   ),
		.bvalid       (bvalid  ),
		.bready       (bready  )
	);

	wire [31:0] EPC, VAddr;
	wire EXL;
	wire [4:0] ExcCode;
	wire BD;
	wire require;
	wire [4:0] CP0Addr;
	wire [31:0] CP0RD, CP0WD, backPC;
	wire CP0We, back;

	CPU cpu(
		.clk		  (aclk				),
		.reset		  (~aresetn			),
		.respon		  (require			),

		.inst_req	  (cpu_inst_req     ),
		.inst_wr	  (cpu_inst_wr      ),
		.inst_size    (cpu_inst_size    ),
		.inst_addr    (cpu_inst_addr    ),
		.inst_wstrb   (),
		.inst_wdata   (cpu_inst_wdata   ),
		.inst_rdata   (cpu_inst_rdata   ),
		.inst_addr_ok (cpu_inst_addr_ok ),
		.inst_data_ok (cpu_inst_data_ok ),

		.data_req     (cpu_data_req     ),
		.data_wr      (cpu_data_wr      ),
		.data_size    (cpu_data_size    ),
		.data_addr    (cpu_data_addr    ),
		.data_wstrb   (),
		.data_wdata   (cpu_data_wdata   ),
		.data_rdata   (cpu_data_rdata   ),
		.data_addr_ok (cpu_data_addr_ok ),
		.data_data_ok (cpu_data_data_ok ),

		.debug_wb_pc		(debug_wb_pc	  ),
		.debug_wb_rf_wen	(debug_wb_rf_wen  ),
		.debug_wb_rf_wnum	(debug_wb_rf_wnum ),
		.debug_wb_rf_wdata	(debug_wb_rf_wdata),
		
		.EXL		  (EXL),
		.ExcCodeOut	  (ExcCode),
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
		.clk(aclk),
		.reset(~aresetn),
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
