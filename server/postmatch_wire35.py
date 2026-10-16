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
    if stop.get('WinTeamId') not in (0,1,255,-1) or not 1<=stop.get('TimeConsume',0)<=86400:
        raise ValueError('Result has no validated end time/outcome')
    if any(not isinstance(row,dict) or not row.get('Name') for row in rows):
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
    if view['Count']!=len(rows) or view['BattleInfo']['TimeConsume']!=stop['TimeConsume']:
        raise ValueError('Native result wire mismatch')
    return encoded
