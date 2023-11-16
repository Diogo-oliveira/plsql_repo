-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 17/10/2014 14:29
-- CHANGE REASON: [ALERT-291854] 
CREATE OR REPLACE TYPE t_rec_surgical_proc_cda AS OBJECT
(
    id_procedure    NUMBER(24),
    id_content      VARCHAR2(200 CHAR),
    procedure_desc  VARCHAR2(4000 CHAR),
    type_code       VARCHAR2(1 CHAR),
    type_desc       VARCHAR2(4000 CHAR),
    status_code     VARCHAR2(2 CHAR),
    status_desc     VARCHAR2(4000 CHAR),
    date_value      TIMESTAMP(6) WITH LOCAL TIME ZONE,
    date_formatted  VARCHAR2(1000 CHAR),
    date_serialized VARCHAR2(14 CHAR),
    target_code     VARCHAR2(1 CHAR),
    target_desc     VARCHAR2(4000 CHAR),
    notes           CLOB,
    performed       t_coll_proc_performed_cda
)
;
-- CHANGE END: Paulo Teixeira