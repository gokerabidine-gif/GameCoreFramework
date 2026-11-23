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
