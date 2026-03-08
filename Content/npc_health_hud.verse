using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/UI }
using { /Fortnite.com/Game }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation/Tags }

# タグの定義
health_hud_tag := class(tag){}

# 仲間のNPCのHPと、ヒーラーのクールタイムを表示するデバイス
npc_health_hud := class(creative_device):

    @editable AllySpawner1 : npc_spawner_device = npc_spawner_device{}
    @editable AllySpawner2 : npc_spawner_device = npc_spawner_device{}
    @editable AllySpawner3 : npc_spawner_device = npc_spawner_device{}

    @editable Name1 : string = "Knight"
    @editable Name2 : string = "Warrior"
    @editable Name3 : string = "Healer"

    # 回復力表示用（Healer の基本回復量。npc_healer_behavior の HealAmount と揃えると分かりやすい）
    @editable HealerBaseHealAmount : float = 50.0

    var Ally1Agent : ?agent = false
    var Ally2Agent : ?agent = false
    var Ally3Agent : ?agent = false

    var HPTextBlocks : []text_block = array{}
    var HealerCooldown : float = 0.0
    var HealerHealBonus : float = 0.0

    AddHealerHeal(Amount : float) : void =
        set HealerHealBonus += Amount

    GetHealerHealBonus() : float =
        return HealerHealBonus

    OnBegin<override>() : void =
        AllySpawner1.SpawnedEvent.Subscribe(OnAlly1Spawned)
        # 修正箇所: SpawnedEvent を介して Subscribe するように変更
        AllySpawner2.SpawnedEvent.Subscribe(OnAlly2Spawned)
        AllySpawner3.SpawnedEvent.Subscribe(OnAlly3Spawned)

        for (Player : GetPlayspace().GetPlayers()):
            spawn{ UpdateHUDLoop(Player) }

    StartHealCooldown(Duration : float) : void =
        set HealerCooldown = Duration

    # --- 修正箇所: スポーン時に死亡イベントも購読するように変更 ---
    OnAlly1Spawned(Agent : agent) : void =
        set Ally1Agent = option{Agent}
        if (FC := Agent.GetFortCharacter[]):
            FC.EliminatedEvent().Subscribe(OnAlly1Eliminated)

    OnAlly1Eliminated(Result : elimination_result) : void =
        set Ally1Agent = false # 死亡したらすぐに参照を消す

    OnAlly2Spawned(Agent : agent) : void =
        set Ally2Agent = option{Agent}
        if (FC := Agent.GetFortCharacter[]):
            FC.EliminatedEvent().Subscribe(OnAlly2Eliminated)

    OnAlly2Eliminated(Result : elimination_result) : void =
        set Ally2Agent = false

    OnAlly3Spawned(Agent : agent) : void =
        set Ally3Agent = option{Agent}
        if (FC := Agent.GetFortCharacter[]):
            FC.EliminatedEvent().Subscribe(OnAlly3Eliminated)

    OnAlly3Eliminated(Result : elimination_result) : void =
        set Ally3Agent = false

    UpdateHUDLoop(Player : player)<suspends> : void =
        if (PlayerUI := GetPlayerUI[Player]):
            NewCanvas := CreateCanvas()
            PlayerUI.AddWidget(NewCanvas)

            loop:
                Sleep(0.2)
                if (HealerCooldown > 0.0):
                    set HealerCooldown -= 0.2
                    if (HealerCooldown < 0.0):
                        set HealerCooldown = 0.0
                RefreshHPValues()

    CreateCanvas() : canvas =
        var StackChildren : []stack_box_slot = array{}
        Names := array{Name1, Name2, Name3}
        for (Name : Names):
            NewText := text_block{DefaultText := GetHPMessage(Name, 0, 0, ""), DefaultTextColor := NamedColors.White}
            set HPTextBlocks += array{NewText}
            set StackChildren += array:
                stack_box_slot:
                    Widget := NewText
                    Padding := margin{Top := 5.0, Bottom := 5.0}

        return canvas:
            Slots := array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.02, Y := 0.4}, Maximum := vector2{X := 0.02, Y := 0.4}}
                    Alignment := vector2{X := 0.0, Y := 0.5}
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := StackChildren

    RefreshHPValues() : void =
        Agents := array{Ally1Agent, Ally2Agent, Ally3Agent}
        Names := array{Name1, Name2, Name3}

        for (Index -> MaybeAgent : Agents):
            if (TextWidget := HPTextBlocks[Index], TargetName := Names[Index]):
                var CDString : string = ""
                if (Index = 2, HealerCooldown > 0.0):
                    set CDString = " [{ToInternalInt(HealerCooldown)}s]"

                # --- 修正箇所: IsEliminated ではなく HP が 0 より大きいかで生存判定を行う ---
                if (A := MaybeAgent?, FortChar := A.GetFortCharacter[], FortChar.GetHealth() > 0.0):
                    CurrentHP := FortChar.GetHealth()
                    MaxHP := FortChar.GetMaxHealth()
                    
                    if (CurrentHP < (MaxHP / 3.0)):
                        TextWidget.SetTextColor(NamedColors.Red)
                    else if (CurrentHP < MaxHP):
                        TextWidget.SetTextColor(NamedColors.Yellow)
                    else:
                        TextWidget.SetTextColor(NamedColors.White)
                    
                    if (Index = 2):
                        TextWidget.SetText(GetHealerLineMessage(TargetName, ToInternalInt(CurrentHP), ToInternalInt(MaxHP), CDString, ToInternalInt(HealerBaseHealAmount + HealerHealBonus)))
                    else:
                        TextWidget.SetText(GetHPMessage(TargetName, ToInternalInt(CurrentHP), ToInternalInt(MaxHP), CDString))
                else:
                    # NPCがいない、または死亡している場合は 0 / 0 表示にする
                    TextWidget.SetTextColor(NamedColors.Gray)
                    if (Index = 2):
                        TextWidget.SetText(GetHealerLineMessage(TargetName, 0, 0, "", ToInternalInt(HealerBaseHealAmount + HealerHealBonus)))
                    else:
                        TextWidget.SetText(GetHPMessage(TargetName, 0, 0, ""))

    GetHPMessage<localizes>(Name: string, HP: int, MaxHP: int, CD: string) : message = "{Name}: {HP} / {MaxHP}{CD}"

    GetHealerLineMessage<localizes>(Name: string, HP: int, MaxHP: int, CD: string, HealPower: int) : message = "{Name}: {HP} / {MaxHP}{CD} 回復力:{HealPower}"

    ToInternalInt(F : float) : int =
        if (I := Int[F]):
            return I
        return 0