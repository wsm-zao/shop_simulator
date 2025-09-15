#!/bin/bash
# 模块：显示当日状态（含库存、资金、天数）
show_status() {
    # 清空屏幕，显示标题
    clear
    echo "============================================="
    echo "            小商店经营模拟器 - 第 $day 天"
    echo "============================================="
    echo "当前资金: $(to_yuan $money) 元"
    echo "每日房租固定开销: $(to_yuan $daily_expense) 元"
    echo "已解锁商品: ${#unlocked_products[@]} 种（${unlocked_products[*]:-无}）"
    echo "---------------------------------------------"

    # 显示库存表头
    echo "库存清单:"
    echo "编号 | 商品 | 数量 | 成本价 | 售价"
    echo "---------------------------------------------"

    # 遍历库存，显示每个商品详情
    for i in "${!inventory[@]}"; do
        item=(${inventory[$i]})
        item_name=${item[0]}
        item_count=${item[1]}
        item_cost=${item[2]}
        item_price=${item[3]}
        # 格式化输出（编号从1开始）
        echo "$((i+1)) | ${item_name} | ${item_count} | $(to_yuan ${item_cost})元 | $(to_yuan ${item_price})元"
    done

    echo "============================================="
}
