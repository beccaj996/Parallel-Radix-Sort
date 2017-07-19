//new

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

// #define MAX 2147483647;
#define MAX 50;

unsigned int * valuesList;
unsigned int totalNumbers;

void printArray(int * array, int size) {
	
	printf("[ ");
  	for (int i = 0; i < size; i++) {
    	printf("%d ", array[i]);
	}

  	printf("]\n");
}

void printArrayU(unsigned int * array, int size) {
	
	printf("[ ");
  	for (int i = 0; i < size; i++) {
    	printf("%d ", array[i]);
	}

  	printf("]\n");
}


__global__ void radixSort(unsigned int* valuesList, int digit, int* testHistogram) {

	// each element is corresponds to a bucket from 0-9
	// each element initialized to 0
	__shared__ int histogram[10];
	int OFFSETOriginal[10] = { 0 };
	int OFFSETChanged[10] = { 0 };

	// create a second temporary list of the same size
	// unsigned int* tempList;

	 int tid = threadIdx.x + blockIdx.x * blockDim.x; // FIXME: Not sure if this line is correct
	//int tid = threadIdx.x; 


	// take element in values at this instanced thread and find the digit 
	// we're looking for thats passed in and increment the corresponding element 
	// in the histogram
	if (tid < digit)
	  // histogram[valuesList[tid] / digit]++;
	  atomicAdd(&histogram[valuesList[tid]/digit], 1);
	__syncthreads();

	// find offset values
	OFFSETOriginal[0] = histogram[0];
	OFFSETChanged[0] = OFFSETOriginal[0];
	for (int i = 1; i < 10; i++) {
		testHistogram[i] = histogram[i]++;
		OFFSETOriginal[i] = OFFSETOriginal[i-1] + histogram[i];
		OFFSETChanged[i] = OFFSETOriginal[i];
	}

	return;

}

__device__ void bucketSort(int* values, int digit) {

}

int * histogram;

int main(int argc, char **argv) {

	totalNumbers = atoi(argv[1]);

	valuesList = (unsigned int *)malloc(sizeof(unsigned int)*totalNumbers);
	histogram = (int*)malloc(sizeof(int)*10);
	unsigned int* d_valuesList;
	int* d_histogram;

	srand(1);	
	// generate totalNumbers random numbers for valuesList
	for (int i = 0; i < totalNumbers; i++) {
		valuesList[i] = (int) rand()%MAX;
	}

	// fill histogram with 0's
	for (int i = 0; i < 10; i++) {
		histogram[i] = 0;
	}

	cudaMalloc((void **) &d_valuesList, sizeof(unsigned int)*totalNumbers);
	cudaMemcpy(d_valuesList, valuesList, sizeof(unsigned int)*totalNumbers, cudaMemcpyHostToDevice);

	cudaMalloc((void**) &d_histogram, sizeof(int)*10);
	cudaMemcpy(d_histogram, histogram, sizeof(int)*10, cudaMemcpyHostToDevice);

	// start with 10th digit. unsigned int limits the digit size to 10 so there can
	// only be a max of 10 digits.
	dim3 dimBlock(10,1);
	dim3 dimGrid(1,1);
	radixSort<<<dimGrid, dimBlock>>>(d_valuesList, 10, d_histogram);

	cudaMemcpy(valuesList, d_valuesList, sizeof(unsigned int)*totalNumbers, cudaMemcpyDeviceToHost);
	cudaFree(d_valuesList);

	cudaMemcpy(histogram, d_histogram, sizeof(int)*10, cudaMemcpyDeviceToHost);
	cudaFree(d_histogram);

	// print valuesList
	printf("VALUES:\n");
	printArrayU(valuesList, totalNumbers);

	printf("check.\n");
	printf("HISTOGRAM:\n");
	printArray(histogram, 10);

	return 0;
}
