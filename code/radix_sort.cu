// Jake Manfre

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

// #define MAX 2147483647;
#define MAX 99;

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


__global__ void radixSort(unsigned int* valuesList, int digit, int arraySize, int* histogram, int* mainOffset, int* mainOffsetChanged) {

	 int tid = threadIdx.x + blockIdx.x * blockDim.x;

	// take element in values at this instanced thread and find the digit 
	// we're looking for thats passed in and increment the corresponding element 
	// in the histogram
	if (tid < arraySize)
	  atomicAdd(&histogram[valuesList[tid]/digit], 1);
	__syncthreads();

	// find offset values
	mainOffset[0] = histogram[0];
	mainOffsetChanged[0] = histogram[0];
	for (int i = 1; i < 10; i++) {
		mainOffsetChanged[i] = mainOffsetChanged[i-1] + histogram[i];
		mainOffset[i] = mainOffset[i-1] + histogram[i];
	}

	__shared__ int i;

	// group numbers together by bucket
	if (tid < arraySize) {

		int value = valuesList[tid];
		int index;

	
		for (i = 0; i < arraySize; i++) {
			if (tid == i) {
				index = mainOffsetChanged[valuesList[tid]/digit] - 1;
				atomicAdd(&mainOffsetChanged[valuesList[tid]/digit], -1);
			}
		}

		__syncthreads();

		valuesList[index] = value;
		
		/************************************************************
		// get the value at this instanced threads id that corresponds to the value at its index in valuesList
		int value = valuesList[tid];
		int previousValue = value;
		// find the max index this threads value found from valueList by looking in its offsetbucket
		int index = mainOffsetChanged[value/digit] - 1;

		__syncthreads();
		
		valuesList[index] = value;
		atomicAdd(&mainOffsetChanged[previousValue/digit], -1);
		// the list should now be sorted by the 10's digit

		*********************************************************/
	}
	__syncthreads();

	// for (int i = 0; i < 10; i++) {
	// 	int min;
	// 	int max;
	// 	if (histogram[i] > 1) {
	// 		// call bucket sort on that bucket and decrement digit
	// 		if (i == 0) {
	// 			min = 0;
	// 		}
	// 		else {
	// 			min = mainOffset[i-1];
	// 		} 

	// 		max = mainOffset[i] - 1;

	// 		bucketSort<<<((max-min)+255)/256, 256>>>(valuesList, min, max, digit, digit/10);
	// 	}
	// }

	return;

}

//***************************************************************************************************
//***************************************************************************************************
//***************************************************************************************************

__global__ void radix_Sort(unsigned int* valuesList, int digit, int startPos, int arraySize, int* histogram, int* mainOffset, int* mainOffsetChanged) {

	 int tid = threadIdx.x + blockIdx.x * blockDim.x;
	 tid += startPos;
	// take element in values at this instanced thread and find the digit 
	// we're looking for thats passed in and increment the corresponding element 
	// in the histogram
	if (tid < arraySize)
	  atomicAdd(&histogram[valuesList[tid]/digit], 1);
	__syncthreads();

	// find offset values
	// if (tid == 0) {
		mainOffset[0] = histogram[0];
		mainOffsetChanged[0] = histogram[0];
		for (int i = 1; i < 10; i++) {
			mainOffsetChanged[i] = mainOffsetChanged[i-1] + histogram[i];
			mainOffset[i] = mainOffset[i-1] + histogram[i];
		}
	// }
	// __syncthreads();

	// group numbers together by bucket
	if (tid < arraySize) {		
		// get the value at this instanced threads id that corresponds to the value at its index in valuesList
		int value = valuesList[tid];
		__syncthreads();
		atomicAdd(&mainOffsetChanged[value/digit], -1);
	}

	__syncthreads();

	return;

}

//***************************************************************************************************
//***************************************************************************************************
//***************************************************************************************************

__device__ void bucketSort(int* valuesList, int min, int max, int highestDigit, int currentDigit) {

	// int tid = threadIdx.x + blockIdx.x * blockDim.x;

	// // rearange specific range of original list
	// __shared__ int tempHistogram[10];
	// __shared__ int tempOffset[10];
	// __shared__ int tempOffsetChanged[10];
	// __shared__ int range;
	// range = max-min;


	// // create histogram that counts the nubmers for each bucket
	// if (tid < range) {
	// 	int num; // value at the digit we are looking for
	// 	int value = valuesList[tid];
	// 	while (highestDigit != currentDigit) {
	// 		num = value / highestDigit;
	// 		num *= highestDigit;


	// 		highestDigit /= 10;
	// 		num = value - num;
	// 		value = num;
	// 	}

	// 	// highest digit and current digit should be the same
	// 	num /= currentDigit;
	// 	// atomicAdd(tempHistogram[num], 1);
	// 	// or this?
	// 	tempHistogram[num]++;
	// }
	// __syncthreads();

	// if (tid == 0) {
	// 	tempOffset[0] = tempHistogram[0];
	// 	for (int i = 1; i < 10; i++) {
	// 		tempOffset[i] = tempOffset[i-1] + tempHistogram[i];
	// 	}
	// }

	// __syncthreads();
}

int * histogram;
int * offset;
int * offsetAfter;
int histogramSize;

unsigned int* d_valuesList;
int* d_histogram;
int* d_offset;
int* d_offsetAfter;


void sortArray() {
	// cudaMalloc((void **) &d_valuesList, sizeof(unsigned int)*totalNumbers);
	// cudaMemcpy(d_valuesList, valuesList, sizeof(unsigned int)*totalNumbers, cudaMemcpyHostToDevice);

	// cudaMalloc((void**) &d_histogram, sizeof(int)*histogramSize);
	// cudaMemcpy(d_histogram, histogram, sizeof(int)*histogramSize, cudaMemcpyHostToDevice);

	// cudaMalloc((void**) &d_offset, sizeof(int)*histogramSize);
	// cudaMemcpy(d_offset, offset, sizeof(int)*histogramSize, cudaMemcpyHostToDevice);

	// cudaMalloc((void**) &d_offsetAfter, sizeof(int)*histogramSize);
	// cudaMemcpy(d_offsetAfter, offsetAfter, sizeof(int)*histogramSize, cudaMemcpyHostToDevice);

	// // digit should be the number we divide valuesList[i] by to find a particular digit.
	// // i.e. if we are looking for the 10's digit we divid by 10. The 100's digit divid
	// // by 100. 326 divide 100 returns 3. This example we limit our number size to only
	// // be 2 digits (max_rand defined at top to be 50) so we pass in 10 as our digit to
	// // find the left most digit, the 10's digit.
	// // dim3 dimBlock(totalNumbers,1);
	// dim3 dimGrid(totalNumbers/256 ,1, 1);
	// if (totalNumbers%256) dimGrid.x++;
	// dim3 dimBlock (256, 1, 1);
	// int digit = 10;
	// // radixSort<<<(totalNumbers+255)/256, 256>>>(d_valuesList, digit, totalNumbers, d_histogram, d_offset, d_offsetAfter);
	// radix_Sort<<<(totalNumbers+255)/256, 256>>>(d_valuesList, digit, 0, totalNumbers, d_histogram, d_offset, d_offsetAfter);

	// cudaMemcpy(valuesList, d_valuesList, sizeof(unsigned int)*totalNumbers, cudaMemcpyDeviceToHost);
	// cudaFree(d_valuesList);

	// cudaMemcpy(histogram, d_histogram, sizeof(int)*histogramSize, cudaMemcpyDeviceToHost);
	// cudaFree(d_histogram);

	// cudaMemcpy(offset, d_offset, sizeof(int)*histogramSize, cudaMemcpyDeviceToHost);
	// cudaFree(d_offset);

	// cudaMemcpy(offsetAfter, d_offsetAfter, sizeof(int)*histogramSize, cudaMemcpyDeviceToHost);
	// cudaFree(d_offsetAfter);
}

int main(int argc, char **argv) {

	totalNumbers = atoi(argv[1]);
	histogramSize = 10;

	valuesList = (unsigned int *)malloc(sizeof(unsigned int)*totalNumbers);
	histogram = (int*)malloc(sizeof(int)*histogramSize);
	offset = (int*)malloc(sizeof(int)*histogramSize);
	offsetAfter = (int*)malloc(sizeof(int)*histogramSize);
	// unsigned int* d_valuesList;
	// int* d_histogram;
	// int* d_offset;
	// int* d_offsetAfter;

	srand(1);	
	// generate totalNumbers random numbers for valuesList
	for (int i = 0; i < totalNumbers; i++) {
		valuesList[i] = (int) rand()%MAX;
	}

	// printf("VALUES BEFORE:\n");
	// printArrayU(valuesList, totalNumbers);

	// fill histogram with 0's
	for (int i = 0; i < histogramSize; i++) {
		histogram[i] = 0;
		offset[i] = 0;
		offsetAfter[i] = 0;
	}

	// sortArray();

	cudaMalloc((void **) &d_valuesList, sizeof(unsigned int)*totalNumbers);
	cudaMemcpy(d_valuesList, valuesList, sizeof(unsigned int)*totalNumbers, cudaMemcpyHostToDevice);

	cudaMalloc((void**) &d_histogram, sizeof(int)*histogramSize);
	cudaMemcpy(d_histogram, histogram, sizeof(int)*histogramSize, cudaMemcpyHostToDevice);

	cudaMalloc((void**) &d_offset, sizeof(int)*histogramSize);
	cudaMemcpy(d_offset, offset, sizeof(int)*histogramSize, cudaMemcpyHostToDevice);

	cudaMalloc((void**) &d_offsetAfter, sizeof(int)*histogramSize);
	cudaMemcpy(d_offsetAfter, offsetAfter, sizeof(int)*histogramSize, cudaMemcpyHostToDevice);

	// digit should be the number we divide valuesList[i] by to find a particular digit.
	// i.e. if we are looking for the 10's digit we divid by 10. The 100's digit divid
	// by 100. 326 divide 100 returns 3. This example we limit our number size to only
	// be 2 digits (max_rand defined at top to be 50) so we pass in 10 as our digit to
	// find the left most digit, the 10's digit.
	// dim3 dimBlock(totalNumbers,1);
	dim3 dimGrid(totalNumbers/256 ,1, 1);
	if (totalNumbers%256) dimGrid.x++;
	dim3 dimBlock (256, 1, 1);
	int digit = 10;
	// radixSort<<<(totalNumbers+255)/256, 256>>>(d_valuesList, digit, totalNumbers, d_histogram, d_offset, d_offsetAfter);
	radix_Sort<<<(totalNumbers+255)/256, 256>>>(d_valuesList, digit, 0, totalNumbers, d_histogram, d_offset, d_offsetAfter);

	cudaMemcpy(valuesList, d_valuesList, sizeof(unsigned int)*totalNumbers, cudaMemcpyDeviceToHost);
	cudaFree(d_valuesList);

	cudaMemcpy(histogram, d_histogram, sizeof(int)*histogramSize, cudaMemcpyDeviceToHost);
	cudaFree(d_histogram);

	cudaMemcpy(offset, d_offset, sizeof(int)*histogramSize, cudaMemcpyDeviceToHost);
	cudaFree(d_offset);

	cudaMemcpy(offsetAfter, d_offsetAfter, sizeof(int)*histogramSize, cudaMemcpyDeviceToHost);
	cudaFree(d_offsetAfter);

	printf("HISTOGRAM:\n");
	printArray(histogram, histogramSize);

	printf("OFFSET BEFORE:\n");
	printArray(offset, histogramSize);

	printf("OFFSET AFTER:\n");
	printArray(offsetAfter, histogramSize);

	// print valuesList
	// printf("VALUES AFTER:\n");
	// printArrayU(valuesList, totalNumbers);

	return 0;
}
