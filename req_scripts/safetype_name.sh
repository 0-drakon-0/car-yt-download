#/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <directory_to_process> <destination_directory>"
    exit 1
fi

TARGET_DIR="$1"
DESTINATION_DIR="$2"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Dirrectory not found!"
    eixt 1

fi


find "$TARGET_DIR" -type f -name "*.mp3" -print0 | while IFS= read -r -d '' f; do

    filename=$(basename "$f")
    safename=$(echo "$filename" | sed 's/[^a-zA-Z0-9._]/_/g')
    
    ffmpeg -i "$f" -map_metadata -1 -c:a libmp3lame -ar 44100 -b:a 192k -y "$DESTINATION_DIR/$safename" < /dev/null

done

echo "All files have been processed."

exit 0
