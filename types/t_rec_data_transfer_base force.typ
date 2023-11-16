create or replace type t_rec_data_transfer_base force as object (
 id_institution					number
,id_episode                     number
,id_prof_req                    number
,dt_request_tstz                timestamp with local time zone
,flg_type                       varchar2(0050 char)
,flg_status                     varchar2(0050 char)
,id_clinical_service_orig       number
,id_department_orig             number
);
/

