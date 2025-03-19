print("This is the modded InfoTooltipInclude from Community Patch");

-- Game object is not available in PreGame, so this will have to do
local MOD_BALANCE_VP = GameInfo.CustomModOptions{Name = "BALANCE_VP"}().Value == 1;
local MOD_BALANCE_CORE_YIELDS = GameInfo.CustomModOptions{Name = "BALANCE_CORE_YIELDS"}().Value == 1;
local MOD_BALANCE_CORE_JFD = GameInfo.CustomModOptions{Name = "BALANCE_CORE_JFD"}().Value == 1;
local MOD_BALANCE_CORE_BUILDING_INVESTMENTS = GameInfo.CustomModOptions{Name = "BALANCE_CORE_BUILDING_INVESTMENTS"}().Value == 1;
local MOD_UNITS_RESOURCE_QUANTITY_TOTALS = GameInfo.CustomModOptions{Name = "UNITS_RESOURCE_QUANTITY_TOTALS"}().Value == 1;
local MOD_BALANCE_CORE_NEW_GP_ATTRIBUTES = GameInfo.CustomModOptions{Name = "BALANCE_CORE_NEW_GP_ATTRIBUTES"}().Value == 1;
local MOD_BALANCE_CORE_INQUISITOR_TWEAKS = GameInfo.CustomModOptions{Name = "BALANCE_CORE_INQUISITOR_TWEAKS"}().Value == 1;
local MOD_GLOBAL_CANNOT_EMBARK = GameInfo.CustomModOptions{Name = "GLOBAL_CANNOT_EMBARK"}().Value == 1;
local MOD_GLOBAL_MOVE_AFTER_UPGRADE = GameInfo.CustomModOptions{Name = "GLOBAL_MOVE_AFTER_UPGRADE"}().Value == 1;

-- GameInfoTypes and YieldTypes are also not available here
local iNumJFDYields = GameInfo.Yields{Type = "YIELD_JFD_SOVEREIGNTY"}().ID + 1;
local iNumCoreYields = GameInfo.Yields{Type = "YIELD_CULTURE_LOCAL"}().ID + 1;
local iNumBaseYields = GameInfo.Yields{Type = "YIELD_GOLDEN_AGE_POINTS"}().ID + 1;
local iNumYields = MOD_BALANCE_CORE_JFD and iNumJFDYields or (MOD_BALANCE_CORE_YIELDS and iNumCoreYields or iNumBaseYields);

local strSeparator = "----------------";
local L = Locale.Lookup;

-------------------------------------------------
-- Help text for game components (Units, Buildings, etc.)
-------------------------------------------------

-- Helper functions
local function TextColor(strColor, strText)
	return strColor .. strText .."[ENDCOLOR]";
end

local function UnitColor(strText)
	return TextColor("[COLOR_YELLOW]", strText);
end

local function BuildingColor(strText)
	return TextColor("[COLOR_YIELD_FOOD]", strText);
end

local function ProjectColor(strText)
	return TextColor("[COLOR_CITY_BLUE]", strText);
end

local function PolicyColor(strText)
	return TextColor("[COLOR_MAGENTA]", strText);
end

local function TechColor(strText)
	return TextColor("[COLOR_CYAN]", strText);
end

local function BeliefColor(strText)
	return TextColor("[COLOR_WHITE]", strText);
end

local function NegativeColor(strText)
	return TextColor("[COLOR_NEGATIVE_TEXT]", strText);
end

local function AppendTech(kTechInfo)
	return kTechInfo and TechColor(string.format(" (%s)", L(kTechInfo.Description))) or "";
end

local function AppendGlobal(strTooltip)
	return string.format("%s %s", strTooltip, L("TXT_KEY_PRODUCTION_GLOBAL_SUFFIX"));
end

local function AppendEraScaling(strTooltip)
	return string.format("%s, %s", strTooltip, L("TXT_KEY_PRODUCTION_BUILDING_ERA_SCALING_SUFFIX"));
end

local function CanHavePromotion(kUnitInfo, strPromotionKey)
	for _ in GameInfo.UnitPromotions_UnitCombats{PromotionType = strPromotionKey, UnitCombatType = kUnitInfo.CombatClass} do
		return true;
	end
	for _ in GameInfo.UnitPromotions_CivilianUnitType{PromotionType = strPromotionKey, UnitType = kUnitInfo.Type} do
		return true;
	end
	return false;
end

local function GetInstantYieldString(strYieldKey, iYield)
	local kYieldInfo = GameInfo.Yields[strYieldKey];
	return L("TXT_KEY_PRODUCTION_INSTANT_YIELD", iYield, kYieldInfo.IconString, kYieldInfo.Description);
end

local function AddTooltipGeneric(tTooltipList, strTextKey, bGlobal, bNotZero, bPositive, ...)
	if bNotZero and arg[1] == 0 then
		return;
	end

	if bPositive and arg[1] <= 0 then
		return;
	end

	local strTooltip = L(strTextKey, unpack(arg));
	if bGlobal then
		strTooltip = AppendGlobal(strTooltip);
	end

	table.insert(tTooltipList, strTooltip);
end

local function AddTooltip(tTooltipList, strTextKey, ...)
	AddTooltipGeneric(tTooltipList, strTextKey, false, false, false, unpack(arg));
end

local function AddTooltipNonZero(tTooltipList, strTextKey, ...)
	AddTooltipGeneric(tTooltipList, strTextKey, false, true, false, unpack(arg));
end

local function AddTooltipPositive(tTooltipList, strTextKey, ...)
	AddTooltipGeneric(tTooltipList, strTextKey, false, false, true, unpack(arg));
end

local function AddTooltipGlobal(tTooltipList, strTextKey, ...)
	AddTooltipGeneric(tTooltipList, strTextKey, true, false, false, unpack(arg));
end

local function AddTooltipGlobalNonZero(tTooltipList, strTextKey, ...)
	AddTooltipGeneric(tTooltipList, strTextKey, true, true, false, unpack(arg));
end

local function AddTooltipGlobalPositive(tTooltipList, strTextKey, ...)
	AddTooltipGeneric(tTooltipList, strTextKey, true, false, true, unpack(arg));
end

local function AddTooltipIfTrue(tTooltipList, strTextKey, bCondition, ...)
	if bCondition then
		AddTooltipGeneric(tTooltipList, strTextKey, false, false, false, unpack(arg));
	end
end

function GetHelpTextForUnit(eUnit, bIncludeRequirementsInfo, pCity)
	local kUnitInfo = GameInfo.Units[eUnit];
	local pActivePlayer = Players[Game.GetActivePlayer()];

	-- When viewing a (foreign) city, always show tooltips as they are for the city owner
	if pCity then
		pActivePlayer = Players[pCity:GetOwner()];
	end

	-- Sometimes a city is needed in tooltips not in city view; in that case use the capital city
	local pActiveCity = pCity or pActivePlayer:GetCapitalCity();

	local eUnitClass = GameInfoTypes[kUnitInfo.Class];
	local kUnitClassInfo = GameInfo.UnitClasses[eUnitClass];
	local eActiveCiv = pActivePlayer:GetCivilizationType();
	local iInvestedCost = pCity and pCity:GetUnitInvestment(eUnit) or 0;
	local tLines = {};

	----------------------
	-- Header section
	----------------------
	local tHeaderLines = {};

	-- Name
	local strName = UnitColor(Locale.ToUpper(L(kUnitInfo.Description)));
	local strUnitCombatKey = kUnitInfo.CombatClass;
	if strUnitCombatKey then
		if strUnitCombatKey == "UNITCOMBAT_ARCHER" and kUnitInfo.IsMounted then
			strName = strName .. " " .. L("TXT_KEY_PRODUCTION_UNIT_COMBAT_CLASS_SKIRMISHER");
		else
			strName = strName .. " " .. L("TXT_KEY_PRODUCTION_UNIT_COMBAT_CLASS", GameInfo.UnitCombatInfos[strUnitCombatKey].Description);
		end
	end
	if kUnitInfo.SpaceshipProject then
		strName = strName .. " " .. L("TXT_KEY_PRODUCTION_UNIT_SPACESHIP_PART");
	end
	if iInvestedCost > 0 then
		strName = strName .. L("TXT_KEY_INVESTED");
	end
	table.insert(tHeaderLines, strName);

	-- Unique Unit? Usually unique to one civ, but it's possible that multiple civs have access to the same unit
	local tCivAdjectives = {};
	for row in GameInfo.Civilization_UnitClassOverrides{UnitType = kUnitInfo.Type} do
		table.insert(tCivAdjectives, GameInfo.Civilizations[row.CivilizationType].Adjective);
	end
	if next(tCivAdjectives) then
		-- Get the unit it is replacing
		local kDefaultUnitInfo = GameInfo.Units[kUnitClassInfo.DefaultUnit];
		local strCivAdj = table.concat(tCivAdjectives, "/");
		if kDefaultUnitInfo then
			AddTooltip(tHeaderLines, "TXT_KEY_PRODUCTION_UNIQUE_UNIT", strCivAdj, kDefaultUnitInfo.Description);
		else
			-- This unit isn't replacing anything
			AddTooltip(tHeaderLines, "TXT_KEY_PRODUCTION_UNIQUE_UNIT_NO_DEFAULT", strCivAdj);
		end
	end

	table.insert(tLines, table.concat(tHeaderLines, "[NEWLINE]"));

	----------------------
	-- Stats section
	----------------------
	local tStatLines = {};

	-- Costs
	if kUnitInfo.Cost > 0 or kUnitInfo.FaithCost > 0 then
		local tCosts = {};
		local iProductionCost, iGoldCost, iFaithCost = 0, 0, 0;
		if kUnitInfo.Cost > 0 then
			iProductionCost = (iInvestedCost > 0) and iInvestedCost or (pActiveCity and pActiveCity:GetUnitProductionNeeded(eUnit) or pActivePlayer:GetUnitProductionNeeded(eUnit));
			iGoldCost = pActiveCity and pActiveCity:GetUnitPurchaseCost(eUnit) or 0;
		end

		if kUnitInfo.FaithCost > 0 then
			iFaithCost = pActiveCity and pActiveCity:GetUnitFaithPurchaseCost(eUnit, true) or 0;
		end

		if not kUnitInfo.PurchaseOnly then
			AddTooltipPositive(tCosts, "TXT_KEY_PRODUCTION_COST_PRODUCTION", iProductionCost);
		end
		AddTooltipPositive(tCosts, "TXT_KEY_PRODUCTION_COST_GOLD", iGoldCost);
		AddTooltipPositive(tCosts, "TXT_KEY_PRODUCTION_COST_FAITH", iFaithCost);

		if next(tCosts) then
			table.insert(tStatLines, L("TXT_KEY_PRODUCTION_COST_PREFIX", table.concat(tCosts, " / ")));
		end
	end

	-- Maintenance (base amount too dynamic to be shown)
	-- These columns can stack, even if they don't make sense together
	AddTooltipNonZero(tStatLines, "TXT_KEY_PRODUCTION_UNIT_EXTRA_MAINTENANCE", kUnitInfo.ExtraMaintenanceCost);
	AddTooltipIfTrue(tStatLines, "TXT_KEY_PRODUCTION_UNIT_NO_MAINTENANCE", kUnitInfo.NoMaintenance);

	-- Supply cost
	AddTooltipIfTrue(tStatLines, "TXT_KEY_PRODUCTION_UNIT_NO_SUPPLY", kUnitInfo.NoSupply);

	-- Stagnation
	AddTooltipIfTrue(tStatLines, "TXT_KEY_PRODUCTION_UNIT_STAGNATION", kUnitInfo.Food);

	-- Max HP (show when non-standard only)
	local iMaxHP = kUnitInfo.MaxHitPoints;
	if iMaxHP ~= 100 then
		AddTooltip(tStatLines, "TXT_KEY_PRODUCTION_UNIT_MAX_HP", iMaxHP);
	end

	-- Moves
	if not kUnitInfo.Immobile then
		AddTooltipPositive(tStatLines, "TXT_KEY_PRODUCTION_MOVEMENT", kUnitInfo.Moves);
	end

	-- Sight (show when non-standard only)
	local iSight = kUnitInfo.BaseSightRange;
	if iSight > 0 and iSight ~= 2 then
		AddTooltip(tStatLines, "TXT_KEY_PRODUCTION_UNIT_SIGHT", iSight);
	end

	-- Range
	AddTooltipPositive(tStatLines, "TXT_KEY_PRODUCTION_RANGE", kUnitInfo.Range);

	-- Ranged Combat Strength
	AddTooltipPositive(tStatLines, "TXT_KEY_PRODUCTION_RANGED_STRENGTH", kUnitInfo.RangedCombat);

	-- Combat Strength
	AddTooltipPositive(tStatLines, "TXT_KEY_PRODUCTION_STRENGTH", kUnitInfo.Combat);

	-- Air Defense
	AddTooltipPositive(tStatLines, "TXT_KEY_PRODUCTION_UNIT_AIR_DEFENSE", kUnitInfo.BaseLandAirDefense);

	-- Intercept Range
	AddTooltipPositive(tStatLines, "TXT_KEY_PRODUCTION_UNIT_INTERCEPT_RANGE", kUnitInfo.AirInterceptRange);

	-- Air Slots (show when non-standard only)
	if kUnitInfo.Domain == DomainTypes.DOMAIN_AIR then
		local iAirSlots = kUnitInfo.AirUnitCap;
		if iAirSlots > 1 then
			AddTooltip(tStatLines, "TXT_KEY_PRODUCTION_UNIT_AIR_SLOTS", iAirSlots);
		elseif iAirSlots == 0 then
			AddTooltip(tStatLines, "TXT_KEY_PRODUCTION_UNIT_NO_AIR_SLOTS");
		end
	end

	-- Cargo
	if kUnitInfo.SpecialCargo then
		AddTooltip(tStatLines, "TXT_KEY_PRODUCTION_UNIT_CAN_CARRY", GameInfo.SpecialUnits[kUnitInfo.SpecialCargo].Description);
	end

	-- Unhappiness (can be negative)
	if not MOD_BALANCE_VP then
		AddTooltipNonZero(tStatLines, "TXT_KEY_PRODUCTION_UNIT_UNHAPPINESS", kUnitInfo.Unhappiness);
	end

	if next(tStatLines) then
		table.insert(tLines, table.concat(tStatLines, "[NEWLINE]"));
	end

	----------------------
	-- Ability section
	----------------------
	local tAbilityLines = {};

	-- Simple (boolean) abilities
	-- This approach is slower than using individual conditions, but is way better for developers and code readers
	-- Reminder: non-array tables are unordered in Lua
	local tAbilities = {
		MoveAfterPurchase = "TXT_KEY_PRODUCTION_UNIT_MOVE_AFTER_PURCHASE",
		PuppetPurchaseOverride = "TXT_KEY_PRODUCTION_UNIT_PUPPET_PURCHASABLE",
		FreeUpgrade = "TXT_KEY_PRODUCTION_UNIT_FREE_UPGRADE",
		RivalTerritory = "TXT_KEY_PRODUCTION_UNIT_RIVAL_TERRITORY",
		CanBuyCityState = "TXT_KEY_MISSION_BUY_CITY_STATE",
		SpreadReligion = "TXT_KEY_MISSION_SPREAD_RELIGION",
		RemoveHeresy = "TXT_KEY_MISSION_REMOVE_HERESY",
		FoundReligion = "TXT_KEY_MISSION_FOUND_RELIGION",
		CulExpOnDisbandUpgrade = "TXT_KEY_PRODUCTION_UNIT_CULTURE_ON_DISBAND_UPGRADE",
		HighSeaRaider = "TXT_KEY_PRODUCTION_UNIT_EXTRA_PLUNDER_GOLD",
		CopyYieldsFromExpendTile = "TXT_KEY_PRODUCTION_UNIT_EXPEND_COPY_TILE_YIELD",
	};

	for k, v in pairs(tAbilities) do
		AddTooltipIfTrue(tAbilityLines, v, kUnitInfo[k]);
	end

	-- Can move after upgrade (into this unit)
	AddTooltipIfTrue(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_MOVE_AFTER_UPGRADE", MOD_GLOBAL_MOVE_AFTER_UPGRADE and kUnitInfo.MoveAfterUpgrade);

	-- Found city
	if kUnitInfo.Found or kUnitInfo.FoundAbroad or kUnitInfo.FoundColony > 0 then
		local strFound;

		-- Technically, if FoundColony is a small number and Found is false, there is only a limited number of colonies that can be founded per game (see old Venice)
		-- But I don't see that feature being used anymore, so let's just assume colonies can always be founded
		if kUnitInfo.FoundColony > 0 then
			strFound = L("TXT_KEY_PRODUCTION_UNIT_FOUND_CITY_PUPPET");
		else
			if kUnitInfo.FoundAbroad then
				strFound = L("TXT_KEY_PRODUCTION_UNIT_FOUND_CITY_ABROAD");
			else
				strFound = L("TXT_KEY_PRODUCTION_UNIT_FOUND_CITY");
			end
			if kUnitInfo.FoundMid or kUnitInfo.FoundLate then
				strFound = strFound .. " " .. L("TXT_KEY_PRODUCTION_UNIT_FOUND_CITY_ADVANCED");
			end
		end

		table.insert(tAbilityLines, strFound);
	end

	-- Culture bomb
	local iRadius = kUnitInfo.CultureBombRadius;
	local iCultureBomb = kUnitInfo.NumberOfCultureBombs;
	if iRadius > 0 and iCultureBomb > 0 then
		if pCity then
			iRadius = iRadius + pActivePlayer:GetCultureBombBoost();
		end
		-- It is possible to have a negative radius boost, and a culture bomb radius of 0 is possible (claiming the tile the unit is on)
		if iRadius >= 0 then
			AddTooltip(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_CULTURE_BOMB", iRadius, iCultureBomb);
		end
	end

	-- Prevent spread
	local strTextKey = MOD_BALANCE_CORE_INQUISITOR_TWEAKS and "TXT_KEY_PRODUCTION_UNIT_PROHIBIT_SPREAD_PARTIAL" or "TXT_KEY_PRODUCTION_UNIT_PROHIBIT_SPREAD";
	AddTooltipIfTrue(tAbilityLines, strTextKey, kUnitInfo.ProhibitsSpread);

	-- Sell exotic goods
	AddTooltipPositive(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_SELL_EXOTIC_GOODS", kUnitInfo.NumExoticGoods);

	-- Ancient ruin reward modifier
	AddTooltipNonZero(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_GOODY_MODIFIER", kUnitInfo.GoodyModifier);

	-- Free promotions (ensure no duplicates)
	local tPromotionKeys = {};
	local tPromotionLines = {};
	for row in GameInfo.Unit_FreePromotions{UnitType = kUnitInfo.Type} do
		tPromotionKeys[row.PromotionType] = true;
		AddTooltip(tPromotionLines, GameInfo.UnitPromotions[row.PromotionType].Description);
	end
	-- Show these only in city view
	if pCity then
		if kUnitInfo.UnitEraUpgrade then
			for row in GameInfo.Unit_EraUnitPromotions{UnitType = kUnitInfo.Type, Value = 1} do
				if not tPromotionKeys[row.PromotionType] and pActivePlayer:GetCurrentEra() >= row.EraType then
					tPromotionKeys[row.PromotionType] = true;
					AddTooltip(tPromotionLines, GameInfo.UnitPromotions[row.PromotionType].Description);
				end
			end
		end
		for kPromotionInfo in GameInfo.UnitPromotions() do
			if not tPromotionKeys[kPromotionInfo.Type]
			and (pActivePlayer:IsFreePromotion(kPromotionInfo.ID) or pCity:IsFreePromotion(kPromotionInfo.ID))
			and CanHavePromotion(kUnitInfo, kPromotionInfo.Type) then
				tPromotionKeys[kPromotionInfo.Type] = true;
				AddTooltip(tPromotionLines, kPromotionInfo.Description);
			end
		end
	end
	if next(tPromotionLines) then
		AddTooltip(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_FREE_PROMOTIONS");
		table.insert(tAbilityLines, "[ICON_BULLET]" .. table.concat(tPromotionLines, "[NEWLINE][ICON_BULLET]"));
	end

	-- Free promotion in friendly lands
	if kUnitInfo.FriendlyLandsPromotion then
		AddTooltip(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_FREE_PROMOTIONS_FRIENDLY", GameInfo.UnitPromotions[kUnitInfo.FriendlyLandsPromotion].Description);
	end

	-- Builds (e.g. chop trees and build roads) and improvements
	local tBuildLines = {};
	local tImprovementLines = {};
	for row in GameInfo.Unit_Builds{UnitType = kUnitInfo.Type} do
		local kBuildInfo = GameInfo.Builds[row.BuildType];
		local kImprovementInfo = kBuildInfo.ImprovementType and GameInfo.Improvements[kBuildInfo.ImprovementType];
		local kPrereqTechInfo = kBuildInfo.PrereqTech and GameInfo.Technologies[kBuildInfo.PrereqTech];
		if kImprovementInfo then
			if not kImprovementInfo.GraphicalOnly then
				-- Is this a unique improvement, and should it show up?
				if not kImprovementInfo.CivilizationType or GameInfoTypes[kImprovementInfo.CivilizationType] == eActiveCiv then
					table.insert(tImprovementLines, L(kImprovementInfo.Description) .. AppendTech(kPrereqTechInfo));
				end
			end
		elseif kBuildInfo.ShowInPedia then
			table.insert(tBuildLines, L(kBuildInfo.Description) .. AppendTech(kPrereqTechInfo));
		end
	end
	if next(tBuildLines) then
		AddTooltip(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_BUILD_NON_IMPROVEMENTS");
		table.insert(tAbilityLines, "[ICON_BULLET]" .. table.concat(tBuildLines, "[NEWLINE][ICON_BULLET]"));
	end
	if next(tImprovementLines) then
		AddTooltip(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_BUILD_IMPROVEMENTS");
		table.insert(tAbilityLines, "[ICON_BULLET]" .. table.concat(tImprovementLines, "[NEWLINE][ICON_BULLET]"));
	end

	-- Instant yield when created
	local tInstantYields = {};
	for row in GameInfo.Unit_YieldOnCompletion{UnitType = kUnitInfo.Type} do
		table.insert(tInstantYields, GetInstantYieldString(row.YieldType, row.Yield));
	end
	if next(tInstantYields) then
		table.insert(tAbilityLines, L("TXT_KEY_PRODUCTION_UNIT_YIELD_ON_COMPLETION", table.concat(tInstantYields, ", ")));
	end

	-- These work on GP only
	if kUnitInfo.Special == "SPECIALUNIT_PEOPLE" then
		-- Global WLTKD on birth
		if kUnitInfo.WLTKDFromBirth then
			local iTrainPercent = Game and GameInfo.GameSpeeds[Game.GetGameSpeedType()].TrainPercent or 100;
			local iWLTKDTurn = math.floor(math.floor(GameDefines.CITY_RESOURCE_WLTKD_TURNS / 3) * iTrainPercent / 100);
			AddTooltipPositive(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_BIRTH_WLTKD", iWLTKDTurn);
		end

		-- Golden age on birth
		if kUnitInfo.GoldenAgeFromBirth then
			AddTooltipPositive(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_BIRTH_WLTKD", pActivePlayer:GetGoldenAgeLength());
		end

		-- Culture on birth to capital
		if kUnitInfo.CultureBoost then
			AddTooltipPositive(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_BIRTH_CULTURE", pActivePlayer:GetTotalJONSCulturePerTurnTimes100() * 4 / 100);
		end

		-- Free supply when expended
		AddTooltipPositive(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_EXPEND_SUPPLY", kUnitInfo.SupplyCapBoost);
	end

	-- Extra attack/move and heal on kill
	if kUnitInfo.ExtraAttackHealthOnKill then
		AddTooltip(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_EXTRA_ATTACK_HEAL_ON_KILL", GameDefines.PILLAGE_HEAL_AMOUNT);
	end

	-- Free resource when expended
	for row in GameInfo.Unit_ResourceQuantityExpended{UnitType = kUnitInfo.Type} do
		local kResourceInfo = GameInfo.Resources[row.ResourceType];
		AddTooltip(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_FREE_RESOURCE", row.Amount, kResourceInfo.IconString, kResourceInfo.Description);
	end

	-- Free XP to units when expended
	AddTooltipPositive(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_EXPEND_XP", kUnitInfo.TileXPOnExpend);

	-- Yields/bonuses when expended
	-- Avoid calling DLL where possible - table lookups are way faster
	local iGold = (kUnitInfo.BaseGold > 0 or kUnitInfo.BaseGoldTurnsToCount > 0 or kUnitInfo.NumGoldPerEra ~= 0) and pActivePlayer:GetTradeGold(eUnit) or 0;
	local strGold = (iGold > 0) and L("TXT_KEY_PRODUCTION_UNIT_TRADE_MISSION_GOLD", iGold);
	local iWLTKDTurn = MOD_BALANCE_CORE_NEW_GP_ATTRIBUTES and (kUnitInfo.BaseWLTKDTurns > 0) and pActivePlayer:GetTradeWLTKDTurns(eUnit) or 0;
	local strWLTKD = (iWLTKDTurn > 0) and L("TXT_KEY_PRODUCTION_UNIT_TRADE_MISSION_WLTKD", iWLTKDTurn);
	if strGold and strWLTKD then
		table.insert(tAbilityLines, string.format("%s: %s, %s", L("TXT_KEY_MISSION_CONDUCT_TRADE_MISSION"), strGold, strWLTKD));
	elseif strGold or strWLTKD then
		table.insert(tAbilityLines, string.format("%s: %s", L("TXT_KEY_MISSION_CONDUCT_TRADE_MISSION"), strGold or strWLTKD));
	end

	AddTooltipNonZero(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_TRADE_MISSION_RESTING_INFLUENCE", kUnitInfo.RestingPointChange);

	local iScience = (kUnitInfo.BaseBeakersTurnsToCount > 0) and pActivePlayer:GetDiscoverScience(eUnit) or 0;
	local strScience = (iScience > 0) and L("TXT_KEY_PRODUCTION_UNIT_DISCOVER_TECH_SCIENCE", iScience);
	local iTechs = kUnitInfo.NumFreeTechs;
	local strTechs = (iTechs > 0) and L("TXT_KEY_PRODUCTION_UNIT_DISCOVER_TECH", iTechs);
	if strScience and strTechs then
		table.insert(tAbilityLines, string.format("%s: %s, %s", L("TXT_KEY_MISSION_DISCOVER_TECH"), strTechs, strScience));
	elseif strScience or strTechs then
		table.insert(tAbilityLines, string.format("%s: %s", L("TXT_KEY_MISSION_DISCOVER_TECH"), strTechs or strScience));
	end

	local iCulture = (kUnitInfo.BaseCultureTurnsToCount > 0) and pActivePlayer:GetTreatiseCulture(eUnit) or 0;
	local strCulture = (iCulture > 0) and L("TXT_KEY_PRODUCTION_UNIT_GIVE_POLICIES_CULTURE", iCulture);
	local iPolicies = kUnitInfo.FreePolicies;
	local strPolicies = (iPolicies > 0) and L("TXT_KEY_PRODUCTION_UNIT_GIVE_POLICIES", iPolicies);
	if strCulture and strPolicies then
		table.insert(tAbilityLines, string.format("%s: %s, %s", L("TXT_KEY_MISSION_GIVE_POLICIES"), strPolicies, strCulture));
	elseif strCulture or strPolicies then
		table.insert(tAbilityLines, string.format("%s: %s", L("TXT_KEY_MISSION_GIVE_POLICIES"), strPolicies or strCulture));
	end

	local iGAP = (kUnitInfo.BaseTurnsForGAPToCount > 0) and pActivePlayer:GetBlastGAP(eUnit) or 0;
	local iGATurns = kUnitInfo.GoldenAgeTurns;
	if iGAP > 0 then
		AddTooltip(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_START_GOLDENAGE", iGAP);
	elseif iGATurns > 0 then
		-- Number of turns is dynamic so we won't know at this point
		AddTooltip(tAbilityLines, "TXT_KEY_MISSION_START_GOLDENAGE");
	end

	local iTourism = (kUnitInfo.OneShotTourism > 0) and pActivePlayer:GetBlastTourism(eUnit) or 0;
	if iTourism > 0 then
		local iOthersPercent = kUnitInfo.OneShotTourismPercentOthers;
		if iOthersPercent > 0 then
			AddTooltip(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_ONE_SHOT_TOURISM_OTHER_PLAYERS", iTourism, iOthersPercent);
		else
			AddTooltip(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_ONE_SHOT_TOURISM", iTourism);
		end
	end

	local iTourismTurn = (kUnitInfo.TourismBonusTurns > 0) and pActivePlayer:GetBlastTourismTurns(eUnit) or 0;
	AddTooltipPositive(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_CONCERT_TOUR", iTourismTurn);

	-- For hurry production, we only know the exact number if there's a city specified, or if it doesn't depend on population
	if pCity or kUnitInfo.HurryMultiplier == 0 then
		if pActiveCity then
			local iProduction = (kUnitInfo.BaseHurry > 0 or kUnitInfo.BaseProductionTurnsToCount > 0) and pActiveCity:GetHurryProduction(eUnit) or 0;
			AddTooltipPositive(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_HURRY_PRODUCTION", iProduction);
		end
	elseif kUnitInfo.BaseHurry > 0 or kUnitInfo.BaseProductionTurnsToCount > 0 or kUnitInfo.HurryMultiplier > 0 then
		AddTooltip(tAbilityLines, "TXT_KEY_MISSION_HURRY_PRODUCTION");
	end

	AddTooltipPositive(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_FREE_LUXURY", kUnitInfo.NumFreeLux);

	-- Bad abilities (placed at the end)
	local tNegativeAbilities = {
		Suicide = "TXT_KEY_PRODUCTION_UNIT_SUICIDE",
		CityAttackOnly = "TXT_KEY_PRODUCTION_UNIT_CITY_ATTACK_ONLY",
	};

	for k, v in pairs(tNegativeAbilities) do
		AddTooltipIfTrue(tAbilityLines, v, kUnitInfo[k]);
	end

	AddTooltipIfTrue(tAbilityLines, "TXT_KEY_PRODUCTION_UNIT_NO_EMBARK", MOD_GLOBAL_CANNOT_EMBARK and kUnitInfo.CannotEmbark);

	-- Bounty on this unit
	tInstantYields = {};
	for row in GameInfo.Unit_Bounties{UnitType = kUnitInfo.Type} do
		table.insert(tInstantYields, GetInstantYieldString(row.YieldType, row.Yield));
	end
	if next(tInstantYields) then
		table.insert(tAbilityLines, L("TXT_KEY_PRODUCTION_UNIT_BOUNTY", table.concat(tInstantYields, ", ")));
	end

	if next(tAbilityLines) then
		table.insert(tLines, table.concat(tAbilityLines, "[NEWLINE]"));
	end

	----------------------
	-- Requirement section
	-- Most are skipped in city view
	----------------------
	local tReqLines = {};

	-- Building requirement
	if not pCity then
		local tBuildings = {};
		for row in GameInfo.Unit_BuildingClassRequireds{UnitType = kUnitInfo.Type} do
			local eBuildingClass = GameInfoTypes[row.BuildingClassType];
			local eBuilding = pActivePlayer:GetCivilizationBuilding(eBuildingClass);
			-- Use default building if active civ doesn't have access to this building class
			if eBuilding == -1 then
				eBuilding = GameInfo.BuildingClasses[eBuildingClass].DefaultBuilding;
			end
			AddTooltip(tBuildings, GameInfo.Buildings[eBuilding].Description);
		end
		if next(tBuildings) then
			table.insert(tReqLines, L("TXT_KEY_PRODUCTION_REQUIRED_BUILDINGS", table.concat(tBuildings, ", ")));
		end
	end

	-- Buildings required for purchase/investment
	local tBuildings = {};
	for row in GameInfo.Unit_BuildingClassPurchaseRequireds{UnitType = kUnitInfo.Type} do
		local eBuildingClass = GameInfoTypes[row.BuildingClassType];
		local eBuilding = pCity and pCity:GetBuildingTypeFromClass(eBuildingClass, true) or pActivePlayer:GetCivilizationBuilding(eBuildingClass);
		-- Use default building if active civ doesn't have access to this building class
		if eBuilding == -1 then
			eBuilding = GameInfo.BuildingClasses[eBuildingClass].DefaultBuilding;
		end
		AddTooltip(tBuildings, GameInfo.Buildings[eBuilding].Description);
	end
	if next(tBuildings) then
		strTextKey = (iInvestedCost > 0) and "TXT_KEY_PRODUCTION_REQUIRED_BUILDINGS_INVEST" or "TXT_KEY_PRODUCTION_REQUIRED_BUILDINGS_PURCHASE";
		table.insert(tReqLines, L(strTextKey, table.concat(tBuildings, ", ")));
	end

	if not pCity then
		-- Project requirement
		if kUnitInfo.ProjectPrereq then
			AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_REQUIRED_PROJECT", GameInfo.Projects[kUnitInfo.ProjectPrereq].Description);
		end

		-- Policy requirement
		if kUnitInfo.PolicyType then
			AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_REQUIRED_POLICY", GameInfo.Policies[kUnitInfo.PolicyType].Description);
		end

		-- Belief requirement
		if kUnitInfo.BeliefRequired then
			AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_REQUIRED_BELIEF", GameInfo.Beliefs[kUnitInfo.BeliefRequired].ShortDescription);
		end

		-- Prereq techs
		local tTechs = {};
		if kUnitInfo.PrereqTech then
			AddTooltip(tTechs, GameInfo.Technologies[kUnitInfo.PrereqTech].Description);
		end
		for row in GameInfo.Unit_TechTypes{UnitType = kUnitInfo.Type} do
			AddTooltip(tTechs, GameInfo.Technologies[row.TechType].Description);
		end
		if next(tTechs) then
			table.insert(tReqLines, L("TXT_KEY_PRODUCTION_PREREQ_TECH", table.concat(tTechs, ", ")));
		end
	end

	-- Obsolete tech
	if kUnitInfo.ObsoleteTech then
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_OBSOLETE_TECH", GameInfo.Technologies[kUnitInfo.ObsoleteTech].Description);
	end

	-- Resource requirements
	for row in GameInfo.Unit_ResourceQuantityRequirements{UnitType = kUnitInfo.Type} do
		local kResourceInfo = GameInfo.Resources[row.ResourceType];
		AddTooltipPositive(tReqLines, "TXT_KEY_PRODUCTION_RESOURCES_REQUIRED", row.Cost, kResourceInfo.IconString, kResourceInfo.Description);
	end

	if kUnitInfo.ResourceType then
		local kResourceInfo = GameInfo.Resources[kUnitInfo.ResourceType];
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_TOTAL_RESOURCES_REQUIRED", 1, kResourceInfo.IconString, kResourceInfo.Description);
	end

	if MOD_UNITS_RESOURCE_QUANTITY_TOTALS then
		for row in GameInfo.Unit_ResourceQuantityTotals{UnitType = kUnitInfo.Type} do
			local kResourceInfo = GameInfo.Resources[row.ResourceType];
			AddTooltipPositive(tReqLines, "TXT_KEY_PRODUCTION_TOTAL_RESOURCES_REQUIRED", row.Amount, kResourceInfo.IconString, kResourceInfo.Description);
		end
	end

	-- Enhanced religion
	AddTooltipIfTrue(tReqLines, "TXT_KEY_PRODUCTION_UNIT_REQUIRE_ENHANCED_RELIGION", not pCity and kUnitInfo.RequiresEnhancedReligion);

	-- Unit class limits
	local iMaxGlobalInstance = kUnitClassInfo.MaxGlobalInstances;
	if iMaxGlobalInstance ~= -1 then
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_MAX_GLOBAL_INSTANCE", iMaxGlobalInstance);
	end
	local iMaxTeamInstance = kUnitClassInfo.MaxTeamInstances;
	if iMaxTeamInstance ~= -1 then
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_MAX_TEAM_INSTANCE", iMaxTeamInstance);
	end
	local iMaxPlayerInstance = kUnitClassInfo.MaxPlayerInstances;
	local iMaxCityInstance = kUnitClassInfo.UnitInstancePerCity;
	if iMaxCityInstance ~= -1 then
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_UNIT_MAX_CITY_INSTANCE", iMaxCityInstance);
	elseif iMaxPlayerInstance ~= -1 then
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_MAX_PLAYER_INSTANCE", iMaxPlayerInstance);
	end

	if next(tReqLines) then
		table.insert(tLines, table.concat(tReqLines, "[NEWLINE]"));
	end

	----------------------
	-- Pre-written section
	----------------------
	local tPreWrittenLines = {};

	-- Help text
	if kUnitInfo.Help then
		AddTooltip(tPreWrittenLines, kUnitInfo.Help);
	end

	-- Requirements text
	if bIncludeRequirementsInfo and kUnitInfo.Requirements then
		AddTooltip(tPreWrittenLines, kUnitInfo.Requirements);
	end

	if next(tPreWrittenLines) then
		table.insert(tLines, table.concat(tPreWrittenLines, "[NEWLINE][NEWLINE]"));
	end

	return table.concat(tLines, "[NEWLINE]" .. strSeparator .. "[NEWLINE]");
end

function GetHelpTextForBuilding(eBuilding, bExcludeName, _, bNoMaintenance, pCity)
	local kBuildingInfo = GameInfo.Buildings[eBuilding];
	local pActivePlayer = Players[Game.GetActivePlayer()];

	-- When viewing a (foreign) city, always show tooltips as they are for the city owner
	if pCity then
		pActivePlayer = Players[pCity:GetOwner()];
	end

	-- Sometimes a city is needed in tooltips not in city view; in that case use the capital city
	local pActiveCity = pCity or pActivePlayer:GetCapitalCity();

	local eBuildingClass = GameInfoTypes[kBuildingInfo.BuildingClass];
	local kBuildingClassInfo = GameInfo.BuildingClasses[eBuildingClass];
	local tLines = {};

	----------------------
	-- Header section
	----------------------
	local tHeaderLines = {};

	local iInvestedCost = pCity and pCity:GetBuildingInvestment(eBuilding) or 0;

	-- Name
	if not bExcludeName then
		local strName = BuildingColor(Locale.ToUpper(L(kBuildingInfo.Description)));
		if pCity and MOD_BALANCE_CORE_BUILDING_INVESTMENTS then
			if iInvestedCost > 0 then
				strName = strName .. L("TXT_KEY_INVESTED");
			end
		end
		table.insert(tHeaderLines, strName);
	end

	-- Unique Building? Usually unique to one civ, but it's possible that multiple civs have access to the same building
	local tCivAdjectives = {};
	for row in GameInfo.Civilization_BuildingClassOverrides{BuildingType = kBuildingInfo.Type} do
		table.insert(tCivAdjectives, GameInfo.Civilizations[row.CivilizationType].Adjective);
	end
	if next(tCivAdjectives) then
		-- Get the building it is replacing
		local kDefaultBuildingInfo = GameInfo.Buildings[kBuildingClassInfo.DefaultBuilding];
		local strCivAdj = table.concat(tCivAdjectives, "/");
		if kDefaultBuildingInfo then
			AddTooltip(tHeaderLines, "TXT_KEY_PRODUCTION_UNIQUE_BUILDING", strCivAdj, kDefaultBuildingInfo.Description);
		else
			-- This building isn't replacing anything
			AddTooltip(tHeaderLines, "TXT_KEY_PRODUCTION_UNIQUE_BUILDING_NO_DEFAULT", strCivAdj);
		end
	end

	if next(tHeaderLines) then
		table.insert(tLines, table.concat(tHeaderLines, "[NEWLINE]"));
	end

	----------------------
	-- Stats section
	----------------------
	local tStatLines = {};

	-- Costs
	if kBuildingInfo.FreeStartEra and Game.GetStartEra() >= GameInfoTypes[kBuildingInfo.FreeStartEra] then
		AddTooltip(tStatLines, "TXT_KEY_PRODUCTION_BUILDING_FREE_ON_FOUND");
	elseif kBuildingInfo.Cost > 0 or kBuildingInfo.FaithCost > 0 then
		local tCosts = {};
		local iProductionCost, iGoldCost, iFaithCost = 0, 0, 0;
		if kBuildingInfo.Cost > 0 then
			iProductionCost = (iInvestedCost > 0) and iInvestedCost or (pActiveCity and pActiveCity:GetBuildingProductionNeeded(eBuilding) or pActivePlayer:GetBuildingProductionNeeded(eBuilding));
			iGoldCost = pActiveCity and pActiveCity:GetBuildingPurchaseCost(eBuilding) or 0;
		end

		if kBuildingInfo.FaithCost > 0 then
			iFaithCost = pActiveCity and pActiveCity:GetBuildingFaithPurchaseCost(eBuilding) or 0;
		end

		if not kBuildingInfo.PurchaseOnly then
			AddTooltipPositive(tCosts, "TXT_KEY_PRODUCTION_COST_PRODUCTION", iProductionCost);
		end
		AddTooltipPositive(tCosts, "TXT_KEY_PRODUCTION_COST_GOLD", iGoldCost);
		AddTooltipPositive(tCosts, "TXT_KEY_PRODUCTION_COST_FAITH", iFaithCost);

		if next(tCosts) then
			table.insert(tStatLines, L("TXT_KEY_PRODUCTION_COST_PREFIX", table.concat(tCosts, " / ")));
		end
	end

	if kBuildingInfo.UnlockedByLeague and not Game.IsOption("GAMEOPTION_NO_LEAGUES") then
		local pLeague = Game.GetActiveLeague();
		if pLeague then
			local iCostPerPlayer = pLeague:GetProjectBuildingCostPerPlayer(eBuilding);
			local strCostPerPlayer = string.format("%s %s", L("TXT_KEY_PEDIA_COST_LABEL"), L("TXT_KEY_LEAGUE_PROJECT_COST_PER_PLAYER", iCostPerPlayer));
			table.insert(tStatLines, strCostPerPlayer);
		end
	end

	-- Maintenance
	if not bNoMaintenance then
		AddTooltipNonZero(tStatLines, "TXT_KEY_PRODUCTION_BUILDING_MAINTENANCE", kBuildingInfo.GoldMaintenance);
	end

	-- Retained on conquest? Don't show if it's your city
	if not (pCity and Game.GetActivePlayer() == pCity:GetOwner()) then
		if kBuildingInfo.NeverCapture then
			AddTooltip(tStatLines, "TXT_KEY_PRODUCTION_BUILDING_NEVER_CAPTURE");
		elseif kBuildingInfo.ConquestProb <= 0 then
			AddTooltip(tStatLines, "TXT_KEY_PRODUCTION_BUILDING_CONQEUST_PROB_0");
		elseif kBuildingInfo.ConquestProb >= 100 then
			AddTooltip(tStatLines, "TXT_KEY_PRODUCTION_BUILDING_CONQEUST_PROB_100");
		end
	end

	if next(tStatLines) then
		table.insert(tLines, table.concat(tStatLines, "[NEWLINE]"));
	end

	----------------------
	-- Yields and abilities section
	----------------------
	local tAbilityLines = {};
	local tYieldLines = {};
	local tLocalAbilityLines = {};
	local tGlobalAbilityLines = {};
	local tTeamAbilityLines = {};
	local tNewMedianLines = {};

	-- Yield change and yield modifier tooltips
	for kYieldInfo in GameInfo.Yields() do
		local eYield = kYieldInfo.ID;
		if eYield >= iNumYields then
			break;
		end

		-- Only show modified numbers in city view
		local fYield = pCity and (pCity:GetBuildingYieldRateTimes100(eBuilding, eYield) / 100) or Game.GetBuildingYieldChange(eBuilding, eYield);
		if fYield ~= 0 then
			AddTooltip(tYieldLines, "TXT_KEY_PRODUCTION_BUILDING_YIELD_CHANGE", kYieldInfo.IconString, kYieldInfo.Description, fYield);
		end

		local iModifier = pCity and pCity:GetBuildingYieldModifier(eBuilding, eYield) or Game.GetBuildingYieldModifier(eBuilding, eYield);
		if iModifier ~= 0 then
			AddTooltip(tYieldLines, "TXT_KEY_PRODUCTION_BUILDING_YIELD_MODIFIER", kYieldInfo.IconString, kYieldInfo.Description, iModifier);
		end

		local iGlobalMod = 0;
		for row in GameInfo.Building_GlobalYieldModifiers{BuildingType = kBuildingInfo.Type, YieldType = kYieldInfo.Type} do
			iGlobalMod = row.Yield;
			-- Not breaking here; taking the last row value like in DLL if duplicated
		end
		if eYield == YieldTypes.YIELD_CULTURE then
			iGlobalMod = iGlobalMod + kBuildingInfo.GlobalCultureRateModifier;
		end
		if iGlobalMod ~= 0 then
			AddTooltipGlobal(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_YIELD_MODIFIER", kYieldInfo.IconString, kYieldInfo.Description, iGlobalMod);
		end
	end

	-- Happiness (from all sources)
	local iHappinessTotal = kBuildingInfo.Happiness + kBuildingInfo.UnmoddedHappiness;

	-- Only show modified number in city view
	if pCity then
		iHappinessTotal = iHappinessTotal + pCity:GetReligionBuildingClassHappiness(eBuildingClass)
			+ pActivePlayer:GetExtraBuildingHappinessFromPolicies(eBuilding)
			+ pActivePlayer:GetPlayerBuildingClassHappiness(eBuildingClass);
	end

	AddTooltipNonZero(tYieldLines, "TXT_KEY_PRODUCTION_BUILDING_HAPPINESS", iHappinessTotal);
	AddTooltipNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_HAPPINESS_GLOBAL", kBuildingInfo.HappinessPerCity);
	AddTooltipPositive(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_HAPPINESS_FROM_POLICY", kBuildingInfo.HappinessPerXPolicies);

	-- Defense
	AddTooltipNonZero(tYieldLines, "TXT_KEY_PRODUCTION_BUILDING_DEFENSE", kBuildingInfo.Defense / 100);

	-- Defense modifier
	AddTooltipNonZero(tYieldLines, "TXT_KEY_PRODUCTION_BUILDING_DEFENSE_MODIFIER", kBuildingInfo.BuildingDefenseModifier);
	AddTooltipNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_DEFENSE_MODIFIER_GLOBAL", kBuildingInfo.GlobalDefenseMod);

	-- Hit points
	AddTooltipNonZero(tYieldLines, "TXT_KEY_PRODUCTION_BUILDING_HITPOINTS", kBuildingInfo.ExtraCityHitPoints);

	-- Damage reduction
	AddTooltipNonZero(tYieldLines, "TXT_KEY_PRODUCTION_BUILDING_DAMAGE_REDUCTION", kBuildingInfo.DamageReductionFlat);

	-- Great People Points and specialist slots
	local strSpecialistKey = kBuildingInfo.SpecialistType;
	if strSpecialistKey then
		local kSpecialistInfo = GameInfo.Specialists[strSpecialistKey];
		local iNumPoints = kBuildingInfo.GreatPeopleRateChange;
		if iNumPoints > 0 then
			table.insert(tYieldLines, string.format("[ICON_GREAT_PEOPLE] %s %d", L(kSpecialistInfo.GreatPeopleTitle), iNumPoints));
		end

		local iNumSlots = kBuildingInfo.SpecialistCount;
		if iNumSlots > 0 then
			-- Append a key such as TXT_KEY_SPECIALIST_ARTIST_SLOTS
			local strSpecialistSlotsKey = kSpecialistInfo.Description .. "_SLOTS";
			table.insert(tYieldLines, string.format("[ICON_GREAT_PEOPLE] %s %d", L(strSpecialistSlotsKey), iNumSlots));
		end
	end

	-- Great Work slots
	local iNumGreatWorks = kBuildingInfo.GreatWorkCount;
	local strGreatWorkKey = kBuildingInfo.GreatWorkSlotType;
	if strGreatWorkKey then
		AddTooltipPositive(tYieldLines, GameInfo.GreatWorkSlots[strGreatWorkKey].SlotsToolTipText, iNumGreatWorks);
	end

	-- Great Person rate
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_GPP_MODIFIER", kBuildingInfo.GreatPeopleRateModifier);
	AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_GPP_MODIFIER", kBuildingInfo.GlobalGreatPeopleRateModifier);
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_GPP_MODIFIER_FROM_CORPORATION", kBuildingInfo.GPRateModifierPerXFranchises);

	-- Great General rate
	AddTooltipNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_GGP_MODIFIER", kBuildingInfo.GreatGeneralRateModifier);

	-- Golden Age length modifier
	AddTooltipNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_GODLEN_AGE_LENGTH_MODIFIER", kBuildingInfo.GoldenAgeModifier);

	-- Unit upgrade cost modifier
	AddTooltipNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_UNIT_UPGRADE_COST_MODIFIER", kBuildingInfo.UnitUpgradeCostMod);

	-- Trained unit experience
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_UNIT_XP_ALL", kBuildingInfo.Experience);
	AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_UNIT_XP_ALL", kBuildingInfo.GlobalExperience);
	for row in GameInfo.Building_UnitCombatFreeExperiences{BuildingType = kBuildingInfo.Type} do
		AddTooltip(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_UNIT_XP_COMBAT", row.Experience, GameInfo.UnitCombatInfos[row.UnitCombatType].Description);
	end
	for row in GameInfo.Building_DomainFreeExperiences{BuildingType = kBuildingInfo.Type} do
		AddTooltip(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_UNIT_XP_DOMAIN", row.Experience, GameInfo.Domains[row.DomainType].Description);
	end
	for row in GameInfo.Building_DomainFreeExperiencesGlobal{BuildingType = kBuildingInfo.Type} do
		AddTooltipGlobal(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_UNIT_XP_DOMAIN", row.Experience, GameInfo.Domains[row.DomainType].Description);
	end
	for row in GameInfo.Building_DomainFreeExperiencePerGreatWork{BuildingType = kBuildingInfo.Type} do
		AddTooltip(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_UNIT_XP_DOMAIN_FROM_GREAT_WORK", row.Experience, GameInfo.Domains[row.DomainType].Description);
	end
	for row in GameInfo.Building_DomainFreeExperiencePerGreatWorkGlobal{BuildingType = kBuildingInfo.Type} do
		AddTooltip(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_UNIT_XP_DOMAIN_FROM_GREAT_WRITING_GLOBAL", row.Experience, GameInfo.Domains[row.DomainType].Description);
	end

	-- Food carried over on growth
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_FOOD_KEPT", kBuildingInfo.FoodKept);

	-- Air slots
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_AIR_SLOTS", kBuildingInfo.AirModifier);
	AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_AIR_SLOTS", kBuildingInfo.AirModifierGlobal);

	-- Missionary spread actions
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_SPREAD_ACTION", kBuildingInfo.ExtraMissionarySpreads);
	AddTooltipNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_SPREAD_ACTION_GLOBAL", kBuildingInfo.ExtraMissionarySpreadsGlobal);

	-- Pressure modifier
	local strTextKey = kBuildingInfo.UnlockedByBelief and "TXT_KEY_PRODUCTION_BUILDING_PRESSURE_MODIFIER_IF_MAJORITY" or "TXT_KEY_PRODUCTION_BUILDING_PRESSURE_MODIFIER";
	AddTooltipNonZero(tLocalAbilityLines, strTextKey, kBuildingInfo.ReligiousPressureModifier);
	AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_BASE_PRESSURE_MODIFIER", kBuildingInfo.BasePressureModifierGlobal);

	-- Defensive espionage modifier
	if not MOD_BALANCE_VP then
		AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_ESPIONAGE_MODIFIER", kBuildingInfo.EspionageModifier);
		AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_ESPIONAGE_MODIFIER", kBuildingInfo.GlobalEspionageModifier);
	end

	-- Garrison extra heal
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_GARRISON_HEAL_RATE", kBuildingInfo.HealRateChange);

	-- Nuke resistance
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_NUKE_RESISTANCE", kBuildingInfo.NukeModifier);

	-- Work rate modifier
	AddTooltipNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_WORK_RATE_MODIFIER", kBuildingInfo.WorkerSpeedModifier);

	-- Building production modifier
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_BUILDING_PRODUCTION_MODIFIER", kBuildingInfo.BuildingProductionModifier);

	-- Wonder production modifier
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_WONDER_PRODUCTION_MODIFIER", kBuildingInfo.WonderProductionModifier);

	-- Military unit production modifier
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_MILITARY_PRODUCTION_MODIFIER", kBuildingInfo.MilitaryProductionModifier);

	-- Spaceship part production modifier
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_SPACESHIP_PRODUCTION_MODIFIER", kBuildingInfo.SpaceProductionModifier);
	AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_SPACESHIP_PRODUCTION_MODIFIER", kBuildingInfo.GlobalSpaceProductionModifier);

	-- City connection modifier
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_CITY_CONNECTION_MODIFIER", kBuildingInfo.CityConnectionGoldModifier);
	AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_CITY_CONNECTION_MODIFIER", kBuildingInfo.CityConnectionTradeRouteModifier);

	-- Policy cost modifier
	AddTooltipNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_POLICY_COST_MODIFIER", kBuildingInfo.PolicyCostModifier);

	-- Border growth cost modifier
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_BORDER_GROWTH_COST_MODIFIER", kBuildingInfo.PlotCultureCostModifier);
	AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_BORDER_GROWTH_COST_MODIFIER", kBuildingInfo.GlobalPlotCultureCostModifier);

	-- Plot purchase cost modifier
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_PLOT_PURCHASE_COST_MODIFIER", kBuildingInfo.PlotBuyCostModifier);
	AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_PLOT_PURCHASE_COST_MODIFIER", kBuildingInfo.GlobalPlotBuyCostModifier);

	-- Tile/World Wonder culture to tourism
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_CULTURE_TO_TOURISM_TERRAIN_WONDER", kBuildingInfo.LandmarksTourismPercent);
	AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_CULTURE_TO_TOURISM_TERRAIN_WONDER", kBuildingInfo.GlobalLandmarksTourismPercent);

	-- Tourism from Great Works modifier
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_GREAT_WORK_TOURISM_MODIFIER", kBuildingInfo.GreatWorksTourismModifier);
	AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_GREAT_WORK_TOURISM_MODIFIER", kBuildingInfo.GlobalGreatWorksTourismModifier);

	-- Production modifier from trade routes with city states
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_PRODUCTION_MODIFIER_FROM_MINOR_TRADE_ROUTES", kBuildingInfo.CityStateTradeRouteProductionModifier);

	-- Discover tech science modifier
	AddTooltipNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_DISCOVER_TECH_SCIENCE_MODIFIER", kBuildingInfo.GreatScientistBeakerModifier);

	-- Instant yield on construction
	local tCompleteYields = {};
	for kYieldInfo in GameInfo.Yields() do
		local eYield = kYieldInfo.ID;
		if eYield >= iNumYields then
			break;
		end

		local strYieldType = kYieldInfo.Type;
		tCompleteYields[strYieldType] = 0;
		for row in GameInfo.Building_InstantYield{BuildingType = kBuildingInfo.Type, YieldType = strYieldType} do
			tCompleteYields[strYieldType] = row.Yield;
		end
	end
	tCompleteYields.YIELD_GOLD = tCompleteYields.YIELD_GOLD + kBuildingInfo.Gold;
	local tCompleteYieldStrings = {};
	for strYieldType, iYield in ipairs(tCompleteYields) do
		if iYield > 0 then
			table.insert(tCompleteYieldStrings, GetInstantYieldString(strYieldType, iYield));
		end
	end
	if next(tCompleteYieldStrings) then
		table.insert(tLocalAbilityLines, L("TXT_KEY_PRODUCTION_BUILDING_YIELD_ON_COMPLETION", table.concat(tCompleteYieldStrings, ", ")));
	end

	-- Instant population
	AddTooltipNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_GLOBAL_POPULATION", kBuildingInfo.GlobalPopulationChange);

	-- Victory points on completion
	AddTooltipNonZero(tTeamAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_VICTORY_POINTS_ON_COMPLETION", kBuildingInfo.VictoryPoints);

	-- Plunder modifier
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_PLUNDER_MODIFIER", kBuildingInfo.CapturePlunderModifier);

	-- Tech share
	AddTooltipPositive(tTeamAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_TECH_SHARE", kBuildingInfo.TechShare);

	-- Free techs
	AddTooltipPositive(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_FREE_TECHS", kBuildingInfo.FreeTechs);

	-- Free policies
	AddTooltipPositive(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_FREE_POLICIES", kBuildingInfo.FreePolicies);

	-- Free great people
	AddTooltipPositive(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_FREE_GP", kBuildingInfo.FreeGreatPeople);

	-- Free spies
	AddTooltipPositive(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_FREE_SPIES", kBuildingInfo.ExtraSpies);

	-- Starting spy rank
	AddTooltipPositive(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_SPY_RANK", kBuildingInfo.SpyRankChange);

	-- Instant spy rank
	AddTooltipPositive(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_INSTANT_SPY_RANK", kBuildingInfo.InstantSpyRankChange);

	-- Trade route bonuses
	AddTooltipNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_TRADE_ROUTES", kBuildingInfo.NumTradeRouteBonus);
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_LAND_TRADE_ROUTE_RANGE_MODIFIER", kBuildingInfo.TradeRouteLandDistanceModifier);
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_SEA_TRADE_ROUTE_RANGE_MODIFIER", kBuildingInfo.TradeRouteSeaDistanceModifier);
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_LAND_ETR_ORIGIN_GOLD", kBuildingInfo.TradeRouteLandGoldBonus / 100);
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_SEA_ETR_ORIGIN_GOLD", kBuildingInfo.TradeRouteSeaGoldBonus / 100);
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_ETR_DESTINATION_OUR_GOLD", kBuildingInfo.TradeRouteRecipientBonus);
	AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_ETR_DESTINATION_THEIR_GOLD", kBuildingInfo.TradeRouteTargetBonus);

	-- Unit copy
	AddTooltipIfTrue(tLocalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_UNIT_COPY", kBuildingInfo.InstantMilitaryIncrease > 0);

	-- Research agreement science modifier
	if Game.IsOption("GAMEOPTION_RESEARCH_AGREEMENTS") then
		-- 50 is base RA multiplier hardcoded in DLL
		AddTooltipPositive(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_RESEARCH_AGREEMENT_SCIENCE_MODIFIER", kBuildingInfo.MedianTechPercentChange * 100 / 50);
	end

	-- Needs modifiers
	if MOD_BALANCE_VP then
		AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_BUILDING_BASIC_NEEDS_MEDIAN_MODIFIER", kBuildingInfo.BasicNeedsMedianModifier);
		AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_BUILDING_GOLD_MEDIAN_MODIFIER", kBuildingInfo.GoldMedianModifier);
		AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_BUILDING_SCIENCE_MEDIAN_MODIFIER", kBuildingInfo.ScienceMedianModifier);
		AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_BUILDING_CULTURE_MEDIAN_MODIFIER", kBuildingInfo.CultureMedianModifier);
		AddTooltipNonZero(tLocalAbilityLines, "TXT_KEY_BUILDING_RELIGIOUS_UNREST_MODIFIER", kBuildingInfo.ReligiousUnrestModifier);

		AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_BUILDING_BASIC_NEEDS_MEDIAN_MODIFIER", kBuildingInfo.BasicNeedsMedianModifierGlobal);
		AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_BUILDING_GOLD_MEDIAN_MODIFIER", kBuildingInfo.GoldMedianModifierGlobal);
		AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_BUILDING_SCIENCE_MEDIAN_MODIFIER", kBuildingInfo.ScienceMedianModifierGlobal);
		AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_BUILDING_CULTURE_MEDIAN_MODIFIER", kBuildingInfo.CultureMedianModifierGlobal);
		AddTooltipGlobalNonZero(tGlobalAbilityLines, "TXT_KEY_BUILDING_RELIGIOUS_UNREST_MODIFIER", kBuildingInfo.ReligiousUnrestModifierGlobal);

		if not OptionsManager.IsNoBasicHelp() then
			if pCity then
				local iBasicModifierTotal = kBuildingInfo.BasicNeedsMedianModifier + kBuildingInfo.BasicNeedsMedianModifierGlobal;
				if iBasicModifierTotal ~= 0 then
					local iNewMedian = pCity:GetTheoreticalNewBasicNeedsMedian(eBuilding) / 100;
					local iOldMedian = pCity:GetBasicNeedsMedian() / 100;
					if iNewMedian ~= 0 or iOldMedian ~= 0 then
						AddTooltip(tNewMedianLines, "TXT_KEY_BUILDING_BASIC_NEEDS_NEW_MEDIAN", iNewMedian, iOldMedian);
					end
				end
				local iGoldModifierTotal = kBuildingInfo.GoldMedianModifier + kBuildingInfo.GoldMedianModifierGlobal;
				if iGoldModifierTotal ~= 0 then
					local iNewMedian = pCity:GetTheoreticalNewGoldMedian(eBuilding) / 100;
					local iOldMedian = pCity:GetGoldMedian() / 100;
					if iNewMedian ~= 0 or iOldMedian ~= 0 then
						AddTooltip(tNewMedianLines, "TXT_KEY_BUILDING_GOLD_NEW_MEDIAN", iNewMedian, iOldMedian);
					end
				end
				local iScienceModifierTotal = kBuildingInfo.ScienceMedianModifier + kBuildingInfo.ScienceMedianModifierGlobal;
				if iScienceModifierTotal ~= 0 then
					local iNewMedian = pCity:GetTheoreticalNewScienceMedian(eBuilding) / 100;
					local iOldMedian = pCity:GetScienceMedian() / 100;
					if iNewMedian ~= 0 or iOldMedian ~= 0 then
						AddTooltip(tNewMedianLines, "TXT_KEY_BUILDING_SCIENCE_NEW_MEDIAN", iNewMedian, iOldMedian);
					end
				end
				local iCultureModifierTotal = kBuildingInfo.CultureMedianModifier + kBuildingInfo.CultureMedianModifierGlobal;
				if iCultureModifierTotal ~= 0 then
					local iNewMedian = pCity:GetTheoreticalNewCultureMedian(eBuilding) / 100;
					local iOldMedian = pCity:GetCultureMedian() / 100;
					if iNewMedian ~= 0 or iOldMedian ~= 0 then
						AddTooltip(tNewMedianLines, "TXT_KEY_BUILDING_CULTURE_NEW_MEDIAN", iNewMedian, iOldMedian);
					end
				end
				local iReligionModifierTotal = kBuildingInfo.ReligiousUnrestModifier + kBuildingInfo.ReligiousUnrestModifierGlobal;
				if iReligionModifierTotal ~= 0 then
					local iNewUnhappyPerPop = pCity:GetTheoreticalNewReligiousUnrestPerMinorityFollower(eBuilding) / 100;
					local iOldUnhappyPerPop = pCity:GetReligiousUnrestPerMinorityFollower(eBuilding) / 100;
					if iNewUnhappyPerPop ~= 0 or iOldUnhappyPerPop ~= 0 then
						AddTooltip(tNewMedianLines, "TXT_KEY_BUILDING_RELIGIOUS_UNREST_NEW_THRESHOLD", iNewUnhappyPerPop, iOldUnhappyPerPop);
					end
				end
			end
		end
	else
		AddTooltipNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_UNHAPPINESS_MODIFIER", kBuildingInfo.UnhappinessModifier);
		AddTooltipNonZero(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_UNHAPPINESS_MODIFIER_CITY_COUNT", kBuildingInfo.CityCountUnhappinessMod);
	end

	-- Simple (boolean) abilities
	-- This approach is slower than using individual conditions, but is way better for developers and code readers
	-- Reminder: non-array tables are unordered in Lua
	local tLocalAbilities = {
		GoldenAge = "TXT_KEY_PRODUCTION_BUILDING_START_GOLDEN_AGE",
		AllowsWaterRoutes = "TXT_KEY_PRODUCTION_BUILDING_WATER_CONNECTION",
		AllowsIndustrialWaterRoutes = "TXT_KEY_PRODUCTION_BUILDING_WATER_INDUSTRIAL_CONNECTION",
		AllowsAirRoutes = "TXT_KEY_PRODUCTION_BUILDING_AIR_CONNECTION",
		ExtraLuxuries = "TXT_KEY_PRODUCTION_BUILDING_EXTRA_LUXURIES",
		Airlift = "TXT_KEY_PRODUCTION_BUILDING_AIRLIFT",
		NoOccupiedUnhappiness = "TXT_KEY_PRODUCTION_BUILDING_REMOVE_OCCUPIED_UNHAPPINESS",
		AllowsFoodTradeRoutes = "TXT_KEY_PRODUCTION_BUILDING_ITR_FOOD",
		AllowsProductionTradeRoutes = "TXT_KEY_PRODUCTION_BUILDING_ITR_PRODUCTION",
	};

	local tGlobalAbilities = {
	};

	local tTeamAbilities = {
		TeamShare = "TXT_KEY_PRODUCTION_BUILDING_TEAM_SHARE",
	};

	for k, v in pairs(tLocalAbilities) do
		AddTooltipIfTrue(tLocalAbilityLines, v, kBuildingInfo[k]);
	end

	for k, v in pairs(tGlobalAbilities) do
		AddTooltipIfTrue(tGlobalAbilityLines, v, kBuildingInfo[k]);
	end

	for k, v in pairs(tTeamAbilities) do
		AddTooltipIfTrue(tTeamAbilityLines, v, kBuildingInfo[k]);
	end

	-- Instant yield triggers
	local tGPExpendScalingYields = {};
	for kYieldInfo in GameInfo.Yields() do
		local eYield = kYieldInfo.ID;
		if eYield >= iNumYields then
			break;
		end

		local strYieldType = kYieldInfo.Type;

		tGPExpendScalingYields[strYieldType] = 0;
		for row in GameInfo.Building_YieldFromGPExpend{BuildingType = kBuildingInfo.Type, YieldType = strYieldType} do
			tGPExpendScalingYields[strYieldType] = row.Yield;
		end
	end

	local iGPExpendGold = kBuildingInfo.GreatPersonExpendGold;
	if MOD_BALANCE_VP then
		tGPExpendScalingYields.YIELD_GOLD = tGPExpendScalingYields.YIELD_GOLD + iGPExpendGold;
		iGPExpendGold = 0;
	end

	-- Now generate the tooltips
	local tInstantYields = {};
	for strYieldType, iYield in ipairs(tGPExpendScalingYields) do
		if iYield > 0 then
			table.insert(tInstantYields, GetInstantYieldString(strYieldType, iYield));
		end
	end
	if iGPExpendGold > 0 then
		AddTooltip(tGlobalAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_INSTANT_YIELD_GP_EXPEND", GetInstantYieldString("YIELD_GOLD", iGPExpendGold));
	end
	if next(tInstantYields) then
		table.insert(tGlobalAbilityLines, AppendEraScaling(L("TXT_KEY_PRODUCTION_BUILDING_INSTANT_YIELD_GP_EXPEND", table.concat(tInstantYields, ", "))));
	end
	-- End of instant yields

	if next(tYieldLines) then
		table.insert(tAbilityLines, table.concat(tYieldLines, "[NEWLINE]"));
	end

	if next(tLocalAbilityLines) then
		AddTooltip(tAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_LOCAL_EFFECTS");
		table.insert(tAbilityLines, "[ICON_BULLET]" .. table.concat(tLocalAbilityLines, "[NEWLINE][ICON_BULLET]"));
	end

	if next(tGlobalAbilityLines) then
		AddTooltip(tAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_GLOBAL_EFFECTS");
		table.insert(tAbilityLines, "[ICON_BULLET]" .. table.concat(tGlobalAbilityLines, "[NEWLINE][ICON_BULLET]"));
	end

	if next(tTeamAbilityLines) then
		AddTooltip(tAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_TEAM_EFFECTS");
		table.insert(tAbilityLines, "[ICON_BULLET]" .. table.concat(tTeamAbilityLines, "[NEWLINE][ICON_BULLET]"));
	end

	-- Influence with all city states on completion
	AddTooltipNonZero(tAbilityLines, "TXT_KEY_PRODUCTION_BUILDING_INFLUENCE_ON_COMPLETION", kBuildingInfo.MinorFriendshipChange);

	if next(tAbilityLines) then
		table.insert(tLines, table.concat(tAbilityLines, "[NEWLINE]"));
	end

	----------------------
	-- New medians (VP only)
	----------------------
	if next(tNewMedianLines) then
		table.insert(tNewMedianLines, 1, L("TXT_KEY_PRODUCTION_BUILDING_MEDIAN_CHANGES"));
		table.insert(tLines, table.concat(tNewMedianLines, "[NEWLINE]"));
	end

	----------------------
	-- Requirement section
	-- Most are skipped in city view
	----------------------
	local tReqLines = {};

	if not pCity then
		-- Simple (boolean) requirements
		-- This approach is slower than using individual conditions, but is way better for developers and code readers
		-- Reminder: non-array tables are unordered in Lua
		local tRequirements = {
			CapitalOnly = "TXT_KEY_PRODUCTION_BUILDING_CAPITAL",
			HolyCity = "TXT_KEY_PRODUCTION_BUILDING_HOLY_CITY",
			River = "TXT_KEY_PRODUCTION_BUILDING_RIVER",
			FreshWater = "TXT_KEY_PRODUCTION_BUILDING_FRESH_WATER",
			AnyWater = "TXT_KEY_PRODUCTION_BUILDING_COASTAL_OR_FRESH_WATER",
			Mountain = "TXT_KEY_PRODUCTION_BUILDING_MOUNTAIN_ADJACENT",
			NearbyMountainRequired = "TXT_KEY_PRODUCTION_BUILDING_MOUNTAIN_NEARBY",
			Hill = "TXT_KEY_PRODUCTION_BUILDING_HILL",
			Flat = "TXT_KEY_PRODUCTION_BUILDING_FLAT",
			IsNoWater = "TXT_KEY_PRODUCTION_BUILDING_NO_FRESH_WATER",
			IsNoRiver = "TXT_KEY_PRODUCTION_BUILDING_NO_RIVER",
			IsNoCoast = "TXT_KEY_PRODUCTION_BUILDING_NO_COASTAL",
		};

		for k, v in pairs(tRequirements) do
			AddTooltipIfTrue(tReqLines, v, kBuildingInfo[k]);
		end

		-- Coastal or whatever custom water size
		if kBuildingInfo.Water then
			local iMinWaterSize = kBuildingInfo.MinAreaSize;
			if iMinWaterSize == GameDefines.MIN_WATER_SIZE_FOR_OCEAN then
				AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_BUILDING_COASTAL");
			elseif iMinWaterSize > 0 then
				AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_BUILDING_COASTAL_CUSTOM_SIZE", iMinWaterSize);
			else
				AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_BUILDING_COASTAL_INCLUDING_LAKE");
			end
		end

		-- Nearby terrain
		if kBuildingInfo.NearbyTerrainRequired then
			AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_BUILDING_NEARBY_TERRAIN", GameInfo.Terrains[kBuildingInfo.NearbyTerrainRequired].Description);
		end

		-- Not on terrain
		if kBuildingInfo.ProhibitedCityTerrain then
			AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_BUILDING_NO_TERRAIN", GameInfo.Terrains[kBuildingInfo.ProhibitedCityTerrain].Description);
		end

		-- Mutually exclusive buildings
		local iExclusiveGroup = kBuildingInfo.MutuallyExclusiveGroup;
		if iExclusiveGroup ~= -1 then
			local tBuildings = {};
			for kExclusiveBuildingInfo in GameInfo.Buildings{MutuallyExclusiveGroup = iExclusiveGroup} do
				AddTooltip(tBuildings, kExclusiveBuildingInfo.Description);
			end
			if next(tBuildings) then
				table.insert(tReqLines, L("TXT_KEY_PRODUCTION_BUILDING_EXCLUSIVE_LOCAL", table.concat(tBuildings, ", ")));
			end
		end

		local tBuildings = {};
		for row in GameInfo.Building_ClassNeededNowhere{BuildingType = kBuildingInfo.Type} do
			local eExclusiveBuilding = pActivePlayer:GetCivilizationBuilding(GameInfoTypes[row.BuildingClassType]);
			-- Use default building if active civ doesn't have access to this building class
			if eExclusiveBuilding == -1 then
				eExclusiveBuilding = GameInfo.BuildingClasses[row.BuildingClassType].DefaultBuilding;
			end
			AddTooltip(tBuildings, GameInfo.Buildings[eExclusiveBuilding].Description);
		end
		if next(tBuildings) then
			table.insert(tReqLines, L("TXT_KEY_PRODUCTION_BUILDING_EXCLUSIVE_GLOBAL", table.concat(tBuildings, ", ")));
		end

		-- Prereq techs
		local tTechs = {};
		if kBuildingInfo.PrereqTech then
			AddTooltip(tTechs, GameInfo.Technologies[kBuildingInfo.PrereqTech].Description);
		end
		for row in GameInfo.Building_TechAndPrereqs{BuildingType = kBuildingInfo.Type} do
			AddTooltip(tTechs, GameInfo.Technologies[row.TechType].Description);
		end
		if next(tTechs) then
			table.insert(tReqLines, L("TXT_KEY_PRODUCTION_PREREQ_TECH", table.concat(tTechs, ", ")));
		end
	end

	-- Obsolete tech
	if kBuildingInfo.ObsoleteTech then
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_OBSOLETE_TECH", GameInfo.Technologies[kBuildingInfo.ObsoleteTech].Description);
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_BUILDING_OBSOLETE_TECH_REMARK");
	end

	-- Required number of policies
	local iNumRequired = kBuildingInfo.NumPoliciesNeeded;
	if pCity then
		iNumRequired = pCity:GetNumPoliciesNeeded(eBuilding);
	end
	if iNumRequired > 0 then
		local iNumHave = pActivePlayer:GetNumPolicies(true);
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_BUILDING_NUM_POLICY_NEEDED", iNumRequired, iNumHave);
	end

	-- Required unit level
	iNumRequired = kBuildingInfo.LevelPrereq;
	if iNumRequired > 0 then
		local iNumHave = pActivePlayer:GetHighestUnitLevel();
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_BUILDING_NUM_UNIT_LEVEL_NEEDED", iNumRequired, iNumHave);
	end

	-- Required number of cities
	iNumRequired = kBuildingInfo.CitiesPrereq;
	if iNumRequired > 0 then
		local iNumHave = pActivePlayer:GetNumCities();
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_BUILDING_NUM_CITY_NEEDED", iNumRequired, iNumHave);
	end

	-- Required national population
	iNumRequired = pActivePlayer:GetScalingNationalPopulationRequired(eBuilding);
	if iNumRequired > 0 then
		local iNumHave = pActivePlayer:GetTotalPopulation();
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_BUILDING_NUM_POPULATION_NATIONAL_NEEDED", iNumRequired, iNumHave);
	end

	-- Required local population
	iNumRequired = kBuildingInfo.LocalPopRequired;
	if iNumRequired > 0 then
		if pCity then
			local iNumHave = pCity:GetPopulation();
			AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_BUILDING_NUM_POPULATION_LOCAL_NEEDED", iNumRequired, iNumHave);
		else
			AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_BUILDING_NUM_POPULATION_LOCAL_NEEDED_NOT_CITY", iNumRequired);
		end
	end

	-- Building class limits
	local iMaxGlobalInstance = kBuildingClassInfo.MaxGlobalInstances;
	if iMaxGlobalInstance ~= -1 then
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_MAX_GLOBAL_INSTANCE", iMaxGlobalInstance);
	end
	local iMaxTeamInstance = kBuildingClassInfo.MaxTeamInstances;
	if iMaxTeamInstance ~= -1 then
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_MAX_TEAM_INSTANCE", iMaxTeamInstance);
	end
	local iMaxPlayerInstance = kBuildingClassInfo.MaxPlayerInstances;
	if iMaxPlayerInstance ~= -1 then
		AddTooltip(tReqLines, "TXT_KEY_PRODUCTION_MAX_PLAYER_INSTANCE", iMaxPlayerInstance);
	end

	if next(tReqLines) then
		table.insert(tLines, table.concat(tReqLines, "[NEWLINE]"));
	end

	----------------------
	-- Footer section(s)
	----------------------

	-- Pre-written Help text
	if not kBuildingInfo.Help then
		print("Building help is NULL:", L(kBuildingInfo.Description));
	else
		AddTooltip(tLines, kBuildingInfo.Help);
	end

	-- Investment rules (for unbuilt buildings only)
	if pCity and MOD_BALANCE_CORE_BUILDING_INVESTMENTS and pCity:GetNumRealBuilding(eBuilding) <= 0 and pCity:GetNumFreeBuilding(eBuilding) <= 0 then
		local iAmount = GameDefines.BALANCE_BUILDING_INVESTMENT_BASELINE * -1;
		local iWonderAmount = iAmount / 2;
		local strInvestRules = L("TXT_KEY_PRODUCTION_INVESTMENT_BUILDING", iAmount, iWonderAmount);
		table.insert(tLines, strInvestRules);
		local iCostModifier = pCity:GetWorldWonderCost(eBuilding);
		if iCostModifier > 0 then
			local strWonderCostMod = L("TXT_KEY_WONDER_COST_INCREASE_METRIC", iCostModifier);
			table.insert(tLines, strWonderCostMod);
		end
	end

	return table.concat(tLines, "[NEWLINE]" .. strSeparator .. "[NEWLINE]");
end

function GetHelpTextForImprovement(eImprovement, bExcludeName, bExcludeHeader)
	local kImprovementInfo = GameInfo.Improvements[eImprovement];
	local tLines = {};

	-- Header
	local bHaveHeader = false;
	if not bExcludeHeader then
		-- Name
		if not bExcludeName then
			table.insert(tLines, Locale.ToUpper(L(kImprovementInfo.Description)));
			table.insert(tLines, strSeparator);
		end
	end

	if bHaveHeader then
		table.insert(tLines, strSeparator);
	end

	-- Pre-written Help text
	if not kImprovementInfo.Help then
		print("Improvement help is NULL:", L(kImprovementInfo.Description));
	else
		local strWrittenHelp = L(kImprovementInfo.Help);
		-- Will include separator if there is extra info
		-- table.insert(tLines, strSeparator);
		table.insert(tLines, strWrittenHelp);
	end

	return table.concat(tLines, "[NEWLINE]");
end

function GetHelpTextForProject(eProject, bIncludeRequirementsInfo, pCity)
	local kProjectInfo = GameInfo.Projects[eProject];
	local pActivePlayer = Players[Game.GetActivePlayer()];
	local tLines = {};

	-- Name
	table.insert(tLines, Locale.ToUpper(L(kProjectInfo.Description)));

	-- Cost
	local iCost;
	if pCity then
		iCost = pCity:GetProjectProductionNeeded(eProject);
	else
		iCost = pActivePlayer:GetProjectProductionNeeded(eProject);
	end
	table.insert(tLines, strSeparator);
	table.insert(tLines, L("TXT_KEY_PRODUCTION_COST", iCost));

	-- Pre-written Help text
	if not kProjectInfo.Help then
		print("Project help is NULL:", L(kProjectInfo.Description));
	else
		local strWrittenHelp = L(kProjectInfo.Help);
		table.insert(tLines, strSeparator);
		table.insert(tLines, strWrittenHelp);
	end

	-- Hardcoded Requirements text
	if bIncludeRequirementsInfo and kProjectInfo.Requirements then
		table.insert(tLines, strSeparator);
		table.insert(tLines, L(kProjectInfo.Requirements));
	end

	return table.concat(tLines, "[NEWLINE]");
end

function GetHelpTextForProcess(eProcess)
	local kProcessInfo = GameInfo.Processes[eProcess];
	local tLines = {};
	local tCondition = {Process = kProcessInfo.Type};

	-- Name
	table.insert(tLines, Locale.ToUpper(L(kProcessInfo.Description)));

	-- This process builds a World Congress project?
	local kLeagueProjectInfo;
	local pLeague = Game.GetActiveLeague();
	if pLeague and not Game.IsOption("GAMEOPTION_NO_LEAGUES") then
		for row in GameInfo.LeagueProjects(tCondition) do
			kLeagueProjectInfo = row;
			break; -- there should only be one
		end
	end

	local strWrittenHelp;
	if kProcessInfo.Help then
		-- Pre-written Help text
		strWrittenHelp = L(kProcessInfo.Help);
	elseif kLeagueProjectInfo then
		-- Auto-generated Help text
		strWrittenHelp = L("TXT_KEY_TT_PROCESS_LEAGUE_PROJECT_HELP", kLeagueProjectInfo.Description);
	else
		print("Process help is NULL and it's not a league project:", L(kProcessInfo.Description));
	end

	if strWrittenHelp then
		table.insert(tLines, strSeparator);
		table.insert(tLines, strWrittenHelp);
	end

	-- Project details
	if kLeagueProjectInfo then
		table.insert(tLines, "");
		table.insert(tLines, pLeague:GetProjectDetails(kLeagueProjectInfo.ID, Game.GetActivePlayer()));
	end

	return table.concat(tLines, "[NEWLINE]");
end

-------------------------------------------------
-- Yield tooltips
-------------------------------------------------
function GetFoodTooltip(pCity)
	local tLines = {};

	if not OptionsManager.IsNoBasicHelp() then
		table.insert(tLines, L("TXT_KEY_FOOD_HELP_INFO"));
		table.insert(tLines, "");
	end

	local fFoodProgress = pCity:GetFoodTimes100() / 100;
	local iFoodNeeded = pCity:GrowthThreshold();

	table.insert(tLines, L("TXT_KEY_FOOD_PROGRESS", fFoodProgress, iFoodNeeded));
	table.insert(tLines, "");
	table.insert(tLines, pCity:GetYieldRateTooltip(YieldTypes.YIELD_FOOD));

	if MOD_BALANCE_VP then
		table.insert(tLines, "");
		table.insert(tLines, pCity:getPotentialUnhappinessWithGrowth());
	end

	return table.concat(tLines, "[NEWLINE]");
end

function GetProductionTooltip(pCity)
	local tLines = {};

	if not OptionsManager.IsNoBasicHelp() then
		table.insert(tLines, L("TXT_KEY_PRODUCTION_HELP_INFO"));
		table.insert(tLines, "");
	end

	table.insert(tLines, pCity:GetYieldRateTooltip(YieldTypes.YIELD_PRODUCTION));

	return table.concat(tLines, "[NEWLINE]");
end

function GetGoldTooltip(pCity)
	local tLines = {};

	if not OptionsManager.IsNoBasicHelp() then
		table.insert(tLines, L("TXT_KEY_GOLD_HELP_INFO"));
		table.insert(tLines, "");
	end

	table.insert(tLines, pCity:GetYieldRateTooltip(YieldTypes.YIELD_GOLD));

	return table.concat(tLines, "[NEWLINE]");
end

function GetScienceTooltip(pCity)
	if Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE) then
		return L("TXT_KEY_TOP_PANEL_SCIENCE_OFF_TOOLTIP");
	end

	local tLines = {};

	if not OptionsManager.IsNoBasicHelp() then
		table.insert(tLines, L("TXT_KEY_SCIENCE_HELP_INFO"));
		table.insert(tLines, "");
	end

	table.insert(tLines, pCity:GetYieldRateTooltip(YieldTypes.YIELD_SCIENCE));

	return table.concat(tLines, "[NEWLINE]");
end

function GetCultureTooltip(pCity)
	local tLines = {};
	if Game.IsOption(GameOptionTypes.GAMEOPTION_NO_POLICIES) then
		table.insert(tLines, L("TXT_KEY_TOP_PANEL_POLICIES_OFF_TOOLTIP"));
	else
		if not OptionsManager.IsNoBasicHelp() then
			table.insert(tLines, L("TXT_KEY_CULTURE_HELP_INFO"));
			table.insert(tLines, "");
		end
		table.insert(tLines, pCity:GetYieldRateTooltip(YieldTypes.YIELD_CULTURE));
	end

	table.insert(tLines, "[NEWLINE]");

	-- Border growth
	local eYield = YieldTypes.YIELD_CULTURE_LOCAL;
	table.insert(tLines, pCity:GetYieldRateTooltip(eYield));
	local fCultureStored = pCity:GetJONSCultureStoredTimes100() / 100;
	local iCultureNeeded = pCity:GetJONSCultureThreshold();
	local iBorderGrowth = pCity:GetYieldRateTimes100(eYield) / 100;

	local strBorderGrowthProgress = L("TXT_KEY_CULTURE_INFO", fCultureStored, iCultureNeeded);
	if iBorderGrowth > 0 then
		local iCultureTurns = math.ceil((iCultureNeeded - fCultureStored) / iBorderGrowth);
		strBorderGrowthProgress = strBorderGrowthProgress .. " " .. L("TXT_KEY_CULTURE_TURNS", iCultureTurns);
	end
	table.insert(tLines, strBorderGrowthProgress);

	return table.concat(tLines, "[NEWLINE]");
end

function GetFaithTooltip(pCity)
	if Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION) then
		return L("TXT_KEY_TOP_PANEL_RELIGION_OFF_TOOLTIP");
	end

	local tLines = {};
	if not OptionsManager.IsNoBasicHelp() then
		table.insert(tLines, L("TXT_KEY_FAITH_HELP_INFO"));
	end

	table.insert(tLines, pCity:GetYieldRateTooltip(YieldTypes.YIELD_FAITH));
	table.insert(tLines, strSeparator);

	-- Religion info
	table.insert(tLines, GetReligionTooltip(pCity));

	return table.concat(tLines, "[NEWLINE]");
end

function GetTourismTooltip(pCity)
	return pCity:GetYieldRateTooltip(YieldTypes.YIELD_TOURISM);
end

function GetCityHappinessTooltip(pCity)
	return pCity:GetCityHappinessBreakdown();
end

function GetCityUnhappinessTooltip(pCity)
	return pCity:GetCityUnhappinessBreakdown(true);
end

----------------------------------------------------------------
-- Diplomacy overview / player icon tooltip
----------------------------------------------------------------
function GetMoodInfo(eOtherPlayer)
	local eActivePlayer = Game.GetActivePlayer();
	local pActivePlayer = Players[eActivePlayer];
	local eActiveTeam = Game.GetActiveTeam();
	local pActiveTeam = Teams[eActiveTeam];
	local pOtherPlayer = Players[eOtherPlayer];
	local eOtherTeam = pOtherPlayer:GetTeam();
	local pOtherTeam = Teams[eOtherTeam];
	local iVisibleApproach = pActivePlayer:GetApproachTowardsUsGuess(eOtherPlayer);

	-- Always war!
	if pActiveTeam:IsAtWar(eOtherTeam) then
		if Game.IsOption(GameOptionTypes.GAMEOPTION_ALWAYS_WAR) or Game.IsOption(GameOptionTypes.GAMEOPTION_NO_CHANGING_WAR_PEACE) then
			return "[ICON_BULLET]" .. L("TXT_KEY_ALWAYS_WAR_TT");
		end
	end

	-- Get the opinion modifier table from the DLL and convert it into bullet points
	local tOpinion = pOtherPlayer:GetOpinionTable(eActivePlayer);
	if next(tOpinion) then
		return "[ICON_BULLET]" + table.concat(tOpinion, "[NEWLINE][ICON_BULLET]");
	end

	-- No specific modifiers are visible, so let's see what string we should use (based on visible approach towards us)
	-- Eliminated
	if not pOtherPlayer:IsAlive() then
		return "[ICON_BULLET]" .. L("TXT_KEY_DIPLO_ELIMINATED_INDICATOR");
	end

	-- Teammates
	if eActiveTeam == eOtherTeam then
		return "[ICON_BULLET]" .. L("TXT_KEY_DIPLO_HUMAN_TEAMMATE");
	end

	-- At war with us
	if pActiveTeam:IsAtWar(eOtherTeam) then
		return "[ICON_BULLET]" .. L("TXT_KEY_DIPLO_AT_WAR");
	end

	-- Appears Friendly
	if iVisibleApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_FRIENDLY then
		return "[ICON_BULLET]" .. L("TXT_KEY_DIPLO_FRIENDLY");
	end

	-- Appears Afraid
	if iVisibleApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_AFRAID then
		return "[ICON_BULLET]" .. L("TXT_KEY_DIPLO_AFRAID");
	end

	-- Appears Guarded
	if iVisibleApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_GUARDED then
		return "[ICON_BULLET]" .. L("TXT_KEY_DIPLO_GUARDED");
	end

	-- Appears Hostile
	if iVisibleApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_HOSTILE then
		return "[ICON_BULLET]" .. L("TXT_KEY_DIPLO_HOSTILE");
	end

	-- Appears Neutral, opinions deliberately hidden
	if Game.IsHideOpinionTable() then
		if pOtherPlayer:IsActHostileTowardsHuman(eActivePlayer) then
			return "[ICON_BULLET]" .. L("TXT_KEY_DIPLO_NEUTRAL_HOSTILE");
		end
		if pOtherTeam:GetTurnsSinceMeetingTeam(eActiveTeam) ~= 0 then
			return "[ICON_BULLET]" .. L("TXT_KEY_DIPLO_NEUTRAL_FRIENDLY");
		end
	end

	-- Appears Neutral, no opinions
	return "[ICON_BULLET]" .. L("TXT_KEY_DIPLO_DEFAULT_STATUS");
end

----------------------------------------------------------------
-- Religion tooltip
----------------------------------------------------------------
function GetReligionTooltip(pCity)
	if Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION) then
		return "";
	end

	local tReligions = {};
	local eMajorityReligion = pCity:GetReligiousMajority();
	local tLines = {};
	local tReligionFollowers = {};
	local iPressureMultiplier = GameDefines.RELIGION_MISSIONARY_PRESSURE_MULTIPLIER;

	-- First, determine the list of religions in this city and the follower count of each
	-- Religions with no followers are not shown even if there is accumulated pressure
	-- Also add the Holy City line at the top
	for kReligionInfo in GameInfo.Religions() do
		local eReligion = kReligionInfo.ID;
		local strReligionName = L(Game.GetReligionName(eReligion));
		local strIconString = kReligionInfo.IconString;
		tReligionFollowers[eReligion] = pCity:GetNumFollowers(eReligion);

		if pCity:IsHolyCityForReligion(eReligion) then
			table.insert(tLines, L("TXT_KEY_HOLY_CITY_TOOLTIP_LINE", strIconString, strReligionName));
		end

		if eReligion == eMajorityReligion then
			table.insert(tReligions, 1, kReligionInfo);
		elseif tReligionFollowers[eReligion] > 0 then
			table.insert(tReligions, kReligionInfo);
		end
	end

	-- Sort the religion list by majority and follower count, greater number first
	local function CompareReligion(kReligionInfo1, kReligionInfo2)
		local eReligion1 = kReligionInfo1.ID;
		local eReligion2 = kReligionInfo2.ID;
		if eMajorityReligion == eReligion1 then
			return true;
		end
		if eMajorityReligion == eReligion2 then
			return false;
		end
		return tReligionFollowers[eReligion1] > tReligionFollowers[eReligion2];
	end

	table.sort(tReligions, CompareReligion);

	-- Now generate the tooltips
	for _, kReligionInfo in ipairs(tReligions) do
		local eReligion = kReligionInfo.ID;
		local strIconString = kReligionInfo.IconString;
		local iPressure, _, iExistingPressure = pCity:GetPressurePerTurn(eReligion);
		local iFollowers = pCity:GetNumFollowers(eReligion);
		local iDisplayPressure = math.floor(iPressure / iPressureMultiplier);
		local iDisplayExistingPressure = math.floor(iExistingPressure / iPressureMultiplier);

		local strPressure = "";
		if iDisplayPressure > 0 or iDisplayExistingPressure > 0 then
			strPressure = L("TXT_KEY_RELIGIOUS_PRESSURE_STRING_EXTENDED", iDisplayExistingPressure, iDisplayPressure);
		end

		table.insert(tLines, L("TXT_KEY_RELIGION_TOOLTIP_LINE", strIconString, iFollowers, strPressure));
	end

	if #tReligions == 0 then
		return L("TXT_KEY_RELIGION_NO_FOLLOWERS");
	end

	return table.concat(tLines, "[NEWLINE]");
end
