%{
#include "parser.tab.h"
#include <string.h>
#include <stdio.h>
%}

%option yylineno

%%

"TASK"      { return TASK; }
"RUN"       { return RUN; }
"EVERY"     { return EVERY; }
"DAY"       { return DAY; }
"AT"        { return AT; }

"MONDAY"    { return MONDAY; }
"TUESDAY"   { return TUESDAY; }
"WEDNESDAY" { return WEDNESDAY; }
"THURSDAY"  { return THURSDAY; }
"FRIDAY"    { return FRIDAY; }
"SATURDAY"  { return SATURDAY; }
"SUNDAY"    { return SUNDAY; }

"AFTER"     { return AFTER; }
"BEFORE"    { return BEFORE; }
"DEPENDS"   { return DEPENDS; }
"ON"        { return ON; }

"IF"        { return IF; }
"success"   { return SUCCESS; }

[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.str = strdup(yytext);
    return IDENTIFIER;
}

\"[^\"]*\" {
    yylval.str = strdup(yytext);
    return STRING;
}

[0-9]{2}:[0-9]{2} {
    int hour = 0;
    int minute = 0;

    sscanf(yytext, "%d:%d", &hour, &minute);

    if (hour <= 23 && minute <= 59) {
        yylval.str = strdup(yytext);
        return TIME;
    }

    printf("Lexical error on line %d: invalid time '%s'\n", yylineno, yytext);
    exit(1);
}

"{"        { return '{'; }
"}"        { return '}'; }

[ \t\r\n]+ ;

. {
    printf("Lexical error on line %d: unexpected character '%s'\n", yylineno, yytext);
    exit(1);
}

%%

int yywrap() {
    return 1;
}