/**
 * Original from :
 * https://github.com/camilojd/sequeljs
 */

/* description: Parses SQL */
/* :tabSize=4:indentSize=4:noTabs=true: */
%lex

%options case-insensitive

%%

[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*   return 'QUALIFIED_IDENTIFIER'
\[[a-zA-Z_][a-zA-Z0-9_]*\]\.\[[a-zA-Z_][a-zA-Z0-9_]*\]   return 'MS_QUALIFIED_IDENTIFIER'
[a-zA-Z_][a-zA-Z0-9_]*\.\*                       return 'QUALIFIED_STAR'
\s+                                              /* skip whitespace */
'SELECT'                                         return 'SELECT'
'FROM'                                           return 'FROM'
'WHERE'                                          return 'WHERE'
'DISTINCT'                                       return 'DISTINCT'
'BETWEEN'                                        return 'BETWEEN'
'GROUP BY'                                       return 'GROUP_BY'
'HAVING'                                         return 'HAVING'
'LIMIT'                                          return 'LIMIT'
'ORDER BY'                                       return 'ORDER_BY'
','                                              return 'COMMA'
'+'                                              return 'PLUS'
'-'                                              return 'MINUS'
'/'                                              return 'DIVIDE'
'*'                                              return 'STAR'
'%'                                              return 'MODULO'
'='                                              return 'CMP_EQUALS'
'!='                                             return 'CMP_NOTEQUALS'
'<>'                                             return 'CMP_NOTEQUALS_BASIC'
'>='                                             return 'CMP_GREATEROREQUAL'
'>'                                              return 'CMP_GREATER'
'<='                                             return 'CMP_LESSOREQUAL'
'<'                                              return 'CMP_LESS'
'('                                              return 'LPAREN'
')'                                              return 'RPAREN'
'||'                                             return 'CONCAT'
'AS'                                             return 'AS'
'ALL'                                            return 'ALL'
'ANY'                                            return 'ANY'
'SOME'                                           return 'SOME'
'EXISTS'                                         return 'EXISTS'
'IS'                                             return 'IS'
'IN'                                             return 'IN'
'ON'                                             return 'ON'
'AND'                                            return 'LOGICAL_AND'
'OR'                                             return 'LOGICAL_OR'
'NOT'                                            return 'LOGICAL_NOT'
'INNER'                                          return 'INNER'
'OUTER'                                          return 'OUTER'
'JOIN'                                           return 'JOIN'
'LEFT'                                           return 'LEFT'
'RIGHT'                                          return 'RIGHT'
'FULL'                                           return 'FULL'
'NATURAL'                                        return 'NATURAL'
'CROSS'                                          return 'CROSS'
'CASE'                                           return 'CASE'
'WHEN'                                           return 'WHEN'
'THEN'                                           return 'THEN'
'ELSE'                                           return 'ELSE'
'END'                                            return 'END'
'LIKE'                                           return 'LIKE'
'ASC'                                            return 'ASC'
'DESC'                                           return 'DESC'
'NULLS'                                          return 'NULLS'
'FIRST'                                          return 'FIRST'
'LAST'                                           return 'LAST'
['](\\.|[^'])*[']                                return 'STRING'
'NULL'                                           return 'NULL'
(true|false)                                     return 'BOOLEAN'
':'[a-zA-Z_][a-zA-Z0-9_]*                        return 'PARAMETER'
[0-9]+(\.[0-9]+)?                                return 'NUMERIC'
[a-zA-Z_][a-zA-Z0-9_]*                           return 'IDENTIFIER'
\[[a-zA-Z_][^\]]*\]                              return 'MS_IDENTIFIER'
<<EOF>>                                          return 'EOF'
.                                                return 'INVALID'

/lex

%start main

%% /* language grammar */

main
    : selectClause EOF { return $1; }
    ;

selectClause
    : SELECT optDistinct selectExprList
      FROM tableExprList
      optWhereClause optGroupByClause optHavingClause optOrderByClause optLimitClause
      {
        $$ = {
          type: 'select',
          distinct: !!$1,
          columns: $3,
          from: $5,
          where:$6,
          group:$7,
          having:$8,
          order:$9,
          limit: $10
        };
      }
    ;

optDistinct
    : { $$ = false; }
    | DISTINCT { $$ = true; }
    ;

optWhereClause
    : { $$ = null; }
    | WHERE expression { $$ = $2; }
    ;

optGroupByClause
    : { $$ = null; }
    | GROUP_BY commaSepExpressionList { $$ = $2; }
    ;

optHavingClause
    : { $$ = null; }
    | HAVING expression { $$ = $2; }
    ;

optLimitClause
    : { $$ = null; }
    | LIMIT NUMERIC COMMA NUMERIC { $$ = [parseInt($2), parseInt($4)]; }
    | LIMIT NUMERIC { $$ = [0, parseInt($2)]; }
    ;

optOrderByClause
    : { $$ = null; }
    | ORDER_BY orderByList { $$ = $2; }
    ;

orderByList
    : orderByList COMMA orderByListItem { $$ = $1; $1.push($3); }
    | orderByListItem { $$ = [$1]; }
    ;

orderByListItem
    : expression optOrderByOrder optOrderByNulls { $$ = {expr:$1, orderAsc: $2, orderByNulls: $3}; }
    ;

optOrderByOrder
    : { $$ = true; }
    | ASC { $$ = true; }
    | DESC { $$ = false; }
    ;

optOrderByNulls
    : { $$ = '';}
    | NULLS FIRST { $$ = 'NULLS FIRST'; }
    | NULLS LAST { $$ = 'NULLS LAST'; }
    ;

selectExprList
    : selectExpr { $$ = [$1]; }
    | selectExprList COMMA selectExpr { $$ = $1; $1.push($3); }
    ;

selectExpr
    : STAR { $$ = {type: 'column', value:'*'}; }
    | QUALIFIED_STAR  { $$ = {type: 'column', value:$1}; }
    | expression optTableExprAlias  { $$ = {type: 'column', value:$1, alias:$2}; }
    ;

tableExprList
    : tableExpr { $$ = [$1]; }
    | tableExprList COMMA tableExpr { $$ = $1; $1.push($3); }
    ;

tableExpr
    : joinComponent { $$ = {type:'table', value: $1, join: []}; }
    | tableExpr optJoinModifier JOIN joinComponent { $$ = $1; $1.join.push({type:'table', value: $4, modifier:$2}); }
    | tableExpr optJoinModifier JOIN joinComponent ON expression { $$ = $1; $1.join.push({type:'table', value: $4, modifier:$2, expr:$6}); }
    ;

joinComponent
    : tableExprPart optTableExprAlias { $$ = {name: $1, alias: $2}; }
    ;

tableExprPart
    : IDENTIFIER { $$ = $1; }
    | QUALIFIED_IDENTIFIER { $$ = $1; }
    | MS_IDENTIFIER { $$ = $1.substring(1, $1.length - 1); }
    | MS_QUALIFIED_IDENTIFIER { $$ = $1.substring(1, $1.length - 1); }
    | STRING { $$ = $1.substring(1, $1.length - 1); }
    | LPAREN selectClause RPAREN { $$ = $2; }
    ;

optTableExprAlias
    : { $$ = null; }
    | IDENTIFIER { $$ = {value: $1 }; }
    | AS IDENTIFIER { $$ = {value: $2, alias: 1}; }
    ;

optJoinModifier
    : { $$ = ''; }
    | LEFT        { $$ = 'LEFT'; }
    | LEFT OUTER  { $$ = 'LEFT OUTER'; }
    | RIGHT       { $$ = 'RIGHT'; }
    | RIGHT OUTER { $$ = 'RIGHT OUTER'; }
    | FULL        { $$ = 'FULL'; }
    | INNER       { $$ = 'INNER'; }
    | CROSS       { $$ = 'CROSS'; }
    | NATURAL     { $$ = 'NATURAL'; }
    ;

expression
    : condition { $$ = { condition:'AND', rules: [$1]}; }
    | condition LOGICAL_AND expression {
      if($3.condition === 'AND') {
        $3.rules.unshift($1);
        $1 = $3.rules;
      } else {
        if ($3.rules.length === 1) $3 = $3.rules[0];
        $1 = [$1, $3];
      }
      $$ = { condition: 'AND', rules: $1 };
    }
    | condition LOGICAL_OR expression {
      if ($3.condition === 'OR') {
        $3.rules.unshift($1);
        $1 = $3.rules;
      } else {
        if ($3.rules.length === 1) $3 = $3.rules[0];
        $1 = [$1, $3];
      }
      $$ = { condition: 'OR', rules: $1 };
    }
    ;

condition
    : operand { $$ = $1; }
    | operand conditionRightHandSide {
      if ($1.type === 'Term' && $1.value) {
        $1 = $1.value;
      }
      if ($2.value && $2.value.type && $2.value.value) {
        $2.value = $2.value.value;
      }
      if ($2.type === 'RhsIs') {
        if (!$2.value || $2.value.type == 'null') {
          $$ = { operator: $2.not ? 'is_not_null' : 'is_null', id: $1 };
        } else {
          $$ = { operator: $2.not ? 'is_not' : 'is', id: $1, value: $2.value };
        }
      } else if ($2.type === 'RhsLike') {
        if ($2.value[0] === '%') {
          $$ = { operator: $2.not ? 'not_ends_with' : 'ends_with', id: $1, value: $2.value };
        } else if ($2.value.substring(-1) === '%') {
          $$ = { operator: $2.not ? 'not_begins_with' : 'begins_with', id: $1, value: $2.value };
        } else {
          $$ = { operator: $2.not ? 'not_contains' : 'contains', id: $1, value: $2.value };
        }
      } else if ($2.type === 'RhsBetween') {
        if ($2.left.type && $2.left.value) {
          $2.left = $2.left.value;
        }
        if ($2.right.type && $2.right.value) {
          $2.right = $2.right.value;
        }
        $$ = { operator: $2.not ? 'not_between' : 'between', id: $1, value: [$2.left, $2.right] };
      } else if ($2.type === 'RhsInExpressionList') {
        $$ = { operator: $2.not ? 'not_in' : 'in', id: $1, value: $2.value };
      } else if ($2.op) {
        $$ = { operator: $2.op, id: $1, value: $2.value };
      } else {
        $$ = { type: 'BinaryCondition', left: $1, right: $2 };
      }
    }
    | EXISTS LPAREN selectClause RPAREN { $$ = {type: 'ExistsCondition', value: $3}; }
    | LOGICAL_NOT condition { $$ = {type: 'NotCondition', value: $2}; }
    ;

compare
    : CMP_EQUALS { $$ = 'equal'; }
    | CMP_NOTEQUALS { $$ = 'not_equal'; }
    | CMP_NOTEQUALS_BASIC { $$ = 'not_equal'; }
    | CMP_GREATER { $$ = 'greater'; }
    | CMP_GREATEROREQUAL { $$ = 'greater_or_equal'; }
    | CMP_LESS { $$ = 'less'; }
    | CMP_LESSOREQUAL { $$ = 'less_or_equal'; }
    ;

conditionRightHandSide
    : rhsCompareTest { $$ = $1; }
    | rhsIsTest { $$ = $1; }
    | rhsInTest { $$ = $1; }
    | rhsLikeTest { $$ = $1; }
    | rhsBetweenTest { $$ = $1; }
    ;

rhsCompareTest
    : compare operand { $$ = {type: 'RhsCompare', op: $1, value: $2 }; }
    | compare ALL LPAREN selectClause RPAREN { $$ = {type: 'RhsCompareSub', op:$1, kind: $2, value: $4 }; }
    | compare ANY LPAREN selectClause RPAREN { $$ = {type: 'RhsCompareSub', op:$1, kind: $2, value: $4 }; }
    | compare SOME LPAREN selectClause RPAREN { $$ = {type: 'RhsCompareSub', op:$1, kind: $2, value: $4 }; }
    ;

rhsIsTest
    : IS operand { $$ = {type: 'RhsIs', value: $2}; }
    | IS LOGICAL_NOT operand { $$ = {type: 'RhsIs', value: $3, not:1}; }
    | IS DISTINCT FROM operand { $$ = {type: 'RhsIs', value: $4, distinctFrom:1}; }
    | IS LOGICAL_NOT DISTINCT FROM operand { $$ = {type: 'RhsIs', value: $5, not:1, distinctFrom:1}; }
    ;

rhsInTest
    : IN LPAREN selectClause RPAREN { $$ = { type: 'RhsInSelect', value: $3 }; }
    | LOGICAL_NOT IN LPAREN selectClause RPAREN { $$ = { type: 'RhsInSelect', value: $4, not:1 }; }
    | IN LPAREN commaSepExpressionList RPAREN { $$ = { type: 'RhsInExpressionList', value: $3 }; }
    | LOGICAL_NOT IN LPAREN commaSepExpressionList RPAREN { $$ = { type: 'RhsInExpressionList', value: $4, not:1 }; }
    ;

commaSepExpressionList
    : commaSepExpressionList COMMA expression { $$ = $1; $1.push($3); }
    | expression { $$ = [$1]; }
    ;

functionParam
    : expression { $$ = $1; }
    | STAR { $$ = $1; }
    | QUALIFIED_STAR { $$ = $1; }
    ;

functionExpressionList
    : functionExpressionList COMMA functionParam { $$ = $1; $1.push($3); }
    | functionExpressionList ';' functionParam { $$ = $1; $1.push($3);  }
    | functionParam { $$ = [$1]; }
    ;

/*
 * Function params are defined by an optional list of functionParam elements,
 * because you may call functions of with STAR/QUALIFIED_STAR parameters (Like COUNT(*)),
 * which aren't `Term`(s) because they cant't have an alias
 */
optFunctionExpressionList
    : { $$ = null; }
    | functionExpressionList { $$ = $1; }
    ;

rhsLikeTest
    : LIKE operand { $$ = {type: 'RhsLike', value: $2}; }
    | LOGICAL_NOT LIKE operand { $$ = {type: 'RhsLike', value: $3, not:1}; }
    ;

rhsBetweenTest
    : BETWEEN operand LOGICAL_AND operand { $$ = {type: 'RhsBetween', left: $2, right: $4}; }
    | LOGICAL_NOT BETWEEN operand LOGICAL_AND operand { $$ = {type: 'RhsBetween', left: $3, right: $5, not:1}; }
    ;

operand
    : summand { $$ = $1; }
    | operand CONCAT summand { $$ = {type:'Operand', left:$1, right:$3, op:$2}; }
    ;


summand
    : factor { $$ = $1; }
    | summand PLUS factor { $$ = {type:'Summand', left:$1, right:$3, op:$2}; }
    | summand MINUS factor { $$ = {type:'Summand', left:$1, right:$3, op:$2}; }
    ;

factor
    : term { $$ = $1; }
    | factor DIVIDE term { $$ = {type:'Factor', left:$1, right:$3, op:$2}; }
    | factor STAR term { $$ = {type:'Factor', left:$1, right:$3, op:$2}; }
    | factor MODULO term { $$ = {type:'Factor', left:$1, right:$3, op:$2}; }
    ;

term
    : value { $$ = $1; }
    | IDENTIFIER { $$ = {type: 'Term', value: $1}; }
    | QUALIFIED_IDENTIFIER { $$ = {type: 'Term', value: $1}; }
    | MS_IDENTIFIER { $$ = {type: 'Term', value: $1.substring(1, $1.length - 1)}; }
    | MS_QUALIFIED_IDENTIFIER { $$ = {type: 'Term', value: $1.substring(1, $1.length - 1)}; }
    | caseWhen { $$ = $1; }
    | LPAREN expression RPAREN { $$ = $2; }
    | IDENTIFIER LPAREN optFunctionExpressionList RPAREN { $$ = {type: 'call', name: $1, args: $3}; }
    | QUALIFIED_IDENTIFIER LPAREN optFunctionExpressionList RPAREN { $$ = {type: 'call', name: $1, args: $3}; }
    ;

caseWhen
    : CASE caseWhenList optCaseWhenElse END { $$ = {type:'case', clauses: $2, else: $3}; }
    ;

caseWhenList
    : caseWhenList WHEN expression THEN expression { $$ = $1; $1.push({when: $3, then: $5}); }
    | WHEN expression THEN expression { $$ = [{when: $2, then: $4}]; }
    ;

optCaseWhenElse
    : { $$ = null; }
    | ELSE expression { $$ = $2; }
    ;

value
    : STRING { $$ = {type: 'string', value: $1}; }
    | NUMERIC { $$ = {type: 'number', value: $1}; }
    | PARAMETER { $$ = {type: 'param', name: $1.substring(1)}; }
    | BOOLEAN { $$ = {type: 'boolean', value: $1}; }
    | NULL { $$ = {type: 'null'}; }
    ;
