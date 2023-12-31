CREATE OR REPLACE TYPE t_rec_episactiveitech force AS OBJECT
(
    rank               NUMBER,
    acuity             VARCHAR2(240 CHAR),
    rank_acuity        NUMBER,
    epis_type          VARCHAR2(1000 CHAR),
    desc_institution   VARCHAR2(1000 CHAR),
    dt_first_obs       VARCHAR2(1000 CHAR),
    desc_patient       VARCHAR2(800 CHAR),
    pat_ndo            VARCHAR2(1000 CHAR),
    pat_nd_icon        VARCHAR2(30 CHAR),
    id_patient         NUMBER(24),
    gender             VARCHAR2(200 CHAR),
    pat_age            VARCHAR2(50 CHAR),
    photo              VARCHAR2(1000 CHAR),
    num_clin_record    VARCHAR2(100 CHAR),
    id_episode         NUMBER(24),
    dt_server          VARCHAR2(1000 CHAR),
    dt_target          VARCHAR2(1000 CHAR),
    desc_exam          VARCHAR2(1000 CHAR),
    col_request        VARCHAR2(1000 CHAR),
    col_transport      VARCHAR2(1000 CHAR),
    col_execute        VARCHAR2(1000 CHAR),
    col_complete       VARCHAR2(1000 CHAR),
    status_string      VARCHAR2(1000 CHAR),
    priority           VARCHAR2(1000 CHAR),
    flg_result         VARCHAR2(1 CHAR),
    contact_state      VARCHAR2(1000 CHAR),
    dept               VARCHAR2(1000 CHAR),
    fast_track_icon    VARCHAR2(100 CHAR),
    fast_track_color   VARCHAR2(240 CHAR),
    fast_track_status  VARCHAR2(1 CHAR),
    fast_track_desc    VARCHAR2(1000 CHAR),
    color_text         VARCHAR2(200 CHAR),
    esi_level          VARCHAR2(200 CHAR),
    id_task_dependency NUMBER(24),
    icon_name          VARCHAR2(200 CHAR),
    order_name         VARCHAR2(800 CHAR)
)
;
/
