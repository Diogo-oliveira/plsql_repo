-- CHANGED BY: Luís Maia
-- CHANGE DATE: 01/06/2011
-- CHANGE REASON: [ALERT-182676]
CREATE OR REPLACE type t_tbl_ar_episodes is table of T_REC_AR_EPISODES;
/
-- CHANGE END: Luìs Maia


-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 01/03/2016 14:56
-- CHANGE REASON: [ALERT-319114] 
drop type t_tbl_ar_episodes;
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 01/03/2016 14:57
-- CHANGE REASON: [ALERT-319114] 
create or replace type t_tbl_ar_episodes IS TABLE OF t_rec_ar_episodes;
-- CHANGE END: Paulo Teixeira