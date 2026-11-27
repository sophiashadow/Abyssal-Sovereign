# M7 soak summary (512 runs)

## Policies

| policy | n | win | mean depth | mean level | mean turns |
|---|---|---|---|---|---|
| baseline | 128 | 70.3% | 6.10 | 11.1 | 824 |
| explorer | 128 | 72.7% | 6.45 | 21.9 | 9996 |
| narrative | 128 | 64.1% | 5.84 | 17.9 | 10305 |
| specialist | 128 | 81.3% | 6.31 | 11.5 | 833 |

## Calling x policy (win rate, n)

| calling | baseline | explorer | narrative | specialist |
|---|---|---|---|---|
| assassin | 75% (16) | 56% (16) | 38% (16) | 69% (16) |
| fallen_knight | 56% (16) | 94% (16) | 75% (16) | 88% (16) |
| false_light_alchemist | 94% (16) | 94% (16) | 75% (16) | 100% (16) |
| occultist | 75% (16) | 44% (16) | 62% (16) | 50% (16) |
| ophite_binder | 56% (16) | 81% (16) | 62% (16) | 88% (16) |
| preliator_warden | 88% (16) | 88% (16) | 81% (16) | 88% (16) |
| rite_weaver | 69% (16) | 56% (16) | 69% (16) | 81% (16) |
| tithe_marksman | 50% (16) | 69% (16) | 50% (16) | 88% (16) |

## Deaths (non-random)

- d2 The Vault Enumerator: 8
- d2 ghoul: 5
- d5 Iron Auditor: 4
- d2 cultist of the false sun: 3
- d3 bleeding: 2
- d1 bleeding: 2
- d4 processional lancer: 2
- d3 cultist of the false sun: 2
- d4 gilded idol: 2
- d3 Choir Cantor Prime: 1
- d1 Warden of the Shut Threshold: 1
- d3 Rime-bound cinder acolyte: 1
- d5 Tithe Inquisitor: 1
- d4 ossuary wight: 1
- d6 Rime-bound iron bulwark: 1
- d3 penance flagellant: 1
- d6 echo jackal: 1
- d4 Crimson processional lancer: 1
- d2 Fleet cultist of the false sun: 1
- d2 Ironbound ghoul: 1

Classification: {"attrition":20,"false_light_window":6,"healing_unused_or_too_slow":6,"no_healing_available":18,"underlevelled":2}

Deaths by depth: {"d1":3,"d2":19,"d3":9,"d4":7,"d5":8,"d6":4,"d7":2}

Victories (policy|ending): {"baseline|return":6,"baseline|serpent":33,"baseline|unwritten":51,"explorer|by_decree":4,"explorer|return":26,"explorer|serpent":44,"explorer|unwritten":19,"narrative|by_decree":3,"narrative|return":23,"narrative|serpent":49,"narrative|unwritten":7,"specialist|return":8,"specialist|serpent":54,"specialist|unwritten":42}

## Coverage

- talents_learned: 104/104
- talents_used: 51/104
- monsters_killed: 86/86
- floors_visited: 28/28
- threads_accepted: 24/24
- monsters never killed: 
- active talents never used: chain_reversal, fade_to_ash, philosophers_loan, quiet_absolution, rite_blink, slip_the_margin, transmute_pain, unbroken_wall, unwork_chains, unyielding_march, vault_step

Mean level on first entry to each depth (policy|depth): {"baseline|d2":1.6,"baseline|d3":4.0,"baseline|d4":6.0,"baseline|d5":7.8,"baseline|d6":9.7,"baseline|d7":11.5,"explorer|d1":2.2,"explorer|d2":5.0,"explorer|d3":8.6,"explorer|d4":12.0,"explorer|d5":15.2,"explorer|d6":18.5,"explorer|d7":21.9,"narrative|d1":2.1,"narrative|d2":4.7,"narrative|d3":7.6,"narrative|d4":9.7,"narrative|d5":12.3,"narrative|d6":15.0,"narrative|d7":18.2,"specialist|d2":1.6,"specialist|d3":4.0,"specialist|d4":5.9,"specialist|d5":7.8,"specialist|d6":9.7,"specialist|d7":11.5}

Optional-content counters: {"branch|enter:archive_stair_annex":113,"branch|enter:audit_cisterns":102,"branch|enter:back_courts_undercroft":165,"branch|enter:cage_oubliette":66,"branch|enter:censer_foundry":117,"branch|enter:closed_stacks_vault":110,"branch|enter:day_house_cellars":172,"branch|enter:debts_cathedral":108,"branch|enter:gilded_cloister":112,"branch|enter:hidden_assembly_catacomb":112,"branch|enter:ophite_seam_hollow":92,"branch|enter:preliator_garrison":108,"branch|enter:processional_underway":119,"branch|enter:seal_foundry_deep":103,"branch|enter:shut_chapel_crypt":153,"branch|enter:sun_house_furnaces":103,"branch|enter:tithe_road_tunnels":142,"branch|enter:unrecorded_market_seams":136,"branch|enter:unwritten_margin":64,"branch|enter:velvet_ossuary":88,"branch|enter:witness_hermitage":62,"branch|leave:archive_stair_annex":129,"branch|leave:audit_cisterns":110,"branch|leave:back_courts_undercroft":166,"branch|leave:cage_oubliette":82,"branch|leave:censer_foundry":104,"branch|leave:closed_stacks_vault":109,"branch|leave:day_house_cellars":172,"branch|leave:debts_cathedral":109,"branch|leave:gilded_cloister":99,"branch|leave:hidden_assembly_catacomb":106,"branch|leave:ophite_seam_hollow":96,"branch|leave:preliator_garrison":94,"branch|leave:processional_underway":115,"branch|leave:seal_foundry_deep":117,"branch|leave:shut_chapel_crypt":158,"branch|leave:sun_house_furnaces":110,"branch|leave:tithe_road_tunnels":150,"branch|leave:unrecorded_market_seams":112,"branch|leave:unwritten_margin":76,"branch|leave:velvet_ossuary":99,"branch|leave:witness_hermitage":63,"consumable|abyssal_shard_dart":5,"consumable|almoners_ration":104,"consumable|apostate_wine":13,"consumable|barbed_dart":61,"consumable|bone_tincture":13,"consumable|cinder_flask":312,"consumable|clarion_drops":2,"consumable|dayhouse_broth_phial":11,"consumable|eye_bright_water":31,"consumable|false_sun_prism":52,"consumable|foundry_pepper_dram":2,"consumable|healing_salve":194,"consumable|hoarfrost_bomb":3,"consumable|iron_bark_tonic":4,"consumable|javelin":399,"consumable|lamp_oil_sip":5,"consumable|ossuary_rime_vial":246,"consumable|pitch_fire_bead":10,"consumable|quicksilver_sip":34,"consumable|salt_shrapnel_bomb":51,"consumable|sanctuary_dew_flask":64,"consumable|sanctuary_poultice":1,"consumable|scroll_of_identify":484,"consumable|scroll_of_unbind":38,"consumable|silver_spike":17,"consumable|snare_bolas":205,"consumable|sunflare_capsule":11,"consumable|throwing_knife":571,"consumable|vial_of_false_light":319,"consumable|wormwood_salt":19,"contract_broken|the_crown_taken":8,"contract_broken|vow_of_poverty":10,"contract_fulfilled|the_crown_taken":6,"contract_fulfilled|the_fast":16,"contract_fulfilled|the_taken_name":14,"contract_fulfilled|vow_of_poverty":2,"contract_signed|the_crown_taken":21,"contract_signed|the_fast":18,"contract_signed|the_taken_name":18,"contract_signed|vow_of_poverty":12,"entangled|depth3":4,"entangled|depth4":6,"entangled|depth5":1,"entangled|depth7":2,"gate|by_name":2424,"gate|given_back":215,"gate|serpents_key":21,"interact|abandoned_rite:dismantle":279,"interact|altar:cleanse":12,"interact|altar:tithe":112,"interact|challenge:default":94,"interact|contract_lectern:sign":69,"interact|echo_cache:read":275,"interact|merchant:buy":132,"interact|npc:pledge":688,"interact|npc:service":1778,"interact|npc:talk":1750,"interact|npc:thread_accept":175,"interact|npc:thread_resolve":81,"interact|ritual_circle:attest":12,"interact|ritual_circle:inscribe":99,"interact|rune_puzzle:solve_order":288,"interact|shrine:witness":417,"interact|vault_gate:force":15,"interact|vault_gate:key":378,"narrative|given_up:ash_canticle_embers":1,"narrative|given_up:honest_blade_inspection":2,"narrative|given_up:loose_stitch_back_courts":2,"narrative|given_up:mute_choir_rehearsal":5,"narrative|given_up:unopened_door_wren":6,"narrative|travel:down":229,"narrative|travel:portal":356,"narrative|travel:up":96966,"relic_transmuted|almoners_purse":124,"relic_transmuted|archive_lens":31,"relic_transmuted|ash_reliquary_box":6,"relic_transmuted|broken_halo":38,"relic_transmuted|cantors_fork":17,"relic_transmuted|confessors_glass":115,"relic_transmuted|counterfeit_sun_coin":8,"relic_transmuted|ophite_key":174,"relic_transmuted|penitents_scourge":61,"relic_transmuted|rime_handbell":1,"relic_transmuted|salt_hourglass":33,"relic_transmuted|severed_crown":42,"relic_transmuted|unwritten_ledger_leaf":3,"relic_transmuted|ward_keepers_lamp":80,"relic_transmuted|warden_portcullis_seal":17,"relic_transmuted|witness_pocket_mirror":1,"thread_abandoned|binder_malakor_codex":6,"thread_abandoned|cistern_catch_basin":50,"thread_abandoned|cut_stamp_closed_stacks":20,"thread_abandoned|dayhouse_soup_kettle":11,"thread_abandoned|forge_cyrus_hammer":2,"thread_abandoned|foundry_slag_debt":2,"thread_abandoned|hermitage_silent_vow":6,"thread_abandoned|hide_from_procession":15,"thread_abandoned|honest_blade_inspection":4,"thread_abandoned|loose_stitch_back_courts":14,"thread_abandoned|margin_unwritten_scroll":68,"thread_abandoned|marginalia_of_the_shut":17,"thread_abandoned|market_short_measure":35,"thread_abandoned|mute_choir_rehearsal":32,"thread_abandoned|night_cart_detour":61,"thread_abandoned|ophite_hollow_vigil":21,"thread_abandoned|oubliette_key_weight":48,"thread_abandoned|readers_locked_chest":13,"thread_abandoned|shuttered_lamp_oil":26,"thread_abandoned|tallyman_erased_row":29,"thread_abandoned|unfiled_census_leaf":7,"thread_abandoned|unopened_door_wren":4,"thread_abandoned|velvet_appraiser_seal":5,"thread_settled|ash_canticle_embers:goal":74,"thread_settled|binder_malakor_codex:goal":39,"thread_settled|cistern_catch_basin:goal":29,"thread_settled|cut_stamp_closed_stacks:goal":2,"thread_settled|dayhouse_soup_kettle:sacrifice":41,"thread_settled|forge_cyrus_hammer:goal":47,"thread_settled|foundry_slag_debt:goal":12,"thread_settled|hermitage_silent_vow:goal":26,"thread_settled|hide_from_procession:sacrifice":40,"thread_settled|honest_blade_inspection:goal":44,"thread_settled|loose_stitch_back_courts:goal":31,"thread_settled|margin_unwritten_scroll:goal":19,"thread_settled|market_short_measure:goal":7,"thread_settled|mute_choir_rehearsal:goal":8,"thread_settled|night_cart_detour:goal":63,"thread_settled|ophite_hollow_vigil:goal":7,"thread_settled|oubliette_key_weight:goal":12,"thread_settled|shuttered_lamp_oil:goal":14,"thread_settled|tallyman_erased_row:goal":20,"thread_settled|unfiled_census_leaf:goal":20,"thread_settled|unopened_door_wren:goal":4,"thread_settled|velvet_appraiser_seal:goal":21,"victory|by_decree":7,"victory|return":63,"victory|serpent":180,"victory|unwritten":119}

Suspect pairs (adaptive sampling): ashborn/false_light_alchemist, ashborn/occultist, ashborn/rite_weaver, cambion/assassin, cambion/preliator_warden, human/false_light_alchemist, human/preliator_warden, human/rite_weaver, human/tithe_marksman, ironbound_ward/false_light_alchemist, penitent/occultist, penitent/preliator_warden, penitent/rite_weaver, revenant/assassin, revenant/false_light_alchemist, revenant/preliator_warden, unrecorded/false_light_alchemist, veilkin/assassin, veilkin/preliator_warden, veilkin/tithe_marksman
