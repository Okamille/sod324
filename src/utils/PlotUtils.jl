"""Plotting and saving utilities."""
module PlotUtils

import PyPlot; const plt = PyPlot
using DelimitedFiles: writedlm

export plot_save_costs, plot_costs, save_costs

"""Plots and saves a costs vector."""
function plot_save_costs(costs, path::String; plot=false, save=false)
    if plot
        plot_costs(costs, path)
    end
    if save
        save_costs(costs, path)
    end
end

"""Plots and saves a costs vector."""
function plot_save_costs(costs, steps, path::String; plot=false, save=false)
    if plot
        plot_costs(costs, steps, path)
    end
    if save
        save_costs(costs, steps, path)
    end
end

"""Plots a cost vector."""
function plot_costs(costs, path::String)
    plt.plot(costs)
    plt.xlabel("Iteration")
    plt.ylabel("Cost")
    plt.savefig("$path.pdf", bbox_inches="tight")
    plt.close()
end

function plot_costs(costs, steps, path::String)
    plt.plot(steps, costs)
    plt.xlabel("Iteration")
    plt.ylabel("Cost")
    plt.savefig("$path.pdf", bbox_inches="tight")
    plt.close()
end

"""Saves a cost vector as txt."""
function save_costs(costs, path::String)
    open("$path.txt", "w") do io
        writedlm(io, costs)
    end
end

function save_costs(costs, steps, path::String)
    open("$path.txt", "w") do io
        writedlm(io, costs)
        writedlm(io, steps)  # FIXME: save array
    end
end

"""Finds the iterations whe the costs improved."""
function arg_improvements(costs)
    improvements_iter = Vector{Int}(undef, 0)
    current_min = Inf
    for (iter, cost) in enumerate(costs)
        if cost < current_min
            push!(improvements_iter, iter)
            current_min = cost
        end
    end
    return improvements_iter
end

end