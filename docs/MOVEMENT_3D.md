# Full range of movement (house standard for every 3D game)

Duff's rule (Nov 20, 2026): characters move like characters. Real-time 3D models on a real
skeleton, playing real animation clips: walk, run, punch, dodge, get hit, die. Working example:
`scenes/character_test.tscn` (dev menu -> 3D CHARACTER TEST). Autoplay proves it on every push.

## Never fake movement
- No bobbing, tilting, squashing or sliding a still image to stand in for walking or attacking.
- No flipbook of 2-3 painted frames for a moving character in a 3D game.
- If a move has no clip yet, the character doesn't do that move yet. Placeholder = the mannequin
  doing the real clip, never a still doing a fake one.
- (2D sprite games keep sprite sheets; this standard is for games with a 3D view.)

## The pieces
| Piece | Where | Notes |
|---|---|---|
| Character node | `scripts/character3d.gd` (`Character3D`) | CharacterBody3D + model + AnimationTree built in code |
| Shared skeleton + clips | `assets/models/ual1_standard.glb` | Quaternius Universal Animation Library 1, CC0. 65 bones, UE5 mannequin names (`pelvis`, `thigh_l`, `foot_l`, `hand_r`...) |
| Toon look | `shaders/toon.gdshader` | hard light bands (`bands` 3), shade floor, rim light (`rim_strength`) |
| Ink outline | `shaders/outline.gdshader` | inverted hull, constant width in pixels (`width_px` 3) |
| Proof | `scripts/autoplay.gd` | MOVE360 / LIMBS / ACTION / DODGE / DEATH / INK PASS lines |

## How a character moves
- `move_input` is a stick: any direction, 360 degrees, length = how fast. The body accelerates
  (`accel`), turns toward where it is going (`turn_speed`), never snaps.
- Locomotion is one BlendSpace1D by real ground speed: Idle 0 -> Walk 1.6 -> Jog_Fwd 3.6 ->
  Sprint 6.0 m/s. Feet match the floor because the clip follows the speed, not a timer.
- Actions are OneShots over the locomotion: `act("punch" | "cross" | "dodge" | "hit")`.
  A dodge (Roll) carries the body forward. `die()` / `revive()` switch to Death01 and back.
- Add a move: put the clip name in `ACTIONS`, call `act()`, add a PASS line to autoplay.

## Clips in UAL1 (all on the same skeleton)
Idle, Walk, Walk_Formal, Jog_Fwd, Sprint, Crouch_Idle, Crouch_Fwd, Jump_Start, Jump, Jump_Land,
Roll, Punch_Jab, Punch_Cross, Sword_Idle, Sword_Attack, Hit_Chest, Hit_Head, Death01, Interact,
PickUp_Table, Push, Sitting_*, Swim_*, Pistol_*, Spell_Simple_*, Dance, Driving, Idle_Talking,
Idle_Torch, Fixing_Kneeling. **No kick in UAL1**: get one from UAL2 (same skeleton, CC0) when a
game needs it, add it to `assets/models/SOURCES.md`.

## New character (keep the skeleton, swap the body)
1. Model it (or generate it) as a humanoid in T- or A-pose, **under ~5k triangles** (phones),
   one material or a small palette texture. Faceless/simple shapes read best under the toon shader.
2. Rig it to the UE5 mannequin bone names (Mixamo-style rigs work too, see 3).
3. Drop the `.glb` in `assets/models/`. If its bones have other names: in Godot's Import dock
   choose the Skeleton3D -> Retarget -> Bone Map -> `SkeletonProfileHumanoid`, then use the same
   profile on `ual1_standard.glb`, so every clip plays on both. (Done on the phone editor too.)
4. `Character3D.new()`, set `model_path`, `tint`, `rim` (hero only), add to the scene.
5. Autoplay: the LIMBS check must pass for it (a foot really travels), INK for its surfaces.
Quick variants without a new model: `tint` recolours the mannequin (the test dummy is red).
The mannequin itself is ~13.7k tris: fine for one or two on screen, replace it for crowds.

## Look
- Toon: 3 light bands, shadows never darker than `shade_floor` 0.35, so silhouettes stay readable
  on a phone in daylight.
- Ink outline 3 px on every character surface. Props may skip it; characters never do.
- Rim light: hero only (`rim` ~1.4, warm), so the player finds themself at a glance.
- Renderer: Compatibility (phones + iPhone Safari). `low_graphics` turns off real-time shadows.

## Camera and controls (phone portrait)
- Fixed high three-quarter camera, ~50 degrees down, ~7.5 m back, follows with a little
  look-ahead in the walking direction. No free camera to manage with one thumb.
- Floating stick: put a thumb down anywhere on the move half of the screen, drag (90 px = full
  speed). Action buttons on the other thumb, >= 72 base units tall, 18 apart. Left-handed setting
  swaps the halves. WASD/arrows + J/K on keyboard.

## Hit feel (when a game adds combat)
On a landed hit: ~60 ms hit-stop (freeze both bodies), white flash on the hit body, small camera
shake, the target plays Hit_Chest/Hit_Head, a buzz (`UI.buzz`). The punch must reach: check
distance + facing, not the button press alone.
