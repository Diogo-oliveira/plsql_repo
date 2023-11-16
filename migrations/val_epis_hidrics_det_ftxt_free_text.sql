-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 15/06/2011 
-- CHANGE REASON: [ALERT-185057] : Intake and Output: It is not possible to use a created free text in more than one line

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
        l_count_way      PLS_INTEGER := 0;
        l_count_hidrics  PLS_INTEGER := 0;
        l_count_location PLS_INTEGER := 0;
        l_count_device   PLS_INTEGER := 0;
        l_count_chars    PLS_INTEGER := 0;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        SELECT COUNT(1)
          INTO l_count_way
          FROM epis_hidrics_line ehl
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_line = ehl.id_epis_hidrics_line
          JOIN way hw
            ON hw.id_way = ehdf.id_way
           AND ehdf.id_way IS NOT NULL
           AND hw.flg_way_type = 'O'
           AND ehl.id_epis_hid_ftxt_way IS NULL
           AND ehdf.free_text IS NOT NULL;
    
        SELECT COUNT(1)
          INTO l_count_hidrics
          FROM epis_hidrics_line ehl
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_line = ehl.id_epis_hidrics_line
          JOIN hidrics hd
            ON hd.id_hidrics = ehl.id_hidrics
           AND ehdf.id_hidrics IS NOT NULL
           AND hd.flg_free_txt = 'Y'
           AND ehl.id_epis_hid_ftxt_fluid IS NULL
           AND ehdf.free_text IS NOT NULL;
    
        SELECT COUNT(1)
          INTO l_count_location
          FROM epis_hidrics_line ehl
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_line = ehl.id_epis_hidrics_line
          JOIN hidrics_location hl
            ON hl.id_hidrics_location = ehl.id_hidrics_location
           AND ehdf.id_hidrics_location IS NOT NULL
           AND hl.id_body_part IS NULL
           AND ehl.id_epis_hid_ftxt_loc IS NULL
           AND ehdf.free_text IS NOT NULL;
    
        SELECT COUNT(1)
          INTO l_count_device
          FROM epis_hidrics_det ehd
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_det = ehd.id_epis_hidrics_det
          JOIN hidrics_device hd
            ON hd.id_hidrics_device = ehd.id_hidrics_device
         WHERE ehdf.id_hidrics_device IS NOT NULL
           AND hd.flg_free_txt = 'Y'
           AND ehd.id_epis_hid_ftxt_dev IS NULL
           AND ehdf.free_text IS NOT NULL;
    
        SELECT COUNT(1)
          INTO l_count_chars
          FROM epis_hidrics_det_charact ehdc
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_det = ehdc.id_epis_hidrics_det
           AND ehdf.id_hidrics_charact = ehdc.id_hidrics_charact
         WHERE ehdf.id_hidrics_charact IS NOT NULL
           AND ehdc.id_hidrics_charact = 0
           AND ehdc.id_epis_hid_ftxt_char IS NULL
           AND ehdf.free_text IS NOT NULL;
    
        IF l_count_way > 0
          /* OR l_count_hidrics > 0           
           OR l_count_device > 0
           OR l_count_chars > 0*/
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('ORA-200001: ERROR - DATA MIGRATION epis_hidrics_det_ftxt: Nr of not migrated free text ways: ' ||
                      l_count_way || ' fluids: ' || l_count_hidrics || ' body_parts: ' || l_count_location ||
                      ' devices: ' || l_count_device || ' characteristics: ' || l_count_chars);
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

-- CHANGE END: Sofia Mendes


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 15/06/2011 
-- CHANGE REASON: [ALERT-185057] : Intake and Output: It is not possible to use a created free text in more than one line

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
        l_count_way      PLS_INTEGER := 0;
        l_count_hidrics  PLS_INTEGER := 0;
        l_count_location PLS_INTEGER := 0;
        l_count_device   PLS_INTEGER := 0;
        l_count_chars    PLS_INTEGER := 0;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        SELECT COUNT(1)
          INTO l_count_way
          FROM epis_hidrics_line ehl
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_line = ehl.id_epis_hidrics_line
          JOIN way hw
            ON hw.id_way = ehdf.id_way
           AND ehdf.id_way IS NOT NULL
           AND hw.flg_way_type = 'O'
           AND ehl.id_epis_hid_ftxt_way IS NULL
           AND ehdf.free_text IS NOT NULL;
    
        SELECT COUNT(1)
          INTO l_count_hidrics
          FROM epis_hidrics_line ehl
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_line = ehl.id_epis_hidrics_line
          JOIN hidrics hd
            ON hd.id_hidrics = ehl.id_hidrics
           AND ehdf.id_hidrics IS NOT NULL
           AND hd.flg_free_txt = 'Y'
           AND ehl.id_epis_hid_ftxt_fluid IS NULL
           AND ehdf.free_text IS NOT NULL;
    
        SELECT COUNT(1)
          INTO l_count_location
          FROM epis_hidrics_line ehl
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_line = ehl.id_epis_hidrics_line
          JOIN hidrics_location hl
            ON hl.id_hidrics_location = ehl.id_hidrics_location
           AND ehdf.id_hidrics_location IS NOT NULL
           AND hl.id_body_part IS NULL
           AND ehl.id_epis_hid_ftxt_loc IS NULL
           AND ehdf.free_text IS NOT NULL;
    
        SELECT COUNT(1)
          INTO l_count_device
          FROM epis_hidrics_det ehd
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_det = ehd.id_epis_hidrics_det
          JOIN hidrics_device hd
            ON hd.id_hidrics_device = ehd.id_hidrics_device
         WHERE ehdf.id_hidrics_device IS NOT NULL
           AND hd.flg_free_txt = 'Y'
           AND ehd.id_epis_hid_ftxt_dev IS NULL
           AND ehdf.free_text IS NOT NULL;
    
        SELECT COUNT(1)
          INTO l_count_chars
          FROM epis_hidrics_det_charact ehdc
          JOIN epis_hidrics_det_ftxt ehdf
            ON ehdf.id_epis_hidrics_det = ehdc.id_epis_hidrics_det
           AND ehdf.id_hidrics_charact = ehdc.id_hidrics_charact
         WHERE ehdf.id_hidrics_charact IS NOT NULL
           AND ehdc.id_hidrics_charact = 0
           AND ehdc.id_epis_hid_ftxt_char IS NULL
           AND ehdf.free_text IS NOT NULL;
    
        IF l_count_way > 0
           OR l_count_hidrics > 0           
           OR l_count_device > 0
           OR l_count_location > 0
           OR l_count_chars > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('ORA-200001: ERROR - DATA MIGRATION epis_hidrics_det_ftxt: Nr of not migrated free text ways: ' ||
                      l_count_way || ' fluids: ' || l_count_hidrics || ' body_parts: ' || l_count_location ||
                      ' devices: ' || l_count_device || ' characteristics: ' || l_count_chars);
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

-- CHANGE END: Sofia Mendes
