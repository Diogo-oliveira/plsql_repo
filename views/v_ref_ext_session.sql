-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2011-JAN-21
-- CHANGED REASON: ALERT-154559
CREATE OR REPLACE VIEW v_ref_ext_session AS
SELECT s.id_session,
       s.dt_session,
       s.id_external_request,
       s.ref_url,
       s.flg_active,
       s.num_order,
       s.ext_code,
       s.id_professional,
       s.dt_inserted,
       (SELECT pk_api_ref_ext.get_dt_expire(1, profissional(NULL, 0, 0), s.dt_session)
          FROM dual) dt_expire_session,
       x.patient_data,
       x.referral_data
  FROM ref_ext_session s
  LEFT JOIN ref_ext_xml_data x ON s.id_session = x.id_session;
-- CHANGE END: Ana Monteiro