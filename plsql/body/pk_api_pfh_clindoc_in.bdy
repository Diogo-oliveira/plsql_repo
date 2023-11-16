/*-- Last Change Revision: $Rev: 2026701 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_pfh_clindoc_in IS

    /********************************************************************************************
    * Get decription of given medication
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_PRESC                 id of prescribed drug
    *
    * @return                             string of drug prescribed or null if no_data_found, or error msg
    *
    * @author                             Luís Maia
    * @version                            2.6.0.1.2
    * @since                              28-JUL-2011
    *
    **********************************************************************************************/
    FUNCTION get_med_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN pk_rt_core_all.t_big_num
    ) RETURN VARCHAR2 IS
    
        l_return VARCHAR2(4000);
    
        l_out_strut t_error_out;
    
    BEGIN
    
        g_error := 'call pk_rt_med_pfh.get_med_desc with i_id_presc ' || i_id_presc;
        pk_alertlog.log_debug(g_error);
        RETURN pk_rt_med_pfh.get_med_desc(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
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
                                              'GET_MED_DESC',
                                              l_out_strut);
            RETURN l_return;
    END get_med_desc;

    /********************************************************************************************
    * Gets the episode medication list. Used to get the most recent records when registering
    * a new AMPLE/SAMPLE/CIAMPEDS assessment.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_type                   Return list of ID's or labels
    *
    * @value i_type                   {*} 'ID' Get list of ID's {*} 'LABEL' Get list of labels
    * @value i_separator              {*} ',' ID separator {*} ',, ' Label separator
    *                        
    * @return                         Medication text
    * 
    * @author                         Jos?Brito
    * @version                        2.6.1.2  
    * @since                          23-08-2011
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION get_abcde_medication_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_type       IN VARCHAR2
    ) RETURN table_varchar IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_ABCDE_MEDICATION_LIST';
        l_items table_varchar;
    
        l_list_id    CONSTANT VARCHAR2(24 CHAR) := 'ID';
        l_list_label CONSTANT VARCHAR2(24 CHAR) := 'LABEL';
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET ITEMS';
        pk_alertlog.log_debug(g_error);
        SELECT decode(i_type, l_list_id, to_char(res.id), l_list_label, res.label || '.')
          BULK COLLECT
          INTO l_items
          FROM TABLE(pk_rt_med_pfh.get_abcde_medication_list(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_id_episode => i_id_episode,
                                                             i_id_patient => i_id_patient)) res;
    
        RETURN l_items;
    
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
    END get_abcde_medication_list;

    /********************************************************************************************
    * Gets the ABCDE assessment medication text
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_record_id              Medication record ID
    * @param i_id_episode             Episode ID
    * @param i_flg_type               Type of prescription
    *                        
    * @return                         Medication text
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0.5
    * @since                          2011/01/15
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION get_abcde_medication_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_record_id  IN NUMBER,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_type   IN epis_abcde_meth_param.flg_type%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_ABCDE_MEDICATION_DESC';
        l_medication_desc VARCHAR2(4000 CHAR);
    
        l_flg_prescription       CONSTANT VARCHAR2(1 CHAR) := 'P';
        l_flg_prescription_other CONSTANT VARCHAR2(2 CHAR) := 'PO';
    
        l_error t_error_out;
    BEGIN
        IF i_flg_type = l_flg_prescription
        THEN
            -- Get the list of reported medication
            l_medication_desc := pk_rt_med_pfh.get_abcde_medication_reported(i_lang         => i_lang,
                                                                             i_prof         => i_prof,
                                                                             i_record_id    => i_record_id,
                                                                             i_id_episode   => i_id_episode,
                                                                             i_history_data => pk_alert_constant.g_no);
        ELSIF i_flg_type = l_flg_prescription_other
        THEN
            -- Get the records registered in the "Home medication" button
            l_medication_desc := pk_rt_med_pfh.get_abcde_medication_home(i_lang         => i_lang,
                                                                         i_prof         => i_prof,
                                                                         i_record_id    => i_record_id,
                                                                         i_id_episode   => i_id_episode,
                                                                         i_history_data => pk_alert_constant.g_no);
        END IF;
    
        RETURN l_medication_desc;
    
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
    END get_abcde_medication_desc;

    /********************************************************************************************
    * Checks if "No Home medication" or "Cannot name medication" was chosen
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_episode                Episode ID
    * @param i_record_id    Medication list ID
    * @param i_flg_type               Type of record: P - medication list, PO - medication det
    *                        
    * @return                         Medication text
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0
    * @since                          15-03-2010
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION get_abcde_medication_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_record_id IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        i_flg_type  IN epis_abcde_meth_param.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_ABCDE_MEDICATION_NAME';
    
        l_flg_type_p  CONSTANT epis_abcde_meth_param.flg_type%TYPE := 'P';
        l_flg_type_po CONSTANT epis_abcde_meth_param.flg_type%TYPE := 'PO';
        l_error t_error_out;
    
        l_desc_med VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF i_flg_type = l_flg_type_p
        THEN
            g_error := 'GET MEDICATION NAME (1)';
            pk_alertlog.log_debug(text => g_error);
            l_desc_med := pk_rt_med_pfh.get_abcde_medication_reported(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_record_id  => i_record_id,
                                                                      i_id_episode => i_episode);
        
        ELSIF i_flg_type = l_flg_type_po
        THEN
            g_error := 'GET MEDICATION NAME (2)';
            pk_alertlog.log_debug(text => g_error);
            l_desc_med := pk_rt_med_pfh.get_abcde_medication_home(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_record_id  => i_record_id,
                                                                  i_id_episode => i_episode);
        END IF;
    
        RETURN l_desc_med;
    
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
    END get_abcde_medication_name;

    /********************************************************************************************
    * Checks if "No Home medication" or "Cannot name medication" was chosen or if medication
    * is active
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_pat_medication_list    Reported medication ID
    * @param i_pat_medication_det     Medication det ID
    *                        
    * @return                         Medication text
    * 
    * @author                         Jos?Brito
    * @version                        2.6.0
    * @since                          15-03-2010
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION check_abcde_medication_flg
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat_medication_list IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        i_pat_medication_det  IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'CHECK_ABCDE_MEDICATION_FLG';
    
        l_flg_check VARCHAR2(1 CHAR);
        l_status    VARCHAR2(200 CHAR);
    
        l_count NUMBER(6);
    
        l_error t_error_out;
    BEGIN
    
        l_flg_check := pk_alert_constant.g_no;
    
        IF i_pat_medication_det IS NOT NULL
        THEN
            g_error := 'GET STATUS - REP. MEDICATION (1)';
            pk_alertlog.log_debug(g_error);
            l_status := pk_rt_med_pfh.get_abcde_medication_home(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_record_id  => i_pat_medication_det,
                                                                i_id_episode => NULL);
        
            IF l_status IS NOT NULL
            THEN
                -- Changes are only required if one of the parameters is 'Yes'.
                l_flg_check := pk_alert_constant.g_yes;
            END IF;
        
        ELSIF i_pat_medication_list IS NOT NULL
        THEN
            g_error := 'GET STATUS - REP. MEDICATION (2)';
            pk_alertlog.log_debug(g_error);
            l_count := pk_rt_med_pfh.check_abcde_medication_rep(i_lang      => i_lang,
                                                                i_prof      => i_prof,
                                                                i_record_id => i_pat_medication_list);
        
            -- Previously we checked if the task was cancelled. With the new medication logic, just check
            -- if the prescription record is not cancelled.
            IF nvl(l_count, 0) > 0
            THEN
                l_flg_check := pk_alert_constant.g_yes;
            END IF;
        
        END IF;
    
        RETURN l_flg_check;
    
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
    END check_abcde_medication_flg;

    /********************************************************************************************
    * Gets the episode medication ID list. 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_patient             Patient ID
    *                        
    * @return                         Medication IDs
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION get_abcde_medication_id_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN table_number IS
    BEGIN
        RETURN pk_rt_med_pfh.get_abcde_medication_id_list(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_patient => i_id_patient);
    END get_abcde_medication_id_list;

    /********************************************************************************************
    * Get medication list used in the abcde multichoice
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
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION get_abcde_medic_multichoice
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat_medication_list IN table_number,
        i_id_episode          IN episode.id_episode%TYPE,
        o_medication          OUT pk_types.cursor_type,
        o_options             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_ABCDE_MEDIC_MULTICHOICE';
        l_internal_error EXCEPTION;
    
        l_flg_search_yes CONSTANT VARCHAR2(1 CHAR) := 'Y';
        l_flg_search_no  CONSTANT VARCHAR2(1 CHAR) := 'N';
    
        l_flg_exclusive_no CONSTANT VARCHAR2(1 CHAR) := 'N';
    
        l_dummy_id CONSTANT NUMBER(6) := -999;
    
        l_pat_medication_list table_number;
    
    BEGIN
    
        IF NOT i_pat_medication_list.exists(1)
        THEN
            -- Set a dummy ID to avoid empty list error.
            l_pat_medication_list := table_number(l_dummy_id);
        END IF;
    
        g_error := 'OPEN O_MEDICATION';
        pk_alertlog.log_debug(text => g_error);
        OPEN o_medication FOR
            SELECT lp.data,
                   lp.label,
                   l_flg_search_no    flg_search,
                   l_flg_exclusive_no flg_exclusive,
                   -- Marks item as "reported medication"
                   pk_alert_constant.g_yes flg_medication,
                   -- Fields used in the warning message, when checking "No home medication"
                   lp.last_dose,
                   -- Convert new medication status to "old" status flag
                   lp.flg_status_converted,
                   lp.desc_status,
                   NULL                    img_type,
                   0                       rank
              FROM TABLE(pk_rt_med_pfh.get_abcde_medic_multichoice(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_pat_medication_list => l_pat_medication_list,
                                                                   i_id_episode          => i_id_episode)) lp
            UNION ALL
            SELECT -1 data,
                   pk_message.get_message(i_lang, 'ABCDE_T029') label,
                   l_flg_search_yes flg_search,
                   l_flg_exclusive_no flg_exclusive,
                   pk_alert_constant.g_no flg_medication,
                   NULL last_dose,
                   NULL flg_status,
                   NULL desc_status,
                   NULL img_type,
                   -1 rank
              FROM dual;
    
        g_error := 'CALL TO GET_EDITOR_LOOKUP';
        pk_alertlog.log_debug(text => g_error);
        IF NOT pk_rt_med_pfh.get_editor_lookup(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_id_editor_lookup => pk_rt_med_pfh.el_global_information,
                                               o_info             => o_options,
                                               o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_medication);
            pk_types.open_my_cursor(o_options);
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
    END get_abcde_medic_multichoice;

    /********************************************************************************************
    * Returns the ID's of the options available in the "Home Medication" screen
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param o_id_global_info          Option ID's
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          Jos?Brito
    * @version                         2.6
    * @since                           30-Sep-2011
    *
    **********************************************************************************************/
    FUNCTION get_abcde_editor_lookup
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_id_global_info OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_ABCDE_EDITOR_LOOKUP';
    
        l_internal_error EXCEPTION;
    
        l_dummy_2 table_varchar;
        l_dummy_3 table_varchar;
        l_dummy_4 table_varchar;
        l_dummy_5 table_number;
        l_dummy_6 table_varchar;
        l_dummy_7 table_number;
        l_dummy_8 table_varchar;
        l_dummy_9 table_varchar;
    
        l_info pk_types.cursor_type;
    BEGIN
    
        g_error := 'CALL TO GET_EDITOR_LOOKUP';
        pk_alertlog.log_debug(text => g_error);
        IF NOT pk_rt_med_pfh.get_editor_lookup(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_id_editor_lookup => pk_rt_med_pfh.el_global_information,
                                               o_info             => l_info,
                                               o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'FETCH OPTIONS CURSOR';
        pk_alertlog.log_debug(text => g_error);
        FETCH l_info BULK COLLECT
            INTO o_id_global_info,
                 l_dummy_2,
                 l_dummy_3,
                 l_dummy_4,
                 l_dummy_5,
                 l_dummy_6,
                 l_dummy_7,
                 l_dummy_8,
                 l_dummy_9;
        CLOSE l_info;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
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
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_abcde_editor_lookup;

    /********************************************************************************************
    * Get the medication data (reported medication and "home medication" options)
    * for the trauma detail screen.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_episode              Episode ID
    * @param i_id_epis_abcde_meth      ABCDE assessment ID
    * @param o_medication              Medication data
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          Jos?Brito
    * @version                         2.6
    * @since                           04-Oct-2011
    *
    **********************************************************************************************/
    FUNCTION get_trauma_hist_medic_by_id
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        o_medication         OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_TRAUMA_HIST_MEDIC_BY_ID';
    BEGIN
    
        g_error := 'GET MEDICATION';
        pk_alertlog.log_debug(g_error);
        OPEN o_medication FOR
            SELECT eam.id_epis_abcde_meth, -- Data for cancellation method
                   rm.id_presc id_task,
                   eamh.flg_type,
                   -- Data to display in the modal window
                   pk_api_pfh_clindoc_in.get_abcde_medication_name(i_lang,
                                                                   i_prof,
                                                                   i_id_episode,
                                                                   rm.id_presc,
                                                                   eamh.flg_type) rep_medication_name,
                   rm.dt_end dt_record
              FROM epis_abcde_meth eam
              JOIN epis_abcde_meth_param eamh
                ON eamh.id_epis_abcde_meth = eam.id_epis_abcde_meth
              JOIN TABLE(pk_rt_med_pfh.get_reported_medication(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode)) rm
                ON rm.id_presc = eamh.id_param
             WHERE eam.id_epis_abcde_meth = i_id_epis_abcde_meth
               AND eam.id_episode = i_id_episode
               AND eamh.flg_type = 'P' -- Reported Medication
               AND eamh.flg_status = 'A'
               AND rm.id_status NOT IN (pk_rt_med_pfh.st_cancelled)
            UNION ALL
            SELECT eam.id_epis_abcde_meth,
                   lr.id_review id_task,
                   eamh.flg_type,
                   pk_api_pfh_clindoc_in.get_abcde_medication_name(i_lang,
                                                                   i_prof,
                                                                   i_id_episode,
                                                                   lr.id_review,
                                                                   eamh.flg_type) rep_medication_name,
                   lr.dt_update dt_record
              FROM epis_abcde_meth eam
              JOIN epis_abcde_meth_param eamh
                ON eamh.id_epis_abcde_meth = eam.id_epis_abcde_meth
              JOIN TABLE(pk_rt_med_pfh.get_list_hm_review(i_lang => i_lang, i_prof => i_prof, i_id_patient => pk_episode.get_id_patient(i_episode => i_id_episode))) lr
                ON lr.id_review = eamh.id_param
             WHERE eam.id_epis_abcde_meth = i_id_epis_abcde_meth
               AND eam.id_episode = i_id_episode
               AND eamh.flg_type = 'PO' -- Reported Medication: "No Home medication"/"Cannot name medication"
               AND eamh.flg_status = 'A'
             ORDER BY dt_record;
    
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
    END get_trauma_hist_medic_by_id;

    /********************************************************************************************
    * Gets all drug prescriptions included in a given period or a specific date
    *
    * @param i_lang                  language ID       
    * @param i_prof                  professional, software and institution ids 
    * @param i_visit                 visit ID   
    * @param i_num_hours             number of hours that will be represented in the partogram graph
    * @param i_dt_birth              devilery start date 
    * @param i_flg_type              Output type: G - graph, T - table
    *        
    * @return o_drug_val             drug prescriptions    
    * @return                        true or false on success or error
    *
    * @author                        Jos?Brito
    * @version                       2.6.1.2  
    * @since                         23-08-2011
    * @dependents                    PK_DELIVERY
    ********************************************************************************************/
    FUNCTION get_delivery_drug_val
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_visit     IN visit.id_visit%TYPE,
        i_num_hours IN table_number,
        i_dt_birth  IN epis_doc_delivery.dt_delivery_tstz%TYPE,
        i_flg_type  IN VARCHAR2,
        o_drug_val  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  CONSTANT VARCHAR2(200 CHAR) := 'GET_DELIVERY_DRUG_VAL';
        l_flg_active CONSTANT VARCHAR2(1 CHAR) := 'A';
        l_flg_cancel CONSTANT VARCHAR2(1 CHAR) := 'C';
    BEGIN
        g_error := 'OPEN CURSOR O_DRUG_VAL';
        pk_alertlog.log_debug(text => g_error);
        OPEN o_drug_val FOR
            SELECT CASE
                        WHEN t.qty BETWEEN - g_one AND g_one THEN
                         decode(t.qty, g_zero, g_zero_chr, g_zero_chr || t.qty)
                        ELSE
                         to_char(t.qty)
                    END VALUE,
                   NULL icon,
                   t.id_presc_plan id_drug_presc_plan,
                   -- Check if record is cancelled
                   decode(t.flg_status_converted, l_flg_cancel, l_flg_cancel, l_flg_active) reg,
                   g_flg_date flg_reg,
                   decode(i_flg_type,
                          g_type_graph,
                          (pk_date_utils.diff_timestamp(nvl(t.dt_last_execution_task, t.dt_next_take),
                                                        pk_date_utils.add_to_ltstz(i_dt_birth,
                                                                                   pk_delivery.get_hour_delivery(i_lang,
                                                                                                                 i_prof,
                                                                                                                 i_num_hours,
                                                                                                                 i_dt_birth,
                                                                                                                 nvl(t.dt_last_execution_task,
                                                                                                                     t.dt_next_take)) - 1,
                                                                                   g_hour_mask)) * g_hours_in_a_day),
                          pk_date_utils.date_send_tsz(i_lang, nvl(t.dt_last_execution_task, t.dt_next_take), i_prof)) time_value,
                   t.dt_start_execution_task,
                   t.dt_end_execution_task,
                   t.flg_take_type,
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(t.dt_last_execution_task, t.dt_next_take),
                                               i_prof.institution,
                                               i_prof.software) dt_read,
                   pk_delivery.get_hour_delivery(i_lang,
                                                 i_prof,
                                                 i_num_hours,
                                                 i_dt_birth,
                                                 nvl(t.dt_last_execution_task, t.dt_next_take)) hour_vs,
                   t.id_drug,
                   nvl(t.dt_last_execution_task, t.dt_next_take) dt_reg
              FROM TABLE(pk_rt_med_pfh.get_delivery_drug_val(i_lang => i_lang, i_prof => i_prof, i_visit => i_visit)) t
             ORDER BY id_drug, hour_vs, dt_reg;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_drug_val);
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
    END get_delivery_drug_val;

    /********************************************************************************************
    * Gets all drugs prescribed during labor
    *
    * @param i_lang                  language ID
    * @param i_prof                  professional, software and institution ids
    * @param i_visit                 visit ID       
    * @param i_dt_birth              devilery start date     
    *        
    * @return o_drug                 drug prescriptions
    * @return                        true or false on success or error
    *
    * @author                        Jos?Brito
    * @version                       2.6.1.2  
    * @since                         23-08-2011  
    * @dependents                    PK_DELIVERY
    ********************************************************************************************/
    FUNCTION get_delivery_drug_param
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_dt_birth IN epis_doc_delivery.dt_delivery_tstz%TYPE,
        o_drug     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_DELIVERY_DRUG_PARAM';
    BEGIN
    
        g_error := 'CALL TO GET_DELIVERY_DRUG_PARAM';
        pk_alertlog.log_debug(text => g_error);
        RETURN pk_rt_med_pfh.get_delivery_drug_param(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_visit    => i_visit,
                                                     i_dt_birth => i_dt_birth,
                                                     o_drug     => o_drug,
                                                     o_error    => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_drug);
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
    END get_delivery_drug_param;

    /********************************************************************************************
    * Gets all drugs prescribed during labor and the associated prescription date
    *
    * @param i_lang                  language ID
    * @param i_prof                  professional, software and institution ids
    * @param i_visit                 visit ID       
    * @param i_dt_birth              delivery start date   
    *
    * @return o_time                 drug prescriptions   
    * @return                        true or false on success or error
    *
    * @author                        Jos?Brito
    * @version                       2.6.1.2  
    * @since                         23-08-2011
    * @dependents                    PK_DELIVERY
    ********************************************************************************************/
    FUNCTION get_delivery_drug_time
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_dt_birth IN epis_doc_delivery.dt_delivery_tstz%TYPE,
        o_time     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_DELIVERY_DRUG_TIME';
    BEGIN
        RETURN pk_rt_med_pfh.get_delivery_drug_time(i_lang     => i_lang,
                                                    i_prof     => i_prof,
                                                    i_visit    => i_visit,
                                                    i_dt_birth => i_dt_birth,
                                                    o_time     => o_time,
                                                    o_error    => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_time);
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
    END get_delivery_drug_time;

    /********************************************************************************************
    * Gets all drugs prescribed during labor
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution IDs
    * @param i_visit                 visit ID     
    * @param i_dt_birth              delivery start date     
    * 
    * @return o_drugs                all drug prescriptions during labor
    * @return                        true or false on success or error
    *
    * @author                        Jos?Brito
    * @version                       2.6.1.2  
    * @since                         23-08-2011
    * @dependents                    PK_DELIVERY
    ********************************************************************************************/
    FUNCTION get_delivery_drug_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_dt_birth IN epis_doc_delivery.dt_delivery_tstz%TYPE,
        o_drugs    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_DELIVERY_DRUG_PRESC';
        l_group_d   CONSTANT VARCHAR2(1 CHAR) := 'D';
        l_zero      CONSTANT NUMBER(6) := 0;
    BEGIN
    
        g_error := 'OPEN CURSOR O_DRUGS';
        pk_alertlog.log_debug(text => g_error);
        OPEN o_drugs FOR
            SELECT t.id_drug               id_vital_sign,
                   l_zero                  fetus_number,
                   t.id_product_desc       name_vs,
                   l_zero                  rank,
                   NULL                    val_min,
                   NULL                    val_max,
                   t.inn_color             color_grafh,
                   NULL                    color_text,
                   NULL                    desc_fetus_measure,
                   NULL                    desc_unit_measure,
                   NULL                    id_unit_measure,
                   pk_alert_constant.g_yes flg_default,
                   l_group_d               flg_group,
                   NULL                    id_vs_parent
              FROM TABLE(pk_rt_med_pfh.get_delivery_drug_presc(i_lang     => i_lang,
                                                               i_prof     => i_prof,
                                                               i_visit    => i_visit,
                                                               i_dt_birth => i_dt_birth)) t
            --GROUP BY t.id_drug, t.inn_color
             ORDER BY flg_group DESC, rank, id_vital_sign, fetus_number;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_drugs);
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
    END get_delivery_drug_presc;

    /********************************************************************************************
    * Gets the detail of an administered medication available in the partogram graph/table
    *
    * @param i_lang                  language ID       
    * @param i_prof                  professional, software and institution ids 
    * @param i_id_reg                administered medication ID 
    *        
    * @return o_val_det              drug detail    
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         06-05-2008
    * @dependents                    PK_WOMAN_HEALTH
    ********************************************************************************************/
    FUNCTION get_delivery_drug_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_reg  IN drug_presc_plan.id_drug_presc_plan%TYPE,
        o_val_det OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_DELIVERY_DRUG_DET';
    BEGIN
        g_error := 'OPEN CURSOR O_VAL_DET';
        pk_alertlog.log_debug(text => g_error);
        OPEN o_val_det FOR
            SELECT t.qty || ' ' ||
                   pk_translation.get_translation(i_lang, 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || t.id_unit) VALUE,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_next_take, i_prof) dt_reg,
                   pk_date_utils.date_char_tsz(i_lang, t.dt_next_take, i_prof.institution, i_prof.software) dt_reg_f,
                   t.id_product_desc desc_reg,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(t.id_prof_upd, t.id_prof_create)) prof_read,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    nvl(t.id_prof_upd, t.id_prof_create),
                                                    nvl(t.dt_upd, t.dt_create),
                                                    t.id_last_episode) desc_speciality,
                   t.id_status_desc flg_status
              FROM TABLE(pk_rt_med_pfh.get_delivery_drug_det(i_lang => i_lang, i_prof => i_prof, i_id_reg => i_id_reg)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_val_det);
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
    END get_delivery_drug_det;

    /********************************************************************************************
    * Gets the maximum time limit in the partogram graph (drug records)
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_episode                    episode ID
    * @param i_visit                      visit ID
    * @param i_dt_birth                   delivery begin date
    * @param o_dt_drug                    drug record dates
    * @param o_duration                   duration of continuous medication 
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              05-06-2009
    * @dependents                         PK_DELIVERY
    **********************************************************************************************/
    FUNCTION get_delivery_max_drug
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_visit    IN visit.id_visit%TYPE,
        i_dt_birth IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_dt_drug  OUT table_number,
        o_duration OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_DELIVERY_MAX_DRUG';
    BEGIN
        g_error := 'GET MAX DT_DRUG';
        pk_alertlog.log_debug(text => g_error);
        IF i_episode IS NOT NULL
        THEN
            SELECT ceil((trunc(SYSDATE) + (nvl(t.dt_last_execution_task, t.dt_next_take) - i_dt_birth) - trunc(SYSDATE)) *
                        g_hours_in_a_day) hour,
                   
                   MAX(nvl(pk_delivery.get_delivery_duration_hours(i_lang,
                                                                   i_prof,
                                                                   t.dt_start_execution_task,
                                                                   t.dt_end_execution_task,
                                                                   g_hours_in_a_day,
                                                                   t.flg_take_type),
                           g_zero)) duration
              BULK COLLECT
              INTO o_dt_drug, o_duration
              FROM TABLE(pk_rt_med_pfh.get_delivery_max_drug(i_lang => i_lang, i_prof => i_prof, i_visit => i_visit)) t
             WHERE nvl(t.dt_last_execution_task, t.dt_next_take) >= i_dt_birth
             GROUP BY ceil((trunc(SYSDATE) + (nvl(t.dt_last_execution_task, t.dt_next_take) - i_dt_birth) -
                           trunc(SYSDATE)) * g_hours_in_a_day)
             ORDER BY hour;
        
        ELSE
            o_duration := table_number();
            o_dt_drug  := table_number();
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
    END get_delivery_max_drug;

    /********************************************************************************************
    * Gets the drug time records to be placed in the partogram table
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution IDs     
    * @param i_visit                 visit ID     
    * @param i_dt_birth              delivery start date
    *
    * @return                        drug administration/prescription dates
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         01-09-2007
    * @dependents                    PK_DELIVERY
    ********************************************************************************************/
    FUNCTION get_delivery_drug_time_t
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_dt_birth IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN table_timestamp_tz IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_DELIVERY_DRUG_TIME_T';
        l_error     t_error_out;
        l_drug_time table_timestamp_tz;
    BEGIN
    
        g_error := 'GET MAX DT_DRUG';
        pk_alertlog.log_debug(text => g_error);
        SELECT nvl(t.dt_last_execution_task, t.dt_next_take) dt_plan
          BULK COLLECT
          INTO l_drug_time
          FROM TABLE(pk_rt_med_pfh.get_delivery_drug_time_t(i_lang => i_lang, i_prof => i_prof, i_visit => i_visit)) t
         WHERE t.dt_next_take >= i_dt_birth
         GROUP BY nvl(t.dt_last_execution_task, t.dt_next_take);
    
        RETURN l_drug_time;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_delivery_drug_time_t;

    /********************************************************************************************
    * Gets all prescriptions associated with the patient treatment
    *
    * @param i_lang                  language ID       
    * @param i_prof                  professional, software and institution ids 
    * @param i_episode               episode ID   
    *        
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       2.6.1.1    
    * @since                         24-05-2011
    * @dependents                    PK_HAND_OFF
    ********************************************************************************************/
    FUNCTION get_hand_off_treatment
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN tf_hand_off_treatment IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_HAND_OFF_TREATMENT';
        l_hand_off_treatment tf_hand_off_treatment;
        l_error              t_error_out;
    BEGIN
    
        g_error := 'OPEN CURSOR O_DRUG_VAL';
        pk_alertlog.log_debug(text => g_error);
        SELECT tr_hand_off_treatment(t.id_presc,
                                     t.id_product_desc || ' (' || t.id_status_desc || ') ',
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL)
          BULK COLLECT
          INTO l_hand_off_treatment
          FROM TABLE(pk_rt_med_pfh.get_hand_off_treatment(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode)) t;
    
        RETURN l_hand_off_treatment;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_hand_off_treatment;

    /**********************************************************************************************
    * Prescriptions list grouped by status
    *
    * @param i_lang                   the id language
    * @param i_epis                   episode id
    * @param i_prof                   professional, software and institution ids
    * @param o_title                  Status titles
    * @param o_drug                   Drugs list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/18  
    * @dependents                     PK_HAND_OFF
    **********************************************************************************************/
    FUNCTION get_hand_off_presc_status
    (
        i_lang  IN language.id_language%TYPE,
        i_epis  IN episode.id_episode%TYPE,
        i_prof  IN profissional,
        o_title OUT table_clob,
        o_drug  OUT table_clob,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32 CHAR) := 'GET_HAND_OFF_PRESC_STATUS';
        l_blank_space    CONSTANT VARCHAR2(1 CHAR) := ' ';
        l_separator      CONSTANT VARCHAR2(1 CHAR) := ':';
        l_separator_item CONSTANT VARCHAR2(2 CHAR) := '; ';
    
        l_medication_title sys_message.desc_message%TYPE;
    
        CURSOR c_drug(l_title sys_message.desc_message%TYPE) IS
            WITH list_presc AS
             (SELECT t.desc_status,
                     t.desc_drug,
                     t.flg_sos,
                     decode(t.flg_sos, pk_alert_constant.g_yes, g_zero, t.presc_rank) rank,
                     t.id_status
                FROM TABLE(pk_rt_med_pfh.get_hand_off_presc_status(i_lang => i_lang, i_epis => i_epis, i_prof => i_prof)) t
               ORDER BY rank)
            SELECT upper(l_title) || l_blank_space || t_status.desc_status || l_separator desc_status,
                   pk_utils.concat_table(CAST(MULTISET (SELECT DISTINCT t1.desc_drug
                                                 FROM list_presc t1
                                                WHERE t1.id_status = t_status.id_status) AS table_varchar),
                                         l_separator_item) desc_drug
              FROM (SELECT DISTINCT t.id_status, t.desc_status
                      FROM list_presc t) t_status;
    
    BEGIN
        l_medication_title := pk_message.get_message(i_lang, 'EDIS_GRID_T028');
    
        g_error := 'OPEN C_DRUG';
        pk_alertlog.log_debug(text => g_error);
        OPEN c_drug(l_medication_title);
        FETCH c_drug BULK COLLECT
            INTO o_title, o_drug;
        CLOSE c_drug;
    
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
            o_title := table_clob();
            o_drug  := table_clob();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_hand_off_presc_status;

    /********************************************************************************************
    * Gets the description of a prescribed medication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_drug_presc_det            Drug prescription detail ID
    *
    * @return  Drug information (episode and description)
    *
    * @author       Jos?Silva
    * @version      v2.6.1.1
    * @since        06-06-2011
    * @dependents   PK_SUSPENDED_TASKS
    ********************************************************************************************/
    FUNCTION get_drug_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_drug_presc_det IN episode.id_episode%TYPE
    ) RETURN tf_hand_off_treatment IS
        l_func_name VARCHAR2(30) := 'GET_DRUG_DESC';
    
        l_error t_error_out;
        l_ret   tf_hand_off_treatment;
    
    BEGIN
    
        g_error := 'GET TF_HAND_OFF_TREATMENT';
        pk_alertlog.log_debug(text => g_error);
        SELECT /*+ cardinality( p 20 ) */
         tr_hand_off_treatment(presc.id_drug_presc_det,
                               presc.desc_treat_manag,
                               NULL,
                               NULL,
                               presc.id_episode,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               presc.last_dt,
                               NULL)
          BULK COLLECT
          INTO l_ret
          FROM TABLE(pk_rt_med_pfh.get_drug_desc(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_drug_presc_det => i_drug_presc_det)) presc;
    
        RETURN l_ret;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_drug_desc;

    /********************************************************************************************
    * Checks if an episode has prescriptions (used in the informative grid)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode ID
    *
    * @return  number of episode prescriptions
    *
    * @author       Jos?Silva
    * @version      v2.6.1.1
    * @since        06-06-2011
    * @dependents   PK_INFORMATION
    ********************************************************************************************/
    FUNCTION check_inf_prescription
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(30) := 'CHECK_INF_PRESCRIPTION';
    
        l_error t_error_out;
        l_ret   NUMBER;
    
    BEGIN
    
        g_error := 'CALL PK_RT_MED_PFH.CHECK_INF_PRESCRIPTION';
        pk_alertlog.log_debug(text => g_error);
        l_ret := pk_rt_med_pfh.check_inf_prescription(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_id_visit => pk_episode.get_id_visit(i_episode => i_episode));
    
        RETURN l_ret;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN 0;
    END check_inf_prescription;

    /********************************************************************************************
    * Gets the list of medication for a given episode or patient (only the ones administered)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_visit                     Visit id
    * @param   i_episode                   Episode id
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       Jos?Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_epis_medication
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_visit   IN visit.id_visit%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_med     OUT pk_api_complications.api_comp_cur,
        --o_med     OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPL_EPIS_MEDICATION';
    BEGIN
        g_error := 'OPEN O_MED';
        pk_alertlog.log_debug(text => g_error);
        OPEN o_med FOR
        -- Receitas para o exterior e outros medicamentos, manipulados e dietéticos
            SELECT /*+ cardinality( lr 20 ) */
             lr.id_presc id_task,
             lr.desc_task,
             lr.id_last_episode id_episode,
             pk_complication_core.get_axe_typ_at_med(i_lang, i_prof) flg_type,
             pk_complication_core.get_ecd_typ_med_ext(i_lang, i_prof) flg_context,
             lr.dt_task,
             lr.dt_task_send,
             lr.id_prof_writes id_prof_task,
             lr.name_prof_task,
             lr.id_prof_writes id_prof_req,
             lr.name_prof_req
              FROM TABLE(pk_rt_med_pfh.get_comp_lst_receipt(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_patient => i_patient,
                                                            i_visit   => nvl(i_visit,
                                                                             pk_episode.get_id_visit(i_episode => i_episode)))) lr
            UNION ALL
            -- Administrar neste local, outros medicamentos (texto livre) e compound
            SELECT /*+ cardinality( lpf 20 ) */
             lpf.id_presc id_task,
             lpf.filt_desc_task desc_task,
             lpf.id_last_episode id_episode,
             pk_complication_core.get_axe_typ_at_med(i_lang, i_prof) flg_type,
             pk_complication_core.get_ecd_typ_med_lcl(i_lang, i_prof) flg_context,
             lpf.dt_task,
             lpf.dt_task_send,
             lpf.id_prof_create id_prof_task,
             lpf.name_prof_task,
             lpf.id_prof_create id_prof_req,
             lpf.name_prof_req
              FROM TABLE(pk_rt_med_pfh.get_comp_lst_presc_filt(i_lang    => i_lang,
                                                               i_prof    => i_prof,
                                                               i_patient => i_patient,
                                                               i_visit   => nvl(i_visit,
                                                                                pk_episode.get_id_visit(i_episode => i_episode)))) lpf
             ORDER BY desc_task;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_med);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_compl_epis_medication;

    /********************************************************************************************
    * Gets a specific outside medication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   i_prescription_pharm        Outside medication ID
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       Jos?Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_out_medication
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_prescription_pharm IN prescription_pharm.id_prescription_pharm%TYPE,
        o_med                OUT pk_api_complications.api_comp_cur,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPL_OUT_MEDICATION';
    BEGIN
    
        g_error := 'OPEN o_med';
        pk_alertlog.log_debug(text => g_error);
        -- Outside medication
        OPEN o_med FOR
            WITH list_prescription AS
             (SELECT /*+ cardinality( p 20 ) */
               p.*
                FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang     => i_lang,
                                                                     i_prof     => i_prof,
                                                                     i_id_presc => i_prescription_pharm)) p),
            list_receipt AS
             (SELECT /*+ cardinality( t 2 ) */
               t.*
                FROM list_prescription p
                JOIN TABLE(pk_rt_med_pfh.get_list_receipt(i_lang => i_lang, i_prof => i_prof, i_id_patient => pk_episode.get_id_patient(i_episode => i_episode), i_id_presc => p.id_presc)) t
                  ON t.id_presc = p.id_presc)
            SELECT lr.id_presc id_task,
                   pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, lp.id_presc) || ' ' ||
                   pk_rt_med_pfh.get_presc_dir_str(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_id_presc     => lp.id_presc,
                                                   i_flg_html     => pk_alert_constant.g_no,
                                                   i_flg_complete => pk_alert_constant.g_no) desc_task,
                   lp.id_last_episode id_episode,
                   pk_complication_core.get_axe_typ_at_med(i_lang, i_prof) flg_type,
                   pk_complication_core.get_ecd_typ_med_ext(i_lang, i_prof) flg_context,
                   pk_date_utils.date_char_tsz(i_lang, lr.dt_writes, i_prof.institution, i_prof.software) dt_task,
                   pk_date_utils.date_send_tsz(i_lang, lr.dt_writes, i_prof) dt_task_send,
                   lr.id_prof_writes id_prof_task,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lr.id_prof_writes) name_prof_task,
                   lr.id_prof_writes id_prof_req,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lr.id_prof_writes) name_prof_req
              FROM list_prescription lp
              JOIN list_receipt lr
                ON lr.id_presc = lp.id_presc;
    
        --SELECT pp.id_prescription_pharm id_task,
        --       pk_medication_core.get_drug_desc(i_lang,
        --                                        i_prof,
        --                                        i_episode,
        --                                        pp.id_prescription_pharm,
        --                                        decode(p.flg_sub_type,
        --                                               pk_medication_current.g_flg_manip_ext,
        --                                               pk_medication_current.g_manipulados,
        --                                               pk_medication_current.g_flg_dietary_ext,
        --                                               pk_medication_current.g_dietetico,
        --                                               pk_medication_current.g_exterior),
        --                                        pk_alert_constant.g_no,
        --                                        pk_alert_constant.g_no) desc_task,
        --       p.id_episode,
        --       pk_complication_core.get_axe_typ_at_med(i_lang, i_prof) flg_type,
        --       pk_complication_core.get_ecd_typ_med_ext(i_lang, i_prof) flg_context,
        --       pk_date_utils.date_char_tsz(i_lang, p.dt_prescription_tstz, i_prof.institution, i_prof.software) dt_task,
        --       pk_date_utils.date_send_tsz(i_lang, p.dt_prescription_tstz, i_prof) dt_task_send,
        --      p.id_professional id_prof_task,
        --       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof_task,
        --       p.id_professional id_prof_req,
        --       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof_req
        -- FROM prescription p
        -- JOIN prescription_pharm pp
        --   ON (pp.id_prescription = p.id_prescription)
        --WHERE pp.id_prescription_pharm = i_prescription_pharm;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_med);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_compl_out_medication;

    /********************************************************************************************
    * Gets a specific prescribed medication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   i_drug_presc_det            Drug prescription ID
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       Jos?Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_drug_presc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_drug_presc_det IN drug_presc_det.id_drug_presc_det%TYPE,
        o_med            OUT pk_api_complications.api_comp_cur,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPL_DRUG_PRESC';
    BEGIN
    
        g_error := 'OPEN o_med';
        pk_alertlog.log_debug(text => g_error);
        -- Medication in this facility
        OPEN o_med FOR
            WITH list_prescription AS
             (SELECT /*+ cardinality( p 20 ) */
               p.*
                FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang        => i_lang,
                                                                     i_prof        => i_prof,
                                                                     i_id_workflow => table_number_id(pk_rt_med_pfh.wf_institution),
                                                                     i_id_presc    => i_drug_presc_det)) p)
            SELECT lp.id_presc id_task,
                   pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, lp.id_presc) || ' ' ||
                   pk_rt_med_pfh.get_presc_dir_str(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_id_presc     => lp.id_presc,
                                                   i_flg_html     => pk_alert_constant.g_no,
                                                   i_flg_complete => pk_alert_constant.g_no) desc_task,
                   lp.id_last_episode id_episode,
                   pk_complication_core.get_axe_typ_at_med(i_lang, i_prof) flg_type,
                   pk_complication_core.get_ecd_typ_med_lcl(i_lang, i_prof) flg_context,
                   pk_date_utils.date_char_tsz(i_lang, lp.dt_create, i_prof.institution, i_prof.software) dt_task,
                   pk_date_utils.date_send_tsz(i_lang, lp.dt_create, i_prof) dt_task_send,
                   lp.id_prof_create id_prof_task,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lp.id_prof_create) name_prof_task,
                   lp.id_prof_create id_prof_req,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lp.id_prof_create) name_prof_req
              FROM list_prescription lp;
    
        --SELECT dpd.id_drug_presc_det id_task,
        --     pk_medication_core.get_drug_desc(i_lang,
        --                                      i_prof,
        --                                      i_episode,
        --                                      dpd.id_drug_presc_det,
        --                                      decode(mi.flg_type,
        --                                             NULL,
        --                                             pk_medication_core.g_local,
        --                                             pk_medication_current.g_drug,
        --                                             pk_medication_current.g_local,
        --                                             pk_medication_current.g_soro),
        --                                      pk_alert_constant.g_no,
        --                                      pk_alert_constant.g_no) desc_task,
        --     dp.id_episode,
        --     pk_complication_core.get_axe_typ_at_med(i_lang, i_prof) flg_type,
        --     pk_complication_core.get_ecd_typ_med_lcl(i_lang, i_prof) flg_context,
        --     pk_date_utils.date_char_tsz(i_lang,
        --                                dp.dt_drug_prescription_tstz,
        --                                 i_prof.institution,
        --                                 i_prof.software) dt_task,
        --     pk_date_utils.date_send_tsz(i_lang, dp.dt_drug_prescription_tstz, i_prof) dt_task_send,
        --     nvl(dpd.id_prof_order, dp.id_professional) id_prof_task,
        --     pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(dpd.id_prof_order, dp.id_professional)) name_prof_task,
        --     dp.id_professional id_prof_req,
        --     pk_prof_utils.get_name_signature(i_lang, i_prof, dp.id_professional) name_prof_req
        --FROM drug_prescription dp
        --JOIN drug_presc_det dpd
        --  ON (dpd.id_drug_prescription = dp.id_drug_prescription)
        --LEFT JOIN mi_med mi
        --  ON (dpd.id_drug = mi.id_drug AND dpd.vers = mi.vers AND mi.vers = l_prescription_version)
        --WHERE dpd.id_drug_presc_det = i_drug_presc_det;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_med);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_compl_drug_presc;

    /********************************************************************************************
    * Gets a specific drug classification
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_pharm_group               Pharm group ID
    * @param   i_episode                   Episode ID
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       Jos?Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_pharm_group
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pharm_group IN mi_med_pharm_group.group_id%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_med         OUT pk_api_complications.api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_COMPL_PHARM_GROUP';
    BEGIN
        g_error := 'OPEN O_MED';
        pk_alertlog.log_debug(text => g_error);
        -- drug classification
        OPEN o_med FOR
            WITH list_prescription AS
             (SELECT /*+ cardinality( p 20 ) */
               p.*
                FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang     => i_lang,
                                                                     i_prof     => i_prof,
                                                                     i_id_visit => pk_episode.get_id_visit(i_episode => i_episode))) p
               WHERE p.id_status NOT IN (pk_rt_med_pfh.g_wf_presc_cancelled)),
            list_product AS
             (SELECT /*+ cardinality( t 2 ) */
               t.*
                FROM list_prescription p
                JOIN TABLE(pk_rt_med_pfh.get_list_product(i_lang => i_lang, i_prof => i_prof, i_id_presc => p.id_presc)) t
                  ON t.id_presc = p.id_presc
               WHERE t.g_id_pharm_therap_class_group = table_varchar(i_pharm_group))
            SELECT NULL id_task, --TODO: lpp.g_id_pharm_therap_class_group id_task,
                   NULL desc_task, --TODO: lpp.g_id_pharm_therap_class_desc  desc_task,
                   --unused parameters
                   NULL id_episode,
                   NULL flg_type,
                   NULL flg_context,
                   NULL dt_task,
                   NULL dt_task_send,
                   NULL id_prof_task,
                   NULL name_prof_task,
                   NULL id_prof_req,
                   NULL name_prof_req
              FROM list_product lpp;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_med);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_compl_pharm_group;

    /********************************************************************************************
    * Gets a specific drug (ID and description)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_drug                      Drug ID
    * @param   i_episode                   Episode ID
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       Jos?Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_drug
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_drug    IN mi_med.id_drug%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_med     OUT pk_api_complications.api_comp_cur,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPL_DRUG';
    BEGIN
        g_error := 'OPEN O_MED';
        pk_alertlog.log_debug(text => g_error);
        -- drug information
        OPEN o_med FOR
            WITH list_prescription AS
             (SELECT /*+ cardinality( p 20 ) */
               p.*
                FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang     => i_lang,
                                                                     i_prof     => i_prof,
                                                                     i_id_visit => pk_episode.get_id_visit(i_episode => i_episode))) p
               WHERE p.id_status NOT IN (pk_rt_med_pfh.g_wf_presc_cancelled)),
            list_product AS
             (SELECT /*+ cardinality( t 2 ) */
               t.*
                FROM list_prescription p
                JOIN TABLE(pk_rt_med_pfh.get_list_product(i_lang => i_lang, i_prof => i_prof, i_id_presc => p.id_presc)) t
                  ON t.id_presc = p.id_presc
               WHERE t.g_id_pharm_therap_class_group = table_varchar(i_drug))
            SELECT NULL id_task, --TODO: lpr.g_id_pharm_therap_class_group id_task,
                   NULL desc_drug, --TODO: lpr.id_product_desc             desc_drug,
                   -- unused parameters
                   NULL id_episode,
                   NULL flg_type,
                   NULL flg_context,
                   NULL dt_task,
                   NULL dt_task_send,
                   NULL id_prof_task,
                   NULL name_prof_task,
                   NULL id_prof_req,
                   NULL name_prof_req
              FROM list_product lpr;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_med);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_compl_drug;

    /********************************************************************************************
    * Gets a specific outside drug classification
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_pharm_group               Pharm group ID
    * @param   i_episode                   Episode ID
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       Jos?Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_out_med_group
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pharm_group IN me_pharm_group.group_id%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_med         OUT pk_api_complications.api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPL_OUT_MED_GROUP';
    BEGIN
    
        RETURN get_compl_drug(i_lang    => i_lang,
                              i_prof    => i_prof,
                              i_drug    => i_pharm_group,
                              i_episode => i_episode,
                              o_med     => o_med,
                              o_error   => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_med);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_compl_out_med_group;

    /********************************************************************************************
    * Gets a specific outside drug (ID and description)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_emb_id                    Drug ID
    * @param   i_episode                   Episode ID
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       Jos?Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_out_drug
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_emb_id  IN me_med.emb_id%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_med     OUT pk_api_complications.api_comp_cur,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPL_OUT_DRUG';
    BEGIN
    
        g_error := 'OPEN o_med';
        -- outside medication
        OPEN o_med FOR
            WITH list_prescription AS
             (SELECT /*+ cardinality( p 20 ) */
               p.*
                FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang     => i_lang,
                                                                     i_prof     => i_prof,
                                                                     i_id_visit => pk_episode.get_id_visit(i_episode => i_episode))) p
               WHERE p.id_status NOT IN (pk_rt_med_pfh.g_wf_presc_cancelled)),
            list_product AS
             (SELECT /*+ cardinality( t 2 ) */
               t.*
                FROM list_prescription p
                JOIN TABLE(pk_rt_med_pfh.get_list_product(i_lang => i_lang, i_prof => i_prof, i_id_presc => p.id_presc)) t
                  ON t.id_presc = p.id_presc
               WHERE t.id_drug = i_emb_id)
            SELECT lpp.id_drug         id_task,
                   lpp.id_product_desc desc_task,
                   --unused parameters
                   NULL id_episode,
                   NULL flg_type,
                   NULL flg_context,
                   NULL dt_task,
                   NULL dt_task_send,
                   NULL id_prof_task,
                   NULL name_prof_task,
                   NULL id_prof_req,
                   NULL name_prof_req
              FROM list_product lpp;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_med);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_compl_out_drug;

    /********************************************************************************************
    * Gets the drug information related to co-sign, to be placed in the todo list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode ID
    * @param   i_drug_presc_det            Drug prescription ID
    * @param   i_flg_type                  Type of information: (D)escription or (T)ime
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       Jos?Brito
    * @version      2.4.3
    * @since        2008-Sep-03
    * @dependents   PK_TODO_LIST
    ********************************************************************************************/
    FUNCTION get_todo_drug_cosign
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_drug_presc_det IN drug_presc_det.id_drug_presc_det%TYPE,
        i_flg_type       IN VARCHAR2
    ) RETURN tf_med_tasks IS
        l_func_name VARCHAR2(32 CHAR) := 'GET_TODO_DRUG_COSIGN';
        l_error     t_error_out;
    
        l_med_ret tf_med_tasks;
    BEGIN
    
        g_error := 'OPEN c_drug';
        pk_alertlog.log_debug(text => g_error);
        SELECT tr_med_tasks(id_drug, desc_status, last_date, dt_begin, desc_drug)
          BULK COLLECT
          INTO l_med_ret
          FROM (SELECT t.id_drug,
                       NULL desc_status,
                       NULL last_date,
                       decode(i_flg_type, pk_todo_list.g_co_sign_drug_desc, NULL, t.dt_begin) dt_begin,
                       decode(i_flg_type, pk_todo_list.g_co_sign_drug_desc, t.label, NULL) desc_drug
                  FROM TABLE(pk_rt_med_pfh.get_todo_drug_cosign(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_episode        => i_episode,
                                                                i_drug_presc_det => i_drug_presc_det)) t);
    
        RETURN l_med_ret;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_todo_drug_cosign;

    /**********************************************************************************************
    * Returns episode's drug prescriptions information like it will be shown on Tracking View.
    *
    * @param i_lang                        language's id
    * @param i_prof                        professional's related data (ID, Institution and Software)
    * @param i_episode                     episode's id from which the data will be gathered
    * @param i_sysdate                     current system date
    * @param i_external_tr                 external tracking view (Y) Yes (N) No
    *
    * @return           drug information to be used in the grid
    *
    * @author           João Eiras
    * @version          2.4.4
    * @dependents       PK_TRACKING_VIEW
    *
    * -- ATTENTION: new medication statuses need to be included as parameters here
    **********************************************************************************************/
    FUNCTION get_tracking_view_drug
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_sysdate     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_external_tr IN VARCHAR2
    ) RETURN pk_edis_types.table_line IS
    
        l_lines pk_edis_types.table_line;
    
        -- Types of takes:
        l_presc_take_sos CONSTANT VARCHAR2(1 CHAR) := 'S'; -- SOS
    
        l_sos_rank CONSTANT NUMBER(6) := 1;
    
    BEGIN
    
        g_error := 'GET TRACKING VIEW (DRUG)';
        pk_alertlog.log_debug(text => g_error);
        BEGIN
            SELECT MIN(t.dt_status) dt_status, t.flg_text, t.content, t.color, MIN(t.rank) rank
              BULK COLLECT
              INTO l_lines
              FROM (SELECT -- DATE ------------------------------------------------------------------------
                     CASE
                          WHEN res.id_status IN (pk_rt_med_pfh.st_suspended,
                                                 pk_rt_med_pfh.st_suspended_ongoing,
                                                 pk_rt_med_pfh.st_suspended_pharm_req,
                                                 pk_rt_med_pfh.st_suspended_ongoing_pharm_req) THEN
                           NULL
                          ELSE
                           coalesce(res.dt_last_execution_task, res.dt_plan, res.dt_begin, res.dt_create)
                      END dt_status,
                     -- TEXT ---------------------------------------------------------------------                    
                     CASE
                          WHEN res.flg_take_type = l_presc_take_sos THEN
                           pk_alert_constant.g_display_type_icon
                          WHEN res.id_status IN (pk_rt_med_pfh.st_suspended,
                                                 pk_rt_med_pfh.st_suspended_ongoing,
                                                 pk_rt_med_pfh.st_suspended_pharm_req,
                                                 pk_rt_med_pfh.st_suspended_ongoing_pharm_req) THEN
                           pk_alert_constant.g_display_type_icon
                          ELSE
                           pk_alert_constant.g_display_type_date_icon
                      END flg_text,
                     -- ICON ---------------------------------------------------------------------           
                     res.id_status_icon_tracking_view content,
                     -- COLOR ---------------------------------------------------------------------
                     CASE
                          WHEN res.flg_take_type = l_presc_take_sos THEN
                           pk_alert_constant.g_color_none
                          WHEN res.id_status IN (pk_rt_med_pfh.st_suspended,
                                                 pk_rt_med_pfh.st_suspended_ongoing,
                                                 pk_rt_med_pfh.st_suspended_pharm_req,
                                                 pk_rt_med_pfh.st_suspended_ongoing_pharm_req) THEN
                           pk_alert_constant.g_color_none
                          WHEN i_sysdate =
                               least(coalesce(res.dt_last_execution_task, res.dt_plan, res.dt_begin, res.dt_create),
                                     i_sysdate) THEN
                           pk_alert_constant.g_color_green
                      
                          ELSE
                           pk_alert_constant.g_color_red
                      END color,
                     
                     -- RANK ---------------------------------------------------------------------
                     decode(res.flg_take_type, pk_alert_constant.g_presc_take_sos, l_sos_rank, res.presc_rank) rank
                      FROM TABLE(pk_rt_med_pfh.get_tracking_view_drug(i_lang        => i_lang,
                                                                      i_prof        => i_prof,
                                                                      i_episode     => i_episode,
                                                                      i_external_tr => i_external_tr)) res) t
             GROUP BY flg_text, content, color
             ORDER BY rank ASC;
        EXCEPTION
            WHEN no_data_found THEN
                l_lines := NULL;
        END;
    
        RETURN l_lines;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN NULL;
    END get_tracking_view_drug;

    /********************************************************************************************
    * Gets the drug prescription information to be placed in the todo list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_epis                   Episode ID
    * @param   i_flg_type                  Type of todo: (P)ending or (D)epending tasks
    * @param   i_flg_count                 Task counter: Yes or No
    * @param   i_visit_desc                Visit description to be used in the grid
    * @param   i_dt_server                 Serialized server date to be used in the grid
    * @param   o_task_count                Task counter
    * @param   o_tasks                     Task list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       Jos?Brito
    * @version      2.4.3
    * @since        2008-Sep-03
    * @dependents   PK_TODO_LIST
    ********************************************************************************************/
    FUNCTION get_todo_drug_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis    IN episode.id_episode%TYPE,
        i_flg_type   IN todo_task.flg_type%TYPE,
        i_flg_count  IN VARCHAR2,
        i_visit_desc IN VARCHAR2,
        i_dt_server  IN VARCHAR2,
        o_task_count OUT NUMBER,
        o_tasks      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_TODO_DRUG_PRESC';
    
    BEGIN
        -- Verifica as tarefas requisitadas/em execução
        IF i_flg_type = pk_todo_list.g_pending
        THEN
            IF i_flg_count = pk_alert_constant.g_yes
            THEN
                g_error := 'CHECK PENDING COUNT';
                SELECT COUNT(*)
                  INTO o_task_count
                  FROM TABLE(pk_rt_med_pfh.get_todo_drug_presc(i_lang    => i_lang,
                                                               i_prof    => i_prof,
                                                               i_id_epis => i_id_epis)) lp;
            
            ELSE
                g_error := 'OPEN PENDING TASKS';
                OPEN o_tasks FOR
                    SELECT lp.label task_desc,
                           pk_date_utils.date_chr_extend_tsz(i_lang, lp.dt_begin, i_prof) task_date,
                           i_visit_desc visit_desc,
                           '|' || pk_date_utils.date_send_tsz(i_lang, lp.dt_begin, i_prof) || '|I|X|WaitingIcon' event_time,
                           i_dt_server dt_server
                      FROM TABLE(pk_rt_med_pfh.get_todo_drug_presc(i_lang    => i_lang,
                                                                   i_prof    => i_prof,
                                                                   i_id_epis => i_id_epis)) lp;
            
            END IF;
        
            -- Verifica a medicação em transporte
        ELSIF i_flg_type = pk_todo_list.g_depending
        THEN
            IF i_flg_count = pk_alert_constant.g_yes
            THEN
                g_error := 'CHECK DEPENDING COUNT';
                SELECT 0
                  INTO o_task_count
                  FROM dual;
            
            ELSE
                g_error := 'OPEN DEPENDING TASKS';
                OPEN o_tasks FOR
                    SELECT NULL task_desc, NULL task_date, NULL visit_desc, NULL event_time, NULL dt_server
                      FROM dual;
            
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_tasks);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_todo_drug_presc;

    /**********************************************************************************************
    * Checks if there is any medication tasks to be performed by the Respiratory Therapist
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    *
    * @return                         Medication list
    *                        
    * @author                         Jos?Silva
    * @version                        2.6.1.1 
    * @since                          2011/05/29
    * @dependents                     PK_RT_TECH
    **********************************************************************************************/
    FUNCTION get_rt_epis_drug_count
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN tf_med_tasks IS
        l_func_name VARCHAR2(32 CHAR) := 'GET_RT_EPIS_DRUG_COUNT';
        l_error     t_error_out;
    
        l_med_ret tf_med_tasks;
    
        CURSOR c_drug IS
            WITH list_rt_epis_presc AS
             (SELECT /*+ cardinality( t 2 ) */
               t.*
                FROM TABLE(pk_rt_med_pfh.get_rt_epis_presc(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_id_visit => pk_episode.get_id_visit(i_episode => i_episode))) t)
            -- Get data
            SELECT tr_med_tasks(tbl.id_drug, NULL, NULL, NULL, NULL)
              FROM list_rt_epis_presc tbl;
    BEGIN
    
        g_error := 'OPEN c_drug';
        OPEN c_drug;
        FETCH c_drug BULK COLLECT
            INTO l_med_ret;
        CLOSE c_drug;
    
        RETURN l_med_ret;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_rt_epis_drug_count;

    /**********************************************************************************************
    * Gets the delayed medication to be performed by the Respiratory Therapist
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    *
    * @return                         medication list. Format: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    *
    * UPDATED: ALERT-19390
    * @author                         Telmo Castro
    * @date                           09-03-2009
    * @version                        2.5
    * @dependents                     PK_RT_TECH
    **********************************************************************************************/
    FUNCTION get_rt_epis_drug_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN tf_med_tasks IS
        l_func_name VARCHAR2(32) := 'GET_RT_EPIS_DRUG_DESC';
        l_error     t_error_out;
    
        l_med_ret tf_med_tasks;
    
        CURSOR c_drug IS
            WITH list_rt_epis_presc AS
             (SELECT /*+ cardinality( t 2 ) */
               t.*
                FROM TABLE(pk_rt_med_pfh.get_rt_epis_presc(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_id_visit => pk_episode.get_id_visit(i_episode => i_episode))) t)
            -- Get data
            SELECT tr_med_tasks(tbl.id_drug, tbl.desc_status, NULL, NULL, NULL)
              FROM list_rt_epis_presc tbl;
    
    BEGIN
    
        g_error := 'OPEN c_drug';
        OPEN c_drug;
        FETCH c_drug BULK COLLECT
            INTO l_med_ret;
        CLOSE c_drug;
    
        RETURN l_med_ret;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_rt_epis_drug_desc;

    /********************************************************************************************
    * Gets all prescriptions
    *
    * @param i_lang                  language ID       
    * @param i_prof                  professional, software and institution ids 
    * @param i_id_episode            episode ID
    *        
    * @return                        true or false on success or error
    *
    * @author                        Filipe Silva
    * @version                       2.6.1.2    
    * @since                         23-Aug-2011
    * @dependents                    PK_EDIS_SUMMARY; PK_PROTOCOLS
    ********************************************************************************************/
    FUNCTION get_presc_treatment
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN tf_medication_pfh IS
    
        l_func_name      VARCHAR2(30 CHAR) := 'GET_PRESC_TREATMENT';
        l_medication_pfh tf_medication_pfh;
        l_error          t_error_out;
    
    BEGIN
    
        SELECT /*+ cardinality( p 20 ) */
         t_medication_pfh(pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, p.id_presc),
                          NULL, --NULL id_protocols,-- TODO: p.id_protocols,
                          p.id_status,
                          p.id_last_episode,
                          pk_episode.get_id_visit(i_episode => p.id_last_episode),
                          p.id_workflow,
                          (SELECT CAST(COLLECT(id_drug) AS table_varchar)
                             FROM TABLE(pk_rt_med_pfh.get_list_product(i_lang     => i_lang,
                                                                       i_prof     => i_prof,
                                                                       i_id_presc => p.id_presc)) t))
          BULK COLLECT
          INTO l_medication_pfh
          FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_id_workflow  => table_number_id(pk_rt_med_pfh.wf_institution,
                                                                                                 pk_rt_med_pfh.wf_iv),
                                                               i_history_data => pk_alert_constant.g_no,
                                                               i_id_visit     => pk_episode.get_id_visit(i_episode => i_id_episode))) p;
    
        RETURN l_medication_pfh;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_presc_treatment;

    /**
    * Check prescriptions for a given product.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   patient identifier
    * @param i_time         minimum register date
    * @param i_id_product   product identifier
    * @param o_presc        prescription identifiers list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/01
    */
    FUNCTION get_cdr_presc_by_product
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_time       IN TIMESTAMP,
        i_id_product IN table_varchar,
        o_presc      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CDR_PRESC_BY_PRODUCT';
    BEGIN
        g_error := 'CALL pk_rt_med_pfh.get_cdr_presc_by_product';
        IF NOT pk_rt_med_pfh.get_cdr_presc_by_product(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_patient => i_id_patient,
                                                      i_time       => i_time,
                                                      i_id_product => i_id_product,
                                                      o_presc      => o_presc,
                                                      o_error      => o_error)
        THEN
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_cdr_presc_by_product;

    /**
    * Check prescriptions for a given ingredient group.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   patient identifier
    * @param i_time         minimum register date
    * @param i_ing_group    ingredient group identifier
    * @param o_presc        prescription identifiers list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/01
    */
    FUNCTION get_cdr_by_ingred_grp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_time       IN TIMESTAMP,
        i_ing_group  IN VARCHAR2,
        o_presc      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CDR_BY_INGRED_GRP';
    BEGIN
        g_error := 'CALL pk_rt_med_pfh.get_cdr_by_ingred_grp';
        IF NOT pk_rt_med_pfh.get_cdr_by_ingred_grp(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_patient => i_id_patient,
                                                   i_time       => i_time,
                                                   i_ing_group  => i_ing_group,
                                                   o_presc      => o_presc,
                                                   o_error      => o_error)
        THEN
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_cdr_by_ingred_grp;

    /**
    * Check prescriptions for a given ingredient.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   patient identifier
    * @param i_time         minimum register date
    * @param i_id_ingredient ingredient identifier
    * @param o_presc        prescription identifiers list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/01
    */
    FUNCTION get_cdr_by_ingred
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_time          IN TIMESTAMP,
        i_id_ingredient IN VARCHAR2,
        o_presc         OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CDR_BY_INGRED';
    BEGIN
        g_error := 'CALL pk_rt_med_pfh.get_cdr_by_ingred';
        IF NOT pk_rt_med_pfh.get_cdr_by_ingred(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_id_patient    => i_id_patient,
                                               i_time          => i_time,
                                               i_id_ingredient => i_id_ingredient,
                                               o_presc         => o_presc,
                                               o_error         => o_error)
        THEN
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_cdr_by_ingred;

    /**
    * Check prescriptions for a given DDI.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   patient identifier
    * @param i_time         minimum register date
    * @param i_id_ddi       ddi identifier
    * @param o_presc        prescription identifiers list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/01
    */
    FUNCTION get_cdr_by_ddi
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_time       IN TIMESTAMP,
        i_id_ddi     IN VARCHAR2,
        o_presc      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CDR_BY_DDI';
    BEGIN
        g_error := 'CALL pk_rt_med_pfh.get_cdr_by_ddi';
        IF NOT pk_rt_med_pfh.get_cdr_by_ddi(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_patient => i_id_patient,
                                            i_time       => i_time,
                                            i_id_ddi     => i_id_ddi,
                                            o_presc      => o_presc,
                                            o_error      => o_error)
        THEN
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_cdr_by_ddi;

    /**
    * Check prescriptions for a given drug group.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   patient identifier
    * @param i_time         minimum register date
    * @param i_id_pharm_theraps drug group identifier
    * @param o_presc        prescription identifiers list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/01
    */
    FUNCTION get_cdr_by_pharm_theraps
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_time             IN TIMESTAMP,
        i_id_pharm_theraps IN VARCHAR2,
        o_presc            OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_med_pfh.get_cdr_by_pharm_theraps(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_id_patient       => i_id_patient,
                                                      i_time             => i_time,
                                                      i_id_pharm_theraps => i_id_pharm_theraps,
                                                      o_presc            => o_presc,
                                                      o_error            => o_error);
    END get_cdr_by_pharm_theraps;

    /********************************************************************************************
    * This function returns the administration list for hidrics screen (Intake and output) for IV fluids
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_VISIT      The id visit
    * @param  I_ID_UNIT       The unit measure
    * @param  I_DT_BEGIN      The begin date for task execution
    * @param  I_DT_END        The end date for task execution
    *
    * @author  Filipe Silva
    * @since   2011-09-02
    *
    ********************************************************************************************/
    FUNCTION get_list_fluid_balance
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_visit   IN visit.id_visit%TYPE,
        i_id_unit    IN unit_measure.id_unit_measure%TYPE,
        i_dt_begin   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_presc   IN table_number DEFAULT NULL,
        i_id_patient IN patient.id_patient%TYPE DEFAULT NULL
    ) RETURN pk_rt_types.g_t_fluid_balance
        PIPELINED IS
    BEGIN
        g_error := 'call pk_rt_med_pfh.get_list_fluid_balance with id_visit ' || i_id_visit;
        pk_alertlog.log_debug(g_error);
    
        FOR row_i IN (SELECT *
                        FROM TABLE(pk_rt_med_pfh.get_list_fluid_balance(i_lang       => i_lang,
                                                                        i_prof       => i_prof,
                                                                        i_id_patient => i_id_patient,
                                                                        i_id_visit   => i_id_visit,
                                                                        i_id_unit    => table_number(g_um_ml,
                                                                                                     g_um_ml_fr,
                                                                                                     g_um_ml_qsp),
                                                                        i_dt_begin   => i_dt_begin,
                                                                        i_dt_end     => i_dt_end)) med
                       WHERE med.id_status != pk_rt_med_pfh.st_undo
                         AND (med.id_presc IN (SELECT /*+opt_estimate(table,t1,scale_rows=0.0000001))*/
                                                t1.column_value
                                                 FROM TABLE(i_id_presc) t1) OR i_id_presc IS NULL))
        
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    END get_list_fluid_balance;

    /********************************************************************************************
    * This function returns information about prescription administrations
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_VISIT      The id visit
    * @param  I_DT_BEGIN      The begin date for task execution
    * @param  I_DT_END        The end date for task execution
    *
    * @author  Filipe Silva
    * @since   2011-09-02
    *
    ********************************************************************************************/
    FUNCTION get_list_administrations
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_visit IN visit.id_visit%TYPE,
        i_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN pk_rt_types.g_t_administrations
        PIPELINED IS
    BEGIN
        g_error := 'call pk_rt_med_pfh.get_list_administrations with id_visit ' || i_id_visit;
        pk_alertlog.log_debug(g_error);
        FOR row_i IN (SELECT *
                        FROM TABLE(pk_rt_med_pfh.get_list_administrations(i_lang          => i_lang,
                                                                          i_prof          => i_prof,
                                                                          i_id_visit      => i_id_visit,
                                                                          is_administered => pk_alert_constant.g_yes,
                                                                          i_dt_begin      => i_dt_begin,
                                                                          i_dt_end        => i_dt_end)))
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    END get_list_administrations;

    /********************************************************************************************
    * This function returns information about related medication
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  i_id_patient    Patient identifier
    * @param  i_id_episode    Episode identifier
    * @param  i_dt_begin      Begin date
    * @param  i_dt_end        End date
    *
    * @author  Sofia Mendes
    * @since   05-Set-2011
    *
    ********************************************************************************************/
    FUNCTION get_list_presc_previous
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN episode.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_begin   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN pk_rt_types.g_tbl_presc_previous
        PIPELINED IS
    BEGIN
        g_error := 'call pk_rt_med_pfh.get_list_presc_previous with i_id_patient: ' || i_id_patient ||
                   ' i_id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        FOR row_i IN (SELECT *
                        FROM TABLE(pk_rt_med_pfh.get_list_presc_previous(i_lang       => i_lang,
                                                                         i_prof       => i_prof,
                                                                         i_id_patient => i_id_patient,
                                                                         i_id_episode => i_id_episode)))
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    END get_list_presc_previous;

    /********************************************************************************************
    * This functions returns 'Y' if the prescription is in an active state, otherwise 'N'
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  i_id_presc      Presc ID    
    *
    * @author  Sofia Mendes
    * @since   11-Oct-2011
    *
    ********************************************************************************************/
    FUNCTION is_active_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        g_error := 'call pk_rt_med_pfh.is_active_presc with i_id_presc: ' || i_id_presc;
        pk_alertlog.log_debug(g_error);
        RETURN pk_rt_med_pfh.is_active_presc(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END is_active_presc;

    /********************************************************************************************
    * This function merges information from old patient or episode to new one
    *
    * @param    I_LANG              The language ID           
    * @param    I_PROF              The professional information        
    * @param    I_OLD_ID_PATIENT    The old patient ID, if I_NEW_ID_PATIENT is filled this field is mandatory
    * @param    I_NEW_ID_PATIENT    The new patient ID, if I_OLD_ID_PATIENT is filled this field is mandatory
    * @param    I_OLD_ID_EPISODE    The old episode ID, if I_NEW_ID_EPISODE is filled this field is mandatory         
    * @param    I_NEW_ID_EPISODE    The new episode ID, if I_OLD_ID_EPISODE is filled this field is mandatory             
    * @param    O_ERROR          
    *
    * @author  Bruno Rego
    * @version 2.6.1.1
    * @since   2011-07-27 
    *
    ********************************************************************************************/
    FUNCTION match_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_old_id_patient IN pk_rt_med_pfh.r_presc.id_patient%TYPE,
        i_new_id_patient IN pk_rt_med_pfh.r_presc.id_patient%TYPE,
        i_old_id_episode IN pk_rt_med_pfh.r_presc.id_epis_create%TYPE,
        i_new_id_episode IN pk_rt_med_pfh.r_presc.id_epis_create%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'MATCH_EPISODE';
    BEGIN
        g_error := 'CALL pk_rt_med_pfh.match_episode';
        pk_rt_med_pfh.merge_episode(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_old_id_patient => i_old_id_patient,
                                    i_new_id_patient => i_new_id_patient,
                                    i_old_id_episode => i_old_id_episode,
                                    i_new_id_episode => i_new_id_episode,
                                    o_error          => o_error);
    
        --workarround - the function in PK_RT_MED_PFH must be a function
        IF o_error.ora_sqlerrm IS NOT NULL
        THEN
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END match_episode;

    /**
    * Get ingredient description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_ingred    ingredient identifier
    *
    * @return               ingredient description
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/09
    */
    FUNCTION get_ingredients_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ingred IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_ingredients_desc(i_lang => i_lang, i_prof => i_prof, i_id_ingredients => i_id_ingred);
    END get_ingredients_desc;

    /**
    * Get ingredient group description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_ing_group ingredient group identifier
    *
    * @return               ingredient group description
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/09
    */
    FUNCTION get_ing_group_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ing_group IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_ing_group_desc(i_lang => i_lang, i_prof => i_prof, i_id_ing_group => i_id_ing_group);
    END get_ing_group_desc;

    /**
    * Unfolds a prescription into CDS concepts.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_presc     prescription identifier
    * @param o_products     products with hierarchy
    * @param o_id_products_no_hierarch        Products without hierarchy
    * @param o_ddis         interaction groups
    * @param o_ingreds      ingredients
    * @param o_ing_groups   ingredient groups
    * @param o_pharm_theraps pharmacotherapeutic groups
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/09
    */
    PROCEDURE get_cdr_concepts_by_presc
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_presc                IN VARCHAR2,
        o_products                OUT table_table_varchar,
        o_id_products_no_hierarch OUT table_varchar,
        o_ddis                    OUT table_table_varchar,
        o_ingreds                 OUT table_table_varchar,
        o_ing_groups              OUT table_table_varchar,
        o_pharm_theraps           OUT table_table_varchar,
        o_error                   OUT t_error_out
    ) IS
    BEGIN
        pk_rt_med_pfh.get_cdr_concepts_by_presc(i_lang                    => i_lang,
                                                i_prof                    => i_prof,
                                                i_id_presc                => i_id_presc,
                                                o_products                => o_products,
                                                o_id_products_no_hierarch => o_id_products_no_hierarch,
                                                o_ddis                    => o_ddis,
                                                o_ingredients             => o_ingreds,
                                                o_ing_groups              => o_ing_groups,
                                                o_pharm_theraps           => o_pharm_theraps,
                                                o_error                   => o_error);
    END get_cdr_concepts_by_presc;

    /********************************************************************************************
    * procedure gives the cdr concepts for a given product
    *
    * @param    I_LANG                                       IN        id language
    * @param    I_PROF                                       IN        profissional
    * @param    i_id_presc                                   IN        list of Prescription id,
    * @param    o_id_products                                IN        Products
    * @param    o_id_ddis                                    IN        ddi
    * @param    o_id_ingredients                             IN        ingredients 
    * @param    o_id_ing_groups                              IN        ingredients groups 
    
    * @param    O_ERROR                    
    *
    * @author   Sofia Mendes
    * @version   2.6.4
    * @since    02-06-2014
    *
    ********************************************************************************************/
    PROCEDURE get_cdr_concepts_by_prod
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_product_sup IN table_varchar,
        o_products       OUT table_table_varchar,
        o_ddis           OUT table_table_varchar,
        o_ingreds        OUT table_table_varchar,
        o_ing_groups     OUT table_table_varchar,
        o_pharm_theraps  OUT table_table_varchar,
        o_error          OUT t_error_out
    ) IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'get_cdr_concepts_by_prod';
    
    BEGIN
        g_error := ' pk_api_med_out.get_cdr_concepts_by_prod';
    
        pk_rt_med_pfh.get_cdr_concepts_by_prod(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_id_product_sup => i_id_product_sup,
                                               o_id_products    => o_products,
                                               o_ddis           => o_ddis,
                                               o_ingredients    => o_ingreds,
                                               o_ing_groups     => o_ing_groups,
                                               o_pharm_theraps  => o_pharm_theraps,
                                               o_error          => o_error);
    
    END get_cdr_concepts_by_prod;

    /**
    * Get a summary of exterior prescriptions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_epis         episode identifiers list
    * @param o_presc_ext    cursor
    * @param o_error        error
    *
    * @return               false, if errors occur, or true, otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/14
    */
    FUNCTION get_ext_med_summ_p
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_epis      IN table_number,
        o_presc_ext OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_EXT_MED_SUMM_P';
    BEGIN
        g_error := 'OPEN o_presc_ext';
        OPEN o_presc_ext FOR
            SELECT (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, t.id_presc)
                      FROM dual) desc_info,
                   t.dt_create dt_prescription,
                   t.id_last_episode id_episode,
                   pk_prof_utils.get_detail_signature(i_lang, i_prof, NULL, t.dt_upd, t.id_prof_upd) signature
              FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang,
                                                                   i_prof,
                                                                   table_number_id(pk_rt_med_pfh.wf_ambulatory),
                                                                   i_patient)) t
             WHERE t.id_last_episode IN (SELECT t.column_value id_episode
                                           FROM TABLE(i_epis) t)
               AND t.id_status = pk_rt_med_pfh.st_concluded
             ORDER BY t.dt_create;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_presc_ext);
            RETURN FALSE;
    END get_ext_med_summ_p;

    /**
    * Get a summary of local prescriptions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_epis         episode identifiers list
    * @param o_presc_ext    cursor
    * @param o_error        error
    *
    * @return               false, if errors occur, or true, otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/14
    */
    FUNCTION get_local_med_summ_p
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_epis    IN table_number,
        o_presc   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LOCAL_MED_SUMM_P';
    BEGIN
        IF i_epis.exists(1)
        THEN
            g_error := 'OPEN o_presc';
            OPEN o_presc FOR
                SELECT (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, t.id_presc)
                          FROM dual) desc_info,
                       t.id_last_episode id_episode,
                       pk_prof_utils.get_detail_signature(i_lang, i_prof, NULL, t.dt_upd, t.id_prof_upd) signature
                  FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang,
                                                                       i_prof,
                                                                       table_number_id(pk_rt_med_pfh.wf_institution,
                                                                                       pk_rt_med_pfh.wf_iv),
                                                                       i_patient)) t
                 WHERE (t.id_last_episode IN (SELECT t.column_value id_episode
                                                FROM TABLE(i_epis) t) --
                       OR --
                       (pk_rt_med_pfh.presc_is_home_care(i_lang => i_lang, i_prof => i_prof, i_id_presc => t.id_presc) =
                       pk_alert_constant.g_yes AND
                       t.id_status NOT IN
                       (pk_rt_med_pfh.st_cancelled, pk_rt_med_pfh.st_discontinued, pk_rt_med_pfh.st_concluded)) --
                       OR --
                       (pk_rt_med_pfh.presc_is_episode_home_care(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_id_presc   => t.id_presc,
                                                                  i_id_episode => i_epis(1)) =
                       pk_alert_constant.g_yes) AND
                       t.id_status IN
                       (pk_rt_med_pfh.st_cancelled, pk_rt_med_pfh.st_discontinued, pk_rt_med_pfh.st_concluded))
                   AND t.id_status NOT IN (pk_rt_med_pfh.st_cancelled,
                                           pk_rt_med_pfh.st_prescribed_pharm_req,
                                           pk_rt_med_pfh.st_suspended_pharm_req,
                                           pk_rt_med_pfh.st_ongoing_pharm_req,
                                           pk_rt_med_pfh.st_suspended_ongoing_pharm_req);
        ELSE
            pk_types.open_my_cursor(i_cursor => o_presc);
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_presc);
            RETURN FALSE;
    END get_local_med_summ_p;

    /**
    * Get a summary of pharmacy requests.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_epis         episode identifiers list
    * @param o_presc_ext    cursor
    * @param o_error        error
    *
    * @return               false, if errors occur, or true, otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/14
    */
    FUNCTION get_pharm_req_summ_p
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_epis      IN table_number,
        o_pharm_req OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PHARM_REQ_SUMM_P';
    BEGIN
        IF i_epis.exists(1)
        THEN
            g_error := 'OPEN o_pharm_req';
            OPEN o_pharm_req FOR
                SELECT pk_rt_med_pfh.get_presc_dir_str(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_presc     => t.id_presc,
                                                       i_flg_html     => pk_alert_constant.g_no,
                                                       i_flg_complete => pk_alert_constant.g_no) desc_info,
                       t.id_last_episode id_episode
                  FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang,
                                                                       i_prof,
                                                                       table_number_id(pk_rt_med_pfh.wf_institution),
                                                                       i_patient)) t
                 WHERE (t.id_last_episode IN (SELECT t.column_value id_episode
                                                FROM TABLE(i_epis) t) OR
                       pk_rt_med_pfh.presc_is_home_care(i_lang => i_lang, i_prof => i_prof, i_id_presc => t.id_presc) =
                       pk_alert_constant.g_yes)
                   AND t.id_status IN (pk_rt_med_pfh.st_prescribed_pharm_req,
                                       pk_rt_med_pfh.st_suspended_pharm_req,
                                       pk_rt_med_pfh.st_ongoing_pharm_req,
                                       pk_rt_med_pfh.st_suspended_ongoing_pharm_req)
                 ORDER BY t.dt_create;
        ELSE
            pk_types.open_my_cursor(i_cursor => o_pharm_req);
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_pharm_req);
            RETURN FALSE;
    END get_pharm_req_summ_p;

    /**
    * Get a summary of pharmacy requests.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_epis         episode identifiers list
    * @param o_presc_ext    cursor
    * @param o_error        error
    *
    * @return               false, if errors occur, or true, otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/14
    */
    FUNCTION get_prev_med_summ_s
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_epis       IN table_number,
        o_medication OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PREV_MED_SUMM_S';
    BEGIN
        g_error := 'OPEN o_medication';
        OPEN o_medication FOR
            SELECT (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, t.id_presc)
                      FROM dual) || ' (' ||
                   ltrim(pk_rt_med_pfh.get_presc_dir_str(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_presc     => t.id_presc,
                                                         i_flg_html     => pk_alert_constant.g_no,
                                                         i_flg_complete => pk_alert_constant.g_yes)) || ')' desc_info,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_create, i_prof) dt,
                   t.id_last_episode id_episode,
                   pk_prof_utils.get_detail_signature(i_lang, i_prof, t.id_last_episode, t.dt_upd, t.id_prof_upd) signature
              FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang,
                                                                   i_prof,
                                                                   table_number_id(pk_rt_med_pfh.wf_report),
                                                                   i_patient)) t
             WHERE t.id_last_episode IN (SELECT t.column_value id_episode
                                           FROM TABLE(i_epis) t)
               AND t.id_status = pk_rt_med_pfh.st_active
             ORDER BY t.dt_create;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_medication);
            RETURN FALSE;
    END get_prev_med_summ_s;

    /********************************************************************************************
    * Gets the medication counter from presc_pat_problem, used on pk_problems
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat_allergy         pat_allergy identifier
    * @param i_flg_status             presc_pat_problem flag status
    * @param i_flg_type               presc_pat_problem flag type
    *                        
    * @return                         number
    * 
    * @author                         Paulo Teixeira
    * @version                        1.0
    * @since                          2011/05/23
    * @dependents                     PK_PROBLEMS
    **********************************************************************************************/
    FUNCTION get_medication_counter_pa
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_allergy IN presc_pat_problem.id_pat_allergy%TYPE,
        i_flg_status     IN presc_pat_problem.flg_status %TYPE,
        i_flg_type       IN presc_pat_problem.flg_type%TYPE
    ) RETURN NUMBER IS
        l_return NUMBER;
    BEGIN
        SELECT COUNT(*) medication_counter
          INTO l_return
          FROM presc_pat_problem ppp
         WHERE ppp.id_pat_allergy = i_id_pat_allergy
           AND ppp.flg_status <> i_flg_status
           AND ppp.flg_type = i_flg_type;
    
        RETURN l_return;
    END get_medication_counter_pa;

    /********************************************************************************************
    * Gets the medication counter from presc_pat_problem, used on pk_problems
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat_history_diagnosis         pat_history_diagnosis identifier
    * @param i_flg_status             presc_pat_problem flag status
    * @param i_flg_type               presc_pat_problem flag type
    *                        
    * @return                         number
    * 
    * @author                         Paulo Teixeira
    * @version                        1.0
    * @since                          2011/05/23
    * @dependents                     PK_PROBLEMS
    **********************************************************************************************/
    FUNCTION get_medication_counter_phd
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_pat_history_diagnosis IN presc_pat_problem.id_pat_history_diagnosis%TYPE,
        i_flg_status               IN presc_pat_problem.flg_status %TYPE,
        i_flg_type                 IN presc_pat_problem.flg_type%TYPE
    ) RETURN NUMBER IS
        l_return NUMBER;
    BEGIN
        SELECT COUNT(*) medication_counter
          INTO l_return
          FROM presc_pat_problem ppp
         WHERE ppp.id_pat_history_diagnosis = i_id_pat_history_diagnosis
           AND ppp.flg_status <> i_flg_status
           AND ppp.flg_type = i_flg_type;
    
        RETURN l_return;
    END get_medication_counter_phd;

    /********************************************************************************************
    * Gets the medication counter from presc_pat_problem, used on pk_problems
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat_problem         pat_problem identifier
    * @param i_flg_status             presc_pat_problem flag status
    * @param i_flg_type               presc_pat_problem flag type
    *                        
    * @return                         number
    * 
    * @author                         Paulo Teixeira
    * @version                        1.0
    * @since                          2011/05/23
    * @dependents                     PK_PROBLEMS
    **********************************************************************************************/
    FUNCTION get_medication_counter_pp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN presc_pat_problem.id_pat_problem%TYPE,
        i_flg_status     IN presc_pat_problem.flg_status %TYPE,
        i_flg_type       IN presc_pat_problem.flg_type%TYPE
    ) RETURN NUMBER IS
        l_return NUMBER;
    BEGIN
        SELECT COUNT(*) medication_counter
          INTO l_return
          FROM presc_pat_problem ppp
         WHERE ppp.id_pat_problem = i_id_pat_problem
           AND ppp.flg_status <> i_flg_status
           AND ppp.flg_type = i_flg_type;
    
        RETURN l_return;
    END get_medication_counter_pp;

    /********************************************************************************************
    * Returns the sum of admistration list for IV fluids
    *
    * @param  I_LANG                  The language id
    * @param  I_PROF                  The profissional
    * @param  i_id_epis_hidrics       The id epis_hidrics
    * @param  I_DT_BEGIN              The begin date for task execution
    * @param  I_DT_END                The end date for task execution
    * @param  I_ID_PRESC              Prescription ID
    *
    * @author  Filipe Silva
    * @since   2011-09-19
    *
    ********************************************************************************************/
    FUNCTION get_fluid_balance_med_tot
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_presc        IN pk_rt_core_all.t_big_num DEFAULT NULL
    ) RETURN NUMBER IS
    
        l_sum      NUMBER(24);
        l_id_visit visit.id_visit%TYPE;
    
    BEGIN
        g_error := 'get id_visit of id_epis_hidrics ' || i_id_epis_hidrics;
        pk_alertlog.log_debug(g_error);
    
        SELECT pk_episode.get_id_visit(eh.id_episode)
          INTO l_id_visit
          FROM epis_hidrics eh
         WHERE eh.id_epis_hidrics = i_id_epis_hidrics;
    
        g_error := 'call pk_rt_med_pfh.get_list_fluid_balance with id_visit ' || l_id_visit;
        pk_alertlog.log_debug(g_error);
    
        SELECT SUM(qty)
          INTO l_sum
          FROM (SELECT dt_execution_task,
                       pk_rt_med_pfh.calc_administered_volume(i_id_presc           => med.id_presc,
                                                              i_id_presc_plan      => med.id_presc_plan,
                                                              i_id_presc_plan_task => med.id_presc_plan_task) qty
                  FROM TABLE(pk_rt_med_pfh.get_list_fluid_balance_basic(i_lang     => i_lang,
                                                                        i_prof     => i_prof,
                                                                        i_id_visit => l_id_visit,
                                                                        i_id_unit  => table_number(g_um_ml,
                                                                                                   g_um_ml_fr,
                                                                                                   g_um_ml_qsp),
                                                                        i_dt_begin => NULL,
                                                                        i_dt_end   => NULL)) med
                 WHERE med.id_presc = nvl(i_id_presc, med.id_presc)
                   AND med.id_status != pk_rt_med_pfh.st_undo)
         WHERE pk_date_utils.trunc_insttimezone(i_prof.institution, i_prof.software, dt_execution_task, 'MI') BETWEEN
               i_dt_begin AND i_dt_end;
    
        RETURN l_sum;
    
    END get_fluid_balance_med_tot;

    /********************************************************************************************
    * Get patient's medication
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_medication_list    List of PAT_MEDICATION_LIST IDs
    * @param i_id_episode             the episode ID
    * @param o_pat_medication_list    Medication info to multichoice use
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.1.2
    * @since                          2011-09-20
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION get_previous_medication
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_pat_medication_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PREVIOUS_MEDICATION';
        --
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'OPEN O_PAT_MEDICATION_LIST';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
        OPEN o_pat_medication_list FOR
            WITH list_prescription AS
             (SELECT p.*, pk_rt_med_pfh.is_active_state(i_lang, i_prof, p.id_status, p.id_workflow) flg_display
                FROM TABLE(pk_rt_med_pfh.get_reported_medication(i_lang       => i_lang,
                                                                 i_prof       => i_prof,
                                                                 i_id_episode => i_id_episode)) p)
            SELECT lp.id_presc data,
                   pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, lp.id_presc) pharm,
                   lp.flg_display
              FROM list_prescription lp;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_types.open_my_cursor(o_pat_medication_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_medication_list);
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
    END get_previous_medication;

    /********************************************************************************************
    * This procedure updates prec episode, saving the previous in the presc.id_prev_episode
    * only to be used for GRID_TASK processing
    *
    * @param  i_lang                     The language ID
    * @param  i_prof                     The professional array
    * @param  i_id_episode               Previous episode
    * @param  i_new_episode              New episode
    * @param  o_error                    The error object
    *
    * @author                            Pedro Teixeira
    * @since                             24/05/2011
    ********************************************************************************************/
    PROCEDURE set_presc_new_episode
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN pk_rt_med_pfh.r_presc.id_epis_create%TYPE,
        i_new_episode IN pk_rt_med_pfh.r_presc.id_epis_create%TYPE,
        o_error       OUT t_error_out
    ) IS
        l_proc_name CONSTANT VARCHAR2(30 CHAR) := 'SET_PRESC_NEW_EPISODE';
    BEGIN
        g_error := 'CALL PK_RT_MED_PFH.SET_PRESC_NEW_EPISODE';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_proc_name, text => g_error);
        pk_rt_med_pfh.set_presc_new_episode(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_id_episode  => i_id_episode,
                                            i_new_episode => i_new_episode,
                                            o_error       => o_error);
    END set_presc_new_episode;

    /*********************************************************************************************
    * This function will update the Grid Task for a certain episode
    *
    * @param i_lang               The ID of the user language
    * @param i_prof               The profissional array
    * @param i_id_episode         Episode Id
    *
    *
    * @author  Pedro Teixeira 
    * @since   2011/08/19
    **********************************************************************************************/
    PROCEDURE process_epis_grid_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN pk_rt_med_pfh.r_presc.id_epis_create%TYPE
    ) IS
        l_proc_name CONSTANT VARCHAR2(30 CHAR) := 'PROCESS_EPIS_GRID_TASK';
    BEGIN
        g_error := 'CALL PK_API_PFH_IN.PROCESS_EPIS_GRID_TASK';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_proc_name, text => g_error);
        pk_api_pfh_in.process_epis_grid_task(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode);
    END process_epis_grid_task;

    /********************************************************************************************
    * Returns dates takes
    *
    * @param  I_LANG                  The language id
    * @param  I_PROF                  The profissional
    * @param  I_ID_EPIS_HIDRICS       The id epis_hidrics
    * @param  I_DT_BEGIN              The begin date for task execution
    * @param  I_DT_END                The end date for task execution
    *
    * @author  Filipe Silva
    * @since   2011-09-21
    *
    ********************************************************************************************/
    FUNCTION get_fluid_balance_med_dates
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE
    ) RETURN table_timestamp_tz IS
    
        l_take_date       table_timestamp_tz;
        l_id_visit        visit.id_visit%TYPE;
        l_dt_initial_tstz epis_hidrics.dt_initial_tstz%TYPE;
        l_dt_end_tstz     epis_hidrics.dt_end_tstz%TYPE;
    
    BEGIN
    
        g_error := 'get id_unit_measure of id_epis_hidrics ' || i_id_epis_hidrics;
        pk_alertlog.log_debug(g_error);
    
        SELECT pk_episode.get_id_visit(eh.id_episode),
               eh.dt_initial_tstz,
               coalesce(eh.dt_end_tstz, eh.dt_inter_tstz, current_timestamp)
          INTO l_id_visit, l_dt_initial_tstz, l_dt_end_tstz
          FROM epis_hidrics eh
         WHERE eh.id_epis_hidrics = i_id_epis_hidrics;
    
        g_error := 'call pk_rt_med_pfh.get_list_fluid_balance for id_visit ' || l_id_visit;
        pk_alertlog.log_debug(g_error);
    
        SELECT DISTINCT pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                         i_prof.software,
                                                         med.dt_execution_task,
                                                         'MI')
          BULK COLLECT
          INTO l_take_date
          FROM TABLE(pk_rt_med_pfh.get_list_fluid_balance_basic(i_lang     => i_lang,
                                                                i_prof     => i_prof,
                                                                i_id_visit => l_id_visit,
                                                                i_id_unit  => table_number(g_um_ml,
                                                                                           g_um_ml_fr,
                                                                                           g_um_ml_qsp),
                                                                i_dt_begin => l_dt_initial_tstz,
                                                                i_dt_end   => l_dt_end_tstz)) med
         WHERE med.id_status != pk_rt_med_pfh.st_undo;
    
        RETURN l_take_date;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN table_timestamp_tz();
    END get_fluid_balance_med_dates;

    /********************************************************************************************
    * Get's medication patient
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_medication_list    List of PAT_MEDICATION_LIST IDs
    * @param i_id_episode             the episode ID
    * @param o_pat_medication_list    Medication info to multichoice use
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    *
    * @author  Filipe Silva
    * @since   2011-09-21
    *
    ********************************************************************************************/
    FUNCTION get_prev_medication_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_pat_medication_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PREVIOUS_MEDICATION';
    
    BEGIN
        g_error := 'OPEN O_PAT_MEDICATION_LIST';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
        OPEN o_pat_medication_list FOR
            WITH list_prescription AS
             (SELECT p.*, pk_rt_med_pfh.is_active_state(i_lang, i_prof, p.id_status, p.id_workflow) flg_display
                FROM TABLE(pk_rt_med_pfh.get_ambulatory_medication(i_lang       => i_lang,
                                                                   i_prof       => i_prof,
                                                                   i_id_episode => i_id_episode)) p)
            
            SELECT lp.id_presc data,
                   pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, lp.id_presc) desc_drug,
                   lp.flg_display
              FROM list_prescription lp;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_medication_list);
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
    END get_prev_medication_list;

    /********************************************************************************************
    * This function descontinue or cancel the prescription depending on the current state
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_PRESC      The prescription Id
    *
    * @author  Pedro Teixeira
    * @since   2011-09-07
    *
    ********************************************************************************************/
    FUNCTION call_cancel_rep_medication
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_presc    IN pk_rt_core_all.t_big_num,
        i_id_reason   IN pk_rt_core_all.t_big_num,
        i_reason      IN VARCHAR2,
        i_notes       IN VARCHAR2,
        i_flg_confirm IN VARCHAR2 DEFAULT 'Y',
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CALL_CANCEL_REP_MEDICATION';
        --
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL TO PK_RT_MED_PFH.SET_CANCEL_PRESC';
        pk_alertlog.log_debug(text => g_error);
        IF NOT pk_rt_med_pfh.set_cancel_presc(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_id_presc    => i_id_presc,
                                              i_id_reason   => i_id_reason,
                                              i_reason      => i_reason,
                                              i_notes       => i_notes,
                                              i_flg_confirm => i_flg_confirm,
                                              o_error       => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
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
    END call_cancel_rep_medication;

    /********************************************************************************************
    * This function descontinue or cancel the prescription depending on the current state
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_PRESC      The prescription Id
    *
    * @author  Pedro Teixeira
    * @since   2011-09-07
    *
    ********************************************************************************************/
    FUNCTION call_cancel_rep_medication
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_presc    IN table_number,
        i_id_reason   IN pk_rt_core_all.t_big_num,
        i_reason      IN VARCHAR2,
        i_notes       IN VARCHAR2,
        i_flg_confirm IN VARCHAR2 DEFAULT 'Y',
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CALL_CANCEL_REP_MEDICATION';
        --
        l_internal_error EXCEPTION;
    BEGIN
        FOR i IN i_id_presc.first .. i_id_presc.last
        LOOP
            g_error := 'CALL TO PK_RT_MED_PFH.SET_CANCEL_PRESC';
            pk_alertlog.log_debug(text => g_error);
            IF NOT pk_rt_med_pfh.set_cancel_presc(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_id_presc    => i_id_presc(i),
                                                  i_id_reason   => i_id_reason,
                                                  i_reason      => i_reason,
                                                  i_notes       => i_notes,
                                                  i_flg_confirm => i_flg_confirm,
                                                  o_error       => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
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
    END call_cancel_rep_medication;

    /********************************************************************************************
    * Get's active medication patient
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_filter_date            Filter date
    * @param o_pat_medication_list    Medication info 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    *
    * @author  Filipe Silva
    * @since   2011-09-23
    *
    ********************************************************************************************/
    FUNCTION get_current_medication
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_filter_date         IN INTERVAL DAY TO SECOND,
        o_pat_medication_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CURRENT_MEDICATION';
    
    BEGIN
        g_error := 'OPEN O_PAT_MEDICATION_LIST';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
        RETURN pk_rt_med_pfh.get_list_active_and_last_presc(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_visit            => pk_episode.get_id_visit(i_id_episode),
                                                            i_int_last_terminated => i_filter_date,
                                                            o_pat_medication_list => o_pat_medication_list,
                                                            o_error               => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_medication_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_current_medication;

    /********************************************************************************************
    * GET_DRUG_FLUIDS_NUM
    *
    * @param i_id_episode          episode identifier
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Maia
    * @version                     2.6.1.1
    * @since                       2011/04/21
    * @dependents                  PK_DISCHARGE.CHECK_DISCHARGE
    **********************************************************************************************/
    FUNCTION get_drug_fluids_num
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN PLS_INTEGER IS
        l_drug_fluids_num PLS_INTEGER := 0;
    BEGIN
    
        SELECT COUNT(1)
          INTO l_drug_fluids_num
          FROM TABLE(pk_rt_med_pfh.get_list_active_prescription(i_lang     => i_lang,
                                                                i_prof     => i_prof,
                                                                i_id_visit => pk_episode.get_id_visit(i_episode => i_id_episode)));
    
        -- SUCCESS
        RETURN l_drug_fluids_num;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_drug_fluids_num;

    /*******************************************************************************************************************************************
    * Get all current active information related with the medication for the patitent                                                          *
    *                                                                                                                                          *
    * @ param i_lang             Id do idioma                                                                                                  *
    * @ param i_prof             professional array                                                                                            *
    * @ param i_id_patient       patient OD                                                                                                    *
    * @ param o_active_med                                                                                                                     *
    *                                                                                                                                          *
    * @ param o_error                                                                                                                          *
    *                                                                                                                                          *
    * @return                     TRUE if success and FALSE otherwise                                                                          *
    *                                                                                                                                          *
    * @author                      Filipe Silva                                                                                            *
    * @version                     1.0                                                                                                         *
    * @since                       2011/09/24                                                                                                  *
    *@notes                        a espera de uma api da "nova" farmacia ALERT-113674
    *******************************************************************************************************************************************/
    FUNCTION get_active_medication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_prescription   IN table_number,
        i_prescription_type IN table_varchar,
        o_active_med        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_active_med FOR
            SELECT NULL id_prescription,
                   NULL prescription_type,
                   NULL lbl_type_desc,
                   NULL type_desc,
                   NULL date_presc,
                   NULL lbl_med_presc,
                   NULL med_presc,
                   NULL lbl_directions,
                   NULL directions,
                   NULL flg_active,
                   NULL descr_prof,
                   NULL descr_spec,
                   NULL id_episode
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_ACTIVE_MEDICATION',
                                                     o_error    => o_error);
        
    END get_active_medication;

    /********************************************************************************************
    * Get medication reconciliation info
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_patient              Patient ID
    * @param i_id_episode              Episode ID
    * @param o_info                    Medication reconciliation data
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          Jos?Brito
    * @version                         2.6
    * @since                           29-Sep-2011
    *
    **********************************************************************************************/
    FUNCTION get_reconciliation_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_RECONCILIATION_STATUS';
    BEGIN
    
        pk_rt_med_pfh.get_reconciliation_status(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_patient => i_id_patient,
                                                i_id_episode => i_id_episode,
                                                o_info       => o_info,
                                                o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_info);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_reconciliation_status;

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
    
        RETURN pk_rt_med_pfh.get_confirmation_screen_data(i_lang                   => i_lang,
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

    /**
    * Get a patient's medication. Used in PFH dashboards/summary screens.
    * Adapted from pk_medication_current.get_history_medication_dash.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_hist_med     cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/30
    */
    FUNCTION get_history_medication_dash
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_hist_med OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_HISTORY_MEDICATION_DASH';
        l_dt_server VARCHAR2(20 CHAR);
    BEGIN
        l_dt_server := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => current_timestamp, i_prof => i_prof);
    
        g_error := 'OPEN o_hist_med';
        OPEN o_hist_med FOR
            SELECT unique_id,
                   subject,
                   rank,
                   id_presc,
                   desc_drug,
                   date_med_order,
                   current_status,
                   l_dt_server dt_server,
                   instr_bg_color,
                   instr_bg_alpha
              FROM (SELECT t.id_presc       unique_id,
                           t.id_status      subject,
                           t.presc_rank     rank,
                           t.id_presc,
                           t.prod_desc      desc_drug,
                           t.dt_create      date_med_order,
                           t.status_desc    current_status,
                           t.instr_bg_color,
                           t.instr_bg_alpha
                      FROM TABLE(pk_api_pfh_in.get_list_presc_resumed(i_lang                 => i_lang,
                                                                      i_prof                 => i_prof,
                                                                      i_id_patient           => i_patient,
                                                                      i_eliminate_duplicates => 'Y')) t
                     WHERE (i_episode IS NULL OR
                           (i_episode IS NOT NULL AND t.id_last_episode <= i_episode AND EXISTS
                            (SELECT 1
                                FROM episode e
                               WHERE e.id_episode = t.id_last_episode
                                 AND e.flg_status IN (pk_alert_constant.g_epis_status_active,
                                                      pk_alert_constant.g_epis_status_inactive,
                                                      pk_alert_constant.g_epis_status_pendent))) OR
                           pk_rt_med_pfh.presc_is_home_care(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_id_presc => t.id_presc) = pk_alert_constant.g_yes)
                       AND t.id_status NOT IN (pk_rt_med_pfh.st_draft,
                                               pk_rt_med_pfh.st_cancelled,
                                               pk_rt_med_pfh.st_temp_edition,
                                               pk_rt_med_pfh.st_cpoe_draft)
                       AND ((t.id_workflow = pk_rt_med_pfh.wf_report AND t.id_last_episode = i_episode) OR
                           t.id_workflow != pk_rt_med_pfh.wf_report))
             ORDER BY rank, date_med_order, unique_id;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_hist_med);
            RETURN FALSE;
    END get_history_medication_dash;

    /**
    * Get a patient's current medication descriptions.
    * Used in the ambulatory SOAP screen.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_this_episode cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/10/03
    */
    FUNCTION get_cur_med_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_id_workflow IN table_number_id
    ) RETURN table_varchar IS
        l_ret   table_varchar;
        l_visit episode.id_visit%TYPE;
    BEGIN
        g_error := 'CALL pk_episode.get_id_visit';
        l_visit := pk_episode.get_id_visit(i_episode => i_episode);
    
        SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, m.id_presc) desc_drug
          BULK COLLECT
          INTO l_ret
          FROM (SELECT DISTINCT t.id_presc
                  FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang        => i_lang,
                                                                       i_prof        => i_prof,
                                                                       i_id_workflow => i_id_workflow,
                                                                       i_id_patient  => i_patient,
                                                                       i_id_visit    => l_visit)) t
                 WHERE t.id_status != pk_rt_med_pfh.st_cancelled
                 ORDER BY 1) m;
    
        RETURN l_ret;
    END get_cur_med_desc;

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
    * @author                          Jos?Brito
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
        RETURN pk_rt_med_pfh.get_presc_description(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_tab_presc         => i_tab_presc,
                                                   o_presc_description => o_presc_description,
                                                   o_error             => o_error);
    END get_presc_description;

    /**********************************************************************************************
    * Get allergy rxnorm
    *
    * @version                       2.6.1.2
    * @since                         2011/10/06
    **********************************************************************************************/
    FUNCTION get_allergy_rxnorm
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_allergy IN NUMBER,
        o_info       OUT table_table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CANCEL_PROBLEM';
        --
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_rt_med_pfh.get_allergy_rxnorm(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_allergy => i_id_allergy,
                                                o_info       => o_info,
                                                o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
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
    END get_allergy_rxnorm;

    /********************************************************************************************
    * This function returns generic information about reported medication 
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_PATIENT    The ids to filter data
    * @param  I_DT_BEGIN      The cursor output with prescription history changes
    * @param  I_DT_END        The cursor output with prescription history changes
    * @param  i_history_data  [Y,N] checks if history data will be shown
    *
    * @author  Sofia Mendes
    * @version 2.6.2
    * @since   2011-11-10 
    *
    ********************************************************************************************/
    FUNCTION get_list_report_active_presc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE DEFAULT NULL,
        i_id_visit     IN visit.id_visit%TYPE DEFAULT NULL,
        i_dt_begin     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_history_data IN VARCHAR2 DEFAULT 'N'
    ) RETURN pk_rt_types.g_tbl_list_prescription_basic
        PIPELINED IS
    
    BEGIN
    
        FOR row_i IN (SELECT *
                        FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang,
                                                                             i_prof,
                                                                             table_number_id(pk_rt_med_pfh.wf_report),
                                                                             i_id_patient,
                                                                             i_id_visit,
                                                                             NULL,
                                                                             NULL,
                                                                             i_dt_begin,
                                                                             i_dt_end,
                                                                             i_history_data)))
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    
    END get_list_report_active_presc;

    /********************************************************************************************
    * This procedure sets the information about home medication global information.
    *
    * @param i_lang                    The user language ID
    * @param i_prof                    The profissional information array
    * @param i_id_patient              The patient ID 
    * @param i_id_episode              The the prescription report info details
    * @param io_id_review              The ID review
    * @param i_global_info             The global information multichoice
    * @param o_error                   The output error
    *
    * @author  Bruno Rego
    * @version alpha
    * @since   2011/09/08
    ********************************************************************************************/
    FUNCTION set_hm_review_global_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN pk_rt_med_pfh.r_presc.id_patient%TYPE,
        i_id_episode  IN NUMBER,
        io_id_review  IN OUT NUMBER,
        i_global_info IN NUMBER,
        o_info        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'SET_HM_REVIEW_GLOBAL_INFO';
    BEGIN
    
        RETURN pk_rt_med_pfh.set_hm_review_global_info(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_id_patient  => i_id_patient,
                                                       i_id_episode  => i_id_episode,
                                                       io_id_review  => io_id_review,
                                                       i_global_info => i_global_info,
                                                       o_info        => o_info,
                                                       o_error       => o_error);
    END;

    /**
    * Get the list of ingredients of a set of products.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_products  product identifiers list
    * @param o_id_ingreds   ingredient identifiers list
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/01/20
    */
    PROCEDURE get_ingredients_by_products
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_products IN table_varchar,
        o_id_ingreds  OUT table_varchar
    ) IS
    BEGIN
        pk_rt_med_pfh.get_ingredients_by_products(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_products    => i_id_products,
                                                  o_id_ingredients => o_id_ingreds);
    END get_ingredients_by_products;

    /********************************************************************************************
    * Get decriptions used on Single Page and Single Note functionality of a given medication
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_PRESC                 id of prescribed drug
    * @param   I_FLG_COMPLETE             Flag indicating if description is complete ('Y'-complete; 'N'-Incomplete)
    * @param   [I_FLG_WITH_NOTES]         Flag that indicates if the notes preffix is in the instructions or not
    * @param   [I_FLG_WITH_STATUS]        Flag that indicates if the status should be in the description or not
    * @param   [I_FLG_WITH_RECON_NOTES]   Flag that indicates if the reconciliation notes should be in the description or not
    *
    * @return                             string of drug prescribed or null if no_data_found, or error msg
    *
    * @author                             Luís Maia
    * @version                            2.6.2
    * @since                              24-Jan-2012
    *
    **********************************************************************************************/
    FUNCTION get_single_page_med_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_presc              IN table_number,
        i_flg_complete          IN VARCHAR2,
        i_flg_with_notes        IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_status       IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_recon_notes  IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_no,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE DEFAULT NULL,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL
    ) RETURN pk_prog_notes_types.t_tasks_descs IS
        l_presc_desc      VARCHAR2(32000);
        l_presc_desc_long VARCHAR2(32000);
        l_selection_list  VARCHAR2(4000);
        --
        l_id_review      PLS_INTEGER;
        l_code_review    PLS_INTEGER;
        l_id_prof_create professional.id_professional%TYPE;
        l_dt_create      TIMESTAMP WITH LOCAL TIME ZONE;
        --
        l_out_strut            t_error_out;
        l_info                 pk_types.cursor_type;
        l_id_presc             pk_rt_core_all.t_big_num;
        l_id_visit             visit.id_visit%TYPE;
        l_id_patient           patient.id_patient%TYPE;
        l_dt_begin             TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end               TIMESTAMP WITH LOCAL TIME ZONE;
        l_prod_desc            VARCHAR2(4000 CHAR);
        l_presc_instructions   VARCHAR2(32000 CHAR);
        l_status_desc          VARCHAR2(1000 CHAR);
        l_recon_notes          VARCHAR2(4000 CHAR);
        l_tasks_descs          pk_prog_notes_types.t_tasks_descs;
        l_desc_rec             pk_prog_notes_types.t_rec_task_desc;
        l_dt_last_update       TIMESTAMP WITH LOCAL TIME ZONE;
        l_presc_last_notes     CLOB;
        l_frequency_desc       pk_translation.t_desc_translation;
        l_free_text_directions pk_translation.t_desc_translation;
        l_prn_desc             VARCHAR2(1000 CHAR);
        l_route_desc           VARCHAR2(1000 CHAR);
        l_duration_desc        VARCHAR2(1000 CHAR);
        l_dose_desc            VARCHAR2(1000 CHAR);
        l_freq_desc            VARCHAR2(1000 CHAR);
        l_dt_last_take         TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_info_source  CLOB;
        l_pat_not_take CLOB;
        l_pat_take     CLOB;
        l_notes        CLOB;
        l_token_list   table_varchar := table_varchar();
        l_delivery     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PROGRESS_NOTES_M013');
                l_delivery_qt     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PROGRESS_NOTES_M014');
    BEGIN
        -- This select can only return one row
        g_error := 'CALL pk_api_pfh_in.get_presc_for_single_page.';
        pk_alertlog.log_debug(g_error);
        pk_api_pfh_in.get_presc_for_single_page(i_lang                 => i_lang,
                                                i_prof                 => i_prof,
                                                i_id_presc             => i_id_presc,
                                                i_flg_with_notes       => i_flg_with_notes,
                                                i_flg_with_recon_notes => i_flg_with_recon_notes,
                                                o_info                 => l_info);
    
        LOOP
            FETCH l_info
                INTO l_id_presc,
                     l_id_visit,
                     l_id_patient,
                     l_dt_begin,
                     l_dt_end,
                     l_prod_desc,
                     l_presc_instructions,
                     l_status_desc,
                     l_recon_notes,
                     l_presc_last_notes,
                     l_frequency_desc,
                     l_free_text_directions,
                     l_prn_desc,
                     l_route_desc,
                     l_dose_desc,
                     l_freq_desc,
                     l_duration_desc,
                     l_dt_last_take;
            EXIT WHEN l_info%NOTFOUND;
        
            g_error := 'CALL pk_api_pfh_in.get_presc_directions. i_id_presc: ' || l_id_presc;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_api_pfh_in.get_last_review(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_id_episode     => i_id_episode,
                                                 i_id_patient     => l_id_patient,
                                                 i_dt_begin       => l_dt_begin,
                                                 i_dt_end         => l_dt_end,
                                                 o_id_review      => l_id_review,
                                                 o_code_review    => l_code_review,
                                                 o_review_desc    => l_selection_list,
                                                 o_dt_create      => l_dt_create,
                                                 o_dt_update      => l_dt_last_update,
                                                 o_id_prof_create => l_id_prof_create,
                                                 o_info_source    => l_info_source,
                                                 o_pat_not_take   => l_pat_not_take,
                                                 o_pat_take       => l_pat_take,
                                                 o_notes          => l_notes)
            THEN
                l_selection_list := '';
            ELSE
                IF l_code_review <> pk_api_pfh_in.g_hm_review_none
                THEN
                    l_selection_list := l_selection_list || chr(10);
                ELSE
                    l_selection_list := '';
                END IF;
            END IF;
        
            IF (i_flg_description IS NULL OR i_flg_description <> pk_prog_notes_constants.g_flg_description_c)
            THEN
                IF l_presc_instructions IS NULL
                THEN
                    IF i_flg_with_status = pk_alert_constant.g_yes
                    THEN
                        l_presc_instructions := ' (';
                    ELSE
                        l_presc_instructions := '';
                    END IF;
                ELSE
                    l_presc_instructions := ' (' || l_presc_instructions;
                END IF;
            
                IF i_flg_with_status = pk_alert_constant.g_yes
                THEN
                    IF l_presc_instructions IS NULL
                    THEN
                        l_status_desc := l_status_desc || ')';
                    ELSE
                        l_status_desc := ', ' || l_status_desc || ')';
                    END IF;
                ELSE
                    IF l_presc_instructions IS NULL
                    THEN
                        l_status_desc := '';
                    ELSE
                        l_status_desc := ')';
                    END IF;
                
                END IF;
            
                IF i_flg_with_recon_notes = pk_alert_constant.g_yes
                   AND l_recon_notes IS NOT NULL
                THEN
                    l_recon_notes := chr(10) || l_recon_notes;
                ELSE
                    l_recon_notes := '';
                END IF;
            
                l_presc_desc := l_prod_desc || l_presc_instructions || l_status_desc || l_recon_notes;
            
                IF l_dt_last_take IS NOT NULL
                THEN
                    l_presc_desc := l_presc_desc || ' - ' ||
                                    pk_message.get_message(i_lang => i_lang, i_code_mess => 'MED_PRESC_T071') || ':' ||
                                    pk_date_utils.date_char_tsz(i_lang,
                                                                l_dt_last_take,
                                                                i_prof.institution,
                                                                i_prof.software);
                END IF;
            
                IF i_flg_complete = pk_alert_constant.g_yes
                THEN
                    l_presc_desc_long := l_selection_list || l_presc_desc;
                END IF;
            
            ELSE
                l_token_list := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|'); -- REPORT-DATE|INVESTIGATION|RESULT
                FOR i IN 1 .. l_token_list.last
                LOOP
                    --PROD_DESC|FREQ|PRESC_NOTES|START_DATE|END_DATE
                    IF l_token_list(i) = 'PROD_DESC'
                    THEN
                        IF l_presc_desc IS NOT NULL
                        THEN
                            l_presc_desc := l_presc_desc || l_prod_desc;
                        ELSE
                            l_presc_desc := l_prod_desc;
                        END IF;
                    ELSIF l_token_list(i) = 'FREQ'
                          AND l_frequency_desc IS NOT NULL
                    THEN
                        l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma || l_frequency_desc;
                    ELSIF l_token_list(i) = 'FREE_TXT_DIRECTIONS'
                          AND l_free_text_directions IS NOT NULL
                    THEN
                        l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma || l_free_text_directions;
                    ELSIF l_token_list(i) = 'PRESC_NOTES'
                          AND l_presc_last_notes IS NOT NULL
                    THEN
                        l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma || l_presc_last_notes;
                    ELSIF l_token_list(i) = 'CATEGORY'
                    THEN
                        IF l_presc_desc IS NOT NULL
                        THEN
                            l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma ||
                                            pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_T152');
                        ELSE
                            l_presc_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_T152');
                        END IF;
                    ELSIF l_token_list(i) = 'START_DATE'
                          AND l_dt_begin IS NOT NULL
                    THEN
                    
                        IF i > 1
                        THEN
                            l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma;
                        END IF;
                        l_presc_desc := l_presc_desc ||
                                        pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                    i_date => l_dt_begin,
                                                                    i_inst => i_prof.institution,
                                                                    i_soft => i_prof.software);
                    
                        IF i = 1
                        THEN
                            l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma;
                        END IF;
                    ELSIF l_token_list(i) = 'START-DATE'
                          AND l_dt_begin IS NOT NULL
                    THEN
                        IF l_presc_desc IS NOT NULL
                        THEN
                            l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma ||
                                            pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                        i_date => l_dt_begin,
                                                                        i_inst => i_prof.institution,
                                                                        i_soft => i_prof.software);
                        ELSE
                            l_presc_desc := pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                        i_date => l_dt_begin,
                                                                        i_inst => i_prof.institution,
                                                                        i_soft => i_prof.software);
                        END IF;
                    
                        IF i = 1
                        THEN
                            l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_space;
                        END IF;
                    ELSIF l_token_list(i) = 'END_DATE'
                          AND l_dt_end IS NOT NULL
                    THEN
                        l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma ||
                                        pk_message.get_message(i_lang => i_lang, i_code_mess => 'MED_DIR_END') ||
                                        pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                    i_date => l_dt_end,
                                                                    i_inst => i_prof.institution,
                                                                    i_soft => i_prof.software);
                    
                    ELSIF l_token_list(i) = 'PRN'
                          AND l_prn_desc IS NOT NULL
                    THEN
                        l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma || l_prn_desc;
                    
                    ELSIF l_token_list(i) = 'ROUTE'
                          AND l_route_desc IS NOT NULL
                    THEN
                        l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma || l_route_desc;
                    
                    ELSIF l_token_list(i) = 'DURATION'
                          AND l_duration_desc IS NOT NULL
                    THEN
                        l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma || l_duration_desc;
                    
                    ELSIF l_token_list(i) = 'DOSE'
                          AND l_dose_desc IS NOT NULL
                    THEN
                        l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma || l_dose_desc;
                    
                    ELSIF l_token_list(i) = 'FREQUENCY'
                          AND l_freq_desc IS NOT NULL
                    THEN
                        l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma || l_freq_desc;
                    ELSIF l_token_list(i) = 'DELIVERY'
                    THEN
                        IF l_presc_desc IS NOT NULL
                        THEN
                            l_presc_desc := l_presc_desc || l_delivery || chr(10) || l_delivery_qt || chr(10);
                        ELSE
                            l_presc_desc := l_delivery || chr(10)|| l_delivery_qt || chr(10);
                        END IF;
                    
                    ELSIF l_token_list(i) = 'LAST_TAKE'
                          AND l_freq_desc IS NOT NULL
                    THEN
                        IF l_dt_last_take IS NOT NULL
                        THEN
                            l_presc_desc := l_presc_desc || pk_prog_notes_constants.g_comma ||
                                            pk_message.get_message(i_lang => i_lang, i_code_mess => 'MED_PRESC_T071') || ': ' ||
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        l_dt_last_take,
                                                                        i_prof.institution,
                                                                        i_prof.software);
                        END IF;
                    END IF;
                
                END LOOP;
            END IF;
            l_presc_desc              := l_presc_desc || chr(10);
            l_desc_rec.task_desc      := to_clob(l_presc_desc);
            l_desc_rec.task_desc_long := to_clob(l_presc_desc_long);
        
            l_tasks_descs(l_id_presc) := l_desc_rec;
        
        END LOOP;
        CLOSE l_info;
        RETURN l_tasks_descs;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_tasks_descs;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SINGLE_PAGE_MED_DESC',
                                              l_out_strut);
            RETURN l_tasks_descs;
    END get_single_page_med_desc;

    /********************************************************************************************
    * get home medication actions for a given prescription  
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_presc                prescription id  
    * @param       i_class_origin_context class origin context
    * @param       o_action               cursor with prescription actions
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Sofia Mendes
    * @since                              19-MAR-2012
    ********************************************************************************************/
    FUNCTION get_home_med_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_presc                IN epis_pn_det_task.id_task%TYPE,
        i_class_origin_context IN VARCHAR2,
        o_action               OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        -- input parameters debug message    
        pk_alertlog.log_debug('pk_api_pfh_clindoc_in.get_home_med_actions called with:' || 'i_presc=' || i_presc,
                              g_package_name);
    
        -- call pk_rt_med_pfh.get_presc_actions function
        IF NOT pk_rt_med_pfh.get_home_med_actions(i_lang                 => i_lang,
                                                  i_prof                 => i_prof,
                                                  i_id_presc             => table_number(i_presc),
                                                  i_class_origin_context => i_class_origin_context,
                                                  o_action               => o_action,
                                                  o_error                => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.get_presc_actions function';
            RAISE l_internal_error;
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
                                              'GET_HOME_MED_ACTIONS',
                                              o_error);
            RETURN FALSE;
    END get_home_med_actions;

    /********************************************************************************************
    * get local medication actions for a given prescription  
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_presc                prescription id  
    * @param       i_class_origin                  IN       class origin
    * @param       i_class_origin_context class origin context
    * @param       o_action               cursor with prescription actions
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Sofia Mendes
    * @since                              19-MAR-2012
    ********************************************************************************************/
    FUNCTION get_presc_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_presc                IN epis_pn_det_task.id_task%TYPE,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        o_action               OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        -- input parameters debug message    
        pk_alertlog.log_debug('pk_api_pfh_clindoc_in.get_presc_actions called with:' || 'i_presc=' || i_presc,
                              g_package_name);
    
        -- call pk_rt_med_pfh.get_presc_actions function
        IF NOT pk_rt_med_pfh.get_presc_actions(i_lang                 => i_lang,
                                               i_prof                 => i_prof,
                                               i_id_presc             => table_number(i_presc),
                                               i_class_origin_context => i_class_origin_context,
                                               i_class_origin         => i_class_origin,
                                               o_action               => o_action,
                                               o_error                => o_error)
        
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.get_presc_actions function';
            RAISE l_internal_error;
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
                                              'GET_PRESC_ACTIONS',
                                              o_error);
            RETURN FALSE;
    END get_presc_actions;

    /********************************************************************************************
    * get reconciliation medication actions for a given prescription  
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_presc                prescription id  
    * @param       i_class_origin_context class origin context
    * @param       o_action               cursor with prescription actions
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Sofia Mendes
    * @since                              12-Oct-2012
    ********************************************************************************************/
    FUNCTION get_recon_med_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_presc                IN epis_pn_det_task.id_task%TYPE,
        i_class_origin_context IN VARCHAR2,
        o_action               OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        -- input parameters debug message    
        pk_alertlog.log_debug('pk_rt_med_pfh.get_recon_med_actions called with:' || 'i_presc=' || i_presc,
                              g_package_name);
    
        -- call pk_rt_med_pfh.get_recon_med_actions function
        IF NOT pk_rt_med_pfh.get_recon_med_actions(i_lang                 => i_lang,
                                                   i_prof                 => i_prof,
                                                   i_id_presc             => table_number(i_presc),
                                                   i_class_origin_context => i_class_origin_context,
                                                   i_flg_ignore_inactive  => pk_alert_constant.g_no,
                                                   o_action               => o_action,
                                                   o_error                => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.get_recon_med_actions function';
            RAISE l_internal_error;
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
                                              'GET_RECON_MED_ACTIONS',
                                              o_error);
            RETURN FALSE;
    END get_recon_med_actions;

    /********************************************************************************************
    * get local medication actions for a given prescription  
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_id_patient           Patient ID
    * @param       i_id_episode           Episode ID
    * @param       i_id_presc             prescription id  
    * @param       i_id_action            Action ID
    * @param       o_info                 cursor with action info
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Sofia Mendes
    * @since                              23-MAR-2012
    ********************************************************************************************/
    FUNCTION set_review_presc_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN presc.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_presc   IN table_number,
        i_id_action  IN table_number,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        -- input parameters debug message    
        pk_alertlog.log_debug('pk_api_pfh_clindoc_in.set_review_presc_status called with:' || ' i_id_patient=' ||
                              i_id_patient || ' i_id_episode: ' || i_id_episode,
                              g_package_name);
    
        -- call pk_rt_med_pfh.get_presc_actions function
        IF NOT pk_rt_med_pfh.set_review_presc_status(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_id_patient => i_id_patient,
                                                     i_id_episode => i_id_episode,
                                                     i_id_presc   => i_id_presc,
                                                     i_id_action  => i_id_action,
                                                     o_info       => o_info,
                                                     o_error      => o_error)
        THEN
            g_error := 'error found while calling pk_rt_med_pfh.set_review_presc_status function';
            RAISE l_internal_error;
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
                                              'SET_REVIEW_PRESC_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_review_presc_status;

    /********************************************************************************************
    * @param  I_LANG                  The language id
    * @param  I_PROF                  The profissional
    * @param  I_ID_VISIT            
    *
    * @author Joel Lopes
    * @since  2014-07-24
    *
    ********************************************************************************************/

    FUNCTION get_rt_epis_presc_id_drug
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN tf_med_tasks IS
        l_func_name VARCHAR2(32 CHAR) := 'GET_RT_EPIS_PRESC_ID_DRUG';
        l_error     t_error_out;
    
        l_med_ret tf_med_tasks;
    
        l_current_profile profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof);
    
        CURSOR c_drug IS
            SELECT tr_med_tasks(med_tasks.id_drug, NULL, NULL, NULL, NULL)
              FROM TABLE(pk_rt_med_pfh.get_rt_epis_presc_id_drug(i_lang,
                                                                 i_prof,
                                                                 i_id_visit => pk_episode.get_id_visit(i_episode => i_episode))) med_tasks
              JOIN profile_context pc
                ON pc.id_context = med_tasks.id_drug
             WHERE pc.id_profile_template = l_current_profile
               AND pc.flg_type = pk_rt_tech.g_drug
               AND pc.flg_available = pk_rt_tech.g_yes
               AND pc.id_institution IN (i_prof.institution, 0);
    BEGIN
    
        g_error := 'OPEN c_drug';
        OPEN c_drug;
        FETCH c_drug BULK COLLECT
            INTO l_med_ret;
        CLOSE c_drug;
    
        RETURN l_med_ret;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_rt_epis_presc_id_drug;

    /********************************************************************************************
    * @param  I_LANG                  The language id
    * @param  I_PROF                  The profissional
    * @param  I_ID_VISIT            
    *
    * @author Joel Lopes
    * @since  2014-07-24
    *
    ********************************************************************************************/

    FUNCTION get_rt_epis_drug_desc_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN tf_med_tasks IS
        l_func_name VARCHAR2(32) := 'GET_RT_EPIS_DRUG_DESC_STATUS';
        l_error     t_error_out;
    
        l_med_ret tf_med_tasks;
    
        CURSOR c_drug IS
            WITH list_rt_epis_presc AS
             (SELECT t.*
                FROM TABLE(pk_rt_med_pfh.get_rt_epis_presc_desc_status(i_lang     => i_lang,
                                                                       i_prof     => i_prof,
                                                                       i_id_visit => pk_episode.get_id_visit(i_episode => i_episode))) t)
            -- Get data 
            SELECT tr_med_tasks(NULL, tbl.desc_status, NULL, NULL, NULL)
              FROM list_rt_epis_presc tbl;
    
    BEGIN
    
        g_error := 'OPEN c_drug';
        OPEN c_drug;
        FETCH c_drug BULK COLLECT
            INTO l_med_ret;
        CLOSE c_drug;
    
        RETURN l_med_ret;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_rt_epis_drug_desc_status;

    /*******************************************************************************************
    * alert_product_tr performance questions by pedro pinheiro
    *
    * @return  type
    *
    * @author      Joel Lopes
    * @version     2.6.5.0
    * @since       27/03/2015
    *
    *******************************************************************************************/

    FUNCTION get_list_fluid_balance_basic
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_visit   IN visit.id_visit%TYPE,
        i_dt_begin   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_presc   IN table_number DEFAULT NULL,
        i_id_patient IN patient.id_patient%TYPE DEFAULT NULL
    ) RETURN t_tbl_list_fluid_balance IS
        l_ret t_tbl_list_fluid_balance := t_tbl_list_fluid_balance(NULL);
    BEGIN
        g_error := 'call pk_rt_med_pfh.get_list_fluid_balance_basic with id_visit ' || i_id_visit;
        pk_alertlog.log_debug(g_error);
    
        SELECT t_rec_list_fluid_balance(id_presc,
                                        id_presc_plan,
                                        g_id_drug,
                                        id_route,
                                        id_route_supplier,
                                        code_status,
                                        dt_execution_task,
                                        id_prof_task,
                                        id_episode_adm,
                                        id_status,
                                        id_presc_plan_task,
                                        id_unit_measure,
                                        id_prof_writes,
                                        dt_writes,
                                        id_route_status)
          BULK COLLECT
          INTO l_ret
          FROM TABLE(pk_rt_med_pfh.get_list_fluid_balance_basic(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_id_patient => i_id_patient,
                                                                i_id_visit   => i_id_visit,
                                                                i_id_unit    => table_number(g_um_ml,
                                                                                             g_um_ml_fr,
                                                                                             g_um_ml_qsp),
                                                                i_dt_begin   => i_dt_begin,
                                                                i_dt_end     => i_dt_end)) med
         WHERE med.id_status != pk_rt_med_pfh.st_undo
           AND (med.id_presc IN (SELECT /*+opt_estimate(table t1 rows=1)*/
                                  t1.column_value
                                   FROM TABLE(i_id_presc) t1) OR i_id_presc IS NULL);
        RETURN l_ret;
    
    END get_list_fluid_balance_basic;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_api_pfh_clindoc_in;
/
