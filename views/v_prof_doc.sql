CREATE VIEW v_prof_doc AS 
SELECT id_prof_doc, id_doc_type, id_professional, value, id_institution, local_emited, dt_emited_tstz, dt_expire_tstz FROM prof_doc;
