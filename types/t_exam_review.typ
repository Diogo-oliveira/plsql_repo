CREATE OR REPLACE TYPE t_exam_review force AS OBJECT
(
    id_exam_req_det NUMBER(24),
    registry        VARCHAR2(1000 CHAR),
    desc_exam       VARCHAR2(4000 CHAR),
    review_notes    VARCHAR(2000 CHAR),
    dt_ord          VARCHAR2(200 CHAR)
)
;
/