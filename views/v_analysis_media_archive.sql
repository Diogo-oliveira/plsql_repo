CREATE OR REPLACE VIEW v_analysis_media_archive AS
SELECT 
ama.id_analysis_media_archive,
ama.id_doc_external,
ama.id_analysis_result_par,
ama.flg_type,
ama.flg_status
FROM analysis_media_archive ama;