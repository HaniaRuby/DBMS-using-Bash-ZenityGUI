#!/bin/bash

table_name=$(zenity --entry \
    --title="Create Table" \
    --text="Enter table name:")

if [[ -z "$table_name" ]]
then
    zenity --error --text="No table name entered. Cancelled."
    exit 1
fi

if [[ -f "$table_name" ]]
then
    zenity --error --text="Table exists. Cancelled."
    exit 1
fi

if [[ "$table_name" =~ [\+\?\[\]\(\)\$\^\|\\] ]]
then
    zenity --error --text="Invalid characters in command. Only letters, numbers, _, ., *, and spaces allowed."
    exit 1
elif [[ "$table_name" =~ ^[0-9] ]]
then
    zenity --error --text="Table name cannot start with a number."
    exit 1
elif [[ "$table_name" =~ [^a-zA-Z0-9_\.] ]]
then
    zenity --error --text="Invalid characters. Only letters, numbers, underscore (_), dot (.), and spaces allowed."
    exit 1
    
elif [[ "${table_name,,}" == "select" || "${table_name,,}" == "where" || "${table_name,,}" == "from" || "${table_name,,}" == "all" ]]; then
    zenity --error --text="Table name cannot be a keyword (select, where, from, all)."
    exit 1
fi


num_cols=$(zenity --entry \
    --title="Create Table" \
    --text="How many columns?" \
    --entry-text="3")

if [[ -z "$num_cols" ]]
then
    zenity --error --text="No column count entered. Cancelled."
    exit 1
    
elif (("$num_cols" < 1 ))
then
zenity --error --text="Must have at least one column"
    exit 1
fi


cols_pairs=()
colnames=()
coltypes=()
for (( i=1; i<=num_cols; i++ ))
do
    col_name=$(zenity --entry \
        --title="Column $i" \
        --text="Enter column $i name:")
    
	if [[ -z "$col_name" ]]
	then
	    zenity --error --text="Column name missing"
	    exit 1

	elif [[ "$col_name" =~ ^[0-9] ]]
	then
	    zenity --error --text="Column name cannot start with a number."
	    exit 1

	elif [[ "$col_name" =~ [^a-zA-Z0-9_\.] ]]
	then
	    zenity --error --text="Invalid characters. Only letters, numbers, underscore (_), dot (.), and spaces allowed."
	    exit 1

	elif [[ " ${collist[*],,} " == *" ${col_name,,} "* ]]
	then
	    zenity --error --text="Column name already exists."
	    exit 1

	elif [[ "${col_name,,}" == "select" || "${col_name,,}" == "where" || "${col_name,,}" == "from" || "${col_name,,}" == "all" ]]
	then
	    zenity --error --text="Column name cannot be a keyword (select, where, from, all)."
	    exit 1
	fi

    
    col_type=$(zenity --list \
        --title="Column ${col_name}" \
        --column="Choose a data type" \
        "String" \
        "Integer" \
        "Float"\
        "Boolean"
        --height=400 --width=200) 
        
    
    if [[ -z "$col_type" ]]
    then
        zenity --error --text="Column type missing."
        exit 1
    fi
    
    colnames+=("$col_name")
    coltypes+=("$col_type")
    cols_pairs+=("$col_name:$col_type")
done

cols_header=$(IFS=, ; echo "${cols_pairs[*]}")


    primary_key=$(zenity --list --title="Choose a Primary Key" --column="Column" "${colnames[@]}" --height=400 --width=350)
if [[ -z "$primary_key" ]]
    then
    zenity --error --text="Primary key missing."
        exit 1
fi


echo "Table: $table_name ${cols_header[@]}"
echo "column types=$coltypes"
echo "column=$cols_header" >> "$table_name"
echo "primary_key=$primary_key" >> "$table_name"


zenity --info \
    --title="Success" \
    --text="Table '$table_name' created successfully!"
    
../../scripts/insert_gui.sh
