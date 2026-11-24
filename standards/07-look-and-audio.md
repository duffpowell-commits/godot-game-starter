# Readability and audio (standards 5 and 6)

## The hero always reads
Hero rim light, a key light that only lights characters, no black-on-black. Contrast hero vs
floor >= 2:1 in normal light and in the dark. Check: `READ PASS`.

## Audio
- Footsteps from the animation, sound picked by surface (stone, wood, grass, water...); floors
  carry a `surface` tag.
- Music with an explore layer and a combat layer that crossfade in sync.
- Music ducks under important sounds.
Godot today: `Audio.step()`, `Audio.music_layers()`, `Audio.set_intensity()`, `Audio.duck()`.
Checks: `STEPS`, `MUSIC`, `DUCK PASS`.

## Real sound replaces placeholders without code changes
- A real clip has the placeholder's name; the game plays it instead. Every clip is levelled the same
  way (effects to one peak, music to one loudness) and logged with its source and licence.
Godot today: upload to `assets/audio/inbox/` (docs/AUDIO.md); `Audio` prefers `.ogg` over `.wav`.
Checks: `AUDIO PASS`, `AUDIO INTAKE PASS`.

## The player's own music keeps playing
- Never grab exclusive audio focus: on Android the game plays alongside Spotify etc. (Godot never
  requests focus; don't add a plugin that does). On iPhone the game mixes with other apps
  (`audio/general/ios/mix_with_others`).
- Settings -> GAME MUSIC: OFF mutes only the game's music; sound effects stay.
Check: `test_play_your_own_music`.
