CREATE OR REPLACE VIEW V_DOC_TEMPLATE AS
SELECT id_doc_template,
       id_documentation_type,
       flg_gender,
       age_max,
       age_min,
       flg_available,
       internal_name,
       code_doc_template,
       id_content,
       template_layout
  FROM doc_template;