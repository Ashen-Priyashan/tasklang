%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);
extern int yylineno;

#define MAX_TASKS 100

typedef struct {
    char *name;
    char *script;
    char *schedule;
    char *dependencyType;
    char *dependency;
    int hasCondition;
  int taskLine;
  int dependencyLine;
} TaskInfo;

TaskInfo tasks[MAX_TASKS];
int taskCount = 0;

char *currentTask;
char *currentScript;
char *currentTime;
char *currentDependency;
char *dependencyType;
char *scheduleType;
char *scheduleDay;
int currentTaskLine = 0;
int currentDependencyLine = 0;
int hasCondition = 0;

int findTask(char *name) {
    for (int i = 0; i < taskCount; i++) {
        if (strcmp(tasks[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

void resetCurrentTaskState() {
  currentTask = NULL;
  currentScript = NULL;
  currentTime = NULL;
  currentDependency = NULL;
  dependencyType = NULL;
  scheduleType = NULL;
  scheduleDay = NULL;
  currentTaskLine = 0;
  currentDependencyLine = 0;
  hasCondition = 0;
}

int validateCurrentTask() {
  if (currentTask == NULL) {
    printf("Syntax error: task name is missing\n");
    return 1;
  }

  if (currentScript == NULL) {
    printf("Syntax error on line %d: task '%s' is missing RUN\n", currentTaskLine, currentTask);
    return 1;
  }

  if (currentTime == NULL) {
    printf("Syntax error on line %d: task '%s' is missing a schedule\n", currentTaskLine, currentTask);
    return 1;
  }

  return 0;
}

void addTask() {
  if (taskCount >= MAX_TASKS) {
    printf("Semantic error: too many tasks (max %d)\n", MAX_TASKS);
    exit(1);
  }

  if (validateCurrentTask()) {
    exit(1);
  }

    tasks[taskCount].name = currentTask;
    tasks[taskCount].script = currentScript;

    char buffer[100];

    if (scheduleDay != NULL) {
        sprintf(buffer, "EVERY %s AT %s", scheduleDay, currentTime);
    } else {
        sprintf(buffer, "%s %s", scheduleType, currentTime);
    }

    tasks[taskCount].schedule = strdup(buffer);
    tasks[taskCount].dependencyType = dependencyType;
    tasks[taskCount].dependency = currentDependency;
    tasks[taskCount].hasCondition = hasCondition;
    tasks[taskCount].taskLine = currentTaskLine;
    tasks[taskCount].dependencyLine = currentDependencyLine;

    taskCount++;

    currentTask = NULL;
    currentScript = NULL;
    currentTime = NULL;
    currentDependency = NULL;
    dependencyType = NULL;
    scheduleType = NULL;
    scheduleDay = NULL;
    currentTaskLine = 0;
    currentDependencyLine = 0;
    hasCondition = 0;
}

  int taskReadyForExecution(int taskIndex, int printed[]) {
    if (tasks[taskIndex].dependencyType != NULL) {
      if (strcmp(tasks[taskIndex].dependencyType, "AFTER") == 0 ||
        strcmp(tasks[taskIndex].dependencyType, "DEPENDS ON") == 0) {
        int dependencyIndex = findTask(tasks[taskIndex].dependency);

        if (dependencyIndex != -1 && !printed[dependencyIndex]) {
          return 0;
        }
      }
    }

    for (int i = 0; i < taskCount; i++) {
      if (tasks[i].dependencyType != NULL &&
        strcmp(tasks[i].dependencyType, "BEFORE") == 0 &&
        strcmp(tasks[i].dependency, tasks[taskIndex].name) == 0 &&
        !printed[i]) {
        return 0;
      }
    }

    return 1;
  }

int getPrerequisite(int taskIndex, int relationIndex) {
    int count = 0;

    if (tasks[taskIndex].dependencyType != NULL) {
        if (strcmp(tasks[taskIndex].dependencyType, "AFTER") == 0 ||
            strcmp(tasks[taskIndex].dependencyType, "DEPENDS ON") == 0) {

            if (count == relationIndex) {
                return findTask(tasks[taskIndex].dependency);
            }
            count++;
        }
    }

    for (int i = 0; i < taskCount; i++) {
        if (tasks[i].dependencyType != NULL &&
            strcmp(tasks[i].dependencyType, "BEFORE") == 0 &&
            strcmp(tasks[i].dependency, tasks[taskIndex].name) == 0) {

            if (count == relationIndex) {
                return i;
            }
            count++;
        }
    }

    return -1;
}

void printCycle(int stack[], int depth, int cycleStart) {
  int start = -1;

  for (int i = 0; i < depth; i++) {
    if (stack[i] == cycleStart) {
      start = i;
      break;
    }
  }

  if (start == -1) {
    printf("Semantic error: circular dependency detected.\n");
    return;
  }

  printf("Semantic error: circular dependency detected: ");

  for (int i = start; i < depth; i++) {
    printf("%s(line %d) -> ", tasks[stack[i]].name, tasks[stack[i]].taskLine);
  }

  printf("%s(line %d)\n", tasks[cycleStart].name, tasks[cycleStart].taskLine);
}

int dfs(int index, int color[], int stack[], int depth) {
    color[index] = 1;
  stack[depth] = index;

    for (int r = 0; ; r++) {
        int prereq = getPrerequisite(index, r);

        if (prereq == -1) {
            break;
        }

        if (color[prereq] == 1) {
            printCycle(stack, depth + 1, prereq);
            return 1;
        }

          if (color[prereq] == 0 && dfs(prereq, color, stack, depth + 1)) {
            return 1;
        }
    }

    color[index] = 2;
    return 0;
}

int hasCircularDependency() {
    int color[MAX_TASKS] = {0};
  int stack[MAX_TASKS];

    for (int i = 0; i < taskCount; i++) {
        if (color[i] == 0) {
      if (dfs(i, color, stack, 0)) {
                return 1;
            }
        }
    }

    return 0;
}

int hasUnknownDependency() {
    for (int i = 0; i < taskCount; i++) {
        if (tasks[i].dependencyType != NULL) {
            if (findTask(tasks[i].dependency) == -1) {
        printf("Semantic error on line %d: task '%s' refers to unknown task '%s'\n",
             tasks[i].dependencyLine,
             tasks[i].name,
             tasks[i].dependency);
                return 1;
            }
        }
    }
    return 0;
}

void printTasks() {
    printf("--- EXECUTION START ---\n");

  int printed[MAX_TASKS] = {0};
  int printedCount = 0;

  while (printedCount < taskCount) {
    int progress = 0;

    for (int i = 0; i < taskCount; i++) {
      if (printed[i] || !taskReadyForExecution(i, printed)) {
        continue;
      }

      printf("Executing Task: %s\n", tasks[i].name);
      printf("  Script: %s\n", tasks[i].script);
      printf("  Schedule: %s\n", tasks[i].schedule);

      if (tasks[i].dependencyType != NULL) {
        printf("  %s %s\n", tasks[i].dependencyType, tasks[i].dependency);
      }

      if (tasks[i].hasCondition) {
        printf("  Condition: success\n");
      }

      printf("\n");

      printed[i] = 1;
      printedCount++;
      progress = 1;
    }

    if (!progress) {
      break;
    }
  }

  if (printedCount != taskCount) {
    for (int i = 0; i < taskCount; i++) {
      if (!printed[i]) {
        printf("Semantic error: unresolved execution order for task '%s'\n", tasks[i].name);
        return;
      }
    }
    }

    printf("--- EXECUTION COMPLETE ---\n");
}
%}

%union {
    char *str;
}

%define parse.error verbose

%token TASK RUN EVERY DAY AT
%token MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY SUNDAY
%token AFTER BEFORE DEPENDS ON IF SUCCESS
%token <str> IDENTIFIER STRING TIME

%type <str> week_day

%%

program:
      task_list
    ;

task_list:
      task_list task
    | task
    ;

task:
      TASK IDENTIFIER
      {
        currentTask = $2;
        currentTaskLine = yylineno;
      }
      '{' task_body '}'
      {
        addTask();
      }
    ;

task_body:
      task_body task_item
    | task_item
    ;

task_item:
      run_stmt
    | schedule_stmt
    | dependency_stmt
    | condition_stmt
    ;

run_stmt:
      RUN STRING
      {
        if (currentScript != NULL) {
          printf("Syntax error: duplicate RUN in task\n");
          exit(1);
        }

        currentScript = $2;
      }
    ;

schedule_stmt:
      EVERY DAY AT TIME
      {
        if (currentTime != NULL) {
          printf("Syntax error: duplicate schedule in task\n");
          exit(1);
        }

        currentTime = $4;
        scheduleType = "EVERY DAY AT";
        scheduleDay = NULL;
      }
    | EVERY week_day AT TIME
      {
        if (currentTime != NULL) {
          printf("Syntax error: duplicate schedule in task\n");
          exit(1);
        }

        currentTime = $4;
        scheduleType = "EVERY";
        scheduleDay = $2;
      }
    | AT TIME
      {
        if (currentTime != NULL) {
          printf("Syntax error: duplicate schedule in task\n");
          exit(1);
        }

        currentTime = $2;
        scheduleType = "AT";
        scheduleDay = NULL;
      }
    ;

week_day:
      MONDAY    { $$ = "MONDAY"; }
    | TUESDAY   { $$ = "TUESDAY"; }
    | WEDNESDAY { $$ = "WEDNESDAY"; }
    | THURSDAY  { $$ = "THURSDAY"; }
    | FRIDAY    { $$ = "FRIDAY"; }
    | SATURDAY  { $$ = "SATURDAY"; }
    | SUNDAY    { $$ = "SUNDAY"; }
    ;

dependency_stmt:
      AFTER IDENTIFIER
      {
        if (currentDependency != NULL) {
          printf("Syntax error: duplicate dependency in task\n");
          exit(1);
        }

        currentDependency = $2;
        dependencyType = "AFTER";
        currentDependencyLine = yylineno;
      }
    | BEFORE IDENTIFIER
      {
        if (currentDependency != NULL) {
          printf("Syntax error: duplicate dependency in task\n");
          exit(1);
        }

        currentDependency = $2;
        dependencyType = "BEFORE";
        currentDependencyLine = yylineno;
      }
    | DEPENDS ON IDENTIFIER
      {
        if (currentDependency != NULL) {
          printf("Syntax error: duplicate dependency in task\n");
          exit(1);
        }

        currentDependency = $3;
        dependencyType = "DEPENDS ON";
        currentDependencyLine = yylineno;
      }
    ;

condition_stmt:
      IF SUCCESS
      {
        if (hasCondition) {
          printf("Syntax error: duplicate condition in task\n");
          exit(1);
        }

        hasCondition = 1;
      }
    ;

%%

void yyerror(const char *s) {
  printf("Syntax error on line %d: %s\n", yylineno, s);
}

int main() {
    printf("Parsing TaskLang++ input...\n\n");

  resetCurrentTaskState();

  if (yyparse() != 0) {
    return 1;
    }

  if (hasUnknownDependency()) {
    return 1;
  }

  if (hasCircularDependency()) {
    return 1;
  }

  printTasks();

    return 0;
}