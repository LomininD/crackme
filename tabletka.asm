; This program triggers the backdoor of password asking program main.asm. It 
; intercepts INT 09h and sets DX value to 18ebh (short jmp to @@CorrectPassword) 
;
; To "heal" the naughty password asker you should launch this program before 
; launching main.asm, it will modify INT 09h handler. Then launch main.asm and
; press Enter: you will send an empty password and DX value will replace NOPs
; in original code with EB18, which will cause an automatic pass of the test.
;
; by LMD
;----------------------File Contents Start After This Line----------------------

.model tiny
.code
org 100h

locals @@

dx_value = 18ebh

Start:

		mov ax, 3509h		; get address of 09 int handler in es:bx
		int 21h
		mov word ptr Old09Offset, bx
		mov word ptr Old09Seg, es

		xor ax, ax
		mov es, ax

		mov bx, 4*09h		; address of 09 int handler is located
		mov ax, offset NewHandler	     ; at seg 0000h offs 4*09h
					
		cli
		mov es:[bx], ax		; replaces existing 09 int handler addr
		mov es:[bx+2], cs
		sti

		mov ax, 3100h
		mov dx, offset EndOfProg
		mov cl, 4
		shr dx, cl
		inc dx			; dx stores memory in paragraphs
		int 21h


;===============================================================================
; NewHandler
;
; Modifies existing handler with ability to change DX value
; Entry:     -
; Exit:      -
; Expected:  -
; Destroyed: DX
;-------------------------------------------------------------------------------

NewHandler	proc

		mov dx, dx_value

		db 0eah			; will be translated to jmp
Old09Offset:	dw 0000h		; this part will be modificated
Old09Seg:	dw 0000h		; to jmp OldSeg:OldOffset

		iret
		endp



EndOfProg:
end		Start



