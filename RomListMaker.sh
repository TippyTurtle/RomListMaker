#!/bin/bash
clear

# xpath -q -e '/mame/machine[not (@cloneof) and not (@isbios="yes")]/driver[@status="good" or @status="imperfect"]//parent::machine/dipswitch/dipvalue[@name="Cocktail"]//parent::dipswitch//parent::machine//parent::mame' GameList.xml

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

# Initialize a variable to store XML content
xml_content=""

# Read the XML file line by line
while IFS= read -r line; do
    # Append each line to the xml_content variable
    xml_content+="$line"$'\n'
    # Check if the line contains "<name>"
    if [[ $line == *"<mame"* ]]; then
        break  # Exit the loop after reaching "<name>"
    fi
done < "$1"

RunCommand="xpath -q -e '/mame/machine"
OutputFileName="GameList-"

echo
read -p "Parent ROM's only? (Y/n) " -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]; then
    RunCommand=$RunCommand"[not (@isbios=\"yes\")]/driver"
else
    RunCommand=$RunCommand"[not (@cloneof) and not (@isbios=\"yes\")]/driver"
    OutputFileName=$OutputFileName"Parents"
fi

echo
read -p "Playable Rom's only? (Y/n) " -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]; then
    RunCommand=$RunCommand
else
    RunCommand=$RunCommand"[@status=\"good\" or @status=\"imperfect\"]" 
    OutputFileName=$OutputFileName"Playable"
fi

echo
read -p "Cocktail Table dipswitch Rom's only? (y/N) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    RunCommand=$RunCommand"//parent::machine/dipswitch/dipvalue[@name=\"Cocktail\"]//parent::dipswitch//parent::machine'"
#    RunCommand=$RunCommand"//parent::machine/configuration/confsetting[@name=\"Cocktail\"]//parent::configuration//parent::machine'"
    OutputFileName=$OutputFileName"Cocktail"
else
    RunCommand=$RunCommand"//parent::machine'"
fi

OutputFileName=$OutputFileName".xml"
RunCommand="$RunCommand $1 >> $OutputFileName" 

echo
if [ -e "$OutputFileName" ]; then
    echo -e "\n\n\n\n"
    echo -e "**** $OutputFileName already exists. Delete it first then run this again. ****\n\n"
    echo
    echo "I was going to run (but didn't): $RunCommand"
    echo -e "\n\n\n\n"
    exit 1
else
    echo -e "\n\n\n\n"
    echo "Running: $RunCommand"
    echo
    echo "Outputfile: $OutputFileName"
    echo -e "\n\n\n\n"
    echo "$xml_content" > $OutputFileName
    eval "$RunCommand"
    echo "</mame>" >> $OutputFileName
    echo -e "\n\n\n\n"
fi
