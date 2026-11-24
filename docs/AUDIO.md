# Audio pipeline (real sound, from a phone)

The game ships with placeholder beeps (`tools/gen_audio.py`). Real sound replaces them one file at a
time, with no code change: `Audio` plays `<name>.ogg` before the placeholder `<name>.wav`.

## Duff's steps (phone only)
1. Make the sound. Effects: ElevenLabs (Sound Effects). Music: Suno. Download it to the phone.
2. Rename it in the Files app to the sound's name: `click.mp3` replaces `click`. Music must start
   with `music_` (`music_loop.mp3`, `music_combat.mp3`). The names in use are in
   `assets/audio/SOURCES.md`; a new name adds a new sound for game code to call.
3. In the phone browser open the repo on github.com -> `assets/audio/inbox/` -> the folder for where
   it came from (`elevenlabs`, `suno`, `other`) -> Add file -> Upload files -> commit to main.
   No Upload button? Chrome menu -> Desktop site. Or send the file to Claude in chat and say which game.
4. Wait about 10 minutes. The `audio-intake` robot converts it, then the normal build makes a new
   dev APK; the game offers the update.

## What the robot does (`tools/audio_intake.py`, `.github/workflows/audio_intake.yml`)
- Converts to `.ogg` (loops without a gap; mp3 can't), 44.1 kHz.
- Sound effects: trims silence off both ends, mono, peak at -2 dB.
- Music (`music_*`): stereo, about -16 LUFS, never trimmed, loops by itself.
- Deletes the placeholder of the same name and the upload, writes the row in `SOURCES.md`
  (source, licence note, date), then starts `build.yml`.
- Skips and leaves in the inbox: silent files, files over 25 MB, anything that isn't sound, a second
  file for the same sound name. The run's summary on GitHub (Actions -> audio-intake) lists what
  was added and what was skipped. Delete a skipped file from the inbox, or it's flagged every run.
- `SOURCES.md` is rewritten each time: fix a licence inside its row; notes outside the table are lost.

## Rules
- `music_layers(explore, combat)` needs two loops of the same length and tempo. Make both from one
  Suno song (same length export), or the crossfade drifts.
- Licence: a free-plan ElevenLabs or Suno download can't be sold. Anything headed for a paid
  release is made on a paid plan; the `SOURCES.md` row records the day it was added. `other/` rows
  say "FILL IN before release" until someone writes the real licence in.
- What's still placeholder: `python3 tools/audio_intake.py --report`.
- Checks: `AUDIO INTAKE PASS` (`tools/test_audio_intake.py`, CI), `AUDIO PASS` (autoplay),
  `test_audio_prefers_real_clips` (rule tests).
