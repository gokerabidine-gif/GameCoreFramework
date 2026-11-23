# Android Porting Status

This file tracks the Android port without changing the existing `main` branch.

## Verified repository audit

- Project engine association: Unreal Engine 5.7.
- The repository contains `GCF_SampleProject.uproject`, `Config/`, `Source/`, and `Plugins/GameCoreFramework/`.
- The README requires these UE 5.7-compatible Lyra plugins before the sample project can compile:
  - CommonGame
  - CommonUser
  - CommonLoadingScreen
  - GameplayMessageRouter
  - ModularGameplayActors
  - GameSubtitles
  - UIExtension
- The framework plugin descriptor also declares dependencies on CommonGame, CommonUI, CommonLoadingScreen, CommonUser, GameplayMessageRouter, ModularGameplayActors, UIExtension, GameplayAbilities, EnhancedInput, GameFeatures, ChaosVehiclesPlugin, AudioModulation, and Mover.
- The current `Config/DefaultEngine.ini` is desktop-oriented: DX12, SM6 shader targets, ray tracing, and `TargetedHardwareClass=Desktop` are configured. No Android renderer configuration was verified.
- The sample content tree contains OffroadCar and SportsCar vehicle assets, a `BP_VehicleAdvSportsCar` blueprint, vehicle pawn code, and Chaos Vehicles integration.
- Vehicle driving input is routed through the shared `InputTag.Move` path: the wheeled vehicle pawn maps the forward/back axis to throttle/brake and the lateral axis to steering. The vehicle-specific component separately binds handbrake and headlights.
- Character movement and look input actions exist in the sample content. Their existence does not prove that an on-screen mobile HUD is configured.
- A repository-tree scan found no paths named for Weapon, Inventory, Touch, VirtualJoystick, or Android. This is a path/name audit, not proof that no related logic exists under differently named assets.
- The plugin code references online subsystem modules and includes some replicated vehicle state, but no configured online service/backend or completed multiplayer deployment was verified.
- No Android package, successful Android build, or on-device test has been supplied or verified.

## Porting gates

- [ ] Obtain the exact UE 5.7-compatible Lyra dependency plugins and place them in `Plugins/`.
- [ ] Verify all plugin descriptors and platform support for Android; disable or replace editor/desktop-only modules where appropriate.
- [ ] Install and configure the Android SDK, NDK, JDK, and matching UE 5.7 Android toolchain.
- [ ] Add Android-specific rendering/device-profile settings only after checking the project's actual assets and supported mobile renderer.
- [ ] Audit all C++ modules and third-party plugins for Android compilation.
- [ ] Implement and connect a landscape touch HUD: movement joystick, camera-look region, jump/crouch/interact, and vehicle throttle/brake/steering/handbrake/headlights.
- [ ] Add weapon, aiming, firing, reload, and inventory gameplay; no corresponding assets or paths were identified in the current repository-tree scan.
- [ ] Verify vehicle physics and performance on a real Android device.
- [ ] Build a Development APK, inspect build logs, install, launch, and test on device.
- [ ] Configure and test an actual multiplayer backend/session flow; module references alone are insufficient.
- [ ] Only after successful device tests, configure Shipping packaging and final multiplayer validation.

## Work recorded on branch

- Created the isolated `android-porting` branch from `main`.
- Added this audit document to track verified prerequisites and prevent unverified configuration changes from being mistaken for a working Android port.

## Important

Do not treat a configuration-only change as proof that the project is Android-ready. Do not merge experimental mobile settings into `main` until the project compiles and runs on the target device. Unreal Engine packaging requires a compatible UE installation and Android toolchain; GitHub file edits alone cannot produce or validate an APK.


## Additional verification (2026-11-23)

- Epic's Android requirements table lists UE 5.7 with Android Studio Koala 2024.1.2 Patch 1 (September 17, 2024), Android SDK target 35, and Android NDK r27c. These are the version-specific baseline values to verify against the installed UE 5.7 toolchain before packaging; do not substitute UE 5.8/5.9 defaults without checking.
- Epic's Common User documentation says the plugin source is acquired with the Lyra Starter Game through the Unreal Engine GitHub or the Epic Games Launcher Learn tab. This confirms that these Lyra modules are not ordinary standalone dependencies that should be replaced with arbitrary third-party mirrors.
- The repository has no .github/workflows/android.yml or .github/workflows/build.yml on this branch (both paths returned 404). No CI build pipeline was verified.
- The .uproject enables ModelingToolsEditorMode for the Editor target only. This is not itself an Android build blocker, but it does not supply any of the missing Lyra modules.

References:
- Epic, Android Development Requirements: https://dev.epicgames.com/documentation/unreal-engine/android-development-requirements-for-unreal-engine
- Epic, Common User Plugin: https://dev.epicgames.com/documentation/unreal-engine/common-user-plugin-in-unreal-engine-for-lyra-sample-game

## Current decision

No Android configuration, touch controls, weapon system, CI workflow, or APK was added in this pass. The required Lyra plugin source and a compatible UE 5.7 + Android toolchain are not present in this GitHub-only workspace. Creating placeholder plugin folders or a workflow that cannot access the licensed engine and dependencies would produce a misleading, non-buildable result. Continue only after the genuine dependencies and a suitable build environment are available.


## Second pass: project build and configuration audit (2026-11-23)

### Newly verified
- Both Unreal target rules already exist:
  - Source/GCF_SampleProject.Target.cs (Game target)
  - Source/GCF_SampleProjectEditor.Target.cs (Editor target)
  Both set BuildSettingsVersion.V6 and IncludeOrderVersion.Unreal5_7. Do not create duplicate target files.
- The README's setup instructions explicitly require copying the seven Lyra-related plugins into this repository's Plugins directory. The current repository Plugins directory audit previously found only GameCoreFramework, so this prerequisite remains unmet.
- DefaultGame.ini references CommonLoadingScreen's LoadingScreenWidget class and several GameCoreFramework content assets. This confirms CommonLoadingScreen is an active project dependency, not just an unused descriptor entry.
- DefaultEngine.ini already contains an AndroidFileServer runtime settings section, but that only configures the file-server plugin. It does not mean Android target platform, mobile renderer, Android SDK/NDK, or packaging are configured.
- The existing DefaultEngine.ini enables ray tracing, Substrate, virtual shadow maps, and desktop-class hardware targeting, and contains desktop SM6 RHI targets for Windows/Linux/Mac. These settings require a deliberate mobile-renderer compatibility review; blindly appending Android settings is not a safe substitute for testing the project's materials, lighting, and plugins.
- The Common User Epic documentation currently describes Common User as distributed with Lyra and also as a standalone plugin. The repository README nevertheless instructs obtaining the Lyra-compatible plugin set. Use the UE 5.7-matched official source, not arbitrary mirrors.

### Corrected implementation status
- Game and Editor Target.cs files: present.
- AndroidFileServer settings: present, but not proof of Android readiness.
- Android build pipeline: not found.
- Lyra dependency set: not present in this repository's Plugins folder.
- Android renderer/device profiles: not verified.
- Touch HUD, weapon/inventory gameplay, APK build, and device tests: not implemented or verified.

### Next safe action
Acquire the genuine UE 5.7-compatible dependency plugin source and a compatible UE 5.7 build environment first. Then validate module/platform support and compile before introducing mobile rendering or gameplay changes. Do not commit placeholder plugins or an unexecutable CI workflow.


## Third pass: touch-input correction and dependency preparation (2026-11-23)

### Touch input correction
- A direct read of Config/DefaultInput.ini found DefaultTouchInterface=/Engine/MobileResources/HUD/DefaultVirtualJoysticks.DefaultVirtualJoysticks. The project therefore references Unreal's built-in default virtual joystick asset. The earlier path-name scan did not reveal this because the setting is in an INI file.
- The same file sets bAlwaysShowTouchInterface=False. This does not establish that the joystick will be visible in every Android runtime/device configuration.
- This is only the engine's generic virtual joystick reference. It does not demonstrate a custom landscape HUD with the required combat buttons (fire, aim, reload, jump/crouch/interact) or vehicle controls. No custom mobile HUD was verified.
- Existing input mappings include gamepad movement/look and a handbrake mapping. No project-specific mobile button layout was verified. DefaultInput.ini was intentionally left unchanged.

### Added preparation utility
- Added Scripts/Prepare-LyraDependencies.ps1 on android-porting.
- The script validates all seven Lyra plugin folders and their .uplugin JSON descriptors before copying any of them from a local UE 5.7-matched Lyra Plugins directory into this project's Plugins directory.
- It refuses to overwrite existing destination folders and supports -WhatIf preview.
- The repository .gitignore already excludes the seven dependency plugin directories, so locally copied dependency source is not accidentally committed or uploaded to GitHub.
- This is a local dependency-staging helper only. It does not download proprietary/engine-associated dependencies, compile C++, validate Android platform support, or produce an APK.

### Current verified state
- Target.cs files exist.
- DefaultTouchInterface points to Unreal's generic virtual joystick; custom mobile HUD remains unverified.
- Lyra dependency folders remain absent from the repository.
- No UE build, Android package, or device test has been run.


## Fourth pass: read-only Android prerequisite preflight (2026-11-23)

- Added `Scripts/Test-AndroidPortPrerequisites.ps1` on `android-porting`.
- The script checks that the project descriptor is valid JSON, that the project still declares Unreal Engine 5.7 and its Runtime game module, and that the GameCoreFramework descriptor is parseable.
- It checks each of the seven required Lyra plugin descriptor paths and parses available descriptors before reporting success.
- Where a plugin module declares platform allow/deny lists, it reports Android exclusions as warnings for manual review. An absent allow-list is not treated as proof of Android support.
- Missing files or malformed JSON cause a non-zero exit code. The script is read-only and does not change project configuration or copy dependencies.
- This script has been committed to GitHub but has not been executed in PowerShell/Unreal in this environment. Its checks are not a substitute for Unreal Build Tool compilation or Android packaging.
- The seven Lyra dependency folders are still absent from the repository, so a complete successful preflight is not currently expected.

### Current blocker
The next implementation steps that alter C++, assets, mobile input/UI, rendering, or packaging require the genuine UE 5.7 Lyra dependencies and an installed UE 5.7 + Android toolchain. Without those inputs, further project edits would be speculative and could make the project less buildable. 


## Fifth pass: project activation and module dependency review (2026-11-23)

### Newly verified from the actual project descriptors and build rules
- `GCF_SampleProject.uproject` currently lists only `ModelingToolsEditorMode`, restricted to the Editor target. It does not explicitly list `GameCoreFramework` as an enabled project plugin.
- The repository README's setup instructions separately tell the user to open Edit > Plugins and ensure GameCoreFramework and its dependencies are enabled. Therefore plugin activation is a manual setup step in the documented workflow and is not currently recorded in the project descriptor.
- `GameCoreFramework.uplugin` declares the framework Runtime module at `PreDefault` and lists the framework's plugin dependencies, including the Lyra modules. The required Lyra plugin source directories are still absent.
- `GameCoreFramework.Build.cs` statically references modules including GameplayMessageRuntime, ChaosVehicles, Mover, GameplayAbilities, GameFeatures, ModularGameplay, CommonLoadingScreen, CommonUser, CommonUI, CommonGame, CommonInput, GameSubtitles, OnlineSubsystem, OnlineSubsystemUtils, UIExtension, and others. All must resolve in the selected UE 5.7 installation or supplied plugin source for a successful build.
- The sample game's own `GCF_SampleProject.Build.cs` currently declares only Core, CoreUObject, Engine, InputCore, and EnhancedInput. Its OnlineSubsystem dependency remains commented out. This is further evidence that a working multiplayer provider/session configuration is not established by the sample game module alone.
- `DefaultGame.ini` includes a `DistillSettings` wildcard for `Weapons/*`. This indicates a planned/expected content category but does not prove that a complete weapon system or weapon assets are present; the earlier path scan did not identify a dedicated weapon system.
- The project input config sets `bAlwaysShowTouchInterface=False`; the default virtual joystick reference remains present. No custom combat or vehicle touch HUD was verified.

### Safe decision
- Did not change `.uproject` to force-enable GameCoreFramework: its required Lyra plugins are still missing, and enabling a plugin with unresolved required dependencies before staging the genuine UE 5.7 dependency set risks turning the project into an immediate plugin-load failure.
- Did not add online provider settings, Android renderer overrides, or touch mappings without a build/test environment.
- Next meaningful gate remains staging the official UE 5.7-compatible Lyra dependencies, then enabling the framework plugin in the Editor, saving the project descriptor, and running an Editor Development build before Android-specific changes.


## Sixth pass: full repository tree and gameplay asset audit (2026-11-23)

- Inspected the complete, non-truncated recursive Git tree: 822 entries / 675 files.
- Added `ANDROID_CONTENT_GAMEPLAY_AUDIT.md` with verified asset/source inventory and implementation gates.
- Important refinement to the earlier filename scan: the project **does contain** sample firing/projectile abilities (`GA_Fire`, `GA_CreateProjectile`), projectile Blueprint assets, pistol/rifle fire and reload animations, combat attributes, damage execution, and GAS ability routing. The earlier scan that found no weapon-related filenames was incomplete.
- However, no complete inventory/equipment/ammunition/weapon swapping system was verified. Binary Blueprint graphs were not decoded or run, so their exact functionality remains unconfirmed.
- Vehicle evidence is broader than previously summarized: both OffroadCar and SportsCar sample asset sets, a vehicle pawn/control component, vehicle input config/context, handbrake and headlight actions are present. This is a vehicle gameplay foundation, not proof of mobile touch driving or Android compatibility.
- The session implementation was inspected directly: `AGCFGameSession::ProcessAutoLogin()` returns true, while match-start/end overrides only call the superclass. This is not proof of a configured online provider, matchmaking, lobby, or deployed backend.
- Enhanced Input configurations exist for player, character and vehicle; the default virtual joystick reference exists but `bAlwaysShowTouchInterface=False`. No dedicated mobile combat/vehicle HUD was identified by asset path.
- No gameplay source, Blueprint asset, or rendering/input configuration was modified in this pass. This was an evidence-focused audit to avoid unsafe assumptions.



## Seventh pass: reconcile audit history and inspect CI evidence (2026-11-23)

### Corrections and source-of-truth clarification
- The Sixth-pass gameplay audit supersedes earlier statements in this file that said no weapon-related assets or firing functionality were identified. The repository does contain sample firing/projectile abilities, projectile Blueprint assets, firearm animations, GAS combat attributes, damage execution, and ability routing. A complete inventory/equipment/ammo/swap system remains unverified.
- The Sixth-pass audit also supersedes any implication that the repository contains no meaningful combat foundation. It does not establish a complete playable shooter or production-ready weapon pipeline.
- Vehicle sample assets and vehicle control code are present as described in the Sixth-pass audit; Android touch driving and device performance remain untested.
- The exact session-source review in the Sixth-pass audit is the current evidence for online readiness. No configured provider, matchmaking/lobby flow, deployed backend, or end-to-end multiplayer test has been verified.
- For detailed file-level evidence and limitations, see `ANDROID_CONTENT_GAMEPLAY_AUDIT.md`.

### CI evidence for inspected latest commit
- Queried GitHub combined commit status for commit `176960532844db65ad9aaaa9a9a58fd5cf00c390`: no status entries were returned.
- Queried workflow runs associated with that commit: no pull-request-triggered workflow runs were returned by the available GitHub endpoint.
- This means no CI result is available as evidence of an Unreal build. It does not prove that no workflow exists for every trigger or that no external build system is used.

### Remaining implementation boundary
- The next code/content implementation still requires the genuine UE 5.7-compatible Lyra dependency source and a UE 5.7 + Android toolchain. Do not add placeholder plugins, guessed mobile renderer settings, or a CI workflow that cannot access the required engine/dependencies.
- No Unreal compilation, cooking, packaging, APK generation, or Android device test has been performed.



## Eighth pass: network security and input lifecycle review (2026-11-23)

- `UGCFGameInstance::Init()` initializes a predictable 32-byte debug key (bytes 0..31). `ReceivedNetworkEncryptionToken()` explicitly describes the sample mechanism as demonstration-only and recommends obtaining a unique key from a secure web service. With `UE_WITH_DTLS=0` in the module build definitions, the default non-DTLS path accepts a non-empty token and returns that predictable key. This is not production network security; do not ship it as the game's encryption design.
- No secure key service, token validation, identity-bound key exchange, certificate provisioning, or production DTLS configuration was verified. Replacing the hard-coded key with another static value would not fix the problem; a backend trust/key-issuance design is required.
- A more complete dedicated-server scaffold exists than the earlier GameSession-only inspection showed: `AGCFGameMode::TryDedicatedServerLogin()` uses CommonUser login and then `HostDedicatedServerMatch()` selects an experience and calls CommonSession `HostSession()`. This is framework scaffolding only; online provider, server deployment, experience/map configuration, and end-to-end tests remain unverified.
- `UGCFPlayerInputBridgeComponent::RemoveInputConfig()` removes the config from its local array but has a TODO for unbinding logic and does not notify the binding manager in the inspected function. Treat this as a potential stale-binding issue to reproduce and fix in Unreal, not as a confirmed runtime defect.
- Detailed findings are recorded in `ANDROID_CONTENT_GAMEPLAY_AUDIT.md`. This was source inspection only; no code or assets were changed and no build/test/APK was produced.



## Ninth pass: mobile rendering and input implementation review (2026-11-23)

- `Config/DefaultEngine.ini` enables ray tracing, ray-tracing proxies, Substrate, virtual shadow maps, mesh distance fields, and desktop-class targeting. Windows targets DX12/SM6; Linux and Mac target SM6. No Android-specific renderer/RHI or mobile scalability profile was verified. These are mobile compatibility/performance risks requiring an intentional UE 5.7 Android rendering configuration and device validation; they do not alone prove packaging impossible.
- `UGCFInputBindingManagerComponent` independently manages pawn mapping contexts directly through Enhanced Input. However, `UGCFInputComponent::AddInputMappings()` and `RemoveInputMappings()` are currently stub-like: their example loops are commented out and the functions do not add/remove mappings. Actual call-site usage must be checked in the editor/runtime.
- `UGCFPlayerInputBridgeComponent::RemoveInputConfig()` still lacks explicit unbinding/manager notification. Pawn-possession cleanup exists in the manager, but does not establish correct dynamic per-config removal.
- The inspected vehicle control component binds handbrake and headlight actions; driving axes are handled elsewhere. No verified on-screen touch HUD or landscape control layout was found. Default virtual joystick config does not provide the full TPS/vehicle touch UI.
- This pass changed documentation only. No code/config settings changed; no Unreal build, cook, Android package, APK, or device test was performed. See `ANDROID_CONTENT_GAMEPLAY_AUDIT.md`.



## Tenth pass: experience/Game Feature failure-path audit (2026-11-23)

- Confirmed defect candidate: `UGCFExperienceManagerComponent::OnGameFeaturePluginLoadComplete(const FResult& Result)` ignores `Result`. When the outstanding callback count reaches zero, it proceeds to full experience loading/actions even if a Game Feature plugin failed. The experience may therefore be marked Loaded without all requested plugins successfully activating. This needs explicit failure state, rollback/reference-count handling, and Unreal tests; no speculative code patch was made.
- Teardown has documented lifecycle gaps: `EndPlay()` deactivates plugin URLs before action deactivation/unregistration; source comments mark FILO teardown and partially-loaded-state handling as TODOs. Async action deactivation pausers are not fully supported and log an error.
- Asset manager startup loads gameplay cue data and required GameData; missing configured GameData is fatal. The configured asset path must be validated by Unreal's asset registry/cook, which cannot be established from Git tree text alone.
- Module startup registers plugin Gameplay Tags config path. No module startup/shutdown defect was established.
- Documentation-only pass. No code/assets changed and no Unreal build, cook, APK, or device test was run. Full evidence is in `ANDROID_CONTENT_GAMEPLAY_AUDIT.md`.
