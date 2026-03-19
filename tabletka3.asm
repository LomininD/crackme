; This program intercepts INT 21h and overwrites hash function stored in video 
; memory with far jump on desired position to avoid password checking.
;
; by LMD
;----------------------File Contents Start After This Line----------------------

.model tiny
.code
org 100h

locals @@

stack_pos = 0fffah
jmp_offset = 017Dh

Start:

		mov ax, 3521h		; get address of 21 int handler in es:bx
		int 21h
		mov word ptr Old09Offset, bx
		mov word ptr Old09Seg, es

		xor ax, ax
		mov es, ax

		mov bx, 4*21h		; address of 09 int handler is located
		mov ax, offset NewHandler	     ; at seg 0000h offs 4*09h
					
		cli
		mov es:[bx], ax		; replaces existing 09 int handler addr
		mov es:[bx+2], cs
		sti


		; mov ah, 01h
		; call NewHandler


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

		cmp ah, 01h
		jne @@Skip

		push di es

		mov di, 599h

@@FillLoop:
		cmp di, stack_pos
		je @@EndLoop
		mov al, byte ptr ss:[di]
		mov byte ptr ss:[di], al
		add di, 1
		jmp @@FillLoop

@@EndLoop:
		mov ss:[di], word ptr jmp_offset

		mov al, 20h		; end of interrupt
		out 20h, al

		mov al, 0dh		; end of "input"

		pop es di
		sti
		iret

@@Skip:		sti

		db 0eah			; will be translated to jmp
Old09Offset:	dw 0000h		; this part will be modificated
Old09Seg:	dw 0000h		; to jmp OldSeg:OldOffset

		iret
		endp

EndOfProg:
end		Start



