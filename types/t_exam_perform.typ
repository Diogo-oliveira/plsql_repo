CREATE OR REPLACE TYPE t_exam_perform force AS OBJECT
(
    id_exam_req_det NUMBER(24),
    registry        VARCHAR2(1000 CHAR),
    desc_exam       VARCHAR2(4000 CHAR),
    prof_perform    VARCHAR2(4000 CHAR),
    dt_perform      VARCHAR2(200 CHAR),
    desc_supplies   VARCHAR2(4000 CHAR),
    desc_time_out   CLOB,
    desc_perform    CLOB,
    dt_ord          VARCHAR2(200 CHAR)
)
;
/