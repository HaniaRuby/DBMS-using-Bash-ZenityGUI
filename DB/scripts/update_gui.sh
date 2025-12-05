#!/usr/bin/env bash

DB_PATH="$1"
cd "$DB_PATH" || { zenity --error --text="Cannot enter database directory"; exit 1; }


tbname=$(zenity --entry --title="Update Table" --text="Enter table name:")
[ -z "$tbname" ] && exit 1
[ ! -f "$tbname" ] && zenity --error --text="This table doesn't exist!" && exit 1

loadmetadata(){
	local file="$tbname"
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

echo $primary_key
echo ${realcollist[@]}

pk_val=$(zenity --entry --title="Select row pk" --text="Enter pk value to update its row:")
[ -z "$pk_val" ] && exit 1

echo $pk_val
# Check if PK exists (skip first line, space-separated)
if ! awk -v pk="$pk_val" -v start="$DATA_START" 'NR>=start && $1==pk {found=1} END{exit !found}' "$tbname"; then
    zenity --error --text="No row found with pk $pk_val"
    exit 1
fi

# Ask which column to update
colname=$(printf "%s\n" "${realcollist[@]}" | zenity --list --title="Choose column to update" --column="Column")
[ -z "$colname" ] && exit 1

colindex=-1
for (( i=0; i<${#realcollist[@]}; i++ )); do
    if [[ "${realcollist[i]}" == "$colname" ]]; then
        colindex=$i
        break
    fi
done

# Ask for new value
newval=$(zenity --entry --title="New Value" --text="Enter new value for '$colname':")

if [[ -z "$newval" ]]
	then
	    zenity --error --text="Column value missing"
	    exit 1

	elif [[ "$newval" =~ [^a-zA-Z0-9_\.\-] ]]
	then
	    zenity --error --text="Invalid characters. Only letters, numbers, underscore (_), dot (.), and spaces allowed."
	    exit 1
	    
	elif [[ ${realtypeslist[colindex],,} == "integer" ]]
	then
		if ! [[ "$newval" =~ ^[0-9]+$ ]]
		then
		zenity --error --text="Invalid. Type is int."
		exit 1
		fi
	elif [[ ${realtypeslist[colindex],,} == "float" ]]
	then
		if ! [[ "$newval" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]
		then
		zenity --error --text="Invalid. Type is float."
		exit 1
		fi
	elif [[ ${realtypeslist[colindex],,} == "string" ]]
	then
		if ! [[ "$newval" =~ ^[^,]+$ ]]
		then
		zenity --error --text="Invalid. Type is string."
		exit 1
		fi
	elif [[ ${realtypeslist[colindex],,} == "boolean" ]]
	then
		if ! [[ "$newval" =~ ^(true|false)$ ]]
		then
		zenity --error --text="Invalid. Type is boolean."
		exit 1
		fi
	
	fi
echo "colindex = $colindex"

#---3shan el duplicates ll marra el million---
if awk -v start="$DATA_START" -v v="$newval" '
NR < start { next }
{
  # trim trailing CR from each field1 and remove leading/trailing whitespace
  f = $1
  sub(/\r+$/,"", f)
  sub(/^[ \t]+/,"", f)
  sub(/[ \t]+$/,"", f)
  if (f == v) { found=1; exit }
}
END { exit (found ? 0 : 1) }
' "$tbname"; then
    zenity --error --text="Primary key value '\''$newval'\'' already exists. Aborting."
    exit 1
fi



# Find column index (1-based) in data rows
colnum=$((colindex + 1))

echo $colnum
# Update row (skip header, update space-separated data)
awk -v pk="$pk_val" -v idx="$colnum" -v val="$newval" -v start="$DATA_START" '
NR < start { print; next }
{
    if ($1 == pk) $idx = val
    print
}' "$tbname" > tmp && mv tmp "$tbname"

zenity --info --text="Row with PK '$pk_val' updated successfully!"
