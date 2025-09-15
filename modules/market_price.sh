#!/bin/bash
# 模块：每日市场价格生成（新增核心功能）
# 功能：营业前为每种商品生成市场价（成本价±30%浮动）
generate_market_prices() {
    daily_market_prices=()  # 清空昨日市场价
    echo "�� 今日市场指导价生成中（成本价±30%浮动）..."
    echo "---------------------------------------------"

    # 为每种商品生成市场价
    for i in "${!inventory[@]}"; do
        item=(${inventory[$i]})
        item_name=${item[0]}
        item_cost=${item[2]}  # 商品成本价（分）

        # 市场价计算：成本价×(70%~130%)，取整数
        local random_ratio=$(( RANDOM % 61 + 70 ))  # 70~130的随机数（±30%）
        local market_price=$(( item_cost * random_ratio / 100 ))

        # 极端情况防护（确保市场价≥1分）
        if [ $market_price -lt 1 ]; then
            market_price=1
        fi

        # 存储市场价（格式：商品名 市场价(分)）
        daily_market_prices+=("${item_name} ${market_price}")

        # 显示市场价（红色提示亏损风险）
        if [ $market_price -lt $item_cost ]; then
            # 终端支持ANSI颜色：红色字体提示亏损
            echo -e "⚠️  ${item_name}：市场价 $(to_yuan $market_price) 元 < 成本价 $(to_yuan $item_cost) 元（销售将亏损）"
        else
            echo "✅ ${item_name}：市场价 $(to_yuan $market_price) 元（成本价 $(to_yuan $item_cost) 元）"
        fi
    done

    echo "---------------------------------------------"
    sleep 2  # 停留2秒，让玩家制定定价策略
}
