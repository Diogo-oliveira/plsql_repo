CREATE OR REPLACE PACKAGE pk_wl_cfg IS

    --***********************************
    PROCEDURE del_one_adm_machine_alloc
    (
        i_id_wl_machine IN NUMBER,
        i_id_wl_queue   IN NUMBER
    );

    --************************************
    PROCEDURE del_all_adm_machine_alloc(i_id_wl_machine IN NUMBER);

    --************************************************************
    PROCEDURE upd_adm_machine_alloc
    (
        i_id_wl_machine IN NUMBER,
        i_id_wl_queue   IN NUMBER,
        i_new_rank      IN NUMBER
    );

    --**********************************************************
    PROCEDURE ins_adm_machine_alloc
    (
        i_id_wl_machine IN NUMBER,
        i_id_wl_queue   IN NUMBER,
        i_order_rank    IN NUMBER
    );

END pk_wl_cfg;
