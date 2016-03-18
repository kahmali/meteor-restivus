HookApi = new Restivus
  useDefaultAuth: true
  apiPath: 'hook-api'
  onLoggedIn: -> Meteor.users.findOne({_id: @userId})
  onLoggedOut: -> Meteor.users.findOne({_id: @userId})

DefaultApi = new Restivus
  useDefaultAuth: true
  apiPath: 'no-hook-api'

describe 'User login and logout', ->
  token = null
  username = 'test2'
  email = 'test2@ivus.com'
  password = 'password'

  # Delete the test account if it's still present
  Meteor.users.remove username: username

  userId = Accounts.createUser {
    username: username
    email: email
    password: password
  }

  describe 'with hook returns', ->
    it 'should call the onLoggedIn hook and attach returned data to the response as data.extra', (test, waitFor) ->
      HTTP.post Meteor.absoluteUrl('hook-api/login'), {
        data:
          username: username
          password: password
      }, waitFor (error, result) ->
        response = result.data
        test.equal result.statusCode, 200
        test.equal response.status, 'success'
        test.equal response.data.userId, userId
        test.equal response.data.extra.username, username

        # Store the token for later use
        token = response.data.authToken

    it 'should call the onLoggedOut hook and attach returned data to the response as data.extra', (test, waitFor) ->
      HTTP.post Meteor.absoluteUrl('hook-api/logout'), {
        headers:
          'X-User-Id': userId
          'X-Auth-Token': token
      }, waitFor (error, result) ->
        response = result.data
        test.equal result.statusCode, 200
        test.equal response.status, 'success'
        test.equal response.data.extra.username, username

  describe 'without hook returns', ->
    it 'should not attach data.extra to the response when login is called', (test, waitFor) ->
      HTTP.post Meteor.absoluteUrl('no-hook-api/login'), {
        data:
          username: username
          password: password
      }, waitFor (error, result) ->
        response = result.data
        test.equal result.statusCode, 200
        test.equal response.status, 'success'
        test.equal response.data.userId, userId
        test.isUndefined response.data.extra

        # Store the token for later use
        token = response.data.authToken

    it 'should not attach data.extra to the response when logout is called', (test, waitFor) ->
      HTTP.post Meteor.absoluteUrl('no-hook-api/logout'), {
        headers:
          'X-User-Id': userId
          'X-Auth-Token': token
      }, waitFor (error, result) ->
        response = result.data
        test.equal result.statusCode, 200
        test.equal response.status, 'success'
        test.isUndefined response.data.extra