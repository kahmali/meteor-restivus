Package.describe({
  name: 'nimble:restivus',
  summary: 'Create authenticated REST APIs in Meteor 0.9+. Setup CRUD endpoints for Collections.',
  version: '0.7.1',
  git: 'https://github.com/kahmali/meteor-restivus.git'
});


Package.onUse(function (api) {
  // Minimum Meteor version
  api.versionsFrom('METEOR@0.9.0');

  // Meteor dependencies
  api.use('check');
  api.use('coffeescript');
  api.use('underscore');
  api.use('iron:router@1.0.6');
  api.use('accounts-base@1.2.0');

  // Package files
  api.addFiles('lib/restivus.coffee', 'server');
  api.addFiles('lib/route.coffee', 'server');
  api.addFiles('lib/auth.coffee', 'server');

  // Exports
  api.export('Restivus', 'server');
});


Package.onTest(function (api) {
  // Meteor dependencies
  api.use('test-helpers');
  api.use('nimble:restivus');
  api.use('http');
  api.use('coffeescript');
  api.use('peterellisjones:describe');
  api.use('accounts-base');
  api.use('accounts-password');

  api.addFiles('test/route_tests.coffee', 'server');
  api.addFiles('test/api_tests.coffee', 'server');
  api.addFiles('test/authentication_tests.coffee', 'server');
});
