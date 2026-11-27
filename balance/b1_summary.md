# M7 soak summary (1248 runs)

## Policies

| policy | n | win | mean depth | mean level | mean turns |
|---|---|---|---|---|---|
| aggressive | 156 | 68.6% | 5.92 | 10.7 | 778 |
| baseline | 156 | 70.5% | 5.99 | 10.8 | 791 |
| defensive | 156 | 62.8% | 5.56 | 9.7 | 704 |
| explorer | 156 | 62.8% | 5.79 | 20.2 | 9664 |
| narrative | 156 | 61.5% | 5.65 | 17.2 | 7061 |
| preserver | 156 | 66.0% | 5.83 | 10.6 | 881 |
| random | 156 | 0.0% | 1.00 | 1.1 | 2634 |
| specialist | 156 | 86.5% | 6.46 | 11.8 | 666 |

## Calling x policy (win rate, n)

| calling | aggressive | baseline | defensive | explorer | narrative | preserver | random | specialist |
|---|---|---|---|---|---|---|---|---|
| assassin | 81% (16) | 81% (16) | 81% (16) | 94% (16) | 69% (16) | 69% (16) | 0% (16) | 94% (16) |
| fallen_knight | 67% (18) | 83% (18) | 72% (18) | 67% (18) | 67% (18) | 72% (18) | 0% (18) | 89% (18) |
| false_light_alchemist | 90% (20) | 95% (20) | 80% (20) | 90% (20) | 50% (20) | 80% (20) | 0% (20) | 100% (20) |
| occultist | 72% (18) | 72% (18) | 61% (18) | 61% (18) | 61% (18) | 78% (18) | 0% (18) | 50% (18) |
| ophite_binder | 68% (22) | 55% (22) | 41% (22) | 36% (22) | 55% (22) | 59% (22) | 0% (22) | 73% (22) |
| preliator_warden | 83% (18) | 94% (18) | 89% (18) | 83% (18) | 67% (18) | 94% (18) | 0% (18) | 94% (18) |
| rite_weaver | 27% (26) | 35% (26) | 38% (26) | 42% (26) | 73% (26) | 27% (26) | 0% (26) | 100% (26) |
| tithe_marksman | 78% (18) | 67% (18) | 56% (18) | 44% (18) | 50% (18) | 67% (18) | 0% (18) | 89% (18) |

## Deaths (non-random)

- d2 The Vault Enumerator: 26
- d3 Choir Cantor Prime: 19
- d5 Iron Auditor: 16
- d2 bleeding: 12
- d2 confessor hound: 10
- d2 ghoul: 10
- d4 gilded idol: 7
- d4 Noonday Cantor Vael: 6
- d2 cultist of the false sun: 5
- d3 ghoul: 5
- d2 tithe bailiff: 5
- d3 bleeding: 5
- d3 penance flagellant: 4
- d2 armed audit clerk: 4
- d2 Fleet ghoul: 4
- d5 ossuary centurion: 4
- d1 bleeding: 4
- d4 ossuary wight: 4
- d3 brass chorister: 4
- d4 processional lancer: 3

Classification: {"attrition":88,"false_light_window":19,"healing_unused_or_too_slow":49,"no_healing_available":50,"underlevelled":5}

Deaths by depth: {"d1":14,"d2":87,"d3":43,"d4":33,"d5":25,"d6":7,"d7":2}

Victories (policy|ending): {"aggressive|return":2,"aggressive|serpent":49,"aggressive|unwritten":56,"baseline|serpent":42,"baseline|unwritten":68,"defensive|return":2,"defensive|serpent":46,"defensive|unwritten":50,"explorer|by_decree":3,"explorer|return":19,"explorer|serpent":51,"explorer|unwritten":25,"narrative|by_decree":7,"narrative|return":20,"narrative|serpent":48,"narrative|unwritten":21,"preserver|return":2,"preserver|serpent":54,"preserver|unwritten":47,"specialist|return":4,"specialist|serpent":72,"specialist|unwritten":59}

## Coverage

- talents_learned: 104/104
- talents_used: 55/104
- monsters_killed: 86/86
- floors_visited: 28/28
- threads_accepted: 24/24
- monsters never killed: 
- active talents never used: philosophers_loan, quiet_absolution, rite_blink, transmute_pain, unbroken_wall, unwork_chains, unyielding_march

Mean level on first entry to each depth (policy|depth): {"aggressive|d2":1.6,"aggressive|d3":4.1,"aggressive|d4":6.0,"aggressive|d5":7.9,"aggressive|d6":9.7,"aggressive|d7":11.4,"baseline|d2":1.6,"baseline|d3":4.1,"baseline|d4":6.0,"baseline|d5":8.0,"baseline|d6":9.7,"baseline|d7":11.4,"defensive|d2":1.5,"defensive|d3":4.0,"defensive|d4":5.9,"defensive|d5":7.8,"defensive|d6":9.5,"defensive|d7":11.1,"explorer|d1":2.2,"explorer|d2":4.9,"explorer|d3":8.7,"explorer|d4":12.1,"explorer|d5":15.5,"explorer|d6":18.8,"explorer|d7":22.2,"narrative|d1":2.2,"narrative|d2":4.6,"narrative|d3":7.5,"narrative|d4":9.5,"narrative|d5":11.6,"narrative|d6":14.4,"narrative|d7":18.0,"preserver|d2":1.6,"preserver|d3":4.1,"preserver|d4":6.0,"preserver|d5":7.9,"preserver|d6":9.7,"preserver|d7":11.4,"specialist|d2":1.6,"specialist|d3":4.1,"specialist|d4":6.0,"specialist|d5":8.0,"specialist|d6":9.7,"specialist|d7":11.4}

Optional-content counters: {"branch|enter:archive_stair_annex":151,"branch|enter:audit_cisterns":131,"branch|enter:back_courts_undercroft":189,"branch|enter:cage_oubliette":89,"branch|enter:censer_foundry":135,"branch|enter:closed_stacks_vault":107,"branch|enter:day_house_cellars":186,"branch|enter:debts_cathedral":118,"branch|enter:gilded_cloister":103,"branch|enter:hidden_assembly_catacomb":106,"branch|enter:ophite_seam_hollow":104,"branch|enter:preliator_garrison":133,"branch|enter:processional_underway":147,"branch|enter:seal_foundry_deep":109,"branch|enter:shut_chapel_crypt":197,"branch|enter:sun_house_furnaces":117,"branch|enter:tithe_road_tunnels":168,"branch|enter:unrecorded_market_seams":139,"branch|enter:unwritten_margin":86,"branch|enter:velvet_ossuary":117,"branch|enter:witness_hermitage":90,"branch|leave:archive_stair_annex":160,"branch|leave:audit_cisterns":140,"branch|leave:back_courts_undercroft":22018,"branch|leave:cage_oubliette":267,"branch|leave:censer_foundry":103,"branch|leave:closed_stacks_vault":104,"branch|leave:day_house_cellars":186,"branch|leave:debts_cathedral":119,"branch|leave:gilded_cloister":88,"branch|leave:hidden_assembly_catacomb":92,"branch|leave:ophite_seam_hollow":105,"branch|leave:preliator_garrison":110,"branch|leave:processional_underway":4024,"branch|leave:seal_foundry_deep":121,"branch|leave:shut_chapel_crypt":198,"branch|leave:sun_house_furnaces":131,"branch|leave:tithe_road_tunnels":186,"branch|leave:unrecorded_market_seams":113,"branch|leave:unwritten_margin":95,"branch|leave:velvet_ossuary":120,"branch|leave:witness_hermitage":100,"consumable|abyssal_shard_dart":22,"consumable|almoners_ration":105,"consumable|apostate_wine":14,"consumable|barbed_dart":79,"consumable|bone_tincture":39,"consumable|cinder_flask":540,"consumable|clarion_drops":12,"consumable|dayhouse_broth_phial":31,"consumable|eye_bright_water":30,"consumable|false_sun_prism":134,"consumable|healing_salve":756,"consumable|hoarfrost_bomb":5,"consumable|iron_bark_tonic":5,"consumable|javelin":696,"consumable|lamp_oil_sip":9,"consumable|marrow_cordial":5,"consumable|ossuary_rime_vial":437,"consumable|pitch_fire_bead":8,"consumable|quicksilver_sip":35,"consumable|salt_shrapnel_bomb":62,"consumable|sanctuary_dew_flask":106,"consumable|sanctuary_poultice":10,"consumable|scroll_of_abyssal_lance":11,"consumable|scroll_of_identify":703,"consumable|scroll_of_map_reveal":6,"consumable|scroll_of_phase_step":73,"consumable|scroll_of_unbind":69,"consumable|silver_spike":18,"consumable|snare_bolas":225,"consumable|sunflare_capsule":9,"consumable|throwing_knife":952,"consumable|veil_drop_phial":1,"consumable|vial_of_false_light":580,"consumable|wormwood_salt":15,"contract_broken|the_crown_taken":32,"contract_fulfilled|the_crown_taken":33,"contract_signed|the_crown_taken":93,"entangled|depth2":1,"entangled|depth3":6,"entangled|depth4":7,"entangled|depth5":4,"entangled|depth6":1,"entangled|depth7":2,"gate|by_name":5133,"gate|given_back":221,"gate|stormed":1,"interact|abandoned_rite:default":2,"interact|abandoned_rite:dismantle":327,"interact|altar:cleanse":16,"interact|altar:default":9,"interact|altar:tithe":133,"interact|challenge:default":130,"interact|contract_lectern:sign":93,"interact|echo_cache:read":350,"interact|merchant:buy":205,"interact|npc:default":44,"interact|npc:pledge":802,"interact|npc:service":2100,"interact|npc:talk":2075,"interact|npc:thread_accept":205,"interact|ritual_circle:attest":5,"interact|ritual_circle:drain":1,"interact|ritual_circle:inscribe":163,"interact|rune_puzzle:default":1,"interact|rune_puzzle:solve_order":337,"interact|sanctuary_hearth:default":3,"interact|sanctuary_hearth:rest_quiet":2,"interact|shrine:default":9,"interact|shrine:witness":539,"interact|vault_gate:force":26,"interact|vault_gate:key":422,"narrative|travel:down":295,"narrative|travel:portal":26346,"narrative|travel:up":79255,"relic_transmuted|almoners_purse":165,"relic_transmuted|archive_lens":26,"relic_transmuted|ash_reliquary_box":1,"relic_transmuted|broken_halo":64,"relic_transmuted|cantors_fork":14,"relic_transmuted|confessors_glass":130,"relic_transmuted|counterfeit_sun_coin":32,"relic_transmuted|ophite_key":314,"relic_transmuted|penitents_scourge":92,"relic_transmuted|salt_hourglass":38,"relic_transmuted|severed_crown":56,"relic_transmuted|unwritten_ledger_leaf":2,"relic_transmuted|ward_keepers_lamp":138,"relic_transmuted|warden_portcullis_seal":25,"relic_worked|ophite_key":1901,"thread_abandoned|ash_canticle_embers":5,"thread_abandoned|binder_malakor_codex":3,"thread_abandoned|cistern_catch_basin":103,"thread_abandoned|cut_stamp_closed_stacks":29,"thread_abandoned|dayhouse_soup_kettle":38,"thread_abandoned|forge_cyrus_hammer":5,"thread_abandoned|foundry_slag_debt":2,"thread_abandoned|hermitage_silent_vow":15,"thread_abandoned|hide_from_procession":57,"thread_abandoned|honest_blade_inspection":9,"thread_abandoned|loose_stitch_back_courts":15,"thread_abandoned|margin_unwritten_scroll":64,"thread_abandoned|marginalia_of_the_shut":24,"thread_abandoned|market_short_measure":37,"thread_abandoned|mute_choir_rehearsal":31,"thread_abandoned|night_cart_detour":208,"thread_abandoned|ophite_hollow_vigil":62,"thread_abandoned|oubliette_key_weight":63,"thread_abandoned|readers_locked_chest":13,"thread_abandoned|shuttered_lamp_oil":29,"thread_abandoned|tallyman_erased_row":38,"thread_abandoned|unfiled_census_leaf":9,"thread_abandoned|unopened_door_wren":6,"thread_abandoned|velvet_appraiser_seal":9,"thread_settled|ash_canticle_embers:goal":62,"thread_settled|binder_malakor_codex:goal":51,"thread_settled|cistern_catch_basin:goal":42,"thread_settled|cut_stamp_closed_stacks:goal":5,"thread_settled|forge_cyrus_hammer:goal":50,"thread_settled|foundry_slag_debt:goal":28,"thread_settled|hermitage_silent_vow:goal":33,"thread_settled|honest_blade_inspection:goal":68,"thread_settled|loose_stitch_back_courts:goal":32,"thread_settled|margin_unwritten_scroll:goal":12,"thread_settled|market_short_measure:goal":6,"thread_settled|mute_choir_rehearsal:goal":11,"thread_settled|night_cart_detour:goal":91,"thread_settled|ophite_hollow_vigil:goal":3,"thread_settled|oubliette_key_weight:goal":16,"thread_settled|shuttered_lamp_oil:goal":18,"thread_settled|tallyman_erased_row:goal":26,"thread_settled|unfiled_census_leaf:goal":16,"thread_settled|unopened_door_wren:goal":4,"thread_settled|velvet_appraiser_seal:goal":15,"victory|by_decree":10,"victory|return":49,"victory|serpent":362,"victory|unwritten":326}

Suspect pairs (adaptive sampling): ashborn/rite_weaver, cambion/false_light_alchemist, human/fallen_knight, human/ophite_binder, penitent/false_light_alchemist, penitent/preliator_warden, penitent/rite_weaver, penitent/tithe_marksman, revenant/rite_weaver, unrecorded/rite_weaver, veilkin/ophite_binder, veilkin/rite_weaver
