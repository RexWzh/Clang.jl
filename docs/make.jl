using Clang
using Clang.LibClang
using Documenter

makedocs(;
    modules=[Clang, Clang.LibClang],
    repo="https://github.com/rexwzh/Clang.jl/blob/{commit}{path}#L{line}",
    sitename="Clang.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://rexwzh.github.io/Clang.jl",
        assets=String[],
    ),
    pages = ["介绍" => "index.md",
         "生成器教程" => "generator.md",
         "LibClang 教程" => "tutorial.md",
         "LibClang 封装器的 API 参考" => "libclang.md",
         "Clang 的 API 参考" => "api.md",
        ],
)


deploydocs(; repo="github.com/RexWzh/Clang.jl.git"
           , devurl = "dev"
           , devbranch = ＂dev＂
           , versions = ["stable" => "v^", "dev" => "dev"])
