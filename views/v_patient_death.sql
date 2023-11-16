CREATE OR REPLACE VIEW V_PATIENT_DEATH AS
SELECT id_patient,
       id_episode,
       id_institution,
       id_death_registry,
       dt_death_registry,
       pk_date_utils.date_send_tsz(i_lang => id_lang,
                                   i_date => dt_death_registry,
                                   i_inst => id_institution,
                                   i_soft => 0) dt_death_registry_str,
       dt_end_tstz,
       pk_date_utils.date_send_tsz(i_lang => id_lang, i_date => dt_end_tstz, i_inst => id_institution, i_soft => 0) dt_end_tstz_str,
       pk_adt.get_rb_reg_classifier_code(i_rb_reg_class => id_rb_regional_classifier, i_rank => 5) cedocapt,
       death_data_folio deffolio,
       death_data_folio_control deffolioco,
       first_name defnombre,
       last_name defapepater,
       middle_name defapemater,
       pk_patient.get_patient_ssn(id_lang, profissional(NULL, id_institution, NULL), i_patient => id_patient) defcurp,
       --social_security_number defcurp,
       gender defsexo,
       defnacion,
       country_hab,
       leng_indig,
       CASE
            WHEN dr_known_weight = 'Y' THEN
             to_char(trunc(weight_gr / 1000), '000')
            WHEN dr_known_weight = 'N' THEN
             '888'
            WHEN dr_known_weight = 'NO' THEN
             '999'
            ELSE
             NULL
        END defpesokg,
       CASE
            WHEN dr_known_weight = 'Y' THEN
             to_char(weight_gr - (trunc(weight_gr / 1000) * 1000), '000')
            WHEN dr_known_weight = 'N' THEN
             '888'
            WHEN dr_known_weight = 'NO' THEN
             '999'
            ELSE
             NULL
        END defpesom,
       dr_known_height,
       CASE
            WHEN dr_known_height = 'Y' THEN
             trunc(height_cm / 100)
            WHEN dr_known_height = 'NE' THEN
             8
            ELSE
             9
        END deftalla_mt,
       CASE
            WHEN dr_known_height = 'Y' THEN
             height_cm - (trunc(height_cm / 100) * 100)
            WHEN dr_known_height = 'NE' THEN
             88
            ELSE
             99
        END deftalla_cm,
       pk_patient.get_partial_pat_age(i_lang    => 17,
                                      i_prof    => profissional(0, id_institution, 0),
                                      i_patient => id_patient) deffech_nac,
       type_age defclv_eda,
       decode(type_age,
              NULL,
              NULL,
              pk_patient.get_pat_age_num(i_lang    => NULL,
                                         i_prof    => profissional(NULL, id_institution, NULL),
                                         i_patient => id_patient,
                                         i_type    => type_age)) defedad,
       /* birth certificate deffol_cn */
       death_data_folio_birth,
       decode(death_data_folio_birth,
              NULL,
              pk_death_registry.check_folio_birth_value(i_lang    => id_lang,
                                                        i_prof    => profissional(NULL, id_institution, 0),
                                                        i_patient => id_patient,i_flg_origin => 'Y'),
              death_data_folio_birth) deffol_cn,
       marital_status defedo_civ,
       pk_adt.get_patient_address(id_lang, id_person) defdom_hab,
       patient_colony_address defcol_hab,
       defent_hab,
       defdel_hab,
       defloc_hab,
       defescolar,
       defocupaci,
       flg_job_status deftrabaja,
       pk_adt.get_health_plan_field_mx(i_episode => id_episode, i_flg_main => 'Y', i_field_to_show => 'ID_CONTENT') defderecho,
       pk_adt.get_health_plan_field_mx(i_episode       => id_episode,
                                       i_flg_main      => 'Y',
                                       i_field_to_show => 'AFFILIATION_NUMBER') defafil_dh,
       pk_adt.get_health_plan_field_mx(i_episode => id_episode, i_flg_main => 'N', i_field_to_show => 'ID_CONTENT') defderecho2,
       death_data_ocurrence defsitio,
       death_data_institution,
       death_registry_clues_code,
       pk_adt.get_clues_name(i_id_clues => NULL, i_id_institution => death_registry_clues_code) defunimed,
       pk_adt.get_clues_code(i_id_clues => NULL, i_id_institution => death_registry_clues_code) defclues,
       -- colony
       pk_death_registry.get_mx_name_from_list(i_lang     => id_lang,
                                               i_prof     => profissional(NULL, id_institution, 0),
                                               i_value    => dr_death_known_address,
                                               i_name     => death_data_adrress_number,
                                               i_flag     => 'TT',
                                               i_group_id => 15542 /*, i_id_ne => 11555 */) defdom_def,
       pk_death_registry.get_mx_name_from_list(i_lang     => id_lang,
                                               i_prof     => profissional(NULL, id_institution, 0),
                                               i_value    => dr_death_known_address,
                                               i_name     => death_data_adrress_colony,
                                               i_flag     => 'TT',
                                               i_group_id => 15542,
                                               i_id_ne    => 11555) defcol_def,
       --         death_data_adrress_number   defdom_def,
       death_data_adrress_entity defent_def,
       death_data_adrress_municipy defdel_def,
       death_data_adrress_location defloc_def,
       death_data_address_jurisd defjur_def,
       pk_date_utils.date_send_tsz(id_lang, dt_death, profissional(NULL, id_institution, 0)) defdata_str,
       -- pk_death_registry.get_death_data( id_lang , profissional(0, id_institution, 0), dr_death_date_exists, dt_death, death_date_format) defdata
       -- dt_death defdata,
       death_date_format,
       dr_death_date_exists,
       'DEPRECATED' defdata,
       pk_dynamic_screen.process_mx_partial_dt(i_lang      => id_lang,
                                               i_prof      => profissional(NULL, id_institution, 0),
                                               i_dt_exists => dr_death_date_exists,
                                               i_value     => dt_death,
                                               i_dt_format => death_date_format) deffech_def,
       --  pk_date_utils.dt_chr_tsz(17, dt_death, id_institution, 0) deffech_def,
       --to_char(dt_death, 'DD/MM/YYYY') deffech_def ,
      -- pk_date_utils.dt_chr_hour_tsz(id_lang, dt_death, id_institution, 0) defhora,
      pk_dynamic_screen.process_mx_partial_dt(i_lang       => id_lang,
                                               i_prof      => profissional(NULL, id_institution, 0),
                                               i_dt_exists => dr_death_date_exists,
                                               i_value     => dt_death,
                                               i_dt_format => death_date_format,
                                               i_type      => 'H') defhora,
       death_data_medical_atention defatencio,
       death_data_necropsy defnecrops,
       death_data_cause_desc_1 descausa1,
       cause_2 causa1,
       --death_data_time_illness1,
       death_tipo_dt_defuncion,
       -- substr(death_data_time_illness1, 1, instr(death_data_time_illness1, '|') - 1) tiempo_c1,
       pk_death_registry.get_data_time_illness(i_lang => id_lang,
                                               i_prof => profissional(NULL, id_institution, 0),
                                               i_mode => 'T',
                                               i_tipo => death_tipo_dt_defuncion,
                                               i_data => death_data_time_illness1) tiempo_c1,
       -- substr(death_data_time_illness1, instr(death_data_time_illness1, '|') + 1) cvetpo_c1,
       pk_death_registry.get_data_time_illness(i_lang => id_lang,
                                               i_prof => profissional(NULL, id_institution, 0),
                                               i_mode => 'C',
                                               i_tipo => death_tipo_dt_defuncion,
                                               i_data => death_data_time_illness1) cvetpo_c1,
     --  substr(cause_2, 1, instr(cause_2, '|') - 1) causa1,
       death_data_cause_desc_2 descausa2,
       cause_3 causa2,
       --substr(death_data_time_illness2, 1, instr(death_data_time_illness2, '|') - 1) tiempo_c2,
       pk_death_registry.get_data_time_illness(i_lang => id_lang,
                                               i_prof => profissional(NULL, id_institution, 0),
                                               i_mode => 'T',
                                               i_tipo => death_tipo_dt_defuncion_2,
                                               i_data => death_data_time_illness2) tiempo_c2,
       --substr(death_data_time_illness2, instr(death_data_time_illness2, '|') + 1) cvetpo_c2,
       pk_death_registry.get_data_time_illness(i_lang => id_lang,
                                               i_prof => profissional(NULL, id_institution, 0),
                                               i_mode => 'C',
                                               i_tipo => death_tipo_dt_defuncion_2,
                                               i_data => death_data_time_illness2) cvetpo_c2,
   --    substr(cause_3, 1, instr(cause_2, '|') - 1) causa2,
       death_data_cause_desc_3 descausa3,
       cause_4 causa3,
       --substr(death_data_time_illness3, 1, instr(death_data_time_illness3, '|') - 1) tiempo_c3,
       pk_death_registry.get_data_time_illness(i_lang => id_lang,
                                               i_prof => profissional(NULL, id_institution, 0),
                                               i_mode => 'T',
                                               i_tipo => death_tipo_dt_defuncion_3,
                                               i_data => death_data_time_illness3) tiempo_c3,
       --substr(death_data_time_illness3, instr(death_data_time_illness3, '|') + 1) cvetpo_c3,
       pk_death_registry.get_data_time_illness(i_lang => id_lang,
                                               i_prof => profissional(NULL, id_institution, 0),
                                               i_mode => 'C',
                                               i_tipo => death_tipo_dt_defuncion_3,
                                               i_data => death_data_time_illness3) cvetpo_c3,
     --  substr(cause_4, 1, instr(cause_4, '|') - 1) causa3,
       death_data_cause_desc_4 descausa4,
       cause_5 causa4,
       -- substr(death_data_time_illness4, 1, instr(death_data_time_illness4, '|') - 1) tiempo_c4,
       pk_death_registry.get_data_time_illness(i_lang => id_lang,
                                               i_prof => profissional(NULL, id_institution, 0),
                                               i_mode => 'T',
                                               i_tipo => death_tipo_dt_defuncion_4,
                                               i_data => death_data_time_illness4) tiempo_c4,
       --substr(death_data_time_illness4, instr(death_data_time_illness4, '|') + 1) cvetpo_c4,
       pk_death_registry.get_data_time_illness(i_lang => id_lang,
                                               i_prof => profissional(NULL, id_institution, 0),
                                               i_mode => 'C',
                                               i_tipo => death_tipo_dt_defuncion_4,
                                               i_data => death_data_time_illness4) cvetpo_c4,
    --   substr(cause_5, 1, instr(cause_5, '|') - 1) causa4,
       death_data_cause_desc_5 descausa5,
       cause_6 causa5,
       -- substr(death_data_time_illness5, 1, instr(death_data_time_illness5, '|') - 1) tiempo_c5,
       pk_death_registry.get_data_time_illness(i_lang => id_lang,
                                               i_prof => profissional(NULL, id_institution, 0),
                                               i_mode => 'T',
                                               i_tipo => death_tipo_dt_defuncion_5,
                                               i_data => death_data_time_illness5) tiempo_c5,
       --substr(death_data_time_illness5, instr(death_data_time_illness5, '|') + 1) cvetpo_c5,
       pk_death_registry.get_data_time_illness(i_lang => id_lang,
                                               i_prof => profissional(NULL, id_institution, 0),
                                               i_mode => 'C',
                                               i_tipo => death_tipo_dt_defuncion_5,
                                               i_data => death_data_time_illness5) cvetpo_c5,
--       substr(cause_6, 1, instr(cause_6, '|') - 1) causa5,
       death_data_cause_desc_6 descausa6,
       cause_7 causa6,
       --substr(death_data_time_illness6, 1, instr(death_data_time_illness6, '|') - 1) tiempo_c6,
       pk_death_registry.get_data_time_illness(i_lang => id_lang,
                                               i_prof => profissional(NULL, id_institution, 0),
                                               i_mode => 'T',
                                               i_tipo => death_tipo_dt_defuncion_6,
                                               i_data => death_data_time_illness6) tiempo_c6,
       --substr(death_data_time_illness6, instr(death_data_time_illness6, '|') + 1) cvetpo_c6,
       pk_death_registry.get_data_time_illness(i_lang => id_lang,
                                               i_prof => profissional(NULL, id_institution, 0),
                                               i_mode => 'C',
                                               i_tipo => death_tipo_dt_defuncion_6,
                                               i_data => death_data_time_illness6) cvetpo_c6,
      -- substr(cause_7, 1, instr(cause_7, '|') - 1) causa6,
       cause_1 defcausabas,
       death_mother_during defdurante,
       death_mother_complications deftpo_emb,
       death_mother_causes_complic defcom_emb,
       death_acced_viol_sent_pub_min mp,
       death_acced_viol_alleged defpresunt,
       death_acced_viol_work_accident defdesempe,
       death_acced_viol_place_ocurr deflug_ocu,
       death_acced_viol_alleged_perp defvio_fam,
       death_acced_viol_pub_min_num defactamp,
       death_acced_viol_description defdesc_les,
       pk_death_registry.get_mx_name_from_list(i_lang     => id_lang,
                                               i_prof     => profissional(NULL, id_institution, 0),
                                               i_value    => dr_known_address,
                                               i_name     => death_acced_viol_street_number,
                                               i_flag     => 'TT',
                                               i_group_id => 15542 /*, i_id_ne => 11555 */) defdom_acc,
       pk_death_registry.get_mx_name_from_list(i_lang     => id_lang,
                                               i_prof     => profissional(NULL, id_institution, 0),
                                               i_value    => dr_known_address,
                                               i_name     => death_acced_viol_colony,
                                               i_flag     => 'TT',
                                               i_group_id => 15542,
                                               i_id_ne    => 11555) defcol_acc,
       death_acced_viol_entity defent_acc,
       death_acced_viol_municipality defdel_acc,
       death_acced_viol_location defloc_acc,
       pk_death_registry.get_mx_name_from_list(i_lang     => id_lang,
                                               i_prof     => profissional(NULL, id_institution, 0),
                                               i_value    => death_inf_info_name_q,
                                               i_name     => death_informant_info_name,
                                               i_flag     => 'Y',
                                               i_group_id => 15544) defnombinfor,
       pk_death_registry.get_mx_name_from_list(i_lang     => id_lang,
                                               i_prof     => profissional(NULL, id_institution, 0),
                                               i_value    => death_inf_info_father_q,
                                               i_name     => death_informant_info_father,
                                               i_flag     => 'Y',
                                               i_group_id => 15544) defpatinfor,
       pk_death_registry.get_mx_name_from_list(i_lang     => id_lang,
                                               i_prof     => profissional(NULL, id_institution, 0),
                                               i_value    => death_inf_info_mother_q,
                                               i_name     => death_informant_info_mother,
                                               i_flag     => 'Y',
                                               i_group_id => 15544) defmatinfor,
       death_informant_info_relation defparentinfor,
       death_certifier_type defcertifi,
       pk_death_registry.get_cert_order_number(i_lang     => id_lang,
                                               i_prof     => profissional(NULL, id_institution, 0),
                                               i_type     => 'G',
                                               i_question => death_cert_order_num_q,
                                               i_value    => death_certifier_order_number) defcedcertifi,
       death_certifier_name defnombcertifi,
       death_certifier_father_name defpatcerti,
       death_certifier_mother_name defmatcerti,
       death_certifier_phone deftel_cert,
       death_certifier_street || ' ' || death_certifier_colony defdomcertifi,
       death_certifier_signed deffirmocert,
       death_certifier_date deffech_cer,
       'UNME' defusu_cre,
       pk_date_utils.date_send_tsz(id_lang, dt_death_registry, id_institution, 0) deffec_cre_str,
       dt_death_registry deffec_cre,
       3 defnivcapt_cre,
       pk_adt.get_clues_name(i_id_clues => NULL, i_id_institution => id_institution) definstcapt_cre,
       pk_adt.get_rb_reg_classifier_code(i_rb_reg_class => id_rb_regional_classifier, i_rank => 5) defedocapt_cre,
       pk_adt.get_rb_reg_classifier_code(i_rb_reg_class => id_rb_regional_classifier, i_rank => 10) defmpocapt_cre,
       pk_adt.get_rb_reg_classifier_code(pk_adt.get_clues_jurisdiction(i_id_clues => NULL, i_id_institution => id_institution)) defjurcapt_cre,
       pk_adt.get_clues_code(i_id_clues => NULL, i_id_institution => id_institution) defcluescapt_cre,
       decode(update_institution, NULL, NULL, 'UNME') defusu_mod,
       decode(update_time, NULL, NULL, pk_date_utils.date_send_tsz(id_lang, update_time, id_institution, 0)) deffec_mod_str,
       decode(update_time, NULL, NULL, update_time) deffec_mod,
       3 defnivcapt,
       decode(update_institution,
              NULL,
              NULL,
              pk_adt.get_clues_name(i_id_clues => NULL, i_id_institution => update_institution)) definstcapt,
       decode(id_rb_reg_class_upd,
              NULL,
              NULL,
              pk_adt.get_rb_reg_classifier_code(i_rb_reg_class => id_rb_reg_class_upd, i_rank => 5)) defedocapt,
       decode(id_rb_reg_class_upd,
              NULL,
              NULL,
              pk_adt.get_rb_reg_classifier_code(i_rb_reg_class => id_rb_reg_class_upd, i_rank => 10)) defmpocapt,
       decode(update_institution,
              NULL,
              NULL,
              pk_adt.get_rb_reg_classifier_code(pk_adt.get_clues_jurisdiction(i_id_clues => NULL, i_id_institution => update_institution))) defjurcapt,
       decode(update_institution,
              NULL,
              NULL,
              pk_adt.get_clues_code(i_id_clues => NULL, i_id_institution => update_institution)) defcluescapt,
       0 defmodificabe,
       0 defmodificabf,
       1 deftipform,
       death_data_surveil_epidemic defverepi,
       death_mother_pregnancy defvermat,
       decode(update_institution, NULL, 0, 1) defextemporaneo,
       decode(update_institution, NULL, 0, 1) defrectifica
  FROM ( /* CMF */
        SELECT 17 id_lang,
                p.id_patient,
                p.id_person,
                e.id_episode,
                e.id_institution,
                e.dt_end_tstz,
                pk_adt.get_clues_id_rb_regional(i_id_clues => NULL, i_id_institution => e.id_institution) id_rb_regional_classifier,
                p.first_name,
                p.last_name,
                p.middle_name,
                ps.social_security_number,
                p.gender,
                c.id_content defnacion,
                cd.id_content country_hab,
                CASE
                     WHEN p.pat_native_lang = 2 THEN
                      'N'
                     WHEN p.pat_native_lang IN (3) THEN
                      'NE'
                     WHEN p.pat_native_lang IN (4) THEN
                      'SI'
                     WHEN p.pat_native_lang IS NULL THEN
                      NULL
                     ELSE
                      'Y'
                 END AS leng_indig,
                nvl(p.dt_birth_tstz, p.dt_birth) birth_date, -- rever
                pk_patient.get_pat_age_type(i_lang    => NULL,
                                            i_prof    => profissional(NULL, e.id_institution, NULL),
                                            i_patient => p.id_patient) type_age,
                pk_patient.get_pat_age_num(i_lang    => 17,
                                           i_prof    => profissional(NULL, e.id_institution, NULL),
                                           i_patient => p.id_patient,
                                           i_type    => 'Y') pat_age,
                -- FALTA A IDADE E TIPO DE IDADE
                --p.code_birth_certificate, -- folio do cretificado de nascimento
                psa.marital_status, --
                psa.address,
                pk_adt.get_patient_address_id(p.id_person) patient_adress_id,
                pk_adt.get_patient_address_colony(I_LANG=>17, I_PROF=>profissional(NULL, e.id_institution, NULL), i_person => p.id_person) patient_colony_address,
                pk_adt.get_rb_reg_classifier_code(pk_adt.get_patient_address_id(p.id_person), 5) defent_hab, -- entidade
                pk_adt.get_rb_reg_classifier_code(pk_adt.get_patient_address_id(p.id_person), 10) defdel_hab, -- municipio
                pk_adt.get_rb_reg_classifier_code(pk_adt.get_patient_address_id(p.id_person), 15) defloc_hab, -- localidade,
                (SELECT id_content
                   FROM scholarship s
                  WHERE s.id_scholarship = psa.id_scholarship) defescolar, -- escolaridade
                (SELECT id_content
                   FROM occupation o
                  WHERE o.id_occupation = pk_patient.get_pat_job(i_id_pat => p.id_patient)) defocupaci, -- JOB
                psa.flg_job_status, -- work?
                dr.dt_death_registry,
                dr.death_date_format,
                dr.dt_death,
                dr.update_institution,
                dr.update_time,
                decode(dr.update_institution,
                       NULL,
                       NULL,
                       pk_adt.get_clues_id_rb_regional(i_id_clues => NULL, i_id_institution => dr.update_institution)) id_rb_reg_class_upd,
                substr(drd.dr_height_cmeters, 1, instr(drd.dr_height_cmeters, '|') - 1) height_cm,
                substr(drd.dr_weight_grams, 1, instr(drd.dr_weight_grams, '|') - 1) weight_gr,
                drd.*
          FROM patient p
          JOIN episode e
            ON e.id_patient = p.id_patient
          JOIN death_registry dr
            ON e.id_episode = dr.id_episode
          LEFT JOIN person ps
            ON p.id_person = ps.id_person
         INNER JOIN pat_soc_attributes psa
            ON psa.id_patient = p.id_patient
          LEFT JOIN pat_soc_attributes psa
            ON p.id_patient = psa.id_patient
          LEFT JOIN country c
            ON psa.id_country_nation = c.id_country
          JOIN (SELECT /*+ OPT_ESTIMATE(TABLE xpivot ROWS=1) */
                 *
                  FROM v_death_patient_pivot xpivot) drd
            ON dr.id_death_registry = drd.id_death_registry
          LEFT JOIN v_contact_address_mx ca
            ON ca.id_contact_entity = p.id_person
           AND ca.flg_main_address = 'Y'
          LEFT JOIN country cd
            ON cd.id_country = ca.id_country
         WHERE dr.flg_type = 'P'
           AND dr.flg_status = 'A'
              -- condition to limit rows: only rows from june to now
           AND dr.dt_death_registry >
               CAST(to_timestamp_tz('201706010000 Mexico/General', 'yyyymmddhh24mi tzr') AS TIMESTAMP WITH LOCAL TIME ZONE)) xsql;
