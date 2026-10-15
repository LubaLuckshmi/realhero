# RealHero · Android 0.2.1

Native Flutter/Dart application with two onboarding paths, short tap-based discovery and a contextual in-progress screen based on the approved design.

The Android package remains `app.realhero.realhero`, with the launcher label `RealHero`. This branch contains the current application sources and offline tests. It does not deploy a server. No API keys, access tokens, personal history, spending ledgers or host configuration are included.

The workflow pins Flutter 3.47.7 and official actions, runs server tests with a mocked provider, analyzes and tests Flutter, renders widget captures, and builds an unsigned release APK. The central Leia button opens the implemented text chat. Voice recording, contact availability and external actions are not simulated.

CI never receives a private signing key. Its unsigned artifact is an internal build output, not an installable delivery. A release must be signed outside CI with a durably preserved Android key and verified before delivery. Matching the original package ID alone does not make it compatible with an installation signed with a different key.

The previous installation's signing key has not been recovered. No in-place update or data migration has been verified. Do not uninstall the existing application before its data has been safely copied and a restoration method tested.

Personal AI uses a separately configured HTTPS server. The build makes no live model calls and does not change the API budget or deployed services.
