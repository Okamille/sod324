# module NeighbourOperators

# using Random: randperm
# using StatsBase: sample
# using Solutions: Solution, swap!, permu!

# export swap_operator!, permutation_operator!

function swap_operator!(sol::Solution)
    swap!(sol)
end

function permutation_operator!(sol::Solution; permuted_ratio=0.1)
    n_permuted_planes = Int(round(permuted_ratio * sol.nb_planes))
    permuted_planes = sample(1:sol.nb_planes, n_permuted_planes,
                             replace=false)
    permu!(sol, permuted_planes, randperm(permuted_planes))
end

# end
