# Changelog

## [2.1.0](https://github.com/broneq/capitan/compare/v2.0.1...v2.1.0) (2026-11-28)


### Features

* add /capitan:delegate to open tasks in a running Capitan session ([52829f7](https://github.com/broneq/capitan/commit/52829f7b7af24996d229b740176a6664b8ab714a))
* **skill:** add hands-on and hands-off modes ([7803561](https://github.com/broneq/capitan/commit/7803561b2d3b3e797a3164c5af7df8ff44224180))


### Bug Fixes

* **skill:** base new worktrees on the fetched remote branch ([f6d2bbb](https://github.com/broneq/capitan/commit/f6d2bbb18a6eadfe0d2af4551298e8926f247804))

## [2.0.1](https://github.com/broneq/capitan/compare/v2.0.0...v2.0.1) (2026-11-27)


### Bug Fixes

* **skill:** let the project's merge policy decide on auto-merge ([f182e26](https://github.com/broneq/capitan/commit/f182e263e514a4206d64acd28d59b54a42362631))
* **skill:** take Capitan's session name from ListAgents, not memory ([0185ada](https://github.com/broneq/capitan/commit/0185adafbf8dbdf0873e99a0ffb9ecd7129969bd))

## [2.0.0](https://github.com/broneq/capitan/compare/v1.0.2...v2.0.0) (2026-11-18)


### ⚠ BREAKING CHANGES

* **skill:** references/agent-prompt.md, agent-protocol.md and operations.md are replaced by agent-rules.md and agent-brief.md; agents merge by default when checks are green and nothing blocks.

### Features

* **skill:** rewrite Capitan as a coordinator of autonomous agents ([215db03](https://github.com/broneq/capitan/commit/215db03ee78890124df01b2a3e5b3c39a3f146f8))


### Bug Fixes

* **skill:** set in-progress status when claiming a task and final status at close-out ([6677feb](https://github.com/broneq/capitan/commit/6677feb89e191bffcfa9b59c459990fe44f09f0c))

## [1.0.2](https://github.com/broneq/capitan/compare/v1.0.1...v1.0.2) (2026-10-28)


### Bug Fixes

* **skill:** define task done as merged and let Capitan do the bookkeeping ([5ff5f39](https://github.com/broneq/capitan/commit/5ff5f39cce56d0d15c1963341c4c488e451761a3))

## [1.0.1](https://github.com/broneq/capitan/compare/v1.0.0...v1.0.1) (2026-10-28)


### Bug Fixes

* **skill:** pass absolute paths to herdr so worktrees group under the main checkout ([7d2f8b2](https://github.com/broneq/capitan/commit/7d2f8b2880c0b4e594ca0ee3d4840578cfde0bd9))

## 1.0.0 (2026-10-13)


### Features

* add the capitan plugin ([c91856f](https://github.com/broneq/capitan/commit/c91856fcc281832f47440f897c552f93eaa9571a))
* **skill:** create and prepare worktrees with Worktrunk ([8062d18](https://github.com/broneq/capitan/commit/8062d18fbb8dab8b2d3ad0599244aca8a2995c27))
* **skill:** generic tasks, same-settings agents, finish via SendMessage ([e9074f6](https://github.com/broneq/capitan/commit/e9074f6d214eff36fb016713fa08bb3ca8e95fd0))


### Bug Fixes

* **skill:** agent ends a reviewable result with an explicit finish question ([7613e65](https://github.com/broneq/capitan/commit/7613e6554ddf49646e57cf6c8c78ba94f38638b6))
* **skill:** agents ask before finishing only when it matters ([4f80437](https://github.com/broneq/capitan/commit/4f804373deea555878a67d6c08abd987ddfca6bc))
* **skill:** front-load the description and name no model ([51e3e5a](https://github.com/broneq/capitan/commit/51e3e5a03a77c18f88f89a923972f103929c219c))
