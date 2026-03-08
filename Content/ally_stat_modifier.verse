using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }

# スイッチをONにすると、タグで検索した HUD の HealerHealBonus が指定値だけ上昇する装置（1回だけ）
# Healer と同じ health_hud_tag で HUD を探すので、必ず同じインスタンスに書き込める
healer_buff_switch_device := class(creative_device):

    @editable Switch : switch_device = switch_device{}
    @editable HealBonusAmount : float = 30.0

    var AlreadyApplied : logic = false

    HealBuffAppliedMessage<localizes>(Amount : int) : message =
        "HealBuff: スイッチON。HUDに+{Amount}を適用しました。"

    HealBonusAmountAsInt() : int =
        if (I := Int[HealBonusAmount]):
            return I
        return 0

    # タグで HUD を取得（GetCreativeObjectsWithTag は非推奨だが、FindCreativeObjectsWithTag は generator/型のため従来 API を使用）
    FindHUDByTag()<decides><transacts> : npc_health_hud = {
        HUDObjects := GetCreativeObjectsWithTag(health_hud_tag{})
        FirstHUDObj := HUDObjects[0]
        npc_health_hud[FirstHUDObj]
    }

    OnBegin<override>() : void =
        Switch.TurnedOnEvent.Subscribe(OnSwitchTurnedOn)

    OnSwitchTurnedOn(Agent : agent) : void =
        if (AlreadyApplied = false):
            if (HUD := FindHUDByTag[]):
                HUD.AddHealerHeal(HealBonusAmount)
                set AlreadyApplied = true
                Print(HealBuffAppliedMessage(HealBonusAmountAsInt()))
            else:
                Print("HealBuff: スイッチONだが、health_hud_tag の HUD が見つかりません。HUD にタグを付けてください。")


# スイッチをONにすると、Warrior の最大HPを指定値だけ上昇させる装置（1回だけ）
# Warrior は WarriorSpawner でスポーンする想定。スポーン中の Warrior にのみ適用する
warrior_hp_buff_switch_device := class(creative_device):

    @editable Switch : switch_device = switch_device{}
    @editable WarriorSpawner : npc_spawner_device = npc_spawner_device{}
    @editable HpBonusAmount : float = 100.0

    var WarriorAgent : ?agent = false
    var AlreadyApplied : logic = false

    WarriorHpBuffAppliedMessage<localizes>(Amount : int) : message =
        "WarriorHPBuff: スイッチON。Warrior の最大HPを+{Amount}にしました。"

    HpBonusAmountAsInt() : int =
        if (I := Int[HpBonusAmount]):
            return I
        return 0

    OnBegin<override>() : void =
        WarriorSpawner.SpawnedEvent.Subscribe(OnWarriorSpawned)
        Switch.TurnedOnEvent.Subscribe(OnSwitchTurnedOn)

    OnWarriorSpawned(Agent : agent) : void =
        set WarriorAgent = option{Agent}

    OnSwitchTurnedOn(Agent : agent) : void =
        if (AlreadyApplied = false):
            if (W := WarriorAgent?, FortChar := W.GetFortCharacter[]):
                NewMax := FortChar.GetMaxHealth() + HpBonusAmount
                FortChar.SetMaxHealth(NewMax)
                set AlreadyApplied = true
                Print(WarriorHpBuffAppliedMessage(HpBonusAmountAsInt()))
            else:
                Print("WarriorHPBuff: スイッチONだが、Warrior がまだスポーンしていません。先に Warrior をスポーンさせてからスイッチをONにしてください。")


# スイッチをONにすると、Knight の最大HPを指定値だけ上昇させる装置（1回だけ）
# Knight は KnightSpawner でスポーンする想定。スポーン中の Knight にのみ適用する
knight_hp_buff_switch_device := class(creative_device):

    @editable Switch : switch_device = switch_device{}
    @editable KnightSpawner : npc_spawner_device = npc_spawner_device{}
    @editable HpBonusAmount : float = 80.0

    var KnightAgent : ?agent = false
    var AlreadyApplied : logic = false

    KnightHpBuffAppliedMessage<localizes>(Amount : int) : message =
        "KnightHPBuff: スイッチON。Knight の最大HPを+{Amount}にしました。"

    HpBonusAmountAsInt() : int =
        if (I := Int[HpBonusAmount]):
            return I
        return 0

    OnBegin<override>() : void =
        KnightSpawner.SpawnedEvent.Subscribe(OnKnightSpawned)
        Switch.TurnedOnEvent.Subscribe(OnSwitchTurnedOn)

    OnKnightSpawned(Agent : agent) : void =
        set KnightAgent = option{Agent}

    OnSwitchTurnedOn(Agent : agent) : void =
        if (AlreadyApplied = false):
            if (K := KnightAgent?, FortChar := K.GetFortCharacter[]):
                NewMax := FortChar.GetMaxHealth() + HpBonusAmount
                FortChar.SetMaxHealth(NewMax)
                set AlreadyApplied = true
                Print(KnightHpBuffAppliedMessage(HpBonusAmountAsInt()))
            else:
                Print("KnightHPBuff: スイッチONだが、Knight がまだスポーンしていません。先に Knight をスポーンさせてからスイッチをONにしてください。")
