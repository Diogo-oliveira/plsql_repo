CREATE OR REPLACE TYPE aggr_clob_concat AS OBJECT
(
-- Author  : LUIS.MAIA
-- Created : 06-01-2009 17:14:47
-- Purpose : This type is necessary to allow CLOB concat.

-- Attributes
    str_agg CLOB,

-- Member functions and procedures
    STATIC FUNCTION odciaggregateinitialize(sctx IN OUT aggr_clob_concat) RETURN NUMBER,

    MEMBER FUNCTION odciaggregateiterate
    (
        SELF  IN OUT aggr_clob_concat,
        VALUE IN CLOB
    ) RETURN NUMBER,

    MEMBER FUNCTION odciaggregateterminate
    (
        SELF         IN aggr_clob_concat,
        return_value OUT CLOB,
        flags        IN NUMBER
    ) RETURN NUMBER,

    MEMBER FUNCTION odciaggregatemerge
    (
        SELF IN OUT aggr_clob_concat,
        ctx2 IN aggr_clob_concat
    ) RETURN NUMBER
		
);
/
