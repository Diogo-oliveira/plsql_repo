CREATE OR REPLACE TYPE BODY aggr_clob_concat IS

    STATIC FUNCTION odciaggregateinitialize(sctx IN OUT aggr_clob_concat) RETURN NUMBER IS
    BEGIN
        sctx := aggr_clob_concat(NULL);
        RETURN odciconst.success;
    END;

    MEMBER FUNCTION odciaggregateiterate
    (
        SELF  IN OUT aggr_clob_concat,
        VALUE IN CLOB
    ) RETURN NUMBER IS
    BEGIN
        str_agg := str_agg || VALUE;
        RETURN odciconst.success;
    END;

    MEMBER FUNCTION odciaggregateterminate
    (
        SELF         IN aggr_clob_concat,
        return_value OUT CLOB,
        flags        IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        return_value := str_agg;
        RETURN odciconst.success;
    END;

    MEMBER FUNCTION odciaggregatemerge
    (
        SELF IN OUT aggr_clob_concat,
        ctx2 IN aggr_clob_concat
    ) RETURN NUMBER IS
    BEGIN
        str_agg := str_agg || ctx2.str_agg;
        RETURN odciconst.success;
    END;

END;
/
