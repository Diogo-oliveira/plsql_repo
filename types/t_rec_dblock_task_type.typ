-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 19/08/2011
-- CHANGE REASON: [ALERT-259146 ] Triage single page
BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t_coll_dblock_task_type';

    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_dblock_task_type AS OBJECT (
        id_pn_data_block             NUMBER(24),
        id_pn_soap_block             NUMBER(24),
        id_pn_note_type              NUMBER(24),
        id_task_type                 NUMBER(24),
        id_department                 NUMBER(24),
        id_dep_clin_serv             NUMBER(24),
        flg_auto_populated           VARCHAR2(200 CHAR),
        task_type_id_parent          NUMBER(24),
        flg_synch_area               VARCHAR2(1 CHAR),
        review_context               VARCHAR2(24 CHAR),
        flg_selected                 VARCHAR2(24 CHAR),
        flg_import_filter            VARCHAR2(200 CHAR),
        flg_ea                       varchar2(1 char),
        last_n_records_nr            number(24),
        flg_shortcut_filter          VARCHAR2(200 char),
        flg_synchronized             VARCHAR2(200 char),
        review_cat               VARCHAR2(200 CHAR),
        flg_review_avail             VARCHAR2(1CHAR),
        flg_description              VARCHAR2(24 CHAR),
        description_condition        VARCHAR2(1000 CHAR),
        flg_dt_task                  VARCHAR2(200 CHAR)
        )';

    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_coll_dblock_task_type AS table of t_rec_dblock_task_type';
end;
/
--CHANGE END: Sofia Mendes
