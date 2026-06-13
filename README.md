# TaskLang++

TaskLang++ is a small domain-specific language for defining scheduled tasks with optional dependencies and conditions. It uses a Flex lexer and a Bison parser to validate input, store task definitions, detect semantic issues, and print an execution trace.

## Features

- Task definitions with a name, script, and schedule
- Schedule forms for `AT`, `EVERY DAY AT`, and `EVERY <weekday> AT`
- Task dependencies using `AFTER`, `BEFORE`, and `DEPENDS ON`
- Optional `IF success` condition
- Semantic checks for unknown tasks and circular dependencies
- Dependency-aware execution order

## Example

```text
TASK backupDB {
  RUN "backup.sh"
  EVERY DAY AT 02:00
}

TASK cleanLogs {
  RUN "clean.sh"
  EVERY DAY AT 03:00
  AFTER backupDB
}

TASK generateReport {
  RUN "report.py"
  AT 18:00
  DEPENDS ON cleanLogs
  IF success
}
```

## Build

```bash
make
```

This generates the lexer and parser, then builds the `tasklang` executable.

## Run

```bash
make run
```

Or run a specific input file directly:

```bash
./tasklang < input.txt
```

## Test

```bash
make test
```

The test target runs the provided valid sample and checks the invalid samples fail as expected.

## Files

- `lexer.l`: token rules for the DSL
- `parser.y`: grammar plus semantic checks and execution logic
- `input.txt`: valid sample program
- `invalid_input.txt`: syntax-invalid sample
- `invalid_circular.txt`: semantic-invalid sample

## Notes

The project is intentionally small, but it demonstrates a complete parser pipeline, semantic validation, and dependency resolution for a custom language.
