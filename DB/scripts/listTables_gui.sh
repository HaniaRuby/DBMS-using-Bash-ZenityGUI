#!/usr/bin/env bash
if [ ! -d "$(pwd)" ]; then
    zenity --error --text="Not inside a database folder!"
    exit 1
fi
tables=$(ls -1)
if [ -z "$tables" ]
then
    zenity --info --text="No tables found in database '$(basename $(pwd))'."
    exit 0
fi
zenity --list \
    --title="Tables in $(basename $(pwd))" \
    --column="Table Name" \
    $tables \
    --height=800 --width=600

