Meteor.startup ->
  describe 'The default authentication endpoints', ->
    token = null
    emailLoginToken = null
    username = 'test'
    email = 'test@ivus.com'
    password = 'password'

    # Delete the test account if it's still present
    Meteor.users.remove username: username

    userId = Accounts.createUser {
      username: username
      email
      password: password
    }

    it 'should allow a user to login', (test, next) ->
      HTTP.post Meteor.absoluteUrl('/api/v1/login'), {
        data: 
          user: username
          password: password
      }, (error, result) ->
        response = JSON.parse result.content
        test.equal result.statusCode, 200
        test.equal response.status, 'success'
        test.equal response.data.userId, userId
        test.isTrue response.data.authToken

        # Store the token for later use
        token = response.data.authToken

        next()

    it 'should allow a user to login again, without affecting the first login', (test, next) ->
      HTTP.post Meteor.absoluteUrl('/api/v1/login'), {
        data: 
          user: email
          password: password
      }, (error, result) ->
        response = JSON.parse result.content
        test.equal result.statusCode, 200
        test.equal response.status, 'success'
        test.equal response.data.userId, userId
        test.isTrue response.data.authToken
        test.notEqual token, response.data.authToken
        
        # Store the token for later use
        emailLoginToken = response.data.authToken

        next()

    it 'should not allow a user with wrong password to login', (test, next) ->
      HTTP.post Meteor.absoluteUrl('/api/v1/login'), {
        data:
          user: username
          password: "NotAllowed"
      }, (error, result) ->
        response = JSON.parse result.content
        test.equal result.statusCode, 403
        test.equal response.status, 'error'

        next()

    it 'should allow a user to logout', (test, next) ->
      HTTP.get Meteor.absoluteUrl('/api/v1/logout'), {
        headers:
          'X-User-Id': userId
          'X-Auth-Token': token
      }, (error, result) ->
        response = JSON.parse result.content
        test.equal result.statusCode, 200
        test.equal response.status, 'success'
        next()

    it 'should remove the logout token after logging out', (test, next) ->
      Restivus.addRoute 'prevent-access-after-logout', {authRequired: true},
        get: -> true

      HTTP.get Meteor.absoluteUrl('/api/v1/prevent-access-after-logout'), {
        headers:
          'X-User-Id': userId
          'X-Auth-Token': token
      }, (error, result) ->
        response = JSON.parse result.content
        test.isTrue error
        test.equal result.statusCode, 401
        test.equal response.status, 'error'
        next()

    it 'should allow a second logged in user to logout', (test, next) ->
      HTTP.get Meteor.absoluteUrl('/api/v1/logout'), {
        headers:
          'X-User-Id': userId
          'X-Auth-Token': emailLoginToken
      }, (error, result) ->
        response = JSON.parse result.content
        test.equal result.statusCode, 200
        test.equal response.status, 'success'
        next()
