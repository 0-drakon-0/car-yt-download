#!/bin/bash
yt-dlp -x --audio-format mp3 -o "music_safe/%(title)s.%(ext)s" "$1" 

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
    if (( i % 2 == 0 )); then
        echo "Copying file $file"

        cp "$file" "$DESTINATION_DIR"
        ((NUMBER_OF_FILES--))
    fi
    (( i++ ))
done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -print0)




