# OpenIM Docker Compose 健康检查失败问题诊断

## 问题现象

使用 docker compose 部署 OpenIM 后，`openim-server` 和 `openim-chat` 容器状态显示为 `unhealthy`。

## 根本原因

通过日志分析发现了两个关键问题：

### 1. Kafka 认证配置不匹配

**问题详情：**
- `.env` 文件中配置了 Kafka 认证信息：
  ```
  KAFKA_USERNAME=admin
  KAFKA_PASSWORD=123456
  ```
- `openim-server` 尝试使用这些凭据连接 Kafka（端口 9094）
- 但 `docker-compose.yaml` 中 Kafka 服务的认证配置被注释掉了：
  ```yaml
  # Authentication configuration variables - comment out to disable auth
  # KAFKA_USERNAME: "openIM"
  # KAFKA_PASSWORD: "openIM123"
  ```

**错误日志：**
```
Kafka check failed: Error: kafka: client has run out of available brokers to talk to
NewClient failed, config: =&{Username:admin Password:123456 ...}
```

### 2. OpenIM-Chat 依赖 OpenIM-Server

`openim-chat` 无法连接到 `openim-server` 的 API（端口 10002），因为 `openim-server` 本身由于 Kafka 连接问题而未能正常启动。

**错误日志：**
```
OpenIM check failed: Post "http://127.0.0.1:10002/auth/get_admin_token": 
dial tcp 127.0.0.1:10002: connect: connection refused
```

## 解决方案

### 方案 1：禁用 Kafka 认证（推荐用于开发环境）

修改 `.env` 文件，注释掉或删除 Kafka 认证配置：

```bash
# Kafka 认证配置 - 注释掉以禁用认证
# KAFKA_USERNAME=admin
# KAFKA_PASSWORD=123456
```

### 方案 2：启用 Kafka 认证（推荐用于生产环境）

修改 `docker-compose.yaml` 中的 Kafka 服务配置，取消注释认证相关的环境变量：

```yaml
kafka:
  image: "${KAFKA_IMAGE}"
  container_name: kafka
  environment:
    # ... 其他配置 ...
    
    # 启用认证配置
    KAFKA_USERNAME: "admin"
    KAFKA_PASSWORD: "123456"
```

**注意：** 如果启用认证，需要确保 `.env` 中的用户名和密码与 docker-compose.yaml 中的配置一致。

### 方案 3：同时禁用 Etcd 认证（可选）

如果你也遇到 Etcd 连接问题，可以同样注释掉 `.env` 中的 Etcd 认证配置：

```bash
# Etcd 认证配置 - 注释掉以禁用认证
# ETCD_USERNAME=root
# ETCD_PASSWORD=123456
```

## 修复步骤

1. 停止所有容器：
   ```bash
   docker compose down
   ```

2. 选择上述方案之一修改配置文件

3. 重新启动服务：
   ```bash
   docker compose up -d
   ```

4. 检查服务状态：
   ```bash
   docker compose ps
   ```

5. 查看日志确认问题已解决：
   ```bash
   docker logs openim-server --tail 50
   docker logs openim-chat --tail 50
   ```

## 验证健康状态

等待约 1-2 分钟后，所有服务应该显示为 `healthy` 状态：

```bash
docker compose ps
```

预期输出应该显示：
- `openim-server`: Up (healthy)
- `openim-chat`: Up (healthy)

## 额外说明

- 健康检查命令：`mage check`
- 健康检查间隔：5秒
- 健康检查超时：60秒
- 最大重试次数：10次

如果服务在 10 次重试后仍然 unhealthy，容器会继续运行但标记为不健康状态。


## 访问管理后台

修复完成后，你可以通过浏览器访问管理后台：

```
http://your_server_ip:11002
```

- `your_server_ip` 为服务端部署机器的 IP 地址
- 如果是本地部署，使用：`http://127.0.0.1:11002` 或 `http://localhost:11002`
- 默认账号：`chatAdmin`
- 默认密码：`chatAdmin`

其他访问地址：
- Web 前端：`http://your_server_ip:11001`
- Chat API：`http://your_server_ip:10008`
- Admin API：`http://your_server_ip:10009`
- OpenIM API：`http://your_server_ip:10002`


## 启动监控组件

OpenIM 使用的监控告警组件包括：prometheus、alertmanager、grafana、node_exporter。

### 启动监控组件

使用 `docker compose up -d` 默认不会启动监控组件。需要使用以下命令：

```bash
docker compose --profile m up -d
```

### 访问 Grafana

Grafana 已配置为使用桥接网络模式，可以通过以下地址访问：

```
http://127.0.0.1:13000
```

或

```
http://your_server_ip:13000
```

- 默认用户名：`admin`
- 默认密码：`admin`（首次登录会要求修改密码）

### 监控组件端口

- Grafana: `13000`
- Prometheus: `19090`
- Alertmanager: `19093`
- Node Exporter: `19100`

### macOS 注意事项

在 macOS 上使用 Docker Desktop 时，Prometheus 和 Alertmanager 可能会遇到配置文件挂载问题。这是 Docker Desktop for Mac 的已知限制。如果遇到此问题：

1. Grafana 和 Node Exporter 仍然可以正常工作
2. 可以手动启动 Prometheus 和 Alertmanager（如果需要）
3. 或者在 Linux 环境中部署以获得完整的监控功能

### 验证 Grafana 状态

```bash
# 检查 Grafana 健康状态
curl http://localhost:13000/api/health

# 预期输出
{
  "commit": "...",
  "database": "ok",
  "version": "11.0.1"
}
```


## MongoDB 外部连接配置

默认情况下，MongoDB 容器没有暴露端口到主机，只能在 Docker 内部网络访问。如果需要使用 Navicat 等工具从主机连接 MongoDB，需要添加端口映射。

### 连接信息

**使用 root 用户（管理员）：**
- 主机：`127.0.0.1`
- 端口：`27017`
- 认证数据库：`admin`
- 用户名：`root`
- 密码：`openIM123`

**使用 OpenIM 应用用户：**
- 主机：`127.0.0.1`
- 端口：`27017`
- 认证数据库：`openim_v3`
- 用户名：`openIM`
- 密码：`openIM123`
- 数据库：`openim_v3`

### 测试连接

```bash
# 使用 mongosh 测试连接
docker exec mongo mongosh -u root -p openIM123 --authenticationDatabase admin --eval "db.adminCommand('ping')"

# 预期输出
{ ok: 1 }
```

### 注意事项

1. MongoDB 启用了认证，必须提供正确的用户名和密码
2. 认证数据库必须正确设置（root 用户使用 `admin`，应用用户使用 `openim_v3`）
3. 如果连接失败，检查 MongoDB 容器是否正在运行：`docker compose ps | grep mongo`
