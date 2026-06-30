#!/bin/bash
set -e

DORIS_HOST="${DORIS_HOST:-doris-fe}"
DORIS_PORT="${DORIS_PORT:-9030}"
DORIS_USER="${DORIS_USER:-root}"
DORIS_PASSWORD="${DORIS_PASSWORD:-}"
DB_NAME="${DORIS_DB:-agent_custom_table}"

# 等待 doris-fe 端口可用
until mysql -h${DORIS_HOST} -P${DORIS_PORT} -u${DORIS_USER} -p${DORIS_PASSWORD} -e "select 1" >/dev/null 2>&1; do
  echo "等待 doris-fe 启动..."
  sleep 5
done

# 检查数据库是否存在，不存在则创建
DB_EXIST=$(mysql -h${DORIS_HOST} -P${DORIS_PORT} -u${DORIS_USER} -p${DORIS_PASSWORD} -e "SHOW DATABASES LIKE '${DB_NAME}';" | grep "${DB_NAME}" || true)
if [ -z "$DB_EXIST" ]; then
  echo "数据库 ${DB_NAME} 不存在，正在创建..."
  mysql -h${DORIS_HOST} -P${DORIS_PORT} -u${DORIS_USER} -p${DORIS_PASSWORD} -e "CREATE DATABASE ${DB_NAME};"
  echo "数据库 ${DB_NAME} 创建完成。"
else
  echo "数据库 ${DB_NAME} 已存在。"
fi