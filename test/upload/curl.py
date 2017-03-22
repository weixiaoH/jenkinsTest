#!/usr/bin/python
import commands
import ast
import sys
homePath =  sys.argv[1]
version =   sys.argv[2]
buildId  =  sys.argv[3]

ipapath  =  homePath+'/Desktop/jenkins/workspace/TestProject/vbk_'+version+'_' + buildId + '_Prd_Sit.ipa'

line = 'curl -s -F file=@'+ ipapath +' -F "uKey=a7db243419b78955c82d1b873c74e17c" -F "_api_key=b10428e23005eb6928df62ff740d913d" https://qiniu-storage.pgyer.com/apiv1/app/upload'
print line
(status, output) = commands.getstatusoutput(line)

value = ast.literal_eval(output)

appkey =value['data']['appKey']

appUrl ='https://www.pgyer.com/' + appkey


print appUrl
