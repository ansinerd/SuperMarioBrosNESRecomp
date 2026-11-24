SMB iOS game linking milestone
=============================

Extract this archive into C:\SuperMarioBrosNESRecomp\.

Adds these files:
  ios/game-arm64/CMakeLists.txt
  ios/game-arm64/main.m
  ios/game-arm64/Info.plist
  ios/game-arm64/README-link-test.txt
  .github/workflows/ios-game-private-link.yml

The GitHub workflow runs on a push by 'ansinerd' to 'ios-port'.
It expects the existing SMB_ROM_ZIP_B64 Actions repository secret.

IMPORTANT:
- Do not add your ROM, the Base64 secret, or generated bank C files to Git.
- This is a PRIVATE CI compilation/link check; it uploads no app or generated code.
- The iOS app expects a user-provided .nes file in the app's Documents directory.
- It is NOT yet device tested or signed. ROM picker, save paths, touch controls,
  and lifecycle integration still need to be developed.
- Do not change the existing working Windows game target.

PowerShell:
  cd C:\SuperMarioBrosNESRecomp
  Expand-Archive -LiteralPath 'C:\Users\Ansab\Downloads\SMB_iOS_Game_Link_Test.zip' -DestinationPath . -Force
  git status --short
  git add ios/game-arm64 .github/workflows/ios-game-private-link.yml
  git commit -m "Add private iOS Mario game linking test"
  git push

The workflow may fail at first due to iOS-specific code or linker differences.
That is a diagnostic milestone. Review the failed log without posting any secret.
