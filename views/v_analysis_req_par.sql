-- CHANGED BY: José Castro
-- CHANGE DATE: 31/05/2010 10:10
-- CHANGE REASON: ALERT-101292
CREATE OR REPLACE VIEW V_ANALYSIS_REQ_PAR AS
SELECT id_analysis_req_par,
       id_analysis_req_det,
       id_analysis_parameter
  FROM analysis_req_par;
-- CHANGE END: José Castro
