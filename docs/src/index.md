# Clang
This package provides a Julia language wrapper for libclang: the stable, C-exported
interface to the LLVM Clang compiler. The [libclang API documentation](http://clang.llvm.org/doxygen/group__CINDEX.html) provides background on the functionality available through libclang, and thus through the Julia wrapper. The repository also hosts related tools built on top of libclang functionality.

这个包提供了一个用于 libclang 的 Julia 语言封装器：一个稳定的，C 导出的 LLVM Clang 编译器的接口。
[libclang API 文档](http://clang.llvm.org/doxygen/group__CINDEX.html) 提供了有关通过 libclang 可用的功能的背景信息，因此也可以通过 Julia 封装器使用。


## Installation

## 安装

Now, the package provides an out-of-box installation experience on Linux, macOS and Windows. You could simply install it by running:

现在，该软件包在 Linux、macOS 和 Windows 上提供开箱即用的安装体验。你可以通过简单地运行下边代码来安装它：

```
pkg> add Clang
```

## C-bindings generator

## C 绑定生成器


The package includes a generator to create Julia wrappers for C libraries from a collection of header files. The following declarations are currently supported:

该软件包包括一个生成器，用于从一组头文件的 C 库创建 Julia 包装器。目前支持以下声明：

- function: translated to Julia ccall (some caveats about variadic functions, see [Variadic Function](@ref))

- `function`：翻译成 Julia ccall（关于可变参数函数的一些注意事项，参见 [Variadic Function](@ref)）


- struct: translated to Julia struct

- `struct`：翻译成 Julia 结构


- eznum: translated to [`Enum`](https://docs.julialang.org/en/v1/base/base/#Base.Enums.Enum) or [`CEnum`](https://github.com/JuliaInterop/CEnum.jl)

- `eznum`：翻译为 [`Enum`](https://docs.julialang.org/en/v1/base/base/#Base.Enums.Enum) 或 [`CEnum`](https://github.com/JuliaInterop/CEnum.jl)


- union: translated to Julia struct

- `union`：翻译成 Julia struct


- typedef: translated to Julia typealias to underlying intrinsic type

- `typedef`：转换为 Julia typealias 以表示底层内置类型


- macro: limited support

- `macro`：有限的支持


- bitfield: experimental support

- `bitfield`：实验性支持


The following example wraps `include/clang-c/*.h` from `Clang_jll` and prints the wrapper to `LibClang.jl`.

以下示例包装了 `Clang_jll` 中的 `include/clang-c/*.h` 并将包装器打印到 `LibClang.jl`。


First write a configuration script `generator.toml`.

首先写一个配置脚本 `generator.toml`。

```toml
[general]
library_name = "libclang"
output_file_path = "./LibClang.jl"
module_name = "LibClang"
jll_pkg_name = "Clang_jll"
export_symbol_prefixes = ["CX", "clang_"]
```


Then load the configurations and generate a wrapper.

然后加载配置并生成封装器。

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

!!! "兼容性"

    The generator above is introduced in Clang.jl 0.14. If you are working with older versions of Clang.jl, check [older versions of documentation](https://juliainterop.github.io/Clang.jl/v0.12/)

    上面的生成器是在 Clang.jl 0.14 中引入的。如果您使用的是旧版本的 Clang.jl，请查看 [旧版本文档](https://juliainterop.github.io/Clang.jl/v0.12/)


## LibClang

## LibClang

LibClang is a thin wrapper over libclang. It's one-to-one mapped to the libclang APIs.
By `using Clang.LibClang`, all of the `CX`/`clang_`-prefixed libclang APIs are imported into the current namespace, with which you could build up your own tools from scratch. If you are unfamiliar with the Clang AST, a good starting point is the [Introduction to the Clang AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html).

LibClang 是 libclang 的精简包装器。它一对一映射到 libclang API。 通过使用 `using Clang.LibClang`，所有以 `CX`/`clang_` 为前缀的 libclang API 都被导入到当前命名空间，您可以使用它从头开始构建自己的工具。如果你不熟悉 Clang AST，一个很好的初学教程是 [Introduction to the Clang AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html)。
