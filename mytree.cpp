#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include<stdarg.h>
#include"mytree.h"

int i;

struct treenode *node(char *idtype, char *value, char *illus)
{
	struct treenode *root = new treenode();
	//struct treenode *root = (struct treenode*)malloc(sizeof(struct treenode));//����ռ䣬����treenode����
	if (!root)
	{
		printf("�ռ䲻�㣬����ʧ��");
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
	//struct treenode *root = (struct treenode*)malloc(sizeof(struct treenode));//����ռ䣬����treenode����
	if (!root)
	{
		printf("�ռ䲻�㣬����ʧ��");
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
	//struct treenode *root = (struct treenode*)malloc(sizeof(struct treenode));//����ռ䣬����treenode����
	if (!root)
	{
		printf("�ռ䲻�㣬����ʧ��");
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
		//����
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
		eval(root->left, level + 1);//����������
		eval(root->right, level + 1);//����������
		eval(root->temp1, level + 1);
		eval(root->temp2, level + 1);

	}
}

struct treenode *node(treenode *a, treenode *b, char *idtype, char *value, char *illus)
{
	struct treenode *root = new treenode();
	//struct treenode *root = (struct treenode*)malloc(sizeof(struct treenode));//����ռ䣬����treenode����
	if (!root)
	{
		printf("�ռ䲻�㣬����ʧ��");
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
	//struct treenode *root = (struct treenode*)malloc(sizeof(struct treenode));//����ռ䣬����treenode����
	if (!root)
	{
		printf("�ռ䲻�㣬����ʧ��");
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

//�ж��ǲ���Val����
bool IsVal(struct treenode* root)
{
	if (root->Idtype == "Val")
		return true;
	else
		return false;
}


/*---------------------------------------���ű�ĺ���-----------------------------------------*/

//�ڵ㴴��
struct dec_id *newid(char *n, char * t)
{
	struct dec_id *root = new dec_id();
	//struct dec_id *root = (struct dec_id*)malloc(sizeof(struct dec_id));
	if (!root)
	{
		printf("�ռ䲻�㣬����ʧ��");
		exit(0);
	}
	root->name = n;
	root->type = t;
	return root;
}