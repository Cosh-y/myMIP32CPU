/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/

module cpu_axi_interface
(
    input         clk,
    input         resetn, 

    //inst sram-like 
    // input         inst_req     ,
    // input         inst_wr      ,
    // input  [1 :0] inst_size    ,
    // input  [31:0] inst_addr    ,
    // input  [31:0] inst_wdata   ,
    // output [31:0] inst_rdata   ,
    // output        inst_addr_ok ,
    // output        inst_data_ok ,
    
    //inst rd Cache <-> AXI
    input          inst_rd_req  ,        // Cache发出的读请求有效信号
    input  [ 2: 0] inst_rd_type ,
    input  [31: 0] inst_rd_addr ,
    output         inst_rd_rdy  ,        // 读请求能否被接收的握手信号
    output         inst_ret_valid,       // 返回数据有效
    output         inst_ret_last,
    output [31: 0] inst_ret_data, 
    //data rd Cache <-> AXI
    input          data_rd_req  ,        // Cache发出的读请求有效信号
    input  [ 2: 0] data_rd_type ,
    input  [31: 0] data_rd_addr ,
    output         data_rd_rdy  ,        // 读请求能否被接收的握手信号
    output         data_ret_valid,       // 返回数据有效
    output         data_ret_last,
    output [31: 0] data_ret_data,
    //data wr Cache <-> AXI
    input          data_wr_req  ,        // Cache发出的写请求有效信号
    input  [ 2: 0] data_wr_type ,
    input  [31: 0] data_wr_addr ,
    input  [ 3: 0] data_wr_wstrb,
    input  [127:0] data_wr_data ,
    output         data_wr_rdy  ,        // 写请求能否被接收的握手信号，先于wr_req置起; AXI总线内16字节缓存为空时置起

    //data sram-like 
    // input         data_req     ,
    // input         data_wr      ,
    // input  [1 :0] data_size    ,
    // input  [31:0] data_addr    ,
    // input  [31:0] data_wdata   ,
    // output [31:0] data_rdata   ,
    // output        data_addr_ok ,
    // output        data_data_ok ,

    //axi <-> DRAM
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock        ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,        // the slave can accept the write data
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,        // 只有写请求和写数据最后一次传输被从方接收后，才会返回写响应
    output        bready       
);

//inst sram-like 
wire        inst_req     ;
wire        inst_wr      ;
wire [1 :0] inst_size    ;
wire [31:0] inst_addr    ;
wire [31:0] inst_wdata   ;
// wire [31:0] inst_rdata   ; // .o
// wire        inst_addr_ok ; // .o
// wire        inst_data_ok ; // .o

assign inst_req = inst_rd_req;
assign inst_wr = 0;         // inst 永远只读
assign inst_size = 2'b10;   // 2'b10 refers to 4bytes 1word 是不是2'b10存疑
assign inst_addr = inst_rd_addr;
assign inst_wdata = 0;
assign inst_ret_data = rdata;

//data sram-like 
wire        data_req     ;
wire        data_wr      ;
wire [1 :0] data_size    ;
wire [31:0] data_addr    ;
wire [31:0] data_wdata   ;
// wire [31:0] data_rdata   ; // .o
// wire        data_addr_ok ; // .o
// wire        data_data_ok ; // .o

assign data_req = data_rd_req | data_wr_req;
assign data_wr = (data_wr_req) ? 1 : 0;
assign data_size = 2'b10;
assign data_addr = (data_wr_req) ? data_wr_addr : data_rd_addr;
assign data_wdata = (w_index == 0) ? data_wr_data[31:0] : w_store[w_index*32 +: 32];
assign data_ret_data = rdata;

reg [3:0]   w_index;
reg [127:0] w_store;
always @(posedge clk) begin
    if (!resetn || data_wr_req) begin
        w_index <= 0;
        w_store <= data_wr_data;
    end
    else if (wvalid && wready && w_index <= awlen) begin
        w_index <= w_index + 1;
    end
    else if (bvalid)begin
        w_index <= 0;
    end
end

//addr
reg do_req;
reg do_req_or; //req is inst or data;1:data,0:inst
reg        do_wr_r;
reg [1 :0] do_size_r;
reg [2 :0] do_type;
reg [31:0] do_addr_r;
reg [31:0] do_wdata_r;
wire data_back;

// 这里addr_ok其实是没有延迟的，即只要此时没有等待数据读出或写入的请求就置1
// 这里如果同时有data_req和inst_req先处理data_req
// assign inst_addr_ok = !do_req&&!data_req;
// assign data_addr_ok = !do_req;
always @(posedge clk)
begin
    // do_req 从发出请求到本次transaction结束置1
    do_req     <= !resetn                       ? 1'b0 : 
                  (inst_req||data_req)&&!do_req ? 1'b1 :
                  data_back                     ? 1'b0 : do_req;
    // 保存这次请求是data sram (1)的还是inst sram (0)的 
    do_req_or  <= !resetn ? 1'b0 : 
                  !do_req ? data_req : do_req_or;
    // 保存这次请求是读请求还是写请求
    do_wr_r    <= data_req&&!do_req ? data_wr :
                  inst_req&&!do_req ? inst_wr : do_wr_r;
    // 保存这次请求的读写数据大小
    do_size_r  <= data_req&&!do_req ? data_size :
                  inst_req&&!do_req ? inst_size : do_size_r;
    // 保存这次请求的读写类型，指导发起arlen, arsize, awlen, awsize
    do_type    <= data_req&&!do_req ? (data_wr ? data_wr_type : data_rd_type) :
                  inst_req&&!do_req ? inst_rd_type : do_type;
    // 这里在发出请求的第一拍把addr保存了，对于CPU来说请求地址已经成功发出
    do_addr_r  <= data_req&&!do_req ? data_addr :
                  inst_req&&!do_req ? inst_addr : do_addr_r;
    // 同样在发出请求的第一拍保存了写数据
    // do_wdata_r <= data_req&&data_addr_ok ? data_wdata :
    //               inst_req&&inst_addr_ok ? inst_wdata :do_wdata_r;
end

//inst sram-like
// assign inst_data_ok = do_req&&!do_req_or&&data_back;
// assign data_data_ok = do_req&& do_req_or&&data_back;
// assign inst_rdata   = rdata;

assign data_wr_rdy    = !do_req;

assign data_rd_rdy    = !do_req && !data_wr_req;              // 读请求能否被接收的握手信号
assign data_ret_valid = rvalid && do_req_or;      // 返回数据有效
assign data_ret_last  = rlast && do_req_or;      // 
assign data_ret_data  = rdata;

assign inst_rd_rdy    = !do_req && !data_req;        // 读请求能否被接收的握手信号
assign inst_ret_valid = rvalid && !do_req_or;       // 返回数据有效
assign inst_ret_last  = rlast && !do_req_or;
assign inst_ret_data  = rdata; 

//---axi
reg addr_rcv;
reg wdata_rcv;

// 上一个地址握手后，第一个结束响应
assign data_back = addr_rcv && (rvalid&&rlast&&rready||bvalid&&bready);        // 读请求数据握手 || 写请求响应握手
always @(posedge clk)
begin
    addr_rcv  <= !resetn          ? 1'b0 :                          // 请求的地址被slave接受后置1，arready表示slave准备好接受地址传输
                 arvalid&&arready ? 1'b1 :                          // 读请求地址握手
                 awvalid&&awready ? 1'b1 :                          // 写请求地址握手
                 data_back        ? 1'b0 : addr_rcv;
    wdata_rcv <= !resetn        ? 1'b0 :                            // 写请求的数据被slave接受后置1，wready表示
                 bvalid&&bready ? 1'b1 :                            // 写请求数据握手   
                 data_back      ? 1'b0 : wdata_rcv;
end
//ar
assign arid    = 4'd0;
assign araddr  = do_addr_r;
assign arlen   = (do_type == 3'b100) ? 8'h03 : 0;
assign arsize  = 3'b010;
assign arburst = 2'd1;
assign arlock  = 2'd0;
assign arcache = 4'd0;
assign arprot  = 3'd0;
assign arvalid = do_req&&!do_wr_r&&!addr_rcv;   // 读地址有效当 有读请求且地址仍未被接受
//r
assign rready  = 1'b1;                          // master 时刻准备接受读数据

//aw
assign awid    = 4'd0;
assign awaddr  = do_addr_r;
assign awlen   = (do_type == 3'b100) ? 8'h03 : 0;                          // the number of data transfers
assign awsize  = (do_type == 3'b100 || do_type == 3'b010) ? 3'b010 : 
                 (do_type == 3'b001) ? 3'b001 : 3'b000;
assign awburst = 2'd1;
assign awlock  = 2'd0;
assign awcache = 4'd0;
assign awprot  = 3'd0;
assign awvalid = do_req&&do_wr_r&&!addr_rcv;    // 写地址有效当 有写请求且地址仍未被接受
//w
assign wid    = 4'd0;
assign wdata  = data_wdata;
assign wstrb  = (do_type == 3'b000) ? 4'b0001<<do_addr_r[1:0] :
                (do_type == 3'b001) ? 4'b0011<<do_addr_r[1:0] : 4'b1111;
assign wlast  = do_type == 3'b100 ? (w_index == 4'd3) : 1;
assign wvalid = do_req&&do_wr_r&&(w_index <= awlen);                // 写数据有效当 有写请求
//b
assign bready  = 1'b1;

endmodule

