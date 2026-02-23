---
name: writing-python
description: >
  Python コードの作成・レビュー時に適用する規約とベストプラクティス。
  Pythonファイルの編集、Pythonプロジェクトのセットアップ、
  pytest/ruff/mypyの実行時に自動で有効化される。
---

# Python Development Standards

## ツールチェイン

必ず以下のツールを使用する。代替ツールは使わない。

| 用途 | ツール | 非推奨 |
|------|--------|--------|
| パッケージ管理 | uv | pip, poetry, pipenv |
| Lint + Format | ruff | flake8, black, isort |
| テスト | pytest | unittest |
| 型チェック | mypy | - |

## コマンド

```bash
# 依存関係
uv add <package>          # 追加
uv add --dev <package>    # dev依存追加
uv sync                   # 同期
uv lock                   # ロック更新

# 実行（直接 python, pytest を呼ばない）
uv run python <script>
uv run pytest -xvs        # テスト
uv run ruff check --fix . # lint + autofix
uv run ruff format .      # format
uv run mypy .             # 型チェック
```

## 型ヒント

- すべての関数シグネチャ、クラス属性に型ヒントを付ける
- ネイティブ構文を使う: `list[str]`, `dict[str, int]`, `str | None`
- `from __future__ import annotations` は不要（Python 3.10+）
- `Any` 型は禁止。具体型、TypeVar、Protocolで代替する
- `# type: ignore` はテストコード内の希少なケースのみ許可

```python
# ✅ Good
def process_users(users: list[User], limit: int | None = None) -> list[Result]:
    ...

# ❌ Bad
def process_users(users, limit=None):
    ...
```

## コーディングパターン

### 推奨
- dataclass / Pydantic model でデータ構造を定義する
- 早期リターンでネストを浅く保つ
- コンテキストマネージャを使う（`with` 文）
- リスト内包表記はシンプルなケースのみ（2条件以下）
- f-string をデフォルトのフォーマット手段とする
- 構造的パターンマッチ（match/case）を適切に使う

```python
# ✅ 早期リターン
def get_user(user_id: str) -> User:
    user = db.find(user_id)
    if user is None:
        raise UserNotFoundError(f"User {user_id} not found")
    if not user.is_active:
        raise InactiveUserError(f"User {user_id} is inactive")
    return user

# ❌ ネスト地獄
def get_user(user_id: str) -> User:
    user = db.find(user_id)
    if user is not None:
        if user.is_active:
            return user
        else:
            raise InactiveUserError(...)
    else:
        raise UserNotFoundError(...)
```

### 禁止
- `except Exception: pass` — エラーを握りつぶさない
- グローバル変数の変更
- `import *` によるワイルドカードインポート
- 循環インポート

## エラーハンドリング

- カスタム例外クラスを定義して使う
- except節は具体的な例外型を捕捉する
- エラーメッセージにデバッグ用コンテキストを含める
- リトライロジックは tenacity 等のライブラリに任せる

```python
# ✅ Good
class PaymentError(Exception):
    def __init__(self, amount: float, reason: str) -> None:
        super().__init__(f"Payment of {amount} failed: {reason}")
        self.amount = amount
        self.reason = reason

try:
    process_payment(order)
except PaymentGatewayTimeout as e:
    logger.warning("Payment gateway timeout for order %s: %s", order.id, e)
    raise PaymentError(order.total, "gateway timeout") from e

# ❌ Bad
try:
    process_payment(order)
except Exception:
    pass
```

## テスト

- テストファイルはソースの隣に置く、または `tests/` ディレクトリ
- テスト関数名は `test_<振る舞い>_<条件>` の形式
- Arrange-Act-Assert パターンに従う
- `@pytest.fixture` でセットアップを共有する
- `@pytest.mark.parametrize` で網羅的にテストする
- エラーケースとエッジケースを必ずテストする

```python
class TestCalculatePrice:
    def test_returns_unit_price_without_tax(self) -> None:
        result = calculate_price(total=100.0, quantity=10, tax_rate=0.0)
        assert result == 10.0

    def test_raises_on_zero_quantity(self) -> None:
        with pytest.raises(ValueError, match="quantity must be positive"):
            calculate_price(total=100.0, quantity=0, tax_rate=0.0)

    @pytest.mark.parametrize("total,qty,tax,expected", [
        (100, 10, 0.0, 10.0),
        (100, 10, 0.1, 11.0),
        (50, 5, 0.2, 12.0),
    ])
    def test_multiple_scenarios(self, total: float, qty: int, tax: float, expected: float) -> None:
        assert calculate_price(total, qty, tax) == pytest.approx(expected)
```

## プロジェクト構成

```
myproject/
├── src/myapp/
│   ├── __init__.py
│   ├── api/
│   ├── models/
│   ├── services/
│   └── utils/
├── tests/
│   ├── conftest.py
│   ├── unit/
│   └── integration/
├── pyproject.toml
└── README.md
```

## pyproject.toml 最小構成

```toml
[project]
name = "myapp"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[dependency-groups]
dev = ["pytest>=8.0", "ruff>=0.8", "mypy>=1.0"]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "B", "C4", "UP"]

[tool.pytest.ini_options]
testpaths = ["tests"]

[tool.mypy]
strict = true
```