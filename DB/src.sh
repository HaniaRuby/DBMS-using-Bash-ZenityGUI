#!/usr/bin/bash
select item in "Create Database" "List Database" "Connect to Database" "Drop Database" "Exit"
do
case $item in 
1) read -p "Enter Database Name" dbname
# checking if name exists
if [ -d DB/$dbname ]
then 
echo "Name exists choose another name"
 exit 1
fi
#checking if it contains a regex
if ! [[ $dbname = ~ ^[ A-Za-z0-9_- ]+$ ]]
then 
echo "Invalid name only letters , numbers,_,- are allowed"
exit 1
fi
#creating db directory with the chosen name
mkdir DB/$dbname
echo " Database $dbname was successfully created"
;;
2)echo "Wait listing your Databases"
ls -F DB | grep /
;;
3) read -p "Enter Database name to connect" dbname
if [[ -d DB/$dbname ]]
then 
echo " Wait to connect to Database $dbname"
cd DB/$dbname
else
echo "File doesn't exist"
fi 
;;
4) read -p "Enter Database Name" dbname
if [[ -d DB/$dbname ]]
then
read -p "Are you sure you want to drop this Database" choice
if [[ $choice = ~^[Y-y]$ ]]
then 
rm -r DB/$dbname
echo "Database $dbname was successfully deleted"
else 
echo "Cancelled"
fi
else 
echo "Database $dbname doesn't exist"
fi
;;
5)echo "Bye"
exit
esac
done



