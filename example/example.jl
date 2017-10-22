using GenGlobal
using GenGlobal.testModule

# initialize workers
pids = addprocs()

# initialize a shared array visible to each worker in pids
ncols = 20
bigsa = SharedArray{Float64}(10,ncols)

# tell globals about the modules
@everywhere begin
    using GenGlobal
    using GenGlobal.testModule
end

# set globals in each worker
@eval @everywhere begin
    set_g_sa($bigsa)
    set_g_ysame2(zeros(2,2))
    set_g_ydiff2(zeros(2,2))
end

# matrix of zeros
@show bigsa

# sa[i,j] = i
s = @sync @parallel for j in 1:ncols
    update_shared!(j)
end
@show fetch.(s)
@show bigsa

# now compute the sums
s = @sync @parallel (pplus) for j in 1:ncols
    compute_shared(j)
end
@show s

# Show what the different matrices are
@everywhere @show get_y2()

# add them up!
remote_mapreduce(get_y2, pplus)
