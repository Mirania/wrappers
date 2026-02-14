A collection of wrapper scripts for CLI utilities. These simplify the common use cases for these tools.

## Requirements

* Install [Git Bash for Windows](https://git-scm.com/downloads)

* Download the required program that you're wrapping (e.g. ffmpeg) and place them in a `bin/` folder. The runner scripts should be placed there as well.

## Wrappers

Application|Purpose
---|---
[ffmpeg](https://ffmpeg.org/)|Fast editing of audio and video files.
[w2x](https://github.com/DeadSix27/waifu2x-converter-cpp)|AI upscaling of image files.
[youtube-dl](https://github.com/yt-dlp/yt-dlp)|Youtube video downloader.
compressor|Wraps [ffmpeg](https://ffmpeg.org/) and [ImageMagick](https://imagemagick.org/) to compress image and video files.