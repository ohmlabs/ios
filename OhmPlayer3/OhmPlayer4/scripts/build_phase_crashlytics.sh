#!/bin/sh

UploadCrashlyticsData () {

echo RUNNING CRASHLYTICS SCRIPT

../Third\ Party/Crashlytics/Crashlytics.framework/run 7ca949e35438fc0d1e7a9c0cd2c2adfb5b7ce6df

}

if [ "$CONFIGURATION" != "Debug" ]
then

UploadCrashlyticsData

elif [ "$CONFIGURATION" == "Debug" ]
then

UploadCrashlyticsData
#echo WARNING: DID NOT RUN CRASHLYTICS FOR CONFIGURATION $CONFIGURATION

fi
