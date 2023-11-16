-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 02/03/2012
-- CHANGE REASON: [ALERT-220948]
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
        l_task_details table_varchar;
    BEGIN
    
        /* Data validation */
        SELECT 'ID_ORDER_SET_TASK_DETAIL = ' || ostd.id_order_set_task_detail || '
  ID_ORDER_SET_TASK = ' || ostd.id_order_set_task || ' 
  FLG_DETAIL_TYPE = ' || ostd.flg_detail_type || '
  VVALUE = ' || ostd.vvalue BULK COLLECT
          INTO l_task_details
          FROM order_set_task_detail ostd
         WHERE ostd.flg_detail_type = 'G'
           AND length(vvalue) > 1;
    
        IF l_task_details.exists(1)
           AND l_task_details.count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        WHEN e_has_findings THEN
            FOR i IN l_task_details.first .. l_task_details.last
            LOOP
            
                log_error('BAD VALUE: ' || l_task_details(i));
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
-- CHANGE END: Tiago Silva
