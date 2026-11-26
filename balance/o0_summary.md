# M7 soak summary (768 runs)

## Policies

| policy | n | win | mean depth | mean level | mean turns |
|---|---|---|---|---|---|
| aggressive | 192 | 65.6% | 5.65 | 10.3 | 695 |
| baseline | 192 | 69.8% | 5.86 | 10.8 | 758 |
| defensive | 192 | 62.5% | 5.43 | 9.6 | 619 |
| specialist | 192 | 82.8% | 6.28 | 11.7 | 651 |

## Calling x policy (win rate, n)

| calling | aggressive | baseline | defensive | specialist |
|---|---|---|---|---|
| assassin | 71% (24) | 79% (24) | 79% (24) | 88% (24) |
| fallen_knight | 67% (24) | 71% (24) | 67% (24) | 83% (24) |
| false_light_alchemist | 96% (24) | 96% (24) | 88% (24) | 100% (24) |
| occultist | 62% (24) | 62% (24) | 71% (24) | 58% (24) |
| ophite_binder | 46% (24) | 38% (24) | 25% (24) | 62% (24) |
| preliator_warden | 83% (24) | 92% (24) | 83% (24) | 83% (24) |
| rite_weaver | 33% (24) | 42% (24) | 38% (24) | 92% (24) |
| tithe_marksman | 67% (24) | 79% (24) | 50% (24) | 96% (24) |

## Deaths (non-random)

- d2 The Vault Enumerator: 37
- d2 bleeding: 16
- d3 Choir Cantor Prime: 16
- d2 cultist of the false sun: 10
- d2 ghoul: 10
- d2 confessor hound: 10
- d4 ossuary wight: 9
- d4 Noonday Cantor Vael: 7
- d1 bleeding: 5
- d4 gilded idol: 5
- d3 ghoul: 5
- d2 catalogued dead: 5
- d3 brass chorister: 4
- d2 Fleet ghoul: 3
- d4 Crimson ossuary wight: 3
- d1 warren rat: 3
- d3 penance flagellant: 3
- d5 Iron Auditor: 3
- d4 bleeding: 3
- d5 pendulum ward: 2

Classification: {"attrition":70,"false_light_window":29,"healing_unused_or_too_slow":40,"no_healing_available":63,"underlevelled":4}

Deaths by depth: {"d1":11,"d2":102,"d3":37,"d4":39,"d5":11,"d6":3,"d7":3}

Victories (policy|ending): {"aggressive|return":4,"aggressive|serpent":53,"aggressive|unwritten":69,"baseline|return":5,"baseline|serpent":61,"baseline|unwritten":68,"defensive|return":4,"defensive|serpent":51,"defensive|unwritten":65,"specialist|return":11,"specialist|serpent":71,"specialist|unwritten":77}

## Coverage

- talents_learned: 92/104
- talents_used: 44/104
- monsters_killed: 38/86
- floors_visited: 7/28
- threads_accepted: 10/24
- monsters never killed: alley_rat_matriarch, apostate_knight, archivist_severin, ash_reliquary, back_court_rat_king, binder_malakor, blind_mole_brute, blinded_witness, bond_wraith, bone_hoarder, brass_automaton, censer_elemental, chapel_penitent_warden, cistern_eel, commander_voss, crux_halberdier, ember_beetle, forge_warden_cyrus, furnace_drake, garrison_crossbowman, geometry_spider, glare_moth, grate_skitterer, heresy_tracker, jailer_of_the_seventh, kiln_brazen, ledger_wyrm, margin_stalker, marrow_leech, marshal_krell, master_smelter_prosay, miasma_spore, mire_lurker, noonday_echo, oath_debtor, ophite_construct, pact_serpent, prism_lynx, rime_slime, runaway_almoner, seal_golem, sealer_captain, seepage_toad, sepulcher_shade, tithe_homunculus, tomb_siren, unsealed_scribe, void_moth
- active talents never used: chain_reversal, fade_to_ash, flurry, margin_collapse, philosophers_loan, pinning_volley, quiet_absolution, rite_blink, shadow_step, siege_breaker, slip_the_margin, solar_distillate, transmute_pain, unbroken_wall, unmake_record, unwork_chains, unyielding_march, vault_step

Mean level on first entry to each depth (policy|depth): {"aggressive|d2":1.6,"aggressive|d3":4.1,"aggressive|d4":6.1,"aggressive|d5":8.1,"aggressive|d6":10.0,"aggressive|d7":11.6,"baseline|d2":1.6,"baseline|d3":4.1,"baseline|d4":6.1,"baseline|d5":8.1,"baseline|d6":9.9,"baseline|d7":11.6,"defensive|d2":1.5,"defensive|d3":4.0,"defensive|d4":6.0,"defensive|d5":8.0,"defensive|d6":9.7,"defensive|d7":11.3,"specialist|d2":1.6,"specialist|d3":4.2,"specialist|d4":6.1,"specialist|d5":8.1,"specialist|d6":9.9,"specialist|d7":11.6}

Optional-content counters: {"consumable|abyssal_shard_dart":15,"consumable|apostate_wine":4,"consumable|barbed_dart":3,"consumable|bone_tincture":23,"consumable|cinder_flask":288,"consumable|clarion_drops":16,"consumable|dayhouse_broth_phial":3,"consumable|false_sun_prism":111,"consumable|healing_salve":473,"consumable|iron_bark_tonic":4,"consumable|javelin":386,"consumable|lamp_oil_sip":7,"consumable|marrow_cordial":2,"consumable|ossuary_rime_vial":162,"consumable|quicksilver_sip":16,"consumable|salt_shrapnel_bomb":14,"consumable|sanctuary_poultice":12,"consumable|scroll_of_identify":104,"consumable|scroll_of_unbind":9,"consumable|silver_spike":16,"consumable|sunflare_capsule":8,"consumable|throwing_knife":480,"consumable|vial_of_false_light":282,"consumable|wormwood_salt":9,"contract_broken|the_crown_taken":1,"contract_broken|the_taken_name":6,"contract_broken|vow_of_poverty":1,"contract_fulfilled|the_crown_taken":6,"contract_fulfilled|the_fast":1,"contract_fulfilled|vow_of_poverty":6,"contract_signed|the_crown_taken":11,"contract_signed|the_fast":1,"contract_signed|the_taken_name":6,"contract_signed|vow_of_poverty":8,"entangled|depth2":1,"entangled|depth3":6,"entangled|depth4":11,"entangled|depth5":4,"gate|by_name":3684,"gate|given_back":6,"interact|abandoned_rite:dismantle":64,"interact|altar:cleanse":1,"interact|altar:tithe":75,"interact|challenge:default":11,"interact|contract_lectern:sign":26,"interact|echo_cache:read":50,"interact|merchant:buy":46,"interact|npc:service":133,"interact|npc:talk":134,"interact|ritual_circle:attest":1,"interact|ritual_circle:inscribe":57,"interact|rune_puzzle:solve_order":35,"interact|sanctuary_hearth:rest_quiet":3,"interact|shrine:witness":84,"interact|vault_gate:key":12,"relic_transmuted|almoners_purse":27,"relic_transmuted|broken_halo":54,"relic_transmuted|cantors_fork":12,"relic_transmuted|confessors_glass":44,"relic_transmuted|counterfeit_sun_coin":23,"relic_transmuted|ophite_key":136,"relic_transmuted|severed_crown":49,"relic_transmuted|ward_keepers_lamp":31,"relic_transmuted|warden_portcullis_seal":14,"retreat|taken":1,"thread_abandoned|cistern_catch_basin":52,"thread_abandoned|hermitage_silent_vow":1,"thread_abandoned|hide_from_procession":2,"thread_abandoned|loose_stitch_back_courts":4,"thread_abandoned|margin_unwritten_scroll":14,"thread_abandoned|night_cart_detour":198,"thread_abandoned|ophite_hollow_vigil":17,"thread_abandoned|tallyman_erased_row":1,"thread_abandoned|unfiled_census_leaf":1,"thread_abandoned|velvet_appraiser_seal":5,"thread_settled|tallyman_erased_row:goal":10,"victory|return":24,"victory|serpent":236,"victory|unwritten":279}

Suspect pairs (adaptive sampling): cambion/false_light_alchemist, cambion/preliator_warden, human/fallen_knight, human/false_light_alchemist, human/occultist, human/ophite_binder, human/preliator_warden, unrecorded/assassin, unrecorded/ophite_binder, unrecorded/rite_weaver, veilkin/fallen_knight, veilkin/false_light_alchemist, veilkin/ophite_binder, veilkin/rite_weaver
