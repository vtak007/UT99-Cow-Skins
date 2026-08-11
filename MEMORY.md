# UT99 Cow Skins — Project Memory

## CONFIRMED ROOT CAUSES

- IG+ swaps every player's class at login for its own `bb*` netcode class and
  only ships the five standard models; any other class (e.g. `MultiMesh.TCow`)
  falls back to **Male Commando**. The BP1H/BP4H handlers plug into IG+'s
  `PlayerPacks[]` mechanism to restore the Bonus Pack models.
- IG+ derives the handler package name it loads from its own `PackageVersion`
  (`BP1H<PackageVersion>` / `BP4H<PackageVersion>`). A handler compiled for a
  different IG+ build will not be found, so the models silently fall back.
  Therefore each IG+ update whose `PackageVersion` changes requires a rebuild.
- Server crash `Failed to load "BP1Hnext-netcode-ef237853": Can't find file`
  (from `server-old.log`, 2026-08-01) = the compiled handler `.u` was never
  uploaded to the server's `System\` folder. `ServerPackages` entries load the
  real `.u` from `System\`; the redirect only holds `.uz` for client download.
  Both destinations are required and are different places.
- "Server became Instagib instead of Deathmatch" after the IG+ update = the
  `?mutator=` start line loads IG+'s instagib weapon-replacement mutator
  (`NewNetIG`). Its presence forces instagib; with it absent, IG+ loads default
  UT weapons (= normal DM). Gametype itself was never wrong (`Game class is
  'DeathMatchPlus'`).
- **`PlayerPacks[]` can silently go blank** (recurrence 2026-08-10). The
  `PlayerPacks[0]=BP1` / `PlayerPacks[1]=BP4` entries in the server's
  `InstaGibPlus.ini` `[ServerSettings]` were empty. This fails **silently**:
  the handler `.u` files still load from `ServerPackages` and still replicate
  to clients, so nothing errors — IG+ simply never invokes them, and every
  custom class falls back to Male Commando. Cause (confirmed 2026-08-11):
  human error while hand-editing `InstaGibPlus.ini` to optimise other
  settings. IG+ does not blank these on its own.
  **First diagnostic for any "wrong model" report:** grep the startup log for
  `Bonus Pack 1 supported` / `Bonus Pack 4 supported`. Absent = `PlayerPacks[]`
  is the problem; no rebuild needed if the IG+ `PackageVersion` is unchanged.

## RULED-OUT THEORIES

- The BP1H/BP4H skin handlers do NOT affect gametype or weapons — they only
  swap player models. The instagib-vs-DM issue was entirely the `?mutator=`
  line, unrelated to the handler work.
- `InstaGibPlus_<ver>.Instagib` is NOT a real mutator class in this build.
  A raw string grep of the package matched `InstaGib` only as a substring of
  `InstaGibPlus` (false positive); the actual name-table mutator classes are
  `UTPure`, `ST_Mutator`, `NewNetIG`, `IGPlus_HitFeedback`. Putting
  `.Instagib` on the mutator line "works" only because it fails to load and is
  silently skipped, which drops `NewNetIG` and yields normal DM weapons.
  Prefer removing `NewNetIG` outright over relying on a bogus class name.
- A server-log skin error such as
  `Failed to load "Texture TCowMeshSkinscc.Gold1"` →
  `so load CommandoSkins.cmdo1` is **not** a missing or corrupt `.utx` on the
  server, and not a mismatch against the client's copy. Note the appended `1`:
  that numeric suffix comes from Botpack's **Male** `SetMultiSkin`, whereas
  `bbTCow.SetMultiSkin` (`bbTCow.uc:60`) passes the skin name verbatim to
  element 1. So the texture error is *downstream* of the class already having
  been downgraded to `bbTMale1` — a symptom, not a cause. Fix the class
  (see `PlayerPacks[]` above) and the texture error disappears. Do not go
  hunting for `.utx` files.
- Client-side `Force Default Models` being unchecked does not rule out a
  server-side model override; check `ForceModels=0` and `bForceModels=False`
  in `InstaGibPlus.ini`, then check the possessed pawn class in the log
  (`Log: Possessed PlayerPawn: <class>`), which is the authoritative answer.

## PROJECT CONVENTIONS

- **Current IG+ target: `next-netcode-ef237853`** (previous:
  `master-3e878ccf`). `build.bat` default and `README.md` reference this
  version. Confirmed by the `PackageVersion` string embedded in
  `InstaGibPlus_next-netcode-ef237853.u`.
- Handler package names for the current target:
  `BP1Hnext-netcode-ef237853` / `BP4Hnext-netcode-ef237853`.
- Build command: `build.bat "C:\UnrealTournament" InstaGibPlus_next-netcode-ef237853`
  (the version arg now defaults to this, so the arg is optional).
- Build inputs required in `<UT>\System`: the IG+ release set
  (`InstaGibPlus_<ver>.u`, `InstaGibPlusAssets_v2.u`, `BaseCylinder.u`,
  `BaseCylinder2.u`, `HeadCylinder.u`), stock GOTY `MultiMesh.u`,
  `EpicCustomModels.u`, `SkeletalChars.u`, plus `ucc.exe`; textures
  `TCowMeshSkins.utx`, `TNaliMeshSkins.utx`, `TSkMSkins.utx` in `<UT>\Textures`.
- `ServerPackages` must keep the stock `MultiMesh`, `EpicCustomModels`,
  `SkeletalChars`, `TCowMeshSkins`, `TNaliMeshSkins`, `TSkMSkins` entries — the
  BP1 handler refuses to load without `MultiMesh`.
- Success log lines on the server: `Bonus Pack 1 supported` /
  `Bonus Pack 4 supported`.
- `.uc` source only changes if IG+'s class hierarchy changes; a routine IG+
  version bump only changes the package **name/build target**.
- **IG+ mutators** (name-table classes in this build): `UTPure` (core +
  netcode/anti-cheat, no weapon change, always required), `NewNetIG` (instagib
  weapon replacement — its presence = instagib), `ST_Mutator` (per docs a
  weapon-replacement mutator, but the live server runs normal DM with it
  loaded, so it is not forcing instagib here — leave it), `IGPlus_HitFeedback`
  (HUD hit feedback). For **normal-weapons Deathmatch, do NOT load `NewNetIG`**.
- The two IG+ ini files: `InstaGibPlus.ini` `[ServerSettings]` holds the
  `PlayerPacks[x]=BP1/BP4` entries (unversioned, stay put);
  `UnrealTournament.ini` `[Engine.GameEngine]` holds the versioned
  `ServerPackages=BP1H.../BP4H...` lines. The `?mutator=...` start line
  (set in the NFO control panel, not these inis) is what controls instagib.
  **After any IG+ update or ini upload, re-check that `PlayerPacks[0]=BP1` and
  `PlayerPacks[1]=BP4` are still populated** — they have been blanked before
  (2026-08-10) and the failure is silent.
- **Triage order for a "wrong player model" report** (fastest to slowest):
  1. Startup log — are `Bonus Pack 1 supported` / `Bonus Pack 4 supported`
     present? No → `PlayerPacks[]` blank in `InstaGibPlus.ini`.
  2. Join log — `Log: Possessed PlayerPawn:` should be `bbTCow` (etc.), not
     `bbTMale1`. This is the definitive check that the handler fired.
  3. Only if 1 and 2 are clean, look at `PackageVersion` / rebuild, then at
     `ServerPackages` and the `.u` upload to the server's `System\`.
  Ignore skin/texture load warnings until 1 and 2 pass — see RULED-OUT.
- This is a standalone local git repo (branch `main`), pushed to GitHub remote
  `origin` = https://github.com/vtak007/UT99-Cow-Skins (public, account
  vtak007). Per global `CLAUDE.md`, doc updates (`README.md`/`CLAUDE.md`) wait
  for tested-and-approved changes before committing.

## OPEN / NEXT STEPS

- DONE 2026-08-01: rebuilt both handlers against `next-netcode-ef237853`
  (0 errors); server crash fixed by uploading the `.u` files to the server
  `System\`; DM restored by removing `NewNetIG` from the start line.
- DONE 2026-08-01: bogus `InstaGibPlus_next-netcode-ef237853.Instagib` mutator
  removed from the start line. Verified against the new `server.log`: mutator
  list loads clean (no `Failed to load class Instagib`), and the server prints
  `UTPure:  Bonus Pack 1 supported` / `Bonus Pack 4 supported` — both handlers
  loaded and ACE registered them as Player Types. Server-side success confirmed.
- Benign pre-existing log noise: `MVU3` / `BDBMapVote` are listed as bare
  package names (no `.Class`), so UT logs `Failed to load "NULL" / Class
  None.MVU3` then loads them anyway. Not an error; ignore.
- DONE 2026-08-01: end-to-end confirmed in-game — a client with the Nali War
  Cow class (`MultiMesh.TCow`) spawns as the cow, not Male Commando. The
  next-netcode-ef237853 handler rebuild + deploy is fully verified. No open
  items; this is the baseline working state for the next IG+ update.
- DONE 2026-08-10: regression — cow model forced to Male Commando again.
  Diagnosed from `FMJ Server Log 2026-08-10.log` + the server's
  `InstaGibPlus.ini`: `PlayerPacks[]` was blank. Restored `BP1`/`BP4`,
  restarted, user confirmed the cow renders in-game. No rebuild required.
- Note: `PlayerPacks[]` sits amid the `[ServerSettings]` tuning block, so it
  is easy to clear by accident during hand-edits. Diff `InstaGibPlus.ini`
  against the previous copy before uploading, or at minimum re-check the two
  `PlayerPacks` lines afterwards.

## CHANGE LOG

Newest first. Format: `- YYYY-MM-DD — what changed`.

- 2026-08-11 — Confirmed the `PlayerPacks[]` blanking was a hand-edit slip,
  not IG+ behaviour; closed the open item.
- 2026-08-10 — Recorded the blank-`PlayerPacks[]` regression: new confirmed
  root cause, two ruled-out theories (the `Gold1` texture error is a symptom;
  client `Force Default Models` proves nothing), a triage order, and a
  post-update check. Server fix was config-only; no source or build change.
- 2026-08-02 — Added this Change Log section (UT99 convention).
