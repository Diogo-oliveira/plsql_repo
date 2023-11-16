CREATE OR REPLACE VIEW v_referral_xml_req AS
SELECT rxr.id_referral_xml_req, rxr.flg_type, rxr.id_report, rxr.xml_request, rxr.xml_response, null auth_request, rxr.auth_response, rxr.flg_Status, rxr.dt_ws_send, rxr.dt_ws_received, rxr.pdf_request, rxr.pdf_response, rxr.id_epis_report, rxr.id_p1_external_request FROM referral_xml_req rxr;
