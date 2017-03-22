#!/usr/bin/python
import commands
import ast
import sys
import os

from sevencow import Cow # Cow 地址https://github.com/yueyoum/seven-cow

homePath    =  sys.argv[1]
buildNumber =  sys.argv[2]
version     =  sys.argv[3]
buildId     =  sys.argv[4]

ipaPath  =  homePath + '/build/' + buildNumber + '/vbk_'+version+'_' + buildId + '_Prd_Sit.ipa'
ipaName  =  'vbk_'+version+'_' + buildId + '_Prd_Sit.ipa'

line = 'curl -s -F file=@'+ ipaPath +' -F "uKey=a7db243419b78955c82d1b873c74e17c" -F "_api_key=b10428e23005eb6928df62ff740d913d" https://qiniu-storage.pgyer.com/apiv1/app/upload'
print line
(status, output) = commands.getstatusoutput(line)

value = ast.literal_eval(output)
print value
appkey =value['data']['appKey']

appUrl ='https://www.pgyer.com/' + appkey


envVar =homePath + '/build'
print envVar
os.chdir(envVar)

f = open('jenkinsUserGlobal.properties', 'w')

f.write('APPLINK_URL='+appUrl)
f.close()
print appUrl


#需要填写你的 Access Key 和 Secret Key 和 bucket name
access_key  = 'eJtU68kdhckgNTZOIgzV1zNugwOh_YpTsfTp5vxg'
secret_key  = 'J-iN3H7f6EChgLETrhvs4AMxavJk5HF_4mLFs4Ar'
bucket_name = 'vbkpackage'

#构建鉴权对象
cow = Cow(access_key, secret_key)
b   = cow.get_bucket(bucket_name)


# Bucket.put(filename, data=None, keep_name=False, override=True)
# filename:  文件名。 或者是从磁盘文件上传，就是文件路径
# data:      如果从buffer中上传数据，就需要此参数。表示文件内容。
# keep_name: 上传后的文件是否保持和filename一样。默认为False，用文件内容的MD5值
# override:  上传同名文件，是否强制覆盖
#try:
c =b.put(ipaPath, keep_name=True)   # 上传本地文件a，并且用a作为上传后的名字
d =b.move(ipaPath, ipaName)                      # 将'a' 改名为'b'
#except CowException as e:
#    print e.url         # 出错的url
#    print e.status_code # 返回码
#    print e.content     # api 错误的原因

print c
