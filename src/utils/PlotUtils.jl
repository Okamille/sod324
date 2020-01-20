"""Plotting and saving utilities."""
module PlotUtils

import PyPlot; const plt = PyPlot
using DelimitedFiles: writedlm

export plot_save_costs, plot_costs, save_costs

function plot_save_costs(costs, path::String; plot=false, save=false)
    if plot
        plot_costs(costs, path)
    end
    if save
        save_costs(costs, path)
    end
end

function plot_costs(costs, path::String)
    println(path)
    plt.plot(costs)
    plt.xlabel("Iteration")
    plt.ylabel("Cost")
    plt.savefig("$path.pdf", bbox_inches="tight")
    plt.close()
end

function save_costs(costs, path::String)
    open("$path.txt", "w") do io
        writedlm(io, costs)
    end
end

end