@Restfully = ->
  this.config =
    paths: []
    useAuth: false
    apiPath: '/api'
    version: 1
    prettyJson: true
    onLoggedIn: -> {}
    onLoggedOut: -> {}
  this.configured = false

###
  Add endpoints for the given HTTP methods at the given path
###
@Restfully.prototype.add = (path, options, methods) ->
  self = this

  path = this.config.apiPath + path

  console.log "Adding #{_.keys(methods)} methods to path: #{path}"

  # Throw an error if this path has already been added
  # TODO: Check for collisions with paths that follow same pattern with different parameter names
  if _.contains this.paths, path
    throw new Error "Cannot Restfully.add() route at an existing path: #{path}"

  # Add all given methods using Iron Router
  Router.route path,
    where: 'server'
    action: ->
      # Authenticate the request if necessary
      if self.config.useAuth and options.authRequired
        authenticate.call this

      # Respond to the requested HTTP method if an endpoint has been provided for it
      method = this.request.method
      console.log "HTTP request method: #{method}"
      if method is 'GET' and methods.get
        responseBody = methods.get.call(this)
      else if method is 'POST' and methods.post
        _.extend this.params, this.request.body
        responseBody = methods.post.call(this)
      else if method is 'PUT' and methods.put
        _.extend this.params, this.request.body
        responseBody = methods.put.call(this)
      else if method is 'PATCH' and methods.patch
        _.extend this.params, this.request.body
        responseBody = methods.patch.call(this)
      else if method is 'DELETE' and methods.delete
        responseBody = methods.delete.call(this)
      else
        return [404, {success: false, message:'ReST API method not found'}]

      # Generate and return the http response
      this.response.writeHead 200,
        'Content-Type': 'text/json'
      this.response.write JSON.stringify responseBody
      this.response.end()

  # Add the path to our list of existing paths
  this.config.paths.push path

  return


###
  Configure the ReST API

  Can only be called once.
###
@Restfully.prototype.configure = (config) ->
  if this.configured
    throw new Error 'Restfully.configure() can only be called once'

  this.configured = true

  # Copy the config properties to our global api configuration
  _.extend this.config, config

  if this.config.apiPath[-1] != '/'
    this.config.apiPath = this.config.apiPath + '/'

  # Add default login and logout endpoints if auth is configured
  if this.config.useAuth
    Restfully.initAuth()


###
  Verify the request is being made by an actively logged in user
###
authenticate = ->
  # Get the auth info from header
  userId = this.request.headers['x-user-id']
  loginToken = this.request.headers['x-login-token']

  # Get the user from the database
  if userId and loginToken
    user = Meteor.users.findOne {'_id': userId, 'services.resume.loginTokens.token': loginToken}

  # Return an error if the login token does not match any belonging to the user
  if not user
    # TODO: Execute the http error response here
    return [403, {success: false, message: "You must be logged in to do this."}]

  this.user = user

Restfully = new @Restfully()