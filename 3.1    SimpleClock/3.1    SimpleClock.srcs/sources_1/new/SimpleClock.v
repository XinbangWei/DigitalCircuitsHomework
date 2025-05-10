`timescale 1ns/1ps
module digital_clock_100M (
    input           clk,        // 100 MHz 系统时钟
    input           rst_n,      // 异步复位，低有效
    output reg [7:0] seg,       // seg[6:0]=A~G 段, seg[7]=DP
    output reg [7:0] an         // 位选 8 位
);

    // -- 1Hz 分频 (100MHz -> 1Hz) --
    reg [26:0] clk_cnt;
    wire       pulse_1hz;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_cnt <= 27'd0;
        else if (clk_cnt == 27'd100_000_000 - 1)
            clk_cnt <= 27'd0;
        else
            clk_cnt <= clk_cnt + 1'b1;
    end
    assign pulse_1hz = (clk_cnt == 27'd100_000_000 - 1);

    // -- 0.5s DP 闪烁 --
    reg blink;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            blink <= 1'b0;
        else if (clk_cnt == 27'd0)
            blink <= 1'b1;
        else if (clk_cnt == 27'd50_000_000)
            blink <= 1'b0;
    end

    // -- 时分秒计数 --
    reg [5:0] sec, min;
    reg [4:0] hr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sec <= 6'd0; min <= 6'd0; hr <= 5'd0;
        end else if (pulse_1hz) begin
            if (sec == 6'd59) begin
                sec <= 6'd0;
                if (min == 6'd59) begin
                    min <= 6'd0;
                    hr  <= (hr == 5'd23) ? 5'd0 : hr + 1'b1;
                end else
                    min <= min + 1'b1;
            end else
                sec <= sec + 1'b1;
        end
    end

    // -- BCD 分解 --
    wire [3:0] d0 = sec  % 10;  // 秒低
    wire [3:0] d1 = sec  / 10;  // 秒高
    wire [3:0] d2 = min  % 10;  // 分低
    wire [3:0] d3 = min  / 10;  // 分高
    wire [3:0] d4 = hr   % 10;  // 时低
    wire [3:0] d5 = hr   / 10;  // 时高

    // -- 7 段译码函数 --
    function [6:0] seg_map;
        input [3:0] v;
        case (v)
            4'd0: seg_map = 7'b1000000;
            4'd1: seg_map = 7'b1111001;
            4'd2: seg_map = 7'b0100100;
            4'd3: seg_map = 7'b0110000;
            4'd4: seg_map = 7'b0011001;
            4'd5: seg_map = 7'b0010010;
            4'd6: seg_map = 7'b0000010;
            4'd7: seg_map = 7'b1111000;
            4'd8: seg_map = 7'b0000000;
            4'd9: seg_map = 7'b0010000;
            default: seg_map = 7'b1111111;
        endcase
    endfunction

    // -- 多路扫描 (~125Hz/位) --
    reg [16:0] refresh_cnt;
    reg [2:0]  scan_idx;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_cnt <= 17'd0;
            scan_idx    <= 3'd0;
        end else if (refresh_cnt == 17'd100_000 - 1) begin
            refresh_cnt <= 17'd0;
            scan_idx    <= scan_idx + 1'b1;
        end else
            refresh_cnt <= refresh_cnt + 1'b1;
    end

    // -- 输出: 00.00.00,隐藏末两位 --
    always @(*) begin
        an  = 8'b11111111;
        seg = 8'b11111111;
        case (scan_idx)
            3'd7: begin an[7]=1'b0; seg[6:0]=seg_map(d5); seg[7]=1'b1; end  // 时高 (不闪)
            3'd6: begin an[6]=1'b0; seg[6:0]=seg_map(d4); seg[7]=blink; end  // 时低, DP闪烁(冒号)
            3'd5: begin an[5]=1'b0; seg[6:0]=seg_map(d3); seg[7]=1'b1; end  // 分高
            3'd4: begin an[4]=1'b0; seg[6:0]=seg_map(d2); seg[7]=blink; end  // 分低, DP闪烁(冒号)
            3'd3: begin an[3]=1'b0; seg[6:0]=seg_map(d1); seg[7]=1'b1; end  // 秒高
            3'd2: begin an[2]=1'b0; seg[6:0]=seg_map(d0); seg[7]=1'b1; end  // 秒低
            default: begin /* scan_idx 1,0 隐藏 */ end
        endcase
    end

endmodule
