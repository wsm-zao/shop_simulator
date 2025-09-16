#!/bin/bash
# 模块：游戏结束处理（新增成就判定，整合商品解锁检查）
# 第一步：检查游戏结束条件（亏损/成就/解锁商品）
check_game_over() {
    # 计算当前总营收（最终资金-初始100元）
    local current_revenue=$(( money - 10000 ))

    # 条件1：达成成就
    if [ $day -le 10 ] && [ $current_revenue -ge $target_basic ] && [ -z "$achievement" ]; then
        achievement="经营合格"
        echo "�� 10天内达成基础目标（营收≥500元）！成就：${achievement}"
        read -p "是否继续游戏冲击更高成就？(y继续/n退出): " choice
        if [[ $choice == "y" || $choice == "Y" ]]; then
            echo "继续经营，冲击下一成就！"
            sleep 2
            return  # 不结束游戏，返回主循环
        else
            game_over=1  # 玩家选择退出
            return
        fi
    elif [ $day -le 15 ] && [ $current_revenue -ge $target_advanced ] && [ "$achievement" != "商业大亨" ] && [ "$achievement" != "经营达人" ]; then
        achievement="经营达人"
        echo "�� 15天内达成进阶目标（营收≥1000元）！成就：${achievement}"
        read -p "是否继续游戏冲击终极成就？(y继续/n退出): " choice
        if [[ $choice == "y" || $choice == "Y" ]]; then
            echo "继续经营，冲击商业大亨！"
            sleep 2
            return
        else
            game_over=1
            return
        fi
    elif [ $day -le 20 ] && [ $current_revenue -ge $target_ultimate ] && [ "$achievement" != "商业大亨" ]; then
        achievement="商业大亨"
        echo "�� 20天内达成终极目标（营收≥2000元）！成就：${achievement}"
        read -p "已达成最高成就，是否结束游戏？(y退出/n继续): " choice
        if [[ $choice == "y" || $choice == "Y" ]]; then
            game_over=1
            return
        else
            echo "继续经营，挑战更高记录！"
            sleep 2
            return
        fi
    fi
    # 条件3：连续3天亏损（经营失败）
    if [ $after_tax_profit -lt 0 ]; then
        consecutive_loss_days=$(( consecutive_loss_days + 1 ))
        echo "⚠️  已连续${consecutive_loss_days}天亏损（再亏$((3-consecutive_loss_days))天经营失败）"
        if [ $consecutive_loss_days -ge 3 ]; then
            echo "<d83d><dc80> 连续3天亏损，经营失败！"
            sleep 3
            game_over=1
            return
        fi
    else
        consecutive_loss_days=0  # 有盈利则重置
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
	    echo "   - 20天内未达成任何成就"
        else
            echo "   - 很遗憾您未解锁成就称号，请下次努力"
        fi
        echo "�� 建议：多关注市场指导价，盈利超50元时注意税款影响！"
    fi
    echo "============================================="
    read -p "按回车键退出游戏..."
}
