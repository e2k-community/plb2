#include <iostream>
#include <cstdlib>

// Объявляем функции для работы с матрицами
double **mat_alloc(int n_row, int n_col)
{
    double **mat, *a;
    int i;
    a = (double*)calloc(n_row * n_col, sizeof(double));
    mat = (double**)malloc(n_row * sizeof(void*));
    for (i = 0; i < n_row; ++i)
        mat[i] = &a[i * n_col];
    return mat;
}

void mat_free(double **mat)
{
    free(mat[0]); 
    free(mat);
}

double **mat_gen(int n)
{
    double **a, tmp = 1.0 / n / n;
    int i, j;
    a = mat_alloc(n, n);
    for (i = 0; i < n; ++i)
        for (j = 0; j < n; ++j)
            a[i][j] = tmp * (i - j) * (i + j);
    return a;
}

double **mat_mul(int n, int p, double **a, int m, double **b)
{
    double **c;
    int i, j, k;
    c = mat_alloc(n, m);
    for (i = 0; i < n; ++i)
        for (k = 0; k < p; ++k)
            for (j = 0; j < m; ++j)
                c[i][j] += a[i][k] * b[k][j];
    return c;
}

// Функция для запуска умножения матриц с указанным размером
void run_matmul(int n) { 
   double **a, **b, **c;

    a = mat_gen(n);  // Генерация матриц
    b = mat_gen(n);
    c = mat_mul(n, n, a, n, b);  // Умножение матриц

    // Выводим элемент в центре
    std::cout << "Element at the center: " << c[n >> 1][n >> 1] << std::endl;

    mat_free(c);  // Освобождение памяти
    mat_free(b);
    mat_free(a);
}

// Функция для вызова из ROOT
void matmul() {
    run_matmul(1500);  // Запуск с размером 1500 по умолчанию
}

int main(int argc, char *argv[])
{
    matmul();  // Запускаем функции ROOT для умножения матриц
    return 0;
}
