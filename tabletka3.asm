; This program intercepts INT 21h and uses buffer overflow vulnerability to get
; position in stack where ret address for input function is stored and replaces 
; it with address of successful pass branch. 
;
; by LMD
;----------------------File Contents Start After This Line----------------------

.model tiny
.code
org 100h

locals @@

stack_pos = 0fffah
jmp_offset = 017Dh
buffer_start = 599h

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

		cmp ah, 01h			; if not 01h was called - skip
		jne @@Skip

		push di es
		mov di, buffer_start

@@FillLoop:					; overflows byte by byte 
		cmp di, stack_pos		; input buffer
		je @@EndLoop
		mov al, byte ptr ss:[di]	; does not change symbol
		mov byte ptr ss:[di], al
		add di, 1
		jmp @@FillLoop

@@EndLoop:
		mov ss:[di], word ptr jmp_offset	; replaces ret address

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



