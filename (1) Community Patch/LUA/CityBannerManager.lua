print("This is the modded CityBannerManager from Community Patch");

include("IconSupport");
include("InfoTooltipInclude");
include("CityStateStatusHelper");
include("CPK.lua");

local L = Locale.Lookup;

local Color = CPK.Text.Color;
local Show = CPK.UI.Control.Show;
local Hide = CPK.UI.Control.Hide;
local Enable = CPK.UI.Control.Enable;
local Refresh = CPK.UI.Control.Refresh;
local InstanceManager = CPK.UI.Control.Instance.Manager;

local teamInstanceManager = InstanceManager.New({
	instance = "TeamCityBanner",
	onCreated = function(instance)
		instance.BannerButton:RegisterCallback(Mouse.eLClick, OnBannerClick);
		instance.CityRangeStrikeButton:RegisterCallback(Mouse.eLClick, OnCityRangeStrikeButtonClick);
	end,
});

local otherInstanceManager = InstanceManager.New({
	instance = "OtherCityBanner",
	onCreated = function(instance)
		instance.BannerButton:RegisterCallback(Mouse.eLClick, OnBannerClick);
	end,
});

local svRangeStrikeInstanceManager = InstanceManager.New({
	instance = "SVRangeStrikeButton",
	onCreated = function(instance)
		instance.CityRangeStrikeButton:RegisterCallback(Mouse.eLClick, OnCityRangeStrikeButtonClick);
	end,
});

--- @class CityBanner
--- @field PlayerID PlayerId
--- @field CityID CityId
--- @field IsActiveTeam boolean
--- @field Instance ControlInstance
--- @field SVInstance ControlInstance
--- @field Hex Vector2

--- @type table<PlayerId, table<CityId, CityBanner>>
local g_cityBanners = {};
for ePlayer = 0, GameDefines.MAX_PLAYERS - 1 do
	g_cityBanners[ePlayer] = {};
end

local WorldPositionOffset = {x = 0, y = 0, z = 35};
local FOWStates = {
	UNEXPLORED = 0,
	EXPLORED = 1,
	VISIBLE = 2,
};

--- Run Func for every city banner on the map
--- @param Func fun(banner: CityBanner)
local function ForEachCityBanner(Func)
	for ePlayer = 0, GameDefines.MAX_PLAYERS - 1 do
		for _, banner in pairs(g_cityBanners[ePlayer]) do
			Func(banner)
		end
	end
end

--- Helper to set the visibility of a banner and refresh it if it was previously hidden
--- @param banner CityBanner
--- @param bVisible boolean
local function SetBannerVisibility(banner, bVisible)
	local anchor = banner.Instance.Anchor; --- @type Control
	local bWasHidden = anchor:IsHidden();
	anchor:SetHide(not bVisible);

	if bVisible and bWasHidden then
		RefreshCityBanner(banner);
	end
end

local function ShouldBannerBeActiveTeamVersion(banner)
end

--- Determine whether or not to show the Range Strike Button
--- @param pCity City?
--- @return boolean
local function ShouldShowRangeStrikeButton(pCity)
	if not pCity then
		return false;
	end

	if pCity:GetOwner() ~= Game.GetActivePlayer() then
		return false;
	end

	return pCity:CanRangeStrikeNow();
end

--- Show/hide the range strike icon
--- @param banner CityBanner
local function UpdateRangeStrikeIcon(banner)
	local instance = banner.Instance;
	local svInstance = banner.SVInstance;
	local bHide = not ShouldShowRangeStrikeButton(Players[banner.PlayerID]:GetCityByID(banner.CityID));

	instance.CityRangeStrikeButton:SetHide(bHide);
	instance.CityRangeStrikeAnim:SetHide(bHide);
	if svInstance then
		svInstance.CityRangeStrikeButton:SetHide(bHide);
		svInstance.CityRangeStrikeAnim:SetHide(bHide);
	end
end

--- Refresh the health bar
--- @param banner CityBanner
--- @param iDamage integer
--- @param iMaxDamage integer
local function RefreshCityDamage(banner, iDamage, iMaxDamage)
	local iHealthPercent = 1 - (iDamage / iMaxDamage);
	local instance = banner.Instance;

	instance.CityBannerHealthBar:SetPercent(iHealthPercent);
	if iHealthPercent > 0.66 then
		instance.CityBannerHealthBar:SetFGColor(Color.Green:Vec4());
	elseif iHealthPercent > 0.33 then
		instance.CityBannerHealthBar:SetFGColor(Color.Yellow:Vec4());
	else
		instance.CityBannerHealthBar:SetFGColor(Color.Red:Vec4());
	end

	instance.CityBannerHealthBarBase:SetHide(iDamage == 0);
	instance.CityBannerHealthBar:SetHide(iDamage == 0);
end

--- Update banner to reflect latest city info.
--- Make sure this function is called immediately after a banner is unhidden.
--- @param banner CityBanner
function RefreshCityBanner(banner)
	-- Skip if banner is hidden
	if banner.Instance.Anchor:IsHidden() then
		return;
	end

	local strToolTip = "";
	local player = Players[banner.PlayerID];
	local team = player:GetTeam();
	local eActivePlayer = Game:GetActivePlayer();
	local eActiveTeam = Game:GetActiveTeam();
	local isActivePlayerCity = (banner.PlayerID == eActivePlayer);
	local isActiveTeamCity = false;
	if (eActiveTeam == team or (PreGame.GetSlotStatus(eActivePlayer) == SlotStatus.SS_OBSERVER and (Game:GetObserverUIOverridePlayer() == -1 or Players[Game:GetObserverUIOverridePlayer()]:GetTeam() == team))) then
		isActiveTeamCity = true;
	end

	-- grab city using playerID and cityID
	local city = player:GetCityByID(banner.CityID);
	-- for debugging purposes, we want to be able to create a city banner without a DLL-side city
	-- assert(city);

	local bHasSpy = false;
	local bHasDiplomat = false;
	local strSpyName = nil;
	local strSpyRank = nil;

	if (city ~= nil) then
		local cityX = city:GetX();
		local cityY = city:GetY();

		local activePlayer = Players[eActivePlayer];
		local spies = activePlayer:GetEspionageSpies();
		for i, v in ipairs(spies) do
			if (v.CityX == cityX and v.CityY == cityY) then
				if (v.IsDiplomat) then
					bHasDiplomat = true;
				else
					bHasSpy = true;
				end
				strSpyName = L(v.Name);
				strSpyRank = L(v.Rank);
			end
		end
	end

	local controls = banner.Instance;

	-- Update colors
	local primaryColor, secondaryColor = player:GetPlayerColors();
	if player:IsMinorCiv() then
		primaryColor, secondaryColor = secondaryColor, primaryColor;
	end

	local backgroundColor = {x = secondaryColor.x, y = secondaryColor.y, z = secondaryColor.z, w = 0.7};

	controls.CityBannerBackground:SetColor(backgroundColor);
	if (isActiveTeamCity) then
		if (controls.CityBannerBGLeftHL ~= nil) then
			controls.CityBannerBGLeftHL:SetColor(backgroundColor);
		end
		if (controls.CityBannerBGRightHL ~= nil) then
			controls.CityBannerBGRightHL:SetColor(backgroundColor);
		end
		if (controls.CityBannerRightBackground ~= nil) then
			controls.CityBannerRightBackground:SetColor(backgroundColor);
		end
		if (controls.CityBannerLeftBackground ~= nil) then
			controls.CityBannerLeftBackground:SetColor(backgroundColor);
		end
	else
		--NOTE: If the active player were to ever change (such as during an auto play) these controls will not exist because
		--		the city banner is of the "active player" type and not the "other player" type.
		--		This fix is merely a fix to the Lua nil value error and not a proper solution to the problem.
		if (controls.RightBackground ~= nil and controls.LeftBackground ~= nil) then
			controls.RightBackground:SetColor(backgroundColor);
			controls.LeftBackground:SetColor(backgroundColor);
		end
	end

	local textColor = {x = primaryColor.x, y = primaryColor.y, z = primaryColor.z, w = 1};
	local textColor200 = {x = primaryColor.x, y = primaryColor.y, z = primaryColor.z, w = 0.7};
	local textColorShadow = {x = 0, y = 0, z = 0, w = 0.5};
	local textColorSoft = {x = 1, y = 1, z = 1, w = 0.5};
	if (controls.CityProductionName) then
		controls.CityProductionName:SetColor(textColor200, 0);
	end

	controls.CityName:SetColor(textColor, 0);
	controls.CityName:SetColor(textColorShadow, 1);
	controls.CityName:SetColor(textColorSoft, 2);

	--print("No city");

	if city ~= nil then
		-- Update name
		local cityName = city:GetNameKey();
		local localizedCityName = L(cityName);
		local convertedKey = Locale.ToUpper(localizedCityName);

		-- Update capital icon
		local isCapital = city:IsCapital() or Players[city:GetOriginalOwner()]:IsMinorCiv();

		if (city:IsCapital() and not player:IsMinorCiv()) then
			convertedKey = "[ICON_CAPITAL]" .. convertedKey;
		end
		--CBP
		if (city:IsCapital() and player:IsMinorCiv() and player:IsMarried(eActivePlayer)) then
			convertedKey = "[ICON_RES_MARRIAGE]" .. convertedKey;
		end
		--END

		controls.CityName:SetText(convertedKey);

		if (isActivePlayerCity) then
			if (city:IsPuppet() and not player:MayNotAnnex()) then
				strToolTip = L("TXT_KEY_CITY_ANNEX_TT");
			else
				strToolTip = L("TXT_KEY_CITY_ENTER_CITY_SCREEN");
			end
		elseif (isActiveTeamCity) then
			strToolTip = L("TXT_KEY_CITY_TEAMMATE");
		elseif (Game.IsOption(GameOptionTypes.GAMEOPTION_ALWAYS_WAR)) then
			strToolTip = L("TXT_KEY_ALWAYS_AT_WAR_WITH_CITY");
		elseif (player:IsMinorCiv()) then
			local strStatusTT = GetCityStateStatusToolTip(eActivePlayer, banner.PlayerID, false);
			strToolTip = strToolTip .. strStatusTT;
			if (PreGame.GetSlotStatus(Game.GetActivePlayer()) ~= SlotStatus.SS_OBSERVER) then
				controls.StatusIconBG:SetToolTipString(strStatusTT);
				controls.StatusIcon:SetToolTipString(strStatusTT);
			end
		elseif (not Teams[Game.GetActiveTeam()]:IsHasMet(player:GetTeam())) then
			strToolTip = L("TXT_KEY_HAVENT_MET");
		else
			strToolTip = L("TXT_KEY_TALK_TO_PLAYER");
		end

		if (Teams[Game.GetActiveTeam()]:IsAtWar(player:GetTeam())) then
			strToolTip = strToolTip .. "[NEWLINE]----------------[NEWLINE]"
			strToolTip = strToolTip .. player:GetWarmongerPreviewString(city:GetOwner(), city, Game.GetActivePlayer());
			if (city:GetOriginalOwner() ~= city:GetOwner()) then
				strToolTip = strToolTip .. "[NEWLINE]----------------[NEWLINE]"
				strToolTip = strToolTip ..
					player:GetLiberationPreviewString(city:GetOwner(), city, Game.GetActivePlayer());
			end
		end

		local eReligion = city:GetReligiousMajority();

		if (eReligion >= 0) then
			local religion = GameInfo.Religions[eReligion];
			IconHookup(religion.PortraitIndex, 32, religion.IconAtlas, controls.ReligiousIcon);
			IconHookup(religion.PortraitIndex, 32, religion.IconAtlas, controls.ReligiousIconShadow);
		end

		local religionToolTip = "";
		if (GetReligionTooltip) then
			religionToolTip = GetReligionTooltip(city);
		end

		if (religionToolTip ~= "") then
			strToolTip = strToolTip .. "[NEWLINE]----------------[NEWLINE]" .. religionToolTip;
		end
		controls.BannerButton:SetToolTipString(strToolTip);

		if (controls.ReligiousIcon ~= nil) then
			controls.ReligiousIcon:SetToolTipString(religionToolTip);
		end

		local bHasReligion = (eReligion >= 0);
		if (controls.ReligiousIcon ~= nil) then
			controls.ReligiousIconContainer:SetHide(not bHasReligion);
		end

		DoResizeBanner(controls);

		-- Connected to capital?
		if (isActiveTeamCity) then
			if (not city:IsCapital() and not city:IsBlockaded()) then
				if (city:IsIndustrialConnectedToCapital()) then
					controls.IndustrialConnectedIcon:SetHide(false);
					controls.ConnectedIcon:SetHide(true);
				elseif (city:IsConnectedToCapital()) then
					controls.ConnectedIcon:SetHide(false);
					controls.IndustrialConnectedIcon:SetHide(true);
				else
					controls.ConnectedIcon:SetHide(true);
					controls.IndustrialConnectedIcon:SetHide(true);
				end
			else
				controls.ConnectedIcon:SetHide(true);
				controls.IndustrialConnectedIcon:SetHide(true);
			end
		end

		-- Blockaded
		if city:IsBlockaded() then
			if city:GetSappedTurns() > 0 then
				controls.BlockadedIcon:SetText("[ICON_SAPPED]");
				controls.BlockadedIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_SAPPED", city:GetSappedTurns());
			else
				controls.BlockadedIcon:SetText("[ICON_BLOCKADED]")
				controls.BlockadedIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_BLOCKADED");
			end
			Show(controls.BlockadedIcon);
		else
			Hide(controls.BlockadedIcon);
		end

		-- Being Razed
		if (city:IsRazing()) then
			controls.RazingIcon:SetHide(false);
			controls.RazingIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_BURNING", city:GetRazingTurns());
		else
			controls.RazingIcon:SetHide(true);
		end

		-- In Resistance
		if (city:IsResistance()) then
			controls.ResistanceIcon:SetHide(false);
			controls.ResistanceIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_RESISTANCE", city:GetResistanceTurns());
		else
			controls.ResistanceIcon:SetHide(true);
		end

		-- Puppet Status
		if (city:IsPuppet()) then
			controls.PuppetIcon:SetHide(false);

			if (isActivePlayerCity) then
				controls.PuppetIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_PUPPET");
			else
				controls.PuppetIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_PUPPET_OTHER");
			end
		else
			controls.PuppetIcon:SetHide(true);
		end

		-- Annexed City-States
		controls.CityStateIcon:SetHide(not Players[city:GetOriginalOwner()]:IsMinorCiv() or
			not player:IsAnnexedCityStatesGiveYields());
		if Players[city:GetOriginalOwner()]:IsMinorCiv() and player:IsAnnexedCityStatesGiveYields() then
			local cityOriginalOwner = Players[city:GetOriginalOwner()];
			if (cityOriginalOwner ~= nil) then
				local iTrait = cityOriginalOwner:GetMinorCivTrait();
				if (iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_CULTURED) then
					controls.CityStateIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_STATE_CULTURED_TT_ANNEXED");
				elseif (iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_MILITARISTIC) then
					controls.CityStateIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_STATE_MILITARISTIC_NO_UU_TT_ANNEXED");
					if (cityOriginalOwner:IsMinorCivHasUniqueUnit()) then
						local eUniqueUnit = cityOriginalOwner:GetMinorCivUniqueUnit();
						if (GameInfo.Units[eUniqueUnit] ~= nil) then
							local ePrereqTech = GameInfo.Units[eUniqueUnit].PrereqTech;
							if (ePrereqTech == nil) then
								-- If no prereq then just make it Agriculture, but make sure that Agriculture is in our database. Otherwise, show the fallback tooltip.
								if (GameInfo.Technologies["TECH_AGRICULTURE"] ~= nil) then
									ePrereqTech = GameInfo.Technologies["TECH_AGRICULTURE"].ID;
								end
							end
							if (ePrereqTech ~= nil) then
								if (GameInfo.Technologies[ePrereqTech] ~= nil) then
									controls.CityStateIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_STATE_MILITARISTIC_TT_ANNEXED", GameInfo.Units[eUniqueUnit].Description, GameInfo.Technologies[ePrereqTech].Description);
								end
							end
						else
							print("Scripting error - City-State's unique unit not found!");
						end
					end
				elseif (iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_MARITIME) then
					controls.CityStateIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_STATE_MARITIME_TT_ANNEXED");
				elseif (iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_MERCANTILE) then
					controls.CityStateIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_STATE_MERCANTILE_TT_ANNEXED");
				elseif (iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_RELIGIOUS) then
					controls.CityStateIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_STATE_RELIGIOUS_TT_ANNEXED");
				end
			end
		end

		controls.OccupiedIcon:SetHide(city:IsNoOccupiedUnhappiness() or not city:IsOccupied());
		controls.CityIsMined:SetHide(not city:IsMined());

		-- CityHasOffice Status
		controls.CityHasOffice:SetHide(not city:HasOffice());
		if Players[city:GetOwner()]:GetCorporation() ~= -1 then
			if (city == Game.GetCorporationHeadquarters(Players[city:GetOwner()]:GetCorporation())) then
				controls.CityHasOffice:SetToolTipString(L("TXT_KEY_CORPORATION_OFFICEHQ_TT",
						GameInfo.Corporations[Players[city:GetOwner()]:GetCorporation()].Description) ..
					"[NEWLINE][ICON_BULLET]" ..
					L(GameInfo.Corporations[Players[city:GetOwner()]:GetCorporation()].Help) ..
					"[NEWLINE][ICON_BULLET]" ..
					L("TXT_KEY_CORPORATION_OFFICEHQ_TT2", city:GetName()) ..
					"[NEWLINE][ICON_BULLET]" .. L("TXT_KEY_CORPORATION_OFFICE_TT2", city:GetName()));
			elseif (city:HasOffice()) then
				controls.CityHasOffice:SetToolTipString(L("TXT_KEY_CORPORATION_OFFICE_TT",
						GameInfo.Corporations[Players[city:GetOwner()]:GetCorporation()].Description) ..
					"[NEWLINE][ICON_BULLET]" ..
					L(GameInfo.Corporations[Players[city:GetOwner()]:GetCorporation()]
						.OfficeBonusHelp) ..
					"[NEWLINE][ICON_BULLET]" .. L("TXT_KEY_CORPORATION_OFFICE_TT2", city:GetName()));
			else
				controls.CityHasOffice:SetToolTipString("");
			end
		end
		-- CityHasFranchise Status
		if Game.GetNumCorporationsFounded() > 1 then
			controls.CityHasFranchise:SetHide(true);
			local FranchiseTT = "";
			for corporation in GameInfo.Corporations() do
				local iFounder = Game.GetCorporationFounder(corporation.ID);
				if iFounder ~= -1 and city:IsFranchised(iFounder) then
					controls.CityHasFranchise:SetHide(false);
					local iFranchiseBuilding = Players[iFounder]:GetSpecificBuildingType(corporation
						.FranchiseBuildingClass);
					if iFranchiseBuilding ~= -1 then
						if FranchiseTT ~= "" then
							FranchiseTT = FranchiseTT .. "[NEWLINE]";
						end
						FranchiseTT = FranchiseTT ..
							"[ICON_BULLET][COLOR_POSITIVE_TEXT]" ..
							L(GameInfo.Buildings[iFranchiseBuilding].Description) ..
							"[ENDCOLOR]: " .. L(GameInfo.Buildings[iFranchiseBuilding].Help);
					end
				end
			end
			controls.CityHasFranchise:SetToolTipString(FranchiseTT);
		else
			controls.CityHasFranchise:SetHide(true);
		end

		controls.CityCanAirlift:SetHide(not city:CanAirlift());
		controls.CityCanSealift:SetHide(not city:CanSealift());
		controls.CityHasObstacle:SetHide(not city:IsBorderObstacleLand());

		if (isActiveTeamCity) then
			-- CityIsAutomated Status
			if (city:IsProductionAutomated() and Players[city:GetOriginalOwner()]:IsHuman() and not city:IsPuppet()) then
				controls.CityIsAutomated:SetHide(false);
			else
				controls.CityIsAutomated:SetHide(true);
			end

			-- Happiness Status
			local delta = city:getHappinessDelta();
			if (delta < 0) then
				controls.UnhappyIcon:SetHide(false);
				local delta = city:getHappinessDelta() * -1;
				controls.UnhappyIcon:SetToolTipString(L("TXT_KEY_CITY_UNHAPPY", delta) .. "[NEWLINE][NEWLINE]" .. city:GetCityUnhappinessBreakdown(false, true));
			else
				controls.UnhappyIcon:SetHide(true);
			end
		end
		if (bHasSpy) then
			controls.SpyIcon:SetHide(false);
			if (isActivePlayerCity) then
				controls.SpyIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_SPY_YOUR_CITY_TT", strSpyRank, strSpyName, city:GetName(), strSpyRank, strSpyName);
			elseif (player:IsMinorCiv()) then
				controls.SpyIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_SPY_CITY_STATE_TT", strSpyRank, strSpyName, city:GetName(), strSpyRank, strSpyName);
			else
				controls.SpyIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_SPY_OTHER_CIV_TT", strSpyRank, strSpyName, city:GetName(), strSpyRank, strSpyName, strSpyRank, strSpyName);
			end
		else
			controls.SpyIcon:SetHide(true);
		end

		if (bHasDiplomat) then
			controls.DiplomatIcon:SetHide(false);
			controls.DiplomatIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_DIPLOMAT_OTHER_CIV_TT", strSpyRank, strSpyName, city:GetName(), strSpyRank, strSpyName, strSpyRank, strSpyName);
		else
			controls.DiplomatIcon:SetHide(true);
		end

		-- Update strength
		local cityStrengthStr = math.floor(city:GetStrengthValue() / 100);

		local garrisonedUnit = city:GetGarrisonedUnit();
		if garrisonedUnit == nil then
			if isActiveTeamCity then
				controls.GarrisonFrame:SetHide(true);
			end
		end

		local iCityDamage = city:GetDamage();
		local iCityMaxHP = city:GetMaxHitPoints();
		local iCityCurrentHP = iCityMaxHP - iCityDamage;
		local ttText = L("TXT_KEY_UPANEL_SET_HITPOINTS_TT", iCityCurrentHP, iCityMaxHP) .. "[NEWLINE]" .. L("TXT_KEY_CITYVIEW_CITY_COMB_STRENGTH_TT");
		local iRange, iIndirect = city:GetBombardRange();
		if (iIndirect == 1) then
			ttText = ttText ..
				": [ICON_RANGE_STRENGTH] " ..
				city:GetStrengthValue(true) / 100 ..
				"[NEWLINE][ICON_RANGE_STRENGTH] " ..
				L("TXT_KEY_COMBAT_RANGE_HEADING3_TITLE") ..
				": " ..
				iRange ..
				"[NEWLINE][COLOR_POSITIVE_TEXT]" .. L("TXT_KEY_PROMOTION_INDIRECT_FIRE") .. "[ENDCOLOR]";
		else
			ttText = ttText ..
				": [ICON_RANGE_STRENGTH] " ..
				city:GetStrengthValue(true) / 100 ..
				"[NEWLINE][ICON_RANGE_STRENGTH] " ..
				L("TXT_KEY_COMBAT_RANGE_HEADING3_TITLE") ..
				": " ..
				iRange ..
				"[NEWLINE][COLOR_NEGATIVE_TEXT]" .. L("TXT_KEY_PROMOTION_INDIRECT_FIRE") .. "[ENDCOLOR]";
		end
		controls.CityStrength:SetToolTipString(ttText);
		controls.CityStrength:SetText(cityStrengthStr);

		UpdateRangeStrikeIcon(banner);

		-- Update population
		local cityPopulation = math.floor(city:GetPopulation());
		controls.CityPopulation:SetText(cityPopulation);

		-- Update Growth Time
		if (controls.CityGrowth) then
			local cityGrowth = city:GetFoodTurnsLeft();

			if (city:GetYieldRateTimes100(YieldTypes.YIELD_FOOD) == 0) then
				cityGrowth = "-";
				controls.CityBannerRightBackground:LocalizeAndSetToolTip("TXT_KEY_CITY_STOPPED_GROWING_TT", localizedCityName, cityPopulation);
			elseif city:GetYieldRateTimes100(YieldTypes.YIELD_FOOD) < 0 then
				cityGrowth = "[COLOR_WARNING_TEXT]-[ENDCOLOR]";
				controls.CityBannerRightBackground:LocalizeAndSetToolTip("TXT_KEY_CITY_STARVING_TT", localizedCityName);
			else
				controls.CityBannerRightBackground:LocalizeAndSetToolTip("TXT_KEY_CITY_WILL_GROW_TT", localizedCityName, cityPopulation, cityPopulation + 1, cityGrowth);
			end

			controls.CityGrowth:SetText(cityGrowth);
		end

		-- Update Production Time
		if (controls.BuildGrowth) then
			local buildGrowth = "-";

			if (city:IsProduction() and not city:IsProductionProcess()) then
				if (city:GetYieldRateTimes100(YieldTypes.YIELD_PRODUCTION) > 0) then
					buildGrowth = city:GetProductionTurnsLeft();
				end
			end

			controls.BuildGrowth:SetText(buildGrowth);
		end

		-- Update Growth Meter
		if (controls.GrowthBar) then
			local iCurrentFood = city:GetFood();
			local iFoodNeeded = city:GrowthThreshold();
			local iFoodPerTurn = city:FoodDifference();
			local iCurrentFoodPlusThisTurn = iCurrentFood + iFoodPerTurn;

			local fGrowthProgressPercent = iCurrentFood / iFoodNeeded;
			local fGrowthProgressPlusThisTurnPercent = iCurrentFoodPlusThisTurn / iFoodNeeded;
			if (fGrowthProgressPlusThisTurnPercent > 1) then
				fGrowthProgressPlusThisTurnPercent = 1
			end

			controls.GrowthBar:SetPercent(fGrowthProgressPercent);
			controls.GrowthBarShadow:SetPercent(fGrowthProgressPlusThisTurnPercent);
		end

		-- Update Production Meter
		if (controls.ProductionBar) then
			local iCurrentProduction = city:GetProductionTimes100() / 100;
			local iProductionNeeded = city:GetProductionNeeded();
			local iProductionPerTurn = city:GetYieldRateTimes100(YieldTypes.YIELD_PRODUCTION) / 100;
			local iCurrentProductionPlusThisTurn = iCurrentProduction + iProductionPerTurn;

			local fProductionProgressPercent = iCurrentProduction / iProductionNeeded;
			local fProductionProgressPlusThisTurnPercent = iCurrentProductionPlusThisTurn / iProductionNeeded;
			if (fProductionProgressPlusThisTurnPercent > 1) then
				fProductionProgressPlusThisTurnPercent = 1
			end

			controls.ProductionBar:SetPercent(fProductionProgressPercent);
			controls.ProductionBarShadow:SetPercent(fProductionProgressPlusThisTurnPercent);
		end

		-- Update Production Name
		local cityProductionName = city:GetProductionNameKey();
		if cityProductionName == nil or string.len(cityProductionName) == 0 then
			cityProductionName = "TXT_KEY_PRODUCTION_NO_PRODUCTION";
		end
		if (controls.CityProductionName) then
			convertedKey = L(cityProductionName);
			controls.CityProductionName:SetText(convertedKey);
			if (controls.CityBannerLeftBackground) then
				if (city:IsProductionProcess()) then
					local cityProductionProcess = city:GetProductionProcess();
					local tooltipString = GetHelpTextForProcess(cityProductionProcess);
					controls.CityBannerLeftBackground:SetToolTipString(tooltipString);
				else
					if cityProductionName == "TXT_KEY_PRODUCTION_NO_PRODUCTION" then
						controls.CityBannerLeftBackground:SetToolTipString(L("TXT_KEY_CITY_NOT_PRODUCING", localizedCityName));
					else
						local productionTurnsLeft = city:GetProductionTurnsLeft();
						local tooltipString;
						if productionTurnsLeft > 99 then
							tooltipString = L("TXT_KEY_CITY_CURRENTLY_PRODUCING_99PLUS_TT", localizedCityName, cityProductionName);
						else
							tooltipString = L("TXT_KEY_CITY_CURRENTLY_PRODUCING_TT", localizedCityName, cityProductionName, productionTurnsLeft);
						end
						controls.CityBannerLeftBackground:SetToolTipString(tooltipString);
					end
				end
			end
		end

		-- Update Production icon
		if controls.CityBannerProductionImage then
			local unitProduction = city:GetProductionUnit();
			local buildingProduction = city:GetProductionBuilding();
			local projectProduction = city:GetProductionProject();
			local processProduction = city:GetProductionProcess();

			if unitProduction ~= -1 then
				local portraitOffset, portraitAtlas = UI.GetUnitPortraitIcon(unitProduction, city:GetOwner());
				if IconHookup(portraitOffset, 45, portraitAtlas, controls.CityBannerProductionImage) then
					controls.CityBannerProductionImage:SetHide(false);
				else
					controls.CityBannerProductionImage:SetHide(true);
				end
			elseif buildingProduction ~= -1 then
				local thisBuildingInfo = GameInfo.Buildings[buildingProduction];
				if IconHookup(thisBuildingInfo.PortraitIndex, 45, thisBuildingInfo.IconAtlas, controls.CityBannerProductionImage) then
					controls.CityBannerProductionImage:SetHide(false);
				else
					controls.CityBannerProductionImage:SetHide(true);
				end
			elseif projectProduction ~= -1 then
				local thisProjectInfo = GameInfo.Projects[projectProduction];
				if IconHookup(thisProjectInfo.PortraitIndex, 45, thisProjectInfo.IconAtlas, controls.CityBannerProductionImage) then
					controls.CityBannerProductionImage:SetHide(false);
				else
					controls.CityBannerProductionImage:SetHide(true);
				end
			elseif processProduction ~= -1 then
				local thisProcessInfo = GameInfo.Processes[processProduction];
				if IconHookup(thisProcessInfo.PortraitIndex, 45, thisProcessInfo.IconAtlas, controls.CityBannerProductionImage) then
					controls.CityBannerProductionImage:SetHide(false);
				else
					controls.CityBannerProductionImage:SetHide(true);
				end
			else -- really should have an error texture
				controls.CityBannerProductionImage:SetHide(true);
			end

			if isActivePlayerCity then
				controls.CityBannerProductionButton:RegisterCallback(Mouse.eLClick, OnProdClick);
				controls.CityBannerProductionButton:SetVoids(city:GetID(), nil);
				Enable(controls.BannerButton);
			end
		end

		-- This is another player's banner instance
		if (controls.MinorIndicator and controls.StatusIcon) then
			controls.StatusIcon:SetColor(textColor);
			local civType = player:GetCivilizationType();
			local civInfo = GameInfo.Civilizations[civType];

			if (player:IsMinorCiv()) then
				SetUpMinorMeter(eActivePlayer, banner.PlayerID, controls, textColor);

				-- minor trait icon
				controls.StatusIcon:SetTexture(GameInfo.MinorCivTraits
					[GameInfo.MinorCivilizations[player:GetMinorCivType()].MinorCivTrait].TraitIcon);
				controls.StatusIcon:SetTextureOffsetVal(0, 0);
			else
				IconHookup(civInfo.PortraitIndex, 32, civInfo.AlphaIconAtlas, controls.StatusIcon);
				controls.StatusIcon:SetOffsetX(0);
				controls.StatusIconBG:SetHide(true);
				controls.StatusMeterFrame:SetHide(true);
			end

			local pOriginalOwner = Players[city:GetOriginalOwner()];
			if (pOriginalOwner:IsMinorCiv()) then
				local _, originalColor = pOriginalOwner:GetPlayerColors();
				originalColor.w = 1;

				civType = pOriginalOwner:GetCivilizationType();
				civInfo = GameInfo.Civilizations[civType];
				IconHookup(civInfo.PortraitIndex, 32, civInfo.AlphaIconAtlas, controls.MinorIndicator);

				controls.MinorIndicator:SetColor(originalColor);
				controls.MinorIndicator:SetHide(false);
			else
				controls.MinorIndicator:SetHide(true);
			end

			Refresh(controls.NameStack);
		end

		-- Refresh the damage bar too
		RefreshCityDamage(banner, iCityDamage, iCityMaxHP);
	end

	Refresh(controls.NameStack, controls.IconsStack);
end

----------------------------------------------------------------
----------------------------------------------------------------
function SetUpMinorMeter(iMajor, iMinor, controls, minorColor)
	controls.StatusMeterFrame:SetHide(false);
	controls.StatusIconBG:SetHide(false);
	controls.StatusIcon:SetOffsetX(0);
	controls.StatusIcon:SetColor({x = 1, y = 1, z = 1, w = 1});

	-- If we're neutral, show the minor's own colors
	if (GetCityStateStatusType(iMajor, iMinor) == "MINOR_FRIENDSHIP_STATUS_NEUTRAL") then
		controls.StatusIcon:SetColor(minorColor);
		controls.StatusIconBG:SetHide(true);
		controls.StatusIcon:SetOffsetX(-5);
	end

	-- If INF is 0, don't bother showing the meter
	if (Players[iMinor]:GetMinorCivFriendshipWithMajor(iMajor) == 0) then
		controls.StatusMeterFrame:SetHide(true);
	end

	UpdateCityStateStatusUI(iMajor, iMinor, controls.PositiveStatusMeter, controls.NegativeStatusMeter,
		controls.StatusMeterMarker, controls.StatusIconBG);
end

-------------------------------------------------
-- On City Created
-------------------------------------------------
function OnCityCreated(hexPos, playerID, cityID, _, _, _, _, _, fowState)
	local instance = {};
	local svInstance = {};

	--If the player is on your team, display TeamCityBanner, otherwise display OtherCityBanner.
	local iActivePlayer = Game.GetActivePlayer();
	local iActiveTeam = Players[iActivePlayer]:GetTeam();
	local team = Players[playerID]:GetTeam();

	if g_cityBanners[playerID][cityID] then
		return;
	end

	local gridPosX, gridPosY = ToGridFromHex(hexPos.x, hexPos.y);

	local isActiveType = false;
	if (iActiveTeam == team or (PreGame.GetSlotStatus(Game.GetActivePlayer()) == SlotStatus.SS_OBSERVER and (Game:GetObserverUIOverridePlayer() == -1 or Players[Game:GetObserverUIOverridePlayer()]:GetTeam() == team))) then
		isActiveType = true;
	end

	if (isActiveType == false) then
		instance = otherInstanceManager:Acquire(Controls.CityBanners);
		instance.BannerButton:SetVoid1(gridPosX);
		instance.BannerButton:SetVoid2(gridPosY);
	else
		instance = teamInstanceManager:Acquire(Controls.CityBanners);

		instance.BannerButton:SetVoid1(gridPosX);
		instance.BannerButton:SetVoid2(gridPosY);

		instance.CityRangeStrikeButton:SetVoid1(playerID);
		instance.CityRangeStrikeButton:SetVoid2(cityID);

		svInstance = svRangeStrikeInstanceManager:Acquire(Controls.StrategicViewStrikeButtons);
		svInstance.Anchor:SetWorldPosition(HexToWorld(hexPos));
		svInstance.CityRangeStrikeButton:SetVoid1(playerID);
		svInstance.CityRangeStrikeButton:SetVoid2(cityID);
	end

	local banner = {
		PlayerID = playerID,
		CityID = cityID,
		IsActiveTeam = isActiveType,
		Instance = instance,
		SVInstance = svInstance,
		Hex = hexPos,
	};

	g_cityBanners[playerID][cityID] = banner;

	local HexPos = HexToWorld(hexPos);
	instance.Anchor:SetWorldPosition(VecAdd(HexPos, WorldPositionOffset));

	RefreshCityBanner(banner);

	-- Hide the banner if the city plot has not been explored
	SetBannerVisibility(banner, fowState ~= FOWStates.UNEXPLORED);
end

Events.SerialEventCityCreated.Add(OnCityCreated);


--- Check the banner to see if it needs to be rebuilt (active player change)
--- @param banner CityBanner
function CheckCityBannerRebuild(banner)
	local cityTeam = Players[banner.PlayerID]:GetTeam();
	local eActivePlayer = Game.GetActivePlayer();
	local eActiveTeam = Game.GetActiveTeam();

	-- If the city banner was instanced for the active team and now its not or vice versa, rebuild the banner
	local bWantActive = cityTeam == eActiveTeam;
	if Players[eActivePlayer]:IsObserver() then
		if Game:GetObserverUIOverridePlayer() == -1 then
			bWantActive = true;
		else
			bWantActive = cityTeam == Players[Game:GetObserverUIOverridePlayer()]:GetTeam();
		end
	end

	if (banner.IsActiveTeam ~= bWantActive) then
		-- rebuild the banner
		local controlTable = {};
		local gridPosX, gridPosY = ToGridFromHex(banner.Hex.x, banner.Hex.y);
		local worldPos = HexToWorld(banner.Hex);

		local bWasHidden = banner.Instance.Anchor:IsHidden();
		-- print("Rebuilding banner for player: " .. tostring(banner.playerID) .. " city: " .. tostring(banner.cityID) .. " from active = " .. tostring(banner.IsActiveType) .. " to active = " .. tostring(bWantActive));

		if (not bWantActive) then
			-- If we don't want the 'active' style, then it must have been active.
			-- Release the old one
			teamInstanceManager:Recycle(banner.Instance);

			if banner.SVInstance then
				svRangeStrikeInstanceManager:Recycle(banner.SVInstance);
				banner.SVInstance = nil;
			end
			-- Create the new, non-active banner
			controlTable = otherInstanceManager:Acquire(Controls.CityBanners);
			controlTable.BannerButton:SetVoid1(gridPosX);
			controlTable.BannerButton:SetVoid2(gridPosY);
		else
			-- Release the old one
			otherInstanceManager:Recycle(banner.Instance);

			-- Create the new active banner
			controlTable = teamInstanceManager:Acquire(Controls.CityBanners);

			controlTable.BannerButton:SetVoid1(gridPosX);
			controlTable.BannerButton:SetVoid2(gridPosY);

			controlTable.CityRangeStrikeButton:SetVoid1(banner.PlayerID);
			controlTable.CityRangeStrikeButton:SetVoid2(banner.CityID);

			-- Create the SV ranged strike button
			local svStrikeButton = svRangeStrikeInstanceManager:Acquire(Controls.StrategicViewStrikeButtons);
			svStrikeButton.Anchor:SetWorldPosition(worldPos);
			svStrikeButton.CityRangeStrikeButton:SetVoid1(banner.PlayerID);
			svStrikeButton.CityRangeStrikeButton:SetVoid2(banner.CityID);

			banner.SVInstance = svStrikeButton;
		end

		controlTable.Anchor:SetWorldPosition(VecAdd(worldPos, WorldPositionOffset));

		-- Attach
		banner.Instance = controlTable;
		-- Set the new active type flag
		banner.IsActiveTeam = bWantActive;

		-- Necessary as the new banner is already visible
		RefreshCityBanner(banner);

		-- Keep the hidden state
		SetBannerVisibility(banner, not bWasHidden);
	end
end

-------------------------------------------------
-- Change the width of the banner so it looks good with the length of the city name
-------------------------------------------------
function DoResizeBanner(BannerInstance)
	-- Just in case
	Refresh(BannerInstance.NameStack);

	local iWidth = BannerInstance.NameStack:GetSizeX();

	-- If this control doesn't exist, then we're using the active player banner as opposed to the other player.
	-- NOTE:	There are rare instances when the active player will change (hotseat, autoplay) so just checking
	--			the active player is not good enough.
	if (BannerInstance.CityBannerBaseFrame == nil) then
		iWidth = iWidth + 60; -- Offset for human player's banners

		BannerInstance.CityBannerBackgroundIcon:SetSizeX(iWidth);
		BannerInstance.CityBannerButtonGlow:SetSizeX(iWidth);
		BannerInstance.CityBannerButtonBase:SetSizeX(iWidth);
	else
		iWidth = iWidth + 10; -- Offset for other player's banners
		BannerInstance.CityBannerBaseFrame:SetSizeX(iWidth);
	end

	BannerInstance.BannerButton:SetSizeX(iWidth);
	BannerInstance.CityBannerBackground:SetSizeX(iWidth);
	BannerInstance.CityBannerBackgroundHL:SetSizeX(iWidth);

	BannerInstance.BannerButton:ReprocessAnchoring();
	BannerInstance.NameStack:ReprocessAnchoring();
end

-- City is destroyed or captured, remove the banner
local function OnCityDestroyed(_, ePlayer, iCityID)
	local banner = g_cityBanners[ePlayer][iCityID];
	if not banner then
		return;
	end

	if teamInstanceManager:HasInstance(banner.Instance) then
		teamInstanceManager:Recycle(banner.Instance);
	else
		otherInstanceManager:Recycle(banner.Instance);
	end

	if banner.SVInstance then
		svRangeStrikeInstanceManager:Recycle(banner.SVInstance);
		banner.SVInstance = nil;
	end

	g_cityBanners[ePlayer][iCityID] = nil;
end

Events.SerialEventCityCaptured.Add(OnCityDestroyed);
Events.SerialEventCityDestroyed.Add(OnCityDestroyed);

Events.SerialEventCitySetDamage.Add(function (ePlayer, iCityID, iDamage)
	local banner = g_cityBanners[ePlayer][iCityID];
	if not banner then
		return;
	end

	-- It is possible that the city is gone (an owner change deletes the city) by now, but the banner still exists as messages are played back.
	-- Get the max hit points from the city, but if it is not there get the global max as a dummy.
	local pCity = Players[ePlayer]:GetCityByID(iCityID);
	local iMaxHitPoints = pCity and pCity:GetMaxHitPoints() or GameDefines.MAX_CITY_HIT_POINTS;
	RefreshCityDamage(banner, iDamage, iMaxHitPoints);
end);

Events.SerialEventCityInfoDirty.Add(function ()
	-- Check all banners for need of update
	ForEachCityBanner(RefreshCityBanner);
end);

Events.SpecificCityInfoDirty.Add(function (ePlayer, iCityID, eUpdateType)
	if eUpdateType == CityUpdateTypes.CITY_UPDATE_TYPE_BANNER or
	eUpdateType == CityUpdateTypes.CITY_UPDATE_TYPE_ENEMY_IN_RANGE or
	eUpdateType == CityUpdateTypes.CITY_UPDATE_TYPE_GARRISON then
		local banner = g_cityBanners[ePlayer][iCityID];
		if not banner then
			return;
		end

		if eUpdateType == CityUpdateTypes.CITY_UPDATE_TYPE_ENEMY_IN_RANGE then
			UpdateRangeStrikeIcon(banner);
		else
			RefreshCityBanner(banner);
		end
	end
end);

Events.HexFOWStateChanged.Add(function (vHex, eFow, bWholeMap)
	if bWholeMap then
		ForEachCityBanner(function (banner)
			SetBannerVisibility(banner, eFow ~= FOWStates.UNEXPLORED);
		end);
		return;
	end

	local iGridX, iGridY = ToGridFromHex(vHex.x, vHex.y);
	local pPlot = Map.GetPlot(iGridX, iGridY);
	local pCity = pPlot and pPlot:GetPlotCity();
	if not pCity then
		return;
	end

	local banner = g_cityBanners[pCity:GetOwner()][pCity:GetID()];
	if not banner then
		return;
	end

	local bVisible = (eFow ~= FOWStates.UNEXPLORED);
	if bVisible then
		local pGarrison = pCity:GetGarrisonedUnit();
		if pGarrison and banner.IsActiveTeam and not UnitMoving(pGarrison:GetOwner(), pGarrison:GetID()) then
			Show(banner.Instance.GarrisonFrame);
		end
	end
	SetBannerVisibility(banner, bVisible);
end);

-------------------------------------------------
-- On City Range Strike Button Selected
-------------------------------------------------
function OnCityRangeStrikeButtonClick(PlayerID, CityID)
	local player = Players[PlayerID];
	if (player == nil) then
		print("Invalid player");
		return;
	end

	local city = player:GetCityByID(CityID);

	if (player:GetID() ~= Game.GetActivePlayer()) then
		print("Not my player!");
		return;
	end

	if (city == nil) then
		print("No city!");
		return;
	end;

	UI.SetInterfaceMode(InterfaceModeTypes.INTERFACEMODE_CITY_RANGE_ATTACK);
	UI.ClearSelectionList();
	UI.SelectCity(city);

	Events.InitCityRangeStrike(PlayerID, CityID);
end

function OnInitCityRangeStrike(PlayerID, CityID)
	local player = Players[PlayerID];
	if (player == nil) then
		print("Invalid player");
		return;
	end

	local city = player:GetCityByID(CityID);

	if (player:GetID() ~= Game.GetActivePlayer()) then
		print("Not my player!");
		return;
	end

	if (city == nil) then
		print("No city!");
		return;
	end;

	UI.SelectCity(city);
	UI.SetInterfaceMode(InterfaceModeTypes.INTERFACEMODE_CITY_RANGE_ATTACK);
end

Events.InitCityRangeStrike.Add(OnInitCityRangeStrike);

------------------------------------------------------------
------------------------------------------------------------
local function LeaderSelected(ePlayer)
	if not Players[Game.GetActivePlayer()]:IsTurnActive() or Game.IsProcessingMessages() then
		return;
	end

	local player = Players[ePlayer];
	if player:IsHuman() then
		Events.OpenPlayerDealScreenEvent(ePlayer);
	else
		UI.SetRepeatActionPlayer(ePlayer);
		UI.ChangeStartDiploRepeatCount(1);
		player:DoBeginDiploWithHuman();
	end
end

------------------------------------------------------------
------------------------------------------------------------
function OnBannerClick(x, y)
	local plot = Map.GetPlot(x, y);
	if plot then
		local playerID = plot:GetOwner();
		local player = Players[playerID];

		-- Active player city
		if playerID == Game.GetActivePlayer() then
			-- Puppets are special
			if (plot:GetPlotCity():IsPuppet() and not player:MayNotAnnex()) then
				local popupInfo = {
					Type = ButtonPopupTypes.BUTTONPOPUP_ANNEX_CITY,
					Data1 = plot:GetPlotCity():GetID(),
					Data2 = -1,
					Data3 = -1,
					Option1 = false,
					Option2 = false,
				}
				Events.SerialEventGameMessagePopup(popupInfo);
			else
				UI.DoSelectCityAtPlot(plot);
			end

			-- Other player, which has been met
		elseif (Teams[Game.GetActiveTeam()]:IsHasMet(player:GetTeam())) then
			if player:IsMinorCiv() then
				UI.DoSelectCityAtPlot(plot);
			else
				LeaderSelected(playerID);
			end
		end
	end
end

Events.UnitGarrison.Add(function (playerID, unitID, bGarrisoned)
	if bGarrisoned and not UnitMoving(playerID, unitID) then
		local player = Players[playerID];
		local unit = player:GetUnitByID(unitID);
		local cityBanners = g_cityBanners[playerID];
		if unit ~= nil and cityBanners ~= nil then
			local city = unit:GetGarrisonedCity();
			if city ~= nil then
				local banner = cityBanners[city:GetID()];
				if banner and banner.IsActiveTeam then
					Show(banner.Instance.GarrisonFrame);
				end
			end
		end
	end
end);

Events.UnitMoveQueueChanged.Add(function (playerID, unitID, bRemainingMoves)
	if not bRemainingMoves then
		local player = Players[playerID];
		local unit = player:GetUnitByID(unitID);
		local cityBanners = g_cityBanners[playerID];
		if unit ~= nil and cityBanners ~= nil and unit:IsGarrisoned() then
			local city = unit:GetGarrisonedCity();
			if city ~= nil then
				local banner = cityBanners[city:GetID()];
				if banner and banner.IsActiveTeam then
					Show(banner.Instance.GarrisonFrame);
				end
			end
		end
	end
end);

-------------------------------------------------
-------------------------------------------------
function OnProdClick(cityID)
	local playerID = Game.GetActivePlayer();
	local activePlayer = Players[playerID]
	local city = activePlayer:GetCityByID(cityID);
	if city and not city:IsPuppet() then
		local popupInfo = {
			Type = ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION,
			Data1 = cityID,
			Data2 = -1,
			Data3 = -1,
			Option1 = false,
			Option2 = false,
		}
		Events.SerialEventGameMessagePopup(popupInfo);
		-- send production popup message
	end
end

------------------------------------------------------------
------------------------------------------------------------
function OnInterfaceModeChanged(oldInterfaceMode, newInterfaceMode)
	local disableBanners = newInterfaceMode ~= InterfaceModeTypes.INTERFACEMODE_SELECTION;
	for iPlayer, playerCityBanners in pairs(g_cityBanners) do
		for iCity, cityBanner in pairs(playerCityBanners) do
			cityBanner.Instance.BannerButton:SetDisabled(disableBanners);
			cityBanner.Instance.BannerButton:EnableToolTip(not disableBanners);
		end
	end
end

Events.InterfaceModeChanged.Add(OnInterfaceModeChanged);

------------------------------------------------------------
------------------------------------------------------------
function OnStrategicViewStateChanged(bStrategicView, bCityBanners)
	local bShowBanners = bCityBanners or not bStrategicView;
	Controls.CityBanners:SetHide(not bShowBanners);
	Controls.StrategicViewStrikeButtons:SetHide(bShowBanners);
end

Events.StrategicViewStateChanged.Add(OnStrategicViewStateChanged);

local function HideGarrisonRing(iX, iY, bHide)
	local pPlot = Map.GetPlot(iX, iY);
	local pCity = pPlot and pPlot:GetPlotCity();
	if not pCity then
		return;
	end

	local banner = g_cityBanners[pCity:GetOwner()][pCity:GetID()];
	if not banner or not banner.IsActiveTeam then
		return;
	end

	banner.Instance.GarrisonFrame:SetHide(bHide or not pCity:GetGarrisonedUnit());
end

Events.RunCombatSim.Add(function(_, _, _, _, _, _, _, _, _, _, _, attackerX, attackerY, defenderX, defenderY)
	HideGarrisonRing(attackerX, attackerY, true);
	HideGarrisonRing(defenderX, defenderY, true);
end);

Events.EndCombatSim.Add(function(_, _, _, _, _, _, _, _, _, _, attackerX, attackerY, defenderX, defenderY)
	HideGarrisonRing(attackerX, attackerY, false);
	HideGarrisonRing(defenderX, defenderY, false);
end);

-- 'Active' (local human) player has changed
Events.GameplaySetActivePlayer.Add(function ()
	-- Check all banners for need of update
	ForEachCityBanner(CheckCityBannerRebuild);
end);

-- The active player's turn has begun; make sure their range strike icons are correct
Events.ActivePlayerTurnStart.Add(function ()
	local eActivePlayer = Game.GetActivePlayer();
	for _, banner in pairs(g_cityBanners[eActivePlayer]) do
		UpdateRangeStrikeIcon(banner);
	end
end);

-- Refresh all city banners on hot load
if ContextPtr:IsHotLoad() then
	for ePlayer, pPlayer in pairs(Players) do
		if pPlayer:IsAlive() then
			for pCity in pPlayer:Cities() do
				OnCityCreated(ToHexFromGrid(Vector2(pCity:GetX(), pCity:GetY())), ePlayer, pCity:GetID(), nil, nil, nil, nil, nil, pCity:Plot():GetActiveFogOfWarMode());
			end
		end
	end
end
