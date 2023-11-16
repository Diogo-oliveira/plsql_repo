/*-- Last Change Revision: $Rev: 2027724 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:07 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_social IS
    --generic exception
    g_sw_generic_exception EXCEPTION;
    g_exception            EXCEPTION;

    g_error        VARCHAR2(4000);
    g_package_name VARCHAR2(30 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_found        BOOLEAN;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_schema_adt CONSTANT all_tab_columns.owner%TYPE := 'ALERT_ADTCOD';

    g_soc_req_status_domain CONSTANT sys_domain.code_domain%TYPE := 'SOCIAL_EPIS_REQUEST.FLG_STATUS';

    g_soc_req_status_pend CONSTANT social_epis_request.flg_status%TYPE := 'P';
    g_soc_req_status_canc CONSTANT social_epis_request.flg_status%TYPE := 'C';
    g_soc_req_status_acc  CONSTANT social_epis_request.flg_status%TYPE := 'A';
    g_soc_req_status_rej  CONSTANT social_epis_request.flg_status%TYPE := 'R';
    g_soc_req_status_dsc  CONSTANT social_epis_request.flg_status%TYPE := 'D';

    -- Alerts
    g_alert_new_request    CONSTANT sys_alert.id_sys_alert%TYPE := 22;
    g_alert_request_answer CONSTANT sys_alert.id_sys_alert%TYPE := 24;

    g_patient_active CONSTANT patient.flg_status%TYPE := 'A';
    g_flg_available  CONSTANT family_monetary.flg_available%TYPE := 'A';
    g_yes_no         CONSTANT sys_domain.code_domain%TYPE := 'YES_NO';

    g_flg_active   CONSTANT VARCHAR2(1) := 'A';
    g_flg_inactive CONSTANT VARCHAR2(1) := 'I';

    /********************************************************************************************
     * This function performs error handling and is used internally by other functions in this package.
     *
     * @param i_lang                Language identifier.
     * @param i_func_proc_name      Function or procedure name.
     * @param i_error               Error message to log.
     * @param i_sqlerror            SQLERRM.
     * @param o_error               Message to be shown to the user.
     *
     * @return                      FALSE (in any case, in order to allow a RETURN error_handling statement in exception
     *                              handling blocks)
     *
     * @author                      SS
     * @version                     0.1
     * @since                       2008/01/10
    **********************************************************************************************/

    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_alert_exceptions.process_error(i_lang,
                                                 NULL,
                                                 i_sqlerror,
                                                 i_error,
                                                 'ALERT',
                                                 'PK_SOCIAL',
                                                 'ERROR_HANDLING',
                                                 o_error);
    END error_handling;

    /********************************************************************************************
     * This function returns the currency pre-defined for the institution.
     *
     * @param  I_PROF   Profissional ID
     *
     * @return          The currency for that intitution
     *
     * @author          Thiago Brito
     * @version         2.4.3
     * @since           2008/05/30
    **********************************************************************************************/
    FUNCTION get_currency_default(i_prof IN profissional) RETURN currency.id_currency%TYPE IS
    
        i_currency_default currency.id_currency%TYPE;
    
    BEGIN
    
        SELECT nvl(ia.id_currency, 1)
          INTO i_currency_default
          FROM inst_attributes ia
         WHERE ia.id_institution = i_prof.institution
           AND ia.flg_available = pk_alert_constant.g_yes;
    
        RETURN i_currency_default;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 1;
    END;

    /********************************************************************************************
     * Create patient's family members
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Patient ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_name                   Family member's name
     * @param i_gender                 Family member's gender
     * @param i_dt_birth               Family member's birth date
     * @param i_id_family_relationship Family relationship     
     * @param i_marital_status         Marital status
     * @param i_scholarship            Scholarship
     * @param i_pension                Pension value
     * @param i_net_wage               Net wage value
     * @param i_unemployment_subsidy   Subsidy value
     * @param i_job                    Job/occupation
     * @param i_prof_cat_type          Professional's category type
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          SS
     * @version                         0.1
     * @since                           2007/12/19
    **********************************************************************************************/

    FUNCTION create_pat_family
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_pat                 IN patient.id_patient%TYPE,
        i_prof                   IN profissional,
        i_name                   IN patient.name%TYPE,
        i_gender                 IN patient.gender%TYPE,
        i_dt_birth               IN patient.dt_birth%TYPE,
        i_id_family_relationship IN pat_family_member.id_family_relationship%TYPE,
        i_marital_status         IN pat_soc_attributes.marital_status%TYPE,
        i_scholarship            IN pat_soc_attributes.id_scholarship%TYPE,
        i_pension                IN pat_soc_attributes.pension%TYPE,
        i_currency_pension       IN currency.id_currency%TYPE,
        i_net_wage               IN pat_soc_attributes.net_wage%TYPE,
        i_currency_net_wage      IN currency.id_currency%TYPE,
        i_unemployment_subsidy   IN pat_soc_attributes.unemployment_subsidy%TYPE,
        i_currency_unemp_sub     IN currency.id_currency%TYPE,
        i_job                    IN pat_job.id_occupation%TYPE,
        i_occupation_desc        IN pat_job.occupation_desc%TYPE,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        IF NOT pk_social.create_pat_family_internal(i_lang                   => i_lang,
                                                    i_id_pat                 => i_id_pat,
                                                    i_id_new_pat             => NULL,
                                                    i_prof                   => i_prof,
                                                    i_name                   => i_name,
                                                    i_gender                 => i_gender,
                                                    i_dt_birth               => i_dt_birth,
                                                    i_id_family_relationship => i_id_family_relationship,
                                                    i_marital_status         => i_marital_status,
                                                    i_scholarship            => i_scholarship,
                                                    i_pension                => i_pension,
                                                    i_currency_pension       => i_currency_pension,
                                                    i_net_wage               => i_net_wage,
                                                    i_currency_net_wage      => i_currency_net_wage,
                                                    i_unemployment_subsidy   => i_unemployment_subsidy,
                                                    i_currency_unemp_sub     => i_currency_unemp_sub,
                                                    i_job                    => i_job,
                                                    i_occupation_desc        => i_occupation_desc,
                                                    i_prof_cat_type          => i_prof_cat_type,
                                                    i_epis                   => i_epis,
                                                    o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SOCIAL',
                                              'CREATE_PAT_FAMILY',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            BEGIN
                pk_utils.undo_changes;
            
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  'PK_SOCIAL',
                                                  'CREATE_PAT_FAMILY',
                                                  o_error);
            
                pk_alert_exceptions.reset_error_state();
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************
     * Create patient's family members
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Patient ID
     * @param i_id_new_pat             New patient to be add to the family
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_name                   Family member's name
     * @param i_gender                 Family member's gender
     * @param i_dt_birth               Family member's birth date
     * @param i_id_family_relationship Family relationship     
     * @param i_marital_status         Marital status
     * @param i_scholarship            Scholarship
     * @param i_pension                Pension value
     * @param i_net_wage               Net wage value
     * @param i_unemployment_subsidy   Subsidy value
     * @param i_job                    Job/occupation
     * @param i_prof_cat_type          Professional's category type
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          SS
     * @version                         0.1
     * @since                           2007/12/19
    **********************************************************************************************/

    FUNCTION create_pat_family_internal
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_pat                 IN patient.id_patient%TYPE,
        i_id_new_pat             IN patient.id_patient%TYPE,
        i_prof                   IN profissional,
        i_name                   IN patient.name%TYPE,
        i_gender                 IN patient.gender%TYPE,
        i_dt_birth               IN patient.dt_birth%TYPE,
        i_id_family_relationship IN pat_family_member.id_family_relationship%TYPE,
        i_marital_status         IN pat_soc_attributes.marital_status%TYPE,
        i_scholarship            IN pat_soc_attributes.id_scholarship%TYPE,
        i_pension                IN pat_soc_attributes.pension%TYPE,
        i_currency_pension       IN currency.id_currency%TYPE,
        i_net_wage               IN pat_soc_attributes.net_wage%TYPE,
        i_currency_net_wage      IN currency.id_currency%TYPE,
        i_unemployment_subsidy   IN pat_soc_attributes.unemployment_subsidy%TYPE,
        i_currency_unemp_sub     IN currency.id_currency%TYPE,
        i_job                    IN pat_job.id_occupation%TYPE,
        i_occupation_desc        IN pat_job.occupation_desc%TYPE,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_inst_type IS
            SELECT flg_type
              FROM institution
             WHERE id_institution = i_prof.institution;
    
        l_next_pat   patient.id_patient%TYPE;
        l_error      t_error_out;
        l_pat_family patient.id_pat_family%TYPE;
        l_inst_type  institution.flg_type%TYPE;
        l_rowids     table_varchar;
        l_id_patient table_number;
    
        CURSOR c_family_brother IS
            SELECT pf.id_patient
              FROM pat_family_member pf
             WHERE pf.id_pat_related = l_next_pat
               AND pf.id_family_relationship = g_id_fam_rel_mother
               AND id_patient <> i_id_pat
               AND flg_status = g_flg_active;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN C_INST_TYPE';
        OPEN c_inst_type;
        FETCH c_inst_type
            INTO l_inst_type;
        CLOSE c_inst_type;
    
        IF l_inst_type = 'C'
        THEN
            --it's not possible to create family members in CARE
            RETURN error_handling(i_lang           => i_lang,
                                  i_func_proc_name => 'CREATE_PAT_FAMILY',
                                  i_error          => g_error,
                                  i_sqlerror       => pk_message.get_message(i_lang, 'SOCIAL_M009'),
                                  o_error          => o_error);
        END IF;
    
        IF i_name IS NULL
        THEN
            --name is mandatory
            RETURN error_handling(i_lang           => i_lang,
                                  i_func_proc_name => 'CREATE_PAT_FAMILY',
                                  i_error          => g_error,
                                  i_sqlerror       => pk_message.get_message(i_lang, 'SOCIAL_M014'),
                                  o_error          => o_error);
        END IF;
    
        -- verificar se o paciente j?em id_pat_family associado
        --cannot commit here
        IF NOT set_pat_fam(i_lang       => i_lang,
                           i_id_pat     => i_id_pat,
                           i_prof       => i_prof,
                           o_id_pat_fam => l_pat_family,
                           o_error      => l_error)
        THEN
            o_error := l_error;
            RAISE g_exception;
        END IF;
    
        IF i_id_new_pat IS NULL
        THEN
        
            g_error := 'GET SEQ_PATIENT.NEXTVAL';
            SELECT ts_patient.next_key
              INTO l_next_pat
              FROM dual;
        
            g_error := 'INSERT INTO PATIENT';
            ts_patient.ins(id_patient_in    => l_next_pat,
                           name_in          => i_name,
                           nick_name_in     => i_name,
                           gender_in        => i_gender,
                           dt_birth_in      => i_dt_birth,
                           id_pat_family_in => l_pat_family,
                           flg_status_in    => g_flg_active,
                           rows_out         => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PATIENT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'INSERT INTO PAT_SOC_ATTRIBUTES';
            ts_pat_soc_attributes.ins(id_patient_in            => l_next_pat,
                                      marital_status_in        => i_marital_status,
                                      id_scholarship_in        => i_scholarship,
                                      id_institution_in        => i_prof.institution,
                                      id_language_in           => i_lang,
                                      pension_in               => i_pension,
                                      id_currency_pension_in   => i_currency_pension,
                                      net_wage_in              => i_net_wage,
                                      id_currency_net_wage_in  => i_currency_net_wage,
                                      unemployment_subsidy_in  => i_unemployment_subsidy,
                                      id_currency_unemp_sub_in => i_currency_unemp_sub,
                                      id_episode_in            => i_epis,
                                      rows_out                 => l_rowids);
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_SOC_ATTRIBUTES';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_SOC_ATTRIBUTES',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            /*g_error := 'INSERT INTO PAT_JOB';
            ts_pat_job.ins(id_patient_in      => l_next_pat,
                           flg_status_in      => 'A',
                           id_occupation_in   => i_job,
                           occupation_desc_in => NULL,
                           dt_pat_job_tstz_in => g_sysdate_tstz,
                           id_institution_in  => i_prof.institution,
                           id_episode_in      => i_epis,
                           rows_out           => l_rowids);*/
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_JOB';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_JOB',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSE
            l_next_pat := i_id_new_pat;
        END IF;
    
        g_error := 'INSERT INTO PAT_FAMILY_MEMBER';
        ts_pat_family_member.ins(id_patient_in             => i_id_pat,
                                 id_pat_related_in         => l_next_pat,
                                 id_family_relationship_in => i_id_family_relationship,
                                 id_pat_family_in          => l_pat_family,
                                 id_institution_in         => i_prof.institution,
                                 flg_status_in             => g_flg_active,
                                 id_episode_in             => i_epis,
                                 rows_out                  => l_rowids);
        IF i_id_family_relationship = g_id_fam_rel_mother
        THEN
            OPEN c_family_brother;
            FETCH c_family_brother BULK COLLECT
                INTO l_id_patient;
            g_found := c_family_brother%NOTFOUND;
            CLOSE c_family_brother;
        
            IF l_id_patient IS NOT NULL
               AND l_id_patient.exists(1)
            THEN
                FOR i IN l_id_patient.first .. l_id_patient.last
                LOOP
                    ts_pat_family_member.ins(id_patient_in             => i_id_pat,
                                             id_pat_related_in         => l_id_patient(i),
                                             id_family_relationship_in => g_id_fam_rel_brother,
                                             id_pat_family_in          => l_pat_family,
                                             id_institution_in         => i_prof.institution,
                                             flg_status_in             => g_flg_active,
                                             id_episode_in             => i_epis,
                                             rows_out                  => l_rowids);
                
                    ts_pat_family_member.ins(id_patient_in             => l_id_patient(i),
                                             id_pat_related_in         => i_id_pat,
                                             id_family_relationship_in => g_id_fam_rel_brother,
                                             id_pat_family_in          => l_pat_family,
                                             id_institution_in         => i_prof.institution,
                                             flg_status_in             => g_flg_active,
                                             id_episode_in             => i_epis,
                                             rows_out                  => l_rowids);
                END LOOP;
            END IF;
        
        END IF;
        g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_FAMILY_MEMBER';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_FAMILY_MEMBER',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SOCIAL',
                                              'CREATE_PAT_FAMILY_INTERNAL',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'CREATE_PAT_FAMILY_INTERNAL',
                                                     o_error);
    END create_pat_family_internal;

    /********************************************************************************************
     * Get patient's family grid 
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat                    Family grid
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @depracated                     The funciton get_household replaces this one
     *
     * @author                          ASM
     * @version                         0.1
     * @since                           2006/11/06
    **********************************************************************************************/
    FUNCTION get_family_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_pat      OUT pk_types.cursor_type,
        o_pat_prob OUT pk_types.cursor_type,
        o_epis     OUT pk_types.cursor_type,
        o_shortcut OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_has_records      VARCHAR2(1 CHAR) := 'N';
        c_pat_prob         pk_types.cursor_type;
        l_cursor_param     table_table_varchar := table_table_varchar();
        l_id_pat_table     table_varchar := table_varchar();
        l_prob_desc_table  table_varchar := table_varchar();
        l_id_patient_table table_varchar := table_varchar();
    
        l_id_pat_family_member  table_number := table_number();
        l_id_patient            table_number := table_number();
        l_pat_num_family_record pat_family.num_family_record%TYPE;
        l_id_pat_family         pat_family_member.id_pat_family%TYPE;
    
        CURSOR c_patient IS
            SELECT p.id_patient id_patient
              FROM patient p
             WHERE p.id_patient IN (SELECT id_patient
                                      FROM pat_family_member pfm
                                     WHERE pfm.id_pat_family = (SELECT id_pat_family
                                                                  FROM pat_family_member pfm
                                                                 WHERE pfm.id_patient = i_id_pat
                                                                   AND rownum = 1))
            UNION
            SELECT i_id_pat id_patient
              FROM dual
             ORDER BY id_patient;
    
    BEGIN
        l_cursor_param.extend(21);
    
        BEGIN
            SELECT pf.num_family_record, pfm.id_pat_family
              INTO l_pat_num_family_record, l_id_pat_family
              FROM pat_family pf, pat_family_member pfm
             WHERE pfm.id_pat_family = pf.id_pat_family
               AND pfm.id_patient = i_id_pat
               AND pfm.flg_status = 'A'
               AND pfm.create_time = (SELECT MAX(create_time)
                                        FROM pat_family_member
                                       WHERE id_patient = i_id_pat
                                         AND flg_status = 'A')
               AND rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                l_pat_num_family_record := NULL;
        END;
    
        g_error := 'GET CURSOR O_PAT';
        IF i_prof.software = pk_alert_constant.g_soft_primary_care
        THEN
        
            SELECT id_pat_family_member, id_patient
              BULK COLLECT
              INTO l_id_pat_family_member, l_id_patient
              FROM (SELECT pfm.id_pat_family_member, pfm.id_patient
                      FROM pat_family_member pfm
                     WHERE pfm.id_pat_family = l_id_pat_family
                       AND create_time IN
                           (SELECT MAX(pfm.create_time)
                              FROM pat_family_member pfm
                             WHERE id_patient IN (SELECT id_patient
                                                    FROM pat_family_member pfm
                                                   WHERE pfm.flg_status = 'A'
                                                     AND pfm.id_pat_family = l_id_pat_family)
                             GROUP BY id_patient)
                    UNION ALL
                    SELECT pfm.id_pat_family_member, pfm.id_patient
                      FROM pat_family_member pfm, pat_family pf
                     WHERE pf.id_pat_family = pfm.id_pat_family
                       AND pfm.flg_status = 'A'
                       AND pf.num_family_record = l_pat_num_family_record
                       AND l_pat_num_family_record IS NOT NULL
                    UNION ALL
                    SELECT pfm.id_pat_family_member, pfm.id_patient
                      FROM pat_family_member pfm, pat_family pf
                     WHERE pf.id_pat_family = pfm.id_pat_family
                       AND pfm.flg_status = 'A'
                       AND pfm.id_pat_related = i_id_pat
                       AND l_pat_num_family_record IS NULL);
        
            OPEN o_pat FOR
                SELECT p.id_patient,
                       i_id_pat id_pat_origin,
                       NULL id_pat_family_member,
                       p.gender,
                       pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                       decode(pk_patphoto.check_blob(p.id_patient),
                              'N',
                              '',
                              pk_patphoto.get_pat_foto(p.id_patient, i_prof)) photo,
                       -- ALERT-189121
                       nvl(decode(p.id_patient,
                                  i_id_pat,
                                  NULL,
                                  pk_translation.get_translation(i_lang,
                                                                 'FAMILY_RELATIONSHIP.CODE_FAMILY_RELATIONSHIP.' ||
                                                                 pfm.id_family_relationship)),
                           '--') family_relationship,
                       p.name,
                       decode(pj.id_occupation,
                              NULL,
                              '--',
                              pk_translation.get_translation(i_lang, 'OCCUPATION.CODE_OCCUPATION.' || pj.id_occupation)) occupation,
                       nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, pfp.id_professional), '--') doctor_nick_name,
                       NULL inst_type
                  FROM patient p,
                       pat_family_prof pfp,
                       pat_job pj,
                       (SELECT *
                          FROM pat_family_member
                         WHERE id_pat_family_member IN (SELECT *
                                                          FROM TABLE(l_id_pat_family_member))) pfm
                 WHERE p.id_patient IN (SELECT /*+opt_estimate(table t rows=1)*/
                                         *
                                          FROM TABLE(l_id_patient) t)
                   AND p.id_patient = pfp.id_patient(+)
                   AND pfp.flg_status(+) = 'A'
                   AND p.id_patient = pj.id_patient(+)
                   AND pj.flg_status(+) = 'A'
                   AND p.id_patient = pfm.id_patient(+)
                   AND pfm.id_pat_related(+) = i_id_pat
                 ORDER BY id_patient;
        
        ELSE
            OPEN o_pat FOR
                SELECT DISTINCT p.id_patient,
                                i_id_pat id_pat_origin,
                                decode(p.id_patient, i_id_pat, NULL, pfm.id_pat_family_member) id_pat_family_member,
                                (SELECT pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang) gender
                                   FROM dual) gender,
                                pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                                decode(pk_patphoto.check_blob(p.id_patient),
                                       'N',
                                       '',
                                       pk_patphoto.get_pat_foto(p.id_patient, i_prof)) photo,
                                decode(p.id_patient,
                                       i_id_pat,
                                       NULL,
                                       pk_translation.get_translation(i_lang, fr.code_family_relationship)) family_relationship,
                                pk_patient.get_pat_name(i_lang, i_prof, p.id_patient, NULL, NULL) name,
                                decode(pj.id_occupation,
                                       NULL,
                                       occupation_desc,
                                       pk_translation.get_translation(i_lang, oc.code_occupation)) occupation,
                                (SELECT DISTINCT pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) --FM 2009/03/19
                                   FROM pat_family_prof pfp, professional prof
                                  WHERE pfp.id_patient = i_id_pat
                                    AND pfp.id_pat_family = pfm.id_pat_family
                                    AND pfp.id_institution = i_prof.institution
                                    AND pfp.id_professional = prof.id_professional) doctor_nick_name,
                                inst.flg_type inst_type
                  FROM patient p,
                       pat_family_member pfm,
                       family_relationship fr,
                       pat_job pj,
                       occupation oc,
                       institution inst,
                       (SELECT i_id_pat id_pat_related
                          FROM dual
                        UNION ALL
                        SELECT id_pat_related
                          FROM pat_family_member pfm2
                         WHERE pfm2.id_patient = i_id_pat
                           AND pfm2.flg_status = 'A') pf_mem
                 WHERE p.id_patient = pf_mem.id_pat_related
                   AND p.id_patient = pfm.id_pat_related(+)
                   AND (pfm.id_patient = i_id_pat OR pfm.id_pat_related = i_id_pat OR pfm.id_pat_related IS NULL)
                   AND pfm.id_family_relationship = fr.id_family_relationship(+)
                   AND p.id_patient = pj.id_patient(+)
                   AND pj.flg_status(+) = 'A'
                   AND pfm.flg_status(+) = 'A'
                   AND pj.id_occupation = oc.id_occupation(+)
                   AND inst.id_institution = i_prof.institution
                 ORDER BY p.id_patient;
        END IF;
    
        g_error := 'OPEN c_patient';
        OPEN c_patient;
        FETCH c_patient BULK COLLECT
            INTO l_id_patient_table;
        g_found := c_patient%NOTFOUND;
        CLOSE c_patient;
    
        FOR i IN l_id_patient_table.first .. l_id_patient_table.last
        LOOP
            g_error := 'GET CURSOR C_PAT_PROB #' || to_char(i);
            IF NOT pk_problems.get_ordered_list(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_patient      => l_id_patient_table(i),
                                                o_ordered_list => c_pat_prob)
            THEN
                RETURN FALSE;
            END IF;
        
            l_has_records := 'Y';
            BEGIN
                g_error := 'FETCH C_ANALYSIS';
                FETCH c_pat_prob BULK COLLECT
                    INTO l_cursor_param(1),
                         l_cursor_param(2),
                         l_cursor_param(3),
                         l_cursor_param(4), --
                         l_cursor_param(5),
                         l_cursor_param(6),
                         l_cursor_param(7),
                         l_cursor_param(8), --
                         l_cursor_param(9),
                         l_cursor_param(10),
                         l_cursor_param(11),
                         l_cursor_param(12), --
                         l_cursor_param(13),
                         l_cursor_param(14),
                         l_cursor_param(15),
                         l_cursor_param(16),
                         l_cursor_param(17),
                         l_cursor_param(18),
                         l_cursor_param(19),
                         l_cursor_param(20),
                         l_cursor_param(21);
            
                FOR j IN l_cursor_param(2).first .. l_cursor_param(2).last
                LOOP
                    l_id_pat_table.extend;
                    l_id_pat_table(l_id_pat_table.last) := l_id_patient_table(i);
                END LOOP;
            
                l_prob_desc_table := l_prob_desc_table MULTISET UNION l_cursor_param(2); -- desc_probl
            
            EXCEPTION
                WHEN OTHERS THEN
                    l_has_records := 'N';
            END;
        END LOOP;
    
        IF l_id_pat_table.count != 0
        THEN
            g_error := 'OPEN o_pat_prob';
            OPEN o_pat_prob FOR
                SELECT a.column_value id_patient, b.column_value desc_probl
                  FROM (SELECT rownum rnum, column_value
                          FROM TABLE(l_id_pat_table)) a,
                       (SELECT rownum rnum, column_value
                          FROM TABLE(l_prob_desc_table)) b
                 WHERE a.rnum = b.rnum;
        ELSE
            pk_types.open_my_cursor(o_pat_prob);
        END IF;
    
        OPEN o_epis FOR
            SELECT e.id_episode, ei.id_patient, ei.id_schedule, ei.id_software
              FROM episode e, epis_info ei
             WHERE ei.id_patient IN (SELECT i_id_pat id_pat_related
                                       FROM dual
                                     UNION ALL
                                     SELECT id_pat_related
                                       FROM pat_family_member pfm
                                      WHERE pfm.id_patient = i_id_pat
                                        AND pfm.flg_status = 'A')
               AND e.flg_status = 'A'
               AND e.id_episode = ei.id_episode
               AND ei.id_software = i_prof.software;
    
        o_shortcut := pk_sysconfig.get_config(i_code_cf => g_config_family_shortcut, i_prof => i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat);
            pk_types.open_my_cursor(o_pat_prob);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_FAMILY_GRID',
                                                     o_error);
        
    END get_family_grid;

    /******************************************************************************
       OBJECTIVO:   Registar o familiar do paciente
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
               I_ID_PAT - ID do paciente.
        
              Saida:   O_ID_PAT_FAM - ID do familiar
                             O_ERROR - erro
        
      CRIAÇÃO: ET 2006/04/13
      NOTAS:
    *********************************************************************************/
    FUNCTION set_pat_fam
    (
        i_lang       IN language.id_language%TYPE,
        i_id_pat     IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        o_id_pat_fam OUT patient.id_pat_family%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT set_pat_fam(i_lang       => i_lang,
                           i_id_pat     => i_id_pat,
                           i_prof       => i_prof,
                           i_commit     => pk_alert_constant.get_yes,
                           o_id_pat_fam => o_id_pat_fam,
                           o_error      => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'SET_PAT_FAM',
                                                     o_error);
        
    END set_pat_fam;
    --

    /******************************************************************************
       OBJECTIVO:   Registar o familiar do paciente
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
               I_ID_PAT - ID do paciente.
        
              Saida:   O_ID_PAT_FAM - ID do familiar
                             O_ERROR - erro
        
      CRIAÇÃO: ET 2006/04/13
      NOTAS:
    *********************************************************************************/
    FUNCTION set_pat_fam
    (
        i_lang       IN language.id_language%TYPE,
        i_id_pat     IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_commit     IN VARCHAR2,
        o_id_pat_fam OUT patient.id_pat_family%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_pat_fam patient.id_pat_family%TYPE;
        l_name       patient.name%TYPE;
    
        CURSOR c_pat IS
            SELECT id_pat_family
              FROM patient p
             WHERE p.id_patient = i_id_pat
               AND id_pat_family IS NOT NULL;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET CURSOR C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO l_id_pat_fam;
        g_found := c_pat%NOTFOUND;
        CLOSE c_pat;
        --
        IF g_found
        THEN
        
            g_error := 'GET SEQ_PAT_FAMILY.NEXTVAL';
            SELECT seq_pat_family.nextval
              INTO o_id_pat_fam
              FROM dual;
            --
            g_error := 'GET PATIENT NAME';
            SELECT name
              INTO l_name
              FROM patient
             WHERE id_patient = i_id_pat;
        
            --
            g_error := 'INSERT PAT_FAMILY';
            INSERT INTO pat_family
                (id_pat_family, name, id_institution, adw_last_update)
            VALUES
                (o_id_pat_fam, l_name, i_prof.institution, SYSDATE);
        
            g_error := 'UPDATE PATIENT';
            UPDATE patient
               SET id_pat_family = o_id_pat_fam
             WHERE id_patient = i_id_pat;
        
        ELSE
            o_id_pat_fam := l_id_pat_fam;
        END IF;
    
        IF i_commit = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL pk_visit.set_first_obs';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => NULL,
                                          i_pat                 => i_id_pat,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
            --
        
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'SET_PAT_FAM',
                                                     o_error);
        
    END set_pat_fam;

    /********************************************************************************************
     * Get total and per capita family budget.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_allowance_family        Abonos
     * @param i_allowance_complementary Abonos complementares ID
     * @param i_subsidy                 Subsídios
     * @param i_other                   Outros
     * @param i_fixed_expenses          Despesas fixas
     * @param i_total                   Total do rendimento do agregado familiar do paciente
     * @param i_tot_person              Nº de pessoas do agragado familiar do paciente
     * @param o_tots                    Total and per capita family budget
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           ET
     * @version                          0.1
     * @since                            2006/05/08
    **********************************************************************************************/

    FUNCTION get_tot_money
    (
        i_lang                    IN language.id_language%TYPE,
        i_allowance_family        IN family_monetary.allowance_family%TYPE,
        i_allowance_complementary IN family_monetary.allowance_complementary%TYPE,
        i_subsidy                 IN family_monetary.subsidy%TYPE,
        i_other                   IN family_monetary.other%TYPE,
        i_fixed_expenses          IN family_monetary.fixed_expenses%TYPE,
        i_total                   IN family_monetary.subsidy%TYPE,
        i_tot_person              IN NUMBER,
        o_tots                    OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rend_capita NUMBER;
        l_tot_alt     NUMBER;
    
    BEGIN
    
        l_tot_alt := i_total;
    
        IF nvl(i_allowance_family, 0) > 0
        THEN
            l_tot_alt := nvl(l_tot_alt, 0) + nvl(i_allowance_family, 0);
        END IF;
    
        IF nvl(i_allowance_complementary, 0) > 0
        THEN
            l_tot_alt := nvl(l_tot_alt, 0) + nvl(i_allowance_complementary, 0);
        END IF;
    
        IF nvl(i_subsidy, 0) > 0
        THEN
            l_tot_alt := nvl(l_tot_alt, 0) + nvl(i_subsidy, 0);
        END IF;
    
        IF nvl(i_other, 0) > 0
        THEN
            l_tot_alt := nvl(l_tot_alt, 0) + nvl(i_other, 0);
        END IF;
    
        /*IF nvl(i_fixed_expenses, 0) > 0
        THEN
            l_tot_alt := nvl(l_tot_alt, 0) - nvl(i_fixed_expenses, 0);
        END IF;*/
    
        IF nvl(i_tot_person, 0) <> 0
        THEN
            l_rend_capita := (l_tot_alt - nvl(i_fixed_expenses, 0)) / i_tot_person;
        ELSE
            l_rend_capita := 0;
        END IF;
    
        OPEN o_tots FOR
            SELECT nvl(l_tot_alt, 0) tot, nvl(round(l_rend_capita, 2), 0) rend_capita
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_TOT_MONEY',
                                                     o_error);
        
    END;

    /********************************************************************************************
     * Save family monetary situation.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_id_pat                  Patient ID
     * @param i_id_fam_money            Family monetary situation ID
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_allowance_family        Abonos
     * @param i_allowance_complementary Abonos complementares ID
     * @param i_other                   Outros
     * @param i_subsidy                 Subsídios
     * @param i_fixed_expenses          Despesas fixas
     * @param i_notes                   Notes
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           ET
     * @version                          0.1
     * @since                            2006/04/13
    **********************************************************************************************/

    --
    --
    --
    FUNCTION get_total_fam_mem_scalar(i_id_pat IN patient.id_patient%TYPE) RETURN NUMBER IS
    
        tot_people PLS_INTEGER;
    
    BEGIN
    
        g_error := 'GET_TOTAL_FAM_MEM_SCALAR - SELECT INTO';
    
        SELECT COUNT(*) tot_person
          INTO tot_people
          FROM ( --the patient
                SELECT pat.id_pat_family, pat.id_patient, pat.name, psa.pension, psa.net_wage, psa.unemployment_subsidy
                  FROM patient pat, pat_soc_attributes psa
                 WHERE pat.id_patient = i_id_pat
                   AND pat.flg_status = g_flg_active
                   AND psa.id_patient(+) = pat.id_patient
                UNION
                -- results with family relantioship
                SELECT pfm.id_pat_family, pat.id_patient, pat.name, psa.pension, psa.net_wage, psa.unemployment_subsidy
                  FROM patient pat_init, patient pat, pat_family_member pfm, pat_soc_attributes psa
                 WHERE pat_init.id_patient = i_id_pat
                   AND pat_init.id_pat_family = pat.id_pat_family
                   AND pat.flg_status(+) = g_flg_active
                   AND pat_init.id_patient = pfm.id_patient
                   AND pat.id_patient = pfm.id_pat_related
                   AND pfm.flg_status(+) = g_flg_active
                   AND psa.id_patient(+) = pat.id_patient
                UNION
                -- results without family relationship
                SELECT pat.id_pat_family, pat.id_patient, pat.name, psa.pension, psa.net_wage, psa.unemployment_subsidy
                  FROM patient pat_init, patient pat, pat_soc_attributes psa
                 WHERE pat_init.id_patient = i_id_pat
                   AND pat_init.id_pat_family = pat.id_pat_family
                   AND pat.flg_status(+) = g_flg_active
                   AND psa.id_patient(+) = pat.id_patient
                      -- except for results with existing family relationship
                   AND pat.id_patient NOT IN
                       (SELECT pat.id_patient
                          FROM patient pat_init, patient pat, pat_family_member pfm, family_relationship fr
                         WHERE pat_init.id_patient = i_id_pat
                           AND pat_init.id_pat_family = pat.id_pat_family
                           AND pat.flg_status(+) = g_flg_active
                           AND fr.id_family_relationship(+) = pfm.id_family_relationship
                           AND pat_init.id_patient = pfm.id_patient
                           AND pat.id_patient = pfm.id_pat_related
                           AND pfm.flg_status(+) = g_flg_active
                           AND fr.flg_available = pk_alert_constant.g_yes)) pm
         GROUP BY pm.id_pat_family;
    
        RETURN tot_people;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN 0;
        
    END get_total_fam_mem_scalar;
    --

    FUNCTION get_val_graf_crit
    (
        i_lang             IN language.id_language%TYPE,
        i_id_pat           IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        i_id_pat_graf_crit IN graffar_criteria.id_graffar_criteria%TYPE,
        o_val_g_crit       OUT graffar_crit_value.val%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Devolver o valor do critério da classe social
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                 I_ID_PAT - Id do doente
                 I_P ROF - profissional q regista
                                 I_ID_GRAF_CRIT - ID do critério
        
                  Saida: O_VAL_G_CRIT - Retorna o valor do critério social
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/04/27
          NOTAS:
        *********************************************************************************/
        CURSOR c_val_g_crit IS
            SELECT gcv.val
              FROM pat_graffar_crit pgc, graffar_crit_value gcv, graffar_criteria gc
             WHERE pgc.id_patient = i_id_pat
                  --AND pgc.id_professional = i_prof.id
               AND pgc.id_graffar_crit_value = gcv.id_graffar_crit_value
               AND gc.id_graffar_criteria = gcv.id_graffar_criteria
               AND gc.id_graffar_criteria = i_id_pat_graf_crit;
    
    BEGIN
        g_error := 'GET O_VAL_G_CRIT';
    
        OPEN c_val_g_crit;
        FETCH c_val_g_crit
            INTO o_val_g_crit;
        CLOSE c_val_g_crit;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_VAL_GRAF_CRIT',
                                                     o_error);
        
    END;

    FUNCTION get_social_class
    (
        i_lang            IN language.id_language%TYPE,
        i_class_number    IN social_class.val_max%TYPE,
        o_id_social_class OUT social_class.id_social_class%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Devolver o código da classe social
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_CLASS_NUMBER - valor total dos critérios
        
                  Saida: O_ID_CLASS_SOCIAL - ID da classe social
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/04/27
          NOTAS:
        *********************************************************************************/
        CURSOR c_id_class IS
            SELECT id_social_class
              FROM social_class
             WHERE val_min <= i_class_number
               AND val_max >= i_class_number
               AND flg_available = pk_alert_constant.g_yes;
    
    BEGIN
        g_error := 'GET CURSOR C_ID_CLASS';
        OPEN c_id_class;
        FETCH c_id_class
            INTO o_id_social_class;
        CLOSE c_id_class;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_SOCIAL_CLASS',
                                                     o_error);
        
    END;
    --

    /********************************************************************************************
     * Get family relationships list.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_gender                 Gender
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_relationship           List
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          SS
     * @version                         0.1
     * @since                           2007/12/24
    **********************************************************************************************/

    FUNCTION get_relationship_list
    (
        i_lang         IN language.id_language%TYPE,
        i_gender       IN patient.gender%TYPE,
        i_prof         IN profissional,
        o_relationship OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR O_RELATIONSHIP';
        OPEN o_relationship FOR
            SELECT fr.id_family_relationship,
                   fr.gender,
                   pk_translation.get_translation(i_lang, fr.code_family_relationship) desc_relationship
              FROM family_relationship fr
             WHERE gender IN (nvl(i_gender, gender), 'T')
               AND fr.flg_available = pk_alert_constant.g_yes
             ORDER BY desc_relationship;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_relationship);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_RELATIONSHIP_LIST',
                                                     o_error);
        
    END;

    FUNCTION get_flg_wc_location_list
    (
        i_lang            IN language.id_language%TYPE,
        o_flg_wc_location OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista da localização dos Modos de lançamento no exterior
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
        
                  Saida: O_FLG_WC_LOCATION - Localização do Modo de lançamento no exterior
                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/04/18
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_FLG_WC_LOCATION';
        OPEN o_flg_wc_location FOR
            SELECT val data, flg_wc_location label
              FROM (SELECT val, rank, desc_val flg_wc_location
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_flg_wc_location
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = 'Y'
                     ORDER BY rank, flg_wc_location ASC);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_flg_wc_location);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_FLG_WC_LOCATION_LIST',
                                                     o_error);
        
    END;

    FUNCTION get_flg_water_origin_list
    (
        i_lang             IN language.id_language%TYPE,
        o_flg_water_origin OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista das origens da água
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
        
                  Saida: O_FLG_WATER_ORIGIN - Origem da água
                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/04/18
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_FLG_WATER_ORIGIN';
        OPEN o_flg_water_origin FOR
            SELECT val data, flg_water_origin label
              FROM (SELECT val, rank, desc_val flg_water_origin
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_flg_water_origin
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = 'Y'
                     ORDER BY rank, flg_water_origin ASC);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_flg_water_origin);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_FLG_WATER_ORIGIN_LIST',
                                                     o_error);
        
    END;

    FUNCTION get_flg_conserv_list
    (
        i_lang        IN language.id_language%TYPE,
        o_flg_conserv OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista dos estados de conservação da habitação
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
        
                  Saida: O_FLG_CONSERV - estado de conservação
                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/04/18
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_FLG_CONSERV';
        OPEN o_flg_conserv FOR
            SELECT val data, flg_conserv label
              FROM (SELECT val, rank, desc_val flg_conserv
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_flg_conserv
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = 'Y'
                     ORDER BY rank, flg_conserv ASC);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_flg_conserv);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_FLG_CONSERV_LIST',
                                                     o_error);
        
    END;

    FUNCTION get_flg_owner_list
    (
        i_lang      IN language.id_language%TYPE,
        o_flg_owner OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista dos regimes de posse da habitação
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
        
                  Saida: O_FLG_OWNER- Regime de posse
                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/04/18
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_FLG_OWNER';
        OPEN o_flg_owner FOR
            SELECT val data, flg_owner label
              FROM (SELECT val, rank, desc_val flg_owner
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_flg_owner
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = 'Y'
                     ORDER BY rank, flg_owner ASC);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_flg_owner);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_FLG_OWNER_LIST',
                                                     o_error);
        
    END;

    FUNCTION get_flg_hab_type_list
    (
        i_lang         IN language.id_language%TYPE,
        o_flg_hab_type OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista dos tipos de habitação
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
        
                  Saida: O_FLG_HAB_TYPE- Tipo de Habitação
                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/04/18
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_FLG_HAB_TYPE';
        OPEN o_flg_hab_type FOR
            SELECT val data, flg_hab_type label
              FROM (SELECT val, rank, desc_val flg_hab_type
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_flg_hab_type
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = 'Y'
                     ORDER BY rank, flg_hab_type ASC);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_flg_hab_type);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_FLG_HAB_TYPE_LIST',
                                                     o_error);
        
    END;

    /********************************************************************************************
     * Get home location list.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_flg_hab_location       List
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/12/18
    **********************************************************************************************/

    FUNCTION get_flg_hab_location_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        o_flg_hab_location OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR o_flg_hab_LOCATION';
        OPEN o_flg_hab_location FOR
            SELECT val data, flg_hab_location label
              FROM (SELECT val, rank, desc_val flg_hab_location
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND code_domain = g_domain_flg_hab_location
                       AND flg_available = 'Y'
                     ORDER BY rank, flg_hab_location ASC);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_FLG_HAB_LOCATION_LIST',
                                                     o_error);
        
    END;

    FUNCTION get_flg_light_list
    (
        i_lang      IN language.id_language%TYPE,
        o_flg_light OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista da ou não Exist¿ncia de Luz
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
        
                  Saida: O_FLG_LIGHT - Exist¿ncia de Luz
                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/04/18
          NOTAS:
        *********************************************************************************/
    
    BEGIN
        g_error := 'GET CURSOR O_FLG_LIGHT';
        OPEN o_flg_light FOR
            SELECT val data, flg_light label
              FROM (SELECT val, rank, desc_val flg_light
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_yes_no
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = 'Y'
                     ORDER BY rank, flg_light ASC);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_flg_light);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_FLG_LIGHT_LIST',
                                                     o_error);
        
    END;

    FUNCTION get_soc_epis_req_epis
    (
        i_lang    IN language.id_language%TYPE,
        i_id_epis IN social_episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_s_epis  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Consultar TODOS os pareceres sociais do epis¿dio clinico
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_ID_EPIS - ID do Epis¿dio
        
                Saida:   O_S_EPIS - Retorna os pareceres sociais do episodio clinico
                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/04/24
          NOTAS:
          DEPRECATED: use GET_REQUEST
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_S_EPIS(1)';
        OPEN o_s_epis FOR
            SELECT notes, name, date_req, special
              FROM (SELECT ser.notes,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name, --FM 2009/03/19
                           pk_date_utils.date_char_tsz(i_lang, ser.dt_creation_tstz, i_prof.institution, i_prof.software) date_req,
                           pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, i_id_epis) special --FM 2009/03/19
                      FROM social_episode se, social_epis_request ser, professional p, speciality s
                     WHERE ser.id_social_episode = se.id_social_episode
                       AND p.id_professional = ser.id_professional
                       AND p.id_speciality = s.id_speciality(+)
                       AND se.id_episode = i_id_epis
                     ORDER BY id_social_epis_request DESC);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_s_epis);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_SOC_EPIS_REQ_EPIS',
                                                     o_error);
    END;

    FUNCTION get_soc_epis_sit
    (
        i_lang    IN language.id_language%TYPE,
        i_id_epis IN social_episode.id_social_episode%TYPE,
        i_prof    IN profissional,
        o_s_epis  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Consultar a situação do epis¿dio social
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_ID_EPIS - ID  do Epis¿dio
        
                Saida:   O_S_EPIS - Retorna a(s) situação do epis¿dio social
                             O_ERROR - erro
        
          CRIAÇÃO: ET 2006/04/28
          NOTAS:
        *********************************************************************************/
        l_episode social_epis_situation.id_social_epis_situation%TYPE;
    
    BEGIN
        BEGIN
            SELECT id_social_epis_situation
              INTO l_episode
              FROM social_epis_situation ses, social_episode se
             WHERE ses.id_social_episode = se.id_social_episode
               AND se.id_social_episode = i_id_epis
               AND rownum = 1;
        
            g_error := 'GET CURSOR O_S_EPIS';
            OPEN o_s_epis FOR
                SELECT ses.notes,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name, --FM 2009/03/19
                       pk_date_utils.date_char_tsz(i_lang,
                                                   ses.dt_social_epis_situation_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) date_sit,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, i_id_epis) special, --FM 2009/03/19
                       se.id_social_episode
                  FROM social_episode se, social_epis_situation ses, professional p, speciality s
                 WHERE ses.id_social_episode = se.id_social_episode
                   AND p.id_professional(+) = ses.id_professional
                   AND p.id_speciality = s.id_speciality(+)
                   AND se.id_social_episode = i_id_epis
                 ORDER BY ses.id_social_epis_situation DESC;
        
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'GET CURSOR O_S_EPIS 2';
                OPEN o_s_epis FOR
                    SELECT 'N' reg,
                           pk_message.get_message(i_lang, 'COMMON_M007') notes,
                           NULL name,
                           NULL date_sit,
                           NULL special,
                           NULL id_social_episode
                      FROM dual;
        END;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_s_epis);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_SOC_EPIS_SIT',
                                                     o_error);
        
    END;

    FUNCTION get_soc_epis_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis         IN social_episode.id_social_episode%TYPE,
        i_new_interv      IN VARCHAR2 DEFAULT 'N',
        o_soc_epis_interv OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter todos os registos de intervenção do epis¿dio social
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                 I_PROF- ID do profissional
                                 I_ID_EPIS - ID do Epis¿dio
                                 I_NEW_INTERV - Pode assumir dois valores: N: Retorna todas as Intervençães Sociais do epis¿dio
                                                                           S: Nova Intervenção Social
        
                Saida:   O_SOC_EPIS_INTERV- Retorna todas as intervençães sociais do episo¿dio
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/05/02
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF i_new_interv = 'N'
        THEN
        
            g_error := 'GET CURSOR ALL INTERVENTION';
            OPEN o_soc_epis_interv FOR
                SELECT sei.id_social_epis_interv id_s_epis_interv,
                       CASE
                            WHEN sei.id_social_intervention IS NULL THEN
                             sei.desc_social_intervention
                            ELSE
                             pk_translation.get_translation(i_lang, si.code_social_intervention)
                        END desc_social_interv,
                       pr.name name_prof,
                       prc.name name_prof_cancel,
                       decode(sei.flg_status, 'A', 'N', 'Y') flg_cancel,
                       sei.flg_status,
                       pk_date_utils.dt_chr_tsz(i_lang, sei.dt_social_epis_interv_tstz, i_prof) date_target,
                       pk_date_utils.dt_chr_tsz(i_lang, sei.dt_cancel_tstz, i_prof) date_cancel,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        sei.dt_social_epis_interv_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       pk_date_utils.date_char_hour_tsz(i_lang, sei.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_cancel,
                       decode(sei.flg_status,
                              'A',
                              pk_message.get_message(i_lang, 'SOCIAL_M005'),
                              pk_message.get_message(i_lang, 'SOCIAL_M004')) desc_status,
                       nvl(sei.notes, pk_message.get_message(i_lang, 'COMMON_M007')) notes,
                       nvl(sei.notes_cancel, pk_message.get_message(i_lang, 'COMMON_M007')) notes_cancel,
                       decode(sei.notes,
                              NULL,
                              decode(sei.notes_cancel,
                                     NULL,
                                     NULL,
                                     '(' || pk_message.get_message(i_lang, 'COMMON_M008') || ')'),
                              
                              '(' || pk_message.get_message(i_lang, 'COMMON_M008') || ')'
                              
                              ) title_notes,
                       decode(sei.flg_status,
                              'A',
                              NULL,
                              '(' || upper(pk_message.get_message(i_lang, 'SOCIAL_M004')) || ')') title_cancel,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, pr.id_professional, NULL, i_id_epis) desc_special, --FM 2009/03/19  
                       sei.notes report_notes,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   sei.dt_social_epis_interv_tstz,
                                                   i_prof.institution,
                                                   i_prof.id) report_date
                  FROM social_epis_interv  sei,
                       social_intervention si,
                       professional        pr,
                       professional        prc,
                       social_episode      se,
                       speciality          s
                 WHERE sei.id_social_intervention = si.id_social_intervention(+)
                   AND pr.id_professional = sei.id_professional
                   AND prc.id_professional(+) = sei.id_prof_cancel
                   AND pr.id_speciality = s.id_speciality(+)
                   AND se.id_social_episode = sei.id_social_episode
                   AND se.id_social_episode = i_id_epis
                 ORDER BY pk_sysdomain.get_rank(i_lang, 'EPIS_DIAGNOSIS.FLG_STATUS', sei.flg_status),
                          sei.id_social_epis_interv DESC;
        ELSE
            -- Botão +
            g_error := 'GET CURSOR NEW INTERVENTION';
            OPEN o_soc_epis_interv FOR
                SELECT name name_prof,
                       pk_date_utils.dt_chr_tsz(i_lang, g_sysdate_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang, g_sysdate_tstz, i_prof.institution, i_prof.software) hour_target,
                       pk_message.get_message(i_lang, 'SOCIAL_M005') desc_status
                  FROM professional
                 WHERE id_professional = i_prof.id;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_soc_epis_interv);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_SOC_EPIS_INTERV',
                                                     o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_soc_epis_interv);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_SOC_EPIS_INTERV',
                                                     o_error);
    END;

    FUNCTION get_soc_epis_sol
    (
        i_lang    IN language.id_language%TYPE,
        i_id_epis IN social_episode.id_social_episode%TYPE,
        i_prof    IN profissional,
        o_s_epis  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar as Soluçães Sociais do epis¿dio
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_ID_EPIS - ID  do Epis¿dio
        
                Saida:   O_S_EPIS - Retorna a(s) situação social do epis¿dio
                             O_ERROR - erro
        
          CRIAÇÃO: ET 2006/05/02
          NOTAS:
        *********************************************************************************/
        l_episode social_epis_solution.id_social_epis_solution%TYPE;
    BEGIN
        BEGIN
            SELECT id_social_epis_solution
              INTO l_episode
              FROM social_epis_solution ses, social_episode se
             WHERE ses.id_social_episode = se.id_social_episode
               AND se.id_social_episode = i_id_epis
               AND rownum = 1;
        
            g_error := 'GET CURSOR';
            OPEN o_s_epis FOR
                SELECT notes, name, date_sol, special
                  FROM (SELECT ses.notes,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name,
                               pk_date_utils.date_char_tsz(i_lang,
                                                           ses.dt_social_epis_solution_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) date_sol,
                               pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, i_id_epis) special --FM 2009/03/19  
                          FROM social_episode se, social_epis_solution ses, professional p, speciality s
                         WHERE ses.id_social_episode = se.id_social_episode
                           AND p.id_professional(+) = ses.id_professional
                           AND p.id_speciality = s.id_speciality(+)
                           AND se.id_social_episode = i_id_epis
                         ORDER BY ses.id_social_epis_solution DESC);
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'GET CURSOR O_S_EPIS 2';
                OPEN o_s_epis FOR
                    SELECT 'N' reg,
                           NULL id_epis_sol,
                           pk_message.get_message(i_lang, 'COMMON_M007') desc_epis_sol,
                           NULL special
                      FROM dual;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_s_epis);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_SOC_EPIS_SOL',
                                                     o_error);
    END;

    FUNCTION get_title_cont
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_title_cont OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listagem do t¿tulo e da mensagem do conte¿do da classe social
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do prof q acede
        
                        SAIDA:   O_TITLE_CONT - array que devolve o t¿tulo/ mensagem
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/06/12
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_TITLE_CONT';
        OPEN o_title_cont FOR ' SELECT DESC_MESSAGE TITLE ' || ' FROM SYS_MESSAGE WHERE ID_LANGUAGE = ' || i_lang || ' AND CODE_MESSAGE = ''SOCIAL_T067'' AND FLG_AVAILABLE = ''Y''' || ' UNION ALL' || ' SELECT DESC_MESSAGE MENSAG' || ' FROM SYS_MESSAGE WHERE ID_LANGUAGE = ' || i_lang || ' AND CODE_MESSAGE = ''SocialClassConteudo'' AND FLG_AVAILABLE = ''Y''';
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_title_cont);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_TITLE_CONT',
                                                     o_error);
        
    END;

    /**
    * Get currency's description
    *
    * @param       I_LANG             Predefined language
    * @param       I_PROF             Profissional ID
    * @param       O_CURRENCY         Currency name
    * @param       O_ERROR            Error message
    *
    * @return      boolean
    * @author      Thiago Brito
    * @version     2.4.3
    * @since       2008/05/15
    */
    FUNCTION get_currency_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_show_all IN VARCHAR2 DEFAULT 'Y',
        o_currency OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR C_CURRENCY';
        IF i_show_all = pk_alert_constant.g_yes
        THEN
            OPEN o_currency FOR
                SELECT c.id_currency,
                       c.currency_desc AS currency_brief_desc,
                       nvl(pk_translation.get_translation(i_lang, c.code_currency), c.currency_desc) currency_desc
                  FROM currency c
                 WHERE c.id_currency IN (SELECT nvl(ia.id_currency, 1)
                                           FROM inst_attributes ia
                                          WHERE ia.id_institution = i_prof.institution
                                            AND ia.flg_available = pk_alert_constant.g_yes)
                 ORDER BY c.currency_desc;
        ELSE
            --flash   
            OPEN o_currency FOR
                SELECT id_currency data, currency_desc label
                  FROM (SELECT c.id_currency,
                               c.currency_desc AS currency_brief_desc,
                               nvl(pk_translation.get_translation(i_lang, c.code_currency), c.currency_desc) currency_desc
                          FROM currency c
                         WHERE c.id_currency IN (SELECT nvl(ia.id_currency, 1)
                                                   FROM inst_attributes ia
                                                  WHERE ia.id_institution = i_prof.institution
                                                    AND ia.flg_available = pk_alert_constant.g_yes)
                         ORDER BY c.currency_desc);
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_CURRENCY_LIST',
                                                     o_error);
    END get_currency_list;
    --

    /**
     * This function is a privated function used to get the total
     * family members according to a patient.
     *
     * @param i_id_pat          patient identifier
     *
     * @return number           this function will return a number which is
     *                          the total family members
     *
     * @author                  thiago brito
     * @since                   23-JUL-2008
    */
    FUNCTION get_total_family_members(i_id_pat IN patient.id_patient%TYPE) RETURN NUMBER IS
        l_tot_person      PLS_INTEGER;
        l_tot_fam_members PLS_INTEGER;
    BEGIN
        --this are patients that exists in the database
        SELECT COUNT(*) tot_person
          INTO l_tot_person
          FROM patient pat
         WHERE pat.id_pat_family IN (SELECT p.id_pat_family
                                       FROM patient p
                                      WHERE p.id_patient = i_id_pat)
           AND pat.flg_status IN (g_patient_active, 'O');
    
        --The patient can also indicate the number of people in his/her household, without specify all of them:
        --At least consider the patient itself
        SELECT nvl(pat.total_fam_members, 1)
          INTO l_tot_fam_members
          FROM patient pat
         WHERE pat.id_patient = i_id_pat;
    
        --
        IF l_tot_fam_members > nvl(l_tot_person, 0)
        THEN
            l_tot_person := l_tot_fam_members;
        END IF;
    
        RETURN l_tot_person;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 1;
    END;

    /**
     * This function is a privated function used to get the amount money
     * from all members of a family according to a patient.
     *
     * @param i_id_pat          patient identifier
     * @param i_prof            profissional (professional, institution, software)
     *
     * @return number           total family's money
     *
     * @author                  thiago brito
     * @since                   23-JUL-2008
    */
    FUNCTION get_total_family_money
    (
        i_id_pat IN patient.id_patient%TYPE,
        i_prof   IN profissional
    ) RETURN NUMBER IS
        tot_money NUMBER;
    BEGIN
        SELECT (nvl(SUM(pension), 0) + nvl(SUM(net_wage), 0) + nvl(SUM(unemployment_subsidy), 0)) total_value
          INTO tot_money
          FROM pat_soc_attributes psa
         WHERE psa.id_patient IN (SELECT pat.id_patient -- ID_PATIENT WITH SAME ID_PAT_FAMILY
                                    FROM patient pat
                                   WHERE pat.id_pat_family IN (SELECT p.id_pat_family -- ID_PAT_FAMILY FROM PATIENT
                                                                 FROM patient p
                                                                WHERE p.id_patient = i_id_pat)
                                     AND pat.flg_status IN (g_patient_active, 'O'))
           AND psa.id_institution = i_prof.institution;
        RETURN tot_money;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END;

    FUNCTION get_occup_list
    (
        i_lang     IN language.id_language%TYPE,
        i_show_all IN VARCHAR2 DEFAULT 'Y',
        o_occup    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR';
        IF i_show_all = pk_alert_constant.g_yes
        THEN
            OPEN o_occup FOR
                SELECT *
                  FROM (SELECT id_occupation, rank, pk_translation.get_translation(i_lang, code_occupation) occupation
                          FROM occupation
                         WHERE flg_available = pk_alert_constant.g_yes)
                 WHERE occupation IS NOT NULL
                 ORDER BY rank, occupation;
        ELSE
            OPEN o_occup FOR
                SELECT id_occupation data, occupation label
                  FROM (SELECT id_occupation, rank, pk_translation.get_translation(i_lang, code_occupation) occupation
                          FROM occupation
                         WHERE flg_available = pk_alert_constant.g_yes)
                 WHERE occupation IS NOT NULL
                 ORDER BY rank, label;
        
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SOCIAL',
                                              'GET_OCCUP_LIST',
                                              o_error);
        
            pk_types.open_my_cursor(o_occup);
            RETURN FALSE;
    END;

    ---------------------------------Version 2.6.0.1-------------------------------------

    /********************************************************************************************
    * Get patient's home characteristics 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat                    Family grid
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_home_2
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_history           IN VARCHAR2 DEFAULT 'N',
        i_show_cancel       IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label IN VARCHAR2 DEFAULT 'N',
        i_report            IN VARCHAR2 DEFAULT 'N',
        o_pat_home          OUT pk_types.cursor_type,
        o_pat_home_prof     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        c_rownum_limited   CONSTANT PLS_INTEGER := 1;
        c_rownum_unlimited CONSTANT PLS_INTEGER := 999999;
    
        l_rownum PLS_INTEGER;
    
        l_show_cancelled VARCHAR2(1 CHAR) := '-';
        --
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        pk_alertlog.log_debug('GET_HOME_2 : i_id_pat = ' || i_id_pat);
        --
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T088',
                                                                                          'SOCIAL_T081',
                                                                                          'SOCIAL_T032',
                                                                                          'SOCIAL_T033',
                                                                                          'SOCIAL_T034',
                                                                                          'SOCIAL_T035',
                                                                                          'SOCIAL_T036',
                                                                                          'SOCIAL_T037',
                                                                                          'SOCIAL_T038',
                                                                                          'SOCIAL_T039',
                                                                                          'SOCIAL_T082',
                                                                                          'COMMON_M072',
                                                                                          'COMMON_M073'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --show home history
        IF i_history = pk_alert_constant.get_no
        THEN
            l_rownum := c_rownum_limited;
        ELSE
            l_rownum := c_rownum_unlimited;
        END IF;
    
        --show cancelled records
        IF i_show_cancel <> pk_alert_constant.get_yes
        THEN
            l_show_cancelled := pk_alert_constant.g_flg_status_c;
        END IF;
    
        --
        g_error := 'GET CURSOR O_PAT_HOME';
        OPEN o_pat_home FOR
            SELECT id,
                   field_header,
                   desc_flg_hab_location,
                   desc_flg_hab_type,
                   desc_flg_owner,
                   desc_flg_conserv,
                   desc_flg_light,
                   desc_flg_water_origin,
                   desc_flg_wc_location,
                   num_rooms,
                   arquitect_barrier,
                   notes,
                   cancel_reason,
                   cancel_notes
              FROM (SELECT id id,
                           decode(i_show_header_label,
                                  pk_alert_constant.g_yes,
                                  REPLACE(pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T088')),
                                          pk_paramedical_prof_core.c_colon) || chr(10),
                                  NULL) field_header,
                           --hab_location,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T081'),
                                                                              i_report) ||
                           nvl2(flg_hab_location,
                                pk_sysdomain.get_domain(g_domain_flg_hab_location, flg_hab_location, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_hab_location,
                           --hab_type,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T032'),
                                                                              i_report) ||
                           nvl2(flg_hab_type,
                                pk_sysdomain.get_domain(g_domain_flg_hab_type, flg_hab_type, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_hab_type,
                           --owner,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T033'),
                                                                              i_report) ||
                           nvl2(flg_owner,
                                pk_sysdomain.get_domain(g_domain_flg_owner, flg_owner, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_owner,
                           --conserv,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T034'),
                                                                              i_report) ||
                           nvl2(flg_conserv,
                                pk_sysdomain.get_domain(g_domain_flg_conserv, flg_conserv, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_conserv,
                           --light,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T035'),
                                                                              i_report) ||
                           nvl2(flg_light,
                                pk_sysdomain.get_domain(g_yes_no, flg_light, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_light,
                           --water_origin,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T036'),
                                                                              i_report) ||
                           nvl2(flg_water_origin,
                                pk_sysdomain.get_domain(g_domain_flg_water_origin, flg_water_origin, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_water_origin,
                           --wc_location,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T037'),
                                                                              i_report) ||
                           nvl2(flg_wc_location,
                                pk_sysdomain.get_domain(g_domain_flg_wc_location, flg_wc_location, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_wc_location,
                           --
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T038'),
                                                                              i_report) ||
                           nvl(to_char(num_rooms), pk_paramedical_prof_core.c_dashes) num_rooms,
                           --arquitect_barrier
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T039'),
                                                                              i_report) ||
                           nvl(arquitect_barrier, pk_paramedical_prof_core.c_dashes) arquitect_barrier,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T082'),
                                                                              i_report) ||
                           nvl(notes, pk_paramedical_prof_core.c_dashes) notes,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('COMMON_M072')) ||
                                  pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, id_cancel),
                                  NULL) cancel_reason,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('COMMON_M073')) ||
                                  pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, id_cancel),
                                  NULL) cancel_notes,
                           flg_status_1
                      FROM (SELECT decode(i_history, pk_alert_constant.g_no, p.id_home, p.id_home_hist) id,
                                   pf.name,
                                   p.dt_home_hist dt_registry_tstz,
                                   p.flg_status,
                                   p.num_rooms,
                                   p.flg_wc_location,
                                   p.flg_wc_type,
                                   p.flg_wc_out,
                                   p.flg_water_origin,
                                   p.flg_water_distrib,
                                   p.flg_conserv,
                                   p.flg_owner,
                                   p.flg_hab_type,
                                   p.flg_hab_location,
                                   p.flg_light,
                                   p.arquitect_barrier,
                                   p.notes,
                                   p.flg_status flg_status_1,
                                   p.id_cancel_info_det id_cancel
                              FROM home_hist p, patient pat, pat_family pf
                             WHERE p.id_pat_family = pf.id_pat_family
                               AND pf.id_pat_family(+) = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                             ORDER BY dt_registry_tstz DESC)
                     WHERE rownum <= l_rownum)
            --in the summary the cancelled records are not displayed
             WHERE l_show_cancelled <> flg_status_1;
    
        g_error := 'GET CURSOR O_PAT_HOME_PROF';
        OPEN o_pat_home_prof FOR
            SELECT *
              FROM (SELECT id id,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_home_hist, i_prof) dt,
                           pk_tools.get_prof_description(i_lang, i_prof, id_professional, dt_home_hist, NULL) prof_sign,
                           flg_status,
                           --only in the detail we have status labels
                           decode(i_history, pk_alert_constant.get_no, NULL, desc_status) desc_status
                      FROM (SELECT decode(i_history, pk_alert_constant.g_no, h.id_home, h.id_home_hist) id,
                                   h.dt_home_hist,
                                   h.id_professional,
                                   decode(h.flg_status, NULL, 'A', h.flg_status) flg_status,
                                   pk_sysdomain.get_domain(g_home_hist_flg_status, h.flg_status, i_lang) desc_status
                              FROM home_hist h, patient pat, pat_family pf
                             WHERE h.id_pat_family = pf.id_pat_family
                               AND pf.id_pat_family(+) = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                             ORDER BY dt_home_hist DESC)
                     WHERE rownum <= l_rownum)
            --in the summary the cancelled records are not displayed
             WHERE l_show_cancelled <> flg_status;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_HOME_2',
                                                     o_error);
        
    END get_home_2;
    --

    /********************************************************************************************
    * Get patient's home characteristics history
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat                    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_home_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        o_pat_home      OUT pk_types.cursor_type,
        o_pat_home_prof OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET HOME LOCATION LIST';
        IF NOT get_home_2(i_lang          => i_lang,
                          i_id_pat        => i_id_pat,
                          i_prof          => i_prof,
                          i_history       => pk_alert_constant.get_yes,
                          o_pat_home      => o_pat_home,
                          o_pat_home_prof => o_pat_home_prof,
                          o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOME_HIST',
                                                     o_error);
        
    END get_home_hist;
    --

    /********************************************************************************************
    * Get patient's home characteristics to edit 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat                    Family grid
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_home_edit
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_pat_home OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR cur_exist_home(id_pat patient.id_patient%TYPE) IS
            SELECT 'x'
              FROM home p, patient pat, pat_family pf
             WHERE p.id_pat_family = pf.id_pat_family
               AND pf.id_pat_family(+) = pat.id_pat_family
               AND pat.id_patient = id_pat
               AND p.flg_status <> pk_alert_constant.g_flg_status_c;
    
        l_temp_str VARCHAR2(1);
    BEGIN
        g_error := 'GET CURSOR O_PAT';
    
        OPEN cur_exist_home(i_id_pat);
        FETCH cur_exist_home
            INTO l_temp_str;
        g_found := cur_exist_home%NOTFOUND;
        CLOSE cur_exist_home;
    
        IF NOT g_found
        THEN
            OPEN o_pat_home FOR
                SELECT *
                  FROM (SELECT p.id_home,
                               pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                         'SOCIAL_T081'),
                                                                                  'Y',
                                                                                  'Y') title_hab_location,
                               pk_sysdomain.get_domain(g_domain_flg_hab_location, p.flg_hab_location, i_lang) desc_hab_location,
                               p.flg_hab_location,
                               --tipo de hab.
                               pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                         'SOCIAL_T032'),
                                                                                  'Y') title_hab_type,
                               pk_sysdomain.get_domain(g_domain_flg_hab_type, p.flg_hab_type, i_lang) desc_hab_type,
                               p.flg_hab_type,
                               --posse de hab
                               pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                         'SOCIAL_T033'),
                                                                                  'Y') title_owner,
                               pk_sysdomain.get_domain(g_domain_flg_owner, p.flg_owner, i_lang) desc_owner,
                               p.flg_owner,
                               --estado cons.
                               
                               pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                         'SOCIAL_T034'),
                                                                                  'Y') title_conserv,
                               pk_sysdomain.get_domain(g_domain_flg_conserv, p.flg_conserv, i_lang) desc_conserv,
                               p.flg_conserv,
                               --luz
                               pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                         'SOCIAL_T035'),
                                                                                  'Y') title_light,
                               pk_sysdomain.get_domain(g_yes_no, p.flg_light, i_lang) desc_light,
                               p.flg_light,
                               --agua
                               pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                         'SOCIAL_T036'),
                                                                                  'Y') title_water_origin,
                               pk_sysdomain.get_domain(g_domain_flg_water_origin, p.flg_water_origin, i_lang) desc_water_origin,
                               p.flg_water_origin,
                               --WC
                               pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                         'SOCIAL_T037'),
                                                                                  'Y') title_wc_location,
                               pk_sysdomain.get_domain(g_domain_flg_wc_location, p.flg_wc_location, i_lang) desc_wc_location,
                               p.flg_wc_location,
                               --rooms
                               pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                         'SOCIAL_T038'),
                                                                                  'Y') title_num_rooms,
                               p.num_rooms desc_num_rooms,
                               NULL flg_num_rooms,
                               --barreiras arq.
                               pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                         'SOCIAL_T039'),
                                                                                  'Y') title_arquitect_barrier,
                               p.arquitect_barrier desc_arquitect_barrier,
                               NULL flg_arquitect_barrier,
                               --notas
                               pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                         'SOCIAL_T082'),
                                                                                  'Y') title_notes,
                               p.notes desc_notes,
                               NULL flg_notes
                          FROM home p, patient pat, pat_family pf
                         WHERE p.id_pat_family = pf.id_pat_family
                           AND pf.id_pat_family(+) = pat.id_pat_family
                           AND pat.id_patient = i_id_pat
                         ORDER BY p.dt_registry_tstz DESC)
                -- only the last record, due to old versions
                 WHERE rownum = 1;
        ELSE
            OPEN o_pat_home FOR
                SELECT NULL id_home,
                       --zona de hab.
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T081'),
                                                                          'Y',
                                                                          'Y') title_hab_location,
                       NULL desc_hab_location,
                       NULL flg_hab_location,
                       --tipo de hab.
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T032'),
                                                                          'Y') title_hab_type,
                       NULL desc_hab_type,
                       NULL flg_hab_type,
                       --posse de hab
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T033'),
                                                                          'Y') title_owner,
                       NULL desc_owner,
                       NULL flg_owner,
                       --estado cons.
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T034'),
                                                                          'Y') title_conserv,
                       NULL desc_conserv,
                       NULL flg_conserv,
                       --luz
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T035'),
                                                                          'Y') title_light,
                       NULL desc_light,
                       NULL flg_light,
                       --agua
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T036'),
                                                                          'Y') title_water_origin,
                       NULL desc_water_origin,
                       NULL flg_water_origin,
                       --WC
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T037'),
                                                                          'Y') title_wc_location,
                       NULL desc_wc_location,
                       NULL flg_wc_location,
                       --rooms
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T038'),
                                                                          'Y') title_num_rooms,
                       NULL desc_num_rooms,
                       NULL flg_num_rooms,
                       --barreiras arq.
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T039'),
                                                                          'Y') title_arquitect_barrier,
                       NULL desc_arquitect_barrier,
                       NULL flg_arquitect_barrier,
                       --notas
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T082'),
                                                                          'Y') title_notes,
                       NULL desc_notes,
                       NULL flg_notes
                  FROM dual;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOME_EDIT',
                                                     o_error);
        
    END get_home_edit;
    --

    /********************************************************************************************
    * Get patient's Social status. This includes information of:
    *    - Home 
    *    - Social class
    *    - Financial status
    *    - Household
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_id_pat                 Patient ID 
    * @ param o_pat_home              Patient's home information
    * @ param o_pat_home_prof         Last professional that edit the home information
    * @ param o_pat_social_class      Social class information
    * @ param o_pat_social_class_prof Last professional that edit the social class
    * @ param o_pat_financial         Financial situation information
    * @ param o_pat_financial_prof    Last professional that edit the financial situation 
    * @ param o_pat_household         Household information
    * @param o_pat                    Family grid
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        --home
        o_pat_home      OUT pk_types.cursor_type,
        o_pat_home_prof OUT pk_types.cursor_type,
        --social class
        o_pat_social_class      OUT pk_types.cursor_type,
        o_pat_social_class_prof OUT pk_types.cursor_type,
        --financial
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        --house hold
        o_pat_household OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT get_home_new(i_lang          => i_lang,
                            i_id_pat        => i_id_pat,
                            i_prof          => i_prof,
                            o_pat_home      => o_pat_home,
                            o_pat_home_prof => o_pat_home_prof,
                            o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF NOT get_social_class(i_lang              => i_lang,
                                i_id_pat            => i_id_pat,
                                i_prof              => i_prof,
                                o_social_class      => o_pat_social_class,
                                o_prof_social_class => o_pat_social_class_prof,
                                o_error             => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF NOT get_household_financial(i_lang               => i_lang,
                                       i_id_pat             => i_id_pat,
                                       i_prof               => i_prof,
                                       o_pat_financial      => o_pat_financial,
                                       o_pat_financial_prof => o_pat_financial_prof,
                                       o_error              => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF NOT get_household(i_lang          => i_lang,
                             i_episode       => i_episode,
                             i_id_pat        => i_id_pat,
                             i_prof          => i_prof,
                             o_pat_household => o_pat_household,
                             o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            pk_types.open_my_cursor(o_pat_social_class);
            pk_types.open_my_cursor(o_pat_social_class_prof);
            pk_types.open_my_cursor(o_pat_financial);
            pk_types.open_my_cursor(o_pat_financial_prof);
            pk_types.open_my_cursor(o_pat_household);
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOME_DETAIL',
                                                     o_error);
        
    END get_social_status;
    --

    /********************************************************************************************
    * Get the social status menu 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_status_menu     Menu options for the social status screen 
    * @param o_social_status_actions  Actions options for the social status screen 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_status_menu
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        o_social_status_menu    OUT pk_types.cursor_type,
        o_social_status_actions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET SOCIAL STATUS MENU';
        IF NOT pk_action.get_actions_with_exceptions(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_subject    => 'SOCIAL_WORKER_SOCIAL_STATUS_MENU',
                                                     i_from_state => 'M',
                                                     o_actions    => o_social_status_menu,
                                                     o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET SOCIAL STATUS ACTIONS';
        IF NOT pk_action.get_actions_with_exceptions(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_subject    => 'SOCIAL_WORKER_SOCIAL_STATUS',
                                                     i_from_state => 'M',
                                                     o_actions    => o_social_status_actions,
                                                     o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_social_status_menu);
            pk_types.open_my_cursor(o_social_status_actions);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOME_DETAIL',
                                                     o_error);
        
    END get_social_status_menu;
    --

    /********************************************************************************************
    * Get the social status screen labels
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_status_labels   Social status screen labels  
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_status_labels
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        o_social_status_labels OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET LABELS';
        pk_alertlog.log_debug('GET_SOCIAL_STATUS_LABELS - get all labels for the social status screen');
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T041',
                                                                                          'SOCIAL_T088',
                                                                                          'SOCIAL_T062',
                                                                                          'SOCIAL_T089',
                                                                                          'SOCIAL_T090',
                                                                                          'SOCIAL_T091',
                                                                                          'SOCIAL_T092',
                                                                                          'SOCIAL_T077',
                                                                                          'SOCIAL_T078',
                                                                                          'SOCIAL_T021',
                                                                                          'SOCIAL_T093',
                                                                                          'SOCIAL_T094',
                                                                                          'SOCIAL_T095',
                                                                                          'SOCIAL_T096',
                                                                                          'SOCIAL_T097',
                                                                                          'SOCIAL_T098',
                                                                                          'SOCIAL_T099',
                                                                                          'SOCIAL_T110',
                                                                                          'SOCIAL_T111',
                                                                                          'SOCIAL_T112',
                                                                                          'SOCIAL_T148'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --    
        OPEN o_social_status_labels FOR
            SELECT t_table_message_array('SOCIAL_T041') social_status_main_header,
                   t_table_message_array('SOCIAL_T088') social_status_home_header,
                   t_table_message_array('SOCIAL_T062') social_status_s_class_header,
                   t_table_message_array('SOCIAL_T089') social_status_financial_header,
                   t_table_message_array('SOCIAL_T090') social_status_household_header,
                   t_table_message_array('SOCIAL_T091') home_edit_header,
                   t_table_message_array('SOCIAL_T092') home_create_header,
                   t_table_message_array('SOCIAL_T077') household_kinship,
                   t_table_message_array('SOCIAL_T078') household_name_profession,
                   t_table_message_array('SOCIAL_T021') household_wage,
                   t_table_message_array('SOCIAL_T093') household_dependency,
                   t_table_message_array('SOCIAL_T094') social_class_edit_header,
                   t_table_message_array('SOCIAL_T095') social_class_create_header,
                   t_table_message_array('SOCIAL_T096') financial_edit_header,
                   t_table_message_array('SOCIAL_T097') financial_create_header,
                   t_table_message_array('SOCIAL_T098') household_edit_header,
                   t_table_message_array('SOCIAL_T099') household_create_header,
                   t_table_message_array('SOCIAL_T110') home_detail_header,
                   t_table_message_array('SOCIAL_T111') social_class_detail_header,
                   t_table_message_array('SOCIAL_T112') financial_detail_header,
                   t_table_message_array('SOCIAL_T148') household_detail_header
              FROM dual;
        --      
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_social_status_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_SOCIAL_STATUS_LABELS',
                                                     o_error);
        
    END get_social_status_labels;
    --

    /********************************************************************************************
    * Get domains values for the home fields.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *
    * @ param o_home_location_domain  Home location domain
    * @ param o_home_type_domain      Home type domain
    * @ param o_home_owner_domain     Owner domain
    * @ param o_home_conserv_domain   Home maintenance status domain
    * @ param o_home_water_domain     Water domain
    * @ param o_home_wc_domain        WC domain
    * @ param o_home_light_domain     Light domain
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_status_home_domains
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        o_home_location_domain OUT pk_types.cursor_type,
        o_home_type_domain     OUT pk_types.cursor_type,
        o_home_owner_domain    OUT pk_types.cursor_type,
        o_home_conserv_domain  OUT pk_types.cursor_type,
        o_home_water_domain    OUT pk_types.cursor_type,
        o_home_wc_domain       OUT pk_types.cursor_type,
        o_home_light_domain    OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET HOME LOCATION LIST';
        IF NOT get_flg_hab_location_list(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         o_flg_hab_location => o_home_location_domain,
                                         o_error            => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        g_error := 'GET HOME TYPE LIST';
        IF NOT get_flg_hab_type_list(i_lang => i_lang, o_flg_hab_type => o_home_type_domain, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        g_error := 'GET OWNER LIST';
        IF NOT get_flg_owner_list(i_lang => i_lang, o_flg_owner => o_home_owner_domain, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        g_error := 'GET CONVERV LIST';
        IF NOT get_flg_conserv_list(i_lang => i_lang, o_flg_conserv => o_home_conserv_domain, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        g_error := 'GET WATER LIST';
        IF NOT
            get_flg_water_origin_list(i_lang => i_lang, o_flg_water_origin => o_home_water_domain, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        g_error := 'GET WC LOCATION LIST';
        IF NOT get_flg_wc_location_list(i_lang => i_lang, o_flg_wc_location => o_home_wc_domain, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        g_error := 'GET LIGHT LIST';
        IF NOT get_flg_light_list(i_lang => i_lang, o_flg_light => o_home_light_domain, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_home_location_domain);
            pk_types.open_my_cursor(o_home_type_domain);
            pk_types.open_my_cursor(o_home_owner_domain);
            pk_types.open_my_cursor(o_home_conserv_domain);
            pk_types.open_my_cursor(o_home_water_domain);
            pk_types.open_my_cursor(o_home_wc_domain);
            pk_types.open_my_cursor(o_home_light_domain);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_SOCIAL_STATUS_LABELS',
                                                     o_error);
        
    END get_social_status_home_domains;
    --

    /********************************************************************************************
     * Save family home conditions.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_id_pat                  Patient ID
     * @param i_id_home                 Home conditions record ID
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_flg_hab_location        Home location
     * @param i_flg_hab_type            Home type
     * @param i_flg_owner               Home owner
     * @param i_flg_conserv             Home state
     * @param i_flg_light               Home light 
     * @param i_flg_water_origin        Water origin
     * @param i_flg_water_distrib       Water distribution
     * @param i_flg_wc_location         WC location
     * @param i_num_rooms               Number of rooms
     * @param i_arquitect_barrier       Barriers
     * @param i_notes                   Notes
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Orlando Antunes
     * @version                          0.1
     * @since                            2010/01/21
    **********************************************************************************************/
    FUNCTION set_home
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_id_home           IN home.id_home%TYPE,
        i_prof              IN profissional,
        i_flg_hab_location  IN home.flg_hab_location%TYPE,
        i_flg_hab_type      IN home.flg_hab_type%TYPE,
        i_flg_owner         IN home.flg_owner%TYPE,
        i_flg_conserv       IN home.flg_conserv%TYPE,
        i_flg_light         IN home.flg_light%TYPE,
        i_flg_water_origin  IN home.flg_water_origin%TYPE,
        i_flg_water_distrib IN home.flg_water_distrib%TYPE,
        i_flg_wc_location   IN home.flg_wc_location%TYPE,
        i_num_rooms         IN home.num_rooms%TYPE,
        i_arquitect_barrier IN home.arquitect_barrier%TYPE,
        i_notes             IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next       home.id_home%TYPE;
        l_id_pat_fam patient.id_pat_family%TYPE;
        l_error      t_error_out;
        l_rowids     table_varchar;
    BEGIN
        pk_alertlog.log_debug('SET_HOME: i_id_pat = ' || i_id_pat || ',i_id_home ' || i_id_home ||
                              ',i_flg_hab_location ' || i_flg_hab_location || ',i_flg_hab_type ' || i_flg_hab_type ||
                              ', i_flg_owner ' || i_flg_owner || ', i_flg_conserv ' || i_flg_conserv ||
                              ', i_flg_light ' || i_flg_light || ', i_flg_water_origin ' || i_flg_water_origin ||
                              ', i_flg_water_distrib ' || i_flg_water_distrib || ', i_flg_wc_location ' ||
                              i_flg_wc_location || ', i_num_rooms ' || i_num_rooms || ', i_arquitect_barrier ' ||
                              i_arquitect_barrier || ',i_notes ' || i_notes);
    
        g_sysdate_tstz := current_timestamp;
        --
        -- verificar se o paciente já tem id_pat_family associado
        IF NOT set_pat_fam(i_lang       => i_lang,
                           i_id_pat     => i_id_pat,
                           i_prof       => i_prof,
                           o_id_pat_fam => l_id_pat_fam,
                           o_error      => l_error)
        THEN
            o_error := l_error;
            RAISE g_exception;
        END IF;
        --
    
        IF i_id_home IS NULL
        THEN
            -- Create new home information 
            g_error := 'INSERT HOME';
        
            ts_home.ins(id_pat_family_in     => l_id_pat_fam,
                        id_professional_in   => i_prof.id,
                        dt_registry_tstz_in  => g_sysdate_tstz,
                        num_rooms_in         => i_num_rooms,
                        flg_wc_location_in   => i_flg_wc_location,
                        flg_water_origin_in  => i_flg_water_origin,
                        flg_water_distrib_in => i_flg_water_distrib,
                        flg_conserv_in       => i_flg_conserv,
                        flg_owner_in         => i_flg_owner,
                        flg_hab_type_in      => i_flg_hab_type,
                        flg_hab_location_in  => i_flg_hab_location,
                        flg_light_in         => i_flg_light,
                        arquitect_barrier_in => i_arquitect_barrier,
                        notes_in             => i_notes,
                        flg_status_in        => pk_alert_constant.g_flg_status_a,
                        id_home_out          => l_next,
                        rows_out             => l_rowids);
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON HOME';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => g_table_home,
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            IF NOT set_home_hist(i_lang    => i_lang,
                                 i_prof    => i_prof,
                                 i_id_pat  => i_id_pat,
                                 i_id_home => l_next,
                                 o_error   => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        
        ELSE
            -- EXISTE
        
            --Actualizar atributos da habitação
            g_error := 'UPDATE HOME';
        
            ts_home.upd(id_home_in           => i_id_home,
                        num_rooms_in         => i_num_rooms,
                        flg_wc_location_in   => i_flg_wc_location,
                        flg_water_origin_in  => i_flg_water_origin,
                        flg_water_distrib_in => i_flg_water_distrib,
                        flg_conserv_in       => i_flg_conserv,
                        flg_owner_in         => i_flg_owner,
                        flg_hab_type_in      => i_flg_hab_type,
                        flg_hab_location_in  => i_flg_hab_location,
                        flg_light_in         => i_flg_light,
                        arquitect_barrier_in => i_arquitect_barrier,
                        notes_in             => i_notes,
                        flg_status_in        => pk_alert_constant.g_flg_status_e,
                        rows_out             => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => g_table_home,
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            --Set history for home information
            IF NOT set_home_hist(i_lang    => i_lang,
                                 i_prof    => i_prof,
                                 i_id_pat  => i_id_pat,
                                 i_id_home => i_id_home,
                                 o_error   => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        
        END IF;
        --
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
        --
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'SET_HOME',
                                                     o_error);
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'SET_HOME',
                                                     o_error);
        
    END set_home;
    --

    /********************************************************************************************
     * Cancel home.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_id_pat                  Patient ID
     * @param i_id_home                 Home conditions record ID
     *
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Orlando Antunes
     * @version                          0.1
     * @since                            2010/01/21
    **********************************************************************************************/
    FUNCTION set_cancel_home
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_home_hist  IN home_hist.id_home_hist%TYPE,
        i_notes         IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cancel_info_det_id cancel_info_det.id_cancel_info_det%TYPE;
        l_rowids             table_varchar;
        l_id_home            home.id_home%TYPE;
    BEGIN
        pk_alertlog.log_debug('SET_CANCEL_HOME: i_id_pat = ' || i_id_pat || ', i_id_home' || i_id_home_hist);
        --
        g_sysdate_tstz := current_timestamp;
    
        BEGIN
            SELECT hh.id_home
              INTO l_id_home
              FROM home_hist hh
             WHERE hh.id_home_hist = i_id_home_hist;
        EXCEPTION
            WHEN OTHERS THEN
                l_id_home := NULL;
        END;
    
        IF l_id_home IS NULL
        THEN
            g_error := 'SET_CANCEL_HOME: INVALID ID_HOME';
            RAISE g_sw_generic_exception;
        ELSE
        
            --
            pk_alertlog.log_debug('SET_CANCEL_HOME : SAVE CANCEL DETAILS');
            ts_cancel_info_det.ins(id_prof_cancel_in      => i_prof.id,
                                   id_cancel_reason_in    => i_cancel_reason,
                                   dt_cancel_in           => g_sysdate_tstz,
                                   notes_cancel_short_in  => i_notes,
                                   id_cancel_info_det_out => l_cancel_info_det_id,
                                   rows_out               => l_rowids);
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON CANCEL_INFO_DET';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CANCEL_INFO_DET',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            --Actualizar atributos da habitação
            g_error := 'UPDATE HOME';
            ts_home.upd(id_home_in            => l_id_home,
                        flg_status_in         => pk_alert_constant.g_flg_status_c,
                        id_cancel_info_det_in => l_cancel_info_det_id,
                        id_professional_in    => i_prof.id,
                        dt_registry_tstz_in   => g_sysdate_tstz,
                        rows_out              => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => g_table_home,
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            --Set history for home information
            IF NOT set_home_hist(i_lang    => i_lang,
                                 i_prof    => i_prof,
                                 i_id_pat  => i_id_pat,
                                 i_id_home => l_id_home,
                                 o_error   => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        
        END IF;
        --
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_CANCEL_HOME',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_cancel_home;
    --
    /********************************************************************************************
     * Set home history information
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_id_pat                  Patient ID
     * @param i_id_home                 Home conditions record ID
     *
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Orlando Antunes
     * @version                          0.1
     * @since                            2010/01/22
    **********************************************************************************************/
    FUNCTION set_home_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_id_home IN home.id_home%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_next     home_hist.id_home_hist%TYPE;
        l_home_row home%ROWTYPE;
        l_rowids   table_varchar;
    BEGIN
        --
        IF i_id_home IS NOT NULL
        THEN
            pk_alertlog.log_debug('SET_HOME_HIST : id_home = ' || i_id_home);
            --Get history for home information
            SELECT *
              INTO l_home_row
              FROM home
             WHERE id_home = i_id_home;
        
            -- Create new home information 
            ts_home_hist.ins(id_home_in             => l_home_row.id_home,
                             id_pat_family_in       => l_home_row.id_pat_family,
                             id_professional_in     => l_home_row.id_professional,
                             dt_registry_tstz_in    => l_home_row.dt_registry_tstz,
                             num_rooms_in           => l_home_row.num_rooms,
                             num_bedrooms_in        => l_home_row.num_bedrooms,
                             num_person_room_in     => l_home_row.num_person_room,
                             flg_wc_type_in         => l_home_row.flg_wc_type,
                             flg_wc_out_in          => l_home_row.flg_wc_out,
                             flg_heat_in            => l_home_row.flg_heat,
                             flg_wc_location_in     => l_home_row.flg_wc_location,
                             flg_water_origin_in    => l_home_row.flg_water_origin,
                             flg_water_distrib_in   => l_home_row.flg_water_distrib,
                             flg_conserv_in         => l_home_row.flg_conserv,
                             flg_owner_in           => l_home_row.flg_owner,
                             flg_hab_type_in        => l_home_row.flg_hab_type,
                             flg_hab_location_in    => l_home_row.flg_hab_location,
                             flg_light_in           => l_home_row.flg_light,
                             arquitect_barrier_in   => l_home_row.arquitect_barrier,
                             notes_in               => l_home_row.notes,
                             flg_status_in          => l_home_row.flg_status,
                             dt_home_hist_in        => l_home_row.dt_registry_tstz,
                             id_cancel_info_det_in  => l_home_row.id_cancel_info_det,
                             flg_water_treatment_in => l_home_row.flg_water_treatment,
                             flg_garbage_dest_in    => l_home_row.flg_garbage_dest,
                             ft_wc_type_in          => l_home_row.ft_wc_type,
                             ft_wc_location_in      => l_home_row.ft_wc_location,
                             ft_wc_out_in           => l_home_row.ft_wc_out,
                             ft_water_distrib_in    => l_home_row.ft_water_distrib,
                             ft_water_origin_in     => l_home_row.ft_water_origin,
                             ft_conserv_in          => l_home_row.ft_conserv,
                             ft_owner_in            => l_home_row.ft_owner,
                             ft_garbage_dest_in     => l_home_row.ft_garbage_dest,
                             ft_hab_type_in         => l_home_row.ft_hab_type,
                             ft_water_treatment_in  => l_home_row.ft_water_treatment,
                             ft_light_in            => l_home_row.ft_light,
                             ft_heat_in             => l_home_row.ft_heat,
                             ft_hab_location_in     => l_home_row.ft_hab_location,
                             flg_bath_in            => l_home_row.flg_bath,
                             ft_bath_in             => l_home_row.ft_bath,
                             id_home_hist_out       => l_next,
                             rows_out               => l_rowids);
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON HOME_HIST';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => g_table_home_hist,
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSE
            g_error := 'ID_HOME IS INVALID!';
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_HOME_HIST',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_home_hist;
    --

    /********************************************************************************************
     * Get patient's household information, that includes: photo, kinship, name/profession, wage, etc
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat                    Family grid
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2006/11/06
    **********************************************************************************************/
    FUNCTION get_household
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        o_pat_household OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_currency_default currency.id_currency%TYPE;
    
    BEGIN
    
        g_error               := 'GET CURRENCY DEFAUL - GET_FAM_MONEY';
        l_id_currency_default := get_currency_default(i_prof);
    
        g_error := 'GET CURSOR';
        OPEN o_pat_household FOR
            SELECT DISTINCT p.id_patient,
                            i_id_pat id_pat_origin,
                            decode(p.id_patient, i_id_pat, NULL, pfm.id_pat_family_member) id_pat_family_member,
                            p.gender,
                            pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                            pk_patphoto.get_pat_photo(i_lang, i_prof, p.id_patient, i_episode, NULL) photo,
                            decode(p.id_patient,
                                   i_id_pat,
                                   NULL,
                                   pk_translation.get_translation(i_lang, fr.code_family_relationship)) family_relationship,
                            
                            pk_patient.get_pat_name(i_lang, i_prof, p.id_patient, i_episode, NULL) name,
                            --VIP information--
                            pk_adt.get_pat_non_disc_options(i_lang, i_prof, p.id_patient) pat_ndo,
                            pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, p.id_patient) pat_nd_icon,
                            --VIP information--
                            get_pat_job(i_lang, p.id_patient) occupation,
                            --TODO Review this field...
                            decode(nvl((SELECT psa.net_wage
                                         FROM pat_soc_attributes psa
                                        WHERE psa.id_patient = p.id_patient
                                             --TODO how can we have this kind of information????
                                          AND psa.id_institution <> 0
                                             --TODO: ????
                                          AND rownum <= 1),
                                       0),
                                   0,
                                   NULL,
                                   (SELECT psa.net_wage
                                      FROM pat_soc_attributes psa
                                     WHERE psa.id_patient = p.id_patient
                                          --TODO how can we have this kind of information????
                                       AND psa.id_institution <> 0
                                          --TODO: ????
                                       AND rownum <= 1) || ' ' ||
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = l_id_currency_default)) wage,
                            --TODO Review this field
                            pk_sysdomain.get_domain('PATIENT.FLG_DEPENDENCE_LEVEL', p.flg_dependence_level, i_lang) dependency,
                            get_family_doctor(i_lang, p.id_patient, i_prof) family_doctor,
                            decode(p.flg_status, 'I', 'C', p.flg_status) flg_status
            --inst.flg_type inst_type
              FROM patient p,
                   pat_family_member pfm,
                   family_relationship fr,
                   (SELECT i_id_pat id_pat_related
                      FROM dual
                    UNION ALL
                    SELECT id_pat_related
                      FROM pat_family_member pfm2
                     WHERE pfm2.id_patient = i_id_pat) pf_mem
             WHERE p.id_patient = pf_mem.id_pat_related
               AND p.id_patient = pfm.id_pat_related(+)
               AND (pfm.id_patient = i_id_pat OR pfm.id_pat_related = i_id_pat OR pfm.id_pat_related IS NULL)
               AND pfm.id_family_relationship = fr.id_family_relationship(+)
            --AND inst.id_institution = i_prof.institution
             ORDER BY flg_status NULLS FIRST, family_relationship NULLS FIRST, p.id_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_household);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_HOUSEHOLD',
                                                     o_error);
        
    END get_household;

    /********************************************************************************************
     * Get patient's household information to show in the summary screen
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat_household          Household information
     * @param o_pat_household_prof     Household professional
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2006/11/06
    **********************************************************************************************/
    FUNCTION get_household_summary
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_prof               IN profissional,
        o_pat_household      OUT pk_types.cursor_type,
        o_pat_household_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_currency_default currency.id_currency%TYPE;
        l_pat_id              table_number := table_number();
        l_pat_info            table_varchar := table_varchar();
    
        l_pat_household_info CLOB;
    BEGIN
    
        g_error := 'GET_HOUSEHOLD_SUMMARY: i_id_pat' || i_id_pat;
        pk_alertlog.log_debug(g_error);
    
        l_id_currency_default := get_currency_default(i_prof);
    
        --Get the information for each household member
        SELECT id, household_member_info
          BULK COLLECT
          INTO l_pat_id, l_pat_info
          FROM (SELECT DISTINCT p.id_patient id,
                                decode(p.id_patient,
                                       i_id_pat,
                                       NULL,
                                       '<b>' || pk_translation.get_translation(i_lang, fr.code_family_relationship) ||
                                       ':</b> ') ||
                                nvl(pk_patient.get_pat_name(i_lang, i_prof, p.id_patient, i_episode, NULL),
                                    pk_paramedical_prof_core.c_dashes) || '; ' ||
                                nvl(get_pat_job(i_lang, p.id_patient), pk_paramedical_prof_core.c_dashes) || '; ' ||
                                nvl(decode(nvl((SELECT psa.net_wage
                                                 FROM pat_soc_attributes psa
                                                WHERE psa.id_patient = p.id_patient
                                                     --TODO how can we have this kind of information????
                                                  AND psa.id_institution <> 0
                                                     --TODO: ????
                                                  AND rownum <= 1),
                                               0),
                                           0,
                                           NULL,
                                           (SELECT psa.net_wage
                                              FROM pat_soc_attributes psa
                                             WHERE psa.id_patient = p.id_patient
                                                  --TODO how can we have this kind of information????
                                               AND psa.id_institution <> 0
                                                  --TODO: ????
                                               AND rownum <= 1) || ' ' ||
                                           (SELECT currency_desc
                                              FROM currency
                                             WHERE id_currency = l_id_currency_default)),
                                    pk_paramedical_prof_core.c_dashes) household_member_info,
                                decode(p.id_patient, i_id_pat, 1, 2) rank
                  FROM patient p,
                       pat_family_member pfm,
                       family_relationship fr,
                       (SELECT i_id_pat id_pat_related
                          FROM dual
                        UNION ALL
                        SELECT id_pat_related
                          FROM pat_family_member pfm2
                         WHERE pfm2.id_patient = i_id_pat) pf_mem
                 WHERE p.id_patient = pf_mem.id_pat_related
                   AND p.id_patient = pfm.id_pat_related(+)
                   AND (pfm.id_patient = i_id_pat OR pfm.id_pat_related = i_id_pat OR pfm.id_pat_related IS NULL)
                   AND pfm.id_family_relationship = fr.id_family_relationship(+)
                      --AND p.id_patient <> i_id_pat
                   AND p.flg_status <> 'I')
         ORDER BY rank, household_member_info, id;
    
        --build a string with all household members information
        FOR i IN 1 .. l_pat_info.count
        LOOP
            l_pat_household_info := l_pat_household_info || chr(10) || l_pat_info(i);
        END LOOP;
    
        IF dbms_lob.getlength(l_pat_household_info) <> 0
        THEN
            g_error := 'GET CURSOR';
            OPEN o_pat_household FOR
                SELECT i_id_pat id,
                       decode(rownum,
                              1,
                              REPLACE(chr(10) ||
                                      pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                                i_prof,
                                                                                                                'SOCIAL_T090')),
                                      pk_paramedical_prof_core.c_colon),
                              NULL) field_header,
                       l_pat_household_info household_member_info
                  FROM dual;
        
            --We don't have information here but we need this ID to send to the flash 
            OPEN o_pat_household_prof FOR
                SELECT i_id_pat id
                  FROM dual;
        ELSE
            pk_types.open_my_cursor(o_pat_household);
            pk_types.open_my_cursor(o_pat_household_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_household);
            pk_types.open_my_cursor(o_pat_household_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_HOUSEHOLD_SUMMARY',
                                                     o_error);
        
    END get_household_summary;

    /********************************************************************************************
     * Get patient's household history information.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat_household          Household information
     * @param o_pat_household_prof     Household professionals
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2006/11/06
    **********************************************************************************************/
    FUNCTION get_household_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_id_pat_household   IN patient.id_patient%TYPE,
        o_pat_household      OUT pk_types.cursor_type,
        o_pat_household_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_currency_default currency.id_currency%TYPE;
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET_HOUSEHOLD_HIST';
        pk_alertlog.log_debug(g_error || ' BEGIN');
    
        --IF NOT get_household_edit(i_lang             => i_lang,
        --                         i_prof             => i_prof,
        --                        i_id_pat           => i_id_pat,
        --                         i_id_pat_household => i_id_pat_household,
        --                        o_pat_household    => o_pat_household,
        --                        o_error            => o_error)
        --THEN
        --    RAISE g_sw_generic_exception;
        -- END IF;
        g_error               := 'GET CURRENCY DEFAUL - GET_FAM_MONEY';
        l_id_currency_default := get_currency_default(i_prof);
    
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T001',
                                                                                          'SOCIAL_T007',
                                                                                          'SOCIAL_T008',
                                                                                          'SOCIAL_T077',
                                                                                          'SOCIAL_T017',
                                                                                          'SOCIAL_T019',
                                                                                          'SOCIAL_T020',
                                                                                          'SOCIAL_T021',
                                                                                          'SOCIAL_T022',
                                                                                          'SOCIAL_T023',
                                                                                          'SOCIAL_T093',
                                                                                          'SOCIAL_T145'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF (i_id_pat_household = i_id_pat)
        THEN
            g_error := 'GET CURSOR O_PAT_DET 1';
            OPEN o_pat_household FOR
                SELECT pat.id_patient id,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T001')) ||
                       pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, i_episode, NULL) desc_name,
                       --
                       --l_id_currency_default l_id_currency_default,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T007')) ||
                       pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof) desc_date_birth,
                       
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T008')) ||
                       pk_sysdomain.get_domain('PATIENT.GENDER', pat.gender, i_lang) desc_gender,
                       
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T077')) || NULL desc_family_relationship,
                       
                       --'N' flg_edit_info,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T017')) ||
                       pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', psa.marital_status, i_lang) desc_marital_status,
                       
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T019')) ||
                       decode(pj.id_occupation,
                              NULL,
                              pj.occupation_desc,
                              pk_translation.get_translation(i_lang, o.code_occupation)) desc_occupation,
                       --                      
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T020')) ||
                       pk_translation.get_translation(i_lang,
                                                      (SELECT s.code_scholarship
                                                         FROM scholarship s
                                                        WHERE s.id_scholarship = psa.id_scholarship)) desc_scholarship,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T021')) ||
                       nvl2(to_char(net_wage),
                            (to_char(net_wage) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_net_wage, l_id_currency_default))),
                            NULL) desc_wage,
                       --psa.id_currency_net_wage id_unit_measure_wage,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T022')) ||
                       nvl2(to_char(pension),
                            (to_char(pension) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_pension, l_id_currency_default))),
                            NULL) desc_pension,
                       nvl(pension, 0) flg_pension,
                       -- psa.id_currency_pension id_unit_measure_pension,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T023')) ||
                       nvl2(to_char(unemployment_subsidy),
                            (to_char(unemployment_subsidy) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_unemp_sub, l_id_currency_default))),
                            NULL) desc_unemployment,
                       
                       --,psa.id_currency_unemp_sub id_unit_measure_unemployment
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T093')) title_dependency_level,
                       pk_sysdomain.get_domain('PATIENT.FLG_DEPENDENCE_LEVEL', pat.flg_dependence_level, i_lang) desc_dependency_level,
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T145')) ||
                       get_family_doctor(i_lang, pat.id_patient, i_prof) desc_fam_doctor
                  FROM patient pat,
                       pat_soc_attributes psa,
                       occupation o,
                       (SELECT *
                          FROM pat_job
                         WHERE dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                                    FROM pat_job p1
                                                   WHERE p1.id_patient = i_id_pat)) pj
                 WHERE pat.id_patient = i_id_pat
                   AND pj.id_patient(+) = psa.id_patient
                   AND o.id_occupation(+) = pj.id_occupation
                   AND pat.id_patient = psa.id_patient(+);
        ELSE
            pk_alertlog.log_debug('Edit a patient that belongs to the household!');
            g_error := 'GET CURSOR O_PAT_DET 2';
            OPEN o_pat_household FOR
                SELECT pat.id_patient id,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T001')) ||
                       pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, i_episode, NULL) desc_name,
                       
                       --
                       --l_id_currency_default l_id_currency_default,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T007')) ||
                       pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof) desc_date_birth,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T008')) ||
                       pk_sysdomain.get_domain('PATIENT.GENDER', pat.gender, i_lang) desc_gender,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T077')) ||
                       pk_translation.get_translation(i_lang, fr.code_family_relationship) desc_family_relationship,
                       --'N' flg_edit_info,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T017')) ||
                       pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', psa.marital_status, i_lang) desc_marital_status,
                       
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T019')) ||
                       decode(pj.id_occupation,
                              NULL,
                              pj.occupation_desc,
                              pk_translation.get_translation(i_lang, o.code_occupation)) desc_occupation,
                       
                       --                      
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T020')) ||
                       pk_translation.get_translation(i_lang,
                                                      (SELECT s.code_scholarship
                                                         FROM scholarship s
                                                        WHERE s.id_scholarship = psa.id_scholarship)) desc_scholarship,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T021')) ||
                       nvl2(to_char(net_wage),
                            (to_char(net_wage) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_net_wage, l_id_currency_default))),
                            NULL) desc_wage,
                       --psa.id_currency_net_wage id_unit_measure_wage,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T022')) ||
                       nvl2(to_char(pension),
                            (to_char(pension) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_pension, l_id_currency_default))),
                            NULL) desc_pension,
                       
                       --psa.id_currency_pension id_unit_measure_pension,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T023')) ||
                       nvl2(to_char(unemployment_subsidy),
                            (to_char(unemployment_subsidy) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_unemp_sub, l_id_currency_default))),
                            NULL) desc_unemployment,
                       
                       --psa.id_currency_unemp_sub id_unit_measure_unemployment
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T093')) ||
                       pk_sysdomain.get_domain('PATIENT.FLG_DEPENDENCE_LEVEL', pat.flg_dependence_level, i_lang) desc_dependency_level,
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T145')) ||
                       get_family_doctor(i_lang, pat.id_patient, i_prof) desc_fam_doctor
                  FROM patient pat,
                       pat_soc_attributes psa,
                       family_relationship fr,
                       pat_family_member pfm,
                       occupation o,
                       (SELECT *
                          FROM pat_job
                         WHERE dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                                    FROM pat_job p1
                                                   WHERE p1.id_patient = i_id_pat_household)) pj
                 WHERE pat.id_patient = i_id_pat_household
                   AND pfm.id_pat_related(+) = pat.id_patient
                   AND pfm.id_family_relationship = fr.id_family_relationship
                   AND pj.id_patient(+) = psa.id_patient
                   AND o.id_occupation(+) = pj.id_occupation
                   AND pat.id_patient = psa.id_patient(+);
        END IF;
    
        g_error := 'GET CURSOR O_PAT_HOUSEHOLD_PROF';
        OPEN o_pat_household_prof FOR
            SELECT pat.id_patient id,
                   NULL dt,
                   NULL prof_sign,
                   decode(pat.flg_status, g_flg_inactive, pk_alert_constant.g_flg_status_c, pat.flg_status) flg_status,
                   NULL desc_status
              FROM patient pat
             WHERE pat.id_patient = i_id_pat;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_household);
            pk_types.open_my_cursor(o_pat_household_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_HOUSEHOLD_HIST',
                                                     o_error);
        
    END get_household_hist;
    --

    /********************************************************************************************
     * Get patient's household members
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_patient             Patient ID     
     * @param o_tbl_id_patient         Table of patient ids
     * @param o_tbl_household_desc     Patient's household members information
     *
     * @return                         True on success, False otherwise
     *
     * @author                         Diogo Oliveira
     * @version                        v2.7.3.6
     * @since                          2018/11/19
    **********************************************************************************************/
    FUNCTION get_household_summary_page
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        o_tbl_id_patient     OUT table_number,
        o_tbl_household_desc OUT table_varchar
    ) RETURN BOOLEAN IS
        l_id_currency_default currency.id_currency%TYPE;
        t_table_message_array pk_paramedical_prof_core.table_message_array;
        l_id_pat_family       patient.id_pat_family%TYPE;
        l_patient_details     VARCHAR2(4000) := NULL;
        l_tbl_family_details  table_varchar := table_varchar();
        l_tbl_household       table_varchar := table_varchar();
        l_family_details      VARCHAR2(4000) := NULL;
        l_tbl_family          table_number := table_number();
        l_tbl_family_aux      table_number := table_number();
    BEGIN
        g_error := 'GET_HOUSEHOLD_ID';
        pk_alertlog.log_debug(g_error);
    
        SELECT p.id_pat_family
          INTO l_id_pat_family
          FROM patient p
         WHERE p.id_patient = i_id_patient;
    
        g_error := 'GET FAMILY';
        pk_alertlog.log_debug(g_error);
        SELECT *
          BULK COLLECT
          INTO l_tbl_family
          FROM (SELECT DISTINCT p.id_patient
                  FROM patient p
                 WHERE p.id_pat_family = l_id_pat_family
                   AND p.flg_status = pk_alert_constant.g_active
                   AND p.id_patient <> i_id_patient
                
                UNION
                
                SELECT DISTINCT pfm.id_pat_related
                  FROM pat_family_member pfm
                 WHERE pfm.id_pat_family = l_id_pat_family
                   AND pfm.id_pat_related <> i_id_patient);
    
        g_error               := 'GET CURRENCY DEFAUL - GET_FAM_MONEY';
        l_id_currency_default := get_currency_default(i_prof);
    
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T001',
                                                                                          'SOCIAL_T007',
                                                                                          'SOCIAL_T008',
                                                                                          'SOCIAL_T077',
                                                                                          'SOCIAL_T017',
                                                                                          'SOCIAL_T019',
                                                                                          'SOCIAL_T020',
                                                                                          'SOCIAL_T021',
                                                                                          'SOCIAL_T022',
                                                                                          'SOCIAL_T023',
                                                                                          'SOCIAL_T093',
                                                                                          'SOCIAL_T145'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error := 'GET PATIENT DETAILS';
        SELECT desc_name || chr(13) || nvl2(desc_date_birth, desc_date_birth || chr(13), NULL) ||
               nvl2(desc_gender, desc_gender || chr(13), NULL) ||
               nvl2(desc_marital_status, desc_marital_status || chr(13), NULL) ||
               nvl2(desc_occupation, desc_occupation || chr(13), NULL) ||
               nvl2(desc_scholarship, desc_scholarship || chr(13), NULL) || nvl2(desc_wage, desc_wage || chr(13), NULL) ||
               nvl2(desc_pension, desc_pension || chr(13), NULL) ||
               nvl2(desc_unemployment, desc_unemployment || chr(13), NULL) ||
               nvl2(desc_dependency_level, desc_dependency_level || chr(13), NULL) || desc_fam_doctor
          INTO l_patient_details
          FROM (SELECT pat.id_patient id,
                       --name
                       t_table_message_array('SOCIAL_T001') || chr(58) || chr(32) ||
                       --  pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, NULL, NULL) desc_name,
                        pat.name desc_name,
                       --
                       --
                       nvl2(pat.dt_birth,
                            t_table_message_array('SOCIAL_T007') || chr(58) || chr(32) ||
                            pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof),
                            NULL) desc_date_birth,
                       --
                       nvl2(pat.gender,
                            t_table_message_array('SOCIAL_T008') || chr(58) || chr(32) ||
                            pk_sysdomain.get_domain('PATIENT.GENDER', pat.gender, i_lang),
                            NULL) desc_gender,
                       --
                       nvl2(psa.marital_status,
                            t_table_message_array('SOCIAL_T017') || chr(58) || chr(32) ||
                            pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', psa.marital_status, i_lang),
                            NULL) desc_marital_status,
                       --
                       nvl2(o.code_occupation,
                            t_table_message_array('SOCIAL_T019') || chr(58) || chr(32) ||
                            decode(pj.id_occupation,
                                   NULL,
                                   pj.occupation_desc,
                                   pk_translation.get_translation(i_lang, o.code_occupation)),
                            NULL) desc_occupation,
                       --                      
                       nvl2(psa.id_scholarship,
                            t_table_message_array('SOCIAL_T020') || chr(58) || chr(32) ||
                            pk_translation.get_translation(i_lang,
                                                           (SELECT s.code_scholarship
                                                              FROM scholarship s
                                                             WHERE s.id_scholarship = psa.id_scholarship)),
                            NULL) desc_scholarship,
                       --
                       nvl2(to_char(net_wage),
                            t_table_message_array('SOCIAL_T021') ||
                            (to_char(net_wage) || ' ' ||
                             (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_net_wage, l_id_currency_default))),
                            NULL) desc_wage,
                       --
                       nvl2(to_char(pension),
                            t_table_message_array('SOCIAL_T022') ||
                            (to_char(pension) || ' ' ||
                             (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_pension, l_id_currency_default))),
                            NULL) desc_pension,
                       --
                       nvl2(to_char(unemployment_subsidy),
                            t_table_message_array('SOCIAL_T023') ||
                            (to_char(unemployment_subsidy) || ' ' ||
                             (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_unemp_sub, l_id_currency_default))),
                            NULL) desc_unemployment,
                       --
                       nvl2(pat.flg_dependence_level,
                            t_table_message_array('SOCIAL_T093') || chr(58) || chr(32) ||
                            pk_sysdomain.get_domain('PATIENT.FLG_DEPENDENCE_LEVEL', pat.flg_dependence_level, i_lang),
                            NULL) desc_dependency_level,
                       --
                       nvl2(get_family_doctor(i_lang, pat.id_patient, i_prof),
                            t_table_message_array('SOCIAL_T145') || chr(58) || chr(32) ||
                            get_family_doctor(i_lang, pat.id_patient, i_prof),
                            NULL) desc_fam_doctor
                  FROM patient pat,
                       pat_soc_attributes psa,
                       occupation o,
                       (SELECT *
                          FROM pat_job
                         WHERE dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                                    FROM pat_job p1
                                                   WHERE p1.id_patient = i_id_patient)) pj
                 WHERE pat.id_patient = i_id_patient
                   AND pj.id_patient(+) = psa.id_patient
                   AND o.id_occupation(+) = pj.id_occupation
                   AND pat.id_patient = psa.id_patient(+)) t;
    
        g_error := 'GET FAMILY DETAILS';
        SELECT (desc_name || chr(13) || nvl2(desc_date_birth, desc_date_birth || chr(13), NULL) ||
               nvl2(desc_gender, desc_gender || chr(13), NULL) ||
               nvl2(desc_marital_status, desc_marital_status || chr(13), NULL) ||
               nvl2(desc_occupation, desc_occupation || chr(13), NULL) ||
               nvl2(desc_scholarship, desc_scholarship || chr(13), NULL) ||
               nvl2(desc_wage, desc_wage || chr(13), NULL) || nvl2(desc_pension, desc_pension || chr(13), NULL) ||
               nvl2(desc_unemployment, desc_unemployment || chr(13), NULL) ||
               nvl2(desc_dependency_level, desc_dependency_level || chr(13), NULL) ||
               nvl2(desc_fam_doctor, desc_fam_doctor || chr(13), NULL)),
               id
          BULK COLLECT
          INTO l_tbl_family_details, l_tbl_family_aux
          FROM (SELECT pat.id_patient id,
                       t_table_message_array('SOCIAL_T001') || chr(58) || chr(32) ||
                       --                       pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, NULL, NULL) desc_name,
                        pat.name desc_name,
                       --
                       nvl2(pat.dt_birth,
                            t_table_message_array('SOCIAL_T007') || chr(58) || chr(32) ||
                            pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof),
                            NULL) desc_date_birth,
                       --
                       nvl2(pat.gender,
                            t_table_message_array('SOCIAL_T008') || chr(58) || chr(32) ||
                            pk_sysdomain.get_domain('PATIENT.GENDER', pat.gender, i_lang),
                            NULL) desc_gender,
                       --
                       nvl2(fr.code_family_relationship,
                            t_table_message_array('SOCIAL_T077') || chr(58) || chr(32) ||
                            pk_translation.get_translation(i_lang, fr.code_family_relationship),
                            NULL) desc_family_relationship,
                       --
                       nvl2(psa.marital_status,
                            t_table_message_array('SOCIAL_T017') || chr(58) || chr(32) ||
                            pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', psa.marital_status, i_lang),
                            NULL) desc_marital_status,
                       --
                       nvl2(o.code_occupation,
                            t_table_message_array('SOCIAL_T019') || chr(58) || chr(32) ||
                            decode(pj.id_occupation,
                                   NULL,
                                   pj.occupation_desc,
                                   pk_translation.get_translation(i_lang, o.code_occupation)),
                            NULL) desc_occupation,
                       --                      
                       nvl2(psa.id_scholarship,
                            t_table_message_array('SOCIAL_T020') || chr(58) || chr(32) ||
                            pk_translation.get_translation(i_lang,
                                                           (SELECT s.code_scholarship
                                                              FROM scholarship s
                                                             WHERE s.id_scholarship = psa.id_scholarship)),
                            NULL) desc_scholarship,
                       --
                       nvl2(to_char(net_wage),
                            t_table_message_array('SOCIAL_T021') || chr(58) || chr(32) ||
                            (to_char(net_wage) || ' ' ||
                             (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_net_wage, l_id_currency_default))),
                            NULL) desc_wage,
                       --
                       nvl2(to_char(pension),
                            t_table_message_array('SOCIAL_T022') || chr(58) || chr(32) ||
                            (to_char(pension) || ' ' ||
                             (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_pension, l_id_currency_default))),
                            NULL) desc_pension,
                       --
                       nvl2(to_char(unemployment_subsidy),
                            t_table_message_array('SOCIAL_T023') || chr(58) || chr(32) ||
                            (to_char(unemployment_subsidy) || ' ' ||
                             (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_unemp_sub, l_id_currency_default))),
                            NULL) desc_unemployment,
                       --
                       nvl2(pat.flg_dependence_level,
                            t_table_message_array('SOCIAL_T093') || chr(58) || chr(32) ||
                            pk_sysdomain.get_domain('PATIENT.FLG_DEPENDENCE_LEVEL', pat.flg_dependence_level, i_lang),
                            NULL) desc_dependency_level,
                       
                       nvl2(get_family_doctor(i_lang, pat.id_patient, i_prof),
                            t_table_message_array('SOCIAL_T145') || chr(58) || chr(32) ||
                            get_family_doctor(i_lang, pat.id_patient, i_prof),
                            NULL) desc_fam_doctor
                  FROM patient pat,
                       pat_soc_attributes psa,
                       family_relationship fr,
                       pat_family_member pfm,
                       occupation o,
                       (SELECT *
                          FROM pat_job
                         WHERE dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                                    FROM pat_job p1
                                                   WHERE p1.id_patient IN (SELECT *
                                                                             FROM TABLE(l_tbl_family)))) pj
                 WHERE pat.id_patient IN (SELECT *
                                            FROM TABLE(l_tbl_family))
                   AND pfm.id_pat_family = l_id_pat_family
                   AND pfm.id_pat_related(+) = pat.id_patient
                   AND pfm.id_family_relationship = fr.id_family_relationship
                   AND pj.id_patient(+) = psa.id_patient
                   AND o.id_occupation(+) = pj.id_occupation
                   AND pat.id_patient = psa.id_patient(+));
    
        l_tbl_family := table_number();
    
        IF l_patient_details IS NOT NULL
        THEN
            l_tbl_household.extend();
            l_tbl_household(l_tbl_household.count) := l_patient_details;
        
            l_tbl_family.extend();
            l_tbl_family(l_tbl_family.count) := i_id_patient;
        END IF;
    
        IF l_tbl_family_details.exists(1)
        THEN
            FOR i IN l_tbl_family_details.first .. l_tbl_family_details.last
            LOOP
                l_tbl_household.extend();
                l_tbl_household(l_tbl_household.count) := l_tbl_family_details(i);
            
                l_tbl_family.extend();
                l_tbl_family(l_tbl_family.count) := l_tbl_family_aux(i);
            END LOOP;
        END IF;
    
        o_tbl_id_patient     := l_tbl_family;
        o_tbl_household_desc := l_tbl_household;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END get_household_summary_page;

    /********************************************************************************************
     * Get patient's job (the last one)
     * This functions is only a wrapper to the original function created in the pk_patient package
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Patient ID 
     * @param o_error                  Error
     *
     * @return                         the patient's job
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2006/11/06
    **********************************************************************************************/
    FUNCTION get_pat_job
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
    
        l_pat_job pk_translation.t_desc_translation;
        l_error   t_error_out;
    BEGIN
    
        g_error := 'GET_PATIENT_JOB';
        IF NOT
            pk_patient.get_last_pat_job(i_lang => i_lang, i_id_pat => i_id_pat, o_occup => l_pat_job, o_error => l_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN l_pat_job;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SOCIAL',
                                              'GET_PAT_JOB',
                                              l_error);
            RETURN NULL;
    END get_pat_job;
    --

    /********************************************************************************************
     * Get patient's family doctor
     *
     * @param i_lang                   Preferred language ID for this professional     
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_error                  Error
     *
     * @return                         patient's family doctor
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2006/11/06
    **********************************************************************************************/
    FUNCTION get_family_doctor
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        i_return_name IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR IS
    
        l_error       t_error_out;
        l_doctor_info VARCHAR2(1000 CHAR);
        l_id_pat_fam  pat_family.id_pat_family%TYPE;
    
        CURSOR c_pat IS
            SELECT id_pat_family
              FROM patient p
             WHERE p.id_patient = i_id_pat
                  --AND p.flg_status = g_patient_active
               AND id_pat_family IS NOT NULL;
    BEGIN
        pk_alertlog.log_debug('GET_FAMILY_DOCTOR - patient = ' || i_id_pat);
        --The family doctor is set by patient in the Social Worker software - table pat_professional_inst.
        --To mantain the previous data, where the family doctor is set by family (pat_family) - table pat_family_prof, 
        -- if no data exists for the specific patient, the family doctor is displayed!
        BEGIN
            IF i_return_name = pk_alert_constant.g_yes
            THEN
                SELECT nvl(pp.desc_professional, pk_prof_utils.get_name_signature(i_lang, i_prof, pp.id_professional))
                  INTO l_doctor_info
                  FROM pat_professional_inst pp
                 WHERE pp.id_patient = i_id_pat
                   AND pp.flg_family_physician = pk_alert_constant.g_yes;
            ELSE
                SELECT nvl(pp.desc_professional, pp.id_professional)
                  INTO l_doctor_info
                  FROM pat_professional_inst pp
                 WHERE pp.id_patient = i_id_pat
                   AND pp.flg_family_physician = pk_alert_constant.g_yes;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                pk_alertlog.log_debug('No family doctor found for the patient');
                l_doctor_info := NULL;
        END;
    
        IF l_doctor_info IS NULL
        THEN
            --get the pat_family id
            OPEN c_pat;
            FETCH c_pat
                INTO l_id_pat_fam;
            g_found := c_pat%FOUND;
            CLOSE c_pat;
            --
            IF g_found
            THEN
            
                BEGIN
                    IF i_return_name = pk_alert_constant.g_yes
                    THEN
                        SELECT DISTINCT pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) --FM 2009/03/19
                          INTO l_doctor_info
                          FROM pat_family_prof pfp, professional prof
                         WHERE pfp.id_patient = i_id_pat
                           AND pfp.id_pat_family = l_id_pat_fam
                           AND pfp.id_institution = i_prof.institution
                           AND pfp.id_professional = prof.id_professional;
                    ELSE
                        SELECT DISTINCT prof.id_professional --FM 2009/03/19
                          INTO l_doctor_info
                          FROM pat_family_prof pfp, professional prof
                         WHERE pfp.id_patient = i_id_pat
                           AND pfp.id_pat_family = l_id_pat_fam
                           AND pfp.id_institution = i_prof.institution
                           AND pfp.id_professional = prof.id_professional;
                    END IF;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_doctor_info := NULL;
                END;
            END IF;
        END IF;
        --
        RETURN l_doctor_info;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_FAMILY_DOCTOR',
                                              l_error);
            RETURN NULL;
    END get_family_doctor;
    --

    /********************************************************************************************
     * Get the household information for the create/edit screen. If no information exists 
     * for the given patient the cursor returns only the screen's labels, otherwise it 
     * returns the information previously created.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_episode                Episode ID
     * @param i_id_pat                 Patient ID 
     * @param i_id_pat_household       Patient ID for the household member to edit
     * @param o_pat_household          Household information
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_household_edit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_pat           IN patient.id_patient%TYPE,
        i_id_pat_household IN patient.id_patient%TYPE,
        o_pat_household    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_currency_default currency.id_currency%TYPE;
        l_mask_wage           pk_utils.t_str_mask;
        l_mask_pension        pk_utils.t_str_mask;
        l_mask_unempl         pk_utils.t_str_mask;
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    
    BEGIN
        pk_alertlog.log_debug('GET_HOUSEHOLD_EDIT : i_id_pat = ' || i_id_pat || ', i_id_pat_household = ' ||
                              i_id_pat_household);
    
        g_error               := 'GET CURRENCY DEFAUL - GET_FAM_MONEY';
        l_id_currency_default := get_currency_default(i_prof);
        g_error               := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T001',
                                                                                          'SOCIAL_T007',
                                                                                          'SOCIAL_T008',
                                                                                          'SOCIAL_T077',
                                                                                          'SOCIAL_T017',
                                                                                          'SOCIAL_T019',
                                                                                          'SOCIAL_T020',
                                                                                          'SOCIAL_T021',
                                                                                          'SOCIAL_T022',
                                                                                          'SOCIAL_T023',
                                                                                          'SOCIAL_T093',
                                                                                          'SOCIAL_T145'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        -- get currency fields masks
        l_mask_wage    := pk_utils.get_numeric_input_mask(i_prof   => i_prof,
                                                          i_owner  => g_schema_adt,
                                                          i_table  => 'PAT_SOC_ATTRIBUTES',
                                                          i_column => 'NET_WAGE');
        l_mask_pension := pk_utils.get_numeric_input_mask(i_prof   => i_prof,
                                                          i_owner  => g_schema_adt,
                                                          i_table  => 'PAT_SOC_ATTRIBUTES',
                                                          i_column => 'PENSION');
        l_mask_unempl  := pk_utils.get_numeric_input_mask(i_prof   => i_prof,
                                                          i_owner  => g_schema_adt,
                                                          i_table  => 'PAT_SOC_ATTRIBUTES',
                                                          i_column => 'UNEMPLOYMENT_SUBSIDY');
    
        --
        pk_alertlog.log_debug('Create New household member');
        IF i_id_pat_household IS NULL
        THEN
            OPEN o_pat_household FOR
                SELECT NULL id_patient,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T001'),
                                                                          'Y',
                                                                          'Y') title_name,
                       NULL desc_name,
                       NULL flg_name,
                       --
                       --l_id_currency_default l_id_currency_default,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T007'), 'Y') title_date_birth,
                       NULL desc_date_birth,
                       NULL flg_date_birth,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T008'),
                                                                          'Y',
                                                                          'Y') title_gender,
                       NULL desc_gender,
                       NULL flg_gender,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T077'),
                                                                          'Y',
                                                                          'Y') title_family_relationship,
                       NULL desc_family_relationship,
                       NULL flg_family_relationship,
                       --'N' flg_edit_info,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T017'), 'Y') title_marital_status,
                       NULL desc_marital_status,
                       NULL flg_marital_status,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T019'), 'Y') title_occupation,
                       NULL desc_occupation,
                       NULL flg_occupation,
                       --                      
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T020'), 'Y') title_scholarship,
                       NULL desc_scholarship,
                       NULL flg_scholarship,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T021'), 'Y') title_wage,
                       NULL desc_wage,
                       NULL flg_wage,
                       l_mask_wage flg_mask_wage,
                       0 flg_min_wage,
                       NULL flg_max_wage,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T022'), 'Y') title_pension,
                       NULL desc_pension,
                       NULL flg_pension,
                       l_mask_pension flg_mask_pension,
                       0 flg_min_pension,
                       NULL flg_max_pension,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T023'), 'Y') title_unemployment,
                       NULL desc_unemployment,
                       NULL flg_unemployment,
                       l_mask_unempl flg_mask_unemployment,
                       0 flg_min_unemployment,
                       NULL flg_max_unemployment,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T093'), 'Y') title_dependency_level,
                       NULL desc_dependency_level,
                       NULL flg_dependency_level,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T145'), 'Y') title_fam_doctor,
                       NULL desc_fam_doctor,
                       NULL flg_fam_doctor
                  FROM dual;
        ELSE
            pk_alertlog.log_debug('Edit the current patient!');
            IF (i_id_pat_household = i_id_pat)
            THEN
                g_error := 'GET CURSOR O_PAT_DET 1';
                OPEN o_pat_household FOR
                    SELECT pat.id_patient,
                           --name
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T001'),
                                                                              'Y',
                                                                              'Y') title_name,
                           pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, i_episode, NULL) desc_name,
                           NULL flg_name,
                           --
                           --l_id_currency_default l_id_currency_default,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T007'), 'Y') title_date_birth,
                           pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof) desc_date_birth,
                           pk_date_utils.date_send(i_lang, pat.dt_birth, i_prof) flg_date_birth,
                           --
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T008'),
                                                                              'Y',
                                                                              'Y') title_gender,
                           pk_sysdomain.get_domain('PATIENT.GENDER', pat.gender, i_lang) desc_gender,
                           pat.gender flg_gender,
                           --
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T077'), 'Y') title_family_relationship,
                           NULL desc_family_relationship,
                           NULL flg_family_relationship,
                           --'N' flg_edit_info,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T017'), 'Y') title_marital_status,
                           pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', psa.marital_status, i_lang) desc_marital_status,
                           psa.marital_status flg_marital_status,
                           --
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T019'), 'Y') title_occupation,
                           decode(pj.id_occupation,
                                  NULL,
                                  pj.occupation_desc,
                                  pk_translation.get_translation(i_lang, o.code_occupation)) desc_occupation,
                           nvl(o.id_occupation, -1) flg_occupation,
                           --                      
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T020'), 'Y') title_scholarship,
                           pk_translation.get_translation(i_lang,
                                                          (SELECT s.code_scholarship
                                                             FROM scholarship s
                                                            WHERE s.id_scholarship = psa.id_scholarship)) desc_scholarship,
                           psa.id_scholarship flg_scholarship,
                           --
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T021'), 'Y') title_wage,
                           nvl2(to_char(net_wage),
                                (to_char(net_wage) || ' ' ||
                                (SELECT currency_desc
                                    FROM currency
                                   WHERE id_currency = nvl(psa.id_currency_net_wage, l_id_currency_default))),
                                NULL) desc_wage,
                           nvl(net_wage, 0) flg_wage,
                           l_mask_wage flg_mask_wage,
                           0 flg_min_wage,
                           NULL flg_max_wage,
                           --psa.id_currency_net_wage id_unit_measure_wage,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T022'), 'Y') title_pension,
                           nvl2(to_char(pension),
                                (to_char(pension) || ' ' ||
                                (SELECT currency_desc
                                    FROM currency
                                   WHERE id_currency = nvl(psa.id_currency_pension, l_id_currency_default))),
                                NULL) desc_pension,
                           nvl(pension, 0) flg_pension,
                           l_mask_pension flg_mask_pension,
                           0 flg_min_pension,
                           NULL flg_max_pension,
                           -- psa.id_currency_pension id_unit_measure_pension,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T023'), 'Y') title_unemployment,
                           nvl2(to_char(unemployment_subsidy),
                                (to_char(unemployment_subsidy) || ' ' ||
                                (SELECT currency_desc
                                    FROM currency
                                   WHERE id_currency = nvl(psa.id_currency_unemp_sub, l_id_currency_default))),
                                NULL) desc_unemployment,
                           nvl(unemployment_subsidy, 0) flg_unemployment,
                           l_mask_unempl flg_mask_unemployment,
                           0 flg_min_unemployment,
                           NULL flg_max_unemployment,
                           --,psa.id_currency_unemp_sub id_unit_measure_unemployment
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T093'), 'Y') title_dependency_level,
                           pk_sysdomain.get_domain('PATIENT.FLG_DEPENDENCE_LEVEL', pat.flg_dependence_level, i_lang) desc_dependency_level,
                           pat.flg_dependence_level flg_dependency_level,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T145'), 'Y') title_fam_doctor,
                           get_family_doctor(i_lang, pat.id_patient, i_prof) desc_fam_doctor,
                           get_family_doctor(i_lang, pat.id_patient, i_prof, pk_alert_constant.g_no) flg_fam_doctor
                      FROM patient pat,
                           pat_soc_attributes psa,
                           occupation o,
                           (SELECT *
                              FROM pat_job
                             WHERE dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                                        FROM pat_job p1
                                                       WHERE p1.id_patient = i_id_pat)) pj
                     WHERE pat.id_patient = i_id_pat
                          --AND pat.flg_status = g_patient_active
                       AND pj.id_patient(+) = psa.id_patient
                       AND o.id_occupation(+) = pj.id_occupation
                       AND pat.id_patient = psa.id_patient(+);
            ELSE
                pk_alertlog.log_debug('Edit a patient that belongs to the household!');
                g_error := 'GET CURSOR O_PAT_DET 2';
                OPEN o_pat_household FOR
                    SELECT pat.id_patient,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T001'),
                                                                              'Y',
                                                                              'Y') title_name,
                           pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, i_episode, NULL) desc_name,
                           NULL flg_name,
                           --
                           --l_id_currency_default l_id_currency_default,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T007'), 'Y') title_date_birth,
                           pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof) desc_date_birth,
                           pk_date_utils.date_send(i_lang, pat.dt_birth, i_prof) flg_date_birth,
                           --
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T008'), 'Y') title_gender,
                           pk_sysdomain.get_domain('PATIENT.GENDER', pat.gender, i_lang) desc_gender,
                           pat.gender flg_gender,
                           --
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T077'),
                                                                              'Y',
                                                                              'Y') title_family_relationship,
                           pk_translation.get_translation(i_lang, fr.code_family_relationship) desc_family_relationship,
                           fr.id_family_relationship flg_family_relationship,
                           --'N' flg_edit_info,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T017'), 'Y') title_marital_status,
                           pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', psa.marital_status, i_lang) desc_marital_status,
                           psa.marital_status flg_marital_status,
                           --
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T019'), 'Y') title_occupation,
                           decode(pj.id_occupation,
                                  NULL,
                                  pj.occupation_desc,
                                  pk_translation.get_translation(i_lang, o.code_occupation)) desc_occupation,
                           
                           nvl(o.id_occupation, -1) flg_occupation,
                           --                      
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T020'), 'Y') title_scholarship,
                           pk_translation.get_translation(i_lang,
                                                          (SELECT s.code_scholarship
                                                             FROM scholarship s
                                                            WHERE s.id_scholarship = psa.id_scholarship)) desc_scholarship,
                           psa.id_scholarship flg_scholarship,
                           --
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T021'), 'Y') title_wage,
                           nvl2(to_char(net_wage),
                                (to_char(net_wage) || ' ' ||
                                (SELECT currency_desc
                                    FROM currency
                                   WHERE id_currency = nvl(psa.id_currency_net_wage, l_id_currency_default))),
                                NULL) desc_wage,
                           nvl(net_wage, 0) flg_wage,
                           l_mask_wage flg_mask_wage,
                           0 flg_min_wage,
                           NULL flg_max_wage,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T022'), 'Y') title_pension,
                           nvl2(to_char(pension),
                                (to_char(pension) || ' ' ||
                                (SELECT currency_desc
                                    FROM currency
                                   WHERE id_currency = nvl(psa.id_currency_pension, l_id_currency_default))),
                                NULL) desc_pension,
                           nvl(pension, 0) flg_pension,
                           l_mask_pension flg_mask_pension,
                           0 flg_min_pension,
                           NULL flg_max_pension,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T023'), 'Y') title_unemployment,
                           nvl2(to_char(unemployment_subsidy),
                                (to_char(unemployment_subsidy) || ' ' ||
                                (SELECT currency_desc
                                    FROM currency
                                   WHERE id_currency = nvl(psa.id_currency_unemp_sub, l_id_currency_default))),
                                NULL) desc_unemployment,
                           nvl(unemployment_subsidy, 0) flg_unemployment,
                           l_mask_unempl flg_mask_unemployment,
                           0 flg_min_unemployment,
                           NULL flg_max_unemployment,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T093'), 'Y') title_dependency_level,
                           pk_sysdomain.get_domain('PATIENT.FLG_DEPENDENCE_LEVEL', pat.flg_dependence_level, i_lang) desc_dependency_level,
                           pat.flg_dependence_level flg_dependency_level,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T145'), 'Y') title_fam_doctor,
                           get_family_doctor(i_lang, pat.id_patient, i_prof) desc_fam_doctor,
                           get_family_doctor(i_lang, pat.id_patient, i_prof, pk_alert_constant.g_no) flg_fam_doctor
                      FROM patient pat,
                           pat_soc_attributes psa,
                           family_relationship fr,
                           pat_family_member pfm,
                           occupation o,
                           (SELECT *
                              FROM pat_job
                             WHERE dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                                        FROM pat_job p1
                                                       WHERE p1.id_patient = i_id_pat_household)) pj
                     WHERE pat.id_patient = i_id_pat_household
                          --AND pat.flg_status = pk_alert_constant.g_flg_status_a
                       AND pfm.id_pat_related(+) = pat.id_patient
                       AND pfm.id_family_relationship = fr.id_family_relationship
                       AND pj.id_patient(+) = psa.id_patient
                       AND o.id_occupation(+) = pj.id_occupation
                       AND pat.id_patient = psa.id_patient(+);
            END IF;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_household);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOUSEHOLD_EDIT',
                                                     o_error);
    END get_household_edit;
    --

    /********************************************************************************************
     * Get patient's social class and its criteria values
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat_g_crit             Info
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_social_class
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_show_cancel       IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label IN VARCHAR2 DEFAULT 'N',
        o_social_class      OUT pk_types.cursor_type,
        o_prof_social_class OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --t_cur_graffar_crit IS TABLE OF VARCHAR2;
        l_t_cur_graffar_crit table_varchar := table_varchar();
        --
        l_pat_family pat_family.id_pat_family%TYPE;
        --
        l_social_class_info PLS_INTEGER;
        --
        l_show_cancelled VARCHAR2(1 CHAR) := '-';
        --
        CURSOR c_social_class_info IS
            SELECT COUNT(*)
              FROM pat_graffar_crit pgc
             WHERE pgc.id_patient = i_id_pat;
    
    BEGIN
        --the patient already has social class information?
        pk_alertlog.log_debug('GET_SOCIAL_CLASS - The patient already have information for social class?');
        --
        g_error := 'Get patient family!';
        --get pat_family ID
        SELECT id_pat_family
          INTO l_pat_family
          FROM patient p
         WHERE p.id_patient = i_id_pat;
        --
        OPEN c_social_class_info;
        FETCH c_social_class_info
            INTO l_social_class_info;
        g_found := c_social_class_info%NOTFOUND;
        CLOSE c_social_class_info;
    
        ---show cancelled records
        IF i_show_cancel <> pk_alert_constant.get_yes
        THEN
            l_show_cancelled := 'C';
        END IF;
    
        -- 
        IF (g_found OR l_social_class_info = 0)
        THEN
            pk_types.open_my_cursor(o_social_class);
            pk_types.open_my_cursor(o_prof_social_class);
        ELSE
        
            pk_alertlog.log_debug('GET_SOCIAL_CLASS - Information found');
            SELECT pk_paramedical_prof_core.format_str_header_w_colon(titulo) || valor desc_valor
              BULK COLLECT
              INTO l_t_cur_graffar_crit
              FROM (SELECT titulo, id_graf_crit, valor, ordena
                      FROM (SELECT *
                              FROM (SELECT pk_message.get_message(i_lang, 'SOCIAL_T062') titulo,
                                           0 id_graf_crit,
                                           nvl2(sc.code_social_class,
                                                pk_translation.get_translation(i_lang, sc.code_social_class),
                                                pk_paramedical_prof_core.c_dashes) valor,
                                           1 ordena
                                      FROM pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                                     WHERE pf.id_pat_family = (SELECT pat.id_pat_family
                                                                 FROM patient pat
                                                                WHERE pat.id_patient = i_id_pat)
                                       AND pfsch.id_pat_family(+) = pf.id_pat_family
                                       AND pfsch.id_social_class = sc.id_social_class(+)
                                     ORDER BY pfsch.dt_registry_tstz DESC)
                             WHERE rownum <= 1
                            UNION ALL
                            SELECT *
                              FROM (SELECT pk_translation.get_translation(i_lang, gc.code_graffar_criteria) titulo,
                                           gc.id_graffar_criteria id_graf_crit,
                                           nvl2(gcv.val,
                                                to_char(gcv.val) || '-' ||
                                                pk_translation.get_translation(i_lang, gcv.code_graffar_crit_value),
                                                pk_paramedical_prof_core.c_dashes) valor,
                                           gc.rank ordena
                                      FROM pat_graffar_crit       pgc,
                                           graffar_crit_value     gcv,
                                           graffar_criteria       gc,
                                           pat_fam_soc_class_hist pfsch
                                     WHERE pgc.id_graffar_crit_value(+) = gcv.id_graffar_crit_value
                                       AND gc.id_graffar_criteria = gcv.id_graffar_criteria
                                       AND pgc.id_patient = i_id_pat
                                       AND pfsch.id_pat_fam_soc_class_hist(+) = pgc.id_pat_fam_soc_class_hist
                                     ORDER BY pfsch.dt_registry_tstz DESC)
                             WHERE rownum <= 5
                            --the social class must exist
                            --AND (pgc.flg_status IS NULL OR pgc.flg_status <> pk_alert_constant.g_flg_status_c)
                            UNION ALL
                            SELECT *
                              FROM (SELECT pk_message.get_message(i_lang, 'SOCIAL_T082') titulo,
                                           99 id_graf_crit,
                                           nvl(pfsch.notes, pk_paramedical_prof_core.c_dashes) valor,
                                           99 ordena
                                      FROM pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                                     WHERE pf.id_pat_family = (SELECT pat.id_pat_family
                                                                 FROM patient pat
                                                                WHERE pat.id_patient = i_id_pat)
                                       AND pfsch.id_pat_family(+) = pf.id_pat_family
                                       AND pfsch.id_social_class = sc.id_social_class(+)
                                     ORDER BY pfsch.dt_registry_tstz DESC)
                             WHERE rownum <= 1
                            UNION ALL
                            SELECT *
                              FROM (SELECT decode(pfsch.flg_status,
                                                  pk_alert_constant.g_flg_status_c,
                                                  pk_message.get_message(i_lang, 'COMMON_M072'),
                                                  NULL) titulo,
                                           999 id_graf_crit,
                                           decode(pfsch.flg_status,
                                                  pk_alert_constant.g_flg_status_c,
                                                  pk_paramedical_prof_core.get_cancel_reason_desc(i_lang,
                                                                                                  i_prof,
                                                                                                  pfsch.id_cancel_info_det),
                                                  NULL) valor,
                                           999 ordena
                                      FROM pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                                     WHERE pf.id_pat_family = (SELECT pat.id_pat_family
                                                                 FROM patient pat
                                                                WHERE pat.id_patient = i_id_pat)
                                       AND pfsch.id_pat_family(+) = pf.id_pat_family
                                       AND pfsch.id_social_class = sc.id_social_class(+)
                                     ORDER BY pfsch.dt_registry_tstz DESC)
                             WHERE rownum <= 1
                            UNION ALL
                            SELECT *
                              FROM (SELECT decode(pfsch.flg_status,
                                                  pk_alert_constant.g_flg_status_c,
                                                  pk_message.get_message(i_lang, 'COMMON_M073'),
                                                  NULL) titulo,
                                           9999 id_graf_crit,
                                           decode(pfsch.flg_status,
                                                  pk_alert_constant.g_flg_status_c,
                                                  pk_paramedical_prof_core.get_notes_desc(i_lang,
                                                                                          i_prof,
                                                                                          pfsch.id_cancel_info_det),
                                                  NULL) valor,
                                           9999 ordena
                                      FROM pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                                     WHERE pf.id_pat_family = (SELECT pat.id_pat_family
                                                                 FROM patient pat
                                                                WHERE pat.id_patient = i_id_pat)
                                       AND pfsch.id_pat_family(+) = pf.id_pat_family
                                       AND pfsch.id_social_class = sc.id_social_class(+)
                                     ORDER BY pfsch.dt_registry_tstz DESC)
                             WHERE rownum <= 1)
                     ORDER BY 4);
        
            g_error := 'GET CURSOR O_SOCIAL_CLASS';
            OPEN o_social_class FOR
                SELECT l_pat_family id,
                       decode(i_show_header_label,
                              pk_alert_constant.g_yes,
                              REPLACE(pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                                'SOCIAL_T062')),
                                      pk_paramedical_prof_core.c_colon) || chr(10),
                              NULL) field_header,
                       l_t_cur_graffar_crit(1) || chr(10) desc_social_class,
                       l_t_cur_graffar_crit(2) desc_social_ocupation,
                       l_t_cur_graffar_crit(3) desc_education_level,
                       l_t_cur_graffar_crit(4) desc_income,
                       l_t_cur_graffar_crit(5) desc_house,
                       l_t_cur_graffar_crit(6) desc_house_location,
                       l_t_cur_graffar_crit(7) desc_notes,
                       l_t_cur_graffar_crit(8) cancel_reason,
                       l_t_cur_graffar_crit(9) cancel_notes
                  FROM dual;
        
            g_error := 'GET CURSOR O_PAT_PROF_SOCIAL_CLASS';
            OPEN o_prof_social_class FOR
                SELECT *
                  FROM (SELECT *
                          FROM (SELECT pf.id_pat_family id,
                                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, pfsch.dt_registry_tstz, i_prof) dt,
                                       pk_tools.get_prof_description(i_lang,
                                                                     i_prof,
                                                                     pfsch.id_professional,
                                                                     pfsch.dt_registry_tstz,
                                                                     NULL) prof_sign,
                                       pfsch.flg_status flg_status,
                                       pfsch.dt_registry_tstz dt_registry_tstz
                                  FROM patient pat, pat_family pf, pat_fam_soc_class_hist pfsch
                                 WHERE pat.id_pat_family = pf.id_pat_family
                                   AND pat.id_patient = i_id_pat
                                   AND pf.id_pat_family = pfsch.id_pat_family
                                 ORDER BY dt_registry_tstz DESC NULLS LAST)
                         WHERE rownum <= 1)
                --in the summary the cancelled records are not displayed
                 WHERE l_show_cancelled <> flg_status;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_social_class);
            pk_types.open_my_cursor(o_prof_social_class);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_SOCIAL_CLASS',
                                                     o_error);
        
    END get_social_class;

    /********************************************************************************************
     * Get patient's social class and its criteria values to use in the summary page
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_patient             Patient ID      
     * @param o_id_pat_fam_soc_class   Patient family social class id
     * @param o_pat_fam_soc_desc       Patient's social class
     *
     * @return                         True on success, False otherwise
     *
     * @author                         Diogo Oliveira
     * @version                        v2.7.3.6
     * @since                          2018/11/19
    **********************************************************************************************/
    FUNCTION get_soc_class_summary_page
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        o_id_pat_fam_soc_class OUT pat_fam_soc_class_hist.id_pat_fam_soc_class_hist%TYPE,
        o_pat_fam_soc_desc     OUT VARCHAR2
    ) RETURN BOOLEAN IS
        l_t_cur_graffar_crit table_varchar := table_varchar();
        --
        l_pat_family pat_family.id_pat_family%TYPE;
        --
        l_social_class_info PLS_INTEGER;
        --
        l_social_class VARCHAR2(4000);
        --
        CURSOR c_social_class_info IS
            SELECT COUNT(*)
              FROM pat_graffar_crit pgc
             WHERE pgc.id_patient = i_id_patient;
    
    BEGIN
        g_error := 'Get patient family!';
        --get pat_family ID
        SELECT id_pat_family
          INTO l_pat_family
          FROM patient p
         WHERE p.id_patient = i_id_patient;
        --
        OPEN c_social_class_info;
        FETCH c_social_class_info
            INTO l_social_class_info;
        g_found := c_social_class_info%NOTFOUND;
        CLOSE c_social_class_info;
    
        -- 
        IF NOT g_found
           OR l_social_class_info > 0
        THEN
            pk_alertlog.log_debug('GET_SOCIAL_CLASS_ID');
            SELECT id_pat_fam_soc_class_hist
              INTO o_id_pat_fam_soc_class
              FROM (SELECT *
                      FROM (SELECT p.id_pat_fam_soc_class_hist, p.flg_status
                              FROM pat_fam_soc_class_hist p
                             WHERE p.id_pat_family = l_pat_family
                             ORDER BY p.dt_registry_tstz DESC)
                     WHERE rownum = 1)
             WHERE flg_status <> pk_alert_constant.g_cancelled;
        
            IF o_id_pat_fam_soc_class IS NOT NULL
            THEN
            
                pk_alertlog.log_debug('GET_SOCIAL_CLASS - Information found');
                SELECT titulo || chr(58) || chr(32) || valor desc_valor
                  BULK COLLECT
                  INTO l_t_cur_graffar_crit
                  FROM (SELECT titulo, id_graf_crit, valor, ordena
                          FROM (SELECT *
                                  FROM (SELECT pk_message.get_message(i_lang, 'SOCIAL_T062') titulo,
                                               0 id_graf_crit,
                                               nvl2(sc.code_social_class,
                                                    pk_translation.get_translation(i_lang, sc.code_social_class),
                                                    pk_paramedical_prof_core.c_dashes) valor,
                                               1 ordena,
                                               pfsch.flg_status
                                          FROM pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                                         WHERE pf.id_pat_family =
                                               (SELECT pat.id_pat_family
                                                  FROM patient pat
                                                 WHERE pat.id_patient = i_id_patient)
                                           AND pfsch.id_pat_family(+) = pf.id_pat_family
                                           AND pfsch.id_social_class = sc.id_social_class(+)
                                         ORDER BY pfsch.dt_registry_tstz DESC)
                                 WHERE rownum <= 1
                                UNION ALL
                                SELECT *
                                  FROM (SELECT pk_translation.get_translation(i_lang, gc.code_graffar_criteria) titulo,
                                               gc.id_graffar_criteria id_graf_crit,
                                               nvl2(gcv.val,
                                                    to_char(gcv.val) || '-' ||
                                                    pk_translation.get_translation(i_lang, gcv.code_graffar_crit_value),
                                                    pk_paramedical_prof_core.c_dashes) valor,
                                               gc.rank ordena,
                                               pfsch.flg_status
                                          FROM pat_graffar_crit       pgc,
                                               graffar_crit_value     gcv,
                                               graffar_criteria       gc,
                                               pat_fam_soc_class_hist pfsch
                                         WHERE pgc.id_graffar_crit_value(+) = gcv.id_graffar_crit_value
                                           AND gc.id_graffar_criteria = gcv.id_graffar_criteria
                                           AND pgc.id_patient = i_id_patient
                                           AND pfsch.id_pat_fam_soc_class_hist(+) = pgc.id_pat_fam_soc_class_hist
                                           AND pfsch.flg_status <> pk_alert_constant.g_cancelled
                                         ORDER BY pfsch.dt_registry_tstz DESC)
                                 WHERE rownum <= 5
                                UNION ALL
                                SELECT *
                                  FROM (SELECT pk_message.get_message(i_lang, 'SOCIAL_T082') titulo,
                                               99 id_graf_crit,
                                               nvl(pfsch.notes, pk_paramedical_prof_core.c_dashes) valor,
                                               99 ordena,
                                               pfsch.flg_status
                                          FROM pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                                         WHERE pf.id_pat_family =
                                               (SELECT pat.id_pat_family
                                                  FROM patient pat
                                                 WHERE pat.id_patient = i_id_patient)
                                           AND pfsch.id_pat_family(+) = pf.id_pat_family
                                           AND pfsch.id_social_class = sc.id_social_class(+)
                                         ORDER BY pfsch.dt_registry_tstz DESC)
                                 WHERE rownum <= 1)
                         WHERE flg_status <> pk_alert_constant.g_cancelled
                         ORDER BY ordena);
            
                g_error := 'GET l_social_class';
            
                FOR i IN l_t_cur_graffar_crit.first .. l_t_cur_graffar_crit.last
                LOOP
                    IF i < l_t_cur_graffar_crit.last
                    THEN
                        l_social_class := l_social_class || l_t_cur_graffar_crit(i) || chr(13);
                    ELSE
                        l_social_class := l_social_class || l_t_cur_graffar_crit(i);
                    END IF;
                END LOOP;
            
            ELSE
                o_pat_fam_soc_desc := NULL;
            END IF;
        END IF;
    
        o_pat_fam_soc_desc := l_social_class;
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_id_pat_fam_soc_class := NULL;
            o_pat_fam_soc_desc     := NULL;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END get_soc_class_summary_page;

    /********************************************************************************************
     * Get the social class information for the create/edit screen. If no information exists 
     * for the given patient the cursor returns only the screen's labels, otherwise it 
     * returns the information previously created.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Selected patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_social_class           Social class information
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_social_class_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat       IN patient.id_patient%TYPE,
        i_prof         IN profissional,
        o_social_class OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --t_cur_graffar_crit IS TABLE OF VARCHAR2;
        l_t_cur_graffar_crit table_table_varchar := table_table_varchar();
    
        l_social_class_info PLS_INTEGER;
    
        CURSOR c_social_class_info IS
            SELECT COUNT(*)
              FROM pat_graffar_crit pgc
             WHERE pgc.id_patient = i_id_pat
               AND (pgc.flg_status IS NULL OR pgc.flg_status <> pk_alert_constant.g_flg_status_c);
    BEGIN
        --the patient already has social class information?
        pk_alertlog.log_debug('GET_SOCIAL_CLASS - The patient already have information for social class?');
        OPEN c_social_class_info;
        FETCH c_social_class_info
            INTO l_social_class_info;
        g_found := c_social_class_info%NOTFOUND;
        CLOSE c_social_class_info;
    
        IF g_found
           OR l_social_class_info = 0
        THEN
            SELECT table_varchar(titulo, valor, flg) desc_valor
              BULK COLLECT
              INTO l_t_cur_graffar_crit
              FROM (SELECT titulo, id_graf_crit, valor, flg, ordena
                      FROM (SELECT pk_message.get_message(i_lang, 'SOCIAL_T062') titulo,
                                   0 id_graf_crit,
                                   pk_translation.get_translation(i_lang, sc.code_social_class) valor,
                                   NULL flg,
                                   1 ordena
                              FROM patient pat, pat_family pf, social_class sc
                             WHERE pat.id_pat_family = pf.id_pat_family(+)
                               AND pf.id_social_class = sc.id_social_class(+)
                               AND pat.id_patient = i_id_pat
                            --   
                            UNION ALL
                            SELECT DISTINCT pk_paramedical_prof_core.format_str_header_w_colon(pk_translation.get_translation(i_lang,
                                                                                                                              gc.code_graffar_criteria),
                                                                                               'Y',
                                                                                               'Y') titulo,
                                            gc.id_graffar_criteria id_graf_crit,
                                            NULL valor,
                                            /*to_char(gcv.val)*/
                                            NULL    flg,
                                            gc.rank ordena
                              FROM graffar_crit_value gcv, graffar_criteria gc
                             WHERE gc.id_graffar_criteria = gcv.id_graffar_criteria
                               AND gc.flg_available = pk_alert_constant.g_yes
                               AND gcv.flg_available = pk_alert_constant.g_yes
                            --
                            UNION ALL
                            SELECT pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                             'SOCIAL_T082'),
                                                                                      'Y') titulo,
                                   99999 id_graf_crit,
                                   --nvl(pf.social_class_notes, pk_message.get_message(i_lang, 'COMMON_M007')) valor,
                                   pf.social_class_notes valor,
                                   pf.social_class_notes flg,
                                   99999                 ordena
                              FROM patient pat, pat_family pf, social_class sc
                             WHERE pat.id_pat_family = pf.id_pat_family(+)
                               AND pf.id_social_class = sc.id_social_class(+)
                               AND pat.id_patient = i_id_pat)
                     ORDER BY 5);
        ELSE
            SELECT table_varchar(titulo, valor, flg) desc_valor
              BULK COLLECT
              INTO l_t_cur_graffar_crit
              FROM (SELECT titulo, id_graf_crit, valor, flg, ordena
                      FROM (SELECT *
                              FROM (SELECT pk_message.get_message(i_lang, 'SOCIAL_T062') titulo,
                                           0 id_graf_crit,
                                           pk_translation.get_translation(i_lang, sc.code_social_class) valor,
                                           NULL flg,
                                           1 ordena
                                      FROM patient pat, pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                                     WHERE pat.id_pat_family = pf.id_pat_family
                                       AND pat.id_patient = i_id_pat
                                       AND pfsch.id_pat_family = pf.id_pat_family
                                       AND pfsch.id_social_class = sc.id_social_class
                                     ORDER BY pfsch.dt_registry_tstz DESC)
                             WHERE rownum <= 1
                            --   
                            UNION ALL
                            SELECT *
                              FROM (SELECT pk_paramedical_prof_core.format_str_header_w_colon(pk_translation.get_translation(i_lang,
                                                                                                                             gc.code_graffar_criteria),
                                                                                              'Y',
                                                                                              'Y') titulo,
                                           gc.id_graffar_criteria id_graf_crit,
                                           pk_translation.get_translation(i_lang, gcv.code_graffar_crit_value) valor,
                                           /*to_char(gcv.val)*/
                                           to_char(pgc.id_graffar_crit_value) flg,
                                           gc.rank ordena
                                      FROM pat_graffar_crit       pgc,
                                           graffar_crit_value     gcv,
                                           graffar_criteria       gc,
                                           pat_fam_soc_class_hist pfsch
                                     WHERE pgc.id_graffar_crit_value(+) = gcv.id_graffar_crit_value
                                       AND gc.id_graffar_criteria = gcv.id_graffar_criteria
                                       AND pgc.id_patient = i_id_pat
                                       AND pfsch.id_pat_fam_soc_class_hist(+) = pgc.id_pat_fam_soc_class_hist
                                     ORDER BY pfsch.dt_registry_tstz DESC)
                             WHERE rownum <= 5
                            --   
                            UNION ALL
                            SELECT *
                              FROM (SELECT pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                                     'SOCIAL_T082'),
                                                                                              'Y') titulo,
                                           99999 id_graf_crit,
                                           -- nvl(pf.social_class_notes, pk_message.get_message(i_lang, 'COMMON_M007')) valor,
                                           pf.social_class_notes valor,
                                           pf.social_class_notes flg,
                                           99999                 ordena
                                      FROM patient pat, pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                                     WHERE pat.id_pat_family = pf.id_pat_family
                                       AND pat.id_patient = i_id_pat
                                       AND pfsch.id_pat_family = pf.id_pat_family
                                       AND pfsch.id_social_class = sc.id_social_class
                                     ORDER BY pfsch.dt_registry_tstz DESC)
                             WHERE rownum <= 1)
                     ORDER BY 5);
        END IF;
        g_error := 'GET CURSOR O_SOCIAL_CLASS';
        OPEN o_social_class FOR
            SELECT NULL id,
                   --
                   l_t_cur_graffar_crit(2)(1) title_social_ocupation,
                   l_t_cur_graffar_crit(2)(2) desc_social_ocupation,
                   l_t_cur_graffar_crit(2)(3) flg_social_ocupation,
                   --
                   l_t_cur_graffar_crit(3)(1) title_education_level,
                   l_t_cur_graffar_crit(3)(2) desc_education_level,
                   l_t_cur_graffar_crit(3)(3) flg_education_level,
                   --
                   l_t_cur_graffar_crit(4)(1) title_income,
                   l_t_cur_graffar_crit(4)(2) desc_income,
                   l_t_cur_graffar_crit(4)(3) flg_income,
                   --
                   l_t_cur_graffar_crit(5)(1) title_house,
                   l_t_cur_graffar_crit(5)(2) desc_house,
                   l_t_cur_graffar_crit(5)(3) flg_house,
                   --
                   l_t_cur_graffar_crit(6)(1) title_house_location,
                   l_t_cur_graffar_crit(6)(2) desc_house_location,
                   l_t_cur_graffar_crit(6)(3) flg_house_location,
                   --
                   l_t_cur_graffar_crit(7)(1) title_notes,
                   l_t_cur_graffar_crit(7)(2) desc_notes,
                   l_t_cur_graffar_crit(7)(3) flg_notes
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_social_class);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_SOCIAL_CLASS_EDIT',
                                                     o_error);
        
    END get_social_class_edit;
    --

    /********************************************************************************************
     * Get patient's social class and its criteria values
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat_g_crit             Info
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          ORlando Antunes
     * @version                         0.1
     * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_social_class_internal_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pat           IN patient.id_patient%TYPE,
        i_social_class_num IN social_class.code_social_class%TYPE
    ) RETURN VARCHAR2 IS
        l_social_class_code social_class.code_social_class%TYPE;
        l_error             t_error_out;
    BEGIN
        g_error := 'GET CURSOR O_PAT_G_CRIT';
        SELECT sc.code_social_class
          INTO l_social_class_code
          FROM patient pat, pat_family pf, social_class sc
         WHERE pat.id_pat_family = pf.id_pat_family
           AND pf.id_social_class(+) = sc.id_social_class
           AND pat.id_patient = i_id_pat
           AND EXISTS (SELECT i_social_class_num
                  FROM pat_graffar_crit pg
                 WHERE pat.id_patient = pg.id_patient);
        RETURN l_social_class_code;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SOCIAL',
                                              'GET_SOCIAL_CLASS_INTERNAL_ID',
                                              l_error);
            RETURN NULL;
        
    END get_social_class_internal_id;

    /********************************************************************************************
     * Get patient's social class and its criteria values
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_graf_crit              Criteria ID 
     *
     * @param o_crit                   Criteria values for a given criteria
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_graff_criteria_value_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_graf_crit IN graffar_criteria.id_graffar_criteria%TYPE,
        o_crit      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR O_CRIT';
        OPEN o_crit FOR
            SELECT id_graf_crit_val data, value_criteria label
              FROM (SELECT gc.id_graffar_criteria id_graf_crit,
                           gcv.id_graffar_crit_value id_graf_crit_val,
                           pk_translation.get_translation(i_lang, gcv.code_graffar_crit_value) value_criteria
                      FROM graffar_criteria gc, graffar_crit_value gcv
                     WHERE gc.id_graffar_criteria = gcv.id_graffar_criteria
                       AND gcv.id_graffar_criteria = i_graf_crit
                       AND gcv.flg_available = pk_alert_constant.g_yes
                     ORDER BY gcv.rank ASC);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_crit);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_GRAFF_CRITERIA_VALUE_LIST',
                                                     o_error);
        
    END get_graff_criteria_value_list;

    /********************************************************************************************
    * Get domains values for the social class fields.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *
    * @ param o_ocupation_domain      Occupation domain list
    * @ param o_education_level_domain Education domain list
    * @ param o_income_domain          Income domain list
    * @ param o_house_domain           House domain list
    * @ param o_house_location_domain  House location list
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_social_class_domains
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        o_ocupation_domain       OUT pk_types.cursor_type,
        o_education_level_domain OUT pk_types.cursor_type,
        o_income_domain          OUT pk_types.cursor_type,
        o_house_domain           OUT pk_types.cursor_type,
        o_house_location_domain  OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET SOCIAL CLASS OCCUPATION LIST';
        IF NOT get_graff_criteria_value_list(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_graf_crit => 1, --occupation
                                             o_crit      => o_ocupation_domain,
                                             o_error     => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error := 'GET SOCIAL CLASS EDUCATION LIST';
        IF NOT get_graff_criteria_value_list(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_graf_crit => 2, --education_level
                                             o_crit      => o_education_level_domain,
                                             o_error     => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error := 'GET SOCIAL CLASS INCOME LIST';
        IF NOT get_graff_criteria_value_list(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_graf_crit => 3, --income
                                             o_crit      => o_income_domain,
                                             o_error     => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error := 'GET SOCIAL CLASS HOME LIST';
        IF NOT get_graff_criteria_value_list(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_graf_crit => 4, --house
                                             o_crit      => o_house_domain,
                                             o_error     => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error := 'GET SOCIAL CLASS HOUSE_LOCATION LIST';
        IF NOT get_graff_criteria_value_list(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_graf_crit => 5, --house_location
                                             o_crit      => o_house_location_domain,
                                             o_error     => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_ocupation_domain);
            pk_types.open_my_cursor(o_education_level_domain);
            pk_types.open_my_cursor(o_income_domain);
            pk_types.open_my_cursor(o_house_domain);
            pk_types.open_my_cursor(o_house_location_domain);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_SOCIAL_CLASS_DOMAINS',
                                                     o_error);
        
    END get_social_class_domains;
    --

    /********************************************************************************************
     * Create patient's social class
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat_graf_crit       Patient's social class record ID
     * @param i_id_pat                 Patient ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          ET
     * @version                         0.1
     * @since                           2006/04/27
    **********************************************************************************************/
    FUNCTION set_pat_soc_class
    (
        i_lang             IN language.id_language%TYPE,
        i_id_pat_graf_crit IN table_number,
        i_id_pat           IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_val_graf_crit   graffar_crit_value.val%TYPE;
        l_char            VARCHAR2(1);
        l_error           t_error_out;
        l_class_number    NUMBER := 0;
        l_id_social_class social_class.id_social_class%TYPE;
        l_id_pat_fam      pat_family.id_pat_family%TYPE;
        l_fam_s_class     pat_family.id_social_class%TYPE;
    
        CURSOR c_pat_g_crit IS
            SELECT 'X'
              FROM pat_graffar_crit
             WHERE id_patient = i_id_pat
               AND id_professional = i_prof.id;
    
        CURSOR c_pat_family IS
            SELECT id_social_class
              FROM patient pat, pat_family pf
             WHERE pat.id_pat_family = pf.id_pat_family
               AND pat.id_patient = i_id_pat;
    
    BEGIN
        pk_alertlog.log_debug('SET_PAT_SOC_CLASS: i_id_pat = ' || i_id_pat);
        -- Verificar se existe algum critério para o paciente
        g_error := 'GET CURSOR C_PAT_G_CRIT';
        OPEN c_pat_g_crit;
        FETCH c_pat_g_crit
            INTO l_char;
        g_found := c_pat_g_crit%NOTFOUND;
        CLOSE c_pat_g_crit;
        --
        IF NOT g_found
        THEN
            g_error := 'BEGIN LOOP';
            --
            FOR i IN 1 .. i_id_pat_graf_crit.count
            LOOP
                -- Qual o valor do critério
                g_error := 'CALL GET_VAL_GRAF_CRIT';
                IF NOT get_val_graf_crit(i_lang             => i_lang,
                                         i_id_pat           => i_id_pat,
                                         i_prof             => i_prof,
                                         i_id_pat_graf_crit => i_id_pat_graf_crit(i),
                                         o_val_g_crit       => l_val_graf_crit,
                                         o_error            => l_error)
                THEN
                    o_error := l_error;
                    RAISE g_exception;
                END IF;
                --
                l_class_number := l_class_number + nvl(l_val_graf_crit, 0);
            END LOOP;
        
            IF nvl(l_class_number, 0) <> 0
            THEN
                g_error := 'CALL GET_CLASS_SOCIAL';
            
                IF NOT get_social_class(i_lang            => i_lang,
                                        i_class_number    => l_class_number,
                                        o_id_social_class => l_id_social_class,
                                        o_error           => l_error)
                THEN
                    o_error := l_error;
                    RAISE g_exception;
                END IF;
                --
                g_error := 'CALL SET_PAT_FAM';
            
                IF NOT set_pat_fam(i_lang       => i_lang,
                                   i_id_pat     => i_id_pat,
                                   i_prof       => i_prof,
                                   i_commit     => 'N',
                                   o_id_pat_fam => l_id_pat_fam,
                                   o_error      => l_error)
                THEN
                    o_error := l_error;
                    RAISE g_exception;
                END IF;
                --
                g_error := 'GET CURSOR C_PAT_FAMILY';
                OPEN c_pat_family;
                FETCH c_pat_family
                    INTO l_fam_s_class;
                CLOSE c_pat_family;
                --
                IF nvl(l_fam_s_class, 0) <> nvl(l_id_social_class, 0)
                THEN
                    g_error := 'UPDATE PAT_FAMILY';
                    UPDATE pat_family
                       SET id_social_class = l_id_social_class
                     WHERE id_pat_family = l_id_pat_fam;
                    ---
                
                END IF;
            END IF;
            --
        END IF;
    
        --COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'SET_PAT_SOC_CLASS',
                                                     o_error);
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'SET_PAT_SOC_CLASS',
                                                     o_error);
        
    END;
    --

    /********************************************************************************************
    * Create patient's social class
    * 
    * @ param i_lang 
    * @param i_prof                   Object (professional ID, institution ID, software ID) 
    * @param i_id_pat                 Patient ID 
    * @ param i_epis                  Episode ID
    * @ param i_occupation_val        Occupation
    * @ param i_education_level_val   Education level
    * @ param i_income_val            Patient's income
    * @ param i_house_val             Patient's house
    * @ param i_house_location_val    Patient's house location
    * @param i_notes                  Social class notes
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION set_pat_social_class
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        i_epis   IN episode.id_episode%TYPE,
        --i_id_pat_graf_crit IN pat_graffar_crit.id_pat_graffar_crit%TYPE,
        i_occupation_val      IN graffar_crit_value.id_graffar_crit_value%TYPE,
        i_education_level_val IN graffar_crit_value.id_graffar_crit_value%TYPE,
        i_income_val          IN graffar_crit_value.id_graffar_crit_value%TYPE,
        i_house_val           IN graffar_crit_value.id_graffar_crit_value%TYPE,
        i_house_location_val  IN graffar_crit_value.id_graffar_crit_value%TYPE,
        i_notes               IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error  t_error_out;
        l_rowids table_varchar;
        --
        l_pat_graffar_crit pat_graffar_crit.id_pat_graffar_crit%TYPE;
    
        CURSOR c_pat_g_crit IS
            SELECT COUNT(*)
              FROM pat_graffar_crit pgc
             WHERE pgc.id_patient = i_id_pat
               AND (pgc.flg_status IS NULL OR pgc.flg_status <> pk_alert_constant.g_flg_status_c);
    
        l_pat_fam_row pat_family%ROWTYPE;
        l_pat_fam_id  pat_family.id_pat_family%TYPE;
    
        l_id_pat_fam_soc_class_hist pat_fam_soc_class_hist.id_pat_fam_soc_class_hist%TYPE;
    
        l_count_pat_graffar_crit PLS_INTEGER;
    BEGIN
        pk_alertlog.log_debug('SET_PAT_SOCIAL_CLASS: i_id_pat = ' || i_id_pat || ', i_occupation_val = ' ||
                              i_occupation_val || 'i_education_level_val = ' || i_education_level_val ||
                              'i_income_val = ' || i_income_val || ' i_house_val =' || i_house_val ||
                              'i_house_location_val = ' || i_house_location_val || 'i_notes = ' || i_notes);
    
        --
        g_sysdate_tstz := current_timestamp;
    
        --------------------------create new data for the patient-------------------------------------------
        -- Verificar qts registos já existem na PAT_GRAFFAR_CRIT
        g_error                     := 'GET_HISTORY_NEXT_ID';
        l_id_pat_fam_soc_class_hist := ts_pat_fam_soc_class_hist.next_key;
        g_error                     := 'GET CURSOR C_PAT_G_CRIT';
        --
        --validate if this is the first data for this patient
        OPEN c_pat_g_crit;
        FETCH c_pat_g_crit
            INTO l_count_pat_graffar_crit;
        CLOSE c_pat_g_crit;
    
        --
        pk_alertlog.log_debug('Creating new Social class information data for the pacient');
        IF i_occupation_val IS NOT NULL
           AND i_education_level_val IS NOT NULL
           AND i_income_val IS NOT NULL
           AND i_house_val IS NOT NULL
           AND i_house_location_val IS NOT NULL
        THEN
            --1
            g_error := 'INSERT PAT_GRAFFAR_CRIT 1';
            ts_pat_graffar_crit.ins(dt_pat_graffar_crit_tstz_in  => g_sysdate_tstz,
                                    id_patient_in                => i_id_pat,
                                    id_graffar_crit_value_in     => i_occupation_val,
                                    id_professional_in           => i_prof.id,
                                    id_episode_in                => i_epis,
                                    id_pat_fam_soc_class_hist_in => l_id_pat_fam_soc_class_hist,
                                    flg_status_in                => pk_alert_constant.g_flg_status_a,
                                    id_pat_graffar_crit_out      => l_pat_graffar_crit,
                                    handle_error_in              => FALSE,
                                    rows_out                     => l_rowids);
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_GRAFFAR_CRIT';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_GRAFFAR_CRIT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            --2
            g_error := 'INSERT PAT_GRAFFAR_CRIT 2';
            ts_pat_graffar_crit.ins(dt_pat_graffar_crit_tstz_in  => g_sysdate_tstz,
                                    id_patient_in                => i_id_pat,
                                    id_graffar_crit_value_in     => i_education_level_val,
                                    id_professional_in           => i_prof.id,
                                    id_episode_in                => i_epis,
                                    id_pat_fam_soc_class_hist_in => l_id_pat_fam_soc_class_hist,
                                    flg_status_in                => pk_alert_constant.g_flg_status_a,
                                    id_pat_graffar_crit_out      => l_pat_graffar_crit,
                                    handle_error_in              => FALSE,
                                    rows_out                     => l_rowids);
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_GRAFFAR_CRIT';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_GRAFFAR_CRIT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            --3
            g_error := 'INSERT PAT_GRAFFAR_CRIT 3';
            ts_pat_graffar_crit.ins(dt_pat_graffar_crit_tstz_in  => g_sysdate_tstz,
                                    id_patient_in                => i_id_pat,
                                    id_graffar_crit_value_in     => i_income_val,
                                    id_professional_in           => i_prof.id,
                                    id_episode_in                => i_epis,
                                    id_pat_fam_soc_class_hist_in => l_id_pat_fam_soc_class_hist,
                                    flg_status_in                => pk_alert_constant.g_flg_status_a,
                                    id_pat_graffar_crit_out      => l_pat_graffar_crit,
                                    rows_out                     => l_rowids);
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_GRAFFAR_CRIT';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_GRAFFAR_CRIT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            --4
            g_error := 'INSERT PAT_GRAFFAR_CRIT 4';
            ts_pat_graffar_crit.ins(dt_pat_graffar_crit_tstz_in  => g_sysdate_tstz,
                                    id_patient_in                => i_id_pat,
                                    id_graffar_crit_value_in     => i_house_val,
                                    id_professional_in           => i_prof.id,
                                    id_episode_in                => i_epis,
                                    id_pat_fam_soc_class_hist_in => l_id_pat_fam_soc_class_hist,
                                    flg_status_in                => pk_alert_constant.g_flg_status_a,
                                    id_pat_graffar_crit_out      => l_pat_graffar_crit,
                                    rows_out                     => l_rowids);
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_GRAFFAR_CRIT';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_GRAFFAR_CRIT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            --5
            g_error := 'INSERT PAT_GRAFFAR_CRIT 5';
            ts_pat_graffar_crit.ins(dt_pat_graffar_crit_tstz_in  => g_sysdate_tstz,
                                    id_patient_in                => i_id_pat,
                                    id_graffar_crit_value_in     => i_house_location_val,
                                    id_professional_in           => i_prof.id,
                                    id_episode_in                => i_epis,
                                    id_pat_fam_soc_class_hist_in => l_id_pat_fam_soc_class_hist,
                                    flg_status_in                => pk_alert_constant.g_flg_status_a,
                                    id_pat_graffar_crit_out      => l_pat_graffar_crit,
                                    rows_out                     => l_rowids);
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_GRAFFAR_CRIT';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_GRAFFAR_CRIT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSE
            g_error := 'INVALID INPUT PARAMETERS';
            RAISE g_sw_generic_exception;
        END IF;
    
        --
    
        --
        --Set social_class: Create and Edit actions
        g_error := 'SET_SOCIAL_CLASS - CALL SET_PAT_CLASS_SOC';
        IF NOT set_pat_soc_class(i_lang             => i_lang,
                                 i_id_pat_graf_crit => table_number(1, 2, 3, 4, 5),
                                 i_id_pat           => i_id_pat,
                                 i_prof             => i_prof,
                                 o_error            => l_error)
        THEN
            o_error := l_error;
            RAISE g_exception;
        END IF;
    
        g_error := 'GET PAT_FAMILY_ID : i_id_pat = ' || i_id_pat;
        SELECT id_pat_family
          INTO l_pat_fam_id
          FROM patient
         WHERE id_patient = i_id_pat;
    
        g_error := 'UPDATE PAT_FAMILY - SOCIAL_CLASS_NOTES';
        UPDATE pat_family
           SET social_class_notes = i_notes, id_prof_social_class = i_prof.id, dt_social_class_tstz = g_sysdate_tstz
         WHERE id_pat_family = l_pat_fam_id;
    
        SELECT *
          INTO l_pat_fam_row
          FROM pat_family pf
         WHERE pf.id_pat_family = l_pat_fam_id;
        --
        pk_alertlog.log_debug('SET SOCIAL CLASS HISTORY');
    
        --
    
        ts_pat_fam_soc_class_hist.ins(id_pat_fam_soc_class_hist_in => l_id_pat_fam_soc_class_hist,
                                      id_pat_family_in             => l_pat_fam_row.id_pat_family,
                                      id_social_class_in           => l_pat_fam_row.id_social_class,
                                      id_professional_in           => i_prof.id,
                                      dt_registry_tstz_in          => g_sysdate_tstz,
                                      notes_in                     => i_notes,
                                      flg_status_in                => CASE
                                                                          WHEN l_count_pat_graffar_crit <> 0 THEN
                                                                           pk_alert_constant.g_flg_status_e
                                                                          ELSE
                                                                           pk_alert_constant.g_flg_status_a
                                                                      END,
                                      rows_out                     => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_FAM_SOC_CLASS_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        --
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
        --
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'SET_PAT_SOCIAL_CLASS',
                                                     o_error);
        WHEN OTHERS THEN
            pk_utils.undo_changes;
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SOCIAL',
                                              'SET_PAT_SOCIAL_CLASS',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_pat_social_class;
    --

    /********************************************************************************************
    * Get patient's household financial information
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat_financial          Financial information cursor
    * @param o_pat_financial_prof     Professional that inputs the financial information        
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/04
    **********************************************************************************************/
    FUNCTION get_household_financial
    (
        i_lang               IN language.id_language%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_prof               IN profissional,
        i_show_cancel        IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label  IN VARCHAR2 DEFAULT 'N',
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_currency_default currency.id_currency%TYPE;
    
        v_total_members PLS_INTEGER;
        v_tot_pat_f_mem NUMBER;
        --
        l_show_cancelled VARCHAR2(1 CHAR) := '-';
        --
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET LABELS';
    
        --show cancelled records
        IF i_show_cancel <> pk_alert_constant.get_yes
        THEN
            l_show_cancelled := 'C';
        END IF;
    
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T024',
                                                                                          'SOCIAL_T025',
                                                                                          'SOCIAL_T026',
                                                                                          'SOCIAL_T027',
                                                                                          'SOCIAL_T028',
                                                                                          'SOCIAL_T029',
                                                                                          'SOCIAL_T030',
                                                                                          'SOCIAL_T031',
                                                                                          'SOCIAL_T082'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error               := 'GET CURRENCY DEFAUL - GET_FAM_MONEY';
        l_id_currency_default := get_currency_default(i_prof);
    
        v_total_members := get_total_family_members(i_id_pat);
    
        v_tot_pat_f_mem := get_total_family_money(i_id_pat, i_prof);
    
        g_error := 'GET CURSOR O_PAT';
        OPEN o_pat_financial FOR
            SELECT id,
                   field_header,
                   desc_allowance_family,
                   desc_allowance_complementary,
                   desc_other_income,
                   desc_allowance,
                   desc_total_income,
                   desc_total_expenses,
                   desc_n_people,
                   desc_income_per_capita,
                   desc_notes,
                   cancel_reason,
                   cancel_notes
              FROM (SELECT id_family_monetary id,
                           decode(i_show_header_label,
                                  pk_alert_constant.g_yes,
                                  REPLACE(pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                                    'SOCIAL_T089')),
                                          pk_paramedical_prof_core.c_colon) || chr(10),
                                  NULL) field_header,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T024')) ||
                           nvl2(to_char(allowance_family),
                                allowance_family || ' ' || allow_family_curr_brief_desc,
                                pk_paramedical_prof_core.c_dashes) desc_allowance_family,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T025')) ||
                           nvl2(to_char(allowance_complementary),
                                allowance_complementary || ' ' || allow_comp_curr_brief_desc,
                                pk_paramedical_prof_core.c_dashes) desc_allowance_complementary,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T026')) ||
                           nvl2(to_char(other), other || ' ' || other_curr_brief_desc, pk_paramedical_prof_core.c_dashes) desc_other_income,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T027')) ||
                           nvl2(to_char(subsidy),
                                subsidy || ' ' || subsidy_curr_brief_desc,
                                pk_paramedical_prof_core.c_dashes) desc_allowance,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T029')) ||
                           nvl2(to_char(tot_pat_f_mem),
                                tot_sit_fin || ' ' || tot_sit_fin_curr_brief_desc,
                                pk_paramedical_prof_core.c_dashes) desc_total_income,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T028')) ||
                           nvl2(to_char(fixed_expenses),
                                fixed_expenses || ' ' || fixed_exp_curr_brief_desc,
                                pk_paramedical_prof_core.c_dashes) desc_total_expenses,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T030')) ||
                           nvl(to_char(tot_person), pk_paramedical_prof_core.c_dashes) desc_n_people,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T031')) ||
                           nvl2(to_char(rend_capita),
                                rend_capita || ' ' || rend_capita_curr_brief_desc,
                                pk_paramedical_prof_core.c_dashes) desc_income_per_capita,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T082')) ||
                           nvl(notes, pk_paramedical_prof_core.c_dashes) desc_notes,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                            'COMMON_M072')) ||
                                  pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, id_cancel),
                                  NULL) cancel_reason,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                            'COMMON_M073')) ||
                                  pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, id_cancel),
                                  NULL) cancel_notes,
                           flg_status_1
                      FROM (SELECT p.id_pat_family,
                                   p.id_family_monetary,
                                   nvl(p.allowance_family, 0) AS allowance_family,
                                   p.id_currency_allow_family,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_allow_family, l_id_currency_default)) AS allow_family_curr_brief_desc,
                                   --  
                                   nvl(p.allowance_complementary, 0) AS allowance_complementary,
                                   p.id_currency_allow_comp,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_allow_comp, l_id_currency_default)) AS allow_comp_curr_brief_desc,
                                   -- 
                                   nvl(p.other, 0) AS other,
                                   p.id_currency_other,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_other, l_id_currency_default)) AS other_curr_brief_desc,
                                   --
                                   nvl(p.subsidy, 0) AS subsidy,
                                   p.id_currency_subsidy,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_subsidy, l_id_currency_default)) AS subsidy_curr_brief_desc,
                                   --
                                   nvl(p.fixed_expenses, 0) AS fixed_expenses,
                                   p.id_currency_fixed_exp,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_fixed_exp, l_id_currency_default)) AS fixed_exp_curr_brief_desc,
                                   --
                                   p.notes,
                                   v_total_members tot_person, -- total de elementos do agregado familiar
                                   v_tot_pat_f_mem tot_pat_f_mem, -- valor total dos vencimentos dos elementos do agregado
                                   ((v_tot_pat_f_mem + nvl(allowance_family, 0) + nvl(allowance_complementary, 0) +
                                   nvl(subsidy, 0) + nvl(other, 0)) /* - nvl(fixed_expenses, 0)*/
                                   ) tot_sit_fin,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_allow_family, l_id_currency_default)) AS tot_sit_fin_curr_brief_desc,
                                   round((((v_tot_pat_f_mem + nvl(allowance_family, 0) + nvl(allowance_complementary, 0) +
                                         nvl(subsidy, 0) + nvl(other, 0)) - (nvl(fixed_expenses, 0))) / v_total_members),
                                         2) rend_capita,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_allow_family, l_id_currency_default)) AS rend_capita_curr_brief_desc,
                                   p.flg_status flg_status_1,
                                   p.id_cancel_info_det id_cancel
                              FROM family_monetary p, patient pat, pat_family pf
                             WHERE p.id_pat_family /*(+)*/
                                   = pf.id_pat_family
                               AND pf.id_pat_family = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                            --AND pf.id_institution = i_prof.institution
                             ORDER BY dt_registry_tstz DESC)
                     WHERE rownum <= 1)
            --in the summary the cancelled records are not displayed
             WHERE l_show_cancelled <> flg_status_1;
    
        g_error := 'GET CURSOR O_PAT_PROF_SOCIAL_CLASS';
        OPEN o_pat_financial_prof FOR
            SELECT *
              FROM (SELECT *
                      FROM (SELECT p.id_family_monetary id,
                                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, p.dt_registry_tstz, i_prof) dt,
                                   --prof.nick_name 
                                   --pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                                   --pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) || ',' ||
                                   --(SELECT i.abbreviation
                                   --   FROM institution i
                                   --  WHERE i.id_institution = i_prof.institution) desc_speciality,
                                   pk_tools.get_prof_description(i_lang,
                                                                 i_prof,
                                                                 p.id_professional,
                                                                 p.dt_registry_tstz,
                                                                 NULL) prof_sign,
                                   p.dt_registry_tstz,
                                   p.flg_status flg_status
                              FROM family_monetary p, patient pat, pat_family pf
                             WHERE p.id_pat_family /*(+) */
                                   = pf.id_pat_family
                               AND pf.id_pat_family = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                            UNION ALL
                            SELECT p.id_family_monetary id,
                                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, p.dt_registry_tstz, i_prof) dt,
                                   --prof.nick_name 
                                   --pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                                   --pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) || ',' ||
                                   --(SELECT i.abbreviation
                                   --   FROM institution i
                                   --  WHERE i.id_institution = i_prof.institution) desc_speciality,
                                   pk_tools.get_prof_description(i_lang,
                                                                 i_prof,
                                                                 p.id_professional,
                                                                 p.dt_registry_tstz,
                                                                 NULL) prof_sign,
                                   p.dt_registry_tstz,
                                   p.flg_status flg_status
                              FROM family_monetary p, patient pat, pat_family pf
                             WHERE p.id_pat_family /*(+) */
                                   = pf.id_pat_family
                               AND pf.id_pat_family = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                             ORDER BY dt_registry_tstz DESC)
                     WHERE rownum <= 1)
            --in the summary the cancelled records are not displayed
             WHERE l_show_cancelled <> flg_status;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_financial);
            pk_types.open_my_cursor(o_pat_financial_prof);
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOUSEHOLD_FINANCIAL',
                                                     o_error);
        
    END get_household_financial;

    /********************************************************************************************
     * Get patient's household financial information
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_patient             Patient ID     
     * @param o_id_fam_mon             Family monetary id
     * @param o_house_fin_desc         Patient's household financial information
     *
     * @return                         True on success, False otherwise
     *
     * @author                         Diogo Oliveira
     * @version                        v2.7.3.6
     * @since                          2018/11/19
    **********************************************************************************************/
    FUNCTION get_house_fin_summary_page
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        o_id_fam_mon     OUT family_monetary.id_family_monetary%TYPE,
        o_house_fin_desc OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_id_currency_default currency.id_currency%TYPE;
    
        v_total_members PLS_INTEGER;
        v_tot_pat_f_mem NUMBER;
        --
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    
        l_household_financial VARCHAR2(4000);
    BEGIN
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T024',
                                                                                          'SOCIAL_T025',
                                                                                          'SOCIAL_T026',
                                                                                          'SOCIAL_T027',
                                                                                          'SOCIAL_T028',
                                                                                          'SOCIAL_T029',
                                                                                          'SOCIAL_T030',
                                                                                          'SOCIAL_T031',
                                                                                          'SOCIAL_T082'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error               := 'GET CURRENCY DEFAUL - GET_FAM_MONEY';
        l_id_currency_default := get_currency_default(i_prof);
    
        v_total_members := get_total_family_members(i_id_patient);
    
        v_tot_pat_f_mem := get_total_family_money(i_id_patient, i_prof);
    
        g_error := 'GET l_household_financial';
        SELECT (desc_allowance_family || chr(13) || desc_allowance_complementary || chr(13) || desc_other_income ||
               chr(13) || desc_allowance || chr(13) || desc_total_income || chr(13) || desc_total_expenses || chr(13) ||
               desc_n_people || chr(13) || desc_income_per_capita || chr(13) || desc_notes),
               id_family_monetary
          INTO o_house_fin_desc, o_id_fam_mon
          FROM (SELECT t_table_message_array('SOCIAL_T024') || chr(58) || chr(32) ||
                       nvl2(to_char(allowance_family),
                            allowance_family || ' ' || allow_family_curr_brief_desc,
                            pk_paramedical_prof_core.c_dashes) desc_allowance_family,
                       t_table_message_array('SOCIAL_T025') || chr(58) || chr(32) ||
                       nvl2(to_char(allowance_complementary),
                            allowance_complementary || ' ' || allow_comp_curr_brief_desc,
                            pk_paramedical_prof_core.c_dashes) desc_allowance_complementary,
                       t_table_message_array('SOCIAL_T026') || chr(58) || chr(32) ||
                       nvl2(to_char(other), other || ' ' || other_curr_brief_desc, pk_paramedical_prof_core.c_dashes) desc_other_income,
                       t_table_message_array('SOCIAL_T027') || chr(58) || chr(32) ||
                       nvl2(to_char(subsidy),
                            subsidy || ' ' || subsidy_curr_brief_desc,
                            pk_paramedical_prof_core.c_dashes) desc_allowance,
                       t_table_message_array('SOCIAL_T029') || chr(58) || chr(32) ||
                       nvl2(to_char(tot_pat_f_mem),
                            tot_sit_fin || ' ' || tot_sit_fin_curr_brief_desc,
                            pk_paramedical_prof_core.c_dashes) desc_total_income,
                       t_table_message_array('SOCIAL_T028') || chr(58) || chr(32) ||
                       nvl2(to_char(fixed_expenses),
                            fixed_expenses || ' ' || fixed_exp_curr_brief_desc,
                            pk_paramedical_prof_core.c_dashes) desc_total_expenses,
                       t_table_message_array('SOCIAL_T030') || chr(58) || chr(32) ||
                       nvl(to_char(tot_person), pk_paramedical_prof_core.c_dashes) desc_n_people,
                       t_table_message_array('SOCIAL_T031') || chr(58) || chr(32) ||
                       nvl2(to_char(rend_capita),
                            rend_capita || ' ' || rend_capita_curr_brief_desc,
                            pk_paramedical_prof_core.c_dashes) desc_income_per_capita,
                       t_table_message_array('SOCIAL_T082') || chr(58) || chr(32) ||
                       nvl(notes, pk_paramedical_prof_core.c_dashes) desc_notes,
                       id_family_monetary
                  FROM (SELECT p.id_pat_family,
                               p.id_family_monetary,
                               nvl(p.allowance_family, 0) AS allowance_family,
                               p.id_currency_allow_family,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_allow_family, l_id_currency_default)) AS allow_family_curr_brief_desc,
                               --  
                               nvl(p.allowance_complementary, 0) AS allowance_complementary,
                               p.id_currency_allow_comp,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_allow_comp, l_id_currency_default)) AS allow_comp_curr_brief_desc,
                               -- 
                               nvl(p.other, 0) AS other,
                               p.id_currency_other,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_other, l_id_currency_default)) AS other_curr_brief_desc,
                               --
                               nvl(p.subsidy, 0) AS subsidy,
                               p.id_currency_subsidy,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_subsidy, l_id_currency_default)) AS subsidy_curr_brief_desc,
                               --
                               nvl(p.fixed_expenses, 0) AS fixed_expenses,
                               p.id_currency_fixed_exp,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_fixed_exp, l_id_currency_default)) AS fixed_exp_curr_brief_desc,
                               --
                               p.notes,
                               v_total_members tot_person, -- total de elementos do agregado familiar
                               v_tot_pat_f_mem tot_pat_f_mem, -- valor total dos vencimentos dos elementos do agregado
                               ((v_tot_pat_f_mem + nvl(allowance_family, 0) + nvl(allowance_complementary, 0) +
                               nvl(subsidy, 0) + nvl(other, 0)) /* - nvl(fixed_expenses, 0)*/
                               ) tot_sit_fin,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_allow_family, l_id_currency_default)) AS tot_sit_fin_curr_brief_desc,
                               round((((v_tot_pat_f_mem + nvl(allowance_family, 0) + nvl(allowance_complementary, 0) +
                                     nvl(subsidy, 0) + nvl(other, 0)) - (nvl(fixed_expenses, 0))) / v_total_members),
                                     2) rend_capita,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_allow_family, l_id_currency_default)) AS rend_capita_curr_brief_desc
                          FROM family_monetary p, patient pat, pat_family pf
                         WHERE p.id_pat_family /*(+)*/
                               = pf.id_pat_family
                           AND pf.id_pat_family = pat.id_pat_family
                           AND pat.id_patient = i_id_patient
                           AND p.flg_status <> pk_alert_constant.g_cancelled
                         ORDER BY dt_registry_tstz DESC)
                 WHERE rownum <= 1);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_id_fam_mon     := NULL;
            o_house_fin_desc := NULL;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END get_house_fin_summary_page;

    /********************************************************************************************
    * Get patient's household financial information
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat_financial          Financial information cursor
    * @param o_pat_financial_prof     Professional that inputs the financial information        
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/04
    **********************************************************************************************/
    FUNCTION get_household_financial_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_prof               IN profissional,
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_currency_default currency.id_currency%TYPE;
    
        v_total_members PLS_INTEGER;
        v_tot_pat_f_mem PLS_INTEGER;
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        pk_alertlog.log_debug('GET_HOUSEHOLD_FINANCIAL_HIST: i_id_pat = ' || i_id_pat);
    
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T024',
                                                                                          'SOCIAL_T025',
                                                                                          'SOCIAL_T026',
                                                                                          'SOCIAL_T027',
                                                                                          'SOCIAL_T028',
                                                                                          'SOCIAL_T029',
                                                                                          'SOCIAL_T030',
                                                                                          'SOCIAL_T031',
                                                                                          'SOCIAL_T082'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error               := 'GET CURRENCY DEFAUL - GET_FAM_MONEY';
        l_id_currency_default := get_currency_default(i_prof);
    
        v_total_members := get_total_family_members(i_id_pat);
    
        v_tot_pat_f_mem := get_total_family_money(i_id_pat, i_prof);
    
        g_error := 'GET CURSOR O_PAT';
        OPEN o_pat_financial FOR
            SELECT id_family_monetary id,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T024')) ||
                   allowance_family || ' ' || allow_family_curr_brief_desc desc_allowance_family,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T025')) ||
                   allowance_complementary || ' ' || allow_comp_curr_brief_desc desc_allowance_complementary,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T026')) || other || ' ' ||
                   other_curr_brief_desc desc_other_income,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T027')) || subsidy || ' ' ||
                   subsidy_curr_brief_desc desc_allowance,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T029')) ||
                   tot_sit_fin || ' ' || tot_sit_fin_curr_brief_desc desc_total_income,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T028')) ||
                   fixed_expenses || ' ' || fixed_exp_curr_brief_desc desc_total_expenses,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T030')) ||
                   tot_person desc_n_people,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T031')) ||
                   rend_capita || ' ' || rend_capita_curr_brief_desc desc_income_per_capita,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T082')) || notes desc_notes,
                   decode(flg_status_1,
                          pk_alert_constant.g_flg_status_c,
                          pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                    'COMMON_M072')) ||
                          pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, id_cancel),
                          NULL) cancel_reason,
                   decode(flg_status_1,
                          pk_alert_constant.g_flg_status_c,
                          pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                    'COMMON_M073')) ||
                          pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, id_cancel),
                          NULL) cancel_notes
              FROM (SELECT id_pat_family,
                           id_family_monetary,
                           nvl(allowance_family, 0) AS allowance_family,
                           id_currency_allow_family,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_allow_family, l_id_currency_default)) AS allow_family_curr_brief_desc,
                           --  
                           nvl(allowance_complementary, 0) AS allowance_complementary,
                           id_currency_allow_comp,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_allow_comp, l_id_currency_default)) AS allow_comp_curr_brief_desc,
                           -- 
                           nvl(other, 0) AS other,
                           id_currency_other,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_other, l_id_currency_default)) AS other_curr_brief_desc,
                           --
                           nvl(subsidy, 0) AS subsidy,
                           id_currency_subsidy,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_subsidy, l_id_currency_default)) AS subsidy_curr_brief_desc,
                           --
                           nvl(fixed_expenses, 0) AS fixed_expenses,
                           id_currency_fixed_exp,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_fixed_exp, l_id_currency_default)) AS fixed_exp_curr_brief_desc,
                           --
                           notes,
                           v_total_members tot_person, -- total de elementos do agregado familiar
                           v_tot_pat_f_mem tot_pat_f_mem, -- valor total dos vencimentos dos elementos do agregado
                           ((v_tot_pat_f_mem + nvl(allowance_family, 0) + nvl(allowance_complementary, 0) +
                           nvl(subsidy, 0) + nvl(other, 0)) /*- nvl(fixed_expenses, 0)*/
                           ) tot_sit_fin,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_allow_family, l_id_currency_default)) AS tot_sit_fin_curr_brief_desc,
                           round((((v_tot_pat_f_mem + nvl(allowance_family, 0) + nvl(allowance_complementary, 0) +
                                 nvl(subsidy, 0) + nvl(other, 0)) - (nvl(fixed_expenses, 0))) / v_total_members),
                                 2) rend_capita,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_allow_family, l_id_currency_default)) AS rend_capita_curr_brief_desc,
                           flg_status_1,
                           id_cancel
                      FROM (SELECT fm.id_pat_family,
                                   fm.id_family_monetary,
                                   fm.allowance_family,
                                   fm.id_currency_allow_family,
                                   fm.allowance_complementary,
                                   fm.id_currency_allow_comp,
                                   fm.other,
                                   fm.id_currency_other,
                                   fm.subsidy,
                                   fm.id_currency_subsidy,
                                   fm.fixed_expenses,
                                   fm.id_currency_fixed_exp,
                                   fm.notes,
                                   fm.dt_registry_tstz,
                                   fm.flg_status               flg_status_1,
                                   fm.id_cancel_info_det       id_cancel
                              FROM family_monetary fm, patient pat, pat_family pf
                             WHERE fm.id_pat_family /*(+)*/
                                   = pf.id_pat_family
                               AND pf.id_pat_family = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                            UNION ALL
                            SELECT fmh.id_pat_family,
                                   fmh.id_family_monetary_hist id_family_monetary,
                                   fmh.allowance_family,
                                   fmh.id_currency_allow_family,
                                   fmh.allowance_complementary,
                                   fmh.id_currency_allow_comp,
                                   
                                   fmh.other,
                                   fmh.id_currency_other,
                                   fmh.subsidy,
                                   fmh.id_currency_subsidy,
                                   fmh.fixed_expenses,
                                   fmh.id_currency_fixed_exp,
                                   fmh.notes,
                                   fmh.dt_registry_tstz,
                                   fmh.flg_status            flg_status_1,
                                   fmh.id_cancel_info_det    id_cancel
                              FROM family_monetary_hist fmh, patient pat, pat_family pf
                             WHERE fmh.id_pat_family /*(+)*/
                                   = pf.id_pat_family
                               AND pf.id_pat_family = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                            --AND pf.id_institution = i_prof.institution
                             ORDER BY dt_registry_tstz DESC));
    
        g_error := 'GET CURSOR O_PAT_PROF_SOCIAL_CLASS';
        OPEN o_pat_financial_prof FOR
            SELECT *
              FROM (SELECT p.id_family_monetary id,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, p.dt_registry_tstz, i_prof) dt,
                           --prof.nick_name 
                           --pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                           --pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) || ',' ||
                           --(SELECT i.abbreviation
                           --   FROM institution i
                           --  WHERE i.id_institution = i_prof.institution) desc_speciality,
                           pk_tools.get_prof_description(i_lang, i_prof, p.id_professional, p.dt_registry_tstz, NULL) prof_sign,
                           p.dt_registry_tstz,
                           p.flg_status flg_status,
                           pk_sysdomain.get_domain('FAMILY_MONETARY.FLG_STATUS', p.flg_status, i_lang) desc_status
                      FROM family_monetary p, patient pat, pat_family pf
                     WHERE p.id_pat_family = pf.id_pat_family
                       AND pf.id_pat_family = pat.id_pat_family
                       AND pat.id_patient = i_id_pat
                    UNION ALL
                    SELECT p.id_family_monetary_hist id,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, p.dt_registry_tstz, i_prof) dt,
                           --prof.nick_name 
                           --pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                           --pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) || ',' ||
                           --(SELECT i.abbreviation
                           --   FROM institution i
                           --  WHERE i.id_institution = i_prof.institution) desc_speciality,
                           pk_tools.get_prof_description(i_lang, i_prof, p.id_professional, p.dt_registry_tstz, NULL) prof_sign,
                           p.dt_registry_tstz,
                           p.flg_status flg_status,
                           pk_sysdomain.get_domain('FAMILY_MONETARY_HIST.FLG_STATUS', p.flg_status, i_lang) desc_status
                      FROM family_monetary_hist p, patient pat, pat_family pf
                     WHERE p.id_pat_family = pf.id_pat_family
                       AND pf.id_pat_family = pat.id_pat_family
                       AND pat.id_patient = i_id_pat)
             ORDER BY dt_registry_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_financial);
            pk_types.open_my_cursor(o_pat_financial_prof);
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOUSEHOLD_FINANCIAL_HIST',
                                                     o_error);
        
    END get_household_financial_hist;
    --

    /********************************************************************************************
    * Get patient's household financial information for the create/edit screen
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_id_pat                 Patient ID 
    * @param o_pat_financial          Financial information cursor
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/04
    **********************************************************************************************/
    FUNCTION get_household_financial_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        o_pat_financial OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_currency_default currency.id_currency%TYPE;
        l_temp_str            VARCHAR2(1);
        v_total_members       PLS_INTEGER;
        v_tot_pat_f_mem       PLS_INTEGER;
        l_mask_allowance_fam  pk_utils.t_str_mask;
        l_mask_allowance_cmpl pk_utils.t_str_mask;
        l_mask_other_inc      pk_utils.t_str_mask;
        l_mask_allowance      pk_utils.t_str_mask;
        l_mask_tot_exp        pk_utils.t_str_mask;
    
        CURSOR cur_fam_mometary(id_pat patient.id_patient%TYPE) IS
            SELECT 'x'
              FROM family_monetary fm, patient pat, pat_family pf
             WHERE fm.id_pat_family(+) = pf.id_pat_family
               AND pf.id_pat_family = pat.id_pat_family
               AND pat.id_patient = id_pat
               AND fm.flg_status <> pk_alert_constant.g_flg_status_c;
    
    BEGIN
        pk_alertlog.log_error('GET_HOUSEHOLD_FINANCIAL_EDIT: i_id_pat = ' || i_id_pat);
        g_error               := 'GET CURRENCY DEFAUL - GET_FAM_MONEY';
        l_id_currency_default := get_currency_default(i_prof);
    
        v_total_members := get_total_family_members(i_id_pat);
    
        v_tot_pat_f_mem := get_total_family_money(i_id_pat, i_prof);
    
        -- get currency fields masks
        l_mask_allowance_fam  := pk_utils.get_numeric_input_mask(i_prof   => i_prof,
                                                                 i_owner  => g_owner,
                                                                 i_table  => 'FAMILY_MONETARY',
                                                                 i_column => 'ALLOWANCE_FAMILY');
        l_mask_allowance_cmpl := pk_utils.get_numeric_input_mask(i_prof   => i_prof,
                                                                 i_owner  => g_owner,
                                                                 i_table  => 'FAMILY_MONETARY',
                                                                 i_column => 'ALLOWANCE_COMPLEMENTARY');
        l_mask_other_inc      := pk_utils.get_numeric_input_mask(i_prof   => i_prof,
                                                                 i_owner  => g_owner,
                                                                 i_table  => 'FAMILY_MONETARY',
                                                                 i_column => 'OTHER');
        l_mask_allowance      := pk_utils.get_numeric_input_mask(i_prof   => i_prof,
                                                                 i_owner  => g_owner,
                                                                 i_table  => 'FAMILY_MONETARY',
                                                                 i_column => 'SUBSIDY');
        l_mask_tot_exp        := pk_utils.get_numeric_input_mask(i_prof   => i_prof,
                                                                 i_owner  => g_owner,
                                                                 i_table  => 'FAMILY_MONETARY',
                                                                 i_column => 'FIXED_EXPENSES');
    
        OPEN cur_fam_mometary(i_id_pat);
        FETCH cur_fam_mometary
            INTO l_temp_str;
        g_found := cur_fam_mometary%NOTFOUND;
        CLOSE cur_fam_mometary;
    
        IF NOT g_found
        THEN
            g_error := 'GET CURSOR O_PAT';
            OPEN o_pat_financial FOR
                SELECT id_family_monetary id,
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T024'),
                                                                          'Y') title_allowance_family,
                       allowance_family || ' ' || allow_family_curr_brief_desc desc_allowance_family,
                       allowance_family flg_allowance_family,
                       l_mask_allowance_fam flg_mask_allowance_family,
                       0 flg_min_allowance_family,
                       NULL flg_max_allowance_family,
                       --id_currency_allow_family flg_unit_allowance_family,
                       --                    
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T025'),
                                                                          'Y') title_allowance_complement,
                       allowance_complementary || ' ' || allow_comp_curr_brief_desc desc_allowance_complement,
                       allowance_complementary flg_allowance_complement,
                       l_mask_allowance_cmpl flg_mask_allowance_complement,
                       0 flg_min_allowance_complement,
                       NULL flg_max_allowance_complement,
                       --id_currency_allow_comp flg_unit_allowance_complement,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T026'),
                                                                          'Y') title_other_income,
                       other || ' ' || other_curr_brief_desc desc_other_income,
                       other flg_other_income,
                       l_mask_other_inc flg_mask_other_income,
                       0 flg_min_other_income,
                       NULL flg_max_other_income,
                       --id_currency_other flg_unit_other_income,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T027'),
                                                                          'Y') title_allowance,
                       subsidy || ' ' || subsidy_curr_brief_desc desc_allowance,
                       subsidy flg_allowance,
                       l_mask_allowance flg_mask_allowance,
                       0 flg_min_allowance,
                       NULL flg_max_allowance,
                       --id_currency_subsidy flg_unit_allowance,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T029'),
                                                                          'Y') title_total_income,
                       tot_sit_fin || ' ' || tot_sit_fin_curr_brief_desc desc_total_income,
                       tot_pat_f_mem flg_total_income,
                       --nvl(id_currency_allow_family, l_id_currency_default) flg_unit_total_income,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T028'),
                                                                          'Y') title_total_expenses,
                       fixed_expenses || ' ' || fixed_exp_curr_brief_desc desc_total_expenses,
                       fixed_expenses flg_total_expenses,
                       l_mask_tot_exp flg_mask_total_expenses,
                       0 flg_min_total_expenses,
                       NULL flg_max_total_expenses,
                       --id_currency_fixed_exp flg_unit_total_expenses,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T030'),
                                                                          'Y') title_n_people,
                       tot_person desc_n_people,
                       tot_person flg_n_people,
                       --NULL flg_unit_n_people,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T031'),
                                                                          'Y') title_income_per_capita,
                       rend_capita || ' ' || rend_capita_curr_brief_desc desc_income_per_capita,
                       rend_capita flg_income_per_capita,
                       --nvl(id_currency_allow_family, l_id_currency_default) flg_unit_income_per_capita,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T082'),
                                                                          'Y') title_notes,
                       notes desc_notes,
                       notes flg_notes
                --NULL flg_unit_notes   
                  FROM (SELECT p.id_pat_family,
                               p.id_family_monetary,
                               nvl(p.allowance_family, 0) AS allowance_family,
                               p.id_currency_allow_family,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_allow_family, l_id_currency_default)) AS allow_family_curr_brief_desc,
                               --  
                               nvl(p.allowance_complementary, 0) AS allowance_complementary,
                               p.id_currency_allow_comp,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_allow_comp, l_id_currency_default)) AS allow_comp_curr_brief_desc,
                               -- 
                               nvl(p.other, 0) AS other,
                               p.id_currency_other,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_other, l_id_currency_default)) AS other_curr_brief_desc,
                               --
                               nvl(p.subsidy, 0) AS subsidy,
                               p.id_currency_subsidy,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_subsidy, l_id_currency_default)) AS subsidy_curr_brief_desc,
                               --
                               nvl(p.fixed_expenses, 0) AS fixed_expenses,
                               p.id_currency_fixed_exp,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_fixed_exp, l_id_currency_default)) AS fixed_exp_curr_brief_desc,
                               --
                               p.notes,
                               v_total_members tot_person, -- total de elementos do agregado familiar
                               v_tot_pat_f_mem tot_pat_f_mem, -- valor total dos vencimentos dos elementos do agregado
                               ((v_tot_pat_f_mem + nvl(allowance_family, 0) + nvl(allowance_complementary, 0) +
                               nvl(subsidy, 0) + nvl(other, 0)) /*- nvl(fixed_expenses, 0)*/
                               ) tot_sit_fin,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_allow_family, l_id_currency_default)) AS tot_sit_fin_curr_brief_desc,
                               round((((v_tot_pat_f_mem + nvl(allowance_family, 0) + nvl(allowance_complementary, 0) +
                                     nvl(subsidy, 0) + nvl(other, 0)) - (nvl(fixed_expenses, 0))) / v_total_members),
                                     2) rend_capita,
                               (SELECT currency_desc
                                  FROM currency
                                 WHERE id_currency = nvl(p.id_currency_allow_family, l_id_currency_default)) AS rend_capita_curr_brief_desc
                          FROM family_monetary p, patient pat, pat_family pf
                         WHERE p.id_pat_family(+) = pf.id_pat_family
                           AND pf.id_pat_family = pat.id_pat_family
                           AND pat.id_patient = i_id_pat
                           AND p.flg_status <> pk_alert_constant.g_flg_status_c
                        --AND pf.id_institution = i_prof.institution
                         GROUP BY p.id_pat_family,
                                  p.id_family_monetary,
                                  p.allowance_family,
                                  p.id_currency_allow_family,
                                  p.allowance_complementary,
                                  p.id_currency_allow_comp,
                                  p.other,
                                  p.id_currency_other,
                                  p.subsidy,
                                  p.id_currency_subsidy,
                                  p.fixed_expenses,
                                  p.id_currency_fixed_exp,
                                  p.notes);
        
        ELSE
            g_error := 'GET CURSOR O_PAT';
            OPEN o_pat_financial FOR
                SELECT NULL id,
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T024'),
                                                                          'Y') title_allowance_family,
                       NULL desc_allowance_family,
                       NULL flg_allowance_family,
                       l_mask_allowance_fam flg_mask_allowance_family,
                       0 flg_min_allowance_family,
                       NULL flg_max_allowance_family,
                       --id_currency_allow_family flg_unit_allowance_family,
                       --                    
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T025'),
                                                                          'Y') title_allowance_complement,
                       NULL desc_allowance_complement,
                       NULL flg_allowance_complement,
                       l_mask_allowance_cmpl flg_mask_allowance_complement,
                       0 flg_min_allowance_complement,
                       NULL flg_max_allowance_complement,
                       --id_currency_allow_comp flg_unit_allowance_complement,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T026'),
                                                                          'Y') title_other_income,
                       NULL desc_other_income,
                       NULL flg_other_income,
                       l_mask_other_inc flg_mask_other_income,
                       0 flg_min_other_income,
                       NULL flg_max_other_income,
                       --id_currency_other flg_unit_other_income,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T027'),
                                                                          'Y') title_allowance,
                       NULL desc_allowance,
                       NULL flg_allowance,
                       l_mask_allowance flg_mask_allowance,
                       0 flg_min_allowance,
                       NULL flg_max_allowance,
                       --id_currency_subsidy flg_unit_allowance,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T029'),
                                                                          'Y') title_total_income,
                       v_tot_pat_f_mem desc_total_income,
                       v_tot_pat_f_mem flg_total_income,
                       --nvl(id_currency_allow_family, l_id_currency_default) flg_unit_total_income,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T028'),
                                                                          'Y') title_total_expenses,
                       NULL desc_total_expenses,
                       NULL flg_total_expenses,
                       l_mask_tot_exp flg_mask_total_expenses,
                       0 flg_min_total_expenses,
                       NULL flg_max_total_expenses,
                       --id_currency_fixed_exp flg_unit_total_expenses,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T030'),
                                                                          'Y') title_n_people,
                       v_total_members desc_n_people,
                       v_total_members flg_n_people,
                       --NULL flg_unit_n_people,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T031'),
                                                                          'Y') title_income_per_capita,
                       NULL desc_income_per_capita,
                       NULL flg_income_per_capita,
                       --nvl(id_currency_allow_family, l_id_currency_default) flg_unit_income_per_capita,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'SOCIAL_T082'),
                                                                          'Y') title_notes,
                       NULL desc_notes,
                       NULL flg_notes
                --NULL flg_unit_notes   
                  FROM dual;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_financial);
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOUSEHOLD_FINANCIAL_EDIT',
                                                     o_error);
        
    END get_household_financial_edit;

    /********************************************************************************************
    * This function allows the creation (i_id_fam_money is null) or the update of household 
    * financial information.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    * @ param i_id_fam_money          Id family money
    * @ param i_allowance_family      Allowance family value
    * @ param i_currency_allow_family Allowance family currency id
    * @ param i_allowance_complementary Allowance complementary value
    * @ param i_currency_allow_comp     Allowance complementary currency id
    * @ param i_other                   Other incomes value
    * @ param i_currency_other          Other incomes currency id
    * @ param i_subsidy                 Allowance value
    * @ param i_currency_subsidy        Allowance currency id
    * @ param i_fixed_expenses          Fixed expenses value
    * @ param i_currency_fixed_exp      Fixed expenses currency id
    * @ param i_total_fam_members       Number of family members
    * @ param i_notes                   Notes
    * @ param i_epis                    ID episode
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/05
    **********************************************************************************************/
    FUNCTION set_household_financial
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_pat                  IN patient.id_patient%TYPE,
        i_id_fam_money            IN family_monetary.id_family_monetary%TYPE,
        i_allowance_family        IN family_monetary.allowance_family%TYPE,
        i_currency_allow_family   IN currency.id_currency%TYPE,
        i_allowance_complementary IN family_monetary.allowance_complementary%TYPE,
        i_currency_allow_comp     IN currency.id_currency%TYPE,
        i_other                   IN family_monetary.other%TYPE,
        i_currency_other          IN currency.id_currency%TYPE,
        i_subsidy                 IN family_monetary.subsidy%TYPE,
        i_currency_subsidy        IN currency.id_currency%TYPE,
        i_fixed_expenses          IN family_monetary.fixed_expenses%TYPE,
        i_currency_fixed_exp      IN currency.id_currency%TYPE,
        i_total_fam_members       IN patient.total_fam_members%TYPE,
        i_notes                   IN VARCHAR2,
        i_epis                    IN episode.id_episode%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_next        family_monetary.id_family_monetary%TYPE;
        l_id_pat_fam  patient.id_pat_family%TYPE;
        l_error       t_error_out;
        l_id_epis_soc social_episode.id_social_episode%TYPE;
    
        CURSOR c_social_episode IS
            SELECT id_social_episode
              FROM social_episode
             WHERE id_patient = i_id_pat
               AND flg_status = pk_alert_constant.g_epis_status_active;
    
        internal_exception EXCEPTION;
    
        l_rows table_varchar;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        pk_alertlog.log_debug('SET_HOUSEHOLD_FINANCIAL: i_id_pat = ' || i_id_pat || ', i_id_fam_money = ' ||
                              i_id_fam_money || 'i_allowance_family = ' || i_allowance_family ||
                              'i_allowance_complementary = ' || i_allowance_complementary || ' i_other =' || i_other ||
                              'i_subsidy = ' || i_subsidy || 'i_fixed_expenses = ' || i_fixed_expenses ||
                              ' i_total_fam_members = ' || i_total_fam_members || 'i_notes = ' || i_notes);
    
        BEGIN
        
            --v_total_fam_members := get_total_fam_mem_scalar(i_id_pat);
            pk_alertlog.log_debug('UPDATE TABLE PATIENT - total_fam_members' || i_total_fam_members);
            ts_patient.upd(id_patient_in => i_id_pat, total_fam_members_in => i_total_fam_members);
        
            --TODO: what a hell is this????
            --IF (v_total_fam_members < i_total_fam_members)
            --THEN
            --g_error := 'CALLING PK_SOCIAL.CREATE_PAT_FAMILY';
        
            --v_total_fam_members := v_total_fam_members + 1;
        
            --TODO: Review this....
            --FOR i IN v_total_fam_members .. i_total_fam_members
            --LOOP
            --IF NOT create_pat_family_internal(i_lang,
            --                                  i_id_pat,
            --                               NULL,
            --                              i_prof,
            --                               pk_message.get_message(i_lang, 'SOCIAL_M016'),
            --                             NULL,
            --                           NULL,
            --                         pk_sysconfig.get_config('UNDEFINED_FAMILY_RELATIONSHIP', i_prof),
            --                       NULL,
            --                     NULL,
            --                   NULL,
            --                 NULL,
            --               NULL,
            --             NULL,
            --           NULL,
            --         NULL,
            --       NULL,
            --     NULL,
            --   NULL,
            -- i_epis,
            --o_error)
            -- THEN
            --NULL;
            ---   RAISE g_sw_generic_exception;
            -- END IF;
        
            --END LOOP;
        
            -- END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE g_sw_generic_exception;
        END;
    
        --
        IF NOT set_pat_fam(i_lang       => i_lang,
                           i_id_pat     => i_id_pat,
                           i_prof       => i_prof,
                           i_commit     => pk_alert_constant.get_no,
                           o_id_pat_fam => l_id_pat_fam,
                           o_error      => l_error)
        THEN
            o_error := l_error;
            RAISE g_exception;
        END IF;
        --
    
        IF i_id_fam_money IS NULL --se ainda não existe situação familiar
        THEN
        
            g_error := 'GET SEQ_FAMILY_MONETARY.NEXTVAL';
            SELECT seq_family_monetary.nextval
              INTO l_next
              FROM dual;
        
            g_error := 'INSERT FAMILY_MONETARY';
            ts_family_monetary.ins(id_family_monetary_in       => l_next,
                                   id_pat_family_in            => l_id_pat_fam,
                                   allowance_family_in         => i_allowance_family,
                                   id_currency_allow_family_in => i_currency_allow_family,
                                   allowance_complementary_in  => i_allowance_complementary,
                                   id_currency_allow_comp_in   => i_currency_allow_comp,
                                   other_in                    => i_other,
                                   id_currency_other_in        => i_currency_other,
                                   subsidy_in                  => i_subsidy,
                                   id_currency_subsidy_in      => i_currency_subsidy,
                                   fixed_expenses_in           => i_fixed_expenses,
                                   id_currency_fixed_exp_in    => i_currency_fixed_exp,
                                   flg_available_in            => g_flg_available,
                                   notes_in                    => i_notes,
                                   id_professional_in          => i_prof.id,
                                   dt_registry_tstz_in         => g_sysdate_tstz,
                                   flg_status_in               => pk_alert_constant.g_flg_status_a,
                                   rows_out                    => l_rows);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'FAMILY_MONETARY',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
        ELSE
            -- EXISTE
            --Inserir registo existente na tabela de histórico
            g_error := 'INSERT FAMILY_MONETARY_HIST';
            INSERT INTO family_monetary_hist
                (id_family_monetary_hist,
                 id_pat_family,
                 allowance_family,
                 id_currency_allow_family,
                 allowance_complementary,
                 id_currency_allow_comp,
                 other,
                 id_currency_other,
                 subsidy,
                 id_currency_subsidy,
                 fixed_expenses,
                 id_currency_fixed_exp,
                 notes,
                 id_professional,
                 dt_registry_tstz,
                 flg_status,
                 id_cancel_info_det)
                SELECT seq_family_monetary_hist.nextval,
                       id_pat_family,
                       allowance_family,
                       i_currency_allow_family,
                       allowance_complementary,
                       i_currency_allow_comp,
                       other,
                       i_currency_other,
                       subsidy,
                       i_currency_subsidy,
                       fixed_expenses,
                       i_currency_fixed_exp,
                       notes,
                       id_professional,
                       dt_registry_tstz,
                       flg_status,
                       id_cancel_info_det
                  FROM family_monetary
                 WHERE id_family_monetary = i_id_fam_money;
        
            --Actualizar situação financeira
            g_error := 'UPDATE FAMILY_MONETARY';
            ts_family_monetary.upd(id_family_monetary_in       => i_id_fam_money,
                                   allowance_family_in         => i_allowance_family,
                                   id_currency_allow_family_in => i_currency_allow_family,
                                   allowance_complementary_in  => i_allowance_complementary,
                                   id_currency_allow_comp_in   => i_currency_allow_comp,
                                   other_in                    => i_other,
                                   id_currency_other_in        => i_currency_other,
                                   subsidy_in                  => i_subsidy,
                                   id_currency_subsidy_in      => i_currency_subsidy,
                                   fixed_expenses_in           => i_fixed_expenses,
                                   id_currency_fixed_exp_in    => i_currency_fixed_exp,
                                   notes_in                    => nvl(i_notes, ''),
                                   id_professional_in          => i_prof.id,
                                   dt_registry_tstz_in         => g_sysdate_tstz,
                                   flg_status_in               => pk_alert_constant.g_flg_status_e,
                                   rows_out                    => l_rows);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'FAMILY_MONETARY',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
        END IF;
        --
        -- Verificar se o episódio social do paciente está activo
        g_error := 'GET CURSOR C_SOCIAL_EPISODE';
        OPEN c_social_episode;
        FETCH c_social_episode
            INTO l_id_epis_soc;
        g_found := c_social_episode%NOTFOUND;
        CLOSE c_social_episode;
        --
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_epis,
                                      i_pat                 => i_id_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
        --
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'SET_HOUSEHOLD_FINANCIAL',
                                                     o_error);
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'SET_HOUSEHOLD_FINANCIAL',
                                                     o_error);
    END set_household_financial;
    --

    /********************************************************************************************
    * Get domains values for the household financial fields.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *
    * @ param o_currency_domain       Currency domain
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/05
    **********************************************************************************************/
    FUNCTION get_household_fin_domains
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        o_currency_domain OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT
            get_currency_list(i_lang => i_lang, i_prof => i_prof, o_currency => o_currency_domain, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_currency_domain);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOUSEHOLD_FIN_DOMAINS',
                                                     o_error);
        
    END get_household_fin_domains;
    --

    /********************************************************************************************
     * Create history records for the financial information of the household
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_id_pat                  Patient ID
     * @param i_id_home                 Home conditions record ID
     *
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Orlando Antunes
     * @version                          0.1
     * @since                            2010/01/22
    **********************************************************************************************/

    FUNCTION set_household_fin_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat       IN patient.id_patient%TYPE,
        i_id_fam_money IN family_monetary.id_family_monetary%TYPE,
        i_epis         IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_household_fin_row family_monetary%ROWTYPE;
    
    BEGIN
    
        pk_alertlog.log_debug('SET_HOUSEHOLD_FIN_HIST BEGIN');
        g_sysdate_tstz := current_timestamp;
        --
        IF i_id_fam_money IS NOT NULL
        THEN
            pk_alertlog.log_debug('SET_HOUSEHOLD_FIN_HIST : i_id_fam_money = ' || i_id_fam_money);
            g_error := 'GET_PREVIOUS_RECORD';
            BEGIN
                --Get history for home information
                SELECT *
                  INTO l_household_fin_row
                  FROM family_monetary
                 WHERE id_family_monetary = i_id_fam_money;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'NO_DATA_FOUND for the given i_id_fam_money!';
                    RAISE g_sw_generic_exception;
            END;
            -- EXISTE
            --Inserir registo existente na tabela de histórico
            g_error := 'INSERT FAMILY_MONETARY_HIST';
            INSERT INTO family_monetary_hist
                (id_family_monetary_hist,
                 id_pat_family,
                 allowance_family,
                 id_currency_allow_family,
                 allowance_complementary,
                 id_currency_allow_comp,
                 other,
                 id_currency_other,
                 subsidy,
                 id_currency_subsidy,
                 fixed_expenses,
                 id_currency_fixed_exp,
                 notes,
                 id_professional,
                 dt_registry_tstz,
                 flg_status,
                 id_cancel_info_det)
            VALUES
                (seq_family_monetary_hist.nextval,
                 l_household_fin_row.id_pat_family,
                 l_household_fin_row.allowance_family,
                 l_household_fin_row.id_currency_allow_family,
                 l_household_fin_row.allowance_complementary,
                 l_household_fin_row.id_currency_allow_comp,
                 l_household_fin_row.other,
                 l_household_fin_row.id_currency_other,
                 l_household_fin_row.subsidy,
                 l_household_fin_row.id_currency_subsidy,
                 l_household_fin_row.fixed_expenses,
                 l_household_fin_row.id_currency_fixed_exp,
                 l_household_fin_row.notes,
                 l_household_fin_row.id_professional,
                 l_household_fin_row.dt_registry_tstz,
                 l_household_fin_row.flg_status,
                 l_household_fin_row.id_cancel_info_det);
        
        ELSE
            g_error := 'I_ID_FAM_MONEY IS INVALID!';
            RAISE g_sw_generic_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'SET_HOUSEHOLD_FIN_HIST',
                                                     o_error);
        
    END set_household_fin_hist;
    --

    /********************************************************************************************
     * Cancel the financial information of the household.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_id_pat                  Patient ID
     * @param i_id_fam_money            Family monetary ID(financial information of the household)
     *
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Orlando Antunes
     * @version                          0.1
     * @since                            2010/02/08
    **********************************************************************************************/
    FUNCTION set_cancel_household_financial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_fam_money  IN family_monetary.id_family_monetary%TYPE,
        i_notes         IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancel_info_det_id cancel_info_det.id_cancel_info_det%TYPE;
        l_rowids             table_varchar;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        --
        --
        IF i_id_fam_money IS NULL
        THEN
            g_error := 'SET_HOUSEHOLD_FINANCIAL: INVALID I_ID_FAM_MONEY';
            RAISE g_sw_generic_exception;
        ELSE
            g_error := 'SET_HOUSEHOLD_FINANCIAL_HISTORY';
            pk_alertlog.log_debug('SET_HOUSEHOLD_FINANCIAL: CANCEL FAM_MONEY = ' || i_id_fam_money);
            --Set history for household financial information
            IF NOT set_household_fin_hist(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_id_pat       => i_id_pat,
                                          i_id_fam_money => i_id_fam_money,
                                          i_epis         => NULL,
                                          o_error        => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
            --
            pk_alertlog.log_debug('SET_CANCEL_HOME : SAVE CANCEL DETAILS');
            ts_cancel_info_det.ins(id_prof_cancel_in      => i_prof.id,
                                   id_cancel_reason_in    => i_cancel_reason,
                                   dt_cancel_in           => g_sysdate_tstz,
                                   notes_cancel_short_in  => i_notes,
                                   id_cancel_info_det_out => l_cancel_info_det_id,
                                   rows_out               => l_rowids);
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON CANCEL_INFO_DET';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CANCEL_INFO_DET',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            --Actualizar atributos da habitação
            g_error := 'UPDATE FAMILY_MONETARY';
            ts_family_monetary.upd(id_family_monetary_in => i_id_fam_money,
                                   dt_registry_tstz_in   => g_sysdate_tstz,
                                   flg_status_in         => pk_alert_constant.g_flg_status_c,
                                   id_cancel_info_det_in => l_cancel_info_det_id,
                                   rows_out              => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'FAMILY_MONETARY',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        END IF;
        --
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
        --
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'SET_CANCEL_HOUSEHOLD_FINANCIAL',
                                                     o_error);
        
    END set_cancel_household_financial;
    --

    /********************************************************************************************
    * 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_graf_crit              Criteria ID 
    *
    * @param o_crit                   Criteria values for a given criteria
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_pat_graff_criteria_id
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_pat      IN patient.id_patient%TYPE,
        i_id_criteria IN graffar_criteria.id_graffar_criteria%TYPE
    ) RETURN pat_graffar_crit.id_pat_graffar_crit%TYPE IS
    
        l_id_pat_graffar_crit pat_graffar_crit.id_pat_graffar_crit%TYPE;
        l_error               t_error_out;
    BEGIN
    
        SELECT pgc.id_pat_graffar_crit
          INTO l_id_pat_graffar_crit
          FROM pat_graffar_crit pgc, graffar_crit_value gcv, graffar_criteria gc
         WHERE pgc.id_graffar_crit_value = gcv.id_graffar_crit_value
           AND pgc.id_patient = i_id_pat
           AND gc.id_graffar_criteria = gcv.id_graffar_criteria
           AND gc.id_graffar_criteria = i_id_criteria
           AND (pgc.flg_status IS NULL OR pgc.flg_status <> pk_alert_constant.g_flg_status_c)
           AND rownum <= 1;
    
        RETURN l_id_pat_graffar_crit;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SOCIAL',
                                              'GET_PAT_GRAFF_CRITERIA_ID',
                                              l_error);
            RETURN NULL;
    END get_pat_graff_criteria_id;
    --

    /********************************************************************************************
     * Cancel a member of the household.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_id_pat                  Patient ID
     * @param i_id_pat_fam_member       Family member ID
     * @param i_notes                   Cancel notes
     * @param i_cancel_reason           Cancel reason ID
     *
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Orlando Antunes
     * @version                          0.1
     * @since                            2010/02/11
    **********************************************************************************************/
    FUNCTION set_cancel_household
    
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_pat            IN patient.id_patient%TYPE,
        i_id_pat_fam_member IN family_monetary.id_family_monetary%TYPE,
        i_notes             IN VARCHAR2,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids table_varchar;
    
    BEGIN
        g_error := 'SET_CANCEL_HOUSEHOLD : i_id_pat = ' || i_id_pat || ', i_id_pat_fam_member = ' ||
                   i_id_pat_fam_member;
    
        g_error := 'UPDATE pat_family_member';
        UPDATE pat_family_member
           SET flg_status = 'I', id_prof_cancel = i_prof.id, dt_cancel_tstz = current_timestamp, notes_cancel = i_notes
         WHERE id_patient = i_id_pat_fam_member;
    
        g_error := 'UPDATE patient';
        ts_patient.upd(id_patient_in => i_id_pat_fam_member, flg_status_in => 'I', rows_out => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PATIENT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        --
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
        --
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'SET_CANCEL_HOUSEHOLD',
                                                     o_error);
        
    END set_cancel_household;

    /********************************************************************************************
     * Cancel the Social class for the givem patient
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)
     * @param i_id_pat                  Patient ID
     * @param i_notes                   Cancel notes
     * @param i_cancel_reason           Cancel reason ID
     *
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Orlando Antunes
     * @version                          0.1
     * @since                            2010/02/11
    **********************************************************************************************/
    FUNCTION set_cancel_social_class
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_notes         IN VARCHAR2,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_pat_fam_row pat_family%ROWTYPE;
        l_pat_fam_id  pat_family.id_pat_family%TYPE;
    
        l_cancel_info_det_id cancel_info_det.id_cancel_info_det%TYPE;
        l_rowids             table_varchar;
    
        l_id_pat_fam_soc_class_hist pat_fam_soc_class_hist.id_pat_fam_soc_class_hist%TYPE;
        l_pat_graffar_crit_row      pat_graffar_crit%ROWTYPE;
    BEGIN
    
        pk_alertlog.log_debug('SET_CANCEL_SOCIAL_CLASS: i_id_pat = ' || i_id_pat || ', i_notes = ' || i_notes ||
                              'i_cancel_reason = ' || i_cancel_reason);
    
        --
        g_error        := 'SET_CANCEL_SOCIAL_CLASS';
        g_sysdate_tstz := current_timestamp;
        --
        SELECT id_pat_family
          INTO l_pat_fam_id
          FROM patient
         WHERE id_patient = i_id_pat;
    
        --
        SELECT *
          INTO l_pat_fam_row
          FROM pat_family pf
         WHERE pf.id_pat_family = l_pat_fam_id;
    
        --
        pk_alertlog.log_debug('SET_CANCEL_SOCIAL_CLASS : SAVE CANCEL DETAILS');
        ts_cancel_info_det.ins(id_prof_cancel_in      => i_prof.id,
                               id_cancel_reason_in    => i_cancel_reason,
                               dt_cancel_in           => g_sysdate_tstz,
                               notes_cancel_short_in  => i_notes,
                               id_cancel_info_det_out => l_cancel_info_det_id,
                               rows_out               => l_rowids);
    
        g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON CANCEL_INFO_DET';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CANCEL_INFO_DET',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'UPDATE PAT_FAMILY - SOCIAL_CLASS_NOTES';
        UPDATE pat_family
           SET id_social_class      = NULL,
               social_class_notes   = NULL,
               id_prof_social_class = NULL,
               dt_social_class_tstz = NULL
         WHERE id_pat_family = l_pat_fam_id;
    
        --
        pk_alertlog.log_debug('SET SOCIAL CLASS HISTORY');
        ts_pat_fam_soc_class_hist.ins(id_pat_family_in              => l_pat_fam_row.id_pat_family,
                                      id_social_class_in            => l_pat_fam_row.id_social_class,
                                      id_professional_in            => i_prof.id,
                                      dt_registry_tstz_in           => g_sysdate_tstz,
                                      notes_in                      => l_pat_fam_row.social_class_notes,
                                      flg_status_in                 => pk_alert_constant.g_flg_status_c,
                                      id_cancel_info_det_in         => l_cancel_info_det_id,
                                      id_pat_fam_soc_class_hist_out => l_id_pat_fam_soc_class_hist,
                                      rows_out                      => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_FAM_SOC_CLASS_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        --Create the history values for the pat_graffar_crit
        -- In order to show the detail of the canceled data we need to create the pat_graffar_crit
        -- values for the new history record.
        --1
        SELECT *
          INTO l_pat_graffar_crit_row
          FROM pat_graffar_crit pgc
         WHERE pgc.id_pat_graffar_crit = get_pat_graff_criteria_id(i_lang, i_prof, i_id_pat, 1);
    
        g_error := 'INSERT PAT_GRAFFAR_CRIT 1';
        ts_pat_graffar_crit.ins(dt_pat_graffar_crit_tstz_in  => g_sysdate_tstz,
                                id_patient_in                => l_pat_graffar_crit_row.id_patient,
                                id_graffar_crit_value_in     => l_pat_graffar_crit_row.id_graffar_crit_value,
                                id_professional_in           => i_prof.id,
                                id_episode_in                => l_pat_graffar_crit_row.id_episode,
                                id_pat_fam_soc_class_hist_in => l_id_pat_fam_soc_class_hist,
                                handle_error_in              => FALSE,
                                rows_out                     => l_rowids);
        g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_GRAFFAR_CRIT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_GRAFFAR_CRIT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- 2 
        SELECT *
          INTO l_pat_graffar_crit_row
          FROM pat_graffar_crit pgc
         WHERE pgc.id_pat_graffar_crit = get_pat_graff_criteria_id(i_lang, i_prof, i_id_pat, 2);
    
        g_error := 'INSERT PAT_GRAFFAR_CRIT 2';
        ts_pat_graffar_crit.ins(dt_pat_graffar_crit_tstz_in  => g_sysdate_tstz,
                                id_patient_in                => l_pat_graffar_crit_row.id_patient,
                                id_graffar_crit_value_in     => l_pat_graffar_crit_row.id_graffar_crit_value,
                                id_professional_in           => i_prof.id,
                                id_episode_in                => l_pat_graffar_crit_row.id_episode,
                                id_pat_fam_soc_class_hist_in => l_id_pat_fam_soc_class_hist,
                                handle_error_in              => FALSE,
                                rows_out                     => l_rowids);
        g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_GRAFFAR_CRIT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_GRAFFAR_CRIT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- 3 
        SELECT *
          INTO l_pat_graffar_crit_row
          FROM pat_graffar_crit pgc
         WHERE pgc.id_pat_graffar_crit = get_pat_graff_criteria_id(i_lang, i_prof, i_id_pat, 3);
    
        g_error := 'INSERT PAT_GRAFFAR_CRIT 3';
        ts_pat_graffar_crit.ins(dt_pat_graffar_crit_tstz_in  => g_sysdate_tstz,
                                id_patient_in                => l_pat_graffar_crit_row.id_patient,
                                id_graffar_crit_value_in     => l_pat_graffar_crit_row.id_graffar_crit_value,
                                id_professional_in           => i_prof.id,
                                id_episode_in                => l_pat_graffar_crit_row.id_episode,
                                id_pat_fam_soc_class_hist_in => l_id_pat_fam_soc_class_hist,
                                handle_error_in              => FALSE,
                                rows_out                     => l_rowids);
        g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_GRAFFAR_CRIT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_GRAFFAR_CRIT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- 4 
        SELECT *
          INTO l_pat_graffar_crit_row
          FROM pat_graffar_crit pgc
         WHERE pgc.id_pat_graffar_crit = get_pat_graff_criteria_id(i_lang, i_prof, i_id_pat, 4);
    
        g_error := 'INSERT PAT_GRAFFAR_CRIT 4';
        ts_pat_graffar_crit.ins(dt_pat_graffar_crit_tstz_in  => g_sysdate_tstz,
                                id_patient_in                => l_pat_graffar_crit_row.id_patient,
                                id_graffar_crit_value_in     => l_pat_graffar_crit_row.id_graffar_crit_value,
                                id_professional_in           => i_prof.id,
                                id_episode_in                => l_pat_graffar_crit_row.id_episode,
                                id_pat_fam_soc_class_hist_in => l_id_pat_fam_soc_class_hist,
                                handle_error_in              => FALSE,
                                rows_out                     => l_rowids);
        g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_GRAFFAR_CRIT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_GRAFFAR_CRIT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- 5 
        SELECT *
          INTO l_pat_graffar_crit_row
          FROM pat_graffar_crit pgc
         WHERE pgc.id_pat_graffar_crit = get_pat_graff_criteria_id(i_lang, i_prof, i_id_pat, 5);
    
        g_error := 'INSERT PAT_GRAFFAR_CRIT 5';
        ts_pat_graffar_crit.ins(dt_pat_graffar_crit_tstz_in  => g_sysdate_tstz,
                                id_patient_in                => l_pat_graffar_crit_row.id_patient,
                                id_graffar_crit_value_in     => l_pat_graffar_crit_row.id_graffar_crit_value,
                                id_professional_in           => i_prof.id,
                                id_episode_in                => l_pat_graffar_crit_row.id_episode,
                                id_pat_fam_soc_class_hist_in => l_id_pat_fam_soc_class_hist,
                                handle_error_in              => FALSE,
                                rows_out                     => l_rowids);
        g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_GRAFFAR_CRIT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_GRAFFAR_CRIT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        --update pat_graffar_crit
        UPDATE pat_graffar_crit pgc
           SET pgc.flg_status = pk_alert_constant.g_flg_status_c
         WHERE pgc.id_patient = i_id_pat
           AND (pgc.flg_status IS NULL OR pgc.flg_status <> pk_alert_constant.g_flg_status_c);
    
        --
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
        --
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'SET_CANCEL_SOCIAL_CLASS',
                                                     o_error);
        
    END set_cancel_social_class;
    --

    /********************************************************************************************
    * Get patient's family social class history information
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat_social_class       Social Class information cursor
    * @param o_pat_social_class_prof  Professional that inputs the social class information        
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/12
    **********************************************************************************************/
    FUNCTION get_social_class_hist
    
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_pat                IN patient.id_patient%TYPE,
        i_prof                  IN profissional,
        o_pat_social_class      OUT pk_types.cursor_type,
        o_pat_social_class_prof OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --t_cur_graffar_crit IS TABLE OF VARCHAR2;
    
        l_social_class_info PLS_INTEGER;
    
        CURSOR c_social_class_info IS
            SELECT COUNT(*)
              FROM pat_graffar_crit pgc
             WHERE pgc.id_patient = i_id_pat;
    
    BEGIN
        --the patient already has social class information?
        pk_alertlog.log_debug('GET_SOCIAL_CLASS - The patient already have information for social class?');
        OPEN c_social_class_info;
        FETCH c_social_class_info
            INTO l_social_class_info;
        g_found := c_social_class_info%NOTFOUND;
        CLOSE c_social_class_info;
    
        IF g_found
           OR l_social_class_info = 0
        THEN
            pk_types.open_my_cursor(o_pat_social_class);
            pk_types.open_my_cursor(o_pat_social_class_prof);
        ELSE
            pk_alertlog.log_debug('GET_SOCIAL_CLASS - Information found');
        
            OPEN o_pat_social_class FOR
                SELECT id,
                       pk_paramedical_prof_core.format_str_header_w_colon(titulo) || valor || chr(10) desc_social_class,
                       desc_social_ocupation,
                       desc_education_level,
                       desc_income,
                       desc_house,
                       desc_house_location,
                       notes desc_notes,
                       cancel_reason desc_cancel_reason,
                       cancel_notes desc_cancel_notes
                  FROM (SELECT pfsch.id_pat_fam_soc_class_hist id,
                               pk_message.get_message(i_lang, 'SOCIAL_T062') titulo,
                               0 id_graf_crit,
                               pk_translation.get_translation(i_lang, sc.code_social_class) valor,
                               --
                               get_graf_crit_desc(i_lang, i_prof, i_id_pat, 1, pfsch.id_pat_fam_soc_class_hist) desc_social_ocupation,
                               get_graf_crit_desc(i_lang, i_prof, i_id_pat, 2, pfsch.id_pat_fam_soc_class_hist) desc_education_level,
                               get_graf_crit_desc(i_lang, i_prof, i_id_pat, 3, pfsch.id_pat_fam_soc_class_hist) desc_income,
                               get_graf_crit_desc(i_lang, i_prof, i_id_pat, 4, pfsch.id_pat_fam_soc_class_hist) desc_house,
                               get_graf_crit_desc(i_lang, i_prof, i_id_pat, 5, pfsch.id_pat_fam_soc_class_hist) desc_house_location,
                               --
                               pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                         'SOCIAL_T082')) ||
                               nvl(pfsch.notes, pk_paramedical_prof_core.c_dashes) notes,
                               decode(pfsch.flg_status,
                                      pk_alert_constant.g_flg_status_c,
                                      pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                                'COMMON_M072')) ||
                                      pk_paramedical_prof_core.get_cancel_reason_desc(i_lang,
                                                                                      i_prof,
                                                                                      pfsch.id_cancel_info_det),
                                      NULL) cancel_reason,
                               decode(pfsch.flg_status,
                                      pk_alert_constant.g_flg_status_c,
                                      pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                                'COMMON_M073')) ||
                                      pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, pfsch.id_cancel_info_det),
                                      NULL) cancel_notes
                          FROM patient pat, pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                         WHERE pat.id_pat_family = pf.id_pat_family
                           AND pat.id_patient = i_id_pat
                           AND pf.id_pat_family = pfsch.id_pat_family
                           AND pfsch.id_social_class = sc.id_social_class(+)
                         ORDER BY pfsch.dt_registry_tstz DESC);
        
            g_error := 'GET CURSOR O_PAT_PROF_SOCIAL_CLASS';
            OPEN o_pat_social_class_prof FOR
                SELECT *
                  FROM ( --SELECT pf.id_pat_family id,
                        --       pk_date_utils.dt_chr_date_hour_tsz(i_lang, pf.dt_social_class_tstz, i_prof) dt,
                        --       pk_tools.get_prof_description(i_lang,
                        --                                     i_prof,
                        --                                     pf.id_prof_social_class,
                        --                                     pf.dt_social_class_tstz,
                        --                                     NULL) prof_sign,
                        --       'A' flg_status,
                        --       pf.dt_social_class_tstz dt_registry_tstz,
                        --       NULL desc_status
                        --  FROM patient pat, pat_family pf
                        -- WHERE pat.id_pat_family = pf.id_pat_family
                        --   AND pat.id_patient = i_id_pat
                        --   AND pf.id_social_class IS NOT NULL
                        --UNION ALL
                        SELECT pfsch.id_pat_fam_soc_class_hist id,
                                pk_date_utils.dt_chr_date_hour_tsz(i_lang, pfsch.dt_registry_tstz, i_prof) dt,
                                pk_tools.get_prof_description(i_lang,
                                                              i_prof,
                                                              pfsch.id_professional,
                                                              pfsch.dt_registry_tstz,
                                                              NULL) prof_sign,
                                pfsch.flg_status flg_status,
                                pfsch.dt_registry_tstz dt_registry_tstz,
                                pk_sysdomain.get_domain('PAT_FAM_SOC_CLASS_HIST.FLG_STATUS', pfsch.flg_status, i_lang) desc_status
                          FROM patient pat, pat_family pf, pat_fam_soc_class_hist pfsch
                         WHERE pat.id_pat_family = pf.id_pat_family
                           AND pat.id_patient = i_id_pat
                           AND pf.id_pat_family = pfsch.id_pat_family
                         ORDER BY dt_registry_tstz DESC NULLS LAST);
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_social_class);
            pk_types.open_my_cursor(o_pat_social_class_prof);
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_SOCIAL_CLASS_HIST',
                                                     o_error);
        
    END get_social_class_hist;
    --

    /********************************************************************************************
    * 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat_social_class       Social Class information cursor
    * @param o_pat_social_class_prof  Professional that inputs the social class information        
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/17
    **********************************************************************************************/
    FUNCTION get_graf_crit_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat                 IN patient.id_patient%TYPE,
        i_id_pat_graf_crit       IN graffar_criteria.id_graffar_criteria%TYPE,
        i_pat_fam_soc_class_hist IN pat_fam_soc_class_hist.id_pat_fam_soc_class_hist%TYPE
    ) RETURN VARCHAR IS
        l_error                 t_error_out;
        l_pat_graffar_crit_desc VARCHAR2(1000 CHAR);
    BEGIN
        g_error := 'GET O_VAL_G_CRIT';
    
        SELECT pk_paramedical_prof_core.format_str_header_w_colon(titulo) || valor desc_valor
          INTO l_pat_graffar_crit_desc
          FROM (SELECT pk_translation.get_translation(i_lang, gc.code_graffar_criteria) titulo,
                       gc.id_graffar_criteria id_graf_crit,
                       to_char(gcv.val) || '-' || pk_translation.get_translation(i_lang, gcv.code_graffar_crit_value) valor
                  FROM pat_graffar_crit pgc, graffar_crit_value gcv, graffar_criteria gc
                 WHERE pgc.id_graffar_crit_value(+) = gcv.id_graffar_crit_value
                   AND gc.id_graffar_criteria = gcv.id_graffar_criteria
                   AND gc.id_graffar_criteria = i_id_pat_graf_crit
                   AND pgc.id_patient = i_id_pat
                   AND pgc.id_pat_fam_soc_class_hist = i_pat_fam_soc_class_hist);
    
        RETURN l_pat_graffar_crit_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SOCIAL',
                                              'GET_GRAF_CRIT_DESC',
                                              l_error);
            RETURN NULL;
        
    END get_graf_crit_desc;
    --

    /********************************************************************************************
    * Get patient's Social Summary. This includes information of:
    *    - Diagnosis
    *    - Intervention plan
    *    - Follow up notes
    *    - Home 
    *    - Social class
    *    - Financial status
    *    - Household
    *    - Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * 
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_diagnosis_prof        Professional that creates/edit the diagnosis
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_interv_plan_prof      Professional that creates/edit the intervention plan
    * @ param o_follow_up             Follow up notes for the current episode
    * @ param o_follow_up_prof        Professional that creates the follow up notes
    * @ param o_pat_home              Patient's home information
    * @ param o_pat_home_prof         Last professional that edit the home information
    * @ param o_pat_social_class      Social class information
    * @ param o_pat_social_class_prof Last professional that edit the social class
    * @ param o_pat_financial         Financial situation information
    * @ param o_pat_financial_prof    Last professional that edit the financial situation 
    * @ param o_pat_household         Household information
    * @ param o_social_report         Social report
    * @ param o_social_report_prof    Professional that creates/edit the social report
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --diagnosis
        o_diagnosis      OUT pk_types.cursor_type,
        o_diagnosis_prof OUT pk_types.cursor_type,
        --intervention_plan
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        --followup notes
        o_follow_up      OUT pk_types.cursor_type,
        o_follow_up_prof OUT pk_types.cursor_type,
        --home
        o_pat_home      OUT pk_types.cursor_type,
        o_pat_home_prof OUT pk_types.cursor_type,
        --social class
        o_pat_social_class      OUT pk_types.cursor_type,
        o_pat_social_class_prof OUT pk_types.cursor_type,
        --financial
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        --household
        o_pat_household      OUT pk_types.cursor_type,
        o_pat_household_prof OUT pk_types.cursor_type,
        --report
        o_social_report      OUT pk_types.cursor_type,
        o_social_report_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_temp_cur pk_types.cursor_type;
    BEGIN
        --
        IF NOT pk_social.get_social_summary(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_id_pat  => i_id_pat,
                                            i_episode => i_episode,
                                            --
                                            o_diagnosis      => o_diagnosis,
                                            o_diagnosis_prof => o_diagnosis_prof,
                                            
                                            o_interv_plan      => o_interv_plan,
                                            o_interv_plan_prof => o_interv_plan_prof,
                                            
                                            o_follow_up      => o_follow_up,
                                            o_follow_up_prof => o_follow_up_prof,
                                            --
                                            o_pat_home              => o_pat_home,
                                            o_pat_home_prof         => o_pat_home_prof,
                                            o_pat_social_class      => o_pat_social_class,
                                            o_pat_social_class_prof => o_pat_social_class_prof,
                                            o_pat_financial         => o_pat_financial,
                                            o_pat_financial_prof    => o_pat_financial_prof,
                                            o_pat_household         => o_pat_household,
                                            o_pat_household_prof    => o_pat_household_prof,
                                            o_social_report         => o_social_report,
                                            o_social_report_prof    => o_social_report_prof,
                                            --
                                            o_social_request      => l_temp_cur,
                                            o_social_request_prof => l_temp_cur,
                                            o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_diagnosis_prof);
            --
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_interv_plan_prof);
            --
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_follow_up_prof);
            --
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            pk_types.open_my_cursor(o_pat_social_class);
            pk_types.open_my_cursor(o_pat_social_class_prof);
            pk_types.open_my_cursor(o_pat_financial);
            pk_types.open_my_cursor(o_pat_financial_prof);
            pk_types.open_my_cursor(o_pat_household);
            pk_types.open_my_cursor(o_pat_household_prof);
            --
            pk_types.open_my_cursor(o_social_report);
            pk_types.open_my_cursor(o_social_report_prof);
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOME_DETAIL',
                                                     o_error);
        
    END get_social_summary;
    --

    /********************************************************************************************
    * Get patient's Social Summary. This includes information of:
    *    - Diagnosis
    *    - Intervention plan
    *    - Follow up notes
    *    - Home 
    *    - Social class
    *    - Financial status
    *    - Household
    *    - Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * 
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_diagnosis_prof        Professional that creates/edit the diagnosis
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_interv_plan_prof      Professional that creates/edit the intervention plan
    * @ param o_follow_up             Follow up notes for the current episode
    * @ param o_follow_up_prof        Professional that creates the follow up notes
    * @ param o_pat_home              Patient's home information
    * @ param o_pat_home_prof         Last professional that edit the home information
    * @ param o_pat_social_class      Social class information
    * @ param o_pat_social_class_prof Last professional that edit the social class
    * @ param o_pat_financial         Financial situation information
    * @ param o_pat_financial_prof    Last professional that edit the financial situation 
    * @ param o_pat_household         Household information
    * @ param o_social_report         Social report
    * @ param o_social_report_prof    Professional that creates/edit the social report
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --diagnosis
        o_diagnosis      OUT pk_types.cursor_type,
        o_diagnosis_prof OUT pk_types.cursor_type,
        --intervention_plan
        o_interv_plan      OUT pk_types.cursor_type,
        o_interv_plan_prof OUT pk_types.cursor_type,
        --followup notes
        o_follow_up      OUT pk_types.cursor_type,
        o_follow_up_prof OUT pk_types.cursor_type,
        --home
        o_pat_home      OUT pk_types.cursor_type,
        o_pat_home_prof OUT pk_types.cursor_type,
        --social class
        o_pat_social_class      OUT pk_types.cursor_type,
        o_pat_social_class_prof OUT pk_types.cursor_type,
        --financial
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        --household
        o_pat_household      OUT pk_types.cursor_type,
        o_pat_household_prof OUT pk_types.cursor_type,
        --report
        o_social_report      OUT pk_types.cursor_type,
        o_social_report_prof OUT pk_types.cursor_type,
        --request
        o_social_request      OUT pk_types.cursor_type,
        o_social_request_prof OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_social_summary_view_type VARCHAR2(1 CHAR);
        l_category                 category.flg_type%TYPE;
    BEGIN
    
        -- get view type
        l_social_summary_view_type := pk_sysconfig.get_config(i_code_cf => 'SUMMARY_VIEW_ALL', i_prof => i_prof);
        l_category                 := pk_prof_utils.get_category(i_lang, i_prof);
    
        IF l_category <> pk_alert_constant.g_cat_type_social
           AND l_social_summary_view_type = pk_alert_constant.g_no
        THEN
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_diagnosis_prof);
            --
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_interv_plan_prof);
            --
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_follow_up_prof);
            --
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            pk_types.open_my_cursor(o_pat_social_class);
            pk_types.open_my_cursor(o_pat_social_class_prof);
            pk_types.open_my_cursor(o_pat_financial);
            pk_types.open_my_cursor(o_pat_financial_prof);
            pk_types.open_my_cursor(o_pat_household);
            pk_types.open_my_cursor(o_pat_household_prof);
            --
        ELSE
        
            IF NOT pk_paramedical_prof_core.get_summ_page_diag(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_epis           => table_number(i_episode),
                                                               o_diagnosis      => o_diagnosis,
                                                               o_diagnosis_prof => o_diagnosis_prof,
                                                               o_error          => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
            --
        
            IF NOT pk_paramedical_prof_core.get_interv_plan_summary(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_id_epis          => table_number(i_episode),
                                                                    o_interv_plan      => o_interv_plan,
                                                                    o_interv_plan_prof => o_interv_plan_prof,
                                                                    o_error            => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        
            --follow_up 
            IF NOT pk_paramedical_prof_core.get_followup_notes(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_episode        => table_number(i_episode),
                                                               i_mng_followup   => NULL,
                                                               i_show_cancelled => pk_alert_constant.g_no,
                                                               i_opinion_type   => pk_opinion.g_ot_social_worker,
                                                               o_follow_up_prof => o_follow_up_prof,
                                                               o_follow_up      => o_follow_up,
                                                               o_error          => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
            --social status
            IF NOT get_home_new(i_lang              => i_lang,
                                i_id_pat            => i_id_pat,
                                i_prof              => i_prof,
                                i_show_cancel       => pk_alert_constant.g_no,
                                i_show_header_label => pk_alert_constant.g_yes,
                                o_pat_home          => o_pat_home,
                                o_pat_home_prof     => o_pat_home_prof,
                                o_error             => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        
            IF NOT get_social_class(i_lang              => i_lang,
                                    i_id_pat            => i_id_pat,
                                    i_prof              => i_prof,
                                    i_show_cancel       => pk_alert_constant.g_no,
                                    i_show_header_label => pk_alert_constant.g_yes,
                                    o_social_class      => o_pat_social_class,
                                    o_prof_social_class => o_pat_social_class_prof,
                                    o_error             => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        
            IF NOT get_household_financial(i_lang               => i_lang,
                                           i_id_pat             => i_id_pat,
                                           i_prof               => i_prof,
                                           i_show_cancel        => pk_alert_constant.g_no,
                                           i_show_header_label  => pk_alert_constant.g_yes,
                                           o_pat_financial      => o_pat_financial,
                                           o_pat_financial_prof => o_pat_financial_prof,
                                           o_error              => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        
            IF NOT get_household_summary(i_lang               => i_lang,
                                         i_episode            => i_episode,
                                         i_id_pat             => i_id_pat,
                                         i_prof               => i_prof,
                                         o_pat_household      => o_pat_household,
                                         o_pat_household_prof => o_pat_household_prof,
                                         o_error              => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        
        END IF;
        --
    
        g_error := 'CALL pk_paramedical_prof_core.get_paramed_report';
        IF NOT pk_paramedical_prof_core.get_paramed_report(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => table_number(i_episode),
                                                           i_report         => NULL,
                                                           i_show_cancelled => pk_alert_constant.g_no,
                                                           o_report_prof    => o_social_report_prof,
                                                           o_report         => o_social_report,
                                                           o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error := 'CALL get_social_requests_summary';
        IF NOT get_social_requests_summary(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_episode       => table_number(i_episode),
                                           o_requests      => o_social_request,
                                           o_requests_prof => o_social_request_prof,
                                           o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_diagnosis_prof);
            --
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_interv_plan_prof);
            --
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_follow_up_prof);
            --
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            pk_types.open_my_cursor(o_pat_social_class);
            pk_types.open_my_cursor(o_pat_social_class_prof);
            pk_types.open_my_cursor(o_pat_financial);
            pk_types.open_my_cursor(o_pat_financial_prof);
            pk_types.open_my_cursor(o_pat_household);
            pk_types.open_my_cursor(o_pat_household_prof);
            --
            pk_types.open_my_cursor(o_social_report);
            pk_types.open_my_cursor(o_social_report_prof);
            --
            pk_types.open_my_cursor(o_social_request);
            pk_types.open_my_cursor(o_social_request_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOME_DETAIL',
                                                     o_error);
        
    END get_social_summary;
    --

    /********************************************************************************************
    * Get the social summary screen labels
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_summary_labels   Social summary screen labels  
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/19
    **********************************************************************************************/
    FUNCTION get_social_summary_labels
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        o_social_summary_labels OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET LABELS';
        pk_alertlog.log_debug('GET_SOCIAL_SUMMARY_LABELS - get all labels for the social summary screen');
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T114',
                                                                                          'PARAMEDICAL_T022',
                                                                                          'PARAMEDICAL_T005',
                                                                                          'SOCIAL_T100',
                                                                                          'SOCIAL_T041',
                                                                                          'SOCIAL_T113',
                                                                                          'SOCIAL_T153',
                                                                                          'SOCIAL_T088'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --    
        OPEN o_social_summary_labels FOR
            SELECT t_table_message_array('SOCIAL_T114') social_summary_main_header,
                   t_table_message_array('PARAMEDICAL_T022') social_diagnosis_header,
                   t_table_message_array('PARAMEDICAL_T005') social_interv_plan_header,
                   t_table_message_array('SOCIAL_T100') social_followup_header,
                   t_table_message_array('SOCIAL_T041') social_status_header,
                   t_table_message_array('SOCIAL_T113') social_report_header,
                   t_table_message_array('SOCIAL_T153') social_request_header,
                   t_table_message_array('SOCIAL_T088') social_home_header
              FROM dual;
        --      
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_social_summary_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_SOCIAL_STATUS_LABELS',
                                                     o_error);
        
    END get_social_summary_labels;
    --

    /********************************************************************************************
    * Get all parametrizations for the social worker software
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_social_parametrizations List with all parametrizations  (name/value) 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/19
    **********************************************************************************************/
    FUNCTION get_social_parametrizations
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        o_social_parametrizations OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_configs CONSTANT table_varchar := table_varchar('SUMMARY_VIEW_ALL', 'GRID_NAVIGATION', 'FREE_TEXT_ID');
    BEGIN
        RETURN pk_sysconfig.get_config(l_configs, i_prof, o_social_parametrizations);
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_social_parametrizations);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     g_package_name,
                                                     'GET_SOCIAL_PARAMETRIZATIONS',
                                                     o_error);
    END get_social_parametrizations;

    /*
    * Check if an active social assistance request exists.
    *
    * @param i_patient        patient identifier
    * @param i_institution    institution identifier
    *
    * @return                 true, if such episodes exists,
    *                         or false otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/24
    */
    FUNCTION check_active_request
    (
        i_patient     IN patient.id_patient%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN BOOLEAN IS
        CURSOR c_active_request IS
            SELECT i_patient
              FROM social_epis_request ser
              JOIN episode e
                ON ser.id_episode_origin = e.id_episode
             WHERE ser.flg_status IN (g_soc_req_status_pend, g_soc_req_status_acc)
               AND e.id_patient = i_patient
               AND e.id_institution = i_institution;
        l_dummy_row c_active_request%ROWTYPE;
        l_retval    BOOLEAN;
    BEGIN
        g_error := 'OPEN c_active_request';
        OPEN c_active_request;
        FETCH c_active_request
            INTO l_dummy_row;
        l_retval := c_active_request%FOUND;
        CLOSE c_active_request;
    
        RETURN l_retval;
    END check_active_request;

    /*
    * Build status string for social assistance requests. Internal use only.
    * Made public to be used in SQL statements.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_status         request status
    * @param i_dt_req         request date
    *
    * @return                 request status string
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/24
    */
    FUNCTION get_req_status_str
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_status IN social_epis_request.flg_status%TYPE,
        i_dt_req IN social_epis_request.dt_creation_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_retval       VARCHAR2(32767);
        l_display_type VARCHAR2(2 CHAR);
        l_value_date   sys_domain.code_domain%TYPE;
        l_value_icon   sys_domain.code_domain%TYPE;
        l_back_color   VARCHAR2(8 CHAR);
        l_icon_color   VARCHAR2(8 CHAR);
    BEGIN
        -- social assistance requests status string logic
        IF i_status = g_soc_req_status_pend
        THEN
            -- pending requests
            l_display_type := pk_alert_constant.g_display_type_date;
            l_value_date   := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => i_dt_req, i_prof => i_prof);
            l_value_icon   := NULL;
            l_back_color   := pk_alert_constant.g_color_red;
            l_icon_color   := pk_alert_constant.g_color_null;
        ELSE
            -- other request status
            l_display_type := pk_alert_constant.g_display_type_icon;
            l_value_date   := NULL;
            l_value_icon   := g_soc_req_status_domain;
            l_back_color   := pk_alert_constant.g_color_null;
            l_icon_color   := pk_alert_constant.g_color_icon_medium_grey;
        END IF;
        -- generate status string
        l_retval := pk_utils.get_status_string_immediate(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_display_type    => l_display_type,
                                                         i_flg_state       => i_status,
                                                         i_value_text      => NULL,
                                                         i_value_date      => l_value_date,
                                                         i_value_icon      => l_value_icon,
                                                         i_shortcut        => NULL,
                                                         i_back_color      => l_back_color,
                                                         i_icon_color      => l_icon_color,
                                                         i_message_style   => NULL,
                                                         i_message_color   => NULL,
                                                         i_flg_text_domain => pk_alert_constant.g_no);
        RETURN l_retval;
    END get_req_status_str;

    /*
    * Check if new social assistance request can be created.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_patient        patient identifier
    * @param o_create         create flag
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/24
    */
    FUNCTION check_create_request
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_create     VARCHAR2(1 CHAR);
        l_prof_cat       category.flg_type%TYPE;
        l_active_request BOOLEAN;
    BEGIN
        l_prof_cat       := pk_tools.get_prof_cat(i_prof => i_prof);
        l_active_request := check_active_request(i_patient => i_patient, i_institution => i_prof.institution);
    
        IF l_prof_cat = pk_alert_constant.g_cat_type_social
        THEN
            -- social workers cannot create requests
            l_flg_create := pk_alert_constant.g_no;
        ELSIF l_active_request
        THEN
            -- at most one active request per patient/institution
            l_flg_create := pk_alert_constant.g_no;
        ELSE
            l_flg_create := pk_alert_constant.g_yes;
        END IF;
    
        o_create := l_flg_create;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_CREATE_REQUEST',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_create_request;

    /*
    * Get social services requests list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_prof_cat       logged professional category
    * @param i_episode        episode identifier
    * @param i_patient        patient identifier
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/23
    */
    FUNCTION get_social_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_patient  IN episode.id_patient%TYPE,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_prof_cat = pk_alert_constant.g_cat_type_social
        THEN
            -- requests to be shown for social worker profiles:
            -- show the request for the current social worker episode
            g_error := 'OPEN o_requests I';
            OPEN o_requests FOR
                SELECT ser.id_social_epis_request,
                       ser.id_episode,
                       ser.flg_status,
                       get_req_status_str(i_lang, i_prof, ser.flg_status, ser.dt_creation_tstz) desc_status,
                       pk_tools.get_prof_description(i_lang,
                                                     i_prof,
                                                     ser.id_professional,
                                                     ser.dt_creation_tstz,
                                                     ser.id_episode_origin) prof_requests,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ser.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) dt_request_hour,
                       pk_date_utils.dt_chr_tsz(i_lang, ser.dt_creation_tstz, i_prof.institution, i_prof.software) dt_request_date,
                       pk_tools.get_prof_description(i_lang,
                                                     i_prof,
                                                     ser.id_prof_answer,
                                                     ser.dt_answer_tstz,
                                                     ser.id_episode) prof_answers,
                       pk_date_utils.date_char_hour_tsz(i_lang, d.dt_med_tstz, i_prof.institution, i_prof.software) dt_discharge_hour,
                       pk_date_utils.dt_chr_tsz(i_lang, d.dt_med_tstz, i_prof.institution, i_prof.software) dt_discharge_date
                  FROM social_epis_request ser
                  JOIN episode e
                    ON ser.id_episode_origin = e.id_episode
                  LEFT JOIN discharge d
                    ON ser.id_episode = d.id_episode
                   AND d.flg_status = pk_alert_constant.g_active
                 WHERE ser.id_episode = i_episode
                 ORDER BY ser.dt_creation_tstz DESC;
        ELSE
            -- requests to be shown for clinical profiles:
            -- show all requests for the patient in this institution
            g_error := 'OPEN o_requests II';
            OPEN o_requests FOR
                SELECT ser.id_social_epis_request,
                       ser.id_episode,
                       ser.flg_status,
                       get_req_status_str(i_lang, i_prof, ser.flg_status, ser.dt_creation_tstz) desc_status,
                       pk_tools.get_prof_description(i_lang,
                                                     i_prof,
                                                     ser.id_professional,
                                                     ser.dt_creation_tstz,
                                                     ser.id_episode_origin) prof_requests,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ser.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) dt_request_hour,
                       pk_date_utils.dt_chr_tsz(i_lang, ser.dt_creation_tstz, i_prof.institution, i_prof.software) dt_request_date,
                       pk_tools.get_prof_description(i_lang,
                                                     i_prof,
                                                     ser.id_prof_answer,
                                                     ser.dt_answer_tstz,
                                                     ser.id_episode) prof_answers,
                       pk_date_utils.date_char_hour_tsz(i_lang, d.dt_med_tstz, i_prof.institution, i_prof.software) dt_discharge_hour,
                       pk_date_utils.dt_chr_tsz(i_lang, d.dt_med_tstz, i_prof.institution, i_prof.software) dt_discharge_date
                  FROM social_epis_request ser
                  JOIN episode e
                    ON ser.id_episode_origin = e.id_episode
                  LEFT JOIN discharge d
                    ON ser.id_episode = d.id_episode
                   AND d.flg_status = pk_alert_constant.g_active
                 WHERE e.id_institution = i_prof.institution
                   AND e.id_patient = i_patient
                 ORDER BY ser.dt_creation_tstz DESC;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SOCIAL_REQUESTS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
    END get_social_requests;
    --

    /*
    * Get social services requests list.
    * Used in the clinical profiles.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Orlando Antnes
    * @version                 2.6.0.1
    * @since                  2010/03/19
    */
    FUNCTION get_social_requests_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN table_number,
        o_requests      OUT pk_types.cursor_type,
        o_requests_prof OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        t_table_message_array pk_paramedical_prof_core.table_message_array;
        l_label_any_prof      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'CONSULT_REQUEST_T021');
    BEGIN
        g_error := 'GET_SOCIAL_REQUESTS_SUMMARY BEGIN';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('DIET_T009',
                                                                                          'CONSULT_REQUEST_T003',
                                                                                          'CONSULT_REQUEST_T024',
                                                                                          'CONSULT_REQUEST_T004',
                                                                                          'SCH_T004'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN o_requests';
        OPEN o_requests FOR
            SELECT o.id_opinion        id,
                   o.id_episode_answer id_episode,
                   --
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T024')) ||
                   nvl((SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                         FROM clinical_service cs
                        WHERE cs.id_clinical_service = o.id_clinical_service),
                       pk_paramedical_prof_core.c_dashes) request_type,
                   --reason
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T003')) ||
                   nvl(decode(o.id_opinion_type,
                              pk_opinion.g_ot_case_manager,
                              pk_opinion.get_cm_req_reason(i_lang, i_prof, o.id_opinion),
                              o.desc_problem),
                       pk_paramedical_prof_core.c_dashes) request_reason,
                   --origin
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T004')) ||
                   pk_translation.get_translation(i_lang,
                                                  (SELECT et.code_epis_type
                                                     FROM episode e
                                                     JOIN epis_type et
                                                       ON et.id_epis_type = e.id_epis_type
                                                    WHERE e.id_episode = o.id_episode)) || pk_opinion.g_dash ||
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, o.id_prof_questions, NULL, o.id_episode) || ' (' ||
                   nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions),
                       pk_paramedical_prof_core.c_dashes) || ')' request_origin,
                   --profissional      
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SCH_T004')) ||
                   nvl2(o.id_prof_questioned,
                        pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                        l_label_any_prof) name_prof_request_type,
                   --notas
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('DIET_T009')) ||
                   nvl(o.notes, pk_paramedical_prof_core.c_dashes) prof_answers,
                   pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                                     i_prof,
                                                                     o.dt_problem_tstz,
                                                                     op.id_professional,
                                                                     o.dt_last_update,
                                                                     o.id_episode) last_update_info
              FROM opinion o
              LEFT JOIN opinion_prof op
                ON o.id_opinion = op.id_opinion
               AND op.flg_type = pk_opinion.g_opinion_prof_accept
             WHERE o.id_episode_answer IN (SELECT column_value
                                             FROM TABLE(i_episode))
               AND o.flg_auto_follow_up <> 'Y'
               AND o.id_opinion_type = pk_opinion.g_ot_social_worker
             ORDER BY o.dt_problem_tstz DESC;
    
        --
        g_error := 'OPEN o_requests_prof';
        OPEN o_requests_prof FOR
            SELECT o.id_opinion id,
                   o.id_episode_answer id_episode,
                   pk_tools.get_prof_description(i_lang, i_prof, op.id_professional, o.dt_problem_tstz, o.id_episode) prof_sign,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, o.dt_last_update, i_prof) dt,
                   o.flg_state flg_status,
                   pk_sysdomain.get_domain('OPINION_PROF.FLG_TYPE', op.flg_type, i_lang) desc_status
              FROM opinion o
              LEFT JOIN opinion_prof op
                ON o.id_opinion = op.id_opinion
             WHERE o.id_episode_answer IN (SELECT column_value
                                             FROM TABLE(i_episode))
               AND o.flg_auto_follow_up <> 'Y'
               AND o.id_opinion_type = pk_opinion.g_ot_social_worker
             ORDER BY o.dt_problem_tstz DESC;
        --
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SOCIAL_REQUESTS_SUMMARY',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_requests);
            pk_types.open_my_cursor(o_requests_prof);
            RETURN FALSE;
    END get_social_requests_summary;

    /**
    * Get social services requests list
    * (implementation of get_social_requests_summary for the Reports layer).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      list of episodes
    * @param o_requests     requests cursor
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/06/12
    */
    PROCEDURE get_social_requests_summ_rep
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN table_number,
        o_requests OUT pk_types.cursor_type
    ) IS
        t_table_message_array pk_paramedical_prof_core.table_message_array;
        l_label_any_prof      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'CONSULT_REQUEST_T021');
    BEGIN
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('DIET_T009',
                                                                                          'CONSULT_REQUEST_T003',
                                                                                          'CONSULT_REQUEST_T024',
                                                                                          'CONSULT_REQUEST_T004',
                                                                                          'SCH_T004',
                                                                                          'PAST_HISTORY_M006'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'OPEN o_requests';
        OPEN o_requests FOR
            SELECT o.id_opinion        id,
                   o.id_episode_answer id_episode,
                   --
                   pk_paramedical_prof_core.format_str_header_w_colon(i_srt       => t_table_message_array('CONSULT_REQUEST_T024'),
                                                                      i_is_report => pk_alert_constant.g_yes) lbl_request_type,
                   (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                      FROM clinical_service cs
                     WHERE cs.id_clinical_service = o.id_clinical_service) desc_request_type,
                   --reason
                   pk_paramedical_prof_core.format_str_header_w_colon(i_srt       => t_table_message_array('CONSULT_REQUEST_T003'),
                                                                      i_is_report => pk_alert_constant.g_yes) lbl_request_reason,
                   decode(o.id_opinion_type,
                          pk_opinion.g_ot_case_manager,
                          pk_opinion.get_cm_req_reason(i_lang, i_prof, o.id_opinion),
                          o.desc_problem) desc_request_reason,
                   --origin
                   pk_paramedical_prof_core.format_str_header_w_colon(i_srt       => t_table_message_array('CONSULT_REQUEST_T004'),
                                                                      i_is_report => pk_alert_constant.g_yes) lbl_request_origin,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT et.code_epis_type
                                                     FROM episode e
                                                     JOIN epis_type et
                                                       ON et.id_epis_type = e.id_epis_type
                                                    WHERE e.id_episode = o.id_episode)) || pk_opinion.g_dash ||
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, o.id_prof_questions, NULL, o.id_episode) || ' (' ||
                   nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions),
                       pk_paramedical_prof_core.c_dashes) || ')' desc_request_origin,
                   --professional      
                   pk_paramedical_prof_core.format_str_header_w_colon(i_srt       => t_table_message_array('SCH_T004'),
                                                                      i_is_report => pk_alert_constant.g_yes) lbl_prof,
                   nvl2(o.id_prof_questioned,
                        pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                        l_label_any_prof) desc_prof,
                   --notes
                   pk_paramedical_prof_core.format_str_header_w_colon(i_srt       => t_table_message_array('DIET_T009'),
                                                                      i_is_report => pk_alert_constant.g_yes) lbl_notes,
                   o.notes desc_notes,
                   -- last update
                   pk_paramedical_prof_core.format_str_header_w_colon(i_srt       => t_table_message_array('PAST_HISTORY_M006'),
                                                                      i_is_report => pk_alert_constant.g_yes) lbl_last_upd,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, op.id_professional) desc_prof_last_upd,
                   pk_prof_utils.get_desc_category(i_lang, i_prof, op.id_professional, i_prof.institution) desc_cat_last_upd,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, o.dt_problem_tstz, i_prof) desc_dt_last_upd,
                   pk_date_utils.date_send_tsz(i_lang, o.dt_problem_tstz, i_prof) serial_dt_last_upd
              FROM opinion o
              LEFT JOIN opinion_prof op
                ON o.id_opinion = op.id_opinion
               AND op.flg_type = pk_opinion.g_opinion_prof_accept
             WHERE o.id_episode_answer IN (SELECT /*+dynamic_sampling(t 2)*/
                                            t.column_value id_episode
                                             FROM TABLE(i_episode) t)
               AND o.flg_auto_follow_up <> pk_alert_constant.g_yes
             ORDER BY o.dt_problem_tstz DESC;
    END get_social_requests_summ_rep;

    /*
    * Get a social assitance request detail.
    * Used in the clinical profiles.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_request        request identifier
    * @param o_req_data       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/25
    */
    FUNCTION get_request_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_request  IN social_epis_request.id_social_epis_request%TYPE,
        o_req_data OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_create sys_message.desc_message%TYPE;
        l_msg_cancel sys_message.desc_message%TYPE;
        l_msg_reject sys_message.desc_message%TYPE;
    BEGIN
        l_msg_create := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T107');
        l_msg_cancel := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T109');
        l_msg_reject := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T136');
    
        g_error := 'OPEN o_req_data';
        OPEN o_req_data FOR
            SELECT l_msg_create operation,
                   pk_date_utils.date_char_tsz(i_lang, ser.dt_creation_tstz, i_prof.institution, i_prof.software) dt_register,
                   pk_tools.get_prof_description(i_lang,
                                                 i_prof,
                                                 ser.id_professional,
                                                 ser.dt_creation_tstz,
                                                 ser.id_episode_origin) prof_register,
                   ser.flg_status,
                   NULL cancel_reason,
                   ser.notes
              FROM social_epis_request ser
             WHERE ser.id_social_epis_request = i_request
            UNION ALL
            SELECT decode(ser.flg_status, g_soc_req_status_canc, l_msg_cancel, l_msg_reject) operation,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(ser.flg_status,
                                                      g_soc_req_status_canc,
                                                      cid.dt_cancel,
                                                      ser.dt_answer_tstz),
                                               i_prof.institution,
                                               i_prof.software) dt_register,
                   pk_tools.get_prof_description(i_lang,
                                                 i_prof,
                                                 decode(ser.flg_status,
                                                        g_soc_req_status_canc,
                                                        cid.id_prof_cancel,
                                                        ser.id_prof_answer),
                                                 decode(ser.flg_status,
                                                        g_soc_req_status_canc,
                                                        cid.dt_cancel,
                                                        ser.dt_answer_tstz),
                                                 NULL) prof_register,
                   ser.flg_status,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, cid.id_cancel_reason) cancel_reason,
                   decode(ser.flg_status,
                          g_soc_req_status_canc,
                          pk_string_utils.clob_to_sqlvarchar2(cid.notes_cancel_long),
                          pk_string_utils.clob_to_sqlvarchar2(ser.notes_answer)) notes
              FROM social_epis_request ser
              JOIN cancel_info_det cid
                ON ser.id_cancel_info_det = cid.id_cancel_info_det
               AND ser.flg_status = g_soc_req_status_canc
             WHERE ser.id_social_epis_request = i_request
               AND ser.flg_status IN (g_soc_req_status_canc, g_soc_req_status_rej);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REQUEST_DETAIL',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_req_data);
            RETURN FALSE;
    END get_request_detail;

    /*
    * Get the request that originated the given episode.
    * Used in the Social worker's profiles.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param o_request        request cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/23
    */
    FUNCTION get_request
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_request OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN o_request';
        OPEN o_request FOR
            SELECT ser.id_social_epis_request,
                   ser.flg_status,
                   pk_sysdomain.get_domain(g_soc_req_status_domain, ser.flg_status, i_lang) desc_status,
                   ser.notes,
                   pk_tools.get_prof_description(i_lang,
                                                 i_prof,
                                                 ser.id_professional,
                                                 ser.dt_creation_tstz,
                                                 ser.id_episode_origin) prof_requests,
                   pk_date_utils.date_char_tsz(i_lang, ser.dt_creation_tstz, i_prof.institution, i_prof.software) dt_request
              FROM social_epis_request ser
             WHERE ser.id_episode = i_episode
               AND ser.flg_status = g_soc_req_status_acc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REQUEST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_request);
            RETURN FALSE;
    END get_request;

    /*
    * Create a social assistance request.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_patient        patient identifier
    * @param i_notes          request notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/23
    */
    FUNCTION create_request
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_notes           IN social_epis_request.notes%TYPE,
        o_id_soc_epis_req OUT social_epis_request.id_social_epis_request%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_soc_epis_req social_epis_request.id_social_epis_request%TYPE;
        l_rows            table_varchar := table_varchar();
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- check if the patient is already under social assistance
        IF check_active_request(i_patient => i_patient, i_institution => i_prof.institution)
        THEN
            g_error := 'An active social assistence request exists!';
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 'SOCIAL_ERR004',
                                              i_sqlerrm  => g_error,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REQUEST',
                                              o_error    => o_error);
            RAISE g_sw_generic_exception;
        END IF;
    
        -- create request
        g_error := 'CALL ts_social_epis_request.ins';
        ts_social_epis_request.ins(id_professional_in         => i_prof.id,
                                   notes_in                   => i_notes,
                                   dt_creation_tstz_in        => g_sysdate_tstz,
                                   id_episode_origin_in       => i_episode,
                                   flg_status_in              => g_soc_req_status_pend,
                                   id_social_epis_request_out => l_id_soc_epis_req,
                                   rows_out                   => l_rows);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SOCIAL_EPIS_REQUEST',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        -- create an alert for this request
        g_error := 'CALL pk_alerts.insert_sys_alert_event';
        IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_sys_alert           => g_alert_new_request,
                                                i_id_episode          => i_episode,
                                                i_id_record           => l_id_soc_epis_req,
                                                i_dt_record           => g_sysdate_tstz,
                                                i_id_professional     => NULL,
                                                i_id_room             => NULL,
                                                i_id_clinical_service => NULL,
                                                i_flg_type_dest       => NULL,
                                                i_replace1            => pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                                          i_prof    => i_prof,
                                                                                                          i_prof_id => i_prof.id),
                                                i_replace2            => pk_sysconfig.get_config(i_code_cf => 'ALERT_SOCIAL_TIMEOUT',
                                                                                                 i_prof    => i_prof),
                                                o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        o_id_soc_epis_req := l_id_soc_epis_req;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REQUEST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_request;

    /*
    * Create a social assistance request.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_request        request identifier
    * @param i_cancel_reason  cancellation reason identifier
    * @param i_notes          cancellation notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/24
    */
    FUNCTION cancel_request
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_request       IN social_epis_request.id_social_epis_request%TYPE,
        i_cancel_reason IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes         IN cancel_info_det.notes_cancel_long%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows   table_varchar := table_varchar();
        l_id_cid cancel_info_det.id_cancel_info_det%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- create cancel information detail
        g_error := 'CALL ts_cancel_info_det.ins';
        ts_cancel_info_det.ins(id_prof_cancel_in      => i_prof.id,
                               id_cancel_reason_in    => i_cancel_reason,
                               dt_cancel_in           => g_sysdate_tstz,
                               notes_cancel_long_in   => i_notes,
                               id_cancel_info_det_out => l_id_cid,
                               rows_out               => l_rows);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CANCEL_INFO_DET',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
        l_rows := table_varchar();
        -- cancel request
        g_error := 'CALL ts_social_epis_request.upd';
        ts_social_epis_request.upd(id_social_epis_request_in => i_request,
                                   flg_status_in             => g_soc_req_status_canc,
                                   flg_status_nin            => FALSE,
                                   id_cancel_info_det_in     => l_id_cid,
                                   id_cancel_info_det_nin    => FALSE,
                                   rows_out                  => l_rows);
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SOCIAL_EPIS_REQUEST',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'ID_CANCEL_INFO_DET'));
    
        -- delete the alert created for this request
        g_error := 'CALL pk_alerts.delete_sys_alert_event';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_sys_alert => g_alert_new_request,
                                                i_id_record    => i_request,
                                                o_error        => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_REQUEST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_request;

    /*
    * Answer a social assistance request.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_request        request identifier
    * @param i_answer         answer flag
    * @param i_notes          answer notes
    * @param o_episode        episode identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/24
    */
    FUNCTION set_request_answer
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_request IN social_epis_request.id_social_epis_request%TYPE,
        i_answer  IN social_epis_request.flg_status%TYPE,
        i_notes   IN social_epis_request.notes_answer%TYPE,
        o_episode OUT episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_request_info IS
            SELECT eo.id_episode, ser.id_professional, ei.id_room, eo.id_clinical_service, eo.id_visit, v.flg_status
              FROM social_epis_request ser
              JOIN episode eo
                ON ser.id_episode_origin = eo.id_episode
              JOIN epis_info ei
                ON ser.id_episode_origin = ei.id_episode
              JOIN visit v
                ON eo.id_visit = v.id_visit
             WHERE ser.id_social_epis_request = i_request;
    
        l_rows          table_varchar := table_varchar();
        l_episode       episode.id_episode%TYPE;
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_req           c_request_info%ROWTYPE;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        -- get request information
        g_error := 'OPEN c_request_info';
        OPEN c_request_info;
        FETCH c_request_info
            INTO l_req;
        CLOSE c_request_info;
    
        IF i_answer = g_soc_req_status_acc
        THEN
            IF l_req.flg_status IS NULL
               OR l_req.flg_status != pk_alert_constant.g_active
            THEN
                g_error := 'Patient''s visit has ended, or is cancelled';
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => 'SOCIAL_ERR002',
                                                  i_sqlerrm  => g_error,
                                                  i_message  => g_error,
                                                  i_owner    => g_owner,
                                                  i_package  => g_package_name,
                                                  i_function => 'SET_REQUEST_ANSWER',
                                                  o_error    => o_error);
                RAISE g_sw_generic_exception;
            END IF;
        
            -- get default dep_clin_serv
            l_dep_clin_serv := pk_sysconfig.get_config(i_code_cf => 'SOCIAL_REQUESTS_DEFAULT_DEP_CLIN_SERV',
                                                       i_prof    => i_prof);
        
            -- check default dep_clin_serv
            IF l_dep_clin_serv IS NULL
               OR l_dep_clin_serv < 1
            THEN
                g_error := 'SYS_CONFIG ''SOCIAL_REQUESTS_DEFAULT_DEP_CLIN_SERV'' is not properly configured!';
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => 'SOCIAL_ERR003',
                                                  i_sqlerrm  => g_error,
                                                  i_message  => g_error,
                                                  i_owner    => g_owner,
                                                  i_package  => g_package_name,
                                                  i_function => 'SET_REQUEST_ANSWER',
                                                  o_error    => o_error);
                RAISE g_sw_generic_exception;
            END IF;
        
            -- create episode
            IF NOT pk_visit.create_episode(i_lang                 => i_lang,
                                           i_id_visit             => l_req.id_visit,
                                           i_id_professional      => i_prof,
                                           i_id_sched             => NULL,
                                           i_id_episode           => NULL,
                                           i_health_plan          => NULL,
                                           i_epis_type            => pk_alert_constant.g_epis_type_social,
                                           i_dep_clin_serv        => l_dep_clin_serv,
                                           i_sysdate              => NULL,
                                           i_sysdate_tstz         => NULL,
                                           i_flg_ehr              => pk_visit.g_flg_ehr_n,
                                           i_flg_appointment_type => pk_visit.g_null_appointment_type,
                                           i_transaction_id       => l_transaction_id,
                                           o_episode              => l_episode,
                                           o_error                => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        
            -- request is accepted
            g_error := 'CALL ts_social_epis_request.upd I';
            ts_social_epis_request.upd(id_social_epis_request_in => i_request,
                                       flg_status_in             => g_soc_req_status_acc,
                                       flg_status_nin            => FALSE,
                                       id_prof_answer_in         => i_prof.id,
                                       id_prof_answer_nin        => FALSE,
                                       dt_answer_tstz_in         => g_sysdate_tstz,
                                       dt_answer_tstz_nin        => FALSE,
                                       id_episode_in             => l_episode,
                                       id_episode_nin            => FALSE);
            g_error := 'CALL t_data_gov_mnt.process_update I';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'SOCIAL_EPIS_REQUEST',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS',
                                                                          'ID_PROF_ANSWER',
                                                                          'DT_ANSWER_TSTZ',
                                                                          'ID_EPISODE'));
        ELSIF i_answer = g_soc_req_status_rej
        THEN
            -- request is rejected
            g_error := 'CALL ts_social_epis_request.upd II';
            ts_social_epis_request.upd(id_social_epis_request_in => i_request,
                                       flg_status_in             => g_soc_req_status_rej,
                                       flg_status_nin            => FALSE,
                                       id_prof_answer_in         => i_prof.id,
                                       id_prof_answer_nin        => FALSE,
                                       dt_answer_tstz_in         => g_sysdate_tstz,
                                       dt_answer_tstz_nin        => FALSE,
                                       notes_answer_in           => i_notes,
                                       notes_answer_nin          => FALSE,
                                       rows_out                  => l_rows);
            g_error := 'CALL t_data_gov_mnt.process_update II';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'SOCIAL_EPIS_REQUEST',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS',
                                                                          'ID_PROF_ANSWER',
                                                                          'DT_ANSWER_TSTZ',
                                                                          'NOTES_ANSWER'));
        ELSE
            g_error := 'Unrecognized social assistance request answer';
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 'SOCIAL_ERR001',
                                              i_sqlerrm  => g_error,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REQUEST_ANSWER',
                                              o_error    => o_error);
            RAISE g_sw_generic_exception;
        END IF;
    
        -- delete the alert created for this request
        g_error := 'CALL pk_alerts.delete_sys_alert_event';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_sys_alert => g_alert_new_request,
                                                i_id_record    => i_request,
                                                o_error        => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        -- create alert with this request's answer
        g_error := 'CALL pk_alerts.insert_sys_alert_event';
        IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_sys_alert           => g_alert_request_answer,
                                                i_id_episode          => l_req.id_episode,
                                                i_id_record           => i_request,
                                                i_dt_record           => g_sysdate_tstz,
                                                i_id_professional     => l_req.id_professional,
                                                i_id_room             => l_req.id_room,
                                                i_id_clinical_service => l_req.id_clinical_service,
                                                i_flg_type_dest       => NULL,
                                                i_replace1            => pk_sysdomain.get_domain(i_code_dom => g_soc_req_status_domain,
                                                                                                 i_val      => i_answer,
                                                                                                 i_lang     => i_lang),
                                                i_replace2            => NULL,
                                                o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        o_episode := l_episode;
        COMMIT;
        --remote scheduler commit. Doesn't affect PFH.
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_utils.undo_changes;
            --remote scheduler rollback. Doesn't affect PFH.
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REQUEST_ANSWER',
                                              o_error    => o_error);
            --remote scheduler rollback. Doesn't affect PFH.
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
        
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_request_answer;

    /*
    * Get the list of possible request answers.
    *
    * @param i_lang           language identifier
    * @param o_options        list of options
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/25
    */
    FUNCTION get_req_ans_options
    (
        i_lang    IN language.id_language%TYPE,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN o_options';
        OPEN o_options FOR
            SELECT sd.desc_val label, sd.val data, sd.img_name icon, sd.rank
              FROM sys_domain sd
             WHERE sd.code_domain = g_soc_req_status_domain
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.val IN (g_soc_req_status_acc, g_soc_req_status_rej)
               AND sd.id_language = i_lang
               AND sd.flg_available = pk_alert_constant.g_yes
             ORDER BY sd.rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REQ_ANS_OPTIONS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_options);
            RETURN FALSE;
    END get_req_ans_options;

    /*
    * Get data for the social requests grids.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_show_all       'Y' to show all requests,
    *                         'N' to show a specific SW requests.
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/25
    */
    FUNCTION get_grid_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_show_all IN VARCHAR2,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_today social_epis_request.dt_creation_tstz%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_today        := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
    
        g_error := 'OPEN o_requests';
        OPEN o_requests FOR
            SELECT dt.id_social_epis_request,
                   dt.id_episode,
                   dt.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, dt.id_patient, dt.id_episode, NULL) name,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, dt.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, dt.id_patient) pat_nd_icon,
                   (SELECT pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', dt.gender, i_lang) gender
                      FROM dual) gender,
                   pk_patient.get_pat_age(i_lang, dt.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, dt.id_patient, dt.id_episode, NULL) photo,
                   (SELECT pk_translation.get_translation(i_lang, dt.code_epis_type)
                      FROM dual) || ' - ' ||
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    dt.id_professional,
                                                    dt.dt_creation_tstz,
                                                    dt.id_episode_origin) origin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, dt.id_professional) origin_prof,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, dt.id_prof_answer) prof_answer,
                   dt.notes reason,
                   pk_date_utils.date_char_hour_tsz(i_lang, dt.next_enc_tstz, i_prof.institution, i_prof.software) dt_next_hour,
                   pk_date_utils.dt_chr_tsz(i_lang, dt.next_enc_tstz, i_prof.institution, i_prof.software) dt_next_date,
                   dt.flg_status,
                   get_req_status_str(i_lang, i_prof, dt.flg_status, dt.dt_creation_tstz) desc_status,
                   dt.id_department,
                   pk_translation.get_translation(i_lang, dt.code_department) desc_department,
                   dt.rank_department,
                   dt.id_room,
                   nvl(dt.desc_room_used, dt.desc_room) desc_room,
                   dt.rank_room,
                   dt.id_bed,
                   nvl(dt.desc_temp_bed, nvl(dt.desc_bed, pk_translation.get_translation(i_lang, dt.code_bed))) desc_bed,
                   dt.rank_bed,
                   pk_diagnosis.get_epis_diagnosis(i_lang, dt.id_episode_origin) diagnostic,
                   dt.show_triage,
                   decode(dt.show_triage, pk_alert_constant.g_yes, dt.acuity) acuity,
                   decode(dt.show_triage, pk_alert_constant.g_yes, dt.color_text) color_text,
                   decode(dt.show_triage, pk_alert_constant.g_yes, dt.rank_acuity) rank_acuity,
                   decode(dt.show_triage,
                          pk_alert_constant.g_yes,
                          (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                                    i_prof,
                                                                    dt.id_episode_origin,
                                                                    dt.id_fast_track,
                                                                    dt.id_triage_color,
                                                                    decode(dt.has_transfer,
                                                                           0,
                                                                           pk_alert_constant.g_icon_ft,
                                                                           pk_alert_constant.g_icon_ft_transfer),
                                                                    dt.has_transfer)
                             FROM dual)) fast_track_icon,
                   decode(dt.show_triage,
                          pk_alert_constant.g_yes,
                          decode(dt.acuity,
                                 pk_alert_constant.g_ft_color,
                                 pk_alert_constant.g_ft_triage_white,
                                 pk_alert_constant.g_ft_color)) fast_track_color,
                   decode(dt.show_triage, pk_alert_constant.g_yes, pk_alert_constant.g_ft_status) fast_track_status,
                   decode(dt.show_triage,
                          pk_alert_constant.g_yes,
                          (SELECT pk_fast_track.get_fast_track_desc(i_lang,
                                                                    i_prof,
                                                                    dt.id_fast_track,
                                                                    pk_alert_constant.g_desc_grid)
                             FROM dual)) fast_track_desc,
                   decode(dt.show_triage,
                          pk_alert_constant.g_yes,
                          (SELECT pk_edis_triage.get_epis_esi_level(i_lang,
                                                                    i_prof,
                                                                    dt.id_episode_origin,
                                                                    dt.id_triage_color)
                             FROM dual)) esi_level,
                   decode(dt.show_triage,
                          pk_alert_constant.g_yes,
                          pk_date_utils.date_send_tsz(i_lang, dt.dt_first_obs_tstz, i_prof)) dt_first_obs
              FROM (SELECT ser.id_social_epis_request,
                           ser.id_episode,
                           eo.id_patient,
                           eo.id_epis_type,
                           et.code_epis_type,
                           p.gender,
                           ser.id_professional,
                           ser.dt_creation_tstz,
                           ser.id_episode_origin,
                           ser.id_prof_answer,
                           ser.notes,
                           pk_paramedical_prof_core.get_dt_next_enc(ser.id_episode) next_enc_tstz,
                           ser.flg_status,
                           dep.id_department,
                           dep.code_department,
                           dep.rank rank_department,
                           r.id_room,
                           r.code_room,
                           r.rank rank_room,
                           b.id_bed,
                           b.code_bed,
                           decode(b.flg_type, pk_bmng_constant.g_bmng_bed_flg_type_t, b.desc_bed) desc_temp_bed,
                           b.rank rank_bed,
                           decode(eo.id_epis_type,
                                  pk_alert_constant.g_epis_type_emergency,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) show_triage,
                           ei.triage_acuity acuity,
                           ei.triage_color_text color_text,
                           ei.triage_rank_acuity rank_acuity,
                           ei.id_triage_color,
                           eo.id_fast_track,
                           pk_transfer_institution.check_epis_transfer(eo.id_episode) has_transfer,
                           ei.dt_first_obs_tstz,
                           b.desc_bed,
                           pk_translation.get_translation(i_lang, r.code_room) desc_room,
                           r.desc_room desc_room_used
                      FROM social_epis_request ser
                      JOIN episode eo
                        ON ser.id_episode_origin = eo.id_episode
                      JOIN patient p
                        ON eo.id_patient = p.id_patient
                      JOIN epis_type et
                        ON eo.id_epis_type = et.id_epis_type
                      JOIN epis_info ei
                        ON eo.id_episode = ei.id_episode
                      LEFT JOIN bed b
                        ON ei.id_bed = b.id_bed
                       AND b.flg_available = pk_alert_constant.g_yes
                      LEFT JOIN room r
                        ON r.id_room = b.id_room
                       AND r.flg_available = pk_alert_constant.g_yes
                      LEFT JOIN department dep
                        ON dep.id_department = r.id_department
                       AND dep.flg_available = pk_alert_constant.g_yes
                      LEFT JOIN discharge d
                        ON ser.id_episode = d.id_episode
                       AND d.flg_status = pk_alert_constant.g_active
                     WHERE eo.id_institution = i_prof.institution
                       AND (i_show_all = pk_alert_constant.g_yes OR ser.id_prof_answer = i_prof.id)
                       AND (ser.flg_status IN (g_soc_req_status_acc, g_soc_req_status_pend) OR
                           (ser.flg_status = g_soc_req_status_dsc AND d.dt_med_tstz > l_today) OR
                           (ser.flg_status = g_soc_req_status_rej AND ser.dt_answer_tstz > l_today))) dt
             ORDER BY decode(dt.flg_status,
                             g_soc_req_status_pend,
                             1,
                             g_soc_req_status_acc,
                             2,
                             g_soc_req_status_rej,
                             3,
                             g_soc_req_status_dsc,
                             4),
                      dt.dt_creation_tstz;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_GRID_REQUESTS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
    END get_grid_requests;
    --

    /********************************************************************************************
    * Create new or edit household members. When the parameter i_id_pat_household is not null 
    * we are editing the family member information
    *
    * @param i_lang                   Preferred language ID for this professional
    * @ param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_pat                 Patient ID
    * @ param i_id_pat_household       Household patient ID to edit
    * @ param i_epis                   Episode ID
    * @ param i_name                   New household member name
    * @ param i_gender                 New household member gender
    * @ param i_dt_birth               New household member birth date
    * @ param i_id_family_relationship Household member family relationship
    * @ param i_marital_status         New household member marital status
    * @ param i_scholarship            New household member scholarship
    * @ param i_pension                New household member pension
    * @ param i_net_wage               New household member wage
    * @ param i_unemployment_subsidy   New household member subsidy
    * @ param i_occupation             New household member occupation 
    * @ param i_free_text_occupation_desc New household member free_text_occupation
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/03/04
    **********************************************************************************************/
    FUNCTION set_household_member
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_pat                    IN patient.id_patient%TYPE,
        i_id_pat_household          IN patient.id_patient%TYPE,
        i_epis                      IN episode.id_episode%TYPE,
        i_name                      IN patient.name%TYPE,
        i_gender                    IN patient.gender%TYPE,
        i_dt_birth                  IN VARCHAR2,
        i_id_family_relationship    IN pat_family_member.id_family_relationship%TYPE,
        i_marital_status            IN pat_soc_attributes.marital_status%TYPE,
        i_scholarship               IN pat_soc_attributes.id_scholarship%TYPE,
        i_pension                   IN pat_soc_attributes.pension%TYPE,
        i_net_wage                  IN pat_soc_attributes.net_wage%TYPE,
        i_unemployment_subsidy      IN pat_soc_attributes.unemployment_subsidy%TYPE,
        i_occupation                IN pat_job.id_occupation%TYPE,
        i_free_text_occupation_desc IN pat_job.occupation_desc%TYPE,
        i_dependecy                 IN patient.flg_dependence_level%TYPE,
        i_fam_doctor                IN pat_professional_inst.id_professional%TYPE,
        i_free_text_fam_doctor      IN pat_professional_inst.desc_professional%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_next_pat        patient.id_patient%TYPE;
        l_error           t_error_out;
        l_pat_family      patient.id_pat_family%TYPE;
        l_pat_job         pat_job.id_pat_job%TYPE;
        l_inst_type       institution.flg_type%TYPE;
        l_rowids          table_varchar;
        l_family_monetary family_monetary.id_family_monetary%TYPE;
    
        l_id_currency_default currency.id_currency%TYPE;
    
        l_pat_professional_num      PLS_INTEGER;
        l_pat_professional_next_key pat_professional_inst.id_pat_professional_inst%TYPE;
    
        l_occupation pat_job.id_occupation%TYPE;
        CURSOR c_inst_type IS
            SELECT flg_type
              FROM institution
             WHERE id_institution = i_prof.institution;
    
        CURSOR c_pat_job(i_pat patient.id_patient%TYPE) IS
            SELECT pj.id_pat_job
              FROM pat_job pj
             WHERE pj.id_patient = i_pat
               AND pj.dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                           FROM pat_job p1
                                          WHERE p1.id_patient = i_pat);
    
        CURSOR c_family_monetary IS
            SELECT fm.id_family_monetary
              FROM family_monetary fm, patient p
             WHERE p.id_patient = i_id_pat
               AND p.id_pat_family = fm.id_pat_family;
    
    BEGIN
        pk_alertlog.log_debug('SET_HOUSEHOLD_MEMBER: i_id_pat = ' || i_id_pat || ', i_id_pat_household =' ||
                              i_id_pat_household || ', i_name =' || i_name || ', i_gender = ' || i_gender ||
                              ', i_dt_birth =  ' || i_dt_birth || ', i_id_family_relationship ' ||
                              i_id_family_relationship || ', i_scholarship = ' || i_scholarship || ', i_pension = ' ||
                              i_pension || ', i_net_wage = ' || i_net_wage || ', i_unemployment_subsidy = ' ||
                              i_unemployment_subsidy || ', i_occupation = ' || i_occupation ||
                              ', i_free_text_occupation_desc = ' || i_free_text_occupation_desc);
    
        g_sysdate_tstz := current_timestamp;
    
        --
        g_error               := 'GET_CURRENCY_DEFAULT';
        l_id_currency_default := get_currency_default(i_prof);
    
        IF i_occupation = -1
        THEN
            l_occupation := NULL;
        ELSE
            l_occupation := i_occupation;
        END IF;
    
        IF i_id_pat_household IS NOT NULL
        THEN
            l_next_pat := i_id_pat_household;
            --update patient data
            ts_patient.upd(id_patient_in    => i_id_pat_household,
                           name_in          => i_name,
                           nick_name_in     => i_name,
                           gender_in        => i_gender,
                           dt_birth_in      => to_date(i_dt_birth, 'YYYYMMDDhh24miss'),
                           id_pat_family_in => l_pat_family,
                           rows_out         => l_rowids);
        
            --TODO: waiting form ADT development synchronization                          
            UPDATE patient pat
               SET pat.flg_dependence_level = i_dependecy
             WHERE pat.id_patient = i_id_pat_household;
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PATIENT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            --
            ts_pat_soc_attributes.upd(marital_status_in        => i_marital_status,
                                      id_scholarship_in        => i_scholarship,
                                      id_institution_in        => i_prof.institution,
                                      id_language_in           => i_lang,
                                      pension_in               => i_pension,
                                      pension_nin              => FALSE,
                                      id_currency_pension_in   => l_id_currency_default,
                                      net_wage_in              => i_net_wage,
                                      net_wage_nin             => FALSE,
                                      id_currency_net_wage_in  => l_id_currency_default,
                                      unemployment_subsidy_in  => i_unemployment_subsidy,
                                      unemployment_subsidy_nin => FALSE,
                                      id_currency_unemp_sub_in => l_id_currency_default,
                                      where_in                 => 'id_patient = ' || i_id_pat_household,
                                      rows_out                 => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_SOC_ATTRIBUTES',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'GET CURSOR C_PAT_JOB';
            OPEN c_pat_job(i_id_pat_household);
            FETCH c_pat_job
                INTO l_pat_job;
            CLOSE c_pat_job;
        
            IF l_pat_job IS NULL
            THEN
                g_error := 'INSERT INTO PAT_JOB';
                ts_pat_job.ins(id_patient_in      => i_id_pat_household,
                               flg_status_in      => pk_alert_constant.g_flg_status_a,
                               id_occupation_in   => l_occupation,
                               occupation_desc_in => i_free_text_occupation_desc,
                               dt_pat_job_tstz_in => g_sysdate_tstz,
                               id_institution_in  => i_prof.institution,
                               id_episode_in      => -1,
                               rows_out           => l_rowids);
            ELSE
                g_error := 'UPDATE INTO PAT_JOB';
                ts_pat_job.upd(id_occupation_in    => l_occupation,
                               id_occupation_nin   => FALSE,
                               occupation_desc_in  => i_free_text_occupation_desc,
                               occupation_desc_nin => FALSE,
                               where_in            => 'id_patient = ' || i_id_pat_household,
                               rows_out            => l_rowids);
            END IF;
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_JOB';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_JOB',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'INSERT INTO PAT_FAMILY_MEMBER';
            ts_pat_family_member.upd(id_family_relationship_in => i_id_family_relationship,
                                     where_in                  => 'id_pat_related  = ' || i_id_pat_household ||
                                                                  ' and id_patient = ' || i_id_pat,
                                     rows_out                  => l_rowids);
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_FAMILY_MEMBER';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_FAMILY_MEMBER',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        ELSE
        
            g_error := 'OPEN C_INST_TYPE';
            OPEN c_inst_type;
            FETCH c_inst_type
                INTO l_inst_type;
            CLOSE c_inst_type;
        
            --PrimaryCare Institution
            IF l_inst_type = 'C'
            THEN
                --it's not possible to create family members in CARE
                pk_alertlog.log_error('PRIMARY CARE INSTITUTION - It is not possible to create new household members');
                RETURN error_handling(i_lang           => i_lang,
                                      i_func_proc_name => 'SET_HOUSEHOLD_MEMBER',
                                      i_error          => g_error,
                                      i_sqlerror       => pk_message.get_message(i_lang, 'SOCIAL_M009'),
                                      o_error          => o_error);
            ELSE
            
                IF i_name IS NULL
                THEN
                    --name is mandatory
                    pk_alertlog.log_error('Name is a mandatory field!');
                    RETURN error_handling(i_lang           => i_lang,
                                          i_func_proc_name => 'CREATE_PAT_FAMILY',
                                          i_error          => g_error,
                                          i_sqlerror       => pk_message.get_message(i_lang, 'SOCIAL_M014'),
                                          o_error          => o_error);
                END IF;
            
                -- verificar se o paciente já tem id_pat_family associado
                --cannot commit here
                IF NOT set_pat_fam(i_lang       => i_lang,
                                   i_id_pat     => i_id_pat,
                                   i_prof       => i_prof,
                                   i_commit     => pk_alert_constant.g_no,
                                   o_id_pat_fam => l_pat_family,
                                   o_error      => l_error)
                THEN
                    o_error := l_error;
                    RAISE g_exception;
                END IF;
            
                g_error := 'INSERT INTO PATIENT';
                ts_patient.ins(name_in          => i_name,
                               nick_name_in     => i_name,
                               gender_in        => i_gender,
                               dt_birth_in      => to_date(i_dt_birth, 'YYYYMMDDhh24miss'),
                               id_pat_family_in => l_pat_family,
                               flg_status_in    => g_flg_active,
                               id_patient_out   => l_next_pat,
                               rows_out         => l_rowids);
            
                --TODO: waiting form ADT development synchronization                          
                UPDATE patient pat
                   SET pat.flg_dependence_level = i_dependecy
                 WHERE pat.id_patient = l_next_pat;
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PATIENT',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'INSERT INTO PAT_SOC_ATTRIBUTES';
                ts_pat_soc_attributes.ins(id_patient_in            => l_next_pat,
                                          marital_status_in        => i_marital_status,
                                          id_scholarship_in        => i_scholarship,
                                          id_institution_in        => i_prof.institution,
                                          id_language_in           => i_lang,
                                          pension_in               => i_pension,
                                          id_currency_pension_in   => l_id_currency_default,
                                          net_wage_in              => i_net_wage,
                                          id_currency_net_wage_in  => l_id_currency_default,
                                          unemployment_subsidy_in  => i_unemployment_subsidy,
                                          id_currency_unemp_sub_in => l_id_currency_default,
                                          id_episode_in            => i_epis,
                                          rows_out                 => l_rowids);
            
                g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_SOC_ATTRIBUTES';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_SOC_ATTRIBUTES',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'INSERT INTO PAT_JOB';
                ts_pat_job.ins(id_patient_in      => l_next_pat,
                               flg_status_in      => pk_alert_constant.g_flg_status_a,
                               id_occupation_in   => l_occupation,
                               occupation_desc_in => i_free_text_occupation_desc,
                               dt_pat_job_tstz_in => g_sysdate_tstz,
                               id_institution_in  => i_prof.institution,
                               id_episode_in      => -1,
                               rows_out           => l_rowids);
            
                g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_JOB';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_JOB',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'INSERT INTO PAT_FAMILY_MEMBER';
                ts_pat_family_member.ins(id_patient_in             => i_id_pat,
                                         id_pat_related_in         => l_next_pat,
                                         id_family_relationship_in => i_id_family_relationship,
                                         id_pat_family_in          => l_pat_family,
                                         id_institution_in         => i_prof.institution,
                                         flg_status_in             => g_flg_active,
                                         id_episode_in             => i_epis,
                                         rows_out                  => l_rowids);
            
                g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON PAT_FAMILY_MEMBER';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_FAMILY_MEMBER',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
            END IF;
        
        END IF;
    
        -- is there is some income and family_monetary not yet defined then create one
        IF nvl(i_pension, 0) != 0
           OR nvl(i_net_wage, 0) != 0
           OR nvl(i_unemployment_subsidy, 0) != 0
        THEN
            g_error := 'OPEN C_INST_TYPE';
            OPEN c_family_monetary;
            FETCH c_family_monetary
                INTO l_family_monetary;
            CLOSE c_family_monetary;
        
            IF l_family_monetary IS NULL
            THEN
                IF NOT pk_social.set_household_financial(i_lang                    => i_lang,
                                                         i_prof                    => i_prof,
                                                         i_id_pat                  => i_id_pat,
                                                         i_id_fam_money            => NULL,
                                                         i_allowance_family        => NULL,
                                                         i_currency_allow_family   => NULL,
                                                         i_allowance_complementary => NULL,
                                                         i_currency_allow_comp     => NULL,
                                                         i_other                   => NULL,
                                                         i_currency_other          => NULL,
                                                         i_subsidy                 => NULL,
                                                         i_currency_subsidy        => NULL,
                                                         i_fixed_expenses          => NULL,
                                                         i_currency_fixed_exp      => NULL,
                                                         i_total_fam_members       => NULL,
                                                         i_notes                   => NULL,
                                                         i_epis                    => i_epis,
                                                         o_error                   => l_error)
                THEN
                    o_error := l_error;
                    RAISE g_exception;
                END IF;
            END IF;
        END IF;
    
        --
        IF i_fam_doctor IS NOT NULL
           OR i_free_text_fam_doctor IS NOT NULL
        THEN
        
            pk_alertlog.log_debug('set family doctor : i_fam_doctor' || i_fam_doctor || ', i_free_text_fam_doctor' ||
                                  i_free_text_fam_doctor);
        
            g_error := 'EXISTS FAMILY DOCTOR?';
            SELECT COUNT(*)
              INTO l_pat_professional_num
              FROM pat_professional_inst pp
             WHERE pp.id_patient = l_next_pat
               AND pp.flg_family_physician = pk_alert_constant.g_yes;
        
            IF l_pat_professional_num = 0
            THEN
                l_pat_professional_next_key := adt_next_key('PAT_PROFESSIONAL_INST', i_prof);
                g_error                     := 'INSERT INTO PAT_PROFESSIONAL_INST FOR PATIENT = ' || l_next_pat ||
                                               ', key = ' || l_pat_professional_next_key;
                pk_alertlog.log_debug(g_error);
            
                INSERT INTO pat_professional_inst
                    (id_pat_professional_inst, id_patient, id_professional, flg_family_physician, desc_professional)
                VALUES
                    (l_pat_professional_next_key,
                     l_next_pat,
                     i_fam_doctor,
                     pk_alert_constant.g_yes,
                     i_free_text_fam_doctor);
                --                     NULL;
            ELSE
                g_error := 'UPDATE PAT_PROFESSIONAL_INST FOR PATIENT = ' || l_next_pat;
                pk_alertlog.log_debug(g_error);
                UPDATE pat_professional_inst pp
                   SET pp.id_professional = i_fam_doctor, pp.desc_professional = i_free_text_fam_doctor
                 WHERE pp.id_patient = l_next_pat
                   AND pp.flg_family_physician = pk_alert_constant.g_yes;
            END IF;
        END IF;
        --
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
        --
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'SET_HOUSEHOLD_MEMBER',
                                                     o_error);
        
    END set_household_member;
    --

    /********************************************************************************************
    * Get domains values for the household fields (gender, marital status, relationship, occupation).
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *
    * @ param o_currency_domain       Currency domain
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/05
    **********************************************************************************************/
    FUNCTION get_household_domains
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_gender_domain       OUT pk_types.cursor_type,
        o_marital_domain      OUT pk_types.cursor_type,
        o_relationship_domain OUT pk_types.cursor_type,
        o_occupation_domain   OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('GET_HOUSEHOLD_DOMAINS');
        --
        g_error := 'GET_GENDER_LIST';
        IF NOT pk_list.get_gender_list(i_lang => i_lang, o_gender => o_gender_domain, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        g_error := 'GET_MARITAL_STATUS_LIST';
        IF NOT pk_list.get_marital_list(i_lang => i_lang, o_marital => o_marital_domain, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        g_error := 'GET_RELATIONSHIP_LIST';
        IF NOT get_relationship_list(i_lang         => i_lang,
                                     i_gender       => NULL,
                                     i_prof         => i_prof,
                                     o_relationship => o_relationship_domain,
                                     o_error        => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        g_error := 'GET_OCCUP_LIST';
        IF NOT get_occup_list(i_lang => i_lang, o_occup => o_occupation_domain, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_gender_domain);
            pk_types.open_my_cursor(o_marital_domain);
            pk_types.open_my_cursor(o_relationship_domain);
            pk_types.open_my_cursor(o_occupation_domain);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_HOUSEHOLD_DOMAINS',
                                                     o_error);
        
    END get_household_domains;
    --

    /********************************************************************************************
    * Get domains values for the household fields (gender, marital status, relationship, occupation).
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *    
    * @ param o_gender_domain         Gender list
    * @ param o_marital_domain        Marital status list  
    * @ param o_relationship_domain   Relationship list 
    * @ param o_occupation_domain     Occupation list
    * @ param o_currency_domain       Currency list
    * @ param o_dependency            Dependency list
    * @ param o_prof_list             List of doctors
    
    * @ param o_currency_domain       Currency domain
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/05
    **********************************************************************************************/
    FUNCTION get_household_domains
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_gender_domain       OUT pk_types.cursor_type,
        o_marital_domain      OUT pk_types.cursor_type,
        o_relationship_domain OUT pk_types.cursor_type,
        o_occupation_domain   OUT pk_types.cursor_type,
        o_currency_domain     OUT pk_types.cursor_type,
        o_dependency          OUT pk_types.cursor_type,
        o_prof_list_domain    OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --get_all_doctors
        l_prof_cat table_varchar := table_varchar('D');
        --
    BEGIN
        pk_alertlog.log_debug('GET_HOUSEHOLD_DOMAINS');
        --
        g_error := 'GET_GENDER_LIST';
        IF NOT pk_list.get_gender_list(i_lang => i_lang, o_gender => o_gender_domain, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        g_error := 'GET_MARITAL_STATUS_LIST';
        IF NOT pk_list.get_marital_list(i_lang => i_lang, o_marital => o_marital_domain, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        g_error := 'GET_RELATIONSHIP_LIST';
        IF NOT get_relationship_list(i_lang         => i_lang,
                                     i_gender       => NULL,
                                     i_prof         => i_prof,
                                     o_relationship => o_relationship_domain,
                                     o_error        => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        g_error := 'GET_OCCUP_LIST';
        IF NOT get_occup_list(i_lang     => i_lang,
                              i_show_all => pk_alert_constant.g_no,
                              o_occup    => o_occupation_domain,
                              o_error    => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        g_error := 'GET_CURRENCY_LIST';
    
        IF NOT get_currency_list(i_lang     => i_lang,
                                 i_prof     => i_prof,
                                 i_show_all => pk_alert_constant.g_no,
                                 o_currency => o_currency_domain,
                                 o_error    => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        g_error := 'GET_DEPENDENCY_LIST';
        IF NOT get_dependency_list(i_lang => i_lang, i_prof => i_prof, o_dependency => o_dependency, o_error => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        g_error := 'GET_PROF_LIST';
        --profs
        IF NOT pk_list.get_prof_inst_and_other_list(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_prof_cat  => l_prof_cat,
                                                    o_prof_list => o_prof_list_domain,
                                                    o_error     => o_error) -- not o_error in order to compile.
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_gender_domain);
            pk_types.open_my_cursor(o_marital_domain);
            pk_types.open_my_cursor(o_relationship_domain);
            pk_types.open_my_cursor(o_occupation_domain);
            pk_types.open_my_cursor(o_currency_domain);
            --
            pk_types.open_my_cursor(o_dependency);
            pk_types.open_my_cursor(o_prof_list_domain);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_HOUSEHOLD_DOMAINS',
                                                     o_error);
        
    END get_household_domains;
    --

    /********************************************************************************************
     * Get values for the dependency list
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_dependency             List of dependency values
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         2.6.0.1
     * @since                           2010/03/08
    **********************************************************************************************/
    FUNCTION get_dependency_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_dependency OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('GET_HOUSEHOLD_DEPENDENCY_LIST');
    
        g_error := 'GET CURSOR o_dependency';
        OPEN o_dependency FOR
            SELECT val data, desc_dependency label
              FROM (SELECT val, rank, desc_val desc_dependency
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND code_domain = 'PATIENT.FLG_DEPENDENCE_LEVEL'
                       AND flg_available = pk_alert_constant.g_yes
                     ORDER BY desc_dependency DESC);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dependency);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_DEPENDENCY_LIST',
                                                     o_error);
        
    END get_dependency_list;
    --
    --TODO: delete this function - to be provided by the ADT team
    FUNCTION adt_next_key
    (
        table_name IN VARCHAR2,
        i_prof     IN profissional
    ) RETURN patient.id_patient%TYPE IS
        retval patient.id_patient%TYPE;
    BEGIN
        pk_alertlog.log_debug('SELECT SEQ_' || table_name || '.NEXTVAL FROM dual');
    
        EXECUTE IMMEDIATE 'SELECT SEQ_' || table_name || '.NEXTVAL FROM dual'
            INTO retval;
        retval := (retval * 1000000) + i_prof.institution;
        pk_alertlog.log_debug('retval = ' || retval);
        RETURN retval;
    EXCEPTION
        WHEN OTHERS THEN
            /*pk_alert_exceptions.raise_error(error_name_in => 'SEQUENCE-GENERATION-FAILURE',
            name1_in      => 'SEQUENCE',
            value1_in     => nvl('SEQ'||table_name, 'seq_PATIENT'));*/
            RAISE;
    END adt_next_key;
    --

    /********************************************************************************************
    * Get patient's EHR Social Summary. This includes information of:
    *    - Diagnosis
    *    - Intervention plan
    *    - Follow up notes
    *    - Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * 
    * @ param  o_screen_labels        Labels
    * @ param  o_episodes_det         List of patient's episodes
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_follow_up             Follow up notes list
    * @ param o_social_report         Social report list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/15
    **********************************************************************************************/
    FUNCTION get_social_summary_ehr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --labels
        o_screen_labels OUT pk_types.cursor_type,
        --list of episodes
        o_episodes_det OUT pk_types.cursor_type,
        --diagnosis
        o_diagnosis OUT pk_types.cursor_type,
        --intervention_plan
        o_interv_plan OUT pk_types.cursor_type,
        --followup notes
        o_follow_up OUT pk_types.cursor_type,
        --report
        o_social_report OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_temp_cur pk_types.cursor_type;
    
    BEGIN
        pk_alertlog.log_debug('GET_SOCIAL_SUMMARY_EHR - get all labels for the social status screen');
        g_error := 'GET_SOCIAL_SUMMARY_EHR';
    
        IF NOT pk_social.get_social_summary_ehr(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_id_pat         => i_id_pat,
                                                i_episode        => i_episode,
                                                o_screen_labels  => o_screen_labels,
                                                o_episodes_det   => o_episodes_det,
                                                o_diagnosis      => o_diagnosis,
                                                o_interv_plan    => o_interv_plan,
                                                o_follow_up      => o_follow_up,
                                                o_social_report  => o_social_report,
                                                o_social_request => l_temp_cur,
                                                o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_screen_labels);
            pk_types.open_my_cursor(o_episodes_det);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_social_report);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_SOCIAL_SUMMARY_EHR',
                                                     o_error);
        
    END get_social_summary_ehr;
    --

    /********************************************************************************************
    * Get patient's EHR Social Summary. This includes information of:
    *    - Diagnosis
    *    - Intervention plan
    *    - Follow up notes
    *    - Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * 
    * @ param  o_screen_labels        Labels
    * @ param  o_episodes_det         List of patient's episodes
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_follow_up             Follow up notes list
    * @ param o_social_report         Social report list
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/15
    **********************************************************************************************/
    FUNCTION get_social_summary_ehr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --labels
        o_screen_labels OUT pk_types.cursor_type,
        --list of episodes
        o_episodes_det OUT pk_types.cursor_type,
        --diagnosis
        o_diagnosis OUT pk_types.cursor_type,
        --intervention_plan
        o_interv_plan OUT pk_types.cursor_type,
        --followup notes
        o_follow_up OUT pk_types.cursor_type,
        --report
        o_social_report OUT pk_types.cursor_type,
        --request
        o_social_request OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_temp_cur pk_types.cursor_type;
        l_episodes table_number;
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    
        l_social_summary_view_type VARCHAR2(1 CHAR);
        l_category                 category.flg_type%TYPE;
    BEGIN
        pk_alertlog.log_debug('GET_SOCIAL_SUMMARY_EHR - get all labels for the social status screen');
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T149',
                                                                                          'PARAMEDICAL_T022',
                                                                                          'PARAMEDICAL_T005',
                                                                                          'SOCIAL_T100',
                                                                                          'SOCIAL_T113',
                                                                                          'SOCIAL_T153'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        OPEN o_screen_labels FOR
            SELECT t_table_message_array('SOCIAL_T149') ehr_summary_main_header,
                   t_table_message_array('PARAMEDICAL_T022') social_diagnosis_header,
                   t_table_message_array('PARAMEDICAL_T005') social_interv_plan_header,
                   t_table_message_array('SOCIAL_T100') social_followup_header,
                   t_table_message_array('SOCIAL_T113') social_report_header,
                   t_table_message_array('SOCIAL_T153') social_request_header
              FROM dual;
    
        IF NOT get_epis_by_pat(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_id_pat       => i_id_pat,
                               i_id_epis_type => table_number(pk_alert_constant.g_epis_type_social),
                               o_episodes_ids => l_episodes,
                               o_error        => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --
        IF NOT get_social_episodes_det(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_episode      => l_episodes,
                                       o_episodes_det => o_episodes_det,
                                       o_error        => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
    
        -- get view type
        l_social_summary_view_type := pk_sysconfig.get_config(i_code_cf => 'SUMMARY_VIEW_ALL', i_prof => i_prof);
        l_category                 := pk_prof_utils.get_category(i_lang, i_prof);
        g_error                    := 'Get only the information that the profissional can see';
        IF l_category <> pk_alert_constant.g_cat_type_social
           AND l_social_summary_view_type = pk_alert_constant.g_no
        THEN
            pk_types.open_my_cursor(o_diagnosis);
            --
            pk_types.open_my_cursor(o_interv_plan);
            --
            pk_types.open_my_cursor(o_follow_up);
            --
        ELSE
            --
            IF NOT pk_paramedical_prof_core.get_summ_page_diag(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_epis           => l_episodes,
                                                               o_diagnosis      => o_diagnosis,
                                                               o_diagnosis_prof => l_temp_cur,
                                                               o_error          => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
            --
        
            IF NOT pk_paramedical_prof_core.get_interv_plan_summary(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_id_epis          => l_episodes,
                                                                    o_interv_plan      => o_interv_plan,
                                                                    o_interv_plan_prof => l_temp_cur,
                                                                    o_error            => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
            CLOSE l_temp_cur;
            --follow_up
        
            IF NOT pk_paramedical_prof_core.get_followup_notes(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_episode        => l_episodes,
                                                               i_mng_followup   => NULL,
                                                               i_show_cancelled => pk_alert_constant.g_no,
                                                               i_opinion_type   => pk_opinion.g_ot_social_worker,
                                                               o_follow_up_prof => l_temp_cur,
                                                               o_follow_up      => o_follow_up,
                                                               o_error          => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        
            CLOSE l_temp_cur;
        END IF;
    
        g_error := 'CALL pk_paramedical_prof_core.get_paramed_report';
        IF NOT pk_paramedical_prof_core.get_paramed_report(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => l_episodes,
                                                           i_report         => NULL,
                                                           i_show_cancelled => pk_alert_constant.g_no,
                                                           o_report_prof    => l_temp_cur,
                                                           o_report         => o_social_report,
                                                           o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        CLOSE l_temp_cur;
    
        g_error := 'CALL get_social_requests_summary';
        IF NOT get_social_requests_summary(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_episode       => l_episodes,
                                           o_requests      => o_social_request,
                                           o_requests_prof => l_temp_cur,
                                           o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        CLOSE l_temp_cur;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_screen_labels);
            pk_types.open_my_cursor(o_episodes_det);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_interv_plan);
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_social_report);
            pk_types.open_my_cursor(o_social_request);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_SOCIAL_SUMMARY_EHR',
                                                     o_error);
        
    END get_social_summary_ehr;

    /**
    * Get the EHR social summary
    * (implementation of get_social_summary_ehr for the Reports layer).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param o_labels       labels
    * @param o_episodes_det episodes
    * @param o_diagnosis    social diagnoses
    * @param o_interv_plan  social intervention plans
    * @param o_follow_up    follow up notes
    * @param o_soc_report   social report
    * @param o_soc_request  previous encounters data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/06/12
    */
    FUNCTION get_social_summary_ehr_rep
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_labels       OUT pk_types.cursor_type,
        o_episodes_det OUT pk_types.cursor_type,
        o_diagnosis    OUT pk_types.cursor_type,
        o_interv_plan  OUT pk_types.cursor_type,
        o_follow_up    OUT pk_types.cursor_type,
        o_soc_report   OUT pk_types.cursor_type,
        o_soc_request  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SOCIAL_SUMMARY_EHR_REP';
        l_temp_cur pk_types.cursor_type;
        l_episodes table_number;
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    
        l_social_summary_view_type VARCHAR2(1 CHAR);
        l_category                 category.flg_type%TYPE;
    BEGIN
        pk_alertlog.log_debug(text            => 'get all labels for the social status screen',
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T149',
                                                                                          'PARAMEDICAL_T022',
                                                                                          'PARAMEDICAL_T005',
                                                                                          'SOCIAL_T100',
                                                                                          'SOCIAL_T113',
                                                                                          'SOCIAL_T153'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        OPEN o_labels FOR
            SELECT t_table_message_array('SOCIAL_T149') ehr_summary_main_header,
                   t_table_message_array('PARAMEDICAL_T022') social_diagnosis_header,
                   t_table_message_array('PARAMEDICAL_T005') social_interv_plan_header,
                   t_table_message_array('SOCIAL_T100') social_followup_header,
                   t_table_message_array('SOCIAL_T113') social_report_header,
                   t_table_message_array('SOCIAL_T153') social_request_header
              FROM dual;
    
        IF NOT get_epis_by_pat(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_id_pat       => i_patient,
                               i_id_epis_type => table_number(pk_alert_constant.g_epis_type_social),
                               o_episodes_ids => l_episodes,
                               o_error        => o_error)
        
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        IF NOT get_social_episodes_det(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_episode      => l_episodes,
                                       o_episodes_det => o_episodes_det,
                                       o_error        => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
    
        -- get view type
        l_social_summary_view_type := pk_sysconfig.get_config(i_code_cf => 'SUMMARY_VIEW_ALL', i_prof => i_prof);
        l_category                 := pk_prof_utils.get_category(i_lang, i_prof);
        g_error                    := 'Get only the information that the profissional can see';
        IF l_category <> pk_alert_constant.g_cat_type_social
           AND l_social_summary_view_type = pk_alert_constant.g_no
        THEN
            pk_types.open_my_cursor(o_diagnosis);
            --
            pk_types.open_my_cursor(o_interv_plan);
            --
            pk_types.open_my_cursor(o_follow_up);
            --
        ELSE
            g_error := 'CALL pk_paramedical_prof_core.get_summ_page_diag_rep';
            pk_paramedical_prof_core.get_summ_page_diag_rep(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_epis      => l_episodes,
                                                            o_diagnosis => o_diagnosis);
        
            g_error := 'CALL pk_paramedical_prof_core.get_interv_plan_summary_rep';
            pk_paramedical_prof_core.get_interv_plan_summary_rep(i_lang        => i_lang,
                                                                 i_prof        => i_prof,
                                                                 i_id_epis     => l_episodes,
                                                                 o_interv_plan => o_interv_plan);
        
            g_error := 'CALL pk_paramedical_prof_core.get_followup_notes_list_report';
            pk_paramedical_prof_core.get_followup_notes_list_report(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_episode        => l_episodes,
                                                                    i_show_cancelled => pk_alert_constant.g_no,
                                                                    i_report         => pk_alert_constant.g_yes,
                                                                    o_follow_up_prof => l_temp_cur,
                                                                    o_follow_up      => o_follow_up);
            CLOSE l_temp_cur;
        END IF;
    
        g_error := 'CALL pk_paramedical_prof_core.get_paramed_report_list_report';
        pk_paramedical_prof_core.get_paramed_report_list_report(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_episode        => l_episodes,
                                                                i_show_cancelled => pk_alert_constant.g_no,
                                                                o_report_prof    => l_temp_cur,
                                                                o_report         => o_soc_report);
        CLOSE l_temp_cur;
    
        g_error := 'CALL get_social_requests_summ_rep';
        get_social_requests_summ_rep(i_lang     => i_lang,
                                     i_prof     => i_prof,
                                     i_episode  => l_episodes,
                                     o_requests => o_soc_request);
    
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_social_summary_ehr_rep;

    /********************************************************************************************
    * Get the episodes detail information 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @ param o_episodes_det          List of episodes detail
    * @ param o_error 
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/15
    **********************************************************************************************/
    FUNCTION get_social_episodes_det
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        --list of episodes
        o_episodes_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_SOCIAL_EPISODES_DET - Begin';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_episodes_det FOR
            SELECT epi.id_episode id_episode,
                   pk_date_utils.dt_chr_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt,
                   pk_date_utils.date_send_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt_str,
                   pk_tools.get_prof_description(i_lang, i_prof, ei.id_professional, epi.dt_creation, NULL) prof_sign,
                   pk_message.get_message(i_lang, 'SOCIAL_T149') epis_det_desc
              FROM episode epi
              JOIN epis_info ei
                ON epi.id_episode = ei.id_episode
             WHERE epi.id_patient = i_id_pat
               AND epi.flg_status <> pk_alert_constant.g_flg_status_c
             ORDER BY epi.dt_begin_tstz DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_episodes_det);
            --
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SOCIAL',
                                              i_function => 'GET_SOCIAL_EPISODES_DET',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_social_episodes_det;
    --

    /********************************************************************************************
    * Get the episodes detail information, within a list of episodes 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episodes ID    
    * @ param o_episodes_det          List of episodes detail
    * @ param o_error 
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Teresa Coutinho
    * @version                         0.1
    * @since                           2014/09/19
    **********************************************************************************************/
    FUNCTION get_social_episodes_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN table_number,
        o_episodes_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_SOCIAL_EPISODES_DET - Begin';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_episodes_det FOR
            SELECT epi.id_episode id_episode,
                   pk_date_utils.dt_chr_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt,
                   pk_date_utils.date_send_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt_str,
                   pk_tools.get_prof_description(i_lang, i_prof, ei.id_professional, epi.dt_creation, NULL) prof_sign,
                   pk_message.get_message(i_lang, 'SOCIAL_T149') epis_det_desc
              FROM episode epi
              JOIN epis_info ei
                ON epi.id_episode = ei.id_episode
             WHERE epi.id_episode IN (SELECT column_value
                                        FROM TABLE(i_episode))
               AND epi.flg_status <> pk_alert_constant.g_flg_status_c
             ORDER BY epi.dt_begin_tstz DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_episodes_det);
            --
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SOCIAL',
                                              i_function => 'GET_SOCIAL_EPISODES_DET',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_social_episodes_det;
    --

    /********************************************************************************************
    * Get patient's list of episode of a given type 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @ param i_id_epis_type          List of epis types
    * @ param i_remove_status         Episode status to remove from the list
    * @ param o_episodes_ids          List of episode IDs
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/15
    **********************************************************************************************/
    FUNCTION get_epis_by_type_and_pat
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_epis_type  IN table_number,
        i_remove_status IN table_varchar DEFAULT table_varchar(pk_alert_constant.g_flg_status_c),
        --list of episodes
        o_episodes_ids OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_EPIS_BY_TYPE_AND_PAT';
        pk_alertlog.log_debug(g_error);
    
        SELECT epi.id_episode id_episode
          BULK COLLECT
          INTO o_episodes_ids
          FROM episode epi
         WHERE epi.id_epis_type IN (SELECT column_value
                                      FROM TABLE(i_id_epis_type))
           AND epi.id_patient = i_id_pat
           AND epi.flg_status NOT IN (SELECT column_value
                                        FROM TABLE(i_remove_status));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            --
            --
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SOCIAL',
                                              i_function => 'GET_EPIS_BY_TYPE_AND_PAT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
    END get_epis_by_type_and_pat;

    /********************************************************************************************
    * Get social episode type
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID
    *
    * @return                         A for appointments or R for requests
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/24
    **********************************************************************************************/
    FUNCTION get_social_epis_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        --
        l_social_epis VARCHAR2(1 CHAR);
        l_count       PLS_INTEGER;
    BEGIN
        g_error := 'GET_SOCIAL_EPIS_TYPE BEGIN';
        pk_alertlog.log_debug(g_error);
    
        SELECT COUNT(*)
          INTO l_count
          FROM opinion o
         WHERE o.id_episode_answer = i_id_epis;
        --
        IF l_count <> 0
        THEN
            l_social_epis := 'R';
        ELSE
            l_social_epis := 'A';
        END IF;
        RETURN l_social_epis;
    EXCEPTION
        WHEN OTHERS THEN
            --
            RETURN l_social_epis;
    END get_social_epis_type;
    --

    /********************************************************************************************
    * Get patient's household data for the report 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    
    * @ param o_pat                   Household information
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/30
    **********************************************************************************************/
    FUNCTION get_social_household_report
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        --
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_social.get_household(i_lang          => i_lang,
                                       i_episode       => NULL,
                                       i_id_pat        => i_id_pat,
                                       i_prof          => i_prof,
                                       o_pat_household => o_pat,
                                       o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_SOCIAL_HOUSEHOLD_REPORT',
                                                     o_error);
        
    END get_social_household_report;
    --

    /********************************************************************************************
    * Get patient's home data for the report 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    *
    * @ param o_pat                   Household information
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/30
    **********************************************************************************************/
    FUNCTION get_social_home_report
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        --
        o_pat      OUT pk_types.cursor_type,
        o_pat_prof OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        IF NOT pk_social.get_home_2(i_lang              => i_lang,
                                    i_id_pat            => i_id_pat,
                                    i_prof              => i_prof,
                                    i_history           => pk_alert_constant.g_no,
                                    i_show_cancel       => pk_alert_constant.g_no,
                                    i_show_header_label => pk_alert_constant.g_no,
                                    i_report            => pk_alert_constant.g_outdated,
                                    o_pat_home          => o_pat,
                                    o_pat_home_prof     => o_pat_prof,
                                    o_error             => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat);
            pk_types.open_my_cursor(o_pat_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_SOCIAL_HOME_REPORT',
                                                     o_error);
        
    END get_social_home_report;
    --

    /********************************************************************************************
    * Get intervention plans data for the given episode to be used in report 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    *
    * @ param o_pat                   Household information
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/30
    **********************************************************************************************/
    FUNCTION get_social_interv_plan_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        o_soc_epis_interv OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_temp_cur pk_types.cursor_type;
    BEGIN
        --
        IF NOT pk_paramedical_prof_core.get_interv_plan(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_id_epis       => i_id_epis,
                                                        o_interv_plan   => o_soc_epis_interv,
                                                        o_screen_labels => l_temp_cur,
                                                        o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        CLOSE l_temp_cur;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_soc_epis_interv);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_SOCIAL_INTERV_PLAN_REPORT',
                                                     o_error);
        
    END get_social_interv_plan_report;
    --

    /********************************************************************************************
    * Get social assistence requests data for the given episode to be used in report 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    *
    * @ param o_s_epis                Social assistence requests data
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/30
    **********************************************************************************************/
    FUNCTION get_social_request_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        o_s_epis      OUT pk_types.cursor_type,
        o_s_epis_prof OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        g_error := 'CALL get_social_requests_summary';
        IF NOT get_social_requests_summary(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_episode       => table_number(i_id_epis),
                                           o_requests      => o_s_epis,
                                           o_requests_prof => o_s_epis_prof,
                                           o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_s_epis);
            pk_types.open_my_cursor(o_s_epis_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_SOCIAL_REQUEST_REPORT',
                                                     o_error);
        
    END get_social_request_report;
    --

    /********************************************************************************************
    * Get social followup notes data for the given episode to be used in report. 
    * This data includes the Social situation information that was migrated into this new 
    * funcionality in version 2.6.0.1.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    *
    * @ param o_s_epis                Follow up data
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/30
    **********************************************************************************************/
    FUNCTION get_social_followup_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        o_s_epis      OUT pk_types.cursor_type,
        o_s_epis_prof OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        --follow_up
        IF NOT pk_paramedical_prof_core.get_followup_notes(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => i_id_epis,
                                                           i_mng_followup   => NULL,
                                                           i_show_cancelled => pk_alert_constant.g_yes,
                                                           o_follow_up_prof => o_s_epis_prof,
                                                           o_follow_up      => o_s_epis,
                                                           o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_s_epis);
            pk_types.open_my_cursor(o_s_epis_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_SOCIAL_FOLLOWUP_REPORT',
                                                     o_error);
        
    END get_social_followup_report;
    --

    /********************************************************************************************
    * Get Social report's data for the given episode 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID 
    *
    * @ param o_pat                   Household information
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/30
    **********************************************************************************************/
    FUNCTION get_social_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        --
        o_s_epis      OUT pk_types.cursor_type,
        o_s_epis_prof OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        g_error := 'CALL pk_paramedical_prof_core.get_paramed_report';
        IF NOT pk_paramedical_prof_core.get_paramed_report(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => table_number(i_id_epis),
                                                           i_report         => NULL,
                                                           i_show_cancelled => pk_alert_constant.g_no,
                                                           o_report_prof    => o_s_epis_prof,
                                                           o_report         => o_s_epis,
                                                           o_error          => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_s_epis);
            pk_types.open_my_cursor(o_s_epis_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_SOCIAL_REPORT',
                                                     o_error);
        
    END get_social_report;
    --

    /********************************************************************************************
    * Get the Follow-up requests summary, concatenated as a String (CLOB).
    * The information includes: Diagnosis, Intervention plans, Follow-up notes and Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @ param i_episode               Episode ID (Epis type = Social Worker)
    * @ param o_follow_up_request_summary  Array with all information, where each 
    *                                      position has a diferent type of data.
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/04/21
    **********************************************************************************************/
    FUNCTION get_follow_up_req_sum_str
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        o_follow_up_request_summary OUT table_clob,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_follow_up_request_summary table_clob := table_clob();
        l_summary_temp              CLOB;
        l_summary_index             PLS_INTEGER := 1;
    BEGIN
        pk_alertlog.log_debug('GET_FOLLOW_UP_REQ_SUM_STR - get follow up requests summary as a string!');
        --title
        g_error := 'Get title';
        l_follow_up_request_summary.extend;
        l_follow_up_request_summary(l_summary_index) := pk_message.get_message(i_lang, 'CONSULT_REQUEST_T031') ||
                                                        '<br>';
        l_summary_index := l_summary_index + 1;
        --
    
        --create complete summary:
        g_error := 'Get Diagnosis summary str';
        --1 - Diagnosis
        IF NOT pk_paramedical_prof_core.get_summ_page_diag_str(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_patient       => i_patient,
                                                               i_episode       => i_episode,
                                                               i_opinion_type  => pk_opinion.g_ot_social_worker,
                                                               o_diagnosis_str => l_summary_temp,
                                                               o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF l_summary_temp IS NOT NULL
        THEN
            l_follow_up_request_summary.extend;
            l_follow_up_request_summary(l_summary_index) := l_summary_temp;
            l_summary_index := l_summary_index + 1;
            --
        END IF;
        --
        g_error := 'Get Intervention plan summary str';
        --2 - Intervention plans
        IF NOT pk_paramedical_prof_core.get_interv_plan_summary_str(i_lang                 => i_lang,
                                                                    i_prof                 => i_prof,
                                                                    i_patient              => i_patient,
                                                                    i_episode              => i_episode,
                                                                    i_opinion_type         => pk_opinion.g_ot_social_worker,
                                                                    o_interv_plan_summ_str => l_summary_temp,
                                                                    o_error                => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF l_summary_temp IS NOT NULL
        THEN
            l_follow_up_request_summary.extend;
            l_follow_up_request_summary(l_summary_index) := l_summary_temp;
            l_summary_index := l_summary_index + 1;
        END IF;
    
        g_error := 'Get Follow up notes summary str';
        --3 - Follow-up notes
        IF NOT pk_paramedical_prof_core.get_followup_notes_str(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_episode   => i_episode,
                                                               o_follow_up => l_summary_temp,
                                                               o_error     => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF l_summary_temp IS NOT NULL
        THEN
            l_follow_up_request_summary.extend;
            l_follow_up_request_summary(l_summary_index) := l_summary_temp;
            l_summary_index := l_summary_index + 1;
        END IF;
        --
    
        g_error := 'Get Follow up notes summary str';
        --4 - Reports
        IF NOT pk_paramedical_prof_core.get_paramed_report_str(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_episode      => i_episode,
                                                               i_opinion_type => pk_opinion.g_ot_social_worker,
                                                               o_report       => l_summary_temp,
                                                               o_error        => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF l_summary_temp IS NOT NULL
        THEN
            l_follow_up_request_summary.extend;
            l_follow_up_request_summary(l_summary_index) := l_summary_temp;
            l_summary_index := l_summary_index + 1;
        END IF;
        --
        o_follow_up_request_summary := l_follow_up_request_summary;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_sw_generic_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_FOLLOW_UP_REQ_SUM_STR',
                                                     o_error);
        
    END get_follow_up_req_sum_str;
    --

    /********************************************************************************************
    * Get patient's home characteristics 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat                    Family grid
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_home_2_report
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_history           IN VARCHAR2 DEFAULT 'N',
        i_show_cancel       IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label IN VARCHAR2 DEFAULT 'N',
        i_report            IN VARCHAR2 DEFAULT 'N',
        o_pat_home          OUT pk_types.cursor_type,
        o_pat_home_prof     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        c_rownum_limited   CONSTANT PLS_INTEGER := 1;
        c_rownum_unlimited CONSTANT PLS_INTEGER := 999999;
    
        l_rownum PLS_INTEGER;
    
        l_show_cancelled VARCHAR2(1 CHAR) := '-';
        --
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        pk_alertlog.log_debug('GET_HOME_2 : i_id_pat = ' || i_id_pat);
        --
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T088',
                                                                                          'SOCIAL_T081',
                                                                                          'SOCIAL_T032',
                                                                                          'SOCIAL_T033',
                                                                                          'SOCIAL_T034',
                                                                                          'SOCIAL_T035',
                                                                                          'SOCIAL_T036',
                                                                                          'SOCIAL_T037',
                                                                                          'SOCIAL_T038',
                                                                                          'SOCIAL_T039',
                                                                                          'SOCIAL_T082',
                                                                                          'COMMON_M072',
                                                                                          'COMMON_M073'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        --show home history
        IF i_history = pk_alert_constant.get_no
        THEN
            l_rownum := c_rownum_limited;
        ELSE
            l_rownum := c_rownum_unlimited;
        END IF;
    
        --show cancelled records
        IF i_show_cancel <> pk_alert_constant.get_yes
        THEN
            l_show_cancelled := pk_alert_constant.g_flg_status_c;
        END IF;
    
        --
        g_error := 'GET CURSOR O_PAT_HOME';
        OPEN o_pat_home FOR
            SELECT id,
                   field_header,
                   desc_flg_hab_location,
                   desc_flg_hab_type,
                   desc_flg_owner,
                   desc_flg_conserv,
                   desc_flg_light,
                   desc_flg_water_origin,
                   desc_flg_wc_location,
                   num_rooms,
                   arquitect_barrier,
                   notes,
                   cancel_reason,
                   cancel_notes,
                   field_header_report,
                   label_flg_hab_location,
                   info_flg_hab_location,
                   label_flg_hab_type,
                   info_flg_hab_type,
                   label_flg_owner,
                   info_flg_owner,
                   label_flg_conserv,
                   info_flg_conserv,
                   label_flg_light,
                   info_flg_light,
                   label_flg_water_origin,
                   info_flg_water_origin,
                   label_flg_wc_location,
                   info_flg_wc_location,
                   label_num_rooms,
                   info_num_rooms,
                   label_arquitect_barrier,
                   info_arquitect_barrier,
                   label_notes,
                   info_notes,
                   label_cancel_reason,
                   info_cancel_reason,
                   label_cancel_notes,
                   info_cancel_notes
              FROM (SELECT id id,
                           decode(i_show_header_label,
                                  pk_alert_constant.g_yes,
                                  REPLACE(pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T088')),
                                          pk_paramedical_prof_core.c_colon) || chr(10),
                                  NULL) field_header,
                           --hab_location,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T081'),
                                                                              i_report) ||
                           nvl2(flg_hab_location,
                                pk_sysdomain.get_domain(g_domain_flg_hab_location, flg_hab_location, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_hab_location,
                           --hab_type,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T032'),
                                                                              i_report) ||
                           nvl2(flg_hab_type,
                                pk_sysdomain.get_domain(g_domain_flg_hab_type, flg_hab_type, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_hab_type,
                           --owner,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T033'),
                                                                              i_report) ||
                           nvl2(flg_owner,
                                pk_sysdomain.get_domain(g_domain_flg_owner, flg_owner, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_owner,
                           --conserv,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T034'),
                                                                              i_report) ||
                           nvl2(flg_conserv,
                                pk_sysdomain.get_domain(g_domain_flg_conserv, flg_conserv, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_conserv,
                           --light,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T035'),
                                                                              i_report) ||
                           nvl2(flg_light,
                                pk_sysdomain.get_domain(g_yes_no, flg_light, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_light,
                           --water_origin,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T036'),
                                                                              i_report) ||
                           nvl2(flg_water_origin,
                                pk_sysdomain.get_domain(g_domain_flg_water_origin, flg_water_origin, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_water_origin,
                           --wc_location,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T037'),
                                                                              i_report) ||
                           nvl2(flg_wc_location,
                                pk_sysdomain.get_domain(g_domain_flg_wc_location, flg_wc_location, i_lang),
                                pk_paramedical_prof_core.c_dashes) desc_flg_wc_location,
                           --
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T038'),
                                                                              i_report) ||
                           nvl(to_char(num_rooms), pk_paramedical_prof_core.c_dashes) num_rooms,
                           --arquitect_barrier
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T039'),
                                                                              i_report) ||
                           nvl(arquitect_barrier, pk_paramedical_prof_core.c_dashes) arquitect_barrier,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T082'),
                                                                              i_report) ||
                           nvl(notes, pk_paramedical_prof_core.c_dashes) notes,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('COMMON_M072')) ||
                                  pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, id_cancel),
                                  NULL) cancel_reason,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('COMMON_M073')) ||
                                  pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, id_cancel),
                                  NULL) cancel_notes,
                           flg_status_1,
                           ----------------------------------
                           decode(i_show_header_label,
                                  pk_alert_constant.g_yes,
                                  t_table_message_array('SOCIAL_T088'),
                                  NULL) field_header_report,
                           --hab_location,
                           t_table_message_array('SOCIAL_T081') label_flg_hab_location,
                           pk_sysdomain.get_domain(g_domain_flg_hab_location, flg_hab_location, i_lang) info_flg_hab_location,
                           --hab_type,
                           t_table_message_array('SOCIAL_T032') label_flg_hab_type,
                           pk_sysdomain.get_domain(g_domain_flg_hab_type, flg_hab_type, i_lang) info_flg_hab_type,
                           --owner,
                           t_table_message_array('SOCIAL_T033') label_flg_owner,
                           pk_sysdomain.get_domain(g_domain_flg_owner, flg_owner, i_lang) info_flg_owner,
                           --conserv,
                           t_table_message_array('SOCIAL_T034') label_flg_conserv,
                           pk_sysdomain.get_domain(g_domain_flg_conserv, flg_conserv, i_lang) info_flg_conserv,
                           --light,
                           t_table_message_array('SOCIAL_T035') label_flg_light,
                           pk_sysdomain.get_domain(g_yes_no, flg_light, i_lang) info_flg_light,
                           --water_origin,
                           t_table_message_array('SOCIAL_T036') label_flg_water_origin,
                           pk_sysdomain.get_domain(g_domain_flg_water_origin, flg_water_origin, i_lang) info_flg_water_origin,
                           --wc_location,
                           t_table_message_array('SOCIAL_T037') label_flg_wc_location,
                           pk_sysdomain.get_domain(g_domain_flg_wc_location, flg_wc_location, i_lang) info_flg_wc_location,
                           --
                           t_table_message_array('SOCIAL_T038') label_num_rooms,
                           to_char(num_rooms) info_num_rooms,
                           --arquitect_barrier
                           t_table_message_array('SOCIAL_T039') label_arquitect_barrier,
                           arquitect_barrier info_arquitect_barrier,
                           
                           t_table_message_array('SOCIAL_T082') label_notes,
                           notes info_notes,
                           
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  t_table_message_array('COMMON_M072'),
                                  NULL) label_cancel_reason,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, id_cancel),
                                  NULL) info_cancel_reason,
                           
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  t_table_message_array('COMMON_M073'),
                                  NULL) label_cancel_notes,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, id_cancel),
                                  NULL) info_cancel_notes
                      FROM (SELECT decode(i_history, pk_alert_constant.g_no, p.id_home, p.id_home_hist) id,
                                   pf.name,
                                   p.dt_home_hist dt_registry_tstz,
                                   p.flg_status,
                                   p.num_rooms,
                                   p.flg_wc_location,
                                   p.flg_wc_type,
                                   p.flg_wc_out,
                                   p.flg_water_origin,
                                   p.flg_water_distrib,
                                   p.flg_conserv,
                                   p.flg_owner,
                                   p.flg_hab_type,
                                   p.flg_hab_location,
                                   p.flg_light,
                                   p.arquitect_barrier,
                                   p.notes,
                                   p.flg_status flg_status_1,
                                   p.id_cancel_info_det id_cancel
                              FROM home_hist p, patient pat, pat_family pf
                             WHERE p.id_pat_family = pf.id_pat_family
                               AND pf.id_pat_family(+) = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                             ORDER BY dt_registry_tstz DESC)
                     WHERE rownum <= l_rownum)
            --in the summary the cancelled records are not displayed
             WHERE l_show_cancelled <> flg_status_1;
    
        g_error := 'GET CURSOR O_PAT_HOME_PROF';
        OPEN o_pat_home_prof FOR
            SELECT *
              FROM (SELECT id id,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_home_hist, i_prof) dt,
                           pk_tools.get_prof_description(i_lang, i_prof, id_professional, dt_home_hist, NULL) prof_sign,
                           flg_status,
                           --only in the detail we have status labels
                           decode(i_history, pk_alert_constant.get_no, NULL, desc_status) desc_status,
                           pk_date_utils.date_send_tsz(i_lang, dt_home_hist, i_prof) dt_send,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) prof_name_sign,
                           pk_prof_utils.get_spec_signature(i_lang, i_prof, id_professional, dt_home_hist, NULL) prof_spec_sign
                      FROM (SELECT decode(i_history, pk_alert_constant.g_no, h.id_home, h.id_home_hist) id,
                                   h.dt_home_hist,
                                   h.id_professional,
                                   decode(h.flg_status, NULL, 'A', h.flg_status) flg_status,
                                   pk_sysdomain.get_domain(g_home_hist_flg_status, h.flg_status, i_lang) desc_status
                              FROM home_hist h, patient pat, pat_family pf
                             WHERE h.id_pat_family = pf.id_pat_family
                               AND pf.id_pat_family(+) = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                             ORDER BY dt_home_hist DESC)
                     WHERE rownum <= l_rownum)
            --in the summary the cancelled records are not displayed
             WHERE l_show_cancelled <> flg_status;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_HOME_2',
                                                     o_error);
        
    END get_home_2_report;

    /********************************************************************************************
     * Get patient's household history information.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat_household          Household information
     * @param o_pat_household_prof     Household professionals
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2006/11/06
    **********************************************************************************************/
    FUNCTION get_household_hist_report
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_id_pat_household   IN patient.id_patient%TYPE,
        o_pat_household      OUT pk_types.cursor_type,
        o_pat_household_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_currency_default currency.id_currency%TYPE;
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET_HOUSEHOLD_HIST';
        pk_alertlog.log_debug(g_error || ' BEGIN');
    
        --IF NOT get_household_edit(i_lang             => i_lang,
        --                         i_prof             => i_prof,
        --                        i_id_pat           => i_id_pat,
        --                         i_id_pat_household => i_id_pat_household,
        --                        o_pat_household    => o_pat_household,
        --                        o_error            => o_error)
        --THEN
        --    RAISE g_sw_generic_exception;
        -- END IF;
        g_error               := 'GET CURRENCY DEFAUL - GET_FAM_MONEY';
        l_id_currency_default := get_currency_default(i_prof);
    
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T001',
                                                                                          'SOCIAL_T007',
                                                                                          'SOCIAL_T008',
                                                                                          'SOCIAL_T077',
                                                                                          'SOCIAL_T017',
                                                                                          'SOCIAL_T019',
                                                                                          'SOCIAL_T020',
                                                                                          'SOCIAL_T021',
                                                                                          'SOCIAL_T022',
                                                                                          'SOCIAL_T023',
                                                                                          'SOCIAL_T093',
                                                                                          'SOCIAL_T145'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF (i_id_pat_household = i_id_pat)
        THEN
            g_error := 'GET CURSOR O_PAT_DET 1';
            OPEN o_pat_household FOR
                SELECT pat.id_patient id,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T001')) ||
                       pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, i_episode, NULL) desc_name,
                       --
                       --l_id_currency_default l_id_currency_default,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T007')) ||
                       pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof) desc_date_birth,
                       
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T008')) ||
                       pk_sysdomain.get_domain('PATIENT.GENDER', pat.gender, i_lang) desc_gender,
                       
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T077')) || NULL desc_family_relationship,
                       
                       --'N' flg_edit_info,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T017')) ||
                       pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', psa.marital_status, i_lang) desc_marital_status,
                       
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T019')) ||
                       decode(pj.id_occupation,
                              NULL,
                              pj.occupation_desc,
                              pk_translation.get_translation(i_lang, o.code_occupation)) desc_occupation,
                       --                      
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T020')) ||
                       pk_translation.get_translation(i_lang,
                                                      (SELECT s.code_scholarship
                                                         FROM scholarship s
                                                        WHERE s.id_scholarship = psa.id_scholarship)) desc_scholarship,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T021')) ||
                       nvl2(to_char(net_wage),
                            (to_char(net_wage) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_net_wage, l_id_currency_default))),
                            NULL) desc_wage,
                       --psa.id_currency_net_wage id_unit_measure_wage,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T022')) ||
                       nvl2(to_char(pension),
                            (to_char(pension) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_pension, l_id_currency_default))),
                            NULL) desc_pension,
                       nvl(pension, 0) flg_pension,
                       -- psa.id_currency_pension id_unit_measure_pension,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T023')) ||
                       nvl2(to_char(unemployment_subsidy),
                            (to_char(unemployment_subsidy) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_unemp_sub, l_id_currency_default))),
                            NULL) desc_unemployment,
                       
                       --,psa.id_currency_unemp_sub id_unit_measure_unemployment
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T093')) title_dependency_level,
                       pk_sysdomain.get_domain('PATIENT.FLG_DEPENDENCE_LEVEL', pat.flg_dependence_level, i_lang) desc_dependency_level,
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T145')) ||
                       get_family_doctor(i_lang, pat.id_patient, i_prof) desc_fam_doctor,
                       
                       ------------------------------------------------------------------------
                       t_table_message_array('SOCIAL_T001') label_name,
                       pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, i_episode, NULL) info_name,
                       t_table_message_array('SOCIAL_T007') label_date_birth,
                       pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof) info_date_birth,
                       t_table_message_array('SOCIAL_T008') label_gender,
                       pk_sysdomain.get_domain('PATIENT.GENDER', pat.gender, i_lang) info_gender,
                       t_table_message_array('SOCIAL_T077') label_family_relationship,
                       NULL info_family_relationship,
                       t_table_message_array('SOCIAL_T017') label_marital_status,
                       pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', psa.marital_status, i_lang) info_marital_status,
                       t_table_message_array('SOCIAL_T019') label_occupation,
                       decode(pj.id_occupation,
                              NULL,
                              pj.occupation_desc,
                              pk_translation.get_translation(i_lang, o.code_occupation)) info_occupation,
                       t_table_message_array('SOCIAL_T020') label_scholarship,
                       pk_translation.get_translation(i_lang,
                                                      (SELECT s.code_scholarship
                                                         FROM scholarship s
                                                        WHERE s.id_scholarship = psa.id_scholarship)) info_scholarship,
                       t_table_message_array('SOCIAL_T021') label_wage,
                       nvl2(to_char(net_wage),
                            (to_char(net_wage) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_net_wage, l_id_currency_default))),
                            NULL) info_wage,
                       t_table_message_array('SOCIAL_T022') label_pension,
                       nvl2(to_char(pension),
                            (to_char(pension) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_pension, l_id_currency_default))),
                            NULL) info_pension,
                       t_table_message_array('SOCIAL_T023') label_unemployment,
                       nvl2(to_char(unemployment_subsidy),
                            (to_char(unemployment_subsidy) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_unemp_sub, l_id_currency_default))),
                            NULL) info_unemployment,
                       t_table_message_array('SOCIAL_T093') label_dependency_level,
                       pk_sysdomain.get_domain('PATIENT.FLG_DEPENDENCE_LEVEL', pat.flg_dependence_level, i_lang) info_dependency_level,
                       t_table_message_array('SOCIAL_T145') label_fam_doctor,
                       get_family_doctor(i_lang, pat.id_patient, i_prof) info_fam_doctor
                  FROM patient pat,
                       pat_soc_attributes psa,
                       occupation o,
                       (SELECT *
                          FROM pat_job
                         WHERE dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                                    FROM pat_job p1
                                                   WHERE p1.id_patient = i_id_pat)) pj
                 WHERE pat.id_patient = i_id_pat
                   AND pj.id_patient(+) = psa.id_patient
                   AND o.id_occupation(+) = pj.id_occupation
                   AND pat.id_patient = psa.id_patient(+);
        ELSE
            pk_alertlog.log_debug('Edit a patient that belongs to the household!');
            g_error := 'GET CURSOR O_PAT_DET 2';
            OPEN o_pat_household FOR
                SELECT pat.id_patient id,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T001')) ||
                       pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, i_episode, NULL) desc_name,
                       
                       --
                       --l_id_currency_default l_id_currency_default,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T007')) ||
                       pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof) desc_date_birth,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T008')) ||
                       pk_sysdomain.get_domain('PATIENT.GENDER', pat.gender, i_lang) desc_gender,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T077')) ||
                       pk_translation.get_translation(i_lang, fr.code_family_relationship) desc_family_relationship,
                       --'N' flg_edit_info,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T017')) ||
                       pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', psa.marital_status, i_lang) desc_marital_status,
                       
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T019')) ||
                       decode(pj.id_occupation,
                              NULL,
                              pj.occupation_desc,
                              pk_translation.get_translation(i_lang, o.code_occupation)) desc_occupation,
                       
                       --                      
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T020')) ||
                       pk_translation.get_translation(i_lang,
                                                      (SELECT s.code_scholarship
                                                         FROM scholarship s
                                                        WHERE s.id_scholarship = psa.id_scholarship)) desc_scholarship,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T021')) ||
                       nvl2(to_char(net_wage),
                            (to_char(net_wage) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_net_wage, l_id_currency_default))),
                            NULL) desc_wage,
                       --psa.id_currency_net_wage id_unit_measure_wage,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T022')) ||
                       nvl2(to_char(pension),
                            (to_char(pension) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_pension, l_id_currency_default))),
                            NULL) desc_pension,
                       
                       --psa.id_currency_pension id_unit_measure_pension,
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T023')) ||
                       nvl2(to_char(unemployment_subsidy),
                            (to_char(unemployment_subsidy) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_unemp_sub, l_id_currency_default))),
                            NULL) desc_unemployment,
                       
                       --psa.id_currency_unemp_sub id_unit_measure_unemployment
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T093')) ||
                       pk_sysdomain.get_domain('PATIENT.FLG_DEPENDENCE_LEVEL', pat.flg_dependence_level, i_lang) desc_dependency_level,
                       
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T145')) ||
                       get_family_doctor(i_lang, pat.id_patient, i_prof) desc_fam_doctor,
                       -----------------------------------------------------
                       t_table_message_array('SOCIAL_T001') label_name,
                       pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, i_episode, NULL) info_name,
                       t_table_message_array('SOCIAL_T007') label_date_birth,
                       pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof) info_date_birth,
                       t_table_message_array('SOCIAL_T008') label_gender,
                       pk_sysdomain.get_domain('PATIENT.GENDER', pat.gender, i_lang) info_gender,
                       t_table_message_array('SOCIAL_T077') label_family_relationship,
                       pk_translation.get_translation(i_lang, fr.code_family_relationship) info_family_relationship,
                       t_table_message_array('SOCIAL_T017') label_marital_status,
                       pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', psa.marital_status, i_lang) info_marital_status,
                       t_table_message_array('SOCIAL_T019') label_occupation,
                       decode(pj.id_occupation,
                              NULL,
                              pj.occupation_desc,
                              pk_translation.get_translation(i_lang, o.code_occupation)) info_occupation,
                       t_table_message_array('SOCIAL_T020') label_scholarship,
                       pk_translation.get_translation(i_lang,
                                                      (SELECT s.code_scholarship
                                                         FROM scholarship s
                                                        WHERE s.id_scholarship = psa.id_scholarship)) info_scholarship,
                       t_table_message_array('SOCIAL_T021') label_wage,
                       nvl2(to_char(net_wage),
                            (to_char(net_wage) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_net_wage, l_id_currency_default))),
                            NULL) info_wage,
                       t_table_message_array('SOCIAL_T022') label_pension,
                       nvl2(to_char(pension),
                            (to_char(pension) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_pension, l_id_currency_default))),
                            NULL) info_pension,
                       t_table_message_array('SOCIAL_T023') label_unemployment,
                       nvl2(to_char(unemployment_subsidy),
                            (to_char(unemployment_subsidy) || ' ' ||
                            (SELECT currency_desc
                                FROM currency
                               WHERE id_currency = nvl(psa.id_currency_unemp_sub, l_id_currency_default))),
                            NULL) info_unemployment,
                       t_table_message_array('SOCIAL_T093') label_dependency_level,
                       pk_sysdomain.get_domain('PATIENT.FLG_DEPENDENCE_LEVEL', pat.flg_dependence_level, i_lang) info_dependency_level,
                       t_table_message_array('SOCIAL_T145') label_fam_doctor,
                       get_family_doctor(i_lang, pat.id_patient, i_prof) info_fam_doctor
                  FROM patient pat,
                       pat_soc_attributes psa,
                       family_relationship fr,
                       pat_family_member pfm,
                       occupation o,
                       (SELECT *
                          FROM pat_job
                         WHERE dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                                    FROM pat_job p1
                                                   WHERE p1.id_patient = i_id_pat_household)) pj
                 WHERE pat.id_patient = i_id_pat_household
                   AND pfm.id_pat_related(+) = pat.id_patient
                   AND pfm.id_family_relationship = fr.id_family_relationship
                   AND pj.id_patient(+) = psa.id_patient
                   AND o.id_occupation(+) = pj.id_occupation
                   AND pat.id_patient = psa.id_patient(+);
        END IF;
    
        g_error := 'GET CURSOR O_PAT_HOUSEHOLD_PROF';
        OPEN o_pat_household_prof FOR
            SELECT pat.id_patient id,
                   NULL dt,
                   NULL prof_sign,
                   decode(pat.flg_status, g_flg_inactive, pk_alert_constant.g_flg_status_c, pat.flg_status) flg_status,
                   NULL desc_status
              FROM patient pat
             WHERE pat.id_patient = i_id_pat;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_household);
            pk_types.open_my_cursor(o_pat_household_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_HOUSEHOLD_HIST',
                                                     o_error);
        
    END get_household_hist_report;

    /********************************************************************************************
     * Get patient's social class and its criteria values
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_pat                 Patient ID 
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_pat_g_crit             Info
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Orlando Antunes
     * @version                         0.1
     * @since                           2010/01/29
    **********************************************************************************************/
    FUNCTION get_social_class_report
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_show_cancel       IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label IN VARCHAR2 DEFAULT 'N',
        o_social_class      OUT pk_types.cursor_type,
        o_prof_social_class OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --t_cur_graffar_crit IS TABLE OF VARCHAR2;
        l_t_cur_graffar_crit       table_varchar := table_varchar();
        l_t_cur_graffar_crit_label table_varchar := table_varchar();
        l_t_cur_graffar_crit_info  table_varchar := table_varchar();
        --
        l_pat_family pat_family.id_pat_family%TYPE;
        --
        l_social_class_info PLS_INTEGER;
        --
        l_show_cancelled VARCHAR2(1 CHAR) := '-';
        --
        CURSOR c_social_class_info IS
            SELECT COUNT(*)
              FROM pat_graffar_crit pgc
             WHERE pgc.id_patient = i_id_pat;
    
    BEGIN
        --the patient already has social class information?
        pk_alertlog.log_debug('GET_SOCIAL_CLASS - The patient already have information for social class?');
        --
        g_error := 'Get patient family!';
        --get pat_family ID
        SELECT id_pat_family
          INTO l_pat_family
          FROM patient p
         WHERE p.id_patient = i_id_pat;
        --
        OPEN c_social_class_info;
        FETCH c_social_class_info
            INTO l_social_class_info;
        g_found := c_social_class_info%NOTFOUND;
        CLOSE c_social_class_info;
    
        ---show cancelled records
        IF i_show_cancel <> pk_alert_constant.get_yes
        THEN
            l_show_cancelled := 'C';
        END IF;
    
        -- 
        IF (g_found OR l_social_class_info = 0)
        THEN
            pk_types.open_my_cursor(o_social_class);
            pk_types.open_my_cursor(o_prof_social_class);
        ELSE
        
            pk_alertlog.log_debug('GET_SOCIAL_CLASS - Information found');
            SELECT pk_paramedical_prof_core.format_str_header_w_colon(titulo) || valor desc_valor,
                   titulo label_valor,
                   valor info_valor
              BULK COLLECT
              INTO l_t_cur_graffar_crit, l_t_cur_graffar_crit_label, l_t_cur_graffar_crit_info
              FROM (SELECT titulo, id_graf_crit, valor, ordena
                      FROM (SELECT *
                              FROM (SELECT pk_message.get_message(i_lang, 'SOCIAL_T062') titulo,
                                           0 id_graf_crit,
                                           nvl2(sc.code_social_class,
                                                pk_translation.get_translation(i_lang, sc.code_social_class),
                                                pk_paramedical_prof_core.c_dashes) valor,
                                           1 ordena
                                      FROM pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                                     WHERE pf.id_pat_family = (SELECT pat.id_pat_family
                                                                 FROM patient pat
                                                                WHERE pat.id_patient = i_id_pat)
                                       AND pfsch.id_pat_family(+) = pf.id_pat_family
                                       AND pfsch.id_social_class = sc.id_social_class(+)
                                     ORDER BY pfsch.dt_registry_tstz DESC)
                             WHERE rownum <= 1
                            UNION ALL
                            SELECT *
                              FROM (SELECT pk_translation.get_translation(i_lang, gc.code_graffar_criteria) titulo,
                                           gc.id_graffar_criteria id_graf_crit,
                                           nvl2(gcv.val,
                                                to_char(gcv.val) || '-' ||
                                                pk_translation.get_translation(i_lang, gcv.code_graffar_crit_value),
                                                pk_paramedical_prof_core.c_dashes) valor,
                                           gc.rank ordena
                                      FROM pat_graffar_crit       pgc,
                                           graffar_crit_value     gcv,
                                           graffar_criteria       gc,
                                           pat_fam_soc_class_hist pfsch
                                     WHERE pgc.id_graffar_crit_value(+) = gcv.id_graffar_crit_value
                                       AND gc.id_graffar_criteria = gcv.id_graffar_criteria
                                       AND pgc.id_patient = i_id_pat
                                       AND pfsch.id_pat_fam_soc_class_hist(+) = pgc.id_pat_fam_soc_class_hist
                                     ORDER BY pfsch.dt_registry_tstz DESC)
                             WHERE rownum <= 5
                            --the social class must exist
                            --AND (pgc.flg_status IS NULL OR pgc.flg_status <> pk_alert_constant.g_flg_status_c)
                            UNION ALL
                            SELECT *
                              FROM (SELECT pk_message.get_message(i_lang, 'SOCIAL_T082') titulo,
                                           99 id_graf_crit,
                                           nvl(pfsch.notes, pk_paramedical_prof_core.c_dashes) valor,
                                           99 ordena
                                      FROM pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                                     WHERE pf.id_pat_family = (SELECT pat.id_pat_family
                                                                 FROM patient pat
                                                                WHERE pat.id_patient = i_id_pat)
                                       AND pfsch.id_pat_family(+) = pf.id_pat_family
                                       AND pfsch.id_social_class = sc.id_social_class(+)
                                     ORDER BY pfsch.dt_registry_tstz DESC)
                             WHERE rownum <= 1
                            UNION ALL
                            SELECT *
                              FROM (SELECT decode(pfsch.flg_status,
                                                  pk_alert_constant.g_flg_status_c,
                                                  pk_message.get_message(i_lang, 'COMMON_M072'),
                                                  NULL) titulo,
                                           999 id_graf_crit,
                                           decode(pfsch.flg_status,
                                                  pk_alert_constant.g_flg_status_c,
                                                  pk_paramedical_prof_core.get_cancel_reason_desc(i_lang,
                                                                                                  i_prof,
                                                                                                  pfsch.id_cancel_info_det),
                                                  NULL) valor,
                                           999 ordena
                                      FROM pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                                     WHERE pf.id_pat_family = (SELECT pat.id_pat_family
                                                                 FROM patient pat
                                                                WHERE pat.id_patient = i_id_pat)
                                       AND pfsch.id_pat_family(+) = pf.id_pat_family
                                       AND pfsch.id_social_class = sc.id_social_class(+)
                                     ORDER BY pfsch.dt_registry_tstz DESC)
                             WHERE rownum <= 1
                            UNION ALL
                            SELECT *
                              FROM (SELECT decode(pfsch.flg_status,
                                                  pk_alert_constant.g_flg_status_c,
                                                  pk_message.get_message(i_lang, 'COMMON_M073'),
                                                  NULL) titulo,
                                           9999 id_graf_crit,
                                           decode(pfsch.flg_status,
                                                  pk_alert_constant.g_flg_status_c,
                                                  pk_paramedical_prof_core.get_notes_desc(i_lang,
                                                                                          i_prof,
                                                                                          pfsch.id_cancel_info_det),
                                                  NULL) valor,
                                           9999 ordena
                                      FROM pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                                     WHERE pf.id_pat_family = (SELECT pat.id_pat_family
                                                                 FROM patient pat
                                                                WHERE pat.id_patient = i_id_pat)
                                       AND pfsch.id_pat_family(+) = pf.id_pat_family
                                       AND pfsch.id_social_class = sc.id_social_class(+)
                                     ORDER BY pfsch.dt_registry_tstz DESC)
                             WHERE rownum <= 1)
                     ORDER BY 4);
        
            g_error := 'GET CURSOR O_SOCIAL_CLASS';
            OPEN o_social_class FOR
                SELECT l_pat_family id,
                       decode(i_show_header_label,
                              pk_alert_constant.g_yes,
                              REPLACE(pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                                'SOCIAL_T062')),
                                      pk_paramedical_prof_core.c_colon) || chr(10),
                              NULL) field_header,
                       l_t_cur_graffar_crit(1) || chr(10) desc_social_class,
                       l_t_cur_graffar_crit(2) desc_social_ocupation,
                       l_t_cur_graffar_crit(3) desc_education_level,
                       l_t_cur_graffar_crit(4) desc_income,
                       l_t_cur_graffar_crit(5) desc_house,
                       l_t_cur_graffar_crit(6) desc_house_location,
                       l_t_cur_graffar_crit(7) desc_notes,
                       l_t_cur_graffar_crit(8) cancel_reason,
                       l_t_cur_graffar_crit(9) cancel_notes,
                       decode(i_show_header_label,
                              pk_alert_constant.g_yes,
                              pk_message.get_message(i_lang, 'SOCIAL_T062'),
                              NULL) field_header_report,
                       l_t_cur_graffar_crit_label(1) label_social_class,
                       l_t_cur_graffar_crit_info(1) info_social_class,
                       l_t_cur_graffar_crit_label(2) label_social_ocupation,
                       l_t_cur_graffar_crit_info(2) info_social_ocupation,
                       l_t_cur_graffar_crit_label(3) label_education_level,
                       l_t_cur_graffar_crit_info(3) info_education_level,
                       l_t_cur_graffar_crit_label(4) label_income,
                       l_t_cur_graffar_crit_info(4) info_income,
                       l_t_cur_graffar_crit_label(5) label_house,
                       l_t_cur_graffar_crit_info(5) info_house,
                       l_t_cur_graffar_crit_label(6) label_house_location,
                       l_t_cur_graffar_crit_info(6) info_house_location,
                       l_t_cur_graffar_crit_label(7) label_notes,
                       l_t_cur_graffar_crit_info(7) info_notes,
                       l_t_cur_graffar_crit_label(8) label_cancel_reason,
                       l_t_cur_graffar_crit_info(8) info_cancel_reason,
                       l_t_cur_graffar_crit_label(9) label_cancel_notes,
                       l_t_cur_graffar_crit_info(9) info_cancel_notes
                  FROM dual;
        
            g_error := 'GET CURSOR O_PAT_PROF_SOCIAL_CLASS';
            OPEN o_prof_social_class FOR
                SELECT *
                  FROM (SELECT *
                          FROM (SELECT pf.id_pat_family id,
                                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, pfsch.dt_registry_tstz, i_prof) dt,
                                       pk_tools.get_prof_description(i_lang,
                                                                     i_prof,
                                                                     pfsch.id_professional,
                                                                     pfsch.dt_registry_tstz,
                                                                     NULL) prof_sign,
                                       pfsch.flg_status flg_status,
                                       pfsch.dt_registry_tstz dt_registry_tstz,
                                       pk_date_utils.date_send_tsz(i_lang, pfsch.dt_registry_tstz, i_prof) dt_send,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, pfsch.id_professional) prof_name_sign,
                                       pk_prof_utils.get_spec_signature(i_lang,
                                                                        i_prof,
                                                                        pfsch.id_professional,
                                                                        pfsch.dt_registry_tstz,
                                                                        NULL) prof_spec_sign
                                  FROM patient pat, pat_family pf, pat_fam_soc_class_hist pfsch
                                 WHERE pat.id_pat_family = pf.id_pat_family
                                   AND pat.id_patient = i_id_pat
                                   AND pf.id_pat_family = pfsch.id_pat_family
                                 ORDER BY dt_registry_tstz DESC NULLS LAST)
                         WHERE rownum <= 1)
                --in the summary the cancelled records are not displayed
                 WHERE l_show_cancelled <> flg_status;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_social_class);
            pk_types.open_my_cursor(o_prof_social_class);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package_name,
                                                     'GET_SOCIAL_CLASS',
                                                     o_error);
        
    END get_social_class_report;

    /********************************************************************************************
    * Get patient's household financial information
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat_financial          Financial information cursor
    * @param o_pat_financial_prof     Professional that inputs the financial information        
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/04
    **********************************************************************************************/
    FUNCTION get_household_financial_report
    (
        i_lang               IN language.id_language%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_prof               IN profissional,
        i_show_cancel        IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label  IN VARCHAR2 DEFAULT 'N',
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_currency_default currency.id_currency%TYPE;
    
        v_total_members PLS_INTEGER;
        v_tot_pat_f_mem NUMBER;
        --
        l_show_cancelled VARCHAR2(1 CHAR) := '-';
        --
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET LABELS';
    
        --show cancelled records
        IF i_show_cancel <> pk_alert_constant.get_yes
        THEN
            l_show_cancelled := 'C';
        END IF;
    
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T024',
                                                                                          'SOCIAL_T025',
                                                                                          'SOCIAL_T026',
                                                                                          'SOCIAL_T027',
                                                                                          'SOCIAL_T028',
                                                                                          'SOCIAL_T029',
                                                                                          'SOCIAL_T030',
                                                                                          'SOCIAL_T031',
                                                                                          'SOCIAL_T082'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error               := 'GET CURRENCY DEFAUL - GET_FAM_MONEY';
        l_id_currency_default := get_currency_default(i_prof);
    
        v_total_members := get_total_family_members(i_id_pat);
    
        v_tot_pat_f_mem := get_total_family_money(i_id_pat, i_prof);
    
        g_error := 'GET CURSOR O_PAT';
        OPEN o_pat_financial FOR
            SELECT id,
                   field_header,
                   desc_allowance_family,
                   desc_allowance_complementary,
                   desc_other_income,
                   desc_allowance,
                   desc_total_income,
                   desc_total_expenses,
                   desc_n_people,
                   desc_income_per_capita,
                   desc_notes,
                   cancel_reason,
                   cancel_notes,
                   field_header_report,
                   label_allowance_family,
                   info_allowance_family,
                   label_allowance_complementary,
                   info_allowance_complementary,
                   label_other_income,
                   info_other_income,
                   label_allowance,
                   info_allowance,
                   label_total_income,
                   info_total_income,
                   label_total_expenses,
                   info_total_expenses,
                   label_n_people,
                   info_n_people,
                   label_income_per_capita,
                   info_income_per_capita,
                   label_notes,
                   info_notes,
                   label_cancel_reason,
                   info_cancel_reason,
                   label_cancel_notes,
                   info_cancel_notes
              FROM (SELECT id_family_monetary id,
                           decode(i_show_header_label,
                                  pk_alert_constant.g_yes,
                                  REPLACE(pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                                    'SOCIAL_T089')),
                                          pk_paramedical_prof_core.c_colon) || chr(10),
                                  NULL) field_header,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T024')) ||
                           nvl2(to_char(allowance_family),
                                allowance_family || ' ' || allow_family_curr_brief_desc,
                                pk_paramedical_prof_core.c_dashes) desc_allowance_family,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T025')) ||
                           nvl2(to_char(allowance_complementary),
                                allowance_complementary || ' ' || allow_comp_curr_brief_desc,
                                pk_paramedical_prof_core.c_dashes) desc_allowance_complementary,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T026')) ||
                           nvl2(to_char(other), other || ' ' || other_curr_brief_desc, pk_paramedical_prof_core.c_dashes) desc_other_income,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T027')) ||
                           nvl2(to_char(subsidy),
                                subsidy || ' ' || subsidy_curr_brief_desc,
                                pk_paramedical_prof_core.c_dashes) desc_allowance,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T029')) ||
                           nvl2(to_char(tot_pat_f_mem),
                                tot_sit_fin || ' ' || tot_sit_fin_curr_brief_desc,
                                pk_paramedical_prof_core.c_dashes) desc_total_income,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T028')) ||
                           nvl2(to_char(fixed_expenses),
                                fixed_expenses || ' ' || fixed_exp_curr_brief_desc,
                                pk_paramedical_prof_core.c_dashes) desc_total_expenses,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T030')) ||
                           nvl(to_char(tot_person), pk_paramedical_prof_core.c_dashes) desc_n_people,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T031')) ||
                           nvl2(to_char(rend_capita),
                                rend_capita || ' ' || rend_capita_curr_brief_desc,
                                pk_paramedical_prof_core.c_dashes) desc_income_per_capita,
                           pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T082')) ||
                           nvl(notes, pk_paramedical_prof_core.c_dashes) desc_notes,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                            'COMMON_M072')) ||
                                  pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, id_cancel),
                                  NULL) cancel_reason,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                            'COMMON_M073')) ||
                                  pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, id_cancel),
                                  NULL) cancel_notes,
                           flg_status_1,
                           ----------------------------
                           decode(i_show_header_label,
                                  pk_alert_constant.g_yes,
                                  pk_message.get_message(i_lang, 'SOCIAL_T089'),
                                  NULL) field_header_report,
                           t_table_message_array('SOCIAL_T024') label_allowance_family,
                           nvl2(to_char(allowance_family), allowance_family || ' ' || allow_family_curr_brief_desc, NULL) info_allowance_family,
                           t_table_message_array('SOCIAL_T025') label_allowance_complementary,
                           nvl2(to_char(allowance_complementary),
                                allowance_complementary || ' ' || allow_comp_curr_brief_desc,
                                NULL) info_allowance_complementary,
                           t_table_message_array('SOCIAL_T026') label_other_income,
                           nvl2(to_char(other), other || ' ' || other_curr_brief_desc, NULL) info_other_income,
                           t_table_message_array('SOCIAL_T027') label_allowance,
                           nvl2(to_char(subsidy), subsidy || ' ' || subsidy_curr_brief_desc, NULL) info_allowance,
                           t_table_message_array('SOCIAL_T029') label_total_income,
                           nvl2(to_char(tot_pat_f_mem), tot_sit_fin || ' ' || tot_sit_fin_curr_brief_desc, NULL) info_total_income,
                           t_table_message_array('SOCIAL_T028') label_total_expenses,
                           nvl2(to_char(fixed_expenses), fixed_expenses || ' ' || fixed_exp_curr_brief_desc, NULL) info_total_expenses,
                           t_table_message_array('SOCIAL_T030') label_n_people,
                           to_char(tot_person) info_n_people,
                           t_table_message_array('SOCIAL_T031') label_income_per_capita,
                           nvl2(to_char(rend_capita), rend_capita || ' ' || rend_capita_curr_brief_desc, NULL) info_income_per_capita,
                           t_table_message_array('SOCIAL_T082') label_notes,
                           notes info_notes,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_message.get_message(i_lang, 'COMMON_M072'),
                                  NULL) label_cancel_reason,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, id_cancel),
                                  NULL) info_cancel_reason,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_message.get_message(i_lang, 'COMMON_M073'),
                                  NULL) label_cancel_notes,
                           decode(flg_status_1,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, id_cancel),
                                  NULL) info_cancel_notes
                      FROM (SELECT p.id_pat_family,
                                   p.id_family_monetary,
                                   nvl(p.allowance_family, 0) AS allowance_family,
                                   p.id_currency_allow_family,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_allow_family, l_id_currency_default)) AS allow_family_curr_brief_desc,
                                   --  
                                   nvl(p.allowance_complementary, 0) AS allowance_complementary,
                                   p.id_currency_allow_comp,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_allow_comp, l_id_currency_default)) AS allow_comp_curr_brief_desc,
                                   -- 
                                   nvl(p.other, 0) AS other,
                                   p.id_currency_other,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_other, l_id_currency_default)) AS other_curr_brief_desc,
                                   --
                                   nvl(p.subsidy, 0) AS subsidy,
                                   p.id_currency_subsidy,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_subsidy, l_id_currency_default)) AS subsidy_curr_brief_desc,
                                   --
                                   nvl(p.fixed_expenses, 0) AS fixed_expenses,
                                   p.id_currency_fixed_exp,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_fixed_exp, l_id_currency_default)) AS fixed_exp_curr_brief_desc,
                                   --
                                   p.notes,
                                   v_total_members tot_person, -- total de elementos do agregado familiar
                                   v_tot_pat_f_mem tot_pat_f_mem, -- valor total dos vencimentos dos elementos do agregado
                                   ((v_tot_pat_f_mem + nvl(allowance_family, 0) + nvl(allowance_complementary, 0) +
                                   nvl(subsidy, 0) + nvl(other, 0)) /* - nvl(fixed_expenses, 0)*/
                                   ) tot_sit_fin,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_allow_family, l_id_currency_default)) AS tot_sit_fin_curr_brief_desc,
                                   round((((v_tot_pat_f_mem + nvl(allowance_family, 0) + nvl(allowance_complementary, 0) +
                                         nvl(subsidy, 0) + nvl(other, 0)) - (nvl(fixed_expenses, 0))) / v_total_members),
                                         2) rend_capita,
                                   (SELECT currency_desc
                                      FROM currency
                                     WHERE id_currency = nvl(p.id_currency_allow_family, l_id_currency_default)) AS rend_capita_curr_brief_desc,
                                   p.flg_status flg_status_1,
                                   p.id_cancel_info_det id_cancel
                              FROM family_monetary p, patient pat, pat_family pf
                             WHERE p.id_pat_family /*(+)*/
                                   = pf.id_pat_family
                               AND pf.id_pat_family = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                            --AND pf.id_institution = i_prof.institution
                             ORDER BY dt_registry_tstz DESC)
                     WHERE rownum <= 1)
            --in the summary the cancelled records are not displayed
             WHERE l_show_cancelled <> flg_status_1;
    
        g_error := 'GET CURSOR O_PAT_PROF_SOCIAL_CLASS';
        OPEN o_pat_financial_prof FOR
            SELECT *
              FROM (SELECT *
                      FROM (SELECT p.id_family_monetary id,
                                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, p.dt_registry_tstz, i_prof) dt,
                                   --prof.nick_name 
                                   --pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                                   --pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) || ',' ||
                                   --(SELECT i.abbreviation
                                   --   FROM institution i
                                   --  WHERE i.id_institution = i_prof.institution) desc_speciality,
                                   pk_tools.get_prof_description(i_lang,
                                                                 i_prof,
                                                                 p.id_professional,
                                                                 p.dt_registry_tstz,
                                                                 NULL) prof_sign,
                                   p.dt_registry_tstz,
                                   p.flg_status flg_status,
                                   pk_date_utils.date_send_tsz(i_lang, p.dt_registry_tstz, i_prof) dt_send,
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name_sign,
                                   pk_prof_utils.get_spec_signature(i_lang,
                                                                    i_prof,
                                                                    p.id_professional,
                                                                    p.dt_registry_tstz,
                                                                    NULL) prof_spec_sign
                            
                              FROM family_monetary p, patient pat, pat_family pf
                             WHERE p.id_pat_family /*(+) */
                                   = pf.id_pat_family
                               AND pf.id_pat_family = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                            UNION ALL
                            SELECT p.id_family_monetary id,
                                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, p.dt_registry_tstz, i_prof) dt,
                                   --prof.nick_name 
                                   --pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                                   --pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) || ',' ||
                                   --(SELECT i.abbreviation
                                   --   FROM institution i
                                   --  WHERE i.id_institution = i_prof.institution) desc_speciality,
                                   pk_tools.get_prof_description(i_lang,
                                                                 i_prof,
                                                                 p.id_professional,
                                                                 p.dt_registry_tstz,
                                                                 NULL) prof_sign,
                                   p.dt_registry_tstz,
                                   p.flg_status flg_status,
                                   pk_date_utils.date_send_tsz(i_lang, p.dt_registry_tstz, i_prof) dt_send,
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name_sign,
                                   pk_prof_utils.get_spec_signature(i_lang,
                                                                    i_prof,
                                                                    p.id_professional,
                                                                    p.dt_registry_tstz,
                                                                    NULL) prof_spec_sign
                            
                              FROM family_monetary p, patient pat, pat_family pf
                             WHERE p.id_pat_family /*(+) */
                                   = pf.id_pat_family
                               AND pf.id_pat_family = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                             ORDER BY dt_registry_tstz DESC)
                     WHERE rownum <= 1)
            --in the summary the cancelled records are not displayed
             WHERE l_show_cancelled <> flg_status;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_financial);
            pk_types.open_my_cursor(o_pat_financial_prof);
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOUSEHOLD_FINANCIAL',
                                                     o_error);
        
    END get_household_financial_report;

    /********************************************************************************************
    * Get patient's household financial information
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat_financial          Financial information cursor
    * @param o_pat_financial_prof     Professional that inputs the financial information        
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/04
    **********************************************************************************************/
    FUNCTION get_household_fin_hist_report
    (
        i_lang               IN language.id_language%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_prof               IN profissional,
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_currency_default currency.id_currency%TYPE;
    
        v_total_members PLS_INTEGER;
        v_tot_pat_f_mem PLS_INTEGER;
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        pk_alertlog.log_debug('GET_HOUSEHOLD_FINANCIAL_HIST: i_id_pat = ' || i_id_pat);
    
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('SOCIAL_T024',
                                                                                          'SOCIAL_T025',
                                                                                          'SOCIAL_T026',
                                                                                          'SOCIAL_T027',
                                                                                          'SOCIAL_T028',
                                                                                          'SOCIAL_T029',
                                                                                          'SOCIAL_T030',
                                                                                          'SOCIAL_T031',
                                                                                          'SOCIAL_T082'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error               := 'GET CURRENCY DEFAUL - GET_FAM_MONEY';
        l_id_currency_default := get_currency_default(i_prof);
    
        v_total_members := get_total_family_members(i_id_pat);
    
        v_tot_pat_f_mem := get_total_family_money(i_id_pat, i_prof);
    
        g_error := 'GET CURSOR O_PAT';
        OPEN o_pat_financial FOR
            SELECT id_family_monetary id,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T024')) ||
                   allowance_family || ' ' || allow_family_curr_brief_desc desc_allowance_family,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T025')) ||
                   allowance_complementary || ' ' || allow_comp_curr_brief_desc desc_allowance_complementary,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T026')) || other || ' ' ||
                   other_curr_brief_desc desc_other_income,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T027')) || subsidy || ' ' ||
                   subsidy_curr_brief_desc desc_allowance,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T029')) ||
                   tot_sit_fin || ' ' || tot_sit_fin_curr_brief_desc desc_total_income,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T028')) ||
                   fixed_expenses || ' ' || fixed_exp_curr_brief_desc desc_total_expenses,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T030')) ||
                   tot_person desc_n_people,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T031')) ||
                   rend_capita || ' ' || rend_capita_curr_brief_desc desc_income_per_capita,
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SOCIAL_T082')) || notes desc_notes,
                   decode(flg_status_1,
                          pk_alert_constant.g_flg_status_c,
                          pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                    'COMMON_M072')) ||
                          pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, id_cancel),
                          NULL) cancel_reason,
                   decode(flg_status_1,
                          pk_alert_constant.g_flg_status_c,
                          pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                    'COMMON_M073')) ||
                          pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, id_cancel),
                          NULL) cancel_notes,
                   -----------------------
                   t_table_message_array('SOCIAL_T024') label_allowance_family,
                   allowance_family || ' ' || allow_family_curr_brief_desc info_allowance_family,
                   t_table_message_array('SOCIAL_T025') label_allowance_complementary,
                   allowance_complementary || ' ' || allow_comp_curr_brief_desc info_allowance_complementary,
                   t_table_message_array('SOCIAL_T026') label_other_income,
                   other || ' ' || other_curr_brief_desc info_other_income,
                   t_table_message_array('SOCIAL_T027') label_allowance,
                   subsidy || ' ' || subsidy_curr_brief_desc info_allowance,
                   t_table_message_array('SOCIAL_T029') label_total_income,
                   tot_sit_fin || ' ' || tot_sit_fin_curr_brief_desc info_total_income,
                   t_table_message_array('SOCIAL_T028') label_total_expenses,
                   fixed_expenses || ' ' || fixed_exp_curr_brief_desc info_total_expenses,
                   t_table_message_array('SOCIAL_T030') label_n_people,
                   tot_person info_n_people,
                   t_table_message_array('SOCIAL_T031') label_income_per_capita,
                   rend_capita || ' ' || rend_capita_curr_brief_desc info_income_per_capita,
                   t_table_message_array('SOCIAL_T082') label_notes,
                   notes info_notes,
                   decode(flg_status_1,
                          pk_alert_constant.g_flg_status_c,
                          pk_message.get_message(i_lang, 'COMMON_M072'),
                          NULL) label_cancel_reason,
                   decode(flg_status_1,
                          pk_alert_constant.g_flg_status_c,
                          pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, id_cancel),
                          NULL) info_cancel_reason,
                   decode(flg_status_1,
                          pk_alert_constant.g_flg_status_c,
                          pk_message.get_message(i_lang, 'COMMON_M073'),
                          NULL) label_cancel_notes,
                   decode(flg_status_1,
                          pk_alert_constant.g_flg_status_c,
                          pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, id_cancel),
                          NULL) info_cancel_notes
            
              FROM (SELECT id_pat_family,
                           id_family_monetary,
                           nvl(allowance_family, 0) AS allowance_family,
                           id_currency_allow_family,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_allow_family, l_id_currency_default)) AS allow_family_curr_brief_desc,
                           --  
                           nvl(allowance_complementary, 0) AS allowance_complementary,
                           id_currency_allow_comp,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_allow_comp, l_id_currency_default)) AS allow_comp_curr_brief_desc,
                           -- 
                           nvl(other, 0) AS other,
                           id_currency_other,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_other, l_id_currency_default)) AS other_curr_brief_desc,
                           --
                           nvl(subsidy, 0) AS subsidy,
                           id_currency_subsidy,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_subsidy, l_id_currency_default)) AS subsidy_curr_brief_desc,
                           --
                           nvl(fixed_expenses, 0) AS fixed_expenses,
                           id_currency_fixed_exp,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_fixed_exp, l_id_currency_default)) AS fixed_exp_curr_brief_desc,
                           --
                           notes,
                           v_total_members tot_person, -- total de elementos do agregado familiar
                           v_tot_pat_f_mem tot_pat_f_mem, -- valor total dos vencimentos dos elementos do agregado
                           ((v_tot_pat_f_mem + nvl(allowance_family, 0) + nvl(allowance_complementary, 0) +
                           nvl(subsidy, 0) + nvl(other, 0)) /*- nvl(fixed_expenses, 0)*/
                           ) tot_sit_fin,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_allow_family, l_id_currency_default)) AS tot_sit_fin_curr_brief_desc,
                           round((((v_tot_pat_f_mem + nvl(allowance_family, 0) + nvl(allowance_complementary, 0) +
                                 nvl(subsidy, 0) + nvl(other, 0)) - (nvl(fixed_expenses, 0))) / v_total_members),
                                 2) rend_capita,
                           (SELECT currency_desc
                              FROM currency
                             WHERE id_currency = nvl(id_currency_allow_family, l_id_currency_default)) AS rend_capita_curr_brief_desc,
                           flg_status_1,
                           id_cancel
                      FROM (SELECT fm.id_pat_family,
                                   fm.id_family_monetary,
                                   fm.allowance_family,
                                   fm.id_currency_allow_family,
                                   fm.allowance_complementary,
                                   fm.id_currency_allow_comp,
                                   fm.other,
                                   fm.id_currency_other,
                                   fm.subsidy,
                                   fm.id_currency_subsidy,
                                   fm.fixed_expenses,
                                   fm.id_currency_fixed_exp,
                                   fm.notes,
                                   fm.dt_registry_tstz,
                                   fm.flg_status               flg_status_1,
                                   fm.id_cancel_info_det       id_cancel
                              FROM family_monetary fm, patient pat, pat_family pf
                             WHERE fm.id_pat_family /*(+)*/
                                   = pf.id_pat_family
                               AND pf.id_pat_family = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                            UNION ALL
                            SELECT fmh.id_pat_family,
                                   fmh.id_family_monetary_hist id_family_monetary,
                                   fmh.allowance_family,
                                   fmh.id_currency_allow_family,
                                   fmh.allowance_complementary,
                                   fmh.id_currency_allow_comp,
                                   
                                   fmh.other,
                                   fmh.id_currency_other,
                                   fmh.subsidy,
                                   fmh.id_currency_subsidy,
                                   fmh.fixed_expenses,
                                   fmh.id_currency_fixed_exp,
                                   fmh.notes,
                                   fmh.dt_registry_tstz,
                                   fmh.flg_status            flg_status_1,
                                   fmh.id_cancel_info_det    id_cancel
                              FROM family_monetary_hist fmh, patient pat, pat_family pf
                             WHERE fmh.id_pat_family /*(+)*/
                                   = pf.id_pat_family
                               AND pf.id_pat_family = pat.id_pat_family
                               AND pat.id_patient = i_id_pat
                            --AND pf.id_institution = i_prof.institution
                             ORDER BY dt_registry_tstz DESC));
    
        g_error := 'GET CURSOR O_PAT_PROF_SOCIAL_CLASS';
        OPEN o_pat_financial_prof FOR
            SELECT *
              FROM (SELECT p.id_family_monetary id,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, p.dt_registry_tstz, i_prof) dt,
                           --prof.nick_name 
                           --pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                           --pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) || ',' ||
                           --(SELECT i.abbreviation
                           --   FROM institution i
                           --  WHERE i.id_institution = i_prof.institution) desc_speciality,
                           pk_tools.get_prof_description(i_lang, i_prof, p.id_professional, p.dt_registry_tstz, NULL) prof_sign,
                           p.dt_registry_tstz,
                           p.flg_status flg_status,
                           pk_sysdomain.get_domain('FAMILY_MONETARY.FLG_STATUS', p.flg_status, i_lang) desc_status,
                           pk_date_utils.date_send_tsz(i_lang, p.dt_registry_tstz, i_prof) dt_send,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name_sign,
                           pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, p.dt_registry_tstz, NULL) prof_spec_sign
                    
                      FROM family_monetary p, patient pat, pat_family pf
                     WHERE p.id_pat_family = pf.id_pat_family
                       AND pf.id_pat_family = pat.id_pat_family
                       AND pat.id_patient = i_id_pat
                    UNION ALL
                    SELECT p.id_family_monetary_hist id,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, p.dt_registry_tstz, i_prof) dt,
                           --prof.nick_name 
                           --pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                           --pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) || ',' ||
                           --(SELECT i.abbreviation
                           --   FROM institution i
                           --  WHERE i.id_institution = i_prof.institution) desc_speciality,
                           pk_tools.get_prof_description(i_lang, i_prof, p.id_professional, p.dt_registry_tstz, NULL) prof_sign,
                           p.dt_registry_tstz,
                           p.flg_status flg_status,
                           pk_sysdomain.get_domain('FAMILY_MONETARY_HIST.FLG_STATUS', p.flg_status, i_lang) desc_status,
                           pk_date_utils.date_send_tsz(i_lang, p.dt_registry_tstz, i_prof) dt_send,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name_sign,
                           pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, p.dt_registry_tstz, NULL) prof_spec_sign
                    
                      FROM family_monetary_hist p, patient pat, pat_family pf
                     WHERE p.id_pat_family = pf.id_pat_family
                       AND pf.id_pat_family = pat.id_pat_family
                       AND pat.id_patient = i_id_pat)
             ORDER BY dt_registry_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_financial);
            pk_types.open_my_cursor(o_pat_financial_prof);
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOUSEHOLD_FINANCIAL_HIST',
                                                     o_error);
        
    END get_household_fin_hist_report;

    /********************************************************************************************
    * Get patient's family social class history information
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat_social_class       Social Class information cursor
    * @param o_pat_social_class_prof  Professional that inputs the social class information        
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/02/12
    **********************************************************************************************/
    FUNCTION get_social_class_hist_report
    
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_pat                IN patient.id_patient%TYPE,
        i_prof                  IN profissional,
        o_pat_social_class      OUT pk_types.cursor_type,
        o_pat_social_class_prof OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --t_cur_graffar_crit IS TABLE OF VARCHAR2;
    
        l_social_class_info PLS_INTEGER;
    
        CURSOR c_social_class_info IS
            SELECT COUNT(*)
              FROM pat_graffar_crit pgc
             WHERE pgc.id_patient = i_id_pat;
    
    BEGIN
        --the patient already has social class information?
        pk_alertlog.log_debug('GET_SOCIAL_CLASS - The patient already have information for social class?');
        OPEN c_social_class_info;
        FETCH c_social_class_info
            INTO l_social_class_info;
        g_found := c_social_class_info%NOTFOUND;
        CLOSE c_social_class_info;
    
        IF g_found
           OR l_social_class_info = 0
        THEN
            pk_types.open_my_cursor(o_pat_social_class);
            pk_types.open_my_cursor(o_pat_social_class_prof);
        ELSE
            pk_alertlog.log_debug('GET_SOCIAL_CLASS - Information found');
        
            OPEN o_pat_social_class FOR
                SELECT id,
                       pk_paramedical_prof_core.format_str_header_w_colon(titulo) || valor || chr(10) desc_social_class,
                       desc_social_ocupation,
                       desc_education_level,
                       desc_income,
                       desc_house,
                       desc_house_location,
                       notes desc_notes,
                       cancel_reason desc_cancel_reason,
                       cancel_notes desc_cancel_notes,
                       
                       titulo                 label_social_class,
                       valor                  info_social_class,
                       label_social_ocupation,
                       info_social_ocupation,
                       label_education_level,
                       info_education_level,
                       label_income,
                       info_income,
                       label_house,
                       info_house,
                       label_house_location,
                       info_house_location,
                       label_notes,
                       info_notes,
                       label_cancel_reason,
                       info_cancel_reason,
                       label_cancel_notes,
                       label_cancel_notes
                  FROM (SELECT pfsch.id_pat_fam_soc_class_hist id,
                               pk_message.get_message(i_lang, 'SOCIAL_T062') titulo,
                               0 id_graf_crit,
                               pk_translation.get_translation(i_lang, sc.code_social_class) valor,
                               --
                               get_graf_crit_desc(i_lang, i_prof, i_id_pat, 1, pfsch.id_pat_fam_soc_class_hist) desc_social_ocupation,
                               get_graf_crit_desc(i_lang, i_prof, i_id_pat, 2, pfsch.id_pat_fam_soc_class_hist) desc_education_level,
                               get_graf_crit_desc(i_lang, i_prof, i_id_pat, 3, pfsch.id_pat_fam_soc_class_hist) desc_income,
                               get_graf_crit_desc(i_lang, i_prof, i_id_pat, 4, pfsch.id_pat_fam_soc_class_hist) desc_house,
                               get_graf_crit_desc(i_lang, i_prof, i_id_pat, 5, pfsch.id_pat_fam_soc_class_hist) desc_house_location,
                               --
                               pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                         'SOCIAL_T082')) ||
                               nvl(pfsch.notes, pk_paramedical_prof_core.c_dashes) notes,
                               decode(pfsch.flg_status,
                                      pk_alert_constant.g_flg_status_c,
                                      pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                                'COMMON_M072')) ||
                                      pk_paramedical_prof_core.get_cancel_reason_desc(i_lang,
                                                                                      i_prof,
                                                                                      pfsch.id_cancel_info_det),
                                      NULL) cancel_reason,
                               decode(pfsch.flg_status,
                                      pk_alert_constant.g_flg_status_c,
                                      pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                                'COMMON_M073')) ||
                                      pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, pfsch.id_cancel_info_det),
                                      NULL) cancel_notes,
                               ---------
                               pk_translation.get_translation(i_lang,
                                                              (SELECT gc.code_graffar_criteria
                                                                 FROM graffar_criteria gc
                                                                WHERE gc.id_graffar_criteria = 1)) label_social_ocupation,
                               (SELECT to_char(gcv.val) || '-' ||
                                       pk_translation.get_translation(i_lang, gcv.code_graffar_crit_value) valor
                                  FROM pat_graffar_crit pgc, graffar_crit_value gcv
                                 WHERE pgc.id_graffar_crit_value = gcv.id_graffar_crit_value
                                   AND gcv.id_graffar_criteria = 1
                                   AND pgc.id_patient = pat.id_patient
                                   AND pgc.id_pat_fam_soc_class_hist = pfsch.id_pat_fam_soc_class_hist
                                   AND rownum < 2) info_social_ocupation,
                               pk_translation.get_translation(i_lang,
                                                              (SELECT gc.code_graffar_criteria
                                                                 FROM graffar_criteria gc
                                                                WHERE gc.id_graffar_criteria = 2)) label_education_level,
                               (SELECT to_char(gcv.val) || '-' ||
                                       pk_translation.get_translation(i_lang, gcv.code_graffar_crit_value) valor
                                  FROM pat_graffar_crit pgc, graffar_crit_value gcv
                                 WHERE pgc.id_graffar_crit_value = gcv.id_graffar_crit_value
                                   AND gcv.id_graffar_criteria = 2
                                   AND pgc.id_patient = pat.id_patient
                                   AND pgc.id_pat_fam_soc_class_hist = pfsch.id_pat_fam_soc_class_hist
                                   AND rownum < 2) info_education_level,
                               pk_translation.get_translation(i_lang,
                                                              (SELECT gc.code_graffar_criteria
                                                                 FROM graffar_criteria gc
                                                                WHERE gc.id_graffar_criteria = 3)) label_income,
                               (SELECT to_char(gcv.val) || '-' ||
                                       pk_translation.get_translation(i_lang, gcv.code_graffar_crit_value) valor
                                  FROM pat_graffar_crit pgc, graffar_crit_value gcv
                                 WHERE pgc.id_graffar_crit_value = gcv.id_graffar_crit_value
                                   AND gcv.id_graffar_criteria = 3
                                   AND pgc.id_patient = pat.id_patient
                                   AND pgc.id_pat_fam_soc_class_hist = pfsch.id_pat_fam_soc_class_hist
                                   AND rownum < 2) info_income,
                               pk_translation.get_translation(i_lang,
                                                              (SELECT gc.code_graffar_criteria
                                                                 FROM graffar_criteria gc
                                                                WHERE gc.id_graffar_criteria = 4)) label_house,
                               (SELECT to_char(gcv.val) || '-' ||
                                       pk_translation.get_translation(i_lang, gcv.code_graffar_crit_value) valor
                                  FROM pat_graffar_crit pgc, graffar_crit_value gcv
                                 WHERE pgc.id_graffar_crit_value = gcv.id_graffar_crit_value
                                   AND gcv.id_graffar_criteria = 4
                                   AND pgc.id_patient = pat.id_patient
                                   AND pgc.id_pat_fam_soc_class_hist = pfsch.id_pat_fam_soc_class_hist
                                   AND rownum < 2) info_house,
                               pk_translation.get_translation(i_lang,
                                                              (SELECT gc.code_graffar_criteria
                                                                 FROM graffar_criteria gc
                                                                WHERE gc.id_graffar_criteria = 5)) label_house_location,
                               (SELECT to_char(gcv.val) || '-' ||
                                       pk_translation.get_translation(i_lang, gcv.code_graffar_crit_value) valor
                                  FROM pat_graffar_crit pgc, graffar_crit_value gcv
                                 WHERE pgc.id_graffar_crit_value = gcv.id_graffar_crit_value
                                   AND gcv.id_graffar_criteria = 5
                                   AND pgc.id_patient = pat.id_patient
                                   AND pgc.id_pat_fam_soc_class_hist = pfsch.id_pat_fam_soc_class_hist
                                   AND rownum < 2) info_house_location,
                               pk_message.get_message(i_lang, 'SOCIAL_T082') label_notes,
                               pfsch.notes info_notes,
                               decode(pfsch.flg_status,
                                      pk_alert_constant.g_flg_status_c,
                                      pk_message.get_message(i_lang, 'COMMON_M072'),
                                      NULL) label_cancel_reason,
                               decode(pfsch.flg_status,
                                      pk_alert_constant.g_flg_status_c,
                                      pk_paramedical_prof_core.get_cancel_reason_desc(i_lang,
                                                                                      i_prof,
                                                                                      pfsch.id_cancel_info_det),
                                      NULL) info_cancel_reason,
                               decode(pfsch.flg_status,
                                      pk_alert_constant.g_flg_status_c,
                                      pk_message.get_message(i_lang, 'COMMON_M073'),
                                      NULL) label_cancel_notes,
                               decode(pfsch.flg_status,
                                      pk_alert_constant.g_flg_status_c,
                                      pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, pfsch.id_cancel_info_det),
                                      NULL) info_cancel_notes
                          FROM patient pat, pat_family pf, social_class sc, pat_fam_soc_class_hist pfsch
                         WHERE pat.id_pat_family = pf.id_pat_family
                           AND pat.id_patient = i_id_pat
                           AND pf.id_pat_family = pfsch.id_pat_family
                           AND pfsch.id_social_class = sc.id_social_class(+)
                         ORDER BY pfsch.dt_registry_tstz DESC);
        
            g_error := 'GET CURSOR O_PAT_PROF_SOCIAL_CLASS';
            OPEN o_pat_social_class_prof FOR
                SELECT *
                  FROM ( --SELECT pf.id_pat_family id,
                        --       pk_date_utils.dt_chr_date_hour_tsz(i_lang, pf.dt_social_class_tstz, i_prof) dt,
                        --       pk_tools.get_prof_description(i_lang,
                        --                                     i_prof,
                        --                                     pf.id_prof_social_class,
                        --                                     pf.dt_social_class_tstz,
                        --                                     NULL) prof_sign,
                        --       'A' flg_status,
                        --       pf.dt_social_class_tstz dt_registry_tstz,
                        --       NULL desc_status
                        --  FROM patient pat, pat_family pf
                        -- WHERE pat.id_pat_family = pf.id_pat_family
                        --   AND pat.id_patient = i_id_pat
                        --   AND pf.id_social_class IS NOT NULL
                        --UNION ALL
                        SELECT pfsch.id_pat_fam_soc_class_hist id,
                                pk_date_utils.dt_chr_date_hour_tsz(i_lang, pfsch.dt_registry_tstz, i_prof) dt,
                                pk_tools.get_prof_description(i_lang,
                                                              i_prof,
                                                              pfsch.id_professional,
                                                              pfsch.dt_registry_tstz,
                                                              NULL) prof_sign,
                                pfsch.flg_status flg_status,
                                pfsch.dt_registry_tstz dt_registry_tstz,
                                pk_sysdomain.get_domain('PAT_FAM_SOC_CLASS_HIST.FLG_STATUS', pfsch.flg_status, i_lang) desc_status,
                                pk_date_utils.date_send_tsz(i_lang, pfsch.dt_registry_tstz, i_prof) dt_send,
                                pk_prof_utils.get_name_signature(i_lang, i_prof, pfsch.id_professional) prof_name_sign,
                                pk_prof_utils.get_spec_signature(i_lang,
                                                                 i_prof,
                                                                 pfsch.id_professional,
                                                                 pfsch.dt_registry_tstz,
                                                                 NULL) prof_spec_sign
                        
                          FROM patient pat, pat_family pf, pat_fam_soc_class_hist pfsch
                         WHERE pat.id_pat_family = pf.id_pat_family
                           AND pat.id_patient = i_id_pat
                           AND pf.id_pat_family = pfsch.id_pat_family
                         ORDER BY dt_registry_tstz DESC NULLS LAST);
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_social_class);
            pk_types.open_my_cursor(o_pat_social_class_prof);
            pk_utils.undo_changes;
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_SOCIAL_CLASS_HIST',
                                                     o_error);
        
    END get_social_class_hist_report;
    /********************************************************************************************
    * Get patient's Social status. This includes information of:
    *    - Home 
    *    - Social class
    *    - Financial status
    *    - Household
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_id_pat                 Patient ID 
    * @ param o_pat_home              Patient's home information
    * @ param o_pat_home_prof         Last professional that edit the home information
    * @ param o_pat_social_class      Social class information
    * @ param o_pat_social_class_prof Last professional that edit the social class
    * @ param o_pat_financial         Financial situation information
    * @ param o_pat_financial_prof    Last professional that edit the financial situation 
    * @ param o_pat_household         Household information
    * @param o_pat                    Family grid
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_social_status_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        --home
        o_pat_home      OUT pk_types.cursor_type,
        o_pat_home_prof OUT pk_types.cursor_type,
        --social class
        o_pat_social_class      OUT pk_types.cursor_type,
        o_pat_social_class_prof OUT pk_types.cursor_type,
        --financial
        o_pat_financial      OUT pk_types.cursor_type,
        o_pat_financial_prof OUT pk_types.cursor_type,
        --house hold
        o_pat_household OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT get_home_new_report(i_lang          => i_lang,
                                   i_id_pat        => i_id_pat,
                                   i_prof          => i_prof,
                                   o_pat_home      => o_pat_home,
                                   o_pat_home_prof => o_pat_home_prof,
                                   o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF NOT get_social_class_report(i_lang              => i_lang,
                                       i_id_pat            => i_id_pat,
                                       i_prof              => i_prof,
                                       o_social_class      => o_pat_social_class,
                                       o_prof_social_class => o_pat_social_class_prof,
                                       o_error             => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF NOT get_household_financial_report(i_lang               => i_lang,
                                              i_id_pat             => i_id_pat,
                                              i_prof               => i_prof,
                                              o_pat_financial      => o_pat_financial,
                                              o_pat_financial_prof => o_pat_financial_prof,
                                              o_error              => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        IF NOT get_household(i_lang          => i_lang,
                             i_episode       => i_episode,
                             i_id_pat        => i_id_pat,
                             i_prof          => i_prof,
                             o_pat_household => o_pat_household,
                             o_error         => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            pk_types.open_my_cursor(o_pat_social_class);
            pk_types.open_my_cursor(o_pat_social_class_prof);
            pk_types.open_my_cursor(o_pat_financial);
            pk_types.open_my_cursor(o_pat_financial_prof);
            pk_types.open_my_cursor(o_pat_household);
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_SOCIAL',
                                                     'GET_HOME_DETAIL',
                                                     o_error);
        
    END get_social_status_report;

    /***
    * Checks if a home_field is available
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info           
    * @param i_id_home_field          home_field identifier
    * @param i_market                 market identifier
    * @param i_flg_active             'Y' or 'N'
    *
    * @return  id_home_field_config
    *
    * @author   Paulo Teixeira
    * @version  2.6.1.2
    * @since    2011/08/25
    */
    FUNCTION get_hfcm_pk
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_home_field IN home_field.id_home_field%TYPE,
        i_market        IN market.id_market%TYPE,
        i_flg_active    IN home_field_config_mkt.flg_active%TYPE
    ) RETURN NUMBER IS
        l_return home_field_config_mkt.id_home_field_config_mkt%TYPE;
    BEGIN
        g_error := 'get home_field_config_mkt primary key';
        BEGIN
            SELECT id_home_field_config_mkt
              INTO l_return
              FROM (SELECT hfc.id_home_field_config_mkt,
                           hfc.flg_active flg_active,
                           row_number() over(ORDER BY decode(hfc.id_market, i_market, 1, 2)) line_number
                      FROM home_field_config_mkt hfc
                     WHERE hfc.id_home_field = i_id_home_field
                       AND hfc.id_market IN (0, i_market))
             WHERE line_number = 1
               AND flg_active = i_flg_active;
        EXCEPTION
            WHEN OTHERS THEN
                l_return := NULL;
        END;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_hfcm_pk;

    /***
    * Checks if a home_field is available
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info           
    * @param i_id_home_field          home_field identifier
    * @param i_flg_active             'Y' or 'N'
    *
    * @return  id_home_field_config
    *
    * @author   Paulo Teixeira
    * @version  2.6.1.2
    * @since    2011/08/25
    */
    FUNCTION get_hfc_pk
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_home_field IN home_field.id_home_field%TYPE,
        i_flg_active    IN home_field_config.flg_active%TYPE
    ) RETURN NUMBER IS
        l_return home_field_config.id_home_field_config%TYPE;
    BEGIN
        g_error := 'get home_field_config primary key';
        BEGIN
        
            SELECT id_home_field_config
              INTO l_return
              FROM (SELECT hfc.id_home_field_config,
                           hfc.flg_active flg_active,
                           row_number() over(ORDER BY decode(hfc.id_institution, i_prof.institution, 1, 2)) line_number
                      FROM home_field_config hfc
                     WHERE hfc.id_home_field = i_id_home_field
                       AND hfc.id_institution IN (i_prof.institution))
             WHERE line_number = 1
               AND flg_active = i_flg_active;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_return := NULL;
        END;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_hfc_pk;
    /***
    * get field 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info           
    * @param i_id                     identifier 
    * @param i_home_field             home_field
    * @param i_table                  table
    *
    * @return  value
    *
    * @author   Paulo Teixeira
    * @version  2.6.1.2
    * @since    2011/08/25
    */
    FUNCTION get_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id         IN NUMBER,
        i_home_field IN home_field.home_field%TYPE,
        i_table      IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000 CHAR);
        l_sql    VARCHAR2(4000 CHAR);
    BEGIN
        g_error := 'get_field';
        BEGIN
            -- build select to retreive the field value 
            l_sql := 'SELECT h.' || i_home_field || ' FROM ' || i_table || ' h WHERE h.id_' || i_table || ' = ' || i_id;
            EXECUTE IMMEDIATE l_sql
                INTO l_return;
        EXCEPTION
            WHEN OTHERS THEN
                l_return := NULL;
        END;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_field;
    /********************************************************************************************
    * Get patient's home characteristics to edit 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat                    Family grid
    * @param o_id_home                id_home out
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Paulo Teixeira
    * @version                         0.1
    * @since                           2011/08/25
    **********************************************************************************************/
    FUNCTION get_home_edit_new
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_pat_home OUT pk_types.cursor_type,
        o_id_home  OUT home.id_home%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_home    table_number;
        l_flg_status table_varchar;
        l_market     institution.id_market%TYPE := pk_core.get_inst_mkt(i_prof.institution);
    BEGIN
        g_error := 'GET l_id_home, l_flg_status';
        BEGIN
            --get id_home and flg_status from home table
            SELECT id_home, flg_status
              BULK COLLECT
              INTO l_id_home, l_flg_status
              FROM (SELECT h.id_home id_home, h.flg_status
                      FROM patient pat
                      JOIN pat_family pf
                        ON pf.id_pat_family = pat.id_pat_family
                      JOIN home h
                        ON h.id_pat_family = pf.id_pat_family
                     WHERE pat.id_patient = i_id_pat
                     ORDER BY h.dt_registry_tstz DESC)
             WHERE rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                l_id_home    := table_number();
                l_flg_status := table_varchar();
        END;
    
        -- flg_status = 'C' then edit equals new record, clean grid, no fields are filed
        IF l_id_home.count = 0
        THEN
            l_id_home := table_number(NULL);
        ELSE
            IF l_flg_status(1) = g_home_flg_status_c
            THEN
                l_id_home := table_number(NULL);
            END IF;
        END IF;
    
        -- get all configured active fields for create/edit home
        g_error := 'open o_pat_home';
        OPEN o_pat_home FOR
            SELECT /*+opt_estimate (table active rows=0.000001)*/
             active.id id_home,
             active.id_home_field field_id,
             active.field_title field_title,
             decode(active.flg_data_type, g_home_flg_data_type_m, active.field, NULL) field_real_value,
             active.field_value field_value,
             active.intern_name_sample_text_type field_sample_text_id,
             active.flg_data_type field_flg_data_type,
             active.flg_mandatory field_flg_mandatory,
             active.min_value field_min_value,
             active.max_value field_max_value,
             active.mask field_mask,
             active.domain field_multichoice_domain
              FROM TABLE(get_home_field_tf(i_lang, i_prof, l_market, pk_alert_constant.g_yes, l_id_home, g_table_home)) active
             ORDER BY nvl(active.hfc_rank, active.hf_rank);
    
        o_id_home := l_id_home(1);
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            o_id_home := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_HOME_EDIT_NEW',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_home_edit_new;
    /********************************************************************************************
     * Save family home conditions.
     *
     * @param i_lang                    Preferred language ID for this professional
     * @param i_prof                    Object (professional ID, institution ID, software ID)     
     * @param i_id_pat                  Patient ID
     * @param i_id_home                 Home conditions record ID
     * @param i_id_home_field           home_field identifier array
     * @param i_table_flg               home_field falgs array
     * @param i_table_desc              home_field discriptions array        
     * @param o_error                   Error
     *
     * @return                          true or false on success or error
     *
     * @author                           Paulo teixeira
     * @version                          0.1
     * @since                            2011/08/28
    **********************************************************************************************/
    FUNCTION set_home_new
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_home       IN home.id_home%TYPE,
        i_id_home_field IN table_number,
        i_table_flg     IN table_varchar,
        i_table_desc    IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_home              home.id_home%TYPE;
        l_next                 home.id_home%TYPE;
        l_id_pat_fam           patient.id_pat_family%TYPE;
        l_sql                  VARCHAR2(32767 CHAR);
        l_rowids               table_varchar;
        l_home_field           home_field.home_field%TYPE;
        l_flg_data_type        home_field.flg_data_type%TYPE;
        l_home_field_free_text home_field.home_field_free_text%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        -- get/create pacient id_pat_family 
        IF NOT set_pat_fam(i_lang       => i_lang,
                           i_id_pat     => i_id_pat,
                           i_prof       => i_prof,
                           i_commit     => pk_alert_constant.g_no,
                           o_id_pat_fam => l_id_pat_fam,
                           o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_id_home IS NULL
        THEN
            --get id_home if it already exists
            BEGIN
                SELECT id_home
                  INTO l_id_home
                  FROM (SELECT h.id_home id_home
                          FROM home h
                         WHERE h.id_pat_family = l_id_pat_fam
                         ORDER BY h.dt_registry_tstz DESC)
                 WHERE rownum = 1;
            EXCEPTION
                WHEN OTHERS THEN
                    l_id_home := NULL;
            END;
        ELSE
            l_id_home := i_id_home;
        END IF;
    
        IF l_id_home IS NULL
        THEN
            -- insert home
            l_sql := 'call ts_home.ins(id_pat_family_in => ' || l_id_pat_fam || ', id_professional_in => ' || i_prof.id ||
                     ', dt_registry_tstz_in => ''' || g_sysdate_tstz || ''', flg_status_in => ''' ||
                     pk_alert_constant.g_flg_status_a || '''';
        
            FOR i IN 1 .. i_id_home_field.count
            LOOP
                SELECT hf.home_field, hf.flg_data_type, hf.home_field_free_text
                  INTO l_home_field, l_flg_data_type, l_home_field_free_text
                  FROM home_field hf
                 WHERE hf.id_home_field = i_id_home_field(i);
            
                CASE
                    WHEN l_flg_data_type = g_home_flg_data_type_n
                         OR l_flg_data_type = g_home_flg_data_type_t THEN
                        l_sql := l_sql || ', ' || l_home_field || '_in => ''' || i_table_desc(i) || '''';
                    WHEN l_flg_data_type = g_home_flg_data_type_m THEN
                        l_sql := l_sql || ', ' || l_home_field || '_in => ''' || i_table_flg(i) || '''';
                        IF i_table_flg(i) = g_home_flg_other
                        THEN
                            l_sql := l_sql || ', ' || l_home_field_free_text || '_in => ''' || i_table_desc(i) || '''';
                        END IF;
                    ELSE
                        NULL;
                END CASE;
            END LOOP;
        
            l_sql := l_sql || ', id_home_out => :l_next, rows_out => :l_rowids)';
        
            g_error := 'INSERT HOME';
            pk_alertlog.log_debug(l_sql);
            EXECUTE IMMEDIATE l_sql
                USING IN OUT l_next, IN OUT l_rowids;
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON HOME';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => g_table_home,
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- insert home_hist
            IF NOT set_home_hist(i_lang    => i_lang,
                                 i_prof    => i_prof,
                                 i_id_pat  => i_id_pat,
                                 i_id_home => l_next,
                                 o_error   => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        
        ELSE
            -- update home
            l_sql := 'DECLARE L_FALSE BOOLEAN := FALSE; L_NULL number; BEGIN ts_home.upd(id_home_in => ' || l_id_home ||
                     ', id_professional_in => ' || i_prof.id || ', dt_registry_tstz_in => ''' || g_sysdate_tstz ||
                     ''', flg_status_in => ''' || pk_alert_constant.g_flg_status_e ||
                     ''', id_cancel_info_det_in => L_NULL, id_cancel_info_det_nin => L_FALSE ';
        
            FOR i IN 1 .. i_id_home_field.count
            LOOP
                SELECT hf.home_field, hf.flg_data_type, hf.home_field_free_text
                  INTO l_home_field, l_flg_data_type, l_home_field_free_text
                  FROM home_field hf
                 WHERE hf.id_home_field = i_id_home_field(i);
            
                CASE
                    WHEN l_flg_data_type = g_home_flg_data_type_n
                         OR l_flg_data_type = g_home_flg_data_type_t THEN
                        l_sql := l_sql || ', ' || l_home_field || '_in => ''' || i_table_desc(i) || '''' || ', ' ||
                                 l_home_field || '_nin => L_FALSE';
                    WHEN l_flg_data_type = g_home_flg_data_type_m THEN
                        l_sql := l_sql || ', ' || l_home_field || '_in => ''' || i_table_flg(i) || '''' || ', ' ||
                                 l_home_field || '_nin => L_FALSE';
                        IF i_table_flg(i) = g_home_flg_other
                        THEN
                            l_sql := l_sql || ', ' || l_home_field_free_text || '_in => ''' || i_table_desc(i) || '''' || ', ' ||
                                     l_home_field_free_text || '_nin => L_FALSE';
                        END IF;
                    ELSE
                        NULL;
                END CASE;
            END LOOP;
        
            l_sql := l_sql || ', rows_out => :l_rowids); END;';
        
            g_error := 'UPDATE HOME';
            pk_alertlog.log_debug(l_sql);
            EXECUTE IMMEDIATE l_sql
                USING IN OUT l_rowids;
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => g_table_home,
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- insert home_hist
            IF NOT set_home_hist(i_lang    => i_lang,
                                 i_prof    => i_prof,
                                 i_id_pat  => i_id_pat,
                                 i_id_home => l_id_home,
                                 o_error   => o_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        
        END IF;
        --
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
        --
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'SET_HOME_NEW',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_home_new;

    /********************************************************************************************
    * Get patient's home characteristics 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat                    Family grid
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          paulo teixeira
    * @version                         0.1
    * @since                           2011/08/29
    **********************************************************************************************/
    FUNCTION get_home_new
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_history           IN VARCHAR2 DEFAULT 'N',
        i_show_cancel       IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label IN VARCHAR2 DEFAULT 'N',
        i_report            IN VARCHAR2 DEFAULT 'N',
        i_show_inactive     IN VARCHAR2 DEFAULT 'N',
        o_pat_home          OUT pk_types.cursor_type,
        o_pat_home_prof     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_home_hist table_number;
        l_market       institution.id_market%TYPE := pk_core.get_inst_mkt(i_prof.institution);
        c_rownum_limited   CONSTANT PLS_INTEGER := 1;
        c_rownum_unlimited CONSTANT PLS_INTEGER := 999999;
        l_rownum         PLS_INTEGER;
        l_show_cancelled VARCHAR2(1 CHAR) := '-';
        l_common_m072    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M072');
        l_common_m073    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M073');
    BEGIN
        --show home history
        IF i_history = pk_alert_constant.get_no
        THEN
            l_rownum := c_rownum_limited;
        ELSE
            l_rownum := c_rownum_unlimited;
        END IF;
    
        --show cancelled records
        IF i_show_cancel <> pk_alert_constant.get_yes
        THEN
            l_show_cancelled := pk_alert_constant.g_flg_status_c;
        END IF;
    
        g_error        := 'get id_home_hist';
        l_id_home_hist := get_ids_home_hist(i_lang, i_prof, i_id_pat, l_rownum, l_show_cancelled);
    
        g_error := 'GET CURSOR O_PAT_HOME';
        OPEN o_pat_home FOR
            SELECT id_home_hist, field_title, field_value
              FROM (SELECT /*+opt_estimate (table active rows=0.000001)*/
                     active.id id_home_hist,
                     active.field_title,
                     active.field_value,
                     active.order_date,
                     active.hfc_rank,
                     active.hf_rank,
                     active.id_home_field
                      FROM TABLE(get_home_field_tf(i_lang,
                                                   i_prof,
                                                   l_market,
                                                   pk_alert_constant.g_yes,
                                                   l_id_home_hist,
                                                   g_table_home_hist)) active
                    UNION ALL
                    SELECT /*+opt_estimate (table inactive rows=0.000001)*/
                     inactive.id id_home_hist,
                     inactive.field_title,
                     inactive.field_value,
                     inactive.order_date,
                     inactive.hfc_rank,
                     inactive.hf_rank,
                     inactive.id_home_field
                      FROM TABLE(get_home_field_tf(i_lang,
                                                   i_prof,
                                                   l_market,
                                                   pk_alert_constant.g_no,
                                                   l_id_home_hist,
                                                   g_table_home_hist)) inactive
                     WHERE inactive.field_value IS NOT NULL
                       AND i_show_inactive = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT /*+opt_estimate (table a rows=0.000001)*/
                     hh.id_home_hist id_home_hist,
                     l_common_m072 field_title,
                     pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, hh.id_cancel_info_det) field_value,
                     pk_date_utils.date_send_tsz(i_lang, hh.dt_home_hist, i_prof) order_date,
                     c_rownum_unlimited hfc_rank,
                     c_rownum_unlimited hf_rank,
                     c_rownum_unlimited id_home_field
                      FROM home_hist hh
                      JOIN TABLE(l_id_home_hist) a
                        ON a.column_value = hh.id_home_hist
                     WHERE hh.id_cancel_info_det IS NOT NULL
                    UNION ALL
                    SELECT /*+opt_estimate (table a rows=0.000001)*/
                     hh.id_home_hist id_home_hist,
                     l_common_m073 field_title,
                     pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, hh.id_cancel_info_det) field_value,
                     pk_date_utils.date_send_tsz(i_lang, hh.dt_home_hist, i_prof) order_date,
                     c_rownum_unlimited + 1 hfc_rank,
                     c_rownum_unlimited + 1 hf_rank,
                     c_rownum_unlimited + 1 id_home_field
                      FROM home_hist hh
                      JOIN TABLE(l_id_home_hist) a
                        ON a.column_value = hh.id_home_hist
                     WHERE hh.id_cancel_info_det IS NOT NULL)
             ORDER BY order_date DESC, nvl(hfc_rank, hf_rank);
    
        g_error := 'GET CURSOR O_PAT_HOME_PROF';
        OPEN o_pat_home_prof FOR
            SELECT /*+opt_estimate (table t rows=0.000001)*/
             t.id_home_hist id,
             pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_home_hist, i_prof) dt,
             pk_tools.get_prof_description(i_lang, i_prof, t.id_professional, t.dt_home_hist, NULL) prof_sign,
             nvl(t.flg_status, g_flg_active) flg_status,
             decode(i_history,
                    pk_alert_constant.get_no,
                    NULL,
                    pk_sysdomain.get_domain(g_home_hist_flg_status, t.flg_status, i_lang)) desc_status
              FROM TABLE(pk_social.get_home_hist_tf(i_lang, i_prof, i_id_pat, l_rownum, l_show_cancelled)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_HOME_NEW',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_home_new;

    /********************************************************************************************
    * Get patient's home characteristics 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_pat                 Patient ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat                    Family grid
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Paulo teixeira
    * @version                         0.1
    * @since                           2011/08/30
    **********************************************************************************************/
    FUNCTION get_home_new_report
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_history           IN VARCHAR2 DEFAULT 'N',
        i_show_cancel       IN VARCHAR2 DEFAULT 'Y',
        i_show_header_label IN VARCHAR2 DEFAULT 'N',
        i_report            IN VARCHAR2 DEFAULT 'N',
        o_pat_home          OUT pk_types.cursor_type,
        o_pat_home_prof     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_home_hist table_number;
        l_market       institution.id_market%TYPE := pk_core.get_inst_mkt(i_prof.institution);
        c_rownum_limited   CONSTANT PLS_INTEGER := 1;
        c_rownum_unlimited CONSTANT PLS_INTEGER := 999999;
        l_rownum         PLS_INTEGER;
        l_show_cancelled VARCHAR2(1 CHAR) := '-';
        l_common_m072    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M072');
        l_common_m073    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_M073');
    BEGIN
        pk_alertlog.log_debug('GET_HOME_NEW : i_id_pat = ' || i_id_pat);
        --show home history
        IF i_history = pk_alert_constant.get_no
        THEN
            l_rownum := c_rownum_limited;
        ELSE
            l_rownum := c_rownum_unlimited;
        END IF;
    
        --show cancelled records
        IF i_show_cancel <> pk_alert_constant.get_yes
        THEN
            l_show_cancelled := pk_alert_constant.g_flg_status_c;
        END IF;
    
        g_error        := 'get id_home_hist';
        l_id_home_hist := get_ids_home_hist(i_lang, i_prof, i_id_pat, l_rownum, l_show_cancelled);
    
        g_error := 'GET CURSOR O_PAT_HOME';
        OPEN o_pat_home FOR
            SELECT id_home_hist, field_title, field_value, id_home_field
              FROM (SELECT /*+opt_estimate (table active rows=0.000001)*/
                     active.id id_home_hist,
                     active.field_title,
                     active.field_value,
                     active.order_date,
                     active.hfc_rank,
                     active.hf_rank,
                     active.id_home_field
                      FROM TABLE(get_home_field_tf(i_lang,
                                                   i_prof,
                                                   l_market,
                                                   pk_alert_constant.g_yes,
                                                   l_id_home_hist,
                                                   g_table_home_hist)) active
                    UNION ALL
                    SELECT /*+opt_estimate (table inactive rows=0.000001)*/
                     inactive.id id_home_hist,
                     inactive.field_title,
                     inactive.field_value,
                     inactive.order_date,
                     inactive.hfc_rank,
                     inactive.hf_rank,
                     inactive.id_home_field
                      FROM TABLE(get_home_field_tf(i_lang,
                                                   i_prof,
                                                   l_market,
                                                   pk_alert_constant.g_no,
                                                   l_id_home_hist,
                                                   g_table_home_hist)) inactive
                     WHERE inactive.field_value IS NOT NULL
                    UNION ALL
                    SELECT /*+opt_estimate (table a rows=0.000001)*/
                     hh.id_home_hist id_home_hist,
                     l_common_m072 field_title,
                     pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, hh.id_cancel_info_det) field_value,
                     pk_date_utils.date_send_tsz(i_lang, hh.dt_home_hist, i_prof) order_date,
                     c_rownum_unlimited hfc_rank,
                     c_rownum_unlimited hf_rank,
                     c_rownum_unlimited id_home_field
                      FROM home_hist hh
                      JOIN TABLE(l_id_home_hist) a
                        ON a.column_value = hh.id_home_hist
                     WHERE hh.id_cancel_info_det IS NOT NULL
                    UNION ALL
                    SELECT /*+opt_estimate (table a rows=0.000001)*/
                     hh.id_home_hist id_home_hist,
                     l_common_m073 field_title,
                     pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, hh.id_cancel_info_det) field_value,
                     pk_date_utils.date_send_tsz(i_lang, hh.dt_home_hist, i_prof) order_date,
                     c_rownum_unlimited + 1 hfc_rank,
                     c_rownum_unlimited + 1 hf_rank,
                     c_rownum_unlimited + 1 id_home_field
                      FROM home_hist hh
                      JOIN TABLE(l_id_home_hist) a
                        ON a.column_value = hh.id_home_hist
                     WHERE hh.id_cancel_info_det IS NOT NULL)
             ORDER BY order_date DESC, nvl(hfc_rank, hf_rank);
    
        g_error := 'GET CURSOR O_PAT_HOME_PROF';
        OPEN o_pat_home_prof FOR
            SELECT /*+opt_estimate (table t rows=0.000001)*/
             t.id_home_hist id_home_hist,
             pk_date_utils.dt_chr_date_hour_tsz(i_lang, t.dt_home_hist, i_prof) dt_sign,
             pk_date_utils.date_send_tsz(i_lang, t.dt_home_hist, i_prof) dt_send,
             pk_tools.get_prof_description(i_lang, i_prof, t.id_professional, t.dt_home_hist, NULL) prof_sign,
             pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_name_sign,
             pk_prof_utils.get_spec_signature(i_lang, i_prof, t.id_professional, t.dt_home_hist, NULL) prof_spec_sign,
             nvl(t.flg_status, g_flg_active) flg_status,
             pk_sysdomain.get_domain(g_home_hist_flg_status, nvl(t.flg_status, g_flg_active), i_lang) desc_status
              FROM TABLE(pk_social.get_home_hist_tf(i_lang, i_prof, i_id_pat, l_rownum, l_show_cancelled)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_home);
            pk_types.open_my_cursor(o_pat_home_prof);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              'GET_HOME_NEW_REPORT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_home_new_report;

    /********************************************************************************************
    * Get patient's home characteristics for the summary page
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)    
    * @param i_id_patient             Patient ID 
    * @param o_id_home                Home id
    * @param o_home_desc              Patient's home characteristics
    *
    * @return                         True on success, False otherwise
    *
    * @author                         Diogo Oliveira
    * @version                        v2.7.3.6
    * @since                          2018/11/19
    **********************************************************************************************/
    FUNCTION get_home_summary_page
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_id_home    OUT home.id_home%TYPE,
        o_home_desc  OUT VARCHAR2
    ) RETURN BOOLEAN IS
        l_id_home table_number;
        l_market  institution.id_market%TYPE := pk_core.get_inst_mkt(i_prof.institution);
    
        l_home     VARCHAR2(4000);
        l_home_aux table_varchar := table_varchar();
    BEGIN
    
        g_error := 'get id_home';
        SELECT h.id_home
          BULK COLLECT
          INTO l_id_home
          FROM patient pat
          JOIN pat_family pf
            ON pf.id_pat_family = pat.id_pat_family
          JOIN home h
            ON h.id_pat_family = pf.id_pat_family
         WHERE pat.id_patient = i_id_patient
           AND h.flg_status <> pk_alert_constant.g_cancelled;
    
        IF l_id_home IS NOT NULL
           AND l_id_home.exists(1)
        THEN
        
            o_id_home := l_id_home(1);
            g_error   := 'GET CURSOR O_PAT_HOME';
            SELECT field_title || chr(58) || chr(32) || field_value
              BULK COLLECT
              INTO l_home_aux
              FROM (SELECT /*+opt_estimate (table active rows=0.000001)*/
                     active.id id_home_hist,
                     active.field_title,
                     decode(active.field_value, NULL, '--', active.field_value) field_value,
                     active.order_date,
                     active.hfc_rank,
                     active.hf_rank,
                     active.id_home_field
                      FROM TABLE(get_home_field_tf(i_lang, i_prof, l_market, pk_alert_constant.g_yes, l_id_home, 'HOME')) active
                     ORDER BY nvl(hfc_rank, hf_rank));
        
            IF l_home_aux IS NOT NULL
               AND l_home_aux.exists(1)
            THEN
                FOR i IN l_home_aux.first .. l_home_aux.last
                LOOP
                    IF i < l_home_aux.last
                    THEN
                        l_home := l_home || l_home_aux(i) || chr(13);
                    ELSE
                        l_home := l_home || l_home_aux(i);
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        o_home_desc := l_home;
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_id_home   := NULL;
            o_home_desc := NULL;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_home_summary_page;

    /********************************************************************************************
    * Get home table function 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_market              market identifier
    * @param i_active                 get active or inactive
    * @param i_ids                    table with id's to select
    * @param i_table                  table to select
    *
    * @return                         pipelined table
    *
    * @author                          Paulo teixeira
    * @version                         0.1
    * @since                           2011/08/30
    **********************************************************************************************/
    FUNCTION get_home_field_tf
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_market IN market.id_market%TYPE,
        i_active    IN VARCHAR2,
        i_ids       IN table_number,
        i_table     IN VARCHAR2
    ) RETURN home_table
        PIPELINED IS
        v_tab    home_rec;
        c_result pk_types.cursor_type;
        l_found  VARCHAR(1 CHAR);
    BEGIN
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO l_found
              FROM home_field_config hfc
             WHERE hfc.id_institution = i_prof.institution
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_found := pk_alert_constant.g_no;
        END;
    
        IF l_found = pk_alert_constant.g_yes
        THEN
            g_error := 'open c_result';
            OPEN c_result FOR
                SELECT t.id id,
                       t.label field_title,
                       t.field field,
                       CASE
                            WHEN t.flg_data_type = g_home_flg_data_type_m
                                 AND t.field <> g_home_flg_other THEN
                             pk_sysdomain.get_domain(g_table_home || g_dot || t.home_field, t.field, i_lang)
                            WHEN t.flg_data_type = g_home_flg_data_type_m
                                 AND t.field = g_home_flg_other THEN
                             nvl(get_field(i_lang, i_prof, t.id, t.home_field_free_text, i_table),
                                 pk_sysdomain.get_domain(g_table_home || g_dot || t.home_field, t.field, i_lang))
                            ELSE
                             t.field
                        END field_value,
                       t.order_date order_date,
                       t.hfc_rank hfc_rank,
                       t.hf_rank hf_rank,
                       t.id_home_field id_home_field,
                       t.intern_name_sample_text_type intern_name_sample_text_type,
                       t.domain domain,
                       t.flg_data_type flg_data_type,
                       t.flg_mandatory flg_mandatory,
                       t.min_value min_value,
                       t.max_value max_value,
                       t.mask mask
                  FROM (SELECT /*+opt_estimate (table a rows=0.000001)*/
                         a.column_value id,
                         pk_message.get_message(i_lang, i_prof, hf1.code_message) label,
                         get_field(i_lang, i_prof, a.column_value, hf1.home_field, i_table) field,
                         hf1.home_field_free_text home_field_free_text,
                         hf1.flg_data_type flg_data_type,
                         hf1.home_field home_field,
                         pk_date_utils.date_send_tsz(i_lang,
                                                     pk_social.get_field(i_lang,
                                                                         i_prof,
                                                                         a.column_value,
                                                                         g_dt_home_hist,
                                                                         i_table),
                                                     i_prof) order_date,
                         hfc.rank hfc_rank,
                         hf1.hf_rank hf_rank,
                         hf1.id_home_field id_home_field,
                         hf1.intern_name_sample_text_type intern_name_sample_text_type,
                         hf1.domain domain,
                         hfc.mask mask,
                         hfc.flg_mandatory flg_mandatory,
                         hfc.min_value min_value,
                         hfc.max_value max_value
                          FROM home_field_config hfc
                          JOIN (SELECT hf.code_message code_message,
                                      hf.home_field home_field,
                                      hf.rank hf_rank,
                                      hf.id_home_field id_home_field,
                                      hf.home_field_free_text home_field_free_text,
                                      hf.flg_data_type flg_data_type,
                                      pk_social.get_hfc_pk(i_lang, i_prof, hf.id_home_field, i_active) id_home_field_config,
                                      hf.domain,
                                      hf.intern_name_sample_text_type
                                 FROM home_field hf) hf1
                            ON hfc.id_home_field_config = hf1.id_home_field_config
                         CROSS JOIN TABLE(i_ids) a
                         WHERE hf1.id_home_field_config IS NOT NULL) t;
        ELSE
        
            g_error := 'open c_result';
            OPEN c_result FOR
                SELECT t.id id,
                       t.label field_title,
                       t.field field,
                       CASE
                            WHEN t.flg_data_type = g_home_flg_data_type_m
                                 AND t.field <> g_home_flg_other THEN
                             pk_sysdomain.get_domain(g_table_home || g_dot || t.home_field, t.field, i_lang)
                            WHEN t.flg_data_type = g_home_flg_data_type_m
                                 AND t.field = g_home_flg_other THEN
                             nvl(get_field(i_lang, i_prof, t.id, t.home_field_free_text, i_table),
                                 pk_sysdomain.get_domain(g_table_home || g_dot || t.home_field, t.field, i_lang))
                            ELSE
                             t.field
                        END field_value,
                       t.order_date order_date,
                       t.hfc_rank hfc_rank,
                       t.hf_rank hf_rank,
                       t.id_home_field id_home_field,
                       t.intern_name_sample_text_type intern_name_sample_text_type,
                       t.domain domain,
                       t.flg_data_type flg_data_type,
                       t.flg_mandatory flg_mandatory,
                       t.min_value min_value,
                       t.max_value max_value,
                       t.mask mask
                  FROM (SELECT /*+opt_estimate (table a rows=0.000001)*/
                         a.column_value id,
                         pk_message.get_message(i_lang, i_prof, hf1.code_message) label,
                         get_field(i_lang, i_prof, a.column_value, hf1.home_field, i_table) field,
                         hf1.home_field_free_text home_field_free_text,
                         hf1.flg_data_type flg_data_type,
                         hf1.home_field home_field,
                         pk_date_utils.date_send_tsz(i_lang,
                                                     pk_social.get_field(i_lang,
                                                                         i_prof,
                                                                         a.column_value,
                                                                         g_dt_home_hist,
                                                                         i_table),
                                                     i_prof) order_date,
                         hfcm.rank hfc_rank,
                         hf1.hf_rank hf_rank,
                         hf1.id_home_field id_home_field,
                         hf1.intern_name_sample_text_type intern_name_sample_text_type,
                         hf1.domain domain,
                         hfcm.mask mask,
                         hfcm.flg_mandatory flg_mandatory,
                         hfcm.min_value min_value,
                         hfcm.max_value max_value
                          FROM home_field_config_mkt hfcm
                          JOIN (SELECT hf.code_message code_message,
                                      hf.home_field home_field,
                                      hf.rank hf_rank,
                                      hf.id_home_field id_home_field,
                                      hf.home_field_free_text home_field_free_text,
                                      hf.flg_data_type flg_data_type,
                                      pk_social.get_hfcm_pk(i_lang, i_prof, hf.id_home_field, i_id_market, i_active) id_home_field_config_mkt,
                                      hf.domain,
                                      hf.intern_name_sample_text_type
                                 FROM home_field hf) hf1
                            ON hfcm.id_home_field_config_mkt = hf1.id_home_field_config_mkt
                         CROSS JOIN TABLE(i_ids) a
                         WHERE hf1.id_home_field_config_mkt IS NOT NULL) t;
        END IF;
        LOOP
            FETCH c_result
                INTO v_tab;
            EXIT WHEN c_result%NOTFOUND;
            PIPE ROW(v_tab);
        END LOOP;
    
        RETURN;
    END get_home_field_tf;

    /********************************************************************************************
    * Get home table function 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 patient identifier
    * @param i_rownum                 rownumber
    * @param i_show_cancelled         flg show cancelled
    *
    * @return                         pipelined table
    *
    * @author                          Paulo teixeira
    * @version                         0.1
    * @since                           2011/08/30
    **********************************************************************************************/
    FUNCTION get_home_hist_tf
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat         IN patient.id_patient%TYPE,
        i_rownum         IN NUMBER,
        i_show_cancelled IN VARCHAR2
    ) RETURN home_hist_table
        PIPELINED IS
        v_tab    home_hist_rec;
        c_result pk_types.cursor_type;
    BEGIN
    
        g_error := 'open c_result';
        OPEN c_result FOR
            SELECT id_home_hist, dt_home_hist, id_professional, flg_status
              FROM (SELECT id_home_hist, dt_home_hist, id_professional, flg_status
                      FROM (SELECT h.id_home_hist id_home_hist,
                                   h.dt_home_hist,
                                   h.id_professional,
                                   nvl(h.flg_status, g_flg_active) flg_status
                              FROM patient pat
                              JOIN pat_family pf
                                ON pf.id_pat_family = pat.id_pat_family
                              JOIN home_hist h
                                ON h.id_pat_family = pf.id_pat_family
                             WHERE pat.id_patient = i_id_pat
                             ORDER BY dt_home_hist DESC)
                     WHERE rownum <= i_rownum) aux
             WHERE i_show_cancelled <> aux.flg_status;
    
        LOOP
            FETCH c_result
                INTO v_tab;
            EXIT WHEN c_result%NOTFOUND;
            PIPE ROW(v_tab);
        END LOOP;
    
        RETURN;
    END get_home_hist_tf;
    /********************************************************************************************
    * get ids home hist  
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 patient identifier
    * @param i_rownum                 rownumber
    * @param i_show_cancelled         show cancelled
    *
    * @return                         id's home_hist
    *
    * @author                          Paulo teixeira
    * @version                         0.1
    * @since                           2011/09/08
    **********************************************************************************************/
    FUNCTION get_ids_home_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat         IN patient.id_patient%TYPE,
        i_rownum         IN NUMBER,
        i_show_cancelled IN VARCHAR2
    ) RETURN table_number IS
        l_id_home_hist table_number;
    BEGIN
        g_error := 'get id_home_hist';
        --get collection of id_home_hist to process
        SELECT /*+opt_estimate (table t rows=0.000001)*/
         t.id_home_hist
          BULK COLLECT
          INTO l_id_home_hist
          FROM TABLE(pk_social.get_home_hist_tf(i_lang, i_prof, i_id_pat, i_rownum, i_show_cancelled)) t;
    
        RETURN l_id_home_hist;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number();
    END get_ids_home_hist;

    /********************************************************************************************
    * get all patients button grid data. 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_software            software id for filtering purpose
    * @param o_data                   output cursor
    * @param o_error                  Error info
    *
    * @return                         true or false on success or error
    *
    * @author                          Telmo
    * @version                         2.6.1.2
    * @since                           19-09-2011
    **********************************************************************************************/
    FUNCTION get_all_patient_grid_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_software IN software.id_software%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(30) := 'GET_ALL_PATIENT_GRID_DATA';
        l_hand_off_type sys_config.value%TYPE;
        l_reasongrid    VARCHAR2(1);
        l_type_opinion  opinion_type.id_opinion_type%TYPE;
        l_category      category.id_category%TYPE;
    
        CURSOR c_type_request IS
            SELECT ot.id_opinion_type
              FROM opinion_type ot
             WHERE ot.id_category = l_category;
    BEGIN
    
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_reasongrid   := pk_sysconfig.get_config('REASON_FOR_VISIT_GRID', i_prof);
        g_sysdate_tstz := current_timestamp;
    
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'OPEN C_TYPE_REQUEST';
        OPEN c_type_request;
        FETCH c_type_request
            INTO l_type_opinion;
        CLOSE c_type_request;
    
        OPEN o_data FOR
            SELECT *
              FROM (SELECT epis.id_episode,
                            epis.id_schedule,
                            epis.id_professional,
                            epis.id_dep_clin_serv id_department_service,
                            pk_translation.get_translation(i_lang, d.code_department) department_name,
                            pk_translation.get_translation(i_lang, cs.code_clinical_service) clinical_service_name,
                            epis.id_room,
                            nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name,
                            epis.id_bed,
                            nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_name,
                            epis.id_patient,
                            pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, epis.id_schedule) pat_photo,
                            pk_patient.get_pat_age(i_lang, epis.id_patient, i_prof) pat_age,
                            pk_patient.get_gender(i_lang, p.gender) pat_gender,
                            pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode, epis.id_schedule) pat_name,
                            pk_patient.get_pat_name_to_sort(i_lang,
                                                            i_prof,
                                                            epis.id_patient,
                                                            epis.id_episode,
                                                            epis.id_schedule) name_pat_to_sort,
                            pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                            (SELECT cr.num_clin_record
                               FROM clin_record cr
                              WHERE cr.id_patient = epis.id_patient
                                AND cr.id_institution = i_prof.institution
                                AND rownum = 1) num_clin_record,
                            epis.id_software id_origin,
                            pk_translation.get_translation(i_lang, sfw.code_software) origin_name,
                            (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                          i_prof,
                                                                          pk_alert_constant.g_cat_type_doc,
                                                                          epis.id_episode,
                                                                          epis.id_professional,
                                                                          l_hand_off_type,
                                                                          'G')
                               FROM dual) responsible_name,
                            pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icon,
                            epis.id_first_nurse_resp id_nurse,
                            (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                          i_prof,
                                                                          pk_alert_constant.g_cat_type_nurse,
                                                                          epis.id_episode,
                                                                          epis.id_first_nurse_resp,
                                                                          l_hand_off_type,
                                                                          'G')
                               FROM dual) nurse_name,
                            decode(epis.id_software,
                                   pk_alert_constant.g_soft_edis, -- EDIS
                                   pk_edis_grid.get_complaint_grid(i_lang, i_prof, epis.id_episode),
                                   pk_alert_constant.g_soft_inpatient, -- INP
                                   pk_edis_grid.get_complaint_grid(i_lang, i_prof, epis.id_episode),
                                   pk_alert_constant.g_soft_primary_care, -- CARE
                                   decode(l_reasongrid,
                                          pk_alert_constant.g_no,
                                          NULL,
                                          pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                      profissional(i_prof.id,
                                                                                                                                   epis.id_institution,
                                                                                                                                   epis.id_software),
                                                                                                                      epis.id_episode,
                                                                                                                      s.id_schedule),
                                                                           4000)),
                                   pk_alert_constant.g_soft_oris, -- ORIS
                                   pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                            epis.id_episode,
                                                                            i_prof,
                                                                            pk_alert_constant.g_no),
                                   -- OUTP E PP
                                   nvl((SELECT substr(concatenate(decode(nvl(ec.id_complaint,
                                                                            decode(s.flg_reason_type,
                                                                                   'C',
                                                                                   s.id_reason,
                                                                                   NULL)),
                                                                        NULL,
                                                                        ec.patient_complaint,
                                                                        pk_translation.get_translation(i_lang,
                                                                                                       'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                       nvl(ec.id_complaint,
                                                                                                           decode(s.flg_reason_type,
                                                                                                                  'C',
                                                                                                                  s.id_reason,
                                                                                                                  NULL)))) || '; '),
                                                     1,
                                                     length(concatenate(decode(nvl(ec.id_complaint,
                                                                                   decode(s.flg_reason_type,
                                                                                          'C',
                                                                                          s.id_reason,
                                                                                          NULL)),
                                                                               NULL,
                                                                               ec.patient_complaint,
                                                                               pk_translation.get_translation(i_lang,
                                                                                                              'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                              nvl(ec.id_complaint,
                                                                                                                  decode(s.flg_reason_type,
                                                                                                                         'C',
                                                                                                                         s.id_reason,
                                                                                                                         NULL))) || '; '))) -
                                                     length('; '))
                                         FROM epis_complaint ec
                                        WHERE ec.id_episode = epis.id_episode
                                          AND nvl(ec.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active),
                                       decode(l_reasongrid,
                                              pk_alert_constant.g_yes,
                                              pk_complaint.get_reason_desc(i_lang,
                                                                           profissional(i_prof.id,
                                                                                        epis.id_institution,
                                                                                        epis.id_software),
                                                                           epis.id_episode,
                                                                           s.id_schedule)))) visit_reason,
                            decode(o.flg_state,
                                   pk_opinion.g_opinion_accepted,
                                   pk_prof_utils.get_name_signature(i_lang,
                                                                    i_prof,
                                                                    nvl(op.id_professional, o.id_prof_questioned)),
                                   NULL) prof_in_charge,
                            pk_diagnosis.get_epis_diagnosis(i_lang, epis.id_episode) diagnosis_name,
                            o.id_opinion,
                            o.id_episode_answer,
                            decode(o.flg_state, 'C', NULL, o.flg_state),
                            CASE
                                 WHEN o.id_opinion IS NULL THEN
                                  'ND' -- este episodio nao tem pedido parecer
                                 WHEN o.id_opinion IS NOT NULL
                                      AND o.id_episode_answer IS NULL
                                      AND ((o.flg_state = pk_opinion.g_opinion_req AND
                                      pk_opinion.check_approval_need(profissional(o.id_prof_questions,
                                                                                        epis.id_institution,
                                                                                        epis.id_software),
                                                                           l_type_opinion) = pk_alert_constant.g_no) OR
                                      o.flg_state = pk_opinion.g_opinion_approved) THEN
                                  pk_opinion.g_opinion_req -- tem pedido de parecer aguardando aceitaçao
                                 WHEN o.id_opinion IS NOT NULL
                                      AND o.id_episode_answer IS NULL
                                      AND o.flg_state = pk_opinion.g_opinion_req
                                      AND pk_opinion.check_approval_need(profissional(o.id_prof_questions,
                                                                                      epis.id_institution,
                                                                                      epis.id_software),
                                                                         l_type_opinion) = pk_alert_constant.g_yes THEN
                                  'ND'
                                 WHEN o.id_opinion IS NOT NULL
                                      AND o.flg_state IN (pk_opinion.g_opinion_rejected, pk_opinion.g_opinion_over) THEN
                                  'ND'
                                 ELSE
                                  pk_opinion.g_opinion_accepted -- todos os outros casos sao pedidos cancelados rejeitados, concluidos, em andamento, etc.
                             
                             END follow_up_status,
                            CASE
                                 WHEN o.id_opinion IS NULL THEN -- este episodio nao tem pedido parecer
                                  pk_utils.get_status_string_immediate(i_lang,
                                                                       i_prof,
                                                                       pk_alert_constant.g_display_type_icon,
                                                                       'N',
                                                                       NULL,
                                                                       NULL,
                                                                       'DISCH_TRANSF_INST.FLG_STATUS',
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL)
                                 WHEN o.id_opinion IS NOT NULL
                                      AND o.id_episode_answer IS NULL
                                      AND (o.flg_state = pk_opinion.g_opinion_approved OR
                                      (o.flg_state = pk_opinion.g_opinion_req AND
                                      pk_opinion.check_approval_need(profissional(o.id_prof_questions,
                                                                                        epis.id_institution,
                                                                                        epis.id_software),
                                                                           l_type_opinion) = pk_alert_constant.g_no)) THEN --tem pedido de parecer aguardando aceitaçao
                                  pk_utils.get_status_string_immediate(i_lang,
                                                                       i_prof,
                                                                       pk_alert_constant.g_display_type_date,
                                                                       NULL,
                                                                       NULL,
                                                                       pk_date_utils.to_char_insttimezone(i_prof,
                                                                                                          nvl(o.dt_last_update,
                                                                                                              o.dt_problem_tstz),
                                                                                                          pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                                       NULL,
                                                                       NULL,
                                                                       pk_alert_constant.g_color_red,
                                                                       pk_alert_constant.g_color_null,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       g_sysdate_tstz)
                                 WHEN o.id_opinion IS NOT NULL
                                      AND o.id_episode_answer IS NULL
                                      AND o.flg_state = pk_opinion.g_opinion_req
                                      AND pk_opinion.check_approval_need(profissional(o.id_prof_questions,
                                                                                      epis.id_institution,
                                                                                      epis.id_software),
                                                                         l_type_opinion) = pk_alert_constant.g_yes THEN
                                  pk_utils.get_status_string_immediate(i_lang,
                                                                       i_prof,
                                                                       pk_alert_constant.g_display_type_icon,
                                                                       'N',
                                                                       NULL,
                                                                       NULL,
                                                                       'DISCH_TRANSF_INST.FLG_STATUS',
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL)
                                 WHEN o.id_opinion IS NOT NULL
                                      AND o.flg_state IN (pk_opinion.g_opinion_rejected, pk_opinion.g_opinion_over) THEN
                                  pk_utils.get_status_string_immediate(i_lang,
                                                                       i_prof,
                                                                       pk_alert_constant.g_display_type_icon,
                                                                       'N',
                                                                       NULL,
                                                                       NULL,
                                                                       'DISCH_TRANSF_INST.FLG_STATUS',
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL)
                                 ELSE -- todos os outros casos sao pedidos cancelados rejeitados, concluidos, em andamento, etc.
                                  pk_utils.get_status_string_immediate(i_lang,
                                                                       i_prof,
                                                                       pk_alert_constant.g_display_type_icon,
                                                                       o.flg_state,
                                                                       NULL,
                                                                       NULL,
                                                                       'OPINION.FLG_STATE.REQUEST',
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL)
                             END follow_up_icon,
                            CASE
                                 WHEN o.flg_state IN (pk_opinion.g_opinion_req, pk_opinion.g_opinion_approved) THEN
                                  pk_alert_constant.g_yes
                                 ELSE
                                  pk_alert_constant.g_no
                             END flg_action,
                            decode(o.dt_problem_tstz,
                                   NULL,
                                   1,
                                   row_number() over(PARTITION BY o.id_episode ORDER BY o.dt_problem_tstz DESC)) rownumber
                       FROM v_episode_act epis
                       LEFT JOIN schedule s
                         ON epis.id_schedule = s.id_schedule
                       LEFT JOIN schedule_outp so
                         ON s.id_schedule = so.id_schedule -- este join so da' nos episodios de outp, pp, pc, edis
                      LEFT JOIN clinical_service cs
                        ON epis.id_clinical_service = cs.id_clinical_service
                      LEFT JOIN bed b
                        ON epis.id_bed = b.id_bed
                      LEFT JOIN room r
                        ON r.id_room = b.id_room
                       AND r.flg_available = pk_alert_constant.g_yes
                      LEFT JOIN department d
                        ON d.id_department = r.id_department
                       AND d.flg_available = pk_alert_constant.g_yes
                      LEFT JOIN patient p
                        ON epis.id_patient = p.id_patient
                      LEFT JOIN software sfw
                        ON epis.id_software = sfw.id_software
                      LEFT JOIN opinion o
                        ON epis.id_episode = o.id_episode
                       AND o.id_opinion_type = l_type_opinion
                      LEFT JOIN opinion_prof op
                        ON o.id_opinion = op.id_opinion
                     WHERE epis.id_institution = i_prof.institution -- so episodios da inst corrente
                       AND epis.id_software = nvl(i_id_software, epis.id_software) -- episodios de [todos os softwares | software pedido]
                       AND epis.id_software IN (pk_alert_constant.g_soft_outpatient,
                                                pk_alert_constant.g_soft_oris,
                                                pk_alert_constant.g_soft_primary_care,
                                                pk_alert_constant.g_soft_edis,
                                                pk_alert_constant.g_soft_inpatient,
                                                pk_alert_constant.g_soft_private_practice)
                       AND epis.flg_ehr = pk_alert_constant.g_flg_ehr_n -- so episodios normais
                       AND epis.flg_status_e = pk_alert_constant.g_epis_status_active -- esta condicao ja existe na v_episode_act
                       AND epis.id_epis_type NOT IN
                           (pk_alert_constant.g_epis_type_case_manager,
                            pk_alert_constant.g_epis_type_social,
                            pk_alert_constant.g_epis_type_dietitian,
                            pk_alert_constant.g_epis_type_psychologist) -- excluir os episodios de social worker e de nutricionista
                    
                     ORDER BY name_pat_to_sort)
             WHERE rownumber = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_all_patient_grid_data;

    /********************************************************************************************
    * create a follow-up request and sets it as accepted. To be used in the All patient button when
    * the user presses OK in a valid episode (those without follow-up). Also used in the same button
    * inside the dietitian software.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             episode that will be followed
    * @param i_id_patient             episode patient
    * @param i_id_dcs                 episode dcs
    * @param i_id_prof                professional that is creating this follow up
    * @param o_id_opinion             resulting follow up request id
    * @param o_id_episode             resulting follow-up episode id
    * @param o_error                  Error info
    *
    * @return                         true or false on success or error
    *
    * @author                         Telmo
    * @version                        2.6.1.2
    * @since                          21-09-2011
    **********************************************************************************************/
    FUNCTION set_accepted_follow_up
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_dcs          IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_prof         IN opinion.id_prof_questioned%TYPE,
        i_id_opinion_type IN opinion.id_opinion_type%TYPE,
        o_id_opinion      OUT opinion.id_opinion%TYPE,
        o_id_episode      OUT opinion.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(30) := 'SET_ACCEPTED_FOLLOW_UP';
        l_id_cs          dep_clin_serv.id_clinical_service%TYPE;
        l_dummy          opinion_hist.id_opinion_hist%TYPE;
        l_dummy2         opinion_prof.id_opinion_prof%TYPE;
        l_dummy4         epis_encounter.id_epis_encounter%TYPE;
        l_transaction_id VARCHAR2(4000);
        l_ext_exception EXCEPTION;
    BEGIN
    
        g_error := l_func_name || ' - GET CLINICAL SERVICE ID';
        SELECT id_clinical_service
          INTO l_id_cs
          FROM dep_clin_serv
         WHERE id_dep_clin_serv = nvl(i_id_dcs, -1);
    
        g_error := l_func_name || ' - CREATE FOLLOW-UP REQUEST';
        IF NOT pk_opinion.set_consult_request(i_lang                => i_lang,
                                              i_prof                => i_prof, -- este vai ser o id_prof_questions
                                              i_episode             => i_id_episode,
                                              i_patient             => i_id_patient,
                                              i_opinion             => NULL,
                                              i_opinion_type        => i_id_opinion_type,
                                              i_clin_serv           => l_id_cs,
                                              i_reason_ft           => NULL,
                                              i_reason_mc           => NULL,
                                              i_tbl_alert_diagnosis => NULL,
                                              i_prof_id             => i_prof.id, -- este vai ser o id_prof_questioned
                                              i_notes               => NULL,
                                              i_do_commit           => pk_alert_constant.g_no,
                                              i_followup_auto       => pk_alert_constant.g_yes,
                                              o_opinion             => o_id_opinion,
                                              o_opinion_hist        => l_dummy,
                                              o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- get remote transaction
        g_error          := 'START REMOTE TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        -- create 'accepted' answer 
        g_error := l_func_name || ' - CREATE FOLLOW-UP ANSWER';
        IF NOT pk_opinion.set_request_answer(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_opinion          => o_id_opinion,
                                             i_patient          => i_id_patient,
                                             i_flg_state        => pk_opinion.g_opinion_accepted,
                                             i_management_level => NULL,
                                             i_notes            => NULL,
                                             i_cancel_reason    => NULL,
                                             i_transaction_id   => l_transaction_id,
                                             i_do_commit        => pk_alert_constant.g_no,
                                             o_opinion_prof     => l_dummy2,
                                             o_episode          => o_id_episode,
                                             o_epis_encounter   => l_dummy4,
                                             o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- fechar transacoes
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            o_id_opinion := NULL;
            o_id_episode := NULL;
            RETURN FALSE;
        WHEN l_ext_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            o_id_opinion := NULL;
            o_id_episode := NULL;
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
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            o_id_opinion := NULL;
            o_id_episode := NULL;
            RETURN FALSE;
    END set_accepted_follow_up;
    /********************************************************************************************
    * Get patient's list of social episodes and social followup requests
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @ param i_remove_status         Episode status to remove from the list
    * @ param o_episodes_ids          List of episode IDs
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Teresa Coutinho
    * @version                         0.1
    * @since                           2014/09/19
    **********************************************************************************************/

    FUNCTION get_epis_by_pat
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_epis_type  IN table_number,
        i_remove_status IN table_varchar DEFAULT table_varchar(pk_alert_constant.g_flg_status_c),
        o_episodes_ids  OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_EPIS_BY_TYPE_AND_PAT';
        pk_alertlog.log_debug(g_error);
    
        SELECT id_episode id_episode
          BULK COLLECT
          INTO o_episodes_ids
          FROM (SELECT epi.id_episode
                  FROM (SELECT o.id_episode
                          FROM opinion o, opinion_type ot
                         WHERE o.id_opinion_type = ot.id_opinion_type
                           AND ot.id_category = g_social_worker_category) opi,
                       episode epi
                 WHERE epi.id_episode = opi.id_episode
                   AND epi.id_patient = i_id_pat
                   AND epi.flg_status NOT IN (SELECT column_value
                                                FROM TABLE(i_remove_status))
                UNION
                SELECT epi.id_episode id_episode
                  FROM episode epi
                 WHERE epi.id_epis_type IN (SELECT column_value
                                              FROM TABLE(i_id_epis_type))
                   AND epi.id_patient = i_id_pat
                   AND epi.flg_status NOT IN (SELECT column_value
                                                FROM TABLE(i_remove_status)));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            --
            --
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SOCIAL',
                                              i_function => 'GET_EPIS_BY_PAT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
    END get_epis_by_pat;

    /********************************************************************************************
    *  Get current state of housing for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_housing_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_HOUSING_VIEWER_CHECK';
        l_episodes      table_number := table_number();
        l_cnt_completed NUMBER(24);
        l_flg_checklist VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
        -- current house record
        SELECT COUNT(*) cnt
          INTO l_cnt_completed
          FROM home h
         WHERE h.id_pat_family = (SELECT p.id_pat_family
                                    FROM patient p
                                    JOIN episode e
                                      ON e.id_patient = p.id_patient
                                     AND e.id_episode IN (SELECT *
                                                            FROM TABLE(l_episodes)))
           AND h.flg_status <> g_home_flg_status_c;
    
        -- fill in viewer checklist flag
        IF l_cnt_completed > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    END get_housing_viewer_check;

    /********************************************************************************************
    *  Get current state of Socio-demographic data for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_demographic_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_DEMOGRAPHIC_VIEWER_CHECK';
        l_episodes      table_number := table_number();
        l_cnt_completed NUMBER(24);
        l_flg_checklist VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
        -- current socio-demographic data records
        SELECT COUNT(*) cnt
          INTO l_cnt_completed
          FROM pat_graffar_crit pgc
         WHERE pgc.id_episode IN (SELECT *
                                    FROM TABLE(l_episodes))
           AND pgc.flg_status <> g_graffar_status_c;
    
        -- fill in viewer checklist flag
        IF l_cnt_completed > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    END get_demographic_viewer_check;

    /********************************************************************************************
    *  Get current state of Household financial situation for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_finance_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_cnt_completed NUMBER(24);
        l_flg_checklist VARCHAR2(1 CHAR);
    BEGIN
    
        -- current Household financial situation records
        SELECT COUNT(*)
          INTO l_cnt_completed
          FROM family_monetary fm
          JOIN patient p
            ON fm.id_pat_family = p.id_pat_family
         WHERE p.id_patient = i_patient
           AND fm.flg_status <> g_hh_finance_status_c;
    
        -- fill in viewer checklist flag
        IF l_cnt_completed > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    END get_finance_viewer_check;

    /********************************************************************************************
    *  Get current state of Social Services Report for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_serv_report_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_SERV_REPORT_VIEWER_CHECK';
        l_episodes      table_number := table_number();
        l_cnt_completed NUMBER(24);
        l_flg_checklist VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
        -- current  Social Services Report records
        SELECT COUNT(*) cnt
          INTO l_cnt_completed
          FROM paramed_report pr
         WHERE pr.id_episode IN (SELECT *
                                   FROM TABLE(l_episodes))
           AND pr.flg_status <> pk_paramedical_prof_core.g_report_cancel;
    
        -- fill in viewer checklist flag
        IF l_cnt_completed > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    END get_serv_report_viewer_check;

    /* *******************************************************************************************
    *  Get current state of Social Services Report for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************pk_case_man************************************************************************/
    FUNCTION get_vwr_social_interv_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_flg_checklist VARCHAR2(0001 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        l_episodes      table_number;
        l_count         NUMBER;
        --k_vwr_flg_resolved CONSTANT VARCHAR2(0001 CHAR) := 'F';
        k_vwr_flg_canceled CONSTANT VARCHAR2(0001 CHAR) := 'C';
        k_epis_type_social CONSTANT NUMBER(24) := pk_alert_constant.g_epis_type_social;
    BEGIN
    
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM epis_interv_plan eip
          JOIN episode e
            ON e.id_episode = eip.id_episode
         WHERE eip.id_episode IN (SELECT column_value id_episode
                                    FROM TABLE(l_episodes))
              --   AND e.id_epis_type = k_epis_type_social
           AND eip.flg_status != k_vwr_flg_canceled;
    
        IF l_count > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        END IF;
    
        RETURN l_flg_checklist;
    
    END get_vwr_social_interv_plan;

    /* *******************************************************************************************
    *  Get current state of Social discharge for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_social_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_flg_checklist VARCHAR2(0001 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        l_episodes      table_number;
        l_count         NUMBER;
        k_vwr_flg_active CONSTANT VARCHAR2(0001 CHAR) := pk_alert_constant.g_active;
    BEGIN
    
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM discharge d
          JOIN episode e
            ON e.id_episode = d.id_episode
         WHERE d.id_episode IN (SELECT column_value id_episode
                                  FROM TABLE(l_episodes))
           AND e.id_epis_type = pk_alert_constant.g_epis_type_social
           AND d.flg_status IN (k_vwr_flg_active);
    
        IF l_count > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        END IF;
    
        RETURN l_flg_checklist;
    
    END get_vwr_social_discharge;

    -- **********************************************************************
    FUNCTION get_impressions(i_episode IN table_number) RETURN VARCHAR2 IS
        l_count  NUMBER;
        l_status VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM epis_diagnosis_notes ed
          JOIN episode e
            ON e.id_episode = ed.id_episode
           AND e.id_epis_type = pk_alert_constant.g_epis_type_social
         WHERE e.id_episode IN (SELECT column_value id_episode
                                  FROM TABLE(i_episode));
    
        IF l_count > 0
        THEN
            l_status := pk_viewer_checklist.g_checklist_completed;
        END IF;
    
        RETURN l_status;
    
    END get_impressions;

    -- *************************************************************************
    FUNCTION get_vwr_social_diff_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status   VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        l_episodes table_number := table_number();
    BEGIN
        l_status := pk_diagnosis.get_diagnosis_viewer_checklist(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_scope_type => i_scope_type,
                                                                i_id_episode => i_episode,
                                                                i_id_patient => i_patient,
                                                                i_flg_type   => pk_diagnosis.g_diag_type_p);
    
        IF l_status = pk_viewer_checklist.g_checklist_not_started
        THEN
        
            l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_patient    => i_patient,
                                               i_episode    => i_episode,
                                               i_flg_filter => i_scope_type);
        
            l_status := get_impressions(i_episode => l_episodes);
        END IF;
    
        RETURN l_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_status;
    END get_vwr_social_diff_diag;

    -- *************************************************************************
    FUNCTION get_vwr_social_final_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status   VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        l_episodes table_number := table_number();
    BEGIN
        l_status := pk_diagnosis.get_diagnosis_viewer_checklist(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_scope_type => i_scope_type,
                                                                i_id_episode => i_episode,
                                                                i_id_patient => i_patient,
                                                                i_flg_type   => pk_diagnosis.g_diag_type_d);
    
        IF l_status = pk_viewer_checklist.g_checklist_not_started
        THEN
        
            l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_patient    => i_patient,
                                               i_episode    => i_episode,
                                               i_flg_filter => i_scope_type);
        
            l_status := get_impressions(i_episode => l_episodes);
        END IF;
    
        RETURN l_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_status;
    END get_vwr_social_final_diag;

    -- *************************************************************************
    FUNCTION get_vwr_social_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status   VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        l_episodes table_number;
        tbl_status table_varchar := table_varchar(pk_diagnosis.g_ed_flg_status_co,
                                                  pk_diagnosis.g_ed_flg_status_d,
                                                  pk_diagnosis.g_ed_flg_status_r,
                                                  pk_diagnosis.g_ed_flg_status_p);
    BEGIN
    
        l_status := pk_diagnosis.get_vwr_diag_type_epis(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_scope_type => i_scope_type,
                                                        i_id_episode => i_episode,
                                                        i_id_patient => i_patient,
                                                        i_epis_type  => pk_alert_constant.g_epis_type_social,
                                                        i_tbl_status => tbl_status);
    
        IF l_status = pk_viewer_checklist.g_checklist_not_started
        THEN
        
            l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_patient    => i_patient,
                                               i_episode    => i_episode,
                                               i_flg_filter => i_scope_type);
        
            l_status := get_impressions(i_episode => l_episodes);
        END IF;
    
        RETURN l_status;
    
    END get_vwr_social_diag;

    FUNCTION get_mom_patient_id
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
        l_id_patient patient.id_patient%TYPE;
    BEGIN
        SELECT pfm.id_pat_related
          INTO l_id_patient
          FROM pat_family_member pfm
         WHERE pfm.id_family_relationship = g_id_fam_rel_mother
           AND pfm.id_patient = i_patient;
        RETURN l_id_patient;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_mom_patient_id;

    /********************************************************************************************
    * Get patient's intervention plans
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             Patient ID     
    *
    * @return                         Returns the list of intervention plans
    *
    * @author                         Diogo Oliveira
    * @version                        v2.7.3.6
    * @since                          2018/11/19
    **********************************************************************************************/
    FUNCTION get_interv_plan_summary_page
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN table_varchar IS
        t_table_message_array  pk_paramedical_prof_core.table_message_array;
        l_category             category.flg_type%TYPE;
        l_tbl_interv_plan_desc table_varchar := table_varchar();
    BEGIN
    
        l_category := pk_prof_utils.get_category(i_lang, i_prof);
    
        g_error := 'GET LABELS';
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('PARAMEDICAL_T003',
                                                                                          'SOCIAL_T082',
                                                                                          'SOCIAL_T124',
                                                                                          'SOCIAL_T104',
                                                                                          'SOCIAL_T125',
                                                                                          'SOCIAL_T004',
                                                                                          'SOCIAL_T107',
                                                                                          'SOCIAL_T108',
                                                                                          'SOCIAL_T109',
                                                                                          'PARAMEDICAL_T002',
                                                                                          'PARAMEDICAL_T022'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_sw_generic_exception;
        END IF;
    
        g_error := 'GET PATIENT DETAILS';
        SELECT
        --plan_desc 
         t_table_message_array('PARAMEDICAL_T003') || chr(58) || chr(32) || CASE
              WHEN eip.id_interv_plan = 0 THEN
               eip.desc_other_interv_plan
              WHEN eip.id_interv_plan IS NULL THEN
               eip.desc_other_interv_plan
              ELSE
               pk_translation.get_translation(i_lang, ip.code_interv_plan)
          END || chr(13) ||
         --task goal
          decode(l_category,
                 pk_alert_constant.g_cat_type_social,
                 NULL,
                 t_table_message_array('PARAMEDICAL_T002') || chr(58) || chr(32) ||
                 pk_paramedical_prof_core.get_task_goal_desc(i_lang, i_prof, eip.id_task_goal_det) || chr(13)) ||
         --desc_dt_begin
          decode(eip.dt_begin,
                 NULL,
                 NULL,
                 t_table_message_array('SOCIAL_T104') || chr(58) || chr(32) ||
                 pk_date_utils.dt_chr_tsz(i_lang, eip.dt_begin, i_prof) || chr(13)) ||
         --desc_dt_end
          decode(eip.dt_end,
                 NULL,
                 NULL,
                 t_table_message_array('SOCIAL_T125') || chr(58) || chr(32) ||
                 pk_date_utils.dt_chr_tsz(i_lang, eip.dt_end, i_prof) || chr(13)) ||
         --desc_status
          t_table_message_array('SOCIAL_T004') || chr(58) || chr(32) ||
          decode(eip.flg_status,
                 pk_alert_constant.g_flg_status_e,
                 pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', pk_alert_constant.g_flg_status_a, i_lang),
                 pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', eip.flg_status, i_lang)) || chr(13) ||
         --diagnoses       
          t_table_message_array('PARAMEDICAL_T022') || chr(58) || chr(32) ||
          pk_utils.concat_table(pk_paramedical_prof_core.get_desc_epis_diag(i_lang,
                                                                            i_prof,
                                                                            pk_paramedical_prof_core.get_epis_interv_plan_diag(i_lang,
                                                                                                                               i_prof,
                                                                                                                               eip.id_epis_interv_plan,
                                                                                                                               NULL)),
                                '; ',
                                1,
                                -1) || chr(13) ||
         --notes
          decode(eip.notes,
                 NULL,
                 NULL,
                 t_table_message_array('SOCIAL_T082') || chr(58) || chr(32) || eip.notes || chr(13))
          BULK COLLECT
          INTO l_tbl_interv_plan_desc
          FROM epis_interv_plan eip
          JOIN interv_plan ip
            ON ip.id_interv_plan = eip.id_interv_plan
         WHERE eip.id_episode IN (SELECT e.id_episode
                                    FROM episode e
                                   WHERE e.id_patient = i_id_patient)
           AND eip.flg_status NOT IN (pk_alert_constant.g_cancelled)
         ORDER BY eip.dt_creation DESC;
    
        RETURN l_tbl_interv_plan_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_interv_plan_summary_page;

    FUNCTION get_interv_plan_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_interv_plan IN epis_interv_plan.id_epis_interv_plan%TYPE,
        i_flg_description     IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_episode IS
            SELECT id_episode
              FROM epis_interv_plan
             WHERE id_epis_interv_plan = i_id_epis_interv_plan;
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
        l_category            category.flg_type%TYPE;
        l_interv_plan_desc    VARCHAR2(4000);
        l_id_episode          episode.id_episode%TYPE;
        l_id_epis_type        epis_type.id_epis_type%TYPE;
        l_error               t_error_out;
    BEGIN
    
        l_category := pk_prof_utils.get_category(i_lang, i_prof);
    
        IF i_flg_description = 'L'
        THEN
            g_error := 'GET LABELS';
            IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                              i_code_msg_arr => table_varchar('PARAMEDICAL_T003',
                                                                                              'SOCIAL_T082',
                                                                                              'SOCIAL_T124',
                                                                                              'SOCIAL_T104',
                                                                                              'SOCIAL_T125',
                                                                                              'SOCIAL_T004',
                                                                                              'SOCIAL_T107',
                                                                                              'SOCIAL_T108',
                                                                                              'SOCIAL_T109',
                                                                                              'PARAMEDICAL_T002',
                                                                                              'PARAMEDICAL_T022',
                                                                                              'PSYCHO_T010'),
                                                              i_prof         => i_prof,
                                                              o_desc_msg_arr => t_table_message_array)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
            g_error := 'OPEN C_EPISODE';
            OPEN c_episode;
            FETCH c_episode
                INTO l_id_episode;
            CLOSE c_episode;
        
            g_error := 'GET EPIS TYPE';
            IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                            i_id_epis   => l_id_episode,
                                            o_epis_type => l_id_epis_type,
                                            o_error     => l_error)
            THEN
                RAISE g_sw_generic_exception;
            END IF;
        
            g_error := 'GET PATIENT DETAILS';
            SELECT
            --plan_desc 
             CASE
                  WHEN l_id_epis_type = pk_alert_constant.g_epis_type_psychologist THEN
                   t_table_message_array('PSYCHO_T010')
                  ELSE
                   t_table_message_array('PARAMEDICAL_T003')
              END || chr(58) || chr(32) || CASE
                  WHEN eip.id_interv_plan = 0 THEN
                   eip.desc_other_interv_plan
                  WHEN eip.id_interv_plan IS NULL THEN
                   eip.desc_other_interv_plan
                  ELSE
                   pk_translation.get_translation(i_lang, ip.code_interv_plan)
              END || chr(13) ||
             --task goal
              decode(l_category,
                     pk_alert_constant.g_cat_type_social,
                     NULL,
                     t_table_message_array('PARAMEDICAL_T002') || chr(58) || chr(32) ||
                     pk_paramedical_prof_core.get_task_goal_desc(i_lang, i_prof, eip.id_task_goal_det) || chr(13)) ||
             --desc_dt_begin
              decode(eip.dt_begin,
                     NULL,
                     NULL,
                     t_table_message_array('SOCIAL_T104') || chr(58) || chr(32) ||
                     pk_date_utils.dt_chr_tsz(i_lang, eip.dt_begin, i_prof) || chr(13)) ||
             --desc_dt_end
              decode(eip.dt_end,
                     NULL,
                     NULL,
                     t_table_message_array('SOCIAL_T125') || chr(58) || chr(32) ||
                     pk_date_utils.dt_chr_tsz(i_lang, eip.dt_end, i_prof) || chr(13)) ||
             --desc_status
              t_table_message_array('SOCIAL_T004') || chr(58) || chr(32) ||
              decode(eip.flg_status,
                     pk_alert_constant.g_flg_status_e,
                     pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', pk_alert_constant.g_flg_status_a, i_lang),
                     pk_sysdomain.get_domain('EPIS_INTERV_PLAN.FLG_STATUS', eip.flg_status, i_lang)) || chr(13) ||
             --diagnoses       
             /*CASE
             WHEN l_id_epis_type = pk_alert_constant.g_epis_type_social THEN*/
              t_table_message_array('PARAMEDICAL_T022') || chr(58) || chr(32) ||
              pk_utils.concat_table(pk_paramedical_prof_core.get_desc_epis_diag(i_lang,
                                                                                i_prof,
                                                                                pk_paramedical_prof_core.get_epis_interv_plan_diag(i_lang,
                                                                                                                                   i_prof,
                                                                                                                                   eip.id_epis_interv_plan,
                                                                                                                                   NULL)),
                                    '; ',
                                    1,
                                    -1)
             /*END*/
              || chr(13) ||
             
             --notes
              decode(eip.notes,
                     NULL,
                     NULL,
                     t_table_message_array('SOCIAL_T082') || chr(58) || chr(32) || eip.notes || chr(13))
              INTO l_interv_plan_desc
              FROM epis_interv_plan eip
              JOIN interv_plan ip
                ON ip.id_interv_plan = eip.id_interv_plan
             WHERE eip.id_epis_interv_plan = i_id_epis_interv_plan
               AND eip.flg_status NOT IN (pk_alert_constant.g_cancelled)
             ORDER BY eip.dt_creation DESC;
        
        ELSE
        
            SELECT CASE
                       WHEN eip.id_interv_plan = 0 THEN
                        eip.desc_other_interv_plan
                       WHEN eip.id_interv_plan IS NULL THEN
                        eip.desc_other_interv_plan
                       ELSE
                        pk_translation.get_translation(i_lang, ip.code_interv_plan)
                   END
              INTO l_interv_plan_desc
              FROM epis_interv_plan eip
              JOIN interv_plan ip
                ON ip.id_interv_plan = eip.id_interv_plan
             WHERE eip.id_epis_interv_plan = i_id_epis_interv_plan
               AND eip.flg_status NOT IN (pk_alert_constant.g_cancelled)
             ORDER BY eip.dt_creation DESC;
        
        END IF;
    
        RETURN l_interv_plan_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_interv_plan_desc;

    FUNCTION get_followup_notes_desc
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_management_follow_up IN management_follow_up.id_management_follow_up%TYPE,
        i_flg_description         IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_notes_title    sys_message.desc_message%TYPE;
        l_start_dt_title sys_message.desc_message%TYPE;
        l_time_title     sys_message.desc_message%TYPE;
        l_next_dt_title  sys_message.desc_message%TYPE;
        l_end_followup   sys_message.desc_message%TYPE;
        l_next_dt_enable VARCHAR2(1 CHAR);
        l_opinion_type   opinion_type.id_opinion_type%TYPE;
        l_followup_notes VARCHAR2(4000);
        l_id_episode     episode.id_episode%TYPE;
    BEGIN
    
        l_next_dt_enable := pk_paramedical_prof_core.check_hospital_profile(i_prof => i_prof);
    
        SELECT id_episode
          INTO l_id_episode
          FROM management_follow_up mfu
         WHERE mfu.id_management_follow_up = i_id_management_follow_up;
    
        --    i_ID_EPISODE
        l_opinion_type := pk_paramedical_prof_core.get_id_opinion_type(i_lang    => i_lang,
                                                                       i_prof    => i_prof,
                                                                       i_episode => l_id_episode);
    
        IF i_flg_description = pk_prog_notes_constants.g_desc_type_l
        THEN
        
            l_notes_title := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T103') || chr(58) || chr(32);
        
            l_start_dt_title := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T104') || chr(58) || chr(32);
        
            l_time_title := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T105') || chr(58) || chr(32);
        
            l_next_dt_title := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T154') || chr(58) || chr(32);
        
            l_end_followup := pk_message.get_message(i_lang, i_prof, 'PARAMEDICAL_T023') || chr(58) || chr(32);
        
            g_error := 'OPEN o_follow_up_list';
        
            SELECT to_clob(l_notes_title || nvl(htf.escape_sc(mfu.notes), pk_paramedical_prof_core.c_dashes)) ||
                   chr(13) || l_start_dt_title ||
                   nvl2(mfu.dt_start,
                        pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_start, i_prof),
                        pk_paramedical_prof_core.c_dashes) || chr(13) || l_time_title ||
                   nvl2(mfu.time_spent,
                        pk_paramedical_prof_core.get_format_time_spent(i_lang,
                                                                       pk_paramedical_prof_core.time_spent_convert(i_prof,
                                                                                                                   mfu.id_episode,
                                                                                                                   mfu.id_management_follow_up)),
                        pk_paramedical_prof_core.c_dashes) || chr(13) || l_end_followup ||
                   nvl2(mfu.flg_end_followup,
                        pk_sysdomain.get_domain(pk_list.g_yes_no, mfu.flg_end_followup, i_lang),
                        pk_sysdomain.get_domain(pk_list.g_yes_no, pk_alert_constant.g_no, i_lang)) || chr(13) ||
                   decode(l_next_dt_enable,
                          pk_alert_constant.g_yes,
                          l_next_dt_title || nvl2(mfu.dt_next_encounter,
                                                  pk_paramedical_prof_core.get_partial_date_format(i_lang      => i_lang,
                                                                                                   i_prof      => i_prof,
                                                                                                   i_date      => mfu.dt_next_encounter,
                                                                                                   i_precision => mfu.dt_next_enc_precision),
                                                  pk_paramedical_prof_core.c_dashes))
              INTO l_followup_notes
              FROM management_follow_up mfu
              LEFT JOIN unit_measure um
                ON mfu.id_unit_time = um.id_unit_measure
             WHERE mfu.id_management_follow_up = i_id_management_follow_up
               AND mfu.flg_status = pk_case_management.g_mfu_status_active
               AND (mfu.id_opinion_type = l_opinion_type OR mfu.id_opinion_type IS NULL);
        
        ELSE
        
            l_notes_title := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T103') || chr(32);
        
            SELECT l_notes_title || chr(40) || nvl2(mfu.dt_start,
                                                    pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_start, i_prof),
                                                    pk_paramedical_prof_core.c_dashes) || chr(41)
              INTO l_followup_notes
              FROM management_follow_up mfu
              LEFT JOIN unit_measure um
                ON mfu.id_unit_time = um.id_unit_measure
             WHERE mfu.id_management_follow_up = i_id_management_follow_up
               AND mfu.flg_status = pk_case_management.g_mfu_status_active
               AND (mfu.id_opinion_type = l_opinion_type OR mfu.id_opinion_type IS NULL);
        
        END IF;
    
        RETURN l_followup_notes;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_followup_notes_desc;

BEGIN
    -- Log initialization
    pk_alertlog.who_am_i(g_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_social;
/
