#!/bin/bash


tablelist=()
i=1

for table in ./*; do
    [ -f "$table" ] || continue
    table=$(basename "$table")
    tablelist+=("$i" "$table")
    ((i++))
done

    selected=$(zenity --list --title="Choose a Table" --column="No" --column="Table" --print-column=2 "${tablelist[@]}" --height=400 --width=350)

    table_name="$selected"
if [[ -z "$table_name" ]]
then
	zenity --error --text="No table selected"
	exit 1
fi


    user_cmd=$(zenity --entry --title="Command for table: $table_name" \
        --text="Type a select command:" --entry-text="select all from $table_name" --width=400)

if [[ -z "$user_cmd" ]]
then
	zenity --error --text="Empty command."
	exit 1
fi
if [[ "$user_cmd" =~ [\+\?\[\]\(\)\$\^\|\\] ]]; then
    zenity --error --text="Invalid characters in command. Only letters, numbers, _, ., *, and spaces allowed."
    exit 1
fi

if [[ "${user_cmd,,}" != select* ]]; then
    zenity --error --text="Invalid command. Command must start with SELECT."
    exit 1
fi

word_count=$(echo "$user_cmd" | wc -w)
if (( word_count < 4 )); then
    zenity --error --text="Invalid command. Command must have at least 4 words."
    exit 1
fi

#------------------------------functions def------------------------------#

#3ndna keywords eh w makanha fen
findfrom() {
    has_from=false
    local argss=("$@")

    for (( i=0; i<$#; i++ )); do
        if [[ "${argss[$i],,}" == "from" ]]; then
            has_from=true
            from_index=$i
            echo "this has from at $i"
            break
        fi
    done
    
    if [[ $has_from == false ]]
    then
        zenity --error --title="Syntax Error" --text="Missing FROM"
	exit 1
    fi
}

finddistinct() {
    has_distinct=false
    local argss=("$@")

    for (( i=0; i<$#; i++ )); do
        if [[ "${argss[$i],,}" == "distinct" ]]; then
            has_distinct=true
            distinct_index=$i
            echo "this has distinct at $i"
            break
        fi
    done
}

findall() {
    has_all=false
    local argss=("$@")

    for (( i=0; i<$#; i++ )); do
        if [[ "${argss[$i]}" == "*" || "${argss[$i],,}" == "all" ]]; then
            has_all=true
            all_index=$i
            echo "this has all/* at $i"
            break
        fi
    done
}

findwhere() {
    has_where=false
    local argss=("$@")

    for (( i=0; i<$#; i++ )); do
        if [[ "${argss[$i],,}" == "where" ]]; then
            has_where=true
            where_col="${argss[$((i+1))]}"
            where_op="${argss[$((i+2))]}"
            where_val="${argss[$((i+3))]}"
            echo "this has where at $i"
            break
        fi
    done
}

findusercolumns(){
if [[ $has_distinct == true ]]
then
	collist=()
	for (( i=2; i<from_index; i++ ))
		do
			collist+=("${args[i]}")
			echo "${collist[i-2]}"
		done
else
	collist=()
	for (( i=1; i<from_index; i++ ))
		do
			collist+=("${args[i]}")
			echo "${collist[i-1]}"
		done
fi
}

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
elif [[ -f "${file}.meta" ]]
then
    meta_file="${file}.meta"
    DATA_START=1
else
    zenity --error --title="Error" --text="Metadata not found"
    exit 1
fi


 cols_line=$(grep "^column=" "$meta_file" | head -n1 | cut -d "=" -f2-)
    if [[ -z "$cols_line" ]]; then
        zenity --error --title="Error" --text="Metadata 'column=' not found in $meta_file"
        exit 1
    fi
    
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

findrealcolumns(){
loadmetadata

    echo "Columns: ${realcollist[*]}"
    echo "Types:   ${realtypeslist[*]}"
    echo "PK:      $primary_key"
    echo "Data starts at: $DATA_START"
}

validatecolumns(){
if [[ $has_all == false ]]
then
        collist1=("${collist[@]}")

	if [[ $has_where == true ]]
	then
            collist1+=("$where_col")

	fi

	for (( i=0; i<${#collist1[@]}; i++ ))
	do
		found=false
		for (( j=0; j<${#realcollist[@]}; j++ ))
		do
		if [[ "${collist1[i],,}" == "${realcollist[j],,}" ]]
		then
			found=true
			break
		fi
		done
		
		if [[ $found == false ]]
		then
		zenity --error --title="Syntax Error" --text="Column ${collist1[i]} not found"
		exit 1
		fi
		
	done
fi
}

selectWhere(){

col_index=0
for i in "${!realcollist[@]}"
do
	if [[ "${realcollist[i],,}" == "${where_col,,}" ]]
	then
		col_index=$((i+1))
		break
	fi
done

if [[ -z "$col_index" || "$col_index" -eq 0 ]]; then
    zenity --error --title="Syntax Error" --text="Column $where_col not found"
    exit 1
fi

    if [[ "$metadata_inside" == true ]]
    then
        awk -v col="$col_index" -v val="$where_val" -v start="$DATA_START" 'NR==start {print; next} NR>start {if(tolower($col) == tolower(val)) print}' "$table_name"
else
    # Header is external, print it first
    echo "${realcollist[@]}"
    awk -v col="$col_index" -v val="$where_val" -v start="$DATA_START" \
        'NR>=start {if(tolower($col) == tolower(val)) print}' "$table_name"
fi
}

colselect() {

    col_indices=()
    for usercol in "${collist[@]}"
    do
    	for (( i=0; i<${#realcollist[@]}; i++));
    	do
    	if [[  "${usercol,,}" == "${realcollist[i],,}" ]]
    	then
		col_indices+=($((i+1)))
	fi
	done
    done

    idx_string="${col_indices[*]}"

    awk -v cols="$idx_string" -v start="$DATA_START" '
        BEGIN {
            n = split(cols, idx, " ")
        }
        {
        split($0, fields, /[[:space:]]+/) #3shan el no output problem
            out=""
            for (j = 1; j <= n;  j++) {
                colnum = idx[j]
                out = out fields[colnum] "|" # no output problem bardo
            }
             sub(/\|$/, "", out) 
            print out
        }
    ' "${1:-/dev/stdin}"

}


#------------------------------functions call------------------------------#

cmd_lower="${user_cmd,,}"
cmd_lower=$(echo "$cmd_lower" | xargs)

args=($cmd_lower)


findrealcolumns
findfrom "${args[@]}"
finddistinct "${args[@]}"
findall "${args[@]}"
if [[ "$has_all" == true ]]; then
    collist=("${realcollist[@]}")
fi
findwhere "${args[@]}"
findusercolumns

usercollist=("${collist[@]}")

validatecolumns

echo "User cols: ${collist[@]}"
echo "Real cols: ${realcollist[@]}"

#------------------------------whtvs------------------------------#


if [[ "$cmd_lower" == "select all from $table_name" ]] || [[ "$cmd_lower" == "select * from $table_name" ]]
then
	output=$(sed -n  "${DATA_START},\$p" $table_name)
        
elif [[ "$has_distinct" == true && "$has_where" == true && "$has_all" == true ]]
then

	output=$(selectWhere | sort -u)
	
	
elif [[ "$has_where" == true && "$has_all" == true ]]
then

	output=$(selectWhere)

    
elif [[ "$has_distinct" == true && "$has_where" == true && "$has_all" == false ]]
then

	output=$(selectWhere | colselect | sort -u)
     
elif [[ "$has_where" == true ]] 
then

	output=$(selectWhere | colselect)
    
else

	 output=$(colselect "$table_name")
fi

outline_count=$(echo "$output" | wc -l)
if (( $outline_count < 1 ))
then 
	zenity --info --title="No Return" --text="No rows returned from the query."
	
else

prepare_rows() {
    rows=""
    if [[ "$has_all" == true ]]; then
        # SELECT * or SELECT all
        while IFS= read -r line; do
            rows+=$(echo "$line" | tr ' ' '|')
            rows+=$'\n'
        done < <(awk -v start="$DATA_START" 'NR>=start {print $0}' "$table_name")
    else
        rows="$output"
    fi
}


columns=()
for col in "${realcollist[@]}"; do
    columns+=("--column=$col")
done

row_args=()
while IFS='|' read -ra fields; do
    for f in "${fields[@]}"; do
        row_args+=("$f")
    done
done <<< "$rows"
fi
echo "${output[@]}"

# ----------------------Display YA RAB----------------------

if [[ "${has_all:-false}" != true ]]; then
    if [[ -n "${output// }" ]]; then

        output="$(printf "%s\n" "$output" | colselect)"
    fi
else
    :
fi


# Build header and rows correctly so zenity receives a matching number of columns and cells.

if [[ "${has_all:-false}" == true ]]; then
    header=("${realcollist[@]}")
    if [[ "${has_where:-false}" == true && -n "${output// }" ]]; then
        raw_lines="$output"
        raw_format="whitespace"
    else
        raw_lines="$(tail -n +"$DATA_START" "$table_name")"
        raw_format="whitespace"
    fi
else
    header=("${usercollist[@]}") # kol dah 3shan zenity
    if grep -q '|' <<< "$output"; then
        raw_lines="$output"
        raw_format="pipe"
    else
        raw_lines="$(printf "%s\n" "$output" | colselect)" 
        raw_format="pipe"
    fi
fi

num_cols=${#header[@]}
if (( num_cols == 0 )); then
    zenity --error --title="Internal Error" --text="No columns found for display."
    exit 1
fi


columns_args=()
for col in "${header[@]}"; do
    columns_args+=( "--column=$col" )
done

row_args=()

if [[ "$raw_format" == "pipe" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        IFS='|' read -ra fields <<< "$line"
        for ((i=0;i<num_cols;i++)); do
            row_args+=( "${fields[i]:-}" )
        done
    done <<< "$raw_lines"
else
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue #a5er 7al el awk
        awk_prog='{
            for(i=1;i<='"$num_cols"';i++){
                if(i<=NF) {
                    gsub(/"/,"\\\"",$i);
                    printf("%s", $i)
                } else {
                    printf("")
                }
                if(i<'"$num_cols"') printf("\x1f") # unit separator as internal delimiter
            }
            printf("\n")
        }'
        parsed="$(awk "$awk_prog" <<< "$line")"
        IFS=$'\x1f' read -ra fields <<< "$parsed"
        for ((i=0;i<num_cols;i++)); do
            row_args+=( "${fields[i]:-}" )
        done
    done <<< "$raw_lines"
fi


if (( ${#row_args[@]} == 0 )); then
    zenity --info --title="No Return" --text="No rows returned from the query."
    exit 0
fi

rem=$(( ${#row_args[@]} % num_cols ))
if (( rem != 0 )); then
    pad=$(( num_cols - rem ))
    for ((i=0;i<pad;i++)); do
        row_args+=( "" )
    done
fi


zenity --list --title="Query Results" "${columns_args[@]}" "${row_args[@]}" --width=500 --height=500

#--------------- end ----------------

echo "Columns: ${#columns[@]}"
echo "Row args: ${#row_args[@]}"
echo "Should be divisible? $(( ${#row_args[@]} % ${#columns[@]} ))"


    echo "Running command on table: $table_name"
    echo "User command: $user_cmd"
