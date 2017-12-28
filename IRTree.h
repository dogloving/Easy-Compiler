#pragma once
// 三地址item
#include <string>

struct IRTree {
	/*
		nodeCount: 临时变量数目(为了保证临时变量不会产生冲突，这里使之递增)
		nodeLabel: 三地址码数目
		op arg1 arg2 result: 四元式
		label: 当前四元式标签号
		type: 存放冗余信息，包括变量类型、定义表达式
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
