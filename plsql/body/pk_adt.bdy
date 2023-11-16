/*-- Last Change Revision: $Rev: 2026615 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:21 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_adt AS

    g_tbl_default CONSTANT t_low_char := 'PATIENT';
    g_idx_default CONSTANT t_low_char := 'PATIENT_LIDX';
    g_yes         CONSTANT t_flg_char := 'Y';
    g_no          CONSTANT t_flg_char := 'N';

    --health plan flg_type:
    c_sns_hp_type           CONSTANT VARCHAR2(1 CHAR) := 'S';
    c_adse_hp_type          CONSTANT VARCHAR2(1 CHAR) := 'A';
    c_sams_hp_type          CONSTANT VARCHAR2(1 CHAR) := 'M';
    c_profdecease_hp_type   CONSTANT VARCHAR2(1 CHAR) := 'P';
    c_other_reimbursed_plan CONSTANT VARCHAR2(1 CHAR) := 'B';
    c_cesd_hp_type          CONSTANT VARCHAR2(1 CHAR) := 'E';

    g_count_error NUMBER(9) := 0;
    g_endsession  VARCHAR2(4000);

    g_chinese_char_range VARCHAR2(1000 CHAR) := unistr('\4E00') || '-' || unistr('\9fa5');
    g_hp_type_profdecease CONSTANT VARCHAR2(2 CHAR) := 'P'; -- profdecease_hp_type

    g_family_rel_guardian CONSTANT NUMBER := 39;

    TYPE l_my_ibt IS TABLE OF VARCHAR2(200 CHAR) INDEX BY VARCHAR2(200 CHAR);
    l_odd_values         l_my_ibt;
    l_even_values        l_my_ibt;
    l_countries_map      l_my_ibt;
    l_check_digits_map   l_my_ibt;
    l_curp_invalid_words l_my_ibt;

    FUNCTION get_default_table_name RETURN t_low_char IS
    BEGIN
        RETURN g_tbl_default;
    END get_default_table_name;

    FUNCTION dummy_refresh
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN professional.id_professional%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- Read sys_config parameter with the authorized profile templates
        g_error := 'dummy_refresh';
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'dummy_refresh',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END dummy_refresh;

    FUNCTION create_all_surgery
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN OUT patient.id_patient%TYPE,
        i_prof        IN professional.id_professional%TYPE,
        o_episode_new OUT episode.id_episode%TYPE,
        o_schedule    OUT schedule.id_schedule%TYPE,
        o_error       OUT VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
    
        o_episode_new := -1;
        o_schedule    := -2;
        o_error       := 'OK';
    
        RETURN 1;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || 'PK_ADT.CREATE_ALL_SURGERY / ' ||
                       g_error || ' / ' || SQLERRM;
            RETURN 0;
    END create_all_surgery;

    FUNCTION process_patient_insert
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof   profissional;
        l_rowids table_varchar;
        myrowid  ROWID;
    BEGIN
        l_prof := profissional(id => i_professional, institution => i_institution, software => i_software);
    
        SELECT ROWID
          INTO myrowid
          FROM patient
         WHERE id_patient = i_patient
           AND rownum = 1;
    
        l_rowids := table_varchar(myrowid);
    
        IF t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                         i_prof       => l_prof,
                                         i_table_name => 'PATIENT',
                                         i_rowids     => l_rowids,
                                         o_error      => o_error)
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'PROCESS_PATIENT_INSERT',
                                              o_error);
            RETURN FALSE;
    END process_patient_insert;

    FUNCTION process_patient_update
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof   profissional;
        l_rowids table_varchar;
        myrowid  ROWID;
    BEGIN
        l_prof := profissional(id => i_professional, institution => i_institution, software => i_software);
    
        SELECT ROWID
          INTO myrowid
          FROM patient
         WHERE id_patient = i_patient
           AND rownum = 1;
    
        l_rowids := table_varchar(myrowid);
    
        IF t_data_gov_mnt.process_update(i_lang       => i_lang,
                                         i_prof       => l_prof,
                                         i_table_name => 'PATIENT',
                                         i_rowids     => l_rowids,
                                         o_error      => o_error)
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'PROCESS_PATIENT_UPDATE',
                                              o_error);
            RETURN FALSE;
    END process_patient_update;

    /**
    * This function matches all the information of the two patients (temporary and definitive).
    *
    * @param i_lang language id
    * @param i_prof user s object
    * @param i_patient new patient id
    * @param i_patient_temp temporary patient which data will be merged out, and then deleted
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    --view spec for full comments
    FUNCTION set_match_patient
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        i_flg_unknown  IN epis_info.flg_unknown%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_adt_core.set_match_patient(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_patient      => i_patient,
                                             i_patient_temp => i_patient_temp,
                                             i_flg_unknown  => i_flg_unknown,
                                             o_error        => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_MATCH_PATIENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END set_match_patient;

    --view spec for full comments
    FUNCTION delete_patient
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_adt_core.delete_patient(i_lang    => i_lang,
                                          i_prof    => i_prof,
                                          i_patient => i_patient,
                                          o_error   => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_PATIENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END delete_patient;

    FUNCTION set_patient_match
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_old_episode IN episode.id_episode%TYPE,
        i_old_visit   IN visit.id_visit%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        vpatidentifier pat_identifier.id_pat_identifier%TYPE;
    BEGIN
    
        --Test parameter values
        IF i_patient IS NULL
           OR i_old_visit IS NULL
        THEN
            g_error := 'INVALID INPUT';
            RAISE g_adtexception;
        END IF;
    
        --Get most recent id_pat_identifier for the patient within the institution
        SELECT id_pat_identifier
          INTO vpatidentifier
          FROM (SELECT id_pat_identifier
                  FROM pat_identifier
                 WHERE id_patient = i_patient
                   AND id_institution = i_prof.institution
                 ORDER BY create_time DESC NULLS LAST)
         WHERE rownum = 1;
    
        IF vpatidentifier IS NULL
        THEN
            g_error := 'INVALID ID_PAT_IDENTIFIER';
            RAISE g_adtexception;
        END IF;
    
        UPDATE visit_adt
           SET id_pat_identifier = vpatidentifier
         WHERE id_visit = i_old_visit;
    
        UPDATE admission_adt
           SET id_pat_health_plan =
               (SELECT id_pat_health_plan
                  FROM epis_health_plan
                 WHERE id_episode = i_old_episode
                   AND rownum = 1)
         WHERE id_episode_adt = (SELECT id_episode_adt
                                   FROM episode_adt
                                  WHERE id_episode = i_old_episode);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PATIENT_MATCH',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END set_patient_match;

    FUNCTION delete_adt_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_visit_temp IN visit_adt.id_visit%TYPE,
        i_visit      IN visit_adt.id_visit%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        vvisitadt visit_adt.id_visit_adt%TYPE := NULL;
    BEGIN
    
        --Test parameter values
        IF i_visit IS NULL
        THEN
            g_error := 'INVALID INPUT';
            RAISE g_adtexception;
        END IF;
    
        --Test if already exists an admission for the definitive visit
        BEGIN
            SELECT id_visit_adt
              INTO vvisitadt
              FROM visit_adt
             WHERE id_visit = i_visit;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF vvisitadt IS NULL
        THEN
            --There isn t any admission info for the definitive visit...
            UPDATE visit_adt
               SET id_visit = i_visit
             WHERE id_visit = i_visit_temp;
        ELSE
            --Delete all info from temporary visit
            g_error := 'TRYING TO DELETE VISIT_ADT';
            DELETE FROM visit_adt
             WHERE id_visit = i_visit_temp;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ADT_VISIT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END delete_adt_visit;

    FUNCTION delete_adt_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode_adt.id_episode%TYPE,
        i_episode      IN episode_adt.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_adt_core.delete_adt_episode(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_episode_temp => i_episode_temp,
                                              i_episode      => i_episode,
                                              o_error        => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ADT_EPISODE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END delete_adt_episode;

    --read spec for full comments
    FUNCTION set_patient_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_status  IN patient.flg_status%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_patient patient%ROWTYPE;
    
    BEGIN
    
        --Test parameter values
        IF i_patient IS NULL
           OR i_status IS NULL
        THEN
            g_error := 'INVALID INPUT';
            RAISE g_adtexception;
        END IF;
    
        --Get patient current info
        SELECT *
          INTO l_patient
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        --Canceled patients cannot change
        IF l_patient.flg_status = pk_alert_constant.g_cancelled
           OR i_status = g_patient_deceased
        THEN
            g_error := 'INVALID STATUS CHANGE';
            RAISE g_adtexception;
        END IF;
    
        --One can only cancel a patient without episodes (at any status)
        IF i_status = pk_alert_constant.g_cancelled
           AND pk_patient.get_pat_has_any_episode(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient)
        THEN
            -- raise error here
            g_error := 'PATIENT WITH EPISODES';
            RAISE g_adtexception;
        END IF;
    
        --ALERT-271134 cancel announced arrival should cancel the patient itself
        --Cancel patient must inactivate patient processes within institution so that is not searchable
        IF i_status = pk_alert_constant.g_cancelled
        THEN
        
            UPDATE pat_identifier pi
               SET flg_status = pk_alert_constant.g_inactive
             WHERE pi.id_patient = i_patient
               AND pi.id_institution IN
                   (SELECT *
                      FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt))
                    UNION
                    SELECT 0
                      FROM dual);
        
            UPDATE clin_record cr
               SET cr.flg_status = pk_alert_constant.g_inactive
             WHERE cr.id_patient = i_patient
               AND cr.id_institution IN
                   (SELECT *
                      FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt))
                    UNION
                    SELECT 0
                      FROM dual);
        
        END IF;
    
        --Update patient info
        UPDATE patient p
           SET p.flg_status = i_status
         WHERE p.id_patient = i_patient;
    
        --Update patient history
        INSERT INTO patient_hist
            (id_patient_hist,
             id_patient,
             id_person,
             id_general_pratictioner,
             id_pat_family,
             name,
             gender,
             dt_birth,
             nick_name,
             flg_status,
             dt_deceased,
             adw_last_update,
             last_name,
             middle_name,
             age,
             flg_migration,
             total_fam_members,
             national_health_number,
             institution_key,
             patient_number,
             deceased_motive,
             deceased_place,
             operation_type,
             operation_time,
             operation_user,
             birth_place,
             first_name,
             record_status,
             import_code,
             id_ethnics,
             preferred_contact_times,
             id_preferred_contact_method,
             id_preferred_com_format,
             id_preferred_language,
             flg_sensitive_record,
             vip_status,
             alias,
             alias_reason,
             non_disclosure_level,
             flg_origin,
             flg_dependence_level,
             flg_death_ident_method,
             death_registry_susp_action_id,
             flg_living_arrangement,
             flg_race,
             maiden_name,
             id_place_of_birth,
             flg_assigning_authority,
             flg_guarantor,
             flg_self_pay,
             flg_living_will,
             flg_overseas_status,
             other_names_1,
             other_names_2,
             other_names_3,
             flg_exemption,
             flg_financial_type)
        VALUES
            (seq_patient_hist.nextval,
             l_patient.id_patient,
             l_patient.id_person,
             l_patient.id_general_pratictioner,
             l_patient.id_pat_family,
             l_patient.name,
             l_patient.gender,
             l_patient.dt_birth,
             l_patient.nick_name,
             i_status,
             l_patient.dt_deceased,
             l_patient.adw_last_update,
             l_patient.last_name,
             l_patient.middle_name,
             l_patient.age,
             l_patient.flg_migration,
             l_patient.total_fam_members,
             l_patient.national_health_number,
             l_patient.institution_key,
             l_patient.patient_number,
             l_patient.deceased_motive,
             l_patient.deceased_place,
             'U',
             current_timestamp,
             i_prof.id,
             l_patient.birth_place,
             l_patient.first_name,
             l_patient.record_status,
             l_patient.import_code,
             l_patient.id_ethnics,
             l_patient.preferred_contact_times,
             l_patient.id_preferred_contact_method,
             l_patient.id_preferred_com_format,
             l_patient.id_preferred_language,
             l_patient.flg_sensitive_record,
             l_patient.vip_status,
             l_patient.alias,
             l_patient.alias_reason,
             l_patient.non_disclosure_level,
             l_patient.flg_origin,
             l_patient.flg_dependence_level,
             l_patient.flg_death_ident_method,
             l_patient.death_registry_susp_action_id,
             l_patient.flg_living_arrangement,
             l_patient.flg_race,
             l_patient.maiden_name,
             l_patient.id_place_of_birth,
             l_patient.flg_assigning_authority,
             l_patient.flg_guarantor,
             l_patient.flg_self_pay,
             l_patient.flg_living_will,
             l_patient.flg_overseas_status,
             l_patient.other_names_1,
             l_patient.other_names_2,
             l_patient.other_names_3,
             l_patient.flg_exemption,
             l_patient.flg_financial_type);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PATIENT_STATUS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END set_patient_status;

    /**********************************************************************************************
    * Updates patient table fields
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                patient id
    * @param i_name                   name
    * @param i_gender                 gender
    * @param i_dt_birth               date of birth
    * @param i_age                    age
    * @param i_is_to_insert           if the patient was created by create_dummy_patient and this is the first update
                                      then this flag should be false otherwise is always true
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/10/29
    **********************************************************************************************/
    FUNCTION set_patient
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_name         IN pre_hosp_accident.name%TYPE,
        i_gender       IN pre_hosp_accident.gender%TYPE,
        i_dt_birth     IN pre_hosp_accident.dt_birth%TYPE,
        i_age          IN pre_hosp_accident.age%TYPE,
        i_is_to_insert IN BOOLEAN DEFAULT TRUE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_PATIENT';
        --
        l_pat_hist_oper_type_c patient_hist.operation_type%TYPE := 'C';
        l_pat_hist_oper_type_u patient_hist.operation_type%TYPE := 'U';
        l_new_id_patient_hist  patient_hist.id_patient_hist%TYPE;
        --
        l_first_name  patient.first_name%TYPE;
        l_middle_name patient.middle_name%TYPE;
        l_last_name   patient.last_name%TYPE;
        l_rowids      table_varchar;
    BEGIN
        g_error := 'GET NEW PAT_HIST ID';
        SELECT seq_patient_hist.nextval * c_seq_offset
          INTO l_new_id_patient_hist
          FROM dual;
    
        g_error := 'SET FIRST MIDDLE AND LAST PAT NAME';
        SELECT substr(i_name, 1, decode(instr(i_name, ' '), 0, length(i_name), instr(i_name, ' ') - 1)) first_name,
               substr(i_name,
                      length(substr(i_name, 1, decode(instr(i_name, ' '), 0, length(i_name), instr(i_name, ' ') - 1))) + 2,
                      length(i_name) -
                      length(substr(i_name, 1, decode(instr(i_name, ' '), 0, length(i_name), instr(i_name, ' ') - 1))) -
                      length(substr(i_name,
                                    decode(instr(i_name, ' ', -1), 0, '', instr(i_name, ' ', -1) + 1),
                                    length(i_name))) - 2) middle_name,
               substr(i_name, decode(instr(i_name, ' ', -1), 0, '', instr(i_name, ' ', -1) + 1), length(i_name)) last_name
          INTO l_first_name, l_middle_name, l_last_name
          FROM dual;
    
        g_error := 'UPDATE PATIENT DATA';
        ts_patient.upd(id_patient_in   => i_patient,
                       name_in         => i_name,
                       name_nin        => FALSE,
                       first_name_in   => l_first_name,
                       first_name_nin  => FALSE,
                       middle_name_in  => l_middle_name,
                       middle_name_nin => FALSE,
                       last_name_in    => l_last_name,
                       last_name_nin   => FALSE,
                       gender_in       => i_gender,
                       gender_nin      => FALSE,
                       dt_birth_in     => i_dt_birth,
                       dt_birth_nin    => FALSE,
                       age_in          => i_age,
                       age_nin         => FALSE,
                       rows_out        => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PATIENT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF i_is_to_insert
        THEN
            INSERT INTO patient_hist
                (id_patient_hist,
                 id_patient,
                 id_person,
                 id_general_pratictioner,
                 id_pat_family,
                 name,
                 gender,
                 dt_birth,
                 nick_name,
                 flg_status,
                 dt_deceased,
                 adw_last_update,
                 last_name,
                 middle_name,
                 age,
                 flg_migration,
                 total_fam_members,
                 national_health_number,
                 institution_key,
                 patient_number,
                 deceased_motive,
                 deceased_place,
                 operation_type,
                 operation_time,
                 operation_user,
                 birth_place,
                 first_name,
                 record_status,
                 import_code,
                 id_ethnics,
                 preferred_contact_times,
                 id_preferred_contact_method,
                 id_preferred_com_format,
                 id_preferred_language,
                 flg_sensitive_record,
                 vip_status)
                SELECT l_new_id_patient_hist,
                       ph.id_patient,
                       ph.id_person,
                       ph.id_general_pratictioner,
                       ph.id_pat_family,
                       i_name,
                       i_gender,
                       i_dt_birth,
                       ph.nick_name,
                       ph.flg_status,
                       ph.dt_deceased,
                       ph.adw_last_update,
                       l_last_name,
                       l_middle_name,
                       i_age,
                       ph.flg_migration,
                       ph.total_fam_members,
                       ph.national_health_number,
                       ph.institution_key,
                       ph.patient_number,
                       ph.deceased_motive,
                       ph.deceased_place,
                       l_pat_hist_oper_type_u,
                       current_timestamp,
                       i_prof.id,
                       ph.birth_place,
                       l_first_name,
                       ph.record_status,
                       ph.import_code,
                       ph.id_ethnics,
                       ph.preferred_contact_times,
                       ph.id_preferred_contact_method,
                       ph.id_preferred_com_format,
                       ph.id_preferred_language,
                       ph.flg_sensitive_record,
                       ph.vip_status
                  FROM patient_hist ph
                 WHERE ph.id_patient = i_patient
                   AND ph.operation_time = (SELECT MAX(ph2.operation_time)
                                              FROM patient_hist ph2
                                             WHERE ph2.id_patient = i_patient);
        ELSE
            g_error := 'UPDATE PATIENT_HIST';
            UPDATE patient_hist ph
               SET ph.name        = i_name,
                   ph.first_name  = l_first_name,
                   ph.middle_name = l_middle_name,
                   ph.last_name   = l_last_name,
                   ph.gender      = i_gender,
                   ph.dt_birth    = i_dt_birth,
                   ph.age         = i_age
             WHERE ph.id_patient = i_patient
               AND ph.operation_type = l_pat_hist_oper_type_c;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_patient;

    /********************************************************************************************
    * Create patients institution history.
    *
    * @param i_lang                language id
    * @param i_patient             patient id
    * @param i_institution         institution id
    * @param i_reason_type         reason type
    * @param i_reason              reason
    * @param i_dt_begin            begin date
    * @param i_institution_enroled institution enroled id
    * @param i_software            software id
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2009/11/06
    * @version                     2.5
    ********************************************************************************************/
    FUNCTION intf_update_patient_care_inst
    (
        i_lang                IN language.id_language%TYPE,
        i_patient             IN patient_care_inst.id_patient%TYPE,
        i_institution         IN patient_care_inst.id_institution%TYPE,
        i_reason_type         IN patient_care_inst.reason_type%TYPE,
        i_reason              IN patient_care_inst.reason%TYPE,
        i_dt_begin            IN patient_care_inst.dt_begin_tstz%TYPE,
        i_institution_enroled IN patient_care_inst.id_institution_enroled%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_begin TIMESTAMP WITH TIME ZONE := nvl(i_dt_begin, current_timestamp);
    BEGIN
    
        --Interfaces team requirement v2603
        --ADT-2530
        IF i_reason_type IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        -- Update PATIENT_CARE_INST
        g_error := 'DELETE PATIENT_CARE_INST';
        DELETE patient_care_inst
         WHERE id_patient = i_patient;
    
        g_error := 'INSERT INTO PATIENT_CARE_INST';
        INSERT INTO patient_care_inst
            (id_patient, id_institution, reason_type, reason, dt_begin_tstz, id_institution_enroled)
        VALUES
            (i_patient, i_institution, i_reason_type, i_reason, l_dt_begin, i_institution_enroled);
    
        -- UPDATE PATIENT_CARE_INST_HISTORY
        g_error := 'UPDATE PATIENT_CARE_INST_HISTORY';
        UPDATE patient_care_inst_history
           SET dt_end_tstz = l_dt_begin
         WHERE dt_end_tstz IS NULL
           AND id_patient = i_patient;
    
        g_error := 'INSERT PATIENT_CARE_INST_HISTORY';
        INSERT INTO patient_care_inst_history
            (id_patient,
             id_institution,
             reason_type,
             reason,
             dt_begin_tstz,
             dt_end_tstz,
             id_patient_care_inst_history,
             id_institution_enroled)
        VALUES
            (i_patient,
             i_institution,
             i_reason_type,
             i_reason,
             l_dt_begin,
             NULL,
             seq_patient_care_inst_history.nextval,
             i_institution_enroled);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'INTF_UPDATE_PATIENT_CARE_INST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_update_patient_care_inst;

    FUNCTION get_emergency_contact
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_contact OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        SELECT phone_number
          INTO o_contact
          FROM (SELECT phone_number
                  FROM contact c
                  JOIN contact_phone cp
                    ON c.id_contact = cp.id_contact
                 WHERE id_contact_entity IN
                       (SELECT id_this_contact_person
                          FROM person_contact
                         WHERE id_origin_person IN (SELECT id_person
                                                      FROM patient
                                                     WHERE id_patient = i_patient))
                   AND id_contact_description IN (g_nl_emergency_contact_desc, g_def_emergency_contact_desc)
                   AND id_contact_type = g_emergency_contact_type
                 ORDER BY contact_priority ASC)
         WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_contact := NULL;
        
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EMERGENCY_CONTACT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END get_emergency_contact;

    FUNCTION get_emergency_contact
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
        l_contact VARCHAR2(30 CHAR);
    
        l_error t_error_out;
    
    BEGIN
    
        IF NOT pk_adt.get_emergency_contact(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_patient => i_patient,
                                            o_contact => l_contact,
                                            o_error   => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_contact;
    
    END get_emergency_contact;

    FUNCTION add_emergency_contact
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_contact IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_adt_core.add_emergency_contact(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_patient => i_patient,
                                                 i_contact => i_contact);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ADD_EMERGENCY_CONTACT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END add_emergency_contact;

    FUNCTION is_core_market
    (
        i_lang   IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_market IN (g_nl_market,
                        g_uk_market,
                        g_pt_market,
                        g_br_market,
                        g_it_market,
                        g_cl_market,
                        g_ch_market,
                        g_fr_market,
                        g_mx_market,
                        g_kw_market)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'IS_CORE_MARKET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END is_core_market;

    /********************************************************************************************
    * Criar ou actualizar a informação do episódio
    *
    * @param i_lang                language id
    * @param i_epis_type           Tipo de episodio
    * @param i_institution         ID da instituicao onde e realizada a criacao/actualizacao do episodio
    * @param i_professional        Professional ID
    * @param i_software            Software ID
    * @param i_patient             Patient ID
    * @param i_episode             Episode ID
    * @param i_ext_episode         External Episode ID
    * @param i_external_sys        External System ID
    * @param i_health_plan         Health Plan ID
    * @param i_schedule            Schedule ID
    * @param i_flg_ehr             Electronic Health Record Flag
    * @param i_origin              Origin of the episode
    * @param i_dt_begin            Begin date
    * @param i_dep_clin_serv       Department Clinical Service
    * @param i_external_cause      ID of external cause
    * @param o_episode             ID do episódio associado ao ID_EPIS_EXT_SYS
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2007/02/04
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_episode_pfh
    (
        i_lang                 IN language.id_language%TYPE,
        i_epis_type            IN epis_type.id_epis_type%TYPE,
        i_institution          IN institution.id_institution%TYPE,
        i_professional         IN professional.id_professional%TYPE,
        i_software             IN software.id_software%TYPE,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_ext_episode          IN epis_ext_sys.value%TYPE,
        i_external_sys         IN external_sys.id_external_sys%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_schedule             IN epis_info.id_schedule%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE,
        i_origin               IN origin.id_origin%TYPE,
        i_dt_begin             IN episode.dt_begin_tstz%TYPE,
        i_dep_clin_serv        IN epis_info.id_dep_clin_serv%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_consultant_in_charge IN epis_multi_prof_resp.id_professional%TYPE,
        i_dt_arrival           IN announced_arrival.dt_announced_arrival%TYPE,
        i_flg_unknown          IN epis_info.flg_unknown%TYPE DEFAULT pk_alert_constant.g_no,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN PLS_INTEGER IS
    
        mytrue  CONSTANT PLS_INTEGER := 1;
        myfalse CONSTANT PLS_INTEGER := 0;
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
        l_prof           profissional := profissional(id          => i_professional,
                                                      institution => i_institution,
                                                      software    => i_software);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, l_prof);
    
        IF pk_api_visit.set_episode_pfh(i_lang           => i_lang,
                                        i_epis_type      => i_epis_type,
                                        i_institution    => i_institution,
                                        i_professional   => i_professional,
                                        i_software       => i_software,
                                        i_patient        => i_patient,
                                        i_episode        => i_episode,
                                        i_ext_episode    => i_ext_episode,
                                        i_external_sys   => i_external_sys,
                                        i_health_plan    => i_health_plan,
                                        i_schedule       => i_schedule,
                                        i_flg_ehr        => i_flg_ehr,
                                        i_origin         => i_origin,
                                        i_dt_begin       => i_dt_begin,
                                        i_dep_clin_serv  => i_dep_clin_serv,
                                        i_external_cause => i_external_cause,
                                        i_transaction_id => l_transaction_id,
                                        i_dt_arrival     => i_dt_arrival,
                                        i_prof_resp      => i_consultant_in_charge,
                                        i_flg_unknown    => i_flg_unknown,
                                        o_episode        => o_episode,
                                        o_error          => o_error) = mytrue
        THEN
            --remote scheduler commit. Doesn't affect PFH.
            pk_schedule_api_upstream.do_commit(l_transaction_id, l_prof);
        
            RETURN mytrue;
        END IF;
    
        pk_schedule_api_upstream.do_rollback(l_transaction_id, l_prof);
        RETURN myfalse;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPISODE_PFH',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, NULL);
            pk_utils.undo_changes;
            RETURN myfalse;
    END set_episode_pfh;

    FUNCTION update_transfer_adt
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_id_inst IN institution.id_institution%TYPE,
        i_episode IN pat_soc_attributes.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        g_clin_rec_act CONSTANT clin_record.flg_status%TYPE := 'A';
        g_found          BOOLEAN := FALSE;
        l_clin_record    clin_record%ROWTYPE;
        l_id_clin_record clin_record.id_clin_record%TYPE;
        l_rows_cr        table_varchar;
        l_error          t_error_out;
        v_id_clin_record clin_record.id_clin_record%TYPE;
        v_pat_identifier pat_identifier.id_pat_identifier%TYPE;
        vcurrentdate     DATE := SYSDATE;
    
        CURSOR c_clin_record(i_inst IN institution.id_institution%TYPE) IS
            SELECT cr.*
              FROM clin_record cr
             WHERE id_patient = i_patient
               AND id_institution = i_inst
               AND flg_status = g_clin_rec_act
             ORDER BY id_clin_record DESC;
    
    BEGIN
    
        -- Update patient attributes
        -- Priority is given to original institution, since they are the most recent.
        g_error := 'MERGE PAT_SOC_ATTRIBUTES';
        MERGE INTO pat_soc_attributes psa
        USING (SELECT psa2.*
                 FROM pat_soc_attributes psa2
                WHERE psa2.id_patient = i_patient
                  AND psa2.id_institution = i_id_inst) psa2
        ON (psa.id_patient = i_patient AND psa.id_institution = i_prof.institution)
        WHEN MATCHED THEN
            UPDATE
               SET psa.marital_status                = nvl(psa2.marital_status, psa.marital_status),
                   psa.address                       = nvl(psa2.address, psa.address),
                   psa.location                      = nvl(psa2.location, psa.location),
                   psa.district                      = nvl(psa2.district, psa.district),
                   psa.zip_code                      = nvl(psa2.zip_code, psa.zip_code),
                   psa.num_main_contact              = nvl(psa2.num_main_contact, psa.num_main_contact),
                   psa.num_contact                   = nvl(psa2.num_contact, psa.num_contact),
                   psa.flg_job_status                = nvl(psa2.flg_job_status, psa.flg_job_status),
                   psa.id_country_nation             = nvl(psa2.id_country_nation, psa.id_country_nation),
                   psa.id_country_address            = nvl(psa2.id_country_address, psa.id_country_address),
                   psa.id_scholarship                = nvl(psa2.id_scholarship, psa.id_scholarship),
                   psa.id_religion                   = nvl(psa2.id_religion, psa.id_religion),
                   psa.mother_name                   = nvl(psa2.mother_name, psa.mother_name),
                   psa.father_name                   = nvl(psa2.father_name, psa.father_name),
                   psa.id_isencao                    = nvl(psa2.id_isencao, psa.id_isencao),
                   psa.dt_isencao                    = nvl(psa2.dt_isencao, psa.dt_isencao),
                   psa.ine_location                  = nvl(psa2.ine_location, psa.ine_location),
                   psa.id_language                   = nvl(psa2.id_language, psa.id_language),
                   psa.notes                         = nvl(psa2.notes, psa.notes),
                   psa.contact_number_3              = nvl(psa2.contact_number_3, psa.contact_number_3),
                   psa.contact_number_4              = nvl(psa2.contact_number_4, psa.contact_number_4),
                   psa.birth_place                   = nvl(psa2.birth_place, psa.birth_place),
                   psa.pension                       = nvl(psa2.pension, psa.pension),
                   psa.net_wage                      = nvl(psa2.net_wage, psa.net_wage),
                   psa.unemployment_subsidy          = nvl(psa2.unemployment_subsidy, psa.unemployment_subsidy),
                   psa.id_geo_state                  = nvl(psa2.id_geo_state, psa.id_geo_state),
                   psa.num_contrib                   = nvl(psa2.num_contrib, psa.num_contrib),
                   psa.id_currency_pension           = nvl(psa2.id_currency_pension, psa.id_currency_pension),
                   psa.id_currency_net_wage          = nvl(psa2.id_currency_net_wage, psa.id_currency_net_wage),
                   psa.id_currency_unemp_sub         = nvl(psa2.id_currency_unemp_sub, psa.id_currency_unemp_sub),
                   psa.flg_migrator                  = nvl(psa2.flg_migrator, psa.flg_migrator),
                   psa.desc_geo_state                = nvl(psa2.desc_geo_state, psa.desc_geo_state),
                   psa.id_episode                    = psa2.id_episode,
                   psa.id_doc_type                   = nvl(psa2.id_doc_type, psa.id_doc_type),
                   psa.national_health_number        = nvl(psa2.national_health_number, psa.national_health_number),
                   psa.document_identifier_number    = nvl(psa2.document_identifier_number,
                                                           psa.document_identifier_number),
                   psa.doc_ident_validation_date     = nvl(psa2.doc_ident_validation_date, psa.doc_ident_validation_date),
                   psa.doc_ident_identification_date = nvl(psa2.doc_ident_identification_date,
                                                           psa.doc_ident_identification_date),
                   psa.flg_sns_unknown_reason        = nvl(psa2.flg_sns_unknown_reason, psa.flg_sns_unknown_reason),
                   psa.legal_guardian                = nvl(psa2.legal_guardian, psa.legal_guardian),
                   psa.flg_nhn_status                = nvl(psa2.flg_nhn_status, psa.flg_nhn_status)
        WHEN NOT MATCHED THEN
            INSERT
                (id_pat_soc_attributes,
                 id_patient,
                 marital_status,
                 address,
                 location,
                 district,
                 zip_code,
                 num_main_contact,
                 num_contact,
                 flg_job_status,
                 id_country_nation,
                 id_country_address,
                 id_scholarship,
                 id_religion,
                 mother_name,
                 father_name,
                 id_isencao,
                 id_institution,
                 dt_isencao,
                 ine_location,
                 id_language,
                 notes,
                 contact_number_3,
                 contact_number_4,
                 birth_place,
                 pension,
                 net_wage,
                 unemployment_subsidy,
                 id_geo_state,
                 num_contrib,
                 id_currency_pension,
                 id_currency_net_wage,
                 id_currency_unemp_sub,
                 flg_migrator,
                 desc_geo_state,
                 id_episode,
                 national_health_number,
                 document_identifier_number,
                 doc_ident_validation_date,
                 doc_ident_identification_date,
                 flg_sns_unknown_reason,
                 legal_guardian,
                 flg_nhn_status)
            VALUES
                (seq_pat_soc_attributes.nextval,
                 i_patient,
                 psa2.marital_status,
                 psa2.address,
                 psa2.location,
                 psa2.district,
                 psa2.zip_code,
                 psa2.num_main_contact,
                 psa2.num_contact,
                 psa2.flg_job_status,
                 psa2.id_country_nation,
                 psa2.id_country_address,
                 psa2.id_scholarship,
                 psa2.id_religion,
                 psa2.mother_name,
                 psa2.father_name,
                 psa2.id_isencao,
                 i_prof.institution,
                 psa2.dt_isencao,
                 psa2.ine_location,
                 psa2.id_language,
                 psa2.notes,
                 psa2.contact_number_3,
                 psa2.contact_number_4,
                 psa2.birth_place,
                 psa2.pension,
                 psa2.net_wage,
                 psa2.unemployment_subsidy,
                 psa2.id_geo_state,
                 psa2.num_contrib,
                 psa2.id_currency_pension,
                 psa2.id_currency_net_wage,
                 psa2.id_currency_unemp_sub,
                 psa2.flg_migrator,
                 psa2.desc_geo_state,
                 i_episode,
                 psa2.national_health_number,
                 psa2.document_identifier_number,
                 psa2.doc_ident_validation_date,
                 psa2.doc_ident_identification_date,
                 psa2.flg_sns_unknown_reason,
                 psa2.legal_guardian,
                 psa2.flg_nhn_status);
    
        g_error := 'GET CLIN_RECORD 1';
        OPEN c_clin_record(i_prof.institution);
        FETCH c_clin_record
            INTO l_clin_record;
        g_found := c_clin_record%NOTFOUND;
        CLOSE c_clin_record;
    
        IF g_found
           OR l_clin_record.num_clin_record IS NULL
        THEN
        
            g_error := 'GET CLIN_RECORD 2';
        
            l_id_clin_record := l_clin_record.id_clin_record;
        
            OPEN c_clin_record(i_id_inst);
            FETCH c_clin_record
                INTO l_clin_record;
            CLOSE c_clin_record;
        
            IF g_found
            THEN
            
                l_clin_record.id_institution := i_prof.institution;
                l_clin_record.id_clin_record := ts_clin_record.next_key * c_seq_offset;
                l_clin_record.flg_status     := g_clin_rec_act;
                l_clin_record.id_patient     := i_patient;
            
                g_error := 'INSERT INTO CLIN_RECORD';
                ts_clin_record.ins(rec_in => l_clin_record, gen_pky_in => FALSE, rows_out => l_rows_cr);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CLIN_RECORD',
                                              i_rowids     => l_rows_cr,
                                              o_error      => l_error);
            
                SELECT id_clin_record
                  INTO v_id_clin_record
                  FROM clin_record
                 WHERE ROWID = l_rows_cr(l_rows_cr.first);
            
                v_pat_identifier := seq_pat_identifier.nextval * c_seq_offset;
            
                INSERT INTO pat_identifier
                    (id_pat_identifier,
                     id_patient,
                     id_institution,
                     alert_process_number,
                     register_date,
                     flg_status,
                     id_clin_record)
                VALUES
                    (v_pat_identifier,
                     l_clin_record.id_patient,
                     l_clin_record.id_institution,
                     l_clin_record.num_clin_record,
                     vcurrentdate,
                     l_clin_record.flg_status,
                     NULL);
            
                INSERT INTO pat_identifier_hist
                    (id_pat_identifier_hist,
                     id_pat_identifier,
                     id_patient,
                     id_institution,
                     alert_process_number,
                     register_date,
                     flg_status,
                     id_clin_record,
                     operation_time,
                     operation_user,
                     operation_type)
                VALUES
                    (seq_pat_identifier_hist.nextval * c_seq_offset,
                     v_pat_identifier,
                     l_clin_record.id_patient,
                     l_clin_record.id_institution,
                     l_clin_record.num_clin_record,
                     SYSDATE,
                     l_clin_record.flg_status,
                     NULL,
                     current_timestamp,
                     i_prof.id,
                     'C');
            
            ELSE
            
                g_error := 'UPDATE CLIN_RECORD';
                ts_clin_record.upd(num_clin_record_in => l_clin_record.num_clin_record,
                                   id_pat_family_in   => l_clin_record.id_pat_family,
                                   id_clin_record_in  => l_id_clin_record,
                                   rows_out           => l_rows_cr);
            
                t_data_gov_mnt.process_update(i_lang,
                                              i_prof,
                                              'CLIN_RECORD',
                                              l_rows_cr,
                                              l_error,
                                              table_varchar('NUM_CLIN_RECORD', 'ID_PAT_FAMILY'));
            
                UPDATE pat_identifier
                   SET alert_process_number = l_clin_record.num_clin_record
                 WHERE id_clin_record = l_id_clin_record;
            
                UPDATE pat_identifier_hist
                   SET alert_process_number = l_clin_record.num_clin_record
                 WHERE id_clin_record = l_id_clin_record;
            
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_TRANSFER_ADT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END update_transfer_adt;

    FUNCTION get_patient_name
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_is_prof_resp  IN BOOLEAN,
        i_id_sys_config IN sys_config.id_sys_config%TYPE DEFAULT 'PATIENT_NAME_PATTERN',
        o_error         OUT t_error_out
    ) RETURN VARCHAR2 IS
        l_name          patient.name%TYPE;
        l_alias         patient.alias%TYPE;
        l_vipstatus     patient.vip_status%TYPE;
        l_other_names_1 patient.other_names_1%TYPE;
        l_other_names_2 patient.other_names_2%TYPE;
        l_other_names_3 patient.other_names_3%TYPE;
        l_other_names_4 patient.other_names_4%TYPE;
        l_first_name    patient.first_name%TYPE;
        l_second_name   patient.second_name%TYPE;
        l_middle_name   patient.middle_name%TYPE;
        l_last_name     patient.last_name%TYPE;
    
        g_concat_other_names CONSTANT VARCHAR(1 CHAR) := pk_sysconfig.get_config('ADT_CONCAT_OTHER_NAMES', i_prof);
    
    BEGIN
        --Get patient s data
        SELECT p.name,
               p.alias,
               p.vip_status,
               p.other_names_1,
               p.other_names_2,
               p.other_names_3,
               p.other_names_4,
               p.first_name,
               p.second_name,
               p.middle_name,
               p.last_name
          INTO l_name,
               l_alias,
               l_vipstatus,
               l_other_names_1,
               l_other_names_2,
               l_other_names_3,
               l_other_names_4,
               l_first_name,
               l_second_name,
               l_middle_name,
               l_last_name
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        --If the professional is responsible for patient (physician or nurse)
        --or if he has not alias
        IF i_is_prof_resp
        THEN
            -- returns patient s real name
            IF l_vipstatus IS NOT NULL
            THEN
                l_name := pk_sysdomain.get_domain('PATIENT.VIP_STATUS.ABBR', l_vipstatus, i_lang) || ' ' || l_name;
            ELSE
                l_name := l_name;
            END IF;
        
            --For KW arabic names are concatenated, for US they aren t, for all other markets those fields are not used
            IF g_concat_other_names = pk_alert_constant.g_yes
            THEN
                --concatenate other names if professional is responsible for patient                
                IF i_id_sys_config = 'BARCODE_PATIENT_NAME_PATTERN'
                THEN
                    --labels 
                    l_name := concat_other_names(i_lang,
                                                 i_prof,
                                                 l_first_name,
                                                 l_second_name,
                                                 l_middle_name,
                                                 l_last_name,
                                                 i_id_sys_config => i_id_sys_config,
                                                 include_sep     => FALSE);
                END IF;
                l_name := l_name || concat_other_names(i_lang,
                                                       i_prof,
                                                       l_other_names_1,
                                                       l_other_names_4,
                                                       l_other_names_2,
                                                       l_other_names_3,
                                                       i_id_sys_config => i_id_sys_config);
            END IF;
        ELSE
            --else returns patient s alias
            IF l_vipstatus IS NOT NULL
            THEN
                IF l_alias IS NOT NULL
                THEN
                    l_name := pk_sysdomain.get_domain('PATIENT.VIP_STATUS.ABBR', l_vipstatus, i_lang) || ' "' ||
                              l_alias || '"';
                ELSE
                    l_name := pk_sysdomain.get_domain('PATIENT.VIP_STATUS.ABBR', l_vipstatus, i_lang) || ' ' || l_name;
                
                    --For KW arabic names are concatenated, for US they aren t, for all other markets those fields are not used
                    IF g_concat_other_names = pk_alert_constant.g_yes
                    THEN
                        --concatenate other names if professional is responsible for patient                
                        IF i_id_sys_config = 'BARCODE_PATIENT_NAME_PATTERN'
                        THEN
                            --labels 
                            l_name := concat_other_names(i_lang,
                                                         i_prof,
                                                         l_first_name,
                                                         l_second_name,
                                                         l_middle_name,
                                                         l_last_name,
                                                         i_id_sys_config => i_id_sys_config,
                                                         include_sep     => FALSE);
                        END IF;
                        --concatenate other names if professional is responsible for patient
                        l_name := l_name || concat_other_names(i_lang,
                                                               i_prof,
                                                               l_other_names_1,
                                                               l_other_names_4,
                                                               l_other_names_2,
                                                               l_other_names_3,
                                                               i_id_sys_config => i_id_sys_config);
                    END IF;
                
                END IF;
            ELSE
                IF l_alias IS NOT NULL
                THEN
                    l_name := '"' || l_alias || '"';
                ELSE
                    --For KW arabic names are concatenated, for US they aren t, for all other markets those fields are not used
                    IF g_concat_other_names = pk_alert_constant.g_yes
                    THEN
                        --concatenate other names if professional is responsible for patient
                        IF i_id_sys_config = 'BARCODE_PATIENT_NAME_PATTERN'
                        THEN
                            --labels                                                              
                            l_name := concat_other_names(i_lang,
                                                         i_prof,
                                                         l_first_name,
                                                         l_second_name,
                                                         l_middle_name,
                                                         l_last_name,
                                                         i_id_sys_config => i_id_sys_config,
                                                         include_sep     => FALSE);
                        END IF;
                        l_name := l_name || concat_other_names(i_lang,
                                                               i_prof,
                                                               l_other_names_1,
                                                               l_other_names_4,
                                                               l_other_names_2,
                                                               l_other_names_3,
                                                               i_id_sys_config => i_id_sys_config);
                    END IF;
                
                END IF;
            END IF;
        END IF;
    
        RETURN l_name;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PATIENT_NAME',
                                              o_error    => o_error);
            --pk_utils.undo_changes;
            RETURN NULL;
    END get_patient_name;

    FUNCTION get_patient_name
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_is_prof_resp  IN PLS_INTEGER,
        i_id_sys_config IN sys_config.id_sys_config%TYPE DEFAULT 'PATIENT_NAME_PATTERN'
    ) RETURN VARCHAR2 IS
    
        v_is_prof_resp BOOLEAN;
        v_error        t_error_out;
    BEGIN
    
        v_is_prof_resp := i_is_prof_resp = g_true;
    
        RETURN get_patient_name(i_lang, i_prof, i_patient, v_is_prof_resp, i_id_sys_config, v_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PATIENT_NAME',
                                              o_error    => v_error);
            --pk_utils.undo_changes;
            RETURN NULL;
    END get_patient_name;

    FUNCTION show_patient_info
    (
        i_lang         IN language.id_language%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_is_prof_resp IN PLS_INTEGER
    ) RETURN BOOLEAN IS
        valias  patient.alias%TYPE;
        v_error t_error_out;
        vresult BOOLEAN := FALSE;
    BEGIN
    
        IF i_is_prof_resp = g_true
        THEN
            vresult := TRUE;
        ELSE
        
            --Get patient s data
            SELECT alias
              INTO valias
              FROM patient
             WHERE id_patient = i_patient;
        
            IF valias IS NULL
            THEN
                vresult := TRUE;
            END IF;
        
        END IF;
    
        RETURN vresult;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SHOW_PATIENT_INFO',
                                              o_error    => v_error);
            --pk_utils.undo_changes;
            RETURN FALSE;
    END show_patient_info;

    FUNCTION call_show_patient_info
    (
        i_lang         IN language.id_language%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_is_prof_resp IN PLS_INTEGER
    ) RETURN PLS_INTEGER IS
        valias  patient.alias%TYPE;
        v_error t_error_out;
        vresult PLS_INTEGER := g_false;
    BEGIN
    
        IF i_is_prof_resp = g_true
        THEN
            vresult := g_true;
        ELSE
        
            --Get patient s data
            SELECT alias
              INTO valias
              FROM patient
             WHERE id_patient = i_patient;
        
            IF valias IS NULL
            THEN
                vresult := g_true;
            END IF;
        
        END IF;
    
        RETURN vresult;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CALL_SHOW_PATIENT_INFO',
                                              o_error    => v_error);
            --pk_utils.undo_changes;
            RETURN g_false;
    END call_show_patient_info;

    FUNCTION has_non_disclosure_level
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN BOOLEAN IS
        vnondisclosurelevel patient.non_disclosure_level%TYPE;
        vresult             BOOLEAN := FALSE;
        v_error             t_error_out;
    BEGIN
    
        --Get patient s non disclosure level
        SELECT non_disclosure_level
          INTO vnondisclosurelevel
          FROM patient
         WHERE id_patient = i_patient;
    
        IF vnondisclosurelevel IS NOT NULL
        THEN
            vresult := TRUE;
        END IF;
    
        RETURN vresult;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'HAS_NON_DISCLOSURE_LEVEL',
                                              o_error    => v_error);
            --pk_utils.undo_changes;
            RETURN FALSE;
    END has_non_disclosure_level;

    FUNCTION get_pat_non_disc_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        vnondisclosurelevel patient.non_disclosure_level%TYPE;
        vresult             VARCHAR2(1000) := '';
        v_error             t_error_out;
        vpatnondiscoptions  table_varchar2;
    BEGIN
    
        --Get patient s level of non disclosure
        SELECT non_disclosure_level,
               pk_sysdomain.get_domain('PATIENT.NON_DISCLOSURE_LEVEL', non_disclosure_level, i_lang)
          INTO vnondisclosurelevel, vresult
          FROM patient
         WHERE id_patient = i_patient;
    
        -- If is partial non disclosure
        IF vnondisclosurelevel = 'P'
        THEN
        
            vresult := '';
        
            --Get patient s partial non disclosure options
            SELECT pk_translation.get_translation(i_lang,
                                                  'NON_DISCLOSURE_OPTION.CODE_NON_DISCLOSURE_OPTION.' ||
                                                  id_non_disclosure_option)
              BULK COLLECT
              INTO vpatnondiscoptions
              FROM pat_non_disclsre_opt
             WHERE id_patient = i_patient;
        
            FOR indx IN 1 .. vpatnondiscoptions.count
            LOOP
                vresult := vresult || vpatnondiscoptions(indx) || ', ';
            END LOOP;
        
            vresult := substr(vresult, 1, length(vresult) - 2);
        END IF;
    
        RETURN vresult;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_NON_DISC_OPTIONS',
                                              o_error    => v_error);
            --pk_utils.undo_changes;
            RETURN vresult;
    END get_pat_non_disc_options;

    FUNCTION get_pat_non_disclosure_icon
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        v_error t_error_out;
    BEGIN
    
        IF has_non_disclosure_level(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient)
        THEN
            RETURN g_vip_icon;
        ELSE
            RETURN '';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_NON_DISCLOSURE_ICON',
                                              o_error    => v_error);
            --pk_utils.undo_changes;
            RETURN '';
    END get_pat_non_disclosure_icon;

    PROCEDURE get_patient_name
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_is_prof_resp IN BOOLEAN,
        o_vip_status   OUT VARCHAR2,
        o_name         OUT VARCHAR2
    ) IS
        l_name          patient.name%TYPE;
        l_alias         patient.alias%TYPE;
        l_vipstatus     patient.vip_status%TYPE;
        l_other_names_1 patient.other_names_1%TYPE;
        l_other_names_2 patient.other_names_2%TYPE;
        l_other_names_3 patient.other_names_3%TYPE;
        l_other_names_4 patient.other_names_3%TYPE;
    
        verror t_error_out;
    BEGIN
        --Get patient s data
        SELECT p.name, p.alias, p.vip_status, p.other_names_1, p.other_names_2, p.other_names_3, p.other_names_4
          INTO l_name, l_alias, l_vipstatus, l_other_names_1, l_other_names_2, l_other_names_3, l_other_names_4
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        --If the professional is responsible for patient (physician or nurse)
        --or if he has not alias
        IF i_is_prof_resp
           OR l_alias IS NULL
        THEN
            -- returns patient s real name
            o_name := l_name || concat_other_names(i_lang,
                                                   i_prof,
                                                   l_other_names_1,
                                                   l_other_names_4,
                                                   l_other_names_2,
                                                   l_other_names_3);
        ELSE
            --else returns patient s alias
            IF l_vipstatus IS NOT NULL
            THEN
                o_vip_status := pk_sysdomain.get_domain('PATIENT.VIP_STATUS.ABBR', l_vipstatus, i_lang);
            END IF;
        
            o_name := l_alias;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PATIENT_NAME',
                                              o_error    => verror);
            --pk_utils.undo_changes;
    END get_patient_name;

    FUNCTION get_vip_icons
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_vip_icons OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN O_VIP_ICONS';
        OPEN o_vip_icons FOR
            SELECT pk_message.get_message(i_lang, g_vip_icon_message) desc_message
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_VIP_ICONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_vip_icons);
            RETURN FALSE;
    END get_vip_icons;

    /********************************************************************************************
    * Create an health_plan associated to an institution
    *
    * @param i_lang                           language id
    * @param i_institution                    institution id
    * @param desc_health_plan                 health plan description
    * @param i_insurance_class                insurance class
    * @param i_health_plan_entity             health plan entity (insurance company or other)
    * @param o_id_health_plan                 created health plan id
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 Susana Seixas (BM copied it to PK_ADT)
    * @version                                2.6
    * @since                                  2010-03-03
    ********************************************************************************************/

    FUNCTION create_health_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_institution        IN institution.id_institution%TYPE,
        desc_health_plan     IN VARCHAR2,
        i_insurance_class    IN health_plan.insurance_class%TYPE,
        i_health_plan_entity IN health_plan.id_health_plan_entity%TYPE,
        o_id_health_plan     OUT health_plan.id_health_plan%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        vidhealthplaninstit health_plan_instit.id_health_plan_instit%TYPE;
    
    BEGIN
    
        --We need to create a new health plan
        IF NOT t_health_plan.ins_health_plan(i_lang => i_lang,
                                             
                                             i_institution        => i_institution,
                                             desc_health_plan     => desc_health_plan,
                                             i_insurance_class    => i_insurance_class,
                                             i_flg_client         => 'Y',
                                             i_health_plan_entity => i_health_plan_entity,
                                             o_id_health_plan     => o_id_health_plan,
                                             o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        SELECT MAX(id_health_plan_instit) + 1
          INTO vidhealthplaninstit
          FROM health_plan_instit;
    
        --and associate the new health plan with the institution
        INSERT INTO health_plan_instit
            (id_health_plan_instit, id_institution, id_health_plan)
        VALUES
            (vidhealthplaninstit, i_institution, o_id_health_plan);
    
        --notify intf_alert that the new health plan is available in the institution
        pk_ia_event_backoffice.health_plan_institution_new(i_id_health_plan_institution => vidhealthplaninstit,
                                                           i_id_institution             => i_institution);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_HEALTH_PLAN',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_health_plan;

    /********************************************************************************************
    * Create an health_plan entity
    *
    * @param i_lang                           language id
    * @param desc_health_plan                 health plan description
    * @param o_id_health_plan_entity          created health plan entity id
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 BM
    * @version                                2.6
    * @since                                  2010-03-03
    ********************************************************************************************/
    FUNCTION create_health_plan_entity
    (
        i_lang                  IN language.id_language%TYPE,
        desc_health_plan_entity IN VARCHAR2,
        o_id_health_plan_entity OUT health_plan.id_health_plan_entity%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        SELECT MAX(id_health_plan_entity) + 1
          INTO o_id_health_plan_entity
          FROM health_plan_entity;
    
        INSERT INTO health_plan_entity
            (id_health_plan_entity, code_health_plan_entity, flg_available, create_time)
        VALUES
            (o_id_health_plan_entity,
             'HEALTH_PLAN_ENTITY.CODE_HEALTH_PLAN_ENTITY.' || o_id_health_plan_entity,
             'Y',
             current_timestamp);
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => 'HEALTH_PLAN_ENTITY.CODE_HEALTH_PLAN_ENTITY.' ||
                                                               o_id_health_plan_entity,
                                               i_desc_trans => desc_health_plan_entity);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_HEALTH_PLAN_ENTITY',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_health_plan_entity;

    /********************************************************************************************
    * Gets patient s family physician life line post office box
    *
    * @param i_lang                           language id
    * @param i_prof                           professional info
    * @param i_patient                        patient identifier
    * @param o_po_box                         life line post office box
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 BM
    * @version                                2.6
    * @since                                  2010-03-03
    ********************************************************************************************/
    FUNCTION get_life_line_post_office_box
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_po_box  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        g_informed_via_edifact CONSTANT VARCHAR2(5) := 'ED';
    
    BEGIN
    
        SELECT life_line_post_office_box
          INTO o_po_box
          FROM pat_professional_inst pp
          JOIN v_physician_institution_nl pnl
            ON pp.id_professional = pnl.id_professional
         WHERE pp.id_patient = i_patient
              --AND pp.id_institution = i_prof.INSTITUTION
           AND pp.flg_family_physician = pk_alert_constant.g_yes
           AND pnl.informed_via = g_informed_via_edifact
           AND rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_po_box := NULL;
        
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LIFE_LINE_POST_OFFICE_BOX',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END get_life_line_post_office_box;

    /********************************************************************************************
    * Gets health plan info
    *
    * @param i_lang                           language id
    * @param i_prof                           professional info
    * @param i_patient                        patient identifier
    * @param i_episode                        episode identifier
    * @param o_error                          error message
    *
    * @return                                 health plan information
    *
    * @author                                 BM
    * @version                                2.6
    * @since                                  2010-03-04
    ********************************************************************************************/
    FUNCTION get_health_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_health_plan VARCHAR2(2000);
    BEGIN
        SELECT desc_hplan
          INTO l_health_plan
          FROM (SELECT php.num_health_plan || ' - ' ||
                       pk_translation.get_translation(i_lang,
                                                      'HEALTH_PLAN_ENTITY.CODE_HEALTH_PLAN_ENTITY.' ||
                                                      hp.id_health_plan_entity) || ' - ' ||
                       pk_translation.get_translation(i_lang, 'HEALTH_PLAN.CODE_HEALTH_PLAN.' || php.id_health_plan) desc_hplan,
                       decode(ehp.id_episode, i_id_episode, 1, 0) in_use_epis,
                       decode(php.flg_default, pk_alert_constant.g_yes, 1, 0) in_use,
                       decode(ehp.flg_primary, 'Y', 1, 0) epis_flg_primary
                  FROM pat_health_plan php
                  LEFT JOIN epis_health_plan ehp
                    ON php.id_pat_health_plan = ehp.id_pat_health_plan
                  JOIN health_plan hp
                    ON hp.id_health_plan = php.id_health_plan
                 WHERE php.id_patient = i_id_patient
                   AND php.id_institution IN
                       (SELECT *
                          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt)))
                   AND (php.flg_default = pk_alert_constant.g_yes OR
                       nvl2(i_id_episode,
                             decode(ehp.id_episode, i_id_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                             pk_alert_constant.g_no) = pk_alert_constant.g_yes)
                   AND php.flg_status = g_adt_hplan_active
                   AND (ehp.id_episode IS NULL OR ehp.id_episode = i_id_episode)
                 ORDER BY epis_flg_primary DESC, in_use_epis DESC, in_use DESC)
         WHERE rownum = 1;
        RETURN l_health_plan;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_health_plan;

    /********************************************************************************************
    * set_inp_episode Create or update inp episode
    *
    * i_lang                Language ID
    * i_id_patient          Patient ID
    * i_id_visit            Visit ID
    * i_id_episode          Episode ID
    * i_external_cause      External cause for admission
    * i_dt_begin            Admission date in TSTZ format
    * i_id_professional     Professional ID - PROFESSIONAL(ID, INST, SOFT),
    * i_health_plan         Patient health plan
    * i_epis_type           Episode Type
    * i_id_dep_clin_serv    Dep clinical service
    * i_id_room             Room
    * i_id_episode_ext      External Episode ID
    * i_flg_type
    * i_type
    * i_dt_surgery          Date of surgery
    * i_flg_surgery
    * i_id_prev_episode     Previous Episode ID
    * i_id_external_sys     External System ID
    * i_prof_resp           Professional responsible 
    * i_id_bed              Bed ID
    * i_admition_notes      Admission notes
    * @param i_dt_creation_allocation Date in which the bed allocation was done
    * @param i_dt_creation_resp       Hand-off date
    * o_id_episode          Episode ID returned
    * o_error               Error executing function
    *
    * @author               Bruno Martins
    * @since                2009/02/18
    * @version              2.5
    *
    * @author               Luís Maia
    * @comment              Reviwed function to avoid existence of two IN parameters with episode DT_BEGIN information
    * @since                2009/09/10
    * @version              2.5.0.6
    * @dependents           ADT TEAM
    **********************************************************************************************/
    FUNCTION set_inp_episode
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_visit               IN visit.id_visit%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_external_cause         IN visit.id_external_cause%TYPE,
        i_dt_begin               IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_disch_sched         IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_id_professional        IN profissional,
        i_health_plan            IN health_plan.id_health_plan%TYPE,
        i_epis_type              IN episode.id_epis_type%TYPE,
        i_id_dep_clin_serv       IN NUMBER,
        i_first_dep_clin_serv    IN NUMBER,
        i_id_room                IN NUMBER,
        i_id_episode_ext         IN VARCHAR2,
        i_flg_type               IN VARCHAR2,
        i_type                   IN VARCHAR2,
        i_dt_surgery             IN VARCHAR2,
        i_flg_surgery            IN VARCHAR2,
        i_id_prev_episode        IN episode.id_prev_episode%TYPE,
        i_id_external_sys        IN epis_ext_sys.id_external_sys%TYPE,
        i_prof_resp              IN profissional,
        i_id_bed                 IN epis_info.id_bed%TYPE,
        i_admition_notes         IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_admission_notes     IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE,
        i_id_transp_entity       IN transportation.id_transp_entity%TYPE,
        i_origin                 IN visit.id_origin%TYPE,
        i_companion              IN epis_info.companion%TYPE,
        i_current_timestamp      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_ehr                IN episode.flg_ehr%TYPE,
        i_flg_bed_type           IN bed.flg_type%TYPE,
        i_desc_bed               IN bed.desc_bed%TYPE,
        i_dt_creation_allocation IN bmng_allocation_bed.dt_creation%TYPE,
        i_dt_creation_resp       IN epis_prof_resp.dt_execute_tstz%TYPE,
        i_flg_resp_type          IN VARCHAR2,
        i_flg_type_upd           IN VARCHAR2,
        i_id_schedule            IN schedule.id_schedule%TYPE,
        i_transaction_id         IN VARCHAR2,
        i_id_cancel_reason       IN cancel_reason.id_cancel_reason%TYPE,
        i_id_waiting_list        IN waiting_list.id_waiting_list%TYPE DEFAULT NULL,
        o_id_episode             OUT NUMBER,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        err_ins_episode EXCEPTION;
        PROCEDURE reset_context_admission IS
        BEGIN
            pk_context_api.set_parameter('ADMISSION_ADT_YN', 'N');
        END;
    
        PROCEDURE setup_context_admission IS
        BEGIN
            pk_context_api.set_parameter('ADMISSION_ADT_YN', 'Y');
        END;
    
        FUNCTION process_error
        (
            i_sqlcode   IN VARCHAR2,
            i_sqlerrm   IN VARCHAR2,
            i_exception IN VARCHAR2
        ) RETURN BOOLEAN IS
        BEGIN
        
            pk_alert_exceptions.process_error(i_lang,
                                              i_sqlcode,
                                              i_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              i_exception,
                                              o_error);
            reset_context_admission();
            RETURN FALSE;
        
        END process_error;
    
    BEGIN
    
        setup_context_admission();
    
        --If there is no episode
        IF i_id_episode IS NULL
        THEN
            g_error := 'CALL PK_API_INPATIENT.INS_VISIT_AND_EPISODE FOR ID_EPISODE ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_api_inpatient.ins_visit_and_episode(i_lang                   => i_lang,
                                                          i_prof_intf              => i_id_professional,
                                                          i_prof_resp              => i_prof_resp,
                                                          i_id_patient             => i_id_patient,
                                                          i_id_visit               => i_id_visit,
                                                          i_external_cause         => i_external_cause,
                                                          i_dt_begin               => i_dt_begin,
                                                          i_id_sched               => i_id_schedule,
                                                          i_health_plan            => i_health_plan,
                                                          i_epis_type              => i_epis_type,
                                                          i_id_dep_clin_serv       => i_id_dep_clin_serv,
                                                          i_id_room                => i_id_room,
                                                          i_id_bed                 => i_id_bed,
                                                          i_id_episode_ext         => i_id_episode_ext,
                                                          i_flg_type               => i_flg_type,
                                                          i_flg_ehr                => i_flg_ehr,
                                                          i_dt_disch_sched         => NULL,
                                                          i_admition_notes         => i_admition_notes,
                                                          i_dt_admission_notes     => i_dt_admission_notes,
                                                          i_dt_surgery             => i_dt_surgery,
                                                          i_flg_surgery            => i_flg_surgery,
                                                          i_id_prev_episode        => i_id_prev_episode,
                                                          i_id_external_sys        => i_id_external_sys,
                                                          i_id_origin              => i_origin,
                                                          i_flg_migration          => NULL,
                                                          i_dt_creation_allocation => i_dt_creation_allocation,
                                                          i_dt_creation_resp       => i_dt_creation_resp,
                                                          i_id_waiting_list        => i_id_waiting_list,
                                                          o_id_episode             => o_id_episode,
                                                          o_error                  => o_error)
            
            THEN
                --If there is an error raise it...
                RAISE err_ins_episode;
            END IF;
        ELSE
            g_error := 'CALL PK_API_INPATIENT.INTF_UPD_EPISODE FOR ID_EPISODE ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
        
            IF NOT pk_api_inpatient.upd_visit_and_episode(i_lang                         => i_lang,
                                                          i_prof_resp                    => i_prof_resp,
                                                          i_prof_intf                    => i_id_professional,
                                                          i_id_episode                   => i_id_episode,
                                                          i_id_dep_clin_serv             => i_id_dep_clin_serv,
                                                          i_id_first_dep_clin_serv       => i_first_dep_clin_serv,
                                                          i_id_room                      => i_id_room,
                                                          i_id_bed                       => i_id_bed,
                                                          i_flg_bed_type                 => i_flg_bed_type,
                                                          i_desc_bed                     => i_desc_bed,
                                                          i_dt_begin                     => i_dt_begin,
                                                          i_flg_ehr                      => i_flg_ehr,
                                                          i_dt_disch_sched               => i_dt_disch_sched,
                                                          i_admition_notes               => i_admition_notes,
                                                          i_dt_admission_notes           => NULL,
                                                          i_id_prev_episode              => i_id_prev_episode,
                                                          i_dt_transportation_str        => NULL,
                                                          i_id_transp_entity             => i_id_transp_entity,
                                                          i_transp_flg_time              => 'E',
                                                          i_transp_notes                 => NULL,
                                                          i_origin                       => i_origin,
                                                          i_external_cause               => i_external_cause,
                                                          i_companion                    => i_companion,
                                                          i_internal_type                => 'A',
                                                          i_current_timestamp            => i_current_timestamp,
                                                          i_dt_creation_allocation       => i_dt_creation_allocation,
                                                          i_dt_creation_resp             => i_dt_creation_resp,
                                                          i_flg_resp_type                => i_flg_resp_type,
                                                          i_flg_type_upd                 => i_flg_type_upd,
                                                          i_id_schedule                  => i_id_schedule,
                                                          i_transaction_id               => i_transaction_id,
                                                          i_id_cancel_reason             => i_id_cancel_reason,
                                                          i_epis_flg_type                => i_flg_type,
                                                          i_flg_allow_bed_alloc_inactive => pk_alert_constant.g_no,
                                                          o_bed_allocation               => o_bed_allocation,
                                                          o_exception_info               => o_exception_info,
                                                          o_error                        => o_error)
            THEN
                --If there is an error raise it...
                RAISE err_ins_episode;
            END IF;
        END IF;
    
        -- SUCCESS
        reset_context_admission();
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_ins_episode THEN
            RETURN process_error(SQLCODE, SQLERRM, 'SET_INP_EPISODE_01');
        WHEN OTHERS THEN
            RETURN process_error(SQLCODE, SQLERRM, 'SET_INP_EPISODE_02');
    END set_inp_episode;

    FUNCTION get_patient_name
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        o_name     OUT patient.name%TYPE,
        o_vip_name OUT patient.name%TYPE,
        o_alias    OUT patient.alias%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        vvipstatus      patient.vip_status%TYPE;
        l_other_names_1 patient.other_names_1%TYPE;
        l_other_names_2 patient.other_names_2%TYPE;
        l_other_names_3 patient.other_names_3%TYPE;
        l_other_names_4 patient.other_names_4%TYPE;
    BEGIN
        --Get patient s data
        SELECT p.name, p.alias, p.vip_status, p.other_names_1, p.other_names_2, p.other_names_3, p.other_names_4
          INTO o_name, o_alias, vvipstatus, l_other_names_1, l_other_names_2, l_other_names_3, l_other_names_4
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        IF vvipstatus IS NOT NULL
        THEN
            IF o_alias IS NOT NULL
            THEN
                o_alias := pk_sysdomain.get_domain('PATIENT.VIP_STATUS.ABBR', vvipstatus, i_lang) || ' "' || o_alias || '"';
            END IF;
        
            o_vip_name := pk_sysdomain.get_domain('PATIENT.VIP_STATUS.ABBR', vvipstatus, i_lang) || ' ' || o_name;
            o_vip_name := o_vip_name || concat_other_names(i_lang,
                                                           i_prof,
                                                           l_other_names_1,
                                                           l_other_names_4,
                                                           l_other_names_2,
                                                           l_other_names_3);
        ELSE
            IF o_alias IS NOT NULL
            THEN
                o_alias := '"' || o_alias || '"';
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PATIENT_NAME',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_patient_name;

    FUNCTION get_patient_name_to_sort
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_is_prof_resp IN PLS_INTEGER
    ) RETURN VARCHAR2 IS
        l_name          patient.name%TYPE;
        l_alias         patient.alias%TYPE;
        l_vipstatus     patient.vip_status%TYPE;
        l_other_names_1 patient.other_names_1%TYPE;
        l_other_names_2 patient.other_names_2%TYPE;
        l_other_names_3 patient.other_names_3%TYPE;
        l_other_names_4 patient.other_names_4%TYPE;
    
        g_concat_other_names CONSTANT VARCHAR(1 CHAR) := pk_sysconfig.get_config('ADT_CONCAT_OTHER_NAMES', i_prof);
        v_error t_error_out;
    BEGIN
    
        --Get patient s data
        SELECT p.name, p.alias, p.vip_status, p.other_names_1, p.other_names_2, p.other_names_3, p.other_names_4
          INTO l_name, l_alias, l_vipstatus, l_other_names_1, l_other_names_2, l_other_names_3, l_other_names_4
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        IF i_is_prof_resp <> g_true
           AND l_alias IS NOT NULL
        THEN
            IF l_vipstatus IS NOT NULL
            THEN
                l_name := pk_sysdomain.get_domain('PATIENT.VIP_STATUS.ABBR', l_vipstatus, i_lang) || ' "' || l_alias || '"';
            ELSE
                l_name := l_alias;
            END IF;
        ELSE
            IF l_vipstatus IS NOT NULL
            THEN
                l_name := pk_sysdomain.get_domain('PATIENT.VIP_STATUS.ABBR', l_vipstatus, i_lang) || ' ' || l_name;
            ELSE
                l_name := l_name;
            END IF;
            --For KW arabic names are concatenated, for US they aren t, for all other markets those fields are not used
            IF g_concat_other_names = pk_alert_constant.g_yes
            THEN
                l_name := l_name || concat_other_names(i_lang,
                                                       i_prof,
                                                       l_other_names_1,
                                                       l_other_names_4,
                                                       l_other_names_2,
                                                       l_other_names_3);
            END IF;
        END IF;
    
        RETURN upper(l_name);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PATIENT_NAME_TO_SORT',
                                              o_error    => v_error);
            --pk_utils.undo_changes;
            RETURN NULL;
    END get_patient_name_to_sort;

    /********************************************************************************************
    * Returns Insitution Health Plan Entities
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional (id, institution, software)
    * @param i_id_institution            Institution identifier
    * @param i_id_health_plan_entity_to  Health Plan Entity id for take over
    * @param o_health_plan_entities      Health Plan Entities
    * @param o_flg_hp_type               Health Plans Types applicable? Y/N
    * @param o_error                     Error message
    *
    * @return                       true (sucess), false (error)
    *
    * @author                       Tércio Soares
    * @since                        2010/05/26
    * @version                      2.6.0.3
    ********************************************************************************************/
    FUNCTION get_health_plan_entities_list
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_institution           IN institution.id_institution%TYPE,
        i_id_health_plan_entity_to IN health_plan_entity.id_health_plan_entity%TYPE,
        o_health_plan_entities     OUT pk_types.cursor_type,
        o_flg_hp_type              OUT VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
        l_count     NUMBER := 0;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
    
        o_flg_hp_type := pk_alert_constant.get_no;
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                     JOIN market m
                       ON i.id_market = m.id_market
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        IF l_id_market != 0
        THEN
            SELECT COUNT(hpt.id_health_plan_type)
              INTO l_count
              FROM health_plan_type hpt
             WHERE hpt.flg_available = pk_alert_constant.get_available
               AND hpt.id_market = l_id_market;
        
            IF l_count > 0
            THEN
                o_flg_hp_type := pk_alert_constant.get_yes;
            
            END IF;
        
        END IF;
    
        IF NOT validate_hpe_to(i_lang, i_prof, i_id_institution, l_error_out)
        THEN
            RAISE l_exception;
        ELSE
        
            g_error := 'GET HEALTH_PLAN_ENTITITES CURSOR';
            pk_alertlog.log_debug('PK_ADT.GET_HEALTH_PLAN_ENTITIES_LIST ' || g_error);
        
            IF i_id_health_plan_entity_to IS NULL
            THEN
                OPEN o_health_plan_entities FOR
                    SELECT hpe.id_health_plan_entity,
                           pk_translation.get_translation(i_lang, hpe.code_health_plan_entity) health_plan_entity_desc,
                           hpe.national_identifier_number,
                           nvl(hpto.flg_status, pk_alert_constant.get_no) flg_take_over,
                           decode(hpto.flg_status,
                                  g_adt_hpe_to_sch,
                                  pk_message.get_message(i_lang, 'ADMINISTRATOR_T706'),
                                  g_adt_hpe_to_finished,
                                  pk_message.get_message(i_lang, 'ADMINISTRATOR_T707'),
                                  pk_message.get_message(i_lang, 'ADMINISTRATOR_T779')) takeover,
                           pk_date_utils.date_send_tsz(i_lang, hpto.take_over_time, i_prof) takeover_time,
                           decode(hpto.id_health_plan,
                                  NULL,
                                  NULL,
                                  (SELECT hp2.id_health_plan_entity
                                     FROM health_plan hp2
                                    WHERE hp2.id_health_plan = hpto.id_health_plan)) takeover_id_health_plan_entity,
                           hpto.id_health_plan takeover_id_health_plan,
                           hpto.notes,
                           verifiy_hpe_take_over_possible(i_lang, hpe.id_health_plan_entity) flg_take_over_possible
                      FROM health_plan_entity hpe, health_plan_entity_instit hpei, health_plan_take_over hpto
                     WHERE hpei.id_institution = i_id_institution
                       AND hpei.id_health_plan_entity = hpe.id_health_plan_entity
                       AND hpe.flg_available = pk_alert_constant.get_available
                       AND hpto.id_health_plan_entity(+) = hpe.id_health_plan_entity;
            ELSE
                OPEN o_health_plan_entities FOR
                    SELECT hpe.id_health_plan_entity,
                           pk_translation.get_translation(i_lang, hpe.code_health_plan_entity) health_plan_entity_desc,
                           hpe.national_identifier_number,
                           nvl(hpto.flg_status, pk_alert_constant.get_no) flg_take_over,
                           decode(hpto.flg_status,
                                  g_adt_hpe_to_sch,
                                  pk_message.get_message(i_lang, 'ADMINISTRATOR_T706'),
                                  g_adt_hpe_to_finished,
                                  pk_message.get_message(i_lang, 'ADMINISTRATOR_T706'),
                                  pk_message.get_message(i_lang, 'ADMINISTRATOR_T779')) takeover,
                           pk_date_utils.date_send_tsz(i_lang, hpto.take_over_time, i_prof) takeover_time,
                           decode(hpto.id_health_plan,
                                  NULL,
                                  NULL,
                                  (SELECT hp2.id_health_plan_entity
                                     FROM health_plan hp2
                                    WHERE hp2.id_health_plan = hpto.id_health_plan)) takeover_id_health_plan_entity,
                           hpto.id_health_plan takeover_id_health_plan,
                           hpto.notes,
                           verifiy_hpe_take_over_possible(i_lang, hpe.id_health_plan_entity) flg_take_over_possible
                      FROM health_plan_entity hpe, health_plan_entity_instit hpei, health_plan_take_over hpto
                     WHERE hpei.id_institution = i_id_institution
                       AND hpei.id_health_plan_entity = hpe.id_health_plan_entity
                       AND hpe.flg_available = pk_alert_constant.get_available
                       AND hpe.id_health_plan_entity != i_id_health_plan_entity_to
                       AND hpto.id_health_plan_entity(+) = hpe.id_health_plan_entity;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error || ' / ' || l_error_out.err_desc,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_HEALTH_PLAN_ENTITIES_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_health_plan_entities);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_HEALTH_PLAN_ENTITIES_LIST',
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_health_plan_entities);
            RETURN FALSE;
    END get_health_plan_entities_list;

    /********************************************************************************************
    * Validate Insitution Health Plan Entities take over dates
    *
    * @param i_lang                 Language id
    * @param i_prof                 Professional (id, institution, software)
    * @param i_id_institution       Institution identifier
    * @param o_error                Error message
    *
    * @return                       true (sucess), false (error)
    *
    * @author                       Tércio Soares
    * @since                        2010/05/31
    * @version                      2.6.0.3
    ********************************************************************************************/
    FUNCTION validate_hpe_to
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'VALIDATE INSTITUTION ID = ' || i_id_institution || ' HEALTH_PLAN_ENTITITES TAKE OVER DATE < ' ||
                   current_timestamp;
        pk_alertlog.log_debug('PK_ADT.VALIDATE_HEALTH_PLAN_ENTITIES_TO ' || g_error);
        UPDATE health_plan_take_over hpto
           SET hpto.flg_status = g_adt_hpe_to_finished
         WHERE hpto.id_health_plan_entity IN
               (SELECT hpei.id_health_plan_entity
                  FROM health_plan_entity_instit hpei
                 WHERE hpei.id_institution = i_id_institution)
           AND hpto.flg_status = g_adt_hpe_to_sch
           AND hpto.take_over_time < current_timestamp;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'VALIDATE_HPE_TO',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_hpe_to;

    /********************************************************************************************
    * Validate Health Plan Entity take overs scheduled
    *
    * @param i_lang                  Language id
    * @param i_id_health_plan_entity Health Plan Entity identifier
    *
    * @return                       true ('Y'), false ('N')
    *
    * @author                       Tércio Soares
    * @since                        2010/06/04
    * @version                      2.6.0.3
    ********************************************************************************************/
    FUNCTION verifiy_hpe_take_over_possible
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_health_plan_entity IN health_plan_entity.id_health_plan_entity%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count_s NUMBER := 0;
        l_count_f NUMBER := 0;
    
        l_error t_error_out;
    
    BEGIN
        g_error := 'VALIDATE HEALTH_PLAN_ENTITITY SCHEDULED TAKE OVER';
        pk_alertlog.log_debug('PK_ADT.VALIDATE_HEALTH_PLAN_ENTITIES_TO ' || g_error);
        SELECT COUNT(*)
          INTO l_count_s
          FROM health_plan_take_over hpto
         WHERE hpto.id_health_plan IN
               (SELECT hp.id_health_plan
                  FROM health_plan hp
                 WHERE hp.id_health_plan_entity = i_id_health_plan_entity)
           AND hpto.flg_status = g_adt_hpe_to_sch;
    
        g_error := 'VALIDATE HEALTH_PLAN_ENTITITY CONCLUDED TAKE OVER';
        pk_alertlog.log_debug('PK_ADT.VALIDATE_HEALTH_PLAN_ENTITIES_TO ' || g_error);
        SELECT COUNT(*)
          INTO l_count_f
          FROM health_plan_take_over hpto
         WHERE hpto.id_health_plan_entity = i_id_health_plan_entity
           AND hpto.flg_status = g_adt_hpe_to_finished;
    
        IF l_count_s = 0
           AND l_count_f = 0
        THEN
            RETURN pk_alert_constant.get_yes;
        ELSE
            RETURN pk_alert_constant.get_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'VALIDATE_HPE_TAKE_OVER_POSSIBLE',
                                              o_error    => l_error);
            RETURN pk_alert_constant.get_no;
    END verifiy_hpe_take_over_possible;

    /********************************************************************************************
    * Returns Insitution Health Plans
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_institution        Institution identifier
    * @param i_id_health_plan_entity Health Plan Entity identifier
    * @param o_health_plan           Health Plans
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/26
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_health_plans_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_health_plan_entity IN health_plan_entity.id_health_plan_entity%TYPE,
        o_health_plan           OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET HEALTH_PLAN CURSOR';
        pk_alertlog.log_debug('PK_ADT.GET_HEALTH_PLANS_LIST ' || g_error);
        OPEN o_health_plan FOR
            SELECT hp.id_health_plan,
                   pk_translation.get_translation(i_lang, hp.code_health_plan) health_plan_desc,
                   nvl(hp.flg_status, g_adt_hplan_active) flg_status,
                   pk_sysdomain.get_domain('HEALTH_PLAN.FLG_STATUS', hp.flg_status, i_lang) status_desc,
                   nvl(hpto.flg_status, pk_alert_constant.get_no) flg_take_over
              FROM health_plan hp, health_plan_instit hpi, health_plan_take_over hpto
             WHERE hp.id_health_plan_entity = i_id_health_plan_entity
               AND hp.id_health_plan = hpi.id_health_plan
               AND hpi.id_institution = i_id_institution
               AND hpto.id_health_plan_entity(+) = hp.id_health_plan_entity
               AND hp.flg_available = pk_alert_constant.get_available;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_HEALTH_PLANS_LIST',
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_health_plan);
            RETURN FALSE;
    END get_health_plans_list;

    /********************************************************************************************
    * Returns Health Plan Entity information
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_health_plan_entity Health Plan Entity identifier
    * @param o_health_plan_entity    Health Plan Entity information
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/26
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_health_plan_entity
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_health_plan_entity IN health_plan_entity.id_health_plan_entity%TYPE,
        o_health_plan_entity    OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET HEALTH_PLAN_ENTITY CURSOR';
        pk_alertlog.log_debug('PK_ADT.GET_HEALTH_PLAN_ENTITY ' || g_error);
        OPEN o_health_plan_entity FOR
            SELECT hpe.id_health_plan_entity,
                   hpe.national_identifier_number,
                   pk_translation.get_translation(i_lang, hpe.code_health_plan_entity) health_plan_entity_desc,
                   hpe.short_name,
                   hpe.street,
                   hpe.city,
                   hpe.telephone,
                   hpe.fax,
                   hpe.email,
                   hpe.postal_code,
                   hpe.postal_code_city
              FROM health_plan_entity hpe
             WHERE hpe.flg_available = pk_alert_constant.get_available
               AND hpe.id_health_plan_entity = i_id_health_plan_entity;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_HEALTH_PLAN_ENTITY',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_health_plan_entity);
            RETURN FALSE;
    END get_health_plan_entity;

    /********************************************************************************************
    * Returns Health Plan information
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_health_plan        Health Plan identifier
    * @param o_health_plan           Health Plan information
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/26
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_health_plan
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_health_plan IN health_plan.id_health_plan%TYPE,
        o_health_plan    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET HEALTH_PLAN CURSOR';
        pk_alertlog.log_debug('PK_ADT.GET_HEALTH_PLAN ' || g_error);
        OPEN o_health_plan FOR
            SELECT hp.id_health_plan,
                   hp.id_health_plan_entity,
                   pk_translation.get_translation(i_lang, hpe.code_health_plan_entity) health_plan_entity_desc,
                   pk_translation.get_translation(i_lang, hp.code_health_plan) health_plan_desc,
                   hp.id_health_plan_type,
                   pk_translation.get_translation(i_lang, hpt.code_health_plan_type) health_plan_type_desc,
                   hp.national_identifier_number health_plan_code
              FROM health_plan hp, health_plan_entity hpe, health_plan_type hpt
             WHERE hp.id_health_plan = i_id_health_plan
               AND hpe.id_health_plan_entity(+) = hp.id_health_plan_entity
               AND hpt.id_health_plan_type(+) = hp.id_health_plan_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_HEALTH_PLAN',
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_health_plan);
            RETURN FALSE;
    END get_health_plan;

    /********************************************************************************************
    * Returns Health Plan Entity created/edited in the institution
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_institution               Institution id
    * @param i_id_health_plan_entity        Health Plan Entity id
    * @param i_health_plan_entity_desc      Health Plan Entity name
    * @param i_national_identifier_number   Health Plan Entity identifier
    * @param i_short_name                   Health Plan Entity short name
    * @param i_street                       Health Plan Entity Street
    * @param i_city                         Health Plan Entity City
    * @param i_telephone                    Health Plan Entity Phone number
    * @param i_fax                          Health Plan Entity Fax number
    * @param i_email                        Health Plan Entity E-mail
    * @param i_postal_code                  Health Plan Entity Postal Code
    * @param i_postal_code_city             Health Plan Entity Postal Code City
    * @param o_id_health_plan_entity        Health Plan Entity id
    * @param o_id_health_plan_entity_instit Health Plan Entity Institution id
    * @param o_error                        Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/27
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_health_plan_entity
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_id_institution               IN institution.id_institution%TYPE,
        i_id_health_plan_entity        IN health_plan_entity.id_health_plan_entity%TYPE,
        i_health_plan_entity_desc      IN VARCHAR2,
        i_national_identifier_number   IN health_plan_entity.national_identifier_number%TYPE,
        i_short_name                   IN health_plan_entity.short_name%TYPE,
        i_street                       IN health_plan_entity.street%TYPE,
        i_city                         IN health_plan_entity.city%TYPE,
        i_telephone                    IN health_plan_entity.telephone%TYPE,
        i_fax                          IN health_plan_entity.fax%TYPE,
        i_email                        IN health_plan_entity.email%TYPE,
        i_postal_code                  IN health_plan_entity.postal_code%TYPE,
        i_postal_code_city             IN health_plan_entity.postal_code_city%TYPE,
        o_id_health_plan_entity        OUT health_plan_entity.id_health_plan_entity%TYPE,
        o_id_health_plan_entity_instit OUT health_plan_entity_instit.id_health_plan_entity_instit%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF set_health_plan_entity_ext(i_lang                         => i_lang,
                                      i_prof                         => i_prof,
                                      i_id_institution               => i_id_institution,
                                      i_id_health_plan_entity        => i_id_health_plan_entity,
                                      i_health_plan_entity_desc      => i_health_plan_entity_desc,
                                      i_flg_available                => pk_alert_constant.get_available,
                                      i_national_identifier_number   => i_national_identifier_number,
                                      i_short_name                   => i_short_name,
                                      i_street                       => i_street,
                                      i_city                         => i_city,
                                      i_telephone                    => i_telephone,
                                      i_fax                          => i_fax,
                                      i_email                        => i_email,
                                      i_postal_code                  => i_postal_code,
                                      i_postal_code_city             => i_postal_code_city,
                                      o_id_health_plan_entity        => o_id_health_plan_entity,
                                      o_id_health_plan_entity_instit => o_id_health_plan_entity_instit,
                                      o_error                        => o_error)
        THEN
        
            COMMIT;
            RETURN TRUE;
        ELSE
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_HEALTH_PLAN_ENTITY',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_health_plan_entity;

    /********************************************************************************************
    * Returns Health Plan created/edited in the institution
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_institution               Institution id
    * @param i_id_health_plan               Health Plan id
    * @param i_health_plan_desc             Health Plan name
    * @param i_id_health_plan_entity        Health Plan Entity id
    * @param i_id_health_plan_type          Health Plan type
    * @param i_national_identifier_number   Health Plan Entity identifier
    * @param o_id_health_plan_entity        Health Plan id
    * @param o_id_health_plan_entity_instit Health Plan Institution id
    * @param o_error                        Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/31
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_health_plan
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_institution             IN institution.id_institution%TYPE,
        i_id_health_plan             IN health_plan.id_health_plan%TYPE,
        i_health_plan_desc           IN VARCHAR2,
        i_id_health_plan_entity      IN health_plan.id_health_plan_type%TYPE,
        i_id_health_plan_type        IN health_plan.id_health_plan_type%TYPE,
        i_national_identifier_number IN health_plan_entity.national_identifier_number%TYPE,
        o_id_health_plan             OUT health_plan.id_health_plan%TYPE,
        o_id_health_plan_instit      OUT health_plan_instit.id_health_plan_instit%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF set_health_plan_ext(i_lang                       => i_lang,
                               i_prof                       => i_prof,
                               i_id_institution             => i_id_institution,
                               i_id_health_plan             => i_id_health_plan,
                               i_health_plan_desc           => i_health_plan_desc,
                               i_id_health_plan_entity      => i_id_health_plan_entity,
                               i_id_health_plan_type        => i_id_health_plan_type,
                               i_flg_available              => pk_alert_constant.get_available,
                               i_national_identifier_number => i_national_identifier_number,
                               o_id_health_plan             => o_id_health_plan,
                               o_id_health_plan_instit      => o_id_health_plan_instit,
                               o_error                      => o_error)
        THEN
        
            COMMIT;
            RETURN TRUE;
        ELSE
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_HEALTH_PLAN',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_health_plan;

    /********************************************************************************************
    * Cancel a Health Plan
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_health_plan        Health Plan id
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/31
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION cancel_health_plan
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_health_plan IN health_plan.id_health_plan%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CANCEL HEALTH_PLAN - ID: ' || i_id_health_plan;
        pk_alertlog.log_debug('PK_ADT.CANCEL_HEALTH_PLAN ' || g_error);
        UPDATE health_plan hp
           SET hp.flg_status = g_adt_hplan_cancel
         WHERE hp.id_health_plan = i_id_health_plan;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_HEALTH_PLAN',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_health_plan;

    /********************************************************************************************
    * Set the Health Plan Entity take over
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_health_plan_entity Health Plan Entity id
    * @param i_id_health_plan        Health Plan id
    * @param i_take_over_time        Take Over defined Time
    * @param i_notes                 Take Over notes
    * @param o_flg_status            Take over status
    * @param o_status_desc           Description of Take over status
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/31
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION set_health_plan_entity_to
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_health_plan_entity IN health_plan_take_over.id_health_plan_entity%TYPE,
        i_id_health_plan        IN health_plan_take_over.id_health_plan%TYPE,
        i_take_over_time        IN VARCHAR2,
        i_notes                 IN health_plan_take_over.notes%TYPE,
        o_flg_status            OUT health_plan_take_over.flg_status%TYPE,
        o_status_desc           OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count NUMBER := 0;
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM health_plan_take_over hpto
         WHERE hpto.id_health_plan_entity = i_id_health_plan_entity
           AND hpto.flg_status = g_adt_hpe_to_sch;
    
        IF l_count = 0
        THEN
            g_error := 'SET HEALTH_PLAN_ENTITY TAKE OVER - HEALTH_PLAN_ENTITY ID: ' || i_id_health_plan_entity ||
                       '  TO HEALTH_PLAN ID: ' || i_id_health_plan;
            pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN_ENTITY_TO ' || g_error);
            INSERT INTO health_plan_take_over
                (id_health_plan_entity, id_health_plan, take_over_time, flg_status, notes)
            VALUES
                (i_id_health_plan_entity,
                 i_id_health_plan,
                 pk_date_utils.get_string_tstz(i_lang, i_prof, i_take_over_time, NULL),
                 g_adt_hpe_to_sch,
                 i_notes);
        
        ELSE
        
            g_error := 'SET HEALTH_PLAN_ENTITY TAKE OVER - HEALTH_PLAN_ENTITY ID: ' || i_id_health_plan_entity ||
                       '  TO HEALTH_PLAN ID: ' || i_id_health_plan;
            pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN_ENTITY_TO ' || g_error);
            UPDATE health_plan_take_over hpto
               SET hpto.take_over_time = pk_date_utils.get_string_tstz(i_lang, i_prof, i_take_over_time, NULL),
                   hpto.notes          = i_notes,
                   hpto.id_health_plan = i_id_health_plan
             WHERE hpto.id_health_plan_entity = i_id_health_plan_entity;
        
        END IF;
    
        o_flg_status  := g_adt_hpe_to_sch;
        o_status_desc := pk_message.get_message(i_lang, 'ADMINISTRATOR_T706');
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_HEALTH_PLAN_ENTITY_TO',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_health_plan_entity_to;

    /********************************************************************************************
    * Cancel a Health Plan Entity take over
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param i_id_health_plan_entity Health Plan Entityid
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/05/31
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION cancel_health_plan_entity_to
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_health_plan_entity IN health_plan_take_over.id_health_plan_entity%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CANCEL HEALTH_PLAN_ENTITY TAKE OVER - HEALTH_PLAN_ENTITY ID: ' || i_id_health_plan_entity;
        pk_alertlog.log_debug('PK_ADT.CANCEL_HEALTH_PLAN_ENTITY_TO ' || g_error);
        DELETE FROM health_plan_take_over hpto
         WHERE hpto.id_health_plan_entity = i_id_health_plan_entity
           AND hpto.flg_status = g_adt_hpe_to_sch;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_HEALTH_PLAN_ENTITY_TO',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_health_plan_entity_to;

    /********************************************************************************************
    * Returns Health Plan Types
    *
    * @param i_lang                  Language id
    * @param i_prof                  Professional (id, institution, software)
    * @param o_health_plan_types     Health Plan Types
    * @param o_error                 Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        Tércio Soares
    * @since                         2010/06/02
    * @version                       2.6.0.3
    ********************************************************************************************/
    FUNCTION get_health_plan_types_list
    (
        i_lang              IN language.id_language%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        o_health_plan_types OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                     JOIN market m
                       ON i.id_market = m.id_market
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        g_error := 'GET HEALTH_PLAN CURSOR';
        pk_alertlog.log_debug('PK_ADT.GET_HEALTH_PLANS_LIST ' || g_error);
        OPEN o_health_plan_types FOR
            SELECT hpt.id_health_plan_type,
                   pk_translation.get_translation(i_lang, hpt.code_health_plan_type) health_plan_type_desc
              FROM health_plan_type hpt
             WHERE hpt.flg_available = pk_alert_constant.get_available
               AND hpt.id_market = l_id_market;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_HEALTH_PLAN_TYPES_LIST',
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_health_plan_types);
            RETURN FALSE;
    END get_health_plan_types_list;

    FUNCTION get_pat_divided_name
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        o_first_name     OUT VARCHAR2,
        o_second_name    OUT VARCHAR2,
        o_middle_name    OUT VARCHAR2,
        o_last_name      OUT VARCHAR2,
        o_maiden_name    OUT VARCHAR2,
        o_mother_surname OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT p.first_name, p.middle_name, p.last_name, p.second_name, p.maiden_name, p.mother_surname_maiden
          INTO o_first_name, o_middle_name, o_last_name, o_second_name, o_maiden_name, o_mother_surname
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_first_name     := '';
            o_last_name      := '';
            o_middle_name    := '';
            o_second_name    := '';
            o_maiden_name    := '';
            o_mother_surname := '';
            RETURN TRUE;
        WHEN OTHERS THEN
            o_first_name     := '';
            o_last_name      := '';
            o_middle_name    := '';
            o_maiden_name    := '';
            o_mother_surname := '';
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_DIVIDED_NAME',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_divided_name;
    /**********************************************************************************************
    * Set patient death details
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_dt_deceased            Date of death
    * @param        i_deceased_motive        Cause of death
    * @param        i_deceased_place         Place of death
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca/Bruno Martins
    * @version      2.6.0.3
    * @since        01-Jul-2010
    **********************************************************************************************/
    FUNCTION set_patient_death_details
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_dt_deceased     IN patient.dt_deceased%TYPE,
        i_deceased_motive IN patient.deceased_motive%TYPE,
        i_deceased_place  IN patient.deceased_place%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(32 CHAR) := 'SET_PATIENT_DEATH_DETAILS';
        l_dbg_msg            VARCHAR2(200 CHAR);
        patient_row          patient%ROWTYPE;
        vflgdeathidentmethod VARCHAR2(5); --Default Death certificate
    
        l_deceased_motive patient.deceased_motive%TYPE;
    
    BEGIN
        l_dbg_msg := 'check if patient exists, if not raises an error (' || i_patient || ')';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        --Get patient info
        SELECT *
          INTO patient_row
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        l_deceased_motive := substr(str1 => i_deceased_motive, pos => 0, len => 200);
    
        --log info
        l_dbg_msg := 'update patient death details';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
    
        --If patient s death info is not filled we have to clean death info
        IF i_dt_deceased IS NULL
           AND l_deceased_motive IS NULL
           AND i_deceased_place IS NULL
        THEN
            --Clean death info
            IF patient_row.flg_status = 'O'
            THEN
                patient_row.flg_status := 'A'; --patient status changed to active, except when he is inactive
            END IF;
            vflgdeathidentmethod := ''; -- default death certificate
            --else patient death is going to be registered
        ELSIF i_dt_deceased IS NOT NULL
        THEN
            patient_row.flg_status := 'O';
            vflgdeathidentmethod   := 'DC';
        END IF;
    
        --update patient info     
        UPDATE patient
           SET dt_deceased            = i_dt_deceased,
               deceased_motive        = l_deceased_motive,
               deceased_place         = i_deceased_place,
               flg_death_ident_method = vflgdeathidentmethod,
               flg_status             = patient_row.flg_status
         WHERE id_patient = i_patient;
    
        --update patient hist
        INSERT INTO patient_hist
            (id_patient_hist,
             id_patient,
             id_person,
             id_general_pratictioner,
             id_pat_family,
             name,
             gender,
             dt_birth,
             nick_name,
             flg_status,
             dt_deceased,
             adw_last_update,
             last_name,
             middle_name,
             age,
             flg_migration,
             total_fam_members,
             national_health_number,
             institution_key,
             create_user,
             create_time,
             update_user,
             update_time,
             patient_number,
             deceased_motive,
             deceased_place,
             operation_type,
             operation_time,
             operation_user,
             birth_place,
             first_name,
             create_institution,
             update_institution,
             record_status,
             import_code,
             id_ethnics,
             preferred_contact_times,
             id_preferred_contact_method,
             id_preferred_com_format,
             id_preferred_language,
             flg_sensitive_record,
             vip_status,
             alias,
             alias_reason,
             non_disclosure_level,
             flg_origin,
             flg_dependence_level,
             flg_death_ident_method,
             death_registry_susp_action_id,
             flg_living_arrangement,
             flg_race,
             maiden_name,
             id_place_of_birth,
             flg_assigning_authority,
             flg_guarantor,
             flg_self_pay,
             flg_living_will,
             flg_overseas_status,
             other_names_1,
             other_names_2,
             other_names_3,
             flg_exemption,
             flg_financial_type,
             flg_immun_reg_status,
             dt_immun_reg_status_eff,
             flg_protection_indicator,
             dt_protection_ind_eff,
             flg_publicity_code,
             dt_publicity_code_eff,
             flg_organ_donor,
             id_person_father,
             id_person_mother,
             flg_death_notif_status,
             flg_nhs_record_share_status,
             flg_health_space_status,
             nhais_information,
             flg_interpreter_required,
             surname_prefix,
             --             surname_maiden,
             partner_surname_prefix,
             partner_surname,
             initials,
             id_nobility_title,
             addressing_preferences,
             flg_pers_data_invest,
             start_date_pers_data_invest,
             flg_decease_data_invest,
             start_date_deceas_data_invest,
             flg_adjournment_reason,
             flg_secret,
             partner_surname_maiden,
             partner_name,
             mother_surname_maiden,
             father_surname_maiden,
             bsn,
             sbvz_invalid_date,
             last_sbvz_update_time,
             last_wid_check_update_time,
             flg_patient_data_check,
             patient_data_check_time,
             id_last_wid_check_doc_type,
             last_wid_check_doc_num,
             flg_last_wid_check_status,
             id_health_center)
        VALUES
            (seq_patient_hist.nextval * c_seq_offset,
             patient_row.id_patient,
             patient_row.id_person,
             patient_row.id_general_pratictioner,
             patient_row.id_pat_family,
             patient_row.name,
             patient_row.gender,
             patient_row.dt_birth,
             patient_row.nick_name,
             patient_row.flg_status,
             i_dt_deceased,
             patient_row.adw_last_update,
             patient_row.last_name,
             patient_row.middle_name,
             patient_row.age,
             patient_row.flg_migration,
             patient_row.total_fam_members,
             patient_row.national_health_number,
             patient_row.institution_key,
             patient_row.create_user,
             patient_row.create_time,
             patient_row.update_user,
             patient_row.update_time,
             patient_row.patient_number,
             l_deceased_motive,
             i_deceased_place,
             'U',
             current_timestamp,
             i_prof.id,
             patient_row.birth_place,
             patient_row.first_name,
             patient_row.create_institution,
             patient_row.update_institution,
             patient_row.record_status,
             patient_row.import_code,
             patient_row.id_ethnics,
             patient_row.preferred_contact_times,
             patient_row.id_preferred_contact_method,
             patient_row.id_preferred_com_format,
             patient_row.id_preferred_language,
             patient_row.flg_sensitive_record,
             patient_row.vip_status,
             patient_row.alias,
             patient_row.alias_reason,
             patient_row.non_disclosure_level,
             patient_row.flg_origin,
             patient_row.flg_dependence_level,
             vflgdeathidentmethod,
             patient_row.death_registry_susp_action_id,
             patient_row.flg_living_arrangement,
             patient_row.flg_race,
             patient_row.maiden_name,
             patient_row.id_place_of_birth,
             patient_row.flg_assigning_authority,
             patient_row.flg_guarantor,
             patient_row.flg_self_pay,
             patient_row.flg_living_will,
             patient_row.flg_overseas_status,
             patient_row.other_names_1,
             patient_row.other_names_2,
             patient_row.other_names_3,
             patient_row.flg_exemption,
             patient_row.flg_financial_type,
             patient_row.flg_immun_reg_status,
             patient_row.dt_immun_reg_status_eff,
             patient_row.flg_protection_indicator,
             patient_row.dt_protection_ind_eff,
             patient_row.flg_publicity_code,
             patient_row.dt_publicity_code_eff,
             patient_row.flg_organ_donor,
             patient_row.id_person_father,
             patient_row.id_person_mother,
             patient_row.flg_death_notif_status,
             patient_row.flg_nhs_record_share_status,
             patient_row.flg_health_space_status,
             patient_row.nhais_information,
             patient_row.flg_interpreter_required,
             patient_row.surname_prefix,
             --             patient_row.surname_maiden,
             patient_row.partner_surname_prefix,
             patient_row.partner_surname,
             patient_row.initials,
             patient_row.id_nobility_title,
             patient_row.addressing_preferences,
             patient_row.flg_pers_data_invest,
             patient_row.start_date_pers_data_invest,
             patient_row.flg_decease_data_invest,
             patient_row.start_date_deceas_data_invest,
             patient_row.flg_adjournment_reason,
             patient_row.flg_secret,
             patient_row.partner_surname_maiden,
             patient_row.partner_name,
             patient_row.mother_surname_maiden,
             patient_row.father_surname_maiden,
             patient_row.bsn,
             patient_row.sbvz_invalid_date,
             patient_row.last_sbvz_update_time,
             patient_row.last_wid_check_update_time,
             patient_row.flg_patient_data_check,
             patient_row.patient_data_check_time,
             patient_row.id_last_wid_check_doc_type,
             patient_row.last_wid_check_doc_num,
             patient_row.flg_last_wid_check_status,
             patient_row.id_health_center);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_patient_death_details;

    FUNCTION delete_discharges
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_discharge_ids IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'TRYING TO DELETE DISCHARGE_ADT';
        DELETE FROM discharge_adt d
         WHERE d.id_discharge IN (SELECT column_value
                                    FROM TABLE(i_discharge_ids));
    
        /*g_error := 'TRYING TO DELETE DISCHARGE_ADT_HIST';
         This table was only created in v2.6
        DELETE FROM discharge_adt_hist d
         WHERE d.id_discharge IN (SELECT column_value
                                    FROM TABLE(i_discharge_ids));*/
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_DISCHARGES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END delete_discharges;

    FUNCTION has_external_account
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count      NUMBER;
        vaccounttype VARCHAR2(20) := pk_sysconfig.get_config('ADT_PHR_TYPE', i_prof);
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM pat_external_account pea
         WHERE pea.id_patient = i_patient
           AND pea.flg_type = vaccounttype
           AND pea.flg_status = pk_alert_constant.g_active;
    
        RETURN(l_count > 0);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'HAS_EXTERNAL_ACCOUNT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END has_external_account;

    FUNCTION get_pat_family_physician
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        o_fam_phys_name OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT physician_name
          INTO o_fam_phys_name
          FROM (SELECT ce.name physician_name
                  FROM patient p
                  JOIN contact_entity ce
                    ON ce.id_contact_entity = p.id_general_pratictioner
                 WHERE id_patient = i_patient
                UNION
                SELECT p.name physician_name
                  FROM pat_professional_inst pp
                  JOIN professional p
                    ON pp.id_professional = p.id_professional
                 WHERE id_patient = i_patient
                   AND pp.flg_family_physician = pk_alert_constant.g_available)
         WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_fam_phys_name := NULL;
        
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FAMILY_PHYSICIAN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END get_pat_family_physician;

    /***********************************************************************************
    **********************************************************************************/

    FUNCTION get_index_name(i_table IN user_tables.table_name%TYPE) RETURN VARCHAR2 IS
        l_index_name all_ind_columns.index_name%TYPE;
        l_is_domain  NUMBER(1);
        l_index_exception EXCEPTION;
    BEGIN
    
        SELECT aic.index_name
          INTO l_index_name
          FROM all_ind_columns aic
          JOIN all_indexes al
            ON aic.index_name = al.index_name
           AND aic.index_owner = al.owner
         WHERE aic.table_name = 'PATIENT'
           AND aic.column_name = 'NAME'
           AND aic.column_position = 1
           AND al.ityp_name = 'LUCENEINDEX';
    
        IF l_index_name IS NOT NULL
        THEN
            SELECT COUNT(1)
              INTO l_is_domain
              FROM all_indexes
             WHERE index_name = l_index_name
               AND ityp_name = 'LUCENEINDEX';
        END IF;
    
        RETURN l_index_name;
    
    EXCEPTION
        WHEN no_data_found THEN
            raise_application_error(-20101, 'Domain index not found for table: ' || i_table || ' on column NAME');
    END get_index_name;

    FUNCTION get_search_hits
    (
        i_table  IN user_tables.table_name%TYPE,
        i_search IN VARCHAR2
    ) RETURN NUMBER IS
        l_index_name user_indexes.index_name%TYPE;
        l_hits       NUMBER(24);
    BEGIN
    
        /*get index name*/
        l_index_name := get_index_name(i_table);
        /*get search hits*/
        l_hits := lucenedomainindex.counthits(l_index_name, i_search);
    
        RETURN l_hits;
    
    END get_search_hits;

    /***********************************************************************************
    **********************************************************************************/

    /********************************************************************************************
    * Returns a collection of patients by pattern name criteria
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_pattern             pattern to search for
    * @param i_dt_birth            date of birth to search for (optional)
    * @return                      a collection of patients (patient_table_type)
    *
    * @author                      Bruno Martins and Pedro Pinheiro
    * @since                       2011-02-16
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_patients
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pattern  IN VARCHAR2,
        i_dt_birth IN DATE DEFAULT NULL
    ) RETURN patient_table_type IS
        l_tab            patient_table_type := patient_table_type();
        l_sql_base       VARCHAR2(32767 CHAR);
        l_sql_where      VARCHAR2(10000 CHAR);
        l_pattern        VARCHAR2(5000 CHAR) := TRIM(i_pattern);
        l_lucene_pattern VARCHAR2(5000 CHAR);
        g_use_wildcards    CONSTANT VARCHAR(1 CHAR) := pk_sysconfig.get_config('ADT_USE_WILDCARDS_SEARCH', i_prof);
        g_use_soundex      CONSTANT VARCHAR(1 CHAR) := pk_sysconfig.get_config('ADT_USE_SOUNDEX', i_prof);
        g_use_alias        CONSTANT VARCHAR(1 CHAR) := pk_sysconfig.get_config('ADT_VIP_AVAILABLE', i_prof);
        g_use_lucene_cache CONSTANT VARCHAR(1 CHAR) := pk_sysconfig.get_config('ADT_LUCENE_PATIENT_SEARCH_CACHE',
                                                                               i_prof);
        g_use_order_by     CONSTANT VARCHAR(1 CHAR) := pk_sysconfig.get_config('ADT_LUCENE_PATIENT_SEARCH_ORDER_BY',
                                                                               i_prof);
        l_sql_order_by VARCHAR2(1000 CHAR);
        l_hits         NUMBER;
        l_index_column VARCHAR2(100 CHAR) := 'full_names';
    BEGIN
    
        IF g_use_lucene_cache = g_no
        THEN
            g_endsession := dbms_java.endsession;
        END IF;
    
        IF g_use_order_by = g_yes
        THEN
            l_sql_order_by := ' ORDER BY relevance desc, name asc)';
        ELSE
            l_sql_order_by := ' )';
        END IF;
    
        --construct base query    
        l_sql_base := 'SELECT patient_object(id_patient,
                                  id_person,
                                  id_pat_family,
                                  name,
                                  gender,
                                  dt_birth,
                                  nick_name,
                                  flg_status,
                                  dt_deceased,
                                  last_name,
                                  middle_name,
                                  age,
                                  national_health_number,
                                  institution_key,
                                  patient_number,
                                  deceased_motive,
                                  deceased_place,
                                  birth_place,
                                  first_name,
                                  id_ethnics,
                                  preferred_contact_times,
                                  id_preferred_contact_method,
                                  id_preferred_com_format,
                                  flg_sensitive_record,
                                  vip_status,
                                  alias,
                                  non_disclosure_level,
                                  flg_origin,
                                  flg_dependence_level,
                                  flg_death_ident_method,
                                  death_registry_susp_action_id,
                                  flg_living_arrangement,
                                  flg_race,
                                  maiden_name,
                                  id_place_of_birth,
                                  flg_assigning_authority,
                                  flg_guarantor,
                                  flg_self_pay,
                                  flg_living_will,
                                  flg_overseas_status,
                                  other_names_1,
                                  other_names_2,
                                  other_names_3,
                                  flg_exemption,
                                  flg_financial_type,
                                  flg_immun_reg_status,
                                  dt_immun_reg_status_eff,
                                  flg_protection_indicator,
                                  dt_protection_ind_eff,
                                  flg_publicity_code,
                                  dt_publicity_code_eff,
                                  flg_organ_donor,
                                  id_person_father,
                                  id_person_mother,
                                  flg_death_notif_status,
                                  flg_nhs_record_share_status,
                                  flg_health_space_status,
                                  nhais_information,
                                  flg_interpreter_required,
                                  surname_prefix,
                                  partner_surname_prefix,
                                  partner_surname,
                                  initials,
                                  id_nobility_title,
                                  addressing_preferences,
                                  flg_pers_data_invest,
                                  start_date_pers_data_invest,
                                  flg_decease_data_invest,
                                  start_date_deceas_data_invest,
                                  flg_adjournment_reason,
                                  flg_secret,
                                  partner_surname_maiden,
                                  partner_name,
                                  mother_surname_maiden,
                                  father_surname_maiden,
                                  bsn,
                                  sbvz_invalid_date,
                                  last_sbvz_update_time,
                                  last_wid_check_update_time,
                                  flg_patient_data_check,
                                  patient_data_check_time,
                                  id_last_wid_check_doc_type,
                                  last_wid_check_doc_num,
                                  flg_last_wid_check_status,
                                  id_health_center,
                                  id_military_branch,
                                  military_status,
                                  worship_place,
                                  id_military_rank,
                                  flg_spanish_speaker,
                                  flg_native_group,
                                  pat_native_lang,
                                  code_birth_certificate ,
                                  type_birth_certificate,
                                  dt_birth_tstz ,
                                  code_type_birth_certificate ,
                                  flg_type_dt_birth  ,
                                  flg_level_dt_birth,
                                  identity_code ,
                                  flg_action_certificate,
                                  other_names_4 ,
                                  second_name ,
                                  flg_patient_test ,
                                  dt_birth_hijri,
                                  in_alias,
                                  rownum, 
                                  relevance
                                  ) 
                        FROM
                        (SELECT /*+opt_estimate(TABLE p rows=1)*/id_patient,
                           id_person,
                           id_pat_family,
                           name,
                           gender,
                           dt_birth,
                           nick_name,
                           flg_status,
                           dt_deceased,
                           last_name,
                           middle_name,
                           pk_patient.get_pat_age(' || i_lang ||
                      ', p.dt_birth, p.dt_deceased, p.age) as age,
                           national_health_number,
                           institution_key,
                           patient_number,
                           deceased_motive,
                           deceased_place,
                           birth_place,
                           first_name,
                           id_ethnics,
                           preferred_contact_times,
                           id_preferred_contact_method,
                           id_preferred_com_format,
                           flg_sensitive_record,
                           vip_status,
                           alias,
                           non_disclosure_level,
                           flg_origin,
                           flg_dependence_level,
                           flg_death_ident_method,
                           death_registry_susp_action_id,
                           flg_living_arrangement,
                           flg_race,
                           maiden_name,
                           id_place_of_birth,
                           flg_assigning_authority,
                           flg_guarantor,
                           flg_self_pay,
                           flg_living_will,
                           flg_overseas_status,
                           other_names_1,
                           other_names_2,
                           other_names_3,
                           flg_exemption,
                           flg_financial_type,
                           flg_immun_reg_status,
                           dt_immun_reg_status_eff,
                           flg_protection_indicator,
                           dt_protection_ind_eff,
                           flg_publicity_code,
                           dt_publicity_code_eff,
                           flg_organ_donor,
                           id_person_father,
                           id_person_mother,
                           flg_death_notif_status,
                           flg_nhs_record_share_status,
                           flg_health_space_status,
                           nhais_information,
                           flg_interpreter_required,
                           surname_prefix,
                           partner_surname_prefix,
                           partner_surname,
                           initials,
                           id_nobility_title,
                           addressing_preferences,
                           flg_pers_data_invest,
                           start_date_pers_data_invest,
                           flg_decease_data_invest,
                           start_date_deceas_data_invest,
                           flg_adjournment_reason,
                           flg_secret,
                           partner_surname_maiden,
                           partner_name,
                           mother_surname_maiden,
                           father_surname_maiden,
                           bsn,
                           sbvz_invalid_date,
                           last_sbvz_update_time,
                           last_wid_check_update_time,
                           flg_patient_data_check,
                           patient_data_check_time,
                           id_last_wid_check_doc_type,
                           last_wid_check_doc_num,
                           flg_last_wid_check_status,
                           id_health_center,
                           id_military_branch,
                           military_status,
                           worship_place,
                           id_military_rank,
                           flg_spanish_speaker,
                           flg_native_group,
                           pat_native_lang,
                           code_birth_certificate ,
                           type_birth_certificate,
                           dt_birth_tstz ,
                           code_type_birth_certificate ,
                           flg_type_dt_birth  ,
                           flg_level_dt_birth,
                           identity_code ,
                           flg_action_certificate,
                           other_names_4 ,
                           second_name ,
                           flg_patient_test ,
                           dt_birth_hijri,
                           null in_alias,
                           null relevance
                      FROM patient p ';
    
        --replace special characters in patterns
        --l_auxpattern := pk_lucene.escape_special_characters(l_pattern, g_yes);
        l_pattern := pk_lucene.escape_special_characters(l_pattern, g_use_wildcards);
        l_pattern := regexp_replace(l_pattern, '''', '''''');
    
        --if we are searching for a name... 
        IF l_pattern IS NOT NULL
        THEN
        
            IF regexp_instr(l_pattern, '[' || g_chinese_char_range || ']') > 0
            THEN
                l_index_column := 'full_names_cn';
            END IF;
        
            l_lucene_pattern := l_index_column || ':(' || l_pattern || ')';
        
            --Search for alias if VIP available
            IF g_use_alias = g_yes
            THEN
                l_sql_base       := REPLACE(l_sql_base,
                                            'null in_alias',
                                            'lcontains (p.name, ''alias:(' || l_pattern || ')'') in_alias');
                l_lucene_pattern := l_lucene_pattern || ' OR alias:(' || l_pattern || ')';
            END IF;
        
            --Use of soundex is enabled in some markets
            IF g_use_soundex = g_yes
            THEN
                l_lucene_pattern := l_lucene_pattern || ' OR soundex_fn:(' || l_pattern || ')';
            END IF;
        
            l_sql_where := ' WHERE lcontains(name, :patt, 1) > 0';
        
            -- -1 means never use lscore
        
            -- 0 means always use lscore
            IF g_lscore_threshold = 0
            THEN
                l_sql_base := REPLACE(l_sql_base, 'null relevance', 'lscore(1) relevance');
            ELSIF g_lscore_threshold > 0
            THEN
                -- 300 means use lscore if l_hits is lower than threshold
                l_hits := lucenedomainindex.counthits(g_idx_default, l_lucene_pattern);
            
                IF l_hits <= g_lscore_threshold
                THEN
                    l_sql_base := REPLACE(l_sql_base, 'null relevance', 'lscore(1) relevance');
                END IF;
            END IF;
        
            --search for a date of birth if required
            IF i_dt_birth IS NOT NULL
            THEN
                IF l_sql_where IS NULL
                THEN
                    l_sql_where := ' WHERE dt_birth = :birth_date';
                ELSE
                    l_sql_where := l_sql_where || ' AND dt_birth = :birth_date';
                END IF;
            
                pk_lucene_index_admin.set_java_session_max_memory;
            
                EXECUTE IMMEDIATE l_sql_base || l_sql_where || l_sql_order_by BULK COLLECT
                    INTO l_tab
                    USING l_lucene_pattern, i_dt_birth;
            ELSE
                --dbms_output.put_line(l_pattern);
                --dbms_output.put_line(l_lucene_pattern); 
                --dbms_output.put_line(l_sql_where);
            
                pk_lucene_index_admin.set_java_session_max_memory;
            
                EXECUTE IMMEDIATE l_sql_base || l_sql_where || l_sql_order_by BULK COLLECT
                    INTO l_tab
                    USING l_lucene_pattern;
            END IF;
        ELSE
            l_sql_where := ' WHERE dt_birth = :birth_date';
        
            EXECUTE IMMEDIATE l_sql_base || l_sql_where || l_sql_order_by BULK COLLECT
                INTO l_tab
                USING i_dt_birth;
        END IF;
    
        /* ORA-01555 counter */
        g_count_error := 0;
    
        RETURN l_tab;
    
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE IN (-1555, -29902, -29903, -29532)
            THEN
                IF g_count_error < 2
                THEN
                    g_count_error := g_count_error + 1;
                    g_error       := 'ERROR: ' || SQLCODE || ' Try again: (' || g_count_error || ')';
                    g_endsession  := dbms_java.endsession;
                    g_error       := 'Clear Java session state: ' || g_endsession;
                
                    RETURN get_patients(i_lang, i_prof, i_pattern, i_dt_birth);
                ELSE
                    RAISE;
                END IF;
            ELSE
                RAISE;
            END IF;
        
    END get_patients;

    /********************************************************************************************
    * Returns a collection of contacts by pattern address criteria
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)
    * @param i_pattern             pattern to search for
    * @return                      a collection of contact address (contact_table_type)
    *
    * @author                      Bruno Martins
    * @since                       2013-02-11
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_search_contacts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pattern IN VARCHAR2
    ) RETURN contact_table_type IS
        l_tab       contact_table_type := contact_table_type();
        l_sql_base  VARCHAR2(32767 CHAR);
        l_sql_where VARCHAR2(10000 CHAR);
        l_pattern   VARCHAR2(5000 CHAR) := TRIM(i_pattern);
        g_use_wildcards    CONSTANT VARCHAR(1 CHAR) := g_no;
        g_use_lucene_cache CONSTANT VARCHAR(1 CHAR) := pk_sysconfig.get_config('ADT_LUCENE_CONTACT_ADDRESS_SEARCH_CACHE',
                                                                               i_prof);
    BEGIN
    
        IF g_use_lucene_cache = g_no
        THEN
            g_endsession := dbms_java.endsession;
        END IF;
    
        --construct base query    
        l_sql_base := 'SELECT contact_object(id_contact_address,
                              id_country,
                              address_line1,
                              regional_entity,
                              location,
                              postal_code,
                              address_line2,
                              address_line3,
                              flg_main_address,
                              door_number,
                              floor,
                              floor_home,
                              institution_key,
                              geo_ref_latitude,
                              geo_ref_longitude,
                              record_status,
                              import_code,
                              flg_address_type,
                              flg_street_type,
                              id_rb_regional_classifier,
                              position, 
                              relevance) 
                        FROM
                        (SELECT id_contact_address,
                              id_country,
                              address_line1,
                              regional_entity,
                              location,
                              postal_code,
                              address_line2,
                              address_line3,
                              flg_main_address,
                              door_number,
                              floor,
                              floor_home,
                              institution_key,
                              geo_ref_latitude,
                              geo_ref_longitude,
                              record_status,
                              import_code,
                              flg_address_type,
                              flg_street_type,
                              id_rb_regional_classifier,
                              rownum position,
                              null relevance
                      FROM contact_address ca';
    
        --if no parameter is passed only base query is executed
        --it should not happens often
        IF l_pattern IS NULL
        THEN
            l_sql_base := l_sql_base || ')';
            EXECUTE IMMEDIATE l_sql_base BULK COLLECT
                INTO l_tab;
        
            RETURN l_tab;
        END IF;
    
        --replace special characters in patterns
        l_pattern   := pk_lucene.escape_special_characters(l_pattern, g_use_wildcards);
        l_pattern   := '(address:(' || l_pattern || '))';
        l_sql_where := ' WHERE lcontains(address_line1, :patt, 1) > 0)';
    
        --relevance should be used when searching for a patient s address
        l_sql_base := REPLACE(l_sql_base, 'null relevance', 'lscore(1) relevance');
    
        EXECUTE IMMEDIATE l_sql_base || l_sql_where || ' ORDER BY relevance desc, address_line1 asc' BULK COLLECT
            INTO l_tab
            USING l_pattern;
    
        /* ORA-01555 counter */
        g_count_error := 0;
    
        RETURN l_tab;
    
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE IN (-1555, -29902, -29903, -29532)
            THEN
                IF g_count_error < 2
                THEN
                    g_count_error := g_count_error + 1;
                    g_error       := 'ERROR: ' || SQLCODE || ' Try again: (' || g_count_error || ')';
                    g_endsession  := dbms_java.endsession;
                    g_error       := 'Clear Java session state: ' || g_endsession;
                
                    RETURN get_search_contacts(i_lang, i_prof, i_pattern);
                ELSE
                    RAISE;
                END IF;
            ELSE
                RAISE;
            END IF;
        
    END get_search_contacts;

    /********************************************************************************************
    * Returns patient s tax number
    *
    * @param i_lang                           language id
    * @param i_prof                           professional info
    * @param i_patient                        patient identifier
    * @param o_error                          error message
    *
    * @return                                 patient s tax number
    *
    * @author                                 BM
    * @version                                2.6
    * @since                                  2010-12-17
    ********************************************************************************************/
    FUNCTION get_tax_number
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN pat_soc_attributes.num_contrib%TYPE IS
        l_tax_number pat_soc_attributes.num_contrib%TYPE := NULL;
        l_error      t_error_out;
    BEGIN
    
        BEGIN
        
            --Get patient s tax_number for that id_patient in id_institution
            SELECT psa.num_contrib
              INTO l_tax_number
              FROM pat_soc_attributes psa
             WHERE psa.id_patient = i_id_patient
               AND psa.id_institution = i_prof.institution;
        
        EXCEPTION
            WHEN no_data_found THEN
                --If patient s data is shareble
                IF pk_sysconfig.get_config('SHARE_PATIENT_ATTRIBUTES', i_prof) = 'Y'
                THEN
                
                    --We will try to find the given data in the set of institutions where
                    --the professional is registered
                    SELECT num_contrib
                      INTO l_tax_number
                      FROM (SELECT psa.num_contrib
                              FROM pat_soc_attributes psa
                             WHERE psa.id_patient = i_id_patient
                               AND psa.id_institution IN
                                   (SELECT *
                                      FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt))))
                     WHERE rownum = 1;
                
                END IF;
        END;
    
        RETURN l_tax_number;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TAX_NUMBER',
                                              l_error);
        
            RETURN NULL;
    END get_tax_number;

    FUNCTION reset_inactivate_patients
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient_list IN table_number
    ) RETURN BOOLEAN IS
        l_myfunction VARCHAR2(100) := 'PK_ADT.RESET_INACTIVATE_PATIENTS';
        inactive_process CONSTANT VARCHAR2(1) := 'I';
        active_process   CONSTANT VARCHAR2(1) := 'A';
        errparam EXCEPTION;
        l_error t_error_out;
    BEGIN
    
        --log input parameters
        g_error := l_myfunction || ' LANG:' || i_lang || ' PROF:' || i_prof.id || ' INST:' || i_prof.institution ||
                   ' SOFT:' || i_prof.software;
        pk_alertlog.log_debug(g_error);
    
        --test input parameters
        IF i_lang IS NULL
           OR i_prof IS NULL
           OR i_prof.id IS NULL
           OR i_prof.institution IS NULL
           OR i_prof.software IS NULL
        THEN
            --raise error if invalid parameters
            RAISE errparam;
        ELSE
        
            --for every process
            UPDATE clin_record cr
               SET cr.flg_status = inactive_process
             WHERE cr.id_institution = i_prof.institution
               AND cr.flg_status = active_process
               AND cr.id_patient NOT IN (SELECT column_value AS id_patient
                                           FROM TABLE(i_patient_list) pat);
        
            UPDATE pat_identifier pi
               SET pi.flg_status = inactive_process
             WHERE pi.id_institution = i_prof.institution
               AND pi.flg_status = active_process
               AND pi.id_patient NOT IN (SELECT column_value AS id_patient
                                           FROM TABLE(i_patient_list) pat);
        
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    EXCEPTION
        WHEN errparam THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_myfunction,
                                              l_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_myfunction,
                                              l_error);
            RETURN FALSE;
    END reset_inactivate_patients;

    FUNCTION get_national_health_number
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        o_hp_id_hp        OUT pat_health_plan.id_health_plan%TYPE,
        o_num_health_plan OUT pat_health_plan.num_health_plan%TYPE,
        o_hp_entity       OUT VARCHAR2,
        o_hp_desc         OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        c_myfunction CONSTANT VARCHAR2(100) := 'PK_ADT.GET_NATIONAL_HEALTH_NUMBER';
        c_conf_fatal_error EXCEPTION;
        l_nh_plan health_plan.id_content%TYPE;
        l_ref_soft CONSTANT NUMBER(2) := pk_sysconfig.get_config('SOFTWARE_ID_P1', i_prof);
    BEGIN
    
        --log input parameters
        g_error := c_myfunction || ' LANG:' || i_lang || ' PROF:' || i_prof.id || ' INST:' || i_prof.institution ||
                   ' SOFT:' || i_prof.software || ' PAT:' || i_id_patient;
    
        pk_alertlog.log_debug(g_error);
    
        --Confirm that national health plan is configured
        l_nh_plan := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
    
        /* no error is raised here due to lack of use in US market
        IF l_nh_plan IS NULL THEN
           g_error := 'ERR_CONF_NO_NATIONAL_HEALTH_PLAN';
           RAISE c_conf_fatal_error;
        END IF;
        */
    
        --ADT-7124 In Referral we have to consult id_inst = 0
        IF i_prof.software = l_ref_soft
        THEN
        
            g_error := 'GET NATIONAL HEALTH PLAN FOR REF';
            SELECT php.id_health_plan nhid,
                   php.num_health_plan nhp,
                   pk_translation.get_translation(i_lang,
                                                  'HEALTH_PLAN_ENTITY.CODE_HEALTH_PLAN_ENTITY.' ||
                                                  hp.id_health_plan_entity) hpe,
                   pk_translation.get_translation(i_lang, 'HEALTH_PLAN.CODE_HEALTH_PLAN.' || php.id_health_plan) desc_hplan
              INTO o_hp_id_hp, o_num_health_plan, o_hp_entity, o_hp_desc
              FROM pat_health_plan php
              JOIN health_plan hp
                ON hp.id_health_plan = php.id_health_plan
             WHERE php.id_patient = i_id_patient
               AND php.id_institution = g_all_institution
               AND hp.id_content = l_nh_plan
               AND hp.flg_available = pk_alert_constant.get_available
               AND php.flg_status = g_adt_hplan_active
               AND rownum = 1;
        ELSE
            --For all other software we use healthcare center instits 
            g_error := 'GET NATIONAL HEALTH PLAN';
            SELECT php.id_health_plan nhid,
                   php.num_health_plan nhp,
                   pk_translation.get_translation(i_lang,
                                                  'HEALTH_PLAN_ENTITY.CODE_HEALTH_PLAN_ENTITY.' ||
                                                  hp.id_health_plan_entity) hpe,
                   pk_translation.get_translation(i_lang, 'HEALTH_PLAN.CODE_HEALTH_PLAN.' || php.id_health_plan) desc_hplan
              INTO o_hp_id_hp, o_num_health_plan, o_hp_entity, o_hp_desc
              FROM pat_health_plan php
              JOIN health_plan hp
                ON hp.id_health_plan = php.id_health_plan
             WHERE php.id_patient = i_id_patient
               AND php.id_institution IN
                   (SELECT *
                      FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt)))
               AND hp.id_content = l_nh_plan
               AND hp.flg_available = pk_alert_constant.get_available
               AND php.flg_status = g_adt_hplan_active
               AND rownum = 1;
        END IF;
    
        g_error := c_myfunction || ' PAT:' || i_id_patient || ' NHP:' || o_num_health_plan || ' HPE:' || o_hp_entity ||
                   ' HPD:' || o_hp_desc;
    
        pk_alertlog.log_debug(g_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            --If there is no information it should not be an error
            RETURN TRUE;
        WHEN c_conf_fatal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              o_error);
            RETURN FALSE;
    END get_national_health_number;

    FUNCTION get_health_plan
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        o_hp_id_hp        OUT pat_health_plan.id_health_plan%TYPE,
        o_num_health_plan OUT pat_health_plan.num_health_plan%TYPE,
        o_hp_entity       OUT VARCHAR2,
        o_hp_desc         OUT VARCHAR2,
        o_hp_in_use       OUT VARCHAR2,
        o_nhn_id_hp       OUT pat_health_plan.id_health_plan%TYPE,
        o_nhn_number      OUT VARCHAR2,
        o_nhn_hp_entity   OUT VARCHAR2,
        o_nhn_hp_desc     OUT VARCHAR2,
        o_nhn_status      OUT VARCHAR2,
        o_nhn_desc_status OUT VARCHAR2,
        o_nhn_in_use      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_nhn_in_use VARCHAR2(200 CHAR) := 'ID_PATIENT_HP_IN_USE';
        c_myfunction CONSTANT VARCHAR2(100) := 'PK_ADT.GET_HEALTH_PLAN';
        c_nhndomain  CONSTANT VARCHAR2(100) := 'PAT_SOC_ATTRIBUTES.FLG_NHN_STATUS';
        l_hn_mask VARCHAR2(100);
    BEGIN
    
        --log input parameters
        g_error := c_myfunction || ' LANG:' || i_lang || ' PROF:' || i_prof.id || ' INST:' || i_prof.institution ||
                   ' SOFT:' || i_prof.software || ' PAT:' || i_id_patient || ' EPIS:' || i_id_episode;
    
        pk_alertlog.log_debug(g_error);
    
        l_hn_mask := pk_sysconfig.get_config('ADT_NHN_MASK', i_prof);
    
        g_error := 'GET HEALTH PLAN IN USE';
        --Get patient s health plan information according to header rules
        --Health plan is returned when
        -- a) registered in health center institution and
        -- b) is active and
        -- c) is default (aka in use) or in use by the episode
        BEGIN
        
            SELECT nhid, nhp, desc_hplan, hpe, pk_message.get_message(i_lang, i_code_mess => l_nhn_in_use)
              INTO o_hp_id_hp, o_num_health_plan, o_hp_desc, o_hp_entity, o_hp_in_use
              FROM (SELECT php.id_health_plan nhid,
                           php.num_health_plan nhp,
                           pk_translation.get_translation(i_lang,
                                                          'HEALTH_PLAN_ENTITY.CODE_HEALTH_PLAN_ENTITY.' ||
                                                          hp.id_health_plan_entity) hpe,
                           pk_translation.get_translation(i_lang, 'HEALTH_PLAN.CODE_HEALTH_PLAN.' || php.id_health_plan) desc_hplan,
                           decode(ehp.id_episode, i_id_episode, 1, 0) in_use_epis,
                           decode(php.flg_default, pk_alert_constant.g_yes, 1, 0) in_use,
                           decode(ehp.flg_primary, 'Y', 1, 0) epis_flg_primary
                      FROM pat_health_plan php
                      LEFT JOIN epis_health_plan ehp
                        ON php.id_pat_health_plan = ehp.id_pat_health_plan
                      JOIN health_plan hp
                        ON hp.id_health_plan = php.id_health_plan
                     WHERE php.id_patient = i_id_patient
                       AND php.id_institution IN
                           (SELECT *
                              FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt)))
                       AND (php.flg_default = pk_alert_constant.g_yes OR
                           nvl2(i_id_episode,
                                 decode(ehp.id_episode, i_id_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                                 pk_alert_constant.g_no) = pk_alert_constant.g_yes)
                       AND php.flg_status = g_adt_hplan_active
                       AND (ehp.id_episode IS NULL OR ehp.id_episode = i_id_episode)
                     ORDER BY epis_flg_primary DESC, in_use_epis DESC, in_use DESC)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                --If there is no health plan in use it should not be an error
                NULL;
        END;
    
        g_error := 'GET NATIONAL_HEALTH_NUMBER';
        --get nhn information (even if its not in use)
        IF get_national_health_number(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_id_patient      => i_id_patient,
                                      o_hp_id_hp        => o_nhn_id_hp,
                                      o_num_health_plan => o_nhn_number,
                                      o_hp_entity       => o_nhn_hp_entity,
                                      o_hp_desc         => o_nhn_hp_desc,
                                      o_error           => o_error)
        THEN
        
            --send label if nhs is in use
            IF o_nhn_number = o_num_health_plan
            THEN
                o_nhn_in_use := pk_message.get_message(i_lang, i_code_mess => 'ID_PATIENT_HP_IN_USE');
            ELSE
                o_nhn_in_use := pk_message.get_message(i_lang, i_code_mess => 'ID_PATIENT_HP_NOT_IN_USE');
            END IF;
        
            IF l_hn_mask IS NOT NULL
            THEN
                --format number with nhs mask
                IF o_nhn_number = o_num_health_plan
                THEN
                    o_num_health_plan := REPLACE(to_char(REPLACE(o_num_health_plan, ' ', ''), l_hn_mask), ',', ' ');
                END IF;
            
                o_nhn_number := REPLACE(to_char(REPLACE(o_nhn_number, ' ', ''), l_hn_mask), ',', ' ');
            END IF;
        
            g_error := 'GET NHN STATUS';
            --get nhn validation status information
            BEGIN
                SELECT psa.flg_nhn_status, pk_sysdomain.get_domain(c_nhndomain, flg_nhn_status, i_lang)
                  INTO o_nhn_status, o_nhn_desc_status
                  FROM pat_soc_attributes psa
                 WHERE psa.id_patient = i_id_patient
                   AND psa.id_institution IN
                       (SELECT *
                          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt)))
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    --If there is no information about national health number
                    --it should not be an error
                    NULL;
            END;
        
        END IF;
    
        g_error := c_myfunction || ' PAT:' || i_id_patient || ' EPIS:' || i_id_episode || ' HPN:' || o_num_health_plan ||
                   ' HPD:' || substr(o_hp_desc, 1, 30) || ' HPE:' || substr(o_hp_entity, 1, 30) || ' HPU:' ||
                   o_hp_in_use || ' NHN:' || o_nhn_number || ' NHS:' || o_nhn_status || ' NHE' ||
                   substr(o_nhn_hp_entity, 1, 30) || ' NHD:' || substr(o_hp_desc, 1, 30);
    
        pk_alertlog.log_debug(g_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              o_error);
            RETURN FALSE;
    END get_health_plan;

    /********************************************************************************************
    * GET_PAT_RECM
    *
    * @param i_lang                language id
    * @param i_prof                professional id (INTERFACE PROFESSIOAL USED FOR MIGRATION)
    * @param i_id_pat              Patient identifier
    * @param o_nkda                Indicate if there is allergies to medication ('Y'-Yes; 'N'No)
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Maia
    * @version                     2.6.1.1
    * @since                       2011/04/18
    * @dependents                  PK_EPISODE.GET_EPIS_HEADER
    **********************************************************************************************/
    FUNCTION get_pat_recm
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        o_nkda   IN OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_recm VARCHAR2(200);
        --
        CURSOR c_pat_recm IS
            SELECT r.flg_recm
              FROM v_pat_recm v, recm r
             WHERE v.id_patient = i_id_pat
               AND v.id_recm = r.id_recm;
    BEGIN
    
        g_error := 'OPEN C_PAT_RECM';
        OPEN c_pat_recm;
        FETCH c_pat_recm
            INTO l_recm;
        g_found := c_pat_recm%FOUND;
        CLOSE c_pat_recm;
    
        IF o_nkda IS NULL
        THEN
            IF g_found
            THEN
                o_nkda := 'RECM - ' || l_recm;
            END IF;
        ELSE
            IF g_found
            THEN
                o_nkda := o_nkda || ' / RECM - ' || l_recm;
            END IF;
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_RECM',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_recm;

    /********************************************************************************************
    * GET_RECM_DESCRIPTION_LIST
    *
    * @param i_lang                language id
    * @param i_prof                professional id (INTERFACE PROFESSIOAL USED FOR MIGRATION)
    * @param o_recm                RECM description
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Maia
    * @version                     2.6.1.1
    * @since                       2011/04/19
    * @dependents                  PK_LIST.GET_RECM_DESCRIPTION_LIST
    **********************************************************************************************/
    FUNCTION get_recm_description_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_recm  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_RECM';
        OPEN o_recm FOR
            SELECT id_recm, 1 rank, decode(label, NULL, flg_recm, flg_recm || ' - ' || label) label
              FROM (SELECT r.id_recm, 1 rank, r.flg_recm, pk_translation.get_translation(i_lang, r.code_recm) label
                      FROM recm r
                     WHERE r.flg_available = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT -1 data, -1 rank, pk_message.get_message(i_lang, 'COMMON_M002') label, NULL AS trans
                      FROM dual)
             ORDER BY rank, label;
    
        -- SUCCESS
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_recm);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RECM_DESCRIPTION_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_recm_description_list;

    FUNCTION get_pat_health_plans
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        o_pat_health_plan OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET PAT HEALTH_PLAN CURSOR';
        pk_alertlog.log_debug('PK_ADT.GET_PAT_HEALTH_PLANS ' || g_error);
        OPEN o_pat_health_plan FOR
            SELECT php.id_pat_health_plan,
                   php.id_health_plan,
                   pk_translation.get_translation(i_lang, hp.code_health_plan) hplan,
                   pk_translation.get_translation(i_lang, hpe.code_health_plan_entity) hpentity,
                   hp.id_health_plan_entity,
                   php.num_health_plan
              FROM pat_health_plan php
              JOIN health_plan hp
                ON php.id_health_plan = hp.id_health_plan
              LEFT JOIN health_plan_entity hpe
                ON hp.id_health_plan_entity = hpe.id_health_plan_entity
             WHERE php.id_patient = i_id_patient
               AND php.id_institution = i_prof.institution
               AND php.flg_status = pk_alert_constant.g_active;
    
        --for now, we will not search within the health center because this info is being replicated
        /*AND php.id_institution IN
        (SELECT *
           FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt)))*/
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_HEALTH_PLANS',
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_pat_health_plan);
            RETURN FALSE;
    END get_pat_health_plans;

    FUNCTION get_pat_health_plan_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_pat_health_plan IN pat_health_plan.id_pat_health_plan%TYPE,
        i_flg_output         IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_output VARCHAR2(2000 CHAR);
        l_error  t_error_out;
        c_financial_entity   CONSTANT VARCHAR2(1 CHAR) := 'F';
        c_health_plan        CONSTANT VARCHAR2(1 CHAR) := 'H';
        c_health_plan_number CONSTANT VARCHAR2(1 CHAR) := 'N';
    BEGIN
    
        g_error := 'GET PAT HEALTH_PLAN_INFO CURSOR';
    
        pk_alertlog.log_debug('PK_ADT.GET_PAT_HEALTH_PLANS ' || g_error);
    
        SELECT decode(i_flg_output,
                      c_financial_entity,
                      pk_translation.get_translation(i_lang, hpe.code_health_plan_entity),
                      c_health_plan,
                      pk_translation.get_translation(i_lang, hp.code_health_plan),
                      c_health_plan_number,
                      php.num_health_plan,
                      NULL) hinfo
          INTO l_output
          FROM pat_health_plan php
          JOIN health_plan hp
            ON php.id_health_plan = hp.id_health_plan
          LEFT JOIN health_plan_entity hpe
            ON hp.id_health_plan_entity = hpe.id_health_plan_entity
         WHERE php.id_pat_health_plan = i_id_pat_health_plan;
    
        RETURN l_output;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_HEALTH_PLAN_INFO',
                                              o_error    => l_error);
        
            RETURN NULL;
    END get_pat_health_plan_info;

    /********************************************************************************************
    * Replace ADT visit of an episode.
    *
    * @param i_lang                Language id
    * @param i_prof                Professional id
    * @param i_id_episode          Episode ID to have its data replaced
    * @param i_prev_id_visit       Previous visit ID, to obtain the new data
    * @param i_prev_id_epis_type   Previous episode type ID
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Brito
    * @version                     2.6.1.1
    * @since                       2011/07/01
    **********************************************************************************************/
    FUNCTION replace_visit_adt
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_prev_id_visit     IN visit.id_visit%TYPE,
        i_prev_id_epis_type IN episode.id_epis_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'REPLACE_VISIT_ADT';
        l_data_error EXCEPTION;
    
        l_new_id_visit_adt   visit_adt.id_visit_adt%TYPE;
        l_new_id_episode_adt episode_adt.id_episode_adt%TYPE;
        l_id_prev_episode    episode.id_prev_episode%TYPE;
        l_current_id_episode episode.id_episode%TYPE;
    BEGIN
        -- Get the ADT data from the previous episode.
        BEGIN
            g_error := 'GET PREV EPISODE ADT DATA';
            pk_alertlog.log_debug(g_error);
            SELECT vadt.id_visit_adt, eadt.id_episode_adt, eadt.id_episode
              INTO l_new_id_visit_adt, l_new_id_episode_adt, l_id_prev_episode
              FROM visit_adt vadt
              LEFT JOIN episode_adt eadt
                ON eadt.id_visit_adt = vadt.id_visit_adt
               AND eadt.id_episode_type = i_prev_id_epis_type
             WHERE vadt.id_visit = i_prev_id_visit;
        EXCEPTION
            WHEN no_data_found THEN
                l_new_id_episode_adt := NULL;
                l_new_id_visit_adt   := NULL;
        END;
    
        IF l_new_id_visit_adt IS NOT NULL
        THEN
            -- Replace episode ADT data, and connect with the previous ADT episode, if available.
            g_error := 'REPLACE EPISODE ADT DATA';
            pk_alertlog.log_debug(g_error);
            UPDATE episode_adt eadt
               SET eadt.id_previous_episode_adt = l_new_id_episode_adt, eadt.id_visit_adt = l_new_id_visit_adt
             WHERE id_episode = i_id_episode
               AND eadt.id_previous_episode_adt IS NULL; -- Condition avoids inconsistent data.
        
            -- Verify data consistency after update, current episode must have connection with the previous episode,
            -- both in ALERT and ADT tables.
            BEGIN
                g_error := 'CHECK DATA EPISODE (1)';
                pk_alertlog.log_debug(g_error);
                SELECT e.id_episode
                  INTO l_current_id_episode
                  FROM episode e
                 WHERE e.id_episode = i_id_episode
                   AND e.id_visit = i_prev_id_visit
                   AND e.id_prev_episode = l_id_prev_episode
                   AND e.id_prev_epis_type = i_prev_id_epis_type;
            
                IF l_new_id_episode_adt IS NOT NULL
                THEN
                    g_error := 'CHECK DATA EPISODE (2)';
                    pk_alertlog.log_debug(g_error);
                    SELECT eadt.id_episode
                      INTO l_current_id_episode
                      FROM episode_adt eadt
                      JOIN episode_adt prev_eadt
                        ON prev_eadt.id_episode_adt = eadt.id_previous_episode_adt
                     WHERE eadt.id_episode = i_id_episode
                       AND prev_eadt.id_episode = l_id_prev_episode
                       AND prev_eadt.id_episode_type = i_prev_id_epis_type
                       AND prev_eadt.id_episode_adt = l_new_id_episode_adt;
                END IF;
            EXCEPTION
                WHEN no_data_found THEN
                    RAISE l_data_error;
            END;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_data_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'DATA ERROR',
                                              'FOUND INCONSISTENT DATA WHILE UPDATING CURRENT EPISODE',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END replace_visit_adt;

    /********************************************************************************************
    * Returns a list of professionals assigned to the specified clinical service.
    * Used to select the responsible physician when admitting a patient to another software.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_institution              Destination institution ID
    * @param   i_software                 Destination software ID
    * @param   i_dest_service             Destination clinical service ID
    * @param   o_prof_list                List of professionals 
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         José Brito
    * @version                        2.6.1
    * @since                          07-07-2011
    **********************************************************************************************/
    FUNCTION get_admission_prof_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE,
        i_dest_service IN clinical_service.id_clinical_service%TYPE,
        o_prof_list    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200 CHAR) := 'GET_ADMISSION_PROF_LIST';
        l_internal_error EXCEPTION;
    BEGIN
    
        IF NOT pk_hand_off_core.get_admission_prof_list(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_institution  => i_institution,
                                                        i_software     => i_software,
                                                        i_dest_service => i_dest_service,
                                                        o_prof_list    => o_prof_list,
                                                        o_error        => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_admission_prof_list;
    /********************************************************************************************
    * Returns Health Plan Entity created/edited in the institution
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_institution               Institution id
    * @param i_id_health_plan_entity        Health Plan Entity id
    * @param i_health_plan_entity_desc      Health Plan Entity name
    * @param i_flg_available                Health Plan status
    * @param i_national_identifier_number   Health Plan Entity identifier
    * @param i_short_name                   Health Plan Entity short name
    * @param i_street                       Health Plan Entity Street
    * @param i_city                         Health Plan Entity City
    * @param i_telephone                    Health Plan Entity Phone number
    * @param i_fax                          Health Plan Entity Fax number
    * @param i_email                        Health Plan Entity E-mail
    * @param i_postal_code                  Health Plan Entity Postal Code
    * @param i_postal_code_city             Health Plan Entity Postal Code City
    * @param o_id_health_plan_entity        Health Plan Entity id
    * @param o_id_health_plan_entity_instit Health Plan Entity Institution id
    * @param o_error                        Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/10/27
    * @version                       2.6.1.4
    ********************************************************************************************/
    FUNCTION set_health_plan_entity_ext
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_id_institution               IN institution.id_institution%TYPE,
        i_id_health_plan_entity        IN health_plan_entity.id_health_plan_entity%TYPE,
        i_health_plan_entity_desc      IN VARCHAR2,
        i_flg_available                IN health_plan_entity.flg_available%TYPE,
        i_national_identifier_number   IN health_plan_entity.national_identifier_number%TYPE,
        i_short_name                   IN health_plan_entity.short_name%TYPE,
        i_street                       IN health_plan_entity.street%TYPE,
        i_city                         IN health_plan_entity.city%TYPE,
        i_telephone                    IN health_plan_entity.telephone%TYPE,
        i_fax                          IN health_plan_entity.fax%TYPE,
        i_email                        IN health_plan_entity.email%TYPE,
        i_postal_code                  IN health_plan_entity.postal_code%TYPE,
        i_postal_code_city             IN health_plan_entity.postal_code_city%TYPE,
        o_id_health_plan_entity        OUT health_plan_entity.id_health_plan_entity%TYPE,
        o_id_health_plan_entity_instit OUT health_plan_entity_instit.id_health_plan_entity_instit%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_language IS
            SELECT l.id_language
              FROM LANGUAGE l
             WHERE l.flg_available = pk_alert_constant.g_available;
    
        --TRANSLATION
        l_id_lang language.id_language%TYPE;
    
        l_health_plan_entity_desc pk_translation.t_desc_translation;
    
    BEGIN
    
        IF i_id_health_plan_entity IS NULL
        THEN
        
            g_error := 'GET HEALTH_PLAN_ENTITY ID TO INSERT';
            SELECT MAX(id_health_plan_entity) + 1
              INTO o_id_health_plan_entity
              FROM health_plan_entity;
        
            g_error := 'INSERT INTO HEALTH_PLAN_ENTITY - ID: ' || o_id_health_plan_entity || ', NAME: ' ||
                       i_health_plan_entity_desc;
            INSERT INTO health_plan_entity
                (id_health_plan_entity,
                 code_health_plan_entity,
                 flg_available,
                 national_identifier_number,
                 short_name,
                 street,
                 city,
                 telephone,
                 fax,
                 email,
                 postal_code,
                 postal_code_city)
            VALUES
                (o_id_health_plan_entity,
                 'HEALTH_PLAN_ENTITY.CODE_HEALTH_PLAN_ENTITY.' || o_id_health_plan_entity,
                 i_flg_available,
                 i_national_identifier_number,
                 i_short_name,
                 i_street,
                 i_city,
                 i_telephone,
                 i_fax,
                 i_email,
                 i_postal_code,
                 i_postal_code_city);
        
            g_error := 'GET LANGUAGES TO INSERT IN TRANSLATION';
            OPEN c_language;
            LOOP
                FETCH c_language
                    INTO l_id_lang;
                EXIT WHEN c_language%NOTFOUND;
            
                g_error := 'INSERT_INTO_TRANSLATION HEALTH_PLAN_ENTITY - ID: ' || o_id_health_plan_entity || ', NAME: ' ||
                           i_health_plan_entity_desc;
                pk_translation.insert_into_translation(l_id_lang,
                                                       'HEALTH_PLAN_ENTITY.CODE_HEALTH_PLAN_ENTITY.' ||
                                                       o_id_health_plan_entity,
                                                       i_health_plan_entity_desc);
            
            END LOOP;
        
            CLOSE c_language;
        
            g_error := 'GET HEALTH_PLAN_ENTITY_INSTIT ID TO INSERT';
            pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN_ENTITY_EXT ' || g_error);
            SELECT seq_health_plan_entity_instit.nextval
              INTO o_id_health_plan_entity_instit
              FROM dual;
        
            g_error := 'INSERT INTO HEALTH_PLAN_ENTITY_INSTIT - ID: ' || o_id_health_plan_entity || ', INSTITUTION: ' ||
                       i_id_institution;
            INSERT INTO health_plan_entity_instit
                (id_health_plan_entity_instit, id_health_plan_entity, id_institution)
            VALUES
                (o_id_health_plan_entity_instit, o_id_health_plan_entity, i_id_institution);
        
            --ADT-6468 replicate in hospital center
            FOR i IN (SELECT *
                        FROM TABLE(pk_list.tf_get_all_inst_group(i_id_institution, g_inst_grp_flg_rel_adt))
                      MINUS
                      SELECT *
                        FROM TABLE(table_number(i_id_institution)))
            LOOP
            
                g_error := 'GET HEALTH_PLAN_ENTITY_INSTIT ID TO INSERT';
                SELECT seq_health_plan_entity_instit.nextval
                  INTO o_id_health_plan_entity_instit
                  FROM dual;
            
                g_error := 'INSERT INTO HEALTH_PLAN_ENTITY_INSTIT - ID: ' || o_id_health_plan_entity ||
                           ', INSTITUTION: ' || i_id_institution;
            
                --ignore error if health plan entity is already configured in that institution
                BEGIN
                    INSERT INTO health_plan_entity_instit
                        (id_health_plan_entity_instit, id_health_plan_entity, id_institution)
                    VALUES
                        (o_id_health_plan_entity_instit, o_id_health_plan_entity, i.column_value);
                EXCEPTION
                    WHEN dup_val_on_index THEN
                        NULL;
                END;
            END LOOP;
        
        ELSE
        
            g_error := 'GET HEALTH_PLAN_ENTITY_INSTIT OF HEALTH_PLAN_ENTITY TO UPDATE';
            SELECT hpei.id_health_plan_entity_instit
              INTO o_id_health_plan_entity_instit
              FROM health_plan_entity_instit hpei
             WHERE hpei.id_health_plan_entity = i_id_health_plan_entity
               AND hpei.id_institution = i_id_institution;
        
            g_error := 'INSERT INTO HEALTH_PLAN_ENTITY - ID: ' || i_id_health_plan_entity || ', NAME: ' ||
                       i_health_plan_entity_desc;
            UPDATE health_plan_entity hpe
               SET hpe.national_identifier_number = nvl(i_national_identifier_number, hpe.national_identifier_number),
                   hpe.short_name                 = nvl(i_short_name, hpe.short_name),
                   hpe.street                     = nvl(i_street, hpe.street),
                   hpe.city                       = nvl(i_city, hpe.city),
                   hpe.telephone                  = nvl(i_telephone, hpe.telephone),
                   hpe.fax                        = nvl(i_fax, hpe.fax),
                   hpe.email                      = nvl(i_email, hpe.email),
                   hpe.postal_code                = nvl(i_postal_code, hpe.postal_code),
                   hpe.postal_code_city           = nvl(i_postal_code_city, hpe.postal_code_city),
                   hpe.flg_available              = i_flg_available
             WHERE hpe.id_health_plan_entity = i_id_health_plan_entity;
        
            g_error := 'GET LANGUAGES TO INSERT IN TRANSLATION';
            OPEN c_language;
            LOOP
                FETCH c_language
                    INTO l_id_lang;
                EXIT WHEN c_language%NOTFOUND;
            
                SELECT pk_translation.get_translation(l_id_lang,
                                                      'HEALTH_PLAN_ENTITY.CODE_HEALTH_PLAN_ENTITY.' ||
                                                      i_id_health_plan_entity)
                  INTO l_health_plan_entity_desc
                  FROM dual;
            
                IF l_health_plan_entity_desc != i_health_plan_entity_desc
                THEN
                    g_error := 'INSERT_INTO_TRANSLATION HEALTH_PLAN_ENTITY - ID: ' || i_id_health_plan_entity ||
                               ', NAME: ' || i_health_plan_entity_desc;
                    pk_translation.insert_into_translation(l_id_lang,
                                                           'HEALTH_PLAN_ENTITY.CODE_HEALTH_PLAN_ENTITY.' ||
                                                           i_id_health_plan_entity,
                                                           i_health_plan_entity_desc);
                END IF;
            END LOOP;
        END IF;
    
        o_id_health_plan_entity := nvl(o_id_health_plan_entity, i_id_health_plan_entity);
        pk_ia_event_backoffice.health_plan_entity_new(o_id_health_plan_entity, i_id_institution);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_HEALTH_PLAN_ENTITY_EXT',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_health_plan_entity_ext;
    /********************************************************************************************
    * Returns Health Plan created/edited in the institution
    *
    * @param i_lang                         Language id
    * @param i_prof                         Professional (id, institution, software)
    * @param i_id_institution               Institution id
    * @param i_id_health_plan               Health Plan id
    * @param i_health_plan_desc             Health Plan name
    * @param i_id_health_plan_entity        Health Plan Entity id
    * @param i_id_health_plan_type          Health Plan type
    * @param i_flg_available                Health Plan status
    * @param i_national_identifier_number   Health Plan Entity identifier
    * @param o_id_health_plan_entity        Health Plan id
    * @param o_id_health_plan_entity_instit Health Plan Institution id
    * @param o_error                        Error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/10/27
    * @version                       2.6.1.4
    ********************************************************************************************/
    FUNCTION set_health_plan_ext
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_institution             IN institution.id_institution%TYPE,
        i_id_health_plan             IN health_plan.id_health_plan%TYPE,
        i_health_plan_desc           IN VARCHAR2,
        i_id_health_plan_entity      IN health_plan.id_health_plan_type%TYPE,
        i_id_health_plan_type        IN health_plan.id_health_plan_type%TYPE,
        i_flg_available              IN health_plan.flg_available%TYPE,
        i_national_identifier_number IN health_plan_entity.national_identifier_number%TYPE,
        o_id_health_plan             OUT health_plan.id_health_plan%TYPE,
        o_id_health_plan_instit      OUT health_plan_instit.id_health_plan_instit%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_type institution.flg_type%TYPE;
    
        --TRANSLATION
        l_id_lang language.id_language%TYPE;
    
        CURSOR c_language IS
            SELECT l.id_language
              FROM LANGUAGE l
             WHERE l.flg_available = pk_alert_constant.g_available;
    
    BEGIN
    
        SELECT flg_type
          INTO l_type
          FROM institution
         WHERE id_institution = i_id_institution;
    
        IF i_id_health_plan IS NULL
        THEN
        
            g_error := 'GET HEALTH_PLAN ID TO INSERT';
            pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN_EXT ' || g_error);
            SELECT MAX(id_health_plan) + 1
              INTO o_id_health_plan
              FROM health_plan;
        
            g_error := 'INSERT INTO HEALTH_PLAN - ID: ' || o_id_health_plan || ', NAME: ' || i_health_plan_desc;
            pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN_EXT ' || g_error);
            INSERT INTO health_plan
                (id_health_plan,
                 code_health_plan,
                 flg_available,
                 flg_instit_type,
                 id_health_plan_entity,
                 id_health_plan_type,
                 national_identifier_number,
                 flg_status,
                 rank)
            VALUES
                (o_id_health_plan,
                 'HEALTH_PLAN.CODE_HEALTH_PLAN.' || o_id_health_plan,
                 i_flg_available,
                 l_type,
                 i_id_health_plan_entity,
                 i_id_health_plan_type,
                 i_national_identifier_number,
                 g_adt_hplan_active,
                 0);
        
            g_error := 'GET LANGUAGES TO INSERT IN TRANSLATION';
            pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN_EXT ' || g_error);
            OPEN c_language;
            LOOP
                FETCH c_language
                    INTO l_id_lang;
                EXIT WHEN c_language%NOTFOUND;
            
                g_error := 'INSERT_INTO_TRANSLATION HEALTH_PLAN - ID: ' || o_id_health_plan || ', NAME: ' ||
                           i_health_plan_desc;
                pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN_EXT ' || g_error);
                pk_translation.insert_into_translation(l_id_lang,
                                                       'HEALTH_PLAN.CODE_HEALTH_PLAN.' || o_id_health_plan,
                                                       i_health_plan_desc);
            
            END LOOP;
        
            CLOSE c_language;
        
            g_error := 'GET HEALTH_PLAN_INSTIT ID TO INSERT';
            pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN ' || g_error);
            SELECT MAX(id_health_plan_instit) + 1
              INTO o_id_health_plan_instit
              FROM health_plan_instit;
        
            g_error := 'INSERT INTO HEALTH_PLAN_INSTIT - ID: ' || o_id_health_plan_instit || ', INSTITUTION: ' ||
                       i_id_institution;
            pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN_EXT ' || g_error);
            INSERT INTO health_plan_instit
                (id_health_plan_instit, id_institution, id_health_plan)
            VALUES
                (o_id_health_plan_instit, i_id_institution, o_id_health_plan);
        
            --ADT-6468 replicate in hospital center
            FOR i IN (SELECT *
                        FROM TABLE(pk_list.tf_get_all_inst_group(i_id_institution, g_inst_grp_flg_rel_adt))
                      MINUS
                      SELECT *
                        FROM TABLE(table_number(i_id_institution)))
            LOOP
            
                SELECT MAX(id_health_plan_instit) + 1
                  INTO o_id_health_plan_instit
                  FROM health_plan_instit;
            
                g_error := 'INSERT INTO HEALTH_PLAN_INSTIT - ID: ' || o_id_health_plan_instit || ', INSTITUTION: ' ||
                           i.column_value;
                pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN_EXT ' || g_error);
            
                --ignore error if health plan is already configured in that institution
                BEGIN
                    INSERT INTO health_plan_instit
                        (id_health_plan_instit, id_institution, id_health_plan)
                    VALUES
                        (o_id_health_plan_instit, i.column_value, o_id_health_plan);
                EXCEPTION
                    WHEN dup_val_on_index THEN
                        NULL;
                END;
            END LOOP;
        
        ELSE
        
            g_error := 'GET HEALTH_PLANINSTIT OF HEALTH_PLAN TO UPDATE';
            pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN_EXT ' || g_error);
            SELECT hpi.id_health_plan_instit
              INTO o_id_health_plan_instit
              FROM health_plan_instit hpi
             WHERE hpi.id_health_plan = i_id_health_plan
               AND hpi.id_institution = i_id_institution;
        
            g_error := 'INSERT INTO HEALTH_PLAN - ID: ' || i_id_health_plan || ', NAME: ' || i_health_plan_desc;
            pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN_EXT ' || g_error);
            UPDATE health_plan hp
               SET hp.id_health_plan_entity      = nvl(i_id_health_plan_entity, hp.id_health_plan_entity),
                   hp.id_health_plan_type        = nvl(i_id_health_plan_type, hp.id_health_plan_type),
                   hp.national_identifier_number = nvl(i_national_identifier_number, hp.national_identifier_number),
                   hp.flg_available              = i_flg_available
             WHERE hp.id_health_plan = i_id_health_plan;
        
            g_error := 'GET LANGUAGES TO INSERT IN TRANSLATION';
            pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN_EXT ' || g_error);
            OPEN c_language;
            LOOP
                FETCH c_language
                    INTO l_id_lang;
                EXIT WHEN c_language%NOTFOUND;
            
                g_error := 'INSERT_INTO_TRANSLATION HEALTH_PLAN - ID: ' || i_id_health_plan || ', NAME: ' ||
                           i_health_plan_desc;
                pk_alertlog.log_debug('PK_ADT.SET_HEALTH_PLAN_EXT ' || g_error);
                pk_translation.insert_into_translation(l_id_lang,
                                                       'HEALTH_PLAN.CODE_HEALTH_PLAN.' || i_id_health_plan,
                                                       i_health_plan_desc);
            
            END LOOP;
        
        END IF;
        --notify intf_alert that the new health plan is available in the institution
        pk_ia_event_backoffice.health_plan_institution_new(i_id_health_plan_institution => o_id_health_plan_instit,
                                                           i_id_institution             => i_id_institution);
        o_id_health_plan := nvl(o_id_health_plan, i_id_health_plan);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_HEALTH_PLAN_EXT',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_health_plan_ext;

    FUNCTION is_contact
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        v_is_contact VARCHAR2(1 CHAR);
        v_error      t_error_out;
    BEGIN
    
        SELECT decode(flg_origin, g_origin_schedule, pk_alert_constant.get_yes, pk_alert_constant.get_no)
          INTO v_is_contact
          FROM patient
         WHERE id_patient = i_patient;
    
        RETURN v_is_contact;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'IS_CONTACT',
                                              o_error    => v_error);
            --pk_utils.undo_changes;
            RETURN NULL;
    END is_contact;

    --read spec for full comments
    FUNCTION get_pat_exemptions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_current_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN table_varchar IS
        pat_exemptions table_varchar := table_varchar();
        l_current_date TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        c_myfunction CONSTANT VARCHAR2(100) := 'PK_ADT.GET_PAT_EXEMPTIONS';
        l_error            t_error_out;
        c_valid_exemptions VARCHAR2(1 CHAR) := pk_sysconfig.get_config('ADT_VALID_EXEMPTIONS_WITH_NO_DATES', i_prof);
    BEGIN
    
        --if no date is passed we use current date as reference
        IF i_current_date IS NOT NULL
        THEN
            l_current_date := i_current_date;
        END IF;
    
        --get all valid exemptions for the patient
        --this is only used in GES - Chile
        --exemptions with no effective_date and no expiration_date are considered not valid
        SELECT pk_translation.get_translation(i_lang, 'ISENCAO.CODE_ISENCAO.' || pi.id_isencao) || '-' ||
               pk_sysdomain.get_domain('PAT_ISENCAO.FLG_NOTIF_STATUS', pi.flg_notif_status, i_lang)
          BULK COLLECT
          INTO pat_exemptions
          FROM pat_isencao pi
         WHERE pi.id_patient = i_id_patient
           AND pi.record_status != pk_alert_constant.g_inactive
           AND (pi.flg_notif_status IN (c_notified_exemption, c_pend_notif_exemption) OR
               (pi.flg_notif_status = c_active_exemption AND
               nvl(pi.expiration_date, l_current_date + 1) >= l_current_date AND
               l_current_date >= nvl(pi.effective_date, l_current_date - 1) AND
               (c_valid_exemptions = 'Y' OR (pi.effective_date IS NOT NULL OR pi.expiration_date IS NOT NULL))))
         ORDER BY pi.flg_notif_status, 1;
    
        RETURN pat_exemptions;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              l_error);
            RETURN pat_exemptions;
    END get_pat_exemptions;

    /********************************************************************************
    * read spec for full description 
    *********************************************************************************/
    FUNCTION get_flg_recm
    (
        i_lang              IN language.id_language%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_current_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_flg_recm          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --Patient ID should prevent to exist more than one
        --but we protect this select just in case of other markets dont do the same
        CURSOR c_pat_recm(incurrentdate IN TIMESTAMP WITH LOCAL TIME ZONE) IS
            SELECT 'R'
              FROM v_pat_recm pr
             WHERE pr.id_patient = i_id_patient
               AND (nvl(pr.effective_date, (incurrentdate - 1)) <= incurrentdate)
               AND incurrentdate < nvl(pr.expiration_date, (incurrentdate + 1))
               AND rownum = 1;
    
        CURSOR c_pat_other_recm(incurrentdate IN TIMESTAMP WITH LOCAL TIME ZONE) IS
            SELECT 'O'
              FROM v_pat_other_recm pro
             WHERE pro.id_patient = i_id_patient
               AND (nvl(pro.effective_date, (incurrentdate - 1)) <= incurrentdate)
               AND (incurrentdate < nvl(pro.expiration_date, (incurrentdate + 1)))
               AND rownum = 1;
    
        l_recm_in_use       VARCHAR2(1 CHAR) := '';
        l_other_recm_in_use VARCHAR2(1 CHAR) := '';
        l_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    BEGIN
        g_error := 'GET FLG RECM';
    
        o_flg_recm := '';
    
        --If no date is passed we use current date
        IF i_current_timestamp IS NOT NULL
        THEN
            l_current_timestamp := i_current_timestamp;
        END IF;
    
        g_error := 'GET RECM INFO - ' || i_id_patient || ' - ' || i_prof.institution;
    
        OPEN c_pat_recm(l_current_timestamp);
        FETCH c_pat_recm
            INTO l_recm_in_use;
        CLOSE c_pat_recm;
    
        g_error := 'GET OTHER_RECM INFO - ' || i_id_patient || ' - ' || i_prof.institution;
    
        OPEN c_pat_other_recm(l_current_timestamp);
        FETCH c_pat_other_recm
            INTO l_other_recm_in_use;
        CLOSE c_pat_other_recm;
    
        --This could have the values R, O or RO
        o_flg_recm := l_recm_in_use || l_other_recm_in_use;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FLG_RECM',
                                              o_error);
            RETURN FALSE;
    END get_flg_recm;

    /******************************************************************************
    * read spec for full description 
    *********************************************************************************/
    FUNCTION get_pat_info
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_patient              IN patient.id_patient%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_current_timestamp       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_id_presc                IN table_number DEFAULT NULL,
        i_flg_info_for_medication IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_name                    OUT patient.name%TYPE,
        o_gender                  OUT patient.gender%TYPE,
        o_desc_gender             OUT VARCHAR2,
        o_dt_birth                OUT VARCHAR2,
        o_dt_deceased             OUT VARCHAR2,
        o_flg_migrator            OUT pat_soc_attributes.flg_migrator%TYPE,
        o_id_country_nation       OUT country.alpha2_code%TYPE,
        o_sns                     OUT pat_health_plan.num_health_plan%TYPE,
        o_valid_sns               OUT VARCHAR2,
        o_flg_occ_disease         OUT VARCHAR2,
        o_flg_independent         OUT VARCHAR2,
        o_num_health_plan         OUT pat_health_plan.num_health_plan%TYPE,
        o_hp_entity               OUT VARCHAR2,
        o_id_health_plan          OUT NUMBER,
        o_flg_recm                OUT VARCHAR2,
        o_main_phone              OUT VARCHAR2,
        o_hp_alpha2_code          OUT VARCHAR2,
        o_hp_country_desc         OUT VARCHAR2,
        o_hp_national_ident_nbr   OUT VARCHAR2,
        o_hp_dt_effective         OUT VARCHAR2,
        o_valid_hp                OUT VARCHAR2,
        o_flg_type_hp             OUT health_plan.flg_type%TYPE,
        o_hp_id_content           OUT health_plan.id_content%TYPE,
        o_hp_inst_ident_nbr       OUT pat_health_plan.inst_identifier_number%TYPE,
        o_hp_inst_ident_desc      OUT pat_health_plan.inst_identifier_desc%TYPE,
        o_hp_dt_valid             OUT VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat IS
            SELECT p.name,
                   p.gender,
                   pk_sysdomain.get_domain('PATIENT.GENDER', p.gender, i_lang) desc_gender,
                   pk_date_utils.date_send(i_lang, p.dt_birth, i_prof) dt_birth,
                   pk_date_utils.date_send_tsz(i_lang, p.dt_deceased, i_prof) dt_deceased
              FROM patient p
             WHERE p.id_patient = i_id_patient;
    
        CURSOR c_pat_soc_att IS
            SELECT (SELECT c.alpha2_code
                      FROM country c
                     WHERE c.id_country = psa.id_country_nation),
                   psa.num_main_contact
              FROM pat_soc_attributes psa
             WHERE psa.id_patient = i_id_patient
               AND psa.id_institution = i_prof.institution;
    
        CURSOR c_pat_soc_att_for_all_inst IS
            SELECT (SELECT c.alpha2_code
                      FROM country c
                     WHERE c.id_country = psa.id_country_nation),
                   psa.num_main_contact
              FROM pat_soc_attributes psa
             WHERE psa.id_patient = i_id_patient
               AND psa.id_institution IN
                   (SELECT *
                      FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt)))
               AND rownum = 1;
    
        CURSOR c_pat_soc_att_for_inst_0 IS
            SELECT (SELECT c.alpha2_code
                      FROM country c
                     WHERE c.id_country = psa.id_country_nation),
                   psa.num_main_contact
              FROM pat_soc_attributes psa
             WHERE psa.id_patient = i_id_patient
               AND psa.id_institution = 0;
    
        lhpentity VARCHAR2(1000 CHAR);
        lhpdesc   VARCHAR2(1000 CHAR);
        lidhp     NUMBER(12);
    
        c_profdecease_hp_type  CONSTANT VARCHAR2(1 CHAR) := 'P';
        c_independent_hp_type  CONSTANT VARCHAR2(1 CHAR) := 'I';
        c_national_health_plan CONSTANT health_plan.id_content%TYPE := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID',
                                                                                               i_prof);
    
        l_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_flg_hp_type       health_plan.flg_type%TYPE;
        l_hp_default        health_plan.id_health_plan%TYPE;
    BEGIN
        g_error := 'INIT - get_pat_info: id_patient = ' || i_id_patient || '|id_episode = ' || i_id_episode;
    
        --By default these hplans, diplomas and recm are not used 
        o_flg_occ_disease := g_no;
        o_flg_independent := g_no;
        o_flg_recm        := '';
        o_valid_sns       := pk_alert_constant.g_no;
        o_valid_hp        := g_no;
    
        --If no date is passed we use current date
        IF i_current_timestamp IS NOT NULL
        THEN
            l_current_timestamp := i_current_timestamp;
        END IF;
    
        --Get patient s main info
        OPEN c_pat;
        FETCH c_pat
            INTO o_name, o_gender, o_desc_gender, o_dt_birth, o_dt_deceased;
        CLOSE c_pat;
    
        g_error := 'GET PAT_SOC_ATT INFO';
        --First we try to find patient demographic information at
        --the current institution
        OPEN c_pat_soc_att;
        FETCH c_pat_soc_att
            INTO o_id_country_nation, o_main_phone;
    
        --If demographic info was not found at the curent institution
        --lets try to find in the health center institution
        IF c_pat_soc_att%NOTFOUND
        THEN
            OPEN c_pat_soc_att_for_all_inst;
            FETCH c_pat_soc_att_for_all_inst
                INTO o_id_country_nation, o_main_phone;
        
            --If nothing was found we try to find info
            --for institution 0
            IF c_pat_soc_att_for_all_inst%NOTFOUND
            THEN
                OPEN c_pat_soc_att_for_inst_0;
                FETCH c_pat_soc_att_for_inst_0
                    INTO o_id_country_nation, o_main_phone;
                CLOSE c_pat_soc_att_for_inst_0;
            END IF;
        
            CLOSE c_pat_soc_att_for_all_inst;
        END IF;
        CLOSE c_pat_soc_att;
    
        --get recm information
        g_error := 'Call get_flg_recm- ' || i_id_patient || ' - ' || i_prof.institution;
        IF NOT get_flg_recm(i_lang              => i_lang,
                            i_id_patient        => i_id_patient,
                            i_prof              => i_prof,
                            i_current_timestamp => l_current_timestamp,
                            o_flg_recm          => o_flg_recm,
                            o_error             => o_error)
        THEN
            RAISE g_adtexception;
        END IF;
    
        --Requested by functional analysis
        --IF RECM is defined in prescription, other recm "O" should be included (except in header)
        g_error := 'Call get_regulations_by_presc';
        IF (pk_rt_med_pfh.get_regulations_by_presc(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc) =
           pk_alert_constant.g_yes)
        THEN
            IF substr(o_flg_recm, -1) <> 'O'
               OR o_flg_recm IS NULL
            THEN
                o_flg_recm := o_flg_recm || 'O';
            END IF;
        END IF;
    
        --Get national health number information 
        g_error := 'Call get_national_health_number - ' || i_id_patient || ' - ' || i_prof.institution;
        IF NOT get_national_health_number(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_id_patient      => i_id_patient,
                                          o_hp_id_hp        => lidhp,
                                          o_num_health_plan => o_sns,
                                          o_hp_entity       => lhpentity,
                                          o_hp_desc         => lhpdesc,
                                          o_error           => o_error)
        THEN
            pk_alertlog.log_warn(g_error);
        END IF;
    
        --Validate NHN to return validation status
        IF validate_sns(i_sns => o_sns)
        THEN
            o_valid_sns := pk_alert_constant.g_yes;
        END IF;
    
        IF (i_flg_info_for_medication = pk_alert_constant.g_yes)
        THEN
            g_error := 'GET HP INFO';
            --Get health plan info for header (all rules apply)
            BEGIN
                SELECT numhp,
                       desc_hplan,
                       idhp,
                       hp_expiration,
                       CASE
                       --has comparticipation
                           WHEN flg_type IN (c_sns_hp_type,
                                             c_profdecease_hp_type,
                                             c_adse_hp_type,
                                             c_other_reimbursed_plan,
                                             c_cesd_hp_type) THEN
                            pk_alert_constant.g_yes
                           ELSE
                            pk_alert_constant.g_no
                       END,
                       flg_type,
                       id_content,
                       hp_validation
                  INTO o_num_health_plan,
                       o_hp_entity,
                       o_id_health_plan,
                       o_hp_dt_effective,
                       o_valid_hp,
                       l_flg_hp_type,
                       o_hp_id_content,
                       o_hp_dt_valid
                  FROM (SELECT php.num_health_plan numhp,
                               pk_translation.get_translation(i_lang,
                                                              'HEALTH_PLAN.CODE_HEALTH_PLAN.' || php.id_health_plan) desc_hplan,
                               decode(ehp.id_episode, i_id_episode, 1, 0) in_use_epis,
                               decode(php.flg_default, pk_alert_constant.g_yes, 1, 0) in_use,
                               php.id_health_plan idhp,
                               pk_date_utils.date_send(i_lang, php.dt_effective, i_prof) hp_expiration,
                               decode(ehp.flg_primary, 'Y', 1, 0) epis_flg_primary,
                               hp.flg_type,
                               /*CASE hp.flg_type
                                   WHEN c_profdecease_hp_type THEN
                                    1
                                   WHEN c_adse_hp_type THEN
                                    2
                                   WHEN c_other_reimbursed_plan THEN
                                    3
                                   WHEN c_sns_hp_type THEN
                                    4
                                   WHEN c_cesd_hp_type THEN
                                    5
                                   ELSE
                                    6
                               END hp_flg_type_rank,*/
                               CASE
                                    WHEN hp.flg_type = c_profdecease_hp_type THEN
                                     1
                                    WHEN hp.id_content = c_national_health_plan THEN --SNS
                                     2
                                    WHEN hp.flg_type = c_sns_hp_type THEN
                                     3
                                    WHEN hp.flg_type = c_cesd_hp_type THEN
                                     4
                                    WHEN hp.flg_type IN (c_adse_hp_type, c_other_reimbursed_plan) THEN
                                     5
                                    ELSE
                                     6
                                END hp_flg_type_rank,
                               hp.id_content,
                               pk_date_utils.date_send(i_lang, php.dt_health_plan, i_prof) hp_validation
                          FROM pat_health_plan php
                          LEFT JOIN epis_health_plan ehp
                            ON php.id_pat_health_plan = ehp.id_pat_health_plan
                          JOIN health_plan hp
                            ON hp.id_health_plan = php.id_health_plan
                         WHERE php.id_patient = i_id_patient
                           AND php.id_institution IN
                               (SELECT *
                                  FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution,
                                                                           pk_ehr_access.g_inst_grp_flg_rel_adt)))
                              /*AND (php.flg_default = pk_alert_constant.g_yes OR
                              nvl2(i_id_episode,
                                    decode(ehp.id_episode, i_id_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                                    pk_alert_constant.g_no) = pk_alert_constant.g_yes)*/
                           AND php.flg_status = pk_edis_proc.g_hplan_active
                           AND (ehp.id_episode IS NULL OR ehp.id_episode = i_id_episode)
                         ORDER BY hp_flg_type_rank, php.flg_default DESC, in_use_epis DESC, in_use DESC)
                 WHERE rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    o_num_health_plan := NULL;
                    o_hp_entity       := NULL;
            END;
        ELSE
            g_error := 'GET HP INFO';
            --Get health plan info for header (all rules apply)
            BEGIN
                SELECT numhp,
                       desc_hplan,
                       idhp,
                       hp_expiration,
                       CASE
                       --has comparticipation
                           WHEN flg_type IN (c_sns_hp_type,
                                             c_profdecease_hp_type,
                                             c_adse_hp_type,
                                             c_other_reimbursed_plan,
                                             c_cesd_hp_type) THEN
                            pk_alert_constant.g_yes
                           ELSE
                            pk_alert_constant.g_no
                       END,
                       flg_type,
                       id_content,
                       hp_validation
                  INTO o_num_health_plan,
                       o_hp_entity,
                       o_id_health_plan,
                       o_hp_dt_effective,
                       o_valid_hp,
                       l_flg_hp_type,
                       o_hp_id_content,
                       o_hp_dt_valid
                  FROM (SELECT php.num_health_plan numhp,
                               pk_translation.get_translation(i_lang,
                                                              'HEALTH_PLAN.CODE_HEALTH_PLAN.' || php.id_health_plan) desc_hplan,
                               decode(ehp.id_episode, i_id_episode, 1, 0) in_use_epis,
                               decode(php.flg_default, pk_alert_constant.g_yes, 1, 0) in_use,
                               php.id_health_plan idhp,
                               pk_date_utils.date_send(i_lang, php.dt_effective, i_prof) hp_expiration,
                               decode(ehp.flg_primary, 'Y', 1, 0) epis_flg_primary,
                               hp.flg_type,
                               CASE hp.flg_type
                                   WHEN c_profdecease_hp_type THEN
                                    1
                                   WHEN c_adse_hp_type THEN
                                    2
                                   WHEN c_other_reimbursed_plan THEN
                                    3
                                   WHEN c_sns_hp_type THEN
                                    4
                                   WHEN c_cesd_hp_type THEN
                                    5
                                   ELSE
                                    6
                               END hp_flg_type_rank,
                               hp.id_content,
                               pk_date_utils.date_send(i_lang, php.dt_health_plan, i_prof) hp_validation
                          FROM pat_health_plan php
                          LEFT JOIN epis_health_plan ehp
                            ON php.id_pat_health_plan = ehp.id_pat_health_plan
                          JOIN health_plan hp
                            ON hp.id_health_plan = php.id_health_plan
                         WHERE php.id_patient = i_id_patient
                           AND php.id_institution IN
                               (SELECT *
                                  FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution,
                                                                           pk_ehr_access.g_inst_grp_flg_rel_adt)))
                           AND (php.flg_default = pk_alert_constant.g_yes OR
                               nvl2(i_id_episode,
                                     decode(ehp.id_episode, i_id_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                                     pk_alert_constant.g_no) = pk_alert_constant.g_yes)
                           AND php.flg_status = pk_edis_proc.g_hplan_active
                           AND (ehp.id_episode IS NULL OR ehp.id_episode = i_id_episode)
                         ORDER BY hp_flg_type_rank, epis_flg_primary DESC, in_use_epis DESC, in_use DESC)
                 WHERE rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    o_num_health_plan := NULL;
                    o_hp_entity       := NULL;
            END;
        END IF;
    
        IF (o_sns IS NULL)
        THEN
            g_error := 'GET FLG_MIGRATOR';
            BEGIN
                SELECT t.flg_migrant,
                       t.national_identifier_number,
                       (SELECT c.alpha2_code
                          FROM country c
                         WHERE c.id_country = t.id_country) hp_alpha2_code,
                       (SELECT pk_translation.get_translation(i_lang, c.code_country)
                          FROM country c
                         WHERE c.id_country = t.id_country) hp_country_desc,
                       inst_identifier_number,
                       inst_identifier_desc
                  INTO o_flg_migrator,
                       o_hp_national_ident_nbr,
                       o_hp_alpha2_code,
                       o_hp_country_desc,
                       o_hp_inst_ident_nbr,
                       o_hp_inst_ident_desc
                  FROM (SELECT php.flg_migrant,
                               nvl(php.national_identifier_number, hp.national_identifier_number) national_identifier_number,
                               nvl(php.id_country, hp.id_country) id_country,
                               php.inst_identifier_number,
                               php.inst_identifier_desc
                          FROM pat_health_plan php
                          JOIN health_plan hp
                            ON hp.id_health_plan = php.id_health_plan
                         WHERE php.id_patient = i_id_patient
                           AND php.flg_migrant = g_yes
                           AND php.id_institution IN
                               (SELECT *
                                  FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution,
                                                                           pk_ehr_access.g_inst_grp_flg_rel_adt)))
                           AND php.flg_status = pk_alert_constant.g_active) t
                 WHERE rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    o_flg_migrator := g_no;
            END;
        END IF;
    
        --get sns info if no health plan is returned above
        IF o_num_health_plan IS NULL
           AND o_hp_entity IS NULL
        THEN
            o_num_health_plan := o_sns;
            --The national health plan is only returned if patient has a non-null national health number
            IF o_num_health_plan IS NOT NULL
            THEN
                o_hp_entity := lhpdesc;
            
                BEGIN
                    SELECT hp.id_health_plan
                      INTO l_hp_default
                      FROM health_plan hp
                     WHERE hp.id_content = c_national_health_plan
                       AND hp.flg_available = 'Y';
                    o_id_health_plan := l_hp_default;
                    o_hp_id_content  := c_national_health_plan;
                EXCEPTION
                    WHEN no_data_found THEN
                        o_id_health_plan := NULL;
                        l_flg_hp_type    := '';
                END;
            
                IF o_id_health_plan IS NOT NULL
                THEN
                    BEGIN
                        SELECT hp.flg_type
                          INTO l_flg_hp_type
                          FROM health_plan hp
                         WHERE hp.id_health_plan = o_id_health_plan;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_flg_hp_type := '';
                    END;
                END IF;
            END IF;
        END IF;
    
        --As requested for RNU purposes
        IF l_flg_hp_type = c_profdecease_hp_type
        THEN
            o_flg_occ_disease := g_yes;
        ELSIF l_flg_hp_type = c_independent_hp_type
        THEN
            o_flg_independent := g_yes;
        END IF;
    
        o_flg_type_hp := l_flg_hp_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_adtexception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_INFO',
                                              o_error);
            RETURN FALSE;
    END get_pat_info;

    FUNCTION get_main_contact
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_contact_method IN contact_method.id_contact_method%TYPE,
        o_contact           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        c_myfunction CONSTANT VARCHAR2(100) := 'PK_ADT.get_main_contact';
        l_person patient.id_patient%TYPE;
    BEGIN
    
        --log input parameters
        g_error := c_myfunction || ' LANG:' || i_lang || ' PROF:' || i_prof.id || ' INST:' || i_prof.institution ||
                   ' SOFT:' || i_prof.software || ' PAT:' || i_id_patient || ' CM:' || i_id_contact_method;
    
        pk_alertlog.log_debug(g_error);
    
        g_error := 'GET PERSON';
    
        SELECT p.id_person
          INTO l_person
          FROM patient p
         WHERE p.id_patient = i_id_patient;
    
        g_error := 'GET MAIN CONTACT';
    
        SELECT contact_val
          INTO o_contact
          FROM (SELECT *
                  FROM (SELECT cp.phone_number contact_val, cp.id_contact_type, c.id_contact_entity
                          FROM contact c
                          JOIN contact_address ca
                            ON ca.id_contact_address = c.id_contact
                           AND ca.flg_main_address = 'Y'
                          JOIN contact_phone cp
                            ON cp.id_contact = c.id_contact
                         WHERE c.id_contact_entity = l_person
                        UNION
                        SELECT ce.email_value, ce.id_contact_type, c.id_contact_entity
                          FROM contact c
                          JOIN contact_address ca
                            ON ca.id_contact_address = c.id_contact
                           AND ca.flg_main_address = 'Y'
                          JOIN contact_email ce
                            ON ce.id_contact = c.id_contact
                         WHERE c.id_contact_entity = l_person) v
                  JOIN contact_method_cont_type cmct
                    ON cmct.id_contact_type = v.id_contact_type
                 WHERE cmct.id_contact_method = i_id_contact_method
                 ORDER BY cmct.priority ASC)
         WHERE rownum = 1;
    
        g_error := c_myfunction || ' CNT:' || o_contact;
    
        pk_alertlog.log_debug(g_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            --If there is no information it should not be an error
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              o_error);
            RETURN FALSE;
    END get_main_contact;

    --see spec for full comments
    FUNCTION validate_sns(i_sns IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
    
        --checks if the last digit (aka check digit) respects ISO 7064 Mod 11,10 standard
        IF length(i_sns) <> 9
        THEN
            RETURN FALSE;
        ELSE
            RETURN pk_iso_utils.get_mod_11_10_check_digit(substr(i_sns, 1, length(i_sns) - 1)) = substr(i_sns, -1, 1);
        END IF;
    
    EXCEPTION
        WHEN value_error THEN
            --pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN FALSE;
    END validate_sns;

    PROCEDURE init_mappings IS
    BEGIN
    
        --populate country mappings      
        FOR i IN (SELECT *
                    FROM adt_map_values a
                   WHERE a.id_market = g_it_market
                     AND a.value_type = 'COUNTRY')
        LOOP
            l_countries_map(i.original_value) := i.mapped_value;
        END LOOP;
    
        --populate check digit mappings      
        FOR i IN (SELECT *
                    FROM adt_map_values a
                   WHERE a.id_market = g_it_market
                     AND a.value_type = 'TAX_NUMBER_CHECK_DIGIT')
        LOOP
            l_check_digits_map(i.original_value) := i.mapped_value;
        END LOOP;
    
        --populate even digit mappings      
        FOR i IN (SELECT *
                    FROM adt_map_values a
                   WHERE a.id_market = g_it_market
                     AND a.value_type = 'TAX_NUMBER_MAP_VAL'
                     AND a.value_condition = '0')
        LOOP
            l_even_values(i.original_value) := i.mapped_value;
        END LOOP;
    
        --populate odd digit mappings      
        FOR i IN (SELECT *
                    FROM adt_map_values a
                   WHERE a.id_market = g_it_market
                     AND a.value_type = 'TAX_NUMBER_MAP_VAL'
                     AND a.value_condition = '1')
        LOOP
            l_odd_values(i.original_value) := i.mapped_value;
        END LOOP;
    
    END init_mappings;

    PROCEDURE init_mappings_curp IS
    BEGIN
    
        --populate invalid words for CURP
        FOR i IN (SELECT *
                    FROM adt_map_values a
                   WHERE a.id_market = g_mx_market
                     AND a.value_type = 'CURP_INVALID_WORDS')
        LOOP
            l_curp_invalid_words(i.original_value) := i.mapped_value;
        END LOOP;
    
    END init_mappings_curp;

    /********************************************************************************************
    * Generates Italian tax number
    *
    * The calculation of the Fiscal Code is carried out thanks to an algorithm
    * that generates a result of sixteenalphanumeric digits, distributed in the following order:
    *
    * - Three letters for the first name. 
    * - Three letters for the last name. 
    * - Five characters for the date of birth and sex. 
    * - Four characters for the city of birth. 
    * - A letter as a control character.
    *
    * @param      
    * @return                      generated italian tax number
    *
    * @author                      Bruno Martins
    * @since                       
    * @version                     2.6.1
    ********************************************************************************************/
    FUNCTION generate_it_tax_number
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_first_name IN patient.first_name%TYPE,
        i_last_name  IN patient.last_name%TYPE,
        i_dt_birth   IN patient.dt_birth%TYPE,
        i_gender     IN patient.gender%TYPE,
        i_country    IN country.id_country%TYPE,
        i_commune    IN rb_regional_classifier.id_rb_regional_classifier%TYPE
    ) RETURN VARCHAR2 IS
        l_tax_number  VARCHAR2(16 CHAR);
        l_first_names VARCHAR2(1000 CHAR) := translate(upper(i_first_name),
                                                       'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                                       'AEIOUAEIOUAEIOUAOCAEIOUN');
        l_last_names  VARCHAR2(1000 CHAR) := translate(upper(i_last_name),
                                                       'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                                       'AEIOUAEIOUAEIOUAOCAEIOUN');
        l_first_name  VARCHAR2(1000 CHAR) := l_first_names;
        l_date_gender VARCHAR2(5 CHAR);
        l_day         VARCHAR2(2 CHAR);
        l_state       VARCHAR2(4 CHAR);
        l_check_digit VARCHAR2(1 CHAR);
        l_error       t_error_out;
        l_sum         PLS_INTEGER := 0;
    BEGIN
    
        init_mappings();
    
        --For the surname consonant of the latter are taken (or names, if there is more than one) in their order:
        --just in case you are taken are insufficient also increasingly vocal in their order: however, the vowels are shown after consonants.
        --In some special cases such as surnames that are less than three letters, the code is completed by adding the letter X
        --(for example, the name will become RE REX).
        l_last_names := substr(regexp_replace(l_last_names, '[^B-DF-HJ-NP-TV-Z]', '') ||
                               regexp_replace(l_last_names, '[^AEIOU]', '') || 'XXX',
                               1,
                               3);
    
        l_first_names := regexp_replace(l_first_names, '[^B-DF-HJ-NP-TV-Z]', '');
    
        --if the name contains four or more consonants, we choose the first, the third and the fourth
        IF length(l_first_names) > 3
        THEN
            l_first_names := substr(l_first_names, 1, 1) || substr(l_first_names, 3, 1) || substr(l_first_names, 4, 1);
        ELSE
            --otherwise the first three in order.
            --Only if the name does not have enough consonants, they also take the vowels:
            --however, the vowels are shown after consonants. In the case where the name has less than three letters,
            --the portion of code is completed by adding the letter X.
            l_first_names := substr(l_first_names || regexp_replace(l_first_name, '[^AEIOU]', '') || 'XXX', 1, 3);
        END IF;
    
        --Date of birth and gender (5 alphanumeric characters) 
        --Year of birth (2 digits): vegnono took the last two digits of the year of birth; 
        --Month of birth (1 letter): each month of the year corrispodne based on the Tabella 1
        --Date of birth and sex (2 digits) are taken the two-digit day of birth
        --(if it is between 1 and 9 stands a zero as the first digit), for female persons in this figure must be added the number 40. 
        l_day := CASE
                     WHEN i_gender = 'F' THEN
                      to_char(to_number(to_char(i_dt_birth, 'DD')) + 40)
                     ELSE
                      to_char(i_dt_birth, 'DD')
                 END;
    
        l_date_gender := to_char(i_dt_birth, 'YY') || CASE to_char(i_dt_birth, 'MM')
                             WHEN '01' THEN
                              'A'
                             WHEN '02' THEN
                              'B'
                             WHEN '03' THEN
                              'C'
                             WHEN '04' THEN
                              'D'
                             WHEN '05' THEN
                              'E'
                             WHEN '06' THEN
                              'H'
                             WHEN '07' THEN
                              'L'
                             WHEN '08' THEN
                              'M'
                             WHEN '09' THEN
                              'P'
                             WHEN '10' THEN
                              'R'
                             WHEN '11' THEN
                              'S'
                             ELSE
                              'T'
                         END || l_day;
    
        --City of birth (4 alphanumeric characters) 
        --For the City of Birth is used code of the town of birth consisting of a letter and three digits
        IF i_commune IS NOT NULL
        THEN
            BEGIN
                SELECT r.reg_classifier_code
                  INTO l_state
                  FROM rb_regional_classifier r
                 WHERE r.id_rb_regional_classifier = i_commune;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'No mapping for rb_reg:' || i_commune;
                    RAISE g_adtexception;
            END;
        
            --If the patient was born outside the Italian territory is considered the foreign state of birth,
            --in which case the abbreviation starts with the letter Z followed by the identification number of the nation.
        ELSIF i_country IS NOT NULL
        THEN
        
            IF l_countries_map.exists(i_country)
            THEN
                l_state := l_countries_map(i_country);
            ELSE
                g_error := 'No mapping for id_country:' || i_country;
                RAISE g_adtexception;
            END IF;
        
        END IF;
    
        IF l_state IS NULL
        THEN
            g_error := 'l_state NULL';
            RAISE g_adtexception;
        END IF;
    
        l_tax_number := l_last_names || l_first_names || l_date_gender || l_state;
    
        FOR i IN 1 .. 15
        LOOP
            IF MOD(i, 2) = 0
            THEN
                l_sum := l_sum + to_number(l_even_values(substr(l_tax_number, i, 1)));
            ELSE
                l_sum := l_sum + to_number(l_odd_values(substr(l_tax_number, i, 1)));
            END IF;
        END LOOP;
    
        l_check_digit := l_check_digits_map(MOD(l_sum, 26));
    
        l_tax_number := l_tax_number || l_check_digit;
    
        g_error := 'pk_adt.generate_it_tax_number: ' || l_last_names || '-' || l_first_names || '-' || l_date_gender || '-' ||
                   l_state || '-' || l_check_digit;
    
        pk_alertlog.log_debug(g_error);
    
        RETURN l_tax_number;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'generate_it_tax_number',
                                              l_error);
            RETURN NULL;
    END generate_it_tax_number;

    --see spec for full comments
    FUNCTION validate_it_tax_number
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_first_name IN patient.first_name%TYPE,
        i_last_name  IN patient.last_name%TYPE,
        i_dt_birth   IN patient.dt_birth%TYPE,
        i_gender     IN patient.gender%TYPE,
        i_country    IN country.id_country%TYPE,
        i_commune    IN rb_regional_classifier.id_rb_regional_classifier%TYPE,
        i_tax_number IN pat_soc_attributes.num_contrib%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        --Test parameter values
        IF i_first_name IS NULL
           OR i_last_name IS NULL
           OR i_dt_birth IS NULL
           OR i_gender IS NULL
           OR i_commune IS NULL
           OR i_tax_number IS NULL
        THEN
            g_error := 'INVALID INPUT';
            RAISE g_adtexception;
        END IF;
    
        RETURN generate_it_tax_number(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_first_name => i_first_name,
                                      i_last_name  => i_last_name,
                                      i_dt_birth   => i_dt_birth,
                                      i_gender     => i_gender,
                                      i_country    => i_country,
                                      i_commune    => i_commune) = upper(i_tax_number);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'validate_it_tax_number',
                                              o_error);
            RETURN FALSE;
    END validate_it_tax_number;

    /********************************************************************************************
    * Generates Mexican CURP
    * http://giro.com.mx/?page_id=72
    * 
    * Every CURP is a eighteenfalphanumeric string with the following characteristics (in spanish)
    *
    * Posición 1-4 La letra inicial y la primera vocal interna del primer apellido, la letra
    * inicial del segundo apellido y la primera letra del nombre. En el
    * caso de las mujeres casadas, se deberán usar los apellidos de
    * soltera (alfabética).
    *
    * Posición 5-10 La fecha de nacimiento en el orden de año, mes y día. Para el año
    * se tomarán los dos últimos dígitos, cuando el mes o el día sea
    * menor a diez, se antepondrá un cero.
    * 1 de diciembre de 1995, Quedaría: 951201 (numérica)
    *
    * Posición 11 Sexo M para mujer y H para hombre (alfabética)
    *
    * Posición 12-13 La letra inicial y última consonante, del nombre del estado de
    * nacimiento conforme al Catálogo de Entidades Federativas (SEGOB)
    *
    * Posición 14-16 Integradas por las primeras consonantes internas del primer
    * apellido, segundo apellido y nombre (alfabética).
    *
    * Posición 17 Diferenciador de homonimia y siglo, caracter progresivo asignado
    * por la Secretaría de Gobernación que se emplea para diferenciar
    * registros homónimos, 1-9 para fechas de nacimiento hasta el año
    * 1999 y A-Z para fechas de nacimiento a partir de 2000 (alfanumérica).
    *
    * Posición 18 Dígito verificador, caracter asignado por la Secretaría de
    * Gobernación a través de la aplicación de un algoritmo que permite
    * calcular y verificar la correcta conformación y transcripción de la clave.
    *
    * @param      
    * @return                      generated mexican curp
    *
    * @author                      Bruno Martins
    * @since                       
    * @version                     2.6.3
    ********************************************************************************************/
    FUNCTION generate_mx_curp
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_first_name  IN patient.first_name%TYPE, --nome
        i_middle_name IN patient.middle_name%TYPE, --segundo apellido
        i_last_name   IN patient.last_name%TYPE, --primer apellido
        i_dt_birth    IN patient.dt_birth%TYPE,
        i_gender      IN patient.gender%TYPE,
        i_country     IN country.id_country%TYPE,
        i_state       IN rb_regional_classifier.id_rb_regional_classifier%TYPE,
        i_letter_curp IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_curp VARCHAR2(18 CHAR);
    
        l_first_names  VARCHAR2(1000 CHAR) := translate(upper(TRIM(i_first_name)),
                                                        'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                                        'AEIOUAEIOUAEIOUAOCAEIOUX');
        l_last_names   VARCHAR2(1000 CHAR) := translate(upper(TRIM(i_last_name)),
                                                        'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                                        'AEIOUAEIOUAEIOUAOCAEIOUX');
        l_middle_names VARCHAR2(1000 CHAR) := translate(upper(TRIM(i_middle_name)),
                                                        'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                                        'AEIOUAEIOUAEIOUAOCAEIOUX');
    
        l_first_names_consonants  VARCHAR2(1000 CHAR);
        l_middle_names_consonants VARCHAR2(1000 CHAR);
        l_last_names_consonants   VARCHAR2(1000 CHAR);
        l_last_names_vowels       VARCHAR2(1000 CHAR);
        l_last_first_name         VARCHAR2(1000 CHAR);
    
        TYPE names_exceptions_list IS TABLE OF VARCHAR2(20);
        l_names_exceptions names_exceptions_list := names_exceptions_list('MARIA',
                                                                          'MA.',
                                                                          'MA',
                                                                          'JOSE',
                                                                          'J',
                                                                          'J.',
                                                                          'DA',
                                                                          'DAS',
                                                                          'DE',
                                                                          'DEL',
                                                                          'DER',
                                                                          'DI',
                                                                          'DIE',
                                                                          'DD',
                                                                          'EL',
                                                                          'LA',
                                                                          'LOS',
                                                                          'LAS',
                                                                          'LE',
                                                                          'LES',
                                                                          'MAC',
                                                                          'MC',
                                                                          'VAN',
                                                                          'VON',
                                                                          'Y');
    
        l_names_to_array table_varchar2 := table_varchar2();
        l_entry_found    BOOLEAN;
    
        l_state VARCHAR2(4 CHAR);
        l_error t_error_out;
        --l_sum                     PLS_INTEGER := 0;
    
        c_mexico_id_ctry PLS_INTEGER := 484;
        c_foreign_suffix VARCHAR2(2 CHAR) := 'NE';
        l_year           NUMBER;
    BEGIN
    
        --Quando a “fecha de nacimiento” é do ano de 1999 para a frente, o penúltimo caractere do CURP deverá ser uma “Letra”
        --Quando a “fecha de nacimiento” é do ano de 1999 para trás, o penúltimo caractere do CURP deverá ser uma “Número”
        l_year := to_char(i_dt_birth, 'YYYY');
    
        IF l_year > 1999
        THEN
            IF pk_utils.is_number(i_letter_curp) = pk_alert_constant.g_yes
            THEN
                RETURN l_curp;
            END IF;
        ELSE
            IF pk_utils.is_number(i_letter_curp) = pk_alert_constant.g_no
            THEN
                RETURN l_curp;
            END IF;
        END IF;
    
        --Init ADT mappings for CURP
        init_mappings_curp();
    
        /********************************
        * Criterios de excepcion
        ********************************/
    
        -- Siempre que no sea MARIA, MA., MA, o JOSE, J, J. o
        -- cuando alguno de los apellidos o nombre es compuesto y la primera palabra de esta comosción es uma preposición,
        -- conjunción, contracción (DA, DAS, DE, DEL, DER, DI, DIE, DD, EL, LA, LOS, LAS, LE, LES, MAC, MC, VAN, VON, Y),
        -- REMOVE-LAS
    
        /**** FIRST_NAMES *****/
        l_names_to_array := pk_utils.str_split(i_list => l_first_names, i_delim => ' ');
    
        -- Cuando el nombre sea compuesto (formado por dos o más palabras), la clave se construye con la letra inicial
        -- de la primera palabra, siempre que no sea MARIA, MA., MA, o JOSE, J, J. en cuyo caso se utilizará
        -- la segunda palabra
        IF (l_names_to_array.count > 1)
        THEN
            l_entry_found := TRUE;
        
            IF (cardinality(l_names_to_array) > 0)
            THEN
                l_last_first_name := l_names_to_array(l_names_to_array.last);
            END IF;
        
            WHILE l_entry_found
            LOOP
                IF (cardinality(l_names_to_array) > 0)
                THEN
                    IF l_names_to_array(1) MEMBER OF(l_names_exceptions)
                    THEN
                        l_names_to_array := pk_utils.remove_element(i_input => l_names_to_array, i_index => 1);
                    ELSE
                        l_entry_found := FALSE;
                    END IF;
                
                    l_first_names := pk_utils.concat_table(i_table => l_names_to_array, i_delim => '');
                ELSE
                    l_first_names := l_last_first_name;
                    l_entry_found := FALSE;
                END IF;
            
            END LOOP;
        
            IF (cardinality(l_names_to_array) > 1)
            THEN
                l_first_names := l_names_to_array(1);
            END IF;
        END IF;
    
        l_first_names_consonants := regexp_replace(l_first_names, '[^B-DF-HJ-NP-TV-Z]', '');
    
        /**** MIDDLE_NAMES *****/
        l_names_to_array := pk_utils.str_split(i_list => l_middle_names, i_delim => ' ');
    
        IF (cardinality(l_names_to_array) > 1)
        THEN
            l_entry_found := TRUE;
        
            WHILE l_entry_found
            LOOP
                IF l_names_to_array(1) MEMBER OF(l_names_exceptions)
                THEN
                    l_names_to_array := pk_utils.remove_element(i_input => l_names_to_array, i_index => 1);
                ELSE
                    l_entry_found := FALSE;
                END IF;
            
                l_middle_names := pk_utils.concat_table(i_table => l_names_to_array, i_delim => '');
            
            END LOOP;
        END IF;
    
        l_middle_names_consonants := regexp_replace(l_middle_names, '[^B-DF-HJ-NP-TV-Z]', '');
    
        /**** LAST_NAMES *****/
        l_names_to_array := pk_utils.str_split(i_list => l_last_names, i_delim => ' ');
    
        IF (cardinality(l_names_to_array) > 1)
        THEN
            l_entry_found := TRUE;
        
            WHILE l_entry_found
            LOOP
                IF l_names_to_array(1) MEMBER OF(l_names_exceptions)
                THEN
                    l_names_to_array := pk_utils.remove_element(i_input => l_names_to_array, i_index => 1);
                ELSE
                    l_entry_found := FALSE;
                END IF;
            
                l_last_names := pk_utils.concat_table(i_table => l_names_to_array, i_delim => '');
            
            END LOOP;
        END IF;
    
        l_last_names_consonants := regexp_replace(l_last_names, '[^B-DF-HJ-NP-TV-Z]', '');
        l_last_names_vowels     := regexp_replace(l_last_names, '[^AEIOU]');
    
        /********************************
        * COnstruccion del CURP
        ********************************/
    
        --Posición 1-4 La letra inicial y la primera vocal interna del primer apellido, la letra
        --inicial del segundo apellido y la primera letra del nombre.
    
        --La letra inicial
        l_curp := substr(l_last_names, 1, 1);
    
        --if the first letter is a vowel we have to correct this
        IF l_curp IN ('A', 'E', 'I', 'O', 'U')
        THEN
            l_last_names_vowels := substr(l_last_names_vowels, 2, length(l_last_names_vowels));
        ELSE
            l_last_names_consonants := substr(l_last_names_consonants, 2, length(l_last_names_consonants));
        END IF;
    
        -- Si en los apellidos o en el nombre aparecieran carateres especiales como diagonal (/), guión (-), o punto (.),
        -- se captura tal cual viene en el documento probatorio y la aplicacion asignará una "X"
        -- en caso de que esa posición intervenga para la confirmación de la clave
        IF substr(l_last_names, 2, 1) IN ('/', '-', '.')
        THEN
            l_curp := l_curp || 'X';
            --si el primer apellido no tiene vocal interna para la construcción de la CURP
            --el sistema asignará una "X" en la segunda posición.
        ELSIF l_last_names_vowels IS NULL
        THEN
            l_curp := l_curp || 'X';
        ELSE
            --la primera vocal interna del primer apellido
            l_curp := l_curp || substr(l_last_names_vowels, 1, 1);
        END IF;
    
        IF l_middle_names IS NOT NULL
        THEN
        
            IF substr(l_middle_names, 1, 1) NOT IN ('A', 'E', 'I', 'O', 'U')
            THEN
                l_middle_names_consonants := substr(l_middle_names_consonants, 2, length(l_middle_names_consonants));
            END IF;
        
            --la letra inicial del segundo apellido
            l_curp := l_curp || substr(l_middle_names, 1, 1);
        ELSE
            l_curp := l_curp || 'X';
        END IF;
    
        --la primera letra del nombre
        l_curp := l_curp || substr(l_first_names, 1, 1);
    
        --
        IF substr(l_first_names, 1, 1) NOT IN ('A', 'E', 'I', 'O', 'U')
        THEN
            l_first_names_consonants := substr(l_first_names_consonants, 2, length(l_first_names_consonants));
        END IF;
    
        --fecha de nacimiento
        l_curp := l_curp || to_char(i_dt_birth, 'YYMMDD');
    
        --Sexo
        l_curp := l_curp || CASE i_gender
                      WHEN 'M' THEN
                       'H'
                      ELSE
                       'M'
                  END;
    
        -- <12-13> City of birth (2 characters)
        IF i_state IS NOT NULL
        THEN
            BEGIN
                SELECT r.reg_classifier_abbreviation
                  INTO l_state
                  FROM rb_regional_classifier r
                 WHERE r.id_rb_regional_classifier = i_state;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'No mapping for rb_reg:' || i_state;
                    RAISE g_adtexception;
            END;
        
            l_curp := l_curp || l_state;
        
            --If the patient was born outside the Mexican territory NE is returned
        ELSIF i_country IS NOT NULL
              AND i_country <> c_mexico_id_ctry
        THEN
            l_curp := l_curp || c_foreign_suffix;
        ELSE
            g_error := 'Error with i_state:' || i_state || ' or i_country:' || i_country;
            RAISE g_adtexception;
        END IF;
    
        -- <14>
        IF substr(l_last_names_consonants, 1, 1) IS NOT NULL
        THEN
            --las primeras consonantes internas del primer apellido
            l_curp := l_curp || substr(l_last_names_consonants, 1, 1);
        ELSE
            l_curp := l_curp || 'X';
        END IF;
    
        -- <15>
        IF substr(l_middle_names_consonants, 1, 1) IS NOT NULL
        THEN
            --las primeras consonantes internas del segundo apellido
            l_curp := l_curp || substr(l_middle_names_consonants, 1, 1);
        ELSE
            l_curp := l_curp || 'X';
        END IF;
    
        -- <16> las primeras consonantes internas del nombre
        IF substr(l_first_names_consonants, 1, 1) IS NOT NULL
        THEN
            --las primeras consonantes internas del segundo apellido
            l_curp := l_curp || substr(l_first_names_consonants, 1, 1);
        ELSE
            l_curp := l_curp || 'X';
        END IF;
    
        --  l_curp := l_curp || substr(l_first_names_consonants, 1, 1);    
    
        -- Verificar/Substituir palavras proibidas
        IF l_curp_invalid_words.exists(substr(l_curp, 1, 4))
        THEN
            l_curp := l_curp_invalid_words(substr(l_curp, 1, 4)) || substr(l_curp, 5, length(l_curp));
        END IF;
    
        g_error := 'pk_adt.generate_mx_curp:' || l_curp;
    
        pk_alertlog.log_debug(g_error);
    
        RETURN l_curp;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'generate_mx_curp',
                                              l_error);
            RETURN NULL;
    END generate_mx_curp;

    --see spec for full comments
    FUNCTION validate_curp
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_first_name  IN patient.first_name%TYPE,
        i_middle_name IN patient.middle_name%TYPE,
        i_last_name   IN patient.last_name%TYPE,
        i_dt_birth    IN patient.dt_birth%TYPE,
        i_gender      IN patient.gender%TYPE,
        i_country     IN country.id_country%TYPE,
        i_state       IN rb_regional_classifier.id_rb_regional_classifier%TYPE,
        i_curp        IN person.social_security_number%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_curp VARCHAR2(18 CHAR);
    
    BEGIN
    
        --Test parameter values
        IF i_first_name IS NULL
           OR i_last_name IS NULL
           OR i_dt_birth IS NULL
           OR i_gender IS NULL
          --OR (i_state IS NULL AND i_country IS NULL)
           OR i_curp IS NULL
        THEN
            g_error := 'INVALID INPUT';
            RAISE g_adtexception;
        END IF;
    
        l_curp := generate_mx_curp(i_lang        => i_lang,
                                   i_prof        => i_prof,
                                   i_first_name  => i_first_name,
                                   i_middle_name => i_middle_name,
                                   i_last_name   => i_last_name,
                                   i_dt_birth    => i_dt_birth,
                                   i_gender      => i_gender,
                                   i_country     => i_country,
                                   i_state       => i_state,
                                   i_letter_curp => substr(i_curp, 17, 1));
    
        IF l_curp IS NULL
        THEN
            RETURN FALSE;
        ELSE
            RETURN l_curp = upper(substr(i_curp, 1, 16));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'validate_curp',
                                              o_error);
            RETURN FALSE;
    END validate_curp;

    FUNCTION set_discharge_adt
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_discharge  IN discharge.id_discharge%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_visit      IN visit.id_visit%TYPE,
        i_dt_admin_tstz IN discharge.dt_admin_tstz%TYPE,
        i_notes         IN discharge_adt.notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_adt_core.set_discharge_adt(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_id_discharge  => i_id_discharge,
                                             i_id_episode    => i_id_episode,
                                             i_id_visit      => i_id_visit,
                                             i_dt_admin_tstz => i_dt_admin_tstz,
                                             i_notes         => i_notes,
                                             o_error         => o_error);
    
    END set_discharge_adt;

    --see spec for full comments
    FUNCTION update_admission_adt
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode_adt.id_episode%TYPE,
        i_origin        IN admission_adt.id_origin%TYPE,
        i_ext_cause     IN admission_edis.id_external_cause%TYPE,
        i_transp_entity IN admission_edis.id_transp_entity%TYPE,
        i_notes         IN admission_adt.comments%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'pk_adt.update_admission_adt epis: ' || i_episode || ' org:' || i_origin || ' ec:' || i_ext_cause ||
                   ' te:' || i_transp_entity;
    
        pk_alertlog.log_debug(g_error);
    
        RETURN pk_adt_core.call_update_admission_adt(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_episode       => i_episode,
                                                     i_origin        => i_origin,
                                                     i_ext_cause     => i_ext_cause,
                                                     i_transp_entity => i_transp_entity,
                                                     i_notes         => i_notes,
                                                     o_error         => o_error);
    
    END update_admission_adt;

    FUNCTION get_contact_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        o_address  OUT VARCHAR2,
        o_location OUT VARCHAR2,
        o_regional OUT VARCHAR2,
        o_phone1   OUT VARCHAR2,
        o_phone2   OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_contact NUMBER(24);
    BEGIN
    
        g_error := 'pk_adt.get_contact_info lang: ' || i_lang || ' pat:' || i_patient;
    
        pk_alertlog.log_debug(g_error);
    
        --------------------------------------------    
        SELECT id_contact, address_line1, location, regional
          INTO l_contact, o_address, o_location, o_regional
          FROM (SELECT c.id_contact,
                       ca.address_line1,
                       ca.location,
                       pk_translation.get_translation(i_lang,
                                                      'RB_REGIONAL_CLASSIFIER.CODE_RB_REGIONAL_CLASSIFIER.' ||
                                                      ca.id_rb_regional_classifier) regional,
                       row_number() over(ORDER BY decode(ca.flg_main_address, pk_alert_constant.g_yes, 1, 2), nvl(ca.update_time, ca.create_time) DESC) rn
                  FROM contact c
                  JOIN contact_address ca
                    ON ca.id_contact_address = c.id_contact
                 WHERE c.id_contact_entity = (SELECT id_person
                                                FROM patient
                                               WHERE id_patient = i_patient))
         WHERE rn = 1;
    
        g_error := 'pk_adt.get_contact_info contact: ' || l_contact;
    
        pk_alertlog.log_debug(g_error);
    
        SELECT cp.phone_number
          INTO o_phone1
          FROM contact_phone cp
         WHERE cp.id_contact = l_contact
           AND cp.id_contact_type = g_mobile_contact_type;
    
        SELECT cp.phone_number
          INTO o_phone2
          FROM contact_phone cp
         WHERE cp.id_contact = l_contact
           AND cp.id_contact_type = g_landline_contact_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            --o_contact := NULL;
        
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONTACT_INFO',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END get_contact_info;

    FUNCTION build_name
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_config      IN sys_config.value%TYPE,
        i_first_name  IN patient.first_name%TYPE,
        i_second_name IN patient.second_name%TYPE,
        i_midlle_name IN patient.middle_name%TYPE,
        i_last_name   IN patient.last_name%TYPE,
        o_pat_name    OUT patient.name%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patname patient.name%TYPE;
    BEGIN
    
        l_patname  := i_config;
        l_patname  := REPLACE(l_patname, 'F', '%F%');
        l_patname  := REPLACE(l_patname, 'S', '%S%');
        l_patname  := REPLACE(l_patname, 'M', '%M%');
        l_patname  := REPLACE(l_patname, 'L', '%L%');
        l_patname  := REPLACE(l_patname, '%F%', nvl(i_first_name, ''));
        l_patname  := REPLACE(l_patname, '%S%', nvl(i_second_name, ''));
        l_patname  := REPLACE(l_patname, '%M%', nvl(i_midlle_name, ''));
        l_patname  := REPLACE(l_patname, '%L%', nvl(i_last_name, ''));
        l_patname  := REPLACE(l_patname, ', ,', '');
        o_pat_name := l_patname;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'BUILD_NAME',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
        
    END build_name;

    FUNCTION build_name
    (
        i_prof        IN profissional,
        i_first_name  IN VARCHAR2,
        i_middle_name IN VARCHAR2,
        i_last_name   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_config VARCHAR2(20) := pk_sysconfig.get_config('PATIENT_NAME_PATTERN', i_prof);
        l_name   VARCHAR2(1000 CHAR);
        l_error  t_error_out;
    BEGIN
        --If no config was found use default one
        IF l_config IS NULL
        THEN
            pk_alertlog.log_warn('No PATIENT_NAME_PATTERN config for p:' || i_prof.id || ' i:' || i_prof.institution ||
                                 ' s:' || i_prof.software);
            l_config := 'F M L';
        END IF;
    
        l_name := l_config;
        l_name := REPLACE(l_name, 'F', '%F%');
        l_name := REPLACE(l_name, 'M', '%M%');
        l_name := REPLACE(l_name, 'L', '%L%');
        l_name := REPLACE(l_name, '%F%', nvl(i_first_name, ''));
        l_name := REPLACE(l_name, '%M%', nvl(i_middle_name, ''));
        l_name := REPLACE(l_name, '%L%', nvl(i_last_name, ''));
    
        RETURN TRIM(l_name);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'build_name',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN '';
    END build_name;

    FUNCTION get_emergency_contact
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        o_name                OUT VARCHAR2,
        o_contact             OUT VARCHAR2,
        o_family_relationship OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_contact  NUMBER(24);
        l_first_name  contact_entity.name%TYPE;
        l_middle_name contact_entity.middle_name%TYPE;
        l_last_name   contact_entity.last_name%TYPE;
    BEGIN
    
        g_error := 'pk_adt.get_emergency_contact lang:' || i_lang || ' prof:' || i_prof.id || ' pat:' || i_patient;
    
        pk_alertlog.log_debug(g_error);
    
        --Get main info from most important emergency contact
        SELECT id_this_contact_person, desc_family_relationship, name, middle_name, last_name
          INTO l_id_contact, o_family_relationship, l_first_name, l_middle_name, l_last_name
          FROM (SELECT pc.id_this_contact_person,
                       pk_translation.get_translation(i_lang,
                                                      'FAMILY_RELATIONSHIP.CODE_FAMILY_RELATIONSHIP.' ||
                                                      pc.id_family_relationship) desc_family_relationship,
                       ce.name,
                       ce.middle_name,
                       ce.last_name
                  FROM person_contact pc
                  JOIN contact_entity ce
                    ON ce.id_contact_entity = pc.id_this_contact_person
                 WHERE pc.id_origin_person IN (SELECT id_person
                                                 FROM patient
                                                WHERE id_patient = i_patient)
                 ORDER BY pc.priority ASC)
         WHERE rownum = 1;
    
        g_error := 'cnt:' || l_id_contact || ' fn:' || l_first_name || ' mn:' || l_middle_name || ' ln:' || l_last_name;
    
        pk_alertlog.log_debug(g_error);
    
        --Build name
        o_name := build_name(i_prof        => i_prof,
                             i_first_name  => l_first_name,
                             i_middle_name => l_middle_name,
                             i_last_name   => l_last_name);
    
        --Get main phone from emergency contact
        SELECT phone_number
          INTO o_contact
          FROM contact c
          JOIN contact_phone cp
            ON c.id_contact = cp.id_contact
         WHERE id_contact_entity = l_id_contact
           AND id_contact_description IN (g_nl_emergency_contact_desc, g_def_emergency_contact_desc)
           AND id_contact_type = g_emergency_contact_type;
    
        g_error := 'phn:' || o_contact;
    
        pk_alertlog.log_debug(g_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_contact := NULL;
        
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EMERGENCY_CONTACT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END get_emergency_contact;
    /********************************************************************************************
    * Returns patient s emergency contact
    *
    * @param i_lang                language id
    * @param i_prof                professional (id, institution, software)   
    * @param i_patient             patient identifier
    * @param o_name                Emergency contact name
    * @return                      varchar2 emergency contact name
    *
    * @author                      Ana Moita
    * @since                       2012-12-20
    * @version                     2.6
    ********************************************************************************************/
    FUNCTION get_emergency_contact_name
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
        l_emergency_name VARCHAR2(4000);
        l_fam_rel        VARCHAR2(4000);
        l_contact        VARCHAR2(4000);
    
        l_error t_error_out;
    
    BEGIN
    
        IF NOT pk_adt.get_emergency_contact(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_patient             => i_patient,
                                            o_name                => l_emergency_name,
                                            o_contact             => l_contact,
                                            o_family_relationship => l_fam_rel,
                                            o_error               => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_emergency_name;
    
    END get_emergency_contact_name;

    FUNCTION get_inail_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_inail_info OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pat_cit            pat_cit%ROWTYPE;
        l_patient            patient%ROWTYPE;
        l_pat_soc_attributes pat_soc_attributes%ROWTYPE;
        l_contact_address    contact_address%ROWTYPE;
        l_employer           contact_entity%ROWTYPE;
        l_emp_cont_address   contact_address%ROWTYPE;
        l_country_inst       inst_attributes.id_country%TYPE;
        l_invalid_inail_exception EXCEPTION;
    
        c_no_prognosis CONSTANT VARCHAR2(1 CHAR) := 'S';
    BEGIN
    
        --debugging in parameters
        g_error := 'pk_adt.get_inail_info lang: ' || i_lang || ' prof:' || i_prof.id || ' inst:' || i_prof.institution ||
                   ' pat:' || i_patient || ' epis:' || i_episode;
    
        pk_alertlog.log_debug(g_error);
    
        --Get institution country to validate regional classifier info
        BEGIN
            SELECT i.id_country
              INTO l_country_inst
              FROM inst_attributes i
             WHERE i.id_institution = i_prof.institution;
        EXCEPTION
            WHEN no_data_found THEN
                l_country_inst := NULL;
        END;
    
        --this is supposed to be used only for IT market
        --where can only be one INAIL active at the moment per episode
        SELECT *
          INTO l_pat_cit
          FROM pat_cit p
         WHERE p.id_patient = i_patient
           AND p.id_episode = i_episode
           AND p.flg_status <> pk_cit.g_flg_status_canceled;
    
        g_error := 'pk_adt.get_inail_info pat_cit: ' || l_pat_cit.id_pat_cit;
    
        pk_alertlog.log_debug(g_error);
    
        --Get patient info to validate
        SELECT *
          INTO l_patient
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        --Get patient social attributes to validate
        BEGIN
            SELECT *
              INTO l_pat_soc_attributes
              FROM pat_soc_attributes p
             WHERE p.id_patient = i_patient
               AND p.id_institution = i_prof.institution;
        
            g_error := 'pk_adt.get_inail_info psa: ' || l_pat_soc_attributes.id_pat_soc_attributes;
        
            pk_alertlog.log_debug(g_error);
        EXCEPTION
            WHEN no_data_found THEN
                RAISE l_invalid_inail_exception;
        END;
    
        --Get employer info to validate
        BEGIN
            SELECT ce.*
              INTO l_employer
              FROM contact_entity ce
              JOIN pat_employer pe
                ON ce.id_contact_entity = pe.id_pat_employer
             WHERE pe.id_patient = i_patient;
        
            g_error := 'pk_adt.get_inail_info emp: ' || l_employer.id_contact_entity;
        
            pk_alertlog.log_debug(g_error);
        EXCEPTION
            WHEN no_data_found THEN
                RAISE l_invalid_inail_exception;
        END;
    
        --Get employer contact address info to validate
        BEGIN
            SELECT ca.*
              INTO l_emp_cont_address
              FROM contact_address ca
              JOIN contact c
                ON ca.id_contact_address = c.id_contact
             WHERE c.id_contact_entity = l_employer.id_contact_entity
               AND ca.flg_main_address = g_yes;
        
            g_error := 'pk_adt.get_inail_info emp_ca: ' || l_emp_cont_address.id_contact_address;
        
            pk_alertlog.log_debug(g_error);
        EXCEPTION
            WHEN no_data_found THEN
                RAISE l_invalid_inail_exception;
        END;
    
        --Get patient contact address info to validate
        BEGIN
            SELECT ca.*
              INTO l_contact_address
              FROM contact_address ca
              JOIN contact c
                ON ca.id_contact_address = c.id_contact
             WHERE c.id_contact_entity = l_patient.id_person
               AND ca.flg_main_address = g_yes;
        
            g_error := 'pk_adt.get_inail_info pat_ca: ' || l_contact_address.id_contact_address;
        
            pk_alertlog.log_debug(g_error);
        EXCEPTION
            WHEN no_data_found THEN
                RAISE l_invalid_inail_exception;
        END;
    
        --Validate patient main info
        IF l_patient.first_name IS NULL
           OR l_patient.last_name IS NULL
           OR l_patient.gender IS NULL
           OR l_patient.dt_birth IS NULL
           OR l_pat_soc_attributes.id_country_address IS NULL
           OR l_pat_soc_attributes.num_contrib IS NULL
        THEN
            RAISE l_invalid_inail_exception;
        END IF;
    
        --Place of birth is only validated for institution country
        IF l_pat_soc_attributes.id_country_address = l_country_inst
           AND l_patient.id_place_of_birth IS NULL
        THEN
            RAISE l_invalid_inail_exception;
        END IF;
    
        --Validate patient address info
        IF l_contact_address.id_country IS NULL
           OR l_contact_address.address_line1 IS NULL
        THEN
            RAISE l_invalid_inail_exception;
        END IF;
    
        --Regional classifier and postal code are only validated for institution country        
        IF l_contact_address.id_country = l_country_inst
        THEN
            IF l_contact_address.id_rb_regional_classifier IS NULL
               OR l_contact_address.postal_code IS NULL
            THEN
                RAISE l_invalid_inail_exception;
            END IF;
        END IF;
    
        --Validate inail info
        IF l_pat_cit.flg_cit_type IS NULL
           OR l_pat_cit.flg_prognosis_type IS NULL
          --Ninguno prognosi can have empty dates
           OR (l_pat_cit.flg_prognosis_type <> c_no_prognosis AND
           (l_pat_cit.dt_start_period_tstz IS NULL OR l_pat_cit.dt_end_period_tstz IS NULL))
           OR l_pat_cit.accident_cause IS NULL
           OR l_pat_cit.dt_event_tstz IS NULL
           OR l_pat_cit.flg_accident_type IS NULL
           OR l_pat_cit.flg_permanent_disability IS NULL
           OR l_pat_cit.dt_stop_work_tstz IS NULL
           OR l_pat_cit.flg_life_danger IS NULL
           OR l_pat_cit.id_county_accident IS NULL
        THEN
        
            RAISE l_invalid_inail_exception;
        END IF;
    
        --Validate employer address info
        IF l_employer.name IS NULL
           OR l_employer.id_business_sector IS NULL
           OR l_emp_cont_address.id_country IS NULL
           OR l_emp_cont_address.address_line1 IS NULL
        THEN
        
            RAISE l_invalid_inail_exception;
        END IF;
    
        IF l_emp_cont_address.id_country = l_country_inst
        THEN
            --Regional classifier and postal code are only validated for institution country
            IF l_emp_cont_address.id_rb_regional_classifier IS NULL
               OR l_emp_cont_address.postal_code IS NULL
            THEN
                RAISE l_invalid_inail_exception;
            END IF;
        END IF;
    
        --If everything is ok than inail is validated
        o_inail_info := c_flg_inail_ok;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_inail_info := c_flg_no_inail;
        
            RETURN TRUE;
        WHEN l_invalid_inail_exception THEN
            o_inail_info := c_flg_inail_incomplete;
        
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_inail_info',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END get_inail_info;

    --read spec for full comments
    FUNCTION get_pat_exemptions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_current_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_exemptions   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_current_date TIMESTAMP WITH LOCAL TIME ZONE := nvl(i_current_date, current_timestamp);
        c_myfunction CONSTANT VARCHAR2(100) := 'PK_ADT.GET_PAT_EXEMPTIONS';
        c_valid_exemptions VARCHAR2(1 CHAR) := pk_sysconfig.get_config('ADT_VALID_EXEMPTIONS_WITH_NO_DATES', i_prof);
    BEGIN
    
        g_error := 'CALL ' || c_myfunction || ' FOR i_id_patient = ' || i_id_patient || ', ' ||
                   to_char(l_current_date, pk_alert_constant.g_dt_yyyymmddhh24miss);
        pk_alertlog.log_debug(g_error);
    
        --get all valid exemptions for the patient
        --exemptions with no effective_date and no expiration_date are considered not valid
        OPEN o_exemptions FOR
            SELECT pi.id_pat_isencao,
                   pk_translation.get_translation(i_lang, 'ISENCAO.CODE_ISENCAO.' || pi.id_isencao) desc_isencao
              FROM pat_isencao pi
             WHERE pi.id_patient = i_id_patient
               AND pi.record_status != pk_alert_constant.g_inactive
               AND (pi.flg_notif_status = c_notified_exemption OR
                   (pi.flg_notif_status = c_active_exemption AND
                   nvl(pi.expiration_date, l_current_date + 1) >= l_current_date AND
                   l_current_date >= nvl(pi.effective_date, l_current_date - 1) AND
                   (c_valid_exemptions = 'Y' OR (pi.effective_date IS NOT NULL OR pi.expiration_date IS NOT NULL))))
             ORDER BY desc_isencao;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              o_error);
            RETURN FALSE;
    END get_pat_exemptions;

    --read spec for full comments
    FUNCTION get_pat_exemption_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_isencao IN pat_isencao.id_pat_isencao%TYPE
    ) RETURN VARCHAR2 IS
        c_myfunction CONSTANT VARCHAR2(100) := 'PK_ADT.GET_PAT_EXEMPTION_DETAIL';
        l_desc  VARCHAR2(1000 CHAR);
        l_error t_error_out;
    BEGIN
    
        g_error := 'CALL ' || c_myfunction || ' FOR i_id_pat_isencao = ' || i_id_pat_isencao;
        pk_alertlog.log_debug(g_error);
    
        SELECT pk_translation.get_translation(i_lang, 'ISENCAO.CODE_ISENCAO.' || pi.id_isencao)
          INTO l_desc
          FROM pat_isencao pi
         WHERE pi.id_pat_isencao = i_id_pat_isencao;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              l_error);
            RETURN NULL;
    END get_pat_exemption_detail;

    --read spec for full comments
    FUNCTION get_flg_financial_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN patient.flg_financial_type%TYPE IS
        c_myfunction CONSTANT VARCHAR2(100) := 'PK_ADT.GET_FLG_FINANCIAL_TYPE';
        l_financial_type patient.flg_financial_type%TYPE := NULL;
        l_error          t_error_out;
    BEGIN
    
        g_error := 'CALL ' || c_myfunction || ' FOR i_id_patient = ' || i_id_patient;
        pk_alertlog.log_debug(g_error);
    
        --Get patient s tax_number for that id_patient in id_institution
        SELECT p.flg_financial_type
          INTO l_financial_type
          FROM patient p
         WHERE p.id_patient = i_id_patient;
    
        RETURN l_financial_type;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              l_error);
        
            RETURN NULL;
    END get_flg_financial_type;

    --read spec for full comments
    FUNCTION get_identification_doc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_doc      doc_external.num_doc%TYPE;
        l_doc_type PLS_INTEGER := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_DOC_TYPE_IDENTIFIER', i_prof);
        l_error    t_error_out;
    BEGIN
    
        SELECT num_doc
          INTO l_doc
          FROM doc_external de
         WHERE de.id_patient = i_id_patient
           AND de.flg_status = pk_alert_constant.g_active
           AND de.id_doc_type = l_doc_type
           AND rownum = 1;
    
        RETURN l_doc;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_IDENTIFIER',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_identification_doc;

    /********************************************************************************************
    * Function to map ADT parameters with external system values
    *
    * @param i_id_market                      market id
    * @param i_value_type                     type of value to be mapped
    * @param i_original_value                 value for ADT
    * @param i_condition                      condition to map value   
    *
    * @return                                 external system value
    *
    * @author                                 Bruno Martins
    * @version                                2.6.4
    * @since                                  2014-05-16
    ********************************************************************************************/
    FUNCTION map_value
    (
        i_id_market      IN market.id_market%TYPE,
        i_value_type     IN VARCHAR2,
        i_original_value IN VARCHAR2,
        i_condition      IN VARCHAR2 DEFAULT '*'
    ) RETURN VARCHAR2 IS
        l_return adt_map_values.mapped_value%TYPE;
    BEGIN
        SELECT a.mapped_value
          INTO l_return
          FROM adt_map_values a
         WHERE a.id_market = i_id_market
           AND a.value_type = i_value_type
           AND a.original_value = i_original_value
           AND a.value_condition = nvl(i_condition, '*');
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END map_value;

    --See spec for full comments
    FUNCTION get_pat_info_report_kw
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        o_name                   OUT patient.name%TYPE,
        o_gender                 OUT patient.gender%TYPE,
        o_desc_gender            OUT VARCHAR2,
        o_dt_birth               OUT VARCHAR2,
        o_place_of_residence_cod OUT VARCHAR2,
        o_nacionality_cod        OUT VARCHAR2,
        o_occupation_cod         OUT VARCHAR2,
        o_marital_status_cod     OUT VARCHAR2,
        o_origin_cod             OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat IS
            SELECT p.name,
                   p.gender,
                   pk_sysdomain.get_domain('PATIENT.GENDER', p.gender, i_lang) desc_gender,
                   pk_date_utils.date_send_tsz(i_lang, p.dt_birth, i_prof) dt_birth,
                   p.id_person
              FROM patient p
             WHERE p.id_patient = i_id_patient;
    
        CURSOR c_pat_soc_att IS
            SELECT psa.id_country_nation, psa.marital_status
              FROM pat_soc_attributes psa
             WHERE psa.id_patient = i_id_patient
               AND psa.id_institution = i_prof.institution;
    
        CURSOR c_origin_admission IS
            SELECT a.id_origin
              FROM admission_adt a
              JOIN episode_adt e
                ON a.id_episode_adt = e.id_episode_adt
             WHERE e.id_episode = i_id_episode;
    
        CURSOR c_pat_job IS
            SELECT pj.id_occupation
              FROM pat_job pj
             WHERE pj.id_patient = i_id_patient;
    
        CURSOR c_address(in_person IN NUMBER) IS
            SELECT ca.id_rb_regional_classifier
              FROM contact_address ca
              JOIN contact c
                ON ca.id_contact_address = c.id_contact
             WHERE c.id_contact_entity = in_person
               AND ca.flg_main_address = g_yes;
    
        l_id_country_nation NUMBER;
        l_id_origin         NUMBER;
        l_marital_status    VARCHAR(2 CHAR);
        l_id_occupation     NUMBER;
        l_id_rb_regional    NUMBER;
        l_id_person         NUMBER;
    
    BEGIN
        g_error := 'GET_PAT_INFO_REPORT_KW - GET PAT_SOC_ATT INFO - PAT:' || i_id_patient || ' PROF: ' || i_prof.id ||
                   ' INST:' || i_prof.institution || ' EPIS:' || i_id_episode;
        pk_alertlog.log_debug(g_error);
    
        --Get patient s main info
        OPEN c_pat;
        FETCH c_pat
            INTO o_name, o_gender, o_desc_gender, o_dt_birth, l_id_person;
        CLOSE c_pat;
    
        g_error := 'GET_PAT_INFO_REPORT_KW - GET PAT_SOC_ATT INFO - PAT:' || i_id_patient || ' INST:' ||
                   i_prof.institution;
        pk_alertlog.log_debug(g_error);
    
        --Find patient demographic information at the current institution
        OPEN c_pat_soc_att;
        FETCH c_pat_soc_att
            INTO l_id_country_nation, l_marital_status;
        CLOSE c_pat_soc_att;
    
        --Map nationality with external system value
        o_nacionality_cod := map_value(i_id_market      => g_kw_market,
                                       i_value_type     => 'NATIONALITY',
                                       i_original_value => l_id_country_nation);
    
        --Map marital status with external system value
        o_marital_status_cod := map_value(i_id_market      => g_kw_market,
                                          i_value_type     => 'MARITAL_STATUS',
                                          i_original_value => l_marital_status);
    
        --Get origin info from ADT
        OPEN c_origin_admission;
        FETCH c_origin_admission
            INTO l_id_origin;
        CLOSE c_origin_admission;
    
        --Map origin with external system value
        o_origin_cod := map_value(i_id_market => g_kw_market, i_value_type => 'ORIGIN', i_original_value => l_id_origin);
    
        --Get occupation info
        OPEN c_pat_job;
        FETCH c_pat_job
            INTO l_id_occupation;
        CLOSE c_pat_job;
    
        --Map occupation with external system value
        o_occupation_cod := map_value(i_id_market      => g_kw_market,
                                      i_value_type     => 'OCCUPATION',
                                      i_original_value => l_id_occupation);
    
        --Get place of residence
        OPEN c_address(l_id_person);
        FETCH c_address
            INTO l_id_rb_regional;
        CLOSE c_address;
    
        --Map place of residence with external system value
        o_place_of_residence_cod := map_value(i_id_market      => g_kw_market,
                                              i_value_type     => 'PLACE_OF_RESIDENCE',
                                              i_original_value => l_id_rb_regional);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_INFO_REPORT_KW',
                                              o_error);
            RETURN FALSE;
    END get_pat_info_report_kw;

    --See spec for full comments
    FUNCTION concat_other_names
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        name1           IN patient.other_names_1%TYPE,
        name2           IN patient.other_names_2%TYPE,
        name3           IN patient.other_names_3%TYPE,
        name4           IN patient.other_names_4%TYPE,
        include_sep     IN BOOLEAN DEFAULT TRUE,
        i_id_sys_config IN sys_config.id_sys_config%TYPE DEFAULT 'PATIENT_NAME_PATTERN'
    ) RETURN VARCHAR2 IS
    
        l_config VARCHAR2(20) := pk_sysconfig.get_config(i_id_sys_config, i_prof);
    
        l_complete_names VARCHAR2(1000 CHAR) := '';
    
        l_error t_error_out;
    
    BEGIN
    
        IF l_config IS NULL
        THEN
            pk_alertlog.log_warn('No PATIENT_NAME_PATTERN config for p:' || i_prof.id || ' i:' || i_prof.institution ||
                                 ' s:' || i_prof.software);
            l_config := 'F M L';
        END IF;
    
        IF NOT pk_adt.build_name(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_config      => l_config,
                                 i_first_name  => name1,
                                 i_second_name => name2,
                                 i_midlle_name => name3,
                                 i_last_name   => name4,
                                 o_pat_name    => l_complete_names,
                                 o_error       => l_error)
        THEN
            NULL;
        END IF;
    
        IF TRIM(l_complete_names) IS NOT NULL
        THEN
            IF include_sep
            THEN
                l_complete_names := ' / ' || TRIM(l_complete_names);
            END IF;
        END IF;
    
        RETURN l_complete_names;
    END concat_other_names;

    --See spec for full comments
    FUNCTION has_other_names(i_patient IN patient.id_patient%TYPE) RETURN VARCHAR2 IS
        l_count PLS_INTEGER;
        l_ret   VARCHAR2(1 CHAR);
    BEGIN
        --Get patient record if other_mames_1/2/3 is filled
        SELECT COUNT(1)
          INTO l_count
          FROM patient p
         WHERE p.id_patient = i_patient
           AND coalesce(p.other_names_1, p.other_names_2, p.other_names_3) IS NOT NULL;
    
        --Return true if other_mames_1/2/3 is filled, false otherwise
        IF l_count > 0
        THEN
            l_ret := pk_alert_constant.g_yes;
        ELSE
            l_ret := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_ret;
    END has_other_names;

    --See spec for full comments
    FUNCTION get_other_names(i_patient IN patient.id_patient%TYPE) RETURN VARCHAR2 IS
    
        l_other_names_1 patient.other_names_1%TYPE;
        l_other_names_2 patient.other_names_2%TYPE;
        l_other_names_3 patient.other_names_3%TYPE;
        l_other_names_4 patient.other_names_4%TYPE;
    BEGIN
    
        --IF has_other_names(i_patient => i_patient) = pk_alert_constant.g_yes
        --THEN
        SELECT p.other_names_1, p.other_names_2, p.other_names_3, p.other_names_4
          INTO l_other_names_1, l_other_names_2, l_other_names_3, l_other_names_4
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        RETURN concat_other_names(NULL,
                                  profissional(0, 0, 0),
                                  l_other_names_1,
                                  l_other_names_4,
                                  l_other_names_2,
                                  l_other_names_3,
                                  FALSE);
    END get_other_names;

    --see spec for full comments
    FUNCTION get_ticket_number
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode_adt.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
        l_internal_error EXCEPTION;
        l_ticket_number admission_adt.ticket_number%TYPE;
    BEGIN
    
        g_error := 'CALL TO GET_TICKET_NUMBER USING EPIS:' || i_id_episode;
        pk_alertlog.log_debug(g_error);
    
        SELECT a.ticket_number
          INTO l_ticket_number
          FROM admission_adt a
          JOIN episode_adt e
            ON e.id_episode_adt = a.id_episode_adt
         WHERE e.id_episode = i_id_episode;
    
        RETURN l_ticket_number;
    
    EXCEPTION
        WHEN no_data_found THEN
            --no admission made, its ok
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TICKET_NUMBER',
                                              l_error);
            RETURN NULL;
    END get_ticket_number;

    --See spec for full comments
    FUNCTION call_cancel_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_cancel_reason  IN episode.desc_cancel_reason%TYPE,
        i_cancel_type    IN VARCHAR2 DEFAULT 'E',
        i_dt_cancel      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_visit.call_cancel_episode(i_lang           => i_lang,
                                            i_id_episode     => i_id_episode,
                                            i_prof           => i_prof,
                                            i_cancel_reason  => i_cancel_reason,
                                            i_cancel_type    => i_cancel_type,
                                            i_dt_cancel      => nvl(i_dt_cancel, current_timestamp),
                                            i_transaction_id => i_transaction_id,
                                            o_error          => o_error);
    END call_cancel_episode;

    FUNCTION get_ges_print_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_flg_show_popup OUT VARCHAR2,
        o_options        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name    VARCHAR2(32) := 'GET_GES_PRINT_LIST';
        l_default_save sys_config.value%TYPE := pk_sysconfig.get_config('GES_DEFAULT_COMPLETION_OPTION_SAVE', i_prof);
    
        l_can_add     VARCHAR2(10 CHAR);
        l_save_option sys_list.internal_name%TYPE;
    
    BEGIN
    
        --Test if professional can add items to printing list
        g_error := 'CALL PK_PRINT_LIST_DB.CHECK_FUNC_CAN_ADD';
        IF NOT pk_print_list_db.check_func_can_add(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   o_flg_can_add => l_can_add,
                                                   o_error       => o_error)
        THEN
            RAISE g_adtexception;
        END IF;
    
        --get flg to know if popup must be shown
        o_flg_show_popup := nvl(pk_sysconfig.get_config('SHOW_CONCLUSION_POPUP_GES', i_prof), g_yes);
    
        --gets printing list configurations
        IF l_default_save = g_no
        THEN
            g_error := 'CALL PK_PRINT_LIST_DB.GET_PRINT_LIST_DEF_OPTION';
            IF NOT pk_print_list_db.get_print_list_def_option(i_lang            => i_lang,
                                                              i_prof            => i_prof,
                                                              i_print_list_area => pk_print_list_db.g_print_list_area_ges,
                                                              o_default_option  => l_save_option,
                                                              o_error           => o_error)
            THEN
                RAISE g_adtexception;
            END IF;
        ELSE
            l_save_option := 'SAVE';
        END IF;
    
        --get options for printing list
        g_error := 'OPEN O_OPTIONS';
        OPEN o_options FOR
            SELECT tbl_opt.flg_context val_option,
                   tbl_opt.desc_list desc_option,
                   decode(tbl_opt.sys_list_internal_name,
                          'SAVE',
                          NULL,
                          pk_print_tool.get_id_report(i_lang, i_prof, 'PL', 'DiagnosisCreateForm.swf')) id_report,
                   decode(tbl_opt.sys_list_internal_name, l_save_option, g_yes, g_no) flg_default,
                   tbl_opt.rank rank,
                   decode(tbl_opt.sys_list_internal_name,
                          'SAVE_PRINT_LIST',
                          decode(l_can_add, g_yes, g_yes, g_no),
                          g_yes) flg_available
              FROM TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, 'GES_COMPLETION_OPTIONS')) tbl_opt;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_ges_print_list;

    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job IS
        l_result                t_rec_print_list_job := t_rec_print_list_job();
        l_context_data          print_list_job.context_data%TYPE;
        l_curr_area             print_list_job.id_print_list_area%TYPE;
        l_id_report             reports.id_reports%TYPE;
        l_context_data_elements table_varchar := table_varchar();
        l_delim                 VARCHAR2(1 CHAR) := '|';
        l_id_isencao            isencao.id_isencao%TYPE;
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'TF_GET_PRINT_JOB_INFO';
        l_error t_error_out;
    BEGIN
        --log input parameters
        g_error := 'GETTING CONTEXT DATA AND AREA OF THIS PRINT LIST JOB ' || i_id_print_list_job || ' PROF:' ||
                   i_prof.id || ' INST:' || i_prof.institution;
        BEGIN
            SELECT v.context_data, v.id_print_list_area
              INTO l_context_data, l_curr_area
              FROM v_print_list_context_data v
             WHERE v.id_print_list_job = i_id_print_list_job;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_context_data := '-1';
        END;
    
        --verify context
        g_error := 'VERIFY IF ID CONTEXT IS VALID';
        IF l_context_data <> '-1'
           AND l_curr_area = pk_print_list_db.g_print_list_area_ges
        THEN
            l_context_data_elements := pk_utils.str_split_l(i_list => l_context_data, i_delim => l_delim);
        
            -- get context_data elements (id_report|id_isencao)
            IF l_context_data_elements.count = 2
            THEN
                l_id_report  := CAST(l_context_data_elements(1) AS NUMBER);
                l_id_isencao := CAST(l_context_data_elements(2) AS NUMBER);
            ELSE
                -- the context data has indetermined element components (should be 1: "id_report|id_isencao")
                RETURN t_rec_print_list_job();
            END IF;
        
            --Get Report and Isencao translation
            g_error := 'GETTING REPORT TRANSLATION';
            SELECT pk_translation.get_translation(i_lang      => i_lang,
                                                  i_code_mess => 'REPORTS.CODE_REPORTS.' || l_id_report),
                   pk_translation.get_translation(i_lang      => i_lang,
                                                  i_code_mess => 'ISENCAO.CODE_ISENCAO.' || l_id_isencao)
              INTO l_result.title_desc, l_result.subtitle_desc
              FROM dual;
        
            l_result.id_print_list_job  := i_id_print_list_job;
            l_result.id_print_list_area := l_curr_area;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END tf_get_print_job_info;

    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_tbl_print_list_jobs    IN table_number
    ) RETURN table_number IS
        l_result table_number := table_number();
        l_func_name CONSTANT VARCHAR2(200) := 'TF_COMPARE_PRINT_JOBS';
        l_error t_error_out;
    BEGIN
    
        g_error := 'GETTING SIMMILAR PRINTING LIST JOBS | PRINT_JOB_CONTEXT_DATA - ' || i_print_job_context_data ||
                   ' PROF:' || i_prof.id || ' INST:' || i_prof.institution;
    
        SELECT t.id_print_list_job
          BULK COLLECT
          INTO l_result
          FROM (SELECT /*+opt_estimate (table t rows=1)*/
                 v2.id_print_list_job
                  FROM v_print_list_context_data v2
                  JOIN TABLE(CAST(i_tbl_print_list_jobs AS table_number)) t
                    ON t.column_value = v2.id_print_list_job
                 WHERE dbms_lob.compare(v2.context_data, i_print_job_context_data) = 0) t;
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END tf_compare_print_jobs;

    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_exemptions   IN table_number,
        i_id_reports      IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'add_print_list_jobs';
        l_params           VARCHAR2(1000 CHAR);
        l_context_data     table_clob;
        l_print_list_areas table_number;
        l_delim            VARCHAR2(1 CHAR) := '|';
    BEGIN
        -- Log input params
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_episode=' || i_episode ||
                    ' i_id_refs=' || pk_utils.to_string(i_id_exemptions);
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        l_context_data     := table_clob();
        l_print_list_areas := table_number();
    
        -- Validate parameters
        IF i_id_exemptions.count = 0
           OR i_id_exemptions.count != i_print_arguments.count
           OR i_id_exemptions.count != i_id_reports.count
           OR i_patient IS NULL
           OR i_episode IS NULL
        THEN
            g_error := 'Invalid parameters / ' || l_params;
            RAISE g_adtexception;
        END IF;
    
        -- Create parameters to pk_print_list_db.add_print_jobs
        l_context_data.extend(i_id_exemptions.count);
        l_print_list_areas.extend(i_id_exemptions.count);
        FOR i IN 1 .. i_id_exemptions.count
        LOOP
            l_context_data(i) := to_clob(i_id_reports(i) || l_delim || i_id_exemptions(i));
            l_print_list_areas(i) := pk_print_list_db.g_print_list_area_ges;
        END LOOP;
    
        -- call function to add job to the print list
        g_error := 'Call pk_print_list_db.add_print_jobs / ' || l_params;
        IF NOT pk_print_list_db.add_print_jobs(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_patient          => i_patient,
                                               i_episode          => i_episode,
                                               i_print_list_areas => l_print_list_areas,
                                               i_context_data     => l_context_data,
                                               i_print_arguments  => i_print_arguments,
                                               o_print_list_jobs  => o_print_list_job,
                                               o_error            => o_error)
        
        THEN
            RAISE g_adtexception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_adtexception THEN
            pk_alertlog.log_error(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END add_print_list_jobs;

    FUNCTION get_pat_exemption
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_isencao.id_patient%TYPE,
        i_id_isencao IN pat_isencao.id_isencao%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        c_myfunction CONSTANT VARCHAR2(100) := 'PK_ADT.GET_PAT_EXEMPTION';
        l_id_pat_isencao   pat_isencao.id_pat_isencao%TYPE;
        l_current_date     TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        c_valid_exemptions VARCHAR2(1 CHAR) := pk_sysconfig.get_config('ADT_VALID_EXEMPTIONS_WITH_NO_DATES', i_prof);
    BEGIN
    
        g_error := 'CALL ' || c_myfunction || ' FOR PAT:' || i_id_patient || ' ISN:' || i_id_isencao;
        pk_alertlog.log_debug(g_error);
    
        SELECT pi.id_pat_isencao
          INTO l_id_pat_isencao
          FROM pat_isencao pi
         WHERE pi.id_patient = i_id_patient
           AND pi.id_isencao = i_id_isencao
           AND ( --pi.flg_notif_status IN (c_notified_exemption, c_pend_notif_exemption) OR
                (pi.flg_notif_status = c_active_exemption AND
                nvl(pi.expiration_date, l_current_date + 1) >= l_current_date AND
                l_current_date >= nvl(pi.effective_date, l_current_date - 1) AND
                (c_valid_exemptions = 'Y' OR (pi.effective_date IS NOT NULL OR pi.expiration_date IS NOT NULL))));
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              o_error);
            RETURN FALSE;
    END get_pat_exemption;

    FUNCTION check_exemption_availability(i_id_isencao IN NUMBER) RETURN BOOLEAN IS
        tbl_return table_varchar;
        l_bool     BOOLEAN;
    BEGIN
    
        SELECT flg_available
          BULK COLLECT
          INTO tbl_return
          FROM isencao
         WHERE id_isencao = i_id_isencao;
    
        l_bool := FALSE;
        IF tbl_return.count > 0
        THEN
            l_bool := (tbl_return(1) = g_yes);
        END IF;
    
        RETURN l_bool;
    
    END check_exemption_availability;

    FUNCTION get_nationality
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_return translation.desc_lang_1%TYPE;
    BEGIN
        SELECT pk_translation.get_translation(i_lang, c.code_nationality) nationality
          INTO l_return
          FROM (SELECT row_number() over(ORDER BY --
                       /*case 
                       when psa.id_institution = i_prof.INSTITUTION
                       then 0 
                       when psa.id_institution = pk_alert_constant.g_inst_all
                       then 1     
                       else 2 
                       end asc*/ -- this type of case has problem with PL/SQL Developer Beautify, sunstituted by decode below
                        decode(psa.id_institution, i_prof.institution, 0, pk_alert_constant.g_inst_all, 1, 2) ASC) rn,
                       psa.id_country_nation
                  FROM pat_soc_attributes psa
                 WHERE psa.id_patient = i_id_patient
                   AND psa.id_institution IN
                       (SELECT /*+opt_estimate (table t rows=1)*/
                         column_value
                          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt)) t
                        UNION ALL
                        SELECT pk_alert_constant.g_inst_all column_value
                          FROM dual)) aux
          JOIN country c
            ON c.id_country = aux.id_country_nation
         WHERE aux.rn = 1;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_nationality;

    FUNCTION get_regional_classifier_desc
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_rb_regional_classifier IN alert_adtcod_cfg.rb_regional_classifier.id_rb_regional_classifier%TYPE
    ) RETURN VARCHAR2 IS
        l_description VARCHAR2(2000);
    BEGIN
        SELECT pk_translation.get_translation(i_lang, r.code_rb_regional_classifier) ||
               nvl2(r.reg_classifier_abbreviation, ' (' || r.reg_classifier_abbreviation || ')', '')
          INTO l_description
          FROM rb_regional_classifier r
         WHERE r.id_rb_regional_classifier = i_id_rb_regional_classifier;
        RETURN l_description;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_regional_classifier_desc;

    FUNCTION get_settlement_type_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_settlement_type IN alert_adtcod_cfg.settlement_type_mx.id_type_settlement%TYPE
    ) RETURN VARCHAR2 IS
        l_description VARCHAR2(2000);
    BEGIN
        SELECT st.desc_type_settlement
          INTO l_description
          FROM alert_adtcod_cfg.settlement_type_mx st
         WHERE st.id_type_settlement = i_id_settlement_type;
        RETURN l_description;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_settlement_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_settlement      IN alert_adtcod_cfg.settlement_mx.id_settlement%TYPE,
        i_id_settlement_type IN alert_adtcod_cfg.settlement_mx.id_type_settlement%TYPE
    ) RETURN VARCHAR2 IS
        l_description VARCHAR2(2000);
    BEGIN
        SELECT sm.desc_settlement
          INTO l_description
          FROM alert_adtcod_cfg.settlement_mx sm
         WHERE sm.id_settlement = i_id_settlement
           AND sm.id_type_settlement = i_id_settlement_type;
        RETURN l_description;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /********************************************************************************************
    * Function that returns settlement code
    *
    * @param i_id_settlement_type     id settlement type ID 
    
    *
    * @return                         CODE of the settlement
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.3.1
    * @since                          04/04/2018
    **********************************************************************************************/
    FUNCTION get_settlement_code
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_settlement_type IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_adt_core.get_settlement_code(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_id_settlement_type => i_id_settlement_type);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_settlement_code;
    /********************************************************************************************
    * Function that returns the classifier_code of a regional_classifier
    *
    * @param i_rb_reg_class           id_rb_regional_classifier ID
    * @param i_rank                   RANK for parent pruposes (if null is the ID in self)
    *
    * @return                         CODE of the regional classifier
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          19/01/2017
    **********************************************************************************************/

    FUNCTION get_rb_reg_classifier_code
    (
        i_rb_reg_class IN rb_regional_classifier.id_rb_regional_classifier%TYPE,
        i_rank         IN NUMBER DEFAULT NULL
    ) RETURN rb_regional_classifier.reg_classifier_code%TYPE IS
    
    BEGIN
        RETURN pk_adt_core.get_rb_reg_classifier_code(i_rb_reg_class => i_rb_reg_class,
                                                      i_rank         => i_rank,
                                                      i_mode         => pk_adt_core.k_rb_code);
    
    END get_rb_reg_classifier_code;

    FUNCTION get_rb_reg_classifier_id
    (
        i_rb_reg_class IN rb_regional_classifier.id_rb_regional_classifier%TYPE,
        i_rank         IN NUMBER DEFAULT NULL
    ) RETURN rb_regional_classifier.id_rb_regional_classifier%TYPE IS
    
    BEGIN
        RETURN to_number(pk_adt_core.get_rb_reg_classifier_code(i_rb_reg_class => i_rb_reg_class,
                                                                i_rank         => i_rank,
                                                                i_mode         => pk_adt_core.k_rb_id));
    
    END get_rb_reg_classifier_id;

    /********************************************************************************************
    * Function that returns the id_rb_regional_classifier
    *
    * @param i_person           PERSON ID
    *
    * @return                         id_rb_regional_classifier
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          19/01/2017
    **********************************************************************************************/

    FUNCTION get_patient_address_id(i_person IN person.id_person%TYPE)
        RETURN contact_address.id_rb_regional_classifier%TYPE IS
        l_id_rb_regional_classifier contact_address.id_rb_regional_classifier%TYPE;
    BEGIN
        SELECT id_rb_regional_classifier
          INTO l_id_rb_regional_classifier
          FROM (SELECT ca.id_rb_regional_classifier
                  FROM contact c
                  JOIN contact_address ca
                    ON c.id_contact = ca.id_contact_address
                 WHERE c.id_contact_entity = i_person
                      --AND c.id_contact_description = c_preferred_contact_desc
                   AND ca.flg_main_address = 'Y'
                 ORDER BY contact_priority ASC)
         WHERE rownum = 1;
        RETURN l_id_rb_regional_classifier;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_patient_address_id;

    /********************************************************************************************
    * Function that returns the ilocalation of the mai address
    *
    * @param i_person           PERSON ID
    *
    * @return                         id_rb_regional_classifier
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          20/01/2017
    **********************************************************************************************/

    FUNCTION get_patient_address_colony(i_person IN person.id_person%TYPE) RETURN contact_address.location%TYPE IS
        l_location contact_address.location%TYPE;
    BEGIN
        SELECT location
          INTO l_location
          FROM (SELECT ca.location
                  FROM contact c
                  JOIN contact_address ca
                    ON c.id_contact = ca.id_contact_address
                 WHERE c.id_contact_entity = i_person
                      --AND c.id_contact_description = c_preferred_contact_desc
                   AND ca.flg_main_address = 'Y'
                 ORDER BY contact_priority ASC)
         WHERE rownum = 1;
        RETURN l_location;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_patient_address_colony;

    FUNCTION get_patient_address_colony
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_person IN person.id_person%TYPE
    ) RETURN contact_address.location%TYPE IS
        l_location contact_address.location%TYPE;
        CURSOR c_adress IS
            SELECT address_option, id_settlement_type, desc_settlement
              FROM (SELECT address_option, camx.id_settlement_type, camx.desc_settlement
                      FROM contact c
                      JOIN contact_address ca
                        ON c.id_contact = ca.id_contact_address
                      JOIN alert_adtcod.contact_address_mx camx
                        ON camx.id_contact_address_mx = ca.id_contact_address
                     WHERE c.id_contact_entity = i_person
                       AND ca.flg_main_address = 'Y'
                     ORDER BY contact_priority ASC)
             WHERE rownum = 1;
        r_address c_adress%ROWTYPE;
    
    BEGIN
        OPEN c_adress;
        FETCH c_adress
            INTO r_address;
        CLOSE c_adress;
    
        CASE r_address.address_option
            WHEN '999' THEN
                l_location := get_settlement_type_desc(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_id_settlement_type => r_address.id_settlement_type) || ' ' ||
                              r_address.desc_settlement;
            
            ELSE
                l_location := upper(get_settlement_type_desc(i_lang               => i_lang,
                                                             i_prof               => i_prof,
                                                             i_id_settlement_type => r_address.id_settlement_type));
        END CASE;
    
        RETURN l_location;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_patient_address_colony;

    /********************************************************************************************
    * This function returns institution clues code
    *
    * @param i_id_clues       CLUES ID
    *
    * @return                 code
    *
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.0
    * @since                  20/01/2017
    **********************************************************************************************/
    FUNCTION get_clues_code
    (
        i_id_clues       IN NUMBER,
        i_id_institution IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_col      t_coll_clues_inst_mx;
        l_id_clues NUMBER;
    
    BEGIN
        IF i_id_clues IS NULL
        THEN
            l_id_clues := get_clues_inst(i_lang           => NULL,
                                         i_prof           => profissional(NULL, NULL, NULL),
                                         i_id_institution => i_id_institution);
        ELSE
            l_id_clues := i_id_clues;
        END IF;
        l_col := pk_adt_core.get_clues_inst_mx(i_lang     => NULL,
                                               i_prof     => profissional(NULL, NULL, NULL),
                                               i_id_clues => l_id_clues);
    
        IF l_col.count > 0
        THEN
            RETURN l_col(1).code_clues;
        END IF;
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_clues_code;

    /********************************************************************************************
    * This function returns institution clues name
    *
    * @param i_id_clues       CLUES ID
    *
    * @return                 code
    *
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.0
    * @since                  20/01/2017
    **********************************************************************************************/
    FUNCTION get_clues_name
    (
        i_id_clues       IN NUMBER,
        i_id_institution IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_col      t_coll_clues_inst_mx;
        l_id_clues NUMBER;
    BEGIN
    
        IF i_id_clues IS NULL
        THEN
            l_id_clues := get_clues_inst(i_lang           => NULL,
                                         i_prof           => profissional(NULL, NULL, NULL),
                                         i_id_institution => i_id_institution);
        ELSE
            l_id_clues := i_id_clues;
        END IF;
        l_col := pk_adt_core.get_clues_inst_mx(i_lang     => NULL,
                                               i_prof     => profissional(NULL, NULL, NULL),
                                               i_id_clues => l_id_clues);
    
        IF l_col.count > 0
        THEN
            RETURN l_col(1).unity_name;
        END IF;
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_clues_name;

    /********************************************************************************************
    * This function returns institution unity_status
    *
    * @param i_id_clues       CLUES ID
    *
    * @return                 code
    *
    *
    * @author                 Carlos Ferreira
    * @version                2.7.0
    * @since                  24/01/2017
    **********************************************************************************************/
    FUNCTION get_clues_unity_status
    (
        i_id_clues       IN NUMBER,
        i_id_institution IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_col          t_coll_clues_inst_mx;
        l_id_clues     NUMBER;
        l_unity_status VARCHAR2(1000 CHAR);
    BEGIN
    
        IF i_id_clues IS NULL
        THEN
            l_id_clues := get_clues_inst(i_lang           => NULL,
                                         i_prof           => profissional(NULL, NULL, NULL),
                                         i_id_institution => i_id_institution);
        ELSE
            l_id_clues := i_id_clues;
        END IF;
    
        l_col := pk_adt_core.get_clues_inst_mx(i_lang     => NULL,
                                               i_prof     => profissional(NULL, NULL, NULL),
                                               i_id_clues => l_id_clues);
    
        IF l_col.count > 0
        THEN
            l_unity_status := l_col(1).unity_status;
        END IF;
    
        RETURN l_unity_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_clues_unity_status;

    /********************************************************************************************
    * This function returns information  id clues of an institution
    *
    * @param i_lang           LANG ID
    * @param i_prof           PROFESSIONAL ID
    * @param i_id_institution INSTITUTION ID     
    *
    * @return                  CLUES ID
    *
    *
    * @author                  Elisabete Bugalho
    * @version                 2.7.0
    * @since                   23/01/2017
    **********************************************************************************************/

    FUNCTION get_clues_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN NUMBER
    ) RETURN NUMBER IS
        l_id_clues NUMBER;
    BEGIN
        SELECT id_clues
          INTO l_id_clues
          FROM institution
         WHERE id_institution = i_id_institution;
        RETURN l_id_clues;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_id_clues;
        
    END get_clues_inst;

    FUNCTION get_health_plan_field_mx
    (
        i_episode       IN NUMBER,
        i_flg_main      IN VARCHAR2,
        i_field_to_show IN VARCHAR2
    ) RETURN VARCHAR2 IS
        tbl_cnt               table_varchar;
        l_return              VARCHAR2(0200 CHAR);
        tbl_affiliation       table_varchar;
        tbl_affiliation_compl table_varchar;
        k_affiliation       CONSTANT VARCHAR2(0100 CHAR) := 'AFFILIATION_NUMBER';
        k_id_content        CONSTANT VARCHAR2(0100 CHAR) := 'ID_CONTENT';
        k_affiliation_compl CONSTANT VARCHAR2(0100 CHAR) := 'AFFILIATION_NUMBER_COMPL';
        l_index       NUMBER;
        l_patient     patient.id_patient%TYPE;
        l_institution institution.id_institution%TYPE;
    BEGIN
    
        SELECT id_patient, id_institution
          INTO l_patient, l_institution
          FROM episode
         WHERE id_episode = i_episode;
    
        SELECT hpe.id_content, php.affiliation_number, php.affiliation_number_compl
          BULK COLLECT
          INTO tbl_cnt, tbl_affiliation, tbl_affiliation_compl
          FROM pat_health_plan php
          JOIN health_plan hp
            ON php.id_health_plan = hp.id_health_plan
          JOIN health_plan_entity hpe
            ON hpe.id_health_plan_entity = hp.id_health_plan_entity
         WHERE php.flg_status != 'I'
           AND php.id_patient = l_patient
           AND php.institution_key = l_institution
         ORDER BY php.id_pat_health_plan;
    
        IF tbl_cnt.count > 0
        THEN
            IF i_flg_main = 'Y'
            THEN
                l_index := 1;
            ELSE
                l_index := 2;
            END IF;
        
            CASE i_field_to_show
                WHEN k_id_content THEN
                    l_return := tbl_cnt(l_index);
                WHEN k_affiliation THEN
                    l_return := tbl_affiliation(l_index);
                WHEN k_affiliation_compl THEN
                    l_return := tbl_affiliation_compl(l_index);
                ELSE
                    l_return := tbl_cnt(l_index);
            END CASE;
        
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_health_plan_field_mx;

    /********************************************************************************************
    * This function returns institution regional classifier
    *
    * @param i_id_clues       CLUES ID
    *
    * @return                 code
    *
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.0
    * @since                  20/01/2017
    **********************************************************************************************/
    FUNCTION get_clues_id_rb_regional
    (
        i_id_clues       IN NUMBER,
        i_id_institution IN NUMBER DEFAULT NULL
    ) RETURN NUMBER IS
        l_col      t_coll_clues_inst_mx;
        l_id_clues NUMBER;
    
    BEGIN
        IF i_id_clues IS NULL
        THEN
            l_id_clues := get_clues_inst(i_lang           => NULL,
                                         i_prof           => profissional(NULL, NULL, NULL),
                                         i_id_institution => i_id_institution);
        ELSE
            l_id_clues := i_id_clues;
        END IF;
        l_col := pk_adt_core.get_clues_inst_mx(i_lang     => NULL,
                                               i_prof     => profissional(NULL, NULL, NULL),
                                               i_id_clues => l_id_clues);
    
        IF l_col.count > 0
        THEN
            RETURN l_col(1).id_rb_regional_classifier;
        END IF;
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_clues_id_rb_regional;

    /********************************************************************************************
    * This function returns institution jurisdiction
    *
    * @param i_id_clues       CLUES ID
    *
    * @return                 code
    *
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.0
    * @since                  20/01/2017
    **********************************************************************************************/
    FUNCTION get_clues_jurisdiction
    (
        i_id_clues       IN NUMBER,
        i_id_institution IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_col      t_coll_clues_inst_mx;
        l_id_clues NUMBER;
    
    BEGIN
    
        IF i_id_clues IS NULL
        THEN
            l_id_clues := get_clues_inst(i_lang           => NULL,
                                         i_prof           => profissional(NULL, NULL, NULL),
                                         i_id_institution => i_id_institution);
        ELSE
            l_id_clues := i_id_clues;
        END IF;
        l_col := pk_adt_core.get_clues_inst_mx(i_lang     => NULL,
                                               i_prof     => profissional(NULL, NULL, NULL),
                                               i_id_clues => l_id_clues);
    
        IF l_col.count > 0
        THEN
            RETURN l_col(1).id_rb_reg_class_juris;
        END IF;
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_clues_jurisdiction;

    FUNCTION get_clues_field
    (
        i_id_clues       IN NUMBER,
        i_id_institution IN NUMBER DEFAULT NULL,
        i_field          IN VARCHAR2,
        i_mode           IN VARCHAR2 DEFAULT pk_adt_core.k_rb_code
    ) RETURN VARCHAR2 IS
        l_col      t_coll_clues_inst_mx;
        l_id_clues NUMBER;
    
        l_return VARCHAR2(4000 CHAR);
    
    BEGIN
        IF i_id_clues IS NULL
        THEN
            l_id_clues := get_clues_inst(i_lang           => NULL,
                                         i_prof           => profissional(NULL, NULL, NULL),
                                         i_id_institution => i_id_institution);
        ELSE
            l_id_clues := i_id_clues;
        END IF;
    
        l_col := pk_adt_core.get_clues_inst_mx(i_lang     => NULL,
                                               i_prof     => profissional(NULL, NULL, NULL),
                                               i_id_clues => l_id_clues);
    
        CASE i_field
            WHEN k_inst_name THEN
                l_return := l_col(1).unity_name;
            WHEN k_clues_inst_name THEN
                l_return := l_col(1).institution_name;
            WHEN k_inside_number THEN
                l_return := l_col(1).inside_number;
            WHEN k_outside_number THEN
                l_return := l_col(1).numero_exterior;
            WHEN k_code_state THEN
                IF i_mode = pk_adt_core.k_rb_code
                THEN
                    l_return := get_rb_reg_classifier_code(i_rb_reg_class => l_col(1).id_rb_regional_classifier,
                                                           i_rank         => 5);
                ELSE
                    l_return := get_rb_reg_classifier_id(i_rb_reg_class => l_col(1).id_rb_regional_classifier,
                                                         i_rank         => 5);
                END IF;
            WHEN k_code_municipality THEN
                l_return := get_rb_reg_classifier_code(i_rb_reg_class => l_col(1).id_rb_regional_classifier,
                                                       i_rank         => 10);
            WHEN k_code_city THEN
                l_return := get_rb_reg_classifier_code(i_rb_reg_class => l_col(1).id_rb_regional_classifier,
                                                       i_rank         => 15);
            WHEN k_postal_code THEN
                l_return := pk_adt_core.get_rb_reg_classif_postal_code(l_col(1).id_rb_reg_class_postal_code);
            WHEN k_phone THEN
                l_return := l_col(1).phone;
            WHEN k_residence THEN
                l_return := l_col(1).residence;
            WHEN k_urbanization THEN
                l_return := l_col(1).urbanization;
            WHEN k_id_tipology THEN
                l_return := l_col(1).id_typology;
            WHEN k_code_clues THEN
                l_return := l_col(1).code_clues;
            WHEN k_jurisdiction_id THEN
                l_return := l_col(1).id_jurisdiction;
            WHEN k_institution_short_code THEN
                l_return := l_col(1).short_code_institution;
            WHEN k_street_type THEN
                l_return := to_char(l_col(1).id_street_type, 'FM09');
            WHEN k_street THEN
                l_return := l_col(1).residence;
            WHEN k_code_settlement THEN
                l_return := pk_adt.get_settlement_code(i_lang               => NULL,
                                                       i_prof               => NULL,
                                                       i_id_settlement_type => l_col(1).id_type_settlement);
            ELSE
                l_return := NULL;
        END CASE;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_clues_field;

    /********************************************************************************************
    * This function returns id_content of given id_origin
    *
    * @param i_id_origin      origin identifier
    *
    * @return                 id_content
    *
    *
    * @author                 Carlos Ferreira
    * @version                2.7.1
    * @since                  2017-03
    **********************************************************************************************/
    FUNCTION get_origin_id_cnt(i_id_origin IN NUMBER) RETURN VARCHAR2 IS
        tbl_return table_varchar;
        l_return   VARCHAR2(4000);
    BEGIN
    
        SELECT id_content
          BULK COLLECT
          INTO tbl_return
          FROM origin a
         WHERE a.id_origin = i_id_origin;
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    
    END get_origin_id_cnt;
    /********************************************************************************************
    * This function returns ithe institution name for einpatient admission
    *
    * @param i_episode      id_episode on pfh
    *
    * @return                 institution name
    *
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.1
    * @since                  2017-05-18
    **********************************************************************************************/

    FUNCTION get_admission_institution
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_institution VARCHAR2(4000);
    BEGIN
        SELECT pk_translation.get_translation(i_lang, i.code_institution)
          INTO l_institution
          FROM admission_inpatient a
          JOIN institution i
            ON a.id_origin_institution = i.id_institution
         WHERE a.id_admission_inpatient IN
               (SELECT id_admission_adt
                  FROM admission_adt
                 WHERE id_episode_adt IN (SELECT id_episode_adt
                                            FROM episode_adt
                                           WHERE id_episode = i_episode));
        RETURN l_institution;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_admission_institution;
    /********************************************************************************************
    * This function returns The institution id for inpatient admission
    *
    * @param i_episode      id_episode on pfh
    *
    * @return                 institution name
    *
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.1
    * @since                  2017-10-18
    **********************************************************************************************/
    FUNCTION get_admission_institution_id(i_episode IN episode.id_episode%TYPE) RETURN NUMBER IS
        l_institution institution.id_institution%TYPE;
    BEGIN
        SELECT id_origin_institution
          INTO l_institution
          FROM admission_inpatient a
        
         WHERE a.id_admission_inpatient IN
               (SELECT id_admission_adt
                  FROM admission_adt
                 WHERE id_episode_adt IN (SELECT id_episode_adt
                                            FROM episode_adt
                                           WHERE id_episode = i_episode));
        RETURN l_institution;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_admission_institution_id;

    FUNCTION get_health_plan_sinac
    (
        i_episode IN NUMBER,
        i_mode    IN NUMBER
    ) RETURN VARCHAR2 IS
        x1        VARCHAR2(1) := 'X';
        x2        VARCHAR2(1) := 'X';
        tbl_pat   table_number;
        tbl_inst  table_number;
        l_patient NUMBER;
        l_inst    NUMBER;
        --tbl_aff   table_varchar;
        tbl_cnt  table_varchar;
        l_return VARCHAR2(1000 CHAR);
    BEGIN
    
        IF i_mode = 1
        THEN
            x1 := 'Y';
            x2 := 'N';
        END IF;
    
        SELECT v.id_patient, v.id_institution
          BULK COLLECT
          INTO tbl_pat, tbl_inst
          FROM visit v
          JOIN episode e
            ON e.id_visit = v.id_visit
         WHERE e.id_episode = i_episode;
    
        IF tbl_pat.count > 0
        THEN
            l_patient := tbl_pat(1);
            l_inst    := tbl_inst(1);
        
        END IF;
    
        SELECT id_content
          BULK COLLECT
          INTO tbl_cnt
          FROM (SELECT x.affiliation_number,
                       hpe.id_content,
                       row_number() over(PARTITION BY x.id_patient ORDER BY nvl(eph.id_episode, 0) DESC, x.create_time DESC) order_plan
                  FROM pat_health_plan x
                  LEFT JOIN epis_health_plan eph
                    ON eph.id_pat_health_plan = x.id_pat_health_plan
                  JOIN health_plan hp
                    ON x.id_health_plan = hp.id_health_plan
                  JOIN health_plan_entity hpe
                    ON hpe.id_health_plan_entity = hp.id_health_plan_entity
                 WHERE x.id_patient = l_patient
                   AND x.flg_status != 'I'
                   AND nvl(eph.flg_primary, 'X') IN (x1, x2)
                   AND x.institution_key = l_inst) xsql
         WHERE order_plan = 1;
    
        IF tbl_cnt.count > 0
        THEN
            l_return := tbl_cnt(1);
        END IF;
    
        RETURN l_return;
    
    END get_health_plan_sinac;

    FUNCTION get_jurisdiction_info
    (
        i_lang             IN NUMBER,
        i_id_entity        IN NUMBER,
        i_id_municipaltity IN NUMBER,
        i_id_jurisdiction  IN NUMBER
    ) RETURN NUMBER IS
        l_jurisdiction NUMBER;
    BEGIN
    
        l_jurisdiction := pk_adt_core.get_jurisdiction_info(i_lang            => i_lang,
                                                            i_id_entity       => i_id_entity,
                                                            i_id_municipality => i_id_municipaltity,
                                                            i_id_jurisdiction => i_id_jurisdiction);
    
        RETURN l_jurisdiction;
    
    END get_jurisdiction_info;

    FUNCTION get_code_birth_certificate(i_patient IN NUMBER) RETURN patient.code_birth_certificate%TYPE IS
        l_return patient.code_birth_certificate%TYPE;
        tbl_code table_varchar;
    BEGIN
    
        SELECT pat.code_birth_certificate
          BULK COLLECT
          INTO tbl_code
          FROM patient pat
         WHERE pat.id_patient = i_patient;
    
        IF tbl_code.count > 0
        THEN
            l_return := tbl_code(1);
        END IF;
    
        RETURN l_return;
    
    END get_code_birth_certificate;

    FUNCTION get_birth_certificate_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_flg_edition IN epis_documentation.flg_edition_type%TYPE DEFAULT 'N',
        i_data_show   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_prof_name professional.name%TYPE;
        l_date      VARCHAR2(4000 CHAR);
        l_return    VARCHAR2(4000 CHAR);
    
        k_prof_name       CONSTANT VARCHAR2(0100 CHAR) := 'PROF_NAME';
        k_reg_date        CONSTANT VARCHAR2(0100 CHAR) := 'REG_DATE';
        k_street_type     CONSTANT VARCHAR2(0100 CHAR) := 'STREET_TYPE';
        k_street          CONSTANT VARCHAR2(0100 CHAR) := 'STREET';
        k_outside_number  CONSTANT VARCHAR2(0100 CHAR) := 'OUTSIDE_NUMBER';
        k_inside_number   CONSTANT VARCHAR2(0100 CHAR) := 'INSIDE_NUMBER';
        k_settlement_type CONSTANT VARCHAR2(0100 CHAR) := 'SETTLEMENT_TYPE';
        k_settlement      CONSTANT VARCHAR2(0100 CHAR) := 'SETTLEMENT';
        k_code_settlement CONSTANT VARCHAR2(0100 CHAR) := 'CODE_SETTLEMENT';
        k_postal_code     CONSTANT VARCHAR2(0100 CHAR) := 'POSTAL_CODE';
        k_code_entity     CONSTANT VARCHAR2(0100 CHAR) := 'CODE_ENTITY';
        k_code_municip    CONSTANT VARCHAR2(0100 CHAR) := 'CODE_MUNICIP';
        k_code_location   CONSTANT VARCHAR2(0100 CHAR) := 'CODE_LOCATION';
        k_phone_number    CONSTANT VARCHAR2(0100 CHAR) := 'PHONE_NUMBER';
        k_date_mask       CONSTANT VARCHAR2(0100 CHAR) := 'DD/MM/YYYY';
    
        l_code_birth patient.code_birth_certificate%TYPE;
        l_id_clues   NUMBER;
    BEGIN
        l_code_birth := get_code_birth_certificate(i_patient => i_patient);
        l_id_clues   := get_clues_inst(i_lang => i_lang, i_prof => i_prof, i_id_institution => i_prof.institution);
        IF l_code_birth IS NOT NULL
        THEN
            IF i_data_show = k_prof_name
            THEN
                IF i_flg_edition = pk_touch_option.g_flg_edition_type_new
                THEN
                    l_return := 'SINAC';
                ELSE
                    BEGIN
                        SELECT 'SINAC'
                          INTO l_prof_name
                          FROM dual
                         WHERE EXISTS (SELECT 1
                                  FROM patient_hist p
                                 WHERE p.id_patient = i_patient
                                   AND p.code_birth_certificate <> l_code_birth
                                   AND p.code_birth_certificate IS NOT NULL);
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_prof_name := NULL;
                    END;
                    l_return := l_prof_name;
                END IF;
            ELSIF i_data_show = k_reg_date
            THEN
                IF i_flg_edition = 'N'
                THEN
                    SELECT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => operation_time,
                                                              i_mask      => k_date_mask)
                      INTO l_date
                      FROM (SELECT p.operation_time, row_number() over(ORDER BY p.operation_time ASC) rn
                              FROM patient_hist p
                             WHERE p.id_patient = i_patient
                               AND p.code_birth_certificate = l_code_birth) t
                     WHERE t.rn = 1;
                ELSE
                    SELECT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => operation_time,
                                                              i_mask      => k_date_mask)
                      INTO l_date
                      FROM (SELECT p.operation_time, row_number() over(ORDER BY p.operation_time DESC) rn
                              FROM patient_hist p
                             WHERE p.id_patient = i_patient
                               AND p.code_birth_certificate <> l_code_birth) t
                     WHERE t.rn = 1;
                END IF;
            
                l_return := l_date;
            ELSIF i_data_show = k_street_type
            THEN
                l_return := pk_adt.get_clues_field(i_id_clues => l_id_clues, i_field => k_street_type);
                -- l_return := pk_backoffice.get_inst_field(i_lang, i_prof, i_prof.institution, k_street_type);
            ELSIF i_data_show = k_street
            THEN
                l_return := pk_adt.get_clues_field(i_id_clues => l_id_clues, i_field => k_residence);
            ELSIF i_data_show = k_outside_number
            THEN
                l_return := pk_adt.get_clues_field(i_id_clues => l_id_clues, i_field => k_outside_number);
            ELSIF i_data_show = k_inside_number
            THEN
                l_return := pk_adt.get_clues_field(i_id_clues => l_id_clues, i_field => k_inside_number);
            ELSIF i_data_show = k_settlement_type
            THEN
                l_return := pk_adt.get_clues_field(i_id_clues => l_id_clues, i_field => k_settlement_type);
            ELSIF i_data_show = k_settlement
            THEN
                l_return := pk_adt.get_clues_field(i_id_clues => l_id_clues, i_field => k_urbanization);
            ELSIF i_data_show = k_code_settlement
            THEN
                l_return := pk_adt.get_clues_field(i_id_clues => l_id_clues, i_field => k_code_settlement);
            ELSIF i_data_show = k_postal_code
            THEN
                l_return := pk_adt.get_clues_field(i_id_clues => l_id_clues, i_field => k_postal_code);
            ELSIF i_data_show = k_code_entity
            THEN
                l_return := pk_adt.get_clues_field(i_id_clues => l_id_clues, i_field => k_code_state);
            ELSIF i_data_show = k_code_municip
            THEN
                l_return := pk_adt.get_clues_field(i_id_clues => l_id_clues, i_field => k_code_municipality);
            ELSIF i_data_show = k_code_location
            THEN
                l_return := pk_adt.get_clues_field(i_id_clues => l_id_clues, i_field => k_code_city);
            ELSIF i_data_show = k_phone_number
            THEN
                l_return := pk_adt.get_clues_field(i_id_clues => l_id_clues, i_field => k_phone);
            ELSE
                l_return := NULL;
            END IF;
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_birth_certificate_data;

    FUNCTION is_place_of_birth_inst
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_birth_inst IN pat_birthplace.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_place_of_birth pat_birthplace.id_institution%TYPE;
    BEGIN
    
        IF i_birth_inst IS NULL
        THEN
            SELECT id_institution
              INTO l_place_of_birth
              FROM v_birthplace_address_mx v
            
             WHERE v.id_patient = i_patient;
        ELSE
            l_place_of_birth := i_birth_inst;
        END IF;
    
        IF l_place_of_birth = i_prof.institution
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END is_place_of_birth_inst;

    /********************************************************************************************
    * Function that returns address
    *
    * @param i_person                 PERSON ID
    *
    * @return                         patient adress
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.1.5
    * @since                          28/09/2017
    **********************************************************************************************/

    FUNCTION get_patient_address
    (
        i_lang   IN language.id_language%TYPE,
        i_person IN person.id_person%TYPE
    ) RETURN contact_address.address_line1%TYPE IS
        l_road_type VARCHAR2(200 CHAR);
        l_address   contact_address.address_line1%TYPE;
        CURSOR c_adress IS
            SELECT address_option, road_type, road, door_number, floor
              FROM (SELECT camx.address_option, road_type, road, door_number, floor
                      FROM contact c
                      JOIN contact_address ca
                        ON c.id_contact = ca.id_contact_address
                      JOIN alert_adtcod.contact_address_mx camx
                        ON camx.id_contact_address_mx = ca.id_contact_address
                     WHERE c.id_contact_entity = i_person
                       AND ca.flg_main_address = 'Y'
                     ORDER BY contact_priority ASC)
             WHERE rownum = 1;
    
        r_address c_adress%ROWTYPE;
    BEGIN
        OPEN c_adress;
        FETCH c_adress
            INTO r_address;
        CLOSE c_adress;
    
        CASE r_address.address_option
            WHEN '999' THEN
                IF r_address.road_type IS NOT NULL
                THEN
                    l_road_type := pk_sysdomain.get_domain(i_code_dom => 'CONTACT_ADDRESS_MX.ROAD_TYPE',
                                                           i_val      => r_address.road_type,
                                                           i_lang     => i_lang);
                END IF;
                l_address := l_road_type || ' ' || r_address.road || ' ' || r_address.door_number || ' ' ||
                             r_address.floor;
            ELSE
                l_address := upper(pk_sysdomain.get_domain(i_code_dom => 'CONTACT_ADDRESS_MX.ADDRESS_OPTION',
                                                           i_val      => r_address.address_option,
                                                           i_lang     => i_lang));
        END CASE;
        RETURN l_address;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_patient_address;

    FUNCTION get_jurisdiction_id(id_rb_regional_classifier IN rb_regional_classifier.id_rb_regional_classifier%TYPE)
        RETURN NUMBER IS
        l_id_rb_regional_classifier rb_regional_classifier.id_rb_regional_classifier%TYPE;
    BEGIN
        l_id_rb_regional_classifier := pk_adt_core.get_jurisdiction_id(id_rb_regional_classifier);
        RETURN l_id_rb_regional_classifier;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_jurisdiction_id;

    FUNCTION set_pat_birthplace
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_id_country            IN country.id_country%TYPE,
        i_institution_code      IN VARCHAR2,
        i_id_mother_nationality IN country.id_country%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_adt_core.set_pat_birthplace(i_lang                  => i_lang,
                                              i_prof                  => i_prof,
                                              i_patient               => i_patient,
                                              i_id_country            => i_id_country,
                                              i_institution_code      => i_institution_code,
                                              i_id_mother_nationality => i_id_mother_nationality,
                                              o_error                 => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_PAT_BIRTHPLACE',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_pat_birthplace;

    FUNCTION get_country_id_cnt(i_id_country IN NUMBER) RETURN VARCHAR2 IS
        tbl_return table_varchar;
        l_return   VARCHAR2(4000);
    BEGIN
    
        SELECT id_content
          BULK COLLECT
          INTO tbl_return
          FROM country a
         WHERE a.id_country = i_id_country;
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    
    END get_country_id_cnt;

    FUNCTION get_pat_health_plan_mx
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN NUMBER,
        i_flg_main IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return        VARCHAR2(0200 CHAR);
        tbl_affiliation table_number;
        l_index         NUMBER;
    BEGIN
    
        SELECT php.id_pat_health_plan
          BULK COLLECT
          INTO tbl_affiliation
          FROM pat_health_plan php
          JOIN health_plan hp
            ON php.id_health_plan = hp.id_health_plan
         WHERE php.flg_status != 'I'
           AND php.id_patient = i_patient
           AND php.institution_key = i_prof.institution
         ORDER BY php.id_pat_health_plan;
    
        IF tbl_affiliation.count > 0
        THEN
            IF i_flg_main = 'Y'
            THEN
                l_index := 1;
            ELSE
                l_index := 2;
            END IF;
        
            l_return := tbl_affiliation(l_index);
        
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_health_plan_mx;

    FUNCTION get_pat_other_names
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        o_other_names_1 OUT patient.other_names_1%TYPE,
        o_other_names_2 OUT patient.other_names_2%TYPE,
        o_other_names_3 OUT patient.other_names_3%TYPE,
        o_other_names_4 OUT patient.other_names_4%TYPE
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --IF has_other_names(i_patient => i_patient) = pk_alert_constant.g_yes
        --THEN
        SELECT p.other_names_1, p.other_names_2, p.other_names_3, p.other_names_4
          INTO o_other_names_1, o_other_names_2, o_other_names_3, o_other_names_4
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_other_names_1 := '';
            o_other_names_2 := '';
            o_other_names_3 := '';
            o_other_names_4 := '';
            RETURN TRUE;
    END get_pat_other_names;

    FUNCTION get_pat_process_nr
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN clin_record.num_clin_record%TYPE IS
        l_process_number clin_record.num_clin_record%TYPE;
    BEGIN
    
        SELECT num_clin_record
          INTO l_process_number
          FROM (SELECT crn.*
                  FROM clin_record crn
                 WHERE crn.id_patient = i_id_patient
                   AND crn.flg_status = pk_alert_constant.g_active
                 ORDER BY decode(crn.id_institution, i_prof.institution, 1, 0) DESC)
         WHERE rownum < 2;
    
        RETURN l_process_number;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_process_nr;

    /********************************************************************************************
    * This function returns the department where the patient is located for inpatient admissions
    *
    * @param i_episode      id_episode on pfh
    *
    * @return                 id department
    *
    *
    * @author                 Sofia Mendes
    * @version                2.7.4
    * @since                  2018-08-29
    **********************************************************************************************/
    FUNCTION get_department_patient_located
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN department.id_department%TYPE IS
        l_id_department department.id_department%TYPE;
    BEGIN
        SELECT dcs.id_department
          INTO l_id_department
          FROM admission_inpatient a
          JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = a.id_loc_dep_clinical_service
         WHERE a.id_admission_inpatient IN
               (SELECT id_admission_adt
                  FROM admission_adt
                 WHERE id_episode_adt IN (SELECT id_episode_adt
                                            FROM episode_adt
                                           WHERE id_episode = i_episode));
        RETURN l_id_department;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_department_patient_located;

    FUNCTION cancel_episode_adt
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        UPDATE episode_adt
           SET flag_status = pk_alert_constant.g_cancelled
         WHERE id_episode = i_episode;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_EPISODE_ADT',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END cancel_episode_adt;

    /******************************************************************************
    * read spec for full description 
    *                                                       Comparticipação Comparticipação especial
    * 1.    Situações sem comparticipação do SNS    
    *   Pacientes com plano de saúde “sem comparticipação”  N               N
    * 2.    Situações com comparticipação do SNS    
    *   Pacientes com SNS                                   S               N
    *   Pacientes migrantes (com ou sem SNS)                S               N
    *   Pacientes da CNRPP                                  S               N
    * 3.    Situações com comparticipação especial do SNS   
    *   Pacientes pensionistas (com RECM = R)               S               S
    *********************************************************************************/
    FUNCTION get_pat_comp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        o_flg_comp         OUT VARCHAR2,
        o_flg_special_comp OUT VARCHAR2,
        o_flg_plan_type    OUT VARCHAR2,
        o_flg_recm         OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_name                  patient.name%TYPE;
        l_gender                patient.gender%TYPE;
        l_desc_gender           VARCHAR2(20 CHAR);
        l_dt_birth              VARCHAR2(20 CHAR);
        l_dt_deceased           VARCHAR2(20 CHAR);
        l_flg_migrator          pat_soc_attributes.flg_migrator%TYPE;
        l_id_country_nation     country.alpha2_code%TYPE;
        l_sns                   pat_health_plan.num_health_plan%TYPE;
        l_valid_sns             VARCHAR2(2 CHAR);
        l_flg_occ_disease       VARCHAR2(2 CHAR);
        l_flg_independent       VARCHAR2(2 CHAR);
        l_num_health_plan       pat_health_plan.num_health_plan%TYPE;
        l_hp_entity             VARCHAR2(2000 CHAR);
        l_id_health_plan        NUMBER;
        l_flg_recm              VARCHAR2(2 CHAR);
        l_main_phone            VARCHAR2(50 CHAR);
        l_hp_alpha2_code        VARCHAR2(10 CHAR);
        l_hp_country_desc       VARCHAR2(50 CHAR);
        l_hp_national_ident_nbr pat_health_plan.num_health_plan%TYPE;
        l_hp_dt_effective       VARCHAR2(20);
        l_error                 t_error_out;
        l_hp_comp               VARCHAR2(1 CHAR);
        l_valid_hp              VARCHAR2(1 CHAR);
        l_flg_type_hp           health_plan.flg_type%TYPE;
        l_hp_id_content         health_plan.id_content%TYPE;
        l_hp_inst_ident_nbr     pat_health_plan.inst_identifier_number%TYPE;
        l_hp_inst_ident_desc    pat_health_plan.inst_identifier_desc%TYPE;
        l_hp_dt_valid           VARCHAR2(20);
    BEGIN
        g_error := 'INIT - get_pat_comp ID_PAT:' || i_id_patient || ' ID_EPIS:' || i_id_episode || ' PROF:(' ||
                   i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || ')';
    
        pk_alertlog.log_debug(g_error);
    
        o_flg_comp         := g_no;
        o_flg_special_comp := g_no;
    
        IF NOT get_pat_info(i_lang                    => i_lang,
                            i_id_patient              => i_id_patient,
                            i_prof                    => i_prof,
                            i_id_episode              => i_id_episode,
                            i_flg_info_for_medication => pk_alert_constant.g_yes,
                            o_name                    => l_name,
                            o_gender                  => l_gender,
                            o_desc_gender             => l_desc_gender,
                            o_dt_birth                => l_dt_birth,
                            o_dt_deceased             => l_dt_deceased,
                            o_flg_migrator            => l_flg_migrator,
                            o_id_country_nation       => l_id_country_nation,
                            o_sns                     => l_sns,
                            o_valid_sns               => l_valid_sns,
                            o_flg_occ_disease         => l_flg_occ_disease,
                            o_flg_independent         => l_flg_independent,
                            o_num_health_plan         => l_num_health_plan,
                            o_hp_entity               => l_hp_entity,
                            o_id_health_plan          => l_id_health_plan,
                            o_flg_recm                => l_flg_recm,
                            o_main_phone              => l_main_phone,
                            o_hp_alpha2_code          => l_hp_alpha2_code,
                            o_hp_country_desc         => l_hp_country_desc,
                            o_hp_national_ident_nbr   => l_hp_national_ident_nbr,
                            o_hp_dt_effective         => l_hp_dt_effective,
                            o_valid_hp                => l_valid_hp,
                            o_flg_type_hp             => l_flg_type_hp,
                            o_hp_id_content           => l_hp_id_content,
                            o_hp_inst_ident_nbr       => l_hp_inst_ident_nbr,
                            o_hp_inst_ident_desc      => l_hp_inst_ident_desc,
                            o_hp_dt_valid             => l_hp_dt_valid,
                            o_error                   => l_error)
        THEN
            pk_alertlog.log_error(g_error);
            RETURN FALSE;
        END IF;
    
        /*
        *                                                       Comparticipação Comparticipação especial
        * 1. Situações sem comparticipação do SNS   
        *       Pacientes com plano de saúde “sem comparticipação”  N               N
        * 2. Situações com comparticipação do SNS   
        *       Pacientes com SNS                                   Y               N
        *       Pacientes migrantes (com ou sem SNS)                Y               N
        *       Pacientes da CNRPP                                  Y               N
        * 3. Situações com comparticipação especial do SNS    
        *       Pacientes pensionistas (com RECM = R)               Y               Y
        */
    
        IF (l_id_health_plan IS NOT NULL)
        THEN
            BEGIN
                SELECT decode(hp.flg_type,
                              c_sns_hp_type,
                              g_yes,
                              c_adse_hp_type,
                              g_yes,
                              c_profdecease_hp_type,
                              g_yes,
                              c_other_reimbursed_plan,
                              g_yes,
                              c_cesd_hp_type,
                              g_yes,
                              g_no),
                       hp.flg_type
                  INTO l_hp_comp, o_flg_plan_type
                  FROM health_plan hp
                 WHERE hp.id_health_plan = l_id_health_plan;
            EXCEPTION
                WHEN no_data_found THEN
                    l_hp_comp := g_no;
            END;
        END IF;
    
        IF (l_flg_migrator = g_yes)
        THEN
            o_flg_comp := g_no;
            --Pacientes com SNS (ou plano válido) ou Pacientes migrantes (com ou sem SNS) ou Pacientes da CNRPP
        END IF;
        IF l_hp_comp = g_yes
           OR l_flg_occ_disease = g_yes
        THEN
            o_flg_comp := g_yes;
        END IF;
    
        --Pacientes pensionistas (com RECM = R ou RO)
        o_flg_recm := l_flg_recm;
        IF l_flg_recm = 'R'
           OR l_flg_recm = 'RO'
        THEN
            o_flg_special_comp := g_yes;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_COMP',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_comp;

    FUNCTION get_preferred_language
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_adt_core.get_preferred_language(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_preferred_language;

    /********************************************************************************************
    * Shows, when applicable, a warning message to the user. Validates Prescription Rules - ACSS Request
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_episode                Episode
    * @param i_type                   M - Medication, R - Referral
    *
    * @param      o_flg_show         Flag that indicates if exist any warning message to be shown
    * @param      o_message_title    Label for the title of the warning message screen
    * @param      o_message_text     Warning message
    * @param      o_forward_button   Label for the forward button
    * @param      o_back_button      Label for the back button
    * @param      o_error            Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Pedro Morais
    * @version                        0.1
    * @since                          2011/07/06
    **********************************************************************************************/
    FUNCTION check_patient_rules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_type            IN VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_message_title   OUT VARCHAR2,
        o_message_text    OUT VARCHAR2,
        o_forward_button  OUT VARCHAR2,
        o_back_button     OUT VARCHAR2,
        o_flg_can_proceed OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(32 CHAR) := 'CHECK_PATIENT_RULES';
        l_sns                   pat_health_plan.num_health_plan%TYPE; --Numero SNS
        l_num_health_plan       pat_health_plan.num_health_plan%TYPE; --Numero sns/seguro saude/etc
        l_pat_name              patient.name%TYPE; --Nome paciente
        l_pat_dt_birth          VARCHAR2(200); --Data de nascimento
        l_pat_gender            patient.gender%TYPE; --Género
        l_pat_birth_place       country.alpha2_code%TYPE; --Nacionalidade
        l_id_health_plan        pat_health_plan.id_health_plan%TYPE;
        l_id_cnt_hp             health_plan.id_content%TYPE; --health plan default content id
        l_id_default_hp         health_plan.id_health_plan%TYPE;
        l_hp_entity             VARCHAR2(4000);
        l_flg_migrator          pat_soc_attributes.flg_migrator%TYPE;
        l_flg_occ_disease       VARCHAR2(1);
        l_flg_independent       VARCHAR2(1);
        l_exist_migrator_doc    VARCHAR2(1);
        l_dummy                 VARCHAR2(4000);
        l_new_line              VARCHAR2(20) := '<br><br>';
        l_dt_expire             doc_external.dt_expire%TYPE;
        l_num_doc               doc_external.num_doc%TYPE;
        l_hp_alpha2_code        VARCHAR2(4000);
        l_hp_national_ident_nbr VARCHAR2(4000);
        l_check_date            VARCHAR2(1 CHAR);
        l_hp_dt_effective       VARCHAR2(200); --Health plan effective date
        l_valid_sns             VARCHAR2(1);
        l_flg_comp              VARCHAR2(1 CHAR);
        l_flg_special_comp      VARCHAR2(1 CHAR);
        l_flg_plan_type         VARCHAR2(1 CHAR);
        l_flg_recm              VARCHAR2(2 CHAR);
        l_valid_hp              VARCHAR2(1 CHAR);
        l_flg_type_hp           health_plan.flg_type%TYPE;
        l_doc_type              doc_type.id_doc_type%TYPE;
        l_id_content_doc_type   doc_type.id_content%TYPE;
        l_hp_id_content         health_plan.id_content%TYPE;
        l_hp_inst_ident_nbr     pat_health_plan.inst_identifier_number%TYPE;
        l_hp_inst_ident_desc    pat_health_plan.inst_identifier_desc%TYPE;
        l_hp_dt_valid           VARCHAR2(200);
        l_msg_no_proceed        VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
    BEGIN
        g_error := 'INIT - check_patient_rules:' || i_type;
    
        -- build cancellation confirmation messsage
        o_flg_show        := pk_alert_constant.g_no;
        o_flg_can_proceed := pk_alert_constant.g_no;
    
        g_error := 'Call pk_adt.get_pat_info i_patient=' || i_patient;
        IF NOT get_pat_info(i_lang                    => i_lang,
                            i_id_patient              => i_patient,
                            i_prof                    => i_prof,
                            i_id_episode              => i_episode,
                            i_flg_info_for_medication => pk_alert_constant.g_yes,
                            o_name                    => l_pat_name,
                            o_gender                  => l_pat_gender,
                            o_desc_gender             => l_dummy,
                            o_dt_birth                => l_pat_dt_birth,
                            o_dt_deceased             => l_dummy,
                            o_flg_migrator            => l_flg_migrator,
                            o_id_country_nation       => l_pat_birth_place,
                            o_sns                     => l_sns,
                            o_valid_sns               => l_valid_sns,
                            o_flg_occ_disease         => l_flg_occ_disease, --Doente profissional: CNPRP
                            o_flg_independent         => l_flg_independent, --EFR: Independente
                            o_num_health_plan         => l_num_health_plan,
                            o_hp_entity               => l_hp_entity,
                            o_id_health_plan          => l_id_health_plan,
                            o_flg_recm                => l_dummy,
                            o_main_phone              => l_dummy,
                            o_hp_alpha2_code          => l_hp_alpha2_code,
                            o_hp_country_desc         => l_dummy,
                            o_hp_national_ident_nbr   => l_hp_national_ident_nbr,
                            o_hp_dt_effective         => l_hp_dt_effective,
                            o_valid_hp                => l_valid_hp,
                            o_flg_type_hp             => l_flg_type_hp,
                            o_hp_id_content           => l_hp_id_content,
                            o_hp_inst_ident_nbr       => l_hp_inst_ident_nbr,
                            o_hp_inst_ident_desc      => l_hp_inst_ident_desc,
                            o_hp_dt_valid             => l_hp_dt_valid,
                            o_error                   => o_error)
        THEN
            RAISE g_adtexception;
        END IF;
    
        g_error := 'Call pk_adt.get_pat_comp i_patient=' || i_patient;
        IF NOT get_pat_comp(i_lang             => i_lang,
                            i_prof             => i_prof,
                            i_id_patient       => i_patient,
                            i_id_episode       => i_episode,
                            o_flg_comp         => l_flg_comp,
                            o_flg_special_comp => l_flg_special_comp,
                            o_flg_plan_type    => l_flg_plan_type,
                            o_flg_recm         => l_flg_recm,
                            o_error            => o_error)
        THEN
            RAISE g_adtexception;
        END IF;
    
        --Obter informação de documento de migrante. Se tem doc ou não, e o número do doc se for necessário
        g_error := 'Call pk_doc.get_migrant_doc i_patient=' || i_patient;
        IF NOT pk_doc.get_migrant_doc(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_id_patient          => i_patient,
                                      o_num_doc             => l_num_doc,
                                      o_exist_doc           => l_exist_migrator_doc,
                                      o_dt_expire           => l_dt_expire,
                                      o_doc_type            => l_doc_type,
                                      o_id_content_doc_type => l_id_content_doc_type,
                                      o_error               => o_error)
        THEN
            RAISE g_adtexception;
        END IF;
    
        /*g_error      := 'Call pk_date_utils.compare_dates_tsz i_date1=' || l_dt_expire || ' i_date2=' ||
                        current_timestamp;
        l_check_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                        i_date1 => l_dt_expire,
                                                        i_date2 => current_timestamp);*/
        l_id_cnt_hp := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
        BEGIN
            SELECT hp.id_health_plan
              INTO l_id_default_hp
              FROM health_plan hp
             WHERE hp.id_content = l_id_cnt_hp
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_id_default_hp := NULL;
        END;
        --Validate data >>>
        --Caso 1 - Nacional só SNS - não obriga a ter nº beneficiário
        IF l_sns IS NOT NULL --Nº utente SNS
          --AND l_valid_sns = pk_alert_constant.g_yes
           AND l_pat_name IS NOT NULL --Nome
           AND l_pat_dt_birth IS NOT NULL --data nascimento
           AND (l_pat_gender IS NOT NULL OR l_pat_gender NOT IN ('F', 'M')) -- Masculino ou Feminio
          --AND l_pat_birth_place IS NOT NULL --Nacionalidade
          --AND l_num_health_plan IS NOT NULL --Entidade financeira - Num beneficiário segundo ADT
           AND l_id_health_plan = l_id_default_hp --é só SNS
        --AND l_flg_occ_disease = pk_alert_constant.g_no
        THEN
            pk_alertlog.log_info('Nacional só SNS - não obriga a ter nº beneficiário');
            RETURN TRUE;
            --Caso 5 - Nacional com numero de beneficiário
        ELSIF l_sns IS NOT NULL --Nº utente SNS
             --AND l_valid_sns = pk_alert_constant.g_yes
              AND l_pat_name IS NOT NULL --Nome
              AND l_pat_dt_birth IS NOT NULL --data nascimento
              AND (l_pat_gender IS NOT NULL --Sexo
              OR l_pat_gender NOT IN ('F', 'M'))
             --AND l_pat_birth_place IS NOT NULL --Nacionalidade
             --AND l_num_health_plan IS NOT NULL --Entidade financeira - Num beneficiário segundo ADT
              AND l_num_health_plan IS NOT NULL --tem num beneficiário
        --AND l_flg_occ_disease = pk_alert_constant.g_no
        THEN
            pk_alertlog.log_info('Nacional com numero de beneficiário');
            RETURN TRUE;
            --Caso 2 - Migrante com documento
        ELSIF l_sns IS NULL --Nº utente SNS
              AND l_pat_name IS NOT NULL --Nome
              AND l_pat_dt_birth IS NOT NULL --data nascimento
              AND (l_pat_gender IS NOT NULL --Sexo
              OR l_pat_gender NOT IN ('F', 'M'))
             --AND l_pat_birth_place IS NOT NULL --Nacionalidade
             --AND l_num_health_plan IS NOT NULL --Entidade financeira - Num beneficiário segundo ADT
             --AND l_flg_migrator = pk_alert_constant.g_yes --é migrante
              AND l_exist_migrator_doc = pk_alert_constant.g_yes --tem documento
              AND l_num_health_plan IS NOT NULL --tem num beneficiário
              AND l_hp_national_ident_nbr IS NOT NULL
              AND l_dt_expire IS NOT NULL
              AND l_num_doc IS NOT NULL
              AND l_hp_alpha2_code IS NOT NULL
        --AND l_check_date <> 'L'
        THEN
            pk_alertlog.log_info('Migrante com documento');
            RETURN TRUE;
            --Caso 3 - Nacional sem SNS, nem é doente profissional, mas outra entidade financeira 
        ELSIF l_sns IS NULL --Nº utente SNS
              AND l_pat_name IS NOT NULL --Nome
              AND l_pat_dt_birth IS NOT NULL --data nascimento
              AND (l_pat_gender IS NOT NULL OR l_pat_gender NOT IN ('F', 'M')) --Sexo
              AND l_id_health_plan <> l_id_default_hp --entidade fin não é SNS
              AND l_num_health_plan IS NOT NULL --tem num beneficiário
        -- AND l_flg_occ_disease = pk_alert_constant.g_no
        THEN
            pk_alertlog.log_info('Nacional sem SNS, nem é doente profissional, mas outra entidade financeira');
            RETURN TRUE;
            --Caso 4 - Migrante sem documento mas com EFR Independente
        ELSIF l_sns IS NULL --Nº utente SNS
              AND l_pat_name IS NOT NULL --Nome
              AND l_pat_dt_birth IS NOT NULL --data nascimento
              AND (l_pat_gender IS NOT NULL OR l_pat_gender NOT IN ('F', 'M')) --Sexo
             --AND l_pat_birth_place IS NOT NULL --Nacionalidade
             --AND l_num_health_plan IS NOT NULL --Entidade financeira - Num beneficiário segundo ADT
              AND l_flg_migrator = pk_alert_constant.g_yes --é migrante
              AND l_flg_independent = pk_alert_constant.g_yes --tem EFR independente
        THEN
            pk_alertlog.log_info('Migrante sem documento mas com EFR Independente');
            RETURN TRUE;
            -- caso doente profissional
        ELSIF l_sns IS NOT NULL --Nº utente SNS
              AND l_pat_name IS NOT NULL --Nome
              AND l_pat_dt_birth IS NOT NULL --data nascimento
              AND (l_pat_gender IS NOT NULL OR l_pat_gender NOT IN ('F', 'M')) --Sexo
             --AND l_pat_birth_place IS NOT NULL --Nacionalidade
              AND (l_flg_comp = pk_alert_constant.g_yes AND l_flg_plan_type = g_hp_type_profdecease)
              AND l_num_health_plan IS NOT NULL --tem num beneficiário
              AND l_flg_occ_disease = pk_alert_constant.g_yes
        THEN
            pk_alertlog.log_info('Caso doente profissional');
            RETURN TRUE;
        ELSE
            o_flg_show := pk_alert_constant.g_yes;
        
            o_message_title  := pk_message.get_message(i_lang, 'PRESCRIPTION_REC_M015');
            o_forward_button := pk_message.get_message(i_lang, 'PRESCRIPTION_REC_M017');
            o_back_button    := pk_message.get_message(i_lang, 'PRESCRIPTION_REC_M016');
        
            --Se não tem SNS
            IF l_sns IS NULL
               OR l_num_health_plan IS NULL
            THEN
                o_message_text := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T025'); --Mensagem utente SNS não foi preenchido ou inválido
            END IF;
            --Se não tem outro número (seg. saúde por exemplo)
            /*IF l_num_health_plan IS NULL
            THEN
                pk_alertlog.log_info('l_num_health_plan IS NULL');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                o_message_text := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T016'); --Mensagem entidade financeira não foi preenchido
            END IF;*/
            --Se não tem nome
            IF l_pat_name IS NULL
            THEN
                pk_alertlog.log_info('l_pat_name IS NULL');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                l_msg_no_proceed := pk_alert_constant.g_no;
                o_message_text   := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T017'); --Mensagem nome paciente não foi preenchido
            END IF;
            --Se não tem género
            IF l_pat_gender IS NULL
            THEN
                pk_alertlog.log_info('l_pat_gender IS NULL');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                l_msg_no_proceed := pk_alert_constant.g_no;
                o_message_text   := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T018'); --Mensagem sexo não foi preenchido
            END IF;
        
            IF l_pat_gender NOT IN ('F', 'M')
            THEN
                pk_alertlog.log_info('l_pat_gender IS NULL');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                l_msg_no_proceed := pk_alert_constant.g_no;
                o_message_text   := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T024'); --Género deve ser Masculino ou Fiminino
            END IF;
            --Se não tem data de nascimento
            IF l_pat_dt_birth IS NULL
            THEN
                pk_alertlog.log_info('l_pat_dt_birth IS NULL');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                l_msg_no_proceed := pk_alert_constant.g_no;
                o_message_text   := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T019'); --Mensagem data nascimento não foi preenchido
            END IF;
        
            /*IF l_check_date = 'L'
            THEN
                pk_alertlog.log_info('l_check_date = L');
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                o_message_text := o_message_text || '- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T023'); --Mensagem data de validade do CESD ou CPS esprirou.
            END IF;*/
        
            o_message_text := '<b>' || o_message_text || '</b>';
        
            IF (l_msg_no_proceed = pk_alert_constant.g_no)
            THEN
                o_flg_can_proceed := pk_alert_constant.g_no;
            ELSE
                o_flg_can_proceed := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_adtexception THEN
            o_flg_show := 'N';
            RETURN FALSE;
        WHEN no_data_found THEN
            o_flg_show := 'N';
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => c_function_name,
                                                     o_error    => o_error);
        
    END check_patient_rules;

    -- CMF **********************
    FUNCTION get_fam_relationship(i_id_patient IN NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN pk_adt_api_out.get_fam_relationship(i_id_patient => i_id_patient);
    END get_fam_relationship;

    -- CMF **********************
    FUNCTION get_fam_relationship_spec(i_id_patient IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_adt_api_out.get_fam_relationship_spec(i_id_patient => i_id_patient);
    END get_fam_relationship_spec;

    FUNCTION get_id_pat_relative(i_id_patient IN NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN pk_adt_api_out.get_id_pat_relative(i_id_patient => i_id_patient);
    END get_id_pat_relative;

    FUNCTION get_info_contact_rel_full(i_pat_relative IN NUMBER) RETURN table_varchar IS
    BEGIN
        RETURN pk_adt_api_out.get_info_contact_rel_full(i_pat_relative => i_pat_relative);
    END get_info_contact_rel_full;

    FUNCTION get_1st_cgiver_1st_name(i_id_patient IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_adt_api_out.get_1st_cgiver_1st_name(i_id_patient => i_id_patient);
    END get_1st_cgiver_1st_name;

    FUNCTION get_1st_cgiver_otname1(i_id_patient IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_adt_api_out.get_1st_cgiver_otname1(i_id_patient => i_id_patient);
    END get_1st_cgiver_otname1;

    FUNCTION get_1st_fam_name(i_id_patient IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_adt_api_out.get_1st_fam_name(i_id_patient => i_id_patient);
    END get_1st_fam_name;

    FUNCTION get_1st_fam_otname3(i_id_patient IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_adt_api_out.get_1st_fam_otname3(i_id_patient => i_id_patient);
    END get_1st_fam_otname3;

    FUNCTION get_1st_mphone_no(i_id_patient IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_adt_api_out.get_1st_mphone_no(i_id_patient => i_id_patient);
    END get_1st_mphone_no;

    --******************************************
    FUNCTION get_family_rel(i_lang IN NUMBER) RETURN t_tbl_core_domain IS
        tbl_return t_tbl_core_domain;
    BEGIN
    
        SELECT t_row_core_domain(internal_name => 'FAMILY_RELATIONSHIP',
                                 desc_domain   => xsql.desc_relationship,
                                 domain_value  => xsql.id_family_relationship,
                                 order_rank    => rownum,
                                 img_name      => '')
          BULK COLLECT
          INTO tbl_return
          FROM (SELECT id_family_relationship,
                       pk_translation.get_translation(i_lang, fr.code_family_relationship) desc_relationship
                  FROM family_relationship fr
                 WHERE fr.flg_available = 'Y') xsql
         WHERE desc_relationship IS NOT NULL;
    
        RETURN tbl_return;
    
    END get_family_rel;

    -- ****************************************************************
    FUNCTION get_fam_rel_domain_desc
    (
        i_lang  IN NUMBER,
        i_value IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_desc table_varchar;
        l_return VARCHAR2(4000);
    BEGIN
    
        SELECT fr.desc_domain
          BULK COLLECT
          INTO tbl_desc
          FROM TABLE(pk_adt.get_family_rel(i_lang)) fr
         WHERE fr.domain_value = i_value;
    
        IF tbl_desc.count > 0
        THEN
            l_return := tbl_desc(1);
        END IF;
    
        RETURN l_return;
    
    END get_fam_rel_domain_desc;

    --******************************************
    FUNCTION get_country_dial_code(i_lang IN NUMBER) RETURN t_tbl_core_domain IS
        tbl_return t_tbl_core_domain;
    BEGIN
    
        SELECT t_row_core_domain(internal_name => 'COUNTRY_DIAL_CODE',
                                 desc_domain   => pk_translation.get_translation(i_lang, cdc.code_country_dial_code),
                                 domain_value  => cdc.id_country_dial_code,
                                 order_rank    => rownum,
                                 img_name      => '')
          BULK COLLECT
          INTO tbl_return
          FROM country_dial_code cdc
         WHERE cdc.flg_available = 'Y';
    
        RETURN tbl_return;
    
    END get_country_dial_code;

    -- ****************************************************************
    FUNCTION get_country_dial_code_desc
    (
        i_lang  IN NUMBER,
        i_value IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_desc table_varchar;
        l_return VARCHAR2(4000);
    BEGIN
    
        SELECT fr.desc_domain
          BULK COLLECT
          INTO tbl_desc
          FROM TABLE(pk_adt.get_country_dial_code(i_lang)) fr
         WHERE fr.domain_value = i_value;
    
        IF tbl_desc.count > 0
        THEN
            l_return := tbl_desc(1);
        END IF;
    
        RETURN l_return;
    
    END get_country_dial_code_desc;

    -- ******************************************************
    FUNCTION save_caregiver_info
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_id_patient    IN NUMBER,
        i_id_fam_rel    IN NUMBER,
        i_fam_rel_spec  IN VARCHAR2,
        i_firstname     IN VARCHAR2,
        i_lastname      IN VARCHAR2,
        i_othernames1   IN VARCHAR2,
        i_othernames3   IN VARCHAR2,
        i_phone_no      IN VARCHAR2,
        i_id_care_giver IN NUMBER
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_adt_api_out.save_caregiver_info(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_id_patient    => i_id_patient,
                                                  i_id_fam_rel    => i_id_fam_rel,
                                                  i_fam_rel_spec  => i_fam_rel_spec,
                                                  i_firstname     => i_firstname,
                                                  i_lastname      => i_lastname,
                                                  i_othernames1   => i_othernames1,
                                                  i_othernames3   => i_othernames3,
                                                  i_phone_no      => i_phone_no,
                                                  i_id_care_giver => i_id_care_giver);
    
    END save_caregiver_info;

    -- ****************************************
    FUNCTION get_patient_type_arabic
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_adt_api_out.get_patient_hajj_umrah(i_prof, i_patient);
    END get_patient_type_arabic;
    --************************************
    FUNCTION get_trl_oci_arab(i_text IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_adt_api_out.get_trl_oci_arab(i_text => i_text);
    
    END get_trl_oci_arab;

    --********************************************
    FUNCTION get_trl_arab_oci(i_text IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_adt_api_out.get_trl_arab_oci(i_text => i_text);
    
    END get_trl_arab_oci;

    FUNCTION check_sus_health_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_has_sus    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        c_myfunction CONSTANT VARCHAR2(100) := 'PK_ADT.CHECK_SUS_HEALTH_PLAN';
        c_conf_fatal_error EXCEPTION;
        l_sus_hp      sys_config.value%TYPE;
        l_sus_hp_list table_varchar2 := table_varchar2();
        l_count       NUMBER;
    BEGIN
    
        --log input parameters
        g_error := c_myfunction || ' LANG:' || i_lang || ' PROF:' || i_prof.id || ' INST:' || i_prof.institution ||
                   ' SOFT:' || i_prof.software || ' PAT:' || i_id_patient;
    
        pk_alertlog.log_debug(g_error);
    
        --Get list of sus health plans
        l_sus_hp := pk_sysconfig.get_config('REP_ID_HEALTH_PLAN_PATIENT_SUS', i_prof);
    
        IF (l_sus_hp IS NOT NULL)
        THEN
            l_sus_hp_list := pk_utils.str_split(i_list => l_sus_hp, i_delim => '|');
            g_error       := 'GET NATIONAL HEALTH PLAN SUS';
        
            IF (l_sus_hp_list.count > 0)
            THEN
                BEGIN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM pat_health_plan php
                      JOIN health_plan hp
                        ON hp.id_health_plan = php.id_health_plan
                     WHERE php.id_patient = i_id_patient
                       AND php.id_institution = g_all_institution
                       AND hp.id_content IN (SELECT column_value AS id_content
                                               FROM TABLE(l_sus_hp_list) hp_cnt)
                       AND hp.flg_available = pk_alert_constant.get_available
                       AND php.flg_status = g_adt_hplan_active
                       AND rownum = 1;
                    IF (l_count > 0)
                    THEN
                        o_has_sus := pk_alert_constant.get_yes;
                    ELSE
                        o_has_sus := pk_alert_constant.get_no;
                    END IF;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        o_has_sus := pk_alert_constant.get_no;
                END;
            ELSE
                o_has_sus := pk_alert_constant.get_no;
            END IF;
        ELSE
            o_has_sus := pk_alert_constant.get_no;
        END IF;
    
        g_error := c_myfunction || ' PAT:' || i_id_patient || ' HAS SUS:' || o_has_sus;
    
        pk_alertlog.log_debug(g_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              o_error);
            RETURN FALSE;
    END check_sus_health_plan;

    FUNCTION get_pat_fam_name
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN NUMBER,
        i_id_family_relationship IN NUMBER,
        o_error                  OUT t_error_out
    ) RETURN VARCHAR2 IS
        l_name        patient.first_name%TYPE;
        l_second_name patient.second_name%TYPE;
        l_middle_name patient.middle_name%TYPE;
        l_last_name   patient.last_name%TYPE;
        l_name_return patient.name%TYPE;
        l_config      sys_config.value%TYPE := pk_sysconfig.get_config('PATIENT_NAME_PATTERN', i_prof);
    BEGIN
    
        IF NOT pk_adt_core.get_pat_fam_rel_name(i_lang                   => i_lang,
                                                i_id_patient             => i_id_patient,
                                                i_id_family_relationship => i_id_family_relationship,
                                                o_name                   => l_name,
                                                o_second_name            => l_second_name,
                                                o_middle_name            => l_middle_name,
                                                o_last_name              => l_last_name,
                                                o_error                  => o_error)
        THEN
            l_name_return := NULL;
        END IF;
    
        IF NOT pk_adt.build_name(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_config      => l_config,
                                 i_first_name  => l_name,
                                 i_second_name => l_second_name,
                                 i_midlle_name => l_middle_name,
                                 i_last_name   => l_last_name,
                                 o_pat_name    => l_name_return,
                                 o_error       => o_error)
        THEN
            l_name_return := NULL;
        END IF;
    
        RETURN l_name_return;
    
    END get_pat_fam_name;

    FUNCTION get_legal_guardian
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN NUMBER
    ) RETURN VARCHAR2 IS
        l_name_return VARCHAR2(4000);
        l_error       t_error_out;
    BEGIN
        l_name_return := get_pat_fam_name(i_lang                   => i_lang,
                                          i_prof                   => i_prof,
                                          i_id_patient             => i_id_patient,
                                          i_id_family_relationship => g_family_rel_guardian,
                                          o_error                  => l_error);
    
        RETURN l_name_return;
    END get_legal_guardian;

    FUNCTION get_patient_id_county
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN NUMBER
    ) RETURN pat_soc_attributes.id_country_nation%TYPE IS
        l_return pat_soc_attributes.id_country_nation%TYPE;
    BEGIN
        SELECT id_country_nation
          INTO l_return
          FROM (SELECT row_number() over(ORDER BY --            
                       decode(psa.id_institution, i_prof.institution, 0, pk_alert_constant.g_inst_all, 1, 2) ASC) rn,
                       psa.id_country_nation
                  FROM pat_soc_attributes psa
                 WHERE psa.id_patient = i_id_patient
                   AND psa.id_institution IN
                       (SELECT /*+opt_estimate (table t rows=1)*/
                         column_value
                          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt)) t
                        UNION ALL
                        SELECT pk_alert_constant.g_inst_all column_value
                          FROM dual)) aux
         WHERE aux.rn = 1;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_patient_id_county;

    FUNCTION get_admission_origin_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_ret pk_translation.t_desc_translation;
    
    BEGIN
    
        SELECT pk_translation.get_translation(8, 'ORIGIN.CODE_ORIGIN.' || a.id_origin)
          INTO l_ret
          FROM episode_adt ea
          JOIN admission_adt a
            ON ea.id_episode_adt = a.id_episode_adt
         WHERE ea.id_episode = i_episode;
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
            RETURN NULL;
        
    END get_admission_origin_desc;

    FUNCTION get_patient_name_search
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_name          patient.name%TYPE;
        l_alias         patient.alias%TYPE;
        l_vipstatus     patient.vip_status%TYPE;
        l_other_names_1 patient.other_names_1%TYPE;
        l_other_names_2 patient.other_names_2%TYPE;
        l_other_names_3 patient.other_names_3%TYPE;
        l_other_names_4 patient.other_names_4%TYPE;
        l_first_name    patient.first_name%TYPE;
        l_second_name   patient.second_name%TYPE;
        l_middle_name   patient.middle_name%TYPE;
        l_last_name     patient.last_name%TYPE;
    
        g_concat_other_names CONSTANT VARCHAR(1 CHAR) := pk_sysconfig.get_config('ADT_CONCAT_OTHER_NAMES', i_prof);
        l_id_market market.id_market%TYPE;
        v_error     t_error_out;
    
    BEGIN
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                     JOIN market m
                       ON i.id_market = m.id_market
                    WHERE i.id_institution = i_prof.institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        --Get patient s data
        SELECT p.name,
               p.alias,
               p.vip_status,
               p.other_names_1,
               p.other_names_2,
               p.other_names_3,
               p.other_names_4,
               p.first_name,
               p.second_name,
               p.middle_name,
               p.last_name
          INTO l_name,
               l_alias,
               l_vipstatus,
               l_other_names_1,
               l_other_names_2,
               l_other_names_3,
               l_other_names_4,
               l_first_name,
               l_second_name,
               l_middle_name,
               l_last_name
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        -- returns patient s real name
        IF l_vipstatus IS NOT NULL
        THEN
            l_name := pk_sysdomain.get_domain('PATIENT.VIP_STATUS.ABBR', l_vipstatus, i_lang) || ' ' || l_name;
        ELSE
            l_name := l_name;
        END IF;
    
        --For KW, MX arabic names are concatenated, for US they aren t, for all other markets those fields are not used
        IF g_concat_other_names = pk_alert_constant.g_yes
           OR l_id_market = g_mx_market
        THEN
            --concatenate other names if professional is responsible for patient                
            IF l_id_market = g_mx_market
            THEN
                --labels 
                l_name := concat_other_names(i_lang,
                                             i_prof,
                                             l_first_name,
                                             l_second_name,
                                             l_middle_name,
                                             l_last_name,
                                             i_id_sys_config => 'BARCODE_PATIENT_NAME_PATTERN',
                                             include_sep     => FALSE);
            
                l_name := l_name || concat_other_names(i_lang,
                                                       i_prof,
                                                       l_other_names_1,
                                                       l_other_names_4,
                                                       l_other_names_2,
                                                       l_other_names_3,
                                                       i_id_sys_config => 'BARCODE_PATIENT_NAME_PATTERN');
            ELSE
                l_name := l_name || concat_other_names(i_lang,
                                                       i_prof,
                                                       l_other_names_1,
                                                       l_other_names_4,
                                                       l_other_names_2,
                                                       l_other_names_3,
                                                       i_id_sys_config => 'PATIENT_NAME_PATTERN');
            END IF;
        END IF;
    
        RETURN l_name;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PATIENT_NAME',
                                              o_error    => v_error);
            --pk_utils.undo_changes;
            RETURN NULL;
    END get_patient_name_search;

    FUNCTION get_create_patient_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ext_value          epis_ext_sys.value%TYPE;
        l_external_sys_exist sys_config.value%TYPE := pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST', i_prof);
        l_id_ext_sys         sys_config.value%TYPE := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
        l_exists_ext         VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_default            VARCHAR2(20 CHAR);
        l_actions            t_coll_action;
        i_subject            VARCHAR2(200 CHAR) := 'ADT_PATIENT_CREATE';
    BEGIN
        IF (l_external_sys_exist = pk_alert_constant.g_no)
        THEN
            l_default := 'DEFINITIVE';
        ELSE
            IF l_id_ext_sys = pk_sysconfig.get_config('ADT_EXTERNAL_SYS_IDENTIFIER', i_prof)
            THEN
                l_default := 'DEFINITIVE';
            ELSE
                l_default := 'TEMPORARY';
            END IF;
        END IF;
    
        l_actions := pk_action.tf_get_actions(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_subject    => i_subject,
                                              i_from_state => NULL);
    
        OPEN o_options FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.id_action,
             t.desc_action,
             t.icon,
             decode(l_default, t.action, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default,
             t.flg_active,
             t.action
              FROM TABLE(CAST(l_actions AS t_coll_action)) t
             ORDER BY t.desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CREATE_PATIENT_OPTIONS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_options);
            RETURN FALSE;
    END get_create_patient_options;

    FUNCTION get_epis_type_create
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_flg_type OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ext_value          epis_ext_sys.value%TYPE;
        l_external_sys_exist sys_config.value%TYPE := pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST', i_prof);
        l_id_ext_sys         sys_config.value%TYPE := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
        l_exists_ext         VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
    BEGIN
        IF (l_external_sys_exist = pk_alert_constant.g_no OR i_prof.software <> pk_alert_constant.g_soft_adt)
        THEN
            o_flg_type := 'N';
        ELSE
            IF l_id_ext_sys = pk_sysconfig.get_config('ADT_EXTERNAL_SYS_IDENTIFIER', i_prof)
            THEN
                o_flg_type := 'N';
            ELSE
                o_flg_type := 'Y';
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_EPIS_TYPE_CREATE',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_epis_type_create;

BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);
    -- Advanced Input configurations
    g_all_institution := 0;
    g_all_software    := 0;

    g_lscore_threshold := nvl(pk_sysconfig.get_config('LUCENE_LSCORE_THRESHOLD', profissional(0, 0, 0)), -1);

END pk_adt;
/
