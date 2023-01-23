
# Clang

# 铿锵声


This package provides a Julia language wrapper for libclang: the stable, C-exported

这个包为 libclang 提供了一个 Julia 语言包装器：稳定的，C-exported


interface to the LLVM Clang compiler. The [libclang API documentation](http://clang.llvm.org/doxygen/group__CINDEX.html)

LLVM Clang 编译器的接口。 [libclang API 文档](http://clang.llvm.org/doxygen/group__CINDEX.html)


provides background on the functionality available through libclang, and thus

提供有关通过 libclang 可用的功能的背景，因此


through the Julia wrapper. The repository also hosts related tools built

通过 Julia 包装器。该存储库还托管构建的相关工具


on top of libclang functionality.

在 libclang 功能之上。


## Installation

＃＃ 安装


Now, the package provides an out-of-box installation experience on Linux, macOS and Windows. You

现在，该软件包在 Linux、macOS 和 Windows 上提供开箱即用的安装体验。你


could simply install it by running:

可以通过运行简单地安装它：

```
pkg> add Clang
```


## C-bindings generator

## C 绑定生成器


The package includes a generator to create Julia wrappers for C libraries from a collection of header files. The following declarations are currently supported:

该软件包包括一个生成器，用于从一组头文件中为 C 库创建 Julia 包装器。目前支持以下声明：


- function: translated to Julia ccall (some caveats about variadic functions, see [Variadic Function](@ref))

- 函数：翻译成 Julia ccall（关于可变参数函数的一些注意事项，参见 [Variadic Function](@ref)）


- struct: translated to Julia struct

- 结构：翻译成 Julia 结构


- enum: translated to [`Enum`](https://docs.julialang.org/en/v1/base/base/#Base.Enums.Enum) or [`CEnum`](https://github.com/JuliaInterop/CEnum.jl)

枚举：翻译为 [`Enum`](https://docs.julialang.org/en/v1/base/base/#Base.Enums.Enum) 或 [`CEnum`](https://github.com /JuliaInterop/CEnum.jl)


- union: translated to Julia struct

- union：翻译成 Julia struct


- typedef: translated to Julia typealias to underlying intrinsic type

- typedef：转换为 Julia typealias 为底层固有类型


- macro: limited support

宏观：有限的支持


- bitfield: experimental support

位域：实验支持


The following example wraps `include/clang-c/*.h` from `Clang_jll` and prints the wrapper to `LibClang.jl`.

以下示例包装了 `Clang_jll` 中的 `include/clang-c/*.h` 并将包装器打印到 `LibClang.jl`。


First write a configuration script `generator.toml`.

首先写一个配置脚本`generator.toml`。

```toml
[general]
library_name = "libclang"
output_file_path = "./LibClang.jl"
module_name = "LibClang"
jll_pkg_name = "Clang_jll"
export_symbol_prefixes = ["CX", "clang_"]
```


Then load the configurations and generate a wrapper.

然后加载配置并生成包装器。

```julia
using Clang.Generators
using Clang.LibClang.Clang_jll

cd(@__DIR__)

include_dir = normpath(Clang_jll.artifact_dir, "include")
clang_dir = joinpath(include_dir, "clang-c")

# wrapper generator options
options = load_options(joinpath(@__DIR__, "generator.toml"))

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()
push!(args, "-I$include_dir")

headers = [joinpath(clang_dir, header) for header in readdir(clang_dir) if endswith(header, ".h")]
# there is also an experimental `detect_headers` function for auto-detecting top-level headers in the directory
# headers = detect_headers(clang_dir, args)

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
```


!!! note "Compatibility"

！！！注意“兼容性”


    

missing


    The generator above is introduced in Clang.jl 0.14. If you are working with older versions of Clang.jl, check [older versions of documentation](https://juliainterop.github.io/Clang.jl/v0.12/)

上面的生成器是在 Clang.jl 0.14 中引入的。如果您使用的是旧版本的 Clang.jl，请查看 [旧版本文档](https://juliainterop.github.io/Clang.jl/v0.12/)


## LibClang

## 库朗


LibClang is a thin wrapper over libclang. It's one-to-one mapped to the libclang APIs.

LibClang 是 libclang 的精简包装器。它一对一映射到 libclang API。


By `using Clang.LibClang`, all of the `CX`/`clang_`-prefixed libclang APIs are imported into the

通过“使用 Clang.LibClang”，所有以“CX”/“clang_”为前缀的 libclang API 都被导入到


current namespace, with which you could build up your own tools from scratch. If you are

当前命名空间，您可以使用它从头开始构建自己的工具。如果你是


unfamiliar with the Clang AST, a good starting point is the [Introduction to the Clang AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html).

不熟悉 Clang AST，一个好的起点是 [Introduction to the Clang AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html)。

