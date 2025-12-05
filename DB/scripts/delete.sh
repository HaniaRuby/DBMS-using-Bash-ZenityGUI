#!/usr/bin/env bash

# Ask for table name
read -p "Please enter table name: " tbname

# Check if table exists
if ! [ -f "$tbname" ]; then
    echo "Table doesn't exist"
    exit 1
fi

# Set PS3 prompt for select menu
PS3="Delete> "
echo "Select an option:"

select option in "Delete all" "Delete by PK" "Delete by name" "Back"; do
    case $REPLY in
        1)
            # Delete all rows (keep header)
            header=$(head -n1 "$tbname")
            echo "$header" > "$tbname"
            # Optionally keep primary key comment line
            secondline=$(sed -n '2p' "$tbname")
            if [[ "$secondline" =~ ^#primary_key= ]]; then
                echo "$secondline" >> "$tbname"
            fi
            echo "All rows are deleted"
            ;;
        2)
            # Delete by primary key
            read -p "Enter primary key value to delete: " pk
            if [[ -z "$pk" ]]; then
                echo "No value entered."
                continue
            fi
            header=$(head -n1 "$tbname")
            secondline=$(sed -n '2p' "$tbname")
            data_start=2
            if [[ "$secondline" =~ ^#primary_key= ]]; then
                data_start=_

