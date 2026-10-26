"""Original OBT MSG_SYNC_BATTLE_INFO (60) for verified native OB15 results.

This is a wire adapter, NOT an UE4 event hook. Never synthesize battle outcomes.
"""
from tdr_codec import packet, decode_all, packets

COMMAND = 60
SCHEMA = 'SyncBattleInfo'

def result_notice(stop, rows, room_sequence=0):
    if not isinstance(stop,dict) or not isinstance(rows,list) or not 1<=len(rows)<=16:
        raise ValueError('Native game result required')
    if type(room_sequence)!=int or room_sequence<0 or room_sequence>=2**63:
        raise ValueError('Invalid room sequence')
    winner = stop.get('WinTeamId')
    duration = stop.get('TimeConsume')
    # bool compares equal to 0/1 in Python; these native fields must be integers.
    if type(winner) is not int or winner not in (0, 1, 255, -1):
        raise ValueError('Result has no validated end time/outcome')
    if type(duration) is not int or not 1 <= duration <= 86400:
        raise ValueError('Result has no validated end time/outcome')
    for row in rows:
        if not isinstance(row, dict) or not isinstance(row.get('Name'), str) or not row['Name'].strip():
            raise ValueError('Invalid original scoreboard')
    value=dict(RoomSeq=room_sequence, BattleInfo=stop, Count=len(rows),
               AccBattleInfo=rows, ItemCount=0, ItemInfo=[],
               ActivityItemCount=0, ActivityItemList=[],
               FirstWinItemCount=0, FirstWinItemList=[], FirstWinMatchId=0,
               BonusCardItemCount=0, BonusCardItemList=[], RandomItemCount=0,
               RandomItemList=[], DeltaQualifyElo=0, DeltaQualifyWarrior=0,
               DeltaQualifyStar=0, NetbarItemCount=0, NetbarItemList=[])
    encoded=packet(COMMAND,SCHEMA,value)
    frames=packets(encoded)
    if len(frames)!=1 or frames[0][0]!=COMMAND:raise ValueError('Invalid result framing')
    view=decode_all(SCHEMA,frames[0][1])
    if (not isinstance(view, dict) or type(view.get('Count')) is not int
            or view['Count'] != len(rows)
            or not isinstance(view.get('BattleInfo'), dict)
            or view['BattleInfo'].get('TimeConsume') != duration
            or view['BattleInfo'].get('WinTeamId') != winner):
        raise ValueError('Native result wire mismatch')
    return encoded
