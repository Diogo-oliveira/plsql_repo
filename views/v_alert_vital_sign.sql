CREATE OR REPLACE VIEW V_ALERT_VITAL_SIGN AS
select m.id_monitorization_vs id_reg, t.id_episode, v.id_institution, t.id_professional id_prof, 
		   m.id_monitorization_vs dt_req, 
         'V_ALERT_M007' msg, 
		   (SELECT PK_SYSCONFIG.GET_CONFIG('ALERT_VITAL_SIGN_TIMEOUT', V.ID_INSTITUTION, 1) FROM DUAL) replace1, 
		   ei.id_room, 
         4 alert_level 
from monitorization_vs m, vital_sign vs, monitorization t, episode e, visit v, epis_info ei 
where m.flg_status = 'A' 
and vs.id_vital_sign = m.id_vital_sign 
and t.id_monitorization = m.id_monitorization 
and t.flg_time = 'E' 
and t.flg_status = 'A' 
and e.id_episode = t.id_episode 
and v.id_visit = e.id_visit 
and m.dt_monitorization_vs_tstz < sysdate - ((SELECT PK_SYSCONFIG.GET_CONFIG('ALERT_VITAL_SIGN_TIMEOUT', V.ID_INSTITUTION, 1) FROM DUAL)/(24*60)) 
and ei.id_episode = e.id_episode;

