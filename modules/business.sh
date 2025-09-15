#!/bin/bash
# 模块：营业逻辑（整合市场价、阶梯税率新功能）
run_business() {
    # 第一步：显示当前状态，生成今日市场价
    show_status
    generate_market_prices  # 新增：生成每日市场价
    echo "今日营业"
    echo "---------------------------------------------"

    # 初始化营业参数
    local daily_sales=0    # 当日总销售额（分）
    total_profit=0         # 当日税前利润（分）
    after_tax_profit=0     # 当日税后利润（分）
    local event_occurred=0 # 随机事件标记
    local event_multiplier=100  # 销量乘数（100=1倍）
    local profit_reduction=0    # 利润扣除比例（特价促销用）

    # 第二步：触发随机事件（保留原逻辑，优化提示）
    local random_event=$(( RANDOM % 10 ))
    case $random_event in
        0|1)  # 20%概率：下雨（销量×0.5）
            echo "������️  今日下雨，顾客减少！销量×0.5"
            event_multiplier=50
            event_occurred=1
            ;;
        2|3)  # 20%概率：集市（销量×1.5）
            echo "������ 今日有集市活动，顾客增多！销量×1.5"
            event_multiplier=150
            event_occurred=1
            ;;
        4)  # 10%概率：特价促销（销量×1.8，利润×0.8）
            echo "������ 今日特价促销！销量×1.8，利润×0.8"
            event_multiplier=180
            profit_reduction=20
            event_occurred=1
            ;;
        5)  # 10%概率：部分商品缺货（仅提示）
            echo "������ 供应商通知：部分商品今日无法进货！"
            local shortage_item=$(( RANDOM % ${#inventory[@]} ))
            local short_item=(${inventory[$shortage_item]})
            echo "❌ ${short_item[0]} 今日缺货"
            event_occurred=1
            ;;
        6)  # 10%概率：成本上涨10%
            echo "������ 今日部分商品成本上涨10%！"
            for ((i=0; i<2; i++)); do
                local rise_idx=$(( RANDOM % ${#inventory[@]} ))
                local rise_item=(${inventory[$rise_idx]})
                local new_cost=$(( rise_item[2] * 110 / 100 ))  # 成本+10%
                inventory[$rise_idx]="${rise_item[0]} ${rise_item[1]} $new_cost ${rise_item[3]}"
                echo "⚠️  ${rise_item[0]} 成本→$(to_yuan $new_cost)元"
            done
            event_occurred=1
            ;;
        7)  # 10%概率：意外账单（房租+3~7元）
            local bill=$(( (RANDOM % 5 + 3) * 100 ))  # 3~7元=300~700分
            echo "������ 收到意外账单：$(to_yuan $bill)元（今日房租增加）"
            daily_expense=$(( daily_expense + bill ))
            event_occurred=1
            ;;
        8)  # 10%概率：匿名捐款（+2~5元）
            local donation=$(( (RANDOM % 4 + 2) * 100 ))  # 2~5元=200~500分
            echo "������ 收到匿名捐款：$(to_yuan $donation)元（直接计入资金）"
            money=$(( money + donation ))
            event_occurred=1
            ;;
        *)  # 20%概率：无事件
            echo "☀️  今日营业正常，无特殊事件"
            ;;
    esac
    [ $event_occurred -eq 1 ] && echo "---------------------------------------------"

    # 第三步：销售计算（核心修改：关联市场价调整销量）
    for i in "${!inventory[@]}"; do
        item=(${inventory[$i]})
        item_name=${item[0]}
        item_count=${item[1]}  # 库存数量
        item_cost=${item[2]}   # 成本价（分）
        item_price=${item[3]}  # 玩家售价（分）

        # 无库存则跳过
        if [ $item_count -eq 0 ]; then
            echo "❌ ${item_name}：库存为0，无法销售"
            continue
        fi

        # 1. 获取该商品今日市场价
        local market_price=0
        for mp in "${daily_market_prices[@]}"; do
            local mp_name=${mp% *}
            local mp_val=${mp#* }
            if [ "$mp_name" = "$item_name" ]; then
                market_price=$mp_val
                break
            fi
        done

        # 2. 按“玩家售价 vs 市场价”调整销量比例
        local price_ratio=100  # 销量比例（100=1倍）
        if [ $item_price -gt $market_price ]; then
            price_ratio=50  # 售价＞市场价：销量×0.5
            echo -n "������ ${item_name}（售价高于市场价）："
        elif [ $item_price -eq $market_price ]; then
            price_ratio=100  # 售价=市场价：销量×1
            echo -n "✅ ${item_name}（售价等于市场价）："
        else
            price_ratio=150  # 售价＜市场价：销量×1.5
            echo -n "������ ${item_name}（售价低于市场价）："
        fi

        # 3. 计算最终销量（基础需求×事件乘数×价格比例×随机波动）
        local base_demand=$(( (10000 / item_price) / 20 + 1 ))  # 基础需求（价格越低需求越高）
        local adjusted_demand=$(( (base_demand * event_multiplier * price_ratio) / 10000 ))  # 综合调整
        [ $adjusted_demand -eq 0 ] && adjusted_demand=1  # 至少1个需求
        local random_factor=$(( RANDOM % 3 + 1 ))  # 1~3倍随机波动
        local possible_sales=$(( adjusted_demand * random_factor ))

        # 4. 实际销量不超过库存
        local sales=$(( possible_sales > item_count ? item_count : possible_sales ))

        # 5. 计算单商品税前利润
        local item_revenue=$(( sales * item_price ))  # 收入
        local item_profit=$(( item_revenue - (sales * item_cost) ))  # 利润
        [ $random_event -eq 4 ] && item_profit=$(( item_profit * 80 / 100 ))  # 特价促销扣20%利润

        # 6. 累计数据，更新库存
        daily_sales=$(( daily_sales + item_revenue ))
        total_profit=$(( total_profit + item_profit ))
        local new_count=$(( item_count - sales ))
        inventory[$i]="${item_name} $new_count ${item_cost} ${item_price}"

        # 显示销售结果（标注盈利/亏损）
        if [ $item_profit -ge 0 ]; then
            echo "售出 $sales 个，收入$(to_yuan $item_revenue)元，利润$(to_yuan $item_profit)元"
        else
            echo -e "售出 $sales 个，收入$(to_yuan $item_revenue)元，亏损$(to_yuan $((-item_profit)))元"
        fi
    done

    # 第四步：计算阶梯税款（新增核心逻辑）
    local tax=0
    if [ $total_profit -gt 5000 ]; then  # 利润＞50元（5000分）才缴税
        if [ $total_profit -le 10000 ]; then
            tax=$(( total_profit * 10 / 100 ))  # 50~100元：10%税率
        elif [ $total_profit -le 20000 ]; then
            tax=$(( total_profit * 20 / 100 ))  # 100~200元：20%税率
        else
            tax=$(( total_profit * 30 / 100 ))  # ＞200元：30%税率
        fi
        echo "---------------------------------------------"
        echo "������ 今日税前利润：$(to_yuan $total_profit)元，需缴税：$(to_yuan $tax)元"
    else
        echo "---------------------------------------------"
        echo "������ 今日税前利润≤50元，免征税款"
    fi

    # 第五步：计算税后利润，更新资金
    after_tax_profit=$(( total_profit - tax - daily_expense ))  # 税后利润=税前-税款-房租
    money=$(( money + daily_sales - tax - daily_expense ))  # 资金=原有+销售额-税款-房租

    # 恢复房租（若有意外账单）
    [ $random_event -eq 7 ] && daily_expense=1000

    # 第六步：营业总结
    echo "---------------------------------------------"
    echo "������ 今日营业总结："
    echo "总销售额：$(to_yuan $daily_sales)元 | 税前利润：$(to_yuan $total_profit)元"
    echo "应缴税款：$(to_yuan $tax)元 | 房租开销：$(to_yuan $daily_expense)元"
    if [ $after_tax_profit -ge 0 ]; then
        echo -e "✅ 税后净利润：$(to_yuan $after_tax_profit)元"
    else
        echo -e "❌ 税后净亏损：$(to_yuan $((-after_tax_profit)))元"
    fi
    echo "---------------------------------------------"
    read -p "按回车键继续..."
}
