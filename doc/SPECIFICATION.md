# dungeon01 仕様書

## 1. 概要

### 1.1 プロジェクト種別

| 項目 | 内容 |
|------|------|
| 種別 | UEFN (Unreal Editor for Fortnite) / Verse |
| 用途 | Fortnite Creative 用ダンジョン風体験（ソロプレイ想定） |
| プラグイン名 | dungeon01 |
| Verse パス | `/whys@fortnite.com/dungeon01` |
| API アクセス | Private |
| 互換バージョン | 39.50 |

### 1.2 概要説明

本プロジェクトは、Fortnite Creative 上でソロプレイを想定したダンジョン風体験を提供する UEFN プロジェクトである。仲間 NPC パーティ（Knight / Warrior / Healer）の HP 表示・回復・バフ・テレポート連携・撃破トラッカー連動を Verse で実装している。

- **マッチメイキング**: 最大 1 プレイヤー、1 チーム、ソロ想定
- **エントリ**: マップに配置された各 `creative_device` の `OnBegin` が起動時に実行される（明示的な main.verse はない）

---

## 2. プロジェクト構成

### 2.1 ディレクトリ・ファイル一覧

| パス | 種別 | 説明 |
|------|------|------|
| `Content/` | ソース | 全 Verse ソース（`.verse`）の配置場所 |
| `.urc/` | 設定 | URC（Unreal Remote Control）用設定・ID |
| `doc/` | ドキュメント | 本仕様書等 |

### 2.2 主要設定ファイル

| ファイル | 役割 |
|----------|------|
| `dungeon01.uefnproject` | UEFN プロジェクト定義（マッチメイキング、Verse パス、プラグイン参照） |
| `dungeon01.uplugin` | Verse プラグイン定義（VersePath、SceneGraph 有効化など） |
| `dungeon01.code-workspace` | VS Code ワークスペース（Content/ 参照、Verse デバッグ設定） |
| `.urc/config.toml` | URC リモート URL・identity・store/file 設定 |
| `.urcignore` | URC 追跡対象外の指定 |

### 2.3 Verse ソースファイル一覧

| ファイル | 主なクラス・役割 |
|----------|------------------|
| `Content/npc_health_hud.verse` | 仲間 NPC 3 体の HP とヒーラー用クールダウンを HUD 表示。`health_hud_tag` を定義 |
| `Content/ally_stat_modifier.verse` | ヒーラー回復バフ・Warrior/Knight の最大 HP バフをスイッチで付与 |
| `Content/npc_healer_behavior.verse` | ヒーラー NPC が自分・仲間・プレイヤーを範囲内で回復。HUD と連携 |
| `Content/npc_teleport_handler.verse` | プレイヤーがテレポートしたときに生存 NPC をプレイヤー周囲に円形オフセットで再配置 |
| `Content/elimination_debugger.verse` | 撃破マネージャーの撃破イベントをトラッカーの進捗 +1 に橋渡し |
| `Content/npc_item_granter_switch.verse` | スイッチ ON で指定 NPC に item_granter_device のアイテムを付与 |
| `Content/random_switch_teleporter.verse` | オフのスイッチから経過時間で3つを選び横並び表示。いずれかONで全スイッチ非表示＋テレポーター表示 |

---

## 3. プロジェクト・プラグイン設定

### 3.1 dungeon01.uefnproject

- **fileVersion**: 15
- **title**: dungeon01
- **apiAccess**: Private
- **compatibilityVersion**: 39.50
- **plugins**: ルートプラグイン `dungeon01`（bIsRoot: true, bIsPublic: false）
- **matchmaking**:
  - maxPlayers: 1, maxTeamCount: 1, maxTeamSize: 1
  - allowJoinInProgress: true, allowSquadFillOption: false
  - islandQueuePrivacy: Public
  - useSkillBasedMatchmaking: false
- **experimental.sceneGraph**: bIsSceneGraphSystemAllowed: true
- **bindings**:
  - projectId: `8d144710-423e-a2d2-a9a7-97bcc25841eb`
  - modules.dungeon01: `be4d4b62-40d0-bdb0-1c6c-a29f99c2057b`
  - projectVersePath: `/whys@fortnite.com/dungeon01`

### 3.2 dungeon01.uplugin

- **VersePath**: `/whys@fortnite.com/dungeon01`
- **EnableVerseAssetReflection**: true
- **EnableSceneGraph**: true
- **CanContainVerse**: true

### 3.3 URC 設定 (.urc/config.toml)

- **remote_url**: urcs://urc-uefn.live.ucs.on.epicgames.com
- **store**: max_capacity, eviction_delay, max_size, compaction_delay
- **file**: direct_write / direct_io / flush_write は false

---

## 4. モジュール仕様

### 4.1 npc_health_hud.verse

#### 目的

仲間 NPC 3 体の HP と、ヒーラーのクールダウン・回復力を HUD に表示する。`health_hud_tag` を定義し、他モジュール（`ally_stat_modifier`、`npc_healer_behavior`）からタグで検索される。

#### タグ

- `health_hud_tag` — 本 HUD デバイスを一意に識別するためのタグ（class(tag)）

#### クラス: npc_health_hud (creative_device)

| 種別 | 名前 | 型 | 説明 |
|------|------|-----|------|
| @editable | AllySpawner1～3 | npc_spawner_device | 仲間 NPC 用スポナー 3 つ |
| @editable | Name1～3 | string | 表示名（既定: "Knight", "Warrior", "Healer"） |
| @editable | HealerBaseHealAmount | float | ヒーラー基本回復量表示用（既定: 50.0）。npc_healer_behavior の HealAmount と揃えると分かりやすい |
| var | Ally1Agent～3Agent | ?agent | スポーンした仲間のエージェント参照 |
| var | HPTextBlocks | []text_block | HUD 用テキストブロック配列 |
| var | HealerCooldown | float | ヒーラークールダウン残り時間（秒） |
| var | HealerHealBonus | float | ヒーラー回復ボーナス（スイッチ等で加算） |

#### 主要メソッド

- **AddHealerHeal(Amount: float)**: HealerHealBonus に Amount を加算
- **GetHealerHealBonus()**: HealerHealBonus を返す
- **StartHealCooldown(Duration: float)**: クールダウンを Duration 秒で開始
- **OnBegin**: 各スポナーの SpawnedEvent を購読、プレイヤーごとに UpdateHUDLoop を spawn
- **UpdateHUDLoop(Player)**: 0.2 秒ごとに HealerCooldown を減算し、RefreshHPValues で HUD 更新
- **RefreshHPValues**: 各仲間の生存・HP に応じてテキストと色を更新（赤/黄/白/灰）。ヒーラー行は回復力（HealerBaseHealAmount + HealerHealBonus）も表示

#### 表示仕様

- 生存判定: `GetHealth() > 0.0`（IsEliminated は使わない）
- HP が最大の 1/3 未満で赤、最大未満で黄、最大で白。死亡または未スポーンは灰で 0/0 表示
- ヒーラー行のみ「回復力: N」を表示し、クールダウン中は「[Ns]」を付加

#### 依存

- Fortnite Devices / Characters / UI、Verse Simulation / Colors、SpatialMath、Tags

---

### 4.2 ally_stat_modifier.verse

#### 目的

スイッチを ON にすることで、ヒーラーの回復ボーナスまたは Warrior/Knight の最大 HP を 1 回だけ増加させるデバイスを提供する。HUD は `health_hud_tag` で検索して同一インスタンスに書き込む。

#### クラス一覧

**healer_buff_switch_device**

| 種別 | 名前 | 型 | 説明 |
|------|------|-----|------|
| @editable | Switch | switch_device | トリガーとなるスイッチ |
| @editable | HealBonusAmount | float | ヒーラー回復ボーナスの上昇値（既定: 30.0） |
| var | AlreadyApplied | logic | 1 回だけ適用するためのフラグ |

- **FindHUDByTag()** (decides, transacts): GetCreativeObjectsWithTag(health_hud_tag{}) で HUD を取得し、npc_health_hud にキャストして返す
- **OnSwitchTurnedOn**: AlreadyApplied が false のとき、FindHUDByTag で HUD を取得し AddHealerHeal(HealBonusAmount) を実行。AlreadyApplied を true に設定（1 回限り）

**warrior_hp_buff_switch_device**

| 種別 | 名前 | 型 | 説明 |
|------|------|-----|------|
| @editable | Switch | switch_device | トリガーとなるスイッチ |
| @editable | WarriorSpawner | npc_spawner_device | Warrior 用スポナー |
| @editable | HpBonusAmount | float | 最大HPの上昇値（既定: 100.0） |
| var | WarriorAgent | ?agent | スポーンした Warrior |
| var | AlreadyApplied | logic | 1 回だけ適用するためのフラグ |

- **OnWarriorSpawned**: スポーン時に WarriorAgent を保存
- **OnSwitchTurnedOn**: Warrior がスポーン済みなら GetMaxHealth() + HpBonusAmount を SetMaxHealth で設定。1 回限り

**knight_hp_buff_switch_device**

| 種別 | 名前 | 型 | 説明 |
|------|------|-----|------|
| @editable | Switch | switch_device | トリガーとなるスイッチ |
| @editable | KnightSpawner | npc_spawner_device | Knight 用スポナー |
| @editable | HpBonusAmount | float | 最大HPの上昇値（既定: 80.0） |
| var | KnightAgent | ?agent | スポーンした Knight |
| var | AlreadyApplied | logic | 1 回だけ適用するためのフラグ |

- **OnKnightSpawned**: スポーン時に KnightAgent を保存
- **OnSwitchTurnedOn**: Knight がスポーン済みなら GetMaxHealth() + HpBonusAmount を SetMaxHealth で設定。1 回限り

#### 依存

- Fortnite Devices / Characters、Verse Simulation、Tags（health_hud_tag は npc_health_hud.verse で定義）

---

### 4.3 npc_healer_behavior.verse

#### 目的

ヒーラー NPC が自分・仲間 NPC・プレイヤーを範囲内で回復する挙動を実装する。回復量は HUD に保存された HealerHealBonus と連携し、クールダウンは HUD に通知して表示する。

#### 補助クラス: _HealerPlayspaceGetter

- **GetPlayersInPlayspace()** (transacts): GetPlayspace().GetPlayers() を返す（AI コンテキストでプレイヤー取得用）

#### クラス: npc_healer_behavior (npc_behavior)

| 種別 | 名前 | 型 | 説明 |
|------|------|-----|------|
| @editable | HealRatio | float | 回復対象の閾値（現在 HP ≤ 最大 HP × HealRatio）。既定: 0.5 |
| @editable | HealAmount | float | 基本回復量。既定: 50.0 |
| @editable | HealRange | float | 回復可能距離（cm）。既定: 1000.0 |
| @editable | CooldownTime | float | 回復後のクールダウン（秒）。既定: 8.0 |
| @editable | AllySpawners | []npc_spawner_device | 仲間 NPC のスポナー配列 |
| @editable | HealSound | audio_player_device | 回復時に再生する音 |
| var | TrackedAllies | []?agent | スポーンした仲間のエージェント参照 |

- **FindHUD()** (decides, transacts): GetCreativeObjectsWithTag(health_hud_tag{}) で HUD を取得し、npc_health_hud にキャストして返す
- **OnBegin**: GetAgent でヒーラーを取得後、AllySpawners の SpawnedEvent を購読。2 秒間隔でループし、プレイヤー・TrackedAllies・自分を PotentialTargets に集め、HealRange 内で HP ≤ MaxHP×HealRatio かつ生存している対象に HealAmount + HUD.GetHealerHealBonus() で回復。回復時に HealSound 再生、HUD.StartHealCooldown(CooldownTime) を呼び、HealedSomeone なら CooldownTime だけ Sleep
- **OnAllyNPCSpawned**: TrackedAllies にスポーンしたエージェントを追加

#### 回復条件

- 距離 < HealRange
- CurrentHP ≤ MaxHP * HealRatio
- CurrentHP > 0.0（生存）

#### 依存

- Fortnite AI / Characters / Devices / Playspaces、Verse Simulation、SpatialMath、Tags

---

### 4.4 npc_teleport_handler.verse

#### 目的

複数の NPC スポナーと複数のテレポーターに対応し、プレイヤーがテレポートしたときに生存している NPC をプレイヤー位置の周囲に円形オフセットで再配置する。

#### クラス: npc_teleport_handler (creative_device)

| 種別 | 名前 | 型 | 説明 |
|------|------|-----|------|
| @editable | NPCSpawners | []npc_spawner_device | NPC スポナーのリスト |
| @editable | TriggerTeleporters | []teleporter_device | トリガーとなるテレポーターのリスト |
| @editable | OffsetDistance | float | NPC を配置する円の半径（cm）。既定: 150.0 |
| var | ActiveNPCs | []agent | 現在生存している NPC のリスト |

- **OnBegin**: 全 NPCSpawners の SpawnedEvent を購読、全 TriggerTeleporters の TeleportedEvent を購読
- **OnNPCSpawned**: ActiveNPCs に追加し、EliminatedEvent を購読
- **OnNPCEliminated**: 撃破された NPC を ActiveNPCs から除去
- **OnPlayerTeleported**: プレイヤーの Transform を取得し、ActiveNPCs の各 NPC を円状に配置（角度 = (Index / Length) * 2π、OffsetDistance で X/Y オフセット）。NPC の TeleportTo で移動

#### 依存

- Fortnite Devices / Characters / Game、Verse Simulation、SpatialMath

---

### 4.5 elimination_debugger.verse

#### 目的

撃破マネージャー（elimination_manager_device）の撃破イベントを購読し、誰が倒したかに関係なくトラッカー（tracker_device）の進捗を 1 進める橋渡しを行う。

#### クラス: elimination_debugger (creative_device)

| 種別 | 名前 | 型 | 説明 |
|------|------|-----|------|
| @editable | TargetEliminationManager | elimination_manager_device | 監視対象の撃破マネージャー |
| @editable | TargetTracker | tracker_device | 進捗を更新するトラッカー |

- **OnBegin**: TargetEliminationManager.EliminatedEvent.Subscribe(OnEliminated)
- **OnEliminated**: GetPlayspace().GetPlayers() の先頭プレイヤーを渡して TargetTracker.Increment(FirstPlayer) を呼ぶ（Sharing が「すべて」の場合はチーム全体の進捗としてカウントされる想定）

#### 依存

- Fortnite Devices / Characters、Verse Simulation

---

### 4.6 npc_item_granter_switch.verse

#### 目的

スイッチを ON にすると、指定した NPC スポナーからスポーンしている NPC に、指定したアイテムを付与（装備）する。アイテムの種類は `item_granter_device` 側でエディタから設定する。

#### クラス: npc_item_granter_switch_device (creative_device)

| 種別 | 名前 | 型 | 説明 |
|------|------|-----|------|
| @editable | Switch | switch_device | トリガーとなるスイッチ |
| @editable | NPCSpawner | npc_spawner_device | アイテムを付与する NPC のスポナー |
| @editable | ItemGranter | item_granter_device | 付与するアイテムを登録したアイテムグランター |
| var | SpawnedAgent | ?agent | スポーンした NPC のエージェント参照 |

- **OnBegin**: NPCSpawner の SpawnedEvent と Switch の TurnedOnEvent を購読
- **OnNPCSpawned**: SpawnedAgent にスポーンしたエージェントを保存
- **OnSwitchTurnedOn**: SpawnedAgent が存在すれば ItemGranter.GrantItem(TargetAgent) を実行。未スポーン時はログのみ出力

#### 使い方（エディタ）

1. マップに npc_item_granter_switch、NPC スポナー、アイテムグランターを配置する。
2. アイテムグランターに付与したいアイテムを登録する（デバイスにアイテムをドロップして設定）。
3. npc_item_granter_switch の詳細で Switch・NPCSpawner・ItemGranter に上記デバイスを割り当てる。
4. ゲーム中に NPC をスポーンさせたあと、スイッチを ON にするとその NPC にアイテムが付与される。

#### 依存

- Fortnite Devices / Characters、Verse Simulation

---

### 4.7 random_switch_teleporter.verse

#### 目的

複数スイッチを配列で設定し、オフのものから「経過時間ベースのオフセット」で3つを選び、デバイス位置に横並びで表示する。いずれか1つでもONになると全スイッチを無表示（マップ外へ移動＋無効化）し、設定したテレポーターを有効化する。GetRandomInt の no_rollback 制約のため真の乱数は使わず、GetSimulationElapsedTime() で開始インデックスを変え、毎回異なる3つの組み合わせになり得るようにしている。

#### クラス: random_switch_teleporter_device (creative_device)

| 種別 | 名前 | 型 | 説明 |
|------|------|-----|------|
| @editable | Switches | []switch_device | 候補となるスイッチの配列 |
| @editable | Teleporter | teleporter_device | いずれかON時に表示するテレポーター |
| @editable | Spacing | float | 横並びの間隔（cm）。既定: 200.0 |
| @editable | HeightOffset | float | スイッチの高さオフセット（cm）。既定: 120.0 |
| var | VisibleSwitches | []switch_device | 今回表示している3つ（以下） |
| 定数 | HiddenPosition | vector3 | 非表示用の位置（Z=-100000 等） |
| 定数 | HiddenRotation | rotation | 非表示時の回転 |

- **OnBegin**: テレポーターを Disable。Switches のうち GetCurrentState が失敗する（オフの）ものを offList に集める。offList が4以上なら Int[GetSimulationElapsedTime()*1000]*1237 を Mod[..., offList.Length] して開始 offset を決め、offset から連続3つ（ループ）を selected とし、selected が空なら先頭3つを採用。VisibleSwitches に設定。全 Switches を Disable したうえで VisibleSwitches のみ Enable。デバイスの GetTransform() から位置を取得し、VisibleSwitches を Spacing・HeightOffset で横並びに TeleportTo（回転は Yaw 90度）。VisibleSwitches の TurnedOnEvent を購読。
- **OnAnyVisibleSwitchTurnedOn**: 全 Switches を HiddenPosition へ TeleportTo してから Disable。テレポーターを Enable。

#### 選択ロジック

- オフのスイッチが4つ以上あるとき、開始インデックスを `Mod[Int[GetSimulationElapsedTime()*1000]*1237, offList.Length]` で算出。その位置から「連続3つ」（末尾で先頭にループ）を選ぶ。5つなら5通りの組み合わせのいずれかになる。
- オフが3つ以下ならそのまま全て採用。Int/Mod が失敗した場合は先頭3つをフォールバック。

#### 非表示について

- switch_device に Hide/Show がないため、非表示は「HiddenPosition（Z=-100000 等）へ TeleportTo したうえで Disable」で実現している。

#### 依存

- Fortnite Devices、Verse Simulation、Verse（Mod）、SpatialMath

---

## 5. データフロー・モジュール連携

### 5.1 HUD を中心とした連携

```
[ally_stat_modifier]
  healer_buff_switch_device → FindHUDByTag(health_hud_tag) → npc_health_hud.AddHealerHeal(HealBonusAmount)

[npc_healer_behavior]
  FindHUD() → npc_health_hud.GetHealerHealBonus() で回復量に加算
  FindHUD() → npc_health_hud.StartHealCooldown(CooldownTime) でクールダウン表示
```

- ヒーラー回復量の「見た目」と「実際の計算」は `npc_health_hud` が保持する HealerHealBonus で一致させる。
- `ally_stat_modifier` のスイッチで +30 すると、HUD 表示の回復力と `npc_healer_behavior` の EffectiveHeal（HealAmount + Bonus）が連動する。

### 5.2 エントリ・依存関係

- **npc_health_hud**: タグ `health_hud_tag` を定義。他からタグで検索される中心。
- **ally_stat_modifier**: `health_hud_tag` で HUD を取得してヒーラーバフ適用。Knight/Warrior は各スポナー経由で HP バフ適用。
- **npc_healer_behavior**: `health_hud_tag` で HUD を取得し、クールダウン表示・回復力ボーナス連携。
- **npc_teleport_handler**: スポナー・テレポーターのイベント購読のみ。他モジュールからは参照されない。
- **elimination_debugger**: 撃破マネージャーとトラッカーを接続。他モジュールからは参照されない。
- **npc_item_granter_switch**: スイッチ・NPC スポナー・アイテムグランターをエディタで指定。他モジュールからは参照されない。
- **random_switch_teleporter**: スイッチ配列・テレポーターをエディタで指定。経過時間で表示する3スイッチを決定。他モジュールからは参照されない。

### 5.3 デバイス配置

- 各デバイスは UEFN エディタ上でマップに配置し、@editable のスポナー・スイッチ・テレポーター・撃破マネージャー・トラッカー等をエディタで指定する。
- `npc_health_hud` には `health_hud_tag` を付与し、同じマップに 1 インスタンス配置する想定（タグ検索で取得するため）。

---

## 6. エントリポイントとライフサイクル

- **起動**: UEFN 上でマップ/プレイスペースが開始されると、配置された各 `creative_device` の `OnBegin` が呼ばれる。
- **明示的な main.verse は存在しない**。デバイス単位で Subscribe と spawn により動作する。
- ヒーラー挙動は `npc_healer_behavior` の OnBegin 内で 2 秒間隔のループと Sleep(CooldownTime) により継続実行される。
- HUD はプレイヤーごとに UpdateHUDLoop が spawn され、0.2 秒間隔で HealerCooldown 減算と RefreshHPValues が行われる。

---

## 7. 開発環境

- **エディタ**: UEFN、VS Code（dungeon01.code-workspace で Content/ 等を参照）
- **Verse デバッグ**: ワークスペースで attach、port 1961 等の設定を利用可能
- **URC**: .urc/config.toml でリモート URL と identity を設定。.urcignore でビルド成果物・.git・アセット等を追跡対象外にできる
- **ドキュメント**: 本仕様書（doc/SPECIFICATION.md）。コード内には日本語コメントで実装意図を記載

---

## 8. 改訂履歴

| 日付 | 内容 |
|------|------|
| 2025-03-08 | 初版作成（コード全体解析に基づく） |
| 2025-03-08 | npc_item_granter_switch.verse を追加（4.6 節・2.3 一覧・5.2）。作業ログ（WORKLOG.md）作成に伴い doc を更新 |
| 2025-03-08 | random_switch_teleporter.verse を追加（4.7 節・2.3 一覧・5.2）。経過時間で3スイッチ選択・非表示・90度回転・高さオフセット。作業ログに 5 を追記 |
