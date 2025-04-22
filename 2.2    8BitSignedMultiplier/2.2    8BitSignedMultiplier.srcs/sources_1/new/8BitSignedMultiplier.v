`timescale 1ns / 1ps

module multiplier_display_signed8 (
    input             clk,
    input      [15:0] sw,      // SW[7:0]=A (signed), SW[15:8]=B (signed)
    output reg  [6:0] seg,     // 七段显示段选
    output reg  [5:0] an       // 七段显示位选（6 位）
);

    // === 输入同步 ===
    reg [15:0] sw_sync_0, sw_sync_1;
    always @(posedge clk) begin
        sw_sync_0 <= sw;
        sw_sync_1 <= sw_sync_0;
    end
    wire [15:0] sw_stable = sw_sync_1;

    // === 有符号输入 ===
    wire signed [7:0] a = sw_stable[7:0];
    wire signed [7:0] b = sw_stable[15:8];

    // === 直接乘法运算 ===
    wire signed [15:0] prod = a * b;

    // === BCD 转换：16 位绝对值 -> 5 位十进制 ===
    reg [35:0] shift;
    reg  [3:0] digit0, digit1, digit2, digit3, digit4;
    integer    i;
    always @(*) begin
        // 加载绝对值
        shift = 36'd0;
        if (prod < 0)
            shift[15:0] = -prod;
        else
            shift[15:0] = prod;
        // Double Dabble 算法
        for (i = 0; i < 16; i = i + 1) begin
            if (shift[35:32] >= 5) shift[35:32] = shift[35:32] + 3;
            if (shift[31:28] >= 5) shift[31:28] = shift[31:28] + 3;
            if (shift[27:24] >= 5) shift[27:24] = shift[27:24] + 3;
            if (shift[23:20] >= 5) shift[23:20] = shift[23:20] + 3;
            if (shift[19:16] >= 5) shift[19:16] = shift[19:16] + 3;
            shift = shift << 1;
        end
        digit4 = shift[35:32];  // 万位
        digit3 = shift[31:28];  // 千位
        digit2 = shift[27:24];  // 百位
        digit1 = shift[23:20];  // 十位
        digit0 = shift[19:16];  // 个位
    end

    // === 数码管刷新：5 位数字 + 1 位符号 ===
    reg [20:0] clkdiv;
    reg  [2:0] scan_idx;
    reg  [3:0] cur_digit;

    always @(posedge clk) begin
        clkdiv   <= clkdiv + 1;
        scan_idx <= clkdiv[20:18];
    end

    always @(*) begin
        an = 6'b111111;
        case (scan_idx)
            3'd0: begin an[0] = 1'b0; cur_digit = digit0; end
            3'd1: begin an[1] = 1'b0; cur_digit = digit1; end
            3'd2: begin an[2] = 1'b0; cur_digit = digit2; end
            3'd3: begin an[3] = 1'b0; cur_digit = digit3; end
            3'd4: begin an[4] = 1'b0; cur_digit = digit4; end
            3'd5: begin
                an[5] = 1'b0;
                // 符号位：负号用 '-'，正数空白
                if (prod < 0)
                    cur_digit = 4'hE;
                else
                    cur_digit = 4'hF;
            end
            default: cur_digit = 4'hF;
        endcase

        // 段码映射
        case (cur_digit)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hE: seg = 7'b0111111; // '-'
            default: seg = 7'b1111111; // 空白
        endcase
    end
endmodule
