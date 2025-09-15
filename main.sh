#!/bin/bash
# 小商店经营模拟器
# 功能：加载所有模块、控制游戏主循环

# ====================== 全局变量定义（所有模块共享） ======================
money=0                  # 资金（分）
day=0                    # 经营天数
daily_expense=0          # 每日房租（分）
inventory=()             # 库存数组（商品名 数量 成本 售价）
game_over=0              # 游戏结束标记（0=继续，1=结束）
consecutive_loss_days=0  # 连续亏损天数
total_profit=0           # 当日税前利润（分）
after_tax_profit=0       # 当日税后利润（分）
daily_market_prices=()   # 每日市场指导价（商品名 市场价）
unlockable_products=()   # 可解锁商品（名 解锁资金 成本 售价）
unlocked_products=()     # 已解锁商品（临时存储）
achievement=""           # 最终成就（空=未达成）
target_basic=0           # 基础成就目标（分）
target_advanced=0        # 进阶成就目标（分）
target_ultimate=0        # 终极成就目标（分）

# ====================== 加载外部模块 ======================
# 加载工具库
if [ ! -f ./lib/utils.sh ]; then
    echo "错误：工具库 ./lib/utils.sh 不存在！"
    exit 1
fi
source ./lib/utils.sh

# 加载业务模块（顺序：初始化→基础功能→核心逻辑→结束处理）
modules=("init.sh" "status.sh" "buy_stock.sh" "adjust_price.sh" "market_price.sh" "unlock_product.sh" "business.sh" "game_over.sh")
for mod in "${modules[@]}"; do
    mod_path="./modules/$mod"
    if [ ! -f "$mod_path" ]; then
        echo "错误：模块文件 $mod_path 不存在！"
        exit 1
    fi
    source "$mod_path"
done

# ====================== 游戏主循环 ======================
main() {
    # 1. 初始化游戏（加载初始资金、库存、成就目标）
    initialize_game

    # 2. 处理用户操作
    while [ $game_over -eq 0 ]; do
        # 显示当日状态（资金、库存、天数）
        show_status

        # 提示操作选项
        echo "请选择操作:"
        echo "1. 进货 | 2. 调整售价 | 3. 开始今日营业 | 4. 退出游戏"
        read -p "你的选择: " choice

        # 处理不同操作
        case $choice in
            1) buy_stock ;;  # 进货功能
            2) adjust_price ;;  # 调整售价
            3) 
                run_business  # 开始营业（含市场价生成、销售计算、缴税）
                day=$((day + 1))  # 营业结束后天数+1
                check_game_over  # 检查结束条件（亏损/成就）+ 解锁商品
                ;;
            4) 
                # 确认退出
                read -p "确定要退出游戏吗？(y/n) " confirm
                if [[ $confirm == "y" || $confirm == "Y" ]]; then
                    game_over=1
                fi
                ;;
            *) 
                echo "无效的选择，2秒后重试..."
                sleep 2
                ;;
        esac
    done

    # 3. 显示游戏结果（成就总结）
    show_results
}

# 启动游戏
main
exit 0
