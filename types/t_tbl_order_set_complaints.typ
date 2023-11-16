-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 02/12/2010 17:30
-- CHANGE REASON: [ALERT-149189] Chief complaints filter for Guidelines, Protocols and Order Sets
CREATE OR REPLACE TYPE t_tbl_order_set_complaints AS TABLE OF t_rec_order_set_complaints;
/
-- CHANGE END: Carlos Loureiro