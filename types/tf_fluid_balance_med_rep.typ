-- CHANGED BY: Luís Maia
-- CHANGE DATE: 23/11/2011 19:10
-- CHANGE REASON: [ALERT-206340] Versioning packages CLINICAL_DOCUMENTATION
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE tf_fluid_balance_med_rep IS TABLE OF tr_fluid_balance_med_rep';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Type não existente tr_fluid_balance_med_rep');
END;
/
