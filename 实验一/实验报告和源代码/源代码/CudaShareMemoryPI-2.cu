#include <stdio.h>
#include <time.h>

#define PerThread 1024*16//每个线程计算多少个i
#define N 64*256*1024*16//积分计算PI总共划分为这么多项相加
#define BlockNum 64 //block的数量
#define ThreadNum 256 //每个block中threads的数量

__global__ void Gpu_calPI(double* Gpu_list)
{
    __shared__ double cache[ThreadNum];//每个block共享一个shared memory.
    int cacheIdx=threadIdx.x;
    int tid=blockIdx.x*blockDim.x*blockDim.y+threadIdx.x;
    int begin=tid*PerThread+1;
    int end=begin+PerThread;
    double temp=0;
    int flag=1;
    for(int i=begin;i<end;i++){
        temp+=flag*(1.0/(2*i-1));
        flag=flag*(-1);
    }
    cache[cacheIdx]=temp;
    __syncthreads();

    int i=blockDim.x/2;
    while(i!=0){
        if(cacheIdx<i) cache[cacheIdx]+=cache[cacheIdx+i];
        __syncthreads();
        i=i/2;
    }

    if(cacheIdx==0){
        Gpu_list[blockIdx.x]=cache[0];
    }
}

int main(void)
{
    double * cpu_list;
    double * Gpu_list;
    double outcome=0;
    cpu_list=(double*)malloc(sizeof(double)*BlockNum);
    cudaMalloc((void**)&Gpu_list,sizeof(double)*BlockNum);
    // dim3 blocksize=dim3(1,ThreadNum);
    // dim3 gridsize=dim3(1,BlockNum);
    // printf("go to GPU\n");
    double begin=clock();
    Gpu_calPI<<<BlockNum,ThreadNum>>>(Gpu_list);

    cudaMemcpy(cpu_list,Gpu_list,sizeof(double)*BlockNum,cudaMemcpyDeviceToHost);
    for(int i=0;i<BlockNum;i++){
        outcome+=cpu_list[i];
    }
    outcome=4*outcome;
    double end=clock();
    printf("CudaShareMemoryPI-2: N=%d, PI value=%.10f, Using time =%.10f\n",N,outcome,(end-begin)/(CLOCKS_PER_SEC));

    
}