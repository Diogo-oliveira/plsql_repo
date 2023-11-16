-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 19/05/2011 15:31
-- CHANGE REASON: [ALERT-179674 ] 
begin
update VACC_MED_EXT v set v.EMB_ID_vc = v.emb_id, v.med_id_vc = v.med_id;
end;
/
-- CHANGE END: Sérgio Santos