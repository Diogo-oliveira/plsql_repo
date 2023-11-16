CREATE OR REPLACE TYPE t_exams_pregnancy_result force AS OBJECT
(
    id_exam_req     NUMBER(24),
    id_exam_req_det NUMBER(24),
    id_exam         NUMBER(24),
    dt_req          TIMESTAMP(6) WITH LOCAL TIME ZONE,
--id_order_recurrence NUMBER(24),
    id_episode       NUMBER(24),
    id_pat_pregnancy NUMBER(24),
    id_exam_result   NUMBER(24),
    dt_result        TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_professional  NUMBER(24),
    notes            CLOB,
    result_count     NUMBER(6)
)
;
/
