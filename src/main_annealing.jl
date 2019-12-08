include("solvers/annealing.jl")

function main_annealing(args)
  ln1("="^70)
  ln1("Début de l'action annealing")
  inst = Instance(args[:infile])

  # Construction de la solution initiale :
  sol = Solution(inst)
  ln1("Solution correspondant à l'ordre de l'instance")
  ln1(to_s(sol))

  # ON POURRAIT AUSSI REPARTIR DE LA SOLUTION DU GLOUTON INTELLIGENT !
  initial_sort!(sol) 
  
  ln1("Solution initiale envoyée au solver")
  ln1(to_s(sol))


  # Choix des options pour le solver
  user_opts = Dict(
      :loglevel           => Args.get("level"),
      # :loglevel           => 2,

      # :startsol           => nothing,  # nothing pour auto à partir de l'instance
      :startsol           => sol,  # nothing pour auto à partir de l'instance
      :step_size          => inst.nb_planes,   # à renommer en step_size
      # :temp_init          => -1.0, # -1.0 pour automatique
      :temp_init          => nothing, # nothing pour automatique
      :temp_init_rate     => 0.30,  # valeur standard : 0.8
      :temp_mini          => 0.000_001,
      # :temp_coef          => 0.999_95,
      :temp_coef          => 0.95,
      :nb_cons_reject_max => 1_000_000_000, # infini
      # :nb_cons_no_improv_max => 500*inst.size*inst.size,
      :nb_cons_no_improv_max => 5000*inst.nb_planes,
  )

  sv = AnnealingSolver(inst, user_opts)
  ln1(get_stats(sv))
  solve(sv)
  bestsol = sv.bestsol
  print_sol(bestsol)
  ln1("Fin de l'action annealing")
end

main_annealing(Args.args)
