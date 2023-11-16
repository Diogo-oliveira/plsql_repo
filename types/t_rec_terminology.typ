-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 2013-11-18
-- CHANGE REASON: ALERT-265471
CREATE OR REPLACE TYPE t_rec_terminology AS OBJECT
(
    id_terminology        NUMBER(24),
    desc_terminology      VARCHAR2(1000 CHAR),
    flg_terminology       VARCHAR2(200 CHAR),
    RANK                  NUMBER(24)
);
-- CHANGE END: Alexandre Santos