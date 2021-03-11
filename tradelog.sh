if [ $# -eq 0 ]
  then
    echo
    echo "Usage:"
    echo "tradelog [-h|--help] [FILTR] [PŘÍKAZ] [LOG [LOG2 [...]]"
    echo
    exit 0
fi

# H E L P
Help()
{
  echo
  echo "Usage:"
  echo "tradelog [-h|--help] [FILTR] [PŘÍKAZ] [LOG [LOG2 [...]]"
  echo
  echo "PŘÍKAZ může být jeden z:"
  printf "\tlist-tick – výpis seznamu vyskytujících se burzovních symbolů, tzv. “tickerů”.\n"
  printf "\tprofit – výpis celkového zisku z uzavřených pozic.\n"
  printf "\tpos – výpis hodnot aktuálně držených pozic seřazených sestupně dle hodnoty.\n"
  printf "\tlast-price – výpis poslední známé ceny pro každý ticker.\n"
  printf "\thist-ord – výpis histogramu počtu transakcí dle tickeru.\n"
  printf "\tgraph-pos – výpis grafu hodnot držených pozic dle tickeru.\n"
  echo "FILTR může být kombinace následujících:"
  printf "\t-a DATETIME – after: jsou uvažovány pouze záznamy PO tomto datu (bez tohoto data). DATETIME je formátu YYYY-MM-DD HH:MM:SS.\n"
  printf "\t-b DATETIME – before: jsou uvažovány pouze záznamy PŘED tímto datem (bez tohoto data).\n"
  printf "\t-t TICKER – jsou uvažovány pouze záznamy odpovídající danému tickeru. Při více výskytech přepínače se bere množina všech uvedených tickerů.\n"
  printf "\t-w WIDTH – u výpisu grafů nastavuje jejich šířku, tedy délku nejdelšího řádku na WIDTH\n"
  echo "-h a --help vypíšou nápovědu s krátkým popisem každého příkazu a přepínače."
  echo
  exit 0
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


printpos()
{
  for t in "${tickers[@]}"
    do
      catfiles | grep ";$t" | sort -t ';' -k1 -r | awk -F ';' -v t="$t" 'NR==1 {lastprice=$4} {if  ($3 == "buy") bought += $6; else sold += $6} END {total = bought - sold; sum = total * lastprice; printf "%s \t : %.2f\n", t, sum; }'
    done
}

printgraph()
{
  getmax
  for t in "${tickers[@]}"
    do
      catfiles | grep ";$t" | sort -t ';' -k1 -r | awk -F ';' -v t="$t" -v max="$max" -v width="$WIDTH" 'NR==1 {lastprice=$4} {if  ($3 == "buy") bought += $6; else sold += $6} END {
                if (width == 0)
                  {
                    total = (bought - sold);
                    sum = total * lastprice;
                    total = int(total / 1000);
                  }
                  else
                  {
                    tick = int(max / width);
                    total = (bought - sold);
                    sum = int(total * lastprice);
                    total = int( sum / tick );
                  }
                graph = "";
                if (total > 0)
                  {
                  ch = "#";
                  for (i = 1; i <= total; i++)
                    {
                       graph = graph "" ch;
                    }
                  }
                else if(total < 0)
                  {
                    ch = "!";
                    for (i = -1; i >= total; i--)
                    {
                      graph = graph "" ch;
                    }
                  }
                else
                  graph = "";

                printf "%s \t : %s\n", t, graph;
                }'
    done
}

getmax()
{
    max=$(printpos | sort -t ":" -k2 -g -r | head -1 | awk -F ":" '{gsub(/^[ \t]+/, "", $2); print $2}')
}

printhist()
{
  getmax
  for t in "${tickers[@]}"
    do
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
      eval "$catcmd" | grep ";$t" | sort -t ';' -k1 -r | awk -F ';' -v t="$t" 'NR==1 {lastprice=$4} END {printf "%s \t : %.2f\n", t, lastprice; }'
    done
}

commands=0
TICKER=''
BEFORE=''
AFTER=''
WIDTH='0'
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
            echo "Error: WIDTH parameter should be a positive integer" >&2; exit 1
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



set -- "${FILES[@]}"


#check if filename is empty
if [ ${#FILES[@]} -eq 0 ]; then
    read -r -p "Please enter filename: " file
     FILES+=("$file")
fi

#check if it's file in current directory
for f in "${FILES[@]}"
do
  if [ ! -f "$f" ]
    then
     >&2 echo "Error reading file!"
     exit 1
  fi
done

#check if it's archived and prepare commands for processing
for f in "${FILES[@]}"
do
  if file --mime-type "$f" | grep -q gzip$
   then
    # cat test.txt.gz | zcat > for OS X compatibility
    catcmd+="cat "$f" | zcat;"
  else
    catcmd+="cat $f;"
  fi
done

#show all ticks in alphabetical order
if [ $LISTTICK ]; then
    eval "$catcmd" | awk -F ';' '{print $2}' | sort -u
    exit 0
fi

#read filters and prepare commands
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


#check if commands > 1
if [ $commands -gt 1 ]
   then
     >&2 echo "Error: too many commands! You can use only one per time."
     exit 1
fi

#if no commands just read logs
if [ $commands == 0 ]
  then
    catfiles
    exit 0
fi

#count total profit
if [ $SHOWPROFIT ]
  then
  catfiles | awk -F ';' '{if  ($3 == "buy") bought += $4 * $6; else sold += $4 * $6} END {total = sold - bought; OFMT="%0.02f"; print total}'
  exit 0
fi

#show positions
if [ $POS ]
  then
    gettickers
    printpos | sort -t ":" -k2 -g -r
    exit 0
fi

#show histogram
if [ $HIST ]
  then
    gettickers
    printhist
    exit 0
fi

#show last know prices
if [ $LASTPRICE ]
  then
    gettickers
    printlastprice
    exit 0
fi

#graph
if [ $GRAPHPOS ]
  then
    gettickers
    printgraph | sort -t ":" -k1
    exit 0
fi