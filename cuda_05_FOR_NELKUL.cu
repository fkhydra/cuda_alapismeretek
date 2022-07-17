#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>

__global__ void GPU_kernel(int maxelemszam)
{
 int aktualis_index = threadIdx.x + (blockIdx.x * blockDim.x);
 if (aktualis_index < maxelemszam) printf("%i\n", aktualis_index);
}

int main(void)
{
 GPU_kernel << < 1, 10 >> > (100);
 cudaDeviceSynchronize();
 printf("Vegrehajtas befejezve!\n");
 return 0;
}
