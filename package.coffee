Package.describe
  name: 'nimblenotes:restfully'
  summary: 'A Meteor package for building ReSTful APIs - inspired by RestStop and backed by Iron Router.'
  version: '0.0.0'
  git: 'https://github.com/krose72205/meteor-restfully.git'


Package.onUse (api) ->
  # Minimum Meteor version
  api.versionsFrom 'METEOR@0.9.0'

  # Meteor dependencies
  api.use 'check'
  api.use 'coffeescript'
  api.use 'underscore'
  api.use 'iron:router'

  # Package files
  api.addFiles 'lib/router.coffee', 'server'
  api.addFiles 'lib/auth.coffee', 'server'

  # Export Restfully
  api.export 'Restfully'


Package.onTest (api) ->
  # Meteor dependencies
  api.use 'tinytest'
  api.use 'test-helpers'
  api.use 'nimblenotes:restfully'