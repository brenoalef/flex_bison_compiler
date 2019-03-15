%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol_table.h"
#include "stack_machine.h"
#include "code_generator.h"
// #define YYDEBYG 1

int errors;

struct lbs {
    int for_goto;
    int for_jmp_false;
};

struct lbs *newlblrec() {
    return (struct lbs *) malloc(sizeof(struct lbs));
}

install (char *sym_name) {
    symrec *s;
    s = getsym(sym_name);
    if (s == 0) {
        s = putsym(sym_name);
    } else {
        errors++;
        printf("%s ja definido\n", sym_name);
    }
}

context_check(enum code_ops operation, char *sym_name) {
    symrec *identifier;
    identifier = getsym(sym_name);
    if (identifier == 0) {
        errors++;
        printf("%s", sym_name);
        printf("%s\n", " e um identificador nao declarado");
    } else {
        gen_code(operation, identifier->offset);
    }
}

%}

%union {
    int intval;
    char boolval;
    char* string_val;
    char *id;
    struct lbs *lbls;
}

%start programa

%token VAR
%token INT BOOL STRING
%token DO TO
%token <lbls> IF WHILE
%token ELSE
%token READ WRITE
%token _BEGIN END

%token OR AND NOT
%token EQ NEQ
%token LEQ GEQ
%token LESS GREATER
%token ASSIGN

%token <id> ID
%token <intval> I_CONST
%token B_CONST
%token S_CONST

%left '+' '-'
%left '*' '/'

%type<intval> const
%type<id> l_val

%%

programa:
    VAR 
        listadecl
    _BEGIN      { gen_code(DATA, data_location() - 1); }
        listacmd 
    END         { gen_code(HALT, 0); YYACCEPT; }
    ;
listadecl:
    listadecl vardecl
    | vardecl
    ;
vardecl:
    tipo ':' listavar ';'       //{ install($1, $3); }
    ;
tipo:
    INT | BOOL | STRING
    ;
listavar:
    listavar ',' var            //{ $$ = add_symbol($1, $3); }
    | var                       //{ $$ = $1; }
    ;
var:
    ID                           { install($1); }//{ $$ = strdup($1); }
    //| ID '[' I_CONST ']'        { $$ = strdup($1); }
    ;
listacmd:
    listacmd cmd
    | cmd
    ;
cmd:
    //DO ID ASSIGN val TO val _BEGIN listacmd END
    /*| IF exp                { $1 = (struct lbs *) newlblrec(); $1 -> for_jmp_false = reserve_loc(); }
        listacmd                { $1->for_goto = reserve_loc(); }
      END                       { back_patch($1->for_goto, GOTO, gen_label()); }
    |*/ IF exp                    { $1 = (struct lbs *) newlblrec(); $1 -> for_jmp_false = reserve_loc(); }
        listacmd                { $1->for_goto = reserve_loc(); }
      ELSE                      { back_patch($1->for_jmp_false, JMP_FALSE, gen_label()); }
        listacmd
      END                       { back_patch($1->for_goto, GOTO, gen_label()); }
    | WHILE                     { $1 = (struct lbs *) newlblrec(); $1->for_goto = gen_label(); }
        exp                     { $1->for_jmp_false = reserve_loc(); }
        listacmd 
      END                       { gen_code(GOTO, $1->for_goto); back_patch($1->for_jmp_false, JMP_FALSE, gen_label()); }
    | READ ID ';'               { context_check(READ_INT, $2); }
    | WRITE exp ';'             { gen_code(WRITE_INT, 0); }
    | l_val ASSIGN exp ';'      { context_check(STORE, $1); }
    ;
val:
    I_CONST
    | '-' I_CONST
    ;
l_val:
    ID
    //| ID '[' exp ']'
    ;
exp:
    exp '+' exp         { gen_code(ADD, 0); }
    | exp '-' exp       { gen_code(SUB, 0); }
    | exp '*' exp       { gen_code(MULT, 0); }
    | exp '/' exp       { gen_code(DIV, 0); }
    //| '-' exp           { $$ = -$1; }
    //| exp OR exp        { gen_code(OROP, 0); }
    //| exp AND exp       { gen_code(ANDOP, 0); }
    |// NOT exp           { gen_code(NOTOP, 0); }
    | exp EQ exp        { gen_code(EQU, 0); }
    //| exp NEQ exp       { gen_code(NEQU, 0); }
    | exp GREATER exp   { gen_code(GT, 0); }
    | exp LESS exp      { gen_code(LT, 0); }
    //| exp LEQ exp       { gen_code(LEQU, 0); }
    //| exp GEQ exp       { gen_code(GEQU, 0); }
    | '(' exp ')'
    | const             { gen_code(LD_INT, $1); }
    | ID                { context_check(LD_VAR, $1); }
    //| ID '[' exp ']'    { context_check(LD_VAR, $1); }
    ;
const:
    I_CONST             { $$ = $1; }
    //| B_CONST
    //| S_CONST
    ;

%%

yyerror(char *message) {
    errors++;
    printf("%s\n", message);
}

int main(int argc, char *argv[]) {
	extern FILE *yyin;
    ++argv; --argc;
    yyin = fopen( argv[0], "r" );
    // yydebug = 1;
    yyparse ();
    printf("\nParse completo\n");
    if (errors == 0) {
        //print_code();
        fetch_execute_cycle();
    }
    return 0;
}
