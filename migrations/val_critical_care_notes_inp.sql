-- CHANGED BY: ANTONIO.NETO
-- CHANGE DATE: 20/Mar/2012 
-- CHANGE REASON: [ALERT-166586] EDIS restructuring - Present Illness / Current visit

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

    /* Edit this function */
    PROCEDURE do_my_validation IS
        /* Declarations */
        /* example: */
        e_has_findings EXCEPTION;
        l_count  PLS_INTEGER;
				
				l_id_doc_area epis_documentation.id_doc_area%TYPE := 6746;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
				begin
        SELECT nvl(count(1), 0)
				into l_count
          FROM epis_documentation ed
         INNER JOIN episode e
            ON ed.id_episode = e.id_episode
           AND e.id_epis_type = 5
         INNER JOIN institution i
            ON e.id_institution = i.id_institution
         INNER JOIN institution_language il
            ON i.id_institution = il.id_institution
          LEFT OUTER JOIN epis_pn_det_task epdt
            ON ed.id_epis_documentation = epdt.id_task
           AND epdt.id_task_type = 36
          LEFT OUTER JOIN epis_pn_det epd
            ON epdt.id_epis_pn_det = epd.id_epis_pn_det
           AND epd.id_pn_data_block = 83
           AND epd.id_pn_soap_block = 16
          LEFT OUTER JOIN epis_pn epn
            ON epd.id_epis_pn = epn.id_epis_pn
						and epn.id_pn_note_type = 5
         WHERE ed.id_doc_area = l_id_doc_area
           AND i.id_market <> 2
           AND ed.flg_status = 'A'
					 and epn.id_epis_pn is null;
				
				exception
				   when no_data_found then
					      l_count := 0;
        end;
		
        IF l_count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of critical care notes not migrated ' || l_count);
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

-- CHANGE END: ANTONIO.NETO