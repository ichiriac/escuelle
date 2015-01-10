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
[a-zA-Z_][a-zA-Z0-9_]*\.\*                       return 'QUALIFIED_STAR'
\s+                                              /* skip whitespace */
'SELECT'                                         return 'SELECT'
'FROM'                                           return 'FROM'
'WHERE'                                          return 'WHERE'
'DISTINCT'                                       return 'DISTINCT'
'BETWEEN'                                        return 'BETWEEN'
'GROUP BY'                                       return 'GROUP_BY'
'HAVING'                                         return 'HAVING'
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
':'[a-zA-Z_][a-zA-Z0-9_]*                          return 'PARAMETER'
[0-9]+(\.[0-9]+)?                                return 'NUMERIC'
[a-zA-Z_][a-zA-Z0-9_]*                           return 'IDENTIFIER'
<<EOF>>                                          return 'EOF'
.                                                return 'INVALID'

/lex

%start main

%% /* language grammar */

main
    : selectClause EOF { return $1; } 
    ;

selectClause
    : SELECT selectExprList 
      FROM tableExprList
      optWhereClause optGroupByClause optHavingClause optOrderByClause
      { $$ = {type: 'select', columns: $2, from: $4, where:$5, group:$6, having:$7, order:$8}; }
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
    : andCondition { $$ = {type:'and', value: $1}; }
    | expression LOGICAL_OR andCondition { $$ = {type:'or', left: $1, right: $3}; }
    ;

andCondition
    : condition { $$ = [$1]; }
    | andCondition LOGICAL_AND condition { $$ = $1; $1.push($3); }
    ;

condition
    : operand { $$ = {type: 'Condition', value: $1}; }
    | operand conditionRightHandSide { $$ = {type: 'BinaryCondition', left: $1, right: $2}; }
    | EXISTS LPAREN selectClause RPAREN { $$ = {type: 'ExistsCondition', value: $3}; }
    | LOGICAL_NOT condition { $$ = {type: 'NotCondition', value: $2}; }
    ;

compare
    : CMP_EQUALS { $$ = $1; }
    | CMP_NOTEQUALS { $$ = $1; }
    | CMP_NOTEQUALS_BASIC { $$ = $1; }
    | CMP_GREATER { $$ = $1; }
    | CMP_GREATEROREQUAL { $$ = $1; }
    | CMP_LESS { $$ = $1; }
    | CMP_LESSOREQUAL { $$ = $1; }
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
    : value { $$ = {type: 'Term', value: $1}; }
    | IDENTIFIER { $$ = {type: 'Term', value: $1}; }
    | QUALIFIED_IDENTIFIER { $$ = {type: 'Term', value: $1}; }
    | caseWhen { $$ = $1; }
    | LPAREN expression RPAREN { $$ = {type: 'Term', value: $2}; }
    | IDENTIFIER LPAREN optFunctionExpressionList RPAREN { $$ = {type: 'FunctionCall', name: $1, args: $3}; }
    | QUALIFIED_IDENTIFIER LPAREN optFunctionExpressionList RPAREN { $$ = {type: 'FunctionCall', name: $1, args: $3}; }
    ;

caseWhen
    : CASE caseWhenList optCaseWhenElse END { $$ = {type:'Case', clauses: $2, else: $3}; }
    ;

caseWhenList
    : caseWhenList WHEN expression THEN expression { $$ = $1; $1.push({type: 'CaseItem', when: $3, then: $5}); }
    | WHEN expression THEN expression { $$ = [{type: 'CaseItem', when: $2, then: $4}]; }
    ;

optCaseWhenElse
    : { $$ = null; }
    | ELSE expression { $$ = $2; }
    ;

value
    : STRING { $$ = $1; } 
    | NUMERIC { $$ = $1; }
    | BOOLEAN { $$ = $1; }
    | NULL { $$ = $1; }
    ;

