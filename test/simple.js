var assert = require("assert");
var lib = require("../index");

describe('Simple Select', function(){

  var query = [
    'SELECT * FROM a',
    'SELECT * FROM table1 a INNER JOIN table2 b ON a.id = b.fk',
    'SELECT * FROM table1 a, table2 b WHERE a.id = b.fk',
    'SELECT CustomCol as Alias FROM table ORDER BY CustomCol, OtherCol DESC',
    'SELECT Label, COUNT(*) as Counter FROM table GROUP BY Label',
    'SELECT DISTINCT * FROM this WHERE id = :arg1',
    'SELECT * FROM TABLE LIMIT 1, 2'
  ];

  it(query[0], function(){
    var ast = lib(query[0]);
    assert(ast.type === 'select');
    assert(ast.from[0].type === 'table');
    assert(ast.from[0].value.name === 'a');
    assert(ast.where === null);
    assert(ast.group === null);
    assert(ast.having === null);
    assert(ast.order === null);
  });

  it(query[1], function(){
    var ast = lib(query[1]);
    // check join
    assert(true);
  });

  it(query[2], function(){
    var ast = lib(query[2]);
    // check where & from parts
    assert(true);
  });

  it(query[3], function(){
    var ast = lib(query[3]);
    // check columns & orders
    assert(true);
  });

  it(query[4], function(){
    var ast = lib(query[4]);
    // check columns & group by
    assert(true);
  });

  it(query[5], function(){
    var ast = lib(query[5]);
    // check param & distinct
    assert(ast.distinct === true);
    assert(ast.where.value[0].right.value.type === 'param');
    assert(ast.where.value[0].right.value.name === 'arg1');
  });

  it(query[6], function(){
    var ast = lib(query[6]);
    // check limit statement
    assert(ast.limit && ast.limit.length === 2);
    assert(ast.limit[0] === 1);
    assert(ast.limit[1] === 2);
  });


});
