Meteor.startup ->

  describe 'An API', ->
    describe 'that hasn\'t been configured', ->
      it 'should have default settings', (test) ->
        test.equal Restivus.config.apiPath, 'api/'
        test.isFalse Restivus.config.useAuth
        test.isFalse Restivus.config.prettyJson
        test.equal Restivus.config.auth.token, 'services.resume.loginTokens.hashedToken'

      it 'should allow you to add an unconfigured route', (test) ->
        Restivus.addRoute 'add-unconfigured-route', {authRequired: true, roleRequired: 'admin'},
          get: ->
            1
        # TODO: Access routes in a less brittle way than this index that can change when new routes are added (more below)
        route = Restivus.routes[2]
        test.equal route.path, 'add-unconfigured-route'
        test.equal route.endpoints.get(), 1
        test.isTrue route.options.authRequired
        test.equal route.options.roleRequired, 'admin'
        test.isUndefined route.endpoints.get.authRequired
        test.isUndefined route.endpoints.get.roleRequired

      it 'should allow you to add an unconfigured collection route', (test) ->
        Restivus.addCollection new Mongo.Collection('add-unconfigured-collection'),
          routeOptions:
            authRequired: true
            roleRequired: 'admin'
          endpoints:
            getAll:
              action: ->
                2

        route = Restivus.routes[3]
        test.equal route.path, 'add-unconfigured-collection'
        test.equal route.endpoints.get.action(), 2
        test.isTrue route.options.authRequired
        test.equal route.options.roleRequired, 'admin'
        test.isUndefined route.endpoints.get.authRequired
        test.isUndefined route.endpoints.get.roleRequired

      it 'should be configurable', (test) ->
        Restivus.configure
          apiPath: 'api/v1'
          useAuth: true
          defaultHeaders:
            'Content-Type': 'text/json'
            'X-Test-Header': 'test header'
          defaultOptionsEndpoint: ->
            headers:
              'Content-Type': 'text/plain'
            body:
              'options'

        config = Restivus.config
        test.equal config.apiPath, 'api/v1/'
        test.equal config.useAuth, true
        test.equal config.auth.token, 'services.resume.loginTokens.hashedToken'
        test.equal config.defaultHeaders['Content-Type'], 'text/json'
        test.equal config.defaultHeaders['X-Test-Header'], 'test header'
        test.equal config.defaultHeaders['Access-Control-Allow-Origin'], '*'

    describe 'that has been configured', ->
      it 'should not allow reconfiguration', (test) ->
        test.throws Restivus.configure, 'Restivus.configure() can only be called once'

      it 'should configure any previously added routes', (test) ->
        route = Restivus.routes[2]
        test.equal route.endpoints.get.action(), 1
        test.isTrue route.endpoints.get.authRequired
        test.equal route.endpoints.get.roleRequired, ['admin']

      it 'should configure any previously added collection routes', (test) ->
        route = Restivus.routes[3]
        test.equal route.endpoints.get.action(), 2
        test.isTrue route.endpoints.get.authRequired
        test.equal route.endpoints.get.roleRequired, ['admin']


  describe 'An API route', ->
    it 'should use the default OPTIONS endpoint if none is defined for the requested method', (test, waitFor) ->
      Restivus.addRoute 'default-endpoints',
        get: ->
          'get'

      HTTP.call 'OPTIONS', Meteor.absoluteUrl('api/v1/default-endpoints'), waitFor (error, result) ->
        response = result.content
        test.equal result.statusCode, 200
        test.equal response, 'options'


  describe 'An API collection route', ->
    it 'should be able to exclude endpoints using just the excludedEndpoints option', (test, waitFor) ->
      Restivus.addCollection new Mongo.Collection('excluded-endpoints'),
        excludedEndpoints: ['get', 'getAll']

      HTTP.get Meteor.absoluteUrl('api/v1/excluded-endpoints/10'), waitFor (error, result) ->
        response = JSON.parse result.content
        test.isTrue error
        test.equal result.statusCode, 405
        test.equal response.status, 'error'
        test.equal response.message, 'API endpoint does not exist'

      HTTP.get Meteor.absoluteUrl('api/v1/excluded-endpoints/'), waitFor (error, result) ->
        response = JSON.parse result.content
        test.isTrue error
        test.equal result.statusCode, 405
        test.equal response.status, 'error'
        test.equal response.message, 'API endpoint does not exist'

      # Make sure it doesn't exclude any endpoints it shouldn't
      HTTP.post Meteor.absoluteUrl('api/v1/excluded-endpoints/'), {data: test: 'abc'}, waitFor (error, result) ->
        response = JSON.parse result.content
        test.equal result.statusCode, 201
        test.equal response.status, 'success'
        test.equal response.data.test, 'abc'

    describe 'with the default autogenerated endpoints', ->
      Restivus.addCollection new Mongo.Collection('autogen')
      testId = null

      it 'should support a POST on api/collection', (test) ->
        result = HTTP.post Meteor.absoluteUrl('api/v1/autogen'),
          data:
            name: 'test name'
            description: 'test description'
        response = JSON.parse result.content
        responseData = response.data
        test.equal result.statusCode, 201
        test.equal response.status, 'success'
        test.equal responseData.name, 'test name'
        test.equal responseData.description, 'test description'

        # Persist the new resource id
        testId = responseData._id

      it 'should not support a DELETE on api/collection', (test, waitFor) ->
        HTTP.del Meteor.absoluteUrl('api/v1/autogen'), waitFor (error, result) ->
          response = JSON.parse result.content
          test.isTrue error
          test.equal result.statusCode, 405
          test.isTrue result.headers['allow'].indexOf('POST') != -1
          test.isTrue result.headers['allow'].indexOf('GET') != -1
          test.equal response.status, 'error'
          test.equal response.message, 'API endpoint does not exist'

      it 'should support a PUT on api/collection/:id', (test) ->
        result = HTTP.put Meteor.absoluteUrl("api/v1/autogen/#{testId}"),
          data:
            name: 'update name'
            description: 'update description'
        response = JSON.parse result.content
        responseData = response.data
        test.equal result.statusCode, 200
        test.equal response.status, 'success'
        test.equal responseData.name, 'update name'
        test.equal responseData.description, 'update description'

        result = HTTP.put Meteor.absoluteUrl("api/v1/autogen/#{testId}"),
          data:
            name: 'update name with no description'
        response = JSON.parse result.content
        responseData = response.data
        test.equal result.statusCode, 200
        test.equal response.status, 'success'
        test.equal responseData.name, 'update name with no description'
        test.isUndefined responseData.description


  describe 'An API endpoint', ->

    it 'should respond with the default headers when not overridden', (test) ->
      Restivus.addRoute 'default-headers',
        get: ->
          true

      result = HTTP.get Meteor.absoluteUrl 'api/v1/default-headers'

      test.equal result.statusCode, 200
      test.equal result.headers['content-type'], 'text/json'
      test.equal result.headers['x-test-header'], 'test header'
      test.equal result.headers['access-control-allow-origin'], '*'
      test.isTrue result.content

    it 'should allow default headers to be overridden', (test) ->
      Restivus.addRoute 'override-default-headers',
        get: ->
          headers:
            'Content-Type': 'application/json'
            'Access-Control-Allow-Origin': 'https://mywebsite.com'
          body:
            true

      result = HTTP.get Meteor.absoluteUrl 'api/v1/override-default-headers'

      test.equal result.statusCode, 200
      test.equal result.headers['content-type'], 'application/json'
      test.equal result.headers['access-control-allow-origin'], 'https://mywebsite.com'
      test.isTrue result.content

    it 'should have access to multiple query params', (test, waitFor) ->
      Restivus.addRoute 'mult-query-params',
        get: ->
          test.equal @queryParams.key1, '1234'
          test.equal @queryParams.key2, 'abcd'
          test.equal @queryParams.key3, 'a1b2'
          true

      HTTP.get Meteor.absoluteUrl('api/v1/mult-query-params?key1=1234&key2=abcd&key3=a1b2'), waitFor (error, result) ->
        test.isTrue result

    it 'should return a 405 error if that method is not implemented on the route', (test, waitFor) ->
      Restivus.addCollection new Mongo.Collection('method-not-implemented'),
        excludedEndpoints: ['get', 'getAll']

      HTTP.get Meteor.absoluteUrl('api/v1/method-not-implemented/'), waitFor (error, result) ->
        response = JSON.parse result.content
        test.isTrue error
        test.equal result.statusCode, 405
        test.isTrue result.headers['allow'].indexOf('POST') != -1
        test.equal response.status, 'error'
        test.equal response.message, 'API endpoint does not exist'

      HTTP.get Meteor.absoluteUrl('api/v1/method-not-implemented/10'), waitFor (error, result) ->
        response = JSON.parse result.content
        test.isTrue error
        test.equal result.statusCode, 405
        test.isTrue result.headers['allow'].indexOf('PUT') != -1
        test.isTrue result.headers['allow'].indexOf('DELETE') != -1
        test.equal response.status, 'error'
        test.equal response.message, 'API endpoint does not exist'

    it 'should cause an error when it returns null', (test, waitFor) ->
      Restivus.addRoute 'null-response',
        get: ->
          null

      HTTP.get Meteor.absoluteUrl('api/v1/null-response'), waitFor (error, result) ->
        test.isTrue error
        test.equal result.statusCode, 500

    it 'should cause an error when it returns undefined', (test, waitFor) ->
      Restivus.addRoute 'undefined-response',
        get: ->
          undefined

      HTTP.get Meteor.absoluteUrl('api/v1/undefined-response'), waitFor (error, result) ->
        test.isTrue error
        test.equal result.statusCode, 500

    it 'should be able to handle it\'s response manually', (test, waitFor) ->
      Restivus.addRoute 'manual-response',
        get: ->
          @response.write 'Testing manual response.'
          @response.end()
          @done()

      HTTP.get Meteor.absoluteUrl('api/v1/manual-response'), waitFor (error, result) ->
        response = result.content

        test.equal result.statusCode, 200
        test.equal response, 'Testing manual response.'

    it 'should not have to call this.response.end() when handling the response manually', (test, waitFor) ->
      Restivus.addRoute 'manual-response-no-end',
        get: ->
          @response.write 'Testing this.end()'
          @done()

      HTTP.get Meteor.absoluteUrl('api/v1/manual-response-no-end'), waitFor (error, result) ->
        response = result.content

        test.isFalse error
        test.equal result.statusCode, 200
        test.equal response, 'Testing this.end()'

    it 'should be able to send it\'s response in chunks', (test, waitFor) ->
      Restivus.addRoute 'chunked-response',
        get: ->
          @response.write 'Testing '
          @response.write 'chunked response.'
          @done()

      HTTP.get Meteor.absoluteUrl('api/v1/chunked-response'), waitFor (error, result) ->
        response = result.content

        test.equal result.statusCode, 200
        test.equal response, 'Testing chunked response.'

#    it 'should respond with an error if this.done() isn\'t called after response is handled manually', (test, waitFor) ->
#      Restivus.addRoute 'manual-response-without-done',
#        get: ->
#          @response.write 'Testing'
#
#      HTTP.get Meteor.absoluteUrl('api/v1/manual-response-without-done'), waitFor (error, result) ->
#        test.isTrue error
#        test.equal result.statusCode, 500

    it 'should not wrap text with quotes when response Content-Type is text/plain', (test, waitFor) ->
      Restivus.addRoute 'plain-text-response',
        get: ->
          headers:
            'Content-Type': 'text/plain'
          body: 'foo"bar'

      HTTP.get Meteor.absoluteUrl('api/v1/plain-text-response'), waitFor (error, result) ->
        response = result.content
        test.equal result.statusCode, 200
        test.equal response, 'foo"bar'

    it 'should have its context set', (test) ->
      Restivus.addRoute 'context/:test',
        post: ->
          test.equal @urlParams.test, '100'
          test.equal @queryParams.test, "query"
          test.equal @bodyParams.test, "body"
          test.isNotNull @request
          test.isNotNull @response
          test.isTrue _.isFunction @done
          test.isFalse @authRequired
          test.isFalse @roleRequired
          true

      result = HTTP.post Meteor.absoluteUrl('api/v1/context/100?test=query'),
        data:
          test: 'body'

      test.equal result.statusCode, 200
      test.isTrue result.content
