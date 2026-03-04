---
name: google-workspace-operations
description: |
  gogcli（gog コマンド）を使って Google Workspace を操作する。
  Google Sheets のデータ取得・数式確認・セル更新など Google Workspace 操作全般に使う。
---

## コマンドリファレンス

```bash
# 認証確認
gog auth list

# スプレッドシートのシート一覧（gid → シート名の特定）
gog sheets metadata <SPREADSHEET_ID>

# 値の取得
gog sheets get <SPREADSHEET_ID> '<シート名>!A1:AZ60' --render UNFORMATTED_VALUE --json

# 数式の取得
gog sheets get <SPREADSHEET_ID> '<シート名>!A1:AZ60' --render FORMULA --json
```

## 落とし穴

**シート名にスペース・スラッシュが含まれる場合はシングルクォートで囲む**（変数展開させない）

```bash
# NG: gog sheets get "$ID" "$SHEET!A1:Z50"
gog sheets get "$ID" '目標案 02/27 黒川作業!A1:AZ60' --render FORMULA --json
```

## ワンライナー集

```bash
# 数式セルだけ抽出
gog sheets get "$ID" "$RANGE" --render FORMULA --json \
  | python3 -c "
import json,sys
for i,row in enumerate(json.load(sys.stdin).get('values',[])):
  for j,c in enumerate(row):
    if isinstance(c,str) and c.startswith('='):
      print(f'行{i+1} 列{chr(65+j) if j<26 else chr(64+j//26)+chr(65+j%26)}: {c}')
"
```
