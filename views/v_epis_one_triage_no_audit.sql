CREATE OR REPLACE view v_epis_one_triage_no_audit AS
    SELECT e.id_episode,
           e.id_visit,
           e.id_clinical_service,
           e.dt_begin_tstz,
           nvl(e.dt_end_tstz,
               (SELECT e2.dt_begin_tstz
                  FROM episode e2
                 WHERE e2.id_prev_episode = e.id_episode
                   AND e2.dt_begin_tstz IS NOT NULL
                   AND rownum < 2)) dt_end,
           nvl(e.dt_end_tstz,
               (SELECT e2.dt_begin_tstz
                  FROM episode e2
                 WHERE e2.id_prev_episode = e.id_episode
                   AND e2.dt_begin_tstz IS NOT NULL
                   AND rownum < 2)) dt_end_tstz,
           e.flg_status,
           e.id_epis_type,
           e.barcode,
           e.flg_type,
           etr.id_epis_triage,
           etr.id_triage_color,
           etr.id_triage,
           t.id_triage_type,
           etr.id_professional id_prof_triage,
           etr.id_room,
           etr.id_triage_nurse,
           etr.pain_scale,
           etr.dt_end_tstz dt_end_triage_tstz,
           ti.id_institution_origin,
           (SELECT COUNT(0)
              FROM epis_triage etr2
             WHERE etr2.id_episode = etr.id_episode) cnt_triage
      FROM episode e, epis_triage etr, triage t, transfer_institution ti
     WHERE e.flg_status IN ('I')
       AND e.id_epis_type IN (2, 9)
       AND ((e.dt_end_tstz IS NOT NULL) OR
           (EXISTS (SELECT e2.dt_begin_tstz
                       FROM episode e2
                      WHERE e2.id_prev_episode = e.id_episode)))
       AND etr.id_episode = e.id_episode
       AND etr.dt_end_tstz = (SELECT MIN(etr2.dt_end_tstz)
                                FROM epis_triage etr2
                               WHERE etr2.id_episode = e.id_episode)
       AND e.id_episode = ti.id_episode(+)
       AND ti.flg_status(+) = 'F'
       AND (ti.dt_end_tstz = (SELECT MIN(ti2.dt_end_tstz)
                                FROM transfer_institution ti2
                               WHERE ti2.id_episode = e.id_episode
                                 AND ti2.dt_end_tstz > etr.dt_end_tstz) OR ti.id_episode IS NULL)
       AND EXISTS
     (SELECT 0
              FROM epis_info ei
             WHERE ei.id_episode = e.id_episode
               AND (nvl(ei.flg_unknown, 'N') != 'Y' OR pk_sysconfig.get_config('AUDIT_ALLOW_TEMP_EPIS', 0, 0) = 'Y'))
       AND t.id_triage = etr.id_triage
       AND etr.id_epis_triage NOT IN (SELECT ae.id_epis_triage
                                        FROM audit_req_prof_epis ae, audit_req_prof ap, audit_req ar
                                       WHERE ae.id_audit_req_prof = ap.id_audit_req_prof
                                         AND ar.id_audit_req = ap.id_audit_req
                                         AND ar.flg_status <> 'C');
/
