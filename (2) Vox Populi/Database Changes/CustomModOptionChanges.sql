UPDATE CustomModOptions SET Value = 1 WHERE Name = 'BALANCE_VP';

UPDATE CustomModOptions SET Value = 1 WHERE Name = 'ALTERNATE_SIAM_TRAIT';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_ENCAMPMENTS_SPAWN_ON_VISIBLE_TILES';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_PERMANENT_VOTE_COMMITMENTS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'RIVER_CITY_CONNECTIONS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_MINORS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_POP_REQ_BUILDINGS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_SETTLERS_CONSUME_POP';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_WONDERS_VARIABLE_REWARD' AND EXISTS (SELECT 1 FROM Community WHERE Type = 'COMMUNITY_CORE_BALANCE_WONDER_CONSOLATION_TWEAK' AND Value <> 0);

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_BELIEFS_RESOURCE';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_AFRAID_ANNEX';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_BUILDING_INSTANT_YIELD';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_BELIEFS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_FOLLOWER_POP_WONDER';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_POLICIES';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_SPIES';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_BARBARIAN_THEFT';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_PURCHASE_COST_INCREASE';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_EMBARK_CITY_NO_COST';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_MINOR_PROTECTION';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_IDEOLOGY_START';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'TRADE_ROUTE_SCALING';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'GLOBAL_CS_UPGRADES';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'GLOBAL_CS_GIFTS_LOCAL_XP';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'GLOBAL_TRULY_FREE_GP';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'GLOBAL_CITY_FOREST_BONUS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_WONDER_COST_INCREASE';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_MINOR_CIV_GIFT';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_SETTLER_ADVANCED';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_MILITARY_PROMOTION_ADVANCED';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_UNIT_CREATION_DAMAGED';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'ADJACENT_BLOCKADE';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_LUXURIES_TRAIT';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_SPIES_ADVANCED';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_RESOURCE_FLAVORS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_RESOURCE_MONOPOLIES';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_RESOURCE_MONOPOLIES_STRATEGIC';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'GLOBAL_SEPARATE_GP_COUNTERS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'GLOBAL_PASSABLE_FORTS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_BUILDING_INVESTMENTS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_MAYA_CHANGE';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_PORTUGAL_CHANGE';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_MINOR_VARIABLE_BULLYING';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_YIELD_SCALE_ERA';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_NEW_GP_ATTRIBUTES';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_MILITARY_RESISTANCE';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_MILITARY_RESOURCES';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_PANTHEON_RESET_FOUND';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_MINOR_PTP_MINIMUM_VALUE';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_BUILDING_RESOURCE_MAINTENANCE';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_RETROACTIVE_PROMOS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_VICTORY_GAME_CHANGES';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_UNIQUE_BELIEFS_ONLY_FOR_CIV';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_DEFENSIVE_PACTS_AGGRESSION_ONLY';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_SCALING_TRADE_DISTANCE';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_SCALING_XP';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_HALF_XP_PURCHASE';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_QUEST_CHANGES';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_PUPPET_CHANGES';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_CITY_DEFENSE_SWITCH';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_ARCHAEOLOGY_FROM_GP';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'GLOBAL_PARATROOPS_AA_DAMAGE';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_BOMBARD_RANGE_BUILDINGS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_TOURISM_HUNDREDS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_FLIPPED_TOURISM_MODIFIER_OPEN_BORDERS';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_RANGED_ATTACK_PENALTY';

UPDATE CustomModOptions
SET Value = 1
WHERE Name = 'BALANCE_CORE_INQUISITOR_TWEAKS';

UPDATE CustomModOptions SET Value = 1 WHERE Name = 'GLOBAL_CS_GIFTS';
UPDATE CustomModOptions SET Value = 1 WHERE Name = 'GLOBAL_CS_GIFT_SHIPS';

UPDATE CustomModOptions SET Value = 1 WHERE Name = 'POLICIES_UNIT_CLASS_REPLACEMENTS';

UPDATE CustomModOptions SET Value = 1 WHERE Name = 'BALANCE_CORE_GOODY_RECON_ONLY';

-- No longer needed now that Helicopter Gunship doesn't embark anywhere
UPDATE CustomModOptions SET Value = 0 WHERE Name = 'PROMOTIONS_DEEP_WATER_EMBARKATION';

UPDATE CustomModOptions SET Value = 1 WHERE Name = 'CORE_RESILIENT_PANTHEONS';
