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
sudo rm -f /opt/planet
docker stop $imageName
docker rm $imageName
docker rmi $imageName

echo "打包镜像"
docker build --network host -t $imageName .

echo "启动服务"
for i in $(lsof -i:9993 -t); do kill -2 $i; done
docker run -d -p 9993:9993 -p 9993:9993/udp -p 3443:3443 --name $imageName --restart unless-stopped $imageName
sudo docker cp zerotier-planet:/app/bin/planet /opt/planet
