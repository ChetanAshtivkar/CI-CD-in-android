#!/bin/sh

mkdir "${ANDROID_HOME}/licenses" || true
echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > "${ANDROID_HOME}/licenses/android-sdk-license"
echo "d56f5187479451eabf01fb78af6dfcb131a6481e" >> "$ANDROID_HOME/licenses/android-sdk-license"
if [ $1 -eq 1 ]
then
     echo "assemble debug"
    ./gradlew clean
    ./gradlew setupKeyStoreProperties
    ./gradlew assembleUatRelease
else
     echo "assemble release"
    ./gradlew clean
    ./gradlew setupKeyStoreProperties
    ./gradlew assembleUatRelease
    ./gradlew publishApkUatRelease
fi