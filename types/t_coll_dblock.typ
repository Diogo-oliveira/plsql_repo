-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 29/01/2013
-- CHANGE REASON: [ALERT-250487] A physician suggested to add the option "Anamnesi Fisiologica" (or in (truncated)
CREATE OR REPLACE TYPE t_coll_dblock AS TABLE OF t_rec_dblock;
/
--CHANGE END: Sofia Mendes

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 22/01/2015 10:26
-- CHANGE REASON: [ALERT-306656] 
drop type t_coll_dblock;
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 22/01/2015 10:27
-- CHANGE REASON: [ALERT-306656] 
CREATE OR REPLACE TYPE t_coll_dblock AS TABLE OF t_rec_dblock
-- CHANGE END: Paulo Teixeira