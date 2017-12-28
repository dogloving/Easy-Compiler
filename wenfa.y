%{
/****************************************************************************
myparser.y
ParserWizard generated YACC file.
Date: 2017-11-18
****************************************************************************/

#include <iostream>
#include <stdlib.h>
#include <string>
#include <map>
#include <math.h>
#include <set>
#include <string>
#include "mytree.h"
#include "IRTree.h"
using namespace std;
int yylex(void);
void yyerror(const char * p) {}
int countOfLines = 0;
vector<string> errors;
vector<string> values;
set<string> symbols;
vector<vector<string>> all;
map<string, string> symbol_type;
struct treenode* rec;
// void show();
void pass_symbol_table(map<string, string>);
IRTree* backtrace(treenode* node);
void checkSymbol(struct treenode* node, int hehe, string tp) {
	// 关于这个hehe，－１表示他是赋值号右边，１表示赋值号左边
	if (node == NULL) return;
	values.push_back(node->Value);
	all.push_back({node->Idtype, node->Value});
	if (node->Idtype == "Deflist") {
		// 需要考虑兄弟节点
		for (int index = node->sibling.size() - 1; index >= 0; --index) {
			checkSymbol(node->sibling[index], hehe, tp);
		}
		if (node->Value == "Var=Expr" || node->Value == "Expr_assign") {
			checkSymbol(node->left, 1, tp);
			checkSymbol(node->right, -1, tp);
		} else {
			checkSymbol(node->left, hehe, tp);
		}
	} else if (node->Idtype == "Var") {
		// 需要考虑兄弟节点
		for (int index = node->sibling.size() - 1; index >= 0; --index) {
			checkSymbol(node->sibling[index], hehe, tp);
		}
		string var_name = node->Value;
		if (hehe == 1) {
			// 左边的话需要检查symbol_type中是否存在，存在的话说明重复定义
			if (symbol_type.find(var_name) != symbol_type.end()) {
				// 这里应该报错，因为重定义了
				string msg = var_name + " is defined repeatly";
				errors.push_back(msg);
			} else {
				symbol_type[var_name] = tp;
			}
		} else if (hehe == -1) {
			// 右边的话需要检查symbol_type中是否存在，存在说明该变量已经声明过，可以使用(可能还需要初始化)
			if (symbol_type.find(var_name) != symbol_type.end()) {
				// 正确
			} else {
				// 这里应该报错，因为使用了未定义或是未声明的变量
				string msg = var_name + " is not defined";
				errors.push_back(msg);
			}
		}
	}
}
void symbolHelper(string tp) {
	// 因为函数checkSymbol总是会将最后一个变量漏掉，所以这个地方我要把漏掉的变量加上
	for (string val_name: symbols) {
		if (symbol_type.find(val_name) == symbol_type.end()) {
			symbol_type[val_name] = tp;
		}
	}
}
void checkTree(struct treenode* node) {
	if(node == NULL) return;
	for (struct treenode* sb: node->sibling){
		checkTree(sb);
	}
	if (node->Idtype == "Var") {
		if (symbol_type.find(node->Value) == symbol_type.end()){
			// 报错
			cout<< (string(node->Value) + " is not defined")<<endl;
			return;
		}
	}
	checkTree(node->left);
	checkTree(node->right);
	checkTree(node->temp1);
	checkTree(node->temp2);
}
// attribute type
#pragma warning (disable : 4996)
%}

/////////////////////////////////////////////////////////////////////////////
// declarations section

// parser name

%union{
	char* str;
	struct treenode* root;
	double d;
	char c;
	int i;
	float f;
}


// place any declarations here
%token <str> ID
%token <str> INTEGER_VALUE
%token <str> FLOAT_VALUE
%token <str> CHAR_VALUE
%token <str> DOUBLE_VALUE
%token <str> COMMENT COMMENTS
%token INT FLOAT VOID DOUBLE CHAR FOR MAIN READ WRITE RETURN IF ELSE WHILE WHITESPACE SQM COMMA ASSIGN EG EL EQ GT LT PLUS MINUS MUL DIV AND OR NOT LP RP LC RC MOD BITAND BITOR EN DPLUS DMINUS BITXOR
%type <root> Program Mtype Comp_stmt Stmts Stmt Def Type Deflist Var Expr While 
Bool Read Write For For_list For_Expr1 For_Expr2 For_Expr3 If Expr_left Varlist COMMEN

%left COMMA
%right ASSIGN // =
%left OR	  // ||
%left AND     // &&
%left BITOR 
%left BITXOR
%left BITAND  // &
%left EQ EN   // == !=
%left LT GT EG EL   // < > <= >=
%left BITLEFT BITRIGHT // << >>
%left PLUS MINUS    // + -
%left MUL DIV MOD// * / %
%nonassoc NOT DPLUS DMINUS NSIGN PSIGN//! ++a --a negative_sign positive_sign
%nonassoc BDPLUS BDMINUS//a++ a-- 

%%
/////////////////////////////////////////////////////////////////////////////
// rules section
// place your YACC rules here (must be at least one)
//Try:PLUS{printf("try");}
Program:Mtype MAIN LP RP Comp_stmt{
	cout<<"=========>Print our tree now"<<endl;
	$$ = node($1,$5,"Program","NULL",NULL);
	if (errors.size() == 0)	eval($$,0);
	cout<<"<-----------------------Finish---------------------------->"<<endl;
	cout << symbol_type.size() << endl;
	for (pair<string, string> pair: symbol_type) {
		cout << pair.first << "\t--\t" << pair.second << endl;
	}
	cout << "node errors is " << endl;
	for (string error: errors) cout << error << " " << endl;
	eval(rec, 1);

	cout << "-----------------------------------------------------------------------------------" << endl;
	pass_symbol_table(symbol_type);
	backtrace($$);
	}
    ;
Mtype:INT{$$ = node("Mtype","int",NULL);}
    |VOID{$$ = node("Mtype","void",NULL);}
	|{$$ = node("Mtype","NULL",NULL);}
	;
Comp_stmt:LC Stmts RC{$$ = node($2,"Comp_stmt","NULL",NULL);}
         ;
Stmts:Stmt Stmts{/*$$ = node($1,$2,"Stmts","Stmts",NULL);*/
		($2->sibling).push_back($1);
		$$ = $2;
	 }
     |Stmt{$$ = $1;}
	 ;
Stmt:Def{$$ = node($1,"Stmt","Def",NULL);}
    |If{$$ = node($1,"Stmt","If",NULL);}
	|While{$$ = node($1,"Stmt","While",NULL);}
	|Read{$$ = node($1,"Stmt","Read",NULL);}
	|Write{$$ = node($1,"Stmt","Write",NULL);}
	|Expr SQM{
		checkTree($1);
	$$ = node($1,"Stmt","Expr;",NULL);}
	|SQM{$$ = node("Stmt",";",NULL);}
	|Comp_stmt{$$ = node($1,"Stmt","Comp_stmt",NULL);}
	|For{$$ = node($1,"Stmt","For",NULL);}
	|Stmt COMMEN{$$ = $1;}
	|COMMEN Stmt{$$ = $2;}
	|RETURN INTEGER_VALUE{$$ = node("Stmt", "Return", NULL);}
	;
COMMEN:COMMENT{$$ = node(NULL,NULL,NULL);}
      |COMMENTS{$$ = node(NULL,NULL,NULL);}
	  |COMMENT COMMEN{$$ =$2;}
	  |COMMENTS COMMEN{$$ = $2;}
	  ;
Def:Type Deflist SQM{
	$$ = node($1, $2, "Def", "NULL", NULL);
	/* 符号表检查 */
	checkSymbol($2, 1, $1->Value);
	}
   ;
Type:INT{$$ = node("Type","int",NULL);}
    |VOID{$$ = node("Type","void",NULL);}
	|CHAR{$$ = node("Type","char",NULL);}
	|FLOAT{$$ = node("Type","float",NULL);}
	|DOUBLE{$$ = node("Type","double",NULL);}
	;
Deflist:Expr_left{$$ = $1;}
       |Expr_left ASSIGN Expr{$$ = node($1,$3,"Deflist","Expr_assign",NULL);}
	   |Expr_left COMMA Deflist{/*$$ = node($1,$3,"Deflist","Var,...",NULL);*/
	   		$3->sibling.push_back($1);
			$$ = $3;
	   }
	   |Expr_left ASSIGN Expr COMMA Deflist{/*$$ = node($1,$3,$5,"Deflist","Var=Expr,...",NULL);*/
	   struct  treenode* temp = node($1,$3,"Deflist","Expr_assign",NULL);
	   $5->sibling.push_back(temp);
	   $$ = $5;
	   }
	   ;
Var:ID{
	$$ = node("Var",$1,"NULL");
	symbols.insert($1);
	}
   ;
Expr_left:Var{$$ = $1;$$->Illus="Expr_left";}
         |LP Var RP{$$ = $2;$$->Illus="Expr_left";}
		 |LP Varlist RP{$$ = $2;$$->Illus="Expr_left";}
		 ;
Varlist:Var{$$ = $1;}
       |Var COMMA Varlist{$$ = $3;}
	   ;
Expr:Expr PLUS Expr{
	if(!($1->Idtype=="Expr")&&!($3->Idtype=="Expr")){
			if(!(IsVal($1)&&IsVal($3))){
				if($1->Idtype=="Var") 
					if(symbol_type.count($1->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
				if($3->Idtype=="Var") 
					if(symbol_type.count($3->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
				$$ = node($1,$3,"Expr","Add",NULL);
			}
			else{	
				int temp1,temp2=0;
				double temp3,temp4=0;
				char c[20]="";
				if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
				if($1->Illus=="float"||$1->Illus=="double") temp3=atof($1->val);
				if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
				if($3->Illus=="float"||$3->Illus=="double") temp4=atof($3->val);
				if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp1+temp2,c,10);$$ = node(c,"Val",c,"int");}
				if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="float"||$3->Illus=="double")) {sprintf(c,"%f",temp1+temp4);$$ = node(c,"Val",c,"double");}
				if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="int"||$3->Illus=="char")) {sprintf(c,"%f",temp3+temp2);$$ = node(c,"Val",c,"double");}
				if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="float"||$3->Illus=="double")) {sprintf(c,"%f",temp3+temp4);$$ = node(c,"Val",c,"double");}
			}
		}
	else{
		$$ = node($1,$3,"Expr","Add",NULL);
	}
	}
	|Expr MINUS Expr{
	if(!(IsVal($1)&&IsVal($3))){
			if($1->Idtype=="Var") 
				if(symbol_type.count($1->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->Idtype=="Var") 
				if(symbol_type.count($3->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"Expr","MINUS",NULL);
			}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") temp3=atof($1->val);
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") temp4=atof($3->val);
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp1-temp2,c,10);$$ = node(c,"Val",c,"int");}
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="float"||$3->Illus=="double")) {sprintf(c,"%f",temp1-temp4);$$ = node(c,"Val",c,"double");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="int"||$3->Illus=="char")) {sprintf(c,"%f",temp3-temp2);$$ = node(c,"Val",c,"double");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="float"||$3->Illus=="double")) {sprintf(c,"%f",temp3-temp4);$$ = node(c,"Val",c,"double");}
			
			// int t1 = atoi($1->Value), t2=atoi($3->Value);
			// char c[20]="";
			// sprintf(c,"%d",t1-t2);
			// $$ = node(c,"Val",c,"int");
			}
	}
	|Expr MUL Expr{
	if(!(IsVal($1)&&IsVal($3))){
			if($1->Idtype=="Var") 
				if(symbol_type.count($1->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->Idtype=="Var") 
				if(symbol_type.count($3->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"Expr","Mul",NULL);
			}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") temp3=atof($1->val);
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") temp4=atof($3->val);
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp1*temp2,c,10);$$ = node(c,"Val",c,"int");}
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="float"||$3->Illus=="double")) {sprintf(c,"%f",temp1*temp4);$$ = node(c,"Val",c,"double");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="int"||$3->Illus=="char")) {sprintf(c,"%f",temp3*temp2);$$ = node(c,"Val",c,"double");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="float"||$3->Illus=="double")) {sprintf(c,"%f",temp3*temp4);$$ = node(c,"Val",c,"double");}
		}
	}
	|Expr DIV Expr{
	if(!(IsVal($1)&&IsVal($3))){
			if($1->Idtype=="Var") 
				if(symbol_type.count($1->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->Idtype=="Var") 
				if(symbol_type.count($3->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"Expr","Div",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") temp3=atof($1->val);
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") temp4=atof($3->val);
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp1/temp2,c,10);$$ = node(c,"Val",c,"int");}
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="float"||$3->Illus=="double")) {sprintf(c,"%f",temp1/temp4);$$ = node(c,"Val",c,"double");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="int"||$3->Illus=="char")) {sprintf(c,"%f",temp3/temp2);$$ = node(c,"Val",c,"double");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="float"||$3->Illus=="double")) {sprintf(c,"%f",temp3/temp4);$$ = node(c,"Val",c,"double");}
		}
	}
	|Expr BITOR Expr{
		if(($1->Idtype=="Expr"&&$3->Idtype=="Expr")) {
			$$ = node($1, $3, "Expr", "Bit_or", "");
		}
		else if(($1->Idtype=="Var"&&$3->Idtype=="Expr")) {
			$$ = node($1, $3, "Expr", "Bit_or", "");
		}
		else if(($1->Idtype=="Expr"&&$3->Idtype=="Var")) {
			$$ = node($1, $3, "Expr", "Bit_or", "");
		}
		else if(($1->Idtype=="Val"&&$3->Idtype=="Expr")) {
			$$ = node($1, $3, "Expr", "Bit_or", "");
		}
		else if(($1->Idtype=="Expr"&&$3->Idtype=="Val")) {
			$$ = node($1, $3, "Expr", "Bit_or", "");
		}



	else if(($1->Idtype=="Var")&&($3->Idtype=="Var")){
		cout << "aaa" <<$1->Value<<" " << $3->Value <<endl;
		if(!((symbol_type.count($1->Value)>0)&&(symbol_type.count($3->Value)>0)))
		 {cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$1->Value]=="int")||(symbol_type[$1->Value]=="char"))&&((symbol_type[$3->Value]=="int")||(symbol_type[$3->Value]=="char")))
		 {$$ = node($1,$3,"Expr","Bit_or",NULL);}
		else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
	}
	else if($1->Idtype=="Var"&&$3->Idtype=="Val"){
		if(!(symbol_type.count($1->Value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$1->Value]=="int")||(symbol_type[$1->Value]=="char"))&&(($3->Illus=="int")||($3->Illus=="char"))) {$$ = node($1,$3,"Expr","Bit_or",NULL);}
		else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
	}
	else if($3->Idtype=="Var"&&$1->Idtype=="Val"){
		if(!(symbol_type.count($3->Value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$3->Value]=="int")||(symbol_type[$3->Value]=="char"))&&(($1->Illus=="int")||($1->Illus=="char"))) {$$ = node($1,$3,"Expr","Bit_or",NULL);}
		else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
	}
	else{	
			int temp1,temp2=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") printf("%s","type error");
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") printf("%s","type error");
			itoa(temp1|temp2,c,10); 
			$$ = node(c,"Val",c,"int");
		}
	}
	|Expr BITXOR Expr{
		if(($1->Idtype=="Expr"&&$3->Idtype=="Expr")) {
			$$ = node($1, $3, "Expr", "Bit_xor", "");
		}
		else if(($1->Idtype=="Var"&&$3->Idtype=="Expr")) {
			$$ = node($1, $3, "Expr", "Bit_xor", "");
		}
		else if(($1->Idtype=="Expr"&&$3->Idtype=="Var")) {
			$$ = node($1, $3, "Expr", "Bit_xor", "");
		}
		else if(($1->Idtype=="Val"&&$3->Idtype=="Expr")) {
			$$ = node($1, $3, "Expr", "Bit_xor", "");
		}
		else if(($1->Idtype=="Expr"&&$3->Idtype=="Val")) {
			$$ = node($1, $3, "Expr", "Bit_xor", "");
		}


	else if(($1->Idtype=="Var")&&($3->Idtype=="Var")){
		if(!((symbol_type.count($1->Value)>0)&&(symbol_type.count($3->Value)>0))) {cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$1->Value]=="int")||(symbol_type[$1->Value]=="char"))&&((symbol_type[$3->Value]=="int")||(symbol_type[$3->Value]=="char"))) {$$ = node($1,$3,"Expr","Bit_xor",NULL);}
		else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
	}
	else if($1->Idtype=="Var"&&$3->Idtype=="Val"){
		if(!(symbol_type.count($1->Value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$1->Value]=="int")||(symbol_type[$1->Value]=="char"))&&(($3->Illus=="int")||($3->Illus=="char"))) {$$ = node($1,$3,"Expr","Bit_xor",NULL);}
		else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
	}
	else if($3->Idtype=="Var"&&$1->Idtype=="Val"){
		if(!(symbol_type.count($3->Value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$3->Value]=="int")||(symbol_type[$3->Value]=="char"))&&(($1->Illus=="int")||($1->Illus=="char"))) {$$ = node($1,$3,"Expr","Bit_xor",NULL);}
		else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
	}
	else{	
			int temp1,temp2=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") printf("%s","type error");
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") printf("%s","type error");
			itoa(temp1^temp2,c,10);
			$$ = node(c,"Val",c,"int");
		}
	}
	|Expr BITAND Expr{
		if(($1->Idtype=="Expr"&&$3->Idtype=="Expr")) {
			$$ = node($1, $3, "Expr", "Bit_and", "");
		}
		else if(($1->Idtype=="Var"&&$3->Idtype=="Expr")) {
			$$ = node($1, $3, "Expr", "Bit_and", "");
		}
		else if(($1->Idtype=="Expr"&&$3->Idtype=="Var")) {
			$$ = node($1, $3, "Expr", "Bit_and", "");
		}
		else if(($1->Idtype=="Val"&&$3->Idtype=="Expr")) {
			$$ = node($1, $3, "Expr", "Bit_and", "");
		}
		else if(($1->Idtype=="Expr"&&$3->Idtype=="Val")) {
			$$ = node($1, $3, "Expr", "Bit_and", "");
		}
	else if(($1->Idtype=="Var")&&($3->Idtype=="Var")){
		if(!((symbol_type.count($1->Value)>0)&&(symbol_type.count($3->Value)>0))) {cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$1->Value]=="int")||(symbol_type[$1->Value]=="char"))&&((symbol_type[$3->Value]=="int")||(symbol_type[$3->Value]=="char"))) {$$ = node($1,$3,"Expr","Bit_and",NULL);}
		else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
	}
	else if($1->Idtype=="Var"&&$3->Idtype=="Val"){
		if(!(symbol_type.count($1->Value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$1->Value]=="int")||(symbol_type[$1->Value]=="char"))&&(($3->Illus=="int")||($3->Illus=="char"))) {$$ = node($1,$3,"Expr","Bit_and",NULL);}
		else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
	}
	else if($3->Idtype=="Var"&&$1->Idtype=="Val"){
		if(!(symbol_type.count($3->Value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
		else if(((symbol_type[$3->Value]=="int")||(symbol_type[$3->Value]=="char"))&&(($1->Illus=="int")||($1->Illus=="char"))) {$$ = node($1,$3,"Expr","Bit_and",NULL);}
		else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
	}
	else{
			int temp1,temp2=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") printf("%s","type error");
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") printf("%s","type error");
			itoa(temp1&temp2,c,10);
			$$ = node(c,"Val",c,"int");
		}
	}
	|Expr MOD Expr{
		if(($1->Idtype=="Var")&&($3->Idtype=="Var")){
			if(!((symbol_type.count($1->Value)>0)&&(symbol_type.count($3->Value)>0))) {cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$1->Value]=="int")||(symbol_type[$1->Value]=="char"))&&((symbol_type[$3->Value]=="int")||(symbol_type[$3->Value]=="char"))) {$$ = node($1,$3,"Expr","Mod",NULL);}
			else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
		}
		else if($1->Idtype=="Var"&&$3->Idtype=="Val"){
			if(!(symbol_type.count($1->Value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$1->Value]=="int")||(symbol_type[$1->Value]=="char"))&&(($3->Illus=="int")||($3->Illus=="char"))) {$$ = node($1,$3,"Expr","Mod",NULL);}
			else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
		}
		else if($3->Idtype=="Var"&&$1->Idtype=="Val"){
			if(!(symbol_type.count($3->Value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$3->Value]=="int")||(symbol_type[$3->Value]=="char"))&&(($1->Illus=="int")||($1->Illus=="char"))) {$$ = node($1,$3,"Expr","Mod",NULL);}
			else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
		}
		else{
			int temp1,temp2=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") printf("%s","type error");
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") printf("%s","type error");
			itoa(temp1%temp2,c,10);
			$$ = node(c,"Val",c,"int");
		}
	}
	|Expr BITRIGHT Expr{
		if(($1->Idtype=="Var")&&($3->Idtype=="Var")){
			if(!((symbol_type.count($1->Value)>0)&&(symbol_type.count($3->Value)>0))) {cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$1->Value]=="int")||(symbol_type[$1->Value]=="char"))&&((symbol_type[$3->Value]=="int")||(symbol_type[$3->Value]=="char"))) {$$ = node($1,$3,"Expr","Bit_right",NULL);}
			else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
		}
		else if($1->Idtype=="Var"&&$3->Idtype=="Val"){
			if(!(symbol_type.count($1->Value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$1->Value]=="int")||(symbol_type[$1->Value]=="char"))&&(($3->Illus=="int")||($3->Illus=="char"))) {$$ = node($1,$3,"Expr","Bit_right",NULL);}
			else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
		}
		else if($3->Idtype=="Var"&&$1->Idtype=="Val"){
			if(!(symbol_type.count($3->Value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$3->Value]=="int")||(symbol_type[$3->Value]=="char"))&&(($1->Illus=="int")||($1->Illus=="char"))) {$$ = node($1,$3,"Expr","Bit_right",NULL);}
			else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
		}
		else{
			int temp1,temp2=0;
			char c[20]="";
			if($1->Illus=="float"||$1->Illus=="double"||$3->Illus=="float"||$3->Illus=="double") printf("type error");
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			itoa(temp1>>temp2,c,10); 
			$$ = node(c,"Val",c,"int");

		}
	}
	|Expr BITLEFT Expr{
		if(($1->Idtype=="Var")&&($3->Idtype=="Var")){
			if(!((symbol_type.count($1->Value)>0)&&(symbol_type.count($3->Value)>0))) {cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$1->Value]=="int")||(symbol_type[$1->Value]=="char"))&&((symbol_type[$3->Value]=="int")||(symbol_type[$3->Value]=="char"))) {$$ = node($1,$3,"Expr","Bit_left",NULL);}
			else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
		}
		else if($1->Idtype=="Var"&&$3->Idtype=="Val"){
			if(!(symbol_type.count($1->Value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$1->Value]=="int")||(symbol_type[$1->Value]=="char"))&&(($3->Illus=="int")||($3->Illus=="char"))) {$$ = node($1,$3,"Expr","Bit_left",NULL);}
			else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
		}
		else if($3->Idtype=="Var"&&$1->Idtype=="Val"){
			if(!(symbol_type.count($3->Value)>0)){cout<<"error:use the ID without definition"<<endl;return 0;}
			else if(((symbol_type[$3->Value]=="int")||(symbol_type[$3->Value]=="char"))&&(($1->Illus=="int")||($1->Illus=="char"))) {$$ = node($1,$3,"Expr","Bit_left",NULL);}
			else {cout<<"error:use the Expr with wrong number"<<endl;return 0;}
		}
		else{
		    int temp1,temp2=0;
		    char c[20]="";
			if($1->Illus=="float"||$1->Illus=="double"||$3->Illus=="float"||$3->Illus=="double") {printf("type error\n");return 0;}
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			itoa(temp1<<temp2,c,10);
			$$ = node(c,"Val",c,"int");
		}
	}
	|Expr EG Expr{
	if(!(IsVal($1)&&IsVal($3))){
			if($1->Idtype=="Var") 
				if(symbol_type.count($1->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->Idtype=="Var") 
				if(symbol_type.count($3->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"Expr","Cmp_EG",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") temp3=atof($1->val);
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") temp4=atof($3->val);
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="int"||$3->Illus=="char")){itoa(temp1>=temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="float"||$3->Illus=="double")){itoa(temp1>=temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp3>=temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="float"||$3->Illus=="double")){itoa(temp3>=temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|Expr EL Expr{
	if(!(IsVal($1)&&IsVal($3))){
			if($1->Idtype=="Var") 
				if(symbol_type.count($1->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->Idtype=="Var") 
				if(symbol_type.count($3->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"Expr","Cmp_EL",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") temp3=atof($1->val);
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") temp4=atof($3->val);
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="int"||$3->Illus=="char")){itoa(temp1<=temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="float"||$3->Illus=="double")){itoa(temp1<=temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp3<=temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="float"||$3->Illus=="double")){itoa(temp3<=temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|Expr EQ Expr{
	if(!(IsVal($1)&&IsVal($3))){
			if($1->Idtype=="Var") 
				if(symbol_type.count($1->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->Idtype=="Var") 
				if(symbol_type.count($3->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"Expr","Cmp_EQ",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") temp3=atof($1->val);
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") temp4=atof($3->val);
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp1==temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="float"||$3->Illus=="double")){itoa(temp1==temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp3==temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="float"||$3->Illus=="double")) {itoa(temp3==temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|Expr EN Expr{
		if(!(IsVal($1)&&IsVal($3))){
			if($1->Idtype=="Var") 
				if(symbol_type.count($1->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->Idtype=="Var") 
				if(symbol_type.count($3->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"Expr","Cmp_EN",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") temp3=atof($1->val);
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") temp4=atof($3->val);
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp1!=temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="float"||$3->Illus=="double")){itoa(temp1!=temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp3!=temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="float"||$3->Illus=="double")) {itoa(temp3!=temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|Expr GT Expr{
	if(!(IsVal($1)&&IsVal($3))){
			if($1->Idtype=="Var") 
				if(symbol_type.count($1->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->Idtype=="Var") 
				if(symbol_type.count($3->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"Expr","Cmp_GT",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") temp3=atof($1->val);
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") temp4=atof($3->val);
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp1>temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="float"||$3->Illus=="double")) {itoa(temp1>temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp3>temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="float"||$3->Illus=="double")){itoa(temp3>temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|Expr LT Expr{
	if(!(IsVal($1)&&IsVal($3))){
			if($1->Idtype=="Var") 
				if(symbol_type.count($1->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->Idtype=="Var") 
				if(symbol_type.count($3->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"Expr","Cmp_LT",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") temp3=atof($1->val);
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") temp4=atof($3->val);
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp1<temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="float"||$3->Illus=="double")) {itoa(temp1<temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp3<temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="float"||$3->Illus=="double")) {itoa(temp3<temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|Expr AND Expr{
	if(!(IsVal($1)&&IsVal($3))){
			if($1->Idtype=="Var") 
				if(symbol_type.count($1->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->Idtype=="Var") 
				if(symbol_type.count($3->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"Expr","Cmp_and",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") temp3=atof($1->val);
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") temp4=atof($3->val);
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp1&&temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="float"||$3->Illus=="double")) {itoa(temp1&&temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp3&&temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="float"||$3->Illus=="double")) {itoa(temp3&&temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}
	|Expr OR Expr{
	if(!(IsVal($1)&&IsVal($3))){
			if($1->Idtype=="Var") 
				if(symbol_type.count($1->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			if($3->Idtype=="Var") 
				if(symbol_type.count($3->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($1,$3,"Expr","Cmp_OR",NULL);
		}
	else{	
			int temp1,temp2=0;
			double temp3,temp4=0;
			char c[20]="";
			if($1->Illus=="int"||$1->Illus=="char") temp1=atoi($1->val);
			if($1->Illus=="float"||$1->Illus=="double") temp3=atof($1->val);
			if($3->Illus=="int"||$3->Illus=="char") temp2=atoi($3->val);
			if($3->Illus=="float"||$3->Illus=="double") temp4=atof($3->val);
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="int"||$3->Illus=="char")){itoa(temp1||temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="int"||$1->Illus=="char")&&($3->Illus=="float"||$3->Illus=="double")){itoa(temp1||temp4,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="int"||$3->Illus=="char")) {itoa(temp3||temp2,c,10); $$ = node(c,"Val",c,"int");}
			if(($1->Illus=="float"||$1->Illus=="double")&&($3->Illus=="float"||$3->Illus=="double")){itoa(temp3||temp4,c,10); $$ = node(c,"Val",c,"int");}
		}
	}

	|Expr ASSIGN Expr{
	if($1->Idtype=="Var"){
			$$ = node($1,$3,"Expr","Assign",NULL);
		}
	else if($1->Value=="(Expr)"){
		if(($1->left)->Idtype=="Var") {
				$$ = node($1,$3,"Expr","Assign",NULL);
		}
		else if(($1->left)->Value=="++front") $$ = node($1,$3,"Expr","Assign",NULL);
		else if(($1->left)->Value=="--front") $$ = node($1,$3,"Expr","Assign",NULL);
		else{cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
	}
	else if($1->Value=="++front") $$ = node($1,$3,"Expr","Assign",NULL);
	else if($1->Value=="--front") $$ = node($1,$3,"Expr","Assign",NULL);
	else if($1->Value=="back++"||$1->Value=="back--"){cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
	// else{cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
	if(IsVal($1)){
			cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;
		}
	else{
			$$ = node($1,$3,"Expr","Assign",NULL);
		}
	}
	|NOT Expr{
	if(!IsVal($2)){
			if($2->Idtype=="Var") 
				if(symbol_type.count($2->Value)==0) {cout<<"error:use the ID without definition"<<endl;return 0;}
			$$ = node($2,"Expr","Not","NULL");
		}
	else{
			int temp1=0;
			double temp3=0;
			char c[20]="";
			if($2->Illus=="int"||$2->Illus=="char") {temp1=atoi($2->val);itoa(!temp1,c,10);$$ = node(c,"Val",c,"int");}
			if($2->Illus=="float"||$2->Illus=="double") {temp3=atof($2->val);itoa(!temp3,c,10);$$ = node(c,"Val",c,"int");}
		}
	}
	|DPLUS Expr{
	if(!IsVal($2)){
			if($2->Idtype=="Var") $$ = node($2,"Expr","++front",NULL);
			else if($2->Value=="++front") $$ = node($2,"Expr","++front",NULL);
			else if($2->Value=="--front") $$ = node($2,"Expr","++front",NULL);
			else if($2->Value=="(Expr)"){
				if(($2->left)->Idtype=="Var") {$$ = node($2,"Expr","++front",NULL);}
				else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
			}
			else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
		}
	else{
			int temp1=0;
			char temp2=0;
			double temp3=0;
			float temp4=0;
			char c[20]="";
			if($2->Illus=="int") {temp1=atoi($2->val);itoa(++temp1,c,10);$$ = node(c,"Val",c,"int");}
			if($2->Illus=="char") {temp2=atoi($2->val);itoa(++temp2,c,10);$$ = node(c,"Val",c,"char");}
			if($2->Illus=="double") {temp3=atof($2->val);sprintf(c,"%f",++temp3);$$ = node(c,"Val",c,"double");}
			if($2->Illus=="float") {temp4=atof($2->val);sprintf(c,"%f",++temp4);$$ = node(c,"Val",c,"float");}
		}
	}
	|DMINUS Expr{
	if(!IsVal($2)){
			if($2->Idtype=="Var") $$ = node($2,"Expr","--front",NULL);
			else if($2->Value=="++front") $$ = node($2,"Expr","--front",NULL);
			else if($2->Value=="--front") $$ = node($2,"Expr","--front",NULL);
			else if($2->Value=="(Expr)"){
				if(($2->left)->Idtype=="Var") {
					$$ = node($2,"Expr","--front",NULL);
					}
					else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
					}
			else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
		}

	else{
			int temp1=0;
			char temp2=0;
			double temp3=0;
			float temp4=0;
			char c[20]="";
			if($2->Illus=="int") {temp1=atoi($2->val);itoa(--temp1,c,10);$$ = node(c,"Val",c,"int");}
			if($2->Illus=="char") {temp2=atoi($2->val);itoa(--temp2,c,10);$$ = node(c,"Val",c,"char");}
			if($2->Illus=="double") {temp3=atof($2->val);sprintf(c,"%f",--temp3);$$ = node(c,"Val",c,"double");}
			if($2->Illus=="float") {temp4=atof($2->val);sprintf(c,"%f",--temp4);$$ = node(c,"Val",c,"float");}
		}
	}
	|Expr DPLUS %prec BDPLUS{
	if(!IsVal($1)){
			if($1->Idtype=="Var") $$ = node($1,"Expr","back++",NULL);
			else if($1->Value=="++front") $$ = node($1,"Expr","back++",NULL);
			else if($1->Value=="--front") $$ = node($1,"Expr","back++",NULL);
			else if($1->Value=="(Expr)"){
				if(($1->left)->Idtype=="Var") {
					$$ = node($1,"Expr","back++","NULL");
					}
					else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
					}
			else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
		}
	else{
			int temp1=0;
			char temp2=0;
			double temp3=0;
			float temp4=0;
			char c[20]="";
			if($1->Illus=="int") {temp1=atoi($1->val);itoa(temp1++,c,10);$$ = node(c,"Val",c,"int");}
			if($1->Illus=="char") {temp2=atoi($1->val);itoa(temp2++,c,10);$$ = node(c,"Val",c,"char");}
			if($1->Illus=="double") {temp3=atof($1->val);sprintf(c,"%f",temp3++);$$ = node(c,"Val",c,"double");}
			if($1->Illus=="float") {temp4=atof($1->val);sprintf(c,"%f",temp4++);$$ = node(c,"Val",c,"float");}
		}
	}
	|Expr DMINUS %prec BDMINUS{
	if(!IsVal($1)){
			if($1->Idtype=="Var") $$ = node($1,"Expr","back--",NULL);
			else if($1->Value=="++front") $$ = node($1,"Expr","back--",NULL);
			else if($1->Value=="--front") $$ = node($1,"Expr","back--",NULL);
			else if($1->Value=="(Expr)"){
				if(($1->left)->Idtype=="Var") {
					$$ = node($1,"Expr","back--","NULL");
					}
					else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
					}
			else {cout<<"error:The expression at the left of the equal sign does not match the rules"<<endl;return 0;}
		}
	else{
			int temp1=0;
			char temp2=0;
			double temp3=0;
			float temp4=0;
			char c[20]="";
			if($1->Illus=="int") {temp1=atoi($1->val);itoa(temp1--,c,10);$$ = node(c,"Val",c,"int");}
			if($1->Illus=="char") {temp2=atoi($1->val);itoa(temp2--,c,10);$$ = node(c,"Val",c,"char");}
			if($1->Illus=="double") {temp3=atof($1->val);sprintf(c,"%f",temp3--);$$ = node(c,"Val",c,"double");}
			if($1->Illus=="float") {temp4=atof($1->val);sprintf(c,"%f",temp4--);$$ = node(c,"Val",c,"float");}
		}
	}
	|PLUS Expr %prec PSIGN{ $$ = node($2,"Expr","+Expr",NULL);}
	|MINUS Expr %prec NSIGN{
	if(!IsVal($2)){
			$$ = node($2,"Expr","-Expr",NULL);
		}
	else{
			int temp1=0;
			char temp2=0;
			double temp3=0;
			float temp4=0;
			char c[20]="";
			if($2->Illus=="int") {temp1=atoi($2->val);itoa(-temp1,c,10);$$ = node(c,"Val",c,"int");}
			if($2->Illus=="char") {temp2=atoi($2->val);itoa(-temp2,c,10);$$ = node(c,"Val",c,"char");}
			if($2->Illus=="double") {temp3=atof($2->val);sprintf(c,"%f",-temp3);$$ = node(c,"Val",c,"double");}
			if($2->Illus=="float") {temp4=atof($2->val);sprintf(c,"%f",-temp4);$$ = node(c,"Val",c,"float");}
		}
	}
	|LP Expr RP{
		rec = $2;
		if($2->Idtype=="Val"){$$ = node($2->Value,"Val",$2->Value,$2->Illus);cout<<"Value:"<<$2->Value;}
		else {$$ = node($2,"Expr","(Expr)",NULL);}
	  }
	|Expr COMMA Expr{
		$3->sibling.push_back($1);
		$$ = $3;
		rec = $$;}
	|Var{$$ = $1;}
	|INTEGER_VALUE{$$ = node($1,"Val",$1,"int");}
	|FLOAT_VALUE{$$ = node($1,"Val",$1,"float");}
	|CHAR_VALUE{$$ = node($1,"Val",$1,"char");}
	|DOUBLE_VALUE{$$ = node($1,"Val",$1,"double");}
	;
If:IF LP Bool RP Stmt{$$ = node($3,$5,"If","if(...) ...",NULL);}
  |IF LP Bool RP Stmt ELSE Stmt{$5->Illus = "IF_BRANCH"; $7->Illus = "ELSE_BRANCH ";  $$ = node($3,$5,$7,"If","if(...) .. else ...",NULL);}
  ;
While:WHILE LP Bool RP Stmt{$$ = node($3,$5,"While","NULL",NULL);}
     ;
Bool:Expr{$$ = node($1,"Bool","Expr",NULL);}
	;
Read:READ LP Var RP SQM{$$ = node($3,"Read","NULL",NULL);}
    ;
Write:WRITE LP Expr RP SQM{$$ = node($3,"Write","NULL",NULL);}
     ;
For:FOR LP For_list RP Stmt{$$ = node($3,$5,"For","NULL",NULL);}
   ;
For_list:For_Expr1 SQM For_Expr2 SQM For_Expr3{$$ = node($1,$3,$5,"For_list",NULL,NULL);}
        ;
For_Expr1:Var{$$ = node($1,"For_Expr1","NULL",NULL);}
         |Expr{$$ = node($1,"For_Expr1","NULL",NULL);}
		 |{$$ = node("For_Expr1 NULL","NULL",NULL);}
		 ;
For_Expr2:Expr{$$ = node($1,"For_Expr2","NULL",NULL);}
		 |{$$ = node("For_Expr2 NULL","NULL",NULL);}
		 ;
For_Expr3:Expr{$$ = node($1,"For_Expr3","NULL",NULL);}
         |{$$ = node("For_Expr3 NULL","NULL",NULL);}
		 ;

%%

/////////////////////////////////////////////////////////////////////////////
// programs section

int main(void)
{
	int n = 1;
	//freopen("input.txt","r",stdin);
	//freopen("output.txt","w",stdout);
	yyparse();
	system("pause");
	return n;
}
