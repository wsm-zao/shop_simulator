#!/bin/bash
# 模块：进货功能（支持批量进货）
buy_stock() {
    # 显示当前状态（清楚库存和资金）
    show_status
    echo "批量进货环节"
    echo "---------------------------------------------"

    # 1. 选择多个商品编号（用空格分隔，0取消）
    read -p "请输入要进货的商品编号（多个编号用空格分隔，0取消）: " -a item_nums
    # 检查是否包含0（取消操作）
    if [[ " ${item_nums[@]} " =~ " 0 " ]]; then
        echo "已取消进货"
        sleep 2
        return
    fi

    # 验证所有商品编号有效性，过滤无效编号
    local valid_items=()  # 存储有效商品信息：索引 名称 成本
    local invalid=0
    for num in "${item_nums[@]}"; do
        if ! is_positive_int "$num"; then
            echo "⚠️ 无效的商品编号：$num（必须是正整数）"
            invalid=1
            continue
        fi
        local idx=$((num - 1))
        if [ $idx -lt 0 ] || [ $idx -ge ${#inventory[@]} ]; then
            echo "⚠️ 商品编号不存在：$num（超出范围）"
            invalid=1
            continue
        fi
        # 提取商品信息
        local item=(${inventory[$idx]})
        valid_items+=("$idx ${item[0]} ${item[2]}")  # 索引 名称 成本（分）
    done

    # 若存在无效编号，终止操作
    if [ $invalid -eq 1 ] || [ ${#valid_items[@]} -eq 0 ]; then
        echo "批量进货失败，请重新选择"
        sleep 2
        return
    fi

    # 2. 为每个有效商品输入进货数量，计算总成本
    local total_cost=0
    local purchase_list=()  # 存储待进货信息：索引 原数量 新增数量
    echo -e "\n请为以下商品输入进货数量："
    for item_info in "${valid_items[@]}"; do
        local idx=$(echo $item_info | cut -d' ' -f1)
        local name=$(echo $item_info | cut -d' ' -f2)
        local cost=$(echo $item_info | cut -d' ' -f3)
        local current_qty=$(echo ${inventory[$idx]} | cut -d' ' -f2)

        # 输入并验证数量
        while true; do
            read -p "������ ${name}（成本价 $(to_yuan $cost) 元）的进货数量：" qty
            if is_positive_int "$qty"; then
                break
            else
                echo "❌ 请输入有效的正整数数量"
            fi
        done

        # 累计成本
        local item_cost=$((qty * cost))
        total_cost=$((total_cost + item_cost))
        purchase_list+=("$idx $current_qty $qty")

        # 实时显示累计花费
        echo "   已选：${name} $qty个，累计花费：$(to_yuan $total_cost)元"
    done

    # 3. 检查资金是否充足
    if [ $total_cost -gt $money ]; then
        echo -e "\n❌ 资金不足！需要 $(to_yuan $total_cost) 元，当前仅有 $(to_yuan $money) 元"
        sleep 2
        return
    fi

    # 4. 批量更新库存和资金
    for purchase in "${purchase_list[@]}"; do
        local idx=$(echo $purchase | cut -d' ' -f1)
        local old_qty=$(echo $purchase | cut -d' ' -f2)
        local add_qty=$(echo $purchase | cut -d' ' -f3)
        local new_qty=$((old_qty + add_qty))
        # 更新库存（保留名称、成本、售价）
        local item=(${inventory[$idx]})
        inventory[$idx]="${item[0]} $new_qty ${item[2]} ${item[3]}"
        # 显示单个商品进货结果
        echo "✅ 已进货 ${item[0]} $add_qty 个，库存变为 $new_qty 个"
    done

    # 扣除总资金
    money=$((money - total_cost))
    echo -e "\n������ 批量进货完成，总花费 $(to_yuan $total_cost) 元，剩余资金 $(to_yuan $money) 元"
    sleep 3
}
