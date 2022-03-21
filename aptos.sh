#!/usr/bin/env bash
echo "首次使用aptos脚本，进行初始化……"
sudo apt-get update
sudo apt-get install -y jq
sudo apt-get install -y lrzsz
sudo apt-get install -y screen
sudo apt-get install -y net-tools

echo "安装 Docker"
# 安装 Docker
wget -O get-docker.sh https://get.docker.com 
sudo sh get-docker.sh
rm -f get-docker.sh

# 安装 docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 安装 docker-compose

echo "下载 Aptos 节点运行所需文件"
mkdir -p ~/aptos-node && cd ~/aptos-node
wget https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/public_full_node/docker-compose.yaml
wget https://devnet.aptoslabs.com/genesis.blob
wget https://devnet.aptoslabs.com/waypoint.txt

echo "创建静态身份"
docker run --rm aptoslab/tools:devnet sh -c "aptos-operational-tool generate-key --encoding hex --key-type x25519 --key-file /root/private-key.txt && aptos-operational-tool extract-peer-from-file --encoding hex --key-file /root/private-key.txt --output-file /root/peer-info.yaml && cat /root/private-key.txt && cat /root/peer-info.yaml" > key.txt
sed -i '1,14d' key.txt
sed -i '3,4d' key.txt
sed -i '4d' key.txt
sed -i 's/-//g' key.txt
sed -i 's/ //g' key.txt
sed -i 's/://g' key.txt

#修改public_fulll_node.yaml内容
cat key.txt | head -n 1 > privateKey.txt
privateKey=$(cat key.txt | head -n 1)
peerID=$(cat key.txt | tail -n +2 | head -n 1)
cat>public_full_node.yaml<<EOF
base:
    # This is the location Aptos will store its database. It is backed by a dedicated docker volume
    # for persistence.
    data_dir: "/opt/aptos/data"
    role: "full_node"
    waypoint:
        # This is a checkpoint into the blockchain for added security.
        from_file: "/opt/aptos/etc/waypoint.txt"

execution:
    # Path to a genesis transaction. Note, this must be paired with a waypoint. If you update your
    # waypoint without a corresponding genesis, the file location should be an empty path.
    genesis_file_location: "/opt/aptos/etc/genesis.blob"

full_node_networks:
    - network_id: "public"
      discovery_method: "onchain"
      identity:
        type: "from_config"
        key: "${privateKey}"
        peer_id: "${peerID}"
      # The network must have a listen address to specify protocols. This runs it locally to
      # prevent remote, incoming connections.
      listen_address: "/ip4/127.0.0.1/tcp/6180"
      # Define the upstream peers to connect to
      seeds:
        {}

api:
    # This specifies your REST API endpoint. Intentionally on public so that Docker can export it.
    address: 0.0.0.0:8080
EOF

echo "显示public_full_node.yaml文本结果"
cat public_full_node.yaml

echo "开始运行"
docker-compose up -d

echo "读取私钥"
cat key.txt | head -n 1
