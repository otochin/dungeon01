using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }

# スイッチをONにすると、タグで検索した HUD の HealerHealBonus が +30 になる装置（1回だけ）
# Healer と同じ health_hud_tag で HUD を探すので、必ず同じインスタンスに書き込める
healer_buff_switch_device := class(creative_device):

    @editable Switch : switch_device = switch_device{}

    var AlreadyApplied : logic = false

    # タグで HUD を取得（キャストが decides のため、失敗コンテキストで呼ぶ）
    FindHUDByTag()<decides><transacts> : npc_health_hud = {
        HUDObjects := GetCreativeObjectsWithTag(health_hud_tag{})
        First := HUDObjects[0]
        npc_health_hud[First]
    }

    OnBegin<override>() : void =
        Switch.TurnedOnEvent.Subscribe(OnSwitchTurnedOn)

    OnSwitchTurnedOn(Agent : agent) : void =
        if (AlreadyApplied = false):
            if (HUD := FindHUDByTag[]):
                HUD.AddHealerHeal(30.0)
                set AlreadyApplied = true
                Print("HealBuff: スイッチON。HUDに+30を適用しました。次の回復から Bonus=30, EffectiveHeal=80 になります。")
            else:
                Print("HealBuff: スイッチONだが、health_hud_tag の HUD が見つかりません。HUD にタグを付けてください。")


# スイッチをONにすると、Warrior の最大HPを +100 する装置（1回だけ）
# Warrior は WarriorSpawner でスポーンする想定。スポーン中の Warrior にのみ適用する
warrior_hp_buff_switch_device := class(creative_device):

    @editable Switch : switch_device = switch_device{}
    @editable WarriorSpawner : npc_spawner_device = npc_spawner_device{}

    var WarriorAgent : ?agent = false
    var AlreadyApplied : logic = false

    OnBegin<override>() : void =
        WarriorSpawner.SpawnedEvent.Subscribe(OnWarriorSpawned)
        Switch.TurnedOnEvent.Subscribe(OnSwitchTurnedOn)

    OnWarriorSpawned(Agent : agent) : void =
        set WarriorAgent = option{Agent}

    OnSwitchTurnedOn(Agent : agent) : void =
        if (AlreadyApplied = false):
            if (W := WarriorAgent?, FortChar := W.GetFortCharacter[]):
                NewMax := FortChar.GetMaxHealth() + 100.0
                FortChar.SetMaxHealth(NewMax)
                set AlreadyApplied = true
                Print("WarriorHPBuff: スイッチON。Warrior の最大HPを+100にしました。")
            else:
                Print("WarriorHPBuff: スイッチONだが、Warrior がまだスポーンしていません。先に Warrior をスポーンさせてからスイッチをONにしてください。")


# スイッチをONにすると、Knight の最大HPを +80 する装置（1回だけ）
# Knight は KnightSpawner でスポーンする想定。スポーン中の Knight にのみ適用する
knight_hp_buff_switch_device := class(creative_device):

    @editable Switch : switch_device = switch_device{}
    @editable KnightSpawner : npc_spawner_device = npc_spawner_device{}

    var KnightAgent : ?agent = false
    var AlreadyApplied : logic = false

    OnBegin<override>() : void =
        KnightSpawner.SpawnedEvent.Subscribe(OnKnightSpawned)
        Switch.TurnedOnEvent.Subscribe(OnSwitchTurnedOn)

    OnKnightSpawned(Agent : agent) : void =
        set KnightAgent = option{Agent}

    OnSwitchTurnedOn(Agent : agent) : void =
        if (AlreadyApplied = false):
            if (K := KnightAgent?, FortChar := K.GetFortCharacter[]):
                NewMax := FortChar.GetMaxHealth() + 80.0
                FortChar.SetMaxHealth(NewMax)
                set AlreadyApplied = true
                Print("KnightHPBuff: スイッチON。Knight の最大HPを+80にしました。")
            else:
                Print("KnightHPBuff: スイッチONだが、Knight がまだスポーンしていません。先に Knight をスポーンさせてからスイッチをONにしてください。")
