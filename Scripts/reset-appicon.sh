#!/bin/sh

function reset_image() {
    local file="$1"

    echo "Reseting ${file}"
}


counter=0
while [ $counter -lt ${SCRIPT_INPUT_FILE_COUNT} ]; do
    tmp="SCRIPT_INPUT_FILE_$counter"
    file=${!tmp}

    reset_image $file

    let counter=counter+1
done
