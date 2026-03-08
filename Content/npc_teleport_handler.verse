using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

# 複数のテレポーターと複数のNPCスポナーに対応したデバイス
npc_teleport_handler := class(creative_device):

    # NPCスポナーのリスト
    @editable
    NPCSpawners : []npc_spawner_device = array{}

    # トリガーとなるテレポーターのリスト
    @editable
    TriggerTeleporters : []teleporter_device = array{}

    # 各NPCを配置する際の距離（cm）
    @editable
    OffsetDistance : float = 150.0

    # 現在生存しているNPCを保持する変数
    var ActiveNPCs : []agent = array{}

    # デバイス開始時の処理
    OnBegin<override>() : void =
        # 配列内のすべてのスポナーのイベントを購読
        for (Spawner : NPCSpawners):
            Spawner.SpawnedEvent.Subscribe(OnNPCSpawned)

        # 配列内のすべてのテレポーターのイベントを購読
        for (Teleporter : TriggerTeleporters):
            Teleporter.TeleportedEvent.Subscribe(OnPlayerTeleported)

    # NPCがスポーンした時に呼び出される
    OnNPCSpawned(SpawnedAgent : agent) : void =
        set ActiveNPCs += array{SpawnedAgent}
        
        if (FortChar := SpawnedAgent.GetFortCharacter[]):
            FortChar.EliminatedEvent().Subscribe(OnNPCEliminated)

    # NPCが倒された時にリストを更新する
    OnNPCEliminated(Result : elimination_result) : void =
        if (EliminatedAgent := Result.EliminatedCharacter.GetAgent[]):
            var NewNPCList : []agent = array{}
            for (NPC : ActiveNPCs):
                if (NPC <> EliminatedAgent):
                    set NewNPCList += array{NPC}
            set ActiveNPCs = NewNPCList

    # いずれかのテレポーターでプレイヤーが移動した時の処理
    OnPlayerTeleported(PlayerAgent : agent) : void =
        if (PlayerChar := PlayerAgent.GetFortCharacter[]):
            PlayerTransform := PlayerChar.GetTransform()
            PlayerLocation := PlayerTransform.Translation
            PlayerRotation := PlayerTransform.Rotation

            Print("A player teleported. Moving NPCs with offsets...")

            # NPCのインデックス番号を利用して円状に配置
            for (Index -> NPCAgent : ActiveNPCs):
                if (NPCChar := NPCAgent.GetFortCharacter[]):
                    # 修正点: intに1.0を掛けることで安全にfloatに変換します
                    FloatIndex := Index * 1.0
                    FloatCount := ActiveNPCs.Length * 1.0
                    
                    # ゼロ除算を避けるためのチェック
                    if (FloatCount > 0.0):
                        # 円状に配置するための角度計算
                        Angle := (FloatIndex / FloatCount) * 2.0 * PiFloat
                        
                        OffsetX := OffsetDistance * Cos(Angle)
                        OffsetY := OffsetDistance * Sin(Angle)
                        
                        TargetLocation := PlayerLocation + vector3{X := OffsetX, Y := OffsetY, Z := 0.0}

                        # TeleportToの実行
                        if (NPCChar.TeleportTo[TargetLocation, PlayerRotation]):
                            Print("NPC moved to offset position")