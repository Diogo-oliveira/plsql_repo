-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 17/12/2014 08:20
-- CHANGE REASON: [ALERT-304679] 
DECLARE
    CURSOR c_cur IS
        SELECT t.id_comm_order_req_hist,
               CASE
                    WHEN t.id_status_prev = t.id_status_actual THEN
                     decode((SELECT COUNT(1)
                              FROM comm_order_req_ack cora
                             WHERE cora.id_comm_order_req_hist = t.id_comm_order_req_hist),
                            0,
                            'EDITION',
                            'ACK')
                    WHEN t.id_status_actual = 500 THEN -- there was a status change
                     'ORDER'
                    WHEN t.id_status_actual = 505 THEN
                     'EXPIRED'
                    WHEN t.id_status_actual = 501 THEN
                     'DISCONTINUED'
                    WHEN t.id_status_actual = 502 THEN
                     'CANCELED'
                    WHEN t.id_status_actual = 503 THEN
                     'DRAFT'
                    WHEN t.id_status_actual = 504 THEN
                     'PREDEFINED'
                    ELSE
                     NULL
                END flg_action
          FROM (SELECT lag(id_status, 1) over(PARTITION BY id_comm_order_req ORDER BY dt_status) AS id_status_prev,
                       id_status AS id_status_actual,
                       h.id_comm_order_req_hist,
                       h.id_comm_order_req,
                       h.dt_status
                  FROM comm_order_req_hist h
                 WHERE flg_action IS NULL) t;

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
            UPDATE comm_order_req_hist
               SET flg_action = l_cur_tab(i).flg_action
             WHERE id_comm_order_req_hist = l_cur_tab(i).id_comm_order_req_hist;
    
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
                                 .id_comm_order_req_hist);
            dbms_output.put_line('Error message is ' || SQLERRM(-sql%BULK_EXCEPTIONS(i).error_code));
        END LOOP;
    WHEN OTHERS THEN
        ROLLBACK;
        dbms_output.put_line(SQLERRM);
END;
/
-- CHANGE END: Ana Monteiro