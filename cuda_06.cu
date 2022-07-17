#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>

__global__ void GPU_kernel(int maxelemszam)
{
 int i;
 int startindex = threadIdx.x + (blockIdx.x * blockDim.x);
 int leptek = blockDim.x * gridDim.x;
 for (i = startindex; i < maxelemszam; i += leptek)
 {
  printf("%i\n", i);
 }
}

int main(void)
{
 int szalak_szama = 128;
 int blokkok_szama = (100000 + szalak_szama - 1) / szalak_szama;

 GPU_kernel <<< blokkok_szama, szalak_szama >>> (100000);
 cudaDeviceSynchronize();
 printf("Vegrehajtas befejezve!\n");
 return 0;
}
