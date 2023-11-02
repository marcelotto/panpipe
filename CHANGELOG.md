# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) and
[Keep a CHANGELOG](http://keepachangelog.com).


## Unreleased

### Added

- type `t` on all AST node structs


[Compare v0.3.0...HEAD](https://github.com/marcelotto/panpipe/compare/v0.3.0...HEAD)



## v0.3.0 - 2023-08-18

This version upgrades to the latest Pandoc version 3.0 with API version 1.23.

### Added

- Add new AST node struct `Panpipe.AST.Figure`

### Changed

- Remove obsolete `Panpipe.AST.Null` AST node struct

### Fixed

- bug in AST traversal of tables


[Compare v0.2.0...v0.3.0](https://github.com/marcelotto/panpipe/compare/v0.2.0...v0.3.0)



## v0.2.0 - 2021-06-14

This version upgrades to the latest Pandoc version 2.14 with API version 1.22.

### Added

- Add new AST node struct `Panpipe.AST.Underline`

### Changed

- Adapt to the completely redesigned AST structure for tables

[Compare v0.1.1...v0.2.0](https://github.com/marcelotto/panpipe/compare/v0.1.1...v0.2.0)



## v0.1.1 - 2019-10-16

### Changed

- Replaced Porcelain with Rambo dependency - This means the separate Goon 
  executable is no longer required to be installed.

[Compare v0.1.0...v0.1.1](https://github.com/marcelotto/panpipe/compare/v0.1.0...v0.1.1)



## v0.1.0 - 2019-08-19

Initial release
