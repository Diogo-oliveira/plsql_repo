DECLARE
    l_type VARCHAR2(4000) := 'CREATE OR REPLACE TYPE t_todo_list_rec AS OBJECT
    (
        id_patient          NUMBER(24),
        id_episode          NUMBER(24),
        id_external_request NUMBER(24),
        id_schedule         NUMBER(24),
        gender              VARCHAR2(1 CHAR),
        age                 VARCHAR2(6 CHAR),
        photo               VARCHAR2(4000),
        name                VARCHAR2(1000),
        name_pat_sort       VARCHAR2(1000),
        pat_ndo             VARCHAR2(1000 CHAR),
        pat_nd_icon         VARCHAR2(10 CHAR),
        dt_begin            VARCHAR2(100 CHAR),
        dt_begin_extend     VARCHAR2(200 CHAR),
        description         VARCHAR2(4000 CHAR),
        flg_type            VARCHAR2(1 CHAR),
        flg_task            VARCHAR2(2 CHAR),
        task_icon           VARCHAR2(30 CHAR),
        icon_type           VARCHAR2(1 CHAR),
        task_count          NUMBER(24),
        task                VARCHAR2(200 CHAR),
        shortcut            NUMBER(24),
        flg_status          VARCHAR2(2 CHAR),
        dt_co_sign          VARCHAR2(30 CHAR),
        dt_server           VARCHAR2(4000 CHAR),
        resp_icons          table_varchar,
        url_ges_ext_app     VARCHAR2(1000 CHAR),
        prof_name           VARCHAR2(100 CHAR),
        note_name           VARCHAR2(100 CHAR),
        time_to_sort        NUMBER(20, 10)
    )';
BEGIN
    pk_versioning.run('DROP TYPE t_todo_list_tbl');
    pk_versioning.run(l_type);
    pk_versioning.run('CREATE OR REPLACE TYPE t_todo_list_tbl AS table of t_todo_list_rec');
END;
/
