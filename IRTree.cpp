#include "IRTree.h"
#include "mytree.h"
#include <vector>
#include <map>
#include <set>
using namespace std;

/*
说下整体思路：
首先要产生三地址码：
	我们只对Expr和While、For、If-Else弄出产生式。首先是我们用链表表示地址码之间的关系，因为到时候要插入跳转指令比较方便。
	比如If-Else我们先得到三条链表If_condition, If_stmt, Else_stmt，然后加入跳转指令，同时将他们连在一起。
对于生成C++代码：
	我们在三地址码的基础上加上Read Write Def，以及大括号即可。 

*/

int extra_count = 0;

IRTree::IRTree() {
	next = last = NULL;
}
IRTree::IRTree(string result, string label) {
	this->op = "";
	this->arg1 = "";
	this->arg2 = "";
	this->result = result;
	this->label = label;
	next = last = NULL;
}
IRTree::IRTree(string op, string arg1, string arg2, string result) {
	this->op = op;
	this->arg1 = arg1;
	this->arg2 = arg2;
	this->result = result;
	this->label = "";
	next = last = NULL;
}
IRTree::IRTree(string op, string arg1, string arg2, string result, string label) {
	this->op = op;
	this->arg1 = arg1;
	this->arg2 = arg2;
	this->result = result;
	this->label = label;
	next = last = NULL;
}
IRTree::IRTree(string op, string arg1, string arg2, string result, string label, string type) {
	this->op = op;
	this->arg1 = arg1;
	this->arg2 = arg2;
	this->result = result;
	this->label = label;
	this->type = type;
	next = last = NULL;
}

int IRTree::nodeCount = 0;
int IRTree::labelCount = 0;
map<string, string> map_goto;
set<string> save_goto;
map<string, string> symbol_table; // 符号表
set<string> output_label; // 要输出的label，即有goto跳向他的
void show(IRTree *node); // 输出三地址码
IRTree* cut(IRTree *node); // 将链表中的无用节点删除
void output(IRTree *node); // 输出C++代码
string only_for_def(treenode* node); // 获取Def
void get_label(IRTree*); // 获取要输出的label
void pass_symbol_table(map<string, string> table) {
	symbol_table = table;
}
string check_type(string value) {
	// 通过value判断是什么类型的，因为语法树中一些Val节点是没有存储类型的
	for (char ch : value) {
		if (ch == '\'') return "char";
		if (ch == '.') return "double";
	}
	return "int";
}

IRTree* backtrace(treenode* node) {
	/*
	通过递归调用构造出关系
	大体思路是我们先将其兄弟节点之间的链表链起来，然后current表示当前节点，我们再专注于当前节点即可。最后将当前节点与之前的链表链起来
	*/

	if (node == NULL) {
		return NULL;
	}
	IRTree *head = NULL; // 当前节点的指令链表头
	IRTree *before = NULL;
	// 构造其兄弟节点的指令链表
	for (int i = node->sibling.size() - 1; i >= 0; --i) {
		IRTree *current = backtrace((node->sibling)[i]);
		if (!current) continue;
		if (head == NULL) {
			head = current;
		}
		else {
			while (before->next) before = before->next;
			before->next = current;
		}
		before = current;
	}

	string idtype(node->Idtype);
	IRTree *current = NULL;
	// 
	if (idtype == "Program") {
		current = backtrace(node->right);
	}
	else if (idtype == "Comp_stmt") {
		int before_count = IRTree::nodeCount;
		IRTree *left = new IRTree("", "", "", "", "", "{");
		current = backtrace(node->left);
		if (current == NULL) current = new IRTree("", "No label");
		IRTree *temp_node = current;
		while (temp_node->next) temp_node = temp_node->next;
		IRTree *right = new IRTree("", "", "", "", "", "}");
		left->next = current;
		temp_node->next = right;
		if (current != NULL)
			current = left;
		IRTree::nodeCount = before_count;
	}
	else if (idtype == "Stmt") {
		string value(node->Value);
		// if (value != "Def") {
		if (value == "If" || value == "While" || value == "For") {
			IRTree *left = new IRTree("", "", "", "", "", "{");
			current = backtrace(node->left);
			if (current == NULL) current = new IRTree("", "No label");
			IRTree *temp_node = current;
			while (temp_node->next) temp_node = temp_node->next;
			IRTree *right = new IRTree("", "", "", "", "", "}");
			IRTree *label = new IRTree("", "label_" + to_string(IRTree::labelCount++));

			left->next = current;
			temp_node->next = right;
			if (right == NULL)right = new IRTree("", "No label");
			temp_node = right;
			while (temp_node->next)temp_node = temp_node->next;
			temp_node->next = label;
			if (current != NULL)
				current = left;
		}
		else {
			IRTree *label = new IRTree("", "LABEL_" + to_string(extra_count++));
			current = backtrace(node->left);
			label->next = current;
			current = label;
		}
	}
	else if (idtype == "Def") {
		string def_stmt = only_for_def(node);
		current = new IRTree("", "", "", "", "", def_stmt);
	}
	else if (idtype == "Write") {
		current = backtrace(node->left);
		if (current == NULL) current = new IRTree("", "No label");
		IRTree *temp_node = current;
		while (temp_node->next) temp_node = temp_node->next;
		string write = "cout << " + temp_node->result + " << endl;";
		IRTree *left = new IRTree("", "", "", "", "", write);
		temp_node->next = left;
		current = cut(current);
		show(current);
	}
	else if (idtype == "Read") {
		current = backtrace(node->left);
		string write = "cin >> " + current->result + ";";
		IRTree *left = new IRTree("", "", "", "", "", write);
		current->next = left;
	}
	else if (idtype == "Var" || idtype == "Val") {
		current = new IRTree(node->Value, "No label");
		return current;
	}
	else if (idtype == "Bool") {
		current = backtrace(node->left);
	}
	else if (idtype == "(Expr)") {
		current = backtrace(node->left);
	}
	else if (idtype == "For_Expr1") {
		current = backtrace(node->left);
	}
	else if (idtype == "For_Expr2") {
		current = backtrace(node->left);
	}
	else if (idtype == "For_Expr3") {
		current = backtrace(node->left);
	}
	else if (idtype == "For_Expr1 NULL") {
		// current = backtrace(node->left);
	}
	else if (idtype == "For_Expr2 NULL") {
		// current = backtrace(node->left);
	}
	else if (idtype == "For_Expr3 NULL") {
		// current = 
	}
	else if (idtype == "Expr") {
		string value(node->Value);
		if (value == "(Expr)") {
			current = backtrace(node->left);
		}
		else if (value == "Add" || value == "MINUS" || value == "Mul" || value == "Div" || value == "Mod"
			|| value == "Cmp_EL" || value == "Cmp_LT" || value == "Cmp_GT" || value == "Cmp_EQ" || value == "Cmp_EG"
			|| value == "Cmp_and" || value == "Cmp_OR" || value == "Cmp_EN" || value == "Bit_right" || value == "Bit_left"
			|| value == "Bit_and" || value == "Bit_or" || value == "Bit_xor"
			) {
			IRTree *left = backtrace(node->left);
			IRTree *right = backtrace(node->right);
			IRTree *left_last = left, *right_last = right;
			IRTree *temp_node = nullptr;
			temp_node = left; while (temp_node->next) temp_node = temp_node->next; left_last = temp_node;
			temp_node = right; while (temp_node->next) temp_node = temp_node->next; right_last = temp_node;

			string op;
			if (value == "Add") op = "+";
			else if (value == "Mul") op = "*";
			else if (value == "MINUS") op = "-";
			else if (value == "Div") op = "/";
			else if (value == "Mod") op = "%";
			else if (value == "Cmp_EL") op = "<=";
			else if (value == "Cmp_LT") op = "<";
			else if (value == "Cmp_GT") op = ">";
			else if (value == "Cmp_EQ") op = "==";
			else if (value == "Cmp_EG") op = ">=";
			else if (value == "Cmp_EN") op = "!=";
			else if (value == "Cmp_and") op = "&&";
			else if (value == "Cmp_OR") op = "||";
			else if (value == "Bit_left") op = "<<";
			else if (value == "Bit_right") op = ">>"; 
			else if (value == "Bit_and") op = "&";
			else if (value == "Bit_or") op = "|";
			else if (value == "Bit_xor") op = "^";
			string type1 = symbol_table[left_last->result], type2 = symbol_table[right_last->result];
			if (type1 == "") type1 = check_type(left_last->result);
			if (type2 == "") type2 = check_type(right_last->result);
			string type;
			if (type1 == type2) type = type1;
			else if (type1 == "int" && type2 == "float") type = "float";
			else if (type1 == "float" && type2 == "int") type = "float";
			else if (type1 == "int" && type2 == "double") type = "double";
			else if (type1 == "double" && type2 == "int") type = "double";
			else if (type1 == "float" && type2 == "double") type = "double";
			else if (type1 == "double" && type2 == "float") type = "double";
			else if (type1 == "int" && type2 == "char") type = "int";
			else if (type1 == "char" && type2 == "int") type = "int";

			IRTree *temp = new IRTree(op, left_last->result, right_last->result, "tempVar" + to_string(IRTree::nodeCount++),
				"label_" + to_string(IRTree::labelCount++), type);
			symbol_table["tempVar" + to_string(IRTree::nodeCount - 1)] = type;
			current = left;
			left_last->next = right;
			right_last->next = temp;
		}
		else if (value == "Assign") {
			// 处理c = c++之类的情况
			if (node->left->Idtype == "Var" && node->right->Idtype == "Expr"
				&& (string(node->right->Value) == "back++" || string(node->right->Value) == "back--")
				&& string(node->left->Value) == string(node->right->left->Value)) {
					current = new IRTree(string(node->right->Value) == "back++" ? "+" : "-", string(node->left->Value),
						"1", string(node->left->Value), "label_" + to_string(IRTree::labelCount++));
			}
			else {
				IRTree *left = backtrace(node->left);
				IRTree *right = backtrace(node->right);
				IRTree *left_last = left, *right_last = right;
				IRTree *temp_node = nullptr;
				temp_node = left; while (temp_node->next) temp_node = temp_node->next; left_last = temp_node;
				temp_node = right; while (temp_node->next) temp_node = temp_node->next; right_last = temp_node;

				string result_left = left_last->result, result_right = right_last->result;
				IRTree *temp = new IRTree("=", result_right, "", result_left, "label_" + to_string(IRTree::labelCount++));
				current = left;
				left_last->next = right;
				right_last->next = temp;
			}
		}
		else if (value == "++front" || value == "--front") {
			IRTree *left = backtrace(node->left);
			IRTree *temp = new IRTree(value == "++front" ? "+" : "-", left->result, "1", left->result, "label_" + to_string(IRTree::labelCount++));
			IRTree *temp2 = new IRTree(left->result, "No label");
			temp->next = temp2;
			current = temp;
		}
		else if (value == "back++" || value == "back--") {
			IRTree *left = backtrace(node->left);
			string type = symbol_table[left->result];
			IRTree *temp2 = new IRTree("=", left->result, "", "tempVar" + to_string(IRTree::nodeCount++),
				"label_" + to_string(IRTree::labelCount++), type);
			symbol_table["tempVar" + to_string(IRTree::nodeCount - 1)] = type;
			IRTree *temp = new IRTree(value == "back++" ? "+" : "-", left->result, "1", left->result,
				"label_" + to_string(IRTree::labelCount++));
			IRTree *temp3 = new IRTree("tempVar" + to_string(IRTree::nodeCount - 1), "No label");
			current = temp2;
			temp2->next = temp;
			temp->next = temp3;
		}
	}
	else if (idtype == "While") {
		IRTree *left = backtrace(node->left);
		// left = cut(left);
		if (left == NULL)left = new IRTree("", "label_" + to_string(IRTree::labelCount++));
		if (left->label == "No label") left->label = "label_" + to_string(IRTree::labelCount++);
		IRTree *left_last = left, *right_last = NULL;
		IRTree *temp_node = nullptr;
		temp_node = left; while (temp_node->next) temp_node = temp_node->next; left_last = temp_node;
		IRTree *mid = new IRTree("IF NOT", left_last->result, "", "", "label_" + to_string(IRTree::labelCount++));
		IRTree *right = backtrace(node->right);	
		right = cut(right);
		if (right == NULL) right = new IRTree("", "No label");
		temp_node = right; while (temp_node->next) temp_node = temp_node->next; right_last = temp_node;

		IRTree *go_back = new IRTree("", "", "", "goto " + left->label, "label_" + to_string(IRTree::labelCount++));
		mid->result = "goto label_" + to_string(IRTree::labelCount);
		current = left;
		left_last->next = mid;
		mid->next = right;
		right_last->next = go_back;
	}
	else if (idtype == "If") {
		string value(node->Value);
		if (value == "if(...) ...") {
			IRTree *left = backtrace(node->left);
			// left = cut(left);
			if (left == NULL)left = new IRTree("", "No label");
			IRTree *left_last = left, *right_last = NULL;
			IRTree *temp_node = nullptr;
			temp_node = left; while (temp_node->next) temp_node = temp_node->next; left_last = temp_node;
			IRTree *mid = new IRTree("IF NOT", left_last->result, "", "", "label_" + to_string(IRTree::labelCount++));
			IRTree *right = backtrace(node->right);
			right = cut(right);
			if (right == NULL) right = new IRTree("", "No label");
			temp_node = right; while (temp_node->next) temp_node = temp_node->next; right_last = temp_node;

			mid->result = "goto label_" + to_string(IRTree::labelCount);
			current = left;
			left_last->next = mid;
			mid->next = right;
		}
		else if (value == "if(...) .. else ...") {
			IRTree *left = backtrace(node->left);
			// left = cut(left);
			if (left == NULL)left = new IRTree("", "No label");
			IRTree *left_last = left, *right_last = NULL;
			IRTree *temp_node = nullptr;
			temp_node = left; while (temp_node->next) temp_node = temp_node->next; left_last = temp_node;
			IRTree *mid = new IRTree("IF NOT", left_last->result, "", "", "label_" + to_string(IRTree::labelCount++));
			IRTree *right = backtrace(node->right);
			right = cut(right);
			if (right == NULL) right = new IRTree("", "No label");
			temp_node = right; while (temp_node->next) temp_node = temp_node->next; right_last = temp_node;

			mid->result = "goto label_" + to_string(IRTree::labelCount + 1);
			current = left;
			left_last->next = mid;
			mid->next = right;
			IRTree *go_to = new IRTree("", "", "", "",
				"label_" + to_string(IRTree::labelCount++));
			IRTree *else_branch = backtrace(node->temp1);
			map_goto[mid->result] = else_branch->label;
			save_goto.insert(else_branch->label);
			go_to->result = "goto label_" + to_string(IRTree::labelCount);
			right_last->next = go_to;
			go_to->next = else_branch;
			current = cut(current);
		}
	}
	else if (idtype == "For") {
		treenode *forlist = node->left;
		IRTree *temp_node = nullptr;
		IRTree *for1_last = NULL, *for2_last = NULL, *for3_last = NULL, *stmt_last = NULL;
		IRTree *for1 = backtrace(forlist->left);
		if (for1 == NULL) for1 = new IRTree("", "No label");
		temp_node = for1; while (temp_node->next) temp_node = temp_node->next; for1_last = temp_node;
		int cnt = IRTree::labelCount;
		IRTree *for2 = backtrace(forlist->right);
		if (for2 == NULL) for2 = new IRTree("", "No label");
		temp_node = for2; while (temp_node->next) temp_node = temp_node->next; for2_last = temp_node;
		IRTree *mid = new IRTree("IF NOT", for2_last->result, "", "", "label_" + to_string(IRTree::labelCount++));
		IRTree *stmt = backtrace(node->right);
		if (stmt == NULL) stmt = new IRTree("", "No label");
		temp_node = stmt; while (temp_node->next) temp_node = temp_node->next; stmt_last = temp_node;
		IRTree *for3 = backtrace(forlist->temp1);
		if (for3 == NULL) for3 = new IRTree("", "No label");
		temp_node = for3; while (temp_node->next) temp_node = temp_node->next; for3_last = temp_node;
		IRTree *go_back = new IRTree("", "", "", "goto label_" + to_string(cnt), "label_" + to_string(IRTree::labelCount++));
		mid->result = "goto label_" + to_string(IRTree::labelCount);

		current = for1;
		for1_last->next = for2;
		for2_last->next = mid;
		mid->next = stmt;
		stmt_last->next = for3;
		for3_last->next = go_back;
		current = cut(current);
	}

	// int main(){int a,b,c,d;c=(c++)/3+(c++)/4;}


	// return
	if (before) {
		while (before->next)before = before->next;
		before->next = current;
		return head;
	}
	if (idtype == "Program") {
		if (current == NULL) current = new IRTree("", "No label");
		IRTree *temp_node = current;
		while (temp_node->next) temp_node = temp_node->next;
		temp_node->next = new IRTree("End", "label_" + to_string(IRTree::labelCount++));
		current = cut(current);
		show(current);
		get_label(current);
		cout << "labels should be output" << endl;
		cout << output_label.size() << endl;
		for (string fuck : output_label)cout << fuck << endl;
		cout << "________________________________________________________________________" << endl;
		output(current);
	}
	return current;
}

string show_help(string s) {
	if (s.size() >= 16) return s + "\t";
	if (s.size() >= 8) return s + "\t\t";
	return s + "\t\t\t";
}

void show(IRTree *node) {
	while (node) {
		if (node->label.size() >= 5 && string(node->label.begin(), node->label.begin() + 5) == "label")
		cout << show_help(node->op) + show_help(node->arg1) + show_help(node->arg2) 
			+ show_help(node->result) + show_help(node->label) << endl;
		node = node->next;
	}
}

IRTree* cut(IRTree *node) {
	// 将没用的节点去除
	IRTree *head = NULL, *pre = NULL;
	while (node) {
		if ((node->label.size() >= 5 && string(node->label.begin(), node->label.begin() + 5) == "label")
			|| (node->type != "") || save_goto.find(node->label) != save_goto.end()) {
			if (head == NULL) head = node;
			else pre->next = node;
			pre = node;
		}
		node = node->next;
	}
	return head;
}

void output(IRTree *node) {
	cout << "int main()" << endl;
	while (node) {
		if (node->result == "End") return;
		if (node->label.size() >= 5 && string(node->label.begin(), node->label.begin() + 5) == "LABEL") {
			cout << node->label << ":" << endl;
		}
		else if (node->op == "=" && node->arg2 == "" && node->result.size() >= 7 &&
			string(node->result.begin(), node->result.begin()+7) == "tempVar") {
			// 输出int tempVar2 = a + b;类似
			if (output_label.find(node->label) != output_label.end()) {
				// 输出label3:类似
				cout << node->label << ":" << endl;
			}
			if (map_goto.find(node->result) != map_goto.end()) {
				cout << node->type << " " << ("goto " + map_goto[node->result]) << "=" << node->arg1 << node->arg2 << ";" << endl;
			}
			else {
				cout << node->type << " " << node->result << "=" << node->arg1 << node->arg2 << ";" << endl;
			}
		}
		else if (node->type != "" && node->type != "int" && node->type != "char" && node->type != "float"
			&& node->type != "double" && node->op != "=") {
			// 输出int a, b, c = 4;类似
			cout << node->type << endl;
		}
		else {
			if (output_label.find(node->label) != output_label.end()) {
				// 输出label3:类似
				cout << node->label << ":" << endl; 
			}
			if (node->op == "IF NOT") {
				// 输出if (tempVar3 == false) goto label3;类似
				if (map_goto.find(node->result) != map_goto.end()) {
					cout << "if (" << node->arg1 << " == false) " << ("goto " + map_goto[node->result]);
				}
				else {
					cout << "if (" << node->arg1 << " == false) " << node->result;
				}
			}
			else if (node->op == "=") {
				// 输出i = tempVar4;类似
				cout << node->result << node->op << node->arg1;
			}
			else if (node->op != ""){
				// 输出int c = tempVar1 + tempVar2;类似
				if (map_goto.find(node->result) != map_goto.end()) {
					cout << node->type << " " << ("goto " + map_goto[node->result]) << "=" << node->arg1
						<< node->op << node->arg2;
				}
				else {
					cout << node->type << " " << node->result << "=" << node->arg1 << node->op << node->arg2;
				}
			}
			else {
				// 输出
				if (map_goto.find(node->result) != map_goto.end()) {
					cout << ("goto " + map_goto[node->result]) << node->arg1 << node->op << node->arg2;
				}
				else {
					cout << node->result << node->arg1 << node->op << node->arg2;
				}
			}
			cout << ";" << endl;
		}

		node = node->next;
	}
	cout << "output labels are: " << endl;
	for (string shit : output_label)cout << shit << endl;
}

string def_expr(treenode* node) {
	if (node == NULL)return "";
	if (node->Idtype == "Var" || node->Idtype == "Val") return node->Value;
	if (node->Idtype == "Expr") {
		string left = def_expr(node->left);
		string right = def_expr(node->right);
		if (node->Value == "Add") return "(" + left + "+" + right + ")";
		else if (node->Value == "MINUS") return "(" + left + "-" + right + ")";
		else if (node->Value == "Mul") return "(" + left + "*" + right + ")";
		else if (node->Value == "Div") return "(" + left + "/" + right + ")";
		else if (node->Value == "Mod") return "(" + left + "%" + right + ")";
		else if (node->Value == "Cmp_EL") return "(" + left + "<=" + right + ")";
		else if (node->Value == "Cmp_LT") return "(" + left + "<" + right + ")";
		else if (node->Value == "Cmp_GT") return "(" + left + ">" + right + ")";
		else if (node->Value == "Cmp_EQ") return "(" + left + "==" + right + ")";
		else if (node->Value == "Cmp_EG") return "(" + left + ">=" + right + ")";
		else if (node->Value == "Cmp_and") return "(" + left + "&&" + right + ")";
		else if (node->Value == "Cmp_OR") return "(" + left + "||" + right + ")";
		else if (node->Value == "Cmp_EN") return "(" + left + "!=" + right + ")";
		else if (node->Value == "Bit_right") return "(" + left + ">>" + right + ")";
		else if (node->Value == "Bit_left") return "(" + left + "<<" + right + ")";
		else if (node->Value == "Bit_and") return "(" + left + "&" + right + ")";
		else if (node->Value == "Bit_or") return "(" + left + "|" + right + ")";
		else if (node->Value == "Bit_xor") return "(" + left + "^" + right + ")";
		else if (node->Value == "(Expr)") return def_expr(node->left);
	}
}

void def_helper(treenode* node, vector<string>& hehe) {
	if (node == NULL) return;
	for (int i = node->sibling.size() - 1; i >= 0; --i) {
		def_helper(node->sibling[i], hehe);
	}
	if (node->Idtype == "Var") hehe.push_back(node->Value);
	else {
		string left = node->left->Value;
		string right = def_expr(node->right);
		hehe.push_back(left + "=" + right);
	}
}

string only_for_def(treenode* node) {
	string type = node->left->Value;
	vector<string> hehe;
	def_helper(node->right, hehe);
	string res = type + " ";
	for (int i = 0; i < hehe.size(); ++i) {
		res += hehe[i];
		if (i < hehe.size() - 1) res += ",";
		else res += ";";
	}
	return res;
}

void get_label(IRTree *node) {
	if (node == NULL) return;
	while (node) {
		if (node->result.size() >= 5 && string(node->result.begin(), node->result.begin() + 5) == "goto ") {
			output_label.insert(string(node->result.begin() + 5, node->result.end()));
		}
		node = node->next;
	}
}