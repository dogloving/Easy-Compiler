### 说明

编译原理大作业。将一种类C语言翻译成没有循环控制语句(如for,while)的C语言。

支持类型推导，错误检测。

输出三地址码和翻译后的C语言。

使用了工具flex + bison。在Windows10 64bit + VS2017下可以配置成功。具体如何配置自行百度。

### 测试样例

```c++
// 源代码
int main()
{
    int x = 0;
    int y = 0;
    int z = 0;
    int n;
    read(n);
    for (; n<1000; n++)
    {
        x = n / 100;
        y = (n % 100)/10 ;
        z = n % 10;

        if(n == x*x*x + y*y*y +z*z*z)
        {
            write(n);
        }
    }
    int a = 0;
    for ( x=1; x<10; x++)
    {
        for ( y =0; y<10; y++)
        {
            for ( z = 0; z<10; z++)
            {
                a = 100*x+10*y+z;
                if (a== x*x*x + y*y*y + z*z*z)
                {
                    write(a);
                }
            }
        }
    }
    return 0;
}
```

```c++
// 翻译后代码
int main()
{
int x=0;
int y=0;
int z=0;
int n;
cin >> n;
{
label_0:
int tempVar0=n<1000;
if (tempVar0 == false) goto label_23;
{
int tempVar1=n/100;
x=tempVar1;
int tempVar2=n%100;
int tempVar3=tempVar2/10;
y=tempVar3;
int tempVar4=n%10;
z=tempVar4;
{
int tempVar5=x*x;
int tempVar6=tempVar5*x;
int tempVar7=y*y;
int tempVar8=tempVar7*y;
int tempVar9=tempVar6+tempVar8;
int tempVar10=z*z;
int tempVar11=tempVar10*z;
int tempVar12=tempVar9+tempVar11;
int tempVar13=n==tempVar12;
if (tempVar13 == false) goto label_19;
{
cout << n << endl;
}
}
label_19:
;
}
int tempVar1=n;
 n=n+1;
goto label_0;
}
label_23:
;
int a=0;
{
x=1;
label_25:
int tempVar2=x<10;
if (tempVar2 == false) goto label_60;
{
{
y=0;
label_28:
int tempVar3=y<10;
if (tempVar3 == false) goto label_56;
{
{
z=0;
label_31:
int tempVar4=z<10;
if (tempVar4 == false) goto label_52;
{
int tempVar5=100*x;
int tempVar6=10*y;
int tempVar7=tempVar5+tempVar6;
int tempVar8=tempVar7+z;
a=tempVar8;
{
int tempVar9=x*x;
int tempVar10=tempVar9*x;
int tempVar11=y*y;
int tempVar12=tempVar11*y;
int tempVar13=tempVar10+tempVar12;
int tempVar14=z*z;
int tempVar15=tempVar14*z;
int tempVar16=tempVar13+tempVar15;
int tempVar17=a==tempVar16;
if (tempVar17 == false) goto label_48;
{
cout << a << endl;
}
}
label_48:
;
}
int tempVar5=z;
 z=z+1;
goto label_31;
}
label_52:
;
}
int tempVar4=y;
 y=y+1;
goto label_28;
}
label_56:
;
}
int tempVar3=x;
 x=x+1;
goto label_25;
}
label_60:
;
}
```

```lex
// 输出的三地址码
=                       100                                             n                       label_0
<                       n                       1000                    tempVar0                label_1
IF NOT                  tempVar0                                        goto label_24           label_2
/                       n                       100                     tempVar1                label_3
=                       tempVar1                                        x                       label_4
%                       n                       100                     tempVar2                label_5
/                       tempVar2                10                      tempVar3                label_6
=                       tempVar3                                        y                       label_7
%                       n                       10                      tempVar4                label_8
=                       tempVar4                                        z                       label_9
*                       x                       x                       tempVar5                label_10
*                       tempVar5                x                       tempVar6                label_11
*                       y                       y                       tempVar7                label_12
*                       tempVar7                y                       tempVar8                label_13
+                       tempVar6                tempVar8                tempVar9                label_14
*                       z                       z                       tempVar10               label_15
*                       tempVar10               z                       tempVar11               label_16
+                       tempVar9                tempVar11               tempVar12               label_17
==                      n                       tempVar12               tempVar13               label_18
IF NOT                  tempVar13                                       goto label_20           label_19
                                                                                                label_20
=                       n                                               tempVar1                label_21
+                       n                       1                       n                       label_22
                                                                        goto label_1            label_23
                                                                                                label_24
=                       1                                               x                       label_25
<                       x                       10                      tempVar2                label_26
IF NOT                  tempVar2                                        goto label_61           label_27
=                       0                                               y                       label_28
<                       y                       10                      tempVar3                label_29
IF NOT                  tempVar3                                        goto label_57           label_30
=                       0                                               z                       label_31
<                       z                       10                      tempVar4                label_32
IF NOT                  tempVar4                                        goto label_53           label_33
*                       100                     x                       tempVar5                label_34
*                       10                      y                       tempVar6                label_35
+                       tempVar5                tempVar6                tempVar7                label_36
+                       tempVar7                z                       tempVar8                label_37
=                       tempVar8                                        a                       label_38
*                       x                       x                       tempVar9                label_39
*                       tempVar9                x                       tempVar10               label_40
*                       y                       y                       tempVar11               label_41
*                       tempVar11               y                       tempVar12               label_42
+                       tempVar10               tempVar12               tempVar13               label_43
*                       z                       z                       tempVar14               label_44
*                       tempVar14               z                       tempVar15               label_45
+                       tempVar13               tempVar15               tempVar16               label_46
==                      a                       tempVar16               tempVar17               label_47
IF NOT                  tempVar17                                       goto label_49           label_48
                                                                                                label_49
=                       z                                               tempVar5                label_50
+                       z                       1                       z                       label_51
                                                                        goto label_32           label_52
                                                                                                label_53
=                       y                                               tempVar4                label_54
+                       y                       1                       y                       label_55
                                                                        goto label_29           label_56
                                                                                                label_57
=                       x                                               tempVar3                label_58
+                       x                       1                       x                       label_59
                                                                        goto label_26           label_60
                                                                                                label_61
                                                                        End                     label_62
```

