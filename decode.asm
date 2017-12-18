;  Executable name : decode
;  Version         : v0.1.0
;  Created date    : 13/12/2017
;  Last update     : 13/12/2017
;  Modified by     : Jan Friedli, Dominik Meister
;  Description     : A base64 decoder

SECTION .bss				; Section containing uninitialized data

	BUFFERLENGTH EQU 4						; reserve 4 bytes for each char
	Buff	resb BUFFERLENGTH
	outputBuffer: resb 3

SECTION .data				; Section containing initialised data

	; this map is used to get the base64 representation of the coresponding 6 bits.
	base64CharacterMap:	db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", 10
	inputMsg: db "Please enter anything you want to decode from base64: ", 10

SECTION .text			; Section containing code
	global main

main:
	nop			; No-ops for GDB
	mov r9, 0 ; counter which goes up to four and resets
	xor rsi, rsi

	Read:
		; Read the necessary data block
		mov rax, 3							; Specify sys_read call
		mov rbx, 0							; Specify File Descriptor 0: Standard Input
		mov rcx, Buff						; Pass offset of the buffer to read to
		mov rdx, BUFFERLENGTH		; Pass number of bytes to read at one pass
		int 80h									; Call sys_read to fill the buffer

		mov rbp, rax		; Save # of bytes read from file for later
		cmp rax, 0			; If eax=0, sys_read reached EOF on stdin
		je Done		; Jump If Equal (to 0, from compare)

		cmp rax, 0			; If eax=0, sys_read reached EOF on stdin
		je Done		; Jump If Equal (to 0, from compare)

		xor rsi, rsi ; clean result every round

		; find first char and shift it into the result
		call findCharInMap
		add esi, ecx
		add r9d, esi
		shl r9d, 6
		; second
		call findCharInMap
		add esi, ecx
		or r9d, esi
		shl r9d, 6

		; third
		call findCharInMap
		add esi, ecx
		or r9d, esi
		shl r9d, esi

		; and last one
		call findCharInMap
		add esi, ecx
		or r9d, esi

		; split the 24-bit number into the original three 8-bit (ASCII) characters
		shr r9d, 16
		mov [outputBuffer], r9d

		xor rax, rax
		mov edx, 64     ; number of bytes to write - one for each letter plus 0Ah (line feed character)
	 	mov ecx, outputBuffer    ; move the memory address of our message string into ecx
	 	mov ebx, 1      ; write to the STDOUT file
	 	mov eax, 4      ; invoke SYS_WRITE (kernel opcode 4)
	 	int 80h

		xor rsi, rsi ; reset res buffer
		jmp Read

	; gets the reverse value of the map char
	findCharInMap:
		xor rax, rax
		xor rbx, rbx
		xor rsi, rsi
		xor rdx, rdx
		xor rcx, rcx
		xor rdx, rdx
		afterClean:
			mov byte bl, [Buff + edx] ; get the char from the buffer
			mov byte al, [base64CharacterMap + ecx] ; get a character
			inc ecx	; inc counter
			cmp al, bl ; compare if both chars are the same
		jne afterClean
		ret

	; All done! Let's end this party:
	Done:
		mov rax, 1		; Code for Exit Syscall
		mov rbx, 0		; Return a code of zero
		int 80H			; Make kernel call
