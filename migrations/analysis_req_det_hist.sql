-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/03/2015 11:20
-- CHANGE REASON: [ALERT-308718] 
update analysis_req_det_hist 
set notes_scheduler = notes;

update analysis_req_det_hist 
set notes = null;
-- CHANGE END: Ana Matos

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 04/05/2017 10:22
-- CHANGE REASON: [ALERT-330278] 
update analysis_req_det_hist
set id_clinical_purpose = 501
where flg_clinical_purpose = 'N';

update analysis_req_det_hist
set id_clinical_purpose = 502
where flg_clinical_purpose = 'S';

update analysis_req_det_hist
set id_clinical_purpose = 508
where flg_clinical_purpose = 'P';

update analysis_req_det_hist
set id_clinical_purpose = 504
where flg_clinical_purpose = 'R';

update analysis_req_det_hist
set id_clinical_purpose = 503
where flg_clinical_purpose = 'T';

update analysis_req_det_hist
set id_clinical_purpose = 505
where flg_clinical_purpose = 'C';

update analysis_req_det_hist
set id_clinical_purpose = 506
where flg_clinical_purpose = 'PO';

update analysis_req_det_hist
set id_clinical_purpose = 507
where flg_clinical_purpose = 'F';

update analysis_req_det_hist
set id_clinical_purpose = 0
where flg_clinical_purpose = 'O';
-- CHANGE END: Ana Matos