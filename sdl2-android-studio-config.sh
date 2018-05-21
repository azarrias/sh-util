#!/bin/bash

# Setup script for SDL2 projects on Android Studio
# Prerequisites: Android Studio 3.1.2 must be installed

V_SDL_URL="https://www.libsdl.org/release"
V_SDL_IMAGE_URL="https://www.libsdl.org/projects/SDL_image/release"
V_SDL_VERSION="SDL2-2.0.5"
V_SDL_IMAGE_VERSION="SDL2_image-2.0.2"
V_PATH_3RD_PARTY="$HOME/3rdparty"
V_PATH_WD=`pwd`
V_PROJECT_PATH="$HOME/dev/lazy-foo-sdl2/lesson-52"
V_INCLUDE_SDL_IMAGE=false

function download_lib {
   if [[ "$#" -ne 3 ]]; then
      echo "[ERROR] library URL, name and extension must be specified!"
      exit 1
   fi
   
   if [[ -d "$V_PATH_3RD_PARTY"/"$1" ]]; then
      echo "[INFO] $1 is locally available"
   else
      echo "[INFO] $1 not locally available, downloading..."
      cd "$V_PATH_3RD_PARTY"
      wget_output=$(wget -q "$2"/"$1""$3")
      if [ $? -ne 0 ]; then
         echo "[ERROR] wget finished with error"
         echo $wget_output
         exit 1
      fi
      tar_output=$(tar -xzf "$1""$3")
      if [ $? -ne 0 ]; then
         echo "[ERROR] tar finished with error"
         echo $tar_output
         exit 1
      fi
      rm "$1""$3"
   fi   
}

if [[ ! -d "$V_PATH_3RD_PARTY" ]]; then
   echo "[INFO] 3rd party source code directory does not exist, creating $V_PATH_3RD_PARTY"
   mkdir -p $V_PATH_3RD_PARTY
fi

download_lib "$V_SDL_VERSION" "$V_SDL_URL" ".tar.gz"

cd "$V_PATH_3RD_PARTY"/"$V_SDL_VERSION"
cp -rf android-project $HOME/Desktop

echo "[INFO] Starting up Android Studio. Once it is open, manually:"
echo "- Click [Import project (Gradle, Eclipse ADT, etc.)]"
echo "- Set path to $HOME/Desktop/android-project and click [OK]"
echo "- Set Import Destination Directory to $V_PROJECT_PATH, click [Next], check every option, then [Finish]" 
echo "- Finally, close Android Studio for the setup process to continue"
android-studio

if ! $(grep -q "google()" "$V_PROJECT_PATH/build.gradle"); then
   if ! $(grep -q "jcenter()" "$V_PROJECT_PATH/build.gradle"); then
      sed -i 's/.*repositories.*/&\n        jcenter()/' "$V_PROJECT_PATH/build.gradle"
   fi
   sed -i 's/.*jcenter().*/&\n        google()/' "$V_PROJECT_PATH/build.gradle" 
fi

if [[ ! -d "$V_PROJECT_PATH/app/src/main/assets" ]]; then
   mkdir -p "$V_PROJECT_PATH/app/src/main/assets"
fi   

if ! $(grep -q "sourceSets" "$V_PROJECT_PATH/app/build.gradle"); then
   sed -i 's/.*buildToolsVersion.*/&\n\n    sourceSets {\n       main{\n          jni.srcDirs = []\n       }\n    }/' "$V_PROJECT_PATH/app/build.gradle"
fi

if ! $(grep -q "externalNativeBuild" "$V_PROJECT_PATH/app/build.gradle"); then
   mv "$V_PROJECT_PATH/app/build.gradle" "$V_PROJECT_PATH/app/build.gradle.old"
   perl -ne 'BEGIN{$state=0;$brackets=0;$q=chr(39)} print; if ($state==0 && /\s*buildTypes/) {$state=1;} if (/{/ && ($state==1 || $state==2)) { $brackets++; $state=2; } if (/}/ && $state==2) { $brackets--; } if ($state==2 && $brackets == 0) { $state=3; print "    compileOptions {\n        sourceCompatibility JavaVersion.VERSION_1_8\n        targetCompatibility JavaVersion.VERSION_1_8\n    }\n    externalNativeBuild {\n        ndkBuild {\n            path $q$\src/main/jni/Android.mk$q\n        }\n    }\n"}' "$V_PROJECT_PATH/app/build.gradle.old" > "$V_PROJECT_PATH/app/build.gradle"
   rm "$V_PROJECT_PATH/app/build.gradle.old"
fi

sed -i 's/compileSdkVersion 12/compileSdkVersion 17/g' "$V_PROJECT_PATH/app/build.gradle"
sed -i 's/targetSdkVersion 12/targetSdkVersion 17/g' "$V_PROJECT_PATH/app/build.gradle"

cd "$V_PROJECT_PATH/app/src/main/jni"
ln -s "$V_PATH_3RD_PARTY"/"$V_SDL_VERSION" SDL2
sed -i 's/# APP_STL := stlport_static/APP_STL := c++_static/g' Application.mk

cd "$V_PROJECT_PATH/app/src/main/jni/src"
sed -i 's|SDL_PATH := ../SDL$|SDL_PATH := ../SDL2|g' Android.mk
sed -i 's/YourSourceHere.c/Main.cpp/g' Android.mk

cat << EOF > "$V_PROJECT_PATH/app/src/main/jni/src/Main.cpp"
#include <SDL.h>

int main( int argc, char* args[] )
{
   //Initialize SDL
   if(SDL_Init(SDL_INIT_VIDEO ) < 0)
   {
      SDL_Log("SDL could not initialize! SDL Error: %s\n", SDL_GetError());
   }

   return 0;
}
EOF

if [[ "$V_INCLUDE_SDL_IMAGE" = true ]]; then
   download_lib "$V_SDL_IMAGE_VERSION" "$V_SDL_IMAGE_URL" ".tar.gz"
fi 

cd "$V_PATH_WD"

echo "[INFO] SDL project successfully set up for Android Studio!"
echo "[INFO] Make sure to sync Project with Gradle Files from Android Studio File menu"

