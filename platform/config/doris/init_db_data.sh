#!/bin/bash

# 检查必要的环境变量
if [ -z "${DORIS_DB}" ]; then
    DORIS_DB="agent_platform"
    echo "DORIS_DB not set, using default value: ${DORIS_DB}"
fi

if [ -z "${CURRENT_FE_IP}" ]; then
    CURRENT_FE_IP="127.0.0.1"
    echo "CURRENT_FE_IP not set, using default value: ${CURRENT_FE_IP}"
fi

# 日志函数
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] $1"
}

# 等待 FE 服务启动
log "Waiting for FE to start..."
for i in {1..30}; do
    if curl -s "http://localhost:8030/api/health?fe=${CURRENT_FE_IP}:8030" > /dev/null; then
        log "FE is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        log "FE failed to start after 150 seconds"
        exit 1
    fi
    log "Waiting for FE to be ready... attempt $i/30"
    sleep 5
done

# 检查数据库是否存在
log "Checking if database ${DORIS_DB} exists..."
DB_EXISTS=$(mysql -h127.0.0.1 -P9030 -uroot --ssl=0 -N -e "SHOW DATABASES LIKE '${DORIS_DB}';" 2>/dev/null)

if [ -z "$DB_EXISTS" ]; then
    log "Database ${DORIS_DB} does not exist, creating it..."
    
    # 检查SQL文件是否存在
    if [ ! -f "./init_processed.sql" ]; then
        log "Warning: init_processed.sql not found in current directory"
        exit 0
    fi

    # 执行初始化 SQL 脚本
    log "Executing initialization SQL script..."
    if ! mysql -h127.0.0.1 -P9030 -uroot --ssl=0 --connect-timeout=30 < ./init_processed.sql 2>/dev/null; then
        log "Failed to execute initialization SQL script!"
        exit 1
    fi
    log "SQL initialization completed successfully"
else
    log "Database ${DORIS_DB} already exists, skipping creation and initialization"
fi

# 验证数据库访问权限
log "Verifying database access..."
if mysql -h127.0.0.1 -P9030 -uroot --ssl=0 --connect-timeout=30 -e "USE ${DORIS_DB}; SHOW TABLES;" 2>/dev/null; then
    log "Database initialization and access verification completed successfully!"
    exit 0
else
    log "Failed to verify database access!"
    exit 1
fi

