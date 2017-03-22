#!/usr/bin/python
import commands
import ast
import sys
import os

homePath    =  sys.argv[1]
buildNumber =  sys.argv[2]
version     =  sys.argv[3]
buildId     =  sys.argv[4]

ipaPath  =  homePath + '/build/' + buildNumber + '/vbk_'+version+'_' + buildId + '_Prd_Sit.ipa'

line = 'curl -s -F file=@'+ ipaPath +' -F "uKey=a7db243419b78955c82d1b873c74e17c" -F "_api_key=b10428e23005eb6928df62ff740d913d" https://qiniu-storage.pgyer.com/apiv1/app/upload'
print 'line='+ line
(status, output) = commands.getstatusoutput(line)

value = ast.literal_eval(output)
print 'value =' + value
appkey =value['data']['appKey']

appUrl ='https://www.pgyer.com/' + appkey


envVar =homePath + '/build'
print 'envVar=' + envVar
os.chdir(envVar)

f = open('jenkinsUserGlobal.properties', 'w')

f.write('APPLINK_URL='+appUrl)

print appUrl
