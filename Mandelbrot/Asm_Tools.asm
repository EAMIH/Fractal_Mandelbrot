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
; Возврат: RDI - адрес пикселя

	push rax
	push rbx
	push r10

	movzx r10, r9w  ; R10 = R10W = buf_color.Buf_Size.Width

	mov rax, rdx
	shr rax, 16
	movzx rax, ax  ; RAX = AX = start_point.Y

	movzx rbx, dx  ; RBX = BX = start_point.X

	imul rax, r10  ; RAX = RAX * R10 = start_point.Y * buf_color.Buf_Size.Width
	add rax, rbx  ; RAX = index = start_point.Y * buf_color.Buf_Size.Width + start_point.X
	shl rax, 2  ; RAX = index * 4 - адрес пикселя в буфере

	mov rdi, r11  ; R11 = video_buf
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

	; 1.2. Проверяем Y
	mov eax, edx
	shr eax, 16  ; EAX = AX = start_point.Y

	mov ebx, r8d
	shr ebx, 16  ; EBX = BX = end_point.Y

	cmp bx, ax
	jbe _exit

	; 2. Вычисляем адрес начала линии
	call Get_Address  ; RDI = адрес в буфере, соответствующий позиции start_point

	mov ax, r8w  ; AX = end_point.X
	sub ax, dx  ; AX = AX - DX = end_point.X - start_point.X = delta_x
	inc ax
	mov r12w, ax  ; R12W = delta_x

	mov ebx, r8d
	shr ebx, 16  ; EBX = BX = end_point.Y

	mov ecx, edx
	shr ecx, 16  ; ECX = CX = start_point.Y

	sub bx, cx  ; BX = end_point.Y - start_point.Y = delta_y
	inc bx
	mov r13w, bx  ; R13W = delta_y

	; 3. Выбираем алгоритм - линия ближе к горизонтали или к вертикали
	cmp ax, bx
	jle _draw_vertical

; _draw_horizontal:
	; 4/14 + 4/14 = 8/14 + 4/14 = 12/14 + 4/14 = 16/14 = 1 (2/14)

	xor r14w, r14w  ; Накопитель числителя

	movzx rcx, r13w  ; RCX = delta_y = количество итераций

	movzx r15, r9w  ; R15 = buf_color.Buf_Size.Width
	shl r15, 2  ; R15 = buf_color.Buf_Size.Width * 4 = изменение адреса для перехода на следующую строку

	mov rax, r9
	shr rax, 32  ; RAX = EAX = buf_color.Color

_draw_horizontal_pixel:
	stosd

	add r14w, r13w  ; Добавили числитель (delta_y)
	cmp r14w, r12w
	jl _draw_horizontal_pixel

	sub r14w, r12w  ; Вычитаем знаменатель (delta_x) из накопленного числителя

	add rdi, r15
	loop _draw_horizontal_pixel

	jmp _exit

_draw_vertical:
	xor r14w, r14w  ; Накопитель числителя

	movzx rcx, r12w  ; RCX = delta_x = количество итераций

	movzx r15, r9w  ; R15 = buf_color.Buf_Size.Width
	dec r15
	shl r15, 2  ; R15 = buf_color.Buf_Size.Width * 4 = изменение адреса для перехода на следующую строку

	mov rax, r9
	shr rax, 32  ; RAX = EAX = buf_color.Color

_draw_vertical_pixel:
	stosd
	add rdi, r15

	add r14w, r12w  ; Добавили числитель (delta_x)
	cmp r14w, r13w
	jl _draw_vertical_pixel

	sub r14w, r13w  ; Вычитаем знаменатель (delta_y) из накопленного числителя

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
; extern "C" void Asm_Draw_Horizontal_Line(char *video_buf, SPoint start_point, int length, SBuf_Color buf_color);
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
	call Get_Address  ; RDI = адрес в буфере, соответствующий позиции start_point

	; 2. Выводим линию
	mov rcx, r8  ; RCX = length = количество пикселей в линии

	mov rax, r9
	shr rax, 32  ; RAX = EAX = buf_color.Color

	rep stosd

	pop r11
	pop rdi
	pop rcx
	pop rax

	ret

Asm_Draw_Horizontal_Line endp
;-------------------------------------------------------------------------------------------------------------
Asm_Set_Pixel proc
; extern "C" void Asm_Set_Pixel(char *video_buf, SPoint point, SBuf_Color buf_color);
; Параметры:
; RCX - video_buf
; RDX - point
; R8 - buf_color
; Возврат: нет

	push rdi
	push r9
	push r11

	mov r9, r8  ; R9 = buf_color
	mov r11, rcx  ; R11 = video_buf

	; 1. Вычисляем адрес пикселя
	call Get_Address  ; RDI = адрес в буфере, соответствующий позиции point

	shr r9, 32  ; R9 = R9D = buf_color.Color
	mov [ rdi ], r9d

	pop r11
	pop r9
	pop rdi

	ret

Asm_Set_Pixel endp
;-------------------------------------------------------------------------------------------------------------
Asm_Get_Mandelbrot_Index proc
; extern "C" int Asm_Get_Mandelbrot_Index(char *video_buf, double x_0, double y_0, int colors_count);
; Параметры:
; RCX - video_buf
; XMM1 - x_0
; XMM2 - y_0
; R9 - colors_count
; Возврат: EAX 

	push rcx

	mov rax, 4
	cvtsi2sd xmm8, rax  ; XMM8 = 4.0

	mov rcx, r9  ; RCX = colors_count = количество итераций

;	x_n = 0.0;
;	y_n = 0.0;
	xorpd xmm3, xmm3  ; XMM3 = x_n = 0.0
	xorpd xmm4, xmm4  ; XMM4 = y_n = 0.0

_iteration_start:
;	for (i = 0; i < colors_count; i++)
;	{
;		x_n1 = x_n * x_n - y_n * y_n + x_0;

	movapd xmm5, xmm3  ; XMM5 = XMM3 = x_n
	movapd xmm6, xmm4  ; XMM6 = XMM4 = y_n

	mulsd xmm5, xmm5  ; XMM5 = x_n * x_n
	mulsd xmm6, xmm6  ; XMM6 = y_n * y_n

	subsd xmm5, xmm6  ; XMM5 = x_n * x_n - y_n * y_n

	addsd xmm5, xmm1  ; XMM5 = x_n1

;		y_n1 = 2.0 * x_n * y_n + y_0;

	movaps xmm7, xmm3  ; XMM7 = x_n
	mulsd xmm7, xmm4  ; XMM7 = x_n * y_n
	addsd xmm7, xmm7  ; XMM7 = 2.0 * x_n * y_n
	addsd xmm7, xmm2  ; XMM7 = y_n1 = 2.0 * x_n * y_n + y_0

;		distance = x_n1 * x_n1 + y_n1 * y_n1;

	movaps xmm6, xmm5  ; XMM6 = x_n1
	mulsd xmm6, xmm6  ; XMM6 = x_n1 * x_n1

	movaps xmm0, xmm7  ; XMM7 = y_n1
	mulsd xmm0, xmm0  ; XMM0 = y_n1 * y_n1

	addsd xmm0, xmm6  ; XMM0 = distance = x_n1 * x_n1 + y_n1 * y_n1

;		if (distance > 4.0)
;			break;

	cmpnlesd xmm0, xmm8  ; XMM0 > 4.0 ?

	movmskpd eax, xmm0

	bt eax, 0
	jc _got_index

;		x_n = x_n1;
;		y_n = y_n1;

	movaps xmm3, xmm5  ; XMM3 = x_n = x_n1
	movaps xmm4, xmm7  ; XMM4 = y_n = y_n1

;	}

	loop _iteration_start


_got_index:
	mov rax, r9
	sub rax, rcx  ; RAX = EAX = colors_count - count = color_index = итерация, на которой прервался цикл

;	return i;

	pop rcx

	ret

Asm_Get_Mandelbrot_Index endp
;-------------------------------------------------------------------------------------------------------------
end
