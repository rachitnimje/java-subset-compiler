%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "header.h"

scope n = {0}; // Define the global variable n
extern FILE *yyin;
FILE *icg_output;
FILE *symtab_output;
FILE *syntree_output;

//---------SYMBOL TABLE STRUCTURE and DEFINTIONS------------
struct double_list {
	struct double_list * next;
  	char name[30];
  	int type; // 0-int 1-float 2-char 
  	int l;//line number
  	int scope;  	
	union Value {
    	int val;
    	char vale;
    	float valu;
  	} value;
};

typedef struct double_list d_list;
d_list* head=NULL;

int fill(char* name,float value,int type);
int  fill_char(char* name,char value,int type);
int  fill_float(char* name,float value,int type);
d_list* lookupsymb(char *id);
void display();
int update(char* id,float value);

//-----MISC DEFINITIONS----------------
int yylex(void);
void yyerror(char *);
extern int yylineno;
int tempno=0;// Global Variable for 
int label=0;
int b_lbl=0;

typedef struct node {
    struct node* left;
    struct node* right;
    int type;  // 0-leaf value, 1-interior node, 2-leaf x, 3-temp_variable
    char* token;
    char* tmp;  // Name of temp var
    float value;
    d_list* ptr;
    char* name;  // Added to store variable names
} node;

union leafval {
	char val1[20];
	float val2;
}; 

node* initialize_node();
node* leaf(int type,union leafval f);
node* new_node(char* token,node* left,node* right);
void preorder(node* root, int indent, FILE* syn_tree_file);

%}

%union {
    float number;
    char *string;
	struct node *tree;
}

%token <number> T_NUM  
%token <string> T_ID
%type<tree> T_Const
%type<tree> cond
%type<tree> cond_stmts
%type<tree> stmt
%type<tree> stmts
%type<tree> var_decl
%type<tree> iter_stmts
%token <number> T_OParen
%token T_CParen
%type<tree> T_expr
%token T_PUBLIC T_STATIC T_VOID T_STRING T_ARGS
%token  T_WHILE T_MAIN  T_DO T_FOR T_IF T_ELSE
%token T_INT  T_CLASS  T_IMPORT T_FLOAT T_CHAR 
%token T_CHARV
%type<string> T_CHARV
%nonassoc  T_S_EQ
%right T_GEQ T_LEQ T_LE T_GE T_ASSG T_NE
%left '+' '-'
%left '%' '*' '/'


%%

class_def:
    modifier Class_head
;

Class_head:
    T_CLASS T_ID T_OParen main_stmt T_CParen   {display();}
;

main_stmt:
    modifier modifier modifier T_MAIN '(' T_STRING '[' ']' T_ARGS ')' T_OParen stmts T_CParen 
	{
		FILE *syn_tree_file = fopen("outputs/syn_tree_output.txt", "w");
		if (syn_tree_file == NULL) {
			perror("Error opening syn_tree_output.txt");
		}
		fprintf(syn_tree_file, "\n Phase 2 : Syntax Analysis - output (AST)\n==============================================\n\n");
		preorder($12, 0, syn_tree_file);
		fclose(syn_tree_file);
	}
;

modifier:
    T_PUBLIC  
    |T_STATIC
    |T_VOID
;

stmts:
 stmts stmt {$$=new_node("MStmts",$1,$2);}
 | stmt {$$=$1;}
;
 
stmt:
    T_ID T_ASSG T_expr ';' { 
        if(lookupsymb($1) != NULL)
        {
            union leafval f;
            strcpy(f.val1, $1);                     
            $$ = new_node("EQUALS", leaf(2, f), $3);

            //Updating Symbol Table
            d_list* t = lookupsymb($1);    
            t->value.val = $3->value;            
                        
            //Printing ICG
            if($3->type == 0)
                fprintf(icg_output, "%s=%d\n", $1, (int)$3->value);
            else if($3->type == 1)
                fprintf(icg_output, "%s=%s\n", $1, $3->tmp);
            else if($3->type == 2)    
                fprintf(icg_output, "%s=%s\n", $1, $3->ptr->name);
        }
    	}  
	| T_ID T_ASSG T_CHARV ';' {
        if(lookupsymb($1) != NULL) {
            d_list* t = lookupsymb($1);
            if(t->type == 2) { // Check if variable is of type char
                t->value.vale = $3[1]; // Store the character value (skip the quotes)
                fprintf(icg_output, "%s=%s\n", $1, $3);
                union leafval f;
                strcpy(f.val1, $1);
                $$ = new_node("EQUALS", leaf(2, f), NULL);
            } else {
                printf("Type mismatch: Cannot assign char to non-char variable at line %d\n", yylineno);
                yyerror("");
            }
        }
    	}
    | var_decl
    | cond_stmts
    | iter_stmts
;

cond_stmts:
  T_IF '(' cond ')' {fprintf(icg_output, "t%d=not %s\n",tempno,$3->tmp);
  						fprintf(icg_output, "if t%d goto L%d\n",tempno,label);} T_OParen stmts T_CParen { 
						$$=new_node("if",$3,$7);
						fprintf(icg_output, "L%d: ",label++);
						
					    }
;

iter_stmts:
    T_WHILE '(' cond ')' {
        fprintf(icg_output, "t%d=not %s\n",tempno,$3->tmp); 
        b_lbl=label;
        fprintf(icg_output, "if t%d goto L%d\n",tempno,label+1);
        fprintf(icg_output, "L%d : ",label++);
    } 
    T_OParen stmts T_CParen { 
        $$=new_node("while",$3,$7);
        fprintf(icg_output, "goto L%d\n",b_lbl);
        fprintf(icg_output, "L%d : ",label++);
    }
    | T_DO {
        b_lbl = label;
        fprintf(icg_output, "L%d : ", label++);
    } T_OParen stmts T_CParen T_WHILE '(' cond ')' ';' {
        $$ = new_node("do-while", $4, $8);
        fprintf(icg_output, "t%d=not %s\n", tempno, $8->tmp);
        fprintf(icg_output, "if t%d goto L%d\n", tempno, label);
        fprintf(icg_output, "goto L%d\n", b_lbl);
        fprintf(icg_output, "L%d : ", label++);
    }
	 | T_FOR '(' var_decl cond ';' T_ID T_ASSG T_expr ')' {
        fprintf(icg_output, "t%d=not %s\n",tempno,$4->tmp); 
        b_lbl=label;
        fprintf(icg_output, "if t%d goto L%d\n",tempno,label+1);
        fprintf(icg_output, "L%d : ",label++);
    }    
    T_OParen stmts T_CParen { 
        $$=new_node("for",$4,$12);
        fprintf(icg_output, "goto L%d\n",b_lbl);
        fprintf(icg_output, "L%d : ",label++);
    }
;




T_expr:
   T_expr '+' T_expr {
			$$=new_node("ADD",$1,$3); 
			$$->value=$1->value+$3->value;
				
			sprintf($$->tmp, "t%d", tempno++);
			if($1->type==0 && $3->type==0)
				fprintf(icg_output, "%s=%d+%d\n",$$->tmp,(int)$1->value,(int)$3->value);
		      	else if($1->type==0 && $3->type==1)
				fprintf(icg_output, "%s=%d+%s\n",$$->tmp,(int)$1->value,$3->tmp);
		        else if($1->type==1 && $3->type==0)
				fprintf(icg_output, "%s=%s+%d\n",$$->tmp,$1->tmp,(int)$3->value);
		        else if($1->type==1 && $3->type==1)
				fprintf(icg_output, "%s=%s+%s\n",$$->tmp,$1->tmp,$3->tmp);
		        else if($1->type==0 && $3->type==2)
				fprintf(icg_output, "%s=%d+%s\n",$$->tmp,(int)$1->value,$3->ptr->name);
			else if($1->type==2 && $3->type==0)
				fprintf(icg_output, "%s=%s+%d\n",$$->tmp,$1->ptr->name,(int)$3->value);
			else if($1->type==1 && $3->type==2)
				fprintf(icg_output, "%s=%s+%s\n",$$->tmp,$1->tmp,$3->ptr->name);
			else if($1->type==2 && $3->type==1)
				fprintf(icg_output, "%s=%s+%s\n",$$->tmp,$1->ptr->name,$3->tmp);
			
		     }
   | T_expr '-' T_expr {
			$$=new_node("SUB",$1,$3); 
			$$->value=$1->value-$3->value;
			
			sprintf($$->tmp, "t%d", tempno++);
			if($1->type==0 && $3->type==0)
				fprintf(icg_output, "%s=%d-%d\n",$$->tmp,(int)$1->value,(int)$3->value);
		      	else if($1->type==0 && $3->type==1)
				fprintf(icg_output, "%s=%d-%s\n",$$->tmp,(int)$1->value,$3->tmp);
		        else if($1->type==1 && $3->type==0)
				fprintf(icg_output, "%s=%s-%d\n",$$->tmp,$1->tmp,(int)$3->value);
		        else if($1->type==1 && $3->type==1)
				fprintf(icg_output, "%s=%s-%s\n",$$->tmp,$1->tmp,$3->tmp);
		        else if($1->type==0 && $3->type==2)
				fprintf(icg_output, "%s=%d-%s\n",$$->tmp,(int)$1->value,$3->ptr->name);
			else if($1->type==2 && $3->type==0)
				fprintf(icg_output, "%s=%s-%d\n",$$->tmp,$1->ptr->name,(int)$3->value);
			else if($1->type==1 && $3->type==2)
				fprintf(icg_output, "%s=%s-%s\n",$$->tmp,$1->tmp,$3->ptr->name);
			else if($1->type==2 && $3->type==1)
				fprintf(icg_output, "%s=%s-%s\n",$$->tmp,$1->ptr->name,$3->tmp);
			
		     }
   | T_expr '*' T_expr{
			$$=new_node("MUL",$1,$3); 
			$$->value=$1->value*$3->value;
			
			sprintf($$->tmp, "t%d", tempno++);
			if($1->type==0 && $3->type==0)
				fprintf(icg_output, "%s=%d*%d\n",$$->tmp,(int)$1->value,(int)$3->value);
		      	else if($1->type==0 && $3->type==1)
				fprintf(icg_output, "%s=%d*%s\n",$$->tmp,(int)$1->value,$3->tmp);
		        else if($1->type==1 && $3->type==0)
				fprintf(icg_output, "%s=%s*%d\n",$$->tmp,$1->tmp,(int)$3->value);
		        else if($1->type==1 && $3->type==1)
				fprintf(icg_output, "%s=%s*%s\n",$$->tmp,$1->tmp,$3->tmp);
		        else if($1->type==0 && $3->type==2)
				fprintf(icg_output, "%s=%d*%s\n",$$->tmp,(int)$1->value,$3->ptr->name);
			else if($1->type==2 && $3->type==0)
				fprintf(icg_output, "%s=%s*%d\n",$$->tmp,$1->ptr->name,(int)$3->value);
			else if($1->type==1 && $3->type==2)
				fprintf(icg_output, "%s=%s*%s\n",$$->tmp,$1->tmp,$3->ptr->name);
			else if($1->type==2 && $3->type==1)
				fprintf(icg_output, "%s=%s*%s\n",$$->tmp,$1->ptr->name,$3->tmp);
			
		     }
   | T_expr '/' T_expr{
			$$=new_node("DIV",$1,$3); 
			$$->value=$1->value/$3->value;
			
			sprintf($$->tmp, "t%d", tempno++);
			if($1->type==0 && $3->type==0)
				fprintf(icg_output, "%s=%d/%d\n",$$->tmp,(int)$1->value,(int)$3->value);
		      	else if($1->type==0 && $3->type==1)
				fprintf(icg_output, "%s=%d/%s\n",$$->tmp,(int)$1->value,$3->tmp);
		        else if($1->type==1 && $3->type==0)
				fprintf(icg_output, "%s=%s/%d\n",$$->tmp,$1->tmp,(int)$3->value);
		        else if($1->type==1 && $3->type==1)
				fprintf(icg_output, "%s=%s/%s\n",$$->tmp,$1->tmp,$3->tmp);
		        else if($1->type==0 && $3->type==2)
				fprintf(icg_output, "%s=%d/%s\n",$$->tmp,(int)$1->value,$3->ptr->name);
			else if($1->type==2 && $3->type==0)
				fprintf(icg_output, "%s=%s/%d\n",$$->tmp,$1->ptr->name,(int)$3->value);
			else if($1->type==1 && $3->type==2)
				fprintf(icg_output, "%s=%s/%s\n",$$->tmp,$1->tmp,$3->ptr->name);
			else if($1->type==2 && $3->type==1)
				fprintf(icg_output, "%s=%s/%s\n",$$->tmp,$1->ptr->name,$3->tmp);
			
		     }
   | T_Const {	$$=$1; /*printf("%d\n",$$->type);*/ /*sprintf($$->tmp, "t%d", tempno++);if($$->type==1) printf("%s=%d\n",$$->tmp,(int)$1->value);*/}
;

T_Const:
    T_NUM {union leafval f;f.val2=$1; $$=leaf(0,f);}
    | T_ID {
		if(lookupsymb($1)!=NULL)
		 {
			union leafval f;
			strcpy(f.val1,$1); 
			$$=leaf(2,f);
			d_list* t=lookupsymb($1);
			$$->value=t->value.val;
		 }
	}
;

cond:
    T_expr T_GEQ T_expr  {	$$=new_node(">=",$1,$3); 
    			if($1->value>=$3->value) 
    				$$->value=1; 
    			else 
    				$$->value=0;
    			sprintf($$->tmp, "t%d", tempno++);
    			if($1->type==0 && $3->type==0)
    				fprintf(icg_output, "%s=%d>=%d\n",$$->tmp,(int)$1->value,(int)$3->value);
    		      	else if($1->type==0 && $3->type==1)
    				fprintf(icg_output, "%s=%d>=%s\n",$$->tmp,(int)$1->value,$3->tmp);
    		        else if($1->type==1 && $3->type==0)
    				fprintf(icg_output, "%s=%s>=%d\n",$$->tmp,$1->tmp,(int)$3->value);
    		        else if($1->type==1 && $3->type==1)
    				fprintf(icg_output, "%s=%s>=%s\n",$$->tmp,$1->tmp,$3->tmp);
    		        else if($1->type==0 && $3->type==2)
    				fprintf(icg_output, "%s=%d>=%s\n",$$->tmp,(int)$1->value,$3->ptr->name);
    			else if($1->type==2 && $3->type==0)
    				fprintf(icg_output, "%s=%s>=%d\n",$$->tmp,$1->ptr->name,(int)$3->value);
    			else if($1->type==1 && $3->type==2)
    				fprintf(icg_output, "%s=%s>=%s\n",$$->tmp,$1->tmp,$3->ptr->name);
    			else if($1->type==2 && $3->type==1)
    				fprintf(icg_output, "%s=%s>=%s\n",$$->tmp,$1->ptr->name,$3->tmp);
    			else if($1->type==2 &&$3->type==2)
    				fprintf(icg_output, "%s=%s>=%s\n",$$->tmp,$1->ptr->name,$3->ptr->name);
    
    		     }
    |T_expr T_LEQ T_expr {
    			$$=new_node("<=",$1,$3); 
    			if($1->value<=$3->value) 
    				$$->value=1; 
    			else $$->value=0;
    			sprintf($$->tmp, "t%d", tempno++);
    			if($1->type==0 && $3->type==0)
    				fprintf(icg_output, "%s=%d<=%d\n",$$->tmp,(int)$1->value,(int)$3->value);
    		      	else if($1->type==0 && $3->type==1)
    				fprintf(icg_output, "%s=%d<=%s\n",$$->tmp,(int)$1->value,$3->tmp);
    		        else if($1->type==1 && $3->type==0)
    				fprintf(icg_output, "%s=%s<=%d\n",$$->tmp,$1->tmp,(int)$3->value);
    		        else if($1->type==1 && $3->type==1)
    				fprintf(icg_output, "%s=%s<=%s\n",$$->tmp,$1->tmp,$3->tmp);
    		        else if($1->type==0 && $3->type==2)
    				fprintf(icg_output, "%s=%d<=%s\n",$$->tmp,(int)$1->value,$3->ptr->name);
    			else if($1->type==2 && $3->type==0)
    				fprintf(icg_output, "%s=%s<=%d\n",$$->tmp,$1->ptr->name,(int)$3->value);
    			else if($1->type==1 && $3->type==2)
    				fprintf(icg_output, "%s=%s<=%s\n",$$->tmp,$1->tmp,$3->ptr->name);
    			else if($1->type==2 && $3->type==1)
    				fprintf(icg_output, "%s=%s<=%s\n",$$->tmp,$1->ptr->name,$3->tmp);
    			else if($1->type==2 &&$3->type==2)
    				fprintf(icg_output, "%s=%s<=%s\n",$$->tmp,$1->ptr->name,$3->ptr->name);
    
    		     }
    |T_expr T_GE T_expr  {
    			$$=new_node(">",$1,$3);  
    			if($1->value>$3->value) 
    				$$->value=1; 
    			else 
    				$$->value=0;
    			sprintf($$->tmp, "t%d", tempno++);
    			if($1->type==0 && $3->type==0)
    				fprintf(icg_output, "%s=%d>%d\n",$$->tmp,(int)$1->value,(int)$3->value);
    		      	else if($1->type==0 && $3->type==1)
    				fprintf(icg_output, "%s=%d>%s\n",$$->tmp,(int)$1->value,$3->tmp);
    		        else if($1->type==1 && $3->type==0)
    				fprintf(icg_output, "%s=%s>%d\n",$$->tmp,$1->tmp,(int)$3->value);
    		        else if($1->type==1 && $3->type==1)
    				fprintf(icg_output, "%s=%s>%s\n",$$->tmp,$1->tmp,$3->tmp);
    		        else if($1->type==0 && $3->type==2)
    				fprintf(icg_output, "%s=%d>%s\n",$$->tmp,(int)$1->value,$3->ptr->name);
    			else if($1->type==2 && $3->type==0)
    				fprintf(icg_output, "%s=%s>%d\n",$$->tmp,$1->ptr->name,(int)$3->value);
    			else if($1->type==1 && $3->type==2)
    				fprintf(icg_output, "%s=%s>%s\n",$$->tmp,$1->tmp,$3->ptr->name);
    			else if($1->type==2 && $3->type==1)
    				fprintf(icg_output, "%s=%s>%s\n",$$->tmp,$1->ptr->name,$3->tmp);
    			else if($1->type==2 &&$3->type==2)
    				fprintf(icg_output, "%s=%s>%s\n",$$->tmp,$1->ptr->name,$3->ptr->name);
    		     }
    |T_expr T_LE T_expr  {
    			$$=new_node("<",$1,$3);  
    			if($1->value<$3->value) 
    				$$->value=1; 
    			else 
    				$$->value=0;
    			sprintf($$->tmp, "t%d", tempno++);
    			//printf("%d %d\n",$1->type,$3->type);
    			if($1->type==0 && $3->type==0)
    				fprintf(icg_output, "%s=%d<%d\n",$$->tmp,(int)$1->value,(int)$3->value);
    		      	else if($1->type==0 && $3->type==1)
    				fprintf(icg_output, "%s=%d<%s\n",$$->tmp,(int)$1->value,$3->tmp);
    		        else if($1->type==1 && $3->type==0)
    				fprintf(icg_output, "%s=%s<%d\n",$$->tmp,$1->tmp,(int)$3->value);
    		        else if($1->type==1 && $3->type==1)
    				fprintf(icg_output, "%s=%s<%s\n",$$->tmp,$1->tmp,$3->tmp);
    		        else if($1->type==0 && $3->type==2)
    				fprintf(icg_output, "%s=%d<%s\n",$$->tmp,(int)$1->value,$3->ptr->name);
    			else if($1->type==2 && $3->type==0)
    				fprintf(icg_output, "%s=%s<%d\n",$$->tmp,$1->ptr->name,(int)$3->value);
    			else if($1->type==1 && $3->type==2)
    				fprintf(icg_output, "%s=%s<%s\n",$$->tmp,$1->tmp,$3->ptr->name);
    			else if($1->type==2 && $3->type==1)
    				fprintf(icg_output, "%s=%s<%s\n",$$->tmp,$1->ptr->name,$3->tmp);
    			else if($1->type==2 &&$3->type==2)
    				fprintf(icg_output, "%s=%s<%s\n",$$->tmp,$1->ptr->name,$3->ptr->name);
    
    		     }
    |T_expr T_S_EQ T_expr {
    			$$=new_node("==",$1,$3);
    			if($1->value==$3->value) 
    				$$->value=1; 
    			else 
    				$$->value=0;
    			sprintf($$->tmp, "t%d", tempno++);
    			if($1->type==0 && $3->type==0)
    				fprintf(icg_output, "%s=%d==%d\n",$$->tmp,(int)$1->value,(int)$3->value);
    		      	else if($1->type==0 && $3->type==1)
    				fprintf(icg_output, "%s=%d==%s\n",$$->tmp,(int)$1->value,$3->tmp);
    		        else if($1->type==1 && $3->type==0)
    				fprintf(icg_output, "%s=%s==%d\n",$$->tmp,$1->tmp,(int)$3->value);
    		        else if($1->type==1 && $3->type==1)
    				fprintf(icg_output, "%s=%s==%s\n",$$->tmp,$1->tmp,$3->tmp);
    		        else if($1->type==0 && $3->type==2)
    				fprintf(icg_output, "%s=%d==%s\n",$$->tmp,(int)$1->value,$3->ptr->name);
    			else if($1->type==2 && $3->type==0)
    				fprintf(icg_output, "%s=%s==%d\n",$$->tmp,$1->ptr->name,(int)$3->value);
    			else if($1->type==1 && $3->type==2)
    				fprintf(icg_output, "%s=%s==%s\n",$$->tmp,$1->tmp,$3->ptr->name);
    			else if($1->type==2 && $3->type==1)
    				fprintf(icg_output, "%s=%s==%s\n",$$->tmp,$1->ptr->name,$3->tmp);
    			else if($1->type==2 &&$3->type==2)
    				fprintf(icg_output, "%s=%s==%s\n",$$->tmp,$1->ptr->name,$3->ptr->name);
    		    } 
;

var_decl:
    T_INT T_ID T_ASSG T_expr ';' {  
        if($4->type==0)
            fprintf(icg_output, "%s=%d\n",$2,(int)$4->value);    
        else if($4->type==1)                    
            fprintf(icg_output, "%s=%s\n",$2,$4->tmp);
        fill($2,$4->value,0);
        union leafval f;
        strcpy(f.val1,$2);                     
        $$=new_node("EQUALS",leaf(2,f),$4);                
    }
    | T_CHAR T_ID T_ASSG T_CHARV ';' {
        fill_char($2, $4[1], 2); // $4[1] to skip the quotes
        fprintf(icg_output, "%s=%s\n", $2, $4);
        union leafval f;
        strcpy(f.val1, $2);
        $$ = new_node("EQUALS", leaf(2, f), NULL);
    }
;



%%


//------SYMBOL TABLE FUNCTIONS---------------------------------
int update(char*name,float value){
  d_list*node=head;
  while(node!=NULL)
  {
    if(strcmp(name,node->name)==0){
      if(node->type==0)
      	node->value.val=(int)value;
      if(node->type==1)
        node->value.valu=value;
      node->l=yylineno;
      return 1;
      
    }
    node=node->next;

  }
   
  return 0;
  exit(1);

}

int  fill(char* name,float value,int type){
  d_list*node=head;
  while(node!=NULL){
    if(strcmp(name,node->name)==0){
      printf("Variable already declared at line %d\n",yylineno);
      yyerror("");
      return  -1;
      exit(1);
      
    }
    node=node->next;
  }
  node=head;
  d_list* newnode=(d_list*) malloc(sizeof(d_list));
  strcpy(newnode->name,name);
  newnode->type=type;
  newnode->scope=n.s;
  newnode->l=yylineno;
  if(type==0)//Integer
  	newnode->value.val=(int)value;
  if(type==1)//Float
  	newnode->value.valu=value;
  newnode->next=head;
  head=newnode;
  return 1;
}

int  fill_char(char* name,char value,int type){
  d_list*node=head;
  //printf("%d\n",yylineno);
  while(node!=NULL){
    if(strcmp(name,node->name)==0){
      printf("Variable already declared at line %d\n",yylineno);
      yyerror("");
      return  -1;
      exit(1);
      
    }
    node=node->next;
  }
  node=head;
  d_list* newnode=(d_list*) malloc(sizeof(d_list));
  strcpy(newnode->name,name);
  newnode->type=type;
  newnode->scope=n.s;
  newnode->l=yylineno;
  if(type==2)//Integer
  {
  	newnode->value.vale=value;
  	//printf("%c\n",newnode->value.vale);
  }
  else{
	printf("Error\n");
	yyerror("");
	return -1;
	exit(1);
  }
  newnode->next=head;
  head=newnode;
  return 1;
}

void display(){
  d_list* node;
  node=head;

	FILE *symtab_file = fopen("outputs/sym_tab_output.txt", "w");
	if (symtab_file == NULL) {
		perror("Error opening symtaboutput.txt");
		return;
	}

	fprintf(symtab_file, "\n Phase 3 : Semantic Analysis - output (Symbol Table)\n=====================================================\n\n");

  fprintf(symtab_file, "\nLINE NUMBER  VARIABLE NAME \t   TYPE \t VALUE \t SCOPE\n");  
  while(node!=NULL)
  {
    if(node->type==0)
    fprintf(symtab_file, "%d            %s           \t   %s \t\t  %d \t %d\n",node->l,node->name,"int",node->value.val,node->scope);
    //printf("var-name\t%s\tvalue\t%d\tint\tline %d\n",node->name,node->value.val,node->l);
    if(node->type==1)
    fprintf(symtab_file, "%d            %s           \t   %s \t  %0.2f \t %d\n",node->l,node->name,"float",node->value.valu,node->scope);
    if(node->type==2)
    fprintf(symtab_file, "%d            %s           \t   %s \t  %c \t %d\n",node->l,node->name,"char",node->value.vale,node->scope);
    node=node->next;
  }

    fclose(symtab_file);
  
}

d_list* lookupsymb(char *id){
  d_list* node;
  node=head;
  if(head==NULL){
    printf("Variable Not declared at line %d\n",yylineno);
    yyerror("");
    return NULL;
    exit(1);

  }
  while(node!=NULL){
    if(strcmp(id,node->name)==0){
      //return node->value.val;
      return node;
    }
    node=node->next;
  }
  if(node==NULL){
    printf("Variable Not declared at line %d\n",yylineno);
    yyerror("");
    return NULL;
    exit(1);
  }  
}

//--------------AST FUNCTIONS-------------------------------

node* initialize_node() {
    node* tmp = (node*)malloc(sizeof(node));
    if (tmp == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    tmp->left = tmp->right = NULL;
    tmp->type = -1;
    tmp->value = 0;
    tmp->tmp = (char*)malloc(sizeof(char)*30);
    tmp->token = (char*)malloc(sizeof(char)*30);
    tmp->name = (char*)malloc(sizeof(char)*30);
    if (tmp->tmp == NULL || tmp->token == NULL || tmp->name == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    tmp->ptr = NULL;
    return tmp;
}

node* leaf(int type, union leafval f) {
    node* tmp = initialize_node();
    
    switch(type) {
        case 0:  // Constant value
            tmp->type = 0;
            tmp->value = f.val2;
            sprintf(tmp->token, "%.2f", f.val2);
            break;
            
        case 2:  // Variable
            tmp->type = 2;
            tmp->ptr = lookupsymb(f.val1);
            if (tmp->ptr != NULL) {
                strcpy(tmp->name, f.val1);
                tmp->value = tmp->ptr->value.val;
            }
            break;
    }
    return tmp;
}

node* new_node(char* token, node* left, node* right) {
    node* tmp = initialize_node();
    tmp->type = 1;  // Interior node
    strcpy(tmp->token, token);
    tmp->left = left;
    tmp->right = right;
    
    // Handle operation-specific logic
    if (strcmp(token, "EQUALS") == 0) {
        if (left->type == 2) {  // Variable assignment
            strcpy(tmp->name, left->name);
        }
    }
    return tmp;
}

void preorder(node* root, int indent, FILE* syn_tree_file) {
    if (root == NULL) return;

    fprintf(syn_tree_file, "\n");
    for (int i = 0; i < indent; i++) {
        fprintf(syn_tree_file, "  ");
    }

    switch(root->type) {
        case 0:  
            fprintf(syn_tree_file, "├── Value: %.2f", root->value);
            break;
            
        case 1:  
            fprintf(syn_tree_file, "├── Operation: %s", root->token);
            break;
            
        case 2:  
            fprintf(syn_tree_file, "├── Variable: %s", root->name);
            if (root->ptr) {
                fprintf(syn_tree_file, " (Value: ");
                if (root->ptr->type == 0) {
                    fprintf(syn_tree_file, "%d)", root->ptr->value.val);
                } else if (root->ptr->type == 1) {
                    fprintf(syn_tree_file, "%.2f)", root->ptr->value.valu);
                } else if (root->ptr->type == 2) {
                    fprintf(syn_tree_file, "%c)", root->ptr->value.vale);
                }
                fprintf(syn_tree_file, ")");
            }
            break;
            
        case 3:  
            fprintf(syn_tree_file, "├── Temp: %s", root->tmp);
            break;
    }
	
	if (root->left) preorder(root->left, indent + 1, syn_tree_file);
    if (root->right) preorder(root->right, indent + 1, syn_tree_file);
}



//------------OTHER FUNCTIONS-------------------------------
void yyerror(char *s) {
    fprintf(stderr, "%s", s);
}

int main(void) {
    printf("start\n");
    yyin = fopen("inputs/input1.txt", "r");
    if (!yyin) {
        perror("Error opening input file");
        return 1;
    }

    icg_output = fopen("outputs/icg_output.txt", "w");
    if (icg_output == NULL) {
        perror("Error opening icgoutput.txt");
        fclose(yyin);
        return 1;
    }

    fprintf(icg_output, "\n Phase 4 : ICG - output (Intermediate Code)\n=============================================\n\n");

    int parse_result = yyparse();
    
    fclose(yyin);
    fclose(icg_output);
    
    return parse_result;
}

void cleanup_ast(node* root) {
    if (root == NULL) return;
    
    cleanup_ast(root->left);
    cleanup_ast(root->right);
    
    free(root->tmp);
    free(root->token);
    free(root->name);
    free(root);
}
