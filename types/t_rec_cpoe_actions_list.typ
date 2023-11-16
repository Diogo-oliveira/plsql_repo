
-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 11/12/2009
-- CHANGE REASON: [ALERT-61939] CPOE 2nd phase: versioning of CPOE feature for Diets and Hidrics
CREATE OR REPLACE TYPE t_rec_cpoe_actions_list AS OBJECT
(
    id_action     NUMBER(24),
    id_parent     NUMBER(24),
    level_num     NUMBER(6),
    from_state    VARCHAR2(1 CHAR),
    to_state      VARCHAR2(1 CHAR),
    desc_action   VARCHAR2(200 CHAR),
    icon          VARCHAR2(200 CHAR),
    flg_default   VARCHAR2(1 CHAR),
    flg_active    VARCHAR2(1 CHAR),
    internal_name VARCHAR2(200 CHAR)
);
-- CHANGE END: Carlos Loureiro


-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 19/12/2016 09:41
-- CHANGE REASON: [ALERT-325129]
CREATE OR REPLACE TYPE t_rec_cpoe_actions_list FORCE AS OBJECT
(
    id_action     NUMBER(24),
    id_parent     NUMBER(24),
    level_num     NUMBER(6),
    from_state    VARCHAR2(2 CHAR),
    to_state      VARCHAR2(2 CHAR),
    desc_action   VARCHAR2(200 CHAR),
    icon          VARCHAR2(200 CHAR),
    flg_default   VARCHAR2(1 CHAR),
    flg_active    VARCHAR2(1 CHAR),
    internal_name VARCHAR2(200 CHAR)
);

-- CHANGE END: Pedro Henriques

