# Changelog

## [2.0.2](https://github.com/cloudandthings/terraform-aws-s3-inventory/compare/v2.0.1...v2.0.2) (2026-02-12)


### Bug Fixes

* Deterministic bucket name ordering in view to reduce TF plan noise ([c253a9d](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/c253a9d87ba35ed76f6058ff0e0e2c0f5b9a80b3))
* Ensure LF principals are distinct between read/admin permission sets ([cd2ade9](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/cd2ade9db3946d16905b977377cc1f076aacb851))
* Validate that source_bucket_names are distinct ([a1f0f90](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/a1f0f901c79fe186c5fe71fef7b0e952a5127c63))

## [2.0.1](https://github.com/cloudandthings/terraform-aws-s3-inventory/compare/v2.0.0...v2.0.1) (2026-02-02)


### Bug Fixes

* Bugfix in union latest view ([5abe5da](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/5abe5da7121a10c87d6318dabe5e79d4ce8edb3f))

## [2.0.0](https://github.com/cloudandthings/terraform-aws-s3-inventory/compare/v1.1.0...v2.0.0) (2026-02-02)


### ⚠ BREAKING CHANGES

* BREAKING CHANGE: Rename var.union_view_name => var.union_all_view_name and add var.union_latest_view_name
* BREAKING CHANGE: Module no longer creates S3 bucket or Glue database. These must be created externally and names supplied to the module.

### Features

* Add MIT license and update README ([d096dc5](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/d096dc57ddc73d4fffd2ffc70aefcafa2dc3cf2b))
* BREAKING CHANGE: Module no longer creates S3 bucket or Glue database. These must be created externally and names supplied to the module. ([eb7eb88](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/eb7eb884825a2fb89c83d0a4c87a7ee18aeb38e0))
* BREAKING CHANGE: Rename var.union_view_name =&gt; var.union_all_view_name and add var.union_latest_view_name ([201706b](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/201706b4e838664ed085cbafea0df929b7958a76))


### Bug Fixes

* Add additional locations for LakeFormation access control to Glue table ([11ce596](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/11ce596417e13cd39b1e86b1be7138cad67ddfc1))

## [1.1.0](https://github.com/cloudandthings/terraform-aws-s3-inventory/compare/v1.0.3...v1.1.0) (2025-11-07)


### Features

* Add descriptions for Glue database and tables, and update data sources ([6cb3c52](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/6cb3c52dc5597a774366912d5ed47d0a8a2cea2d))


### Bug Fixes

* Use for_each instead of count to avoid unnecessary lakeformation permissions changes ([d009136](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/d009136a09b970091c8db4ea8a3ba77295a3d4a7))

## [1.0.3](https://github.com/cloudandthings/terraform-aws-s3-inventory/compare/v1.0.2...v1.0.3) (2025-09-10)


### Bug Fixes

* Use for_each instead of count to avoid unnecessary glue table replacements ([824d895](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/824d895333b357154ae0d043dde4054833b7bedf))

## [1.0.2](https://github.com/cloudandthings/terraform-aws-s3-inventory/compare/v1.0.1...v1.0.2) (2025-09-03)


### Bug Fixes

* Add lifecycle block to ignore changes in parameters ([fd29b7f](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/fd29b7fe43a6ffe951c7a4120ff27cc0534ac10f))

## [1.0.1](https://github.com/cloudandthings/terraform-aws-s3-inventory/compare/v1.0.0...v1.0.1) (2025-09-01)


### Bug Fixes

* Avoid drift due to table parameters order ([18f8a40](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/18f8a40a185425b5f9771d6fbe6ae8c98f567344))

## 1.0.0 (2025-09-01)


### Features

* Initial release ([170cdb0](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/170cdb0dad51ed194088aa67cee347bfc0e01b93))
* Initial release ([91758a0](https://github.com/cloudandthings/terraform-aws-s3-inventory/commit/91758a00dd106b59db52314bb4abb603ac4a33b9))

## [1.2.0](https://github.com/cloudandthings/terraform-aws-template/compare/v1.1.0...v1.2.0) (2023-05-05)


### Features

* Add shell script pre-commits ([#24](https://github.com/cloudandthings/terraform-aws-template/issues/24)) ([9b55002](https://github.com/cloudandthings/terraform-aws-template/commit/9b55002520bf0757470f90a2ff694ddca5581bc7))


### Bug Fixes

* Exclude external modules from tf min-max workflow ([5923e84](https://github.com/cloudandthings/terraform-aws-template/commit/5923e842eb639b1d58abf200f22ec04b9d6e0108))
* **pre-commit:** Correct README update check ([9bfeb61](https://github.com/cloudandthings/terraform-aws-template/commit/9bfeb613cc9f83f4f4f88ae1f558b14237f3b37b))

## [1.1.0](https://github.com/cloudandthings/terraform-aws-template/compare/v1.0.1...v1.1.0) (2023-03-06)


### Features

* Add random naming to example ([#20](https://github.com/cloudandthings/terraform-aws-template/issues/20)) ([0677cd1](https://github.com/cloudandthings/terraform-aws-template/commit/0677cd149337082923186ad40292baacba038224))
* **ci:** Add `concurrency` to github workflows ([#21](https://github.com/cloudandthings/terraform-aws-template/issues/21)) ([2c73dc9](https://github.com/cloudandthings/terraform-aws-template/commit/2c73dc9d52482d027ae6a47f4f6397e3c1b70faa))


### Bug Fixes

* `tftest` was hanging waiting for user input ([fdd614a](https://github.com/cloudandthings/terraform-aws-template/commit/fdd614aa8dc10377e4470a907ca365d56af767f3))
* Example naming ([6b50612](https://github.com/cloudandthings/terraform-aws-template/commit/6b5061244fce9baa83003eb40003543fdf4f8475))
* Minor improvements ([#18](https://github.com/cloudandthings/terraform-aws-template/issues/18)) ([e3a0b43](https://github.com/cloudandthings/terraform-aws-template/commit/e3a0b4387d99da6f7495d3fa053603467c37320d))
* The `tftest` was hanging waiting for user input ([#22](https://github.com/cloudandthings/terraform-aws-template/issues/22)) ([fdd614a](https://github.com/cloudandthings/terraform-aws-template/commit/fdd614aa8dc10377e4470a907ca365d56af767f3))

## [1.0.1](https://github.com/cloudandthings/terraform-aws-template/compare/v1.0.0...v1.0.1) (2022-12-22)


### Bug Fixes

* **simplify:** Cleanup tests and docs ([#8](https://github.com/cloudandthings/terraform-aws-template/issues/8)) ([92b1297](https://github.com/cloudandthings/terraform-aws-template/commit/92b1297fe8f9f202ba6fc80875f4f64c090c32e1))

## 1.0.0 (2022-12-21)


### Features

* Module tests and standardisation  ([#1](https://github.com/cloudandthings/terraform-aws-template/issues/1)) ([cfbc665](https://github.com/cloudandthings/terraform-aws-template/commit/cfbc6653f103118764e99bc98a0f70ea42098338))


### Bug Fixes

* **ci:** Terraform min-max ([#7](https://github.com/cloudandthings/terraform-aws-template/issues/7)) ([71acf4a](https://github.com/cloudandthings/terraform-aws-template/commit/71acf4a932b5a210217279265bc707e29711620d))
* **ci:** Update workflow triggers ([#6](https://github.com/cloudandthings/terraform-aws-template/issues/6)) ([a37afcb](https://github.com/cloudandthings/terraform-aws-template/commit/a37afcbaa54e3c6918d5206694844eb25f87930c))
