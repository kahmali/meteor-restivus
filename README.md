# Restivus
#### ReST APIs for the Best of Us!

Restivus makes building ReSTful APIs in Meteor 0.9.0+ an absolute breeze. The package is inspired by
[RestStop2][reststop2-docs] and uses [Iron Router][iron-router]'s server-side routing to provide:
- A simple interface for building ReSTful APIs
- User authentication via the API
  - Optional login and logout endpoints
  - Access to `this.user` in authenticated endpoints
- **NEW!** Role permissions for limiting access to specific endpoints
  - Works alongside the [`alanning:roles`][alanning-roles] package - Meteor's accepted role 
    permission package

## Installation

You can install Restivus using Meteor's package manager:
```bash
> meteor add nimble:restivus
```

And to update Restivus to the latest version:
```bash
> meteor update nimble:restivus
```

## Quick Start

###### CoffeeScript:
```coffeescript
  if Meteor.isServer

    # Global configuration
    Restivus.configure
      useAuth: true

    # Maps to: /api/users
    Restivus.add 'users',
      get: ->
        Meteor.users.find().fetch()
      post:
        authRequired: true
        action: ->
          Accounts.createUser
            email: @bodyParams.email
            password: @bodyParams.password
          Meteor.users.findOne {'emails.address': @bodyParams.email}
      delete:
        roleRequired: ['admin', 'dev']
        action: ->
          if Meteor.users.remove()
            {success: true, message: "All users removed"}
          else
            statusCode: 404
            body: {success: false, message: "No users found"}

    # Maps to: api/friends/abc123
    Restivus.add 'friends/:friendId', {authRequired: true},
      get: ->
        _.findWhere @user.profile.friends, {_id: @urlParams.friendId}
      delete: ->
        if _.contains @user.profile.friends, @urlParams.friendId
          Meteor.users.update(userId, {$pull: {'profile.devices.android': deviceId}})
          {success: true, message: 'Friend removed'}
        else
          statusCode: 404
          body: {success: false, message: 'Friend not found. No friend removed.'}
```

###### JavaScript:
```javascript
  if(Meteor.isServer) {

    // Global configuration
    Restivus.configure({
      useAuth: true
    });

    // Maps to: /api/users
    Restivus.add('users', {
      get: function () {
        return Meteor.users.find().fetch();
      },
      post: {
        authRequired: true,
        action: function () {
          Accounts.createUser({
            email: this.bodyParams.email,
            password: this.bodyParams.password
          });
          return Meteor.users.findOne({emails.address: this.bodyParams.email});
        }
      },
      delete: {
        roleRequired: ['admin', 'dev'],
        action: function () {
          if (Meteor.users.remove()) {
            return {success: true, message: "All users removed"};
          }
          else {
            statusCode: 404,
            body: {success: false, message: "No users found"}
          }
        }
      }
    });

    // Maps to: api/friends/abc123
    Restivus.add('friends/:friendId', {authRequired: true}, {
      get: function () {
        return _.findWhere(this.user.profile.friends, {id: this.urlParams.friendId});
      },
      delete: function () {
        if (_.contains(this.user.profile.friends, this.urlParams.friendId) {
          Meteor.users.update(userId, {$pull: {'profile.devices.android': deviceId}});
          return {success: true, message: 'Friend removed'};
        }
        else {
          return {
            statusCode: 404,
            body: {success: false, message: 'Friend not found. No friend removed.'}
        };
      }
    });
  }
```

## Table of Contents

- [Writing a Restivus API](#writing-a-restivus-api)
  - [Configuration Options](#configuration-options)
  - [Defining Routes](#defining-routes)
    - [Path Structure](#path-structure)
    - [Route Options](#route-options)
    - [Defining Endpoints](#defining-endpoints)
    - [Endpoint Context](#endpoint-context)
    - [Response Data](#response-data)
  - [Documenting Your API](#documenting-your-api)
- [Consuming a Restivus API](#consuming-a-restivus-api)
  - [Basic Usage](#basic-usage)
  - [Authenticating](#authenticating)
  - [Authenticated Calls](#authenticated-calls)

# Writing A Restivus API

## Configuration Options

The following configuration options are available with `Restivus.configure`:
- `useAuth`
  - Default: `false`
  - If true, `POST /login` and `GET /logout` endpoints are added to the API. You can access
    `this.user` and `this.userId` in [authenticated](#authenticating) endpoints.
- `apiPath`
  - Default: `'api'`
  - The base path for your API. If you use 'api' and add a route called 'users', the URL will be
    `https://yoursite.com/api/users/`.
- `prettyJson`
  - Default: `false`
  - If true, render formatted JSON in response.
- `onLoggedIn`
  - Default: `undefined`
  - A hook that runs once a user has been successfully logged into their account via the `/login`
    endpoint. [Context](#endpoint-context) is the same as within authenticated endpoints. Any
    returned data will be added to the response body as `data.extra` (coming soon).
- `onLoggedOut`
  - Default: `undefined`
  - Same as onLoggedIn, but runs once a user has been successfully logged out of their account via
    the `/logout` endpoint. [Context](#endpoint-context) is the same as within authenticated endpoints.
    Any returned data will be added to the response body as `data.extra` (coming soon).

## Defining Routes

Routes are defined using `Restivus.add`. A route consists of a path and a set of endpoints defined
at that path.

### Path Structure

The `path` is the 1st parameter of `Restivus.add`. You can pass it a string or regex. If you pass it
`test/path`, the full path will be `https://yoursite.com/api/test/path`.

Paths can have variable parameters. For example, you can create a route to show a post with a
specific id. The `id` is variable depending on the post you want to see such as "/posts/1" or
"/posts/2". To declare a named parameter in the path, use the `:` syntax followed by the parameter
name. When a user goes to that url, the actual value of the parameter will be stored as a property
on `this.urlParams` in your endpoint function.

In this example we have a parameter named `_id`. If we navigate to the `/post/5` url in our browser,
inside of the GET endpoint function we can get the actual value of the `_id` from
`this.urlParams._id`. In this case `this.urlParams._id => 5`.

###### CoffeeScript:
```coffeescript
# Given a url like "/post/5"
Restivus.add '/post/:_id',
  get: ->
    id = @urlParams._id # "5"
```
###### JavaScript:
```javascript
// Given a url "/post/5"
Restivus.add('/post/:_id', {
  get: function () {
    var id = this.urlParams._id; // "5"
  }
});
```

You can have multiple url parameters. In this example, we have an `_id` parameter and a `commentId`
parameter. If you navigate to the url `/post/5/comments/100` then inside your endpoint function
`this.params._id => 5` and `this.params.commentId => 100`.

###### CoffeeScript:
```coffeescript
# Given a url "/post/5/comments/100"
Restivus.add '/post/:_id/comments/:commentId',
  get: ->
    id = @urlParams._id # "5"
    commentId = @urlParams.commentId # "100"
```

###### JavaScript:
```javascript
// Given a url "/post/5/comments/100"
Restivus.add('/post/:_id/comments/:commentId', {
  get: function () {
    var id = this.urlParams._id; // "5"
    var commentId = this.urlParams.commentId; // "100"
  }
});
```

If there is a query string in the url, you can access that using `this.queryParams`.

###### Coffeescript:
```coffeescript
# Given the url: "/post/5?q=liked#hash_fragment"
Restivus.add '/post/:_id',
  get: ->
    id = @urlParams._id
    query = @queryParams # query.q -> "liked"
```

###### JavaScript:
```javascript
// Given the url: "/post/5?q=liked#hash_fragment"
Restivus.add('/post/:_id', {
  get: function () {
    var id = this.urlParams._id;
    var query = this.queryParams; // query.q -> "liked"
  }
});
```

### Route Options

The following options are available in Restivus.add (as the 2nd, optional parameter):
- `authRequired`
  - Default: `false`
  - If true, all endpoints on this route will return a `401` if the user is not properly
    [authenticated](#authenticating).
- `roleRequired`
  - Default: `undefined` (no role required)
  - A string or array of strings corresponding to the acceptable user roles for all endpoints on
    this route (e.g., `'admin'`, `['admin', 'dev']`). Additional role permissions can be defined on
    specific endpoints. If the authenticated user does not belong to at least one of the accepted
    roles, a `401` is returned. Since a role cannot be verified without an authenticated user,
    setting the `roleRequired` implies `authRequired: true`, so that option can be omitted without
    any consequence. For more on setting up roles, check out the [`alanning:roles`][alanning-roles]
    package.

### Defining Endpoints

The last parameter of Restivus.add is an object with properties corresponding to the supported HTTP
methods. At least one method must have an endpoint defined on it. The following endpoints can be
defined in Restivus:
- `get`
- `post`
- `put`
- `delete`
- `patch`

These endpoints can be defined one of two ways. First, you can simply provide a function for each
method you want to support at the given path. The corresponding endpoint will be executed when that
type of request is made at that path.

Otherwise, for finer-grained control over each endpoint, you can also define each one as an object
with the following properties:
- `authRequired`
  - Default: `false`
  - If true, this endpoint will return a `401` if the user is not properly
    [authenticated](#authenticating). Overrides the option of the same name defined on the entire
    route.
- `roleRequired`
  - Default: `undefined` (no role required)
  - A string or array of strings corresponding to the acceptable user roles for this endpoint (e.g.,
    `'admin'`, `['admin', 'dev']`). These roles will be accepted in addition to any defined over the
    entire route. If the authenticated user does not belong to at least one of the accepted roles, a
    `401` is returned. Since a role cannot be verified without an authenticated user, setting the
    `roleRequired` implies `authRequired: true`, so that option can be omitted without any
    consequence. For more on setting up roles, check out the [`alanning:roles`][alanning-roles]
    package.
- `action`
  - Default: `undefined`
  - A function that will be executed when a request is made for the corresponding HTTP method.

###### CoffeeScript
```coffeescript
Restivus.add 'posts', {authRequired: true},
  get:
    authRequired: false
    action: ->
      # GET api/posts
  post: ->
    # POST api/posts
  put: ->
    # PUT api/posts
  patch: ->
    # PATCH api/posts
  delete: ->
    # DELETE api/posts
```

###### JavaScript
```javascript
Restivus.add('posts', {authRequired: true}, {
  get: function () {
    authRequired: false
    action: function () {
      // GET api/posts
    }
  },
  post: function () {
    // POST api/posts
  },
  put: function () {
    // PUT api/posts
  },
  patch: function () {
    // PATCH api/posts
  },
  delete: function () {
    // DELETE api/posts
  }
```
In the above examples, all the endpoints except the GETs will require
[authentication](#authenticating).

### Endpoint Context

Each endpoint has access to:
- `this.user`
  - The authenticated `Meteor.user`. Only available if `useAuth` and
    `authRequired` are both `true`. If not, it will be `undefined`.
- `this.userId`
  - The authenticated user's `Meteor.userId`. Only available if `useAuth` and `authRequired` are both `true`. If
    not, it will be `undefined`.
- `this.urlParams`
  - Non-optional parameters extracted from the URL. A parameter `id` on the path `posts/:id` would
    be available as `this.urlParams.id`.
- `this.queryParams`
  - Optional query parameters from the URL. Given the url `https://yoursite.com/posts?likes=true`,
    `this.queryParams.likes => true`.
- `this.bodyParams`
  - Parameters passed in the request body. Given the request body
    `{ "friend": { "name": "Jack" } }`, `this.bodyParams.friend.name => "Jack"`.
- `this.request`
  - The [Node request object][node-request]
- `this.response`
  - The [Node response object][node-response]

### Response Data

You can return a raw string:
```javascript
return "That's current!";
```

A JSON object:
```javascript
return { json: 'object' };
```

A raw array:
```javascript
return [ 'red', 'green', 'blue' ];
```

Or optionally include a `statusCode` or `headers`. At least one must be provided along with the
`body`:
```javascript
return {
  statusCode: 404,
  headers: {
    'Content-Type': 'text/plain'
  },
  body: {
    success: false,
    message: "There's nothing here!"
  }
};
```

All responses contain the following defaults, which will be overridden with any provided values:
- Status code: `200`
- Headers:
  - `Content-Type`: `text/json`
  - `Access-Control-Allow-Origin`: `*`
    - This is a CORS-compliant header that allows requests to be made to the API from any domain.
      Without this, requests from within the browser would only be allowed from the same domain the
      API is hosted on, which is typically not the intended behavior. To prevent this, override it
      with your domain.

## Documenting Your API

What's a ReST API without awesome docs? I'll tell you: absolutely freaking useless. So to fix that,
we use and recommend [apiDoc][]. It allows you to generate beautiful and extremely handy API docs
from your JavaScript or CoffeeScript comments. It supports other comment styles as well, but we're
Meteorites, so who cares? Check it out. Use it.

# Consuming A Restivus API

The following uses the above code.

## Basic Usage

We can call our `POST /posts/:id/comments` endpoint the following way. Note the /api/ in the URL
(defined with the api_path option above):
```bash
curl --data "message=Some message details" http://localhost:3000/api/posts/3/comments
```

## Authenticating

If you have `useAuth` set to `true`, you now have a `/login` endpoint that returns a `userId` and
`authToken`. You must save these, and include them in subsequent requests.

**Note: Make absolute certain you're using HTTPS, otherwise this is insecure. In an ideal world,
this should only be done with DDP and SRP, but, alas, this is a ReSTful API.**

```bash
curl --data "password=testpassword&user=test" http://localhost:3000/api/login/
```

The response will look something like this, which you must save (for subsequent requests):
```javascript
{ success: true, authToken: "f2KpRW7KeN9aPmjSZ", userId: fbdpsNf4oHiX79vMJ }
```

## Authenticated Calls

Since this is a RESTful API (and it's meant to be used by non-browsers), you must include the
`userId` and `authToken` with each request under the following headers:
- X-User-Id
- X-Auth-Token

```bash
curl --data "userId=fbdpsNf4oHiX79vMJ&authToken=f2KpRW7KeN9aPmjSZ" http://localhost:3000/api/posts/
```

Or, pass it as a header. This is probably a bit cleaner:
```bash
curl -H "X-Auth-Token: f2KpRW7KeN9aPmjSZ" -H "X-User-Id: fbdpsNf4oHiX79vMJ" http://localhost:3000/api/posts/
```

## Thanks

Thanks to the developers over at Differential for [RestStop2][], where we got our inspiration for
this package and stole tons of ideas and code, as well as the [Iron Router][iron-router] team for
giving us a solid foundation with their server-side routing in Meteor.

Also, thanks to the following projects, which RestStop2 was inspired by:
- [gkoberger/meteor-reststop](https://github.com/gkoberger/meteor-reststop)
- [tmeasday/meteor-router](https://github.com/tmeasday/meteor-router)
- [crazytoad/meteor-collectionapi](https://github.com/crazytoad/meteor-collectionapi)

## License

MIT License. See LICENSE for details.


[reststop2-docs]:    http://github.differential.com/reststop2/                       "RestStop2 Docs"
[reststop2]:         https://github.com/Differential/reststop2                       "RestStop2"
[iron-router]:       https://github.com/EventedMind/iron-router                      "Iron Router"
[node-request]:      http://nodejs.org/api/http.html#http_http_incomingmessage       "Node Request Object Docs"
[node-response]:     http://nodejs.org/api/http.html#http_class_http_serverresponse  "Node Response Object Docs"
[jsend]:             http://labs.omniti.com/labs/jsend                               "JSend ReST API Standard"
[apidoc]:            http://apidocjs.com/                                            "apiDoc"
[alanning-roles]:    https://github.com/alanning/meteor-roles                        "Meteor Roles Package"