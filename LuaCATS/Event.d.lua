--- @meta

--- @class Event
--- @field Add function

Events = {}

--- @class SerialEventGameMessagePopup: Event
--- @field Add fun(EventHandler: fun(popupInfo: PopupInfo))
--- @overload fun(popupInfo: PopupInfo)
Events.SerialEventGameMessagePopup = {}

--- @class SerialEventGameMessagePopupProcessed: Event
--- @field Add fun(EventHandler: fun(ePopup: ButtonPopupType, arg1: number))
--- @field CallImmediate fun(ePopup: ButtonPopupType, arg1: number)
--- @overload fun(ePopup: ButtonPopupType, arg1: number)
Events.SerialEventGameMessagePopupProcessed = {}

--- @class SerialEventGameMessagePopupShown: Event
--- @field Add fun(EventHandler: fun(popupInfo: PopupInfo))
--- @overload fun(popupInfo: PopupInfo)
Events.SerialEventGameMessagePopupShown = {}

--- @class SerialEventCitySetDamage: Event
--- @field Add fun(EventHandler: fun(ePlayer: PlayerId, iCityID: CityId, iDamage: integer))
Events.SerialEventCitySetDamage = {}

--- @class SerialEventCityCreated: Event
--- @field Add fun(EventHandler: fun(vHex: Vector2, ePlayer: PlayerId, iCityID: CityId, eArtStyle: ArtStyleType, eEra: EraType, arg1: any, arg2: any, arg3: any, eFow: integer))
Events.SerialEventCityCreated = {}

--- @class SerialEventCityCaptured: Event
--- @field Add fun(EventHandler: fun(vHexPos: Vector2, ePlayer: PlayerId, eCity: CityId))
Events.SerialEventCityCaptured = {}

--- @class SerialEventCityDestroyed: Event
--- @field Add fun(EventHandler: fun(vHexPos: Vector2, ePlayer: PlayerId, eCity: CityId))
Events.SerialEventCityDestroyed = {}

--- @class SerialEventCityInfoDirty: Event
--- @field Add fun(EventHandler: fun())
Events.SerialEventCityInfoDirty = {}

--- @class SearchForPediaEntry: Event
--- @field Add fun(EventHandler: fun(strSearch: string))
--- @overload fun(strSearch: string)
Events.SearchForPediaEntry = {}

--- @class OpenInfoCorner: Event
--- @field Add fun(EventHandler: fun(eInfoCorner: InfoCornerId))
--- @overload fun(eInfoCorner: InfoCornerId)
Events.OpenInfoCorner = {}

--- @class ActivePlayerTurnStart: Event
--- @field Add fun(EventHandler: fun())
Events.ActivePlayerTurnStart = {}

--- @class AIProcessingStartedForPlayer: Event
--- @field Add fun(EventHandler: fun(ePlayer: PlayerId))
Events.AIProcessingStartedForPlayer = {}

--- @class GameplaySetActivePlayer: Event
--- @field Add fun(EventHandler: fun(eActivePlayer: PlayerId, ePrevActivePlayer: PlayerId))
Events.GameplaySetActivePlayer = {}

--- @class AudioPlay2DSound: Event
--- @overload fun(str2DSound: string)
Events.AudioPlay2DSound = {}

--- @class InterfaceModeChanged: Event
--- @field Add fun(EventHandler: fun(eOldInterface: InterfaceModeType, eNewInterface: InterfaceModeType))
Events.InterfaceModeChanged = {}

--- @class StrategicViewStateChanged: Event
--- @field Add fun(EventHandler: fun(bStrategicView: boolean, bCityBanners: boolean))
Events.StrategicViewStateChanged = {}

--- @class SpecificCityInfoDirty: Event
--- @field Add fun(EventHandler: fun(ePlayer: PlayerId, iCityID: CityId, eUpdateType: CityUpdateType))
--- @overload fun(ePlayer: PlayerId, iCityID: CityId, eUpdateType: CityUpdateType)
Events.SpecificCityInfoDirty = {}

--- @class HexFOWStateChanged: Event
--- @field Add fun(EventHandler: fun(vHex: Vector2, eFow: integer, bWholeMap: boolean))
Events.HexFOWStateChanged = {}

--- @class RunCombatSim: Event
--- @field Add fun(EventHandler: fun(attackingPlayer: PlayerId, attackingUnit: UnitId, attackingUnitDamage: integer, attackingUnitFinalDamage: integer, attackingUnitMaxHitPoints: integer, defendingPlayer: PlayerId, defendingUnit: UnitId, defendingUnitDamage: integer, defendingUnitFinalDamage: integer, defendingUnitMaxHitPoints: integer, bContinuation: boolean, attackerX: integer, attackerY: integer, defenderX: integer, defenderY: integer))
--- @overload fun(attackingPlayer: PlayerId, attackingUnit: UnitId, attackingUnitDamage: integer, attackingUnitFinalDamage: integer, attackingUnitMaxHitPoints: integer, defendingPlayer: PlayerId, defendingUnit: UnitId, defendingUnitDamage: integer, defendingUnitFinalDamage: integer, defendingUnitMaxHitPoints: integer, bContinuation: boolean, attackerX: integer, attackerY: integer, defenderX: integer, defenderY: integer)
Events.RunCombatSim = {}

--- @class EndCombatSim: Event
--- @field Add fun(EventHandler: fun(attackingPlayer: PlayerId, attackingUnit: UnitId, attackingUnitDamage: integer, attackingUnitFinalDamage: integer, attackingUnitMaxHitPoints: integer, defendingPlayer: PlayerId, defendingUnit: UnitId, defendingUnitDamage: integer, defendingUnitFinalDamage: integer, defendingUnitMaxHitPoints: integer, attackerX: integer, attackerY: integer, defenderX: integer, defenderY: integer))
--- @overload fun(attackingPlayer: PlayerId, attackingUnit: UnitId, attackingUnitDamage: integer, attackingUnitFinalDamage: integer, attackingUnitMaxHitPoints: integer, defendingPlayer: PlayerId, defendingUnit: UnitId, defendingUnitDamage: integer, defendingUnitFinalDamage: integer, defendingUnitMaxHitPoints: integer, attackerX: integer, attackerY: integer, defenderX: integer, defenderY: integer)
Events.EndCombatSim = {}

--- @class InitCityRangeStrike: Event
--- @field Add fun(EventHandler: fun(ePlayer: PlayerId, iCityID: CityId))
--- @overload fun(ePlayer: PlayerId, iCityID: CityId)
Events.InitCityRangeStrike = {}

--- @class UnitGarrison: Event
--- @field Add fun(EventHandler: fun(ePlayer: PlayerId, iUnitID: UnitId, bGarrisoned: boolean))
Events.UnitGarrison = {}

--- @class UnitMoveQueueChanged: Event
--- @field Add fun(EventHandler: fun(ePlayer: PlayerId, iUnitID: UnitId, bRemainingMoves: boolean))
Events.UnitMoveQueueChanged = {}

--- @class OpenPlayerDealScreenEvent: Event
--- @field Add fun(EventHandler: fun(ePlayer: PlayerId))
--- @overload fun(ePlayer: PlayerId)
Events.OpenPlayerDealScreenEvent = {}
