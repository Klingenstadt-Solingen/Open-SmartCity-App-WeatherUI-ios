<div style="display:flex;gap:1%;margin-bottom:20px">
  <h1 style="border:none">Open SmartCity Weather UI Module of the Open SmartCity App</h1>
  <img height="100px" alt="logo" src="Docs/img/logo.svg">
</div>

## Important Notice

- **Changed Commit History** Commit history changed due to removal of credentials in previous commits ❗❗❗
- **Read-Only Repository:** This GitHub repository is a mirror of our project's source code. It is not intended for direct changes.
- **Contribution Process:** Once our Open Code platform is live, any modifications, improvements, or contributions must be made through our [Open Code](https://gitlab.opencode.de/) platform. Direct changes via GitHub are not accepted.

---

- [Important Notice](#important-notice)
- [Changelog 📝](#changelog-)
- [License](#license)

<p align="center">
<img src="https://img.shields.io/badge/Platform%20Compatibility%20-ios-red">
<img src="https://img.shields.io/badge/Swift%20Compatibility%20-5.5%20%7C%205.4%20%7C%205.3%20%7C%205.2%20%7C%205.1-blue">
<a href="#"><img src="https://img.shields.io/badge/Swift-Doc-inactive"></a>
<a href="https://swift.org/package-manager/"><img src="https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat"></a>
</p>

## Features
- [x] List your features

## Requirements

- iOS 13.0+
- Swift 5.0+
- [SwiftDate 7.0.0+](https://github.com/malcommac/SwiftDate/releases/tag/7.0.0)

### Installation
#### Swift Package Manager
- File > Swift Packages > Add Package Dependency
- Add `URL`
- Select "Up to Next Major" with "VERSION"
#### `SupportingFiles` secrets #####
* copy `Development.xcconfig` and `Production.xcconfig` to `OSCAWeathertUI/OSCAWeatherUI/SupportingFiles`, these files have to be ignored by git
### Deeplinking
|                |                                            |
|---             |---                                         |
| Weather overview: | `{scheme}://sensorstation/`                         |
| Weather detail:   | `{scheme}://sensorstation/detail?object={objectId}` |

## Other
### Developments and Tests

Any contributing and pull requests are warmly welcome. However, before you plan to implement some features or try to fix an uncertain issue, it is recommended to open a discussion first. It would be appreciated if your pull requests could build and with all tests green.

## Changelog 📝

Please see the [Changelog](CHANGELOG.md).

## License

OSCA Server is licensed under the [Open SmartCity License](LICENSE.md).
