#pragma once
#include<iostream>
#include<vector>
using namespace std;
//普通节点
struct treenode
{
	struct treenode *left;//左孩子
	struct treenode *right;//右孩子
	struct treenode *temp1;//有备无患一
	struct treenode *temp2;//有备无患二
	char* Idtype;//节点类型
	char* Value;//节点的值
	char* Illus;//节点说明
	char* val;
	std::vector<struct treenode*> sibling;
};

/*如果有时间的话可以考虑去尝试一下利用变长函数*/

//这个就是我们从终结符-->S的过程
extern struct treenode *node(char *idtype, char *value, char *illus);

extern struct treenode *node(char *v, char *idtype, char *value, char *illus);

//只有一个孩子
extern struct treenode *node(treenode *a, char *idtype, char *value, char *illus);

//有两个节点的情况
extern struct treenode *node(treenode *a, treenode *b, char *idtype, char *value, char *illus);

//有三个节点的情况
extern struct treenode *node(treenode *a, treenode *b, treenode *c, char *idtype, char *value, char *illus);

//先序遍历
extern void eval(struct treenode *root, int level);

//判断是不是Val
extern bool IsVal(struct treenode *root);



/*------------------------------------------向下是符号表的一些东西------------------------------------------------*/
//符号表的节点
struct dec_id {
	char *name;//ID名字
	char *type;//ID的类型
};

//创建符号节点
extern struct dec_id *newid(char *n, char * t);

//
