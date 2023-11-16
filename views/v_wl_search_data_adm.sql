CREATE OR REPLACE VIEW v_wl_search_data_adm AS
SELECT
-- campos comuns
 wtl.id_waiting_list idrequisition,
 'W' flgtype,
 wtl.flg_type qtl_flg_type,
 wtl.flg_status,
 wtl.id_patient idpatient,
 round(pk_date_utils.get_timestamp_diff(wtl.dt_dpa, current_timestamp), 0) relative_urgency,
 wtl.dt_reg dtcreation,
 wtl.id_prof_reg idusercreation,
 ar.id_dest_inst idinstitution,
 ar.id_department idservice,
 (SELECT wp.id_prof
    FROM wtl_prof wp
   WHERE wp.id_waiting_list = wtle.id_waiting_list
     AND wp.flg_type = 'A'
     AND wp.flg_status = 'A'
     AND rownum = 1) idresource, -- o admission prof vai aqui
 'H' resourcetype,
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
 table_number(ar.id_dep_clin_serv) iddepclinserv,
 (SELECT table_number(id_clinical_service)
    FROM dep_clin_serv dcsz
   WHERE dcsz.id_dep_clin_serv = ar.id_dep_clin_serv) idspeciality,
 ar.expected_duration expectedduration,
 nvl((SELECT 'Y'
       FROM wtl_epis ft
      WHERE ft.id_waiting_list = wtl.id_waiting_list
        AND ft.id_epis_type = 4
        AND ft.flg_status <> 'S'
        AND rownum = 1),
     'N') hasrequisitiontoschedule,
 -- campos ordenacao. nao remover
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
 NULL           idcontent,
 wtl.dt_surgery dtsugested,
 NULL           admissionneeded,
 NULL           ids_pref_surgeons,
 NULL           icuneeded,
 NULL           pos,
 -- campos wl admission
 ar.id_room_type idroomtype,
 ar.id_bed_type idbedtype,
 ar.id_pref_room idpreferedroom,
 ar.flg_nit nurseintakeneed,
 ar.flg_mixed_nursing mixednursing,
 CASE
      WHEN ar.id_adm_indication = pk_admission_request.get_reason_admission_ft() THEN
       ar.adm_indication_ft
      ELSE
       (SELECT nvl(pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), adin.code_adm_indication),
                   adin.desc_adm_indication)
          FROM adm_indication adin
         WHERE adin.id_adm_indication = ar.id_adm_indication)
  END admindic,
 NULL unavailabilitydatebegin, -- falta
 NULL unavailabilitydateend, -- falta
 NULL dangerofcontamination, -- nao encontro origem
 ar.id_department idadmward, -- fica igual ao campo id_service acima?
 (SELECT id_clinical_service
    FROM dep_clin_serv dcs20
   WHERE dcs20.id_dep_clin_serv = ar.id_dep_clin_serv) idadmclinserv,
 NULL procdiagnosis,
 NULL procsurgeon
  FROM waiting_list wtl
 INNER JOIN wtl_epis wtle
    ON wtl.id_waiting_list = wtle.id_waiting_list
 INNER JOIN adm_request ar
    ON wtle.id_episode = ar.id_dest_episode
 WHERE wtle.id_epis_type = 5
   AND wtle.flg_status <> 'S';
