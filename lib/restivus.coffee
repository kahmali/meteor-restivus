class @Restivus

  constructor: ->
    @routes = []
    @config =
      paths: []
      useAuth: false
      apiPath: 'api/'
      version: 1
      prettyJson: false
      auth:
        token: 'services.resume.loginTokens.token'
        user: ->
          userId: @request.headers['x-user-id']
          token: @request.headers['x-auth-token']
      onLoggedIn: -> {}
      onLoggedOut: -> {}
    @configured = false


  ###*
    Configure the ReST API

    Must be called exactly once, from anywhere on the server.
  ###
  configure: (config) ->
    if @configured
      throw new Error 'Restivus.configure() can only be called once'

    @configured = true

    # Configure API with the given options
    _.extend @config, config

    # Normalize the API path
    if @config.apiPath[0] is '/'
      @config.apiPath = @config.apiPath.slice 1
    if _.last(@config.apiPath) isnt '/'
      @config.apiPath = @config.apiPath + '/'

    # Add any existing routes to the API now that it's configured
    _.each @routes, (route) -> route.addToApi()

    # Add default login and logout endpoints if auth is configured
    if @config.useAuth
      @_initAuth()
      console.log "Restivus configured at #{@config.apiPath} with authentication"
    else
      console.log "Restivus configured at #{@config.apiPath} without authentication"
    return


  ###*
    Add endpoints for the given HTTP methods at the given path
  ###
  add: (path, options, methods) ->
    # Create a new route and add it to our list of existing routes
    route = new Route(this, path, options, methods)
    @routes.push(route)

    # Don't add the route to the API until the API has been configured
    route.addToApi() if @configured
    return


  ###*
    Generate routes for the Meteor Collection with the given name
  ###
  addCollection: (name, options = {}) ->
    methods = ['get', 'post', 'put', 'delete', 'getAll', 'deleteAll']
    methodsOnCollection = ['post', 'getAll', 'deleteAll']

    # Get the collection from the db
    if name.toLowerCase() is 'users'
      collection = Meteor.users
    else
      collection = new Mongo.Collection name

    # Get the path or use name as default
    path = options.path or name

    # Get the endpoints and any global options
    requestedEndpoints = options.endpoints
    endpointOptions = options.endpointOptions or {}

    # Separate the requested endpoints by the route they belong to (one for operating on the entire collection and one
    # for operating on a single entity within the collection)
    collectionEndpoints = {}
    entityEndpoints = {}
    if requestedEndpoints
      console.log requestedEndpoints
      console.log "Setting up a #{method} endpoint at #{path} with options #{endpointOptions.toString()}"
    else
      _.each methods, (method) ->
        if method in methodsOnCollection
          _.extend collectionEndpoints, @_collectionEndpoints[method](collection)
        else _.extend entityEndpoints, @_collectionEndpoints[method](collection)
        return
      , this

    # Add the routes to the API
    @add path, endpointOptions, collectionEndpoints
    @add "#{path}/:id", endpointOptions, entityEndpoints

    return


  ###*
    A set of endpoints that can be applied to a Collection Route
  ###
  _collectionEndpoints:
    get: (collection) ->
      get:
        action: ->
          entity = collection.findOne @urlParams.id
          if entity
            {status: "success", data: entity}
          else
            statusCode: 404
            body: {status: "fail", message: "Item not found"}
    put: (collection) ->
      put: ->
        entityIsUpdated = collection.update @urlParams.id, @bodyParams
        if entityIsUpdated
          entity = collection.findOne @urlParams.id
          {status: "success", data: entity}
        else
          statusCode: 404
          body: {status: "fail", message: "Item not found"}
    delete: (collection) ->
      delete: ->
        if collection.remove @urlParams.id
          {status: "success", data: message: "Item removed"}
        else
          statusCode: 404
          body: {status: "fail", message: "Item not found"}
    post: (collection) ->
      post: ->
        entityId = collection.insert @bodyParams
        entity = collection.findOne entityId
        if entity
          {status: "success", data: entity}
        else
          statusCode: 400
          {status: "fail", message: "No item added"}
    getAll: (collection) ->
      get:
        action: ->
          entities = collection.find().fetch()
          if not entities
            {status: "success", data: entities}
          else
            statusCode: 404
            body: {status: "fail", message: "Unable to retrieve items from collection"}
    deleteAll: (collection) ->
      delete: ->
        itemsRemoved = collection.remove()
        if itemsRemoved
          {status: "success", data: message: "Removed #{itemsRemoved} items"}
        else
          statusCode: 404
          body: {status: "fail", message: "No items found"}


  ###
    Add /login and /logout endpoints to the API
  ###
  _initAuth: ->
    self = this
    ###
      Add a login endpoint to the API

      After the user is logged in, the onLoggedIn hook is called (see Restfully.configure() for adding hook).
    ###
    @add 'login', {authRequired: false},
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
        if auth.userId and auth.authToken
          @user = Meteor.users.findOne
            '_id': auth.userId
            'services.resume.loginTokens.token': auth.authToken
          @userId = @user._id

        # TODO: Add any return data to response as data.extra
        # Call the login hook with the authenticated user attached
        self.config.onLoggedIn.call this

        auth.success = true
        auth

    ###
      Add a logout endpoint to the API

      After the user is logged out, the onLoggedOut hook is called (see Restfully.configure() for adding hook).
    ###
    @add 'logout', {authRequired: true},
      get: ->
        # Remove the given auth token from the user's account
        authToken = @request.headers['x-auth-token']
        Meteor.users.update @user._id, {$pull: {'services.resume.loginTokens': {token: authToken}}}

        # TODO: Add any return data to response as data.extra
        # Call the logout hook with the logged out user attached
        self.config.onLoggedOut.call this

        {success: true, message: 'You\'ve been logged out!'}

Restivus = new @Restivus