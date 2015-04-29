Package.describe({
  name: 'nimble:restivus',
  summary: 'Create authenticated REST APIs in Meteor 0.9+. Setup CRUD endpoints for Collections.',
  version: '0.6.5',
  git: 'https://github.com/kahmali/meteor-restivus.git'
});


Package.onUse(function (api) {
  // Minimum Meteor version
  api.versionsFrom('METEOR@0.9.0');

  // Meteor dependencies
  api.use('check');
  api.use('coffeescript');
  api.use('underscore');
  api.use('simple:json-routes@1.0.2');

  // Package files
  api.addFiles('lib/restivus.coffee');
  api.addFiles('lib/iron-router-error-to-response.js', 'server');
  api.addFiles('lib/route.coffee', 'server');
  api.addFiles('lib/auth.coffee', 'server');

  // Exports
  api.export('Restivus');
});


Package.onTest(function (api) {
  // Meteor dependencies
  api.use('test-helpers');
  api.use('nimble:restivus');
  api.use('http');
  api.use('coffeescript');
  api.use('peterellisjones:describe');

  api.addFiles('test/route_tests.coffee', 'server');
  api.addFiles('test/api_tests.coffee', 'server');
});