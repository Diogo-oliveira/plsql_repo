-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 17/12/2014 08:20
-- CHANGE REASON: [ALERT-304679] 
DECLARE
    CURSOR c_cur IS
        SELECT t.id_comm_order_req, t.flg_action
          FROM (SELECT row_number() over(PARTITION BY id_comm_order_req ORDER BY dt_status DESC) AS rn,
                       h.id_comm_order_req,
                       h.flg_action
                  FROM comm_order_req_hist h) t
         WHERE rn = 1;

    TYPE t_cur_tab IS TABLE OF c_cur%ROWTYPE;
    l_cur_tab t_cur_tab;

    l_limit  PLS_INTEGER := 1000;
    l_error  VARCHAR2(1000 CHAR);
    l_errors PLS_INTEGER;
    e_dml_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_dml_errors, -24381);
BEGIN
    l_error := 'OPEN c_cur';
    OPEN c_cur;
    LOOP
    
        l_error := 'FETCH c_cur BULK COLLECT';
        FETCH c_cur BULK COLLECT
            INTO l_cur_tab LIMIT l_limit;
    
        l_error := 'FORALL i IN 1 .. l_cur_tab.count';
        FORALL i IN 1 .. l_cur_tab.count
            UPDATE comm_order_req
               SET flg_action = l_cur_tab(i).flg_action
             WHERE id_comm_order_req = l_cur_tab(i).id_comm_order_req
               AND flg_action IS NULL;
    
        l_error := 'COMMIT';
        COMMIT;
    
        l_error := 'EXIT WHEN l_cur_tab.count < l_limit';
        EXIT WHEN l_cur_tab.count < l_limit;
    
    END LOOP;
    CLOSE c_cur;

EXCEPTION
    WHEN e_dml_errors THEN
        l_errors := SQL%bulk_exceptions.count;
        dbms_output.put_line('Number of UPDATE statements that failed: ' || l_errors);
    
        FOR i IN 1 .. l_errors
        LOOP
            dbms_output.put_line('Error #' || i || ' at ' || 'iteration #' || SQL%BULK_EXCEPTIONS(i).error_index);
            dbms_output.put_line('id_external_request=' || l_cur_tab(SQL%BULK_EXCEPTIONS(i).error_index)
                                 .id_comm_order_req);
            dbms_output.put_line('Error message is ' || SQLERRM(-sql%BULK_EXCEPTIONS(i).error_code));
        END LOOP;
    WHEN OTHERS THEN
        ROLLBACK;
        dbms_output.put_line(SQLERRM);
END;
/
-- CHANGE END: Ana Monteiro