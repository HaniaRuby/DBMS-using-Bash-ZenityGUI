#!/bin/bash


tablelist=()
i=1
table_name=""
for table in ./*; do
    [ -f "$table" ] || continue
    table=$(basename "$table")
    tablelist+=("$i" "$table")
    ((i++))
done

    selected=$(zenity --list --title="Choose a Table to insert into" --column="No" --column="Table" --print-column=2 "${tablelist[@]}" --height=400 --width=350)

    table_name="$selected"
if [[ -z "$selected" ]]
then
	zenity --error --text="No table selected"
	exit 1
fi


loadmetadata(){
	local file="$table_name"
	metadata_inside=false
	meta_file=""

	firstline=$(head -n1 "$file")
	if [[ "$firstline" == column=* ]]
	then
		metadata_inside=true
		DATA_START=3
		meta_file="$file"
	elif [[ -f "$file.meta" ]]
		then
		meta_file="$file.meta"
		DATA_START=1
	else
		zenity --error --title="Error" --text="Metadata not found"
		exit 1
	fi

	cols_line=$(grep "^column=" "$meta_file" | head -n1 | cut -d "=" -f2)
	IFS="," read -ra cols_array <<< "$cols_line"

	realcollist=()
	realtypeslist=()

	for coldef in "${cols_array[@]}"
	do
	name="${coldef%%:*}"
	type="${coldef##*:}"
	realcollist+=("$name")
	realtypeslist+=("$type")
	done

	primary_key=$(grep "^primary_key=" "$meta_file" |head -n1 | cut -d "=" -f2)
}

loadmetadata
echo "primary key = $primary_key"
echo "col names = ${realcollist[@]}"
echo "col types = ${realtypeslist[@]}"

col_values=()
for (( i=0; i<${#realcollist[@]}; i++ ))
do
col_value=$(zenity --entry \
    --title="Insert to Table1" \
    --text="Enter value to insert into column ${realcollist[i]}:")
    col_values+=("$col_value")
    	
    	if [[ -z "$col_value" ]]
	then
	    zenity --error --text="Column value missing"
	    exit 1

	elif [[ "$col_value" =~ [^a-zA-Z0-9_\.\-] ]]
	then
	    zenity --error --text="Invalid characters. Only letters, numbers, underscore (_), dot (.), and spaces allowed."
	    exit 1
	    
	elif [[ ${realtypeslist[i],,} == "integer" ]]
	then
		if ! [[ "$col_value" =~ ^[0-9]+$ ]]
		then
		zenity --error --text="Invalid. Type is int."
		exit 1
		fi
	elif [[ ${realtypeslist[i],,} == "float" ]]
	then
		if ! [[ "$col_value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]
		then
		zenity --error --text="Invalid. Type is float."
		exit 1
		fi
	elif [[ ${realtypeslist[i],,} == "string" ]]
	then
		if ! [[ "$col_value" =~ ^[^,]+$ ]]
		then
		zenity --error --text="Invalid. Type is string."
		exit 1
		fi
	elif [[ ${realtypeslist[i],,} == "boolean" ]]
	then
		if ! [[ "$col_value" =~ ^(true|false)$ ]]
		then
		zenity --error --text="Invalid. Type is boolean."
		exit 1
		fi
	
	fi

done

pk_index=-1
for (( i=0; i<${#realcollist[@]}; i++ )); do
    if [[ "${realcollist[i]}" == "$primary_key" ]]; then
        pk_index=$i
        break
    fi
done

pk_value="${col_values[pk_index]}"

if [[ -z "$pk_value" ]]; then
    zenity --error --text="Primary key not null"
    exit 1
fi

while IFS= read -r line; do
    read -ra fields <<< "$line"

    existing_pk_val="${fields[pk_index]}"

    if [[ "$existing_pk_val" == "$pk_value" ]]; then
        zenity --error --text="Primary key value '$pk_value' already exists."
        exit 1
    fi

done < <(tail -n +"$DATA_START" "$table_name")


zenity --info --text="Row inserted"
echo "Inserted row: $row"

echo "col vals = ${col_values[@]}"
