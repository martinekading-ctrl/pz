# Survivor jog motion

- Recording: Carnegie Mellon University Graphics Lab Motion Capture Database, subject 02, trial 03 (`run/jog`).
- Original database and usage terms: https://mocap.cs.cmu.edu/
- FBX conversion: RancidMilk, *Massive Library of Free 3D Character Animations*, Anims_Only FBX V1; the single `02_03.fbx` file was obtained from https://huggingface.co/datasets/gbionics/cmu-fbx/blob/main/animations/02_03.fbx .
- Converter's terms: https://rancidmilk.itch.io/free-character-animations . The motion may be used and modified in a game, including a commercial game. Do not sell the motion data itself, including a converted or retargeted copy. Preserve these terms when redistributing the source file.
- CMU's requested acknowledgment: “The data used in this project was obtained from mocap.cs.cmu.edu. The database was created with funding from NSF EIA-0196217.”
- Project adaptation: `tools/retarget_cmu_run.gd` samples frames 41–131 of the 120 fps capture, removes horizontal root travel, applies the captured joint rotations to the project's existing 65-bone adult survivor, aligns facing, preserves vertical pelvis motion, and closes the loop. No replacement character model is included.
