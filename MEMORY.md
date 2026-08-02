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

## RULED-OUT THEORIES

- (none recorded yet)

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
- This is a standalone local git repo (branch `main`); no remote configured.
  Per global `CLAUDE.md`, doc updates (`README.md`/`CLAUDE.md`) wait for
  tested-and-approved changes before committing.

## OPEN / NEXT STEPS

- Rebuild the two handlers against `next-netcode-ef237853` (needs the full IG+
  System set on a UT99/469 install), then update the server's `ServerPackages`
  lines and redirect `.uz` files. Not yet done as of 2026-08-01.
