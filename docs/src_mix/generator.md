
# Generator Tutorial

# 生成器教程

## Tutorial on wrapping a JLL package

## 包装 JLL 包的教程

In most situations, Clang.jl is used to export a Julia interface to a C library managed by a JLL package. A JLL package wraps an artifact which provides a shared library that can be called with the `ccall` syntax and headers suitable for a C compiler. Clang.jl can translate the C headers into Julia files that can be directly used like normal Julia functions and types.

在大多数情况下，Clang.jl 用于将 Julia 接口导出到由 JLL 包管理的 C 库。 JLL 包包装了一个工件，它提供了一个共享库，可以使用适用于 C 编译器的 ccall 语法和标头进行调用。 Clang.jl 可以将 C 头文件翻译成 Julia 文件，这些文件可以像普通的 Julia 函数和类型一样直接使用。


The general workflow of wrapping a JLL package is as follows.

包装 JLL 包的一般工作流程如下。


1. Locate the C headers relative to the artifact directory.

1. 找到与工件目录相关的 C 头文件。


2. Find the compiler flags needed to parse these headers.

2. 找到解析这些标头所需的编译器标志。


3. Create a `.toml` file with generator options.

3. 使用生成器选项创建一个 .toml 文件。


4. Build a context with the above three and run.

4.用以上三者搭建context并运行。


5. Test and troubleshoot the wrapper.

5. 对包装器进行测试和故障排除。


### Create a default generator

### 创建默认生成器


A generator context consists of a list of headers, a list of compiler flags, and generator options. The example below creates a typical context and runs the generator.

生成器上下文由标题列表、编译器标志列表和生成器选项组成。下面的示例创建一个典型的上下文并运行生成器。

```julia
using Clang.Generators
using Clang.LibClang.Clang_jll

cd(@__DIR__)

include_dir = normpath(Clang_jll.artifact_dir, "include")

# wrapper generator options
options = load_options(joinpath(@__DIR__, "generator.toml"))

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()
push!(args, "-I$include_dir")

# only wrap libclang headers in include/clang-c
header_dir = joinpath(include_dir, "clang-c")
headers = [joinpath(header_dir, header) for header in readdir(header_dir) if endswith(header, ".h")]

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
```


You can also use the experimental `detect_headers` function to automatically detect top-level headers in the directory.

您还可以使用实验性的“detect_headers”功能自动检测目录中的顶级标头。

```julia
headers = detect_headers(header_dir, args)
```


You also need an options file `generator.toml` that to make this script work, you can refer to [this toml file](https://github.com/JuliaInterop/Clang.jl/blob/master/gen/generator.toml) for a reference.

您还需要一个选项文件 `generator.toml` 来使这个脚本工作，您可以参考 [this toml file](https://github.com/JuliaInterop/Clang.jl/blob/master/gen/generator. toml) 供参考。


### Skipping specific symbols

### 跳过特定符号


The C header may contain some symbols that are not correctly handled by Clang.jl or may need manual wrapping. For example, julia provides `tm` as `Libc.TmStruct`, so you may not want to map it to a new struct. As a workaround, you can skip these symbols. After that, if this symbol is needed, you can add it back in the prologue. Prologue is specified by the `prologue_file_path` option.

标头可能包含一些未被 Clang.jl 正确处理的符号，或者可能需要手动换行。例如，julia 将 `tm` 提供为 `Libc.TmStruct`，因此您可能不想将其映射到新结构。作为解决方法，您可以跳过这些符号。之后，如果需要此符号，您可以将其添加回序言中。 Prologue 由 `prologue_file_path` 选项指定。


* Add the symbol to `output_ignorelist` to avoid it from being wrapped.

* 将符号添加到 `output_ignorelist` 以避免它被包装。


* If the symbol is in system headers and causes Clang.jl to error before printing, apart from posting an issue, write `@add_def symbol_name` before generating to suppress it from being wrapped.

如果符号在系统头文件中并导致 Clang.jl 在打印前出错，除了发布问题外，在生成之前写入 `@add_def symbol_name` 以抑制它被包装。


### Rewrite expressions before printing

### 打印前重写表达式


You can also modify the generated wrapped before it is printed. Clang.jl separates the building process into generating and printing processes. You can run these two processes separately and rewrite the expressions before printing.

您还可以在打印之前修改生成的包装。 Clang.jl 将构建过程分为生成和打印过程。您可以分别运行这两个过程并在打印前重写表达式。

```julia
# build without printing so we can do custom rewriting
build!(ctx, BUILDSTAGE_NO_PRINTING)

# custom rewriter
function rewrite!(e::Expr)
end

function rewrite!(dag::ExprDAG)
    for node in get_nodes(dag)
        for expr in get_exprs(node)
            rewrite!(expr)
        end
    end
end

rewrite!(ctx.dag)

# print
build!(ctx, BUILDSTAGE_PRINTING_ONLY)
```


### Multi-platform configuration

### 多平台配置


Some headers may contain system-dependent symbols such as `long` or `char`, or system-independent symbols may be resolved to system-dependent ones. For example, `time_t` is usually just a 64-bit unsigned integer, but implementations may conditionally implement it as `long` or `long long`, which is not portable. You can skip these symbols and add them back manually as in [Skipping specific symbols](@ref). If the differences are too large to be manually fixed, you can generate wrappers for each platform as in [LibClang.jl](https://github.com/Gnimuc/LibClang.jl/blob/v0.61.0/gen/generator.jl).

一些标头可能包含与系统相关的符号，例如“long”或“char”，或者与系统无关的符号可能会解析为与系统相关的符号。例如，`time_t` 通常只是一个 64 位无符号整数，但实现可能有条件地将其实现为 `long` 或 `long long`，这是不可移植的。您可以跳过这些符号并手动将它们添加回来，如 [跳过特定符号](@ref)。如果差异太大而无法手动修复，您可以为每个平台生成包装器，如 [LibClang.jl](https://github.com/Gnimuc/LibClang.jl/blob/v0.61.0/gen/generator。 jl).


## Variadic Function

## 可变参数函数


With the help of `@ccall` macro, variadic C functions can be called from Julia. For example, `@ccall printf("%d\n"::Cstring; 123::Cint)::Cint` can be used to call the C function `printf`. Note that those arguments after the semicolon `;` are variadic arguments.

在 @ccall 宏的帮助下，可以从 Julia 调用可变参数 C 函数。例如，`@ccall printf("%d\n"::Cstring; 123::Cint::Cint` 可用于调用 C 函数 `printf`。请注意，分号“;”之后的那些参数是可变参数。


If `wrap_variadic_function` in `codegen` section of options is set to `true`, `Clang.jl` will generate wrappers for variadic C functions. For example, `printf` will be wrapped as follows.

如果选项的 codegen 部分中的 wrap_variadic_function 设置为 true，则 Clang.jl 将为可变 C 函数生成包装器。例如，`printf` 将被包装如下。

```julia
@generated function printf(fmt, va_list...)
        :(@ccall(libexample.printf(fmt::Ptr{Cchar}; $(to_c_type_pairs(va_list)...))::Cint))
    end
```


It can be called just like normal Julia functions without specifying types: `LibExample.printf("%d\n", 123)`.

它可以像普通的 Julia 函数一样调用而无需指定类型：`LibExample.printf("%d\n", 123)`。


!!! note

！！！笔记


    Although variadic functions are supported, the C type `va_list` cannot be used from Julia.

尽管支持可变参数函数，但不能在 Julia 中使用 C 类型 `va_list`。


### Type Correspondence

### 类型对应


However, variadic C functions must be called with the correct argument types. The most useful ones are listed below.

但是，必须使用正确的参数类型调用可变参数 C 函数。下面列出了最有用的。


| C type                              | ccall signature                                  | Julia type                             |

| C型 | ccall 签名 |朱莉娅型 |


|-------------------------------------|--------------------------------------------------|----------------------------------------|

|------------------------------------|------------ --------------------------------------|---------- ------------------------------|


| Integers and floating point numbers | the same type                                    | the same type                          |

|整数和浮点数 |同类型 |同类型 |


| Struct `T`                          | a concrete Julia struct `T` with the same layout | `T`                                    |

|结构`T` |具有相同布局的具体 Julia 结构 `T` | `T` |


| Pointer (`T*`)                      | `Ref{T}` or `Ptr{T}`                             | `Ref{T}` or `Ptr{T}` or any array type |

|指针 (`T*`) | `Ref{T}` 或 `Ptr{T}` | `Ref{T}` 或 `Ptr{T}` 或任何数组类型 |


| String (`char*`)                    | `Cstring` or `Ptr{Cchar}`                        | `String`                               |

|字符串 (`char*`) | `Cstring` 或 `Ptr{Cchar}` | `字符串` |


!!! note

！！！笔记


    `Ref` is not a concrete type but an abstract type in Julia. For example, `Ref(1)` is `Base.RefValue(1)`, which cannot be directly passed to C.

`Ref` 在 Julia 中不是具体类型而是抽象类型。比如`Ref(1)`就是`Base.RefValue(1)`，不能直接传给C。


As observed from the table, if you want to pass strings or arrays to C, you need to annotate the type as `Ptr{T}` or `Ref{T}` (or `Cstring`). Otherwise, the struct that represents the `String` or `Array` type instead of the buffer itself will be passed. There are two methods to pass arguments of these types:

从表中可以看出，如果要将字符串或数组传递给 C，则需要将类型注释为 `Ptr{T}` 或 `Ref{T}`（或 `Cstring`）。否则，将传递表示“String”或“Array”类型而不是缓冲区本身的结构。有两种方法可以传递这些类型的参数：


* Directly use the @ccall macro: `@ccall printf("%s\n"; "hello"::Cstring)::Cint`. You can also create wrappers for common use cases of this.

直接使用@ccall 宏：`@ccall printf("%s\n"; "hello"::Cstring)::Cint`。您还可以为此的常见用例创建包装器。


* Overload `to_c_type` to map Julia type to correct ccall signature type: add `to_c_type(::Type{String}) = Cstring` to prologue (prologue can be added by setting `prologue_file_path` in options). Then all arguments of type `String` will be annotated as `Cstring`.

* 重载 `to_c_type` 以将 Julia 类型映射到正确的 ccall 签名类型：将 `to_c_type(::Type{String}) = Cstring` 添加到序言（可以通过在选项中设置 `prologue_file_path` 来添加序言）。然后所有类型为 String 的参数都将被注释为 Cstring。


The above type correspondence can be implemented by including the following lines in the prologue.

上面的类型对应可以通过在序言中包含以下几行来实现。

```julia
to_c_type(::Type{<:AbstractString}) = Cstring # or Ptr{Cchar}
to_c_type(t::Type{<:Union{AbstractArray,Ref}}) = Ptr{eltype(t)}
```


For a complete tutorial on calling C functions, refer to [Calling C and Fortran Code](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/#Calling-C-and-Fortran-Code) in the Julia manual.

有关调用 C 函数的完整教程，请参阅 [调用 C 和 Fortran 代码](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/#Calling-C- and-Fortran-Code) 在 Julia 手册中。

