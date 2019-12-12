module testModule

using Distributed
using GenGlobal
using StatsFuns
using SharedArrays

@GenGlobal globalx g_ysame2 g_ydiff2 g_sa
@GenGlobal myglobalx

export pplus, globf, update_shared!, compute_shared, remote_mapreduce, get_y2, myglobalx

pplus(x...) = broadcast(+, x...)

"each worker in `pids` returns `f()`, and results are reduced using `R()`"
remote_mapreduce(pids::AbstractVector{<:Integer}, f::Function, R::Function) = mapreduce((p::Int) -> remotecall_fetch(f, p), R, pids )

"each worker returns `f()`, and results are reduced using `R()`"
remote_mapreduce(f::Function, R::Function) = remote_mapreduce(workers(), f, R)


"set sa[i,j] = i ∀ i,j"
function update_shared!(sa::SharedArray{T,2}, j::Integer) where {T}
    # This is the inner function
    j ∈ 1:size(sa,2) || throw(DomainError())
    @views sa_vw = sa[:,j]
    for i in eachindex(sa_vw)
        sa_vw[i] = i
    end
end

# This is the "outer-wrapper" for above & ensures type-stability
function update_shared!(j::Integer)
    global g_sa
    update_shared!(g_sa, j)
end

"return `logsumexp(sa[:,j])` and `myid()`... as well as adding these to `ysame2` and `ydiff2`"
function compute_shared(sa::SharedArray{T,2}, j::Integer, ysame2::Matrix{T}, ydiff2::Matrix{T}) where {T}
    @views sa_vw = sa[:,j]
    ysame = logsumexp(sa_vw)
    ydiff = myid()
    ysame2 .+= ysame
    ydiff2 .+= ydiff
    return ysame, ydiff
end

function compute_shared(j::Integer)
    global g_sa
    global g_ysame2
    global g_ydiff2
    compute_shared(g_sa, j, g_ysame2, g_ydiff2)
end

"return global y2s as tuple from a worker"
function get_y2()
    # could also be done as get_y2() = (get_g_ysame2(), get_g_ydiff2(), )
    global g_ysame2
    global g_ydiff2
    return (g_ysame2, g_ydiff2,)
end


end # module end
