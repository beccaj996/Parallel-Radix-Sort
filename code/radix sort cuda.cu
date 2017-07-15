#include <stdio.h>

int blockSize = 32;
int numBlocks = 512;

//Declaration for partition sort
__device__ void partition_by_bit(unsigned int *values, unsigned int bit);

__device__ void radix_sort(unsigned int *values)
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
    unsigned int i = threadIdx.x; // id of thread executing this instance
    unsigned int n = blockDim.x;  // total number of threads in this block
    unsigned int offset;          // distance between elements to be added

    for( offset = 1; offset < n; offset *= 2) {
        T t;

        if ( i >= offset ) 
            t = x[i-offset];
        
        __syncthreads();

        if ( i >= offset ) 
            x[i] = t + x[i];      // i.e., x[i] = x[i] + x[i-1]

        __syncthreads();
    }
    return x[i];
}

__device__ void partition_by_bit(unsigned int *values, unsigned int bit)
{
    unsigned int i = threadIdx.x;
    unsigned int size = blockDim.x;
    unsigned int x_i = values[i];          // value of integer at position i
    unsigned int p_i = (x_i >> bit) & 1;   // value of bit at position bit

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
    unsigned int T_before = plus_scan(values);
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
    unsigned int T_total  = values[size-1];
    // T_total, after the scan, is the total number of 1-bits in the entire array.

    unsigned int F_total  = size - T_total;
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

int main(){
	//FIXME: add arugment handler
	int numElements = 4;
	unsigned int valueArray[numElements];

	//FOR TESTING ----
	valueArray[0] = 15;
	valueArray[1] = 1;
	valueArray[2] = 8;
	valueArray[3] = 4;

	unsigned int dArray = NULL;
	cudaMalloc((unsigned int)%dArray,sizeof(unsigned int) * numElements);

	cudaMemcpy(dArray,valueArray,sizeof(unsigned int) * numElements, CudaMemcpyHostToDevice);

	radix_sort<<<numBlocks, blockSize>>>(dArray);

	cudaMemcpy(valueArray,dArray,sizeof(unsigned int) * numElements, CudaMemcpyDeviceToHost);

	cudaFree(dArray);

	for(int i = 0; i < numElements;i++){
		printf("%d \n");
	}

	return 0;
}