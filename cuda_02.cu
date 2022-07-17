#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "helper_cuda.h"
#include <stdio.h>

int main()
{
 int darabszam;
 int dev, driverVersion = 0, runtimeVersion = 0;

 cudaGetDeviceCount(&darabszam);
 if (darabszam == 0) printf("Nem talaltam tamogatott CUDA eszkozt!\n");
 else printf("%i darab CUDA eszkozt talaltam...", darabszam);

 for (dev = 0; dev < darabszam; ++dev)
 {
  cudaSetDevice(dev);
  cudaDeviceProp deviceProp;
  cudaGetDeviceProperties(&deviceProp, dev);
  printf("\n%d. eszkoz neve: \"%s\"\n", dev, deviceProp.name);

  cudaDriverGetVersion(&driverVersion);
  cudaRuntimeGetVersion(&runtimeVersion);

  printf("  CUDA meghajto verzioja / Futtato kornyezet verzioja          %d.%d / %d.%d\n",
   driverVersion / 1000, (driverVersion % 100) / 10,
   runtimeVersion / 1000, (runtimeVersion % 100) / 10);

  printf("  CUDA Capability verzio:   %d.%d\n",
   deviceProp.major, deviceProp.minor);

  char msg[256];
  sprintf_s(msg, sizeof(msg),
   "  Osszmemoria:     %.0f MBytes "
   "(%llu bytes)\n",
   static_cast<float>(deviceProp.totalGlobalMem / 1048576.0f),
   (unsigned long long)deviceProp.totalGlobalMem);
  printf("%s", msg);

  printf("  (%2d) Multiprocesszor, (%3d) CUDA mag/MP: %d CUDA mag\n",
   deviceProp.multiProcessorCount,
   _ConvertSMVer2Cores(deviceProp.major, deviceProp.minor),
   _ConvertSMVer2Cores(deviceProp.major, deviceProp.minor) *
   deviceProp.multiProcessorCount);

  printf(
   "  GPU max. orajel:                            %.0f MHz (%0.2f "
   "GHz)\n",
   deviceProp.clockRate * 1e-3f, deviceProp.clockRate * 1e-6f);

  printf("  Memoria orajel:                             %.0f Mhz\n",
   deviceProp.memoryClockRate * 1e-3f);
  printf("  Memoria atviteli sebesseg:                  %d-bit\n",
   deviceProp.memoryBusWidth);
  printf("  Warp merete:                                %d\n",
   deviceProp.warpSize);
  printf("  Szalak max. szama / multiprocessor: %d\n",
   deviceProp.maxThreadsPerMultiProcessor);
  printf("  Szalak max. szama / blokk:  %d\n",
   deviceProp.maxThreadsPerBlock);
  printf("  Blokk maximalis dimenzioi (x,y,z):  (%d, %d, %d)\n",
   deviceProp.maxThreadsDim[0], deviceProp.maxThreadsDim[1],
   deviceProp.maxThreadsDim[2]);
  printf("  Grid maximalis dimenzioi (x,y,z): (%d, %d, %d)\n",
   deviceProp.maxGridSize[0], deviceProp.maxGridSize[1],
   deviceProp.maxGridSize[2]);
 }
 return 0;
}
