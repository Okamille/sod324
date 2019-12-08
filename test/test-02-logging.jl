# ===========
println("Test de l'analyse des logging... ")


include("../src/utils/log.jl")

args = Args.parse_commandline()
Args.set(:level, 2)

# EXEMPLE DE CAPTURE ET RESTAURATION DU FLUS DE SORTIE STANDARD
#
# original_stdout = stdout
# (read_pipe, write_pipe) = redirect_stdout();
#
# redirect_stdout(original_stdout);
# close(write_pipe)

##########################
# CAPTURE DE STDOUT
original_stdout = stdout
(read_pipe, write_pipe) = redirect_stdout();

# --------------------------------------------
lg2("A") # Affiche A sans saut de ligne
lg2("B") # Affiche B sans saut de ligne
ln2("")  # Affiche un saut de ligne

# --------------------------------------------
ln2("C") # Affiche C avec saut de ligne

# --------------------------------------------
# Affiche des valeura de type varié sans saut de ligne malgré le ln3()
# car suffix est positionné pour annuler le "\n" par défaut.
n=5
f=3.1
r=22//7
ln2("n=", n, " f=", f, " r=", r,
    prefix="UN_PREFIX==",
    suffix="==UN_SUFFIX"
   )


# --------------------------------------------
lg2("-1-") # On ajoute à la fin de la ligne précédente
ln2() # n'affiche rien, même pas un saut de ligne
lg2("-2-") # On ajoute à la fin de la ligne précédente
ln2("") # affiche un saut de ligne

# --------------------------------------------
ln2("FIN") # affiche "FIN" puis un saut de ligne

##########################
# RESTAURATION DE STDOUT
redirect_stdout(original_stdout)
close(write_pipe)

# On exploite l'ecriture capturée présendant pour vérification
@testset "Test des logging via capture de stdout par redirect_stdout" begin

    # --------------------------------------------
    # txt = read(read_pipe, String)
    line =  readline(read_pipe, keep=true)
    # @show line
    @test line == "AB\n"

    # --------------------------------------------
    line =  readline(read_pipe, keep=true)
    # @show line
    @test line == "C\n"

    # --------------------------------------------
    line =  readline(read_pipe, keep=true)
    # @show line
    # @test line == "UN_PREFIX==n=5 f=3.1 r=22//7==UN_SUFFIX" # NON car suffix écrasé !
    @test line == "UN_PREFIX==n=5 f=3.1 r=22//7\n"

    # --------------------------------------------
    #
    line =  readline(read_pipe, keep=true)
    # @show line
    @test line == "-1--2-\n"

    # --------------------------------------------
    line =  readline(read_pipe, keep=true)
    # @show line
    @test line == "FIN\n"

end
# Suppress unnecessary output when include this file.
return nothing


