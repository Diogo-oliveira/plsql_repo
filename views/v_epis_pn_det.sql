CREATE OR REPLACE VIEW v_epis_pn_det AS
SELECT id_epis_pn, id_epis_pn_det, id_pn_soap_block, id_pn_data_block, flg_status,dt_note, PN_NOTE
  FROM epis_pn_det;

