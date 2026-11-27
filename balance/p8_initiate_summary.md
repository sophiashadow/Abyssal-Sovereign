# M7 soak summary (192 runs)

## Policies

| policy | n | win | mean depth | mean level | mean turns |
|---|---|---|---|---|---|
| baseline | 64 | 76.6% | 6.17 | 11.3 | 720 |
| explorer | 64 | 76.6% | 6.31 | 21.3 | 8982 |
| specialist | 64 | 90.6% | 6.63 | 12.2 | 674 |

## Calling x policy (win rate, n)

| calling | baseline | explorer | specialist |
|---|---|---|---|
| assassin | 88% (8) | 62% (8) | 100% (8) |
| fallen_knight | 88% (8) | 88% (8) | 100% (8) |
| false_light_alchemist | 100% (8) | 100% (8) | 100% (8) |
| occultist | 75% (8) | 25% (8) | 75% (8) |
| ophite_binder | 75% (8) | 88% (8) | 75% (8) |
| preliator_warden | 88% (8) | 100% (8) | 100% (8) |
| rite_weaver | 38% (8) | 88% (8) | 100% (8) |
| tithe_marksman | 62% (8) | 62% (8) | 75% (8) |

## Deaths (non-random)

- d2 The Vault Enumerator: 7
- d3 Choir Cantor Prime: 2
- d2 armed audit clerk: 2
- d3 brass chorister: 1
- d6 Lord Decreetory Octavius: 1
- d1 tangled rat-pack: 1
- d4 ossuary wight: 1
- d3 penance flagellant: 1
- d2 bleeding: 1
- d5 Iron Auditor: 1
- d1 Back-Court Matriarch: 1

Classification: {"attrition":5,"false_light_window":1,"healing_unused_or_too_slow":9,"no_healing_available":3,"underlevelled":1}

Deaths by depth: {"d1":2,"d2":10,"d3":4,"d4":1,"d5":1,"d6":1}

Victories (policy|ending): {"baseline|return":2,"baseline|serpent":19,"baseline|unwritten":28,"explorer|by_decree":1,"explorer|return":17,"explorer|serpent":25,"explorer|unwritten":6,"specialist|return":3,"specialist|serpent":22,"specialist|unwritten":33}

## Coverage

- talents_learned: 104/104
- talents_used: 49/104
- monsters_killed: 86/86
- floors_visited: 28/28
- threads_accepted: 24/24
- monsters never killed: 
- active talents never used: backstep, chain_reversal, cleanse_vapor, fade_to_ash, philosophers_loan, quiet_absolution, rite_blink, slip_the_margin, transmute_pain, unbroken_wall, unwork_chains, unyielding_march, vault_step

Mean level on first entry to each depth (policy|depth): {"baseline|d2":1.6,"baseline|d3":4.1,"baseline|d4":6.1,"baseline|d5":7.9,"baseline|d6":9.8,"baseline|d7":11.4,"explorer|d1":2.2,"explorer|d2":4.9,"explorer|d3":8.3,"explorer|d4":11.5,"explorer|d5":15.0,"explorer|d6":18.5,"explorer|d7":21.6,"specialist|d2":1.6,"specialist|d3":4.0,"specialist|d4":6.0,"specialist|d5":7.9,"specialist|d6":9.7,"specialist|d7":11.4}

Optional-content counters: {"branch|enter:archive_stair_annex":35,"branch|enter:audit_cisterns":36,"branch|enter:back_courts_undercroft":42,"branch|enter:cage_oubliette":23,"branch|enter:censer_foundry":44,"branch|enter:closed_stacks_vault":32,"branch|enter:day_house_cellars":39,"branch|enter:debts_cathedral":33,"branch|enter:gilded_cloister":30,"branch|enter:hidden_assembly_catacomb":31,"branch|enter:ophite_seam_hollow":37,"branch|enter:preliator_garrison":34,"branch|enter:processional_underway":36,"branch|enter:seal_foundry_deep":29,"branch|enter:shut_chapel_crypt":45,"branch|enter:sun_house_furnaces":39,"branch|enter:tithe_road_tunnels":43,"branch|enter:unrecorded_market_seams":36,"branch|enter:unwritten_margin":17,"branch|enter:velvet_ossuary":39,"branch|enter:witness_hermitage":21,"branch|leave:archive_stair_annex":35,"branch|leave:audit_cisterns":35,"branch|leave:back_courts_undercroft":39,"branch|leave:cage_oubliette":23,"branch|leave:censer_foundry":44,"branch|leave:closed_stacks_vault":32,"branch|leave:day_house_cellars":39,"branch|leave:debts_cathedral":33,"branch|leave:gilded_cloister":30,"branch|leave:hidden_assembly_catacomb":31,"branch|leave:ophite_seam_hollow":36,"branch|leave:preliator_garrison":34,"branch|leave:processional_underway":36,"branch|leave:seal_foundry_deep":29,"branch|leave:shut_chapel_crypt":45,"branch|leave:sun_house_furnaces":37,"branch|leave:tithe_road_tunnels":43,"branch|leave:unrecorded_market_seams":35,"branch|leave:unwritten_margin":17,"branch|leave:velvet_ossuary":38,"branch|leave:witness_hermitage":20,"consumable|abyssal_shard_dart":2,"consumable|almoners_ration":22,"consumable|barbed_dart":13,"consumable|cinder_flask":113,"consumable|clarion_drops":2,"consumable|dayhouse_broth_phial":1,"consumable|eye_bright_water":5,"consumable|false_sun_prism":24,"consumable|foundry_pepper_dram":1,"consumable|healing_salve":80,"consumable|javelin":129,"consumable|ossuary_rime_vial":60,"consumable|quicksilver_sip":11,"consumable|salt_shrapnel_bomb":9,"consumable|sanctuary_dew_flask":19,"consumable|scroll_of_identify":137,"consumable|scroll_of_unbind":15,"consumable|silver_spike":3,"consumable|snare_bolas":44,"consumable|throwing_knife":182,"consumable|vial_of_false_light":119,"consumable|wormwood_salt":2,"contract_broken|the_crown_taken":1,"contract_broken|vow_of_poverty":3,"contract_fulfilled|the_crown_taken":2,"contract_fulfilled|the_fast":2,"contract_fulfilled|the_taken_name":4,"contract_fulfilled|vow_of_poverty":4,"contract_signed|the_crown_taken":4,"contract_signed|the_fast":3,"contract_signed|the_taken_name":4,"contract_signed|vow_of_poverty":7,"entangled|depth3":3,"gate|by_name":966,"gate|given_back":61,"gate|serpents_key":4,"interact|abandoned_rite:dismantle":74,"interact|altar:cleanse":3,"interact|altar:tithe":35,"interact|challenge:default":22,"interact|contract_lectern:sign":18,"interact|echo_cache:read":87,"interact|merchant:buy":31,"interact|npc:service":291,"interact|npc:talk":275,"interact|ritual_circle:attest":1,"interact|ritual_circle:inscribe":27,"interact|rune_puzzle:solve_order":79,"interact|sanctuary_hearth:rest_quiet":2,"interact|shrine:witness":132,"interact|vault_gate:force":15,"interact|vault_gate:key":115,"relic_transmuted|almoners_purse":27,"relic_transmuted|archive_lens":9,"relic_transmuted|ash_reliquary_box":2,"relic_transmuted|broken_halo":16,"relic_transmuted|cantors_fork":4,"relic_transmuted|confessors_glass":31,"relic_transmuted|counterfeit_sun_coin":3,"relic_transmuted|ophite_key":58,"relic_transmuted|penitents_scourge":25,"relic_transmuted|salt_hourglass":6,"relic_transmuted|severed_crown":13,"relic_transmuted|ward_keepers_lamp":20,"relic_transmuted|warden_portcullis_seal":5,"relic_transmuted|witness_pocket_mirror":1,"thread_abandoned|cistern_catch_basin":7,"thread_abandoned|cut_stamp_closed_stacks":2,"thread_abandoned|dayhouse_soup_kettle":5,"thread_abandoned|forge_cyrus_hammer":1,"thread_abandoned|foundry_slag_debt":4,"thread_abandoned|hermitage_silent_vow":8,"thread_abandoned|hide_from_procession":11,"thread_abandoned|loose_stitch_back_courts":7,"thread_abandoned|margin_unwritten_scroll":19,"thread_abandoned|marginalia_of_the_shut":4,"thread_abandoned|market_short_measure":6,"thread_abandoned|mute_choir_rehearsal":9,"thread_abandoned|night_cart_detour":38,"thread_abandoned|ophite_hollow_vigil":16,"thread_abandoned|oubliette_key_weight":12,"thread_abandoned|readers_locked_chest":3,"thread_abandoned|shuttered_lamp_oil":8,"thread_abandoned|tallyman_erased_row":1,"thread_abandoned|unfiled_census_leaf":3,"thread_abandoned|unopened_door_wren":4,"thread_abandoned|velvet_appraiser_seal":1,"thread_settled|ash_canticle_embers:goal":19,"thread_settled|binder_malakor_codex:goal":19,"thread_settled|cistern_catch_basin:goal":6,"thread_settled|forge_cyrus_hammer:goal":16,"thread_settled|foundry_slag_debt:goal":1,"thread_settled|hermitage_silent_vow:goal":3,"thread_settled|honest_blade_inspection:goal":18,"thread_settled|loose_stitch_back_courts:goal":2,"thread_settled|night_cart_detour:goal":17,"thread_settled|tallyman_erased_row:goal":3,"thread_settled|unfiled_census_leaf:goal":1,"thread_settled|velvet_appraiser_seal:goal":4,"victory|by_decree":1,"victory|return":22,"victory|serpent":66,"victory|unwritten":67}

Suspect pairs (adaptive sampling): cambion/false_light_alchemist, human/fallen_knight, human/false_light_alchemist, human/occultist, human/preliator_warden
