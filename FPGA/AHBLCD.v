module AHBLCD(
    // AHB-Lite Interface
    input wire        HCLK,
    input wire        HRESETn,
    input wire        HSEL,
    input wire [31:0] HADDR,
    input wire [1:0]  HTRANS,
    input wire        HWRITE,
    input wire [31:0] HWDATA,
    input wire        HREADY,
    
    output wire        HREADYOUT,
    output wire [31:0] HRDATA,
    
    // LCD Interface (4-bit mode)
    output reg [3:0]  LCD_DATA,
    output reg        LCD_RS,
    output reg        LCD_RW,
    output reg        LCD_E
);

    // AHB Control Logic
    reg last_HSEL;
    reg last_HWRITE;
    reg [31:0] last_HADDR;
    
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            last_HSEL <= 1'b0;
            last_HWRITE <= 1'b0;
            last_HADDR <= 32'h0;
        end else if (HREADY) begin
            last_HSEL <= HSEL;
            last_HWRITE <= HWRITE;
            last_HADDR <= HADDR;
        end
    end
    
    wire write_enable = last_HSEL && last_HWRITE && HREADY;
    wire read_enable = last_HSEL && !last_HWRITE && HREADY;
    
    // Address Map
    // 0x00: Command Register (RS=0) - writes 4-bit nibble directly
    // 0x04: Data Register (RS=1)    - writes 4-bit nibble directly
    // 0x08: Status Register (read busy flag)
    
    // LCD Controller State Machine
    localparam IDLE       = 3'd0;
    localparam SETUP      = 3'd1;
    localparam ENABLE_H   = 3'd2;
    localparam ENABLE_L   = 3'd3;
    // localparam HOLD       = 3'd4;
    localparam WAIT_DONE  = 3'd5;
    
    reg [2:0] state;
    reg [3:0] nibble_data;
    reg rs_value;
    reg busy_flag;
    
    // Timing counter for E pulse (minimum 450ns for 5V, 1400ns for 2.7V)
    // At 50MHz: 450ns = 23 cycles, 1400ns = 70 cycles
    // We'll use conservative values
    reg [7:0] timer;
    
    localparam SETUP_CYCLES = 8'd5;    // 100ns setup time
    localparam ENABLE_CYCLES = 8'd75;  // 1.5us E pulse width (conservative)
    localparam HOLD_CYCLES = 8'd5;     // 100ns hold time
    localparam WAIT_CYCLES = 8'd50;    // 1us between operations
    
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state <= IDLE;
            LCD_DATA <= 4'h0;
            LCD_RS <= 1'b0;
            LCD_RW <= 1'b0;
            LCD_E <= 1'b0;
            nibble_data <= 4'h0;
            rs_value <= 1'b0;
            timer <= 8'd0;
            busy_flag <= 1'b0;
            
        end else begin
            case (state)
                IDLE: begin
                    LCD_E <= 1'b0;
                    LCD_RW <= 1'b0;
                    busy_flag <= 1'b0;
                    timer <= 8'd0;
                    
                    // Check for write from AHB
                    if (write_enable) begin
                        nibble_data <= HWDATA[3:0];  // Take lower 4 bits
                        
                        // Determine if command or data based on address
                        if (last_HADDR[2] == 1'b0) begin
                            rs_value <= 1'b0;  // Command (0x00)
                        end else begin
                            rs_value <= 1'b1;  // Data (0x04)
                        end
                        
                        state <= SETUP;
                        busy_flag <= 1'b1;
                    end
                end
                
                SETUP: begin
                    // Setup time: Set RS, RW, and DATA before E goes high
                    LCD_RS <= rs_value;
                    LCD_RW <= 1'b0;
                    LCD_DATA <= nibble_data;
                    LCD_E <= 1'b0;
                    
                    if (timer >= SETUP_CYCLES) begin
                        timer <= 8'd0;
                        state <= ENABLE_H;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end
                
                ENABLE_H: begin
                    // E pulse high
                    LCD_E <= 1'b1;
                    LCD_RS <= rs_value;
                    LCD_RW <= 1'b0;
                    LCD_DATA <= nibble_data;
                    
                    if (timer >= ENABLE_CYCLES) begin
                        timer <= 8'd0;
                        state <= ENABLE_L;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end
                
                ENABLE_L: begin
                    // E pulse low
                    LCD_E <= 1'b0;
                    LCD_RS <= rs_value;
                    LCD_RW <= 1'b0;
                    LCD_DATA <= nibble_data;
                    
                    if (timer >= HOLD_CYCLES) begin
                        timer <= 8'd0;
                        state <= WAIT_DONE;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end
                
                WAIT_DONE: begin
                    // Wait before ready for next operation
                    LCD_E <= 1'b0;
                    
                    if (timer >= WAIT_CYCLES) begin
                        timer <= 8'd0;
                        state <= IDLE;
                        busy_flag <= 1'b0;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // AHB Read data - return busy flag
    assign HRDATA = (read_enable && last_HADDR[7:0] == 8'h08) ? {31'b0, busy_flag} : 32'h00000000;
    
    // Always ready for AHB transactions (internal buffering)
    assign HREADYOUT = 1'b1;

endmodule