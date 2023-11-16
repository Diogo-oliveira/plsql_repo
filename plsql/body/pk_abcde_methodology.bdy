/*-- Last Change Revision: $Rev: 2026600 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:17 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_abcde_methodology IS

    /********************************************************************************************
    * Trauma and ABCDE history page
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param o_ann_arrival_list       announced arrival
    * @param o_pre_hospital           pre hospital accident
    * @param o_pre_hosp_vs            vs of pre_hosp_acc
    * @param o_trauma_hist            ABCDE assessment history
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_trauma_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        o_ann_arrival_list OUT pk_types.cursor_type,
        o_pre_hospital     OUT pk_types.cursor_type,
        o_pre_hosp_vs      OUT pk_types.cursor_type,
        o_trauma_hist      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dummy_cursor pk_types.cursor_type;
    BEGIN
        g_error := 'GET ANN ARRIVAL INFO';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_announced_arrival.get_ann_arrival_by_epi(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_episode           => i_id_episode,
                                                           o_ann_arrival_list  => o_ann_arrival_list,
                                                           o_pre_hosp_accident => o_pre_hospital,
                                                           o_pre_hosp_vs_read  => o_pre_hosp_vs,
                                                           o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET AMPLE/SAMPLE/CIAMPEDS INFO';
        pk_alertlog.log_debug(g_error);
        IF NOT get_abcde_summary(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_id_episode  => i_id_episode,
                                 i_get_titles  => pk_alert_constant.g_no,
                                 o_titles      => l_dummy_cursor,
                                 o_trauma_hist => o_trauma_hist,
                                 o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_ann_arrival_list);
            pk_types.open_my_cursor(o_pre_hospital);
            pk_types.open_my_cursor(o_pre_hosp_vs);
            pk_types.open_my_cursor(o_trauma_hist);
            pk_types.open_my_cursor(l_dummy_cursor);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'GET_TRAUMA_HIST',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_trauma_hist;

    /**
      * The function returns the string with the id/ desc os all allergies and allergies unawareness registred throw trauma.
      *
      * @param i_lang                   The language ID
      * @param i_prof                   Object (professional ID, institution ID, software ID)
      * @param i_id_episode             the episode ID
      * @param i_type                   the type as two values possible: {ID, LABEL}
      * @param i_separator              The separator as teo values possible:{',' ,',, '}
    * @return                         String with the allergies descriptions
      *  
      * @author                         Pedro Fernandes
      * @version                        2.6.1.2
      * @since                          01-09-2011
      */
    FUNCTION get_allergy_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_type       IN VARCHAR2,
        i_separator  IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_allergy_desc             VARCHAR2(4000 CHAR) := '';
        l_allergy_unawareness_desc VARCHAR2(1000 CHAR) := '';
        l_error                    t_error_out;
    
        l_ret VARCHAR2(1000 CHAR);
    
    BEGIN
        CASE i_type
            WHEN g_list_id THEN
                SELECT pk_utils.concat_table(CAST(MULTISET
                                                  (SELECT pa.id_pat_allergy
                                                     FROM pat_allergy pa
                                                    WHERE pa.id_episode = i_id_episode
                                                      AND pa.flg_status IN ('A', 'P')
                                                    ORDER BY nvl(pa.desc_allergy,
                                                                 pk_translation.get_translation(i_lang,
                                                                                                'ALLERGY.CODE_ALLERGY.' ||
                                                                                                to_char(pa.id_allergy)))) AS
                                                  table_varchar),
                                             i_separator)
                  INTO l_allergy_desc
                  FROM dual;
            
                BEGIN
                    --select the id_allergy_unawareness  
                    SELECT *
                      INTO l_allergy_unawareness_desc
                      FROM (SELECT pau.id_pat_allergy_unawareness
                              FROM pat_allergy_unawareness pau
                             WHERE pau.flg_status = 'A'
                               AND pau.id_episode = i_id_episode
                             ORDER BY pau.dt_creation DESC)
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_allergy_unawareness_desc := '';
                END;
            
            WHEN g_list_label THEN
                SELECT pk_utils.concat_table(CAST(MULTISET (SELECT nvl(pa.desc_allergy,
                                                              pk_translation.get_translation(i_lang,
                                                                                             'ALLERGY.CODE_ALLERGY.' ||
                                                                                             to_char(pa.id_allergy))) || ' (' ||
                                                          pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE',
                                                                                  pa.flg_type,
                                                                                  i_lang) || '; ' ||
                                                          pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS',
                                                                                  pa.flg_status,
                                                                                  i_lang) ||
                                                          decode(pa.year_begin, NULL, '', '; ' || pa.year_begin) || ').'
                                                     FROM pat_allergy pa
                                                    WHERE pa.id_episode = i_id_episode
                                                      AND pa.flg_status IN ('A', 'P')
                                                    ORDER BY 1) AS table_varchar),
                                             i_separator)
                  INTO l_allergy_desc
                  FROM dual;
            
                BEGIN
                    --select allergie unawareness decrpition
                    SELECT *
                      INTO l_allergy_unawareness_desc
                      FROM (SELECT pk_translation.get_translation(i_lang,
                                                                  'ALLERGY_UNAWARENESS.CODE_ALLERGY_UNAWARENESS.' ||
                                                                  to_char(pau.id_allergy_unawareness))
                              FROM pat_allergy_unawareness pau
                             WHERE pau.flg_status = 'A'
                               AND pau.id_episode = i_id_episode
                             ORDER BY pau.dt_creation DESC)
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_allergy_unawareness_desc := '';
                END;
            
            WHEN g_list_type THEN
                SELECT pk_utils.concat_table(CAST(MULTISET
                                                  (SELECT pa.flg_type
                                                     FROM pat_allergy pa
                                                    WHERE pa.id_episode = i_id_episode
                                                      AND pa.flg_status IN ('A', 'P')
                                                    ORDER BY nvl(pa.desc_allergy,
                                                                 pk_translation.get_translation(i_lang,
                                                                                                'ALLERGY.CODE_ALLERGY.' ||
                                                                                                to_char(pa.id_allergy)))) AS
                                                  table_varchar),
                                             i_separator)
                  INTO l_allergy_desc
                  FROM dual;
            
                BEGIN
                    -- select the id_allergy_unawareness 
                    SELECT *
                      INTO l_allergy_unawareness_desc
                      FROM (SELECT nvl2(pau.id_pat_allergy_unawareness, 'AU', '')
                              FROM pat_allergy_unawareness pau
                             WHERE pau.flg_status = 'A'
                               AND pau.id_episode = i_id_episode
                             ORDER BY pau.dt_creation DESC)
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_allergy_unawareness_desc := '';
                END;
        END CASE;
    
        l_ret := l_allergy_desc || i_separator || l_allergy_unawareness_desc;
    
        SELECT substr(l_ret, 0, length(l_ret) - 1)
          INTO l_ret
          FROM dual;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'get_allergy_desc',
                                              l_error);
            RETURN NULL;
    END get_allergy_desc;

    /**
      * This function returns the allergies and allergies unawareness registred throw Trauma
      * @param i_lang                   The language ID
      * @param i_prof                   Object (professional ID, institution ID, software ID)
      * @param i_id_episode             the episode ID
      * @param i_epis_abcde_meth        The abcde episode
      * @param i_separator              The separator as two values possible:{',' ,',, '}
    * @return                         true or false on success or error
      *
      * @autor                          Pedro Fernandes
    * @version                        2.6.1.2
    * @since                          01-09-2011
      **/
    FUNCTION get_allergy_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE
    ) RETURN VARCHAR2 IS
    
        l_items           table_varchar;
        l_list_str        VARCHAR2(4000);
        l_unawareness_str VARCHAR2(1000 CHAR) := '';
        l_id_unawareness  NUMBER(3);
        l_error           t_error_out;
    
    BEGIN
    
        SELECT pk_utils.concatenate_list(CURSOR
                                         (SELECT nvl(pa.desc_allergy,
                                                     pk_translation.get_translation(i_lang,
                                                                                    'ALLERGY.CODE_ALLERGY.' ||
                                                                                    to_char(pa.id_allergy))) || ', ' ||
                                                 pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE', pa.flg_type, i_lang) || ', ' ||
                                                 pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS', pa.flg_status, i_lang) ||
                                                 decode(pa.year_begin, NULL, '', (' - ' || pa.year_begin)) || '; '
                                            FROM epis_abcde_meth_param eamp
                                            JOIN pat_allergy pa
                                              ON eamp.id_param = pa.id_pat_allergy
                                           WHERE eamp.id_epis_abcde_meth = i_epis_abcde_meth
                                             AND eamp.flg_type = 'A'
                                             AND eamp.flg_status = 'A'
                                           ORDER BY 1),
                                         ', ')
          INTO l_list_str
          FROM dual;
    
        -- Gets the id for unawareness 
        BEGIN
            SELECT (SELECT DISTINCT pau.id_allergy_unawareness AS unawareness
                      FROM epis_abcde_meth_param eamp
                      JOIN pat_allergy_unawareness pau
                        ON eamp.id_param = pau.id_pat_allergy_unawareness
                     WHERE eamp.id_epis_abcde_meth = i_epis_abcde_meth
                       AND eamp.flg_status = 'A'
                       AND eamp.flg_type = 'AU')
              INTO l_id_unawareness
              FROM dual;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_unawareness := NULL;
        END;
    
        IF l_id_unawareness IS NOT NULL
        THEN
            --Select the descriptive of unawareness      
            SELECT pk_translation.get_translation(i_lang,
                                                  'ALLERGY_UNAWARENESS.CODE_ALLERGY_UNAWARENESS.' ||
                                                  to_char(l_id_unawareness))
              INTO l_unawareness_str
              FROM dual;
        END IF;
    
        IF (length(ch => l_unawareness_str) > 0)
        THEN
            l_unawareness_str := l_unawareness_str || ';';
        END IF;
    
        RETURN l_list_str || l_unawareness_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'get_allergy_list',
                                              l_error);
            RETURN NULL;
    END get_allergy_list;

    /********************************************************************************************
    * Gets the episode medication list. Used to get the most recent records when registering
    * a new AMPLE/SAMPLE/CIAMPEDS assessment.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_type                   Return list of ID's or labels
    * @param i_separator              List items separator
    *
    * @value i_type                   {*} 'ID' Get list of ID's {*} 'LABEL' Get list of labels
    * @value i_separator              {*} ',' ID separator {*} ',, ' Label separator
    *                        
    * @return                         Medication text
    * 
    * @author                         José Brito
    * @version                        2.6.0.5
    * @since                          2011/01/15
    **********************************************************************************************/
    FUNCTION get_medication_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_type       IN VARCHAR2,
        i_separator  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_MEDICATION_LIST';
        l_items    table_varchar;
        l_list_str VARCHAR2(4000 CHAR);
        l_error    t_error_out;
    BEGIN
    
        g_error := 'GET ITEMS';
        pk_alertlog.log_debug(g_error);
        l_items := pk_api_pfh_clindoc_in.get_abcde_medication_list(i_lang       => i_lang,
                                                                   i_prof       => i_prof,
                                                                   i_id_episode => i_id_episode,
                                                                   i_id_patient => i_id_patient,
                                                                   i_type       => i_type);
    
        g_error := 'CONCAT ITEMS LIST';
        pk_alertlog.log_debug(g_error);
        SELECT pk_utils.concat_table(l_items, i_separator)
          INTO l_list_str
          FROM dual;
    
        RETURN l_list_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_medication_list;

    /********************************************************************************************
    * Gets the ABCDE assessment medication text
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_epis_abcde_meth     Assessment record ID
    *                        
    * @return                         Medication text
    * 
    * @author                         José Brito
    * @version                        2.6.0.5
    * @since                          2011/01/15
    **********************************************************************************************/
    FUNCTION get_medication_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_MEDICATION_DESC';
        l_medication_desc_med VARCHAR2(1000 CHAR);
        l_medication_desc_oth VARCHAR2(1000 CHAR);
        l_error               t_error_out;
    BEGIN
    
        g_error := 'GET MEDICATION DESC (1)';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT pk_api_pfh_clindoc_in.get_abcde_medication_desc(i_lang,
                                                                   i_prof,
                                                                   eamp.id_param,
                                                                   eam.id_episode,
                                                                   eamp.flg_type)
              INTO l_medication_desc_med
              FROM epis_abcde_meth_param eamp
              JOIN epis_abcde_meth eam
                ON eam.id_epis_abcde_meth = eamp.id_epis_abcde_meth
             WHERE eamp.id_epis_abcde_meth = i_id_epis_abcde_meth
               AND eamp.flg_type = 'P'
               AND eamp.flg_status = 'A';
        EXCEPTION
            WHEN OTHERS THEN
                l_medication_desc_med := NULL;
        END;
    
        -- Get "No Home medication" or "Cannot name medication" records
        g_error := 'GET MEDICATION DESC (2)';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT pk_api_pfh_clindoc_in.get_abcde_medication_desc(i_lang,
                                                                   i_prof,
                                                                   eamp.id_param,
                                                                   eam.id_episode,
                                                                   eamp.flg_type)
              INTO l_medication_desc_oth
              FROM epis_abcde_meth_param eamp
              JOIN epis_abcde_meth eam
                ON eam.id_epis_abcde_meth = eamp.id_epis_abcde_meth
             WHERE eamp.id_epis_abcde_meth = i_id_epis_abcde_meth
               AND eamp.flg_type = 'PO'
               AND eamp.flg_status = 'A';
        EXCEPTION
            WHEN OTHERS THEN
                l_medication_desc_oth := NULL;
        END;
    
        RETURN l_medication_desc_med || l_medication_desc_oth;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              l_func_name,
                                              l_error);
            RETURN '';
    END get_medication_desc;

    /********************************************************************************************
    * Get ABCDE assessment data (AMPLE/SAMPLE/CIAMPEDS) for a given episode
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_get_titles             Return titles in a cursor?
    * @param i_most_recent            Get the most recent (active) record only?
    * @param o_titles                 ABCDE assessment field titles
    * @param o_trauma_hist            ABCDE assessment history
    * @param o_error                  Error message
    *
    * @value i_get_titles             {*} 'Y' Yes {*} 'N' No
    * @value i_most_recent            {*} 'Y' Yes {*} 'N' No - default
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Brito
    * @version                        1.0
    * @since                          2011/01/04
    **********************************************************************************************/
    FUNCTION get_abcde_summary
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_get_titles  IN VARCHAR2,
        i_most_recent IN VARCHAR2 DEFAULT 'N',
        o_titles      OUT pk_types.cursor_type,
        o_trauma_hist OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_ABCDE_SUMMARY';
    BEGIN
    
        IF i_get_titles = pk_alert_constant.g_yes
        THEN
            g_error := 'OPEN O_TITLES (1)';
            pk_alertlog.log_debug(g_error);
            OPEN o_titles FOR
                SELECT pk_message.get_message(i_lang, 'ABCDE_T017') title_allergies,
                       pk_message.get_message(i_lang, 'ABCDE_T018') title_medication,
                       pk_message.get_message(i_lang, 'ABCDE_T019') title_past_medical,
                       pk_message.get_message(i_lang, 'ABCDE_T020') title_last_meal,
                       pk_message.get_message(i_lang, 'ABCDE_T021') title_event,
                       pk_message.get_message(i_lang, 'ABCDE_T023') title_complaint,
                       pk_message.get_message(i_lang, 'ABCDE_T024') title_immunization,
                       pk_message.get_message(i_lang, 'ABCDE_T025') title_parents_impression,
                       pk_message.get_message(i_lang, 'ABCDE_T026') title_diet,
                       pk_message.get_message(i_lang, 'ABCDE_T027') title_diapers,
                       pk_message.get_message(i_lang, 'ABCDE_T022') title_symptoms
                  FROM dual;
        
        ELSE
            g_error := 'OPEN O_TITLES (2)';
            pk_alertlog.log_debug(g_error);
            pk_types.open_my_cursor(o_titles);
        END IF;
    
        g_error := 'GET TRAUMA_HIST INFO';
        OPEN o_trauma_hist FOR
            SELECT eam.id_epis_abcde_meth,
                   eam.flg_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eam.id_prof_create) professional,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, eam.id_prof_create, eam.dt_create, eam.id_episode) spec_prof,
                   pk_date_utils.date_char_tsz(i_lang, eam.dt_create, i_prof.institution, i_prof.software) dt_create,
                   eam.dt_create order_date_created,
                   -- Cancellation
                   decode(eam.id_prof_cancel,
                          NULL,
                          NULL,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, eam.id_prof_cancel)) prof_cancel,
                   decode(eam.id_prof_cancel,
                          NULL,
                          NULL,
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           eam.id_prof_create,
                                                           eam.dt_cancel,
                                                           eam.id_episode)) spec_prof_cancel,
                   decode(eam.id_prof_cancel,
                          NULL,
                          NULL,
                          pk_date_utils.date_char_tsz(i_lang, eam.dt_cancel, i_prof.institution, i_prof.software)) dt_cancel,
                   pk_abcde_methodology.get_allergy_list(i_lang, i_prof, i_id_episode, eam.id_epis_abcde_meth) allergies,
                   get_medication_desc(i_lang, i_prof, eam.id_epis_abcde_meth) medication,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'H'
                       AND eamp.flg_status = 'A') past_medical,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'M'
                       AND eamp.flg_status = 'A') last_meal,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'E'
                       AND eamp.flg_status = 'A') event,
                   pk_utils.concat_table(CAST(MULTISET (SELECT pk_translation.get_translation(i_lang, c.code_complaint)
                                                 FROM epis_abcde_meth_param eamp
                                                 JOIN epis_complaint ec
                                                   ON eamp.id_param = ec.id_epis_complaint
                                                 JOIN complaint c
                                                   ON ec.id_complaint = c.id_complaint
                                                WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                                                  AND eamp.flg_type = 'C'
                                                  AND eamp.flg_status = 'A'
                                                  AND ec.id_episode = eam.id_episode
                                                ORDER BY 1) AS table_varchar),
                                         ', ') chief_complaint,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'I'
                       AND eamp.flg_status = 'A') imunisation,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'PI'
                       AND eamp.flg_status = 'A') parents_impression,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'D'
                       AND eamp.flg_status = 'A') diet,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'DI'
                       AND eamp.flg_status = 'A') diapers,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'S'
                       AND eamp.flg_status = 'A') sympthoms,
                   (SELECT am.flg_meth_type
                      FROM abcde_meth am
                     WHERE am.id_abcde_meth = eam.id_abcde_meth) flg_type,
                   decode((SELECT am.flg_meth_type
                             FROM abcde_meth am
                            WHERE am.id_abcde_meth = eam.id_abcde_meth),
                           'A',
                           pk_message.get_message(i_lang, 'ABCDE_T003'),
                           decode((SELECT am.flg_meth_type
                                    FROM abcde_meth am
                                   WHERE am.id_abcde_meth = eam.id_abcde_meth),
                                  'S',
                                  pk_message.get_message(i_lang, 'ABCDE_T004'),
                                  decode((SELECT am.flg_meth_type
                                           FROM abcde_meth am
                                          WHERE am.id_abcde_meth = eam.id_abcde_meth),
                                         'C',
                                         pk_message.get_message(i_lang, 'ABCDE_T005'),
                                         ''))) || (CASE
                                                       WHEN eam.flg_status IN ('C', 'O') THEN
                                                        ' (' || upper(pk_sysdomain.get_domain('EPIS_ABCDE_METH.FLG_STATUS', eam.flg_status, i_lang)) || ')'
                                                       ELSE
                                                        NULL
                                                   END) desc_type,
                   0 rank
              FROM epis_abcde_meth eam
             WHERE -- Get all records: ACTIVE, CANCELLED and OUTDATED records
             ((eam.flg_status IN ('A', 'C', 'O') AND i_most_recent = pk_alert_constant.g_no) OR
             -- Get only the most recent (ACTIVE) record. It should exist only one active record, so there's no need to sort by date.
              (eam.flg_status = 'A' AND i_most_recent = pk_alert_constant.g_yes))
             AND eam.id_episode = i_id_episode
             ORDER BY order_date_created DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_titles);
            pk_types.open_my_cursor(o_trauma_hist);
            RETURN FALSE;
    END get_abcde_summary;

    /********************************************************************************************
      * Set ABCDE information
      *
      * @param i_lang                       The language ID
      * @param i_prof                       Object (professional ID, institution ID, software ID)
      * @param i_id_episode                 the episode ID
      * @param i_id_epis_abcde_meth         EPIS_ABCDE_METH - NULL if it is a new registry
      * @param i_flg_meth_type              Type of ABCDE registry (A)mple / (S)ample / (C)iampeds
      * @param i_chief_complaint            List of epis_complaint
      * @param i_imunisation                Imunisation information (Free text)
      * @param i_allergies                  List of pat_allergy
    * @param i_allergies_unawareness      Allergie unawareness Id
      * @param i_medication                 List of pat_medication_list
      * @param i_past_medical               Past medical information (Free text)
      * @param i_parents_impression         Parents impression information (Free text)
      * @param i_event                      Event information (Free text)
      * @param i_diet                       Diet information (Free text)
      * @param i_diapers                    Diapers information (Free text)
      * @param i_sympthoms                  Sympthoms information (Free text)
      * @param i_last_meal                  Last meal information (Free text)
      * @param o_id_epis_abcde_meth         Inserted EPIS_ABCDE_METH
      * @param o_id_epis_abcde_meth_param   Inserted EPIS_ABCDE_METH_PARAM
      * @param o_error                      Error message
      *                        
      * @return                             true or false on success or error
      * 
      * @author                             Sérgio Cunha
      * @version                            1.0
      * @since                              2009/07/05
      **********************************************************************************************/
    FUNCTION set_trauma_hist
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth       IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        i_flg_meth_type            IN abcde_meth.flg_meth_type%TYPE,
        i_chief_complaint          IN table_number,
        i_imunisation              IN epis_abcde_meth_param.param_text%TYPE,
        i_allergies                IN table_number,
        i_allergies_unawareness    IN pat_allergy_unawareness.id_allergy_unawareness%TYPE,
        i_medication               IN table_number,
        i_past_medical             IN epis_abcde_meth_param.param_text%TYPE,
        i_parents_impression       IN epis_abcde_meth_param.param_text%TYPE,
        i_event                    IN epis_abcde_meth_param.param_text%TYPE,
        i_diet                     IN epis_abcde_meth_param.param_text%TYPE,
        i_diapers                  IN epis_abcde_meth_param.param_text%TYPE,
        i_sympthoms                IN epis_abcde_meth_param.param_text%TYPE,
        i_last_meal                IN epis_abcde_meth_param.param_text%TYPE,
        o_id_epis_abcde_meth       OUT table_number,
        o_id_epis_abcde_meth_param OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_error EXCEPTION;
    
        l_param_flg_type              epis_abcde_meth_param.flg_type%TYPE;
        l_param_medication_id         epis_abcde_meth_param.id_param%TYPE;
        l_id_patient                  patient.id_patient%TYPE;
        l_id_epis_abcde_meth          epis_abcde_meth.id_epis_abcde_meth%TYPE;
        l_id_epis_abcde_meth_param    epis_abcde_meth_param.id_epis_abcde_meth_param%TYPE;
        l_id_abcde_meth               abcde_meth.id_abcde_meth%TYPE;
        l_rows_out                    table_varchar;
        l_error                       t_error_out;
        epis_abcde_meth_counter       NUMBER := 0;
        epis_abcde_meth_param_counter NUMBER := 0;
        l_pat_allergie_unawareness    pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE;
        l_tab_id_pat_medication_list  table_number;
        l_tab_status                  table_varchar;
        l_info                        pk_types.cursor_type;
        l_id_review                   NUMBER(24, 0);
        l_id_global_info              table_number;
        l_find_id_global_info         NUMBER(6);
    
        CURSOR c_next_epis_abcde_meth IS
            SELECT seq_epis_abcde_meth.nextval
              FROM dual;
    
        CURSOR c_next_epis_abcde_meth_param IS
            SELECT seq_epis_abcde_meth_param.nextval
              FROM dual;
    
        CURSOR c_abcde_meth IS
            SELECT am.id_abcde_meth
              FROM abcde_meth am
             WHERE am.flg_meth_type = i_flg_meth_type
               AND am.flg_available = pk_alert_constant.g_yes;
    
    BEGIN
        o_id_epis_abcde_meth       := table_number();
        o_id_epis_abcde_meth_param := table_number();
    
        g_error := 'GET PATIENT ID';
        pk_alertlog.log_debug(g_error);
        SELECT epis.id_patient
          INTO l_id_patient
          FROM episode epis
         WHERE epis.id_episode = i_id_episode;
    
        g_error := 'GET ABCDE_METH';
        OPEN c_abcde_meth;
        FETCH c_abcde_meth
            INTO l_id_abcde_meth;
        g_found := c_abcde_meth%NOTFOUND;
        CLOSE c_abcde_meth;
    
        IF i_id_epis_abcde_meth IS NULL
        THEN
            -- Get the list of ID's of previous medication. These records will be disabled if applicable.
            l_tab_id_pat_medication_list := pk_api_pfh_clindoc_in.get_abcde_medication_id_list(i_lang       => i_lang,
                                                                                               i_prof       => i_prof,
                                                                                               i_id_patient => l_id_patient);
        
            g_error := 'GET NEXT EPIS_ABCDE_METH';
            OPEN c_next_epis_abcde_meth;
            FETCH c_next_epis_abcde_meth
                INTO l_id_epis_abcde_meth;
            g_found := c_next_epis_abcde_meth%NOTFOUND;
            CLOSE c_next_epis_abcde_meth;
        
            g_error := 'SET PREVIOUS RECORDS AS OUTDATED';
            pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            l_rows_out := table_varchar();
            ts_epis_abcde_meth.upd(flg_status_in  => 'O',
                                   flg_status_nin => FALSE,
                                   where_in       => 'id_episode = ' || i_id_episode || ' AND flg_status <> ''C''',
                                   rows_out       => l_rows_out);
        
            g_error := 'PROCESS_UPDATE EPIS_ABCDE_METH';
            pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_ABCDE_METH',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
        
            g_error := 'INSERT EPIS_ABCDE_METH';
            pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            l_rows_out := table_varchar();
            ts_epis_abcde_meth.ins(id_epis_abcde_meth_in => l_id_epis_abcde_meth,
                                   id_abcde_meth_in      => l_id_abcde_meth,
                                   id_episode_in         => i_id_episode,
                                   flg_status_in         => 'A',
                                   id_prof_create_in     => i_prof.id,
                                   dt_create_in          => current_timestamp,
                                   rows_out              => l_rows_out);
        
            g_error := 'PROCESS_INSERT EPIS_ABCDE_METH';
            pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_ABCDE_METH',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
        
            epis_abcde_meth_counter := epis_abcde_meth_counter + 1;
            o_id_epis_abcde_meth.extend;
            o_id_epis_abcde_meth(epis_abcde_meth_counter) := l_id_epis_abcde_meth;
        
        ELSE
        
            l_id_epis_abcde_meth := i_id_epis_abcde_meth;
        
            -- Get the list of ID's of previous medication. These records will be disabled if applicable.
            BEGIN
                g_error := 'GET LIST OF PREVIOUS MEDICATION (2)';
                pk_alertlog.log_debug(g_error);
                SELECT eamp.id_param
                  BULK COLLECT
                  INTO l_tab_id_pat_medication_list
                  FROM epis_abcde_meth eam
                  JOIN epis_abcde_meth_param eamp
                    ON eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                 WHERE eam.id_epis_abcde_meth = l_id_epis_abcde_meth
                   AND eamp.flg_type = 'P'
                   AND eamp.flg_status = g_flg_active;
            EXCEPTION
                WHEN no_data_found THEN
                    l_tab_id_pat_medication_list := NULL;
            END;
        
            g_error := 'UPDATE EPIS_ABCDE_METH';
            pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            l_rows_out := table_varchar();
            ts_epis_abcde_meth_param.upd(flg_status_in  => 'O',
                                         flg_status_nin => FALSE,
                                         where_in       => 'id_epis_abcde_meth = ' || l_id_epis_abcde_meth,
                                         rows_out       => l_rows_out);
        
            g_error := 'PROCESS_UPDATE EPIS_ABCDE_METH';
            pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_ABCDE_METH_PARAM',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
        END IF;
    
        -- AMPLE / SAMPLE / CIAMPEDS
        IF i_flg_meth_type IN ('A', 'S', 'C')
        THEN
            IF i_allergies.count > 0
            THEN
                FOR i IN i_allergies.first .. i_allergies.last
                LOOP
                    g_error := 'GET NEXT EPIS_ABCDE_METH_PARAM';
                    OPEN c_next_epis_abcde_meth_param;
                    FETCH c_next_epis_abcde_meth_param
                        INTO l_id_epis_abcde_meth_param;
                    g_found := c_next_epis_abcde_meth_param%NOTFOUND;
                    CLOSE c_next_epis_abcde_meth_param;
                
                    g_error := 'INSERT EPIS_ABCDE_METH_PARAM ALLERGIES';
                    pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                    l_rows_out := table_varchar();
                    ts_epis_abcde_meth_param.ins(id_epis_abcde_meth_param_in => l_id_epis_abcde_meth_param,
                                                 id_epis_abcde_meth_in       => l_id_epis_abcde_meth,
                                                 id_param_in                 => i_allergies(i),
                                                 flg_type_in                 => 'A',
                                                 param_text_in               => NULL,
                                                 flg_status_in               => 'A',
                                                 id_prof_create_in           => i_prof.id,
                                                 dt_create_in                => current_timestamp);
                
                    g_error := 'PROCESS_INSERT EPIS_ABCDE_METH';
                    pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_ABCDE_METH_PARAM',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => l_error);
                
                    epis_abcde_meth_param_counter := epis_abcde_meth_param_counter + 1;
                    o_id_epis_abcde_meth_param.extend;
                    o_id_epis_abcde_meth_param(epis_abcde_meth_param_counter) := l_id_epis_abcde_meth_param;
                
                END LOOP;
            END IF;
        
            IF i_allergies_unawareness IS NOT NULL
            THEN
                IF NOT pk_allergy.set_allergy_unawareness_no_com(i_lang            => i_lang,
                                                                 i_prof            => i_prof,
                                                                 i_episode         => i_id_episode,
                                                                 i_patient         => l_id_patient,
                                                                 i_unawareness     => i_allergies_unawareness,
                                                                 i_pat_unawareness => NULL,
                                                                 i_notes           => '',
                                                                 o_pat_unawareness => l_pat_allergie_unawareness,
                                                                 o_error           => l_error)
                
                THEN
                    RAISE l_internal_error;
                ELSE
                    g_error := 'GET NEXT EPIS_ABCDE_METH_PARAM';
                    OPEN c_next_epis_abcde_meth_param;
                    FETCH c_next_epis_abcde_meth_param
                        INTO l_id_epis_abcde_meth_param;
                    g_found := c_next_epis_abcde_meth_param%NOTFOUND;
                    CLOSE c_next_epis_abcde_meth_param;
                
                    l_rows_out := table_varchar();
                
                    g_error := 'INSERT EPIS_ABCDE_METH_PARAM ALLERGIES_UNAWARENESS';
                    pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                    l_rows_out := table_varchar();
                    ts_epis_abcde_meth_param.ins(id_epis_abcde_meth_param_in => l_id_epis_abcde_meth_param,
                                                 id_epis_abcde_meth_in       => l_id_epis_abcde_meth,
                                                 id_param_in                 => l_pat_allergie_unawareness,
                                                 flg_type_in                 => 'AU',
                                                 param_text_in               => NULL,
                                                 flg_status_in               => 'A',
                                                 id_prof_create_in           => i_prof.id,
                                                 dt_create_in                => current_timestamp,
                                                 rows_out                    => l_rows_out);
                
                    --g_error := 'PROCESS_INSERT EPIS_ABCDE_METH';
                    pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_ABCDE_METH_PARAM',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => l_error);
                
                    epis_abcde_meth_param_counter := epis_abcde_meth_param_counter + 1;
                    o_id_epis_abcde_meth_param.extend;
                    o_id_epis_abcde_meth_param(epis_abcde_meth_param_counter) := l_id_epis_abcde_meth_param;
                END IF;
            END IF;
        
            IF i_medication.count > 0
            THEN
            
                -- Get the list of "Home Medication" option ID's
                g_error := 'CALL TO GET_ABCDE_EDITOR_LOOKUP';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_api_pfh_clindoc_in.get_abcde_editor_lookup(i_lang           => i_lang,
                                                                     i_prof           => i_prof,
                                                                     o_id_global_info => l_id_global_info,
                                                                     o_error          => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                FOR i IN i_medication.first .. i_medication.last
                LOOP
                
                    g_error := 'SEARCH ID_GLOBAL_INFO';
                    pk_alertlog.log_debug(g_error);
                    BEGIN
                        SELECT COUNT(*)
                          INTO l_find_id_global_info
                          FROM (SELECT column_value
                                  FROM TABLE(l_id_global_info)) t
                         WHERE t.column_value = i_medication(i);
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_find_id_global_info := 0;
                    END;
                
                    -- Save options "No Home medication" or "Cannot name medication"
                    IF l_find_id_global_info > 0
                    THEN
                        g_error := 'SET MEDICATION PREVIOUS STATE';
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_api_pfh_clindoc_in.set_hm_review_global_info(i_lang       => i_lang,
                                                                               i_prof       => i_prof,
                                                                               i_id_patient => l_id_patient,
                                                                               i_id_episode => i_id_episode,
                                                                               -- ID_GLOBAL_INFO is sent by Flash,
                                                                               -- but the value saved to ABCDE tables
                                                                               -- must be the new ID_REVIEW.
                                                                               io_id_review  => l_id_review, -- ID_REVIEW
                                                                               i_global_info => i_medication(i), -- ID_GLOBAL_INFO
                                                                               --
                                                                               o_info  => l_info,
                                                                               o_error => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    
                        l_param_medication_id := l_id_review;
                        l_param_flg_type      := 'PO';
                    
                    ELSE
                        l_param_medication_id := i_medication(i);
                        l_param_flg_type      := 'P';
                    END IF;
                
                    g_error := 'GET NEXT EPIS_ABCDE_METH_PARAM';
                    OPEN c_next_epis_abcde_meth_param;
                    FETCH c_next_epis_abcde_meth_param
                        INTO l_id_epis_abcde_meth_param;
                    g_found := c_next_epis_abcde_meth_param%NOTFOUND;
                    CLOSE c_next_epis_abcde_meth_param;
                
                    g_error := 'INSERT EPIS_ABCDE_METH_PARAM MEDICATION';
                    pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                    l_rows_out := table_varchar();
                    ts_epis_abcde_meth_param.ins(id_epis_abcde_meth_param_in => l_id_epis_abcde_meth_param,
                                                 id_epis_abcde_meth_in       => l_id_epis_abcde_meth,
                                                 id_param_in                 => l_param_medication_id,
                                                 flg_type_in                 => l_param_flg_type,
                                                 param_text_in               => NULL,
                                                 flg_status_in               => 'A',
                                                 id_prof_create_in           => i_prof.id,
                                                 dt_create_in                => current_timestamp,
                                                 rows_out                    => l_rows_out);
                
                    g_error := 'PROCESS_INSERT EPIS_ABCDE_METH';
                    pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_ABCDE_METH_PARAM',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => l_error);
                
                    epis_abcde_meth_param_counter := epis_abcde_meth_param_counter + 1;
                    o_id_epis_abcde_meth_param.extend;
                    o_id_epis_abcde_meth_param(epis_abcde_meth_param_counter) := l_id_epis_abcde_meth_param;
                END LOOP;
            END IF;
        
            IF i_past_medical IS NOT NULL
            THEN
                g_error := 'GET NEXT EPIS_ABCDE_METH_PARAM';
                OPEN c_next_epis_abcde_meth_param;
                FETCH c_next_epis_abcde_meth_param
                    INTO l_id_epis_abcde_meth_param;
                g_found := c_next_epis_abcde_meth_param%NOTFOUND;
                CLOSE c_next_epis_abcde_meth_param;
            
                g_error := 'INSERT EPIS_ABCDE_METH_PARAM PAST_MEDICATION';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                l_rows_out := table_varchar();
                ts_epis_abcde_meth_param.ins(id_epis_abcde_meth_param_in => l_id_epis_abcde_meth_param,
                                             id_epis_abcde_meth_in       => l_id_epis_abcde_meth,
                                             id_param_in                 => -1,
                                             flg_type_in                 => 'H',
                                             param_text_in               => i_past_medical,
                                             flg_status_in               => 'A',
                                             id_prof_create_in           => i_prof.id,
                                             dt_create_in                => current_timestamp,
                                             rows_out                    => l_rows_out);
            
                g_error := 'PROCESS_INSERT EPIS_ABCDE_METH';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_ABCDE_METH_PARAM',
                                              i_rowids     => l_rows_out,
                                              o_error      => l_error);
            
                epis_abcde_meth_param_counter := epis_abcde_meth_param_counter + 1;
                o_id_epis_abcde_meth_param.extend;
                o_id_epis_abcde_meth_param(epis_abcde_meth_param_counter) := l_id_epis_abcde_meth_param;
            END IF;
        
            IF i_event IS NOT NULL
            THEN
                g_error := 'GET NEXT EPIS_ABCDE_METH_PARAM';
                OPEN c_next_epis_abcde_meth_param;
                FETCH c_next_epis_abcde_meth_param
                    INTO l_id_epis_abcde_meth_param;
                g_found := c_next_epis_abcde_meth_param%NOTFOUND;
                CLOSE c_next_epis_abcde_meth_param;
            
                g_error := 'INSERT EPIS_ABCDE_METH_PARAM EVENT';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                l_rows_out := table_varchar();
                ts_epis_abcde_meth_param.ins(id_epis_abcde_meth_param_in => l_id_epis_abcde_meth_param,
                                             id_epis_abcde_meth_in       => l_id_epis_abcde_meth,
                                             id_param_in                 => -1,
                                             flg_type_in                 => 'E',
                                             param_text_in               => i_event,
                                             flg_status_in               => 'A',
                                             id_prof_create_in           => i_prof.id,
                                             dt_create_in                => current_timestamp,
                                             rows_out                    => l_rows_out);
            
                g_error := 'PROCESS_INSERT EPIS_ABCDE_METH';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_ABCDE_METH_PARAM',
                                              i_rowids     => l_rows_out,
                                              o_error      => l_error);
            
                epis_abcde_meth_param_counter := epis_abcde_meth_param_counter + 1;
                o_id_epis_abcde_meth_param.extend;
                o_id_epis_abcde_meth_param(epis_abcde_meth_param_counter) := l_id_epis_abcde_meth_param;
            END IF;
        END IF;
    
        -- AMPLE / SAMPLE
        IF i_flg_meth_type IN ('A', 'S')
        THEN
            IF i_last_meal IS NOT NULL
            THEN
                g_error := 'GET NEXT EPIS_ABCDE_METH_PARAM';
                OPEN c_next_epis_abcde_meth_param;
                FETCH c_next_epis_abcde_meth_param
                    INTO l_id_epis_abcde_meth_param;
                g_found := c_next_epis_abcde_meth_param%NOTFOUND;
                CLOSE c_next_epis_abcde_meth_param;
            
                g_error := 'INSERT EPIS_ABCDE_METH_PARAM LAST_MEAL';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                l_rows_out := table_varchar();
                ts_epis_abcde_meth_param.ins(id_epis_abcde_meth_param_in => l_id_epis_abcde_meth_param,
                                             id_epis_abcde_meth_in       => l_id_epis_abcde_meth,
                                             id_param_in                 => -1,
                                             flg_type_in                 => 'M',
                                             param_text_in               => i_last_meal,
                                             flg_status_in               => 'A',
                                             id_prof_create_in           => i_prof.id,
                                             dt_create_in                => current_timestamp,
                                             rows_out                    => l_rows_out);
            
                g_error := 'PROCESS_INSERT EPIS_ABCDE_METH';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_ABCDE_METH_PARAM',
                                              i_rowids     => l_rows_out,
                                              o_error      => l_error);
            
                epis_abcde_meth_param_counter := epis_abcde_meth_param_counter + 1;
                o_id_epis_abcde_meth_param.extend;
                o_id_epis_abcde_meth_param(epis_abcde_meth_param_counter) := l_id_epis_abcde_meth_param;
            END IF;
        END IF;
    
        -- SAMPLE / CIAMPEDS
        IF i_flg_meth_type IN ('S', 'C')
        THEN
            IF i_sympthoms IS NOT NULL
            THEN
                g_error := 'GET NEXT EPIS_ABCDE_METH_PARAM';
                OPEN c_next_epis_abcde_meth_param;
                FETCH c_next_epis_abcde_meth_param
                    INTO l_id_epis_abcde_meth_param;
                g_found := c_next_epis_abcde_meth_param%NOTFOUND;
                CLOSE c_next_epis_abcde_meth_param;
            
                g_error := 'INSERT EPIS_ABCDE_METH_PARAM LAST_MEAL';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                l_rows_out := table_varchar();
                ts_epis_abcde_meth_param.ins(id_epis_abcde_meth_param_in => l_id_epis_abcde_meth_param,
                                             id_epis_abcde_meth_in       => l_id_epis_abcde_meth,
                                             id_param_in                 => -1,
                                             flg_type_in                 => 'S',
                                             param_text_in               => i_sympthoms,
                                             flg_status_in               => 'A',
                                             id_prof_create_in           => i_prof.id,
                                             dt_create_in                => current_timestamp,
                                             rows_out                    => l_rows_out);
            
                g_error := 'PROCESS_INSERT EPIS_ABCDE_METH';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_ABCDE_METH_PARAM',
                                              i_rowids     => l_rows_out,
                                              o_error      => l_error);
            
                epis_abcde_meth_param_counter := epis_abcde_meth_param_counter + 1;
                o_id_epis_abcde_meth_param.extend;
                o_id_epis_abcde_meth_param(epis_abcde_meth_param_counter) := l_id_epis_abcde_meth_param;
            
            END IF;
        END IF;
    
        -- CIAMPEDS
        IF i_flg_meth_type = 'C'
        THEN
            IF i_chief_complaint.count > 0
            THEN
                FOR i IN i_chief_complaint.first .. i_chief_complaint.last
                LOOP
                    g_error := 'GET NEXT EPIS_ABCDE_METH_PARAM';
                    OPEN c_next_epis_abcde_meth_param;
                    FETCH c_next_epis_abcde_meth_param
                        INTO l_id_epis_abcde_meth_param;
                    g_found := c_next_epis_abcde_meth_param%NOTFOUND;
                    CLOSE c_next_epis_abcde_meth_param;
                
                    g_error := 'INSERT EPIS_ABCDE_METH_PARAM CHIEF_COMPLAINT';
                    pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                    l_rows_out := table_varchar();
                    ts_epis_abcde_meth_param.ins(id_epis_abcde_meth_param_in => l_id_epis_abcde_meth_param,
                                                 id_epis_abcde_meth_in       => l_id_epis_abcde_meth,
                                                 id_param_in                 => i_chief_complaint(i),
                                                 flg_type_in                 => 'C',
                                                 param_text_in               => NULL,
                                                 flg_status_in               => 'A',
                                                 id_prof_create_in           => i_prof.id,
                                                 dt_create_in                => current_timestamp,
                                                 rows_out                    => l_rows_out);
                
                    g_error := 'PROCESS_INSERT EPIS_ABCDE_METH';
                    pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_ABCDE_METH_PARAM',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => l_error);
                
                    epis_abcde_meth_param_counter := epis_abcde_meth_param_counter + 1;
                    o_id_epis_abcde_meth_param.extend;
                    o_id_epis_abcde_meth_param(epis_abcde_meth_param_counter) := l_id_epis_abcde_meth_param;
                END LOOP;
            END IF;
        
            IF i_imunisation IS NOT NULL
            THEN
                g_error := 'GET NEXT EPIS_ABCDE_METH_PARAM';
                OPEN c_next_epis_abcde_meth_param;
                FETCH c_next_epis_abcde_meth_param
                    INTO l_id_epis_abcde_meth_param;
                g_found := c_next_epis_abcde_meth_param%NOTFOUND;
                CLOSE c_next_epis_abcde_meth_param;
            
                g_error := 'INSERT EPIS_ABCDE_METH_PARAM IMUNISATION';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                l_rows_out := table_varchar();
                ts_epis_abcde_meth_param.ins(id_epis_abcde_meth_param_in => l_id_epis_abcde_meth_param,
                                             id_epis_abcde_meth_in       => l_id_epis_abcde_meth,
                                             id_param_in                 => -1,
                                             flg_type_in                 => 'I',
                                             param_text_in               => i_imunisation,
                                             flg_status_in               => 'A',
                                             id_prof_create_in           => i_prof.id,
                                             dt_create_in                => current_timestamp,
                                             rows_out                    => l_rows_out);
            
                g_error := 'PROCESS_INSERT EPIS_ABCDE_METH';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_ABCDE_METH_PARAM',
                                              i_rowids     => l_rows_out,
                                              o_error      => l_error);
            
                epis_abcde_meth_param_counter := epis_abcde_meth_param_counter + 1;
                o_id_epis_abcde_meth_param.extend;
                o_id_epis_abcde_meth_param(epis_abcde_meth_param_counter) := l_id_epis_abcde_meth_param;
            END IF;
        
            IF i_parents_impression IS NOT NULL
            THEN
                g_error := 'GET NEXT EPIS_ABCDE_METH_PARAM';
                OPEN c_next_epis_abcde_meth_param;
                FETCH c_next_epis_abcde_meth_param
                    INTO l_id_epis_abcde_meth_param;
                g_found := c_next_epis_abcde_meth_param%NOTFOUND;
                CLOSE c_next_epis_abcde_meth_param;
            
                g_error := 'INSERT EPIS_ABCDE_METH_PARAM PARENTS_IMPRESSION';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                l_rows_out := table_varchar();
                ts_epis_abcde_meth_param.ins(id_epis_abcde_meth_param_in => l_id_epis_abcde_meth_param,
                                             id_epis_abcde_meth_in       => l_id_epis_abcde_meth,
                                             id_param_in                 => -1,
                                             flg_type_in                 => 'PI',
                                             param_text_in               => i_parents_impression,
                                             flg_status_in               => 'A',
                                             id_prof_create_in           => i_prof.id,
                                             dt_create_in                => current_timestamp,
                                             rows_out                    => l_rows_out);
            
                g_error := 'PROCESS_INSERT EPIS_ABCDE_METH';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_ABCDE_METH_PARAM',
                                              i_rowids     => l_rows_out,
                                              o_error      => l_error);
            
                epis_abcde_meth_param_counter := epis_abcde_meth_param_counter + 1;
                o_id_epis_abcde_meth_param.extend;
                o_id_epis_abcde_meth_param(epis_abcde_meth_param_counter) := l_id_epis_abcde_meth_param;
            END IF;
        
            IF i_diet IS NOT NULL
            THEN
                g_error := 'GET NEXT EPIS_ABCDE_METH_PARAM';
                OPEN c_next_epis_abcde_meth_param;
                FETCH c_next_epis_abcde_meth_param
                    INTO l_id_epis_abcde_meth_param;
                g_found := c_next_epis_abcde_meth_param%NOTFOUND;
                CLOSE c_next_epis_abcde_meth_param;
            
                g_error := 'INSERT EPIS_ABCDE_METH_PARAM PARENTS_IMPRESSION';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                l_rows_out := table_varchar();
                ts_epis_abcde_meth_param.ins(id_epis_abcde_meth_param_in => l_id_epis_abcde_meth_param,
                                             id_epis_abcde_meth_in       => l_id_epis_abcde_meth,
                                             id_param_in                 => -1,
                                             flg_type_in                 => 'D',
                                             param_text_in               => i_diet,
                                             flg_status_in               => 'A',
                                             id_prof_create_in           => i_prof.id,
                                             dt_create_in                => current_timestamp,
                                             rows_out                    => l_rows_out);
            
                g_error := 'PROCESS_INSERT EPIS_ABCDE_METH';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_ABCDE_METH_PARAM',
                                              i_rowids     => l_rows_out,
                                              o_error      => l_error);
            
                epis_abcde_meth_param_counter := epis_abcde_meth_param_counter + 1;
                o_id_epis_abcde_meth_param.extend;
                o_id_epis_abcde_meth_param(epis_abcde_meth_param_counter) := l_id_epis_abcde_meth_param;
            END IF;
        
            IF i_diapers IS NOT NULL
            THEN
                g_error := 'GET NEXT EPIS_ABCDE_METH_PARAM';
                OPEN c_next_epis_abcde_meth_param;
                FETCH c_next_epis_abcde_meth_param
                    INTO l_id_epis_abcde_meth_param;
                g_found := c_next_epis_abcde_meth_param%NOTFOUND;
                CLOSE c_next_epis_abcde_meth_param;
            
                g_error := 'INSERT EPIS_ABCDE_METH_PARAM PARENTS_IMPRESSION';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
                l_rows_out := table_varchar();
                ts_epis_abcde_meth_param.ins(id_epis_abcde_meth_param_in => l_id_epis_abcde_meth_param,
                                             id_epis_abcde_meth_in       => l_id_epis_abcde_meth,
                                             id_param_in                 => -1,
                                             flg_type_in                 => 'DI',
                                             param_text_in               => i_diapers,
                                             flg_status_in               => 'A',
                                             id_prof_create_in           => i_prof.id,
                                             dt_create_in                => current_timestamp,
                                             rows_out                    => l_rows_out);
            
                g_error := 'PROCESS_INSERT EPIS_ABCDE_METH';
                pk_alertlog.log_debug('PK_ABCDE_METHODOLOGY.SET_TRAUMA_HIST ' || g_error);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_ABCDE_METH_PARAM',
                                              i_rowids     => l_rows_out,
                                              o_error      => l_error);
            
                epis_abcde_meth_param_counter := epis_abcde_meth_param_counter + 1;
                o_id_epis_abcde_meth_param.extend;
                o_id_epis_abcde_meth_param(epis_abcde_meth_param_counter) := l_id_epis_abcde_meth_param;
            END IF;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'SET_TRAUMA_HIST',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'SET_TRAUMA_HIST',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_trauma_hist;

    /********************************************************************************************
    * Cancel ABCDE assessment (AMPLE/SAMPLE/CIAMPEDS).
    *
    * @param   i_lang                 Language ID
    * @param   i_prof                 Professional info
    * @param   i_id_episode           Episode ID
    * @param   i_id_patient           Patient ID
    * @param   i_id_epis_abcde_meth   ABCDE assessment ID
    * @param   i_tab_task             Associated tasks ID (allergies, reported medication)
    * @param   i_tab_type             Associated tasks type: (A) Allergies (P) Reported medication - prescription
    * @param   i_id_cancel_reason     Cancel reason ID
    * @param   i_cancel_reason        Cancel reason (free text)
    * @param   i_cancel_notes         Cancellation notes
    * @param   o_error                error message
    *                        
    * @return  TRUE if successfull, FALSE otherwise
    * 
    * @author                         José Brito
    * @version                        2.6.0
    * @since                          15-03-2010
    **********************************************************************************************/
    FUNCTION cancel_trauma_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        i_tab_task           IN table_number,
        i_tab_type           IN table_varchar,
        i_id_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes       IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'CANCEL_TRAUMA_HIST';
    
        l_cancel_tasks VARCHAR2(1 CHAR) := 'N';
        l_flg_status   VARCHAR2(1 CHAR);
    
        l_tab_pat_med_list table_number := table_number();
        l_tab_dummy_num    table_number := table_number();
        l_tab_dummy_chr    table_varchar := table_varchar();
        l_counter_pml      NUMBER(6) := 0;
        l_counter_pmd      NUMBER(6) := 0;
        l_flg_med_check    VARCHAR2(1 CHAR);
    
        l_dummy_str VARCHAR2(200 CHAR);
    
        l_rowids    table_varchar;
        l_error_msg VARCHAR2(200 CHAR);
        l_param_error    EXCEPTION;
        l_internal_error EXCEPTION;
    
    BEGIN
        g_error := 'VALIDATE PARAMETERS';
        IF i_tab_task.exists(1)
        THEN
            IF i_tab_task.count <> i_tab_type.count
            THEN
                l_error_msg := 'INVALID ARRAY SIZE';
                RAISE l_param_error;
            ELSIF i_tab_task.count > 0
            THEN
                l_cancel_tasks := 'Y';
            END IF;
        
        ELSIF i_id_epis_abcde_meth IS NULL
        THEN
            l_error_msg := 'NULL VALUE FOUND (EVALUATION ID)';
            RAISE l_param_error;
        END IF;
    
        g_error := 'CANCEL ABCDE EVALUATION';
        pk_alertlog.log_debug(g_error);
        ts_epis_abcde_meth.upd(id_epis_abcde_meth_in => i_id_epis_abcde_meth,
                               flg_status_in         => 'C',
                               id_prof_cancel_in     => i_prof.id,
                               dt_cancel_in          => current_timestamp,
                               id_cancel_reason_in   => i_id_cancel_reason,
                               notes_cancel_in       => i_cancel_notes,
                               rows_out              => l_rowids);
    
        IF l_cancel_tasks = 'Y'
        THEN
            FOR i IN i_tab_task.first .. i_tab_task.last
            LOOP
                IF i_tab_type(i) = 'P'
                THEN
                    g_error := 'GET STATUS - REP. MEDICATION';
                    pk_alertlog.log_debug(g_error);
                    l_flg_med_check := pk_api_pfh_clindoc_in.check_abcde_medication_flg(i_lang,
                                                                                        i_prof,
                                                                                        i_tab_task(i),
                                                                                        NULL);
                
                    IF l_flg_med_check = pk_alert_constant.g_yes
                    THEN
                        -- Build arrays to cancel reported medication
                        g_error := 'BUILD ARRAYS - REP. MEDICATION';
                        pk_alertlog.log_debug(g_error);
                        l_counter_pml := l_counter_pml + 1;
                        l_tab_pat_med_list.extend;
                        l_tab_pat_med_list(l_counter_pml) := i_tab_task(i);
                        l_tab_dummy_num.extend;
                        l_tab_dummy_num(l_counter_pml) := NULL;
                        l_tab_dummy_chr.extend;
                        l_tab_dummy_chr(l_counter_pml) := NULL;
                    END IF;
                
                ELSIF i_tab_type(i) = 'PO'
                THEN
                    g_error := 'GET STATUS - REP. MEDICATION (2)';
                    pk_alertlog.log_debug(g_error);
                    l_flg_med_check := pk_api_pfh_clindoc_in.check_abcde_medication_flg(i_lang,
                                                                                        i_prof,
                                                                                        NULL,
                                                                                        i_tab_task(i));
                
                    IF l_flg_med_check = pk_alert_constant.g_yes
                    THEN
                        -- Changes are only required if one of the parameters is 'Yes'.
                        l_counter_pmd := l_counter_pmd + 1;
                    END IF;
                ELSIF i_tab_type(i) = 'AU'
                THEN
                    g_error := 'CANCEL ALLERGIES_UNAWARENESS';
                    pk_alertlog.log_debug(g_error);
                
                    IF NOT pk_allergy.cancel_unawareness(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_unawareness   => i_tab_task(i),
                                                         i_id_cancel_reason => i_id_cancel_reason,
                                                         i_cancel_notes     => i_cancel_notes,
                                                         o_error            => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                
                ELSIF i_tab_type(i) = 'A'
                THEN
                    g_error := 'GET STATUS - ALLERGY';
                    pk_alertlog.log_debug(g_error);
                    SELECT pa.flg_status
                      INTO l_flg_status
                      FROM pat_allergy pa
                     WHERE pa.id_pat_allergy = i_tab_task(i);
                
                    IF l_flg_status <> 'C' -- Do not cancel tasks that are already cancelled.
                    THEN
                        g_error := 'CANCEL ALLERGIES';
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_allergy.call_cancel_allergy(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_id_pat_allergy   => i_tab_task(i),
                                                              i_id_cancel_reason => i_id_cancel_reason,
                                                              i_cancel_notes     => i_cancel_notes,
                                                              o_error            => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        
            IF l_counter_pml > 0
               OR l_counter_pmd > 0
            THEN
                g_error := 'CANCEL REPORTED MEDICATION';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_api_pfh_clindoc_in.call_cancel_rep_medication(i_lang      => i_lang,
                                                                        i_prof      => i_prof,
                                                                        i_id_presc  => l_tab_pat_med_list,
                                                                        i_id_reason => i_id_cancel_reason,
                                                                        i_reason    => NULL,
                                                                        i_notes     => i_cancel_notes,
                                                                        o_error     => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        END IF;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_ABCDE_METH',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM_ERROR',
                                              l_error_msg,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_trauma_hist;

    /********************************************************************************************
    * Return registered allergies and reported medication 
    *
    * @param   i_lang                 Language ID
    * @param   i_prof                 Professional info
    * @param   i_id_episode           Episode ID
    * @param   i_id_patient           Patient ID
    * @param   i_id_epis_abcde_meth   ABCDE assessment ID
    * @param   o_allergies            Allergies data
    * @param   o_medication           Reported medication data
    * @param   o_error                Error message
    *                        
    * @return  TRUE if successfull, FALSE otherwise
    * 
    * @author                         José Brito
    * @version                        2.6.0
    * @since                          15-03-2010
    **********************************************************************************************/
    FUNCTION get_trauma_hist_by_id
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth    IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        o_allergies_unawareness OUT pk_types.cursor_type,
        o_allergies             OUT pk_types.cursor_type,
        o_medication            OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    
        l_func_name VARCHAR2(200) := 'GET_TRAUMA_HIST_BY_ID';
        l_with_notes CONSTANT sys_message.desc_message%TYPE := '(' ||
                                                               lower(pk_message.get_message(i_lang      => i_lang,
                                                                                            i_code_mess => 'COMMON_M008')) || ')';
    BEGIN
    
        g_error := 'GET ALLERGIES_UNAWARENESS';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_allergies_unawareness FOR
            SELECT eamh.id_epis_abcde_meth,
                   eamh.flg_type,
                   eamh.flg_status,
                   eamh.id_param id_task,
                   pk_translation.get_translation(i_lang,
                                                  'ALLERGY_UNAWARENESS.CODE_ALLERGY_UNAWARENESS.' ||
                                                  to_char(pau.id_allergy_unawareness)) desc_allergy
              FROM epis_abcde_meth_param eamh
              JOIN pat_allergy_unawareness pau
                ON (pau.id_pat_allergy_unawareness = eamh.id_param)
            
             WHERE eamh.id_epis_abcde_meth = i_id_epis_abcde_meth
               AND pau.id_episode IN (SELECT DISTINCT eam.id_episode
                                        FROM epis_abcde_meth eam
                                       WHERE eam.id_episode = i_id_episode)
               AND eamh.flg_type = 'AU' -- Allergies unawareness
               AND eamh.flg_status = 'A';
    
        g_error := 'GET ALLERGIES';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_allergies FOR
            SELECT eam.id_epis_abcde_meth, -- Data for cancellation method
                   pa.id_pat_allergy id_task,
                   eamh.flg_type,
                   -- Data to display in the modal window
                   decode(pa.id_allergy,
                          NULL,
                          pa.desc_allergy,
                          (SELECT pk_translation.get_translation(i_lang, a.code_allergy)
                             FROM allergy a
                            WHERE a.id_allergy = pa.id_allergy)) allergen,
                   pk_date_utils.date_char_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof.institution, i_prof.software) dt_pat_allergy,
                   pk_sysdomain.get_domain(pk_allergy.g_pat_allergy_type, pa.flg_type, i_lang) type_reaction,
                   pa.year_begin onset,
                   pa.flg_status,
                   pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS', pa.flg_status, i_lang) status,
                   pk_allergy.get_status_string(pa.flg_status,
                                                pk_sysdomain.get_domain(pk_allergy.g_pat_allergy_status,
                                                                        pa.flg_status,
                                                                        i_lang)) status_string,
                   pk_allergy.get_status_color(pa.flg_status) status_color,
                   decode(pa.notes, NULL, NULL, l_with_notes) with_notes,
                   decode(pa.cancel_notes, NULL, NULL, l_with_notes) cancelled_with_notes
              FROM epis_abcde_meth eam
              JOIN epis_abcde_meth_param eamh
                ON eamh.id_epis_abcde_meth = eam.id_epis_abcde_meth
              JOIN pat_allergy pa
                ON pa.id_pat_allergy = eamh.id_param
             WHERE eam.id_epis_abcde_meth = i_id_epis_abcde_meth
               AND eam.id_episode = i_id_episode
               AND eamh.flg_type = 'A' -- Allergies
               AND eamh.flg_status = 'A'
               AND pa.flg_status <> 'C' -- Do not show records that are already cancelled.
             ORDER BY pa.dt_pat_allergy_tstz;
    
        g_error := 'GET MEDICATION';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_api_pfh_clindoc_in.get_trauma_hist_medic_by_id(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_id_episode         => i_id_episode,
                                                                 i_id_epis_abcde_meth => i_id_epis_abcde_meth,
                                                                 o_medication         => o_medication,
                                                                 o_error              => o_error)
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
                                              'PK_ABCDE_METHODOLOGY',
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_allergies);
            pk_types.open_my_cursor(o_medication);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_allergies);
            pk_types.open_my_cursor(o_medication);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_trauma_hist_by_id;

    /********************************************************************************************
    * Return all data registered in a given ABCDE assessment.
    *
    * @param   i_lang                 Language ID
    * @param   i_prof                 Professional info
    * @param   i_id_episode           Episode ID
    * @param   i_id_epis_abcde_meth   ABCDE assessment ID
    * @param   o_trauma_detail        Assessment data
    * @param   o_error                Error message
    *                        
    * @return  TRUE if successfull, FALSE otherwise
    * 
    * @author                         José Brito
    * @version                        2.6.0
    * @since                          15-03-2010
    **********************************************************************************************/
    FUNCTION get_trauma_hist_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        o_trauma_detail      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_TRAUMA_HIST_DETAIL';
    
        l_flg_meth_type abcde_meth.flg_meth_type%TYPE;
    
        l_ample    CONSTANT VARCHAR2(1 CHAR) := 'A';
        l_sample   CONSTANT VARCHAR2(1 CHAR) := 'S';
        l_ciampeds CONSTANT VARCHAR2(1 CHAR) := 'C';
    
        l_value_error EXCEPTION;
    BEGIN
    
        g_error := 'GET ABCDE ASSESSMENT TYPE';
        pk_alertlog.log_debug(g_error);
        SELECT am.flg_meth_type
          INTO l_flg_meth_type
          FROM epis_abcde_meth e
          JOIN abcde_meth am
            ON am.id_abcde_meth = e.id_abcde_meth
         WHERE e.id_epis_abcde_meth = i_id_epis_abcde_meth;
    
        IF l_flg_meth_type = l_ample
        THEN
            g_error := 'GET AMPLE DETAIL';
            pk_alertlog.log_debug(g_error);
            OPEN o_trauma_detail FOR
                SELECT am.flg_meth_type,
                       eam.flg_status,
                       -- Creation data
                       pk_prof_utils.get_name_signature(i_lang, i_prof, eam.id_prof_create) professional,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        eam.id_prof_create,
                                                        eam.dt_create,
                                                        eam.id_episode) spec_prof,
                       pk_date_utils.date_char_tsz(i_lang, eam.dt_create, i_prof.institution, i_prof.software) dt_create,
                       -- Cancellation data
                       decode(eam.id_prof_cancel,
                              NULL,
                              NULL,
                              pk_prof_utils.get_name_signature(i_lang, i_prof, eam.id_prof_cancel)) prof_cancel,
                       decode(eam.id_prof_cancel,
                              NULL,
                              NULL,
                              pk_prof_utils.get_spec_signature(i_lang,
                                                               i_prof,
                                                               eam.id_prof_create,
                                                               eam.dt_cancel,
                                                               eam.id_episode)) spec_prof_cancel,
                       decode(eam.id_prof_cancel,
                              NULL,
                              NULL,
                              pk_date_utils.date_char_tsz(i_lang, eam.dt_cancel, i_prof.institution, i_prof.software)) dt_cancel,
                       (SELECT pk_message.get_message(i_lang, 'COMMON_M072')
                          FROM dual) title_cancel_reason,
                       decode(eam.id_prof_cancel,
                              NULL,
                              NULL,
                              pk_translation.get_translation(i_lang,
                                                             'CANCEL_REASON.CODE_CANCEL_REASON.' || eam.id_cancel_reason)) cancel_reason,
                       (SELECT pk_message.get_message(i_lang, 'COMMON_M073')
                          FROM dual) title_cancel_notes,
                       decode(eam.id_prof_cancel, NULL, NULL, eam.notes_cancel) cancel_notes,
                       -- ASSESSMENT TITLE --
                       pk_translation.get_translation(i_lang, am.code_abcde_meth) ||
                       decode(eam.flg_status,
                              'A',
                              NULL,
                              ' (' ||
                              upper(pk_sysdomain.get_domain('EPIS_ABCDE_METH.FLG_STATUS', eam.flg_status, i_lang)) || ')') title_assessment,
                       -- Allergies
                       pk_message.get_message(i_lang, 'ABCDE_T006') title_allergies,
                       get_allergy_list(i_lang, i_prof, i_id_episode, eam.id_epis_abcde_meth) desc_allergies,
                       -- Reported medication
                       pk_message.get_message(i_lang, 'ABCDE_T007') title_medication,
                       get_medication_desc(i_lang, i_prof, eam.id_epis_abcde_meth) desc_medication,
                       -- Past medical
                       pk_message.get_message(i_lang, 'ABCDE_T008') title_past_medical,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'H'
                           AND eamp.flg_status = 'A') desc_past_medical,
                       -- Last meal
                       pk_message.get_message(i_lang, 'ABCDE_T009') title_last_meal,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'M'
                           AND eamp.flg_status = 'A') desc_last_meal,
                       -- Event
                       pk_message.get_message(i_lang, 'ABCDE_T010') title_event,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'E'
                           AND eamp.flg_status = 'A') desc_event
                  FROM epis_abcde_meth eam
                  JOIN abcde_meth am
                    ON am.id_abcde_meth = eam.id_abcde_meth
                 WHERE eam.id_epis_abcde_meth = i_id_epis_abcde_meth;
        
        ELSIF l_flg_meth_type = l_sample
        THEN
            g_error := 'GET SAMPLE DETAIL';
            pk_alertlog.log_debug(g_error);
            OPEN o_trauma_detail FOR
                SELECT am.flg_meth_type,
                       eam.flg_status,
                       -- Creation data
                       pk_prof_utils.get_name_signature(i_lang, i_prof, eam.id_prof_create) professional, -- Creation data
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        eam.id_prof_create,
                                                        eam.dt_create,
                                                        eam.id_episode) spec_prof,
                       pk_date_utils.date_char_tsz(i_lang, eam.dt_create, i_prof.institution, i_prof.software) dt_create,
                       -- Cancellation data
                       decode(eam.id_prof_cancel,
                              NULL,
                              NULL,
                              pk_prof_utils.get_name_signature(i_lang, i_prof, eam.id_prof_cancel)) prof_cancel,
                       decode(eam.id_prof_cancel,
                              NULL,
                              NULL,
                              pk_prof_utils.get_spec_signature(i_lang,
                                                               i_prof,
                                                               eam.id_prof_create,
                                                               eam.dt_cancel,
                                                               eam.id_episode)) spec_prof_cancel,
                       decode(eam.id_prof_cancel,
                              NULL,
                              NULL,
                              pk_date_utils.date_char_tsz(i_lang, eam.dt_cancel, i_prof.institution, i_prof.software)) dt_cancel,
                       (SELECT pk_message.get_message(i_lang, 'COMMON_M072')
                          FROM dual) title_cancel_reason,
                       decode(eam.id_prof_cancel,
                              NULL,
                              NULL,
                              pk_translation.get_translation(i_lang,
                                                             'CANCEL_REASON.CODE_CANCEL_REASON.' || eam.id_cancel_reason)) cancel_reason,
                       (SELECT pk_message.get_message(i_lang, 'COMMON_M073')
                          FROM dual) title_cancel_notes,
                       decode(eam.id_prof_cancel, NULL, NULL, eam.notes_cancel) cancel_notes,
                       -- ASSESSMENT TITLE --
                       pk_translation.get_translation(i_lang, am.code_abcde_meth) ||
                       decode(eam.flg_status,
                              'A',
                              NULL,
                              ' (' ||
                              upper(pk_sysdomain.get_domain('EPIS_ABCDE_METH.FLG_STATUS', eam.flg_status, i_lang)) || ')') title_assessment,
                       -- Symptoms
                       pk_message.get_message(i_lang, 'ABCDE_T011') title_symptoms,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'S'
                           AND eamp.flg_status = 'A') desc_symptoms,
                       -- Allergies
                       pk_message.get_message(i_lang, 'ABCDE_T006') title_allergies,
                       get_allergy_list(i_lang, i_prof, i_id_episode, eam.id_epis_abcde_meth) desc_allergies,
                       -- Reported medication
                       pk_message.get_message(i_lang, 'ABCDE_T007') title_medication,
                       get_medication_desc(i_lang, i_prof, eam.id_epis_abcde_meth) desc_medication,
                       -- Past medical
                       pk_message.get_message(i_lang, 'ABCDE_T008') title_past_medical,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'H'
                           AND eamp.flg_status = 'A') desc_past_medical,
                       -- Last meal
                       pk_message.get_message(i_lang, 'ABCDE_T009') title_last_meal,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'M'
                           AND eamp.flg_status = 'A') desc_last_meal,
                       -- Event
                       pk_message.get_message(i_lang, 'ABCDE_T010') title_event,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'E'
                           AND eamp.flg_status = 'A') desc_event
                  FROM epis_abcde_meth eam
                  JOIN abcde_meth am
                    ON am.id_abcde_meth = eam.id_abcde_meth
                 WHERE eam.id_epis_abcde_meth = i_id_epis_abcde_meth;
        
        ELSIF l_flg_meth_type = l_ciampeds
        THEN
            g_error := 'GET CIAMPEDS DETAIL';
            pk_alertlog.log_debug(g_error);
            OPEN o_trauma_detail FOR
                SELECT am.flg_meth_type,
                       eam.flg_status,
                       -- Creation data
                       pk_prof_utils.get_name_signature(i_lang, i_prof, eam.id_prof_create) professional, -- Creation data
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        eam.id_prof_create,
                                                        eam.dt_create,
                                                        eam.id_episode) spec_prof,
                       pk_date_utils.date_char_tsz(i_lang, eam.dt_create, i_prof.institution, i_prof.software) dt_create,
                       -- Cancellation data
                       decode(eam.id_prof_cancel,
                              NULL,
                              NULL,
                              pk_prof_utils.get_name_signature(i_lang, i_prof, eam.id_prof_cancel)) prof_cancel,
                       decode(eam.id_prof_cancel,
                              NULL,
                              NULL,
                              pk_prof_utils.get_spec_signature(i_lang,
                                                               i_prof,
                                                               eam.id_prof_create,
                                                               eam.dt_cancel,
                                                               eam.id_episode)) spec_prof_cancel,
                       decode(eam.id_prof_cancel,
                              NULL,
                              NULL,
                              pk_date_utils.date_char_tsz(i_lang, eam.dt_cancel, i_prof.institution, i_prof.software)) dt_cancel,
                       (SELECT pk_message.get_message(i_lang, 'COMMON_M072')
                          FROM dual) title_cancel_reason,
                       decode(eam.id_prof_cancel,
                              NULL,
                              NULL,
                              pk_translation.get_translation(i_lang,
                                                             'CANCEL_REASON.CODE_CANCEL_REASON.' || eam.id_cancel_reason)) cancel_reason,
                       (SELECT pk_message.get_message(i_lang, 'COMMON_M073')
                          FROM dual) title_cancel_notes,
                       decode(eam.id_prof_cancel, NULL, NULL, eam.notes_cancel) cancel_notes,
                       -- ASSESSMENT TITLE --
                       pk_translation.get_translation(i_lang, am.code_abcde_meth) ||
                       decode(eam.flg_status,
                              'A',
                              NULL,
                              ' (' ||
                              upper(pk_sysdomain.get_domain('EPIS_ABCDE_METH.FLG_STATUS', eam.flg_status, i_lang)) || ')') title_assessment,
                       -- Complaint
                       pk_message.get_message(i_lang, 'ABCDE_T012') title_complaint,
                       pk_utils.concatenate_list(CURSOR (SELECT pk_translation.get_translation(i_lang, c.code_complaint)
                                                    FROM epis_abcde_meth_param eamp
                                                    JOIN epis_complaint ec
                                                      ON eamp.id_param = ec.id_epis_complaint
                                                    JOIN complaint c
                                                      ON ec.id_complaint = c.id_complaint
                                                   WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                                                     AND eamp.flg_type = 'C'
                                                     AND eamp.flg_status = 'A'
                                                     AND ec.id_episode = eam.id_episode
                                                   ORDER BY 1),
                                                 ', ') desc_complaint,
                       -- Immunization
                       pk_message.get_message(i_lang, 'ABCDE_T013') title_immunization,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'I'
                           AND eamp.flg_status = 'A') desc_immunization,
                       -- Allergies
                       pk_message.get_message(i_lang, 'ABCDE_T006') title_allergies,
                       get_allergy_list(i_lang, i_prof, i_id_episode, eam.id_epis_abcde_meth) desc_allergies,
                       -- Reported medication
                       pk_message.get_message(i_lang, 'ABCDE_T007') title_medication,
                       get_medication_desc(i_lang, i_prof, eam.id_epis_abcde_meth) desc_medication,
                       -- Past medical
                       pk_message.get_message(i_lang, 'ABCDE_T008') title_past_medical,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'H'
                           AND eamp.flg_status = 'A') desc_past_medical,
                       -- Parent's impreesion
                       pk_message.get_message(i_lang, 'ABCDE_T014') title_parents_impression,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'PI'
                           AND eamp.flg_status = 'A') desc_parents_impression,
                       -- Event
                       pk_message.get_message(i_lang, 'ABCDE_T010') title_event,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'E'
                           AND eamp.flg_status = 'A') desc_event,
                       -- Diet
                       pk_message.get_message(i_lang, 'ABCDE_T015') title_diet,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'D'
                           AND eamp.flg_status = 'A') desc_diet,
                       -- Diapers
                       pk_message.get_message(i_lang, 'ABCDE_T016') title_diapers,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'DI'
                           AND eamp.flg_status = 'A') desc_diapers,
                       -- Symptoms
                       pk_message.get_message(i_lang, 'ABCDE_T011') title_symptoms,
                       (SELECT eamp.param_text
                          FROM epis_abcde_meth_param eamp
                         WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                           AND eamp.flg_type = 'S'
                           AND eamp.flg_status = 'A') desc_symptoms
                  FROM epis_abcde_meth eam
                  JOIN abcde_meth am
                    ON am.id_abcde_meth = eam.id_abcde_meth
                 WHERE eam.id_epis_abcde_meth = i_id_epis_abcde_meth;
        
        ELSE
            g_error := 'UNDEFINED ASSESSMENT TYPE: (' || l_flg_meth_type || ')';
            pk_alertlog.log_debug(g_error);
            RAISE l_value_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_value_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'VALUE ERROR',
                                              g_error,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_trauma_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_trauma_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_trauma_hist_detail;

    /********************************************************************************************
    * Get selected AMPLE information
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_id_epis_abcde_meth     EPIS_ABCDE_METH ID
    * @param o_ample                  AMPLE information
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_ample_trauma_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        o_ample              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_patient patient.id_patient%TYPE;
    
    BEGIN
    
        g_error := 'GET PATIENT ID';
        pk_alertlog.log_debug(g_error);
        SELECT epis.id_patient
          INTO l_id_patient
          FROM episode epis
         WHERE epis.id_episode = i_id_episode;
    
        g_error := 'GET AMPLE INFO TO EDIT';
        OPEN o_ample FOR
            SELECT eam.id_epis_abcde_meth,
                   pk_abcde_methodology.get_allergy_desc(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => eam.id_episode,
                                                         i_type       => g_list_id,
                                                         i_separator  => g_list_id_sep) id_allergies,
                   pk_abcde_methodology.get_allergy_desc(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => eam.id_episode,
                                                         i_type       => g_list_label,
                                                         i_separator  => g_list_label_sep) allergies,
                   pk_abcde_methodology.get_allergy_desc(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => eam.id_episode,
                                                         i_type       => g_list_type,
                                                         i_separator  => g_list_id_sep) allergy_type,
                   get_medication_list(i_lang, i_prof, eam.id_episode, l_id_patient, g_list_id, g_list_id_sep) id_medication,
                   get_medication_list(i_lang, i_prof, eam.id_episode, l_id_patient, g_list_label, g_list_label_sep) medication,
                   (SELECT *
                      FROM (SELECT pau.id_pat_allergy_unawareness
                              FROM pat_allergy_unawareness pau
                             WHERE pau.flg_status = 'A'
                               AND pau.id_episode = i_id_episode
                             ORDER BY pau.dt_creation DESC)
                     WHERE rownum = 1) id_allergy_unawareness,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'H'
                       AND eamp.flg_status = 'A') past_medical,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'M'
                       AND eamp.flg_status = 'A') last_meal,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'E'
                       AND eamp.flg_status = 'A') event
              FROM epis_abcde_meth eam
             WHERE eam.id_epis_abcde_meth = i_id_epis_abcde_meth
                OR (i_id_epis_abcde_meth IS NULL AND
                   eam.dt_create =
                   (SELECT MAX(dt_create)
                       FROM epis_abcde_meth eamm
                      WHERE eamm.id_episode = i_id_episode
                        AND eamm.flg_status = 'A'
                        AND eamm.id_abcde_meth IN (SELECT amm.id_abcde_meth
                                                     FROM abcde_meth amm
                                                    WHERE amm.flg_meth_type IN ('A', 'S', 'C'))) AND
                   eam.id_episode = i_id_episode AND eam.flg_status = 'A' AND
                   eam.id_abcde_meth IN (SELECT amm.id_abcde_meth
                                            FROM abcde_meth amm
                                           WHERE amm.flg_meth_type IN ('A', 'S', 'C')));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_ample);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'GET_AMPLE_TRAUMA_HIST',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_ample_trauma_hist;

    /********************************************************************************************
    * Get selected SAMPLE information
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_id_epis_abcde_meth     EPIS_ABCDE_METH ID
    * @param o_sample                  SAMPLE information
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_sample_trauma_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        o_sample             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_patient patient.id_patient%TYPE;
    
    BEGIN
    
        g_error := 'GET PATIENT ID';
        pk_alertlog.log_debug(g_error);
        SELECT epis.id_patient
          INTO l_id_patient
          FROM episode epis
         WHERE epis.id_episode = i_id_episode;
    
        g_error := 'GET SAMPLE INFO TO EDIT';
        OPEN o_sample FOR
            SELECT eam.id_epis_abcde_meth,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'S'
                       AND eamp.flg_status = 'A') sympthoms,
                   pk_abcde_methodology.get_allergy_desc(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => eam.id_episode,
                                                         i_type       => g_list_id,
                                                         i_separator  => g_list_id_sep) id_allergies,
                   pk_abcde_methodology.get_allergy_desc(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => eam.id_episode,
                                                         i_type       => g_list_label,
                                                         i_separator  => g_list_label_sep) allergies,
                   pk_abcde_methodology.get_allergy_desc(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => eam.id_episode,
                                                         i_type       => g_list_type,
                                                         i_separator  => g_list_id_sep) allergy_type,
                   get_medication_list(i_lang, i_prof, eam.id_episode, l_id_patient, g_list_id, g_list_id_sep) id_medication,
                   get_medication_list(i_lang, i_prof, eam.id_episode, l_id_patient, g_list_label, g_list_label_sep) medication,
                   (SELECT *
                      FROM (SELECT pau.id_pat_allergy_unawareness
                              FROM pat_allergy_unawareness pau
                             WHERE pau.flg_status = 'A'
                               AND pau.id_episode = i_id_episode
                             ORDER BY pau.dt_creation DESC)
                     WHERE rownum = 1) id_allergy_unawareness,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'H'
                       AND eamp.flg_status = 'A') past_medical,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'M'
                       AND eamp.flg_status = 'A') last_meal,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'E'
                       AND eamp.flg_status = 'A') event
              FROM epis_abcde_meth eam
             WHERE eam.id_epis_abcde_meth = i_id_epis_abcde_meth
                OR (i_id_epis_abcde_meth IS NULL AND
                   eam.dt_create =
                   (SELECT MAX(dt_create)
                       FROM epis_abcde_meth eamm
                      WHERE eamm.id_episode = i_id_episode
                        AND eamm.flg_status = 'A'
                        AND eamm.id_abcde_meth IN (SELECT amm.id_abcde_meth
                                                     FROM abcde_meth amm
                                                    WHERE amm.flg_meth_type IN ('A', 'S', 'C'))) AND
                   eam.id_episode = i_id_episode AND eam.flg_status = 'A' AND
                   eam.id_abcde_meth IN (SELECT amm.id_abcde_meth
                                            FROM abcde_meth amm
                                           WHERE amm.flg_meth_type IN ('A', 'S', 'C')));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_sample);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'GET_SAMPLE_TRAUMA_HIST',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_sample_trauma_hist;

    /********************************************************************************************
    * Get selected CIAMPEDS information
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_id_epis_abcde_meth     EPIS_ABCDE_METH ID
    * @param o_ciampeds                  CIAMPEDS information
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_ciampeds_trauma_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        o_ciampeds           OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_patient patient.id_patient%TYPE;
    
    BEGIN
    
        g_error := 'GET PATIENT ID';
        pk_alertlog.log_debug(g_error);
        SELECT epis.id_patient
          INTO l_id_patient
          FROM episode epis
         WHERE epis.id_episode = i_id_episode;
    
        g_error := 'GET CIAMPEDS INFO TO EDIT';
        OPEN o_ciampeds FOR
            SELECT eam.id_epis_abcde_meth,
                   pk_utils.concat_table(CAST(MULTISET
                                              (SELECT ec.id_epis_complaint
                                                 FROM epis_complaint ec
                                                 JOIN complaint c
                                                   ON ec.id_complaint = c.id_complaint
                                                WHERE ec.flg_status = 'A'
                                                  AND ec.id_episode = eam.id_episode
                                                ORDER BY pk_translation.get_translation(i_lang, c.code_complaint)) AS
                                              table_varchar),
                                         ',') id_chief_complaint,
                   pk_utils.concat_table(CAST(MULTISET (SELECT pk_translation.get_translation(i_lang, c.code_complaint)
                                                 FROM epis_complaint ec
                                                 JOIN complaint c
                                                   ON ec.id_complaint = c.id_complaint
                                                WHERE ec.flg_status = 'A'
                                                  AND ec.id_episode = eam.id_episode
                                                ORDER BY 1) AS table_varchar),
                                         ', ') chief_complaint,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'I'
                       AND eamp.flg_status = 'A') imunisation,
                   pk_abcde_methodology.get_allergy_desc(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => eam.id_episode,
                                                         i_type       => g_list_id,
                                                         i_separator  => g_list_id_sep) id_allergies,
                   pk_abcde_methodology.get_allergy_desc(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => eam.id_episode,
                                                         i_type       => g_list_label,
                                                         i_separator  => g_list_label_sep) allergies,
                   pk_abcde_methodology.get_allergy_desc(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => eam.id_episode,
                                                         i_type       => g_list_type,
                                                         i_separator  => g_list_id_sep) allergy_type,
                   get_medication_list(i_lang, i_prof, eam.id_episode, l_id_patient, g_list_id, g_list_id_sep) id_medication,
                   get_medication_list(i_lang, i_prof, eam.id_episode, l_id_patient, g_list_label, g_list_label_sep) medication,
                   (SELECT *
                      FROM (SELECT pau.id_pat_allergy_unawareness
                              FROM pat_allergy_unawareness pau
                             WHERE pau.flg_status = 'A'
                               AND pau.id_episode = i_id_episode
                             ORDER BY pau.dt_creation DESC)
                     WHERE rownum = 1) id_allergy_unawareness,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'H'
                       AND eamp.flg_status = 'A') past_medical,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'PI'
                       AND eamp.flg_status = 'A') parents_impression,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'E'
                       AND eamp.flg_status = 'A') event,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'D'
                       AND eamp.flg_status = 'A') diet,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'DI'
                       AND eamp.flg_status = 'A') diapers,
                   (SELECT eamp.param_text
                      FROM epis_abcde_meth_param eamp
                     WHERE eamp.id_epis_abcde_meth = eam.id_epis_abcde_meth
                       AND eamp.flg_type = 'S'
                       AND eamp.flg_status = 'A') sympthoms
              FROM epis_abcde_meth eam
             WHERE eam.id_epis_abcde_meth = i_id_epis_abcde_meth
                OR (i_id_epis_abcde_meth IS NULL AND
                   eam.dt_create =
                   (SELECT MAX(dt_create)
                       FROM epis_abcde_meth eamm
                      WHERE eamm.id_episode = i_id_episode
                        AND eamm.flg_status = 'A'
                        AND eamm.id_abcde_meth IN (SELECT amm.id_abcde_meth
                                                     FROM abcde_meth amm
                                                    WHERE amm.flg_meth_type IN ('A', 'S', 'C'))) AND
                   eam.id_episode = i_id_episode AND eam.flg_status = 'A' AND
                   eam.id_abcde_meth IN (SELECT amm.id_abcde_meth
                                            FROM abcde_meth amm
                                           WHERE amm.flg_meth_type IN ('A', 'S', 'C')));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_ciampeds);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'GET_CIAMPEDS_TRAUMA_HIST',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_ciampeds_trauma_hist;

    /********************************************************************************************
    * Get patient's allergys
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             the patient ID
    * @param o_pat_allergy_list       Alergies info to multichoice use
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_pat_allergy_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        o_pat_allergy_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        unawareness_exception EXCEPTION;
        l_unawareness       pk_allergy.t_cur_allergy_unawareness;
        l_unawarenessrec    pk_allergy.t_rec_allergy_unawareness;
        l_unawarenessresult BOOLEAN;
        g_allergy             CONSTANT VARCHAR2(2) := 'A';
        g_allergy_unawareness CONSTANT VARCHAR2(2) := 'AU';
        g_allergy_medication  CONSTANT VARCHAR2(1) := 'M';
        g_allergy_other       CONSTANT VARCHAR2(1) := 'O';
    
        l_tbl_allergy_unwareness t_table_allergy_unawareness := t_table_allergy_unawareness();
    
    BEGIN
    
        g_error             := 'GET UNAWARENESS_CONDITION';
        l_unawarenessresult := pk_allergy.get_unawareness_condition(i_lang    => i_lang,
                                                                    i_patient => i_id_patient,
                                                                    o_choices => l_unawareness,
                                                                    o_error   => o_error);
    
        --Percorro o cursor                                           
        LOOP
            FETCH l_unawareness
                INTO l_unawarenessrec;
            EXIT WHEN l_unawareness%NOTFOUND;
        
            --Just return to flash the alergy unawareness that could be choosen.  
            l_tbl_allergy_unwareness.extend();
            l_tbl_allergy_unwareness(l_tbl_allergy_unwareness.count) := t_rec_allergy_unawareness(data          => l_unawarenessrec.id_allergy_unawareness,
                                                                                                  label         => l_unawarenessrec.type_unawareness,
                                                                                                  flg_search    => pk_alert_constant.g_no,
                                                                                                  extra_data    => '',
                                                                                                  flg_exclusive => pk_alert_constant.g_yes,
                                                                                                  flg_type      => g_allergy_unawareness,
                                                                                                  flg_enabled   => l_unawarenessrec.flg_enabled,
                                                                                                  flg_default   => l_unawarenessrec.flg_default,
                                                                                                  rank          => -1 *
                                                                                                                   l_unawarenessrec.id_allergy_unawareness);
            --  END IF;                                                                                       
        END LOOP;
    
        g_error := 'GET PAT_ALLERGY LIST';
    
        OPEN o_pat_allergy_list FOR
            SELECT pa.id_pat_allergy data,
                   nvl(pa.desc_allergy,
                       pk_translation.get_translation(i_lang, 'ALLERGY.CODE_ALLERGY.' || to_char(pa.id_allergy))) || ' (' ||
                   pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE', pa.flg_type, i_lang) || '; ' ||
                   pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS', pa.flg_status, i_lang) ||
                   decode(pa.year_begin, NULL, '', '; ' || pa.year_begin) || ').' label,
                   pk_alert_constant.get_no flg_search,
                   '(' || pk_sysdomain.get_domain('PAT_ALLERGY.FLG_TYPE', pa.flg_type, i_lang) || '; ' ||
                   pk_sysdomain.get_domain('PAT_ALLERGY.FLG_STATUS', pa.flg_status, i_lang) ||
                   decode(pa.year_begin, NULL, '', '; ' || pa.year_begin) || ')' extra_data,
                   pk_alert_constant.get_no flg_exclusive,
                   g_allergy flg_type,
                   pk_allergy.get_flg_is_drug_allergy(pa.id_allergy) flg_exclusive_group,
                   pk_alert_constant.g_yes flg_enabled,
                   pk_alert_constant.g_yes flg_default,
                   0 rank
              FROM pat_allergy pa
             WHERE pa.id_patient = i_id_patient
               AND pa.flg_status IN ('A', 'P')
            UNION ALL
            SELECT tau.data,
                   tau.label,
                   tau.flg_search,
                   tau.extra_data,
                   tau.flg_exclusive,
                   tau.flg_type,
                   decode(tau.data, 3, g_allergy_medication, 1, 'O', pk_alert_constant.g_yes) flg_exclusive_group,
                   tau.flg_enabled,
                   tau.flg_default,
                   tau.rank
              FROM TABLE(l_tbl_allergy_unwareness) tau
            
            UNION ALL
            SELECT -1 data,
                   pk_message.get_message(i_lang, 'ABCDE_T029') label,
                   'Y' flg_search,
                   NULL extra_data,
                   'N' flg_exclusive,
                   NULL flg_type,
                   pk_alert_constant.g_yes flg_exclusive_group,
                   pk_alert_constant.g_yes flg_enabled,
                   pk_alert_constant.g_yes flg_default,
                   -1 rank
              FROM dual
             ORDER BY flg_search ASC, rank DESC, label ASC;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_allergy_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'GET_PAT_ALLERGY_LIST',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_pat_allergy_list;

    /********************************************************************************************
    * Get patient's medication
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_id_patient             the patient ID
    * @param o_pat_medication_list    PAT_MEDICATION_LIST information
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_pat_medication_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        o_pat_medication_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        my_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_api_pfh_clindoc_in.get_previous_medication(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_id_episode          => i_id_episode,
                                                             o_pat_medication_list => o_pat_medication_list,
                                                             o_error               => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'GET_PAT_MEDICATION_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_medication_list);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'GET_PAT_MEDICATION_LIST',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_pat_medication_list;

    /********************************************************************************************
    * Get episode associated complaint
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             the patient ID
    * @param o_epis_complaint_list    Complaint info to multichoice use
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_epis_complaint_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_epis_complaint_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET EPIS COMPLAINT LIST';
        OPEN o_epis_complaint_list FOR
            SELECT ec.id_epis_complaint data,
                   pk_translation.get_translation(i_lang, c.code_complaint) label,
                   'N' flg_search
              FROM epis_complaint ec
              JOIN complaint c
                ON ec.id_complaint = c.id_complaint
             WHERE ec.id_episode = i_id_episode
               AND ec.flg_status = 'A'
            UNION ALL
            SELECT -1 data, pk_message.get_message(i_lang, 'ABCDE_T029') label, 'Y' flg_search
              FROM dual
             ORDER BY flg_search ASC, label ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_epis_complaint_list);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'GET_EPIS_COMPLAINT_LIST',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_epis_complaint_list;

    /********************************************************************************************
    * Get edition options
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_options                Available edition options
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION edit_assess_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET EPIS DIET LIST';
        OPEN o_options FOR
            SELECT a.from_state data, pk_message.get_message(i_lang, i_prof, a.code_action) label
              FROM action a
             WHERE a.subject = 'ABCDE_HIST_EDIT'
               AND a.flg_status = 'A';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_options);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'EDIT_ASSESS_OPTIONS',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END edit_assess_options;

    /********************************************************************************************
    * Get creations options available by patient's age and professional profile
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             the patient ID
    * @param i_id_episode             the episode ID
    * @param o_options                Available creation options
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION create_assess_options
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_options    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cat             category.flg_type%TYPE;
        l_age             patient.age%TYPE;
        l_alias           patient.alias%TYPE;
        l_min_abcde       sys_config.value%TYPE;
        l_max_abcde       sys_config.value%TYPE;
        l_ample_status    VARCHAR2(1);
        l_sample_status   VARCHAR2(1);
        l_ciampeds_status VARCHAR2(1);
        l_pre_hosp_status VARCHAR2(1);
    
        l_ample_available  sys_config.value%TYPE;
        l_sample_available sys_config.value%TYPE;
    
        l_is_resp PLS_INTEGER;
    
    BEGIN
    
        g_error := 'GET PATIENT AGE';
        SELECT nvl(p.age, trunc(months_between(SYSDATE, p.dt_birth) / 12)) age, p.alias
          INTO l_age, l_alias
          FROM patient p
         WHERE p.id_patient = i_id_patient;
    
        g_error := 'GET PROFESSIONAL CATEGORY';
        l_cat   := pk_prof_utils.get_category(i_lang, i_prof);
    
        l_min_abcde := nvl(pk_sysconfig.get_config('ABCDE_AMPLE_AGE_MIN', i_prof), 0);
        l_max_abcde := nvl(pk_sysconfig.get_config('ABCDE_SAMP_CIAMP_AGE_MAX', i_prof), 200);
    
        l_ample_available  := nvl(pk_sysconfig.get_config('ABCDE_AVAILABLE_AMPLE', i_prof), 'Y');
        l_sample_available := nvl(pk_sysconfig.get_config('ABCDE_AVAILABLE_SAMPLE', i_prof), 'Y');
    
        g_error   := 'GET EPISODE RESPONSABILITY';
        l_is_resp := pk_patient.get_prof_resp(i_lang, i_prof, i_id_patient, i_id_episode);
    
        IF l_is_resp = pk_adt.g_true
           OR l_alias IS NULL
        THEN
            l_pre_hosp_status := 'A';
        ELSE
            l_pre_hosp_status := 'I';
        END IF;
    
        IF l_age IS NULL
        THEN
            l_ample_status    := 'A';
            l_sample_status   := 'A';
            l_ciampeds_status := 'A';
        ELSE
            IF l_age >= l_min_abcde
            THEN
                l_ample_status := 'A';
            ELSE
                l_ample_status := 'I';
            END IF;
        
            IF l_age <= l_max_abcde
            THEN
                l_sample_status   := 'A';
                l_ciampeds_status := 'A';
            ELSE
                l_sample_status   := 'I';
                l_ciampeds_status := 'I';
            END IF;
        END IF;
    
        g_error := 'GET ACTIONS';
        OPEN o_options FOR
            SELECT id_action,
                   id_parent,
                   LEVEL, --used to manage the shown' items by Flash
                   to_state, --destination state flag
                   pk_message.get_message(i_lang, i_prof, code_action) desc_action, --action's description
                   icon, --action's icon
                   decode(flg_default, 'D', 'Y', 'N') flg_default, --default action
                   decode(to_state,
                          'A',
                          l_ample_status,
                          'S',
                          l_sample_status,
                          'C',
                          l_ciampeds_status,
                          'H',
                          l_pre_hosp_status,
                          'A') flg_active,
                   internal_name action
              FROM action a
             WHERE subject = 'ABCDE_HIST'
               AND ((a.to_state = 'A' AND l_ample_available = 'Y') OR (a.to_state = 'S' AND l_sample_available = 'Y') OR
                   a.to_state NOT IN ('A', 'S'))
            CONNECT BY PRIOR id_action = id_parent
             START WITH id_parent IS NULL
             ORDER BY LEVEL, rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_options);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'CREATE_ASSESS_OPTIONS',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_assess_options;

    /********************************************************************************************
    * Checks if there is any records for a given area
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_doc_area               doc area ID
    * @param o_flg_exists             Records exist: Y - yes, N - No
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2009/07/07
    **********************************************************************************************/
    FUNCTION get_doc_area_exists
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_doc_area   IN doc_area.id_doc_area%TYPE,
        o_flg_exists OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_documentation epis_documentation.id_epis_documentation%TYPE;
    
        CURSOR c_epis_doc IS
            SELECT ed.id_epis_documentation
              FROM epis_documentation ed
             WHERE ed.id_episode = i_episode
               AND ed.id_doc_area = i_doc_area;
    BEGIN
    
        g_error := 'CHECK_ASSESSMENT';
        OPEN c_epis_doc;
        FETCH c_epis_doc
            INTO l_id_epis_documentation;
        CLOSE c_epis_doc;
    
        IF l_id_epis_documentation IS NOT NULL
        THEN
            o_flg_exists := pk_alert_constant.g_yes;
        ELSE
            o_flg_exists := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'GET_DOC_AREA_EXISTS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_doc_area_exists;

    /********************************************************************************************
    * Gets the summary page description for a specific section
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_internal_name          Section internal name
    *                        
    * @return                         Section description
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2009/07/07
    **********************************************************************************************/
    FUNCTION get_summ_section_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_internal_name IN summary_page_section.internal_name%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_exists   VARCHAR2(1);
        l_desc_section VARCHAR2(4000);
        l_doc_area     table_number;
        l_desc_area    table_varchar;
        l_count        NUMBER := 1;
        l_error        t_error_out;
    
    BEGIN
    
        SELECT sps.id_doc_area, pk_translation.get_translation(i_lang, sps.code_summary_page_section)
          BULK COLLECT
          INTO l_doc_area, l_desc_area
          FROM summary_page_section sps
          JOIN summary_page sp
            ON sp.id_summary_page = sps.id_summary_page
         WHERE sp.internal_name = i_internal_name
         ORDER BY sps.id_doc_area;
    
        LOOP
            g_error := 'CHECK_ASSESSMENT';
            IF NOT get_doc_area_exists(i_lang       => i_lang,
                                       i_prof       => i_prof,
                                       i_episode    => i_episode,
                                       i_doc_area   => l_doc_area(l_count),
                                       o_flg_exists => l_flg_exists,
                                       o_error      => l_error)
            THEN
                RETURN '';
            END IF;
        
            IF l_flg_exists = pk_alert_constant.g_yes
            THEN
                l_desc_section := l_desc_area(l_count);
            END IF;
        
            EXIT WHEN l_desc_section IS NOT NULL OR l_count = l_doc_area.count;
            l_count := l_count + 1;
        END LOOP;
    
        RETURN l_desc_section;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_summ_section_desc;

    /********************************************************************************************
    * Trauma and ABCDE summary page sections
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param o_sections               Cursor containing the sections info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2009/07/06
    **********************************************************************************************/
    FUNCTION get_summary_sections
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_sections OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_prim_assess summary_page.internal_name%TYPE := 'TRAUMA_PRIM_ASSESS';
        l_internal_sec_assess  summary_page.internal_name%TYPE := 'TRAUMA_SEC_ASSESS';
        l_height               summary_page_section.height%TYPE := 144;
    
    BEGIN
    
        g_error := 'GET SUMMARY SECTIONS';
        OPEN o_sections FOR
            SELECT pk_message.get_message(i_lang, 'ABCDE_T002') translated_code,
                   '' internal_name,
                   l_height height,
                   table_number(0) id_doc_area,
                   '' desc_section
              FROM dual
            -- ALERT-61607 03/01/11 Show AMPLE/SAMPLE/CIAMPEDS
            UNION ALL
            SELECT pk_message.get_message(i_lang, 'ABCDE_T028') translated_code,
                   '' internal_name,
                   l_height height,
                   table_number(0) id_doc_area,
                   '' desc_section
              FROM dual
            UNION ALL
            SELECT pk_translation.get_translation(i_lang, sp.code_summary_page) translated_code,
                   sp.internal_name,
                   l_height height,
                   CAST(MULTISET (SELECT sps.id_doc_area
                           FROM summary_page_section sps
                          WHERE sps.id_summary_page = sp.id_summary_page) AS table_number) id_doc_area,
                   get_summ_section_desc(i_lang, i_prof, i_episode, sp.internal_name) desc_section
              FROM summary_page sp
             WHERE sp.internal_name IN (l_internal_prim_assess, l_internal_sec_assess)
             ORDER BY internal_name NULLS FIRST;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_sections);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'GET_SUMMARY_SECTIONS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_summary_sections;

    /********************************************************************************************
    * Trauma and ABCDE summary page
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_id_doc_area            doc area IDs (primary and secondary assessment)
    * @param o_trauma                 Trauma score information
    * @param o_ann_arrival_list       announced arrival
    * @param o_pre_hosp               Pre-hospital assessment
    * @param o_pre_hosp               Pre-hospital assessment (vital signs)
    * @param o_prim_assess            Primary assessment (physician and nurse)
    * @param o_sec_assess             Secondary assessment (physician and nurse)
    * @param o_trauma_hist_titles     ABCDE assessment field titles
    * @param o_trauma_hist            ABCDE assessment data
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2009/07/04
    **********************************************************************************************/
    FUNCTION get_summary
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_doc_area        IN table_number,
        o_trauma             OUT pk_types.cursor_type,
        o_ann_arrival_list   OUT pk_types.cursor_type,
        o_pre_hosp           OUT pk_types.cursor_type,
        o_pre_hosp_vs        OUT pk_types.cursor_type,
        o_prim_assess_reg    OUT pk_types.cursor_type,
        o_prim_assess_val    OUT pk_types.cursor_type,
        o_sec_assess_reg     OUT pk_types.cursor_type,
        o_sec_assess_val     OUT pk_types.cursor_type,
        o_trauma_hist_titles OUT pk_types.cursor_type,
        o_trauma_hist        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_template_layouts   pk_types.cursor_type;
        l_doc_area_component pk_types.cursor_type;
        l_flg_exists         VARCHAR2(1);
    
    BEGIN
    
        g_error := 'GET TRAUMA INFO';
        OPEN o_trauma FOR
            SELECT pk_translation.get_translation(i_lang, ms.code_mtos_score) desc_score,
                   pk_sysdomain.get_domain('MTOS_SCORE.FLG_SCORE_TYPE', ms.flg_score_type, i_lang) desc_abrev_score,
                   ms.id_mtos_score,
                   mt.id_mtos_param,
                   decode(mt.internal_name,
                          'TRISS_TOTAL_P',
                          pk_message.get_message(i_lang, 'TRAUMA_T017'),
                          'TRISS_TOTAL_B',
                          pk_message.get_message(i_lang, 'TRAUMA_T016'),
                          '') type_score,
                   pk_sev_scores_core.get_formatted_total(i_lang, i_prof, es.registered_value, mt.internal_name) total_score_desc
              FROM mtos_score ms
              JOIN mtos_param mt
                ON mt.id_mtos_score = ms.id_mtos_score
              LEFT JOIN (SELECT es.dt_create,
                                ep.id_mtos_param,
                                ep.registered_value,
                                es.id_epis_mtos_score,
                                es.id_episode
                           FROM epis_mtos_score es
                           JOIN epis_mtos_param ep
                             ON ep.id_epis_mtos_score = es.id_epis_mtos_score
                          WHERE es.id_episode = i_id_episode
                            AND es.dt_create = (SELECT MAX(es2.dt_create)
                                                  FROM epis_mtos_score es2
                                                 WHERE es2.id_episode = i_id_episode)) es
                ON mt.id_mtos_param = es.id_mtos_param
             WHERE ms.id_mtos_score IN (pk_sev_scores_constant.g_id_score_gcs,
                                        pk_sev_scores_constant.g_id_score_pts,
                                        pk_sev_scores_constant.g_id_score_rts,
                                        pk_sev_scores_constant.g_id_score_iss,
                                        pk_sev_scores_constant.g_id_score_triss)
               AND mt.flg_fill_type = pk_sev_scores_constant.g_flg_fill_type_t
               AND ms.flg_available =
                   decode(es.registered_value, NULL, pk_alert_constant.g_available, ms.flg_available)
               AND mt.flg_available =
                   decode(es.registered_value, NULL, pk_alert_constant.g_available, ms.flg_available)
             ORDER BY ms.rank;
    
        g_error := 'CHECK PRIMARY ASSESSMENT';
        IF NOT get_doc_area_exists(i_lang       => i_lang,
                                   i_prof       => i_prof,
                                   i_episode    => i_id_episode,
                                   i_doc_area   => i_id_doc_area(1),
                                   o_flg_exists => l_flg_exists,
                                   o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_flg_exists = pk_alert_constant.g_yes
        THEN
            g_error := 'GET PRIMARY ASSESSMENT DOC';
            IF NOT pk_summary_page.get_summ_page_doc_area_value(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_episode            => i_id_episode,
                                                                i_doc_area           => i_id_doc_area(1),
                                                                o_doc_area_register  => o_prim_assess_reg,
                                                                o_doc_area_val       => o_prim_assess_val,
                                                                o_template_layouts   => l_template_layouts,
                                                                o_doc_area_component => l_doc_area_component,
                                                                o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            g_error := 'GET PRIMARY ASSESSMENT NURSE';
            IF NOT pk_summary_page.get_summ_page_doc_area_value(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_episode            => i_id_episode,
                                                                i_doc_area           => i_id_doc_area(2),
                                                                o_doc_area_register  => o_prim_assess_reg,
                                                                o_doc_area_val       => o_prim_assess_val,
                                                                o_template_layouts   => l_template_layouts,
                                                                o_doc_area_component => l_doc_area_component,
                                                                o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'CHECK SECONDARY ASSESSMENT';
        IF NOT get_doc_area_exists(i_lang       => i_lang,
                                   i_prof       => i_prof,
                                   i_episode    => i_id_episode,
                                   i_doc_area   => i_id_doc_area(3),
                                   o_flg_exists => l_flg_exists,
                                   o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_flg_exists = pk_alert_constant.g_yes
        THEN
            g_error := 'GET SECONDARY ASSESSMENT DOC';
            IF NOT pk_summary_page.get_summ_page_doc_area_value(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_episode            => i_id_episode,
                                                                i_doc_area           => i_id_doc_area(3),
                                                                o_doc_area_register  => o_sec_assess_reg,
                                                                o_doc_area_val       => o_sec_assess_val,
                                                                o_template_layouts   => l_template_layouts,
                                                                o_doc_area_component => l_doc_area_component,
                                                                o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            g_error := 'GET PRIMARY ASSESSMENT NURSE';
            IF NOT pk_summary_page.get_summ_page_doc_area_value(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_episode            => i_id_episode,
                                                                i_doc_area           => i_id_doc_area(4),
                                                                o_doc_area_register  => o_sec_assess_reg,
                                                                o_doc_area_val       => o_sec_assess_val,
                                                                o_template_layouts   => l_template_layouts,
                                                                o_doc_area_component => l_doc_area_component,
                                                                o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'GET ANN ARRIVAL DATA';
        IF NOT pk_announced_arrival.get_ann_arrival_by_epi(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_episode           => i_id_episode,
                                                           o_ann_arrival_list  => o_ann_arrival_list,
                                                           o_pre_hosp_accident => o_pre_hosp,
                                                           o_pre_hosp_vs_read  => o_pre_hosp_vs,
                                                           o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET AMPLE/SAMPLE/CIAMPEDS INFO';
        pk_alertlog.log_debug(g_error);
        IF NOT get_abcde_summary(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_id_episode  => i_id_episode,
                                 i_get_titles  => pk_alert_constant.g_yes,
                                 o_titles      => o_trauma_hist_titles,
                                 o_trauma_hist => o_trauma_hist,
                                 o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_trauma);
            pk_types.open_my_cursor(o_ann_arrival_list);
            pk_types.open_my_cursor(o_pre_hosp);
            pk_types.open_my_cursor(o_pre_hosp_vs);
            pk_types.open_my_cursor(o_prim_assess_reg);
            pk_types.open_my_cursor(o_prim_assess_val);
            pk_types.open_my_cursor(o_sec_assess_reg);
            pk_types.open_my_cursor(o_sec_assess_val);
            pk_types.open_my_cursor(o_trauma_hist_titles);
            pk_types.open_my_cursor(o_trauma_hist);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'GET_SUMMARY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_summary;

    /********************************************************************************************
    * Get medication description
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_medication_list    List of PAT_MEDICATION_LIST IDs
    * @param i_id_episode             the episode ID
    * @param o_medication             Medication info to multichoice use
    * @param o_options                Medication options
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_pat_medic_multichoice
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat_medication_list IN table_number,
        i_id_episode          IN episode.id_episode%TYPE,
        o_medication          OUT pk_types.cursor_type,
        o_options             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'OPEN O_PAT_MEDICATION_LIST';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_api_pfh_clindoc_in.get_abcde_medic_multichoice(i_lang                => i_lang,
                                                                 i_prof                => i_prof,
                                                                 i_pat_medication_list => i_pat_medication_list,
                                                                 i_id_episode          => i_id_episode,
                                                                 o_medication          => o_medication,
                                                                 o_options             => o_options,
                                                                 o_error               => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_types.open_my_cursor(o_medication);
            pk_types.open_my_cursor(o_options);
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'GET_PAT_MEDIC_MULTICHOICE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_medication);
            pk_types.open_my_cursor(o_options);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ABCDE_METHODOLOGY',
                                              'GET_PAT_MEDIC_MULTICHOICE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_medic_multichoice;

    /********************************************************************************************
    * Get information to the confirmation screen
    *
    * @author  Pedro Teixeira
    * @since   2011-09-23
    ********************************************************************************************/
    FUNCTION get_confirmation_screen_data
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        o_confirm_msg            OUT VARCHAR2,
        o_confirmation_title     OUT VARCHAR2,
        o_continue_button_msg    OUT VARCHAR2,
        o_back_button_msg        OUT VARCHAR2,
        o_field_type_header      OUT VARCHAR2,
        o_field_pharm_header     OUT VARCHAR2,
        o_field_last_dose_header OUT VARCHAR2,
        o_inactive_icon          OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_api_pfh_clindoc_in.get_confirmation_screen_data(i_lang                   => i_lang,
                                                                  i_prof                   => i_prof,
                                                                  o_confirm_msg            => o_confirm_msg,
                                                                  o_confirmation_title     => o_confirmation_title,
                                                                  o_continue_button_msg    => o_continue_button_msg,
                                                                  o_back_button_msg        => o_back_button_msg,
                                                                  o_field_type_header      => o_field_type_header,
                                                                  o_field_pharm_header     => o_field_pharm_header,
                                                                  o_field_last_dose_header => o_field_last_dose_header,
                                                                  o_inactive_icon          => o_inactive_icon,
                                                                  o_error                  => o_error);
    
    END get_confirmation_screen_data;

    /********************************************************************************************
    * Returns list of descriptions for prescription ID's
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_tab_presc               Table with prescription ID's
    * @param o_presc_description       Set of prescription descriptions
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         2.6
    * @since                           10-Oct-2011
    *
    **********************************************************************************************/
    FUNCTION get_presc_description
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_tab_presc         IN table_number_id,
        o_presc_description OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_api_pfh_clindoc_in.get_presc_description(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_tab_presc         => i_tab_presc,
                                                           o_presc_description => o_presc_description,
                                                           o_error             => o_error);
    END get_presc_description;

END pk_abcde_methodology;
/
