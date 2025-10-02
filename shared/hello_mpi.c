#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int world_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
    int world_size;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    char hostname[MPI_MAX_PROCESSOR_NAME];
    int name_len;
    MPI_Get_processor_name(hostname, &name_len);

    printf("=== Hello MPI with PMIx ===\n");
    printf("进程 %d/%d 在节点 %s 上运行\n", world_rank, world_size, hostname);
    printf("时间: %s", ctime(&(time_t){time(NULL)}));

    // 简单的并行计算示例
    long long local_sum = 0;
    long long start_val = world_rank * 1000000;
    long long end_val = (world_rank + 1) * 1000000;
    
    printf("进程 %d: 计算范围 %lld 到 %lld\n", world_rank, start_val, end_val - 1);
    
    for (long long i = start_val; i < end_val; ++i) {
        local_sum += i;
    }
    
    printf("进程 %d: 局部和 = %lld\n", world_rank, local_sum);

    // 进程间通信示例
    long long global_sum;
    MPI_Reduce(&local_sum, &global_sum, 1, MPI_LONG_LONG, MPI_SUM, 0, MPI_COMM_WORLD);

    if (world_rank == 0) {
        printf("进程 0: 全局和 = %lld\n", global_sum);
        printf("=== Hello MPI with PMIx 完成 ===\n");
    }

    MPI_Finalize();
    return 0;
}
