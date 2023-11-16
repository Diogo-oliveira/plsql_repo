CREATE OR REPLACE VIEW v_lab_test_cdr AS
SELECT ltea.id_analysis_req_det, ltea.id_patient, ltea.id_analysis, ltea.id_institution, ltea.dt_req
	FROM lab_tests_ea ltea
 WHERE ltea.flg_status_det != 'C';
