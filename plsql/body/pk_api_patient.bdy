/*-- Last Change Revision: $Rev: 1655187 $*/
/*-- Last Change by: $Author: mario.mineiro $*/
/*-- Date of last change: $Date: 2014-11-01 00:23:40 +0000 (sÃ¡b, 01 nov 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_patient IS
    /*
    * return patients short name.
    *
    * @param   i_id_pat            patient identifier
    *
    * @return  patient short name, null if not available
    *
    * @author  rui spratley
    * @version 2.4.3
    * @since   2008/05/23
    *
    */
    FUNCTION intf_get_pat_short_name(i_id_pat IN patient.id_patient%TYPE) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_patient.get_pat_short_name(i_id_pat => i_id_pat);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END intf_get_pat_short_name;

    /*
    * cancel patients allergy.
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_id_pat_allergy    patients allergy identifier
    * @param   i_id_prof           profissional
    * @param   i_notes             notes
    * @param   o_error             error message
    *
    * @return                    true if everything was ok. false otherwise.
    *
    * @author  rui spratley
    * @version 2.4.3
    * @since   2008/05/23
    *
    */
    FUNCTION intf_cancel_pat_allergy
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_prof           IN profissional,
        i_notes          IN pat_allergy.notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_patient.call_cancel_pat_allergy(i_lang           => i_lang,
                                                  i_id_pat_allergy => i_id_pat_allergy,
                                                  i_prof           => i_prof,
                                                  i_notes          => i_notes,
                                                  o_error          => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_log_object_owner,
                                              i_package  => g_log_object_name,
                                              i_function => 'INTF_CANCEL_PAT_ALLERGY',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_cancel_pat_allergy;

    /*
    * create patients allergy records.
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_epis              patients allergy identifier
    * @param   i_prof              Profissional
    * @param   i_allergy           Allergy
    * @param   i_allergy_cancel    Allergy to cancel
    * @param   i_status            Status: A-Active; C-Canceled; P-Passive
    * @param   i_notes             notes
    * @param   i_dt_symptoms       Aprox. date of problem start. String with format YYYY-MM-DD that is converted after.
    * @param   i_type              I - reacção idiossincrática, A - allergy
    * @param   i_approved          U-Related by patient / M-Clinicaly comproved
    * @param   i_prof_cat_type     Professional category
    * @param   o_flg_show          Shows message (Y/N)
    * @param   o_msg_title         Title to show if o_flg_show=Y
    * @param   o_msg               Text to show if o_flg_show=Y
    * @param   o_button            button to show: N-No; R-Read; C-Confirmed. Can also show combinations of more than one button
    * @param   o_error             error message
    *
    * @return                    true if everything was ok. false otherwise.
    *
    * @author  rui spratley
    * @version 2.4.3
    * @since   2008/05/23
    *
    */
    FUNCTION intf_create_pat_allergy_array
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_allergy.id_patient%TYPE,
        i_prof           IN profissional,
        i_allergy        IN table_number,
        i_allergy_cancel IN table_number,
        i_status         IN table_varchar,
        i_notes          IN table_varchar,
        i_dt_symptoms    IN table_varchar,
        i_type           IN table_varchar,
        i_approved       IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_patient.call_create_pat_allergy_array(i_lang           => i_lang,
                                                        i_epis           => i_epis,
                                                        i_pat            => i_pat,
                                                        i_prof           => i_prof,
                                                        i_allergy        => i_allergy,
                                                        i_allergy_cancel => i_allergy_cancel,
                                                        i_status         => i_status,
                                                        i_notes          => i_notes,
                                                        i_dt_symptoms    => i_dt_symptoms,
                                                        i_type           => i_type,
                                                        i_approved       => i_approved,
                                                        i_prof_cat_type  => i_prof_cat_type,
                                                        o_flg_show       => o_flg_show,
                                                        o_msg_title      => o_msg_title,
                                                        o_msg            => o_msg,
                                                        o_button         => o_button,
                                                        o_error          => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_log_object_owner,
                                              i_package  => g_log_object_name,
                                              i_function => 'INTF_CREATE_PAT_ALLERGY_ARRAY',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_create_pat_allergy_array;

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
    * @author                      Paulo Fonseca
    * @since                       2009/05/28
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
        l_message                debug_msg;
        l_inst_type_primary_care PLS_INTEGER;
        l_dt_begin CONSTANT patient_care_inst.dt_begin_tstz%TYPE := nvl(i_dt_begin, current_timestamp);
    
    BEGIN
        -- If it's not a primary care institution don't do nothing
        l_message := 'COUNT INST_TYPE_PRIMARY_CARE';
        SELECT COUNT(0)
          INTO l_inst_type_primary_care
          FROM institution
         WHERE flg_type = pk_alert_constant.g_inst_type_primary_care
           AND id_institution = i_institution;
    
        IF l_inst_type_primary_care = 0
        THEN
            RETURN TRUE;
        END IF;
    
        -- If the reason type isn't configured don't do nothing
        l_message := 'GET CREATE_INSTITUTION_REASON';
        IF pk_sysconfig.get_config(i_code_cf   => 'CREATE_INSTITUTION_REASON.' || nvl(i_reason_type, 0),
                                   i_prof_inst => i_institution,
                                   i_prof_soft => pk_alert_constant.g_soft_primary_care) IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        -- Update PATIENT_CARE_INST
        l_message := 'DELETE PATIENT_CARE_INST';
        DELETE patient_care_inst
         WHERE id_patient = i_patient;
    
        l_message := 'INSERT INTO PATIENT_CARE_INST';
        INSERT INTO patient_care_inst
            (id_patient, id_institution, reason_type, reason, dt_begin_tstz, id_institution_enroled)
        VALUES
            (i_patient, i_institution, i_reason_type, i_reason, l_dt_begin, i_institution_enroled);
    
        -- UPDATE PATIENT_CARE_INST_HISTORY
        l_message := 'UPDATE PATIENT_CARE_INST_HISTORY';
        UPDATE patient_care_inst_history
           SET dt_end_tstz = l_dt_begin
         WHERE dt_end_tstz IS NULL
           AND id_patient = i_patient;
    
        l_message := 'INSERT PATIENT_CARE_INST_HISTORY';
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
                                              i_message  => l_message,
                                              i_owner    => g_log_object_owner,
                                              i_package  => g_log_object_name,
                                              i_function => 'INTF_UPDATE_PATIENT_CARE_INST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_update_patient_care_inst;

    /********************************************************************************************
    * Create patient family.
    *
    * i_lang                   language id
    * i_id_professional        professional id
    * i_id_institution         institution id
    * i_id_software            software id
    * i_num_clin_record        clin record id
    * i_id_instit_enroled      institution enroled id
    * i_id_prof_family         professional family id
    * i_complete_name          complete name
    * i_address                address
    * i_postal_code            postal code
    * i_city                   city
    * i_id_patient             patient id
    * i_episode                episode id
    * i_num_family_record      family record number
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Sérgio Santos (based on pk_pfh_interface.create_family)
    * @since                       2009/05/29
    * @version                     2.5
    ********************************************************************************************/
    FUNCTION intf_create_pat_family
    (
        i_lang              IN language.id_language%TYPE,
        i_id_professional   IN professional.id_professional%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_software       IN software.id_software%TYPE,
        i_num_clin_record   IN clin_record.num_clin_record%TYPE,
        i_id_instit_enroled IN clin_record.id_instit_enroled%TYPE,
        i_id_prof_family    IN pat_family_prof.id_professional%TYPE,
        i_complete_name     IN patient.name%TYPE,
        i_address           IN pat_soc_attributes.address%TYPE,
        i_postal_code       IN pat_soc_attributes.zip_code%TYPE,
        i_city              IN pat_soc_attributes.location%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_num_family_record IN pat_family.num_family_record%TYPE,
        o_id_pat_family     OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         CONSTANT obj_name := 'INTF_CREATE_PAT_FAMILY';
        l_sysdate           CONSTANT pat_family.adw_last_update%TYPE := SYSDATE;
        l_current_timestamp CONSTANT pat_family_prof.dt_begin_tstz%TYPE := current_timestamp;
        l_found   BOOLEAN;
        l_message debug_msg;
    
        l_name                      pat_family.name%TYPE;
        l_num                       PLS_INTEGER;
        l_id_pat_family             pat_family.id_pat_family%TYPE;
        l_next_pat_fam              pat_family.id_pat_family%TYPE;
        l_next_pat_f_prof           pat_family_prof.id_pat_family_prof%TYPE;
        l_next_pat_f_member         pat_family_member.id_pat_family_member%TYPE;
        l_rowids_pfp                table_varchar := table_varchar();
        l_rowids_pfm                table_varchar := table_varchar();
        l_id_pat_family_member      pat_family_member.id_pat_family_member%TYPE;
        l_id_pat_family_institution pat_family_member.id_institution%TYPE;
        l_id_pat_family_prof        pat_family_prof.id_pat_family_prof%TYPE;
        l_id_patient                patient.id_patient%TYPE;
    
        -- PAT_FAMILY_MEMBER
        CURSOR c_pat_family_member IS
            SELECT pfm.id_pat_family_member, pfm.id_institution
              FROM pat_family_member pfm
             WHERE pfm.id_patient = i_id_patient
               AND pfm.id_pat_family = o_id_pat_family
               AND pfm.id_institution IN (i_id_institution, -1)
               AND pfm.flg_status = pk_alert_constant.g_active;
    
        -- PAT_FAMILY_PROF
        CURSOR c_pat_family_prof IS
            SELECT pfp.id_pat_family_prof
              FROM pat_family_prof pfp
             WHERE pfp.id_pat_family = o_id_pat_family
               AND pfp.id_institution = i_id_instit_enroled
                  --AND pfp.id_episode = nvl(i_episode, -1)
               AND pfp.id_professional = i_id_prof_family
               AND pfp.id_patient = i_id_patient
               AND pfp.flg_status = pk_alert_constant.g_active;
    
        CURSOR c_pat_family IS
            SELECT DISTINCT pat.id_pat_family
              FROM patient pat, clin_record cr, pat_family pf
             WHERE pat.id_patient = cr.id_patient
               AND cr.num_clin_record = i_num_clin_record
               AND cr.id_institution = i_id_institution
               AND cr.id_instit_enroled = i_id_instit_enroled
               AND cr.id_pat_family = pf.id_pat_family
                  --AND cr.id_patient = i_id_patient
               AND cr.flg_status = pk_alert_constant.g_active;
    
        CURSOR c_clin_rec_pat IS
            SELECT DISTINCT cr.id_patient
              FROM clin_record cr
             WHERE cr.id_patient = i_id_patient
               AND cr.flg_status = pk_alert_constant.g_active;
    
        CURSOR c_patient_profissional IS
            SELECT pfp.id_pat_family_prof, pfp.id_pat_family, pfp.id_institution, pfp.id_professional
              FROM pat_family_prof pfp
             WHERE pfp.id_patient = i_id_patient
               AND pfp.flg_status = pk_alert_constant.g_active;
        rec_patient_professional c_patient_profissional%ROWTYPE;
    BEGIN
        IF i_num_clin_record IS NULL
        THEN
            RETURN TRUE;
        ELSE
            ------------------------------------------------------------------------
            --Inactiva os médicos de familia anteriormente associados na instituição em causa
            --para aquele paciente
            FOR rec_patient_professional IN c_patient_profissional
            LOOP
                IF (i_id_instit_enroled IS NOT NULL)
                -- AND (i_id_prof_family IS NOT NULL) -- by orders provided by the interfaces team, when i_id_prof_family is null we remove the family doctor
                THEN
                    UPDATE pat_family_prof pfp
                       SET pfp.flg_status = pk_alert_constant.g_inactive, pfp.dt_end_tstz = l_current_timestamp
                     WHERE pfp.id_pat_family_prof = rec_patient_professional.id_pat_family_prof;
                END IF;
            END LOOP;
        
            l_message := 'OPEN C_PAT_FAMILY';
            pk_alertlog.log_debug(l_message, g_log_object_name);
            OPEN c_pat_family;
            FETCH c_pat_family
                INTO l_id_pat_family;
            l_found := c_pat_family%FOUND;
            CLOSE c_pat_family;
        
            ------------------------------------------------------------------------
            IF NOT l_found
               OR l_id_pat_family IS NULL
            THEN
                -- Paciente SEM FAMÍLIA
                pk_alertlog.log_debug('Paciente SEM FAMÍLIA', g_log_object_name);
                l_name := i_complete_name;
                --
                IF l_name IS NOT NULL
                THEN
                    -- Encontrar o APELIDO do paciente
                    pk_alertlog.log_debug('Encontrar o APELIDO do paciente', g_log_object_name);
                    LOOP
                        l_name := substr(l_name, instr(l_name, chr(32)) + 1);
                        l_num  := instr(l_name, chr(32));
                        --
                        IF l_num = 0
                        THEN
                            EXIT;
                        ELSIF l_num IS NULL
                        THEN
                            l_name := i_complete_name;
                            EXIT;
                        END IF;
                    END LOOP;
                END IF;
                --
                l_message := 'GET SEQ_PAT_FAMILY.NEXTVAL';
                pk_alertlog.log_debug(l_message, g_log_object_name);
                SELECT seq_pat_family.nextval
                  INTO l_next_pat_fam
                  FROM dual;
                --
                l_message := 'INSERT PAT_FAMILY';
                pk_alertlog.log_debug(l_message, g_log_object_name);
            
                ts_pat_family.ins(id_pat_family_in     => l_next_pat_fam,
                                  name_in              => l_name,
                                  address_in           => i_address,
                                  zip_code_in          => i_postal_code,
                                  location_in          => i_city,
                                  id_institution_in    => i_id_institution,
                                  id_instit_enroled_in => i_id_instit_enroled,
                                  adw_last_update_in   => l_sysdate,
                                  num_family_record_in => i_num_family_record);
            
                l_message := 'OPEN c_clin_rec_pat';
                pk_alertlog.log_debug(l_message, g_log_object_name);
                OPEN c_clin_rec_pat;
                FETCH c_clin_rec_pat
                    INTO l_id_patient;
                l_found := c_clin_rec_pat%FOUND;
                CLOSE c_clin_rec_pat;
            
                IF l_found
                THEN
                    UPDATE clin_record cr
                       SET cr.id_pat_family = l_next_pat_fam
                     WHERE cr.num_clin_record = i_num_clin_record
                       AND cr.id_patient = i_id_patient;
                
                    UPDATE patient p
                       SET p.id_pat_family = l_next_pat_fam
                     WHERE p.id_patient = i_id_patient;
                END IF;
            
                o_id_pat_family := l_next_pat_fam;
            ELSE
                ts_pat_family.upd(id_pat_family_in     => l_id_pat_family,
                                  name_in              => l_name,
                                  address_in           => i_address,
                                  zip_code_in          => i_postal_code,
                                  location_in          => i_city,
                                  id_institution_in    => i_id_institution,
                                  id_instit_enroled_in => i_id_instit_enroled,
                                  adw_last_update_in   => l_sysdate,
                                  num_family_record_in => i_num_family_record);
            
                o_id_pat_family := l_id_pat_family;
            
            END IF;
        
            ------------------------------------------------------------------------
            -- PAT_FAMILY_PROF
            l_message := 'OPEN C_PAT_FAMILY_PROF';
            pk_alertlog.log_debug(l_message, g_log_object_name);
            OPEN c_pat_family_prof;
            FETCH c_pat_family_prof
                INTO l_id_pat_family_prof;
            l_found := c_pat_family_prof%FOUND;
            CLOSE c_pat_family_prof;
        
            IF NOT l_found
               OR l_id_pat_family_prof IS NULL
            THEN
                IF (i_id_instit_enroled IS NOT NULL)
                   AND (i_id_prof_family IS NOT NULL)
                THEN
                    l_message         := 'GET SEQ_PAT_FAMILY_PROF.NEXTVAL';
                    l_next_pat_f_prof := ts_pat_family_prof.next_key();
                
                    l_message := 'INSERT PAT_FAMILY_PROF';
                
                    ts_pat_family_prof.ins(id_pat_family_prof_in => l_next_pat_f_prof,
                                           id_pat_family_in      => o_id_pat_family,
                                           id_institution_in     => i_id_instit_enroled,
                                           id_professional_in    => i_id_prof_family,
                                           dt_begin_tstz_in      => l_current_timestamp,
                                           id_episode_in         => nvl(i_episode, -1),
                                           id_patient_in         => i_id_patient,
                                           rows_out              => l_rowids_pfp);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => profissional(i_id_professional,
                                                                               i_id_institution,
                                                                               i_id_software),
                                                  i_table_name => 'PAT_FAMILY_PROF',
                                                  i_rowids     => l_rowids_pfp,
                                                  o_error      => o_error);
                END IF;
            END IF;
        
            ------------------------------------------------------------------------
            -- PAT_FAMILY_MEMBER
            l_message := 'OPEN C_PAT_FAMILY_MEMBER';
            pk_alertlog.log_debug(l_message, g_log_object_name);
            OPEN c_pat_family_member;
            FETCH c_pat_family_member
                INTO l_id_pat_family_member, l_id_pat_family_institution;
            l_found := c_pat_family_member%FOUND;
            CLOSE c_pat_family_member;
        
            IF NOT l_found
               OR l_id_pat_family_member IS NULL
            THEN
                l_message           := 'GET SEQ_PAT_FAMILY_MEMBER.NEXTVAL';
                l_next_pat_f_member := ts_pat_family_member.next_key();
            
                l_message := 'INSERT INTO PAT_FAMILY_MEMBER';
                ts_pat_family_member.ins(id_pat_family_member_in => l_next_pat_f_member,
                                         id_pat_family_in        => o_id_pat_family,
                                         id_institution_in       => i_id_institution,
                                         id_patient_in           => i_id_patient,
                                         flg_status_in           => pk_alert_constant.g_active,
                                         id_episode_in           => nvl(i_episode, -1),
                                         rows_out                => l_rowids_pfm);
            
                l_message := 'UPDATES T_DATA_GOV_MNT - INSERT ON PAT_FAMILY_MEMBER';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => profissional(i_id_professional,
                                                                           i_id_institution,
                                                                           i_id_software),
                                              i_table_name => 'PAT_FAMILY_MEMBER',
                                              i_rowids     => l_rowids_pfm,
                                              o_error      => o_error);
            ELSIF (i_id_institution != -1 OR i_id_institution IS NOT NULL) -- a instituição não estava definida apesar de a familia estar criada
                  AND l_id_pat_family_institution != i_id_institution -- actualizar portanto para a instituição passado por parâmetro
            THEN
                l_message := 'UPDATE PAT_FAMILY_MEMBER';
                ts_pat_family_member.upd(id_pat_family_member_in => l_id_pat_family_member,
                                         id_institution_in       => i_id_institution,
                                         rows_out                => l_rowids_pfm);
            
                l_message := 'UPDATES T_DATA_GOV_MNT - UPDATE PAT_FAMILY_MEMBER';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => profissional(i_id_professional,
                                                                           i_id_institution,
                                                                           i_id_software),
                                              i_table_name => 'PAT_FAMILY_MEMBER',
                                              i_rowids     => l_rowids_pfm,
                                              o_error      => o_error);
            END IF;
        
            RETURN TRUE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_log_object_owner,
                                              i_package  => g_log_object_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_create_pat_family;

    /************************************************************************************************************
    * This function patient blood type
    *
    * @param      i_lang            Prefered language
    * @param      i_epis            Episode id
    * @param      i_id_pat          Patient id
    * @param      i_flg_group       Blood group
    * @param      i_flg_rh          Rhesus factor
    * @param      i_desc_other      Other information
    * @param      i_prof            Profissional, institution and software id's
    * @param      i_prof_cat_type   Professional category
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Fonseca
    * @version    2.5.0
    * @since      2010/01/19
    ************************************************************************************************************/
    FUNCTION intf_set_pat_blood
    (
        i_lang          IN language.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_flg_group     IN pat_blood_group.flg_blood_group%TYPE,
        i_flg_rh        IN pat_blood_group.flg_blood_rhesus%TYPE,
        i_desc_other    IN pat_blood_group.desc_other_system%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN intf_set_pat_blood(i_lang               => i_lang,
                                  i_epis               => i_epis,
                                  i_id_pat             => i_id_pat,
                                  i_flg_group          => i_flg_group,
                                  i_flg_rh             => i_flg_rh,
                                  i_desc_other         => i_desc_other,
                                  i_prof               => i_prof,
                                  i_prof_cat_type      => i_prof_cat_type,
                                  i_dt_pat_blood_group => NULL,
                                  o_error              => o_error);
    END intf_set_pat_blood;

    /************************************************************************************************************
    * This function patient blood type
    *
    * @param      i_lang            Prefered language
    * @param      i_epis            Episode id
    * @param      i_id_pat          Patient id
    * @param      i_flg_group       Blood group
    * @param      i_flg_rh          Rhesus factor
    * @param      i_desc_other      Other information
    * @param      i_prof            Profissional, institution and software id's
    * @param      i_prof_cat_type   Professional category
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Fonseca
    * @version    2.5.0
    * @since      2010/01/19
    ************************************************************************************************************/
    FUNCTION intf_set_pat_blood
    (
        i_lang               IN language.id_language%TYPE,
        i_epis               IN episode.id_episode%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_flg_group          IN pat_blood_group.flg_blood_group%TYPE,
        i_flg_rh             IN pat_blood_group.flg_blood_rhesus%TYPE,
        i_desc_other         IN pat_blood_group.desc_other_system%TYPE,
        i_prof               IN profissional,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_pat_blood_group IN pat_blood_group.dt_pat_blood_group_tstz%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_patient.set_pat_blood_int(i_lang               => i_lang,
                                            i_epis               => i_epis,
                                            i_id_pat             => i_id_pat,
                                            i_flg_group          => i_flg_group,
                                            i_flg_rh             => i_flg_rh,
                                            i_desc_other         => i_desc_other,
                                            i_prof               => i_prof,
                                            i_prof_cat_type      => i_prof_cat_type,
                                            i_dt_pat_blood_group => i_dt_pat_blood_group,
                                            o_error              => o_error);
    END intf_set_pat_blood;

    /************************************************************************************************************
    * Return the patient active health plan
    *
    * @param      i_lang            Prefered language
    * @param      i_epis            Episode id
    * @param      i_id_pat          Patient id
    * @param      i_prof            Profissional, institution and software id's
    *
    * @param      o_hplan           Health plan info
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Sérgio Santos
    * @version    2.5.0.7.8
    * @since      2010/05/05
    ************************************************************************************************************/
    FUNCTION intf_get_pat_hplan
    (
        i_lang        IN language.id_language%TYPE,
        i_epis        IN episode.id_episode%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_hplan_out   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT obj_name := 'INTF_CREATE_PAT_FAMILY';
        l_message debug_msg;
    BEGIN
        l_message := 'O_HPLAN_OUT';
        OPEN o_hplan_out FOR
            SELECT *
              FROM (SELECT php.id_pat_health_plan,
                           php.id_health_plan,
                           hp.code_health_plan,
                           pk_translation.get_translation(i_lang, hp.code_health_plan) desc_health_plan,
                           php.dt_health_plan,
                           php.num_health_plan,
                           php.flg_status,
                           hp.flg_type,
                           hp.flg_instit_type,
                           php.barcode,
                           php.flg_default,
                           php.id_institution,
                           hp.insurance_class,
                           decode(ehp.id_episode, i_epis, 1, 0) in_use_epis,
                           decode(php.flg_default, pk_alert_constant.g_yes, 1, 0) in_use
                      FROM pat_health_plan php
                      LEFT JOIN epis_health_plan ehp
                        ON php.id_pat_health_plan = ehp.id_pat_health_plan
                      JOIN health_plan hp
                        ON hp.id_health_plan = php.id_health_plan
                     WHERE php.id_patient = i_id_pat
                       AND php.id_institution IN
                           (SELECT *
                              FROM TABLE(pk_list.tf_get_all_inst_group(i_institution,
                                                                       pk_ehr_access.g_inst_grp_flg_rel_adt)))
                          
                       AND php.flg_status = pk_edis_proc.g_hplan_active
                       AND (ehp.id_episode IS NULL OR ehp.id_episode = i_epis)
                     ORDER BY in_use_epis DESC, in_use DESC) t
             WHERE rownum = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_log_object_owner,
                                              i_package  => g_log_object_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END intf_get_pat_hplan;

    /*
    * Update patient with the new id patient
    *
    * @param   i_old_id_patient    
    * @param   i_new_id_patient    
    * @param   o_error             error message
    *
    * @return                    true if everything was ok. false otherwise.
    *
    * @author  Mário Mineiro
    * @version 2.6.3.10.1
    * @since   2008/05/23
    *
    */
    FUNCTION intf_update_patient
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_old_id_patient IN patient.id_patient%TYPE,
        i_new_id_patient IN patient.id_patient%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT obj_name := 'INTF_CREATE_PAT_FAMILY';
        l_message debug_msg;
    
        -- denormalization variables
        l_rowids table_varchar;
    
    BEGIN
    
        IF i_old_id_patient = i_new_id_patient
        THEN
            RETURN TRUE;
        ELSIF nvl(i_old_id_patient, i_new_id_patient) IS NULL
        THEN
            g_error := 'INVALID INPUT';
            RAISE g_exception;
        END IF;
    
        g_error  := 'UPDATE EPISODE';
        l_rowids := table_varchar();
        -- update episode
        ts_episode.upd(id_patient_in  => i_new_id_patient,
                       id_patient_nin => FALSE,
                       where_in       => 'id_patient = ' || i_old_id_patient,
                       rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
        g_error := 'UPDATE VISIT';
        -- update visit    
        ts_visit.upd(id_patient_in  => i_new_id_patient,
                     id_patient_nin => FALSE,
                     where_in       => 'id_patient = ' || i_old_id_patient,
                     rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'VISIT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'UPDATE VISIT';
        -- update epis_info                                     
        ts_epis_info.upd(id_patient_in  => i_new_id_patient,
                         id_patient_nin => FALSE,
                         where_in       => 'id_patient = ' || i_old_id_patient,
                         rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_INFO',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_log_object_owner,
                                              i_package  => g_log_object_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    FUNCTION get_patient_profs
    (
        i_id_institution IN NUMBER,
        i_id_patient     IN sch_group.id_patient%TYPE,
        o_result         OUT t_search_profs,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list      pk_types.cursor_type;
        l_prof_resp pk_types.cursor_type;
    
        l_lang  NUMBER := 2; -- nvl(pk_sysconfig.get_config(i_code_cf => 'CDS_FIRE_SAME_USER_ELEM', i_prof => i_prof),                              pk_alert_constant.g_no)
        l_prof  profissional := profissional(0, i_id_institution, 1);
        l_scope VARCHAR2(2) := pk_hand_off.g_patient_scope;
    
        -- fetch l_list
        l_list_id   table_number;
        l_list_name table_varchar2;
    
        -- fetch l_prof_resp        
        l_ho_id          table_number;
        l_ho_name        table_varchar2;
        l_ho_institution table_number;
        l_ho_software    table_number;
    
        l_row t_search_prof := t_search_prof(NULL, NULL);
        l_add BOOLEAN := TRUE;
    
        PROCEDURE inner_add_row(i_rou t_search_prof) IS
        BEGIN
            o_result.extend;
            o_result(o_result.last) := i_rou;
        END inner_add_row;
    
    BEGIN
        o_result := t_search_profs();
        -- get prof list from schedule
        IF NOT pk_schedule.get_patient_scheds(i_lang       => l_lang,
                                              i_prof       => l_prof,
                                              i_id_patient => i_id_patient,
                                              o_list       => l_list,
                                              o_error      => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
        -- fetch
        FETCH l_list BULK COLLECT
            INTO l_list_id, l_list_name;
        CLOSE l_list;
    
        FOR i IN 1 .. l_list_id.count
        LOOP
        
            l_row.id   := l_list_id(i);
            l_row.name := l_list_name(i);
            inner_add_row(l_row);
        
        END LOOP;
    
        -- get hand off prof responsibles
        IF NOT pk_hand_off.get_prof_responsibles(i_lang      => l_lang,
                                                 i_prof      => l_prof,
                                                 i_scope     => l_scope,
                                                 i_id_scope  => i_id_patient,
                                                 o_prof_resp => l_prof_resp,
                                                 o_error     => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        -- fetch
        FETCH l_prof_resp BULK COLLECT
            INTO l_ho_id, l_ho_name, l_ho_institution, l_ho_software;
        CLOSE l_prof_resp;
    
        FOR i IN 1 .. l_ho_id.count
        LOOP
            -- control to merge apis, remove duplicated profissionals
            l_add := TRUE;
            FOR x IN 1 .. l_list_id.count
            LOOP
                IF l_ho_id(i) = l_list_id(x)
                THEN
                    l_add := FALSE;
                    EXIT;
                END IF;
            END LOOP;
        
            IF l_add
            THEN
                l_row.id   := l_ho_id(i);
                l_row.name := l_ho_name(i);
                inner_add_row(l_row);
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_log_object_owner,
                                              i_package  => g_log_object_name,
                                              i_function => 'GET_PATIENT_PROFS',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_patient_profs;

BEGIN
    -- Logging mechanism
    pk_alertlog.who_am_i(g_log_object_owner, g_log_object_name);
    pk_alertlog.log_init(g_log_object_name);
END pk_api_patient;
/
