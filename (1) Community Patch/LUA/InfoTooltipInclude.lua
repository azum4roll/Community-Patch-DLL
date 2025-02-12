print("This is the modded InfoTooltipInclude from Community Patch");

local MOD_BALANCE_VP = Game.IsCustomModOption("BALANCE_VP");
local MOD_BALANCE_CORE_JFD = Game.IsCustomModOption("BALANCE_CORE_JFD");
local MOD_BALANCE_CORE_BUILDING_INVESTMENTS = Game.IsCustomModOption("BALANCE_CORE_BUILDING_INVESTMENTS");
local MOD_UNITS_RESOURCE_QUANTITY_TOTALS = Game.IsCustomModOption("UNITS_RESOURCE_QUANTITY_TOTALS");
local strSeparator = "----------------";

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

local function PolicyColor(strText)
	return TextColor("[COLOR_MAGENTA]", strText);
end

local function TechColor(strText)
	return TextColor("[COLOR_CYAN]", strText);
end

local function BeliefColor(strText)
	return TextColor("[COLOR_WHITE]", strText);
end

local function GetBuildingYieldChangeTooltip(eBuilding, eYield, pCity, pActivePlayer)
	local kBuildingInfo = GameInfo.Buildings[eBuilding];
	local eBuildingClass = GameInfoTypes[kBuildingInfo.BuildingClass];
	local iYield = Game.GetBuildingYieldChange(eBuilding, eYield);

	-- Only show modified yields in city view
	if pCity then
		iYield = iYield + pCity:GetReligionBuildingClassYieldChange(eBuildingClass, eYield)
			+ pActivePlayer:GetPlayerBuildingClassYieldChange(eBuildingClass, eYield)
			+ pCity:GetLeagueBuildingClassYieldChange(eBuildingClass, eYield)
			+ pCity:GetLocalBuildingClassYield(eBuildingClass, eYield)
			+ pCity:GetBuildingYieldChangeFromCorporationFranchises(eBuildingClass, eYield)
			+ pActivePlayer:GetPolicyBuildingClassYieldChange(eBuildingClass, eYield)
			+ pCity:GetEventBuildingClassYield(eBuildingClass, eYield);

		if eYield == YieldTypes.YIELD_CULTURE then
			iYield = iYield + pCity:GetBuildingClassCultureChange(eBuildingClass);
		end

		if eYield == YieldTypes.YIELD_TOURISM then
			iYield = iYield + pCity:GetBuildingClassTourism(eBuildingClass);
			if kBuildingInfo.FaithCost > 0 and kBuildingInfo.Cost < 0 and (kBuildingInfo.UnlockedByBelief or kBuildingInfo.PolicyType) then
				iYield = iYield + pCity:GetFaithBuildingTourism();
			end

			local iTechEnhancedTourism = kBuildingInfo.TechEnhancedTourism;
			local eTech = GameInfoTypes[kBuildingInfo.EnhancedYieldTech];
			if iTechEnhancedTourism > 0 and pActivePlayer:HasTech(eTech) then
				iYield = iYield + iTechEnhancedTourism;
			end
		end

		if Game.IsWorldWonderClass(eBuildingClass) then
			iYield = iYield + pActivePlayer:GetExtraYieldWorldWonder(eBuilding, eYield);
		end
	end

	if iYield ~= 0 then
		local kYieldInfo = GameInfo.Yields[eYield];
		return Locale.Lookup("TXT_KEY_PRODUCTION_BUILDING_YIELD_CHANGE", kYieldInfo.IconString, kYieldInfo.Description, iYield);
	end

	return "";
end

local function GetBuildingYieldModifierTooltip(eBuilding, eYield, pCity, pActivePlayer)
	local kBuildingInfo = GameInfo.Buildings[eBuilding];
	local eBuildingClass = GameInfoTypes[kBuildingInfo.BuildingClass];
	local iModifier = Game.GetBuildingYieldModifier(eBuilding, eYield);

	-- Only show modified modifiers in city view
	if pCity then
		iModifier = iModifier + pActivePlayer:GetPolicyBuildingClassYieldModifier(eBuildingClass, eYield)
			+ pCity:GetReligionBuildingYieldRateModifier(eBuildingClass, eYield)
			+ pCity:GetEventBuildingClassModifier(eBuildingClass, eYield);
	end

	if iModifier ~= 0 then
		local kYieldInfo = GameInfo.Yields[eYield];
		return Locale.Lookup("TXT_KEY_PRODUCTION_BUILDING_YIELD_MODIFIER", kYieldInfo.IconString, kYieldInfo.Description, iModifier);
	end

	return "";
end

function GetHelpTextForUnit(eUnit, bIncludeRequirementsInfo, pCity)
	local kUnitInfo = GameInfo.Units[eUnit];
	local pActivePlayer = Players[Game.GetActivePlayer()];
	local tLines = {};

	local iInvestCost = pCity and pCity:GetUnitInvestment(eUnit) or 0;

	-- Name
	local strName = Locale.ToUpper(Locale.Lookup(kUnitInfo.Description));
	if iInvestCost > 0 then
		strName = strName .. Locale.Lookup("TXT_KEY_INVESTED");
	end
	table.insert(tLines, strName);
	table.insert(tLines, strSeparator);

	-- Cost
	if kUnitInfo.Cost > 0 then
		local iCost = (iInvestCost > 0) and iInvestCost or pActivePlayer:GetUnitProductionNeeded(eUnit);
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_COST", iCost));
	end

	-- Unique Unit? Usually unique to one civ, but it's possible that multiple civs have access to the same unit
	local tCivAdjectives = {};
	for row in GameInfo.Civilization_UnitClassOverrides{UnitType = kUnitInfo.Type} do
		table.insert(tCivAdjectives, GameInfo.Civilizations[row.CivilizationType].Adjective);
	end

	if next(tCivAdjectives) then
		-- Get the unit it is replacing
		local kDefaultUnitInfo = GameInfo.Units[GameInfo.UnitClasses[kUnitInfo.Class].DefaultUnit];
		local strCivAdj = table.concat(tCivAdjectives, "/");
		if kDefaultUnitInfo then
			table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_UNIQUE_UNIT", strCivAdj, kDefaultUnitInfo.Description));
		else
			-- This unit isn't replacing anything
			table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_UNIQUE_UNIT_NO_DEFAULT", strCivAdj));
		end
	end

	-- Moves
	if kUnitInfo.Domain ~= "DOMAIN_AIR" then
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_MOVEMENT", kUnitInfo.Moves));
	end

	-- Range
	local iRange = kUnitInfo.Range;
	if iRange ~= 0 then
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_RANGE", iRange));
	end

	-- Ranged Combat Strength
	local iRangedStrength = kUnitInfo.RangedCombat;
	if iRangedStrength ~= 0 then
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_RANGED_STRENGTH", iRangedStrength));
	end

	-- Combat Strength
	local iStrength = kUnitInfo.Combat;
	if iStrength ~= 0 then
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_STRENGTH", iStrength));
	end

	-- Air Defense
	local iAirDefense = kUnitInfo.BaseLandAirDefense;
	if iAirDefense ~= 0 then
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_AIR_DEFENSE", iAirDefense));
	end

	----------------------
	-- Ability section
	----------------------
	local tAbilityLines = {};

	-- Free promotions
	local tPromotionLines = {};
	for row in GameInfo.Unit_FreePromotions{UnitType = kUnitInfo.Type} do
		table.insert(tPromotionLines, "[ICON_BULLET]" .. Locale.Lookup(GameInfo.UnitPromotions[row.PromotionType].Description));
	end
	if next(tPromotionLines) then
		table.insert(tAbilityLines, Locale.Lookup("TXT_KEY_PRODUCTION_FREE_PROMOTIONS"));
		table.insert(tAbilityLines, "[ICON_BULLET]" .. table.concat(tPromotionLines, "[NEWLINE][ICON_BULLET]"));
	end

	if next(tAbilityLines) then
		table.insert(tLines, strSeparator);
		table.insert(tLines, table.concat(tAbilityLines, "[NEWLINE]"));
		table.insert(tLines, strSeparator);
	end

	----------------------
	-- Requirement section
	----------------------

	-- Building requirement
	local tBuildings = {};

	-- Tech requirements
	local kPrereqTechInfo = kUnitInfo.PrereqTech and GameInfo.Technologies[kUnitInfo.PrereqTech];
	if kPrereqTechInfo then
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_PREREQ_TECH", kPrereqTechInfo.Description));
	end

	local kObsoleteTechInfo = kUnitInfo.ObsoleteTech and GameInfo.Technologies[kUnitInfo.ObsoleteTech];
	if kObsoleteTechInfo then
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_OBSOLETE_TECH", kObsoleteTechInfo.Description));
	end

	-- Resource requirements
	for kResourceInfo in GameInfo.Resources() do
		local eResource = kResourceInfo.ID;
		local iNumResourceNeeded = Game.GetNumResourceRequiredForUnit(eUnit, eResource);
		if iNumResourceNeeded > 0 then
			table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_RESOURCES_REQUIRED", iNumResourceNeeded, kResourceInfo.IconString, kResourceInfo.Description));
		end
	end

	if MOD_UNITS_RESOURCE_QUANTITY_TOTALS then
		for kResourceInfo in GameInfo.Resources() do
			local eResource = kResourceInfo.ID;
			local iNumResourceTotalNeeded = Game.GetNumResourceTotalRequiredForUnit(eUnit, eResource);
			if iNumResourceTotalNeeded > 0 then
				table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_TOTAL_RESOURCES_REQUIRED", iNumResourceTotalNeeded, kResourceInfo.IconString, kResourceInfo.Description));
			end
		end
	end

	-- Pre-written Help text
	if not kUnitInfo.Help then
		print("Unit help is NULL:", Locale.Lookup(kUnitInfo.Description));
	else
		local strWrittenHelp = Locale.Lookup(kUnitInfo.Help);
		table.insert(tLines, strSeparator);
		table.insert(tLines, strWrittenHelp);
	end

	-- Hardcoded Requirements text
	if bIncludeRequirementsInfo and kUnitInfo.Requirements then
		table.insert(tLines, strSeparator);
		table.insert(tLines, Locale.Lookup(kUnitInfo.Requirements));
	end

	return table.concat(tLines, "[NEWLINE]");
end

function GetHelpTextForBuilding(eBuilding, bExcludeName, bExcludeHeader, bNoMaintenance, pCity)
	local kBuildingInfo = GameInfo.Buildings[eBuilding];
	local pActivePlayer = Players[Game.GetActivePlayer()];

	-- When viewing a (foreign) city, always show tooltips as they are for the city owner
	if pCity then
		pActivePlayer = Players[pCity:GetOwner()];
	end

	local eBuildingClass = GameInfoTypes[kBuildingInfo.BuildingClass];
	local tLines = {};

	-- Header
	local bHaveHeader = false;
	if not bExcludeHeader then
		local iInvestedCost = pCity:GetBuildingInvestment(eBuilding);

		-- Name
		if not bExcludeName then
			local strName =  Locale.ToUpper(Locale.Lookup(kBuildingInfo.Description));
			if pCity and MOD_BALANCE_CORE_BUILDING_INVESTMENTS then
				if iInvestedCost > 0 then
					strName = strName .. Locale.Lookup("TXT_KEY_INVESTED");
				end
			end
			table.insert(tLines, strName);
			table.insert(tLines, strSeparator);
		end

		-- Cost
		if kBuildingInfo.Cost > 0 then
			local iCost = pActivePlayer:GetBuildingProductionNeeded(eBuilding);
			if pCity then
				if iInvestedCost > 0 then
					iCost = iInvestedCost;
				end
			end

			table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_COST", iCost));
			bHaveHeader = true;
		end

		if kBuildingInfo.UnlockedByLeague and not Game.IsOption("GAMEOPTION_NO_LEAGUES") then
			local pLeague = Game.GetActiveLeague();
			if pLeague then
				local iCostPerPlayer = pLeague:GetProjectBuildingCostPerPlayer(eBuilding);
				local strCostPerPlayer = Locale.Lookup("TXT_KEY_PEDIA_COST_LABEL") .. " " .. Locale.Lookup("TXT_KEY_LEAGUE_PROJECT_COST_PER_PLAYER", iCostPerPlayer);
				table.insert(tLines, strCostPerPlayer);
				bHaveHeader = true;
			end
		end

		-- Maintenance
		if not bNoMaintenance then
			local iMaintenance = kBuildingInfo.GoldMaintenance;
			if iMaintenance ~= 0 then
				table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_BUILDING_MAINTENANCE", iMaintenance));
				bHaveHeader = true;
			end
		end

		-- Required number of policies
		local iNumRequired = kBuildingInfo.NumPoliciesNeeded;
		if pCity then
			iNumRequired = pCity:GetNumPoliciesNeeded(eBuilding);
		end
		if iNumRequired > 0 then
			local iNumHave = pActivePlayer:GetNumPolicies(true);
			table.insert(tLines, Locale.Lookup("TXT_KEY_TT_NUM_POLICY_NEEDED_LABEL", iNumRequired, iNumHave));
			bHaveHeader = true;
		end

		-- Required national population
		iNumRequired = pActivePlayer:GetScalingNationalPopulationRequired(eBuilding);
		if iNumRequired > 0 then
			local iNumHave = pActivePlayer:GetTotalPopulation();
			table.insert(tLines, Locale.Lookup("TXT_KEY_TT_NUM_POPULATION_NATIONAL_NEEDED_LABEL", iNumRequired, iNumHave));
			bHaveHeader = true;
		end

		-- Required local population
		iNumRequired = kBuildingInfo.LocalPopRequired;
		if pCity and iNumRequired > 0 then
			local iNumHave = pCity:GetPopulation();
			table.insert(tLines, Locale.Lookup("TXT_KEY_TT_NUM_POPULATION_LOCAL_NEEDED_LABEL", iNumRequired, iNumHave));
			bHaveHeader = true;
		end
	end

	if bHaveHeader then
		table.insert(tLines, strSeparator);
	end

	-- Happiness (from all sources)
	local iHappinessTotal = kBuildingInfo.Happiness + kBuildingInfo.UnmoddedHappiness;

	-- Only show modified number in city view
	if pCity then
		iHappinessTotal = iHappinessTotal + pCity:GetReligionBuildingClassHappiness(eBuildingClass)
			+ pActivePlayer:GetExtraBuildingHappinessFromPolicies(eBuilding)
			+ pActivePlayer:GetPlayerBuildingClassHappiness(eBuildingClass);
	end

	if iHappinessTotal ~= 0 then
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_BUILDING_HAPPINESS", iHappinessTotal));
	end

	-- Needs modifiers
	if MOD_BALANCE_VP then
		local iBasicModifier = kBuildingInfo.BasicNeedsMedianModifier;
		if iBasicModifier ~= 0 then
			table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_BASIC_NEEDS_MEDIAN_MODIFIER", iBasicModifier));
		end
		local iGoldModifier = kBuildingInfo.GoldMedianModifier;
		if iGoldModifier ~= 0 then
			table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_GOLD_MEDIAN_MODIFIER", iGoldModifier));
		end
		local iScienceModifier = kBuildingInfo.ScienceMedianModifier;
		if iScienceModifier ~= 0 then
			table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_SCIENCE_MEDIAN_MODIFIER", iScienceModifier));
		end
		local iCultureModifier = kBuildingInfo.CultureMedianModifier;
		if iCultureModifier ~= 0 then
			table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_CULTURE_MEDIAN_MODIFIER", iCultureModifier));
		end
		local iReligionModifier = kBuildingInfo.ReligiousUnrestModifier;
		if iReligionModifier ~= 0 then
			table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_RELIGIOUS_UNREST_MODIFIER", iReligionModifier));
		end

		local iBasicModifierGlobal = kBuildingInfo.BasicNeedsMedianModifierGlobal;
		if iBasicModifierGlobal ~= 0 then
			table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_BASIC_NEEDS_MEDIAN_MODIFIER_GLOBAL", iBasicModifierGlobal));
		end
		local iGoldModifierGlobal = kBuildingInfo.GoldMedianModifierGlobal;
		if iGoldModifierGlobal ~= 0 then
			table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_GOLD_MEDIAN_MODIFIER_GLOBAL", iGoldModifierGlobal));
		end
		local iScienceModifierGlobal = kBuildingInfo.ScienceMedianModifierGlobal;
		if iScienceModifierGlobal ~= 0 then
			table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_SCIENCE_MEDIAN_MODIFIER_GLOBAL", iScienceModifierGlobal));
		end
		local iCultureModifierGlobal = kBuildingInfo.CultureMedianModifierGlobal;
		if iCultureModifierGlobal ~= 0 then
			table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_CULTURE_MEDIAN_MODIFIER_GLOBAL", iCultureModifierGlobal));
		end
		local iReligionModifierGlobal = kBuildingInfo.ReligiousUnrestModifierGlobal;
		if iReligionModifierGlobal ~= 0 then
			table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_RELIGIOUS_UNREST_MODIFIER_GLOBAL", iReligionModifierGlobal));
		end

		if not OptionsManager.IsNoBasicHelp() then
			if pCity then
				local iBasicModifierTotal = iBasicModifier + iBasicModifierGlobal;
				if iBasicModifierTotal ~= 0 then
					local iNewMedian = pCity:GetTheoreticalNewBasicNeedsMedian(eBuilding) / 100;
					local iOldMedian = pCity:GetBasicNeedsMedian() / 100;
					if iNewMedian ~= 0 or iOldMedian ~= 0 then
						table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_BASIC_NEEDS_NEW_MEDIAN", iNewMedian, iOldMedian));
					end
				end
				local iGoldModifierTotal = iGoldModifier + iGoldModifierGlobal;
				if iGoldModifierTotal ~= 0 then
					local iNewMedian = pCity:GetTheoreticalNewGoldMedian(eBuilding) / 100;
					local iOldMedian = pCity:GetGoldMedian() / 100;
					if iNewMedian ~= 0 or iOldMedian ~= 0 then
						table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_GOLD_NEW_MEDIAN", iNewMedian, iOldMedian));
					end
				end
				local iScienceModifierTotal = iScienceModifier + iScienceModifierGlobal;
				if iScienceModifierTotal ~= 0 then
					local iNewMedian = pCity:GetTheoreticalNewScienceMedian(eBuilding) / 100;
					local iOldMedian = pCity:GetScienceMedian() / 100;
					if iNewMedian ~= 0 or iOldMedian ~= 0 then
						table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_SCIENCE_NEW_MEDIAN", iNewMedian, iOldMedian));
					end
				end
				local iCultureModifierTotal = iCultureModifier + iCultureModifierGlobal;
				if iCultureModifierTotal ~= 0 then
					local iNewMedian = pCity:GetTheoreticalNewCultureMedian(eBuilding) / 100;
					local iOldMedian = pCity:GetCultureMedian() / 100;
					if iNewMedian ~= 0 or iOldMedian ~= 0 then
						table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_CULTURE_NEW_MEDIAN", iNewMedian, iOldMedian));
					end
				end
				local iReligionModifierTotal = iReligionModifier + iReligionModifierGlobal;
				if iReligionModifierTotal ~= 0 then
					local iNewUnhappyPerPop = pCity:GetTheoreticalNewReligiousUnrestPerMinorityFollower(eBuilding) / 100;
					local iOldUnhappyPerPop = pCity:GetReligiousUnrestPerMinorityFollower(eBuilding) / 100;
					if iNewUnhappyPerPop ~= 0 or iOldUnhappyPerPop ~= 0 then
						table.insert(tLines, Locale.Lookup("TXT_KEY_BUILDING_RELIGIOUS_UNREST_NEW_THRESHOLD", iNewUnhappyPerPop, iOldUnhappyPerPop));
					end
				end
			end
		end
	end

	-- Yield change and yield modifier tooltips
	for kYieldInfo in GameInfo.Yields() do
		local eYield = kYieldInfo.ID;
		if not MOD_BALANCE_CORE_JFD and eYield >= YieldTypes.YIELD_JFD_HEALTH then
			break;
		end

		local strTooltip = GetBuildingYieldChangeTooltip(eBuilding, eYield, pCity, pActivePlayer);
		if strTooltip ~= "" then
			table.insert(tLines, strTooltip);
		end

		strTooltip = GetBuildingYieldModifierTooltip(eBuilding, eYield, pCity, pActivePlayer);
		if strTooltip ~= "" then
			table.insert(tLines, strTooltip);
		end
	end

	-- Defense
	local iDefense = kBuildingInfo.Defense;
	if iDefense ~= 0 then
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_BUILDING_DEFENSE", iDefense / 100));
	end

	-- Defense modifier
	local iDefenseMod = kBuildingInfo.BuildingDefenseModifier;
	if iDefenseMod ~= 0 then
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_BUILDING_DEFENSE_MODIFIER", iDefenseMod));
	end

	-- Hit points
	local iHitPoints = kBuildingInfo.ExtraCityHitPoints;
	if iHitPoints ~= 0 then
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_BUILDING_HITPOINTS", iHitPoints));
	end

	-- Damage reduction
	local iDamageReductionFlat = kBuildingInfo.DamageReductionFlat;
	if iDamageReductionFlat ~= 0 then
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_BUILDING_DAMAGE_REDUCTION", iDamageReductionFlat));
	end

	-- Great People Points and specialist slots
	local strSpecialistKey = kBuildingInfo.SpecialistType;
	if strSpecialistKey then
		local kSpecialistInfo = GameInfo.Specialists[strSpecialistKey];
		local iNumPoints = kBuildingInfo.GreatPeopleRateChange;
		if iNumPoints > 0 then
			table.insert(tLines, "[ICON_GREAT_PEOPLE] " .. Locale.Lookup(kSpecialistInfo.GreatPeopleTitle) .. " " .. iNumPoints);
		end

		if kBuildingInfo.SpecialistCount > 0 then
			-- Append a key such as TXT_KEY_SPECIALIST_ARTIST_SLOTS
			local strSpecialistSlotsKey = kSpecialistInfo.Description .. "_SLOTS";
			table.insert(tLines, "[ICON_GREAT_PEOPLE] " .. Locale.Lookup(strSpecialistSlotsKey) .. " " .. kBuildingInfo.SpecialistCount);
		end
	end

	-- TODO: change this to include all GP rate changes (e.g. Garden)
	if pCity then
		local iCorpGPChange = kBuildingInfo.GPRateModifierPerXFranchises;
		if iCorpGPChange ~= 0 then
			iCorpGPChange = pCity:GetGPRateModifierPerXFranchises();
			if iCorpGPChange ~= 0 then
				local localizedText = Locale.Lookup("TXT_KEY_BUILDING_CORP_GP_CHANGE", iCorpGPChange);
				table.insert(tLines, localizedText);
			end
		end
	end

	-- Great Work slots
	local iNumGreatWorks = kBuildingInfo.GreatWorkCount;
	local strGreatWorkKey = kBuildingInfo.GreatWorkSlotType;
	if iNumGreatWorks > 0 and strGreatWorkKey then
		local localizedText = Locale.Lookup(GameInfo.GreatWorkSlots[strGreatWorkKey].SlotsToolTipText, iNumGreatWorks);
		table.insert(tLines, localizedText);
	end

	-- Pre-written Help text
	if not kBuildingInfo.Help then
		print("Building help is NULL:", Locale.Lookup(kBuildingInfo.Description));
	else
		local strWrittenHelp = Locale.Lookup(kBuildingInfo.Help);
		table.insert(tLines, strSeparator);
		table.insert(tLines, strWrittenHelp);
	end

	-- Investment rules (for unbuilt buildings only)
	if pCity and MOD_BALANCE_CORE_BUILDING_INVESTMENTS and pCity:GetNumRealBuilding(eBuilding) <= 0 and pCity:GetNumFreeBuilding(eBuilding) <= 0 then
		local iAmount = GameDefines.BALANCE_BUILDING_INVESTMENT_BASELINE * -1;
		local iWonderAmount = iAmount / 2;
		local strInvestRules = Locale.Lookup("TXT_KEY_PRODUCTION_INVESTMENT_BUILDING", iAmount, iWonderAmount);
		table.insert(tLines, strSeparator);
		table.insert(tLines, strInvestRules);
		local iCostModifier = pCity:GetWorldWonderCost(eBuilding);
		if iCostModifier > 0 then
			local strWonderCostMod = Locale.Lookup("TXT_KEY_WONDER_COST_INCREASE_METRIC", iCostModifier);
			table.insert(tLines, strSeparator);
			table.insert(tLines, strWonderCostMod);
		end
	end

	return table.concat(tLines, "[NEWLINE]");
end

function GetHelpTextForImprovement(eImprovement, bExcludeName, bExcludeHeader)
	local kImprovementInfo = GameInfo.Improvements[eImprovement];
	local tLines = {};

	-- Header
	local bHaveHeader = false;
	if not bExcludeHeader then
		-- Name
		if not bExcludeName then
			table.insert(tLines, Locale.ToUpper(Locale.Lookup(kImprovementInfo.Description)));
			table.insert(tLines, strSeparator);
		end
	end

	if bHaveHeader then
		table.insert(tLines, strSeparator);
	end

	-- Pre-written Help text
	if not kImprovementInfo.Help then
		print("Improvement help is NULL:", Locale.Lookup(kImprovementInfo.Description));
	else
		local strWrittenHelp = Locale.Lookup(kImprovementInfo.Help);
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
	table.insert(tLines, Locale.ToUpper(Locale.Lookup(kProjectInfo.Description)));

	-- Cost
	local iCost;
	if pCity then
		iCost = pCity:GetProjectProductionNeeded(eProject);
	else
		iCost = pActivePlayer:GetProjectProductionNeeded(eProject);
	end
	table.insert(tLines, strSeparator);
	table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_COST", iCost));

	-- Pre-written Help text
	if not kProjectInfo.Help then
		print("Project help is NULL:", Locale.Lookup(kProjectInfo.Description));
	else
		local strWrittenHelp = Locale.Lookup(kProjectInfo.Help);
		table.insert(tLines, strSeparator);
		table.insert(tLines, strWrittenHelp);
	end

	-- Hardcoded Requirements text
	if bIncludeRequirementsInfo and kProjectInfo.Requirements then
		table.insert(tLines, strSeparator);
		table.insert(tLines, Locale.Lookup(kProjectInfo.Requirements));
	end

	return table.concat(tLines, "[NEWLINE]");
end

function GetHelpTextForProcess(eProcess)
	local kProcessInfo = GameInfo.Processes[eProcess];
	local tLines = {};
	local tCondition = {Process = kProcessInfo.Type};

	-- Name
	table.insert(tLines, Locale.ToUpper(Locale.Lookup(kProcessInfo.Description)));

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
		strWrittenHelp = Locale.Lookup(kProcessInfo.Help);
	elseif kLeagueProjectInfo then
		-- Auto-generated Help text
		strWrittenHelp = Locale.Lookup("TXT_KEY_TT_PROCESS_LEAGUE_PROJECT_HELP", kLeagueProjectInfo.Description);
	else
		print("Process help is NULL and it's not a league project:", Locale.Lookup(kProcessInfo.Description));
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

-- Helper function
local function GetYieldTooltip(pCity, eYield)
	local strIconString = GameInfo.Yields[eYield].IconString;
	local tLines = {};

	local iBaseYield, strBaseYieldTooltip = pCity:GetBaseYieldRate(eYield, true);
	local strModifierTooltip = pCity:GetYieldModifierTooltip(eYield);
	local iTotalYield = pCity:GetYieldRateTimes100(eYield) / 100;
	local iPostYield, strPostYieldTooltip = pCity:GetPostModifierYieldRate(eYield, true);
	table.insert(tLines, strBaseYieldTooltip);
	table.insert(tLines, strSeparator);
	if strModifierTooltip ~= "" or strPostYieldTooltip ~= "" then
		table.insert(tLines, Locale.Lookup("TXT_KEY_YIELD_BASE", iBaseYield, strIconString));
		table.insert(tLines, strModifierTooltip);
		table.insert(tLines, strSeparator);
		table.insert(tLines, Locale.Lookup("TXT_KEY_YIELD_POST_MODIFIER", iTotalYield - iPostYield, strIconString));
		table.insert(tLines, strPostYieldTooltip);
		table.insert(tLines, strSeparator);
	end
	table.insert(tLines, Locale.Lookup("TXT_KEY_YIELD_TOTAL", iTotalYield, strIconString));

	return table.concat(tLines, "[NEWLINE]");
end

function GetFoodTooltip(pCity)
	local eYield = YieldTypes.YIELD_FOOD;
	local tLines = {};

	if not OptionsManager.IsNoBasicHelp() then
		table.insert(tLines, Locale.Lookup("TXT_KEY_FOOD_HELP_INFO"));
		table.insert(tLines, "");
	end

	local fFoodProgress = pCity:GetFoodTimes100() / 100;
	local iFoodNeeded = pCity:GrowthThreshold();

	table.insert(tLines, Locale.Lookup("TXT_KEY_FOOD_PROGRESS", fFoodProgress, iFoodNeeded));
	table.insert(tLines, "");
	table.insert(tLines, GetYieldTooltip(pCity, eYield));

	if MOD_BALANCE_VP then
		table.insert(tLines, "");
		table.insert(tLines, pCity:getPotentialUnhappinessWithGrowth());
	end

	return table.concat(tLines, "[NEWLINE]");
end

function GetProductionTooltip(pCity)
	local eYield = YieldTypes.YIELD_PRODUCTION;
	local tLines = {};

	if not OptionsManager.IsNoBasicHelp() then
		table.insert(tLines, Locale.Lookup("TXT_KEY_PRODUCTION_HELP_INFO"));
		table.insert(tLines, "");
	end

	table.insert(tLines, GetYieldTooltip(pCity, eYield));

	return table.concat(tLines, "[NEWLINE]");
end

function GetGoldTooltip(pCity)
	local eYield = YieldTypes.YIELD_GOLD;
	local tLines = {};

	if not OptionsManager.IsNoBasicHelp() then
		table.insert(tLines, Locale.Lookup("TXT_KEY_GOLD_HELP_INFO"));
		table.insert(tLines, "");
	end

	table.insert(tLines, GetYieldTooltip(pCity, eYield));

	return table.concat(tLines, "[NEWLINE]");
end

function GetScienceTooltip(pCity)
	if Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE) then
		return Locale.Lookup("TXT_KEY_TOP_PANEL_SCIENCE_OFF_TOOLTIP");
	end

	local eYield = YieldTypes.YIELD_SCIENCE;
	local tLines = {};

	if not OptionsManager.IsNoBasicHelp() then
		table.insert(tLines, Locale.Lookup("TXT_KEY_SCIENCE_HELP_INFO"));
		table.insert(tLines, "");
	end

	table.insert(tLines, GetYieldTooltip(pCity, eYield));

	return table.concat(tLines, "[NEWLINE]");
end

function GetCultureTooltip(pCity)
	local eYield = YieldTypes.YIELD_CULTURE;
	local tLines = {};
	local iBaseCulture = pCity:GetBaseYieldRate(eYield);
	local iTotalCulture = pCity:GetYieldRateTimes100(eYield) / 100;
	local strIconString = GameInfo.Yields[YieldTypes.YIELD_CULTURE_LOCAL].IconString;
	if Game.IsOption(GameOptionTypes.GAMEOPTION_NO_POLICIES) then
		table.insert(tLines, Locale.Lookup("TXT_KEY_TOP_PANEL_POLICIES_OFF_TOOLTIP"));
		table.insert(tLines, Locale.Lookup("TXT_KEY_YIELD_FROM_LOCAL_CULTURE", iBaseCulture, strIconString));
	else
		if not OptionsManager.IsNoBasicHelp() then
			table.insert(tLines, Locale.Lookup("TXT_KEY_CULTURE_HELP_INFO"));
			table.insert(tLines, "");
		end
		table.insert(tLines, GetYieldTooltip(pCity, eYield));
	end

	-- Border growth
	eYield = YieldTypes.YIELD_CULTURE_LOCAL;
	local iCultureStored = pCity:GetJONSCultureStored();
	local iCultureNeeded = pCity:GetJONSCultureThreshold();
	local iBaseBorderGrowth = pCity:GetBaseYieldRate(eYield);
	local iBorderGrowthMod, strBorderGrowthModTooltip = pCity:GetBorderGrowthRateIncreaseTotal(true);
	local iTotalBorderGrowth = math.floor((iTotalCulture + iBaseBorderGrowth) * (100 + iBorderGrowthMod) / 100);
	iTotalBorderGrowth = math.max(iTotalBorderGrowth, 0);

	table.insert(tLines, Locale.Lookup("TXT_KEY_YIELD_FROM_MISC", iBaseBorderGrowth, strIconString));
	table.insert(tLines, strSeparator);
	if iTotalCulture + iBaseBorderGrowth > 0 then
		if strBorderGrowthModTooltip ~= "" then
			table.insert(tLines, Locale.Lookup("TXT_KEY_YIELD_BASE", iTotalCulture + iBaseBorderGrowth, strIconString));
			table.insert(tLines, strBorderGrowthModTooltip);
			table.insert(tLines, strSeparator);
		end
	end
	table.insert(tLines, Locale.Lookup("TXT_KEY_YIELD_TOTAL", iTotalBorderGrowth, strIconString));

	table.insert(tLines, "[NEWLINE]");

	local strBorderGrowthProgress = Locale.Lookup("TXT_KEY_CULTURE_INFO", iCultureStored, iCultureNeeded);
	if iTotalBorderGrowth > 0 then
		local iCultureTurns = math.ceil((iCultureNeeded - iCultureStored) / iTotalBorderGrowth);
		strBorderGrowthProgress = strBorderGrowthProgress .. " " .. Locale.Lookup("TXT_KEY_CULTURE_TURNS", iCultureTurns);
	end
	table.insert(tLines, strBorderGrowthProgress);

	return table.concat(tLines, "[NEWLINE]");
end

function GetFaithTooltip(pCity)
	if Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION) then
		return Locale.Lookup("TXT_KEY_TOP_PANEL_RELIGION_OFF_TOOLTIP");
	end

	local eYield = YieldTypes.YIELD_FAITH;
	local tLines = {};
	if not OptionsManager.IsNoBasicHelp() then
		table.insert(tLines, Locale.Lookup("TXT_KEY_FAITH_HELP_INFO"));
	end

	table.insert(tLines, GetYieldTooltip(pCity, eYield));

	table.insert(tLines, strSeparator);

	-- Religion info
	table.insert(tLines, GetReligionTooltip(pCity));

	return table.concat(tLines, "[NEWLINE]");
end

function GetTourismTooltip(pCity)
	return pCity:GetTourismTooltip();
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
			return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_ALWAYS_WAR_TT");
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
		return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_ELIMINATED_INDICATOR");
	end

	-- Teammates
	if eActiveTeam == eOtherTeam then
		return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_HUMAN_TEAMMATE");
	end

	-- At war with us
	if pActiveTeam:IsAtWar(eOtherTeam) then
		return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_AT_WAR");
	end

	-- Appears Friendly
	if iVisibleApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_FRIENDLY then
		return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_FRIENDLY");
	end

	-- Appears Afraid
	if iVisibleApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_AFRAID then
		return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_AFRAID");
	end

	-- Appears Guarded
	if iVisibleApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_GUARDED then
		return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_GUARDED");
	end

	-- Appears Hostile
	if iVisibleApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_HOSTILE then
		return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_HOSTILE");
	end

	-- Appears Neutral, opinions deliberately hidden
	if Game.IsHideOpinionTable() then
		if pOtherPlayer:IsActHostileTowardsHuman(eActivePlayer) then
			return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_NEUTRAL_HOSTILE");
		end
		if pOtherTeam:GetTurnsSinceMeetingTeam(eActiveTeam) ~= 0 then
			return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_NEUTRAL_FRIENDLY");
		end
	end

	-- Appears Neutral, no opinions
	return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_DEFAULT_STATUS");
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
		local strReligionName = Locale.Lookup(Game.GetReligionName(eReligion));
		local strIconString = kReligionInfo.IconString;
		tReligionFollowers[eReligion] = pCity:GetNumFollowers(eReligion);

		if pCity:IsHolyCityForReligion(eReligion) then
			table.insert(tLines, Locale.Lookup("TXT_KEY_HOLY_CITY_TOOLTIP_LINE", strIconString, strReligionName));
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
			strPressure = Locale.Lookup("TXT_KEY_RELIGIOUS_PRESSURE_STRING_EXTENDED", iDisplayExistingPressure, iDisplayPressure);
		end

		table.insert(tLines, Locale.Lookup("TXT_KEY_RELIGION_TOOLTIP_LINE", strIconString, iFollowers, strPressure));
	end

	if #tReligions == 0 then
		return Locale.Lookup("TXT_KEY_RELIGION_NO_FOLLOWERS");
	end

	return table.concat(tLines, "[NEWLINE]");
end
