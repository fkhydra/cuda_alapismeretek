#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>

int main()
{
 int darabszam;
 cudaGetDeviceCount(&darabszam);
 printf("%i darab CUDA eszkozt talaltam...",darabszam);
 return 0;
}
