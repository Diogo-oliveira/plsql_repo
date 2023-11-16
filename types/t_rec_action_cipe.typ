-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 04/11/2010 17:06
-- CHANGE REASON: [ALERT-137960] 
CREATE OR REPLACE TYPE t_rec_action_cipe AS OBJECT
(
    id_action     NUMBER(24),
    desc_action   VARCHAR2(1000 CHAR),
    subject       VARCHAR2(200 CHAR),
    to_state      VARCHAR2(1 CHAR),
    icon          VARCHAR2(200 CHAR),
    flg_active    VARCHAR2(1 CHAR),
    rank          NUMBER,
    flg_default   VARCHAR2(1 CHAR),
    id_parent     NUMBER(24),
    internal_name VARCHAR2(50 CHAR),
    action_level  NUMBER
)
;
-- CHANGE END: Sérgio Santos