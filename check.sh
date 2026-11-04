# 最推荐：检查是否有 * 标记的正在运行的 workflow
if gh run list --limit 10 | grep -q '^\*'; then
    echo "✅ 当前有 Workflow 正在运行中"
    gh run list --limit 5
else
    echo "⛔ 当前没有 Workflow 在运行"
fi
