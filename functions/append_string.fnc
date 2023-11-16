CREATE OR REPLACE FUNCTION append_string(i_string IN VARCHAR2) RETURN table_varchar
    AGGREGATE USING aggr_table_varchar;
/
