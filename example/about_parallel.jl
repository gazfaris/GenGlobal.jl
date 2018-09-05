# These notes are partly based on Michael Shashoua's notes on parallelization. Thanks, Michael!
#     https://economics.rice.edu/students/michael-shashoua
# See also https://juliaeconomics.com/2014/06/18/parallel-processing-in-julia-bootstrapping-the-mle/


# ------------------------------------------------
# Starting workers
# ------------------------------------------------

myid()             # Master is always "1"
workers()          # Return vector of worker IDs
addprocs(2)        # Add workers. Good to add as many as CPU CORES
@show Sys.CPU_CORES      # this is the number of hyper-threading cores (NOT PHYSICAL)
rmprocs(workers()) # get rid of all workers

@show addprocs()  # Defaults to number of virtual cores
@show procs()     # Master + workers
@show workers()   # workers only

# doing stuff on the workers
@everywhere println(myid()) # @everywhere macro will have each process return info
@show fetch(@spawn myid())        # @spawn will go through the different workers
@show fetch(@spawnat workers()[2] myid())    # @spawnat will be directed to a specific worker

# ------------------------------------------------
# Getting data on workers
# ------------------------------------------------

data_example = 54 # "data_example" has value of 54 only for the Master
@everywhere try
    println(data_example)
  catch e
    println(e)
end


# to send arrays, data, etc use @eval
@eval @everywhere begin
  data_example1 = 54+3
  data_example2 = $data_example+2
  println((data_example1,data_example2,))
end


# This works the same with packages.
using Distributions  # load pkg on the master, but not workers
@everywhere begin
  try
    println(rand(Normal(0,1)))
  catch e
    println(e)
  end
end

# NOTE: have to load pkg on master first before loading on worker
@everywhere begin
  using Distributions
  println(rand(Normal(0,1)))

  function exmp(n)
    println("worker $myid() will draw $n random values")
    rand(n)
  end
end

val = pmap(exmp,[1,3,4,10])
@show valcat = vcat(val...)
rmprocs(workers())


# ------------------------------------------------
# Doing things in parallel
# ------------------------------------------------

#=
2 main options: pmap and @distributed

- pmap([::AbstractWorkerPool], f, c...)
    + like a parallel map function that returns a Vector{Any}
    + If needing to move data, make sure to use a CachingPool(), not a WorkerPool()
    + Allocates tasks 1 at a time to different workers.
    + Better if tasks take different amounts of time
- @distributed
    + can be put in front of a loop to make it run over all available workers
    + Usually want to prefix w/ @sync if not a reduction... otherwise code won't wait on workers
    + can also be made into a reduction
    + Divides up index into big chunks and gives each worker a section
    + Best when tasks take same amount of time
=#


# Example 1: Simulating Heads or Tails with parallel reduction
tic()
nheads = @sync @distributed (+) for i=1:8
  sleep(1)
  println(i)
  Int(rand(Bool))
end
toc()


addprocs()

tic()
nheads = @sync @distributed (+) for i=1:8
  sleep(1)
  println(i)
  Int(rand(Bool))
end
toc()



# EXAMPLE 2: FINDING Area under a curve
NITER = 2000000000
rmprocs(workers())
f(i::Int) = rand()^2 + rand()^2 <= 1 ? 1 : 0

sleep(1)

tic()
srand(1234)
out = @sync @distributed (+) for i = 1:NITER
  f(i)
end
println(out / NITER)
toc()

addprocs()
@eval @everywhere g(i::Int) = rand()^2 + rand()^2 <= 1 ? 1 : 0


tic()
srand(1234)
inside = @sync @distributed (+) for i = 1:NITER
  g(i)
end
println(inside / NITER)
toc()


# ------------------------------------------------
# Working on big arrays together
# ------------------------------------------------

#=
- SharedArray{T,N}(dims::NTuple; init=false, pids=Int[])
  + each “participating” process has access to the entire array,
  + participating workers specified by the pids named argument
- DistributedArray
  + each worker "owns" a particular subset of array and can't see the rest
=#

# Workers can't see this array on master
rmprocs(workers())
addprocs()
a = zeros(Int, 10)
s = @sync @distributed for i in eachindex(a)
  a[i] = myid()
  println(i)
end
@show a


# SharedArray(T::Type, dims::NTuple; init=false, pids=Int[])=
b = SharedArray(Int, 10)
fill!(b, 0)
s = @sync @distributed for i in eachindex(b)
  b[i] = myid()
  println(i)
end
@show b

rmprocs(workers())


# ------------------------------------------------
# Jedi tricks
# ------------------------------------------------

#=
- Easiest to load things on workers by "using" an entire module
- Can define global variables in a module
  + that can only be seen by that module...
  + and only modified from w/ in module
  + functions in the module can use the globals if "global" keyword given
- Problem: globals are not typed, so compiler can't optimize
- Solution
  + Annotate types of globals when used in function arguments
    * Must be CONCRETE
    * eg, Array{Real} does not help, but Matrix{Int} does.
  + "function-barrier" technique: outer wrapper + inner function
- Set global variables (like data) using module functions

=#
