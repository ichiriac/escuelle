# ESCUELLE (SQL)

This library contains an SQL parser that converts a query string into a structured object (AST).

[![Coverage Status](https://coveralls.io/repos/ichiriac/escuelle/badge.png)](https://coveralls.io/r/ichiriac/escuelle)

## How to use it

- Add it to you project with :

```sh
$ npm install esquelle --save
```

- And use it into your code :

```js
var sql_parser = require('esquelle');

console.log(
  sql_parser('SELECT * FROM your_table')
);
```