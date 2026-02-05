#!/bin/zsh

# ==========================================
# 1. Time Machine の監視と停止
# ==========================================

echo "🚀 安全な一括アンマウント処理を開始します..."

# Time Machineの状態を確認する関数
function is_tm_running() {
    tmutil status | grep -q "Running = 1"
}

if is_tm_running; then
    echo "⚠️ Time Machineバックアップが実行中です。"
    echo "🛑 バックアップを停止しています..."
    
    tmutil stopbackup
    
    # 完全に停止するまで待機（最大60秒）
    wait_count=0
    while is_tm_running; do
        if (( wait_count > 60 )); then
            echo "❌ 停止できませんでした。処理を中断します。"
            exit 1
        fi
        printf "."
        sleep 1
        ((wait_count++))
    done
    echo "\n✅ Time Machineバックアップが停止しました。"
else
    echo "ℹ️ Time Machineは実行されていません。"
fi

# ==========================================
# 2. キャッシュ書き込み (sync)
# ==========================================
echo "💾 キャッシュをディスクに書き込んでいます..."
sync

# ==========================================
# 3. アンマウント処理 (除外リスト方式)
# ==========================================

for disk in /Volumes/*; do
    # 存在チェック
    [ -e "$disk" ] || continue

    # ---------------------------------------------------------
    # 除外リスト（ここを最初のコードと同じロジックに戻しました）
    # ---------------------------------------------------------
    # 1. Macintosh HD (標準のシステムドライブ名)
    # 2. Recovery (リカバリ領域)
    # 3. .timemachine (Time Machineの一時マウント領域)
    # 4. com.apple.TimeMachine (ローカルスナップショット等)
    # ---------------------------------------------------------
    if [[ "$disk" == "/Volumes/Macintosh HD" || \
          "$disk" == "/Volumes/Recovery" || \
          "$disk" == "/Volumes/.timemachine" || \
          "$disk" == *"/com.apple.TimeMachine"* ]]; then
        # システム系はスキップしてログも出さない（あるいはデバッグで出す）
        continue
    fi

    # ここに来たものはすべてアンマウント対象
    echo "----------------------------------------"
    echo "Stopping: ${disk:t}"

    # eject実行
    if diskutil eject "$disk"; then
        echo "✅ 成功"
    else
        echo "⚠️ 失敗 (使用中の可能性があります)"
    fi

    # 2秒待機
    sleep 2
done

echo "----------------------------------------"
echo "✅ すべての外部ドライブの処理が完了しました。"