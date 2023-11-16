CREATE OR REPLACE VIEW V_REHAB_APPOINTMENT_TODAY AS
SELECT
       sp.id_schedule,
       sp.dt_begin_tstz,
       sp.dt_schedule_tstz,
       sp.id_lock_uq_value,
       sp.id_episode_rehab,
       NULL id_resp_professional,
       NULL id_resp_rehab_group,
       sp.dt_creation,
       /*
       pk_rehab.get_rehab_app_status(sp.sys_lang,
                                     sp.sys_lprof,
                                     sp.id_patient,
                                     sp.re_flg_status) flg_status,
       */
       null flg_Status,
       --1442 shortcut,
       null shortcut,
       sp.id_epis_type id_schedule_type,
       NULL code_rehab_session_type,
       NULL abbreviation,
       NULL code_department,
       NULL id_room,
       NULL desc_room_abbreviation,
       NULL code_abbreviation,
       NULL code_room,
       NULL desc_room,
       NULL code_bed,
       NULL desc_bed,
       sp.id_rehab_epis_encounter,
       NULL id_rehab_sch_need,
       NULL id_rehab_schedule,
       sp.id_software,
       sp.id_professional,
       sp.e_flg_status e_flg_status,
       sp.id_patient  ,
       sp.id_visit    ,
       sp.id_episode  ,
       'REHAB_GRID_SCHED' lock_func,
       'A' grid_workflow_icon,
       'A' grid_workflow_icon_status,
       'A' flg_type,
       sp.desc_schedule_type desc_schedule_type,
       re_flg_status
  FROM (
            with sys_info as
            (
            select
            1 id
            , ( select pk_message.get_message(sys_context('ALERT_CONTEXT', 'l_lang'), profissional(sys_context('ALERT_CONTEXT', 'l_prof_id'),sys_context('ALERT_CONTEXT', 'l_prof_institution'),sys_context('ALERT_CONTEXT', 'l_prof_software')), 'REHAB_T148') from dual )  desc_schedule_type
            , sys_context('ALERT_CONTEXT', 'l_lang') sys_lang
            , profissional(sys_context('ALERT_CONTEXT', 'l_prof_id'),sys_context('ALERT_CONTEXT', 'l_prof_institution'),sys_context('ALERT_CONTEXT', 'l_prof_software')) sys_lprof
            ,sys_context('ALERT_CONTEXT', 'l_scfg_rehab_needs_sch') sys_scfg_rehab_needs_sch
            ,sys_context('ALERT_CONTEXT', 'l_flg_sch_type_cr') sys_flg_sch_type_cr
            ,sys_context('ALERT_CONTEXT', 'l_show_med_disch')  sys_show_med_disch
            ,sys_context('ALERT_CONTEXT', 'l_epis_type_rehab_ap')  sys_epis_type_rehab_ap
            , ( select cast( pk_date_utils.get_string_tstz(
              i_lang => sys_context('ALERT_CONTEXT', 'l_lang'),
              i_prof => profissional(sys_context('ALERT_CONTEXT', 'l_prof_id'),sys_context('ALERT_CONTEXT', 'l_prof_institution'),sys_context('ALERT_CONTEXT', 'l_prof_software')),
              i_timestamp => sys_context('ALERT_CONTEXT', 'l_dt_begin'),
              i_timezone  => ''
              ) as timestamp with local time zone ) from dual )sys_dt_begin
            , ( select cast( ( pk_date_utils.get_string_tstz(
              i_lang => sys_context('ALERT_CONTEXT', 'l_lang'),
              i_prof => profissional(sys_context('ALERT_CONTEXT', 'l_prof_id'),sys_context('ALERT_CONTEXT', 'l_prof_institution'),sys_context('ALERT_CONTEXT', 'l_prof_software')),
              i_timestamp => sys_context('ALERT_CONTEXT', 'l_dt_end'),
              i_timezone  => ''
              ) + numtodsinterval(1, 'DAY') + numtodsinterval( -1, 'SECOND') ) as timestamp with local time zone ) from dual ) sys_dt_end
            from dual
            )
            select
              ( select pk_grid.get_schedule_real_state(so.flg_state, epis.flg_ehr) from dual ) sp_real_state
              ,so.id_epis_type
              ,epis.flg_status e_flg_status
              ,epis.id_patient
              ,epis.id_visit
              ,epis.id_episode
              ,re.flg_status  re_flg_status
              ,s.id_schedule
              ,s.dt_begin_tstz
              ,s.dt_schedule_tstz
              ,s.id_schedule id_lock_uq_value
              ,ei.id_software
              ,ei.id_professional
              ,re.id_rehab_epis_encounter
              ,re.id_episode_rehab
              ,re.dt_creation
              , si.sys_lprof
              , si.sys_lang
              ,si.sys_show_med_disch
              ,si.desc_schedule_type
              ,row_number() over ( partition by EPIS.ID_EPISODE order by re.dt_creation desc ) re_rn
            from schedule_outp so
            join sys_info si on si.id = 1
            JOIN epis_type et    ON so.id_epis_type = et.id_epis_type
            JOIN schedule s  ON s.id_schedule = so.id_schedule
            JOIN epis_info ei ON s.id_schedule = ei.id_schedule
            join episode epis ON ei.id_episode = epis.id_episode
            JOIN sch_group sg    ON sg.id_schedule = s.id_schedule
            LEFT JOIN rehab_epis_encounter re   ON re.id_episode_origin = epis.id_episode
          /*
            JOIN rehab_environment r
            ON r.id_epis_type = epis.id_epis_type
            AND r.id_institution = si.sys_lprof.institution
            AND r.id_rehab_environment IN
               (SELECT rep.id_rehab_environment
                FROM rehab_environment_prof rep
               WHERE rep.id_professional = si.sys_lprof.id )
             */
            where so.dt_target_tstz BETWEEN si.sys_dt_begin AND si.sys_dt_end
            and s.flg_sch_type = si.sys_flg_sch_type_cr
            AND s.flg_status != 'V' -- agendamentos temporários (SCH 3.0)
            AND s.flg_status != 'C'
            AND s.id_instit_requested = si.sys_lprof.institution
            AND so.id_epis_type = si.sys_epis_type_rehab_ap
            and rownum > 0
               ) sp
 WHERE sp.sp_real_state != 'M'
 -- cmf
 and nvl(re_rn,1) = 1
 -- cmf
 and ( sp.sys_show_med_disch = 'Y' OR
      ( sp.sys_show_med_disch = 'N' AND sp.sp_real_state != 'D' )
     )
;
