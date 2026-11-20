--- @meta

--- @class Event
--- @field Add function

Events = {}

--- @class SearchForPediaEntry: Event
--- @field Add fun(EventHandler: fun(strSearch: string))
--- @overload fun(strSearch: string)
Events.SearchForPediaEntry = {}

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

--- @class SerialEventCityCaptured: Event
--- @field Add fun(EventHandler: fun(vHexPos: Vector2, ePlayer: PlayerId, eCity: CityId))
Events.SerialEventCityCaptured = {}

--- @class SerialEventCityDestroyed: Event
--- @field Add fun(EventHandler: fun(vHexPos: Vector2, ePlayer: PlayerId, eCity: CityId))
Events.SerialEventCityDestroyed = {}

--- @class OpenInfoCorner: Event
--- @field Add fun(EventHandler: fun(eInfoCorner: InfoCornerId))
--- @overload fun(eInfoCorner: InfoCornerId)
Events.OpenInfoCorner = {}

--- @class AIProcessingStartedForPlayer: Event
--- @field Add fun(EventHandler: fun(ePlayer: PlayerId))
Events.AIProcessingStartedForPlayer = {}

--- @class GameplaySetActivePlayer: Event
--- @field Add fun(EventHandler: fun(eActivePlayer: PlayerId, ePrevActivePlayer: PlayerId))
Events.GameplaySetActivePlayer = {}

--- @class AudioPlay2DSound: Event
--- @overload fun(str2DSound: string)
Events.AudioPlay2DSound = {}

--- @class SpecificCityInfoDirty: Event
--- @field Add fun(EventHandler: fun(ePlayer: PlayerId, iCityID: CityId, eUpdateType: CityUpdateType))
--- @overload fun(ePlayer: PlayerId, iCityID: CityId, eUpdateType: CityUpdateType)
Events.SpecificCityInfoDirty = {}

--- @class RunCombatSim: Event
--- @field Add fun(EventHandler: fun(attackingPlayer: PlayerId, attackingUnit: UnitId, attackingUnitDamage: integer, attackingUnitFinalDamage: integer, attackingUnitMaxHitPoints: integer, defendingPlayer: PlayerId, defendingUnit: UnitId, defendingUnitDamage: integer, defendingUnitFinalDamage: integer, defendingUnitMaxHitPoints: integer, bContinuation: boolean, attackerX: integer, attackerY: integer, defenderX: integer, defenderY: integer))
--- @overload fun(attackingPlayer: PlayerId, attackingUnit: UnitId, attackingUnitDamage: integer, attackingUnitFinalDamage: integer, attackingUnitMaxHitPoints: integer, defendingPlayer: PlayerId, defendingUnit: UnitId, defendingUnitDamage: integer, defendingUnitFinalDamage: integer, defendingUnitMaxHitPoints: integer, bContinuation: boolean, attackerX: integer, attackerY: integer, defenderX: integer, defenderY: integer)
Events.RunCombatSim = {}

--- @class EndCombatSim: Event
--- @field Add fun(EventHandler: fun(attackingPlayer: PlayerId, attackingUnit: UnitId, attackingUnitDamage: integer, attackingUnitFinalDamage: integer, attackingUnitMaxHitPoints: integer, defendingPlayer: PlayerId, defendingUnit: UnitId, defendingUnitDamage: integer, defendingUnitFinalDamage: integer, defendingUnitMaxHitPoints: integer, attackerX: integer, attackerY: integer, defenderX: integer, defenderY: integer))
--- @overload fun(attackingPlayer: PlayerId, attackingUnit: UnitId, attackingUnitDamage: integer, attackingUnitFinalDamage: integer, attackingUnitMaxHitPoints: integer, defendingPlayer: PlayerId, defendingUnit: UnitId, defendingUnitDamage: integer, defendingUnitFinalDamage: integer, defendingUnitMaxHitPoints: integer, attackerX: integer, attackerY: integer, defenderX: integer, defenderY: integer)
Events.EndCombatSim = {}
