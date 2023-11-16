-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 13/05/2011
-- CHANGE REASON: [ALERT-178978]
CREATE OR REPLACE TYPE t_rec_summary_grid_exam IS OBJECT
(
    dt_req      VARCHAR2(4000),
    rank_status NUMBER(6),
    description VARCHAR2(4000),
    flg_status  VARCHAR2(2),
    dt_server   VARCHAR2(50),
    icon_name1  VARCHAR2(4000)
);
/
--END CHANGE: Filipe Silva
