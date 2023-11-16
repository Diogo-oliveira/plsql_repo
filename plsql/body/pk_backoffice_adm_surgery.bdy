/*-- Last Change Revision: $Rev: 2026763 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:49 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_adm_surgery IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    -- Private exceptions
    g_exception EXCEPTION;
    --

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    -- Function and procedure implementations

    /*******************************************
    |        Admission Indication               |
    ********************************************/

    /********************************************************************************************
    * Get the list of Indications for admission 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_indications            List of indications
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/10
    **********************************************************************************************/
    FUNCTION get_adm_indication_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_indications    OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_ADM_INDICATION_LIST: ';
        pk_alertlog.log_debug(g_error);
        --
        OPEN o_indications FOR
            SELECT ai.id_adm_indication id_indication,
                   nvl(ai.desc_adm_indication, pk_translation.get_translation(i_lang, ai.code_adm_indication)) indication_desc,
                   get_dcs_description(i_lang,
                                       i_prof,
                                       get_adm_indication_pref_dcs(i_lang, i_prof, ai.id_adm_indication)) indication_pref_service,
                   pk_date_utils.dt_chr_tsz(i_lang, ai.dt_last_update, i_prof) indication_date,
                   pk_sysdomain.get_domain('ADM_INDICATION.FLG_AVAILABLE', ai.flg_available, i_lang) indication_state,
                   ai.flg_status flg_status,
                   decode(ai.flg_status,
                          pk_alert_constant.g_flg_status_c,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) can_cancel
              FROM adm_indication ai
             WHERE (ai.id_institution = i_id_institution OR
                   i_id_institution IN (SELECT ig.id_institution
                                           FROM institution_group ig
                                          WHERE ig.id_group = ai.id_group
                                            AND ig.flg_relation = 'INST_CNT'))
             ORDER BY ai.flg_available        DESC /*Y, N*/,
                      can_cancel              DESC,
                      indication_pref_service,
                      indication_desc,
                      indication_date;
    
        --
        g_error := 'GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --    
        OPEN o_screen_labels FOR
            SELECT pk_message.get_message(i_lang, 'ADMINISTRATOR_T643') grid_main_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T163') name_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T646') pref_serv_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T644') date_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T332') status_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T645') filter
              FROM dual;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_indications);
            pk_types.open_my_cursor(o_screen_labels);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_ADM_INDICATION_LIST',
                                                     o_error);
        
    END get_adm_indication_list;
    --

    /********************************************************************************************
    * Insert the history of the room
    *
    * @param i_lang                     Preferred language ID for this professional  
    * @param i_id_room_hist             Room ID History
    * @param i_id_room                  Room ID
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @author                           AntÛnio Neto
    * @version                          2.6.1
    * @since                            2011/04/14
    **********************************************************************************************/
    FUNCTION insert_room_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_id_room_hist IN room_hist.id_room_hist%TYPE,
        i_id_room      IN room.id_room%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
        FOR item_room_hist IN (SELECT rdcs.id_dep_clin_serv, rdcs.id_room_dep_clin_serv
                                 FROM room r
                                 JOIN room_dep_clin_serv rdcs
                                   ON (r.id_room = rdcs.id_room)
                                WHERE r.id_room = i_id_room)
        LOOP
            ts_room_dep_clin_serv_hist.ins(id_room_hist_in          => i_id_room_hist,
                                           id_room_dep_clin_serv_in => item_room_hist.id_room_dep_clin_serv,
                                           id_room_in               => i_id_room,
                                           id_dep_clin_serv_in      => item_room_hist.id_dep_clin_serv,
                                           rows_out                 => l_rows_out);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'INSERT_ROOM_HIST',
                                              o_error);
            RETURN FALSE;
    END insert_room_hist;

    /********************************************************************************************
    * Get the description of a given dep. clinical service (dcs) in the format: Service+Separator+Specialty
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_indications            List of indications
    * @param o_error                  Error
    *
    * @return                         the dcs description
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/11
    **********************************************************************************************/
    FUNCTION get_dcs_description
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_dcs    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_separator IN VARCHAR2 DEFAULT g_dcs_separator_char
    ) RETURN VARCHAR2 IS
    
        --dcs description
        l_dcs_descr VARCHAR2(1000 CHAR) := '';
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'GET_DCS_DESCRIPTION: i_id_dcs = ' || i_id_dcs || ', i_separator = ' || i_separator;
        pk_alertlog.log_debug(g_error);
        --
        IF i_id_dcs IS NOT NULL
        THEN
            SELECT pk_translation.get_translation(i_lang, d.code_department) || i_separator ||
                   pk_translation.get_translation(i_lang, cs.code_clinical_service)
              INTO l_dcs_descr
              FROM dep_clin_serv dcs
              JOIN clinical_service cs
                ON (dcs.id_clinical_service = cs.id_clinical_service)
              JOIN department d
                ON (dcs.id_department = d.id_department)
             WHERE dcs.id_dep_clin_serv = i_id_dcs;
        END IF;
        --else return null
        --
        RETURN l_dcs_descr;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DCS_DESCRIPTION',
                                              l_error);
            RETURN NULL;
    END get_dcs_description;
    --

    /********************************************************************************************
    * Get the description of a given Specialty
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_specialty           Specialty ID
    *
    * @return                         the specialty description
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_specialty_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_specialty IN clinical_service.id_clinical_service%TYPE
    ) RETURN VARCHAR2 IS
    
        --dcs description
        l_specialty_descr VARCHAR2(1000 CHAR) := '';
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'get_specialty_description: i_id_specialty = ' || i_id_specialty;
        pk_alertlog.log_debug(g_error);
        --
        IF i_id_specialty IS NOT NULL
        THEN
            SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
              INTO l_specialty_descr
              FROM clinical_service cs
             WHERE cs.id_clinical_service = i_id_specialty;
        END IF;
        --else return null
        --
        RETURN l_specialty_descr;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_SPECIALTY_DESCRIPTION',
                                              l_error);
            RETURN NULL;
    END get_specialty_description;
    --

    /********************************************************************************************
    * Get prefered dep. clinical service (dcs) for a given admission indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_indications            List of indications
    *
    * @return                         the prefered dcs id
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/11
    **********************************************************************************************/
    FUNCTION get_adm_indication_pref_dcs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN NUMBER IS
    
        --dcs description
        l_id_indication_pref_dcs dep_clin_serv.id_dep_clin_serv%TYPE;
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'GET_ADM_INDICATION_PREF_DCS: i_id_adm_indication = ' || i_id_adm_indication;
        pk_alertlog.log_debug(g_error);
        --
    
        SELECT aidcs.id_dep_clin_serv
          INTO l_id_indication_pref_dcs
          FROM adm_indication ai
          JOIN adm_ind_dep_clin_serv aidcs
            ON (ai.id_adm_indication = aidcs.id_adm_indication AND aidcs.flg_pref = pk_alert_constant.g_yes)
         WHERE ai.id_adm_indication = i_id_adm_indication
           AND EXISTS (SELECT 1
                  FROM dep_clin_serv t
                 WHERE aidcs.id_dep_clin_serv = t.id_dep_clin_serv
                   AND id_department IN (SELECT id_department
                                           FROM department
                                          WHERE id_institution IN (i_prof.institution)));
    
        --
        RETURN l_id_indication_pref_dcs;
        --      
        --IF there are more than one dcs defined as prefered (flg_pref = Y) an exception is raised an nothing is returned!
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ADM_INDICATION_PREF_DCS',
                                              l_error);
            RETURN - 1;
    END get_adm_indication_pref_dcs;
    --

    /********************************************************************************************
    * Get the list dep. clinical service (dcs) for a given admission indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication ID
    *
    * @return                         the list dcs ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/12
    **********************************************************************************************/
    FUNCTION get_adm_indication_dcs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN table_number IS
    
        --dcs description
        l_id_indication_dcs table_number := table_number();
    
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'GET_ADM_INDICATION_DCS: i_id_adm_indication = ' || i_id_adm_indication;
        pk_alertlog.log_debug(g_error);
        --
    
        SELECT aidcs.id_dep_clin_serv
          BULK COLLECT
          INTO l_id_indication_dcs
          FROM adm_indication ai
          JOIN adm_ind_dep_clin_serv aidcs
            ON (ai.id_adm_indication = aidcs.id_adm_indication)
         WHERE ai.id_adm_indication = i_id_adm_indication
         ORDER BY aidcs.id_dep_clin_serv;
    
        --
        RETURN l_id_indication_dcs;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ADM_INDICATION_DCS',
                                              l_error);
            RETURN NULL;
    END get_adm_indication_dcs;
    --

    /********************************************************************************************
    * Get the list of escape services defined for a given admission indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication ID
    *
    * @return                         the list escape services ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION get_adm_ind_esc_services
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN table_number IS
    
        --escape services
        l_id_indication_esc_serv table_number := table_number();
    
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'GET_ADM_IND_ESC_SERVICES: i_id_adm_indication = ' || i_id_adm_indication;
        pk_alertlog.log_debug(g_error);
        --
    
        SELECT ed.id_department
          BULK COLLECT
          INTO l_id_indication_esc_serv
          FROM escape_department ed
         WHERE ed.id_adm_indication = i_id_adm_indication
         ORDER BY ed.id_department;
    
        --
        RETURN l_id_indication_esc_serv;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ADM_IND_ESC_SERVICES',
                                              l_error);
            RETURN NULL;
    END get_adm_ind_esc_services;
    --

    /********************************************************************************************
    * Get the list dep. clinical service (dcs) as a string for a given admission indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication ID
    * @param i_id_adm_indication_hist Adm indication history Id
    *
    * @return                         the list of dcs as a string
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/12
    **********************************************************************************************/
    FUNCTION get_adm_indication_dcs_str
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_adm_indication      IN adm_indication.id_adm_indication%TYPE,
        i_id_adm_indication_hist IN adm_indication_hist.id_adm_indication_hist%TYPE
    ) RETURN VARCHAR2 IS
    
        --dcs description
        l_id_indication_dcs table_number := table_number();
        --
        l_str_final      VARCHAR2(1000 CHAR);
        l_str_length     PLS_INTEGER := 0;
        l_str_length_aux PLS_INTEGER := 0;
        l_str            VARCHAR2(1000 CHAR);
        l_item_count     PLS_INTEGER;
        --error
        l_error t_error_out;
    BEGIN
    
        --
    
        IF i_id_adm_indication IS NOT NULL
        THEN
            g_error := 'GET_ADM_INDICATION_DCS: i_id_adm_indication = ' || i_id_adm_indication;
            pk_alertlog.log_debug(g_error);
        
            SELECT aidcs.id_dep_clin_serv
              BULK COLLECT
              INTO l_id_indication_dcs
              FROM adm_indication ai
              JOIN adm_ind_dep_clin_serv aidcs
                ON (ai.id_adm_indication = aidcs.id_adm_indication)
             WHERE ai.id_adm_indication = i_id_adm_indication;
        ELSE
            SELECT aidh.id_dep_clin_serv
              BULK COLLECT
              INTO l_id_indication_dcs
              FROM adm_ind_dcs_hist aidh
             WHERE aidh.id_adm_indication_hist = i_id_adm_indication_hist
               AND aidh.flg_available = pk_alert_constant.g_yes;
        END IF;
        l_item_count := l_id_indication_dcs.count;
        --    
        IF l_item_count = 0
        THEN
            l_str_final := ' ';
        ELSE
            FOR i IN 1 .. l_item_count
            LOOP
                l_str := get_dcs_description(i_lang, i_prof, l_id_indication_dcs(i));
            
                l_str_length_aux := length(l_str) + 2;
                IF l_str_length + l_str_length_aux >= g_max_size_to_select
                THEN
                    l_str_final := l_str_final || substr(l_str, 0, g_max_size_to_select - l_str_length) ||
                                   g_not_complete;
                    EXIT;
                ELSE
                
                    IF i < l_item_count
                    THEN
                        l_str_final := l_str_final || l_str || ', ';
                    ELSE
                        l_str_final := l_str_final || l_str;
                    END IF;
                    l_str_length := l_str_length + l_str_length_aux;
                END IF;
            END LOOP;
        END IF;
    
        --
        RETURN l_str_final;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ADM_INDICATION_DCS_STR',
                                              l_error);
            RETURN NULL;
    END get_adm_indication_dcs_str;
    --

    /********************************************************************************************
    * Get the list dep. clinical service (dcs) as a string for a given admission indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication ID
    *
    * @return                         the list of dcs as a string
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/12
    **********************************************************************************************/
    FUNCTION get_adm_indication_dcs_array
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN table_table_varchar IS
    
        --dcs description
        l_id_indication_dcs table_number := table_number();
        --
        l_id_indication_dcs_str VARCHAR2(1000 CHAR);
        --
        l_dcs_list table_table_varchar := table_table_varchar();
        --format; [id_dcs, desc_service, desc_specialty]
        l_dcs_info table_varchar := table_varchar();
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'GET_ADM_INDICATION_DCS: i_id_adm_indication = ' || i_id_adm_indication;
        pk_alertlog.log_debug(g_error);
        --
    
        SELECT aidcs.id_dep_clin_serv
          BULK COLLECT
          INTO l_id_indication_dcs
          FROM adm_indication ai
          JOIN adm_ind_dep_clin_serv aidcs
            ON (ai.id_adm_indication = aidcs.id_adm_indication)
         WHERE ai.id_adm_indication = i_id_adm_indication;
    
        --    
        IF l_id_indication_dcs.count = 0
        THEN
            l_dcs_list := table_table_varchar();
        ELSE
            FOR i IN 1 .. l_id_indication_dcs.count
            LOOP
                l_dcs_info              := table_varchar();
                l_id_indication_dcs_str := get_dcs_description(i_lang, i_prof, l_id_indication_dcs(i), '-|-');
                --id_dcs
                l_dcs_info.extend;
                l_dcs_info(1) := to_char(l_id_indication_dcs(i));
                --desc_service
                l_dcs_info.extend;
                l_dcs_info(2) := substr(l_id_indication_dcs_str, 1, (instr(l_id_indication_dcs_str, '-|-') - 1));
                --esc_specialty
                l_dcs_info.extend;
                l_dcs_info(3) := substr(l_id_indication_dcs_str, (instr(l_id_indication_dcs_str, '-|-') + 3));
                --
                l_dcs_list.extend;
                l_dcs_list(i) := l_dcs_info; --l_dcs_info(1)||'|'||l_dcs_info(2)||'|'||l_dcs_info(3);
            END LOOP;
        END IF;
    
        --
        RETURN l_dcs_list;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ADM_INDICATION_DCS_STR',
                                              l_error);
            RETURN NULL;
    END get_adm_indication_dcs_array;
    --

    /********************************************************************************************
    * Get the Indications for admission data for the create/edit screen
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication data   
    * @param o_indications            List of indications
    * @param o_indications_nch        NCH for the given indications
    * @param o_screen_labels          Screen labels
    * @param o_selected_dcs           Selected dep_clin_serv's
    * @param o_selected_serv          Selected services
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/12
    **********************************************************************************************/
    FUNCTION get_adm_indication_edit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_indications       OUT pk_types.cursor_type,
        o_indications_nch   OUT pk_types.cursor_type,
        o_screen_labels     OUT pk_types.cursor_type,
        o_selected_dcs      OUT pk_types.cursor_type,
        o_selected_serv     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        g_error := 'GET_ADM_INDICATION_EDIT: GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --
        OPEN o_screen_labels FOR
            SELECT pk_message.get_message(i_lang, 'ADMINISTRATOR_T647') main_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T648') sub_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T653') grid_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T654') period_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T655') startday_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T656') numhours_column_header,
                   pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                             'ADMINISTRATOR_T657'),
                                                                      pk_alert_constant.g_yes,
                                                                      pk_alert_constant.g_yes) nch_1row_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T658') nch_2row_header,
                   pk_message.get_message(i_lang, 'BMNG_T126') week_msg,
                   pk_message.get_message(i_lang, 'BMNG_T127') weeks_msg,
                   pk_message.get_message(i_lang, 'BMNG_T128') day_msg,
                   pk_message.get_message(i_lang, 'BMNG_T129') days_msg,
                   pk_message.get_message(i_lang, 'BMNG_T130') hour_msg,
                   pk_message.get_message(i_lang, 'BMNG_T131') hours_msg,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T228') all_msg,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T053') none_msg
              FROM dual;
    
        --
        g_error := 'GET_ADM_INDICATION_EDIT: GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --
        IF i_id_adm_indication IS NULL
        THEN
            --create new indication
            OPEN o_indications FOR
                SELECT NULL id_indication,
                       NULL flg_escape,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) indication_adm_name_title,
                       NULL indication_adm_name_desc,
                       NULL indication_adm_name_flg,
                       --services
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T649'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) indication_adm_services_title,
                       NULL indication_adm_services_desc,
                       NULL indication_adm_services_flg,
                       --pref_service
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T646'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) indication_pref_service_title,
                       NULL indication_pref_service_desc,
                       NULL indication_pref_service_flg,
                       --escape_service
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T650'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) indication_esc_service_title,
                       NULL indication_esc_service_desc,
                       NULL indication_esc_service_flg,
                       --urg_level
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T651'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) indication_urg_level_title,
                       NULL indication_urg_level_desc,
                       NULL indication_urg_level_flg,
                       --expected duration
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T652'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) indication_exp_duration_title,
                       NULL indication_exp_duration_desc,
                       NULL indication_exp_duration_flg,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) indication_state_title,
                       pk_sysdomain.get_domain('ADM_INDICATION.FLG_AVAILABLE', pk_alert_constant.g_yes, i_lang) indication_state_desc,
                       pk_alert_constant.g_yes indication_state_flg
                  FROM dual;
        
            OPEN o_indications_nch FOR
                SELECT NULL id_indication,
                       --always 1!
                       1    indication_nch_1_startday,
                       NULL indication_nch_1_n_hours,
                       NULL indication_nch_2_startday,
                       NULL indication_nch_2_n_hours
                  FROM dual;
        
            pk_types.open_my_cursor(o_selected_dcs);
            pk_types.open_my_cursor(o_selected_serv);
        
        ELSE
            --edit an exsting indication
            OPEN o_indications FOR
                SELECT ai.id_adm_indication id_indication,
                       ai.flg_escape        flg_escape,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) indication_adm_name_title,
                       nvl(ai.desc_adm_indication, pk_translation.get_translation(i_lang, ai.code_adm_indication)) indication_adm_name_desc,
                       nvl(ai.desc_adm_indication, pk_translation.get_translation(i_lang, ai.code_adm_indication)) indication_adm_name_flg,
                       --services
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T649'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) indication_adm_services_title,
                       get_adm_indication_dcs_str(i_lang, i_prof, i_id_adm_indication, NULL) indication_adm_services_desc,
                       get_adm_indication_dcs(i_lang, i_prof, ai.id_adm_indication) indication_adm_services_flg,
                       --pref_service
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T646'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) indication_pref_service_title,
                       get_dcs_description(i_lang,
                                           i_prof,
                                           get_adm_indication_pref_dcs(i_lang, i_prof, ai.id_adm_indication)) indication_pref_service_desc,
                       get_adm_indication_pref_dcs(i_lang, i_prof, ai.id_adm_indication) indication_pref_service_flg,
                       --escape_services
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T650'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) indication_esc_service_title,
                       get_escape_services_list_str(i_lang, i_prof, i_id_adm_indication) indication_esc_service_desc,
                       get_escape_services_list(i_lang, i_prof, i_id_adm_indication) indication_esc_service_flg,
                       --urg_level
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T651'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) indication_urg_level_title,
                       nvl(wul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, wul.code)) indication_urg_level_desc,
                       ai.id_wtl_urg_level indication_urg_level_flg,
                       --expected duration
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T652'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) indication_exp_duration_title,
                       ai.avg_duration indication_exp_duration_desc,
                       ai.avg_duration indication_exp_duration_flg,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) indication_state_title,
                       pk_sysdomain.get_domain('ADM_INDICATION.FLG_AVAILABLE', ai.flg_available, i_lang) indication_state_desc,
                       ai.flg_available indication_state_flg
                  FROM adm_indication ai
                  LEFT JOIN wtl_urg_level wul
                    ON (wul.id_wtl_urg_level = ai.id_wtl_urg_level)
                 WHERE ai.id_adm_indication = i_id_adm_indication;
        
            -- 
            OPEN o_indications_nch FOR
                SELECT ai.id_adm_indication id_indication,
                       1 indication_nch_1_startday,
                       nl.value indication_nch_1_n_hours,
                       (nl.duration + 1) indication_nch_2_startday,
                       nl2.value indication_nch_2_n_hours
                  FROM adm_indication ai
                  JOIN nch_level nl
                    ON (ai.id_nch_level = nl.id_nch_level)
                  LEFT JOIN nch_level nl2
                    ON (nl.id_nch_level = nl2.id_previous)
                 WHERE ai.id_adm_indication = i_id_adm_indication;
            --
            OPEN o_selected_dcs FOR
                SELECT *
                  FROM TABLE(get_adm_indication_dcs_array(i_lang, i_prof, i_id_adm_indication));
        
            OPEN o_selected_serv FOR
                SELECT dcs.id_dep_clin_serv, dcs.id_department
                  FROM adm_indication ai
                  JOIN adm_ind_dep_clin_serv aidcs
                    ON (ai.id_adm_indication = aidcs.id_adm_indication)
                  JOIN dep_clin_serv dcs
                    ON (aidcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
                 WHERE ai.id_adm_indication = i_id_adm_indication;
        
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_screen_labels);
            pk_types.open_my_cursor(o_indications);
            pk_types.open_my_cursor(o_indications_nch);
            pk_types.open_my_cursor(o_selected_dcs);
            pk_types.open_my_cursor(o_selected_serv);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_ADM_INDICATION_EDIT',
                                                     o_error);
        
    END get_adm_indication_edit;
    --

    /********************************************************************************************
    * Get the list of services that are available in the instituion 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_institution         Institution ID
    * @param o_services_list          List of services
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/13
    **********************************************************************************************/
    FUNCTION get_services_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_services_list  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET DEPARTMENT_LIST CURSOR';
        OPEN o_services_list FOR
            SELECT id_service, service_name, bed_permission
              FROM (SELECT d.id_department id_service,
                           (pk_translation.get_translation(i_lang, d.code_department) || --
                           ' ' || pk_message.get_message(i_lang, 'ADM_REQUEST_T081') || ' ' || --
                           pk_translation.get_translation(i_lang, dp.code_dept)) service_name,
                           --Tipo: C - consulta externa, U - urgÍncia, I - internamento, S - bloco operatÛrio, A - Lab. an·lises, P - Lab. patologia clÌnica, T - Lab. anatomia patolÛgica, R - radiologia, F - farm·cia, W- Waiting Room. 
                           --Pode conter combinaÁıes (ex: AP - lab an·lises de patologia clÌnica)
                           CASE
                                WHEN d.flg_type = g_department_urg THEN
                                 pk_alert_constant.g_yes
                                WHEN d.flg_type = g_department_inp THEN
                                 pk_alert_constant.g_yes
                                WHEN d.flg_type = g_department_obs THEN
                                 pk_alert_constant.g_yes
                                ELSE
                                 pk_alert_constant.g_no
                            END bed_permission
                      FROM department d
                      JOIN dept dp
                        ON dp.id_dept = d.id_dept
                     WHERE d.id_institution = i_id_institution
                       AND d.flg_available = pk_alert_constant.g_yes)
             WHERE service_name IS NOT NULL
             ORDER BY service_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_services_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_SERVICES_LIST',
                                                     o_error);
        
    END get_services_list;
    --

    /********************************************************************************************
    * Get the list of specialties available for a given service
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_service             Service ID
    * @param i_id_institution         Institution ID
    * @param o_specialty_list         List of specialties
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/13
    **********************************************************************************************/
    FUNCTION get_specialties_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_service     IN department.id_department%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_search         IN VARCHAR2,
        o_specialty_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_SPECIALTIES_LIST CURSOR';
        IF i_search IS NULL
        THEN
            OPEN o_specialty_list FOR
                SELECT cs.id_clinical_service id_specialty,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_specialty,
                       d.id_department id_service,
                       pk_translation.get_translation(i_lang, d.code_department) desc_service,
                       dcs.id_dep_clin_serv id_dcs,
                       get_dcs_description(i_lang, i_prof, dcs.id_dep_clin_serv, '<br>') desc_dcs
                  FROM dep_clin_serv dcs
                  JOIN clinical_service cs
                    ON (dcs.id_clinical_service = cs.id_clinical_service)
                  JOIN department d
                    ON (dcs.id_department = d.id_department)
                 WHERE cs.flg_available = pk_alert_constant.g_yes
                   AND dcs.flg_available = pk_alert_constant.g_yes
                   AND dcs.id_department = i_id_service
                   AND pk_translation.get_translation(i_lang, cs.code_clinical_service) IS NOT NULL
                   AND d.id_institution = i_id_institution
                 ORDER BY desc_specialty;
        ELSE
            OPEN o_specialty_list FOR
                SELECT cs.id_clinical_service id_specialty,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_specialty,
                       d.id_department id_service,
                       pk_translation.get_translation(i_lang, d.code_department) desc_service,
                       dcs.id_dep_clin_serv id_dcs,
                       get_dcs_description(i_lang, i_prof, dcs.id_dep_clin_serv, '<br>') desc_dcs
                  FROM dep_clin_serv dcs
                  JOIN clinical_service cs
                    ON (dcs.id_clinical_service = cs.id_clinical_service)
                  JOIN department d
                    ON (dcs.id_department = d.id_department)
                 WHERE cs.flg_available = pk_alert_constant.g_yes
                   AND dcs.flg_available = pk_alert_constant.g_yes
                   AND translate(upper(pk_translation.get_translation(i_lang, cs.code_clinical_service)),
                                 '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ',
                                 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' || translate(upper(i_search), '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
                   AND pk_translation.get_translation(i_lang, cs.code_clinical_service) IS NOT NULL
                   AND d.id_institution = i_id_institution
                 ORDER BY desc_specialty;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_specialty_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_SPECIALTIES_LIST',
                                                     o_error);
        
    END get_specialties_list;
    --

    /********************************************************************************************
    * Get the list of specialties (detailed information) for a given array of DCSs
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_dcs                 array with DCSs IDs 
    * @param i_id_institution         Institution ID
    * @param o_specialties_list       List of specialties
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/02
    **********************************************************************************************/
    FUNCTION get_specialties_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_dcs         IN table_number,
        i_id_institution IN institution.id_institution%TYPE,
        o_specialty_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_SPECIALTIES_LIST CURSOR';
    
        OPEN o_specialty_list FOR
            SELECT cs.id_clinical_service id_specialty,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_specialty,
                   d.id_department id_service,
                   pk_translation.get_translation(i_lang, d.code_department) desc_service,
                   dcs.id_dep_clin_serv id_dcs,
                   get_dcs_description(i_lang, i_prof, dcs.id_dep_clin_serv, '<br>') desc_dcs
              FROM dep_clin_serv dcs
              JOIN clinical_service cs
                ON (dcs.id_clinical_service = cs.id_clinical_service)
              JOIN department d
                ON (dcs.id_department = d.id_department)
             WHERE dcs.id_dep_clin_serv IN (SELECT column_value
                                              FROM TABLE(i_id_dcs))
               AND cs.flg_available = pk_alert_constant.g_yes
               AND dcs.flg_available = pk_alert_constant.g_yes
               AND pk_translation.get_translation(i_lang, cs.code_clinical_service) IS NOT NULL
               AND d.id_institution = i_id_institution
             ORDER BY desc_specialty;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_specialty_list);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_SPECIALTIES_LIST',
                                                     o_error);
        
    END get_specialties_list;
    --

    /********************************************************************************************
    * Set admission indication.
    * This function allows the create of new indication (i_adm_indication = null) or the 
    * edit of an existing indication.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_adm_indication        Adm_indication ID (not null only for the edit operation)
    * @ param i_name                  Indication name
    * @ param i_services              List of serices for the indication
    * @ param i_pref_service          Preferential service 
    * @ param i_esc_services          List of escape services
    * @ param i_flg_escape            Flag that indicates the possible escape services: A - all, N - none, E - other
    * @ param i_urg_level             Urgency level
    * @ param i_exp_duration          Expected duration of admission
    * @ param i_state                 Indication state
    * @ param i_nch_1_startday        NCH startday for the first period
    * @ param i_nch_1_n_hours         NCH number of hours for the first period
    * @ param i_nch_2_startday        NCH startday for the second period
    * @ param i_nch_2_n_hours         NCH number of hours for the second period
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/14
    **********************************************************************************************/
    FUNCTION set_adm_indication
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        --
        i_name                 IN adm_indication.code_adm_indication%TYPE,
        i_services             IN table_number,
        i_pref_service         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_esc_services         IN table_number,
        i_flg_escape           IN adm_indication.flg_escape%TYPE,
        i_urg_level            IN adm_indication.id_wtl_urg_level%TYPE,
        i_exp_duration         IN adm_indication.avg_duration%TYPE,
        i_state                IN adm_indication.flg_available%TYPE,
        i_nch_1_startday       IN nch_level.value%TYPE,
        i_nch_1_n_hours        IN nch_level.duration%TYPE,
        i_nch_2_startday       IN nch_level.value%TYPE,
        i_nch_2_n_hours        IN nch_level.duration%TYPE,
        i_adm_indication_multi IN adm_indication.id_adm_indication%TYPE,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_adm_indication adm_indication.id_adm_indication%TYPE;
    
        l_nch_level_previous nch_level.id_nch_level%TYPE;
        l_nch_level_not_used nch_level.id_nch_level%TYPE;
        l_nch_1_duration     nch_level.duration%TYPE;
        --
        --dcs
        l_cur_dcs_list table_number := table_number();
        l_new_dcs_list table_number := table_number();
        --escape services
        l_cur_esc_services_list table_number := table_number();
        l_new_esc_services_list table_number := table_number();
        --nch_level
        l_nch_level_id nch_level.id_nch_level%TYPE;
        --
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_adm_indication_row adm_indication%ROWTYPE;
    
        l_id_adm_indication_hist adm_indication_hist.id_adm_indication_hist%TYPE;
    
        l_inst_group institution_group.id_group%TYPE;
    BEGIN
        --
        g_error := 'SET_ADM_INDICATION: i_adm_indication=' || i_adm_indication || ', i_name=' || i_name ||
                   ', i_pref_service' || i_pref_service || ', i_urg_level=' || i_urg_level || ', i_state=' || i_state ||
                   ', i_nch_1_startday=' || i_nch_1_startday || ', i_nch_1_n_hours=' || i_nch_1_n_hours ||
                   ', i_nch_2_startday=' || i_nch_2_startday || ', i_nch_2_n_hours=' || i_nch_2_n_hours;
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_nch_1_startday IS NOT NULL
           AND i_nch_2_startday IS NOT NULL
        THEN
            l_nch_1_duration := i_nch_2_startday - i_nch_1_startday;
        ELSE
            l_nch_1_duration := NULL;
        END IF;
    
        --create new ADM_INDICATION
        IF i_adm_indication IS NULL
        THEN
            pk_alertlog.log_debug('CREATE NEW ADM_INDICATION');
            --
            --create NCH:
            IF i_nch_1_n_hours IS NOT NULL
            THEN
                pk_alertlog.log_debug('FOUND and create the NHC first period for the ADM_INDICATION = ' ||
                                      i_adm_indication);
            
                IF NOT create_nch_periods(i_lang,
                                          i_prof,
                                          g_nch_1_period,
                                          l_nch_1_duration,
                                          i_nch_1_n_hours,
                                          NULL,
                                          l_nch_level_previous,
                                          o_error)
                THEN
                    RAISE g_exception;
                END IF;
                --
                pk_alertlog.log_debug('First period found and created successfully for the indication' ||
                                      i_adm_indication);
            
                IF i_nch_2_n_hours IS NOT NULL
                THEN
                    pk_alertlog.log_debug('FOUND and create the NHC second period for the ADM_INDICATION = ' ||
                                          i_adm_indication);
                    IF NOT create_nch_periods(i_lang,
                                              i_prof,
                                              g_nch_2_period,
                                              NULL,
                                              i_nch_2_n_hours,
                                              l_nch_level_previous,
                                              l_nch_level_not_used,
                                              o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            END IF;
            --
            pk_alertlog.log_debug('INSERT INTO adm_indication');
        
            IF i_adm_indication_multi IS NULL
            THEN
            
                l_id_adm_indication := ts_adm_indication.next_key;
            
                BEGIN
                    SELECT a.id_group
                      INTO l_inst_group
                      FROM institution_group a
                     WHERE id_institution = i_id_institution
                       AND a.flg_relation = 'INST_CNT';
                EXCEPTION
                    WHEN OTHERS THEN
                        l_inst_group := NULL;
                END;
            
                ts_adm_indication.ins(id_adm_indication_in         => l_id_adm_indication,
                                      avg_duration_in              => i_exp_duration,
                                      id_wtl_urg_level_in          => i_urg_level,
                                      id_nch_level_in              => l_nch_level_previous,
                                      flg_escape_in                => i_flg_escape,
                                      id_institution_in            => i_id_institution,
                                      code_adm_indication_in       => NULL, --l_adm_indication_code || l_id_adm_indication,
                                      flg_available_in             => i_state,
                                      flg_parameterization_type_in => g_backoffice_parameterization,
                                      flg_status_in                => pk_alert_constant.g_flg_status_a,
                                      id_professional_in           => i_prof.id,
                                      dt_creation_in               => g_sysdate_tstz,
                                      dt_last_update_in            => g_sysdate_tstz,
                                      desc_adm_indication_in       => i_name,
                                      id_group_in                  => l_inst_group,
                                      rows_out                     => l_rows_out);
                --                    
                g_error := 'CALL t_data_gov_mnt.process_insert';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ADM_INDICATION',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
                --
                --pk_translation.insert_into_translation(i_lang       => i_lang,
                --                                       i_code_trans => l_adm_indication_code || l_id_adm_indication,
                --                                       i_desc_trans => i_name);
            
                l_id_adm_indication_hist := seq_adm_indication_hist.nextval;
            
                --history
                INSERT INTO adm_indication_hist
                    (id_adm_indication_hist,
                     id_adm_indication,
                     avg_duration,
                     id_wtl_urg_level,
                     id_nch_level,
                     flg_escape,
                     id_institution,
                     code_adm_indication,
                     flg_available,
                     flg_parameterization_type,
                     flg_status,
                     id_professional,
                     dt_creation,
                     dt_last_update,
                     desc_adm_indication,
                     preferred_dcs_id,
                     nch_value_1_period,
                     nch_duration_1_period,
                     nch_value_2_period,
                     nch_duration_2_period)
                VALUES
                    (l_id_adm_indication_hist,
                     l_id_adm_indication,
                     i_exp_duration,
                     i_urg_level,
                     l_nch_level_previous,
                     i_flg_escape,
                     i_id_institution,
                     NULL, --l_adm_indication_code || l_id_adm_indication,
                     i_state,
                     g_backoffice_parameterization,
                     pk_alert_constant.g_flg_status_a,
                     i_prof.id,
                     g_sysdate_tstz,
                     g_sysdate_tstz,
                     i_name,
                     i_pref_service,
                     1,
                     i_nch_1_n_hours,
                     i_nch_2_startday,
                     i_nch_2_n_hours);
            
                --
                pk_alertlog.log_debug('CREATE NEW ADM_INDICATION PARAMETERIZATION');
                --
            
            END IF;
            IF i_adm_indication_multi IS NOT NULL
            THEN
                l_id_adm_indication := i_adm_indication_multi;
            END IF;
        
            IF i_services IS NOT NULL
               AND i_services.count > 0
            THEN
                FOR i IN 1 .. i_services.count
                LOOP
                    pk_alertlog.log_debug('INSERT INTO ADM_IND_DEP_CLIN_SERV: i_services' || i_services(i));
                    INSERT INTO adm_ind_dep_clin_serv
                        (id_adm_indication, id_dep_clin_serv, flg_available, flg_pref)
                    VALUES
                        (l_id_adm_indication,
                         i_services(i),
                         pk_alert_constant.g_yes,
                         decode(i_pref_service, i_services(i), pk_alert_constant.g_yes, pk_alert_constant.g_no));
                
                    IF i_adm_indication_multi IS NULL
                    THEN
                    
                        ts_adm_ind_dcs_hist.ins(id_adm_indication_hist_in => l_id_adm_indication_hist,
                                                id_adm_indication_in      => l_id_adm_indication,
                                                id_dep_clin_serv_in       => i_services(i),
                                                flg_available_in          => pk_alert_constant.g_yes,
                                                flg_pref_in               => pk_alert_constant.g_no,
                                                rows_out                  => l_rows_out);
                    END IF;
                END LOOP;
            END IF;
        
            pk_alertlog.log_debug('CREATE NEW ADM_INDICATION ESCAPE SERVICES');
            --
            IF i_esc_services IS NOT NULL
               AND i_esc_services.count > 0
            THEN
                FOR i IN 1 .. i_esc_services.count
                LOOP
                    pk_alertlog.log_debug('INSERT INTO ESCAPE_DEPARTMENTS: i_esc_services' || i_esc_services(i));
                
                    INSERT INTO escape_department
                        (id_department, id_adm_indication)
                    VALUES
                        (i_esc_services(i), l_id_adm_indication);
                
                    IF i_adm_indication_multi IS NULL
                    THEN
                        ts_escape_department_hist.ins(id_adm_indication_hist_in => l_id_adm_indication_hist,
                                                      id_department_in          => i_esc_services(i),
                                                      id_adm_indication_in      => l_id_adm_indication,
                                                      rows_out                  => l_rows_out);
                    END IF;
                END LOOP;
            
            END IF;
            --
        ELSE
            pk_alertlog.log_debug('EDITING AN EXISTING ADM_INDICATION: i_adm_indication=' || i_adm_indication);
        
            l_nch_level_id := get_adm_indication_nch(i_lang, i_prof, i_adm_indication);
            --
            pk_alertlog.log_debug('UPDATE adm_indication');
        
            --
            ts_adm_indication.upd(id_adm_indication_in   => i_adm_indication,
                                  avg_duration_in        => i_exp_duration,
                                  id_wtl_urg_level_in    => i_urg_level,
                                  flg_available_in       => i_state,
                                  flg_escape_in          => i_flg_escape,
                                  flg_status_in          => pk_alert_constant.g_flg_status_e,
                                  desc_adm_indication_in => i_name,
                                  dt_last_update_in      => g_sysdate_tstz,
                                  rows_out               => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ADM_INDICATION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --pk_translation.insert_into_translation(i_lang       => i_lang,
            --                                       i_code_trans => l_adm_indication_code || i_adm_indication,
            --                                      i_desc_trans => i_name);
        
            --history
            SELECT *
              INTO l_adm_indication_row
              FROM adm_indication ap
             WHERE ap.id_adm_indication = i_adm_indication;
        
            l_id_adm_indication_hist := seq_adm_indication_hist.nextval;
        
            --history
            INSERT INTO adm_indication_hist
                (id_adm_indication_hist,
                 id_adm_indication,
                 avg_duration,
                 id_wtl_urg_level,
                 id_nch_level,
                 flg_escape,
                 id_institution,
                 code_adm_indication,
                 flg_available,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_adm_indication,
                 preferred_dcs_id,
                 nch_value_1_period,
                 nch_duration_1_period,
                 nch_value_2_period,
                 nch_duration_2_period)
            VALUES
                (l_id_adm_indication_hist,
                 i_adm_indication,
                 i_exp_duration,
                 i_urg_level,
                 l_nch_level_id,
                 i_flg_escape,
                 i_id_institution,
                 l_adm_indication_row.code_adm_indication, --l_adm_indication_code || i_adm_indication,
                 i_state,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_e,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 i_name,
                 i_pref_service,
                 1, --constant value
                 i_nch_1_n_hours,
                 i_nch_2_startday,
                 i_nch_2_n_hours);
        
            ------------------------
        
            --
            --new_list_of_dcs - delete the ones that are not being used, and create the new ones.
            l_cur_dcs_list := get_adm_indication_dcs(i_lang, i_prof, i_adm_indication);
            IF l_cur_dcs_list IS NOT NULL
               AND i_services IS NOT NULL
            THEN
                --delete not used dcs
                l_new_dcs_list := l_cur_dcs_list MULTISET except i_services;
                IF l_new_dcs_list IS NOT NULL
                   AND l_new_dcs_list.count > 0
                   AND i_adm_indication_multi IS NULL
                THEN
                    FOR i IN 1 .. l_new_dcs_list.count
                    LOOP
                        pk_alertlog.log_debug('DELETE NOT USED DCS FROM ADM_IND_DEP_CLIN_SERV: l_new_dcs_list' ||
                                              l_new_dcs_list(i));
                        DELETE FROM adm_ind_dep_clin_serv aidcs
                         WHERE aidcs.id_adm_indication = i_adm_indication
                           AND aidcs.id_dep_clin_serv = l_new_dcs_list(i)
                           AND EXISTS
                         (SELECT 1
                                  FROM dep_clin_serv t
                                 WHERE aidcs.id_dep_clin_serv = t.id_dep_clin_serv
                                   AND id_department IN (SELECT id_department
                                                           FROM department
                                                          WHERE id_institution IN (i_prof.institution)));
                    END LOOP;
                END IF;
                --
                --create the new dcs
                l_new_dcs_list := i_services MULTISET except l_cur_dcs_list;
                IF l_new_dcs_list IS NOT NULL
                   AND l_new_dcs_list.count > 0
                THEN
                    FOR i IN 1 .. l_new_dcs_list.count
                    LOOP
                        pk_alertlog.log_debug('INSERT INTO ADM_IND_DEP_CLIN_SERV_2: l_new_dcs_list' ||
                                              l_new_dcs_list(i));
                    
                        --If a new prefered service isn't the one is stored remove the preference to comply the unique index 'AIDCS_FPREF_UK' in ALERT-178226
                        IF i_pref_service = l_new_dcs_list(i)
                           AND i_adm_indication_multi IS NULL
                        THEN
                            --Remove all prefered services
                            UPDATE adm_ind_dep_clin_serv aidcs
                               SET aidcs.flg_pref = pk_alert_constant.g_no
                             WHERE aidcs.id_adm_indication = i_adm_indication
                               AND EXISTS (SELECT 1
                                      FROM dep_clin_serv t
                                     WHERE aidcs.id_dep_clin_serv = t.id_dep_clin_serv
                                       AND id_department IN
                                           (SELECT id_department
                                              FROM department
                                             WHERE id_institution IN (i_prof.institution)));
                        END IF;
                    
                        INSERT INTO adm_ind_dep_clin_serv
                            (id_adm_indication, id_dep_clin_serv, flg_available, flg_pref)
                        VALUES
                            (i_adm_indication,
                             l_new_dcs_list(i),
                             pk_alert_constant.g_yes,
                             decode(i_pref_service, l_new_dcs_list(i), pk_alert_constant.g_yes, pk_alert_constant.g_no));
                    END LOOP;
                END IF;
            ELSE
                NULL;
            END IF;
        
            IF i_services IS NOT NULL
               AND i_services.count > 0
            THEN
                FOR i IN 1 .. i_services.count
                LOOP
                    ts_adm_ind_dcs_hist.ins(id_adm_indication_hist_in => l_id_adm_indication_hist,
                                            id_adm_indication_in      => i_adm_indication,
                                            id_dep_clin_serv_in       => i_services(i),
                                            flg_available_in          => pk_alert_constant.g_yes,
                                            flg_pref_in               => pk_alert_constant.g_no,
                                            rows_out                  => l_rows_out);
                END LOOP;
            END IF;
        
            --Prefered service:
            IF get_adm_indication_pref_dcs(i_lang, i_prof, i_adm_indication) <> i_pref_service
            THEN
                --Remove all prefered services
                UPDATE adm_ind_dep_clin_serv aidcs
                   SET aidcs.flg_pref = pk_alert_constant.g_no
                 WHERE aidcs.id_adm_indication = i_adm_indication
                   AND EXISTS
                 (SELECT 1
                          FROM dep_clin_serv t
                         WHERE aidcs.id_dep_clin_serv = t.id_dep_clin_serv
                           AND id_department IN (SELECT id_department
                                                   FROM department
                                                  WHERE id_institution IN (i_prof.institution)));
                --and set the new one
                UPDATE adm_ind_dep_clin_serv aidcs
                   SET aidcs.flg_pref = pk_alert_constant.g_yes
                 WHERE aidcs.id_adm_indication = i_adm_indication
                   AND aidcs.id_dep_clin_serv = i_pref_service;
            END IF;
        
            --new_list_of_serv_escape_services - delete the ones that are not being used, and create the new ones.
            l_cur_esc_services_list := get_adm_ind_esc_services(i_lang, i_prof, i_adm_indication);
            IF l_cur_esc_services_list IS NOT NULL
               AND i_esc_services IS NOT NULL
            THEN
                --delete not used escape services
            
                IF i_adm_indication_multi IS NULL
                THEN
                    l_new_esc_services_list := l_cur_esc_services_list MULTISET except i_esc_services;
                    IF l_new_esc_services_list IS NOT NULL
                       AND l_new_esc_services_list.count > 0
                    THEN
                        FOR i IN 1 .. l_new_esc_services_list.count
                        LOOP
                            pk_alertlog.log_debug('DELETE NOT USED ESCAPE_SERVICES FROM ESCAPE_DEPARTMENT: l_new_esc_services_list' ||
                                                  l_new_esc_services_list(i));
                            DELETE FROM escape_department ed
                             WHERE ed.id_adm_indication = i_adm_indication
                               AND ed.id_department = l_new_esc_services_list(i)
                               AND EXISTS (SELECT 1
                                      FROM department
                                     WHERE id_institution IN (i_prof.institution)
                                       AND id_department = ed.id_department);
                        END LOOP;
                    END IF;
                END IF;
                --
            
                --create the new dcs
                l_new_esc_services_list := i_esc_services MULTISET except l_cur_esc_services_list;
                IF l_new_esc_services_list IS NOT NULL
                   AND l_new_esc_services_list.count > 0
                THEN
                    FOR i IN 1 .. l_new_esc_services_list.count
                    LOOP
                        pk_alertlog.log_debug('INSERT INTO ESCAPE_DEPARTMENT_2: l_new_esc_services_list' ||
                                              l_new_esc_services_list(i));
                        INSERT INTO escape_department
                            (id_department, id_adm_indication)
                        VALUES
                            (l_new_esc_services_list(i), i_adm_indication);
                    END LOOP;
                END IF;
            
            ELSE
                NULL;
            END IF;
        
            IF i_esc_services IS NOT NULL
               AND i_esc_services.count > 0
            THEN
                FOR i IN 1 .. i_esc_services.count
                LOOP
                    ts_escape_department_hist.ins(id_adm_indication_hist_in => l_id_adm_indication_hist,
                                                  id_department_in          => i_esc_services(i),
                                                  id_adm_indication_in      => i_adm_indication,
                                                  rows_out                  => l_rows_out);
                END LOOP;
            END IF;
        
            --UPDATE NCH periods
            IF l_nch_level_id IS NOT NULL
            THEN
                IF NOT update_nch_periods(i_lang,
                                          i_prof,
                                          l_nch_level_id,
                                          l_nch_1_duration,
                                          i_nch_1_n_hours,
                                          i_nch_2_n_hours,
                                          o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSE
                --we shouldn't get here because we are editing the indication, but if we do so, Fix the problem and create the NCH
                IF NOT create_nch_periods(i_lang,
                                          i_prof,
                                          g_nch_1_period,
                                          l_nch_1_duration,
                                          i_nch_1_n_hours,
                                          NULL,
                                          l_nch_level_previous,
                                          o_error)
                THEN
                    RAISE g_exception;
                END IF;
                IF NOT update_nch_periods(i_lang,
                                          i_prof,
                                          l_nch_level_previous,
                                          l_nch_1_duration,
                                          i_nch_1_n_hours,
                                          i_nch_2_n_hours,
                                          o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_ADM_INDICATION',
                                                     o_error);
        
    END set_adm_indication;
    --

    /********************************************************************************************
    * Set of a new Admission indication state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_adm_indication        Adm_indication ID (not null only for the edit operation)
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/14
    **********************************************************************************************/
    FUNCTION set_adm_indication_state
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        --
        i_state IN adm_indication.flg_available%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_adm_indication_row adm_indication%ROWTYPE;
    
        l_id_adm_indication_hist adm_indication_hist.id_adm_indication_hist%TYPE;
    
        l_services     table_number;
        l_esc_services table_number;
    BEGIN
        --
        g_error := 'SET_ADM_INDICATION_STATE: i_adm_indication=' || i_id_adm_indication || ', i_state=' || i_state;
        pk_alertlog.log_debug(g_error);
    
        IF i_id_adm_indication IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            g_error := 'UPDATE ADM_INDICATION_STATE';
            pk_alertlog.log_debug(g_error);
            --
            g_sysdate_tstz := current_timestamp;
            --
            ts_adm_indication.upd(id_adm_indication_in => i_id_adm_indication,
                                  flg_available_in     => i_state,
                                  flg_status_in        => pk_alert_constant.g_flg_status_e,
                                  dt_last_update_in    => g_sysdate_tstz,
                                  rows_out             => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ADM_INDICATION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --history
            SELECT *
              INTO l_adm_indication_row
              FROM adm_indication ap
             WHERE ap.id_adm_indication = i_id_adm_indication;
        
            l_id_adm_indication_hist := seq_adm_indication_hist.nextval;
            --history
            INSERT INTO adm_indication_hist
                (id_adm_indication_hist,
                 id_adm_indication,
                 avg_duration,
                 id_wtl_urg_level,
                 id_nch_level,
                 flg_escape,
                 id_institution,
                 code_adm_indication,
                 flg_available,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_adm_indication)
            VALUES
                (l_id_adm_indication_hist,
                 i_id_adm_indication,
                 l_adm_indication_row.avg_duration,
                 l_adm_indication_row.id_wtl_urg_level,
                 l_adm_indication_row.id_nch_level,
                 l_adm_indication_row.flg_escape,
                 l_adm_indication_row.id_institution,
                 l_adm_indication_row.code_adm_indication,
                 i_state,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_e,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 l_adm_indication_row.desc_adm_indication);
        
            l_services := get_adm_indication_dcs(i_lang, i_prof, i_id_adm_indication);
            IF l_services IS NOT NULL
               AND l_services.count > 0
            THEN
                FOR i IN 1 .. l_services.count
                LOOP
                    ts_adm_ind_dcs_hist.ins(id_adm_indication_hist_in => l_id_adm_indication_hist,
                                            id_adm_indication_in      => i_id_adm_indication,
                                            id_dep_clin_serv_in       => l_services(i),
                                            flg_available_in          => pk_alert_constant.g_yes,
                                            flg_pref_in               => pk_alert_constant.g_no,
                                            rows_out                  => l_rows_out);
                END LOOP;
            END IF;
        
            l_esc_services := get_adm_ind_esc_services(i_lang, i_prof, i_id_adm_indication);
            IF l_esc_services IS NOT NULL
               AND l_esc_services.count > 0
            THEN
                FOR i IN 1 .. l_esc_services.count
                LOOP
                    ts_escape_department_hist.ins(id_adm_indication_hist_in => l_id_adm_indication_hist,
                                                  id_department_in          => l_esc_services(i),
                                                  id_adm_indication_in      => i_id_adm_indication,
                                                  rows_out                  => l_rows_out);
                END LOOP;
            END IF;
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_ADM_INDICATION_STATE',
                                                     o_error);
        
    END set_adm_indication_state;
    --

    /********************************************************************************************
    * Cancel an NCH perido for a given admission indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_adm_indication     Adm_indication ID (not null only for the edit operation)
    * @ param i_nch_period            NHC period: F - first, S - second
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/14
    **********************************************************************************************/
    FUNCTION cancel_adm_ind_nch_period
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_nch_period        IN VARCHAR2 DEFAULT 'S',
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_nch_level nch_level.id_nch_level%TYPE;
    BEGIN
        --
        g_error := 'cancel_adm_ind_nch_period: i_id_adm_indication=' || i_id_adm_indication || ', i_nch_period=' ||
                   i_nch_period;
        pk_alertlog.log_debug(g_error);
    
        IF i_id_adm_indication IS NULL
           OR i_nch_period IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSIF i_nch_period <> 'S'
        THEN
            raise_application_error(-20100, 'Cannot cancel this NHC period');
        ELSE
            g_error := 'DELETE THE NCH ADM_INDICATION_STATE';
            --Only the second period can be deleted(canceled), but the function can received 
            -- the parameter that indicates which nhc period should be canceled for futur use.
            --The NCH periods are not in table form, so a String was used!
            BEGIN
                SELECT (SELECT n2.id_nch_level
                          FROM nch_level n2
                         WHERE n2.id_previous = n.id_nch_level)
                  INTO l_id_nch_level
                  FROM adm_indication a
                  JOIN nch_level n
                    ON (a.id_nch_level = n.id_nch_level)
                 WHERE a.id_adm_indication = i_id_adm_indication;
            
                pk_alertlog.log_debug('Deleting nhc = ' || l_id_nch_level);
            EXCEPTION
                WHEN no_data_found THEN
                    pk_alertlog.log_debug('Nothing to delete');
            END;
        
        END IF;
    
        --COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'CANCEL_ADM_IND_NCH_PERIOD',
                                                     o_error);
        
    END cancel_adm_ind_nch_period;
    --

    /********************************************************************************************
    * Get the list of Escape services for a given Admission indication 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_adm_indication     Adm_indication ID
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_escape_services_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN table_number IS
    
        l_escape_services table_number := table_number();
        l_error           t_error_out;
    BEGIN
    
        g_error := 'GET_escape_SERVICES_LIST: i_id_adm_indication=' || i_id_adm_indication;
        pk_alertlog.log_debug(g_error);
    
        SELECT ed.id_department
          BULK COLLECT
          INTO l_escape_services
          FROM escape_department ed
         WHERE ed.id_adm_indication = i_id_adm_indication;
    
        --
        RETURN l_escape_services;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_escape_SERVICES_LIST',
                                              l_error);
            RETURN NULL;
    END get_escape_services_list;
    --

    /********************************************************************************************
    * Get the list of Escape services for a given Admission indication, as string 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_adm_indication     Adm_indication ID
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_escape_services_list_str
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN VARCHAR2 IS
    
        l_escape_services table_varchar := table_varchar();
        --
        l_str_final VARCHAR2(1000 CHAR);
    
        l_str_length     PLS_INTEGER := 0;
        l_str_length_aux PLS_INTEGER := 0;
        l_str            VARCHAR2(1000 CHAR);
        l_item_count     PLS_INTEGER;
        --
        l_error t_error_out;
    BEGIN
    
        g_error := 'GET_escape_SERVICES_LIST_STR: i_id_adm_indication=' || i_id_adm_indication;
        pk_alertlog.log_debug(g_error);
    
        --
        SELECT pk_translation.get_translation(i_lang, d.code_department) service_name
          BULK COLLECT
          INTO l_escape_services
          FROM department d
         WHERE d.id_department IN
               (SELECT column_value
                  FROM TABLE(get_escape_services_list(i_lang, i_prof, i_id_adm_indication)));
    
        -- 
        pk_alertlog.log_debug('BUILD ESCAPE SERVICES STR');
        l_item_count := l_escape_services.count;
        FOR i IN 1 .. l_item_count
        LOOP
            l_str := l_escape_services(i);
        
            l_str_length_aux := length(l_str) + 2;
            IF l_str_length + l_str_length_aux >= g_max_size_to_select
            THEN
                l_str_final := l_str_final || substr(l_str, 0, g_max_size_to_select - l_str_length) || g_not_complete;
                EXIT;
            ELSE
            
                IF i < l_item_count
                THEN
                    l_str_final := l_str_final || l_str || ', ';
                ELSE
                    l_str_final := l_str_final || l_str;
                END IF;
                l_str_length := l_str_length + l_str_length_aux;
            END IF;
        END LOOP;
        --
        RETURN l_str_final;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_escape_SERVICES_LIST_STR',
                                              l_error);
            RETURN NULL;
    END get_escape_services_list_str;
    --

    /********************************************************************************************
    * Get the list of Escape services for a given Admission indication, as string 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_adm_indication_hist    Adm indication history ID
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_escape_serv_list_str_hist
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_adm_indication_hist IN escape_department_hist.id_adm_indication_hist%TYPE
    ) RETURN VARCHAR2 IS
    
        l_escape_services table_varchar := table_varchar();
        --
        l_str_final      VARCHAR2(1000 CHAR);
        l_str_length     PLS_INTEGER := 0;
        l_str_length_aux PLS_INTEGER := 0;
        l_str            VARCHAR2(1000 CHAR);
        l_item_count     PLS_INTEGER;
        --
        l_error t_error_out;
    BEGIN
    
        g_error := 'GET_escape_SERVICES_LIST_STR: ';
        pk_alertlog.log_debug(g_error);
    
        --
        SELECT pk_translation.get_translation(i_lang, d.code_department) service_name
          BULK COLLECT
          INTO l_escape_services
          FROM department d
          JOIN escape_department_hist edh
            ON edh.id_department = d.id_department
         WHERE edh.id_adm_indication_hist = i_id_adm_indication_hist;
    
        -- 
        pk_alertlog.log_debug('BUILD ESCAPE SERVICES STR');
        l_item_count := l_escape_services.count;
        FOR i IN 1 .. l_item_count
        LOOP
            l_str            := l_escape_services(i);
            l_str_length_aux := length(l_str) + 2;
            IF l_str_length + l_str_length_aux >= g_max_size_to_select
            THEN
                l_str_final := l_str_final || substr(l_str, 0, g_max_size_to_select - l_str_length) || g_not_complete;
                EXIT;
            ELSE
            
                IF i < l_item_count
                THEN
                    l_str_final := l_str_final || l_str || ', ';
                ELSE
                    l_str_final := l_str_final || l_str;
                END IF;
                l_str_length := l_str_length + l_str_length_aux;
            END IF;
        END LOOP;
        --
        RETURN l_str_final;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ESCAPE_SERV_LIST_STR_HIST',
                                              l_error);
            RETURN NULL;
    END get_escape_serv_list_str_hist;
    --

    /********************************************************************************************
    * Cancel Admission indication.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_adm_indication     Adm_indication ID
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION cancel_adm_indication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_adm_indication_row adm_indication%ROWTYPE;
    
        l_id_adm_indication_hist adm_indication_hist.id_adm_indication_hist%TYPE;
    
        l_services     table_number := get_adm_indication_dcs(i_lang, i_prof, i_id_adm_indication);
        l_esc_services table_number := get_adm_ind_esc_services(i_lang, i_prof, i_id_adm_indication);
    BEGIN
        --
        g_error := 'CANCEL_ADM_INDICATION: i_id_adm_indication=' || i_id_adm_indication;
        pk_alertlog.log_debug(g_error);
    
        --
        --get_current_time
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_adm_indication IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            g_error := 'CANCEL ADM_INDICATION';
            pk_alertlog.log_debug(g_error);
            -- 
            g_sysdate_tstz := current_timestamp;
            --
        
            ts_adm_indication.upd(id_adm_indication_in => i_id_adm_indication,
                                  flg_available_in     => pk_alert_constant.g_no,
                                  flg_status_in        => pk_alert_constant.g_flg_status_c,
                                  dt_last_update_in    => g_sysdate_tstz,
                                  rows_out             => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ADM_INDICATION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --history
            SELECT *
              INTO l_adm_indication_row
              FROM adm_indication ap
             WHERE ap.id_adm_indication = i_id_adm_indication;
        
            l_id_adm_indication_hist := seq_adm_indication_hist.nextval;
            --history
            INSERT INTO adm_indication_hist
                (id_adm_indication_hist,
                 id_adm_indication,
                 avg_duration,
                 id_wtl_urg_level,
                 id_nch_level,
                 flg_escape,
                 id_institution,
                 code_adm_indication,
                 flg_available,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_adm_indication)
            VALUES
                (l_id_adm_indication_hist,
                 i_id_adm_indication,
                 l_adm_indication_row.avg_duration,
                 l_adm_indication_row.id_wtl_urg_level,
                 l_adm_indication_row.id_nch_level,
                 l_adm_indication_row.flg_escape,
                 l_adm_indication_row.id_institution,
                 l_adm_indication_row.code_adm_indication,
                 pk_alert_constant.g_no,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_c,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 l_adm_indication_row.desc_adm_indication);
        
            IF l_services IS NOT NULL
               AND l_services.count > 0
            THEN
                FOR i IN 1 .. l_services.count
                LOOP
                    ts_adm_ind_dcs_hist.ins(id_adm_indication_hist_in => l_id_adm_indication_hist,
                                            id_adm_indication_in      => i_id_adm_indication,
                                            id_dep_clin_serv_in       => l_services(i),
                                            flg_available_in          => pk_alert_constant.g_yes,
                                            flg_pref_in               => pk_alert_constant.g_no,
                                            rows_out                  => l_rows_out);
                END LOOP;
            END IF;
        
            IF l_esc_services IS NOT NULL
               AND l_esc_services.count > 0
            THEN
                FOR i IN 1 .. l_esc_services.count
                LOOP
                    ts_escape_department_hist.ins(id_adm_indication_hist_in => l_id_adm_indication_hist,
                                                  id_department_in          => l_esc_services(i),
                                                  id_adm_indication_in      => i_id_adm_indication,
                                                  rows_out                  => l_rows_out);
                END LOOP;
            END IF;
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'CANCEL_ADM_INDICATION',
                                                     o_error);
        
    END cancel_adm_indication;
    --

    /********************************************************************************************
    * Get the Indications for admission detail
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication ID   
    * @param o_indication             List of indication details
    * @param o_indication_prof        List of professionals responsible for each action in 
    *                                 the given Indications
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION get_adm_indication_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_indication        OUT pk_types.cursor_type,
        o_indication_prof   OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_nch     pk_types.cursor_type;
        l_ind_adm adm_indication.id_adm_indication%TYPE;
    
        l_nch_value_1    nch_level.id_nch_level%TYPE;
        l_nch_duration_1 nch_level.duration%TYPE;
        l_nch_value_2    nch_level.id_nch_level%TYPE;
        l_nch_duration_2 nch_level.duration%TYPE;
    
    BEGIN
        --
        g_error := 'GET_ADM_INDICATION_DETAIL: i_id_adm_indication = ' || i_id_adm_indication;
        pk_alertlog.log_debug(g_error);
    
        --
        IF i_id_adm_indication IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            --get_nch_data
            IF NOT get_nch_periods(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_id_adm_indication => i_id_adm_indication,
                                   o_nch               => l_nch,
                                   o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            FETCH l_nch
                INTO l_ind_adm, l_nch_duration_1, l_nch_value_1, l_nch_duration_2, l_nch_value_2;
            CLOSE l_nch;
        
            --edit an exsting indication
            OPEN o_indication FOR
                SELECT ai.id_adm_indication_hist id,
                       --ai.flg_escape        flg_escape,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163')) ||
                       nvl(ai.desc_adm_indication, pk_translation.get_translation(i_lang, ai.code_adm_indication)) indication_adm_name_desc,
                       --services
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T649')) ||
                       get_adm_indication_dcs_str(i_lang, i_prof, NULL, ai.id_adm_indication_hist) indication_adm_services_desc,
                       --pref_service
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T646')) ||
                       get_dcs_description(i_lang,
                                           i_prof,
                                           nvl(ai.preferred_dcs_id,
                                               get_adm_indication_pref_dcs(i_lang, i_prof, ai.id_adm_indication))) indication_pref_service_desc,
                       --escape_services
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T650')) ||
                       get_escape_serv_list_str_hist(i_lang, i_prof, ai.id_adm_indication_hist) indication_esc_service_desc,
                       --urg_level
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T651')) ||
                       nvl(wul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, wul.code)) indication_urg_level_desc,
                       --expected duration
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T652')) ||
                       ai.avg_duration indication_exp_duration_desc,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332')) ||
                       pk_sysdomain.get_domain('ADM_INDICATION.FLG_AVAILABLE', ai.flg_available, i_lang) indication_state_desc,
                       chr(10) ||
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T653')) nch_title,
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T657') || ' ' ||
                                                                          lower(pk_message.get_message(i_lang,
                                                                                                       'ADMINISTRATOR_T654'))) || ' ' ||
                       pk_message.get_message(i_lang, 'ADMINISTRATOR_T655') || ': ' || ai.nch_value_1_period || ', ' ||
                       pk_message.get_message(i_lang, 'ADMINISTRATOR_T656') || ': ' || ai.nch_duration_1_period nch_desc,
                       decode(ai.nch_duration_2_period,
                              NULL,
                              NULL,
                              pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                        'ADMINISTRATOR_T658') || ' ' ||
                                                                                 lower(pk_message.get_message(i_lang,
                                                                                                              'ADMINISTRATOR_T654'))) || ' ' ||
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T655') || ': ' || ai.nch_value_2_period || ', ' ||
                              pk_message.get_message(i_lang, 'ADMINISTRATOR_T656') || ': ' || ai.nch_duration_2_period) nch_desc2
                  FROM adm_indication_hist ai
                  LEFT JOIN wtl_urg_level wul
                    ON (wul.id_wtl_urg_level = ai.id_wtl_urg_level)
                 WHERE ai.id_adm_indication = i_id_adm_indication
                 ORDER BY ai.dt_last_update DESC;
        
            OPEN o_indication_prof FOR
                SELECT ai.id_adm_indication_hist id,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, ai.dt_last_update, i_prof) dt,
                       pk_tools.get_prof_description(i_lang, i_prof, ai.id_professional, ai.dt_last_update, NULL) prof_sign,
                       ai.dt_last_update,
                       ai.flg_status flg_status,
                       decode(ai.flg_status,
                              g_active,
                              pk_message.get_message(i_lang, 'DETAIL_COMMON_M001'),
                              pk_sysdomain.get_domain('ADM_INDICATION.FLG_STATUS', ai.flg_status, i_lang)) desc_status
                  FROM adm_indication_hist ai
                 WHERE ai.id_adm_indication = i_id_adm_indication
                 ORDER BY ai.dt_last_update DESC;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_indication);
            pk_types.open_my_cursor(o_indication_prof);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_ADM_INDICATION_DETAIL',
                                                     o_error);
        
    END get_adm_indication_detail;
    --

    /*******************************************
    |             Urgency Level                 |
    ********************************************/

    /********************************************************************************************
    * Get the list of Urgency levels for a given institution 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_urgency_levels         List of Urgency levels
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_urgency_levels_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_urgency_levels OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_URGENCY_LEVELS_LIST: i_id_institution = ' || i_id_institution;
        pk_alertlog.log_debug(g_error);
        --
        OPEN o_urgency_levels FOR
            SELECT ul.id_wtl_urg_level id_urgency,
                   nvl(ul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, ul.code)) urgency_desc,
                   ul.duration urgency_duration,
                   pk_date_utils.dt_chr_tsz(i_lang, ul.dt_last_update, i_prof) urgency_date,
                   pk_sysdomain.get_domain('WTL_URG_LEVEL.FLG_AVAILABLE', ul.flg_available, i_lang) urgency_state,
                   ul.flg_status flg_status,
                   decode(ul.flg_status,
                          pk_alert_constant.g_flg_status_c,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) can_cancel
              FROM wtl_urg_level ul
             WHERE (ul.id_institution = i_id_institution OR
                   i_id_institution IN (SELECT ig.id_institution
                                           FROM institution_group ig
                                          WHERE ig.id_group = ul.id_group
                                            AND ig.flg_relation = 'INST_CNT'))
             ORDER BY ul.flg_available DESC, can_cancel DESC, urgency_desc;
    
        --
        g_error := 'GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --    
        OPEN o_screen_labels FOR
            SELECT pk_message.get_message(i_lang, 'ADMINISTRATOR_T675') grid_main_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T163') name_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T676') scheduling_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T644') date_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T332') status_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T677') filter
              FROM dual;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_urgency_levels);
            pk_types.open_my_cursor(o_screen_labels);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_URGENCY_LEVELS_LIST',
                                                     o_error);
        
    END get_urgency_levels_list;
    --

    /********************************************************************************************
    * Get the list of Urgency levels for a given institution. For each urgency level item only 
    * id|desc will be returned. To get the complete information of urgency levels the function 
    * get_urgency_levels_list should be used.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_urgency_levels         List of Urgency levels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/20
    **********************************************************************************************/
    FUNCTION get_urgency_levels
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_urgency_levels OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_URGENCY_LEVELS: i_id_institution = ' || i_id_institution;
        pk_alertlog.log_debug(g_error);
        --
        OPEN o_urgency_levels FOR
            SELECT ul.id_wtl_urg_level id_urgency,
                   nvl(ul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, ul.code)) urgency_desc
              FROM wtl_urg_level ul
             WHERE (ul.id_institution = i_id_institution OR
                   i_id_institution IN (SELECT ig.id_institution
                                           FROM institution_group ig
                                          WHERE ig.id_group = ul.id_group
                                            AND ig.flg_relation = 'INST_CNT'))
               AND (ul.flg_status IS NULL OR ul.flg_status <> pk_alert_constant.g_flg_status_c)
               AND ul.flg_available = pk_alert_constant.g_yes
             ORDER BY urgency_desc;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_urgency_levels);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_URGENCY_LEVELS',
                                                     o_error);
        
    END get_urgency_levels;
    --

    /********************************************************************************************
    * Get the Urgency level data for a given institution 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_urgency_level       ID urgency level to edit and NULL when creating a new one
    * @param o_urgency_levels         List of Urgency levels
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/20
    **********************************************************************************************/
    FUNCTION get_urgency_levels_edit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_urgency_level IN wtl_urg_level.id_wtl_urg_level%TYPE,
        o_urgency_levels   OUT pk_types.cursor_type,
        o_screen_labels    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_URGENCY_LEVELS_EDIT: i_id_urgency_level = ' || i_id_urgency_level;
        pk_alertlog.log_debug(g_error);
        --
        IF i_id_urgency_level IS NULL
        THEN
            pk_alertlog.log_debug('Creating new Urgency Level');
            OPEN o_urgency_levels FOR
                SELECT NULL id_urgency,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) urgency_name_title,
                       NULL urgency_name_desc,
                       NULL urgency_name_flg,
                       --max_scheduling
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T676'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) urgency_max_sched_title,
                       NULL urgency_max_sched_desc,
                       NULL urgency_max_sched_flg,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) urgency_state_title,
                       pk_sysdomain.get_domain('WTL_URG_LEVEL.FLG_AVAILABLE', pk_alert_constant.g_yes, i_lang) urgency_state_desc,
                       pk_alert_constant.g_yes urgency_state_flg
                  FROM dual;
        ELSE
            pk_alertlog.log_debug('Editing Urgency Level');
            OPEN o_urgency_levels FOR
                SELECT ul.id_wtl_urg_level id_urgency,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) urgency_name_title,
                       nvl(ul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, ul.code)) urgency_name_desc,
                       nvl(ul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, ul.code)) urgency_name_flg,
                       --max_scheduling
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T676'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) urgency_max_sched_title,
                       ul.duration urgency_max_sched_desc,
                       ul.duration urgency_max_sched_flg,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) urgency_state_title,
                       pk_sysdomain.get_domain('WTL_URG_LEVEL.FLG_AVAILABLE', ul.flg_available, i_lang) urgency_state_desc,
                       ul.flg_available urgency_state_flg
                  FROM wtl_urg_level ul
                 WHERE ul.id_wtl_urg_level = i_id_urgency_level;
        END IF;
        --
    
        g_error := 'GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --    
        OPEN o_screen_labels FOR
            SELECT decode(i_id_urgency_level,
                          NULL,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T738'),
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T739')) main_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T740') sub_header
              FROM dual;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_urgency_levels);
            pk_types.open_my_cursor(o_screen_labels);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_URGENCY_LEVELS_EDIT',
                                                     o_error);
        
    END get_urgency_levels_edit;
    --

    /********************************************************************************************
    * Set of a new Urgency level state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_urgency_level      Urgency level ID 
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION set_urgency_level
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_urgency_level IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_name             IN wtl_urg_level.code%TYPE,
        i_max_scheduling   IN wtl_urg_level.duration%TYPE,
        i_state            IN wtl_urg_level.flg_available%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_urgency_level wtl_urg_level.id_wtl_urg_level%TYPE;
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_urgency_level_row wtl_urg_level%ROWTYPE;
    BEGIN
        --
        g_error := 'SET_URGENCY_LEVEL: i_id_urgency_level=' || i_id_urgency_level || ', i_name = ' || i_name ||
                   ', i_max_scheduling = ' || i_max_scheduling || ', i_state=' || i_state;
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_urgency_level IS NULL
        THEN
            g_error := 'CREATE NEW URGENCY_LEVEL';
            pk_alertlog.log_debug(g_error);
            --
        
            l_id_urgency_level := ts_wtl_urg_level.next_key;
        
            ts_wtl_urg_level.ins(id_wtl_urg_level_in          => l_id_urgency_level,
                                 code_in                      => NULL, --l_urgency_level_code || l_id_urgency_level,
                                 flg_available_in             => i_state,
                                 duration_in                  => i_max_scheduling,
                                 id_institution_in            => i_id_institution,
                                 flg_parameterization_type_in => g_backoffice_parameterization,
                                 flg_status_in                => pk_alert_constant.g_flg_status_a,
                                 id_professional_in           => i_prof.id,
                                 dt_creation_in               => g_sysdate_tstz,
                                 dt_last_update_in            => g_sysdate_tstz,
                                 desc_wtl_urg_level_in        => i_name,
                                 rows_out                     => l_rows_out);
        
            --                    
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'WTL_URG_LEVEL',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --pk_translation.insert_into_translation(i_lang       => i_lang,
            --                                       i_code_trans => l_urgency_level_code || l_id_urgency_level,
            --                                       i_desc_trans => i_name);
        
            --history
            INSERT INTO wtl_urg_level_hist
                (id_wtl_urg_level_hist,
                 id_wtl_urg_level,
                 code,
                 flg_available,
                 duration,
                 id_institution,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_wtl_urg_level)
            VALUES
                (seq_wtl_urg_level.nextval,
                 l_id_urgency_level,
                 NULL, --l_urgency_level_code || l_id_urgency_level,
                 i_state,
                 i_max_scheduling,
                 i_id_institution,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_a,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 i_name);
        
        ELSE
            g_error := 'UPDATE URGENCY_LEVEL';
            pk_alertlog.log_debug(g_error);
            --
            ts_wtl_urg_level.upd(id_wtl_urg_level_in   => i_id_urgency_level,
                                 duration_in           => i_max_scheduling,
                                 flg_available_in      => i_state,
                                 flg_status_in         => pk_alert_constant.g_flg_status_e,
                                 desc_wtl_urg_level_in => i_name,
                                 dt_last_update_in     => g_sysdate_tstz,
                                 rows_out              => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'WTL_URG_LEVEL',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --pk_translation.insert_into_translation(i_lang       => i_lang,
            --                                       i_code_trans => l_urgency_level_code || i_id_urgency_level,
            --                                       i_desc_trans => i_name);
        
            --history
            SELECT *
              INTO l_urgency_level_row
              FROM wtl_urg_level wul
             WHERE wul.id_wtl_urg_level = i_id_urgency_level;
        
            INSERT INTO wtl_urg_level_hist
                (id_wtl_urg_level_hist,
                 id_wtl_urg_level,
                 code,
                 flg_available,
                 duration,
                 id_institution,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_wtl_urg_level)
            VALUES
                (seq_wtl_urg_level.nextval,
                 i_id_urgency_level,
                 l_urgency_level_row.code,
                 i_state,
                 i_max_scheduling,
                 i_id_institution,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_e,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 i_name);
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_URGENCY_LEVEL',
                                                     o_error);
        
    END set_urgency_level;
    --

    /********************************************************************************************
    * Set of a new Urgency level state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_urgency_level      Urgency level ID 
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION set_urgency_level_state
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_urgency_level IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_state            IN wtl_urg_level.flg_available%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_urgency_level_row wtl_urg_level%ROWTYPE;
    BEGIN
        --
        g_error := 'SET_URGENCY_LEVEL: i_id_urgency_level=' || i_id_urgency_level || ', i_state=' || i_state;
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := current_timestamp;
        --
        IF i_id_urgency_level IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            g_error := 'UPDATE URGENCY_LEVEL_STATE';
            pk_alertlog.log_debug(g_error);
            --
        
            ts_wtl_urg_level.upd(id_wtl_urg_level_in => i_id_urgency_level,
                                 flg_available_in    => i_state,
                                 flg_status_in       => pk_alert_constant.g_flg_status_e,
                                 dt_last_update_in   => g_sysdate_tstz,
                                 rows_out            => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'WTL_URG_LEVEL',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
            --history
            SELECT *
              INTO l_urgency_level_row
              FROM wtl_urg_level wul
             WHERE wul.id_wtl_urg_level = i_id_urgency_level;
        
            INSERT INTO wtl_urg_level_hist
                (id_wtl_urg_level_hist,
                 id_wtl_urg_level,
                 code,
                 flg_available,
                 duration,
                 id_institution,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_wtl_urg_level)
            VALUES
                (seq_wtl_urg_level.nextval,
                 i_id_urgency_level,
                 l_urgency_level_row.code,
                 i_state,
                 l_urgency_level_row.duration,
                 l_urgency_level_row.id_institution,
                 l_urgency_level_row.flg_parameterization_type,
                 pk_alert_constant.g_flg_status_e,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 l_urgency_level_row.desc_wtl_urg_level);
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_URGENCY_LEVEL_STATE',
                                                     o_error);
        
    END set_urgency_level_state;
    --

    /********************************************************************************************
    * Cancel Urgency levels.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_urgency_level      Urgency level ID
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION cancel_urgency_level
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_urgency_level IN wtl_urg_level.id_wtl_urg_level%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_urgency_level_row wtl_urg_level%ROWTYPE;
    BEGIN
        --
        g_error := 'CANCEL_URGENCY_LEVEL: i_id_urgency_level=' || i_id_urgency_level;
        pk_alertlog.log_debug(g_error);
    
        --
        --get_current_time
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_urgency_level IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            g_error := 'CANCEL URGENCY_LEVEL';
            pk_alertlog.log_debug(g_error);
            --
        
            ts_wtl_urg_level.upd(id_wtl_urg_level_in => i_id_urgency_level,
                                 flg_available_in    => pk_alert_constant.g_no,
                                 flg_status_in       => pk_alert_constant.g_flg_status_c,
                                 dt_last_update_in   => g_sysdate_tstz,
                                 rows_out            => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'WTL_URG_LEVEL',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --history
            SELECT *
              INTO l_urgency_level_row
              FROM wtl_urg_level wul
             WHERE wul.id_wtl_urg_level = i_id_urgency_level;
        
            INSERT INTO wtl_urg_level_hist
                (id_wtl_urg_level_hist,
                 id_wtl_urg_level,
                 code,
                 flg_available,
                 duration,
                 id_institution,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_wtl_urg_level)
            VALUES
                (seq_wtl_urg_level.nextval,
                 i_id_urgency_level,
                 l_urgency_level_row.code,
                 pk_alert_constant.g_no,
                 l_urgency_level_row.duration,
                 l_urgency_level_row.id_institution,
                 l_urgency_level_row.flg_parameterization_type,
                 pk_alert_constant.g_flg_status_c,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 l_urgency_level_row.desc_wtl_urg_level);
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'CANCEL_URGENCY_LEVEL',
                                                     o_error);
        
    END cancel_urgency_level;
    --

    /********************************************************************************************
    * Get the Urgency level detail
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_urgency_level       Urgency level ID   
    * @param o_urgency_level          List of urgency level details
    * @param o_preparation_prof       List of professionals responsible for each action in 
    *                                 the given preparation
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION get_urgency_level_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_urgency_level   IN wtl_urg_level.id_wtl_urg_level%TYPE,
        o_urgency_level      OUT pk_types.cursor_type,
        o_urgency_level_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        g_error := 'GET_URGENCY_LEVEL_DETAIL: i_id_urgency_level = ' || i_id_urgency_level;
        pk_alertlog.log_debug(g_error);
    
        --
        IF i_id_urgency_level IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            --edit an exsting indication
            OPEN o_urgency_level FOR
                SELECT ul.id_wtl_urg_level_hist id,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163')) ||
                       nvl(ul.desc_wtl_urg_level, pk_translation.get_translation(i_lang, ul.code)) urgency_name_desc,
                       --max_scheduling
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T676')) ||
                       ul.duration || ' ' ||
                       decode(ul.duration,
                              NULL,
                              NULL,
                              1,
                              pk_message.get_message(i_lang, 'COMMON_M019'),
                              pk_message.get_message(i_lang, 'COMMON_M020')) urgency_max_sched_desc,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332')) ||
                       pk_sysdomain.get_domain('WTL_URG_LEVEL.FLG_AVAILABLE', ul.flg_available, i_lang) urgency_state_desc
                  FROM wtl_urg_level_hist ul
                 WHERE ul.id_wtl_urg_level = i_id_urgency_level
                 ORDER BY ul.dt_last_update DESC;
        
            OPEN o_urgency_level_prof FOR
                SELECT ul.id_wtl_urg_level_hist id,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, ul.dt_last_update, i_prof) dt,
                       pk_tools.get_prof_description(i_lang, i_prof, ul.id_professional, ul.dt_last_update, NULL) prof_sign,
                       ul.dt_last_update,
                       ul.flg_status flg_status,
                       decode(ul.flg_status,
                              g_active,
                              pk_message.get_message(i_lang, 'DETAIL_COMMON_M001'),
                              pk_sysdomain.get_domain('ADM_INDICATION.FLG_STATUS', ul.flg_status, i_lang)) desc_status
                  FROM wtl_urg_level_hist ul
                 WHERE ul.id_wtl_urg_level = i_id_urgency_level
                 ORDER BY ul.dt_last_update DESC;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_urgency_level);
            pk_types.open_my_cursor(o_urgency_level_prof);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_URGENCY_LEVEL_DETAIL',
                                                     o_error);
        
    END get_urgency_level_detail;
    --

    /*******************************************
    |             Preparation list              |
    ********************************************/

    /********************************************************************************************
    * Get the list of Preparatuions for admission 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_preparation            List of preparations
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_preparation_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_preparation    OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_ADM_INDICATION_LIST: ';
        pk_alertlog.log_debug(g_error);
        --
        OPEN o_preparation FOR
            SELECT p.id_adm_preparation id_preparation,
                   nvl(p.desc_adm_preparation, pk_translation.get_translation(i_lang, p.code_adm_preparation)) preparation_desc,
                   pk_date_utils.dt_chr_tsz(i_lang, p.dt_last_update, i_prof) preparation_date,
                   pk_sysdomain.get_domain('ADM_PREPARATION.FLG_AVAILABLE', p.flg_available, i_lang) preparation_state,
                   p.flg_status flg_status,
                   decode(p.flg_status,
                          pk_alert_constant.g_flg_status_c,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) can_cancel
              FROM adm_preparation p
             WHERE p.id_institution IN (i_id_institution, 0)
             ORDER BY p.flg_available DESC, can_cancel DESC, preparation_desc;
    
        --
        g_error := 'GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --    
        OPEN o_screen_labels FOR
            SELECT pk_message.get_message(i_lang, 'ADMINISTRATOR_T788') grid_main_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T163') name_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T646') pref_serv_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T644') date_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T332') status_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T677') filter
              FROM dual;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_preparation);
            pk_types.open_my_cursor(o_screen_labels);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_PREPARATION_LIST',
                                                     o_error);
        
    END get_preparation_list;
    --

    /********************************************************************************************
    * Get the Preparation data for the create/edit screen 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_preparation         Preparation ID
    * @param o_preparations           Preparation data details
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_preparation_edit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_preparation IN adm_preparation.id_adm_preparation%TYPE,
        o_preparations   OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_PREPARATIONS_EDIT: i_id_preparation = ' || i_id_preparation;
        pk_alertlog.log_debug(g_error);
        --
        IF i_id_preparation IS NULL
        THEN
            OPEN o_preparations FOR
                SELECT NULL id_preparation,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) preparation_name_title,
                       NULL preparation_name_desc,
                       NULL preparation_name_flg,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) preparation_state_title,
                       pk_sysdomain.get_domain('ADM_PREPARATION.FLG_AVAILABLE', pk_alert_constant.g_yes, i_lang) preparation_state_desc,
                       pk_alert_constant.g_yes preparation_state_flg
                  FROM dual;
        ELSE
            OPEN o_preparations FOR
                SELECT NULL id_urgency,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) preparation_name_title,
                       nvl(ap.desc_adm_preparation, pk_translation.get_translation(i_lang, ap.code_adm_preparation)) preparation_name_desc,
                       nvl(ap.desc_adm_preparation, pk_translation.get_translation(i_lang, ap.code_adm_preparation)) preparation_name_flg,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) preparation_state_title,
                       pk_sysdomain.get_domain('ADM_PREPARATION.FLG_AVAILABLE', ap.flg_available, i_lang) preparation_state_desc,
                       ap.flg_available preparation_state_flg
                  FROM adm_preparation ap
                 WHERE ap.id_adm_preparation = i_id_preparation;
        END IF;
        --
    
        g_error := 'GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --    
        OPEN o_screen_labels FOR
            SELECT decode(i_id_preparation,
                          NULL,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T741'),
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T742')) main_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T648') sub_header
              FROM dual;
        --
        RETURN TRUE;
    
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_preparations);
            pk_types.open_my_cursor(o_screen_labels);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_PREPARATION_EDIT',
                                                     o_error);
        
    END get_preparation_edit;
    --

    /********************************************************************************************
    * Create or update a Preparation.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_preparation        Preparation ID (not null only for the edit operation)
    * @ param i_name                  Preparation name
    * @ param i_state                 Preparation state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION set_preparation
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_preparation IN adm_preparation.id_adm_preparation%TYPE,
        i_name           IN adm_preparation.code_adm_preparation%TYPE,
        i_state          IN adm_preparation.flg_available%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count          NUMBER(6);
        l_id_preparation adm_preparation.id_adm_preparation%TYPE;
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_adm_preparation_row adm_preparation%ROWTYPE;
    BEGIN
        --
        g_error := 'SET_PREPARATION: i_id_preparation=' || i_id_preparation || ', i_name = ' || i_name || ', i_state=' ||
                   i_state;
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := current_timestamp;
    
        SELECT COUNT(1)
          INTO l_count
          FROM adm_preparation ap
         WHERE ap.id_adm_preparation = i_id_preparation
           AND ap.flg_parameterization_type <> 'C';
    
        IF l_count = 0
        THEN
            g_error := 'CREATE NEW PREPARATION';
            pk_alertlog.log_debug(g_error);
            --
        
            l_id_preparation := ts_adm_preparation.next_key;
        
            ts_adm_preparation.ins(id_adm_preparation_in        => l_id_preparation,
                                   flg_available_in             => i_state,
                                   id_institution_in            => i_id_institution,
                                   code_adm_preparation_in      => NULL, --l_preparation_code || l_id_preparation,
                                   flg_parameterization_type_in => g_backoffice_parameterization,
                                   flg_status_in                => pk_alert_constant.g_flg_status_a,
                                   id_professional_in           => i_prof.id,
                                   dt_creation_in               => g_sysdate_tstz,
                                   dt_last_update_in            => g_sysdate_tstz,
                                   desc_adm_preparation_in      => i_name,
                                   rows_out                     => l_rows_out);
            --                    
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ADM_PREPARATION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
            --
            --pk_translation.insert_into_translation(i_lang       => i_lang,
            --                                       i_code_trans => l_preparation_code || l_id_preparation,
            --                                       i_desc_trans => i_name);
        
            --history
            INSERT INTO adm_preparation_hist
                (id_adm_preparation_hist,
                 id_adm_preparation,
                 flg_available,
                 id_institution,
                 code_adm_preparation,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_adm_preparation)
            VALUES
                (seq_adm_preparation_hist.nextval,
                 l_id_preparation,
                 i_state,
                 i_id_institution,
                 NULL, --l_preparation_code || l_id_preparation,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_a,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 i_name);
        
        ELSE
            g_error := 'UPDATE PREPARATION';
            pk_alertlog.log_debug(g_error);
            --
            ts_adm_preparation.upd(id_adm_preparation_in   => i_id_preparation,
                                   flg_available_in        => i_state,
                                   flg_status_in           => pk_alert_constant.g_flg_status_e,
                                   desc_adm_preparation_in => i_name,
                                   dt_last_update_in       => g_sysdate_tstz,
                                   rows_out                => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ADM_PREPARATION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --pk_translation.insert_into_translation(i_lang       => i_lang,
            --                                       i_code_trans => l_preparation_code || i_id_preparation,
            --                                       i_desc_trans => i_name);
        
            --history
            SELECT *
              INTO l_adm_preparation_row
              FROM adm_preparation ap
             WHERE ap.id_adm_preparation = i_id_preparation;
        
            --history
            INSERT INTO adm_preparation_hist
                (id_adm_preparation_hist,
                 id_adm_preparation,
                 flg_available,
                 id_institution,
                 code_adm_preparation,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_adm_preparation)
            VALUES
                (seq_adm_preparation_hist.nextval,
                 i_id_preparation,
                 i_state,
                 i_id_institution,
                 l_adm_preparation_row.code_adm_preparation,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_e,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 i_name);
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_PREPARATION',
                                                     o_error);
        
    END set_preparation;
    --

    /********************************************************************************************
    * Set of a new Preparation state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_preparation        Preparation ID 
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION set_preparation_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_preparation IN adm_preparation.id_adm_preparation%TYPE,
        i_state          IN adm_preparation.flg_available%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_adm_preparation_row adm_preparation%ROWTYPE;
    BEGIN
        --
        g_error := 'SET_URGENCY_LEVEL: i_id_preparation=' || i_id_preparation || ', i_state=' || i_state;
        pk_alertlog.log_debug(g_error);
        --
        g_sysdate_tstz := current_timestamp;
        --
        IF i_id_preparation IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            g_error := 'UPDATE URGENCY_LEVEL_STATE';
            pk_alertlog.log_debug(g_error);
            --
            ts_adm_preparation.upd(id_adm_preparation_in => i_id_preparation,
                                   flg_available_in      => i_state,
                                   flg_status_in         => pk_alert_constant.g_flg_status_e,
                                   dt_last_update_in     => g_sysdate_tstz,
                                   rows_out              => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ADM_PREPARATION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --history
            SELECT *
              INTO l_adm_preparation_row
              FROM adm_preparation ap
             WHERE ap.id_adm_preparation = i_id_preparation;
        
            --history
            INSERT INTO adm_preparation_hist
                (id_adm_preparation_hist,
                 id_adm_preparation,
                 flg_available,
                 id_institution,
                 code_adm_preparation,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_adm_preparation)
            VALUES
                (seq_adm_preparation_hist.nextval,
                 i_id_preparation,
                 i_state,
                 l_adm_preparation_row.id_institution,
                 l_adm_preparation_row.code_adm_preparation,
                 l_adm_preparation_row.flg_parameterization_type,
                 pk_alert_constant.g_flg_status_e,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 l_adm_preparation_row.desc_adm_preparation);
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_PREPARATION_STATE',
                                                     o_error);
        
    END set_preparation_state;
    --

    /********************************************************************************************
    * Cancel Preparations.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_adm_preparation    Preparation ID
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION cancel_preparation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_adm_preparation IN adm_preparation.id_adm_preparation%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_adm_preparation_row adm_preparation%ROWTYPE;
    BEGIN
        --
        g_error := 'CANCEL_PREPARATION: i_id_adm_preparation=' || i_id_adm_preparation;
        pk_alertlog.log_debug(g_error);
        --
        --get_current_time
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_adm_preparation IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            g_error := 'CANCEL_PREPARATION';
            pk_alertlog.log_debug(g_error);
            --
            ts_adm_preparation.upd(id_adm_preparation_in => i_id_adm_preparation,
                                   flg_available_in      => pk_alert_constant.g_no,
                                   flg_status_in         => pk_alert_constant.g_flg_status_c,
                                   dt_last_update_in     => g_sysdate_tstz,
                                   rows_out              => l_rows_out);
            --
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ADM_PREPARATION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --history
            SELECT *
              INTO l_adm_preparation_row
              FROM adm_preparation ap
             WHERE ap.id_adm_preparation = i_id_adm_preparation;
            --history
            INSERT INTO adm_preparation_hist
                (id_adm_preparation_hist,
                 id_adm_preparation,
                 flg_available,
                 id_institution,
                 code_adm_preparation,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_adm_preparation)
            VALUES
                (seq_adm_preparation_hist.nextval,
                 i_id_adm_preparation,
                 pk_alert_constant.g_no,
                 l_adm_preparation_row.id_institution,
                 l_adm_preparation_row.code_adm_preparation,
                 l_adm_preparation_row.flg_parameterization_type,
                 pk_alert_constant.g_flg_status_c,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 l_adm_preparation_row.desc_adm_preparation);
            --
        END IF;
        --
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'CANCEL_PREPARATION',
                                                     o_error);
        
    END cancel_preparation;
    --

    /********************************************************************************************
    * Get the Preparation detail
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_preparation         Preparation ID   
    * @param o_preparation            List of preparations
    * @param o_preparation_prof       List of professional responsible for each preparation
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION get_preparation_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_preparation   IN adm_preparation.id_adm_preparation%TYPE,
        o_preparation      OUT pk_types.cursor_type,
        o_preparation_prof OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        g_error := 'GET_PREPARATION_DETAIL: i_id_preparation = ' || i_id_preparation;
        pk_alertlog.log_debug(g_error);
    
        --
        IF i_id_preparation IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            --edit an exsting indication
            OPEN o_preparation FOR
                SELECT aph.id_adm_preparation_hist id,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163')) || /*preparation_name_title,*/
                       nvl(aph.desc_adm_preparation, pk_translation.get_translation(i_lang, aph.code_adm_preparation)) preparation_name_desc,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332')) || /*preparation_state_title,*/
                       pk_sysdomain.get_domain('ADM_PREPARATION.FLG_AVAILABLE', aph.flg_available, i_lang) preparation_state_desc
                  FROM adm_preparation_hist aph
                 WHERE aph.id_adm_preparation = i_id_preparation
                 ORDER BY aph.dt_last_update DESC;
        
            --
            OPEN o_preparation_prof FOR
                SELECT aph.id_adm_preparation_hist id,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, aph.dt_last_update, i_prof) dt,
                       pk_tools.get_prof_description(i_lang, i_prof, aph.id_professional, aph.dt_last_update, NULL) prof_sign,
                       aph.dt_last_update,
                       aph.flg_status flg_status,
                       decode(aph.flg_status,
                              g_active,
                              pk_message.get_message(i_lang, 'DETAIL_COMMON_M001'),
                              pk_sysdomain.get_domain('ADM_PREPARATION.FLG_STATUS', aph.flg_status, i_lang)) desc_status
                  FROM adm_preparation_hist aph
                 WHERE aph.id_adm_preparation = i_id_preparation
                 ORDER BY aph.dt_last_update DESC;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_preparation);
            pk_types.open_my_cursor(o_preparation_prof);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_PREPARATION_DETAIL',
                                                     o_error);
        
    END get_preparation_detail;
    --

    /*******************************************
    |             Admission types               |
    ********************************************/
    /********************************************************************************************
    * Get the list of Admission types 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_admission_types        List of Admission types
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_admission_types_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_institution  IN institution.id_institution%TYPE,
        o_admission_types OUT pk_types.cursor_type,
        o_screen_labels   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_ADM_INDICATION_LIST: ';
        pk_alertlog.log_debug(g_error);
        --
        OPEN o_admission_types FOR
            SELECT at.id_admission_type id_admission_type,
                   nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) admission_type_desc,
                   at.max_admission_time || ' ' ||
                   decode(at.max_admission_time,
                          NULL,
                          NULL,
                          1,
                          pk_message.get_message(i_lang, 'BMNG_T130'),
                          pk_message.get_message(i_lang, 'BMNG_T131')) admission_type_max_time,
                   pk_date_utils.dt_chr_tsz(i_lang, at.dt_last_update, i_prof) admission_type_date,
                   pk_sysdomain.get_domain('ADMISSION_TYPE.FLG_AVAILABLE', at.flg_available, i_lang) admission_type_state,
                   at.flg_status flg_status,
                   decode(at.flg_status,
                          pk_alert_constant.g_flg_status_c,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) can_cancel
              FROM admission_type at
             WHERE at.id_institution = i_id_institution
             ORDER BY at.flg_available DESC, can_cancel DESC, admission_type_desc;
    
        --
        g_error := 'GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --    
        OPEN o_screen_labels FOR
            SELECT pk_message.get_message(i_lang, 'ADMINISTRATOR_T771') grid_main_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T163') name_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T799') adm_time_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T644') date_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T332') status_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T677') filter
              FROM dual;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_admission_types);
            pk_types.open_my_cursor(o_screen_labels);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_ADMISSION_TYPES_LIST',
                                                     o_error);
        
    END get_admission_types_list;
    --

    /********************************************************************************************
    * Get the list of Admission types 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_admission_types        List of Admission types
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/1
    **********************************************************************************************/
    FUNCTION get_admission_types
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_institution  IN institution.id_institution%TYPE,
        o_admission_types OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_ADM_INDICATION_LIST: ';
        pk_alertlog.log_debug(g_error);
        --
        OPEN o_admission_types FOR
            SELECT at.id_admission_type id_admission_type,
                   nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) admission_type_desc
              FROM admission_type at
             WHERE at.id_institution = i_id_institution
             ORDER BY admission_type_desc;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_admission_types);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_ADMISSION_TYPES',
                                                     o_error);
        
    END get_admission_types;
    --

    /********************************************************************************************
    * Get the Admission types data for the create/edit screen 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_type            Admission type ID
    * @param o_admission_types        List of Admission types
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION get_admission_types_edit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_adm_type     IN admission_type.id_admission_type%TYPE,
        o_admission_types OUT pk_types.cursor_type,
        o_screen_labels   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_ADMISSION_TYPES_EDIT: i_id_adm_type = ' || i_id_adm_type;
        pk_alertlog.log_debug(g_error);
        --
        IF i_id_adm_type IS NULL
        THEN
            OPEN o_admission_types FOR
                SELECT NULL id_admission_type,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) admission_type_name_title,
                       NULL admission_type_name_desc,
                       NULL admission_type_name_flg,
                       --max_time
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T799'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) admission_type_max_time_title,
                       NULL admission_type_max_time_desc,
                       NULL admission_type_max_time_flg,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) admission_type_state_title,
                       pk_sysdomain.get_domain('ADMISSION_TYPE.FLG_AVAILABLE', pk_alert_constant.g_yes, i_lang) admission_type_state_desc,
                       pk_alert_constant.g_yes admission_type_state_flg
                  FROM dual;
        ELSE
            OPEN o_admission_types FOR
                SELECT at.id_admission_type id_admission_type,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) admission_type_name_title,
                       nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) admission_type_name_desc,
                       nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) admission_type_name_flg,
                       --max_time
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T799'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) admission_type_max_time_title,
                       at.max_admission_time admission_type_max_time_desc,
                       at.max_admission_time admission_type_max_time_flg,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) admission_type_state_title,
                       pk_sysdomain.get_domain('ADMISSION_TYPE.FLG_AVAILABLE', at.flg_available, i_lang) admission_type_state_desc,
                       at.flg_available admission_type_state_flg
                  FROM admission_type at
                 WHERE at.id_admission_type = i_id_adm_type;
        END IF;
        --
    
        g_error := 'GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --    
        OPEN o_screen_labels FOR
            SELECT decode(i_id_adm_type,
                          NULL,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T747'),
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T748')) main_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T751') sub_header,
                   pk_message.get_message(i_lang, 'BMNG_T130') hour_msg,
                   pk_message.get_message(i_lang, 'BMNG_T131') hours_msg
              FROM dual;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_admission_types);
            pk_types.open_my_cursor(o_screen_labels);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_ADMISSION_TYPES_EDIT',
                                                     o_error);
        
    END get_admission_types_edit;
    --

    /********************************************************************************************
    * Set of a new Urgency level state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_urgency_level      Urgency level ID 
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/20
    **********************************************************************************************/
    FUNCTION set_admission_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_admission_type IN admission_type.id_admission_type%TYPE,
        i_name              IN admission_type.code_admission_type%TYPE,
        i_state             IN admission_type.flg_available%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_admission_type   admission_type.id_admission_type%TYPE;
        l_admission_type_code VARCHAR2(100 CHAR) := 'ADMISSION_TYPE.CODE_ADMISSION_TYPE.';
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_admission_type_row admission_type%ROWTYPE;
    BEGIN
        --
        g_error := 'SET_ADMISSION_TYPE: i_id_admission_type=' || i_id_admission_type || ', i_name = ' || i_name ||
                   ', i_state=' || i_state;
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_admission_type IS NULL
        THEN
            g_error := 'CREATE NEW ADMISSION_TYPE';
            pk_alertlog.log_debug(g_error);
            --
        
            l_id_admission_type := ts_admission_type.next_key;
        
            ts_admission_type.ins(id_admission_type_in         => l_id_admission_type,
                                  flg_available_in             => i_state,
                                  id_institution_in            => i_id_institution,
                                  code_admission_type_in       => l_admission_type_code || l_id_admission_type,
                                  flg_parameterization_type_in => g_backoffice_parameterization,
                                  flg_status_in                => pk_alert_constant.g_flg_status_a,
                                  id_professional_in           => i_prof.id,
                                  dt_creation_in               => g_sysdate_tstz,
                                  dt_last_update_in            => g_sysdate_tstz,
                                  desc_admission_type_in       => i_name,
                                  rows_out                     => l_rows_out);
            --                    
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ADMISSION_TYPE',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => l_admission_type_code || l_id_admission_type,
                                                   i_desc_trans => i_name);
        
            --history
            INSERT INTO admission_type_hist
                (id_admission_type_hist,
                 id_admission_type,
                 flg_available,
                 id_institution,
                 code_admission_type,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_admission_type)
            VALUES
                (seq_admission_type_hist.nextval,
                 l_id_admission_type,
                 i_state,
                 i_id_institution,
                 l_admission_type_code || l_id_admission_type,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_a,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 i_name);
        
        ELSE
            g_error := 'UPDATE ADMISSION_TYPE';
            pk_alertlog.log_debug(g_error);
        
            ts_admission_type.upd(id_admission_type_in   => l_id_admission_type,
                                  flg_available_in       => i_state,
                                  flg_status_in          => pk_alert_constant.g_flg_status_e,
                                  desc_admission_type_in => i_name,
                                  dt_last_update_in      => g_sysdate_tstz,
                                  rows_out               => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ADMISSION_TYPE',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => l_admission_type_code || i_id_admission_type,
                                                   i_desc_trans => i_name);
        
            --history
            SELECT *
              INTO l_admission_type_row
              FROM admission_type at
             WHERE at.id_admission_type = i_id_admission_type;
        
            INSERT INTO admission_type_hist
                (id_admission_type_hist,
                 id_admission_type,
                 flg_available,
                 id_institution,
                 code_admission_type,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_admission_type,
                 max_admission_time)
            VALUES
                (seq_admission_type_hist.nextval,
                 i_id_admission_type,
                 i_state,
                 i_id_institution,
                 l_admission_type_code || l_id_admission_type,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_e,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 i_name,
                 l_admission_type_row.max_admission_time);
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_ADMISSION_TYPE',
                                                     o_error);
        
    END set_admission_type;
    --

    /********************************************************************************************
    * Set of a new Urgency level state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_admission_type     Admission type ID 
    * @ param i_name                  Admission type name
    * @ param i_max_adm_time          Maximum time for admission 
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/20
    **********************************************************************************************/
    FUNCTION set_admission_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_admission_type IN admission_type.id_admission_type%TYPE,
        i_name              IN admission_type.code_admission_type%TYPE,
        i_max_adm_time      IN admission_type.max_admission_time%TYPE,
        i_state             IN admission_type.flg_available%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_admission_type admission_type.id_admission_type%TYPE;
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_admission_type_row admission_type%ROWTYPE;
    BEGIN
        --
        g_error := 'SET_ADMISSION_TYPE: i_id_admission_type=' || i_id_admission_type || ', i_name = ' || i_name ||
                   ', i_state=' || i_state;
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_admission_type IS NULL
        THEN
            g_error := 'CREATE NEW ADMISSION_TYPE';
            pk_alertlog.log_debug(g_error);
            --
        
            l_id_admission_type := ts_admission_type.next_key;
        
            ts_admission_type.ins(id_admission_type_in         => l_id_admission_type,
                                  flg_available_in             => i_state,
                                  id_institution_in            => i_id_institution,
                                  code_admission_type_in       => NULL, --l_admission_type_code || l_id_admission_type,
                                  flg_parameterization_type_in => g_backoffice_parameterization,
                                  flg_status_in                => pk_alert_constant.g_flg_status_a,
                                  id_professional_in           => i_prof.id,
                                  dt_creation_in               => g_sysdate_tstz,
                                  dt_last_update_in            => g_sysdate_tstz,
                                  desc_admission_type_in       => i_name,
                                  max_admission_time_in        => i_max_adm_time,
                                  rows_out                     => l_rows_out);
            --                    
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ADMISSION_TYPE',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --pk_translation.insert_into_translation(i_lang       => i_lang,
            --                                       i_code_trans => l_admission_type_code || l_id_admission_type,
            --                                       i_desc_trans => i_name);
        
            --history
            INSERT INTO admission_type_hist
                (id_admission_type_hist,
                 id_admission_type,
                 flg_available,
                 id_institution,
                 code_admission_type,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_admission_type,
                 max_admission_time)
            VALUES
                (seq_admission_type_hist.nextval,
                 l_id_admission_type,
                 i_state,
                 i_id_institution,
                 NULL, --l_admission_type_code || l_id_admission_type,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_a,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 i_name,
                 i_max_adm_time);
        
        ELSE
            g_error := 'UPDATE ADMISSION_TYPE';
            pk_alertlog.log_debug(g_error);
        
            ts_admission_type.upd(id_admission_type_in   => i_id_admission_type,
                                  flg_available_in       => i_state,
                                  flg_status_in          => pk_alert_constant.g_flg_status_e,
                                  desc_admission_type_in => i_name,
                                  max_admission_time_in  => i_max_adm_time,
                                  dt_last_update_in      => g_sysdate_tstz,
                                  rows_out               => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ADMISSION_TYPE',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --pk_translation.insert_into_translation(i_lang       => i_lang,
            --                                       i_code_trans => l_admission_type_code || i_id_admission_type,
            --                                       i_desc_trans => i_name);
        
            --history
            SELECT *
              INTO l_admission_type_row
              FROM admission_type at
             WHERE at.id_admission_type = i_id_admission_type;
        
            INSERT INTO admission_type_hist
                (id_admission_type_hist,
                 id_admission_type,
                 flg_available,
                 id_institution,
                 code_admission_type,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_admission_type,
                 max_admission_time)
            VALUES
                (seq_admission_type_hist.nextval,
                 i_id_admission_type,
                 i_state,
                 i_id_institution,
                 l_admission_type_row.code_admission_type, --l_admission_type_code || l_id_admission_type,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_e,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 i_name,
                 i_max_adm_time);
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_ADMISSION_TYPE',
                                                     o_error);
        
    END set_admission_type;
    --

    /********************************************************************************************
    * Set of a new Admission type state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_adm_type           Admission type ID 
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/17
    **********************************************************************************************/
    FUNCTION set_admission_types_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_adm_type    IN admission_type.id_admission_type%TYPE,
        i_state          IN admission_type.flg_available%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_admission_type_row admission_type%ROWTYPE;
    BEGIN
        --
        g_error := 'SET_ADMISSION_TYPES_STATE: i_id_adm_type=' || i_id_adm_type || ', i_state=' || i_state;
        pk_alertlog.log_debug(g_error);
        --
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_adm_type IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            g_error := 'UPDATE ADMISSION_TYPE_STATE';
            pk_alertlog.log_debug(g_error);
            --
        
            ts_admission_type.upd(id_admission_type_in => i_id_adm_type,
                                  flg_available_in     => i_state,
                                  flg_status_in        => pk_alert_constant.g_flg_status_e,
                                  dt_last_update_in    => g_sysdate_tstz,
                                  rows_out             => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ADMISSION_TYPE',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --history
            SELECT *
              INTO l_admission_type_row
              FROM admission_type at
             WHERE at.id_admission_type = i_id_adm_type;
        
            INSERT INTO admission_type_hist
                (id_admission_type_hist,
                 id_admission_type,
                 flg_available,
                 id_institution,
                 code_admission_type,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_admission_type,
                 max_admission_time)
            VALUES
                (seq_admission_type_hist.nextval,
                 i_id_adm_type,
                 i_state,
                 l_admission_type_row.id_institution,
                 l_admission_type_row.code_admission_type,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_e,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 l_admission_type_row.desc_admission_type,
                 l_admission_type_row.max_admission_time);
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_ADMISSION_TYPES_STATE',
                                                     o_error);
        
    END set_admission_types_state;
    --

    /********************************************************************************************
    * Cancel Admission type.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_admission_type     Admission_type ID
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION cancel_admission_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_admission_type IN admission_type.id_admission_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_admission_type_row admission_type%ROWTYPE;
    BEGIN
        --
        g_error := 'CANCEL_ADMISSION_TYPE: i_id_admission_type=' || i_id_admission_type;
        pk_alertlog.log_debug(g_error);
    
        --
        --get_current_time
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_admission_type IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            g_error := 'CANCEL ADMISSION_TYPE';
            pk_alertlog.log_debug(g_error);
            --
        
            ts_admission_type.upd(id_admission_type_in => i_id_admission_type,
                                  flg_available_in     => pk_alert_constant.g_no,
                                  flg_status_in        => pk_alert_constant.g_flg_status_c,
                                  dt_last_update_in    => g_sysdate_tstz,
                                  rows_out             => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ADMISSION_TYPE',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --history
            SELECT *
              INTO l_admission_type_row
              FROM admission_type at
             WHERE at.id_admission_type = i_id_admission_type;
        
            INSERT INTO admission_type_hist
                (id_admission_type_hist,
                 id_admission_type,
                 flg_available,
                 id_institution,
                 code_admission_type,
                 flg_parameterization_type,
                 flg_status,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_admission_type,
                 max_admission_time)
            VALUES
                (seq_admission_type_hist.nextval,
                 i_id_admission_type,
                 pk_alert_constant.g_no,
                 l_admission_type_row.id_institution,
                 l_admission_type_row.code_admission_type,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_c,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 l_admission_type_row.desc_admission_type,
                 l_admission_type_row.max_admission_time);
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'CANCEL_ADMISSION_TYPE',
                                                     o_error);
        
    END cancel_admission_type;
    --

    /********************************************************************************************
    * Get the Admission type detail
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_admission_type         admission_type ID   
    * @param o_admission_type            List of admission_types
    * @param o_admission_type_prof       List of professional responsible for each admission_type
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/24
    **********************************************************************************************/
    FUNCTION get_admission_type_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_admission_type   IN admission_type.id_admission_type%TYPE,
        o_admission_type      OUT pk_types.cursor_type,
        o_admission_type_prof OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        g_error := 'GET_admission_type_DETAIL: i_id_admission_type = ' || i_id_admission_type;
        pk_alertlog.log_debug(g_error);
    
        --
        IF i_id_admission_type IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
        
            OPEN o_admission_type FOR
                SELECT at.id_admission_type_hist id,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163')) ||
                       nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) admission_type_name_desc,
                       --max_time
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T799')) ||
                       at.max_admission_time || ' ' ||
                       decode(at.max_admission_time,
                              NULL,
                              NULL,
                              1,
                              pk_message.get_message(i_lang, 'BMNG_T130'),
                              pk_message.get_message(i_lang, 'BMNG_T131')) admission_type_max_time_desc,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332')) ||
                       pk_sysdomain.get_domain('ADMISSION_TYPE.FLG_AVAILABLE', at.flg_available, i_lang) admission_type_state_desc
                  FROM admission_type_hist at
                 WHERE at.id_admission_type = i_id_admission_type
                 ORDER BY at.dt_last_update DESC;
        
            --
            OPEN o_admission_type_prof FOR
                SELECT at.id_admission_type_hist id,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, at.dt_last_update, i_prof) dt,
                       pk_tools.get_prof_description(i_lang, i_prof, at.id_professional, at.dt_last_update, NULL) prof_sign,
                       at.dt_last_update,
                       at.flg_status flg_status,
                       decode(at.flg_status,
                              g_active,
                              pk_message.get_message(i_lang, 'DETAIL_COMMON_M001'),
                              pk_sysdomain.get_domain('ADMISSION_TYPE.FLG_STATUS', at.flg_status, i_lang)) desc_status
                  FROM admission_type_hist at
                 WHERE at.id_admission_type = i_id_admission_type
                 ORDER BY at.dt_last_update DESC;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_admission_type);
            pk_types.open_my_cursor(o_admission_type_prof);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_ADMISSION_TYPE_DETAIL',
                                                     o_error);
        
    END get_admission_type_detail;
    --

    /*******************************************
    |                    NCH                   |
    ********************************************/

    /********************************************************************************************
    * Create NCH periods 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_period                 ID NCH period
    * @param i_nch_startday           Start day 
    * @param i_nch_n_hours            Number of hours
    * @param i_id_nch_previous        ID NCH of the previous period
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/10
    **********************************************************************************************/
    FUNCTION create_nch_periods
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_period          IN VARCHAR2 DEFAULT 'F',
        i_nch_duration    IN nch_level.duration%TYPE,
        i_nch_n_hours     IN nch_level.value%TYPE,
        i_id_nch_previous IN nch_level.id_previous%TYPE,
        o_nch_id          OUT nch_level.id_nch_level%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_nch nch_level.id_nch_level%TYPE;
    BEGIN
        g_error := 'CREATE_NCH_PERIODS: i_period = ' || i_period || ', i_nch_duration = ' || i_nch_duration ||
                   ', i_nch_n_hours = ' || i_nch_n_hours || ', i_id_nch_previous =' || i_id_nch_previous;
        pk_alertlog.log_debug(g_error);
        --
        SELECT seq_nch_level.nextval
          INTO l_id_nch
          FROM dual;
        --  
        INSERT INTO nch_level
            (id_nch_level, VALUE, duration, id_previous)
        VALUES
            (l_id_nch, i_nch_n_hours, i_nch_duration, i_id_nch_previous);
    
        o_nch_id := l_id_nch;
        --don't commit
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'CREATE_NCH_PERIODS',
                                                     o_error);
        
    END create_nch_periods;
    --

    /********************************************************************************************
    * Get NCH periods for a given Indications for admission
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication ID
    * @param o_nch                    NCH information (First and Second periods)
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/17
    **********************************************************************************************/
    FUNCTION get_nch_periods
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_nch               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_NCH_PERIODS: i_id_adm_indication = ' || i_id_adm_indication;
        pk_alertlog.log_debug(g_error);
        --
    
        OPEN o_nch FOR
            SELECT ai.id_adm_indication id_indication,
                   1 indication_nch_1_startday,
                   nl.value indication_nch_1_n_hours,
                   (nl.duration + 1) indication_nch_2_startday,
                   nl2.value indication_nch_2_n_hours
              FROM adm_indication ai
              JOIN nch_level nl
                ON (ai.id_nch_level = nl.id_nch_level)
              LEFT JOIN nch_level nl2
                ON (nl.id_nch_level = nl2.id_previous)
             WHERE ai.id_adm_indication = i_id_adm_indication;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_nch);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_NCH_PERIODS',
                                                     o_error);
        
    END get_nch_periods;
    --

    /********************************************************************************************
    * Update NCH periods 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_nch_level              ID NCH period
    * @param i_nch_duration           First period duration 
    * @param i_nch_n_hours            Number of hours for the first period
    * @param i_nch_2_n_hours          Number of hours for the second period  
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/25
    **********************************************************************************************/
    FUNCTION update_nch_periods
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nch_level     IN nch_level.id_nch_level%TYPE,
        i_nch_duration  IN nch_level.duration%TYPE,
        i_nch_n_hours   IN nch_level.value%TYPE,
        i_nch_2_n_hours IN nch_level.duration%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_second_period_count PLS_INTEGER := 0;
        l_nch_level_not_used  nch_level.id_nch_level%TYPE;
    BEGIN
        g_error := 'UPDATE_NCH_PERIODS: i_nch_level = ' || i_nch_level || ', i_nch_duration = ' || i_nch_duration ||
                   ', i_nch_n_hours = ' || i_nch_n_hours || ', i_nch_2_n_hours =' || i_nch_2_n_hours;
        pk_alertlog.log_debug(g_error);
        --
    
        UPDATE nch_level nl
           SET nl.value = i_nch_n_hours, nl.duration = i_nch_duration
         WHERE nl.id_nch_level = i_nch_level;
    
        IF i_nch_2_n_hours IS NULL
        THEN
            pk_alertlog.log_debug('Delete the second period for i_nch_level = ' || i_nch_level);
            DELETE nch_level nl
             WHERE nl.id_previous = i_nch_level;
        ELSE
        
            SELECT COUNT(*)
              INTO l_second_period_count
              FROM nch_level nl
             WHERE nl.id_previous = i_nch_level;
            --
            IF l_second_period_count = 0
            THEN
                pk_alertlog.log_debug('Create the second period for i_nch_level = ' || i_nch_level);
                IF NOT create_nch_periods(i_lang,
                                          i_prof,
                                          g_nch_2_period,
                                          NULL,
                                          i_nch_2_n_hours,
                                          i_nch_level,
                                          l_nch_level_not_used,
                                          o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSE
                pk_alertlog.log_debug('Update the second period for i_nch_level = ' || i_nch_level);
                UPDATE nch_level nl
                   SET nl.value = i_nch_2_n_hours
                 WHERE nl.id_previous = i_nch_level;
            END IF;
        
        END IF;
    
        --don't commit
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'UPDATE_NCH_PERIODS',
                                                     o_error);
        
    END update_nch_periods;
    --

    /********************************************************************************************
    * Get the nch_level id for the given adm indication
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_adm_indication      Indication ID
    * @param o_error                  Error
    *
    * @return                         The NCH ID, or null if the NCH doesn't exist
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/25
    **********************************************************************************************/
    FUNCTION get_adm_indication_nch
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN NUMBER IS
        l_nch_level nch_level.id_nch_level%TYPE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET_ADM_INDICATION_NCH: i_id_adm_indication = ' || i_id_adm_indication;
        pk_alertlog.log_debug(g_error);
    
        SELECT ai.id_nch_level
          INTO l_nch_level
          FROM adm_indication ai
         WHERE ai.id_adm_indication = i_id_adm_indication;
    
        RETURN l_nch_level;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ADM_INDICATION_NCH',
                                              l_error);
            RETURN NULL;
    END get_adm_indication_nch;
    --

    /*******************************************
    |             Equipment types              |
    ********************************************/

    /********************************************************************************************
    * Get the list of Equipment types for the institution
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_institution         Institution ID
    * @param o_equipments             List of equipments
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/26
    **********************************************************************************************/
    FUNCTION get_equipment_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_equipment      OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_EQUIPMENT_LIST: i_id_institution' || i_id_institution;
        pk_alertlog.log_debug(g_error);
        --
        OPEN o_equipment FOR
            SELECT id_equipment,
                   equipment_desc,
                   equipment_date,
                   equipment_state,
                   equipment_type_desc,
                   equipment_type,
                   flg_status,
                   can_cancel
              FROM (SELECT rt.id_room_type id_equipment,
                           nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) equipment_desc,
                           pk_date_utils.dt_chr_tsz(i_lang, rt.dt_last_update, i_prof) equipment_date,
                           pk_sysdomain.get_domain('ROOM_TYPE.FLG_AVAILABLE', rt.flg_available, i_lang) equipment_state,
                           pk_sysdomain.get_domain('EQUIPMENT_TYPE', g_equipment_type_room, i_lang) equipment_type_desc,
                           g_equipment_type_room equipment_type,
                           rt.flg_status,
                           decode(rt.flg_status,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_alert_constant.g_no,
                                  pk_alert_constant.g_yes) can_cancel,
                           rt.flg_available flg_available
                      FROM room_type rt
                     WHERE rt.id_institution IN (i_id_institution, 0)
                    UNION ALL
                    SELECT bt.id_bed_type id_equipment,
                           nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) equipment_desc,
                           pk_date_utils.dt_chr_tsz(i_lang, bt.dt_last_update, i_prof) equipment_date,
                           pk_sysdomain.get_domain('BED_TYPE.FLG_AVAILABLE', bt.flg_available, i_lang) equipment_state,
                           pk_sysdomain.get_domain('EQUIPMENT_TYPE', g_equipment_type_bed, i_lang) equipment_type_desc,
                           g_equipment_type_bed equipment_type,
                           bt.flg_status,
                           decode(bt.flg_status,
                                  pk_alert_constant.g_flg_status_c,
                                  pk_alert_constant.g_no,
                                  pk_alert_constant.g_yes) can_cancel,
                           bt.flg_available flg_available
                      FROM bed_type bt
                     WHERE bt.id_institution IN (i_id_institution, 0)) t
             WHERE t.equipment_desc IS NOT NULL
             ORDER BY flg_available DESC, can_cancel DESC, equipment_type_desc, equipment_desc, equipment_date;
    
        --
        g_error := 'GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --    
        OPEN o_screen_labels FOR
            SELECT pk_message.get_message(i_lang, 'ADMINISTRATOR_T756') grid_main_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T163') name_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T757') kind_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T644') date_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T332') status_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T645') filter
              FROM dual;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_equipment);
            pk_types.open_my_cursor(o_screen_labels);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_EQUIPMENT_LIST',
                                                     o_error);
        
    END get_equipment_list;
    --

    /********************************************************************************************
    * Get the list of Room types available in the institution
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_institution         Institution ID
    * @param o_room_type              List of room types
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/07
    **********************************************************************************************/
    FUNCTION get_room_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_room_type      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_ROOM_TYPE_LIST: i_id_institution' || i_id_institution;
        pk_alertlog.log_debug(g_error);
        --
        OPEN o_room_type FOR
            SELECT rt.id_room_type id,
                   nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_desc,
                   pk_date_utils.dt_chr_tsz(i_lang, rt.dt_last_update, i_prof) room_date,
                   pk_sysdomain.get_domain('ROOM_TYPE.FLG_AVAILABLE', rt.flg_available, i_lang) room_state,
                   pk_sysdomain.get_domain('EQUIPMENT_TYPE', g_equipment_type_room, i_lang) room_type_desc
              FROM room_type rt
             WHERE rt.id_institution IN (i_id_institution, 0)
               AND (rt.flg_status IS NULL OR rt.flg_status <> pk_alert_constant.g_flg_status_c)
               AND rt.flg_available = pk_alert_constant.g_yes
             ORDER BY room_desc, room_type_desc, room_date;
    
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_room_type);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_ROOM_TYPE_LIST',
                                                     o_error);
        
    END get_room_type_list;
    --

    /********************************************************************************************
    * Get the list of bed types available in the institution
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_institution         Institution ID
    * @param o_bed_type               List of bed types
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/07
    **********************************************************************************************/
    FUNCTION get_bed_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_bed_type       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_BED_TYPE_LIST: i_id_institution' || i_id_institution;
        pk_alertlog.log_debug(g_error);
        --
        OPEN o_bed_type FOR
            SELECT bt.id_bed_type id,
                   nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) bed_desc,
                   pk_date_utils.dt_chr_tsz(i_lang, bt.dt_last_update, i_prof) bed_date,
                   pk_sysdomain.get_domain('BED_TYPE.FLG_AVAILABLE', bt.flg_available, i_lang) bed_state,
                   pk_sysdomain.get_domain('EQUIPMENT_TYPE', g_equipment_type_bed, i_lang) bed_type_desc
              FROM bed_type bt
             WHERE bt.id_institution IN (i_id_institution, 0)
               AND (bt.flg_status IS NULL OR bt.flg_status <> pk_alert_constant.g_flg_status_c)
               AND bt.flg_available = pk_alert_constant.g_yes
             ORDER BY bed_desc, bed_type_desc, bed_date;
    
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_bed_type);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_BED_TYPE_LIST',
                                                     o_error);
        
    END get_bed_type_list;
    --

    /********************************************************************************************
    * Get the equipment data for the create/edit screen 
    *
    * @param i_lang                 Preferred language ID for this professional 
    * @param i_prof                 Object (professional ID, institution ID, software ID)
    * @param i_id_equipment         Equipment ID
    * @param i_equipment_type       Equipment type: R - room, B - bed
    * @param o_equipments           Equipment data details
    * @param o_screen_labels        Screen labels
    * @param o_error                Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/26
    **********************************************************************************************/
    FUNCTION get_equipment_edit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_equipment   IN room_type.id_room_type%TYPE,
        i_equipment_type IN VARCHAR2,
        o_equipment      OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET_EQUIPMENTS_EDIT: i_id_equipment = ' || i_id_equipment || ', i_equipment_type ' ||
                   i_equipment_type;
        pk_alertlog.log_debug(g_error);
    
        IF i_equipment_type IS NULL
           OR i_equipment_type = g_equipment_type_room
        THEN
            --
            pk_alertlog.log_debug('EDIT/CREATE ROOMS');
            --
            IF i_id_equipment IS NULL
            THEN
                OPEN o_equipment FOR
                    SELECT NULL id_equipment,
                           --name
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T163'),
                                                                              pk_alert_constant.g_yes,
                                                                              pk_alert_constant.g_yes) equipment_name_title,
                           NULL equipment_name_desc,
                           NULL equipment_name_flg,
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T757'),
                                                                              pk_alert_constant.g_yes,
                                                                              pk_alert_constant.g_yes) equipment_kind_title,
                           pk_sysdomain.get_domain('EQUIPMENT_TYPE', g_equipment_type_room, i_lang) equipment_kind_desc,
                           g_equipment_type_room equipment_kind_flg,
                           --state
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T332'),
                                                                              pk_alert_constant.g_yes,
                                                                              pk_alert_constant.g_yes) equipment_state_title,
                           pk_sysdomain.get_domain('ROOM_TYPE.FLG_AVAILABLE', pk_alert_constant.g_yes, i_lang) equipment_state_desc,
                           pk_alert_constant.g_yes equipment_state_flg
                      FROM dual;
            ELSE
                OPEN o_equipment FOR
                    SELECT rt.id_room_type id_equipment,
                           --name
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T163'),
                                                                              pk_alert_constant.g_yes,
                                                                              pk_alert_constant.g_yes) equipment_name_title,
                           nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) equipment_name_desc,
                           nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) equipment_name_flg,
                           --kind
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T757'),
                                                                              pk_alert_constant.g_yes,
                                                                              pk_alert_constant.g_yes) equipment_kind_title,
                           pk_sysdomain.get_domain('EQUIPMENT_TYPE', g_equipment_type_room, i_lang) equipment_kind_desc,
                           g_equipment_type_room equipment_kind_flg,
                           --state
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T332'),
                                                                              pk_alert_constant.g_yes,
                                                                              pk_alert_constant.g_yes) equipment_state_title,
                           pk_sysdomain.get_domain('ROOM_TYPE.FLG_AVAILABLE', rt.flg_available, i_lang) equipment_state_desc,
                           rt.flg_available equipment_state_flg
                      FROM room_type rt
                     WHERE rt.id_room_type = i_id_equipment;
            END IF;
            --
        ELSE
            pk_alertlog.log_debug('EDIT/CREATE BEDS');
            --
            IF i_id_equipment IS NULL
            THEN
                OPEN o_equipment FOR
                    SELECT NULL id_equipment,
                           --name
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T163'),
                                                                              pk_alert_constant.g_yes,
                                                                              pk_alert_constant.g_yes) equipment_name_title,
                           NULL equipment_name_desc,
                           NULL equipment_name_flg,
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T757'),
                                                                              pk_alert_constant.g_yes,
                                                                              pk_alert_constant.g_yes) equipment_kind_title,
                           pk_sysdomain.get_domain('EQUIPMENT_TYPE', g_equipment_type_bed, i_lang) equipment_kind_desc,
                           g_equipment_type_bed equipment_kind_flg,
                           --state
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T332'),
                                                                              pk_alert_constant.g_yes,
                                                                              pk_alert_constant.g_yes) equipment_state_title,
                           pk_sysdomain.get_domain('BED_TYPE.FLG_AVAILABLE', pk_alert_constant.g_yes, i_lang) equipment_state_desc,
                           pk_alert_constant.g_yes equipment_state_flg
                      FROM dual;
            ELSE
                OPEN o_equipment FOR
                    SELECT bt.id_bed_type id_urgency,
                           --name
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T163'),
                                                                              pk_alert_constant.g_yes,
                                                                              pk_alert_constant.g_yes) equipment_name_title,
                           nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) equipment_name_desc,
                           nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) equipment_name_flg,
                           --kind
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T757'),
                                                                              pk_alert_constant.g_yes,
                                                                              pk_alert_constant.g_yes) equipment_kind_title,
                           pk_sysdomain.get_domain('EQUIPMENT_TYPE', g_equipment_type_bed, i_lang) equipment_kind_desc,
                           g_equipment_type_bed equipment_kind_flg,
                           --state
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T332'),
                                                                              pk_alert_constant.g_yes,
                                                                              pk_alert_constant.g_yes) equipment_state_title,
                           pk_sysdomain.get_domain('BED_TYPE.FLG_AVAILABLE', bt.flg_available, i_lang) equipment_state_desc,
                           bt.flg_available equipment_state_flg
                      FROM bed_type bt
                     WHERE bt.id_bed_type = i_id_equipment;
            END IF;
            --
        END IF;
    
        g_error := 'GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --    
        OPEN o_screen_labels FOR
            SELECT decode(i_id_equipment,
                          NULL,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T758'),
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T759')) main_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T648') sub_header
              FROM dual;
        --
        RETURN TRUE;
    
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_equipment);
            pk_types.open_my_cursor(o_screen_labels);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_equipment_EDIT',
                                                     o_error);
        
    END get_equipment_edit;
    --

    /********************************************************************************************
    * Create a new equipment. The i_equipment_type defines if we are creating 
    * a new Room or a new Bed.
    *
    * @param i_lang                  Preferred language ID for this professional 
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_institution        Institution ID 
    * @param i_id_equipment          Equipment ID
    * @param i_name                  Equipment name
    * @param i_equipment_type        Equipment type: R - room, B - bed
    * @param i_state                 Equipment state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/26
    **********************************************************************************************/
    FUNCTION set_equipment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_equipment   IN room_type.id_room_type%TYPE,
        i_name           IN room_type.code_room_type%TYPE,
        i_equipment_type IN VARCHAR2,
        i_state          IN room_type.flg_available%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count        NUMBER(6);
        l_id_room_type room_type.id_room_type%TYPE;
    
        l_id_bed_type bed_type.id_bed_type%TYPE;
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_room_type_row room_type%ROWTYPE;
        l_bed_type_row  bed_type%ROWTYPE;
    BEGIN
        --
        g_error := 'SET_equipment: i_id_equipment=' || i_id_equipment || ', i_name = ' || i_name || ', i_state=' ||
                   i_state || ', i_equipment_type = ' || i_equipment_type;
    
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_equipment_type = g_equipment_type_room
        THEN
            --
            SELECT COUNT(1)
              INTO l_count
              FROM room_type rt
             WHERE rt.id_room_type = i_id_equipment
               AND rt.flg_parameterization_type <> 'C';
            --
            IF l_count = 0
            THEN
                g_error := 'CREATE NEW ROOM_TYPE';
                pk_alertlog.log_debug(g_error);
                --
            
                l_id_room_type := ts_room_type.next_key;
            
                ts_room_type.ins(id_room_type_in              => l_id_room_type,
                                 flg_available_in             => i_state,
                                 id_institution_in            => i_id_institution,
                                 code_room_type_in            => NULL, --l_room_type_code || l_id_room_type,
                                 flg_parameterization_type_in => g_backoffice_parameterization,
                                 flg_status_in                => pk_alert_constant.g_flg_status_a,
                                 id_professional_in           => i_prof.id,
                                 dt_creation_in               => g_sysdate_tstz,
                                 dt_last_update_in            => g_sysdate_tstz,
                                 desc_room_type_in            => i_name,
                                 rows_out                     => l_rows_out);
                --                    
                g_error := 'CALL t_data_gov_mnt.process_insert';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ROOM_TYPE',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
                --
                --pk_translation.insert_into_translation(i_lang       => i_lang,
                --                                       i_code_trans => l_room_type_code || l_id_room_type,
                --                                       i_desc_trans => i_name);
            
                --history
                INSERT INTO room_type_hist
                    (id_room_type_hist,
                     id_room_type,
                     flg_available,
                     id_institution,
                     code_room_type,
                     flg_parameterization_type,
                     flg_status,
                     id_professional,
                     dt_creation,
                     dt_last_update,
                     desc_room_type)
                VALUES
                    (seq_room_type_hist.nextval,
                     l_id_room_type,
                     i_state,
                     i_id_institution,
                     NULL, --l_room_type_code || l_id_room_type,
                     g_backoffice_parameterization,
                     pk_alert_constant.g_flg_status_a,
                     i_prof.id,
                     g_sysdate_tstz,
                     g_sysdate_tstz,
                     i_name);
            
            ELSE
                g_error := 'UPDATE ROOM_TYPE';
                pk_alertlog.log_debug(g_error);
                --
            
                ts_room_type.upd(id_room_type_in   => i_id_equipment,
                                 flg_available_in  => i_state,
                                 flg_status_in     => pk_alert_constant.g_flg_status_e,
                                 desc_room_type_in => i_name,
                                 dt_last_update_in => g_sysdate_tstz,
                                 rows_out          => l_rows_out);
            
                g_error := 'CALL t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ROOM_TYPE',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                --pk_translation.insert_into_translation(i_lang       => i_lang,
                --                                       i_code_trans => l_room_type_code || i_id_equipment,
                --                                       i_desc_trans => i_name);
            
                --history
                SELECT *
                  INTO l_room_type_row
                  FROM room_type rt
                 WHERE rt.id_room_type = i_id_equipment;
            
                --history
                INSERT INTO room_type_hist
                    (id_room_type_hist,
                     id_room_type,
                     flg_available,
                     id_institution,
                     code_room_type,
                     flg_parameterization_type,
                     flg_status,
                     id_professional,
                     dt_creation,
                     dt_last_update,
                     desc_room_type)
                VALUES
                    (seq_room_type_hist.nextval,
                     i_id_equipment,
                     i_state,
                     i_id_institution,
                     l_room_type_row.code_room_type, --l_room_type_code || l_id_room_type,
                     g_backoffice_parameterization,
                     pk_alert_constant.g_flg_status_e,
                     i_prof.id,
                     g_sysdate_tstz,
                     g_sysdate_tstz,
                     i_name);
            
            END IF;
        ELSE
        
            SELECT COUNT(1)
              INTO l_count
              FROM bed_type bt
             WHERE bt.id_bed_type = i_id_equipment
               AND bt.flg_parameterization_type <> 'C';
        
            IF l_count = 0
            THEN
                g_error := 'CREATE NEW BED_TYPE';
                pk_alertlog.log_debug(g_error);
                --
            
                l_id_bed_type := ts_bed_type.next_key;
            
                ts_bed_type.ins(id_bed_type_in               => l_id_bed_type,
                                flg_available_in             => i_state,
                                id_institution_in            => i_id_institution,
                                code_bed_type_in             => NULL, --l_bed_type_code || l_id_bed_type,
                                flg_parameterization_type_in => g_backoffice_parameterization,
                                flg_status_in                => pk_alert_constant.g_flg_status_a,
                                id_professional_in           => i_prof.id,
                                dt_creation_in               => g_sysdate_tstz,
                                dt_last_update_in            => g_sysdate_tstz,
                                desc_bed_type_in             => i_name,
                                rows_out                     => l_rows_out);
                --                    
                g_error := 'CALL t_data_gov_mnt.process_insert';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'BED_TYPE',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
                --
                --pk_translation.insert_into_translation(i_lang       => i_lang,
                --                                       i_code_trans => l_bed_type_code || l_id_bed_type,
                --                                      i_desc_trans => i_name);
            
                --history
                INSERT INTO bed_type_hist
                    (id_bed_type_hist,
                     id_bed_type,
                     flg_available,
                     id_institution,
                     code_bed_type,
                     flg_parameterization_type,
                     flg_status,
                     id_professional,
                     dt_creation,
                     dt_last_update,
                     desc_bed_type)
                VALUES
                    (seq_bed_type_hist.nextval,
                     l_id_bed_type,
                     i_state,
                     i_id_institution,
                     NULL, --l_bed_type_code || l_id_bed_type,
                     g_backoffice_parameterization,
                     pk_alert_constant.g_flg_status_a,
                     i_prof.id,
                     g_sysdate_tstz,
                     g_sysdate_tstz,
                     i_name);
            
            ELSE
                g_error := 'UPDATE BED_TYPE';
                pk_alertlog.log_debug(g_error);
                --
            
                ts_bed_type.upd(id_bed_type_in    => i_id_equipment,
                                flg_available_in  => i_state,
                                flg_status_in     => pk_alert_constant.g_flg_status_e,
                                desc_bed_type_in  => i_name,
                                dt_last_update_in => g_sysdate_tstz,
                                rows_out          => l_rows_out);
            
                g_error := 'CALL t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'bed_TYPE',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                --pk_translation.insert_into_translation(i_lang       => i_lang,
                --                                       i_code_trans => l_bed_type_code || i_id_equipment,
                --                                       i_desc_trans => i_name);
            
                --history
                SELECT *
                  INTO l_bed_type_row
                  FROM bed_type rt
                 WHERE rt.id_bed_type = i_id_equipment;
            
                --history
                INSERT INTO bed_type_hist
                    (id_bed_type_hist,
                     id_bed_type,
                     flg_available,
                     id_institution,
                     code_bed_type,
                     flg_parameterization_type,
                     flg_status,
                     id_professional,
                     dt_creation,
                     dt_last_update,
                     desc_bed_type)
                VALUES
                    (seq_bed_type_hist.nextval,
                     i_id_equipment,
                     i_state,
                     i_id_institution,
                     l_bed_type_row.code_bed_type, --l_bed_type_code || l_id_bed_type,
                     g_backoffice_parameterization,
                     pk_alert_constant.g_flg_status_e,
                     i_prof.id,
                     g_sysdate_tstz,
                     g_sysdate_tstz,
                     i_name);
            
            END IF;
        END IF;
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_EQUIPMENT',
                                                     o_error);
        
    END set_equipment;
    --

    /********************************************************************************************
    * Set of a new equipment state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_equipment          Equipment ID 
    * @param i_equipment_type         Equipment type: R - room, B - bed
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/26
    **********************************************************************************************/
    FUNCTION set_equipment_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_equipment   IN room_type.id_room_type%TYPE,
        i_equipment_type IN VARCHAR2,
        i_state          IN room_type.flg_available%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_room_type_row room_type%ROWTYPE;
        l_bed_type_row  bed_type%ROWTYPE;
    BEGIN
        --
        g_error := 'SET_EQUIPMENT_STATE: i_id_equipment=' || i_id_equipment || ', i_state=' || i_state ||
                   ', i_equipment_type' || i_equipment_type;
    
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_equipment_type = g_equipment_type_room
        THEN
        
            IF i_id_equipment IS NULL
            THEN
                raise_application_error(-20100, 'Invalid Input Parameters');
            ELSE
                g_error := 'UPDATE ROOM_TYPE_STATE';
                pk_alertlog.log_debug(g_error);
                --
            
                ts_room_type.upd(id_room_type_in   => i_id_equipment,
                                 flg_available_in  => i_state,
                                 flg_status_in     => pk_alert_constant.g_flg_status_e,
                                 dt_last_update_in => g_sysdate_tstz,
                                 rows_out          => l_rows_out);
            
                g_error := 'CALL t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ROOM_TYPE',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                --history
                SELECT *
                  INTO l_room_type_row
                  FROM room_type rt
                 WHERE rt.id_room_type = i_id_equipment;
            
                --history
                INSERT INTO room_type_hist
                    (id_room_type_hist,
                     id_room_type,
                     flg_available,
                     id_institution,
                     code_room_type,
                     flg_parameterization_type,
                     flg_status,
                     id_professional,
                     dt_creation,
                     dt_last_update,
                     desc_room_type)
                VALUES
                    (seq_room_type_hist.nextval,
                     i_id_equipment,
                     i_state,
                     l_room_type_row.id_institution,
                     l_room_type_row.code_room_type,
                     g_backoffice_parameterization,
                     pk_alert_constant.g_flg_status_e,
                     i_prof.id,
                     g_sysdate_tstz,
                     g_sysdate_tstz,
                     l_room_type_row.desc_room_type);
            
            END IF;
        ELSE
            IF i_id_equipment IS NULL
            THEN
                raise_application_error(-20100, 'Invalid Input Parameters');
            ELSE
                g_error := 'UPDATE BED_TYPE_STATE';
                pk_alertlog.log_debug(g_error);
                --
            
                ts_bed_type.upd(id_bed_type_in    => i_id_equipment,
                                flg_available_in  => i_state,
                                flg_status_in     => pk_alert_constant.g_flg_status_e,
                                dt_last_update_in => g_sysdate_tstz,
                                rows_out          => l_rows_out);
            
                g_error := 'CALL t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'BED_TYPE',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                --history
                SELECT *
                  INTO l_bed_type_row
                  FROM bed_type rt
                 WHERE rt.id_bed_type = i_id_equipment;
            
                --history
                INSERT INTO bed_type_hist
                    (id_bed_type_hist,
                     id_bed_type,
                     flg_available,
                     id_institution,
                     code_bed_type,
                     flg_parameterization_type,
                     flg_status,
                     id_professional,
                     dt_creation,
                     dt_last_update,
                     desc_bed_type)
                VALUES
                    (seq_bed_type_hist.nextval,
                     i_id_equipment,
                     i_state,
                     l_bed_type_row.id_institution,
                     l_bed_type_row.code_bed_type,
                     g_backoffice_parameterization,
                     pk_alert_constant.g_flg_status_e,
                     i_prof.id,
                     g_sysdate_tstz,
                     g_sysdate_tstz,
                     l_bed_type_row.desc_bed_type);
            END IF;
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_EQUIPMENT_STATE',
                                                     o_error);
        
    END set_equipment_state;
    --

    /********************************************************************************************
    * Cancel equipments.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_adm_equipment      Equipment ID
    * @param i_equipment_type         Equipment type: R - room, B - bed
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/26
    **********************************************************************************************/
    FUNCTION cancel_equipment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_equipment   IN room_type.id_room_type%TYPE,
        i_equipment_type IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_room_type_row room_type%ROWTYPE;
        l_bed_type_row  bed_type%ROWTYPE;
    BEGIN
        --
        g_error := 'CANCEL_EQUIPMENT: i_id_equipment=' || i_id_equipment || ', i_equipment_type=' || i_equipment_type;
        pk_alertlog.log_debug(g_error);
    
        --
        --get_current_time
        g_sysdate_tstz := current_timestamp;
    
        IF i_equipment_type = g_equipment_type_room
        THEN
        
            IF i_id_equipment IS NULL
            THEN
                raise_application_error(-20100, 'Invalid Input Parameters');
            ELSE
                g_error := 'CANCEL_EQUIPMENT';
                pk_alertlog.log_debug(g_error);
                --
            
                ts_room_type.upd(id_room_type_in   => i_id_equipment,
                                 flg_available_in  => pk_alert_constant.g_no,
                                 flg_status_in     => pk_alert_constant.g_flg_status_c,
                                 dt_last_update_in => g_sysdate_tstz,
                                 rows_out          => l_rows_out);
            
                g_error := 'CALL t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ROOM_TYPE',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                --history
                SELECT *
                  INTO l_room_type_row
                  FROM room_type rt
                 WHERE rt.id_room_type = i_id_equipment;
            
                --history
                INSERT INTO room_type_hist
                    (id_room_type_hist,
                     id_room_type,
                     flg_available,
                     id_institution,
                     code_room_type,
                     flg_parameterization_type,
                     flg_status,
                     id_professional,
                     dt_creation,
                     dt_last_update,
                     desc_room_type)
                VALUES
                    (seq_room_type_hist.nextval,
                     i_id_equipment,
                     pk_alert_constant.g_no,
                     l_room_type_row.id_institution,
                     l_room_type_row.code_room_type,
                     g_backoffice_parameterization,
                     pk_alert_constant.g_flg_status_c,
                     i_prof.id,
                     g_sysdate_tstz,
                     g_sysdate_tstz,
                     l_room_type_row.desc_room_type);
            
            END IF;
        ELSE
        
            IF i_id_equipment IS NULL
            THEN
                raise_application_error(-20100, 'Invalid Input Parameters');
            ELSE
                g_error := 'CANCEL_EQUIPMENT';
                pk_alertlog.log_debug(g_error);
                --
            
                ts_bed_type.upd(id_bed_type_in    => i_id_equipment,
                                flg_available_in  => pk_alert_constant.g_no,
                                flg_status_in     => pk_alert_constant.g_flg_status_c,
                                dt_last_update_in => g_sysdate_tstz,
                                rows_out          => l_rows_out);
            
                g_error := 'CALL t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'BED_TYPE',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                --history
                SELECT *
                  INTO l_bed_type_row
                  FROM bed_type rt
                 WHERE rt.id_bed_type = i_id_equipment;
            
                --history
                INSERT INTO bed_type_hist
                    (id_bed_type_hist,
                     id_bed_type,
                     flg_available,
                     id_institution,
                     code_bed_type,
                     flg_parameterization_type,
                     flg_status,
                     id_professional,
                     dt_creation,
                     dt_last_update,
                     desc_bed_type)
                VALUES
                    (seq_bed_type_hist.nextval,
                     i_id_equipment,
                     pk_alert_constant.g_no,
                     l_bed_type_row.id_institution,
                     l_bed_type_row.code_bed_type,
                     g_backoffice_parameterization,
                     pk_alert_constant.g_flg_status_c,
                     i_prof.id,
                     g_sysdate_tstz,
                     g_sysdate_tstz,
                     l_bed_type_row.desc_bed_type);
            END IF;
        END IF;
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'CANCEL_EQUIPMENT',
                                                     o_error);
        
    END cancel_equipment;
    --

    /********************************************************************************************
    * Get the equipment detail. The i_equipment_type defines the type of equipment: Room or a Bed.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_equipment           Equipment ID   
    * @param i_equipment_type         Equipment type: R - room, B - bed
    * @param o_equipment              List of equipments
    * @param o_equipment_prof         List of professional responsible for each equipment
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/26
    **********************************************************************************************/
    FUNCTION get_equipment_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_equipment   IN room_type.id_room_type%TYPE,
        i_equipment_type IN VARCHAR2,
        o_equipment      OUT pk_types.cursor_type,
        o_equipment_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        g_error := 'GET_equipment_DETAIL: i_id_equipment = ' || i_id_equipment || ', i_equipment_type=' ||
                   i_equipment_type;
        pk_alertlog.log_debug(g_error);
    
        IF i_equipment_type = g_equipment_type_room
        THEN
            --
            IF i_id_equipment IS NULL
            THEN
                raise_application_error(-20100, 'Invalid Input Parameters');
            ELSE
                --get details
                OPEN o_equipment FOR
                    SELECT rt.id_room_type_hist id,
                           --name
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T163')) ||
                           nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) equipment_name_desc,
                           --kind
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T757')) ||
                           pk_sysdomain.get_domain('EQUIPMENT_TYPE', g_equipment_type_room, i_lang) equipment_kind_desc,
                           --state
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T332')) ||
                           pk_sysdomain.get_domain('ROOM_TYPE.FLG_AVAILABLE', rt.flg_available, i_lang) equipment_state_desc
                      FROM room_type_hist rt
                     WHERE rt.id_room_type = i_id_equipment
                     ORDER BY rt.dt_last_update DESC;
            
                --
                OPEN o_equipment_prof FOR
                    SELECT rt.id_room_type_hist id,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, rt.dt_last_update, i_prof) dt,
                           pk_tools.get_prof_description(i_lang, i_prof, rt.id_professional, rt.dt_last_update, NULL) prof_sign,
                           rt.dt_last_update,
                           rt.flg_status flg_status,
                           decode(rt.flg_status,
                                  g_active,
                                  pk_message.get_message(i_lang, 'DETAIL_COMMON_M001'),
                                  pk_sysdomain.get_domain('ROOM_TYPE.FLG_STATUS', rt.flg_status, i_lang)) desc_status
                      FROM room_type_hist rt
                     WHERE rt.id_room_type = i_id_equipment
                     ORDER BY rt.dt_last_update DESC;
            END IF;
        ELSE
            IF i_id_equipment IS NULL
            THEN
                raise_application_error(-20100, 'Invalid Input Parameters');
            ELSE
                --get details 
                OPEN o_equipment FOR
                    SELECT bt.id_bed_type_hist id,
                           --name
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T163')) ||
                           nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) equipment_name_desc,
                           --kind
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T757')) ||
                           pk_sysdomain.get_domain('EQUIPMENT_TYPE', g_equipment_type_bed, i_lang) equipment_kind_desc,
                           --state
                           pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                     'ADMINISTRATOR_T332')) ||
                           pk_sysdomain.get_domain('BED_TYPE.FLG_AVAILABLE', bt.flg_available, i_lang) equipment_state_desc
                      FROM bed_type_hist bt
                     WHERE bt.id_bed_type = i_id_equipment
                     ORDER BY bt.dt_last_update DESC;
            
                --
                OPEN o_equipment_prof FOR
                    SELECT bt.id_bed_type_hist id,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, bt.dt_last_update, i_prof) dt,
                           pk_tools.get_prof_description(i_lang, i_prof, bt.id_professional, bt.dt_last_update, NULL) prof_sign,
                           bt.dt_last_update,
                           bt.flg_status flg_status,
                           decode(bt.flg_status,
                                  g_active,
                                  pk_message.get_message(i_lang, 'DETAIL_COMMON_M001'),
                                  pk_sysdomain.get_domain('BED_TYPE.FLG_STATUS', bt.flg_status, i_lang)) desc_status
                      FROM bed_type_hist bt
                     WHERE bt.id_bed_type = i_id_equipment
                     ORDER BY bt.dt_last_update DESC;
            END IF;
        END IF;
    
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_equipment);
            pk_types.open_my_cursor(o_equipment_prof);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_EQUIPMENT_DETAIL',
                                                     o_error);
        
    END get_equipment_detail;
    --

    /*******************************************
    |                  Rooms                   |
    ********************************************/

    /********************************************************************************************
    * Get the list of rooms for a given institution with all details that includes:
    *     Number of beds, room type, Service, Specialtya and status
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_institution         Institution ID
    * @param o_rooms                  List of Rooms
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_room_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_institutiton IN institution.id_institution%TYPE,
        o_rooms           OUT pk_types.cursor_type,
        o_screen_labels   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'get_room_list: i_id_institutiton=' || i_id_institutiton;
        pk_alertlog.log_debug(g_error);
    
        --
        OPEN o_rooms FOR
            SELECT to_char(r.id_room) id_room,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_desc,
                   (SELECT COUNT(*)
                      FROM bed b
                     WHERE b.id_room = r.id_room
                       AND b.flg_available = pk_alert_constant.g_yes
                       AND b.flg_type = g_bed_type_permanent_p) room_n_beds,
                   nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_type,
                   -- RG: added department information in the grid
                   pk_translation.get_translation(i_lang, d.code_department) || ' ' ||
                   pk_message.get_message(i_lang, 'ADM_REQUEST_T081') || ' ' ||
                   pk_translation.get_translation(i_lang, 'DEPT.CODE_DEPT.' || d.id_dept) service_name,
                   get_specialties_list_as_str(i_lang, i_prof, get_room_specialties(i_lang, i_prof, r.id_room), ',') specialties_desc,
                   pk_date_utils.dt_chr_tsz(i_lang, r.dt_last_update, i_prof) room_date,
                   -- RG: add to make available flash date ordering
                   pk_date_utils.date_send(i_lang, r.dt_last_update, i_prof) room_date_ux,
                   pk_sysdomain.get_domain('ROOM.FLG_AVAILABLE', r.flg_available, i_lang) room_state,
                   nvl(r.flg_status, decode(r.flg_available, pk_alert_constant.get_available, 'A', 'C')) flg_status,
                   decode(r.flg_status,
                          pk_alert_constant.g_flg_status_c,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) can_cancel,
                   has_all_beds_available(i_lang, r.id_room) flg_available,
                   r.capacity
              FROM room r
              LEFT JOIN room_type rt
                ON rt.id_room_type = r.id_room_type
              JOIN department d
                ON d.id_department = r.id_department
             WHERE d.id_institution = i_id_institutiton
             ORDER BY r.flg_available DESC, can_cancel DESC, room_desc, room_type;
        --
        g_error := 'GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --    
        OPEN o_screen_labels FOR
            SELECT pk_message.get_message(i_lang, 'ADMINISTRATOR_T769') grid_main_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T163') name_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T770') act_beds_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T375') type_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T369') service_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T776') specialties_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T644') date_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T332') status_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T677') filter,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_ROOM_T006') capacity_column_header
              FROM dual;
        --
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_types.open_my_cursor(o_rooms);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ROOM_LIST',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_room_list;
    --

    /********************************************************************************************
    * Get the list dep. clinical service (dcs) for a given room
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    *
    * @return                         the list dcs ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_room_dcs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN VARCHAR2
    ) RETURN table_number IS
    
        --dcs description
        l_id_room_dcs table_number := table_number();
    
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'get_room_dcs: i_id_room = ' || i_id_room;
        pk_alertlog.log_debug(g_error);
        --
    
        SELECT rdcs.id_dep_clin_serv
          BULK COLLECT
          INTO l_id_room_dcs
          FROM room r
          JOIN room_dep_clin_serv rdcs
            ON (r.id_room = rdcs.id_room)
         WHERE r.id_room = i_id_room
         ORDER BY rdcs.id_room_dep_clin_serv;
    
        --
        RETURN l_id_room_dcs;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ROOM_DCS',
                                              l_error);
            RETURN NULL;
    END get_room_dcs;
    --

    /********************************************************************************************
    * Get the list of specialties for a given room
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    *
    * @return                         the list specialties ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_room_specialties
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room.id_room%TYPE
    ) RETURN table_number IS
    
        --room_specialties
        l_id_room_specialties table_number := table_number();
    
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'GET_ROOM_SPECIALTIES: i_id_room = ' || i_id_room;
        pk_alertlog.log_debug(g_error);
        --
    
        SELECT dcs.id_clinical_service
          BULK COLLECT
          INTO l_id_room_specialties
          FROM dep_clin_serv dcs
          JOIN room_dep_clin_serv rdcs
            ON (rdcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
         WHERE rdcs.id_room = i_id_room
         ORDER BY rdcs.id_room_dep_clin_serv;
    
        --
        RETURN l_id_room_specialties;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ROOM_SPECIALTIES',
                                              l_error);
            RETURN NULL;
    END get_room_specialties;
    --

    /********************************************************************************************
    * Get a list dep. clinical service (dcs) as a string
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_dcs_list               List of DCS IDs
    *
    * @return                         the list of dcs as a string
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_dcs_list_as_str
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_dcs_list       IN table_number,
        i_separator_char IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        --dcs description
        l_str_final      VARCHAR2(1000 CHAR);
        l_str_length     PLS_INTEGER := 0;
        l_str_length_aux PLS_INTEGER := 0;
        l_str            VARCHAR2(1000 CHAR);
        l_item_count     PLS_INTEGER;
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'GET_DCS_LIST_AS_STR: ';
        pk_alertlog.log_debug(g_error);
        --
        --    
        l_item_count := i_dcs_list.count;
        IF l_item_count = 0
        THEN
            l_str_final := ' ';
        ELSE
            FOR i IN 1 .. l_item_count
            LOOP
                l_str := get_dcs_description(i_lang, i_prof, i_dcs_list(i)) || i_separator_char || ' ';
            
                l_str_length_aux := length(l_str);
                IF l_str_length + l_str_length_aux >= g_max_size_to_select
                THEN
                    l_str_final := l_str_final || substr(l_str, 0, g_max_size_to_select - l_str_length) ||
                                   g_not_complete;
                    EXIT;
                ELSE
                    l_str_final  := l_str_final || l_str;
                    l_str_length := l_str_length + l_str_length_aux;
                END IF;
            END LOOP;
        END IF;
    
        --
        RETURN l_str_final;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DCS_LIST_AS_STR',
                                              l_error);
            RETURN NULL;
    END get_dcs_list_as_str;
    --

    /********************************************************************************************
    * Get a list of specialties as a string
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_specialties_list       List of specialties IDs
    *
    * @return                         the list of specialties as a string
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_specialties_list_as_str
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_specialties_list IN table_number,
        i_separator_char   IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        --dcs description
        l_str_final      VARCHAR2(1000 CHAR);
        l_str_length     PLS_INTEGER := 0;
        l_str_length_aux PLS_INTEGER := 0;
        l_str            VARCHAR2(1000 CHAR);
        l_item_count     PLS_INTEGER;
        l_sep_length     PLS_INTEGER;
        --error
        l_error           t_error_out;
        l_separator_space VARCHAR2(10 CHAR) := i_separator_char || ' ';
    BEGIN
    
        g_error := 'get_specialties_list_as_str: ';
        pk_alertlog.log_debug(g_error);
        --
        --    
        l_item_count := i_specialties_list.count;
        IF l_item_count = 0
        THEN
            l_str_final := ' ';
        ELSE
            l_sep_length := length(l_separator_space);
            FOR i IN 1 .. l_item_count
            LOOP
                l_str := get_specialty_description(i_lang, i_prof, i_specialties_list(i));
            
                l_str_length_aux := length(l_str) + l_sep_length;
                IF l_str_length + l_str_length_aux >= g_max_size_to_select
                THEN
                    l_str_final := l_str_final || substr(l_str, 0, g_max_size_to_select - l_str_length) ||
                                   g_not_complete;
                    EXIT;
                ELSE
                
                    IF i < l_item_count
                    THEN
                        l_str_final := l_str_final || l_str || l_separator_space;
                    ELSE
                        l_str_final := l_str_final || l_str;
                    END IF;
                    l_str_length := l_str_length + l_str_length_aux;
                END IF;
            END LOOP;
        END IF;
        --
        RETURN l_str_final;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_SPECIALTIES_LIST_AS_STR',
                                              l_error);
            RETURN NULL;
    END get_specialties_list_as_str;
    --

    /********************************************************************************************
    * Get the list of rooms for a given institution with all details that includes:
    *     Number of beds, room type, Service, Specialtya and status
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_institution         Institution ID
    * @param o_rooms                  List of Rooms
    * @param o_beds                   List of beds for the selected room
    * @param o_screen_labels          Screen labels
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_room_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_room       IN VARCHAR2,
        o_room          OUT pk_types.cursor_type,
        o_beds          OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'get_room_edit: i_id_room =' || i_id_room;
        pk_alertlog.log_debug(g_error);
        --
    
        IF i_id_room IS NULL
        THEN
            OPEN o_room FOR
                SELECT NULL id_room,
                       NULL flg_selected_specialties,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) room_name_title,
                       NULL room_name_desc,
                       NULL room_name_flg,
                       --abbreviation
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T775'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) room_abbreviation_title,
                       NULL room_abbreviation_desc,
                       NULL room_abbreviation_flg,
                       --Category
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T768'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) room_category_title,
                       NULL room_category_desc,
                       NULL room_category_flg,
                       --Type
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T375'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) room_type_title,
                       NULL room_type_desc,
                       NULL room_type_flg,
                       --service
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T369'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) room_service_title,
                       NULL room_service_desc,
                       NULL room_service_flg,
                       --specialties
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T776'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) room_specialties_title,
                       NULL room_specialties_desc,
                       NULL room_specialties_flg,
                       --Floor
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T637'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) room_floor_title,
                       NULL room_floor_desc,
                       NULL room_floor_flg,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) room_state_title,
                       pk_sysdomain.get_domain('ROOM.FLG_AVAILABLE', pk_alert_constant.g_yes, i_lang) room_state_desc,
                       pk_alert_constant.g_yes room_state_flg,
                       pk_alert_constant.g_yes flg_available,
                       -- Capacity
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_ROOM_T006'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) room_capacity,
                       NULL capacity
                  FROM dual;
            --
            pk_types.open_my_cursor(o_beds);
            --
        ELSE
            OPEN o_room FOR
                SELECT r.id_room                  id_room,
                       r.flg_selected_specialties flg_selected_specialties,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) room_name_title,
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name_desc,
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name_flg,
                       --abbreviation
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T775'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) room_abbreviation_title,
                       nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)) room_abbreviation_desc,
                       nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)) room_abbreviation_flg,
                       --Category
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T768'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) room_category_title,
                       rtrim(concat(decode(r.flg_prof,
                                           pk_alert_constant.g_yes,
                                           pk_sysdomain.get_domain('INSTITUTION_ROOM_TYPES', 'P', i_lang) || ', ',
                                           ''),
                                    concat(decode(r.flg_recovery,
                                                  pk_alert_constant.g_yes,
                                                  pk_sysdomain.get_domain('INSTITUTION_ROOM_TYPES', 'R', i_lang) || ', ',
                                                  ''),
                                           concat(decode(r.flg_lab,
                                                         pk_alert_constant.g_yes,
                                                         pk_sysdomain.get_domain('INSTITUTION_ROOM_TYPES', 'L', i_lang) || ', ',
                                                         ''),
                                                  concat(decode(r.flg_wait,
                                                                pk_alert_constant.g_yes,
                                                                pk_sysdomain.get_domain('INSTITUTION_ROOM_TYPES',
                                                                                        'W',
                                                                                        i_lang) || ', ',
                                                                ''),
                                                         concat(decode(r.flg_wl,
                                                                       pk_alert_constant.g_yes,
                                                                       pk_sysdomain.get_domain('INSTITUTION_ROOM_TYPES',
                                                                                               'C',
                                                                                               i_lang) || ', ',
                                                                       ''),
                                                                decode(r.flg_transp,
                                                                       pk_alert_constant.g_yes,
                                                                       pk_sysdomain.get_domain('INSTITUTION_ROOM_TYPES',
                                                                                               'T',
                                                                                               i_lang) || ', ',
                                                                       '')))))),
                             ', ') room_category_desc,
                       pk_utils.str_split(TRIM(trailing ',' FROM
                                               concat(decode(r.flg_prof, pk_alert_constant.g_yes, 'P,', ''),
                                                      concat(decode(r.flg_recovery, pk_alert_constant.g_yes, 'R,', ''),
                                                             concat(decode(r.flg_lab, pk_alert_constant.g_yes, 'L,', ''),
                                                                    concat(decode(r.flg_wait,
                                                                                  pk_alert_constant.g_yes,
                                                                                  'W,',
                                                                                  ''),
                                                                           concat(decode(r.flg_wl,
                                                                                         pk_alert_constant.g_yes,
                                                                                         'C,',
                                                                                         ''),
                                                                                  decode(r.flg_transp,
                                                                                         pk_alert_constant.g_yes,
                                                                                         'T,',
                                                                                         ''))))))),
                                          ',') room_category_flg,
                       
                       --Type
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T375'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) room_type_title,
                       nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_type_desc,
                       rt.id_room_type room_type_flg,
                       --service
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T369'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) room_service_title,
                       -- RG: added department information in the grid
                       pk_translation.get_translation(i_lang, d.code_department) || ' ' ||
                       pk_message.get_message(i_lang, 'ADM_REQUEST_T081') || ' ' ||
                       pk_translation.get_translation(i_lang, 'DEPT.CODE_DEPT.' || d.id_dept) room_service_desc,
                       d.id_department room_service_flg,
                       --specialties
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T776'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) room_specialties_title,
                       get_specialties_list_as_str(i_lang, i_prof, get_room_specialties(i_lang, i_prof, i_id_room), ',') room_specialties_desc,
                       get_room_dcs(i_lang, i_prof, i_id_room) room_specialties_flg,
                       --Floor
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T637'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) room_floor_title,
                       get_room_floor_desc(i_lang, r.id_room) room_floor_desc,
                       r.id_floors_department room_floor_flg,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) room_state_title,
                       pk_sysdomain.get_domain('ROOM.FLG_AVAILABLE', r.flg_available, i_lang) room_state_desc,
                       r.flg_available room_state_flg,
                       has_all_beds_available(i_lang, r.id_room) flg_available,
                       -- Capacity
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_ROOM_T006'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) room_capacity,
                       r.capacity
                  FROM room r
                  LEFT JOIN room_type rt
                    ON rt.id_room_type = r.id_room_type
                  JOIN department d
                    ON d.id_department = r.id_department
                 WHERE r.id_room = i_id_room;
        
            --get_beds
            IF NOT get_beds_edit(i_lang    => i_lang,
                                 i_prof    => i_prof,
                                 i_id_room => i_id_room,
                                 o_beds    => o_beds,
                                 o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
        --
        --
        g_error := 'GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --    
        OPEN o_screen_labels FOR
            SELECT decode(i_id_room,
                          NULL,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T773'),
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T772')) main_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T774') sub_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T777') grid_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T163') name_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T375') type_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T778') condition_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T776') specialties_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T644') date_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T332') status_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T228') all_msg,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T053') none_msg
              FROM dual;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_room);
            pk_types.open_my_cursor(o_beds);
            pk_types.open_my_cursor(o_screen_labels);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_ROOM_EDIT',
                                                     o_error);
        
    END get_room_edit;
    --

    /*******************************************
    |                  Beds                    |
    ********************************************/

    /********************************************************************************************
    * Get the list of bed for a given room
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    * @param o_rooms                  List of Beds
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_beds_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN institution.id_institution%TYPE,
        o_beds    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'get_beds_list: i_id_room =' || i_id_room;
        pk_alertlog.log_debug(g_error);
        --
    
        OPEN o_beds FOR
            SELECT b.id_bed                   id_bed,
                   b.flg_selected_specialties flg_selected_specialties,
                   --name
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_name_desc,
                   --type
                   nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) bed_type_desc,
                   --specialties
                   get_specialties_list_as_str(i_lang, i_prof, get_bed_specialties(i_lang, i_prof, i_id_room), ',') bed_specialties_desc,
                   --date
                   pk_date_utils.dt_chr_tsz(i_lang, b.dt_last_update, i_prof) bed_date,
                   --state
                   pk_sysdomain.get_domain('BED.FLG_AVAILABLE', b.flg_available, i_lang) bed_state_desc,
                   --
                   b.flg_status flg_status,
                   pk_bmng.is_bed_available(i_lang, b.id_bed) flg_available
              FROM bed b
              JOIN bed_type bt
                ON bt.id_bed_type = b.id_bed_type
             WHERE b.id_room = i_id_room
             ORDER BY b.flg_available DESC, bed_name_desc, bed_type_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_beds);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_BEDS_LIST',
                                                     o_error);
        
    END get_beds_list;
    --

    /********************************************************************************************
    * Get the list of beds for a given room with all information to edit the room
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    * @param o_rooms                  List of Beds
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/07
    **********************************************************************************************/
    FUNCTION get_beds_edit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN VARCHAR2,
        o_beds    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'get_beds_list: i_id_room =' || i_id_room;
        pk_alertlog.log_debug(g_error);
    
        OPEN o_beds FOR
            SELECT b.id_bed                   id_bed,
                   b.flg_selected_specialties flg_selected_specialties,
                   --name
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_name_desc,
                   --type
                   nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) bed_type_desc,
                   bt.id_bed_type bed_type_flg,
                   --specialties
                   get_bed_room_dcs_match(i_lang, i_prof, i_id_room, b.id_bed) desc_specialty,
                   get_bed_dcs(i_lang, i_prof, b.id_bed) id_dcs,
                   --date
                   pk_date_utils.dt_chr_tsz(i_lang, b.dt_last_update, i_prof) bed_date,
                   --state
                   pk_sysdomain.get_domain('BED.FLG_AVAILABLE', b.flg_available, i_lang) bed_state_desc,
                   b.flg_available bed_state_flg,
                   --
                   b.flg_status flg_status,
                   pk_bmng.is_bed_available(i_lang, b.id_bed) flg_available
              FROM bed b
            --JOIN bed r ON r.id_bed = b.id_bed
              LEFT OUTER JOIN bed_type bt
                ON b.id_bed_type = bt.id_bed_type
             WHERE b.id_room = i_id_room
               AND (b.flg_bed_status IS NULL OR b.flg_bed_status <> pk_alert_constant.g_flg_status_c)
               AND b.flg_type = g_bed_type_permanent_p
             ORDER BY b.flg_available DESC, bed_name_desc, bed_type_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_beds);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_BEDS_EDIT',
                                                     o_error);
        
    END get_beds_edit;
    --

    /********************************************************************************************
    * Get the list of bed for a given room
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    * @param o_rooms                  List of Beds
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_bed_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_bed        IN institution.id_institution%TYPE,
        o_bed           OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'get_bed_edit: i_id_bed =' || i_id_bed;
        pk_alertlog.log_debug(g_error);
        --
    
        IF i_id_bed IS NULL
        THEN
            OPEN o_bed FOR
                SELECT NULL id_bed,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) bed_name_title,
                       NULL bed_name_desc,
                       NULL bed_name_flg,
                       --Type
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T375'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) bed_type_title,
                       NULL bed_type_desc,
                       NULL bed_type_flg,
                       --specialties
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T776'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) bed_specialties_title,
                       NULL bed_specialties_desc,
                       NULL bed_specialties_flg,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) bed_state_title,
                       pk_sysdomain.get_domain('BED.FLG_AVAILABLE', pk_alert_constant.g_yes, i_lang) bed_state_desc,
                       pk_alert_constant.g_yes bed_state_flg,
                       pk_alert_constant.g_yes flg_available
                  FROM dual;
        ELSE
        
            OPEN o_bed FOR
                SELECT b.id_bed id_bed,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) bed_name_title,
                       nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_name_desc,
                       nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_name_flg,
                       --Type
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T375'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) bed_type_title,
                       nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) bed_type_desc,
                       bt.id_bed_type bed_type_flg,
                       --specialties
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T776'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_no) bed_specialties_title,
                       get_specialties_list_as_str(i_lang, i_prof, get_bed_specialties(i_lang, i_prof, i_id_bed), ',') bed_specialties_desc,
                       get_bed_specialties(i_lang, i_prof, i_id_bed) bed_specialties_flg,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332'),
                                                                          pk_alert_constant.g_yes,
                                                                          pk_alert_constant.g_yes) bed_state_title,
                       pk_sysdomain.get_domain('BED.FLG_AVAILABLE', b.flg_available, i_lang) bed_state_desc,
                       b.flg_available bed_state_flg,
                       pk_bmng.is_bed_available(i_lang, b.id_bed) flg_available
                  FROM bed b
                  JOIN bed_type bt
                    ON bt.id_bed_type = b.id_bed_type
                 WHERE b.id_bed = i_id_bed;
        
        END IF;
    
        --
        g_error := 'GET_SCREEN_LABELS: ';
        pk_alertlog.log_debug(g_error);
        --    
        OPEN o_screen_labels FOR
            SELECT decode(i_id_bed,
                          NULL,
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T783'),
                          pk_message.get_message(i_lang, 'ADMINISTRATOR_T782')) main_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T774') sub_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T777') grid_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T163') name_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T375') type_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T778') condition_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T776') specialties_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T644') date_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T332') status_column_header,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T228') all_msg,
                   pk_message.get_message(i_lang, 'ADMINISTRATOR_T053') none_msg
              FROM dual;
        --
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_bed);
            pk_types.open_my_cursor(o_screen_labels);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_BED_EDIT',
                                                     o_error);
        
    END get_bed_edit;
    --

    /********************************************************************************************
    * Get the list of specialties for a given bed
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_bed                 Bed ID
    *
    * @return                         the list specialties ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/31
    **********************************************************************************************/
    FUNCTION get_bed_specialties
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN table_number IS
    
        --room_specialties
        l_id_bed_specialties table_number := table_number();
    
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'GET_BED_SPECIALTIES: i_id_bed = ' || i_id_bed;
        pk_alertlog.log_debug(g_error);
        --
    
        SELECT dcs.id_clinical_service
          BULK COLLECT
          INTO l_id_bed_specialties
          FROM dep_clin_serv dcs
          JOIN bed_dep_clin_serv bdcs
            ON (bdcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
         WHERE bdcs.id_bed = i_id_bed
           AND dcs.id_clinical_service IN
               (SELECT cs.id_clinical_service id_specialty
                  FROM dep_clin_serv dcs
                  JOIN clinical_service cs
                    ON (dcs.id_clinical_service = cs.id_clinical_service)
                  JOIN department d
                    ON (dcs.id_department = d.id_department)
                 WHERE cs.flg_available = pk_alert_constant.g_yes
                   AND dcs.flg_available = pk_alert_constant.g_yes
                   AND dcs.id_department = (SELECT d.id_department
                                              FROM bed b
                                              JOIN room r
                                                ON r.id_room = b.id_room
                                              JOIN department d
                                                ON d.id_department = r.id_department
                                               AND d.id_institution = i_prof.institution
                                             WHERE b.id_bed = i_id_bed)
                   AND pk_translation.get_translation(i_lang, cs.code_clinical_service) IS NOT NULL)
         ORDER BY bdcs.id_dep_clin_serv;
    
        --
        RETURN l_id_bed_specialties;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_BED_SPECIALTIES',
                                              l_error);
            RETURN NULL;
    END get_bed_specialties;
    --

    /********************************************************************************************
    * Get the list of specialties for a given bed history record
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_bed_hist            Bed history Id
    *
    * @return                         the list specialties ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/18
    **********************************************************************************************/
    FUNCTION get_bed_hist_specialties
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_bed_hist IN bed_hist.id_bed_hist%TYPE
    ) RETURN table_number IS
    
        --bed_hist_specialties
        l_id_bed_specialties table_number := table_number();
    
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'get_bed_hist_specialties:';
        pk_alertlog.log_debug(g_error);
        --
    
        SELECT dcs.id_clinical_service
          BULK COLLECT
          INTO l_id_bed_specialties
          FROM dep_clin_serv dcs
          JOIN bed_dep_clin_serv_hist bdh
            ON bdh.id_dep_clin_serv = dcs.id_dep_clin_serv
         WHERE bdh.id_bed_hist = i_id_bed_hist
           AND bdh.flg_available = pk_alert_constant.g_yes;
    
        --
        RETURN l_id_bed_specialties;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_BED_HIST_SPECIALTIES',
                                              l_error);
            RETURN NULL;
    END get_bed_hist_specialties;
    --

    /********************************************************************************************
    * Get the list of dep. clinical service (dcs) for a given bed
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_bed                 Bed ID
    *
    * @return                         the list dcs ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION get_bed_dcs
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN table_number IS
    
        --room_dcs
        l_id_bed_dcs table_number := table_number();
    
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'GET_BED_SPECIALTIES: i_id_bed = ' || i_id_bed;
        pk_alertlog.log_debug(g_error);
        --
    
        SELECT dcs.id_dep_clin_serv
          BULK COLLECT
          INTO l_id_bed_dcs
          FROM dep_clin_serv dcs
          JOIN bed_dep_clin_serv bdcs
            ON (bdcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
         WHERE bdcs.id_bed = i_id_bed
         ORDER BY bdcs.id_dep_clin_serv;
    
        --
        RETURN l_id_bed_dcs;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_BED_DCS',
                                              l_error);
            RETURN NULL;
    END get_bed_dcs;
    --

    /********************************************************************************************
    * Get the list of beds for a given room
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    *
    * @return                         the list beds ids
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION get_room_beds
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room.id_room%TYPE
    ) RETURN table_number IS
    
        --room_dcs
        l_id_bed_list table_number := table_number();
    
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'get_room_beds: i_id_room = ' || i_id_room;
        pk_alertlog.log_debug(g_error);
        --
    
        SELECT b.id_bed
          BULK COLLECT
          INTO l_id_bed_list
          FROM bed b
         WHERE b.id_room = i_id_room
         ORDER BY b.id_bed;
    
        --
        RETURN l_id_bed_list;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ROOM_BEDS',
                                              l_error);
            RETURN NULL;
    END get_room_beds;
    --

    /********************************************************************************************
    * Create or edit a room and all the beds associated with it.
    *
    * @param i_lang                       Preferred language ID for this professional 
    * @param i_prof                       Object (professional ID, institution ID, software ID)
    * @ param i_id_institution            Institution ID 
    * @ param i_id_room                   Room ID (not null only for the edit operation)
    *--
    * @ param i_name                      room name
    * @ param i_abbreviation              room abbreviation
    * @ param i_category                  room category
    * @ param i_room_type                 room type
    * @ param i_room_service              select room service
    * @ param i_room_specialties          list of specialties
    * @ param i_flg_selected_spec         Flag that indicates the type of selection of specialties: 
    *                                     A - all, N - none, O - other
    * @ param i_state                     room state (Y - active/N - Inactive)
    * @ param i_beds_name                 array with beds names
    * @ param i_beds_type                 array with beds types
    * @ param i_beds_specialties          array with beds specialties
    * @ param i_beds_flg_selected_spec    array with flags indicating the type of selection of specialties: 
    *                                     A - all, N - none, O - other
    * @ param i_beds_state                array with beds states (Y - active/N - Inactive)
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION set_room
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_room        IN room.id_room%TYPE,
        --
        i_name              IN room.code_room%TYPE,
        i_abbreviation      IN room.code_room%TYPE,
        i_category          IN table_varchar,
        i_room_type         IN room_type.id_room_type%TYPE,
        i_room_service      IN room.id_department%TYPE,
        i_room_specialties  IN table_number,
        i_flg_selected_spec IN room.flg_selected_specialties%TYPE,
        i_floors_department IN floors_department.id_floors_department%TYPE,
        i_state             IN room.flg_available%TYPE,
        --beds
        i_beds_id                IN table_number,
        i_beds_name              IN table_varchar,
        i_beds_type              IN table_number,
        i_beds_specialties       IN table_table_number,
        i_beds_flg_selected_spec IN table_varchar,
        i_beds_state             IN table_varchar,
        --
        i_capacity IN room.capacity%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_room        room.id_room%TYPE;
        l_room_code      VARCHAR2(100 CHAR) := 'ROOM.CODE_ROOM.';
        l_room_abbr_code VARCHAR2(100 CHAR) := 'ROOM.CODE_ABBREVIATION.';
    
        l_flg_prof      VARCHAR2(1) := 'N';
        l_flg_recovery  VARCHAR2(1) := 'N';
        l_flg_lab       VARCHAR2(1) := 'N';
        l_flg_wait      VARCHAR2(1) := 'N';
        l_flg_wl        VARCHAR2(1) := 'N';
        l_flg_transp    VARCHAR2(1) := 'N';
        l_flg_icu       VARCHAR2(1) := pk_alert_constant.g_no;
        l_room_type_nin BOOLEAN := TRUE;
    
        --specialties current defined:
        l_cur_room_specialties table_number := table_number();
        l_new_room_dcs_list    table_number := table_number();
        --new list of beds(to delete)
        l_cur_beds_list table_number := table_number();
        l_new_beds_list table_number := table_number();
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_room_row room%ROWTYPE;
        --
        l_id_room_hist room_hist.id_room_hist%TYPE;
    
        --TRANSLATION
        l_id_lang language.id_language%TYPE;
    
        l_id_room_dep_clin_serv room_dep_clin_serv.id_room_dep_clin_serv%TYPE;
    
        CURSOR c_language IS
            SELECT l.id_language
              FROM LANGUAGE l
             WHERE l.flg_available = pk_alert_constant.g_available;
    BEGIN
        --
        g_error := 'SET_ROOM: i_id_room =' || i_id_room || ', i_name = ' || i_name || ', i_state=' || i_state;
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := current_timestamp;
    
        --room flags:
        --find the room category and set the correspondent flag:
        FOR i IN 1 .. i_category.count
        LOOP
            CASE i_category(i)
                WHEN 'P' THEN
                    l_flg_prof := 'Y';
                WHEN 'R' THEN
                    l_flg_recovery := 'Y';
                WHEN 'L' THEN
                    l_flg_lab := 'Y';
                WHEN 'W' THEN
                    l_flg_wait := 'Y';
                WHEN 'C' THEN
                    l_flg_wl := 'Y';
                WHEN 'T' THEN
                    l_flg_transp := 'Y';
                WHEN 'I' THEN
                    l_flg_icu := pk_alert_constant.g_yes;
                
            END CASE;
        END LOOP;
    
        g_error := 'SET_ROOM';
        IF i_id_room IS NULL
        THEN
        
            l_id_room := pk_backoffice.get_next_value('ROOM', i_id_institution);
        
            g_error := 'INSERT_INTO ROOM: l_id_room =' || l_id_room || ', i_name = ' || i_name;
            pk_alertlog.log_debug(g_error);
            --
        
            ts_room.ins(id_room_in                   => l_id_room,
                        id_department_in             => i_room_service,
                        rank_in                      => 0,
                        flg_available_in             => i_state,
                        flg_prof_in                  => l_flg_prof,
                        flg_recovery_in              => l_flg_recovery,
                        flg_lab_in                   => l_flg_lab,
                        flg_wait_in                  => l_flg_wait,
                        flg_wl_in                    => l_flg_wl,
                        flg_transp_in                => l_flg_transp,
                        id_floors_department_in      => i_floors_department,
                        code_room_in                 => l_room_code || l_id_room,
                        code_abbreviation_in         => l_room_abbr_code || l_id_room,
                        id_room_type_in              => i_room_type,
                        flg_parameterization_type_in => g_backoffice_parameterization,
                        flg_status_in                => pk_alert_constant.g_flg_status_a,
                        flg_selected_specialties_in  => i_flg_selected_spec,
                        id_professional_in           => i_prof.id,
                        dt_creation_in               => g_sysdate_tstz,
                        dt_last_update_in            => g_sysdate_tstz,
                        desc_room_in                 => i_name,
                        desc_room_abbreviation_in    => i_abbreviation,
                        capacity_in                  => i_capacity,
                        flg_icu_in                   => l_flg_icu,
                        rows_out                     => l_rows_out);
        
            g_error := 'INSERT_INTO_TRANSLATION ROOM';
            --Set the translation for all languages because the code_room are being used in many packages and this is how is done in Backofice.
            --In a future version this should be fixed, and should be used only the desc_room column!
            OPEN c_language;
            LOOP
                FETCH c_language
                    INTO l_id_lang;
                EXIT WHEN c_language%NOTFOUND;
            
                pk_translation.insert_into_translation(i_lang       => l_id_lang,
                                                       i_code_trans => l_room_code || l_id_room,
                                                       i_desc_trans => i_name);
                pk_translation.insert_into_translation(i_lang       => l_id_lang,
                                                       i_code_trans => l_room_abbr_code || l_id_room,
                                                       i_desc_trans => i_abbreviation);
            
            END LOOP;
            CLOSE c_language;
        
            --                    
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ROOM',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            l_id_room_hist := seq_room_hist.nextval;
            --history
            INSERT INTO room_hist
                (id_room_hist,
                 id_room,
                 id_department,
                 rank,
                 flg_available,
                 flg_prof,
                 flg_recovery,
                 flg_lab,
                 flg_wait,
                 flg_wl,
                 flg_transp,
                 id_floors_department,
                 code_room,
                 code_abbreviation,
                 id_room_type,
                 flg_parameterization_type,
                 flg_status,
                 flg_selected_specialties,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_room,
                 desc_room_abbreviation,
                 capacity)
            VALUES
                (l_id_room_hist,
                 l_id_room,
                 i_room_service,
                 0,
                 i_state,
                 l_flg_prof,
                 l_flg_recovery,
                 l_flg_lab,
                 l_flg_wait,
                 l_flg_wl,
                 l_flg_transp,
                 i_floors_department,
                 l_room_code || l_id_room,
                 l_room_abbr_code || l_id_room,
                 i_room_type,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_a,
                 i_flg_selected_spec,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 i_name,
                 i_abbreviation,
                 i_capacity);
        
            --set to all DCS
            pk_alertlog.log_debug('Associate the room with all given DCS(Service/Specialties)');
            IF i_room_specialties IS NOT NULL
               AND i_room_specialties.count > 0
            THEN
                FOR i IN 1 .. i_room_specialties.count
                LOOP
                    g_error := 'INSERT INTO ROOM_DEP_CLIN_SERV';
                    pk_alertlog.log_debug(g_error);
                
                    l_id_room_dep_clin_serv := seq_room_dep_clin_serv.nextval;
                
                    INSERT INTO room_dep_clin_serv
                        (id_room_dep_clin_serv, id_room, id_dep_clin_serv)
                    VALUES
                        (l_id_room_dep_clin_serv, l_id_room, i_room_specialties(i));
                
                    ts_room_dep_clin_serv_hist.ins(id_room_hist_in          => l_id_room_hist,
                                                   id_room_dep_clin_serv_in => l_id_room_dep_clin_serv,
                                                   id_room_in               => l_id_room,
                                                   id_dep_clin_serv_in      => i_room_specialties(i),
                                                   rows_out                 => l_rows_out);
                END LOOP;
            END IF;
        
            -----------------------BEDS-------------------------
            FOR j IN 1 .. i_beds_name.count
            LOOP
                --set_bed
                IF NOT set_bed(i_lang                  => i_lang,
                               i_prof                  => i_prof,
                               i_id_institution        => i_id_institution,
                               i_id_room               => l_id_room,
                               i_id_room_hist          => l_id_room_hist,
                               i_bed_id                => NULL,
                               i_bed_name              => i_beds_name(j),
                               i_bed_type              => i_beds_type(j),
                               i_bed_specialties       => i_beds_specialties(j),
                               i_bed_flg_selected_spec => i_beds_flg_selected_spec(j),
                               i_bed_state             => i_beds_state(j),
                               i_bed_date              => g_sysdate_tstz,
                               i_commit                => pk_alert_constant.g_no,
                               o_error                 => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END LOOP;
        ELSE
            IF i_room_type IS NULL
            THEN
                l_room_type_nin := FALSE;
            ELSE
                l_room_type_nin := TRUE;
            END IF;
            g_error := 'UPDATE ROOM';
            pk_alertlog.log_debug(g_error);
            --
        
            -----//------
            ts_room.upd(id_room_in                  => i_id_room,
                        id_department_in            => i_room_service,
                        flg_available_in            => i_state,
                        flg_prof_in                 => l_flg_prof,
                        flg_recovery_in             => l_flg_recovery,
                        flg_lab_in                  => l_flg_lab,
                        flg_wait_in                 => l_flg_wait,
                        flg_wl_in                   => l_flg_wl,
                        flg_transp_in               => l_flg_transp,
                        id_floors_department_in     => i_floors_department,
                        id_room_type_in             => i_room_type,
                        id_room_type_nin            => l_room_type_nin,
                        flg_status_in               => pk_alert_constant.g_flg_status_e,
                        flg_selected_specialties_in => i_flg_selected_spec,
                        desc_room_in                => i_name,
                        dt_last_update_in           => g_sysdate_tstz,
                        desc_room_abbreviation_in   => i_abbreviation,
                        capacity_nin                => FALSE,
                        capacity_in                 => i_capacity,
                        flg_icu_in                  => l_flg_icu,
                        rows_out                    => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ROOM',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            g_error := 'UPDATE_TRANSLATION ROOM';
            --Set the translation for all languages because the code_room are being used in many packages and this is how is done in Backofice.
            --In a future version this should be fixed, and should be used only the desc_room column!
            OPEN c_language;
            LOOP
                FETCH c_language
                    INTO l_id_lang;
                EXIT WHEN c_language%NOTFOUND;
            
                pk_translation.insert_into_translation(i_lang       => l_id_lang,
                                                       i_code_trans => l_room_code || i_id_room,
                                                       i_desc_trans => i_name);
                pk_translation.insert_into_translation(i_lang       => l_id_lang,
                                                       i_code_trans => l_room_abbr_code || i_id_room,
                                                       i_desc_trans => i_abbreviation);
            END LOOP;
            CLOSE c_language;

            --history
            SELECT *
              INTO l_room_row
              FROM room r
             WHERE r.id_room = i_id_room;
        
            --get_next_key
            SELECT seq_room_hist.nextval
              INTO l_id_room_hist
              FROM dual;
        
            --history
            INSERT INTO room_hist
                (id_room_hist,
                 id_room,
                 id_department,
                 rank,
                 flg_available,
                 flg_prof,
                 flg_recovery,
                 flg_lab,
                 flg_wait,
                 flg_wl,
                 flg_transp,
                 id_floors_department,
                 code_room,
                 code_abbreviation,
                 id_room_type,
                 flg_parameterization_type,
                 flg_status,
                 flg_selected_specialties,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_room,
                 desc_room_abbreviation,
                 capacity)
            VALUES
                (l_id_room_hist,
                 i_id_room,
                 i_room_service,
                 0,
                 i_state,
                 l_flg_prof,
                 l_flg_recovery,
                 l_flg_lab,
                 l_flg_wait,
                 l_flg_wl,
                 l_flg_transp,
                 i_floors_department,
                 l_room_code || l_id_room,
                 l_room_abbr_code || l_id_room,
                 i_room_type,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_e,
                 i_flg_selected_spec,
                 i_prof.id,
                 g_sysdate_tstz,
                 g_sysdate_tstz,
                 i_name,
                 i_abbreviation,
                 i_capacity);
        
            -----//----
            g_error := 'UPDATE The list of specialties for the room';
            pk_alertlog.log_debug(g_error);
        
            --new_list_of_dcs - delete the ones that are not being used, and create the new ones.
            l_cur_room_specialties := get_room_dcs(i_lang, i_prof, i_id_room);
        
            IF l_cur_room_specialties IS NOT NULL
               AND i_room_specialties IS NOT NULL
            THEN
                --delete not used dcs
                l_new_room_dcs_list := l_cur_room_specialties MULTISET except i_room_specialties;
                IF l_new_room_dcs_list IS NOT NULL
                   AND l_new_room_dcs_list.count > 0
                THEN
                    FOR i IN 1 .. l_new_room_dcs_list.count
                    LOOP
                        pk_alertlog.log_debug('DELETE NOT USED DCS FROM ROOM_DEP_CLIN_SERV : room_dep_clin_serv' ||
                                              l_new_room_dcs_list(i));
                    
                        DELETE FROM room_dep_clin_serv rdcs
                         WHERE rdcs.id_room = i_id_room
                           AND rdcs.id_dep_clin_serv = l_new_room_dcs_list(i);
                    END LOOP;
                END IF;
                --
                --create the new dcs
                l_new_room_dcs_list := i_room_specialties MULTISET except l_cur_room_specialties;
                IF l_new_room_dcs_list IS NOT NULL
                   AND l_new_room_dcs_list.count > 0
                THEN
                    FOR i IN 1 .. l_new_room_dcs_list.count
                    LOOP
                        pk_alertlog.log_debug('INSERT INTO ROOM_DEP_CLIN_SERV_2: l_new_room_dcs_list' ||
                                              l_new_room_dcs_list(i));
                    
                        INSERT INTO room_dep_clin_serv
                            (id_room_dep_clin_serv, id_room, id_dep_clin_serv)
                        VALUES
                            (seq_room_dep_clin_serv.nextval, i_id_room, l_new_room_dcs_list(i));
                    
                    END LOOP;
                END IF;
            ELSE
                RAISE g_exception;
            END IF;
        
            IF NOT insert_room_hist(i_lang         => i_lang,
                                    i_id_room_hist => l_id_room_hist,
                                    i_id_room      => i_id_room,
                                    o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'Editing the Beds of the Room: i_id_room' || i_id_room;
            pk_alertlog.log_debug(g_error);
        
            --Find out the beds to cancel - Cancel not used BEDs!
            l_cur_beds_list := get_room_beds(i_lang => i_lang, i_prof => i_prof, i_id_room => i_id_room);
            l_new_beds_list := l_cur_beds_list MULTISET except i_beds_id;
        
            FOR j IN 1 .. i_beds_id.count
            LOOP
                IF i_beds_id(j) IS NULL
                THEN
                    --If there is no ID for the BED is a new BED - create it
                    IF NOT set_bed(i_lang                  => i_lang,
                                   i_prof                  => i_prof,
                                   i_id_institution        => i_id_institution,
                                   i_id_room               => i_id_room,
                                   i_id_room_hist          => l_id_room_hist,
                                   i_bed_id                => NULL,
                                   i_bed_name              => i_beds_name(j),
                                   i_bed_type              => i_beds_type(j),
                                   i_bed_specialties       => i_beds_specialties(j),
                                   i_bed_flg_selected_spec => i_beds_flg_selected_spec(j),
                                   i_bed_state             => i_beds_state(j),
                                   i_bed_date              => g_sysdate_tstz,
                                   i_commit                => pk_alert_constant.g_no,
                                   o_error                 => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSE
                    --If the BED ID is not null the BED already exists - update it
                    IF NOT set_bed(i_lang                  => i_lang,
                                   i_prof                  => i_prof,
                                   i_id_institution        => i_id_institution,
                                   i_id_room               => i_id_room,
                                   i_id_room_hist          => l_id_room_hist,
                                   i_bed_id                => i_beds_id(j),
                                   i_bed_name              => i_beds_name(j),
                                   i_bed_type              => i_beds_type(j),
                                   i_bed_specialties       => i_beds_specialties(j),
                                   i_bed_flg_selected_spec => i_beds_flg_selected_spec(j),
                                   i_bed_state             => i_beds_state(j),
                                   i_bed_date              => g_sysdate_tstz,
                                   i_commit                => pk_alert_constant.g_no,
                                   o_error                 => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            END LOOP;
        
            --Cancel not used BEDs!
            IF l_new_beds_list IS NOT NULL
               AND l_new_beds_list.count > 0
            THEN
                FOR i IN 1 .. l_new_beds_list.count
                LOOP
                    IF NOT cancel_bed(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_id_bed       => l_new_beds_list(i),
                                      i_id_room_hist => l_id_room_hist,
                                      i_commit       => pk_alert_constant.g_no,
                                      o_error        => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END LOOP;
            END IF;
        END IF;
        --
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_ROOM',
                                                     o_error);
        
    END set_room;
    --

    /********************************************************************************************
    * Create a bed.
    *
    * @param i_lang                      Preferred language ID for this professional 
    * @param i_prof                      Object (professional ID, institution ID, software ID)
    * @ param i_id_institution           Institution ID 
    * @ param i_id_room                  Room ID (not null only for the edit operation)
    * @ param i_bed_name                 bed name
    * @ param i_bed_type                 bed type
    * @ param i_bed_specialties          array with bed specialties
    * @ param i_bed_flg_selected_spec    flg indicating the type of selection of specialties: 
    *                                     A - all, N - none, O - other
    * @ param i_bed_state                beds state (Y - active/N - Inactive)
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION set_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_room        IN room.id_room%TYPE,
        i_id_room_hist   IN room_hist.id_room_hist%TYPE,
        --beds
        i_bed_id                IN bed.id_bed%TYPE,
        i_bed_name              IN pk_translation.t_desc_translation,
        i_bed_type              IN bed_type.id_bed_type%TYPE,
        i_bed_specialties       IN table_number,
        i_bed_flg_selected_spec IN VARCHAR2,
        i_bed_state             IN bed.flg_available%TYPE,
        i_bed_date              IN bed.dt_creation%TYPE DEFAULT NULL,
        i_commit                IN VARCHAR2 DEFAULT 'N',
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_bed   bed.id_bed%TYPE;
        l_bed_code VARCHAR2(100 CHAR) := 'BED.CODE_BED.';
        --
        l_cur_bed_specialties table_number := table_number();
        l_new_bed_dcs_list    table_number := table_number();
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_bed_row bed%ROWTYPE;
    
        --TRANSLATION
        l_id_lang language.id_language%TYPE;
    
        CURSOR c_language IS
            SELECT l.id_language
              FROM LANGUAGE l
             WHERE l.flg_available = pk_alert_constant.g_available;
    
        l_id_bed_hist bed_hist.id_bed_hist%TYPE;
    BEGIN
        --
        g_error := 'SET_BED: i_bed_name = ' || i_bed_name || ', i_bed_state = ' || i_bed_state;
        pk_alertlog.log_debug(g_error);
    
        IF i_bed_date IS NOT NULL
        THEN
            g_sysdate_tstz := i_bed_date;
        ELSE
            g_sysdate_tstz := current_timestamp;
        END IF;
    
        IF i_bed_id IS NULL
        THEN
        
            ---//---
            g_error := 'INSERT_INTO BED: i_beds_name =' || i_bed_name;
            pk_alertlog.log_debug(g_error);
            l_id_bed := ts_bed.next_key;
        
            ts_bed.ins(id_bed_in                    => l_id_bed,
                       id_room_in                   => i_id_room,
                       code_bed_in                  => l_bed_code || l_id_bed,
                       flg_type_in                  => g_bed_type_permanent_p,
                       flg_status_in                => g_bed_occupation_v,
                       flg_available_in             => i_bed_state,
                       id_bed_type_in               => i_bed_type,
                       flg_bed_status_in            => pk_alert_constant.g_flg_status_a,
                       flg_parameterization_type_in => g_backoffice_parameterization,
                       id_professional_in           => i_prof.id,
                       flg_selected_specialties_in  => i_bed_flg_selected_spec,
                       dt_creation_in               => g_sysdate_tstz,
                       dt_last_update_in            => g_sysdate_tstz,
                       desc_bed_in                  => i_bed_name,
                       rows_out                     => l_rows_out);
        
            g_error := 'INSERT_TRANSLATION BED';
            --Set the translation for all languages because the code_room are being used in many packages and this is how is done in Backofice.
            --In a future version this should be fixed, and should be used only the desc_room column!
            OPEN c_language;
            LOOP
                FETCH c_language
                    INTO l_id_lang;
                EXIT WHEN c_language%NOTFOUND;
            
                pk_translation.insert_into_translation(i_lang       => l_id_lang,
                                                       i_code_trans => l_bed_code || l_id_bed,
                                                       i_desc_trans => i_bed_name);
            END LOOP;
            CLOSE c_language;
            --                    
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BED',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            l_id_bed_hist := seq_bed_hist.nextval;
            --history
            INSERT INTO bed_hist
                (id_bed_hist,
                 id_bed,
                 code_bed,
                 id_room_hist,
                 flg_type,
                 flg_status,
                 flg_available,
                 id_bed_type,
                 flg_bed_status,
                 flg_parameterization_type,
                 id_professional,
                 flg_selected_specialties,
                 desc_bed,
                 dt_creation,
                 dt_last_update)
            VALUES
                (l_id_bed_hist,
                 l_id_bed,
                 l_bed_code || l_id_bed,
                 i_id_room_hist,
                 g_bed_type_permanent_p,
                 g_bed_occupation_v,
                 i_bed_state,
                 i_bed_type,
                 pk_alert_constant.g_flg_status_a,
                 g_backoffice_parameterization,
                 i_prof.id,
                 i_bed_flg_selected_spec,
                 i_bed_name,
                 g_sysdate_tstz,
                 g_sysdate_tstz);
        
            ---//---
            --set beds to all DCS
            pk_alertlog.log_debug('Associate the bed with all given DCS(Service/Specialties)');
            --
            l_rows_out := table_varchar();
            FOR i IN 1 .. i_bed_specialties.count
            LOOP
                g_error := 'INSERT INTO BED_DEP_CLIN_SERV';
                pk_alertlog.log_debug(g_error);
                INSERT INTO bed_dep_clin_serv
                    (id_bed, id_dep_clin_serv, flg_available)
                VALUES
                    (l_id_bed, i_bed_specialties(i), pk_alert_constant.g_yes);
            
                ts_bed_dep_clin_serv_hist.ins(id_bed_hist_in      => l_id_bed_hist,
                                              id_bed_in           => l_id_bed,
                                              id_dep_clin_serv_in => i_bed_specialties(i),
                                              flg_available_in    => pk_alert_constant.g_yes,
                                              rows_out            => l_rows_out);
            END LOOP;
        ELSE
            -----------------------
            g_error := 'UPDATE BED';
            pk_alertlog.log_debug(g_error);
        
            ---//---            
            ts_bed.upd(id_bed_in                   => i_bed_id,
                       flg_available_in            => i_bed_state,
                       id_bed_type_in              => i_bed_type,
                       flg_bed_status_in           => pk_alert_constant.g_flg_status_e,
                       flg_selected_specialties_in => i_bed_flg_selected_spec,
                       dt_last_update_in           => g_sysdate_tstz,
                       desc_bed_in                 => i_bed_name,
                       rows_out                    => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BED',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            g_error := 'UPDATE_TRANSLATION BED';
            --Set the translation for all languages because the code_room are being used in many packages and this is how is done in Backofice.
            --In a future version this should be fixed, and should be used only the desc_room column!
            OPEN c_language;
            LOOP
                FETCH c_language
                    INTO l_id_lang;
                EXIT WHEN c_language%NOTFOUND;
            
                pk_translation.insert_into_translation(i_lang       => l_id_lang,
                                                       i_code_trans => l_bed_code || i_bed_id,
                                                       i_desc_trans => i_bed_name);
            END LOOP;
            CLOSE c_language;
        
            --history
            SELECT *
              INTO l_bed_row
              FROM bed b
             WHERE b.id_bed = i_bed_id;
        
            l_id_bed_hist := seq_bed_hist.nextval;
            --history
            INSERT INTO bed_hist
                (id_bed_hist,
                 id_bed,
                 code_bed,
                 id_room_hist,
                 flg_type,
                 flg_status,
                 flg_available,
                 id_bed_type,
                 flg_bed_status,
                 flg_parameterization_type,
                 id_professional,
                 flg_selected_specialties,
                 desc_bed,
                 dt_creation,
                 dt_last_update)
            VALUES
                (l_id_bed_hist,
                 i_bed_id,
                 l_bed_row.code_bed,
                 i_id_room_hist,
                 l_bed_row.flg_type,
                 l_bed_row.flg_status,
                 i_bed_state,
                 i_bed_type,
                 pk_alert_constant.g_flg_status_e,
                 g_backoffice_parameterization,
                 i_prof.id,
                 i_bed_flg_selected_spec,
                 i_bed_name,
                 g_sysdate_tstz,
                 g_sysdate_tstz);
        
            ---//---
            --For each bed, update the specialties
            --new_list_of_dcs - delete the ones that are not being used, and create the new ones.
            l_cur_bed_specialties := get_bed_dcs(i_lang, i_prof, i_bed_id);
        
            IF l_cur_bed_specialties IS NOT NULL
               AND i_bed_specialties IS NOT NULL
            THEN
                --delete not used dcs
                l_new_bed_dcs_list := l_cur_bed_specialties MULTISET except i_bed_specialties;
                FOR z IN 1 .. l_new_bed_dcs_list.count
                LOOP
                    pk_alertlog.log_debug('DELETE NOT USED DCS FROM BED_DEP_CLIN_SERV : bed_dep_clin_serv' ||
                                          l_new_bed_dcs_list(z));
                
                    DELETE FROM bed_dep_clin_serv bdcs
                     WHERE bdcs.id_bed = i_bed_id
                       AND bdcs.id_dep_clin_serv = l_new_bed_dcs_list(z);
                END LOOP;
                --
                --create the new dcs
                l_new_bed_dcs_list := i_bed_specialties MULTISET except l_cur_bed_specialties;
                FOR z IN 1 .. l_new_bed_dcs_list.count
                LOOP
                    pk_alertlog.log_debug('INSERT INTO BED_DEP_CLIN_SERV_2: l_new_bed_dcs_list' ||
                                          l_new_bed_dcs_list(z));
                
                    INSERT INTO bed_dep_clin_serv
                        (id_bed, id_dep_clin_serv, flg_available)
                    VALUES
                        (i_bed_id, l_new_bed_dcs_list(z), pk_alert_constant.g_yes);
                
                END LOOP;
            ELSE
                RAISE g_exception;
            END IF;
        
            IF i_bed_specialties IS NOT NULL
            THEN
                FOR i IN 1 .. i_bed_specialties.count
                LOOP
                    ts_bed_dep_clin_serv_hist.ins(id_bed_hist_in      => l_id_bed_hist,
                                                  id_bed_in           => i_bed_id,
                                                  id_dep_clin_serv_in => i_bed_specialties(i),
                                                  flg_available_in    => pk_alert_constant.g_yes,
                                                  rows_out            => l_rows_out);
                END LOOP;
            END IF;
        END IF;
    
        --
        IF i_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_BED',
                                                     o_error);
        
    END set_bed;
    --

    /********************************************************************************************
    * Cancel room.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_room               room ID
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION cancel_room
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room.id_room%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_room_row room%ROWTYPE;
    
        l_id_room_hist room_hist.id_room_hist%TYPE;
    
    BEGIN
        --
        g_error := 'CANCEL_ROOM: i_id_room=' || i_id_room;
        pk_alertlog.log_debug(g_error);
    
        --
        --get_current_time
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_room IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            g_error := 'CANCEL room';
            pk_alertlog.log_debug(g_error);
            --
        
            ts_room.upd(id_room_in        => i_id_room,
                        flg_available_in  => pk_alert_constant.g_no,
                        flg_status_in     => pk_alert_constant.g_flg_status_c,
                        dt_last_update_in => g_sysdate_tstz,
                        rows_out          => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ROOM',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
            --history
            SELECT *
              INTO l_room_row
              FROM room r
             WHERE r.id_room = i_id_room;
        
            l_id_room_hist := seq_room_hist.nextval;
            --history
            INSERT INTO room_hist
                (id_room_hist,
                 id_room,
                 id_department,
                 rank,
                 flg_available,
                 flg_prof,
                 flg_recovery,
                 flg_lab,
                 flg_wait,
                 flg_wl,
                 flg_transp,
                 id_floors_department,
                 code_room,
                 code_abbreviation,
                 id_room_type,
                 flg_parameterization_type,
                 flg_status,
                 flg_selected_specialties,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_room,
                 desc_room_abbreviation)
            VALUES
                (l_id_room_hist,
                 i_id_room,
                 l_room_row.id_department,
                 0,
                 pk_alert_constant.g_no,
                 l_room_row.flg_prof,
                 l_room_row.flg_recovery,
                 l_room_row.flg_lab,
                 l_room_row.flg_wait,
                 l_room_row.flg_wl,
                 l_room_row.flg_transp,
                 l_room_row.id_floors_department,
                 l_room_row.code_room,
                 l_room_row.code_abbreviation,
                 l_room_row.id_room_type,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_c,
                 l_room_row.flg_selected_specialties,
                 i_prof.id,
                 l_room_row.dt_creation,
                 g_sysdate_tstz,
                 l_room_row.desc_room,
                 l_room_row.desc_room_abbreviation);
        
            IF NOT insert_room_hist(i_lang         => i_lang,
                                    i_id_room_hist => l_id_room_hist,
                                    i_id_room      => i_id_room,
                                    o_error        => o_error)
            THEN
                raise_application_error(-20100, 'Error on inserting Room History With Clinical Service');
            END IF;
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'CANCEL_ROOM',
                                                     o_error);
        
    END cancel_room;
    --

    /********************************************************************************************
    * Cancel bed.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_bed                bed ID
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/02
    **********************************************************************************************/
    FUNCTION cancel_bed
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_bed       IN bed.id_bed%TYPE,
        i_id_room_hist IN room_hist.id_room_hist%TYPE DEFAULT NULL,
        i_commit       IN VARCHAR2 DEFAULT 'N',
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_bed_row bed%ROWTYPE;
    
        l_id_bed_hist     bed_hist.id_bed_hist%TYPE;
        l_bed_specialties table_number := get_bed_specialties(i_lang, i_prof, i_id_bed);
    BEGIN
        --
        g_error := 'cancel_bed: i_id_bed=' || i_id_bed;
        pk_alertlog.log_debug(g_error);
    
        --
        --get_current_time
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_bed IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            g_error := 'CANCEL BED';
            pk_alertlog.log_debug(g_error);
            --
        
            ts_bed.upd(id_bed_in         => i_id_bed,
                       flg_available_in  => pk_alert_constant.g_no,
                       flg_bed_status_in => pk_alert_constant.g_flg_status_c,
                       dt_last_update_in => g_sysdate_tstz,
                       rows_out          => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'BED',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --history
            SELECT *
              INTO l_bed_row
              FROM bed b
             WHERE b.id_bed = i_id_bed;
        
            l_id_bed_hist := seq_bed_hist.nextval;
            --history
            INSERT INTO bed_hist
                (id_bed_hist,
                 id_bed,
                 code_bed,
                 id_room_hist,
                 flg_type,
                 flg_status,
                 flg_available,
                 id_bed_type,
                 flg_bed_status,
                 flg_parameterization_type,
                 id_professional,
                 flg_selected_specialties,
                 desc_bed,
                 dt_creation,
                 dt_last_update)
            VALUES
                (l_id_bed_hist,
                 i_id_bed,
                 l_bed_row.code_bed,
                 i_id_room_hist,
                 l_bed_row.flg_type,
                 l_bed_row.flg_status,
                 pk_alert_constant.g_no,
                 l_bed_row.id_bed_type,
                 pk_alert_constant.g_flg_status_c,
                 g_backoffice_parameterization,
                 i_prof.id,
                 l_bed_row.flg_selected_specialties,
                 l_bed_row.desc_bed,
                 l_bed_row.dt_creation,
                 g_sysdate_tstz);
        
            IF NOT l_bed_specialties IS NOT NULL
            THEN
                FOR i IN 1 .. l_bed_specialties.count
                LOOP
                    ts_bed_dep_clin_serv_hist.ins(id_bed_hist_in      => l_id_bed_hist,
                                                  id_bed_in           => i_id_bed,
                                                  id_dep_clin_serv_in => l_bed_specialties(i),
                                                  flg_available_in    => pk_alert_constant.g_yes,
                                                  rows_out            => l_rows_out);
                END LOOP;
            END IF;
        
        END IF;
    
        IF i_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'CANCEL_BED',
                                                     o_error);
        
    END cancel_bed;
    --

    /********************************************************************************************
    * Set of a new room state.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_institution        Institution ID 
    * @ param i_id_room               room ID 
    * @ param i_state                 Indication state (Y - active/N - Inactive)
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/31
    **********************************************************************************************/
    FUNCTION set_room_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_room        IN room.id_room%TYPE,
        --
        i_state IN room.flg_available%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --created/updated rows
        l_rows_out table_varchar := table_varchar();
        --
        l_room_row     room%ROWTYPE;
        l_id_room_hist room_hist.id_room_hist%TYPE;
    BEGIN
        --
        g_error := 'SET_ROOM_STATE: i_room=' || i_id_room || ', i_state=' || i_state;
        pk_alertlog.log_debug(g_error);
    
        IF i_id_room IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            g_error := 'UPDATE ROOM_STATE';
            pk_alertlog.log_debug(g_error);
            --
        
            ts_room.upd(id_room_in        => i_id_room,
                        flg_available_in  => i_state,
                        flg_status_in     => pk_alert_constant.g_flg_status_e,
                        dt_last_update_in => g_sysdate_tstz,
                        rows_out          => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ROOM',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            --history
            SELECT *
              INTO l_room_row
              FROM room r
             WHERE r.id_room = i_id_room;
        
            l_id_room_hist := seq_room_hist.nextval;
            --history
            INSERT INTO room_hist
                (id_room_hist,
                 id_room,
                 id_department,
                 rank,
                 flg_available,
                 flg_prof,
                 flg_recovery,
                 flg_lab,
                 flg_wait,
                 flg_wl,
                 flg_transp,
                 id_floors_department,
                 code_room,
                 code_abbreviation,
                 id_room_type,
                 flg_parameterization_type,
                 flg_status,
                 flg_selected_specialties,
                 id_professional,
                 dt_creation,
                 dt_last_update,
                 desc_room,
                 desc_room_abbreviation)
            VALUES
                (l_id_room_hist,
                 i_id_room,
                 l_room_row.id_department,
                 0,
                 i_state,
                 l_room_row.flg_prof,
                 l_room_row.flg_recovery,
                 l_room_row.flg_lab,
                 l_room_row.flg_wait,
                 l_room_row.flg_wl,
                 l_room_row.flg_transp,
                 l_room_row.id_floors_department,
                 l_room_row.code_room,
                 l_room_row.code_abbreviation,
                 l_room_row.id_room_type,
                 g_backoffice_parameterization,
                 pk_alert_constant.g_flg_status_e,
                 l_room_row.flg_selected_specialties,
                 i_prof.id,
                 l_room_row.dt_creation,
                 g_sysdate_tstz,
                 l_room_row.desc_room,
                 l_room_row.desc_room_abbreviation);
        
            IF NOT insert_room_hist(i_lang         => i_lang,
                                    i_id_room_hist => l_id_room_hist,
                                    i_id_room      => i_id_room,
                                    o_error        => o_error)
            THEN
                raise_application_error(-20100, 'Error on inserting Room History With Clinical Service');
            END IF;
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_ROOM_STATE',
                                                     o_error);
        
    END set_room_state;
    --

    /********************************************************************************************
    * Get the room detail.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                room ID   
    * @param o_room                   List of rooms
    * @param o_room_prof              List of professional responsible for each room
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION get_room_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_room   IN room_type.id_room_type%TYPE,
        o_room      OUT pk_types.cursor_type,
        o_room_prof OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --
        g_error := 'GET_room_DETAIL: i_id_room = ' || i_id_room;
        pk_alertlog.log_debug(g_error);
    
        --
        IF i_id_room IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
            --get details
            OPEN o_room FOR
                SELECT r.id_room_hist id,
                       --r.flg_selected_specialties flg_selected_specialties,
                       --name
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T163')) ||
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name_desc,
                       --abbreviation
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T775')) ||
                       nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)) room_abbreviation_desc,
                       --Category
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T768')) ||
                       TRIM(trailing ',' FROM
                            concat(decode(r.flg_prof,
                                          pk_alert_constant.g_yes,
                                          pk_sysdomain.get_domain('INSTITUTION_ROOM_TYPES', 'P', i_lang) || ',',
                                          ''),
                                   concat(decode(r.flg_recovery,
                                                 pk_alert_constant.g_yes,
                                                 pk_sysdomain.get_domain('INSTITUTION_ROOM_TYPES', 'R', i_lang) || ',',
                                                 ''),
                                          concat(decode(r.flg_lab,
                                                        pk_alert_constant.g_yes,
                                                        pk_sysdomain.get_domain('INSTITUTION_ROOM_TYPES', 'L', i_lang) || ',',
                                                        ''),
                                                 concat(decode(r.flg_wait,
                                                               pk_alert_constant.g_yes,
                                                               pk_sysdomain.get_domain('INSTITUTION_ROOM_TYPES',
                                                                                       'W',
                                                                                       i_lang) || ',',
                                                               ''),
                                                        concat(decode(r.flg_wl,
                                                                      pk_alert_constant.g_yes,
                                                                      pk_sysdomain.get_domain('INSTITUTION_ROOM_TYPES',
                                                                                              'C',
                                                                                              i_lang) || ',',
                                                                      ''),
                                                               decode(r.flg_transp,
                                                                      pk_alert_constant.g_yes,
                                                                      pk_sysdomain.get_domain('INSTITUTION_ROOM_TYPES',
                                                                                              'T',
                                                                                              i_lang) || ',',
                                                                      ''))))))) room_category_desc,
                       
                       --Type
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T375')) ||
                       nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_type_desc,
                       --service
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                  'ADMINISTRATOR_T369')) ||
                       -- RG: added department information in the grid
                        pk_translation.get_translation(i_lang, d.code_department) || --
                        ' ' || pk_message.get_message(i_lang, 'ADM_REQUEST_T081') || ' ' ||
                        pk_translation.get_translation(i_lang, 'DEPT.CODE_DEPT.' || d.id_dept) room_service_desc,
                       --specialties
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T776')) ||
                       get_specialties_list_as_str(i_lang,
                                                   i_prof,
                                                   get_room_hist_specialties(i_lang, i_prof, r.id_room_hist),
                                                   ',') room_specialties_desc,
                       --Floor
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T637')) ||
                       get_room_floor_desc(i_lang, r.id_room) room_floor_desc,
                       --state
                       pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                 'ADMINISTRATOR_T332')) ||
                       pk_sysdomain.get_domain('ROOM.FLG_AVAILABLE', r.flg_available, i_lang) room_state_desc,
                       ---BEDs---
                       get_beds_detail_str(i_lang, i_prof, r.id_room_hist) beds
                
                  FROM room_hist r
                  LEFT JOIN room_type rt
                    ON rt.id_room_type = r.id_room_type
                  JOIN department d
                    ON d.id_department = r.id_department
                 WHERE r.id_room = i_id_room
                 ORDER BY r.dt_last_update DESC;
        
            OPEN o_room_prof FOR
                SELECT r.id_room_hist id,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, r.dt_last_update, i_prof) dt,
                       pk_tools.get_prof_description(i_lang, i_prof, r.id_professional, r.dt_last_update, NULL) prof_sign,
                       r.dt_last_update,
                       r.flg_status flg_status,
                       decode(r.flg_status,
                              g_active,
                              pk_message.get_message(i_lang, 'DETAIL_COMMON_M001'),
                              pk_sysdomain.get_domain('ROOM_TYPE.FLG_STATUS', r.flg_status, i_lang)) desc_status
                  FROM room_hist r
                 WHERE r.id_room = i_id_room
                 ORDER BY r.dt_last_update DESC;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_room);
            pk_types.open_my_cursor(o_room_prof);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'GET_ROOM_DETAIL',
                                                     o_error);
        
    END get_room_detail;
    --

    /********************************************************************************************
    * Get the room detail.
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                room ID   
    * @param o_room                   List of rooms
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/06/01
    **********************************************************************************************/
    FUNCTION get_beds_detail_str
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room_hist.id_room_hist%TYPE
    ) RETURN CLOB IS
    
        l_beds_list_str CLOB := '';
        l_error         t_error_out;
    
        CURSOR l_beds_list IS
            SELECT chr(10) ||
                    pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                              'ADMINISTRATOR_T163')) || ' ' ||
                    nvl(bh.desc_bed, pk_translation.get_translation(i_lang, bh.code_bed)) || '; ' ||
                    pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                              'ADMINISTRATOR_T375')) || ' ' ||
                    nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) || '; ' ||
                    pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                              'ADMINISTRATOR_T776')) || ' ' ||
                    get_specialties_list_as_str(i_lang,
                                                i_prof,
                                                get_bed_hist_specialties(i_lang, i_prof, bh.id_bed_hist),
                                                ',') ||
                   --           '; '|| pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang, 'ADMINISTRATOR_T644'))|| ' '||pk_date_utils.dt_chr_tsz(i_lang, bh.dt_last_update, i_prof) ||
                    '; ' ||
                    pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                              'ADMINISTRATOR_T332')) || ' ' ||
                    pk_sysdomain.get_domain('BED.FLG_AVAILABLE', bh.flg_available, i_lang) desc_bed
              FROM bed_hist bh
              JOIN bed_type bt
                ON bt.id_bed_type = bh.id_bed_type
             WHERE bh.id_room_hist = i_id_room
               AND bh.flg_bed_status <> pk_alert_constant.g_flg_status_c
               AND bh.flg_type = g_bed_type_permanent_p;
    
    BEGIN
        --
        g_error := 'GET_BEDS_DETAIL: i_id_room = ' || i_id_room;
        pk_alertlog.log_debug(g_error);
    
        --
        IF i_id_room IS NULL
        THEN
            raise_application_error(-20100, 'Invalid Input Parameters');
        ELSE
        
            FOR i IN l_beds_list
            LOOP
                l_beds_list_str := l_beds_list_str || i.desc_bed;
            END LOOP;
        
            IF l_beds_list_str IS NOT NULL
            THEN
                l_beds_list_str := chr(10) ||
                                   pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang,
                                                                                                             'ADMINISTRATOR_T777')) ||
                                   l_beds_list_str;
            END IF;
        END IF;
        --
        RETURN l_beds_list_str;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_BEDS_DETAIL_STR',
                                              l_error);
            RETURN NULL;
    END get_beds_detail_str;
    --

    /********************************************************************************************
    * Get Room Floor description
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_room               Room ID
    *
    *
    * @return                      Floor description
    *
    * @author                      Orlando Antunes
    * @version                     2.6.0.3
    * @since                       2010/06/02
    ********************************************************************************************/
    FUNCTION get_room_floor_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_id_room IN room.id_room%TYPE
    ) RETURN VARCHAR IS
    
        l_floor_desc pk_translation.t_desc_translation;
        --error
        l_error t_error_out;
    BEGIN
    
        SELECT (SELECT pk_translation.get_translation(i_lang, f.code_floors)
                  FROM room r, floors_department fd, floors_institution fi, floors f
                 WHERE r.id_room = i_id_room
                   AND r.id_floors_department = fd.id_floors_department
                   AND fd.id_floors_institution = fi.id_floors_institution
                   AND fi.id_floors = f.id_floors
                   AND f.flg_available = pk_alert_constant.g_yes
                   AND fi.flg_available = pk_alert_constant.g_yes
                   AND fd.flg_available = pk_alert_constant.g_yes
                   AND r.flg_available = pk_alert_constant.g_yes)
          INTO l_floor_desc
          FROM dual;
    
        RETURN l_floor_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ROOM_FLOOR_DESC',
                                              l_error);
            RETURN NULL;
    END get_room_floor_desc;
    --

    /********************************************************************************************
    * Checks if all beds of a given room are available
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_id_room                Room ID
    *
    * @return                         'Y' if all beds of this room are available or 'N' otherwise
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/07/14
    **********************************************************************************************/
    FUNCTION has_all_beds_available
    (
        i_lang    IN language.id_language%TYPE,
        i_id_room IN institution.id_institution%TYPE
    ) RETURN VARCHAR IS
    
        l_func_name VARCHAR2(32) := 'HAS_ALL_BEDS_AVAILABLE';
        l_avail     VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_error     t_error_out;
    BEGIN
        g_error := 'HAS_ALL_BEDS_AVAILABLE: i_id_room =' || i_id_room;
        pk_alertlog.log_debug(g_error);
        --
    
        FOR c IN (SELECT b.id_bed id_bed, pk_bmng.is_bed_available(i_lang, b.id_bed) flg_cancel
                    FROM bed b
                   WHERE b.id_room = i_id_room)
        LOOP
            IF c.flg_cancel = pk_alert_constant.g_no
            THEN
                l_avail := pk_alert_constant.g_no;
                EXIT;
            END IF;
        END LOOP;
    
        RETURN l_avail;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_no;
        
    END has_all_beds_available;
    /********************************************************************************************
    * Get the list of specialities for a given bed 
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room                Room ID
    * @param i_id_bed                 Bed ID
    * @param o_error                  Error
    *
    * @return                         CLOB with specialities associated to a bed
    *
    * @author                          Rui Gomes
    * @version                         2.6.0.5
    * @since                           2011/03/18
    **********************************************************************************************/
    FUNCTION get_bed_room_dcs_match
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN VARCHAR2,
        i_id_bed  IN bed.id_bed%TYPE
    ) RETURN CLOB IS
        l_room_dcs  CLOB;
        l_bed_dcs   CLOB;
        l_msg_all   CLOB;
        l_bed_spec  CLOB;
        l_spec_list CLOB;
    
        o_error t_error_out;
    BEGIN
        g_error := 'get_beds_list: i_id_room =' || i_id_room;
        pk_alertlog.log_debug(g_error);
        SELECT pk_utils.query_to_string('SELECT column_value
                                         FROM TABLE(pk_backoffice_adm_surgery.get_room_dcs(' ||
                                        i_lang || ', profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                                        i_prof.software || ') , ' || i_id_room || '))',
                                        ',')
          INTO l_room_dcs
          FROM dual;
    
        g_error := 'get_beds_list: i_id_bed =' || i_id_bed;
        pk_alertlog.log_debug(g_error);
        SELECT nvl((SELECT pk_utils.query_to_string('SELECT column_value
                                                          FROM TABLE(pk_backoffice_adm_surgery.get_bed_dcs(' ||
                                                   i_lang || ', profissional(' || i_prof.id || ', ' ||
                                                   i_prof.institution || ', ' || i_prof.software || ') , ' || i_id_bed || '))',
                                                   ',')
                     FROM dual),
                   '')
          INTO l_bed_dcs
          FROM dual;
    
        g_error := 'get_beds_list: msg_all';
        pk_alertlog.log_debug(g_error);
        SELECT pk_message.get_message(i_lang, 'ADMINISTRATOR_T228')
          INTO l_msg_all
          FROM dual;
    
        g_error := 'get_beds_list_spec: i_id_bed =' || i_id_bed;
        pk_alertlog.log_debug(g_error);
        SELECT get_specialties_list_as_str(i_lang, i_prof, get_bed_specialties(i_lang, i_prof, i_id_bed), ',')
          INTO l_bed_spec
          FROM dual;
    
        IF (l_room_dcs = l_bed_dcs)
        THEN
            l_spec_list := l_msg_all;
        ELSE
            l_spec_list := l_bed_spec;
        END IF;
    
        RETURN l_spec_list;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_bed_room_dcs_match',
                                              o_error);
        
            RETURN NULL;
    END get_bed_room_dcs_match;
    --

    /********************************************************************************************
    * Get the list of specialties for a given bed history record
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_room_hist           Room history Id
    *
    * @return                         the list specialties ids
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1
    * @since                           14-Apr-2011
    **********************************************************************************************/
    FUNCTION get_room_hist_specialties
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_room_hist IN room_hist.id_room_hist%TYPE
    ) RETURN table_number IS
    
        --room_hist_specialties
        l_id_room_specialties table_number := table_number();
    
        --error
        l_error t_error_out;
    BEGIN
    
        g_error := 'get_bed_hist_specialties:';
        pk_alertlog.log_debug(g_error);
        --
    
        SELECT dcs.id_clinical_service
          BULK COLLECT
          INTO l_id_room_specialties
          FROM dep_clin_serv dcs
          JOIN room_dep_clin_serv_hist rdh
            ON rdh.id_dep_clin_serv = dcs.id_dep_clin_serv
         WHERE rdh.id_room_hist = i_id_room_hist;
    
        --
        RETURN l_id_room_specialties;
        --      
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ROOM_HIST_SPECIALTIES',
                                              l_error);
            RETURN NULL;
    END get_room_hist_specialties;

BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_backoffice_adm_surgery;
/
