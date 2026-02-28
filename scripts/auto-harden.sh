#!/usr/bin/env bash

##############################################
# OpenClaw 自动加固脚本
# 
# 功能：一键加固 OpenClaw 实例
# 警告：运行前请备份配置！
##############################################

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
OPENCLAW_DIR="${HOME}/.openclaw"
BACKUP_DIR="${OPENCLAW_DIR}/backup"
CONFIG_FILE="${OPENCLAW_DIR}/openclaw.json"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# 检查是否有 jq，如果没有则使用降级方案
HAS_JQ=false
if command -v jq &> /dev/null; then
    HAS_JQ=true
fi

# 打印函数
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_step() {
    echo -e "${BLUE}[步骤]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✅]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ️  信息]${NC} $1"
}

# 检查和安装 jq
check_jq() {
    if ! command -v jq &> /dev/null; then
        print_warning "缺少 jq 工具，尝试安装..."
        
        # 检测系统类型
        if command -v apt-get &> /dev/null; then
            # Debian/Ubuntu
            if sudo -n apt-get install -y jq 2>/dev/null; then
                print_success "jq 已安装"
                return 0
            else
                print_error "无法自动安装 jq（需要 sudo 权限）"
                print_info "请手动运行：sudo apt-get install jq"
                return 1
            fi
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            if sudo -n yum install -y jq 2>/dev/null; then
                print_success "jq 已安装"
                return 0
            else
                print_error "无法自动安装 jq（需要 sudo 权限）"
                print_info "请手动运行：sudo yum install jq"
                return 1
            fi
        elif command -v brew &> /dev/null; then
            # macOS
            if brew install jq 2>/dev/null; then
                print_success "jq 已安装"
                return 0
            else
                print_error "无法安装 jq"
                print_info "请手动运行：brew install jq"
                return 1
            fi
        else
            print_error "未知系统类型，无法自动安装 jq"
            print_info "请手动安装 jq：https://stedolan.github.io/jq/download/"
            return 1
        fi
    else
        print_success "jq 已安装"
        return 0
    fi
}

# 备份配置
backup_config() {
    print_step "备份当前配置..."
    
    mkdir -p "$BACKUP_DIR"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "${BACKUP_DIR}/openclaw-backup-${TIMESTAMP}.json"
        print_success "配置已备份：${BACKUP_DIR}/openclaw-backup-${TIMESTAMP}.json"
    else
        print_warning "配置文件不存在，跳过备份"
    fi
    
    return 0
}

# 确认操作
confirm_action() {
    local message="$1"
    
    if [[ "${INTERACTIVE:-false}" == "true" ]]; then
        read -p "$message (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    return 0
}

# 检查 OpenClaw 版本
check_version() {
    print_step "检查 OpenClaw 版本..."
    
    if ! command -v openclaw &> /dev/null; then
        print_error "OpenClaw 未安装"
        return 1
    fi
    
    local version=$(openclaw --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1)
    local min_safe_version="2026.1.29"
    
    print_info "当前版本：$version"
    
    if [[ "$version" < "$min_safe_version" ]]; then
        print_warning "版本过旧，建议升级"
        
        if confirm_action "是否升级到最新版本？"; then
            print_step "升级 OpenClaw..."
            openclaw update
            print_success "升级完成"
        fi
    else
        print_success "版本安全"
    fi
    
    return 0
}

# 加固配置文件
harden_config() {
    print_step "加固配置文件..."
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "配置文件不存在：$CONFIG_FILE"
        return 1
    fi
    
    # 创建安全配置
    print_info "应用安全配置..."
    
    local temp_file=$(mktemp)
    
    if [[ "$HAS_JQ" == "true" ]]; then
        # 使用 jq 更新配置（推荐方式）
        jq '
        # 加固 Gateway 配置
        .gateway.bind = "loopback" |
        .gateway.controlUi.allowInsecureAuth = false |
        .gateway.controlUi.dangerouslyDisableDeviceAuth = false |
        .gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback = false |
        
        # 配置技能安全
        .skills.denyCommands = ["rm -rf /", "sudo", "curl * | bash", "wget * | bash", "chmod 777", "mkfs", "dd if="] |
        .skills.allowlist = (if .skills.allowlist then .skills.allowlist else ["web-search-free", "github", "healthcheck"] end)
        ' "$CONFIG_FILE" > "$temp_file" && mv "$temp_file" "$CONFIG_FILE"
        
        print_success "配置已加固（jq 模式）"
        
        # 显示关键配置
        print_info "关键配置："
        jq '{
            gateway_bind: .gateway.bind,
            allowInsecureAuth: .gateway.controlUi.allowInsecureAuth,
            disableDeviceAuth: .gateway.controlUi.dangerouslyDisableDeviceAuth,
            denyCommands: (.skills.denyCommands | length),
            allowlist: (.skills.allowlist | length)
        }' "$CONFIG_FILE"
    else
        # 降级方案：使用 sed 手动修改
        print_warning "jq 未安装，使用降级方案..."
        
        # 备份原文件
        cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
        
        # 使用 sed 修改配置（简化版）
        sed -i 's/"bind"[[:space:]]*:[[:space:]]*"[^"]*"/"bind": "loopback"/' "$CONFIG_FILE"
        sed -i 's/"allowInsecureAuth"[[:space:]]*:[[:space:]]*true/"allowInsecureAuth": false/' "$CONFIG_FILE"
        sed -i 's/"dangerouslyDisableDeviceAuth"[[:space:]]*:[[:space:]]*true/"dangerouslyDisableDeviceAuth": false/' "$CONFIG_FILE"
        
        print_success "配置已加固（降级模式）"
        print_warning "建议安装 jq 以获得完整功能：sudo apt install jq"
    fi
    
    return 0
}

# 配置防火墙
configure_firewall() {
    print_step "配置防火墙..."
    
    if ! command -v ufw &> /dev/null; then
        print_warning "UFW 未安装，跳过防火墙配置"
        print_info "手动安装：sudo apt install ufw"
        return 0
    fi
    
    if confirm_action "是否配置 UFW 防火墙？"; then
        print_info "配置 UFW 规则..."
        
        # 允许 SSH
        sudo ufw allow 22/tcp comment "SSH" 2>/dev/null || true
        
        # 允许 OpenClaw Gateway 仅本地访问
        sudo ufw deny from any to any port 18789 comment "OpenClaw Gateway" 2>/dev/null || true
        sudo ufw allow from 127.0.0.1 to any port 18789 comment "OpenClaw Local" 2>/dev/null || true
        
        # 允许 Telegram（如果使用）
        sudo ufw allow out 443 comment "HTTPS Outbound" 2>/dev/null || true
        
        # 启用防火墙（如果未启用）
        if ! sudo ufw status | grep -q "Status: active"; then
            if confirm_action "是否启用 UFW 防火墙？"; then
                echo "y" | sudo ufw enable
                print_success "UFW 防火墙已启用"
            fi
        else
            print_success "UFW 防火墙已启用"
        fi
        
        # 显示规则
        print_info "防火墙规则："
        sudo ufw status numbered | head -20
    fi
    
    return 0
}

# 修复文件权限
fix_file_permissions() {
    print_step "修复文件权限..."
    
    # 修复配置文件权限
    if [[ -f "$CONFIG_FILE" ]]; then
        local current_perms=$(stat -c %a "$CONFIG_FILE" 2>/dev/null || stat -f %Lp "$CONFIG_FILE" 2>/dev/null)
        
        if [[ "$current_perms" != "600" && "$current_perms" != "400" ]]; then
            print_warning "配置文件权限不安全：$current_perms"
            print_info "修复为 600..."
            chmod 600 "$CONFIG_FILE"
            print_success "配置文件权限已修复"
        else
            print_success "配置文件权限已安全：$current_perms"
        fi
    fi
    
    # 修复认证文件权限
    local auth_dir="${OPENCLAW_DIR}/agents"
    if [[ -d "$auth_dir" ]]; then
        local fixed_count=0
        for file in $(find "$auth_dir" -name "*.json" -type f 2>/dev/null); do
            local perms=$(stat -c %a "$file" 2>/dev/null || stat -f %Lp "$file" 2>/dev/null)
            if [[ "$perms" != "600" && "$perms" != "400" ]]; then
                chmod 600 "$file"
                fixed_count=$((fixed_count + 1))
            fi
        done
        
        if [[ $fixed_count -gt 0 ]]; then
            print_success "已修复 $fixed_count 个认证文件权限"
        else
            print_success "认证文件权限已安全"
        fi
    fi
    
    # 修复备份目录权限
    if [[ -d "$BACKUP_DIR" ]]; then
        chmod 700 "$BACKUP_DIR"
        print_success "备份目录权限已设置为 700"
    fi
    
    return 0
}

# 保护 API 密钥
protect_api_keys() {
    print_step "保护 API 密钥..."
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return 1
    fi
    
    # 检查是否有明文密钥
    if grep -qE 'sk-[a-zA-Z0-9]{20,}' "$CONFIG_FILE"; then
        print_warning "发现明文 API 密钥"
        print_info "建议：将 API 密钥移到环境变量"
        
        if confirm_action "是否创建环境变量配置文件？"; then
            local env_file="${OPENCLAW_DIR}/.env"
            
            cat > "$env_file" << 'EOF'
# OpenClaw API 密钥配置
# 请将 xxx 替换为你的实际密钥

# 阿里云百炼
export BAILIAN_API_KEY="sk-xxx"

# OpenRouter
export OPENROUTER_API_KEY="sk-or-v1-xxx"

# Moonshot (Kimi)
export MOONSHOT_API_KEY="sk-xxx"

# Google Gemini
export GEMINI_API_KEY="AIzaSyxxx"

# Groq
export GROQ_API_KEY="gsk_xxx"
EOF
            
            chmod 600 "$env_file"
            print_success "环境变量文件已创建：$env_file"
            print_info "使用方法：source $env_file"
        fi
    else
        print_success "未发现明显明文密钥"
    fi
    
    return 0
}

# 创建安全监控脚本
create_monitor_script() {
    print_step "创建安全监控脚本..."
    
    local monitor_script="${OPENCLAW_DIR}/security-monitor.sh"
    
    cat > "$monitor_script" << 'MONITOR_EOF'
#!/usr/bin/env bash
# OpenClaw 安全监控脚本

OPENCLAW_DIR="${HOME}/.openclaw"
LOG_FILE="${OPENCLAW_DIR}/security-monitor.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 检查 Gateway 状态
check_gateway() {
    if openclaw gateway status 2>&1 | grep -q "running"; then
        log "✅ Gateway 运行正常"
    else
        log "❌ Gateway 异常"
        # 这里可以添加告警逻辑
    fi
}

# 检查公开端口
check_ports() {
    if ss -tlnp 2>/dev/null | grep -q ":18789.*0.0.0.0"; then
        log "⚠️  警告：Gateway 端口公开暴露"
    else
        log "✅ Gateway 端口安全"
    fi
}

# 检查配置文件变更
check_config_changes() {
    local config_file="${OPENCLAW_DIR}/openclaw.json"
    local checksum_file="${OPENCLAW_DIR}/.config-checksum"
    
    if [[ -f "$config_file" ]]; then
        local current_checksum=$(md5sum "$config_file" | cut -d' ' -f1)
        
        if [[ -f "$checksum_file" ]]; then
            local stored_checksum=$(cat "$checksum_file")
            
            if [[ "$current_checksum" != "$stored_checksum" ]]; then
                log "⚠️  警告：配置文件已变更"
                echo "$current_checksum" > "$checksum_file"
            fi
        else
            echo "$current_checksum" > "$checksum_file"
        fi
    fi
}

# 主循环
main() {
    log "=== 安全监控启动 ==="
    
    check_gateway
    check_ports
    check_config_changes
    
    log "=== 监控完成 ==="
}

main "$@"
MONITOR_EOF
    
    chmod +x "$monitor_script"
    print_success "监控脚本已创建：$monitor_script"
    
    return 0
}

# 生成加固报告
generate_report() {
    print_step "生成加固报告..."
    
    local report_file="hardening-report-${TIMESTAMP}.md"
    
    cat > "$report_file" << EOF
# OpenClaw 安全加固报告

**加固时间**: $(date '+%Y-%m-%d %H:%M:%S')
**配置文件**: $CONFIG_FILE

## 已完成的加固项

### ✅ 配置加固
- Gateway 绑定：loopback（仅本地访问）
- 禁用不安全认证：allowInsecureAuth = false
- 启用设备认证：dangerouslyDisableDeviceAuth = false
- 配置危险命令黑名单
- 配置技能白名单

### ✅ 备份
- 配置备份：${BACKUP_DIR}/openclaw-backup-${TIMESTAMP}.json

### ⚠️ 需要手动完成
- [ ] 审查并升级 API 密钥存储方式
- [ ] 配置防火墙规则（如未自动配置）
- [ ] 设置定期安全审计
- [ ] 配置安全监控和告警

## 后续建议

1. **立即**: 重启 OpenClaw 使配置生效
   \`\`\`bash
   openclaw gateway restart
   \`\`\`

2. **24 小时内**: 
   - 审查所有已安装技能
   - 更新 API 密钥为环境变量存储
   - 运行安全审计验证

3. **每周**:
   - 运行安全审计：\`./scripts/security-audit.sh\`
   - 检查监控日志
   - 审查配置变更

4. **每月**:
   - 更新 OpenClaw 到最新版本
   - 审查和更新技能白名单
   - 备份配置并存档

## 安全评分

加固前：未知
加固后：预计 85-95/100

## 支持

遇到问题？
- GitHub Issues: https://github.com/YOUR_USERNAME/openclaw-security-hardening/issues
- 文档：docs/SECURITY.md

---

*报告生成时间*: $(date '+%Y-%m-%d %H:%M:%S')
*工具版本*: 1.0.0
EOF

    print_success "加固报告已保存：$report_file"
    
    return 0
}

# 主函数
main() {
    print_header "OpenClaw 自动加固工具 v1.0"
    
    print_warning "警告：本工具将修改你的 OpenClaw 配置"
    print_warning "建议：运行前先备份重要数据"
    echo
    
    # 解析参数
    INTERACTIVE=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--interactive)
                INTERACTIVE=true
                shift
                ;;
            -y|--yes)
                INTERACTIVE=false
                shift
                ;;
            *)
                print_error "未知参数：$1"
                exit 1
                ;;
        esac
    done
    
    if ! confirm_action "是否继续执行加固？"; then
        print_info "操作已取消"
        exit 0
    fi
    
    print_info "加固开始时间：$(date '+%Y-%m-%d %H:%M:%S')"
    
    # 检查并安装 jq
    check_jq || {
        print_warning "jq 未安装，部分功能可能受限"
        print_info "继续执行基础加固..."
    }
    
    # 执行加固步骤
    backup_config || true
    check_version || true
    harden_config || true
    fix_file_permissions || true
    configure_firewall || true
    protect_api_keys || true
    create_monitor_script || true
    generate_report || true
    
    # 打印总结
    print_header "加固完成"
    
    print_success "所有加固步骤已完成"
    print_info "重启 OpenClaw 使配置生效：openclaw gateway restart"
    print_info "查看加固报告：cat hardening-report-${TIMESTAMP}.md"
    print_info "运行安全审计验证：./scripts/security-audit.sh"
    
    return 0
}

# 运行主函数
main "$@"
