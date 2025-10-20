#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <source_directory> <destination_directory> <number_of_files>"
    exit 1
fi

SOURCE_DIR="$1"
DESTINATION_DIR="$2"
NUMBER_OF_FILES="$3"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

if [ ! -d "$DESTINATION_DIR" ]; then
    echo "Destination directory does not exist: $DESTINATION_DIR"
    exit 1
fi

i=0

while IFS= read -r -d '' file && [ "$NUMBER_OF_FILES" -gt 0 ]; do
    echo "Moving file $file"

    mv "$file" "$DESTINATION_DIR"
    ((NUMBER_OF_FILES--))
done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -print0)




