#!/usr/bin/env node

var sys = require('sys');
var exec = require('child_process').exec;
var path = __dirname;

exec(
  'node ' + path + '/../node_modules/jison/lib/cli.js '
  + path + '/../lib/parser.jison '
  + '-o ' + path + '/../lib/parser.js'
  , function (error, stdout, stderr) {
    sys.print(stdout);
    sys.print(stderr);
    if (error !== null) {
      console.log('\n' + error);
      process.exit(1);
    }
  }
);