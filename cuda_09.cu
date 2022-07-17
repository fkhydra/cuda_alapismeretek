#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <math.h>
#include <stdio.h>
#include <windows.h>
#include <time.h>
#include <d2d1.h>
#include <d2d1helper.h>
#pragma comment(lib, "d2d1")

//*****double buffering*****
#define KEPERNYO_WIDTH 600
#define KEPERNYO_HEIGHT 400

D2D1_RECT_U display_area;
ID2D1Bitmap *memkeptarolo = NULL;
unsigned int kepadat[KEPERNYO_WIDTH * KEPERNYO_HEIGHT];
//**************************************

//**********STATISZTIKA*******************
int kezdet, vege;
FILE *statfajl;

void writestat(char *szoveg, int ertek);
void meres_start(void);
void meres_end(void);
int getrandom(int maxnum);
//***************************************

//**************PEGAZUS************
#define MAX_OBJ_NUM 1000000
float raw_verticesX[MAX_OBJ_NUM], raw_verticesY[MAX_OBJ_NUM];
int raw_colors[MAX_OBJ_NUM];
int raw_vertices_length;
//*******CUDA*************
float *dev_raw_verticesX, *dev_raw_verticesY;
unsigned int *dev_raw_colors;
unsigned int *dev_kepadat;
//************************
void data_transfer_to_GPU(void);
void D2D_rajzolas(ID2D1HwndRenderTarget* pRT);
__global__ void render_objects(int maxitemcount, float *arrayX, float *arrayY, unsigned int *colorpuffer, unsigned int *puffer);
//************************************

//***********STANDARD WIN32API WINDOWING************
ID2D1Factory* pD2DFactory = NULL;
ID2D1HwndRenderTarget* pRT = NULL;
#define HIBA_00 TEXT("Error:Program initialisation process.")
HINSTANCE hInstGlob;
int SajatiCmdShow;
char szClassName[] = "WindowsApp";
HWND Form1; //Ablak kezeloje
LRESULT CALLBACK WndProc0(HWND, UINT, WPARAM, LPARAM);
//******************************************************

//*****double buffering*****
void create_main_buffer(void);
void CUDA_cleanup_main_buffer(void);
void swap_main_buffer(void);
//**************************************

//*****drawig algorithms*****
__device__ void CUDA_SetPixel(int x1, int y1, int color, unsigned int *puffer);
__device__ void CUDA_DrawLine(int x1, int y1, int x2, int y2, int color, unsigned int *puffer);
__device__ void CUDA_FillTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int color, unsigned int *puffer);
//**************************************

//*********************************
//The main entry point of our program
//*********************************
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
 static TCHAR szAppName[] = TEXT("StdWinClassName");
 HWND hwnd;
 MSG msg;
 WNDCLASS wndclass0;
 SajatiCmdShow = iCmdShow;
 hInstGlob = hInstance;

 //*********************************
 //Preparing Windows class
 //*********************************
 wndclass0.style = CS_HREDRAW | CS_VREDRAW;
 wndclass0.lpfnWndProc = WndProc0;
 wndclass0.cbClsExtra = 0;
 wndclass0.cbWndExtra = 0;
 wndclass0.hInstance = hInstance;
 wndclass0.hIcon = LoadIcon(NULL, IDI_APPLICATION);
 wndclass0.hCursor = LoadCursor(NULL, IDC_ARROW);
 wndclass0.hbrBackground = (HBRUSH)GetStockObject(LTGRAY_BRUSH);
 wndclass0.lpszMenuName = NULL;
 wndclass0.lpszClassName = TEXT("WIN0");

 //*********************************
 //Registering our windows class
 //*********************************
 if (!RegisterClass(&wndclass0))
 {
  MessageBox(NULL, HIBA_00, TEXT("Program Start"), MB_ICONERROR);
  return 0;
 }

 //*********************************
 //Creating the window
 //*********************************
 Form1 = CreateWindow(TEXT("WIN0"),
  TEXT("CUDA - DIRECT2D"),
  (WS_OVERLAPPED | WS_SYSMENU | WS_THICKFRAME | WS_MAXIMIZEBOX | WS_MINIMIZEBOX),
  50,
  50,
  KEPERNYO_WIDTH,
  KEPERNYO_HEIGHT,
  NULL,
  NULL,
  hInstance,
  NULL);

 //*********************************
 //Displaying the window
 //*********************************
 ShowWindow(Form1, SajatiCmdShow);
 UpdateWindow(Form1);

 //*********************************
 //Activating the message processing for our window
 //*********************************
 while (GetMessage(&msg, NULL, 0, 0))
 {
  TranslateMessage(&msg);
  DispatchMessage(&msg);
 }
 return msg.wParam;
}

//*********************************
//The window's callback funtcion: handling events
//*********************************
LRESULT CALLBACK WndProc0(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
 HDC hdc;
 PAINTSTRUCT ps;

 switch (message)
 {
  //*********************************
  //When creating the window
  //*********************************
 case WM_CREATE:
  srand((unsigned)time(NULL));
  D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &pD2DFactory);
  pD2DFactory->CreateHwndRenderTarget(
   D2D1::RenderTargetProperties(),
   D2D1::HwndRenderTargetProperties(
    hwnd, D2D1::SizeU(KEPERNYO_WIDTH, KEPERNYO_HEIGHT)),
   &pRT);
  cudaDeviceReset();
  create_main_buffer();
  cudaMalloc((void**)&dev_raw_verticesX, MAX_OBJ_NUM * sizeof(float));
  cudaMalloc((void**)&dev_raw_verticesY, MAX_OBJ_NUM * sizeof(float));
  cudaMalloc((void**)&dev_raw_colors, MAX_OBJ_NUM * sizeof(unsigned int));
  cudaMalloc((void**)&dev_kepadat, KEPERNYO_WIDTH * KEPERNYO_HEIGHT * sizeof(unsigned int));

  int i;
  for (i = raw_vertices_length = 0; i < MAX_OBJ_NUM; ++i)
  {
   raw_verticesX[i] = getrandom(KEPERNYO_WIDTH);
   raw_verticesY[i] = getrandom(KEPERNYO_HEIGHT);
   raw_colors[i] = RGB(getrandom(255), getrandom(255), getrandom(255));
   ++raw_vertices_length;
  }
  data_transfer_to_GPU();
  return 0;
  //*********************************
  //to eliminate color flickering
  //*********************************
 case WM_ERASEBKGND:
  return (LRESULT)1;
  //*********************************
  //Repainting the client area of the window
  //*********************************
 case WM_PAINT:
  hdc = BeginPaint(hwnd, &ps);
  EndPaint(hwnd, &ps);
  D2D_rajzolas(pRT);
  return 0;
  //*********************************
  //Closing the window, freeing resources
  //*********************************
 case WM_CLOSE:
  pRT->Release();
  pD2DFactory->Release();
  cudaFree(dev_raw_verticesX);
  cudaFree(dev_raw_verticesY);
  cudaFree(dev_raw_colors);
  cudaFree(dev_kepadat);
  DestroyWindow(hwnd);
  return 0;
  //*********************************
  //Destroying the window
  //*********************************
 case WM_DESTROY:
  PostQuitMessage(0);
  return 0;
 }
 return DefWindowProc(hwnd, message, wParam, lParam);
}

//********************************
//PEGAZUS
//********************************
void create_main_buffer(void)
{
 pRT->CreateBitmap(D2D1::SizeU(KEPERNYO_WIDTH, KEPERNYO_HEIGHT),
  D2D1::BitmapProperties(D2D1::PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM,
   D2D1_ALPHA_MODE_IGNORE)), &memkeptarolo);
}

void CUDA_cleanup_main_buffer(void)
{
 cudaMemset(dev_kepadat, 200, KEPERNYO_HEIGHT*KEPERNYO_WIDTH * sizeof(unsigned int));
}

void swap_main_buffer(void)
{
 display_area.left = 0;
 display_area.top = 0;
 display_area.right = KEPERNYO_WIDTH;
 display_area.bottom = KEPERNYO_HEIGHT;
 memkeptarolo->CopyFromMemory(&display_area, kepadat, KEPERNYO_WIDTH * sizeof(unsigned int));
 pRT->BeginDraw();
 pRT->DrawBitmap(memkeptarolo, D2D1::RectF(0.0f, 0.0f, KEPERNYO_WIDTH, KEPERNYO_HEIGHT), 1.0f, D2D1_BITMAP_INTERPOLATION_MODE_NEAREST_NEIGHBOR, NULL);
 pRT->EndDraw();
}

__device__ void CUDA_SetPixel(int x1, int y1, int color, unsigned int *puffer)
{
 puffer[(y1 * KEPERNYO_WIDTH) + x1] = color;
}

__device__ void CUDA_DrawLine(int x1, int y1, int x2, int y2, int color, unsigned int *puffer)
{
 bool flip = false;
 int swap, offset;

 if (abs(x2 - x1) < 2 && abs(y2 - y1) < 2)
 {
  puffer[(y2*KEPERNYO_WIDTH) + x2] = color; return;
 }
 if (abs(x1 - x2) < abs(y1 - y2))
 {
  swap = x1;
  x1 = y1;
  y1 = swap;

  swap = x2;
  x2 = y2;
  y2 = swap;
  flip = true;
 }
 if (x1 > x2)
 {
  swap = x1;
  x1 = x2;
  x2 = swap;

  swap = y1;
  y1 = y2;
  y2 = swap;
 }
 int dx = x2 - x1;
 int dy = y2 - y1;

 int marker1 = abs(dy) * 2;
 int marker2 = 0;
 int y = y1, x;

 if (flip)
 {
  for (x = x1; x <= x2; ++x)
  {
   offset = (x * KEPERNYO_WIDTH);
   puffer[offset + y] = color;
   marker2 += marker1;
   if (marker2 > dx)
   {
    y += (y2 > y1 ? 1 : -1);
    marker2 -= dx * 2;
   }
  }
 }
 else
 {
  for (x = x1; x <= x2; ++x)
  {
   offset = (y * KEPERNYO_WIDTH);
   puffer[offset + x] = color;
   marker2 += marker1;
   if (marker2 > dx)
   {
    y += (y2 > y1 ? 1 : -1);
    marker2 -= dx * 2;
   }
  }
 }
}

__device__ void CUDA_FillTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int color, unsigned int *puffer)
{
 int Ax, Ay, Bx, By, i, j;
 int swapx, swapy, offset, maxoffset = KEPERNYO_HEIGHT * KEPERNYO_WIDTH;
 if (y1 == y2 && y1 == y3) return;

 if (y1 > y2)
 {
  swapx = x1;
  swapy = y1;
  x1 = x2;
  y1 = y2;
  x2 = swapx;
  y2 = swapy;
 }
 if (y1 > y3)
 {
  swapx = x1;
  swapy = y1;
  x1 = x3;
  y1 = y3;
  x3 = swapx;
  y3 = swapy;
 }
 if (y2 > y3)
 {
  swapx = x3;
  swapy = y3;
  x3 = x2;
  y3 = y2;
  x2 = swapx;
  y2 = swapy;
 }
 int t_height = y3 - y1;
 for (i = 0; i < t_height; ++i)
 {
  bool lower_part = i > y2 - y1 || y2 == y1;
  int part_height = lower_part ? y3 - y2 : y2 - y1;
  float alpha = (float)i / t_height;
  float beta = (float)(i - (lower_part ? y2 - y1 : 0)) / part_height;
  Ax = x1 + (x3 - x1)*alpha;
  Ay = y1 + (y3 - y1)*alpha;
  Bx = lower_part ? x2 + (x3 - x2)*beta : x1 + (x2 - x1)*beta;
  By = lower_part ? y2 + (y3 - y2)*beta : y1 + (y2 - y1)*beta;
  if (Ax > Bx)
  {
   swapx = Ax;
   swapy = Ay;
   Ax = Bx;
   Ay = By;
   Bx = swapx;
   By = swapy;
  }

  offset = (y1 + i)*KEPERNYO_WIDTH;
  for (j = Ax; j < Bx; ++j)
  {
   if (offset + j > maxoffset) continue;
   puffer[offset + j] = color;
  }
 }
}

void data_transfer_to_GPU(void)
{
 cudaMemcpy(dev_raw_verticesX, raw_verticesX, raw_vertices_length * sizeof(float), cudaMemcpyHostToDevice);
 cudaMemcpy(dev_raw_verticesY, raw_verticesY, raw_vertices_length * sizeof(float), cudaMemcpyHostToDevice);
 cudaMemcpy(dev_raw_colors, raw_colors, raw_vertices_length * sizeof(unsigned int), cudaMemcpyHostToDevice);
}

void D2D_rajzolas(ID2D1HwndRenderTarget* pRT)
{
 char hibauzenet[256];

 meres_start();
 CUDA_cleanup_main_buffer();
 cudaDeviceSynchronize();//opcionálisan elhagyható
 meres_end();
 writestat("Képpuffer törlése: ", vege);
 strcpy_s(hibauzenet, cudaGetErrorString(cudaGetLastError()));
 SetWindowTextA(Form1, hibauzenet);

 meres_start();
 int szalak_szama = 128;
 int blokkok_szama = (100000 + szalak_szama - 1) / szalak_szama;
 render_objects << <80,8 >> > (raw_vertices_length, dev_raw_verticesX, dev_raw_verticesY, dev_raw_colors, dev_kepadat);
 cudaDeviceSynchronize();
 meres_end();
 writestat("Rendereléshez szükséges idő: ", vege);
 strcpy_s(hibauzenet, cudaGetErrorString(cudaGetLastError()));
 SetWindowTextA(Form1, hibauzenet);

 meres_start();
 cudaMemcpy(kepadat, dev_kepadat, KEPERNYO_WIDTH * KEPERNYO_HEIGHT * sizeof(unsigned int), cudaMemcpyDeviceToHost);
 strcpy_s(hibauzenet, cudaGetErrorString(cudaGetLastError()));
 SetWindowTextA(Form1, hibauzenet);
 swap_main_buffer();
 meres_end();
 writestat("Képkocka másolása és megjelenítése: ", vege);
}

__global__ void render_objects(int maxitemcount, float *arrayX, float *arrayY, unsigned int *colorpuffer, unsigned int *puffer)
{
 int i, px, py, tesztcolor;
 int index = (blockIdx.x * blockDim.x) + (threadIdx.x * 2);
 int stride = blockDim.x * gridDim.x;

 for (i = index; i < maxitemcount - 1; i += stride)
 {
  //CUDA_SetPixel(arrayX[i], arrayY[i], colorpuffer[i], puffer);
  CUDA_DrawLine(arrayX[i], arrayY[i], arrayX[i + 1], arrayY[i + 1], colorpuffer[i], puffer);
  //CUDA_FillTriangle(arrayX[i], arrayY[i], arrayX[i + 1], arrayY[i + 1], arrayX[i + 2], arrayY[i + 2], colorpuffer[i], puffer);
 }
}

void meres_start(void)
{
 kezdet = GetTickCount();
}

void meres_end(void)
{
 vege = GetTickCount() - kezdet;
}

void writestat(char *szoveg, int ertek)
{
 statfajl = fopen("statisztika.txt", "at");
 if (statfajl == NULL) return;
 fprintf(statfajl, "%s: ", szoveg);
 fprintf(statfajl, "%i\n", ertek);
 fclose(statfajl);
}

int getrandom(int maxnum)
{
 return (double)rand() / (RAND_MAX + 1) * maxnum;
}
