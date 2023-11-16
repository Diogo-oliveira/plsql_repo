create or replace type t_rec_data_emergency_base force as object
(
 id_institution     number
,id_patient             number
,id_episode             number
,id_next_episode    number
,flg_status       varchar2(4000)
,dt_discharge           timestamp with local time zone
--***************************
,dis_flg_status         varchar2(4000)
,dis_flg_type           varchar2(4000)
,dis_dt_pend_tstz       timestamp with local time zone
,dis_dt_admin_tstz       timestamp with local time zone
--***************************
,dt_examination         timestamp with local time zone
,dt_triage              timestamp with local time zone
,dt_visit               timestamp with local time zone
,arrival_method         varchar2(4000)
,discharge_destination  varchar2(4000)
,discharge_status       varchar2(4000)
,id_prof_discharge      number
,id_habit               number
,id_epis_triage         number
,code_triage_color      varchar2(4000)
,flg_type               varchar2(4000)
,code_accuity           varchar2(4000)
,id_triage_type         number
,id_triage_color        number
,id_epis_triage_first   number
,code_triage_color_first      varchar2(4000)
,flg_type_first               varchar2(4000)
,code_accuity_first           varchar2(4000)
,id_triage_type_first         number
,id_triage_color_first        number
,id_software            number
,patient_complaint      varchar2(4000)
,code_complaint         varchar2(4000)
,dt_complaint     timestamp with local time zone
,DT_LAST_UPDATE_TSTZ   timestamp with local time zone
);
/

