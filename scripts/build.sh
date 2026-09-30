#!/bin/bash
set -euo pipefail

UPSTREAM_OWNER=loongarch64-releases
UPSTREAM_REPO=containerd-rpm
VERSION="${1}"
echo "   🏢 Org:   ${UPSTREAM_OWNER}"
echo "   📦 Proj:  ${UPSTREAM_REPO}"
echo "   🏷️  Ver:   ${VERSION}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DISTS="${ROOT_DIR}/dists"
SRCS="${ROOT_DIR}/srcs"

mkdir -p "${DISTS}/${VERSION}" "${SRCS}"

# ==========================================
# 👇 用户自定义构建逻辑 (示例)
# ==========================================

echo "🔧 Compiling ${UPSTREAM_OWNER}/${UPSTREAM_REPO} ${VERSION}..."

# 1. 准备阶段：安装依赖、下载代码、应用补丁等
prepare()
{
    echo "📦 [Prepare] Setting up build environment..."
    
    # TODO: 在此处添加准备命令
    rm -rf ${SRCS}/${VERSION}
    git clone -b loong64-containerd --depth=1 https://github.com/loongarch64-releases/docker-packaging ${SRCS}/${VERSION}
    
    echo "✅ [Prepare] Environment ready."
}

# 2. 编译阶段：核心构建命令
build()
{
    echo "🔨 [Build] Compiling source code..."
    
    # TODO: 在此处添加编译命令
    # 例如：make -j$(nproc) ARCH=loongarch64
    # 例如：cmake -DCMAKE_BUILD_TYPE=Release .. && make
    (
        cd ${SRCS}/${VERSION}
        (
            cd pkg/containerd
            docker buildx build -f rpm.Dockerfile --target pkg \
            --build-context scripts=../../hack/scripts \
            --build-arg PKG_REF=${VERSION} \
            -o type=local,dest=../../bin/pkg/containerd/anolis23 \
            . 
        )
    )
    

    echo "✅ [Build] Compilation finished."
}

# 3. 后处理阶段：整理产物、清理临时文件、验证版本
post_build()
{
    echo "📦 [Post-Build] Organizing artifacts..."
    
    rm -rf dists/${VERSION}
    mkdir -p dists/${VERSION}
    # TODO: 在此处添加整理命令
    local binary_path=$(find ./srcs/${VERSION}/bin -name  '*.rpm')
    mkdir -p dists && cp $binary_path dists/${VERSION}/
    
    echo "✅ [Post-Build] Artifacts ready in ./dists/${VERSION}."
}

# 主入口
main()
{
    prepare
    build
    post_build
}

main

# ==========================================
# 👆 自定义逻辑结束
# ==========================================

cat > "${DISTS}/${VERSION}/release.txt" <<EOF
Project: ${UPSTREAM_REPO}
Organization: ${UPSTREAM_OWNER}
Version: ${VERSION}
Build Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

echo "✅ Compilation finished."
ls -lh "${DISTS}/${VERSION}"
