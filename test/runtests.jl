using GenGlobal
using GenGlobal.testModule
using Test
using LinearAlgebra

dump(@GenGlobal somevar)

x = 1.0
set_myglobalx(x)
@test myglobalx === get_myglobalx()

a = Matrix(1.0I,3,3)
set_myglobalx(a)
a === get_myglobalx()

@test myglobalx != x
set_myglobalx(x)
@test myglobalx == x
@test get_myglobalx() != a
