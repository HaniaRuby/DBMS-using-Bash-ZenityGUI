#!/usr/bin/bash
dbname=$(zenity --entry --title="Drop Database" --text="Enter Database Name: " )
if [ -z myDB/$dbname ]
then
zenity --error --text="Enter database name"
    exit 1
    
if [ ! -d myDB/$dbname ]
then
    zenity --error --text="Database does not exist"
    exit 1
fi
zenity --question --title="confirm Delete" --text="Are you sure you want to drop this Database '$dbname'"
if [ $? -eq 0 ]
then 
	rm -r myDB/$dbname
	zenity --info --text="Database $dbname was successfully deleted"
else 
	zenity --info --text="Cancelled"
fi