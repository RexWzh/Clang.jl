# Clang

这个包提供了一个用于 libclang 的 Julia 语言封装器：一个稳定的，C 导出的 LLVM Clang 编译器的接口。
[libclang API 文档](http://clang.llvm.org/doxygen/group__CINDEX.html) 提供了有关通过 libclang 可用的功能的背景信息，因此也可以通过 Julia 封装器使用。

## 安装

现在，该软件包在 Linux、macOS 和 Windows 上提供开箱即用的安装体验。你可以通过简单地运行下边代码来安装它：

```
pkg> add Clang
```

## C 绑定生成器

该软件包包括一个生成器，用于从一组头文件的 C 库创建 Julia 包装器。目前支持以下声明：

- `function`：翻译成 Julia ccall（关于可变参数函数的一些注意事项，参见 [Variadic Function](@ref)）

- `struct`：翻译成 Julia 结构

- `eznum`：翻译为 [`Enum`](https://docs.julialang.org/en/v1/base/base/#Base.Enums.Enum) 或 [`CEnum`](https://github.com/JuliaInterop/CEnum.jl)

- `union`：翻译成 Julia struct

- `typedef`：转换为 Julia typealias 以表示底层内置类型

- `macro`：有限的支持

- `bitfield`：实验性支持

以下示例包装了 `Clang_jll` 中的 `include/clang-c/*.h` 并将包装器打印到 `LibClang.jl`。

首先写一个配置脚本 `generator.toml`。

```toml
[general]
library_name = "libclang"
output_file_path = "./LibClang.jl"
module_name = "LibClang"
jll_pkg_name = "Clang_jll"
export_symbol_prefixes = ["CX", "clang_"]
```

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

!!! note "兼容性"
    上面的生成器是在 Clang.jl 0.14 中引入的。如果您使用的是旧版本的 Clang.jl，请查看 [旧版本文档](https://juliainterop.github.io/Clang.jl/v0.12/)

## LibClang

LibClang 是 libclang 的精简包装器。它一对一映射到 libclang API。 通过使用 `using Clang.LibClang`，所有以 `CX`/`clang_` 为前缀的 libclang API 都被导入到当前命名空间，您可以使用它从头开始构建自己的工具。如果你不熟悉 Clang AST，一个很好的初学教程是 [Introduction to the Clang AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html)。
