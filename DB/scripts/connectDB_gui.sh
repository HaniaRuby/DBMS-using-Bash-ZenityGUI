#!/usr/bin/env bash
dbname=$(zenity --entry --title="Connect to a Database"      --text="Enter Database name to connect ")
if [ -z "$dbname" ]; then
    exit 0
fi
if ! [ -d myDB/$dbname ]
then 
zenity --error --text=" Database $dbname doesn't exist "
exit 1
fi
zenity --info --text="Connected to Database $dbname"
cd myDB/$dbname
while true
 do

    choice=$(zenity --list \
        --title="Database: $dbname" \
        --column="Option" --column="Description" \
        1 "Create Table" \
        2 "Drop Table" \
        3 "List Tables" \
        4 "Insert into Table" \
        5 "Delete from Table" \
        6 "Select From Table" \
        7 "Update Table" \
        8 "Back" \
        --height=400 --width=350)

    case $choice in
        1) ../../scripts/createTable_gui.sh ;;
        2) ../../scripts/dropTable_gui.sh ;;
        3) ../../scripts/listTables_gui.sh ;;
        4) ../../scripts/insert_gui.sh ;;
        5) ../../scripts/delete_gui.sh ;;
        6) ../../scripts/select_gui.sh ;;
        7) ../../scripts/update_gui.sh ;;
        8) cd ../.. ; break ;;
        *) exit 0 ;;
    esac

done
