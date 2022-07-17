#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>

__global__ void ertek_beallitas(int *c, int szam)
{
    c[0] = szam;
}

int main()
{
 int *dev0_adat;
 int *dev1_adat;
 int akt_adat=0;

 cudaSetDevice(0);
 cudaMalloc((void**)&dev0_adat, 1 * sizeof(int));
 cudaMemcpy(dev0_adat, &akt_adat, 1 * sizeof(int), cudaMemcpyHostToDevice); 
 cudaSetDevice(1);
 cudaMalloc((void**)&dev1_adat, 1 * sizeof(int)); 
 cudaMemcpy(dev0_adat, &akt_adat, 1 * sizeof(int), cudaMemcpyHostToDevice);
 printf("Memoria lefoglalva...\n");

 cudaSetDevice(0);
 ertek_beallitas << <1, 1 >> > (dev0_adat,1);
 cudaDeviceSynchronize();
 cudaSetDevice(1);
 ertek_beallitas << <1, 1 >> > (dev1_adat, 9);
 cudaDeviceSynchronize();
 printf("Kernelek ok...\n");

 cudaSetDevice(0);
 cudaMemcpy(&akt_adat, dev0_adat, 1 * sizeof(int), cudaMemcpyDeviceToHost);
 printf("DEV0: %i\n", akt_adat);
 cudaSetDevice(1);
 cudaMemcpy(&akt_adat, dev1_adat, 1 * sizeof(int), cudaMemcpyDeviceToHost);
 printf("DEV1: %i\n", akt_adat);

 cudaMemcpyPeer(dev0_adat,0, dev1_adat,1,1*sizeof(int));
 printf("Csere ok...\n");

 cudaSetDevice(0);
 cudaMemcpy(&akt_adat, dev0_adat, 1 * sizeof(int), cudaMemcpyDeviceToHost);
 printf("DEV0: %i\n",akt_adat);
 cudaSetDevice(1);
 cudaMemcpy(&akt_adat, dev1_adat, 1 * sizeof(int), cudaMemcpyDeviceToHost);
 printf("DEV1: %i\n", akt_adat);
 
 cudaFree(dev0_adat);
 cudaFree(dev1_adat);
 return 0;
}
