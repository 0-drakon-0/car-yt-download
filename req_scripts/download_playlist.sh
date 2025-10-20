#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Error: not enough arguments!"
    echo "Usage: $0 <playlist_url> <download_folder>"
    exit 1
fi

PLAYLIST_URL="$1"
DOWNLOAD_FOLDER="$2"

yt-dlp --download-archive downloaded.txt -x --audio-format mp3 -o "$DOWNLOAD_FOLDER/%(title)s_[%(id)s].%(ext)s" "$PLAYLIST_URL" 


exit 0
