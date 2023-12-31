#include <stdio.h>
#include<time.h>

#define PerThread 1024*4*8//每个线程计算多少个i
#define N 64*256*1024*4//积分计算PI总共划分为这么多项相加
#define BlockNum 32 //block的数量
#define ThreadNum 64 //每个block中threads的数量

__global__ void Gpu_calPI(double* Gpu_list)
{   //核函数
    int tid=blockIdx.x*blockDim.x*blockDim.y+threadIdx.x;//计算线程号
    int begin=tid*PerThread;
    int end=begin+PerThread-1;//计算每个线程的工作范围
    double temp=0;
    for(int i=begin;i<end;i++){
        temp+=4.0/(1+((i+0.5)/(N))*((i+0.5)/(N)));
    }
    Gpu_list[tid]=temp;//存入计算结果
}

int main(void)
{
    double * cpu_list;
    double * Gpu_list;
    double outcome=0;
    cpu_list=(double*)malloc(sizeof(double)*BlockNum*ThreadNum);
    cudaMalloc((void**)&Gpu_list,sizeof(double)*BlockNum*ThreadNum);
    // dim3 blocksize=dim3(1,ThreadNum);
    // dim3 gridsize=dim3(1,BlockNum);
    double begin=clock();
    Gpu_calPI<<<BlockNum,ThreadNum>>>(Gpu_list);

    cudaMemcpy(cpu_list,Gpu_list,sizeof(double)*BlockNum*ThreadNum,cudaMemcpyDeviceToHost);
    for(int i=0;i<BlockNum*ThreadNum;i++){
        outcome+=cpu_list[i];
    }
    outcome=outcome/(N);
    double end=clock();
    printf("CudaPI-1: N=%d, PI value=%.10f, Using time =%.10f\n",N,outcome,(end-begin)/(CLOCKS_PER_SEC));

    
}