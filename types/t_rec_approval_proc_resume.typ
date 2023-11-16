-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 28/10/2009
-- CHANGE REASON: [ALERT-52460] Desenvolvimentos Director Clinico ALERT_34026
CREATE OR REPLACE TYPE t_rec_approval_proc_resume AS OBJECT
(
    rank           NUMBER(6),
    flg_status     VARCHAR2(1),
    flg_action     VARCHAR2(1),
    id_prof_action NUMBER(24),
    dt_action      TIMESTAMP WITH LOCAL TIME ZONE,
    notes          VARCHAR2(4000),
    prof_name      VARCHAR2(4000),
    speciality     VARCHAR2(4000)
)
;
-- CHANGE END: Gustavo Serrano