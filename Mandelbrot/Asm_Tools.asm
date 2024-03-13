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
Asm_Set_Mandelbrot_Point proc
; extern "C" int Asm_Set_Mandelbrot_Point(char *video_buf, SPoint_Double *xy_0, int *palette_rgb, int colors_count);
; Параметры:
; RCX - video_buf
; RDX - xy_0
; R8 - palette_rgb
; R9 - colors_count
; Возврат: EAX 

	push rbx
	push rcx
	push r10

	mov rax, 4
	cvtsi2sd xmm8, rax  ; XMM8 = 4.0

	mov r10, rcx  ; R10 = video_buf

	mov rcx, r9  ; RCX = colors_count = количество итераций

	movupd xmm1, [ rdx ]  ; XMM1 = x_0
	movupd xmm2, [ rdx + 8 ]  ; XMM2 = y_0

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
	mov rbx, r9
	sub rbx, rcx  ; RBX = EBX = colors_count - count = color_index = итерация, на которой прервался цикл

	; Если RCX == 0, то выбираем чёрный цвет (т.е. 0), иначе - цвет из палитры

	xor eax, eax  ; EAX = 0 не случай, если цвет - чёрный, а также, чтобы не сравнивать с нулевой константой
	cmp ecx, eax
	cmovne eax, [ r8 + rbx * 4 ]  ; EAX = palette_rgb[color_index]

	mov [ r10 ], eax  ; Сохраняем пиксель в память

	pop r10
	pop rcx
	pop rbx

	ret

Asm_Set_Mandelbrot_Point endp
;-------------------------------------------------------------------------------------------------------------
Asm_Set_Mandelbrot_2_Points proc
; extern "C" int Asm_Set_Mandelbrot_2_Points(char *video_buf, SPacked_XY *xy_0, int *palette_rgb, int colors_count);
; Параметры:
; RCX - video_buf
; RDX - xy_0
; R8 - palette_rgb
; R9 - colors_count
; Возврат: EAX 

	push rbx
	push rcx
	push r10
	push r11
	push r12

	mov r11, 11b  ; R11[1..0] - Маска значений, для которых уже посчитан индекс (0/1 - да / ещё нет)

	mov rax, 4
	cvtsi2sd xmm8, rax  ; XMM8 = 4.0

	pshufd xmm8, xmm8, 01000100b  ; XMM8 = { 4.0, 4.0 }

	mov r10, rcx  ; R10 = video_buf

	mov rcx, r9  ; RCX = colors_count = количество итераций

	movupd xmm2, [ rdx ]  ; XMM2 = y_0
	pshufd xmm2, xmm2, 01000100b  ; XMM2 = { y_0, y_0 }

	movupd xmm1, [ rdx + 8 ]  ; XMM1 = { x1_0, x2_0 }

;	x_n = 0.0;
;	y_n = 0.0;
	xorpd xmm3, xmm3  ; XMM3 = { x1_n, x2_n } = { 0.0, 0.0 }
	xorpd xmm4, xmm4  ; XMM4 = { y1_n, y2_n } = { 0.0, 0.0 }

_iteration_start:
;	for (i = 0; i < colors_count; i++)
;	{
;		x_n1 = x_n * x_n - y_n * y_n + x_0;

	movapd xmm5, xmm3  ; XMM5 = XMM3 = { x1_n, x2_n }
	movapd xmm6, xmm4  ; XMM6 = XMM4 = { y1_n, y2_n }

	mulpd xmm5, xmm5  ; XMM5 = { x1_n * x1_n, x2_n * x2_n }
	mulpd xmm6, xmm6  ; XMM6 = { y1_n * y1_n, y2_n * y2_n }

	subpd xmm5, xmm6  ; XMM5 = { x1_n * x1_n - y1_n * y1_n,  x2_n * x2_n - y2_n * y2_n }

	addpd xmm5, xmm1  ; XMM5 = { x1_n1, x2_n1 }

;		y_n1 = 2.0 * x_n * y_n + y_0;

	movaps xmm7, xmm3  ; XMM7 = { x1_n, x2_n }
	mulpd xmm7, xmm4  ; XMM7 = { x1_n * y1_n, x2_n * y2_n }
	addpd xmm7, xmm7  ; XMM7 = { 2.0 * x1_n * y1_n,  2.0 * x2_n * y2_n }
	addpd xmm7, xmm2  ; XMM7 = { y1_n1, y2_n1 }

;		distance = x_n1 * x_n1 + y_n1 * y_n1;

	movaps xmm6, xmm5  ; XMM6 = { x1_n1, x2_n1 }
	mulpd xmm6, xmm6  ; XMM6 = { x1_n1 * x1_n1, x2_n1 * x2_n1 }

	movaps xmm0, xmm7  ; XMM7 = { y1_n1, y1_n1 }
	mulpd xmm0, xmm0  ; XMM0 = { y1_n1 * y1_n1, y2_n1 * y2_n1 }

	addpd xmm0, xmm6  ; XMM0 = { distance_1, distance_2 }

;		x_n = x_n1;
;		y_n = y_n1;

	movaps xmm3, xmm5  ; XMM3 = x_n = x_n1
	movaps xmm4, xmm7  ; XMM4 = y_n = y_n1

;		if (distance > 4.0)
;			break;

	cmpnlepd xmm0, xmm8  ; XMM0 > 4.0 ?

	movmskpd eax, xmm0
	and rax, r11  ; Накладываем маску, обнуляя биты, для которых уже был посчитан индекс

	cmp rax, 0
	jne _check_bits

	; bt eax, 0
	; jc _got_index

;	}

	loop _iteration_start  ; Продолжаем, т.к. нет новых индексов

	; Дойдём сюда, когда закончатся все итерации, при этом в RAX - результат последнего сравнения
	; Надо к этому результату применить результат, накопленный в маске

	or rax, r11  ; Принудительно отмечаем оставшиеся биты как те, для которых надо посчитать индекс

_check_bits:
	xor edx, edx  ; Начнём проверять EAX с 0-го бита

_check_one_bit:
	bt eax, edx
	jnc _check_next_value  ; Переходим к следующему биту, если текущий = 0

	mov r12, r9
	sub r12, rcx  ; R12 = colors_count - count = color_index = итерация, на которой прервался цикл

	; Если RCX == 0, то выбираем чёрный цвет (т.е. 0), иначе - цвет из палитры

	xor ebx, ebx  ; EBX = 0 не случай, если цвет - чёрный, а также, чтобы не сравнивать с нулевой константой
	cmp ecx, ebx
	cmovne ebx, [ r8 + r12 * 4 ]  ; EBX = palette_rgb[color_index]

	mov [ r10 + rdx * 4 ], ebx  ; Сохраняем пиксель в память

	btr r11d, edx  ; Сбросим бит маски, чтобы не проверять больше этот индекс

_check_next_value:
	inc edx
	cmp edx, 2
	jl _check_one_bit  ; Продолжим проверять биты [1..0]


	cmp r11d, 0
	je _exit

	dec rcx

	cmp rcx, 0
	jg _iteration_start  ; Продолжаем, т.к. не все ещё индексы посчитаны


_exit:
	pop r12
	pop r11
	pop r10
	pop rcx
	pop rbx

	ret

Asm_Set_Mandelbrot_2_Points endp
;-------------------------------------------------------------------------------------------------------------
Asm_Set_Mandelbrot_4_Points proc
; extern "C" int Asm_Set_Mandelbrot_4_Points(char *video_buf, SPacked_XY_4 *packed_xy, int *palette_rgb, int colors_count);
; Параметры:
; RCX - video_buf
; RDX - packed_xy
; R8 - palette_rgb
; R9 - colors_count
; Возврат: EAX 

	push rbx
	push rcx
	push r10
	push r11
	push r12

	mov r11, 1111b  ; R11[3..0] - Маска значений, для которых уже посчитан индекс (0/1 - да / ещё нет)

	vmovupd ymm8, [ rdx ]  ; YMM8 = { 4.0, 4.0, 4.0, 4.0 }

	mov r10, rcx  ; R10 = video_buf

	mov rcx, r9  ; RCX = colors_count = количество итераций

	vmovupd ymm1, [ rdx + 8 * 4 ]  ; YMM1 = { x1_0, x2_0, x3_0, x4_0 }
	vmovupd ymm2, [ rdx + 8 * 8 ]  ; YMM2 = { y1_0, y2_0, y3_0, y4_0 }

;	x_n = 0.0;
;	y_n = 0.0;
	vxorpd ymm3, ymm3, ymm3  ; YMM3 = { x1_n, x2_n, x3_n, x4_n } = { 0.0, 0.0, 0.0, 0.0 }
	vxorpd ymm4, ymm4, ymm4  ; YMM4 = { y1_n, y2_n, y3_n, y4_n } = { 0.0, 0.0, 0.0, 0.0 }

_iteration_start:
;	for (i = 0; i < colors_count; i++)
;	{
;		x_n1 = x_n * x_n - y_n * y_n + x_0;

	vmovapd ymm5, ymm3  ; YMM5 = YMM3 = { x1_n, x2_n, x3_n, x4_n }
	vmovapd ymm6, ymm4  ; YMM6 = YMM4 = { y1_n, y2_n, y3_n, y4_n }

	vmulpd ymm5, ymm3, ymm3  ; YMM5 = { x1_n * x1_n,.. x4_n * x4_n }
	vmulpd ymm6, ymm4, ymm4  ; YMM6 = { y1_n * y1_n,.. y4_n * y4_n }

	vsubpd ymm5, ymm5, ymm6  ; YMM5 = { x1_n * x1_n - y1_n * y1_n,..  x4_n * x4_n - y4_n * y4_n }

	vaddpd ymm5, ymm5, ymm1  ; YMM5 = { x1_n1,.. x4_n1 }

;		y_n1 = 2.0 * x_n * y_n + y_0;

	; movaps xmm7, xmm3  ; XMM7 = { x1_n, x2_n }
	vmulpd ymm7, ymm4, ymm3  ; YMM7 = { x1_n * y1_n,.. x4_n * y4_n }
	vaddpd ymm7, ymm7, ymm7  ; yMM7 = { 2.0 * x1_n * y1_n,..  2.0 * x4_n * y4_n }
	vaddpd ymm7, ymm7, ymm2  ; yMM7 = { y1_n1,.. y4_n1 }

;		distance = x_n1 * x_n1 + y_n1 * y_n1;

	; movaps xmm6, xmm5  ; XMM6 = { x1_n1, x2_n1 }
	vmulpd ymm6, ymm5, ymm5  ; YMM6 = { x1_n1 * x1_n1,.. x4_n1 * x4_n1 }

	; movaps xmm0, xmm7  ; XMM7 = { y1_n1, y1_n1 }
	vmulpd ymm0, ymm7, ymm7  ; YMM0 = { y1_n1 * y1_n1,.. y2_n1 * y2_n1 }

	vaddpd ymm0, ymm0, ymm6  ; YMM0 = { distance_1,.. distance_4 }

;		x_n = x_n1;
;		y_n = y_n1;

	vmovaps ymm3, ymm5  ; YMM3 = x_n = x_n1
	vmovaps ymm4, ymm7  ; YMM4 = y_n = y_n1

;		if (distance > 4.0)
;			break;

	vcmpnlepd ymm0, ymm0, ymm8  ; YMM0 > 4.0 ?

	vmovmskpd eax, ymm0
	and rax, r11  ; Накладываем маску, обнуляя биты, для которых уже был посчитан индекс

	cmp rax, 0
	jne _check_bits


	loop _iteration_start  ; Продолжаем, т.к. нет новых индексов

	; Дойдём сюда, когда закончатся все итерации, при этом в RAX - результат последнего сравнения
	; Надо к этому результату применить результат, накопленный в маске

	or rax, r11  ; Принудительно отмечаем оставшиеся биты как те, для которых надо посчитать индекс

_check_bits:
	xor edx, edx  ; Начнём проверять EAX с 0-го бита

_check_one_bit:
	bt eax, edx
	jnc _check_next_value  ; Переходим к следующему биту, если текущий = 0

	mov r12, r9
	sub r12, rcx  ; R12 = colors_count - count = color_index = итерация, на которой прервался цикл

	; Если RCX == 0, то выбираем чёрный цвет (т.е. 0), иначе - цвет из палитры

	xor ebx, ebx  ; EBX = 0 не случай, если цвет - чёрный, а также, чтобы не сравнивать с нулевой константой
	cmp ecx, ebx
	cmovne ebx, [ r8 + r12 * 4 ]  ; EBX = palette_rgb[color_index]

	mov [ r10 + rdx * 4 ], ebx  ; Сохраняем пиксель в память

	btr r11d, edx  ; Сбросим бит маски, чтобы не проверять больше этот индекс

_check_next_value:
	inc edx
	cmp edx, 4
	jl _check_one_bit  ; Продолжим проверять биты [3..0]


	cmp r11d, 0
	je _exit

	dec rcx

	cmp rcx, 0
	jg _iteration_start  ; Продолжаем, т.к. не все ещё индексы посчитаны


_exit:
	pop r12
	pop r11
	pop r10
	pop rcx
	pop rbx

	ret

Asm_Set_Mandelbrot_4_Points endp
;-------------------------------------------------------------------------------------------------------------
end
