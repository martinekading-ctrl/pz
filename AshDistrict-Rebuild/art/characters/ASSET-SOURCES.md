# Character asset sources

## Current runtime: Universal Base Characters + Universal Animation Library

- Creator: Quaternius; both free Standard downloads use CC0 1.0.
- Model source: https://quaternius.com/packs/universalbasecharacters.html
- Animation source: https://quaternius.com/packs/universalanimationlibrary.html
- Download pages: https://quaternius.itch.io/universal-base-characters and https://quaternius.itch.io/universal-animation-library
- Original licenses: `human_base/License_Standard.txt` and `human_base/License_Animation.txt`.
- Source meshes: Superhero_Male_FullBody and Hair_SimpleParted; source motions: UAL1_Standard.glb.
- Project modifications: adult height normalization, narrower torso, skinned clothing shell, recoloring, hair and backpack attachments, animation retargeting and armed upper-body poses.
- Generated runtime scenes: `human_base/survivor.scn` and `human_base/infected.scn`, rebuilt by `tools/build_human_characters.gd`.
- Infected `GrabBite` is project-authored skeletal keyframing (open-handed reach, head contact, recovery); the infected scene no longer includes the source boxing clip.
- `ZombieShuffle` is a project-edited derivative of the CC0 Walk animation: asymmetric stance timing, reduced leg lift, slumped torso and independently posed dangling arms. Player locomotion retains its own clips.
- The older Zombie Apocalypse models below are retained for rollback/reference, not current player/zombie runtime rendering.

## Quaternius Zombie Apocalypse Kit

- Source: https://quaternius.com/packs/zombieapocalypsekit.html
- Creator: Quaternius
- License: CC0 1.0 Universal
- Files included: `Characters_Matt.gltf`, `Zombie_Basic.gltf`, `Zombie_Atlas.png`
- Local purpose: player and zombie skinned meshes, humanoid skeletons and embedded animation clips
- Imported clips used by the game: Idle, Walk, Run, armed locomotion, Slash, Punch, HitReact, Jump and Death

Both glTF files embed their mesh, skin, animation and texture data. The separate
zombie atlas is retained as a source reference; runtime rendering uses the copy
embedded in the glTF. The original model files remain unchanged so Godot can
reproduce the import and their origin stays auditable.
