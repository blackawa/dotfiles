---
name: writing-mermaid
description: >
  Mermaid ダイアグラムの作成・レビュー時に適用する規約とベストプラクティス。
  Mermaidファイルの編集、Mermaidダイアグラムの生成時に自動で有効化される。
---

## 共通規則

**ノード命名規則**: アルファベット連番（A, B, C...）ではなく、意味のある名前を使用する

- フェーズごとの命名: `phase1`, `phase2` など
- 処理内容を表す命名: `init1`, `check1`, `api1` など
- 機能を表す命名: `slack1`, `trans1` など

## シーケンス図

1. autonumber
2. noteを左揃えにして、そのステップの概要を書き記す。
3. box で関心事の境界線を見える化する。

例:

```mermaid
%% 表の設定
%%{init: {'noteAlign': 'left'}}%%
sequenceDiagram
autonumber

%% 列の定義
box 社外
	actor お客様
	actor 郵便局
end
box 社内
	actor 営業事務
end

%% 手順の定義
お客様 ->> 郵便局: 申込書類一式を郵送
郵便局->>営業事務: 1日1回、配達
Note left of 営業事務: ・申込用紙<br>・委任状<br>・その他書類
Note left of 営業事務: 1日1回、郵便局から受け取る
```

## フローチャート

1. 意味のあるノード名を使用する（A, B, C... 禁止）
2. フェーズや機能ごとに連番を振る
3. 色分けで役割を明確化する

例:

```mermaid
flowchart TD
    start1[開始] --> init1[初期処理]
    init1 --> check1{条件確認}
    check1 -->|Yes| process1[処理実行]
    check1 -->|No| error1[エラー処理]
    process1 --> end1[終了]
    error1 --> end1
```