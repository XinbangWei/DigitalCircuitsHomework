`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: debounce
// Description: 对按钮信号进行去抖处理，输出稳定信号
//////////////////////////////////////////////////////////////////////////////////
module debounce(
    input clk,           // 默认时钟，例如 100MHz
    input rst,
    input noisy_in,      // 原始（可能有抖动的）按钮信号
    output reg clean_out // 去抖后的稳定信号
);
    reg [127:0] shift_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            clean_out <= 0;
        end else begin
            shift_reg <= {shift_reg[126:0], noisy_in};
            // 当连续16个采样周期全为1时，认为按钮确实按下；全为0时认为释放
            if (shift_reg == 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                clean_out <= 1;
            else if (shift_reg == 128'h0000000000000000000000000000000)
                clean_out <= 0;
        end
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Module: configurable_shift_reg_4bit
// Description: 4位移位寄存器，支持：
//   - 并行加载（通过 load 按钮触发加载外部数据 d）
//   - 按钮触发一次性移位操作（通过 start 按钮边沿检测触发移位）
//   - 移位方向（dir：1 左移，0 右移）
//   - 移位模式（mode：1 循环移位，0 逻辑移位，补0）
//////////////////////////////////////////////////////////////////////////////////
module configurable_shift_reg_4bit(
    input clk,            // 默认时钟，100MHz
    input rst,
    input start,          // 去抖后的移位按钮信号
    input load,           // 去抖后的加载按钮信号
    input dir,            // 移位方向，1：左移，0：右移
    input mode,           // 移位模式，1：循环移位，0：逻辑移位（补0）
    input [3:0] d,        // 并行加载数据
    output reg [3:0] q    // 寄存器输出
);
    // 边沿检测：对 start 按钮
    reg start_d;
    wire start_pulse = ~start_d & start;  // 检测到上升沿时产生脉冲

    // 边沿检测：对 load 按钮
    reg load_d;
    wire load_pulse = ~load_d & load;     // 检测到上升沿时产生脉冲

    // 对 start 和 load 信号分别进行延时采样
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            start_d <= 0;
            load_d <= 0;
        end else begin
            start_d <= start;
            load_d <= load;
        end
    end

    // 移位寄存器逻辑
    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 4'b0000;
        else if (load_pulse)
            q <= d;       // 优先并行加载
        else if (start_pulse) begin
            // 根据移位方向和模式进行一次性移位操作
            if (dir) begin  // 左移
                if (mode)
                    q <= {q[2:0], q[3]}; // 循环左移
                else
                    q <= {q[2:0], 1'b0}; // 逻辑左移（补0）
            end else begin    // 右移
                if (mode)
                    q <= {q[0], q[3:1]}; // 循环右移
                else
                    q <= {1'b0, q[3:1]}; // 逻辑右移（补0）
            end
        end
        // 如果既没有加载也没有检测到移位脉冲，则保持寄存器 q 不变
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Module: top
// Description: 顶层模块，采用默认 100MHz 时钟。
//   - 按钮 btn_start_raw 和 btn_load_raw 分别用于移位和并行加载。
//   - 这些原始信号经过去抖模块生成稳定信号，再传入移位寄存器模块。
//   - 控制信号 dir 与 mode 可通过开关设置，d 为4位数据输入，q 输出到LED显示。
//////////////////////////////////////////////////////////////////////////////////
module top(
    input clk_100mhz,    // Nexys A7 板上的 100MHz 时钟
    input rst,           // 外部复位信号（建议使用一个独立的复位按钮），低/高电平请与设计匹配
    input btn_start_raw, // 原始移位触发按钮信号（例如 BTNC）
    input btn_load_raw,  // 原始加载按钮信号
    input dir,           // 移位方向开关，1=左移，0=右移
    input mode,          // 移位模式开关，1=循环移位，0=逻辑移位
    input [3:0] d,       // 4位并行加载数据（可通过拨码开关输入）
    output [3:0] q       // 4个LED 输出移位寄存器内容
);
    wire btn_start_clean;
    wire btn_load_clean;
    
    // 对移位按钮进行去抖处理
    debounce u_debounce_start(
        .clk(clk_100mhz),
        .rst(rst),
        .noisy_in(btn_start_raw),
        .clean_out(btn_start_clean)
    );
    
    // 对加载按钮进行去抖处理
    debounce u_debounce_load(
        .clk(clk_100mhz),
        .rst(rst),
        .noisy_in(btn_load_raw),
        .clean_out(btn_load_clean)
    );
    
    // 实例化可配置移位寄存器模块
    configurable_shift_reg_4bit u_shift_reg(
        .clk(clk_100mhz),
        .rst(rst),
        .start(btn_start_clean),
        .load(btn_load_clean),
        .dir(~dir),
        .mode(mode),
        .d(d),
        .q(q)
    );
    
endmodule
