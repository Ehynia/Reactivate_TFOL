"""Queue the ORIGINAL OBT Megatron tutorial via an existing native engine job.

Requires a registered local account and a bridge capable of OB27.
Does not synthesize a boss or mark the tutorial completed.
"""
import struct
import accounts

MAP_ID=1009
ACTION=2
PRIVATE_MODE=1004
ARRIVAL_DELAY=8.0

def tutorial_due(database,uid):
    try:identity=accounts.identity(database,uid)
    except ValueError:return False
    return identity['tutorial_required']==1 and identity['tutorial_completed_at'] is None

def poll(database,uid,context,now):
    if not (context.get('native_bots') and context.get('logged_in')
            and context.get('allow_local_rewards')):return b''
    step=context.get('megatron_tutorial36')
    if step is None:
        step={'phase':'pending' if tutorial_due(database,uid) else 'not_required',
              'deadline':now+ARRIVAL_DELAY}
        context['megatron_tutorial36']=step
    if step['phase']!='pending' or now<step['deadline']:return b''
    if context.get('engine_match'):return b''
    from native_bots import selected,COMMAND
    from tdr_codec import HEAD
    hero=selected(database,uid)
    sequence=context.get('engine_sequence',0)+1
    context['engine_sequence']=sequence
    context['engine_match']=dict(state='travel_requested',action=ACTION,map=MAP_ID,
       mode=PRIVATE_MODE,bots=0,hero=hero,sequence=sequence,round_id=None,
       tutorial_original=True,dispatch_deadline=now+20)
    step['phase']='travel_requested'
    body=struct.pack('<4s6I',b'OB27',sequence,ACTION,MAP_ID,hero,0,PRIVATE_MODE)
    return HEAD.pack(1,COMMAND,12,len(body))+body
