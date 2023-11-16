-- CHANGED BY: Ana Matos
-- CHANGE DATE: 04/05/2017 10:22
-- CHANGE REASON: [ALERT-330278] 
update interv_presc_det_hist
set id_clinical_purpose = 501
where flg_clinical_purpose = 'N';

update interv_presc_det_hist
set id_clinical_purpose = 502
where flg_clinical_purpose = 'S';

update interv_presc_det_hist
set id_clinical_purpose = 508
where flg_clinical_purpose = 'P';

update interv_presc_det_hist
set id_clinical_purpose = 504
where flg_clinical_purpose = 'R';

update interv_presc_det_hist
set id_clinical_purpose = 503
where flg_clinical_purpose = 'T';

update interv_presc_det_hist
set id_clinical_purpose = 0
where flg_clinical_purpose = 'O';
-- CHANGE END: Ana Matos