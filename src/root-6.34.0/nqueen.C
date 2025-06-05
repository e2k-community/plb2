#include <iostream>
#include <cstdlib>
#include <stdint.h>

#define NQ_MAX 31

static int nq_solve(int n) // Решение задачи N-Queens
{
    int k, a[NQ_MAX], m = 0;
    const uint32_t y0 = (1U<<n) - 1;
    uint32_t l[NQ_MAX], c[NQ_MAX], r[NQ_MAX];

    for (k = 0; k < n; ++k) a[k] = -1, l[k] = c[k] = r[k] = 0;

    for (k = 0; k >= 0;) {
        uint32_t y = (l[k] | c[k] | r[k]) & y0; // битовый массив возможных выборов на строке k
        if ((y ^ y0) >> (a[k] + 1)) { // возможно сделать выбор
            int i = a[k] + 1;
            while (i < n) {
                // ищем первый выбор
                if ((y & (1U << i)) == 0) break;
                i++;
            }
            if (k < n - 1) { // сохраняем выбор
                uint32_t z = 1U<<i;
                a[k++] = i;
                l[k] = (l[k-1] | z) << 1U;
                c[k] = c[k-1] | z;
                r[k] = (r[k-1] | z) >> 1;
            } else {
                ++m; 
                --k; // решение найдено
            }
        } else {
            a[k--] = -1; // нет выбора; откатываемся
        }
    }
    return m;
}

// Функция для вызова из ROOT
void nqueen() {
    int n = 15; // размер по умолчанию
    if (n > NQ_MAX || n <= 0) abort();
    std::cout << "Number of solutions for " << n << " queens: " << nq_solve(n) << std::endl;
}

int main(int argc, char *argv[])
{
    nqueen(); // запускаем функцию для решения задачи
    return 0;
}
