#!/usr/bin/env bash
tbname=$(zenity --entry --title="Delete table" --text="Enter table name to delete ")
if ! [ -f "$tbname" ]
then 
zenity --error --text="This table doesn't exist"
exit 1
fi
zenity --question --title="Delete table" --text="Are you sure you want to drop table ($tbname)"
if [ $? -eq 0 ]
then 
	rm  $tbname
	zenity --info --text="table $tbname was successfully deleted"
else 
	zenity --info --text="Cancelled"
fi
