%option noyywrap
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "linguagem.tab.h"

%}

white_space       [ \t]*
digit             [0-9]
alpha             [A-Za-z]
alpha_num         ({alpha}|{digit})
identifier        {alpha}{alpha_num}*
int               {digit}+
bool              (true|false)
string            \"(\\.|[^"\\])*\"

%%

"var"                { printf("var"); return(VAR);}
"int"                { printf("int"); return(INT);}
"bool"               { printf("bool"); return(BOOL);}
"string"             { printf("string"); return(STRING);}

{int}                { printf("i_const"); yylval.intval = atoi(yytext); return(I_CONST);}
{bool}               { printf("b_const"); yylval.boolval = yytext[0] == 't' ? 1 : 0; return(B_CONST);}
{string}             { printf("s_const"); yylval.string_val = yytext; return(S_CONST);}

"do"                 { printf("do"); return(DO);}
"to"                 { printf("to"); return(TO);}

"if"                 { printf("if"); return(IF);}
"else"               { printf("else"); return(ELSE);}

"while"              { printf("while"); return(WHILE);}

"read"               { printf("read"); return(READ);}
"write"              { printf("write"); return(WRITE);}

"begin"              { printf("begin"); return(_BEGIN);}
"end"                { printf("end"); return(END);}

"not"                { printf("not"); return(NOT);}
"and"                { printf("and"); return(AND);}
"or"                 { printf("or"); return(OR);}
"<"                  { printf("less"); return(LESS);}
">"                  { printf("greater"); return(GREATER);}
"<="                 { printf("leq"); return(LEQ);}
">="                 { printf("geq"); return(GEQ);}
"!="                 { printf("neq"); return(NEQ);}
"=="                 { printf("eq"); return(EQ);}
":="                 { printf("assign"); return(ASSIGN);}

{identifier}         { printf("id"); yylval.id = (char *) strdup(yytext); return(ID);}

[*/+\-,;:()\[\]]     { printf("%c", yytext[0]); return(yytext[0]);}

{white_space}        { printf("%s", yytext); /* do nothing */}
\n                   { printf("\n"); /* do nothing */}
.                    { yyerror("Illegal input"); }

%%
