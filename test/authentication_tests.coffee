DefaultAuthApi = new Restivus
  apiPath: 'default-auth'
  useDefaultAuth: true
  auth:
    token: 'services.resume.loginTokens.hashedToken'
    user: ->
      userId: @request.headers['x-user-id']
      token: Accounts._hashLoginToken @request.headers['x-auth-token']

NoDefaultAuthApi = new Restivus
  apiPath: 'no-default-auth'
  useDefaultAuth: false

LegacyDefaultAuthApi = new Restivus
  apiPath: 'legacy-default-auth'
  useAuth: true

LegacyNoDefaultAuthApi = new Restivus
  apiPath: 'legacy-no-default-auth'
  useAuth: false

describe 'Authentication', ->

  it 'can be required even when the default endpoints aren\'t configured', (test, waitFor) ->
    NoDefaultAuthApi.addRoute 'require-auth', { authRequired: true },
      get: ->
        data: 'test'
    startTime = new Date()
    HTTP.get Meteor.absoluteUrl('no-default-auth/require-auth'), waitFor (error, result) ->
      response = result.data
      test.isTrue error
      test.equal result.statusCode, 401
      test.equal response.status, 'error'
      durationInMilliseconds = new Date() - startTime
      # Check for security delay for failed auth
      test.isTrue durationInMilliseconds >= 500

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

  it 'should only be available when configured', (test, waitFor) ->
    HTTP.post Meteor.absoluteUrl('default-auth/login'), {
      data:
        user: username
        password: password
    }, waitFor (error, result) ->
      response = result.data
      test.equal result.statusCode, 200
      test.equal response.status, 'success'
      test.equal response.data.userId, userId
      test.isTrue response.data.authToken

    HTTP.post Meteor.absoluteUrl('no-default-auth/login'), {
      data:
        user: username
        password: password
    }, waitFor (error, result) ->
      response = result.data
      test.isUndefined response?.data?.userId
      test.isUndefined response?.data?.authToken

    HTTP.post Meteor.absoluteUrl('legacy-default-auth/login'), {
      data:
        user: username
        password: password
    }, waitFor (error, result) ->
      response = result.data
      test.equal result.statusCode, 200
      test.equal response.status, 'success'
      test.equal response.data.userId, userId
      test.isTrue response.data.authToken

    HTTP.post Meteor.absoluteUrl('legacy-no-default-auth/login'), {
      data:
        user: username
        password: password
    }, waitFor (error, result) ->
      response = result.data
      test.isUndefined response?.data?.userId
      test.isUndefined response?.data?.authToken



  it 'should allow a user to login', (test, waitFor) ->
    HTTP.post Meteor.absoluteUrl('default-auth/login'), {
      data:
        user: username
        password: password
    }, waitFor (error, result) ->
      response = result.data
      test.equal result.statusCode, 200
      test.equal response.status, 'success'
      test.equal response.data.userId, userId
      test.isTrue response.data.authToken

      # Store the token for later use
      token = response.data.authToken


  it 'should allow a user to login again, without affecting the first login', (test, waitFor) ->
    HTTP.post Meteor.absoluteUrl('default-auth/login'), {
      data:
        user: email
        password: password
    }, waitFor (error, result) ->
      response = result.data
      test.equal result.statusCode, 200
      test.equal response.status, 'success'
      test.equal response.data.userId, userId
      test.isTrue response.data.authToken
      test.notEqual token, response.data.authToken

      # Store the token for later use
      emailLoginToken = response.data.authToken


  it 'should not allow a user with wrong password to login and should respond after 500 msec', (test, waitFor) ->
    # This test should take 500 msec or more. To speed up testing, these two tests have been combined.
    startTime = new Date()
    HTTP.post Meteor.absoluteUrl('default-auth/login'), {
      data:
        user: username
        password: "NotAllowed"
    }, waitFor (error, result) ->
      response = result.data
      test.equal result.statusCode, 401
      test.equal response.status, 'error'
      durationInMilliseconds = new Date() - startTime
      test.isTrue durationInMilliseconds >= 500


  it 'should allow a user to logout', (test, waitFor) ->
    HTTP.post Meteor.absoluteUrl('default-auth/logout'), {
      headers:
        'X-User-Id': userId
        'X-Auth-Token': token
    }, waitFor (error, result) ->
      response = result.data
      test.equal result.statusCode, 200
      test.equal response.status, 'success'

  it 'should remove the logout token after logging out and should respond after 500 msec', (test, waitFor) ->
    DefaultAuthApi.addRoute 'prevent-access-after-logout', {authRequired: true},
      get: -> true
    # This test should take 500 msec or more. To speed up testing, these two tests have been combined.
    startTime = new Date()
    HTTP.get Meteor.absoluteUrl('default-auth/prevent-access-after-logout'), {
      headers:
        'X-User-Id': userId
        'X-Auth-Token': token
    }, waitFor (error, result) ->
      response = result.data
      test.isTrue error
      test.equal result.statusCode, 401
      test.equal response.status, 'error'
      durationInMilliseconds = new Date() - startTime
      test.isTrue durationInMilliseconds >= 500

  it 'should allow a second logged in user to logout', (test, waitFor) ->
    HTTP.post Meteor.absoluteUrl('default-auth/logout'), {
      headers:
        'X-User-Id': userId
        'X-Auth-Token': emailLoginToken
    }, waitFor (error, result) ->
      response = result.data
      test.equal result.statusCode, 200
      test.equal response.status, 'success'
