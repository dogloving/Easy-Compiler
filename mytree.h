#pragma once
#include<iostream>
#include<vector>
using namespace std;
//��ͨ�ڵ�
struct treenode
{
	struct treenode *left;//����
	struct treenode *right;//�Һ���
	struct treenode *temp1;//�б��޻�һ
	struct treenode *temp2;//�б��޻���
	char* Idtype;//�ڵ�����
	char* Value;//�ڵ��ֵ
	char* Illus;//�ڵ�˵��
	char* val;
	std::vector<struct treenode*> sibling;
};

/*�����ʱ��Ļ����Կ���ȥ����һ�����ñ䳤����*/

//����������Ǵ��ս��-->S�Ĺ���
extern struct treenode *node(char *idtype, char *value, char *illus);

extern struct treenode *node(char *v, char *idtype, char *value, char *illus);

//ֻ��һ������
extern struct treenode *node(treenode *a, char *idtype, char *value, char *illus);

//�������ڵ�����
extern struct treenode *node(treenode *a, treenode *b, char *idtype, char *value, char *illus);

//�������ڵ�����
extern struct treenode *node(treenode *a, treenode *b, treenode *c, char *idtype, char *value, char *illus);

//�������
extern void eval(struct treenode *root, int level);

//�ж��ǲ���Val
extern bool IsVal(struct treenode *root);



/*------------------------------------------�����Ƿ��ű��һЩ����------------------------------------------------*/
//���ű�Ľڵ�
struct dec_id {
	char *name;//ID����
	char *type;//ID������
};

//�������Žڵ�
extern struct dec_id *newid(char *n, char * t);

//
