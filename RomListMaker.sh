#!/bin/bash
clear

if ! command -v xpath &> /dev/null; then
    echo -e "\n\n\nThe 'xpath' command is not installed.\n\nMaybe try: sudo apt install libxml-xpath-perl\n\n"
    exit 1
fi

echo -e "\n\n\n\n"
echo -e "MAME Rom List Maker.\n\n"

if [ $# -eq 0 ]; then
    echo -e "**** Usage: $0 <XML filename> ****\n\n"
    exit 1
fi

if [ -e "$1" ]; then
    echo -e "$1 File exists. Good.\n\n"
else
    echo -e "**** $1 File does not exist. Maybe its called GameList.xml? ****\n\n"
    exit 1
fi

RunCommand="xpath -n -p '    ' -q -e '/mame/machine[not (@ismechanical=\"yes\")  and not (@runnable=\"no\")"
OutputFileName="GameList-"

echo
read -p "Parent ROM's only? (Y/n) " -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]; then
    RunCommand=$RunCommand"]"
else
    RunCommand=$RunCommand" and not (@cloneof)]"
    OutputFileName=$OutputFileName"Parents"
fi

echo
read -p "Playable Rom's only? (Y/n) " -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]; then
    RunCommand=$RunCommand
else
    RunCommand=$RunCommand"/driver[@status=\"good\" or @status=\"imperfect\"]//parent::machine" 
    OutputFileName=$OutputFileName"Playable"
fi

echo
read -p "Cocktail Table dipswitch Rom's only? (y/N) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    RunCommand=$RunCommand"/dipswitch/dipvalue[@name=\"Cocktail\"]//parent::dipswitch//parent::machine'"
#    RunCommand=$RunCommand"/configuration/confsetting[@name=\"Cocktail\"]//parent::configuration//parent::machine'"
    OutputFileName=$OutputFileName"Cocktail"
else
    RunCommand=$RunCommand"'"
fi

echo
read -p "Would you like to add the CLONE Pacman? (y/N) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    PacManMachine=""
    echo -e "\n\nLooking for the Pacman Machine in $1. This might take a little while."
    # Read the file line by line
    while IFS= read -r line; do
      # Check if the line contains "name="pacman""
      if [[ $line == *"name=\"pacman\""* ]]; then
        # Store the line in the PacManMachine variable
        PacManMachine="$line"$'\n'
        echo "Found the start of Pacman."
        # Continue reading the file
        while IFS= read -r line; do
          # Add the line to the PacManMachine variable
          PacManMachine+="$line"$'\n'
          
          # Check if the line contains "</machine>"
          if [[ $line == *"</machine>"* ]]; then
            echo "Found the end of Pacman."
            # Exit the inner loop
            break
          fi
        done
        
        # Exit the outer loop
        break
      fi
    done < "$1"
    OutputFileName=$OutputFileName"Pacman"
fi

# Copy the DTD and the mame tag with all of it attributes
DTDHeader=""
echo "Reading DTD header."
while IFS= read -r line; do
    # Append each line to the     DTDHeader variable
        DTDHeader+="$line"$'\n'
    # Check if the line contains "<name>"
    if [[ $line == *"<mame"* ]]; then
        break  # Exit the loop after reaching "<name>"
    fi
done < "$1"

OutputFileName=$OutputFileName".xml"
RunCommand="$RunCommand $1 >> $OutputFileName"

echo
if [ -e "$OutputFileName" ]; then
    echo -e "\n\n\n\n"
    echo -e "**** $OutputFileName already exists. Delete it first then run this again. ****\n\n"
    echo
    echo "I was going to run (but didn't): $RunCommand"
    echo -e "\n\n"
    exit 1
else
    echo -e "\n\n\n\n"
    echo "Running: $RunCommand"
    echo
    echo "Outputfile: $OutputFileName"
    echo
    echo "This will take a long time on a modern MAME gamelist.  It will take minutes, maybe dozens of minutes.  Press ctrl-c to bail out before it finishes."
    echo -e "\n\n\n\n"
    echo "$DTDHeader" > $OutputFileName
    eval "$RunCommand"
    echo "$PacManMachine" >> $OutputFileName
    echo "</mame>" >> $OutputFileName
    echo -e "\n\n\n\n"
fi
