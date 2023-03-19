`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/11 08:42:03
// Design Name: 
// Module Name: MMU
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


module MMU(
    input  [31: 0] cpu_inst_addr,	
    output [31:12] inst_tag,		
    output [11: 4] inst_index,		
    output [ 3: 0] inst_offset, 	
    output         inst_cache,		
    input  [31: 0] cpu_data_addr,	
    output [31:12] data_tag,		
    output [11: 4] data_index,		
    output [ 3: 0] data_offset, 	
    output         data_cache		
);

    assign inst_cache = cpu_inst_addr[31:28] >= 4'b1000 && cpu_inst_addr[31:28] <= 4'b1001;
    assign data_cache = cpu_data_addr[31:28] >= 4'b1000 && cpu_data_addr[31:28] <= 4'b1001;

    wire [31:0] phs_inst_addr = cpu_inst_addr & 32'h1fffffff;
    wire [31:0] phs_data_addr = cpu_data_addr & 32'h1fffffff;

    assign inst_tag    = phs_inst_addr[31:12];
    assign inst_index  = phs_inst_addr[11: 4];
    assign inst_offset = phs_inst_addr[ 3: 0];

    assign data_tag    = phs_data_addr[31:12];
    assign data_index  = phs_data_addr[11: 4];
    assign data_offset = phs_data_addr[ 3: 0]; 
endmodule
