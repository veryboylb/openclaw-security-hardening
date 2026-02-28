#!/usr/bin/env bash
# JSON 处理辅助函数（无 jq 降级方案）

# 简单的 JSON 值提取（仅支持简单键值对）
json_get() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed "s/\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\"/\1/" | head -1
}

# 简单的 JSON 布尔值提取
json_get_bool() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*[a-z]*" | sed "s/\"$key\"[[:space:]]*:[[:space:]]*//" | head -1
}

# 简单的 JSON 数组提取
json_get_array() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\[[^]]*\]" | sed "s/\"$key\"[[:space:]]*:[[:space:]]*//" | head -1
}
