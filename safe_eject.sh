#!/bin/zsh

echo "🚀 安全な一括アンマウントを開始します..."

# 1. 念のためキャッシュをディスクに物理的に書き込む
sync

# 2. /Volumes 内のボリュームをループ処理
for disk in /Volumes/*; do
    # システムドライブ、Recovery、モバイルバックアップなどは除外
    if [[ "$disk" == "/Volumes/Macintosh HD" || "$disk" == "/Volumes/Recovery" || "$disk" == "/Volumes/.timemachine" ]]; then
        continue
    fi

    echo "Stopping: $disk"

    # 3. 1つずつ丁寧にアンマウント（2秒の猶予を持たせる）
    # ejectを使うことで、ハードウェア的にも安全に切り離します
    diskutil eject "$disk"

    sleep 2
done

echo "✅ すべての外部ドライブの処理が完了しました。"
