-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 19/08/2011
-- CHANGE REASON: ALERT-168848 
CREATE OR REPLACE TYPE t_rec_pn_texts AS OBJECT
(
    id_note             NUMBER(24),
    id_note_type        NUMBER(24),
    id_soap_block       NUMBER(24),
    id_soap_area        NUMBER(24),
    soap_block_desc     VARCHAR2(4000),
    soap_block_desc_new VARCHAR2(4000),
    soap_area_desc      VARCHAR2(4000),
    soap_area_desc_new  VARCHAR2(4000),
    soap_block_txt      CLOB,
    soap_area_txt       CLOB,
    rank_soap_block     NUMBER(6),
    flg_status          VARCHAR2(1),
    rank_data_block     NUMBER(6),
    id_task             number(24),
    id_task_type        number(24)
);
/
--CHANGE END: Sofia Mendes