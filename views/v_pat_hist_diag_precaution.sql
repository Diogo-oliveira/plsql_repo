-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 27/02/2012 09:40
-- CHANGE REASON: [ALERT-220425 ] 
create or replace view v_pat_hist_diag_precaution as
select id_pat_history_diagnosis,
id_precaution
from pat_hist_diag_precaution;
-- CHANGE END: Sérgio Santos