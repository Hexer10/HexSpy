#!/bin/bash
set -ev

VERSION=$1
TAG=$2

echo "Download und extract sourcemod"
wget "http://www.sourcemod.net/latest.php?version=$VERSION&os=linux" -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

echo "Give compiler rights for compile"
chmod +x addons/sourcemod/scripting/spcomp

echo "Set plugins version"
for file in addons/sourcemod/scripting/hexspy.sp
do
  sed -i "s/<TAG>/$TAG/g" $file > output.txt
  rm output.txt
done

addons/sourcemod/scripting/compile.sh hexspy.sp

echo "Remove plugins folder if exists"
if [ -d "addons/sourcemod/plugins" ]; then
  rm -r addons/sourcemod/plugins
fi

echo "Create clean plugins folder"
mkdir -p build/addons/sourcemod/scripting
mkdir build/addons/sourcemod/configs
mkdir build/addons/sourcemod/plugins
mkdir build/addons/sourcemod/translations

echo "Move plugins files to their folder"
mv addons/sourcemod/scripting/hexspy.sp build/addons/sourcemod/scripting
mv addons/sourcemod/scripting/compiled/hexspy.smx build/addons/sourcemod/plugins
mv addons/sourcemod/configs/hexspy.ini build/addons/sourcemod/configs/hexspy.ini
mv addons/sourcemod/translations/hexspy.phrases.txt build/addons/sourcemod/translations/hexspy.phrases.txt

echo "Compress the plugin"
mv LICENSE build/
cd build/ && zip -9rq HexSpy.zip addons/ LICENSE && mv HexSpy.zip ../

echo "Build done"