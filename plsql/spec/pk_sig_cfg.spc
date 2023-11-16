CREATE OR REPLACE PACKAGE pk_sig_cfg IS

    --*******************************************************
    PROCEDURE ins_prof_sig
    (
        i_row IN prof_signature%ROWTYPE,
        o_id  OUT NUMBER
    );

    --*******************************************************
    --PROCEDURE ins_active_prof_sig(i_row IN prof_signature%ROWTYPE);

    PROCEDURE del_active_sig(i_id_prof IN NUMBER);

    PROCEDURE ins_active_sig
    (
        i_id_prof IN NUMBER,
        i_id_sig  IN NUMBER
    );

    --*******************************************************
    PROCEDURE ins_prof_sig_h
    (
        i_mode IN VARCHAR2,
        i_row  IN prof_signature%ROWTYPE
    );

    PROCEDURE del_prof_signature(i_row IN prof_signature%ROWTYPE);

    PROCEDURE upd_prof_sig(i_row IN prof_signature%ROWTYPE);

    PROCEDURE set_history
    (
        i_cud IN VARCHAR2,
        i_row IN prof_signature%ROWTYPE
    );

    PROCEDURE cancel_signature(i_sig IN NUMBER);

END pk_sig_cfg;
