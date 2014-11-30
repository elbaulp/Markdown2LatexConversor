				 /*----- Sección de Declaraciones --------------*/ 

%option case-insensitive
%option debug
%option verbose

%{
#include<stdio.h>
#include<string.h>

char *trimCharacter(char *str, char *c);
void trimMarkDown();
%}

/* Primitives */ 
word					.+


strong				(_|"*"){2}[^ ]{word}[^ ]("*"|_){2}
em						(_|"*"){1}[^ ]{word}[^ ]("*"|_){1}
list					^"* "|"- "
h1						^#{1}[ ]{1}{word}
h2						^#{2}[ ]{1}{word}
h3						^#{3,6}[ ]{1}{word}
code					`{word}`


%x IN_MARKDOWN_LIST

%%
				 /*----- Sección de Reglas ----------------*/ 

{list}	{BEGIN(IN_MARKDOWN_LIST);fprintf(yyout, "\\begin{itemize}\n");}

%{
	// Si detectamos una linea vacía, no metemos en IN_MARKDOWN_LIST con bEGIN, para comprobar si es un itemize en markdown 
%}
<IN_MARKDOWN_LIST>{
	^\n						fprintf(yyout, "\\end{itemize}\n\n");BEGIN(INITIAL); /* si volvemos a detectar línea vacia, hemos acabado el itemize, o no era nada y salimos */
	^"* "|"- "																						 /* Eliminar la sintáxis de itemize en markdown */
	[^"*"\-\n]+			fprintf(yyout, "\t\\item{%s}\n", yytext); 			 /* Éste es el texto que compone cada línea del itemize */
	\n						yylineno++;BEGIN(IN_MARKDOWN_LIST);							 /* Si detectamos salto de línea, aumentar el número de línea, y seguimos comprobando dentro de IN_MARKDOWN_LIST buscando más items*/
}

{code}	{
					fprintf(yyout, "\\begin{bashcode}\n%s\n\\end{bashcode}", trimCharacter(yytext, "`"));
				}
{h1}		{
					fprintf(yyout, "\\section{%s}", trimCharacter(yytext, "#"));
				}
{h2}		{
					fprintf(yyout, "\\subsection{%s}", trimCharacter(yytext, "#"));
				}
{h3}		{
					fprintf(yyout, "\\subsubsection{%s}", trimCharacter(yytext, "#"));
				}

{strong}		{	
							trimMarkDown(2);
							fprintf(yyout, "\\textbf{%s}", yytext);
						}
{em}				{
							trimMarkDown(1);
							fprintf(yyout, "\\textit{%s}", yytext);
						}





.|\n			{ECHO;}

%%   
				/*----- Sección de Procedimientos --------*/ 

void trimMarkDown(int len){
	yytext[strlen(yytext)-len]='\0'; // exclude last len characters
	yytext+=len; // exclude first len characters
}

/**
 * Thanks to http://stackoverflow.com/a/122721/1612432
 * //fprintf(yyout, "\\textbf{%s}", trimCharacter(yytext, "_*"));
 **/
char *trimCharacter(char *str, char *c)
{
	char *end;

  // Trim leading characters
	while(strncmp(str, c, 1) == 0){
		str++;
	}
	
  if(*str == 0)  // All spaces?
    return str;

  // Trim trailing character
	end = str + strlen(str) - 1;
	while(end > str && (strncmp(end, c, 1) == 0)){ 
		end--;
	}

  // Write new null terminator
  *(end+1) = 0;

  return str;
}

int main (int argc, char *argv[]) {
	if (argc == 2) {
		yyin = fopen (argv[1], "rt");
		if (yyin == NULL) {
			printf ("El fichero %s no se puede abrir\n", argv[1]);
			exit (-1);
		}
	} else 
		yyin = stdin;

	yyout = fopen("salida", "wt");

	if (yyout == NULL) {
		printf ("El fichero %s no se puede abrir\n", argv[1]);
		exit (-1);
	}

	yylex ();
	
	return 0;
}

//<INITIAL>{
	//^\n						BEGIN(IN_MARKDOWN_LIST);fprintf(yyout, "\n\\begin{itemize}\n");
//}

//<IN_MARKDOWN_LIST>{
	//^\n						fprintf(yyout, "\\end{itemize}\n\n");BEGIN(INITIAL); /* si volvemos a detectar línea vacia, hemos acabado el itemize, o no era nada y salimos */
	//^"* "																													 /* Eliminar la sintáxis de itemize en markdown */
	//[^"*"\n]+			fprintf(yyout, "\t\\item{%s}\n", yytext); 			 /* Éste es el texto que compone cada línea del itemize */
	//\n						yylineno++;																			 /* Si detectamos salto de línea, aumentar el número de línea, y seguimos comprobando dentro de IN_MARKDOWN_LIST buscando más items*/
//}

//<INITIAL>{
					//^\n				BEGIN(IN_MARKDOWN_LIST);
				//}
//<IN_MARKDOWN_LIST>{
					//^\n						BEGIN(INITIAL);
					//^"* "
					//[^"*"]+				fprintf(yyout, "\\item{%s}", yytext); // eat comment in chunks
					//\n						yylineno++;
//}

//<INITIAL>{
					//"/*"			BEGIN(IN_COMMENT);
				//}
//<IN_COMMENT>{
					//"*/"			BEGIN(INITIAL);
					//[^*\n]+   fprintf(yyout,"\\item{%s}\n", yytext); // eat comment in chunks
					//"*"       // eat the lone star
					//\n				yylineno++;
//}
