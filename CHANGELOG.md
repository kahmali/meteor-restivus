# Change Log

## [v0.5.6] - 2015-01-31

#### Fixed
- Issue #2: Make Restivus.\_initAuth() private only by convention for proper context. Context was
  accidentally altered when refactoring Restivus into a class in latest update.


## [v0.5.5] - 2015-01-30

#### Added
- User role permissions for limiting access to endpoints (works alongside the `alanning:roles`
  package)

#### Updated
- Resolve and configure endpoints during Route construction, to prevent a bunch of unnecessary
  processing every time an endpoint was being accessed. This should yield at least a minor
  performance gain on all endpoints.
- Refactor Route and Restivus into CoffeeScript classes
- README
  - Add info on setting up role permissions to [Route Options] and [Defining Endpoints] sections
  - Update Quick Start example to show definition of role permissions on an endpoint


## [v0.5.4] - 2015-01-27

#### Fixed
- Issue #1: The default api path ('api/') is used if no apiPath is provided in Restivus.configure() (would
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



[v0.5.6]:  https://github.com/kahmali/meteor-restivus/compare/v0.5.5...v0.5.6 "Version 0.5.6"
[v0.5.5]:  https://github.com/kahmali/meteor-restivus/compare/v0.5.4...v0.5.5 "Version 0.5.5"
[v0.5.4]:  https://github.com/kahmali/meteor-restivus/compare/v0.5.3...v0.5.4 "Version 0.5.4"
[v0.5.3]:  https://github.com/kahmali/meteor-restivus/compare/v0.5.2...v0.5.3 "Version 0.5.3"
[v0.5.2]:  https://github.com/kahmali/meteor-restivus/compare/v0.5.1...v0.5.2 "Version 0.5.2"
[v0.5.1]:  https://github.com/kahmali/meteor-restivus/compare/v0.5.0...v0.5.1 "Version 0.5.1"
[v0.5.0]:  https://github.com/kahmali/meteor-restivus/compare/d4ae97...v0.5.0 "Version 0.5.0"

[configuration options]: https://github.com/kahmali/meteor-restivus#configuration-options "Configuration Options"
[endpoint context]: https://github.com/kahmali/meteor-restivus#endpoint-context "Endpoint Context"
[defining endpoints]: https://github.com/kahmali/meteor-restivus#defining-endpoints "Defining Endpoints"
[route options]: https://github.com/kahmali/meteor-restivus#route-options "Route Options"
