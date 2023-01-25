
# LibClang 教程

Clang 是一个开源编译器，它建立在 LLVM 框架之上，面向 C、C++ 和 Objective-C（LLVM 也是 Julia 的 JIT 后端）。由于高度模块化的设计，近年来，Clang 已成为越来越多使用编译器部分的项目的核心，例如用于源到源转换、静态分析和安全评估的工具，以及用于代码补全的编辑器工具、格式化等

虽然 LLVM 和 Clang 是用 C++ 编写的，但 Clang 项目维护了一个名为 “libclang” 的 C 导出接口，它提供对抽象语法树和类型表示的访问。由于对 C 调用习惯的支持无处不在，许多语言都使用 libclang 作为与 C 和 C++ 相关的工具的基础。

Julia 包 Clang.jl 封装了 libclang，为 Julia 风格的编程提供了一个小型的便利 API，并提供了一个基于 libclang 功能构建的 C-to-Julia 封装器生成器。

这是以下是使用的头文件 `example.h` 的示例：

```c
// example.h
struct ExStruct {
    int    kind;
    char*  name;
    float* data;
};

void* ExFunction (int kind, char* name, float* data) {
    struct ExStruct st;
    st.kind = kind;
    st.name = name;
    st.data = data;
}
```

## 打印结构字段

为了用一个简洁的例子来激发讨论，考虑这个结构：

```c
struct ExStruct {
    int    kind;
    char*  name;
    float* data;
};
```

解析和查询这个结构的字段只需要几行代码：

```julia
julia> using Clang

julia> trans_unit = Clang.parse_header(Index(), "example.h")
TranslationUnit(Ptr{Nothing} @0x00007fe13cdc8a00, Index(Ptr{Nothing} @0x00007fe13cc8dde0, 0, 1))

julia> root_cursor = Clang.getTranslationUnitCursor(trans_unit)
CLCursor (CLTranslationUnit) example.h

julia> struct_cursor = search(root_cursor, "ExStruct") |> only
CLCursor (CLStructDecl) ExStruct

julia> for c in children(struct_cursor)  # print children
           println("Cursor: ", c, "\n  Kind: ", kind(c), "\n  Name: ", name(c), "\n  Type: ", Clang.getCursorType(c))
       end
Cursor: CLCursor (CLFieldDecl) kind
  Kind: CXCursor_FieldDecl(6)
  Name: kind
  Type: CLType (CLInt)
Cursor: CLCursor (CLFieldDecl) name
  Kind: CXCursor_FieldDecl(6)
  Name: name
  Type: CLType (CLPointer)
Cursor: CLCursor (CLFieldDecl) data
  Kind: CXCursor_FieldDecl(6)
  Name: data
  Type: CLType (CLPointer)
```

### 抽象语法树(AST)的表示

让我们检查上面的示例，从变量 `trans_unit` 开始：

```julia
julia> trans_unit
TranslationUnit(Ptr{Nothing} @0x00007fa9ac6a9f90, Index(Ptr{Nothing} @0x00007fa9ac6b4080, 0, 1))
```

`TranslationUnit` 是 libclang AST 的入口点。在上面的示例中，`trans_unit` 是解析文件 `example.h` 的 `TranslationUnit`。 libclang AST 表示为包含三个基本信息的游标节点的有向无环图：

* Kind：游标节点的用途

* Type：游标所代表的对象的类型

* Children：子节点列表

```julia
julia> root_cursor
CLCursor (CLTranslationUnit) example.h
```

`root_cursor` 是 `TranslationUnit` 的根游标节点。

在 Clang.jl 中，游标类型通过从抽象类型 CLCursor 派生的 Julia 类型进行封装。在这背后，libclang 将每个游标 (CXCursor) 种类和类型 (CXType) 表示为一个枚举值。这些枚举值用于自动将所有 CXCursor 和 CXType 对象映射到 Julia 类型。因此，可以针对 CLCursor 或 CLType 变量编写多重调度方法。

```julia
julia> dump(root_cursor)
CLTranslationUnit
  cursor: Clang.LibClang.CXCursor
    kind: Clang.LibClang.CXCursorKind CXCursor_TranslationUnit(300)
    xdata: Int32 0
    data: Tuple{Ptr{Nothing},Ptr{Nothing},Ptr{Nothing}}
      1: Ptr{Nothing} @0x00007fe13b3552e8
      2: Ptr{Nothing} @0x0000000000000001
      3: Ptr{Nothing} @0x00007fe13cdc8a00
```

在背后，libclang 将每个游标种类和类型表示为枚举值。

这些枚举翻译到 Julia 中作为 `Cenum` 的子类型：

```julia
julia> dump(Clang.LibClang.CXCursorKind)
Clang.LibClang.CXCursorKind <: Clang.LibClang.CEnum.Cenum{UInt32}
```

该示例演示了访问给定游标的子节点的两种不同方式。这里，`children` 函数返回给定游标的子节点上的迭代器：

```julia
julia> children(struct_cursor)
3-element Array{CLCursor,1}:
 CLCursor (CLFieldDecl) kind
 CLCursor (CLFieldDecl) name
 CLCursor (CLFieldDecl) data
```

在这里，`search` 函数返回与给定名称匹配的子节点列表：

```julia
julia> search(root_cursor, "ExStruct")
1-element Array{CLCursor,1}:
 CLCursor (CLStructDecl) ExStruct
```

### 类型表示

上面的示例还演示了使用辅助函数 `type` 查询与给定游标关联的类型。输出信息中：

```julia
Cursor: CLCursor (CLFieldDecl) kind
  Kind: CXCursor_FieldDecl(6)
  Name: kind
  Type: CLType (CLInt)
Cursor: CLCursor (CLFieldDecl) name
  Kind: CXCursor_FieldDecl(6)
  Name: name
  Type: CLType (CLPointer)
Cursor: CLCursor (CLFieldDecl) data
  Kind: CXCursor_FieldDecl(6)
  Name: data
  Type: CLType (CLPointer)
```

每个 `CLFieldDecl` 游标都有一个关联的 `CLType` 对象，其标识反映了给定结构成员的字段类型。请务必注意 *kind* 字段与名称和数据字段的表示之间的区别。 *kind* 直接表示为 `CLInt` 对象，但名称和数据表示为 `CLPointer` CLTypes。如下一节所述，可以查询 CLPointer 的完整类型以检索这些成员的完整 `char *` 和 `float *` 类型。使用类似的方案捕获用户定义的类型。

## 函数参数和类型

要进一步探索类型表示，请考虑以下函数（包含在 example.h 中）：

```c
void* ExFunction (int kind, char* name, float* data) {
    struct ExStruct st;
    st.kind = kind;
    st.name = name;
    st.data = data;
}
```

为了找到此函数声明的游标，我们使用函数 `search` 检索类型为 `CXCursor_FunctionDecl` 的节点，并选择列表中的最后一个：

```julia
julia> using Clang.LibClang  # CXCursor_FunctionDecl is exposed from LibClang

julia> fdecl = search(root_cursor, CXCursor_FunctionDecl) |> only
CLCursor (CLFunctionDecl) ExFunction(int, char *, float *)

julia> fdecl_children = [c for c in children(fdecl)]
4-element Array{CLCursor,1}:
 CLCursor (CLParmDecl) kind
 CLCursor (CLParmDecl) name
 CLCursor (CLParmDecl) data
 CLCursor (CLCompoundStmt)
```

前三个 `children` 是 `CLParmDecl` 游标，与函数签名中的参数同名。检查 `CLParmDecl` 游标的类型表明了与函数签名相似性：

```julia
julia> [Clang.getCursorType(t) for t in fdecl_children[1:3]]
3-element Array{CLType,1}:
 CLType (CLInt)     
 CLType (CLPointer)
 CLType (CLPointer)
```

最后，通过检索每个 `CLPointer` 参数的目标类型，确认这些游标代表了函数参数类型声明：

```julia
julia> [Clang.getPointeeType(Clang.getCursorType(t)) for t in fdecl_children[2:3]]
2-element Array{CLType,1}:
 CLType (CLChar_S)
 CLType (CLFloat)  
```

## 打印缩进游标层次结构

作为结尾示例，这是一个简单的缩进式 AST 打印机，它使用与 `CLType` 和 `CLCursor` 相关的函数，并利用了 Julia 类型系统的各个方面。

```julia
printind(ind::Int, st...) = println(join([repeat(" ", 2*ind), st...]))

printobj(cursor::CLCursor) = printobj(0, cursor)
printobj(t::CLType) = join(typeof(t), " ", spelling(t))
printobj(t::CLInt) = t
printobj(t::CLPointer) = Clang.getPointeeType(t)
printobj(ind::Int, t::CLType) = printind(ind, printobj(t))

function printobj(ind::Int, cursor::Union{CLFieldDecl, CLParmDecl})
    printind(ind+1, typeof(cursor), " ", printobj(Clang.getCursorType(cursor)), " ", name(cursor))
end

function printobj(ind::Int, node::Union{CLCursor, CLStructDecl, CLCompoundStmt,
                                        CLFunctionDecl, CLBinaryOperator})
    printind(ind, " ", typeof(node), " ", name(node))
    for c in children(node)
        printobj(ind + 1, c)
    end
end
```

```julia
julia> printobj(root_cursor)
 CLTranslationUnit example.h
   CLStructDecl ExStruct
      CLFieldDecl CLType (CLInt)  kind
      CLFieldDecl CLType (CLChar_S)  name
      CLFieldDecl CLType (CLFloat)  data
   CLFunctionDecl ExFunction(int, char *, float *)
      CLParmDecl CLType (CLInt)  kind
      CLParmDecl CLType (CLChar_S)  name
      CLParmDecl CLType (CLFloat)  data
     CLCompoundStmt
       CLDeclStmt
         CLVarDecl st
           CLTypeRef struct ExStruct
       CLBinaryOperator
         CLMemberRefExpr kind
           CLDeclRefExpr st
         CLUnexposedExpr kind
           CLDeclRefExpr kind
       CLBinaryOperator
         CLMemberRefExpr name
           CLDeclRefExpr st
         CLUnexposedExpr name
           CLDeclRefExpr name
       CLBinaryOperator
         CLMemberRefExpr data
           CLDeclRefExpr st
         CLUnexposedExpr data
           CLDeclRefExpr data
```

请注意，已为抽象的 `CLType` 和 `CLCursor` 类型定义了通用的 `printobj` 函数，并且使用多重分派为需要自定义行为的各种特定类型定义了打印器。特别是，以下函数处理所有需要递归打印子节点的游标类型：

```julia
function printobj(ind::Int, node::Union{CLCursor, CLStructDecl, CLCompoundStmt, CLFunctionDecl})
```

现在，`printobj` 已移至 Clang.jl 中，新名称为：`dumpobj`。

## 解析总结

如上所述，Clang.jl/libclang API 有几个关键方面：

* 代表 AST 的 Cursor 节点树，notes 有唯一的孩子。

* 每个 Cursor 节点都有一个 Julia 类型，用于标识节点表示的句法结构。

* 每个节点还有一个关联的 CLType，引用内部或用户定义的数据类型。

这篇文章省略了许多细节，特别是关于通过 libclang 可用的各种 `CLCursor` 和 `CLType` 表示。有关详细信息，请参阅 [libclang 文档](http://clang.llvm.org/doxygen/group__CINDEX.html)。

## 致谢

Eli Bendersky 的博文 [使用 Clang 在 Python 中解析 C++](http://eli.thegreenplace.net/2011/07/03/parsing-c-in-python-with-clang/) 是非常有用的参考。

