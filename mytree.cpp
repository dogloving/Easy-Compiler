#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include<stdarg.h>
#include"mytree.h"

int i;

struct treenode *node(char *idtype, char *value, char *illus)
{
	struct treenode *root = new treenode();
	//struct treenode *root = (struct treenode*)malloc(sizeof(struct treenode));//申请空间，创建treenode变量
	if (!root)
	{
		printf("空间不足，程序失败");
		exit(0);
	}
	root->Idtype = idtype;
	root->Value = value;
	root->Illus = illus;
	root->val = NULL;
	root->left = NULL;
	root->right = NULL;
	root->temp1 = NULL;
	root->temp2 = NULL;
	return root;
}

struct treenode *node(char* v, char *idtype, char *value, char *illus)
{
	struct treenode *root = new treenode();
	//struct treenode *root = (struct treenode*)malloc(sizeof(struct treenode));//申请空间，创建treenode变量
	if (!root)
	{
		printf("空间不足，程序失败");
		exit(0);
	}
	root->Idtype = idtype;
	root->Value = value;
	root->Illus = illus;
	root->val = v;
	root->left = NULL;
	root->right = NULL;
	root->temp1 = NULL;
	root->temp2 = NULL;
	return root;
}

struct treenode *node(treenode *a, char *idtype, char *value, char *illus)
{
	struct treenode *root = new treenode();
	//struct treenode *root = (struct treenode*)malloc(sizeof(struct treenode));//申请空间，创建treenode变量
	if (!root)
	{
		printf("空间不足，程序失败");
		exit(0);
	}
	root->Idtype = idtype;
	root->Value = value;
	root->Illus = illus;
	root->val = NULL;
	root->left = a;
	root->right = NULL;
	root->temp1 = NULL;
	root->temp2 = NULL;
	return root;
}


void eval(struct treenode*root, int level)
{
	if (root != NULL)
	{
		/* huang adds this */
		for (int index = root->sibling.size() - 1; index >= 0; --index)
			eval(root->sibling[index], level);
		/*
		for (struct treenode* sibling : root->sibling) {
		eval(sibling, level);
		}*/
		//缩进
		for (i = 0; i < level; ++i)
		{
			printf("  ");
		}
		if (root->Idtype != NULL)
		{
			printf("%s  ", root->Idtype);
		}
		if (root->Value != NULL)
		{
			printf("%s  ", root->Value);
		}
		if (root->Illus != NULL)
		{
			printf("%s  ", root->Illus);
		}
		printf("\n");
		eval(root->left, level + 1);//遍历左子树
		eval(root->right, level + 1);//遍历右子树
		eval(root->temp1, level + 1);
		eval(root->temp2, level + 1);

	}
}

struct treenode *node(treenode *a, treenode *b, char *idtype, char *value, char *illus)
{
	struct treenode *root = new treenode();
	//struct treenode *root = (struct treenode*)malloc(sizeof(struct treenode));//申请空间，创建treenode变量
	if (!root)
	{
		printf("空间不足，程序失败");
		exit(0);
	}
	root->Idtype = idtype;
	root->Value = value;
	root->Illus = illus;
	root->val = NULL;
	root->left = a;
	root->right = b;
	root->temp1 = NULL;
	root->temp2 = NULL;
	return root;
}

struct treenode *node(treenode *a, treenode *b, treenode *c, char *idtype, char *value, char *illus)
{
	struct treenode *root = new treenode();
	//struct treenode *root = (struct treenode*)malloc(sizeof(struct treenode));//申请空间，创建treenode变量
	if (!root)
	{
		printf("空间不足，程序失败");
		exit(0);
	}
	root->Idtype = idtype;
	root->Value = value;
	root->Illus = illus;
	root->val = NULL;
	root->left = a;
	root->right = b;
	root->temp1 = c;
	root->temp2 = NULL;
	return root;
}

//判断是不是Val类型
bool IsVal(struct treenode* root)
{
	if (root->Idtype == "Val")
		return true;
	else
		return false;
}


/*---------------------------------------符号表的函数-----------------------------------------*/

//节点创建
struct dec_id *newid(char *n, char * t)
{
	struct dec_id *root = new dec_id();
	//struct dec_id *root = (struct dec_id*)malloc(sizeof(struct dec_id));
	if (!root)
	{
		printf("空间不足，程序失败");
		exit(0);
	}
	root->name = n;
	root->type = t;
	return root;
}