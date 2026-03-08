using { /Fortnite.com/AI }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation/Tags }

# 補助クラス：プレイスペースから全プレイヤーを取得する用
_HealerPlayspaceGetter := class(creative_device):
    GetPlayersInPlayspace()<transacts> : []agent =
        return GetPlayspace().GetPlayers()

# NPCが自分・仲間NPC・プレイヤーを回復する挙動
npc_healer_behavior := class(npc_behavior):

    @editable HealRatio : float = 0.5   # 回復対象: 現在HPが最大HPのこの割合以下になったら回復 (0.5 = 50%)
    @editable HealAmount : float = 50.0
    @editable HealRange : float = 1000.0
    @editable CooldownTime : float = 8.0
    @editable AllySpawners : []npc_spawner_device = array{}
    @editable HealSound : audio_player_device = audio_player_device{}
    
    var TrackedAllies : []?agent = array{}

    # --- GetCreativeObjectsWithTag を使用（GetPlayspace().GetObjectsWithTag は AI コンテキストで未定義のため）---
    FindHUD()<decides><transacts> : npc_health_hud = {
        # 1. グローバルの GetCreativeObjectsWithTag を使用
        HUDObjects := GetCreativeObjectsWithTag(health_hud_tag{});
        
        # 2. 配列の最初の要素を取得
        FirstHUDObj := HUDObjects[0];
        
        # 3. 直接 npc_health_hud クラスへキャストして返す
        # [ ] 構文によるキャストは失敗の可能性があるため、<decides> 関数内で評価可能です
        npc_health_hud[FirstHUDObj]
    }

    # 調査ログ用
    HealDebugMessage<localizes>(HPCur : int, HPMax : int, B : int, EffHeal : int) : message =
        "Heal: HP {HPCur}/{HPMax} Bonus={B} EffectiveHeal={EffHeal}"

    HealDebugInt(F : float) : int =
        if (I := Int[F]):
            return I
        return 0

    OnBegin<override>()<suspends> : void = {
        if (HealerAgent := GetAgent[]) {
            for (Spawner : AllySpawners) {
                Spawner.SpawnedEvent.Subscribe(OnAllyNPCSpawned)
            }
            
            loop {
                Sleep(2.0)
                if (HealerChar := HealerAgent.GetFortCharacter[]) {
                    var PotentialTargets : []fort_character = array{}
                    
                    # プレイヤーをリストに追加
                    for (P : _HealerPlayspaceGetter{}.GetPlayersInPlayspace()) {
                        if (FC := P.GetFortCharacter[]) { set PotentialTargets += array{FC} }
                    }
                    
                    # 追跡中の仲間NPCをリストに追加
                    for (MaybeAlly : TrackedAllies) {
                        if (AllyAgent := MaybeAlly?, FC := AllyAgent.GetFortCharacter[]) {
                            set PotentialTargets += array{FC}
                        }
                    }
                    
                    # 自分自身（Healer）をリストに追加
                    set PotentialTargets += array{HealerChar}

                    HealerPos := HealerChar.GetTransform().Translation
                    var HealedSomeone : logic = false

                    for (TargetChar : PotentialTargets) {
                        if (HealedSomeone = false) {
                            TargetPos := TargetChar.GetTransform().Translation
                            Dist := Distance(HealerPos, TargetPos)
                            CurrentHP := TargetChar.GetHealth()
                            MaxHP := TargetChar.GetMaxHealth()
                            # 仲間ごとの最大HPの HealRatio 以下（例: 半分以下）かつ生存していれば回復対象
                            if (Dist < HealRange, CurrentHP <= MaxHP * HealRatio, CurrentHP > 0.0) {
                                # 回復を実行（基本値 + HUD に保存された補正。スイッチが HUD.AddHealerHeal(30) で書き込む）
                                var Bonus : float = 0.0
                                if (HUD := FindHUD[]):
                                    set Bonus = HUD.GetHealerHealBonus()
                                EffectiveHeal := HealAmount + Bonus
                                # 調査ログ: 誰に・何ポイント回復したか（Bonus=補正、EffectiveHeal=実際の回復量）
                                Print(HealDebugMessage(HealDebugInt(CurrentHP), HealDebugInt(MaxHP), HealDebugInt(Bonus), HealDebugInt(EffectiveHeal)))
                                TargetChar.Heal(EffectiveHeal)
                                
                                # 音を鳴らす
                                for (Player : _HealerPlayspaceGetter{}.GetPlayersInPlayspace()) {
                                    HealSound.Play(Player)
                                }
                                
                                # HUDにクールタイムを通知
                                if (HUD := FindHUD[]) {
                                    HUD.StartHealCooldown(CooldownTime)
                                }
                                
                                set HealedSomeone = true
                            }
                        }
                    }
                    
                    if (HealedSomeone?) {
                        Sleep(CooldownTime)
                    }
                }
            }
        }
    }

    OnAllyNPCSpawned(Agent : agent) : void = {
        set TrackedAllies += array{option{Agent}}
    }