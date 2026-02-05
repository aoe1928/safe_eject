#!/bin/zsh

# ==========================================
# 設定と準備
# ==========================================

echo "🚀 安全な一括アンマウント処理を開始します..."

# Time Machineの状態を確認する関数
function is_tm_running() {
    # tmutil status の出力に "Running = 1" があるか確認
    tmutil status | grep -q "Running = 1"
}

# ==========================================
# 1. Time Machine の制御
# ==========================================

if is_tm_running; then
    echo "⚠️ Time Machineバックアップが実行中です。"
    echo "🛑 バックアップを停止しています..."
    
    # バックアップ停止コマンド
    tmutil stopbackup
    
    # 完全に停止するまでループで待機（最大60秒待つ例）
    local wait_count=0
    while is_tm_running; do
        if (( wait_count > 60 )); then
            echo "❌ Time Machineの停止に時間がかかりすぎています。処理を中断します。"
            exit 1
        fi
        printf "."
        sleep 1
        ((wait_count++))
    done
    echo "\n✅ Time Machineバックアップが停止しました。"
else
    echo "ℹ️ Time Machineは実行されていません。次に進みます。"
fi

# ==========================================
# 2. ディスク書き込みの同期
# ==========================================

echo "💾 キャッシュをディスクに書き込んでいます (sync)..."
sync

# ==========================================
# 3. 外部ボリュームのアンマウント処理
# ==========================================

# /Volumes 内のディレクトリをチェック
for disk in /Volumes/*; do
    # ディレクトリが存在しない場合（/Volumesが空など）はスキップ
    [ -e "$disk" ] || continue

    # .timemachine などの特殊ディレクトリはスキップ
    if [[ "$disk" == *".timemachine"* ]]; then
        continue
    fi

    # 【重要】diskutil info を使って「取り出し可能(Ejectable)」なディスクか判定
    # システムドライブやRecovery領域を名前指定で除外するより確実です
    is_ejectable=$(diskutil info "$disk" | grep "Ejectable" | grep "Yes")

    if [[ -n "$is_ejectable" ]]; then
        echo "----------------------------------------"
        echo "⏏️  Ejecting: ${disk:t} ..." # :t はパスの末尾(ファイル名)のみ表示するzsh修飾子

        # アンマウント実行
        if diskutil eject "$disk"; then
            echo "✅ 成功: ${disk:t} を取り外しました。"
        else
            echo "⚠️ 失敗: ${disk:t} は使用中の可能性があります。"
        fi
        
        # 連続処理時の安定性のため少し待つ
        sleep 1
    else
        # Ejectable: No のディスク（内蔵SSDなど）は無視してログも出さない（あるいはデバッグ用に出す）
        # echo "スキップ (内蔵/システム): ${disk:t}"
        continue
    fi
done

echo "----------------------------------------"
echo "🎉 処理が完了しました。"