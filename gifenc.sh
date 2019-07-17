#!/bin/sh
#Usage: ./gifenc.sh input.mov output.gif 720 15

start=`date +%s`

cd $(dirname $0)

# ~10 MB LIMIT
LIMIT=10400000

# ffmpeg options
palette="./palette.png"
filters="fps=$4,scale=$3:-1:flags=lanczos"

# bash specific
size_original=`stat --printf="%s" $1`
read_size_original=`numfmt --to=iec-i --suffix=B --format="%.2f" $size_original`
fps=`ffmpeg -i $1 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p"`

echo ""
echo "Processing $1 ($read_size_original, $fps FPS)..."
var=$(awk 'BEGIN{ print "'$4'"<"'$fps'" }')

if [ "$var" -eq 0 ];
	then
		filters="fps=$fps,scale=$3:-1:flags=lanczos"
		echo " > WARNING: Clamping GIF FPS to $fps..."
else
	fps=$4
fi

ffmpeg -v error -i $1 -vf "$filters,palettegen" -y $palette
ffmpeg -v error -i $1 -i $palette -lavfi "$filters,paletteuse=dither=sierra2:diff_mode=rectangle" -y $2

size=`stat --printf="%s" $2`
read_size=`numfmt --to=iec-i --suffix=B --format="%.2f" $size`

if [ $size -ge $LIMIT ]
	then
		echo " > WARNING: GIF is too big: $read_size"
		echo " > STEP 2: Uber Optimizations in progress..."

		optimized_name=$(basename $2 .gif)
		optimized_name+="_optimized.gif"
		cmd //c "gifsicle.exe -i $2 -O3 --color-method=blend-diversity --colors 216 --lossy=35 -o $optimized_name"
		
		size=`stat --printf="%s" $optimized_name`
		read_size=`numfmt --to=iec-i --suffix=B --format="%.2f" $size`
		
		if [ $size -ge $LIMIT ]
			then
			echo " > ERROR: File is still too big: $read_size"
		fi
fi

echo ""
echo "=================================="
echo "GIF size: $read_size"
echo "GIF FPS: $fps"
echo "Overall compression rate: $((size_original / size))x"

end=`date +%s`
runtime=$((end-start))

echo "Overall time spent: $((runtime))s"
echo "=================================="
