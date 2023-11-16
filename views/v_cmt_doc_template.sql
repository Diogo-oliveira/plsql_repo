CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_DOC_TEMPLATE AS
SELECT desc_template,
       id_doc_template,
       decode(rn, 1, 'Most recent') AS version,
       internal_name,
       id_content,
       flg_gender,
       age_max,
       age_min
  FROM (SELECT desc_template,
               id_doc_template,
               internal_name,
               id_content,
               flg_gender,
               age_max,
               age_min,
               row_number() over(PARTITION BY pk_cmt_content_core.format_prepare_for_search(desc_template) ORDER BY id_doc_template DESC) AS rn
          FROM (SELECT DISTINCT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                       dt.code_doc_template)
                                   FROM dual) desc_template,
                                id_doc_template,
                                dt.internal_name,
                                dt.id_content,
                                dt.age_max,
                                dt.age_min,
                                dt.flg_gender
                  FROM doc_template dt
                 WHERE flg_available = 'Y')
         WHERE desc_template IS NOT NULL)
 ORDER BY pk_cmt_content_core.format_prepare_for_search(desc_template), id_doc_template DESC;

