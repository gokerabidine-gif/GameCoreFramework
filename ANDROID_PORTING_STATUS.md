# Android Porting Status

This file tracks the Android port without changing the existing `main` branch.

## Repository audit

- Project engine association: Unreal Engine 5.7.
- The project root contains `GCF_SampleProject.uproject`, `Config/`, `Source/`, and `Plugins/GameCoreFramework/`.
- The README states that these Lyra plugins must be copied into the project's `Plugins/` directory before the sample project can be built:
  - CommonGame
  - CommonUser
  - CommonLoadingScreen
  - GameplayMessageRouter
  - ModularGameplayActors
  - GameSubtitles
  - UIExtension
- The framework plugin descriptor also declares dependencies on CommonGame, CommonUI, CommonLoadingScreen, CommonUser, GameplayMessageRouter, ModularGameplayActors, UIExtension, GameplayAbilities, EnhancedInput, GameFeatures, ChaosVehiclesPlugin, AudioModulation, and Mover.
- The current `Config/DefaultEngine.ini` is desktop-oriented: it enables DX12/SM6 and ray tracing, and sets the hardware target to Desktop.
- The project currently has no verified Android package, no verified Android build, and no verified on-screen touch HUD.

## Porting gates

- [ ] Obtain the exact UE 5.7-compatible Lyra dependency plugins and place them in `Plugins/`.
- [ ] Verify all plugin descriptors and platform support for Android; disable or replace editor/desktop-only modules where appropriate.
- [ ] Install and configure the Android SDK, NDK, JDK, and matching UE 5.7 Android toolchain.
- [ ] Add Android-specific rendering/device-profile settings only after checking the project's actual assets and supported mobile renderer.
- [ ] Audit all C++ modules and third-party plugins for Android compilation.
- [ ] Implement and connect landscape touch controls for character movement, camera look, fire, aim, reload, interact, and vehicle driving.
- [ ] Verify vehicle physics and performance on a real Android device.
- [ ] Build a Development APK, inspect build logs, install, launch, and test on device.
- [ ] Only after successful device tests, configure Shipping packaging and multiplayer validation.

## Important

Do not treat a configuration-only change as proof that the project is Android-ready. Do not merge experimental mobile settings into `main` until the project compiles and runs on the target device.
