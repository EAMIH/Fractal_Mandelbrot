.code
;-------------------------------------------------------------------------------------------------------------
Asm_Draw proc
; extern "C" void Asm_Draw(char *video_buf, SSize size);
; Параметры:
; RCX - video_buf
; RDX - size
; Возврат: нет

	mov rdi, rcx
	mov eax, 0ffffffffh

	mov rcx, 100000

	rep stosd

	ret

Asm_Draw endp
;-------------------------------------------------------------------------------------------------------------
Asm_Draw_Line proc
; extern "C" void Asm_Draw_Line(char *video_buf, SPoint start_point, SPoint end_point, SBuf_Color buf_color);
; Параметры:
; RCX - video_buf
; RDX - start_point
; R8 - end_point
; R9 - buf_color
; Возврат: нет

	mov rdi, rcx
	mov eax, 0ffffffffh
	
	mov rcx, 100000
	
	rep stosd

	ret

Asm_Draw_Line endp
;-------------------------------------------------------------------------------------------------------------
end
