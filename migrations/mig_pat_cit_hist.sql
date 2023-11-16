-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 07/12/2011 09:10
-- CHANGE REASON: [ALERT-208654] 
DECLARE e_expt EXCEPTION;
PRAGMA EXCEPTION_INIT(e_expt, -00904);
BEGIN
    EXECUTE IMMEDIATE 'UPDATE pat_cit_hist SET beneficiary_number = beneficiary_num';
EXCEPTION
    WHEN e_expt THEN
        dbms_output.put_line('already executed');
END;
/
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 07/12/2011 09:48
-- CHANGE REASON: [ALERT-208654] 
DECLARE
    e_expt EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_expt, -00904);
    e_expt1 EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_expt1, -01430);
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE pat_cit_hist add beneficiary_number VARCHAR2(200 CHAR)';
    EXCEPTION
        WHEN e_expt1 THEN
            dbms_output.put_line('already executed');
    END;

    EXECUTE IMMEDIATE 'COMMENT ON column pat_cit_hist.beneficiary_number IS ''Nº de identificação da Função Pública/Segurança Social''';

    BEGIN
        EXECUTE IMMEDIATE 'UPDATE pat_cit_hist SET beneficiary_number = beneficiary_num';
    EXCEPTION
        WHEN e_expt THEN
            dbms_output.put_line('already executed');
    END;

    BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE pat_cit_hist drop column beneficiary_num';
    EXCEPTION
        WHEN e_expt THEN
            dbms_output.put_line('already executed');
    END;
END;
/
-- CHANGE END: Paulo Teixeira