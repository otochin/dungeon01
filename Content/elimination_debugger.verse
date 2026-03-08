using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }

# 撃破マネージャーの信号をトラッカーに橋渡しするデバイス
elimination_debugger := class(creative_device):

    # 監視対象の撃破マネージャー
    @editable
    TargetEliminationManager : elimination_manager_device = elimination_manager_device{}

    # 進捗を進めたいトラッカーデバイス
    @editable
    TargetTracker : tracker_device = tracker_device{}

    # ゲーム開始時に実行される関数
    OnBegin<override>() : void =
        # Print("撃破トラッカー連動デバイスが起動しました。")
        
        # 撃破マネージャーのイベントを購読
        TargetEliminationManager.EliminatedEvent.Subscribe(OnEliminated)

    # 撃破が検知された時に呼ばれる関数
    OnEliminated(VictimAgent : agent) : void =
        # Print("★撃破を検知しました。トラッカーの進捗を更新します★")
        
        # 誰が倒したかに関わらず、トラッカーの進捗を1進めます。
        # トラッカーの Sharing（共有）が「すべて」に設定されている場合、
        # 便宜上、最初のプレイヤーのエージェントを渡すことでチーム全体の進捗としてカウントされます。
        AllPlayers := GetPlayspace().GetPlayers()
        if (FirstPlayer := AllPlayers[0]):
            # tracker_device で進捗を1増やす正しい関数名は Increment(Agent) です
            TargetTracker.Increment(FirstPlayer)
            # Print("トラッカーの進捗を +1 しました。")