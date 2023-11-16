-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 19/12/2011 14:55
-- CHANGE REASON: [ALERT-207801] Reusability of documentation components in Touch-option templates
DECLARE
    /* Leave as is */
    PROCEDURE log_error(i_text IN VARCHAR2) IS
    BEGIN
        pk_alertlog.log_error(text => i_text, object_name => 'MIGRATION');
    END log_error;

    /* Leave as is */
    PROCEDURE announce_error IS
    BEGIN
        dbms_output.put_line('Error on data migration. Please look into alertlog.tlog table in ''MIGRATION'' section. Example:
select *
  from alertlog.tlog
 where lsection = ''MIGRATION''
 order by 2 desc, 3 desc, 1 desc;');
    END announce_error;

    /* Leave as is */
    FUNCTION should_execute RETURN BOOLEAN IS
    BEGIN
        RETURN &exec_val = 1;
    END should_execute;

    PROCEDURE do_my_validation IS
        /* Declarations */
        e_has_findings EXCEPTION;
        l_missing_dta_templates table_varchar;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT 'ID_DOC_TEMPLATE = ' || t.id_doc_template || ' ID_DOC_AREA = ' || t.id_doc_area BULK COLLECT
          INTO l_missing_dta_templates
          FROM (SELECT DISTINCT id_doc_template, id_doc_area
                  FROM documentation
                 WHERE id_doc_template IS NOT NULL
                   AND id_doc_area IS NOT NULL
                MINUS
                SELECT dta.id_doc_template, dta.id_doc_area
                  FROM doc_template_area dta) t;
    
        IF l_missing_dta_templates.exists(1)
           AND l_missing_dta_templates.count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        WHEN e_has_findings THEN
            log_error('Missing rows in the table DOC_TEMPLATE_AREA:');
            FOR i IN l_missing_dta_templates.first .. l_missing_dta_templates.last
            LOOP
            
                log_error('MISSING ENTRY: ' || l_missing_dta_templates(i));
            END LOOP;
            /* in the end call announce_error to warn the installation script */
            announce_error;
    END do_my_validation;

BEGIN
    /* Leave as is */
    IF should_execute
    THEN
        do_my_validation;
    END IF;

EXCEPTION
    /* Leave as is */
    WHEN OTHERS THEN
        log_error('UNEXPECTED ERROR: ' || SQLERRM);
        announce_error;
END;
/
-- CHANGE END: Ariel Machado