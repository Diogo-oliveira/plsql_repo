CREATE OR REPLACE VIEW V_DOC_AREA AS	
SELECT id_doc_area,
       mdm_coding,
       flg_available,
       internal_name,
       code_doc_area,
       code_abbreviation,
       flg_score,
       intern_name_sample_text_type,
       gender,
       age_min,
       age_max,
       id_parent_doc_area,
       id_content
  FROM doc_area;