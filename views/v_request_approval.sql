create or replace view V_REQUEST_APPROVAL as
SELECT id_request_approval,
       id_consult_req,
       id_professional,
       flg_active,
       create_user,
       create_time,
       create_institution,
       update_user,
       update_time,
       update_institution
  FROM request_approval;
  