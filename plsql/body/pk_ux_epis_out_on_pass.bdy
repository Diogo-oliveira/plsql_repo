/*-- Last Change Revision: $Rev: 2027833 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:26 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_ux_epis_out_on_pass IS

    /* CAN'T TOUCH THIS */
    g_error         VARCHAR2(1000 CHAR);
    g_package_owner VARCHAR2(30 CHAR);
    g_package_name  VARCHAR2(30 CHAR);
    g_retval        BOOLEAN;
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;

    /**
    * Gets actions available for the out on pass
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_epis_out_on_pass        Epis_out_on_pass identifier
    * @param   o_actions                    List of actions available
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  Adriana Ramos
    * @since   2019/04/18
    */
    FUNCTION get_actions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_actions             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_ACTIONS';
    BEGIN
        g_error := 'Call pk_epis_out_on_pass.get_actions / i_id_epis_out_on_pass= ' || i_id_epis_out_on_pass;
    
        RETURN pk_epis_out_on_pass.get_actions(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_epis_out_on_pass => i_id_epis_out_on_pass,
                                               o_actions             => o_actions,
                                               o_error               => o_error);
    
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
    END get_actions;

    /********************************************************************************************
    * set cancel on the epis_out_on_pass
    *
    * @author          Adriana Ramos
    * @since           22/04/2019
    ********************************************************************************************/
    FUNCTION set_cancel_epis_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_id_cancel_reason    IN epis_out_on_pass.id_cancel_reason%TYPE,
        i_cancel_reason       IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'SET_CANCEL_EPIS_OUT_ON_PASS';
    BEGIN
        g_error := 'Call pk_epis_out_on_pass.set_cancel_epis_out_on_pass / i_id_epis_out_on_pass= ' ||
                   i_id_epis_out_on_pass;
    
        IF NOT pk_epis_out_on_pass.set_cancel_epis_out_on_pass(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_id_epis_out_on_pass => i_id_epis_out_on_pass,
                                                               i_id_cancel_reason    => i_id_cancel_reason,
                                                               i_cancel_reason       => i_cancel_reason,
                                                               o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
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
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END set_cancel_epis_out_on_pass;

    /********************************************************************************************
    * set the epis_out_on_pass
    *
    * @author          Adriana Ramos
    * @since           24/04/2019
    ********************************************************************************************/
    FUNCTION set_epis_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN epis_out_on_pass.id_patient%TYPE,
        i_id_episode          IN epis_out_on_pass.id_episode%TYPE,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_cmpt_mkt_rel        IN table_number,
        i_values              IN table_table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'SET_EPIS_OUT_ON_PASS';
    
        l_id_ds_component            ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
        l_id_request_reason          epis_out_on_pass.id_request_reason%TYPE := NULL;
        l_id_requested_by            epis_out_on_pass.id_requested_by%TYPE := NULL;
        l_dt_out                     TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_dt_in                      TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_total_allowed_hours        epis_out_on_pass.total_allowed_hours%TYPE := NULL;
        l_patient_contact_number     epis_out_on_pass.patient_contact_number%TYPE := NULL;
        l_flg_attending_physic_agree epis_out_on_pass.flg_attending_physic_agree%TYPE := NULL;
        l_note_admission_office      pk_types.t_huge_byte := NULL;
        l_other_notes                pk_types.t_huge_byte := NULL;
        l_request_reason_other       pk_types.t_huge_byte := NULL;
        l_requested_by_other         pk_types.t_huge_byte := NULL;
    BEGIN
        g_error := 'Call pk_epis_out_on_pass.create_epis_out_on_pass';
    
        FOR i IN 1 .. i_cmpt_mkt_rel.count
        LOOP
            SELECT dcmr.id_ds_component_child
              INTO l_id_ds_component
              FROM ds_cmpt_mkt_rel dcmr
             WHERE dcmr.id_ds_cmpt_mkt_rel = i_cmpt_mkt_rel(i);
        
            CASE l_id_ds_component
                WHEN g_request_reason_ds_id THEN
                    l_id_request_reason := to_number(i_values(i) (1));
                
                WHEN g_requested_by_ds_id THEN
                    l_id_requested_by := to_number(i_values(i) (1));
                
                WHEN g_dt_out_ds_id THEN
                    l_dt_out := pk_date_utils.get_string_tstz(i_lang, i_prof, i_values(i) (1), NULL);
                
                WHEN g_dt_in_ds_id THEN
                    l_dt_in := pk_date_utils.get_string_tstz(i_lang, i_prof, i_values(i) (1), NULL);
                
                WHEN g_total_allowed_days_ds_id THEN
                    l_total_allowed_hours := pk_utils.char_to_number(i_prof => i_prof, i_input => i_values(i) (1));
                
                WHEN g_pat_contact_number_ds_id THEN
                    l_patient_contact_number := i_values(i) (1);
                
                WHEN g_attending_physic_agree_ds_id THEN
                    l_flg_attending_physic_agree := i_values(i) (1);
                
                WHEN g_note_admission_office_ds_id THEN
                    l_note_admission_office := i_values(i) (1);
                
                WHEN g_other_notes_ds_id THEN
                    l_other_notes := i_values(i) (1);
                
                WHEN g_request_reason_other_ds_id THEN
                    l_request_reason_other := i_values(i) (1);
                
                WHEN g_requested_by_other_ds_id THEN
                    l_requested_by_other := i_values(i) (1);
            END CASE;
        END LOOP;
    
        IF i_id_epis_out_on_pass IS NULL
        THEN
        
            IF NOT pk_epis_out_on_pass.create_epis_out_on_pass(i_lang                       => i_lang,
                                                               i_prof                       => i_prof,
                                                               i_id_patient                 => i_id_patient,
                                                               i_id_episode                 => i_id_episode,
                                                               i_id_request_reason          => l_id_request_reason,
                                                               i_request_reason             => l_request_reason_other,
                                                               i_dt_out                     => l_dt_out,
                                                               i_dt_in                      => l_dt_in,
                                                               i_total_allowed_hours        => l_total_allowed_hours,
                                                               i_flg_attending_physic_agree => l_flg_attending_physic_agree,
                                                               i_id_requested_by            => l_id_requested_by,
                                                               i_requested_by               => l_requested_by_other,
                                                               i_patient_contact_number     => l_patient_contact_number,
                                                               i_other_notes                => l_other_notes,
                                                               o_error                      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            IF NOT pk_epis_out_on_pass.update_epis_out_on_pass(i_lang                       => i_lang,
                                                               i_prof                       => i_prof,
                                                               i_id_epis_out_on_pass        => i_id_epis_out_on_pass,
                                                               i_id_request_reason          => l_id_request_reason,
                                                               i_request_reason             => l_request_reason_other,
                                                               i_dt_out                     => l_dt_out,
                                                               i_dt_in                      => l_dt_in,
                                                               i_total_allowed_hours        => l_total_allowed_hours,
                                                               i_flg_attending_physic_agree => l_flg_attending_physic_agree,
                                                               i_id_requested_by            => l_id_requested_by,
                                                               i_requested_by               => l_requested_by_other,
                                                               i_patient_contact_number     => l_patient_contact_number,
                                                               i_other_notes                => l_other_notes,
                                                               i_note_admission_office      => l_note_admission_office,
                                                               o_error                      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
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
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END set_epis_out_on_pass;

    /********************************************************************************************
    * complete the epis_out_on_pass
    *
    * @author          Adriana Ramos
    * @since           26/04/2019
    ********************************************************************************************/
    FUNCTION complete_epis_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN epis_out_on_pass.id_episode%TYPE,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_dt_in_returned      IN VARCHAR2,
        i_id_conclude_reason  IN epis_out_on_pass.id_conclude_reason%TYPE,
        i_conclude_notes      IN VARCHAR2,
        i_flg_adm_medication  IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'COMPLETE_EPIS_OUT_ON_PASS';
    BEGIN
        g_error := 'Call pk_epis_out_on_pass.create_epis_out_on_pass';
    
        IF i_flg_adm_medication = pk_alert_constant.get_yes
        THEN
            --chama pack medicação
            IF NOT pk_api_pfh_in.complete_presc_out_on_pass(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_episode          => i_id_episode,
                                                            i_id_epis_out_on_pass => i_id_epis_out_on_pass,
                                                            i_dt_in_returned      => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                   i_prof,
                                                                                                                   i_dt_in_returned,
                                                                                                                   NULL),
                                                            o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF NOT pk_epis_out_on_pass.complete_epis_out_on_pass(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_id_epis_out_on_pass => i_id_epis_out_on_pass,
                                                             i_dt_in_returned      => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                    i_prof,
                                                                                                                    i_dt_in_returned,
                                                                                                                    NULL),
                                                             i_id_conclude_reason  => i_id_conclude_reason,
                                                             i_conclude_notes      => i_conclude_notes,
                                                             i_flg_all_med_adm     => i_flg_adm_medication,
                                                             o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
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
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END complete_epis_out_on_pass;

    /********************************************************************************************
    * start the epis_out_on_pass
    *
    * @author          Adriana Ramos
    * @since           26/04/2019
    ********************************************************************************************/
    FUNCTION start_epis_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN epis_out_on_pass.id_episode%TYPE,
        i_id_presc            IN table_number,
        i_dt_out              IN VARCHAR2,
        i_dt_in               IN VARCHAR2,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_start_notes         IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'START_EPIS_OUT_ON_PASS';
    BEGIN
        g_error := 'Call pk_epis_out_on_pass.start_epis_out_on_pass';
    
        IF nvl(cardinality(i_id_presc), 0) != 0
        THEN
            --chama pack medicação
            IF NOT pk_api_pfh_in.set_presc_out_on_pass(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_episode          => i_id_episode,
                                                       i_id_presc            => i_id_presc,
                                                       i_id_epis_out_on_pass => i_id_epis_out_on_pass,
                                                       i_first_date          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                              i_prof,
                                                                                                              i_dt_out,
                                                                                                              NULL),
                                                       i_last_date           => nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                                  i_prof,
                                                                                                                  i_dt_in,
                                                                                                                  NULL),
                                                                                    current_timestamp),
                                                       o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF NOT pk_epis_out_on_pass.start_epis_out_on_pass(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_id_epis_out_on_pass => i_id_epis_out_on_pass,
                                                          i_start_notes         => i_start_notes,
                                                          o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
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
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END start_epis_out_on_pass;

    FUNCTION get_presc_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_presc_data          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_OUT_ON_PASS';
    
        l_id_episode epis_out_on_pass.id_episode%TYPE;
        l_dt_out     epis_out_on_pass.dt_out%TYPE;
        l_dt_in      epis_out_on_pass.dt_in%TYPE;
    BEGIN
    
        SELECT eoop.id_episode, eoop.dt_out, eoop.dt_in
          INTO l_id_episode, l_dt_out, l_dt_in
          FROM epis_out_on_pass eoop
         WHERE eoop.id_epis_out_on_pass = i_id_epis_out_on_pass;
    
        g_error := 'Call pk_api_pfh_in.get_presc_out_on_pass / i_id_epis_out_on_pass = ' || i_id_epis_out_on_pass;
    
        RETURN pk_api_pfh_in.get_presc_out_on_pass(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_episode => l_id_episode,
                                                   i_first_date => l_dt_out,
                                                   i_last_date  => l_dt_in,
                                                   o_presc_data => o_presc_data,
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
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_presc_out_on_pass;

    FUNCTION get_epis_out_on_pass_data
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_data                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_EPIS_OUT_ON_PASS_DATA';
    BEGIN
    
        RETURN pk_epis_out_on_pass.get_epis_out_on_pass_data(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_id_epis_out_on_pass => i_id_epis_out_on_pass,
                                                             o_data                => o_data,
                                                             o_error               => o_error);
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
    END get_epis_out_on_pass_data;

    FUNCTION get_presc_out_on_pass_complete
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_presc_data          OUT pk_types.cursor_type,
        o_server_time         OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_OUT_ON_PASS_COMPLETE';
        l_id_episode epis_out_on_pass.id_episode%TYPE;
    BEGIN
    
        o_server_time := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => current_timestamp, i_prof => i_prof);
    
        SELECT eoop.id_episode
          INTO l_id_episode
          FROM epis_out_on_pass eoop
         WHERE eoop.id_epis_out_on_pass = i_id_epis_out_on_pass;
    
        g_error := 'Call pk_api_pfh_in.get_presc_out_on_pass_complete / i_id_epis_out_on_pass = ' ||
                   i_id_epis_out_on_pass;
        RETURN pk_api_pfh_in.get_presc_out_on_pass_complete(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_episode          => l_id_episode,
                                                            i_id_epis_out_on_pass => i_id_epis_out_on_pass,
                                                            o_presc_data          => o_presc_data,
                                                            o_error               => o_error);
    
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
    END get_presc_out_on_pass_complete;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_detail              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_EPIS_OUT_ON_PASS_HIST';
    
    BEGIN
    
        RETURN pk_epis_out_on_pass.get_epis_out_on_pass_hist(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_id_epis_out_on_pass => i_id_epis_out_on_pass,
                                                             o_detail              => o_detail,
                                                             o_error               => o_error);
    
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
    END get_epis_out_on_pass_hist;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_detail              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_EPIS_OUT_ON_PASS_HIST';
    
    BEGIN
    
        RETURN pk_epis_out_on_pass.get_epis_out_on_pass_det(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_epis_out_on_pass => i_id_epis_out_on_pass,
                                                            o_detail              => o_detail,
                                                            o_error               => o_error);
    
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
    END get_epis_out_on_pass_detail;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION check_can_add
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN epis_out_on_pass.id_episode%TYPE,
        i_id_patient  IN epis_out_on_pass.id_patient%TYPE,
        o_flg_can_add OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'CHECK_CAN_ADD';
    
    BEGIN
    
        RETURN pk_epis_out_on_pass.check_can_add(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_id_episode  => i_id_episode,
                                                 i_id_patient  => i_id_patient,
                                                 o_flg_can_add => o_flg_can_add,
                                                 o_error       => o_error);
    
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
    END check_can_add;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package_name);

END pk_ux_epis_out_on_pass;
/
