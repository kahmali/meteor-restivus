if Meteor.isServer

  describe 'A route', ->

    it 'can be constructed with options', (test) ->
      route = new @Route new @Restivus, 'test-route-1', {authRequired: true, roleRequired: ['admin', 'dev']},
        get: -> 'GET test-route-1'

      test.equal route.path, 'test-route-1'
      test.isTrue route.options.authRequired
      test.isTrue _.contains(route.options.roleRequired, 'admin')
      test.isTrue _.contains(route.options.roleRequired, 'dev')
      test.equal route.endpoints.get(), 'GET test-route-1'

    it 'can be constructed without options', (test) ->
      route = new @Route new @Restivus, 'test-route-2',
        get: -> 'GET test-route-2'

      test.equal route.path, 'test-route-2'
      test.equal route.endpoints.get(), 'GET test-route-2'

    it 'should support endpoints for all HTTP methods', (test) ->
      route = new @Route new @Restivus, 'test-route-3',
        get: -> 'GET test-route-2'
        post: -> 'POST test-route-2'
        put: -> 'PUT test-route-2'
        patch: -> 'PATCH test-route-2'
        delete: -> 'DELETE test-route-2'
        options: -> 'OPTIONS test-route-2'

      test.equal route.endpoints.get(), 'GET test-route-2'
      test.equal route.endpoints.post(), 'POST test-route-2'
      test.equal route.endpoints.put(), 'PUT test-route-2'
      test.equal route.endpoints.patch(), 'PATCH test-route-2'
      test.equal route.endpoints.delete(), 'DELETE test-route-2'
      test.equal route.endpoints.options(), 'OPTIONS test-route-2'


    context 'that\'s initialized without options', ->
     it 'should have the default configuration', (test) ->
       test.equal Restivus.config.apiPath, 'api/'
       test.isFalse Restivus.config.useAuth
       test.isFalse Restivus.config.prettyJson
       test.equal Restivus.config.auth.token, 'services.resume.loginTokens.token'