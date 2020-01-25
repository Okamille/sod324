# module NeighbourOperators

# using Random: randperm
# using Distributions: NegativeBinomial
# using StatsBase: sample, ProbabilityWeights
# using Solutions: Solution, swap!, permu!

# export small_shift!,
#        swap_close_planes!,
#        swap_close_costly_planes!,
#        permutation_operator!

function small_shift!(sol::Solution; p=0.5)
    n = sol.inst.nb_planes
    shifted_plane = sample(1:n)
    new_position = find_shift_destination(shifted_plane, p, n)
    shift!(sol, shifted_plane, new_position)
end

function shift_costly_plane!(sol::Solution; p=0.5)
    shifted_plane = cost_weighted_sample(sol)
    new_position = find_shift_destination(shifted_plane, p,
                                          sol.inst.nb_planes)
    shift!(sol, shifted_plane, new_position)
end

"""Given a position, returns a random but valid destination.

The size of the shift is a random variable 1 + X,
where X follows a Negative Binomial of parameters (1, p)
"""
function find_shift_destination(current_position::Int, p::Float64, n_planes::Int)
    negative_binomial = NegativeBinomial(1, p)
    direction = sample([-1, 1])
    norm = 1 + rand(negative_binomial)
    new_position = current_position + direction * norm
    new_position = min(max(new_position, 1), n_planes)
    return new_position
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
    swapped_plane_1_id = cost_weighted_sample(sol)
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


function cost_weighted_sample(sol::Solution)
    sample(1:sol.inst.nb_planes, ProbabilityWeights(sol.costs))
end

# end
