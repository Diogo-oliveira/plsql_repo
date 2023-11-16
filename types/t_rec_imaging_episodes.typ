CREATE OR REPLACE TYPE t_rec_imaging_episodes force IS OBJECT
(
    id_episode         NUMBER(24),
    id_schedule        NUMBER(24),
    origin             VARCHAR(1000 CHAR),
    origin_desc        VARCHAR(1000 CHAR),
    pat_name           VARCHAR(1000 CHAR),
    pat_name_sort      VARCHAR(1000 CHAR),
    pat_age            VARCHAR2(50 CHAR),
    pat_gender         VARCHAR2(1 CHAR),
    photo              VARCHAR(1000 CHAR),
    num_clin_record    VARCHAR2(100 CHAR),
    name_prof_resp     VARCHAR2(800 CHAR),
    name_prof_req      CLOB,
    desc_exam          CLOB,
    flg_imaging_status VARCHAR(2 CHAR),
    flg_status         VARCHAR(2 CHAR),
    flg_status_desc    VARCHAR(1000 CHAR),
    flg_status_icon    VARCHAR(1000 CHAR),
    dt_target          VARCHAR(1000 CHAR),
    dt_target_tstz     VARCHAR(1000 CHAR),
    dt_admission_tstz  VARCHAR(1000 CHAR),
    epis_duration      VARCHAR(1000 CHAR),
    epis_duration_desc VARCHAR(1000 CHAR),
    rank_acuity        VARCHAR(1000 CHAR),
    acuity             VARCHAR(1000 CHAR)
);
/
