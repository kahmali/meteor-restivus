@Auth or= {}

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
  A password can be either in plain text or hashed
###
passwordValidator = Match.OneOf(String,
  digest: String
  algorithm: String)

###
  Return a MongoDB query selector for finding the given user
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

@Auth.customAttemptLogin = (methodInvocation, methodName, methodArgs, result) ->
  if !result
    throw new Error('result is required')
  # XXX A programming error in a login handler can lead to this occuring, and
  # then we don't call onLogin or onLoginFailure callbacks. Should
  # tryLoginMethod catch this case and turn it into an error?
  if !result.userId and !result.error
    throw new Error('A login method must specify a userId or an error')
  user = undefined
  if result.userId
    user = Meteor.users.findOne(result.userId)
  attempt =
    type: result.type or 'unknown'
    allowed: ! !(result.userId and !result.error)
    methodName: methodName
    methodArguments: _.toArray(methodArgs)
  if result.error
    attempt.error = result.error
  if user
    attempt.user = user
  # _validateLogin may mutate `attempt` by adding an error and changing allowed
  # to false, but that's the only change it can make (and the user's callbacks
  # only get a clone of `attempt`).
  Accounts._validateLogin methodInvocation.connection, attempt
  if attempt.allowed
    ret = result.options or {}
    ret.type = attempt.type
    Accounts._successfulLogin methodInvocation.connection, attempt
    return ret
  else
    Accounts._failedLogin methodInvocation.connection, attempt
    throw attempt.error
  return

###
  Log a user in with their password
###
@Auth.loginWithPassword = (user, password) ->
  if not user or not password
    throw new Meteor.Error 401, 'Unauthorized'

  # Validate the login input types
  check user, userValidator
  check password, passwordValidator

  # Retrieve the user from the database
  authenticatingUserSelector = getUserQuerySelector(user)
  authenticatingUser = Meteor.users.findOne(authenticatingUserSelector)

  if not authenticatingUser
    throw new Meteor.Error 401, 'Unauthorized'
  if not authenticatingUser.services?.password
    throw new Meteor.Error 401, 'Unauthorized'

  # Authenticate the user's password
  passwordVerification = Accounts._checkPassword authenticatingUser, password
  passwordVerification.type = 'password';
  preparedPassword = if _.isString(password) then {digest: SHA256(password), algorithm: 'sha-256'} else password

  Auth.customAttemptLogin {connection: null}, 'login', [ {user: user, password: preparedPassword} ], passwordVerification

  # Add a new auth token to the user's account
  authToken = Accounts._generateStampedLoginToken()
  hashedToken = Accounts._hashLoginToken authToken.token
  Accounts._insertHashedLoginToken authenticatingUser._id, {hashedToken}

  return {authToken: authToken.token, userId: authenticatingUser._id}
