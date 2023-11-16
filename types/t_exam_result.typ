CREATE OR REPLACE TYPE t_exam_result force AS OBJECT
(
    id_exam_req_det       NUMBER(24),
    id_exam_result        NUMBER(24),
    id_exam_result_parent NUMBER(24),
    id_result_status      NUMBER(24),
    registry              VARCHAR2(1000 CHAR),
    desc_exam             VARCHAR2(4000 CHAR),
    result_origin         VARCHAR2(1000 CHAR),
    result_origin_notes   VARCHAR2(200 CHAR),
    result_status         VARCHAR2(1000 CHAR),
    abnormality_level     VARCHAR2(1000 CHAR),
    desc_relevant         VARCHAR2(4000 CHAR),
    notes                 CLOB,
    desc_result_notes     VARCHAR2(4000 CHAR),
    desc_result_diagnosis VARCHAR2(4000 CHAR),
    notes_result          CLOB,
    cancel_reason         VARCHAR2(1000 CHAR),
    notes_cancel          VARCHAR2(4000 CHAR),
    dt_ord                VARCHAR2(200 CHAR),
    dt_last_update        TIMESTAMP(6)
)
;
/