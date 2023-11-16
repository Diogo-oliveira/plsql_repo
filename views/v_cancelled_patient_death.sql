CREATE OR REPLACE VIEW V_CANCELLED_PATIENT_DEATH AS
SELECT id_episode,
       id_patient,
       id_institution_epis id_institution,
       pk_death_registry.get_death_data_folio_by_id(i_id_death_registry => id_death_registry) deffolio,
       'UNME' defusu_mod,
       pk_date_utils.date_send_tsz(i_lang => 17, i_date => update_time, i_inst => id_institution, i_soft => 0) deffec_mod,
       '3' defnivcapt,
       pk_adt.get_clues_name(i_id_clues => NULL, i_id_institution => id_institution) definstcapt,
       pk_adt.get_rb_reg_classifier_code(id_rb_regional_classifier, 5) defedocapt,
       pk_adt.get_clues_jurisdiction(i_id_clues => NULL, i_id_institution => id_institution) defjurcapt,
       pk_adt.get_rb_reg_classifier_code(id_rb_regional_classifier, 10) defmpocapt,
       pk_adt.get_clues_code(i_id_clues => NULL, i_id_institution => id_institution) defcluescapt
  FROM (SELECT dr.id_death_registry id_death_registry,e.id_episode,
       e.id_patient,
               nvl(dr.update_institution, e.id_institution) id_institution,
               e.id_institution id_institution_epis, 
               pk_adt.get_clues_id_rb_regional(i_id_clues => NULL, i_id_institution => e.id_institution) id_rb_regional_classifier,
               dr.update_time update_time
          FROM death_registry dr
          JOIN episode e
            ON e.id_episode = dr.id_episode
         WHERE dr.flg_type = 'P'
           AND dr.flg_status = 'C') t;
