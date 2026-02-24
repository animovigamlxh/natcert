#!/bin/bash



# 颜色定义

RED='\033[0;31m'

GREEN='\033[0;32m'

YELLOW='\033[0;33m'

PLAIN='\033[0m'



echo -e "${YELLOW}======================================================${PLAIN}"

echo -e "${YELLOW}       NAT VPS SSL 证书一键申请脚本 (DNS-01 模式)      ${PLAIN}"

echo -e "${YELLOW}          默认适配 Cloudflare DNS API                 ${PLAIN}"

echo -e "${YELLOW}======================================================${PLAIN}"



# 1. 检查是否为 Root 用户

[[ $EUID -ne 0 ]] && echo -e "${RED}错误: 请使用 root 用户运行此脚本！${PLAIN}" && exit 1



# 2. 安装依赖

echo -e "${GREEN}[1/5] 正在安装必要依赖 (curl, socat, openssl)...${PLAIN}"

if [ -f /etc/debian_version ]; then

    apt-get update -y && apt-get install -y curl socat openssl tar cron

elif [ -f /etc/redhat-release ]; then

    yum update -y && yum install -y curl socat openssl tar cronie

fi



# 3. 安装 acme.sh

echo -e "${GREEN}[2/5] 正在安装 acme.sh...${PLAIN}"

curl https://get.acme.sh | sh

source ~/.bashrc

# 设置默认 CA 为 Let's Encrypt (兼容性更好)

~/.acme.sh/acme.sh --set-default-ca --server letsencrypt



# 4. 收集用户输入

echo -e "${YELLOW}------------------------------------------------------${PLAIN}"

echo -e "请准备好 Cloudflare 的 Global API Key。"

echo -e "如果没有，请访问 https://dash.cloudflare.com/profile/api-tokens 获取"

echo -e "${YELLOW}------------------------------------------------------${PLAIN}"



read -p "请输入你的域名 (例如 nat.abc.com): " domain

read -p "请输入 Cloudflare 注册邮箱: " cf_email

read -p "请输入 Cloudflare Global API Key: " cf_key



if [[ -z "$domain" || -z "$cf_email" || -z "$cf_key" ]]; then

    echo -e "${RED}错误: 所有选项都不能为空！${PLAIN}"

    exit 1

fi



# 5. 导出环境变量

export CF_Key="$cf_key"

export CF_Email="$cf_email"



# 6. 申请证书

# 修改第 6 步的申请命令
echo -e "${GREEN}[3/5] 正在尝试更新/申请证书...${PLAIN}"

# 使用 --renew 和 --force 结合
~/.acme.sh/acme.sh --renew -d "$domain" --dns dns_cf --force



if [ $? -ne 0 ]; then

    echo -e "${RED}证书申请失败！请检查 API Key 是否正确，或域名 DNS 是否托管在 Cloudflare。${PLAIN}"

    exit 1

fi



# 7. 安装证书到指定目录

echo -e "${GREEN}[4/5] 正在导出证书...${PLAIN}"

CERT_DIR="/root/cert"

mkdir -p $CERT_DIR



~/.acme.sh/acme.sh --install-cert -d "$domain" \

--key-file       $CERT_DIR/private.key  \

--fullchain-file $CERT_DIR/fullchain.crt



# 8. 完成

echo -e "${YELLOW}======================================================${PLAIN}"

echo -e "${GREEN}恭喜！证书申请成功！${PLAIN}"

echo -e "证书文件已保存在: ${RED}${CERT_DIR}${PLAIN}"

echo -e "公钥 (Fullchain): ${CERT_DIR}/fullchain.crt"

echo -e "私钥 (Private Key): ${CERT_DIR}/private.key"

echo -e "${YELLOW}======================================================${PLAIN}"

echo -e "注意：请妥善保管你的私钥文件。"
