print("This is the modded InfoTooltipInclude from Community Patch");

-------------------------------------------------
-- Help text for game components (Units, Buildings, etc.)
-------------------------------------------------
local MOD_BALANCE_VP = Game.IsCustomModOption("BALANCE_VP");
local MOD_BALANCE_CORE_JFD = Game.IsCustomModOption("BALANCE_CORE_JFD");
local MOD_BALANCE_CORE_BUILDING_INVESTMENTS = Game.IsCustomModOption("BALANCE_CORE_BUILDING_INVESTMENTS");
local MOD_UNITS_RESOURCE_QUANTITY_TOTALS = Game.IsCustomModOption("UNITS_RESOURCE_QUANTITY_TOTALS");

-- Helper functions
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

function GetHelpTextForUnit(eUnit, _, pCity)
	local kUnitInfo = GameInfo.Units[eUnit];
	local pActivePlayer = Players[Game.GetActivePlayer()];
	local strTooltip = "";

	-- Name
	strTooltip = strTooltip .. Locale.ToUpper(Locale.Lookup(kUnitInfo.Description));
	if pCity then
		if pCity:GetUnitInvestment(eUnit) > 0 then
			strTooltip = strTooltip .. Locale.Lookup("TXT_KEY_INVESTED");
		end
	end

	strTooltip = strTooltip .. "[NEWLINE]----------------[NEWLINE]";

	-- Cost
	if kUnitInfo.Cost > 0 then
		local iCost = pActivePlayer:GetUnitProductionNeeded(eUnit);
		if pCity then
			if pCity:GetUnitInvestment(eUnit) > 0 then
				iCost = pCity:GetUnitInvestment(eUnit);
			end
		end
		strTooltip = strTooltip .. Locale.Lookup("TXT_KEY_PRODUCTION_COST", iCost);
	end

	-- Moves
	if kUnitInfo.Domain ~= "DOMAIN_AIR" then
		strTooltip = strTooltip .. "[NEWLINE]";
		strTooltip = strTooltip .. Locale.Lookup("TXT_KEY_PRODUCTION_MOVEMENT", kUnitInfo.Moves);
	end

	-- Range
	local iRange = kUnitInfo.Range;
	if iRange ~= 0 then
		strTooltip = strTooltip .. "[NEWLINE]";
		strTooltip = strTooltip .. Locale.Lookup("TXT_KEY_PRODUCTION_RANGE", iRange);
	end

	-- Ranged Strength
	local iRangedStrength = kUnitInfo.RangedCombat;
	if iRangedStrength ~= 0 then
		strTooltip = strTooltip .. "[NEWLINE]";
		strTooltip = strTooltip .. Locale.Lookup("TXT_KEY_PRODUCTION_RANGED_STRENGTH", iRangedStrength);
	end

	-- Strength
	local iStrength = kUnitInfo.Combat;
	if iStrength ~= 0 then
		strTooltip = strTooltip .. "[NEWLINE]";
		strTooltip = strTooltip .. Locale.Lookup("TXT_KEY_PRODUCTION_STRENGTH", iStrength);
	end

	-- Air Defense
	local iAirDefense = kUnitInfo.BaseLandAirDefense;
	if iAirDefense ~= 0 then
		strTooltip = strTooltip .. "[NEWLINE]";
		strTooltip = strTooltip .. Locale.Lookup("TXT_KEY_PRODUCTION_AIR_DEFENSE", iAirDefense);
	end

	-- Resource Requirements
	for kResourceInfo in GameInfo.Resources() do
		local eResource = kResourceInfo.ID;
		local iNumResourceNeeded = Game.GetNumResourceRequiredForUnit(eUnit, eResource);
		if iNumResourceNeeded > 0 then
			strTooltip = strTooltip .. "[NEWLINE]";
			strTooltip = strTooltip .. Locale.Lookup("TXT_KEY_PRODUCTION_RESOURCES_REQUIRED", iNumResourceNeeded, kResourceInfo.IconString, kResourceInfo.Description);
		end
	end

	if MOD_UNITS_RESOURCE_QUANTITY_TOTALS then
		for kResourceInfo in GameInfo.Resources() do
			local eResource = kResourceInfo.ID;
			local iNumResourceTotalNeeded = Game.GetNumResourceTotalRequiredForUnit(eUnit, eResource);
			if iNumResourceTotalNeeded > 0 then
				strTooltip = strTooltip .. "[NEWLINE]";
				strTooltip = strTooltip .. Locale.Lookup("TXT_KEY_PRODUCTION_TOTAL_RESOURCES_REQUIRED", iNumResourceTotalNeeded, kResourceInfo.IconString, kResourceInfo.Description);
			end
		end
	end

	-- Pre-written Help text
	if not kUnitInfo.Help then
		print("Unit help is NULL:", Locale.Lookup(kUnitInfo.Description));
	else
		local strWrittenHelp = Locale.Lookup(kUnitInfo.Help);
		if strWrittenHelp ~= "" then
			strTooltip = strTooltip .. "[NEWLINE]----------------[NEWLINE]";
			strTooltip = strTooltip .. strWrittenHelp;
		end
	end

	return strTooltip;
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
			table.insert(tLines, "----------------");
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
		table.insert(tLines, "----------------");
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
		if strWrittenHelp ~= "" then
			table.insert(tLines, "----------------");
			table.insert(tLines, strWrittenHelp);
		end
	end

	-- Investment rules (for unbuilt buildings only)
	if pCity and MOD_BALANCE_CORE_BUILDING_INVESTMENTS and pCity:GetNumRealBuilding(eBuilding) <= 0 and pCity:GetNumFreeBuilding(eBuilding) <= 0 then
		local iAmount = GameDefines.BALANCE_BUILDING_INVESTMENT_BASELINE * -1;
		local iWonderAmount = iAmount / 2;
		local strInvestRules = Locale.Lookup("TXT_KEY_PRODUCTION_INVESTMENT_BUILDING", iAmount, iWonderAmount);
		table.insert(tLines, "----------------");
		table.insert(tLines, strInvestRules);
		local iCostModifier = pCity:GetWorldWonderCost(eBuilding);
		if iCostModifier > 0 then
			local strWonderCostMod = Locale.Lookup("TXT_KEY_WONDER_COST_INCREASE_METRIC", iCostModifier);
			table.insert(tLines, "----------------");
			table.insert(tLines, strWonderCostMod);
		end
	end

	return table.concat(tLines, "[NEWLINE]");
end

-- IMPROVEMENT
function GetHelpTextForImprovement(iImprovementID, bExcludeName, bExcludeHeader)
	local pImprovementInfo = GameInfo.Improvements[iImprovementID];
	local strTooltip = "";

	if (not bExcludeHeader) then
		if (not bExcludeName) then
			-- Name
			strTooltip = strTooltip .. Locale.ToUpper(Locale.Lookup(pImprovementInfo.Description));
			strTooltip = strTooltip .. "[NEWLINE]----------------[NEWLINE]";
		end
	end

	-- if we end up having a lot of these we may need to add some more stuff here

	-- Pre-written Help text
	if (pImprovementInfo.Help ~= nil) then
		local strWrittenHelp = Locale.Lookup(pImprovementInfo.Help);
		if (strWrittenHelp ~= nil and strWrittenHelp ~= "") then
			-- Separator
			-- strTooltip = strTooltip .. "[NEWLINE]----------------[NEWLINE]";
			strTooltip = strTooltip .. strWrittenHelp;
		end
	end

	return strTooltip;
end

-- PROJECT
function GetHelpTextForProject(iProjectID, bIncludeRequirementsInfo)
	local pProjectInfo = GameInfo.Projects[iProjectID];

	local pActivePlayer = Players[Game.GetActivePlayer()];
	local pActiveTeam = Teams[Game.GetActiveTeam()];

	local strTooltip = "";

	-- Name
	strTooltip = strTooltip .. Locale.ToUpper(Locale.Lookup(pProjectInfo.Description));

	-- Cost
	local iCost = 0;
	if (pCity ~= nil) then
		iCost = pCity:GetProjectProductionNeeded(iProjectID);
	else
		iCost = pActivePlayer:GetProjectProductionNeeded(iProjectID);
	end
	strTooltip = strTooltip .. "[NEWLINE]----------------[NEWLINE]";
	strTooltip = strTooltip .. Locale.Lookup("TXT_KEY_PRODUCTION_COST", iCost);

	-- Pre-written Help text
	local strWrittenHelp = Locale.Lookup(pProjectInfo.Help);
	if (strWrittenHelp ~= nil and strWrittenHelp ~= "") then
		-- Separator
		strTooltip = strTooltip .. "[NEWLINE]----------------[NEWLINE]";
		strTooltip = strTooltip .. strWrittenHelp;
	end

	-- Requirements?
	if (bIncludeRequirementsInfo) then
		if (pProjectInfo.Requirements) then
			strTooltip = strTooltip .. Locale.Lookup(pProjectInfo.Requirements);
		end
	end

	return strTooltip;
end

-- PROCESS
function GetHelpTextForProcess(iProcessID, bIncludeRequirementsInfo)
	local pProcessInfo = GameInfo.Processes[iProcessID];
	local pActivePlayer = Players[Game.GetActivePlayer()];
	local pActiveTeam = Teams[Game.GetActiveTeam()];

	local strTooltip = "";

	-- Name
	strTooltip = strTooltip .. Locale.ToUpper(Locale.Lookup(pProcessInfo.Description));

	-- Pre-written Help text
	local strWrittenHelp = Locale.Lookup(pProcessInfo.Help);
	if (strWrittenHelp ~= nil and strWrittenHelp ~= "") then
		strTooltip = strTooltip .. "[NEWLINE]----------------[NEWLINE]";
		strTooltip = strTooltip .. strWrittenHelp;
	end

	-- League Project text
	if (not Game.IsOption("GAMEOPTION_NO_LEAGUES")) then
		local tProject = nil;

		for t in GameInfo.LeagueProjects() do
			if (iProcessID == GameInfo.Processes[t.Process].ID) then
				tProject = t;
				break;
			end
		end

		local pLeague = Game.GetActiveLeague();

		if (tProject ~= nil and pLeague ~= nil) then
			strTooltip = strTooltip .. "[NEWLINE][NEWLINE]";
			strTooltip = strTooltip ..
			pLeague:GetProjectDetails(GameInfo.LeagueProjects[tProject.Type].ID, Game.GetActivePlayer());
		end
	end

	return strTooltip;
end

-------------------------------------------------
-- Tooltips for Yield & Similar (e.g. Culture)
-------------------------------------------------

-- FOOD
function GetFoodTooltip(pCity)
	local iYieldType = YieldTypes.YIELD_FOOD;
	local strFoodToolTip = "";

	if (not OptionsManager.IsNoBasicHelp()) then
		strFoodToolTip = strFoodToolTip .. Locale.Lookup("TXT_KEY_FOOD_HELP_INFO");
		strFoodToolTip = strFoodToolTip .. "[NEWLINE][NEWLINE]";
	end

	local fFoodProgress = pCity:GetFoodTimes100() / 100;
	local iFoodNeeded = pCity:GrowthThreshold();

	strFoodToolTip = strFoodToolTip .. Locale.Lookup("TXT_KEY_FOOD_PROGRESS", fFoodProgress, iFoodNeeded);

	strFoodToolTip = strFoodToolTip .. "[NEWLINE][NEWLINE]";
	strFoodToolTip = strFoodToolTip .. GetYieldTooltipHelper(pCity, iYieldType, "[ICON_FOOD]");

	if MOD_BALANCE_VP then
		strFoodToolTip = strFoodToolTip .. pCity:getPotentialUnhappinessWithGrowth();
	end


	return strFoodToolTip;
end

-- GOLD
function GetGoldTooltip(pCity)
	local iYieldType = YieldTypes.YIELD_GOLD;

	local strGoldToolTip = "";
	if (not OptionsManager.IsNoBasicHelp()) then
		strGoldToolTip = strGoldToolTip .. Locale.Lookup("TXT_KEY_GOLD_HELP_INFO");
		strGoldToolTip = strGoldToolTip .. "[NEWLINE][NEWLINE]";
	end

	strGoldToolTip = strGoldToolTip .. GetYieldTooltipHelper(pCity, iYieldType, "[ICON_GOLD]");

	return strGoldToolTip;
end

-- SCIENCE
function GetScienceTooltip(pCity)
	local strScienceToolTip = "";

	if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE)) then
		strScienceToolTip = Locale.Lookup("TXT_KEY_TOP_PANEL_SCIENCE_OFF_TOOLTIP");
	else
		local iYieldType = YieldTypes.YIELD_SCIENCE;

		if (not OptionsManager.IsNoBasicHelp()) then
			strScienceToolTip = strScienceToolTip .. Locale.Lookup("TXT_KEY_SCIENCE_HELP_INFO");
			strScienceToolTip = strScienceToolTip .. "[NEWLINE][NEWLINE]";
		end

		strScienceToolTip = strScienceToolTip .. GetYieldTooltipHelper(pCity, iYieldType, "[ICON_RESEARCH]");
	end

	return strScienceToolTip;
end

-- PRODUCTION
function GetProductionTooltip(pCity)
	local iBaseProductionPT = pCity:GetBaseYieldRate(YieldTypes.YIELD_PRODUCTION);
	local iYieldPerPop = pCity:GetYieldPerPopTimes100(YieldTypes.YIELD_PRODUCTION);
	if (iYieldPerPop ~= 0) then
		iYieldPerPop = iYieldPerPop * pCity:GetPopulation();
		iYieldPerPop = iYieldPerPop / 100;

		iBaseProductionPT = iBaseProductionPT + iYieldPerPop;
	end
	local iYieldPerPopInEmpire = pCity:GetYieldPerPopInEmpireTimes100(YieldTypes.YIELD_PRODUCTION);
	if (iYieldPerPopInEmpire ~= 0) then
		iYieldPerPopInEmpire = iYieldPerPopInEmpire * Players[pCity:GetOwner()]:GetTotalPopulation();
		iYieldPerPopInEmpire = iYieldPerPopInEmpire / 100;

		iBaseProductionPT = iBaseProductionPT + iYieldPerPopInEmpire;
	end
	if pCity:IsIndustrialConnectedToCapital() then
		iBaseProductionPT = iBaseProductionPT + pCity:GetConnectionGoldTimes100() / 100
	end
	local iProductionPerTurn = pCity:GetCurrentProductionDifferenceTimes100(false, false) / 100; --pCity:GetYieldRate(YieldTypes.YIELD_PRODUCTION);
	local strCodeToolTip = pCity:GetYieldModifierTooltip(YieldTypes.YIELD_PRODUCTION);

	local strProductionBreakdown = GetYieldTooltip(pCity, YieldTypes.YIELD_PRODUCTION, iBaseProductionPT,
		iProductionPerTurn, "[ICON_PRODUCTION]", strCodeToolTip);

	-- Basic explanation of production
	local strProductionHelp = "";
	if (not OptionsManager.IsNoBasicHelp()) then
		strProductionHelp = strProductionHelp .. Locale.Lookup("TXT_KEY_PRODUCTION_HELP_INFO");
		strProductionHelp = strProductionHelp .. "[NEWLINE][NEWLINE]";
		--Controls.ProductionButton:SetToolTipString(Locale.Lookup("TXT_KEY_CITYVIEW_CHANGE_PROD_TT"));
	else
		--Controls.ProductionButton:SetToolTipString(Locale.Lookup("TXT_KEY_CITYVIEW_CHANGE_PROD"));
	end

	return strProductionHelp .. strProductionBreakdown;
end

-- CULTURE
function GetCultureTooltip(pCity)
	local strCultureToolTip = "";
	local iCulturePerTurn = pCity:GetJONSCulturePerTurn();
	if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_POLICIES)) then
		strCultureToolTip = Locale.Lookup("TXT_KEY_TOP_PANEL_POLICIES_OFF_TOOLTIP");
	else
		if (not OptionsManager.IsNoBasicHelp()) then
			strCultureToolTip = strCultureToolTip .. Locale.Lookup("TXT_KEY_CULTURE_HELP_INFO");
			strCultureToolTip = strCultureToolTip .. "[NEWLINE][NEWLINE]";
		end

		local bFirst = true;

		-- Culture from Terrain
		local iCultureFromTerrain = pCity:GetBaseYieldRateFromTerrain(YieldTypes.YIELD_CULTURE);
		if (iCultureFromTerrain ~= 0) then
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end

			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_TERRAIN", iCultureFromTerrain);
		end

		-- Culture from Buildings
		local iCultureFromBuildings = pCity:GetJONSCulturePerTurnFromBuildings();
		if (iCultureFromBuildings ~= 0) then
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end

			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_BUILDINGS", iCultureFromBuildings);
		end

		-- Culture from Policies
		local iCultureFromPolicies = pCity:GetJONSCulturePerTurnFromPolicies();
		if (iCultureFromPolicies ~= 0) then
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end

			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_POLICIES", iCultureFromPolicies);
		end

		-- Culture from Specialists
		local iCultureFromSpecialists = pCity:GetJONSCulturePerTurnFromSpecialists();
		if (iCultureFromSpecialists ~= 0) then
			--CBP
			iCultureFromSpecialists = (iCultureFromSpecialists + pCity:GetBaseYieldRateFromSpecialists(YieldTypes.YIELD_CULTURE));
			--END
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end

			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_SPECIALISTS", iCultureFromSpecialists);
		end

		-- Culture from Great Works
		local iCultureFromGreatWorks = pCity:GetJONSCulturePerTurnFromGreatWorks();
		if (iCultureFromGreatWorks ~= 0) then
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end

			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_GREAT_WORKS", iCultureFromGreatWorks);
		end

		-- Culture from Religion
		local iCultureFromReligion = pCity:GetJONSCulturePerTurnFromReligion();
		if (iCultureFromReligion ~= 0) then
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end

			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_RELIGION", iCultureFromReligion);
		end

		-- CBP

		-- Base Yield from Pop
		local iYieldPerPop = pCity:GetYieldPerPopTimes100(YieldTypes.YIELD_CULTURE);
		if (iYieldPerPop ~= 0) then
			iYieldPerPop = iYieldPerPop * pCity:GetPopulation();
			iYieldPerPop = iYieldPerPop / 100;
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end
			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_POPULATION", iYieldPerPop);
		end

		-- Base Yield from Pop in Empire
		local iYieldPerPopInEmpire = pCity:GetYieldPerPopInEmpireTimes100(YieldTypes.YIELD_CULTURE);
		if (iYieldPerPopInEmpire ~= 0) then
			iYieldPerPopInEmpire = iYieldPerPopInEmpire * Players[pCity:GetOwner()]:GetTotalPopulation();
			iYieldPerPopInEmpire = iYieldPerPopInEmpire / 100;
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end
			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_EMPIRE_POPULATION", iYieldPerPopInEmpire);
		end

		-- Base Yield from Misc
		local iYieldFromMisc = pCity:GetBaseYieldRateFromMisc(YieldTypes.YIELD_CULTURE);
		if (iYieldFromMisc ~= 0) then
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end
			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" ..
			Locale.Lookup("TXT_KEY_YIELD_FROM_MISC", iYieldFromMisc,
				GameInfo.Yields[YieldTypes.YIELD_CULTURE].IconString);
		end
		-- END

		-- CBP -- Yield Increase from Piety
		local iYieldFromPiety = pCity:GetReligionYieldRateModifier(YieldTypes.YIELD_CULTURE);
		if (iYieldFromPiety ~= 0) then
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end

			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_PIETY", iYieldFromPiety);
		end
		-- END
		-- CBP -- Yield Increase from CS Alliance
		local iYieldFromCSAlliance = pCity:GetBaseYieldRateFromCSAlliance(YieldTypes.YIELD_CULTURE);
		if (iYieldFromCSAlliance ~= 0) then
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end

			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_CS_ALLIANCE", iYieldFromCSAlliance);
		end
		-- END
		-- CBP -- Culture from Corporations
		local iYieldFromCorporations = pCity:GetYieldChangeFromCorporationFranchises(YieldTypes.YIELD_CULTURE);
		if (iYieldFromCorporations ~= 0) then
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end

			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_CORPORATIONS", iYieldFromCorporations);
		end
		-- END		
		-- Culture from Leagues
		local iCultureFromLeagues = pCity:GetJONSCulturePerTurnFromLeagues();
		if (iCultureFromLeagues ~= 0) then
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end

			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_LEAGUES", iCultureFromLeagues);
		end

		-- Culture from Traits
		local iCultureFromTraits = pCity:GetJONSCulturePerTurnFromTraits();
		iCultureFromTraits = (iCultureFromTraits + pCity:GetYieldPerTurnFromTraits(YieldTypes.YIELD_CULTURE));
		if (iCultureFromTraits ~= 0) then
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end

			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_TRAITS", iCultureFromTraits);
		end

		-- CP Events
		-- Culture from Events
		local iCultureFromEvent = pCity:GetEventCityYield(YieldTypes.YIELD_CULTURE);
		if (iCultureFromEvent ~= 0) then
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end

			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_EVENTS", iCultureFromEvent);
		end
		-- END

		local iCultureFromYields = pCity:GetYieldFromCityYield(YieldTypes.YIELD_CULTURE);
		if (iCultureFromYields ~= 0) then
			-- Spacing
			if (bFirst) then
				bFirst = false;
			else
				strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
			end

			strCultureToolTip = strCultureToolTip ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_CULTURE_FROM_CITY_YIELDS", iCultureFromYields);
		end

		-- Base Total
		local baseCulturePerTurn = pCity:GetBaseJONSCulturePerTurn();
		if (baseCulturePerTurn ~= iCulturePerTurn) then
			strCultureToolTip = strCultureToolTip ..
			"[NEWLINE]----------------[NEWLINE]" ..
			Locale.Lookup("TXT_KEY_YIELD_BASE", baseCulturePerTurn,
				GameInfo.Yields[YieldTypes.YIELD_CULTURE].IconString);
		end

		-- Yield modifiers string
		local strCultureFromTR = pCity:GetYieldModifierTooltip(YieldTypes.YIELD_CULTURE);
		if (strCultureFromTR ~= "") then
			strCultureToolTip = strCultureToolTip .. "[NEWLINE]----------------" .. strCultureFromTR;
		end
		-- END

		-- Puppet modifier
		if (pCity:IsPuppet()) then
			local puppetMod = Players[pCity:GetOwner()]:GetPuppetYieldPenalty(YieldTypes.YIELD_CULTURE);

			if (puppetMod ~= 0) then
				strCultureToolTip = strCultureToolTip ..
				"[NEWLINE]----------------" .. Locale.Lookup("TXT_KEY_PRODMOD_PUPPET", puppetMod);
			end
		end

		-- Trade Routes and Processes
		local iYieldFromTrade = pCity:GetBaseYieldRateFromTradeRoutes(YieldTypes.YIELD_CULTURE) / 100.0;
		local iYieldFromProcess = pCity:GetBaseYieldRateFromProcess(YieldTypes.YIELD_CULTURE);
		if (iYieldFromTrade ~= 0 or iYieldFromProcess ~= 0) then
			strCultureToolTip = strCultureToolTip .. "[NEWLINE]----------------";
			if (iYieldFromTrade ~= 0) then
				strCultureToolTip = strCultureToolTip ..
				"[NEWLINE][ICON_BULLET]" ..
				Locale.Lookup("TXT_KEY_YIELD_FROM_TRADE_ROUTES", iYieldFromTrade,
					GameInfo.Yields[YieldTypes.YIELD_CULTURE].IconString);
			end
			if (iYieldFromProcess ~= 0) then
				strCultureToolTip = strCultureToolTip ..
				"[NEWLINE][ICON_BULLET]" ..
				Locale.Lookup("TXT_KEY_YIELD_FROM_PROCESS", iYieldFromProcess,
					GameInfo.Yields[YieldTypes.YIELD_CULTURE].IconString);
			end
		end

		-- Total
		strCultureToolTip = strCultureToolTip .. "[NEWLINE]----------------[NEWLINE]" ..
			Locale.Lookup("TXT_KEY_YIELD_TOTAL", iCulturePerTurn,
				GameInfo.Yields[YieldTypes.YIELD_CULTURE].IconString);
	end

	-- Tile growth
	local iCultureStored = pCity:GetJONSCultureStored();
	local iCultureNeeded = pCity:GetJONSCultureThreshold();
	local borderGrowthRate = iCulturePerTurn + pCity:GetBaseYieldRate(YieldTypes.YIELD_CULTURE_LOCAL);
	local borderGrowthRateIncrease = pCity:GetBorderGrowthRateIncreaseTotal();
	borderGrowthRate = math.floor(borderGrowthRate * (100 + borderGrowthRateIncrease) / 100);

	strCultureToolTip = strCultureToolTip .. "[NEWLINE]";
	if pCity:GetBaseYieldRate(YieldTypes.YIELD_CULTURE_LOCAL) ~= 0 then
		strCultureToolTip = strCultureToolTip ..
		"[NEWLINE][ICON_BULLET]" ..
		pCity:GetBaseYieldRate(YieldTypes.YIELD_CULTURE_LOCAL) ..
		" [ICON_CULTURE_LOCAL] " .. Locale.Lookup("TXT_KEY_YIELD_CULTURE_LOCAL")
	end
	if pCity:GetBorderGrowthRateIncreaseTotal() ~= 0 then
		strCultureToolTip = strCultureToolTip ..
		"[NEWLINE][ICON_BULLET]+" ..
		pCity:GetBorderGrowthRateIncreaseTotal() ..
		"% [ICON_CULTURE_LOCAL] " .. Locale.Lookup("TXT_KEY_YIELD_CULTURE_LOCAL")
	end
	if borderGrowthRate > 0 and borderGrowthRate ~= iCulturePerTurn then
		strCultureToolTip = strCultureToolTip .. "[NEWLINE]----------------[NEWLINE]" ..
			Locale.Lookup("TXT_KEY_YIELD_TOTAL", borderGrowthRate,
				GameInfo.Yields[YieldTypes.YIELD_CULTURE_LOCAL].IconString);
	end

	strCultureToolTip = strCultureToolTip .. "[NEWLINE][NEWLINE]";
	strCultureToolTip = strCultureToolTip ..
	Locale.Lookup("TXT_KEY_CULTURE_INFO", iCultureStored, iCultureNeeded);

	if borderGrowthRate > 0 then
		local iCultureDiff = iCultureNeeded - iCultureStored;
		local iCultureTurns = math.ceil(iCultureDiff / borderGrowthRate);
		strCultureToolTip = strCultureToolTip .. " " .. Locale.Lookup("TXT_KEY_CULTURE_TURNS", iCultureTurns);
	end

	return strCultureToolTip;
end

-- FAITH
function GetFaithTooltip(pCity)
	local faithTips = {};

	if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION)) then
		table.insert(faithTips, Locale.Lookup("TXT_KEY_TOP_PANEL_RELIGION_OFF_TOOLTIP"));
	else
		if (not OptionsManager.IsNoBasicHelp()) then
			table.insert(faithTips, Locale.Lookup("TXT_KEY_FAITH_HELP_INFO"));
		end

		-- Faith from Buildings
		local iFaithFromBuildings = pCity:GetFaithPerTurnFromBuildings();
		if (iFaithFromBuildings ~= 0) then
			table.insert(faithTips,
				"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_BUILDINGS", iFaithFromBuildings));
		end
		-- CBP

		-- Base Yield from Pop
		local iYieldPerPop = pCity:GetYieldPerPopTimes100(YieldTypes.YIELD_FAITH);
		if (iYieldPerPop ~= 0) then
			iYieldPerPop = iYieldPerPop * pCity:GetPopulation();
			iYieldPerPop = iYieldPerPop / 100;

			table.insert(faithTips, "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_POP", iYieldPerPop));
		end
		-- Base Yield from Pop in Empire
		local iYieldPerPopInEmpire = pCity:GetYieldPerPopInEmpireTimes100(YieldTypes.YIELD_FAITH);
		if (iYieldPerPopInEmpire ~= 0) then
			iYieldPerPopInEmpire = iYieldPerPopInEmpire * Players[pCity:GetOwner()]:GetTotalPopulation();
			iYieldPerPopInEmpire = iYieldPerPopInEmpire / 100;

			table.insert(faithTips,
				"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_EMPIRE_POP", iYieldPerPopInEmpire));
		end
		-- Faith from Specialists
		local iYieldFromSpecialists = pCity:GetBaseYieldRateFromSpecialists(YieldTypes.YIELD_FAITH);
		if (iYieldFromSpecialists ~= 0) then
			table.insert(faithTips,
				"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_SPECIALISTS_FAITH", iYieldFromSpecialists));
		end
		-- END
		-- Faith from Traits
		local iFaithFromTraits = pCity:GetFaithPerTurnFromTraits();
		iFaithFromTraits = (iFaithFromTraits + pCity:GetYieldPerTurnFromTraits(YieldTypes.YIELD_FAITH));
		if (iFaithFromTraits ~= 0) then
			table.insert(faithTips,
				"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_TRAITS", iFaithFromTraits));
		end

		-- CBP -- Yield Increase from Piety
		local iYieldFromPiety = pCity:GetReligionYieldRateModifier(YieldTypes.YIELD_FAITH);
		if (iYieldFromPiety ~= 0) then
			table.insert(faithTips, "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_PIETY", iYieldFromPiety));
		end
		-- END
		-- CBP -- Yield Increase from CS Alliance
		local iYieldFromCSAlliance = pCity:GetBaseYieldRateFromCSAlliance(YieldTypes.YIELD_FAITH);
		if (iYieldFromCSAlliance ~= 0) then
			table.insert(faithTips,
				"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_CS_ALLIANCE", iYieldFromCSAlliance));
		end
		-- END		
		-- Faith from Terrain
		local iFaithFromTerrain = pCity:GetBaseYieldRateFromTerrain(YieldTypes.YIELD_FAITH);
		if (iFaithFromTerrain ~= 0) then
			table.insert(faithTips,
				"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_TERRAIN", iFaithFromTerrain));
		end

		-- Faith from Policies
		local iFaithFromPolicies = pCity:GetFaithPerTurnFromPolicies();
		if (iFaithFromPolicies ~= 0) then
			table.insert(faithTips,
				"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_POLICIES", iFaithFromPolicies));
		end

		-- Faith from Religion
		local iFaithFromReligion = pCity:GetFaithPerTurnFromReligion();
		if (iFaithFromReligion ~= 0) then
			table.insert(faithTips,
				"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_RELIGION", iFaithFromReligion));
		end

		-- CP Events
		-- Faith from Events
		local iFaithFromEvent = pCity:GetEventCityYield(YieldTypes.YIELD_FAITH);
		if (iFaithFromEvent ~= 0) then
			table.insert(faithTips,
				"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_EVENTS", iFaithFromEvent));
		end

		local iFaithFromYields = pCity:GetYieldFromCityYield(YieldTypes.YIELD_FAITH);
		if (iFaithFromYields ~= 0) then
			table.insert(faithTips,
				"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_CITY_YIELDS", iFaithFromYields));
		end

		local iYieldFromCorps = pCity:GetYieldChangeFromCorporationFranchises(YieldTypes.YIELD_FAITH);
		if (iYieldFromCorps ~= 0) then
			table.insert(faithTips,
				"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_CORPORATIONS", iYieldFromCorps));
		end
		-- END
		-- CBP
		local iFaithWLTKDMod = pCity:GetModFromWLTKD(YieldTypes.YIELD_FAITH);
		if (iFaithWLTKDMod ~= 0) then
			table.insert(faithTips, "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_WLTKD", iFaithWLTKDMod));
		end

		local iFaithGoldenAgeMod = pCity:GetModFromGoldenAge(YieldTypes.YIELD_FAITH);
		if (iFaithGoldenAgeMod ~= 0) then
			table.insert(faithTips,
				"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_GOLDEN_AGE", iFaithGoldenAgeMod));
		end
		-- END

		-- CBP Yield from Great Works
		local iYieldFromGreatWorks = pCity:GetBaseYieldRateFromGreatWorks(YieldTypes.YIELD_FAITH);
		if (iYieldFromGreatWorks ~= 0) then
			table.insert(faithTips,
				"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_ART_CBP_FAITH", iYieldFromGreatWorks));
		end
		-- END

		-- CBP -- Resource Monopoly
		if (pCity:GetCityYieldModFromMonopoly(YieldTypes.YIELD_FAITH) > 0) then
			local iAmount = pCity:GetCityYieldModFromMonopoly(YieldTypes.YIELD_FAITH);

			if (iAmount ~= 0) then
				table.insert(faithTips,
					"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_RESOURCE_MONOPOLY", iAmount));
			end
		end
		-- END

		if (pCity:GetGreatWorkYieldMod(YieldTypes.YIELD_FAITH) > 0) then
			local iAmount = pCity:GetGreatWorkYieldMod(YieldTypes.YIELD_FAITH);

			if (iAmount ~= 0) then
				table.insert(faithTips, "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_GWS", iAmount));
			end
		end
		if (pCity:GetActiveSpyYieldMod(YieldTypes.YIELD_FAITH) > 0) then
			local iAmount = pCity:GetActiveSpyYieldMod(YieldTypes.YIELD_FAITH);

			if (iAmount ~= 0) then
				table.insert(faithTips, "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_FAITH_FROM_SPIES", iAmount));
			end
		end

		-- Puppet modifier
		if (pCity:IsPuppet()) then
			local puppetMod = Players[pCity:GetOwner()]:GetPuppetYieldPenalty(YieldTypes.YIELD_FAITH);

			if (puppetMod ~= 0) then
				table.insert(faithTips, Locale.Lookup("TXT_KEY_PRODMOD_PUPPET", puppetMod));
			end
		end

		local trfaith = pCity:GetYieldModifierTooltip(YieldTypes.YIELD_FAITH)
		if (trfaith ~= "") then
			table.insert(faithTips, trfaith);
		end

		-- Citizens breakdown
		table.insert(faithTips, "----------------");

		table.insert(faithTips, GetReligionTooltip(pCity));
	end

	local strFaithToolTip = table.concat(faithTips, "[NEWLINE]");
	return strFaithToolTip;
end

-- TOURISM
function GetTourismTooltip(pCity)
	return pCity:GetTourismTooltip();
end

-- CBP
function GetCityHappinessTooltip(pCity)
	local strHappinessBreakdown = pCity:GetCityHappinessBreakdown();
	return strHappinessBreakdown;
end

function GetCityUnhappinessTooltip(pCity)
	local strUnhappinessBreakdown = pCity:GetCityUnhappinessBreakdown(true);
	return strUnhappinessBreakdown;
end

-- END

-- Yield Tooltip Helper
function GetYieldTooltipHelper(pCity, iYieldType, strIcon)
	local strModifiers = "";

	-- Base Yield
	local iBaseYield = pCity:GetBaseYieldRate(iYieldType);

	local iYieldPerPop = pCity:GetYieldPerPopTimes100(iYieldType);
	if (iYieldPerPop ~= 0) then
		iYieldPerPop = iYieldPerPop * pCity:GetPopulation();
		iYieldPerPop = iYieldPerPop / 100;

		iBaseYield = iBaseYield + iYieldPerPop;
	end

	local iYieldPerPopInEmpire = pCity:GetYieldPerPopInEmpireTimes100(iYieldType);
	if (iYieldPerPopInEmpire ~= 0) then
		iYieldPerPopInEmpire = iYieldPerPopInEmpire * Players[pCity:GetOwner()]:GetTotalPopulation();
		iYieldPerPopInEmpire = iYieldPerPopInEmpire / 100;

		iBaseYield = iBaseYield + iYieldPerPopInEmpire;
	end

	if iYieldType == YieldTypes.YIELD_PRODUCTION and pCity:IsIndustrialConnectedToCapital() then
		iBaseYield = iBaseYield + pCity:GetConnectionGoldTimes100() / 100
	end

	-- Total Yield
	local iTotalYield;

	-- Food is special
	if (iYieldType == YieldTypes.YIELD_FOOD) then
		iTotalYield = pCity:FoodDifferenceTimes100() / 100;
	else
		iTotalYield = pCity:GetYieldRateTimes100(iYieldType) / 100;
	end

	-- Yield modifiers string
	strModifiers = strModifiers .. pCity:GetYieldModifierTooltip(iYieldType);

	-- Build tooltip
	local strYieldToolTip = GetYieldTooltip(pCity, iYieldType, iBaseYield, iTotalYield, strIcon, strModifiers);

	return strYieldToolTip;
end

------------------------------
-- Helper function to build yield tooltip string
function GetYieldTooltip(pCity, iYieldType, iBase, iTotal, strIconString, strModifiersString)
	local strYieldBreakdown = "";

	-- Base Yield from terrain
	local iYieldFromTerrain = pCity:GetBaseYieldRateFromTerrain(iYieldType);
	if (iYieldFromTerrain ~= 0) then
		strYieldBreakdown = strYieldBreakdown ..
		"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_TERRAIN", iYieldFromTerrain, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- Base Yield from Buildings
	local iYieldFromBuildings = pCity:GetBaseYieldRateFromBuildings(iYieldType);
	if (iYieldFromBuildings ~= 0) then
		strYieldBreakdown = strYieldBreakdown ..
		"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_BUILDINGS", iYieldFromBuildings, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- Base Yield from Specialists
	local iYieldFromSpecialists = pCity:GetBaseYieldRateFromSpecialists(iYieldType);
	if (iYieldFromSpecialists ~= 0) then
		strYieldBreakdown = strYieldBreakdown ..
		"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_SPECIALISTS", iYieldFromSpecialists, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- Base Yield from Misc
	local iYieldFromMisc = pCity:GetBaseYieldRateFromMisc(iYieldType);
	if (iYieldFromMisc ~= 0) then
		if (iYieldType == YieldTypes.YIELD_SCIENCE) then
			strYieldBreakdown = strYieldBreakdown ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_POP", iYieldFromMisc, strIconString);
		else
			strYieldBreakdown = strYieldBreakdown ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_MISC", iYieldFromMisc, strIconString);
		end
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- Yield Increase from City Yields
	local iYieldFromYields = pCity:GetYieldFromCityYield(iYieldType);
	if (iYieldFromYields ~= 0) then
		strYieldBreakdown = strYieldBreakdown ..
		"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_CITY_YIELDS", iYieldFromYields, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- CBP -- Yield Increase from CS Alliance (Germany)

	local iYieldFromCSAlliance = pCity:GetBaseYieldRateFromCSAlliance(iYieldType);
	if (iYieldFromCSAlliance ~= 0) then
		strYieldBreakdown = strYieldBreakdown ..
		"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_CS_ALLIANCE", iYieldFromCSAlliance, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- CBP -- Yield Increase from Corporation Franchises
	local iYieldFromCorps = pCity:GetYieldChangeFromCorporationFranchises(iYieldType);
	if (iYieldFromCorps ~= 0) then
		strYieldBreakdown = strYieldBreakdown ..
		"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_CORPORATIONS", iYieldFromCorps, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- CBP -- Yield Increase from Piety
	local iYieldFromPiety = pCity:GetReligionYieldRateModifier(iYieldType);
	if (iYieldFromPiety ~= 0) then
		strYieldBreakdown = strYieldBreakdown ..
		"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_PIETY", iYieldFromPiety, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- Base Yield from Pop
	local iYieldPerPop = pCity:GetYieldPerPopTimes100(iYieldType);
	if (iYieldPerPop ~= 0) then
		local iYieldFromPop = iYieldPerPop * pCity:GetPopulation();
		iYieldFromPop = iYieldFromPop / 100;

		strYieldBreakdown = strYieldBreakdown ..
		"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_POP_EXTRA", iYieldFromPop, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- Base Yield from Pop in Empire
	local iYieldPerPopInEmpire = pCity:GetYieldPerPopInEmpireTimes100(iYieldType);
	if (iYieldPerPopInEmpire ~= 0) then
		local iYieldFromPopInEmpire = iYieldPerPopInEmpire * Players[pCity:GetOwner()]:GetTotalPopulation();
		iYieldFromPopInEmpire = iYieldFromPopInEmpire / 100;

		strYieldBreakdown = strYieldBreakdown ..
		"[ICON_BULLET]" ..
		Locale.Lookup("TXT_KEY_YIELD_FROM_EMPIRE_POP_EXTRA", iYieldFromPopInEmpire, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- Base Yield from Industrial City Connection
	if iYieldType == YieldTypes.YIELD_PRODUCTION and pCity:IsIndustrialConnectedToCapital() then
		local iYieldFromIndustrialCityConnection = pCity:GetConnectionGoldTimes100();
		iYieldFromIndustrialCityConnection = iYieldFromIndustrialCityConnection / 100

		strYieldBreakdown = strYieldBreakdown ..
		"[ICON_BULLET]" ..
		Locale.Lookup("TXT_KEY_YIELD_FROM_INDUSTRIAL_CITY_CONNECTION", iYieldFromIndustrialCityConnection,
			strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- Base Yield from Religion
	local iYieldFromReligion = pCity:GetBaseYieldRateFromReligion(iYieldType);
	if (iYieldFromReligion ~= 0) then
		strYieldBreakdown = strYieldBreakdown ..
		"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_RELIGION", iYieldFromReligion, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- CBP Base Yield From City Connections
	local iYieldFromConnection = pCity:GetYieldChangeTradeRoute(iYieldType);
	if (iYieldFromConnection ~= 0) then
		strYieldBreakdown = strYieldBreakdown ..
		"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_CONNECTION", iYieldFromConnection, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- Base Yield from League Art (CSD)
	if (iYieldType == YieldTypes.YIELD_SCIENCE) then
		local iYieldFromLeague = pCity:GetBaseYieldRateFromLeague(iYieldType);
		if (iYieldFromLeague ~= 0) then
			if (iYieldType == YieldTypes.YIELD_SCIENCE) then
				strYieldBreakdown = strYieldBreakdown ..
				"[ICON_BULLET]" ..
				Locale.Lookup("TXT_KEY_SCIENCE_YIELD_FROM_LEAGUE_ART", iYieldFromLeague, strIconString);
				strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
			end
		end
	end

	-- CBP Yield from Great Works
	if (iYieldType ~= YieldTypes.YIELD_CULTURE) then
		local iYieldFromGreatWorks = pCity:GetBaseYieldRateFromGreatWorks(iYieldType);
		if (iYieldFromGreatWorks ~= 0) then
			strYieldBreakdown = strYieldBreakdown ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_ART_CBP", iYieldFromGreatWorks, strIconString);
			strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
		end
	end

	if (iYieldType ~= YieldTypes.YIELD_CULTURE) then
		local iYieldFromTraits = pCity:GetYieldPerTurnFromTraits(iYieldType);
		if (iYieldFromTraits ~= 0) then
			strYieldBreakdown = strYieldBreakdown ..
			"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_TRAIT_BONUS", iYieldFromTraits, strIconString);
			strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
		end
	end

	-- CP Events
	-- Base Yield from Events
	local iYieldFromEvents = pCity:GetEventCityYield(iYieldType);
	if (iYieldFromEvents ~= 0) then
		strYieldBreakdown = strYieldBreakdown ..
		"[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_YIELD_FROM_EVENTS", iYieldFromEvents, strIconString);
		strYieldBreakdown = strYieldBreakdown .. "[NEWLINE]";
	end

	-- WLTKD MOD
	-- END CBP

	if (iBase ~= iTotal) then
		strYieldBreakdown = strYieldBreakdown ..
		"----------------[NEWLINE]" .. Locale.Lookup("TXT_KEY_YIELD_BASE", iBase, strIconString) .. "[NEWLINE]";
	end

	-- Modifiers
	if (strModifiersString ~= "") then
		strYieldBreakdown = strYieldBreakdown .. "----------------" .. strModifiersString .. "[NEWLINE]";
	end

	-- Trade Routes and Processes
	local iYieldFromTrade = 0;
	if (iYieldType ~= YieldTypes.YIELD_FOOD) then
		iYieldFromTrade = pCity:GetBaseYieldRateFromTradeRoutes(iYieldType) / 100.0;
	end
	local iYieldFromProcess = pCity:GetBaseYieldRateFromProcess(iYieldType);
	if (iYieldFromTrade ~= 0 or iYieldFromProcess ~= 0) then
		strYieldBreakdown = strYieldBreakdown .. "----------------";
		if (iYieldFromTrade ~= 0) then
			strYieldBreakdown = strYieldBreakdown ..
			"[NEWLINE][ICON_BULLET]" ..
			Locale.Lookup("TXT_KEY_YIELD_FROM_TRADE_ROUTES", iYieldFromTrade, strIconString) .. "[NEWLINE]";
		end
		if (iYieldFromProcess ~= 0) then
			strYieldBreakdown = strYieldBreakdown ..
			"[NEWLINE][ICON_BULLET]" ..
			Locale.Lookup("TXT_KEY_YIELD_FROM_PROCESS", iYieldFromProcess, strIconString) .. "[NEWLINE]";
		end
	end

	-- Total
	local strTotal;
	if (iTotal >= 0) then
		strTotal = Locale.Lookup("TXT_KEY_YIELD_TOTAL", iTotal, strIconString);
	else
		strTotal = Locale.Lookup("TXT_KEY_YIELD_TOTAL_NEGATIVE", iTotal, strIconString);
	end

	strYieldBreakdown = strYieldBreakdown .. "----------------[NEWLINE]" .. strTotal;
	return strYieldBreakdown;
end

----------------------------------------------------------------
-- MOOD INFO
----------------------------------------------------------------
function GetMoodInfo(iOtherPlayer)
	local strInfo = "";

	local iActivePlayer = Game.GetActivePlayer();
	local pActivePlayer = Players[iActivePlayer];
	local pActiveTeam = Teams[pActivePlayer:GetTeam()];
	local pOtherPlayer = Players[iOtherPlayer];
	local iOtherTeam = pOtherPlayer:GetTeam();
	local pOtherTeam = Teams[iOtherTeam];
	local iVisibleApproach = Players[iActivePlayer]:GetApproachTowardsUsGuess(iOtherPlayer);

	-- Always war!
	if (pActiveTeam:IsAtWar(iOtherTeam)) then
		if (Game.IsOption(GameOptionTypes.GAMEOPTION_ALWAYS_WAR) or Game.IsOption(GameOptionTypes.GAMEOPTION_NO_CHANGING_WAR_PEACE)) then
			return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_ALWAYS_WAR_TT");
		end
	end

	--  Get the opinion modifier table from the DLL and convert it into bullet points
	local aOpinion = pOtherPlayer:GetOpinionTable(iActivePlayer);
	for i, v in ipairs(aOpinion) do
		strInfo = strInfo .. "[ICON_BULLET]" .. v .. "[NEWLINE]";
	end

	--  No specific modifiers are visible, so let's see what string we should use (based on visible approach towards us)
	if (strInfo == "") then
		-- Eliminated
		if (not pOtherPlayer:IsAlive()) then
			return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_ELIMINATED_INDICATOR");
			-- Teammates
		elseif (Game.GetActiveTeam() == iOtherTeam) then
			return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_HUMAN_TEAMMATE");
			-- At war with us
		elseif (pActiveTeam:IsAtWar(iOtherTeam)) then
			return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_AT_WAR");
			-- Appears Friendly
		elseif (iVisibleApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_FRIENDLY) then
			return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_FRIENDLY");
			-- Appears Afraid
		elseif (iVisibleApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_AFRAID) then
			return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_AFRAID");
			-- Appears Guarded
		elseif (iVisibleApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_GUARDED) then
			return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_GUARDED");
			-- Appears Hostile
		elseif (iVisibleApproach == MajorCivApproachTypes.MAJOR_CIV_APPROACH_HOSTILE) then
			return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_HOSTILE");
			-- Appears Neutral, opinions deliberately hidden
		elseif (Game.IsHideOpinionTable() and (pOtherTeam:GetTurnsSinceMeetingTeam(pActivePlayer:GetTeam()) ~= 0 or pOtherPlayer:IsActHostileTowardsHuman(iActivePlayer))) then
			if (pOtherPlayer:IsActHostileTowardsHuman(iActivePlayer)) then
				return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_NEUTRAL_HOSTILE");
			else
				return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_NEUTRAL_FRIENDLY");
			end
			-- Appears Neutral, no opinions
		else
			return "[ICON_BULLET]" .. Locale.Lookup("TXT_KEY_DIPLO_DEFAULT_STATUS");
		end
	end

	-- Remove extra newline off the end if we have one
	if (Locale.EndsWith(strInfo, "[NEWLINE]")) then
		local iNewLength = Locale.Length(strInfo) - 9;
		strInfo = Locale.Substring(strInfo, 1, iNewLength);
	end

	return strInfo;
end

------------------------------
-- Helper function to build religion tooltip string
function GetReligionTooltip(city)
	local religionToolTip = "";

	if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION)) then
		return religionToolTip;
	end

	local bFoundAFollower = false;
	local eReligion = city:GetReligiousMajority();
	local bFirst = true;

	if (eReligion >= 0) then
		bFoundAFollower = true;
		local religion = GameInfo.Religions[eReligion];
		local strReligion = Locale.Lookup(Game.GetReligionName(eReligion));
		local strIcon = religion.IconString;
		local strPressure = "";

		if (city:IsHolyCityForReligion(eReligion)) then
			if (not bFirst) then
				religionToolTip = religionToolTip .. "[NEWLINE]";
			else
				bFirst = false;
			end
			religionToolTip = religionToolTip ..
			Locale.Lookup("TXT_KEY_HOLY_CITY_TOOLTIP_LINE", strIcon, strReligion);
		end

		local iPressure;
		local iNumTradeRoutesAddingPressure;
		local iExistingPressure;
		local pressureMultiplier = GameDefines["RELIGION_MISSIONARY_PRESSURE_MULTIPLIER"];
		iPressure, iNumTradeRoutesAddingPressure, iExistingPressure = city:GetPressurePerTurn(eReligion);
		local iFollowers = city:GetNumFollowers(eReligion)

		if (iFollowers > 0 or math.floor(iPressure / pressureMultiplier) > 0) then
			strPressure = Locale.Lookup("TXT_KEY_RELIGIOUS_PRESSURE_STRING_EXTENDED",
				math.floor(iExistingPressure / pressureMultiplier), math.floor(iPressure / pressureMultiplier));
		end

		if (not bFirst) then
			religionToolTip = religionToolTip .. "[NEWLINE]";
		else
			bFirst = false;
		end

		religionToolTip = religionToolTip ..
		Locale.Lookup("TXT_KEY_RELIGION_TOOLTIP_LINE", strIcon, iFollowers, strPressure);
	end

	local iReligionID;
	for pReligion in GameInfo.Religions() do
		iReligionID = pReligion.ID;

		if (iReligionID >= 0 and iReligionID ~= eReligion and city:GetNumFollowers(iReligionID) > 0) then
			bFoundAFollower = true;
			local religion = GameInfo.Religions[iReligionID];
			local strReligion = Locale.Lookup(Game.GetReligionName(iReligionID));
			local strIcon = religion.IconString;
			local strPressure = "";

			if (city:IsHolyCityForReligion(iReligionID)) then
				if (not bFirst) then
					religionToolTip = religionToolTip .. "[NEWLINE]";
				else
					bFirst = false;
				end
				religionToolTip = religionToolTip ..
				Locale.Lookup("TXT_KEY_HOLY_CITY_TOOLTIP_LINE", strIcon, strReligion);
			end

			local iPressure;
			local iNumTradeRoutesAddingPressure;
			local iExistingPressure;
			local pressureMultiplier = GameDefines["RELIGION_MISSIONARY_PRESSURE_MULTIPLIER"];
			iPressure, iNumTradeRoutesAddingPressure, iExistingPressure = city:GetPressurePerTurn(iReligionID);

			local iFollowers = city:GetNumFollowers(iReligionID)

			if (iFollowers > 0 or math.floor(iPressure / pressureMultiplier) > 0) then
				strPressure = Locale.Lookup("TXT_KEY_RELIGIOUS_PRESSURE_STRING_EXTENDED",
					math.floor(iExistingPressure / pressureMultiplier), math.floor(iPressure / pressureMultiplier));
			end


			if (not bFirst) then
				religionToolTip = religionToolTip .. "[NEWLINE]";
			else
				bFirst = false;
			end

			religionToolTip = religionToolTip ..
			Locale.Lookup("TXT_KEY_RELIGION_TOOLTIP_LINE", strIcon, iFollowers, strPressure);
		end
	end

	if (not bFoundAFollower) then
		religionToolTip = religionToolTip .. Locale.Lookup("TXT_KEY_RELIGION_NO_FOLLOWERS");
	end

	return religionToolTip;
end
