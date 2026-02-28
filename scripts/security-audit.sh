#!/usr/bin/env bash

##############################################
# OpenClaw 安全审计脚本
# 
# 功能：检测 OpenClaw 实例的安全风险
# 输出：详细的安全审计报告
##############################################

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
OPENCLAW_DIR="${HOME}/.openclaw"
REPORT_FILE="security-audit-report-$(date +%Y%m%d-%H%M%S).md"
SCORE=100

# 打印函数
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_critical() {
    echo -e "${RED}[🔴 严重]${NC} $1"
}

print_high() {
    echo -e "${ORANGE}[🟠 高]${NC} $1"
}

print_medium() {
    echo -e "${YELLOW}[🟡 中]${NC} $1"
}

print_low() {
    echo -e "${GREEN}[🟢 低]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ️  信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✅ 通过]${NC} $1"
}

# 检查 jq 是否安装
check_jq() {
    if ! command -v jq &> /dev/null; then
        print_warning "jq 未安装，部分检查可能受限"
        print_info "安装 jq 可获得更详细的审计报告"
        print_info "Ubuntu/Debian: sudo apt install jq"
        print_info "macOS: brew install jq"
        return 1
    fi
    return 0
}

# 检查 OpenClaw 是否安装
check_openclaw_installed() {
    print_info "检查 OpenClaw 安装..."
    
    if ! command -v openclaw &> /dev/null; then
        print_critical "OpenClaw 未安装"
        SCORE=$((SCORE - 20))
        return 1
    fi
    
    print_success "OpenClaw 已安装"
    return 0
}

# 检查 OpenClaw 版本
check_openclaw_version() {
    print_info "检查 OpenClaw 版本..."
    
    local version=$(openclaw --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1)
    local min_safe_version="2026.1.29"
    
    if [[ -z "$version" ]]; then
        print_critical "无法获取 OpenClaw 版本"
        SCORE=$((SCORE - 15))
        return 1
    fi
    
    print_info "当前版本：$version"
    
    # 版本比较（简化版）
    if [[ "$version" < "$min_safe_version" ]]; then
        print_critical "版本过旧（<$min_safe_version），易受 CVE-2026-25253 攻击"
        print_info "建议：运行 'openclaw update' 升级"
        SCORE=$((SCORE - 15))
        return 1
    fi
    
    print_success "版本安全（≥$min_safe_version）"
    return 0
}

# 检查 CVE-2026-25253
check_cve_2026_25253() {
    print_header "CVE-2026-25253 检查"
    
    # 检查配置文件
    local config_file="${OPENCLAW_DIR}/openclaw.json"
    
    if [[ ! -f "$config_file" ]]; then
        print_critical "配置文件不存在：$config_file"
        SCORE=$((SCORE - 20))
        return 1
    fi
    
    # 检查是否允许不安全认证
    local allow_insecure=$(jq -r '.gateway.controlUi.allowInsecureAuth // false' "$config_file" 2>/dev/null || echo "false")
    local disable_device_auth=$(jq -r '.gateway.controlUi.dangerouslyDisableDeviceAuth // false' "$config_file" 2>/dev/null || echo "false")
    
    if [[ "$allow_insecure" == "true" ]]; then
        print_critical "配置风险：allowInsecureAuth = true"
        print_info "这会使你易受 WebSocket 劫持攻击"
        SCORE=$((SCORE - 20))
    else
        print_success "allowInsecureAuth = false"
    fi
    
    if [[ "$disable_device_auth" == "true" ]]; then
        print_high "配置风险：dangerouslyDisableDeviceAuth = true"
        print_info "设备身份验证已禁用"
        SCORE=$((SCORE - 10))
    else
        print_success "dangerouslyDisableDeviceAuth = false"
    fi
    
    return 0
}

# 检查 Gateway 暴露
check_gateway_exposure() {
    print_header "Gateway 暴露检查"
    
    local config_file="${OPENCLAW_DIR}/openclaw.json"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    # 检查绑定地址
    local bind=$(jq -r '.gateway.bind // "loopback"' "$config_file" 2>/dev/null || echo "loopback")
    local port=$(jq -r '.gateway.port // 18789' "$config_file" 2>/dev/null || echo "18789")
    
    print_info "Gateway 配置：bind=$bind, port=$port"
    
    if [[ "$bind" == "0.0.0.0" || "$bind" == "any" || "$bind" == "lan" ]]; then
        print_critical "Gateway 暴露在非本地网络"
        print_info "风险：未授权访问和配置泄露"
        print_info "建议：设置 gateway.bind = \"loopback\""
        SCORE=$((SCORE - 25))
    elif [[ "$bind" == "loopback" || "$bind" == "localhost" || "$bind" == "127.0.0.1" ]]; then
        print_success "Gateway 仅本地访问"
    else
        print_medium "Gateway 绑定配置：$bind"
        SCORE=$((SCORE - 5))
    fi
    
    # 检查端口是否公开监听
    if command -v ss &> /dev/null; then
        if ss -tlnp 2>/dev/null | grep -q ":$port "; then
            print_info "端口 $port 正在监听"
        fi
    fi
    
    return 0
}

# 检查 API 密钥安全
check_api_keys() {
    print_header "API 密钥安全检查"
    
    local config_file="${OPENCLAW_DIR}/openclaw.json"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    # 检查是否有明文 API 密钥
    local has_plaintext_keys=false
    
    # 检查常见 API 密钥模式
    if grep -qE 'sk-[a-zA-Z0-9]{20,}' "$config_file" 2>/dev/null; then
        has_plaintext_keys=true
    fi
    
    if grep -qE 'AIzaSy[A-Za-z0-9_-]{33}' "$config_file" 2>/dev/null; then
        has_plaintext_keys=true
    fi
    
    if [[ "$has_plaintext_keys" == "true" ]]; then
        print_high "发现明文 API 密钥"
        print_info "风险：配置文件泄露导致密钥被盗"
        print_info "建议：使用环境变量存储 API 密钥"
        print_info "示例：export BAILIAN_API_KEY=\"sk-xxx\""
        SCORE=$((SCORE - 15))
    else
        print_success "未发现明显明文密钥"
    fi
    
    return 0
}

# 检查技能配置
check_skills_config() {
    print_header "技能配置检查"
    
    local config_file="${OPENCLAW_DIR}/openclaw.json"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    # 检查技能白名单
    local has_allowlist=$(jq -r '.skills.allowlist // empty' "$config_file" 2>/dev/null)
    
    if [[ -z "$has_allowlist" ]]; then
        print_medium "未配置技能白名单"
        print_info "建议：配置 skills.allowlist 限制可安装技能"
        SCORE=$((SCORE - 10))
    else
        print_success "已配置技能白名单"
        print_info "允许的技能：$(jq -r '.skills.allowlist | join(", ")' "$config_file")"
    fi
    
    # 检查危险命令黑名单
    local has_deny_commands=$(jq -r '.skills.denyCommands // empty' "$config_file" 2>/dev/null)
    
    if [[ -z "$has_deny_commands" ]]; then
        print_medium "未配置危险命令黑名单"
        print_info "建议：配置 skills.denyCommands 阻止危险命令"
        SCORE=$((SCORE - 5))
    else
        print_success "已配置危险命令黑名单"
    fi
    
    return 0
}

# 检查防火墙配置
check_firewall() {
    print_header "防火墙配置检查"
    
    # 检查 UFW
    if command -v ufw &> /dev/null; then
        local ufw_status=$(ufw status 2>&1 | head -1)
        if [[ "$ufw_status" == *"active"* ]]; then
            print_success "UFW 防火墙已启用"
            print_info "状态：$ufw_status"
        else
            print_medium "UFW 防火墙未启用"
            print_info "建议：运行 'sudo ufw enable'"
            SCORE=$((SCORE - 10))
        fi
    else
        print_info "UFW 未安装（可选）"
    fi
    
    # 检查 iptables
    if command -v iptables &> /dev/null; then
        local rules_count=$(iptables -L 2>/dev/null | wc -l)
        if [[ $rules_count -gt 10 ]]; then
            print_success "iptables 已配置规则"
        else
            print_info "iptables 规则较少（可选配置）"
        fi
    fi
    
    return 0
}

# 检查 SSRF 保护
check_ssrf_protection() {
    print_header "SSRF 保护检查"
    
    local config_file="${OPENCLAW_DIR}/openclaw.json"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    # 检查 SSRF 保护配置（v2026.2.13+）
    if command -v jq &> /dev/null; then
        local ssrf_enabled=$(jq -r '.gateway.ssrfProtection // false' "$config_file" 2>/dev/null)
        
        if [[ "$ssrf_enabled" == "true" ]]; then
            print_success "SSRF 保护已启用"
        else
            print_medium "SSRF 保护未配置"
            print_info "建议：升级 OpenClaw 到 v2026.2.13+ 并配置 SSRF 保护"
            SCORE=$((SCORE - 10))
        fi
    else
        print_info "jq 未安装，跳过 SSRF 检查"
    fi
    
    return 0
}

# 检查文件权限
check_file_permissions() {
    print_header "文件权限检查"
    
    local config_file="${OPENCLAW_DIR}/openclaw.json"
    local auth_dir="${OPENCLAW_DIR}/agents"
    
    # 检查配置文件权限
    if [[ -f "$config_file" ]]; then
        local perms=$(stat -c %a "$config_file" 2>/dev/null || stat -f %Lp "$config_file" 2>/dev/null)
        
        if [[ "$perms" == "600" || "$perms" == "400" ]]; then
            print_success "配置文件权限安全：$perms"
        else
            print_high "配置文件权限不安全：$perms（应为 600）"
            print_info "修复：chmod 600 $config_file"
            SCORE=$((SCORE - 15))
        fi
    fi
    
    # 检查认证文件权限
    if [[ -d "$auth_dir" ]]; then
        local auth_files=$(find "$auth_dir" -name "*.json" -type f 2>/dev/null)
        local insecure_count=0
        
        for file in $auth_files; do
            local perms=$(stat -c %a "$file" 2>/dev/null || stat -f %Lp "$file" 2>/dev/null)
            if [[ "$perms" != "600" && "$perms" != "400" ]]; then
                insecure_count=$((insecure_count + 1))
            fi
        done
        
        if [[ $insecure_count -gt 0 ]]; then
            print_high "发现 $insecure_count 个认证文件权限不安全"
            print_info "修复：find ~/.openclaw/agents -name '*.json' -exec chmod 600 {} \\;"
            SCORE=$((SCORE - 10))
        else
            print_success "认证文件权限安全"
        fi
    fi
    
    return 0
}

# 检查配置备份
check_backup() {
    print_header "配置备份检查"
    
    local backup_dir="${OPENCLAW_DIR}/backup"
    
    if [[ -d "$backup_dir" ]]; then
        local backup_count=$(ls -1 "$backup_dir"/*.json 2>/dev/null | wc -l)
        if [[ $backup_count -gt 0 ]]; then
            print_success "发现 $backup_count 个配置备份"
            local latest=$(ls -t "$backup_dir"/*.json 2>/dev/null | head -1)
            print_info "最新备份：$(basename "$latest")"
        else
            print_medium "备份目录存在但无备份文件"
            SCORE=$((SCORE - 5))
        fi
    else
        print_medium "未找到备份目录"
        print_info "建议：定期备份 ~/.openclaw 配置"
        SCORE=$((SCORE - 5))
    fi
    
    return 0
}

# 生成报告
generate_report() {
    print_header "生成审计报告"
    
    cat > "$REPORT_FILE" << EOF
# OpenClaw 安全审计报告

**审计时间**: $(date '+%Y-%m-%d %H:%M:%S')
**OpenClaw 目录**: $OPENCLAW_DIR
**安全评分**: $SCORE/100

## 评分标准

- **90-100**: 🟢 优秀 - 安全性良好
- **70-89**: 🟡 良好 - 需要少量改进
- **50-69**: 🟠 中等 - 需要改进
- **0-49**: 🔴 危险 - 需要立即加固

## 检查结果

**评分**: $SCORE/100

$(if [[ $SCORE -ge 90 ]]; then
    echo "✅ 安全性优秀！继续保持良好实践。"
elif [[ $SCORE -ge 70 ]]; then
    echo "⚠️  安全性良好，建议修复中等风险项。"
elif [[ $SCORE -ge 50 ]]; then
    echo "🚨 安全性中等，建议尽快加固。"
else
    echo "🔴 安全性危险！请立即运行加固脚本！"
fi)

## 建议操作

1. **立即**: 运行 \`./scripts/auto-harden.sh\` 自动加固
2. **短期**: 审查所有配置和权限
3. **长期**: 定期运行安全审计

---

*报告生成时间*: $(date '+%Y-%m-%d %H:%M:%S')
*工具版本*: 1.0.0
EOF

    print_success "审计报告已保存：$REPORT_FILE"
    print_info "查看报告：cat $REPORT_FILE"
    
    return 0
}

# 主函数
main() {
    print_header "OpenClaw 安全审计工具 v1.0"
    
    print_info "审计开始时间：$(date '+%Y-%m-%d %H:%M:%S')"
    print_info "OpenClaw 目录：$OPENCLAW_DIR"
    
    # 检查 jq
    check_jq || true
    
    # 执行检查
    check_openclaw_installed || true
    check_openclaw_version || true
    check_cve_2026_25253 || true
    check_gateway_exposure || true
    check_api_keys || true
    check_skills_config || true
    check_ssrf_protection || true
    check_file_permissions || true
    check_firewall || true
    check_backup || true
    
    # 生成报告
    generate_report
    
    # 打印总结
    print_header "审计总结"
    print_info "安全评分：$SCORE/100"
    
    if [[ $SCORE -ge 90 ]]; then
        print_success "安全性优秀！"
    elif [[ $SCORE -ge 70 ]]; then
        print_medium "安全性良好，建议改进"
    elif [[ $SCORE -ge 50 ]]; then
        print_high "安全性中等，建议尽快加固"
    else
        print_critical "安全性危险！请立即加固！"
        print_info "运行：./scripts/auto-harden.sh"
    fi
    
    print_info "\n详细报告：$REPORT_FILE"
    
    return 0
}

# 运行主函数
main "$@"
