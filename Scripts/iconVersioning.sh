export PATH=/opt/local/bin/:/opt/local/sbin:$PATH:/usr/local/bin:

convertPath=`which convert`
echo ${convertPath}
if [[ ! -f ${convertPath} || -z ${convertPath} ]]; then
    echo "WARNING: Skipping Icon versioning, you need to install ImageMagick and ghostscript (fonts) first, you can use brew to simplify process:
    brew install imagemagick
    brew install ghostscript"
    exit 0;
fi

commit=`git rev-parse --short HEAD`
branch=`git rev-parse --abbrev-ref HEAD`
version=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}"`
build_num=`git rev-list HEAD --count`

#SRCROOT=..
#CONFIGURATION_BUILD_DIR=.
#UNLOCALIZED_RESOURCES_FOLDER_PATH=.

#commit="3783bab"
#branch="master"
#version="3.4"
#build_num="9999"

shopt -s extglob
build_num="${build_num##*( )}"
shopt -u extglob
caption="${version} ($build_num)\n${branch}\n${commit}"
echo $caption

function processIcon() {
    base_file=$1

    cd "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
    base_path=`find . -name ${base_file}`

    echo "Processing $base_path"

    if [[ ! -f ${base_path} || -z ${base_path} ]]; then
    return;
    fi

    target_file=$base_path
    target_path="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/${target_file}"

    if [ $CONFIGURATION = "Release" ]; then
    cp "${base_path}" "$target_path"
    return 0;
    fi

    echo "Reverting optimized PNG to normal"
    # form a normalized png filename
    base_tmp_normalizedFileName="${base_file%.*}-normalized.${base_file##*.}"
    base_tmp_path=`dirname $base_path`
    base_tmp_normalizedFilePath="${base_tmp_path}/${base_tmp_normalizedFileName}"
    
    # Normalize
    echo "xcrun -sdk iphoneos pngcrush -revert-iphone-optimizations -q $base_path $base_tmp_normalizedFilePath"
    xcrun -sdk iphoneos pngcrush -revert-iphone-optimizations -q "$base_path" "$base_tmp_normalizedFilePath"

    # Remove pngcrush png
    echo "Removing pngcrushed png file at $base_path"
    rm "$base_path"

    # Rename normalized png's filename to original one
    echo "Moving normalized png file to original one"
    mv "$base_tmp_normalizedFilePath" "$base_path"

    width=`identify -format %w ${base_path}`
    height=`identify -format %h ${base_path}`
    band_height=$((($height * 47) / 100))
    band_position=$(($height - $band_height))
    text_position=$(($band_position - 3))
    point_size=$(((13 * $width) / 100))

    echo "Image dimensions ($width x $height) - band height $band_height @ $band_position - point size $point_size"

    #
    # blur band and text
    #
    convert $base_path -blur 10x8 /tmp/blurred.png
    convert /tmp/blurred.png -gamma 0 -fill white -draw "rectangle 0,$band_position,$width,$height" /tmp/mask.png
    convert -size ${width}x${band_height} xc:none -fill 'rgba(0,0,0,0.2)' -draw "rectangle 0,0,$width,$band_height" /tmp/labels-base.png
    convert -background none -size ${width}x${band_height} -pointsize $point_size -fill white -gravity center -gravity South caption:"$caption" /tmp/labels.png
    
    convert $base_path /tmp/blurred.png /tmp/mask.png -composite /tmp/temp.png

    rm /tmp/blurred.png
    rm /tmp/mask.png

    #
    # compose final image
    #
    filename=New$base_file
    convert /tmp/temp.png /tmp/labels-base.png -geometry +0+$band_position -composite /tmp/labels.png -geometry +0+$text_position -geometry +${w}-${h} -composite "$target_path"

    # clean up
    rm /tmp/temp.png
    rm /tmp/labels-base.png
    rm /tmp/labels.png

    echo "Overlayed ${target_path}"
}

icon_count=`/usr/libexec/PlistBuddy -c "Print CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles" "${CONFIGURATION_BUILD_DIR}/${INFOPLIST_PATH}" | wc -l`
last_icon_index=$((${icon_count} - 2))

i=0
while [  $i -lt $last_icon_index ]; do
    icon=`/usr/libexec/PlistBuddy -c "Print CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:$i" "${CONFIGURATION_BUILD_DIR}/${INFOPLIST_PATH}"`

    if [[ $icon == *.png ]] || [[ $icon == *.PNG ]]
    then
        processIcon $icon
    else
        processIcon "${icon}.png"
        processIcon "${icon}@2x.png"
    fi
    let i=i+1
done

# Workaround to fix issue#16 to use wildcard * to actually find the file
# Only 72x72 and 76x76 that we need for ipad app icons
processIcon "AppIcon72x72~ipad*"
processIcon "AppIcon72x72@2x~ipad*"
processIcon "AppIcon76x76~ipad*"
processIcon "AppIcon76x76@2x~ipad*"