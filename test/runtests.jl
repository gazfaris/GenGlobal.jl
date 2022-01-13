using GenGlobal
using Test
using LinearAlgebra

using GenGlobal.testModule: set_globalx, get_globalx

@show dump(@GenGlobal somevar)

@testset "GenGlobal Tests" begin

    x = 1.0
    a = Matrix(1.0I,3,3)

    set_globalx(x)
    @test x === get_globalx()

    set_globalx(a)
    a === get_globalx()

    @test get_globalx() != x
    set_globalx(x)
    @test get_globalx() == x
    @test get_globalx() === x
    @test get_globalx() != a

end
