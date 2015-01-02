@Endpoint = (@api, @path, @options, @methods) ->
  # TODO: Make the options...well...optional

@Endpoint.prototype.addToApi =  ->
  self = this

  # Throw an error if this endpoint has already been added
  # TODO: Check for collisions with paths that follow same pattern with different parameter names
  if _.contains @api.config.paths, @path
    throw new Error "Cannot add endpoint at an existing path: #{@path}"

  # Append the path to the base API path
  fullPath = @api.config.apiPath + @path

  # TODO: Remove log statements before package release
  console.log "Adding [#{ _.keys @methods }] methods to path: #{fullPath}"

  # Add all given methods using Iron Router
  Router.route fullPath,
    where: 'server'
    action: ->
      # Authenticate the request if necessary
      if self.api.config.useAuth and self.options.authRequired
        authenticate.call this

      # Respond to the requested HTTP method if an endpoint has been provided for it
      method = @request.method
      console.log "Handling #{method} request at #{self.path}"
      # TODO: Handle the different method definition types (e.g., function, object) proposed in README
      if method is 'GET' and self.methods.get
        responseBody = self.methods.get.call this
      else if method is 'POST' and self.methods.post
        _.extend @params, @request.body
        responseBody = self.methods.post.call this
      else if method is 'PUT' and self.methods.put
        _.extend @params, @request.body
        responseBody = self.methods.put.call this
      else if method is 'PATCH' and self.methods.patch
        _.extend @params, @request.body
        responseBody = self.methods.patch.call this
      else if method is 'DELETE' and self.methods.delete
        responseBody = self.methods.delete.call this
      else
        return [404, {success: false, message:'ReST API method not found'}]

      # TODO: Handle the different method responses proposed in README
      # TODO: Flatten params into this.urlParams, this.queryParams, and this.bodyParams

      # Generate and return the http response
      @response.writeHead 200,
        'Content-Type': 'text/json'
      @response.write JSON.stringify responseBody
      @response.end()

  # Add the path to our list of existing paths
  @api.config.paths.push @path


###
  Verify the request is being made by an actively logged in user
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
    # TODO: Execute the http error response here
    return [403, {success: false, message: "You must be logged in to do this."}]

  this.user = user