#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_REPO_DEFAULT="crpi-j4qy2kq2mmf6tmse.cn-beijing.personal.cr.aliyuncs.com/open-rdma/open-rdma"
IMAGE_REPO="${IMAGE_REPO:-$IMAGE_REPO_DEFAULT}"
PUBKEY_PATH="${1:-}"

if [[ -n "$PUBKEY_PATH" ]]; then
    if [[ ! -f "$PUBKEY_PATH" ]]; then
        echo "错误：指定的公钥文件不存在: $PUBKEY_PATH"
        echo "用法: ./quick-start.sh [pubkey_path]"
        exit 1
    fi

    cp "$PUBKEY_PATH" "$SCRIPT_DIR/authorized_keys"
    echo "已写入公钥: $PUBKEY_PATH -> authorized_keys"
else
    echo "未传入公钥路径，跳过 authorized_keys 更新"
fi

IMAGE_REPO="$IMAGE_REPO" docker compose up -d
echo "容器已启动，镜像仓库: $IMAGE_REPO"

for _ in {1..30}; do
    if docker compose ps --status running --services | grep -q '^open-rdma$'; then
        break
    fi
    sleep 1
done

if ! docker compose ps --status running --services | grep -q '^open-rdma$'; then
    echo "错误：open-rdma 容器未成功运行。请检查: docker compose logs open-rdma"
    exit 1
fi

echo "进入容器并连接 tmux(open-rdma)..."
exec docker compose exec open-rdma tmux attach-session -t open-rdma
