## Clang

[![CI](https://github.com/JuliaInterop/Clang.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/JuliaInterop/Clang.jl/actions/workflows/ci.yml)
[![TagBot](https://github.com/JuliaInterop/Clang.jl/actions/workflows/TagBot.yml/badge.svg)](https://github.com/JuliaInterop/Clang.jl/actions/workflows/TagBot.yml)
[![codecov](https://codecov.io/gh/JuliaInterop/Clang.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaInterop/Clang.jl)
[![docs-stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaInterop.github.io/Clang.jl/stable)
[![docs-dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaInterop.github.io/Clang.jl/dev)
[![GitHub Discussions](https://img.shields.io/github/discussions/JuliaInterop/Clang.jl)](https://github.com/JuliaInterop/Clang.jl/discussions)
[![Genie Downloads](https://shields.io/endpoint?url=https://pkgs.genieframework.com/api/v1/badge/Clang)](https://pkgs.genieframework.com?packages=Clang)

这个包提供了一个用于 libclang 的 Julia 语言封装器：一个稳定的，C 导出的 LLVM Clang 编译器的接口。
[libclang API 文档](http://clang.llvm.org/doxygen/group__CINDEX.html) 提供了有关通过 libclang 可用功能的背景信息，因此也可以通过 Julia 封装器使用。

## 安装

```
pkg> add Clang
```

如果你想使用旧的生成器（Clang.jl v0.13），请查看[这个分支](https://github.com/JuliaInterop/Clang.jl/tree/old-generator) 的文档。如果你有任何关于如何升级生成器脚本的问题，请随时在[讨论区](https://github.com/JuliaInterop/Clang.jl/discussions) 提交帖子/请求。

## 绑定生成器

Clang.jl 提供了一个模块 `Clang.Generators` 用于从 C 头文件自动生成 C 库的 Julia 语言绑定。

### 快速入门

编写一个配置文件 `generator.toml`：
```
[general]
library_name = "libclang"
output_file_path = "./LibClang.jl"
module_name = "LibClang"
jll_pkg_name = "Clang_jll"
export_symbol_prefixes = ["CX", "clang_"]
```

以及一个 Julia 脚本 `generator.jl`：
```julia
using Clang.Generators
using Clang.LibClang.Clang_jll  # replace this with your jll package

cd(@__DIR__)

include_dir = normpath(Clang_jll.artifact_dir, "include")
clang_dir = joinpath(include_dir, "clang-c")

options = load_options(joinpath(@__DIR__, "generator.toml"))

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()  # Note you must call this function firstly and then append your own flags
push!(args, "-I$include_dir")

headers = [joinpath(clang_dir, header) for header in readdir(clang_dir) if endswith(header, ".h")]
# there is also an experimental `detect_headers` function for auto-detecting top-level headers in the directory
# headers = detect_headers(clang_dir, args)

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
```

请参阅 [这个 toml 文件](https://github.com/JuliaInterop/Clang.jl/blob/master/gen/generator.toml) 以获取完整的配置选项列表。

### 示例

绑定生成器目前被 Julia 包生态系统中的许多项目使用，你可以将它们作为很好的示例。

- [JuliaInterop/Clang.jl](https://github.com/JuliaInterop/Clang.jl): 低级封装器 [LibClang.jl](./lib/14/LibClang.jl) 是由这个包自身生成的
- [JuliaSparse/SparseArrays.jl](https://github.com/JuliaSparse/SparseArrays.jl): 为 SuiteSparse 生成平台特定的绑定
- [maleadt/LLVM.jl](https://github.com/maleadt/LLVM.jl)：为 LLVM 生成平台特定的绑定（多个版本）
- [JuliaGPU/VulkanCore.jl](https://github.com/JuliaGPU/VulkanCore.jl)：为 Vulkan 生成平台特定的绑定，第三方 JLL 依赖项可选
- [JuliaGPU/oneAPI.jl](https://github.com/JuliaGPU/oneAPI.jl)：为 oneAPI 生成绑定，并使用 [JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl) 格式化生成的代码
- [JuliaGeo/GDAL.jl](https://github.com/JuliaGeo/GDAL.jl)：使用从 doxygen 中提取的自定义文档字符串为 GDAL 生成绑定
- [JuliaGeo/LibGEOS.jl](https://github.com/JuliaGeo/LibGEOS.jl)：使用自定义重写器为 LibGEOS 生成绑定
- [JuliaMultimedia/CSFML.jl](https://github.com/JuliaMultimedia/CSFML.jl)：使用多个库名称为 CSFML 生成绑定
- [SciML/Sundials.jl](https://github.com/SciML/Sundials.jl)：使用高度定制的重写器为 Sundials 生成绑定

其他用户：

- [CEED/libCEED](https://github.com/CEED/libCEED)：libCEED 的 Julia 绑定
- [JuliaGPU/CUDA.jl](https://github.com/JuliaGPU/CUDA.jl)：Julia 中的 CUDA 编程
- [scipopt/SCIP.jl](https://github.com/scipopt/SCIP.jl)：SCIP 求解器的 Julia 接口
- [JuliaParallel/MPI.jl](https://github.com/JuliaParallel/MPI.jl)：Julia 语言的 MPI 接口
- [JuliaGPU/Metal.jl](https://github.com/JuliaGPU/Metal.jl)：Julia 中的 Metal 编程
- [JuliaIO/VideoIO.jl](https://github.com/JuliaIO/VideoIO.jl)：在 Julia 中读写视频文件
- [JuliaGPU/AMDGPU.jl](https://github.com/JuliaGPU/AMDGPU.jl)：Julia 中的 AMD GPU（ROCm）编程
- [JuliaGeo/Proj.jl](https://github.com/JuliaGeo/Proj.jl)：PROJ 地图投影库的 Julia 封装器
- [JuliaIO/PNGFiles.jl](https://github.com/JuliaIO/PNGFiles.jl)：libpng 的 Julia 封装器
- [JuliaSparse/KLU.jl](https://github.com/JuliaSparse/KLU.jl)：SuiteSparse 求解器 KLU 的 Julia 封装器
- [JuliaGraphics/FreeType.jl](https://github.com/JuliaGraphics/FreeType.jl)：Julia 的 FreeType 绑定


