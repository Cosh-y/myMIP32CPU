`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:11:41 12/01/2022 
// Design Name: 
// Module Name:    CP0 
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
`define IE 		SR[0]
`define EXL 	SR[1]
`define IM 		SR[15:8]
`define BD 		Cause[31]
`define IP 		Cause[15:10]
`define softIP 	Cause[9:8]
`define ExcCode Cause[6:2]

module CP0(
	input clk,
	input reset,
	input en,
	input [4:0] CP0ADD,   	    // 寄存器地址
	input [31:0] CP0In,			// CP0写入数据
	output [31:0] CP0Out,		// CP0读出数据
	input EXLSet,				// 用来置位EXL
	input [31:0] VPC,			// 受害PC
	input [31:0] VAddr,			// BadVAddr
	input BDIn,					// 是否是延迟槽指令
	input [4:0] ExcCodeIn,		// 记录异常类型
	input [5:0] HWInt,			// 输入中断信号
	input EXLClr,				// 用来复位EXL
	output [31:0] EPCOut,		// EPC的值
	output Req					// 进入处理程序请求
    );
	 
	reg [31:0] BadVAddr, Count, Compare, SR, Cause, EPC; //编号分别为8, 9, 11, 12, 13, 14
	
	wire interrupt, inner_interrupt;
	assign inner_interrupt = (Count == Compare);
	assign interrupt = (`EXL == 1 || `IE == 0) ? 0 : 
						(Cause[8] == 1 && SR[8]  == 1) ? 1 :
						(Cause[9] == 1 && SR[9]  == 1) ? 1 :
						(HWInt[0] == 1 && SR[10] == 1) ? 1 :
						(HWInt[1] == 1 && SR[11] == 1) ? 1 :
						(HWInt[2] == 1 && SR[12] == 1) ? 1 :
						(HWInt[3] == 1 && SR[13] == 1) ? 1 :
						(HWInt[4] == 1 && SR[14] == 1) ? 1 :
						(HWInt[5] == 1 && SR[15] == 1) ? 1 :
						(inner_interrupt == 1 && SR[15] == 1) ? 1 : 0;
							 
	assign Req = (interrupt == 1) ? 1 :
					(EXLSet == 1) ? 1 : 0;
					 
	always@(posedge clk) begin
		if(reset) begin
			SR <= 32'h00400000;
			Cause <= 0;
			EPC <= 0;
			BadVAddr <= 0;
		end
		else begin
			`IP <= HWInt | {inner_interrupt, 5'b0};
			if(interrupt == 1) begin
				`EXL <= 1;
				`ExcCode <= 0;
				`BD <= BDIn;
				if(BDIn == 1) EPC <= VPC - 4;
				else EPC <= VPC;
			end
			else if(EXLSet == 1) begin
				`BD <= BDIn;
				`ExcCode <= ExcCodeIn;
				`EXL <= 1;
				if(BDIn == 1) EPC <= VPC - 4;
				else EPC <= VPC;
				if(ExcCodeIn == 5'b00100 || ExcCodeIn == 5'b00101) BadVAddr <= VAddr;
				else BadVAddr <= BadVAddr;
			end
			else if(EXLClr == 1) begin
				`EXL <= 0;
			end
			else if(en == 1) begin
				case(CP0ADD)
					5'b01011: begin
						Compare <= CP0In;
					end
					5'b01100: begin
						`IE <= CP0In[0];
						`EXL <= CP0In[1];
						`IM <= CP0In[15:8];
						Cause <= Cause;
						EPC <= EPC;
					end
					5'b01101: begin
						SR <= SR;
						`BD <= CP0In[31];
						`IP <= CP0In[15:10];
						`softIP <= CP0In[9:8];
						`ExcCode <= CP0In[6:2];
						EPC <= EPC;
					end
					5'b01110: begin
						SR <= SR;
						Cause <= Cause;
						EPC <= CP0In;
					end
					default: ;
				endcase
			end
			else begin
				SR <= SR;
				Cause <= Cause;
				EPC <= EPC;
				BadVAddr <= BadVAddr;
			end
		end

		if(reset) begin
			Count <= 0;
		end
		else if(en == 1 && CP0ADD == 5'b01001) begin
			Count <= CP0In;
		end
		else Count <= Count + 1;
	end
	
	assign CP0Out = (CP0ADD == 5'b01000) ? BadVAddr :
					(CP0ADD == 5'b01001) ? Count :
					(CP0ADD == 5'b01011) ? Compare :
					(CP0ADD == 5'b01100) ? SR :
					(CP0ADD == 5'b01101) ? Cause :
					(CP0ADD == 5'b01110) ? EPC : 0;
	assign EPCOut = EPC;
endmodule
