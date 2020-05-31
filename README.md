# gif_converter
Optimize GIF Size with ffmpeg &amp; gifsicle. FFmpeg should be in `%PATH%`.

Requirements: git bash + ffmpeg + Windows.

Usage: `./gifenc.sh -i input.mov -o output.gif -w 720 -f 15 -s 1`
- `-i` - input file (gif, avi, mov, mp4 ...)
- `-o` - output gif file
- `-w` - witdh in pixels, will be clamped in case if `new width > input width`
- `-h` - height in pixels, will be clamped in case if `new height > input height`
- `-f` - desired framerate (will be clamped if `input file fps is lower`)
- `-s` - desired gif file size limit in megabytes (1 = 1 MB)
         if gif will be larger than size limit another compression attempt will be
         performed

Thx to Gifsicle: https://github.com/kohler/gifsicle

Usage examples:
- `./gifenc.sh -i 1.avi -o output.gif -w 720 -f 15 -s 10` - converts `1.avi` to `output.gif` (sets width to 720p, framerate to 15 fps and size target to 10 MB)
