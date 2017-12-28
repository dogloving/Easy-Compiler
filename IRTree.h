#pragma once
// ����ַitem
#include <string>

struct IRTree {
	/*
		nodeCount: ��ʱ������Ŀ(Ϊ�˱�֤��ʱ�������������ͻ������ʹ֮����)
		nodeLabel: ����ַ����Ŀ
		op arg1 arg2 result: ��Ԫʽ
		label: ��ǰ��Ԫʽ��ǩ��
		type: ���������Ϣ�������������͡�������ʽ
	*/
	static int nodeCount;
	static int labelCount;
	std::string op, arg1, arg2, result, label, type;
	IRTree *last, *next;
	IRTree();
	IRTree(std::string result, std::string label);
	IRTree(std::string op, std::string arg1, std::string arg2, std::string result);
	IRTree(std::string op, std::string arg1, std::string arg2, std::string result, std::string label);
	IRTree(std::string op, std::string arg1, std::string arg2, std::string result, std::string label, std::string type);
};
