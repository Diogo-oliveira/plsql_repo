-->v_license
create or replace view v_license as
SELECT id_license,
       id_institution,
       id_product_purchasable,
       id_professional,
       flg_status,
       payment_schedule,
       notes_license,
       id_profile_template_desc,
       dt_expire_tstz,
       dt_purchase_tstz
  FROM license;
-->v_document
create or replace view v_document as
SELECT id_patient, id_doc_type, num_doc, dt_emited, dt_expire, flg_status
  FROM doc_external;