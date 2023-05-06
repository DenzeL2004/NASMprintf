all: mkdirectory

FLAGS = -Wshadow -Winit-self -Wredundant-decls -Wcast-align -Wundef -Wfloat-equal -Winline -Wunreachable-code -Wmissing-declarations 		\
		-Wmissing-include-dirs -Wswitch-enum -Wswitch-default -Weffc++ -Wmain -Wextra -Wall -g -pipe -fexceptions -Wcast-qual -Wconversion	\
		-Wctor-dtor-privacy -Wempty-body -Wformat-security -Wformat=2 -Wignored-qualifiers -Wlogical-op -Wmissing-field-initializers		\
		-Wnon-virtual-dtor -Woverloaded-virtual -Wpointer-arith -Wsign-promo -Wstack-usage=8192 -Wstrict-aliasing -Wstrict-null-sentinel  	\
		-Wtype-limits -Wwrite-strings -D_DEBUG -D_EJUDGE_CLIENT_SIDE


asm_print: 	obj/main.o obj/printf.o 
		gcc -no-pie obj/main.o obj/printf.o -o asm_print

C_print: 	obj/call_Cprint.o
		ld obj/call_Cprint.o -o C_print /lib/x86_64-linux-gnu/libc.so -dynamic-linker /lib64/ld-linux-x86-64.so.2

obj/main.o: main.cpp
		gcc main.cpp -c -o obj/main.o $(FLAGS)

obj/printf.o: printf.s
		nasm -f elf64 -l lst/printf.o printf.s -o obj/printf.o


obj/call_Cprint.o: call_Cprint.s
		nasm -f elf64 -l lst/call_Cprint.lst call_Cprint.s -o obj/call_Cprint.o

mkdirectory:
	mkdir -p obj;
	mkdir -p lst;

cleanup:
	rm obj/*.o