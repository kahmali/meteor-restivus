@Route = (@api, @path, @options, @endpoints) ->
  # Check if options were provided
  if not @endpoints
    @endpoints = @options
    @options = null

@Route.prototype.addToApi = ->
  self = this

  # Throw an error if a route has already been added at this path
  # TODO: Check for collisions with paths that follow same pattern with different parameter names
  if _.contains @api.config.paths, @path
    throw new Error "Cannot add a route at an existing path: #{@path}"

  # Append the path to the base API path
  fullPath = @api.config.apiPath + @path

  # Setup endpoints on route using Iron Router
  Router.route fullPath,
    where: 'server'
    action: ->
      # Flatten parameters in the URL and request body (and give them better names)
      # TODO: Decide whether or not to nullify the copied objects. Makes sense to do it, right?
      @urlParams = @params
      @queryParams = @params.query
      @bodyParams = @request.body

      # Respond to the requested HTTP method if an endpoint has been provided for it
      method = @request.method
      if method is 'GET' and self.endpoints.get
        responseData = callEndpoint.call(this, self, self.endpoints.get)
      else if method is 'POST' and self.endpoints.post
        responseData = callEndpoint.call(this, self, self.endpoints.post)
      else if method is 'PUT' and self.endpoints.put
        responseData = callEndpoint.call(this, self, self.endpoints.put)
      else if method is 'PATCH' and self.endpoints.patch
        responseData = callEndpoint.call(this, self, self.endpoints.patch)
      else if method is 'DELETE' and self.endpoints.delete
        responseData = callEndpoint.call(this, self, self.endpoints.delete)
      else
        responseData = {statusCode: 404, body: {success: false, message:'API endpoint not found'}}

      # Generate and return the http response, handling the different endpoint response types
      if responseData.body and (responseData.statusCode or responseData.headers)
        responseData.statusCode or= 200
        responseData.headers or= {'Content-Type': 'text/json'}
        respond.call this, self, responseData.body, responseData.statusCode, responseData.headers
      else
        respond.call this, self, responseData

  # Add the path to our list of existing paths
  @api.config.paths.push @path


###
  Authenticate an endpoint if required, and return the result of calling it

  @context: IronRouter.Router.route()
  @returns The endpoint response or a 401 if authentication fails
###
callEndpoint = (route, endpoint) ->
  endpoint = resolveEndpoint endpoint

  # Call the endpoint if authentication doesn't fail
  if authAccepted.call this, route, endpoint
    endpoint.action.call this
  else
    statusCode: 401
    body: {success: false, message: "You must be logged in to do this."}


###
  Convert the given endpoint into our expected endpoint object if it is a bare function
###
resolveEndpoint = (endpoint) ->
  if _.isFunction(endpoint)
    endpoint = {action: endpoint}
  endpoint

###
  Authenticate the given endpoint if required

  Once it's globally configured in the API, authentication can be required on an entire route or individual
  endpoints. If required on an entire endpoint, that serves as the default. If required in any individual endpoints, that
  will override the default.

  @context: IronRouter.Router.route()
  @returns False if authentication fails, and true otherwise
###
authAccepted = (route, endpoint) ->
  accept = true
  if route.api.config.useAuth
    if endpoint.authRequired is undefined
      accept = authenticate.call(this, route) if route.options?.authRequired
    else if endpoint.authRequired
      accept = authenticate.call this, route
  accept


###
  Verify the request is being made by an actively logged in user

  If verified, attach the authenticated user to the context.

  @context: IronRouter.Router.route()
  @returns {Boolean} True if the authentication was successful
###
authenticate = ->
  # Get the auth info from header
  userId = @request.headers['x-user-id']
  authToken = @request.headers['x-auth-token']

  # Get the user from the database
  if userId and authToken
    user = Meteor.users.findOne {'_id': userId, 'services.resume.loginTokens.token': authToken}

  # Attach the user and their ID to the context if the authentication was successful
  if user
    @user = user
    @userId = user._id
    true
  else false


###
  Respond to an HTTP request

  @context: IronRouter.Router.route()
###
respond = (route, body, statusCode=200, headers) ->
  # Allow cross-domain requests to be made from the browser
  @response.setHeader 'Access-Control-Allow-Origin', '*'

  # Ensure that a content type is set (will be overridden if also included in given headers)
  # TODO: Consider enforcing a text/json-only content type (override any user-defined content-type)
  @response.setHeader 'Content-Type', 'text/json'

  # Prettify JSON if configured in API
  if route.api.config.prettyJson
    bodyAsJson = JSON.stringify body, undefined, 2
  else
    bodyAsJson = JSON.stringify body

  # Send response
  @response.writeHead statusCode, headers
  @response.write bodyAsJson
  @response.end()