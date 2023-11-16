CREATE OR REPLACE TYPE aggr_table_varchar AS OBJECT
(
    l_tv table_varchar,

    STATIC FUNCTION ODCIAggregateInitialize(i_atv IN OUT aggr_table_varchar) RETURN NUMBER,

    MEMBER FUNCTION ODCIAggregateIterate
    (
        SELF     IN OUT aggr_table_varchar,
        i_string IN VARCHAR2
    ) RETURN NUMBER,

    MEMBER FUNCTION ODCIAggregateMerge
    (
        SELF  IN OUT aggr_table_varchar,
        i_atv IN aggr_table_varchar
    ) RETURN NUMBER,

    MEMBER FUNCTION ODCIAggregateTerminate
    (
        SELF           IN OUT aggr_table_varchar,
        o_return_value OUT table_varchar,
        i_flags        IN NUMBER
    ) RETURN NUMBER
)
/
CREATE OR REPLACE TYPE BODY aggr_table_varchar IS

    STATIC FUNCTION ODCIAggregateInitialize(i_atv IN OUT aggr_table_varchar) RETURN NUMBER IS
    BEGIN
        i_atv := aggr_table_varchar(table_varchar());
        RETURN ODCIConst.Success;
    END ODCIAggregateInitialize;

    MEMBER FUNCTION ODCIAggregateIterate
    (
        SELF     IN OUT aggr_table_varchar,
        i_string IN VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
        IF i_string IS NOT NULL
        THEN
            self.l_tv.extend;
            self.l_tv(self.l_tv.last) := i_string;
        END IF;
    
        RETURN ODCIConst.Success;
    END ODCIAggregateIterate;

    MEMBER FUNCTION ODCIAggregateMerge
    (
        SELF  IN OUT aggr_table_varchar,
        i_atv IN aggr_table_varchar
    ) RETURN NUMBER IS
    BEGIN
        RETURN ODCIConst.Success;
    END ODCIAggregateMerge;

    MEMBER FUNCTION ODCIAggregateTerminate
    (
        SELF           IN OUT aggr_table_varchar,
        o_return_value OUT table_varchar,
        i_flags        IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        o_return_value := self.l_tv;
        RETURN ODCIConst.Success;
    END ODCIAggregateTerminate;

END;
/
