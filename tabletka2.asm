; This program intercepts INT 09h and overwrites hash function stored in video 
; memory with far jump on desired position to avoid password checking.
;
; by LMD
;----------------------File Contents Start After This Line----------------------

.model tiny
.code
org 100h

locals @@

inject_address = 0fa2h			; position in video mem to inject code
jmp_offset = 017Dh			; position to jump on


Start:

		mov ax, 3509h		; get address of 21 int handler in es:bx
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

		;add sp, 8
		; mov ah, 01h
		; int 21h


		mov ax, 3100h
		mov dx, offset EndOfProg
		mov cl, 4
		shr dx, cl
		inc dx			; dx stores memory in paragraphs
		int 21h

;CodeStr		db 083h, 0c4h, 06h


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

		cli

		;cmp ah, 01h
		;jne @@Skip

		push es di		; saves all used regs

		push 0b800h
		pop es
		mov di, inject_address

		mov byte ptr es:[di], 083h
		mov byte ptr es:[di+1], 0c4h
		mov byte ptr es:[di+2], 06h
		mov byte ptr es:[di+3], 0eah		; far jump
		mov word ptr es:[di+4], jmp_offset	; offset
		mov word ptr es:[di+6], ss		; segment
						; SS is not changed by INT
		pop di es		; restores saved regs


@@Skip:		sti

		db 0eah			; will be translated to jmp
Old09Offset:	dw 0000h		; this part will be modificated
Old09Seg:	dw 0000h		; to jmp OldSeg:OldOffset

		iret
		endp

EndOfProg:
end		Start



