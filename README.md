# OpenIM Docker Usage Instructions 📘

> **Documentation Resources** 📚

+ [Official Deployment Guide](https://docs.openim.io/guides/gettingstarted/dockercompose)

## :busts_in_silhouette: Community

+ 💬 [Follow us on Twitter](https://twitter.com/founder_im63606)
+ 🚀 [Join our Slack channel](https://join.slack.com/t/openimsdk/shared_invite/zt-22720d66b-o_FvKxMTGXtcnnnHiMqe9Q)
+ :eyes: [Join our WeChat Group](https://openim-1253691595.cos.ap-nanjing.myqcloud.com/WechatIMG20.jpeg)

## Environment Preparation 🌍

- Install Docker with the Compose plugin or docker-compose on your server. For installation details, visit [Docker Compose Installation Guide](https://docs.docker.com/compose/install/linux/).

## Repository Cloning 🗂️

```bash
git clone https://github.com/openimsdk/openim-docker
```

## Configuration Modification 🔧

- Modify the `.env` file to configure the external IP. If using a domain name, Nginx configuration is required.

  ```plaintext
  # Set the external access address (IP or domain) for MinIO service
  MINIO_EXTERNAL_ADDRESS="http://external_ip:10005"
  ```

- For other configurations, please refer to the comments in the .env file

## Service Launch 🚀

- To start the service:

```bash
docker compose up -d
```

- To stop the service:

```bash
docker compose down
```

- To view logs:

```bash
docker logs -f openim-server
docker logs -f openim-chat
```

## Quick Experience ⚡

For a quick experience with OpenIM services, please visit the [Quick Test Server Guide](https://docs.openim.io/guides/gettingStarted/quickTestServer).

## Local Development 🛠️

If you want to use your own modified version of openim-server:

- **Quick Start**: [QUICK_START_LOCAL_DEV.md](./QUICK_START_LOCAL_DEV.md) - 3 steps to deploy your custom version
- **Detailed Guide**: [LOCAL_BUILD_GUIDE.md](./LOCAL_BUILD_GUIDE.md) - Complete guide for local development
- **Auto Script**: Use `./build-local.sh /path/to/openim-server` for automated build and deployment

### Quick Example

```bash
# 1. Build your custom image
cd /path/to/your/openim-server
docker build -t openim/openim-server:my-version .

# 2. Update configuration
cd /path/to/openim-docker
# Edit .env: OPENIM_SERVER_IMAGE=openim/openim-server:my-version

# 3. Deploy
docker compose up -d --force-recreate openim-server
```

## Troubleshooting 🔍

If you encounter issues with unhealthy services or connection problems, please refer to:
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues and solutions
```

