`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/10 21:25:20
// Design Name: 
// Module Name: Decoder
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


module Decoder(
input [2:0] data_i, // 3位输入数据
input [2:0] en_i, // 3位使能信号
output reg [7:0] data_o // 8位输出数据
);

always @(*) begin
if(en_i[0] || en_i[1] || !en_i[2]) // 使能信号检测
data_o = 8'b1111_1111; // 使能无效时输出全高
else
case (data_i) // 根据输入数据选择输出
3'b000: data_o = 8'b1111_1110;
3'b001: data_o = 8'b1111_1101;
3'b010: data_o = 8'b1111_1011;
3'b011: data_o = 8'b1111_0111;
3'b100: data_o = 8'b1110_1111;
3'b101: data_o = 8'b1101_1111;
3'b110: data_o = 8'b1011_1111;
3'b111: data_o = 8'b0111_1111;
endcase
end

endmodule