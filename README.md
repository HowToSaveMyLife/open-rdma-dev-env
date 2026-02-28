# 简介
Open-rdma 镜像是一个预配置的开发环境，旨在为 Open-rdma 驱动开发和测试提供即开即用的解决方案。镜像中包含了所有必要的工具、依赖和配置，帮助开发者高效地进行 Open-rdma 驱动的开发和测试。对于大多数初次接触本项目的同学，建议按照下列[一键启动](#一键启动)来完成初次体验。对于希望了解该开发环境细节的高级用户，请参阅 [Open-rdma 镜像设计](#open-rdma-镜像设计)。

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

`Ctrl+B, D` 退出会话，后台运行虚拟机。

再次进入虚拟机会话：

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
构建的开发测试镜像采用 “Docker 容器封装 QEMU 虚拟机” 的双层架构设计，既兼顾了容器化环境的易用性，又解决了内核模块开发对独立内核环境的需求，


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

# Open-rdma 镜像设计

## 镜像概述

Open-rdma 镜像采用 "Docker 容器封装 QEMU 虚拟机" 的双层架构设计，既兼顾了容器化环境的易用性，又满足了内核模块开发对独立内核环境的需求。

### 为什么选择 Docker + QEMU？

- **Docker 的优势**：容器技术使用便捷、分发高效，是现代开发环境的首选方案
- **QEMU 的必要性**：由于 Open-rdma 涉及内核模块的开发和测试，而 Docker 容器共享宿主机的操作系统内核，可能存在以下问题：
  - 内核版本不一致导致的兼容性问题
  - 内核模块加载冲突
  - 对宿主机内核的潜在风险
  
因此，我们在 Docker 容器内运行 QEMU 虚拟机，提供完全独立的内核环境，确保内核模块开发的稳定性和可控性。

## 镜像组成

### 1. QEMU 虚拟机环境

镜像中包含了完整的 QEMU 启动环境，配置了：
- **指定版本的 Linux 内核**：确保内核版本的一致性，避免兼容性问题
- **定制的文件系统**：通过 `virt-make-fs` 工具制作的 QEMU 镜像，包含完整的根文件系统

### 2. 开发工具链

QEMU 虚拟机镜像中预装了 Open-rdma 开发所需的全套工具链：

- **Python 环境**：用于测试脚本和辅助工具的运行
- **BSC (Bluespec Compiler)**：Bluespec 硬件描述语言编译器，用于 RTL 开发
- **Rust 工具链**：支持 Rust 驱动开发，包括 cargo、rustc 等完整工具集
- **rdma-core**：RDMA 用户空间库，提供 verbs API 和相关工具

### 3. Open-rdma 源码

镜像中包含 Open-rdma 的完整源码，包括：
- 内核驱动模块
- 用户空间驱动`open-rdma-driver`
- 硬件代码`open-rdma-rtl`

## 工作流程

1. **启动 Docker 容器**：通过 `docker compose` 一键启动容器环境
2. **自动启动 QEMU**：容器内的 tmux 会话自动启动 QEMU 虚拟机
3. **开发与测试**：在 QEMU 虚拟机中进行驱动的编译和测试，例如运行基础双端测试脚本

## 优势总结

- ✅ **开箱即用**：无需手动安装依赖，一键启动即可开发
- ✅ **环境一致**：所有开发者使用相同的内核版本、工具链和代码版本，避免环境差异导致的问题
- ✅ **易于分发**：Docker 镜像可以快速分发和部署
- ✅ **内核隔离**：QEMU 提供独立的内核环境，避免宿主机内核污染
