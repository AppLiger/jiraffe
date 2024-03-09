# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Token generation
- QSH module

## [0.1.2] - 2024-03-09

### Fixed

- Pagination in general
- Some test case descriptions

## [0.1.1] - 2024-02-25

### Fixed

- Issue.get_edit_metadata specification
- Jiraffe client function and type name collision
- Some warnings

### Changed

- Moved some types inside the corresponding specifications

### Added

- A guard agains wrong params in Issue.Field.Metadata.Schema.new

## [0.1.0] - 2024-02-23

### Changed

- Rename the modules into singular form
- Return corresponding structs instead of raw JSON (Map) responses
- Improve the documentation
- Update Elixir to 1.16

### Added

- Structs to represent Jira entities
  - Agile.Sprint
  - Issue
  - Issue.CreateMetadata
  - Issue.EditMetadata
  - Issue.Link
  - User
  - etc
- Pagination module to simplify pagination handling
- Development Container

## [0.0.1] - 2024-01-17

### Added

- Issues module for managing issues
- Issues.Search module for searching issues using JQL
- Links module for managing issue links
- Users module for managing users
- Permissions module to get user permissions
- Agile.Sprints module for handling sprint-related APIs
- Agile.Issues module for ranking issues in Jira Software projects
