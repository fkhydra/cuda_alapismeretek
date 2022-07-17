#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>

__global__ void GPU_kernel(int maxelemszam)
{
 int i;
 for (i = 0; i < maxelemszam; ++i)
 {
  printf("%i\n", i);
 }
}

int main(void)
{
 GPU_kernel << < 1, 1 >> > (100);
 cudaDeviceSynchronize();
 printf("Vegrehajtas befejezve!\n");
 return 0;
}
