#!/bin/sh

# Usage: ./gifenc.sh -i input.mov -o output.gif -w 720 -f 15 -s 1
# -i - input file (gif, avi, mov, mp4 ...)
# -o - output gif file
# -w - witdh in pixels, will be clamped in case if new width > video width
# -f - desired framerate (will be clamped if input file fps is lower)
# -s - desired gif file size limit in megabytes (1 = 1 MB)
#      if gif will be larger than size limit another compression attempt will be
#      performed

start=`date +%s`

while getopts i:o:w:f:s: option
do
case "${option}"
in
i) INPUT_FILE=${OPTARG};;
o) OUTPUT_GIF=${OPTARG};;
w) TARGET_WIDTH=${OPTARG};;
f) TARGET_FPS=${OPTARG};;
s) TARGET_SIZE=${OPTARG};;
esac
done

cd $(dirname $0)

# Megabytes to bytes
if (( $(echo "$TARGET_SIZE " | awk '{print ($1 <= 0)}') )) 
	then 
		TARGET_SIZE=1
fi
LIMIT_OUTPUT_SIZE_BYTES=$(($TARGET_SIZE*1024*1024))
echo $LIMIT_OUTPUT_SIZE_BYTES

INPUT_FPS=`ffmpeg -i $INPUT_FILE 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p"`
INPUT_RES=`ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 $INPUT_FILE`

# stupid checks
INPUT_WIDTH=(${INPUT_RES//x/ })
if [ $TARGET_WIDTH -le 0 ] 
	then
		TARGET_WIDTH=$INPUT_WIDTH
fi

INPUT_SIZE_BYTES=`stat --printf="%s" $INPUT_FILE`
INPUT_SIZE_PRETTY=`numfmt --to=iec-i --suffix=B --format="%.2f" $INPUT_SIZE_BYTES`

echo ""
echo " >>> Processing '$INPUT_FILE' ($INPUT_RES, $INPUT_SIZE_PRETTY, $INPUT_FPS FPS)..."
if (( $(echo "$INPUT_FPS $TARGET_FPS" | awk '{print ($1 < $2)}') )) || [ $TARGET_FPS -le 0 ];
	then
		echo " 	WARNING: Clamping GIF FPS to $INPUT_FPS..."
		TARGET_FPS=$INPUT_FPS
fi

FILTERS="fps=$TARGET_FPS,scale='min($TARGET_WIDTH,iw)':-1:flags=lanczos"
ffmpeg -v error -i $INPUT_FILE -vf "$FILTERS,palettegen" -y ./palette.png
ffmpeg -v error -i $INPUT_FILE -i ./palette.png -lavfi "$FILTERS,paletteuse=dither=sierra2:diff_mode=rectangle" -y $OUTPUT_GIF

OUTPUT_GIF_SIZE=`stat --printf="%s" $OUTPUT_GIF`
OUTPUT_GIF_SIZE_PRETTY=`numfmt --to=iec-i --suffix=B --format="%.2f" $OUTPUT_GIF_SIZE`

if [ $OUTPUT_GIF_SIZE -ge $LIMIT_OUTPUT_SIZE_BYTES ]
	then
		echo " > WARNING: GIF is too big: $OUTPUT_GIF_SIZE_PRETTY"
		echo " > STEP 2: Uber Optimizations in progress..."

		optimized_name=$(basename $OUTPUT_GIF .gif)
		optimized_name+="_optimized.gif"
		cmd //c "gifsicle.exe -i $OUTPUT_GIF -O3 --color-method=blend-diversity --colors 226 --lossy=35 -o $optimized_name"
		
		OUTPUT_GIF_SIZE=`stat --printf="%s" $optimized_name`
		OUTPUT_GIF_SIZE_PRETTY=`numfmt --to=iec-i --suffix=B --format="%.2f" $OUTPUT_GIF_SIZE`
		
		if [ $OUTPUT_GIF_SIZE -ge $LIMIT_OUTPUT_SIZE_BYTES ]
			then
			echo " > ERROR: File is still too big: $OUTPUT_GIF_SIZE_PRETTY"
		fi
fi

OUTPUT_RES=`ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 $OUTPUT_GIF`

echo ""
echo " >>> Optimized: '$OUTPUT_GIF' ($OUTPUT_RES, $OUTPUT_GIF_SIZE_PRETTY, $TARGET_FPS FPS)."
echo "	Compression factor: $((INPUT_SIZE_BYTES / OUTPUT_GIF_SIZE))x"
echo "========================================================"

end=`date +%s`
runtime=$((end-start))

echo "Overall time spent: $((runtime))s"
