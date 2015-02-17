Package.describe({
  name: 'nimble:restivus',
  summary: 'Create authenticated REST APIs in Meteor 0.9.0+. Setup CRUD endpoints for Collections.',
  version: '0.6.0',
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

  // Package files
  api.addFiles('lib/restivus.coffee', 'server');
  api.addFiles('lib/route.coffee', 'server')
  api.addFiles('lib/auth.coffee', 'server');

  // Export Restfully
  api.export('Restivus');
});


Package.onTest(function (api) {
  // Meteor dependencies
  api.use('tinytest');
  api.use('test-helpers');
  api.use('nimble:restivus');
});