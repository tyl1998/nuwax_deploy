-- 创建数据库
CREATE DATABASE IF NOT EXISTS agent_platform;

-- 设置默认字符集和排序规则
ALTER DATABASE agent_platform
SET PROPERTIES (
    "charset"="utf8mb4",
    "collation"="utf8mb4_general_ci"
); 