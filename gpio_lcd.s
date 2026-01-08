				PRESERVE8
                THUMB

; ============================================================================
; VECTOR TABLE
; ============================================================================
                AREA    RESET, DATA, READONLY
                EXPORT  __Vectors

__Vectors       DCD     0x00003FFC          ; Initial Stack Pointer (16KB)
                DCD     Reset_Handler       ; Reset Handler

; ============================================================================
; PROGRAM CODE
; ============================================================================
                AREA    |.text|, CODE, READONLY

; ============================================================================
; HARDWARE ADDRESS DEFINITIONS
; ============================================================================
LCD_CMD_PORT    EQU     0x50000000          ; LCD Command Register
LCD_DATA_PORT   EQU     0x50000004          ; LCD Data Register

GPIO_DATA_PORT  EQU     0x53000000          ; GPIO Data Register
GPIO_DIR_PORT   EQU     0x53000004          ; GPIO Direction Register

; ============================================================================
; LCD COMMANDS
; ============================================================================
LCD_ROW1_ADDR   EQU     0x80                ; Line 1 start address
LCD_ROW2_ADDR   EQU     0xC0                ; Line 2 start address

; ============================================================================
; DISPLAY STRINGS
; ============================================================================
Title_String    DCB     "HELLO WORLD!", 0
Button1_Msg     DCB     "BUTTON 1 PRESSED", 0
Button2_Msg     DCB     "BUTTON 2 PRESSED", 0
Button3_Msg     DCB     "BUTTON 3 PRESSED", 0
Button4_Msg     DCB     "BUTTON 4 PRESSED", 0
Blank_Line      DCB     "                ", 0  ; 16 spaces to clear line
                ALIGN

; ============================================================================
; MAIN PROGRAM
; ============================================================================
Reset_Handler   PROC
                GLOBAL  Reset_Handler
                ENTRY

; ---------------------------------------------------------------------------
; 1. INITIALIZE GPIO AS INPUT
; ---------------------------------------------------------------------------
                LDR     R0, =GPIO_DIR_PORT
                MOVS    R1, #0x0000         ; Set all GPIO as input
                STR     R1, [R0]

; ---------------------------------------------------------------------------
; 2. POWER-ON DELAY (>40ms)
; ---------------------------------------------------------------------------
                BL      Delay_Long
                BL      Delay_Long
                BL      Delay_Long
                BL      Delay_Long
                BL      Delay_Long
                BL      Delay_Long
                BL      Delay_Long
                BL      Delay_Long

; ---------------------------------------------------------------------------
; 3. LCD SYNCHRONIZATION SEQUENCE
; ---------------------------------------------------------------------------
                LDR     R4, =LCD_CMD_PORT

                MOVS    R0, #0x03
                STR     R0, [R4]
                BL      Delay_Long

                STR     R0, [R4]
                BL      Delay_Short

                STR     R0, [R4]
                BL      Delay_Short

; ---------------------------------------------------------------------------
; 4. SET 4-BIT MODE
; ---------------------------------------------------------------------------
                MOVS    R0, #0x02
                STR     R0, [R4]
                BL      Delay_Short

; ---------------------------------------------------------------------------
; 5. LCD CONFIGURATION
; ---------------------------------------------------------------------------
                MOVS    R0, #0x28            ; 4-bit, 2-line, 5x8 font
                BL      LCD_Send_Command

                MOVS    R0, #0x0C            ; Display ON, cursor OFF
                BL      LCD_Send_Command

                MOVS    R0, #0x01            ; Clear display
                BL      LCD_Send_Command
                BL      Delay_Long

                MOVS    R0, #0x06            ; Entry mode: auto increment
                BL      LCD_Send_Command

; ---------------------------------------------------------------------------
; 6. DISPLAY TITLE (LINE 1)
; ---------------------------------------------------------------------------
                MOVS    R0, #LCD_ROW1_ADDR
                BL      LCD_Send_Command

                LDR     R1, =Title_String
                BL      LCD_Print_String

; ---------------------------------------------------------------------------
; 7. MAIN LOOP - CHECK BUTTONS
; ---------------------------------------------------------------------------
                LDR     R5, =GPIO_DATA_PORT ; R5 = GPIO base address
                MOVS    R6, #0              ; R6 = previous button state

Main_Loop
                ; Read GPIO input
                LDR     R7, [R5]            ; R7 = current GPIO state
                MOVS    R0, #0x0F
                ANDS    R7, R0              ; Mask to get only SW[3:0]
                
                ; Check if button state changed
                CMP     R7, R6
                BEQ     Main_Loop           ; No change, continue
                
                ; Button state changed
                MOVS    R6, R7              ; Update previous state
                
                ; Debounce delay
                BL      Delay_Debounce
                
                ; Check which button is pressed
                CMP     R7, #0x00
                BEQ     Main_Loop           ; No button pressed
                
                ; Clear line 2 first
                MOVS    R0, #LCD_ROW2_ADDR
                BL      LCD_Send_Command
                LDR     R1, =Blank_Line
                BL      LCD_Print_String
                
                ; Check Button 1 (SW[0] = bit 0)
                MOVS    R0, #0x01
                TST     R7, R0
                BEQ     Check_Button2
                
                MOVS    R0, #LCD_ROW2_ADDR
                BL      LCD_Send_Command
                LDR     R1, =Button1_Msg
                BL      LCD_Print_String
                B       Main_Loop

Check_Button2
                ; Check Button 2 (SW[1] = bit 1)
                MOVS    R0, #0x02
                TST     R7, R0
                BEQ     Check_Button3
                
                MOVS    R0, #LCD_ROW2_ADDR
                BL      LCD_Send_Command
                LDR     R1, =Button2_Msg
                BL      LCD_Print_String
                B       Main_Loop

Check_Button3
                ; Check Button 3 (SW[2] = bit 2)
                MOVS    R0, #0x04
                TST     R7, R0
                BEQ     Check_Button4
                
                MOVS    R0, #LCD_ROW2_ADDR
                BL      LCD_Send_Command
                LDR     R1, =Button3_Msg
                BL      LCD_Print_String
                B       Main_Loop

Check_Button4
                ; Check Button 4 (SW[3] = bit 3)
                MOVS    R0, #0x08
                TST     R7, R0
                BEQ     Main_Loop
                
                MOVS    R0, #LCD_ROW2_ADDR
                BL      LCD_Send_Command
                LDR     R1, =Button4_Msg
                BL      LCD_Print_String
                B       Main_Loop

                ENDP

; ============================================================================
; LCD INTERFACE ROUTINES
; ============================================================================
; Send command byte to LCD
; R0 = command
LCD_Send_Command PROC
                PUSH    {R0-R4, LR}
                LDR     R4, =LCD_CMD_PORT
                B       LCD_Send_4Bit
                ENDP

; Send data byte to LCD
; R0 = data
LCD_Send_Data    PROC
                PUSH    {R0-R4, LR}
                LDR     R4, =LCD_DATA_PORT
                ; fall through
                ENDP

; Split byte into high & low nibble and send
LCD_Send_4Bit    PROC
                MOVS    R2, R0
                LSRS    R2, R2, #4
                STR     R2, [R4]
                BL      Delay_Short

                MOVS    R2, R0
                MOVS    R3, #0x0F
                ANDS    R2, R3
                STR     R2, [R4]
                BL      Delay_Short

                POP     {R0-R4, PC}
                ENDP

; Print null-terminated string
; R1 = string address
LCD_Print_String PROC
                PUSH    {R0-R1, LR}

Print_Loop
                LDRB    R0, [R1]
                CMP     R0, #0
                BEQ     Print_Exit

                BL      LCD_Send_Data
                ADDS    R1, R1, #1
                B       Print_Loop

Print_Exit
                POP     {R0-R1, PC}
                ENDP

; ============================================================================
; DELAY ROUTINES
; ============================================================================
Delay_Short     PROC
                PUSH    {R0}
                LDR     R0, =0x3000
Delay_S_Loop
                SUBS    R0, R0, #1
                BNE     Delay_S_Loop
                POP     {R0}
                BX      LR
                ENDP

Delay_Long      PROC
                PUSH    {LR}
                BL      Delay_Short
                BL      Delay_Short
                BL      Delay_Short
                BL      Delay_Short
                BL      Delay_Short
                POP     {PC}
                ENDP

Delay_Debounce  PROC
                PUSH    {LR}
                BL      Delay_Long
                BL      Delay_Long
                POP     {PC}
                ENDP

                END
