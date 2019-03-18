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

struct var_list {
    symrec *var;
    struct var_list * next;
};

struct var_list * install (char *sym_name) {
    symrec *s;
    s = getsym(sym_name);
    if (s == 0) {
        s = putsym(sym_name);
        struct var_list *v = (struct var_list *) malloc(sizeof(struct var_list));
        v->next = NULL;
        v->var = s;
        return v;
    } else {
        errors++;
        printf("%s ja definido\n", sym_name);
    }
}

set_var_type(char type, struct var_list * vars) {
    printf("set_var_type, %c", type);
    struct var_list * next = vars;
    while (next) {
        set_type(type, (next->var)->offset);
        next = next->next;
    }
}

element *create_int(int arg) {
    element * const_val = (element *) malloc(sizeof(element));
    const_val->el_type = 'i';
    const_val->int_val = arg;
    return const_val;
}

element *create_bool(char arg) {
    element * const_val = (element *) malloc(sizeof(element));
    const_val->el_type = 'b';
    const_val->bool_val = arg;
    return const_val;
}

element *create_string(char *arg) {
    element * const_val = (element *) malloc(sizeof(element));
    const_val->el_type = 's';
    const_val->string_val = arg;
    return const_val;
}

context_check(enum code_ops operation, char *sym_name) {
    symrec *identifier;
    identifier = getsym(sym_name);
    if (identifier == 0) {
        errors++;
        printf("%s", sym_name);
        printf("%s\n", " e um identificador nao declarado");
    } else {
        element * offset = create_int(identifier->offset);
        gen_code(operation, offset);
    }
}

%}

%union {
    int intval;
    char boolval;
    char charval;
    char* string_val;
    char *id;
    struct lbs *lbls;
    struct var_list * var_names;
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
%token <boolval> B_CONST
%token <string_val> S_CONST

%left '+' '-'
%left '*' '/'
%left AND OR
%right NOT

%type<id> l_val
%type<charval> tipo
%type<var_names> var
%type<var_names> listavar

%%

programa:
    VAR 
        listadecl
    _BEGIN      { gen_code(DATA, create_int(data_location() - 1)); }
        listacmd 
    END         { gen_code(HALT, create_int(0)); YYACCEPT; }
    ;
listadecl:
    listadecl vardecl
    | vardecl
    ;
vardecl:
    tipo ':' listavar ';'       { set_var_type($1, $3); }
    ;
tipo:
    INT                         { $$ = 'i'; }               
    | BOOL                      { $$ = 'b'; }
    | STRING                    { $$ = 's'; }
    ;
listavar:
    listavar ',' var            { $1->next = $3; }
    | var                       
    ;
var:
    ID                           { $$ = install($1); }
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
      END                       { gen_code(GOTO, create_int($1->for_goto)); back_patch($1->for_jmp_false, JMP_FALSE, gen_label()); }
    | READ ID ';'               { context_check(READ_VAL, $2); }
    | WRITE exp ';'             { gen_code(WRITE_VAL, create_int(0)); }
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
    exp '+' exp         { gen_code(ADD, create_int(0)); }
    | exp '-' exp       { gen_code(SUB, create_int(0)); }
    | exp '*' exp       { gen_code(MULT, create_int(0)); }
    | exp '/' exp       { gen_code(DIV, create_int(0)); }
    | '-' exp           { gen_code(NEG, create_int(0)); }
    | exp OR exp        { gen_code(OR_OP, create_int(0)); }
    | exp AND exp       { gen_code(AND_OP, create_int(0)); }
    | NOT exp           { gen_code(NOT_OP, create_int(0)); }
    | exp EQ exp        { gen_code(EQU, create_int(0)); }
    | exp NEQ exp       { gen_code(NEQU, create_int(0)); }
    | exp GREATER exp   { gen_code(GT, create_int(0)); }
    | exp LESS exp      { gen_code(LT, create_int(0)); }
    | exp LEQ exp       { gen_code(LEQU, create_int(0)); }
    | exp GEQ exp       { gen_code(GEQU, create_int(0)); }
    | '(' exp ')'
    | const             
    | ID                { context_check(LD_VAR, $1); }
    //| ID '[' exp ']'    { context_check(LD_VAR, $1); }
    ;
const:
    I_CONST             { gen_code(LD_CONST, create_int($1)); }
    | B_CONST           { gen_code(LD_CONST, create_bool($1)); }
    | S_CONST           { gen_code(LD_CONST, create_string(strdup($1))); }
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
        print_code();
        fetch_execute_cycle();
    }
    return 0;
}
