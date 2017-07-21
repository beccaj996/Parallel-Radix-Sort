/*****************************************
Project 3
James Albu, Rebecca Johnson, Jacob Manfre
GPU Radix Sort Algorithm
*******************************************/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

//#define MAX 2147483647;								//largest 32bit signed integer
 #define MAX 99;

unsigned int * valuesList;							//holds values for parallel radix sort
unsigned int * valuesList2;							//array holds values for sequential radix sort
unsigned int* d_valuesList;							//holds values for device

struct timezone Idunno;
struct timeval startTime, endTime;

float totalRunningTime = 0.00000;
unsigned int totalNumbers;							//number of data values in array
int histogramSize;
int digit = 1000000000;								//largest possible place value for 32bit signed integers

//calculates running time of the radix sort algorithm
float report_running_time() {
	long sec_diff, usec_diff;
	gettimeofday(&endTime, &Idunno);
	sec_diff = endTime.tv_sec - startTime.tv_sec;
	usec_diff= endTime.tv_usec-startTime.tv_usec;
	if(usec_diff < 0) {
		sec_diff --;
		usec_diff += 1000000;
	}

	return (float)(sec_diff*1.0 + usec_diff/1000000.0);
}

//sequentially sorts the radix sort algorithm on the CPU in order to compare its running time to GPU
void seqSort(unsigned int * array, int size){
  int i;
  long long semiSorted[size];
  int significantDigit = 1;
  int largestNum = 1000000000;
  // Loop until we reach the largest significant digit
  while (largestNum / significantDigit > 0)
  {  
    long long bucket[10] = { 0 };
    // Counts the number of "keys" or digits that will go into each bucket
    for (i = 0; i < size; i++)
      bucket[(array[i] / significantDigit) % 10]++;
    for (i = 1; i < 10; i++)
      bucket[i] += bucket[i - 1];   
    // Use the bucket to fill a "semiSorted" array
    for (i = size - 1; i >= 0; i--)
      semiSorted[--bucket[(array[i] / significantDigit) % 10]] = array[i];
    for (i = 0; i < size; i++)
      array[i] = semiSorted[i];
    // Move to next significant digit
    significantDigit *= 10;
    
  }
}

//function to print out arrays
void printArray(int * array, int size) {	
	printf("[ ");
  	for (int i = 0; i < size; i++) {
    	printf("%d ", array[i]);}
  	printf("]\n");
}

void printArrayU(unsigned int * array, int size) {	
	printf("[ ");
  	for (int i = 0; i < size; i++) {
    	printf("%d ", array[i]);
	}
  	printf("]\n");
}

//main GPU kernel
//counts the number of instances for a place value and stores in a histogram
__global__ void radix_Sort(unsigned int* valuesList, int digitMax, int digitCurrent, int startPos, int arraySize, int* histogram) {

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

//rearragnes the array elements to correspond to the bucket they are placed in
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

//initializing the radix sort values and memory allocation functions
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

	cudaMalloc((void **) &d_valuesList, sizeof(unsigned int)*totalNumbers);
	cudaMalloc((void**) &d_histogram, sizeof(int)*histogramSize);

	cudaMemcpy(d_valuesList, valuesList, sizeof(unsigned int)*totalNumbers, cudaMemcpyHostToDevice);
	cudaMemcpy(d_histogram, histogram, sizeof(int)*histogramSize, cudaMemcpyHostToDevice);
        
        gettimeofday(&startTime, &Idunno);
	radix_Sort<<<(totalNums+255)/256, 256>>>(d_valuesList, digit, dig, minIndex, totalNums, d_histogram);
	totalRunningTime = totalRunningTime + report_running_time();
	
	// copy data back to host from the device
	cudaMemcpy(valuesList, d_valuesList, sizeof(unsigned int)*totalNumbers, cudaMemcpyDeviceToHost);
	cudaMemcpy(histogram, d_histogram, sizeof(int)*histogramSize, cudaMemcpyDeviceToHost);

	// free memory on device
	cudaFree(d_valuesList);
	cudaFree(d_histogram);

	//find offset before values
	offset[0] = histogram[0];
	offsetAfter[0] = histogram[0];
	for (int i = 1; i < 10; i++) {
	   offsetAfter[i] = offsetAfter[i-1] + histogram[i];
           offset[i] = offset[i-1] + histogram[i]; 
	}

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
 	
	gettimeofday(&startTime, &Idunno);
	// kernel call to rearrange the numbers in valuesList
	moveElements<<<(totalNums+255)/256,256>>>(d_valuesList, d_indexArray, minIndex, totalNums);
	totalRunningTime = totalRunningTime + report_running_time();

	// copy data back to host from the device
	cudaMemcpy(valuesList, d_valuesList, sizeof(unsigned int)*totalNumbers, cudaMemcpyDeviceToHost);
	cudaMemcpy(indexArray, d_indexArray, sizeof(unsigned int)*totalNumbers, cudaMemcpyDeviceToHost);
	// free memory
	cudaFree(d_valuesList);
	cudaFree(d_indexArray);

	 printf("HISTOGRAM:\n");
	 printArray(histogram, histogramSize);

	 printf("OFFSET BEFORE:\n");
	 printArray(offset, histogramSize);

	 printf("OFFSET AFTER:\n");
	 printArray(offsetAfter, histogramSize);

	 printf("VALUES AFTER:\n");
	 printArrayU(valuesList, totalNumbers);
printf("----------Place value-----------: %i\n", placeValue);
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
			sortArray(dig/10, offset[i]-minInd, minInd+prevMin, minInd+prevMin, placeValue+1);
		}
	}
	
	return;
}

int main(int argc, char **argv) {

	totalNumbers = atoi(argv[1]);
	histogramSize = 10;

	valuesList = (unsigned int *)malloc(sizeof(unsigned int)*totalNumbers);
	valuesList2 = (unsigned int *)malloc(sizeof(unsigned int)*totalNumbers);

	srand(1);	
	// generate totalNumbers random numbers for valuesList
	for (int i = 0; i < totalNumbers; i++) {
		valuesList[i] = (int) rand()%MAX;
	}
	for (int i = 0; i < totalNumbers; i++)
		valuesList2[i] = valuesList[i];

//	printf("VALUES BEFORE:\n");
//	printArrayU(valuesList, totalNumbers);
	printf("\nGPU running time: \n");
	sortArray(digit, totalNumbers, 0, 0, 0);
        printf("%f \n", totalRunningTime);
  
        printf("CPU running time:\n");
  	gettimeofday(&startTime, &Idunno);
  	seqSort(valuesList2, totalNumbers);
  	printf("%f \n", report_running_time());

//        printf("SeqSort: \n");
//  	printArrayU(&valuesList2[0], totalNumbers);
  
//	printf("GPU sort values:\n");
//	printArrayU(valuesList, totalNumbers);

	return 0;
}
