
/* A Bison parser, made by GNU Bison 2.4.1.  */

/* Skeleton interface for Bison's Yacc-like parsers in C
   
      Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.
   
   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */


/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     T_NUM = 258,
     T_ID = 259,
     T_OParen = 260,
     T_CParen = 261,
     T_PUBLIC = 262,
     T_STATIC = 263,
     T_VOID = 264,
     T_STRING = 265,
     T_ARGS = 266,
     T_WHILE = 267,
     T_MAIN = 268,
     T_DO = 269,
     T_FOR = 270,
     T_IF = 271,
     T_ELSE = 272,
     T_INT = 273,
     T_CLASS = 274,
     T_IMPORT = 275,
     T_FLOAT = 276,
     T_CHAR = 277,
     T_CHARV = 278,
     T_S_EQ = 279,
     T_NE = 280,
     T_ASSG = 281,
     T_GE = 282,
     T_LE = 283,
     T_LEQ = 284,
     T_GEQ = 285
   };
#endif
/* Tokens.  */
#define T_NUM 258
#define T_ID 259
#define T_OParen 260
#define T_CParen 261
#define T_PUBLIC 262
#define T_STATIC 263
#define T_VOID 264
#define T_STRING 265
#define T_ARGS 266
#define T_WHILE 267
#define T_MAIN 268
#define T_DO 269
#define T_FOR 270
#define T_IF 271
#define T_ELSE 272
#define T_INT 273
#define T_CLASS 274
#define T_IMPORT 275
#define T_FLOAT 276
#define T_CHAR 277
#define T_CHARV 278
#define T_S_EQ 279
#define T_NE 280
#define T_ASSG 281
#define T_GE 282
#define T_LE 283
#define T_LEQ 284
#define T_GEQ 285




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
{

/* Line 1676 of yacc.c  */
#line 68 "parser.y"

    float number;
    char *string;
	struct node *tree;



/* Line 1676 of yacc.c  */
#line 120 "y.tab.h"
} YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif

extern YYSTYPE yylval;


