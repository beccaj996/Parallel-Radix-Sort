#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

unsigned int * valuesList;
unsigned int totalNumbers;

__global__ unsigned int radixSort(unsigned int* values, int digit) {

	// not sure about the implenetation of the histogram part
	__shared__ histogram;
	temp_list;
	int tid = thisInstanceThread;

	// histogram contains buckets 0-9
	// use each thread to place its corresponding element of the array into 
	// the right bucket based on the current digit.
	// each recursion has its own instanced histogram.

	// iterate over each list in the histogram. Each list corresponds to a different bucket.
	// if each list has more than 1 value in it, call radixSort on that specific list(aka bucket) but
	// increment the digit.
	// if there is only 1 value then that list (bucket) is sorted. radiSort will return a sorted list as well.
	// append the list (bucket) at each index of the histogram to temp_list.
	for (int i = 0; i < histogramSize; i++) {
		if (histogram[i] size > 1) {
			temp_list += radixSort<<<numBlocks, numThreads>>>(histogram[i], digit++);
		}
		
		temp_list += histogram[i]; // append each bucket to the end of temp_list
		
	}

	return temp_list;

}

unsigned int padNumbers(unsigned int* values) {
	// pad each element with 0's to match the number with the most digits
	return paddedNumbers;
}

int main(int argc, char **argv) {

	totalNumbers = atoi(argv[1]);

	// generate totalNumbers random numbers for valuesList

	// pad the numbers with 0's
	unsigned int paddedNumbers[totalNumbers] = paddedNumbers(valuesList);

	cudaMalloc((void **) device_list, size);
	cudaMemscpy(device_list, host_list, size, cudaMemcpyHostToDevice);

	// start with 10th digit. unsigned int limits the digit size to 10 so there can
	// only be a max of 10 digits.
	radixSort<<<numBlocks, numThreads>>>(paddedNumbers, 10);

	cudaMemcpy(host_list, device_list,j size, cudaMemcpyDeviceToHost);
	cudaFree(device_list);

	// print ordered list

	return 0;
}