-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 17/10/2014 14:29
-- CHANGE REASON: [ALERT-291854] 
CREATE OR REPLACE TYPE t_rec_proc_performed_cda AS OBJECT
(
    id_procedure   NUMBER(24),
    id_performed   NUMBER(24),
    performed_name VARCHAR2(4000 CHAR),
    id_institution NUMBER(24),
    id_software    NUMBER(24),    
    role_code      NUMBER(24),
    role_desc      VARCHAR2(4000 CHAR)
)
;
-- CHANGE END: Paulo Teixeira