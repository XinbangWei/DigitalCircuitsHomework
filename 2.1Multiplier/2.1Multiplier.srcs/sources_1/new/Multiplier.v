`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/15 21:52:57
// Design Name: 
// Module Name: Multiplier
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


module multiplier_display (
    input clk,
    input [7:0] sw,           // SW[3:0] = A, SW[7:4] = B
    output reg [6:0] seg,     // 7段数码管段选
    output reg [3:0] an       // 4位数码管位选
);
    // === 输入分离 ===
    wire [3:0] a = sw[3:0];
    wire [3:0] b = sw[7:4];

    // === 移位相加乘法 ===
    reg [7:0] result = 0;
    reg [7:0] multiplicand;
    reg [3:0] multiplier;
    reg [3:0] count = 0;
    reg [7:0] accumulator = 0;

    always @(posedge clk) begin
        if (count == 0) begin
            multiplicand <= {4'b0000, a};
            multiplier <= b;
            accumulator <= 0;
            count <= 4;
        end else begin
            if (multiplier[0] == 1)
                accumulator <= accumulator + multiplicand;
            multiplicand <= multiplicand << 1;
            multiplier <= multiplier >> 1;
            count <= count - 1;
        end
        result <= accumulator;
    end

    // === 二进制转BCD ===
    reg [3:0] hundreds, tens, ones;
    reg [19:0] shift;
    integer i;

    always @(*) begin
        shift = 20'd0;
        shift[7:0] = result;

        for (i = 0; i < 8; i = i + 1) begin
            if (shift[11:8] >= 5) shift[11:8] = shift[11:8] + 3;
            if (shift[15:12] >= 5) shift[15:12] = shift[15:12] + 3;
            if (shift[19:16] >= 5) shift[19:16] = shift[19:16] + 3;
            shift = shift << 1;
        end

        hundreds = shift[19:16];
        tens     = shift[15:12];
        ones     = shift[11:8];
    end

    // === 数码管显示 ===
    reg [15:0] clkdiv;
    reg [3:0] digit;

    always @(posedge clk)
        clkdiv <= clkdiv + 1;

    always @(*) begin
        case (clkdiv[15:14])  // 控制显示的哪一位
            2'b00: begin an = 4'b1110; digit = ones; end
            2'b01: begin an = 4'b1101; digit = tens; end
            2'b10: begin an = 4'b1011; digit = hundreds; end
            default: begin an = 4'b1111; digit = 4'd0; end
        endcase

        case (digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end
endmodule