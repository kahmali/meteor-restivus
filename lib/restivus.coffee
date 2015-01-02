@Restivus = ->
  @endpoints = []
  @config =
    paths: []
    useAuth: false
    apiPath: '/api'
    version: 1
    prettyJson: true
    onLoggedIn: -> {}
    onLoggedOut: -> {}
  @configured = false

###
  Add endpoints for the given HTTP methods at the given path
###
@Restivus.prototype.add = (path, options, methods) ->
  # Create a new endpoint and add it to our list of existing endpoints
  endpoint = new Endpoint(this, path, options, methods)
  @endpoints.push(endpoint)

  # Don't add the endpoint to the API until the API has been configured
  endpoint.addToApi() if @configured


###
  Configure the ReST API

  Can only be called once.
###
@Restivus.prototype.configure = (config) ->
  if @configured
    throw new Error 'Restivus.configure() can only be called once'

  @configured = true

  if config.apiPath[-1] != '/'
    config.apiPath = config.apiPath + '/'

  # Configure API with the given options
  _.extend @config, config

  # Add any existing endpoints to the API now that it's configured
  _.each @endpoints, (endpoint) -> endpoint.addToApi()

  # Add default login and logout endpoints if auth is configured
  if @config.useAuth
    initAuth()


###
  Add /login and /logout endpoints to the API
###
initAuth = ->
  ###
  Add a login method to the API

  After the user is logged in, the onLoggedIn hook is called (see Restfully.configure() for adding hook).
  ###
  Restivus.add 'login', {authRequired: false},
    post: ->
      # Grab the username or email that the user is logging in with
      user = {}
      if @params.user.indexOf('@') is -1
        user.username = @params.user
      else
        user.email = @params.user

      # Try to log the user into the user's account (if successful we'll get an auth token back)
      try
        auth = Auth.loginWithPassword user, @params.password
      catch e
        return [e.error, {success: false, message: e.reason}]

      # Get the authenticated user
      # TODO: Consider returning the user in Auth.loginWithPassword(), instead of fetching it again here
      context = {}
      if auth.userId and auth.authToken
        context.user = Meteor.users.findOne
          '_id': auth.userId
          'services.resume.loginTokens.token': auth.authToken

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
      authToken = @request.headers['x-auth-token']
      Meteor.users.update @user._id, {$pull: {'services.resume.loginTokens': {token: authToken}}}

      # Call the logout hook with the logged out user attached
      Restivus.config.onLoggedOut.call @user

      {success: true, message: 'You\'ve been logged out!'}

Restivus = new @Restivus()