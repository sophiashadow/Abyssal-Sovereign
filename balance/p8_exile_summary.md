# M7 soak summary (192 runs)

## Policies

| policy | n | win | mean depth | mean level | mean turns |
|---|---|---|---|---|---|
| baseline | 64 | 78.1% | 6.30 | 12.1 | 939 |
| explorer | 64 | 60.9% | 5.63 | 19.8 | 10993 |
| specialist | 64 | 85.9% | 6.52 | 12.6 | 676 |

## Calling x policy (win rate, n)

| calling | baseline | explorer | specialist |
|---|---|---|---|
| assassin | 88% (8) | 38% (8) | 88% (8) |
| fallen_knight | 88% (8) | 75% (8) | 100% (8) |
| false_light_alchemist | 100% (8) | 88% (8) | 100% (8) |
| occultist | 75% (8) | 88% (8) | 75% (8) |
| ophite_binder | 38% (8) | 38% (8) | 62% (8) |
| preliator_warden | 100% (8) | 75% (8) | 75% (8) |
| rite_weaver | 62% (8) | 62% (8) | 88% (8) |
| tithe_marksman | 75% (8) | 25% (8) | 100% (8) |

## Deaths (non-random)

- d2 The Vault Enumerator: 3
- d3 ghoul: 2
- d1 Back-Court Matriarch: 2
- d2 confessor hound: 2
- d1 bleeding: 2
- d2 ghoul: 1
- d4 Crimson ossuary wight: 1
- d4 bleeding: 1
- d4 Rime-bound processional lancer: 1
- d4 Gilded ossuary wight: 1
- d3 cinder acolyte: 1
- d1 Warden of the Shut Threshold: 1

Classification: {"attrition":7,"false_light_window":2,"healing_unused_or_too_slow":3,"no_healing_available":6}

Deaths by depth: {"d1":5,"d2":6,"d3":3,"d4":4}

Victories (policy|ending): {"baseline|return":1,"baseline|serpent":17,"baseline|unwritten":32,"explorer|by_decree":3,"explorer|return":8,"explorer|serpent":20,"explorer|unwritten":8,"specialist|return":2,"specialist|serpent":24,"specialist|unwritten":29}

## Coverage

- talents_learned: 104/104
- talents_used: 48/104
- monsters_killed: 86/86
- floors_visited: 28/28
- threads_accepted: 24/24
- monsters never killed: 
- active talents never used: backstep, chain_reversal, cleanse_vapor, fade_to_ash, margin_collapse, philosophers_loan, quiet_absolution, rite_blink, slip_the_margin, transmute_pain, unbroken_wall, unwork_chains, unyielding_march, vault_step

Mean level on first entry to each depth (policy|depth): {"baseline|d2":1.7,"baseline|d3":4.3,"baseline|d4":6.4,"baseline|d5":8.5,"baseline|d6":10.2,"baseline|d7":11.8,"explorer|d1":2.3,"explorer|d2":5.2,"explorer|d3":8.9,"explorer|d4":12.2,"explorer|d5":15.5,"explorer|d6":19.1,"explorer|d7":22.5,"specialist|d2":1.7,"specialist|d3":4.3,"specialist|d4":6.4,"specialist|d5":8.4,"specialist|d6":10.3,"specialist|d7":12.0}

Optional-content counters: {"branch|enter:archive_stair_annex":36,"branch|enter:audit_cisterns":29,"branch|enter:back_courts_undercroft":41,"branch|enter:cage_oubliette":23,"branch|enter:censer_foundry":38,"branch|enter:closed_stacks_vault":25,"branch|enter:day_house_cellars":39,"branch|enter:debts_cathedral":26,"branch|enter:gilded_cloister":26,"branch|enter:hidden_assembly_catacomb":29,"branch|enter:ophite_seam_hollow":33,"branch|enter:preliator_garrison":27,"branch|enter:processional_underway":31,"branch|enter:seal_foundry_deep":22,"branch|enter:shut_chapel_crypt":45,"branch|enter:sun_house_furnaces":31,"branch|enter:tithe_road_tunnels":42,"branch|enter:unrecorded_market_seams":34,"branch|enter:unwritten_margin":13,"branch|enter:velvet_ossuary":37,"branch|enter:witness_hermitage":20,"branch|leave:archive_stair_annex":35,"branch|leave:audit_cisterns":29,"branch|leave:back_courts_undercroft":39,"branch|leave:cage_oubliette":23,"branch|leave:censer_foundry":38,"branch|leave:closed_stacks_vault":25,"branch|leave:day_house_cellars":39,"branch|leave:debts_cathedral":26,"branch|leave:gilded_cloister":25,"branch|leave:hidden_assembly_catacomb":28,"branch|leave:ophite_seam_hollow":33,"branch|leave:preliator_garrison":26,"branch|leave:processional_underway":29,"branch|leave:seal_foundry_deep":22,"branch|leave:shut_chapel_crypt":44,"branch|leave:sun_house_furnaces":27,"branch|leave:tithe_road_tunnels":41,"branch|leave:unrecorded_market_seams":33,"branch|leave:unwritten_margin":12,"branch|leave:velvet_ossuary":36,"branch|leave:witness_hermitage":20,"consumable|abyssal_shard_dart":3,"consumable|almoners_ration":26,"consumable|apostate_wine":1,"consumable|barbed_dart":16,"consumable|bone_tincture":4,"consumable|cinder_flask":121,"consumable|clarion_drops":4,"consumable|eye_bright_water":3,"consumable|false_sun_prism":28,"consumable|healing_salve":62,"consumable|javelin":139,"consumable|lamp_oil_sip":1,"consumable|ossuary_rime_vial":90,"consumable|pitch_fire_bead":2,"consumable|quicksilver_sip":12,"consumable|salt_shrapnel_bomb":12,"consumable|sanctuary_dew_flask":25,"consumable|sanctuary_poultice":3,"consumable|scroll_of_identify":131,"consumable|scroll_of_unbind":15,"consumable|silver_spike":2,"consumable|snare_bolas":47,"consumable|throwing_knife":175,"consumable|vial_of_false_light":130,"consumable|wormwood_salt":1,"contract_broken|the_crown_taken":2,"contract_broken|vow_of_poverty":4,"contract_fulfilled|the_crown_taken":3,"contract_fulfilled|the_fast":3,"contract_fulfilled|the_taken_name":2,"contract_fulfilled|vow_of_poverty":1,"contract_signed|the_crown_taken":7,"contract_signed|the_fast":3,"contract_signed|the_taken_name":5,"contract_signed|vow_of_poverty":7,"entangled|depth4":3,"entangled|depth6":1,"entangled|depth7":1,"gate|by_name":905,"gate|given_back":78,"gate|serpents_key":5,"interact|abandoned_rite:dismantle":67,"interact|altar:cleanse":2,"interact|altar:tithe":18,"interact|challenge:default":16,"interact|contract_lectern:sign":22,"interact|echo_cache:read":88,"interact|merchant:buy":42,"interact|npc:service":236,"interact|npc:talk":224,"interact|ritual_circle:attest":1,"interact|ritual_circle:inscribe":19,"interact|rune_puzzle:solve_order":65,"interact|shrine:witness":107,"interact|vault_gate:force":10,"interact|vault_gate:key":96,"relic_transmuted|almoners_purse":41,"relic_transmuted|archive_lens":12,"relic_transmuted|ash_reliquary_box":1,"relic_transmuted|broken_halo":9,"relic_transmuted|confessors_glass":31,"relic_transmuted|counterfeit_sun_coin":2,"relic_transmuted|ophite_key":58,"relic_transmuted|penitents_scourge":26,"relic_transmuted|salt_hourglass":13,"relic_transmuted|severed_crown":4,"relic_transmuted|ward_keepers_lamp":27,"relic_transmuted|warden_portcullis_seal":2,"thread_abandoned|binder_malakor_codex":2,"thread_abandoned|cistern_catch_basin":14,"thread_abandoned|cut_stamp_closed_stacks":4,"thread_abandoned|dayhouse_soup_kettle":4,"thread_abandoned|hermitage_silent_vow":7,"thread_abandoned|hide_from_procession":8,"thread_abandoned|loose_stitch_back_courts":2,"thread_abandoned|margin_unwritten_scroll":15,"thread_abandoned|marginalia_of_the_shut":1,"thread_abandoned|market_short_measure":5,"thread_abandoned|mute_choir_rehearsal":9,"thread_abandoned|night_cart_detour":34,"thread_abandoned|ophite_hollow_vigil":11,"thread_abandoned|oubliette_key_weight":12,"thread_abandoned|shuttered_lamp_oil":7,"thread_abandoned|unfiled_census_leaf":2,"thread_abandoned|unopened_door_wren":3,"thread_abandoned|velvet_appraiser_seal":2,"thread_settled|ash_canticle_embers:goal":16,"thread_settled|binder_malakor_codex:goal":10,"thread_settled|cistern_catch_basin:goal":5,"thread_settled|forge_cyrus_hammer:goal":12,"thread_settled|foundry_slag_debt:goal":2,"thread_settled|hermitage_silent_vow:goal":4,"thread_settled|honest_blade_inspection:goal":14,"thread_settled|loose_stitch_back_courts:goal":2,"thread_settled|night_cart_detour:goal":17,"thread_settled|tallyman_erased_row:goal":5,"thread_settled|velvet_appraiser_seal:goal":3,"victory|by_decree":3,"victory|return":11,"victory|serpent":61,"victory|unwritten":69}

Suspect pairs (adaptive sampling): cambion/false_light_alchemist, cambion/ophite_binder, human/fallen_knight
