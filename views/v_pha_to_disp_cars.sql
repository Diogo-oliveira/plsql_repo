CREATE OR REPLACE VIEW V_PHA_TO_DISP_CARS AS
SELECT t.id_presc,
       t.id_patient,
       t.id_presc_type_rel,
       t.id_workflow,
       t.id_status,
       t.id_presc_directions,
       t.dt_first_valid_plan,
       t.dt_create,
       t.id_prof_create,
       t.id_cds,
       t.flg_req_origin_module,
       t.dt_stoptime,
       t.dt_begin,
       t.flg_edited,
       t.dt_end,
       t.id_status_review,
       t.dt_create_dispense,
       t.id_pha_dispense,
       t.id_pha_return,
       t.flg_dispense_type,
       t.dt_birth,
       t.dt_deceased,
       t.gender,
       t.age,
       t.id_department id_department,
       t.id_last_episode,
       listagg(t.name_car_model, '; ' || chr(10)) within GROUP(ORDER BY t.name_car_model) name_car_model,
       (SELECT pk_utils.get_service_desc(i_lang => sys_context('ALERT_CONTEXT', 'i_lang'),
                                         i_id   => t.id_department,
                                         i_mode => 'DEPT_DESC_BY_DPT')
          FROM dual) desc_service,
       t.last_change_dispense_date
  FROM (SELECT vpc.id_presc,
               vpc.id_patient,
               vpc.id_presc_type_rel,
               vpc.id_workflow,
               vpc.id_status,
               vpc.id_presc_directions,
               vpc.dt_first_valid_plan,
               vpc.id_last_episode id_epis_create,
               vpc.dt_create,
               vpc.id_prof_create,
               vpc.id_cds,
               vpc.flg_req_origin_module,
               vpc.dt_stoptime,
               vpc.dt_begin,
               vpc.flg_edited,
               vpc.dt_end,
               vpc.id_status_review,
               vpc.dt_create_dispense,
               vpc.id_pha_dispense,
               vpc.id_pha_return,
               vpc.flg_dispense_type,
               pat.dt_birth dt_birth,
               pat.dt_deceased dt_deceased,
               pat.gender gender,
               pat.age age,
               decode(e.id_department_requested,
                      -1,
                      nvl(r.id_department, dcs.id_department),
                      decode(b.id_bed, NULL, e.id_department_requested, nvl(r.id_department, dcs.id_department))) id_department,
               vpc.id_last_episode,
               pcm.name_car_model name_car_model,
               NULL desc_service,
               nvl(vpc.dt_begin_dispense, vpc.last_change_dispense_date) last_change_dispense_date
          FROM v_disp vpc
          JOIN episode e
            ON e.id_episode = vpc.id_last_episode
          JOIN patient pat
            ON pat.id_patient = vpc.id_patient
          JOIN epis_info ei
            ON ei.id_episode = vpc.id_last_episode
          JOIN dep_clin_serv dcs
            ON (dcs.id_dep_clin_serv = ei.id_dep_clin_serv AND dcs.flg_available = 'Y')
          LEFT JOIN bed b
            ON b.id_bed = ei.id_bed
          LEFT JOIN room r
            ON r.id_room = b.id_room
          JOIN tbl_temp tt
            ON tt.num_1 =
               decode(e.id_department_requested,
                      -1,
                      nvl(r.id_department, dcs.id_department),
                      decode(b.id_bed, NULL, e.id_department_requested, nvl(r.id_department, dcs.id_department)))
          LEFT JOIN v_pha_car_model pcm
            ON pcm.id_pha_car_model = vpc.id_pha_car_model
         WHERE pat.flg_status = 'A'
           AND e.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
           AND e.flg_status IN ('A', 'P')
           AND vpc.id_status_dispense IN (517, 1792)
           AND vpc.id_workflow IN (13, 20)
           AND vpc.id_status NOT IN (55, 68, 60, 64, 65, 70, 72, 95, 98)) t
 GROUP BY id_presc,
          t.id_patient,
          id_presc_type_rel,
          id_workflow,
          id_status,
          id_presc_directions,
          dt_first_valid_plan,
          dt_create,
          id_prof_create,
          id_cds,
          flg_req_origin_module,
          dt_stoptime,
          dt_begin,
          flg_edited,
          dt_end,
          id_status_review,
          dt_create_dispense,
          id_pha_dispense,
          id_pha_return,
          flg_dispense_type,
          dt_birth,
          dt_deceased,
          gender,
          age,
          t.id_department,
          id_last_episode,
          desc_service,
          last_change_dispense_date;