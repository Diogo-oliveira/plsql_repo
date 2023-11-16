-- CHANGED BY: José Silva
-- CHANGE DATE: 17/02/2012 17:13
-- CHANGE REASON: [ALERT-219583] 
UPDATE epis_info t SET t.id_triage_color = 1674 WHERE t.id_triage_color = 1672;
UPDATE epis_triage t SET t.id_triage_color = 1674 WHERE t.id_triage_color = 1672;
UPDATE epis_triage t SET t.id_triage_color_orig = 1674 WHERE t.id_triage_color_orig = 1672;
--
UPDATE epis_info t SET t.id_triage_color = 1683 WHERE t.id_triage_color = 1681;
UPDATE epis_triage t SET t.id_triage_color = 1683 WHERE t.id_triage_color = 1681;
UPDATE epis_triage t SET t.id_triage_color_orig = 1683 WHERE t.id_triage_color_orig = 1681;
--
UPDATE epis_info t SET t.id_triage_color = 1692 WHERE t.id_triage_color = 1690;
UPDATE epis_triage t SET t.id_triage_color = 1692 WHERE t.id_triage_color = 1690;
UPDATE epis_triage t SET t.id_triage_color_orig = 1692 WHERE t.id_triage_color_orig = 1690;
-- CHANGE END: José Silva