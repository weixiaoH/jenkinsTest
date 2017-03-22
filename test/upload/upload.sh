#!/bin/sh
#  Copyright (c) 2017 huangwx Ctrip.com. All rights reserved.

#upload app
#echo "*** Start uload app, this will take a long time, please wait...***"



python curl.py  ${WORKSPACE} ${BUILD_NUMBER} ${VERSION} ${BUILD_ID}

echo ${appkey}
