# module NeighbourOperators

# using Random: randperm
# using StatsBase: sample, ProbabilityWeights
# using Solutions: Solution, swap!, permu!

# export swap_operator!,
#        swap_close_planes!,
#        swap_close_costly_planes!,
#        permutation_operator!


function swap_operator!(sol::Solution)
    swap!(sol)
end

"""Swaps a random plane and one of its neighbour."""
function swap_close_planes!(sol::Solution)
    n = sol.inst.nb_planes
    swapped_plane_1_id = sample(1:n)
    if swapped_plane_1_id == n
        swapped_plane_2_id = n-1
    elseif swapped_plane_1_id == 1
        swapped_plane_2_id = 2
    else
        swapped_plane_2_id = swapped_plane_1_id + sample([-1, 1])
    end
    swap!(sol, swapped_plane_1_id, swapped_plane_2_id)
end

"""Swaps a random plane according to the cost distribution and one of its neighbour."""
function swap_close_costly_planes!(sol::Solution)
    n = sol.inst.nb_planes
    cost_distribution = ProbabilityWeights(sol.costs)
    swapped_plane_1_id = sample(1:n, cost_distribution)
    if swapped_plane_1_id == n
        swapped_plane_2_id = n-1
    elseif swapped_plane_1_id == 1
        swapped_plane_2_id = 2
    else
        swapped_plane_2_id = swapped_plane_1_id + sample([-1, 1])
    end
    swap!(sol, swapped_plane_1_id, swapped_plane_2_id)
end

function permutation_operator!(sol::Solution; permuted_ratio=0.1)
    n_permuted_planes = Int(round(permuted_ratio * sol.inst.nb_planes))
    println(n_permuted_planes)
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
