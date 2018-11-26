#!/bin/sh

directory="$1"

for file in `find "$directory" -name "*.png" -type f`; do
    echo "Discarding changes in ${file}"
    git checkout -- "$file"
done
