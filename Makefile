.PHONY: all run test clean

all:
	bison -d parser.y
	flex lexer.l
	gcc lex.yy.c parser.tab.c -o tasklang

run:
	./tasklang < input.txt

test: all
	@sh -c './tasklang < input.txt >/dev/null && ! ./tasklang < invalid_input.txt >/dev/null 2>&1 && ! ./tasklang < invalid_circular.txt >/dev/null 2>&1'

clean:
	rm -f lex.yy.c parser.tab.c parser.tab.h tasklang