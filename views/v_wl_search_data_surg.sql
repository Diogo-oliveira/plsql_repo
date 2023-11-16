CREATE OR REPLACE VIEW v_wl_search_data_surg AS
SELECT
-- campos comuns
 wtl.id_waiting_list idrequisition,
 'W' flgtype,
 wtl.flg_type qtl_flg_type,
 wtl.flg_status,
 wtl.id_patient idpatient,
 trunc(pk_date_utils.diff_timestamp(wtl.dt_dpa, current_timestamp)) relative_urgency,
 wtl.dt_reg dtcreation,
 wtl.id_prof_reg idusercreation,
 schs.id_institution idinstitution,
 schs.id_dept_dest idservice,
 NULL idresource,
 NULL resourcetype,
 wtl.dt_dpb dtbeginmin,
 wtl.dt_dpa dtbeginmax,
 NULL flgcontacttype,
 NULL priority,
 (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), wul.code)
    FROM wtl_urg_level wul
   WHERE wul.id_wtl_urg_level = wtl.id_wtl_urg_level) urgencylevel,
 NULL idlanguage,
 NULL idmotive,
 NULL motivetype,
 NULL motivedescription,
 NULL sessionnumber,
 NULL frequencyunit,
 NULL frequency,
 CAST(MULTISET (SELECT DISTINCT wdcs.id_dep_clin_serv
         FROM wtl_dep_clin_serv wdcs
        WHERE wdcs.id_waiting_list = wtle.id_waiting_list
          AND wdcs.id_episode = wtle.id_episode
          AND wdcs.flg_status = 'A') AS table_number) iddepclinserv,
 CAST(MULTISET (SELECT DISTINCT dcss.id_clinical_service
         FROM wtl_dep_clin_serv wdcs
         JOIN dep_clin_serv dcss
           ON wdcs.id_dep_clin_serv = dcss.id_dep_clin_serv
        WHERE wdcs.id_waiting_list = wtle.id_waiting_list
          AND wdcs.id_episode = wtle.id_episode
          AND wdcs.flg_status = 'A') AS table_number) idspeciality,
 round(nvl(schs.duration, 0) / 60, 2) expectedduration,
 nvl((SELECT 'Y'
       FROM wtl_epis ft
      WHERE ft.id_waiting_list = wtl.id_waiting_list
        AND ft.id_epis_type = 5
        AND ft.flg_status <> 'S'
        AND rownum = 1),
     'N') hasrequisitiontoschedule,
 -- campos para a ordenacao. nao remover
 pk_date_utils.get_timestamp_diff(wtl.dt_dpa, current_timestamp) sk_relative_urgency,
 pk_date_utils.get_timestamp_diff(wtl.dt_dpa, wtl.dt_placement) sk_absolute_urgency,
 pk_date_utils.get_timestamp_diff(current_timestamp, wtl.dt_placement) sk_waiting_time,
 (SELECT wul.duration
    FROM wtl_urg_level wul
   WHERE wul.id_wtl_urg_level = wtl.id_wtl_urg_level) sk_urgency_level,
 (wtl.func_eval_score * -1) sk_barthel,
 nvl((SELECT g.rank
       FROM patient p
      INNER JOIN (SELECT *
                   FROM TABLE(pk_wtl_prv_core.get_sort_keys_children(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                     profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                                                  sys_context('ALERT_CONTEXT',
                                                                                              'i_institution'),
                                                                                  sys_context('ALERT_CONTEXT',
                                                                                              'i_software')),
                                                                     sys_context('ALERT_CONTEXT', 'l_inst'),
                                                                     sys_context('ALERT_CONTEXT', 'l_wtlsk_gender')))) g
         ON g.value = p.gender
      WHERE p.id_patient = wtl.id_patient),
     0) sk_gender,
 -- campos wl surgery
 pk_wtl_pbl_core.get_sr_proc_id_content_string(sys_context('ALERT_CONTEXT', 'i_lang'),
                                               profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                            sys_context('ALERT_CONTEXT', 'i_institution'),
                                                            sys_context('ALERT_CONTEXT', 'i_software')),
                                               wtl.id_waiting_list) idcontent,
 wtl.dt_surgery dtsugested,
 schs.adm_needed admissionneeded,
 CAST(MULTISET (SELECT DISTINCT wp.id_prof
         FROM wtl_prof wp
        WHERE wp.id_waiting_list = wtle.id_waiting_list
          AND wp.flg_type = 'S'
          AND wp.flg_status = 'A') AS table_number) ids_pref_surgeons,
 schs.icu icuneeded,
 CASE (SELECT COUNT(1)
     FROM sr_pos_schedule sps
    WHERE sps.id_schedule_sr = schs.id_schedule_sr
      AND sps.flg_status = 'A')
     WHEN 0 THEN
      'N'
     ELSE
      'S'
 END pos,
 -- campos wl admission
 NULL idroomtype,
 NULL idbedtype,
 NULL idpreferedroom,
 NULL nurseintakeneed,
 NULL mixednursing,
 NULL admindic,
 NULL unavailabilitydatebegin,
 NULL unavailabilitydateend,
 NULL dangerofcontamination,
 NULL idadmward,
 NULL idadmclinserv,
 pk_wtl_pbl_core.get_procedure_diagnosis_string(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                             sys_context('ALERT_CONTEXT', 'i_institution'),
                                                             sys_context('ALERT_CONTEXT', 'i_software')),
                                                wtle.id_waiting_list) procdiagnosis,
 pk_wtl_pbl_core.get_proc_main_surgeon_string(sys_context('ALERT_CONTEXT', 'i_lang'),
                                              profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                           sys_context('ALERT_CONTEXT', 'i_institution'),
                                                           sys_context('ALERT_CONTEXT', 'i_software')),
                                              wtle.id_waiting_list) procsurgeon
  FROM waiting_list wtl
 INNER JOIN wtl_epis wtle
    ON wtle.id_waiting_list = wtl.id_waiting_list
 INNER JOIN schedule_sr schs
    ON schs.id_waiting_list = wtle.id_waiting_list
 WHERE wtle.id_epis_type = 4
   AND wtle.flg_status <> 'S';
