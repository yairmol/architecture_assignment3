test: tests.c test.o
	gcc -m32 -g -c -Wall -o tests.o tests.c -lm
	gcc -m32 -g -o test tests.o test.o -lm

test.o: test.s
	nasm -g -f elf test.s -o test.o

.PHONY: clean

clean: 
	rm -f *.o test