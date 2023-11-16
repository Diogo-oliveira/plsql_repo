-- CREATED BY: Pedro Pinheiro
-- CREATED DATE: 13/02/2012 12:00
-- CREATED REASON: [ALERT-217580]
DECLARE
    e_already_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_already_exists, -02303);
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_search_lob AS OBJECT(code_translation VARCHAR2(4000), desc_translation clob, position NUMBER, relevance FLOAT)';
EXCEPTION
    WHEN e_already_exists THEN
        NULL;
END;
/
-- CHANGE END: Pedro Pinheiro

DECLARE
l_sql varchar2(1000 char);
BEGIN
l_sql := 'drop type t_search_lob';
pk_versioning.run(l_sql);
end;
/
