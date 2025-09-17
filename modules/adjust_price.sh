#!/bin/bash
# 模块：调整售价（支持批量调整）
adjust_price() {
    # 显示当前状态（清楚当前售价）
    show_status
    echo "批量调整售价"
    echo "---------------------------------------------"

    # 1. 选择多个商品编号（用空格分隔，0取消）
    read -p "请输入要调整价格的商品编号（多个编号用空格分隔，0取消）: " -a item_nums
    # 检查是否包含0（取消操作）
    if [[ " ${item_nums[@]} " =~ " 0 " ]]; then
        echo "已取消调整售价"
        sleep 2
        return
    fi

    # 验证所有商品编号有效性，过滤无效编号
    local valid_items=()  # 存储有效商品信息：索引 名称 成本 当前售价
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
        valid_items+=("$idx ${item[0]} ${item[2]} ${item[3]}")  # 索引 名称 成本 当前售价（分）
    done

    # 若存在无效编号或无有效商品，终止操作
    if [ $invalid -eq 1 ] || [ ${#valid_items[@]} -eq 0 ]; then
        echo "批量调整失败，请重新选择"
        sleep 2
        return
    fi

    # 2. 为每个有效商品输入新售价并更新
    echo -e "\n请为以下商品设置新售价（需高于成本价）："
    for item_info in "${valid_items[@]}"; do
        local idx=$(echo $item_info | cut -d' ' -f1)
        local name=$(echo $item_info | cut -d' ' -f2)
        local cost=$(echo $item_info | cut -d' ' -f3)
        local current_price=$(echo $item_info | cut -d' ' -f4)

        # 显示当前商品信息
        echo -e "\n������ ${name}"
        echo "   当前售价: $(to_yuan $current_price) 元 | 成本价: $(to_yuan $cost) 元"

        # 输入并验证新售价
        while true; do
            read -p "   请输入新售价（元，例如3.50）: " new_price_str
            local new_price=$(validate_price "$new_price_str")
            if [ $? -ne 0 ]; then
                echo "   ❌ 无效格式，请输入类似3.50的价格"
                continue
            fi
            if [ $new_price -le $cost ]; then
                echo "   ❌ 新售价必须高于成本价 $(to_yuan $cost) 元"
                continue
            fi
            break  # 验证通过
        done

        # 3. 更新该商品售价
        local item=(${inventory[$idx]})
        inventory[$idx]="${item[0]} ${item[1]} ${cost} $new_price"
        echo "   ✅ 已更新为 $(to_yuan $new_price) 元"
    done

    # 4. 批量操作总结
    echo -e "\n������ 批量调整完成，共更新 ${#valid_items[@]} 个商品的售价"
    sleep 3
}
