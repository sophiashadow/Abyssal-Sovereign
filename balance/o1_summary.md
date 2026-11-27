# M7 soak summary (768 runs)

## Policies

| policy | n | win | mean depth | mean level | mean turns |
|---|---|---|---|---|---|
| aggressive | 192 | 67.7% | 5.79 | 10.6 | 730 |
| baseline | 192 | 71.9% | 5.99 | 11.0 | 792 |
| defensive | 192 | 64.6% | 5.50 | 9.7 | 638 |
| specialist | 192 | 83.3% | 6.30 | 11.7 | 647 |

## Calling x policy (win rate, n)

| calling | aggressive | baseline | defensive | specialist |
|---|---|---|---|---|
| assassin | 75% (24) | 83% (24) | 79% (24) | 83% (24) |
| fallen_knight | 75% (24) | 79% (24) | 83% (24) | 83% (24) |
| false_light_alchemist | 92% (24) | 96% (24) | 92% (24) | 100% (24) |
| occultist | 58% (24) | 71% (24) | 71% (24) | 58% (24) |
| ophite_binder | 50% (24) | 42% (24) | 29% (24) | 75% (24) |
| preliator_warden | 88% (24) | 83% (24) | 71% (24) | 79% (24) |
| rite_weaver | 33% (24) | 42% (24) | 38% (24) | 92% (24) |
| tithe_marksman | 71% (24) | 79% (24) | 54% (24) | 96% (24) |

## Deaths (non-random)

- d2 The Vault Enumerator: 38
- d3 Choir Cantor Prime: 17
- d2 bleeding: 14
- d2 confessor hound: 13
- d2 ghoul: 10
- d4 Noonday Cantor Vael: 9
- d4 ossuary wight: 7
- d4 gilded idol: 5
- d1 bleeding: 4
- d4 Crimson ossuary wight: 4
- d2 cultist of the false sun: 4
- d1 tithe bailiff: 3
- d1 warren rat: 3
- d2 catalogued dead: 3
- d3 ghoul: 3
- d7 Preliator Sentinel: 3
- d3 bleeding: 3
- d2 Fleet ghoul: 3
- d4 bleeding: 3
- d3 penance flagellant: 3

Classification: {"attrition":72,"false_light_window":21,"healing_unused_or_too_slow":34,"no_healing_available":59,"underlevelled":5}

Deaths by depth: {"d1":10,"d2":93,"d3":33,"d4":38,"d5":10,"d6":3,"d7":4}

Victories (policy|ending): {"aggressive|return":4,"aggressive|serpent":56,"aggressive|unwritten":70,"baseline|return":5,"baseline|serpent":61,"baseline|unwritten":72,"defensive|return":4,"defensive|serpent":53,"defensive|unwritten":67,"specialist|return":12,"specialist|serpent":71,"specialist|unwritten":77}

## Coverage

- talents_learned: 92/104
- talents_used: 43/104
- monsters_killed: 38/86
- floors_visited: 7/28
- threads_accepted: 10/24
- monsters never killed: alley_rat_matriarch, apostate_knight, archivist_severin, ash_reliquary, back_court_rat_king, binder_malakor, blind_mole_brute, blinded_witness, bond_wraith, bone_hoarder, brass_automaton, censer_elemental, chapel_penitent_warden, cistern_eel, commander_voss, crux_halberdier, ember_beetle, forge_warden_cyrus, furnace_drake, garrison_crossbowman, geometry_spider, glare_moth, grate_skitterer, heresy_tracker, jailer_of_the_seventh, kiln_brazen, ledger_wyrm, margin_stalker, marrow_leech, marshal_krell, master_smelter_prosay, miasma_spore, mire_lurker, noonday_echo, oath_debtor, ophite_construct, pact_serpent, prism_lynx, rime_slime, runaway_almoner, seal_golem, sealer_captain, seepage_toad, sepulcher_shade, tithe_homunculus, tomb_siren, unsealed_scribe, void_moth
- active talents never used: backstep, chain_reversal, fade_to_ash, flurry, margin_collapse, philosophers_loan, pinning_volley, quiet_absolution, rite_blink, shadow_step, siege_breaker, slip_the_margin, solar_distillate, transmute_pain, unbroken_wall, unmake_record, unwork_chains, unyielding_march, vault_step

Mean level on first entry to each depth (policy|depth): {"aggressive|d2":1.6,"aggressive|d3":4.1,"aggressive|d4":6.1,"aggressive|d5":8.1,"aggressive|d6":10.0,"aggressive|d7":11.7,"baseline|d2":1.6,"baseline|d3":4.1,"baseline|d4":6.1,"baseline|d5":8.1,"baseline|d6":9.9,"baseline|d7":11.6,"defensive|d2":1.5,"defensive|d3":4.0,"defensive|d4":6.0,"defensive|d5":8.0,"defensive|d6":9.7,"defensive|d7":11.3,"specialist|d2":1.6,"specialist|d3":4.1,"specialist|d4":6.1,"specialist|d5":8.1,"specialist|d6":9.9,"specialist|d7":11.6}

Optional-content counters: {"consumable|abyssal_shard_dart":15,"consumable|apostate_wine":3,"consumable|barbed_dart":4,"consumable|bone_tincture":29,"consumable|cinder_flask":300,"consumable|clarion_drops":14,"consumable|dayhouse_broth_phial":5,"consumable|false_sun_prism":114,"consumable|healing_salve":468,"consumable|iron_bark_tonic":4,"consumable|javelin":389,"consumable|lamp_oil_sip":7,"consumable|marrow_cordial":2,"consumable|ossuary_rime_vial":165,"consumable|quicksilver_sip":16,"consumable|salt_shrapnel_bomb":15,"consumable|sanctuary_poultice":12,"consumable|scroll_of_identify":104,"consumable|scroll_of_unbind":12,"consumable|silver_spike":20,"consumable|sunflare_capsule":8,"consumable|throwing_knife":485,"consumable|vial_of_false_light":289,"consumable|wormwood_salt":9,"contract_broken|the_crown_taken":1,"contract_broken|the_taken_name":4,"contract_broken|vow_of_poverty":1,"contract_fulfilled|the_crown_taken":6,"contract_fulfilled|the_fast":1,"contract_fulfilled|vow_of_poverty":6,"contract_signed|the_crown_taken":12,"contract_signed|the_fast":1,"contract_signed|the_taken_name":5,"contract_signed|vow_of_poverty":8,"entangled|depth2":1,"entangled|depth3":7,"entangled|depth4":14,"entangled|depth5":4,"gate|by_name":3756,"gate|given_back":5,"interact|abandoned_rite:dismantle":69,"interact|altar:cleanse":1,"interact|altar:tithe":78,"interact|challenge:default":14,"interact|contract_lectern:sign":26,"interact|echo_cache:read":53,"interact|merchant:buy":46,"interact|npc:service":137,"interact|npc:talk":137,"interact|ritual_circle:attest":1,"interact|ritual_circle:inscribe":53,"interact|rune_puzzle:solve_order":37,"interact|sanctuary_hearth:rest_quiet":2,"interact|shrine:witness":84,"interact|vault_gate:key":11,"relic_transmuted|almoners_purse":23,"relic_transmuted|broken_halo":56,"relic_transmuted|cantors_fork":11,"relic_transmuted|confessors_glass":40,"relic_transmuted|counterfeit_sun_coin":19,"relic_transmuted|ophite_key":138,"relic_transmuted|severed_crown":51,"relic_transmuted|ward_keepers_lamp":35,"relic_transmuted|warden_portcullis_seal":15,"retreat|taken":1,"thread_abandoned|cistern_catch_basin":52,"thread_abandoned|hermitage_silent_vow":1,"thread_abandoned|hide_from_procession":2,"thread_abandoned|loose_stitch_back_courts":4,"thread_abandoned|margin_unwritten_scroll":14,"thread_abandoned|night_cart_detour":201,"thread_abandoned|ophite_hollow_vigil":19,"thread_abandoned|unfiled_census_leaf":1,"thread_abandoned|velvet_appraiser_seal":3,"thread_settled|tallyman_erased_row:goal":10,"victory|return":25,"victory|serpent":241,"victory|unwritten":286}

Suspect pairs (adaptive sampling): cambion/false_light_alchemist, cambion/preliator_warden, human/fallen_knight, human/false_light_alchemist, human/occultist, human/ophite_binder, human/preliator_warden, unrecorded/assassin, unrecorded/rite_weaver, veilkin/false_light_alchemist, veilkin/ophite_binder, veilkin/rite_weaver
