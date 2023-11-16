BEGIN
    EXECUTE IMMEDIATE 'create or replace type t_rec_pat_education_rec as object(
        icon                 VARCHAR2(200),
        unique_id            NUMBER(24),
        id_intervention      NUMBER(24),
        description          VARCHAR2(4000),
        id_mcdt_codification NUMBER(24),
        id_codification      NUMBER(24),
        codification         VARCHAR2(4000),
        id_exec_institution  NUMBER(24),
        exec_institution     VARCHAR2(4000),
        flg_type             VARCHAR2(2),
        flg_timeout          VARCHAR2(2),
        flg_referral         VARCHAR2(2),
        flg_assoc_drug       VARCHAR2(2),
        title_notes          VARCHAR2(4000),
        notes_tooltip        VARCHAR2(4000),
        instructions         VARCHAR2(4000),
        flg_status           VARCHAR2(2),
        desc_status          VARCHAR2(200),
        avail_butt_ok        VARCHAR2(2),
        avail_butt_cancel    VARCHAR2(2),
        prof_order           VARCHAR2(200),
        desc_diagnosis       VARCHAR2(4000),
        status_string        VARCHAR2(4000),
        dt_ord1              VARCHAR2(50),
        id_prof_req          NUMBER(24),
        dt_ord_tstz          TIMESTAMP WITH LOCAL TIME ZONE,
        dt_last_update       TIMESTAMP WITH LOCAL TIME ZONE)';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/