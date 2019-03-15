enum code_ops {
    HALT, STORE, JMP_FALSE, GOTO,
    DATA, LD_CONST, LD_VAR,
    READ_VAL, WRITE_VAL,
    LT, LEQU, EQU, GEQU, GT, NEQU,
    NOT_OP, AND_OP, OR_OP,
    ADD, SUB, NEG, MULT, DIV
};

char *op_name[] = {
    "halt", "store", "jmp_false", "goto",
    "data", "ld_const", "ld_var",
    "in_val", "out_val",
    "lt", "lequ", "equ", "gequ", "gt", "nequ",
    "not_op", "and_op", "or_op",
    "add", "sub", "neg", "mult", "div"
};

struct instruction {
    enum code_ops op;
    element *arg;
};

struct instruction code[999];

element stack[999];

int pc = 0;
struct instruction ir;
int  ar  = 0;
int top = 0;
char ch;

void check_type(element *val1, element *val2, char type) {
    if (val1->el_type != type || (val2 != NULL && val2->el_type != type)) {
        yyerror("Tipo incompativel");
    }
}

void fetch_execute_cycle() {
    do {
        ir = code[pc++];
        switch (ir.op) {
            case HALT:
                printf("halt\n");
                break;
            case READ_VAL:
                printf("Input: ");
                int arg = ir.arg->int_val;
                switch (stack[ar + arg].el_type) {
                    case 'i':
                        scanf("%d", &stack[ar + arg].int_val);
                        break;
                    case 'b':
                        scanf("%c", &stack[ar + arg].bool_val);
                        stack[ar + arg].bool_val = stack[ar + arg].bool_val == 0 ? 0 : 1;
                        break;
                    case 's':
                        scanf("%s", stack[ar + arg].string_val);
                        break;    
                }
                break;
            case WRITE_VAL:
                switch(stack[top].el_type) {
                    case 'i':
                        printf("%d\n", stack[top--].int_val);
                        break;
                    case 'b':
                        printf("%d\n", stack[top--].bool_val);
                        break;
                    case 's':
                        printf("%s\n", stack[top--].string_val);
                        break;
                }
                break;
            case STORE:
                stack[ir.arg->int_val] = stack[top--];
                break;
            case JMP_FALSE:
                if (stack[top--].bool_val == 0) {
                    pc = ir.arg->int_val;
                }
                break;
            case GOTO:
                pc = ir.arg->int_val;
                break;
            case DATA:
                top = top + ir.arg->int_val;
                break;
            case LD_CONST:
                stack[++top] = *ir.arg;
                break;
            case LD_VAR:
                stack[++top] = stack[ar + ir.arg->int_val];
                break;
            case LT:
                check_type(&stack[top - 1], &stack[top], 'i');
                stack[top - 1].el_type = 'b';
                if (stack[top - 1].int_val < stack[top].int_val) {
                    stack[--top].bool_val = 1;
                } else {
                    stack[--top].bool_val = 0;
                }
                break;
            case LEQU:
                check_type(&stack[top - 1], &stack[top], 'i');
                stack[top - 1].el_type = 'b';
                if (stack[top - 1].int_val <= stack[top].int_val) {
                    stack[--top].bool_val = 1;
                } else {
                    stack[--top].bool_val = 0;
                }
                break;
            case EQU:
                check_type(&stack[top - 1], &stack[top], 'i');
                stack[top - 1].el_type = 'b';
                if (stack[top - 1].int_val == stack[top].int_val) {
                    stack[--top].bool_val = 1;
                } else {
                    stack[--top].bool_val = 0;
                }
                break;
            case GEQU:
                check_type(&stack[top - 1], &stack[top], 'i');
                stack[top - 1].el_type = 'b';
                if (stack[top - 1].int_val >= stack[top].int_val) {
                    stack[--top].bool_val = 1;
                } else {
                    stack[--top].bool_val = 0;
                }
                break;
            case GT:
                check_type(&stack[top - 1], &stack[top], 'i');
                stack[top - 1].el_type = 'b';
                if (stack[top - 1].int_val > stack[top].int_val) {
                    stack[--top].bool_val = 1;
                } else {
                    stack[--top].bool_val = 0;
                }
                break;
            case NEQU:
                check_type(&stack[top - 1], &stack[top], 'i');
                stack[top - 1].el_type = 'b';
                if (stack[top - 1].int_val != stack[top].int_val) {
                    stack[--top].bool_val = 1;
                } else {
                    stack[--top].bool_val = 0;
                }
                break;
            case NOT_OP:
                check_type(&stack[top], NULL, 'b');
                stack[top].bool_val = !stack[top].bool_val;
                break;
            case AND_OP:
                check_type(&stack[top - 1], &stack[top], 'b');
                if (stack[top - 1].bool_val && stack[top].bool_val) {
                    stack[--top].bool_val = 1;
                } else {
                    stack[--top].bool_val = 0;
                }
                break;
            case OR_OP:
                check_type(&stack[top - 1], &stack[top], 'b');
                if (stack[top - 1].bool_val || stack[top].bool_val) {
                    stack[--top].bool_val = 1;
                } else {
                    stack[--top].bool_val = 0;
                }
                break;
            case ADD:
                check_type(&stack[top - 1], &stack[top], 'i');
                stack[top - 1].int_val = stack[top - 1].int_val + stack[top].int_val;
                top--;
                break;
            case SUB:
                check_type(&stack[top - 1], &stack[top], 'i');
                stack[top - 1].int_val = stack[top - 1].int_val - stack[top].int_val;
                top--;
                break;
            case NEG:
                check_type(&stack[top], NULL, 'i');
                stack[top].int_val = - stack[top].int_val;
                break;   
            case MULT:
                check_type(&stack[top - 1], &stack[top], 'i');
                stack[top - 1].int_val = stack[top - 1].int_val * stack[top].int_val;
                top--;
                break;
            case DIV:
                check_type(&stack[top - 1], &stack[top], 'i');
                stack[top - 1].int_val = stack[top - 1].int_val / stack[top].int_val;
                top--;
                break;
            default:
                printf("Internal Error: Memory Dump\n");
                break;
        }
    } while (ir.op != HALT);
}
