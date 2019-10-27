# TABLEUR EN SHELL


## 1 Fonctionnalités

L'utilisateur peut indiquer les options suivantes à partir de la ligne de commandes :
in, out, scin, slin, scout, slout, inverse
Le tableur peut comporter des cellules texte ou des cellules sous la forme =fonction(arg1[,arg2,...]) ou =[cellule]. Les fonctions pouvant être présentes sont celles détaillés dans l'énoncé. Trois fichiers tests sont mis à disposition (calcul1.txt : cas simple, calcul2.txt : fichier plus complet, calcul3.txt : fichier comportant des cellules invalides), ainsi que leurs fichiers traduits respectifs pouvant être supprimés (calcul1res.txt, calcul2res.txt, calcul3res.txt), et un fichier correspondant aux erreurs.


## 2. Gestion des erreurs

Six erreurs principales sont gérées,nous avons décidé que ces erreurs ne devaient pas arrêter le programme. Chacune de ces erreurs écrira dans la cellule source du texte variant selon l'erreur.
Ces erreurs sont écrites pendant l'exécution du programme dans un fichier "tmp.txt" (/!\ qui est vidé au début du programme mais pas à la fin) puis sont affichés à la fin sur la sortie standard. Les voici :

-"Un argument ou plus n'est pas un nombre.", exemple : =+(toto,7)
Dans ce cas, "7" sera écrit dans le fichier destination, car toto vaudra 0. Dans le cas d'une division, toto aurait valu 0.

-"Deuxième argument manquant, initialisation à 0.", exemple : =+(8)
Dans ce cas, "8" sera écrit dans le fichier destination, et le membre manquant sera initialisé à 0.
Cette erreur concerne les calculs entre deux nombres.

-"Deuxième argument manquant, seul le premier argument est pris en compte.", exemple : =+somme(l1c1)
La différence avec l'erreur précédente est que celle-ci concerne les plages de cellules. Comme l'argument est manquant, le résultat sera donc égal à l'unique argument.

-"Nombre d'arguments invalide : il en faut trois.", exemple : =subsitute(l1c2,l1c2,l1c3)
Cette erreur ne concerne que la fonction "subsitute", car c'est la seule qui comporte trois arguments. Si deux arguments sont donnés, la fonction supprime la sous-chaîne arg2 de la chaîne arg1. Si quatre arguments (ou plus) sont donnés, la fonction ignore tous les paramètres après le troisième (même fonctionnement que s'il y avait trois arguments).

-"Division par zéro." : exemple : =/(8,0)
Il n'est pas possible de diviser par 0. La fonction écrit "erreur" dans le fichier destination. Cela peut donc mener à d'autres erreurs si cette case destination est utilisée par d'autres fonctions de calcul.

-"Fichier inexistant." : exemple : =size(toto.txt)
Le fichier renseigné n'existe pas. Les fonctions en rapport avec cette erreur (size, lines) écriront donc 0 dans la cellule ciblée.


## 3. Difficultés rencontrées

Il nous a d'abord était difficile de gérer la fonction display et le booléen correspondant à l'option "inverse".

### a) Display
Display a été géré de cette manière : lorsqu'il est rencontré, il est écrit dans la chaîne servant à écrire dans le fichier destination. Le programme récupère alors cette chaîne, et si "display" et écrit dedans, il l'ajoute à la variable "plagesDisplay" au lieu de l'ajouter à l'autre variable (contenant tout le fichier destination en l'absence de display). Le programme écrit ensuite le contenu de plagesDisplay dans le fichier destination, en ayant d'abord vérifié qu'un display n'était pas déjà présent dans la plage d'un autre display, puis en concaténant les différentes plages de display.

### b) Inverse
L'utilisation de variables, présentes dans le script, depuis les fonctions a posé problème, puisque des sous-shells sont lancés. Une solution simple bien qu'embêtante a été de passer cette variable en argument de toutes les fonctions.

### c) Stdin/Stdout
Si l'utilisateur n'indique pas de fichier source, il devra écrire son tableur sur l'entrée standard (la saisie se termine en entrant "done"). Ensuite, le programme récupèrera ce tableur et le stockera dans un fichier "tmpsrc.txt", la suite se déroule de la même manière que pour un fichier source classique.
Si l'utilisateur n'indique pas de fichier destination, tous les résultats de chaque ligne seront écrits dans le fichier "tmpdest.txt". La création d'un fichier est surtout utile pour pouvoir calculer les fonctions dépendant de cellules devant déjà être calculées. A la fin, le programme affiche le contenu de la variable "res", ce qui est équivalent au fait d'afficher le contenu de "tmpdest.txt".
Ces deux fichiers, ainsi que celui généré par "display", sont vidés en début de programme (utile si la précédente exécution ne s'est pas passée comme prévu), et effacés à la fin du programme.

### d) Slin
Le fichier "tmp.txt" utilisé par "display" est également utilisé pour gérer le séparateur de lignes d'entrée. Sa gestion se déroule ainsi : le programme récupère chaque champ du fichier d'entrée censé représenter une ligne du tableur, puis l'écrit dans "tmp.txt", de manière à ce que tous les caractères correspondants à "slin" soient remplacés par des retours charriot. Le programme s'exécute ensuite normalement.


## 4. Bugs

Certaines erreurs ou définitions pouvant mener à des conflits d'exécution ne sont pas gérées.
Cela inclut :

-L'utilisation de '-' comme séparateur : la ligne de commandes est gérée en utilisant "cut -d-". Utiliser '-' comme séparateur rend la gestion de la ligne de commandes incorrecte.

-L'utilisation du même séparateur de lignes et de colonnes pour l'entrée ou pour la sortie, pour des raisons évidentes.

-Utiliser '=', ',' ou une parenthèse est également impossible, ces caractères étant déjà utilisés pour gérer la composition d'une cellule.

-Même si cela est possible, utiliser une lettre de l'alphabet est une mauvaise idée. Le 'l' et le 'c' sont utilisés pour repérer les arguments de la forme "l[nombre]c[nombre]", et la lettre utilisée comme séparateur pourrait poser problème si elle venait à être présente dans une des cellules du tableur.

-Enfin, même si cela est également possible, l'utilisation d'un caractère représentant une fonction ('+', '-', etc, ...) peut poser problème si la fonction correspondante est présente dans le fichier.
