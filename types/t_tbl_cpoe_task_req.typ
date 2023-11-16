-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 12/07/2010 20:27
-- CHANGE REASON: [ALERT-111270] CPOE performance fix
CREATE OR REPLACE TYPE t_tbl_cpoe_task_req AS TABLE OF t_rec_cpoe_task_req;
/
-- CHANGE END: Carlos Loureiro

-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 12/10/2010
-- CHANGE REASON: [ALERT-128777] CPOE improvement
CREATE OR REPLACE TYPE t_tbl_cpoe_task_req AS TABLE OF t_rec_cpoe_task_req;
-- CHANGE END: Tiago Silva