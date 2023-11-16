-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 26/11/2010 17:30
-- CHANGE REASON: [ALERT-149189] Chief complaints filter for Guidelines, Protocols and Order Sets
CREATE OR REPLACE TYPE t_tbl_guideline_complaints AS TABLE OF t_rec_guideline_complaints;
/
-- CHANGE END: Carlos Loureiro