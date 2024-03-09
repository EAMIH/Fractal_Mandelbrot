#pragma once

#include "resource.h"
#include "framework.h"

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

	//int Width, Height;
	SSize Buf_Size;
	HBRUSH BG_Brush;
	HPEN White_Pen;

private:
	HDC DC;
	HBITMAP Bitmap;
	char *Bitmap_Buf;
};
//------------------------------------------------------------------------------------------------------------
extern "C" void Asm_Draw(char *video_buf, SSize size);
extern "C" void Asm_Draw_Line(char *video_buf, SPoint start_point, SPoint end_point, SBuf_Color buf_color);
extern "C" void Asm_Draw_Horizontal_Line(char *video_buf, SPoint start_point, int length, SBuf_Color buf_color);
