/*-- Last Change Revision: $Rev: 2026875 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:16 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_clinical_info IS

    g_package_name VARCHAR2(32);
    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
        o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                   i_func_proc_name;
        pk_alertlog.log_error(i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror, g_package_name);
        RETURN FALSE;
    END error_handling;

    /********************************************************************************************
    * Criar queixa / anamnese 
    * Internal function (does not commit).
    *
    * @param i_lang                 id da lingua
    * @param i_episode              episode id
    * @param i_prof                 objecto com info do utilizador
    * @param i_desc                 descrição da queixa / anamnese 
    * @param i_flg_type             C  - queixa ; A - anamnese
    * @param i_flg_type_mode        type of edition
    * @param i_id_epis_anamnesis    Episódio da queixa/historia 
    * @param i_id_diag              ID do diagnóstico associado ao texto + freq.seleccionado para registo da queixa / história 
    * @param i_flg_class            A - motivo administrativo de consulta (CARE: texto + freq. do ICPC2)
    * @param i_prof_cat_type        Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF
    * @param i_flg_rep_by           record reported by
    * @param i_dt_epis_anamnesis_tstz    Date/Time of Admition
    * @param o_id_epis_anamnesis    registo           
    * @param o_error                Error message
    * 
    * @value i_flg_type_mode        {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    * @return                       true or false on success or error
    * 
    * @author                       Claudia Silva
    * @version                      1.0
    * @since                        2005/03/04 
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/05/08
    *                             Added new edit options: Update from previous assessment; No changes;
    * Changed:
    *                             Elisabete bugalho
    *                             2009/03/20
    *                             Ignore the codification of reason of visit and deactivate previous 
    *                             anamnesis, depending on the configuration (OUTP, PP-PT)
    ********************************************************************************************/
    FUNCTION set_epis_anamnesis_int
    (
        i_lang                   IN language.id_language%TYPE,
        i_episode                IN epis_anamnesis.id_episode%TYPE,
        i_prof                   IN profissional,
        i_desc                   IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_flg_type               IN epis_anamnesis.flg_type%TYPE,
        i_flg_type_mode          IN epis_anamnesis.flg_edition_type%TYPE,
        i_id_epis_anamnesis      IN epis_anamnesis.id_epis_anamnesis%TYPE,
        i_id_diag                IN epis_anamnesis.id_diagnosis%TYPE,
        i_flg_class              IN epis_anamnesis.flg_class%TYPE,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_rep_by             IN epis_anamnesis.flg_reported_by%TYPE,
        i_dt_epis_anamnesis_tstz IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE DEFAULT NULL,
        o_id_epis_anamnesis      OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_prev_epis_anamnesis IS
            SELECT desc_epis_anamnesis, id_diagnosis, flg_class
              FROM epis_anamnesis ea
             WHERE ea.id_epis_anamnesis = i_id_epis_anamnesis;
    
        l_exist                   VARCHAR2(1 CHAR);
        l_temp                    epis_anamnesis.flg_temp%TYPE;
        l_id                      epis_anamnesis.id_epis_anamnesis%TYPE;
        l_desc                    epis_anamnesis.desc_epis_anamnesis%TYPE;
        l_diag                    epis_anamnesis.id_diagnosis%TYPE;
        l_flg_class               epis_anamnesis.flg_class%TYPE;
        l_sys_reason_codification sys_config.value%TYPE;
        l_sys_one_active          sys_config.value%TYPE;
    
        l_rows table_varchar := table_varchar();
    BEGIN
        g_sysdate_tstz := current_timestamp;
        --
        g_error                   := 'GET SYS_CONFIG';
        l_sys_reason_codification := pk_sysconfig.get_config('VISIT_REASON_DOCTOR_CODIFICATION', i_prof);
        l_sys_one_active          := pk_sysconfig.get_config('REASON_FOR_VISIT_ONLY_ONE_ACTIVE', i_prof);
    
        --
        IF (i_id_epis_anamnesis IS NOT NULL AND i_flg_type_mode = g_flg_edition_type_edit)
        THEN
            g_error := 'UPDATE epis_anamnesis -> i_flg_type_mode = E ';
            ts_epis_anamnesis.upd(flg_status_in        => g_epis_outdated,
                                  id_epis_anamnesis_in => i_id_epis_anamnesis,
                                  rows_out             => l_rows);
        
            g_error := 't_data_gov_mnt.process_update ts_epis_anamnesis';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_ANAMNESIS',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        END IF;
        -- EB deactivate previous active anamnesis
        IF i_flg_type_mode IN (g_flg_edition_type_new, g_flg_edition_type_update, g_flg_edition_type_edit)
           AND l_sys_one_active = pk_alert_constant.g_yes
           AND i_flg_type = g_complaint
        THEN
            -- outdated previous anamnenis (ALL ACTIVE)
            g_error := 'UPDATE epis_anamnesis -> outdated previous anamnenis (ALL ACTIVE)';
            l_rows  := table_varchar();
            ts_epis_anamnesis.upd(flg_status_in => g_epis_outdated,
                                  where_in      => 'id_episode = ' || i_episode || ' and flg_status = ''' ||
                                                   g_epis_active || ''' and flg_type = ''' || g_complaint || '''',
                                  rows_out      => l_rows);
        
            g_error := 't_data_gov_mnt.process_update ts_epis_anamnesis';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_ANAMNESIS',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        END IF;
        --
        IF (i_flg_type_mode = g_flg_edition_type_nochanges)
        THEN
            --No changes edition. 
            --Copies the values from previous record and creates a new record using current professional
            IF (i_id_epis_anamnesis IS NULL)
            THEN
                -- Checking: flg_type = no changes, but previous record was not defined
                g_error := 'NO CHANGES WITHOUT ID_EPIS_ANAMNESIS PARAMETER';
                RAISE g_exception;
            END IF;
        
            g_error := 'GET EPIS_ANAMNESIS';
            OPEN c_prev_epis_anamnesis;
            FETCH c_prev_epis_anamnesis
                INTO l_desc, l_diag, l_flg_class;
            CLOSE c_prev_epis_anamnesis;
        ELSE
            --Editions of type New,Edit,Agree,Update. 
            --Creates a new record using the arguments passed to function
            l_desc := i_desc;
            IF l_sys_reason_codification = pk_alert_constant.g_no -- EB - IF codification of reason of visit must be ignored
            THEN
                l_diag := NULL;
            ELSE
                l_diag := i_id_diag;
            END IF;
            l_flg_class := i_flg_class;
        END IF;
    
        g_error             := 'INSERT EPIS_ANAMNESIS';
        l_rows              := table_varchar();
        o_id_epis_anamnesis := ts_epis_anamnesis.next_key;
    
        ts_epis_anamnesis.ins(id_epis_anamnesis_in        => o_id_epis_anamnesis,
                              dt_epis_anamnesis_tstz_in   => nvl(i_dt_epis_anamnesis_tstz, g_sysdate_tstz),
                              desc_epis_anamnesis_in      => l_desc,
                              id_episode_in               => i_episode,
                              id_professional_in          => i_prof.id,
                              flg_type_in                 => i_flg_type,
                              flg_temp_in                 => g_flg_def,
                              id_institution_in           => i_prof.institution,
                              id_software_in              => i_prof.software,
                              id_diagnosis_in             => l_diag,
                              flg_class_in                => l_flg_class,
                              flg_status_in               => g_epis_active,
                              id_epis_anamnesis_parent_in => i_id_epis_anamnesis,
                              flg_edition_type_in         => i_flg_type_mode,
                              flg_reported_by_in          => i_flg_rep_by,
                              rows_out                    => l_rows);
    
        g_error := 'PROCESS INSERT WITH ID_EPIS_ANAMNESIS ' || o_id_epis_anamnesis;
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_insert(i_lang, i_prof, 'EPIS_ANAMNESIS', l_rows, o_error);
        --    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --    
        g_error := 'CALL pk_visit.update_epis_info';
        IF NOT pk_visit.update_epis_info(i_lang         => i_lang,
                                         i_id_episode   => i_episode,
                                         i_id_room      => NULL,
                                         i_bed          => NULL,
                                         i_norton       => NULL,
                                         i_professional => NULL,
                                         i_flg_hydric   => NULL,
                                         i_flg_wound    => NULL,
                                         i_companion    => NULL,
                                         i_flg_unknown  => NULL,
                                         i_desc_info    => pk_string_utils.clob_to_sqlvarchar2(i_desc),
                                         i_prof         => i_prof,
                                         o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => 'SET_EPIS_ANAMNESIS_INT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_anamnesis_int;

    /********************************************************************************************
    * Criar queixa / anamnese 
    *
    * @param i_lang                 id da lingua
    * @param i_episode              episode id
    * @param i_prof                 objecto com info do utilizador
    * @param i_desc                 descrição da queixa / anamnese 
    * @param i_flg_type             C  - queixa ; A - anamnese
    * @param i_flg_type_mode        type of edition
    * @param i_id_epis_anamnesis    Episódio da queixa/historia 
    * @param i_id_diag              ID do diagnóstico associado ao texto + freq.seleccionado para registo da queixa / história 
    * @param i_flg_class            A - motivo administrativo de consulta (CARE: texto + freq. do ICPC2)
    * @param i_prof_cat_type        Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF
    * @param o_id_epis_anamnesis    registo           
    * @param o_error                Error message
    * 
    * @value i_flg_type_mode        {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    * @return                       true or false on success or error
    * 
    * @author                       Claudia Silva
    * @version                      1.0
    * @since                        2005/03/04 
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/05/08
    *                             Added new edit options: Update from previous assessment; No changes;
    * Changed:
    *                             Elisabete bugalho
    *                             2009/03/20
    *                             Ignore the codification of reason of visit and deactivate previous 
    *                             anamnesis, depending on the configuration (OUTP, PP-PT)
    ********************************************************************************************/
    FUNCTION set_epis_anamnesis
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN epis_anamnesis.id_episode%TYPE,
        i_prof              IN profissional,
        i_desc              IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_flg_type          IN epis_anamnesis.flg_type%TYPE,
        i_flg_type_mode     IN VARCHAR2,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        i_id_diag           IN epis_anamnesis.id_diagnosis%TYPE,
        i_flg_class         IN epis_anamnesis.flg_class%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        o_id_epis_anamnesis OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL set_epis_anamnesis_int';
        IF NOT set_epis_anamnesis_int(i_lang              => i_lang,
                                      i_episode           => i_episode,
                                      i_prof              => i_prof,
                                      i_desc              => i_desc,
                                      i_flg_type          => i_flg_type,
                                      i_flg_type_mode     => i_flg_type_mode,
                                      i_id_epis_anamnesis => i_id_epis_anamnesis,
                                      i_id_diag           => i_id_diag,
                                      i_flg_class         => i_flg_class,
                                      i_prof_cat_type     => i_prof_cat_type,
                                      i_flg_rep_by        => NULL,
                                      o_id_epis_anamnesis => o_id_epis_anamnesis,
                                      o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => 'SET_EPIS_ANAMNESIS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_anamnesis;
    --
    FUNCTION get_all_epis_anamnesis
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_anamnesis.id_episode%TYPE,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        i_prof     IN profissional,
        o_desc     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter queixa / anamnese por ordem cronológica do + recente p/ o + antigo 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                 I_EPISODE - ID do episódio 
                                 I_DESC - queixas / anamneses 
                                 I_FLG_TYPE - C  - queixa 
                                              A - anamnese 
                                              NULL - ambos 
                        Saida:   O_DESC - texto da queixa / anamnese, ID do autor e data de registo 
                                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/04 
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_desc FOR
            SELECT ea.id_epis_anamnesis,
                   pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_epis_anamnesis,
                   ea.flg_type,
                   --p.nick_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name,
                   
                   pk_date_utils.date_char_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof.institution, i_prof.software) dt_epis_anamnesis,
                   flg_temp,
                   --pk_translation.get_translation_dtchk(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || p.id_speciality) desc_speciality
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ea.id_professional,
                                                    ea.dt_epis_anamnesis_tstz,
                                                    ea.id_episode) desc_speciality
            
              FROM epis_anamnesis ea, professional p
             WHERE ea.id_episode = i_episode
               AND ea.flg_type = nvl(i_flg_type, ea.flg_type)
               AND p.id_professional = ea.id_professional
             ORDER BY ea.dt_epis_anamnesis_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_ALL_EPIS_ANAMNESIS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_desc);
            RETURN FALSE;
    END;
    --
    --
    FUNCTION get_last_id_epis_anamnesis
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_anamnesis.id_episode%TYPE,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        o_id_compl OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_id_anamn OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter ID da queixa / anamnese mais recente no episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                 I_EPISODE - ID do episódio actual 
                                 I_FLG_TYPE - C  - queixa 
                                              A - anamnese 
                                              NULL - ambos 
                        Saida:   O_ID_COMPL - ID da queixa 
                                 O_ID_ANAMN - ID da anamnese 
                                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/04/05 
          NOTAS: 
        *********************************************************************************/
        l_type epis_anamnesis.flg_type%TYPE;
        --
        CURSOR c_last_type IS
            SELECT e.id_epis_anamnesis, e.flg_type
              FROM epis_anamnesis e
             WHERE e.id_episode = i_episode
               AND flg_type = nvl(l_type, flg_type)
             ORDER BY e.dt_epis_anamnesis_tstz DESC;
        --
        r_last_type c_last_type%ROWTYPE;
    
    BEGIN
        l_type := i_flg_type;
        -- Encontrar o ID do tipo I_FLG_TYPE, ou o ID + recente do epis. 
        g_error := 'GET CURSOR C_LAST_TYPE(1)';
        OPEN c_last_type;
        FETCH c_last_type
            INTO r_last_type;
        g_found := c_last_type%FOUND;
        CLOSE c_last_type;
        --
        IF g_found
        THEN
            g_error := 'GET ID(1)';
            IF r_last_type.flg_type = g_complaint
            THEN
                o_id_compl := r_last_type.id_epis_anamnesis;
            ELSIF r_last_type.flg_type = g_anamnesis
            THEN
                o_id_anamn := r_last_type.id_epis_anamnesis;
            END IF;
        END IF;
    
        IF i_flg_type IS NULL
        THEN
            -- Pretende-se ainda o ID do outro tipo (queixa / anamnese) 
            g_error := 'GET TYPE';
            IF r_last_type.flg_type = g_complaint
            THEN
                l_type := g_anamnesis;
            ELSIF r_last_type.flg_type = g_anamnesis
            THEN
                l_type := g_complaint;
            END IF;
        
            r_last_type := NULL;
            g_error     := 'GET CURSOR C_LAST_TYPE(2)';
            OPEN c_last_type;
            FETCH c_last_type
                INTO r_last_type;
            g_found := c_last_type%FOUND;
            CLOSE c_last_type;
            IF g_found
            THEN
                g_error := 'GET ID(2)';
                IF r_last_type.flg_type = g_complaint
                THEN
                    o_id_compl := r_last_type.id_epis_anamnesis;
                ELSIF r_last_type.flg_type = g_anamnesis
                THEN
                    o_id_anamn := r_last_type.id_epis_anamnesis;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_LAST_EPIS_ANAMNESIS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Indica se o episódio tem registos de queixa ou anamneses em texto livre
    *
    * @param i_lang            id da lingua 
    * @param i_episode         id do episódio
    * @param i_prof            objecto do profissional
    * @param i_flg_type        informação que se quer saber: C para queixa e A para anamnese 
    * @param o_flg_data        flag com valores Y/N que indica se há ou não, respectivamente, os registos  
    * @param o_error           mensagem de erro
    *
    * @return                  true successo, false erro
    *  
    * @author                  João Eiras
    * @version                 1.0
    * @since                   2007/09/20 
    ********************************************************************************************/
    FUNCTION get_epis_anamnesis_exists
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_anamnesis.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        o_flg_data OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_data_epis_anam      VARCHAR2(1);
        l_flg_data_epis_recommend VARCHAR2(1);
        l_flg_data                VARCHAR2(1);
    BEGIN
        g_error := 'COUNT REGISTRIES epis_anamnesis';
        SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_flg_data_epis_anam
          FROM epis_anamnesis ea
         WHERE ea.id_episode = i_episode
           AND ea.flg_type = i_flg_type;
    
        g_error := 'COUNT REGISTRIES epis_recomend - SOAP subjective';
        SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_flg_data_epis_recommend
          FROM epis_recomend er
         WHERE er.id_episode = i_episode
           AND er.flg_status = pk_alert_constant.g_active
           AND er.flg_type = pk_progress_notes.g_type_subjective;
        --
        IF i_flg_type = g_flg_type_c
        THEN
            g_error := 'CALL pk_complaint.get_complaint_exists';
            IF NOT pk_complaint.get_complaint_template_exists(i_lang     => i_lang,
                                                              i_prof     => i_prof,
                                                              i_episode  => i_episode,
                                                              o_flg_data => l_flg_data,
                                                              o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'CALL pk_touch_option.get_doc_area_exists';
            IF NOT pk_touch_option.get_doc_area_exists(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_episode  => i_episode,
                                                       i_doc_area => g_doc_area_hist_ill,
                                                       o_flg_data => l_flg_data,
                                                       o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
        --        
        IF l_flg_data_epis_anam = pk_alert_constant.g_yes
           OR l_flg_data = pk_alert_constant.g_yes
           OR l_flg_data_epis_recommend = pk_alert_constant.g_yes
        THEN
            o_flg_data := pk_alert_constant.g_yes;
        ELSE
            o_flg_data := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_ANAMNESIS_EXISTS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Indica se o profissional actual registou uma queixa/história no episódio pretendido
    *
    * @param i_lang                    id da lingua 
    * @param i_episode                 id do episódio
    * @param i_prof                    objecto do profissional
    * @param i_flg_type                informação que se quer saber: C para queixa e A para anamnese 
    * @param o_last_prof_episode       último episódio de queixa ou história
    * @param o_flg_data                flag com valores Y/N que indica se há ou não, respectivamente, os registos  
    * @param o_error                   mensagem de erro
    *
    * @return                          true successo, false erro
    *  
    * @author                          Emilia Taborda
    * @version                         1.0
    * @since                           2007/09/24 
    ********************************************************************************************/
    FUNCTION get_prof_epis_anamn_exists
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN epis_anamnesis.id_episode%TYPE,
        i_prof              IN profissional,
        i_flg_type          IN epis_anamnesis.flg_type%TYPE,
        o_last_prof_episode OUT episode.id_episode%TYPE,
        o_flg_data          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_data_free_text    VARCHAR2(1);
        l_flg_data_touch_option VARCHAR2(1);
        --
        l_last_epis_free_text    epis_anamnesis.id_epis_anamnesis%TYPE;
        l_last_date_free_text    epis_anamnesis.dt_epis_anamnesis_tstz%TYPE;
        l_last_epis_touch_option epis_documentation.id_epis_documentation%TYPE;
        l_last_date_touch_option epis_documentation.dt_creation_tstz%TYPE;
    BEGIN
        BEGIN
            g_error := 'Find Exists epis_observation';
            SELECT flg_exists, id_epis_anamnesis, dt_epis_anamnesis_tstz
              INTO l_flg_data_free_text, l_last_epis_free_text, l_last_date_free_text
              FROM (SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_exists,
                           ea.id_epis_anamnesis,
                           ea.dt_epis_anamnesis_tstz
                      FROM epis_anamnesis ea
                     WHERE ea.id_episode = i_episode
                       AND ea.flg_type = i_flg_type
                       AND ea.dt_epis_anamnesis_tstz = (SELECT MAX(ea1.dt_epis_anamnesis_tstz)
                                                          FROM epis_anamnesis ea1
                                                         WHERE ea1.id_episode = i_episode
                                                           AND ea1.flg_type = i_flg_type)
                       AND ea.id_professional = i_prof.id
                     GROUP BY ea.id_epis_anamnesis, ea.dt_epis_anamnesis_tstz) t
             WHERE rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        --
        IF i_flg_type = g_flg_type_c
        THEN
            g_error := 'CALL pk_complaint.get_prof_compl_templ_exists';
            IF NOT pk_complaint.get_prof_compl_templ_exists(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_episode        => i_episode,
                                                            o_epis_complaint => l_last_epis_touch_option,
                                                            o_date_last_epis => l_last_date_touch_option,
                                                            o_flg_data       => l_flg_data_touch_option,
                                                            o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'CALL pk_touch_option.get_prof_doc_area_exists';
            IF NOT pk_touch_option.get_prof_doc_area_exists(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_episode            => i_episode,
                                                            i_doc_area           => g_doc_area_hist_ill,
                                                            o_last_prof_epis_doc => l_last_epis_touch_option,
                                                            o_date_last_epis     => l_last_date_touch_option,
                                                            o_flg_data           => l_flg_data_touch_option,
                                                            o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
        --
        IF l_last_date_free_text > l_last_date_touch_option
           OR l_last_date_touch_option IS NULL
        THEN
            o_last_prof_episode := l_last_epis_free_text;
        
        ELSIF l_last_date_touch_option > l_last_date_free_text
              OR l_last_date_free_text IS NULL
        THEN
            o_last_prof_episode := l_last_epis_touch_option;
        END IF;
        --
        IF l_flg_data_free_text = pk_alert_constant.g_yes
           OR l_flg_data_touch_option = pk_alert_constant.g_yes
        THEN
            o_flg_data := pk_alert_constant.g_yes;
        ELSE
            o_flg_data := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_PROF_EPIS_ANAMN_EXISTS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Retorna informação relativa ao último registo de queixa ou anamneses neste episódio, em texto livre
    *
    * @param i_lang                id da lingua 
    * @param i_episode             id do episódio
    * @param i_prof                objecto do profissional
    * @param i_flg_type            informação que se quer saber: C para queixa e A para anamnese 
    * @param o_last_update         cursor con informação  
    * @param o_error               mensagem de erro
    *
    * @return                      true successo, false erro
    *  
    * @author                      João Eiras
    * @version                     1.0
    * @since                       2007/09/20 
    ********************************************************************************************/
    FUNCTION get_epis_anamnesis_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN epis_anamnesis.id_episode%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN epis_anamnesis.flg_type%TYPE,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_LAST_UPDATE';
        OPEN o_last_update FOR
            SELECT *
              FROM (SELECT pk_date_utils.date_send_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof) dt_epis_anamnesis,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            ea.id_professional,
                                                            ea.dt_epis_anamnesis_tstz,
                                                            ea.id_episode) desc_speciality,
                           pk_date_utils.date_chr_short_read_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof) date_target,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            ea.dt_epis_anamnesis_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) hour_target,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       ea.dt_epis_anamnesis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) date_hour_target
                      FROM epis_anamnesis ea
                     WHERE ea.id_episode = i_episode
                       AND ea.flg_type = nvl(i_flg_type, ea.flg_type)
                     ORDER BY ea.dt_epis_anamnesis_tstz DESC)
             WHERE rownum < 2;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_ANAMNESIS_EXISTS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    FUNCTION get_last_epis_anamnesis
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_anamnesis.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        o_temp     OUT pk_types.cursor_type,
        o_def      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter queixas / anamneses do episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                 I_EPISODE - ID do episódio actual 
                                 I_PROF - ID do profissional
                                 I_FLG_TYPE - C  - queixa 
                                              A - anamnese 
                          Saida: O_TEMP - último registo temporário
                                 O_DEF - último registo definitivo registado antes da passagem de temporários para definitivos + 
                                         todos os registos definitivos registado após a passagem de temporários para definitivos
                                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/04/05 
          ALTERAÇÃO: SS 2005/12/30
                     SS 2006/10/12 - mostrar sempre o último temporário qualquer seja o utilizador (independentemente de ser o autor do registo)
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET O_COMPL';
        OPEN o_temp FOR
            SELECT reg,
                   id_epis_anamnesis,
                   date_ordena,
                   flg_type,
                   pk_string_utils.clob_to_sqlvarchar2(desc_epis_anamnesis) desc_epis_anamnesis,
                   nick_name,
                   dt_epis_anamnesis,
                   desc_speciality,
                   instit,
                   clin_serv,
                   flg_temp,
                   epis_anamn_type,
                   epis_current
              FROM (SELECT 'R' reg,
                           NULL id_epis_anamnesis,
                           et.dt_begin_tstz date_ordena,
                           NULL flg_type,
                           to_clob(decode(et.id_triage_white_reason,
                                          NULL,
                                          NULL,
                                          pk_translation.get_translation(i_lang,
                                                                         'TRIAGE_WHITE_REASON.CODE_TRIAGE_WHITE_REASON.' ||
                                                                         et.id_triage_white_reason) || ': ' || et.notes)) desc_epis_anamnesis,
                           --pk_tools.get_prof_nick_name(i_lang, et.id_professional) nick_name,
                           
                           pk_prof_utils.get_name_signature(i_lang, i_prof, et.id_professional) nick_name,
                           
                           pk_date_utils.date_char_tsz(i_lang, et.dt_begin_tstz, i_prof.institution, i_prof.software) dt_epis_anamnesis,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            et.id_professional,
                                                            et.dt_begin_tstz,
                                                            et.id_episode) desc_speciality,
                           NULL instit,
                           NULL clin_serv,
                           NULL flg_temp,
                           pk_message.get_message(i_lang, 'CURRENT_HIST_DOCTOR_T009') epis_anamn_type,
                           NULL epis_current
                      FROM epis_triage et
                     WHERE et.id_episode = i_episode
                       AND et.dt_end_tstz = (SELECT MAX(et1.dt_end_tstz)
                                               FROM epis_triage et1
                                              WHERE et1.id_episode = i_episode)
                    UNION ALL
                    SELECT 'R' reg,
                           e.id_epis_anamnesis,
                           e.dt_epis_anamnesis_tstz date_ordena,
                           e.flg_type,
                           e.desc_epis_anamnesis,
                           --pk_tools.get_prof_nick_name(i_lang, e.id_professional) nick_name,
                           
                           pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional) nick_name,
                           
                           pk_date_utils.date_char_tsz(i_lang,
                                                       e.dt_epis_anamnesis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_epis_anamnesis,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            e.id_professional,
                                                            e.dt_epis_anamnesis_tstz,
                                                            e.id_episode) desc_speciality,
                           pk_tools.get_desc_institution(i_lang, e.id_institution, g_abbreviation) instit,
                           pk_translation.get_translation(i_lang,
                                                          'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                          epis.id_clinical_service) clin_serv,
                           e.flg_temp,
                           decode(i_flg_type,
                                  g_complaint,
                                  pk_message.get_message(i_lang, i_prof, 'CURRENT_HIST_DOCTOR_T004'),
                                  pk_message.get_message(i_lang, 'CURRENT_HIST_DOCTOR_T005')) epis_anamn_type,
                           decode(e.flg_temp, g_flg_temp, pk_message.get_message(i_lang, 'CURRENT_HIST_DOCTOR_T006'), '') epis_current
                      FROM epis_anamnesis e, episode epis
                     WHERE e.id_episode = i_episode
                       AND epis.id_episode = e.id_episode
                       AND e.flg_type = i_flg_type
                       AND e.flg_temp = g_flg_temp
                       AND e.dt_epis_anamnesis_tstz = (SELECT MAX(e2.dt_epis_anamnesis_tstz)
                                                         FROM epis_anamnesis e2
                                                        WHERE e2.id_episode = e.id_episode
                                                          AND e2.id_professional = e.id_professional
                                                          AND flg_type = i_flg_type))
             WHERE desc_epis_anamnesis IS NOT NULL
             ORDER BY flg_temp DESC, date_ordena DESC;
        --
        g_error := 'GET CURSOR O_DEF';
        OPEN o_def FOR
            SELECT id_epis_anamnesis,
                   desc_epis_anamnesis,
                   date_ordena,
                   flg_type,
                   nick_name,
                   dt_epis_anamnesis,
                   flg_temp,
                   clin_serv,
                   desc_speciality,
                   instit,
                   epis_anamn_type,
                   epis_current,
                   flg_status
              FROM (SELECT NULL id_epis_anamnesis,
                           to_clob(decode(et.id_triage_white_reason,
                                          NULL,
                                          NULL,
                                          pk_translation.get_translation(i_lang,
                                                                         'TRIAGE_WHITE_REASON.CODE_TRIAGE_WHITE_REASON.' ||
                                                                         et.id_triage_white_reason) || ': ' || et.notes)) desc_epis_anamnesis,
                           et.dt_begin_tstz date_ordena,
                           NULL flg_type,
                           --pk_tools.get_prof_nick_name(i_lang, et.id_professional) nick_name,
                           
                           pk_prof_utils.get_name_signature(i_lang, i_prof, et.id_professional) nick_name,
                           
                           pk_date_utils.date_char_tsz(i_lang, et.dt_begin_tstz, i_prof.institution, i_prof.software) dt_epis_anamnesis,
                           NULL flg_temp,
                           NULL clin_serv,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            et.id_professional,
                                                            et.dt_begin_tstz,
                                                            et.id_episode) desc_speciality,
                           NULL instit,
                           pk_message.get_message(i_lang, 'CURRENT_HIST_DOCTOR_T009') epis_anamn_type,
                           NULL epis_current,
                           NULL flg_status
                      FROM epis_triage et
                     WHERE et.id_episode = i_episode
                       AND et.dt_end_tstz = (SELECT MAX(et1.dt_end_tstz)
                                               FROM epis_triage et1
                                              WHERE et1.id_episode = i_episode)
                    UNION ALL
                    SELECT ea.id_epis_anamnesis,
                           ea.desc_epis_anamnesis,
                           ea.dt_epis_anamnesis_tstz date_ordena,
                           ea.flg_type,
                           --pk_tools.get_prof_nick_name(i_lang, ea.id_professional) nick_name,
                           
                           pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name,
                           
                           pk_date_utils.date_char_tsz(i_lang,
                                                       ea.dt_epis_anamnesis_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_epis_anamnesis,
                           ea.flg_temp,
                           pk_translation.get_translation(i_lang,
                                                          'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                          epis.id_clinical_service) clin_serv,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            ea.id_professional,
                                                            ea.dt_epis_anamnesis_tstz,
                                                            ea.id_episode) desc_speciality,
                           pk_tools.get_desc_institution(i_lang, ea.id_institution, g_abbreviation) instit,
                           pk_message.get_message(i_lang, i_prof, 'CURRENT_HIST_DOCTOR_T004') epis_anamn_type,
                           decode(ea.flg_temp,
                                  g_flg_temp,
                                  pk_message.get_message(i_lang, 'CURRENT_HIST_DOCTOR_T006'),
                                  '') epis_current,
                           ea.flg_status flg_status
                      FROM epis_anamnesis ea, episode epis
                     WHERE ea.flg_type = i_flg_type
                       AND ea.flg_temp = g_flg_def
                       AND ea.id_episode = i_episode
                       AND epis.id_episode = ea.id_episode)
             WHERE desc_epis_anamnesis IS NOT NULL
             ORDER BY flg_temp DESC, date_ordena DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_LAST_EPIS_ANAMNESIS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_temp);
            pk_types.open_my_cursor(o_def);
            RETURN FALSE;
    END;
    --
    --
    FUNCTION get_epis_anamnesis_det
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_anamnesis.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        o_det      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter detalhe das queixas / anamneses do episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                 I_EPISODE - ID do episódio actual 
                                 I_PROF - ID do profissional
                                 I_FLG_TYPE - C  - queixa 
                                              A - anamnese 
                          Saida: O_DET - último registo temporário  
                                 O_ERROR - erro 
          
          CRIAÇÃO: SS 2006/10/12 
          NOTAS: 
        *********************************************************************************/
        l_aux epis_anamnesis.id_episode%TYPE;
    BEGIN
        BEGIN
            --verificar se há registos neste episódio
            SELECT DISTINCT id_episode
              INTO l_aux
              FROM epis_anamnesis
             WHERE id_episode = i_episode;
            --
            g_error := 'GET O_DET';
            OPEN o_det FOR
                SELECT 'R' reg,
                       e.id_epis_anamnesis,
                       e.flg_type,
                       pk_string_utils.clob_to_sqlvarchar2(e.desc_epis_anamnesis) desc_epis_anamnesis,
                       --pk_tools.get_prof_nick_name(i_lang, e.id_professional) nick_name,
                       
                       pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional) nick_name,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        e.id_professional,
                                                        e.dt_epis_anamnesis_tstz,
                                                        e.id_episode) desc_speciality,
                       pk_tools.get_desc_institution(i_lang, e.id_institution, g_abbreviation) instit,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   e.dt_epis_anamnesis_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_epis_anamnesis,
                       pk_translation.get_translation(i_lang,
                                                      'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                      epis.id_clinical_service) clin_serv,
                       e.flg_temp
                  FROM epis_anamnesis e, episode epis
                 WHERE e.id_episode = i_episode
                   AND e.flg_type = i_flg_type
                   AND epis.id_episode = e.id_episode
                 ORDER BY e.flg_temp DESC, e.dt_epis_anamnesis_tstz DESC;
        
        EXCEPTION
            WHEN no_data_found THEN
                --se não houver registos, mostra <nada registado>
                g_error := 'GET CURSOR2';
                OPEN o_det FOR
                    SELECT 'N' reg,
                           NULL id_epis_anamnesis,
                           NULL flg_type,
                           pk_message.get_message(i_lang, 'COMMON_M007') desc_epis_anamnesis,
                           NULL nick_name,
                           NULL desc_speciality,
                           NULL instit,
                           NULL dt_epis_anamnesis,
                           NULL clin_serv,
                           NULL flg_temp
                      FROM dual;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_ANAMNESIS_DET',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_det);
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Obter todas as queixas / anamneses do doente, excepto a mais recente no episódio (se existir)  
    *
    * @param i_lang                 id da lingua
    * @param i_pat                  patient id
    * @param i_episode              episode id
    * @param i_flg_type             C  - queixa ; A - anamnese
    * @param i_prof                 objecto com info do utilizador    
    * @param o_desc                 registos de queixa/historia          
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       Claudia Silva
    * @version                      1.0
    * @since                        2005/03/30  
    ********************************************************************************************/
    FUNCTION get_previous_epis_anamnesis
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        i_prof     IN profissional,
        o_desc     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_complaint epis_anamnesis.id_epis_anamnesis%TYPE;
        l_id_anamnesis epis_anamnesis.id_epis_anamnesis%TYPE;
    BEGIN
        -- Encontrar o ID da queixa + recente 
        g_error := 'CALL TO GET_LAST_EPIS_ANAMNESIS';
        IF NOT get_last_id_epis_anamnesis(i_lang     => i_lang,
                                          i_episode  => i_episode,
                                          i_flg_type => i_flg_type,
                                          o_id_compl => l_id_complaint,
                                          o_id_anamn => l_id_anamnesis,
                                          o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        l_id_complaint := nvl(l_id_complaint, -99);
        --
        g_error := 'GET CURSOR';
        OPEN o_desc FOR
            SELECT ea.id_epis_anamnesis,
                   pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_epis_anamnesis,
                   ea.flg_type,
                   --pk_tools.get_prof_nick_name(i_lang, ea.id_professional) nick_name,
                   
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name,
                   
                   pk_date_utils.date_char_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof.institution, i_prof.software) dt_epis_anamnesis,
                   ea.flg_temp,
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || epis.id_clinical_service) clin_serv
              FROM epis_anamnesis ea, episode epis
             WHERE ea.flg_type = nvl(i_flg_type, ea.flg_type)
               AND ea.id_epis_anamnesis != l_id_complaint
               AND ea.flg_temp = g_flg_def
               AND epis.id_episode = ea.id_episode
               AND epis.id_patient = i_pat
             ORDER BY ea.dt_epis_anamnesis_tstz DESC;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_PREVIOUS_EPIS_ANAMNESIS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_desc);
            RETURN FALSE;
    END;
    --
    FUNCTION get_last_id_epis_observation
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN epis_observation.id_episode%TYPE,
        i_prof        IN profissional,
        o_id_epis_obs OUT epis_observation.id_epis_observation%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter ID da observação mais recente do profissional no episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                 I_EPISODE - ID do episódio actual 
                        Saida:   O_ID_EPIS_OBS - ID da observação 
                                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/04/05 
          NOTAS: 
        *********************************************************************************/
        CURSOR c_last_obs IS
            SELECT e.id_epis_observation
              FROM epis_observation e
             WHERE e.id_episode = i_episode
               AND e.id_professional = i_prof.id
               AND e.flg_temp = g_flg_temp
             ORDER BY e.dt_epis_observation_tstz DESC;
    BEGIN
        -- Encontrar o ID do tipo I_FLG_TYPE, ou o ID + recente do epis. 
        g_error := 'GET CURSOR C_LAST_OBS';
        OPEN c_last_obs;
        FETCH c_last_obs
            INTO o_id_epis_obs;
        CLOSE c_last_obs;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_LAST_ID_EPIS_OBSERVATION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Registar observações do episódio  
    *
    * @param i_lang                 id da lingua
    * @param i_episode              episode id
    * @param i_prof                 objecto com info do utilizador
    * @param i_desc                 observação
    * @param i_id_epis_observation  Episódio da observação 
    * @param i_prof_cat_type        Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF
    * @param i_flg_type_mode        Type of edition
    * @param o_id_epis_observation  novo registo           
    * @param o_error                Error message
    *
    * @value i_flg_type_mode        {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes                        
    * @return                       true or false on success or error
    * 
    * @author                       Claudia Silva
    * @version                      1.0
    * @since                        2005/03/04
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/05/08
    *                             Added new edit options: Update from previous assessment; No changes;
    ********************************************************************************************/
    FUNCTION set_epis_observation
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN epis_observation.id_episode%TYPE,
        i_prof                IN profissional,
        i_desc                IN epis_observation.desc_epis_observation%TYPE,
        i_id_epis_observation IN epis_observation.id_epis_observation%TYPE,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_flg_type_mode       IN VARCHAR2,
        o_id_epis_observation OUT epis_observation.id_epis_observation%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next     epis_observation.id_epis_observation%TYPE;
        l_exist    VARCHAR2(1);
        l_temp     VARCHAR2(1);
        l_id       epis_anamnesis.id_epis_anamnesis%TYPE;
        l_flg_type epis_observation.flg_type%TYPE;
        l_desc     epis_observation.desc_epis_observation%TYPE;
    
        CURSOR c_prev_epis_obs IS
            SELECT desc_epis_observation
              FROM epis_observation
             WHERE id_epis_observation = i_id_epis_observation;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --    
        IF (i_id_epis_observation IS NOT NULL AND i_flg_type_mode = g_flg_edition_type_edit)
        THEN
            g_error := 'UPDATE epis_observation -> i_flg_type_mode = E ';
            UPDATE epis_observation
               SET flg_status = g_epis_outdated
             WHERE id_epis_observation = i_id_epis_observation;
        END IF;
        --
        IF i_prof_cat_type = g_cat_flg_type_d
           OR i_prof_cat_type = g_cat_flg_type_u
        THEN
            l_flg_type := g_observ_flg_type_e;
        ELSE
            l_flg_type := g_observ_flg_type_a;
        END IF;
        --
        IF (i_flg_type_mode = g_flg_edition_type_nochanges)
        THEN
            --No changes edition. 
            --Copies the values from previous record and creates a new record using current professional
            IF (i_id_epis_observation IS NULL)
            THEN
                -- Checking: flg_type = no changes, but previous record was not defined
                g_error := 'NO CHANGES WITHOUT ID_EPIS_OBSERVATION PARAMETER';
                RAISE g_exception;
            END IF;
        
            g_error := 'GET EPIS_OBSERVATION';
            OPEN c_prev_epis_obs;
            FETCH c_prev_epis_obs
                INTO l_desc;
            CLOSE c_prev_epis_obs;
        ELSE
            --Editions of type New,Edit,Agree,Update. 
            --Creates a new record using the arguments passed to function
            l_desc := i_desc;
        END IF;
    
        g_error := 'GET SEQ_EPIS_OBSERVATION.NEXTVAL';
        SELECT seq_epis_observation.nextval
          INTO l_next
          FROM dual;
        --
        g_error := 'INSERT EPIS_OBSERVATION';
        INSERT INTO epis_observation
            (id_epis_observation,
             dt_epis_observation_tstz,
             desc_epis_observation,
             id_episode,
             id_professional,
             flg_temp,
             id_institution,
             id_software,
             flg_type,
             flg_status,
             id_epis_observation_parent,
             flg_edition_type)
        VALUES
            (l_next,
             g_sysdate_tstz,
             l_desc,
             i_episode,
             i_prof.id,
             g_flg_def,
             i_prof.institution,
             i_prof.software,
             l_flg_type,
             g_epis_active,
             i_id_epis_observation,
             i_flg_type_mode);
        --
        o_id_epis_observation := l_next;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'SET_EPIS_OBSERVATION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    FUNCTION get_epis_observation
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_observation.id_episode%TYPE,
        i_prof    IN profissional,
        o_temp    OUT pk_types.cursor_type,
        o_def     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /***********************************************************************************
           OBJECTIVO:   Obter todas as observações do episódio excepto a última temporária 
                        do profissional no episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                 I_EPISODE - ID do episódio
                                 I_PROF - profissional que acede 
                          Saida: O_TEMP - último registo temporário
                                 O_DEF - último registo definitivo registado antes da passagem de temporários para definitivos + 
                                         todos os registos definitivos registado após a passagem de temporários para definitivos
                                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/04 
          NOTAS: 
        ************************************************************************************/
    BEGIN
        g_error := 'GET O_COMPL';
        OPEN o_temp FOR
            SELECT 'R' reg,
                   e.id_epis_observation,
                   e.desc_epis_observation,
                   --pk_tools.get_prof_nick_name(i_lang, e.id_professional) nick_name,
                   
                   pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional) nick_name,
                   
                   pk_date_utils.date_char_tsz(i_lang, e.dt_epis_observation_tstz, i_prof.institution, i_prof.software) dt_epis_observation,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    e.id_professional,
                                                    e.dt_epis_observation_tstz,
                                                    e.id_episode) desc_speciality,
                   pk_tools.get_desc_institution(i_lang, e.id_institution, g_abbreviation) instit,
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || epis.id_clinical_service) clin_serv,
                   e.flg_temp
              FROM epis_observation e, episode epis
             WHERE e.id_episode = i_episode
               AND epis.id_episode = e.id_episode
               AND e.flg_temp = g_flg_temp
               AND e.dt_epis_observation_tstz =
                   (SELECT MAX(e2.dt_epis_observation_tstz)
                      FROM epis_observation e2
                     WHERE e2.id_episode = e.id_episode
                       AND e2.id_professional = e.id_professional)
             ORDER BY e.flg_temp DESC, e.dt_epis_observation_tstz DESC;
        --
        g_error := 'GET CURSOR O_DEF';
        OPEN o_def FOR
            SELECT ea.id_epis_observation,
                   ea.desc_epis_observation,
                   --pk_tools.get_prof_nick_name(i_lang, ea.id_professional) nick_name,
                   
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name,
                   
                   pk_date_utils.date_char_tsz(i_lang, ea.dt_epis_observation_tstz, i_prof.institution, i_prof.software) dt_epis_observation,
                   ea.flg_temp,
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || epis.id_clinical_service) clin_serv,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ea.id_professional,
                                                    ea.dt_epis_observation_tstz,
                                                    ea.id_episode) desc_speciality,
                   pk_tools.get_desc_institution(i_lang, ea.id_institution, g_abbreviation) instit
              FROM epis_observation ea, episode epis
             WHERE ea.id_episode = i_episode
               AND ea.flg_temp = g_flg_def
               AND epis.id_episode = ea.id_episode
             ORDER BY ea.flg_temp DESC, ea.dt_epis_observation_tstz DESC;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_OBSERVATION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_temp);
            pk_types.open_my_cursor(o_def);
            RETURN FALSE;
    END;
    --
    --
    FUNCTION get_epis_observation_det
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_anamnesis.id_episode%TYPE,
        i_prof    IN profissional,
        o_det     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter detalhe do exame físico do episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                 I_EPISODE - ID do episódio actual 
                                 I_PROF - ID do profissional
                          Saida: O_DET - registos de exame físico  
                                 O_ERROR - erro 
          
           CRIAÇÃO: SS 2006/10/12 
           NOTAS: 
        *********************************************************************************/
        l_aux epis_observation.id_episode%TYPE;
    BEGIN
        BEGIN
            --verificar se há registos neste episódio
            SELECT DISTINCT id_episode
              INTO l_aux
              FROM epis_observation
             WHERE id_episode = i_episode;
            --        
            g_error := 'GET O_DET';
            OPEN o_det FOR
                SELECT 'R' reg,
                       e.id_epis_observation,
                       e.desc_epis_observation,
                       --pk_tools.get_prof_nick_name(i_lang, e.id_professional) nick_name,
                       
                       pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional) nick_name,
                       
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        e.id_professional,
                                                        e.dt_epis_observation_tstz,
                                                        e.id_episode) desc_speciality,
                       pk_tools.get_desc_institution(i_lang, e.id_institution, g_abbreviation) instit,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   e.dt_epis_observation_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_epis_observation,
                       pk_translation.get_translation(i_lang,
                                                      'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                      epis.id_clinical_service) clin_serv,
                       e.flg_temp
                  FROM epis_observation e, episode epis
                 WHERE e.id_episode = i_episode
                   AND epis.id_episode = e.id_episode
                 ORDER BY e.flg_temp DESC, e.dt_epis_observation_tstz DESC;
        
        EXCEPTION
            WHEN no_data_found THEN
                --se não houver registos, mostra <nada registado>
                g_error := 'GET CURSOR2';
                OPEN o_det FOR
                    SELECT 'N' reg,
                           NULL id_epis_observation,
                           pk_message.get_message(i_lang, 'COMMON_M007') desc_epis_observation,
                           NULL nick_name,
                           NULL desc_speciality,
                           NULL instit,
                           NULL dt_epis_observation,
                           NULL clin_serv,
                           NULL flg_temp
                      FROM dual;
        END;
        --    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_OBSERVATION_DET',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_det);
            RETURN FALSE;
    END;
    --
    --
    FUNCTION get_epis_observation_temp
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_observation.id_episode%TYPE,
        i_prof    IN profissional,
        o_desc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
        
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter observações temporárias do episódio de outros profissionais
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                 I_EPISODE - ID do episódio 
                                 I_PROF - ID do profissional
                        Saida:   O_DESC - texto da observação, ID do autor e data de registo 
                                 O_ERROR - erro 
          
          CRIAÇÃO: RB 2005/04/07 
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_desc FOR
            SELECT e.desc_epis_observation,
                   --pk_tools.get_prof_nick_name(i_lang, e.id_professional) nick_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional) nick_name,
                   
                   e.id_epis_observation,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    e.id_professional,
                                                    e.dt_epis_observation_tstz,
                                                    e.id_episode) desc_speciality,
                   pk_tools.get_desc_institution(i_lang, e.id_institution, g_abbreviation) instit,
                   pk_date_utils.date_char_tsz(i_lang, e.dt_epis_observation_tstz, i_prof.institution, i_prof.software) dt_epis_observation,
                   flg_temp,
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || epis.id_clinical_service) clin_serv,
                   pk_message.get_message(i_lang, 'PHYSICAL_EXAM_T009') epis_obs_type,
                   decode(e.flg_temp, g_flg_temp, pk_message.get_message(i_lang, 'CURRENT_HIST_DOCTOR_T006'), '') epis_current
              FROM epis_observation e, episode epis
             WHERE e.id_episode = i_episode
               AND e.id_professional != i_prof.id
               AND e.flg_temp = g_flg_temp
               AND epis.id_episode = e.id_episode
             ORDER BY e.dt_epis_observation_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_OBSERVATION_TEMP',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_desc);
            RETURN FALSE;
    END;
    --
    --
    FUNCTION get_last_epis_observation
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_observation.id_episode%TYPE,
        i_prof    IN profissional,
        o_temp    OUT pk_types.cursor_type,
        o_def     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter última observação temporária do profissional neste episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                 I_EPISODE - ID do episódio 
                        Saida:   O_DESC - texto da observação, ID do autor e data de registo 
                                 O_ERROR - erro 
          
          CRIAÇÃO: RB 2005/04/07 
          ALTERAÇÃO: SS 2005/12/30
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET O_COMPL';
        OPEN o_temp FOR
            SELECT 'R' reg,
                   e.id_epis_observation,
                   e.desc_epis_observation,
                   --pk_tools.get_prof_nick_name(i_lang, e.id_professional) nick_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional) nick_name,
                   
                   pk_date_utils.date_char_tsz(i_lang, e.dt_epis_observation_tstz, i_prof.institution, i_prof.software) dt_epis_observation,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    e.id_professional,
                                                    e.dt_epis_observation_tstz,
                                                    e.id_episode) desc_speciality,
                   pk_tools.get_desc_institution(i_lang, e.id_institution, g_abbreviation) instit,
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || epis.id_clinical_service) clin_serv,
                   e.flg_temp
              FROM epis_observation e, episode epis
             WHERE e.id_episode = i_episode
               AND epis.id_episode = e.id_episode
               AND e.flg_temp = g_flg_temp
               AND e.dt_epis_observation_tstz =
                   (SELECT MAX(e2.dt_epis_observation_tstz)
                      FROM epis_observation e2
                     WHERE e2.id_episode = e.id_episode
                       AND e2.id_professional = e.id_professional)
             ORDER BY e.flg_temp DESC, e.dt_epis_observation_tstz DESC;
        --    
        g_error := 'GET CURSOR O_DEF';
        OPEN o_def FOR
            SELECT ea.id_epis_observation,
                   ea.desc_epis_observation,
                   --pk_tools.get_prof_nick_name(i_lang, ea.id_professional) nick_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name,
                   
                   pk_date_utils.date_char_tsz(i_lang, ea.dt_epis_observation_tstz, i_prof.institution, i_prof.software) dt_epis_observation,
                   ea.flg_temp,
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || epis.id_clinical_service) clin_serv,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ea.id_professional,
                                                    ea.dt_epis_observation_tstz,
                                                    ea.id_episode) desc_speciality,
                   pk_tools.get_desc_institution(i_lang, ea.id_institution, g_abbreviation) instit
              FROM epis_observation ea, episode epis
             WHERE ea.id_episode = i_episode
               AND ea.flg_temp = g_flg_def
               AND epis.id_episode = ea.id_episode
             ORDER BY ea.flg_temp DESC, ea.dt_epis_observation_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_LAST_EPIS_OBSERVATION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_temp);
            pk_types.open_my_cursor(o_def);
            RETURN FALSE;
    END;
    --
    --
    FUNCTION get_available_info
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_prof        IN profissional,
        o_complaint   OUT pk_types.cursor_type,
        o_history     OUT pk_types.cursor_type,
        o_observation OUT pk_types.cursor_type,
        o_text_vs     OUT table_varchar,
        o_author_vs   OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter a informação disponível de queixa, história, 
                  sinais vitais (último registo de cada sinal vital) e exame físico. 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional  
                                 I_EPISODE - ID do episódio 
                                 I_PROF - identificação do profissional
                        Saida:   O_COMPLAINT - registos de queixa
                                 O_HISTORY - registos de história
                                 O_OBSERVATION - registos de exame físico
                                 O_TEXT_VS - textos dos sinais vitais
                                 O_AUTHOR_VS - autor dos registos dos sinais vitais
                                 O_ERROR - erro  
          
          CRIAÇÃO: SS 2005/12/28 
          ALTERADO: ET 2007/10/10
          NOTAS: 
        *********************************************************************************/
        CURSOR c_vs IS
            SELECT vs_ea.id_vital_sign_read,
                   vs_ea.id_vital_sign,
                   vs_ea.relation_domain,
                   vs_ea.id_unit_measure,
                   vs_ea.id_vs_scales_element,
                   vs_ea.id_vital_sign_desc,
                   decode(vs_ea.relation_domain,
                          'S',
                          (SELECT vsd.value
                             FROM vital_sign_desc vsd
                            WHERE vsd.id_vital_sign_desc = vs_ea.id_vital_sign_desc),
                          vs_ea.value) VALUE,
                   TRIM(nvl(to_char(vs_ea.value),
                            pk_vital_sign.get_vs_alias(i_lang,
                                                       vs_ea.id_patient,
                                                       (SELECT vsd.code_vital_sign_desc
                                                          FROM vital_sign_desc vsd
                                                         WHERE vsd.id_vital_sign_desc = vs_ea.id_vital_sign_desc))) || ' ' ||
                        pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                  vs_ea.id_unit_measure,
                                                                  vs_ea.id_vs_scales_element)) desc_value,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT vs.code_vital_sign
                                                     FROM vital_sign vs
                                                    WHERE vs.id_vital_sign = vs_ea.id_vital_sign)) name_vs,
                   pk_date_utils.date_char_tsz(i_lang, vs_ea.dt_vital_sign_read, i_prof.institution, i_prof.software) dt_read,
                   vs_ea.id_prof_read id_prof_read,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, vs_ea.id_prof_read) prof_read,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    vs_ea.id_prof_read,
                                                    vs_ea.dt_vital_sign_read,
                                                    vs_ea.id_episode) desc_speciality
              FROM vital_signs_ea vs_ea
             WHERE vs_ea.id_episode = i_episode
               AND vs_ea.flg_state = pk_alert_constant.g_active
               AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
             ORDER BY vs_ea.dt_vital_sign_read, prof_read, relation_domain, id_vital_sign;
    
        CURSOR c_temp_compl IS
            SELECT 'Y'
              FROM epis_anamnesis e
             WHERE e.id_episode = i_episode
               AND e.flg_type = g_complaint
               AND e.flg_temp = g_flg_temp;
    
        CURSOR c_temp_anamn IS
            SELECT 'Y'
              FROM epis_anamnesis e
             WHERE e.id_episode = i_episode
               AND e.flg_type = g_anamnesis
               AND e.flg_temp = g_flg_temp;
    
        CURSOR c_temp_obs IS
            SELECT 'Y'
              FROM epis_observation e
             WHERE e.id_episode = i_episode
               AND e.flg_temp = g_flg_temp;
        --  
        l_temp_compl VARCHAR2(1);
        l_temp_anamn VARCHAR2(1);
        l_temp_obs   VARCHAR2(1);
        --    
        i          NUMBER := 0;
        j          NUMBER;
        l_first    BOOLEAN := TRUE;
        l_doit     BOOLEAN;
        l_date     VARCHAR2(50 CHAR);
        l_prof     professional.nick_name%TYPE;
        l_pressure VARCHAR2(50);
        l_glasgow  NUMBER;
    BEGIN
        -- Queixa
        g_error := 'OPEN C_TEMP_COMPL'; --último temporário
        OPEN c_temp_compl;
        FETCH c_temp_compl
            INTO l_temp_compl;
        g_found := c_temp_compl%FOUND;
        CLOSE c_temp_compl;
        --
        IF NOT g_found
        THEN
            --já passaram a definitivos
            g_error := 'GET CURSOR O_COMPLAINT1';
            OPEN o_complaint FOR
                SELECT id_epis_anamnesis,
                       desc_epis_anamnesis,
                       flg_type,
                       date_ordena,
                       nick_name,
                       dt_epis_anamnesis,
                       flg_temp,
                       clin_serv,
                       desc_speciality,
                       instit,
                       epis_anamn_type
                  FROM (SELECT NULL id_epis_anamnesis,
                               decode(et.id_triage_white_reason,
                                      NULL,
                                      NULL,
                                      pk_translation.get_translation(i_lang,
                                                                     'TRIAGE_WHITE_REASON.CODE_TRIAGE_WHITE_REASON.' ||
                                                                     et.id_triage_white_reason) || ': ' || et.notes) desc_epis_anamnesis,
                               
                               NULL             flg_type,
                               et.dt_begin_tstz date_ordena,
                               --pk_tools.get_prof_nick_name(i_lang, et.id_professional) nick_name,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, et.id_professional) nick_name,
                               
                               pk_date_utils.date_char_tsz(i_lang, et.dt_begin_tstz, i_prof.institution, i_prof.software) dt_epis_anamnesis,
                               NULL flg_temp,
                               NULL clin_serv,
                               pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                et.id_professional,
                                                                et.dt_begin_tstz,
                                                                et.id_episode) desc_speciality,
                               NULL instit,
                               pk_message.get_message(i_lang, 'CURRENT_HIST_DOCTOR_T009') epis_anamn_type
                          FROM epis_triage et
                         WHERE et.id_episode = i_episode
                           AND (et.dt_begin_tstz = (SELECT MAX(et1.dt_begin_tstz)
                                                      FROM epis_triage et1
                                                     WHERE et1.id_episode = i_episode) OR et.dt_begin_tstz IS NULL)
                        UNION ALL
                        SELECT ea.id_epis_anamnesis,
                               pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_epis_anamnesis,
                               ea.flg_type,
                               ea.dt_epis_anamnesis_tstz date_ordena,
                               --pk_tools.get_prof_nick_name(i_lang, ea.id_professional) nick_name,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name,
                               
                               pk_date_utils.date_char_tsz(i_lang,
                                                           ea.dt_epis_anamnesis_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) dt_epis_anamnesis,
                               ea.flg_temp,
                               pk_translation.get_translation(i_lang,
                                                              'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                              epis.id_clinical_service) clin_serv,
                               pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                ea.id_professional,
                                                                ea.dt_epis_anamnesis_tstz,
                                                                ea.id_episode) desc_speciality,
                               pk_tools.get_desc_institution(i_lang, ea.id_institution, g_abbreviation) instit,
                               pk_message.get_message(i_lang, i_prof, 'CURRENT_HIST_DOCTOR_T004') epis_anamn_type
                          FROM epis_anamnesis ea, episode epis
                         WHERE ea.flg_type = g_complaint
                           AND ea.id_episode = i_episode
                           AND ea.flg_temp = g_flg_def
                           AND epis.id_episode = ea.id_episode)
                 WHERE desc_epis_anamnesis IS NOT NULL
                 ORDER BY flg_temp DESC, date_ordena DESC;
        
        ELSE
            g_error := 'GET CURSOR O_COMPLAINT2';
            OPEN o_complaint FOR
                SELECT id_epis_anamnesis,
                       desc_epis_anamnesis,
                       flg_type,
                       date_ordena,
                       nick_name,
                       dt_epis_anamnesis,
                       flg_temp,
                       clin_serv,
                       desc_speciality,
                       instit,
                       epis_anamn_type
                  FROM (SELECT NULL id_epis_anamnesis,
                               decode(et.id_triage_white_reason,
                                      NULL,
                                      NULL,
                                      pk_translation.get_translation(i_lang,
                                                                     'TRIAGE_WHITE_REASON.CODE_TRIAGE_WHITE_REASON.' ||
                                                                     et.id_triage_white_reason) || ': ' || et.notes) desc_epis_anamnesis,
                               
                               NULL             flg_type,
                               et.dt_begin_tstz date_ordena,
                               --pk_tools.get_prof_nick_name(i_lang, et.id_professional) nick_name,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, et.id_professional) nick_name,
                               
                               pk_date_utils.date_char_tsz(i_lang, et.dt_begin_tstz, i_prof.institution, i_prof.software) dt_epis_anamnesis,
                               NULL flg_temp,
                               NULL clin_serv,
                               pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                et.id_professional,
                                                                et.dt_begin_tstz,
                                                                et.id_episode) desc_speciality,
                               NULL instit,
                               pk_message.get_message(i_lang, 'CURRENT_HIST_DOCTOR_T009') epis_anamn_type
                          FROM epis_triage et
                         WHERE et.id_episode = i_episode
                           AND (et.dt_begin_tstz = (SELECT MAX(et1.dt_begin_tstz)
                                                      FROM epis_triage et1
                                                     WHERE et1.id_episode = i_episode) OR et.dt_begin_tstz IS NULL)
                        UNION ALL
                        SELECT ea.id_epis_anamnesis,
                               pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_epis_anamnesis,
                               ea.flg_type,
                               ea.dt_epis_anamnesis_tstz date_ordena,
                               --pk_tools.get_prof_nick_name(i_lang, ea.id_professional) nick_name,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name,
                               
                               pk_date_utils.date_char_tsz(i_lang,
                                                           ea.dt_epis_anamnesis_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) dt_epis_anamnesis,
                               ea.flg_temp,
                               pk_translation.get_translation(i_lang,
                                                              'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                              epis.id_clinical_service) clin_serv,
                               pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                ea.id_professional,
                                                                ea.dt_epis_anamnesis_tstz,
                                                                ea.id_episode) desc_speciality,
                               pk_tools.get_desc_institution(i_lang, ea.id_institution, g_abbreviation) instit,
                               pk_message.get_message(i_lang, i_prof, 'CURRENT_HIST_DOCTOR_T004') epis_anamn_type
                          FROM epis_anamnesis ea, episode epis
                         WHERE ea.flg_type = g_complaint
                           AND ea.id_episode = i_episode
                           AND ea.flg_temp = g_flg_temp
                           AND epis.id_episode = ea.id_episode)
                 WHERE desc_epis_anamnesis IS NOT NULL
                 ORDER BY flg_temp DESC, date_ordena DESC;
        END IF;
        --
        -- História
        g_error := 'OPEN C_TEMP_ANAMN';
        OPEN c_temp_anamn;
        FETCH c_temp_anamn
            INTO l_temp_anamn;
        g_found := c_temp_anamn%FOUND;
        CLOSE c_temp_anamn;
        --    
        IF NOT g_found
        THEN
            --já passaram a definitivos
            g_error := 'GET CURSOR O_HISTORY1';
            OPEN o_history FOR
                SELECT ea.id_epis_anamnesis,
                       ea.desc_epis_anamnesis,
                       ea.flg_type,
                       --pk_tools.get_prof_nick_name(i_lang, ea.id_professional) nick_name,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name,
                       
                       pk_date_utils.date_char_tsz(i_lang,
                                                   ea.dt_epis_anamnesis_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_epis_anamnesis,
                       ea.flg_temp,
                       pk_translation.get_translation(i_lang,
                                                      'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                      epis.id_clinical_service) clin_serv,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        ea.id_professional,
                                                        ea.dt_epis_anamnesis_tstz,
                                                        ea.id_episode) desc_speciality,
                       pk_tools.get_desc_institution(i_lang, ea.id_institution, g_abbreviation) instit,
                       pk_message.get_message(i_lang, 'CURRENT_HIST_DOCTOR_T005') epis_anamn_type
                  FROM epis_anamnesis ea, episode epis
                 WHERE ea.flg_type = g_anamnesis
                   AND ea.id_episode = i_episode
                   AND ea.flg_temp = g_flg_def
                   AND epis.id_episode = ea.id_episode
                 ORDER BY ea.flg_temp DESC, ea.dt_epis_anamnesis_tstz DESC;
        ELSE
            g_error := 'GET CURSOR O_HISTORY2';
            OPEN o_history FOR
                SELECT ea.id_epis_anamnesis,
                       ea.desc_epis_anamnesis,
                       ea.flg_type,
                       --pk_tools.get_prof_nick_name(i_lang, ea.id_professional) nick_name,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name,
                       
                       pk_date_utils.date_char_tsz(i_lang,
                                                   ea.dt_epis_anamnesis_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_epis_anamnesis,
                       ea.flg_temp,
                       pk_translation.get_translation(i_lang,
                                                      'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                      epis.id_clinical_service) clin_serv,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        ea.id_professional,
                                                        ea.dt_epis_anamnesis_tstz,
                                                        ea.id_episode) desc_speciality,
                       pk_tools.get_desc_institution(i_lang, ea.id_institution, g_abbreviation) instit,
                       pk_message.get_message(i_lang, 'CURRENT_HIST_DOCTOR_T005') epis_anamn_type
                  FROM epis_anamnesis ea, episode epis
                 WHERE ea.flg_type = g_anamnesis
                   AND ea.id_episode = i_episode
                   AND ea.flg_temp = g_flg_temp
                   AND epis.id_episode = ea.id_episode
                 ORDER BY ea.flg_temp DESC, ea.dt_epis_anamnesis_tstz DESC;
        END IF;
        --  
        -- Exame físico
        g_error := 'OPEN C_TEMP_OBS'; --último temporário
        OPEN c_temp_obs;
        FETCH c_temp_obs
            INTO l_temp_obs;
        g_found := c_temp_obs%FOUND;
        CLOSE c_temp_obs;
        --
        IF NOT g_found
        THEN
            --já passaram a definitivos
            g_error := 'GET CURSOR O_OBSERVATION1';
            OPEN o_observation FOR
                SELECT e.id_epis_observation,
                       e.desc_epis_observation,
                       --pk_tools.get_prof_nick_name(i_lang, e.id_professional) nick_name,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional) nick_name,
                       
                       pk_date_utils.date_char_tsz(i_lang,
                                                   e.dt_epis_observation_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_epis_observation,
                       flg_temp,
                       pk_translation.get_translation(i_lang,
                                                      'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                      epis.id_clinical_service) clin_serv,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        e.id_professional,
                                                        e.dt_epis_observation_tstz,
                                                        e.id_episode) desc_speciality,
                       pk_tools.get_desc_institution(i_lang, e.id_institution, g_abbreviation) instit,
                       pk_message.get_message(i_lang, 'PHYSICAL_EXAM_T009') epis_obs_type
                  FROM epis_observation e, episode epis
                 WHERE e.id_episode = i_episode
                   AND e.flg_temp = g_flg_def
                   AND epis.id_episode = e.id_episode
                 ORDER BY flg_temp DESC, e.dt_epis_observation_tstz DESC;
        ELSE
            g_error := 'GET CURSOR O_OBSERVATION2';
            OPEN o_observation FOR
                SELECT e.id_epis_observation,
                       e.desc_epis_observation,
                       --pk_tools.get_prof_nick_name(i_lang, e.id_professional) nick_name,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional) nick_name,
                       
                       pk_date_utils.date_char_tsz(i_lang,
                                                   e.dt_epis_observation_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_epis_observation,
                       flg_temp,
                       pk_translation.get_translation(i_lang,
                                                      'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                      epis.id_clinical_service) clin_serv,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        e.id_professional,
                                                        e.dt_epis_observation_tstz,
                                                        e.id_episode) desc_speciality,
                       pk_tools.get_desc_institution(i_lang, e.id_institution, g_abbreviation) instit,
                       pk_message.get_message(i_lang, 'PHYSICAL_EXAM_T009') epis_obs_type
                  FROM epis_observation e, episode epis
                 WHERE e.id_episode = i_episode
                   AND e.flg_temp = g_flg_temp
                   AND epis.id_episode = e.id_episode
                 ORDER BY flg_temp DESC, e.dt_epis_observation_tstz DESC;
        END IF;
        --
        -- Sinais vitais
        g_error     := 'INITIALIZATION';
        o_text_vs   := table_varchar(); -- inicialização do vector
        o_author_vs := table_varchar(); -- inicialização do vector
        --
        g_error := 'GET CURSOR C_VITAL_SIGN';
        FOR c_vital_sign IN c_vs
        LOOP
            -- se for a 1ª vez (L_DATE IS NULL) ou se a data da leitura actual for diferente da data da leitura anterior
            IF l_date IS NULL
               OR l_date != c_vital_sign.dt_read
            THEN
                g_error := 'IF L_DATE IS NULL OR L_DATE != C_VITAL_SIGN.DT_READ';
                i       := i + 1; -- novo índice dos arrays
                l_first := TRUE; -- é a 1ª leitura dessa linha
                o_text_vs.extend; -- o array O_TEXT_VS tem mais uma linha
                o_author_vs.extend; -- o array O_AUTHOR_VS tem mais uma linha
            
                -- se a data da leitura actual for igual à data da leitura anterior mas o 
                -- profissional da leitura actual for diferente do profissional da leitura anterior
            ELSIF l_prof != c_vital_sign.prof_read
            THEN
                g_error := 'IF L_PROF != C_VITAL_SIGN.PROF_READ';
                i       := i + 1; -- novo índice dos arrays
                l_first := TRUE; -- é a 1ª leitura dessa linha
                o_text_vs.extend; -- o array O_TEXT_VS tem mais uma linha
                o_author_vs.extend; -- o array O_AUTHOR_VS tem mais uma linha
            END IF;
            --
            IF c_vital_sign.relation_domain = 'S'
            THEN
                -- GLASGOW
                g_error   := 'GLASGOW';
                j         := nvl(j, 0) + 1;
                l_glasgow := nvl(l_glasgow, 0) + c_vital_sign.value; -- total de Glasgow
                l_doit    := TRUE; -- escreve valor
            
            ELSIF c_vital_sign.relation_domain = 'C'
            THEN
                -- PRESSÃO
                g_error := 'PRESSÃO';
                j       := nvl(j, 0) + 1;
            
                IF j < 2
                THEN
                    -- se for a primeira leitura (pressão sistólica) não escreve
                    l_pressure := c_vital_sign.value;
                    l_doit     := FALSE;
                ELSE
                    -- concatena a 1ª com a 2ª e escreve
                    l_pressure := l_pressure || '/' || c_vital_sign.desc_value;
                    l_doit     := TRUE;
                END IF; -- J
            ELSE
                -- outros sinais vitais, escreve
                g_error := 'OTHER';
                l_doit  := TRUE;
            END IF; -- RELATION_DOMAIN
            --
            IF l_doit
            THEN
                -- se é para escrever
                g_error := 'L_DOIT TRUE';
            
                IF l_first
                THEN
                    -- se é a primeira leitura de uma linha
                    g_error := 'L_FIRST TRUE';
                
                    IF c_vital_sign.relation_domain = 'C'
                    THEN
                        -- PRESSÃO
                        g_error := 'GET CURSOR L_DOIT PRESSAO = 1ª leitura da linha';
                        o_text_vs(i) := c_vital_sign.name_vs || ': ' || l_pressure;
                        l_first := FALSE; -- próxima leitura já não é a 1ª desta linha
                        j := 0;
                    ELSE
                        g_error := 'GET CURSOR L_DOIT = 1ª leitura da linha';
                        o_text_vs(i) := c_vital_sign.name_vs || ': ' || c_vital_sign.desc_value;
                        l_first := FALSE; -- próxima leitura já não é a 1ª desta linha
                    END IF;
                ELSE
                    -- se não é  1ª leitura da linha
                    g_error := 'L_FIRST FALSE';
                    --
                    IF c_vital_sign.relation_domain = 'C'
                    THEN
                        -- PRESSãO
                        g_error := 'PRESSAO != 1ª leitura da linha';
                        o_text_vs(i) := o_text_vs(i) || chr(10) || c_vital_sign.name_vs || ': ' || l_pressure; --odete monteiro 22/9/2007 substitui o <br> por chr(10)
                        j := 0; -- limpa o J para q esteja tudo correcto se houver leitura de Glasglow
                    ELSE
                        -- se são outros sinais vitais então concatena com as leituras anteriores 
                        g_error := 'outros sinais != 1ª leitura da linha';
                        o_text_vs(i) := o_text_vs(i) || chr(10) || c_vital_sign.name_vs || ': ' || --odete monteiro 22/9/2007 substitui o <br> por chr(10)
                                        c_vital_sign.desc_value;
                    
                        IF c_vital_sign.relation_domain = 'S'
                           AND j = 3
                        THEN
                            -- se for Glasgow e foi a última leitura, então escreve o total
                            g_error := 'TOTAL DE GLASGOW';
                            o_text_vs(i) := o_text_vs(i) || chr(10) || --odete monteiro 22/9/2007 substitui o <br> por chr(10)
                                            pk_translation.get_translation(i_lang, 'VITAL_SIGN.CODE_VITAL_SIGN.18') || ': ' ||
                                            l_glasgow; -- TOTAL DE GLASGOW        
                            j := 0; -- limpa o J para q esteja tudo correcto se houver leitura de pressão
                        END IF;
                    
                    END IF;
                END IF;
            
                -- autor da leitura
                IF c_vital_sign.desc_speciality IS NULL
                THEN
                    -- se não tem especialidade (se é enfermeiro) então só apareec instituição
                    g_error := 'C_VITAL_SIGN.DESC_SPECIALITY IS NULL';
                    o_author_vs(i) := c_vital_sign.dt_read || ' / ' || c_vital_sign.prof_read; -- || ' / ' ||
                    --c_vital_sign.instit;
                ELSE
                    g_error := 'C_VITAL_SIGN.DESC_SPECIALITY IS NOT NULL';
                    o_author_vs(i) := c_vital_sign.dt_read || ' / ' || c_vital_sign.prof_read -- || ' / ' ||
                                      || ' (' || c_vital_sign.desc_speciality || ')'; -- || ', ' || c_vital_sign.instit;
                END IF;
            END IF;
        
            g_error := 'C_VITAL_SIGN.DT_READ';
            l_date  := c_vital_sign.dt_read;
            g_error := 'C_VITAL_SIGN.PROF_READ';
            l_prof  := c_vital_sign.prof_read;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_text_vs   := table_varchar(); -- inicialização do vector
            o_author_vs := table_varchar(); -- inicialização do vector
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_AVAILABLE_INFO',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_complaint);
            pk_types.open_my_cursor(o_history);
            pk_types.open_my_cursor(o_observation);
            RETURN FALSE;
    END;
    --
    FUNCTION set_epis_problem
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN epis_anamnesis.id_episode%TYPE,
        i_prof          IN profissional,
        i_desc          IN epis_problem.desc_epis_problem%TYPE,
        i_pat_problem   IN epis_problem.id_pat_problem%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar problemas do episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                 I_EPISODE - ID do episódio 
                                 I_PROF - ID do profissional q regista 
                                 I_DESC - problema  
                                 I_PAT_PROBLEM - problema registado no processo clínico do doente
                        Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/04 
          NOTAS: Se o problema deste episódio é um problema do proc. clínico do doente, 
                 I_PAT_PROBLEM está preenchido. Nesse caso, I_DESC é o descritivo do problema já registado em PAT_PROBLEM. 
        *********************************************************************************/
        l_next epis_problem.id_epis_problem%TYPE;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --    
        IF i_desc IS NOT NULL
           AND i_pat_problem IS NOT NULL
        THEN
            g_error := REPLACE(REPLACE(pk_message.get_message(i_lang, 'COMMON_M006'), '@1', 'descritivo'),
                               '@2',
                               'problema do processo clínico');
            ROLLBACK;
            --RETURN FALSE;
            raise_application_error('20001', g_error);
        END IF;
        --  
        g_error := 'GET SEQ_EPIS_PROBLEM.NEXTVAL';
        SELECT seq_epis_problem.nextval
          INTO l_next
          FROM dual;
        --
        g_error := 'INSERT EPIS_PROBLEM';
        INSERT INTO epis_problem
            (id_epis_problem, dt_epis_problem_tstz, desc_epis_problem, id_episode, id_professional, id_pat_problem)
        VALUES
            (l_next, g_sysdate_tstz, i_desc, i_episode, i_prof.id, i_pat_problem);
        --
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'SET_EPIS_PROBLEM',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    --
    FUNCTION get_epis_problem
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_anamnesis.id_episode%TYPE,
        i_prof    IN profissional,
        o_desc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter problemas do episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                 I_EPISODE - ID do episódio 
                        Saida:   O_DESC - texto do problema, ID do autor e data de registo 
                                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/04 
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_desc FOR
            SELECT e.desc_epis_problem,
                   --pk_tools.get_prof_nick_name(i_lang, e.id_professional) nick_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional) nick_name,
                   
                   pk_date_utils.date_char_tsz(i_lang, e.dt_epis_problem_tstz, i_prof.institution, i_prof.software) dt_epis_problem
              FROM epis_problem e
             WHERE e.id_episode = i_episode
             ORDER BY e.dt_epis_problem_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_PROBLEM',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_desc);
            RETURN FALSE;
    END;
    --
    --
    FUNCTION set_epis_obs_exam
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN epis_obs_exam.id_episode%TYPE,
        i_prof             IN profissional,
        i_exam             IN epis_obs_exam.id_periodic_exam_educ%TYPE,
        i_desc             IN epis_obs_exam.desc_epis_obs_exam%TYPE,
        i_flg_brd          IN epis_obs_exam.flg_brd%TYPE,
        i_flg_na           IN epis_obs_exam.flg_na%TYPE,
        i_id_epis_obs_exam IN epis_obs_exam.id_epis_obs_exam%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar observações relativas a exames periódicos no episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_EPISODE - ID do episódio 
                       I_PROF - ID do profissional q regista 
                     I_EXAM - exame periódico a q se refere a observação 
                     I_DESC - observação 
                     I_FLG_BRD - Classificação (facultativa) do parâmetro examinado: 
                             B - bom, R - regular, D - deficiente 
                     I_FLG_NA - Classificação (facultativa) do parâmetro examinado: 
                            N - normal, A - anormal 
                     I_ID_EPIS_OBS_EXAM - ID do registo. Se é null é um novo registo e deve ser inserido. Se já existe, pode ser um registo
                                 temporário e deve ser actualizado/eliminado. 
                     I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                               como é retornada em PK_LOGIN.GET_PROF_PREF 
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/04 
          NOTAS: 
        *********************************************************************************/
    
        CURSOR c_obs_exam IS
            SELECT *
              FROM epis_obs_exam
             WHERE id_epis_obs_exam = i_id_epis_obs_exam
               AND id_professional = i_prof.id;
    
        l_next          epis_obs_exam.id_epis_obs_exam%TYPE;
        v_epis_obs_exam epis_obs_exam%ROWTYPE;
    
        l_error t_error_out;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        o_error        := NULL;
    
        g_error         := 'GET LAST ID_EPIS_OBS_EXAM';
        v_epis_obs_exam := NULL;
        --Verificar se o registo é novo ou já existe
        OPEN c_obs_exam;
        FETCH c_obs_exam
            INTO v_epis_obs_exam;
        CLOSE c_obs_exam;
    
        --Actualiza novo valor no rowtype
        v_epis_obs_exam.desc_epis_obs_exam := i_desc;
    
        IF v_epis_obs_exam.id_epis_obs_exam IS NULL
        THEN
            g_error := 'GET SEQ_EPIS_OBS_EXAM.NEXTVAL';
            SELECT seq_epis_obs_exam.nextval
              INTO l_next
              FROM dual;
        
            g_error := 'INSERT EPIS_OBS_EXAM';
            INSERT INTO epis_obs_exam
                (id_epis_obs_exam,
                 dt_epis_obs_exam_tstz,
                 desc_epis_obs_exam,
                 id_episode,
                 id_professional,
                 id_periodic_exam_educ,
                 flg_brd,
                 flg_na,
                 flg_temp)
            VALUES
                (l_next, g_sysdate_tstz, i_desc, i_episode, i_prof.id, i_exam, i_flg_brd, i_flg_na, g_flg_def);
        
            g_error := 'CALL TO SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_episode,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => i_prof_cat_type,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
        o_error := l_error;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'SET_EPIS_OBS_EXAM',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_epis_obs_exam
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_obs_exam.id_episode%TYPE,
        i_exam    IN epis_obs_exam.id_periodic_exam_educ%TYPE,
        i_prof    IN profissional,
        o_desc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter observações relativas a um determinado exame periódico, 
                  se I_EXAM estiver preenchido, ou todas as obs. do episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_EPISODE - ID do episódio 
                     I_EXAM - exame periódico cuja observação se pretende  
                  Saida:   O_DESC - texto da observação, ID do autor e 
                          data de registo 
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/04 
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_desc FOR
            SELECT e.desc_epis_obs_exam,
                   --pk_tools.get_prof_nick_name(i_lang, e.id_professional) nick_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional) nick_name,
                   
                   e.id_periodic_exam_educ,
                   pk_sysdomain.get_domain('EPIS_OBS_EXAM.FLG_BRD', e.flg_brd, i_lang) flg_brd,
                   pk_sysdomain.get_domain('EPIS_OBS_EXAM.FLG_NA', e.flg_na, i_lang) flg_na,
                   pk_date_utils.date_char_tsz(i_lang, e.dt_epis_obs_exam_tstz, i_prof.institution, i_prof.software) dt_epis_obs_exam,
                   flg_temp
              FROM epis_obs_exam e
             WHERE e.id_episode = i_episode
               AND e.id_periodic_exam_educ = nvl(i_exam, e.id_periodic_exam_educ)
             ORDER BY e.dt_epis_obs_exam_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_OBS_EXAM',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_desc);
            RETURN FALSE;
    END;

    FUNCTION set_epis_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN epis_diagnosis.id_episode%TYPE,
        i_prof          IN profissional,
        i_diagnosis     IN epis_diagnosis.id_diagnosis%TYPE,
        i_type          IN epis_diagnosis.flg_type%TYPE,
        i_notes         IN epis_diagnosis.notes%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar diagnóstico 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                 I_EPISODE - ID do episódio 
                 I_PROF - ID do profissional q regista 
                 I_DIAGNOSIS - ID do diagnóstico 
                 I_TYPE - P - provável 
                      D - definitivo 
                 I_NOTES - notas 
                 I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                       como é retornada em PK_LOGIN.GET_PROF_PREF 
                  Saida: O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/04 
          NOTAS: 
        *********************************************************************************/
        l_next      epis_diagnosis.id_epis_diagnosis%TYPE;
        l_char      VARCHAR2(1);
        l_diag      pk_translation.t_desc_translation;
        l_pat       visit.id_patient%TYPE;
        l_flg_show  VARCHAR2(1);
        l_msg_title VARCHAR2(2000);
        l_msg_text  VARCHAR2(2000);
        l_button    VARCHAR2(6);
        l_rowids    table_varchar;
    
        CURSOR c_epis_diag IS
            SELECT 'X'
              FROM epis_diagnosis
             WHERE id_episode = i_episode
               AND id_diagnosis = i_diagnosis
               AND dt_cancel_tstz IS NULL;
    
        CURSOR c_desc_diag IS
            SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_id_alert_diagnosis => NULL,
                                              i_id_diagnosis       => d.id_diagnosis,
                                              i_code               => d.code_icd,
                                              i_flg_other          => d.flg_other,
                                              i_flg_std_diag       => pk_alert_constant.g_yes)
              FROM (SELECT DISTINCT id_diagnosis, code_icd, flg_other
                      FROM diagnosis_content
                     WHERE id_diagnosis = i_diagnosis) d;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN CURSOR C_EPIS_DIAG';
        OPEN c_epis_diag;
        FETCH c_epis_diag
            INTO l_char;
        g_found := c_epis_diag%FOUND;
        CLOSE c_epis_diag;
        IF g_found
        THEN
            -- Este diagnóstico já existe neste episódio 
            g_error := pk_message.get_message(i_lang, 'CLINICAL_INFO_M001');
            raise_application_error('20001', g_error);
        END IF;
    
        g_error := 'GET ID_PATIENT';
        SELECT id_patient
          INTO l_pat
          FROM episode
         WHERE id_episode = i_episode;
    
        g_error := 'GET SEQ_EPIS_DIAGNOSIS.NEXTVAL';
        l_next  := ts_epis_diagnosis.next_key();
    
        g_error  := 'INSERT EPIS_DIAGNOSIS';
        l_rowids := NULL;
        ts_epis_diagnosis.ins(id_epis_diagnosis_in      => l_next,
                              dt_epis_diagnosis_tstz_in => g_sysdate_tstz,
                              flg_status_in             => g_epis_diag_act,
                              notes_in                  => i_notes,
                              id_episode_in             => i_episode,
                              id_patient_in             => l_pat,
                              id_professional_diag_in   => i_prof.id,
                              flg_type_in               => i_type,
                              id_diagnosis_in           => i_diagnosis,
                              rows_out                  => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_DIAGNOSIS',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'CALL TO PK_PATIENT.SET_PAT_PROBLEM';
        IF NOT pk_patient.set_pat_problem(i_lang          => i_lang,
                                          i_epis          => i_episode,
                                          i_pat           => l_pat,
                                          i_pat_problem   => NULL,
                                          i_prof          => i_prof,
                                          i_diag          => NULL,
                                          i_desc          => NULL,
                                          i_notes         => NULL,
                                          i_age           => NULL,
                                          i_dt_symptoms   => NULL,
                                          i_flg_approved  => g_aproved_clin,
                                          i_pct           => NULL,
                                          i_surgery       => NULL,
                                          i_notes_support => NULL,
                                          i_dt_confirm    => NULL,
                                          i_rank          => NULL,
                                          i_status        => g_pat_prob_active,
                                          i_epis_diag     => l_next,
                                          i_prof_cat_type => i_prof_cat_type,
                                          o_flg_show      => l_flg_show,
                                          o_msg_title     => l_msg_title,
                                          o_msg_text      => l_msg_text,
                                          o_button        => l_button,
                                          o_error         => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR C_DESC_DIAG';
        OPEN c_desc_diag;
        FETCH c_desc_diag
            INTO l_diag;
        CLOSE c_desc_diag;
    
        g_error := 'CALL TO UPDATE_EPIS_INFO';
        IF NOT pk_visit.update_epis_info(i_lang         => i_lang,
                                         i_id_episode   => i_episode,
                                         i_id_room      => NULL,
                                         i_bed          => NULL,
                                         i_norton       => NULL,
                                         i_professional => NULL,
                                         i_flg_hydric   => NULL,
                                         i_flg_wound    => NULL,
                                         i_companion    => NULL,
                                         i_flg_unknown  => NULL,
                                         i_desc_info    => l_diag,
                                         i_prof         => i_prof,
                                         o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'SET_EPIS_DIAGNOSIS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION set_epis_diagnosis_array
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN epis_diagnosis.id_episode%TYPE,
        i_prof          IN profissional,
        i_diagnosis     IN table_number,
        i_type          IN table_varchar,
        i_notes         IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_desc_diag     IN epis_diagnosis.desc_epis_diagnosis%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar diagnóstico 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                 I_EPISODE - ID do episódio 
                 I_PROF - ID do profissional q regista 
                 I_DIAGNOSIS - Array de IDs de diagnósticos 
                 I_TYPE - Array, mas tem sempre uma só posição 
                  P - provável 
                  D - definitivo 
                 I_NOTES - Array de notas, mas tem sempre uma só posição 
                 I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                       como é retornada em PK_LOGIN.GET_PROF_PREF 
                 I_DESC_DIAG - descritivo do diagnóstico (no caso de "outro diagnóstico") 
                  Saida: O_ERROR - erro 
          
          CRIAÇÃO: RB 2005/03/27 
          NOTAS: 
        *********************************************************************************/
        l_next      epis_diagnosis.id_epis_diagnosis%TYPE;
        l_char      VARCHAR2(1);
        l_diag      pk_translation.t_desc_translation;
        l_last_diag NUMBER;
        l_pat       visit.id_patient%TYPE;
        l_flg_show  VARCHAR2(1);
        l_msg_title VARCHAR2(2000);
        l_msg_text  VARCHAR2(2000);
        l_button    VARCHAR2(6);
        l_rowids    table_varchar;
    
        CURSOR c_epis_diag
        (
            i_episode   NUMBER,
            i_diagnosis NUMBER
        ) IS
            SELECT 'X'
              FROM epis_diagnosis
             WHERE id_episode = i_episode
               AND id_diagnosis = i_diagnosis
               AND dt_cancel_tstz IS NULL
               AND desc_epis_diagnosis IS NULL;
    
        CURSOR c_desc_diag(i_diagnosis NUMBER) IS
            SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_id_alert_diagnosis => NULL,
                                              i_id_diagnosis       => d.id_diagnosis,
                                              i_code               => d.code_icd,
                                              i_flg_other          => d.flg_other,
                                              i_flg_std_diag       => pk_alert_constant.g_yes)
              FROM (SELECT DISTINCT id_diagnosis, code_icd, flg_other
                      FROM diagnosis_content
                     WHERE id_diagnosis = i_diagnosis) d;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET ID_PATIENT';
        SELECT id_patient
          INTO l_pat
          FROM episode
         WHERE id_episode = i_episode;
    
        FOR i IN 1 .. i_diagnosis.count
        LOOP
            -- Loop sobre o array de descritivos
            l_last_diag := i_diagnosis(i);
            g_error     := 'OPEN CURSOR C_EPIS_DIAG';
            OPEN c_epis_diag(i_episode, i_diagnosis(i));
            FETCH c_epis_diag
                INTO l_char;
            g_found := c_epis_diag%FOUND;
            CLOSE c_epis_diag;
        
            IF g_found
            THEN
                -- Este diagnóstico já existe neste episódio 
                g_error := pk_message.get_message(i_lang, 'CLINICAL_INFO_M001');
                raise_application_error('20001', g_error);
            END IF;
        
            g_error := 'GET SEQ_EPIS_DIAGNOSIS.NEXTVAL';
            l_next  := ts_epis_diagnosis.next_key();
        
            g_error := 'INSERT EPIS_DIAGNOSIS';
            ts_epis_diagnosis.ins(id_epis_diagnosis_in      => l_next,
                                  dt_epis_diagnosis_tstz_in => g_sysdate_tstz,
                                  flg_status_in             => g_epis_diag_act,
                                  notes_in                  => i_notes(1),
                                  id_episode_in             => i_episode,
                                  id_patient_in             => l_pat,
                                  id_professional_diag_in   => i_prof.id,
                                  flg_type_in               => i_type(1),
                                  id_diagnosis_in           => i_diagnosis(i),
                                  desc_epis_diagnosis_in    => i_desc_diag,
                                  rows_out                  => l_rowids);
        
            g_error := 'CALL TO PK_PATIENT.SET_PAT_PROBLEM';
            IF NOT pk_patient.set_pat_problem(i_lang          => i_lang,
                                              i_epis          => i_episode,
                                              i_pat           => l_pat,
                                              i_pat_problem   => NULL,
                                              i_prof          => i_prof,
                                              i_diag          => NULL,
                                              i_desc          => NULL,
                                              i_notes         => NULL,
                                              i_age           => NULL,
                                              i_dt_symptoms   => NULL,
                                              i_flg_approved  => g_aproved_clin,
                                              i_pct           => NULL,
                                              i_surgery       => NULL,
                                              i_notes_support => NULL,
                                              i_dt_confirm    => NULL,
                                              i_rank          => NULL,
                                              i_status        => g_pat_prob_active,
                                              i_epis_diag     => l_next,
                                              i_prof_cat_type => i_prof_cat_type,
                                              o_flg_show      => l_flg_show,
                                              o_msg_title     => l_msg_title,
                                              o_msg_text      => l_msg_text,
                                              o_button        => l_button,
                                              o_error         => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END LOOP;
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_DIAGNOSIS',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR C_DESC_DIAG';
        OPEN c_desc_diag(l_last_diag);
        FETCH c_desc_diag
            INTO l_diag;
        CLOSE c_desc_diag;
    
        g_error := 'CALL TO UPDATE_EPIS_INFO';
        IF NOT pk_visit.update_epis_info(i_lang         => i_lang,
                                         i_id_episode   => i_episode,
                                         i_id_room      => NULL,
                                         i_bed          => NULL,
                                         i_norton       => NULL,
                                         i_professional => NULL,
                                         i_flg_hydric   => NULL,
                                         i_flg_wound    => NULL,
                                         i_companion    => NULL,
                                         i_flg_unknown  => NULL,
                                         i_desc_info    => l_diag,
                                         i_prof         => i_prof,
                                         o_error        => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'SET_EPIS_DIAGNOSIS_ARRAY',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_epis_diag_list
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN epis_diagnosis.id_episode%TYPE,
        i_type      IN epis_diagnosis.flg_type%TYPE,
        i_status    IN epis_diagnosis.flg_status%TYPE,
        i_prof      IN profissional,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter diagnósticos do episódio  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                 I_EPISODE - ID do episódio 
                 I_TYPE - P - provável 
                      D - definitivo 
                         Se ñ está preenchido, retorna qq tipo 
                 I_STATUS - estado do registo (activo / cancelado). 
                    Se ñ está preenchido, retorna todos os registos 
                  Saida: O_DESC - diagnóstico, ID do autor e data de registo 
                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/04 
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_diagnosis FOR
            SELECT e.id_epis_diagnosis,
                   --pk_tools.get_prof_nick_name(i_lang, e.id_professional_diag) nick_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional_diag) nick_name,
                   e.id_diagnosis,
                   pk_sysdomain.get_domain('EPIS_DIAGNOSIS.FLG_TYPE', e.flg_type, i_lang) TYPE,
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => e.id_alert_diagnosis,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => e.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => pk_alert_constant.g_yes,
                                              i_epis_diag           => e.id_epis_diagnosis) diag,
                   pk_date_utils.dt_chr_tsz(i_lang, e.dt_epis_diagnosis_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    e.dt_epis_diagnosis_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_target,
                   e.flg_status,
                   pk_sysdomain.get_domain('EPIS_DIAGNOSIS.FLG_STATUS', e.flg_status, i_lang) flg_status_desc, -- CHR(10)CHR(10)
                   decode(e.notes,
                          '',
                          decode(e.notes_cancel, '', '', pk_message.get_message(i_lang, 'COMMON_M008')),
                          pk_message.get_message(i_lang, 'COMMON_M008')) title_notes,
                   pk_message.get_message(i_lang, 'COMMON_M008') status,
                   decode(e.flg_status, g_epis_diag_can, 'Y', 'N') flg_cancel,
                   pk_date_utils.to_char_insttimezone(i_prof, e.dt_epis_diagnosis_tstz, 'YYYYMMDDHH24MISS') dt_ord1
              FROM epis_diagnosis e
              JOIN diagnosis d
                ON d.id_diagnosis = e.id_diagnosis
             WHERE e.id_episode = i_episode
               AND e.flg_type = nvl(i_type, e.flg_type)
               AND e.flg_status = nvl(i_status, e.flg_status)
             ORDER BY pk_sysdomain.get_rank(i_lang, 'EPIS_DIAGNOSIS.FLG_STATUS', e.flg_status),
                      e.dt_epis_diagnosis_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_DIAGNOSIS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END;

    FUNCTION get_epis_diag_det
    (
        i_lang      IN language.id_language%TYPE,
        i_epis_diag epis_diagnosis.id_epis_diagnosis%TYPE,
        i_prof      IN profissional,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter detalhe do diagnóstico   
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_DIAG - ID do registo  
                  Saida: O_DESC - detalhe do diagnóstico 
                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/31 
          NOTAS: 
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_diagnosis FOR 'SELECT  DECODE(E.NOTES, NULL, ''N'', ''R'') REG, E.ID_EPIS_DIAGNOSIS, P.NICK_NAME PROF_DIAG, NVL(E.NOTES,PK_MESSAGE.GET_MESSAGE(' || i_lang || ', ''COMMON_M007'')) NOTES, ' || --
         'PK_DATE_UTILS.DATE_CHAR_TSZ(' || i_lang || ', E.DT_EPIS_DIAGNOSIS_TSTZ, ' || i_prof.institution || ', ' || i_prof.software || ') DT_EPIS_DIAGNOSIS,' || --
         'PK_SYSDOMAIN.GET_DOMAIN(''EPIS_DIAGNOSIS.FLG_STATUS'', E.FLG_STATUS, ' || i_lang || ') DESC_FLG_STATUS,' || --
         'P1.NICK_NAME PROF_CANCEL, E.NOTES_CANCEL, ' || --
         'PK_DATE_UTILS.DATE_CHAR_TSZ(' || i_lang || ', E.DT_CANCEL_TSTZ, ' || i_prof.institution || ', ' || i_prof.software || ') DT_CANCEL,' || --
         'DECODE(E.FLG_STATUS, ''' || g_epis_diag_can || ''', PK_MESSAGE.GET_MESSAGE(' || i_lang || ', ''COMMON_M017''), '''') TITLE_CANCEL,' || --
        --'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', S1.CODE_SPECIALITY) DESC_SPECIALITY,' || --
         'pk_prof_utils.get_spec_signature(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ') ||, e.id_professional, e.DT_EPIS_DIAGNOSIS_TSTZ, e.id_episode)  DESC_SPECIALITY,' || --
        
        --'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', S2.CODE_SPECIALITY) DESC_SPECIALITY_CANCEL,' || 'PK_SYSDOMAIN.GET_DOMAIN(''EPIS_DIAGNOSIS.FLG_TYPE'', E.FLG_TYPE, ' || i_lang || ') TYPE, ' || --
         'pk_prof_utils.get_spec_signature(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ') ||, e.id_professional_cancel, e.DT_CANCEL_TSTZ, e.id_episode)  DESC_SPECIALITY_CANCEL,' || 'PK_SYSDOMAIN.GET_DOMAIN(''EPIS_DIAGNOSIS.FLG_TYPE'', E.FLG_TYPE, ' || i_lang || ') TYPE, ' || --
         'pk_diagnosis.std_diag_desc(i_lang => ' || i_lang || ', ' || 'i_prof => profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), ' || 'i_id_diagnosis => d.id_diagnosis, ' || 'i_desc_epis_diagnosis => e.desc_epis_diagnosis, ' || 'i_code => d.code_icd,' || 'i_flg_other => d.flg_other,' || 'i_flg_std_diag => ''Y'', ' || 'i_epis_diag => e.id_epis_diagnosis) DIAG ' || --
         'FROM EPIS_DIAGNOSIS E, PROFESSIONAL P, DIAGNOSIS D, PROFESSIONAL P1, SPECIALITY S1, SPECIALITY S2 ' || --
         'WHERE P.ID_PROFESSIONAL = E.ID_PROFESSIONAL_DIAG' || --
         ' AND D.ID_DIAGNOSIS = E.ID_DIAGNOSIS ' || --
         ' AND E.ID_EPIS_DIAGNOSIS = ' || i_epis_diag || --
         ' AND P1.ID_PROFESSIONAL(+) = E.ID_PROFESSIONAL_CANCEL' || --
         ' AND S1.ID_SPECIALITY(+) = P.ID_SPECIALITY' || --
         ' AND S2.ID_SPECIALITY(+) = P1.ID_SPECIALITY';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_DIAG_DET',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END;
    --
    --
    FUNCTION cancel_epis_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_prof           IN profissional,
        i_notes_cancel   IN epis_diagnosis.notes_cancel%TYPE,
        i_prof_cat_type  IN category.flg_type%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Cancelar diagnóstico do episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                 I_EPIS_DIAGNOSIS - ID do registo a cancelar 
                 I_PROF - ID do profissional responsável 
                 I_NOTES_CANCEL - notas de cancelamento 
                 I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                       como é retornada em PK_LOGIN.GET_PROF_PREF 
                  Saida: O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/04 
          NOTAS: 
        *********************************************************************************/
        l_pat       visit.id_patient%TYPE;
        l_episode   epis_diagnosis.id_episode%TYPE;
        l_flg_show  VARCHAR2(1);
        l_msg_title VARCHAR2(2000);
        l_msg_text  VARCHAR2(2000);
        l_button    VARCHAR2(6);
    
        CURSOR c_diag IS
            SELECT ed.id_episode, e.id_patient
              FROM epis_diagnosis ed, episode e
             WHERE ed.id_epis_diagnosis = i_epis_diagnosis
               AND ed.flg_status = g_epis_diag_can
               AND e.id_episode = ed.id_episode;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_diag;
        FETCH c_diag
            INTO l_episode, l_pat;
        g_found := c_diag%FOUND;
        CLOSE c_diag;
        IF g_found
        THEN
            g_error := REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'), '@1', 'diagnóstico');
            raise_application_error('20001', g_error);
        END IF;
    
        g_error := 'UPDATE EPIS_DIAGNOSIS';
        UPDATE epis_diagnosis
           SET id_professional_cancel = i_prof.id,
               dt_cancel_tstz         = g_sysdate_tstz,
               notes_cancel           = i_notes_cancel,
               flg_status             = g_epis_diag_can
         WHERE id_epis_diagnosis = i_epis_diagnosis;
    
        g_error := 'CALL TO PK_PATIENT.SET_PAT_PROBLEM';
        IF NOT pk_patient.set_pat_problem(i_lang          => i_lang,
                                          i_epis          => l_episode,
                                          i_pat           => l_pat,
                                          i_pat_problem   => NULL,
                                          i_prof          => i_prof,
                                          i_diag          => NULL,
                                          i_desc          => NULL,
                                          i_notes         => i_notes_cancel,
                                          i_age           => NULL,
                                          i_dt_symptoms   => NULL,
                                          i_flg_approved  => g_aproved_clin,
                                          i_pct           => NULL,
                                          i_surgery       => NULL,
                                          i_notes_support => NULL,
                                          i_dt_confirm    => NULL,
                                          i_rank          => NULL,
                                          i_status        => g_pat_prob_cancel,
                                          i_epis_diag     => i_epis_diagnosis,
                                          i_prof_cat_type => i_prof_cat_type,
                                          o_flg_show      => l_flg_show,
                                          o_msg_title     => l_msg_title,
                                          o_msg_text      => l_msg_text,
                                          o_button        => l_button,
                                          o_error         => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        COMMIT;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'CANCEL_EPIS_DIAGNOSIS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION check_epis_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN epis_diagnosis.id_episode%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN epis_diagnosis.id_diagnosis%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Verifica se o diagnóstico já tinha sido atribuído ao doente noutro 
                  episódio. 
                  Se já tinha sido, avisa o utilizador 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                 I_ID_EPISODE - ID de episódio 
                 I_PROF - profissional (utilizador) 
                 I_DIAGNOSIS - diagnóstico 
                  Saida: O_FLG_SHOW - indica se deve ser mostrada uma msg (Y / N) 
                 O_MSG_TITLE - Título da msg a mostrar ao utilizador, caso 
                 O_FLG_SHOW = Y 
                 O_MSG - Texto da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y 
                 O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado 
                    Tb pode mostrar combinações destes, qd é p/ mostrar 
                  + do q 1 botão 
                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/04/18 
          NOTAS: 
        *********************************************************************************/
        l_char VARCHAR2(1);
    
        CURSOR c_diag IS
            SELECT 'X'
              FROM epis_diagnosis ed, episode e
             WHERE ed.id_diagnosis = i_diagnosis
               AND ed.dt_cancel_tstz IS NULL
               AND ed.id_episode != i_episode
               AND ed.id_episode = e.id_episode
               AND e.id_patient = (SELECT e1.id_patient
                                     FROM episode e1
                                    WHERE e1.id_episode = i_episode);
    
    BEGIN
        o_flg_show := 'N';
    
        g_error := 'OPEN CURSOR C_DIAG';
        OPEN c_diag;
        FETCH c_diag
            INTO l_char;
        g_found := c_diag%FOUND; -- Este diagnóstico já foi atribuído a este doente 
        CLOSE c_diag;
    
        IF g_found
        THEN
            o_flg_show  := 'Y';
            o_msg_text  := pk_message.get_message(i_lang, 'CLINICAL_INFO_M005');
            o_msg_title := pk_message.get_message(i_lang, 'CLINICAL_INFO_T001');
            o_button    := 'R';
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'CHECK_EPIS_DIAG',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_epis_vs_read
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN vital_sign_read.id_episode%TYPE,
        i_prof    IN profissional,
        o_vs      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter todos os SVs activos registados num episódio. 
                  Se há + do q 1 leitura do mesmo SV, retorna o + recente. 
                Retorna tb os nomes e IDs dos SVs q ñ têm leitura neste episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_EPISODE - ID do episódio 
                  Saida: O_VS - SVs 
                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/22 
          NOTAS: FLG_SHOW: Y - Tem valor a mostrar no campo 
                 N - Não tem valor, mas activa o botão de detalhe (só tem leituras canceladas) 
                   X - Não tem valor, e ñ activa o botão de detalhe 
        *********************************************************************************/
        l_id_bp_d  sys_config.value%TYPE;
        l_id_bp_s  sys_config.value%TYPE;
        l_id_bp    NUMBER;
        l_val_bp_d VARCHAR2(20);
        l_val_bp_s VARCHAR2(20);
        l_dt       VARCHAR2(20);
        l_short_dt VARCHAR2(20);
    
        CURSOR c_bp_parent IS
            SELECT id_vital_sign_parent
              FROM vital_sign_relation
             WHERE relation_domain = pk_alert_constant.g_vs_rel_conc;
    
        CURSOR c_bp IS
            SELECT vs_ea.value,
                   vs_ea.id_vital_sign,
                   pk_date_utils.date_char_tsz(i_lang, vs_ea.dt_vital_sign_read, i_prof.institution, i_prof.software) dt_vital_sign_read,
                   pk_date_utils.to_char_insttimezone(i_prof, vs_ea.dt_vital_sign_read, 'YYYYMMDDHH24MI') dt_vs_read
              FROM vital_sign vs, vital_signs_ea vs_ea
             WHERE vs_ea.id_episode = i_episode
               AND vs_ea.id_vital_sign IN
                   (SELECT id_vital_sign_detail
                      FROM vital_sign_relation
                     WHERE relation_domain = pk_alert_constant.g_vs_rel_conc)
               AND vs.id_vital_sign = vs_ea.id_vital_sign
               AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
             ORDER BY vs.intern_name_vital_sign;
    
    BEGIN
        g_error := 'OPEN C_BP';
        FOR wrec_bp IN c_bp
        LOOP
            IF nvl(l_val_bp_d, -1) = -1
            THEN
                l_val_bp_d := to_char(wrec_bp.value);
                l_id_bp_d  := wrec_bp.id_vital_sign;
            ELSE
                l_val_bp_s := to_char(wrec_bp.value);
                l_id_bp_s  := wrec_bp.id_vital_sign;
            END IF;
            l_dt       := wrec_bp.dt_vital_sign_read;
            l_short_dt := wrec_bp.dt_vs_read;
        END LOOP;
    
        g_error := 'OPEN C_BP_PARENT';
        OPEN c_bp_parent;
        FETCH c_bp_parent
            INTO l_id_bp;
        CLOSE c_bp_parent;
    
        g_error := 'GET CURSOR';
        OPEN o_vs FOR
            SELECT vs_ea.id_vital_sign_read,
                   vs_ea.id_vital_sign,
                   vs_ea.id_vital_sign_desc,
                   'Y' flg_show, -- tem valor 
                   decode(nvl(vs_ea.value, -999),
                          -999,
                          --pk_translation.get_translation(i_lang, vsd.code_vital_sign_desc),
                          pk_vital_sign.get_vs_alias(i_lang, vs_ea.id_patient, vsd.code_vital_sign_desc),
                          to_char(vs_ea.value) ||
                          pk_unit_measure.get_unit_measure_description(i_lang, i_prof, vs_ea.id_unit_measure)) VALUE,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                   pk_date_utils.date_char_tsz(i_lang, vs_ea.dt_vital_sign_read, i_prof.institution, i_prof.software) dt_read,
                   pk_date_utils.to_char_insttimezone(i_prof, vs_ea.dt_vital_sign_read, 'YYYYMMDDHH24MI') short_dt_read,
                   p.id_professional id_prof_read,
                   --p.nick_name prof_read,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_read,
                   
                   --p1.nick_name prof_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional) prof_cancel,
                   
                   vs_ea.notes_cancel,
                   pk_sysdomain.get_domain('VITAL_SIGN_READ.FLG_STATE', vs_ea.flg_state, i_lang) desc_status,
                   pk_date_utils.date_char_tsz(i_lang, vs_ea.dt_cancel, i_prof.institution, i_prof.software) dt_cancel,
                   vs.rank,
                   pk_tools.get_desc_institution(i_lang, vs_ea.id_institution_read, g_abbreviation) instit,
                   --pk_translation.get_translation(i_lang, s1.code_speciality) desc_speciality,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    vs_ea.id_prof_read,
                                                    vs_ea.dt_vital_sign_read,
                                                    vs_ea.id_episode) desc_speciality,
                   --pk_translation.get_translation(i_lang, s2.code_speciality) desc_speciality_cancel
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    vs_ea.id_prof_cancel,
                                                    vs_ea.dt_cancel,
                                                    vs_ea.id_episode) desc_speciality_cancel
              FROM vital_signs_ea  vs_ea,
                   vital_sign      vs,
                   vital_sign_desc vsd,
                   vs_clin_serv    vcs,
                   professional    p,
                   professional    p1,
                   speciality      s1,
                   speciality      s2
             WHERE vsd.id_vital_sign_desc(+) = vs_ea.id_vital_sign_desc
               AND vs.id_vital_sign = vs_ea.id_vital_sign
               AND vs_ea.id_episode = i_episode
               AND vs_ea.flg_state = pk_alert_constant.g_active
               AND p.id_professional(+) = vs_ea.id_prof_read
               AND p1.id_professional(+) = vs_ea.id_prof_cancel
               AND s1.id_speciality(+) = p.id_speciality
               AND s2.id_speciality(+) = p1.id_speciality
               AND vs.flg_available = pk_alert_constant.g_yes
               AND vs.flg_show = pk_alert_constant.g_yes
               AND vcs.id_vital_sign = vs.id_vital_sign ------------  
               AND vcs.id_software = i_prof.software ----------       
               AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
            UNION -- SVs que só têm leituras canceladas 
            SELECT NULL id_vital_sign_read,
                   vs_ea.id_vital_sign,
                   NULL id_vital_sign_desc,
                   'N' flg_show, -- Não tem valor, mas activa o botão de detalhe 
                   NULL VALUE,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                   NULL dt_read,
                   NULL short_dt_read,
                   NULL id_prof_read,
                   NULL prof_read,
                   NULL prof_cancel,
                   NULL notes_cancel,
                   NULL desc_status,
                   NULL dt_cancel,
                   vs.rank,
                   NULL instit,
                   NULL desc_speciality,
                   NULL desc_speciality_cancel
              FROM vital_signs_ea vs_ea, vital_sign vs, vs_clin_serv vcs
             WHERE vs_ea.id_episode = i_episode
               AND vs_ea.flg_state = pk_alert_constant.g_cancelled
               AND vs.id_vital_sign = vs_ea.id_vital_sign
               AND vs.flg_available = pk_alert_constant.g_yes
               AND vs.flg_show = pk_alert_constant.g_yes
               AND vcs.id_vital_sign = vs.id_vital_sign ----------             
               AND vcs.id_software = i_prof.software ----------       
               AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
            UNION -- formatação da pressão arterial 
            SELECT vs_ea.id_vital_sign_read,
                   l_id_bp id_vital_sign,
                   vs_ea.id_vital_sign_desc,
                   'Y' flg_show, -- tem valor 
                   l_val_bp_s || '/' || l_val_bp_d ||
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, vs_ea.id_unit_measure) VALUE,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                   l_dt dt_read,
                   l_short_dt short_dt_read,
                   p.id_professional id_prof_read,
                   --p.nick_name prof_read,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_read,
                   
                   --p1.nick_name prof_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional) prof_cancel,
                   
                   vs_ea.notes_cancel,
                   pk_sysdomain.get_domain('VITAL_SIGN_READ.FLG_STATE', vs_ea.flg_state, i_lang) desc_status,
                   pk_date_utils.date_char_tsz(i_lang, vs_ea.dt_cancel, i_prof.institution, i_prof.software) dt_cancel,
                   vs.rank,
                   pk_tools.get_desc_institution(i_lang, vs_ea.id_institution_read, g_abbreviation) instit,
                   --pk_translation.get_translation(i_lang, s1.code_speciality) desc_speciality,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    vs_ea.id_prof_read,
                                                    vs_ea.dt_vital_sign_read,
                                                    vs_ea.id_episode) desc_speciality,
                   --pk_translation.get_translation(i_lang, s2.code_speciality) desc_speciality_cancel
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    vs_ea.id_prof_cancel,
                                                    vs_ea.dt_cancel,
                                                    vs_ea.id_episode) desc_speciality_cancel
              FROM vital_signs_ea  vs_ea,
                   vital_sign      vs,
                   vital_sign_desc vsd,
                   professional    p,
                   professional    p1,
                   speciality      s1,
                   speciality      s2
             WHERE vsd.id_vital_sign_desc(+) = vs_ea.id_vital_sign_desc
               AND vs.id_vital_sign = vs_ea.id_vital_sign
               AND vs_ea.id_episode = i_episode
               AND vs_ea.flg_state = pk_alert_constant.g_active
               AND p.id_professional(+) = vs_ea.id_prof_read
               AND p1.id_professional(+) = vs_ea.id_prof_cancel
               AND s1.id_speciality(+) = p.id_speciality
               AND s2.id_speciality(+) = p1.id_speciality
               AND vs.id_vital_sign = l_id_bp_d
               AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
            UNION -- SVs sem leitura (excluindo o total de Glasgow e a pressão arterial) 
            SELECT NULL id_vital_sign_read,
                   vs.id_vital_sign,
                   NULL id_vital_sign_desc,
                   'X' flg_show, -- Não tem valor, e ñ activa o botão de detalhe 
                   NULL VALUE,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                   NULL dt_read,
                   NULL short_dt_read,
                   NULL id_prof_read,
                   NULL prof_read,
                   NULL prof_cancel,
                   NULL notes_cancel,
                   NULL desc_status,
                   NULL dt_cancel,
                   vs.rank,
                   NULL instit,
                   NULL desc_speciality,
                   NULL desc_speciality_cancel
              FROM vital_sign vs, vs_clin_serv vcs
             WHERE NOT EXISTS
             (SELECT 1
                      FROM vital_sign_read vsr
                     WHERE vsr.id_vital_sign = vs.id_vital_sign
                       AND vsr.id_episode = i_episode
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0)
               AND ((vs.id_vital_sign != l_id_bp) OR (vs.id_vital_sign = l_id_bp AND nvl(l_val_bp_s, -999) = -999))
               AND vs.flg_available = pk_alert_constant.g_yes
               AND vs.flg_show = pk_alert_constant.g_yes
               AND vcs.id_vital_sign = vs.id_vital_sign ----------             
               AND vcs.id_software = i_prof.software ----------       
               AND vs.id_vital_sign NOT IN
                   (SELECT vr.id_vital_sign_parent
                      FROM vital_sign_relation vr
                     WHERE vr.relation_domain = pk_alert_constant.g_vs_rel_sum)
            UNION -- total de Glasgow 
            SELECT DISTINCT NULL id_vital_sign_read,
                            vs.id_vital_sign,
                            NULL id_vital_sign_desc,
                            'X' flg_show, -- Não tem valor e ñ activa o botão de detalhe 
                            to_char(aux.val) VALUE,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            NULL dt_read,
                            NULL short_dt_read,
                            NULL id_prof_read,
                            NULL prof_read,
                            NULL prof_cancel,
                            NULL notes_cancel,
                            NULL desc_status,
                            NULL dt_cancel,
                            vs.rank,
                            NULL instit,
                            NULL desc_speciality,
                            NULL desc_speciality_cancel
              FROM vital_sign vs,
                   vital_sign_relation vr_par,
                   vs_clin_serv vcs,
                   (SELECT SUM(vsd.value) val, vr.id_vital_sign_parent
                      FROM vital_sign_desc vsd, vital_sign_relation vr, vital_signs_ea vs_ea
                     WHERE vs_ea.id_episode = i_episode
                       AND vs_ea.flg_state = pk_alert_constant.g_active
                       AND vr.id_vital_sign_detail = vs_ea.id_vital_sign
                       AND vr.relation_domain = pk_alert_constant.g_vs_rel_sum
                       AND vsd.id_vital_sign_desc = vs_ea.id_vital_sign_desc
                       AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
                     GROUP BY vr.id_vital_sign_parent) aux
             WHERE vr_par.id_vital_sign_parent = vs.id_vital_sign
               AND vr_par.relation_domain = pk_alert_constant.g_vs_rel_sum
               AND aux.id_vital_sign_parent(+) = vs.id_vital_sign
               AND vcs.id_vital_sign = vs.id_vital_sign ----------             
               AND vcs.id_software = i_prof.software ----------        
             ORDER BY rank, name_vs;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_VS_READ',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_vs);
            RETURN FALSE;
    END;

    FUNCTION get_epis_vs_read_group
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN vital_sign_read.id_episode%TYPE,
        i_prof    IN profissional,
        o_vs      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter leituras de SVs agrupadas por data de leitura 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_EPISODE - ID do episódio 
                  Saida:   O_VS - SVs 
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/04/19 
          NOTAS: 
        *********************************************************************************/
        l_dt    VARCHAR2(30);
        l_prof  VARCHAR2(200);
        i       NUMBER;
        l_first BOOLEAN := TRUE;
        l_aux   VARCHAR2(4000);
    
        TYPE vtl_sign IS RECORD(
            val            VARCHAR2(2000),
            dt_char        VARCHAR2(30),
            prof           professional.nick_name%TYPE,
            clin_serv      VARCHAR2(200),
            code_epis_type VARCHAR2(200),
            dt             VARCHAR2(200));
        TYPE vs IS TABLE OF vtl_sign INDEX BY BINARY_INTEGER;
        vsign vs;
    
        CURSOR c_vs IS
            SELECT vsr.id_vital_sign_read,
                   vsr.id_vital_sign,
                   vsr.id_vital_sign_desc,
                   pk_date_utils.to_char_insttimezone(i_prof, vsr.dt_vital_sign_read_tstz, 'YYYYMMDD HH24:MI') dt_vital_sign_read,
                   decode(vsr.value,
                          '',
                          --pk_translation.get_translation(i_lang, vsd.code_vital_sign_desc),
                          pk_vital_sign.get_vs_alias(i_lang, vsr.id_patient, vsd.code_vital_sign_desc),
                          vsr.value || pk_unit_measure.get_unit_measure_description(i_lang, i_prof, vsr.id_unit_measure)) VALUE,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                   pk_date_utils.date_char_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof.institution, i_prof.software) dt_read,
                   --pk_tools.get_prof_nick_name(i_lang, vsr.id_prof_read) prof_read,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, vsr.id_prof_read) prof_read,
                   
                   pk_translation.get_translation(i_lang, ete.code_epis_type) eps_type,
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || e.id_clinical_service) clin_serv
            
              FROM vital_sign_read vsr, vital_sign vs, vital_sign_desc vsd, episode e, epis_type ete
             WHERE vsd.id_vital_sign_desc(+) = vsr.id_vital_sign_desc
               AND vs.id_vital_sign = vsr.id_vital_sign
               AND vsr.id_episode = i_episode
               AND vs.flg_available = pk_alert_constant.g_yes
               AND e.id_episode = vsr.id_episode
               AND ete.id_epis_type = e.id_epis_type
               AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
             ORDER BY vsr.dt_vital_sign_read_tstz;
    
    BEGIN
        i       := 1;
        g_error := 'LOOP';
        FOR r_vs IN c_vs
        LOOP
            IF nvl(l_dt, r_vs.dt_read) != r_vs.dt_read
               OR nvl(l_prof, r_vs.prof_read) != r_vs.prof_read
            THEN
                i       := i + 1;
                l_first := TRUE;
            END IF;
        
            g_error := 'SET VECTOR';
            vsign(i).prof := r_vs.prof_read;
            vsign(i).dt_char := r_vs.dt_read;
            vsign(i).clin_serv := r_vs.clin_serv;
            vsign(i).code_epis_type := r_vs.eps_type;
            vsign(i).dt := r_vs.dt_vital_sign_read;
        
            g_error := 'SET VECTOR VAL';
            IF l_first
            THEN
                vsign(i).val := r_vs.name_vs || ' ' || r_vs.value;
                l_first := FALSE;
            ELSE
                vsign(i).val := vsign(i).val || '; ' || r_vs.name_vs || ' ' || r_vs.value;
            END IF;
        
            l_dt   := r_vs.dt_read;
            l_prof := r_vs.prof_read;
        END LOOP;
    
        l_first := TRUE;
        g_error := 'LOOP VECTOR';
        FOR j IN 1 .. vsign.count
        LOOP
            IF NOT l_first
            THEN
                l_aux := l_aux || ' UNION ';
            ELSE
                l_first := FALSE;
            END IF;
        
            l_aux := l_aux || 'SELECT ''' || vsign(j).val || ''' VALUE, ' || '''' || vsign(j).prof || ''' PROF, ' || '''' || vsign(j)
                    .clin_serv || ''' CLIN_SERV, ' || '''' || vsign(j).code_epis_type || ''' EPIS_TYPE, ' || '''' || vsign(j)
                    .dt_char || ''' DT_CHAR,' || '''' || vsign(j).dt || ''' DT ' || ' FROM DUAL';
        END LOOP;
        l_aux := l_aux || ' ORDER BY DT DESC';
    
        OPEN o_vs FOR l_aux;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_VS_READ_GROUP',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_vs);
            RETURN FALSE;
    END;

    FUNCTION get_all_vs_read
    (
        i_lang    IN language.id_language%TYPE,
        i_pat     IN vital_sign_read.id_patient%TYPE,
        i_episode IN vital_sign_read.id_episode%TYPE,
        i_vs      IN vital_sign_read.id_vital_sign%TYPE,
        i_prof    IN profissional,
        o_vs      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter todas as leituras de um SV, no episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_PAT - ID do doente 
                     I_EPISODE - ID do episódio 
                     I_VS - ID do SV pretendido 
                  Saida:   O_VS - SVs 
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/07/14 
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_vs FOR
            SELECT vsr.id_vital_sign_read,
                   vsr.id_vital_sign_desc,
                   --  PK_TRANSLATION.GET_TRANSLATION(I_LANG, VSD.CODE_VITAL_SIGN_DESC) NAME_VS_DESC,
                   pk_sysdomain.get_rank(i_lang, 'VITAL_SIGN_READ.FLG_STATE', vsr.flg_state) rank,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                   pk_date_utils.dt_chr_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    vsr.dt_vital_sign_read_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_target,
                   decode(nvl(vsr.value, -999),
                          -999,
                          --pk_translation.get_translation(i_lang, vsd.code_vital_sign_desc),
                          pk_vital_sign.get_vs_alias(i_lang, vsr.id_patient, vsd.code_vital_sign_desc),
                          to_char(vsr.value) ||
                          pk_unit_measure.get_unit_measure_description(i_lang, i_prof, vsr.id_unit_measure)) VALUE,
                   --               TO_CHAR(VSR.VALUE)||PK_TRANSLATION.GET_TRANSLATION(I_LANG, VS.CODE_MEASURE_UNIT) VALUE,
                   pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_vital_sign_read,
                   --pk_tools.get_prof_nick_name(i_lang, vsr.id_prof_read) prof_read,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, vsr.id_prof_read) prof_read,
                   
                   vsr.id_prof_read id_professional,
                   vsr.flg_state,
                   pk_sysdomain.get_domain('VITAL_SIGN_READ.FLG_STATE', vsr.flg_state, i_lang) desc_status,
                   pk_date_utils.dt_chr_tsz(i_lang, vsr.dt_cancel_tstz, i_prof) date_cancel,
                   pk_date_utils.date_char_hour_tsz(i_lang, vsr.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_cancel,
                   decode(vsr.flg_state, pk_alert_constant.g_cancelled, 'Y', 'N') flg_cancel,
                   pk_date_utils.to_char_insttimezone(i_prof, vsr.dt_vital_sign_read_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   pk_date_utils.to_char_insttimezone(i_prof, vsr.dt_cancel_tstz, 'YYYYMMDDHH24MISS') dt_ord2,
                   decode(vsr.flg_state,
                          pk_alert_constant.g_cancelled,
                          'N',
                          decode(i_prof.id, vsr.id_prof_read, 'Y', 'N')) avail_butt_canc
              FROM vital_sign_read vsr, vital_sign vs, vital_sign_desc vsd
             WHERE vsr.id_episode = i_episode
               AND vsr.id_patient = i_pat
               AND vsr.id_vital_sign = i_vs
               AND vs.id_vital_sign = vsr.id_vital_sign
               AND vsd.id_vital_sign_desc(+) = vsr.id_vital_sign_desc
               AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
            UNION
            SELECT vsr.id_vital_sign_read,
                   vsr.id_vital_sign_desc, --'' NAME_VS_DESC, 
                   pk_sysdomain.get_rank(i_lang, 'VITAL_SIGN_READ.FLG_STATE', vsr.flg_state) rank,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                   pk_date_utils.dt_chr_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    vsr.dt_vital_sign_read_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_target,
                   vsr.value || '/' || aux.value VALUE,
                   pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_vital_sign_read,
                   --pk_tools.get_prof_nick_name(i_lang, vsr.id_prof_read) prof_read,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, vsr.id_prof_read) prof_read,
                   
                   vsr.id_prof_read id_professional,
                   vsr.flg_state,
                   pk_sysdomain.get_domain('VITAL_SIGN_READ.FLG_STATE', vsr.flg_state, i_lang) desc_status,
                   pk_date_utils.dt_chr_tsz(i_lang, vsr.dt_cancel_tstz, i_prof) date_cancel,
                   pk_date_utils.date_char_hour_tsz(i_lang, vsr.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_cancel,
                   decode(vsr.flg_state, pk_alert_constant.g_cancelled, 'Y', 'N') flg_cancel,
                   pk_date_utils.to_char_insttimezone(i_prof, vsr.dt_vital_sign_read_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   pk_date_utils.to_char_insttimezone(i_prof, vsr.dt_cancel_tstz, 'YYYYMMDDHH24MISS') dt_ord2,
                   decode(vsr.flg_state,
                          pk_alert_constant.g_cancelled,
                          'N',
                          decode(i_prof.id, vsr.id_prof_read, 'Y', 'N')) avail_butt_canc
              FROM vital_sign_read vsr,
                   vital_sign vs,
                   vital_sign_relation vrl,
                   (SELECT vsr1.value,
                           vsr1.dt_vital_sign_read_tstz dt_tstz,
                           vsr1.id_vital_sign,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       vsr1.dt_vital_sign_read_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_vital_sign_read
                      FROM vital_sign_read vsr1, vital_sign_relation vr_conc
                     WHERE vsr1.id_episode = i_episode
                       AND vsr1.id_patient = i_pat
                       AND vr_conc.id_vital_sign_parent = i_vs
                       AND vsr1.id_vital_sign = vr_conc.id_vital_sign_detail
                       AND vr_conc.relation_domain = 'C'
                       AND vr_conc.rank = (SELECT MAX(vsr2.rank)
                                             FROM vital_sign_relation vsr2
                                            WHERE vsr2.relation_domain = 'C')
                       AND pk_delivery.check_vs_read_from_fetus(vsr1.id_vital_sign_read) = 0) aux
             WHERE vsr.id_episode = i_episode
               AND vsr.id_patient = i_pat
               AND aux.id_vital_sign != vsr.id_vital_sign
               AND aux.dt_tstz = vsr.dt_vital_sign_read_tstz
               AND vsr.id_vital_sign = vrl.id_vital_sign_detail
               AND vrl.id_vital_sign_parent = i_vs
               AND vrl.relation_domain != pk_alert_constant.g_vs_rel_percentile
               AND vrl.rank = (SELECT MIN(vsr3.rank)
                                 FROM vital_sign_relation vsr3
                                WHERE vsr3.relation_domain = 'C')
               AND vs.id_vital_sign = vsr.id_vital_sign
               AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
             ORDER BY rank, dt_vital_sign_read DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_ALL_VS_READ',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_vs);
            RETURN FALSE;
    END;

    FUNCTION get_epis_read
    (
        i_lang    IN language.id_language%TYPE,
        i_pat     IN vital_sign_read.id_patient%TYPE,
        i_episode IN vital_sign_read.id_episode%TYPE,
        i_vs      IN vital_sign_read.id_vital_sign%TYPE,
        i_prof    IN profissional,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter todas as leituras de peso ou altura ou p.cefálico, no episódio 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_PAT - ID do doente 
                     I_EPISODE - ID do episódio 
                     I_VS - ID do campo pretendido 
                  Saida:   O_INFO - leituras 
                     O_ERROR - erro 
          
          CRIAÇÃO: SS 2005/11/22 
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_info FOR
            SELECT vsr.id_vital_sign_read,
                   vsr.id_vital_sign_desc,
                   pk_sysdomain.get_rank(i_lang, 'VITAL_SIGN_READ.FLG_STATE', vsr.flg_state) rank,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                   pk_date_utils.dt_chr_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    vsr.dt_vital_sign_read_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_target,
                   pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_vital_sign_read,
                   decode(vsr.flg_state,
                          pk_alert_constant.g_cancelled,
                          to_char(vsr.value) ||
                          pk_unit_measure.get_unit_measure_description(i_lang, i_prof, vsr.id_unit_measure) || ' ' ||
                          pk_message.get_message(i_lang, 'COMMON_M028'),
                          to_char(vsr.value) || ' ' ||
                          pk_unit_measure.get_unit_measure_description(i_lang, i_prof, vsr.id_unit_measure)) VALUE,
                   --TO_CHAR(VSR.VALUE)||Pk_Translation.GET_TRANSLATION(I_LANG, VS.CODE_MEASURE_UNIT) VALUE, 
                   --pk_tools.get_prof_nick_name(i_lang, vsr.id_prof_read) prof_read,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, vsr.id_prof_read) prof_read,
                   
                   vsr.id_prof_read id_professional,
                   vsr.flg_state,
                   pk_sysdomain.get_domain('VITAL_SIGN_READ.FLG_STATE', vsr.flg_state, i_lang) desc_status,
                   pk_date_utils.dt_chr_tsz(i_lang, vsr.dt_cancel_tstz, i_prof) date_cancel,
                   pk_date_utils.date_char_hour_tsz(i_lang, vsr.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_cancel,
                   decode(vsr.flg_state, pk_alert_constant.g_cancelled, 'Y', 'N') flg_cancel,
                   pk_date_utils.to_char_insttimezone(i_prof, vsr.dt_vital_sign_read_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   pk_date_utils.to_char_insttimezone(i_prof, vsr.dt_cancel_tstz, 'YYYYMMDDHH24MISS') dt_ord2,
                   decode(vsr.flg_state,
                          pk_alert_constant.g_cancelled,
                          'N',
                          decode(i_prof.id, vsr.id_prof_read, 'Y', 'N')) avail_butt_canc
              FROM vital_sign_read vsr, vital_sign vs, vital_sign_desc vsd
             WHERE vsr.id_patient = i_pat
               AND vsr.id_vital_sign = i_vs
               AND vs.id_vital_sign = vsr.id_vital_sign
               AND vsd.id_vital_sign_desc(+) = vsr.id_vital_sign_desc
               AND vs.flg_vs = pk_alert_constant.g_vs_flg_bio
               AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
             ORDER BY rank, dt_vital_sign_read DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_READ',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END;

    FUNCTION get_diag_anamnesis
    (
        i_lang    IN language.id_language%TYPE,
        i_pat     IN patient.id_patient%TYPE,
        i_episode IN epis_anamnesis.id_episode%TYPE,
        o_text    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Obter queixas / histórias do episódio que tenham por base a selecção 
                de um texto mais frequente transcrito de um standard 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_PAT - ID do doente 
                 I_EPISODE - ID do episódio 
                  Saida: O_TEXT - leituras 
                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2006/05/30 
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_text FOR
            SELECT id_epis_anamnesis,
                   pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_epis_anamnesis,
                   pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) title
              FROM epis_anamnesis ea
             WHERE id_episode = i_episode
               AND ea.id_diagnosis IS NOT NULL
               AND ea.flg_type = g_complaint
             ORDER BY pk_string_utils.clob_to_sqlvarchar2(desc_epis_anamnesis);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_DIAG_ANAMNESIS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_text);
            RETURN FALSE;
    END;

    FUNCTION get_anamnesis_code
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_anamnesis.id_episode%TYPE,
        i_prof    IN profissional,
        o_code    OUT VARCHAR2,
        o_id_diag OUT epis_anamnesis.id_diagnosis%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Obter info relativa à última queixa do episódio que tenha por base a selecção 
                de um texto mais frequente transcrito de um standard 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                 I_EPISODE - ID do episódio 
                   I_PROF - ID do profissional 
                  Saida: O_CODE - Código do standard associado à última queixa 
                                registada pelo user  
                                 O_ID_DIAG - ID do diagnóstico do standard associado à 
                                    última queixa registada pelo user  
                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2006/05/31 
          NOTAS: 
        *********************************************************************************/
        CURSOR c_anam IS
            SELECT e.id_diagnosis, d.code_icd
              FROM epis_anamnesis e, diagnosis d
             WHERE e.id_episode = i_episode
               AND e.id_professional = i_prof.id
               AND d.id_diagnosis = e.id_diagnosis
             ORDER BY e.dt_epis_anamnesis_tstz DESC;
    BEGIN
        g_error := 'GET C_ANAM';
        OPEN c_anam;
        FETCH c_anam
            INTO o_id_diag, o_code;
        CLOSE c_anam;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_ANAMNESIS_CODE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Retorna informação relativa ao último registo de revisão de sistemas neste episódio, em texto livre
    *
    * @param i_lang                   id da lingua 
    * @param i_episode                id do episódio
    * @param i_prof                   objecto do profissional
    * @param o_last_update            cursor con informação  
    * @param o_error                  mensagem de erro
    *
    * @return                         true successo, false erro
    *  
    * @author                         João Eiras
    * @version                        1.0
    * @since                          2007/09/20 
    ********************************************************************************************/
    FUNCTION get_epis_rvsystems_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_REVIEW_SYS';
        OPEN o_last_update FOR
            SELECT *
              FROM (SELECT pk_date_utils.date_send_tsz(i_lang, ers.dt_creation_tstz, i_prof) dt_creation,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, ers.id_professional) nick_name,
                           
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            ers.id_professional,
                                                            ers.dt_creation_tstz,
                                                            ers.id_episode) desc_speciality,
                           pk_date_utils.date_chr_short_read_tsz(i_lang, ers.dt_creation_tstz, i_prof) date_target,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            ers.dt_creation_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) hour_target,
                           pk_date_utils.date_char_tsz(i_lang, ers.dt_creation_tstz, i_prof.institution, i_prof.software) date_hour_target
                      FROM epis_review_systems ers
                     WHERE ers.id_episode = i_episode
                     ORDER BY ers.dt_creation_tstz DESC)
             WHERE rownum < 2;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_RVSYSTEMS_LAST_UPDATE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_last_update);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Listar as revisões de sistemas do episódio
    *
    * @param i_lang                 id da lingua
    * @param i_prof                 objecto com info do utilizador
    * @param i_epis                 episode id 
    * @param o_review_sys           cursor with review of systems values
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       Emília Taborda
    * @version                      1.0
    * @since                        10-01-2007
    ********************************************************************************************/
    FUNCTION get_epis_review_systems
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_epis       IN episode.id_episode%TYPE,
        o_review_sys OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_rsystems epis_review_systems.id_epis_review_systems%TYPE;
    BEGIN
        BEGIN
            SELECT id_epis_review_systems
              INTO l_epis_rsystems
              FROM epis_review_systems
             WHERE id_episode = i_epis
               AND rownum = 1;
            -- 
            g_error := 'GET CURSOR O_REVIEW_SYS(1)';
            OPEN o_review_sys FOR
                SELECT ers.id_epis_review_systems,
                       --pk_tools.get_prof_nick_name(i_lang, ers.id_professional) name_prof,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ers.id_professional) name_prof,
                       
                       ers.desc_review_systems,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        ers.id_professional,
                                                        ers.dt_creation_tstz,
                                                        ers.id_episode) desc_spec,
                       pk_date_utils.dt_chr_tsz(i_lang, ers.dt_creation_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ers.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target
                  FROM epis_review_systems ers
                 WHERE ers.id_episode = i_epis
                 ORDER BY ers.dt_creation_tstz DESC;
            --                        
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'GET CURSOR O_REVIEW_SYS(2)';
                OPEN o_review_sys FOR
                    SELECT 'N' reg, pk_message.get_message(i_lang, 'COMMON_M007') desc_review_systems
                      FROM dual;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_REVIEW_SYSTEMS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_review_sys);
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Registar as revisões de sistemas associadas a um episódio 
    *
    * @param i_lang                 id da lingua
    * @param i_prof                 objecto com info do utilizador
    * @param i_epis                 episode id 
    * @param i_desc_rev_sys         Review of systems notes
    * @param i_prof_cat_type        categoty of professional
    * @param i_flg_type             Type of edition 
    * @param i_epis_rsystem         episode review system id
    * @param o_error                Error message
    *
    * @value i_flg_type             {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes                        
    * @return                       true or false on success or error
    * 
    * @author                       Emília Taborda
    * @version                      1.0
    * @since                        10-01-2007
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/05/08
    *                             Added new edit options: Update from previous assessment; No changes;
    ********************************************************************************************/
    FUNCTION set_epis_review_systems
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_desc_rev_sys  IN epis_review_systems.desc_review_systems%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_flg_type      IN VARCHAR2,
        i_epis_rsystem  IN epis_review_systems.id_epis_review_systems%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_char         VARCHAR2(1);
        l_desc_rev_sys epis_review_systems.desc_review_systems%TYPE;
        --
        CURSOR c_episode IS
            SELECT 'X'
              FROM episode
             WHERE id_episode = i_epis
               AND flg_status = g_epis_active;
    
        CURSOR c_prev_epis_rsystems IS
            SELECT desc_review_systems
              FROM epis_review_systems
             WHERE id_epis_review_systems = i_epis_rsystem;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        g_error := 'GET CURSOR C_EPISODE';
        OPEN c_episode;
        FETCH c_episode
            INTO l_char;
        g_found := c_episode%FOUND;
        CLOSE c_episode;
        --
        IF g_found
        THEN
            IF (i_epis_rsystem IS NOT NULL AND i_flg_type = g_flg_edition_type_edit)
            THEN
                g_error := 'UPDATE epis_review_systems -> i_flg_type_mode = E ';
                UPDATE epis_review_systems
                   SET flg_status = g_epis_outdated
                 WHERE id_epis_review_systems = i_epis_rsystem;
            END IF;
        
            IF (i_flg_type = g_flg_edition_type_nochanges)
            THEN
                --No changes edition. 
                --Copies the values from previous record and creates a new record using current professional
                IF (i_epis_rsystem IS NULL)
                THEN
                    -- Checking: flg_type = no changes, but previous record was not defined
                    g_error := 'NO CHANGES WITHOUT ID_EPIS_REVIEW_SYSTEMS PARAMETER';
                    RAISE g_exception;
                END IF;
            
                g_error := 'GET EPIS_REVIEW_SYSTEMS';
                OPEN c_prev_epis_rsystems;
                FETCH c_prev_epis_rsystems
                    INTO l_desc_rev_sys;
                CLOSE c_prev_epis_rsystems;
            ELSE
                --Editions of type New,Edit,Agree,Update. 
                --Creates a new record using the arguments passed to function
                l_desc_rev_sys := i_desc_rev_sys;
            END IF;
            --
            g_error := 'INSERT EPIS_REVIEW_SYSTEMS';
            INSERT INTO epis_review_systems
                (id_epis_review_systems,
                 desc_review_systems,
                 dt_creation_tstz,
                 id_professional,
                 id_episode,
                 flg_status,
                 adw_last_update,
                 id_epis_review_systems_parent,
                 flg_edition_type)
            VALUES
                (seq_epis_review_systems.nextval,
                 l_desc_rev_sys,
                 g_sysdate_tstz,
                 i_prof.id,
                 i_epis,
                 g_epis_active,
                 g_sysdate,
                 i_epis_rsystem,
                 i_flg_type);
        
        END IF;
        --
        COMMIT;
        --
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'SET_EPIS_REVIEW_SYSTEMS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Listar as observações de um dado episódio
    *
    * @param i_lang                 id da lingua
    * @param i_prof                 objecto com info do utilizador
    * @param i_episode              episode id 
    * @param i_flg_obs              Se a observação do episódio é: D - Definitiva; T - Temporária
    * @param o_phy_exam_text        cursor with observation values
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       Emília Taborda
    * @version                      1.0
    * @since                        30-01-2007
    ********************************************************************************************/
    FUNCTION get_physical_exam_text
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_obs       IN epis_observation.flg_temp%TYPE,
        o_phy_exam_text OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_temp epis_observation.flg_temp%TYPE;
        --
        --Visualizar que tipo de exame físico o episódio tem
        -- Se só apresentar registos temporários, será apenas apresentado o último exame físico 
        -- Se apresentar registos definitos, serão apresentadas todos os exames definitivos desse episódio
        CURSOR c_temp_observation IS
            SELECT DISTINCT flg_temp
              FROM epis_observation
             WHERE id_episode = i_episode
               AND flg_temp IN ('T', 'D')
             ORDER BY dt_epis_observation_tstz;
    BEGIN
        g_error := 'OPEN C_TEMP_OBSERVATION';
        OPEN c_temp_observation;
        FETCH c_temp_observation
            INTO l_flg_temp;
        CLOSE c_temp_observation;
        --
        IF l_flg_temp = g_flg_temp_d
        THEN
            g_error := 'OPEN C_EPIS_OBS_D ';
            OPEN o_phy_exam_text FOR
                SELECT pk_utils.concat_table(CAST(COLLECT(t.desc_observation) AS table_varchar), ';') desc_observation
                  FROM (SELECT desc_epis_observation desc_observation
                          FROM epis_observation
                         WHERE id_episode = i_episode
                           AND id_institution = i_prof.institution
                           AND flg_temp = l_flg_temp
                           AND id_software = i_prof.software
                         ORDER BY dt_epis_observation_tstz DESC) t;
        
        ELSIF l_flg_temp = g_flg_temp_t
        THEN
            g_error := 'OPEN C_EPIS_OBS_T ';
            OPEN o_phy_exam_text FOR
                SELECT *
                  FROM (SELECT desc_epis_observation desc_observation
                          FROM epis_observation eo
                         WHERE eo.id_episode = i_episode
                           AND eo.id_institution = i_prof.institution
                           AND eo.flg_temp = l_flg_temp
                           AND eo.id_software = i_prof.software
                         ORDER BY eo.dt_epis_observation_tstz DESC)
                 WHERE rownum < 2;
        ELSE
            pk_types.open_my_cursor(o_phy_exam_text);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_PHYSICAL_EXAM_TEXT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_phy_exam_text);
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Listar as revisões de sistema de um dado episódio
    *
    * @param i_lang                 id da lingua
    * @param i_prof                 objecto com info do utilizador
    * @param i_episode              episode id 
    * @param o_rev_sys_text         cursor with review of systems values
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       Emília Taborda
    * @version                      1.0
    * @since                        30-01-2007
    ********************************************************************************************/
    FUNCTION get_review_system_text
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_rev_sys_text OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_rev_sys_text FOR
            SELECT pk_utils.concat_table(CAST(COLLECT(ers.desc_review_systems) AS table_varchar), ', ') desc_element
              FROM epis_review_systems ers
             WHERE id_episode = i_episode
             ORDER BY dt_creation_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_REVIEW_SYSTEM_TEXT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_rev_sys_text);
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Checks if an episode has review of systems.
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       18-09-2007
    **********************************************************************************************/
    FUNCTION get_review_system_exists
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_flg_data OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_data_rev_system VARCHAR2(1);
        l_flg_data_rsy        VARCHAR2(1);
    BEGIN
        g_error := 'COUNT REGISTRIES epis_review_systems';
        SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_flg_data_rev_system
          FROM epis_review_systems
         WHERE id_episode = i_episode;
        --
        g_error := 'CALL pk_touch_option.get_doc_area_exists';
        IF NOT pk_touch_option.get_doc_area_exists(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_episode  => i_episode,
                                                   i_doc_area => g_doc_area_rev_sys,
                                                   o_flg_data => l_flg_data_rsy,
                                                   o_error    => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
        --        
        IF l_flg_data_rsy = pk_alert_constant.g_yes
           OR l_flg_data_rev_system = pk_alert_constant.g_yes
        THEN
            o_flg_data := pk_alert_constant.g_yes;
        ELSE
            o_flg_data := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_REVIEW_SYSTEM_EXISTS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Indica se o profissional actual registou uma revisão de sistemas no episódio pretendido
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_last_prof_episode   último episódio registado de revisão de sistemas
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       18-09-2007
    **********************************************************************************************/
    FUNCTION get_prof_rev_system_exists
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        o_last_prof_episode OUT episode.id_episode%TYPE,
        o_flg_data          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_data_free_text    VARCHAR2(1);
        l_flg_data_touch_option VARCHAR2(1);
        --
        l_last_epis_free_text    epis_anamnesis.id_epis_anamnesis%TYPE;
        l_last_date_free_text    epis_anamnesis.dt_epis_anamnesis_tstz%TYPE;
        l_last_epis_touch_option epis_documentation.id_epis_documentation%TYPE;
        l_last_date_touch_option epis_documentation.dt_creation_tstz%TYPE;
    BEGIN
        BEGIN
            g_error := 'Find Exists epis_review_systems';
            SELECT flg_exists, id_epis_review_systems, dt_creation_tstz
              INTO l_flg_data_free_text, l_last_epis_free_text, l_last_date_free_text
              FROM (SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_exists,
                           ers.id_epis_review_systems,
                           ers.dt_creation_tstz
                      FROM epis_review_systems ers
                     WHERE ers.id_episode = i_episode
                       AND ers.dt_creation_tstz = (SELECT MAX(ers1.dt_creation_tstz)
                                                     FROM epis_review_systems ers1
                                                    WHERE ers1.id_episode = i_episode)
                       AND ers.id_professional = i_prof.id
                     GROUP BY ers.id_epis_review_systems, ers.dt_creation_tstz) t
             WHERE rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        --
        g_error := 'CALL pk_touch_option.get_prof_doc_area_exists';
        IF NOT pk_touch_option.get_prof_doc_area_exists(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_episode            => i_episode,
                                                        i_doc_area           => g_doc_area_rev_sys,
                                                        o_last_prof_epis_doc => l_last_epis_touch_option,
                                                        o_date_last_epis     => l_last_date_touch_option,
                                                        o_flg_data           => l_flg_data_touch_option,
                                                        o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        IF l_last_date_free_text > l_last_date_touch_option
           OR l_last_date_touch_option IS NULL
        THEN
            o_last_prof_episode := l_last_epis_free_text;
        
        ELSIF l_last_date_touch_option > l_last_date_free_text
              OR l_last_date_free_text IS NULL
        THEN
            o_last_prof_episode := l_last_epis_touch_option;
        END IF;
        --
        IF l_flg_data_free_text = pk_alert_constant.g_yes
           OR l_flg_data_touch_option = pk_alert_constant.g_yes
        THEN
            o_flg_data := pk_alert_constant.g_yes;
        ELSE
            o_flg_data := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_PROF_REV_SYSTEM_EXISTS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Checks if an episode has physical exam
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param i_doc_area            area ID (physical exam, physical assessment)
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       18-09-2007
    **********************************************************************************************/
    FUNCTION get_physical_exam_exists
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        o_flg_data      OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_data_f_observ VARCHAR2(1);
        l_flg_data_t_observ VARCHAR2(1);
    
    BEGIN
        g_error := 'COUNT REGISTRIES epis_review_systems';
        SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_flg_data_f_observ
          FROM epis_observation eo
         WHERE eo.id_episode = i_episode
           AND eo.flg_type = decode(i_doc_area, g_doc_area_phy_exam, g_observ_flg_type_e, g_observ_flg_type_a);
    
        g_error := 'CALL pk_touch_option.get_doc_area_exists';
        IF NOT pk_touch_option.get_doc_area_exists(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_episode  => i_episode,
                                                   i_doc_area => i_doc_area,
                                                   o_flg_data => l_flg_data_t_observ,
                                                   o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --        
        IF l_flg_data_f_observ = pk_alert_constant.g_yes
           OR l_flg_data_t_observ = pk_alert_constant.g_yes
        THEN
            o_flg_data := pk_alert_constant.g_yes;
        ELSE
            o_flg_data := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_PHYSICAL_EXAM_EXISTS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Indica se o profissional actual registou um exame fisico no episódio pretendido
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_prof_cat_type       Categoria do profissional
    * @param i_episode             episode id
    * @param o_last_prof_episode   último episódio registado de exame físico
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       18-09-2007
    **********************************************************************************************/
    FUNCTION get_prof_physical_exam_exists
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        o_last_prof_episode OUT episode.id_episode%TYPE,
        o_flg_data          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_data_free_text    VARCHAR2(1);
        l_flg_data_touch_option VARCHAR2(1);
        --
        l_last_epis_free_text    epis_anamnesis.id_epis_anamnesis%TYPE;
        l_last_date_free_text    epis_anamnesis.dt_epis_anamnesis_tstz%TYPE;
        l_last_epis_touch_option epis_documentation.id_epis_documentation%TYPE;
        l_last_date_touch_option epis_documentation.dt_creation_tstz%TYPE;
        --
        l_doc_area_obs_exam doc_area.id_doc_area%TYPE;
    BEGIN
        BEGIN
            g_error := 'Find Exists epis_observation';
            SELECT flg_exists, id_epis_observation, dt_epis_observation_tstz
              INTO l_flg_data_free_text, l_last_epis_free_text, l_last_date_free_text
              FROM (SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_exists,
                           eo.id_epis_observation,
                           eo.dt_epis_observation_tstz
                      FROM epis_observation eo
                     WHERE eo.id_episode = i_episode
                       AND eo.flg_type = decode(i_prof_cat_type,
                                                g_cat_flg_type_d,
                                                g_observ_flg_type_e,
                                                g_cat_flg_type_u,
                                                g_observ_flg_type_e,
                                                g_observ_flg_type_a)
                       AND eo.dt_epis_observation_tstz =
                           (SELECT MAX(eo1.dt_epis_observation_tstz)
                              FROM epis_observation eo1
                             WHERE eo1.id_episode = i_episode
                               AND eo1.flg_type = decode(i_prof_cat_type,
                                                         g_cat_flg_type_d,
                                                         g_observ_flg_type_e,
                                                         g_cat_flg_type_u,
                                                         g_observ_flg_type_e,
                                                         g_observ_flg_type_a))
                       AND eo.id_professional = i_prof.id
                     GROUP BY eo.id_epis_observation, eo.dt_epis_observation_tstz) t
             WHERE rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        --        
        l_doc_area_obs_exam := g_doc_area_phy_exam;
        --
        g_error := 'CALL pk_touch_option.get_prof_doc_area_exists';
        IF NOT pk_touch_option.get_prof_doc_area_exists(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_episode            => i_episode,
                                                        i_doc_area           => l_doc_area_obs_exam,
                                                        o_last_prof_epis_doc => l_last_epis_touch_option,
                                                        o_date_last_epis     => l_last_date_touch_option,
                                                        o_flg_data           => l_flg_data_touch_option,
                                                        o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        IF l_last_date_free_text > l_last_date_touch_option
           OR l_last_date_touch_option IS NULL
        THEN
            o_last_prof_episode := l_last_epis_free_text;
        
        ELSIF l_last_date_touch_option > l_last_date_free_text
              OR l_last_date_free_text IS NULL
        THEN
            o_last_prof_episode := l_last_epis_touch_option;
        END IF;
        --
        IF l_flg_data_free_text = pk_alert_constant.g_yes
           OR l_flg_data_touch_option = pk_alert_constant.g_yes
        THEN
            o_flg_data := pk_alert_constant.g_yes;
        ELSE
            o_flg_data := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_PROF_PHYSICAL_EXAM_EXISTS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Toda a informação para um ID episódio de queixa / história
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_prof_cat_type       category of professional   
    * @param i_epis_anamnesis      episode anamnesis id
    * @param o_information         array with all information to episode anamnesis
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/09/24
    **********************************************************************************************/
    FUNCTION get_epis_anamnesis_free_text
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        o_information    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_INFORMATION';
        OPEN o_information FOR
            SELECT pk_date_utils.date_send_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof) dt_anamnesis,
                   ea.desc_epis_anamnesis,
                   ea.id_episode,
                   ea.id_professional,
                   --pk_tools.get_prof_nick_name(i_lang, ea.id_professional) name_prof,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) name_prof,
                   
                   ea.flg_type,
                   ea.flg_temp,
                   ea.id_institution,
                   ea.id_software,
                   ea.id_diagnosis,
                   ea.flg_class,
                   ea.id_patient,
                   ea.dt_epis_anamnesis_tstz,
                   ea.id_epis_anamnesis_parent,
                   ea.flg_status
              FROM epis_anamnesis ea
             WHERE ea.id_epis_anamnesis = i_epis_anamnesis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_ANAMNESIS_FREE_TEXT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_information);
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Toda a informação para um ID episódio de exame fisico
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_prof_cat_type       category of professional
    * @param i_epis_observation    episode observation id
    * @param o_information         array with all information to episode observation
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/09/24
    **********************************************************************************************/
    FUNCTION get_epis_observ_free_text
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_epis_observation IN epis_observation.id_epis_observation%TYPE,
        o_information      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_INFORMATION';
        OPEN o_information FOR
            SELECT pk_date_utils.date_send_tsz(i_lang, eo.dt_epis_observation_tstz, i_prof) dt_observation,
                   eo.desc_epis_observation,
                   eo.id_episode,
                   eo.id_professional,
                   --pk_tools.get_prof_nick_name(i_lang, eo.id_professional) name_prof,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eo.id_professional) name_prof,
                   
                   eo.flg_temp,
                   eo.id_institution,
                   eo.id_software,
                   eo.flg_type,
                   eo.dt_epis_observation_tstz,
                   eo.id_epis_observation_parent,
                   eo.flg_status
              FROM epis_observation eo
             WHERE eo.id_epis_observation = i_epis_observation;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_OBSERV_FREE_TEXT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_information);
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Toda a informação para um ID episódio de revisão de sistemas
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_prof_cat_type       category of professional
    * @param i_epis_rev_system     episode review of system id
    * @param o_information         array with all information to episode review of system
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/09/24
    **********************************************************************************************/
    FUNCTION get_epis_review_sys_free_text
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        i_epis_rev_system IN epis_review_systems.id_epis_review_systems%TYPE,
        o_information     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_INFORMATION';
        OPEN o_information FOR
            SELECT pk_date_utils.date_send_tsz(i_lang, ers.dt_creation_tstz, i_prof) dt_creation,
                   ers.id_episode,
                   ers.id_professional,
                   --pk_tools.get_prof_nick_name(i_lang, ers.id_professional) name_prof,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ers.id_professional) name_prof,
                   
                   ers.desc_review_systems,
                   ers.id_prof_cancel,
                   --pk_tools.get_prof_nick_name(i_lang, ers.id_prof_cancel) name_prof_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ers.id_prof_cancel) name_prof_cancel,
                   
                   ers.flg_status,
                   ers.dt_creation_tstz,
                   ers.dt_cancel_tstz,
                   ers.id_epis_review_systems_parent
              FROM epis_review_systems ers
             WHERE ers.id_epis_review_systems = i_epis_rev_system;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_REVIEW_SYS_FREE_TEXT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_information);
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Checks last episode of review of systems.
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_rev_system          last review of systems episode 
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/01
    **********************************************************************************************/
    FUNCTION get_summ_last_review_system
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_rev_system OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_last_epis_free_text    epis_review_systems.id_epis_review_systems%TYPE;
        l_last_date_free_text    epis_review_systems.dt_creation_tstz%TYPE;
        l_last_epis_touch_option epis_documentation.id_epis_documentation%TYPE;
        l_last_date_touch_option epis_documentation.dt_creation_tstz%TYPE;
    BEGIN
        BEGIN
            g_error := 'Find last epis_review_systems';
            SELECT id_epis_review_systems, dt_creation_tstz
              INTO l_last_epis_free_text, l_last_date_free_text
              FROM (SELECT ers.id_epis_review_systems, ers.dt_creation_tstz
                      FROM epis_review_systems ers
                     WHERE ers.id_episode = i_episode
                     ORDER BY ers.dt_creation_tstz DESC) t
             WHERE rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        --
        g_error := 'CALL pk_touch_option.get_last_doc_area';
        IF NOT pk_touch_option.get_last_doc_area(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_episode            => i_episode,
                                                 i_doc_area           => g_doc_area_rev_sys,
                                                 o_last_epis_doc      => l_last_epis_touch_option,
                                                 o_last_date_epis_doc => l_last_date_touch_option,
                                                 o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        IF l_last_date_free_text > l_last_date_touch_option
           OR l_last_date_touch_option IS NULL
        THEN
            g_error := 'OPEN O_REV_SYSTEM - Free text';
            OPEN o_rev_system FOR
                SELECT ers.desc_review_systems desc_element
                  FROM epis_review_systems ers
                 WHERE ers.id_epis_review_systems = l_last_epis_free_text;
        
        ELSIF l_last_date_touch_option > l_last_date_free_text
              OR l_last_date_free_text IS NULL
        THEN
            g_error := 'OPEN O_REV_SYSTEM - Touch option';
            IF NOT pk_summary_page.get_summ_last_doc_area(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_epis_documentation => l_last_epis_touch_option,
                                                          i_doc_area           => g_doc_area_rev_sys,
                                                          o_documentation      => o_rev_system,
                                                          o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_rev_system);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_SUMM_LAST_REVIEW_SYSTEM',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_rev_system);
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Checks last episode of physical exam.
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param i_prof_cat_type       Categoria do profissional
    * @param o_physical_exam       last physical exam episode 
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/01
    **********************************************************************************************/
    FUNCTION get_summ_last_physical_exam
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_physical_exam OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_last_epis_free_text    epis_observation.id_epis_observation%TYPE;
        l_last_date_free_text    epis_observation.dt_epis_observation_tstz%TYPE;
        l_last_epis_touch_option epis_documentation.id_epis_documentation%TYPE;
        l_last_date_touch_option epis_documentation.dt_creation_tstz%TYPE;
        l_doc_area_obs_exam      doc_area.id_doc_area%TYPE;
    BEGIN
        BEGIN
            g_error := 'Find last epis_observation';
            SELECT id_epis_observation, dt_epis_observation_tstz
              INTO l_last_epis_free_text, l_last_date_free_text
              FROM (SELECT eo.id_epis_observation, eo.dt_epis_observation_tstz
                      FROM epis_observation eo
                     WHERE eo.id_episode = i_episode
                       AND eo.flg_type = decode(i_prof_cat_type,
                                                g_cat_flg_type_d,
                                                g_observ_flg_type_e,
                                                g_cat_flg_type_u,
                                                g_observ_flg_type_e,
                                                g_observ_flg_type_a)
                     ORDER BY eo.dt_epis_observation_tstz DESC) t
             WHERE rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        --
    
        l_doc_area_obs_exam := g_doc_area_phy_exam;
    
        g_error := 'CALL pk_touch_option.get_last_doc_area';
        IF NOT pk_touch_option.get_last_doc_area(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_episode            => i_episode,
                                                 i_doc_area           => l_doc_area_obs_exam,
                                                 o_last_epis_doc      => l_last_epis_touch_option,
                                                 o_last_date_epis_doc => l_last_date_touch_option,
                                                 o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        IF l_last_date_free_text > l_last_date_touch_option
           OR l_last_date_touch_option IS NULL
        THEN
            g_error := 'OPEN O_PHYSICAL_EXAM - Free text';
            OPEN o_physical_exam FOR
                SELECT eo.desc_epis_observation desc_element, eo.desc_epis_observation desc_info
                  FROM epis_observation eo
                 WHERE eo.id_epis_observation = l_last_epis_free_text;
        
        ELSIF l_last_date_touch_option > l_last_date_free_text
              OR l_last_date_free_text IS NULL
        THEN
            g_error := 'OPEN O_PHYSICAL_EXAM - Touch option';
            IF NOT pk_summary_page.get_summ_last_doc_area(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_epis_documentation => l_last_epis_touch_option,
                                                          i_doc_area           => l_doc_area_obs_exam,
                                                          o_documentation      => o_physical_exam,
                                                          o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_physical_exam);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_SUMM_LAST_PHYSICAL_EXAM',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_physical_exam);
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Checks last episode of anamnesis or complaint
    *
    * @param i_lang                    id da lingua 
    * @param i_episode                 id do episódio
    * @param i_prof                    objecto do profissional
    * @param i_flg_type                informação que se quer saber: C para queixa e A para anamnese 
    * @param o_anamnesis               Last complaint episode  
    * @param o_error                   mensagem de erro
    *
    * @return                          true successo, false erro
    *  
    * @author                          Emilia Taborda
    * @version                         1.0
    * @since                           2007/10/01
    ********************************************************************************************/
    FUNCTION get_summ_last_anamnesis
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN epis_anamnesis.id_episode%TYPE,
        i_prof      IN profissional,
        i_flg_type  IN epis_anamnesis.flg_type%TYPE,
        o_anamnesis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_last_epis_free_text    epis_anamnesis.id_epis_anamnesis%TYPE;
        l_last_date_free_text    epis_anamnesis.dt_epis_anamnesis_tstz%TYPE;
        l_last_epis_touch_option epis_documentation.id_epis_documentation%TYPE;
        l_last_date_touch_option epis_documentation.dt_creation_tstz%TYPE;
    BEGIN
        BEGIN
            g_error := 'Find last epis_observation';
            SELECT id_epis_anamnesis, dt_epis_anamnesis_tstz
              INTO l_last_epis_free_text, l_last_date_free_text
              FROM (SELECT ea.id_epis_anamnesis, ea.dt_epis_anamnesis_tstz
                      FROM epis_anamnesis ea
                     WHERE ea.id_episode = i_episode
                       AND ea.flg_type = i_flg_type
                     ORDER BY ea.dt_epis_anamnesis_tstz DESC) t
             WHERE rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        --
        IF i_flg_type = g_flg_type_c
        THEN
            g_error := 'CALL pk_complaint.get_last_complaint_templ';
            IF NOT pk_complaint.get_last_complaint_templ(i_lang                 => i_lang,
                                                         i_prof                 => i_prof,
                                                         i_episode              => i_episode,
                                                         o_last_epis_compl      => l_last_epis_touch_option,
                                                         o_last_date_epis_compl => l_last_date_touch_option,
                                                         o_error                => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'CALL pk_touch_option.get_last_doc_area';
            IF NOT pk_touch_option.get_last_doc_area(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_episode            => i_episode,
                                                     i_doc_area           => g_doc_area_hist_ill,
                                                     o_last_epis_doc      => l_last_epis_touch_option,
                                                     o_last_date_epis_doc => l_last_date_touch_option,
                                                     o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
        --
        IF l_last_date_free_text > l_last_date_touch_option
           OR l_last_date_touch_option IS NULL
        THEN
            g_error := 'OPEN O_ANAMNESIS - Free text';
            pk_utils.put_line(g_error);
            OPEN o_anamnesis FOR
                SELECT ea.desc_epis_anamnesis desc_element,
                       ea.id_professional,
                       ' (' || pk_message.get_message(i_lang, 'EDIS_IDENT_T001') || ' ' ||
                       pk_tools.get_prof_nick_name(i_lang, ea.id_professional) || ';' ||
                       pk_date_utils.date_time_chr_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof) || ')' anamnesis_prof
                  FROM epis_anamnesis ea
                 WHERE ea.id_epis_anamnesis = l_last_epis_free_text;
        
        ELSIF l_last_date_touch_option > l_last_date_free_text
              OR l_last_date_free_text IS NULL
        THEN
            IF i_flg_type = g_flg_type_c -- QUEIXA
            THEN
                g_error := 'OPEN O_ANAMNESIS - Complaint(Touch option)';
                OPEN o_anamnesis FOR
                    SELECT pk_translation.get_translation(i_lang, 'COMPLAINT.CODE_COMPLAINT.' || ec.id_complaint) desc_complaint,
                           ec.id_professional,
                           ' (' || pk_message.get_message(i_lang, 'EDIS_IDENT_T001') || ' ' ||
                           --pk_tools.get_prof_nick_name(i_lang, ec.id_professional) || ';' ||
                            pk_prof_utils.get_name_signature(i_lang, i_prof, ec.id_professional) || ';' ||
                           
                            pk_date_utils.date_time_chr_tsz(i_lang, ec.adw_last_update_tstz, i_prof) || ')' anamnesis_prof
                      FROM epis_complaint ec
                     WHERE ec.id_epis_complaint = l_last_epis_touch_option;
            
            ELSE
                -- HISTORIA
                g_error := 'OPEN o_anamnesis - Touch option';
                IF NOT pk_summary_page.get_summ_last_doc_area(i_lang               => i_lang,
                                                              i_prof               => i_prof,
                                                              i_epis_documentation => l_last_epis_touch_option,
                                                              i_doc_area           => g_doc_area_hist_ill,
                                                              o_documentation      => o_anamnesis,
                                                              o_error              => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_anamnesis);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_SUMM_LAST_ANAMNESIS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_anamnesis);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Returns cursor with last record made in the social or family history area, according to the i_flg_type parameter
    *
    * @param i_lang                    language id
    * @param i_prof                    user's data
    * @param i_patient                 patient id
    * @param i_flg_type                which area to check: F - family, S -ssocial , R - surgical
    * @param o_history               cursor with data  
    * @param o_error                   mensagem de erro
    *
    * @return                          true successo, false erro
    *  
    * @author                          João Eiras, 
    * @version                         1.0
    * @since                           2008/01/28
    ********************************************************************************************/
    FUNCTION get_summ_last_soc_fam_sr_hist
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_flg_type IN pat_fam_soc_hist.flg_type%TYPE,
        o_history  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_last_epis_free_text    epis_anamnesis.id_epis_anamnesis%TYPE;
        l_last_date_free_text    epis_anamnesis.dt_epis_anamnesis_tstz%TYPE;
        l_last_epis_touch_option epis_documentation.id_epis_documentation%TYPE;
        l_last_date_touch_option epis_documentation.dt_creation_tstz%TYPE;
    
        l_doc_area doc_area.id_doc_area%TYPE;
    BEGIN
        g_error := 'GET DOC_AREA';
        IF i_flg_type = g_pat_hist_type_fam
        THEN
            l_doc_area := g_doc_area_past_fam;
        ELSIF i_flg_type = g_pat_hist_type_soc
        THEN
            l_doc_area := g_doc_area_past_soc;
        ELSIF i_flg_type = 'R'
        THEN
            l_doc_area := g_doc_area_past_surg;
        ELSE
            pk_types.open_my_cursor(o_history);
            g_error := 'INVALID FLG_TYPE';
            raise_application_error('20001', g_error);
        END IF;
    
        BEGIN
            g_error := 'FIND LAST EPIS_OBSERVATION - FREE TEXT';
            IF i_flg_type IN (g_pat_hist_type_fam, g_pat_hist_type_soc)
            THEN
                g_error := 'FIND LAST EPIS_OBSERVATION FS - FREE TEXT';
                SELECT *
                  INTO l_last_epis_free_text, l_last_date_free_text
                  FROM (SELECT pf.id_pat_fam_soc_hist, pf.dt_pat_fam_soc_hist_tstz
                          FROM pat_fam_soc_hist pf
                         WHERE pf.id_patient = i_patient
                           AND pf.flg_type = i_flg_type
                           AND pf.flg_status != pk_alert_constant.g_cancelled
                           AND pf.flg_type = i_flg_type
                           AND i_flg_type IN (g_pat_hist_type_fam, g_pat_hist_type_soc)) t
                 WHERE rownum < 2;
            ELSE
                g_error := 'FIND LAST EPIS_OBSERVATION R - FREE TEXT';
                SELECT *
                  INTO l_last_epis_free_text, l_last_date_free_text
                  FROM (SELECT ph.id_pat_history_diagnosis, ph.dt_pat_history_diagnosis_tstz
                          FROM pat_history_diagnosis ph, alert_diagnosis ad
                         WHERE ph.flg_type = g_pat_hist_diag_surg
                           AND ph.id_patient = i_patient
                           AND ph.id_alert_diagnosis = ad.id_alert_diagnosis
                           AND (ad.flg_type = g_alert_diag_type_surg OR
                               ph.id_alert_diagnosis IN (g_alert_diag_unknown, g_alert_diag_none))
                           AND ph.flg_type IN (g_alert_diag_type_surg)
                         ORDER BY 2 DESC) t
                 WHERE rownum < 2;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        --
        BEGIN
            g_error := 'FIND LAST EPIS_OBSERVATION - TOUCH OPTION';
            SELECT id_epis_documentation, dt_creation_tstz
              INTO l_last_epis_touch_option, l_last_date_touch_option
              FROM (SELECT ed.id_epis_documentation, ed.dt_creation_tstz
                      FROM epis_documentation ed
                     WHERE ed.id_episode IN (SELECT e.id_episode
                                               FROM episode e
                                              WHERE e.id_patient = i_patient)
                       AND ed.id_doc_area = l_doc_area
                       AND ed.flg_status != pk_alert_constant.g_cancelled
                     ORDER BY ed.dt_creation_tstz DESC)
             WHERE rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        --
        IF l_last_date_free_text > l_last_date_touch_option
           OR l_last_date_touch_option IS NULL
        THEN
            g_error := 'OPEN O_HISTORY - FREE TEXT';
            OPEN o_history FOR
                SELECT pf.notes desc_element
                  FROM pat_fam_soc_hist pf
                 WHERE pf.id_pat_fam_soc_hist = l_last_epis_free_text
                   AND i_flg_type IN (g_pat_hist_type_fam, g_pat_hist_type_soc)
                UNION ALL
                SELECT REPLACE(REPLACE(decode(phd.id_alert_diagnosis,
                                              pk_summary_page.g_diag_none,
                                              pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                                      pk_summary_page.g_pat_hist_diag_none,
                                                                      i_lang),
                                              decode(phd.id_alert_diagnosis,
                                                     pk_summary_page.g_diag_unknown,
                                                     pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                                             pk_summary_page.g_pat_hist_diag_unknown,
                                                                             i_lang),
                                                     -- ALERT-736: diagnosis synonyms support                        
                                                     pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                                i_prof               => i_prof,
                                                                                i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                                i_id_diagnosis       => d.id_diagnosis,
                                                                                i_code               => d.code_icd,
                                                                                i_flg_other          => d.flg_other,
                                                                                i_flg_std_diag       => ad.flg_icd9) ||
                                                     nvl2(phd.desc_pat_history_diagnosis,
                                                          ' - ' || phd.desc_pat_history_diagnosis,
                                                          '') || nvl2(phd.notes, chr(10) || phd.notes, ''))),
                                       '<b>',
                                       ''),
                               '</b>',
                               '') desc_element
                  FROM pat_history_diagnosis phd,
                       alert_diagnosis ad,
                       diagnosis d,
                       (SELECT MAX(p2.dt_pat_history_diagnosis_tstz) dt_pat_history_diagnosis_tstz,
                               p2.id_alert_diagnosis
                          FROM pat_history_diagnosis p2, alert_diagnosis a2
                         WHERE p2.id_alert_diagnosis = a2.id_alert_diagnosis
                           AND p2.id_patient = i_patient
                           AND (a2.flg_type = g_pat_hist_diag_surg OR
                               p2.id_alert_diagnosis IN (pk_summary_page.g_diag_unknown, pk_summary_page.g_diag_none))
                         GROUP BY p2.id_alert_diagnosis) filter
                 WHERE phd.id_alert_diagnosis = ad.id_alert_diagnosis
                   AND phd.id_diagnosis = d.id_diagnosis(+)
                   AND phd.id_patient = i_patient
                   AND phd.flg_status != pk_alert_constant.g_cancelled
                   AND (ad.flg_type = g_pat_hist_diag_surg OR
                       phd.id_alert_diagnosis IN (pk_summary_page.g_diag_unknown, pk_summary_page.g_diag_none))
                   AND phd.flg_type = g_pat_hist_diag_surg
                   AND phd.id_alert_diagnosis = filter.id_alert_diagnosis
                   AND (phd.id_alert_diagnosis NOT IN (pk_summary_page.g_diag_none, pk_summary_page.g_diag_unknown) OR
                       phd.id_pat_history_diagnosis_new IS NULL)
                   AND phd.dt_pat_history_diagnosis_tstz = filter.dt_pat_history_diagnosis_tstz
                   AND i_flg_type = 'R';
        
        ELSIF l_last_date_touch_option > l_last_date_free_text
              OR l_last_date_free_text IS NULL
        THEN
            g_error := 'OPEN O_HISTORY - TOUCH OPTION';
            IF NOT pk_summary_page.get_summ_last_doc_area(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_epis_documentation => l_last_epis_touch_option,
                                                          i_doc_area           => l_doc_area,
                                                          o_documentation      => o_history,
                                                          o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_history);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_SUMM_LAST_SOC_FAM_SR_HIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_history);
            RETURN FALSE;
    END;

    --
    /********************************************************************************************
    * Returns cursor with last record of exam or assessment in this episode, in free text
    *
    * @param i_lang                language id
    * @param i_episode             episóde id
    * @param i_prof                professional object
    * @param i_flg_type            type of information to return
    * @param o_last_update         cursor with data
    * @param o_error               error message
    *
    * @value i_flg_type           {*} 'E' exam {A} Assessment
    *
    * @return                      true success, false error
    *  
    * @author                      Ariel Machado
    * @version                     1.0
    * @since                       2008/04/15 
    ********************************************************************************************/
    FUNCTION get_epis_obs_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN epis_observation.id_episode%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN epis_observation.flg_type%TYPE,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_LAST_UPDATE';
        OPEN o_last_update FOR
            SELECT *
              FROM (SELECT pk_date_utils.date_send_tsz(i_lang, eo.dt_epis_observation_tstz, i_prof) dt_epis_observation,
                           --pk_tools.get_prof_nick_name(i_lang, eo.id_professional) nick_name,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, eo.id_professional) nick_name,
                           
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            eo.id_professional,
                                                            eo.dt_epis_observation_tstz,
                                                            eo.id_episode) desc_speciality,
                           pk_date_utils.date_chr_short_read_tsz(i_lang, eo.dt_epis_observation_tstz, i_prof) date_target,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            eo.dt_epis_observation_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) hour_target,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       eo.dt_epis_observation_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) date_hour_target
                    
                      FROM epis_observation eo
                     WHERE eo.id_episode = i_episode
                       AND eo.flg_type = nvl(i_flg_type, eo.flg_type)
                     ORDER BY eo.dt_epis_observation_tstz DESC)
             WHERE rownum < 2;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_EPIS_OBS_LAST_UPDATE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_last_update);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Criar queixa / anamnese 
    *
    * @param i_lang                 id da lingua
    * @param i_episode              episode id
    * @param i_prof                 objecto com info do utilizador
    * @param i_desc                 descrição da queixa / anamnese 
    * @param i_flg_type             C  - queixa ; A - anamnese
    * @param i_flg_type_mode        A - Agree, E - edit, N - new
    * @param i_id_epis_anamnesis    Episódio da queixa/historia 
    * @param i_id_diag              ID do diagnóstico associado ao texto + freq.seleccionado para registo da queixa / história 
    * @param i_flg_class            A - motivo administrativo de consulta (CARE: texto + freq. do ICPC2)
    * @param i_prof_cat_type        Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF
    * @param i_dt_init              data de início de consulta
    * @param o_id_epis_anamnesis    registo           
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       Teresa Coutinho
    * @version                      1.0
    * @since                        2008/05/08
    ********************************************************************************************/
    FUNCTION set_epis_anamnesis
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN epis_anamnesis.id_episode%TYPE,
        i_prof              IN profissional,
        i_desc              IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_flg_type          IN epis_anamnesis.flg_type%TYPE,
        i_flg_type_mode     IN VARCHAR2,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        i_id_diag           IN epis_anamnesis.id_diagnosis%TYPE,
        i_flg_class         IN epis_anamnesis.flg_class%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_dt_init           IN VARCHAR2,
        o_id_epis_anamnesis OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error t_error_out;
    BEGIN
        g_error := 'CALL PK_VISIT.SET_VISIT_INIT';
        IF NOT
            pk_visit.set_visit_init(i_lang => i_lang, i_id_episode => i_episode, i_prof => i_prof, o_error => l_error)
        
        THEN
            o_error := l_error;
            RETURN FALSE;
        
        END IF;
    
        g_error := 'CALL PK_CLINICAL_INFO.SET_EPIS_ANAMNESIS';
        IF NOT pk_clinical_info.set_epis_anamnesis(i_lang              => i_lang,
                                                   i_episode           => i_episode,
                                                   i_prof              => i_prof,
                                                   i_desc              => i_desc,
                                                   i_flg_type          => i_flg_type,
                                                   i_flg_type_mode     => i_flg_type_mode,
                                                   i_id_epis_anamnesis => i_id_epis_anamnesis,
                                                   i_id_diag           => i_id_diag,
                                                   i_flg_class         => i_flg_class,
                                                   i_prof_cat_type     => i_prof_cat_type,
                                                   o_id_epis_anamnesis => o_id_epis_anamnesis,
                                                   o_error             => l_error)
        THEN
            o_error := l_error;
            RETURN FALSE;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'SET_EPIS_ANAMNESIS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /********************************************************************************************
    * Obter queixa / anamnese de episódio anterior (ou de 1º episódio) no caso deste ser subsequente
    *
    * @param i_lang                 id da lingua
    * @param i_episode              episode id
    * @param i_prof                 objecto com info do utilizador
    * @param o_id_epis_anamnesis    registo           
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       Pedro Teixeira
    * @version                      1.0
    * @since                        2008/06/17
    ********************************************************************************************/
    FUNCTION get_subsequent_epis_anamnesis
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN epis_anamnesis.id_episode%TYPE,
        i_prof                IN profissional,
        o_id_epis_anamnesis   OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_desc_epis_anamnesis OUT epis_anamnesis.desc_epis_anamnesis%TYPE,
        o_id_visit            OUT visit.id_visit%TYPE,
        o_id_clinical_service OUT episode.id_clinical_service%TYPE,
        o_id_patient          OUT patient.id_patient%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_visit              visit.id_visit%TYPE;
        l_id_clinical_service   episode.id_clinical_service%TYPE;
        l_id_patient            patient.id_patient%TYPE;
        l_count_espis_anamnesis NUMBER;
        l_sys_reason_sugestion  VARCHAR2(1);
        CURSOR c_count_epis_anamnesis IS
            SELECT COUNT(1)
              FROM epis_anamnesis ea
             WHERE ea.id_episode = i_episode
               AND flg_type = g_flg_type_c;
    
        CURSOR c_episode IS
            SELECT e.id_visit, e.id_clinical_service, e.id_patient
              FROM episode e
             WHERE e.id_episode = i_episode;
    
    BEGIN
        g_error := 'GET CURSOR C_COUNT_EPIS_ANAMNESIS';
        OPEN c_count_epis_anamnesis;
        FETCH c_count_epis_anamnesis
            INTO l_count_espis_anamnesis;
        CLOSE c_count_epis_anamnesis;
    
        IF l_count_espis_anamnesis = 0
        THEN
            g_error := 'GET CURSOR C_EPISODE';
            OPEN c_episode;
            FETCH c_episode
                INTO l_id_visit, l_id_clinical_service, l_id_patient;
            CLOSE c_episode;
        
            o_id_visit            := l_id_visit;
            o_id_patient          := l_id_patient;
            o_id_clinical_service := l_id_clinical_service;
        
            l_sys_reason_sugestion := pk_sysconfig.get_config('VISIT_REASON_SUGESTION', i_prof);
        
            IF l_sys_reason_sugestion = pk_alert_constant.g_yes
            THEN
                BEGIN
                    SELECT reason_notes
                      INTO o_desc_epis_anamnesis
                      FROM epis_info e, schedule s
                     WHERE e.id_episode = i_episode
                       AND e.id_schedule = s.id_schedule;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        o_desc_epis_anamnesis := NULL;
                END;
            END IF;
            IF o_desc_epis_anamnesis IS NULL
            THEN
                g_error := 'GET EPIS_ANAMNESIS';
            
                BEGIN
                    SELECT fea.id_epis_anamnesis, fea.desc_epis_anamnesis
                      INTO o_id_epis_anamnesis, o_desc_epis_anamnesis
                      FROM epis_anamnesis fea
                     WHERE fea.id_epis_anamnesis =
                           (SELECT MAX(ea.id_epis_anamnesis) -- necessário para o caso de existir registos de ea.dt_epis_anamnesis_tstz iguais para o mesmo episódio
                              FROM episode e, epis_anamnesis ea
                             WHERE e.id_patient = l_id_patient
                               AND e.id_episode != i_episode
                               AND e.id_clinical_service = l_id_clinical_service
                               AND ea.id_episode = e.id_episode
                               AND e.flg_ehr = g_flg_ehr_n
                               AND ea.flg_type = g_flg_type_c
                               AND e.id_epis_type IN
                                   (pk_alert_constant.g_epis_type_outpatient, pk_alert_constant.g_epis_type_primary_care) -- só disponível para OUTPATIENT e CARE
                               AND e.dt_begin_tstz =
                                   (SELECT MAX(e1.dt_begin_tstz) -- episódio mais recente diferente do actual
                                      FROM episode e1
                                     WHERE e1.id_patient = e.id_patient
                                       AND e1.id_episode != i_episode
                                       AND e1.flg_ehr = g_flg_ehr_n
                                       AND e1.id_clinical_service = e.id_clinical_service));
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CLINICAL_INFO',
                                              i_function => 'GET_SUBSEQUENT_EPIS_ANAMNESIS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Retorna a lista dos motivos codificados ou a lista dos textos mais frequentes. Isto
    * consoante a configuração.
    *
    * @param i_lang                ID language
    * @param i_prof                Professional's details     
    * @param i_pat                 ID of patient 
    * @param i_episode             ID of episode
    *
    * @param o_type                The type of information R - Epis_anamnesis (codified); S - Sample Text
    * @param o_text                Array of information for evaluation notes
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/03/20
    **********************************************************************************************/

    FUNCTION get_evaluation_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_episode IN epis_anamnesis.id_episode%TYPE,
        o_text    OUT pk_types.cursor_type,
        o_type    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sys_reason_codification VARCHAR2(1);
    BEGIN
        g_error                   := 'GET CONFIG VISIT_REASON_DOCTOR_CODIFICATION';
        l_sys_reason_codification := pk_sysconfig.get_config('VISIT_REASON_DOCTOR_CODIFICATION', i_prof);
        IF l_sys_reason_codification = pk_alert_constant.g_no
        THEN
            g_error := 'CALL PK_SAMPLE_TEXT.GET_SAMPLE_TEXT';
            IF NOT pk_sample_text.get_sample_text(i_lang             => i_lang,
                                                  i_sample_text_type => 'NOTES_EVALUATION',
                                                  i_patient          => i_pat,
                                                  i_prof             => i_prof,
                                                  o_sample_text      => o_text,
                                                  o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
            o_type := 'S';
        ELSE
            g_error := 'CALL get_diag_anamnesis';
            IF NOT get_diag_anamnesis(i_lang    => i_lang,
                                      i_pat     => i_pat,
                                      i_episode => i_episode,
                                      o_text    => o_text,
                                      o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
            o_type := 'R';
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CLINICAL_INFO',
                                              'GET_EVALUATION_NOTES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_text);
            RETURN FALSE;
        
    END get_evaluation_notes;

    FUNCTION get_epis_reason_for_visit
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN NUMBER,
        i_id_schedule IN NUMBER,
        i_separator   IN VARCHAR2 DEFAULT '.'
    ) RETURN CLOB IS
    
        l_epis_reason CLOB;
    
        CURSOR c_epis_reason_for_visit IS
            SELECT pk_utils.concat_table(i_tab => b.reason, i_delim => chr(10)) desc_reason
              FROM (SELECT CAST(MULTISET
                                (SELECT a.reason
                                   FROM (SELECT concatenate_clob(pk_translation.get_translation(i_lang,
                                                                                                'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                ec.id_complaint) ||
                                                                 i_separator || ' ') reason,
                                                1 rank
                                           FROM epis_complaint ec
                                          WHERE ec.id_episode = i_id_episode
                                            AND ec.flg_status = pk_alert_constant.g_active
                                         UNION ALL
                                         SELECT concatenate_clob(desc_epis_anamnesis || i_separator || ' ') reason, 2 rank
                                           FROM epis_anamnesis ea
                                          WHERE ea.id_episode = i_id_episode
                                            AND ea.id_institution = i_prof.institution
                                            AND ea.id_software = i_prof.software
                                            AND ea.flg_type = g_complaint
                                            AND ea.flg_status = pk_alert_constant.g_active
                                            AND ea.flg_temp != g_flg_hist
                                          ORDER BY rank) a
                                  WHERE dbms_lob.compare(a.reason, empty_clob()) <> 0) AS table_clob) reason
                      FROM dual) b;
    
        CURSOR c_epis_appointment_reason IS
            SELECT to_clob(TRIM(nvl2(s.reason_notes, s.reason_notes || chr(10), NULL) ||
                                decode(decode(s.flg_reason_type, 'C', s.id_reason, NULL),
                                       NULL,
                                       NULL,
                                       pk_translation.get_translation(i_lang, 'COMPLAINT.CODE_COMPLAINT.' || s.id_reason)))) reason
              FROM schedule s
             WHERE s.id_schedule = i_id_schedule
               AND (s.reason_notes IS NOT NULL OR (s.id_reason IS NOT NULL AND s.flg_reason_type = 'C'));
    BEGIN
        IF i_id_episode IS NOT NULL
        THEN
            g_error := 'GET CURSOR C_EPIS_ANAMNESIS_REASON';
            OPEN c_epis_reason_for_visit;
            FETCH c_epis_reason_for_visit
                INTO l_epis_reason;
            CLOSE c_epis_reason_for_visit;
        END IF;
        IF length(l_epis_reason) = 0
        THEN
            g_error := 'GET CURSOR C_EPIS_APPOINTMENT_REASON';
            OPEN c_epis_appointment_reason;
            FETCH c_epis_appointment_reason
                INTO l_epis_reason;
            CLOSE c_epis_appointment_reason;
        END IF;
        RETURN rtrim(l_epis_reason, i_separator || ' ');
    END get_epis_reason_for_visit;

    /**********************************************************************************************
    * Retorna o motivo da consulta ou o do agendamento
    *
    * @param i_lang                ID language
    * @param i_id_schedule         ID schedule
    * @param i_episode             ID of episode
    *
    * @param o_epis_reason         The reason for visit
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/03/20
    **********************************************************************************************/

    FUNCTION get_epis_reason_for_visit
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN NUMBER,
        i_id_schedule IN NUMBER,
        o_epis_reason OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error       := 'CALL  CURSOR get_epis_reason_for_visit';
        o_epis_reason := pk_string_utils.clob_to_varchar2(i_clob            => get_epis_reason_for_visit(i_lang,
                                                                                                         i_prof,
                                                                                                         i_id_episode,
                                                                                                         i_id_schedule),
                                                          i_maxlenght_bytes => 4000);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CLINICAL_INFO',
                                              'GET_EVALUATION_NOTES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_reason_for_visit;

    /**********************************************************************************************
    * Returns complaint related anamnesis. Used in ambulatory products.
    * Not called directly by the UI layer.
    *
    * @param i_lang                language identifier
    * @param i_prof                logged professional structure
    * @param i_episode             episode identifier
    * @param o_anamnesis           cursor
    * @param o_error               error
    *
    * @return                      false if errors occur, true otherwise
    *                        
    * @author                      Pedro Carneiro
    * @version                      2.5.0.6
    * @since                       2009/09/18
    **********************************************************************************************/
    FUNCTION get_anamnesis_summ
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN epis_anamnesis.id_episode%TYPE,
        o_anamnesis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN o_anamnesis';
        OPEN o_anamnesis FOR
            SELECT ea.id_epis_anamnesis, ea.desc_epis_anamnesis
              FROM epis_anamnesis ea
             WHERE ea.id_episode = i_episode
               AND ea.id_institution = i_prof.institution
               AND ea.id_software = i_prof.software
               AND ea.flg_type = g_complaint
               AND ea.flg_status = pk_alert_constant.g_active
               AND ea.flg_temp != g_flg_hist
             ORDER BY ea.dt_epis_anamnesis_tstz DESC;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     g_package_name,
                                                     'GET_ANAMNESIS_SUMM',
                                                     o_error);
    END get_anamnesis_summ;

    /**********************************************************************************************
    * Returns complaint related anamnesis associated to the episodes of an patient to a given epis
    * type. 
    * Not called directly by the UI layer.
    *
    * @param i_lang                language identifier
    * @param i_prof                logged professional structure
    * @param i_id_patient          Patient identifier
    * @param i_id_epis_type        Epis type identifier
    * @param i_flg_which           ALL- all the episodes
    *                              CUR- active episodes
    *                              PRV- inactive episodes                             
    * @param o_anamnesis           output cursor
    * @param o_error               error
    *
    * @return                      false if errors occur, true otherwise
    *                        
    * @author                      Sofia Mendes
    * @version                      2.5.1
    * @since                       08-Sep-2010
    **********************************************************************************************/
    FUNCTION get_anamnesis_pat
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_flg_which    IN VARCHAR2,
        o_anamnesis    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN o_anamnesis';
        OPEN o_anamnesis FOR
            SELECT epi.id_episode,
                   ea.id_epis_anamnesis,
                   ea.desc_epis_anamnesis,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ea.id_professional,
                                                    ea.dt_epis_anamnesis_tstz,
                                                    ea.id_episode) desc_speciality,
                   pk_date_utils.date_char_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof.institution, i_prof.software) dt_epis_anamnesis,
                   ea.dt_epis_anamnesis_tstz
              FROM epis_anamnesis ea
              JOIN episode epi
                ON epi.id_episode = ea.id_episode
             WHERE (epi.flg_ehr = pk_alert_constant.g_epis_ehr_normal OR
                   epi.flg_ehr = pk_alert_constant.g_epis_ehr_schedule)
               AND epi.id_institution = i_prof.institution
               AND epi.id_epis_type = i_id_epis_type
               AND ((nvl(i_flg_which, 'ALL') = 'ALL') OR
                   (nvl(i_flg_which, 'ALL') = 'CUR' AND epi.flg_status = pk_alert_constant.g_active) OR
                   (nvl(i_flg_which, 'ALL') = 'PRV' AND epi.flg_status != pk_alert_constant.g_active))
               AND ea.id_episode = epi.id_episode
               AND ea.id_institution = i_prof.institution
               AND ea.id_software = i_prof.software
               AND ea.flg_type = g_complaint
               AND ea.flg_status = pk_alert_constant.g_active
               AND ea.flg_temp != g_flg_hist
               AND epi.id_patient = i_id_patient
             ORDER BY ea.dt_epis_anamnesis_tstz DESC;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     g_package_name,
                                                     'GET_ANAMNESIS_PAT',
                                                     o_error);
    END get_anamnesis_pat;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END;
/
