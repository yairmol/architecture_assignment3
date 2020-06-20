ass3: ass3.s drone.o printer.o scheduler.o target.o
	nasm -g -f elf32 ass3.s -o ass3.o
	gcc -m32 -Wall -g ass3.o drone.o printer.o scheduler.o target.o -o ass3

drone.o: drone.s
	nasm -g -f elf32 drone.s -o drone.o

printer.o: printer.s
	nasm -g -f elf32 printer.s -o printer.o

scheduler.o: scheduler.s
	nasm -g -f elf32 scheduler.s -o scheduler.o

target.o: target.s
	nasm -g -f elf32 target.s -o target.o

clean:
	rm ass3 *.o