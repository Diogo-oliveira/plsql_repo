-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 01/03/2010 14:31
-- CHANGE REASON: [ALERT-60380] Dev Barthel Idx

CREATE OR REPLACE TYPE t_tbl_doc_area_val IS TABLE OF t_rec_doc_area_val;
/
-- CHANGE END: Gustavo Serrano

-- CHANGED BY: Ana Moita
-- CHANGE DATE: 06/08/2019
-- CHANGE REASON: [EMR_18650] 

CREATE OR REPLACE TYPE t_tbl_doc_area_val AS TABLE OF t_rec_doc_area_val;
/
-- CHANGE END: Ana Moita