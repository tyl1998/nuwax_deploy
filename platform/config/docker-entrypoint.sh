#!/bin/bash
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}[ERROR]${NC} $1"
}

# 普通echo输出也替换为log函数
echo_log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 生成随机 JWT 密钥函数
generate_jwt_secret() {
    local uuid1=$(cat /proc/sys/kernel/random/uuid)
    local uuid2=$(cat /proc/sys/kernel/random/uuid)
    local secret=$(echo "${uuid1}${uuid2}" | tr -d '-')
    echo "$secret"
}

# 管理 JWT 密钥并导出为环境变量
manage_jwt_secret() {
    local secret_file="/app/config/jwt/jwt_secret_key.txt"
    local secret_dir=$(dirname "$secret_file")

    # 检查并创建目录
    if [ ! -d "$secret_dir" ]; then
        log_info "创建目录: $secret_dir"
        mkdir -p "$secret_dir"
        if [ $? -ne 0 ]; then
            log_error "无法创建目录: $secret_dir"
            exit 1
        fi
    fi

    if [ ! -f "$secret_file" ]; then
        log_info "JWT 密钥文件 $secret_file 不存在，将自动生成。"
        JWT_SECRET_KEY=$(generate_jwt_secret)
        log_info "生成新的 JWT 密钥并写入文件: $secret_file"
        echo "$JWT_SECRET_KEY" > "$secret_file"
        if [ $? -ne 0 ]; then
            log_error "无法写入 JWT 密钥文件 $secret_file"
            exit 1
        fi
    else
        log_info "从文件 $secret_file 读取 JWT 密钥。"
        JWT_SECRET_KEY=$(cat "$secret_file")
        if [ -z "$JWT_SECRET_KEY" ]; then
             log_error "JWT 密钥文件 $secret_file 为空或读取失败"
             exit 1
        fi
    fi

    # 确保环境变量在整个会话中可用
    export JWT_SECRET_KEY
    # 将环境变量写入 /etc/environment 确保其他进程也能访问
    echo "JWT_SECRET_KEY=\"$JWT_SECRET_KEY\"" >> /etc/environment
    local write_status=$?
    if [ $write_status -ne 0 ]; then
        log_error "写入 /etc/environment 失败，退出码: $write_status"
    else
        log_info "成功将 JWT_SECRET_KEY 写入 /etc/environment"
    fi
    # 确认脚本内部变量值
    log_info "脚本内部确认 JWT_SECRET_KEY (前8位): ${JWT_SECRET_KEY:0:8}..."

    # 可选：打印部分密钥用于调试，注意安全风险
    # log_info "JWT_SECRET_KEY (前8位): ${JWT_SECRET_KEY:0:8}..."
}

# 打印环境变量
log_info "打印环境变量值..."
log_info "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}"
log_info "MYSQL_DATABASE=${MYSQL_DATABASE}"
log_info "MYSQL_USER=${MYSQL_USER}"
log_info "MYSQL_PASSWORD=${MYSQL_PASSWORD}"
log_info "APP_DEBUG_PORT=${APP_DEBUG_PORT}"
log_info "APP_PROFILE=${APP_PROFILE}"
log_info "APP_PORT=${APP_PORT}"

# 检查必要的环境变量
check_env_vars() {
    local required_vars=(
        "MYSQL_ROOT_PASSWORD"
        "MYSQL_DATABASE"
        "MYSQL_USER"
        "MYSQL_PASSWORD"
        "APP_DEBUG_PORT"
        "APP_PROFILE"
        "APP_PORT"
        "JWT_SECRET_KEY"
    )

    local missing_vars=0
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "环境变量 $var 未设置"
            missing_vars=1
        fi
    done

    if [ $missing_vars -eq 1 ]; then
        log_error "请设置所有必要的环境变量后重试"
        exit 1
    fi
}

# 等待目录就绪
wait_for_directory() {
    local dir=$1
    local timeout=30
    local counter=0
    log_info "等待目录 $dir 就绪..."
    while [ ! -d "$dir" ]; do
        if [ $counter -ge $timeout ]; then
            log_error "等待目录 $dir 超时"
            exit 1
        fi
        sleep 1
        ((counter++))
    done
}

# 创建目录并设置权限
create_and_chmod() {
    local dir=$1
    local user=$2
    local group=$3
    local mode=$4
    
    mkdir -p "$dir"
    if ! chown "$user:$group" "$dir" 2>/dev/null; then
        log_warn "警告: 无法设置 $dir 的所有者为 $user:$group"
    fi
    if ! chmod "$mode" "$dir" 2>/dev/null; then
        log_warn "警告: 无法设置 $dir 的权限为 $mode"
    fi
}

# 创建配置文件
create_config_file() {
    local file=$1
    local content=$2
    if [ ! -f "$file" ]; then
        log_info "创建配置文件: $file"
        log_info "$content" > "$file"
    else
        log_info "配置文件已存在: $file"
    fi
}

# 替换原来的普通echo为echo_log
echo_log "开始初始化环境..."
# 管理 JWT 密钥
manage_jwt_secret

check_env_vars


# 等待 MySQL 服务就绪
log_info "等待 MySQL 服务就绪..."
for i in {1..30}; do
    if mysqladmin ping -h mysql -u root -p"${MYSQL_ROOT_PASSWORD}" --silent 2>/dev/null; then
        log_info "MySQL 服务已就绪"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "MySQL 服务启动超时"
        break
    fi
    log_info "等待 MySQL 服务就绪... ($i/30)"
    sleep 2
done

# 测试 MySQL 连接
log_info "测试 MySQL 连接..."
if mysql -h mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
    log_info "MySQL 连接测试成功"
else
    log_error "MySQL 连接测试失败"
    exit 1
fi

# 检查数据库表是否存在
echo_log "检查数据库表是否需要初始化..."
    
# 检查关键表是否存在
CHECK_TABLES="agent_config schedule_task workflow_config knowledge_config model_config"
MISSING_TABLES=""
    
for table in $CHECK_TABLES; do
    TABLE_EXISTS=$(mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -h mysql -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${MYSQL_DATABASE}' AND table_name = '$table';" | tail -n 1)
    if [ "$TABLE_EXISTS" -eq "0" ]; then
        if [ -z "$MISSING_TABLES" ]; then
            MISSING_TABLES="$table"
        else
            MISSING_TABLES="$MISSING_TABLES, $table"
        fi
    fi
done
    



# 等待 Redis 启动
# 等待 Redis 启动
log_info "等待 Redis 启动..."
for i in {1..30}; do
    if redis-cli -h redis ping > /dev/null 2>&1; then
        log_info "Redis 已就绪"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "Redis 启动超时"
        exit 1
    fi
    log_info "等待 Redis 就绪... ($i/30)"
    sleep 1
done



# 检查 Milvus 服务
log_info "检查 Milvus 服务..."
for i in {1..30}; do
    if curl -s http://milvus:9091/healthz > /dev/null; then
        log_info "Milvus 服务已就绪"
        break
    fi
    if [ $i -eq 30 ]; then
        log_warn "无法连接到 Milvus 服务"
    fi
    log_info "等待 Milvus 服务就绪... ($i/30)"
    sleep 2
done



# 启动 Java 应用
if [ -f "/app/app.jar" ]; then
    echo_log "启动 Java 应用..."
    echo_log "使用的配置文件: application-${APP_PROFILE}.yml"
    echo_log "应用端口: ${APP_PORT}"
    echo_log "调试端口: ${APP_DEBUG_PORT}"
    # 确认 JWT_SECRET_KEY 环境变量已设置
    if [ -z "$JWT_SECRET_KEY" ]; then
        log_error "环境变量 JWT_SECRET_KEY 未设置，无法启动应用。"
        exit 1
    else
        log_info "JWT_SECRET_KEY 环境变量已设置。"
        echo_log "JWT_SECRET_KEY (前8位): ${JWT_SECRET_KEY:0:8}..."
    fi
    
    # 创建日志目录并设置权限
    echo_log "创建并设置日志目录权限..."
    mkdir -p /app/logs
    touch /app/logs/app.log
    chmod 755 /app/logs
    chmod 644 /app/logs/app.log
    
    # 检查 JAR 文件
    echo_log "检查 JAR 文件完整性..."
    JAR_PATH="/app/app.jar"

    # 检查文件是否存在
    if [ ! -f "$JAR_PATH" ]; then
        log_error "JAR 文件不存在: $JAR_PATH"
        ls -l /app/ | while read -r line; do
            log_error "目录内容: $line"
        done
        exit 1
    fi
    log_info "JAR 文件存在: $JAR_PATH"

    # 检查文件大小
    file_size=$(stat -f%z "$JAR_PATH" 2>/dev/null || stat -c%s "$JAR_PATH" 2>/dev/null)
    if [ -z "$file_size" ] || [ "$file_size" -eq 0 ]; then
        log_error "JAR 文件大小异常: $JAR_PATH (size: ${file_size:-unknown})"
        exit 1
    fi
    log_info "JAR 文件大小: $file_size bytes"

    # 检查文件权限
    if [ ! -r "$JAR_PATH" ]; then
        log_error "JAR 文件没有读取权限: $JAR_PATH"
        ls -l "$JAR_PATH" | while read -r line; do
            log_error "文件权限: $line"
        done
        exit 1
    fi
    log_info "JAR 文件权限: 可读"
    # 打印java版本
    log_info "Java 版本: $(java -version 2>&1)"
    # 打印java_home 环境变量
    log_info "Java 环境变量: $(echo $JAVA_HOME)"    
    # 设置 Java 选项
    export JAVA_OPTS="-server -Xms256m -Xmx2048m -XX:MaxMetaspaceSize=512m -XX:MaxMetaspaceFreeRatio=70 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/logs/java_heap.dump"
    
    # 启动 Java 应用并将日志重定向到文件
    # 修改 Java 启动命令
    java $JAVA_OPTS \
         -jar \
         -Dfile.encoding=UTF-8 \
         -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:${APP_DEBUG_PORT} \
         -Dspring.config.location=classpath:/,file:/app/config/ \
         -Dspring.config.name=application,application-external \
         -Dspring.profiles.active=${APP_PROFILE} \
         -Dserver.port=${APP_PORT} \
         -Dlogging.file.path=/app/logs \
         -Dlogging.level.root=INFO \
         "$JAR_PATH" &
    
    # 记录 Java 进程 ID
    JAVA_PID=$!
    
    # 等待应用启动
    echo_log "等待 Java 应用启动..."
    tail -f /app/logs/app.log &
    TAIL_PID=$!
    
    # 检查应用是否成功启动
    for i in {1..180}; do
        if curl -s http://localhost:${APP_PORT}/health > /dev/null; then
            log_info "Java 应用已成功启动，进程 ID: $JAVA_PID"
            break
        fi
        if [ $i -eq 180 ]; then
            log_error "Java 应用启动超时（180秒），请检查日志: /app/logs/app.log"
            kill $TAIL_PID
            exit 1
        fi
        # 检查 Java 进程是否还在运行
        if ! kill -0 $JAVA_PID 2>/dev/null; then
            log_error "Java 进程已退出，请检查日志: /app/logs/app.log"
            kill $TAIL_PID
            exit 1
        fi
        sleep 2
    done
else
    log_warn "Java 应用 JAR 文件不存在: /app/app.jar"
fi