@Route = (@api, @path, @options, @endpoints) ->
  # Check if options were provided
  if not @endpoints
    @endpoints = @options
    @options = null

@Route.prototype.addToApi =  ->
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
###
callEndpoint = (route, endpoint) ->
  endpoint = resolveEndpoint endpoint
  authenticateIfRequired.call this, route, endpoint
  endpoint.action.call this

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
###
authenticateIfRequired = (route, endpoint) ->
  # Authenticate the request if necessary
  if route.api.config.useAuth
    if endpoint.authRequired is undefined
      authenticate.call(this, route) if route.options?.authRequired
    else if endpoint.authRequired
      authenticate.call this, route


###
  Verify the request is being made by an actively logged in user

  @context: IronRouter.Router.route()
###
authenticate = (route) ->
  # Get the auth info from header
  userId = @request.headers['x-user-id']
  authToken = @request.headers['x-auth-token']

  # Get the user from the database
  if userId and authToken
    user = Meteor.users.findOne {'_id': userId, 'services.resume.loginTokens.token': authToken}

  # Return an error if the login token does not match any belonging to the user
  if not user
    respond.call this, route, {success: false, message: "You must be logged in to do this."}, 401

  @user = user


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

  console.log bodyAsJson

  # Send response
  @response.writeHead statusCode, headers
  @response.write bodyAsJson
  @response.end()