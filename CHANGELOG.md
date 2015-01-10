# Change Log

## [v0.5.1] - 2014-01-10

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

#### Fixed
- `Content-Type` header in endpoint response will default to `text/json` if not overridden by user


## [v0.5.0] - 2014-01-04
- Initial release

[v0.5.0]:  https://github.com/krose72205/meteor-restivus/releases/tag/v0.5.0 "v0.5.0"
[v0.5.1]:  https://github.com/krose72205/meteor-restivus/releases/tag/v0.5.1 "v0.5.1"
