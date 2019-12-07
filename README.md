# SOD 324 - Meta heuristics project

## Introduction

Ce répertoire contient le prototype d'un code de résolution d'un projet
d'élèves (SEQATA) pour le cours de RO SOD324 (ENSTA Paris).

Ce prototype est opérationnel et intègre les fonctionnalités suivantes :

- organisation multi fichiers pour simuler les conditions d'un gros projet
  (en pensant à la programmation objet et transposable en C++).
- implémentation avec choix entre plusieurs méthodes méthaheuristiques
  (dont recuit et un taboo évolué) et exactes (PLNE)
- gestion de nombreuses options dont le premier argument est une action
  (à la git) pour le choix de la méthode de résolution du problème complet,
  ou de l'algorithme du résolution du sous-problème de timing,
- choix par une option du solveur linéair externe quand un tel solveur
  est nécessaire (e.g cplex, glpk, clp, ...)

La liste des options disponibles peut-être obtenue par :

```bash
./bin/seqata.jl -h
```

Ou peut avoir des détails complémentaires :

```bash
./bin/seqata.jl help
```

Voir en fin de fichier pour des exemples d'utilisation du code.

### Rappel du problème SEQATA (ALP simplifié)

Problème de séquencement d'atterrissage d'avions (Aircraft Landing Problem)
pour une seule piste.

Un avion est caractérisé par :

- sa date d'atterrissage souhaitée (T_i = target)
- ses dates d'atterrissage au plus tôt (E_i = lb_i) et au plus tard (L_i = ub_i)
- son type (plus ou moins gros, ...)
- des coûts de pénalité par unité de retard (tp = tardiness penality),
  ou d'avance (ep = earliness penalty)

Une durée d'écart minimale S_{kl} doit être respectée entre un avion de type k
et un avion de type l.
En effet un gros porteur peut sans inconvénient atterrir juste après un
"delta-plane" alors que l'inverse n'est pas du tout vrai !
L'instance définit donc une matrice S_{kl} pour chaque type d'avion
possible.

L'objectif consiste à affecter la date d'atterrissage de chaque avion
en minimisant le coût de pénalité global tout en respectant les contraintes
sur les dates limites d'atterrissage.

## Exemples d'utilisation

### Résolution du sous-problème de timing

On passe la clé "timing ou tim", une instance (option `-i`) et une liste d'avions
(option `--planes` ou `-p`). Le programme appelle un des solveurs de timing
disponible en fonction de l'option `--timing-algo-solver` ou `-t`
(e.g `-t lp` ou `-t earliest`)
Dans le prototype, seul le solver ```EarliestTimingSolver``` est fonctionnel.
Un fichier est généré dans le sous répertoire "_tmp/"

```bash
./bin/seqata.jl tim -t earliest -i data/alp_01_p10.alp  -p 3,4,5,6,7,8,9,1,10,2
```

=> 2830.0

Si le type ```LpTimingSolver``` est implanté :

```bash
./bin/seqata.jl tim -t lp -i data/alp_01_p10.alp  -p 3,4,5,6,7,8,9,1,10,2
```

=> 700.0

### Validation d'une solution existante

On passe la clé "val", une instance (option `-i`) et une solution (option `-s`) et le
programme indique si la solution est valide ou liste les viols de contraintes.

Test de la solution générées précédemment  avec l'algo `-t earliest`

```bash
./bin/seqata.jl val -t earliest -i data/alp_01_p10.alp -s _tmp/alp_01_p10=2830.0.sol
```

=> Solution correcte de coût : 2830.0

Test de la solution optimale du sujet

```bash
./bin/seqata.jl val -t lp -i data/alp_01_p10.alp -s sols/alp_01_p10_k3=700.0.sol
```

=> Solution correcte de coût : 700.0

### Heuristique de Monte Carlo (action `carlo`)

```bash
./bin/seqata.jl carlo -i data/01.alp  -t earliest -n 10000000 -L1
```

```bash
./bin/seqata.jl carlo -i data/01.alp  -t lp -n 10000000 -L1
```

### Heuristique d'exploration (action `explore`)

Test d'une exploration aléatoire (action explore) à partir d'une solution
aléatoire (`--presort shuffle`) pendant 10^7 itérations
On utilise ici l'algo de timing earliest (non optimal mais fourni avec
le proto)
Les solutions sont enregistrée dans le sous-répertoire _tmp.

```bash
./bin/seqata.jl explore -i data/01.alp  --presort shuffle -t earliest -n 10000000 -L2
```

```julia
Début de l'action explore
Solution correspondant à l'ordre de l'instance
cost=25910.0  :[p1,p2,p3,p4,p5,p6,p7,p8,p9,p10]
Solution initiale envoyée au solver
cost=19990.0  :[p10,p5,p1,p9,p8,p4,p3,p2,p6,p7]
BEGIN solve(ExploreSolver)
iter <nb_move>=<nb_improve>+<nb_degrade> => <bestcost>
iter 1=1+0 => cost=11150.0  :[p7,p5,p1,p9,p8,p4,p3,p2,p6,p10]
iter 53=17+36 => cost=10180.0  :[p5,p3,p10,p9,p6,p4,p7,p8,p2,p1]
iter 55=18+37 => cost=4540.0   :[p5,p3,p8,p4,p6,p9,p7,p10,p2,p1]
iter 171=51+120 => cost=3870.0   :[p3,p4,p7,p5,p6,p1,p9,p8,p10,p2]
iter 2733=796+1937 => cost=3070.0   :[p4,p5,p3,p6,p8,p9,p7,p1,p10,p2]
iter 19724=5571+14153 => cost=3010.0   :[p4,p3,p5,p6,p7,p8,p1,p9,p10,p2]
iter 77586=21977+55609 => cost=2950.0   :[p4,p3,p7,p6,p8,p9,p5,p1,p10,p2]
iter 169472=48162+121310 => cost=2780.0   :[p3,p5,p4,p6,p7,p8,p1,p9,p10,p2]
iter 242903=69022+173881 => cost=2500.0   :[p3,p5,p4,p8,p7,p6,p9,p1,p10,p2]
iter 263272=74779+188493 => cost=2470.0   :[p4,p3,p6,p5,p7,p9,p8,p1,p10,p2]
iter 1034240=293687+740553 => cost=2110.0   :[p4,p3,p6,p5,p7,p8,p9,p1,p10,p2]
END solve(ExploreSolver)

meilleure solution trouvée :
cost=2110.0   :[p4,p3,p6,p5,p7,p8,p9,p1,p10,p2]
```

Quant vous aurez implanté l'algorithme ```LpTimingSolver```, la solution optimale
de coût 700 pourra être régulièrement atteinte en 10^7 itérations

```bash
./bin/seqata.jl explore -i data/01.alp  --presort shuffle -t lp -n 1000000 -L1
```

```julia
=> optimum régulièrement atteignable
=> affichage
Début de l'action explore
iter 2:1+/1- bestsol=cost=13850.0  :[p9,p3,p4,p1,p8,p10,p2,p5,p7,p6]
iter 10:3+/7- bestsol=cost=9730.0   :[p8,p4,p5,p9,p6,p1,p3,p2,p7,p10]
iter 48:13+/35- bestsol=cost=7340.0   :[p7,p5,p6,p3,p10,p9,p8,p4,p1,p2]
iter 174:49+/125- bestsol=cost=6710.0   :[p3,p8,p7,p4,p5,p1,p6,p10,p2,p9]
iter 175:50+/125- bestsol=cost=6470.0   :[p3,p8,p5,p4,p7,p1,p6,p10,p2,p9]
iter 190:54+/136- bestsol=cost=6100.0   :[p6,p7,p4,p5,p9,p3,p8,p10,p2,p1]
iter 269:77+/192- bestsol=cost=3940.0   :[p5,p3,p4,p7,p9,p8,p1,p10,p6,p2]
iter 670:191+/479- bestsol=cost=3800.0   :[p3,p4,p1,p6,p8,p7,p5,p9,p10,p2]
iter 1776:520+/1256- bestsol=cost=2800.0   :[p3,p5,p4,p9,p8,p7,p6,p10,p1,p2]
iter 1915:573+/1342- bestsol=cost=2560.0   :[p4,p5,p3,p6,p9,p8,p7,p10,p1,p2]
iter 24124:6934+/17190- bestsol=cost=1600.0   :[p3,p5,p4,p6,p7,p8,p9,p10,p1,p2]
iter 67661:19230+/48431- bestsol=cost=1090.0   :[p3,p4,p5,p8,p6,p7,p9,p10,p1,p2]
iter 248515:69936+/178579- bestsol=cost=700.0    :[p3,p4,p5,p7,p6,p8,p9,p1,p10,p2]
meilleure solution trouvée :
cost=700.0    :[p3,p4,p5,p7,p6,p8,p9,p1,p10,p2]
```

### Heuristique de descente (action descent)

L'efficacité de la descente dépend beaucoup de la largeur de la pertinence et
de la votre voisinage !

- avec algo de timing earliest
  ```./bin/seqata.jl des -i data/01.alp  --presort shuffle -t earliest -L1 -n 100000```
  => peut trouver 2110 en moins de 200 itérations !

- avec algo de timing lp (à faire par les élèves !)
  ```./bin/seqata.jl des -i data/01.alp  --presort shuffle        -L1 -n 10000```
  ```./bin/seqata.jl des -i data/01.alp  --presort shuffle  -t lp -L1 -n 10000```
  => peut trouver l'optimum 700 en moins de 200 itération

### Méthode exacte PLNE avec coût discrétisé (action `dmip`)

Il y a une variable distincte pour chaque avion et chaque date d'atterrissage
possible ! Cette variable est donc directement associée à un coût d'avion
quand celui-ci atterrit à une date précise.

```bash
./bin/seqata.jl dmip -i data/01.alp  
```

## Tests unitaires

Une bonne partie des fonctionnalités proposées (ou à développer) dispose de
ses propres tests unitaires.
Ces tests sont indépendant et sont regroupés dans le répertoire test, et le
programme de lancement peut s'exécuter depuis le répertoire de travail.

```bash
./test/runtests.jl
```

=> exécute tous les tests commençant par "test/test-xxxx.jl".
    (on peut préciser des exceptions dans le fichier `runtests.jl`)
    Une synthèse des tests réussis ou échoués est indiquée à la fin de l'exécution.

```bash
./test/runtests.jl ./test/test-05-validate.jl
```

=> test seulement le ou les fichiers précisés

En fonction de l'évolution de Julia, des solvers disponibles, ...
Certaines fonctionnalités de ce projet peuvent ne pas fonctionner.

## À propos des instances

Les instances d'origines (de la bibliohèque orlib) sont accessibles depuis le
site :

- <http://people.brunel.ac.uk/~mastjjb/jeb/jeb.html#aircraft>
- <http://people.brunel.ac.uk/~mastjjb/jeb/orlib/airlandinfo.html>
- <http://people.brunel.ac.uk/~mastjjb/jeb/orlib/files/>

Ces 13 instances ont été transformées dans un nouveau format plus lisible, plus dense
et mieux adapté à une évolution de la fonction de coût.
(voir sujet de projet pour sa description).
