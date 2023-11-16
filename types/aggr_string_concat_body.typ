CREATE OR REPLACE TYPE BODY aggr_string_concat IS
    STATIC FUNCTION odciaggregateinitialize(po_sctx IN OUT aggr_string_concat) RETURN NUMBER IS
    BEGIN
        po_sctx := aggr_string_concat('');
        RETURN odciconst.success;
    END;
    MEMBER FUNCTION odciaggregateiterate
    (
        SELF IN OUT aggr_string_concat,
        val  IN VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
        SELF.ps_string_so_far := SELF.ps_string_so_far|| val;
        RETURN odciconst.success;
    END;
    MEMBER FUNCTION odciaggregateterminate
    (
        SELF           IN aggr_string_concat,
        ps_returnvalue OUT VARCHAR2,
        pn_flags       IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        ps_returnvalue := SELF.ps_string_so_far;
        RETURN odciconst.success;
    END;
    MEMBER FUNCTION odciaggregatemerge
    (
        SELF    IN OUT aggr_string_concat,
        po_ctx2 IN aggr_string_concat
    ) RETURN NUMBER IS
    BEGIN
        RETURN odciconst.success;
    END;
END;
/
