create or replace type t_rec_data_emr_transfer_plus force as object (
 id_institution         number
,institution_name       varchar2(4000)
,id_episode                     number
,id_prof_req                    number
,prof_req_name          varchar2(4000)
,dt_request_tstz                timestamp with local time zone
,flg_type                       varchar2(0050 char)
,flg_type_desc          varchar2(4000)
,flg_status                     varchar2(0050 char)
,flg_status_Desc        varchar2(4000)
,id_clinical_service_orig       number
,clinical_service_orig_desc   varchar2(4000)
,id_department_orig             number
,department_orig_desc     varchar2(4000)
);
/

