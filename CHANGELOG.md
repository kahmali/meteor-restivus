# Change Log

## [v0.5.4] - 2015-01-27

#### Fixed
- The default api path ('api/') is used if no apiPath is provided in Restivus.configure() (would
  previously crash Meteor).
- Only a `config.apiPath` that is missing the trailing '/' will have it appended during API
  configuration


## [v0.5.3] - 2015-01-15

#### Fixed
- Context in onLoggedIn and onLoggedOut hooks is now the same as within an
  [authenticated endpoint][endpoint context]

#### Added
- Access `this.userId` within authenticated endpoints

#### Updated
- README
  - Add `this.userId` to [Endpoint Context]
  - [Specify context][configuration options] in `onLoggedIn` and `onLoggedOut` hooks


## [v0.5.2] - 2015-01-14

#### Fixed
- Prevent endpoint from being called if authentication fails (and return 401)

#### Added
- Support pretty JSON in API configuration

#### Updated
- README
  - Show endpoint object in 'Quick Start' code examples
  - Restructure topic hierarchy
  - Change 'Route Structure' section to 'Path Structure' and reword for consistent use of
    terminology
  - Add `prettyJson` to [Configuration Options]


## [v0.5.1] - 2015-01-10

#### Fixed
- `Content-Type` header in endpoint response will default to `text/json` if not overridden by user

#### Added
- Allow cross-domain requests to API from browsers (CORS-compliant)

#### Updated
- README
  - Clean up code examples
  - Add section on documenting API with apiDoc
  - Specify supported Meteor version
  - Add section on default http response configuration
  - Make it more readable in plain-text format
- Terminology (in code, comments, and README)
  - `Method`: The type of HTTP request (e.g., GET, PUT, POST, etc.)
  - `Endpoint`: The function executed when a request is made at a given path for a specific HTTP method
  - `Route`: A path and a set of endpoints


## [v0.5.0] - 2015-01-04
- Initial release



[v0.5.4]:  https://github.com/krose72205/meteor-restivus/releases/tag/v0.5.4 "Version 0.5.4"
[v0.5.3]:  https://github.com/krose72205/meteor-restivus/releases/tag/v0.5.3 "Version 0.5.3"
[v0.5.2]:  https://github.com/krose72205/meteor-restivus/releases/tag/v0.5.2 "Version 0.5.2"
[v0.5.1]:  https://github.com/krose72205/meteor-restivus/releases/tag/v0.5.1 "Version 0.5.1"
[v0.5.0]:  https://github.com/krose72205/meteor-restivus/releases/tag/v0.5.0 "Version 0.5.0"

[configuration options]: https://github.com/krose72205/meteor-restivus#configuration-options "Configuration Options"
[endpoint context]: https://github.com/krose72205/meteor-restivus#endpoint-context "Endpoint Context"
