CREATE OR REPLACE VIEW v_rt_my_patients AS
SELECT epis.triage_acuity,
       epis.triage_color_text,
       epis.id_software, 
       epis.id_epis_type, 
       epis.triage_flg_letter,
       epis.ID_EPISODE,
       epis.ID_PATIENT,
       epis.ID_SCHEDULE,
       epis.ID_CLINICAL_SERVICE,
       epis.DT_BEGIN_TSTZ_E,
       epis.DT_FIRST_OBS_TSTZ,
       epis.id_visit,
       epis.has_transfer,
       epis.ID_FAST_TRACK,
       epis.id_triage_color,
       epis.ID_ROOM,
       epis.ID_PROFESSIONAL,
       epis.ID_FIRST_NURSE_RESP,
			 epis.triage_rank_acuity,
       r.desc_room_abbreviation,
       r.desc_room,
       sd.rank,
       sd.img_name,
       sys_context('ALERT_CONTEXT', 'l_lang') i_lang,
       sys_context('ALERT_CONTEXT', 'l_prof_id') i_prof_id,
       sys_context('ALERT_CONTEXT', 'l_prof_institution') i_prof_institution,
       sys_context('ALERT_CONTEXT', 'l_prof_software') i_prof_software
FROM v_episode_act epis, sys_domain sd, room r
             WHERE sd.id_language = sys_context('ALERT_CONTEXT', 'l_lang')
               AND sd.val = epis.flg_status_ei
               AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
               AND sd.domain_owner = 'ALERT'
               AND epis.id_room = r.id_room(+)
							 AND epis.id_institution = sys_context('ALERT_CONTEXT', 'l_prof_institution')
							  AND pk_prof_follow.get_follow_episode_by_me(profissional(sys_context('ALERT_CONTEXT', 'l_prof_id'),sys_context('ALERT_CONTEXT', 'l_prof_institution'),sys_context('ALERT_CONTEXT', 'l_prof_software')), epis.id_episode, epis.id_schedule) = 'Y';
