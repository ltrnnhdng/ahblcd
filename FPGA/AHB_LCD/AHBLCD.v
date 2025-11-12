`timescale 1ns / 1ps

// Module ?i?u khi?n LCD 4-bit, ho?t ??ng nh? m?t AHB-Lite Slave
module AHBLCD #(
    // ?? r?ng xung E, tính b?ng s? chu k? HCLK.
    // Ví d?: HCLK = 50MHz (20ns). 50 chu k? = 1us (1000ns).
    // Ki?m tra datasheet ST7066U (trang 32/33, T_PW)
    parameter E_PULSE_CYCLES = 50
) (
    // --- Giao di?n Bus AHB-Lite (Slave) ---
    input  wire        HCLK,      // Clock h? th?ng
    input  wire        HRESETn,   // Reset (active-low)
    input  wire        HSEL,      // Tín hi?u ch?n module
    input  wire [31:0] HADDR,     // ??a ch?
    input  wire [31:0] HWDATA,    // D? li?u ghi
    input  wire        HWRITE,    // 1 = Ghi
    input  wire [1:0]  HTRANS,    // Lo?i
    input  wire        HREADY,    // Tín hi?u Ready t? master/mux
    output wire [31:0] HRDATA,    // D? li?u ??c (không dùng)
    output wire        HREADYOUT, // Tín hi?u Ready c?a slave (1=s?n sàng)

    // --- Giao di?n V?t lý t?i Màn hình LCD ---
    output reg         LCD_RS,    // Chân Register Select
    output wire        LCD_RW,    // Chân Read/Write
    output reg         LCD_E,     // Chân Enable
    output reg  [3:0]  LCD_DB     // Bus d? li?u 4-bit (ch? DB4-DB7)
);

    // ??nh ngh?a các tr?ng thái FSM
    localparam [3:0]
        S_IDLE          = 4'h0,
        S_HI_SETUP      = 4'h1,
        S_HI_PULSE_UP   = 4'h2,
        S_HI_PULSE_HOLD = 4'h3,
        S_HI_PULSE_DOWN = 4'h4,
        S_LO_SETUP      = 4'h5,
        S_LO_PULSE_UP   = 4'h6,
        S_LO_PULSE_HOLD = 4'h7,
        S_LO_PULSE_DOWN = 4'h8;
        
    localparam [7:0] lcd_ins_addr = 8'h00;
    localparam [7:0] lcd_data_addr = 8'h04;
  
    // Các thanh ghi n?i b?
    reg [3:0] fsm_state;
    reg [$clog2(E_PULSE_CYCLES + 1):0] counter;
    reg [7:0] lcd_data_reg; // Thanh ghi ??m cho 8 bit
    reg       lcd_rs_reg;   // Thanh ghi ??m cho RS

    // Tín hi?u cho logic t? h?p
    wire ahb_write_req;

    // --- Logic T? h?p ---

    // Yêu c?u ghi AHB h?p l?
    assign ahb_write_req = (HSEL == 1'b1) &&
                           (HREADY == 1'b1) &&
                           (HWRITE == 1'b1) &&
                           (HTRANS == 2'b10 || HTRANS == 2'b11);

    // HREADYOUT = 1 (s?n sàng) CH? KHI FSM ?ang ? S_IDLE
    // N?u FSM b?n (?ang g?i 2 nibble), HREADYOUT = 0, "stall" bus AHB
    assign HREADYOUT = (fsm_state == S_IDLE);

    // Gán các ??u ra c? ??nh
    assign LCD_RW = 1'b0;           // Luôn luôn GHI vào LCD
    assign HRDATA = 32'h00000000; // Không h? tr? ??c t? LCD

    // --- Logic Tu?n t? (FSM và Thanh ghi) ---
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            // Reset
            fsm_state    <= S_IDLE;
            counter      <= 0;
            lcd_data_reg <= 8'h00;
            lcd_rs_reg   <= 1'b0;
            LCD_RS       <= 1'b0;
            LCD_E        <= 1'b0;
            LCD_DB       <= 4'h0;
        end else begin
            // Logic máy tr?ng thái
            case (fsm_state)
                S_IDLE: begin
                    LCD_E <= 1'b0;
                    if (ahb_write_req) begin
                        // CPU ?ã ghi! Latch d? li?u và RS
                        lcd_data_reg <= HWDATA[7:0];
                        
                        // Gi?i mã ??a ch? ?? ??t RS
                        // Offset 0x00 (HADDR[2]=0) là L?nh
                        // Offset 0x04 (HADDR[2]=1) là D? li?u
                        if (HADDR[7:0] == lcd_ins_addr) begin
                            lcd_rs_reg <= 1'b0;
                        end 
                        else if(HADDR[7:0] == lcd_data_addr) begin
                            lcd_rs_reg <= 1'b1;
                        end
                        
                        // Chuy?n sang tr?ng thái g?i
                        fsm_state <= S_HI_SETUP;
                    end
                end

                // G?i 4-bit cao
                S_HI_SETUP: begin
                    LCD_RS <= lcd_rs_reg;
                    LCD_DB <= lcd_data_reg[7:4];
                    LCD_E  <= 1'b0;
                    fsm_state <= S_HI_PULSE_UP;
                end

                S_HI_PULSE_UP: begin
                    LCD_E <= 1'b1;
                    counter <= 0; // B?t ??u ??m
                    fsm_state <= S_HI_PULSE_HOLD;
                end

                S_HI_PULSE_HOLD: begin
                    LCD_E <= 1'b1;
                    if (counter < E_PULSE_CYCLES) begin
                        counter <= counter + 1;
                    end else begin
                        fsm_state <= S_HI_PULSE_DOWN;
                    end
                end

                S_HI_PULSE_DOWN: begin
                    LCD_E <= 1'b0; // C?nh xu?ng -> LCD ch?t d? li?u
                    fsm_state <= S_LO_SETUP;
                end

                // G?i 4-bit th?p
                S_LO_SETUP: begin
                    LCD_RS <= lcd_rs_reg;
                    LCD_DB <= lcd_data_reg[3:0];
                    LCD_E  <= 1'b0;
                    fsm_state <= S_LO_PULSE_UP;
                end

                S_LO_PULSE_UP: begin
                    LCD_E <= 1'b1;
                    counter <= 0; // B?t ??u ??m
                    fsm_state <= S_LO_PULSE_HOLD;
                end

                S_LO_PULSE_HOLD: begin
                    LCD_E <= 1'b1;
                    if (counter < E_PULSE_CYCLES) begin
                        counter <= counter + 1;
                    end else begin
                        fsm_state <= S_LO_PULSE_DOWN;
                    end
                end

                S_LO_PULSE_DOWN: begin
                    LCD_E <= 1'b0; // C?nh xu?ng -> LCD ch?t d? li?u
                    fsm_state <= S_IDLE; // Hoàn thành, quay v? IDLE
                end

                default: begin
                    fsm_state <= S_IDLE;
                end
            endcase
        end
    end

endmodule