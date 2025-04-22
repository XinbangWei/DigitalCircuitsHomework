`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/09 22:58:32
// Design Name: 
// Module Name: Adder
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


module full_adder_8bit(
    input        clk,    // 系统时钟
    input        rst,    // 异步复位，高电平有效
    input  [7:0] a,      // 8位输入
    input        sel,    // 控制信号：
                         // sel = 0：更新存储的旧值，同时输出当前 a（或作为复位操作）
                         // sel = 1：不更新存储，输出 新 a 与之前存储的 a 相加的结果（加进位）
    input        cin,    // 进位输入
    output reg [8:0] sum   // 9位输出（含进位）
);

reg [7:0] stored_a;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        stored_a <= 8'b0;
        sum      <= 9'b0;
    end else begin
        if (sel == 1'b0) begin
            // 当 sel 为低时，将当前输入 a 存储下来，并直接输出 a
            stored_a <= a;
            sum <= {1'b0, a} + cin;  // 将 a 扩展到9位后输出
        end else begin
            // 当 sel 为高时，不更新 stored_a，
            // 输出新输入 a 与之前存储的 stored_a 的和（加上 cin）
            sum <= a + stored_a + cin;
        end
    end
end

endmodule