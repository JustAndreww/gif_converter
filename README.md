# gif_converter
Optimize GIF Size with ffmpeg &amp; gifsicle. FFmpeg should be in `%PATH%`.

Requirements: git bash 

Usage: `./gifenc.sh -i input.mov -o output.gif -w 720 -f 15 -s 1`
- `-i` - input file (gif, avi, mov, mp4 ...)
- `-o` - output gif file
- `-w` - witdh in pixels, will be clamped in case if `new width > input width`
- `-f` - desired framerate (will be clamped if `input file fps is lower`)
- `-s` - desired gif file size limit in megabytes (1 = 1 MB)
         if gif will be larger than size limit another compression attempt will be
         performed

Thx to Gifsicle: https://github.com/kohler/gifsicle
