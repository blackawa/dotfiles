---
name: test-clasp-project
description: >
  Google Apps Script (GAS) プロジェクトのテスト戦略。
  return-based assertion、テスト関数の構造化、開発用ヘルパー、devMode実行までを実体験ベースで記述。
  GASプロジェクトでテストを書きたいとき、または `clasp run` / `gws script` の戻り値が取れず詰まったときに使う。
---

# clasp プロジェクト テスト戦略

GASプロジェクトの自己検証ループを構築するための実装パターン。
前提セットアップは `setup-clasp-project` を参照。

## 基本原則

| 原則 | 理由 |
|------|------|
| **`return` で結果を返す** | `Logger.log` の出力は `clasp run` / `gws script` では取得できない |
| **テスト関数は `_test_` をプレフィックスに** | テスト関数だけまとめて呼び出せるようにするため |
| **本番ヘルパーと開発用ヘルパーは別ファイル** | リリース時に開発用を物理的に除外できる |
| **`devMode: true` で実行** | デプロイ不要で最新の HEAD コードを実行できる |

## テスト関数の標準形

```javascript
/** T4: シート操作の検証 */
function プロジェクト_test_T4() {
  // 1. テスト対象を実行
  var result = doSomething();

  // 2. 期待値と比較してチェックを集める
  var checks = {
    '結果が真': result.ok === true,
    '件数が3件': result.count === 3,
    '想定外のフィールドがない': !('unexpected' in result),
  };

  // 3. オブジェクトで return（passフラグも一緒に）
  return {
    result: result,
    checks: checks,
    allPass: Object.values(checks).every(function(v) { return v === true; }),
  };
}
```

`checks` をオブジェクトにする利点:
- 各assertionに**自然言語のラベル**が付く（失敗時にどれが落ちたか即わかる）
- テストフレームワーク不要、純粋なJavaScriptで完結
- 戻り値をそのまま見ればテストレポートになる

## 全テスト集約関数

```javascript
function プロジェクト_runAllTests() {
  var t4 = プロジェクト_test_T4();
  var t6 = プロジェクト_test_T6();
  var t10 = プロジェクト_test_T10();
  return {
    T4_シート操作: t4.allPass ? 'PASS' : 'FAIL',
    T6_BQクエリ: t6.allPass ? 'PASS' : 'FAIL',
    T10_バッチ統合: t10.allPass ? 'PASS' : 'FAIL',
    allPass: t4.allPass && t6.allPass && t10.allPass,
  };
}
```

CLI から1コマンドで全テスト実行:

```bash
gws script scripts run \
  --params '{"scriptId":"<scriptId>"}' \
  --json '{"function":"プロジェクト_runAllTests","devMode":true}'
```

→ `{ T4_シート操作: "PASS", T6_BQクエリ: "PASS", ..., allPass: true }`

落ちたテストだけ個別実行して詳細を確認:

```bash
gws script scripts run \
  --params '{"scriptId":"<scriptId>"}' \
  --json '{"function":"プロジェクト_test_T4","devMode":true}'
```

→ `checks` の中で false になっているキーを見れば即原因特定。

## 開発用ヘルパー（dev_）の分離

リリース時に除外するために、開発専用関数は **`プロジェクト_dev_*`** プレフィックスで命名し、テストファイルか専用ファイルに置く:

```javascript
/** 開発用: シート一覧を取得 */
function プロジェクト_dev_listSheets() {
  var ss = SpreadsheetApp.openById(CONFIG.SPREADSHEET_ID);
  return ss.getSheets().map(function(s) { return s.getName(); });
}

/** 開発用: 旧マーカー付きシートを新マーカーにリネーム（設定変更時の一発移行） */
function プロジェクト_dev_renameMarker() {
  var ss = SpreadsheetApp.openById(CONFIG.SPREADSHEET_ID);
  var renamed = [];
  ss.getSheets().forEach(function(s) {
    var name = s.getName();
    if (name.startsWith('旧')) {
      var newName = '新' + name.substring('旧'.length);
      s.setName(newName);
      renamed.push({ from: name, to: newName });
    }
  });
  return { renamed: renamed };
}
```

これらの利点:
- 環境構築や設定移行を**1コマンドで再現可能**にする（手作業を排除）
- 履歴に残るので「どんな移行があったか」あとから追える
- リリース時には `プロジェクト_テスト.js` ごと除外すれば本番に持ち込まれない

## devMode の威力

| 実行方法 | デプロイ必要 | 最新コード | 戻り値 |
|---------|------------|----------|--------|
| `clasp run 関数名` | ⚠ API実行可能デプロイ必須 | ✅ | ✅ |
| `gws script scripts run --json '{"devMode":true}'` | ❌ 不要 | ✅ | ✅ |
| GAS エディタで「実行」 | ❌ 不要 | ✅ | ❌（ログのみ） |

**`devMode: true` を指定すると、deployIDを作らなくても HEAD（最新）コードを実行できる**。
clasp run のセットアップ（API実行可能デプロイ）が面倒な場合や詰まったときに有用。

`clasp push -f && gws script scripts run --json '{"function":"...","devMode":true}'` の組み合わせが最速の開発ループ。

## テストデータの整え方

### パターン1: 専用テストシート

シート名にテスト用マーカー（例: `★テスト`）を付け、`findTargetSheets` がマーカーで判定するようにすれば、テストシートも本番ロジックと同じ経路で処理される。

利点:
- 本番ロジックを別の経路で動かす必要がない（テスト用フックや分岐を作らない）
- 期待値も同じスプシに固定値で入れておけば検証が楽

### パターン2: 既存シートのスナップショット

整形済みのテストデータをスプシに固定行として入れておき、`Row 4 = 正常`, `Row 5 = STATUS=計上`, `Row 6 = 計上コードなし`, `Row 7 = 存在しないコード` のように1行=1ケースで配置する。

```javascript
var checks = {
  'Row4(正常)が処理される': targetRows[0] && targetRows[0].row === 4,
  'Row5(STATUS=計上)はスキップ': !targetRows.some(function(r) { return r.row === 5; }),
  'Row6(計上コードなし)はスキップ': !targetRows.some(function(r) { return r.row === 6; }),
  'Row7(存在しないコード)は対象だがエラー': targetRows.some(function(r) { return r.row === 7; }),
};
```

### パターン3: テスト前後でクリーンアップ

破壊的なテスト（書き込み系）の場合、各実行ごとに対象セルをクリアしてから実行:

```javascript
function プロジェクト_test_T10() {
  // テスト前にクリーンアップ
  var sheet = ss.getSheetByName('★テスト');
  for (var row = 4; row <= 8; row++) {
    sheet.getRange(row, COL_COST).clearContent();
  }

  // バッチ実行
  var summary = プロジェクト_nightlyBatch();

  // 結果確認
  var row4cost = sheet.getRange(4, COL_COST).getValue();
  var checks = {
    'Row4にコストが書き込まれた': row4cost > 0,
    'Row5(STATUS=計上)は空のまま': sheet.getRange(5, COL_COST).getValue() === '',
  };
  return { summary: summary, checks: checks, allPass: ... };
}
```

## アンチパターン

| やってはいけないこと | 理由 |
|------------------|------|
| `Logger.log` でテスト結果を出す | CLI実行で結果が取れない（GAS実行履歴を見に行く必要がある） |
| `assert` 関数を作って `throw` する | エラーで止まると後続のテストが実行されない、レポートも乱れる |
| テスト関数の中で `SpreadsheetApp.getUi()` を使う | CLI実行ではUIが起動できずエラー |
| 本番ロジックにテスト用の if 分岐を入れる | テストが本物のフローを通っていない証拠 |
| テスト用と本番用でシートを別物にする | テストが本物のシート判定を通っていない |

## 実行サイクルの典型

```bash
# 編集
vim gas/プロジェクト_バッチ.js

# push & test
clasp push -f && \
  gws script scripts run \
    --params '{"scriptId":"<scriptId>"}' \
    --json '{"function":"プロジェクト_runAllTests","devMode":true}' \
    --format json | jq '.response.result'

# → { "T4_シート操作": "PASS", ..., "allPass": true }
```

`allPass: true` を CI のexit条件にすれば、自動化も可能。

## 関連スキル

- `setup-clasp-project` — clasp + gws CLI の初期セットアップ
- `deploy-clasp-project` — テスト合格後の本番デプロイ手順
