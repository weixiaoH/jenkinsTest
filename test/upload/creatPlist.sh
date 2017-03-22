#!/bin/sh
#  Copyright (c) 2017 huangwx Ctrip.com. All rights reserved.

cd "${WORKSPACE}/build"

echo "creat" > jenkinsUserGlobal.properties

ipaName='vbk_'${VERSION}'_'${BUILD_ID}'_Prd_Sit.ipa'
ipaUrl ='http://on76eeinn.bkt.clouddn.com/'ipaName
cat << EOF > ${WORKSPACE}/build/${BUILD_NUMBER}/$ipaName.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>items</key>
        <array>
                <dict>
                        <key>assets</key>
                        <array>
                                <dict>
                                        <key>kind</key>
                                        <string>software-package</string>
                                        <key>url</key>
                                        <string>${ipaName}</string>
                                </dict>
                        </array>
                        <key>metadata</key>
                        <dict>
                                <key>bundle-identifier</key>
                                <string>com.ctrip.vbooking</string>
                                <key>bundle-version</key>
                                <string>1</string>
                                <key>kind</key>
                                <string>software</string>
                                <key>title</key>
                                <string>test</string>
                        </dict>
                </dict>
        </array>
</dict>
</plist>
EOF
