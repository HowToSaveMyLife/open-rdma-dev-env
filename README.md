# Open-rdma Image Quick Start Guide

## 前置条件

- Linux
- 已安装 docker、docker compose

## 一键启动

在仓库根目录执行：

```bash
./quick-start.sh
```

待虚拟机启动后用`root:root`登录，运行基础双端测试：

```bash
cd /root/open-rdma/open-rdma-driver && ./tests/base_test/scripts/test_send_recv_sim.sh
```

`Ctrl+B, D` 退出 tmux 会话，容器内 QEMU 会话仍在运行。

启动后再次进入虚拟机会话：

```bash
docker compose exec open-rdma tmux attach-session -t open-rdma
```

## 启动可选项

指定公钥路径以用于ssh登录虚机，登录用户与地址为`root@localhost:2222`：

```bash
./quick-start.sh ~/.ssh/id_ed25519.pub
```

切换到Dockerhub镜像（默认使用阿里云镜像）：

```bash
IMAGE_REPO=harum1chi/open-rdma ./quick-start.sh
```

# Open-rdma 手动启动

## 1. 替换 SSH 公钥

默认公钥文件：`authorized_keys`

将你公钥写入该文件（例如 `~/.ssh/id_ed25519.pub`）：

```bash
cp ~/.ssh/id_ed25519.pub authorized_keys
```

>启动容器时会将 `authorized_keys` 中的公钥写入虚机的 `/root/.ssh/authorized_keys`，无需重新构建镜像即可生效

## 2. 镜像构建与启动

### 2.1 使用预构建镜像

我们已将构建好的镜像推送到阿里云和 Docker Hub，你可以直接使用：

- 阿里云镜像：
```bash
IMAGE_REPO=crpi-j4qy2kq2mmf6tmse.cn-beijing.personal.cr.aliyuncs.com/open-rdma/open-rdma docker compose up -d
```

- Docker Hub 镜像：
```bash
IMAGE_REPO=harum1chi/open-rdma docker compose up -d
```

### 2.2 本地构建镜像

如果你需要修改 Dockerfile 或安装脚本，可以选择本地构建镜像：
```bash
docker compose up -d --build
```

#### 代理配置

当前仓库里代理地址为Docker默认网桥 `http://172.17.0.1:1081`

根据你的实际环境取消代理或修改地址

需要修改的文件有三处：

1. `Dockerfile`
	- `ENV HTTP_PROXY=...`
	- `ENV HTTPS_PROXY=...`

2. `scripts/install-env.sh`
	- `export http_proxy=...`
	- `export https_proxy=...`
	- 末尾写入 `.bashrc` 的 proxy 配置

3. `scripts/get-src.sh`
	- `export http_proxy=...`
	- `export https_proxy=...`

## 3. 连接虚拟机

tmux 会自动启动并运行 QEMU 虚机，稍等片刻后即可通过 SSH 连接：

```bash
ssh -p 2222 root@127.0.0.1
```

或者通过docker进入虚拟机：

```bash
docker compose exec open-rdma tmux attach-session -t open-rdma
```

退出虚拟机，后台运行：`Ctrl+B D`

## 4. 运行基础双端测试

进入虚拟机后，运行：

```bash
cd /root/open-rdma/open-rdma-driver && ./tests/base_test/scripts/test_send_recv_sim.sh
```

# 常见问题与解决

1. `ssh -p 2222 root@127.0.0.1` 失败
	- 检查容器是否启动：`docker compose ps`
	- 检查端口是否监听：`ss -lntp | grep 2222`
	- 检查防火墙是否放行 `2222/tcp`

2. 下载慢/超时
	- 优先确认代理地址可用
	- 确认 `Dockerfile` 和 `scripts/install-env.sh` 两处都已修改
	- 修改后必须重新 build

3. 密钥不生效
	- 确认 `authorized_keys` 内容是**完整单行公钥**
	- 修改 `authorized_keys` 后无需重建镜像，直接重启容器即可生效

4. 端口冲突
	- 若宿主机 `2222` 已被占用，需修改 `docker-compose.yaml` 的端口映射

5. 构建时间长
	- 首次构建会下载大量依赖（含工具链和镜像），属于预期行为
    - 后续构建会利用downloader缓存，时间会大幅缩短，但qemu镜像的构建以及virt-make-fs仍消耗较多时间