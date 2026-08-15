# BP1H / BP4H — Bonus Pack Skin Handlers for InstaGibPlus

Restores the **Nali WarCow, Nali, Skaarj Hybrid** (Bonus Pack 1 / MultiMesh) and
**War Boss, Xan Mark II** (Bonus Pack 4 / SkeletalChars) player models on servers
running modern InstaGibPlus (Deaod/utspect NewNet fork).

Ported from the original UTPure 7G/7H `BP1Handler` / `BP4Handler` by TNSe et al.
(sources: https://github.com/Deaod/UTPure) to the modern IG+ class hierarchy.

## Why this is needed

IG+ swaps every player's class at login for its own netcode-enhanced `bb*`
class. It only ships classes for the five standard models; anything else
(e.g. `MultiMesh.TCow`) falls back to **Male Commando**. IG+ still supports
plug-in handlers via `PlayerPacks[]`, but it derives the handler package name
from its own version:

```
PlayerPacks[0]=BP1  ->  loads  BP1H<PackageVersion>.BP1LoginHandler
```

For `InstaGibPlus_next-netcode-ef237853` the `PackageVersion` is
`next-netcode-ef237853`, so the handlers must be compiled as
`BP1Hnext-netcode-ef237853.u` and `BP4Hnext-netcode-ef237853.u` **against
that exact IG+ build**. That is what `build.bat` does.

> **IMPORTANT:** every time you update IG+ on the server, re-run `build.bat`
> with the new package name and update the ServerPackages lines accordingly.

## Building

1. Use a local UT99 GOTY install patched to v469 (any recent 469 works for
   compiling; 469e recommended to match the server).
2. Copy the **System files from the IG+ release zip** the server runs
   (`InstaGibPlus_next-netcode-ef237853.zip` → `System\*.u`, includes
   `InstaGibPlusAssets_v2.u`, `BaseCylinder.u`, `BaseCylinder2.u`,
   `HeadCylinder.u`) into `<UT>\System`.
3. Verify the stock GOTY files exist in `<UT>\System`: `MultiMesh.u`,
   `EpicCustomModels.u`, `SkeletalChars.u` (plus `TCowMeshSkins.utx`,
   `TNaliMeshSkins.utx`, `TSkMSkins.utx` in `<UT>\Textures`).
4. From the `BPHandlers` folder, run:

   ```
   build.bat "C:\UnrealTournament" InstaGibPlus_next-netcode-ef237853
   ```

   Output lands in `Output\`: the two `.u` files plus `.uz` copies for the
   redirect.

### If the compile errors on `SkeletalMesh'SkeletalChars...'`

Older UCC builds may not accept the `SkeletalMesh'...'` literal in
`bbWarBoss.uc` / `bbXanMK2.uc` defaultproperties. If `ucc make` complains
there, change `SkeletalMesh'SkeletalChars.WarMachineBoss'` to
`Mesh'SkeletalChars.WarMachineBoss'` (and likewise `NewXan`) and rebuild.

## Server installation

1. Upload `BP1Hnext-netcode-ef237853.u` and `BP4Hnext-netcode-ef237853.u` to
   the server's `System` folder.
2. Upload the `.uz` files to the redirect
   (`http://titan7.site.nfoservers.com/Server/`).
3. `InstaGibPlus.ini` → `[ServerSettings]`:

   ```ini
   PlayerPacks[0]=BP1
   PlayerPacks[1]=BP4
   ```

4. `UnrealTournament.ini` → `[Engine.GameEngine]`, add:

   ```ini
   ServerPackages=BP1Hnext-netcode-ef237853
   ServerPackages=BP4Hnext-netcode-ef237853
   ```

   (The existing `MultiMesh`, `EpicCustomModels`, `SkeletalChars`,
   `TCowMeshSkins`, `TNaliMeshSkins`, `TSkMSkins` ServerPackages entries must
   stay — the BP1 handler refuses to load without them.)

5. Restart the server and check the log. On success IG+ prints:

   ```
   Bonus Pack 1 supported
   Bonus Pack 4 supported
   ```

   If instead you see `You need to add 'ServerPackages=BP1Hmaster-...'`, the
   ServerPackages entry is missing or misspelled; if you see
   `'BP1H...' requires module 'MULTIMESH' to load properly`, the MultiMesh
   ServerPackages entry is missing.

6. Test: connect with a client whose Player Setup uses Class **Nali Cow**
   (Class `MultiMesh.TCow`), skin `TCowMeshSkins.WarCow` etc. You should spawn
   as the cow instead of Male Commando.

## Troubleshooting: "the server forces me into Commando"

Work through these in order. Steps 1 and 2 identify the cause in almost every
case; do not start with the texture warnings.

1. **Check the startup log for `Bonus Pack 1 supported` /
   `Bonus Pack 4 supported`.** If they are missing, IG+ never registered the
   handlers. The usual cause is that `PlayerPacks[0]=BP1` / `PlayerPacks[1]=BP4`
   in `InstaGibPlus.ini` `[ServerSettings]` have gone blank — most often an
   accidental hand-edit while changing other `[ServerSettings]` values, since
   they sit in the middle of the tuning block.

   This failure is **silent**: `ServerPackages` still loads the handler `.u`
   files and still sends them to clients, so nothing errors. Restore the two
   entries and restart; no rebuild is needed if the IG+ `PackageVersion` has
   not changed.

2. **Check the join log for `Log: Possessed PlayerPawn:`.** This is the
   definitive answer. It should read `bbTCow` (or `bbTNali`, `bbWarBoss`, …).
   If it reads `bbTMale1`/`bbTMale2`, the handler did not fire — go back to
   step 1, then check `PackageVersion` and the `.u` upload to `System\`.

3. **Ignore skin/texture load warnings until 1 and 2 pass.** A line like

   ```
   Warning: Failed to load "Texture TCowMeshSkinscc.Gold1": Object not found.
   ScriptLog: Failed to load tcowmeshskinscc.Gold1 so load CommandoSkins.cmdo1
   ```

   is a *symptom*, not the cause, and does **not** mean the `.utx` on the
   server is missing, corrupt, or out of sync with the client. Note the
   appended `1`: that numeric suffix is Botpack's **Male** `SetMultiSkin`,
   whereas `bbTCow.SetMultiSkin` passes the skin name verbatim. Seeing it
   proves the class was already downgraded to a Male pawn upstream. Fix the
   class and the texture warning goes away on its own.

4. **The client's `Force Default Models` setting is a red herring.** It being
   unchecked does not rule out a server-side override. Verify `ForceModels=0`
   and `bForceModels=False` in `InstaGibPlus.ini`, then trust step 2.

## Port notes (what changed vs the UTPure 7H originals)

- `bbCustomPlayer` no longer overrides `Tick` — modern IG+ has a real
  `simulated event Tick` used by its netcode. The v400-era mesh-fixup polling
  was moved to `PostNetBeginPlay` (available since 469, which IG+ requires),
  with a 1s `Timer` retry that only touches simulated proxies and defers to
  IG+'s `Timer` everywhere else.
- `PostBeginPlay` is no longer `simulated` (IG+'s does heavy server-side init
  that must not run on clients); client-side mesh setup happens in
  `PostNetBeginPlay` instead.
- All overridden `SetMultiSkin` functions now store `SkinName`/`FaceName`
  into `bbPlayerReplicationInfo`, matching what IG+'s own classes do (used by
  its ForceModels / brightskin logic).
- State overrides (`PlayerWalking`, `PlayerWaiting`, `PlayerSpectating`) call
  `Super` instead of duplicating stock bodies, so IG+'s state logic runs
  unmodified.
- Everything else (animations, decaps, sounds, skin resolution, FakeClass
  values) is verbatim from the originals.
