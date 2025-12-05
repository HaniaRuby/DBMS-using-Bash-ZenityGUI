#!/bin/bash

mkdir -p myDB
mkdir -p scripts

while true
do
    choice=$(zenity --list \
        --title="DBMS" \
        --column="Choose an Option" \
        "Create Database" \
        "List Databases" \
        "Connect to Database" \
        "Drop Database" \
        "Exit"  --height=800 --width=600)

    case "$choice" in

        "Create Database")
            ./scripts/createDB_gui.sh
        ;;

        "List Databases")
            ./scripts/listDB_gui.sh
        ;;

        "Connect to Database")
            ./scripts/connectDB_gui.sh
        ;;

        "Drop Database")
            ./scripts/dropDB_gui.sh
        ;;

        "Exit")
            exit
        ;;

    esac
done


