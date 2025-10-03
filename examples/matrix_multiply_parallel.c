#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

#define MATRIX_SIZE 3000
#define BLOCK_SIZE 500

// 矩阵乘法函数
void matrix_multiply(double *A, double *B, double *C, int n) {
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            C[i * n + j] = 0.0;
            for (int k = 0; k < n; k++) {
                C[i * n + j] += A[i * n + k] * B[k * n + j];
            }
        }
    }
}

// 初始化矩阵
void init_matrix(double *matrix, int n, int seed) {
    srand(seed);
    for (int i = 0; i < n * n; i++) {
        matrix[i] = (double)rand() / RAND_MAX * 10.0;
    }
}

// 打印矩阵（仅用于小矩阵）
void print_matrix(double *matrix, int n, const char *name) {
    if (n <= 10) {
        printf("%s:\n", name);
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                printf("%.2f ", matrix[i * n + j]);
            }
            printf("\n");
        }
        printf("\n");
    }
}

int main(int argc, char *argv[]) {
    int rank, size;
    int matrix_size = MATRIX_SIZE;
    double start_time, end_time;
    
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    if (rank == 0) {
        printf("==========================================\n");
        printf("并行矩阵乘法计算开始\n");
        printf("==========================================\n");
        printf("矩阵大小: %d x %d\n", matrix_size, matrix_size);
        printf("进程数: %d\n", size);
        printf("开始时间: %s", ctime(&(time_t){time(NULL)}));
        printf("==========================================\n");
    }
    
    // 计算每个进程负责的行数
    int rows_per_process = matrix_size / size;
    int remainder = matrix_size % size;
    
    // 分配额外的行给前几个进程
    int start_row = rank * rows_per_process + (rank < remainder ? rank : remainder);
    int end_row = start_row + rows_per_process + (rank < remainder ? 1 : 0);
    int local_rows = end_row - start_row;
    
    if (rank == 0) {
        printf("进程 %d: 负责行 %d 到 %d (共 %d 行)\n", rank, start_row, end_row-1, local_rows);
    }
    
    // 分配内存
    double *A = NULL;
    double *B = (double*)malloc(matrix_size * matrix_size * sizeof(double));
    double *C = (double*)malloc(local_rows * matrix_size * sizeof(double));
    double *local_A = (double*)malloc(local_rows * matrix_size * sizeof(double));
    
    if (rank == 0) {
        A = (double*)malloc(matrix_size * matrix_size * sizeof(double));
        printf("内存分配完成\n");
    }
    
    MPI_Barrier(MPI_COMM_WORLD);
    start_time = MPI_Wtime();
    
    // 初始化矩阵B（所有进程都需要）
    init_matrix(B, matrix_size, 42);
    
    // 进程0初始化矩阵A
    if (rank == 0) {
        init_matrix(A, matrix_size, 123);
        printf("矩阵初始化完成\n");
    }
    
    // 分发矩阵A的行给各个进程
    MPI_Scatterv(A, 
                 (int[]){local_rows * matrix_size}, 
                 (int[]){start_row * matrix_size}, 
                 MPI_DOUBLE,
                 local_A, 
                 local_rows * matrix_size, 
                 MPI_DOUBLE, 
                 0, 
                 MPI_COMM_WORLD);
    
    if (rank == 0) {
        printf("矩阵分发完成，开始计算...\n");
    }
    
    // 执行矩阵乘法
    for (int i = 0; i < local_rows; i++) {
        for (int j = 0; j < matrix_size; j++) {
            C[i * matrix_size + j] = 0.0;
            for (int k = 0; k < matrix_size; k++) {
                C[i * matrix_size + j] += local_A[i * matrix_size + k] * B[k * matrix_size + j];
            }
        }
    }
    
    if (rank == 0) {
        printf("本地计算完成，开始收集结果...\n");
    }
    
    // 收集结果到进程0
    double *result = NULL;
    if (rank == 0) {
        result = (double*)malloc(matrix_size * matrix_size * sizeof(double));
    }
    
    MPI_Gatherv(C, 
                local_rows * matrix_size, 
                MPI_DOUBLE,
                result, 
                (int[]){local_rows * matrix_size}, 
                (int[]){start_row * matrix_size}, 
                MPI_DOUBLE, 
                0, 
                MPI_COMM_WORLD);
    
    end_time = MPI_Wtime();
    
    if (rank == 0) {
        printf("==========================================\n");
        printf("并行计算完成！\n");
        printf("总计算时间: %.2f 秒\n", end_time - start_time);
        printf("结束时间: %s", ctime(&(time_t){time(NULL)}));
        
        // 验证结果（计算几个元素）
        printf("结果验证:\n");
        printf("C[0][0] = %.6f\n", result[0]);
        printf("C[%d][%d] = %.6f\n", matrix_size-1, matrix_size-1, result[matrix_size*matrix_size-1]);
        
        // 计算性能指标
        double flops = 2.0 * matrix_size * matrix_size * matrix_size;
        double gflops = flops / (end_time - start_time) / 1e9;
        printf("性能: %.2f GFLOPS\n", gflops);
        printf("==========================================\n");
    }
    
    // 清理内存
    free(B);
    free(C);
    free(local_A);
    if (rank == 0) {
        free(A);
        free(result);
    }
    
    MPI_Finalize();
    return 0;
}

