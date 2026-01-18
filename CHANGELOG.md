# Changelog

## [3.4.0](https://github.com/datapointchris/theme/compare/v3.3.0...v3.4.0) (2026-01-18)


### Features

* **browsers,bat:** add Firefox-based browser and bat syntax theming ([8fbb1ef](https://github.com/datapointchris/theme/commit/8fbb1eff1d2b6c7e5fc6296b0615d6f3d5f3f24d))

## [3.3.0](https://github.com/datapointchris/theme/compare/v3.2.0...v3.3.0) (2026-01-17)


### Features

* **regenerate:** add parallel regeneration script with timing stats ([2916baf](https://github.com/datapointchris/theme/commit/2916bafaf068229c2438761b4b2544464c0c9463))


### Bug Fixes

* **popping-and-locking:** correct syntax colors to match hedinne/popping-and-locking-vscode ([cb1b864](https://github.com/datapointchris/theme/commit/cb1b864c09c8908ed577ebd4645e70cbbf2ee937))
* **smyck:** correct syntax colors to match hukl/Smyck-Color-Scheme ([ecfbc43](https://github.com/datapointchris/theme/commit/ecfbc4376b0229a6d2906a59133f08aa8e8bbc7a))

## [3.2.0](https://github.com/datapointchris/theme/compare/v3.1.0...v3.2.0) (2026-01-17)


### Features

* **neovim:** add overrides.lua system and remove italic from comments ([53454fc](https://github.com/datapointchris/theme/commit/53454fc7848032e3f0f24654e84eac0985199048))

## [3.1.0](https://github.com/datapointchris/theme/compare/v3.0.1...v3.1.0) (2026-01-17)


### Features

* **display:** unify theme display functions with font tool pattern ([ec4ca3c](https://github.com/datapointchris/theme/commit/ec4ca3cd2032798011ae83d0919e42b7e1fe726c))


### Bug Fixes

* **apply:** add missing -r flag to yq for display name matching ([a9ecc18](https://github.com/datapointchris/theme/commit/a9ecc18a6dc8cd89f005f415a7984645ce78b877))
* **apply:** reject invalid themes instead of applying with warning ([490a1f3](https://github.com/datapointchris/theme/commit/490a1f3a3b3a510fc16d3810df8d585d7f591f2b))

## [3.0.1](https://github.com/datapointchris/theme/compare/v3.0.0...v3.0.1) (2026-01-15)


### Bug Fixes

* **rankings:** filter rejected themes from rankings display ([1a0d1c9](https://github.com/datapointchris/theme/commit/1a0d1c9a122d6e9946161aa148ace749b27274ae))

## [3.0.0](https://github.com/datapointchris/theme/compare/v2.0.0...v3.0.0) (2026-01-11)


### ⚠ BREAKING CHANGES

* **mako:** migrate notification configs to new format

### Features

* **extended:** add batch generator with plugin protection ([6f646e1](https://github.com/datapointchris/theme/commit/6f646e1bce1e4cc08e458952ad754ae2462566cb))
* **flexoki-moon:** add extended palette for all 5 variants ([e4cf44f](https://github.com/datapointchris/theme/commit/e4cf44f77635fa38a2c7761835a34c6b3baa4e47))
* **github:** add extended palette extraction and regenerate configs ([e7af1bb](https://github.com/datapointchris/theme/commit/e7af1bbee3c5b825cdfd2c0faf6ce3f82b75dee5))
* **gruvbox-dark-medium:** regenerate configs with extended palette ([3e6a0d0](https://github.com/datapointchris/theme/commit/3e6a0d06a7ed5a767f8699319a3aa3573f36c0bd))
* **nightfox:** add extended palette colors from plugin source ([2e8cbad](https://github.com/datapointchris/theme/commit/2e8cbad658997ca5b3df09f637421f9ad1600428))
* **oceanic-next:** add extended palette from plugin source ([3631920](https://github.com/datapointchris/theme/commit/3631920d9e75da320fb6ca41229e865246854be1))
* **solarized-osaka:** add extended palette from plugin source ([15a0960](https://github.com/datapointchris/theme/commit/15a0960b54da4d455d713b1e351b8c943e0fd90a))
* **themes:** add generated extended palettes for 20 themes ([cb18920](https://github.com/datapointchris/theme/commit/cb18920f3b137d2240cb9b7e171e3d712ac5984f))
* **themes:** protect plugin-extracted extended palettes ([12b64d8](https://github.com/datapointchris/theme/commit/12b64d8e2d5d3fe20d18e33ff423301fe2b5748e))
* **themes:** regenerate app configs to use extended palette colors ([50159fb](https://github.com/datapointchris/theme/commit/50159fb8c7df25f24a16ff25721eb8de26648bf9))
* **themes:** regenerate remaining app configs with extended palette ([37e3c30](https://github.com/datapointchris/theme/commit/37e3c30005add8f660f6541b19dd075bedb4c601))


### Code Refactoring

* **mako:** migrate notification configs to new format ([fa5c80c](https://github.com/datapointchris/theme/commit/fa5c80cbb4d3f9b4740375d72a1a7f1fd5532dd3))

## [2.0.0](https://github.com/datapointchris/theme/compare/v1.0.0...v2.0.0) (2026-01-10)


### ⚠ BREAKING CHANGES

* **neovim:** regenerate colorschemes with extended palette support

### Features

* **background:** add cross-platform wallpaper support ([c92e266](https://github.com/datapointchris/theme/commit/c92e266062ac36439026748bd5e6c1392a28b053))
* **borders:** use extended palette for semantic border colors ([a6d6476](https://github.com/datapointchris/theme/commit/a6d6476e713f193cb259edc1b9da3ac6d0e5151c))
* **btop:** use extended palette for semantic color choices ([c04927e](https://github.com/datapointchris/theme/commit/c04927e35c6a9cdbac4f9e5ca0686dbe223f1d54))
* **dunst:** use extended palette for semantic notification colors ([a25a9a5](https://github.com/datapointchris/theme/commit/a25a9a5eb2b2678457baa78d1825c1d124d6b7ce))
* **hyprland:** use extended palette for window border colors ([4582f98](https://github.com/datapointchris/theme/commit/4582f98663f71872e28eea5c1c01d39b61d4cbbb))
* **hyprlock:** use extended palette for authentication state colors ([4ff5942](https://github.com/datapointchris/theme/commit/4ff5942d3b0a5bca41fcfcaab1a10383a27f7318))
* **mako:** use extended palette for semantic notification colors ([ac818df](https://github.com/datapointchris/theme/commit/ac818df38ede6bcd2e85c3e4b2aa5fb6eaa2df8a))
* **neovim:** improve generator with extended palette and plugin safety ([7b3585c](https://github.com/datapointchris/theme/commit/7b3585c658303a94cf754dc2ccf10f7e66215dd4))
* **neovim:** regenerate colorschemes with extended palette support ([017edcb](https://github.com/datapointchris/theme/commit/017edcb2c51e0f24843f56f0dc45447a0beaff31))
* **rofi:** use extended palette for semantic status colors ([2b2608a](https://github.com/datapointchris/theme/commit/2b2608a2e614d8b6518cd168a2ad87e87768f9f9))
* **tmux:** use extended palette for semantic UI elements ([92f718c](https://github.com/datapointchris/theme/commit/92f718cabede741693d1f218147b88c70ec4a42b))
* **waybar:** use extended palette for semantic status colors ([d70db07](https://github.com/datapointchris/theme/commit/d70db07c507736e9ec0d9156322cb36a87e0a7a6))
* **yazi:** add algorithmic flavor generator for yazi file manager ([9353094](https://github.com/datapointchris/theme/commit/9353094ec57d0cf4a9bd6fc0740b20ddbac504b2))


### Bug Fixes

* **tmux:** restore DIAG_INFO and UI_SELECTION variables in generator ([8f2c6a3](https://github.com/datapointchris/theme/commit/8f2c6a3e677423e833a43bb73cc7415825a2b878))
