###
  A valid user will have exactly one of the following identification fields: id, username, or email
###
userValidator = Match.Where (user) ->
  check user,
    id: Match.Optional String
    username: Match.Optional String
    email: Match.Optional String

  if _.keys(user).length is not 1
    throw new Match.Error 'User must have exactly one identifier field'

  return true


###
  Return a MongoDB query selector for finding the given user
  TODO: Allow the user to configure a user field that they define as valid, and check that instead of this arbitrary 'username'
###
getUserQuerySelector = (user) ->
  if user.id
    return {'_id': user.id}
  else if user.username
    return {'username': user.username}
  else if user.email
    return {'emails.address': user.email}

  # We shouldn't be here if the user object was properly validated
  throw new Error 'Cannot create selector from invalid user'


###
  Log a user in with their password
###
loginWithPassword = (user, password) ->
  if not user or not password
    return undefined # TODO: Should we throw a more descriptive error here, or is that insecure?

  # Validate the login input types
  check user, userValidator
  check password, String

  # Retrieve the user from the database
  authenticatingUserSelector = getUserQuerySelector(user)
  authenticatingUser = Meteor.users.findOne(authenticatingUserSelector)

  if not authenticatingUser
    throw new Meteor.Error 403, 'User not found'
  if not authenticatingUser.services?.password
    throw new Meteor.Error 403, 'User has no password set'

  # Authenticate the user's password
  passwordVerification = Accounts._checkPassword authenticatingUser, password
  if passwordVerification.error
    throw new Meteor.Error 403, 'Incorrect password'

  # Add a new auth token to the user's account
  authToken = Accounts._generateStampedLoginToken()
  Meteor.users.update authenticatingUser._id, {$push: {'services.resume.loginTokens': authToken}}

  return {loginToken: authToken.token, userId: authenticatingUser._id}

@Restivus.prototype.initAuth = ->
  ###
  Add a login method to the API

  After the user is logged in, the onLoggedIn hook is called (see Restfully.configure() for adding hook).
  ###
  Restivus.add 'login', {authRequired: false},
    post: ->
      # Grab the username or email that the user is logging in with
      user = {}
      if this.params.user.indexOf('@') is -1
        user.username = this.params.user
      else
        user.email = this.params.user

      # Try to log the user into their account (if successful we'll get an auth token back)
      try
        auth = loginWithPassword user, this.params.password
      catch e
        return [e.error, {success: false, message: e.reason}]

      # Get the authenticated user
      # TODO: Consider returning the user in loginWithPassword(), instead of fetching it again here
      context = {}
      if auth.userId and auth.loginToken
        context.user = Meteor.users.findOne
          '_id': auth.userId
          'services.resume.loginTokens.token': auth.loginToken

      # Call the login hook with the authenticated user attached
      Restivus.config.onLoggedIn.call context

      auth.success = true
      auth

  ###
  Add a logout method to the API

  After the user is logged out, the onLoggedOut hook is called (see Restfully.configure() for adding hook).
  ###
  Restivus.add 'logout', {authRequired: true},
    get: ->
      # Remove the given auth token from the user's account
      authToken = this.request.headers['x-login-token']
      Meteor.users.update this.user._id, {$pull: {'services.resume.loginTokens': {token: authToken}}}

      # Call the logout hook with the logged out user attached
      Restivus.config.onLoggedOut.call this.user

      {success: true, message: 'You\'ve been logged out!'}
