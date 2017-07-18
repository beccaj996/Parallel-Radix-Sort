#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

unsigned int * valuesList;
unsigned int totalNumbers;

/***************** EXAMPLE ***********************

ArrayVals: 			9, 31, 4, 18

padded arrayVals:	09, 18, 04, 31

Sort into histogram by leftMost digit (digit 1).
This can be done in parallel. The order in which
they are placed in their corresponding bucket
doesn't matter. So we can use a thread for each
element of the array and fill the buckets
simultaneously.


bucket: 	0  | 1  | 3
		   -------------
values:		09 | 18 | 31		
			04 |	|  

Once all the elements of the array have been placed
in a bucket we must synch the threads before we 
continue.

__syncthreads();

Iterate through each bucket. If a bucket contains
more than 1 value in it then split it into more
buckets based on the next digit to the right.
bucket 0 contains 04 and 09 so sort these by digit 
0 (the right most digit) to get:

bucket: 	4  |  9
		   ---------
values:	   04  |  09

Iterate through each bucket. If a bucket contains
more than 1 value in it then split into more
buckets based on the next digit to the right.
Bucket 4 and 9 each contain only 1 value.

Enter each bucket in the histogram onto a list
starting from the smallest bucket and moving up
to the largest bucket. So in this example add
04 to the list and then 09 to the list and return
this list back to the previous recursion call.
This is line (34) above where it will continue onto
the next iteration of its loop. The list that just
returned to it will be sorted as we just saw.

return list: 04,09

histogram from line 17 should now look like this
after the returned sorted list:

bucket: 	0  | 1  | 3
		   -------------
values:		04 | 18 | 31		
			09 |	| 

Each bucket in the list now contains either a
sorted list or only one element, which is also
a sorted list. Therefore we can put these values
into the original array in the sorted order by
beginning with bucket 0 and moving up to bucket 3.

arrayVals: 04, 09, 18, 31

The array is sorted!

**************************************************/




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
			// sort the values at histogram[i] (bucket[i]) by calling radixSort on that list
			histogram[i] = radixSort<<<numBlocks, numThreads>>>(histogram[i], digit++);
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