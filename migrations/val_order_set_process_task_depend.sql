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
        l_odst_tasks table_varchar;
    BEGIN
        /* Initializations */
    
        /* Data validation */
    
        SELECT 'ID_RELATIONSHIP_TYPE = ' || odst_proc_task_dep.id_relationship_type ||
               ' ID_ORDER_SET_PROC_TASK_FROM = ' || odst_proc_task_dep.id_order_set_proc_task_from ||
               ' ID_ORDER_SET_PROC_TASK_TO = ' || odst_proc_task_dep.id_order_set_proc_task_to BULK COLLECT
          INTO l_odst_tasks
          FROM order_set_process_task_depend odst_proc_task_dep
         WHERE odst_proc_task_dep.id_order_set_process IS NULL
            OR odst_proc_task_dep.id_order_set_process !=
               (SELECT b.id_order_set_process
                  FROM order_set_process_task b
                 WHERE b.id_order_set_process_task = odst_proc_task_dep.id_order_set_proc_task_to);
    
        IF l_odst_tasks.exists(1)
           AND l_odst_tasks.count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        WHEN e_has_findings THEN
            FOR i IN l_odst_tasks.first .. l_odst_tasks.last
            LOOP
            
                log_error('VAL_ORDER_SET_PROCESS_TASK_DEPEND - BAD VALUE: ' || l_odst_tasks(i));
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
