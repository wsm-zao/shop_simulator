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
# 4. 保存历史记录（限制最多20条）
save_history() {
    local history_file="$(dirname "$0")/history.csv"  # 历史文件路径
    local date=$(date "+%Y-%m-%d %H:%M")  # 记录日期时间
    local days=$day                       # 经营天数
    local final_money=$(to_yuan $money)   # 最终资金
    local revenue=$(to_yuan $((money - 10000)))  # 总营收
    local ach=$([ -z "$achievement" ] && echo "未达成" || echo "$achievement")  # 成就
    local unlock_count=${#unlocked_products[@]}  # 解锁商品数
    local unlock_list=${unlocked_products[*]:-无}  # 解锁商品列表

    # 步骤1：检查当前记录数量（排除表头）
    if [ -f "$history_file" ]; then
        # 获取数据行数（总行数-1行表头）
        local line_count=$(wc -l < "$history_file")
        local data_count=$((line_count - 1))  # 实际记录数

        # 步骤2：若记录数≥20，保留最近19条（删除最早的1条）
        if [ $data_count -ge 20 ]; then
            # 创建临时文件存储表头+最近19条记录
            local temp_file=$(mktemp)
            # 保留表头（第1行）和最后19条数据
            head -n 1 "$history_file" > "$temp_file"  # 表头
            tail -n 19 "$history_file" >> "$temp_file"  # 最近19条记录
            # 用临时文件替换原文件（保持权限）
            mv "$temp_file" "$history_file"
        fi
    fi

    # 步骤3：追加新记录
    echo "${date},${days},${final_money},${revenue},${ach},${unlock_count},${unlock_list}" >> "$history_file"
}
