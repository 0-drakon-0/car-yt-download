# Simple YT music playlist downloader script on USB for old cars

This project was build to help creating an usb stick with songs from youtube for older cars whose stereo do not recognize newer partitioning fromats or might have problems with special characters.

**This project was made for LINUX not windows**

### Safety Checks
* Only works on block devices smaller than 16GB.
* Asks for final confirmation before wiping the disk.


### Dependencies
 * yt-dlp -> for downloading yt playlists
 * ffmpeg -> for fixing any .mp3's corruption

#### Arch & derivatives:
```
sudo pacman -S yt-dlp ffmpeg
```

#### Debian, Ubuntu, Mint & derivatives:
```
sudo apt update && sudo apt install yt-dlp ffmpeg
```

#### Fedora, CentOS Stream, Rocky Linux, AlmaLinux:
```
sudo dnf install yt-dlp ffmpeg
```

#### OpenSUSE:
```
sudo zypper install yt-dlp ffmpeg
```

### Usage

#### Step 1)
clone this repo:

```
git clone https://github.com/0-drakon-0/car-yt-download.git
```

#### Step 2)
Run lsblk to know which disk you will format

```
lsblk
```

You will be greeted by something like this:

```
NAME       MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
sda        259:0    0 15.2G  0 disk
├─sda1     259:1    0 15.2G  0 part
```

Choose the disk you think it's the usb you are searching for. Usually it's something small. (don't worry about erasing your system, the program has safety checks put in place for that)

#### Step 3)
run the script like so: (note that it works only on playlists not single videos)

sudo $0 /dev/sdX <youtube_PLAYLIST_link>'

Example:
```
sudo $0 /dev/sdb https://youtube.com/someurl
sudo $0 /dev/sda https://youtube.com/someurl
```

**!!! /dev/sda not /dev/sda1 !!!**

yes, it does require *sudo*, it needs the privilages to format the disk

### Logic

The main script install-music-on-usb.sh will:

* Wipe the USB stick and create a new MBR (DOS) partition table.
* Create one primary partition.
* Set the partition type to 'c' (W95 FAT32 LBA).
* Format the partition as FAT32.
* Create a folder named CD01.
* Use helper script to Download music.
* Use other helper script to safe name it (no emoji's or special chars).
* Lastly, moves only the specified amount of songs to the usb.


