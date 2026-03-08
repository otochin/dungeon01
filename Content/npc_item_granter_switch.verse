using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }

# スイッチをONにすると、指定したNPCスポナーからスポーンしているNPCに、指定したアイテムを付与（装備）するデバイス
# アイテムの種類は item_granter_device 側で設定（エディタでアイテムをドロップして登録）
npc_item_granter_switch_device := class(creative_device):

    @editable Switch : switch_device = switch_device{}
    @editable NPCSpawner : npc_spawner_device = npc_spawner_device{}
    @editable ItemGranter : item_granter_device = item_granter_device{}

    var SpawnedAgent : ?agent = false

    OnBegin<override>() : void =
        NPCSpawner.SpawnedEvent.Subscribe(OnNPCSpawned)
        Switch.TurnedOnEvent.Subscribe(OnSwitchTurnedOn)

    OnNPCSpawned(Agent : agent) : void =
        set SpawnedAgent = option{Agent}

    OnSwitchTurnedOn(Agent : agent) : void =
        if (TargetAgent := SpawnedAgent?):
            ItemGranter.GrantItem(TargetAgent)
            Print("NPCItemGranter: スイッチON。NPCにアイテムを付与しました。")
        else:
            Print("NPCItemGranter: スイッチONだが、NPCがまだスポーンしていません。先にNPCをスポーンさせてからスイッチをONにしてください。")
