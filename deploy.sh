#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORCE_BUILD=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) FORCE_BUILD=true; shift ;;
    *) echo "未知参数: $1（仅支持 -f 强制重建 webview）"; exit 1 ;;
  esac
done

command -v java >/dev/null 2>&1 || { echo "错误: 未找到 java，请安装 JDK 17+"; exit 1; }
JAVA_VER=$(java -version 2>&1 | awk -F'"' '/version/{print $2}' | awk -F'.' '{print $1}')
[ "$JAVA_VER" -ge 17 ] 2>/dev/null || { echo "错误: 需要 JDK 17+，当前版本: $JAVA_VER"; exit 1; }

command -v npm >/dev/null 2>&1 || { echo "错误: 未找到 npm，请安装 Node.js"; exit 1; }

# 项目依赖安装（属于打包流程的一部分）
[ ! -d "$PROJECT_DIR/webview/node_modules" ] && (cd "$PROJECT_DIR/webview" && npm install --silent --loglevel=error)
[ ! -d "$PROJECT_DIR/ai-bridge/node_modules" ] && (cd "$PROJECT_DIR/ai-bridge" && npm install --silent --loglevel=error)

GRADLE_ARGS=("buildPlugin" "--no-daemon" "--stacktrace")

# 默认跳过 webview 构建（复用已有产物），-f 强制重建
if [ "$FORCE_BUILD" = false ]; then
  GRADLE_ARGS+=("-PskipWebview=true")
  echo "=> 跳过 webview 构建（使用 -f 强制重建）"
else
  echo "=> 强制重建 webview"
fi

"$PROJECT_DIR/gradlew" "${GRADLE_ARGS[@]}"

PLUGIN_ZIP=$(find "$PROJECT_DIR/build/distributions" -name "*.zip" -type f | head -1)
[ -z "$PLUGIN_ZIP" ] && { echo "错误: 未找到构建产物"; exit 1; }

echo ""
echo "打包成功: $PLUGIN_ZIP ($(du -h "$PLUGIN_ZIP" | cut -f1))"
cp $PLUGIN_ZIP ~/Downloads/

#./deploy.sh
#./deploy.sh -f