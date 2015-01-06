@Restivus = ->
  @routes = []
  @config =
    paths: []
    useAuth: false
    apiPath: 'api/'
    version: 1
    prettyJson: true
    onLoggedIn: -> {}
    onLoggedOut: -> {}
  @configured = false

###
  Add endpoints for the given HTTP methods at the given path
###
@Restivus.prototype.add = (path, options, methods) ->
  # Create a new route and add it to our list of existing routes
  route = new Route(this, path, options, methods)
  @routes.push(route)

  # Don't add the route to the API until the API has been configured
  route.addToApi() if @configured


###
  Configure the ReST API

  Must be called exactly once, from anywhere on the server.
###
@Restivus.prototype.configure = (config) ->
  if @configured
    throw new Error 'Restivus.configure() can only be called once'

  @configured = true

  # Normalize the API path
  if config.apiPath[0] is '/'
    config.apiPath = config.apiPath.slice 1
  if config.apiPath[-1] isnt '/'
    config.apiPath = config.apiPath + '/'

  # Configure API with the given options
  _.extend @config, config

  # Add any existing routes to the API now that it's configured
  _.each @routes, (route) -> route.addToApi()

  # Add default login and logout endpoints if auth is configured
  if @config.useAuth
    initAuth()
    console.log "Restivus configured at #{@config.apiPath} with authentication"
  else
    console.log "Restivus configured at #{@config.apiPath} without authentication"



###
  Add /login and /logout endpoints to the API
###
initAuth = ->
  ###
  Add a login endpoint to the API

  After the user is logged in, the onLoggedIn hook is called (see Restfully.configure() for adding hook).
  ###
  Restivus.add 'login', {authRequired: false},
    post: ->
      # Grab the username or email that the user is logging in with
      user = {}
      if @bodyParams.user.indexOf('@') is -1
        user.username = @bodyParams.user
      else
        user.email = @bodyParams.user

      # Try to log the user into the user's account (if successful we'll get an auth token back)
      try
        auth = Auth.loginWithPassword user, @bodyParams.password
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
  Add a logout endpoint to the API

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