-- CHANGED BY: Jorge Silva
-- CHANGE DATE: 28/11/2014
-- CHANGE REASON: ALERT-303171
CREATE OR REPLACE TYPE t_rec_action force AS OBJECT
(
    id_action     NUMBER,
    id_parent     NUMBER(24),
    level_nr      NUMBER,
    from_state    VARCHAR2(30),
    to_state      VARCHAR2(30),
    desc_action   VARCHAR2(4000),
    icon          VARCHAR2(200),
    flg_default   VARCHAR2(1),
    action        VARCHAR2(50),
    flg_active    VARCHAR2(1),
    CONSTRUCTOR FUNCTION t_rec_action RETURN SELF AS RESULT
);
-- CHANGE END: Jorge Silva
/
