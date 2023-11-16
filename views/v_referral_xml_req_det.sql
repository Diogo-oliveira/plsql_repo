CREATE OR REPLACE VIEW v_referral_xml_req_det AS
SELECT a.id_referral_xml_req_det, a.id_referral_xml_req, a.id_group, a.xml_det_request, a.xml_det_response, a.flg_status FROM referral_xml_Req_det a;
