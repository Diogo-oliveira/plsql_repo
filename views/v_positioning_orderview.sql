CREATE OR REPLACE VIEW v_positioning_orderview as
     SELECT epp.id_epis_positioning_plan,
            epp.id_epis_positioning_det,
            epp.dt_prev_plan_tstz,
            epp.id_epis_positioning_next,
            ep.rot_interval rotation,
            ep.dt_creation_tstz,
            epp.dt_execution_tstz,
            epp.notes,
            ep.id_episode,
            ep.flg_status,   
            epp.flg_status status_epis_posit_plan,                   
            ep.id_epis_positioning,
            ep.flg_massage,
            ep.dt_cancel_tstz,
            p.id_professional,
            p.nick_name,
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
       LEFT OUTER JOIN professional p
         ON epp.id_prof_exec = p.id_professional
      WHERE ep.id_epis_positioning = sys_context('ALERT_CONTEXT', 'l_epis_pos') 
        AND epp.flg_status NOT IN ('L', 'D','O')
        AND EPD.FLG_OUTDATED ='N';