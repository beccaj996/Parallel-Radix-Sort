/*****************************************
Project 3
James Albu, Rebecca Johnson, Jacob Manfre
GPU Radix Sort Algorithm
*******************************************/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

int * valuesList;							//holds values for parallel radix sort
int * valuesList2;							//array holds values for sequential radix sort
int* d_valuesList;							//holds values for device

struct timezone Idunno;
struct timeval startTime, endTime;

float totalRunningTime = 0.00000;
int totalNumbers;							//number of data values in array
int histogramSize;
int digit = 1000000000;						//largest possible place value for 32bit signed integers
int MAX;


// function to print out arrays
void printArray(int * array, int size) {	
	printf("[ ");
  	for (int i = 0; i < size; i++) {
    	printf("%d ", array[i]);}
  	printf("]\n");
}

// main GPU kernel
// counts the number of instances for a place value and stores in a histogram
__global__ void radix_Sort(int* valuesList, int digitMax, int digitCurrent, int startPos, int arraySize, int* histogram) {

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
	return;

}

// rearragnes the array elements to correspond to the bucket they are placed in
__global__ void moveElements(int *valuesList, int *indexList, int startPos, int arraySize) {
	int tid = threadIdx.x + blockIdx.x * blockDim.x;
	tid += startPos;

	if (tid < startPos + arraySize) {
		int val = valuesList[tid];
		int index = indexList[tid] + startPos;

		__syncthreads();
		valuesList[index] = val;
		tid += blockDim.x * blockIdx.x;
	}
	__syncthreads();

	return;

}

// initializing the radix sort values and memory allocation functions
void sortArray(int dig, int totalNums, int minIndex, int prevMin, int placeValue) {
	int * histogram;
	int * offset;
	int * offsetAfter;

	int* d_histogram;

	histogram = (int*)malloc(sizeof(int)*histogramSize);
	offset = (int*)malloc(sizeof(int)*histogramSize);
	offsetAfter = (int*)malloc(sizeof(int)*histogramSize);

	// fill histogram and offset arrays with 0's
	for (int i = 0; i < histogramSize; i++) {
		histogram[i] = 0;
		offset[i] = 0;
		offsetAfter[i] = 0;
	}

	// copy data from host to device
	cudaMalloc((void **) &d_valuesList, sizeof(int)*totalNumbers);
	cudaMalloc((void**) &d_histogram, sizeof(int)*histogramSize);

	cudaMemcpy(d_valuesList, valuesList, sizeof(int)*totalNumbers, cudaMemcpyHostToDevice);
	cudaMemcpy(d_histogram, histogram, sizeof(int)*histogramSize, cudaMemcpyHostToDevice);
    
    // kernel call
	radix_Sort<<<(totalNums+255)/256, 256>>>(d_valuesList, digit, dig, minIndex, totalNums, d_histogram);
	
	// copy data back to host from the device
	cudaMemcpy(valuesList, d_valuesList, sizeof(int)*totalNumbers, cudaMemcpyDeviceToHost);
	cudaMemcpy(histogram, d_histogram, sizeof(int)*histogramSize, cudaMemcpyDeviceToHost);

	// free memory on device
	cudaFree(d_valuesList);
	cudaFree(d_histogram);

	// find offset before and after values
	offset[0] = histogram[0];
	offsetAfter[0] = histogram[0];
	for (int i = 1; i < 10; i++) {
		offsetAfter[i] = offsetAfter[i-1] + histogram[i];
        offset[i] = offset[i-1] + histogram[i]; 
	}

	// find offset after values
	int *indexArray = (int*)malloc(sizeof(int)*totalNumbers);
	int *d_indexArray;
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
	cudaMalloc((void **) &d_valuesList, sizeof(int)*totalNumbers);
	cudaMalloc((void **) &d_indexArray, sizeof(int)*totalNumbers);

	cudaMemcpy(d_valuesList, valuesList, sizeof(int)*totalNumbers, cudaMemcpyHostToDevice);
	cudaMemcpy(d_indexArray, indexArray, sizeof(int)*totalNumbers, cudaMemcpyHostToDevice);
 	
	// kernel call to rearrange the numbers in valuesList
	moveElements<<<(totalNums+1023)/1024,1024>>>(d_valuesList, d_indexArray, minIndex, totalNums);

	// copy data back to host from the device
	cudaMemcpy(valuesList, d_valuesList, sizeof(int)*totalNumbers, cudaMemcpyDeviceToHost);
	cudaMemcpy(indexArray, d_indexArray, sizeof(int)*totalNumbers, cudaMemcpyDeviceToHost);
	// free memory
	cudaFree(d_valuesList);
	cudaFree(d_indexArray);

	// printf("HISTOGRAM:\n");
	// printArray(histogram, histogramSize);

	// printf("OFFSET BEFORE:\n");
	// printArray(offset, histogramSize);

	// printf("OFFSET AFTER:\n");
	// printArray(offsetAfter, histogramSize);

	// if there is more than 1 value in any index of the histogram, then those numbers
	// need to be sorted unless the digit is 1
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
			sortArray(dig/10, offset[i]-minInd, minInd+prevMin, minInd+prevMin, placeValue+1);
		}
	}
	
	return;
}

int main(int argc, char **argv) {

	// array input size
	totalNumbers = atoi(argv[1]);
	// max bit size
	if (atoi(argv[2]) > 31) {
		MAX = (int)(1 << 31);
	} else {
		MAX = (int)(1 << atoi(argv[2]));
	}
	histogramSize = 10;

	valuesList = (int *)malloc(sizeof(int)*totalNumbers);

	srand(1);	
	// generate totalNumbers random numbers for valuesList
	for (int i = 0; i < totalNumbers; i++) {
		valuesList[i] = (int) rand()%MAX;
	}

	printf("VALUES BEFORE:\n");
	printArray(valuesList, totalNumbers);
	printf("---------------------------------------------\n");

	sortArray(digit, totalNumbers, 0, 0, 0);

	printf("VALUES AFTER:\n");
	printArray(valuesList, totalNumbers);

	return 0;
}
