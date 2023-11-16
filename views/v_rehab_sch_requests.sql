CREATE OR REPLACE VIEW V_REHAB_SCH_REQUESTS AS
WITH tf_rehab AS
 (SELECT /*+ materialize */
   *
    FROM TABLE(pk_rehab.find_prof_rehab_areas(alert_context( 'l_prof_id'),
                                              alert_context( 'l_prof_institution'))))
SELECT t.id_patient,
       t.id_episode,
       t.id_epis_type,
       t.code_department,
       t.code_clinical_service,
       t.id_professional,
       t.id_resp_professional,
       t.id_resp_rehab_group,
       t.id_rehab_sch_need,
       t.num_sessions,
       t.num_sessions_pending,
       t.frequency_num,
       t.frequency_time_unit,
       t.dt_begin,
       t.session_notes,
       t.num_clin_record,
       t.id_rehab_session_type,
       t.code_rehab_session_type,
       t.flg_status,
       t.request_id_prof,
       t.dt_rehab_sch_need,
       t.i_lang,
       t.i_prof_id,
       t.i_prof_institution,
       t.i_prof_software,
       (CAST(MULTISET (SELECT DISTINCT ra.id_rehab_area
                FROM rehab_area ra
                JOIN rehab_area_interv rai
                  ON rai.id_rehab_area = ra.id_rehab_area
                JOIN rehab_presc rp
                  ON rp.id_rehab_area_interv = rai.id_rehab_area_interv
               WHERE rp.id_rehab_sch_need = t.id_rehab_sch_need) AS table_number)) AS tbl_id_rehab_area
  FROM (SELECT /*+ opt_estimate(table x rows=1) */
        DISTINCT e.id_patient,
                 e.id_episode,
                 e.id_epis_type,
                 d.code_department,
                 cs.code_clinical_service,
                 rsn.id_professional,
                 rsn.id_resp_professional,
                 rsn.id_resp_rehab_group,
                 rsn.id_rehab_sch_need,
                 rsn.sessions AS num_sessions,
                 (SELECT rsn.sessions - COUNT(*)
                    FROM rehab_schedule rs
                   WHERE rs.id_rehab_sch_need = rsn.id_rehab_sch_need
                     AND rs.flg_status = 'A') AS num_sessions_pending,
                 rsn.frequency AS frequency_num,
                 rsn.flg_frequency AS frequency_time_unit,
                 rsn.dt_begin,
                 rsn.notes AS session_notes,
                 cr.num_clin_record,
                 rst.id_rehab_session_type,
                 rst.code_rehab_session_type,
                 rsn.flg_status,
                 rsn.id_professional AS request_id_prof,
                 rsn.dt_rehab_sch_need,
                 alert_context( 'l_lang') i_lang,
                 alert_context( 'l_prof_id') i_prof_id,
                 alert_context( 'l_prof_institution') i_prof_institution,
                 alert_context( 'l_prof_software') i_prof_software
          FROM rehab_sch_need rsn
          JOIN (SELECT DISTINCT rsn.id_rehab_sch_need id_rehab_sch_needd
                 FROM rehab_presc rp
                 JOIN rehab_sch_need rsn
                   ON rp.id_rehab_sch_need = rsn.id_rehab_sch_need
                WHERE rp.id_institution = rp.id_exec_institution
                  AND rp.id_institution = alert_context( 'l_prof_institution')) rp
            ON rsn.id_rehab_sch_need = rp.id_rehab_sch_needd
          JOIN rehab_presc rpres
            ON rpres.id_rehab_sch_need = rsn.id_rehab_sch_need
          JOIN rehab_area_interv rai
            ON rai.id_rehab_area_interv = rpres.id_rehab_area_interv
          LEFT JOIN tf_rehab x
            ON x.id_rehab_area = rai.id_rehab_area
          JOIN rehab_session_type rst
            ON rst.id_rehab_session_type = rsn.id_rehab_session_type
          JOIN episode e
            ON e.id_episode = rsn.id_episode_origin
          JOIN clinical_service cs
            ON cs.id_clinical_service = e.id_cs_requested
          JOIN epis_info ei
            ON ei.id_episode = e.id_episode
          LEFT JOIN room r
            ON r.id_room = ei.id_room
          LEFT JOIN department d
            ON d.id_department = r.id_department
          LEFT JOIN clin_record cr
            ON cr.id_episode = e.id_episode
         WHERE rsn.flg_status = 'W'
           AND rpres.id_rehab_presc IN (SELECT rpc.id_rehab_presc
                                          FROM rehab_presc rpc
                                         WHERE rpc.id_rehab_sch_need = rsn.id_rehab_sch_need
                                           AND rpc.flg_status not in ( 'D', 'C')
                                           AND rownum = 1)
           /*AND (alert_context( 'l_id_category') = 4 OR
               (alert_context( 'l_id_category') = 24 OR
               (rsn.id_resp_professional IS NOT NULL AND
               rsn.id_resp_professional = alert_context( 'l_prof_id')) OR
               (rsn.id_resp_rehab_group IS NOT NULL AND
               rsn.id_resp_rehab_group IN
               (SELECT id_rehab_group
                     FROM rehab_group_prof rgp
                    WHERE rgp.id_professional = alert_context( 'l_prof_id')))))*/
           AND ((alert_context( 'l_id_category') NOT IN (4, 23, 24) OR (x.id_rehab_area IS NOT NULL)))) t
UNION ALL
-- union all com agendados mas count diferente do numero de sessoes e que não tenham sido agendados hoje
SELECT t.id_patient,
       t.id_episode,
       t.id_epis_type,
       t.code_department,
       t.code_clinical_service,
       t.id_professional,
       t.id_resp_professional,
       t.id_resp_rehab_group,
       t.id_rehab_sch_need,
       t.num_sessions,
       t.num_sessions_pending,
       t.frequency_num,
       t.frequency_time_unit,
       t.dt_begin,
       t.session_notes,
       t.num_clin_record,
       t.id_rehab_session_type,
       t.code_rehab_session_type,
       t.flg_status,
       t.request_id_prof,
       t.dt_rehab_sch_need,
       t.i_lang,
       t.i_prof_id,
       t.i_prof_institution,
       t.i_prof_software,
       (CAST(MULTISET (SELECT DISTINCT ra.id_rehab_area
                FROM rehab_area ra
                JOIN rehab_area_interv rai
                  ON rai.id_rehab_area = ra.id_rehab_area
                JOIN rehab_presc rp
                  ON rp.id_rehab_area_interv = rai.id_rehab_area_interv
               WHERE rp.id_rehab_sch_need = t.id_rehab_sch_need) AS table_number)) AS tbl_id_rehab_area
  FROM (SELECT /*+ opt_estimate(table x rows=1) */
        DISTINCT e.id_patient,
                 e.id_episode,
                 e.id_epis_type,
                 d.code_department,
                 cs.code_clinical_service,
                 rsn.id_professional,
                 rsn.id_resp_rehab_group,
                 rsn.id_resp_professional,
                 rsn.id_rehab_sch_need,
                 rsn.sessions AS num_sessions,
                 (SELECT rsn.sessions - COUNT(*)
                    FROM rehab_schedule rs
                   WHERE rs.id_rehab_sch_need = rsn.id_rehab_sch_need
                     AND rs.flg_status = 'A') AS num_sessions_pending,
                 rsn.frequency AS frequency_num,
                 rsn.flg_frequency AS frequency_time_unit,
                 rsn.dt_begin,
                 rsn.notes AS session_notes,
                 cr.num_clin_record,
                 rst.id_rehab_session_type,
                 rst.code_rehab_session_type,
                 rsn.flg_status,
                 rsn.id_professional AS request_id_prof,
                 rsn.dt_rehab_sch_need,
                 alert_context( 'l_lang') i_lang,
                 alert_context( 'l_prof_id') i_prof_id,
                 alert_context( 'l_prof_institution') i_prof_institution,
                 alert_context( 'l_prof_software') i_prof_software
          FROM rehab_sch_need rsn
          JOIN (SELECT DISTINCT rsn.id_rehab_sch_need id_rehab_sch_needd
                 FROM rehab_presc rp
                 JOIN rehab_sch_need rsn
                   ON rp.id_rehab_sch_need = rsn.id_rehab_sch_need
                WHERE rp.id_institution = rp.id_exec_institution
                  AND rp.id_institution = alert_context( 'l_prof_institution')) rp
            ON rsn.id_rehab_sch_need = rp.id_rehab_sch_needd
          JOIN rehab_presc rpres
            ON rpres.id_rehab_sch_need = rsn.id_rehab_sch_need
          JOIN rehab_area_interv rai
            ON rai.id_rehab_area_interv = rpres.id_rehab_area_interv
          LEFT JOIN tf_rehab x
            ON x.id_rehab_area = rai.id_rehab_area
          JOIN rehab_session_type rst
            ON rst.id_rehab_session_type = rsn.id_rehab_session_type
          JOIN episode e
            ON e.id_episode = rsn.id_episode_origin
          JOIN clinical_service cs
            ON cs.id_clinical_service = e.id_cs_requested
          JOIN epis_info ei
            ON ei.id_episode = e.id_episode
          LEFT JOIN room r
            ON r.id_room = ei.id_room
          LEFT JOIN department d
            ON d.id_department = r.id_department
          LEFT JOIN clin_record cr
            ON cr.id_episode = e.id_episode
          LEFT JOIN rehab_schedule rs
            ON rs.id_rehab_sch_need = rsn.id_rehab_sch_need
          LEFT JOIN schedule s
            ON s.id_schedule = rs.id_schedule
           AND s.flg_status NOT IN ('C', 'D')
           AND s.dt_schedule_tstz BETWEEN cast( current_timestamp  as timestamp with local time zone ) AND cast( (current_timestamp + numtodsinterval(1, 'DAY')) as timestamp with local time zone )
         WHERE rsn.flg_status = 'S'
           AND rsn.sessions > (SELECT COUNT(*)
                                 FROM rehab_schedule rs
                                WHERE rs.id_rehab_sch_need = rsn.id_rehab_sch_need)
           AND rpres.id_rehab_presc IN (SELECT rpc.id_rehab_presc
                                          FROM rehab_presc rpc
                                         WHERE rpc.id_rehab_sch_need = rsn.id_rehab_sch_need
                                           AND rpc.flg_status not in ( 'D', 'C')
                                           AND rownum = 1)
           AND s.id_schedule IS NULL
           /*AND (alert_context( 'l_id_category') = 4 OR
               (alert_context( 'l_id_category') <> 23 OR
               (rsn.id_resp_professional IS NOT NULL AND
               rsn.id_resp_professional = alert_context( 'l_prof_id')) OR
               (rsn.id_resp_rehab_group IS NOT NULL AND
               rsn.id_resp_rehab_group IN
               (SELECT id_rehab_group
                     FROM rehab_group_prof rgp
                    WHERE rgp.id_professional = alert_context( 'l_prof_id')))))*/
           AND ((alert_context( 'l_id_category') NOT IN (4, 23, 24) OR (x.id_rehab_area IS NOT NULL)))) t
UNION ALL
--Patients scheduled for today
SELECT t.id_patient,
       t.id_episode,
       t.id_epis_type,
       t.code_department,
       t.code_clinical_service,
       t.id_professional,
       t.id_resp_rehab_group,
       t.id_resp_professional,
       t.id_rehab_sch_need,
       t.num_sessions,
       t.num_sessions_pending,
       t.frequency_num,
       t.frequency_time_unit,
       t.dt_begin,
       t.session_notes,
       t.num_clin_record,
       t.id_rehab_session_type,
       t.code_rehab_session_type,
       t.flg_status,
       t.request_id_prof,
       t.dt_rehab_sch_need,
       t.i_lang,
       t.i_prof_id,
       t.i_prof_institution,
       t.i_prof_software,
       (CAST(MULTISET (SELECT DISTINCT ra.id_rehab_area
                FROM rehab_area ra
                JOIN rehab_area_interv rai
                  ON rai.id_rehab_area = ra.id_rehab_area
                JOIN rehab_presc rp
                  ON rp.id_rehab_area_interv = rai.id_rehab_area_interv
               WHERE rp.id_rehab_sch_need = t.id_rehab_sch_need) AS table_number)) AS tbl_id_rehab_area
  FROM (SELECT /*+ opt_estimate(table x rows=1) */
        DISTINCT e.id_patient,
                 e.id_episode,
                 e.id_epis_type,
                 d.code_department,
                 cs.code_clinical_service,
                 rsn.id_professional,
                 rsn.id_resp_rehab_group,
                 rsn.id_resp_professional,
                 rsn.id_rehab_sch_need,
                 rsn.sessions AS num_sessions,
                 (SELECT rsn.sessions - COUNT(*)
                    FROM rehab_schedule rs
                   WHERE rs.id_rehab_sch_need = rsn.id_rehab_sch_need
                     AND rs.flg_status = 'A') AS num_sessions_pending,
                 rsn.frequency AS frequency_num,
                 rsn.flg_frequency AS frequency_time_unit,
                 rsn.dt_begin,
                 rsn.notes AS session_notes,
                 cr.num_clin_record,
                 rst.id_rehab_session_type,
                 rst.code_rehab_session_type,
                 rsn.flg_status,
                 rsn.id_professional AS request_id_prof,
                 rsn.dt_rehab_sch_need,
                 alert_context( 'l_lang') i_lang,
                 alert_context( 'l_prof_id') i_prof_id,
                 alert_context( 'l_prof_institution') i_prof_institution,
                 alert_context( 'l_prof_software') i_prof_software
          FROM rehab_sch_need rsn
          JOIN (SELECT DISTINCT rsn.id_rehab_sch_need id_rehab_sch_needd
                 FROM rehab_presc rp
                 JOIN rehab_sch_need rsn
                   ON rp.id_rehab_sch_need = rsn.id_rehab_sch_need
                WHERE rp.id_institution = rp.id_exec_institution
                  AND rp.id_institution = alert_context( 'l_prof_institution')) rp
            ON rsn.id_rehab_sch_need = rp.id_rehab_sch_needd
          JOIN rehab_presc rpres
            ON rpres.id_rehab_sch_need = rsn.id_rehab_sch_need
          JOIN rehab_area_interv rai
            ON rai.id_rehab_area_interv = rpres.id_rehab_area_interv
          LEFT JOIN tf_rehab x
            ON x.id_rehab_area = rai.id_rehab_area
          JOIN rehab_session_type rst
            ON rst.id_rehab_session_type = rsn.id_rehab_session_type
          JOIN episode e
            ON e.id_episode = rsn.id_episode_origin
          JOIN clinical_service cs
            ON cs.id_clinical_service = e.id_cs_requested
          JOIN epis_info ei
            ON ei.id_episode = e.id_episode
          LEFT JOIN room r
            ON r.id_room = ei.id_room
          LEFT JOIN department d
            ON d.id_department = r.id_department
          LEFT JOIN clin_record cr
            ON cr.id_episode = e.id_episode
          LEFT JOIN rehab_schedule rs
            ON rs.id_rehab_sch_need = rsn.id_rehab_sch_need
          LEFT JOIN schedule s
            ON s.id_schedule = rs.id_schedule
           AND s.flg_status NOT IN ('C', 'D')
           AND s.dt_schedule_tstz BETWEEN cast( current_timestamp  as timestamp with local time zone ) AND cast( (current_timestamp + numtodsinterval(1, 'DAY')) as timestamp with local time zone )
         WHERE rsn.flg_status = 'S'
           AND s.id_schedule IS NOT NULL
           AND rpres.id_rehab_presc IN (SELECT rpc.id_rehab_presc
                                          FROM rehab_presc rpc
                                         WHERE rpc.id_rehab_sch_need = rsn.id_rehab_sch_need
                                           AND rpc.flg_status not in ( 'D', 'C')
                                           AND rownum = 1)
           /*AND (alert_context( 'l_id_category') = 4 OR
               (alert_context( 'l_id_category') <> 23 OR
               (rsn.id_resp_professional IS NOT NULL AND
               rsn.id_resp_professional = alert_context( 'l_prof_id')) OR
               (rsn.id_resp_rehab_group IS NOT NULL AND
               rsn.id_resp_rehab_group IN
               (SELECT id_rehab_group
                     FROM rehab_group_prof rgp
                    WHERE rgp.id_professional = alert_context( 'l_prof_id')))))*/
           AND ((alert_context( 'l_id_category') NOT IN (4, 23, 24) OR (x.id_rehab_area IS NOT NULL)))) t
;