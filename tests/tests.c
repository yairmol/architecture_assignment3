#include <stdint.h>
#include <stdio.h>

extern uint16_t random_generator_1();

unsigned lfsr1(void)
{
    uint16_t start_state = 0xACE1u;  /* Any nonzero start state will work. */
    uint16_t lfsr = start_state, my_lfsr;
    uint16_t bit;                    /* Must be 16-bit to allow bit<<15 later in the code */
    unsigned period = 0;

    do
    {   /* taps: 16 14 13 11; feedback polynomial: x^16 + x^14 + x^13 + x^11 + 1 */
        my_lfsr = random_generator_1();
        bit = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5)) /* & 1u */;
        lfsr = (lfsr >> 1) | (bit << 15);
        printf("true lfsr: %X, my lfsr: %X\n", lfsr, my_lfsr);
        if (my_lfsr != lfsr){
            printf("test failed\n");
            return lfsr;
        }
        ++period;
    }
    while (period != 10);

    return period;
}

int main(int argc, char* argv[]) {
    lfsr1();
}