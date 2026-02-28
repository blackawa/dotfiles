---
name: ui-bug-fix
description: |
  UIの見た目の不具合（フォント・レイアウト・色など）をFigmaと実装の差分から特定・修正・検証し、Slackでレビュー依頼するワークフロー。
  「Figmaと違う」「デザインと差異がある」「スマホで見た目がおかしい」「フォントが違う」「レイアウトがズレている」
  「デザイン確認して」「QAして」「実装とFigmaを比較して」といった発言があれば、このスキルを使うこと。
  Figma MCP + testing-browser スキルを組み合わせて使用する。
---

# UI Bug Fix ワークフロー

## ステップ

1. **DoD合意** — 対象URL・デバイス・Figmaノード・合格条件・Slack報告先をユーザーと確定する
2. **現状把握** — Figma MCPでデザイン仕様取得 → agent-browserでComputedStyleを実測
3. **計画立案** — 根本原因・修正箇所・副作用をPlanモードで整理
4. **修正** — 影響最小・既存パターンに従う
5. **セルフQA** — agent-browserでComputedStyleを再計測し、DoDと照合
6. **git push** — コミット → push → `gh run watch` でCI/CD完了を待機
7. **Slackレビュー依頼** — Slack MCPで対象スレッドに結果を報告

## 現状把握：診断コマンド集

```bash
# 要素の計算済みスタイルを取得
agent-browser eval "
  var el = document.querySelector('.target');
  var s = window.getComputedStyle(el);
  JSON.stringify({fontFamily: s.fontFamily, fontSize: s.fontSize, color: s.color});
"

# 読み込み済みWebフォントを確認
agent-browser eval "
  var fonts = [];
  document.fonts.forEach(f => fonts.push({family: f.family, weight: f.weight, status: f.status}));
  JSON.stringify(fonts.filter(f => f.status === 'loaded'));
"

# 該当キーワードのCSSルールを抽出
agent-browser eval "
  var rules = [];
  Array.from(document.styleSheets).forEach(sheet => {
    try { Array.from(sheet.cssRules).forEach(r => {
      if (r.cssText?.includes('keyword')) rules.push(r.cssText.slice(0, 200));
    }); } catch(e) {}
  });
  JSON.stringify(rules);
"
```

## よくある落とし穴

- フォント読み込みが**環境別条件**（本番のみ等）に入っている → 条件分岐を必ず確認
- WebフォントはFontFaceSetに登録されていても `status: unloaded` のことがある → 実際に使われている要素のComputedStyleで確認
- SCSSの詳細度（specificity）でユーティリティクラスが上書きされている → DevToolsのCascadeを確認

## Slackレビュー依頼テンプレート

```
@田浦さん @川端さん 修正が完了しました。

【原因】（1-2文）
【修正】ファイル名・変更内容 / コミット: URL
【QA結果】DoD合格条件の実測値
ステージング: URL
```
