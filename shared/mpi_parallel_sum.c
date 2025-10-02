#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>

#define ARRAY_SIZE 1000000  // 数组大小
#define ITERATIONS 1000     // 迭代次数

// 获取当前时间（秒）
double get_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1000000.0;
}

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int world_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
    int world_size;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    char hostname[MPI_MAX_PROCESSOR_NAME];
    int name_len;
    MPI_Get_processor_name(hostname, &name_len);

    if (world_rank == 0) {
        printf("=== MPI并行求和任务 ===\n");
        printf("进程数量: %d\n", world_size);
        printf("数组大小: %d\n", ARRAY_SIZE);
        printf("迭代次数: %d\n", ITERATIONS);
        printf("开始时间: %s", ctime(&(time_t){time(NULL)}));
    }

    // 每个进程负责的数组部分
    int elements_per_process = ARRAY_SIZE / world_size;
    int remainder = ARRAY_SIZE % world_size;
    
    // 计算每个进程的起始和结束位置
    int start_idx = world_rank * elements_per_process;
    int end_idx = start_idx + elements_per_process;
    if (world_rank == world_size - 1) {
        end_idx += remainder;  // 最后一个进程处理剩余元素
    }
    
    int local_size = end_idx - start_idx;
    
    printf("进程 %d/%d 在节点 %s 上运行\n", world_rank, world_size, hostname);
    printf("进程 %d: 负责元素 %d 到 %d (共%d个元素)\n", world_rank, start_idx, end_idx - 1, local_size);

    // 分配本地数组
    double* local_array = (double*)malloc(local_size * sizeof(double));
    if (!local_array) {
        fprintf(stderr, "进程 %d: 内存分配失败！\n", world_rank);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    // 初始化本地数组
    srand(time(NULL) + world_rank);
    for (int i = 0; i < local_size; i++) {
        local_array[i] = (double)rand() / RAND_MAX * 100.0;
    }
    printf("进程 %d: 本地数组初始化完成\n", world_rank);

    // 同步所有进程
    MPI_Barrier(MPI_COMM_WORLD);
    
    double start_time = get_time();
    
    // 执行多次迭代的并行求和
    double global_sum = 0.0;
    for (int iter = 0; iter < ITERATIONS; iter++) {
        // 计算本地和
        double local_sum = 0.0;
        for (int i = 0; i < local_size; i++) {
            local_sum += local_array[i];
        }
        
        // 使用MPI_Reduce进行全局求和
        double iteration_sum;
        MPI_Reduce(&local_sum, &iteration_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
        
        if (world_rank == 0) {
            global_sum = iteration_sum;
        }
        
        // 广播全局和到所有进程
        MPI_Bcast(&global_sum, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);
        
        // 使用全局和更新本地数组（模拟需要全局信息的计算）
        for (int i = 0; i < local_size; i++) {
            local_array[i] = local_array[i] / (global_sum + 1.0);
        }
        
        if (world_rank == 0 && (iter + 1) % 100 == 0) {
            printf("迭代 %d: 全局和 = %.6f\n", iter + 1, global_sum);
        }
    }
    
    double end_time = get_time();
    double total_time = end_time - start_time;
    
    // 最终结果收集
    double final_local_sum = 0.0;
    for (int i = 0; i < local_size; i++) {
        final_local_sum += local_array[i];
    }
    
    double final_global_sum;
    MPI_Reduce(&final_local_sum, &final_global_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    
    if (world_rank == 0) {
        printf("\n=== 计算完成 ===\n");
        printf("总计算时间: %.3f 秒\n", total_time);
        printf("最终全局和: %.6f\n", final_global_sum);
        printf("平均每次迭代时间: %.6f 秒\n", total_time / ITERATIONS);
        printf("结束时间: %s", ctime(&(time_t){time(NULL)}));
    }
    
    // 清理内存
    free(local_array);
    
    MPI_Finalize();
    return 0;
}
