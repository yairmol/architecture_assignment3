ass3: ass3.s drone.o printer.o scheduler.o target.o
	nasm -g -f elf ass3.s -o ass3.o
	gcc -m32 -Wall -g ass3.o drone.o printer.o scheduler.o target.o -o ass3

drone.o: drone.s
	nasm -g -f elf drone.s -o drone.o

printer.o: printer.s
	nasm -g -f elf printer.s -o printer.o

scheduler.o: scheduler.s
	nasm -g -f elf scheduler.s -o scheduler.o

target.o: target.s
	nasm -g -f elf target.s -o target.o

clean:
	rm ass3 *.o