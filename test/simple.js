var assert = require("assert");
var lib = require("../index");

describe('Simple Select', function(){

  it('SELECT * FROM table', function(){
    var ast = lib('SELECT * FROM table');
    console.log(ast);
  });

});
