CREATE OR REPLACE VIEW V_PHA_DISPENSED AS
SELECT vd.id_presc,
       vd.id_patient,
       (SELECT pk_patient.get_pat_name(e.sys_lang,
                                       profissional(e.sys_prof_id, e.sys_institution, e.sys_software),
                                       vd.id_patient,
                                       e.id_episode)
          FROM dual) patient_name,
       (SELECT pk_patient.get_pat_name_to_sort(e.sys_lang,
                                               profissional(e.sys_prof_id, e.sys_institution, e.sys_software),
                                               vd.id_patient,
                                               e.id_episode)
          FROM dual) patient_name_to_sort,
       (SELECT pk_api_pfh_in.get_prod_desc_by_presc(e.sys_lang,
                                                    profissional(e.sys_prof_id, e.sys_institution, e.sys_software),
                                                    vd.id_presc)
          FROM dual) desc_product,
       vd.id_presc_type_rel,
       vd.id_workflow,
       vd.id_status,
       vd.id_presc_directions,
       vd.dt_first_valid_plan,
       vd.id_epis_create,
       vd.dt_create,
       vd.id_prof_create,
       vd.id_cds,
       vd.flg_req_origin_module,
       vd.dt_stoptime,
       vd.dt_begin,
       vd.flg_edited,
       vd.dt_end,
       nvl(vd.dt_begin_dispense, vd.last_change_dispense_date) last_change_dispense_date,
       vd.last_change_dispense_prof,
       vd.id_status_review,
       vd.dt_create_dispense,
       vd.id_pha_dispense,
       vd.id_pha_return,
       vd.flg_dispense_type,
       pat.dt_birth dt_birth,
       pat.dt_deceased dt_deceased,
       pat.gender gender,
       pat.age age,
       pcm.id_pha_car_model id_pha_car_model,
       pcm.name_car_model name_car_model,
       pcm.id_department,
       vd.id_last_episode,
       (SELECT pk_utils.get_service_desc(i_lang => sys_context('ALERT_CONTEXT', 'i_lang'),
                                         i_id   => pcm.id_department,
                                         i_mode => 'DEPT_DESC_BY_DPT')
          FROM dual) desc_service
  FROM v_disp vd
  JOIN (SELECT sys_context('ALERT_CONTEXT', 'i_institution') sys_institution,
               sys_context('ALERT_CONTEXT', 'i_lang') sys_lang,
               sys_context('ALERT_CONTEXT', 'i_software') sys_software,
               sys_context('ALERT_CONTEXT', 'i_prof_id') sys_prof_id,
               epis.id_episode
          FROM epis_info epis) e
    ON e.id_episode = vd.id_epis_create
  JOIN episode ei
    ON e.id_episode = ei.id_episode
  JOIN visit v
    ON v.id_visit = ei.id_visit
  JOIN patient pat
    ON pat.id_patient = v.id_patient
  JOIN v_pha_car_model pcm
    ON pcm.id_pha_car_model = vd.id_pha_car_model
  JOIN tbl_temp tt
    ON tt.num_1 = pcm.id_pha_car_model
 WHERE v.id_institution = e.sys_institution
   AND vd.id_status_dispense IN (518, 522);
