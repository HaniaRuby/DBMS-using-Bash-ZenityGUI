#!/usr/bin/bash
dbname=$(zenity --entry --title="Create Database" --text="Enter Database name: ")
if [ -z "$dbname" ]
then 
exit 1
fi
if [ -d myDB/$dbname ]
then
    zenity --error --text="Database already exists"
    exit 1
fi

if [[ ! "$dbname" =~ ^[A-Za-z][A-Za-z0-9_-]*$ ]]

 then
    zenity --error --text="Invalid name! Only letters,numbers,_ and - allowed."
    exit 1
fi

mkdir myDB/$dbname
zenity --info --text="Database '$dbname' created."
