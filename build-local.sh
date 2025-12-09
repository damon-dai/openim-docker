#!/bin/bash

# OpenIM Server 本地构建和部署脚本
# 使用方法: ./build-local.sh /path/to/openim-server [image-tag]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认值
DEFAULT_TAG="local-dev"
OPENIM_SERVER_PATH="${1}"
IMAGE_TAG="${2:-$DEFAULT_TAG}"
IMAGE_NAME="openim/openim-server:${IMAGE_TAG}"

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查参数
if [ -z "$OPENIM_SERVER_PATH" ]; then
    print_error "请提供 openim-server 源码路径"
    echo "使用方法: $0 /path/to/openim-server [image-tag]"
    echo "示例: $0 ../openim-server local-dev"
    exit 1
fi

# 检查路径是否存在
if [ ! -d "$OPENIM_SERVER_PATH" ]; then
    print_error "路径不存在: $OPENIM_SERVER_PATH"
    exit 1
fi

# 检查是否有 Dockerfile
if [ ! -f "$OPENIM_SERVER_PATH/Dockerfile" ]; then
    print_error "在 $OPENIM_SERVER_PATH 中未找到 Dockerfile"
    exit 1
fi

print_info "开始构建 OpenIM Server 镜像..."
print_info "源码路径: $OPENIM_SERVER_PATH"
print_info "镜像名称: $IMAGE_NAME"

# 进入源码目录
cd "$OPENIM_SERVER_PATH"

# 显示当前分支
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
print_info "当前分支: $CURRENT_BRANCH"

# 构建镜像
print_info "正在构建 Docker 镜像..."
docker build -t "$IMAGE_NAME" .

if [ $? -eq 0 ]; then
    print_info "镜像构建成功: $IMAGE_NAME"
else
    print_error "镜像构建失败"
    exit 1
fi

# 返回 openim-docker 目录
cd - > /dev/null

# 更新 .env 文件
print_info "更新 .env 配置..."
if [ -f ".env" ]; then
    # 备份原文件
    cp .env .env.backup
    print_info "已备份 .env 到 .env.backup"
    
    # 更新镜像配置
    if grep -q "^OPENIM_SERVER_IMAGE=" .env; then
        sed -i.tmp "s|^OPENIM_SERVER_IMAGE=.*|OPENIM_SERVER_IMAGE=$IMAGE_NAME|" .env
        rm -f .env.tmp
        print_info "已更新 OPENIM_SERVER_IMAGE=$IMAGE_NAME"
    else
        print_warn ".env 中未找到 OPENIM_SERVER_IMAGE 配置"
    fi
else
    print_error "未找到 .env 文件"
    exit 1
fi

# 询问是否重启服务
read -p "是否立即重启 openim-server 服务? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "正在重启 openim-server 服务..."
    docker compose up -d --force-recreate openim-server
    
    print_info "等待服务启动..."
    sleep 5
    
    # 检查服务状态
    print_info "检查服务状态..."
    docker compose ps | grep openim-server
    
    print_info "查看最近日志..."
    docker logs openim-server --tail 20
    
    print_info "部署完成！"
else
    print_info "跳过重启服务"
    print_warn "请手动运行: docker compose up -d --force-recreate openim-server"
fi

print_info "完成！"
print_info "使用的镜像: $IMAGE_NAME"
print_info "查看日志: docker logs -f openim-server"
print_info "回滚配置: cp .env.backup .env && docker compose up -d openim-server"
