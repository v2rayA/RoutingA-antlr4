// Define a grammar called routingA
grammar routingA;

// Fragments
fragment SAFE_ID_HEAD_CHAR: [a-zA-Z_] ;
fragment SAFE_NONID_HEAD_CHAR: [/\\^*.+0-9-] ;
fragment SAFE_INTERMEDIATE_CHAR: [@$] ;
fragment SAFE_CHAR: ( SAFE_ID_HEAD_CHAR | SAFE_NONID_HEAD_CHAR | SAFE_INTERMEDIATE_CHAR ) ;
fragment DOUBLE_QUOTE_STRING : '"' ( '\\"' | . )*? '"' ; // match "foo", "\"", "x\"\"y", ...
fragment SINGLE_QUOTE_STRING : '\'' ( '\\\'' | . )*? '\'' ; // match 'foo', '\'', 'x\'\'y', ...

// Tokens
WHITESPACE : [ \t\r\n]+ -> skip ; // skip spaces, tabs, newlines
COMMENT_BLOCK : '/*' .*? '*/' -> skip ;
COMMENT_LINE_SHARP : '#' .*? ( [\r\n]+ | EOF ) -> skip ;

ID : SAFE_ID_HEAD_CHAR SAFE_CHAR* ;
NON_ID : SAFE_NONID_HEAD_CHAR SAFE_CHAR* ;
QUOTE_STRING: DOUBLE_QUOTE_STRING | SINGLE_QUOTE_STRING;

// Rules
start : input EOF;

bare_literal : ID | NON_ID ;
quote_literal :  QUOTE_STRING;
literal : quote_literal | bare_literal ;

input
    : programStructureBlcok
    | input programStructureBlcok
    | // empty
    ;

programStructureBlcok
    : optConditionStatement optFunctionPrototypeExpressionAnd expression
    ;

expression
    : declaration
    | routingRule
    | '{' routingRuleOrDeclarationList '}'
    ;

optConditionStatement
    : '@' ID '==' literal
    | '@' ID '!=' literal
    | // empty
    ;

optFunctionPrototypeExpressionAnd
    : functionPrototypeExpression '&&'
    | // empty
    ;

declaration
    : ID ':' assignmentExpression
    | ID ':' literal
    ;

assignmentExpression
    : ID '=' functionPrototype
    ;

functionPrototype
    : ID '(' parameterList ')'
    ;

parameterList
    : nonEmptyParameterList
    | // empty
    ;

nonEmptyParameterList
    : parameter
    | nonEmptyParameterList ',' parameter
    ;

parameter
    : ID ':' literal
    | ID '=' literal
    | literal
    ;

routingRule
    : functionPrototypeExpression '->' bare_literal
    |  '{' functionPrototypeExpressionList '}' '->' bare_literal
    ;

functionPrototypeExpression
    : functionPrototype
    | functionPrototypeExpression '&&' functionPrototypeExpression
//    | functionPrototypeExpression '||' functionPrototypeExpression
    ;

functionPrototypeExpressionList
    : functionPrototypeExpression
    | functionPrototypeExpression functionPrototypeExpressionList
    ;

routingRuleOrDeclarationList
    : routingRule routingRuleOrDeclarationList
    | declaration routingRuleOrDeclarationList
    | // empty
    ;