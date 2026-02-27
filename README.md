# open-rdma Docker 使用指南

本目录用于构建并启动 `open-rdma` 开发容器，容器内会启动 QEMU 虚机，并将虚机 SSH 端口转发到宿主机 `2222`。

## 1. 前置条件

- 系统：Linux
- 已安装：`docker`、`docker compose`

## 2. 替换 SSH 公钥

默认公钥文件：`authorized_keys`

将你公钥写入该文件（例如 `~/.ssh/id_ed25519.pub`）：

```bash
cp ~/.ssh/id_ed25519.pub authorized_keys
```

>启动容器时会将 `authorized_keys` 中的公钥写入虚机的 `/root/.ssh/authorized_keys`，无需重新构建镜像即可生效

## 3. 镜像构建与启动

### 3.1 使用预构建镜像

我们已将构建好的镜像推送到阿里云和 Docker Hub，你可以直接使用：

- 阿里云镜像：
```
IMAGE_REPO=crpi-j4qy2kq2mmf6tmse.cn-beijing.personal.cr.aliyuncs.com/open-rdma/open-rdma docker compose up -d
```

- Docker Hub 镜像：
```
IMAGE_REPO=harum1chi/open-rdma docker compose up -d
```

### 3.2 本地构建镜像

如果你需要修改 Dockerfile 或安装脚本，可以选择本地构建镜像：
```
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

## 4. 连接虚拟机

tmux 会自动启动并运行 QEMU 虚机，稍等片刻后即可通过 SSH 连接：

```bash
ssh -p 2222 root@127.0.0.1
```

进入容器并查看 QEMU 运行状态：

```bash
docker compose exec open-rdma bash
```

```bash
tmux attach-session -t open-rdma
```

退出 tmux：`Ctrl+B D`

## 5. 防火墙与端口放行

存在两层端口转发：

- 宿主机 `2222` -> Docker 容器 `2222`
- Docker 容器 `2222` -> QEMU 虚机 `22`

如果 SSH 连接失败，请确认宿主机防火墙放行 `2222`。

## 6. 常见问题与建议

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

# open-rdma 使用指南

## 1. 构建open-rdma-driver并运行测试

测试脚本会自动编译driver和cocotb测试代码，并运行测试

示例：
```bash
cd open-rdma-driver && ./tests/base_test/scripts/test_send_recv_sim.sh
```
首次编译rust代码会比较慢，后续会利用cargo缓存加速编译，cocotb测试会调用verilator进行编译，时间较长

## 2. 编译open-rdma-rtl backend

镜像已经将 Verilog 文件生成，如果修改了rtl代码需要重新生成。

```bash
cd open-rdma-rtl/test/cocotb && make verilog
```