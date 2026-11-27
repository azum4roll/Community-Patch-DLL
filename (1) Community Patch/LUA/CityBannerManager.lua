print("This is the modded CityBannerManager from Community Patch");

include("IconSupport");
include("InfoTooltipInclude");
include("CityStateStatusHelper");
include("VPUI_core");
include("CPK.lua");

local L = Locale.Lookup;

local IconHookupOrDefault = VP.IconHookupOrDefault;

local Color = CPK.Text.Color;
local Show = CPK.UI.Control.Show;
local Hide = CPK.UI.Control.Hide;
local Enable = CPK.UI.Control.Enable;
local Refresh = CPK.UI.Control.Refresh;
local InstanceManager = CPK.UI.Control.Instance.Manager;

local WORLD_POSITION_OFFSET = {x = 0, y = 0, z = 35};

--- Handle the behavior when a city banner is clicked.
--- @param ePlayer PlayerId
--- @param iCityID CityId
local function OnBannerClick(ePlayer, iCityID)
	local pPlayer = Players[ePlayer];
	local pCity = pPlayer:GetCityByID(iCityID);
	local pPlot = pCity:Plot();

	-- Active player city
	if ePlayer == Game.GetActivePlayer() then
		-- Puppets are special
		if pCity:IsPuppet() and not pPlayer:MayNotAnnex() then
			local popupInfo = {
				Type = ButtonPopupTypes.BUTTONPOPUP_ANNEX_CITY,
				Data1 = iCityID,
				Data2 = -1,
				Data3 = -1,
				Option1 = false,
				Option2 = false,
			};
			Events.SerialEventGameMessagePopup(popupInfo);
		else
			UI.DoSelectCityAtPlot(pPlot);
		end

	-- Another player, which has been met
	elseif Teams[Game.GetActiveTeam()]:IsHasMet(pPlayer:GetTeam()) then
		if pPlayer:IsMinorCiv() then
			UI.DoSelectCityAtPlot(pPlot);
		else
			-- Do nothing if it's not the active player's turn or the game is still processing
			if not Players[Game.GetActivePlayer()]:IsTurnActive() or Game.IsProcessingMessages() then
				return;
			end

			if pPlayer:IsHuman() then
				Events.OpenPlayerDealScreenEvent(ePlayer);
			else
				UI.SetRepeatActionPlayer(ePlayer);
				UI.ChangeStartDiploRepeatCount(1);
				pPlayer:DoBeginDiploWithHuman();
			end
		end
	end
end

--- @param ePlayer PlayerId
--- @param iCityID CityId
local function InitCityRangeStrike(ePlayer, iCityID)
	assert(ePlayer == Game.GetActivePlayer(), "Leftover range strike button on other players");

	UI.ClearSelectionList();

	Events.InitCityRangeStrike(ePlayer, iCityID);
end

-- Always call SetBannerVisibility() after acquiring an instance.
-- That decides whether the banner's appearance needs to be updated.
local teamInstanceManager = InstanceManager.New({
	instance = "TeamCityBanner",
	onCreated = function (instance)
		instance.BannerButton:RegisterCallback(Mouse.eLClick, OnBannerClick);
		instance.CityRangeStrikeButton:RegisterCallback(Mouse.eLClick, InitCityRangeStrike);
	end,
	onAcquire = function (instance)
		Hide(instance.Anchor);
	end,
});

-- Always call SetBannerVisibility() after acquiring an instance.
-- That decides whether the banner's appearance needs to be updated.
local otherInstanceManager = InstanceManager.New({
	instance = "OtherCityBanner",
	onCreated = function (instance)
		instance.BannerButton:RegisterCallback(Mouse.eLClick, OnBannerClick);
	end,
	onAcquire = function (instance)
		Hide(instance.Anchor);
	end,
});

local svRangeStrikeInstanceManager = InstanceManager.New({
	instance = "SVRangeStrikeButton",
	onCreated = function (instance)
		instance.CityRangeStrikeButton:RegisterCallback(Mouse.eLClick, InitCityRangeStrike);
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

--- @enum FOWStates
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

--- @param banner CityBanner
--- @return boolean
local function ShouldBannerBeActiveTeamVersion(banner)
	local eTeam = Players[banner.PlayerID]:GetTeam();
	if Players[Game.GetActivePlayer()]:IsObserver() then
		local eObserverUIOverridePlayer = Game:GetObserverUIOverridePlayer();
		if eObserverUIOverridePlayer == -1 then -- global observer mode
			return true;
		else
			return eTeam == Players[eObserverUIOverridePlayer]:GetTeam();
		end
	end

	return eTeam == Game.GetActiveTeam();
end

local function OpenProductionPopup(iCityID)
	-- Verify city exists
	if Players[Game.GetActivePlayer()]:GetCityByID(iCityID) then
		Events.SerialEventGameMessagePopup({
			Type = ButtonPopupTypes.BUTTONPOPUP_CHOOSEPRODUCTION,
			Data1 = iCityID,
			Data2 = -1,
			Data3 = -1,
			Option1 = false,
			Option2 = false,
		});
	end
end

--- Determine whether to show the Range Strike Button
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
local function UpdateRangeStrikeButton(banner)
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

--- Change the width of the banner based on the length of the city name
--- @param instance ControlInstance
local function ResizeBanner(instance)
	-- Just in case
	Refresh(instance.NameStack);

	local iWidth = instance.NameStack:GetSizeX();

	-- Only other teams' banners have this control
	if not instance.CityBannerBaseFrame then
		-- Active team banners are wider
		iWidth = iWidth + 60;
		instance.CityBannerBackgroundIcon:SetSizeX(iWidth);
		instance.CityBannerButtonGlow:SetSizeX(iWidth);
		instance.CityBannerButtonBase:SetSizeX(iWidth);
	else
		iWidth = iWidth + 10;
		instance.CityBannerBaseFrame:SetSizeX(iWidth);
	end

	instance.BannerButton:SetSizeX(iWidth);
	instance.CityBannerBackground:SetSizeX(iWidth);
	instance.CityBannerBackgroundHL:SetSizeX(iWidth);

	instance.BannerButton:ReprocessAnchoring();
	instance.NameStack:ReprocessAnchoring();
end

--- @param eMajor PlayerId
--- @param eMinor PlayerId
--- @param instance ControlInstance
--- @param vMinorColor Vector4
local function SetUpMinorMeter(eMajor, eMinor, instance, vMinorColor)
	-- If we're neutral, show the minor's own colors
	if GetCityStateStatusType(eMajor, eMinor) == "MINOR_FRIENDSHIP_STATUS_NEUTRAL" then
		Hide(instance.StatusIconBG);
		instance.StatusIcon:SetOffsetX(-5);
		instance.StatusIcon:SetColor(vMinorColor);
	else
		Show(instance.StatusIconBG);
		instance.StatusIcon:SetOffsetX(0);
		instance.StatusIcon:SetColor(Color.White:Vec4());
	end

	-- If influence is 0, don't bother showing the meter
	instance.StatusMeterFrame:SetHide(Players[eMinor]:GetMinorCivFriendshipWithMajor(eMajor) == 0);

	UpdateCityStateStatusUI(eMajor, eMinor, instance.PositiveStatusMeter, instance.NegativeStatusMeter, instance.StatusMeterMarker, instance.StatusIconBG);
end

--- Update banner to reflect latest city info.
--- Make sure this function is called immediately after a banner is unhidden.
--- @param banner CityBanner
local function RefreshCityBanner(banner)
	-- Skip if banner is hidden
	if banner.Instance.Anchor:IsHidden() then
		return;
	end

	local strToolTip = "";
	local pPlayer = Players[banner.PlayerID];
	local eActivePlayer = Game:GetActivePlayer();
	local bActivePlayer = (banner.PlayerID == eActivePlayer);
	local bActiveTeam = ShouldBannerBeActiveTeamVersion(banner);
	local bMinor = pPlayer:IsMinorCiv();
	local pCity = pPlayer:GetCityByID(banner.CityID);

	assert(pCity);

	local bHasSpy = false;
	local bHasDiplomat = false;
	local strSpyName;
	local strSpyRank;
	for _, tSpy in ipairs(Players[eActivePlayer]:GetEspionageSpies()) do
		if tSpy.CityX == pCity:GetX() and tSpy.CityY == pCity:GetY() then
			if tSpy.IsDiplomat then
				bHasDiplomat = true;
			else
				bHasSpy = true;
			end
			strSpyName = L(tSpy.Name);
			strSpyRank = L(tSpy.Rank);
			break;
		end
	end

	local instance = banner.Instance;

	-- Update colors
	local primaryColor, secondaryColor = pPlayer:GetPlayerColors();
	if bMinor then
		primaryColor, secondaryColor = secondaryColor, primaryColor;
	end

	local backgroundColor = {x = secondaryColor.x, y = secondaryColor.y, z = secondaryColor.z, w = 0.7};

	instance.CityBannerBackground:SetColor(backgroundColor);
	if (bActiveTeam) then
		if (instance.CityBannerBGLeftHL ~= nil) then
			instance.CityBannerBGLeftHL:SetColor(backgroundColor);
		end
		if (instance.CityBannerBGRightHL ~= nil) then
			instance.CityBannerBGRightHL:SetColor(backgroundColor);
		end
		if (instance.CityBannerRightBackground ~= nil) then
			instance.CityBannerRightBackground:SetColor(backgroundColor);
		end
		if (instance.CityBannerLeftBackground ~= nil) then
			instance.CityBannerLeftBackground:SetColor(backgroundColor);
		end
	else
		--NOTE: If the active player were to ever change (such as during an auto play) these controls will not exist because
		--		the city banner is of the "active player" type and not the "other player" type.
		--		This fix is merely a fix to the Lua nil value error and not a proper solution to the problem.
		if (instance.RightBackground ~= nil and instance.LeftBackground ~= nil) then
			instance.RightBackground:SetColor(backgroundColor);
			instance.LeftBackground:SetColor(backgroundColor);
		end
	end

	local textColor = {x = primaryColor.x, y = primaryColor.y, z = primaryColor.z, w = 1};
	local textColor200 = {x = primaryColor.x, y = primaryColor.y, z = primaryColor.z, w = 0.7};
	local textColorShadow = {x = 0, y = 0, z = 0, w = 0.5};
	local textColorSoft = {x = 1, y = 1, z = 1, w = 0.5};
	if (instance.CityProductionName) then
		instance.CityProductionName:SetColor(textColor200, 0);
	end

	instance.CityName:SetColor(textColor, 0);
	instance.CityName:SetColor(textColorShadow, 1);
	instance.CityName:SetColor(textColorSoft, 2);

	-- Update name
	local cityName = pCity:GetNameKey();
	local localizedCityName = L(cityName);
	local convertedKey = Locale.ToUpper(localizedCityName);

	if (pCity:IsCapital() and not bMinor) then
		convertedKey = "[ICON_CAPITAL]" .. convertedKey;
	end
	--CBP
	if (pCity:IsCapital() and bMinor and pPlayer:IsMarried(eActivePlayer)) then
		convertedKey = "[ICON_RES_MARRIAGE]" .. convertedKey;
	end
	--END

	instance.CityName:SetText(convertedKey);

	if (bActivePlayer) then
		if (pCity:IsPuppet() and not pPlayer:MayNotAnnex()) then
			strToolTip = L("TXT_KEY_CITY_ANNEX_TT");
		else
			strToolTip = L("TXT_KEY_CITY_ENTER_CITY_SCREEN");
		end
	elseif (bActiveTeam) then
		strToolTip = L("TXT_KEY_CITY_TEAMMATE");
	elseif (Game.IsOption(GameOptionTypes.GAMEOPTION_ALWAYS_WAR)) then
		strToolTip = L("TXT_KEY_ALWAYS_AT_WAR_WITH_CITY");
	elseif (bMinor) then
		local strStatusTT = GetCityStateStatusToolTip(eActivePlayer, banner.PlayerID, false);
		strToolTip = strToolTip .. strStatusTT;
		if (PreGame.GetSlotStatus(Game.GetActivePlayer()) ~= SlotStatus.SS_OBSERVER) then
			instance.StatusIconBG:SetToolTipString(strStatusTT);
			instance.StatusIcon:SetToolTipString(strStatusTT);
		end
	elseif (not Teams[Game.GetActiveTeam()]:IsHasMet(pPlayer:GetTeam())) then
		strToolTip = L("TXT_KEY_HAVENT_MET");
	else
		strToolTip = L("TXT_KEY_TALK_TO_PLAYER");
	end

	if (Teams[Game.GetActiveTeam()]:IsAtWar(pPlayer:GetTeam())) then
		strToolTip = strToolTip .. "[NEWLINE]----------------[NEWLINE]"
		strToolTip = strToolTip .. pPlayer:GetWarmongerPreviewString(pCity:GetOwner(), pCity, Game.GetActivePlayer());
		if (pCity:GetOriginalOwner() ~= pCity:GetOwner()) then
			strToolTip = strToolTip .. "[NEWLINE]----------------[NEWLINE]"
			strToolTip = strToolTip ..
				pPlayer:GetLiberationPreviewString(pCity:GetOwner(), pCity, Game.GetActivePlayer());
		end
	end

	local eReligion = pCity:GetReligiousMajority();

	if (eReligion >= 0) then
		local religion = GameInfo.Religions[eReligion];
		IconHookupOrDefault(religion.PortraitIndex, 32, religion.IconAtlas, instance.ReligiousIcon);
		IconHookupOrDefault(religion.PortraitIndex, 32, religion.IconAtlas, instance.ReligiousIconShadow);
	end

	local religionToolTip = "";
	if (GetReligionTooltip) then
		religionToolTip = GetReligionTooltip(pCity);
	end

	if (religionToolTip ~= "") then
		strToolTip = strToolTip .. "[NEWLINE]----------------[NEWLINE]" .. religionToolTip;
	end
	instance.BannerButton:SetToolTipString(strToolTip);

	if (instance.ReligiousIcon ~= nil) then
		instance.ReligiousIcon:SetToolTipString(religionToolTip);
	end

	local bHasReligion = (eReligion >= 0);
	if (instance.ReligiousIcon ~= nil) then
		instance.ReligiousIconContainer:SetHide(not bHasReligion);
	end

	ResizeBanner(instance);

	-- Connected to capital?
	if (bActiveTeam) then
		if (not pCity:IsCapital() and not pCity:IsBlockaded()) then
			if (pCity:IsIndustrialConnectedToCapital()) then
				instance.IndustrialConnectedIcon:SetHide(false);
				instance.ConnectedIcon:SetHide(true);
			elseif (pCity:IsConnectedToCapital()) then
				instance.ConnectedIcon:SetHide(false);
				instance.IndustrialConnectedIcon:SetHide(true);
			else
				instance.ConnectedIcon:SetHide(true);
				instance.IndustrialConnectedIcon:SetHide(true);
			end
		else
			instance.ConnectedIcon:SetHide(true);
			instance.IndustrialConnectedIcon:SetHide(true);
		end
	end

	-- Blockaded
	if pCity:IsBlockaded() then
		if pCity:GetSappedTurns() > 0 then
			instance.BlockadedIcon:SetText("[ICON_SAPPED]");
			instance.BlockadedIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_SAPPED", pCity:GetSappedTurns());
		else
			instance.BlockadedIcon:SetText("[ICON_BLOCKADED]")
			instance.BlockadedIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_BLOCKADED");
		end
		Show(instance.BlockadedIcon);
	else
		Hide(instance.BlockadedIcon);
	end

	-- Being Razed
	if (pCity:IsRazing()) then
		instance.RazingIcon:SetHide(false);
		instance.RazingIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_BURNING", pCity:GetRazingTurns());
	else
		instance.RazingIcon:SetHide(true);
	end

	-- In Resistance
	if (pCity:IsResistance()) then
		instance.ResistanceIcon:SetHide(false);
		instance.ResistanceIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_RESISTANCE", pCity:GetResistanceTurns());
	else
		instance.ResistanceIcon:SetHide(true);
	end

	-- Puppet Status
	if (pCity:IsPuppet()) then
		instance.PuppetIcon:SetHide(false);

		if (bActivePlayer) then
			instance.PuppetIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_PUPPET");
		else
			instance.PuppetIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_PUPPET_OTHER");
		end
	else
		instance.PuppetIcon:SetHide(true);
	end

	-- Annexed City-States
	instance.CityStateIcon:SetHide(not Players[pCity:GetOriginalOwner()]:IsMinorCiv() or
		not pPlayer:IsAnnexedCityStatesGiveYields());
	if Players[pCity:GetOriginalOwner()]:IsMinorCiv() and pPlayer:IsAnnexedCityStatesGiveYields() then
		local cityOriginalOwner = Players[pCity:GetOriginalOwner()];
		if (cityOriginalOwner ~= nil) then
			local iTrait = cityOriginalOwner:GetMinorCivTrait();
			if (iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_CULTURED) then
				instance.CityStateIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_STATE_CULTURED_TT_ANNEXED");
			elseif (iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_MILITARISTIC) then
				instance.CityStateIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_STATE_MILITARISTIC_NO_UU_TT_ANNEXED");
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
								instance.CityStateIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_STATE_MILITARISTIC_TT_ANNEXED", GameInfo.Units[eUniqueUnit].Description, GameInfo.Technologies[ePrereqTech].Description);
							end
						end
					else
						print("Scripting error - City-State's unique unit not found!");
					end
				end
			elseif (iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_MARITIME) then
				instance.CityStateIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_STATE_MARITIME_TT_ANNEXED");
			elseif (iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_MERCANTILE) then
				instance.CityStateIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_STATE_MERCANTILE_TT_ANNEXED");
			elseif (iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_RELIGIOUS) then
				instance.CityStateIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_STATE_RELIGIOUS_TT_ANNEXED");
			end
		end
	end

	instance.OccupiedIcon:SetHide(pCity:IsNoOccupiedUnhappiness() or not pCity:IsOccupied());
	instance.CityIsMined:SetHide(not pCity:IsMined());

	-- CityHasOffice Status
	instance.CityHasOffice:SetHide(not pCity:HasOffice());
	if Players[pCity:GetOwner()]:GetCorporation() ~= -1 then
		if (pCity == Game.GetCorporationHeadquarters(Players[pCity:GetOwner()]:GetCorporation())) then
			instance.CityHasOffice:SetToolTipString(L("TXT_KEY_CORPORATION_OFFICEHQ_TT",
					GameInfo.Corporations[Players[pCity:GetOwner()]:GetCorporation()].Description) ..
				"[NEWLINE][ICON_BULLET]" ..
				L(GameInfo.Corporations[Players[pCity:GetOwner()]:GetCorporation()].Help) ..
				"[NEWLINE][ICON_BULLET]" ..
				L("TXT_KEY_CORPORATION_OFFICEHQ_TT2", pCity:GetName()) ..
				"[NEWLINE][ICON_BULLET]" .. L("TXT_KEY_CORPORATION_OFFICE_TT2", pCity:GetName()));
		elseif (pCity:HasOffice()) then
			instance.CityHasOffice:SetToolTipString(L("TXT_KEY_CORPORATION_OFFICE_TT",
					GameInfo.Corporations[Players[pCity:GetOwner()]:GetCorporation()].Description) ..
				"[NEWLINE][ICON_BULLET]" ..
				L(GameInfo.Corporations[Players[pCity:GetOwner()]:GetCorporation()]
					.OfficeBonusHelp) ..
				"[NEWLINE][ICON_BULLET]" .. L("TXT_KEY_CORPORATION_OFFICE_TT2", pCity:GetName()));
		else
			instance.CityHasOffice:SetToolTipString("");
		end
	end
	-- CityHasFranchise Status
	if Game.GetNumCorporationsFounded() > 1 then
		instance.CityHasFranchise:SetHide(true);
		local FranchiseTT = "";
		for corporation in GameInfo.Corporations() do
			local iFounder = Game.GetCorporationFounder(corporation.ID);
			if iFounder ~= -1 and pCity:IsFranchised(iFounder) then
				instance.CityHasFranchise:SetHide(false);
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
		instance.CityHasFranchise:SetToolTipString(FranchiseTT);
	else
		instance.CityHasFranchise:SetHide(true);
	end

	instance.CityCanAirlift:SetHide(not pCity:CanAirlift());
	instance.CityCanSealift:SetHide(not pCity:CanSealift());
	instance.CityHasObstacle:SetHide(not pCity:IsBorderObstacleLand());

	if (bActiveTeam) then
		-- CityIsAutomated Status
		if (pCity:IsProductionAutomated() and Players[pCity:GetOriginalOwner()]:IsHuman() and not pCity:IsPuppet()) then
			instance.CityIsAutomated:SetHide(false);
		else
			instance.CityIsAutomated:SetHide(true);
		end

		-- Happiness Status
		local delta = pCity:getHappinessDelta();
		if (delta < 0) then
			instance.UnhappyIcon:SetHide(false);
			local delta = pCity:getHappinessDelta() * -1;
			instance.UnhappyIcon:SetToolTipString(L("TXT_KEY_CITY_UNHAPPY", delta) .. "[NEWLINE][NEWLINE]" .. pCity:GetCityUnhappinessBreakdown(false, true));
		else
			instance.UnhappyIcon:SetHide(true);
		end
	end
	if (bHasSpy) then
		instance.SpyIcon:SetHide(false);
		if (bActivePlayer) then
			instance.SpyIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_SPY_YOUR_CITY_TT", strSpyRank, strSpyName, pCity:GetName(), strSpyRank, strSpyName);
		elseif (bMinor) then
			instance.SpyIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_SPY_CITY_STATE_TT", strSpyRank, strSpyName, pCity:GetName(), strSpyRank, strSpyName);
		else
			instance.SpyIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_SPY_OTHER_CIV_TT", strSpyRank, strSpyName, pCity:GetName(), strSpyRank, strSpyName, strSpyRank, strSpyName);
		end
	else
		instance.SpyIcon:SetHide(true);
	end

	if (bHasDiplomat) then
		instance.DiplomatIcon:SetHide(false);
		instance.DiplomatIcon:LocalizeAndSetToolTip("TXT_KEY_CITY_DIPLOMAT_OTHER_CIV_TT", strSpyRank, strSpyName, pCity:GetName(), strSpyRank, strSpyName, strSpyRank, strSpyName);
	else
		instance.DiplomatIcon:SetHide(true);
	end

	-- Update strength
	local cityStrengthStr = math.floor(pCity:GetStrengthValue() / 100);

	local iCityDamage = pCity:GetDamage();
	local iCityMaxHP = pCity:GetMaxHitPoints();
	local iCityCurrentHP = iCityMaxHP - iCityDamage;
	local ttText = L("TXT_KEY_UPANEL_SET_HITPOINTS_TT", iCityCurrentHP, iCityMaxHP) .. "[NEWLINE]" .. L("TXT_KEY_CITYVIEW_CITY_COMB_STRENGTH_TT");
	local iRange, iIndirect = pCity:GetBombardRange();
	if (iIndirect == 1) then
		ttText = ttText ..
			": [ICON_RANGE_STRENGTH] " ..
			pCity:GetStrengthValue(true) / 100 ..
			"[NEWLINE][ICON_RANGE_STRENGTH] " ..
			L("TXT_KEY_COMBAT_RANGE_HEADING3_TITLE") ..
			": " ..
			iRange ..
			"[NEWLINE][COLOR_POSITIVE_TEXT]" .. L("TXT_KEY_PROMOTION_INDIRECT_FIRE") .. "[ENDCOLOR]";
	else
		ttText = ttText ..
			": [ICON_RANGE_STRENGTH] " ..
			pCity:GetStrengthValue(true) / 100 ..
			"[NEWLINE][ICON_RANGE_STRENGTH] " ..
			L("TXT_KEY_COMBAT_RANGE_HEADING3_TITLE") ..
			": " ..
			iRange ..
			"[NEWLINE][COLOR_NEGATIVE_TEXT]" .. L("TXT_KEY_PROMOTION_INDIRECT_FIRE") .. "[ENDCOLOR]";
	end
	instance.CityStrength:SetToolTipString(ttText);
	instance.CityStrength:SetText(cityStrengthStr);

	UpdateRangeStrikeButton(banner);

	-- Update population
	local cityPopulation = math.floor(pCity:GetPopulation());
	instance.CityPopulation:SetText(cityPopulation);

	-- Update Growth Time
	if (instance.CityGrowth) then
		local cityGrowth = pCity:GetFoodTurnsLeft();

		if (pCity:GetYieldRateTimes100(YieldTypes.YIELD_FOOD) == 0) then
			cityGrowth = "-";
			instance.CityBannerRightBackground:LocalizeAndSetToolTip("TXT_KEY_CITY_STOPPED_GROWING_TT", localizedCityName, cityPopulation);
		elseif pCity:GetYieldRateTimes100(YieldTypes.YIELD_FOOD) < 0 then
			cityGrowth = "[COLOR_WARNING_TEXT]-[ENDCOLOR]";
			instance.CityBannerRightBackground:LocalizeAndSetToolTip("TXT_KEY_CITY_STARVING_TT", localizedCityName);
		else
			instance.CityBannerRightBackground:LocalizeAndSetToolTip("TXT_KEY_CITY_WILL_GROW_TT", localizedCityName, cityPopulation, cityPopulation + 1, cityGrowth);
		end

		instance.CityGrowth:SetText(cityGrowth);
	end

	-- Update Production Time
	if (instance.BuildGrowth) then
		local buildGrowth = "-";

		if (pCity:IsProduction() and not pCity:IsProductionProcess()) then
			if (pCity:GetYieldRateTimes100(YieldTypes.YIELD_PRODUCTION) > 0) then
				buildGrowth = pCity:GetProductionTurnsLeft();
			end
		end

		instance.BuildGrowth:SetText(buildGrowth);
	end

	-- Update Growth Meter
	if (instance.GrowthBar) then
		local iCurrentFood = pCity:GetFood();
		local iFoodNeeded = pCity:GrowthThreshold();
		local iFoodPerTurn = pCity:FoodDifference();
		local iCurrentFoodPlusThisTurn = iCurrentFood + iFoodPerTurn;

		local fGrowthProgressPercent = iCurrentFood / iFoodNeeded;
		local fGrowthProgressPlusThisTurnPercent = iCurrentFoodPlusThisTurn / iFoodNeeded;
		if (fGrowthProgressPlusThisTurnPercent > 1) then
			fGrowthProgressPlusThisTurnPercent = 1
		end

		instance.GrowthBar:SetPercent(fGrowthProgressPercent);
		instance.GrowthBarShadow:SetPercent(fGrowthProgressPlusThisTurnPercent);
	end

	-- Update Production Meter
	if (instance.ProductionBar) then
		local iCurrentProduction = pCity:GetProductionTimes100() / 100;
		local iProductionNeeded = pCity:GetProductionNeeded();
		local iProductionPerTurn = pCity:GetYieldRateTimes100(YieldTypes.YIELD_PRODUCTION) / 100;
		local iCurrentProductionPlusThisTurn = iCurrentProduction + iProductionPerTurn;

		local fProductionProgressPercent = iCurrentProduction / iProductionNeeded;
		local fProductionProgressPlusThisTurnPercent = iCurrentProductionPlusThisTurn / iProductionNeeded;
		if (fProductionProgressPlusThisTurnPercent > 1) then
			fProductionProgressPlusThisTurnPercent = 1
		end

		instance.ProductionBar:SetPercent(fProductionProgressPercent);
		instance.ProductionBarShadow:SetPercent(fProductionProgressPlusThisTurnPercent);
	end

	-- Update Production Name
	local cityProductionName = pCity:GetProductionNameKey();
	if cityProductionName == nil or string.len(cityProductionName) == 0 then
		cityProductionName = "TXT_KEY_PRODUCTION_NO_PRODUCTION";
	end
	if (instance.CityProductionName) then
		convertedKey = L(cityProductionName);
		instance.CityProductionName:SetText(convertedKey);
		if (instance.CityBannerLeftBackground) then
			if (pCity:IsProductionProcess()) then
				local cityProductionProcess = pCity:GetProductionProcess();
				local tooltipString = GetHelpTextForProcess(cityProductionProcess);
				instance.CityBannerLeftBackground:SetToolTipString(tooltipString);
			else
				if cityProductionName == "TXT_KEY_PRODUCTION_NO_PRODUCTION" then
					instance.CityBannerLeftBackground:SetToolTipString(L("TXT_KEY_CITY_NOT_PRODUCING", localizedCityName));
				else
					local productionTurnsLeft = pCity:GetProductionTurnsLeft();
					local tooltipString;
					if productionTurnsLeft > 99 then
						tooltipString = L("TXT_KEY_CITY_CURRENTLY_PRODUCING_99PLUS_TT", localizedCityName, cityProductionName);
					else
						tooltipString = L("TXT_KEY_CITY_CURRENTLY_PRODUCING_TT", localizedCityName, cityProductionName, productionTurnsLeft);
					end
					instance.CityBannerLeftBackground:SetToolTipString(tooltipString);
				end
			end
		end
	end

	-- Update Production icon
	if instance.CityBannerProductionImage then
		local unitProduction = pCity:GetProductionUnit();
		local buildingProduction = pCity:GetProductionBuilding();
		local projectProduction = pCity:GetProductionProject();
		local processProduction = pCity:GetProductionProcess();

		if unitProduction ~= -1 then
			local portraitOffset, portraitAtlas = UI.GetUnitPortraitIcon(unitProduction, pCity:GetOwner());
			if IconHookupOrDefault(portraitOffset, 45, portraitAtlas, instance.CityBannerProductionImage) then
				instance.CityBannerProductionImage:SetHide(false);
			else
				instance.CityBannerProductionImage:SetHide(true);
			end
		elseif buildingProduction ~= -1 then
			local thisBuildingInfo = GameInfo.Buildings[buildingProduction];
			if IconHookupOrDefault(thisBuildingInfo.PortraitIndex, 45, thisBuildingInfo.IconAtlas, instance.CityBannerProductionImage) then
				instance.CityBannerProductionImage:SetHide(false);
			else
				instance.CityBannerProductionImage:SetHide(true);
			end
		elseif projectProduction ~= -1 then
			local thisProjectInfo = GameInfo.Projects[projectProduction];
			if IconHookupOrDefault(thisProjectInfo.PortraitIndex, 45, thisProjectInfo.IconAtlas, instance.CityBannerProductionImage) then
				instance.CityBannerProductionImage:SetHide(false);
			else
				instance.CityBannerProductionImage:SetHide(true);
			end
		elseif processProduction ~= -1 then
			local thisProcessInfo = GameInfo.Processes[processProduction];
			if IconHookupOrDefault(thisProcessInfo.PortraitIndex, 45, thisProcessInfo.IconAtlas, instance.CityBannerProductionImage) then
				instance.CityBannerProductionImage:SetHide(false);
			else
				instance.CityBannerProductionImage:SetHide(true);
			end
		else -- really should have an error texture
			instance.CityBannerProductionImage:SetHide(true);
		end

		if bActivePlayer then
			instance.CityBannerProductionButton:RegisterCallback(Mouse.eLClick, OpenProductionPopup);
			instance.CityBannerProductionButton:SetVoid1(pCity:GetID());
			Enable(instance.BannerButton);
		end
	end

	-- This is another player's banner instance
	if (instance.MinorIndicator and instance.StatusIcon) then
		instance.StatusIcon:SetColor(textColor);
		local civType = pPlayer:GetCivilizationType();
		local civInfo = GameInfo.Civilizations[civType];

		if (bMinor) then
			SetUpMinorMeter(eActivePlayer, banner.PlayerID, instance, textColor);

			-- minor trait icon
			instance.StatusIcon:SetTexture(GameInfo.MinorCivTraits
				[GameInfo.MinorCivilizations[pPlayer:GetMinorCivType()].MinorCivTrait].TraitIcon);
			instance.StatusIcon:SetTextureOffsetVal(0, 0);
		else
			IconHookupOrDefault(civInfo.PortraitIndex, 32, civInfo.AlphaIconAtlas, instance.StatusIcon);
			instance.StatusIcon:SetOffsetX(0);
			instance.StatusIconBG:SetHide(true);
			instance.StatusMeterFrame:SetHide(true);
		end

		local pOriginalOwner = Players[pCity:GetOriginalOwner()];
		if (pOriginalOwner:IsMinorCiv()) then
			local _, originalColor = pOriginalOwner:GetPlayerColors();
			originalColor.w = 1;

			civType = pOriginalOwner:GetCivilizationType();
			civInfo = GameInfo.Civilizations[civType];
			IconHookupOrDefault(civInfo.PortraitIndex, 32, civInfo.AlphaIconAtlas, instance.MinorIndicator);

			instance.MinorIndicator:SetColor(originalColor);
			instance.MinorIndicator:SetHide(false);
		else
			instance.MinorIndicator:SetHide(true);
		end

		Refresh(instance.NameStack);
	end

	-- Refresh the damage bar too
	RefreshCityDamage(banner, iCityDamage, iCityMaxHP);

	Refresh(instance.NameStack, instance.IconsStack);
end

--- Get a new instance from the respective instance manager depending on the active state.<br>
--- `banner.IsActiveTeam` must be finalized before calling this.
--- @param banner CityBanner
--- @return ControlInstance
local function GetNewBannerInstance(banner)
	local instanceManager = banner.IsActiveTeam and teamInstanceManager or otherInstanceManager;
	local instance = instanceManager:Acquire(Controls.CityBanners);
	local vWorld = HexToWorld(banner.Hex);

	instance.BannerButton:SetVoid1(banner.PlayerID);
	instance.BannerButton:SetVoid2(banner.CityID);

	if banner.IsActiveTeam then
		instance.CityRangeStrikeButton:SetVoid1(banner.PlayerID);
		instance.CityRangeStrikeButton:SetVoid2(banner.CityID);

		local svInstance = svRangeStrikeInstanceManager:Acquire(Controls.StrategicViewStrikeButtons);
		svInstance.Anchor:SetWorldPosition(vWorld);
		svInstance.CityRangeStrikeButton:SetVoid1(banner.PlayerID);
		svInstance.CityRangeStrikeButton:SetVoid2(banner.CityID);
		banner.SVInstance = svInstance;
	end

	instance.Anchor:SetWorldPosition(VecAdd(vWorld, WORLD_POSITION_OFFSET));

	return instance;
end

--- Helper to set the visibility of a banner and refresh it if it was previously hidden
--- @param banner CityBanner
--- @param bVisible boolean
local function SetBannerVisibility(banner, bVisible)
	banner.Instance.Anchor:SetHide(not bVisible);

	if bVisible and banner.Instance.Anchor:IsHidden() then
		RefreshCityBanner(banner);
	end
end

--- Check the banner to see if it needs to be rebuilt (active player change)
--- @param banner CityBanner
local function CheckCityBannerRebuild(banner)
	local bWasActive = banner.IsActiveTeam;
	banner.IsActiveTeam = ShouldBannerBeActiveTeamVersion(banner);

	-- Nothing to do here
	if bWasActive == banner.IsActiveTeam then
		return;
	end

	local bWasHidden = banner.Instance.Anchor:IsHidden();
	-- print("Rebuilding banner for player: " .. tostring(banner.playerID) .. " city: " .. tostring(banner.cityID) .. " from active = " .. tostring(banner.IsActiveType) .. " to active = " .. tostring(bWantActive));

	if banner.IsActiveTeam then
		-- Release the old one
		otherInstanceManager:Recycle(banner.Instance);
	else
		-- Release the old one
		teamInstanceManager:Recycle(banner.Instance);

		if banner.SVInstance then
			svRangeStrikeInstanceManager:Recycle(banner.SVInstance);
			banner.SVInstance = nil;
		end
	end

	-- Create the new banner
	banner.Instance = GetNewBannerInstance(banner);

	-- Keep the hidden state.
	-- RefreshCityBanner() is called inside the function if the banner is shown.
	SetBannerVisibility(banner, not bWasHidden);
end

--- City is destroyed or captured, remove the banner
--- @param ePlayer PlayerId
--- @param iCityID CityId
local function RemoveBanner(_, ePlayer, iCityID)
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

Events.SerialEventCityCaptured.Add(RemoveBanner);
Events.SerialEventCityDestroyed.Add(RemoveBanner);

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
			UpdateRangeStrikeButton(banner);
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

	local pPlot = Map.GetPlot(ToGridFromHex(vHex.x, vHex.y));
	local pCity = pPlot and pPlot:GetPlotCity();
	if not pCity then
		return;
	end

	local banner = g_cityBanners[pCity:GetOwner()][pCity:GetID()];
	if not banner then
		return;
	end

	SetBannerVisibility(banner, eFow ~= FOWStates.UNEXPLORED);
end);

Events.InitCityRangeStrike.Add(function (ePlayer, iCityID)
	assert(ePlayer == Game.GetActivePlayer(), "City range strike initialized for non-active player");

	local pPlayer = Players[ePlayer];
	local pCity = pPlayer:GetCityByID(iCityID);

	UI.SelectCity(pCity);
	UI.SetInterfaceMode(InterfaceModeTypes.INTERFACEMODE_CITY_RANGE_ATTACK);
end);

Events.InterfaceModeChanged.Add(function (_, eNewInterface)
	local bDisabled = (eNewInterface ~= InterfaceModeTypes.INTERFACEMODE_SELECTION);
	ForEachCityBanner(function (banner)
		banner.Instance.BannerButton:SetDisabled(bDisabled);
		banner.Instance.BannerButton:EnableToolTip(not bDisabled);
	end);
end);

Events.StrategicViewStateChanged.Add(function (bStrategicView, bCityBanners)
	local bShowBanners = bCityBanners or not bStrategicView;
	Controls.CityBanners:SetHide(not bShowBanners);
	Controls.StrategicViewStrikeButtons:SetHide(bShowBanners);
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
		UpdateRangeStrikeButton(banner);
	end
end);

--- Initialize a city banner when a city is created. This is called for all cities, including those that are not on the active team.
--- @param vHex Vector2
--- @param ePlayer PlayerId
--- @param iCityID CityId
--- @param eFow FOWStates
local function InitCityBanner(vHex, ePlayer, iCityID, _, _, _, _, _, eFow)
	if g_cityBanners[ePlayer][iCityID] then
		return;
	end

	local banner = {
		PlayerID = ePlayer,
		CityID = iCityID,
		Hex = vHex,
	};

	banner.IsActiveTeam = ShouldBannerBeActiveTeamVersion(banner);
	banner.Instance = GetNewBannerInstance(banner);

	g_cityBanners[ePlayer][iCityID] = banner;

	-- Hide the banner if the city plot has not been explored.
	-- RefreshCityBanner() is called inside the function if the banner is shown.
	SetBannerVisibility(banner, eFow ~= FOWStates.UNEXPLORED);
end

-- Initialize banner on city creation
Events.SerialEventCityCreated.Add(InitCityBanner);

-- Initialize all city banners on hot load
if ContextPtr:IsHotLoad() then
	for ePlayer, pPlayer in pairs(Players) do
		if pPlayer:IsAlive() then
			for pCity in pPlayer:Cities() do
				InitCityBanner(ToHexFromGrid(Vector2(pCity:GetX(), pCity:GetY())), ePlayer, pCity:GetID(), nil, nil, nil, nil, nil, pCity:Plot():GetActiveFogOfWarMode());
			end
		end
	end
end
