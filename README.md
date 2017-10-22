# GenGlobal

[![Build Status](https://travis-ci.org/magerton/GenGlobal.jl.svg?branch=master)](https://travis-ci.org/magerton/GenGlobal.jl)

[![Coverage Status](https://coveralls.io/repos/magerton/GenGlobal.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/magerton/GenGlobal.jl?branch=master)

[![codecov.io](http://codecov.io/github/magerton/GenGlobal.jl/coverage.svg?branch=master)](http://codecov.io/github/magerton/GenGlobal.jl?branch=master)

# Installing

Clone by running the following, and then package can be imported as usual.
```julia
Pkg.clone("https://github.com/magerton/GenGlobal.jl.git", "GenGlobal")
```

# Explanation

`@GenGlobal` declares expression to be a global variable and generates exported functions
`set_` and `get_` that set the global. Should be used in a module declaration. Thanks to @npfrazier for suggesting how to use global variables in parallel computations.

# Example

See [example/example.jl](example/example.jl) and [src/TestFunctions/testModule.jl](src/TestFunctions/testModule.jl) for how to use `GenGlobal` to (1) update a shared array, (2) compute things based on the values in the Shared Array, and (3) return all the computations. This is useful in problems like dynamic discrete choice models where the inner NFXP loop computes the Emax function / integrated value function in parallel, and the outer loop returns the log-likelihood and its gradient (for which we need the `pplus` and `remote_mapreduce` functions).


## Other examples

In the module
```julia
module mymodule

export dostuff

@GenGlobal myglob1 myglob2

dostuff(i::Int) = myglob1 * i

end
```

```julia-repl
using mymodule

dostuff(1)  # errors out

set_myglob1(1.0)
get_myglob1() == 1.0

dostuff(2) == 2.0
set_myglob1(2.0)
dostuff(4) == 2.0
```

# Example 2

Using `@GenGlobal` is one way to declare pre-allocated tmpvars for parallel
computations. Just make sure to annotate the type of the variables so that the compiler
knows what types are being used

```julia
module testModule

using GenGlobal
using StatsFuns

@GenGlobal globalx

export pplus, globf

pplus(x...) = broadcast(+, x...)

function globf(i::Int, s::T) where {T}
    y = logsumexp(globalx::Vector{T})
    return (y, fill(y, 2, 2), )
end

end # module end
```

```julia
using Base.Test
using BenchmarkTools
using testModule3

iters = 1:1000

addprocs()
@everywhere begin
    using testModule
    using StatsFuns
    rx = collect(1.:1000.)
    rxmyid = rx * myid()

    # to show that each worker has different variables...
    set_globalx(myid() * collect(1.:1000.))

    function fmyid(i::Int)
        y = logsumexp(rxmyid)
        return (y, fill(y, 2, 2), )
    end
end


# ---------- check on what gets computed ---------

plsemyid = @parallel (pplus) for i=iters
    fmyid(i)
end

gplse = @parallel (pplus) for i=iters
    globf(i, zero(Float64))
end

@show @benchmark mapreduce(fmyid, pplus, iters)

@show @benchmark begin
    @parallel (pplus) for i=iters
        f(i)
    end
end

@show @benchmark begin
    @parallel (pplus) for i=iters
        globf(i, zero(Float64))
    end
end
```
