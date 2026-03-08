using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /UnrealEngine.com/Temporary/SpatialMath }

# 複数スイッチを配列で設定し、オフのものを「経過時間ベースのオフセット」で3つ選んでデバイス位置に横並び表示。
# 毎回スタート時に GetSimulationElapsedTime() でオフセットを変えるため、5つあれば5通りの組み合わせのどれかになる。
# どれか1つでもONになると全スイッチを無表示（マップ外へ移動＋無効化）し、テレポーターを有効化する。
random_switch_teleporter_device := class(creative_device):

    @editable Switches : []switch_device = array{}
    @editable Teleporter : teleporter_device = teleporter_device{}
    @editable Spacing : float = 200.0
    # スイッチの高さオフセット（cm）。地面に埋まらないようキャラの目の高さ程度に。既定 120
    @editable HeightOffset : float = 120.0

    var VisibleSwitches : []switch_device = array{}
    # スイッチを「非表示」にするときの位置（switch_device に Hide がないためマップ外へ移動）
    HiddenPosition : vector3 = vector3{X := 0.0, Y := 0.0, Z := -100000.0}
    HiddenRotation : rotation = MakeRotationFromYawPitchRollDegrees(0.0, 0.0, 0.0)

    OnBegin<override>() : void =
        Teleporter.Disable()
        var offList : []switch_device = array{}
        for (sw : Switches):
            if (sw.GetCurrentState[]):
                ()
            else:
                set offList += array{sw}
        var selected : []switch_device = array{}
        if (offList.Length <= 3):
            set selected = offList
        else:
            # 経過時間から開始インデックスを算出（5つなら0～4のいずれか → 毎回違う3つの組み合わせになり得る）
            if (iVal := Int[GetSimulationElapsedTime() * 1000.0]):
                if (offset := Mod[iVal * 1237, offList.Length]):
                    if (s0 := offList[offset]):
                        if (s1 := offList[Mod[offset + 1, offList.Length]]):
                            if (s2 := offList[Mod[offset + 2, offList.Length]]):
                                set selected += array{s0}
                                set selected += array{s1}
                                set selected += array{s2}
            if (selected.Length = 0):
                if (s0 := offList[0]):
                    if (s1 := offList[1]):
                        if (s2 := offList[2]):
                            set selected += array{s0}
                            set selected += array{s1}
                            set selected += array{s2}
        set VisibleSwitches = selected

        # 最初に、ランダムに選んだ３つのスイッチの表示をオンにする
        for (sw : Switches):
            sw.Disable()
        for (sw : VisibleSwitches):
            sw.Enable()
        MyTransform := GetTransform()
        Pos := MyTransform.Translation
        NewRot := MakeRotationFromYawPitchRollDegrees(90.0, 0.0, 0.0)
        for (Index -> sw : VisibleSwitches):
            OffsetX := (Index * 1.0 - 1.0) * Spacing
            NewPos := Pos + vector3{X := OffsetX, Y := 0.0, Z := HeightOffset}
            if (sw.TeleportTo[NewPos, NewRot]):
                ()

        for (sw : VisibleSwitches):
            sw.TurnedOnEvent.Subscribe(OnAnyVisibleSwitchTurnedOn)

    OnAnyVisibleSwitchTurnedOn(Agent : agent) : void =
        for (sw : Switches):
            if (sw.TeleportTo[HiddenPosition, HiddenRotation]):
                ()
            sw.Disable()
        Teleporter.Enable()
