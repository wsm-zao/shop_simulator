#!/bin/bash
# 模块：商品解锁检查（新增核心功能）
# 功能：营业后检查资金是否达标，解锁新商品并加入库存
check_unlock_products() {
    local new_unlocked=()  # 临时存储本次解锁的商品

    # 遍历可解锁商品，检查资金条件
    for up in "${unlockable_products[@]}"; do
        # 拆分可解锁商品信息：名 解锁资金 成本 售价
	local parts=($up)  # 将商品信息按空格拆分为数组
	local up_name=${parts[0]}      # 商品名（第1个元素）
	local up_money=${parts[1]}     # 解锁资金（第2个元素，纯数字）
	local up_cost=${parts[2]}      # 成本（第3个元素）
	local up_price=${parts[3]}     # 售价（第4个元素）
        # 解锁条件：资金达标 + 未解锁过
        if [ $money -ge $up_money ] && ! [[ " ${unlocked_products[@]} " =~ " ${up_name} " ]]; then
            new_unlocked+=("$up_name $up_cost $up_price")
            unlocked_products+=("$up_name")  # 标记为已解锁
        fi
    done

    # 若有新解锁商品，加入库存并提示
    if [ ${#new_unlocked[@]} -gt 0 ]; then
        echo "---------------------------------------------"
        echo -e "������ 恭喜！解锁新商品："
        for np in "${new_unlocked[@]}"; do
            local np_name=${np%% *}
            local np_cost=${np% *}
            np_cost=${np_cost#* }
            local np_price=${np#* * }
            # 新商品初始库存5个，加入库存数组
            inventory+=("${np_name} 5 ${np_cost} ${np_price}")
            echo -e "✅ ${np_name}（成本：$(to_yuan $np_cost)元，初始售价：$(to_yuan $np_price)元）"
        done
        echo "---------------------------------------------"
        sleep 3  # 停留3秒，让玩家看清
    fi
}
