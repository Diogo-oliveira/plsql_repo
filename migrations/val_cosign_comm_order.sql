-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 22/04/2015 09:11
-- CHANGE REASON: [ALERT-310275] 
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
        l_comm_orders_not_migrated table_varchar;
    BEGIN
    
        /* Data validation */
        SELECT 'ID_COMM_ORDER_REQ = ' || cor.id_comm_order_req BULK COLLECT
          INTO l_comm_orders_not_migrated
          FROM comm_order_req cor
         WHERE cor.id_order_type IS NOT NULL
           AND NOT EXISTS
         (SELECT *
                  FROM co_sign cs
                 WHERE cs.id_task_group = cor.id_comm_order_req
                   AND cs.id_task = (SELECT DISTINCT first_value(corh.id_comm_order_req_hist) over(ORDER BY corh.dt_status)
                                       FROM comm_order_req_hist corh
                                      WHERE corh.id_comm_order_req = cor.id_comm_order_req)
                   AND cs.id_task_type = pk_alert_constant.g_task_comm_orders);
    
        IF l_comm_orders_not_migrated.exists(1)
           AND l_comm_orders_not_migrated.count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        WHEN e_has_findings THEN
            FOR i IN l_comm_orders_not_migrated.first .. l_comm_orders_not_migrated.last
            LOOP
            
                log_error('BAD VALUE: ' || l_comm_orders_not_migrated(i));
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
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 24/04/2015 17:59
-- CHANGE REASON: [ALERT-310275] 
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
        l_comm_orders_not_migrated table_varchar;
    BEGIN
    
        /* Data validation */
        SELECT 'ID_COMM_ORDER_REQ = ' || cor.id_comm_order_req BULK COLLECT
          INTO l_comm_orders_not_migrated
          FROM comm_order_req cor
         WHERE cor.id_order_type IS NOT NULL
   AND cor.id_episode IS NOT NULL
           AND NOT EXISTS
         (SELECT *
                  FROM co_sign cs
                 WHERE cs.id_task_group = cor.id_comm_order_req
                   AND cs.id_task = (SELECT DISTINCT first_value(corh.id_comm_order_req_hist) over(ORDER BY corh.dt_status)
                                       FROM comm_order_req_hist corh
                                      WHERE corh.id_comm_order_req = cor.id_comm_order_req)
                   AND cs.id_task_type = pk_alert_constant.g_task_comm_orders);
    
        IF l_comm_orders_not_migrated.exists(1)
           AND l_comm_orders_not_migrated.count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        WHEN e_has_findings THEN
            FOR i IN l_comm_orders_not_migrated.first .. l_comm_orders_not_migrated.last
            LOOP
            
                log_error('BAD VALUE: ' || l_comm_orders_not_migrated(i));
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
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 11/05/2015
-- CHANGE REASON: [ALERT-310275] 
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
        l_comm_orders_not_migrated table_varchar;
    BEGIN
    
        /* Data validation */
        SELECT 'ID_COMM_ORDER_REQ = ' || cor.id_comm_order_req BULK COLLECT
          INTO l_comm_orders_not_migrated
          FROM comm_order_req cor
         WHERE cor.id_order_type IS NOT NULL
           AND cor.id_episode IS NOT NULL
           AND NOT EXISTS
         (SELECT *
                  FROM co_sign cs
                 WHERE cs.id_task_group = cor.id_comm_order_req
                   AND cs.id_task =
                       (SELECT DISTINCT first_value(t.id_h) over(PARTITION BY(t.id_comm_order_req) ORDER BY decode(t.flg_action, 'ORDER', 0, 1), t.dt_status ASC) id_task
                          FROM (SELECT corh2.flg_action,
                                       cor2.id_comm_order_req,
                                       (CASE
                                            WHEN (corh2.id_order_type = cor2.id_order_type AND
                                                 corh2.id_prof_order = cor2.id_prof_order AND
                                                 corh2.dt_order = cor2.dt_order) -- co-sign excepto id_order_type in (7,9)
                                                 OR (corh2.id_order_type = cor2.id_order_type AND
                                                 cor2.id_order_type IN (7, 9) AND corh2.id_prof_order IS NULL AND
                                                 cor2.id_prof_order IS NULL AND corh2.dt_order = cor2.dt_order) -- id_prof=null e id_order_type in (7,9)
                                                 OR (corh2.id_order_type = cor2.id_order_type AND
                                                 corh2.id_prof_order IS NULL AND corh2.dt_order IS NULL) -- bug existente nos drafts
                                             THEN
                                             corh2.id_comm_order_req_hist
                                            ELSE
                                             0
                                        END) id_h,
                                       corh2.dt_status
                                  FROM alert.comm_order_req cor2
                                  JOIN alert.comm_order_req_hist corh2
                                    ON cor2.id_comm_order_req = corh2.id_comm_order_req
                                 WHERE cor2.id_order_type IS NOT NULL
                                   AND corh2.flg_action IN ('ORDER', 'EDITION', 'DRAFT')) t
                         WHERE t.id_h != 0
                           AND t.id_comm_order_req = cor.id_comm_order_req)
                   AND cs.id_task_type = pk_alert_constant.g_task_comm_orders);
    
        IF l_comm_orders_not_migrated.exists(1)
           AND l_comm_orders_not_migrated.count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        WHEN e_has_findings THEN
            FOR i IN l_comm_orders_not_migrated.first .. l_comm_orders_not_migrated.last
            LOOP
            
                log_error('BAD VALUE: ' || l_comm_orders_not_migrated(i));
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