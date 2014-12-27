Package.describe
  name: 'nimblenotes:restfully'
  summary: 'A Meteor package for building ReSTful APIs, backed by Iron Router.'
  version: '0.0.0'
  git: 'https://github.com/krose72205/meteor-restfully.git'


Package.onUse (api) ->
  # Minimum Meteor version
  api.versionsFrom('METEOR@1.0.2.1')

  # Meteor dependencies
  api.use('underscore')
  api.use('coffeescript')
  api.use('iron:router')

  # Package files
  api.addFiles('restfully.coffee')


Package.onTest (api) ->
  # Meteor dependencies
  api.use('tinytest')
  api.use('nimblenotes:restfully')

  # Package test files
  api.addFiles('/* Fill me in! */')

