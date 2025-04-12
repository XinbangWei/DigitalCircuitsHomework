`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/10 23:10:18
// Design Name: 
// Module Name: 8sel1
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


module MUX(
input [2:0] sel, // 选择信号
input [7:0] in, // 8路输入信号
output reg out // 输出信号
);

always @(sel) begin
case(sel)
3'b000: out <= in[0];
3'b001: out <= in[1];
3'b010: out <= in[2];
3'b011: out <= in[3];
3'b100: out <= in[4];
3'b101: out <= in[5];
3'b110: out <= in[6];
3'b111: out <= in[7];
endcase
end

endmodule