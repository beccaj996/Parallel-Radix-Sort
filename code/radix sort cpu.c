/*
*********************************************************************************************************
 Project 3
 Rebecca Johnson, James Albu, Jacob Manfre

 GPU Radix Sort algortihm

*********************************************************************************************************
*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

long long num_dataPts;
int MAX_VALUE = 2147483647;
int num_buckets;

typedef struct hist_entry{
long long digit_count;
} bucket;

bucket *histogram;

void printArray(int * array, int size){

	int i;
	printf("[ ");
	for (i = 0; i < size; i++)
		printf("%d ", array[i]);
	printf("]\n");
}

// Radix Sort
void radixSort(int * array, int size){
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

		/**
		 * Add the count of the previous buckets,
		 * Acquires the indexes after the end of each bucket location in the array
		 * Works similar to the count sort algorithm
		 **/
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
//output the histogram
void outputHistogram()
{ int i;
long long total_cnt = 0;
for (i = 0; i < num_buckets; i++)
	{ 
	if (i%10 == 0)
		printf("\n%02d: ",i);
	printf("%15lld ", histogram[i].digit_count);
	total_cnt += histogram[i].digit_count;
	if (i == num_buckets-1)
		printf("\n Total: %lld \n", total_cnt);
	else printf("| ");
	}
}

int main(int argc, char **argv){

	num_dataPts = atoi(argv[1]);	//amount of data to sort
	num_buckets = 100;
	int data[num_dataPts];
	histogram = (bucket *)malloc(sizeof(bucket)*num_buckets);

	//generate random 32 bit signed integers until we have data[num_dataPts] filled
	srand(1);
	for (int i = 0; i < num_dataPts; i++)
		{ 
		if ((int)rand() < MAX_VALUE)
			data[i] = (int)rand();
		}

	radixSort(&data[0], num_dataPts);	//sort data using radix sort algorithm MSD

	printf("\nSorted List:");
	printArray(&data[0], num_dataPts);
	outputHistogram();
	printf("\n");

	return 0;
}