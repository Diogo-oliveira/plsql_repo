-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 29/01/2013
-- CHANGE REASON: []
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
        l_not_predef_tasks table_varchar;
    BEGIN
    
        /* Data validation */
        SELECT 'ID_ORDER_SET = ' || os.id_order_set || ' ID_ORDER_SET_TASK = ' || ost.id_order_set_task BULK COLLECT
          INTO l_not_predef_tasks
          FROM order_set os
         INNER JOIN order_set_task ost
            ON os.id_order_set = ost.id_order_set
         WHERE os.flg_status IN ('F', 'C') -- final version or cancelled
           AND ost.id_task_type IN (7, 8, 11) -- lab test, image and other exam type
           AND EXISTS (SELECT 1
                  FROM order_set_task_link ostl
                 WHERE ostl.id_order_set_task = ost.id_order_set_task
                   AND ostl.flg_task_link_type != pk_order_sets.g_task_link_predefined)
         ORDER BY os.id_order_set;
    
        IF l_not_predef_tasks.exists(1)
           AND l_not_predef_tasks.count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        WHEN e_has_findings THEN
            FOR i IN l_not_predef_tasks.first .. l_not_predef_tasks.last
            LOOP
            
                log_error('BAD VALUE: ' || l_not_predef_tasks(i));
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
