create or replace view V_VACC_DOC_VIS  AS
SELECT id_vacc_doc_vis, doc_vis_name, doc_vis_barcode, doc_edition_data, id_content, flg_available
  FROM vacc_doc_vis;
