-------------------------------------------
-- Consistency
-------------------------------------------

-- These are empty strings instead of null in vanilla. Probably should follow.
-- And no, modifying columns (and default values) isn't a thing in SQLite.
UPDATE ArtDefine_UnitInfos SET UnitFlagAtlas = '' WHERE UnitFlagAtlas IS NULL;
UPDATE ArtDefine_UnitInfos SET IconAtlas = '' WHERE IconAtlas IS NULL;
UPDATE ArtDefine_UnitMemberInfos SET Domain = '' WHERE Domain IS NULL;
UPDATE ArtDefine_UnitMemberCombatWeapons SET ID = '' WHERE ID IS NULL;
UPDATE ArtDefine_UnitMemberCombatWeapons SET HitEffect = '' WHERE HitEffect IS NULL;
UPDATE ArtDefine_UnitMemberCombatWeapons SET WeaponTypeSoundOverrideTag = '' WHERE WeaponTypeSoundOverrideTag IS NULL;

-- Similarly, this seems to be always non-null.
UPDATE ArtDefine_UnitMemberCombats SET HasRefaceAfterCombat = 0 WHERE HasRefaceAfterCombat IS NULL;

-------------------------------------------
-- Unit formations
-------------------------------------------
DELETE FROM ArtDefine_UnitInfoMemberInfos WHERE UnitInfoType IN (
	'ART_DEF_UNIT_U_GERMAN_LANDSKNECHT',
	'ART_DEF_UNIT_U_SPANISH_CONQUISTADOR'
);

INSERT INTO ArtDefine_UnitInfoMemberInfos
	(UnitInfoType, UnitMemberInfoType, NumMembers)
VALUES
	('ART_DEF_UNIT_U_GERMAN_LANDSKNECHT', 'ART_DEF_UNIT_MEMBER_U_GERMAN_LANDSKNECHT_A', 2),
	('ART_DEF_UNIT_U_GERMAN_LANDSKNECHT', 'ART_DEF_UNIT_MEMBER_U_GERMAN_LANDSKNECHT_B', 3),
	('ART_DEF_UNIT_U_GERMAN_LANDSKNECHT', 'ART_DEF_UNIT_MEMBER_U_GERMAN_LANDSKNECHT_2', 2),
	('ART_DEF_UNIT_U_GERMAN_LANDSKNECHT', 'ART_DEF_UNIT_MEMBER_U_GERMAN_LANDSKNECHT_3', 7),
	('ART_DEF_UNIT_VP_SLINGER', 'ART_DEF_UNIT_MEMBER_VP_SLINGER', 12),
	('ART_DEF_UNIT_FIELD_GUN', 'ART_DEF_UNIT_MEMBER_FIELD_GUN', 3),
	('ART_DEF_UNIT_HEAVY_SKIRMISH', 'ART_DEF_UNIT_MEMBER_HEAVY_SKIRMISH', 5),
	('ART_DEF_UNIT_CUIRASSIER', 'ART_DEF_UNIT_MEMBER_CUIRASSIER', 5),
	('ART_DEF_UNIT_ARMORED_CAR', 'ART_DEF_UNIT_MEMBER_ARMORED_CAR', 2),
	('ART_DEF_UNIT_EXPLORER_CBP', 'ART_DEF_UNIT_MEMBER_BANDEIRANTE_1', 1),
	('ART_DEF_UNIT_EXPLORER_CBP', 'ART_DEF_UNIT_MEMBER_BANDEIRANTE_2', 1),
	('ART_DEF_UNIT_EXPLORER_CBP', 'ART_DEF_UNIT_MEMBER_BANDEIRANTE_3', 1),
	('ART_DEF_UNIT_EXPLORER_CBP', 'ART_DEF_UNIT_MEMBER_BANDEIRANTE_1', 1),
	('ART_DEF_UNIT_EXPLORER_CBP', 'ART_DEF_UNIT_MEMBER_BANDEIRANTE_2', 1),
	('ART_DEF_UNIT_EXPLORER_CBP', 'ART_DEF_UNIT_MEMBER_BANDEIRANTE_3', 1),
	('ART_DEF_UNIT_BANDEIRANTES', 'ART_DEF_UNIT_MEMBER_BANDEIRANTE_1', 1),
	('ART_DEF_UNIT_BANDEIRANTES', 'ART_DEF_UNIT_MEMBER_BANDEIRANTE_2', 1),
	('ART_DEF_UNIT_BANDEIRANTES', 'ART_DEF_UNIT_MEMBER_BANDEIRANTE_3', 1),
	('ART_DEF_UNIT_BANDEIRANTES', 'ART_DEF_UNIT_MEMBER_BANDEIRANTE_FLAGBEARER', 1),
	('ART_DEF_UNIT_U_SPANISH_CONQUISTADOR', 'ART_DEF_UNIT_MEMBER_U_SPANISH_CONQUISTADOR', 2),
	('ART_DEF_UNIT_U_SPANISH_CONQUISTADOR', 'ART_DEF_UNIT_MEMBER_SCOUT', 1),
	('ART_DEF_UNIT_U_SPANISH_CONQUISTADOR', 'ART_DEF_UNIT_MEMBER_U_SPANISH_TERCIO_PIQUERO', 1),
	('ART_DEF_UNIT_U_SPANISH_CONQUISTADOR', 'ART_DEF_UNIT_MEMBER_U_SPANISH_CONQUISTADOR', 1),
	('ART_DEF_UNIT_U_SPANISH_CONQUISTADOR', 'ART_DEF_UNIT_MEMBER_U_SPANISH_TERCIO_PIQUERO', 2),
	('ART_DEF_UNIT_COMMANDO', 'ART_DEF_UNIT_MEMBER_BOER_COMMANDO', 2),
	('ART_DEF_UNIT_COMMANDO', 'ART_DEF_UNIT_MEMBER_BOER_COMMANDO_2', 3),
	('ART_DEF_UNIT_COMMANDO', 'ART_DEF_UNIT_MEMBER_BOER_COMMANDO', 1),
	('ART_DEF_UNIT_COMMANDO', 'ART_DEF_UNIT_MEMBER_BOER_COMMANDO_2', 2),
	('ART_DEF_UNIT_COMMANDO', 'ART_DEF_UNIT_MEMBER_BOER_COMMANDO', 2),
	('ART_DEF_UNIT_COMMANDO', 'ART_DEF_UNIT_MEMBER_BOER_COMMANDO_2', 1),
	('ART_DEF_UNIT_VP_GALLEY', 'ART_DEF_UNIT_MEMBER_VP_GALLEY', 1),
	('ART_DEF_UNIT_CORVETTE', 'ART_DEF_UNIT_MEMBER_CORVETTE', 1),
	('ART_DEF_UNIT_EARLY_DESTROYER', 'ART_DEF_UNIT_MEMBER_EARLY_DESTROYER', 1),
	('ART_DEF_UNIT_MISSILE_DESTROYER', 'ART_DEF_UNIT_MEMBER_MISSILE_DESTROYER', 1),
	('ART_DEF_UNIT_VP_LIBURNA', 'ART_DEF_UNIT_MEMBER_VP_LIBURNA', 1),
	('ART_DEF_UNIT_CRUISER', 'ART_DEF_UNIT_MEMBER_CRUISER', 1),
	('ART_DEF_UNIT_DREADNOUGHT', 'ART_DEF_UNIT_MEMBER_DREADNOUGHT', 1),
	('ART_DEF_UNIT_ATTACK_SUBMARINE', 'ART_DEF_UNIT_MEMBER_ATTACK_SUBMARINE', 1),
	('ART_DEF_UNIT_SUPERCARRIER', 'ART_DEF_UNIT_MEMBER_SUPERCARRIER', 1),
	('ART_DEF_UNIT_ROCKET_MISSILE', 'ART_DEF_UNIT_MEMBER_ROCKET_MISSILE', 1),
	('ART_DEF_UNIT_PIONEER', 'ART_DEF_UNIT_MEMBER_EUROFEMALE18', 1),
	('ART_DEF_UNIT_PIONEER', 'ART_DEF_UNIT_MEMBER_EUROMALE20', 1),
	('ART_DEF_UNIT_PIONEER', 'ART_DEF_UNIT_MEMBER_EUROFEMALE18', 1),
	('ART_DEF_UNIT_PIONEER', 'ART_DEF_UNIT_MEMBER_EURODONKEY', 1),
	('ART_DEF_UNIT_PIONEER', 'ART_DEF_UNIT_MEMBER_GREATMERCHANT_EARLY_CAMEL_V1', 1),
	('ART_DEF_UNIT_PIONEER', 'ART_DEF_UNIT_MEMBER_CARAVAN_F1', 1),
	('ART_DEF_UNIT_PIONEER', 'ART_DEF_UNIT_MEMBER_CARAVAN_F2', 1),
	('ART_DEF_UNIT_PIONEER', 'ART_DEF_UNIT_MEMBER_GREATMERCHANT_EARLY_CAMEL_V2', 1),
	('ART_DEF_UNIT_COLONIST', 'ART_DEF_UNIT_MEMBER_COLONIST2', 1),
	('ART_DEF_UNIT_COLONIST', 'ART_DEF_UNIT_MEMBER_COLONIST3', 1),
	('ART_DEF_UNIT_COLONIST', 'ART_DEF_UNIT_MEMBER_COLONIST4', 1),
	('ART_DEF_UNIT_EMISSARY', 'ART_DEF_UNIT_MEMBER_SETTLERS_ASIAN_F2', 1),
	('ART_DEF_UNIT_ENVOY', 'ART_DEF_UNIT_MEMBER_MISSIONARY_01', 1),
	('ART_DEF_UNIT_DIPLOMAT', 'ART_DEF_UNIT_MEMBER_EUROFEMALE18', 1),
	('ART_DEF_UNIT_AMBASSADOR', 'ART_DEF_UNIT_MEMBER_ARCHAEOLOGIST', 1),
	('ART_DEF_UNIT_GREAT_DIPLOMAT', 'ART_DEF_UNIT_MEMBER_AFRIMALE3', 1),
	('ART_DEF_UNIT_GREAT_DIPLOMAT_RENAISSANCE', 'ART_DEF_UNIT_MEMBER_EUROFEMALE18', 1),
	('ART_DEF_UNIT_GREAT_DIPLOMAT_MODERN', 'ART_DEF_UNIT_MEMBER_GREAT_ARTIST_F2', 1),
	('ART_DEF_UNIT_FCOMPANY', 'ART_DEF_UNIT_MEMBER_FCOMPANY_4', 3),
	('ART_DEF_UNIT_FCOMPANY', 'ART_DEF_UNIT_MEMBER_FCOMPANY_1', 1),
	('ART_DEF_UNIT_FCOMPANY', 'ART_DEF_UNIT_MEMBER_FCOMPANY_2', 1),
	('ART_DEF_UNIT_FCOMPANY', 'ART_DEF_UNIT_MEMBER_FCOMPANY_4', 2),
	('ART_DEF_UNIT_FCOMPANY', 'ART_DEF_UNIT_MEMBER_FCOMPANY_1', 1),
	('ART_DEF_UNIT_FCOMPANY', 'ART_DEF_UNIT_MEMBER_FCOMPANY_3', 2),
	('ART_DEF_UNIT_FCOMPANY', 'ART_DEF_UNIT_MEMBER_FCOMPANY_2', 2),
	('ART_DEF_UNIT_MERC', 'ART_DEF_UNIT_MERC_GUERILLA', 14);

-------------------------------------------
-- Other changes
-------------------------------------------
UPDATE ArtDefine_UnitInfos SET Formation = 'HonorableGunpowder' WHERE Type = 'ART_DEF_UNIT_U_GERMAN_LANDSKNECHT';

UPDATE ArtDefine_StrategicView SET Asset = 'svmountedxbow.dds' WHERE StrategicViewType = 'ART_DEF_UNIT_U_MONGOLIAN_KESHIK';
UPDATE ArtDefine_StrategicView SET Asset = 'tercio_flag2.dds' WHERE StrategicViewType = 'ART_DEF_UNIT_U_SPANISH_TERCIO';

UPDATE ArtDefine_UnitMemberCombats
SET AttackAltitude = 90.0, MoveRate = 4.8
WHERE UnitMemberType = 'ART_DEF_UNIT_MEMBER_GUIDEDMISSILE';

UPDATE ArtDefine_UnitMemberCombatWeapons
SET WeaponTypeSoundOverrideTag = 'EXPLOSION1TON'
WHERE UnitMemberType = 'ART_DEF_UNIT_MEMBER_GUIDEDMISSILE';

UPDATE ArtDefine_UnitMemberInfos SET Scale = 0.094 WHERE Type = 'ART_DEF_UNIT_MEMBER_IRONCLAD';
UPDATE ArtDefine_UnitMemberInfos SET Model = 'Z_Class.fxsxml', Scale = 0.109 WHERE Type = 'ART_DEF_UNIT_MEMBER_DESTROYER';
UPDATE ArtDefine_UnitMemberInfos SET Scale = 0.088 WHERE Type = 'ART_DEF_UNIT_MEMBER_BATTLESHIP';
UPDATE ArtDefine_UnitMemberInfos SET Scale = 0.1 WHERE Type = 'ART_DEF_UNIT_MEMBER_MISSILECRUISER';
UPDATE ArtDefine_UnitMemberInfos SET Scale = 0.14 WHERE Type = 'ART_DEF_UNIT_MEMBER_SUBMARINE';
UPDATE ArtDefine_UnitMemberInfos SET Scale = 0.115 WHERE Type = 'ART_DEF_UNIT_MEMBER_NUCLEARSUBMARINE';
UPDATE ArtDefine_UnitMemberInfos SET Scale = 0.07 WHERE Type = 'ART_DEF_UNIT_MEMBER_CARRIER';