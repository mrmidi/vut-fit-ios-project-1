#!/usr/bin/env bash

# H E L P
Help()
{
  echo "Trade Log Analyzer Semester Project"
  echo "by mrmidi, 2021"
  echo "Usage:"
  echo "tradelog [-h|--help] [FILTR] [PŘÍKAZ] [LOG [LOG2 [...]]"
  echo "Try tradelog list-tick stock-2.log"
  echo
}

#create array with tickers
gettickers()
{

  tickers=( $(catfiles | awk -F ';' '{print $2}' | sort -u) )
}

catfiles(){
  if [ $FILTER ]
    then
      eval "$catcmd" | eval "$filter"
    else
      eval "$catcmd"
  fi
}

filter()
{
eval "$filter"
}

#REMOVE
ListTick()
{
  #sort -k 2 -u -t';' -s "$file"
  #awk -F ';' '{print $2}' "$file"  | sort -u
  echo "==="
  echo ${POSITIONAL[*]}
  echo "==="
  awk -F ';' '{print $2}' "${POSITIONAL[*]}"  | sort -u
}

printpos()
{
  for t in "${tickers[@]}"
    do
      #echo "$t"
      #awk -F ';' 'NR==1 {lastprice=$4}' {print f,$1}' < if on first line - save last price
      # what's going on here: 1) iterate through tickers array. 1) sort strings by date descending. get last price from first line {print "'$t'\t : \t" /NR}
      catfiles | grep ";$t" | sort -t ';' -k1 -r | awk -F ';' -v t="$t" 'NR==1 {lastprice=$4} {if  ($3 == "buy") bought += $6; else sold += $6} END {total = bought - sold; sum = total * lastprice; printf "%s \t : %.2f\n", t, sum; }'
    done
}

printpos()
{
  for t in "${tickers[@]}"
    do
      #echo "$t"
      #awk -F ';' 'NR==1 {lastprice=$4}' {print f,$1}' < if on first line - save last price
      # what's going on here: 1) iterate through tickers array. 1) sort strings by date descending. get last price from first line {print "'$t'\t : \t" /NR}
      catfiles | grep ";$t" | sort -t ';' -k1 -r | awk -F ';' -v t="$t" 'NR==1 {lastprice=$4} {if  ($3 == "buy") bought += $6; else sold += $6} END {
                total = bought - sold;
                total = int( total / 1000 );
                if (total > 0)
                  {
                  }
                else if(total < 0)
                  {
                  }
                else
                  graph = "";
                sum = total * lastprice;
                printf "%s \t : %.2f\n", t, sum; }'
    done
}

printhist()
{
for t in "${tickers[@]}"
    do
      #echo "$t"
      #awk -F ';' 'NR==1 {lastprice=$4}' {print f,$1}' < if on first line - save last price
      # what's going on here: 1) iterate through tickers array. 1) sort strings by date descending. get last price from first line {print "'$t'\t : \t" /NR}
      catfiles | grep ";$t" | awk -F ';' -v t="$t" 'END {
              printf "%s\t: ", t;
              for (i = 1; i <= NR; i++) {
                printf "%s", "#";
              }
              printf "\n"
              }'
    done
}

printlastprice()
{
  for t in "${tickers[@]}"
    do
      #echo "$t"
      #awk -F ';' 'NR==1 {lastprice=$4}' {print f,$1}' < if on first line - save last price
      # what's going on here: 1) iterate through tickers array. 1) sort strings by date descending. get last price from first line {print "'$t'\t : \t" /NR}
      eval "$catcmd" | grep ";$t" | sort -t ';' -k1 -r | awk -F ';' -v t="$t" 'NR==1 {lastprice=$4} END {printf "%s \t : %.2f\n", t, lastprice; }'
    done
}






# test if arguments is empty
# exit if true
#if [ -z $* ]
#then
#  echo "Usage: tradelog [-h|--help] [FILTR] [PŘÍKAZ] [LOG [LOG2 [...]]"
#  exit 1
#fi

commands=0
TICKER=''
BEFORE=''
AFTER=''
WIDTH=''
FILES=()
tickers=()

while [ ! -z "$1" ]; do
  case "$1" in
     --help|-h)
         Help
         ;;
      --width|-w)
         shift
         regex='^[0-9]+$'
         if ! [[ $1 =~ $regex ]] ; then
            echo "Error: WIDTH parameter should be positive integer" >&2; exit 1
         fi
         WIDTH=$1
         ;;
     --after|-a)
         FILTER=YES
         shift
         AFTER="$1"
         shift
         AFTER+=" $1"
         ;;
     --before|-b)
         FILTER=YES
         shift
         BEFORE="$1"
         shift
         BEFORE+=" $1"
         ;;
     --ticker|-t)
        shift
        FILTER=YES
        if [ "$TICKER" != '' ] # split regex with
          then
            TICKER+='|'
        fi
        TICKER+=";$1;"
         ;;
     list-tick)
        #shift
        commands+=1
        LISTTICK=YES
        ;;
     profit)
        commands+=1
        SHOWPROFIT=YES
        ;;
     pos)
        commands+=1
        POS=YES
        ;;
     hist-ord)
        commands+=1
        HIST=YES
        ;;
     last-price)
        commands+=1
        LASTPRICE=YES
        ;;
     graph-pos)
        commands+=1
        GRAPHPOS=YES
        ;;
     list-tick1)
        commands+=1
        if [ "$2" ]
          then
            file=$2
            echo "Your file is: $file"
            ListTick
            shift
        else
          echo 'Error: please specify log file with list-tick argument'
          exit 1
        fi
        ;;
     *)
        # put arguments into filenames array
        FILES+=("$1")
        ;;
  esac
shift
done

if [ $commands -gt 1 ]
   then
     >&2 echo "Error: too many commands! You can use only one per time."
     exit 1
fi

set -- "${FILES[@]}"


#iterrate all files in arguments. check if it's archived. prompt filename if it's empty
#TODO prompt if empty filename

for f in "${FILES[@]}"
do
  if file --mime-type "$f" | grep -q gzip$; then #check if it gzipped
    # cat test.txt.gz | zcat > for OS X compatibility
    catcmd+="cat "$f" | zcat;"
  else
    catcmd+="cat $f;"
  fi
#  echo "$f"
done

#echo "$TICKER"
#echo "$catcmd"
#stream=eval "$catcmd"
#echo "$stream"
#echo "$files"
#echo "$command"
#eval "$command"
# awk -F ';' -v d1="2021-07-29 15:51:18" -v d2="2021-07-29 16:33:26" '$1 > d1 && $1 < d2' stock-2.log

if [ $LISTTICK ]; then
    eval "$catcmd" | awk -F ';' '{print $2}' | sort -u
    exit 0
fi

if [ $FILTER ]
  then
    #echo "filtered"
    if [ "$AFTER" != '' ]
      then
        if [ "$filter" != '' ] # split cmd with
          then
            filter+='|'
        fi
        filter+="awk -F ';' -v d=\""$AFTER"\" '\$1 > d'"
    fi
    if [ "$BEFORE" != '' ]
      then
        if [ "$filter" != '' ] # split cmd with
          then
            filter+='|'
        fi
        filter+="awk -F ';' -v d=\""$BEFORE"\" '\$1 < d'"
    fi
    if [ "$TICKER" != '' ]
      then
        if [ "$filter" != '' ] # split cmd with
          then
            filter+='|'
        fi
        filter+="grep -E '$TICKER'" # TODO поменять имя переменной
    fi
fi

#echo $filter


if [ $SHOWPROFIT ]
  then
  catfiles | awk -F ';' '{if  ($3 == "buy") bought += $4 * $6; else sold += $4 * $6} END {total = sold - bought; OFMT="%0.02f"; print total}'
  exit 0
fi

if [ $POS ]
  then
    gettickers
    printpos | sort -t ":" -k2 -g -r
    exit 0
fi


if [ $HIST ]
  then
    gettickers
    printhist
    exit 0
fi

if [ $LASTPRICE ]
  then
    gettickers
    printlastprice
    exit 0
fi

if [ $GRAPHPOS ]
  then
    gettickers
    printgraph
    exit 0
fi

#echo
#echo "TEST"
#tst="cat fucklog | awk -F ';' '{print \$2}'"
#eval "$tst"
#eval "$catcmd" | eval "$filter"
#catfiles | filter

#catfiles