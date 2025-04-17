`timescale 1ns / 1ps

module multiplier_display (
    input clk,
    input [7:0] sw,           // SW[3:0] = A, SW[7:4] = B
    output reg [6:0] seg,     // 数码管段选
    output reg [3:0] an       // 数码管位选
);

    // === 输入同步 ===
    reg [7:0] sw_sync_0, sw_sync_1;
    always @(posedge clk) begin
        sw_sync_0 <= sw;
        sw_sync_1 <= sw_sync_0;
    end
    wire [7:0] sw_stable = sw_sync_1;
    wire [3:0] a = sw_stable[3:0];
    wire [3:0] b = sw_stable[7:4];

    // === 检测输入变化 ===
    reg [7:0] prev_sw = 0;
    wire input_changed = (sw_stable != prev_sw);

    // === 状态机定义 ===
    reg [3:0] state = 0;
    parameter IDLE = 0, TRIGGER = 1, CALC = 2, DONE = 3;

    reg [7:0] multiplicand;
    reg [3:0] multiplier;
    reg [7:0] accumulator;
    reg [3:0] count;
    reg [7:0] result = 0;

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                if (input_changed) begin
                    prev_sw <= sw_stable;
                    state <= TRIGGER;
                end
            end
            TRIGGER: begin
                multiplicand <= {4'b0000, a};
                multiplier <= b;
                accumulator <= 0;
                count <= 4;
                state <= CALC;
            end
            CALC: begin
                if (count > 0) begin
                    if (multiplier[0])
                        accumulator <= accumulator + multiplicand;
                    multiplicand <= multiplicand << 1;
                    multiplier <= multiplier >> 1;
                    count <= count - 1;
                end else begin
                    result <= accumulator;
                    state <= DONE;
                end
            end
            DONE: begin
                state <= IDLE;
            end
        endcase
    end

    // === BCD 转换 ===
    reg [19:0] shift;
    reg [3:0] hundreds, tens, ones;
    integer i;

    always @(*) begin
        shift = 0;
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

    // === 数码管动态刷新（死区 + 空白帧）===
    reg [15:0] clkdiv = 0;
    reg [2:0] scan_idx = 0;
    reg [3:0] digit;

    always @(posedge clk) begin
        clkdiv <= clkdiv + 1;
        scan_idx <= clkdiv[15:13];
    end

    always @(*) begin
        an = 4'b1111;
        seg = 7'b1111111;

        case (scan_idx)
            3'd0: begin an = 4'b1110; digit = ones; end
            3'd1: begin an = 4'b1101; digit = tens; end
            3'd2: begin an = 4'b1011; digit = hundreds; end
            3'd3: begin an = 4'b1111; digit = 4'd0; end  // 空白帧
            3'd7: begin an = 4'b1111; digit = 4'd0; end  // 死区
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