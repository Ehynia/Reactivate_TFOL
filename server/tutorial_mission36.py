"""OBT33 v41: original ONCE-ONLY tutorial on first account login.

The native OnMSG_LOGIN_DATA_RES handler (OBT x86 0x7d0860) handles the
first tutorial before constructing the lobby HUD. Return Result=badName
with an empty PlayerInfo.Name and let original StartTutorialLevel run.

Do not use the old deferred OB27 travel: it opened Tutorial_Scene AFTER
the lobby and left menu widgets overlaid onto the mission.
"""
import accounts

MAP_ID=1009
PRIVATE_MODE=1004
HERO_ID=15

def tutorial_due(database,uid):
    try:
        identity=accounts.identity(database,uid)
    except ValueError:
        return False
    # One-time UI gate. Authoritative mission success is recorded separately,
    # never forged by map travel, menu exit or nickname creation.
    return bool(identity['tutorial_required'] and not identity['nickname_set']
                and identity['tutorial_completed_at'] is None)

def login_state(database,uid,context):
    needed=tutorial_due(database,uid)
    if needed:
        context['original_tutorial_login41']=dict(state='native_login_pending',
            map=MAP_ID,mode=PRIVATE_MODE,hero=HERO_ID)
        context.pop('megatron_tutorial36',None)
        context.pop('engine_match',None)
    else:
        context.pop('original_tutorial_login41',None)
        context.pop('megatron_tutorial36',None)
    return needed

def poll(database,uid,context,now):
    # Delayed OB27 launch deliberately retired; native login owns the level.
    return b''
