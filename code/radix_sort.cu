// Jake Manfre

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

#define MAX 2147483647;
// #define MAX 999999;

unsigned int * valuesList;
unsigned int* d_valuesList;

unsigned int totalNumbers;
int histogramSize;
int digit = 1000000000;

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

__global__ void radix_Sort(unsigned int* valuesList, int digitMax, int digitCurrent, int startPos, int arraySize, int* histogram, int* mainOffset, int* mainOffsetChanged) {

	 int tid = threadIdx.x + blockIdx.x * blockDim.x;
	 tid += startPos;
	// take element in values at this instanced thread and find the digit 
	// we're looking for thats passed in and increment the corresponding element 
	// in the histogram
	int tempDigitMax = digitMax;
	int tempDigitCurrent = digitCurrent;
	if (tid < startPos + arraySize) {
		int num = valuesList[tid];
		while (tempDigitMax != tempDigitCurrent) {
			num = valuesList[tid] / tempDigitMax;
			num *= tempDigitMax;

			tempDigitMax /= 10;
			num = valuesList[tid] - num;
		}

		atomicAdd(&histogram[num/digitCurrent], 1);
	}
	__syncthreads();

	// find offset before values
	mainOffset[0] = histogram[0];
	mainOffsetChanged[0] = histogram[0];
	for (int i = 1; i < 10; i++) {
		mainOffsetChanged[i] = mainOffsetChanged[i-1] + histogram[i];
		mainOffset[i] = mainOffset[i-1] + histogram[i];
	}


	__syncthreads();

	return;

}

__global__ void moveElements(unsigned int *valuesList, unsigned int *indexList, int startPos, int arraySize) {
	int tid = threadIdx.x + blockIdx.x * blockDim.x;
	tid += startPos;

	if (tid < startPos + arraySize) {
		int val = valuesList[tid];
		int index = indexList[tid] + startPos;

		__syncthreads();

		valuesList[index] = val;
	}

	__syncthreads();

	return;

}

void sortArray(int dig, int totalNums, int minIndex, int prevMin) {
	int * histogram;
	int * offset;
	int * offsetAfter;

	int* d_histogram;
	int* d_offset;
	int* d_offsetAfter;

	histogram = (int*)malloc(sizeof(int)*histogramSize);
	offset = (int*)malloc(sizeof(int)*histogramSize);
	offsetAfter = (int*)malloc(sizeof(int)*histogramSize);

	// fill histogram and offset arrays with 0's
	for (int i = 0; i < histogramSize; i++) {
		histogram[i] = 0;
		offset[i] = 0;
		offsetAfter[i] = 0;
	}

	cudaMalloc((void **) &d_valuesList, sizeof(unsigned int)*totalNumbers);
	cudaMalloc((void**) &d_histogram, sizeof(int)*histogramSize);
	cudaMalloc((void**) &d_offset, sizeof(int)*histogramSize);
	cudaMalloc((void**) &d_offsetAfter, sizeof(int)*histogramSize);

	cudaMemcpy(d_valuesList, valuesList, sizeof(unsigned int)*totalNumbers, cudaMemcpyHostToDevice);
	cudaMemcpy(d_histogram, histogram, sizeof(int)*histogramSize, cudaMemcpyHostToDevice);
	cudaMemcpy(d_offset, offset, sizeof(int)*histogramSize, cudaMemcpyHostToDevice);
	cudaMemcpy(d_offsetAfter, offsetAfter, sizeof(int)*histogramSize, cudaMemcpyHostToDevice);

	radix_Sort<<<(totalNums+255)/256, 256>>>(d_valuesList, digit, dig, minIndex, totalNums, d_histogram, d_offset, d_offsetAfter);

	// copy data back to host from the device
	cudaMemcpy(valuesList, d_valuesList, sizeof(unsigned int)*totalNumbers, cudaMemcpyDeviceToHost);
	cudaMemcpy(histogram, d_histogram, sizeof(int)*histogramSize, cudaMemcpyDeviceToHost);
	cudaMemcpy(offset, d_offset, sizeof(int)*histogramSize, cudaMemcpyDeviceToHost);
	cudaMemcpy(offsetAfter, d_offsetAfter, sizeof(int)*histogramSize, cudaMemcpyDeviceToHost);
	// free memory on device
	cudaFree(d_valuesList);
	cudaFree(d_histogram);
	cudaFree(d_offset);
	cudaFree(d_offsetAfter);

	// find offset after values
	unsigned int *indexArray = (unsigned int*)malloc(sizeof(unsigned int)*totalNumbers);
	unsigned int *d_indexArray;
	for (int i = minIndex; i < minIndex + totalNums; i++) {
		// find the digit to sort by
		int num = valuesList[i];
		int tempDigit = digit;
		while (tempDigit != dig) {
			num = valuesList[i] / tempDigit;
			num *= tempDigit;

			tempDigit /= 10;
			num = valuesList[i] - num;
		}

		indexArray[i] = (offsetAfter[num/dig] - 1);
		offsetAfter[num/dig]--;
	}

	// copy main array and index array to device to rearrange values
	cudaMalloc((void **) &d_valuesList, sizeof(unsigned int)*totalNumbers);
	cudaMalloc((void **) &d_indexArray, sizeof(unsigned int)*totalNumbers);

	cudaMemcpy(d_valuesList, valuesList, sizeof(unsigned int)*totalNumbers, cudaMemcpyHostToDevice);
	cudaMemcpy(d_indexArray, indexArray, sizeof(unsigned int)*totalNumbers, cudaMemcpyHostToDevice);

	// printf("MIN INDEX: %d\n", minIndex);
	// printf("SIZE: %d\n", totalNums);
	// printf("DIGIT: %d\n", dig);
	// printArrayU(indexArray, totalNumbers);
	// kernel call to rearrange the numbers in valuesList
	moveElements<<<(totalNums+255)/256,256>>>(d_valuesList, d_indexArray, minIndex, totalNums);

	// copy data back to host from the device
	cudaMemcpy(valuesList, d_valuesList, sizeof(unsigned int)*totalNumbers, cudaMemcpyDeviceToHost);
	cudaMemcpy(indexArray, d_indexArray, sizeof(unsigned int)*totalNumbers, cudaMemcpyDeviceToHost);
	// free memory
	cudaFree(d_valuesList);
	cudaFree(d_indexArray);

	// printf("HISTOGRAM:\n");
	// printArray(histogram, histogramSize);

	// printf("OFFSET BEFORE:\n");
	// printArray(offset, histogramSize);

	// printf("OFFSET AFTER:\n");
	// printArray(offsetAfter, histogramSize);

	// printf("VALUES AFTER:\n");
	// printArrayU(valuesList, totalNumbers);

	// call sortArray on each index of the histogram if that index value is greater than 1
	for (int i = 0; i < 10; i++) {
		if (histogram[i] > 1 && dig != 1) {
			int minInd;
			if (i == 0) {
				minInd = 0;
			}
			else{
				minInd = offset[i-1];
			} 

			// recursion
			sortArray(dig/10, offset[i]-minInd, minInd+prevMin, minInd+prevMin);
		}
	}

	return;
}

int main(int argc, char **argv) {

	totalNumbers = atoi(argv[1]);
	histogramSize = 10;

	valuesList = (unsigned int *)malloc(sizeof(unsigned int)*totalNumbers);

	srand(1);	
	// generate totalNumbers random numbers for valuesList
	for (int i = 0; i < totalNumbers; i++) {
		valuesList[i] = (int) rand()%MAX;
	}

	printf("VALUES BEFORE:\n");
	printArrayU(valuesList, totalNumbers);

	sortArray(digit, totalNumbers, 0, 0);

	printf("VALUES AFTER:\n");
	printArrayU(valuesList, totalNumbers);

	return 0;
}
