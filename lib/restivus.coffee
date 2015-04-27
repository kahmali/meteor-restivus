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
      defaultHeaders:
        'Content-Type': 'application/json'
      enableCors: true
    @configured = false


  ###*
    Configure the ReST API

    Must be called exactly once, from anywhere on the server.
  ###
  configure: (config) =>
    if @configured
      throw new Error 'Restivus.configure() can only be called once'

    @configured = true

    # Configure API with the given options
    _.extend @config, config

    # Set default header to enable CORS if configured
    if @config.enableCors
      _.extend @config.defaultHeaders, 'Access-Control-Allow-Origin': '*'

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
  addRoute: (path, options, methods) ->
    # Create a new route and add it to our list of existing routes
    route = new Route(this, path, options, methods)
    @routes.push(route)

    # Don't add the route to the API until the API has been configured
    route.addToApi() if @configured
    return


  ###*
    Generate routes for the Meteor Collection with the given name
  ###
  addCollection: (collection, options={}) ->
    methods = ['get', 'post', 'put', 'delete', 'getAll', 'deleteAll']
    methodsOnCollection = ['post', 'getAll', 'deleteAll']

    # Grab the set of endpoints
    if collection is Meteor.users
      collectionEndpoints = @_userCollectionEndpoints
    else
      collectionEndpoints = @_collectionEndpoints

    # Flatten the options and set defaults if necessary
    endpointsAwaitingConfiguration = options.endpoints or {}
    routeOptions = options.routeOptions or {}
    excludedEndpoints = options.excludedEndpoints or []
    # Use collection name as default path
    path = options.path or collection._name

    # Separate the requested endpoints by the route they belong to (one for operating on the entire collection and one
    # for operating on a single entity within the collection)
    collectionRouteEndpoints = {}
    entityRouteEndpoints = {}
    if _.isEmpty(endpointsAwaitingConfiguration) and _.isEmpty(excludedEndpoints)
      # Generate all endpoints on this collection
      _.each methods, (method) ->
        # Partition the endpoints into their respective routes
        if method in methodsOnCollection
          _.extend collectionRouteEndpoints, collectionEndpoints[method].call(this, collection)
        else _.extend entityRouteEndpoints, collectionEndpoints[method].call(this, collection)
        return
      , this
    else
      # Generate any endpoints that haven't been explicitly excluded
      _.each methods, (method) ->
        if method not in excludedEndpoints and endpointsAwaitingConfiguration[method] isnt false
          # Configure endpoint and map to it's http method
          # TODO: Consider predefining a map of methods to their http method type (e.g., deleteAll: delete)
          endpointOptions = endpointsAwaitingConfiguration[method]
          configuredEndpoint = {}
          _.each collectionEndpoints[method].call(this, collection), (action, methodType) ->
            configuredEndpoint[methodType] =
              _.chain action
              .clone()
              .extend endpointOptions
              .value()
          # Partition the endpoints into their respective routes
          if method in methodsOnCollection
            _.extend collectionRouteEndpoints, configuredEndpoint
          else _.extend entityRouteEndpoints, configuredEndpoint
          return
      , this

    # Add the routes to the API
    @addRoute path, routeOptions, collectionRouteEndpoints
    @addRoute "#{path}/:id", routeOptions, entityRouteEndpoints

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
      put:
        action: ->
          entityIsUpdated = collection.update @urlParams.id, @bodyParams
          if entityIsUpdated
            entity = collection.findOne @urlParams.id
            {status: "success", data: entity}
          else
            statusCode: 404
            body: {status: "fail", message: "Item not found"}
    delete: (collection) ->
      delete:
        action: ->
          if collection.remove @urlParams.id
            {status: "success", data: message: "Item removed"}
          else
            statusCode: 404
            body: {status: "fail", message: "Item not found"}
    post: (collection) ->
      post:
        action: ->
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
          if entities
            {status: "success", data: entities}
          else
            statusCode: 404
            body: {status: "fail", message: "Unable to retrieve items from collection"}
    deleteAll: (collection) ->
      delete:
        action: ->
          itemsRemoved = collection.remove({})
          if itemsRemoved
            {status: "success", data: message: "Removed #{itemsRemoved} items"}
          else
            statusCode: 404
            body: {status: "fail", message: "No items found"}


  ###*
    A set of endpoints that can be applied to a Meteor.users Collection Route
  ###
  _userCollectionEndpoints:
    get: (collection) ->
      get:
        action: ->
          entity = collection.findOne @urlParams.id, fields: profile: 1
          if entity
            {status: "success", data: entity}
          else
            statusCode: 404
            body: {status: "fail", message: "User not found"}
    put: (collection) ->
      put:
        action: ->
          entityIsUpdated = collection.update @urlParams.id, $set: profile: @bodyParams
          if entityIsUpdated
            entity = collection.findOne @urlParams.id, fields: profile: 1
            {status: "success", data: entity}
          else
            statusCode: 404
            body: {status: "fail", message: "User not found"}
    delete: (collection) ->
      delete:
        action: ->
          if collection.remove @urlParams.id
            {status: "success", data: message: "User removed"}
          else
            statusCode: 404
            body: {status: "fail", message: "User not found"}
    post: (collection) ->
      post:
        action: ->
          # Create a new user account
          entityId = Accounts.createUser @bodyParams
          entity = collection.findOne entityId, fields: profile: 1
          if entity
            {status: "success", data: entity}
          else
            statusCode: 400
            {status: "fail", message: "No user added"}
    getAll: (collection) ->
      get:
        action: ->
          entities = collection.find({}, fields: profile: 1).fetch()
          if entities
            {status: "success", data: entities}
          else
            statusCode: 404
            body: {status: "fail", message: "Unable to retrieve users"}
    deleteAll: (collection) ->
      delete:
        action: ->
          usersRemoved = collection.remove({})
          if usersRemoved
            {status: "success", data: message: "Removed #{usersRemoved} users"}
          else
            statusCode: 404
            body: {status: "fail", message: "No users found"}


  ###
    Add /login and /logout endpoints to the API
  ###
  _initAuth: ->
    self = this
    ###
      Add a login endpoint to the API

      After the user is logged in, the onLoggedIn hook is called (see Restfully.configure() for adding hook).
    ###
    @addRoute 'login', {authRequired: false},
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
          return {} =
            statusCode: e.error
            body: status: "error", message: e.reason

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

        {status: "success", data: auth}

    ###
      Add a logout endpoint to the API

      After the user is logged out, the onLoggedOut hook is called (see Restfully.configure() for adding hook).
    ###
    @addRoute 'logout', {authRequired: true},
      get: ->
        # Remove the given auth token from the user's account
        authToken = @request.headers['x-auth-token']
        Meteor.users.update @user._id, {$pull: {'services.resume.loginTokens': {token: authToken}}}

        # TODO: Add any return data to response as data.extra
        # Call the logout hook with the logged out user attached
        self.config.onLoggedOut.call this

        {status: "success", data: message: 'You\'ve been logged out!'}

Restivus = new @Restivus