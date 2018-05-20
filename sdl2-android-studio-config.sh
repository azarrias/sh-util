#!/bin/bash

# Setup script for SDL2 projects on Android Studio
# Prerequisites: Android Studio 3.1.2 must be installed

V_SDL_URL="https://www.libsdl.org/release"
V_SDL_IMAGE_URL="https://www.libsdl.org/projects/SDL_image/release"
V_SDL_VERSION="SDL2-2.0.5"
V_SDL_IMAGE_VERSION="SDL2_image-2.0.2"
V_PATH_3RD_PARTY="$HOME/3rdparty"
V_PATH_WD=`pwd`
V_PROJECT_PATH="$HOME/dev/lazy-foo/lesson-53"

function download_lib {
   if [[ "$#" -ne 3 ]]; then
      echo "Error: library URL, name and extension must be specified!"
      exit 1
   fi
   
   if [[ -d "$V_PATH_3RD_PARTY"/"$1" ]]; then
      echo "$1 is locally available"
   else
      echo "$1 not locally available"
      echo "Downloading..."
      cd "$V_PATH_3RD_PARTY"
      wget "$2"/"$1""$3"
      tar -xvzf "$1""$3"
      rm "$1""$3"
   fi   
}

if [[ ! -d "$V_PATH_3RD_PARTY" ]]; then
   echo "3rd party source code directory does not exist, creating $V_PATH_3RD_PARTY"
   mkdir -p $V_PATH_3RD_PARTY
fi
download_lib "$V_SDL_VERSION" "$V_SDL_URL" ".tar.gz"
download_lib "$V_SDL_IMAGE_VERSION" "$V_SDL_IMAGE_URL" ".tar.gz"
cd "$V_PATH_3RD_PARTY"/"$V_SDL_VERSION"
cp -rf android-project $HOME/Desktop
echo "From Android Studio, manually:"
echo "Select Import project (Gradle, Eclipse ADT, etc.)"
echo "Set path to $HOME/Desktop/android-project and click [OK]"
echo "Set Import Destination Directory to $V_PROJECT_PATH, click [Next], check every option, then [Finish]" 
echo "Finally, close Android Studio for the setup process to continue"
android-studio
if [[ -z $(grep -q "google()" "$V_PROJECT_PATH/build.gradle") ]]; then
   if [[ -z $(grep -q "jcenter()" "$V_PROJECT_PATH/build.gradle") ]]; then
      sed -i 's/.*repositories.*/&\n        jcenter()/' "$V_PROJECT_PATH/build.gradle"
   fi
   sed -i 's/.*jcenter().*/&\n        google()/' "$V_PROJECT_PATH/build.gradle" 
fi

if [[ -z $(grep -q "sourceSets" "$V_PROJECT_PATH/app/build.gradle") ]]; then
   sed -i 's/.*buildToolsVersion.*/&\n\n    sourceSets {\n       main{\n          jni.srcDirs = []\n       }\n    }/' "$V_PROJECT_PATH/app/build.gradle"
fi

sed -i 's/compileSdkVersion 12/compileSdkVersion 17/g' "$V_PROJECT_PATH/app/build.gradle"
sed -i 's/targetSdkVersion 12/targetSdkVersion 17/g' "$V_PROJECT_PATH/app/build.gradle"

cd "$V_PROJECT_PATH/app/src/main/jni"
ln -s "$V_PATH_3RD_PARTY"/"$V_SDL_VERSION" SDL2

cd "$V_PROJECT_PATH/app/src/main/jni/src"
sed -i 's|SDL_PATH := ../SDL$|SDL_PATH := ../SDL2|g' Android.mk
sed -i 's/YourSourceHere.c/Main.cpp/g' Android.mk

cd "$V_PATH_WD"
