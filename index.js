var lib = require('./lib/parser');
module.exports = function(query) {
  return lib.parser.parse(query);
};