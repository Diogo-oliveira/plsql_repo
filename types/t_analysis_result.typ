CREATE OR REPLACE TYPE t_analysis_result force AS OBJECT
(
    id_analysis_result      NUMBER(24),
    id_analysis             NUMBER(12),
    id_analysis_req_det     NUMBER(24),
    id_professional         NUMBER(24),
    id_patient              NUMBER(24),
    notes                   CLOB,
    flg_type                VARCHAR2(1),
    id_institution          NUMBER(12),
    id_episode              NUMBER(24),
    loinc_code              VARCHAR2(200),
    flg_status              VARCHAR2(1),
    dt_analysis_result_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_sample               TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_visit                NUMBER(24),
    id_exam_cat             NUMBER(24),
    flg_orig_analysis       VARCHAR2(1),
    id_episode_orig         NUMBER(24),
    id_result_status        NUMBER(24),
    flg_result_origin       VARCHAR2(2),
    id_prof_req             NUMBER(24),
    id_harvest              NUMBER(24),
    id_sample_type          NUMBER(12),
    result_origin_notes     VARCHAR2(200),
    flg_mult_result         VARCHAR2(1)
);
/
