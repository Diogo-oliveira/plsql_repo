--
CREATE OR REPLACE VIEW v_EPIS_HHC_REQ_STATUS AS
SELECT e.id_epis_hhc_req, 
        e.id_professional, 
        e.flg_status, 
        e.dt_status, 
        e.id_cancel_reason id_reason,
        e.cancel_notes reason_notes,
        e.flg_undone
  FROM epis_hhc_req_status e;



