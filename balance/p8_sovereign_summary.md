# M7 soak summary (192 runs)

## Policies

| policy | n | win | mean depth | mean level | mean turns |
|---|---|---|---|---|---|
| baseline | 64 | 65.6% | 5.91 | 11.9 | 751 |
| explorer | 64 | 56.3% | 5.58 | 21.0 | 11296 |
| specialist | 64 | 79.7% | 6.31 | 12.9 | 793 |

## Calling x policy (win rate, n)

| calling | baseline | explorer | specialist |
|---|---|---|---|
| assassin | 88% (8) | 50% (8) | 75% (8) |
| fallen_knight | 88% (8) | 50% (8) | 75% (8) |
| false_light_alchemist | 100% (8) | 88% (8) | 100% (8) |
| occultist | 50% (8) | 50% (8) | 50% (8) |
| ophite_binder | 50% (8) | 25% (8) | 75% (8) |
| preliator_warden | 62% (8) | 88% (8) | 88% (8) |
| rite_weaver | 25% (8) | 38% (8) | 100% (8) |
| tithe_marksman | 62% (8) | 62% (8) | 75% (8) |

## Deaths (non-random)

- d2 cultist of the false sun: 4
- d2 The Vault Enumerator: 3
- d5 Iron Auditor: 3
- d4 gilded idol: 3
- d6 Lord Decreetory Octavius: 2
- d3 ghoul: 2
- d1 cistern eel: 2
- d4 Noonday Cantor Vael: 2
- d2 confessor hound: 1
- d5 Gilded Tithe Inquisitor: 1
- d2 Sealed cultist of the false sun: 1
- d4 Ashen gilded idol: 1
- d2 armed audit clerk: 1
- d2 Ironbound ghoul: 1
- d5 quill interrogator: 1
- d1 bleeding: 1
- d3 Choir Cantor Prime: 1
- d1 blinded witness: 1
- d2 bleeding: 1
- d1 Back-Court Matriarch: 1

Classification: {"attrition":18,"false_light_window":3,"healing_unused_or_too_slow":3,"no_healing_available":10}

Deaths by depth: {"d1":5,"d2":12,"d3":4,"d4":6,"d5":5,"d6":2}

Victories (policy|ending): {"baseline|return":2,"baseline|serpent":18,"baseline|unwritten":22,"explorer|by_decree":2,"explorer|return":6,"explorer|serpent":21,"explorer|unwritten":7,"specialist|return":2,"specialist|serpent":30,"specialist|unwritten":19}

## Coverage

- talents_learned: 104/104
- talents_used: 48/104
- monsters_killed: 86/86
- floors_visited: 28/28
- threads_accepted: 24/24
- monsters never killed: 
- active talents never used: backstep, cleanse_vapor, fade_to_ash, margin_collapse, philosophers_loan, quiet_absolution, rite_blink, slip_the_margin, transmute_pain, unbroken_wall, unwork_chains, unyielding_march, vault_step, volatile_salve

Mean level on first entry to each depth (policy|depth): {"baseline|d2":1.9,"baseline|d3":4.6,"baseline|d4":6.7,"baseline|d5":8.9,"baseline|d6":11.0,"baseline|d7":12.6,"explorer|d1":2.7,"explorer|d2":5.8,"explorer|d3":10.0,"explorer|d4":13.8,"explorer|d5":17.2,"explorer|d6":20.7,"explorer|d7":23.9,"specialist|d2":1.9,"specialist|d3":4.6,"specialist|d4":6.8,"specialist|d5":9.0,"specialist|d6":10.9,"specialist|d7":12.7}

Optional-content counters: {"branch|enter:archive_stair_annex":32,"branch|enter:audit_cisterns":30,"branch|enter:back_courts_undercroft":42,"branch|enter:cage_oubliette":17,"branch|enter:censer_foundry":36,"branch|enter:closed_stacks_vault":25,"branch|enter:day_house_cellars":38,"branch|enter:debts_cathedral":31,"branch|enter:gilded_cloister":23,"branch|enter:hidden_assembly_catacomb":24,"branch|enter:ophite_seam_hollow":28,"branch|enter:preliator_garrison":29,"branch|enter:processional_underway":33,"branch|enter:seal_foundry_deep":22,"branch|enter:shut_chapel_crypt":44,"branch|enter:sun_house_furnaces":32,"branch|enter:tithe_road_tunnels":43,"branch|enter:unrecorded_market_seams":32,"branch|enter:unwritten_margin":10,"branch|enter:velvet_ossuary":37,"branch|enter:witness_hermitage":17,"branch|leave:archive_stair_annex":30,"branch|leave:audit_cisterns":29,"branch|leave:back_courts_undercroft":38,"branch|leave:cage_oubliette":17,"branch|leave:censer_foundry":36,"branch|leave:closed_stacks_vault":25,"branch|leave:day_house_cellars":37,"branch|leave:debts_cathedral":31,"branch|leave:gilded_cloister":23,"branch|leave:hidden_assembly_catacomb":24,"branch|leave:ophite_seam_hollow":27,"branch|leave:preliator_garrison":28,"branch|leave:processional_underway":32,"branch|leave:seal_foundry_deep":22,"branch|leave:shut_chapel_crypt":43,"branch|leave:sun_house_furnaces":30,"branch|leave:tithe_road_tunnels":43,"branch|leave:unrecorded_market_seams":32,"branch|leave:unwritten_margin":10,"branch|leave:velvet_ossuary":35,"branch|leave:witness_hermitage":16,"consumable|abyssal_shard_dart":1,"consumable|almoners_ration":24,"consumable|apostate_wine":3,"consumable|barbed_dart":15,"consumable|bone_tincture":11,"consumable|cinder_flask":102,"consumable|clarion_drops":1,"consumable|dayhouse_broth_phial":5,"consumable|eye_bright_water":9,"consumable|false_sun_prism":17,"consumable|healing_salve":30,"consumable|iron_bark_tonic":3,"consumable|javelin":144,"consumable|lamp_oil_sip":1,"consumable|ossuary_rime_vial":78,"consumable|quicksilver_sip":10,"consumable|salt_shrapnel_bomb":16,"consumable|sanctuary_dew_flask":13,"consumable|sanctuary_poultice":3,"consumable|scroll_of_identify":146,"consumable|scroll_of_unbind":18,"consumable|silver_spike":6,"consumable|snare_bolas":33,"consumable|sunflare_capsule":3,"consumable|throwing_knife":178,"consumable|vial_of_false_light":128,"consumable|wormwood_salt":3,"contract_broken|vow_of_poverty":2,"contract_fulfilled|the_crown_taken":1,"contract_fulfilled|the_fast":2,"contract_fulfilled|the_taken_name":5,"contract_fulfilled|vow_of_poverty":1,"contract_signed|the_crown_taken":3,"contract_signed|the_fast":2,"contract_signed|the_taken_name":5,"contract_signed|vow_of_poverty":3,"entangled|depth2":1,"entangled|depth3":1,"entangled|depth4":4,"entangled|depth7":1,"gate|by_name":860,"gate|given_back":77,"gate|serpents_key":10,"interact|abandoned_rite:dismantle":63,"interact|altar:cleanse":5,"interact|altar:tithe":24,"interact|challenge:default":25,"interact|contract_lectern:sign":13,"interact|echo_cache:read":73,"interact|merchant:buy":30,"interact|npc:service":229,"interact|npc:talk":216,"interact|ritual_circle:attest":1,"interact|ritual_circle:inscribe":27,"interact|rune_puzzle:solve_order":70,"interact|shrine:witness":121,"interact|vault_gate:force":10,"interact|vault_gate:key":99,"relic_transmuted|almoners_purse":36,"relic_transmuted|archive_lens":11,"relic_transmuted|ash_reliquary_box":2,"relic_transmuted|broken_halo":14,"relic_transmuted|cantors_fork":4,"relic_transmuted|confessors_glass":49,"relic_transmuted|counterfeit_sun_coin":5,"relic_transmuted|ophite_key":68,"relic_transmuted|penitents_scourge":22,"relic_transmuted|salt_hourglass":12,"relic_transmuted|severed_crown":13,"relic_transmuted|ward_keepers_lamp":28,"relic_transmuted|warden_portcullis_seal":5,"thread_abandoned|cistern_catch_basin":15,"thread_abandoned|cut_stamp_closed_stacks":3,"thread_abandoned|dayhouse_soup_kettle":5,"thread_abandoned|forge_cyrus_hammer":2,"thread_abandoned|foundry_slag_debt":2,"thread_abandoned|hermitage_silent_vow":11,"thread_abandoned|hide_from_procession":8,"thread_abandoned|honest_blade_inspection":1,"thread_abandoned|loose_stitch_back_courts":1,"thread_abandoned|margin_unwritten_scroll":15,"thread_abandoned|marginalia_of_the_shut":1,"thread_abandoned|market_short_measure":7,"thread_abandoned|mute_choir_rehearsal":8,"thread_abandoned|night_cart_detour":30,"thread_abandoned|ophite_hollow_vigil":18,"thread_abandoned|oubliette_key_weight":10,"thread_abandoned|readers_locked_chest":2,"thread_abandoned|shuttered_lamp_oil":7,"thread_abandoned|unfiled_census_leaf":3,"thread_abandoned|unopened_door_wren":1,"thread_abandoned|velvet_appraiser_seal":1,"thread_settled|ash_canticle_embers:goal":15,"thread_settled|binder_malakor_codex:goal":13,"thread_settled|cistern_catch_basin:goal":5,"thread_settled|cut_stamp_closed_stacks:goal":1,"thread_settled|forge_cyrus_hammer:goal":12,"thread_settled|foundry_slag_debt:goal":1,"thread_settled|hermitage_silent_vow:goal":2,"thread_settled|honest_blade_inspection:goal":13,"thread_settled|loose_stitch_back_courts:goal":2,"thread_settled|night_cart_detour:goal":18,"thread_settled|tallyman_erased_row:goal":3,"thread_settled|velvet_appraiser_seal:goal":5,"victory|by_decree":2,"victory|return":10,"victory|serpent":69,"victory|unwritten":48}

Suspect pairs (adaptive sampling): cambion/false_light_alchemist
