#pragma once

#include "resource.h"
#include "framework.h"

//------------------------------------------------------------------------------------------------------------
class AsFrame_DC
{
public:
	~AsFrame_DC();
	AsFrame_DC();

	HDC Get_DC(HWND hwnd, HDC hdc);

	int Width, Height;
	HBRUSH BG_Brush;
	HPEN White_Pen;

private:
	HDC DC;
	HBITMAP Bitmap;
};
//------------------------------------------------------------------------------------------------------------
