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

    # 新增：成就进度实时显示
    echo "成就进度："
    # 计算当前总营收（元）：(当前资金 - 初始资金100元) / 100
    current_revenue=$(( money - 10000 ))  # 单位：分
    current_revenue_yuan=$(to_yuan $current_revenue)

    # 1. 经营合格（10天内营收≥500元）
    if [ "$achievement" != "经营合格" ] && [ "$achievement" != "经营达人" ] && [ "$achievement" != "商业大亨" ] && [ $day -le 10 ]; then
        remaining_days=$((10 - day))
        target_basic_yuan=500
        needed=$(( target_basic - current_revenue ))  # 单位：分
        if [ $needed -le 0 ]; then
            echo "✅ 经营合格：已完成（10天内营收≥500元）"
        else
            needed_yuan=$(to_yuan $needed)
            echo "������ 经营合格：剩余 $remaining_days 天，还差 $needed_yuan 元（目标：10天内营收≥500元）"
        fi
    fi

    # 2. 经营达人（15天内营收≥1000元）
    if [ "$achievement" != "经营达人" ] && [ "$achievement" != "商业大亨" ] && [ $day -le 15 ]; then
        remaining_days=$((15 - day))
        target_advanced_yuan=1000
        needed=$(( target_advanced - current_revenue ))
        if [ $needed -le 0 ]; then
            echo "✅ 经营达人：已完成（15天内营收≥1000元）"
        else
            needed_yuan=$(to_yuan $needed)
            echo "������ 经营达人：剩余 $remaining_days 天，还差 $needed_yuan 元（目标：15天内营收≥1000元）"
        fi
    fi

    # 3. 商业大亨（20天内营收≥2000元）
    if [ "$achievement" != "商业大亨" ] && [ $day -le 20 ]; then
        remaining_days=$((20 - day))
        target_ultimate_yuan=2000
        needed=$(( target_ultimate - current_revenue ))
        if [ $needed -le 0 ]; then
            echo "✅ 商业大亨：已完成（20天内营收≥2000元）"
        else
            needed_yuan=$(to_yuan $needed)
            echo "������ 商业大亨：剩余 $remaining_days 天，还差 $needed_yuan 元（目标：20天内营收≥2000元）"
        fi
    fi
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
