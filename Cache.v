`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/20 10:56:35
// Design Name: 
// Module Name: Cache
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define IDLE    4'b0000
`define WRITE   4'b0001
`define LOOKUP  4'b0001
`define MISS    4'b0010
`define REPLACE 4'b0011
`define REFILL  4'b0100

module Cache(
    input clk,
    input reset,
    
    // CPU - Cache
    input          valid   ,        // 表明请求有效
    input          uncache ,        // 为1则表示这条读写指令是Uncache的
    input          op      ,        // 操作类型，0 = 读
    input  [11: 4] index   ,        // 虚拟地址的[11:4]位
    input  [31:12] tag     ,        // 物理地址的高20位
    input  [ 3: 0] offset  ,
    input  [ 3: 0] wstrb   ,
    input  [31: 0] wdata   ,
    output         addr_ok ,
    output         data_ok ,
    output [31: 0] rdata   ,

    // Cache - AXI
    output         rd_req  ,        // Cache发出的读请求有效信号
    output [ 2: 0] rd_type ,        // 读请求类型，似乎是规定读多少内容的
    output [31: 0] rd_addr ,
    input          rd_rdy  ,        // 读请求能否被接收的握手信号
    input          ret_valid,       // 返回数据有效
    input          ret_last,
    input  [31: 0] ret_data,
    output reg     wr_req  ,        // Cache发出的写请求有效信号
    output [ 2: 0] wr_type ,
    output [31: 0] wr_addr ,
    output [ 3: 0] wr_wstrb,
    output [127:0] wr_data ,
    input          wr_rdy           // 写请求能否被接收的握手信号，先于wr_req置起; AXI总线内16字节缓存为空时置起
);
    
    wire Cache_hit;
    reg Hazard;

    // 主状态机
    reg [3:0] m_status;             // 主状态机状态寄存器
    always@(posedge clk) begin
        if(reset) begin
            m_status <= `IDLE;
        end
        else begin
            case (m_status)
                `IDLE: begin
                    if(valid && !Hazard) begin             // 空闲时间如果接收到有效Cache访问，并且与Hit Write没有写后读冲突，进入查找并判断Hit的LOOKUP状态
                        m_status <= `LOOKUP;
                    end
                end
                `LOOKUP: begin
                    if(Cache_hit && !valid) begin   // 查找的访问hit了，且没有新的访问(或者有但是与Hit Write冲突)需要查找，就进入空闲时间IDLE
                        m_status <= `IDLE;
                    end
                    else if(Cache_hit && valid && !Hazard) begin   // 查找的访问hit了，并且有新的访问需要查找
                        m_status <= `LOOKUP;
                    end
                    else if(!Cache_hit) begin
                        m_status <= `MISS;
                    end
                end
                `MISS: begin
                    if(!wr_rdy) begin
                        m_status <= `MISS;
                    end
                    else begin
                        m_status <= `REPLACE;   // MISS下，当看到wr_rdy为1, 应发起读取Cache内将被替换行的读请求，并转换到REPLACE状态
                    end
                end
                `REPLACE: begin                 // REPLACE阶段应该把被替换的脏行写回RAM，如果是脏的的话
                    if(!rd_rdy) begin
                        m_status <= `REPLACE;
                    end
                    else begin
                        m_status <= `REFILL;    // REPLACE下，rd_rdy == 1表明Cache发起的对缺失行(块 block)的读请求可以被接收了，进入REFILL
                    end
                end
                `REFILL: begin
                    if(refill_wen) begin // 最后一组读数据返回的下一拍进入IDLE, 完成缺失替换
                        m_status <= `IDLE;
                    end
                    else if (rb_uncache && rb_op) begin
                        m_status <= `IDLE;
                    end
                    else if (rb_uncache && !rb_op && ret_valid) begin
                        m_status <= `IDLE;
                    end
                    else begin
                        m_status <= `REFILL;
                    end
                end
            endcase
        end
    end

    // 写操作状态机
    reg [3:0] w_status;
    always@(posedge clk) begin
        if(reset) begin
            w_status <= `IDLE;
        end
        else begin
            case (w_status)
                `IDLE: begin
                    if(m_status == `LOOKUP && Cache_hit && rb_op) begin // Write Buffer没有待写的数据并且主状态机发现新的Hit Write
                        w_status <= `WRITE;
                    end
                    else w_status <= `IDLE;
                end 
                `WRITE: begin
                    if(m_status == `LOOKUP && Cache_hit && rb_op) begin
                        w_status <= `WRITE;     // Write Buffer有待写的数据且主状态机发现新的Hit Write
                    end
                    else w_status <= `IDLE;     // Write Buffer有待写的数据且主状态机没有新的Hit Write
                end
            endcase
        end
    end

    // 冲突判断
    always @(*) begin
        if (m_status == `LOOKUP && Cache_hit && valid && !op) begin
            if (rb_tag == tag && rb_index == index && rb_offset[3:2] == offset[3:2]) begin
                Hazard = 1;
            end
            else begin
                Hazard = 0;
            end
        end
        else if (m_status == `IDLE && |wb_wstrb && valid && !op) begin
            if (wb_tag == tag && wb_index == index && wb_offset[3:2] == offset[3:2]) begin
                Hazard = 1;
            end
            else begin
                Hazard = 0;
            end
        end
        else Hazard = 0;
    end

    // LFSR
    wire way_to_replace;
    LFSR lfsr(
        .clk            (clk            ),
        .reset          (reset          ),
        .q              (               ),
        .way_to_replace (way_to_replace )
    );

    // Request Buffer
    reg         rb_uncache;
    reg         rb_op     ;
    reg [11: 4] rb_index  ;
    reg [31:12] rb_tag    ;
    reg [ 3: 0] rb_offset ;
    reg [ 3: 0] rb_wstrb  ;
    reg [31: 0] rb_wdata  ;
    always@(posedge clk) begin
        if(valid && ((m_status == `IDLE && !Hazard) || (m_status == `LOOKUP && Cache_hit && !Hazard))) begin
            rb_uncache<= uncache;
            rb_op     <= op     ;       // 保存请求，为在下一拍对比tag确定命中与否
            rb_index  <= index  ;
            rb_tag    <= tag    ;
            rb_offset <= offset ; 
            rb_wstrb  <= wstrb  ;     
            rb_wdata  <= wdata  ;
        end
    end

    // Miss Buffer
    reg [ 1: 0] ret_num         ;
    reg         replace_way     ;
    reg [127:0] dirt_data       ;
    reg         isDirt          ;
    reg [127:0] ret_data_store  ;
    wire         refill_wen     ;               // refill时的写使能
    wire [127:0] replace_data   ;               // 准备写回内存的脏数据
    wire [127:0] refill_data    ;               // 准备写入Cache的新数据
    assign refill_wen = (ret_valid && ret_last && !rb_uncache);
    assign refill_data = (rb_op == 0) ? {ret_data, ret_data_store[127:32]} : 
        (rb_offset[3:2] == 2'b00) ? {ret_data, ret_data_store[127:64], rb_wdata} :
        (rb_offset[3:2] == 2'b01) ? {ret_data, ret_data_store[127:96], rb_wdata, ret_data_store[63:32]} :
        (rb_offset[3:2] == 2'b10) ? {ret_data, rb_wdata, ret_data_store[95:32]} : {rb_wdata, ret_data_store[127:32]};
    always @(posedge clk) begin
        if (m_status == `LOOKUP && !Cache_hit) begin
            ret_num         <= 0            ;
            isDirt          <= replace_dirt ;             // 保存脏位
            dirt_data       <= replace_data ;             // 保存脏数据准备写回内存
            ret_data_store  <= 0            ;
            replace_way     <=  way_to_replace;           // 保存 LFSR 确定要替换的路号
        end
        else if (ret_valid && ret_num < 2'b11 && !rb_uncache) begin // 
            ret_data_store <= {ret_data, ret_data_store[127:32]};
            ret_num <= ret_num + 1;
        end
    end
    // 完成写回操作
    assign wr_addr = (rb_uncache) ? {rb_tag, rb_index, rb_offset} :
                                    {rb_tag, rb_index, 4'b0000  } ;      // 这里我们写内存需要物理地址
    assign wr_data = (rb_uncache) ? {96'b0, rb_wdata} : dirt_data;                          // 一次性向AXI传回128位
    assign wr_wstrb = {4{isDirt && wr_req}};              // 为何不是整行读写        另外，因为wr_req是保证了wr_rdy == 1是置高的，所以必然能写入
    assign wr_type = !rb_uncache ? 3'b100 :
                     (wb_wstrb == 4'b1111) ? 3'b010 :
                     (wb_wstrb == 4'b1100 || wb_wstrb == 4'b0011) ? 3'b001 : 3'b000;


    // Write Buffer
    reg         wb_way0_hit;
    reg         wb_way1_hit;
    reg [31:12] wb_tag    ;
    reg [11: 4] wb_index  ;
    reg [ 3: 0] wb_offset ;
    reg [ 3: 0] wb_wstrb  ;
    reg [31: 0] wb_wdata  ;
    always@(posedge clk) begin
        if(reset) begin
            wb_wstrb    <= 0;
            wb_way0_hit <= 0;
            wb_way1_hit <= 0;
            wb_tag      <= 0;
            wb_index    <= 0;
            wb_offset   <= 0;
            wb_wstrb    <= 0;
            wb_wdata    <= 0;
        end
        else if(m_status == `LOOKUP && Cache_hit && rb_op) begin
            wb_way0_hit <= (way0_hit);
            wb_way1_hit <= (way1_hit);
            wb_tag      <= rb_tag    ;
            wb_index    <= rb_index  ;
            wb_offset   <= rb_offset ;
            wb_wstrb    <= rb_wstrb  ;
            wb_wdata    <= rb_wdata  ;
        end
        else begin
            wb_wstrb    <= 0;
            wb_way0_hit <= 0;
            wb_way1_hit <= 0;
        end 
    end

    wire way0_hit, way1_hit;

    wire [3 : 0] way_wstrb;
    wire [11: 4] way_index;
    // wire [ 3: 0] way_offset;
    wire [31:12] way_wtag ;
    wire         way_setD ;
    assign way_index = (m_status == `IDLE) ? index : 
                       (|wb_wstrb) ? wb_index : rb_index;
    // assign way_offset= (|wb_wstrb) ? wb_offset: rb_offset;
    assign way_wstrb = (|wb_wstrb) ? wb_wstrb : rb_wstrb;
    assign way_wtag  = (|wb_wstrb) ? wb_tag   : rb_tag  ;
    assign way_setD  = (|wb_wstrb) ? 1        : 
                       (refill_wen && rb_op)  ? 1 : 0   ;
    
    wire way0_refill = (refill_wen && replace_way == 0);
    wire way1_refill = (refill_wen && replace_way == 1);

    wire [31:12] way0_tag, way1_tag;        // 这一组为从两路里读出的内容
    wire         way0_v, way1_v;
    wire [127:0] way0_rdata, way1_rdata;
    wire         way0_D, way1_D;
    wire [31:0]  way0_load_word, way1_load_word;

    Cache_mem way0_mem(
        .clk(clk),
        .reset(reset),

        .wtag       (way_wtag       ),
        .index      (way_index      ),
        .offset     (wb_offset      ),
        .hit        (wb_way0_hit    ),
        .refill     (way0_refill    ),
        .wstrb      (way_wstrb      ),             // wstrb有两个来源，rb和wb
        .w_data     (wb_wdata       ),             //正常写入，32位
        .refill_data(refill_data    ),             //替换写入，128位
        .set_D      (way_setD       ),
        .v          (way0_v         ),
        .rtag       (way0_tag       ),
        .rdata      (way0_rdata     ),
        .D          (way0_D         )
    );

    Cache_mem way1_mem(
        .clk(clk),
        .reset(reset),

        .wtag       (way_wtag       ),
        .index      (way_index      ),
        .offset     (wb_offset      ),
        .hit        (wb_way1_hit    ),
        .refill     (way1_refill    ),
        .wstrb      (way_wstrb      ),             // wstrb有两个来源，rb和wb
        .w_data     (wb_wdata       ),             //正常写入，32位
        .refill_data(refill_data    ),             //替换写入，128位
        .set_D      (way_setD       ),
        .v          (way1_v         ),
        .rtag       (way1_tag       ),
        .rdata      (way1_rdata     ),
        .D          (way1_D         )
    );

    assign way0_hit = (m_status == `LOOKUP && rb_tag == way0_tag && way0_v && !rb_uncache);
    assign way1_hit = (m_status == `LOOKUP && rb_tag == way1_tag && way1_v && !rb_uncache);
    assign Cache_hit = (way0_hit | way1_hit) && !rb_uncache;

    assign way0_load_word = way0_rdata[rb_offset[3:2]*32 +: 32];
    assign way1_load_word = way1_rdata[rb_offset[3:2]*32 +: 32];
    assign rdata = {32{way0_hit}} & way0_load_word | {32{way1_hit}} & way1_load_word | {32{!way0_hit & !way1_hit}} & ret_data;
    assign replace_data = (way_to_replace == 0) ? way0_load_word : way1_load_word;
    assign replace_dirt = (way_to_replace == 0) ? way0_D : way1_D;

    assign addr_ok = (m_status == `IDLE) | (m_status == `LOOKUP && Cache_hit && valid && !Hazard);      // | 后面的条件还需加入 !Write_Hazard
    assign data_ok = (m_status == `LOOKUP && Cache_hit) | (m_status == `LOOKUP && rb_op) |
                     (m_status == `REFILL && ret_valid && ret_num == rb_offset[3:2] && !rb_op) | 
                     (m_status == `REFILL && ret_valid && rb_uncache && !rb_op);
                                                            // 待填充的条件是Miss Buffer中记录的返回字个数与Cache缺失地址的[3:2]相等
    assign rd_req = (m_status == `REPLACE && !(rb_uncache && rb_op));                 // 在REPLACE阶段进行脏位的写回 并且随时发出读取替换数据的读请求(AXI 总线的 rd_rdy不一定接收)
    assign rd_type = (rb_uncache) ? 3'b010 : 3'b100;           // uncache的读，读一个字节，否则读一个cache行
    assign rd_addr = (rb_uncache) ? {rb_tag, rb_index, rb_offset}
                                  : {rb_tag, rb_index, 4'b0000} ;
    // wr_req
    always@(posedge clk) begin
        if(reset) begin
            wr_req <= 0;
        end
        else if(m_status == `MISS && wr_rdy && isDirt && !(rb_uncache && !rb_op)) begin
            wr_req <= 1;
        end
        else if(m_status == `MISS && wr_rdy && rb_uncache && rb_op) begin
            wr_req <= 1;
        end
        else if(wr_rdy) begin
            wr_req <= 0;
        end
    end
endmodule
