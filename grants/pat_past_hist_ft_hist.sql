-- CHANGED BY: Rui Duarte
-- CHANGE DATE: 24/01/2011 14:50
-- CHANGE REASON: [ALERT-157301] New developments in PastHistory, free text values added(DML STEP 1)(v.2.6.0.5)
--                
GRANT SELECT ON pat_past_hist_ft_hist TO alert_viewer;
-- CHANGE END: Rui Duarte

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-APR-2011
-- CHANGE REASON: ALERT-171286 
grant select, update, delete on PAT_PAST_HIST_FT_HIST to alert_reset;
-- CHANGE END: Ana Coelho