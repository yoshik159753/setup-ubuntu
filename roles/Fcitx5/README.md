# Ubuntu / Fcitx5 セットアップまとめ

---

## 1. Fcitx5 + Mozc インストール

```bash
sudo apt install fcitx5 fcitx5-mozc
```

---

## 2. IM システムの切り替え

「システム設定 > 地域と言語 > 言語サポート > キーボード入力に使う IM システム」を **Fcitx5** に変更し、**再起動**する。

---

## 3. Fcitx5 の自動起動設定

GNOME on Wayland（Ubuntu 22.04 以降のデフォルト）では、`im-config` の起動スクリプトが X11 セッション専用のため Fcitx5 が自動起動しない。  
`~/.config/autostart/fcitx5.desktop` を配置することで、ログイン時に Fcitx5 を起動する。

```bash
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/fcitx5.desktop << 'EOF'
[Desktop Entry]
Type=Application
Exec=/usr/bin/fcitx5 --replace -d
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[ja]=Fcitx5
Name=Fcitx5
Comment[ja]=入力メソッドを開始
Comment=Start Input Method
EOF
```

> **出典**
> - [Running Fcitx 5 on Wayland — Fcitx Wiki](https://fcitx-im.org/wiki/Running_Fcitx_5_on_Wayland)
> - `/usr/share/doc/fcitx5/README.Debian` — "You may also opt to configure the environment variable or autostart by yourself."

---

## 4. Fcitx5 の入力メソッド設定

Fcitx5 の設定を開き、以下を行う。

- **入力メソッド**タブ: Mozc を追加
- **グローバルオプション**タブ: 「入力メソッドの切り替え」に半角/全角の切り替えキーを設定（例: `Ctrl+Space`）

---

## 4. US 配列でのセミコロン/コロン入れ替え

US 配列はデフォルトで「Shift なし → `;`、Shift あり → `:`」。
これを逆（**Shift なし → `:`、Shift あり → `;`**）にする手順。

### 手順

```bash
# システムファイルをユーザー XKB ディレクトリにコピー
mkdir -p ~/.config/xkb/symbols
cp /usr/share/X11/xkb/symbols/us ~/.config/xkb/symbols/us
```

`~/.config/xkb/symbols/us` を開き、`xkb_symbols "basic"` セクション内の以下の行を探す:

```text
# 変更前
key <AC10> { [ semicolon, colon ] };

# 変更後
key <AC10> { [ colon, semicolon ] };
```

### 設定の反映

**再ログイン**が必要（libxkbcommon はセッション開始時に `~/.config/xkb/` を読み込む）。

### メンテナンス

`xkb-data` パッケージ更新後にレイアウトが戻った場合は、ユーザーファイルを削除して再度手順を実施する。

```bash
rm ~/.config/xkb/symbols/us
```

---
