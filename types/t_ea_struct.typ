-- CHANGED BY: Diogo Oliveira
-- CHANGE DATE: 2018-05-07
CREATE OR REPLACE TYPE t_ea_struct IS OBJECT
(
    status_str  VARCHAR2(200),
    status_msg  VARCHAR2(200),
    status_icon VARCHAR2(200),
    status_flg  VARCHAR2(2)
)
;
/
-- CHANGE END: Diogo Oliveira