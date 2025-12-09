# OpenIM Server 本地开发快速开始

## 场景

你已经：
1. ✅ 拉取了 openim-server 源码到本地
2. ✅ 修改了代码，新增了接口
3. ✅ 想要使用 Docker 部署你的自定义版本

## 最简单的方法（3 步完成）

### 步骤 1：构建你的镜像

```bash
# 进入 openim-server 源码目录
cd /path/to/your/openim-server

# 构建 Docker 镜像
docker build -t openim/openim-server:my-version .
```

### 步骤 2：修改配置

```bash
# 进入 openim-docker 目录
cd /path/to/openim-docker

# 编辑 .env 文件
vim .env

# 找到这一行：
# OPENIM_SERVER_IMAGE=openim/openim-server:v3.8.3-patch.9

# 改为：
# OPENIM_SERVER_IMAGE=openim/openim-server:my-version
```

### 步骤 3：部署

```bash
# 重启 openim-server 服务
docker compose up -d --force-recreate openim-server

# 查看日志确认启动成功
docker logs -f openim-server
```

## 使用自动化脚本（推荐）

我们提供了一个自动化脚本来简化整个流程：

```bash
cd openim-docker
./build-local.sh /path/to/your/openim-server my-version
```

脚本会自动完成：
- ✅ 构建 Docker 镜像
- ✅ 更新 .env 配置
- ✅ 备份原配置
- ✅ 询问是否重启服务
- ✅ 显示部署状态

## 验证部署

### 1. 检查服务状态

```bash
docker compose ps | grep openim-server
```

应该显示：
```
openim-server   Up X minutes (healthy)   0.0.0.0:10001-10002->10001-10002/tcp
```

### 2. 测试你的新接口

```bash
# 测试新增的接口
curl http://localhost:10002/your-new-endpoint

# 查看 API 健康状态
curl http://localhost:10002/healthz
```

### 3. 查看日志

```bash
# 实时查看日志
docker logs -f openim-server

# 查看最近 100 行日志
docker logs openim-server --tail 100
```

## 开发迭代流程

当你继续修改代码时：

```bash
# 1. 修改代码
vim /path/to/openim-server/your-file.go

# 2. 重新构建
cd /path/to/openim-server
docker build -t openim/openim-server:my-version .

# 3. 重新部署
cd /path/to/openim-docker
docker compose up -d --force-recreate openim-server

# 4. 查看日志
docker logs -f openim-server
```

或者使用脚本一键完成：

```bash
cd openim-docker
./build-local.sh /path/to/openim-server my-version
```

## 常见问题

### Q1: 修改代码后重启容器，但更改没有生效？

**A:** 确保重新构建了镜像：

```bash
# 必须重新构建镜像
docker build -t openim/openim-server:my-version /path/to/openim-server

# 然后强制重新创建容器
docker compose up -d --force-recreate openim-server
```

### Q2: 如何回滚到官方版本？

**A:** 修改 .env 文件：

```bash
# 如果使用了脚本，可以恢复备份
cp .env.backup .env

# 或者手动修改 .env
# OPENIM_SERVER_IMAGE=openim/openim-server:v3.8.3-patch.9

# 重启服务
docker compose up -d openim-server
```

### Q3: 如何查看我当前使用的是哪个镜像？

**A:** 

```bash
# 方法 1：查看 .env 配置
grep OPENIM_SERVER_IMAGE .env

# 方法 2：查看运行中的容器
docker inspect openim-server | grep Image

# 方法 3：查看 compose 配置
docker compose config | grep image
```

### Q4: 构建镜像很慢怎么办？

**A:** 使用 BuildKit 加速：

```bash
DOCKER_BUILDKIT=1 docker build -t openim/openim-server:my-version .
```

### Q5: 如何同时使用本地的 openim-chat？

**A:** 同样的方法：

```bash
# 构建 chat 镜像
cd /path/to/openim-chat
docker build -t openim/openim-chat:my-version .

# 修改 .env
# OPENIM_CHAT_IMAGE=openim/openim-chat:my-version

# 重启服务
docker compose up -d --force-recreate openim-chat
```

## 版本管理建议

使用有意义的标签：

```bash
# 功能开发
docker build -t openim/openim-server:dev-new-api .

# 日期版本
docker build -t openim/openim-server:dev-$(date +%Y%m%d) .

# 测试版本
docker build -t openim/openim-server:test-v1.0.0 .
```

## 下一步

- 📖 详细文档：[LOCAL_BUILD_GUIDE.md](./LOCAL_BUILD_GUIDE.md)
- 🔧 配置示例：[.env.example.local](./.env.example.local)
- 📝 完整 README：[LOCAL_BUILD_README.md](./LOCAL_BUILD_README.md)

## 需要帮助？

- 查看日志：`docker logs openim-server`
- 进入容器：`docker exec -it openim-server sh`
- 检查健康：`docker exec openim-server mage check`
- 查看配置：`docker compose config`
