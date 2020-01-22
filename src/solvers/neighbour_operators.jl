# module NeighbourOperators

# using Random: randperm
# using StatsBase: sample
# using Solutions: Solution, swap!, permu!

# export swap_operator!, permutation_operator!

function swap_operator!(sol::Solution)
    swap!(sol)
end

function permutation_operator!(sol::Solution; permuted_ratio=0.1)
    n_permuted_planes = Int(round(permuted_ratio * sol.inst.nb_planes))
    if n_permuted_planes <= 2
        swap!(sol)
    else
        permuted_planes = sample(1:sol.inst.nb_planes, n_permuted_planes,
                                replace=false)
        permu!(sol, permuted_planes,
               permuted_planes[randperm(length(permuted_planes))])
    end
end

# end
