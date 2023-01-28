`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:15:25 11/17/2022 
// Design Name: 
// Module Name:    macro 
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
`define aluAdd      4'b0000
`define aluSub      4'b0001
`define aluOr       4'b0010
`define aluAnd      4'b0011
`define aluSlt      4'b0100
`define aluSltu     4'b0101
`define aluSL       4'b0110     //ShiftLeft
`define aluSR       4'b0111     //ShiftRight
`define aluASR      4'b1000     //ArithmeticShiftRight
`define aluNOR      4'b1001
`define aluXOR      4'b1010
`define aluFree     4'b1111

`define none 4'b0000
`define ALUM_rdD 4'b0001
`define LAddrM_rdD 4'b0010
`define HLE_rdD 4'b0011
`define HLM_rdD 4'b0100
`define CP0M_rdD 4'b0101

`define ALUM_ALUAB 4'b0001
`define wdW_ALUAB 4'b0010
`define LAddrM_ALUAB 4'b0011
`define HLM_ALUAB 4'b0100
`define CP0M_ALUAB 4'b0101

`define fullWord 2'b00
`define halfWord 2'b01
`define quatWord 2'b10

`define MemOut_fullWord 3'b000
`define MemOut_half_signExt 3'b001
`define MemOut_half_zeroExt 3'b010
`define MemOut_quat_signExt 3'b011  // quarter
`define MemOut_quat_zeroExt 3'b100