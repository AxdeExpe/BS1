#!/bin/bash

#Datei
File='./bib.csv'





#--------------categories---------------------------------------
categories()
{
    IFS='|'

    array=()
    i=0
    log="file.txt"

    touch file.txt
    chmod +rw $log

    while read Titel Autoren Schriftenreihe Kategorien Publikationsdatum Verlag Seiten ISBN
    do
        if [ $i -eq 0 ]
        then
            i=1
            continue
        fi

        #array+=($Kategorien)

        if [ "$Kategorien" = "" ]
        then
            continue
        else
            echo "$Kategorien;" >> $log
        fi
    done < $File

    while IFS= read -r line
    do
        sort=($(echo "$line" | tr ';' ';'))
        array+=$sort
    done < "$log"

    sorted=($(echo "${array[@]}" | tr ';' '\n' | sort -u))

    echo "Kategorie: $sorted"
    rm file.txt
    
    exit 0
}





#--------------count---------------------------------------
count()
{
    #zählt die Zeilen, erste Zeile wird nicht mitgezählt
    count=$(wc -l < $File)
    eins='1'
    echo "Anzahl der Einträge:" $count
    exit 0
}





#--------------isbn---------------------------------------
isbn()
{
    i=0

    IFS='|'

    #liest Datei ein
    while read Titel Autoren Schriftenreihe Kategorien Publikationsdatum Verlag Seiten ISBN
    do
        if [ $i -eq 0 ]
        then
            i=$(($i+1))
            continue
        fi

        if [ "$ISBN" = "" ]
        then
            continue
        fi

            #entfernt alle '-' uns ersetzt sie durch ''
            newISBN=$(echo "$ISBN" | sed -r 's/[-]+//g')

            #ermittelt die Stringlänge
            size=${#newISBN}

            #prüft, ob die ISBN größer 10 ist
            if [ $size -lt 10 ]
            then
                echo "Die ISBN '$newISBN' ist kleiner als 10"
                continue
            fi

            #prüft, ob die ISBN größer 10 ist
            if [ $size -gt 10 ]
            then
                #prüft, ob die ISBN größer 13 ist
                if [ $size -gt 13 ]
                then
                    echo "Die ISBN '$newISBN' ist größer als 13"
                    continue
                #prüft, ob die ISBN kleiner 13 ist
                elif [ $size -lt 13 ]
                then
                    echo "Die ISBN '$newISBN' ist größer 10 und kleiner 13"
                    continue
                fi  
            fi

            #prüft, ob die 10 stellige ISBN nur Zahlen mit einem 'X' am Ende beinhaltet
            if [[ "$newISBN" = [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"X" ]]
            then
                #ersetzt das 'X' durch eine 10, sodass man damit rechnen kann
                newISBNX=$(echo "$newISBN" | sed -r 's/.$/10/')
                value=0

                #durchläuft den String, Character für Character und berechnet die Summe 
                for ((j=1; j<=${#newISBNX}; j++))
                do
                    if [ $j -eq 1 ]
                    then
                        let "value=$value+${newISBNX:0:1}"
                    else
                        cache=$(("$j-1")) #muss wegen der ilux so sein
                        if [ "${newISBNX:$cache:2}" = "10" -a $j -eq 10 ]
                        then
                            cache=$(("$j-1")) #muss wegen der ilux so sein
                            let "value=$value+$j*(${newISBNX:$cache:2})"
                        else 
                            cache=$(("$j-1")) #muss wegen der ilux so sein
                            let "value=$value+$j*(${newISBNX:$cache:1})"
                        fi
                    fi
                done
                
                #berechnet die Summe modulo 11
                mod=$(($value % 11))

                if [ $mod -eq 0 ]
                then
                    continue
                else
                    echo "Die Berechnung stimmt für '$newISBNX'/'$ISBN' nicht!  Mod: $mod, Value: $value"
                fi

            #prüft, ob die 10 stellig ISBN nur Zahlen enthält
            elif [[ "$newISBN" = [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] ]]
            then
                value=0

                #berechnet ebenfalls die Summe 
                for ((j=1; j<=${#newISBN}; j++))
                do
                    if [ $j -eq 1 ]
                    then
                        let "value=$value+${newISBN:0:1}"
                    else
                        cache=$(("$j-1")) #muss wegen der ilux so sein
                        let "value=$value+($j*${newISBN:$cache:1})"
                    fi
                done
                
                #berechnet die Summe modulo 11
                mod=$(($value % 11))

                if [ $mod -eq 0 ]
                then
                    continue
                else
                    echo "Die Berechnung stimmt für '$newISBN' nicht! Mod: $mod, Value: $value"
                fi

            #püft, ob die 13 stellige ISBN nur aus Zahlen besteht
            elif [[ "$newISBN" = [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] ]]
            then
                continue

            #ansonsten enthält die ISBN keine gültigen Character 
            else
                echo "Die ISBN '$ISBN' enthält Buchstaben!"
            fi
    done < $File

    unset IFS


    exit 0
}





#--------------longest---------------------------------------
longest()
{
    IFS='|'

    array=()

    #liest die Datei aus
    while read Titel Autoren Schriftenreihe Kategorien Publikationsdatum Verlag Seiten ISBN
    do
        #schreibt jede Seitenanzahl in ein Array
        array+=($Seiten)
    done < $File

    unset IFS

    #sortiert jede Seitenanzahl
    IFS=$'\n' 
    sorted=($(sort -n <<<"${array[*]}")); 
    unset IFS

    #die größte Seitenanzahl steht am Ende vom Array
    seiten=${sorted[-1]}

    IFS='|'
    #ließt die Datei erneut ein und sucht das Buch mit der größten Seitenanzahl
    while read Titel Autoren Schriftenreihe Kategorien Publikationsdatum Verlag Seiten ISBN
    do
        if [ "$Seiten" = "$seiten" ]
        then
            Buch="Das Buch '$Titel' von '$Autoren' ist das größte Buch mit '$Seiten' Seiten"
            break
        fi
    done < $File

    unset IFS

    echo "$Buch"

    exit 0
}





#--------------nopub---------------------------------------
nopub()
{
    IFS='|'

    #ließt die Datei ein und sucht nach Büchern ohne Verlag
    while read Titel Autoren Schriftenreihe Kategorien Publikationsdatum Verlag Seiten ISBN
    do
        if [ "$Verlag" = "" ]
        then
            echo "Das Buch '$Titel' von '$Autoren' hat keinen Verlag"
        fi
    done < $File

    unset IFS

    exit 0
}





#--------------search---------------------------------------
search()
{

    author='author='

    #schneidet "author=" heraus und '@' gibt alle Subparameter von $2 mit
    autor=${@#"$author"}

    IFS='|'

    echo "Titel Autoren Schriftenreihe Kategorien Publikationsdatum Verlag Seiten ISBN"
    while read Titel Autoren Schriftenreihe Kategorien Publikationsdatum Verlag Seiten ISBN
    do
        if [[ "$Autoren" = *"$autor"* ]]
        then
            echo "$Titel $Autoren $Schriftenreihe $Kategorien $Publikationsdatum $Verlag $Seiten $ISBN"
        fi
    done < $File
    

    exit 0
}





#--------------years---------------------------------------
years()
{
   
    while IFS="|" read -r Titel Autoren Schriftenreihe Kategorien Publikationsdatum Verlag Seiten ISBN
    do
        # liest das Publikationsjahr
        if [[ $Publikationsdatum =~ ^[0-9]{4}$ ]] 
        then
            # Jahr hat das Format "yyyy"
            year_extracted=$Publikationsdatum

        elif [[ $Publikationsdatum =~ ^[0-9]{2}\/[0-9]{2}\/([0-9]{4})$ ]]
        then
            # Jahr hat das Format "dd/mm/yyyy"
            year_extracted=${BASH_REMATCH[1]}
        
        elif [[ $Publikationsdatum =~ ^[0-9]{2}\/([0-9]{4})$ ]]
        then
            # Jahr hat das Format "mm/yyyy"
            year_extracted=${BASH_REMATCH[1]}
  
        elif [ "$Publikationsdatum" = "" ]
        then
            # Jahr ist Leer
            year_extracted="unknown"

        else
            # Jahr hat ein unbekanntes Format
            year_extracted="unrecognized"
        fi
  
        # Inkrementiert den Counter
        if [ "$year_extracted" != "unrecognized" ]
        then
            ((year_counts["$year_extracted"]++))
        fi

    done < "$File"

    # Ausgabe
    count=0

    for year in "${!year_counts[@]}"
    do
        # Leereinträge
        if [ "$year" = 0 ]
        then
            echo "Es gibt ${year_counts[$year]} Leereinträge"
            continue
        fi

        echo "Im Jahr $year gibt es ${year_counts[$year]} Bücher"
        count=$(($count+${year_counts[$year]}))
    done


    # Histogramm
    echo ""
    echo "Histogramm: ('-' ist jeweils 1 Eintrag)"
    echo "_______________________________________________________________________________________________ Anzahl"
    echo "|"

    for year in "${!year_counts[@]}"
    do
        # Leereinträge
        if [ "$year" = 0 ]
        then
            echo -n "| Leer: "
            for ((j=1; j<=${year_counts[$year]}; j++))
            do
                echo -n "-"
            done
            continue
        fi

        echo ""
        echo -n "| $year: "

        for ((j=1; j<=${year_counts[$year]}; j++))
        do
            echo -n "-"
        done

    done

    echo ""
    echo "|"
    echo "Jahr"

    exit 0
}


#--------------Main---------------------------------------

#checkt ob die Argumente in Ordnung sind
if [ $# -eq 2 ]
then
    if [[ "$2" = "author="* ]]
    then

        search $2

    else

        echo "Usage: search author=xxxx"
        exit 1

    fi
elif [ $# -eq 1 ]
then
    #ruft die jeweiligen Funkionen auf
    case "$1" in
        categories) categories ;;
        count) count ;;
        isbn) isbn ;;
        longest) longest ;;
        nopub) nopub ;;
        years) years ;;
        *) echo "Usage: <commando>: categories, count, isbn, longest, nopub, years, search <auhor=xxxx>" 
        exit 1 ;;
    esac

else
    echo "Usage: <commando>: categories, count, isbn, longest, nopub, years, search <auhor=xxxx>" 
    echo "Usage: <command> <author=xxxx>"
    echo "'<author=xxxx>' use only if your '<command>' is 'search'"
    exit 1

fi