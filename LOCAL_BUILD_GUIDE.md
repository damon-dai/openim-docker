# OpenIM Server 本地构建和部署指南

当你修改了 openim-server 源码并新增了接口后，需要构建自己的 Docker 镜像来部署。

## 方案一：使用本地构建的镜像（推荐）

### 1. 准备 openim-server 源码

```bash
# 克隆或确保你已经有 openim-server 源码
cd /path/to/your/workspace
git clone https://github.com/openim-sigs/openim-server.git
cd openim-server

# 或者如果已经克隆，拉取最新代码并切换到你的开发分支
git pull
git checkout your-feature-branch
```

### 2. 构建 Docker 镜像

在 openim-server 源码目录中：

```bash
# 构建镜像（使用自定义标签）
docker build -t openim/openim-server:local-dev .

# 或者指定 Dockerfile 路径
docker build -f Dockerfile -t openim/openim-server:local-dev .
```

### 3. 修改 docker-compose.yaml

在 `openim-docker` 目录中，修改 `.env` 文件：

```bash
# 将这一行：
# OPENIM_SERVER_IMAGE=openim/openim-server:v3.8.3-patch.9

# 改为：
OPENIM_SERVER_IMAGE=openim/openim-server:local-dev
```

### 4. 重启服务

```bash
cd /path/to/openim-docker
docker compose up -d --force-recreate openim-server
```

## 方案二：挂载本地源码（开发调试）

如果你想在不重新构建镜像的情况下测试代码，可以挂载本地源码。

### 1. 修改 docker-compose.yaml

在 `openim-server` 服务中添加 volumes：

```yaml
openim-server:
  image: ${OPENIM_SERVER_IMAGE}
  container_name: openim-server
  init: true
  ports:
    - "${OPENIM_MSG_GATEWAY_PORT}:10001"
    - "${OPENIM_API_PORT}:10002"
  volumes:
    # 挂载你的本地源码目录
    - /path/to/your/openim-server:/openim-server
  # ... 其他配置保持不变
```

### 2. 重启服务

```bash
docker compose up -d --force-recreate openim-server
```

**注意：** 这种方式需要确保容器内的 Go 环境和依赖与你的代码兼容。

## 方案三：使用 docker-compose build

### 1. 创建本地 Dockerfile

在 `openim-docker` 目录创建 `Dockerfile.server`：

```dockerfile
# 使用官方 Go 镜像作为构建环境
FROM golang:1.21-alpine AS builder

WORKDIR /build

# 复制本地源码
COPY /path/to/your/openim-server .

# 构建
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o openim-server ./cmd/openim-server

# 使用轻量级镜像运行
FROM alpine:latest

WORKDIR /app

COPY --from=builder /build/openim-server .
COPY --from=builder /build/config ./config

EXPOSE 10001 10002

CMD ["./openim-server"]
```

### 2. 修改 docker-compose.yaml

```yaml
openim-server:
  build:
    context: /path/to/your/openim-server
    dockerfile: Dockerfile
  container_name: openim-server
  # ... 其他配置
```

### 3. 构建并启动

```bash
docker compose build openim-server
docker compose up -d openim-server
```

## 验证部署

### 1. 检查容器状态

```bash
docker compose ps | grep openim-server
```

应该显示 `healthy` 状态。

### 2. 查看日志

```bash
docker logs openim-server --tail 100
```

### 3. 测试新接口

```bash
# 测试你新增的接口
curl http://localhost:10002/your-new-endpoint

# 或者查看 API 文档
curl http://localhost:10002/swagger/index.html
```

## 常见问题

### 1. 构建失败

**问题：** 构建镜像时出现依赖错误

**解决：**
```bash
# 在源码目录中清理并重新下载依赖
go mod tidy
go mod download
```

### 2. 容器启动失败

**问题：** 容器启动后立即退出

**解决：**
```bash
# 查看详细日志
docker logs openim-server

# 检查配置文件是否正确
docker exec openim-server ls -la /openim-server/config/
```

### 3. 健康检查失败

**问题：** 容器显示 unhealthy

**解决：**
```bash
# 进入容器检查
docker exec -it openim-server sh

# 手动运行健康检查命令
mage check
```

### 4. 代码修改未生效

**问题：** 修改代码后重启容器，但更改未生效

**解决：**
- 确保重新构建了镜像：`docker build -t openim/openim-server:local-dev .`
- 强制重新创建容器：`docker compose up -d --force-recreate openim-server`
- 清理旧镜像：`docker image prune -a`

## 最佳实践

### 开发流程

1. **本地开发**：在本地修改代码并测试
2. **构建镜像**：`docker build -t openim/openim-server:local-dev .`
3. **更新配置**：修改 `.env` 使用新镜像
4. **部署测试**：`docker compose up -d --force-recreate openim-server`
5. **验证功能**：测试新接口和功能
6. **查看日志**：`docker logs -f openim-server`

### 版本管理

建议使用有意义的标签：

```bash
# 开发版本
docker build -t openim/openim-server:dev-feature-name .

# 测试版本
docker build -t openim/openim-server:test-v1.0.0 .

# 生产版本
docker build -t openim/openim-server:prod-v1.0.0 .
```

然后在 `.env` 中相应修改：
```bash
OPENIM_SERVER_IMAGE=openim/openim-server:dev-feature-name
```

## 回滚到官方版本

如果需要回滚到官方版本：

```bash
# 修改 .env
OPENIM_SERVER_IMAGE=openim/openim-server:v3.8.3-patch.9

# 重启服务
docker compose up -d --force-recreate openim-server
```
