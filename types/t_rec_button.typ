-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 13/05/2013
-- CHANGE REASON: [ALERT-259146 ] EDIS nurse single page
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_button force AS OBJECT
(
    id_pn_soap_block     NUMBER(24), -- soap block identifier
    id_conf_button_block NUMBER(24), -- soap button identifier
    id_doc_area          NUMBER(24), -- documentation area identifier
    id_pn_task_type      NUMBER(24),
    action               varchar2(2 char),
    id_parent            number(24),
    icon                 varchar2(200 char),
    flg_visible          varchar2(1 char),
    id_type              NUMBER(24),
    rank                 number(6),
    flg_activation       varchar2(1 char),
    CONSTRUCTOR FUNCTION t_rec_button RETURN SELF AS RESULT
)';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
--CHANGE END: Sofia Mendes