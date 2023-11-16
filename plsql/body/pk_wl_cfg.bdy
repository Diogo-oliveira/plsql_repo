CREATE OR REPLACE PACKAGE BODY pk_wl_cfg IS

    --g_owner   VARCHAR2(0200 CHAR) := 'ALERT';
    --g_package VARCHAR2(0200 CHAR) := 'PK_WL_CFG';

    --***********************************
    PROCEDURE del_one_adm_machine_alloc
    (
        i_id_wl_machine IN NUMBER,
        i_id_wl_queue   IN NUMBER
    ) IS
    BEGIN
    
        DELETE wl_q_machine
         WHERE id_wl_machine = i_id_wl_machine
           AND id_wl_queue = i_id_wl_queue;
    
    END del_one_adm_machine_alloc;

    --************************************
    PROCEDURE del_all_adm_machine_alloc(i_id_wl_machine IN NUMBER) IS
    
        tbl_queues table_number;
    
        --*********************************************
        PROCEDURE get_all_queues(i_id_wl_machine IN NUMBER) IS
        BEGIN
        
            SELECT qm.id_wl_queue
              BULK COLLECT
              INTO tbl_queues
              FROM wl_q_machine qm
             WHERE qm.id_wl_machine = i_id_wl_machine;
        
        END get_all_queues;
    
    BEGIN
    
        get_all_queues(i_id_wl_machine);
    
        <<lup_thru_allocated_queues>>
        FOR i IN 1 .. tbl_queues.count
        LOOP
        
            del_one_adm_machine_alloc(i_id_wl_machine => i_id_wl_machine, i_id_wl_queue => tbl_queues(i));
        
        END LOOP lup_thru_allocated_queues;
    
    END del_all_adm_machine_alloc;

    --************************************************************
    PROCEDURE upd_adm_machine_alloc
    (
        i_id_wl_machine IN NUMBER,
        i_id_wl_queue   IN NUMBER,
        i_new_rank      IN NUMBER
    ) IS
    BEGIN
    
        UPDATE wl_q_machine
           SET order_rank = i_new_rank
         WHERE id_wl_machine = i_id_wl_machine
           AND id_wl_queue = i_id_wl_queue;
    
    END upd_adm_machine_alloc;

    --**********************************************************
    PROCEDURE ins_adm_machine_alloc
    (
        i_id_wl_machine IN NUMBER,
        i_id_wl_queue   IN NUMBER,
        i_order_rank    IN NUMBER
    ) IS
    BEGIN
    
        INSERT INTO wl_q_machine
            (id_wl_machine, id_wl_queue, order_rank)
        VALUES
            (i_id_wl_machine, i_id_wl_queue, i_order_rank);
    
    END ins_adm_machine_alloc;

    --***********************************************************
    PROCEDURE ins_all_adm_machine_alloc
    (
        i_id_wl_machine IN NUMBER,
        i_tbl_queue     IN table_number,
        i_tbl_rank      IN table_number
    ) IS
    BEGIN
    
        <<lup_thru_new_queues>>
        FOR i IN 1 .. i_tbl_queue.count
        LOOP
        
            ins_adm_machine_alloc(i_id_wl_machine => i_id_wl_machine,
                                  i_id_wl_queue   => i_tbl_queue(i),
                                  i_order_rank    => i_tbl_rank(i));
        
        END LOOP lup_thru_new_queues;
    
    END ins_all_adm_machine_alloc;

END pk_wl_cfg;
