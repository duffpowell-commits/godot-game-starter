#!/usr/bin/env python3
"""Proves tools/audio_intake.py on a throwaway copy of assets/audio (needs ffmpeg): an uploaded mp3
replaces the placeholder of the same name, gets levelled, trimmed and logged; music stays stereo and
keeps its length; junk is skipped and left alone. Then checks the real repo: every clip in
assets/audio has a row in SOURCES.md. Prints AUDIO INTAKE PASS."""
import os, shutil, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import audio_intake as ai

bad = []
def check(ok, what):
    if not ok:
        bad.append(what)
        print("  failed: " + what)

def ff(*args):
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y"] + list(args), check=True)

def probe(path, entry):
    return subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries", entry,
                           "-of", "csv=p=0", path], capture_output=True, text=True).stdout.strip().strip(",")

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
root = tempfile.mkdtemp()
audio = os.path.join(root, ai.AUDIO)
os.makedirs(os.path.join(audio, "inbox", "elevenlabs"))
os.makedirs(os.path.join(audio, "inbox", "suno"))
os.makedirs(os.path.join(audio, "inbox", "other"))
for fn in os.listdir(os.path.join(repo, ai.AUDIO)):
    if os.path.isfile(os.path.join(repo, ai.AUDIO, fn)):
        shutil.copy(os.path.join(repo, ai.AUDIO, fn), audio)
check(os.path.exists(os.path.join(audio, "click.wav.import")), "fixture has the placeholder click and its .import")

# A quiet beep with half a second of silence on each side, the way generators hand them over.
ff("-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo", "-f", "lavfi", "-i", "sine=frequency=880:duration=0.3",
   "-filter_complex", "[0]atrim=0:0.5[a];[1]volume=0.1[b];[0]atrim=0:0.5[c];[a][b][c]concat=n=3:v=0:a=1",
   os.path.join(audio, "inbox", "elevenlabs", "Click.mp3"))
ff("-f", "lavfi", "-i", "sine=frequency=220:duration=4", "-af", "volume=0.05", "-ac", "2",
   os.path.join(audio, "inbox", "suno", "music_loop.mp3"))
ff("-f", "lavfi", "-i", "sine=frequency=500:duration=0.2", os.path.join(audio, "inbox", "other", "Door Creak (2).wav"))
ff("-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono", "-t", "1", os.path.join(audio, "inbox", "other", "silent.wav"))
ff("-f", "lavfi", "-i", "sine=frequency=300:duration=0.2", os.path.join(audio, "inbox", "other", "CLICK.wav"))
open(os.path.join(audio, "inbox", "other", "notes.txt"), "w").write("not a sound")

done, skipped = ai.intake(root, today="2026-01-02")
print("\n".join(done + skipped))
rows = ai.read_rows(os.path.join(root, ai.SOURCES))

check(len(done) == 3 and len(skipped) == 3, "3 converted, 3 skipped (got %d, %d)" % (len(done), len(skipped)))
check(os.path.exists(os.path.join(audio, "inbox", "other", "CLICK.wav")) and rows.get("click", [""] * 5)[2].startswith("elevenlabs"),
      "a second upload with the same sound name is skipped, not swapped in silently")
click = os.path.join(audio, "click.ogg")
check(os.path.exists(click), "click.ogg written")
check(not os.path.exists(os.path.join(audio, "click.wav")) and not os.path.exists(os.path.join(audio, "click.wav.import")),
      "placeholder click.wav and its .import removed")
check(os.path.exists(os.path.join(audio, "good.wav")), "untouched placeholder stays")
check(not os.path.exists(os.path.join(audio, "inbox", "elevenlabs", "Click.mp3")), "converted upload leaves the inbox")
if os.path.exists(click):
    m = ai.measure(click)
    check(m is not None and 0.2 < m[2] < 0.45, "silence trimmed off both ends (1.3 s -> %.2f s)" % (m[2] if m else -1))
    check(m is not None and -3.5 < m[1] < -0.5, "sound effect peaks near -2 dB (%.1f)" % (m[1] if m else 99))
    check(probe(click, "stream=channels") == "1", "sound effect is mono")
music = os.path.join(audio, "music_loop.ogg")
if os.path.exists(music):
    m = ai.measure(music)
    check(m is not None and abs(m[2] - 4.0) < 0.08, "music keeps its length (%.2f s)" % (m[2] if m else -1))
    check(m is not None and m[0] is not None and -17.5 < m[0] < -14.5, "music lands near -16 LUFS (%s)" % (m[0] if m else 99))
    check(m is not None and m[1] < -0.5, "music peak stays under 0 dB (%.1f)" % (m[1] if m else 99))
    check(probe(music, "stream=channels") == "2", "music stays stereo")
else:
    check(False, "music_loop.ogg written")
check(os.path.exists(os.path.join(audio, "door_creak_2.ogg")), "file name becomes a clean sound name")
check(rows.get("click", [""] * 5)[2].startswith("elevenlabs") and "ElevenLabs" in rows["click"][3] and rows["click"][4] == "2026-01-02",
      "click row says where it came from, the licence note and the date")
check(rows.get("door_creak_2", [""] * 5)[3] == ai.FILL, "unknown source is flagged to fill in")
check(rows.get("good", [""] * 5)[2] == ai.PLACEHOLDER, "placeholder rows survive the rewrite")
check(os.path.exists(os.path.join(audio, "inbox", "other", "silent.wav")) and not os.path.exists(os.path.join(audio, "silent.ogg")),
      "a silent upload is skipped and left in the inbox")
check(os.path.exists(os.path.join(audio, "inbox", "other", "notes.txt")), "a non-sound file is left alone")
lines, problems = ai.report(root)
check(not problems, "report finds every clip logged after an intake: %s" % problems)
os.remove(os.path.join(audio, "good.wav"))
check(len(ai.report(root)[1]) == 1, "report catches a row whose clip is gone")
shutil.rmtree(root)

lines, problems = ai.report(repo)
print("\n".join(lines))
check(not problems, "this repo: " + "; ".join(problems))

print("AUDIO INTAKE PASS" if not bad else "AUDIO INTAKE FAILED %d" % len(bad))
sys.exit(1 if bad else 0)
