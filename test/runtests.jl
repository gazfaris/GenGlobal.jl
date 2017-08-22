using GenGlobal
using Base.Test

dump(@GenGlobal somevar)

module mytest
 using GenGlobal
 @GenGlobal myglobalx
end

using mytest

x = 1.0
set_myglobalx(x)
@test mytest.myglobalx === get_myglobalx()

a = eye(3)
set_myglobalx(a)
a === get_myglobalx()

@test mytest.myglobalx != x
set_myglobalx(x)
@test mytest.myglobalx == x
@test get_myglobalx() != a
