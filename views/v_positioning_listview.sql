CREATE OR REPLACE VIEW V_POSITIONING_LISTVIEW AS
SELECT ep.id_epis_positioning,
       ep.flg_status AS status_epis_posit,
       epp.id_epis_positioning_plan,
       epp.flg_status AS status_epis_posit_plan,
       epp.id_epis_positioning_det,
       epp.id_epis_positioning_next,
       ep.rot_interval,
       ep.flg_massage,
       epp.dt_prev_plan_tstz,
       ep.notes,
       ep.notes_cancel,
       ep.notes_inter,
       ep.dt_creation_tstz,
       ep.id_episode,
       epp.dt_epis_positioning_plan,
       sys_context('ALERT_CONTEXT', 'l_lang') i_lang,
       sys_context('ALERT_CONTEXT', 'l_prof_id') i_prof_id,
       sys_context('ALERT_CONTEXT', 'l_prof_institution') i_prof_institution,
       sys_context('ALERT_CONTEXT', 'l_prof_software') i_prof_software
  FROM epis_positioning ep
 INNER JOIN epis_positioning_det epd
    ON ep.id_epis_positioning = epd.id_epis_positioning
 INNER JOIN epis_positioning_plan epp
    ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
   AND epp.id_epis_positioning_plan IN
       (SELECT MAX(epp1.id_epis_positioning_plan)
          FROM epis_positioning_plan epp1
         WHERE epp1.id_epis_positioning_det IN
               (SELECT epd1.id_epis_positioning_det
                  FROM epis_positioning_det epd1
                 WHERE epd1.id_epis_positioning = ep.id_epis_positioning))
 WHERE ep.flg_status NOT IN ('D', 'L')
   AND ep.flg_origin = sys_context('ALERT_CONTEXT', 'l_flg_origin')
   AND ((ep.flg_origin = 'SR' AND
       (ep.id_episode_context IN
       (sys_context('ALERT_CONTEXT', 'l_id_episode'), sys_context('ALERT_CONTEXT', 'l_id_episode_sr')) OR
       ep.id_episode IN
       (sys_context('ALERT_CONTEXT', 'l_id_episode'), sys_context('ALERT_CONTEXT', 'l_id_episode_sr')))) OR
       (ep.flg_origin = 'N' AND ep.id_episode = sys_context('ALERT_CONTEXT', 'l_id_episode') AND
       ep.id_episode_context IS NULL));