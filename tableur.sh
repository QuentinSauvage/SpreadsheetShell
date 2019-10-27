#!/bin/bash

set -e

function rmTmp() {
	if [ -f "tmp.txt" ]
	then
		rm "tmp.txt"
	fi
	if [ -f "tmpsrc.txt" ]
	then
		rm "tmpsrc.txt"
	fi
	if [ -f "tmpdest.txt" ]
	then
		rm "tmpdest.txt"
	fi
}

function viderFichiers() {
	> "tmpsrc.txt"
	> "tmpdest.txt"
	> "tmp.txt"
	> "errlog.txt"
}

function printError() {
	local str="$2 :"
	if test "$1" = 1
	then
		str="$str Un argument ou plus n'est pas un nombre."
	elif test "$1" = 2
	then
		str="$str Deuxième argument manquant, initialisation à 0."
	elif test "$1" = 3
	then
		str="$str Deuxième argument manquant, seul le premier argument est pris en compte."
	elif test "$1" = 4
	then
		str="$str Nombre d'arguments invalide : il en faut trois."
	elif test "$1" = 5
	then
		str="$str Division par zéro."
	elif test "$1" = 6
	then
		str="$str Fichier inexistant."
	fi
	echo "$str" >> "errlog.txt"
}

#opérations de la forme nombre op nombre
#$3 est le booléen inverse
function calc1() {
	local res1=`echo "$1" | cut -d, -f1`
	res1=`getValeur "$res1" $3 "$4"`
	if echo "$1" | grep -q ","
	then
		local res2=`echo "$1" | cut -d, -f2`
		res2=`getValeur "$res2" $3 "$4"`
	else
		if test "$2" = "/"
		then
			res2=1
		else
			res2=0
		fi
		printError 2 "$4"
	fi
	if test "$2" = "/" && test "$res2" -eq 0
	then
		printError 5 "$4"
		echo "erreur"
	else
		echo "scale=5;$res1 $2 $res2" | bc -l
	fi
}

#opérations de la forme op(nombre)
function calc2() {
	local args=`analyseArgs "$1" "$3" "$4"`
	args=`echo "$args" | cut -d, -f1`
	args=`echo "scale=5;$2($args)" | bc -l`
	echo "$args"
}

function +() {
	calc1 "$1" + "$2" "$3"
}

function -() {
	calc1 "$1" - "$2" "$3"
}

function *() {
	calc1 "$1" \* "$2" "$3"
}

function /() {
	calc1 "$1" / "$2" "$3"
}

function ^() {
	calc1 "$1" ^ "$2" "$3"
}

function ln() {	
	calc2 "$1" l "$2" "$3"
}

function e() {
	calc2 "$1" e "$2" "$3"
}

function sqrt() {
	calc2 "$1" sqrt "$2" "$3"
}

function somme() {
	local args=`analyseArgs2 "$1" "$2" "$3" ""`
	local res=0	
	local cpt=0
	local OLDIFS=$IFS
	IFS=","
	if echo "$1" | grep -q ","
	then
		for i in $args
		do
			res=`echo "$res + $i" | bc -l`
			cpt=`expr "$cpt" + 1`
		done
	else
		res="$args"
		cpt=1
		printError 3 "$3"
	fi
	IFS=$OLDIFS
	if test "$4" = ""
	then
		echo "$res"
	else
		echo "scale=5;$res / $cpt" | bc -l
	fi
}

function moyenne() {
	somme "$1" "$2" "$3" 1
}

function variance() {
	local moy=`somme "$1" "$2" "$3" 1`
	local args=`analyseArgs2 "$1" "$2" "$3" ""`
	local res=0
	local cpt=-1
	local OLDIFS=$IFS
	IFS=","
	if echo "$1" | grep -q ","
	then
		for i in $args
		do
			res=`echo "$res + (($i - $moy) ^ 2)" | bc -l`
			cpt=`expr "$cpt" + 1`
		done
	else
		res="$args"
		cpt=1
		printError 3 "$3"
	fi
	IFS=$OLDIFS
	res=`echo "scale=5;$res / $cpt" | bc -l`
	echo "$res"
}

function ecarttype() {
	local res=`variance "$1" "$2" "$3"`
	res=`sqrt $res "$2" "$3"`
	echo "$res"
}

function mediane() {
	local args=`analyseArgs2 "$1" "$2" "$3" ""`
	local cpt=0
	declare -a local tab
	declare -a local tab2
	local OLDIFS=$IFS
	IFS=","
	if echo "$1" | grep -q ","
	then
		for i in $args
		do
			tab[i]="$i"
			cpt=`expr "$cpt" + 1`
		done
		args=`sort <<<"${tab[*]}"`
		i=`expr "$cpt" / 2`
		i=`expr "$i" + 1`
		cpt=`expr "$cpt" % 2`
		for e in "${tab[@]}"
		do
			if test "$i" -eq 2
				then
					res="$e"
				fi
			if test "$i" -eq 1
			then
				if test "$cpt" -eq 0
				then
					res=`echo "scale=5;($e + $res) / 2" | bc -l`
					echo "$res"
				else
					echo "$e"
				fi
				break
			fi
			i=`expr "$i" - 1`
		done
	else
		printError 3 "$3"
		echo "$args"
	fi
	IFS=$OLDIFS
}

function compare() {
	local args=`analyseArgs2 "$1" "$2" "$3" ""`
	local res=`echo "$args" | cut -d, -f1`	
	local OLDIFS=$IFS
	IFS=","
	if echo "$1" | grep -q ","
	then
		for i in $args
		do
			if test `echo "$res $4 $i" | bc -l` -eq 1
			then
				res="$i"
			fi
		done
	else
		printError 3 "$3"
		res="$args"
	fi
	IFS=$OLDIFS
	echo "$res"
}

function min() {
	compare "$1" "$2" "$3" "<"
}

function max() {
	compare "$1" "$2" "$3" ">"
}

function concat() {
	local args=`analyseArgs "$1" "$2" "$3"`
	local res1=`echo "$args" | cut -d, -f1`
	local res2
	if echo "$1" | grep -q ","
	then
		res2=`echo "$args" | cut -d, -f2`
	else
		res2=""
		printError 3 "$3"
	fi
	echo "$res1$res2"
}

function length() {
	local args=`analyseArgs "$1" "$2" "$3"`
	local res1=`echo "$args" | cut -d, -f1`
	echo ${#res1}
}

function subsitute() {
	local args=`analyseArgs "$1" "$2" "$3"`
	tmp=`echo "$1" | cut -d, -f3`
	if test "$tmp" != ""
	then
		tmp=`echo "$1" | cut -d, -f4`
		if test "$tmp" != ""
		then
			printError 4 "$3"
		fi
		else
			printError 4 "$3"
	fi
	local str=`echo "$args" | cut -d, -f1`
	local new=`echo "$args" | cut -d, -f3`
	local old=`echo "$args" | cut -d, -f2`
	echo "$str" | sed -e "s/"$old"/$new/g"
}

function opFile() {
	local args=`analyseArgs "$1" "$3" "$4"`
	local res=`echo "$args" | cut -d, -f1`
	if [ -f "$res" ]
	then
		wc -$2 < "$res"
	else
		printError 6 "$4"
		echo 0
	fi
}

function size() {
	opFile "$1" c "$2" "$3"
}

function lines() {
	opFile "$1" l "$2" "$3"
}

function shell() {
	OLDIFS=$IFS
	IFS=" "
	$1
	IFS=$OLDIFS
}

function display() {
	local val1Display=`echo "$1" | cut -d, -f1`
	local val2Display=`echo "$1" | cut -d, -f2`
	echo "display=$val1Display,$val2Display"
}

function writeDisplay() {
	local tmp="tmp"
	local cpt=1
	local args=""
	while test 0 -lt 1
	do
		tmp=`echo "$1" | cut -d'|' -f"$cpt"`
		if test "$tmp" = ""
		then
			break
		fi
		args=`analyseArgs2 "$tmp" "$3" 1`
		args=`echo "$args" | tr '
' "$slout"`
		args=`echo "$args" | head -c -2`
		if test "$2" = "tmp.txt"
		then
			echo "$args"
		else
			echo -n "$args" >> "$2"
		fi
		cpt=`expr "$cpt" + 1`
	done
}

#recupere la valeur d'une cellule
function getValeur() {
	local OLDIFS=$IFS
	IFS=" "
	if echo "$1" | grep -q "^l[1-9][0-9]*c[1-9][0-9]*$"
	then
		local l=`echo "$1" | cut -dc -f1 | tail -c +2`
		local c=`echo "$1" | cut -dc -f2`
	else
		if [[ $1 =~ [+-]?([0-9].)?[0-9]+ ]]
		then
			echo "$1"
			exit 0
		else
			echo "$3 : Un argument ou plus n'est pas un nombre" >> "errlog.txt"
			echo "0"
			exit 1
		fi
	fi
	local s
	if test "$2" -eq 0
	then
		s=`sed -n "$l p" "$in" | cut -d"$scin" -f"$c"`
	else
		s=`sed -n "$c p" "$in" | cut -d"$scin" -f"$l"`
	fi
	local res="$s"
	local begin=`echo "$res" | head -c 1`
	if test "$begin" = "="
	then
		if test "$2" -eq 0
		then
			res=`sed -n "$l p" "$out" | cut -d"$scin" -f"$c"`
		else
			res=`sed -n "$c p" "$out" | cut -d"$scin" -f"$l"`
		fi
		if test "$res" = ""
		then
				res=`echo "$s" | tail -c +2`
				res=`analyseOp "$res" 0 "$2" "$3"`
		fi
	fi
	echo "$res"
	IFS=$OLDIFS
}

#permet de recuperer les valeurs des arguments d'une op
function analyseArgs() {
	local cleanArgs=""
	local begin
	local res
	local cpt=1
	local ko=0
	local arg=`echo "$1" | cut -d, -f1`	
	local last=""
	while test "$arg" != "$last"
	do
		begin=`echo "$arg" | head -c 1`
		ko=0
		#if test "$begin" = "l"
		if echo "$arg" | grep -q "^l[0-9][0-9]*c[0-9][0-9]*$"
		then
			res=`getValeur "$arg" "$2" "$4"`	
		elif test -z `echo "$begin" | sed -e s/[0-9]//g`
		then
			res="$arg"
		elif echo "$arg" | grep -q "("
		then
			begin=`echo "$arg" | tail -c 2`
			if test "$begin" = ")"
			then
				res=`analyseOp "$arg" 0 "$2" "$4"`
			else
				cpt=`expr $cpt + 1`
				last="$arg"
				arg="$arg",`echo "$1" | cut -d, -f"$cpt"`
				ko=1
			fi
		else
			res="$arg"
		fi
		if test "$ko" -eq 0
		then
			if test "$cleanArgs" = ""
				then
					cleanArgs="$res"
				else
					cleanArgs="$cleanArgs,$res"
				fi
			cpt=`expr $cpt + 1`
			last="$arg"
			arg=`echo "$1" | cut -d, -f"$cpt"`
		fi	
	done
	
	echo "$cleanArgs"
}

#permet de recuperer les valeur sur l'intervalle $1
function analyseArgs2() {
	local cleanArgs
	local res
	local startL=`echo "$1" | cut -d, -f1 | head -c 2 | tail -c 1`
	local startC=`echo "$1" | cut -d, -f1 | head -c 4 | tail -c 1`
	local endL=`echo "$1" | cut -d, -f2 | head -c 2 | tail -c 1`
	local endC=`echo "$1" | cut -d, -f2 | head -c 4 | tail -c 1`
	cleanArgs=`getValeur l"$startL"c"$startC" "$2" "$3"`
	while test "$startC" -ne "$endC" || test "$startL" -ne "$endL"
	do
		startC=`expr "$startC" + 1`
		res=`getValeur l"$startL"c"$startC" "$2" "$3"`
		if test "$res" = ""
		then
			cleanArgs="$cleanArgs
"
			startC=1
			startL=`expr "$startL" + 1`
			res=`getValeur l"$startL"c"$startC" "$2" "$3"`	
		fi
		if test "$4" != ""
		then
			if test "$startC" -ne 1
			then
				cleanArgs="$cleanArgs$scout"
			fi
			cleanArgs="$cleanArgs$res"
		else
			cleanArgs="$cleanArgs,$res"
		fi
	done
	echo "$cleanArgs"
}

#Appella la fonction correspondante : $1 operation a analyser, $2 booleen ecriture
function analyseOp() {
	local res
	local begin=`echo "$1" | head -c 1`
	if test  "$begin" = "["
	then 
		begin=`echo "$1" | head -c -2 | tail -c +2`
		res=`getValeur "$begin" "$3" "$1" "$4"`
	else
		local op=`echo "$1" | cut -d\( -f1`
		local args=`echo "$1" | cut -d\( -f2- | head -c -2`
		res=`"$op" "$args" "$3" "$4"`
	fi
	echo "$res"
}

#récupère le premier caractère et test avec "="
#$1 le contenu, $2 la ligne, $3 la colonne
function analyse() {
	local begin=`echo "$1" | head -c 1`
	local op
	local res
	if test  "$begin" = "="
	then
		#récupère le reste
		op=`echo "$1" | tail -c +2`
		res=`analyseOp "$op" "1" "$4" "$1"`
	else
		res="$1"
	fi
	echo -n "$res"
}

#Appelle l'analyseur de lignes pour chaque ligne
#$1 contenu de la ligne, $2 numero de la ligne
function cutLignes() {
	local OLDIFS=$IFS
	IFS="$scin"
	local col=1
	res=""
	for j in `echo "$1"`
	do
		tmp=`analyse $j $2 $col $3`
		col=`expr $col + 1`
		res="$res$tmp$scin"
	done
	res=`echo "$res" | sed 's/:$//g'`
	echo -n "$res$slout"
	IFS=$OLDIFS
}

############
####MAIN####
############

cpt=2
args=`echo "$@" | cut -d- -f"$cpt"`
inverse=0
scin=" "
slin="
"
slout="
"
scout=" "
viderFichiers
out="tmpdest.txt"
while test "$args" != ""
do
	cpt=`expr "$cpt" + 1`
	option=`echo "$args" | cut -d' ' -f1`
	value=`echo "$args" | cut -d' ' -f2`
	case $option in
		in)
			in="$value" #src dans in
		;;
		out)
			out="$value" #dest dans out
			> "$out"
		;;
		scin)
			scin="$value"
		;;
		scout)
			scout="$value"
		;;
		slin)
			slin="$value"
		;;
		slout)
			slout="$value"
		;;
		inverse)
			inverse=1
		;;
		*)
			echo "Option non reconnue"
			exit 1
	esac
	args=`echo "$@" | cut -d- -f"$cpt"`
done

if test "$in" = ""
then
	in="tmpsrc.txt"
	echo "Entrez la feuille de calculs (entrez done pour finir) : "
	feuille=1
	while test 1
	do
		read feuille
		if test "$feuille" = "done"
		then
			break;
		fi
		echo "$feuille" >> "$in"
	done
fi
if test "$slin" != ""
then
	if [ -f "tmp.txt" ]
	then
		rm "tmp.txt"
	fi
	lignes=`cat "$in"`
	res=1
	cpt=2
	res=`echo "$lignes" | cut -d"$slin" -f1`
	while test "$res" != ""
	do
		echo "$res" >> "tmp.txt"
		res=`echo "$lignes" | cut -d"$slin" -f"$cpt"`
		cpt=`expr "$cpt" + 1`
	done
	in="tmp.txt"
fi
lignes=`cat $in`
OLDIFS=$IFS
IFS="
"
l=1
dest=`echo "$in" | cut -d. -f1`
res=""
subres=""
plagesDisplay=""

for i in $lignes
do
	subres=`cutLignes $i $l $inverse`
	if echo "$subres" | grep -q "display"
	then
		cpt=1
		tmpStr="a"
		while test "$tmpStr" != ""
		do
			tmpStr=`echo "$subres" | cut -d"$scin" -f"$cpt"`
			if echo "$tmpStr" | grep -q "display"
			then
				break
			fi
			cpt=`expr "$cpt" + 1`
		done
		if test "$tmpStr" != ""
		then
			if test "$plagesDisplay" != ""
			then
				plagesDisplay="$plagesDisplay|"
			fi
			plagesDisplay="$plagesDisplay"`echo "$tmpStr" | cut -d= -f2 | cut -d, -f1,2`
		fi
		
	else
		res="$res$subres"
	fi
	l=`expr $l + 1`
done
res=`echo "$res" | head -c -2`
IFS=$OLDIFS
if test "$plagesDisplay" != ""
then
	writeDisplay "$plagesDisplay" "$out" "$inverse"
elif test "$out" = "tmpdest.txt"
then
	echo -e "$res"
else
	echo -e "$res" >> "$out"
fi
rmTmp
echo "Liste des erreurs : " | cat "errlog.txt"
