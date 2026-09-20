# Character asset sources

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
