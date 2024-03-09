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
Get_Address proc
; Вычисляет адрес в памяти, соответствующий координатам X, Y
; Параметры:
; RDX - start_point
; R9 - buf_color
; R11 - video_buf
; Возврат: PDI - адрес пикселя

	push rax
	push rbx
	push r10

	movzx r10, r9w	; R10 = R10W = buf_color.Buf_Size.Width

	mov rax, rdx
	shr rax, 16
	movzx rax, ax	; RAX = AX = start_point.Y

	movzx rbx, dx	; RBX = BX = start_point.X

	imul rax, r10	; RAX = RAX * R10 = start_point.Y * buf_color.Buf_Size.Width
	add rax, rbx	; RAX = index =  start_point.Y * buf_color.Buf_Size.Width + start_point.X
	shl rax, 2		; RAX = index * 4 - адрес пикселя в буфере

	mov rdi, r11	; R11 = video_buf
	add rdi, rax

	pop r10
	pop rbx
	pop rax

	ret
Get_Address endp
;-------------------------------------------------------------------------------------------------------------
Asm_Draw_Line proc
; extern "C" void Asm_Draw_Line(char *video_buf, SPoint start_point, SPoint end_point, SBuf_Color buf_color);
; Параметры:
; RCX - video_buf
; RDX - start_point
; R8 - end_point
; R9 - buf_color
; Возврат: нет

	push rax
	push rbx
	push rcx
	push rdx
	push rdi
	push r11
	push r12
	push r13
	push r14
	push r15

	mov r11, rcx

	; 1. Ожидаем координаты конечной точки не меньше, чем начальной
	; 1.1. Проверяем X
	cmp r8w, dx
	jbe _exit


	; 1.2. Проверям Y
	mov eax, edx
	shr eax, 16			; EAX = AX = start_point.Y

	mov ebx, r8d
	shr ebx, 16			; EBX = AX = end_point.Y

	cmp bx, ax
	jbe _exit

	; 2. Вычисляем адрес начала линии 
	call Get_Address	; RDI = адрес в  буфере соответствующий позиции start_point

	mov ax, r8w			; AX = end_point.X
	sub ax, dx			; AX = AX - DX = end_point.X - start_point.X = delta_x
	inc ax
	mov r12w, ax		; R12W = delta_x

	mov ebx, r8d
	shr ebx, 16			; EBX = BX = end_point.Y
	
	mov ecx, edx
	shr ecx, 16			; ECX = CX = start_point.X
	
	sub bx, cx			; BX = BX - CX = end_point.Y - start_point.Y = delta_y
	inc bx
	mov r13w, bx		; R13W = delta_y

	; 3. Выбираем алгоритм - линия ближе к горизонтали или к вертикали
	cmp ax, bx
	jle _draw_vertical


_draw_horizontal:
	
	xor r14w, r14w		; Накопитель числителя

	movzx rcx, r13w		; RCX = delta_y = количество итераций

	movzx r15, r9w		; R15 = buf_color.Buf_Size.Width
	shl r15, 2			; R15 = buf_color.Buf_Size.Width * 4 = изменение адреса для перехода на следующую строку

	mov rax, r9
	shr rax, 32			; RAX = EAX = buf_color.Color

_draw_horizontal_pixel:
	stosd

	add r14w, r13w		; Добавили числитель (delta_y)
	cmp r14w, r12w
	jl _draw_horizontal_pixel

	sub r14w, r12w		; Вычитаем значенатель (delta_x) из накопленного числителя

	add rdi, r15
	loop _draw_horizontal_pixel

	jmp _exit

_draw_vertical:
		
	xor r14w, r14w		; Накопитель числителя

	movzx rcx, r12w		; RCX = delta_x = количество итераций

	movzx r15, r9w		; R15 = buf_color.Buf_Size.Width
	dec r15
	shl r15, 2			; R15 = buf_color.Buf_Size.Width * 4 = изменение адреса для перехода на следующую строку

	mov rax, r9
	shr rax, 32			; RAX = EAX = buf_color.Color

_draw_vertical_pixel:
	stosd
	add rdi, r15

	add r14w, r12w		; Добавили числитель (delta_x)
	cmp r14w, r13w
	jl _draw_vertical_pixel

	sub r14w, r13w		; Вычитаем значенатель (delta_y) из накопленного числителя

	add rdi, 4
	loop _draw_vertical_pixel

_exit:

	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop rdi
	pop rdx
	pop rcx
	pop rbx
	pop rax

	ret

Asm_Draw_Line endp
;-------------------------------------------------------------------------------------------------------------
Asm_Draw_Horizontal_Line proc
; extern "C" void Asm_Draw_Line(char *video_buf, SPoint start_point, int length, SBuf_Color buf_color);
; Параметры:
; RCX - video_buf
; RDX - start_point
; R8 - length
; R9 - buf_color
; Возврат: нет

	push rax
	push rcx
	push rdi
	push r11

	mov r11, rcx

	; 1. Вычисляем адрес начала линии
	call Get_Address	; RDI = адрес в буфере соответствующий позиции start_point

	mov rax, r9
	shr rax, 32		; RAX = EAX = buf_color.Color

	; 2. Выводим линию
	mov rcx, r8		; RCX = length = количество пикселей в линии

	rep stosd

	pop r11
	pop rdi
	pop rcx
	pop rax

	ret

Asm_Draw_Horizontal_Line endp
;-------------------------------------------------------------------------------------------------------------
end
