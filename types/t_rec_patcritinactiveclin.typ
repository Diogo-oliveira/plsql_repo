CREATE OR REPLACE TYPE t_rec_patcritinactiveclin AS OBJECT
(
    id_schedule       NUMBER(24),
    id_patient        NUMBER(24),
    num_clin_record   VARCHAR2(100),
    id_episode        NUMBER(24),
    name              VARCHAR2(200),
    gender            VARCHAR2(200),
    pat_age           VARCHAR2(50),
    photo             VARCHAR2(4000),
    cons_type         VARCHAR2(4000),
    hour_target       VARCHAR2(200),
    date_target       VARCHAR2(200),
    nick_name         VARCHAR2(200),
    flg_state         VARCHAR2(200),
    dt_server         VARCHAR2(200),
    img_sched         VARCHAR2(200),
    dt_efectiv        VARCHAR2(4000),
    desc_speciality   VARCHAR2(200),
    disch_dest        VARCHAR2(200),
    desc_drug_presc   VARCHAR2(200),
    desc_interv_presc VARCHAR2(200),
    desc_analysis_req VARCHAR2(200),
    desc_exam_req     VARCHAR2(200),
    dt_ord1           VARCHAR2(200),
    pat_ndo           VARCHAR2(200),
    pat_nd_icon       VARCHAR2(200)
)
;
/
