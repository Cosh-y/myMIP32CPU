`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/21 08:18:06
// Design Name: 
// Module Name: Cache_mem
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


module Cache_mem(
    input clk,
    input reset,

    input  [31:12] wtag       ,
    input  [7:0]   index      ,
    input  [3:0]   offset     ,
    input          hit        ,
    input          refill     ,
    input  [3:0]   wstrb      ,
    input  [31: 0] w_data     ,
    input  [127:0] refill_data,
    input          set_D      ,
    output         v          ,         // 替换时一次性写入128位 即一行(块), Store请求时一次写入32位
    output [31:12] rtag       ,
    output [127:0] rdata      ,
    output         D          
    );

    reg D_file [0:255];
    integer i;
    always@(posedge clk) begin
        if(reset) begin
            for(i=0;i<256;i=i+1) begin
                D_file[i] <= 0;
            end
        end
        else if(set_D && (hit || refill)) begin
            D_file[index] <= 1;
        end
    end
    assign D = D_file[index];

    wire wea = refill; //refill?

    TagV_RAM TagV (
        .clka   (clk        ),                                 // input wire clka
        .wea    (wea        ),                                     // input wire [0 : 0] wea
        .addra  (index      ),                                  // input wire [7 : 0] addra
        .dina   ({wtag, 1'b1}),                                    // input wire [20 : 0] dina
        .douta  ({rtag, v}  )                                // output wire [20 : 0] douta
    );


    wire [3:0] wea0 = (hit && offset[3:2] == 2'b00) ? wstrb :
                      (refill) ? 4'b1111 : 0;
    wire [31:0] dina0 = (hit) ? w_data : refill_data[31:0];
    Bank_RAM bank0 (
        .clka   (clk        ),                  // input wire clka
        .wea    (wea0       ),                 // input wire [3 : 0] wea
        .addra  (index      ),               // input wire [7 : 0] addra
        .dina   (dina0      ),                     // input wire [31 : 0] dina
        .douta  (rdata[31:0])          // output wire [31 : 0] douta
    );

    wire [3:0] wea1 = (hit && offset[3:2] == 2'b01) ? wstrb :
                      (refill) ? 4'b1111 : 0;
    wire [31:0] dina1 = (hit) ? w_data : refill_data[63:32];
    Bank_RAM bank1 (
        .clka   (clk        ),          // input wire clka
        .wea    (wea1       ),          // input wire [3 : 0] wea
        .addra  (index      ),          // input wire [7 : 0] addra
        .dina   (dina1      ),          // input wire [31 : 0] dina
        .douta  (rdata[63:32])          // output wire [31 : 0] douta
    );

    wire [3:0] wea2 = (hit && offset[3:2] == 2'b10) ? wstrb :
                      (refill) ? 4'b1111 : 0;
    wire [31:0] dina2 = (hit) ? w_data : refill_data[95:64];
    Bank_RAM bank2 (
        .clka   (clk        ),          // input wire clka
        .wea    (wea2       ),          // input wire [3 : 0] wea
        .addra  (index      ),          // input wire [7 : 0] addra
        .dina   (dina2      ),          // input wire [31 : 0] dina
        .douta  (rdata[95:64])          // output wire [31 : 0] douta
    );

    wire [3:0] wea3 = (hit && offset[3:2] == 2'b11) ? wstrb :
                      (refill) ? 4'b1111 : 0;
    wire [31:0] dina3 = (hit) ? w_data : refill_data[127:96];
    Bank_RAM bank3 (
        .clka   (clk        ),           // input wire clka
        .wea    (wea3       ),           // input wire [3 : 0] wea
        .addra  (index      ),           // input wire [7 : 0] addra
        .dina   (dina3      ),           // input wire [31 : 0] dina
        .douta  (rdata[127:96])          // output wire [31 : 0] douta
    );

endmodule
