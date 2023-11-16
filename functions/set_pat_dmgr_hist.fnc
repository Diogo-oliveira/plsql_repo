CREATE OR REPLACE FUNCTION set_pat_dmgr_hist
(
    i_lang          IN LANGUAGE.id_language%TYPE,
    i_pat_dmgr_hist IN pat_dmgr_hist%ROWTYPE,
    o_error         OUT VARCHAR2
) RETURN BOOLEAN IS
    g_error VARCHAR2(200);
BEGIN
    g_error := 'insert into pat_dmgr_hist';

    ts_pat_dmgr_hist.ins(id_pat_dmgr_hist_in   => i_pat_dmgr_hist.id_pat_dmgr_hist,
                         id_patient_in         => i_pat_dmgr_hist.id_patient,
                         id_professional_in    => i_pat_dmgr_hist.id_professional,
                         id_institution_in     => i_pat_dmgr_hist.id_institution,
                         name_in               => i_pat_dmgr_hist.name,
                         gender_in             => i_pat_dmgr_hist.gender,
                         nick_name_in          => i_pat_dmgr_hist.nick_name,
                         age_in                => i_pat_dmgr_hist.age,
                         marital_status_in     => i_pat_dmgr_hist.marital_status,
                         address_in            => i_pat_dmgr_hist.address,
                         district_in           => i_pat_dmgr_hist.district,
                         zip_code_in           => i_pat_dmgr_hist.zip_code,
                         num_main_contact_in   => i_pat_dmgr_hist.num_main_contact,
                         num_contact_in        => i_pat_dmgr_hist.num_contact,
                         flg_job_status_in     => i_pat_dmgr_hist.flg_job_status,
                         id_country_nation_in  => i_pat_dmgr_hist.id_country_nation,
                         id_scholarship_in     => i_pat_dmgr_hist.id_scholarship,
                         father_name_in        => i_pat_dmgr_hist.father_name,
                         id_isencao_in         => i_pat_dmgr_hist.id_isencao,
                         birth_place_in        => i_pat_dmgr_hist.birth_place,
                         num_health_plan_in    => i_pat_dmgr_hist.num_health_plan,
                         id_recm_in            => i_pat_dmgr_hist.id_recm,
                         id_occupation_in      => i_pat_dmgr_hist.id_occupation,
                         occupation_desc_in    => i_pat_dmgr_hist.occupation_desc,
                         mother_name_in        => i_pat_dmgr_hist.mother_name,
                         location_in           => i_pat_dmgr_hist.location,
                         num_doc_external_in   => i_pat_dmgr_hist.num_doc_external,
                         dt_change_tstz_in     => i_pat_dmgr_hist.dt_change_tstz,
                         id_geo_state_in       => i_pat_dmgr_hist.id_geo_state,
                         flg_migrator_in       => i_pat_dmgr_hist.flg_migrator,
                         id_country_address_in => i_pat_dmgr_hist.id_country_address,
                         id_episode_in         => i_pat_dmgr_hist.id_episode,
                         dt_birth_in           => i_pat_dmgr_hist.dt_birth,
                         handle_error_in       => TRUE);
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        DECLARE
            l_id PLS_INTEGER;
        BEGIN
            ROLLBACK;
            pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                               err_instance_id_out => l_id,
                                               text_in             => g_error,
                                               name1_in            => 'OWNER',
                                               value1_in           => 'ALERT',
                                               name2_in            => 'PACKAGE',
                                               value2_in           => 'PK_PATIENT',
                                               name3_in            => 'FUNCTION',
                                               value3_in           => 'SET_PAT_DMGR_HIST',
                                               name4_in            => 'PATIENT_ID',
                                               value4_in           => i_pat_dmgr_hist.id_patient);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END;
    
END set_pat_dmgr_hist;
