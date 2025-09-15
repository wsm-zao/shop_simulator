#!/bin/bash
# 模块：进货功能（逻辑不变，适配新库存结构）
buy_stock() {
    # 显示当前状态（清楚库存和资金）
    show_status
    echo "进货环节"
    echo "---------------------------------------------"

    # 1. 选择商品编号（0取消）
    read -p "请选择要进货的商品编号 (0取消): " item_num
    if [ "$item_num" -eq 0 ]; then
        return
    fi

    # 验证商品编号有效性
    local item_index=$((item_num - 1))
    if ! is_positive_int "$item_num" || [ $item_index -lt 0 ] || [ $item_index -ge ${#inventory[@]} ]; then
        echo "无效的商品编号!"
        sleep 2
        return
    fi

    # 2. 获取商品信息
    local item=(${inventory[$item_index]})
    local item_name=${item[0]}
    local item_cost=${item[2]}  # 成本价（分）
    echo "你选择了 ${item_name}, 成本价 $(to_yuan $item_cost) 元"

    # 3. 输入进货数量（正整数）
    read -p "请输入进货数量: " quantity
    if ! is_positive_int "$quantity"; then
        echo "请输入有效的正整数数量!"
        sleep 2
        return
    fi

    # 4. 计算成本并检查资金
    local total_cost=$((quantity * item_cost))
    if [ $total_cost -gt $money ]; then
        echo "资金不足! 需要 $(to_yuan $total_cost) 元, 但你只有 $(to_yuan $money) 元"
        sleep 2
        return
    fi

    # 5. 更新库存和资金
    local current_count=${item[1]}
    local new_count=$((current_count + quantity))
    inventory[$item_index]="${item_name} $new_count ${item_cost} ${item[3]}"  # 保留原售价
    money=$((money - total_cost))

    # 6. 提示结果
    echo "成功进货 ${item_name} $quantity 个, 花费 $(to_yuan $total_cost) 元"
    sleep 2
}
