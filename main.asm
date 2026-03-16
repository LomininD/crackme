; This program asks for password and displays message "ACCESS GRANTED" if
; password is correct and "ACCESS DENIED" in other case. However it has several
; vulnerabilities...
;
; Good luck in hacking it!
;
; by LMD
;----------------------File Contents Start After This Line----------------------

.model tiny
.code
org 100h

locals @@

inp_buffer_len = 100
max_len = 20
green_color = 0afh
red_color = 0cfh

;----------------------------------- MACROS ------------------------------------

LoadES		macro
		mov ax, 0b800h
		mov es, ax
		endm

NewL		macro
		add FrameOffset, 160
		mov di, FrameOffset
		endm

;-------------------------------------------------------------------------------

;---------------------------------- Main Body ----------------------------------

Start:

		mov bx, offset InputBuffer
		mov cx, 0		; cx stores number of symbols read

@@InputLoop:
		mov ax, 0100h
		int 21h			; waits for symbol to read
		cmp al, 0dh		; stops loop if enter was pressed
		je @@EndOfInput
		mov [bx], al		; saves symbol to InputBuffer
		inc bx
		inc cx
		jmp @@InputLoop

@@EndOfInput:
		mov di, offset DeniedMsg	; wrong password
		mov ah, red_color
		call DrawFrame

		mov ax, 0100h		; waits for any key to be pressed
		int 21h

		call ClearScreen
		mov ax, 4c00h
		int 21h			; quits the program


FrameOffset	dw 0			; frame beginning pos
TextWidth	dw 0			; number of symbols in text
FrameStyle	db 0cdh, 0bah , 0c9h, 0bbh, 0c8h, 0bch	; frame style arr
GrantedMsg	db 'ACCESS GRANTED$'
DeniedMsg	db 'ACCESS DENIED$'
InputBuffer	db inp_buffer_len dup(01h)	; input buffer

;===============================================================================
; ClearScreen
;
; Dumps empty chars in video memory page
; Entry:     ES -> video mem segment
; Exit:      -
; Expected:  -
; Destroyed: -
;-------------------------------------------------------------------------------

ClearScreen	proc

		push ax			; saves all used registers
		push cx
		push di

		xor di, di		; of video memory
		mov ax, 0		; blank symbol on black bg
		mov cx, 80 * 25		; symbols in video page
		rep stosw

		pop di			; restores used registers values
		pop cx
		pop ax

		ret
		endp

;===============================================================================
; DrawFrame
;
; Draws in video memory frame with given text and color attr
; Entry:     ES -> video mem segment
;	     CS -> code segment
;	     AH -> color attribute
; 	     DI -> msg offset
; Exit:      -
; Expected:  -
; Destroyed: AX, BX, CX, DI, SI, DX
;-------------------------------------------------------------------------------

DrawFrame	proc

		push ax di		; saves ax, di as they will be destroyed

		call CalculateLen	; calculates TextWidth
		mov TextWidth, ax

		call CalcFrameOffset	; calculates FrameOffset
		mov FrameOffset, ax

		LoadES

		pop di ax		; restores ax, di and prepares for
		mov si, di		; drawing in video memory

		mov bx, 0		; bx = 0 for top border
		call DrawHBorder
		NewL

@@Center:
		mov al, [FrameStyle + 1]
		stosw			; draws part of left vert border
		mov al, 00h
		stosw			; draws blank space

		call DisplayStr

		mov al, 00h
		stosw			; draws blank space
		mov al, [FrameStyle + 1]
		stosw			; draws part of right vert border
		NewL

		mov bx, 1		; bx = 1 for bottom border
		call DrawHBorder

		ret
		endp

;===============================================================================
; CalculateLen
;
; Calculates len of string located at ds:di
; Entry:     CS -> code segment
;	     DI -> string offset
; Exit:      AX <- text len
; Expected:  -
; Destroyed: AX, CX, DI
;-------------------------------------------------------------------------------

CalculateLen	proc

		push es
		push ds
		pop es

		cld
		mov cx, max_len
		mov al, '$'		; '$' - end symbol

		repne scasb		; searches for $

		mov ax, max_len		; len = ax = max_len - cx
		sub ax, cx
		dec ax			; $ symbol is not counted in len

		pop es
		ret
		endp

;===============================================================================
; CalcFrameOffset
;
; Calculates line offset for frame beginning and puts value in ax
; Entry:     -
; Exit:      AX <- frame offset
; Expected:  -
; Destroyed: AX, BX, DX
;-------------------------------------------------------------------------------

CalcFrameOffset	proc

		mov bx, TextWidth
		and bx, 0feh		; 1111 1110 mask to make odd number even

		mov ax, 9
		mov dx, 160		; dx - bytes in line
		mul dx			; whole value should be stored in ax
		add ax, 40 * 2		; 80 - mid offset (40 words)
		sub ax, bx
		sub ax, 2 * 2		; -2 words for border and space

		ret
		endp

;===============================================================================
; DrawHBorder
;
; Draws horizontal border in video mem
; Entry:     ES -> video mem segment
;	     BX -> 0 - top border, 1 - bottom border
; Exit:      -
; Expected:  -
; Destroyed: AX, BX, CX, DI
;-------------------------------------------------------------------------------

DrawHBorder	proc

		shl bx, 1		; modificates bx=0 -> bx=2
		add bx, 2		; 	      bx=1 -> bx=4

		mov di, FrameOffset
		mov al, [FrameStyle + bx]
		stosw			; left corner

		mov cx, TextWidth
		add cx, 2
		mov al, [FrameStyle]

		rep stosw		; draws mid part of upper hor border

		mov al, [FrameStyle + bx + 1]
		stosw			; right corner

		ret
		endp

;===============================================================================
; DisplayStr
;
; Copies string located at ds:si to video memory at es:di
; Entry:     ES -> video mem segment
;	     DS -> data segment where string is stored
;	     AH -> color attr
;	     DI -> line offset for text
;	     SI -> text line offset
; Exit:      -
; Expected:  -
; Destroyed: CX, DI, SI
;-------------------------------------------------------------------------------

DisplayStr	proc

		mov cx, TextWidth

@@DisplayLoop:
		lodsb
		stosw
		loop @@DisplayLoop

		ret
		endp


end 		Start
