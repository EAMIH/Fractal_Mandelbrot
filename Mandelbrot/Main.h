#pragma once

#include "resource.h"
#include "framework.h"

//------------------------------------------------------------------------------------------------------------
struct SRGB
{
	SRGB(unsigned char r, unsigned char g, unsigned char b)
		: R(r), G(g), B(b)
	{
	}

	unsigned char R, G, B;
};
//------------------------------------------------------------------------------------------------------------
struct SPoint_Double
{
	SPoint_Double();
	SPoint_Double(double x, double y);

	double X, Y;
};
//------------------------------------------------------------------------------------------------------------
struct SPacked_XY
{
	double Y0;
	double X0_1, X0_2;	// SIMD-пакет из 2-х значений
};
//------------------------------------------------------------------------------------------------------------
struct SPacked_XY_4
{
	SPacked_XY_4();

	// SIMD-пакеты из 4-х значений
	double Four_Fours[4];
	double X0[4];
	double Y0[4];
};
//------------------------------------------------------------------------------------------------------------
struct SPoint
{
	SPoint();

	SPoint(unsigned short x, unsigned short y);

	unsigned short X, Y;
};
//------------------------------------------------------------------------------------------------------------
struct SSize
{
	SSize();

	SSize(unsigned short width, unsigned short height);

	unsigned short Width, Height;
};
//------------------------------------------------------------------------------------------------------------
struct SBuf_Color
{
	SSize Buf_Size;

	unsigned int Color;
};
//------------------------------------------------------------------------------------------------------------
class AsFrame_DC
{
public:
	~AsFrame_DC();
	AsFrame_DC();

	HDC Get_DC(HWND hwnd, HDC hdc);
	char *Get_Buf();
	void Create_Color_Palette();
	void Create_Web_Palette();
	void Create_Two_Color_Palette(int start_index, const SRGB &color_1, const SRGB &color_2);
	void Draw_Color_Palette(HDC hdc);
	void Draw_Web_Palette(HDC hdc);
	void Draw_Multi_Color_Palette(HDC hdc);
	void Draw_Grayscale_Palette(HDC hdc);

	//int Width, Height;
	SSize Buf_Size;
	HBRUSH BG_Brush;
	HPEN White_Pen;

	static const int Colors_Count = 400;

	int Palette_RGB[Colors_Count];
	int Palette_Web[Colors_Count];

private:
	int Color_To_RGB(int color);

	HDC DC;
	HBITMAP Bitmap;
	char *Bitmap_Buf;

	HPEN Palette_Pens[Colors_Count];
	HBRUSH Palette_Brush[Colors_Count];
};
//------------------------------------------------------------------------------------------------------------
extern "C" void Asm_Draw(char *video_buf, SSize size);
extern "C" void Asm_Draw_Line(char *video_buf, SPoint start_point, SPoint end_point, SBuf_Color buf_color);
extern "C" void Asm_Draw_Horizontal_Line(char *video_buf, SPoint start_point, int length, SBuf_Color buf_color);
extern "C" void Asm_Set_Pixel(char *video_buf, SPoint point, SBuf_Color buf_color);
extern "C" int Asm_Get_Mandelbrot_Index(char *video_buf, double x_0, double y_0, int colors_count);
extern "C" int Asm_Set_Mandelbrot_Point(char *video_buf, SPoint_Double *xy_0, int *palette_rgb, int colors_count);
extern "C" int Asm_Set_Mandelbrot_2_Points(char *video_buf, SPacked_XY *xy_0, int *palette_rgb, int colors_count);
extern "C" int Asm_Set_Mandelbrot_4_Points(char *video_buf, SPacked_XY_4 *packed_xy, int *palette_rgb, int colors_count);
