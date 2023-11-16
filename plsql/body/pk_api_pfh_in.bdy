/*-- Last Change Revision: $Rev: 2055066 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2023-02-03 16:25:00 +0000 (sex, 03 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_pfh_in IS

    -- debug mode enabled/disabled
    g_debug BOOLEAN;
    g_exception EXCEPTION;
    g_retval BOOLEAN;

    /********************************************************************************************
    * process_presc_grid_task
    *
    *
    * @author                          Pedro Teixeira
    * @version                         2.6.1.2
    * @since                           2011/07/27
    *
    **********************************************************************************************/
    PROCEDURE process_presc_grid_task
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'PROCESS_PRESC_GRID_TASK';
        l_error_out t_error_out;
    
        l_process_name VARCHAR2(30);
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_debug(g_error, g_package_name, l_db_object_name);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => i_dg_table_name,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        IF i_event_type IN
           (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_delete)
        THEN
        
            IF i_event_type = t_data_gov_mnt.g_event_insert
            THEN
                l_process_name := 'INSERT';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name := 'UPDATE';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name := 'DELETE';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  i_dg_table_name || ')',
                                  g_package_name,
                                  l_db_object_name);
        
            -- Call Routing function
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                pk_rt_med_pfh.process_presc_grid_task(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_source_table_name => i_source_table_name,
                                                      i_rowids            => i_rowids,
                                                      o_error             => l_error_out);
            
            END IF;
        END IF;
    
        RETURN;
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END process_presc_grid_task;

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
        i_id_episode IN r_presc.id_epis_create%TYPE
    ) IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'PROCESS_EPIS_GRID_TASK';
        l_error_out t_error_out;
    
    BEGIN
        g_error := 'CALL PK_RT_MED_PFH.PROCESS_EPIS_GRID_TASK';
        pk_rt_med_pfh.process_epis_grid_task(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_id_episode,
                                             o_error      => l_error_out);
    
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END process_epis_grid_task;

    /******************************************************************************************
    * This procedure returns the rank for given prescription
    *
    * @param i_lang          The ID of the user language
    * @param i_prof          The profissional information array
    * @param i_id_presc      The prescription ID
    * 
    * @return The rank for the given prescription
    *
    * @author                Bruno Rego
    * @version               V.2.6.1
    * @since                 2011/08/25
    ********************************************************************************************/
    FUNCTION get_presc_rank
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN NUMBER IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_RANK';
        l_error_out t_error_out;
    BEGIN
    
        RETURN pk_rt_med_pfh.get_presc_rank(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error_out);
            RAISE;
    END;

    /********************************************************************************************
    * This function processes the prescription time task, returning to PFH the necessary information to update time task
    * only to be used for TIME_TASK processing
    *
    * @author                            Pedro Teixeira
    * @since                             02/08/2011
    ********************************************************************************************/
    PROCEDURE get_presc_time_task_line
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_rowids     IN table_varchar,
        o_presc_data OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_TIME_TASK_LINE';
    
    BEGIN
        g_error := 'CALL PK_RT_MED_PFH.GET_PRESC_TIME_TASK_LINE';
        pk_rt_med_pfh.get_presc_time_task_line(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_rowids     => i_rowids,
                                               o_presc_data => o_presc_data,
                                               o_error      => o_error);
    
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_presc_time_task_line;

    /********************************************************************************************
    * This function processes the prescription time task, returning to PFH the necessary information to update time task
    * only to be used for TIME_TASK processing
    *
    * @author                            Pedro Teixeira
    * @since                             26/08/2011
    ********************************************************************************************/
    PROCEDURE get_presc_time_task_line
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN r_presc.id_patient%TYPE,
        i_id_episode IN r_presc.id_last_episode%TYPE,
        o_presc_data OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_TIME_TASK_LINE';
        l_error_out t_error_out;
    
    BEGIN
        g_error := 'CALL PK_RT_MED_PFH.GET_PRESC_TIME_TASK_LINE V2';
        pk_rt_med_pfh.get_presc_time_task_line(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_id_patient => i_id_patient,
                                               i_id_episode => i_id_episode,
                                               o_presc_data => o_presc_data,
                                               o_error      => o_error);
    
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_presc_time_task_line;

    /********************************************************************************************
    * This function processes the recon time task, returning to PFH the necessary information to update recon task
    *
    * @author                          Pedro Teixeira
    * @since                           09/06/2017
    ********************************************************************************************/
    PROCEDURE get_recon_time_task_line
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN presc.id_patient%TYPE,
        i_id_episode IN presc.id_last_episode%TYPE,
        o_recon_data OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'GET_RECON_TIME_TASK_LINE';
    
    BEGIN
        g_error := 'CALL pk_rt_med_pfh.get_recon_time_task_line';
        pk_rt_med_pfh.get_recon_time_task_line(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_id_patient => i_id_patient,
                                               i_id_episode => i_id_episode,
                                               o_recon_data => o_recon_data,
                                               o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
    END get_recon_time_task_line;

    /********************************************************************************************
    * This function processes notes time task, returning to PFH the necessary information to update time task
    * only to be used for TIME_TASK processing
    *
    * @author           Pedro Teixeira
    * @since            2012/05/04
    ********************************************************************************************/
    PROCEDURE get_presc_notes_ttl
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_rowids     IN table_varchar,
        o_notes_info OUT pk_types.cursor_type
    ) IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'GET_PRESC_NOTES_TTL';
        l_error_out t_error_out;
    BEGIN
        g_error := 'CALL PK_RT_MED_PFH.GET_PRESC_NOTES_TTL';
        pk_rt_med_pfh.get_presc_notes_ttl(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_rowids     => i_rowids,
                                          o_notes_info => o_notes_info);
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_presc_notes_ttl;

    /********************************************************************************************
    * This function processes notes time task, returning to PFH the necessary information to update time task
    * only to be used for TIME_TASK processing
    *
    * @author           Pedro Teixeira
    * @since            2012/05/04
    ********************************************************************************************/
    PROCEDURE get_presc_notes_ttl
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN r_presc.id_patient%TYPE,
        i_id_episode IN r_presc.id_last_episode%TYPE,
        o_notes_info OUT pk_types.cursor_type
    ) IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'GET_PRESC_NOTES_TTL';
        l_error_out t_error_out;
    BEGIN
        g_error := 'CALL PK_RT_MED_PFH.GET_PRESC_NOTES_TTL V2';
        pk_rt_med_pfh.get_presc_notes_ttl(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_id_patient => i_id_patient,
                                          i_id_episode => i_id_episode,
                                          o_notes_info => o_notes_info);
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_presc_notes_ttl;

    /********************************************************************************************
    * This function returns generic information about prescription basic version
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_WORKFLOW   The workflow 
    * @param  I_ID_PATIENT    The ids to filter data
    * @param  I_ID_VISIT      The visit   
    * @param  I_ID_PRESC      The prescription
    *
    * @author  Alexis Nascimento
    * @since   2013-07-16 
    *
    ********************************************************************************************/
    FUNCTION get_list_prescription_basic
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_workflow  IN table_number_id DEFAULT NULL,
        i_id_patient   IN r_presc.id_patient%TYPE DEFAULT NULL,
        i_id_visit     IN r_presc.id_epis_create%TYPE DEFAULT NULL,
        i_id_presc     IN r_presc.id_presc%TYPE DEFAULT NULL,
        i_dt_begin     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_history_data IN VARCHAR2 DEFAULT 'N' -- [Y,N] checks if history data will be shown
    ) RETURN pk_rt_types.g_tbl_list_prescription_basic
        PIPELINED IS
    BEGIN
    
        FOR row_i IN (SELECT *
                        FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang         => i_lang,
                                                                             i_prof         => i_prof,
                                                                             i_id_workflow  => i_id_workflow,
                                                                             i_id_patient   => i_id_patient,
                                                                             i_id_visit     => i_id_visit,
                                                                             i_id_presc     => i_id_presc,
                                                                             i_dt_begin     => i_dt_begin,
                                                                             i_dt_end       => i_dt_end,
                                                                             i_history_data => i_history_data)))
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    
    END get_list_prescription_basic;

    /********************************************************************************************
    * This function returns DATA_GOV_ADMIN prescription count 
    *
    *
    * @author  Pedro Teixeira
    * @version 2.6.2.0.1
    * @since   2011-12-07 
    *
    ********************************************************************************************/
    FUNCTION get_dga_prescription_count
    (
        i_id_workflow IN table_number_id, --[WF_INSTITUTION, WF_AMBULATORY, WF_REPORT]
        i_id_visit    IN r_presc.id_epis_create%TYPE,
        i_id_episode  IN r_presc.id_last_episode%TYPE
    ) RETURN NUMBER IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_DGA_PRESCRIPTION_COUNT';
    BEGIN
        RETURN pk_rt_med_pfh.get_dga_prescription_count(i_id_workflow => i_id_workflow,
                                                        i_id_visit    => i_id_visit,
                                                        i_id_episode  => i_id_episode);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => l_db_object_name);
            RAISE;
    END;

    /**********************************************************************************************
    * Gets the prescription status string
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_presc              Prescription identifier 
    *
    * @return                        Returns the status string of the prescription
    *                        
    * @author                        Pedro Teixeira
    * @version                       2.6.1.2
    * @since                         2011/08/25
    **********************************************************************************************/
    FUNCTION get_presc_status_icon
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_STATUS_ICON';
        l_error_out t_error_out;
    
    BEGIN
    
        RETURN pk_rt_med_pfh.get_presc_status_icon(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_presc_status_icon;

    /**********************************************************************************************
    * Gets the description of a most frequent product
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_most_freq          id most frequent product 
    *
    * @return                        Returns the name of the product
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/08/26
    **********************************************************************************************/
    FUNCTION get_most_freq_product_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_most_freq IN NUMBER
    ) RETURN VARCHAR2 IS
        l_prod_desc VARCHAR2(4000);
        l_error     t_error_out;
    BEGIN
    
        l_prod_desc := pk_rt_med_pfh.get_most_freq_product_desc(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_id_most_freq => i_id_most_freq);
    
        RETURN l_prod_desc;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MOST_FREQ_PRODUCT_DESC',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_most_freq_product_desc;

    /**********************************************************************************************
    * Gets the treatment management
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID 
    *
    * @return                        Returns treatments with at least one execution should appear in grid
    *                        
    * @author                        Nuno Neves
    * @version                       2.6.1.2
    * @since                         2011/08/26
    **********************************************************************************************/
    FUNCTION get_treat_manag
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN g_tbl_list_treat_manag
        PIPELINED IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_TREAT_MANAG';
        l_error_out t_error_out;
    
        l_sysdate_char    VARCHAR2(50);
        l_icon_type_drug  sys_domain.img_name%TYPE := 'TherapeuticIcon';
        l_treat_type_drug treatment_management.flg_type%TYPE := 'D';
        l_treat_manag     g_tbl_list_treat_manag;
        l_id_visit        episode.id_visit%TYPE;
    
        CURSOR c_treat_manag IS
            SELECT g_rec_list_treatment_manag(id_presc,
                                              g_id_presc_mci_desc_short,
                                              id_presc_directions_desc_long,
                                              conv_presc_status_new2old,
                                              id_status_desc,
                                              l_treat_type_drug,
                                              desc_treatment_management,
                                              dt_begin,
                                              hr_begin,
                                              id_status_icon,
                                              l_icon_type_drug,
                                              l_sysdate_char)
              FROM (SELECT /*+OPT_ESTIMATE(TABLE PRESC ROWS=1)*/
                     presc.id_presc,
                     presc.g_id_presc_mci_desc_short,
                     presc.id_presc_directions_desc_long,
                     pk_rt_med_pfh.get_conv_presc_status_new2old(i_lang, i_prof, presc.id_workflow, presc.id_status) conv_presc_status_new2old,
                     presc.id_status_desc,
                     l_treat_type_drug,
                     (SELECT tm.desc_treatment_management
                        FROM treatment_management tm
                       WHERE tm.id_treatment = presc.id_presc
                         AND tm.flg_type = l_treat_type_drug
                         AND tm.dt_creation_tstz = (SELECT MAX(tm1.dt_creation_tstz)
                                                      FROM treatment_management tm1
                                                     WHERE tm1.id_treatment = presc.id_presc
                                                       AND tm1.flg_type = l_treat_type_drug)) desc_treatment_management,
                     pk_date_utils.dt_chr(i_lang, presc.dt_begin, i_prof) dt_begin,
                     pk_date_utils.date_char_hour(i_lang, presc.dt_begin, i_prof.institution, i_prof.software) hr_begin,
                     presc.id_status_icon
                      FROM TABLE(pk_rt_med_pfh.get_list_presc_last_plan(i_lang        => i_lang,
                                                                        i_prof        => i_prof,
                                                                        i_id_workflow => table_number_id(pk_rt_med_pfh.wf_institution,
                                                                                                         pk_rt_med_pfh.wf_iv),
                                                                        i_id_visit    => l_id_visit)) presc);
    BEGIN
    
        l_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        g_error        := 'pk_episode.get_id_visit';
    
        BEGIN
            l_id_visit := pk_episode.get_id_visit(i_episode => i_epis);
        EXCEPTION
            WHEN no_data_found THEN
                RETURN;
        END;
    
        OPEN c_treat_manag;
    
        FETCH c_treat_manag BULK COLLECT
            INTO l_treat_manag;
    
        FOR i IN 1 .. l_treat_manag.count
        LOOP
            PIPE ROW(l_treat_manag(i));
        END LOOP;
    
        CLOSE c_treat_manag;
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_treat_manag;

    /**********************************************************************************************
    * Gets the treatment management notes
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    * @param i_flg_type               Tipo de revisão sobre: I - Intervention ;D - Drug
    * @param i_treat_manag            treatment management id 
    *
    * @return                        Returns treatment management notes
    *                        
    * @author                        Nuno Neves
    * @version                       2.6.1.2
    * @since                         2011/08/29
    **********************************************************************************************/
    FUNCTION get_treat_manag_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis        IN episode.id_episode%TYPE,
        i_flg_type    IN treatment_management.flg_type%TYPE,
        i_treat_manag IN treatment_management.id_treatment%TYPE
    ) RETURN g_tbl_list_treat_manag_notes
        PIPELINED IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_TREAT_MANAG_DET';
        l_error_out t_error_out;
    
        l_treat_manag_notes g_tbl_list_treat_manag_notes;
    
        CURSOR c_treat_manag_notes IS
            SELECT /*+OPT_ESTIMATE(TABLE PRESC ROWS=1)*/ /*+OPT_ESTIMATE(TABLE PLAN ROWS=1)*/
             g_rec_list_treat_manag_notes(presc.id_presc,
                                          /* presc.g_id_presc_mci_desc_short*/
                                          (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, presc.id_presc)
                                             FROM dual),
                                          tm.desc_treatment_management,
                                          pk_date_utils.date_send_tsz(i_lang, tm.dt_creation_tstz, i_prof),
                                          pk_date_utils.dt_chr_tsz(i_lang, tm.dt_creation_tstz, i_prof),
                                          pk_date_utils.date_char_hour_tsz(i_lang,
                                                                           tm.dt_creation_tstz,
                                                                           i_prof.institution,
                                                                           i_prof.software),
                                          pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                             tm.dt_creation_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software),
                                          pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                          pk_prof_utils.get_spec_signature(i_lang,
                                                                           i_prof,
                                                                           p.id_professional,
                                                                           tm.dt_creation_tstz,
                                                                           i_epis))
              FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang => i_lang,
                                                                   i_prof => i_prof,
                                                                   --i_id_workflow => i_id_workflow,
                                                                   i_id_visit => pk_episode.get_id_visit(i_epis))) presc
              JOIN treatment_management tm
                ON tm.id_treatment = presc.id_presc
              JOIN professional p
                ON p.id_professional = tm.id_professional
             WHERE tm.flg_type = i_flg_type
               AND presc.id_presc = i_treat_manag;
    
    BEGIN
    
        OPEN c_treat_manag_notes;
    
        FETCH c_treat_manag_notes BULK COLLECT
            INTO l_treat_manag_notes;
    
        FOR i IN 1 .. l_treat_manag_notes.count
        LOOP
            PIPE ROW(l_treat_manag_notes(i));
        END LOOP;
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_treat_manag_det;

    /**********************************************************************************************
    * Gets the professional and date of the last update treatment notes
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    *
    * @return                        Returns the professional and date of the last update treatment notes
    *                        
    * @author                        Nuno Neves
    * @version                       2.6.1.2
    * @since                         2011/08/31
    **********************************************************************************************/
    FUNCTION get_summary_list_last_upd
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN g_tbl_list_treat_manag_l_upd
        PIPELINED IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_SUMMARY_LIST_LAST_UPD';
        l_error_out t_error_out;
    
        l_treat_manag_l_upd g_tbl_list_treat_manag_l_upd;
    
        CURSOR c_last_update IS
            SELECT /*+ cardinality( presc 20 ) */ /*+OPT_ESTIMATE(TABLE PLAN ROWS=1)*/
             g_rec_list_treat_manag_l_upd(tm.dt_creation_tstz, tm.id_professional)
              FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang     => i_lang,
                                                                   i_prof     => i_prof,
                                                                   i_id_visit => pk_episode.get_id_visit(i_epis))) presc
              JOIN (SELECT *
                      FROM TABLE(pk_rt_med_pfh.get_list_presc_plan(i_lang     => i_lang,
                                                                   i_prof     => i_prof,
                                                                   i_id_visit => pk_episode.get_id_visit(i_epis)))) plan
                ON plan.id_presc = presc.id_presc
              JOIN treatment_management tm
                ON tm.id_treatment = presc.id_presc;
    
    BEGIN
    
        OPEN c_last_update;
    
        FETCH c_last_update BULK COLLECT
            INTO l_treat_manag_l_upd;
    
        FOR i IN 1 .. l_treat_manag_l_upd.count
        LOOP
            PIPE ROW(l_treat_manag_l_upd(i));
        END LOOP;
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_summary_list_last_upd;

    /**********************************************************************************************
    * Gets the title of treatment notes
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   the episode ID
    *
    * @return                        Returns the title of treatment notes
    *                        
    * @author                        Nuno Neves
    * @version                       2.6.1.2
    * @since                         2011/08/31
    **********************************************************************************************/
    FUNCTION get_title_treatement_manag
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN g_tbl_title_treat_manag
        PIPELINED IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_TITLE_TREATEMENT_MANAG';
        l_error_out t_error_out;
    
        l_title_treat_manag g_tbl_title_treat_manag;
        l_treat_type_drug   treatment_management.flg_type%TYPE := 'D';
    
        CURSOR c_title_treat_manag IS
            SELECT /*+ cardinality( presc 20 ) */ /*+OPT_ESTIMATE(TABLE PLAN ROWS=1)*/
             g_rec_title_treat_manag( --presc.g_id_presc_mci_desc_short,
                                     (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, presc.id_presc)
                                        FROM dual),
                                     --presc.id_presc_directions_desc_long,
                                     /*(SELECT pk_rt_med_pfh.get_presc_dir_str(i_lang         => i_lang,
                                                                          i_prof         => i_prof,
                                                                          i_id_presc     => presc.id_presc,
                                                                          i_flg_html     => pk_alert_constant.g_no,
                                                                          i_flg_complete => pk_alert_constant.g_yes)
                                     FROM dual)*/
                                     NULL, --TODO
                                     tm.desc_treatment_management,
                                     pk_date_utils.date_send_tsz(i_lang, tm.dt_creation_tstz, i_prof))
              FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang        => i_lang,
                                                                   i_prof        => i_prof,
                                                                   i_id_workflow => table_number_id(pk_rt_med_pfh.wf_institution,
                                                                                                    pk_rt_med_pfh.wf_iv),
                                                                   i_id_visit    => pk_episode.get_id_visit(i_epis))) presc
              JOIN (SELECT *
                      FROM TABLE(pk_rt_med_pfh.get_list_presc_plan(i_lang     => i_lang,
                                                                   i_prof     => i_prof,
                                                                   i_id_visit => pk_episode.get_id_visit(i_epis)))) plan
                ON plan.id_presc = presc.id_presc
              JOIN treatment_management tm
                ON tm.id_treatment = presc.id_presc
             WHERE ((plan.id_workflow = pk_rt_med_pfh.wf_take_iv AND
                   (plan.id_status IN (SELECT /*+OPT_ESTIMATE(TABLE T1 ROWS=1)*/
                                          column_value
                                           FROM TABLE(pk_rt_med_pfh.stg_take_iv_admin) t1))) OR
                   (plan.id_workflow = pk_rt_med_pfh.wf_take_institution AND
                   (plan.id_status IN
                   (SELECT /*+OPT_ESTIMATE(TABLE T2 ROWS=1)*/
                        column_value
                         FROM TABLE(pk_rt_med_pfh.stg_take_institution_admin) t2))))
               AND tm.flg_type = l_treat_type_drug
               AND (tm.dt_creation_tstz = (SELECT MAX(tm1.dt_creation_tstz)
                                             FROM treatment_management tm1
                                            WHERE tm1.id_treatment(+) = presc.id_presc
                                              AND tm1.flg_type(+) = l_treat_type_drug) OR tm.dt_creation_tstz IS NULL);
    
    BEGIN
    
        OPEN c_title_treat_manag;
    
        FETCH c_title_treat_manag BULK COLLECT
            INTO l_title_treat_manag;
    
        FOR i IN 1 .. l_title_treat_manag.count
        LOOP
            PIPE ROW(l_title_treat_manag(i));
        END LOOP;
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_title_treatement_manag;

    /**********************************************************************************************
    * Gets the directions of a prescription 
    *
    * @param i_lang                       Language ID
    * @param i_prof                       Professional's details
    * @param i_id_product                 id product
    * @param i_id_product_supplier        id product supplier
    * @param i_id_presc_dir               id prescription directions
    * @param i_flg_with_dt_begin          Begin date is included or not
    * @param i_flg_with_duration          Duration is included or not    
    * @param i_flg_with_executions        Executions are included or not    
    * @param i_flg_with_dt_end            End date is included or not
    *
    * @return                        Returns the directions prescription
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/02
    **********************************************************************************************/
    FUNCTION get_presc_resumed_dir_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_id_presc_dir        IN presc.id_presc_directions%TYPE,
        i_flg_with_dt_begin   IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_duration   IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_executions IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_dt_end     IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_resumed_dir_str(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_presc            => NULL,
                                                       i_id_product          => i_id_product,
                                                       i_id_product_supplier => i_id_product_supplier,
                                                       i_id_presc_dir        => i_id_presc_dir,
                                                       i_flg_with_dt_begin   => i_flg_with_dt_begin,
                                                       i_flg_with_duration   => i_flg_with_duration,
                                                       i_flg_with_executions => i_flg_with_executions,
                                                       i_flg_with_dt_end     => i_flg_with_dt_end);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PRESC_RESUMED_DIR_STR',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_presc_resumed_dir_str;

    /*******************************************************************************************************************************************
    * Gets the permission of product by financial (configured on ALERT_PRODUCT_TR.CONFIG_FINANCIAL_TYPE_MED_PER by default have permission)
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_product            id product
    * @param  I_ID_PATIENT    The ids to filter data
    *
    * @return                        returns W or B (warning or block)
    *                        
    * @author                        Mário Mineiro
    * @version                       2.6.3.8.4
    * @since                         2013/11/13
    *******************************************************************************************************************************************/
    /* FUNCTION get_financial_aprove
        (
            i_lang                IN language.id_language%TYPE,
            i_prof                IN profissional,
            i_id_patient          IN patient.id_patient%TYPE,
            i_id_product          IN table_varchar DEFAULT table_varchar(NULL),
            i_id_product_supplier IN table_varchar DEFAULT table_varchar(NULL)
            
        ) RETURN VARCHAR2 IS
        
        BEGIN
        
            IF (i_id_product.exists(1))
            THEN
                RETURN pk_rt_med_pfh.get_financial_aprove(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_id_patient          => i_id_patient,
                                                          i_id_product          => i_id_product,
                                                          i_id_product_supplier => i_id_product_supplier);
            ELSE
                RETURN NULL;
            END IF;
        
        EXCEPTION
            WHEN OTHERS THEN
                pk_alertlog.log_error(text            => g_error,
                                      object_name     => g_package_owner,
                                      sub_object_name => 'GET_FINANCIAL_APROVE');
                RAISE;
        END get_financial_aprove;
    */
    /**********************************************************************************************
    * Lucene Search
    *
    * @param i_lang                  Language ID
    * @param i_search                string to search
    * @param i_column_name           column name
    * @param i_id_description_type   i_id_description_type
    *
    * @return                        Returns the search results
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/02
    **********************************************************************************************/
    FUNCTION get_src_entity
    (
        i_lang                IN language.id_language%TYPE,
        i_search              IN VARCHAR2,
        i_column_name         IN VARCHAR2,
        i_id_description_type IN NUMBER
    ) RETURN table_t_search IS
        l_error t_error_out;
    BEGIN
        RETURN pk_rt_med_pfh.get_src_entity(i_lang                => i_lang,
                                            i_search              => i_search,
                                            i_column_name         => i_column_name,
                                            i_id_description_type => i_id_description_type);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SRC_ENTITY',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
        
    END get_src_entity;

    /**********************************************************************************************
    * Initialize params for filters search 
    *
    * @param i_context_ids            array with context ids
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/05
    **********************************************************************************************/
    PROCEDURE init_params_products
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
    BEGIN
    
        pk_rt_med_pfh.init_params_products(i_filter_name   => i_filter_name,
                                           i_custom_filter => i_custom_filter,
                                           i_context_ids   => i_context_ids,
                                           i_context_vals  => i_context_vals,
                                           i_name          => i_name,
                                           o_vc2           => o_vc2,
                                           o_num           => o_num,
                                           o_id            => o_id,
                                           o_tstz          => o_tstz);
    END init_params_products;

    /**********************************************************************************************
    * Gets the translation of a given entity
    *
    * @param i_lang                  Language ID
    * @param i_code_entity           code entity to translate
    * @param i_column_name           description type
    * @param i_id_description_type   i_id_description_type
    *
    * @return                        Returns the entity translation
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/06
    **********************************************************************************************/
    FUNCTION get_entity_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_code_entity         IN VARCHAR2,
        i_id_description_type IN NUMBER
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_entity_desc(i_lang                => i_lang,
                                             i_code_entity         => i_code_entity,
                                             i_id_description_type => i_id_description_type);
    
    END get_entity_desc;

    /********************************************************************************************
    * This function returns generic information about prescription administrations
    * intended to replace pk_api_drug.get_ongoing_task_med_int
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-09-06
    *
    ********************************************************************************************/
    FUNCTION get_list_ongoing_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN r_presc.id_patient%TYPE
    ) RETURN tf_tasks_list IS
    
        l_tasks_list tf_tasks_list := tf_tasks_list();
    
    BEGIN
        SELECT tr_tasks_list(tbl.id_presc,
                             tbl.prod_desc,
                             pk_translation.get_translation(i_lang,
                                                            'EPIS_TYPE.CODE_EPIS_TYPE.' ||
                                                            pk_episode.get_epis_type(i_lang, tbl.id_last_episode)),
                             pk_date_utils.date_char_tsz(i_lang, tbl.dt_adm, i_prof.institution, i_prof.software))
          BULK COLLECT
          INTO l_tasks_list
          FROM TABLE(pk_rt_med_pfh.get_list_ongoing_presc(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_patient => i_id_patient)) tbl;
    
        RETURN l_tasks_list;
    
    END get_list_ongoing_presc;

    FUNCTION create_presc_exterior
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN r_presc.id_patient%TYPE,
        i_id_episode            IN r_presc.id_epis_create%TYPE,
        i_id_product_serialized IN VARCHAR2,
        i_id_task_dependency    IN r_presc.id_task_dependency%TYPE,
        i_flg_req_origin_module IN r_presc.flg_req_origin_module%TYPE,
        i_id_presc_directions   IN r_presc.id_presc_directions%TYPE DEFAULT NULL,
        i_flg_confirm           IN VARCHAR2 DEFAULT 'Y',
        o_id_presc              OUT r_presc.id_presc%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'CREATE_PRESC_EXTERIOR';
    
    BEGIN
    
        g_error := 'PK_RT_MED_PFH.CREATE_PRESC_EXTERIOR';
        pk_rt_med_pfh.create_presc_exterior(i_lang                  => i_lang,
                                            i_prof                  => i_prof,
                                            i_id_patient            => i_id_patient,
                                            i_id_episode            => i_id_episode,
                                            i_id_product_serialized => i_id_product_serialized,
                                            i_id_task_dependency    => i_id_task_dependency,
                                            i_flg_req_origin_module => i_flg_req_origin_module,
                                            i_id_presc_directions   => i_id_presc_directions,
                                            i_flg_confirm           => i_flg_confirm,
                                            o_id_presc              => o_id_presc);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
        
            RETURN FALSE;
    END create_presc_exterior;

    FUNCTION create_presc_local
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN r_presc.id_patient%TYPE,
        i_id_episode            IN r_presc.id_epis_create%TYPE,
        i_id_product_serialized IN VARCHAR2,
        i_id_task_dependency    IN r_presc.id_task_dependency%TYPE,
        i_flg_req_origin_module IN r_presc.flg_req_origin_module%TYPE,
        i_id_presc_directions   IN r_presc.id_presc_directions%TYPE DEFAULT NULL,
        i_flg_confirm           IN VARCHAR2 DEFAULT 'Y',
        o_id_presc              OUT r_presc.id_presc%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'CREATE_PRESC_LOCAL';
    
    BEGIN
    
        g_error := 'PK_RT_MED_PFH.CREATE_PRESC_LOCAL';
        pk_rt_med_pfh.create_presc_local(i_lang                  => i_lang,
                                         i_prof                  => i_prof,
                                         i_id_patient            => i_id_patient,
                                         i_id_episode            => i_id_episode,
                                         i_id_product_serialized => i_id_product_serialized,
                                         i_id_task_dependency    => i_id_task_dependency,
                                         i_flg_req_origin_module => i_flg_req_origin_module,
                                         i_id_presc_directions   => i_id_presc_directions,
                                         i_flg_confirm           => i_flg_confirm,
                                         o_id_presc              => o_id_presc);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
        
            RETURN FALSE;
    END create_presc_local;

    /********************************************************************************************
    * This function descontinue or cancel the prescription depending on the current state
    *
    * @author  Pedro Teixeira
    * @since   2011-09-09
    *
    ********************************************************************************************/
    FUNCTION set_cancel_presc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_presc    IN r_presc.id_presc%TYPE,
        i_id_reason   IN r_presc.id_cancel_reason%TYPE,
        i_reason      IN VARCHAR2,
        i_notes       IN VARCHAR2,
        i_flg_confirm IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'SET_CANCEL_PRESC';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'pk_rt_med_pfh.set_cancel_presc';
        IF NOT pk_rt_med_pfh.set_cancel_presc(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_id_presc    => i_id_presc,
                                              i_id_reason   => i_id_reason,
                                              i_reason      => i_reason,
                                              i_notes       => i_notes,
                                              i_flg_confirm => i_flg_confirm,
                                              o_error       => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_db_object_name,
                                                     o_error);
    END set_cancel_presc;

    /********************************************************************************************
    * This function descontinue or cancel all the prescriptions of an episode
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_EPISODE    Episode whose prescription are to be cancelled
    *
    * @author  Pedro Teixeira
    * @since   2011-10-10
    *
    ********************************************************************************************/
    FUNCTION set_cancel_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN r_presc.id_epis_create%TYPE,
        i_notes      IN VARCHAR2 DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'SET_CANCEL_PRESC';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'pk_rt_med_pfh.set_cancel_presc';
        IF NOT
            pk_rt_med_pfh.set_cancel_presc(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_id_episode => i_id_episode,
                                           i_notes      => i_notes,
                                           i_workflows  => table_number(pk_rt_med_pfh.wf_iv, pk_rt_med_pfh.wf_institution),
                                           o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_db_object_name,
                                                     o_error);
    END set_cancel_presc;

    /********************************************************************************************
    * This function suspends the prescription
    *
    * @author  Pedro Teixeira
    * @since   2011-09-12
    *
    ********************************************************************************************/
    FUNCTION set_suspend_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN r_presc.id_presc%TYPE,
        i_dt_begin_suspend IN VARCHAR2,
        i_dt_end_suspend   IN VARCHAR2,
        i_id_reason        IN r_presc.id_cancel_reason%TYPE,
        i_reason           IN VARCHAR2,
        i_notes            IN VARCHAR2,
        i_flg_confirm      IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'SET_SUSPEND_PRESC';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'pk_rt_med_pfh.set_suspend_presc';
        IF NOT pk_rt_med_pfh.set_suspend_presc(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_id_presc         => i_id_presc,
                                               i_dt_begin_suspend => i_dt_begin_suspend,
                                               i_dt_end_suspend   => i_dt_end_suspend,
                                               i_id_reason        => i_id_reason,
                                               i_reason           => i_reason,
                                               i_notes            => i_notes,
                                               i_flg_confirm      => i_flg_confirm,
                                               o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_db_object_name,
                                                     o_error);
    END set_suspend_presc;

    /********************************************************************************************
    * This function suspends the administration
    *
    * @author  Pedro Teixeira
    * @since   2011-10-25
    *
    ********************************************************************************************/
    FUNCTION set_suspend_adm
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_presc      IN r_presc.id_presc%TYPE,
        i_id_presc_plan IN r_presc_plan.id_presc_plan%TYPE,
        i_id_reason     IN r_presc.id_cancel_reason%TYPE,
        i_reason        IN VARCHAR2,
        i_notes         IN VARCHAR2,
        i_dt_suspend    IN VARCHAR2,
        i_flg_confirm   IN VARCHAR2 DEFAULT 'Y',
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'SET_SUSPEND_ADM';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'pk_rt_med_pfh.set_suspend_adm';
        IF NOT pk_rt_med_pfh.set_suspend_adm(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_id_presc      => i_id_presc,
                                             i_id_presc_plan => i_id_presc_plan,
                                             i_id_reason     => i_id_reason,
                                             i_reason        => i_reason,
                                             i_notes         => i_notes,
                                             i_dt_suspend    => i_dt_suspend,
                                             i_flg_confirm   => i_flg_confirm,
                                             o_error         => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_db_object_name,
                                                     o_error);
    END set_suspend_adm;

    /********************************************************************************************
    * This function resumes the prescription
    *
    * @author  Pedro Teixeira
    * @since   2011-09-12
    *
    ********************************************************************************************/
    FUNCTION set_resume_presc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc        IN r_presc.id_presc%TYPE,
        i_dt_begin_resume IN VARCHAR2,
        i_id_reason       IN r_presc.id_cancel_reason%TYPE,
        i_reason          IN VARCHAR2,
        i_notes           IN VARCHAR2,
        i_flg_confirm     IN VARCHAR2 DEFAULT 'Y',
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'SET_RESUME_PRESC';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'pk_rt_med_pfh.set_resume_presc';
        IF NOT pk_rt_med_pfh.set_resume_presc(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_id_presc        => i_id_presc,
                                              i_dt_begin_resume => i_dt_begin_resume,
                                              i_id_reason       => i_id_reason,
                                              i_reason          => i_reason,
                                              i_notes           => i_notes,
                                              i_flg_confirm     => i_flg_confirm,
                                              o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_db_object_name,
                                                     o_error);
    END set_resume_presc;

    /********************************************************************************************
    * This function resumes the administration
    *
    * @author  Pedro Teixeira
    * @since   2011-10-25
    *
    ********************************************************************************************/
    FUNCTION set_resume_adm
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_presc      IN r_presc.id_presc%TYPE,
        i_id_presc_plan IN r_presc_plan.id_presc_plan%TYPE,
        i_flg_confirm   IN VARCHAR2 DEFAULT 'Y',
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'SET_RESUME_ADM';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'pk_rt_med_pfh.set_resume_adm';
        IF NOT pk_rt_med_pfh.set_resume_adm(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_id_presc      => i_id_presc,
                                            i_id_presc_plan => i_id_presc_plan,
                                            i_flg_confirm   => i_flg_confirm,
                                            o_error         => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_db_object_name,
                                                     o_error);
    END set_resume_adm;

    /********************************************************************************************
    * This function resumes the administration
    *
    * @author  Pedro Teixeira
    * @since   2014-05-23
    *
    ********************************************************************************************/
    FUNCTION set_resume_adm
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN r_presc.id_presc%TYPE,
        i_id_presc_plan    IN r_presc_plan.id_presc_plan%TYPE,
        i_id_resume_reason IN r_presc.id_cancel_reason%TYPE,
        i_resume_reason    IN VARCHAR2,
        i_notes_resume     IN VARCHAR2,
        i_dt_resume        IN VARCHAR2,
        i_flg_confirm      IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'SET_RESUME_ADM';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'pk_rt_med_pfh.set_resume_adm';
        IF NOT pk_rt_med_pfh.set_resume_adm(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            i_id_presc         => i_id_presc,
                                            i_id_presc_plan    => i_id_presc_plan,
                                            i_id_resume_reason => i_id_resume_reason,
                                            i_resume_reason    => i_resume_reason,
                                            i_notes_resume     => i_notes_resume,
                                            i_dt_resume        => i_dt_resume,
                                            i_flg_confirm      => i_flg_confirm,
                                            o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_db_object_name,
                                                     o_error);
    END set_resume_adm;

    /********************************************************************************************
    * This function cancel an administration
    *
    * @author  Pedro Teixeira
    * @since   2011-09-12
    *
    ********************************************************************************************/
    FUNCTION set_cancel_adm
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_presc      IN r_presc.id_presc%TYPE,
        i_id_presc_plan IN r_presc_plan.id_presc_plan%TYPE,
        i_id_reason     IN r_presc.id_cancel_reason%TYPE,
        i_reason        IN VARCHAR2,
        i_notes         IN VARCHAR2,
        i_flg_confirm   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'SET_CANCEL_ADM';
    BEGIN
        g_error := 'pk_rt_med_pfh.suspend_presc';
        IF NOT pk_rt_med_pfh.set_cancel_adm(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_id_presc      => i_id_presc,
                                            i_id_presc_plan => i_id_presc_plan,
                                            i_id_reason     => i_id_reason,
                                            i_reason        => i_reason,
                                            i_notes         => i_notes,
                                            i_flg_confirm   => i_flg_confirm,
                                            o_error         => o_error)
        THEN
            RETURN TRUE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_db_object_name,
                                                     o_error);
    END set_cancel_adm;

    /********************************************************************************************
    * This function is supposed to reactivate the prescription, but no workflow is defined
    * to reactivate a discontinued or canceled presc, so, instead it return the presc description
    * -- created to replace: PK_API_DRUG.REACTIVATE_TASK_MED_INT
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_PRESC      The prescription Id
    *
    * @author  Pedro Teixeira
    * @since   2011-09-08
    *
    ********************************************************************************************/
    FUNCTION reactivate_presc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_presc  IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        o_msg_error OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'REACTIVATE_PRESC';
    BEGIN
        g_error := 'pk_rt_med_pfh.reactivate_presc';
        IF NOT pk_rt_med_pfh.reactivate_presc(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_id_presc  => i_id_presc,
                                              o_msg_error => o_msg_error,
                                              o_error     => o_error)
        THEN
            RETURN TRUE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_db_object_name,
                                                     o_error);
    END reactivate_presc;

    /********************************************************************************************
    * pk_api_med_out.get_prod_desc_by_presc  
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        PROFISSIONAL
    * @param    I_ID_PRESC                      IN        NUMBER(24)
    *
    * @return   VARCHAR2
    *
    * @author   Rui Marante
    * @version    
    * @since    2011-08-24
    *
    * @notes    
    *
    * @ext_refs   --
    *
    * @status   100% - DONE!
    *
    ********************************************************************************************/
    FUNCTION get_prod_desc_by_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2 IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'GET_PROD_DESC_BY_PRESC';
    BEGIN
        g_error := 'pk_api_pfh_in.get_prod_desc_by_presc';
        RETURN pk_rt_med_pfh.get_prod_desc_by_presc(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => g_error, object_name => g_package_owner, sub_object_name => l_db_object_name);
        
            RAISE;
    END get_prod_desc_by_presc;

    /**********************************************************************************************
    * This function return the id presc type rel for a specific pick list
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Array with the professional information 
    * @param i_id_pick_list          id pick list
    * @param i_id_prod_med_type      id product type
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/13
    **********************************************************************************************/
    FUNCTION get_type_rel_pick_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pick_list     IN NUMBER,
        i_id_prod_med_type IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        g_error := 'call pk_api_med_out.get_type_rel_pick_list';
    
        RETURN pk_rt_med_pfh.get_type_rel_pick_list(i_lang, i_prof, i_id_pick_list, i_id_prod_med_type);
    END get_type_rel_pick_list;

    /**********************************************************************************************
    * This function return the directions of a specific product
    *
    * @param i_lang                     Language ID
    * @param i_prof                     Array with the professional information 
    * @param i_id_product                 id product
    * @param i_id_product_supplier      id product supplier
    * @param i_id_pick_list             ID pick list
    * @param i_flg_with_dt_begin          Begin date is included or not
    * @param i_flg_with_duration          Duration is included or not    
    * @param i_flg_with_executions        Executions are included or not    
    * @param i_flg_with_dt_end            End date is included or not
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/13
    **********************************************************************************************/

    FUNCTION get_presc_directions_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_id_pick_list        IN NUMBER DEFAULT 2,
        i_flg_with_dt_begin   IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_duration   IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_executions IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_dt_end     IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'call   pk_api_med_out.get_presc_directions_str';
        RETURN pk_rt_med_pfh.get_presc_directions_str(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_product          => i_id_product,
                                                      i_id_product_supplier => i_id_product_supplier,
                                                      i_id_pick_list        => i_id_pick_list,
                                                      i_flg_with_dt_begin   => i_flg_with_dt_begin,
                                                      i_flg_with_duration   => i_flg_with_duration,
                                                      i_flg_with_executions => i_flg_with_executions,
                                                      i_flg_with_dt_end     => i_flg_with_dt_end);
    
    END get_presc_directions_str;

    /********************************************************************************************
    * get_patients_for_rowids  
    *
    * @param    I_ROWIDS                        IN        TABLE_VARCHAR
    * @param    I_SOURCE_TABLE_NAME             IN        VARCHAR2
    *
    * @return   TABLE_NUMBER
    *
    * @author   Rui Marante
    * @version    
    * @since    2011-08-23
    *
    * @notes    
    *
    * @ext_refs   --
    *
    * @status   100% - DONE!
    *
    ********************************************************************************************/
    FUNCTION get_patients_for_rowids
    (
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2
    ) RETURN table_number IS
    BEGIN
        g_error := 'pk_rt_med_pfh.get_patients_for_rowids';
        RETURN pk_rt_med_pfh.get_patients_for_rowids(i_rowids => i_rowids, i_source_table_name => i_source_table_name);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END get_patients_for_rowids;

    /********************************************************************************************
    * get_prescs_for_patient  
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        PROFISSIONAL
    * @param    I_ID_PATIENT                    IN        NUMBER(24)
    *
    * @return   TABLE_TABLE_VARCHAR
    *
    * @author   Rui Marante
    * @version    
    * @since    2011-08-23
    *
    * @notes    
    *
    * @ext_refs   --
    *
    * @status   100% - DONE!
    *
    ********************************************************************************************/
    FUNCTION get_prescs_for_patient
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN table_table_varchar IS
    BEGIN
        g_error := 'pk_api_med_out.get_prescs_for_patient';
        RETURN pk_rt_med_pfh.get_prescs_for_patient(i_lang => i_lang, i_prof => i_prof, i_id_patient => i_id_patient);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END get_prescs_for_patient;

    /**********************************************************************************************
    * This function return the id directions of a specific product
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Array with the professional information 
    * @param i_id_product            id product
    * @param i_id_product_supplier   id product supplier
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/13
    **********************************************************************************************/
    FUNCTION get_id_std_presc_directions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_id_pick_list        IN NUMBER DEFAULT 0
    ) RETURN NUMBER IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_id_std_presc_directions(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_id_product          => i_id_product,
                                                         i_id_product_supplier => i_id_product_supplier,
                                                         i_id_pick_list        => i_id_pick_list);
    
    END get_id_std_presc_directions;

    /*********************************************************************************************
    * get medication directions string for any given prescription detail
    *
    * @param i_lang                 language id
    * @param i_prof                 professional structure
    * @param i_id_presc             prescription id
    * @param i_flg_complete         controls if descriptives show all information, or only 
    *                               significative instructions (without dates) 
    *
    * @return varchar2              directions string based on the parameterized presc_dir 
    *                               string
    *
    * @author                       Elisabete Bugalho
    * @version                      2.6.1.2
    * @since                        2011/09/19
    **********************************************************************************************/
    FUNCTION get_presc_directions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_presc     IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        i_flg_html     IN VARCHAR2 DEFAULT pk_rt_core_all.g_no,
        i_flg_complete IN VARCHAR2 DEFAULT pk_rt_core_all.g_yes
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_directions(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_id_presc     => i_id_presc,
                                                  i_flg_html     => i_flg_html,
                                                  i_flg_complete => i_flg_complete);
    END get_presc_directions;

    /********************************************************************************************
    * This function gets route rank
    *
    * @param i_lang                  id language
    * @param i_prof                  Array with the professional information 
    * @param i_id_route              id route
    * @param i_id_route_supplier     id route supplier
    *
    * @return                        route rank
    * 
    * @author                Elisabete Bugalho
    * @version               2.6.1.2
    * @since                 2011/09/19
    ********************************************************************************************/
    FUNCTION get_route_rank
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_route          IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE
    ) RETURN NUMBER IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_route_rank(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_route          => i_id_route,
                                            i_id_route_supplier => i_id_route_supplier);
    
    END get_route_rank;

    /********************************************************************************************
    * This function returns the last execution date of a prescription
    *
    * @param i_lang          id language
    * @param i_prof          array with the professional information 
    * @param i_id_presc      id prescription
    *
    * @return                last execution date
    * 
    * @author                Elisabete Bugalho
    * @version               2.6.1.2
    * @since                 2011/09/19
    ********************************************************************************************/
    FUNCTION get_last_adm_start_date
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    BEGIN
        RETURN pk_rt_med_pfh.get_last_adm_start_date(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END get_last_adm_start_date;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_last_presc_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_episode IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    BEGIN
        RETURN pk_rt_med_pfh.get_last_presc_date(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_id_patient => i_patient,
                                                 i_id_episode => i_id_episode);
    
    END get_last_presc_date;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_prescriber
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_episode IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN NUMBER IS
        l_id_prof professional.id_professional%TYPE;
    BEGIN
        SELECT t.id_prof_create
          INTO l_id_prof
          FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               i_id_workflow => table_number_id(pk_rt_med_pfh.wf_institution,
                                                                                                pk_rt_med_pfh.wf_iv),
                                                               i_id_patient  => i_patient)) t
         WHERE t.id_last_episode = i_id_episode
           AND rownum = 1
         ORDER BY t.dt_create DESC;
    
        RETURN l_id_prof;
    
    END get_prescriber;

    /********************************************************************************************
    * This function returns the id of the last professional that executed 
    *
    * @param i_lang          id language
    * @param i_prof          array with the professional information 
    * @param i_id_presc      id prescription
    *
    * @return                professional id
    * 
    * @author                Elisabete Bugalho
    * @version               2.6.1.2
    * @since                 2011/09/20
    ********************************************************************************************/

    FUNCTION get_last_adm_prof
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN NUMBER IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_last_adm_prof(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END get_last_adm_prof;

    /********************************************************************************************
    * This function gets route color
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_route              id route
    * @param i_id_route_supplier     id route supplier
    *
    * @return                        route color
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/20
    ********************************************************************************************/
    FUNCTION get_route_color
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_route          IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
        g_error := 'call pk_api_product.get_route_color';
        RETURN pk_rt_med_pfh.get_route_color(i_lang              => i_lang,
                                             i_prof              => i_prof,
                                             i_id_route          => i_id_route,
                                             i_id_route_supplier => i_id_route_supplier);
    END get_route_color;

    /*********************************************************************************************
    * This function returns product Route description
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_route              id route
    * @param i_id_route_supplier     id route supplier
    * @value i_id_description_type   {*} 1 - normal {*} 2 - abbreviation
    *
    * @return                        route color
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/20
    *********************************************************************************************/
    FUNCTION get_route_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_route            IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier   IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE,
        i_id_route_status     IN pk_rt_med_pfh.r_presc_dir.id_route_status%TYPE,
        i_id_description_type IN NUMBER DEFAULT pk_rt_med_pfh.g_entity_description_type_def
    ) RETURN VARCHAR2 IS
    
    BEGIN
        g_error := 'call pk_api_product.get_route_desc';
        RETURN pk_rt_med_pfh.get_route_desc(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_route            => i_id_route,
                                            i_id_route_supplier   => i_id_route_supplier,
                                            i_id_route_status     => i_id_route_status,
                                            i_id_description_type => i_id_description_type);
    
    END get_route_desc;

    /**********************************************************************************************
    * Initialize params for filters search (Administrations and Tasks)
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/20
    **********************************************************************************************/
    PROCEDURE init_params_adm_task
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
    BEGIN
    
        g_error := 'call pk_rt_med_pfh.init_params_adm_task';
        pk_rt_med_pfh.init_params_adm_task(i_filter_name   => i_filter_name,
                                           i_custom_filter => i_custom_filter,
                                           i_context_ids   => i_context_ids,
                                           i_context_vals  => i_context_vals,
                                           i_name          => i_name,
                                           o_vc2           => o_vc2,
                                           o_num           => o_num,
                                           o_id            => o_id,
                                           o_tstz          => o_tstz);
    
    END init_params_adm_task;

    /*********************************************************************************************
    * This function returns the code description for a prescription
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              id prescription
    *
    * @return                        array with code_
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/22
    *********************************************************************************************/
    FUNCTION get_code_prod_by_presc
    (
        i_lang     language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN table_varchar IS
    
    BEGIN
        g_error := 'call pk_presc_core.get_code_prod_by_presc';
        RETURN pk_rt_med_pfh.get_code_prod_by_presc(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END get_code_prod_by_presc;

    /**********************************************************************************************
    * This function returns a array with the active states for a prescription
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/23
    **********************************************************************************************/
    FUNCTION get_wfg_presc_active RETURN table_number_id IS
    
    BEGIN
        RETURN g_wfg_presc_med_active;
    END get_wfg_presc_active;

    /**********************************************************************************************
    * This function returns a array with the inactive states for a prescription
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/23
    **********************************************************************************************/
    FUNCTION get_wfg_presc_inactive RETURN table_number_id IS
    
    BEGIN
        RETURN g_wfg_presc_med_inactive;
    END get_wfg_presc_inactive;

    /**********************************************************************************************
    * This function returns a array with the temporary states for a prescription
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/23
    **********************************************************************************************/
    FUNCTION get_tmp_presc_temp RETURN table_number IS
    
    BEGIN
        RETURN g_tmp_presc_states;
    END get_tmp_presc_temp;

    /********************************************************************************************
    * This procedure updates viewer_ea precriptions
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-09-26
    *
    ********************************************************************************************/
    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'UPD_VIEWER_EHR_EA';
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
        l_prod_desc    table_varchar := table_varchar();
        l_counter      table_number := table_number();
        l_dt_begin     table_timestamp_tstz := table_timestamp_tstz();
        l_id_patient   table_number := table_number();
        c_viewer_presc pk_types.cursor_type;
    BEGIN
        -- 
        g_error := 'CALL pk_rt_med_pfh.get_viewer_ehr_presc';
        IF NOT pk_rt_med_pfh.get_viewer_ehr_presc(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  o_viewer_presc => c_viewer_presc,
                                                  o_error        => l_error_out)
        THEN
            RAISE l_exception;
        END IF;
    
        ----------------------------------------------------------
        -- fetch c_viewer_presc
        BEGIN
            g_error := 'FETCH c_doc_reg';
            FETCH c_viewer_presc BULK COLLECT
                INTO --
                     l_prod_desc,
                     l_counter,
                     l_dt_begin,
                     l_id_patient;
            CLOSE c_viewer_presc;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE l_exception;
        END;
    
        g_error := 'update viewer_ehr_ea';
        FORALL i IN 1 .. l_id_patient.count
            UPDATE viewer_ehr_ea vee
               SET vee.desc_med = l_prod_desc(i), vee.num_med = l_counter(i), vee.dt_med = l_dt_begin(i)
             WHERE vee.id_patient = l_id_patient(i) log errors INTO err$_viewer_ehr_ea(to_char(SYSDATE)) reject LIMIT
             unlimited;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            RAISE;
    END upd_viewer_ehr_ea;

    /********************************************************************************************
    * GET_PRESC_NUMBER_SEQ
    *
    * @param i_lang                language id
    * @param i_prof                professional id (INTERFACE PROFESSIOAL USED FOR MIGRATION)
    * @param i_id_institution      Institution identifier
    * @param i_flg_type            Flg_type
    * @param i_id_clinical_service Clinical service identifier
    * @param o_sequence_name       Sequence name
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Maia
    * @version                     2.6.1.1
    * @since                       2011/04/19
    * @dependents                  PK_REF_ORIG_PHY.GET_REFERRAL_NUMBER
    **********************************************************************************************/
    FUNCTION get_presc_number_seq
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_institution      IN prescription_number_seq.id_institution%TYPE,
        i_flg_type            IN prescription_number_seq.flg_type%TYPE,
        i_id_clinical_service IN prescription_number_seq.id_clinical_service%TYPE,
        o_sequence_name       OUT prescription_number_seq.sequence_name%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        BEGIN
            SELECT pns.sequence_name
              INTO o_sequence_name
              FROM prescription_number_seq pns
             WHERE pns.id_institution = i_id_institution
               AND pns.flg_type = i_flg_type
               AND nvl(pns.id_clinical_service, nvl(i_id_clinical_service, 0)) = nvl(i_id_clinical_service, 0);
        EXCEPTION
            WHEN no_data_found THEN
                SELECT 'SEQ_REFERRAL_NUMBER_0083'
                  INTO o_sequence_name
                  FROM dual;
        END;
    
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
                                              'GET_PRESC_NUMBER_SEQ',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_presc_number_seq;

    /**************************************************************************
    * This function will return all chronic prescription for a specific       *
    * patient \ visit                                                         *
    *                                                                         *
    * @param i_lang               The ID of the user language                 *
    * @param i_prof               The profissional array                      *
    * @param i_patient            Patient identifier                          *
    * @param i_visit              Visit identifier                            *
    *                                                                         *
    * @param o_info               Cursor with information                     *
    * @param o_error              Error message                               *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/09/28                                                     *
    **************************************************************************/
    FUNCTION get_active_chronic_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN r_presc.id_patient%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'call pk_rt_med_pfh.get_active_chronic_presc';
        RETURN pk_rt_med_pfh.get_active_chronic_presc(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_patient => i_id_patient,
                                                      i_id_visit   => i_id_visit,
                                                      o_info       => o_info,
                                                      o_error      => o_error);
    
    END get_active_chronic_presc;

    /*****************************************************************************************
    * This function returns product description
    *
    * @param i_lang                                                        Input - id language
    * @param i_prof                                                        Input - i_prof
    * @param i_id_product                                                  Input - product id
    * @param i_id_presc                                                    Input - prescription id
    *
    * @return                product description
    * 
    * @raises                
    *
    * @author                Pedro Quinteiro
    * @version               V.2.6.1
    * @since                 2011/09/07
    ********************************************************************************************/
    FUNCTION get_product_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_product IN VARCHAR2,
        i_id_presc   IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_rt_med_pfh.get_product_desc(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_id_product => i_id_product,
                                              i_id_presc   => i_id_presc);
    
    END;

    /********************************************************************************************
    * This functions returns prescription last change date
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-09-28
    *
    ********************************************************************************************/
    FUNCTION get_presc_change_date
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_error t_error_out;
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_CHANGE_DATE';
    
    BEGIN
    
        RETURN pk_rt_med_pfh.get_presc_change_date(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error);
            RAISE;
    END get_presc_change_date;

    /********************************************************************************************
    * This functions returns 'Y' if the prescription is in an active state, otherwise 'N'
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-09-29
    *
    ********************************************************************************************/
    FUNCTION is_active_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_rt_med_pfh.is_active_presc(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END is_active_presc;

    /********************************************************************************************
    * This functions returns 'Y' if the prescription has administrations
    *
    *
    * @author  Pedro Teixeira
    * @since   2012-07-11
    *
    ********************************************************************************************/
    FUNCTION has_administrations
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_rt_med_pfh.has_administrations(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END has_administrations;

    /********************************************************************************************
    * This functions returns 'Y' if the prescription is canceled, otherwise 'N'
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-10-28
    *
    ********************************************************************************************/
    FUNCTION is_canceled_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_rt_med_pfh.is_canceled_presc(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END is_canceled_presc;

    /**********************************************************************************************
    * Gets the product description
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_product            id product
    * @param i_id_product_supplier   id product supplier
    * @param i_id_presc              prescription id
    *
    * @return                        Returns the product description
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/29
    **********************************************************************************************/
    FUNCTION get_product_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN pk_rt_med_pfh.r_product.id_product%TYPE,
        i_id_product_supplier IN pk_rt_med_pfh.r_product.id_product_supplier%TYPE,
        i_id_presc            IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
    BEGIN
        g_error := 'call pk_rt_med_pfh.get_product_desc';
        RETURN pk_rt_med_pfh.get_product_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_product          => i_id_product,
                                              i_id_product_supplier => i_id_product_supplier,
                                              i_id_presc            => i_id_presc);
    
    END get_product_desc;

    /**************************************************************************
    * This function will return all reported prescription for a specific      *
    * patient                                                                 *
    *                                                                         *
    * @param i_lang               The ID of the user language                 *
    * @param i_prof               The profissional array                      *
    * @param i_patient            Patient identifier                          *
    *                                                                         *
    * @param o_info               Cursor with information                     *
    * @param o_error              Error message                               *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/09/28                                                     *
    **************************************************************************/
    FUNCTION get_list_report_active_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN r_presc.id_patient%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'get_list_report_active_presc';
    BEGIN
        OPEN o_info FOR
            SELECT id_presc id_value,
                   (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, id_presc)
                      FROM dual) description,
                   (SELECT pk_rt_med_pfh.get_presc_status_icon(i_lang, i_prof, p.id_presc)
                      FROM dual) desc_status
              FROM TABLE(get_list_prescription_basic(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_id_workflow => table_number_id(pk_rt_med_pfh.wf_report),
                                                     i_id_patient  => i_id_patient,
                                                     i_id_visit    => i_id_visit)) p
             WHERE id_workflow = pk_rt_med_pfh.wf_report
               AND id_status IN (SELECT column_value
                                   FROM TABLE(table_number(pk_rt_med_pfh.st_active,
                                                           pk_rt_med_pfh.st_unknown,
                                                           pk_rt_med_pfh.st_active_gen_auto)));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_list_report_active_presc;

    /**********************************************************************************************
    * Gets the directions of a prescription 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_product            id product
    * @param i_id_product_supplier   id product supplier
    * @param i_id_presc_dir          id prescription directions
    *
    * @return                        Returns the directions prescription
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/29
    **********************************************************************************************/
    FUNCTION get_presc_dir_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN pk_rt_med_pfh.r_product.id_product%TYPE,
        i_id_product_supplier IN pk_rt_med_pfh.r_product.id_product_supplier%TYPE,
        i_id_presc_dir        IN pk_rt_med_pfh.r_presc.id_presc_directions%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_dir_str(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_presc            => NULL,
                                               i_id_product          => i_id_product,
                                               i_id_product_supplier => i_id_product_supplier,
                                               i_id_presc_dir        => i_id_presc_dir);
    END get_presc_dir_str;

    /*********************************************************************************************
    *  This function will return the icon that distinguishes the different types of medication / workflows for a given id_presc
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              id prescription
    *
    * @return                        type of presc icon
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/29
    *********************************************************************************************/

    FUNCTION get_presc_type_icon
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        g_error := 'pk_rt_med_pfh.get_presc_type_icon';
        RETURN pk_rt_med_pfh.get_presc_type_icon(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END get_presc_type_icon;

    /*********************************************************************************************
    *  This function will return the prescription notes
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              id prescription
    *
    * @return                        prescription notes
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/30
    *********************************************************************************************/
    FUNCTION get_presc_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        g_error := 'pk_api_med_out.get_presc_notes';
        RETURN pk_rt_med_pfh.get_presc_notes(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END get_presc_notes;

    /**********************************************************************************************
    * This function returns the status name of a icon
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_workflow           id workflow
    * @param i_id_status             id status 
    *
    * @return                        Returns the icon name
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/30
    **********************************************************************************************/
    FUNCTION get_icon_wf_status_name
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_workflow IN NUMBER,
        i_id_status   IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_icon_wf_status_name(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_id_workflow => i_id_workflow,
                                                     i_id_status   => i_id_status);
    
    END get_icon_wf_status_name;

    /**********************************************************************************************
    * This function returns the icon back color
    *
    * @param i_id_workflow           id workflow
    * @param i_id_status             id status 
    *
    * @return                        Returns the icon back color
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/30
    **********************************************************************************************/
    FUNCTION get_icon_bg_color
    (
        i_id_workflow IN NUMBER,
        i_id_status   IN NUMBER
    ) RETURN VARCHAR2 IS
    
    BEGIN
        g_error := 'call pk_api_metadata_utils.get_icon_bg_color';
        RETURN pk_rt_med_pfh.get_icon_bg_color(i_id_workflow => i_id_workflow, i_id_status => i_id_status);
    
    END get_icon_bg_color;

    /**********************************************************************************************
    * This function returns the icon color
    *
    * @param i_id_workflow           id workflow
    * @param i_id_status             id status 
    *
    * @Returns                       icon color
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/30
    **********************************************************************************************/
    FUNCTION get_icon_color
    (
        i_id_workflow IN NUMBER,
        i_id_status   IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
    
        g_error := 'call  pk_api_metadata_utils.get_icon_color';
        RETURN pk_rt_med_pfh.get_icon_color(i_id_workflow => i_id_workflow, i_id_status => i_id_status);
    
    END get_icon_color;

    /**********************************************************************************************
    * Initialize params for filters search (Ambulatory Medication (Pending Prescriptions))
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/09/30
    **********************************************************************************************/
    PROCEDURE init_params_amb_pend
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
    BEGIN
    
        pk_rt_med_pfh.init_params_amb_pend(i_filter_name   => i_filter_name,
                                           i_custom_filter => i_custom_filter,
                                           i_context_ids   => i_context_ids,
                                           i_context_vals  => i_context_vals,
                                           i_name          => i_name,
                                           o_vc2           => o_vc2,
                                           o_num           => o_num,
                                           o_id            => o_id,
                                           o_tstz          => o_tstz);
    
    END init_params_amb_pend;

    /********************************************************************************************
    * Gets the task_list_by_patient for PDMS 
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-09-29
    *
    ********************************************************************************************/
    FUNCTION get_task_list_by_patient
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN NUMBER,
        i_first_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_last_date  IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_presc      OUT pk_types.cursor_type,
        o_tasks      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_TASK_LIST_BY_PATIENT';
    BEGIN
    
        RETURN pk_rt_med_pfh.get_task_list_by_patient(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_patient => i_id_patient,
                                                      i_first_date => i_first_date,
                                                      i_last_date  => i_last_date,
                                                      o_presc      => o_presc,
                                                      o_tasks      => o_tasks,
                                                      o_error      => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_presc);
            pk_types.open_cursor_if_closed(o_tasks);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END get_task_list_by_patient;

    /********************************************************************************************
    * Gets the presc_plan task actions 
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-09-30
    *
    ********************************************************************************************/
    FUNCTION get_task_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_TASK_ACTIONS';
    BEGIN
        RETURN pk_rt_med_pfh.get_task_actions(i_lang    => i_lang,
                                              i_prof    => i_prof,
                                              o_actions => o_actions,
                                              o_error   => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
    END get_task_actions;

    /********************************************************************************************
    * Function for get all action for a prescription or administration
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)    
    * @param   i_id_patient                Patient Identifier
    * @param   i_id_episode                Episode Identifier
    * @param   i_id_presc                  Prescription Identifier
    * @param   i_id_presc_plan             Prescription Plan Identifier 
    * @param   i_id_print_group            Print Group Identifier
    * @param   i_flg_action_type           Flag action type
    * @param   o_action                    All Actions and availability
    * @param   o_error                     Error information
    *
    * @RETURN                             true or false if the function was executed correctly
    *
    * @author                             Miguel Gomes (This function should be review)
    * @version                            2.6.4.3
    * @since                              10-11-2014
    *
    **********************************************************************************************/
    FUNCTION get_med_tab_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN presc.id_patient%TYPE,
        i_id_episode           IN presc.id_epis_create%TYPE,
        i_id_presc             IN table_number,
        i_id_presc_plan        IN table_number,
        i_id_presc_plan_task   IN table_number DEFAULT NULL,
        i_id_print_group       IN table_number,
        i_id_editor_tab        IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        i_flg_ignore_inactive  IN VARCHAR2,
        i_flg_action_type      IN VARCHAR2,
        o_action               OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'get_med_tab_actions';
    BEGIN
        RETURN pk_rt_med_pfh.get_med_tab_actions(i_lang                 => i_lang,
                                                 i_prof                 => i_prof,
                                                 i_id_patient           => i_id_patient,
                                                 i_id_episode           => i_id_episode,
                                                 i_id_presc             => i_id_presc,
                                                 i_id_presc_plan        => i_id_presc_plan,
                                                 i_id_presc_plan_task   => i_id_presc_plan_task,
                                                 i_id_print_group       => i_id_print_group,
                                                 i_id_editor_tab        => i_id_editor_tab,
                                                 i_class_origin_context => i_class_origin_context,
                                                 i_flg_ignore_inactive  => i_flg_ignore_inactive,
                                                 i_flg_action_type      => i_flg_action_type,
                                                 o_action               => o_action,
                                                 o_error                => o_error);
    
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
    END get_med_tab_actions;

    /********************************************************************************************
    * Gets the prescription actions 
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-10-20
    *
    ********************************************************************************************/
    FUNCTION get_presc_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_ACTIONS';
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_actions(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               o_actions => o_actions,
                                               o_error   => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
    END get_presc_actions;

    /**********************************************************************************************
    * This function returns a array with the status for printed and Faxed RX
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/03
    **********************************************************************************************/
    FUNCTION get_pg_print_fax RETURN table_number IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_pg_print_fax;
    END get_pg_print_fax;

    /**********************************************************************************************
    * This function returns a array with the status for printed  RX
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/03
    **********************************************************************************************/
    FUNCTION get_pg_printed RETURN table_number IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_pg_printed;
    END get_pg_printed;

    /**********************************************************************************************
    * This function returns a array with the status for faxed  RX
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/03
    **********************************************************************************************/
    FUNCTION get_pg_faxed RETURN table_number IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_pg_faxed;
    END get_pg_faxed;

    /**********************************************************************************************
    * Initialize params for filters search (Ambulatory Medication (Printed and Faxed RX))
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/03
    **********************************************************************************************/
    PROCEDURE init_params_amb_print_fax
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
    BEGIN
    
        g_error := 'call pk_rt_med_pfh.init_params_amb_print_fax';
        pk_rt_med_pfh.init_params_amb_print_fax(i_filter_name   => i_filter_name,
                                                i_custom_filter => i_custom_filter,
                                                i_context_ids   => i_context_ids,
                                                i_context_vals  => i_context_vals,
                                                i_name          => i_name,
                                                o_vc2           => o_vc2,
                                                o_num           => o_num,
                                                o_id            => o_id,
                                                o_tstz          => o_tstz);
    
    END init_params_amb_print_fax;

    /**********************************************************************************************
    * Initialize params for filters search (Prescribed Medication )
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/06
    **********************************************************************************************/
    PROCEDURE init_params_prod_med
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
    BEGIN
    
        g_error := 'call pk_rt_med_pfh.init_params_prod_med';
        pk_rt_med_pfh.init_params_prod_med(i_filter_name   => i_filter_name,
                                           i_custom_filter => i_custom_filter,
                                           i_context_ids   => i_context_ids,
                                           i_context_vals  => i_context_vals,
                                           i_name          => i_name,
                                           o_vc2           => o_vc2,
                                           o_num           => o_num,
                                           o_id            => o_id,
                                           o_tstz          => o_tstz);
    
    END init_params_prod_med;

    /********************************************************************************************
    * pk_api_pfh_in.get_hand_off_med (PIPELINED) 
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        PROFISSIONAL
    * @param    I_ID_EPISODE                    IN        NUMBER(24)
    * @param    I_FLG_STATUS                    IN        VARCHAR2
    *
    * @return   PK_API_PFH_IN.T_COLL_TAB_MED
    *
    * @author   Rui Marante
    * @version    
    * @since    2011-10-06
    *
    * @notes    
    *
    * @ext_refs   --
    *
    * @status   
    *
    ********************************************************************************************/
    FUNCTION get_hand_off_med
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_status IN VARCHAR2
    ) RETURN t_coll_tab_med
        PIPELINED IS
        --
        l_med        t_rec_med;
        l_id_patient patient.id_patient%TYPE;
        l_id_visit   episode.id_visit%TYPE;
        --
        l_flg_status_hold       CONSTANT VARCHAR2(1 CHAR) := 'H';
        l_flg_status_progress   CONSTANT VARCHAR2(1 CHAR) := 'P';
        l_flg_status_last_24h   CONSTANT VARCHAR2(1 CHAR) := 'D';
        l_flg_status_to_be_done CONSTANT VARCHAR2(1 CHAR) := 'T';
        --
        l_ex_invalid_flag_status EXCEPTION;
        --
    
        CURSOR c_med_progress IS
            SELECT pk_rt_med_pfh.get_conv_presc_status_new2old(i_lang, i_prof, v1.id_workflow, v1.id_status),
                   v1.dt_execution_task,
                   NULL, --trans_status
                   --v2.g_id_presc_mci_desc_long,
                   (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, v1.id_presc)
                      FROM dual),
                   v1.qty,
                   v1.id_unit_desc,
                   v3.dose_rng_min,
                   v3.id_sliding_scale_desc,
                   v3.dose_rng_max,
                   v3.id_sliding_scale_desc,
                   NULL, --value_bolus   !!TODO!!
                   NULL, --id_unit_measure_bolus
                   NULL, --value_drip
                   NULL --id_unit_measure_drip
              FROM TABLE(pk_rt_med_pfh.get_list_presc_administration(i_lang           => i_lang,
                                                                     i_prof           => i_prof,
                                                                     i_id_patient     => l_id_patient,
                                                                     i_id_episode_adm => i_id_episode,
                                                                     i_history_data   => pk_alert_constant.g_no)) v1
             INNER JOIN TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang => i_lang, i_prof => i_prof, i_id_visit => l_id_visit)) v2
                ON (v1.id_presc = v2.id_presc)
             INNER JOIN TABLE(pk_rt_med_pfh.get_list_presc_admin(i_lang => i_lang, i_prof => i_prof, i_id_presc => v1.id_presc)) v3
                ON (v2.id_presc = v3.id_presc)
             WHERE v1.id_status IN (201, 202, 203) --on going
             ORDER BY v1.dt_execution_task;
    
        CURSOR c_med_hold IS
            SELECT pk_rt_med_pfh.get_conv_presc_status_new2old(i_lang, i_prof, v1.id_workflow, v1.id_status),
                   v1.dt_execution_task,
                   NULL, --trans_status
                   --v2.g_id_presc_mci_desc_long,
                   (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, v1.id_presc)
                      FROM dual),
                   v1.qty,
                   v1.id_unit_desc,
                   v3.dose_rng_min,
                   v3.id_sliding_scale_desc,
                   v3.dose_rng_max,
                   v3.id_sliding_scale_desc,
                   NULL, --value_bolus TODO
                   NULL, --id_unit_measure_bolus
                   NULL, --value_drip
                   NULL --id_unit_measure_drip
              FROM TABLE(pk_rt_med_pfh.get_list_presc_administration(i_lang           => i_lang,
                                                                     i_prof           => i_prof,
                                                                     i_id_patient     => l_id_patient,
                                                                     i_id_episode_adm => i_id_episode,
                                                                     i_history_data   => pk_alert_constant.g_no)) v1
             INNER JOIN TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang => i_lang, i_prof => i_prof, i_id_visit => l_id_visit)) v2
                ON (v1.id_presc = v2.id_presc)
             INNER JOIN TABLE(pk_rt_med_pfh.get_list_presc_admin(i_lang => i_lang, i_prof => i_prof, i_id_presc => v1.id_presc)) v3
                ON (v2.id_presc = v3.id_presc)
             WHERE v1.id_status IN (204, 205) --suspended
             ORDER BY v1.dt_execution_task;
    
        CURSOR c_med_last_24h IS
            SELECT pk_rt_med_pfh.get_conv_presc_status_new2old(i_lang, i_prof, v1.id_workflow, v1.id_status),
                   v1.dt_execution_task,
                   NULL, --trans_status
                   --v2.g_id_presc_mci_desc_long,
                   (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, v1.id_presc)
                      FROM dual),
                   v1.qty,
                   v1.id_unit_desc,
                   v3.dose_rng_min,
                   v3.id_sliding_scale_desc,
                   v3.dose_rng_max,
                   v3.id_sliding_scale_desc,
                   NULL, --value_bolus  TODO
                   NULL, --id_unit_measure_bolus
                   NULL, --value_drip
                   NULL --id_unit_measure_drip
              FROM TABLE(pk_rt_med_pfh.get_list_presc_administration(i_lang           => i_lang,
                                                                     i_prof           => i_prof,
                                                                     i_id_patient     => l_id_patient,
                                                                     i_id_episode_adm => i_id_episode,
                                                                     i_history_data   => pk_alert_constant.g_no)) v1
             INNER JOIN TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang => i_lang, i_prof => i_prof, i_id_visit => l_id_visit)) v2
                ON (v1.id_presc = v2.id_presc)
              LEFT JOIN TABLE(pk_rt_med_pfh.get_list_presc_admin(i_lang => i_lang, i_prof => i_prof, i_id_presc => v1.id_presc)) v3
                ON (v2.id_presc = v3.id_presc)
             WHERE v1.dt_execution_task BETWEEN (current_timestamp - 1) AND current_timestamp --last 24h
             ORDER BY v1.dt_execution_task;
    
        CURSOR c_med_to_be_done IS
            SELECT pk_rt_med_pfh.get_conv_presc_status_new2old(i_lang, i_prof, v1.id_workflow, v1.id_status),
                   v1.dt_execution_task,
                   NULL, --trans_status
                   -- v2.g_id_presc_mci_desc_long,
                   (SELECT pk_rt_med_pfh.get_prod_desc_by_presc(i_lang, i_prof, v1.id_presc)
                      FROM dual),
                   v1.qty,
                   v1.id_unit_desc,
                   v3.dose_rng_min,
                   v3.id_sliding_scale_desc,
                   v3.dose_rng_max,
                   v3.id_sliding_scale_desc,
                   NULL, --value_bolus TODO
                   NULL, --id_unit_measure_bolus
                   NULL, --value_drip
                   NULL --id_unit_measure_drip
              FROM TABLE(pk_rt_med_pfh.get_list_presc_administration(i_lang           => i_lang,
                                                                     i_prof           => i_prof,
                                                                     i_id_patient     => l_id_patient,
                                                                     i_id_episode_adm => i_id_episode,
                                                                     i_history_data   => pk_alert_constant.g_no)) v1
             INNER JOIN TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang => i_lang, i_prof => i_prof, i_id_visit => l_id_visit)) v2
                ON (v1.id_presc = v2.id_presc)
             INNER JOIN TABLE(pk_rt_med_pfh.get_list_presc_admin(i_lang => i_lang, i_prof => i_prof, i_id_presc => v1.id_presc)) v3
                ON (v2.id_presc = v3.id_presc)
             WHERE v1.id_status = 200 --scheduled
             ORDER BY v1.dt_execution_task;
    
        --
    BEGIN
        g_error := 'get labels';
    
        g_error      := 'pk_episode.get_id_patient';
        l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
    
        g_error    := 'pk_episode.get_id_visit';
        l_id_visit := pk_episode.get_id_visit(i_episode => i_id_episode);
    
        g_error := 'switch flg_status...';
        CASE i_flg_status
            WHEN l_flg_status_hold THEN
                g_error := 'open cursor c_med_HOLD';
                OPEN c_med_hold;
                LOOP
                    FETCH c_med_hold
                        INTO l_med;
                    EXIT WHEN c_med_hold%NOTFOUND;
                    PIPE ROW(l_med);
                END LOOP;
                CLOSE c_med_hold;
            
            WHEN l_flg_status_last_24h THEN
                g_error := 'open cursor c_med_LAST_24H';
                OPEN c_med_last_24h;
                LOOP
                    FETCH c_med_last_24h
                        INTO l_med;
                    EXIT WHEN c_med_last_24h%NOTFOUND;
                    PIPE ROW(l_med);
                END LOOP;
                CLOSE c_med_last_24h;
            
            WHEN l_flg_status_progress THEN
                g_error := 'open cursor c_med_PROGRESS';
                OPEN c_med_progress;
                LOOP
                    FETCH c_med_progress
                        INTO l_med;
                    EXIT WHEN c_med_progress%NOTFOUND;
                    PIPE ROW(l_med);
                END LOOP;
                CLOSE c_med_progress;
            
            WHEN l_flg_status_to_be_done THEN
                g_error := 'open cursor c_med_TO_BE_DONE';
                OPEN c_med_to_be_done;
                LOOP
                    FETCH c_med_to_be_done
                        INTO l_med;
                    EXIT WHEN c_med_to_be_done%NOTFOUND;
                    PIPE ROW(l_med);
                END LOOP;
                CLOSE c_med_to_be_done;
            
            ELSE
                RAISE l_ex_invalid_flag_status;
        END CASE;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            IF (c_med_hold%ISOPEN)
            THEN
                CLOSE c_med_hold;
            END IF;
            IF (c_med_last_24h%ISOPEN)
            THEN
                CLOSE c_med_last_24h;
            END IF;
            IF (c_med_progress%ISOPEN)
            THEN
                CLOSE c_med_progress;
            END IF;
            IF (c_med_to_be_done%ISOPEN)
            THEN
                CLOSE c_med_to_be_done;
            END IF;
            --log
            pk_alertlog.log_error(text => SQLERRM);
            RAISE;
    END get_hand_off_med;

    /********************************************************************************************
    * This function copy to a new one all information of a given prescription
    *
    * @param  I_LANG                                  The language id
    * @param  I_PROF                                  The profissional
    * @param  I_ID_PRESC                              Prescription Id
    * @param  i_id_patient                            Patient Id
    * @param  i_id_episode                            Episode Id
    * @param  i_id_workflow                           Workflow Id
    * @param  i_id_status                             Status Id
    * @param  i_id_presc_type_rel                     Prescription type
    * @param  i_flg_exclude_detail                    flag that controls if copys only the main information
    * @param  i_flg_execution                         flag that specifies the type of execution: B; E; N
    *   
    *
    * @author  Pedro Teixeira
    * @since   2011-10-07
    *
    ********************************************************************************************/
    FUNCTION copy_presc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_presc           IN r_presc.id_presc%TYPE,
        i_id_patient         IN r_presc.id_patient%TYPE DEFAULT NULL, -- nullable
        i_id_episode         IN r_presc.id_epis_create%TYPE DEFAULT NULL, -- nullable
        i_id_workflow        IN r_presc.id_workflow%TYPE DEFAULT NULL, -- nullable
        i_id_status          IN r_presc.id_status%TYPE DEFAULT NULL, -- nullable
        i_id_presc_type_rel  IN r_presc.id_presc_type_rel%TYPE DEFAULT NULL, -- nullable
        i_flg_exclude_detail IN VARCHAR2 DEFAULT pk_rt_core_all.g_no, -- nullable
        i_flg_confirm        IN VARCHAR2 DEFAULT pk_rt_core_all.g_no,
        i_flg_execution      IN r_presc.flg_execution%TYPE DEFAULT NULL,
        o_id_presc           OUT r_presc.id_presc%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'COPY_PRESC';
    
    BEGIN
        g_error := 'copy prescription';
        RETURN pk_rt_med_pfh.copy_presc(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_id_presc           => i_id_presc,
                                        i_id_patient         => i_id_patient,
                                        i_id_episode         => i_id_episode,
                                        i_id_workflow        => i_id_workflow,
                                        i_id_status          => i_id_status,
                                        i_id_presc_type_rel  => i_id_presc_type_rel,
                                        i_flg_exclude_detail => i_flg_exclude_detail,
                                        i_flg_confirm        => i_flg_confirm,
                                        i_flg_execution      => i_flg_execution,
                                        o_id_presc           => o_id_presc,
                                        o_error              => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_db_object_name,
                                                     o_error);
        
    END copy_presc;

    /********************************************************************************************
    * This functions returns prescription for a given patient and episode
    * where flg_execution = 'N' (Next episode)
    *
    *
    * @author  Pedro Teixeira
    * @since   2011-10-07
    *
    ********************************************************************************************/
    FUNCTION get_next_epis_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN r_presc.id_patient%TYPE,
        i_id_episode IN r_presc.id_epis_create%TYPE,
        o_id_presc   OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_NEXT_EPIS_PRESC';
    
    BEGIN
        o_id_presc := table_number();
        g_error    := 'open bulk collect o_id_presc';
    
        RETURN pk_rt_med_pfh.get_next_epis_presc(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_id_patient => i_id_patient,
                                                 i_id_episode => i_id_episode,
                                                 o_id_presc   => o_id_presc,
                                                 o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => l_db_object_name,
                                                     o_error    => o_error);
    END get_next_epis_presc;

    /********************************************************************************************
    * This function deletes all information of a given prescription
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_EPISODE    Episode whose prescriptions will be deleted
    * @param i_flg_clean_vital_sign_only     Y: cleans only the presc associated to a vital_sign_read 
    *
    * @author  Pedro Quinteiro
    * @since   2011-08-18
    *
    ********************************************************************************************/
    FUNCTION delete_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'DELETE_PRESC';
    BEGIN
        g_error := 'delete prescription by episode';
        pk_alertlog.log_debug(g_error);
        RETURN pk_rt_med_pfh.delete_presc(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_id_episode => i_id_episode,
                                          o_error      => o_error);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_db_object_name,
                                                     o_error);
    END delete_presc;

    FUNCTION del_presc_vital_sign_assoc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN table_number,
        i_id_vital_sign_read IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'DELETE_PRESC';
    BEGIN
        g_error := 'delete prescription by vital_sign_read';
        pk_alertlog.log_debug(g_error);
        RETURN pk_rt_med_pfh.del_presc_vital_sign_assoc(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_id_episode         => i_id_episode,
                                                        i_id_vital_sign_read => i_id_vital_sign_read,
                                                        o_error              => o_error);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_db_object_name,
                                                     o_error);
    END del_presc_vital_sign_assoc;

    /*********************************************************************************************
    * This function returns 'Y' if presc is active for current visit
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_patient            patient identification
    * @param i_id_presc_type         Prescription type
    * @param i_product               Product
    *
    *
    * @author                        Pedro Teixeira
    * @since                         2012/07/25
    *********************************************************************************************/
    FUNCTION is_presc_med_view_active
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN presc.id_patient%TYPE,
        i_id_presc_type IN NUMBER,
        i_product       IN VARCHAR2,
        i_id_episode    IN presc.id_epis_create%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
    BEGIN
        g_error := 'CALL pk_api_med_out.is_presc_med_view_active';
        RETURN pk_rt_med_pfh.is_presc_med_view_active(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_id_patient    => i_id_patient,
                                                      i_id_presc_type => i_id_presc_type,
                                                      i_product       => i_product,
                                                      i_id_episode    => i_id_episode);
    
    END is_presc_med_view_active;

    /*********************************************************************************************
    * This function returns the status icon for a given product prescription
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_patient            patient identification
    * @param i_id_presc_type         Prescription type
    * @param i_product               Product
    *
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/10
    *********************************************************************************************/
    FUNCTION get_product_status_icon
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_presc_type IN NUMBER,
        i_product       IN VARCHAR2,
        i_id_episode    IN presc.id_epis_create%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
    BEGIN
        g_error := 'CALL pk_rt_med_pfh.get_product_status_icon';
        RETURN pk_rt_med_pfh.get_product_status_icon(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_patient    => i_id_patient,
                                                     i_id_presc_type => i_id_presc_type,
                                                     i_product       => i_product,
                                                     i_id_episode    => i_id_episode);
    
    END get_product_status_icon;

    /**
    * Checks if there are active home medication prescriptions for the given visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    *
    * @return               Y if such prescriptions exist, N otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.5
    * @since                2016/07/26
    */
    FUNCTION check_visit_home_med_presc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_visit   IN episode.id_visit%TYPE
    ) RETURN VARCHAR2 IS
        l_ret    VARCHAR2(1 CHAR);
        l_prescs table_number;
    BEGIN
        SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
         t.id_presc
          BULK COLLECT
          INTO l_prescs
          FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               i_id_workflow => table_number_id(pk_rt_med_pfh.wf_report),
                                                               i_id_patient  => i_patient,
                                                               i_id_visit    => i_visit)) t;
    
        IF l_prescs.count > 0
        THEN
            l_ret := pk_alert_constant.g_yes;
        ELSE
            l_ret := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_ret;
    END check_visit_home_med_presc;

    /********************************************************************************************
    * when new visit is created the on_create_visit procedure is executed
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @RETURN                             true or false, if error wasn't found or not
    *
    * @author                             Bruno Rego
    * @version                            2.6.1.1
    * @since                              02-06-2011 12:45
    *
    **********************************************************************************************/
    PROCEDURE on_create_visit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'ON_CREATE_VISIT';
        l_error t_error_out;
    
        l_has_home_med_presc VARCHAR2(1char);
        l_id_episode         NUMBER;
        l_flg_ehr            VARCHAR2(30char);
    
        CURSOR lc_episode_rowids IS
            SELECT e.id_episode,
                   e.id_visit,
                   e.id_patient,
                   e.id_prev_episode,
                   (SELECT COUNT(*)
                      FROM episode
                     WHERE id_visit = e.id_visit) num_episodes
              FROM episode e
             WHERE ROWID IN (SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
                              column_value
                               FROM TABLE(i_rowids) t)
               AND e.flg_ehr = pk_alert_constant.g_epis_ehr_normal;
    
    BEGIN
        --pk_alertlog.log_debug('CALL pk_rt_med_pfh.on_create_visit ENTREI');
        IF i_rowids IS NOT NULL
           AND i_rowids.count > 0
        THEN
            IF (g_debug)
            THEN
                FOR i IN 1 .. i_rowids.count
                LOOP
                    pk_alertlog.log_debug('pk_rt_med_pfh.on_create_visit i_rowids: ' || i_rowids(i));
                    BEGIN
                        SELECT e.id_episode, e.flg_ehr
                          INTO l_id_episode, l_flg_ehr
                          FROM episode e
                         WHERE e.rowid = i_rowids(i);
                    EXCEPTION
                        WHEN no_data_found THEN
                            pk_alertlog.log_debug('No episode found');
                    END;
                
                    pk_alertlog.log_debug('pk_rt_med_pfh.on_create_visit l_id_episode: ' || l_id_episode ||
                                          ' l_flg_ehr: ' || l_flg_ehr);
                END LOOP;
            END IF;
        
            IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
            THEN
                IF i_source_table_name = 'EPISODE'
                THEN
                    FOR l_er_item IN lc_episode_rowids
                    LOOP
                        --ONLY FOR THE FIRST VISIT                        
                        IF l_er_item.num_episodes = 1
                        THEN
                            --check if the visit do not have home medication yet
                            g_error              := 'check_visit_home_med_presc';
                            l_has_home_med_presc := check_visit_home_med_presc(i_lang    => i_lang,
                                                                               i_prof    => i_prof,
                                                                               i_patient => l_er_item.id_patient,
                                                                               i_visit   => l_er_item.id_visit);
                        
                            pk_alertlog.log_debug('l_has_home_med_presc: ' || l_has_home_med_presc);
                        
                            IF (l_has_home_med_presc = pk_alert_constant.g_no)
                            THEN
                                g_error := 'CALL pk_rt_med_pfh.on_create_visit. id_visit: ' || l_er_item.id_visit ||
                                           ' id_episode: ' || l_er_item.id_episode || ' id_patient: ' ||
                                           l_er_item.id_patient || ' i_lang: ' || i_lang || ' i_prof.id: ' || i_prof.id ||
                                           ' i_prof.institution: ' || i_prof.institution || ' i_prof.software: ' ||
                                           i_prof.software;
                                pk_alertlog.log_debug(g_error);
                                pk_rt_med_pfh.on_create_visit(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_id_visit   => l_er_item.id_visit,
                                                              i_id_episode => l_er_item.id_episode,
                                                              i_id_patient => l_er_item.id_patient,
                                                              o_error      => l_error);
                            END IF;
                        
                        END IF;
                    END LOOP;
                END IF;
            
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error);
            RAISE;
    END on_create_visit;

    /*********************************************************************************************
    * This function returns rank for a given product prescription
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_patient            patient identification
    * @param i_id_presc_type         Prescription type
    * @param i_product               Product
    *
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/11
    *********************************************************************************************/
    FUNCTION get_product_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_presc_type IN NUMBER,
        i_product       IN VARCHAR2
    ) RETURN NUMBER IS
    
    BEGIN
        g_error := 'CALL pk_rt_med_pfh.get_product_rank';
        RETURN pk_rt_med_pfh.get_product_rank(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_id_patient    => i_id_patient,
                                              i_id_presc_type => i_id_presc_type,
                                              i_product       => i_product);
    
    END get_product_rank;

    /*********************************************************************************************
    * This function returns the prescription type icon name for a given prescription detail identifier
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              The ID of the prescription
    *
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/11
    *********************************************************************************************/
    FUNCTION get_presc_icon_by_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
        g_error := 'CALL pk_rt_med_pfh.get_presc_icon_by_presc';
        RETURN pk_rt_med_pfh.get_presc_icon_by_presc(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END get_presc_icon_by_presc;

    /**********************************************************************************************
    * This function returns a array with the temporary states for a prescription reconciliation
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/11
    **********************************************************************************************/
    FUNCTION get_tmp_presc_recon RETURN table_number IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_tmp_presc_recon;
    END get_tmp_presc_recon;

    /**********************************************************************************************
    * Initialize params for filters search (Home Medication )
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Elisabete Bugalho
    * @version                       2.6.1.2
    * @since                         2011/10/06
    **********************************************************************************************/
    PROCEDURE init_params_home_med
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
    BEGIN
    
        g_error := 'call pk_rt_med_pfh.init_params_home_med';
        pk_rt_med_pfh.init_params_home_med(i_filter_name   => i_filter_name,
                                           i_custom_filter => i_custom_filter,
                                           i_context_ids   => i_context_ids,
                                           i_context_vals  => i_context_vals,
                                           i_name          => i_name,
                                           o_vc2           => o_vc2,
                                           o_num           => o_num,
                                           o_id            => o_id,
                                           o_tstz          => o_tstz);
    
    END init_params_home_med;

    /********************************************************************************************
    * Get editor lookup list
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_EDITOR_LOOKUP         the editor lookup type, as defined in el_* types
    * @param   I_ID_PRODUCT               the product identification (if needed)
    * @param   I_ID_PRODUCT_SUPPLIER      the product suppliter identification (if needed)
    * @param   O_INFO                     cursor with lookup list
    * @param   O_ERROR                    error information
    *
    * @RETURN                             true or false, if error wasn't found or not
    *
    * @author                             Bruno Rego
    * @version                            2.6.1.1
    * @since                              02-Sep-2011
    *
    **********************************************************************************************/
    FUNCTION get_editor_lookup
    
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_editor_lookup    IN NUMBER,
        i_id_product          IN NUMBER DEFAULT NULL,
        i_id_product_supplier IN NUMBER DEFAULT NULL,
        o_info                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_editor_lookup(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_editor_lookup    => i_id_editor_lookup,
                                               i_id_product          => i_id_product,
                                               i_id_product_supplier => i_id_product_supplier,
                                               o_info                => o_info,
                                               o_error               => o_error);
    END;

    /********************************************************************************************
    * This function returns presc details based on presc_med row_id
    * necessary for awareness processing
    *
    * @author  Pedro Teixeira
    * @since   2011-11-04
    *
    ********************************************************************************************/
    FUNCTION get_presc_med_details
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_rowid      IN VARCHAR2,
        o_id_patient OUT r_presc.id_patient%TYPE,
        o_id_episode OUT r_presc.id_epis_create%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_MED_DETAILS';
    
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_med_details(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_rowid      => i_rowid,
                                                   o_id_patient => o_id_patient,
                                                   o_id_episode => o_id_episode,
                                                   o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => l_db_object_name,
                                                     o_error    => o_error);
    END get_presc_med_details;

    /********************************************************************************************
    * This function returns presc details based on presc_med row_id
    * necessary for awareness processing
    *
    * @author  Bruno Rego
    * @since   2011-11-22
    *
    ********************************************************************************************/
    FUNCTION get_list_medication_aggr
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE DEFAULT NULL,
        i_id_visit   IN visit.id_visit%TYPE DEFAULT NULL,
        i_id_presc   IN pk_rt_med_pfh.r_presc.id_presc%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN CLOB IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_LIST_MEDICATION_AGGR';
    BEGIN
        RETURN pk_rt_med_pfh.get_list_medication_aggr(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_patient => i_id_patient,
                                                      i_id_visit   => i_id_visit,
                                                      i_id_presc   => i_id_presc).get_json(i_lang, i_prof);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN NULL;
    END get_list_medication_aggr;

    /******************************************************************************************
    * This function returns builded medication unique ID - Supplier + ..._id
    * based on the product/ingred/... AND supplier 
    *
    * @param i_id_product                         Input - Product ID
    * @param i_id_product_supplier                Input - Supplier ID
    *
    * @return  Medication Unique ID
    *          null if error
    * @raises                
    *
    * @author                Pedro Morais
    * @version               V.2.6.1
    * @since                 2011/07/12
    ********************************************************************************************/
    FUNCTION get_unique_id_by_id_and_supp
    (
        i_lang        IN NUMBER,
        i_id          IN VARCHAR2,
        i_id_supplier IN VARCHAR2,
        o_id_unique   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_id_unique := pk_rt_med_pfh.get_unique_id_by_id_and_supp(i_id, i_id_supplier);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UTILS',
                                              'GET_UNIQUE_ID_BY_ID_AND_SUPP',
                                              o_error);
        
            RETURN FALSE;
    END get_unique_id_by_id_and_supp;

    /******************************************************************************************
    * This function returns builded medication unique ID - Supplier + ..._id
    *
    * @param i_id_product                         Input - Product ID
    * @param i_id_product_supplier                Input - Supplier ID
    *
    * @return  Medication Unique ID
    *          null if error
    * @raises                
    *
    * @author                Sofia Mendes
    * @version               V.2.8.0.1
    * @since                 2019/11/11
    ********************************************************************************************/
    FUNCTION get_unique_id_by_id_and_supp
    (
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_rt_med_pfh.get_unique_id_by_id_and_supp(i_id_product, i_id_product_supplier);
    
    END get_unique_id_by_id_and_supp;

    /******************************************************************************************
    * This function returns builded medication unique ID - Supplier + ..._id
    * based on the product/ingred/... AND supplier 
    *
    * @param i_id_product                         Input - list of Product ID
    * @param i_id_product_supplier                Input - list of Supplier ID
    *
    * @return  Medication Unique ID
    *          null if error
    * @raises                
    *
    * @author                Pedro Quinteiro
    * @version               V.2.6.1
    * @since                 2011/08/24
    ********************************************************************************************/
    FUNCTION get_unique_ids_by_id_and_supp
    (
        i_lang        IN NUMBER,
        i_id          IN table_varchar,
        i_id_supplier IN table_varchar,
        o_id_unique   OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        o_id_unique := pk_rt_med_pfh.get_unique_id_by_id_and_supp(i_id, i_id_supplier);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UTILS',
                                              'GET_UNIQUE_IDS_BY_ID_AND_SUPP',
                                              o_error);
        
            RETURN FALSE;
    END get_unique_ids_by_id_and_supp;

    /********************************************************************************************
    * Returns CDS call icon associated to the passed prescription
    *
    *
    * @author               Pedro Teixeira
    * @since                2011/12/13
    ********************************************************************************************/
    FUNCTION get_cds_call_icon
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_call      IN NUMBER,
        i_task_reqs IN VARCHAR2
    ) RETURN VARCHAR IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_CDS_CALL_ICON';
        l_error t_error_out;
    BEGIN
        RETURN pk_rt_med_pfh.get_cds_call_icon(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               i_call      => i_call,
                                               i_task_reqs => i_task_reqs);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_cds_call_icon;

    /**********************************************************************************************
    * Initialize params for eRx filter
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Pedro Teixeira
    * @since                         2011/12/22
    **********************************************************************************************/
    PROCEDURE init_params_amb_erx
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
    BEGIN
    
        g_error := 'call pk_rt_med_pfh.init_params_amb_erx';
        pk_rt_med_pfh.init_params_amb_erx(i_filter_name   => i_filter_name,
                                          i_custom_filter => i_custom_filter,
                                          i_context_ids   => i_context_ids,
                                          i_context_vals  => i_context_vals,
                                          i_name          => i_name,
                                          o_vc2           => o_vc2,
                                          o_num           => o_num,
                                          o_id            => o_id,
                                          o_tstz          => o_tstz);
    
    END init_params_amb_erx;
    /*********************************************************************************************
    * This function returns the product configurations
    *
    * @author  Pedro Teixeira
    * @since   2011-12-13
    *********************************************************************************************/
    FUNCTION get_product_configurations
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN pk_rt_med_pfh.r_product.id_product%TYPE,
        i_id_product_supplier IN pk_rt_med_pfh.r_product.id_product_supplier%TYPE,
        i_id_pick_list        IN NUMBER
    ) RETURN table_varchar IS
    
        l_error_out t_error_out;
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRODUCT_CONFIGURATIONS';
    
    BEGIN
        g_error := 'call GET_PRODUCT_CONFIGURATIONS';
    
        RETURN pk_rt_med_pfh.get_product_configurations(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_product          => i_id_product,
                                                        i_id_product_supplier => i_id_product_supplier,
                                                        i_id_pick_list        => i_id_pick_list);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error_out);
            RETURN NULL;
    END get_product_configurations;

    /**
    * Checks if there are active prescriptions for the given episode.
    * Used in the Information desk patients grid detail.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    *
    * @return               Y if such prescriptions exist, N otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/01/20
    */
    FUNCTION check_epis_presc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_ret    VARCHAR2(1 CHAR);
        l_prescs table_number;
    BEGIN
        SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
         t.id_presc
          BULK COLLECT
          INTO l_prescs
          FROM TABLE(pk_rt_med_pfh.get_list_prescription_basic(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               i_id_workflow => table_number_id(pk_rt_med_pfh.wf_institution,
                                                                                                pk_rt_med_pfh.wf_iv),
                                                               i_id_patient  => i_patient)) t
         WHERE t.id_last_episode = i_episode
           AND t.id_status NOT IN (pk_rt_med_pfh.st_draft,
                                   pk_rt_med_pfh.st_cancelled,
                                   pk_rt_med_pfh.st_concluded,
                                   pk_rt_med_pfh.st_discontinued);
    
        IF l_prescs.count > 0
        THEN
            l_ret := pk_alert_constant.g_yes;
        ELSE
            l_ret := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_ret;
    END check_epis_presc;

    /********************************************************************************************
    * Create new review for home medication
    *
    * @param  i_prof                        The professional array
    * @param  i_id_patient                  Patient ID
    * @param  o_id_review                   Id review
    * @param  o_code_review                 Review Code
    * @param  o_review_desc                 Review Desc
    * @param  o_dt_create                   Review Creation Date
    * @param  o_id_prof_create              Review Creation Professional
    *
    * @return boolean
    *
    * @author Pedro Quinteiro
    * @last_rev Pedro Teixeira
    * @since  09/05/2010
    *
    ********************************************************************************************/
    FUNCTION get_last_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient     IN episode.id_patient%TYPE DEFAULT NULL,
        i_dt_begin       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_id_review      OUT NUMBER,
        o_code_review    OUT NUMBER,
        o_review_desc    OUT VARCHAR2,
        o_dt_create      OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_dt_update      OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_id_prof_create OUT NUMBER,
        o_info_source    OUT CLOB,
        o_pat_not_take   OUT CLOB,
        o_pat_take       OUT CLOB,
        o_notes          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_error_out t_error_out;
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_LAST_REVIEW';
    BEGIN
        g_error := 'call pk_rt_med_pfh.get_last_review';
    
        RETURN pk_rt_med_pfh.get_last_review(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_id_episode     => i_id_episode,
                                             i_id_patient     => i_id_patient,
                                             i_dt_begin       => i_dt_begin,
                                             i_dt_end         => i_dt_end,
                                             o_id_review      => o_id_review,
                                             o_code_review    => o_code_review,
                                             o_review_desc    => o_review_desc,
                                             o_dt_create      => o_dt_create,
                                             o_dt_update      => o_dt_update,
                                             o_id_prof_create => o_id_prof_create,
                                             o_info_source    => o_info_source,
                                             o_pat_not_take   => o_pat_not_take,
                                             o_pat_take       => o_pat_take,
                                             o_notes          => o_notes);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error_out);
            RETURN NULL;
    END get_last_review;

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
    * @last_rev Pedro Teixeira
    * @since  13/03/2012
    ********************************************************************************************/
    FUNCTION set_hm_review_global_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        io_id_review  IN OUT NUMBER,
        i_code_review IN NUMBER
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'SET_HM_REVIEW_GLOBAL_INFO';
    
        l_error_out    t_error_out;
        l_dummy_cursor pk_types.cursor_type;
        l_exception EXCEPTION;
    
    BEGIN
        g_error := 'call pk_rt_med_pfh.set_hm_review_global_info';
    
        /*IF NOT pk_rt_med_pfh.set_hm_review_global_info(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_id_patient  => i_id_patient,
                                                       i_id_episode  => i_id_episode,
                                                       io_id_review  => io_id_review,
                                                       i_global_info => i_code_review,
                                                       o_info        => l_dummy_cursor,
                                                       o_error       => l_error_out)
        THEN
            RAISE l_exception;
        END IF;*/
    
        RETURN pk_rt_med_pfh.set_hm_review_status_reviewed(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_id_patient => i_id_patient,
                                                           i_id_episode => i_id_episode,
                                                           i_id_review  => io_id_review);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(l_dummy_cursor);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error_out);
            RETURN NULL;
    END set_hm_review_global_info;

    /********************************************************************************************
    * This procedure gets the reconciliation status
    *
    * @param i_lang                   The ID of the user language
    * @param i_prof                   The profissional information array
    * @param i_id_patient             The patient name
    * @param i_id_episode             The ID of the episode
    *
    * @author  Pedro Teixeira
    * @since   12/03/2012
    ********************************************************************************************/
    FUNCTION get_recon_status_summary
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        o_flg_rev_reviewed     OUT VARCHAR2,
        o_flg_rev_reconciled   OUT VARCHAR2,
        o_flg_revision_warning OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_RECON_STATUS_SUMMARY';
    BEGIN
    
        RETURN pk_rt_med_pfh.get_recon_status_summary(i_lang                 => i_lang,
                                                      i_prof                 => i_prof,
                                                      i_id_patient           => i_id_patient,
                                                      i_id_episode           => i_id_episode,
                                                      o_flg_rev_reviewed     => o_flg_rev_reviewed,
                                                      o_flg_rev_reconciled   => o_flg_rev_reconciled,
                                                      o_flg_revision_warning => o_flg_revision_warning);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => l_db_object_name);
            RAISE;
    END get_recon_status_summary;

    /*********************************************************************************************
    * This function will return prescription basic information:
    * - product description
    * - directions description
    * - status description
    *
    * @param i_lang             The ID of the user language
    * @param i_prof             The profissional array
    * @param i_id_presc         The ID of the prescription
    *
    * @return boolean
    *
    * @author Pedro Teixeira
    * @since  26/01/2012
    *
    ********************************************************************************************/
    FUNCTION get_presc_basic_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_presc          IN r_presc.id_presc%TYPE,
        o_presc_prod_desc   OUT VARCHAR2,
        o_presc_dir_desc    OUT VARCHAR2,
        o_presc_status_desc OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_error_out t_error_out;
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_BASIC_INFO';
    BEGIN
    
        RETURN pk_rt_med_pfh.get_presc_basic_info(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_id_presc          => i_id_presc,
                                                  o_presc_prod_desc   => o_presc_prod_desc,
                                                  o_presc_dir_desc    => o_presc_dir_desc,
                                                  o_presc_status_desc => o_presc_status_desc);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error_out);
            RETURN NULL;
    END get_presc_basic_info;

    /********************************************************************************************
    * Adds notes to a prescription
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        ALERT_PRODUCT_TR.PROFISSIONAL
    * @param    I_ID_PRESC                      IN        PRESCRIPTION ID
    * @param    I_NOTES                         IN        NOTES TEXT
    *
    * @author   Pedro Morais
    * @version    
    * @since    2011-11-04
    *
    * @added to this package         Pedro Teixeira
    * @version                       2.6.2
    * @since                         08/02/2012
    ********************************************************************************************/
    FUNCTION set_prescription_notes
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_presc            IN r_presc.id_presc%TYPE,
        i_notes               IN VARCHAR2,
        o_id_presc_notes      OUT NUMBER,
        o_id_presc_notes_item OUT NUMBER
    ) RETURN BOOLEAN IS
    
        l_error_out t_error_out;
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'SET_PRESCRIPTION_NOTES';
    BEGIN
        g_error := 'call pk_rt_med_pfh.set_prescription_notes';
        RETURN pk_rt_med_pfh.set_prescription_notes(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_id_presc            => i_id_presc,
                                                    i_notes               => i_notes,
                                                    o_id_presc_notes      => o_id_presc_notes,
                                                    o_id_presc_notes_item => o_id_presc_notes_item);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error_out);
            RETURN NULL;
    END set_prescription_notes;

    /********************************************************************************************
    * This function is for single_page
    *
    * @author           Pedro Teixeira
    * @since            2012/06/22
    ********************************************************************************************/
    PROCEDURE get_presc_for_single_page
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_presc             IN table_number,
        i_flg_with_notes       IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_recon_notes IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_no,
        o_info                 OUT pk_types.cursor_type
    ) IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'GET_PRESC_FOR_SINGLE_PAGE';
        l_error_out t_error_out;
    BEGIN
        g_error := 'CALL PK_API_MED_OUT.GET_PRESC_FOR_SINGLE_PAGE';
        pk_rt_med_pfh.get_presc_for_single_page(i_lang                 => i_lang,
                                                i_prof                 => i_prof,
                                                i_id_presc             => i_id_presc,
                                                i_flg_with_notes       => i_flg_with_notes,
                                                i_flg_with_recon_notes => i_flg_with_recon_notes,
                                                o_info                 => o_info);
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_presc_for_single_page;

    /********************************************************************************************
    * This function is to obtain prescription list with less returned columns
    *
    * @author           Pedro Teixeira
    * @since            2012/12/04
    ********************************************************************************************/
    FUNCTION get_list_presc_resumed
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_workflow          IN table_number_id DEFAULT NULL,
        i_id_patient           IN r_presc.id_patient%TYPE DEFAULT NULL,
        i_id_visit             IN r_presc.id_epis_create%TYPE DEFAULT NULL,
        i_eliminate_duplicates IN VARCHAR2 DEFAULT 'N'
    ) RETURN pk_rt_types.g_tbl_list_presc_resumed
        PIPELINED IS
    BEGIN
        FOR row_i IN (SELECT *
                        FROM TABLE(pk_rt_med_pfh.get_list_presc_resumed(i_lang                 => i_lang,
                                                                        i_prof                 => i_prof,
                                                                        i_id_workflow          => i_id_workflow,
                                                                        i_id_patient           => i_id_patient,
                                                                        i_id_visit             => i_id_visit,
                                                                        i_eliminate_duplicates => i_eliminate_duplicates)))
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    
    END get_list_presc_resumed;

    /********************************************************************************************
    * pk_api_med_out.create_reported_freetext
    *
    * @param    I_LANG                          IN        NUMBER(6)
    * @param    I_PROF                          IN        PROFISSIONAL
    * @param    I_ID_PATIENT                    IN        NUMBER(24)
    * @param    I_ID_EPISODE                    IN        NUMBER(24)
    * @param    I_DESC_PRODUCT                  IN        VARCHAR2
    * @param    O_ID_PRESC                      OUT       NUMBER(24)
    *
    * @author   Rita Lopes
    * @version    
    * @since    2013-02-20
    *
    * @notes    cria relatos medicacao em texto livre
    *
    * @ext_refs   --
    *
    * @status   100% - DONE!
    *
    ********************************************************************************************/
    PROCEDURE create_reported_freetext
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN presc.id_patient%TYPE,
        i_id_episode   IN presc.id_epis_create%TYPE,
        i_desc_product IN VARCHAR2,
        o_id_presc     OUT presc.id_presc%TYPE,
        o_error        OUT t_error_out
    ) IS
    
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'CREATE_REPORTED_FREETEXT';
    
    BEGIN
        g_error := 'pk_api_med_out.get_drug_details_4report';
        pk_rt_med_pfh.create_reported_freetext(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_id_patient   => i_id_patient,
                                               i_id_episode   => i_id_episode,
                                               i_desc_product => i_desc_product,
                                               o_id_presc     => o_id_presc,
                                               o_error        => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => l_db_object_name);
        
            RAISE;
    END create_reported_freetext;

    /********************************************************************************************
    * This function returns information of Home and Local medication to reports
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_EPISODE    The Episode
    *
    * @author  Alexis Nascimento
    * @since   2013-07-22 
    *
    ********************************************************************************************/

    FUNCTION get_medication_info_4report
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_flg_reconciliantion  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_review           IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_home_medication  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_local_medication IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_presc_administ   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_presc_stat_hist  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_presc_revisions  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_local_presc_dirs IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_direction_config IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_hm_revision          OUT pk_types.cursor_type,
        o_hm_reports           OUT pk_types.cursor_type,
        o_reconciliantion_info OUT pk_types.cursor_type,
        o_local_presc          OUT pk_types.cursor_type,
        o_local_admin          OUT pk_types.cursor_type,
        o_local_admin_detail   OUT pk_types.cursor_type,
        o_presc_stat_hist      OUT pk_types.cursor_type,
        o_list_revisions       OUT pk_types.cursor_type,
        o_list_prod_revisions  OUT pk_types.cursor_type,
        o_local_presc_dirs     OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        RESULT BOOLEAN;
    
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'GET_MEDICATION_INFO_4REPORT';
    BEGIN
        g_error := 'pk_rt_med_pfh.get_medication_info_4report';
        RESULT  := pk_rt_med_pfh.get_medication_info_4report(i_lang                 => i_lang,
                                                             i_prof                 => i_prof,
                                                             i_id_episode           => i_id_episode,
                                                             i_flg_reconciliantion  => i_flg_reconciliantion,
                                                             i_flg_review           => i_flg_review,
                                                             i_flg_home_medication  => i_flg_home_medication,
                                                             i_flg_local_medication => i_flg_local_medication,
                                                             i_flg_presc_administ   => i_flg_presc_administ,
                                                             i_flg_presc_stat_hist  => i_flg_presc_stat_hist,
                                                             i_flg_presc_revisions  => i_flg_presc_revisions,
                                                             i_flg_local_presc_dirs => i_flg_local_presc_dirs,
                                                             i_flg_direction_config => i_flg_direction_config,
                                                             o_hm_revision          => o_hm_revision,
                                                             o_hm_reports           => o_hm_reports,
                                                             o_reconciliantion_info => o_reconciliantion_info,
                                                             o_local_presc          => o_local_presc,
                                                             o_local_admin          => o_local_admin,
                                                             o_local_admin_detail   => o_local_admin_detail,
                                                             o_presc_stat_hist      => o_presc_stat_hist,
                                                             o_list_revisions       => o_list_revisions,
                                                             o_list_prod_revisions  => o_list_prod_revisions,
                                                             o_local_presc_dirs     => o_local_presc_dirs,
                                                             o_error                => o_error);
    
        RETURN RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => l_db_object_name);
        
            RAISE;
    END get_medication_info_4report;

    /********************************************************************************************
    * This procedure returns the necessary data to delete or create an Alert
    *
    * @author Pedro Teixeira
    * @since  07/08/2013
    *
    ********************************************************************************************/
    PROCEDURE get_presc_alerts_data
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_source_table_name   IN VARCHAR2 DEFAULT 'PRESC',
        i_rowids              IN table_varchar,
        o_id_presc            OUT presc.id_presc%TYPE,
        o_dt_first_valid_plan OUT r_presc.dt_first_valid_plan%TYPE,
        o_id_patient          OUT r_presc.id_patient%TYPE,
        o_id_episode          OUT r_presc.id_epis_create%TYPE,
        o_prod_desc           OUT VARCHAR2,
        o_id_prof_co_sign     OUT NUMBER,
        o_id_status           OUT r_presc.id_status%TYPE,
        o_dt_last_update      OUT r_presc.dt_last_update%TYPE,
        o_flg_edited          OUT r_presc.flg_edited%TYPE,
        o_trigger_event       OUT NUMBER,
        o_error               OUT t_error_out
    ) IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'GET_PRESC_ALERTS_DATA';
    BEGIN
        g_error := 'pk_api_pfh_in.get_presc_alerts_data';
        pk_rt_med_pfh.get_presc_alerts_data(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_source_table_name   => i_source_table_name,
                                            i_rowids              => i_rowids,
                                            o_id_presc            => o_id_presc,
                                            o_dt_first_valid_plan => o_dt_first_valid_plan,
                                            o_id_patient          => o_id_patient,
                                            o_id_episode          => o_id_episode,
                                            o_prod_desc           => o_prod_desc,
                                            o_id_prof_co_sign     => o_id_prof_co_sign,
                                            o_id_status           => o_id_status,
                                            o_dt_last_update      => o_dt_last_update,
                                            o_flg_edited          => o_flg_edited,
                                            o_trigger_event       => o_trigger_event,
                                            o_error               => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => l_db_object_name);
            RAISE;
    END get_presc_alerts_data;

    /********************************************************************************************
    * This procedure processes the presc alerts
    *
    * @author Pedro Teixeira
    * @since  07/08/2013
    *
    ********************************************************************************************/
    PROCEDURE process_presc_alerts
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'PROCESS_PRESC_ALERTS';
        l_error_out t_error_out;
    
        -- alerts specific variables
        l_alert_event_row     sys_alert_event%ROWTYPE;
        l_id_presc            r_presc.id_presc%TYPE;
        l_dt_first_valid_plan r_presc.dt_first_valid_plan%TYPE;
        l_id_patient          r_presc.id_patient%TYPE;
        l_id_episode          r_presc.id_epis_create%TYPE;
        l_prod_desc           translation.desc_lang_1%TYPE;
        l_id_prof_co_sign     NUMBER;
        l_id_status           r_presc.id_status%TYPE;
        l_dt_last_update      r_presc.dt_last_update%TYPE;
        l_flg_edited          r_presc.flg_edited%TYPE;
        l_trigger_event       NUMBER(6);
    
        ----------------------------------------------------------------
        -- CONSTANTS
        ----------------------------------------------------------------
        -- Alert 150: Medications to be administered
        c_alert_presc_admin CONSTANT sys_alert.id_sys_alert%TYPE := 150;
        -- Alert 316: Medication order update
        c_alert_presc_update CONSTANT sys_alert.id_sys_alert%TYPE := 316;
    
        ----------------------------------------------------------------
        -- FUNCTIONS
        ----------------------------------------------------------------
        FUNCTION get_clinical_service_id(i_id_episode IN episode.id_episode%TYPE) RETURN episode.id_clinical_service%TYPE IS
            l_id_cs episode.id_clinical_service%TYPE;
        BEGIN
            BEGIN
                -- Get_clinical_service
                g_error := 'GET ID_CLINICAL_SERVICE';
                SELECT e.id_clinical_service
                  INTO l_id_cs
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            EXCEPTION
                WHEN OTHERS THEN
                    pk_alertlog.log_debug('Clinical Service not found for episode ' || i_id_episode);
                    l_id_cs := NULL;
            END;
            RETURN l_id_cs;
        END get_clinical_service_id;
    BEGIN
        -- Validate arguments
        g_error := 't_data_gov_mnt.validate_arguments - process_presc_alerts';
        pk_alertlog.log_debug(g_error);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => i_dg_table_name,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- obtain presc data for alert creation deletion 
        g_error := 'GET_PRESC_ALERTS_DATA';
        pk_alertlog.log_debug(g_error);
        get_presc_alerts_data(i_lang                => i_lang,
                              i_prof                => i_prof,
                              i_source_table_name   => i_source_table_name,
                              i_rowids              => i_rowids,
                              o_id_presc            => l_id_presc, -- id_presc is always returned
                              o_id_episode          => l_id_episode, -- id_episode is always returned
                              o_dt_first_valid_plan => l_dt_first_valid_plan,
                              o_id_patient          => l_id_patient,
                              o_prod_desc           => l_prod_desc,
                              o_id_prof_co_sign     => l_id_prof_co_sign,
                              o_id_status           => l_id_status,
                              o_dt_last_update      => l_dt_last_update,
                              o_flg_edited          => l_flg_edited,
                              o_trigger_event       => l_trigger_event,
                              o_error               => l_error_out);
    
        -- if id_presc is not found then exit
        IF l_id_presc IS NULL
           OR l_id_patient IS NULL
        THEN
            pk_alertlog.log_debug('id_presc or id_patient IS NULL');
            RETURN;
        END IF;
    
        ------------------------------------------------------------------------------------------------
        -- PROCESS ALERT 150
        -- Medications to be administered
        ------------------------------------------------------------------------------------------------ 
    
        -- create / update / delete alert
        IF i_event_type = t_data_gov_mnt.g_event_delete
           OR l_dt_first_valid_plan IS NULL -- if l_dt_first_valid_plan is null then no more tasks defined for the presc: delete alert
        THEN
            l_alert_event_row.id_sys_alert := c_alert_presc_admin;
            l_alert_event_row.id_episode   := l_id_patient;
            l_alert_event_row.id_record    := l_id_presc;
        
            g_error := 'ALERT150: DELETE_SYS_ALERT_EVENT';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_alert_event_row,
                                                    o_error           => l_error_out)
            THEN
                pk_alertlog.log_error(g_error);
            END IF;
        
        ELSIF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            l_alert_event_row.id_sys_alert := c_alert_presc_admin;
        
            -- ALERT-305433 professional is not needed and may create duplicate alerts
            -- (if administered by different professional than the one that precribed)
            /*-- ALERT-265576 - Alert for profissional with co-sign
            IF l_id_prof_co_sign IS NULL
            THEN
                l_alert_event_row.id_professional := i_prof.id;
            ELSE
                l_alert_event_row.id_professional := l_id_prof_co_sign;
            END IF;*/
        
            g_error := 'ALERT150: BUILD ALERT ROW';
            pk_alertlog.log_debug(g_error);
            l_alert_event_row.id_software         := i_prof.software;
            l_alert_event_row.id_institution      := i_prof.institution;
            l_alert_event_row.id_episode          := l_id_episode;
            l_alert_event_row.id_patient          := l_id_patient;
            l_alert_event_row.id_visit            := pk_episode.get_id_visit(i_episode => l_id_episode);
            l_alert_event_row.id_record           := l_id_presc;
            l_alert_event_row.dt_record           := l_dt_first_valid_plan;
            l_alert_event_row.replace1            := l_prod_desc;
            l_alert_event_row.replace2            := pk_sysconfig.get_config('ALERT_TAKE_TIMEOUT1', i_prof);
            l_alert_event_row.id_clinical_service := get_clinical_service_id(i_id_episode => l_id_episode);
        
            g_error := 'ALERT150: INSERT_SYS_ALERT_EVENT';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_alert_event_row,
                                                    o_error           => l_error_out)
            THEN
                pk_alertlog.log_error(g_error);
            END IF;
        END IF;
    
        ------------------------------------------------------------------------------------------------
        -- PROCESS ALERT 316
        -- Medication order update
        ------------------------------------------------------------------------------------------------ 
        -- The nurse responsible by the patient must receive an alert each time there is 
        --     a) a new medication order, 
        --     b) the medication order is changed, 
        --     c) the medication order is stopped (cancelled, discontinued, put on hold) 
        ------------------------------------------------------------------------------------------------ 
    
        -- Clear alert row
        l_alert_event_row := NULL;
    
        g_error := 'ALERT316 [' || i_event_type || '] STATUS CHANGE = ' || l_trigger_event || '; ID_STATUS = ' ||
                   l_id_status || '; ID_PRESC = ' || l_id_presc || '; DT_LAST_UPDATE = ' || l_dt_last_update;
        pk_alertlog.log_debug(g_error);
        IF nvl(l_trigger_event, pk_rt_med_pfh.g_not_trigger_event) IN
           (pk_rt_med_pfh.g_trigger_event, pk_rt_med_pfh.g_delete_event)
        THEN
            -- Set new row
            g_error := 'ALERT316 [' || i_event_type || '] BUILD ALERT ROW';
            pk_alertlog.log_debug(g_error);
            l_alert_event_row.id_sys_alert        := c_alert_presc_update;
            l_alert_event_row.id_software         := i_prof.software;
            l_alert_event_row.id_institution      := i_prof.institution;
            l_alert_event_row.id_patient          := pk_episode.get_id_patient(i_episode => l_id_episode);
            l_alert_event_row.id_visit            := pk_episode.get_id_visit(i_episode => l_id_episode);
            l_alert_event_row.id_episode          := l_id_episode;
            l_alert_event_row.id_record           := l_id_presc;
            l_alert_event_row.dt_record           := l_dt_last_update;
            l_alert_event_row.id_professional     := NULL;
            l_alert_event_row.id_clinical_service := NULL;
            l_alert_event_row.replace1            := l_prod_desc;
            l_alert_event_row.replace2            := NULL;
        
            -- UPDATE / DELETE
            IF i_event_type = t_data_gov_mnt.g_event_update
               OR i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                -- Remove previous record of this alert
                g_error := 'ALERT316 [' || i_event_type || '] DELETE_SYS_ALERT_EVENT';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_alert_event_row,
                                                        o_error           => l_error_out)
                THEN
                    pk_alertlog.log_error(g_error);
                END IF;
            
                IF l_trigger_event = pk_rt_med_pfh.g_trigger_event
                THEN
                    -- Insert new record for this alert
                    g_error := 'ALERT316 [' || i_event_type || '] INSERT_SYS_ALERT_EVENT';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_sys_alert_event => l_alert_event_row,
                                                            o_error           => l_error_out)
                    THEN
                        pk_alertlog.log_error(g_error);
                    END IF;
                END IF;
            
            ELSIF i_event_type = t_data_gov_mnt.g_event_insert
                  AND l_trigger_event = pk_rt_med_pfh.g_trigger_event
            THEN
                -- INSERT
                g_error := 'ALERT316 [' || i_event_type || '] INSERT_SYS_ALERT_EVENT';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_alert_event_row,
                                                        o_error           => l_error_out)
                THEN
                    pk_alertlog.log_error(g_error);
                END IF;
            END IF;
        END IF;
    
        RETURN;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END process_presc_alerts;

    /********************************************************************************************
    * This procedure emits an alert every time a prescription is updated.
    *
    * @param  i_lang              Language ID
    * @param  i_prof              Professional info array
    * @param  i_event_type        Event type
    * @param  i_rowids            Row ID's
    * @param  i_source_table_name Source table name
    * @param  i_list_columns      List of columns
    * @param  i_dg_table_name     Data governance table
    *
    * @author Jose Brito
    * @since  04/11/2014
    *
    ********************************************************************************************/
    PROCEDURE process_presc_update_alerts
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'PROCESS_PRESC_UPDATE_ALERTS';
        l_error_out t_error_out;
    
        l_alert_event_row sys_alert_event%ROWTYPE;
    
        l_id_episode          episode.id_episode%TYPE;
        l_id_patient          episode.id_patient%TYPE;
        l_id_presc            r_presc.id_presc%TYPE;
        l_dt_first_valid_plan r_presc.dt_first_valid_plan%TYPE;
        l_id_prof_co_sign     professional.id_professional%TYPE;
        l_id_status           r_presc.id_status%TYPE;
        l_dt_last_update      r_presc.dt_last_update%TYPE;
        l_prod_desc           translation.desc_lang_1%TYPE;
        l_flg_edited          r_presc.flg_edited%TYPE;
        l_trigger_event       NUMBER(6);
    
        ----------------------------------------------------------------
        -- CONSTANTS
        ----------------------------------------------------------------
        -- Alert 316: Medication order update
        c_alert_presc_update CONSTANT sys_alert.id_sys_alert%TYPE := 316;
    
    BEGIN
        -- Validate arguments
        g_error := 't_data_gov_mnt.validate_arguments - process_presc_alerts';
        pk_alertlog.log_debug(g_error);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => i_dg_table_name,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => table_varchar('FLG_EDITED'))
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        g_error := 'GET_PRESC_ALERTS_DATA';
        pk_alertlog.log_debug(g_error);
        get_presc_alerts_data(i_lang                => i_lang,
                              i_prof                => i_prof,
                              i_source_table_name   => i_source_table_name,
                              i_rowids              => i_rowids,
                              o_id_presc            => l_id_presc, -- ID_PRESC is always returned
                              o_id_episode          => l_id_episode, -- ID_EPISODE is always returned
                              o_dt_first_valid_plan => l_dt_first_valid_plan,
                              o_id_patient          => l_id_patient,
                              o_prod_desc           => l_prod_desc,
                              o_id_prof_co_sign     => l_id_prof_co_sign,
                              o_id_status           => l_id_status,
                              o_dt_last_update      => l_dt_last_update,
                              o_flg_edited          => l_flg_edited,
                              o_trigger_event       => l_trigger_event,
                              o_error               => l_error_out);
    
        IF l_id_presc IS NULL
           OR (l_id_presc IS NOT NULL AND l_id_status IS NULL AND l_trigger_event IS NULL)
        THEN
            -- Exit if id_presc is not found OR prescription is not eligible for this type of alert
            pk_alertlog.log_debug('[ALERT_NOT_TRIGGERED] ID_PRESC IS NULL OR PRESC NOT ELIGIBLE');
            RETURN;
        END IF;
    
        --
        -- This should only process UPDATE events
        --
        IF i_event_type = t_data_gov_mnt.g_event_update
           AND l_flg_edited = pk_alert_constant.g_yes
        THEN
            g_error := '[ALERT_TRIGGERED] ID_PRESC = ' || l_id_presc || '; STATUS CHANGE = ' || l_trigger_event || --
                       '; ID_STATUS = ' || l_id_status || '; DT_LAST_UPDATE = ' || l_dt_last_update;
            pk_alertlog.log_debug(g_error);
            -- Set new row
            l_alert_event_row.id_sys_alert        := c_alert_presc_update;
            l_alert_event_row.id_software         := i_prof.software;
            l_alert_event_row.id_institution      := i_prof.institution;
            l_alert_event_row.id_patient          := pk_episode.get_id_patient(i_episode => l_id_episode);
            l_alert_event_row.id_visit            := pk_episode.get_id_visit(i_episode => l_id_episode);
            l_alert_event_row.id_episode          := l_id_episode;
            l_alert_event_row.id_record           := l_id_presc;
            l_alert_event_row.dt_record           := l_dt_last_update;
            l_alert_event_row.id_professional     := NULL;
            l_alert_event_row.id_clinical_service := NULL;
            l_alert_event_row.replace1            := l_prod_desc;
            l_alert_event_row.replace2            := NULL;
        
            -- Remove previous record of this alert
            g_error := '[ALERT_TRIGGERED] ALERT316 [' || i_event_type || '] DELETE_SYS_ALERT_EVENT';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_alert_event_row,
                                                    o_error           => l_error_out)
            THEN
                pk_alertlog.log_error(g_error);
            END IF;
        
            -- Insert new record for this alert
            g_error := '[ALERT_TRIGGERED] ALERT316 [' || i_event_type || '] INSERT_SYS_ALERT_EVENT';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_alert_event_row,
                                                    o_error           => l_error_out)
            THEN
                pk_alertlog.log_error(g_error);
            END IF;
        END IF;
    
        RETURN;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END process_presc_update_alerts;

    PROCEDURE init_params_witness
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
    BEGIN
    
        pk_rt_med_pfh.init_params_witness(i_filter_name   => i_filter_name,
                                          i_custom_filter => i_custom_filter,
                                          i_context_ids   => i_context_ids,
                                          i_context_vals  => i_context_vals,
                                          i_name          => i_name,
                                          o_vc2           => o_vc2,
                                          o_num           => o_num,
                                          o_id            => o_id,
                                          o_tstz          => o_tstz);
    END init_params_witness;

    /********************************************************************************************
    * This function returns data for the details and history
    *
    * @param  I_LANG          The langiage id
    * @param  I_PROF          The profissional
    * @param  I_ID_DETAIL     The details id to get the data as defined in presc_details_history table    
    * @param  I_ID_EPISODE    The visit episode (MED_ENTRY_DETAILS, MED_ENTRY_HISTORY, RECONCILIATION_DETAILS, RECONCILIATION_HISTORY) 
    * @param  I_ID_PRESC_PLAN The id prescription plan (ADMINISTRATION_DETAILS, ADMINISTRATION_HISTORY)
    * @param  I_ID_PRESC      The product id prescription list (PRESCRIPTION_DETAILS, PRESCRIPTION_HISTORY)         
    * @param  O_CUR_DATA      The cursor output with information
    * @param  O_CUR_TABLES    The cursor output with tables
    * @param  O_ERROR         The output for error information
    *
    * @author  Rui Teixeira
    * @version 2.6.3.8.5
    * @since   2013-11-18 
    *
    ********************************************************************************************/
    FUNCTION get_details_history
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_detail     IN NUMBER,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_presc_plan IN episode.id_episode%TYPE,
        i_id_presc      IN table_number,
        o_cur_data      OUT pk_types.cursor_type,
        o_cur_tables    OUT table_table_varchar,
        o_header_presc  OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_details_history(i_lang,
                                                 i_prof,
                                                 i_id_detail,
                                                 i_id_episode,
                                                 i_id_presc_plan,
                                                 i_id_presc,
                                                 o_cur_data,
                                                 o_cur_tables,
                                                 o_header_presc,
                                                 o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT_INTER',
                                              i_package  => 'PK_RT_MED_PFH',
                                              i_function => 'get_details_history',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_details_history;

    /********************************************************************************************
    * This function returns data for the details and history
    *
    * @param  I_LANG          The langiage id
    * @param  I_PROF          The profissional
    * @param  I_ID_DETAIL     The details id to get the data as defined in presc_details_history table    
    * @param  I_ID_EPISODE    The visit episode (MED_ENTRY_DETAILS, MED_ENTRY_HISTORY, RECONCILIATION_DETAILS, RECONCILIATION_HISTORY) 
    * @param  I_ID_PRESC_PLAN The id prescription plan (ADMINISTRATION_DETAILS, ADMINISTRATION_HISTORY)
    * @param  I_ID_PRESC      The product id prescription list (PRESCRIPTION_DETAILS, PRESCRIPTION_HISTORY)         
    * @param  O_CUR_DATA      The cursor output with information
    * @param  O_CUR_TABLES    The cursor output with tables
    * @param  O_ERROR         The output for error information
    *
    * @author  Rui Teixeira
    * @version 2.6.3.8.5
    * @since   2013-11-18 
    *
    ********************************************************************************************/
    FUNCTION get_details
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_detail          IN NUMBER,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_presc_plan      IN episode.id_episode%TYPE,
        i_id_presc           IN table_number,
        i_id_presc_plan_task IN NUMBER DEFAULT NULL,
        o_cur_data           OUT pk_types.cursor_type,
        o_cur_tables         OUT table_table_varchar,
        o_header_presc       OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_details(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_id_detail          => i_id_detail,
                                         i_id_episode         => i_id_episode,
                                         i_id_presc_plan      => i_id_presc_plan,
                                         i_id_presc           => i_id_presc,
                                         i_id_presc_plan_task => i_id_presc_plan_task,
                                         o_cur_data           => o_cur_data,
                                         o_cur_tables         => o_cur_tables,
                                         o_header_presc       => o_header_presc,
                                         o_error              => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT_INTER',
                                              i_package  => 'PK_RT_MED_PFH',
                                              i_function => 'get_details',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_details;

    /********************************************************************************************
    * Get patient and presc products for CDR validations
    ********************************************************************************************/
    FUNCTION get_patient_presc_prods
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN r_presc.id_patient%TYPE,
        i_id_product_sup IN table_varchar DEFAULT NULL,
        i_id_presc       IN table_number,
        o_products       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PATIENT_PRESC_PRODS';
    BEGIN
    
        RETURN pk_rt_med_pfh.get_patient_presc_prods(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_id_patient     => i_id_patient,
                                                     i_id_product_sup => i_id_product_sup,
                                                     i_id_presc       => i_id_presc,
                                                     o_products       => o_products,
                                                     o_error          => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => l_db_object_name);
        
            RAISE;
    END get_patient_presc_prods;

    /** @grant_by_soft_inst
    * Public Function. gets most relevant grant by institution/software criteria
    *
    * @param    i_context            context to be used ( table name )
    * @param    i_prof               info of current user
    * @param    i_dcs                array od dep_clin_Sev to compare( if available )
    * @param    i_specialty          array of clinical_service to compare ( if available )
    *
    * @return   array of relevant id_grant 
    *
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2013/11/29
    */
    FUNCTION grant_by_soft_inst
    (
        i_context   IN VARCHAR2,
        i_prof      IN profissional,
        i_dcs       IN table_number DEFAULT table_number(0),
        i_specialty IN table_number DEFAULT table_number(0)
    ) RETURN table_number IS
        l_tbl_return table_number;
    BEGIN
    
        l_tbl_return := pk_rt_med_pfh.grant_by_soft_inst(i_context => i_context,
                                                         
                                                         i_prof      => i_prof,
                                                         i_dcs       => i_dcs,
                                                         i_specialty => i_specialty);
    
        RETURN l_tbl_return;
    
    END grant_by_soft_inst;

    FUNCTION grant_by_prof_dcs
    (
        i_context IN VARCHAR2,
        i_prof    IN profissional
    ) RETURN table_number IS
        l_tbl_return table_number;
    BEGIN
    
        l_tbl_return := pk_rt_med_pfh.grant_by_prof_dcs(i_context => i_context, i_prof => i_prof);
    
        RETURN l_tbl_return;
    
    END grant_by_prof_dcs;

    /*************************************************************************
    * This function returns home medication ranks!                           *
    *                                                                        *
    * @param                 i_status                 Input - id status      *
    * @return                rank                                            *
    *                                                                        *
    * @raises                                                                *
    *                                                                        *
    * @author                Alexis Nascimento                               *
    * @version               V.2.6.3                                         *
    * @since                 2013/11/29                                      *
    *************************************************************************/

    FUNCTION get_hm_rank_by_status
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_presc  IN presc.id_presc%TYPE,
        i_status IN NUMBER
    ) RETURN NUMBER IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'GET_HM_RANK_BY_STATUS';
    
    BEGIN
        g_error := 'pk_rt_med_pfh.get_hm_rank_by_status';
    
        RETURN pk_rt_med_pfh.get_hm_rank_by_status(i_lang   => i_lang,
                                                   i_prof   => i_prof,
                                                   i_presc  => i_presc,
                                                   i_status => i_status);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => l_db_object_name);
        
    END get_hm_rank_by_status;

    /**
    * Check if product anda directions are vailable in favorite list
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    *
    *
    * @return  'Y'es if is favorite, otherwise 'N'o 
    *
    * @author  JOANA.BARROSO
    * @version <Product Version>
    * @since   28-11-2013
    */

    FUNCTION check_prod_favorite
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_pick_list        IN NUMBER,
        i_id_most_freq        IN NUMBER,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_type                IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'CHECK_PROD_FAVORITE';
    
        l_ret VARCHAR2(1);
    BEGIN
        g_error := 'pk_rt_med_pfh.check_prod_favorite / I_ID_PICK_LIST=' || i_id_pick_list || ', I_ID_MOST_FREQ=' ||
                   i_id_most_freq || ', I_ID_PRODUCT=' || i_id_product || ', I_ID_PRODUCT_SUPPLIER=' ||
                   i_id_product_supplier || ', I_TYPE' || i_type;
    
        l_ret := pk_rt_med_pfh.check_prod_favorite(i_lang                => i_lang,
                                                   i_prof                => i_prof,
                                                   i_id_pick_list        => i_id_pick_list,
                                                   i_id_most_freq        => i_id_most_freq,
                                                   i_id_product          => i_id_product,
                                                   i_id_product_supplier => i_id_product_supplier,
                                                   i_type                => i_type);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text => SQLERRM, object_name => g_package_name, sub_object_name => l_db_object_name);
            RETURN pk_alert_constant.g_no;
        
    END check_prod_favorite;

    /*******************************************************************************************************************************************
    * Receives id_product_level and returns the level_tag
    *
    * @param  i_id_product_level                                Input - id_product_level          
    *
    * @return                       level_Tag 
    *                        
    * @author                        Mário Mineiro
    * @version                       2.6.3.8.9
    * @since                         2013/12/11
    *******************************************************************************************************************************************/
    FUNCTION get_product_level_tag
    (
        i_id_product           IN VARCHAR2,
        i_id_product_level     IN VARCHAR2,
        i_id_product_level_sup IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_tag_already_in_product VARCHAR2(200 CHAR);
    BEGIN
        l_tag_already_in_product := regexp_replace(i_id_product, '[^[:alpha:]]', NULL);
    
        IF (l_tag_already_in_product IS NULL)
        THEN
            RETURN pk_rt_med_pfh.get_product_level_tag(i_id_product_level     => i_id_product_level,
                                                       i_id_product_level_sup => i_id_product_level_sup);
        ELSE
            RETURN NULL;
        END IF;
    END get_product_level_tag;

    /*******************************************************************************************************************************************
    * Receives id_product and returns the id_product without the level_tag
    *
    * @param  i_id_product_level                                Input - id_product_level          
    *
    * @return                       level_Tag 
    *                        
    * @author                        Mário Mineiro
    * @version                       2.6.3.8.9
    * @since                         2013/12/11
    *******************************************************************************************************************************************/

    FUNCTION remove_product_level_tag(
                                      
                                      i_id_product          IN VARCHAR2,
                                      i_id_product_supplier IN VARCHAR2 DEFAULT NULL
                                      
                                      ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_rt_med_pfh.remove_product_level_tag(i_id_product          => i_id_product,
                                                      i_id_product_supplier => i_id_product_supplier);
    END remove_product_level_tag;

    /**
    * This function check if products are available in lnk_product_pick_list_grant
    *
    * @param i_lang                The ID of the user language
    * @param i_prof                The profissional information array
    * @param i_id_product          Array of product id
    * @param i_id_product_supplier Array of product supplier id    
    * @param i_grant               ID grant
    * @param i_id_pick_list        ID pick list
    *
    * @author  Joana Madureira Barroso
    * @version 2.6.3.9
    * @since   2013/12/19
    */
    FUNCTION check_product_pkl_available
    (
        i_lang                language.id_language%TYPE,
        i_prof                profissional,
        i_id_product          table_varchar,
        i_id_product_supplier table_varchar,
        i_grant               NUMBER,
        i_id_pick_list        NUMBER
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_rt_med_pfh.check_product_pkl_available(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_id_product          => i_id_product,
                                                         i_id_product_supplier => i_id_product_supplier,
                                                         i_grant               => i_grant,
                                                         i_id_pick_list        => i_id_pick_list);
    
    END check_product_pkl_available;

    /********************************************************************************************
    * Get instructions background color
    *
    * @author      Joana Madureira Barroso
    * @version     
    * @since       07/01/2014
    *
    ********************************************************************************************/

    FUNCTION get_instr_bg_color
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dt_stoptime IN presc.dt_stoptime%TYPE,
        i_id_workflow IN presc.id_workflow%TYPE,
        i_id_status   IN presc.id_status%TYPE,
        i_flg_edited  IN presc.flg_edited%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_instr_bg_color(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_dt_stoptime => i_dt_stoptime,
                                                i_id_workflow => i_id_workflow,
                                                i_id_status   => i_id_status,
                                                i_flg_edited  => i_flg_edited);
    END get_instr_bg_color;

    FUNCTION get_instr_bg_alpha
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dt_stoptime IN presc.dt_stoptime%TYPE,
        i_id_workflow IN presc.id_workflow%TYPE,
        i_id_status   IN presc.id_status%TYPE,
        i_flg_edited  IN presc.flg_edited%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_rt_med_pfh.get_instr_bg_alpha(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_dt_stoptime => i_dt_stoptime,
                                                i_id_workflow => i_id_workflow,
                                                i_id_status   => i_id_status,
                                                i_flg_edited  => i_flg_edited);
    END get_instr_bg_alpha;

    FUNCTION get_instr_bg_color_by_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_instr_bg_color_by_presc(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END get_instr_bg_color_by_presc;

    FUNCTION get_instr_bg_alpha_by_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_instr_bg_alpha_by_presc(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END get_instr_bg_alpha_by_presc;

    /**
    * Get draft RX prescription list for a given episode
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis         Episode identification
    *
    * @return  pipelined
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_draft
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN presc.id_epis_create%TYPE
    ) RETURN pk_rt_types.g_tbl_presc_viewer_list
        PIPELINED IS
    BEGIN
        FOR row_i IN (SELECT *
                        FROM TABLE(pk_rt_med_pfh.get_rx_prescription_draft(i_lang => i_lang,
                                                                           i_prof => i_prof,
                                                                           i_epis => i_epis)))
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    
    END get_rx_prescription_draft;

    /**
    * Get all active RX prescription list for a given episode
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis         Episode identification
    *
    * @return  pipelined
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_epis
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN pk_rt_types.g_tbl_presc_viewer_list
        PIPELINED IS
    BEGIN
        FOR row_i IN (SELECT *
                        FROM TABLE(pk_rt_med_pfh.get_rx_prescription_epis(i_lang => i_lang,
                                                                          i_prof => i_prof,
                                                                          i_epis => i_epis)))
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    
    END get_rx_prescription_epis;

    /**
    * Get all active RX prescription list for a given patient from previous episodes
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_pat          Patient identification
    * @param   i_epis         Episode identification    
    *
    * @return  pipelined
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_all
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_pat  IN patient.id_patient%TYPE,
        i_epis IN episode.id_episode%TYPE
    ) RETURN pk_rt_types.g_tbl_presc_viewer_list
        PIPELINED IS
    BEGIN
        FOR row_i IN (SELECT *
                        FROM TABLE(pk_rt_med_pfh.get_rx_prescription_all(i_lang => i_lang,
                                                                         i_prof => i_prof,
                                                                         i_pat  => i_pat,
                                                                         i_epis => i_epis)))
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    
    END get_rx_prescription_all;

    /**
    * Get detail for a given RX prescription
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id           Prescription identification
    * @param   i_type         Type of prescription list
    *
    * @value   i_type   {*} 'DRAFT' get_rx_prescription_darft 
                        {*} 'ALL' get_rx_prescription_all    
                        {*} 'EPIS' get_rx_prescription_epis    
    *
    * @return  pipelined
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_detail
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_id   IN NUMBER,
        i_type IN VARCHAR2
    ) RETURN pk_rt_types.g_tbl_presc_viewer_detail
        PIPELINED IS
    BEGIN
        FOR row_i IN (SELECT *
                        FROM TABLE(pk_rt_med_pfh.get_rx_prescription_detail(i_lang => i_lang,
                                                                            i_prof => i_prof,
                                                                            i_id   => i_id,
                                                                            i_type => i_type)))
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    
    END get_rx_prescription_detail;

    PROCEDURE pat_take_not_take_label
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_pat_take     OUT VARCHAR2,
        o_pat_not_take OUT VARCHAR2,
        o_info_source  OUT VARCHAR2,
        o_notes        OUT VARCHAR2
    ) IS
    BEGIN
        pk_rt_med_pfh.pat_take_not_take_label(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              o_pat_take     => o_pat_take,
                                              o_pat_not_take => o_pat_not_take,
                                              o_info_source  => o_info_source,
                                              o_notes        => o_notes);
    
    END pat_take_not_take_label;

    /********************************************************************************************
    * pk_api_pfh_in.get_info_button_med
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        ALERT_PRODUCT_TR.PROFISSIONAL
    * @param  I_ID_ELEMENTS                           IN        TABLE
    * @param  O_ID_RXNORM                             OUT       TABLE
    * @param  O_DESC_RXNORM                           OUT       TABLE
    * @param  O_TERMINOLOGY                           OUT       TABLE
    *
    *
    *
    * @author      Pedro Miranda
    * @version     
    * @since       08/04/2014
    *
    ********************************************************************************************/
    FUNCTION get_info_button_med
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_elements IN table_varchar,
        o_id_rxnorm   OUT table_varchar,
        o_desc_rxnorm OUT table_varchar,
        o_terminology OUT table_varchar
    ) RETURN BOOLEAN IS
        l_error_out t_error_out;
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_INFO_BUTTON_DETAILS';
    
        l_hl7 terminology.hl7_oid%TYPE;
    
        l_terminology table_varchar;
        l_dummy       table_varchar;
        l_bool        BOOLEAN;
    
    BEGIN
    
        l_terminology := table_varchar();
    
        l_bool := pk_rt_med_pfh.get_info_button_med(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_id_elements => i_id_elements,
                                                    o_id_rxnorm   => o_id_rxnorm,
                                                    o_desc_rxnorm => o_desc_rxnorm,
                                                    o_terminology => l_dummy);
    
        SELECT t.hl7_oid
          INTO l_hl7
          FROM terminology t
         WHERE t.internal_name = 'RXNORM';
    
        FOR i IN 1 .. o_id_rxnorm.count
        LOOP
            l_terminology.extend(1);
            l_terminology(l_terminology.count) := l_hl7;
        END LOOP;
    
        o_terminology := l_terminology;
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
        
            RETURN FALSE;
    END get_info_button_med;

    /********************************************************************************************
    * pk_api_pfh_in.get_products_by_presc
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        ALERT_INTER.PROFISSIONAL
    * @param  I_ID_PRESC                              IN        NUMBER
    * @param  O_ELEMENTS                              OUT       TABLE
    * @param  O_ELEMENTS_TYPE                         OUT       TABLE
    *
    * @return  PL/SQL BOOLEAN
    *
    * @author      Pedro Miranda
    * @version     
    * @since       09/04/2014
    *
    ********************************************************************************************/
    FUNCTION get_products_by_presc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_presc      IN NUMBER,
        o_elements      OUT table_varchar,
        o_elements_type OUT table_varchar
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_rt_med_pfh.get_products_by_presc(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_id_presc      => i_id_presc,
                                                   o_elements      => o_elements,
                                                   o_elements_type => o_elements_type);
    
    END get_products_by_presc;

    /********************************************************************************************
    * Get a string of info icons for a given prescription ID
    *
    * @param  I_LANG                 The language id
    * @param  I_PROF                 The profissional
    * @param  I_ID_PRESC             Prescription ID
    *
    * @return  PL/SQL VARCHAR2
    *
    * @author      Sérgio Cunha
    * @version     
    * @since       13/06/2014
    *
    ********************************************************************************************/
    FUNCTION get_presc_info_icons
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_rt_med_pfh.get_presc_info_icons(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END get_presc_info_icons;

    /*********************************************************************************************
    * @author      Pedro Teixeira
    * @since       20/06/2014
    *********************************************************************************************/
    FUNCTION get_last_request_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN r_presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_rt_med_pfh.get_last_request_desc(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END get_last_request_desc;
    /********************************************************************************************
    * This functions returns 'Y' if all the prescriptions for a product are cancelled.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional ID / Institution ID / Software ID
    * @param   i_id_episode               Episode ID
    * @param   i_product                  Product description
    *
    * @return                             (Y) All prescriptions are cancelled. 
    *                                     (N) At least one prescription is not cancelled.
    *
    * @author  José Brito
    * @version 2.6.4.2
    * @since   05/09/2014
    *
    ********************************************************************************************/
    FUNCTION check_all_cancel_presc_by_prod
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN presc.id_epis_create%TYPE,
        i_product    IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.check_all_cancel_presc_by_prod(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_episode => i_id_episode,
                                                            i_product    => i_product);
    END check_all_cancel_presc_by_prod;

    /********************************************************************************************
    * pk_api_pfh_in.get_entity_desc_by_grant
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_PRODUCT                            IN        VARCHAR2
    * @param  I_ID_PRODUCT_SUPPLIER                   IN        VARCHAR2
    * @param  I_CODE_PRODUCT                          IN        VARCHAR2
    * @param  I_CODE_SYNONYM                          IN        VARCHAR2
    * @param  I_ID_PICK_LIST                          IN        NUMBER
    * @param  I_USE_SYNONYM                           IN        VARCHAR2
    * @param  I_ID_DESCRIPTION_TYPE                   IN        NUMBER
    * @param  I_FLG_SYNS_ONLY                         IN        VARCHAR2
    *
    * @return  VARCHAR2
    *
    * @author      Pedro Miranda
    * @version     
    * @since       19/09/2014
    *
    ********************************************************************************************/
    FUNCTION get_entity_desc_by_grant
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_code_product        IN VARCHAR2,
        i_code_synonym        IN VARCHAR2,
        i_id_pick_list        IN NUMBER,
        i_use_synonym         IN VARCHAR2,
        i_id_description_type IN NUMBER DEFAULT 1,
        i_flg_syns_only       IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_entity_desc_by_grant(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_product          => i_id_product,
                                                      i_id_product_supplier => i_id_product_supplier,
                                                      i_code_product        => i_code_product,
                                                      i_code_synonym        => i_code_synonym,
                                                      i_id_pick_list        => i_id_pick_list,
                                                      i_use_synonym         => i_use_synonym,
                                                      i_id_description_type => i_id_description_type,
                                                      i_flg_syns_only       => i_flg_syns_only);
    END get_entity_desc_by_grant;
    /**********************************************************************************************
    * Initialize params for filters search (Replacing The prescribed medication)
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name
    *
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Joana Madureira Barroso
    * @version                       2.6.4.2.1
    * @since                         2014/10/02
    **********************************************************************************************/
    PROCEDURE init_params_product_replace
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
    BEGIN
    
        g_error := 'Call pk_filters.init_params_pharm_pat_grid';
        pk_rt_med_pfh.init_params_product_replace(i_filter_name   => i_filter_name,
                                                  i_custom_filter => i_custom_filter,
                                                  i_context_ids   => i_context_ids,
                                                  i_context_vals  => i_context_vals,
                                                  i_name          => i_name,
                                                  o_vc2           => o_vc2,
                                                  o_num           => o_num,
                                                  o_id            => o_id,
                                                  o_tstz          => o_tstz);
    
    END init_params_product_replace;

    /********************************************************************************************
    * Get a string of pharmacy icons for a given prescription ID
    *
    * @author      Alexis Nascimento
    * @version     
    * @since       05/09/2014
    *
    ********************************************************************************************/
    FUNCTION get_presc_pharm_icons
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc        IN presc.id_presc%TYPE,
        i_id_presc_type   IN NUMBER,
        i_id_pha_dispense IN NUMBER
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_rt_pha_pfh.get_presc_pharm_icons(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_task         => i_id_presc,
                                                   i_id_task_type    => i_id_presc_type,
                                                   i_id_pha_dispense => i_id_pha_dispense);
    
    END get_presc_pharm_icons;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_presc_pharm_bg_color
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc        IN presc.id_presc%TYPE,
        i_id_presc_type   IN NUMBER,
        i_id_pha_dispense IN NUMBER
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_rt_pha_pfh.get_presc_pharm_bg_color(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_task         => i_id_presc,
                                                      i_id_task_type    => i_id_presc_type,
                                                      i_id_pha_dispense => i_id_pha_dispense);
    
    END get_presc_pharm_bg_color;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_presc_pharm_rank
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc_type   IN NUMBER,
        i_id_pha_dispense IN NUMBER
    ) RETURN NUMBER IS
    
    BEGIN
        RETURN pk_rt_pha_pfh.get_presc_pharm_rank(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_id_task_type    => i_id_presc_type,
                                                  i_id_pha_dispense => i_id_pha_dispense);
    
    END get_presc_pharm_rank;

    /********************************************************************************************
    * Return 'Y' or 'N', if the product in medication backoffice was edited or not edited
    *
    * @author      Joel Lopes
    * @version     
    * @since       07/10/2014
    *
    ********************************************************************************************/
    FUNCTION get_product_edit
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional DEFAULT NULL,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
        g_error := 'call pk_rt_med_pfh.get_product_edit';
    
        RETURN pk_rt_med_pfh.get_product_edit(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_product          => i_id_product,
                                              i_id_product_supplier => i_id_product_supplier);
    
    END get_product_edit;

    /********************************************************************************************
    * Return 'Y' or 'N', if the product in medication backoffice is or isn't a composite product
    *
    * @author      Joel Lopes
    * @version     
    * @since       07/10/2014
    *
    ********************************************************************************************/
    FUNCTION get_prod_comp
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional DEFAULT NULL,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
        g_error := 'call pk_rt_med_pfh.get_prod_comp';
    
        RETURN pk_rt_med_pfh.get_prod_comp(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_id_product          => i_id_product,
                                           i_id_product_supplier => i_id_product_supplier);
    
    END get_prod_comp;

    /**********************************************************************************************
    * Lucene Search
    *
    * @param i_lang                  Language ID
    * @param i_search                string to search
    * @param i_column_name           column name
    * @param i_id_description_type   i_id_description_type
    *
    * @return                        Returns the search results
    *                        
    * @author                        Joana Madureira Barroso
    * @version                       2.6.1.2
    * @since                         2011/09/02
    **********************************************************************************************/
    FUNCTION get_my_src_entity
    (
        i_lang                IN language.id_language%TYPE,
        i_inn_search          IN VARCHAR2,
        i_brand_search        IN VARCHAR2,
        i_id_description_type IN NUMBER
    ) RETURN table_t_search IS
        l_error   t_error_out;
        tbl_inn   table_t_search;
        tbl_brand table_t_search;
        tbl_total table_t_search;
    
    BEGIN
    
        IF i_inn_search IS NOT NULL
        THEN
        
            tbl_inn := pk_api_pfh_in.get_src_entity(i_lang                => i_lang,
                                                    i_search              => i_inn_search,
                                                    i_column_name         => 'INN.CODE_INN',
                                                    i_id_description_type => i_id_description_type);
        END IF;
        IF i_brand_search IS NOT NULL
        THEN
        
            tbl_brand := pk_api_pfh_in.get_src_entity(i_lang                => i_lang,
                                                      i_search              => i_brand_search,
                                                      i_column_name         => 'BRAND.CODE_BRAND',
                                                      i_id_description_type => i_id_description_type);
        END IF;
    
        tbl_total := tbl_inn MULTISET UNION tbl_brand;
    
        RETURN tbl_total;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MY_SRC_ENTITY',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
        
    END get_my_src_entity;

    /**********************************************************************************************
    * Gets information about print list job related to the medication
    * Used by print list
    *
    * @param     i_lang               Professional preferred language
    * @param     i_prof               Professional identification and its context (institution and software)
    * @param     i_id_print_list_job  Print list job identifier, related to the referral
    *
    * @return    t_rec_print_list_job Print list job information
    *                        
    * @author    Pedro Teixeira
    * @version   2.6.4.2.1 - issue ALERT-281418 
    * @since     14/10/2014
    **********************************************************************************************/
    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'tf_get_print_job_info';
    
        ----------------------
        l_params       VARCHAR2(1000 CHAR);
        l_result       t_rec_print_list_job;
        l_context_data print_list_job.context_data%TYPE; -- "id_workflow|id_presc"
    
        ----------------------
        l_delim                 VARCHAR2(1 CHAR) := '|';
        l_context_data_elements table_varchar := table_varchar();
        l_id_workflow           presc.id_workflow%TYPE;
        l_id_presc_type         NUMBER;
        l_code_presc_type       VARCHAR2(100 CHAR) := 'PRESC_TYPE.ID_PRESC_TYPE.';
        l_duplicate_code_action VARCHAR2(100 CHAR) := 'ACTION.CODE_ACTION.701850';
        l_id_presc              VARCHAR2(4000 CHAR);
        l_desc                  VARCHAR2(100 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' || i_id_print_list_job;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        l_result := t_rec_print_list_job();
    
        ----------------------------------------------------------------    
        -- getting context data of this print list job
        SELECT v.context_data
          INTO l_context_data
          FROM v_print_list_context_data v
         WHERE v.id_print_list_job = i_id_print_list_job;
    
        ----------------------------------------------------------------
        -- get information from context_data
        g_error                 := 'l_id_ref / ' || l_params;
        l_context_data_elements := pk_utils.str_split_l(i_list => l_context_data, i_delim => l_delim);
    
        ----------------------------------------------------------------
        -- get context_data elements
        IF l_context_data_elements.count = 1
        THEN
            l_id_workflow := CAST(l_context_data_elements(1) AS NUMBER);
        ELSIF l_context_data_elements.count = 2
        THEN
            l_id_workflow := CAST(l_context_data_elements(1) AS NUMBER);
            l_id_presc    := l_context_data_elements(2);
        ELSE
            -- the context data has indetermined element components (should be 1: "id_workflow" or 2: "id_workflow|id_presc")
            RETURN t_rec_print_list_job();
        END IF;
    
        ----------------------------------------------------------------
        -- decode workflow into presc_type
        CASE l_id_workflow
            WHEN 13 THEN
                l_id_presc_type := 2;
            WHEN 20 THEN
                l_id_presc_type := 5;
            WHEN 15 THEN
                l_id_presc_type := 4;
            WHEN 16 THEN
                l_id_presc_type := 3;
            WHEN 18 THEN
                -- report duplicata
                l_id_presc_type := 4;
            ELSE
                l_id_presc_type := 2;
        END CASE;
    
        l_code_presc_type := l_code_presc_type || l_id_presc_type;
    
        ----------------------------------------------------------------
        l_params := l_params || ' id_presc_type=' || l_id_presc_type || ' id_presc=' || l_id_presc;
        g_error  := 'Call get_translation for code_presc_type of: / ' || l_params;
        l_desc   := pk_translation.get_translation(i_lang, l_code_presc_type);
    
        IF l_id_workflow = 18
        THEN
            l_desc := l_desc || ' (' || lower(pk_message.get_message(i_lang, l_duplicate_code_action)) || ')';
        END IF;
    
        ----------------------------------------------------------------
        -- Setting the output type
        g_error                    := 'Setting output / ' || l_params;
        l_result.id_print_list_job := i_id_print_list_job;
        l_result.title_desc        := pk_message.get_message(i_lang => i_lang, i_code_mess => 'MED_PRESC_T001');
        l_result.subtitle_desc     := l_desc;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLERRM || ' / ' || g_error);
            RETURN t_rec_print_list_job();
    END tf_get_print_job_info;

    /**********************************************************************************************
    * Compares if a print list job context data is similar to the array of print list jobs
    * Used by print list
    *
    * @param     i_lang                         Professional preferred language
    * @param     i_prof                         Professional identification and its context (institution and software)
    * @param     i_print_job_context_data       Print list job context data
    * @param     i_print_list_jobs              Array of print list job identifiers
    *
    * @return    table_number                   Arry of print list jobs that are similar
    *                        
    * @author    Pedro Teixeira - based on code by ana.monteiro
    * @version   2.6.4.2.1 - issue ALERT-281418 
    * @since     14/10/2014
    **********************************************************************************************/
    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_print_list_jobs        IN table_number
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'tf_compare_print_jobs';
        l_params VARCHAR2(1000 CHAR);
        l_result table_number;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_print_job_context_data=' || i_print_job_context_data ||
                    ' i_print_list_jobs=' || pk_utils.to_string(i_print_list_jobs);
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- getting all id_print_list_jobs from i_print_list_jobs that have the same context_data (id_ref) as i_print_list_job
        SELECT t.id_print_list_job
          BULK COLLECT
          INTO l_result
          FROM (SELECT /*+opt_estimate (table t rows=1)*/
                 v2.id_print_list_job
                  FROM v_print_list_context_data v2
                  JOIN TABLE(CAST(i_print_list_jobs AS table_number)) t
                    ON t.column_value = v2.id_print_list_job
                 WHERE dbms_lob.compare(v2.context_data, i_print_job_context_data) = 0) t;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLERRM || ' / ' || g_error);
            RETURN table_number();
    END tf_compare_print_jobs;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION get_presc_print_list_data
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_rowids          IN table_varchar,
        o_id_patient      OUT patient.id_patient%TYPE,
        o_id_episode      OUT episode.id_episode%TYPE,
        o_print_list_area OUT NUMBER,
        o_id_workflow     OUT table_number,
        o_id_presc        OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_PRINT_LIST_DATA';
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_print_list_data(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_rowids          => i_rowids,
                                                       o_id_patient      => o_id_patient,
                                                       o_id_episode      => o_id_episode,
                                                       o_print_list_area => o_print_list_area,
                                                       o_id_workflow     => o_id_workflow,
                                                       o_id_presc        => o_id_presc,
                                                       o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RAISE;
    END get_presc_print_list_data;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION update_list_job_prescs
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_presc    IN table_number,
        i_action_type IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'UPDATE_LIST_JOB_PRESCS';
    BEGIN
        RETURN pk_rt_med_pfh.update_list_job_prescs(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_id_presc    => i_id_presc,
                                                    i_action_type => i_action_type,
                                                    o_error       => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RAISE;
    END update_list_job_prescs;

    /********************************************************************************************
    * pk_api_pfh_in.get_info_button_med_ddi
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_ELEMENTS                           IN        TABLE_VARCHAR
    * @param  O_ID_RXNORM                             OUT       TABLE_VARCHAR
    * @param  O_DESC_RXNORM                           OUT       TABLE_VARCHAR
    * @param  O_TERMINOLOGY                           OUT       TABLE_VARCHAR
    *
    * @return  BOOLEAN
    *
    * @author      Pedro Miranda
    * @version     
    * @since       03/11/2014
    *
    ********************************************************************************************/
    FUNCTION get_info_button_med_therap
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN NUMBER,
        i_id_elements IN table_varchar,
        o_id_rxnorm   OUT table_varchar,
        o_desc_rxnorm OUT table_varchar,
        o_terminology OUT table_varchar
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_INFO_BUTTON_MED_THERAP';
        l_error t_error_out;
    
        l_hl7 terminology.hl7_oid%TYPE;
    
        l_terminology table_varchar;
        l_dummy       table_varchar;
        l_bool        BOOLEAN;
    
    BEGIN
    
        l_terminology := table_varchar();
    
        l_bool := pk_rt_med_pfh.get_info_button_med_therap(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_id_patient  => i_id_patient,
                                                           i_id_elements => i_id_elements,
                                                           o_id_rxnorm   => o_id_rxnorm,
                                                           o_desc_rxnorm => o_desc_rxnorm,
                                                           o_terminology => l_dummy);
    
        SELECT t.hl7_oid
          INTO l_hl7
          FROM terminology t
         WHERE t.internal_name = 'RXNORM';
    
        IF nvl(cardinality(o_id_rxnorm), 0) > 0
        THEN
            FOR i IN 1 .. o_id_rxnorm.count
            LOOP
                l_terminology.extend(1);
                l_terminology(l_terminology.count) := l_hl7;
            END LOOP;
        END IF;
    
        o_terminology := l_terminology;
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error);
            RETURN FALSE;
    END get_info_button_med_therap;

    /********************************************************************************************
    * alert_product_mt.pk_product.get_product_icons
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_SESSION_DATA                          IN        SESSION_DATA
    * @param  I_ID_PRODUCT                            IN        VARCHAR2(120)
    * @param  I_ID_PRODUCT_SUPPLIER                   IN        VARCHAR2(120)
    *
    * @return  VARCHAR2
    *
    * @author      Alexis Nascimento
    * @version     2.6.4.2.4
    * @since       18/11/2014
    *
    ********************************************************************************************/

    FUNCTION get_product_icons
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_product              IN VARCHAR2 DEFAULT NULL,
        i_id_product_supplier     IN VARCHAR2 DEFAULT NULL,
        i_tbl_id_product          IN table_varchar DEFAULT table_varchar(),
        i_tbl_id_product_supplier IN table_varchar DEFAULT table_varchar(),
        i_id_picklist             IN NUMBER DEFAULT NULL,
        i_id_grant                IN NUMBER DEFAULT NULL,
        i_chk_prod_restrictions   IN NUMBER DEFAULT 0,
        i_flg_needs_dilution      IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_product_icons(i_lang                    => i_lang,
                                               i_prof                    => i_prof,
                                               i_id_product              => i_id_product,
                                               i_id_product_supplier     => i_id_product_supplier,
                                               i_tbl_id_product          => i_tbl_id_product,
                                               i_tbl_id_product_supplier => i_tbl_id_product_supplier,
                                               i_id_picklist             => i_id_picklist,
                                               i_id_grant                => i_id_grant,
                                               i_chk_prod_restrictions   => i_chk_prod_restrictions,
                                               i_flg_needs_dilution      => i_flg_needs_dilution);
    END get_product_icons;

    FUNCTION get_product_search_by_name
    (
        i_lang              language.id_language%TYPE,
        i_prof              profissional,
        i_syn_str           IN VARCHAR2,
        i_prd_str           IN VARCHAR2,
        i_search            IN VARCHAR2,
        i_column_name       IN VARCHAR2,
        i_description_type  IN NUMBER,
        i_id_pick_list      IN NUMBER,
        i_id_market         IN NUMBER,
        i_flg_similar_prods IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_grant_group       IN NUMBER DEFAULT NULL
    ) RETURN t_tab_product_search IS
    BEGIN
        RETURN pk_rt_med_pfh.get_product_search_by_name(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_syn_str           => i_syn_str,
                                                        i_prd_str           => i_prd_str,
                                                        i_search            => i_search,
                                                        i_column_name       => i_column_name,
                                                        i_description_type  => i_description_type,
                                                        i_id_pick_list      => i_id_pick_list,
                                                        i_id_market         => i_id_market,
                                                        i_flg_similar_prods => i_flg_similar_prods,
                                                        i_grant_group       => i_grant_group);
    END get_product_search_by_name;

    /********************************************************************************************
    * alert_product_tr.pk_api_med_out.get_supply_source_pat_desc
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_PRESC                              IN        NUMBER(22,24)
    *
    * @return  VARCHAR2
    *
    * @author      Pedro Miranda
    * @version     
    * @since       02/12/2014
    *
    ********************************************************************************************/
    FUNCTION get_supply_source_pat_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_supply_source_pat_desc(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_supply_source_pat_desc;

    /********************************************************************************************
    * Gets the external prescription directions
    *
    * @param  i_lang              Language ID
    * @param  i_prof              Professional info array
    * @param  i_id_episode        Episode ID
    * @param  i_id_visit          Visit ID
    * @param  i_id_patient        Patient ID
    * @param  o_local_presc_dirs  Cursor with data
    * @param  o_error             Error object
    *
    * @return true/false
    *
    * @author Sofia Mendes
    * @since  12/12/2014
    *
    ********************************************************************************************/
    FUNCTION get_list_ext_presc_dirs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_visit   IN episode.id_visit%TYPE,
        i_id_patient IN episode.id_patient%TYPE,
        i_id_presc   IN presc.id_presc%TYPE,
        o_presc_dirs OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_med_pfh.get_list_ext_presc_dirs(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_id_episode => i_id_episode,
                                                     i_id_visit   => i_id_visit,
                                                     i_id_patient => i_id_patient,
                                                     i_id_presc   => i_id_presc,
                                                     o_presc_dirs => o_presc_dirs,
                                                     o_error      => o_error);
    
    END get_list_ext_presc_dirs;

    /********************************************************************************************
    * pk_api_pfh_in.get_std_version_date
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  O_ID_VERSION                            OUT       VARCHAR2
    * @param  O_PUBLISH_DATE                          OUT       VARCHAR2
    *
    *
    *
    * @author      Pedro Miranda
    * @version     
    * @since       24/12/2014
    * @issue       ALERT-293097
    *
    ********************************************************************************************/
    PROCEDURE get_std_version_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_id_version   OUT VARCHAR2,
        o_publish_date OUT VARCHAR2
    ) IS
    BEGIN
    
        pk_rt_med_pfh.get_std_version_date(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           o_id_version   => o_id_version,
                                           o_publish_date => o_publish_date);
    
    END get_std_version_date;

    /********************************************************************************************
    * Get the product price
    *
    * @param  i_lang                          Language ID
    * @param  i_prof                          Professional info array
    * @param  i_tbl_id_product                Product ID
    * @param  i_tbl_id_product_supplier       Product supplier ID
    * @param  i_id_price_type                 Price type ID
    *
    * @return Formatted text with product price
    *
    * @author Jose Brito
    * @since  30/12/2014
    *
    ********************************************************************************************/
    FUNCTION get_prod_unit_price
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_tbl_id_product          IN table_varchar DEFAULT table_varchar(),
        i_tbl_id_product_supplier IN table_varchar DEFAULT table_varchar(),
        i_id_price_type           IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_prod_unit_price(i_lang                    => i_lang,
                                                 i_prof                    => i_prof,
                                                 i_tbl_id_product          => i_tbl_id_product,
                                                 i_tbl_id_product_supplier => i_tbl_id_product_supplier,
                                                 i_id_price_type           => i_id_price_type);
    END get_prod_unit_price;

    /********************************************************************************************
    * Calculate the Rx overall treatment cost.
    *
    * @param  i_lang              Language ID
    * @param  i_prof              Professional info array
    * @param  i_id_episode        Episode ID
    * @param  i_id_patient        Patient ID
    * @param  i_id_presc_group    Prescription group ID
    *
    * @return Treatment cost by prescription group
    *
    * @author Jose Brito
    * @since  12/01/2015
    *
    ********************************************************************************************/
    FUNCTION calc_overall_treatment_cost
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_presc_group IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.calc_overall_treatment_cost(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_id_episode     => i_id_episode,
                                                         i_id_patient     => i_id_patient,
                                                         i_id_presc_group => i_id_presc_group);
    
    END calc_overall_treatment_cost;

    /********************************************************************************************
    * GET_MEDICATION_DESCRIPTION
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_PRESC                              IN        NUMBER(22,24)
    *
    * @return  VARCHAR2
    *
    * @author      Alexis Nascimento
    * @version     2.6.4.3
    * @since       30/12/2014
    *
    ********************************************************************************************/

    FUNCTION get_medication_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc        IN presc.id_presc%TYPE,
        i_id_co_sign_hist NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_medication_description(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_presc        => i_id_presc,
                                                        i_id_co_sign_hist => i_id_co_sign_hist);
    END get_medication_description;

    /********************************************************************************************
    * GET_MEDICATION_INSTRUCTIONS
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_PRESC                              IN        NUMBER(22,24)
    *
    * @return  VARCHAR2
    *
    * @author      Alexis Nascimento
    * @version     2.6.4.3
    * @since       30/12/2014
    *
    ********************************************************************************************/

    FUNCTION get_medication_instructions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc        IN presc.id_presc%TYPE,
        i_id_co_sign_hist IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_medication_instructions(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_presc        => i_id_presc,
                                                         i_id_co_sign_hist => i_id_co_sign_hist);
    END get_medication_instructions;

    FUNCTION get_cosign_action_description
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_task         NUMBER,
        i_id_action       IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_cosign_action_description(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_id_action       => i_id_action,
                                                           i_id_co_sign_hist => i_id_co_sign_hist);
    
    END get_cosign_action_description;

    /********************************************************************************************
    * alert_product_tr.pk_presc_cosign.get_med_admin_description
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_PRESC_PLAN                              IN        NUMBER(22,24)
    *
    * @return  VARCHAR2
    *
    * @author      Alexis Nascimento
    * @version     2.6.4.3
    * @since       30/12/2014
    *
    ********************************************************************************************/

    FUNCTION get_med_admin_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc_plan   IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_med_admin_description(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_presc_plan   => i_id_presc_plan,
                                                       i_id_co_sign_hist => i_id_co_sign_hist);
    END get_med_admin_description;

    /********************************************************************************************
    * alert_product_tr.pk_presc_cosign.get_med_admin_instructions
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  i_id_presc_plan                         IN        NUMBER(22,24)
    *
    * @return  VARCHAR2
    *
    * @author      Alexis Nascimento
    * @version     2.6.4.3
    * @since       30/12/2014
    *
    ********************************************************************************************/

    FUNCTION get_med_admin_instructions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc_plan   IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_med_admin_instructions(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_presc_plan   => i_id_presc_plan,
                                                        i_id_co_sign_hist => i_id_co_sign_hist);
    
    END get_med_admin_instructions;

    FUNCTION get_presc_doses_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN presc.id_patient%TYPE,
        i_id_presc     IN table_number,
        i_id_task_type IN NUMBER,
        i_tbl_xml      IN table_varchar DEFAULT NULL,
        o_doses_info   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_rt_med_pfh.get_presc_doses_info(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_id_patient   => i_id_patient,
                                                  i_id_presc     => i_id_presc,
                                                  i_tbl_xml      => i_tbl_xml,
                                                  i_id_task_type => i_id_task_type,
                                                  o_doses_info   => o_doses_info,
                                                  o_error        => o_error);
    
    END get_presc_doses_info;

    /********************************************************************************************
    * Updates the id cds call of the prescriptions associated to the i_products 
    * in the visit of the given id_episode
    *
    * @param  I_LANG                 language identifier                            
    * @param  I_PROF                 professional infor                          
    * @param  i_id_episode           episode id   
    * @param  i_id_product           Product Ids   
    * @param  i_id_product_supplier  Product supplier Ids                 
    * @param  i_id_call              cdr call id                    
    * @param  O_ERROR                error info                    
    *
    * @author      Sofia Mendes
    * @version     2.6.5
    * @since       28/05/2015
    ********************************************************************************************/
    FUNCTION set_presc_cds_id_call
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN presc.id_epis_upd%TYPE,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        i_id_call             IN NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_rt_med_pfh.set_presc_cds_id_call(i_lang                => i_lang,
                                                   i_prof                => i_prof,
                                                   i_id_episode          => i_id_episode,
                                                   i_id_product          => i_id_product,
                                                   i_id_product_supplier => i_id_product_supplier,
                                                   i_id_call             => i_id_call,
                                                   o_error               => o_error);
    
    END set_presc_cds_id_call;

    /********************************************************************************************
    * Get FLG_EDITED for a given prescription ID
    *
    * @param  I_LANG                 The language id
    * @param  I_PROF                 The profissional
    * @param  I_ID_PRESC             Prescription ID
    *
    * @return  PL/SQL VARCHAR2
    *
    * @author      Pedro Teixeira
    * @version     
    * @since       30/06/2015
    *
    ********************************************************************************************/
    FUNCTION get_presc_flg_edited
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_rt_med_pfh.get_presc_flg_edited(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END get_presc_flg_edited;

    /********************************************************************************************
    * alert_product_tr.pk_presc_core.get_presc_by_prod_search
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_EPISODE                            IN        NUMBER(22,24)
    * @param  I_SEARCH_VALUE                          IN        VARCHAR2
    *
    * @return  PUBLIC.TABLE_NUMBER
    *
    * @author      Alexis Nascimento
    * @version     2.6.5.0.3
    * @since       08/07/2015
    *
    ********************************************************************************************/

    FUNCTION get_presc_by_prod_search
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN presc.id_epis_create%TYPE,
        i_search_value          IN VARCHAR2,
        i_flg_search_by_patient IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN table_number IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_by_prod_search(i_lang                  => i_lang,
                                                      i_prof                  => i_prof,
                                                      i_id_episode            => i_id_episode,
                                                      i_search_value          => i_search_value,
                                                      i_flg_search_by_patient => i_flg_search_by_patient);
    
    END get_presc_by_prod_search;

    /*********************************************************************************************
    *  This function will return the product group description for group type configured
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              id prescription
    *
    * @return                        product group description
    *
    * @author                        Vitor Reis
    * @version                       2.6.5.0.3
    * @since                         2015/07/10
    *********************************************************************************************/

    FUNCTION get_product_category_descr
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     profissional,
        i_id_presc IN r_presc.id_presc%TYPE,
        i_id_grant IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        g_error := 'pk_api_pfg_in.get_product_category_descr';
    
        RETURN pk_rt_med_pfh.get_product_category_descr(i_lang                   => i_lang,
                                                        i_prof                   => i_prof,
                                                        i_id_presc               => i_id_presc,
                                                        i_id_grant               => i_id_grant,
                                                        i_flg_exclude_high_alert => pk_alert_constant.g_yes);
    
    END get_product_category_descr;

    /*********************************************************************************************
    *  This function will return the product group rank for group type configured
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              id prescription
    *
    * @return                        product group rank
    *
    * @author                        Vitor Reis
    * @version                       2.6.5.0.3
    * @since                         2015/07/10
    *********************************************************************************************/

    FUNCTION get_product_category_rank
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     profissional,
        i_id_presc IN r_presc.id_presc%TYPE,
        i_id_grant IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        g_error := 'pk_api_pfg_in.get_product_category_rank';
    
        RETURN pk_rt_med_pfh.get_product_category_rank(i_lang                   => i_lang,
                                                       i_prof                   => i_prof,
                                                       i_id_presc               => i_id_presc,
                                                       i_id_grant               => i_id_grant,
                                                       i_flg_exclude_high_alert => pk_alert_constant.g_yes);
    
    END get_product_category_rank;

    /*********************************************************************************************
    *  This function will return the number of prescriptions of all active institutions
    *
    * @param i_number_of_days        number(24)
    *
    * @return                        number 
    *
    * @author                        Alexis Nascimento
    * @version                       2.6.5.0.4
    * @since                         2015/08/11
    *********************************************************************************************/
    FUNCTION get_prescriptions_noc(i_number_of_days NUMBER DEFAULT NULL) RETURN NUMBER IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_prescriptions_noc(i_number_of_days);
    END get_prescriptions_noc;

    /*********************************************************************************************
    *  This function will return the product group id for a given prescription
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_presc              id prescription
    *
    * @return                        product group id
    *
    * @author                        Rui Mendonça
    * @version                       2.6.5.0.5
    * @since                         2015/09/21
    *********************************************************************************************/
    FUNCTION get_presc_category_id
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     profissional,
        i_id_presc IN presc.id_presc%TYPE,
        i_id_grant IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_category_id(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_id_presc => i_id_presc,
                                                   i_id_grant => i_id_grant);
    END get_presc_category_id;

    /*********************************************************************************************
    *  This function will return the prescription's start date
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_task               task id (prescription id)
    * @param i_id_co_sign_hist       
    * @return                        prescription start date
    *
    * @author                        Rui Mendonça
    * @version                       2.6.5.0.6
    * @since                         2015/10/06
    *********************************************************************************************/
    FUNCTION get_presc_start_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_start_date(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_id_task         => i_id_task,
                                                  i_id_co_sign_hist => i_id_co_sign_hist);
    END get_presc_start_date;

    /*********************************************************************************************
    *  This function will return the prescription interruption date
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_task               task id (prescription id)
    * @param i_id_co_sign_hist       
    * @return                        prescription interruption date
    *
    * @author                        Rui Mendonça
    * @version                       2.6.5.0.6
    * @since                         2015/10/06
    *********************************************************************************************/
    FUNCTION get_presc_interruption_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_interruption_date(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_task         => i_id_task,
                                                         i_id_co_sign_hist => i_id_co_sign_hist);
    END get_presc_interruption_date;

    /*********************************************************************************************
    *  This function will return the prescription suspension date
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_task               task id (prescription id)
    * @param i_id_co_sign_hist       
    * @return                        prescription suspension date
    *
    * @author                        Rui Mendonça
    * @version                       2.6.5.0.6
    * @since                         2015/10/06
    *********************************************************************************************/
    FUNCTION get_presc_suspension_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_suspension_date(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_task         => i_id_task,
                                                       i_id_co_sign_hist => i_id_co_sign_hist);
    END get_presc_suspension_date;

    /*********************************************************************************************
    *  This function will return the administration start date
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_task               task id (prescription id)
    * @param i_id_co_sign_hist       
    * @return                        administration start date
    *
    * @author                        Rui Mendonça
    * @version                       2.6.5.0.6
    * @since                         2015/10/06
    *********************************************************************************************/
    FUNCTION get_admin_start_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    BEGIN
        RETURN pk_rt_med_pfh.get_admin_start_date(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_id_task         => i_id_task,
                                                  i_id_co_sign_hist => i_id_co_sign_hist);
    END get_admin_start_date;

    /********************************************************************************************
    * Check if the product supplier are available in the market
    *
    * @param i_lang                The ID of the user language
    * @param i_prof                The profissional information array
    * @param i_id_product_supplier Product supplier id    
    *
    * @return                      VARCHAR2 ('Y' or 'N')
    *
    * @author                      CRISTINA.OLIVEIRA
    * @version                     2.6.5.1
    * @since                       2016/03/11
    ********************************************************************************************/
    FUNCTION check_supplier_mkt_available
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product_supplier IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_rt_med_pfh.check_supplier_mkt_available(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_id_product_supplier => i_id_product_supplier);
    
    END check_supplier_mkt_available;

    /*********************************************************************************************
    * Inserts given department id into tbl_temp
    *
    * @param i_lang             The ID of the user language
    * @param i_prof             Current professional
    * @param i_id_department    Department id
    *
    * @author                   rui.mendonca
    * @version                  2.6.5.2
    * @since                    2016/06/06
    **********************************************************************************************/
    PROCEDURE ins_prof_dept_into_tbl_temp
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN NUMBER
    ) IS
    BEGIN
        pk_rt_pha_pfh.ins_prof_dept_into_tbl_temp(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_id_department => i_id_department);
    END ins_prof_dept_into_tbl_temp;

    FUNCTION get_end_date_last_adm
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_end_date_last_adm(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END get_end_date_last_adm;

    /**************************************************************************
    **************************************************************************/
    FUNCTION get_favorite_prefix_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product_favorite IN NUMBER
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_rt_med_pfh.get_favorite_prefix_str(i_lang, i_prof, i_id_product_favorite);
    
    END get_favorite_prefix_str;

    /**************************************************************************
    **************************************************************************/
    FUNCTION get_favorite_suffix_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product_favorite IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_favorite_suffix_str(i_lang, i_prof, i_id_product_favorite);
    
    END get_favorite_suffix_str;

    /*********************************************************************************************
    * Returns the instructions descriptions to the favorites filter
    *
    * @param i_lang                         The ID of the user language
    * @param i_prof                         Current professional
    * @param i_id_product_favorite          Favorite ID
    * @param i_id_presc_directions          Presc directions ID
    *
    * @author                   Sofia Mendes
    * @version                  2.7.0
    * @since                    2016/12/02
    **********************************************************************************************/
    FUNCTION get_favorite_instructions_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product_favorite IN NUMBER,
        i_id_presc_directions IN NUMBER
    ) RETURN VARCHAR2 IS
        l_favorite_prefix VARCHAR2(32000);
        l_instr_descr     VARCHAR2(32000);
        l_favorite_suffix VARCHAR2(32000);
        l_descr           pk_translation.t_desc_translation;
        l_length_pre      NUMBER;
        l_length_suf      NUMBER;
    BEGIN
    
        l_favorite_prefix := pk_api_pfh_in.get_favorite_prefix_str(i_lang, i_prof, i_id_product_favorite);
    
        l_instr_descr := substr(get_presc_resumed_dir_str(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_id_product          => NULL,
                                                          i_id_product_supplier => NULL,
                                                          i_id_presc_dir        => i_id_presc_directions,
                                                          i_flg_with_dt_begin   => pk_alert_constant.g_no,
                                                          i_flg_with_dt_end     => pk_alert_constant.g_no),
                                1,
                                3850);
    
        l_favorite_suffix := pk_api_pfh_in.get_favorite_suffix_str(i_lang, i_prof, i_id_product_favorite);
    
        l_length_pre := length(l_favorite_prefix);
        l_length_suf := length(l_favorite_suffix);
    
        IF (length(l_instr_descr) + l_length_pre + l_length_suf >= 3800)
        THEN
            l_descr := l_favorite_prefix || substr(l_instr_descr, 1, 3800 - (l_length_pre + l_length_suf)) || '...' ||
                       l_favorite_suffix;
        ELSE
            l_descr := l_favorite_prefix || l_instr_descr || l_favorite_suffix;
        END IF;
    
        RETURN l_descr;
    END get_favorite_instructions_desc;

    /********************************************************************************************
    * Get the viewer checklist status for the medication area (home medication list)
    *
    * @param   i_lang            IN  language.id_language%TYPE
    * @param   i_prof            IN  profissional
    * @param   i_scope_type      IN  VARCHAR2
    * @param   i_episode         IN  episode.id_episode%TYPE
    * @param   i_patient         IN  patient.id_patient%TYPE
    * 
    * @return  'N' - No prescriptions
    *          'C' - All the prescriptions are finished
    *
    * @author          rui.mendonca
    * @version         2.7.0.0
    * @since           07/12/2016
    ********************************************************************************************/
    FUNCTION get_viewer_checklist_status_hm
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_viewer_checklist_status(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_episode   => i_episode,
                                                         i_id_patient   => i_patient,
                                                         i_scope_type   => i_scope_type,
                                                         i_call_context => pk_rt_med_pfh.g_vcc_home_med);
    END get_viewer_checklist_status_hm;

    /********************************************************************************************
    * Get the viewer checklist status for the medication area (local medication list)
    *
    * @param   i_lang            IN  language.id_language%TYPE
    * @param   i_prof            IN  profissional
    * @param   i_scope_type      IN  VARCHAR2
    * @param   i_episode         IN  episode.id_episode%TYPE
    * @param   i_patient         IN  patient.id_patient%TYPE
    * 
    * @return  'N' - No prescriptions
    *          'C' - All the prescriptions are finished
    *          'O' - Unfinished prescriptions / ongoing prescriptions
    *
    * @author          rui.mendonca
    * @version         2.7.0.0
    * @since           07/12/2016
    ********************************************************************************************/
    FUNCTION get_viewer_checklist_status_lm
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_viewer_checklist_status(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_episode   => i_episode,
                                                         i_id_patient   => i_patient,
                                                         i_scope_type   => i_scope_type,
                                                         i_call_context => pk_rt_med_pfh.g_vcc_local_med);
    END get_viewer_checklist_status_lm;

    /********************************************************************************************
    * Get the viewer checklist status for the medication area (ambulatory medication list)
    *
    * @param   i_lang            IN  language.id_language%TYPE
    * @param   i_prof            IN  profissional
    * @param   i_scope_type      IN  VARCHAR2
    * @param   i_episode         IN  episode.id_episode%TYPE
    * @param   i_patient         IN  patient.id_patient%TYPE
    * 
    * @return  'N' - No prescriptions
    *          'C' - All the prescriptions are finished
    *          'O' - Unfinished prescriptions / ongoing prescriptions
    *
    * @author          rui.mendonca
    * @version         2.7.0.0
    * @since           07/12/2016
    ********************************************************************************************/
    FUNCTION get_viewer_checklist_status_am
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_viewer_checklist_status(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_episode   => i_episode,
                                                         i_id_patient   => i_patient,
                                                         i_scope_type   => i_scope_type,
                                                         i_call_context => pk_rt_med_pfh.g_vcc_amb_med);
    END get_viewer_checklist_status_am;

    /********************************************************************************************
    * Get the viewer checklist status for the medication area (pharmacy validations)
    *
    * @param   i_lang            IN  language.id_language%TYPE
    * @param   i_prof            IN  profissional
    * @param   i_scope_type      IN  VARCHAR2
    * @param   i_episode         IN  episode.id_episode%TYPE
    * @param   i_patient         IN  patient.id_patient%TYPE
    * 
    * @return  'N' - No prescriptions
    *          'C' - All the prescriptions are finished
    *          'O' - Unfinished prescriptions / ongoing prescriptions
    *
    * @author          rui.mendonca
    * @version         2.7.0.0
    * @since           09/12/2016
    ********************************************************************************************/
    FUNCTION get_viewer_checklist_status_pv
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_viewer_checklist_status_pv(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_episode => i_episode,
                                                            i_id_patient => i_patient,
                                                            i_scope_type => i_scope_type);
    END get_viewer_checklist_status_pv;

    /********************************************************************************************
    * Get the pharmacy validation info icon if the pharmacist added any notes
    *
    * @param   i_lang      IN  language.id_language%TYPE
    * @param   i_prof      IN  profissional
    * @param   i_id_presc  IN  presc.id_presc%TYPE
    * 
    * @return  VARCHAR2
    *
    * @author          rui.mendonca
    * @version         2.7.0.0
    * @since           21/12/2016
    ********************************************************************************************/
    FUNCTION get_pharm_validation_info_icon
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_pharm_validation_info_icon(i_lang     => i_lang,
                                                            i_prof     => i_prof,
                                                            i_id_presc => i_id_presc);
    END get_pharm_validation_info_icon;

    /********************************************************************************************
    * Get the background color for the end date cell at the admin and tasks tab
    *
    * @param  i_lang     Language id
    * @param  i_prof     Professional type
    * @param  i_id_presc Prescription id
    *
    * @return VARCHAR2
    *
    * @author  rui.mendonca
    * @version 2.7.1.1
    * @since   23/06/2017
    ********************************************************************************************/
    FUNCTION get_dt_end_bg_color
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_dt_end_bg_color(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END get_dt_end_bg_color;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION add_print_list_jobs
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_id_presc                IN table_varchar,
        i_json_list               IN table_varchar,
        i_prescription_print_type IN VARCHAR2,
        o_print_list_job          OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'ADD_PRINT_LIST_JOBS';
    
    BEGIN
    
        IF NOT pk_rt_med_pfh.add_print_list_jobs(i_lang                    => i_lang,
                                                 i_prof                    => i_prof,
                                                 i_patient                 => i_patient,
                                                 i_episode                 => i_episode,
                                                 i_id_presc                => i_id_presc,
                                                 i_json_list               => i_json_list,
                                                 i_prescription_print_type => i_prescription_print_type,
                                                 o_print_list_job          => o_print_list_job,
                                                 o_error                   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END add_print_list_jobs;

    /********************************************************************************************
    * Get the pharmacy dispense details. Function for populating the grid with information
    * regarding the dispense status.Checks for interface information if there is no information 
    * associated
    *
    * @param   i_lang          language.id_language%TYPE
    * @param   i_prof          profissional
    * @param   i_id_presc      Prescription ID
    * 
    * @return  varchar
    *
    * @author   João Coutinho  
    * @version  2.7.2   
    * @since  15/11/2017
    ********************************************************************************************/
    FUNCTION get_pharm_dispense_details
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_presc            IN r_presc.id_presc%TYPE,
        i_id_pha_dispense     IN VARCHAR2,
        i_id_pha_dispense_det IN NUMBER DEFAULT NULL,
        i_id_pha_return       IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_DISPENSE_INFO';
        l_error      t_error_out;
        l_error_disp t_error_out;
        l_result     VARCHAR2(5000char);
        ---------------------------------------
    BEGIN
        IF NOT pk_rt_pha_pfh.get_pharm_dispense_details(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_presc            => i_id_presc,
                                                        i_id_pha_dispense     => i_id_pha_dispense,
                                                        i_id_pha_dispense_det => i_id_pha_dispense_det,
                                                        i_id_pha_return       => i_id_pha_return,
                                                        o_details_info        => l_result,
                                                        o_error               => l_error_disp)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_result IS NULL
        THEN
            l_result := pk_api_pfh_in.get_last_request_desc(i_lang, i_prof, i_id_presc);
        END IF;
        IF l_result IS NULL
        THEN
            l_result := pk_api_pfh_in.get_supply_source_pat_desc(i_lang, i_prof, i_id_presc);
        END IF;
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error);
            RETURN NULL;
        
    END get_pharm_dispense_details;

    /********************************************************************************************
    * Function to check if a certain cancelled dispensed should still be shown
    *
    * @param   i_lang             Language ID
    * @param   i_prof             Professional ID
    * @param   i_id_episode       Prescription ID
    * @param   i_id_pha_dispense  Dispense ID
    *
    * @return  VARCHAR
    *
    * @author          João Coutinho
    * @version         2.7.2.2
    * @since           13/12/2017
    ********************************************************************************************/
    FUNCTION get_pha_disp_cancel_show
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pha_dispense IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_pha_disp_cancel_show(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_episode      => i_id_episode,
                                                      i_id_pha_dispense => i_id_pha_dispense);
    END get_pha_disp_cancel_show;

    /**********************************************************************************************
    * Initialize params for filters - Pharmacy Dispense
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        João Coutinho
    * @version                       2.7.2.3
    * @since                         15/01/2018
    **********************************************************************************************/
    PROCEDURE init_params_pharm_dispense
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    BEGIN
        pk_rt_pha_pfh.init_params_pharm_dispense(i_filter_name   => i_filter_name,
                                                 i_custom_filter => i_custom_filter,
                                                 i_context_ids   => i_context_ids,
                                                 i_context_vals  => i_context_vals,
                                                 i_context_keys  => i_context_keys,
                                                 i_name          => i_name,
                                                 o_vc2           => o_vc2,
                                                 o_num           => o_num,
                                                 o_id            => o_id,
                                                 o_tstz          => o_tstz);
    
    END init_params_pharm_dispense;

    /**
    *  This function updates the episode temp id to the definitive one in the pharmacy table
    * To be used in match functionality
    *
    * @param      I_LANG                      Language id
    * @param      i_prof                      Professional, institution and software ids
    * @param      i_episode_temp              Temporary episode ID
    * @param      i_episode                   Definitive episode ID
    * @param      o_error                     Error message
    *
    * @return     BOOLEAN             TRUE if sucess, FALSE otherwise
    *
    * @author     Sofia Mendes
    * @since      16/01/2018
    */
    FUNCTION match_episode_pharmacy
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_rt_pha_pfh.match_episode_pharmacy(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_episode_temp => i_episode_temp,
                                                    i_episode      => i_episode,
                                                    o_error        => o_error);
    
    END match_episode_pharmacy;

    /**
    * This function updates the patient temp id to the definitive one in the pharmacy table.
    * To be used in match functionality
    *
    * @param      I_LANG                      Language id
    * @param      i_prof                      Professional, institution and software ids
    * @param      i_patient_temp              Temporary patient ID
    * @param      i_patient                   Definitive patient ID
    * @param      o_error                     Error message
    *
    * @return     BOOLEAN             TRUE if sucess, FALSE otherwise
    *
    * @author     Sofia Mendes
    * @since      16/01/2018
    */
    FUNCTION match_patient_pharmacy
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient_temp IN patient.id_patient%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_rt_pha_pfh.match_patient_pharmacy(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient_temp => i_patient_temp,
                                                    i_patient      => i_patient,
                                                    o_error        => o_error);
    
    END match_patient_pharmacy;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_pharm_presc_prop_by_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_presc  IN presc.id_presc%TYPE,
        i_prop_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_rt_pha_pfh.get_pharm_presc_prop_by_type(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_id_presc  => i_id_presc,
                                                          i_prop_type => i_prop_type);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pharm_presc_prop_by_type;

    FUNCTION get_dispense_return_icon
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pha_dispense IN NUMBER,
        i_id_pha_return   IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_dispense_return_icon(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_pha_dispense => i_id_pha_dispense,
                                                      i_id_pha_return   => i_id_pha_return);
    END get_dispense_return_icon;

    FUNCTION get_dispense_return_rank
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pha_dispense IN NUMBER,
        i_id_pha_return   IN NUMBER,
        i_id_task         IN NUMBER DEFAULT NULL
    ) RETURN NUMBER IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_dispense_return_rank(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_pha_dispense => i_id_pha_dispense,
                                                      i_id_pha_return   => i_id_pha_return,
                                                      i_id_task         => i_id_task);
    
    END get_dispense_return_rank;

    /******************************************************************************
    * get pharmacy status string
    ******************************************************************************/
    FUNCTION get_pharm_status_str
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_workflow     IN v_pha_review.id_workflow%TYPE,
        i_id_status       IN v_pha_review.id_status%TYPE,
        i_dt_status       IN v_pha_review.dt_status%TYPE,
        i_id_pha_dispense IN NUMBER DEFAULT NULL,
        i_id_pha_return   IN NUMBER DEFAULT NULL,
        i_id_presc        IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_rt_pha_pfh.get_pharm_status_str(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_id_workflow     => i_id_workflow,
                                                  i_id_status       => i_id_status,
                                                  i_dt_status       => i_dt_status,
                                                  i_id_pha_dispense => i_id_pha_dispense,
                                                  i_id_pha_return   => i_id_pha_return,
                                                  i_id_presc        => i_id_presc);
    END get_pharm_status_str;

    FUNCTION get_revised_prof_id
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_presc  IN presc.id_presc%TYPE,
        o_prof_name OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_rt_med_pfh.get_revised_prof_id(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_id_presc  => i_id_presc,
                                                 o_prof_name => o_prof_name,
                                                 o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REVISED_PROF_ID',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_revised_prof_id;

    FUNCTION get_pha_status_icon
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_pha_return    IN NUMBER,
        i_pha_dispense  IN NUMBER,
        i_status_review IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        k_workflow CONSTANT NUMBER := 57;
    BEGIN
    
        CASE
            WHEN i_pha_return IS NULL
                 AND i_pha_dispense IS NULL THEN
            
                l_return := pk_workflow.get_status_icon(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_workflow         => k_workflow,
                                                        i_id_status           => i_status_review,
                                                        i_id_category         => NULL,
                                                        i_id_profile_template => NULL,
                                                        i_id_functionality    => NULL,
                                                        i_param               => NULL);
            ELSE
                l_return := pk_api_pfh_in.get_dispense_return_icon(i_lang            => i_lang,
                                                                   i_prof            => i_prof,
                                                                   i_id_pha_dispense => i_pha_dispense,
                                                                   i_id_pha_return   => i_pha_return);
        END CASE;
    
        RETURN l_return;
    
    END get_pha_status_icon;

    FUNCTION get_pha_bg_color
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_pha_return   IN NUMBER,
        i_presc        IN NUMBER,
        i_pha_dispense IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        k_workflow CONSTANT NUMBER := 45;
    BEGIN
    
        CASE
            WHEN i_pha_return IS NULL THEN
                l_return := pk_api_pfh_in.get_presc_pharm_bg_color(i_lang, i_prof, i_presc, k_workflow, i_pha_dispense);
            ELSE
                NULL;
        END CASE;
    
        RETURN l_return;
    
    END get_pha_bg_color;

    FUNCTION get_correct_workflow
    (
        i_pha_return   IN NUMBER,
        i_pha_dispense IN NUMBER
    ) RETURN NUMBER IS
        l_return NUMBER;
    BEGIN
    
        CASE
            WHEN i_pha_return IS NULL
                 AND i_pha_dispense IS NULL THEN
                l_return := 57; -- review WF
            WHEN i_pha_return IS NULL
                 AND i_pha_dispense IS NOT NULL THEN
                l_return := 59; -- dispense WF
            ELSE
                l_return := 62; -- return WF
        END CASE;
    
        RETURN l_return;
    
    END get_correct_workflow;

    -- ********************************************
    FUNCTION get_correct_id_status
    (
        i_pha_return    IN NUMBER,
        i_pha_dispense  IN NUMBER,
        i_status_review IN NUMBER
    ) RETURN NUMBER IS
        l_return NUMBER;
    BEGIN
    
        CASE
            WHEN i_pha_return IS NULL
                 AND i_pha_dispense IS NULL THEN
                l_return := i_status_review;
            ELSE
                l_return := NULL;
        END CASE;
    
        RETURN l_return;
    
    END get_correct_id_status;

    -- ********************************************
    FUNCTION get_correct_dt_status
    (
        i_pha_return   IN NUMBER,
        i_pha_dispense IN NUMBER,
        i_dt_status    IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_return TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        CASE
            WHEN i_pha_return IS NULL
                 AND i_pha_dispense IS NULL THEN
                l_return := i_dt_status;
            ELSE
                l_return := NULL;
        END CASE;
    
        RETURN l_return;
    
    END get_correct_dt_status;

    -- *************************************************************
    FUNCTION get_pha_status_str
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_pha_return    IN NUMBER,
        i_pha_dispense  IN NUMBER,
        i_status_review IN NUMBER,
        i_dt_creat_disp IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_wkf       NUMBER;
        l_id_status NUMBER;
        l_dt_status TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_return VARCHAR2(4000);
    
    BEGIN
    
        l_wkf       := get_correct_workflow(i_pha_return, i_pha_dispense);
        l_id_status := get_correct_id_status(i_pha_return, i_pha_dispense, i_status_review);
        l_dt_status := get_correct_dt_status(i_pha_return, i_pha_dispense, i_dt_status => i_dt_creat_disp);
    
        l_return := pk_api_pfh_in.get_pharm_status_str(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_workflow     => l_wkf,
                                                       i_id_status       => l_id_status,
                                                       i_dt_status       => l_dt_status,
                                                       i_id_pha_dispense => i_pha_dispense,
                                                       i_id_pha_return   => i_pha_return);
    
        RETURN l_return;
    
    END get_pha_status_str;

    FUNCTION get_pha_cars
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list IS
    BEGIN
    
        RETURN pk_rt_pha_pfh.get_pha_cars(i_lang => i_lang, i_prof => i_prof);
    
    END get_pha_cars;
    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_allow_label_print
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_allow_label_print(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END get_allow_label_print;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_prepare_label_print_label
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_presc_plan IN NUMBER
    ) RETURN CLOB IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_prepare_label_print_label(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_id_episode    => i_id_episode,
                                                           i_id_presc_plan => i_id_presc_plan);
    END get_prepare_label_print_label;

    FUNCTION get_amb_dispense_print_label
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_code_patient_instructions IN pk_translation.t_desc_translation,
        i_id_pha_dispense           IN NUMBER,
        i_id_task                   IN NUMBER,
        i_id_patient                IN NUMBER,
        i_pat_name                  IN pk_translation.t_desc_translation,
        i_rownum                    IN NUMBER,
        i_nr_of_labels              IN NUMBER,
        i_cfg_value                 IN pk_translation.t_desc_translation,
        i_cfg_label_y_start         IN NUMBER DEFAULT NULL,
        i_cfg_label_y_increment     IN NUMBER DEFAULT NULL,
        i_cfg_label_height          IN NUMBER DEFAULT NULL,
        i_cfg_label_chars_by_line   IN NUMBER DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_amb_dispense_print_label(i_lang                      => i_lang,
                                                          i_prof                      => i_prof,
                                                          i_code_patient_instructions => i_code_patient_instructions,
                                                          i_id_pha_dispense           => i_id_pha_dispense,
                                                          i_id_task                   => i_id_task,
                                                          i_id_patient                => i_id_patient,
                                                          i_pat_name                  => i_pat_name,
                                                          i_rownum                    => i_rownum,
                                                          i_nr_of_labels              => i_nr_of_labels,
                                                          i_cfg_value                 => i_cfg_value,
                                                          i_cfg_label_y_start         => i_cfg_label_y_start,
                                                          i_cfg_label_y_increment     => i_cfg_label_y_increment,
                                                          i_cfg_label_height          => i_cfg_label_height,
                                                          i_cfg_label_chars_by_line   => i_cfg_label_chars_by_line);
    
    END get_amb_dispense_print_label;

    FUNCTION get_local_dispense_print_label
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_flg_single_label        IN VARCHAR2 DEFAULT 'N',
        i_id_pha_dispense         IN NUMBER DEFAULT NULL,
        i_id_product              IN pk_translation.t_desc_translation,
        i_id_product_supplier     IN pk_translation.t_desc_translation,
        i_qty_dispensed           IN NUMBER,
        i_id_unit_mea_dispensed   IN NUMBER,
        i_dt_expiration_product   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_task                 IN NUMBER,
        i_id_patient              IN NUMBER,
        i_id_episode              IN NUMBER,
        i_pat_name                IN pk_translation.t_desc_translation,
        i_rownum                  IN NUMBER,
        i_nr_of_labels            IN NUMBER,
        i_cfg_value               IN pk_translation.t_desc_translation,
        i_barcode                 IN VARCHAR2 DEFAULT NULL,
        i_cfg_label_y_start       IN NUMBER DEFAULT NULL,
        i_cfg_label_y_increment   IN NUMBER DEFAULT NULL,
        i_cfg_label_height        IN NUMBER DEFAULT NULL,
        i_cfg_label_chars_by_line IN NUMBER DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_local_dispense_print_label(i_lang                    => i_lang,
                                                            i_prof                    => i_prof,
                                                            i_flg_single_label        => i_flg_single_label,
                                                            i_id_pha_dispense         => i_id_pha_dispense,
                                                            i_id_product              => i_id_product,
                                                            i_id_product_supplier     => i_id_product_supplier,
                                                            i_qty_dispensed           => i_qty_dispensed,
                                                            i_id_unit_mea_dispensed   => i_id_unit_mea_dispensed,
                                                            i_dt_expiration_product   => i_dt_expiration_product,
                                                            i_id_task                 => i_id_task,
                                                            i_id_patient              => i_id_patient,
                                                            i_id_episode              => i_id_episode,
                                                            i_pat_name                => i_pat_name,
                                                            i_rownum                  => i_rownum,
                                                            i_nr_of_labels            => i_nr_of_labels,
                                                            i_cfg_value               => i_cfg_value,
                                                            i_barcode                 => i_barcode,
                                                            i_cfg_label_y_start       => i_cfg_label_y_start,
                                                            i_cfg_label_y_increment   => i_cfg_label_y_increment,
                                                            i_cfg_label_height        => i_cfg_label_height,
                                                            i_cfg_label_chars_by_line => i_cfg_label_chars_by_line);
    
    END get_local_dispense_print_label;

    FUNCTION is_product_high_alert
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        i_id_grant            IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
    
        --Call alert_product_mt to get product category of product obtained before
        RETURN pk_rt_med_pfh.is_product_high_alert(i_lang                => i_lang,
                                                   i_prof                => i_prof,
                                                   i_id_product          => i_id_product,
                                                   i_id_product_supplier => i_id_product_supplier,
                                                   i_id_grant            => i_id_grant);
    
    END is_product_high_alert;

    FUNCTION get_pha_depts
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list IS
    BEGIN
    
        RETURN pk_rt_pha_pfh.get_pha_depts(i_lang => i_lang, i_prof => i_prof);
    
    END get_pha_depts;

    FUNCTION get_review_refill_date
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN r_presc.id_last_episode%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_rt_pha_pfh.get_review_refill_date(i_lang => i_lang, i_id_episode => i_id_episode);
    
    END get_review_refill_date;

    /********************************************************************************************
    * Function that returns the products description associated to a dispense record
    *
    * @param i_lang              IN  language.id_language%TYPE      Language ID
    * @param i_prof              IN  profissional                   Professional structure data
    * @param i_id_pha_dispense   Pha dispense id
    * @param i_id_task           Prescription id
    * @param i_id_task_type      Task type id
    *
    * @author   Sofia Mendes
    * @version  2.7.3
    * @since    17/05/2018            
    ********************************************************************************************/
    FUNCTION get_dispense_products_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pha_dispense IN NUMBER,
        i_id_task         IN NUMBER,
        i_id_task_type    IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_dispense_products_desc(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_pha_dispense => i_id_pha_dispense,
                                                        i_id_task         => i_id_task,
                                                        i_id_task_type    => i_id_task_type);
    
    END get_dispense_products_desc;

    FUNCTION inactivate_presc_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_rt_med_pfh.inactivate_presc_tasks(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_inst      => i_inst,
                                                    o_has_error => o_has_error,
                                                    o_error     => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'INACTIVATE_PRESC_TASKS',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END inactivate_presc_tasks;

    FUNCTION get_dt_last_take
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    BEGIN
        RETURN pk_rt_med_pfh.get_dt_last_take(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END get_dt_last_take;

    FUNCTION get_count_dt_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN NUMBER,
        i_id_workflow IN NUMBER
        
    ) RETURN NUMBER IS
    
    BEGIN
        RETURN pk_rt_pha_pfh.get_count_dt_status(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_id_episode  => i_id_episode,
                                                 i_id_workflow => i_id_workflow);
    END get_count_dt_status;

    PROCEDURE init_params_patient_grids
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
    BEGIN
        pk_rt_pha_pfh.init_params_patient_grids(i_filter_name   => i_filter_name,
                                                i_custom_filter => i_custom_filter,
                                                i_context_ids   => i_context_ids,
                                                i_context_keys  => i_context_keys,
                                                i_context_vals  => i_context_vals,
                                                i_name          => i_name,
                                                o_vc2           => o_vc2,
                                                o_num           => o_num,
                                                o_id            => o_id,
                                                o_tstz          => o_tstz);
    
    END init_params_patient_grids;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_presc_home_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN NUMBER,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_home_discharge(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_episode => i_id_episode,
                                                      o_info       => o_info,
                                                      o_error      => o_error);
    END get_presc_home_discharge;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_presc_prod_restrictions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_presc     IN NUMBER,
        i_id_pick_list IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
    BEGIN
    
        --Call alert_product_mt to get product category of product obtained before
        RETURN pk_rt_med_pfh.get_presc_prod_restrictions(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_presc     => i_id_presc,
                                                         i_id_pick_list => i_id_pick_list);
    
    END get_presc_prod_restrictions;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_check_co_sign
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN alert.profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_check_co_sign(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    
    END get_check_co_sign;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_check_prod_pat_weight
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_presc                  IN NUMBER,
        o_id_patient                OUT patient.id_patient%TYPE,
        o_flg_prod_weight_mandatory OUT VARCHAR2,
        o_flg_invalid_weighing      OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_check_prod_pat_weight(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_id_presc                  => i_id_presc,
                                                       o_id_patient                => o_id_patient,
                                                       o_flg_prod_weight_mandatory => o_flg_prod_weight_mandatory,
                                                       o_flg_invalid_weighing      => o_flg_invalid_weighing);
    END get_check_prod_pat_weight;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_pharm_car_icon
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_pha_car IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_rt_pha_pfh.get_pharm_car_icon(i_lang => i_lang, i_prof => i_prof, i_id_pha_car => i_id_pha_car);
    
    END get_pharm_car_icon;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION count_patient_by_car
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_pha_car IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
    
        RETURN pk_rt_pha_pfh.count_patient_by_car(i_lang => i_lang, i_prof => i_prof, i_id_pha_car => i_id_pha_car);
    
    END count_patient_by_car;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION location_by_car
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_status    IN NUMBER,
        i_desc_service IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_rt_pha_pfh.location_by_car(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_id_status    => i_id_status,
                                             i_desc_service => i_desc_service);
    
    END location_by_car;

    /********************************************************************************************
    ********************************************************************************************/

    FUNCTION get_prepare_ivroom_print_label
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_dispense   IN NUMBER,
        i_id_presc_plan IN NUMBER
    ) RETURN CLOB IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_prepare_ivroom_print_label(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_id_episode    => i_id_episode,
                                                            i_id_dispense   => i_id_dispense,
                                                            i_id_presc_plan => i_id_presc_plan);
    
    END get_prepare_ivroom_print_label;

    /*******************************************************************************
    *******************************************************************************/
    FUNCTION get_all_product_routes
    (
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2
    ) RETURN table_varchar IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_all_product_routes(i_id_product          => i_id_product,
                                                    i_id_product_supplier => i_id_product_supplier);
    END get_all_product_routes;

    /*******************************************************************************
    *******************************************************************************/
    FUNCTION get_all_product_inn
    (
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2
    ) RETURN table_varchar IS
    
    BEGIN
    
        RETURN pk_rt_med_pfh.get_all_product_inn(i_id_product          => i_id_product,
                                                 i_id_product_supplier => i_id_product_supplier);
    END get_all_product_inn;

    /*******************************************************************************
    *******************************************************************************/
    FUNCTION inactivate_pharm_dispense
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_rt_pha_pfh.inactivate_pharm_dispense(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_inst      => i_inst,
                                                       o_has_error => o_has_error,
                                                       o_error     => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'INACTIVATE_PHARM_DISPENSE',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END inactivate_pharm_dispense;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_pharm_dispense_ivroom_rank
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pha_dispense IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_pharm_dispense_ivroom_rank(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_id_pha_dispense => i_id_pha_dispense);
    
    END get_pharm_dispense_ivroom_rank;

    /*******************************************************************************
    *******************************************************************************/
    FUNCTION get_product_price_lst
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_id_patient          IN NUMBER
    ) RETURN table_varchar IS
    BEGIN
        RETURN pk_rt_med_pfh.get_product_price_lst(i_lang                => i_lang,
                                                   i_prof                => i_prof,
                                                   i_id_product          => i_id_product,
                                                   i_id_product_supplier => i_id_product_supplier,
                                                   i_id_patient          => i_id_patient);
    END get_product_price_lst;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION get_presc_out_on_pass
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN presc.id_epis_create%TYPE,
        i_first_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_last_date  IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_presc_data OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_out_on_pass(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_episode => i_id_episode,
                                                   i_first_date => i_first_date,
                                                   i_last_date  => i_last_date,
                                                   o_presc_data => o_presc_data,
                                                   o_error      => o_error);
    END get_presc_out_on_pass;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION set_presc_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN presc.id_epis_create%TYPE,
        i_id_presc            IN table_number,
        i_id_epis_out_on_pass IN NUMBER,
        i_first_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_last_date           IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_rt_med_pfh.set_presc_out_on_pass(i_lang                => i_lang,
                                                   i_prof                => i_prof,
                                                   i_id_episode          => i_id_episode,
                                                   i_id_presc            => i_id_presc,
                                                   i_id_epis_out_on_pass => i_id_epis_out_on_pass,
                                                   i_first_date          => i_first_date,
                                                   i_last_date           => i_last_date,
                                                   o_error               => o_error);
    END set_presc_out_on_pass;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION complete_presc_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN presc.id_epis_create%TYPE,
        i_id_epis_out_on_pass IN NUMBER,
        i_dt_in_returned      IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_rt_med_pfh.complete_presc_out_on_pass(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_episode          => i_id_episode,
                                                        i_id_epis_out_on_pass => i_id_epis_out_on_pass,
                                                        i_dt_in_returned      => i_dt_in_returned,
                                                        o_error               => o_error);
    END complete_presc_out_on_pass;

    FUNCTION get_presc_out_on_pass_complete
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN presc.id_epis_create%TYPE,
        i_id_epis_out_on_pass     IN NUMBER,
        i_flg_html                IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_force_pp_oop_status IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        o_presc_data              OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_out_on_pass_complete(i_lang                    => i_lang,
                                                            i_prof                    => i_prof,
                                                            i_id_episode              => i_id_episode,
                                                            i_id_epis_out_on_pass     => i_id_epis_out_on_pass,
                                                            i_flg_html                => i_flg_html,
                                                            i_flg_force_pp_oop_status => i_flg_force_pp_oop_status,
                                                            o_presc_data              => o_presc_data,
                                                            o_error                   => o_error);
    END get_presc_out_on_pass_complete;

    PROCEDURE init_params_cars
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
    BEGIN
    
        pk_rt_pha_pfh.init_params_cars(i_filter_name   => i_filter_name,
                                       i_custom_filter => i_custom_filter,
                                       i_context_ids   => i_context_ids,
                                       i_context_vals  => i_context_vals,
                                       i_name          => i_name,
                                       o_vc2           => o_vc2,
                                       o_num           => o_num,
                                       o_id            => o_id,
                                       o_tstz          => o_tstz);
    
    END init_params_cars;

    FUNCTION get_unidose_services
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain IS
        l_ret t_tbl_core_domain;
    BEGIN
    
        g_error := 'INIT get_unidose_services';
        SELECT t_row_core_domain(internal_name => i_internal_name,
                                 desc_domain   => d.desc_department,
                                 domain_value  => d.id_department,
                                 order_rank    => NULL,
                                 img_name      => NULL)
        
          BULK COLLECT
          INTO l_ret
          FROM (SELECT dep.id_department, pk_translation.get_translation(i_lang, dep.code_department) desc_department
                  FROM department dep
                 WHERE dep.id_institution = i_prof.institution
                   AND dep.flg_available = pk_alert_constant.g_yes
                   AND dep.flg_unidose = pk_alert_constant.g_yes
                 ORDER BY upper(desc_department)) d;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_UNIDOSE_SERVICES',
                                              o_error    => o_error);
            RETURN NULL;
    END get_unidose_services;

    FUNCTION get_pharm_slots
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_pharm_slots(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_internal_name => i_internal_name,
                                             o_error         => o_error);
    END get_pharm_slots;

    /********************************************************************************************
    * Get default values for the dynamic screen creation of car configurations by service
    *
    * @param   i_tbl_id_pk    receives id_pha_car_model
    *
    * @author          Sofia Mendes
    * @since           05/12/2019
    ********************************************************************************************/
    FUNCTION get_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    BEGIN
        IF i_root_name IN ('DS_MED_ERRORS',
                           'DS_MED_LOCAL_PRESC',
                           'DS_MED_ADM_COMPLETE',
                           'DS_MED_ADM_DRIP',
                           'DS_MED_ADM_DISCONTINUE',
                           'DS_MED_ADM_EDIT_DT_END',
                           'DS_MED_ADM_COND_ORDER',
                           'DS_MED_OTHER_FREQUENCIES')
        THEN
            RETURN pk_rt_med_pfh.get_values(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_episode        => i_episode,
                                            i_patient        => i_patient,
                                            i_action         => i_action,
                                            i_root_name      => i_root_name,
                                            i_curr_component => i_curr_component,
                                            i_tbl_id_pk      => i_tbl_id_pk,
                                            i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                            i_value          => i_value,
                                            o_error          => o_error);
        ELSE
            --DS_PHA_CARTS_CONFIGS, DS_PHA_UNIDOSE_ORDERS
            RETURN pk_rt_pha_pfh.get_values(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_episode        => i_episode,
                                            i_patient        => i_patient,
                                            i_action         => i_action,
                                            i_root_name      => i_root_name,
                                            i_curr_component => i_curr_component,
                                            i_tbl_id_pk      => i_tbl_id_pk,
                                            i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                            i_value          => i_value,
                                            o_error          => o_error);
        END IF;
    END get_values;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_pha_car_model_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pha_car_model IN NUMBER,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_pha_car_model_det(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_id_pha_car_model => i_id_pha_car_model,
                                                   o_detail           => o_detail,
                                                   o_error            => o_error);
    
    END get_pha_car_model_det;
    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_pha_car_model_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pha_car_model IN NUMBER,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_pha_car_model_hist(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_id_pha_car_model => i_id_pha_car_model,
                                                    o_detail           => o_detail,
                                                    o_error            => o_error);
    END get_pha_car_model_hist;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_prescs_grouped_by_prod
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_flg_antibiotic   IN VARCHAR2,
        i_last_x_h         IN NUMBER DEFAULT NULL,
        o_grouped_products OUT t_tbl_prescs_grouped_by_prod,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESCS_GROUPED_BY_PROD';
    BEGIN
        RETURN pk_rt_med_pfh.get_prescs_grouped_by_prod(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_id_episode       => i_id_episode,
                                                        i_flg_antibiotic   => i_flg_antibiotic,
                                                        i_last_x_h         => i_last_x_h,
                                                        o_grouped_products => o_grouped_products,
                                                        o_error            => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prescs_grouped_by_prod;

    FUNCTION get_light_license_credits
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_LIGHT_LICENSE_CREDITS';
        l_error_out t_error_out;
    BEGIN
    
        RETURN pk_rt_med_pfh.get_light_license_credits(i_lang => i_lang, i_prof => i_prof);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error_out);
            RAISE;
    END;

    /*************************************************************************************************
    *************************************************************************************************/
    FUNCTION presc_is_copy_other_epis
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.presc_is_copy_other_epis(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END presc_is_copy_other_epis;

    /*************************************************************************************************
    *************************************************************************************************/
    FUNCTION get_allow_show_all_med
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_allow_show_all_med(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END get_allow_show_all_med;

    PROCEDURE init_params_reconciliation
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
    BEGIN
    
        g_error := 'call pk_rt_med_pfh.init_params_reconciliation';
        pk_rt_med_pfh.init_params_reconciliation(i_filter_name   => i_filter_name,
                                                 i_custom_filter => i_custom_filter,
                                                 i_context_ids   => i_context_ids,
                                                 i_context_vals  => i_context_vals,
                                                 i_name          => i_name,
                                                 o_vc2           => o_vc2,
                                                 o_num           => o_num,
                                                 o_id            => o_id,
                                                 o_tstz          => o_tstz);
    
    END init_params_reconciliation;

    FUNCTION get_presc_icon_untyped(i_id_presc IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_icon_untyped(i_id_presc => i_id_presc);
    END get_presc_icon_untyped;

    FUNCTION is_parent_presc_pending_val
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.is_parent_presc_pending_val(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END is_parent_presc_pending_val;

    FUNCTION check_presc_migrated(i_id_presc IN NUMBER) RETURN VARCHAR IS
    BEGIN
        RETURN pk_rt_med_pfh.check_presc_migrated(i_id_presc => i_id_presc);
    END check_presc_migrated;

    FUNCTION presc_is_home_care
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.presc_is_home_care(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END presc_is_home_care;

    FUNCTION presc_is_episode_home_care
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_presc   IN NUMBER,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.presc_is_episode_home_care(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_presc   => i_id_presc,
                                                        i_id_episode => i_id_episode);
    END presc_is_episode_home_care;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION presc_is_prod_visit_active
    (
        i_id_unique IN VARCHAR2,
        i_id_visit  IN episode.id_visit%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_rt_med_pfh.presc_is_prod_visit_active(i_id_unique => i_id_unique, i_id_visit => i_id_visit);
    END presc_is_prod_visit_active;

    FUNCTION get_clinical_purpose_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN presc.id_patient%TYPE,
        i_id_episode          IN presc.id_epis_create%TYPE,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        i_id_presc_type_rel   IN NUMBER,
        o_info                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_med_pfh.get_clinical_purpose_list(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_patient          => i_id_patient,
                                                       i_id_episode          => i_id_episode,
                                                       i_id_product          => i_id_product,
                                                       i_id_product_supplier => i_id_product_supplier,
                                                       i_id_presc_type_rel   => i_id_presc_type_rel,
                                                       o_info                => o_info,
                                                       o_error               => o_error);
    END get_clinical_purpose_list;

    FUNCTION get_clinical_purpose_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN presc.id_patient%TYPE,
        i_id_episode          IN presc.id_epis_create%TYPE,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        i_id_presc_type_rel   IN NUMBER
    ) RETURN t_tbl_core_domain IS
        l_error           t_error_out;
        l_info            pk_types.cursor_type;
        l_ret             t_tbl_core_domain := t_tbl_core_domain();
        l_data            NUMBER(24);
        l_label           VARCHAR2(200 CHAR);
        l_type            VARCHAR2(200 CHAR);
        l_subtype         VARCHAR2(200 CHAR);
        l_rank            VARCHAR2(200 CHAR);
        l_value           VARCHAR2(200 CHAR);
        l_unit            VARCHAR2(200 CHAR);
        l_unitdesc        VARCHAR2(200 CHAR);
        l_code_domain     VARCHAR2(200 CHAR);
        l_text            VARCHAR2(200 CHAR);
        l_notes_mandatory VARCHAR2(3000 CHAR);
        l_internal_name   ds_cmpt_mkt_rel.internal_name_child%TYPE;
    BEGIN
    
        IF NOT pk_rt_med_pfh.get_clinical_purpose_list(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_patient          => i_id_patient,
                                                       i_id_episode          => i_id_episode,
                                                       i_id_product          => i_id_product,
                                                       i_id_product_supplier => i_id_product_supplier,
                                                       i_id_presc_type_rel   => i_id_presc_type_rel,
                                                       o_info                => l_info,
                                                       o_error               => l_error)
        THEN
            RAISE g_exception;
        END IF;
        LOOP
            FETCH l_info
                INTO l_data,
                     l_label,
                     l_type,
                     l_subtype,
                     l_rank,
                     l_value,
                     l_unit,
                     l_unitdesc,
                     l_code_domain,
                     l_text,
                     l_notes_mandatory;
            EXIT WHEN l_info%NOTFOUND;
            l_ret.extend;
            l_ret(l_ret.count) := t_row_core_domain(l_internal_name, l_label, to_char(l_data), l_rank, NULL);
        
        END LOOP;
    
        RETURN l_ret;
    END get_clinical_purpose_list;

    FUNCTION get_diag_problem_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN presc.id_patient%TYPE,
        i_id_episode IN presc.id_epis_create%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_med_pfh.get_diag_problem_list(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_patient => i_id_patient,
                                                   i_id_episode => i_id_episode,
                                                   o_info       => o_info,
                                                   o_error      => o_error);
    END get_diag_problem_list;

    FUNCTION get_diag_problem_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN presc.id_patient%TYPE,
        i_id_episode IN presc.id_epis_create%TYPE
    ) RETURN t_tbl_core_domain IS
        l_error             t_error_out;
        l_info              pk_types.cursor_type;
        l_ret               t_tbl_core_domain := t_tbl_core_domain();
        l_id_diagnosis      VARCHAR2(200 CHAR);
        l_label             VARCHAR2(200 CHAR);
        l_type              VARCHAR2(200 CHAR);
        l_subtype           VARCHAR2(200 CHAR);
        l_rank              VARCHAR2(200 CHAR);
        l_value             VARCHAR2(200 CHAR);
        l_unit              VARCHAR2(200 CHAR);
        l_unitdesc          VARCHAR2(200 CHAR);
        l_code_domain       VARCHAR2(200 CHAR);
        l_text              VARCHAR2(200 CHAR);
        l_id_task           VARCHAR2(200 CHAR);
        l_id_task_type_func VARCHAR2(200 CHAR);
        l_data              VARCHAR2(200 CHAR);
        l_internal_name     ds_cmpt_mkt_rel.internal_name_child%TYPE;
    BEGIN
    
        IF NOT pk_rt_med_pfh.get_diag_problem_list(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_patient => i_id_patient,
                                                   i_id_episode => i_id_episode,
                                                   o_info       => l_info,
                                                   o_error      => l_error)
        THEN
            RAISE g_exception;
        END IF;
        LOOP
            FETCH l_info
                INTO l_id_diagnosis,
                     l_label,
                     l_type,
                     l_subtype,
                     l_rank,
                     l_value,
                     l_unit,
                     l_unitdesc,
                     l_code_domain,
                     l_text,
                     l_id_task,
                     l_id_task_type_func,
                     l_data;
            EXIT WHEN l_info%NOTFOUND;
            l_ret.extend;
            l_ret(l_ret.count) := t_row_core_domain(l_internal_name, l_label, l_data, l_rank, NULL);
        
        END LOOP;
    
        RETURN l_ret;
    
    END get_diag_problem_list;

    FUNCTION get_presc_list_by_type
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2 DEFAULT NULL,
        i_id_product_supplier IN VARCHAR2 DEFAULT NULL,
        i_presc_list_type     IN NUMBER,
        o_info                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_list_by_type(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_id_product          => i_id_product,
                                                    i_id_product_supplier => i_id_product_supplier,
                                                    i_presc_list_type     => i_presc_list_type,
                                                    o_info                => o_info,
                                                    o_error               => o_error);
    END get_presc_list_by_type;

    FUNCTION get_presc_list_by_type
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2 DEFAULT NULL,
        i_id_product_supplier IN VARCHAR2 DEFAULT NULL,
        i_presc_list_type     IN NUMBER
    ) RETURN t_tbl_core_domain IS
        l_error         t_error_out;
        l_info          pk_types.cursor_type;
        l_ret           t_tbl_core_domain := t_tbl_core_domain();
        l_data          VARCHAR2(200 CHAR);
        l_label         VARCHAR2(200 CHAR);
        l_type          VARCHAR2(200 CHAR);
        l_subtype       VARCHAR2(200 CHAR);
        l_rank          VARCHAR2(200 CHAR);
        l_value         VARCHAR2(200 CHAR);
        l_unit          VARCHAR2(200 CHAR);
        l_unitdesc      VARCHAR2(200 CHAR);
        l_flg_default   VARCHAR2(1 CHAR);
        l_internal_name ds_cmpt_mkt_rel.internal_name_child%TYPE;
    BEGIN
    
        IF NOT pk_rt_med_pfh.get_presc_list_by_type(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_id_product          => i_id_product,
                                                    i_id_product_supplier => i_id_product_supplier,
                                                    i_presc_list_type     => i_presc_list_type,
                                                    o_info                => l_info,
                                                    o_error               => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        LOOP
            FETCH l_info
                INTO l_data, l_label, l_type, l_subtype, l_rank, l_value, l_unit, l_unitdesc, l_flg_default;
            EXIT WHEN l_info%NOTFOUND;
            l_ret.extend;
            l_ret(l_ret.count) := t_row_core_domain(l_internal_name, l_label, l_data, l_rank, NULL);
        
        END LOOP;
    
        RETURN l_ret;
    END get_presc_list_by_type;

    FUNCTION get_admin_method_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_route          IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE,
        o_info              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_med_pfh.get_admin_method_list(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_id_route          => i_id_route,
                                                   i_id_route_supplier => i_id_route_supplier,
                                                   o_info              => o_info,
                                                   o_error             => o_error);
    END get_admin_method_list;

    FUNCTION get_admin_method_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_route          IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE
    ) RETURN t_tbl_core_domain IS
        l_error         t_error_out;
        l_info          pk_types.cursor_type;
        l_ret           t_tbl_core_domain := t_tbl_core_domain();
        l_data          VARCHAR2(200 CHAR);
        l_label         VARCHAR2(200 CHAR);
        l_type          VARCHAR2(200 CHAR);
        l_subtype       VARCHAR2(200 CHAR);
        l_rank          VARCHAR2(200 CHAR);
        l_value         VARCHAR2(200 CHAR);
        l_unit          VARCHAR2(200 CHAR);
        l_unitdesc      VARCHAR2(200 CHAR);
        l_internal_name ds_cmpt_mkt_rel.internal_name_child%TYPE;
    BEGIN
    
        IF NOT pk_rt_med_pfh.get_admin_method_list(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_id_route          => i_id_route,
                                                   i_id_route_supplier => i_id_route_supplier,
                                                   o_info              => l_info,
                                                   o_error             => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        LOOP
            FETCH l_info
                INTO l_data, l_label, l_type, l_subtype, l_rank, l_value, l_unit, l_unitdesc;
            EXIT WHEN l_info%NOTFOUND;
            l_ret.extend;
            l_ret(l_ret.count) := t_row_core_domain(l_internal_name, l_label, l_data, l_rank, NULL);
        
        END LOOP;
    
        RETURN l_ret;
    END get_admin_method_list;

    FUNCTION get_admin_site_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_route          IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE,
        o_info              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rt_med_pfh.get_admin_site_list(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_route          => i_id_route,
                                                 i_id_route_supplier => i_id_route_supplier,
                                                 o_info              => o_info,
                                                 o_error             => o_error);
    END get_admin_site_list;

    FUNCTION get_admin_site_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_route          IN pk_rt_med_pfh.r_presc_dir.id_route%TYPE,
        i_id_route_supplier IN pk_rt_med_pfh.r_presc_dir.id_route_supplier%TYPE
    ) RETURN t_tbl_core_domain IS
        l_error         t_error_out;
        l_info          pk_types.cursor_type;
        l_ret           t_tbl_core_domain := t_tbl_core_domain();
        l_data          VARCHAR2(200 CHAR);
        l_label         VARCHAR2(200 CHAR);
        l_type          VARCHAR2(200 CHAR);
        l_subtype       VARCHAR2(200 CHAR);
        l_rank          VARCHAR2(200 CHAR);
        l_value         VARCHAR2(200 CHAR);
        l_unit          VARCHAR2(200 CHAR);
        l_unitdesc      VARCHAR2(200 CHAR);
        l_internal_name ds_cmpt_mkt_rel.internal_name_child%TYPE;
    BEGIN
    
        IF NOT pk_rt_med_pfh.get_admin_site_list(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_route          => i_id_route,
                                                 i_id_route_supplier => i_id_route_supplier,
                                                 o_info              => l_info,
                                                 o_error             => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        LOOP
            FETCH l_info
                INTO l_data, l_label, l_type, l_subtype, l_rank, l_value, l_unit, l_unitdesc;
            EXIT WHEN l_info%NOTFOUND;
            l_ret.extend;
            l_ret(l_ret.count) := t_row_core_domain(l_internal_name, l_label, l_data, l_rank, NULL);
        
        END LOOP;
    
        RETURN l_ret;
    END get_admin_site_list;

    /*********************************************************************************************
    *  This function will return the prescription resume date
    *
    * @param i_lang                  id language
    * @param i_prof                  array with the professional information
    * @param i_id_task               task id (prescription id)
    * @param i_id_co_sign_hist       
    * @return                        prescription suspension date
    *
    * @author                        Cristina Oliveira
    * @version                       2.8.3.1
    * @since                         2021/07/23
    *********************************************************************************************/
    FUNCTION get_presc_resume_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN NUMBER,
        i_id_co_sign_hist IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_resume_date(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_task         => i_id_task,
                                                   i_id_co_sign_hist => i_id_co_sign_hist);
    END get_presc_resume_date;

    FUNCTION get_cancel_reasons_by_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_presc_list_type IN NUMBER
    ) RETURN t_tbl_core_domain IS
        l_error           t_error_out;
        l_info            pk_types.cursor_type;
        l_ret             t_tbl_core_domain := t_tbl_core_domain();
        l_internal_name   ds_cmpt_mkt_rel.internal_name_child%TYPE;
        l_id_reason       VARCHAR2(200 CHAR);
        l_reason_desc     VARCHAR2(200 CHAR);
        l_notes_mandatory VARCHAR2(200 CHAR);
        l_flg_error       VARCHAR2(1 CHAR);
    BEGIN
        IF NOT pk_rt_med_pfh.get_cancel_reasons_by_type(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_presc_list_type => i_presc_list_type,
                                                        o_info            => l_info,
                                                        o_error           => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        LOOP
            FETCH l_info
                INTO l_id_reason, l_reason_desc, l_notes_mandatory, l_flg_error;
            EXIT WHEN l_info%NOTFOUND;
            l_ret.extend;
            l_ret(l_ret.count) := t_row_core_domain(l_internal_name, l_reason_desc, l_id_reason, NULL, NULL);
        
        END LOOP;
    
        RETURN l_ret;
    
    END get_cancel_reasons_by_type;

    FUNCTION get_presc_rate_by_type
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_presc_list_type     IN NUMBER,
        i_context             IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_core_domain IS
        l_error         t_error_out;
        l_info          pk_types.cursor_type;
        l_ret           t_tbl_core_domain := t_tbl_core_domain();
        l_data          VARCHAR2(200 CHAR);
        l_label         VARCHAR2(200 CHAR);
        l_context       VARCHAR2(200 CHAR);
        l_type          VARCHAR2(200 CHAR);
        l_subtype       VARCHAR2(200 CHAR);
        l_value         VARCHAR2(200 CHAR);
        l_unit          VARCHAR2(200 CHAR);
        l_unitdesc      VARCHAR2(200 CHAR);
        l_rank          VARCHAR2(200 CHAR);
        l_internal_name ds_cmpt_mkt_rel.internal_name_child%TYPE;
    BEGIN
    
        IF NOT pk_rt_med_pfh.get_presc_rate_by_type(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_id_product          => i_id_product,
                                                    i_id_product_supplier => i_id_product_supplier,
                                                    i_presc_list_type     => i_presc_list_type,
                                                    o_info                => l_info,
                                                    o_error               => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        LOOP
            FETCH l_info
                INTO l_data, l_label, l_context, l_type, l_subtype, l_value, l_unit, l_unitdesc, l_rank;
            EXIT WHEN l_info%NOTFOUND;
            IF i_context IS NULL
               OR l_context = i_context
            THEN
                l_ret.extend;
                l_ret(l_ret.count) := t_row_core_domain(l_internal_name, l_label, l_data, l_rank, NULL);
            END IF;
        END LOOP;
    
        RETURN l_ret;
    END get_presc_rate_by_type;

    FUNCTION get_process_status_per_task
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_request IN cpoe_process_task.id_task_request%TYPE,
        i_id_task_type    IN cpoe_process_task.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_cpoe.get_process_status_per_task(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_task_request => i_id_task_request,
                                                   i_id_task_type    => i_id_task_type);
    END get_process_status_per_task;

    FUNCTION get_frequencies_by_type
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_freq_type           IN NUMBER
    ) RETURN t_tbl_core_domain IS
        l_error             t_error_out;
        l_info              pk_types.cursor_type;
        l_ret               t_tbl_core_domain := t_tbl_core_domain();
        l_data              VARCHAR2(200 CHAR);
        l_label             VARCHAR2(200 CHAR);
        l_type              VARCHAR2(200 CHAR);
        l_subtype           VARCHAR2(200 CHAR);
        l_rank              VARCHAR2(200 CHAR);
        l_value             VARCHAR2(200 CHAR);
        l_unit              VARCHAR2(200 CHAR);
        l_unitdesc          VARCHAR2(200 CHAR);
        l_flg_freq_type     VARCHAR2(200 CHAR);
        l_freq_daily_amount VARCHAR2(200 CHAR);
        l_id_group          VARCHAR2(200 CHAR);
        l_rownum            VARCHAR2(200 CHAR);
        l_flg_default       VARCHAR2(200 CHAR);
        l_flg_prn           VARCHAR2(200 CHAR);
        l_flg_normal_presc  VARCHAR2(200 CHAR);
        l_flg_iv_presc      VARCHAR2(200 CHAR);
    
        l_internal_name ds_cmpt_mkt_rel.internal_name_child%TYPE;
    BEGIN
    
        IF NOT pk_rt_med_pfh.get_frequencies_by_type(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_id_product          => i_id_product,
                                                     i_id_product_supplier => i_id_product_supplier,
                                                     i_freq_type           => i_freq_type,
                                                     o_info                => l_info,
                                                     o_error               => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        LOOP
            FETCH l_info
                INTO l_data,
                     l_label,
                     l_type,
                     l_subtype,
                     l_rank,
                     l_value,
                     l_unit,
                     l_unitdesc,
                     l_flg_freq_type,
                     l_freq_daily_amount,
                     l_id_group,
                     l_rownum,
                     l_flg_default,
                     l_flg_prn,
                     l_flg_normal_presc,
                     l_flg_iv_presc;
            EXIT WHEN l_info%NOTFOUND;
            l_ret.extend;
            l_ret(l_ret.count) := t_row_core_domain(l_internal_name, l_label, l_data, l_rank, NULL);
        END LOOP;
    
        RETURN l_ret;
    END get_frequencies_by_type;

    FUNCTION pharm_is_out_of_stock_by_status
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_presc  IN NUMBER,
        i_id_status IN NUMBER --g_wf_declined, g_wf_on_hold
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_pha_pfh.pharm_is_out_of_stock_by_status(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_id_presc  => i_id_presc,
                                                             i_id_status => i_id_status);
    END pharm_is_out_of_stock_by_status;

    FUNCTION get_review_flg_remove_list
    (
        i_lang    IN language.id_language%TYPE,
        i_id_task IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_review_flg_remove_list(i_lang => i_lang, i_id_task => i_id_task);
    
    END get_review_flg_remove_list;

    FUNCTION get_pharm_show_alert_out_of_stock
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_pha_pfh.get_pharm_show_alert_out_of_stock(i_lang       => i_lang,
                                                               i_prof       => i_prof,
                                                               i_id_episode => i_id_episode,
                                                               i_id_patient => i_id_patient);
    
    END get_pharm_show_alert_out_of_stock;

    FUNCTION get_presc_disp_method(i_id_presc IN NUMBER) RETURN NUMBER IS
    BEGIN
    
        RETURN pk_rt_med_pfh.get_presc_disp_method(i_id_presc => i_id_presc);
    
    END get_presc_disp_method;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_presc_notes_serialized
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN presc.id_presc%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_rt_med_pfh.get_presc_notes_serialized(i_lang => i_lang, i_prof => i_prof, i_id_presc => i_id_presc);
    END get_presc_notes_serialized;

    FUNCTION get_dispense_type(i_id_presc IN NUMBER) RETURN VARCHAR2 IS
        l_dispense_type VARCHAR2(1);
    BEGIN
        SELECT d.flg_dispense_type
          INTO l_dispense_type
          FROM v_pha_dispense d
         WHERE d.id_task = i_id_presc
           AND rownum = 1;
    
        RETURN l_dispense_type;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_dispense_type;

    FUNCTION check_product_is_glp1agonist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        i_id_grant            IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
    
        --Call alert_product_mt to get product category of product obtained before
        RETURN pk_rt_med_pfh.check_product_is_glp1agonist(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_id_product          => i_id_product,
                                                          i_id_product_supplier => i_id_product_supplier,
                                                          i_id_grant            => i_id_grant);
    
    END check_product_is_glp1agonist;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package_name);

END pk_api_pfh_in;
/
