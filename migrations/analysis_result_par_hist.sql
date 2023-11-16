-- CHANGED BY: Ana Matos
-- CHANGE DATE: 07/07/2014 11:14
-- CHANGE REASON: [ALERT-289548] 
update analysis_result_par_hist
set analysis_result_value_1 = analysis_result_value
where id_analysis_result_par_hist = id_analysis_result_par_hist
and dt_analysis_res_par_hist = dt_analysis_res_par_hist;
-- CHANGE END: Ana Matos