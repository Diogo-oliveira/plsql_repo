create or replace view v_trial as
SELECT id_trial,
       name,
       code,
       flg_status,
       dt_record,
       id_prof_record,
       responsible,
       resp_contact_det,
       notes,
       dt_start,
       dt_end,
       id_institution,
       flg_trial_type,
       id_cancel_info_det,
       pharma_code,
       pharma_name
  FROM trial;
/	
   
