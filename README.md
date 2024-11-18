# Compiler Design Course Project
## Topic : Java Subset Compiler

## Steps to run:
1. `flex lexer.l`
2. `bison -dy parser.y`
3. `gcc lex.yy.c y.tab.c -o compiler`
4. `./compiler.exe`

### Refer to the report for more info