//**********************************************************************************************************
//  Project 3
// Rebecca Johnson, James Albu, Jacob Manfre
//
// GPU Radix Sort algortihm
//
//*********************************************************************************************************

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

long long  num_dataPts;
int MAX_VALUE = 2147483647;
int num_buckets;
int blockSize = 32;
int numBlocks = 512;
struct timezone Idunno;	
struct timeval startTime, endTime;


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

__global__
void Kernel(long long *bucket, int *array, int sigDig);

void sort(int *semiSorted, int *array, bucket *histo, int size)
{  int significantDigit = 1;
   int largestNum = 1000000000;
  while (largestNum/significantDigit > 0)
  {   long long  bucket[10] = {0};
    //  long long bin[10] = {0};
      Kernel<<<numBlocks, blockSize>>>(bucket, array, significantDigit); 
      cudaMemcpy(bucket, bucket, 10*sizeof(long long), cudaMemcpyDeviceToHost);
    //  cudaMemcpy(array, array, size*sizeof(int), cudaMemcpyDeviceToHost);      
 //     printArray(&array[0], size); 
  //  for (int k = 1; k < 10; k++)
    //     bucket[k] += bucket[k-1];
    // for (int k = size - 1; k >= 0; k--)
     //  semiSorted[--bucket[(array[k] / significantDigit) % 10]] = array[k];
     //for (int k = 0; k < size; k++)
     //  array[k] = semiSorted[k];
     significantDigit *= 10;
}
}
__global__
 void Kernel(long long *bucket, int *array, int sigDig)
{   int k = threadIdx.x + blockDim.x;
 //   int n = blockDim.x;
//    int  semiSorted[size] = {0};
    //int significantDigit = 1;
    //int largestNum = 1000000000;

 //   while(largestNum/significantDigit > 0)
//    {
//	long long bucket[10] = {0};
//	for (int k = 0; k < size; k++)
         bucket[(array[k] /sigDig)%10] ++;
	__syncthreads();
//	for (int k = 1; k < 10; k++)
//           bucket[k] += bucket[k-1];
//	for (int k = size - 1; k >= 0; k--)
//	   semiSorted[--bucket[(array[k] / significantDigit) % 10]] = array[k];
//	for (int k = 0; k < size; k++)
//	   array[k] = semiSorted[k];
//	significantDigit *= 10;
//	__syncthreads();
  //  }
}//end of kernel

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
{  int i;
   long long total_cnt = 0;
   for (i = 0; i < num_buckets; i++)
   {  if (i%10 == 0)
        printf("\n%02d: ",i);
      printf("%15lld ", histogram[i].digit_count);
      total_cnt += histogram[i].digit_count;
      if (i == num_buckets-1)
	printf("\n Total: %lld \n", total_cnt);
      else printf("| ");
   }
}

double report_running_time() {
	long sec_diff, usec_diff;
	gettimeofday(&endTime, &Idunno);
	sec_diff = endTime.tv_sec - startTime.tv_sec;
	usec_diff= endTime.tv_usec-startTime.tv_usec;
	if(usec_diff < 0) {
		sec_diff --;
		usec_diff += 1000000;
	}
	printf("Running time: %ld.%06ld\n", sec_diff, usec_diff);
	return (double)(sec_diff*1.0 + usec_diff/1000000.0);
}

int main(int argc, char **argv){
 
  bucket *dhistogram;
  num_dataPts = atoi(argv[1]);		//amount of data to sort
  num_buckets = 100;
  int data[num_dataPts]; 
  int *device_data, sortedData[num_dataPts], semiSorted[num_dataPts];
  
  cudaMemset(dhistogram, 0, sizeof(bucket)*num_buckets);
  histogram = (bucket *)malloc(sizeof(bucket)*num_buckets);
  cudaMalloc(&dhistogram, sizeof(bucket)*num_buckets);
  cudaMalloc(&device_data, sizeof(int)*num_dataPts);

  //generate random 32 bit signed integers until we have data[num_dataPts] filled
  srand(1);
  for (int i = 0; i < num_dataPts; i++)
  { if ((int)rand() < MAX_VALUE)
      data[i] = (int)rand();
  }

  printf("Unsorted data: ");
  printArray(&data[0], num_dataPts);  
  cudaMemcpy(device_data, data, num_dataPts*sizeof(int), cudaMemcpyHostToDevice);

  gettimeofday(&startTime, &Idunno);
   sort(semiSorted, device_data, dhistogram, num_dataPts);
  // Kernel<<<numBlocks, blockSize>>>(semiSorted, device_data, dhistogram, num_dataPts); 
// radixSort(&data[0], num_dataPts);		//sort data using radix sort algorithm MSD
  report_running_time();
  
  cudaMemcpy(histogram, dhistogram, num_buckets*sizeof(bucket), cudaMemcpyDeviceToHost);
  cudaMemcpy(sortedData, device_data, num_dataPts*sizeof(int), cudaMemcpyDeviceToHost); 
//  printf("\nSorted List:");
//  printArray(&data[0], num_dataPts);
    printf("\nSorted data: ");
    printArray(&sortedData[0], num_dataPts);
 //   printArray(&device_data[0], num_dataPts); 
// outputHistogram();
  printf("\n");
  
  return 0;
}

