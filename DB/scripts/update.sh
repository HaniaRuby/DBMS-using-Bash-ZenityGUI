#!/usr/bin/env bash
#getting table name
read -p "Please enter table name " tbname 
[ -z "$tbname" ] && echo "No table name entered." && exit 1
if ! [ -f "$tbname" ]
then 
echo "Table doesn't exist"
exit 1
fi
#parsing the metadata and getting column of primary key
metadata=$(head -n1 "$tbname")
IFS=':' read -ra cols <<< "$metadata"
pk_name=${cols[0]}
echo "Primary Key column = $pk_name"
#getting pk value whose row would be changed
read -p "enter primary value: " pk_val
[ -z "$pk_val" ] && echo "No PK value entered." && exit 1
if ! grep -q "^$pk_val:" "$tbname" 
then
echo "No row found with PK = $pk_val"
exit 1
fi
#choosing column then entering the new value to be set
read -p "Enter column to update: " colname
[ -z "$colname" ] && echo "No column name entered." && exit 1
#finding cols indices from cols names and adding 1 because awk indexing starts from 1 not 0
colnum=$(echo "$metadata" | tr ':' '\n' | grep -n "^$colname$" | cut -d: -f1)
if [ -z "$colnum" ]
then
echo "Column '$colname' not found."
exit 1
fi
read -p "Enter new value: " newval
[ -z "$newval" ] && echo "No new value entered." && exit 1
awk -F: -v OFS=: -v pk="$pk_val" -v idx="$colnum" -v val="$newval" '
NR==1 {print; next}$1 == pk {$idx = val}{print}' "$tbname" > tmp && mv tmp "$tbname"
echo "Row with PK = $pk_val updated: $colname = '$newval'"

