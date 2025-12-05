#!/usr/bin/bash
databases=$(ls myDB)
zenity --list \
    --title="Databases" \
    --column="Database Name" \
    $databases \
    --height=800 --width=600
