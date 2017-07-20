//new
/***************** EXAMPLE ***********************
ArrayVals:			9, 31, 4, 18
padded ArrayVals:	09, 31, 04, 18
create histogram of size 10 for buckets 0-9
which each element initialized to 0. Use a thread
on each element of ArrayVals and increment the value
in the bucket it belongs to. This will count how many
values that belong in each bucket. In the above
example the histogram values would look like this:
HISTOGRAM:	
0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 	BUCKET
--------------------------------------
2 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 	VALUES COUNTER
next use an array to count the OFFSET and a copy of  that OFFSET array.
This is done by taking the element value at each index of the
histogram and adding it to the value at the previous index.
OFFSET Original:
0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
--------------------------------------
2 | 3 | 3 | 4 | 4 | 4 | 4 | 4 | 4 | 4
												OFFSET CHANGED IS JUST A 
												COPY OF OFFSET ORIGINAL.
OFFSET Changed:
0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
--------------------------------------
2 | 3 | 3 | 4 | 4 | 4 | 4 | 4 | 4 | 4
^   ^		^
|	|		|
|	|		taken from 4th index in histogram plus previous (1+3)
|	|
|	taken from second index plus the first index (1+2)
|
taken from the first index in histogram (2)
The reason we create a copy is because later, when we
want to determine how to rearange the elements, we have
to decrement the values in OFFSET so they don't overwrite
each other but we must also remember the original OFFSET
values. This will become clearer later.
As you can see the numbers that repeat occur (like index 2
and 4-9) when its corresponding index in the histogram equals 0
so the value doesn't increase.
Now we need to iterate over ArrayVals again and look at
the OFFSET changed array index it corresponds with to determine
where it goes in the list. We'll create a second temporary
list so that we don't ruin the order of the elements in the
original ArrayVals. This can be done in parallel so we can
use a thread to look at each element of ArrayVals at once.
secondList[ArrayValsSize];
we will, for example, look at the first element in ArrayVals.
Its left most digit is 0 so we will look at index 0 in the 
OFFSET changed array. We notice it has a value 2 so we can place this
number at the 2nd index of the secondList array we just created.
This would be index 1 because arrays start at 0. So whatever
number fills the OFFSET changed index we subtract 1 to determine the position
to insert into the secondList. After we input into the secondList 
we want to decrement the value in OFFSET changed so that the next number
that checks can be placed in an empty spot and not overwrite
the numbers in the same bucket. This means index 0 of the OFFSET changed
array goes from 2 to 1. We do the same thing for the other three
elements in ArrayVals. 31's first digit is a 3 so look at index 3 in 
OFFSET changed and we see that it gets placed at 4-1=3 index in the secondList.
Remember to decrement the value at OFFSET changed[3] which = 4 so it becomes 3.
continue this with the next value which is 04 which means we look at 
OFFSET changed[0], because its left most digit is 0, which has a value of 1 
because the value 2 was decremented when 09 was placed in secondList above
in line 75-78. Because the value is now 1 that means we insert 04 into 
index 1-1=0 of secondList. We finish with value 18. OFFSET changed[1] (because its
left most bit is 1) has a value of 3 so we put 18 into secondList[2] 
because 3-1 = 2. After every element has been properly inserted into secondList, 
it should now look like this:
secondList:
04, 09, 18, 31
We can see that its sorted but the computer doensn't know that.
In order to be sure its sorted we iterate through the histogram
and check to see if each value is at most 1. So if any value
in histogram is greater than 1 then we can't be sure its sorted
because we don't know which threads finished first.
So next if we find a value in histogram that is greater than 1 we
look to that index but in the original OFFSET. So histogram[0] has
a value of 2 which means we look in the original OFFSET[0] to get
the value 2. This means we are working from the ranges of
0-2 in the secondList. so we create histogram and OFFSET again.
To do this we just use a recursion and basically repeate the process 
above but now only working with elements 0 and 1 based on the range
provided. We want to do the same process as above but
on the next digit to the right. so we sort 04 and 09
by counting them into the histogram and finding the OFFSET just
like above in lines 15-30.
They will each look like this:
HISTOGRAM:
0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
--------------------------------------
0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 1
OFFSET:
0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
--------------------------------------
0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 2
									  
We iterate over histogram and see if any values are
greater than 1. There are none so they must all be
sorted! so we iterate over histogram and when we
get to a value that is non 0 we can point to
secondList and overwrite those numbers with the
current numbers and they will be in the correct 
order. histogram[4] is the first element with a 
non 0 value. We were given ranges 0-2 from above
(see lines 103-106) so we start at 0 and point
to secondList[0] and insert 4. Then we continue
our iteration over histogram and get to 9 as the
next non 0 element. We can point to secondList[1]
to insert 9. We are done with this part so it will
return to the previous step which is line 102 where
it will continuing iterating over its histogram
looking for values greater than 1. Refer to the
histogram displayed on line 23 as displayed here:
HISTOGRAM:	
0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 	BUCKET
--------------------------------------
2 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 	VALUES COUNTER
We branched off initially from histogram[0] because it 
had a value greater than 1 but now we are back and can 
continue. The rest of the elemnts contain either a 0 or 1 
so don't need to be sorted anymore. This means secondList
contains the sorted array. 
All that is left is to use threads for each element
of secondList and copy their value into the original
array ArrayVals because ArrayVals is the one that
was sent from the CPU that needs to go back to the CPU.
The array is sorted and we are done!
**************************************************/

//new

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


__global__ void radixSort(unsigned int* valuesList, int digit, int arraySize, int* histogram, int* mainOffset, int* mainOffsetAfter) {

	// each element is corresponds to a bucket from 0-9
	// each element initialized to 0.
//	__shared__ int histogram[10];
	// int OFFSETOriginal[10];
	__shared__ int OFFSETChanged[10];

	 int tid = threadIdx.x + blockIdx.x * blockDim.x;

	// take element in values at this instanced thread and find the digit 
	// we're looking for thats passed in and increment the corresponding element 
	// in the histogram
	if (tid < arraySize)
	  atomicAdd(&histogram[valuesList[tid]/digit], 1);
	__syncthreads();

	// find offset values
	// OFFSETOriginal[0] = histogram[0];
	OFFSETChanged[0] = histogram[0];
//	mainHistogram[0] = histogram[0]; // for testing purposes.
	mainOffset[0] = histogram[0];
	for (int i = 1; i < 10; i++) {
//		mainHistogram[i] = histogram[i]; // for testing purposes.
		// OFFSETOriginal[i] = OFFSETOriginal[i-1] + histogram[i];
		OFFSETChanged[i] = OFFSETChanged[i-1] + histogram[i];
		mainOffset[i] = OFFSETChanged[i];
	}

	// group numbers together by bucket
	if (tid < arraySize) {
		// get the value at this instanced threads id that corresponds to the value at its index in valuesList
		int value = valuesList[tid];
		// find the max index this threads value found from valueList by looking in its offsetbucket
		int index = OFFSETChanged[valuesList[tid]/digit] - 1;
		// set every element in valuesList to 0.
		// valuesList[tid] = 0;
		// OFFSETChanged[valuesList[tid]/digit]--;
		__syncthreads();

		// place the values at their index found above as long as its empty (contains a 0)
		// if its filled from another thread already placing a value there,
		// go to the index before it and keep searching down until you find an empty spot
		
		// while (valuesList[index] != 0) {
		// 	atomicAdd(&OFFSETChanged[valuesList[tid]/digit], -1);
		// 	index = OFFSETChanged[valuesList[tid]/digit] - 1;
		// }
		
		int previousValue = value;
		valuesList[index] = value;
		atomicAdd(&OFFSETChanged[previousValue/digit], -1);
		// the list should now be sorted by the 10's digit
	}
	__syncthreads();

	for (int i = 0; i < 10; i++) {
		mainOffsetAfter[i] = OFFSETChanged[i];
	}

	return;

}

__device__ void bucketSort(int* values, int digit) {

}

int * histogram;
int * offset;
int * offsetAfter;

int main(int argc, char **argv) {

	totalNumbers = atoi(argv[1]);
	int histogramSize = 10;

	valuesList = (unsigned int *)malloc(sizeof(unsigned int)*totalNumbers);
	histogram = (int*)malloc(sizeof(int)*histogramSize);
	offset = (int*)malloc(sizeof(int)*histogramSize);
	offsetAfter = (int*)malloc(sizeof(int)*histogramSize);
	unsigned int* d_valuesList;
	int* d_histogram;
	int* d_offset;
	int* d_offsetAfter;

	srand(1);	
	// generate totalNumbers random numbers for valuesList
	for (int i = 0; i < totalNumbers; i++) {
		valuesList[i] = (int) rand()%MAX;
		// valuesList[i] = 26;
	}

	printf("VALUES BEFORE:\n");
	printArrayU(valuesList, totalNumbers);

	// fill histogram with 0's
	for (int i = 0; i < histogramSize; i++) {
		histogram[i] = 0;
		offset[i] = 0;
		offsetAfter[i] = 0;
	}

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
	radixSort<<<(totalNumbers+255)/256, 256>>>(d_valuesList, digit, totalNumbers, d_histogram, d_offset, d_offsetAfter);

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
	printf("VALUES AFTER:\n");
	printArrayU(valuesList, totalNumbers);

	return 0;
}
