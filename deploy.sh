#!/bin/bash

imageName="zerotier-planet"

# 处理ip信息
ip=$(curl -s cip.cc | grep http | awk -F '/' '{print $4}')

echo "-------------------------------------------"
echo 使用当前公网 IP："$ip"
echo "-------------------------------------------"
echo "{
  \"stableEndpoints\": [
    \"$ip/9993\"
  ]
}
" >./patch/patch.json

# 开始安装程序
echo "清除原有内容"
rm -f /opt/planet

# 安装docker
docker -v
if [ $? -eq  0 ]; then
  echo "检查到Docker已安装!"
else
  echo "安装docker环境..."
  curl -fsSL https://get.docker.com | bash -s docker --mirror aliyun
  echo "安装docker环境...安装完成!"
fi

# 安装docker-compose
# docker-compose -v
# if [ $? -eq  0 ]; then
#   echo "检查到Docker已安装!"
# else
#   echo "安装docker环境..."
#   curl -L https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-`uname -m` > ./docker-compose
#   chmod +x ./docker-compose
#   mv ./docker-compose /usr/local/bin/docker-compose
#   echo "安装docker环境...安装完成!"
# fi


docker stop $imageName
docker rm $imageName
docker rmi $imageName

echo "打包镜像"
docker build --network host -t $imageName .

echo "启动服务"
for i in $(lsof -i:9993 -t); do kill -2 $i; done
docker run -d -p 9993:9993 -p 9993:9993/udp -p 3443:3443 --name $imageName --restart unless-stopped $imageName
docker cp zerotier-planet:/app/bin/planet /opt/planet
