#!/usr/bin/env bash

# Select Table
table_name=$(zenity --entry --title="Delete from Table" --text="Enter table name:")
[ -z "$table_name" ] && exit 1
[ ! -f "$table_name" ] && zenity --error --text="Table not found!" && exit 1

# Read header
header=$(head -n1 "$table_name")
IFS=':' read -ra columns <<< "$header"

# Check for primary key comment line
secondline=$(sed -n '2p' "$table_name")
if [[ "$secondline" =~ ^#primary_key=(.+)$ ]]; then
    primary_key="${BASH_REMATCH[1]}"
    DATA_START=3
else
    primary_key="${columns[0]}"
    DATA_START=2
fi

# Ask for PK to delete
pk_value=$(zenity --entry --title="Delete by PK" --text="Enter primary key value to delete:")
[ -z "$pk_value" ] && exit 1

# Find PK column index
pk_index=-1
for i in "${!columns[@]}"; do
    if [[ "${columns[i]}" == "$primary_key" ]]; then
        pk_index=$i
        break
    fi
done
[ $pk_index -eq -1 ] && zenity --error --text="Primary key column not found!" && exit 1

# Rewrite table: keep metadata, remove matching row(s)
{
    # Write header
    echo "$header"
    # Write primary key comment if present
    [[ "$secondline" =~ ^#primary_key= ]] && echo "$secondline"

    # Filter rows
    tail -n +$DATA_START "$table_name" | while IFS= read -r line; do
        # Skip metadata just in case
        [[ "$line" == column=* ]] && continue
        [[ "$line" == \#primary_key=* ]] && continue

        # Split fields
        read -ra fields <<< "$line"
        # Only keep rows whose PK does NOT match
        if [[ "${fields[pk_index]}" != "$pk_value" ]]; then
            echo "$line"
        fi
    done
} > tmp && mv tmp "$table_name"

zenity --info --text="Row(s) with primary key '$pk_value' deleted successfully."

