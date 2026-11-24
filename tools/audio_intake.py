#!/usr/bin/env python3
"""Real sound in, from a phone. Duff uploads a file into assets/audio/inbox/<where it came from>/
(elevenlabs, suno, other) named after the sound it should be: click.mp3 becomes the game's "click".
This turns each upload into assets/audio/<name>.ogg, levels it, removes the placeholder .wav of the
same name and logs it in assets/audio/SOURCES.md. Audio.sfx/music pick the .ogg up with no code change.

  python3 tools/audio_intake.py            convert everything in the inbox (CI: audio_intake.yml)
  python3 tools/audio_intake.py --report   which sounds are still placeholders, which need a licence

Needs ffmpeg + ffprobe. Sound effects: silence trimmed off both ends, mono, peak at -2 dB.
Music (name starts with music_): stereo, about -16 LUFS, never trimmed (a loop must keep its length).
Ogg because it loops without a gap; mp3 doesn't."""
import datetime, json, os, re, subprocess, sys

AUDIO = "assets/audio"
INBOX = AUDIO + "/inbox"
SOURCES = AUDIO + "/SOURCES.md"
TYPES = (".mp3", ".wav", ".ogg", ".m4a", ".flac", ".aac", ".opus")
CLIPS = (".ogg", ".mp3", ".wav")            # what Audio.find_clip looks for, same order
MAX_BYTES = 25 * 1024 * 1024
PEAK_DB = -2.0                              # headroom: ogg encoding overshoots a little
MUSIC_LUFS = -16.0
PLACEHOLDER = "tools/gen_audio.py"
LICENCES = {
    "elevenlabs": "ElevenLabs plan terms on the day added (free plan: no commercial use, credit ElevenLabs)",
    "suno": "Suno plan terms on the day added (free plan: no commercial use)",
}
FILL = "FILL IN before release"
HEAD = """# Audio sources
One row per sound. Placeholders are synthesized by `tools/gen_audio.py` (original, no licence).
Real clips are added by `tools/audio_intake.py` (docs/AUDIO.md), which writes their row.
A row that says "%s" must be fixed before the game is sold.

| Sound | File | Source | Licence | Added |
|---|---|---|---|---|
""" % FILL


def run(args):
    return subprocess.run(args, capture_output=True, text=True)


def sound_name(filename):
    """'Sword Hit (2).MP3' -> 'sword_hit_2'. The name is what game code passes to Audio.sfx()."""
    stem = os.path.splitext(os.path.basename(filename))[0].lower()
    return re.sub(r"[^a-z0-9]+", "_", stem).strip("_")


def read_rows(path=SOURCES):
    rows = {}
    if os.path.exists(path):
        for line in open(path, encoding="utf-8"):
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) == 5 and cells[0] not in ("Sound", "---") and not set(cells[0]) <= set("-"):
                rows[cells[0]] = cells
    return rows


def write_rows(rows, path=SOURCES):
    with open(path, "w", encoding="utf-8") as f:
        f.write(HEAD)
        for name in sorted(rows):
            f.write("| " + " | ".join(rows[name]) + " |\n")


def measure(path):
    """(loudness in LUFS or None for a clip too short to rate, peak dB, seconds); None = unreadable or silent."""
    p = run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path])
    try:
        seconds = float(p.stdout.strip())
    except ValueError:
        return None
    m = run(["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-af", "volumedetect,loudnorm=print_format=json",
             "-f", "null", "-"])
    peak = re.search(r"max_volume: (-?[0-9.]+) dB", m.stderr)
    if seconds <= 0 or not peak or float(peak.group(1)) < -80.0:
        return None
    loud = re.search(r"\"input_i\"\s*:\s*\"(-?[0-9.]+)\"", m.stderr)
    return (float(loud.group(1)) if loud else None), float(peak.group(1)), seconds


def convert(src, dst, music):
    """Writes dst (.ogg). Returns "" when fine, else why not."""
    tmp = dst + ".trim.wav"
    trim = "silenceremove=start_periods=1:start_threshold=-50dB"
    pre = [] if music else ["-af", "%s,areverse,%s,areverse" % (trim, trim)]
    p = run(["ffmpeg", "-loglevel", "error", "-y", "-i", src, "-vn"] + pre + [tmp])
    if p.returncode != 0 or not os.path.exists(tmp):
        if os.path.exists(tmp):
            os.remove(tmp)
        return "ffmpeg could not read it"
    m = measure(tmp)
    if m is None:
        os.remove(tmp)
        return "silent or empty"
    loud, peak, _ = m
    gain = PEAK_DB - peak                                   # sound effects: as loud as the headroom allows
    if music and loud is not None:
        gain = min(MUSIC_LUFS - loud, gain)                 # music: a steady level, never past the peak
    lev = dst + ".level.wav"                               # level first, encode second: doing both in one
    p = run(["ffmpeg", "-loglevel", "error", "-y", "-i", tmp, "-af", "volume=%.2fdB" % gain,   # ffmpeg call clipped
             "-ac", "2" if music else "1", "-ar", "44100", "-c:a", "pcm_s16le", lev])
    if p.returncode != 0:
        for f in (tmp, lev):
            if os.path.exists(f):
                os.remove(f)
        return "ffmpeg could not level it"
    p = run(["ffmpeg", "-loglevel", "error", "-y", "-i", lev, "-c:a", "libvorbis", "-q:a", "5", "-f", "ogg", dst])
    for f in (tmp, lev):
        if os.path.exists(f):
            os.remove(f)
    if p.returncode != 0 or not os.path.exists(dst) or os.path.getsize(dst) == 0:
        return "ffmpeg could not write the ogg"
    return ""


def intake(root=".", today=None):
    """Converts every upload under <root>/assets/audio/inbox. Returns (done, skipped) lists of text lines."""
    today = today or datetime.date.today().isoformat()
    audio, inbox, sources = (os.path.join(root, p) for p in (AUDIO, INBOX, SOURCES))
    rows = read_rows(sources)
    done, skipped = [], []
    # Two uploads for one sound name: convert neither, every run, until Duff deletes one. Picking one
    # would let the other replace it on the next run.
    names = {}
    for folder, _, files in os.walk(inbox):
        for fn in files:
            if fn.lower().endswith(TYPES) and sound_name(fn):
                names.setdefault(sound_name(fn), []).append(os.path.relpath(os.path.join(folder, fn), inbox))
    for folder, _, files in sorted(os.walk(inbox)):
        for fn in sorted(files):
            src = os.path.join(folder, fn)
            rel = os.path.relpath(src, inbox)
            if not fn.lower().endswith(TYPES):
                if fn not in ("README.md", ".gdignore", ".gitkeep"):
                    skipped.append("%s: not a sound file (%s)" % (rel, ", ".join(TYPES)))
                continue
            name = sound_name(fn)
            if not name:
                skipped.append("%s: the file name has no letters or numbers" % rel)
                continue
            if len(names[name]) > 1:
                skipped.append("%s: %d uploads are named \"%s\" (%s); delete all but one" % (
                    rel, len(names[name]), name, ", ".join(sorted(names[name]))))
                continue
            if os.path.getsize(src) > MAX_BYTES:
                skipped.append("%s: over 25 MB" % rel)
                continue
            dst = os.path.join(audio, name + ".ogg")
            why = convert(src, dst + ".new.ogg", name.startswith("music_"))
            if why:
                if os.path.exists(dst + ".new.ogg"):
                    os.remove(dst + ".new.ogg")
                skipped.append("%s: %s" % (rel, why))
                continue
            was = rows.get(name)
            for ext in CLIPS:                # the old clip of this name goes, with its .import
                for old in (os.path.join(audio, name + ext), os.path.join(audio, name + ext + ".import")):
                    if os.path.exists(old):
                        os.remove(old)
            os.replace(dst + ".new.ogg", dst)
            os.remove(src)
            where = os.path.relpath(folder, inbox).split(os.sep)[0].lower()
            where = "unknown" if where == "." else where
            rows[name] = [name, name + ".ogg", "%s (uploaded as %s)" % (where, fn.replace("|", "_")),
                          LICENCES.get(where, FILL), today]
            kind = "replaced the placeholder" if was and was[2] == PLACEHOLDER else ("replaced the old clip" if was else "new sound")
            secs = measure(dst)
            done.append("%s.ogg: %s, %.1f s, %d KB, from %s" % (name, kind, secs[2] if secs else 0.0,
                                                               os.path.getsize(dst) // 1024, where))
    if done:
        write_rows(rows, sources)
    return done, skipped


def report(root="."):
    """Lines for Duff + a list of problems (a clip with no row, a row with no clip)."""
    audio = os.path.join(root, AUDIO)
    rows = read_rows(os.path.join(root, SOURCES))
    clips = {}
    for fn in sorted(os.listdir(audio)):
        if fn.lower().endswith(CLIPS):
            clips.setdefault(os.path.splitext(fn)[0], fn)
    problems = ["%s has no row in SOURCES.md" % clips[n] for n in clips if n not in rows]
    problems += ["SOURCES.md lists %s but there is no such clip" % n for n in rows if n not in clips]
    place = [n for n in rows if rows[n][2] == PLACEHOLDER and n in clips]
    fill = [n for n in rows if rows[n][3] == FILL]
    lines = ["%d sounds: %d real, %d still placeholder" % (len(clips), len(clips) - len(place), len(place))]
    if place:
        lines.append("Placeholder: " + ", ".join(place))
    if fill:
        lines.append("Licence missing (fix before selling): " + ", ".join(fill))
    return lines, problems


def main(argv):
    if "--report" in argv:
        lines, problems = report()
        print("\n".join(lines + ["PROBLEM: " + p for p in problems]))
        return 1 if problems else 0
    done, skipped = intake()
    for d in done:
        print("ADDED " + d)
    for s in skipped:
        print("SKIPPED " + s)
    if not done and not skipped:
        print("inbox empty")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
