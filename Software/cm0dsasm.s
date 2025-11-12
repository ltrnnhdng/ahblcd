 ;------------------------------------------------------------------------------------------------------
; Design and Implementation of an AHB UART peripheral
; 1)Display text string: "TEST" on VGA. 
; 2)Receive/ print characters from/ to a computer through UART port.
;------------------------------------------------------------------------------------------------------


; Vector Table Mapped to Address 0 at Reset

						PRESERVE8
                		THUMB

        				AREA	RESET, DATA, READONLY	  			; First 32 WORDS is VECTOR TABLE
        				EXPORT 	__Vectors
					
__Vectors		    	DCD		0x00003FFC
        				DCD		Reset_Handler
        				DCD		0  			
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD 	0
        				DCD		0
        				DCD		0
        				DCD 	0
        				DCD		0
        				
        				; External Interrupts
						        				
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
        				DCD		0
              
                AREA |.text|, CODE, READONLY
; Constants

;------------------------------------------	
;Reset Handler
Reset_Handler   PROC
                GLOBAL Reset_Handler
                ENTRY

;Write "TEST" to the text console and the UART



				LDR 	R2, =0x51000000
				MOVS	R0, #'T'
				
				STR		R0, [R2]

				
				LDR 	R2, =0x51000000
				MOVS	R0, #'E'
				
				STR		R0, [R2]

				
				LDR 	R2, =0x51000000
				MOVS	R0, #'S'
				
				STR		R0, [R2]
				
				
				LDR 	R2, =0x51000000
				MOVS	R0, 'T'
				
				STR		R0, [R2]




;---forever loop
;wait until receive buffer is not empty


LOOP        LDR     R1, =0x53000004
            MOVS    R0, #00
            STR     R0, [R1]    ; set as input

            LDR    R1, =0x53000000
            LDR     R2, [R1]    ; INPUT DATA

            LDR    R1, =0x53000004
            MOVS    R0, #01
            STR     R0, [R1]        ; SET PUTPUT

            LDR     R1, =0x53000000
            STR     R2, [R1]

            B LOOP



				ENDP
;---


				ALIGN 		4					 ; Align to a word boundary

		END                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
   