# M7 soak summary (192 runs)

## Policies

| policy | n | win | mean depth | mean level | mean turns |
|---|---|---|---|---|---|
| baseline | 64 | 73.4% | 6.23 | 12.4 | 758 |
| explorer | 64 | 56.3% | 5.78 | 21.4 | 11707 |
| specialist | 64 | 81.3% | 6.39 | 12.8 | 774 |

## Calling x policy (win rate, n)

| calling | baseline | explorer | specialist |
|---|---|---|---|
| assassin | 88% (8) | 75% (8) | 100% (8) |
| fallen_knight | 62% (8) | 62% (8) | 88% (8) |
| false_light_alchemist | 100% (8) | 100% (8) | 100% (8) |
| occultist | 50% (8) | 62% (8) | 62% (8) |
| ophite_binder | 50% (8) | 38% (8) | 75% (8) |
| preliator_warden | 100% (8) | 75% (8) | 100% (8) |
| rite_weaver | 62% (8) | 12% (8) | 62% (8) |
| tithe_marksman | 75% (8) | 25% (8) | 62% (8) |

## Deaths (non-random)

- d5 Iron Auditor: 3
- d3 bleeding: 2
- d2 armed audit clerk: 2
- d2 Sealed armed audit clerk: 1
- d2 bleeding: 1
- d3 Choir Cantor Prime: 1
- d4 processional lancer: 1
- d2 ossuary arbalest: 1
- d4 Crimson processional lancer: 1
- d4 Noonday Cantor Vael: 1
- d5 Fleet Tithe Inquisitor: 1
- d2 Fleet confessor hound: 1
- d1 bone hoarder: 1
- d2 Apostate ghoul: 1
- d4 Crimson gilded idol: 1
- d2 The Vault Enumerator: 1
- d5 Crimson Tithe Inquisitor: 1
- d1 bleeding: 1
- d5 quill interrogator: 1
- d6 Sphere gate warden: 1

Classification: {"attrition":11,"false_light_window":3,"healing_unused_or_too_slow":3,"no_healing_available":9}

Deaths by depth: {"d1":3,"d2":8,"d3":3,"d4":5,"d5":6,"d6":1}

Victories (policy|ending): {"baseline|serpent":24,"baseline|unwritten":23,"explorer|by_decree":2,"explorer|return":13,"explorer|serpent":15,"explorer|unwritten":6,"specialist|return":1,"specialist|serpent":30,"specialist|unwritten":21}

## Coverage

- talents_learned: 104/104
- talents_used: 48/104
- monsters_killed: 86/86
- floors_visited: 28/28
- threads_accepted: 23/24
- monsters never killed: 
- active talents never used: backstep, chain_reversal, cleanse_vapor, fade_to_ash, philosophers_loan, quiet_absolution, rite_blink, slip_the_margin, transmute_pain, unbroken_wall, unwork_chains, unyielding_march, vault_step, volatile_salve

Mean level on first entry to each depth (policy|depth): {"baseline|d2":1.8,"baseline|d3":4.4,"baseline|d4":6.4,"baseline|d5":8.7,"baseline|d6":10.7,"baseline|d7":12.4,"explorer|d1":2.6,"explorer|d2":5.6,"explorer|d3":9.4,"explorer|d4":13.3,"explorer|d5":16.9,"explorer|d6":20.7,"explorer|d7":24.1,"specialist|d2":1.8,"specialist|d3":4.4,"specialist|d4":6.5,"specialist|d5":8.6,"specialist|d6":10.7,"specialist|d7":12.5}

Optional-content counters: {"branch|enter:archive_stair_annex":33,"branch|enter:audit_cisterns":31,"branch|enter:back_courts_undercroft":42,"branch|enter:cage_oubliette":13,"branch|enter:censer_foundry":41,"branch|enter:closed_stacks_vault":30,"branch|enter:day_house_cellars":39,"branch|enter:debts_cathedral":27,"branch|enter:gilded_cloister":26,"branch|enter:hidden_assembly_catacomb":29,"branch|enter:ophite_seam_hollow":27,"branch|enter:preliator_garrison":31,"branch|enter:processional_underway":32,"branch|enter:seal_foundry_deep":19,"branch|enter:shut_chapel_crypt":44,"branch|enter:sun_house_furnaces":35,"branch|enter:tithe_road_tunnels":44,"branch|enter:unrecorded_market_seams":33,"branch|enter:unwritten_margin":13,"branch|enter:velvet_ossuary":40,"branch|enter:witness_hermitage":14,"branch|leave:archive_stair_annex":33,"branch|leave:audit_cisterns":28,"branch|leave:back_courts_undercroft":40,"branch|leave:cage_oubliette":13,"branch|leave:censer_foundry":41,"branch|leave:closed_stacks_vault":30,"branch|leave:day_house_cellars":38,"branch|leave:debts_cathedral":27,"branch|leave:gilded_cloister":26,"branch|leave:hidden_assembly_catacomb":29,"branch|leave:ophite_seam_hollow":26,"branch|leave:preliator_garrison":29,"branch|leave:processional_underway":32,"branch|leave:seal_foundry_deep":19,"branch|leave:shut_chapel_crypt":43,"branch|leave:sun_house_furnaces":33,"branch|leave:tithe_road_tunnels":44,"branch|leave:unrecorded_market_seams":33,"branch|leave:unwritten_margin":13,"branch|leave:velvet_ossuary":40,"branch|leave:witness_hermitage":14,"consumable|abyssal_shard_dart":6,"consumable|almoners_ration":28,"consumable|apostate_wine":2,"consumable|barbed_dart":17,"consumable|bone_tincture":4,"consumable|cinder_flask":104,"consumable|clarion_drops":1,"consumable|dayhouse_broth_phial":3,"consumable|eye_bright_water":5,"consumable|false_sun_prism":22,"consumable|foundry_pepper_dram":2,"consumable|healing_salve":78,"consumable|javelin":148,"consumable|lamp_oil_sip":5,"consumable|ossuary_rime_vial":65,"consumable|pitch_fire_bead":2,"consumable|quicksilver_sip":8,"consumable|salt_shrapnel_bomb":19,"consumable|sanctuary_dew_flask":20,"consumable|scroll_of_identify":147,"consumable|scroll_of_unbind":14,"consumable|silver_spike":2,"consumable|snare_bolas":43,"consumable|sunflare_capsule":2,"consumable|throwing_knife":177,"consumable|vial_of_false_light":137,"consumable|wormwood_salt":5,"contract_broken|the_crown_taken":2,"contract_broken|vow_of_poverty":4,"contract_fulfilled|the_crown_taken":1,"contract_fulfilled|the_fast":4,"contract_fulfilled|the_taken_name":3,"contract_signed|the_crown_taken":5,"contract_signed|the_fast":5,"contract_signed|the_taken_name":3,"contract_signed|vow_of_poverty":6,"entangled|depth4":3,"entangled|depth5":1,"entangled|depth7":1,"gate|by_name":900,"gate|given_back":80,"gate|serpents_key":6,"interact|abandoned_rite:dismantle":81,"interact|altar:cleanse":4,"interact|altar:tithe":19,"interact|challenge:default":23,"interact|contract_lectern:sign":19,"interact|echo_cache:read":78,"interact|merchant:buy":35,"interact|npc:service":246,"interact|npc:talk":237,"interact|ritual_circle:attest":1,"interact|ritual_circle:inscribe":19,"interact|rune_puzzle:solve_order":74,"interact|shrine:witness":97,"interact|vault_gate:force":8,"interact|vault_gate:key":91,"relic_transmuted|almoners_purse":46,"relic_transmuted|archive_lens":3,"relic_transmuted|ash_reliquary_box":2,"relic_transmuted|broken_halo":12,"relic_transmuted|cantors_fork":3,"relic_transmuted|confessors_glass":36,"relic_transmuted|ophite_key":59,"relic_transmuted|penitents_scourge":29,"relic_transmuted|salt_hourglass":9,"relic_transmuted|severed_crown":19,"relic_transmuted|ward_keepers_lamp":33,"relic_transmuted|warden_portcullis_seal":7,"thread_abandoned|cistern_catch_basin":17,"thread_abandoned|cut_stamp_closed_stacks":2,"thread_abandoned|dayhouse_soup_kettle":6,"thread_abandoned|forge_cyrus_hammer":1,"thread_abandoned|foundry_slag_debt":2,"thread_abandoned|hermitage_silent_vow":3,"thread_abandoned|hide_from_procession":4,"thread_abandoned|honest_blade_inspection":1,"thread_abandoned|loose_stitch_back_courts":3,"thread_abandoned|margin_unwritten_scroll":16,"thread_abandoned|marginalia_of_the_shut":3,"thread_abandoned|market_short_measure":7,"thread_abandoned|mute_choir_rehearsal":8,"thread_abandoned|night_cart_detour":33,"thread_abandoned|ophite_hollow_vigil":11,"thread_abandoned|oubliette_key_weight":12,"thread_abandoned|readers_locked_chest":8,"thread_abandoned|shuttered_lamp_oil":8,"thread_abandoned|tallyman_erased_row":2,"thread_abandoned|unfiled_census_leaf":3,"thread_abandoned|velvet_appraiser_seal":1,"thread_settled|ash_canticle_embers:goal":18,"thread_settled|binder_malakor_codex:goal":15,"thread_settled|cistern_catch_basin:goal":3,"thread_settled|forge_cyrus_hammer:goal":8,"thread_settled|foundry_slag_debt:goal":5,"thread_settled|hermitage_silent_vow:goal":3,"thread_settled|honest_blade_inspection:goal":14,"thread_settled|loose_stitch_back_courts:goal":3,"thread_settled|night_cart_detour:goal":19,"thread_settled|tallyman_erased_row:goal":1,"thread_settled|unfiled_census_leaf:goal":1,"thread_settled|velvet_appraiser_seal:goal":4,"victory|by_decree":2,"victory|return":14,"victory|serpent":69,"victory|unwritten":50}

Suspect pairs (adaptive sampling): cambion/false_light_alchemist, cambion/preliator_warden, cambion/rite_weaver, human/false_light_alchemist
