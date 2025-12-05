#!/usr/bin/env bash
read -p "Choose a database to list " dbname
if ! [ -d myDB/$dbname ]
then 
echo "Database $dbname doesn't exist"
exit 1
fi
echo "Listing tables in Database $dbname"
ls myDB/$dbname
