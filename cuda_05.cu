#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>

__global__ void GPU_kernel(int maxelemszam)
{
 int i;
 int startindex = threadIdx.x;
 int leptek = blockDim.x;
 for (i = startindex; i < maxelemszam; i += leptek)
 {
  printf("%i\n", i);
 }
}

int main(void)
{
 GPU_kernel << < 1, 10 >> > (100);
 cudaDeviceSynchronize();
 printf("Vegrehajtas befejezve!\n");
 return 0;
}
