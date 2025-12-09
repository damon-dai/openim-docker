# 使用本地源码部署 OpenIM Server

## 快速开始

### 方法 1：使用自动化脚本（推荐）

```bash
# 1. 确保你有 openim-server 源码
cd /path/to/your/workspace
git clone https://github.com/openim-sigs/openim-server.git

# 2. 在 openim-docker 目录运行构建脚本
cd openim-docker
./build-local.sh ../openim-server local-dev

# 脚本会自动：
# - 构建 Docker 镜像
# - 更新 .env 配置
# - 询问是否重启服务
```

### 方法 2：手动构建

```bash
# 1. 构建镜像
cd /path/to/openim-server
docker build -t openim/openim-server:local-dev .

# 2. 修改配置
cd /path/to/openim-docker
# 编辑 .env 文件，修改这一行：
# OPENIM_SERVER_IMAGE=openim/openim-server:local-dev

# 3. 重启服务
docker compose up -d --force-recreate openim-server
```

## 开发工作流

### 1. 修改代码

在 openim-server 源码中修改代码，新增接口等。

### 2. 本地测试（可选）

```bash
cd openim-server
go mod tidy
go run ./cmd/openim-server
```

### 3. 构建并部署

```bash
cd openim-docker
./build-local.sh ../openim-server dev-$(date +%Y%m%d)
```

### 4. 验证部署

```bash
# 查看服务状态
docker compose ps | grep openim-server

# 查看日志
docker logs -f openim-server

# 测试新接口
curl http://localhost:10002/your-new-endpoint
```

## 常用命令

```bash
# 查看当前使用的镜像
docker compose config | grep openim-server -A 5

# 查看所有本地构建的镜像
docker images | grep openim-server

# 重启服务
docker compose restart openim-server

# 强制重新创建容器
docker compose up -d --force-recreate openim-server

# 查看实时日志
docker logs -f openim-server

# 进入容器调试
docker exec -it openim-server sh

# 清理未使用的镜像
docker image prune -a
```

## 版本管理建议

使用有意义的标签来管理不同版本：

```bash
# 功能开发版本
./build-local.sh ../openim-server dev-new-api

# 测试版本
./build-local.sh ../openim-server test-v1.0.0

# 修复版本
./build-local.sh ../openim-server fix-bug-123
```

## 回滚到官方版本

```bash
# 方法 1：使用备份的配置
cp .env.backup .env
docker compose up -d openim-server

# 方法 2：手动修改 .env
# 将 OPENIM_SERVER_IMAGE 改回官方版本
# OPENIM_SERVER_IMAGE=openim/openim-server:v3.8.3-patch.9
docker compose up -d openim-server
```

## 故障排查

### 构建失败

```bash
# 清理 Go 缓存
cd openim-server
go clean -cache -modcache -i -r

# 重新下载依赖
go mod download
go mod tidy

# 重新构建
docker build --no-cache -t openim/openim-server:local-dev .
```

### 容器启动失败

```bash
# 查看详细日志
docker logs openim-server

# 检查健康检查
docker inspect openim-server | grep -A 10 Health

# 手动运行健康检查
docker exec openim-server mage check
```

### 代码修改未生效

确保：
1. 重新构建了镜像
2. 使用了 `--force-recreate` 参数
3. 镜像标签正确

```bash
# 完整的更新流程
docker build -t openim/openim-server:local-dev /path/to/openim-server
docker compose up -d --force-recreate openim-server
docker logs -f openim-server
```

## 性能优化

### 使用构建缓存

```bash
# 使用 BuildKit 加速构建
DOCKER_BUILDKIT=1 docker build -t openim/openim-server:local-dev .
```

### 多阶段构建

确保 Dockerfile 使用多阶段构建来减小镜像大小。

## 更多信息

详细文档请参考：[LOCAL_BUILD_GUIDE.md](./LOCAL_BUILD_GUIDE.md)
