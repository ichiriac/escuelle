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
    'SELECT * FROM TABLE LIMIT 1, 2',
    'SELECT * FROM TABLE WHERE a=1 OR b=2 AND c=3',
    'SELECT * FROM TABLE WHERE (a=1 OR b>2) AND (c<3 OR d<>4)',
    'SELECT * FROM TABLE WHERE '+
      'a IS NULL OR '+
      'b IS NOT NULL OR '+
      'c LIKE \'%text\' OR '+
      'c NOT LIKE \'%text\' OR '+
      'd BETWEEN 1 AND 2 OR '+
      'f = 1 OR '+
      'g > 1 OR '+
      'h < 1 oR '+
      'i <> 0 OR '+
      'j >= 1 OR '+
      'k <= 10 OR '+
      'l != 1 OR ' +
      'm IN (a, b, c) OR '+
      'n NOT IN (a, b, c) ',
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
    assert(ast.where.rules[0].value.type === 'param');
    assert(ast.where.rules[0].value.name === 'arg1');
  });

  it(query[6], function(){
    var ast = lib(query[6]);
    // check limit statement
    assert(ast.limit && ast.limit.length === 2);
    assert(ast.limit[0] === 1);
    assert(ast.limit[1] === 2);
  });

  it(query[7], function(){
    var ast = lib(query[7]);
    // check where operands
    assert(ast.where.condition === 'OR');
    assert(ast.where.rules.length === 2);
    assert(ast.where.rules[1].condition === 'AND');
  });

  it(query[8], function(){
    var ast = lib(query[8]);
    // check where operands
    assert(ast.where.condition === 'AND');
    assert(ast.where.rules.length === 2);
    assert(ast.where.rules[0].condition === 'OR');
    assert(ast.where.rules[1].condition === 'OR');
  });

  it(query[9], function(){
    var ast = lib(query[9]);
    // check operators
    assert(ast.where.rules[0].operator === 'is_null');
    assert(ast.where.rules[1].operator === 'is_not_null');
    assert(ast.where.rules[2].operator === 'contains');
    assert(ast.where.rules[3].operator === 'not_contains');
    assert(ast.where.rules[4].operator === 'between');
    assert(ast.where.rules[5].operator === 'equal');
    assert(ast.where.rules[6].operator === 'greater');
    assert(ast.where.rules[7].operator === 'less');
    assert(ast.where.rules[8].operator === 'not_equal');
    assert(ast.where.rules[9].operator === 'greater_or_equal');
    assert(ast.where.rules[10].operator === 'less_or_equal');
    assert(ast.where.rules[11].operator === 'not_equal');
    assert(ast.where.rules[12].operator === 'in');
    assert(ast.where.rules[13].operator === 'not_in');
  });

});
