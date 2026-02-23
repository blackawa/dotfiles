---
name: writing-bigquery
description: |
  BigQuery SQLの作成・レビュー・実行時に適用する規約とベストプラクティス。
  BigQuery SQLファイルの編集、BigQueryクエリの作成、データ分析クエリの設計・実行時に自動で有効化される。
  「BigQueryで〜」「BQで集計して」「SQLを書いて」「データを分析して」「クエリを作って」
  「dbtモデルを確認して」「テーブルを調べて」といった発言があれば、このスキルを使うこと。
  bqコマンドによるクエリ実行、スキーマ調査、データ探索にも適用される。
---

# BigQuery SQL 規約・ベストプラクティス

BigQuery SQLを書く際は、このスキルに従って**規約の遵守**と**分析→設計→テスト**のワークフローを実行する。

---

## 1. SQL記述規約

### 命名規則

- テーブル名・カラム名は `snake_case` を基本とする
- 日本語カラム名を使う場合は、必ずバッククォートで囲む
- CTEには処理内容がわかる意味ある名前をつける（`tmp1` のような名前は避ける）

```sql
-- Good
WITH daily_revenue AS (...),
     user_segments AS (...)

-- Bad
WITH t1 AS (...),
     t2 AS (...)
```

### 括弧の扱い

括弧はBigQueryのエイリアスとして利用不可。ユーザーが括弧を含むカラム名を指定した場合、アンダースコアに自動変更し、変更した旨を報告する。

例: `売上(税込)` → `` `売上_税込` ``

### フォーマット

- SQLキーワードは **大文字** （`SELECT`, `FROM`, `WHERE`, `GROUP BY` 等）
- インデントは **4スペース**（タブ不可）
- SELECT句のカラムは **1行に1つ**、先頭カンマスタイル
- 長いクエリはCTEで段階的に分解し、可読性を保つ

```sql
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(order_date, MONTH) AS order_month
        ,customer_id
        ,SUM(amount) AS total_amount
    FROM `project.dataset.orders`
    WHERE order_date >= '2024-01-01'
    GROUP BY 1, 2
)

SELECT
    order_month
    ,COUNT(DISTINCT customer_id) AS `顧客数`
    ,SUM(total_amount) AS `売上合計`
FROM monthly_sales
GROUP BY 1
ORDER BY 1
```

### タイムゾーン

タイムスタンプを人が読む日時に変換する場合は、必ず `Asia/Tokyo` を指定して一貫させる。

```sql
SELECT
    DATETIME(created_at, 'Asia/Tokyo') AS `作成日時`
    ,DATE(created_at, 'Asia/Tokyo') AS `作成日`
```

---

## 2. パフォーマンスとコスト最適化

BigQueryはスキャンしたバイト数で課金されるため、読み取るデータ量を最小化することがコスト削減とパフォーマンス向上の両方に直結する。

### SELECT * を避ける

必要なカラムのみを明示的に指定する。`SELECT *` はスキャン量を不必要に増やし、コストとパフォーマンスの両方に悪影響がある。

```sql
-- Good
SELECT user_id, email, created_at
FROM `project.dataset.users`

-- Bad
SELECT *
FROM `project.dataset.users`
```

### パーティションフィルタを活用する

パーティションされたテーブルに対しては、WHERE句で必ずパーティションカラムをフィルタする。これによりスキャン範囲が限定され、コストが大幅に下がる。

```sql
-- パーティションプルーニングが効く
WHERE DATE(created_at) BETWEEN '2024-01-01' AND '2024-01-31'

-- パーティションプルーニングが効かない（関数でラップしている）
WHERE EXTRACT(MONTH FROM created_at) = 1
```

### 自己結合を避け、ウィンドウ関数を使う

行間の比較が必要な場合、自己結合は出力行数を二乗的に増やすリスクがある。代わりにウィンドウ関数を使う。

```sql
-- Good: ウィンドウ関数で前回値を取得
SELECT
    user_id
    ,order_date
    ,amount
    ,LAG(amount) OVER (PARTITION BY user_id ORDER BY order_date) AS prev_amount
FROM `project.dataset.orders`

-- Bad: 自己結合
SELECT a.user_id, a.amount, b.amount AS prev_amount
FROM orders a
JOIN orders b ON a.user_id = b.user_id AND ...
```

### CROSS JOINは事前集約してから

CROSS JOINが必要な場合は、結合前にデータを可能な限り集約し、爆発的な行数増加を防ぐ。

### 概算で十分なら近似関数を使う

厳密な値が不要な場面では近似集約関数を使うと高速になる。

```sql
-- 厳密なカウント
COUNT(DISTINCT user_id)

-- 概算で十分な場合（大規模データで高速）
APPROX_COUNT_DISTINCT(user_id)
```

### コスト見積もりにはドライランを使う

本番実行前にドライランでスキャン量を確認する習慣をつける。

```bash
bq query --use_legacy_sql=false --dry_run "
SELECT user_id, created_at
FROM \`project.dataset.large_table\`
WHERE DATE(created_at) = '2024-06-01'
"
```

---

## 3. BigQuery特有の便利機能

### QUALIFY句で重複排除をシンプルに

サブクエリなしでウィンドウ関数の結果をフィルタできる。重複排除パターンで特に有用。

```sql
-- Good: QUALIFYでシンプルに書く
SELECT
    user_id
    ,email
    ,updated_at
FROM `project.dataset.users`
QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY updated_at DESC) = 1

-- Bad: サブクエリが必要
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY updated_at DESC) AS rn
    FROM `project.dataset.users`
) WHERE rn = 1
```

### SAFE_DIVIDE でゼロ除算を防ぐ

割り算でゼロ除算エラーを回避したい場合、`SAFE_DIVIDE` を使うとゼロ除算時にNULLを返す。

```sql
-- Good
SAFE_DIVIDE(revenue, cost) AS roi

-- Bad: ゼロ除算でエラー
revenue / cost AS roi

-- これもOK（明示的にデフォルト値を設定したい場合）
IFNULL(SAFE_DIVIDE(revenue, cost), 0) AS roi
```

### NULL処理の使い分け

- `IFNULL(expr, default)` — 単一のNULLチェックに。シンプルで意図が明確
- `COALESCE(expr1, expr2, ...)` — 複数候補からフォールバックする場合に
- `NULLIF(expr, value)` — 特定の値をNULLに変換したい場合に

```sql
SELECT
    IFNULL(phone, 'N/A') AS phone
    ,COALESCE(mobile, home_phone, office_phone) AS best_phone
    ,NULLIF(status, '') AS status  -- 空文字をNULLに
```

### ARRAY_AGG + STRUCT で関連データをネスト

1対多のデータを1行にまとめる場合に有効。

```sql
SELECT
    customer_id
    ,ARRAY_AGG(
        STRUCT(order_id, order_date, amount)
        ORDER BY order_date DESC
    ) AS orders
FROM `project.dataset.orders`
GROUP BY customer_id
```

### DATE/TIMESTAMP関数の使い分け

```sql
-- 日付の切り捨て
DATE_TRUNC(order_date, MONTH)

-- タイムスタンプ → 日付（タイムゾーン付き）
DATE(created_at, 'Asia/Tokyo')

-- 日付差分
DATE_DIFF(end_date, start_date, DAY)

-- 日付の加減算
DATE_ADD(start_date, INTERVAL 7 DAY)
DATE_SUB(end_date, INTERVAL 1 MONTH)

-- 現在日時（Asia/Tokyo）
CURRENT_DATETIME('Asia/Tokyo')
```

---

## 4. アンチパターン

以下は避けるべきパターン。レビュー時にこれらを発見した場合は修正を提案する。

| アンチパターン | 問題 | 対策 |
|---|---|---|
| `SELECT *` | 不要なカラムスキャンでコスト増 | 必要カラムのみ指定 |
| パーティションフィルタ忘れ | フルスキャンになる | WHERE句でパーティションカラムを必ずフィルタ |
| 自己結合 | 出力行数が二乗的に増加 | ウィンドウ関数・PIVOT |
| ORDER BY without LIMIT | 大規模データのソートでスロット消費 | 最終出力以外のORDER BYには必ずLIMIT |
| CTEの過度なネスト | 可読性低下 | 5階層を超える場合は中間テーブルを検討 |
| JOINキーのデータ偏り | 特定スロットに負荷集中 | 事前フィルタ・分割クエリ |
| 関数内でパーティションカラムを加工 | プルーニング無効化 | 加工せず直接比較 |

---

## 5. データ分析クエリの作成ワークフロー

新しい分析クエリを実装する場合、以下のステップを順に実行する。

### Step 1: 現状分析

まずデータの所在と構造を正確に把握する。

**コードベースの確認**: 可能であればdbtモデルなどデータリネージを確認できるソースを読み込み、テーブル間の関係性を理解する。

**スキーマの走査**: 実際のDWH内を探索し、分析対象のデータが存在するテーブル・カラムを特定する。

```bash
# テーブル一覧
bq ls project:dataset

# スキーマ確認
bq show --schema --format=prettyjson project:dataset.table

# INFORMATION_SCHEMAでカラム一覧
bq query --use_legacy_sql=false --max_rows=50 "
SELECT column_name, data_type, is_nullable
FROM \`project.dataset.INFORMATION_SCHEMA.COLUMNS\`
WHERE table_name = 'target_table'
ORDER BY ordinal_position
"
```

**実データの調査**: テーブル内のデータのバリエーションや分布を調査し、ユーザーの認識と合っているか確認する。特にNULLの割合やカーディナリティに注目する。

```bash
bq query --use_legacy_sql=false --max_rows=20 "
SELECT
    status
    ,COUNT(*) AS cnt
    ,ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM \`project.dataset.target_table\`
GROUP BY status
ORDER BY cnt DESC
"
```

### Step 2: クエリ作成

現状分析の結果を踏まえてクエリを作成する。本スキルのSQL記述規約・パフォーマンス規約をすべて遵守すること。

### Step 3: テスト

書いたクエリがユーザーの要求を満たすか、2段階で検証する。

**テスト実行**: クエリが構文的に正しく実行可能か確認する。

```bash
bq query --use_legacy_sql=false --max_rows=20 "
<作成したクエリ>
"
```

実行結果に以下のような異常がないか確認し、あればユーザーに報告する:
- NULL率が異常に高い行
- 想定外のゼロ値やマイナス値
- 件数のオーダーが想定と大きく異なる

**サンプルテスト**: テスト実行結果から平均的な行を1つ選び、その行の内訳を個別に確認するクエリを書いて、同じ結果が得られるか検証する。集計ロジックの正しさを担保するための重要なステップ。

---

## 6. bq コマンドリファレンス

クエリ実行やスキーマ調査には `bq` コマンドを積極的に利用する。

```bash
# クエリ実行（結果を表示）
bq query --use_legacy_sql=false --max_rows=20 "SELECT 1"

# ドライラン（スキャン量確認、実行しない）
bq query --use_legacy_sql=false --dry_run "SELECT * FROM \`project.dataset.table\`"

# テーブル一覧
bq ls project:dataset

# テーブルスキーマ確認
bq show --schema --format=prettyjson project:dataset.table

# テーブル情報（行数・サイズ等）
bq show --format=prettyjson project:dataset.table

# クエリ結果をCSV出力
bq query --use_legacy_sql=false --format=csv "SELECT ..." > output.csv
```