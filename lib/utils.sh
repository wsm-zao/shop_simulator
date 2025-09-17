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
# 4. 批量处理公共函数
get_batch_item_nums() {
    read -p "请输入商品编号（多个用空格分隔，0取消）: " -a input_nums
    
    # 检查是否包含0（取消操作）
    if [[ " ${input_nums[@]} " =~ " 0 " ]]; then
        return 1  # 取消
    fi
    
    # 检查输入是否为空
    if [ ${#input_nums[@]} -eq 0 ]; then
        return 2  # 无输入
    fi
    
    # 输出有效编号数组（供调用者处理）
    echo "${input_nums[@]}"
    return 0
}
# 5. 验证批量函数
validate_batch_items() {
    local input_nums=($1)
    local valid_items=()
    local has_invalid=0
    
    for num in "${input_nums[@]}"; do
        # 验证是否为正整数
        if ! is_positive_int "$num"; then
            echo "⚠️ 无效编号：$num（必须是正整数）" >&2  # 错误信息输出到stderr
            has_invalid=1
            continue
        fi
        
        # 验证编号范围
        local idx=$((num - 1))
        if [ $idx -lt 0 ] || [ $idx -ge ${#inventory[@]} ]; then
            echo "⚠️ 编号不存在：$num（超出范围）" >&2
            has_invalid=1
            continue
        fi
        
        # 提取商品信息（名称 数量 成本 售价）
        local item=(${inventory[$idx]})
        valid_items+=("$idx ${item[0]} ${item[2]} ${item[3]}")  # 索引 名称 成本 售价（分）
    done
    
    # 输出有效商品信息（供调用者解析）
    if [ ${#valid_items[@]} -gt 0 ]; then
        printf "%s\n" "${valid_items[@]}"
        return 0
    else
        return 1  # 无有效商品
    fi
}
