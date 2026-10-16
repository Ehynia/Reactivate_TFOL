# TFOL — технические референсы и план восстановления игровых режимов

**Дата:** 2026-10-17  
**Состояние:** независимый обзор документации и открытых репозиториев; НЕ заявляет, что механика заработала в реальном TFOL-клиенте.  
**Сверка с кодом:** локальное рабочее дерево `Reactivate_TFOL_OBT33_v32_DIAGNOSTICS_GITHUB_PREVIEW_FULL/Release/Server/`. Исходный проект не равен приведённым аналогам, не копировать их код без проверки лицензий и совместимости.

## 1. Сетевые роли — решение для TFOL

Официальные источники UE4.27:
- https://dev.epicgames.com/documentation/en-us/unreal-engine/client-server-model?application_version=4.27
- https://dev.epicgames.com/documentation/en-us/unreal-engine/networking-overview?application_version=4.27
- https://dev.epicgames.com/documentation/unreal-engine/session-interface?application_version=4.27
- https://dev.epicgames.com/documentation/en-us/unreal-engine/travelling-in-multiplayer?application_version=4.27

UE4 Listen Server — полноценный авторитетный **игровой сервер в процессе игрока-хоста** (с GameMode и миром UE4), а VPS — **координатор**: аккаунты, объявления комнат, поиск, безопасный обмен адресами, выбор нового хоста, результат и экономика. VPS не должен запускать симуляцию PvP/PvE. Не подменять настоящий listen-порт `127.0.0.1` в чужой сети. `GameState` реплицирует общее состояние участникам, `PlayerState` — данные игрока.

Сверка с OBT33 v32:
- `matchmaking.py::Queue.poll`: без действующего worker/peer возвращает `no_game_host`; попадание двух игроков в очередь само по себе не подтверждает сетевой матч.
- `matchmaking.py::Queue.join` — отдельные таймеры ожидания 20 сек / тестовый peer grace 2 сек.
- `peer_rooms.py::Rooms.allocate/solo/poll/bound`: назначение listen-хоста, свободных мест и присоединения; текущий `DsDomain='127.0.0.1:<port>'` подходит только для localhost.
- `peer_rooms.py::Rooms.cancel/publish_snapshot/migration_checkpoint`: выбирает следующего хоста и передаёт непрозрачный checkpoint, но прямо указывает `world_restored=False`: сериализация/восстановление Actors, Pawn, AI, снарядов, флагов и времени **не реализованы**.

**Проверка:** два ПК в разных сетях; host A стартует карту; B подключается к А и видит актуальные реплицированные Pawn/пули/урон; один бот уступает место B; затем A уходит и B восстанавливает исходное состояние мира. Не считать назначение B в таблице комнат миграцией работающего матча.

## 2. Самый близкий исходник UE4-шутера: ShooterGame

- Исходники: https://github.com/Noesis/UE4-ShooterGame
- Клиентский конец матча: https://github.com/Noesis/UE4-ShooterGame/blob/master/Source/ShooterGame/Private/Player/ShooterPlayerController.cpp
- Заголовок: https://github.com/Noesis/UE4-ShooterGame/blob/master/Source/ShooterGame/Public/Player/ShooterPlayerController.h

Референс разделяет `ClientGameEnded_Implementation`, показ Win/Loss в HUD, `UpdateSaveFileOnGameEnd`, достижения, лидерборды и `ClientSendRoundEndEvent`. Анализировать как последовательность UI/результаты/сохранение, а НЕ заимствовать чужой бинарник.

**TFOL:** увидеть `WaitingPostMatch` недостаточно. Последнее зафиксированное `OnBattleResultDataTimeout` требует трассировки источника native round-end, итогового `OB15`, получения всеми клиентами, сохранения транзакции и подтверждения отображения UI.
- `game_protocol.py` — входящие команды `TutorialBattleReq`, `ExitPostGameReq` и связанные обработчики.
- `battle_statistics.py::complete` — ожидание и применение native result.
- `economy.py::complete` — проверяет матч/участников и выдаёт валюту только после подтверждённого исхода; счётчик `CaptureFlagCount` уже участвует в формуле, но это **не доказывает реальный захват флага**.
- Построить end-to-end журнал: `match_id/host_epoch/phase/result_nonce`; завершение движка -> валидированный snapshot -> клиентский результат -> идемпотентная транзакция -> ответ кошелька -> UI; явная ветка «раунд прерван» с ограниченным дропом, не имитирующим победу.

**Acceptance:** настоящий бой на Windows завершается; обе машины видят экран итогов; повтор `OB15` не дублирует XP/3 валюты; отсутствие `OB15` не превращается в ложную победу.

## 3. Флаги CTF: доступные референсы

- Исходник игрового CTF с Unreal: https://github.com/jamesjang/P2P-Capture-The-Flag
- Unreal Tournament classic (устаревший движок, логика событий как спецификация): https://github.com/Deaod/NewCTF
- Описание древнего Unreal CTF: https://wiki.beyondunreal.com/Legacy%3ACTFFlag
- Epic учебный CTF (UEFN — **не код TFOL/UE4**): https://dev.epicgames.com/documentation/fortnite/build-a-capture-the-flag-in-unreal-editor-for-fortnite

Реализовать состояние флага как автомат **HOME -> CARRIED -> DROPPED -> RETURNED/CAPTURED**, авторитетный на UE4 listen-хосте. Взятие/смерть носителя/возврат/захват проверяются с учётом TeamId, роли носителя, положения у собственной базы и положения своего флага. Счёт команды растёт один раз только на `CAPTURED`; GameState реплицирует статус/очки, PlayerState — индивидуальные захваты. Конфигурационная таблица `CaptureTheFlagModeConf.bytes` в `bot_modes.py` сама не содержит обработчиков событий и не гарантирует счёт.

**Acceptance:** 2 ПК; взятие чужого флага -> перенос -> возврат к базе -> +1 очко ровно один раз; смерть носителя -> drop; возврат своего -> reset; рестарт и переподключение сохраняют актуальное состояние.

## 4. PvE: миссия, инсектиконы, ядро, таймер

- UE4 AI overview: https://dev.epicgames.com/documentation/unreal-engine/artificial-intelligence?application_version=4.27
- Behavior Trees/Blackboards: https://dev.epicgames.com/documentation/unreal-engine/behavior-trees?application_version=4.27
- EQS quickstart: https://dev.epicgames.com/documentation/en-us/unreal-engine/environment-query-system-quick-start?application_version=4.27
- AI debugger: https://dev.epicgames.com/documentation/unreal-engine/ai-debugging?application_version=4.27
- Coop шутер UE4 с AI/репликацией: https://github.com/saha0073/Coop-Multiplayer-Shooter-Unreal

Не использовать generic `BotFill` PvP для инсектиконов PvE. Отдельный MissionDirector/GameMode управляет волнами врагов, их AIController, цели атаки, урону по ядру, здоровью ядра и условиям win/lose. Хост авторитетен для: `wave_id`, `core_hp`, `mission_start_server_time`, `remaining_seconds`, `enemy_alive_count`. Репликация через GameState/Actor, урон через проверку на хосте. Кооперативные игроки в одной союзной команде; PvE враги имеют другую faction/team, collision и damage policy. При `0:0` искать пропущенный BeginPlay/GameMode/ServerTime/OnRep, а не выводить нулевой таймер из Python.

**Acceptance:** 1 игрок, 2 игрока, 1 игрок+дружественный AI; инсектиконы идут к ядру; при подтверждённых ударах ядро теряет HP; таймер виден одинаково двум клиентам; смерть ядра/таймаут приводит к итогам и наградам без атаки союзников друг на друга.

## 5. Возрождение сетевой игры: OpenFusion/OpenSpy

- https://github.com/OpenFusionProject/OpenFusion — reverse-engineered сервер FusionFall, отдельно login/tutorial и shard. **Сильный образец:** декомпозиция логина/персонажа/обучения/геймплея и автоматизация доступных сборок; это НЕ UE4/Listen Server.
- https://github.com/openspy/openspy-core — восстановленные сервисы списка серверов, NAT и game statistics; **образец протокольной координации**, не совместимый с TFOL «как есть».
- https://openspy.org/faq — ограничения CGNAT, NAT traversal.
- https://github.com/ValveSoftware/GameNetworkingSockets — P2P/ICE/NAT, надёжные/ненадёжные UDP, шифрование; **библиотека транспорта**, не замена UE4 NetDriver и не готовая миграция мира.
- https://github.com/ValveSoftware/GameNetworkingSockets/blob/master/README_P2P.md — требования к signaling/STUN/TURN и особенности relay fallback.

Вывод: модуль регистрации/подбора и модуль транспорта отделить от нативного мира UE4; при отсутствии публичного IP нужен проверенный relay/возможность соединиться через NAT. Не утверждать, что добавление одного Python TCP API создало рабочий мультиплеер.

## 6. Очередность внедрения в TFOL

### P0: один настоящий PvE-матч end-to-end
1. На закреплённом EXE/ресурсах трассировать InitGame -> authority GameMode -> actors ядра/инсектиконов -> damage -> win/lose -> WaitingPostMatch -> OB15/UI. Снять timestamps, класс GameMode, start/server_time, core actor, PlayerState.
2. Устранить атаки внутри союзной команды, проверить AI perception, navmesh, server authority.
3. Восстановить core_hp, wave counter и общий таймер; test 1/2 PCs.
4. Восстановить результат и награды, отдельные reward_grant_id и transaction idempotency.

### P1: CTF и матчи с несколькими людьми
1. Flag actor с репликацией и таблицей переходов, тест корректного score; `mode_id`/карта строго из конфигурации.
2. Join-in-progress реального участника на host endpoint; удалить одного конкретного bot-пешку только **после подтверждённого успешного player spawn** (иначе бой теряет место).
3. Проверить CTF и PvP на двух физических ПК и через Интернет, не только localhost.

### P2: миграция хоста, снайперская дуэль, остальные режимы
1. Полный UE4 snapshot мира: actor IDs, pawn/controller, teams, HP, flags, pickups, waves, timers, RNG seed, projectile state, AI blackboard.
2. Новый host_epoch, переподключение, восстановление, подтверждение клиентам, анти-replay; не начислять выигрыш во время миграции.
3. Режимы получают из оригинальных `.bytes` индивидуальные team sizes, allowed weapon classes и win conditions; снайперская дуэль — только снайперское оружие.

## 7. Тестовая матрица и критерии доказательства

| Сценарий | Тест | Требуемое подтверждение |
| --- | --- | --- |
| Solo PvE | 1 Windows | enemies/core HP/timer/win/lose + OB15 |
| Coop PvE | 2 Windows | friendly-fire off, shared mission state |
| CTF | 2 Windows | pickup/drop/return/capture, +1 ровно один раз |
| Join-in-progress | 2 Windows | человек заменяет живого бота, без удвоения места |
| Listen host | 2 сети/NAT | B подключается к A, replicated actors visible |
| Host migration | A -> B | world_restored=true **только после** восстановления мира |
| Результаты | окончание/повтор OB15 | один реальный outcome, один набор наград |
| Диагностика | off/on в лаунчере | off: нет ZIP/сканирования логов; on: ZIP по запросу |

## 8. Важные ограничения

- Документация Epic UE4.27 — стабильный референс концепций, но TFOL может быть собрана с другой версией UE4. Перед патчингом x86 адресов проверить версию, ABI, PE hash, offsets, таблицы и точки хуков.
- NewCTF — Unreal Tournament (другой движок/поколение). UEFN — другая платформа. Игровой код нельзя переносить буквально.
- Github reference code может требовать соблюдения собственных лицензий. В проект TFOL переносить **идею/протокол** только после проверки лицензии и структуры оригинала.
- Оригинальные файлы игры, чужие бинарники и контент не публиковать в публичном репозитории.
- Это **исследование и план**, а не готовый исправленный матч или опубликованный GitHub Release.
