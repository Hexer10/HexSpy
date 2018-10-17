#!/bin/bash
set -ev

TAG=$1

echo $1
echo $2

echo "Download und extract sourcemod"
wget "http://www.sourcemod.net/latest.php?version="$2"&os=linux" -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

echo "Give compiler rights for compile"
chmod +x addons/sourcemod/scripting/spcomp

echo "Set plugins version"
for file in addons/sourcemod/scripting/HexSpy.sp
do
  sed -i "s/<TAG>/$TAG/g" $file > output.txt
  rm output.txt
done

addons/sourcemod/scripting/compile.sh HexSpy.sp

echo "Remove plugins folder if exists"
if [ -d "addons/sourcemod/plugins" ]; then
  rm -r addons/sourcemod/plugins
fi

echo "Create clean plugins folder"
mkdir -p build/addons/sourcemod/scripting
mkdir build/addons/sourcemod/configs
mkdir build/addons/sourcemod/plugins

echo "Move plugins files to their folder"
mv addons/sourcemod/scripting/HexSpy.sp build/addons/sourcemod/scripting
mv addons/sourcemod/scripting/compiled/HexSpy.smx build/addons/sourcemod/plugins
mv addons/sourcemod/configs/hexspy.ini build/addons/sourcemod/configs/hexspy.ini


echo "Compress the plugin"
mv LICENSE build/
cd build/ && zip -9rq HexSpy.zip addons/ LICENSE && mv HexSpy.zip ../

echo "Build done"