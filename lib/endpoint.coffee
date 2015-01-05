@Endpoint = (@api, @path, @options, @methods) ->
  # Check if options were provided
  if not @methods
    @methods = @options
    @options = null

@Endpoint.prototype.addToApi =  ->
  self = this

  # Throw an error if this endpoint has already been added
  # TODO: Check for collisions with paths that follow same pattern with different parameter names
  if _.contains @api.config.paths, @path
    throw new Error "Cannot add endpoint at an existing path: #{@path}"

  # Append the path to the base API path
  fullPath = @api.config.apiPath + @path

#  console.log "Adding [#{ _.keys @methods }] methods to path: #{fullPath}"

  # Add all given methods using Iron Router
  Router.route fullPath,
    where: 'server'
    action: ->
      method = @request.method
#      console.log "Handling #{method} request at #{self.path}"

      # Flatten parameters in the URL and request body (and give them better names)
      # TODO: Decide whether or not to nullify the copied objects. Makes sense to do it, right?
      @urlParams = @params
      @queryParams = @params.query
      @bodyParams = @request.body
#      @params = @params.query = @request.body = null

      # Respond to the requested HTTP method if an endpoint has been provided for it
      if method is 'GET' and self.methods.get
        responseData = callEndpoint.call(this, self, self.methods.get)
      else if method is 'POST' and self.methods.post
        responseData = callEndpoint.call(this, self, self.methods.post)
      else if method is 'PUT' and self.methods.put
        responseData = callEndpoint.call(this, self, self.methods.put)
      else if method is 'PATCH' and self.methods.patch
        responseData = callEndpoint.call(this, self, self.methods.patch)
      else if method is 'DELETE' and self.methods.delete
        responseData = callEndpoint.call(this, self, self.methods.delete)
      else
        responseData = {statusCode: 404, body: {success: false, message:'API method not found'}}

      # Generate and return the http response, handling the different method response types
      if responseData.body and (responseData.statusCode or responseData.headers)
        responseData.statusCode or= 200
        responseData.headers or= {'Content-Type': 'text/json'}
        respond.call this, responseData.body, responseData.statusCode, responseData.headers
      else
        respond.call this, responseData

  # Add the path to our list of existing paths
  @api.config.paths.push @path


###
  Authenticate an endpoint if required, and return the result of calling it

  @context: IronRouter.Router.route()
###
callEndpoint = (endpoint, method) ->
  method = resolveMethod method
  authenticateIfRequired.call this, endpoint, method
  method.action.call this

###
  Convert the given endpoint method into our expected object if it is a bare function
###
resolveMethod = (method) ->
  if _.isFunction(method)
    method = {action: method}
  method

###
  Authenticate the given method if required

  Once it's globally configured in the API, authentication can be required on an entire endpoint or individual
  methods. If required on an entire endpoint, that serves as the default. If required in any individual methods, that
  will override the default.

  @context: IronRouter.Router.route()
###
authenticateIfRequired = (endpoint, method) ->
  # Authenticate the request if necessary
  if endpoint.api.config.useAuth
    if method.authRequired is undefined
      authenticate.call(this) if endpoint.options?.authRequired
    else if method.authRequired
      authenticate.call this


###
  Verify the request is being made by an actively logged in user

  @context: IronRouter.Router.route()
###
authenticate = ->
  # Get the auth info from header
  userId = @request.headers['x-user-id']
  loginToken = @request.headers['x-auth-token']

  # Get the user from the database
  if userId and loginToken
    user = Meteor.users.findOne {'_id': userId, 'services.resume.loginTokens.token': loginToken}

  # Return an error if the login token does not match any belonging to the user
  if not user
    respond.call this, {success: false, message: "You must be logged in to do this."}, 401

  @user = user


###
  Respond to an HTTP request

  @context: IronRouter.Router.route()
###
respond = (body, statusCode=200, headers={'Content-Type':'text/json'}) ->
  @response.writeHead statusCode, headers
  @response.write JSON.stringify body
  @response.end()