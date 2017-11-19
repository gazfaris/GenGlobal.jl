using GenGlobal
using GenGlobal.testModule

# -----------------------------------------
# demo on global variables and GenGlobal
# -----------------------------------------

# GenGlobal.testModule defines a global "globalx"

# set a global variable's value in another module
set_globalx(3)

# globalx not available in Main
try
    @show globalx
catch e
    println(e)
end

# but it is through module
@show GenGlobal.testModule.globalx

# Can't set global normally
try
    GenGlobal.testModule.globalx = 2
catch e
    @show e
end

# so use the generated functions
set_globalx(2)
@show get_globalx()

# -----------------------------------------
# Parallel computing & GenGlobal
# -----------------------------------------

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
# Can set up temp arrays on remotes this way
@eval @everywhere begin
    set_globalx(3)
    set_g_sa($bigsa)
    set_g_ysame2(zeros(2,2))
    set_g_ydiff2(zeros(2,2))
end


# matrix of zeros
@show bigsa

# Update large shared array slice by slice
# sa[i,j] = i
s = @sync @parallel for j in 1:ncols
    update_shared!(j)  # sets      g_sa[:,j] = 1:end
end
@show fetch.(s)
@show bigsa

# Compute things based on the shared array
# For example, can compute likelihood this way, and possibly gradient
s = @sync @parallel (pplus) for j in 1:ncols
    compute_shared(j)  # for each j, compute logsumexp(g_sa[:,j]) and add to ysame2. Add myid() to ydiff2
end
@show s

# Show what the different matrices are
@everywhere @show get_y2()

# add them up!
# Example: have each worker compute part of likelihood + gradient, then add up partial gradients on each worker 
remote_mapreduce(get_y2, pplus)





#
