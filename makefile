all: linguagem
linguagem.tab.c linguagem.tab.h:	linguagem.y
	bison -d linguagem.y
lex.yy.c: linguagem.l linguagem.tab.h
	flex linguagem.l
linguagem: lex.yy.c linguagem.tab.c linguagem.tab.h
	gcc -o linguagem linguagem.tab.c lex.yy.c
clean:
	rm linguagem linguagem.tab.c lex.yy.c linguagem.tab.h