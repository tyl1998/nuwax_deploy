#!/bin/sh
set -e

# MinIO服务器地址和凭证，从环境变量中获取
MINIO_SERVER_ALIAS=${MINIO_SERVER_ALIAS:-myminio}
MINIO_SERVER_URL=${MINIO_SERVER_URL:-http://minio:9000}
MINIO_ACCESS_KEY=${MINIO_ROOT_USER:-minioadmin} # 使用MINIO_ROOT_USER作为默认值
MINIO_SECRET_KEY=${MINIO_ROOT_PASSWORD:-minioadmin} # 使用MINIO_ROOT_PASSWORD作为默认值
BUCKET_NAME=${MINIO_BUCKET_NAME:-quickwit-indexes}

# 等待MinIO启动
until mc alias set ${MINIO_SERVER_ALIAS} ${MINIO_SERVER_URL} ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY} --api S3v4; do
  echo "Waiting for MinIO server to be ready..."
  sleep 5
done

echo "MinIO server is ready."

# 检查存储桶是否存在
if mc ls "${MINIO_SERVER_ALIAS}/${BUCKET_NAME}" > /dev/null 2>&1; then
  echo "Bucket '${BUCKET_NAME}' already exists."
else
  echo "Bucket '${BUCKET_NAME}' does not exist. Creating bucket..."
  mc mb "${MINIO_SERVER_ALIAS}/${BUCKET_NAME}"
  if [ $? -eq 0 ]; then
    echo "Bucket '${BUCKET_NAME}' created successfully."
  else
    echo "Failed to create bucket '${BUCKET_NAME}'."
    exit 1
  fi
fi

exit 0