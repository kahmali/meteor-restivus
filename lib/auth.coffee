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
getQuerySelectorFor = (user) ->
  if user.id
    return {'_id': user.id}
  else if user.username
    return {'username': user.username}
  else if user.email
    return {'email.address': user.email}

  # We shouldn't be here if the user object was properly validated
  throw new Error 'Cannot create selector from invalid user'


###
  Log a user in with their password
###
loginWithPassword = (userId, password) ->
  if not userId or not password
    return undefined # TODO: Should we throw a more descriptive error here, or is that insecure?

  # Validate the login input types
  check userId, userValidator
  check password, String

  # Retrieve the user from the database
  authUserSelector = getQuerySelectorFor(userId)
  user = Meteor.users.findOne(authUserSelector)
  if not user
    throw new Meteor.Error 403, 'User not found'

  if not user.services?.password
    throw new Meteor.Error 403, 'User has no password set'

  # Verify the user's password
  passwordVerification = Accounts._checkPassword user, password
  if passwordVerification.error
    throw new Meteor.Error 403, 'Incorrect password'

  # Add a new auth token to the user's account
  authToken = Accounts._generateStampedLoginToken()
  Meteor.users.update user._id, {$push: {'services.resume.loginTokens': authToken}}

  return {loginToken: authToken, userId: user._id}

@Restfully.prototype.initAuth = ->
  # TODO: Add login and logout endpoints
