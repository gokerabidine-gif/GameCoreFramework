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
