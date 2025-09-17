#!/bin/bash
# 模块：每日市场价格生成
generate_market_prices() {
    daily_market_prices=()  # 清空昨日市场价
    echo "�� 今日市场指导价生成中（成本价±30%浮动）..."
    echo "---------------------------------------------"

    # 为每种商品生成市场价
    for i in "${!inventory[@]}"; do
        item=(${inventory[$i]})
        item_name=${item[0]}
        item_cost=${item[2]}  # 成本价（分）
        item_price=${item[3]} # 当前售价（分） 新增：获取当前售价

        # 市场价计算：成本价×(70%~130%)，取整数
        local random_ratio=$(( RANDOM % 61 + 70 ))  # 70~130的随机数（±30%）
        local market_price=$(( item_cost * random_ratio / 100 ))
        [ $market_price -lt 1 ] && market_price=1  # 极端情况防护

        # 存储市场价
        daily_market_prices+=("${item_name} ${market_price}")

        # 三价关系分析与提示
        echo -n "${item_name}："
        echo -n "成本=$(to_yuan $item_cost)元 | "
        echo -n "市场价=$(to_yuan $market_price)元 | "
        echo -n "当前售价=$(to_yuan $item_price)元 "
        if [ $market_price -lt $item_cost ]; then
          # 市场价 < 成本价时的策略提示（基于售价与成本价的核心关系）
          if [ $item_price -gt $item_cost ]; then
              # 售价 > 成本价：即使市场价低，销售仍有利润空间
              echo -e "✅ [策略机会] 售价高于成本价，可正常销售盈利"
          else
              # 售价 ≤ 成本价：无论市场价如何，销售都会亏损
              echo -e "⚠️ [风险提示] 售价低于/等于成本价，销售将亏损"
          fi
        else
           # 市场价 ≥ 成本价时的常规提示（保持不变）
           if [ $item_price -gt $market_price ]; then
               echo -e "�� 售价高于市场价，销量可能下降"
           elif [ $item_price -eq $market_price ]; then
               echo -e "�� 售价等于市场价，销量正常"
           else
               echo -e "�� 售价低于市场价，销量可能上升"
           fi
        fi 
    done

    echo "---------------------------------------------"
    read -p "请分析市场后制定策略，按回车键继续..." 
}
