/*-- Last Change Revision: $Rev: 1974697 $*/
/*-- Last Change by: $Author: anna.kurowska $*/
/*-- Date of last change: $Date: 2020-12-21 12:45:25 +0000 (seg, 21 dez 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_dest_reg AS

    g_error         VARCHAR2(4000);
    g_sysdate_tstz  TIMESTAMP WITH TIME ZONE;
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;

    /**
    * Checks if theres a process in the institution that matches the patient
    *
    * ATENTION: This function is used only for simulation purposes.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional id, institution and software
    * @param   I_PAT patient id professional, institution and software ids
    * @param   I_SEQ_NUM external system id
    * @param   I_SNS National Health System number
    * @param   I_NAME patient name
    * @param   I_GENDER patient gender (M, F or I)
    * @param   I_DT_BIRTH patient date of birth                
    * @param   O_DATA_OUT patient data to be returned    
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 3.0
    * @since   30-10-2007
    */
    FUNCTION get_match
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pat      IN patient.id_patient%TYPE,
        i_sns      IN VARCHAR2,
        i_name     IN VARCHAR2,
        i_gender   IN VARCHAR2,
        i_dt_birth IN VARCHAR2,
        o_data_out OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_show  VARCHAR2(1 CHAR);
        l_msg       VARCHAR2(1000 CHAR);
        l_msg_title VARCHAR2(1000 CHAR);
        l_button    VARCHAR2(1 CHAR);
    
        l_crit_id_tab  table_number;
        l_crit_val_tab table_varchar;
    
        l_sc_multi_instit VARCHAR2(1 CHAR);
        l_id_health_plan  health_plan.id_health_plan%TYPE;
        l_id_market       market.id_market%TYPE;
        l_limit           PLS_INTEGER;
        l_params          VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_pat=' || i_pat || ' i_sns=' || i_sns || ' i_gender=' ||
                    i_gender || ' i_dt_birth=' || i_dt_birth;
        g_error  := 'Init get_match / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error           := 'Configs / ' || l_params;
        l_sc_multi_instit := pk_sysconfig.get_config(pk_ref_constant.g_sc_multi_institution, i_prof);
        l_id_health_plan  := pk_ref_utils.get_default_health_plan(i_prof => i_prof);
        l_id_market       := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
        l_limit           := to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_num_record_search, i_prof));
    
        ----------------------
        -- FUNC
        ----------------------
        g_error        := 'MARKET=' || l_id_market || ' LIMIT=' || l_limit || ' / ' || l_params || ' / tabs';
        l_crit_id_tab  := table_number();
        l_crit_val_tab := table_varchar();
    
        -- Tem id 
        IF i_pat IS NOT NULL
        THEN
        
            IF l_id_market = pk_ref_constant.g_market_pt
            THEN
            
                -- PT ACSS
                g_error := 'OPEN o_data_out ' || l_id_market || ' / ' || l_params;
                OPEN o_data_out FOR
                    SELECT t.id_patient,
                           t.name,
                           t.gender,
                           pk_sysdomain.get_domain(pk_ref_constant.g_domain_gender, t.gender, i_lang) desc_gender,
                           pk_date_utils.dt_chr(i_lang, t.dt_birth, i_prof) dt_birth,
                           pk_patient.get_pat_age(i_lang, t.id_patient, i_prof.institution, i_prof.software) pat_age,
                           decode(pk_patphoto.check_blob(t.id_patient),
                                  pk_ref_constant.g_no,
                                  '',
                                  pk_patphoto.get_pat_foto(t.id_patient, i_prof.institution, i_prof.software)) photo,
                           t.address || ' - ' || t.zip_code || ' ' || t.location address,
                           t.num_health_plan,
                           t.sequential_number,
                           t.num_clin_record
                      FROM (SELECT pat.id_patient,
                                   pat.name,
                                   pat.gender,
                                   pat.dt_birth,
                                   psa.address,
                                   psa.zip_code,
                                   psa.location,
                                   php.num_health_plan,
                                   m.sequential_number,
                                   cr.num_clin_record
                              FROM patient pat
                              LEFT JOIN pat_health_plan php
                                ON (pat.id_patient = php.id_patient AND php.id_health_plan = l_id_health_plan AND
                                   php.flg_status = pk_ref_constant.g_active AND
                                   ((php.id_institution = 0 AND l_sc_multi_instit = pk_ref_constant.g_yes) OR
                                   (php.id_institution = i_prof.institution AND
                                   l_sc_multi_instit = pk_ref_constant.g_no)))
                              LEFT JOIN pat_soc_attributes psa
                                ON (pat.id_patient = psa.id_patient AND
                                   ((psa.id_institution = 0 AND l_sc_multi_instit = pk_ref_constant.g_yes) OR
                                   (psa.id_institution = i_prof.institution AND
                                   l_sc_multi_instit = pk_ref_constant.g_no)))
                              LEFT JOIN p1_match m
                                ON (pat.id_patient = m.id_patient AND m.flg_status = pk_ref_constant.g_active AND
                                   m.id_institution = i_prof.institution)
                              LEFT JOIN clin_record cr
                                ON (pat.id_patient = cr.id_patient AND cr.flg_status = pk_ref_constant.g_active AND
                                   cr.id_institution = i_prof.institution AND cr.id_institution = cr.id_instit_enroled)
                             WHERE pat.id_patient = i_pat
                               AND rownum <= 1 + l_limit) t;
            
            ELSE
                -- US
                g_error := 'OPEN o_data_out ' || l_id_market || ' / ' || l_params;
                OPEN o_data_out FOR
                    SELECT t.id_patient,
                           t.name,
                           t.gender,
                           pk_sysdomain.get_domain(pk_ref_constant.g_domain_gender, t.gender, i_lang) desc_gender,
                           pk_date_utils.dt_chr(i_lang, t.dt_birth, i_prof) dt_birth,
                           pk_patient.get_pat_age(i_lang, t.id_patient, i_prof.institution, i_prof.software) pat_age,
                           decode(pk_patphoto.check_blob(t.id_patient),
                                  pk_ref_constant.g_no,
                                  '',
                                  pk_patphoto.get_pat_foto(t.id_patient, i_prof.institution, i_prof.software)) photo,
                           t.address_line1 || ' - ' || t.postal_code || ' ' || t.city_us address,
                           t.num_health_plan,
                           t.sequential_number,
                           t.num_clin_record
                      FROM (SELECT pat.id_patient,
                                   pat.name,
                                   pat.gender,
                                   pat.dt_birth,
                                   vca.address_line1,
                                   vca.postal_code,
                                   vca.city_us,
                                   php.num_health_plan,
                                   m.sequential_number,
                                   cr.num_clin_record
                              FROM patient pat
                              LEFT JOIN pat_health_plan php
                                ON (pat.id_patient = php.id_patient AND php.id_health_plan = l_id_health_plan AND
                                   ((php.id_institution = 0 AND l_sc_multi_instit = pk_ref_constant.g_yes) OR
                                   (php.id_institution = i_prof.institution AND
                                   l_sc_multi_instit = pk_ref_constant.g_no)))
                              LEFT JOIN v_contact_address_us vca
                                ON (vca.id_contact_entity = pat.id_person)
                              LEFT JOIN p1_match m
                                ON (pat.id_patient = m.id_patient AND m.flg_status = pk_ref_constant.g_active AND
                                   m.id_institution = i_prof.institution)
                              LEFT JOIN clin_record cr
                                ON (pat.id_patient = cr.id_patient AND cr.flg_status = pk_ref_constant.g_active AND
                                   cr.id_institution = i_prof.institution)
                             WHERE pat.id_patient = i_pat
                               AND rownum <= 1 + l_limit) t;
            
            END IF;
        
            RETURN TRUE;
        
        ELSIF i_sns IS NOT NULL
        THEN
        
            g_error := 'SNS not null / ' || l_params;
            l_crit_id_tab.extend(1);
            l_crit_val_tab.extend(1);
        
            -- Search by health plan
            l_crit_id_tab(1) := pk_ref_constant.g_crit_pat_sns;
            l_crit_val_tab(1) := i_sns;
        
        ELSE
        
            g_error := 'else / ' || l_params;
            l_crit_id_tab.extend(3);
            l_crit_val_tab.extend(3);
        
            -- Search by name
            l_crit_id_tab(1) := pk_ref_constant.g_crit_pat_name;
            l_crit_val_tab(1) := i_name;
        
            -- Search by date of birth
            l_crit_id_tab(2) := pk_ref_constant.g_crit_pat_dt_birth;
            l_crit_val_tab(2) := to_char(to_date(i_dt_birth, 'YYYY-MM-DD'), pk_ref_constant.g_crit_pat_dt_birth_format);
        
            -- Search by gender
            l_crit_id_tab(3) := pk_ref_constant.g_crit_pat_gender;
            l_crit_val_tab(3) := i_gender;
        
        END IF;
    
        g_error  := 'Call pk_ref_list.get_search_pat / ' || l_params;
        g_retval := pk_ref_list.get_search_pat(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_crit_id_tab   => l_crit_id_tab,
                                               i_crit_val_tab  => l_crit_val_tab,
                                               i_prof_cat_type => pk_ref_constant.g_doctor,
                                               o_flg_show      => l_flg_show,
                                               o_msg           => l_msg,
                                               o_msg_title     => l_msg_title,
                                               o_button        => l_button,
                                               o_pat           => o_data_out,
                                               o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_data_out);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_MATCH',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data_out);
            RETURN FALSE;
    END get_match;

    /**
    * Sets the connection between the patient id and the hospital process
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional id, institution and software
    * @param   I_PAT patient
    * @param   I_SEQ_NUM external system id
    * @param   I_CLIN_REC patient process number on the institution, if available.
    * @param   O_ID_MATCH P1_MATCH identifier
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao S
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION set_match
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pat      IN patient.id_patient%TYPE,
        i_seq_num  IN p1_match.sequential_number%TYPE,
        i_clin_rec IN clin_record.num_clin_record%TYPE,
        i_epis     IN episode.id_episode%TYPE,
        o_id_match OUT p1_match.id_match%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_match IS
            SELECT m.id_match, m.id_clin_record
              FROM p1_match m
             WHERE m.id_patient = i_pat
               AND m.id_institution = i_prof.institution
               AND m.flg_status = pk_ref_constant.g_active
               FOR UPDATE;
    
        l_match_old p1_match.id_match%TYPE;
    
        l_cr       clin_record.id_clin_record%TYPE;
        l_rowids   table_varchar;
        l_id_match p1_match.id_match%TYPE;
    
        l_cr_tab        table_number;
        l_match_old_tab table_number;
        l_params        VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_pat=' || i_pat || ' i_seq_num=' || i_seq_num ||
                    ' i_clin_rec=' || i_clin_rec || ' i_epis=' || i_epis;
        g_error  := 'Init set_match / ' || l_params;
        pk_alertlog.log_debug(g_error);
        --g_sysdate_tstz := current_timestamp;
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        g_error  := 'Call set_clin_record / ' || l_params;
        g_retval := set_clin_record(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_pat          => i_pat,
                                    i_num_clin_rec => i_clin_rec,
                                    i_epis         => i_epis,
                                    o_id_clin_rec  => l_cr,
                                    o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'OPEN C_MATCH / ' || l_params;
        OPEN c_match;
        FETCH c_match BULK COLLECT
            INTO l_match_old_tab, l_cr_tab;
        g_found := c_match%FOUND;
        CLOSE c_match;
    
        g_error := 'l_match_old_tab.COUNT=' || l_match_old_tab.count || ' l_cr_tab.COUNT=' || l_cr_tab.count || ' / ' ||
                   l_params;
        FOR i IN 1 .. l_match_old_tab.count
        LOOP
        
            -- cancelling all active match
            l_rowids := NULL;
        
            g_error := 'Call ts_p1_match.upd / ' || l_params || ' / ID_MATCH=' || l_match_old_tab(i) || ' FLG_STATUS=' ||
                       pk_ref_constant.g_cancelled || ' ID_PROF_CANCEL=' || i_prof.id || ' DT_CANCEL_TSTZ=' ||
                       to_char(g_sysdate_tstz) || ' l_cr_tab(' || i || ')=' || l_cr_tab(i);
            ts_p1_match.upd(id_match_in       => l_match_old_tab(i),
                            flg_status_in     => pk_ref_constant.g_cancelled,
                            id_prof_cancel_in => i_prof.id,
                            dt_cancel_tstz_in => g_sysdate_tstz,
                            rows_out          => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'P1_MATCH',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- inactive this clin_record (if not the active clin_record)
            IF l_cr_tab(i) IS NOT NULL
               AND l_cr IS NOT NULL
               AND l_cr_tab(i) != l_cr
            THEN
                g_error  := 'Call ts_clin_record.upd / ' || l_params || ' / ID_CLIN_RECORD=' || l_cr_tab(i) ||
                            ' NUM_CLIN_RECORD=' || i_clin_rec || ' ID_EPISODE=' || i_epis || ' l_match_old_tab(' || i || ')=' ||
                            l_match_old_tab(i);
                l_rowids := NULL;
                ts_clin_record.upd(id_clin_record_in => l_cr_tab(i),
                                   flg_status_in     => pk_ref_constant.g_inactive,
                                   rows_out          => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CLIN_RECORD',
                                              i_rowids     => SET(l_rowids),
                                              o_error      => o_error);
            
                --2009/05/14 BM: because of ADT, there is the need to update the alert_process_number of pat_identifier
                g_error := 'UPDATE pat_identifier SET alert_process_number=' || i_clin_rec || ' WHERE id_clin_record=' || l_cr ||
                           ' / ' || l_params;
                UPDATE pat_identifier
                   SET flg_status = pk_ref_constant.g_inactive
                 WHERE id_clin_record = l_cr_tab(i);
            
            END IF;
        
        END LOOP;
    
        g_error := 'l_match_old_tab.EXISTS(1) / ' || l_params;
        IF l_match_old_tab.exists(1)
        THEN
            l_match_old := l_match_old_tab(1);
        END IF;
    
        l_rowids   := NULL;
        g_error    := 'ts_p1_match.next_key() / ' || l_params;
        l_id_match := ts_p1_match.next_key();
    
        g_error := 'Call ts_p1_match.ins / ' || l_params || ' ID_MATCH=' || l_id_match || ' ID_CLIN_REC=' || l_cr;
        ts_p1_match.ins(id_match_in          => l_id_match,
                        id_patient_in        => i_pat,
                        id_clin_record_in    => l_cr,
                        id_institution_in    => i_prof.institution,
                        sequential_number_in => i_seq_num,
                        flg_status_in        => pk_ref_constant.g_active,
                        id_prof_create_in    => i_prof.id,
                        dt_create_tstz_in    => g_sysdate_tstz,
                        id_match_prev_in     => l_match_old,
                        id_episode_in        => i_epis,
                        rows_out             => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_MATCH',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF l_match_old_tab.count > 0
        THEN
            -- notify INTER-ALERT (rematch)
            g_error := '---- REFERRAL PATIENT RE-MATCH / ' || l_params;
            pk_ia_event_referral.referral_patient_rematch(i_id_match       => l_id_match,
                                                          i_id_institution => i_prof.institution);
        
        ELSE
            -- notify INTER-ALERT (match)
            g_error := '---- REFERRAL PATIENT MATCH / ' || l_params;
            pk_ia_event_referral.referral_patient_match(i_id_match       => l_id_match,
                                                        i_id_institution => i_prof.institution);
        END IF;
    
        o_id_match := l_id_match;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_MATCH',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_match;

    /**
    * Inserts/updates patient clinical record
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Professional id, institution and software
    * @param   i_pat          Patient identifier
    * @param   i_num_clin_rec Patient process number on the institution, if available.
    * @param   o_id_clin_rec  Id created/updated        
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-12-2009
    */
    FUNCTION set_clin_record
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat          IN patient.id_patient%TYPE,
        i_num_clin_rec IN clin_record.num_clin_record%TYPE,
        i_epis         IN episode.id_episode%TYPE,
        o_id_clin_rec  OUT clin_record.id_clin_record%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cr
        (
            x_pat  IN clin_record.id_patient%TYPE,
            x_inst IN clin_record.id_institution%TYPE
        ) IS
            SELECT cr.id_clin_record
              FROM clin_record cr
             WHERE cr.id_patient = x_pat
               AND cr.id_institution = x_inst
               AND cr.id_instit_enroled = x_inst
               AND cr.flg_status = pk_ref_constant.g_active
             ORDER BY cr.id_clin_record DESC
               FOR UPDATE;
    
        l_rowids       table_varchar;
        l_current_date DATE;
        l_params       VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_pat=' || i_pat || ' i_num_clin_rec=' ||
                    i_num_clin_rec || ' i_epis=' || i_epis;
        g_error  := 'Init set_clin_record / ' || l_params;
        pk_alertlog.log_debug(g_error);
        l_current_date := SYSDATE;
    
        g_error := 'OPEN C_CR / ' || l_params;
        OPEN c_cr(i_pat, i_prof.institution);
        FETCH c_cr
            INTO o_id_clin_rec;
        g_found := c_cr%FOUND;
        CLOSE c_cr;
    
        IF g_found
        THEN
            -- JS: 2008-07-30: Do not update if null, but always create it    
            g_error := 'ID_CLIN_RECORD=' || o_id_clin_rec || ' / ' || l_params;
            IF i_num_clin_rec IS NOT NULL
            THEN
            
                g_error := 'Call ts_clin_record.upd / ID_CLIN_RECORD=' || o_id_clin_rec || ' / ' || l_params;
                ts_clin_record.upd(id_clin_record_in   => o_id_clin_rec,
                                   num_clin_record_in  => i_num_clin_rec,
                                   num_clin_record_nin => FALSE,
                                   id_episode_in       => i_epis,
                                   id_episode_nin      => FALSE,
                                   rows_out            => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CLIN_RECORD',
                                              i_rowids     => SET(l_rowids),
                                              o_error      => o_error);
            
                --2009/05/14 BM: because of ADT, there is the need to update the alert_process_number of pat_identifier
                g_error := 'UPDATE pat_identifier SET alert_process_number=' || i_num_clin_rec ||
                           ' WHERE id_clin_record=' || o_id_clin_rec;
                UPDATE pat_identifier
                   SET alert_process_number = i_num_clin_rec
                 WHERE id_clin_record = o_id_clin_rec;
            
            END IF;
        
        ELSE
            g_error       := 'INSERT INTO clin_record / ' || l_params;
            o_id_clin_rec := ts_clin_record.next_key();
        
            g_error := 'Call ts_clin_record.ins / ID_CLIN_RECORD=' || o_id_clin_rec || ' FLG_STATUS=' ||
                       pk_ref_constant.g_active || ' ID_PATIENT=' || i_pat || ' ID_INSTITUTION=' || i_prof.institution ||
                       ' NUM_CLIN_RECORD=' || i_num_clin_rec || ' ID_INSTIT_ENROLED=' || i_prof.institution ||
                       ' ID_EPISODE=' || i_epis;
            ts_clin_record.ins(id_clin_record_in    => o_id_clin_rec,
                               flg_status_in        => pk_ref_constant.g_active,
                               id_patient_in        => i_pat,
                               id_institution_in    => i_prof.institution,
                               id_pat_family_in     => NULL,
                               num_clin_record_in   => i_num_clin_rec,
                               id_instit_enroled_in => i_prof.institution,
                               id_episode_in        => i_epis,
                               rows_out             => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CLIN_RECORD',
                                          i_rowids     => SET(l_rowids),
                                          o_error      => o_error);
        
            --2009/05/14 BM: because of ADT, there is the need to update the alert_process_number of pat_identifier
            g_error := 'INSERT INTO pat_identifier / ID_CLIN_RECORD=' || o_id_clin_rec || ' / ' || l_params;
            INSERT INTO pat_identifier
                (id_pat_identifier,
                 id_patient,
                 id_institution,
                 alert_process_number,
                 last_update_date,
                 register_date,
                 flg_status,
                 id_clin_record)
            VALUES
                (seq_pat_identifier.nextval,
                 i_pat,
                 i_prof.institution,
                 i_num_clin_rec,
                 l_current_date,
                 l_current_date,
                 pk_ref_constant.g_active,
                 o_id_clin_rec);
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
                                              i_function => 'SET_CLIN_RECORD',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_clin_record;

    /**
    * Cancels match
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_pat patient id 
    * @param   i_prof professional id, institution and software
    * @param   i_id not in use
    * @param   i_id_ext_sys not in use    
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  JoÆo S
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION drop_match
    (
        i_lang       IN language.id_language%TYPE,
        i_pat        IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_id         IN patient.id_patient%TYPE,
        i_id_ext_sys IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids   table_varchar;
        l_where_in VARCHAR2(1000 CHAR);
    BEGIN
        g_error        := 'Init drop_match / ID_PAT=' || i_pat;
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
    
        l_where_in := ' id_patient = ' || i_pat || ' AND id_institution = ' || i_prof.institution ||
                      ' AND flg_status = ' || pk_ref_constant.g_active;
    
        g_error := 'UPDATE P1_MATCH';
        ts_p1_match.upd(flg_status_in     => pk_ref_constant.g_cancelled,
                        id_prof_cancel_in => i_prof.id,
                        dt_cancel_tstz_in => g_sysdate_tstz,
                        where_in          => l_where_in,
                        handle_error_in   => TRUE,
                        rows_out          => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_MATCH',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'DROP_MATCH',
                                              o_error    => o_error);
            RETURN FALSE;
    END drop_match;

    /**
    * Validates if the professional is associated to the dcs provided 
    *
    * @param   i_prof Professional id, institution and software
    * @param   i_dcs dep_clin_serv id
    * @param   i_func functionality id (sys_functionality)
    *
    * @RETURN  Y if true, N otherwise
    * @author  Joao Sa
    * @version 4.0
    * @since   24-11-2007
    */
    FUNCTION validate_dcs
    (
        i_prof IN profissional,
        i_dcs  IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c IS
            SELECT 1 -- any change to this query, remember to change the referral filter base to (VALUE_08)
              FROM prof_dep_clin_serv pdcs
             WHERE pdcs.id_dep_clin_serv = i_dcs
               AND pdcs.id_professional = i_prof.id
               AND pdcs.flg_status = pk_ref_constant.g_selected
               AND rownum <= 1;
    
        l_res PLS_INTEGER;
    BEGIN
        g_error := 'Init validate_dcs / i_prof=' || pk_utils.to_string(i_prof) || ' DCS=' || i_dcs;
        OPEN c;
        FETCH c
            INTO l_res;
        g_found := c%FOUND;
        CLOSE c;
    
        IF g_found
        THEN
            RETURN pk_ref_constant.g_yes;
        ELSE
            RETURN pk_ref_constant.g_no;
        END IF;
    END validate_dcs;

    /**
    * Gets departments available for forwarding the request. 
    *
    * @param   I_LANG          Language associated to the professional executing the request
    * @param   I_PROF          Professional id, institution and software
    * @param   i_ext_req       Referral id
    * @param   o_dep           Department ids and description    
    * @param   O_ERROR         An error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_dep_forward_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_dep     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init get_dep_forward_list / ID_REF=' || i_ext_req;
        OPEN o_dep FOR
            SELECT DISTINCT t.id_department, pk_translation.get_translation(i_lang, t.code_department) dep
              FROM (SELECT d.id_department, d.code_department
                      FROM p1_workflow_config wc
                      JOIN dep_clin_serv dcs
                        ON (wc.code_workflow_config = pk_ref_constant.g_adm_forward_dcs AND
                           dcs.id_dep_clin_serv = to_number(wc.value))
                      JOIN department d
                        ON (d.id_department = dcs.id_department)
                     CROSS JOIN p1_external_request exr
                     WHERE wc.id_institution IN (exr.id_inst_dest, 0)
                       AND wc.id_speciality IN (exr.id_speciality, 0)
                       AND wc.id_inst_dest IN (exr.id_inst_dest, 0)
                       AND wc.id_inst_orig IN (exr.id_inst_orig, 0)
                       AND exr.id_external_request = i_ext_req
                       AND d.id_institution = exr.id_inst_dest) t
             ORDER BY dep;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DEP_FORWARD_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_dep);
            RETURN FALSE;
    END get_dep_forward_list;

    /**
    * Gets clinical_services (the ids are dep_clin_serv) available for forwarding the request. 
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_ext_req       Referral id
    * @param   i_dep           Department id    
    * @param   o_clin_serv     Dep_clin_serv ids and clinical services description    
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_clin_serv_forward_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ext_req   IN p1_external_request.id_external_request%TYPE,
        i_dep       IN department.id_department%TYPE,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_row p1_external_request%ROWTYPE;
    BEGIN
        g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || i_ext_req || ' ID_DEP=' || i_dep;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_ext_req,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'OPEN o_clin_serv / ID_REF=' || i_ext_req || ' ID_DEP=' || i_dep;
        OPEN o_clin_serv FOR
            SELECT DISTINCT t.id_dep_clin_serv id,
                            pk_translation.get_translation(i_lang, t.code_clinical_service) clin_serv
              FROM (SELECT dcs.id_dep_clin_serv, cs.code_clinical_service
                      FROM p1_workflow_config wc
                      JOIN dep_clin_serv dcs
                        ON (dcs.id_dep_clin_serv = to_number(wc.value))
                      JOIN clinical_service cs
                        ON (dcs.id_clinical_service = cs.id_clinical_service)
                     WHERE wc.code_workflow_config = pk_ref_constant.g_adm_forward_dcs
                       AND wc.id_institution IN (l_ref_row.id_inst_dest, 0)
                       AND wc.id_speciality IN (l_ref_row.id_speciality, 0)
                       AND wc.id_inst_dest IN (l_ref_row.id_inst_dest, 0)
                       AND wc.id_inst_orig IN (l_ref_row.id_inst_orig, 0)
                       AND dcs.id_department = i_dep) t
             ORDER BY clin_serv;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_clin_serv);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLIN_SERV_FORWARD_COUNT',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_clin_serv);
            RETURN FALSE;
    END get_clin_serv_forward_list;

    /*
    * Returns institutions info 
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   o_inst          Institutions info
    * @param   o_other         Label Other institution
    * @param   o_error         Error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   14-12-2009
    */
    FUNCTION get_instit_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_inst  OUT pk_types.cursor_type,
        o_other OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_var sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_instit_list / i_prof=' || pk_utils.to_string(i_prof);
        l_var   := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'REF_DETAIL_T024');
    
        OPEN o_inst FOR
            SELECT DISTINCT data.id_institution,
                            nvl(data.abbreviation, pk_translation.get_translation(i_lang, data.code_institution)) abbreviation,
                            pk_translation.get_translation(i_lang, data.code_institution) desc_institution
              FROM (SELECT ist.id_institution, ist.abbreviation, ist.code_institution
                      FROM institution ist, p1_dest_institution pdi
                     WHERE ist.flg_available = pk_ref_constant.g_yes
                       AND (pdi.id_inst_orig = ist.id_institution OR pdi.id_inst_dest = ist.id_institution)
                       AND pdi.flg_type = pk_ref_constant.g_p1_type_c) data
             ORDER BY abbreviation, desc_institution;
    
        OPEN o_other FOR
            SELECT -10 id_institution, '' abbreviation, l_var desc_institution
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
                                              i_function => 'GET_INSTIT_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_inst);
            pk_types.open_my_cursor(o_other);
            RETURN FALSE;
    END get_instit_list;

    /*
    * Get professional data
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_num_order     Professional NUM ORDER 
    * @param   o_prof          Professional data  
    * @param   o_error         Error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   15-12-2009
    */
    FUNCTION get_prof_data
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_num_order IN professional.num_order%TYPE,
        o_prof      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Open o_prof / i_num_order=' || i_num_order;
        OPEN o_prof FOR
            SELECT t.id_professional, pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) prof_name
              FROM (SELECT p.id_professional
                      FROM professional p
                     WHERE p.num_order = i_num_order
                       AND p.flg_state = pk_ref_constant.g_active
                       AND nvl(p.flg_prof_test, pk_ref_constant.g_no) = pk_ref_constant.g_no
                       AND EXISTS (SELECT 1
                              FROM prof_cat pc
                             WHERE pc.id_professional = p.id_professional
                               AND pc.id_category = pk_ref_constant.g_cat_id_med)) t
             ORDER BY prof_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_DATA',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_prof);
            RETURN FALSE;
    END get_prof_data;

    /**
    * Returns the Sequencial Number of the p1_match table for the specified patient
    * and the num_clin_record for the patient on the specific institution
    *
    * @param   i_lang           Language id
    * @param   i_prof           Professional, institution, software
    * @param   i_old_inst_dest  Id of the old institution
    * @param   i_patient        Department id
    * @param   o_seq_num        Sequencial Number 
    * @param   o_num_clin_rec   Clinical Record Number
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   13-07-2010
    */
    FUNCTION check_match
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_old_inst_dest IN institution.id_institution%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        o_seq_num       OUT p1_match.sequential_number%TYPE,
        o_num_clin_rec  OUT clin_record.num_clin_record%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_match(i_inst IN institution.id_institution%TYPE) IS
            SELECT m.sequential_number, cr.num_clin_record
              FROM p1_match m
              JOIN clin_record cr
                ON (m.id_clin_record = cr.id_clin_record AND m.flg_status = pk_ref_constant.g_match_status_a)
             WHERE m.id_patient = i_patient
               AND m.id_institution = i_inst;
    BEGIN
    
        g_error := 'OPEN C_MATCH NEW DEST INSTITUTION / i_old_inst_dest=' || i_old_inst_dest || ' i_patient=' ||
                   i_patient;
        OPEN c_match(i_prof.institution);
        FETCH c_match
            INTO o_seq_num, o_num_clin_rec;
        g_found := c_match%FOUND;
        CLOSE c_match;
    
        IF NOT g_found
        THEN
            OPEN c_match(i_old_inst_dest);
            FETCH c_match
                INTO o_seq_num, o_num_clin_rec;
            g_found := c_match%FOUND;
            CLOSE c_match;
        
            RETURN FALSE;
        
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
                                              i_function => 'CHECK_MATCH',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_match;

BEGIN
    -- Log initialization  
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ref_dest_reg;
/
