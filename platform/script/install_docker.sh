#!/bin/bash

# 设置错误时退出
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${GREEN}[INFO]${NC} ${BLUE}[$timestamp]${NC} $1"
}

log_warn() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${YELLOW}[WARN]${NC} ${BLUE}[$timestamp]${NC} $1"
}

log_error() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${RED}[ERROR]${NC} ${BLUE}[$timestamp]${NC} $1"
}

# 调试日志函数（默认禁用）
DEBUG_MODE=${DEBUG_MODE:-false}
log_debug() {
    if [ "$DEBUG_MODE" = true ]; then
        local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo -e "\033[0;36m[DEBUG]\033[0m ${BLUE}[$timestamp]${NC} $1"
    fi
}

# Docker一键安装函数 - 统一处理get.docker.com脚本的调用
run_docker_install_script() {
    log_info "准备执行Docker官方一键安装脚本..."
    
    # 使用本地已下载好的脚本
    local SCRIPT_FILE="./script/fast-install-docker.sh"
    
    # 检查脚本文件是否存在
    if [ ! -f "$SCRIPT_FILE" ]; then
        log_error "找不到本地安装脚本: $SCRIPT_FILE"
        log_info "请确保 fast-install-docker.sh 文件存在于当前目录"
        return 1
    fi
    
    # 确保脚本有执行权限
    log_info "设置脚本执行权限..."
    chmod +x "$SCRIPT_FILE"
    
    # 执行安装前的验证
    log_info "验证脚本内容..."
    head -n 10 "$SCRIPT_FILE"
    log_info "脚本头部内容预览已显示，确认无误后继续"
    
    # 先使用--dry-run测试
    log_info "使用--dry-run测试安装过程..."
    if ! sh "$SCRIPT_FILE" --dry-run; then
        log_error "Dry-run测试失败，安装可能存在问题"
        return 1
    fi
    
    log_info "Dry-run测试成功，准备正式安装"
    
    # 使用sudo运行正式安装
    log_info "执行Docker安装..."
    if ! sudo sh "$SCRIPT_FILE"; then
        log_error "Docker安装失败"
        return 1
    fi
    
    log_info "Docker安装脚本执行成功!"
    
    # 启动Docker服务
    log_info "启动Docker服务..."
    if command -v systemctl &> /dev/null; then
        sudo systemctl enable docker
        sudo systemctl start docker
    elif command -v service &> /dev/null; then
        sudo service docker start
    fi
    
    # 验证安装
    log_info "验证Docker安装..."
    if command -v docker &> /dev/null && sudo docker --version; then
        log_info "Docker安装成功! 版本信息:"
        sudo docker version
        return 0
    else
        log_error "Docker似乎安装成功但无法正确运行，请检查系统日志"
        return 1
    fi
}

# 检测操作系统类型和版本
detect_os() {
    local OS="Unknown"
    local OS_VERSION="Unknown"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        OS_VERSION=$VERSION_ID
        # 检查是否是openEuler或deepin
        if [[ "$ID" == "openEuler" ]]; then
            OS="openEuler"
        elif [[ "$ID" == "deepin" ]]; then
            OS="Deepin"
        fi
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        OS_VERSION=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        OS_VERSION=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS="Debian"
        OS_VERSION=$(cat /etc/debian_version)
    elif [ -f /etc/fedora-release ]; then
        OS="Fedora"
        OS_VERSION=$(grep -oE '[0-9]+' /etc/fedora-release)
    elif [ -f /etc/centos-release ]; then
        OS="CentOS"
        OS_VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/centos-release | cut -d"." -f1)
    elif [ -f /etc/redhat-release ]; then
        OS="RedHat"
        OS_VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | cut -d"." -f1)
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="MacOS"
        OS_VERSION=$(sw_vers -productVersion)
    fi
    
    # 将日志信息输出到标准错误流，避免干扰命令替换
    log_info "检测到操作系统: $OS $OS_VERSION" >&2 
    
    # 只将OS名称输出到标准输出
    echo "$OS"
}

#---------------------------------------------------
# 定义 install_compatible_docker 函数 (移到顶层)
#---------------------------------------------------
install_compatible_docker() {
    local system=$1
    local version=$2
    
    log_info "为 $system $version 安装兼容版本的Docker..."
    
    case $system in
        "Ubuntu"|"Debian"|"Deepin")
            # 为旧版Ubuntu/Debian安装兼容版本
            if [ $(echo "$version < 16.04" | bc) -eq 1 ]; then
                # 安装Docker 18.x (适合旧版Ubuntu/Debian)
                log_info "为旧版Linux安装Docker 18.x..."
                if run_docker_install_script; then
                    # 固定版本
                    sudo apt-get install -y --allow-downgrades docker-ce=18.09.1~ce-0~ubuntu
                else
                    log_warn "一键安装脚本执行失败，尝试使用系统包管理器安装Docker..."
                    # 尝试使用apt安装
                    sudo apt-get update
                    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
                    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                    sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
                    sudo apt-get update
                    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
                fi
            else
                # 安装最新版Docker
                sudo apt-get update
                sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            fi
            ;;
        "openEuler")
            log_info "为openEuler系统安装Docker..."
            # 尝试使用dnf命令从系统自带仓库安装Docker
            if command -v dnf &> /dev/null; then
                log_info "使用dnf安装Docker..."
                if sudo dnf install -y docker; then
                   log_info "使用dnf成功安装Docker"
                else 
                   log_warn "使用dnf安装Docker失败，尝试其他方式..."
                   # 尝试使用yum命令
                   if command -v yum &> /dev/null; then
                       log_info "使用yum安装Docker..."
                       if sudo yum install -y docker; then
                           log_info "使用yum成功安装Docker"
                       else
                            log_warn "使用yum安装Docker也失败，尝试安装podman..."
                            sudo dnf install -y podman podman-docker || sudo yum install -y podman podman-docker
                       fi
                   else
                       log_warn "未找到yum命令，尝试安装podman..."
                       sudo dnf install -y podman podman-docker
                   fi
                fi
            else
                # 如果没有dnf命令，尝试使用yum
                log_info "没有找到dnf命令，使用yum安装Docker..."
                if sudo yum install -y docker; then
                    log_info "使用yum成功安装Docker"
                else
                    log_warn "使用yum安装Docker失败，尝试安装podman..."
                    sudo yum install -y podman podman-docker
                fi
            fi

            # 检查Docker/Podman是否安装成功并设置别名
            if command -v docker &> /dev/null; then
                 log_info "Docker已成功安装"
            elif command -v podman &> /dev/null; then
                 log_warn "Docker安装失败，但Podman已安装，将设置docker别名指向podman"
                 sudo ln -sf $(which podman) /usr/bin/docker 2>/dev/null || true
                 log_info "已设置docker别名，后续操作将使用podman"
            else
                 log_error "无法安装Docker或Podman，请检查系统仓库或手动安装"
                 return 1 # 返回错误码
            fi
            ;;
        "CentOS"|"RedHat"|"Fedora")
            # 为旧版CentOS安装兼容版本
            if [ $(echo "$version < 7" | bc) -eq 1 ]; then
                # 安装Docker 1.13.x (最后支持CentOS 6的版本)
                log_info "为旧版CentOS安装Docker 1.13.x..."
                sudo yum install -y https://get.docker.com/rpm/1.7.1/centos-6/RPMS/x86_64/docker-engine-1.7.1-1.el6.x86_64.rpm
            elif [ "$version" = "7" ]; then
                # 先尝试一键安装，失败则使用传统方式
                if run_docker_install_script; then
                    log_info "一键安装成功，检查是否需要降级到兼容版本..."
                    # 检查安装的版本是否兼容，如果需要可以降级
                    INSTALLED_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
                    if [ $(echo "$INSTALLED_VERSION > 20.10.25" | bc) -eq 1 ]; then
                        log_warn "安装的Docker版本过高，尝试降级到CentOS/RHEL 7兼容版本..."
                        sudo yum downgrade -y docker-ce-20.10.25 docker-ce-cli-20.10.25 containerd.io
                    fi
                else
                    log_warn "一键安装失败，使用传统方式安装CentOS/RHEL 7兼容版本..."
                    # 为CentOS/RedHat 7安装最高支持版本的Docker
                    log_info "为CentOS/RedHat 7安装稳定版Docker 20.10.x..."
                    
                    # 移除旧版本Docker（如果存在）
                    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine &>/dev/null || true
                    
                    # 安装必要的依赖
                    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
                    
                    # 添加Docker仓库，先尝试国内镜像源，提高成功率
                    if [ "$system" = "RedHat" ]; then
                        log_info "检测到RedHat系统，使用适配的镜像源..."
                        # 移除可能存在的官方仓库
                        sudo rm -f /etc/yum.repos.d/docker-ce.repo
                        
                        # 创建自定义仓库文件
                        cat <<EOF | sudo tee /etc/yum.repos.d/docker-ce.repo
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
EOF
                        log_info "已添加阿里云Docker镜像源 (RedHat 7)"
                    else
                        # 对于CentOS系统，也优先使用国内镜像源
                        sudo rm -f /etc/yum.repos.d/docker-ce.repo
                        
                        # 添加阿里云镜像源
                        sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
                        log_info "已添加阿里云Docker镜像源 (CentOS 7)"
                    fi
                    
                    # 刷新仓库
                    log_info "正在更新仓库缓存..."
                    sudo yum clean all
                    sudo yum makecache
                    
                    # 首先尝试安装最后支持CentOS/RHEL 7的特定Docker版本
                    log_info "尝试安装Docker 20.10.25 (CentOS/RHEL 7最高支持版本)..."
                    sudo yum install -y docker-ce-20.10.25 docker-ce-cli-20.10.25 containerd.io
                fi
            else
                # 尝试一键安装，失败则使用传统方式
                if run_docker_install_script; then
                    log_info "一键安装成功"
                else
                    # 安装较新但仍兼容的版本
                    log_warn "一键安装失败，使用传统方式安装Docker..."
                    sudo yum install -y yum-utils
                    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                    sudo yum install -y docker-ce docker-ce-cli containerd.io
                fi
            fi
            ;;
        "MacOS")
            log_info "MacOS系统请手动安装Docker Desktop"
            open "https://www.docker.com/products/docker-desktop/"
            ;;
        *)
            # 默认安装Docker (适用于未知或未特殊处理的Linux系统)
            # 先判断参数是否为openEuler，如果是，我们仍然使用dnf/yum安装
            if [[ "$system" == "openEuler" ]]; then
                log_info "重新尝试为openEuler系统安装Docker..."
                if command -v dnf &> /dev/null; then
                    log_info "使用dnf安装Docker..."
                    sudo dnf install -y docker
                elif command -v yum &> /dev/null; then
                    log_info "使用yum安装Docker..."
                    sudo yum install -y docker
                else
                    log_warn "openEuler系统未找到dnf或yum命令，尝试fallback到通用脚本..."
                    if ! run_docker_install_script; then
                        log_error "所有安装方法均失败，请手动安装Docker"
                        return 1
                    fi
                fi
            else
                log_warn "未知的Linux发行版 ($system)，尝试使用通用一键安装脚本..."
                if ! run_docker_install_script; then
                    log_warn "一键安装失败，尝试自动检测系统类型并使用相应包管理器..."
                    
                    # 尝试检测包管理器并安装
                    if command -v apt-get &> /dev/null; then
                        log_info "检测到apt包管理器，尝试安装Docker..."
                        sudo apt-get update
                        sudo apt-get install -y docker.io || sudo apt-get install -y docker-ce
                    elif command -v dnf &> /dev/null; then
                        log_info "检测到dnf包管理器，尝试安装Docker..."
                        sudo dnf install -y docker
                    elif command -v yum &> /dev/null; then
                        log_info "检测到yum包管理器，尝试安装Docker..."
                        sudo yum install -y docker
                    else
                        log_error "无法识别系统包管理器，请手动安装Docker"
                        log_info "建议手动按照Docker官方文档安装: https://docs.docker.com/engine/install/"
                        return 1
                    fi
                fi
            fi
            ;;
    esac
    
    # 启动Docker服务 (对非MacOS系统)
    if [[ "$system" != "MacOS" ]] && command -v systemctl &> /dev/null; then
        if sudo systemctl enable docker && sudo systemctl start docker; then
            log_info "Docker服务已启用并启动"
            # 添加用户到docker组（如果需要sudo）
            if docker info > /dev/null 2>&1; then :; else
                if docker info 2>&1 | grep -q "permission denied"; then
                     log_info "将当前用户 $USER 添加到docker组..."
                     sudo usermod -aG docker $USER
                     log_info "请重新登录以使组更改生效"
                fi
            fi
        else
             log_error "启动或启用Docker服务失败"
             sudo systemctl status docker
             return 1
        fi
    elif [[ "$system" != "MacOS" ]] && command -v service &> /dev/null; then # For older systems
        if sudo chkconfig docker on && sudo service docker start; then
             log_info "Docker服务已启用并启动 (使用service)"
             # 添加用户到docker组...
        else
             log_error "启动或启用Docker服务失败 (使用service)"
             return 1
        fi
    fi

    # 检查安装是否最终成功
    if ! command -v docker &> /dev/null && ! (command -v podman &> /dev/null && readlink /usr/bin/docker | grep -q podman); then
        log_error "Docker安装失败，未找到docker命令或有效的podman别名"
        return 1
    fi

    log_info "Docker安装流程完成"
    return 0
}

#---------------------------------------------------
# 安装 Docker 的主函数
#---------------------------------------------------
install_docker() {
    log_info "Installing Docker..."
    
    # 在函数内部强制重新检测操作系统
    detect_os > /dev/null  # 先运行一次detect_os以确保获取了OS变量
    local current_os=$OS   # 直接使用全局OS变量
    local current_os_version=$OS_VERSION
    log_info "Install Docker: Re-detected OS as: $current_os $current_os_version"

    # 根据重新检测的结果决定流程
    if [[ "$current_os" == "openEuler" ]]; then
        log_info "检测到openEuler系统，将直接使用系统包管理器安装..."
        # 直接调用兼容性安装函数
        install_compatible_docker "$current_os" "$current_os_version"
        return $? # 返回安装结果
    fi

    # --- 非 openEuler 系统的逻辑 --- 
    log_info "非openEuler系统，继续标准安装流程..."
    
    # 询问是否使用一键安装方式
    read -p "是否使用一键安装方式(速度更快，推荐)? [Y/n] " -n 1 -r REPLY_QUICK_INSTALL
    echo
    
    # 如果选择了一键安装
    if [[ $REPLY_QUICK_INSTALL =~ ^[Yy]$ ]] || [[ -z $REPLY_QUICK_INSTALL ]]; then
        log_info "尝试使用一键安装方式安装Docker..."

        # 检查是否为RedHat 7系统
        if [[ "$current_os" == "RedHat" ]] && [[ "$current_os_version" == "7" ]]; then
            log_info "检测到RedHat 7系统，执行特定安装..."
            # ... (省略RedHat 7安装逻辑，假设成功会 return 0) ...
            # if install_rhel7_docker; then return 0; else log_warn "RHEL7安装失败，尝试通用脚本..." ; fi
        fi

        # 执行一键安装脚本
        if run_docker_install_script; then
            QUICK_INSTALL_SUCCESS=true
            return 0
        else
            # 安装失败，尝试系统包管理器安装
            log_warn "一键安装失败，尝试使用系统包管理器安装Docker..."
        fi
        
        # 系统包管理器安装Docker
        log_info "使用系统包管理器安装Docker..."
        if [[ "$current_os" == "Ubuntu" || "$current_os" == "Debian" || "$current_os" == "Deepin" ]]; then
            # Ubuntu/Debian系安装方法
            log_info "在 $current_os 上安装Docker..."
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            
            # 优先尝试国内镜像源
            log_info "尝试使用国内镜像源添加Docker仓库..."
            if curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -; then
                sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" -y
                log_info "已添加阿里云Docker镜像源"
            else
                # 如果国内源失败，使用官方源
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
            fi
            
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            
        elif [[ "$current_os" == "CentOS" || "$current_os" == "RedHat" || "$current_os" == "Fedora" ]]; then
            # CentOS/RHEL/Fedora系安装方法
            log_info "在 $current_os 上安装Docker..."
            sudo yum install -y yum-utils
            
            # 优先尝试国内镜像源
            log_info "尝试使用国内镜像源添加Docker仓库..."
            if sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo; then
                log_info "已添加阿里云Docker镜像源"
            else
                # 如果国内源失败，使用官方源
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            fi
            
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            
        elif [[ "$current_os" == "openEuler" ]]; then
            # openEuler系统特殊处理
            log_info "在openEuler系统上安装Docker..."
            sudo dnf install -y docker || sudo yum install -y docker
            
        else
            log_warn "未知的操作系统类型: $current_os"
            
            # 尝试检测包管理器并安装
            if command -v apt-get &> /dev/null; then
                log_info "检测到apt包管理器，尝试安装Docker..."
                sudo apt-get update
                sudo apt-get install -y docker.io || sudo apt-get install -y docker-ce
            elif command -v dnf &> /dev/null; then
                log_info "检测到dnf包管理器，尝试安装Docker..."
                sudo dnf install -y docker
            elif command -v yum &> /dev/null; then
                log_info "检测到yum包管理器，尝试安装Docker..."
                sudo yum install -y docker
            else
                log_error "无法识别系统包管理器，请手动安装Docker"
                log_info "建议手动按照Docker官方文档安装: https://docs.docker.com/engine/install/"
                return 1
            fi
        fi
        
        # 启动服务
        log_info "尝试启动Docker服务..."
        if command -v systemctl &> /dev/null; then 
            sudo systemctl enable docker 
            sudo systemctl start docker
        elif command -v service &> /dev/null; then
            sudo service docker start
        fi
        
        # 验证最终安装结果
        sleep 3
        if command -v docker &> /dev/null && sudo docker info &> /dev/null; then
            log_info "Docker已成功通过系统包管理器安装并启动!"
            return 0
        else
            log_error "Docker安装或启动失败，请尝试手动安装"
            return 1
        fi
    fi

    # 对于 用户选择不使用一键安装 / 一键安装失败 的情况
    log_info "执行系统特定的包管理器安装 Docker..."
    install_compatible_docker "$current_os" "$current_os_version"
    return $?
}

# 安装 Docker Compose
install_docker_compose() {
    log_info "正在安装 Docker Compose..."
    OS=$(detect_os)
    
    # 获取 Docker 版本
    local docker_major_version=""
    if command -v docker &>/dev/null && docker version --format '{{.Server.Version}}' &>/dev/null; then
        docker_major_version=$(docker version --format '{{.Server.Version}}' | cut -d '.' -f1)
        log_info "检测到 Docker 主版本: $docker_major_version"
    elif command -v docker &>/dev/null && docker --version &>/dev/null; then # Fallback version check
         docker_major_version=$(docker --version | cut -d ' ' -f3 | cut -d '.' -f1)
         log_info "检测到 Docker 主版本 (fallback): $docker_major_version"
    fi # 结束版本检测
    
    # 检查是否成功获取到 Docker 版本
    if [ -z "$docker_major_version" ]; then
        log_error "无法检测到有效的 Docker 版本。"
        log_error "请确保 Docker 已正确安装并正在运行。"
        log_error "无法自动确定应安装哪个 Docker Compose 版本，安装中止。"
        return 1 # 返回错误码，中止安装
    fi
    
    # 优先尝试通过包管理器安装
    install_docker_compose_pkg() {
        local docker_major_version=$1 #接收传入的Docker版本
        log_info "尝试通过系统包管理器安装Docker Compose (Docker Major: $docker_major_version)..."
        
        case $OS in
            "Ubuntu"|"Debian"|"Deepin")
                sudo apt-get update
                if [ "$docker_major_version" -lt 19 ]; then
                    log_info "Docker < 19，仅尝试安装 docker-compose (V1)..."
                    if sudo apt-get install -y docker-compose; then
                        log_info "Docker Compose V1 通过 apt 安装成功!"
                        return 0
                    fi
                else
                    log_info "Docker >= 19，优先尝试安装 docker-compose-plugin (V2)..."
                    # 优先安装 V2 plugin
                    if sudo apt-get install -y docker-compose-plugin; then
                        log_info "Docker Compose V2 (plugin) 通过 apt 安装成功!"
                        # 检查并创建兼容V1的链接
                        if [ -f /usr/libexec/docker/cli-plugins/docker-compose ]; then
                            sudo ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
                            sudo chmod +x /usr/local/bin/docker-compose
                        elif [ -f /usr/lib/docker/cli-plugins/docker-compose ]; then
                            sudo ln -sf /usr/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
                            sudo chmod +x /usr/local/bin/docker-compose
                        fi
                        return 0
                    elif sudo apt-get install -y docker-compose; then # 如果V2失败，尝试安装V1
                        log_info "Docker Compose V1 通过 apt 安装成功! (V2 安装失败或不可用)"
                        return 0
                    fi
                fi
                ;;
            "openEuler")
                if [ "$docker_major_version" -lt 19 ]; then
                    log_info "Docker < 19，仅尝试安装 docker-compose (V1)..."
                    if command -v dnf &> /dev/null; then
                        if sudo dnf install -y docker-compose; then log_info "V1 (dnf) OK"; return 0; fi
                    elif command -v yum &> /dev/null; then
                        if sudo yum install -y docker-compose; then log_info "V1 (yum) OK"; return 0; fi
                    fi
                else
                    log_info "Docker >= 19，优先尝试安装 docker-compose-plugin (V2)..."
                    # 优先使用dnf命令
                    if command -v dnf &> /dev/null; then
                        log_info "检测到 dnf 命令，尝试使用 dnf 安装..."
                        # 优先安装 V2 plugin
                        if sudo dnf install -y docker-compose-plugin; then
                            log_info "Docker Compose V2 (plugin) 通过 dnf 安装成功!"
                            # 检查并创建兼容V1的链接
                            if [ -f /usr/libexec/docker/cli-plugins/docker-compose ]; then
                                sudo ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
                                sudo chmod +x /usr/local/bin/docker-compose
                            elif [ -f /usr/lib/docker/cli-plugins/docker-compose ]; then
                                sudo ln -sf /usr/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
                                sudo chmod +x /usr/local/bin/docker-compose
                            fi
                            return 0
                        elif sudo dnf install -y docker-compose; then # 如果V2失败，尝试安装V1
                             log_info "Docker Compose V1 通过 dnf 安装成功! (V2 安装失败或不可用)"
                             return 0
                        else
                            log_warn "使用 dnf 安装 Docker Compose V2 或 V1 失败。"
                        fi
                    # 如果没有dnf，尝试使用yum
                    elif command -v yum &> /dev/null; then
                         log_info "未找到 dnf 命令，尝试使用 yum 安装..."
                        # 优先安装 V2 plugin
                        if sudo yum install -y docker-compose-plugin; then
                            log_info "Docker Compose V2 (plugin) 通过 yum 安装成功!"
                            # 检查并创建兼容V1的链接
                            if [ -f /usr/libexec/docker/cli-plugins/docker-compose ]; then
                                sudo ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
                                sudo chmod +x /usr/local/bin/docker-compose
                            elif [ -f /usr/lib/docker/cli-plugins/docker-compose ]; then
                                sudo ln -sf /usr/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
                                sudo chmod +x /usr/local/bin/docker-compose
                            fi
                            return 0
                        elif sudo yum install -y docker-compose; then # 如果V2失败，尝试安装V1
                             log_info "Docker Compose V1 通过 yum 安装成功! (V2 安装失败或不可用)"
                             return 0
                        else
                             log_warn "使用 yum 安装 Docker Compose V2 或 V1 失败。"
                        fi
                    else
                        log_warn "在 openEuler 系统上未找到 dnf 或 yum 命令。"
                    fi
                fi
                ;;
            "CentOS"|"RedHat"|"Fedora")
                 if [ "$docker_major_version" -lt 19 ]; then
                    log_info "Docker < 19，仅尝试安装 docker-compose (V1)..."
                    if sudo yum install -y docker-compose; then
                        log_info "Docker Compose V1 通过 yum 安装成功!"
                        return 0
                    fi
                 else
                    log_info "Docker >= 19，优先尝试安装 docker-compose-plugin (V2)..."
                    # 优先安装 V2 plugin
                    if sudo yum install -y docker-compose-plugin; then
                        log_info "Docker Compose V2 (plugin) 通过 yum 安装成功!"
                         # 检查并创建兼容V1的链接
                        if [ -f /usr/libexec/docker/cli-plugins/docker-compose ]; then
                            sudo ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
                            sudo chmod +x /usr/local/bin/docker-compose
                        elif [ -f /usr/lib/docker/cli-plugins/docker-compose ]; then
                            sudo ln -sf /usr/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
                            sudo chmod +x /usr/local/bin/docker-compose
                        fi
                        return 0
                    elif sudo yum install -y docker-compose; then # 如果V2失败，尝试安装V1
                        log_info "Docker Compose V1 通过 yum 安装成功! (V2 安装失败或不可用)"
                        return 0
                    fi
                 fi
                ;;
            *)  # 其他未知系统
                log_warn "未知操作系统 ($OS)，无法使用包管理器安装"
                return 1
                ;;
        esac
        
        # 如果安装命令执行了但未成功找到命令
        if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
            log_warn "包管理器安装命令执行完成，但未检测到有效的 docker-compose 或 docker compose 命令。"
            return 1
        fi
        
        # 如果任意一个命令安装成功，函数会提前返回0
        log_warn "无法通过系统包管理器安装Docker Compose"
        return 1 # 如果所有尝试都失败
    }
    
    # 下载并安装 Docker Compose V1 的最新二进制文件 (1.29.2)
    install_docker_compose_v1_binary() {
        local v1_version="1.29.2"
        log_info "尝试下载并安装 Docker Compose V1 二进制文件 (版本 $v1_version)..."
        local install_path="/usr/local/bin/docker-compose"
        
        # 尝试从官方 GitHub 下载
        local download_url="https://github.com/docker/compose/releases/download/${v1_version}/docker-compose-$(uname -s)-$(uname -m)"
        log_info "尝试从官方源下载: $download_url"
        
        if sudo curl -L "$download_url" -o "$install_path" -f; then
             # 检查下载的是否是HTML
             if grep -q -i 'DOCTYPE html' "$install_path" 2>/dev/null || grep -q -i '<html' "$install_path" 2>/dev/null; then
                  log_error "从官方源下载的文件似乎是HTML页面，安装失败。"
                  sudo rm -f "$install_path"
                  return 1
             else
                  sudo chmod +x "$install_path"
                  log_info "Docker Compose V1 ($v1_version) 二进制文件安装成功!"
                  return 0
             fi
        else
            log_warn "从官方源下载 V1 二进制文件失败。"
            # 使用 ghfast.top 作为国内镜像源备选
            local cn_url="https://ghfast.top/${download_url}" # 使用 ghfast.top 镜像
            log_info "尝试从国内镜像源下载: $cn_url"
            if sudo curl -L "$cn_url" -o "$install_path" -f; then
                if grep -q -i 'DOCTYPE html' "$install_path" 2>/dev/null || grep -q -i '<html' "$install_path" 2>/dev/null; then
                    log_warn "从国内镜像下载的文件似乎是HTML页面。"
                    sudo rm -f "$install_path"
                    return 1
                else
                    sudo chmod +x "$install_path"
                    log_info "Docker Compose V1 ($v1_version) 二进制文件通过国内镜像安装成功!"
                    return 0
                fi
            else
                 log_error "从国内镜像下载 V1 二进制文件也失败。"
                 return 1
            fi
        fi
    }
    
    # 尝试从国内镜像下载 (这个方法主要下载 V2，如果 Docker<19 可能不兼容，但作为备选保留)
    install_docker_compose_cn() {
        log_info "尝试从国内镜像下载Docker Compose V2..."
        
        # 获取最新稳定版本号
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        if [ -z "$COMPOSE_VERSION" ]; then
            # 如果获取失败，使用默认版本
            COMPOSE_VERSION="v2.24.6" # 使用一个较新的稳定版本
            log_info "无法获取最新版本，使用默认版本: $COMPOSE_VERSION"
        else
            log_info "最新Docker Compose版本: $COMPOSE_VERSION"
        fi
        
        # 确定下载目标路径
        local install_dir="/usr/local/lib/docker/cli-plugins"
        local install_path="${install_dir}/docker-compose"
        sudo mkdir -p "$install_dir"
        
        # 尝试从国内镜像下载
        local DOWNLOAD_URLS=(
            "https://ghproxy.com/https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
            "https://ghfast.top/https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
            "https://get.daocloud.io/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
            "https://download.fastgit.org/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
        )
        
        for url in "${DOWNLOAD_URLS[@]}"; do
            log_info "尝试从 $url 下载..."
            # 使用 -f 选项允许失败，如果下载的文件是HTML则删除
            if sudo curl -L "$url" -o "$install_path" --connect-timeout 10 -f; then
                # 检查下载的是否是HTML
                if grep -q -i 'DOCTYPE html' "$install_path" 2>/dev/null || grep -q -i '<html' "$install_path" 2>/dev/null; then
                     log_warn "下载的文件似乎是HTML页面，尝试下一个源..."
                     sudo rm -f "$install_path"
                     continue
                fi
                 
                sudo chmod +x "$install_path"
                log_info "Docker Compose V2 下载成功!"
                # 创建 V1 兼容链接
                sudo ln -sf "$install_path" /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
                return 0
            else
                 log_warn "从 $url 下载失败或超时。"
            fi
        done
        
        log_warn "从所有国内镜像下载失败。"
        return 1
    }
    
    # 使用pip安装 (这个方法安装 V1)
    install_docker_compose_pip() {
        log_info "尝试通过pip安装Docker Compose V1..."
        
        # 检查pip是否安装
        if ! command -v pip3 &> /dev/null; then
            log_info "未找到 pip3，尝试安装..."
            case $OS in
                "Ubuntu"|"Debian"|"Deepin")
                    sudo apt-get update
                    sudo apt-get install -y python3-pip
                    ;;
                "openEuler")
                    # 优先使用dnf命令
                    if command -v dnf &> /dev/null; then
                        sudo dnf install -y python3-pip
                    else
                        sudo yum install -y python3-pip
                    fi
                    ;;
                "CentOS"|"RedHat"|"Fedora")
                    sudo yum install -y python3-pip
                    ;;
                *)  # 其他未知系统
                    log_warn "未知操作系统 ($OS)，无法自动安装pip3"
                    return 1
                    ;;
            esac
            
             # 再次检查pip3是否安装成功
             if ! command -v pip3 &> /dev/null; then
                 log_error "安装pip3失败，无法继续使用pip安装。"
                 return 1
             fi
        fi
        
        # 安装docker-compose
        if sudo pip3 install --upgrade pip && sudo pip3 install docker-compose; then
            log_info "Docker Compose V1 通过pip安装成功!"
            return 0
        else
             log_warn "使用pip安装docker-compose失败。"
             return 1
        fi
    }
    
    # 使用Docker Desktop (仅MacOS)
    if [[ "$OS" == "MacOS" ]]; then
        log_info "Docker Compose 包含在 Docker Desktop for Mac 中。"
        log_info "请确保Docker Desktop已安装并运行。"
        # 检查 V2 是否可用
        if docker compose version &> /dev/null; then
             log_info "检测到 Docker Compose V2。"
             return 0
        else
             log_warn "未检测到有效的 Docker Compose V2 命令。"
             log_info "如果已安装 Docker Desktop，请确保其已启动。"
             return 1 # 在 MacOS 上，我们期望 Compose V2 随 Desktop 提供
        fi
    fi
    
    # 按优先级尝试安装方法
    log_info "尝试按优先级安装 Docker Compose..."
    
    # 1. 优先使用包管理器 (传入Docker版本)
    if install_docker_compose_pkg "$docker_major_version"; then
        # 检查包管理器安装的版本是否合适（特别是V1的已知问题版本）
        if [ "$docker_major_version" -lt 19 ]; then
             if command -v docker-compose &> /dev/null; then
                 installed_v1_version=$(docker-compose -v 2>/dev/null | tr -d '\0' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
                 # 如果包管理器安装的是已知的有问题的 V1 版本 (如 1.22.0)，则尝试用二进制文件覆盖
                 if [[ "$installed_v1_version" == "1.22.0" ]]; then
                     log_warn "包管理器安装了 Docker Compose V1 ($installed_v1_version)，该版本可能与当前 Python 环境不兼容。"
                     log_info "将尝试下载并安装 V1 最新二进制版本 (1.29.2) 进行覆盖。"
                     if ! install_docker_compose_v1_binary; then
                         log_error "无法下载 V1 二进制文件覆盖有问题的版本。安装可能失败。"
                         # 不直接退出，允许后续 pip 作为最终备选
                     else 
                         log_info "已成功使用 V1 二进制文件覆盖。"
                         return 0 # 二进制覆盖成功，安装完成
                     fi
                 else
                     log_info "Docker Compose V1 ($installed_v1_version) 已通过系统包管理器成功安装。"
                     return 0 # 包管理器安装了没问题的 V1 版本
                 fi
             else
                  # 包管理器声称成功，但找不到命令，这不应该发生，但作为保险
                  log_warn "包管理器安装声称成功，但未找到 docker-compose 命令。继续尝试其他方法..."
             fi
        else # Docker >= 19
             log_info "Docker Compose V2/V1 已通过系统包管理器成功安装或已存在。"
             return 0 # 对于 >=19 的情况，包管理器安装成功即可
        fi
    fi
    
    # 2. 如果 Docker < 19，且包管理器失败或安装了问题版本，尝试下载 V1 二进制
    if [ "$docker_major_version" -lt 19 ]; then
        log_info "包管理器安装 V1 失败或安装了问题版本，尝试下载 V1 二进制..."
        if install_docker_compose_v1_binary; then
             log_info "Docker Compose V1 二进制文件已成功安装。"
             return 0
        fi
    # 3. 如果 Docker >= 19，且包管理器失败，尝试从国内镜像下载 V2
    elif [ "$docker_major_version" -ge 19 ]; then
        log_info "包管理器安装失败，尝试从国内镜像下载 V2 (因为 Docker >= 19)..."
        if install_docker_compose_cn; then
             log_info "Docker Compose V2 已通过国内镜像成功下载。"
             return 0
        fi
    fi
    
    # 4. 尝试通过 pip 安装 V1 (所有Docker版本都可以尝试作为备选)
    log_info "前面的方法失败或跳过，尝试通过 pip 安装 V1..."
    if install_docker_compose_pip; then
         log_info "Docker Compose V1 已通过 pip 成功安装。"
         return 0
    fi
    
    # 5. 如果 Docker >= 19，且其他方法失败，最后尝试从官方下载 V2
    if [ "$docker_major_version" -ge 19 ]; then
        log_info "所有优先方法失败，尝试从官方源下载 Docker Compose V2 (因为 Docker >= 19)..."
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        if [ -z "$COMPOSE_VERSION" ]; then
            COMPOSE_VERSION="v2.24.6" # 使用一个较新的稳定版本
            log_info "无法获取最新版本，使用默认版本: $COMPOSE_VERSION"
        fi
        
        log_info "尝试下载Docker Compose版本: $COMPOSE_VERSION"
        
        local install_dir="/usr/local/lib/docker/cli-plugins"
        local install_path="${install_dir}/docker-compose"
        sudo mkdir -p "$install_dir"
        
        if sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o "$install_path" -f; then
            # 检查下载的是否是HTML
            if grep -q -i 'DOCTYPE html' "$install_path" 2>/dev/null || grep -q -i '<html' "$install_path" 2>/dev/null; then
                 log_error "从官方源下载的文件似乎是HTML页面，安装失败。"
                 sudo rm -f "$install_path"
            else
                 sudo chmod +x "$install_path"
                 log_info "Docker Compose V2 通过官方源安装成功!"
                 # 创建 V1 兼容链接
                 sudo ln -sf "$install_path" /usr/local/bin/docker-compose
                 sudo chmod +x /usr/local/bin/docker-compose
                 return 0
            fi
        else
            log_error "从官方源下载失败。"
        fi
    fi
    
    # 如果所有方法都失败
    log_error "所有安装方法均失败，请手动安装Docker Compose后重试。"
    log_info "手动安装指南: https://docs.docker.com/compose/install/" 
    return 1
}

# 检查Docker版本兼容性并进行调整
check_docker_compatibility() {
    # 提取版本号
    DOCKER_MAJOR_VERSION=$(echo $DOCKER_VERSION | cut -d '.' -f1)
    DOCKER_MINOR_VERSION=$(echo $DOCKER_VERSION | cut -d '.' -f2)
    
    log_info "检查Docker版本兼容性..."
    log_info "Docker版本: $DOCKER_VERSION"
    
    # 保存Docker版本信息到环境文件，供deploy.sh使用
    echo "DOCKER_VERSION=\"$DOCKER_VERSION\"" > "$(dirname "$0")/docker_version.env"
    echo "DOCKER_MAJOR_VERSION=\"$DOCKER_MAJOR_VERSION\"" >> "$(dirname "$0")/docker_version.env"
    echo "NEED_SUDO=\"$NEED_SUDO\"" >> "$(dirname "$0")/docker_version.env"
    
    log_info "Docker版本信息已保存到环境文件"
    return 0
}

# 检查 Docker 是否安装
check_docker() {
    log_info "检查Docker是否已安装..."
    
    if ! command -v docker &> /dev/null; then
        log_warn "Docker未安装，将自动开始安装..."
        install_docker
    else
        DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
        DOCKER_MAJOR_VERSION=$(echo $DOCKER_VERSION | cut -d '.' -f1)
        log_info "已安装Docker (版本 $DOCKER_VERSION)"
        
        # 检查Docker版本兼容性
        check_docker_compatibility
    fi
    
    # 检查 Docker 是否运行
    MAX_RETRIES=5
    RETRY_COUNT=0
    DOCKER_STARTED=false
    NEED_SUDO=false
    
    # 首先尝试不使用sudo运行docker info
    if docker info > /dev/null 2>&1; then
        DOCKER_STARTED=true
        log_info "Docker服务正在运行，用户权限正常"
    else
        # 检查错误类型，判断是否是权限问题还是服务未启动
        if docker info 2>&1 | grep -q "permission denied"; then
            log_info "检测到Docker权限问题，将尝试使用sudo"
            NEED_SUDO=true
            # 尝试使用sudo
            if sudo docker info > /dev/null 2>&1; then
                DOCKER_STARTED=true
                log_info "Docker服务正在运行（需要sudo权限）"
            fi
        fi
    fi
    
    # 如果服务未启动，尝试启动
    while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$DOCKER_STARTED" = false ]; do
        RETRY_COUNT=$((RETRY_COUNT+1))
        log_warn "Docker未运行，尝试启动 (尝试 $RETRY_COUNT/$MAX_RETRIES)"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            log_info "MacOS系统请手动启动Docker Desktop"
            # 尝试打开Docker Desktop
            open -a Docker
            sleep 10
        else
            sudo systemctl daemon-reload
            sudo systemctl start docker || sudo service docker start
            sleep 3
        fi
        
        # 根据之前的检测结果决定是否使用sudo检查
        if [ "$NEED_SUDO" = true ]; then
            if sudo docker info > /dev/null 2>&1; then
                DOCKER_STARTED=true
                log_info "Docker服务已成功启动（需要sudo权限）"
                break
            fi
        else
            if docker info > /dev/null 2>&1; then
                DOCKER_STARTED=true
                log_info "Docker服务已成功启动"
                break
            elif docker info 2>&1 | grep -q "permission denied"; then
                NEED_SUDO=true
                if sudo docker info > /dev/null 2>&1; then
                    DOCKER_STARTED=true
                    log_info "Docker服务已成功启动（需要sudo权限）"
                    break
                fi
            fi
        fi
    done
    
    if [ "$DOCKER_STARTED" = false ]; then
        log_error "在多次尝试后无法启动Docker服务"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            log_info "请手动打开Docker Desktop并确保其正在运行"
        else
            log_info "请尝试手动运行: sudo systemctl start docker"
            log_info "然后检查状态: sudo systemctl status docker"
        fi
        
        exit 1
    fi
    
    # 检查当前用户是否在docker组中，仅在需要sudo时提示
    if [ "$NEED_SUDO" = true ] && ! groups | grep -q docker && [[ "$OSTYPE" != "darwin"* ]]; then
        log_warn "当前用户不在docker组中，需要使用sudo运行docker命令"
        log_info "要避免每次输入密码，请运行以下命令并重新登录:"
        log_info "sudo usermod -aG docker $USER"
    fi
    
    return 0
}

# 检查 Docker Compose 是否安装
check_docker_compose() {
    log_info "检查Docker Compose是否已安装..."
    
    # 添加Ubuntu 24专用检测
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$NAME" == "Ubuntu" && "$VERSION_ID" == "24.04" ]]; then
            log_info "检测到Ubuntu 24.04系统"
            
            # 检查是否有docker compose插件（V2版本）
            if docker compose version &> /dev/null; then
                COMPOSE_VERSION=$(docker compose version --short)
                COMPOSE_V2=true
                log_info "检测到Docker Compose V2 (版本 $COMPOSE_VERSION)"
                # 创建别名以兼容后续代码
                shopt -s expand_aliases
                alias docker-compose='docker compose'
                
                # 保存Compose版本信息到环境文件
                echo "COMPOSE_VERSION=\"$COMPOSE_VERSION\"" > "$(dirname "$0")/compose_version.env"
                echo "COMPOSE_V2=\"$COMPOSE_V2\"" >> "$(dirname "$0")/compose_version.env"
                
                return 0
            fi
            
            # 检查是否有docker-compose命令（V1版本）
            if command -v docker-compose &> /dev/null; then
                COMPOSE_VERSION=$(docker-compose --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
                COMPOSE_V2=false
                log_info "检测到Docker Compose V1 (版本 $COMPOSE_VERSION)"
                
                # 保存Compose版本信息到环境文件
                echo "COMPOSE_VERSION=\"$COMPOSE_VERSION\"" > "$(dirname "$0")/compose_version.env"
                echo "COMPOSE_V2=\"$COMPOSE_V2\"" >> "$(dirname "$0")/compose_version.env"
                
                return 0
            fi
            
            # 如果都没有安装，则提示安装
            log_warn "Ubuntu 24.04系统缺少Docker Compose，将尝试安装"
            install_docker_compose
            
            # 安装后再次检查
            if docker compose version &> /dev/null; then
                COMPOSE_VERSION=$(docker compose version --short)
                COMPOSE_V2=true
                log_info "成功安装Docker Compose V2 (版本 $COMPOSE_VERSION)"
                shopt -s expand_aliases
                alias docker-compose='docker compose'
                
                # 保存Compose版本信息到环境文件
                echo "COMPOSE_VERSION=\"$COMPOSE_VERSION\"" > "$(dirname "$0")/compose_version.env"
                echo "COMPOSE_V2=\"$COMPOSE_V2\"" >> "$(dirname "$0")/compose_version.env"
                
                return 0
            elif command -v docker-compose &> /dev/null; then
                COMPOSE_VERSION=$(docker-compose --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
                COMPOSE_V2=false
                log_info "成功安装Docker Compose V1 (版本 $COMPOSE_VERSION)"
                
                # 保存Compose版本信息到环境文件
                echo "COMPOSE_VERSION=\"$COMPOSE_VERSION\"" > "$(dirname "$0")/compose_version.env"
                echo "COMPOSE_V2=\"$COMPOSE_V2\"" >> "$(dirname "$0")/compose_version.env"
                
                return 0
            else
                log_error "所有安装方法均失败，请手动安装Docker Compose后重试"
                exit 1
            fi
        fi
    fi
    
    # 继续使用原有逻辑检查非Ubuntu 24系统
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_warn "Docker Compose未安装"
        log_info "将自动安装Docker Compose..."
        install_docker_compose
        
        # 安装后再次检查是否安装成功
        if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
            log_error "安装Docker Compose失败"
            log_info "请手动安装Docker Compose后重试"
            exit 1
        fi
    fi
    
    # 检查是否是Docker Compose V2
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short)
        COMPOSE_V2=true
        log_info "检测到Docker Compose V2 (版本 $COMPOSE_VERSION)"
        # 创建别名以兼容后续代码
        shopt -s expand_aliases
        alias docker-compose='docker compose'
    else
        COMPOSE_VERSION=$(docker-compose --version | sed -E 's/.*version[^0-9]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/g')
        COMPOSE_V2=false
        log_info "检测到Docker Compose V1 (版本 $COMPOSE_VERSION)"
    fi
    
    # 提取主要版本号
    COMPOSE_MAJOR_VERSION=$(echo $COMPOSE_VERSION | cut -d '.' -f1)
    COMPOSE_MINOR_VERSION=$(echo $COMPOSE_VERSION | cut -d '.' -f2)
    
    # 保存Compose版本信息到环境文件
    echo "COMPOSE_VERSION=\"$COMPOSE_VERSION\"" > "$(dirname "$0")/compose_version.env"
    echo "COMPOSE_V2=\"$COMPOSE_V2\"" >> "$(dirname "$0")/compose_version.env"
    echo "COMPOSE_MAJOR_VERSION=\"$COMPOSE_MAJOR_VERSION\"" >> "$(dirname "$0")/compose_version.env"
    echo "COMPOSE_MINOR_VERSION=\"$COMPOSE_MINOR_VERSION\"" >> "$(dirname "$0")/compose_version.env"
    
    log_info "Docker Compose版本信息已保存到环境文件"
    
    return 0
}

# 安装和检查所有依赖
install_all_dependencies() {
    log_info "开始安装和检查所有依赖..."
    
    # 检查Docker
    check_docker
    
    # 检查Docker Compose
    check_docker_compose
    
    log_info "所有依赖安装和检查完成"
    return 0
}

# 主函数
main() {
    # 解析命令行参数
    case "$1" in
        docker)
            check_docker
            ;;
        compose)
            check_docker_compose
            ;;
        all)
            install_all_dependencies
            ;;
        quick)
            log_info "使用一键方式安装Docker..."
            USE_QUICK_INSTALL="y" 
            install_docker
            check_docker_compose
            ;;
        *)
            log_info "用法: $0 {docker|compose|all|quick}"
            log_info "  docker  - 仅安装或检查Docker"
            log_info "  compose - 仅安装或检查Docker Compose"
            log_info "  all     - 安装和检查所有依赖"
            log_info "  quick   - 使用一键脚本快速安装Docker和Docker Compose"
            ;;
    esac
}

# 如果直接执行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

exit 0 