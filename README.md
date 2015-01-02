# Restivus
#### ReST APIs for the Best of US!

Restivus makes building ReSTful APIs in Meteor an absolute breeze. The package is inspired by [RestStop2][reststop2-docs] and uses [Iron Router][iron-router]'s server-side routing to provide:
- A simple interface for building ReSTful APIs
- User authentication via the API
  - Optional login and logout endpoints
  - Access to `this.user` in authenticated endpoints
- Role permissions on endpoints coming soon!

## Installation

You can install Restivus using Meteor's package manager:
```bash
> meteor add nimble:restivus
```
To update Restivus to the latest version just use the `meteor update` command:

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
      post: ->
        Accounts.createUser
          email: this.bodyParams.email
          password: this.bodyParams.password
        Meteor.users.findOne {emails.address: this.bodyParams.email}

    # Maps to: api/friends/abc123
    Restivus.add 'friends/:friendId', {authRequired: true},
      get: ->
        _.findWhere this.user.profile.friends, {id: this.urlParams.friendId}
      delete: ->
        if _.contains this.user.profile.friends, this.urlParams.friendId
          Meteor.users.update(userId, {$pull: {'profile.devices.android': deviceId}})
          {success: true, message: 'Friend removed'}
        else
          [404, {success: false, message: 'Friend not found. No friend removed.'}]
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
      }
      post: function () {
        Accounts.createUser({
          email: this.bodyParams.email,
          password: this.bodyParams.password
        });
        return Meteor.users.findOne({emails.address: this.bodyParams.email});
      }
    });

    // Maps to: api/friends/abc123
    Restivus.add('friends/:friendId', {authRequired: true}, {
      get: function () {
        return _.findWhere(this.user.profile.friends, {id: this.urlParams.friendId});
      }
      delete: function () {
        if (_.contains(this.user.profile.friends, this.urlParams.friendId) {
          Meteor.users.update(userId, {$pull: {'profile.devices.android': deviceId}});
          return {success: true, message: 'Friend removed'};
        }
        else {
          return [404, {success: false, message: 'Friend not found. No friend removed.'}];
        }
      }
    });
  }
```

## Table of Contents

- [Writing a Restivus API](#writing-a-restivus-api)
  - [Configuration Options](#configuration-options)
  - [Route Structure](#route-structure)
  - [Route Options](#route-options)
  - [Method Context](#method-context)
  - [Response Data](#response-data)
- [Consuming a Restivus API](#consuming-a-restivus-api)
  - [Basic Usage](#basic-usage)
  - [Authenticating](#authenticating)
  - [Authenticated Calls](#authenticated-calls)

# Writing A Restivus API

## Configuration Options

The following configuration options are available with `Restivus.configure`:
- `useAuth`
  - Default: `false`
  - If true, `/login` and `/logout` routes are added to the API. You can access `this.user` in [authenticated][#authenticating] endpoints.
- `apiPath`
  - Default: `'api'`
  - The base path for your API. If you use 'api' and add a route called 'users', the URL will be
    `https://yoursite.com/api/users/`.
- `prettyJson`
  - Default: `false`
  - If true, render formatted JSON in responses.
- `onLoggedIn`
  - Default: `undefined`
  - A hook that runs once a user has been successfully logged into their account via the `/login` endpoint. You can access `this.user` from within the function you define, and any returned data will be added to the response body as `data.extra` (coming soon).
- `onLoggedOut`
  - Default: `undefined`
  - Same as onLoggedIn, but runs once a user has been successfully logged out of their account via the `/logout` endpoint.

## Route Structure

The `path` is the 1st parameter of `Restivus.add`. You can pass it a string or regex. If you pass it `test/path`, the full path will be `https://yoursite.com/api/test/path`.

Routes can have variable parameters. For example, you can create one route to
show any post with an id. The `id` is variable depending on the post you want to
see such as "/posts/1" or "/posts/2". To declare a named parameter in your route
use the `:` syntax in the url followed by the parameter name. When a user goes
to that url, the actual value of the parameter will be stored as a property on
`this.urlParams` in your endpoint function.

In this example we have a route parameter named `_id`. If we navigate to the
`/post/5` url in our browser, inside of the route function we can get the actual
value of the `_id` from `this.urlParams._id`. In this case `this.params._id => 5`.

###### CoffeeScript:
```coffeescript
# Given a url like "/post/5"
Restivus.add '/post/:_id',
  get: ->
    urlParams = this.urlParams # { _id: "5" }
    id = urlParams._id # "5"
```
###### JavaScript:
```javascript
// Given a url "/post/5"
Restivus.add('/post/:_id', {
  get: function () {
    var params = this.urlParams; // { _id: "5" }
    var id = urlParams._id; // "5"
  }
});
```

You can have multiple route parameters. In this example, we have an `_id`
parameter and a `commentId` parameter. If you navigate to the url
`/post/5/comments/100` then inside your route function `this.params._id => 5`
and `this.params.commentId => 100`.

###### CoffeeScript:
```coffeescript
# Given a url "/post/5/comments/100"
Restivus.add '/post/:_id/comments/:commentId',
  get: ->
    id = this.urlParams._id # "5"
    commentId = this.urlParams.commentId # "100"
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

If there is a query string or hash fragment in the url, you can access those
using the `query` and `hash` properties of the `this.params` object.

###### Coffeescript:
```coffeescript
# Given the url: "/post/5?q=liked"
Restivus.add '/post/:_id',
  get: ->
    var id = this.urlParams._id
    var query = this.urlParams.query # query.q -> "liked"
```

###### JavaScript:
```javascript
// Given the url: "/post/5?q=liked"
Restivus.add('/post/:_id', {
  get: function () {
    var id = this.urlParams._id;
    var query = this.urlParams.query; // query.q -> "liked"
  }
});
```

## Route Options

The following options are available in Restivus.add (as the 2nd, optional parameter):
-`authRequired`
  - Default: false
  - If true, all methods on this endpoint will return a 401 if the user is not properly [authenticated][#authentication].


## Method Definition

The last parameter of Restivus.add is an object with properties corresponding to the supported HTTP methods. The following methods can be defined in Restivus:
- `get`
- `post`
- `put`
- `delete`
- `patch`

These methods can be defined one of two ways. First, you can simply provide a function for each method you want to support at the given path. The corresponding method will be executed when that type of request is made at that path. Otherwise, for finer-grained control over each method, you can also define each one as an object with the following properties:
- `authRequired`
  - Default: false
  - If true, this method will return a 401 if the user is not properly [authenticated][#authentication]. Overrides the option of the same name defined on the entire route.
- `action`
  - Default: undefined
  - A function that will be executed when a request is made for the corresponding HTTP method.


## Method Context

Each method has access to:
- `this.user`
  - The [authenticated][#authenticating] `Meteor.user`. Only available if `useAuth` and `authRequired` are both `true`. If not, it will be `false`.
- `this.urlParams`
  - Non-optional parameters extracted from the URL. A parameter `id` on the path `posts/:id` would be available as `this.urlParams.id`.
- `this.queryParams`
  - Optional query parameters from the URL. Given the url `https://yoursite.com/posts?likes=true`, `this.queryParams.likes => true`.
- `this.bodyParams`
  - Parameters passed in the request body. Given the request body `{ "friend": { "name": "Jack" } }`, `this.bodyParams.friend.name => "Jack"`.
- `this.request`
  - The [Node request object][node-request]
- `this.response`
  - The [Node response object][node-response]


## Response Data

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

Include a status code by using an array with the status code as the first element:
```javascript
return [404, { success: false, message: "There's nothing here!" }];
```

Include a status code AND headers (first and second elements, respectively):
```javascript
return [404, { 'Content-Type': 'text/plain' }, { success: false, message: "There's nothing here!" }];
```

Or just skip using a function at all, and just provide the return data when adding a route to the API:
```javascript
Restivus.add('/404', [404, "There's nothing here!"]);
```

# Consuming A Restivus API

The following uses the above code.

Any results specified by Restivus (mostly errors) will include a JSON object that follows the [JSend][] standard.

## Basic Usage

We can call our `POST /posts/:id/comments` endpoint the following way. Note the /api/ in the URL (defined with the api_path option above):
```bash
curl --data "message=Some message details" http://localhost:3000/api/posts/3/comments
```


## Authenticating

If you have `useAuth` set to `true`, you now have a `/login` method that returns a `userId` and `authToken`. You must save these, and include them in subsequent requests.

(Note: Make absolute certain you're using HTTPS, otherwise this is insecure. In an ideal world, this should only be done with DDP and SRP, but, alas, this is a ReSTful API.)

```bash
curl --data "password=testpassword&user=test" http://localhost:3000/api/login/
```

The response will look something like this, which you must save (for subsequent requests):
```javascript
{ success: true, authToken: "f2KpRW7KeN9aPmjSZ", userId: fbdpsNf4oHiX79vMJ }
```

## Authenticated Calls

Since this is a RESTful API (and it's meant to be used by non-browsers), you must include the `userId` and `authToken` with each request under the following headers:
- X-User-Id
- X-Auth-Token

```bash
curl --data "userId=fbdpsNf4oHiX79vMJ&authToken=f2KpRW7KeN9aPmjSZ" http://localhost:3000/api/posts/
```

Or, pass it as a header. This is probably a bit cleaner:
```bash
curl -H "X-Auth-Token: f2KpRW7KeN9aPmjSZ" -H "X-User-Id: fbdpsNf4oHiX79vMJ" http://localhost:3000/api/posts/
```
# Thanks To

Thanks to the developers over at Differential for [RestStop2][], where we got our inspiration for this package and stole tons of ideas and code, as well as the [Iron Router][iron-router] team for giving us a solid foundation with their server-side routing in Meteor.



[reststop2-docs]:    http://github.differential.com/reststop2/   "RestStop2 Docs"
[reststop2]:    https://github.com/Differential/reststop2   "RestStop2"
[iron-router]:  https://github.com/EventedMind/iron-router  "Iron Router"
[node-request]:  http://nodejs.org/api/http.html#http_http_incomingmessage  "Node Request Object Docs"
[node-response]:  http://nodejs.org/api/http.html#http_class_http_serverresponse  "Node Response Object Docs"
[jsend]:  http://labs.omniti.com/labs/jsend  "JSend ReST API Standard"