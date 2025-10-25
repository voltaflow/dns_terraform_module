# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of multi-provider DNS Terraform module
- Support for AWS Route53, Cloudflare, and Vercel
- Dual input mode: JSON files and Terraform variables
- Built-in validation for record type compatibility
- Migration scripts for moving between providers
- Comprehensive documentation and examples
- CI/CD pipeline with validation, testing, linting, and automated releases
- JSON schema for configuration validation

### Features
- **AWS Route53**: Alias records, delegation sets, health checks support
- **Cloudflare**: Proxy mode (CDN + DDoS protection)
- **Vercel**: Native integration with Vercel projects
- Automatic provider-specific transformations
- Validation warnings for unsupported record types
- Post-deployment instructions per provider

## [0.1.0] - 2025-10-24

### Added
- Project initialization
- Core module structure
- Provider-specific submodules
- Documentation and examples
- License (MIT)
- Initial CHANGELOG

---

**Note**: This changelog will be automatically updated by semantic-release based on conventional commits.
