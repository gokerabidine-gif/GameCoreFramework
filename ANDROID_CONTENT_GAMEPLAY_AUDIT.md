# Android Port Content and Gameplay Audit

Audit date: 2026-11-23  
Branch: `android-porting`  
Scope: repository Git tree and selected C++/configuration files. This is a static source audit, not an Unreal Editor or device test.

## Verified inventory

The recursive Git tree contains 822 entries (675 files) and is not truncated.

### Vehicles: assets and framework code are present
- Sample vehicle content includes OffroadCar and SportsCar assets, materials, textures, rigs, physics assets and animation blueprints.
- The sample includes `BP_VehicleAdvSportsCar`, `DA_PawnData_Vehicle`, `DA_InputConfig_Vehicle`, `IMC_Vehicle`, `IA_HandBrake`, and `IA_HeadLight`.
- Framework source includes `GCFWheeledVehiclePawn`, `GCFVehicleControlComponent`, and `GCFModularVehicle`.
- The vehicle control component binds handbrake and headlight actions. The project has a vehicle control foundation; mobile touch driving controls and device performance are not verified.

### Weapon/combat sample: partial functionality exists
- Sample assets include `GA_Fire`, `GA_CreateProjectile`, `BP_Projectile`, `BP_Projectile_Fire`, `BP_Projectile_Spark`, and `DA_AbilitySet_Manny_Fire`.
- Character animation assets include pistol and rifle fire, dry-fire, reload, and related movement/aim animations.
- Framework source includes Gameplay Ability System classes, combat/health attribute sets, damage execution, ability sets, and an ability input router.
- These are evidence of sample firing/projectile abilities and weapon-related animation assets. They do **not** establish a complete player weapon system: no verified inventory, weapon pickup/equip/swap system, ammo/reload state model, weapon actor/equipment component, or production-ready firearm data pipeline was identified in the tree.
- Binary `.uasset` contents were inventoried by path and size only; their Blueprint graphs and references were not decoded or executed.

### Online/session: not a finished multiplayer service
- `AGCFGameSession::ProcessAutoLogin()` currently returns `true` with a comment that login is handled elsewhere by `GCFGameMode::TryDedicatedServerLogin`.
- `HandleMatchHasStarted` and `HandleMatchHasEnded` only call their superclass implementations.
- The sample module's `OnlineSubsystem` dependency remains commented out in `GCF_SampleProject.Build.cs`.
- This audit did not find a configured online provider, backend endpoint, matchmaking flow, lobby UI, deployment configuration, or end-to-end client/server test. The framework's replicated gameplay code is not equivalent to a deployable online game service.

### Mobile input/UI: framework input support, no mobile HUD proof
- Enhanced Input actions and contexts exist for player, character, and vehicle.
- `DefaultInput.ini` references Unreal's default virtual joystick but has `bAlwaysShowTouchInterface=False`.
- Sample UI assets found are debug/log/loading/layout widgets; no dedicated mobile combat HUD or touch vehicle control widget was identified by filename.
- This does not prove no touch interaction can be built in Blueprint, but it means a working touch-first interface has not been demonstrated.

## Next implementation gates
1. Obtain the genuine UE 5.7-compatible Lyra plugin folders required by the project.
2. Open and compile the sample in Unreal Editor 5.7; resolve actual compiler/plugin errors before platform-specific edits.
3. Inspect the Blueprint assets in-editor to confirm firing/projectile wiring and identify missing weapon gameplay.
4. Implement and test inventory/equip/ammo/reload and mobile HUD in the Editor, using the existing GAS/input architecture.
5. Configure an actual online provider/session/lobby architecture and test two clients on a reachable server.
6. Configure Android rendering/input/performance based on a successful UE 5.7 Android build and on-device profiling.

## Limitations
- No UE 5.7 Editor, UnrealBuildTool, Android SDK/NDK, or Android device deployment was available in this audit environment.
- No source or asset compilation, cooking, packaging, or APK generation was performed.
- No project runtime behavior is claimed as verified.



## Eighth pass: network security and input lifecycle review (2026-11-23)

### Network encryption: sample-only, unsafe for production
- `UGCFGameInstance::Init()` fills `DebugTestEncryptionKey` with the predictable byte sequence 0..31.
- `ReceivedNetworkEncryptionToken()` explicitly documents the implementation as a demonstration and says a secure service should supply a unique key. With the default `UE_WITH_DTLS=0` compile definition in `GameCoreFramework.Build.cs`, the non-DTLS path accepts any non-empty token and returns that hard-coded debug key.
- The source itself labels the key/debug approach as not secure. It must not be treated as production network encryption or shipped as the security design for an online game.
- No key service, token validation, identity-bound session key exchange, certificate provisioning, or production DTLS configuration was verified.
- Do not replace this with another hard-coded key. A real implementation requires a backend trust model and server-side key issuance/validation.

### Dedicated server flow: framework scaffolding exists
- `AGCFGameMode::TryDedicatedServerLogin()` checks for dedicated-server mode and the default map, invokes `UCommonUserSubsystem::TryToLoginForOnlinePlay(0)`, and then calls `HostDedicatedServerMatch(ECommonSessionOnlineMode::Online)` after the callback.
- `HostDedicatedServerMatch()` selects a user-facing experience and calls `UCommonSessionSubsystem::HostSession()`.
- This is more than a no-op session class: a CommonUser/CommonSession dedicated-server hosting path exists. However, it still depends on a correctly configured online subsystem/provider, server target/deployment, maps/experience assets, and a tested backend. None of those end-to-end requirements has been verified here.

### Input config lifecycle: unfinished removal path
- `UGCFPlayerInputBridgeComponent::AddInputConfig()` notifies the binding manager to refresh bindings.
- `RemoveInputConfig()` removes the config from its local list but contains a TODO for unbinding logic and does not notify the binding manager in the inspected implementation.
- This is a potential stale-binding/lifecycle issue to test and resolve in Unreal; no code change was made without running the input system and understanding binding receipt ownership.

### Scope and safety
- This pass was a source inspection only. No code, project settings, or assets were changed.
- The hard-coded key is a production security blocker for online deployment. The input removal TODO is an implementation risk requiring a targeted Editor test.
- No Unreal compile, dedicated server launch, two-client test, Android build, or APK was run.



## Ninth pass: mobile rendering and input implementation review (2026-11-23)

### Mobile rendering configuration
- The inspected `Config/DefaultEngine.ini` explicitly enables ray tracing, ray-tracing proxies, Substrate, virtual shadow maps, mesh distance fields, and desktop-class targeting. Windows uses DX12/SM6; Linux and Mac target SM6.
- No Android-specific renderer/RHI profile or mobile scalability profile was verified in this config.
- These settings are desktop-oriented and require an intentional Android rendering strategy. They are not proof that Android packaging is impossible, but they are a material compatibility/performance risk for mobile and must be validated against UE 5.7 Android capabilities and target devices.
- No renderer settings were changed without an actual UE 5.7 Android build and device test.

### Input helper implementation status
- `UGCFInputBindingManagerComponent` has its own binding lifecycle and directly adds/removes pawn mapping contexts through `UEnhancedInputLocalPlayerSubsystem`.
- Separately, `UGCFInputComponent::AddInputMappings()` and `RemoveInputMappings()` contain commented example loops and perform no mapping operation in their current implementation. This is a stub/helper limitation; whether these methods are called by current gameplay flows must be checked in an Unreal project build.
- The player input bridge's `RemoveInputConfig()` still removes only the local config entry and has a TODO for unbinding. The binding manager's explicit pawn-possession cleanup does remove pawn-dependent bindings, but it does not by itself prove dynamic per-config removal is correct.
- Vehicle control code inspected here binds only handbrake and headlight actions. Throttle/brake and steering are handled through the movement path and vehicle input configuration; no touch widget or on-screen vehicle control layout was found in this source review.

### Mobile gameplay/UI conclusion
- The project has Enhanced Input abstractions and a default virtual joystick reference in DefaultInput.ini, but no verified custom touch HUD for TPS combat and driving. A virtual joystick reference alone does not supply fire/aim/reload/crouch/jump/interact/vehicle pedal/steering buttons.
- No landscape-specific UI layout or Android touch interaction test was verified.
- These are implementation gaps, not something that can be safely solved by adding arbitrary config entries without knowing the actual Input Actions, mapping contexts, pawn data, and widget assets.

### Scope
- Source/config inspection only; no gameplay code or renderer settings were changed.
- No Unreal compile, cook, Android package, APK, or device test was performed.



## Tenth pass: experience and Game Feature failure-path audit (2026-11-23)

### Confirmed failure-handling gap
- In `GCFExperienceManagerComponent::OnGameFeaturePluginLoadComplete(const UE::GameFeatures::FResult& Result)`, the callback parameter `Result` is not inspected. The code decrements the outstanding plugin count and calls `OnExperienceFullLoadCompleted()` when the count reaches zero regardless of whether a Game Feature plugin load/activation succeeded.
- Consequently, a failed plugin operation is not surfaced as a failed experience state here; the experience can continue into action activation and eventually report itself Loaded despite a plugin failure. This is a source-level failure-path defect and a high-priority fix candidate.
- The component already has a TODO to represent a completed-but-failed state rather than relying on checks. No change was made because failure propagation affects loading UI, multiplayer replication, action rollback, and plugin reference counting; it needs an Unreal test harness.

### Teardown and lifecycle risks
- `EndPlay()` deactivates referenced Game Feature plugins before invoking each experience/action-set action's deactivation and unregister callbacks. The code itself contains a TODO that plugin teardown should be FILO and a TODO for partially-loaded state handling.
- The deactivation path logs an error when actions register asynchronous pausers, noting that asynchronous deactivation is not fully supported.
- These limitations matter for seamless experience transitions, failed/partial startup, and cleanup during travel or disconnect. They are not proof of a current crash, but must be covered by runtime tests before production multiplayer use.

### Startup and asset management
- `UGCFAssetManager::StartInitialLoading()` synchronously executes startup jobs for gameplay cue initialization and required base GameData loading. Failure to load the configured GameData asset is intentionally fatal.
- The project config points at `/GameCoreFramework/DA_DefaultGameData`; the repository tree must contain the matching cooked source asset and dependencies for a real package. Source inspection alone cannot validate the Unreal asset registry or cook output.
- `GameCoreFrameworkModule::StartupModule()` registers the plugin's `Config/Tags` directory with GameplayTagsManager. No startup/shutdown defect was established in this pass.

### Scope
- Source review and documentation only. No gameplay code or assets changed. No Unreal build, editor validation, cook, Android package, APK, or device test was performed.


## Eleventh pass: map discovery and project startup configuration (2026-11-23)

### Map Asset Manager scan-path mismatch
- `Config/DefaultGame.ini` registers the `Map` primary asset type for scanning only under `/Game/Maps`.
- The tracked sample map is `Plugins/GameCoreFramework/Content/Sample/Maps/L_GCF_Showcase.umap`, whose plugin content mount path is `/GameCoreFramework/Sample/Maps/L_GCF_Showcase`.
- `Config/DefaultEngine.ini` uses that plugin-mounted path directly for both `EditorStartupMap` and `GameDefaultMap`, so the configured startup map path and the tracked map asset agree.
- However, the current `Map` PrimaryAsset scan directory does not include the plugin-mounted sample map. Therefore, the sample map is not covered by that configured directory scan. This may affect workflows that discover or address maps through the `Map` PrimaryAsset type; direct startup-map loading is separately configured and should not be conflated with Asset Manager discovery.
- No config change was made: broadening the scan directory or adding a second scan entry needs validation in UE 5.7, including asset registry results, duplicate primary asset IDs, and cook/package behavior.

### Project/plugin startup configuration cross-check
- `GCF_SampleProject.uproject` declares EngineAssociation 5.7 and the sample runtime module. The GameCoreFramework plugin is present in the project plugin directory and its descriptor declares `CanContainContent: true`.
- The default map, GameInstance, global GameMode, AssetManager, default UI policy, loading screen, and default experience references in the inspected config resolve to matching tracked asset/source paths by name/path in the repository tree. This is path-level consistency only; Unreal asset loading and cooking have not been executed.
- The project Build.cs leaves the OnlineSubsystem dependency commented out. This is consistent with the existing finding that a CommonUser/CommonSession hosting scaffold does not by itself establish a configured online provider. No provider was selected or enabled in this pass.

### Scope and validation boundary
- This was a new configuration/tree cross-check, not a repeat of the earlier gameplay/source passes.
- No runtime config or project files were changed. No UE 5.7 editor validation, asset registry scan, cook, Android package, APK, or device test was run.
