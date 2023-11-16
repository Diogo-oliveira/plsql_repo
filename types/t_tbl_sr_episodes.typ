-- CHANGED BY: Luís Maia
-- CHANGE DATE: 02/06/2011 08:42
-- CHANGE REASON: [ALERT-182676] Versioning 01 - types
create or replace type t_tbl_sr_episodes is table of T_REC_SR_EPISODES;
/
-- CHANGE END: Luís Maia


-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 01/03/2016 14:56
-- CHANGE REASON: [ALERT-319114] 
drop type t_tbl_sr_episodes;
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 01/03/2016 14:57
-- CHANGE REASON: [ALERT-319114] 
CREATE OR REPLACE TYPE t_tbl_sr_episodes is table of T_REC_SR_EPISODES;
-- CHANGE END: Paulo Teixeira