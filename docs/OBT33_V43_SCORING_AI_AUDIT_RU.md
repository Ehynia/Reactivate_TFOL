# OBT33 v43 — проверка TRW/CTF-счёта и оригинального AI (исследование)

**Состояние:** по состоянию на 2026-10-17 изучены исходники OBT33 v42, pinned client EXE SHA-256 `482309c9ae725f563006d1bb00b41b88b98a056927131142711e798500002797`, исходные ModeConf.bytes и два прежних ZIP-отчёта OBT33. Это **не игровой фикс**, и никакие оригинальные EXE/PAK не публикуются.

## Результат аудита

- `TRW`, mode 1003, `LittleTown` map 201/submode 1005, оригинальный `ResourceWarModeConf.bytes`. На хосте захват точек должен приводить к начислению очков за реальное удержание.
- `CTF`, mode 1005, `moon` map 701, `CTF_Factory` 702, `DM_EndorBase` 703/submode 1001; оригинальный `CaptureTheFlagModeConf.bytes`. Подъём флага — не завершённая доставка на базу; счёт должен расти от авторитетного `FlagCapture`.
- В EXE обнаружены строки с путями исходников `Private/TFGameMode/UTTeamRWGameState.cpp`, `Private/UTCTFGameMode.cpp`, `Private/UTCTFGameState.cpp`, а также имена `OnRep_TeamScore`, `OnRep_PlayerFlagCaptures`, `FlagCapture`, `ScoreObject`.
- Текущий Python-сервер раздаёт информацию о комнате и результате, но **не** меняет Unreal GameState и не получает подлинные события pickup/capture/point-ownership. Поэтому таймер может идти независимо от стоящего на нуле счёта.
- Значения исходной CTF-конфигурации (raw DWORD): `1001,6,3,900,30,1,20,180,1`. Значения TRW для строки submode 1005: `1005,3,6,2000,1800` и float `20,5,15,2`, затем `360,400`. Семантика всех полей не доказана: не патчить их по догадке.

## Боты

В EXE присутствуют родные классы `UTBot.cpp`, `AIModule/UTBaseAIController.cpp` и строки тактики `Return to base with enemy flag`, `Hunt flag carrier`, `Defend objective`, `Go pickup flag`, `Charge`, `Ranged Attack`, `Try to Duck`, `MoveAndShoot`, `Shoot Target`.

`bot_aim34.py` в v42 — автономная математическая модель, НЕ подключённая к нативному Unreal AIController, поэтому игрок не увидит её в настоящем бою. Реально включён `ai_repair.h` с исходным `SpawnDefaultController` для отсутствующих контроллеров — это не улучшение аима.

В двух поздних исторических OBT33 отчётах счётчики `OnRep_TeamScore`, `OnRep_PlayerFlagCaptures`, `LOCAL_AI_CONTROLLER_CREATED` равны 0; отсутствие записи не равняется доказательству отсутствия всех событий (логирование может не перехватывать внутренние вызовы). В CTF-отчёте подтверждён `OnBattleResultDataTimeout`.

## Следующая инженерная работа

1. На стороне **настоящего UE4 listen-host**, а не VPS, инструментировать родные `UTTeamRWGameState` и `UTCTFGameMode/GameState`: команда, активная точка/флаг, contested, переход score_before -> score_after, `OnRep`, уникальный native event.
2. Проверить GameMode authority/replication; устранить пропущенный вызов изменения TeamScore. Точно воспроизвести правила ResourceWarModeConf и CTF (семантический дизассемблинг).
3. Для AI логировать наличие Pawn.Controller, выбор ветки BT, видимость/команду врага, наличие LOS, целевой угол/фактический выстрел на хосте. Затем реализовывать упреждение и укрытия через настоящие Unreal controllers.
4. Приобрести проверяемый Windows-лог с TRW захватом трёх точек и CTF полным заносом флага; после этого подключить реальные, а не синтетические игровые события. Два клиента должны видеть одинаковый счёт.

Локальный ZIP с тестовой моделью **не является игровым патчем**: `TFOL_OBT33_v43_OBJECTIVES_AI_AUDIT_TOOLS.zip`. Девять моделей-тестов прошли; нативные события не подключены. Не подделывать XP, деньги, очки или результат матча.
