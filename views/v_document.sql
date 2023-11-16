-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2013-12-17
-- CHANGED REASON: ADT-7968

CREATE OR REPLACE VIEW V_DOCUMENT AS
SELECT de.id_patient, de.id_doc_type, de.num_doc, de.dt_emited, de.dt_expire, de.flg_status,
de.LOCAL_EMITED, de.ORGAN_SHIPPER, de.dt_last_identification dt_last_identification_tstz
  FROM doc_external de;

-- CHANGED END: Bruno Martins