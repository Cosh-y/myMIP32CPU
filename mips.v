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
	wire [3 :0] cpu_inst_wstrb	 ;
    wire [31:0] cpu_inst_wdata   ;
    wire [31:0] cpu_inst_rdata   ;
    wire        cpu_inst_addr_ok ;
    wire        cpu_inst_data_ok ;

	wire [31:12] mmu_inst_tag	 ;
	wire [11: 4] mmu_inst_index  ;
	wire [ 3: 0] mmu_inst_offset ;
	wire 		 mmu_inst_cache  ;

	wire        cpu_data_req     ;
    wire        cpu_data_wr      ;
    wire [1 :0] cpu_data_size    ;
    wire [31:0] cpu_data_addr    ;
	wire [3 :0] cpu_data_wstrb	 ;
    wire [31:0] cpu_data_wdata   ;
    wire [31:0] cpu_data_rdata   ;
    wire        cpu_data_addr_ok ;
    wire        cpu_data_data_ok ;

	wire [31:12] mmu_data_tag	 ;
	wire [11: 4] mmu_data_index  ;
	wire [ 3: 0] mmu_data_offset ;
	wire 		 mmu_data_cache  ;

	wire  		 inst_rd_req	 ;
	wire [ 2: 0] inst_rd_type  	 ;
	wire [31: 0] inst_rd_addr  	 ;
	wire 		 inst_rd_rdy	 ;
	wire 		 inst_ret_valid  ;
	wire 		 inst_ret_last	 ;
	wire [31: 0] inst_ret_data	 ;

	wire  		 data_rd_req	 ;
	wire [ 2: 0] data_rd_type  	 ;
	wire [31: 0] data_rd_addr  	 ;
	wire 		 data_rd_rdy	 ;
	wire 		 data_ret_valid  ;
	wire 		 data_ret_last	 ;
	wire [31: 0] data_ret_data	 ;
	wire 		 data_wr_req	 ;		
	wire [ 2: 0] data_wr_type	 ;	
	wire [31: 0] data_wr_addr	 ;	
	wire [ 3: 0] data_wr_wstrb 	 ;
	wire [127:0] data_wr_data	 ;	
	wire  		 data_wr_rdy     ;		

	cpu_axi_interface cpu_axi_interface(
		.clk		  (aclk				),
		.resetn	 	  (aresetn			),

		// .inst_req     (cpu_inst_req     ),
		// .inst_wr      (cpu_inst_wr      ),
		// .inst_size    (cpu_inst_size    ),
		// .inst_addr    (cpu_inst_addr    ),
		// .inst_wdata   (cpu_inst_wdata   ),
		// .inst_rdata   (cpu_inst_rdata   ),
		// .inst_addr_ok (cpu_inst_addr_ok ),
		// .inst_data_ok (cpu_inst_data_ok ),
		
		// //data sram-like 
		// .data_req     (cpu_data_req     ),
		// .data_wr      (cpu_data_wr      ),
		// .data_size    (cpu_data_size    ),
		// .data_addr    (cpu_data_addr    ),
		// .data_wdata   (cpu_data_wdata   ),
		// .data_rdata   (cpu_data_rdata   ),
		// .data_addr_ok (cpu_data_addr_ok ),
		// .data_data_ok (cpu_data_data_ok ),

		//inst rd Cache <-> AXI
		.inst_rd_req    (inst_rd_req    ),        // Cache发出的读请求有效信号
		.inst_rd_type   (inst_rd_type   ),
		.inst_rd_addr   (inst_rd_addr   ),
		.inst_rd_rdy    (inst_rd_rdy    ),        // 读请求能否被接收的握手信号
		.inst_ret_valid (inst_ret_valid ),       // 返回数据有效
		.inst_ret_last  (inst_ret_last	),
		.inst_ret_data  (inst_ret_data	), 
		//data rd Cache <-> AXI
		.data_rd_req  	(data_rd_req	),        // Cache发出的读请求有效信号
		.data_rd_type 	(data_rd_type   ),
		.data_rd_addr 	(data_rd_addr   ),
		.data_rd_rdy  	(data_rd_rdy	),        // 读请求能否被接收的握手信号
		.data_ret_valid (data_ret_valid ),       // 返回数据有效
		.data_ret_last  (data_ret_last	),
		.data_ret_data  (data_ret_data	),
		//data wr Cache <-> AXI
		.data_wr_req   (data_wr_req		),        // Cache发出的写请求有效信号
		.data_wr_type  (data_wr_type	),
		.data_wr_addr  (data_wr_addr	),
		.data_wr_wstrb (data_wr_wstrb	),
		.data_wr_data  (data_wr_data	),
		.data_wr_rdy   (data_wr_rdy		),        // 写请求能否被接收的握手信号，先于wr_req置起; AXI总线内16字节缓存为空时置起

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

	Cache dCache(
		.clk	   (aclk),			
		.reset	   (~aresetn),
		
		// CPU - Cache
		.valid     (cpu_data_req	),
		.uncache   (!mmu_data_cache ),
		.op        (cpu_data_wr		),
		.index     (mmu_data_index  ),
		.tag       (mmu_data_tag 	),
		.offset    (mmu_data_offset ),
		.wstrb     (cpu_data_wstrb	),
		.wdata     (cpu_data_wdata	),
		.addr_ok   (cpu_data_addr_ok),
		.data_ok   (cpu_data_data_ok),
		.rdata     (cpu_data_rdata	),

		// Cache - AXI
		.rd_req    (data_rd_req	  	),
		.rd_type   (data_rd_type  	),
		.rd_addr   (data_rd_addr  	),
		.rd_rdy    (data_rd_rdy	 	),
		.ret_valid (data_ret_valid	),
		.ret_last  (data_ret_last	),
		.ret_data  (data_ret_data	),
		.wr_req    (data_wr_req		),
		.wr_type   (data_wr_type	),
		.wr_addr   (data_wr_addr	),
		.wr_wstrb  (data_wr_wstrb	),
		.wr_data   (data_wr_data	),
		.wr_rdy    (data_wr_rdy		)
	);

	Cache iCache(
		.clk	   (aclk),			
		.reset	   (~aresetn),
		
		// CPU - Cache
		.valid     (cpu_inst_req	),
		.uncache   (!mmu_inst_cache ),
		.op        (cpu_inst_wr		),
		.index     (mmu_inst_index  ),
		.tag       (mmu_inst_tag 	),
		.offset    (mmu_inst_offset ),
		.wstrb     (cpu_inst_wstrb	),
		.wdata     (cpu_inst_wdata	),
		.addr_ok   (cpu_inst_addr_ok),
		.data_ok   (cpu_inst_data_ok),
		.rdata     (cpu_inst_rdata	),

		// Cache - AXI
		.rd_req    (inst_rd_req	  	),
		.rd_type   (inst_rd_type  	),
		.rd_addr   (inst_rd_addr  	),
		.rd_rdy    (inst_rd_rdy	 	),
		.ret_valid (inst_ret_valid	),
		.ret_last  (inst_ret_last	),
		.ret_data  (inst_ret_data	),
		.wr_req    (),
		.wr_type   (),
		.wr_addr   (),
		.wr_wstrb  (),
		.wr_data   (),
		.wr_rdy    (1)
	);

	MMU mmu(
		.cpu_inst_addr	(cpu_inst_addr 	),
		.inst_tag		(mmu_inst_tag	),
		.inst_index		(mmu_inst_index ),
		.inst_offset	(mmu_inst_offset),
		.inst_cache		(mmu_inst_cache ),
		.cpu_data_addr	(cpu_data_addr  ),
		.data_tag		(mmu_data_tag	),
		.data_index		(mmu_data_index ),
		.data_offset	(mmu_data_offset),
		.data_cache		(mmu_data_cache )
	);

	CPU cpu(
		.clk		  (aclk				),
		.reset		  (~aresetn			),
		.respon		  (require			),

		.inst_req	  (cpu_inst_req     ),
		.inst_wr	  (cpu_inst_wr      ),
		.inst_size    (cpu_inst_size    ),
		.inst_addr    (cpu_inst_addr    ),
		.inst_wstrb   (cpu_inst_wstrb	),
		.inst_wdata   (cpu_inst_wdata   ),
		.inst_rdata   (cpu_inst_rdata   ),
		.inst_addr_ok (cpu_inst_addr_ok ),
		.inst_data_ok (cpu_inst_data_ok ),

		.data_req     (cpu_data_req     ),
		.data_wr      (cpu_data_wr      ),
		.data_size    (cpu_data_size    ),
		.data_addr    (cpu_data_addr    ),
		.data_wstrb   (cpu_data_wstrb 	),
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
