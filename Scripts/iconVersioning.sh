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
build_num=`git log --oneline | wc -l`

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
caption="${version} ($build_num) ${branch} ${commit}"
echo $caption
function processIcon() {
    base_file=$1
    base_path=`find "${SRCROOT}/IconOverlaying" -name $base_file`
    
    echo "Processing $base_path"
    
    if [[ ! -f ${base_path} || -z ${base_path} ]]; then
    return;
    fi
    
    target_file=$base_file
    target_path="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/${target_file}"
    
    if [ $CONFIGURATION = "Release" ]; then
    cp "${base_path}" "$target_path"
    return
    fi
    
    width=`identify -format %w ${base_path}`
    height=`identify -format %h ${base_path}`
    band_height=$((($height * 45) / 100))
    band_position=$(($height - $band_height))
    text_position=$(($band_position - 5))
    point_size=$(((15 * $width) / 100))
    
    echo "Image dimensions ($width x $height) - band height $band_height @ $band_position - point size $point_size"

    #
    # blur band and text
    #
    convert $base_path -blur 10x8 /tmp/blurred.png
    convert /tmp/blurred.png -gamma 0 -fill white -draw "rectangle 0,$band_position,$width,$height" /tmp/mask.png
    convert -size ${width}x${band_height} xc:none -fill 'rgba(0,0,0,0.2)' -draw "rectangle 0,0,$width,$band_height" /tmp/labels-base.png
    convert -background none -size ${width}x${band_height} -fill white -gravity center -gravity South caption:"$caption" /tmp/labels.png
    
    convert $base_path /tmp/blurred.png /tmp/mask.png -composite /tmp/temp.png
    
    rm /tmp/blurred.png
    rm /tmp/mask.png
    
    #
    # compose final image
    #
    filename=New$base_file
    convert /tmp/temp.png /tmp/labels-base.png -geometry +0+$band_position -composite /tmp/labels.png -geometry +0+$text_position -geometry +${w}-${h} -composite $target_path
    
    # clean up
    rm /tmp/temp.png
    rm /tmp/labels-base.png
    rm /tmp/labels.png
    
    echo "Overlayed ${target_path}"
}

icon_count=`/usr/libexec/PlistBuddy -c "Print CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles" "${INFOPLIST_FILE}" | wc -l`
last_icon_index=$((${icon_count} - 2))

i=0
while [  $i -lt $last_icon_index ]; do
    icon=`/usr/libexec/PlistBuddy -c "Print CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:$i" "${INFOPLIST_FILE}"`
    processIcon $icon
    let i=i+1
done