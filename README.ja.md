# setpanel

Windows Terminal を **バランスの取れた複数ペインのグリッド** で一発起動する CLI。

```cmd
setpanel -ps 3 -bash 2
```

→ 現在の Windows Terminal ウィンドウに、5 ペイン(PowerShell 3 + Git Bash 2)のグリッドが開く。

## なぜ作ったか

`wt split-pane ...` のチェーンを手で組み立てるのは面倒。分割比率の計算、フォーカス移動の方向、シェルの選択など、気にすることが多い。
`setpanel` は `-ps N -bash N` というフラグだけで、**全ペインが同じサイズの真のグリッド** を組んでくれる。

## 必要なもの

- **Windows 10/11** + [Windows Terminal](https://github.com/microsoft/terminal)(`wt.exe` が PATH 上にあること)
- **PowerShell 5.1+**(Windows 標準で入っている)。PowerShell 7+(`pwsh.exe`)があれば自動的にそちらを優先利用する。
- **Git Bash** *(任意、`-bash` を使うときだけ必要)*。デフォルトパス: `C:\Program Files\Git\bin\bash.exe`
- **WSL** *(任意、`-wsl` を使うときだけ必要)*。`wsl.exe` で既定のディストリビューションを起動する。

## インストール

1. リポジトリをクローン、またはダウンロード:
   ```cmd
   git clone https://github.com/ishizakahiroshi/setpanel.git
   ```
2. ダウンロードした `setpanel` フォルダは、そのまま一式で保存して使う。`.bat` は同じフォルダ内の `.ps1` を呼び出すため、ファイルを1つだけ別の場所に移動しない。
3. *(任意)* フォルダを `PATH` に追加すると、どこからでも `setpanel` を呼べる。

## どのファイルを使えばいい？

迷ったらまず `setpanel-menu.bat` を使う。キーボード操作のメニューで、プリセットや作業ディレクトリを選べる。

下のファイルは同じフォルダに入れたまま使う。フォルダごとなら好きな場所へ移動・コピーしてよい。

| ファイル | 使う場面 |
|---|---|
| `setpanel-menu.bat` | 一番かんたんな対話メニューを使いたい |
| `setpanel.bat` | `setpanel -ps 2 -bash 2` のようにコマンドで直接実行したい |
| `install-shortcuts.ps1` | よく使うレイアウトのデスクトップショートカットを作りたい |
| `setpanel.ps1` | メインのレイアウト処理を編集したい |
| `setpanel-menu.ps1` | 対話メニューの表示や入力処理を編集したい |

## 使い方

```cmd
setpanel                     # 4 ペイン (2x2 grid) — デフォルト
setpanel -d C:\work -ps 4    # C:\work でペインを開く
setpanel -ps 3               # PowerShell ペイン 3 つ
setpanel -ps 6               # 6 ペイン (2x3 grid)
setpanel -ps 2 -bash 2       # 混在: pwsh 2 + bash 2 (2x2)
setpanel -ps 2 -wsl 2        # 混在: pwsh 2 + WSL 2
setpanel -ps 4 -bash 2       # 合計 6 ペイン (2x3)
```

- `-d DIR`, `-dir DIR`, `-cwd DIR` で全ペインの作業ディレクトリを指定
- `-ps N` で PowerShell ペインを N 個追加(1〜12)
- `-bash N` で Git Bash ペインを N 個追加(1〜12)
- `-wsl N` で WSL ペインを N 個追加(1〜12)
- 合計ペイン数の上限は **12**
- `-d` 未指定時は、呼び出し元シェルのカレントディレクトリで開く

## 対話メニュー

`setpanel-menu.bat` をダブルクリック、またはコマンドから実行すると、キーボードでプリセットを選べる:

```
> 1) ps 2 (side by side)
  2) ps 3
  3) ps 4 (2x2 grid)
  4) ps 6 (2x3 grid)
  5) ps 2 + bash 2
  6) ps 3 + bash 3
  7) Custom args
  8) Change working directory
  0) cancel
```

上下キーで移動し、Enter で決定する。1〜8 の数字キーでも直接選択できる。デフォルトでは現在のディレクトリで開き、別の場所で起動したい場合は `Change working directory` を選ぶ。

## デスクトップショートカット

ワンクリックでプリセット起動できる `.lnk` を一括生成:

```powershell
.\install-shortcuts.ps1
```

デスクトップに 6 個のショートカットが作られる:

| ショートカット | 実行内容 |
|---|---|
| `setpanel-ps2.lnk` | `setpanel -ps 2` |
| `setpanel-ps4.lnk` | `setpanel -ps 4` |
| `setpanel-ps6.lnk` | `setpanel -ps 6` |
| `setpanel-mixed.lnk` | `setpanel -ps 2 -bash 2` |
| `setpanel-wsl.lnk` | `setpanel -wsl 2` |
| `setpanel-menu.lnk` | 対話メニューを開く |

別の場所にインストールする例(スタートメニュー):

```powershell
.\install-shortcuts.ps1 -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\setpanel"
```

各ショートカットの作業フォルダは、デフォルトでは `$env:USERPROFILE`。`-WorkingDirectory <path>` で変更できる。後からショートカットのプロパティで編集してもよい。

## 設定

Git Bash のパスは `setpanel.ps1` の先頭付近にハードコードされている:

```powershell
$BASH = 'C:\Program Files\Git\bin\bash.exe'
```

別の場所にインストールしている場合はここを書き換える。指定パスに `bash.exe` が無い場合、`-bash` ペインは警告とともに PowerShell にフォールバックする。
WSL ペインは `wsl.exe --cd <dir>` で、既定のディストリビューションを起動する。

## 他のプラットフォーム

setpanel は Windows 専用。`wt.exe` に依存しており、Linux/macOS では使えない。
他 OS で同様のグリッドレイアウトが欲しい場合は以下を検討:

- [tmux](https://github.com/tmux/tmux) — 定番のターミナルマルチプレクサ
- [zellij](https://zellij.dev/) — 宣言的レイアウトを持つ最近のツール
- [wezterm](https://wezfurlong.org/wezterm/) — GPU アクセラレーション付き、CLI 制御も充実

## ライセンス

MIT — [LICENSE](LICENSE) を参照。

---

[English README](README.md)
