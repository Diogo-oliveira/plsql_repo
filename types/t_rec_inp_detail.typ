-- CHANGED BY: Ant�nio Neto
-- CHANGE DATE: 17/05/2011 10:22
-- CHANGE REASON: [ALERT-179647] Change Details screen to allow clob's - Descri��o: No perfil M�dico, no INP, no bot�o da Hist�ria da Doen�a (truncated)

CREATE OR REPLACE TYPE t_rec_inp_detail AS OBJECT
(
    id_history NUMBER(24),
    tbl_labels CLOB,
    tbl_values CLOB,
    tbl_types  VARCHAR2(3 CHAR)
)
;

-- CHANGE END: Ant�nio Neto
/


-- CHANGED BY: Ant�nio Neto
-- CHANGE DATE: 18/05/2011 14:30
-- CHANGE REASON: [ALERT-179647] Change Details screen to allow clob's - Descri��o: No perfil M�dico, no INP, no bot�o da Hist�ria da Doen�a (truncated)

BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_inp_detail AS OBJECT
(
    id_detail   NUMBER(24),
    label_descr VARCHAR2(4000 CHAR),
    value_descr CLOB,
    flg_type    VARCHAR2(3 CHAR),
    flg_status  VARCHAR2(1 CHAR)
)'; 
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/

-- CHANGE END: Ant�nio Neto