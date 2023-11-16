CREATE OR REPLACE TYPE t_exam_doc force AS OBJECT
(
    id_exam_req_det          NUMBER(24),
    id_doc_external          NUMBER(24),
    registry                 VARCHAR2(1000 CHAR),
    doc_title                VARCHAR2(1000 CHAR),
    doc_original_type        VARCHAR2(1000 CHAR),
    desc_status              VARCHAR2(1000 CHAR),
    dt_doc                   VARCHAR2(200 CHAR),
    perform_by               VARCHAR2(1000 CHAR),
    num_img                  VARCHAR2(200 CHAR),
    doc_original_desc        VARCHAR2(1000 CHAR),
    doc_original_destination VARCHAR2(1000 CHAR),
    notes                    VARCHAR2(4000 CHAR),
    thumbnail                VARCHAR2(1000 CHAR),
    thumbnail_icon           VARCHAR2(10 CHAR),
    dt_ord                   VARCHAR2(200 CHAR)
)
;
/