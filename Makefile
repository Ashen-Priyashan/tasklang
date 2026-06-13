.PHONY: all run test clean

# Build from canonical src/ directory
all:
	bison -d src/parser.y
	flex src/lexer.l
	gcc lex.yy.c parser.tab.c -o tasklang

run:
	./tasklang < examples/input.txt

test: all
	@echo "Running example tests..."
	@./tasklang < examples/input.txt || { echo "Expected examples/input.txt to succeed"; exit 1; }
	@./tasklang < examples/invalid_input.txt >/dev/null 2>&1 && { echo "Expected examples/invalid_input.txt to fail"; exit 1; } || true
	@./tasklang < examples/invalid_circular.txt >/dev/null 2>&1 && { echo "Expected examples/invalid_circular.txt to fail"; exit 1; } || true
	@echo "Example tests passed"

clean:
	rm -f lex.yy.c parser.tab.c parser.tab.h tasklang