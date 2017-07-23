#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

#define MAX 99;

int blockSize = 256;
int numBlocks;
int* valueArray;
int * dArray;

//Declaration for partition sort
__device__ void partition_by_bit(int *values, int bit);

__global__ void radix_sort(int *values)
{

    int  bit;
    for( bit = 0; bit < 32; ++bit )
    {
        partition_by_bit(values, bit);
        __syncthreads();
    }
    
}

template<class T>
__device__ T plus_scan(T *x)
{
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    // int i = threadIdx.x; // id of thread executing this instance
    int n = blockDim.x;  // total number of threads in this block
    // int n = 10;
    int offset;          // distance between elements to be added

    if (i < n) {
        for( offset = 1; offset < n; offset *= 2) {
            T t;

            if ( i >= offset ) 
                t = x[i-offset];
            
            __syncthreads();

            if ( i >= offset ) 
                x[i] = t + x[i];      // i.e., x[i] = x[i] + x[i-1]

            __syncthreads();
        }

    }
    return x[i];
}

__device__ void partition_by_bit(int *values, int bit)
{
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    // int i = threadIdx.x;
    int size = blockDim.x;
    // int size = 10;
    if (i < size) {

        int x_i = values[i];          // value of integer at position i
        int p_i = (x_i >> bit) & 1;   // value of bit at position bit

        // Replace values array so that values[i] is the value of bit bit in
        // element i.
        values[i] = p_i;  

        // Wait for all threads to finish this.
        __syncthreads();

        // Now the values array consists of 0's and 1's, such that values[i] = 0
        // if the bit at position bit in element i was 0 and 1 otherwise.

        // Compute number of True bits (1-bits) up to and including values[i], 
        // transforming values[] so that values[i] contains the sum of the 1-bits
        // from values[0] .. values[i]
        int T_before = plus_scan(values);
    /*
        plus_scan(values) returns the total number of 1-bits for all j such that
        j <= i. This is assigned to T_before, the number of 1-bits before i 
        (includes i itself)
    */

        // The plus_scan() function does not return here until all threads have
        // reached the __syncthreads() call in the last iteration of its loop
        // Therefore, when it does return, we know that the entire array has had
        // the prefix sums computed, and that values[size-1] is the sum of all
        // elements in the array, which happens to be the number of 1-bits in 
        // the current bit position.
        int T_total  = values[size-1];
        // T_total, after the scan, is the total number of 1-bits in the entire array.

        int F_total  = size - T_total;
    /*    
        F_total is the total size of the array less the number of 1-bits and hence
        is the number of 0-bits.
    */
        __syncthreads();

        if ( p_i )
            values[T_before-1 + F_total] = x_i;
        else
            values[i - T_before] = x_i;


    }

}

int main(int argc, char **argv){
	//FIXME: add arugment handler
	int numElements = atoi(argv[1]);
    numBlocks = numElements;
	// valueArray[numElements];

	valueArray = (int *)malloc(sizeof(int)*numElements);

    for (int i = 0; i < numElements; i++) {
        valueArray[i] = (int) rand()%MAX;
    }

    printf("PRINTING BEFORE:\n");
    for(int i = 0; i < numElements;i++){
        printf("%d, ",valueArray[i]);
    }

	cudaMalloc((void **) &dArray, sizeof(int) * numElements);

	cudaMemcpy(dArray,valueArray, sizeof(int) * numElements, cudaMemcpyHostToDevice);

    // radix_sort<<<ceil(numElements/256), 256>>>(dArray);
	radix_sort<<<1, numElements>>>(dArray);

	cudaMemcpy(valueArray, dArray, sizeof(int) * numElements, cudaMemcpyDeviceToHost);

	cudaFree(dArray);

    printf("\n\nPRINTING AFTER:\n");
	for(int i = 0; i < numElements;i++){
		printf("%d, ",valueArray[i]);
	}

    printf("DONE!\n");

	return 0;
}