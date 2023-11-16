-- CHANGED BY: José Silva
-- CHANGE DATE: 27/08/2010 00:48
-- CHANGE REASON: [ALERT-120163] Administrative discharge cancellation
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
        e_has_findings2 EXCEPTION;
        e_has_findings3 EXCEPTION;
        e_has_findings4 EXCEPTION;
        l_aux_count pls_integer;
    BEGIN
        /* Initializations */
    
        /* Data validation 1*/
        SELECT count(*)
          into l_aux_count
          FROM discharge d
 WHERE d.flg_status_adm = 'A'
   AND (d.dt_admin_tstz IS NULL OR flg_status <> 'A');
    
        IF l_aux_count != 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;

        /* Data validation 2*/
        SELECT count(*)
          into l_aux_count
          FROM discharge d
 WHERE d.flg_status_adm = 'C'
   AND (d.dt_admin_tstz IS NULL OR flg_status <> 'C');
    
        IF l_aux_count != 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings2;
        END IF;

        /* Data validation 3*/
        SELECT count(*)
          into l_aux_count
          FROM discharge_hist d
 WHERE d.flg_status_adm = 'A'
   AND (d.dt_admin_tstz IS NULL OR flg_status <> 'A');
    
        IF l_aux_count != 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings3;
        END IF;

        /* Data validation 4*/
        SELECT count(*)
          into l_aux_count
          FROM discharge_hist d
 WHERE d.flg_status_adm = 'C'
   AND (d.dt_admin_tstz IS NULL OR flg_status <> 'C');
    
        IF l_aux_count != 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings4;
        END IF;

    
    EXCEPTION
        WHEN e_has_findings THEN
log_error('DISCHARGE TABLE: FLG_STATUS_ADM COLUMN HAS INVALID VALUES (A)!!');
            /* in the end call announce_error to warn the installation script */
            announce_error;
        WHEN e_has_findings2 THEN
log_error('DISCHARGE TABLE: FLG_STATUS_ADM COLUMN HAS INVALID VALUES (C)!!');
            /* in the end call announce_error to warn the installation script */
            announce_error;
        WHEN e_has_findings3 THEN
log_error('DISCHARGE_HIST TABLE: FLG_STATUS_ADM COLUMN HAS INVALID VALUES (A)!!');
            /* in the end call announce_error to warn the installation script */
            announce_error;
        WHEN e_has_findings4 THEN
log_error('DISCHARGE_HIST TABLE: FLG_STATUS_ADM COLUMN HAS INVALID VALUES (C)!!');
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
-- CHANGE END: José Silva