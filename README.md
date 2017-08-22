# GenGlobal

[![Build Status](https://travis-ci.org/magerton/GenGlobal.jl.svg?branch=master)](https://travis-ci.org/magerton/GenGlobal.jl)

[![Coverage Status](https://coveralls.io/repos/magerton/GenGlobal.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/magerton/GenGlobal.jl?branch=master)

[![codecov.io](http://codecov.io/github/magerton/GenGlobal.jl/coverage.svg?branch=master)](http://codecov.io/github/magerton/GenGlobal.jl?branch=master)

# Explanation

`@GenGlobal` declares expression to be a global variable and generates exported functions
`set_` and `get_` that set the global. Should be used in a module declaration.

# Example
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
