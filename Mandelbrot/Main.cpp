#include "Main.h"

// SPoint
//------------------------------------------------------------------------------------------------------------
SPoint::SPoint()
: X(0), Y(0)
{
}
//------------------------------------------------------------------------------------------------------------
SPoint::SPoint(unsigned short x, unsigned short y)
: X(x), Y(y)
{
}
//------------------------------------------------------------------------------------------------------------




// SSize
//------------------------------------------------------------------------------------------------------------
SSize::SSize()
: Width(0), Height(0)
{
}
//------------------------------------------------------------------------------------------------------------
SSize::SSize(unsigned short width, unsigned short height)
: Width(width), Height(height)
{
}
//------------------------------------------------------------------------------------------------------------




// AsFrame_DC
//------------------------------------------------------------------------------------------------------------
AsFrame_DC::~AsFrame_DC()
{
	if (Bitmap != 0)
		DeleteObject(Bitmap);

	if (DC != 0)
		DeleteObject(DC);
}
//------------------------------------------------------------------------------------------------------------
AsFrame_DC::AsFrame_DC()
: DC(0), Bitmap(0), BG_Brush(0), Bitmap_Buf(0)
{
	BG_Brush = CreateSolidBrush(RGB(0, 0, 0));
	White_Pen = CreatePen(PS_SOLID, 0, RGB(255, 255, 255) );
}
//------------------------------------------------------------------------------------------------------------
HDC AsFrame_DC::Get_DC(HWND hwnd, HDC hdc)
{
	int dc_width, dc_height;
	RECT rect;
	BITMAPINFO bmp_info{};

	GetClientRect(hwnd, &rect);

	dc_width = rect.right - rect.left;
	dc_height = rect.bottom - rect.top;

	if (dc_width != Buf_Size.Width && dc_height != Buf_Size.Height)
	{
		if (Bitmap != 0)
			DeleteObject(Bitmap);

		if (DC != 0)
			DeleteObject(DC);

		Buf_Size.Width = dc_width;
		Buf_Size.Height = dc_height;

		DC = CreateCompatibleDC(hdc);
		//Bitmap = CreateCompatibleBitmap(hdc, Width, Height);

		bmp_info.bmiHeader.biSize = sizeof(BITMAPINFO);
		bmp_info.bmiHeader.biWidth = Buf_Size.Width;
		bmp_info.bmiHeader.biHeight = Buf_Size.Height;
		bmp_info.bmiHeader.biPlanes = 1;
		bmp_info.bmiHeader.biBitCount = 32;
		bmp_info.bmiHeader.biCompression = BI_RGB;

		Bitmap = CreateDIBSection(hdc, &bmp_info, DIB_RGB_COLORS, (void **)&Bitmap_Buf, 0, 0);

		if (Bitmap != 0)
			SelectObject(DC, Bitmap);

		++rect.right;
		++rect.bottom;

		SelectObject(DC, BG_Brush);
		Rectangle(DC, rect.left, rect.top, rect.right, rect.bottom);
	}

	return DC;
}
//------------------------------------------------------------------------------------------------------------
char *AsFrame_DC::Get_Buf()
{
	return Bitmap_Buf;
}
//------------------------------------------------------------------------------------------------------------




//------------------------------------------------------------------------------------------------------------
#define MAX_LOADSTRING 100
// Global Variables:
float Main_Scale = 1.0f;
AsFrame_DC Frame_DC;
HINSTANCE hInst;                                // current instance
WCHAR szTitle[MAX_LOADSTRING];                  // The title bar text
WCHAR szWindowClass[MAX_LOADSTRING];            // the main window class name
//------------------------------------------------------------------------------------------------------------
// Forward declarations of functions included in this code module:
ATOM                MyRegisterClass(HINSTANCE hInstance);
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK    About(HWND, UINT, WPARAM, LPARAM);
//------------------------------------------------------------------------------------------------------------
int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
	_In_opt_ HINSTANCE hPrevInstance,
	_In_ LPWSTR    lpCmdLine,
	_In_ int       nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);

	// TODO: Place code here.

	// Initialize global strings
	LoadStringW(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
	LoadStringW(hInstance, IDC_MANDELBROT, szWindowClass, MAX_LOADSTRING);
	MyRegisterClass(hInstance);

	// Perform application initialization:
	if (!InitInstance(hInstance, nCmdShow))
	{
		return FALSE;
	}

	HACCEL hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_MANDELBROT));

	MSG msg;

	// Main message loop:
	while (GetMessage(&msg, nullptr, 0, 0))
	{
		if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}

	return (int)msg.wParam;
}
//------------------------------------------------------------------------------------------------------------
ATOM MyRegisterClass(HINSTANCE hInstance)
{
	WNDCLASSEXW wcex;

	wcex.cbSize = sizeof(WNDCLASSEX);

	wcex.style = CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc = WndProc;
	wcex.cbClsExtra = 0;
	wcex.cbWndExtra = 0;
	wcex.hInstance = hInstance;
	wcex.hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_MANDELBROT));
	wcex.hCursor = LoadCursor(nullptr, IDC_ARROW);
	wcex.hbrBackground = Frame_DC.BG_Brush;
	wcex.lpszMenuName = MAKEINTRESOURCEW(IDC_MANDELBROT);
	wcex.lpszClassName = szWindowClass;
	wcex.hIconSm = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));

	return RegisterClassExW(&wcex);
}
//------------------------------------------------------------------------------------------------------------
BOOL InitInstance(HINSTANCE instance, int command_show)
{

	HWND hwnd;
	RECT window_rect;

	hInst = instance;

	window_rect.left = 0;
	window_rect.top = 0;
	window_rect.right = 320 * 3;
	window_rect.bottom = 200 * 3;

	AdjustWindowRect(&window_rect, WS_OVERLAPPEDWINDOW - WS_THICKFRAME, TRUE);

	hwnd = CreateWindowW(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW - WS_THICKFRAME, 0, 0, window_rect.right - window_rect.left, window_rect.bottom - window_rect.top, 0, 0, instance, 0);

	if (hwnd == 0)
		return FALSE;

	ShowWindow(hwnd, command_show);
	UpdateWindow(hwnd);

	return TRUE;
}
//------------------------------------------------------------------------------------------------------------
void Clear_Screen(HDC frame_dc)
{
	int i;
	char *buf;
	SPoint start_point(0, 0);
	SPoint end_point(300, 400);
	SBuf_Color buf_color;
	unsigned long long start_tick, end_tick, delta_tick;

	buf = Frame_DC.Get_Buf();
	//Asm_Draw(buf, Frame_DC.Buf_Size);

	buf_color.Buf_Size = Frame_DC.Buf_Size;
	buf_color.Color = 0xffffffff;

	start_tick = __rdtsc();

	for (i = 0; i < Frame_DC.Buf_Size.Height; i++)
	{
		start_point.Y = i;
		Asm_Draw_Horizontal_Line(buf, start_point, Frame_DC.Buf_Size.Width, buf_color);
	}

	//SelectObject(frame_dc, Frame_DC.White_Pen);

	//for (i = 0; i < Frame_DC.Buf_Size.Height; i++)
	//{
	//	MoveToEx(frame_dc, 0, i, 0);
	//	LineTo(frame_dc, Frame_DC.Buf_Size.Width, i);
	//}

	end_tick = __rdtsc();

	delta_tick = end_tick - start_tick;  // 4135839, 4276307, 4135398;  405340, 412059, 298102
}
//------------------------------------------------------------------------------------------------------------
void Draw_Line(HDC frame_dc)
{
	int i, j;
	//char *buf;
	SPoint start_point(10, 0);
	SPoint end_point(910, 100);
	SBuf_Color buf_color;
	unsigned long long start_tick, end_tick, delta_tick;

	SelectObject(frame_dc, Frame_DC.White_Pen);

	start_tick = __rdtsc();

	for (j = 0; j < 1000; j++)
		for (i = 0; i < Frame_DC.Buf_Size.Height - 100; i++)
		{
			MoveToEx(frame_dc, 10, i, 0);
			LineTo(frame_dc, 910, i + 100);
		}

	//buf = Frame_DC.Get_Buf();
	//buf_color.Buf_Size = Frame_DC.Buf_Size;
	//buf_color.Color = 0xffffffff;

	//for (j = 0; j < 1000; j++)
	//	for (i = 0; i < Frame_DC.Buf_Size.Height - 100; i++)
	//	{
	//		start_point.Y = i;
	//		end_point.Y = i + 100;

	//		Asm_Draw_Line(buf, start_point, end_point, buf_color);
	//	}

	end_tick = __rdtsc();

	delta_tick = end_tick - start_tick;  // 3794444, 3736534, 3661211;  991257, 834824, 812938
													 // 79445658, 79462206, 81834156;  876670586, 897536322, 886424207
													 //										  3733109658, 3675917672, 3761133071
}
//------------------------------------------------------------------------------------------------------------
void Draw_Mandelbrot(HDC frame_dc)
{
	int i;
	int x, y;
	const int max_iter_count = 100;
	float x_0, y_0;
	float x_n, y_n;
	float x_n1, y_n1;
	float center_x = -1.0f + 0.005606f;
	float center_y = -0.3f;
	float x_scale = (float)Frame_DC.Buf_Size.Width / (float)Frame_DC.Buf_Size.Height * Main_Scale;
	float distance;
	unsigned char color;
	unsigned long long start_tick, end_tick, delta_tick;

	start_tick = __rdtsc();

	for (y = 0; y < Frame_DC.Buf_Size.Height; y++)
	{
		y_0 = (float)y / (float)Frame_DC.Buf_Size.Height - 0.5f;  // \CF\EE\EB\F3\F7\E0\E5\EC y_0 \E2 \E4\E8\E0\EF\E0\E7\EE\ED\E5 [-0.5 .. 0.5)
		y_0 = y_0 * Main_Scale + center_y;

		for (x = 0; x < Frame_DC.Buf_Size.Width; x++)
		{
			x_0 = (float)x / (float)Frame_DC.Buf_Size.Width - 0.5f;  // \CF\EE\EB\F3\F7\E0\E5\EC x_0 \E2 \E4\E8\E0\EF\E0\E7\EE\ED\E5 [-0.5 .. 0.5)
			x_0 = x_0 * x_scale + center_x;

			x_n = 0.0f;
			y_n = 0.0f;

			for (i = 0; i < max_iter_count; i++)
			{
				x_n1 = x_n * x_n - y_n * y_n + x_0;
				y_n1 = 2.0f * x_n * y_n + y_0;

				distance = x_n1 * x_n1 + y_n1 * y_n1;
				if (distance > 4.0f)
					break;

				x_n = x_n1;
				y_n = y_n1;
			}

			if (i == max_iter_count)
				color = 0;
			else
				color = i * 2;

			SetPixel(frame_dc, x, y, RGB(color, color, color));
		}
	}
	end_tick = __rdtsc();
	delta_tick = end_tick - start_tick;  // 5093001763, 3751900039, 5200691303

	SetPixel(frame_dc, Frame_DC.Buf_Size.Width / 2, Frame_DC.Buf_Size.Height / 2, RGB(255, 255, 255));  // 3820570558, 3829638160, 3826690214
}
//------------------------------------------------------------------------------------------------------------
void On_Paint(HWND hwnd)
{
	HDC hdc, frame_dc;
	PAINTSTRUCT ps;

	hdc = BeginPaint(hwnd, &ps);
	frame_dc = Frame_DC.Get_DC(hwnd, hdc);
	//Engine.Draw_Frame(frame_dc, ps.rcPaint);

	GdiFlush();

	//Clear_Screen(frame_dc);
	//Draw_Line(frame_dc);

	Main_Scale /= 2.0f;

	Draw_Mandelbrot(frame_dc);
	InvalidateRect(hwnd, &ps.rcPaint, FALSE);

	BitBlt(hdc, 0, 0, Frame_DC.Buf_Size.Width, Frame_DC.Buf_Size.Height, frame_dc, 0, 0, SRCCOPY);

	EndPaint(hwnd, &ps);
}
//------------------------------------------------------------------------------------------------------------
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
	{
	case WM_COMMAND:
	{
		int wmId = LOWORD(wParam);
		// Parse the menu selections:
		switch (wmId)
		{
		case IDM_ABOUT:
			DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
			break;
		case IDM_EXIT:
			DestroyWindow(hWnd);
			break;
		default:
			return DefWindowProc(hWnd, message, wParam, lParam);
		}
	}
	break;


	case WM_PAINT:
		On_Paint(hWnd);
	break;


	case WM_DESTROY:
		PostQuitMessage(0);
		break;


	default:
		return DefWindowProc(hWnd, message, wParam, lParam);
	}

	return 0;
}
//------------------------------------------------------------------------------------------------------------
INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);
	switch (message)
	{
	case WM_INITDIALOG:
		return (INT_PTR)TRUE;

	case WM_COMMAND:
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
		{
			EndDialog(hDlg, LOWORD(wParam));
			return (INT_PTR)TRUE;
		}
		break;
	}
	return (INT_PTR)FALSE;
}
//------------------------------------------------------------------------------------------------------------
