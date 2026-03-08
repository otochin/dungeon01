# dungeon01 作業ログ

このドキュメントは、プロジェクトに対する主な作業を時系列で記録する。

---

## 2025-03-08

### 1. 仕様書の作成

- **依頼**: コード全体を解析し、`/doc/` 配下に仕様書を出力する。
- **実施内容**:
  - プロジェクト全体（UEFN/Verse）の構造・設定ファイル・全 Verse ソースを解析。
  - `doc/SPECIFICATION.md` を新規作成。
    - 概要、プロジェクト構成、プロジェクト・プラグイン設定、各モジュール仕様（4.1～4.5）、データフロー・連携、エントリとライフサイクル、開発環境、改訂履歴を記載。
  - `doc/README.md` を新規作成（doc 配下の索引）。
- **成果物**: `doc/SPECIFICATION.md`, `doc/README.md`

---

### 2. GitHub へのコミット・プッシュ

- **依頼**: GitHub のプロジェクト「dungeon01」にコミットする。のちにリポジトリ URL が https://github.com/otochin/dungeon01 であると指定された。
- **実施内容**:
  - Git リポジトリを初期化（`git init`）。
  - `.gitignore` を追加（Binaries, DerivedDataCache, Intermediate, Saved, .vs, .vscode, .urc/）。
  - 全ファイルをステージし、`.urc/` は追跡対象外とするためインデックスから削除（`git rm -r --cached .urc`）。
  - リポジトリ用に `user.name` / `user.email` を設定（コミット用）。
  - 初回コミット実行: `Initial commit: dungeon01 UEFN project with specification doc`（539 ファイル）。
  - ブランチ名を `main` に変更。
  - リモートを `https://github.com/otochin/dungeon01.git` に設定し、`git push -u origin main` を実行。
- **結果**: プッシュ成功。コミットは https://github.com/otochin/dungeon01 に反映済み。
- **成果物**: ルートの `.gitignore`、リモート `origin` の設定。

---

### 3. npc_item_granter_switch デバイスの追加

- **依頼**: 以下のような Verse デバイスを作成する。
  - 設定項目: スイッチ、NPC スポナー、アイテム
  - スイッチを ON にすると、指定した NPC に指定したアイテムを装備させる
- **実施内容**:
  - 既存の `ally_stat_modifier.verse` のパターン（スイッチ＋スポナー、SpawnedEvent / TurnedOnEvent の購読）を参考に実装。
  - UEFN の `item_granter_device` が `GrantItem(Agent)` でエージェントにアイテムを付与する API であることを確認し、これを利用。
  - `Content/npc_item_granter_switch.verse` を新規作成。
    - クラス名: `npc_item_granter_switch_device`（creative_device）
    - @editable: Switch（switch_device）, NPCSpawner（npc_spawner_device）, ItemGranter（item_granter_device）
    - スイッチ ON 時に、スポーン済み NPC がいる場合に `ItemGranter.GrantItem(TargetAgent)` を実行。未スポーン時はログのみ出力。
- **成果物**: `Content/npc_item_granter_switch.verse`
- **仕様**: アイテムの種類はエディタで `item_granter_device` に登録（アイテムをドロップして設定）。詳細は `doc/SPECIFICATION.md` の「4.6 npc_item_granter_switch.verse」を参照。

---

### 4. 作業ログ・仕様書の更新

- **依頼**: これまでの作業ログを `/doc/` 配下に書き出し、必要に応じて仕様書を更新する。
- **実施内容**:
  - 本ファイル `doc/WORKLOG.md` を新規作成し、上記 1～3 の作業をまとめて記載。
  - `doc/SPECIFICATION.md` を更新:
    - 2.3 Verse ソースファイル一覧に `npc_item_granter_switch.verse` を追加。
    - 4.6 節「npc_item_granter_switch.verse」を追加（目的・クラス・@editable・挙動・依存・使い方）。
    - 5.2 エントリ・依存関係に npc_item_granter_switch を追記。
    - 8. 改訂履歴に 2025-03-08 の追記項目を追加。
  - `doc/README.md` の一覧に `WORKLOG.md` を追加。
- **成果物**: `doc/WORKLOG.md`、`doc/SPECIFICATION.md`（更新）、`doc/README.md`（更新）

---

### 5. random_switch_teleporter デバイスの追加と修正

- **依頼**: 複数スイッチを配列で設定し、オフのものをランダムに3つ選んでデバイス位置に横並び表示。いずれか1つがONになったら3つを非表示にし、設定したテレポーターを表示する。のちに「毎回違う3つ」「非表示」「角度90度」「高さ調整」などの要望に対応。
- **実施内容**:
  - `Content/random_switch_teleporter.verse` を新規作成。
  - **設定**: Switches（[]switch_device）、Teleporter（teleporter_device）、Spacing、HeightOffset。オフのスイッチのみを集め、その中から3つを選んでデバイス位置に横並びで配置（Enable/Disable で表示制御）。いずれかONで全スイッチを Disable し、テレポーターを Enable。
  - **スクリプトエラー対応**: GetRandomInt の no_rollback により transacts な OnBegin 内で使用不可のため、ランダム選択は断念。GetCreativeObjectsWithTag 非推奨・FindCreativeObjectsWithTag への置き換えは self/first/fail/break 等でエラーになるため ally_stat_modifier・npc_healer_behavior は従来 API のままに維持。switch_device/teleporter_device に Hide/Show がないため、非表示は「全スイッチを HiddenPosition（Z=-100000）へ TeleportTo してから Disable」で対応。rotation 同士の * が無いため、90度は MakeRotationFromYawPitchRollDegrees(90,0,0) のみを適用。GetTransform/TeleportTo の decides・失敗コンテキスト、配列アクセス・Mod の失敗コンテキストを整理。
  - **高さ**: HeightOffset（既定 120 cm）を追加し、スイッチを目の高さ付近に配置。
  - **角度**: スイッチの向きを Yaw 90 度に固定。
  - **非表示**: いずれかON時に全 Switches を HiddenPosition へ TeleportTo したうえで Disable。
  - **毎回違う3つ**: GetRandomInt が使えないため、GetSimulationElapsedTime() から開始インデックスを算出（Mod[Int[経過秒*1000]*1237, offList.Length]）。5つあれば5通りの組み合わせのいずれかが選ばれる。フォールバックで先頭3つを採用。
- **成果物**: `Content/random_switch_teleporter.verse`
- **依存**: Fortnite Devices、Verse Simulation、Verse、SpatialMath

---

### 6. バフ・スイッチデバイスの上昇値パラメータ化と random_switch_teleporter の表示処理明示

- **依頼**: healer buff / warrior HP buff / knight HP buff の各スイッチデバイスで上昇値をプロパティから指定可能にする。random_switch_teleporter で「最初にランダムに選んだ3つのスイッチの表示をオンにする」処理を追加。のちに GetCreativeObjectsWithTag 置き換えによるエラーを解消するため従来 API に戻す対応。
- **実施内容**:
  - **healer_buff_switch_device**: `@editable HealBonusAmount : float = 30.0` を追加。`AddHealerHeal(HealBonusAmount)` で適用。表示用に `HealBonusAmountAsInt()` と `HealBuffAppliedMessage` を追加（`ToInternalInt` は npc_health_hud のメソッドのため未使用・自前の int 変換に変更）。
  - **warrior_hp_buff_switch_device**: `@editable HpBonusAmount : float = 100.0` を追加。`GetMaxHealth() + HpBonusAmount` で適用。`WarriorHpBuffAppliedMessage` と `HpBonusAmountAsInt()` を追加。
  - **knight_hp_buff_switch_device**: `@editable HpBonusAmount : float = 80.0` を追加。同様に `KnightHpBuffAppliedMessage` と `HpBonusAmountAsInt()` を追加。
  - **FindCreativeObjectsWithTag への置き換え**: ally_stat_modifier と npc_healer_behavior で `FindCreativeObjectsWithTag`（generator）を使うよう変更したが、`self` 未定義・複数オーバーロード・`for` の第一引数が generator でない・失敗コンテキスト内の return/fail 等でエラーが発生。従来の `GetCreativeObjectsWithTag` に戻した（非推奨警告は残る）。
  - **random_switch_teleporter_device**: 「最初に、ランダムに選んだ３つのスイッチの表示をオンにする」処理をコメント付きブロックで明示。選定後に全スイッチを Disable → VisibleSwitches のみ Enable → 表示位置へ TeleportTo の流れを整理。
  - **doc/SPECIFICATION.md**: healer_buff_switch_device / warrior_hp_buff_switch_device / knight_hp_buff_switch_device の @editable 一覧と OnSwitchTurnedOn の説明を更新。
- **成果物**: `Content/ally_stat_modifier.verse`（更新）、`Content/npc_healer_behavior.verse`（FindHUD を GetCreativeObjectsWithTag に戻す）、`Content/random_switch_teleporter.verse`（表示オン処理の明示）、`doc/SPECIFICATION.md`（更新）

---

## 今後の追記について

大きな変更やリリースごとに、日付と実施内容をこの WORKLOG に追記することを推奨する。
