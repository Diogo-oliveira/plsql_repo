/*-- Last Change Revision: $Rev:$*/
/*-- Last Change by: $Author:$*/
/*-- Date of last change: $Date:$*/
CREATE OR REPLACE TYPE t_rec_diet_episodes force IS OBJECT
(
    id_episode                NUMBER(24),
    id_schedule               NUMBER(24),
    id_patient                NUMBER(24),
    origin                    VARCHAR(1000 CHAR),
    origin_desc               VARCHAR(1000 CHAR),
    pat_name                  VARCHAR(1000 CHAR),
    pat_name_sort             VARCHAR(1000 CHAR),
    pat_age                   VARCHAR2(50 CHAR),
    pat_gender                VARCHAR2(1 CHAR),
    photo                     VARCHAR(1000 CHAR),
    num_clin_record           VARCHAR2(100),
    diagnosis_desc            VARCHAR(1000 CHAR),
    service_desc              VARCHAR(1000 CHAR),
    room_desc                 VARCHAR(1000 CHAR),
    bed_desc                  VARCHAR(1000 CHAR),
    name_prof_resp            VARCHAR2(800),
    name_prof_req             VARCHAR2(800),
    reason_req                VARCHAR(1000 CHAR),
    dt_target                 VARCHAR(1000 CHAR),
    dt_target_tstz            VARCHAR(1000 CHAR),
    dt_next_followup          VARCHAR(1000 CHAR),
    dt_next_followup_tstz     VARCHAR(1000 CHAR),
    flg_request_type          VARCHAR(2 CHAR),
    flg_status                VARCHAR(2 CHAR),
    flg_status_desc           VARCHAR(1000 CHAR),
    flg_status_icon           VARCHAR(1000 CHAR),
    desc_status               VARCHAR(50 CHAR),
    id_type_appointment       NUMBER(24),
    flg_type_appointment_desc VARCHAR(1000 CHAR),
    rank_acuity               VARCHAR(1000 CHAR),
    acuity                    VARCHAR(1000 CHAR)
);
/
