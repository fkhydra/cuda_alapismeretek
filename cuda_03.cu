#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>

void CPU_kernel(int maxelemszam)
{
 int i;
 for (i = 0; i < maxelemszam; ++i)
 {
  printf("%i\n", i);
 }
}

int main(void)
{
 CPU_kernel(100);
 printf("Vegrehajtas befejezve!\n");
 return 0;
}
