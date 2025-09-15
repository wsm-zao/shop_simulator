#!/bin/bash
# 工具函数库 - 通用辅助功能
# 1. 分转元（保留2位小数）
to_yuan() {
    local cents=$1
    # 处理非整数输入
    if ! [[ $cents =~ ^[0-9]+$ ]]; then
        echo "0.00"
        return
    fi
    # 计算元、分并补零
    local yuan=$((cents / 100))
    local fen=$((cents % 100))
    [[ $fen -lt 10 ]] && fen="0$fen"
    echo "${yuan}.${fen}"
}

# 2. 验证输入是否为正整数（1、10，排除0、负数、小数）
is_positive_int() {
    local input=$1
    if [[ $input =~ ^[1-9][0-9]*$ ]]; then
        return 0  # 有效
    else
        return 1  # 无效
    fi
}

# 3. 验证价格格式（支持整数如10、小数如3.50，转换为分）
validate_price() {
    local price_str=$1
    # 正则匹配：整数或1-2位小数
    if [[ $price_str =~ ^([0-9]+)(\.([0-9]{1,2}))?$ ]]; then
        local yuan=${BASH_REMATCH[1]}
        local fen=${BASH_REMATCH[3]:-00}  # 无小数则默认为00分
        [[ ${#fen} -eq 1 ]] && fen="${fen}0"  # 补零（如5.2→20分）
        echo $((yuan * 100 + fen))  # 输出转换后的“分”
        return 0
    else
        return 1  # 格式无效
    fi
}
