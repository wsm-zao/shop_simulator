#!/bin/bash
# 模块：游戏结束处理（新增成就判定，整合商品解锁检查）
# 第一步：检查游戏结束条件（亏损/成就/解锁商品）
check_game_over() {
    # 计算当前总营收（最终资金-初始100元）
    local current_revenue=$(( money - 10000 ))

    # 条件1：资金不足以支付明日房租（经营失败）
    if [ $money -lt $daily_expense ]; then
        echo "�� 资金不足以支付明日房租（需$(to_yuan $daily_expense)元，仅有$(to_yuan $money)元）"
        echo "经营失败！"
        sleep 3
        game_over=1
        return
    fi

    # 条件2：连续3天亏损（经营失败）
    if [ $after_tax_profit -lt 0 ]; then
        consecutive_loss_days=$(( consecutive_loss_days + 1 ))
        echo "⚠️  已连续${consecutive_loss_days}天亏损（再亏$((3-consecutive_loss_days))天经营失败）"
        if [ $consecutive_loss_days -ge 3 ]; then
            echo "�� 连续3天亏损，经营失败！"
            sleep 3
            game_over=1
            return
        fi
    else
        consecutive_loss_days=0  # 有盈利则重置
    fi

    # 条件3：达成成就（提前结束，经营成功）
    if [ $day -le 10 ] && [ $current_revenue -ge $target_basic ]; then
        achievement="经营合格"
        echo "�� 10天内达成基础目标（营收≥500元）！成就：${achievement}"
        sleep 3
        game_over=1
        return
    elif [ $day -le 15 ] && [ $current_revenue -ge $target_advanced ]; then
        achievement="经营达人"
        echo "�� 15天内达成进阶目标（营收≥1000元）！成就：${achievement}"
        sleep 3
        game_over=1
        return
    elif [ $day -le 20 ] && [ $current_revenue -ge $target_ultimate ]; then
        achievement="商业大亨"
        echo "�� 20天内达成终极目标（营收≥2000元）！成就：${achievement}"
        sleep 3
        game_over=1
        return
    fi

    # 条件4：20天未达成任何成就（经营失败）
    if [ $day -ge 20 ]; then
        echo "�� 20天未达成基础目标（营收≥500元），经营失败！"
        sleep 3
        game_over=1
        return
    fi

    # 每日营业后检查商品解锁（新增逻辑）
    check_unlock_products
}

# 第二步：显示游戏结果（成就总结）
show_results() {
    clear
    echo "============================================="
    echo "            游戏结束 - 成就总结"
    echo "============================================="
    echo "经营天数：$day 天"
    echo "初始资金：100.00 元"
    echo "最终资金：$(to_yuan $money) 元"
    echo "总营收：$(to_yuan $(( money - 10000 ))) 元"
    echo "解锁商品：${#unlocked_products[@]} 种"
    [ ${#unlocked_products[@]} -gt 0 ] && echo "已解锁商品：${unlocked_products[*]}"
    echo "---------------------------------------------"

    # 成就详情展示
    if [ "$achievement" = "商业大亨" ]; then
        echo -e "�� 最终成就：商业大亨"
        echo "�� 恭喜！你是天生的商人！20天内营收突破2000元，精通市场博弈与成本控制！"
    elif [ "$achievement" = "经营达人" ]; then
        echo -e "�� 最终成就：经营达人"
        echo "�� 优秀！15天内营收突破1000元，你的经营策略已具备专业水准！"
    elif [ "$achievement" = "经营合格" ]; then
        echo -e "�� 最终成就：经营合格"
        echo "✅ 不错！10天内营收突破500元，基本经营能力达标，继续加油可冲击更高成就！"
    else
        echo -e "❌ 最终成就：未达成"
        echo "�� 失败原因分析："
        if [ $consecutive_loss_days -ge 3 ]; then
            echo "   - 连续3天亏损（需关注市场价波动，避免亏本销售）"
        elif [ $day -ge 20 ]; then
            echo "   - 20天未达成500元营收（需优化定价策略，优先解锁高利润商品）"
        else
            echo "   - 资金不足以支付房租（需控制成本，避免过度进货）"
        fi
        echo "�� 建议：多关注市场指导价，盈利超50元时注意税款影响！"
    fi
    echo "============================================="
    read -p "按回车键退出游戏..."
}
