`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/10 23:26:13
// Design Name: 
// Module Name: ShiftRegister
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

module clk_divider(
    input clk_in,        // 原始 100MHz 时钟
    input rst,
    output reg clk_out   // 降频后的慢时钟
);

reg [25:0] count;

always @(posedge clk_in or posedge rst) begin
    if (rst) begin
        count <= 0;
        clk_out <= 0;
    end else begin
        if (count == 50_000_000) begin  // 100MHz ÷ 2 = 50M 周期为半秒
            count <= 0;
            clk_out <= ~clk_out;       // 翻转输出，每翻一次是半秒，一正一负 = 1秒
        end else begin
            count <= count + 1;
        end
    end
end

endmodule


module ShiftReg(
    input        clk,      // 系统时钟（例如经过分频后降低频率以便观察）
    input        rst,      // 异步复位，高电平有效
    input        start,    // 启动移位。当 start 为高时，每个时钟沿执行移位操作
    input        dir,      // 移位方向：1 表示左移，0 表示右移
    input        mode,     // 移位模式：1 表示循环移位，0 表示逻辑移位
    input  [3:0] d,        // 数据输入（用于并行加载）
    input        load,     // 加载使能。load 为高时，将 d 加载到寄存器
    output reg [3:0] q     // 4 位寄存器输出
);

// 例程：移位寄存器
// 如果 load 为高，则 q 被 d 并行加载；
// 如果 start 为高且 load 为低，则每个时钟沿根据信号 dir 和 mode 来移位；
// 否则，保持 q 不变。
always @(posedge clk or posedge rst) begin
    if (rst) begin
        q <= 4'b0;
    end else begin
        if (load) begin
            // 并行加载优先级最高
            q <= d;
        end else if (start) begin
            // 进行移位操作
            if (dir) begin  // 左移
                if (mode) begin
                    // 循环左移：将最高位 q[3] 移入最低位
                    q <= {q[2:0], q[3]};
                end else begin
                    // 逻辑左移：最低位补 0
                    q <= {q[2:0], 1'b0};
                end
            end else begin  // 右移（dir == 0）
                if (mode) begin
                    // 循环右移：将最低位 q[0] 移入最高位
                    q <= {q[0], q[3:1]};
                end else begin
                    // 逻辑右移：最高位补 0
                    q <= {1'b0, q[3:1]};
                end
            end
        end
        // 如果 start 为低且 load 为低，则 q 保持不变（不执行移位）
    end
end

endmodule

module top(
    input clk,           // 板子上的 100MHz 时钟
    input rst,
    input shift_en,
    output [3:0] q
);

wire slow_clk;

clk_divider u_div (
    .clk_in(clk),
    .rst(rst),
    .clk_out(slow_clk)
);

ShiftReg (
    .clk(slow_clk),
    .rst(rst),
    .shift_en(shift_en),
    .q(q)
);

endmodule

