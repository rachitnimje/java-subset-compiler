%{
	#include <stdio.h>
	#include <stdlib.h>	
	#include <string.h>
	#include "y.tab.h"
	#include "header.h"
	int l = 1; // line number
	int yylineno = 1;
	int is_first_write = 1;

	void print_to_file(const char *lexeme, const char *token_type) {
        FILE *lex_file = fopen("outputs/lex_output.txt", "a");  // Open the file in append mode
        if (lex_file == NULL) {
            perror("Error opening lexoutput.txt");
            return;
        }

        // If it's the first write, print the header
        if (is_first_write) {
            fprintf(lex_file, "\n Phase 1 : Lexical Analysis - output (Tokenization)\n====================================================\n\n");
            is_first_write = 0;  // Set the flag to false after the first write
        }

        // Format the output
        char output[256];
        snprintf(output, sizeof(output), " %10s -> %s\n", lexeme, token_type);  // Format output

        fprintf(lex_file, "%s", output);  // Write the formatted output to the file
        fclose(lex_file);  // Close the file
    }
%}

digit      [0-9]
alpha      [a-zA-Z]
und        "_"
comment_start \/\* 
comment_end   \*\/ 

%%

[\n]                    {l++; yylineno++;}
[\t \n]
\/\/(.*)                {}; 
{comment_start}(.|[\n])*{comment_end} {};
({digit})+	            { print_to_file(yytext, "integer");
                          yylval.number = atoi(yytext); 
                          return T_NUM;
                        }
([0-9]*[.])?[0-9]+      { print_to_file(yytext, "float");
                          yylval.number = atof(yytext); 
                          return T_NUM;
                        }
"import"                { print_to_file(yytext, "keyword"); return T_IMPORT; }
"class"	                { print_to_file(yytext, "keyword"); return T_CLASS;  }
"public"                { print_to_file(yytext, "keyword"); return T_PUBLIC; }
"static"                { print_to_file(yytext, "keyword"); return T_STATIC; }
"void"	                { print_to_file(yytext, "keyword"); return T_VOID;   }
"main"                  { print_to_file(yytext, "keyword"); return T_MAIN;   }
"int"                   { print_to_file(yytext, "keyword"); return T_INT;    }
"float"                 { print_to_file(yytext, "keyword"); return T_FLOAT;  }
"if"                    { print_to_file(yytext, "keyword"); return T_IF;     }
"else"                  { print_to_file(yytext, "keyword"); return T_ELSE;   }
"while"                 { print_to_file(yytext, "keyword"); return T_WHILE;  }
"for"                   { print_to_file(yytext, "keyword"); return T_FOR;    }
"do"                    { print_to_file(yytext, "keyword"); return T_DO;     }
"{"                     { print_to_file(yytext, "open parenthesis"); n.s++; return T_OParen;  }
"}"                     { print_to_file(yytext, "close parenthesis"); n.s--; return T_CParen; }
"String"                { print_to_file(yytext, "keyword"); return T_STRING; }
"args"                  { print_to_file(yytext, "keyword"); return T_ARGS;   }
"char"                  { print_to_file(yytext, "keyword"); return T_CHAR;   }

"=="                    { print_to_file(yytext, "operator"); return T_S_EQ; }
"!="                    { print_to_file(yytext, "comparison operator"); return T_NE;  }
">="	                { print_to_file(yytext, "comparison operator"); return T_GEQ; }
"<="	                { print_to_file(yytext, "comparison operator"); return T_LEQ; }
">"	                    { print_to_file(yytext, "comparison operator"); return T_GE;  }
"<"	                    { print_to_file(yytext, "comparison operator"); return T_LE;  }
"="                     { print_to_file(yytext, "assignment operator"); return T_ASSG; }

({alpha}|{und})({alpha}|{und}|{digit})*	{ print_to_file(yytext, "identifier"); 
                            yylval.string = strdup(yytext); 
                            return T_ID;
                        }
\'{alpha}\' { print_to_file(yytext, "character"); yylval.string = strdup(yytext); return T_CHARV;}
.    {return yytext[0];}

%%

int yywrap() {
	return 1;
}
