#!/bin/bash
# 模块：调整售价（逻辑不变，适配新库存结构）
adjust_price() {
    # 显示当前状态（清楚当前售价）
    show_status
    echo "调整售价"
    echo "---------------------------------------------"

    # 1. 选择商品编号（0取消）
    read -p "请选择要调整价格的商品编号 (0取消): " item_num
    if [ "$item_num" -eq 0 ]; then
        return
    fi

    # 验证商品编号有效性
    local item_index=$((item_num - 1))
    if [ $item_index -lt 0 ] || [ $item_index -ge ${#inventory[@]} ]; then
        echo "无效的商品编号!"
        sleep 2
        return
    fi

    # 2. 获取商品当前信息
    local item=(${inventory[$item_index]})
    local item_name=${item[0]}
    local item_cost=${item[2]}  # 成本价（分）
    local current_price=${item[3]}  # 当前售价（分）
    echo "${item_name} 当前售价: $(to_yuan $current_price) 元, 成本价: $(to_yuan $item_cost) 元"

    # 3. 输入新售价（验证格式）
    read -p "请输入新售价（元，例如3.50）: " new_price_str
    local new_price=$(validate_price "$new_price_str")
    if [ $? -ne 0 ]; then
        echo "请输入有效的价格格式（如3.50）!"
        sleep 2
        return
    fi

    # 4. 验证新售价高于成本价（避免亏本定价）
    if [ $new_price -le $item_cost ]; then
        echo "新售价必须高于成本价 $(to_yuan $item_cost) 元!"
        sleep 2
        return
    fi

    # 5. 更新售价
    inventory[$item_index]="${item_name} ${item[1]} ${item_cost} $new_price"
    echo "${item_name} 售价已调整为 $(to_yuan $new_price) 元"
    sleep 2
}
