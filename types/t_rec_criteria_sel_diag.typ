
-- CHANGED BY: Carlos Loureiro
-- CHANGED DATE: 30-JUL-2010
-- CHANGED REASON: [ALERT-116034] SCT search fix for guidelines and protocols
CREATE OR REPLACE TYPE t_rec_criteria_sel_diag AS OBJECT
(
    diag_rowid    VARCHAR2(40),
    criteria_type VARCHAR2(1)
);
-- CHANGE END: Carlos Loureiro

