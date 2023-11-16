CREATE OR REPLACE VIEW TL_TRANSACTION_DATA AS
SELECT EPE.ID_EPISODE ID_TRANSACTION
          ,EPE.DT_BEGIN_TSTZ DT_BEGIN_TSTZ
          ,EPE.DT_END_TSTZ DT_END_TSTZ
          ,EI.DT_LAST_INTERACTION_TSTZ
          ,EI.DT_FIRST_OBS_TSTZ
          ,EI.ID_SOFTWARE ID_SOFTWARE
          ,EPE.ID_PATIENT ID_PATIENT
FROM EPISODE EPE
    ,EPIS_INFO EI
    ,tl_software ts
    where  EI.ID_EPISODE=EPE.ID_EPISODE
and epe.flg_ehr='N'
and ts.id_TL_software=EI.id_software
AND EPE.flg_status != 'C'
union
select -1 *se.id_social_episode ID_TRANSACTION
          ,se.dt_first_obs_tstz DT_BEGIN_TSTZ
          ,sed.dt_social_epis_discharge_tstz DT_END_TSTZ
          ,nvl(sed.dt_social_epis_discharge_tstz,e.dt_last_interaction_tstz) DT_LAST_INTERACTION_TSTZ
          ,nvl(nvl(se.dt_first_obs_tstz,e.dt_first_obs_tstz),Epe.Dt_Begin_Tstz )   DT_FIRST_OBS_TSTZ
          ,24 ID_SOFTWARE
          ,se.id_patient ID_PATIENT
from social_episode   se
left join EPIS_info e on (e.id_episode=se.id_episode)
left join episode epe on (epe.id_episode=se.id_episode)
left join social_epis_discharge sed on (sed.id_social_episode=se.id_social_episode)
where epe.flg_status != 'C'
and epe.flg_ehr='N';

 
 COMMENT ON table TL_TRANSACTION_DATA IS 'Timeline data';
 comment on column TL_TRANSACTION_DATA.ID_TRANSACTION is 'timeline data identifier';
 comment on column TL_TRANSACTION_DATA.DT_BEGIN_TSTZ is 'Begin date';
 comment on column TL_TRANSACTION_DATA.DT_END_TSTZ is 'End date';
 comment on column TL_TRANSACTION_DATA.DT_LAST_INTERACTION_TSTZ is 'Last interaction date';
 comment on column TL_TRANSACTION_DATA.DT_FIRST_OBS_TSTZ is 'First interaction date';
 comment on column TL_TRANSACTION_DATA.ID_SOFTWARE is 'Software identifier';
 comment on column TL_TRANSACTION_DATA.ID_PATIENT is 'Patient identifier';
 
