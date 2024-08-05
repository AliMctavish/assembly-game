				processor 6502		
				include	 "vcs.h"		
				include "macro.h"
										
BORDERCOLOR		equ 	#$3f
TESTBORDERCOLOR	equ 	#$1a
BORDERHEIGHT	equ		#8				; How many scan lines are our top and bottom borders

				; ------------------------- Start of main segment ---------------------------------

				seg		main
				org 	$F000

				; ------------------------- Start of program execution ----------------------------

reset: 			ldx 	#0 				; Clear RAM and all TIA registers
				lda 	#0 
  
clear:       	sta 	0,x 			; $0 to $7F (0-127) reserved OS page zero, $80 to $FF (128-255) user zero page ram.
				inx 
				bne 	clear

				lda 	#%00000001		; Set D0 to reflect the playfield
				sta 	CTRLPF			; Apply to the CTRLPF register

	; Set the PF color

				; --------------------------- Begin main loop -------------------------------------

startframe:			; ------- 76543210 ---------- Bit order
				lda 	#$3f		; Writing a bit into the D1 vsync latch
				sta 	VSYNC 

				; --------------------------- 3 scanlines of VSYNC signal
				sta 	WSYNC
				sta 	WSYNC
				sta 	WSYNC  

				; --------------------------- Turn off VSYNC         	 
				lda 	#0
				sta		VSYNC

				; -------------------------- Additional 37 scanlines of vertical blank ------------

				ldx 	#0 					
				lda 	#0
lvblank:		sta 	WSYNC
				inx
				cpx 	#37				; 37 scanlines of vertical blank
				bne 	lvblank
				
				; --------------------------- 192 lines of drawfield ------------------------------

    			ldx 	#0 					
drawfield:		cpx		#BORDERHEIGHT-1	; Borderheight-1 will be interpreted by the assembler (-1 because the index starts at 0)
				beq		borderwalls
				
				cpx 	#192-BORDERHEIGHT	; will be interpreted by the assembler
				beq		borderbottom
				
				cpx    #100
				beq    changecolor
				cpx    #191
				beq    changetoanothercolor
				
				jmp    DrawPlayer
				
							
				jmp 	borderdone
				
				
DrawPlayer:
			lda #%1111111
			sta GRP0
			lda #$0E
			sta COLUP0
			ldx #10
			


			jmp borderdone
			
			
MovePlayer: ;building the player movement for the game
			inx
			cpx #100
			beq borderdone
			
			sta WSYNC
			Sleep #10
			sta RESP0
			jmp MovePlayer



borderbottom:  	lda		#%11111111		; Solid row of pixels for all PF# registers
				 sta     PF0
				sta		PF1
				sta		PF2				

				jmp 	borderdone

borderwalls:	lda     #%11111111		; Set the first pixel of PF0. Uses the 4 hight bits and rendered in reverse.
				sta     PF0				; Set PF0 register
				lda		#%0000000		; Clear the PF1-2 registers to have an empty middle
				sta 	PF1
				sta     PF2
				
				jmp     borderdone
				
changecolor:
				lda		#TESTBORDERCOLOR			
				sta		COLUPF
				jmp     borderdone
				
changetoanothercolor:
				lda		#BORDERCOLOR			
				sta		COLUPF
				jmp     borderdone
				
borderdone:		sta 	WSYNC
    			inx  
				cpx 	#192
				bne 	drawfield

				; -------------------------- 30 scanlines of overscan -----------------------------

				ldx 	#0					
overscan:       sta 	WSYNC
				inx
				cpx 	#30
				bne 	overscan

				; --------------------------- End of overscan -------------------------------------

				jmp 	startframe		; jump back up to start the next frame

				; --------------------------- Pad until end of main segment -----------------------

				org 	$FFFA
	
irqvectors:
				.word reset          	; NMI
				.word reset          	; RESET
				.word reset          	; IRQ

				; -------------------------- End of main segment ----------------------------------
				
				

