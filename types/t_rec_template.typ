-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 25/02/2011 10:10
-- CHANGE REASON: [ALERT-164483] soap note blocks configuration types
CREATE OR REPLACE TYPE t_rec_template AS OBJECT
(
    id_doc_template NUMBER(24), -- documentation template identifier
    desc_template   VARCHAR2(1000 CHAR), -- documentation template description
    id_doc_area     NUMBER(24), -- documentation area identifier
    flg_type        VARCHAR2(2 CHAR), -- documentation templates search mode

    CONSTRUCTOR FUNCTION t_rec_template RETURN SELF AS RESULT
)
;
/
-- CHANGE END: Pedro Carneiro