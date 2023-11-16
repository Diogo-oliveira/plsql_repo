/*-- Last Change Revision: $Rev: 2014634 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-05-19 15:14:36 +0100 (qui, 19 mai 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ux_progress_notes IS

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception EXCEPTION;

    PROCEDURE end_transaction(i_bool IN BOOLEAN) IS
    BEGIN
    
        IF i_bool
        THEN
            COMMIT;
        ELSE
            ROLLBACK;
        END IF;
    
    END end_transaction;

    /**
    * Similar to PK_SYSDOMAIN.GET_DOMAINS for domain DIAGNOSIS.FLG_TYPE.
    * Marks one option as default.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_domains      cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.0.?
    * @since                2009/05/20
    */
    FUNCTION get_diag_types
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_domains OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DIAG_TYPES';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_diag_types';
        IF NOT pk_progress_notes.get_diag_types(i_lang    => i_lang,
                                                i_prof    => i_prof,
                                                o_domains => o_domains,
                                                o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_domains);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_domains);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_diag_types;

    /**
    * Retrieve summarized descriptions on all previous encounters.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param i_flg_type     {*} 'A' All Specialities {*} 'M' With me {*} 'S' My speciality    
    * @param o_enc_info     previous contacts descriptions
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2009/04/27
    */
    FUNCTION get_prev_enc_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2,
        o_enc_info OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PREV_ENC_INFO';
    BEGIN
        g_error := 'CALL pk_prev_encounter.get_prev_enc_info';
        IF NOT pk_prev_encounter.get_prev_enc_info(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_patient  => i_patient,
                                                   i_episode  => i_episode,
                                                   i_flg_type => i_flg_type,
                                                   o_enc_info => o_enc_info,
                                                   o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_enc_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_enc_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prev_enc_info;

    /**
    * Retrieve summarized info on all previous encounters.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param o_enc_info     previous encounters info
    * @param o_enc_data     previous encounters data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2009/03/31
    */
    FUNCTION get_prev_encounter
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_enc_info OUT pk_types.cursor_type,
        o_enc_data OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PREV_ENCOUNTER';
    BEGIN
        g_error := 'CALL pk_prev_encounter.get_prev_encounter';
        IF NOT pk_prev_encounter.get_prev_encounter(i_lang     => i_lang,
                                                    i_prof     => i_prof,
                                                    i_patient  => i_patient,
                                                    i_episode  => i_episode,
                                                    o_enc_info => o_enc_info,
                                                    o_enc_data => o_enc_data,
                                                    o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_enc_info);
            pk_types.open_my_cursor(o_enc_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_enc_info);
            pk_types.open_my_cursor(o_enc_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prev_encounter;

    /**
    * Retrieve detailed info on previous encounter.
    * Information is SOAP oriented.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param o_soap_blocks  soap blocks
    * @param o_data_blocks  data blocks
    * @param o_simple_text  simple text blocks structure
    * @param o_doc_reg      documentation registers
    * @param o_doc_val      documentation values
    * @param o_free_text    free text records
    * @param o_rea_visit    reason for visit records
    * @param o_app_type     appointment type
    * @param o_prof_rec     author and date of last change
    * @param o_nur_data     previous encounter nursing data
    * @param o_addendums_list addendums list    
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5
    * @since                2010/12/20
    */
    FUNCTION get_prev_encounter_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        o_soap_blocks    OUT pk_types.cursor_type,
        o_data_blocks    OUT pk_types.cursor_type,
        o_simple_text    OUT pk_types.cursor_type,
        o_doc_reg        OUT pk_types.cursor_type,
        o_doc_val        OUT pk_types.cursor_type,
        o_free_text      OUT pk_types.cursor_type,
        o_rea_visit      OUT pk_types.cursor_type,
        o_app_type       OUT pk_types.cursor_type,
        o_prof_rec       OUT VARCHAR2,
        o_nur_data       OUT pk_types.cursor_type,
        o_addendums_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PREV_ENCOUNTER_DET';
    BEGIN
        g_error := 'CALL pk_prev_encounter.get_prev_encounter_det';
        IF NOT pk_prev_encounter.get_prev_encounter_det(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_patient     => i_patient,
                                                        i_episode     => i_episode,
                                                        o_soap_blocks => o_soap_blocks,
                                                        o_data_blocks => o_data_blocks,
                                                        o_simple_text => o_simple_text,
                                                        o_doc_reg     => o_doc_reg,
                                                        o_doc_val     => o_doc_val,
                                                        o_free_text   => o_free_text,
                                                        o_rea_visit   => o_rea_visit,
                                                        o_app_type    => o_app_type,
                                                        o_prof_rec    => o_prof_rec,
                                                        o_nur_data    => o_nur_data,
                                                        o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_sign_off.GET_ADDENDUMS_LIST';
        IF NOT pk_sign_off.get_epis_addendums(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_episode   => i_episode,
                                              o_addendums => o_addendums_list,
                                              o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_data_blocks);
            pk_types.open_my_cursor(o_simple_text);
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            pk_types.open_my_cursor(o_nur_data);
            pk_types.open_my_cursor(o_addendums_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_data_blocks);
            pk_types.open_my_cursor(o_simple_text);
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            pk_types.open_my_cursor(o_nur_data);
            pk_types.open_my_cursor(o_addendums_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prev_encounter_det;

    /**
    * Get current appointment type.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_parent       parent type of appointment identifier
    * @param o_data         cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/20
    */
    FUNCTION get_appointment_type
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_id_dcs   OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_desc_dcs OUT pk_translation.t_desc_translation,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_APPOINTMENT_TYPE';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_appointment_type';
        IF NOT pk_progress_notes.get_appointment_type(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_episode  => i_episode,
                                                      o_id_dcs   => o_id_dcs,
                                                      o_desc_dcs => o_desc_dcs,
                                                      o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_appointment_type;

    /**
    * Get appointment types. Considers parenting.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_parent       parent type of appointment identifier
    * @param o_data         cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/20
    */
    FUNCTION get_appointment_types
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_parent  IN clinical_service.id_clinical_service_parent%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_APPOINTMENT_TYPES';
        l_prof profissional := profissional(i_prof.id, i_prof.institution, pk_alert_constant.g_soft_outpatient);
    BEGIN
        g_error := 'CALL pk_progress_notes.get_appointment_types';
        IF NOT pk_progress_notes.get_appointment_types(i_lang    => i_lang,
                                                  i_prof    => CASE
                                                                   WHEN i_episode IS NULL
                                                                        AND i_parent IS NULL THEN
                                                                   --When i_episode is null it means this function is being called
                                                                   --from the Order Set area. The professional software must be set
                                                                   --to OUTPATIENT
                                                                    l_prof
                                                                   ELSE
                                                                    i_prof
                                                               END,
                                                  i_episode => i_episode,
                                                  i_parent  => i_parent,
                                                  o_data    => o_data,
                                                  o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_appointment_types;

    /**
    * Get appointment types.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_data         cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/20
    */
    FUNCTION get_appointment_types
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_APPOINTMENT_TYPES';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_appointment_types';
        IF NOT pk_progress_notes.get_appointment_types(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_episode => i_episode,
                                                       o_data    => o_data,
                                                       o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_appointment_types;

    /**
    * Set appointment type.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_dcs          appointment identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/20
    */
    FUNCTION set_appointment_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_dcs     IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_APPOINTMENT_TYPE';
    BEGIN
        g_error := 'CALL pk_progress_notes.set_appointment_type';
        IF NOT pk_progress_notes.set_appointment_type(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_episode => i_episode,
                                                      i_dcs     => i_dcs,
                                                      o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END set_appointment_type;

    /**
    * Get complaints for current episode's type of appointment.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_user_query   user query
    * @param o_complaints   complaints cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/28
    */
    FUNCTION get_complaints_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_user_query IN VARCHAR2,
        o_complaints OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_COMPLAINTS_EPIS';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_complaints_epis';
        IF NOT pk_progress_notes.get_complaints_epis(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_episode    => i_episode,
                                                     i_user_query => i_user_query,
                                                     o_complaints => o_complaints,
                                                     o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_complaints);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_complaints);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_complaints_epis;

    /**
    * Get complaints for given type of appointment.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_dcs          appointment identifier
    * @param o_complaints   complaints cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/28
    */
    FUNCTION get_complaints_dcs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_dcs        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_complaints OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_COMPLAINTS_DCS';
        l_prof profissional := profissional(i_prof.id, i_prof.institution, pk_alert_constant.g_soft_outpatient);
    BEGIN
        g_error := 'CALL pk_progress_notes.get_complaints_dcs';
        IF NOT pk_progress_notes.get_complaints_dcs(i_lang       => i_lang,
                                               i_prof       => CASE
                                                                   WHEN i_episode IS NULL THEN
                                                                   --When i_episode is null it means this function is being called
                                                                   --from the Order Set area. The professional software must be set
                                                                   --to OUTPATIENT
                                                                    l_prof
                                                                   ELSE
                                                                    i_prof
                                                               END,
                                               i_episode    => i_episode,
                                               i_dcs        => i_dcs,
                                               o_complaints => o_complaints,
                                               o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_complaints);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_complaints);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_complaints_dcs;

    /**
    * Get complaints for all types of appointment.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_user_query   user query
    * @param o_complaints   complaints cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/09/28
    */
    FUNCTION get_complaints_all
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_user_query IN VARCHAR2,
        o_complaints OUT pk_types.cursor_type,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_complaint t_tbl_complaint;
    
        l_count NUMBER := 0;
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_COMPLAINTS_ALL';
    
    BEGIN
        g_error := 'CALL pk_progress_notes.get_complaints_all';
        IF NOT pk_progress_notes.get_complaints_all(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_episode    => i_episode,
                                                    i_user_query => i_user_query,
                                                    o_complaints => l_complaint,
                                                    o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        SELECT COUNT(*)
          INTO l_count
          FROM TABLE(l_complaint) t;
    
        IF l_count = 0
        THEN
            o_flg_show  := 'Y';
            o_msg       := pk_message.get_message(i_lang, 'COMMON_M117');
            o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
        
            pk_types.open_my_cursor(o_complaints);
        ELSE
            g_error := 'OPEN O_COMPLAINTS';
            OPEN o_complaints FOR
                SELECT t.id_complaint, t.desc_complaint
                  FROM TABLE(l_complaint) t;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_complaints);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_complaints);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_complaints_all;

    /********************************************************************************************
    * returns the soap block associated with the institution / software / clinical_service
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    *
    * @param OUT  o_free_text   Free text records cursor
    * @param OUT  o_rea_visit   Reason for visit records cursor
    * @param OUT  o_app_type    Appointment type records cursor
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    21/09/2010
    ********************************************************************************************/
    FUNCTION get_prog_notes_blocks
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_soap_blocks        OUT pk_types.cursor_type,
        o_data_blocks        OUT pk_types.cursor_type,
        o_button_blocks      OUT pk_types.cursor_type,
        o_simple_text        OUT pk_types.cursor_type,
        o_doc_reg            OUT pk_types.cursor_type,
        o_doc_val            OUT pk_types.cursor_type,
        o_free_text          OUT pk_types.cursor_type,
        o_rea_visit          OUT pk_types.cursor_type,
        o_app_type           OUT pk_types.cursor_type,
        o_screen_det         OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PROG_NOTES_BLOCKS';
    
    BEGIN
    
        -- get c_soap_blocks
        g_error := 'CALL pk_progress_notes_upd.get_prog_notes_blocks';
        IF NOT pk_progress_notes_upd.get_prog_notes_blocks(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_patient            => i_patient,
                                                           i_episode            => i_episode,
                                                           o_soap_blocks        => o_soap_blocks,
                                                           o_data_blocks        => o_data_blocks,
                                                           o_button_blocks      => o_button_blocks,
                                                           o_simple_text        => o_simple_text,
                                                           o_doc_reg            => o_doc_reg,
                                                           o_doc_val            => o_doc_val,
                                                           o_free_text          => o_free_text,
                                                           o_rea_visit          => o_rea_visit,
                                                           o_app_type           => o_app_type,
                                                           o_screen_det         => o_screen_det,
                                                           o_template_layouts   => o_template_layouts,
                                                           o_doc_area_component => o_doc_area_component,
                                                           o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_data_blocks);
            pk_types.open_my_cursor(o_button_blocks);
            pk_types.open_my_cursor(o_simple_text);
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            pk_types.open_my_cursor(o_screen_det);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_data_blocks);
            pk_types.open_my_cursor(o_button_blocks);
            pk_types.open_my_cursor(o_simple_text);
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            pk_types.open_my_cursor(o_screen_det);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**
    * Get free text record detail.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_soap_block   block identifier
    * @param i_record       record identifier
    * @param o_detail       detail cursor
    * @param o_history      history cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_free_text_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_record     IN NUMBER,
        o_detail     OUT pk_types.cursor_type,
        o_history    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_FREE_TEXT_DET';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_free_text_det';
        IF NOT pk_progress_notes.get_free_text_det(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_soap_block => i_soap_block,
                                                   i_record     => i_record,
                                                   o_detail     => o_detail,
                                                   o_history    => o_history,
                                                   o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_detail);
            pk_types.open_my_cursor(i_cursor => o_history);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_detail);
            pk_types.open_my_cursor(i_cursor => o_history);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_free_text_det;

    /**
    * Get free text records of a given area.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_soap_block   block identifier
    * @param i_inc_cancel   include cancelled records? Y/N
    * @param o_free_text    detail cursor
    * @param o_warning      user warning
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/08
    */
    FUNCTION get_free_text_area
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_inc_cancel IN VARCHAR2,
        o_free_text  OUT pk_types.cursor_type,
        o_warning    OUT table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_FREE_TEXT_AREA';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_free_text_area';
        IF NOT pk_progress_notes.get_free_text_area(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_episode    => i_episode,
                                                    i_soap_block => i_soap_block,
                                                    i_inc_cancel => i_inc_cancel,
                                                    o_free_text  => o_free_text,
                                                    o_warning    => o_warning,
                                                    o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_free_text);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_free_text);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_free_text_area;

    /**
    * Stores user input from free text data blocks.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_soap_blocks  block identifiers list
    * @param i_records      record identifiers list
    * @param i_texts        texts list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/04
    */
    FUNCTION set_free_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_cat    IN category.flg_type%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_soap_blocks IN table_number,
        i_records     IN table_number,
        i_texts       IN table_clob,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_FREE_TEXT';
    BEGIN
        g_error := 'CALL pk_progress_notes.set_free_text';
        IF NOT pk_progress_notes.set_free_text(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_prof_cat    => i_prof_cat,
                                               i_episode     => i_episode,
                                               i_patient     => i_patient,
                                               i_soap_blocks => i_soap_blocks,
                                               i_records     => i_records,
                                               i_texts       => i_texts,
                                               o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END set_free_text;

    /**
    * Cancels record from free text data blocks.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_soap_block   block identifier
    * @param i_record       record identifier
    * @param i_reason       cancel reason identifier
    * @param i_notes        cancel notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/04
    */
    FUNCTION set_free_text_cancel
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_record     IN NUMBER,
        i_reason     IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes      IN cancel_info_det.notes_cancel_long%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_FREE_TEXT_CANCEL';
    BEGIN
        g_error := 'CALL pk_progress_notes.set_free_text_cancel';
        IF NOT pk_progress_notes.set_free_text_cancel(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_prof_cat   => i_prof_cat,
                                                      i_episode    => i_episode,
                                                      i_patient    => i_patient,
                                                      i_soap_block => i_soap_block,
                                                      i_record     => i_record,
                                                      i_reason     => i_reason,
                                                      i_notes      => i_notes,
                                                      o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END set_free_text_cancel;

    /**
    * Stores user input from reason for visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_record       record identifier
    * @param i_text         text
    * @param i_complaints   complaint identifiers list
    * @param o_id_per       created record identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/04
    */
    FUNCTION set_reason_for_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_record     IN pn_epis_reason.id_pn_epis_reason%TYPE,
        i_text       IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_complaints IN table_number,
        o_id_per     OUT pn_epis_reason.id_pn_epis_reason%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_REASON_FOR_VISIT';
    BEGIN
        g_error := 'CALL pk_progress_notes.set_reason_for_visit';
        IF NOT pk_progress_notes.set_reason_for_visit(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_prof_cat   => i_prof_cat,
                                                      i_episode    => i_episode,
                                                      i_patient    => i_patient,
                                                      i_record     => i_record,
                                                      i_text       => i_text,
                                                      i_complaints => i_complaints,
                                                      o_id_per     => o_id_per,
                                                      o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END set_reason_for_visit;

    /**
    * Stores user input from reason for visit and coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_record       record identifier
    * @param i_text         text
    * @param i_complaints   complaint identifiers list
    * @param i_diags        diagnoses identifiers list
    * @param o_id_per       created record identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Nuno Alves
    * @version               2.6.4.1
    * @since                2014/08/27
    */
    FUNCTION set_reason_for_visit_coding
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_record     IN pn_epis_reason.id_pn_epis_reason%TYPE,
        i_text       IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_complaints IN table_number,
        i_flg_rep_by IN epis_complaint.flg_reported_by%TYPE,
        i_diags      IN table_number,
        o_id_per     OUT pn_epis_reason.id_pn_epis_reason%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_REASON_FOR_VISIT_CODING';
    BEGIN
    
        g_error := 'CALL pk_progress_notes.set_reason_for_visit_coding';
        IF NOT pk_progress_notes.set_reason_for_visit_coding(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_prof_cat   => i_prof_cat,
                                                             i_episode    => i_episode,
                                                             i_patient    => i_patient,
                                                             i_record     => i_record,
                                                             i_text       => i_text,
                                                             i_complaints => i_complaints,
                                                             i_flg_rep_by => i_flg_rep_by,
                                                             i_diags      => i_diags,
                                                             o_id_per     => o_id_per,
                                                             o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_reason_for_visit_coding;
    /**
    * Cancels record from reason for visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_record       record identifier
    * @param i_reason       cancel reason identifier
    * @param i_notes        cancel notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/22
    */
    FUNCTION set_reason_for_visit_cancel
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_record   IN pn_epis_reason.id_pn_epis_reason%TYPE,
        i_reason   IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes    IN cancel_info_det.notes_cancel_long%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_REASON_FOR_VISIT_CANCEL';
    BEGIN
        g_error := 'CALL pk_progress_notes.set_reason_for_visit_cancel';
        IF NOT pk_progress_notes.set_reason_for_visit_cancel(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_prof_cat => i_prof_cat,
                                                             i_episode  => i_episode,
                                                             i_patient  => i_patient,
                                                             i_record   => i_record,
                                                             i_reason   => i_reason,
                                                             i_notes    => i_notes,
                                                             o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END set_reason_for_visit_cancel;

    /**
    * Stores user input from reported by field.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_record       record identifier
    * @param i_flg_rep_by   complaint reported by
    * @param o_id_per       created record identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/22
    */
    FUNCTION set_reported_by
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_record     IN pn_epis_reason.id_pn_epis_reason%TYPE,
        i_flg_rep_by IN epis_complaint.flg_reported_by%TYPE,
        o_id_per     OUT pn_epis_reason.id_pn_epis_reason%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_REPORTED_BY';
    BEGIN
        g_error := 'CALL pk_progress_notes.set_reported_by';
        IF NOT pk_progress_notes.set_reported_by(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_prof_cat   => i_prof_cat,
                                                 i_episode    => i_episode,
                                                 i_patient    => i_patient,
                                                 i_record     => i_record,
                                                 i_flg_rep_by => i_flg_rep_by,
                                                 o_id_per     => o_id_per,
                                                 o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END set_reported_by;

    /**
    * Stores user input from coding.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_soap_block   block identifier
    * @param i_record       record identifier
    * @param i_diags        diagnoses identifiers list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/22
    */
    FUNCTION set_coding
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_record     IN NUMBER,
        i_diags      IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_CODING';
    BEGIN
        g_error := 'CALL pk_progress_notes.set_coding';
        IF NOT pk_progress_notes.set_coding(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_prof_cat   => i_prof_cat,
                                            i_episode    => i_episode,
                                            i_patient    => i_patient,
                                            i_soap_block => i_soap_block,
                                            i_record     => i_record,
                                            i_diags      => i_diags,
                                            o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_coding;

    /**
    * Get information transfer default data.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_default
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IT_DEFAULT';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_it_default';
        IF NOT pk_progress_notes.get_it_default(i_lang    => i_lang,
                                                i_prof    => i_prof,
                                                i_episode => i_episode,
                                                i_patient => i_patient,
                                                o_data    => o_data,
                                                o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_it_default;

    /**
    * Get information transfer data for current visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_this_visit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IT_THIS_VISIT';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_it_this_visit';
        IF NOT pk_progress_notes.get_it_this_visit(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_episode => i_episode,
                                                   i_patient => i_patient,
                                                   o_data    => o_data,
                                                   o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_it_this_visit;

    /**
    * Get information transfer data for current user.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_my_visits
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IT_MY_VISITS';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_it_my_visits';
        IF NOT pk_progress_notes.get_it_my_visits(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_episode => i_episode,
                                                  i_patient => i_patient,
                                                  o_data    => o_data,
                                                  o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_it_my_visits;

    /**
    * Get information transfer data for current specialty.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_this_spec
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IT_THIS_SPEC';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_it_this_spec';
        IF NOT pk_progress_notes.get_it_this_spec(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_episode => i_episode,
                                                  i_patient => i_patient,
                                                  o_data    => o_data,
                                                  o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_it_this_spec;

    /**
    * Get information transfer data for all visits.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param o_data         information transfer data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/18
    */
    FUNCTION get_it_all_visits
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IT_ALL_VISITS';
    BEGIN
        g_error := 'CALL pk_progress_notes.get_it_all_visits';
        IF NOT pk_progress_notes.get_it_all_visits(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_episode => i_episode,
                                                   i_patient => i_patient,
                                                   o_data    => o_data,
                                                   o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_it_all_visits;

    /**
    * Get soap note blocks.
    *
    * @param i_lang               language identifier
    * @param i_prof               logged professional structure
    * @param i_episode            episode identifier
    * @param i_patient            patient identifier
    * @param i_id_pn_note_type    note type identifier
    * @param i_epis_pn_work       soap note identifier
    * @param o_soap_block         soap blocks cursor
    * @param o_data_block         data blocks cursor
    * @param o_button_block       button blocks cursor
    * @param o_error              error
    *
    * @return                     false if errors occur, true otherwise
    *
    * @author                     António Neto
    * @version                    2.6.1.2
    * @since                      27-Jul-2011
    */
    FUNCTION get_soap_note_blocks
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_epis_pn_work    IN epis_pn.id_epis_pn%TYPE,
        i_filter_search   IN table_varchar DEFAULT NULL,
        o_soap_block      OUT pk_types.cursor_type,
        o_data_block      OUT pk_types.cursor_type,
        o_button_block    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SOAP_NOTE_BLOCKS';
    BEGIN
        g_error := 'CALL pk_progress_notes_upd.get_soap_note_blocks';
        IF NOT pk_progress_notes_upd.get_soap_note_blocks(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_episode         => i_episode,
                                                          i_patient         => i_patient,
                                                          i_id_pn_note_type => i_id_pn_note_type,
                                                          i_epis_pn_work    => i_epis_pn_work,
                                                          i_filter_search   => i_filter_search,
                                                          o_soap_block      => o_soap_block,
                                                          o_data_block      => o_data_block,
                                                          o_button_block    => o_button_block,
                                                          o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_soap_block);
            pk_types.open_my_cursor(o_data_block);
            pk_types.open_my_cursor(o_button_block);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_soap_block);
            pk_types.open_my_cursor(o_data_block);
            pk_types.open_my_cursor(o_button_block);
            RETURN FALSE;
    END get_soap_note_blocks;
    /**
    * Returns the actions to be displayed in the 'ADD' button in the History and Physician screen.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_episode                    episode identifier
    * @param i_id_epis_pn                 Selected note Id.
    *                                     If no note is selected this param should be null
    * @param i_flg_status_note            Selected note status.
    *                                     If no note is selected this param should be null
    * @param i_area                       Area internal name
    * @param o_actions      actions data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since                27-Jul-2011
    */
    FUNCTION get_actions_add_button
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        i_flg_status_note IN epis_pn.flg_status%TYPE,
        i_area            IN pn_area.internal_name%TYPE,
        o_actions         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_prog_notes_core.get_actions_add_hp';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_actions_add_button(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_episode      => i_id_episode,
                                                          i_id_epis_pn      => i_id_epis_pn,
                                                          i_flg_status_note => i_flg_status_note,
                                                          i_area            => i_area,
                                                          o_actions         => o_actions,
                                                          o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_actions);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ACTIONS_ADD_BUTTON',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_actions);
            RETURN FALSE;
        
    END get_actions_add_button;

    /**
    * Returns the actions to be displayed in the 'ACTIONS' button when an addendum is selected
    *
    *
    * @param i_lang                    language identifier
    * @param i_prof                    logged professional structure
    * @param i_area                    Area name: 
    *                                       HP - histoy and physician
    *                                       PN-Progress Note
    * @param i_flg_status_addendum     Addendum status: D-draft; S-signed-off; C-Cancelled; F-Finalized
    * @param i_id_epis_addendum        Addendum Id
    * @param o_actions                 actions data
    * @param o_error                   error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_actions_addendum
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_area                IN pn_area.id_pn_area%TYPE,
        i_flg_status_addendum IN epis_addendum.flg_status%TYPE,
        i_id_epis_addendum    IN epis_addendum.id_epis_addendum%TYPE,
        o_actions             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.get_actions_addendum';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_actions_addendum(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_flg_status_addendum => i_flg_status_addendum,
                                                        i_id_epis_addendum    => i_id_epis_addendum,
                                                        o_actions             => o_actions,
                                                        o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_actions);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ACTIONS_ADDENDUM',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_actions);
            RETURN FALSE;
        
    END get_actions_addendum;

    /**
    * Returns the actions to be displayed in the 'ACTIONS' button when a note is selected.
    *
    *
    * @param i_lang                    language identifier
    * @param i_prof                    logged professional structure
    * @param i_area                    Area type
    *                                       HP - histoy and physician
    *                                       PN-Progress Note
    * @param i_flg_status_note         Note status: D-draft; S-signed-off; C-Cancelled; F-Finalized
    * @param i_id_epis_pn                 Selected note Id.
    *                                     If no note is selected this param should be null
    * @param o_actions      actions data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_actions_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_area            IN pn_area.internal_name%TYPE,
        i_flg_status_note IN epis_pn.flg_status%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_actions         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.get_actions_notes';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_actions_notes(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_flg_status_note => i_flg_status_note,
                                                     i_id_epis_pn      => i_id_epis_pn,
                                                     o_actions         => o_actions,
                                                     o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_actions);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ACTIONS_NOTES',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_actions);
            RETURN FALSE;
    END get_actions_notes;

    /********************************************************************************************
    * Returns Number of records to display in each page
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)    
    * @param I_ID_EPISODE            Episode identifier
    * @param I_AREA                  Area Internal Name
    * @param O_NUM_RECORDS           number of records per page
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                        Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        Sofia Mendes
    * @since                         28-Jan-2011
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_num_page_records
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_area        IN pn_area.internal_name%TYPE,
        o_num_records OUT PLS_INTEGER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        err_general_exception EXCEPTION;
    BEGIN
        g_error := 'CALL pk_prog_notes_core.GET_NUM_PAGE_RECORDS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_num_page_records(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_id_episode  => i_id_episode,
                                                        i_area        => i_area,
                                                        o_num_records => o_num_records,
                                                        o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            o_num_records := 0;
            RETURN FALSE;
        WHEN OTHERS THEN
            o_num_records := 0;
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NUM_PAGE_RECORDS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_num_page_records;

    /*******************************************************************************************************************************************
    * get_epis_prog_notes_count          Get number of all notes of the given type associated with the current episode.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_ID_EPIS_PN             progress note identifier
    * @param i_area                   Area internal name (HP,PN,...)
    * @param I_SEARCH                 keyword to Search for
    * @param I_FILTER                 Filter 
    * @param o_num_epis_pn            Returns the number of records for the search criteria
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR    
    
    * 
    * @return                        Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          27-Jan-2011
    *******************************************************************************************************************************************/
    FUNCTION get_epis_prog_notes_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area        IN pn_area.internal_name%TYPE,
        i_search      IN VARCHAR2,
        i_filter      IN VARCHAR2,
        o_num_epis_pn OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode   episode.id_episode%TYPE := i_id_episode;
        l_id_schedule  rehab_schedule.id_schedule%TYPE;
        l_id_epis_type episode.id_epis_type%TYPE;
    BEGIN
        IF i_prof.software = pk_alert_constant.g_soft_rehab
           AND i_area = pk_prog_notes_constants.g_screen_hp
        THEN
            g_error := 'CALL pk_rehab.get_origin_episode';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_rehab.get_origin_episode(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_id_episode        => i_id_episode,
                                               i_id_schedule       => NULL,
                                               o_id_episode_origin => l_id_episode,
                                               o_id_schedule       => l_id_schedule,
                                               o_id_epis_type      => l_id_epis_type,
                                               o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'CALL pk_prog_notes_core.get_epis_pnotes_count 1';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_epis_pnotes_count(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_id_episode  => l_id_episode,
                                                         i_id_epis_pn  => i_id_epis_pn,
                                                         i_area        => i_area,
                                                         i_search      => i_search,
                                                         i_filter      => i_filter,
                                                         o_num_epis_pn => o_num_epis_pn,
                                                         o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            o_num_epis_pn := 0;
            RETURN FALSE;
        WHEN OTHERS THEN
            o_num_epis_pn := 0;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_PROG_NOTES_COUNT',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_epis_prog_notes_count;

    /*******************************************************************************************************************************************
    * get_epis_prog_notes_count          Get number of all notes of the given type associated with the current episode.
    *                                    Function to the slide over
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param i_id_patient             patient identifier
    * @param i_flg_scope              E-episode; P-patient
    * @param i_area                   Area internal name (HP,PN,...)
    * @param I_SEARCH                 keyword to Search for
    * @param I_FILTER                 Filter 
    * @param o_num_epis_pn            Returns the number of records for the search criteria
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR    
    
    * 
    * @return                        Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          27-Jan-2011
    *******************************************************************************************************************************************/
    FUNCTION get_epis_prog_notes_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area        IN pn_area.internal_name%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_flg_scope   IN VARCHAR2,
        i_search      IN VARCHAR2,
        i_filter      IN VARCHAR2,
        o_num_epis_pn OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_prog_notes_core.get_epis_pnotes_count 2';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_epis_pnotes_count(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_id_episode  => i_id_episode,
                                                         i_id_patient  => i_id_patient,
                                                         i_id_epis_pn  => i_id_epis_pn,
                                                         i_flg_scope   => i_flg_scope,
                                                         i_area        => i_area,
                                                         i_search      => i_search,
                                                         i_filter      => i_filter,
                                                         o_num_epis_pn => o_num_epis_pn,
                                                         o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            o_num_epis_pn := 0;
            RETURN FALSE;
        WHEN OTHERS THEN
            o_num_epis_pn := 0;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_PROG_NOTES_COUNT',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_epis_prog_notes_count;

    /**
      * Returns the notes to the summary grid.
      *
      * @param i_lang                   language identifier
      * @param i_prof                   logged professional structure
      * @param i_episode                episode identifier
      * @param i_id_epis_pn             progress note identifier
      * @param i_area                   Area name. Ex:
      *                                       HP - histoy and physician
      *                                       PN-Progress Note    
      * @param I_START_RECORD           Paging - initial record number
      * @param I_NUM_RECORDS            Paging - number of records to display
      * @param I_SEARCH                 keyword to Search for
      * @param I_FILTER                 Filter by a listed interval of dates
      * @param o_data                   notes data
      * @param o_notes_texts            Texts that compose the note
      * @param o_addendums              Addendums data
    * @param o_comments         Comments data
      * @param o_area_configs           Configs associated to the area
      * @param o_error                  error
      *
      * @return                         false if errors occur, true otherwise
      *
      * @author               Sofia Mendes
      * @version               2.6.0.5
      * @since                26-Jan-2011
      */
    FUNCTION get_epis_prog_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_pn         IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area               IN VARCHAR2,
        i_search             IN VARCHAR2,
        i_filter             IN VARCHAR2,
        i_start_record       IN NUMBER,
        i_num_records        IN NUMBER,
        o_data               OUT pk_types.cursor_type,
        o_notes_texts        OUT pk_types.cursor_type,
        o_addendums          OUT pk_types.cursor_type,
        o_comments           OUT pk_types.cursor_type,
        o_area_configs       OUT NOCOPY pk_types.cursor_type,
        o_doc_reg            OUT NOCOPY pk_types.cursor_type,
        o_doc_val            OUT NOCOPY pk_types.cursor_type,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type,
        o_flg_is_arabic_note OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode   episode.id_episode%TYPE := i_id_episode;
        l_id_schedule  rehab_schedule.id_schedule%TYPE;
        l_id_epis_type episode.id_epis_type%TYPE;
        l_id_patient   patient.id_patient%TYPE;
        l_epis_doc     table_number := table_number();
        l_pn_note_tcl  table_clob;
        l_pn_note      epis_pn_det.pn_note%TYPE;
        l_epis_doc_aux table_number := table_number();
    
        l_flg_is_arabic_note VARCHAR2(1 CHAR);
    BEGIN
    
        IF i_prof.software = pk_alert_constant.g_soft_rehab
           AND i_area = pk_prog_notes_constants.g_screen_hp
        THEN
            g_error := 'CALL pk_rehab.get_origin_episode';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_rehab.get_origin_episode(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_id_episode        => i_id_episode,
                                               i_id_schedule       => NULL,
                                               o_id_episode_origin => l_id_episode,
                                               o_id_schedule       => l_id_schedule,
                                               o_id_epis_type      => l_id_epis_type,
                                               o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'CALL pk_prog_notes_core.get_epis_prog_notes 1';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_epis_prog_notes(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_episode   => l_id_episode,
                                                       i_id_patient   => NULL,
                                                       i_id_epis_pn   => i_id_epis_pn,
                                                       i_flg_scope    => pk_prog_notes_constants.g_flg_scope_e,
                                                       i_area         => i_area,
                                                       i_start_record => i_start_record,
                                                       i_num_records  => i_num_records,
                                                       i_search       => i_search,
                                                       i_filter       => i_filter,
                                                       o_data         => o_data,
                                                       o_notes_texts  => o_notes_texts,
                                                       o_addendums    => o_addendums,
                                                       o_comments     => o_comments,
                                                       o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_prog_notes_utils.get_area_name';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_area_configs(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_area         => i_area,
                                                    i_id_episode   => l_id_episode,
                                                    o_area_configs => o_area_configs,
                                                    o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        l_flg_is_arabic_note := pk_prog_notes_utils.has_arabic_note(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    i_episode => i_id_episode,
                                                                    i_area    => i_area);
        o_flg_is_arabic_note := l_flg_is_arabic_note;
    
        l_id_patient := pk_episode.get_epis_patient(i_lang => i_lang, i_prof => i_prof, i_episode => l_id_episode);
    
        SELECT t.id_task
          BULK COLLECT
          INTO l_epis_doc
          FROM (SELECT epdt.id_task
                  FROM epis_pn ep
                  JOIN epis_pn_det epd
                    ON epd.id_epis_pn = ep.id_epis_pn
                   AND epd.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                  JOIN epis_pn_det_task epdt
                    ON epdt.id_epis_pn_det = epd.id_epis_pn_det
                   AND epdt.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                   AND epdt.id_task_type = pk_prog_notes_constants.g_task_templates
                 WHERE ep.id_episode = l_id_episode
                   AND rownum > 0) t
         WHERE (SELECT pk_touch_option_out.has_layout(i_epis_documentation => t.id_task)
                  FROM dual) = pk_alert_constant.g_yes;
    
        -- martelada templates bilaterais gravados noutras SP   
        SELECT epd.pn_note
          BULK COLLECT
          INTO l_pn_note_tcl
          FROM epis_pn_det epd
          JOIN epis_pn ep
            ON ep.id_epis_pn = epd.id_epis_pn_det
         WHERE ep.id_episode = l_id_episode
           AND epd.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
           AND instr(epd.pn_note, '[B|ID_TASK:') > 0;
    
        FOR i IN 1 .. l_pn_note_tcl.count
        LOOP
            l_pn_note := l_pn_note || chr(13) || l_pn_note_tcl(i);
        END LOOP;
    
        l_epis_doc_aux := pk_prog_notes_utils.get_bl_epis_documentation_ids(l_pn_note);
    
        l_epis_doc := l_epis_doc MULTISET UNION DISTINCT l_epis_doc_aux;
        --
    
        IF l_epis_doc.count > 0
        THEN
            IF NOT pk_touch_option.get_doc_area_value_internal(i_lang               => i_lang,
                                                               i_prof               => i_prof,
                                                               i_id_episode         => l_id_episode,
                                                               i_id_patient         => l_id_patient,
                                                               i_doc_area           => NULL,
                                                               i_epis_doc           => l_epis_doc,
                                                               i_epis_anamn         => table_number(),
                                                               i_epis_rev_sys       => table_number(),
                                                               i_epis_obs           => table_number(),
                                                               i_epis_past_fsh      => table_number(),
                                                               i_epis_recomend      => table_number(),
                                                               i_flg_show_fm        => pk_alert_constant.g_no,
                                                               o_doc_area_register  => o_doc_reg,
                                                               o_doc_area_val       => o_doc_val,
                                                               o_template_layouts   => o_template_layouts,
                                                               o_doc_area_component => o_doc_area_component,
                                                               o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(i_cursor => o_doc_reg);
            pk_types.open_my_cursor(i_cursor => o_doc_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            pk_types.open_my_cursor(i_cursor => o_comments);
            pk_types.open_my_cursor(i_cursor => o_doc_reg);
            pk_types.open_my_cursor(i_cursor => o_doc_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_PROG_NOTES',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            pk_types.open_my_cursor(i_cursor => o_comments);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_types.open_my_cursor(i_cursor => o_doc_reg);
            pk_types.open_my_cursor(i_cursor => o_doc_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
            RETURN FALSE;
        
    END get_epis_prog_notes;

    /**
      * Returns the notes to the summary grid.
      * Function to the slide over screen
      *
      * @param i_lang                   language identifier
      * @param i_prof                   logged professional structure
      * @param i_episode                episode identifier
      * @param i_id_patient             patient identifier
      * @param i_flg_scope              E-episode; P-patient
      * @param i_area                   Area name. Ex:
      *                                       HP - histoy and physician
      *                                       PN-Progress Note    
      * @param I_START_RECORD           Paging - initial record number
      * @param I_NUM_RECORDS            Paging - number of records to display
      * @param I_SEARCH                 keyword to Search for
      * @param I_FILTER                 Filter by a listed interval of dates
      * @param o_data                   notes data
      * @param o_notes_texts            Texts that compose the note
      * @param o_addendums              Addendums data
    * @param o_comments         Comments data
      * @param o_area_configs           Configs associated to the area
      * @param o_error                  error
      *
      * @return                         false if errors occur, true otherwise
      *
      * @author               Sofia Mendes
      * @version               2.6.0.5
      * @since                26-Jan-2011
      */
    FUNCTION get_epis_prog_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_pn         IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area               IN VARCHAR2,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_scope          IN VARCHAR2,
        i_search             IN VARCHAR2,
        i_filter             IN VARCHAR2,
        i_start_record       IN NUMBER,
        i_num_records        IN NUMBER,
        o_data               OUT pk_types.cursor_type,
        o_notes_texts        OUT pk_types.cursor_type,
        o_addendums          OUT pk_types.cursor_type,
        o_comments           OUT pk_types.cursor_type,
        o_area_configs       OUT NOCOPY pk_types.cursor_type,
        o_doc_reg            OUT NOCOPY pk_types.cursor_type,
        o_doc_val            OUT NOCOPY pk_types.cursor_type,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type,
        o_flg_is_arabic_note OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_patient         patient.id_patient%TYPE := i_id_patient;
        l_epis_doc           table_number := table_number();
        l_pn_note_tcl        table_clob;
        l_pn_note            epis_pn_det.pn_note%TYPE;
        l_epis_doc_aux       table_number := table_number();
        l_flg_is_arabic_note VARCHAR2(1 CHAR);
    BEGIN
    
        IF i_id_patient IS NULL
        THEN
            l_id_patient := pk_episode.get_epis_patient(i_lang => i_lang, i_prof => i_prof, i_episode => i_id_episode);
        ELSE
            l_id_patient := i_id_patient;
        END IF;
    
        g_error := 'CALL pk_prog_notes_core.get_epis_prog_notes';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_epis_prog_notes(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_episode   => i_id_episode,
                                                       i_id_patient   => l_id_patient,
                                                       i_id_epis_pn   => i_id_epis_pn,
                                                       i_flg_scope    => i_flg_scope,
                                                       i_area         => i_area,
                                                       i_start_record => i_start_record,
                                                       i_num_records  => i_num_records,
                                                       i_search       => i_search,
                                                       i_filter       => i_filter,
                                                       o_data         => o_data,
                                                       o_notes_texts  => o_notes_texts,
                                                       o_addendums    => o_addendums,
                                                       o_comments     => o_comments,
                                                       o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_prog_notes_utils.get_area_name 2';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_area_configs(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_area         => i_area,
                                                    i_id_episode   => i_id_episode,
                                                    o_area_configs => o_area_configs,
                                                    o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        l_flg_is_arabic_note := pk_prog_notes_utils.has_arabic_note(i_lang      => i_lang,
                                                                    i_prof      => i_prof,
                                                                    i_episode   => i_id_episode,
                                                                    i_flg_scope => i_flg_scope,
                                                                    i_area      => i_area);
        o_flg_is_arabic_note := l_flg_is_arabic_note;
    
        SELECT t.id_task
          BULK COLLECT
          INTO l_epis_doc
          FROM (SELECT epdt.id_task
                  FROM epis_pn ep
                  JOIN episode epi
                    ON epi.id_episode = ep.id_episode
                  JOIN epis_pn_det epd
                    ON epd.id_epis_pn = ep.id_epis_pn
                   AND epd.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                  JOIN epis_pn_det_task epdt
                    ON epdt.id_epis_pn_det = epd.id_epis_pn_det
                   AND epdt.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                   AND epdt.id_task_type = pk_prog_notes_constants.g_task_templates
                 WHERE (ep.id_episode = i_id_episode OR i_flg_scope = pk_prog_notes_constants.g_flg_scope_p)
                   AND epi.id_patient = l_id_patient
                   AND rownum > 0) t
         WHERE (SELECT pk_touch_option_out.has_layout(i_epis_documentation => t.id_task)
                  FROM dual) = pk_alert_constant.g_yes;
    
        -- martelada templates bilaterais gravados noutras SP   
        SELECT epd.pn_note
          BULK COLLECT
          INTO l_pn_note_tcl
          FROM epis_pn_det epd
          JOIN epis_pn ep
            ON ep.id_epis_pn = epd.id_epis_pn_det
          JOIN episode epi
            ON epi.id_episode = ep.id_episode
         WHERE (ep.id_episode = i_id_episode OR i_flg_scope = pk_prog_notes_constants.g_flg_scope_p)
           AND epi.id_patient = l_id_patient
           AND epd.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
           AND instr(epd.pn_note, '[B|ID_TASK:') > 0;
    
        FOR i IN 1 .. l_pn_note_tcl.count
        LOOP
            l_pn_note := l_pn_note || chr(13) || l_pn_note_tcl(i);
        END LOOP;
    
        l_epis_doc_aux := pk_prog_notes_utils.get_bl_epis_documentation_ids(l_pn_note);
    
        l_epis_doc := l_epis_doc MULTISET UNION DISTINCT l_epis_doc_aux;
        --
    
        IF l_epis_doc.count > 0
        THEN
            IF NOT pk_touch_option.get_doc_area_value_internal(i_lang               => i_lang,
                                                               i_prof               => i_prof,
                                                               i_id_episode         => i_id_episode,
                                                               i_id_patient         => l_id_patient,
                                                               i_doc_area           => NULL,
                                                               i_epis_doc           => l_epis_doc,
                                                               i_epis_anamn         => table_number(),
                                                               i_epis_rev_sys       => table_number(),
                                                               i_epis_obs           => table_number(),
                                                               i_epis_past_fsh      => table_number(),
                                                               i_epis_recomend      => table_number(),
                                                               i_flg_show_fm        => pk_alert_constant.g_no,
                                                               o_doc_area_register  => o_doc_reg,
                                                               o_doc_area_val       => o_doc_val,
                                                               o_template_layouts   => o_template_layouts,
                                                               o_doc_area_component => o_doc_area_component,
                                                               o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(i_cursor => o_doc_reg);
            pk_types.open_my_cursor(i_cursor => o_doc_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            pk_types.open_my_cursor(i_cursor => o_doc_reg);
            pk_types.open_my_cursor(i_cursor => o_doc_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_PROG_NOTES',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_types.open_my_cursor(i_cursor => o_doc_reg);
            pk_types.open_my_cursor(i_cursor => o_doc_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
            RETURN FALSE;
        
    END get_epis_prog_notes;

    /**
    * Returns the note info.
    * Function to the sign-off screen.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_epis_pn             Note Id     
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note   
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_epis_prog_notes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_notes_texts OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.get_epis_prog_notes 3';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_epis_prog_notes(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_id_episode  => i_id_episode,
                                                       i_id_epis_pn  => i_id_epis_pn,
                                                       i_flg_config  => pk_prog_notes_constants.g_flg_config_signoff,
                                                       o_data        => o_data,
                                                       o_notes_texts => o_notes_texts,
                                                       o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_PROG_NOTES',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            RETURN FALSE;
        
    END get_epis_prog_notes;

    /**
    * Returns the notes to the summary grid.
    * Function to the slide over screen
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_patient             patient identifier             
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note
    * @param o_addendums              Addendums data
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_epis_prog_notes_res
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_notes_texts OUT pk_types.cursor_type,
        o_addendums   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_comments_dummy pk_types.cursor_type;
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.get_epis_prog_notes';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_epis_prog_notes(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_episode   => i_id_episode,
                                                       i_id_patient   => i_id_patient,
                                                       i_flg_scope    => pk_prog_notes_constants.g_flg_scope_e,
                                                       i_area         => pk_prog_notes_constants.g_screen_pn,
                                                       i_start_record => 0,
                                                       i_num_records  => 1,
                                                       i_search       => NULL,
                                                       i_filter       => NULL,
                                                       o_data         => o_data,
                                                       o_notes_texts  => o_notes_texts,
                                                       o_addendums    => o_addendums,
                                                       o_comments     => l_comments_dummy,
                                                       o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_PROG_NOTES_RES',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            RETURN FALSE;
        
    END get_epis_prog_notes_res;

    /**
    * Returns the last note to the summary grid.
    * Function to the slide over screen
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_patient             patient identifier             
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note
    * @param o_addendums              Addendums data
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                01-11-2013
    */
    FUNCTION get_last_prog_notes_res
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_area         IN pn_area.internal_name%TYPE,
        o_data         OUT pk_types.cursor_type,
        o_notes_texts  OUT pk_types.cursor_type,
        o_addendums    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_comments_dummy pk_types.cursor_type;
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.get_last_prog_notes_res';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_epis_prog_notes(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_episode   => i_id_episode,
                                                       i_id_patient   => i_id_patient,
                                                       i_flg_scope    => pk_prog_notes_constants.g_flg_scope_e,
                                                       i_area         => i_area,
                                                       i_start_record => 0,
                                                       i_num_records  => 1,
                                                       i_search       => NULL,
                                                       i_filter       => NULL,
                                                       o_data         => o_data,
                                                       o_notes_texts  => o_notes_texts,
                                                       o_addendums    => o_addendums,
                                                       o_comments     => l_comments_dummy,
                                                       o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_last_prog_notes_res',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            RETURN FALSE;
        
    END get_last_prog_notes_res;


    FUNCTION get_last_prog_notes_res
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_area         IN pn_area.internal_name%TYPE,
        i_flg_category IN VARCHAR2,
        o_data         OUT pk_types.cursor_type,
        o_notes_texts  OUT pk_types.cursor_type,
        o_addendums    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_comments_dummy pk_types.cursor_type;
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.get_last_prog_notes_res';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_epis_prog_notes(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_episode   => i_id_episode,
                                                       i_id_patient   => i_id_patient,
                                                       i_flg_scope    => pk_prog_notes_constants.g_flg_scope_e,
                                                       i_area         => i_area,
                                                       i_start_record => 0,
                                                       i_num_records  => 1,
                                                       i_search       => NULL,
                                                       i_filter       => NULL,
                                                       i_flg_category => i_flg_category,
                                                       o_data         => o_data,
                                                       o_notes_texts  => o_notes_texts,
                                                       o_addendums    => o_addendums,
                                                       o_comments     => l_comments_dummy,
                                                       o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_last_prog_notes_res',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            RETURN FALSE;
        
    END get_last_prog_notes_res;

    /**
    * Create/update a Progress Notes Addendum
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_epis_pn             Progress Notes ID
    * @param   i_id_epis_pn_addendum Addendum ID
    * @param   i_pn_addendum         Progress Notes Addendum (text)
    * @param   i_area                Screen flg_type
    *  
    * @param   o_epis_pn_addendum    PN Addendum ID created or updated
    * @param   o_error               Error information
    *
    * @return  Boolean               True: Sucess, False: Fail
    *
    * @author  RUI.BATISTA
    * @version <2.6.0.5>
    * @since   31-01-2011
    */
    FUNCTION set_pn_addendum
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        i_pn_addendum         IN epis_pn_addendum.pn_addendum%TYPE,
        i_area                IN VARCHAR2,
        o_epis_pn_addendum    OUT epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.set_pn_addendum with flg_type "A" (Addendum)';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_prog_notes_core.set_pn_addendum(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_epis_pn          => i_id_epis_pn,
                                                  i_flg_type            => pk_prog_notes_constants.g_epa_flg_type_addendum,
                                                  i_id_epis_pn_addendum => i_id_epis_pn_addendum,
                                                  i_pn_addendum         => i_pn_addendum,
                                                  o_epis_pn_addendum    => o_epis_pn_addendum,
                                                  o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_PN_ADDENDUM',
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
        
    END set_pn_addendum;

    /**
    * Create/update a Progress Notes Addendum
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_epis_pn             Progress Notes ID
    * @param   i_id_epis_pn_addendum Addendum ID
    * @param   i_pn_addendum         Progress Notes Addendum (text)    
    *  
    * @param   o_epis_pn_addendum    PN Addendum ID created or updated
    * @param   o_error               Error information
    *
    * @return  Boolean               True: Sucess, False: Fail
    *
    * @author  RUI.BATISTA
    * @version <2.6.0.5>
    * @since   31-01-2011
    */
    FUNCTION set_pn_addendum
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        i_pn_addendum         IN epis_pn_addendum.pn_addendum%TYPE,
        o_epis_pn_addendum    OUT epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.set_pn_addendum';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_prog_notes_core.set_pn_addendum(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_epis_pn          => i_id_epis_pn,
                                                  i_flg_type            => pk_prog_notes_constants.g_epa_flg_type_addendum,
                                                  i_id_epis_pn_addendum => i_id_epis_pn_addendum,
                                                  i_pn_addendum         => i_pn_addendum,
                                                  o_epis_pn_addendum    => o_epis_pn_addendum,
                                                  o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_PN_ADDENDUM',
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
        
    END set_pn_addendum;

    /**
    * Cancel a Progress Notes Addendum
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note 
    * @param   i_epis_pn_addendum      Progress Notes ID
    * @param   i_cancel_reason  Cancel reason ID
    * @param   i_notes_cancel Cancel notes
    *
    * @param   o_error        Error information
    *
    * @return  Boolean        True: Sucess, False: Fail
    *
    * @author  RUI.BATISTA
    * @version <2.6.0.5>
    * @since   31-01-2011
    */
    FUNCTION cancel_pn_addendum
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_area             IN VARCHAR2,
        i_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        i_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN epis_pn_addendum.notes_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.cancel_pn_addendum';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_prog_notes_core.cancel_pn_addendum(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_epis_pn_addendum => i_epis_pn_addendum,
                                                     i_cancel_reason    => i_cancel_reason,
                                                     i_notes_cancel     => i_notes_cancel,
                                                     o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CANCEL_PN_ADDENDUM',
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
    END cancel_pn_addendum;

    /**
    * Sign-Off an addendum
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note 
    * @param   i_epis_pn             Progress Notes ID    
    * @param   i_epis_pn_addendum    Addendum to signoff
    * @param   i_pn_addendum         Progress Notes Addendum (text)
    * @param   i_dt_signoff          Sign-off date
    * @param   i_flg_just_save       Just Save flag (Y- Just Save, N- Sign-off
    * @param   i_flg_edited          Edited addentum? (Y- Yes, N- No)
    *
    * @param   o_epis_pn_addendum    PN Addendum ID created or updated
    * @param   o_error        Error information
    *
    * @return  Boolean        True: Sucess, False: Fail
    *
    * @author  RUI.BATISTA
    * @version <2.6.0.5>
    * @since   01-02-2011
    */
    FUNCTION set_signoff_addendum
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_area             IN VARCHAR2,
        i_id_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        i_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        i_pn_addendum      IN epis_pn_addendum.pn_addendum%TYPE,
        i_dt_signoff       IN VARCHAR2,
        i_flg_just_save    IN VARCHAR2,
        i_flg_edited       IN VARCHAR2,
        i_flg_hist         IN VARCHAR2 DEFAULT 'Y',
        o_epis_pn_addendum OUT epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.set_signoff_addendum';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_prog_notes_core.set_signoff_addendum(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_id_epis_pn       => i_id_epis_pn,
                                                       i_epis_pn_addendum => i_epis_pn_addendum,
                                                       i_pn_addendum      => i_pn_addendum,
                                                       i_dt_signoff       => NULL,
                                                       i_flg_just_save    => i_flg_just_save,
                                                       i_flg_edited       => i_flg_edited,
                                                       i_flg_hist         => i_flg_hist,
                                                       o_epis_pn_addendum => o_epis_pn_addendum,
                                                       o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_SIGNOFF_ADDENDUM',
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
    END set_signoff_addendum;

    /**
    * Get addendum for the sign-off screen
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_epis_pn_addendum   Addendum ID
    *
    * @param   o_addendum           Addendum text
    * @param   o_error              Error information
    *
    * @return  Boolean              True: Sucess, False: Fail
    *
    * @author  RUI.BATISTA
    * @version <2.6.0.5>
    * @since   11-02-2011
    */
    FUNCTION get_pn_addendum
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_addendum         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.get_pn_addendum';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'GET_PN_ADDENDUM');
        IF NOT pk_prog_notes_utils.get_pn_addendum(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_epis_pn_addendum => i_epis_pn_addendum,
                                                   o_addendum         => o_addendum,
                                                   o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_addendum);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_addendum);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DATA_IMPORT',
                                              o_error);
            RETURN FALSE;
    END get_pn_addendum;

    /**
    * Saves work data into progress notes tables
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis_pn      Progress note identifier
    * @param   i_epis_pn_work Progress note identifier in work table
    *
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  RUI.SPRATLEY
    * @version 2.6.0.5
    * @since   31-01-2011
    */
    FUNCTION set_save_work_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_pn      IN NUMBER,
        i_epis_pn_work IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.set_save_work_data';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_prog_notes_core.set_save_work_data(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_epis_pn      => i_epis_pn,
                                                     i_epis_pn_work => i_epis_pn_work,
                                                     o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_SAVE_WORK_DATA',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END set_save_work_data;

    /**
    * Cancel progress note
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note 
    * @param   i_epis_pn        Progress note identifier
    * @param   i_cancel_reason  Cancel reason identifier
    *
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  RUI.SPRATLEY
    * @version 2.6.0.5
    * @since   01-02-2011
    */
    FUNCTION cancel_progress_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_area          IN VARCHAR2,
        i_epis_pn       IN NUMBER,
        i_cancel_reason IN NUMBER,
        i_notes_cancel  IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_show  VARCHAR2(1);
        l_msg_title VARCHAR2(1);
        l_msg_text  VARCHAR2(1);
        l_button    VARCHAR2(1);
    
        l_id_epis_documentation table_number;
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.cancel_progress_note';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_prog_notes_core.cancel_progress_note(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_epis_pn       => i_epis_pn,
                                                       i_cancel_reason => i_cancel_reason,
                                                       i_notes_cancel  => i_notes_cancel,
                                                       o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --no caso da nursing mental discharge, quando se cancela a nota, as discharge notes devem ser canceladas 
        IF i_area = pk_prog_notes_constants.g_area_nmd
        THEN
        
            SELECT e.id_epis_documentation
              BULK COLLECT
              INTO l_id_epis_documentation
              FROM epis_documentation e
              JOIN epis_pn ep
                ON ep.id_episode = e.id_episode
             WHERE ep.id_epis_pn = i_epis_pn
               AND e.id_doc_area = pk_prog_notes_constants.g_discharge_notes
               AND e.flg_status != pk_alert_constant.g_cancelled;
        
            FOR idx IN 1 .. l_id_epis_documentation.count
            LOOP
                IF NOT pk_touch_option.cancel_epis_doc_no_commit(i_lang          => i_lang,
                                                                 i_prof          => i_prof,
                                                                 i_id_epis_doc   => l_id_epis_documentation(idx),
                                                                 i_notes         => i_notes_cancel,
                                                                 i_test          => pk_alert_constant.g_no,
                                                                 i_cancel_reason => i_cancel_reason,
                                                                 o_flg_show      => l_flg_show,
                                                                 o_msg_title     => l_msg_title,
                                                                 o_msg_text      => l_msg_text,
                                                                 o_button        => l_button,
                                                                 o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END LOOP;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CANCEL_PROGRESS_NOTE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END cancel_progress_note;

    /**
    * Sign off a progress note
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_area                      Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note 
    * @param   i_epis_pn                   Progress note identifier
    * @param   i_flg_edited                Indicate if the SOAP block was edited
    * @param   i_pn_soap_block             Soap Block array with ids
    * @param   i_pn_signoff_note           Notes array
    * @param   i_flg_just_save             Indicate if its just to save or to signoff
    * @param   i_flg_showed_just_save      Indicates if just save screen showed or not
    *
    * @param   o_error                     Error information
    *
    * @value   i_flg_just_save             {*} 'Y'- Yes {*} 'N'- No
    * @value   i_flg_showed_just_save      {*} 'Y'- screen was showed to Professional {*} 'N'- screen didn't showed to Professional
    *
    * @return                              Returns TRUE if success, otherwise returns FALSE
    *
    * @author                              RUI.SPRATLEY
    * @version                             2.6.0.5
    * @since                               02-02-2011
    *
    * @author                              ANTONIO.NETO
    * @version                             2.6.2
    * @since                               19-Apr-2012
    */
    FUNCTION set_sign_off
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_area                 IN VARCHAR2,
        i_epis_pn              IN epis_pn.id_epis_pn%TYPE,
        i_flg_edited           IN table_varchar,
        i_pn_soap_block        IN table_number,
        i_pn_signoff_note      IN table_clob,
        i_flg_just_save        IN VARCHAR2,
        i_flg_showed_just_save IN VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.set_sign_off';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_prog_notes_core.set_sign_off(i_lang                 => i_lang,
                                               i_prof                 => i_prof,
                                               i_epis_pn              => i_epis_pn,
                                               i_flg_edited           => i_flg_edited,
                                               i_pn_soap_block        => i_pn_soap_block,
                                               i_pn_signoff_note      => i_pn_signoff_note,
                                               i_flg_just_save        => i_flg_just_save,
                                               i_flg_showed_just_save => i_flg_showed_just_save,
                                               o_error                => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_SIGN_OFF',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END set_sign_off;

    /********************************************************************************************
    * Returns Number of records to display in each page. to be used on the history pagging
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE            Episode Identifier
    * @param I_AREA                  Area internal name description
    * @param O_NUM_RECORDS           number of records per page
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        Sofia Mendes
    * @since                         28-Jan-2011
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_num_page_records_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_area        IN pn_area.internal_name%TYPE,
        o_num_records OUT PLS_INTEGER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        err_general_exception EXCEPTION;
    BEGIN
        g_error := 'CALL pk_prog_notes_core.GET_NUM_PAGE_RECORDS_HIST';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_num_page_records_hist(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_id_episode  => i_id_episode,
                                                             i_area        => i_area,
                                                             o_num_records => o_num_records,
                                                             o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            o_num_records := 0;
            RETURN FALSE;
        WHEN OTHERS THEN
            o_num_records := 0;
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NUM_PAGE_RECORDS_HIST',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_num_page_records_hist;

    /**
    * Returns the note detail or history.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param i_id_epis_pn             Note Id     
    * @param i_flg_screen             D- detail screen; H- History screen
    * @param o_data                   notes data (cursor with labels, format types, note id,...)
    * @param o_values                 Clobs values list    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_notes_det_history
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        i_flg_screen IN VARCHAR2,
        o_data       OUT pk_types.cursor_type,
        o_values     OUT table_clob,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note_ids table_number;
    BEGIN
        g_error := 'CALL pk_prog_notes_grids.get_notes_det_history';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_notes_det_history(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_ids_epis_pn     => table_number(i_id_epis_pn),
                                                         i_flg_screen      => i_flg_screen,
                                                         i_flg_report_type => NULL,
                                                         i_start_record    => NULL,
                                                         i_num_records     => NULL,
                                                         o_data            => o_data,
                                                         o_values          => o_values,
                                                         o_note_ids        => l_note_ids,
                                                         o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NOTES_DET_HISTORY',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_notes_det_history;

    /**
    * Returns the note detail or history.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param i_id_epis_pn             Note Id     
    * @param i_flg_screen             D- detail screen; H- History screen
    * @param o_data                   notes data (cursor with labels, format types, note id,...)
    * @param o_values                 Clobs values list    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_notes_det_history
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_pn   IN epis_pn.id_epis_pn%TYPE,
        i_flg_screen   IN VARCHAR2,
        i_start_record IN NUMBER,
        i_num_records  IN NUMBER,
        o_data         OUT pk_types.cursor_type,
        o_values       OUT table_clob,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note_ids table_number;
    BEGIN
        g_error := 'CALL pk_prog_notes_grids.get_notes_det_history';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_notes_det_history(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_ids_epis_pn     => table_number(i_id_epis_pn),
                                                         i_flg_screen      => i_flg_screen,
                                                         i_flg_report_type => NULL,
                                                         i_start_record    => i_start_record,
                                                         i_num_records     => i_num_records,
                                                         o_data            => o_data,
                                                         o_values          => o_values,
                                                         o_note_ids        => l_note_ids,
                                                         o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NOTES_DET_HISTORY',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_notes_det_history;

    /*******************************************************************************************************************************************
    * get_notes_history_count          Get number of all records in history associated to a given note.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_epis_pn             Note identifier
    * @param o_num_records            The number of records in history + actual info
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR    
    
    * 
    * @return                        Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          27-Jan-2011
    *******************************************************************************************************************************************/
    FUNCTION get_notes_history_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE,
        o_num_records OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_prog_notes_core.get_epis_pnotes_count';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_notes_history_count(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_id_epis_pn  => i_id_epis_pn,
                                                           o_num_records => o_num_records,
                                                           o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            o_num_records := 0;
            RETURN FALSE;
        WHEN OTHERS THEN
            o_num_records := 0;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_notes_history_count',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_notes_history_count;

    /**
    * Returns the note detail or history.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param i_id_epis_pn             Note Id     
    * @param i_flg_screen             D- detail screen; H- History screen
    * @param o_data                   notes data (cursor with labels, format types, note id,...)
    * @param o_values                 Clobs values list    
    * @param o_note_type_desc         Note type desc
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_notes_history
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE,
        i_start_record   IN NUMBER,
        i_num_records    IN NUMBER,
        o_data           OUT pk_types.cursor_type,
        o_values         OUT table_clob,
        o_note_type_desc OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note_ids table_number;
    BEGIN
        g_error := 'CALL pk_prog_notes_grids.get_notes_det_history';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_notes_det_history(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_ids_epis_pn     => table_number(i_id_epis_pn),
                                                         i_flg_screen      => 'H',
                                                         i_flg_report_type => NULL,
                                                         i_start_record    => i_start_record,
                                                         i_num_records     => i_num_records,
                                                         o_data            => o_data,
                                                         o_values          => o_values,
                                                         o_note_ids        => l_note_ids,
                                                         o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_prog_notes_utils.get_note_type_desc';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_note_type_desc(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_pn_note_type => pk_prog_notes_utils.get_note_type(i_lang       => i_lang,
                                                                                                             i_prof       => i_prof,
                                                                                                             i_id_epis_pn => i_id_epis_pn),
                                                      o_desc            => o_note_type_desc,
                                                      o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NOTES_DET_HISTORY',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_notes_history;

    /**
    * Returns the note detail or history.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param i_id_epis_pn             Note Id     
    * @param i_flg_screen             D- detail screen; H- History screen
    * @param o_data                   notes data (cursor with labels, format types, note id,...)
    * @param o_values                 Clobs values list    
    * @param o_note_type_desc         Note type desc
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_notes_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE,
        o_data           OUT pk_types.cursor_type,
        o_values         OUT table_clob,
        o_note_type_desc OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note_ids table_number;
    BEGIN
        g_error := 'CALL pk_prog_notes_grids.get_notes_det_history';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_notes_det_history(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_ids_epis_pn     => table_number(i_id_epis_pn),
                                                         i_flg_screen      => 'D',
                                                         i_flg_report_type => NULL,
                                                         i_start_record    => NULL,
                                                         i_num_records     => NULL,
                                                         o_data            => o_data,
                                                         o_values          => o_values,
                                                         o_note_ids        => l_note_ids,
                                                         o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_prog_notes_utils.get_note_type_desc';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_note_type_desc(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_pn_note_type => pk_prog_notes_utils.get_note_type(i_lang       => i_lang,
                                                                                                             i_prof       => i_prof,
                                                                                                             i_id_epis_pn => i_id_epis_pn),
                                                      o_desc            => o_note_type_desc,
                                                      o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_notes_detail',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_notes_detail;

    /**
    * Returns the note detail or history for arabic free text note.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param i_id_epis_pn             Note Id     
    * @param i_flg_screen             D- detail screen; H- History screen
    * @param o_data                   notes data (cursor with labels, format types, note id,...)
    * @param o_values                 Clobs values list    
    * @param o_note_type_desc         Note type desc
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Vítor Sá
    * @version               2.7.4.6
    * @since                03-Dec-2018
    */
    FUNCTION get_notes_arabic
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn     IN table_number,
        o_data           OUT pk_types.cursor_type,
        o_values         OUT table_clob,
        o_arabic_field   OUT table_clob,
        o_note_type_desc OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note_ids        table_number;
        l_arabic_note_ids table_number;
        l_arabic_field    table_clob := table_clob();
    BEGIN
    
        SELECT column_value id_epis_pn
          BULK COLLECT
          INTO l_arabic_note_ids
          FROM TABLE(i_id_epis_pn) t
          JOIN epis_pn e
            ON e.id_epis_pn = t.column_value
         WHERE e.id_pn_note_type IN (pk_prog_notes_constants.g_note_type_arabic_ft,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_psy,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_sw,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_cdc_vn,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_cdc_ia,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_cdc_pn,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_rc_pn,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_rc_vn)
           AND e.flg_status != 'C';
    
        IF l_arabic_note_ids.count > 0
        THEN
            g_error := 'CALL pk_prog_notes_grids.get_notes_det_history';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_prog_notes_grids.get_notes_det_history(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_ids_epis_pn     => l_arabic_note_ids,
                                                             i_flg_screen      => 'D',
                                                             i_flg_report_type => NULL,
                                                             i_start_record    => NULL,
                                                             i_num_records     => NULL,
                                                             o_data            => o_data,
                                                             o_values          => o_values,
                                                             o_note_ids        => l_note_ids,
                                                             o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'CALL pk_prog_notes_utils.get_note_type_desc';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_prog_notes_utils.get_note_type_desc(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_pn_note_type => pk_prog_notes_constants.g_note_type_arabic_ft,
                                                          o_desc            => o_note_type_desc,
                                                          o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            pk_prog_notes_utils.get_arabic_fields(i_note_ids => l_arabic_note_ids, o_arabic_field => o_arabic_field);
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_notes_detail',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_notes_arabic;

    /**
    * Returns the notes to the summary grid.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_epis_pn_work        Note identifier
    * @param i_id_pn_note_type        Note type id. 3-Progress Note; 4-Prolonged Progress Note; 5-Intensive Care Note; 2-History and Physician Note
    * @param i_flg_definitive         Save PN in the definitive model (Y- YES, N- NO)
    * @param i_id_epis_pn_det_task    Task Ids that have to be syncronized
    * @param i_id_pn_soap_block       Soap block id
    * @param o_data                   notes data
    * @param o_text_blocks            Texts that compose the note
    * @param o_text_comments          Comments cursor
    * @param o_suggested              Texts that compose the note with the suggested records    
    * @param o_configs                Dynamic configs: flg_import_available; flg_editable      
    * @param o_data_blocks            Dynamic data blocks (date data blocks)
    * @param o_buttons                Dynamic buttons (template records)
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author  RUI.SPRATLEY
    * @version 2.6.0.5
    * @since   04-02-2011
    */
    FUNCTION get_work_notes_core
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_pn_work     IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_note_type     IN epis_pn.id_pn_note_type%TYPE,
        i_flg_definitive      IN VARCHAR2,
        i_id_epis_pn_det_task IN table_number,
        i_id_pn_soap_block    IN table_number,
        o_data                OUT pk_types.cursor_type,
        o_text_blocks         OUT pk_types.cursor_type,
        o_text_comments       OUT pk_types.cursor_type,
        o_suggested           OUT pk_types.cursor_type,
        o_configs             OUT NOCOPY pk_types.cursor_type,
        o_data_blocks         OUT NOCOPY pk_types.cursor_type,
        o_buttons             OUT NOCOPY pk_types.cursor_type,
        o_cancelled           OUT NOCOPY pk_types.cursor_type,
        o_doc_reg             OUT NOCOPY pk_types.cursor_type,
        o_doc_val             OUT NOCOPY pk_types.cursor_type,
        o_template_layouts    OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component  OUT NOCOPY pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_prog_notes_core.get_work_notes_core';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_core.get_notes_core(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_episode          => i_id_episode,
                                                 i_id_epis_pn          => i_id_epis_pn_work,
                                                 i_id_pn_note_type     => i_id_pn_note_type,
                                                 i_id_epis_pn_det_task => i_id_epis_pn_det_task,
                                                 i_id_pn_soap_block    => i_id_pn_soap_block,
                                                 o_data                => o_data,
                                                 o_text_blocks         => o_text_blocks,
                                                 o_text_comments       => o_text_comments,
                                                 o_suggested           => o_suggested,
                                                 o_configs             => o_configs,
                                                 o_data_blocks         => o_data_blocks,
                                                 o_buttons             => o_buttons,
                                                 o_cancelled           => o_cancelled,
                                                 o_doc_reg             => o_doc_reg,
                                                 o_doc_val             => o_doc_val,
                                                 o_template_layouts    => o_template_layouts,
                                                 o_doc_area_component  => o_doc_area_component,
                                                 o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
        
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_text_blocks);
            pk_types.open_my_cursor(i_cursor => o_text_comments);
            pk_types.open_my_cursor(i_cursor => o_suggested);
            pk_types.open_my_cursor(i_cursor => o_doc_reg);
            pk_types.open_my_cursor(i_cursor => o_doc_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_WORK_NOTES_CORE',
                                              o_error    => o_error);
            ROLLBACK;
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_text_blocks);
            pk_types.open_my_cursor(i_cursor => o_text_comments);
            pk_types.open_my_cursor(i_cursor => o_suggested);
            pk_types.open_my_cursor(i_cursor => o_doc_reg);
            pk_types.open_my_cursor(i_cursor => o_doc_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_work_notes_core;

    /**
    * sincronize note records. When a record is created througth the help save. It is necessary to syncronize the record
    * to synch it (the data block can be configured to be not synch).
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_epis_pn             Note identifier
    * @param i_id_pn_note_type        Note type id. 3-Progress Note; 4-Prolonged Progress Note; 5-Intensive Care Note; 2-History and Physician Note
    * @param i_id_epis_pn_det_task    Task Ids that have to be syncronized
    * @param i_id_pn_soap_block       Soap block id    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author  Sofia Mendes
    * @version 2.6.0.5
    * @since   04-02-2011
    */

    FUNCTION set_note_synch
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_note_type     IN epis_pn.id_pn_note_type%TYPE,
        i_id_epis_pn_det_task IN table_number,
        i_id_pn_soap_block    IN table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_prog_notes_core.get_work_notes_core';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_core.set_note_synch(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_episode          => i_id_episode,
                                                 i_id_epis_pn          => i_id_epis_pn,
                                                 i_id_pn_note_type     => i_id_pn_note_type,
                                                 i_id_epis_pn_det_task => i_id_epis_pn_det_task,
                                                 i_id_pn_soap_block    => i_id_pn_soap_block,
                                                 o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_NOTE_SYNCH',
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
    END set_note_synch;

    /**
    * Update all data block's content for a PN. If the data doesn't exists yet, the record will be created.
    * the IN parameter Type allow for select if append or update should be done to the text.
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_episode              Episode ID
    * @param   i_epis_pn              Progress note ID
    * @param   i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note 
    * @param   i_flg_action           C-Create; U-update
    * @param   i_dt_pn_date           Progress Note date Array
    * @param   i_date_type            DH- Date hour; D-Date
    * @param   i_pn_soap_block        SOAP Block ID
    * @param   i_pn_data_block        Data Block ID
    * @param   i_id_task              Array of task IDs
    * @param   i_id_task_type         Array of task type IDs
    * @param   i_dep_clin_serv        Clinical Service ID
    * @param   i_epis_pn_det          Progress note detail ID
    * @param   i_pn_note              Progress note detail text 
    * @param   i_flg_add_remove       Add or remove block from note. A R-Removed block is like a canceled one.
    * @param   i_id_pn_note_type      Progress Note type (P-progress note; L-prolonged progress note; CC-intensive care note; H-history and physician note) 
    * @param   i_flg_app_upd          Type of operation: A-Append, U-Update
    * @param   i_flg_definitive       Save PN in the definitive model (Y- YES, N- NO)
    * @param   i_epis_pn_det_task     Array of PN task details
    * @param   i_pn_note_task         Array of PN task descriptions
    * @param   i_flg_add_rem_task     Array of task status (A- Active, R- Removed)
    * @param   i_flg_table_origin     Flag origin table for documentation ( D - documentation, A - Anamnesis, S - Review of system)
    * @param   i_id_task_aggregator   For analysis and exam recurrences, an imported registry will only be uniquely 
    *                                 Identified by id_task (id_analysis/id_exam) + i_id_task_aggregator
    * @param   i_dt_task              Task dates
    * @param   i_id_task_parent       Parent task identifier for comments functionality
    * @param   i_flg_task_parent      Flag tells where i_id_task_parent is a taskid or id_epis_pn_det_task
    * @param   i_id_multichoice       Array of tasks identifiers for cases that have more than one parameter (multichoice on exam results)
    *
    * @param   o_id_epis_pn           ID of the PN created 
    * @param   o_flg_reload           Tells UX layer it It's needed the reload screen or not
    * @param   o_error                Error information
    *
    * @return  Boolean                True: Sucess, False: Fail
    *
    * @value   o_flg_reload           {*} 'Y'- Yes {*} 'N'- No
    * @value   i_flg_task_parent      {*} 'Y'- Passed in i_id_task_parent the id_epis_pn_det_task {*} 'N'- Passed in i_id_task_parent the taskid
    *
    * @author                         RUI.BATISTA
    * @version                        <2.6.0.5>
    * @since                          04-02-2011
    */
    FUNCTION set_all_data_block_work
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_pn            IN epis_pn.id_epis_pn%TYPE,
        i_area               IN VARCHAR2,
        i_flg_action         IN VARCHAR2,
        i_flg_definitive     IN VARCHAR2,
        i_dt_pn_date         IN table_varchar,
        i_date_type          IN table_varchar,
        i_pn_soap_block      IN table_number,
        i_pn_data_block      IN table_number,
        i_id_task            IN table_table_number,
        i_id_task_type       IN table_table_number,
        i_dep_clin_serv      IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_epis_pn_det        IN table_number,
        i_pn_note            IN table_clob,
        i_flg_add_remove     IN table_varchar,
        i_id_pn_note_type    IN epis_pn.id_pn_note_type%TYPE,
        i_flg_app_upd        IN VARCHAR2,
        i_epis_pn_det_task   IN table_table_number,
        i_pn_note_task       IN table_table_clob,
        i_flg_add_rem_task   IN table_table_varchar,
        i_flg_table_origin   IN table_table_varchar DEFAULT NULL,
        i_id_task_aggregator IN table_table_number,
        i_dt_task            IN table_table_varchar,
        i_id_task_parent     IN table_table_number,
        i_flg_task_parent    IN VARCHAR2,
        i_id_multichoice     IN table_table_number,
        i_id_group_table     IN table_table_number,
        o_id_epis_pn         OUT epis_pn.id_epis_pn%TYPE,
        o_flg_reload         OUT VARCHAR2,
        o_dt_finished        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.set_all_data_block_work';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_core.set_all_data_block(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_episode            => i_episode,
                                                     i_epis_pn            => i_epis_pn,
                                                     i_dt_pn_date         => i_dt_pn_date,
                                                     i_flg_action         => i_flg_action,
                                                     i_date_type          => i_date_type,
                                                     i_pn_soap_block      => i_pn_soap_block,
                                                     i_pn_data_block      => i_pn_data_block,
                                                     i_id_task            => i_id_task,
                                                     i_id_task_type       => i_id_task_type,
                                                     i_dep_clin_serv      => i_dep_clin_serv,
                                                     i_epis_pn_det        => i_epis_pn_det,
                                                     i_pn_note            => i_pn_note,
                                                     i_flg_add_remove     => i_flg_add_remove,
                                                     i_id_pn_note_type    => i_id_pn_note_type,
                                                     i_flg_app_upd        => i_flg_app_upd,
                                                     i_flg_definitive     => i_flg_definitive,
                                                     i_epis_pn_det_task   => i_epis_pn_det_task,
                                                     i_pn_note_task       => i_pn_note_task,
                                                     i_flg_add_rem_task   => i_flg_add_rem_task,
                                                     i_flg_table_origin   => i_flg_table_origin,
                                                     i_id_task_aggregator => i_id_task_aggregator,
                                                     i_dt_task            => i_dt_task,
                                                     i_id_task_parent     => i_id_task_parent,
                                                     i_flg_task_parent    => i_flg_task_parent,
                                                     i_id_multichoice     => i_id_multichoice,
                                                     i_id_group_table     => i_id_group_table,
                                                     o_id_epis_pn         => o_id_epis_pn,
                                                     o_flg_reload         => o_flg_reload,
                                                     o_error              => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        g_error := 'CALL GET_JUMP_DATETIME';
        pk_alertlog.log_debug(g_error);
        IF NOT get_jump_datetime(i_lang => i_lang, i_prof => i_prof, o_dt_jump => o_dt_finished, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_ALL_DATA_BLOCK_WORK',
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
    END set_all_data_block_work;

    /**
    * Check if it is possible to create more addendums.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_epis_pn                 Note identifier
    * @param o_flg_show                   Y - It is necessary to show the popup.
    *                                     N - otherwise.                                     
    * @param o_msg_title                  Title
    * @param o_msg                        Message text
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                09-Feb-2011
    */
    FUNCTION check_create_addendums
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL check_max_addendums';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.check_create_addendums(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_epis_pn => i_id_epis_pn,
                                                          o_flg_show   => o_flg_show,
                                                          o_msg_title  => o_msg_title,
                                                          o_msg        => o_msg,
                                                          o_error      => o_error)
        
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_CREATE_ADDENDUMS',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END check_create_addendums;

    /**
    * Check if it is possible to create more notes.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_episode                 Episode identifier    
    * @param i_note_type                  Note type id
    * @param o_flg_show                   Y - It is necessary to show the popup.
    *                                     N - otherwise.                                     
    * @param o_msg_title                  Title
    * @param o_msg                        Message text
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                09-Feb-2011
    */
    FUNCTION check_create_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL check_max_addendums';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.check_create_notes(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_episode => i_id_episode,
                                                      i_note_type  => i_note_type,
                                                      o_flg_show   => o_flg_show,
                                                      o_msg_title  => o_msg_title,
                                                      o_msg        => o_msg,
                                                      o_error      => o_error)
        
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_CREATE_NOTES',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END check_create_notes;

    /**
    * Returns the notes to the summary grid.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_patient                Patient identifier
    * @param i_id_pn_note_type        Note type Identifier
    * @param i_id_epis_pn             Note type Identifier
    * @param o_data_1                 Grid data level 1
    * @param o_data_2                 Grid data level 2
    * @param o_data_3                 Grid data level 3
    * @param o_data_4                 Grid data level 4
    * @param o_data_5                 Grid data level 5
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         António Neto
    * @version                        2.6.1.2
    * @since                          27-Jul-2011
    */
    FUNCTION get_import_data
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_data_1          OUT pk_types.cursor_type,
        o_data_2          OUT pk_types.cursor_type,
        o_data_3          OUT pk_types.cursor_type,
        o_data_4          OUT pk_types.cursor_type,
        o_data_5          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_prog_notes_core.get_import_data';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_core.get_import_data(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_episode         => i_episode,
                                                  i_patient         => i_patient,
                                                  i_id_pn_note_type => i_id_pn_note_type,
                                                  i_id_epis_pn      => i_id_epis_pn,
                                                  o_data_1          => o_data_1,
                                                  o_data_2          => o_data_2,
                                                  o_data_3          => o_data_3,
                                                  o_data_4          => o_data_4,
                                                  o_data_5          => o_data_5,
                                                  o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_data_1);
            pk_types.open_my_cursor(i_cursor => o_data_2);
            pk_types.open_my_cursor(i_cursor => o_data_3);
            pk_types.open_my_cursor(i_cursor => o_data_4);
            pk_types.open_my_cursor(i_cursor => o_data_5);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_IMPORT_DATA',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_data_1);
            pk_types.open_my_cursor(i_cursor => o_data_2);
            pk_types.open_my_cursor(i_cursor => o_data_3);
            pk_types.open_my_cursor(i_cursor => o_data_4);
            pk_types.open_my_cursor(i_cursor => o_data_5);
            RETURN FALSE;
    END get_import_data;

    /********************************************************************************************
    * Returns the list of configs to the given note type.
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PN_NOTE_TYPE       Note Type Identifier 
    * @param I_ID_EPISODE            Episode Identifier 
    * @param O_CONFIGS               Cursor with all the configs for the note type
    * @param o_note_type_desc         Note type desc
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                        Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        António Neto
    * @since                         03-Aug-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_note_type_configs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        o_configs         OUT pk_types.cursor_type,
        o_note_type_desc  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF (i_id_pn_note_type IS NOT NULL)
        THEN
            g_error := 'CALL pk_prog_notes_core.GET_NOTE_TYPE_CONFIGS';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_prog_notes_utils.get_note_type_configs(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_id_pn_note_type => i_id_pn_note_type,
                                                             i_id_episode      => i_id_episode,
                                                             o_configs         => o_configs,
                                                             o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'CALL pk_prog_notes_utils.get_note_type_desc';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_prog_notes_utils.get_note_type_desc(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_pn_note_type => i_id_pn_note_type,
                                                          o_desc            => o_note_type_desc,
                                                          o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            o_note_type_desc := NULL;
            pk_types.open_my_cursor(i_cursor => o_configs);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_configs);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NOTE_TYPE_CONFIGS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_note_type_configs;

    /**************************************************************************
    * Return cursor with records for touch option area
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID
    * @param i_epis_doc               Table number with id_epis_documentation
    * @param i_epis_anamn             Table number with id_epis_anamnesis
    * @param i_epis_rev_sys           Table number with id_epis_review_systems
    * @param i_epis_obs               Table number with id_epis_observation
    * @param i_epis_past_fsh          Table number with id_pat_fam_soc_hist
    * @param i_epis_recomend          Table number with id_epis_recomend
    *
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/17                                
    **************************************************************************/
    FUNCTION get_import_epis_documentation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_epis_doc           IN table_number,
        i_epis_anamn         IN table_number,
        i_epis_rev_sys       IN table_number,
        i_epis_obs           IN table_number,
        i_epis_past_fsh      IN table_number,
        i_epis_recomend      IN table_number,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_IMPORT_EPIS_DOCUMENTATION';
        l_id_patient    patient.id_patient%TYPE;
        l_no_data_found_excep EXCEPTION;
    
    BEGIN
    
        g_error := 'GET PATIENT ID FOR ID_EPISODE : ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT e.id_patient
              INTO l_id_patient
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                RAISE l_no_data_found_excep;
        END;
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_AREA_VALUE_INTERNAL';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_doc_area_value_internal(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_episode         => i_id_episode,
                                                           i_id_patient         => l_id_patient,
                                                           i_doc_area           => NULL,
                                                           i_epis_doc           => i_epis_doc,
                                                           i_epis_anamn         => i_epis_anamn,
                                                           i_epis_rev_sys       => i_epis_rev_sys,
                                                           i_epis_obs           => i_epis_obs,
                                                           i_epis_past_fsh      => i_epis_past_fsh,
                                                           i_epis_recomend      => i_epis_recomend,
                                                           i_flg_show_fm        => pk_alert_constant.g_no,
                                                           o_doc_area_register  => o_doc_area_register,
                                                           o_doc_area_val       => o_doc_area_val,
                                                           o_template_layouts   => o_template_layouts,
                                                           o_doc_area_component => o_doc_area_component,
                                                           o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_no_data_found_excep THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   'There are no id_patient',
                                   g_error,
                                   g_owner,
                                   g_package,
                                   l_function_name);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
                /* Open out cursors */
                pk_touch_option.open_cur_doc_area_register(o_doc_area_register);
                pk_touch_option.open_cur_doc_area_val(o_doc_area_val);
                pk_types.open_my_cursor(o_template_layouts);
                pk_types.open_my_cursor(o_doc_area_component);
                RETURN FALSE;
            END;
        WHEN g_exception THEN
            /* Open out cursors */
            pk_touch_option.open_cur_doc_area_register(o_doc_area_register);
            pk_touch_option.open_cur_doc_area_val(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            /* Open out cursors */
            pk_touch_option.open_cur_doc_area_register(o_doc_area_register);
            pk_touch_option.open_cur_doc_area_val(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
    END get_import_epis_documentation;

    /**
    * Save an imported data block to a progress note
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_episode            Episode ID
    * @param   i_patient            Patient ID
    * @param   i_id_pn_note_type    Progress Note type (P-progress note; L-prolonged progress note; CC-intensive care note; H-history and physician note) 
    * @param   i_epis_pn            Progress note ID
    * @param   i_epis_pn_det        Progress note detail ID
    * @param   i_dep_clin_serv      Clinical Service ID
    * @param   i_pn_soap_block      SOAP Block ID
    * @param   i_pn_data_block      Data Block ID
    * @param   i_dt_begin           Start date to filter
    * @param   i_dt_end             End date to filter
    * @param   i_id_task_type       Array of task type ids
    * @param   i_id_pn_group        Group identifier
    * @param   i_id_epis_pn_det_task Epis_pn_det_task ID. To be used in templates when performing the copy and edit action, 
    *                                to replace the previous record (if configured to behave like that)         
    * @param   o_flg_imported       Flg indicating data imported Y/N
    * @param   o_id_epis_pn        Id of the created note
    * @param   o_error              Error information
    *
    * @return  Boolean        True: Sucess, False: Fail
    * 
    * @author  RUI.SPRATLEY
    * @version 2.6.0.5
    * @since   16-02-2011
    */
    FUNCTION import_data_block
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_id_pn_note_type     IN epis_pn.id_pn_note_type%TYPE,
        i_epis_pn             IN epis_pn.id_epis_pn%TYPE,
        i_epis_pn_det         IN epis_pn_det.id_epis_pn_det%TYPE,
        i_dep_clin_serv       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_soap_block          IN epis_pn_det.id_pn_soap_block%TYPE,
        i_data_block          IN epis_pn_det.id_pn_data_block%TYPE,
        i_dt_begin            IN VARCHAR2,
        i_dt_end              IN VARCHAR2,
        i_id_task_type        IN epis_pn_det_task.id_task_type%TYPE,
        i_id_pn_group         IN pn_group.id_pn_group%TYPE DEFAULT NULL,
        i_id_epis_pn_det_task IN epis_pn_det_task.id_epis_pn_det_task%TYPE,
        o_flg_imported        OUT VARCHAR2,
        o_id_epis_pn          OUT epis_pn.id_epis_pn%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_prog_notes_core.set_import_data_block';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_core.set_import_data_block(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_episode             => i_episode,
                                                        i_patient             => i_patient,
                                                        i_id_pn_note_type     => i_id_pn_note_type,
                                                        i_epis_pn             => i_epis_pn,
                                                        i_epis_pn_det         => i_epis_pn_det,
                                                        i_dep_clin_serv       => i_dep_clin_serv,
                                                        i_soap_block          => i_soap_block,
                                                        i_data_block          => i_data_block,
                                                        i_dt_begin            => i_dt_begin,
                                                        i_dt_end              => i_dt_end,
                                                        i_id_task_type        => i_id_task_type,
                                                        i_id_pn_group         => i_id_pn_group,
                                                        i_id_epis_pn_det_task => i_id_epis_pn_det_task,
                                                        o_flg_imported        => o_flg_imported,
                                                        o_id_epis_pn          => o_id_epis_pn,
                                                        o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'IMPORT_DATA_BLOCK',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END import_data_block;

    /**
    * Delete work tables
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis_pn      Progress note identifier
    *
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  RUI.SPRATLEY
    * @version 2.6.0.5
    * @since   31-01-2011
    */
    FUNCTION delete_work_tables
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis_pn IN NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.delete_work_tables';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_core.delete_work_tables(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_epis_pn => i_epis_pn,
                                                     o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'DELETE_WORK_TABLES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        
    END delete_work_tables;

    /**
    * Get just save status
    *
    * @param   i_lang             Professional preferred language
    * @param   i_prof             Professional identification and its context (institution and software)
    * @param   i_epis_pn          Progress note identifier
    *
    * @param   i_flg_just_save    Indicate if there is a just saved record (Y/N)
    * @param   o_error            Error information
    *
    * @return  Boolean
    *
    * @author  RUI.SPRATLEY
    * @version 2.6.0.5
    * @since   22-02-2011
    */
    FUNCTION get_flg_just_save
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        o_flg_just_save OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.get_flg_just_save';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_flg_just_save(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_epis_pn       => i_epis_pn,
                                                     o_flg_just_save => o_flg_just_save,
                                                     o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_FLG_JUST_SAVE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_flg_just_save;

    /**
    * Returns the actions to be displayed in summary screen paging filter options.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_episode                    episode identifier
    * @param i_id_epis_pn                 Selected note Id.
    *                                     If no note is selected this param should be null
    * @param i_area                       Area name. Ex: HP - History and Physician Notes Screen
    *                                     PN - Progress Note Screen
    * @param o_actions      actions data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_actions_pag_filter
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_area       IN pn_area.internal_name%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_prog_notes_core.get_actions_pag_filter';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_actions_pag_filter(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_episode => i_id_episode,
                                                          i_area       => i_area,
                                                          o_actions    => o_actions,
                                                          o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_actions);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ACTIONS_PAG_FILTER',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_actions);
            RETURN FALSE;
    END get_actions_pag_filter;

    /**************************************************************************
    * Returns a set of records done in a touch-option area for a specific id_epis_documentation
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID
    * @param i_id_epis_documentation  Epis documentation ID
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    *
    * @param   o_doc_area_register    Cursor with the doc area info register
    * @param   o_doc_area_val         Cursor containing the completed info for episode
    * @param   o_template_layouts     Cursor containing the layout for each template used
    * @param   o_doc_area_component   Cursor containing the components for each template used 
    * @param   o_id_doc_area          Documentation area ID 
    * @param   o_error                Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/03/03                                 
    **************************************************************************/
    FUNCTION get_epis_document_area_value
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_scope                 NUMBER,
        i_scope_type            IN VARCHAR2,
        o_doc_area_register     OUT pk_types.cursor_type,
        o_doc_area_val          OUT pk_types.cursor_type,
        o_template_layouts      OUT pk_types.cursor_type,
        o_doc_area_component    OUT pk_types.cursor_type,
        o_id_doc_area           OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_EPIS_DOCUMENT_AREA_VALUE';
    
    BEGIN
        g_error := 'CALL pk_prog_notes_core.GET_EPIS_DOCUMENT_AREA_VALUE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_core.get_epis_document_area_value(i_lang                  => i_lang,
                                                               i_prof                  => i_prof,
                                                               i_id_episode            => i_id_episode,
                                                               i_id_epis_documentation => i_id_epis_documentation,
                                                               i_scope                 => i_scope,
                                                               i_scope_type            => i_scope_type,
                                                               o_doc_area_register     => o_doc_area_register,
                                                               o_doc_area_val          => o_doc_area_val,
                                                               o_template_layouts      => o_template_layouts,
                                                               o_doc_area_component    => o_doc_area_component,
                                                               o_id_doc_area           => o_id_doc_area,
                                                               o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_touch_option.open_cur_doc_area_register(i_cursor => o_doc_area_register);
            pk_touch_option.open_cur_doc_area_val(i_cursor => o_doc_area_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_touch_option.open_cur_doc_area_register(i_cursor => o_doc_area_register);
            pk_touch_option.open_cur_doc_area_val(i_cursor => o_doc_area_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
            RETURN FALSE;
    END get_epis_document_area_value;

    /**************************************************************************
    * Return functionality help 
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_doc_area            Documentation area ID
    * 
    * @param   o_text                 Cursor with functionality help       
    * @param   o_error                Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/03/17                                 
    **************************************************************************/

    FUNCTION get_section_help_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        o_text        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_SECTION_HELP_TEXT';
    
    BEGIN
    
        g_error := 'CALL PK_PROG_NOTES_CORE.GET_SECTION_HELP_TEXT FUNCTION';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_prog_notes_utils.get_section_help_text(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_id_doc_area => i_id_doc_area,
                                                         o_text        => o_text,
                                                         o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_text);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_text);
        
            RETURN FALSE;
    END get_section_help_text;

    /**************************************************************************
    * When editing some data inserted by template validates
    * if the template was edited since the note creation date.
    * This is used because the physical exam template inserts vital signs values
    * and if the vital signs are edited in the vital signs area the template is updated.
    * However in the H&P appear the values inserted when the template was created. So,
    * when the user edits this template he should be notified that the template had been edited
    * after its insertion in the H&P area.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_epis_documentation  Epis documentation Id
    * @param i_id_epis_pn             Epis Progress Note Id
    * @param o_flg_edited             Y-the template was edited.
    *                                 N-otherwise    
    * @param o_error                  Error message
    *                                                                         
    * @author                         Sofia Mendes                       
    * @version                        2.6.1                                
    * @since                          19-Mai-2011                                
    **************************************************************************/
    FUNCTION check_show_edition_popup
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_epis_pn            IN epis_pn.id_epis_pn%TYPE,
        o_flg_show              OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL pk_prog_notes_core.check_template_edited';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.check_show_edition_popup(i_lang                  => i_lang,
                                                            i_prof                  => i_prof,
                                                            i_id_epis_documentation => i_id_epis_documentation,
                                                            i_id_epis_pn            => i_id_epis_pn,
                                                            o_flg_show              => o_flg_show,
                                                            o_msg_title             => o_msg_title,
                                                            o_msg                   => o_msg,
                                                            o_error                 => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_SHOW_EDITION_POPUP',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_show_edition_popup;

    /**
    * Get the max notes of all the note type of an area.
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_area               Area internal name
    *
    * @param   o_area_max_notes     Area max notes
    * @param   o_error              Error information
    *
    * @return  Boolean              True: Sucess, False: Fail
    *
    * @author  Sofia Mendes
    * @version <2.6.1.2>
    * @since   18-08-2011
    */
    FUNCTION get_area_max_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_area           IN pn_area.internal_name%TYPE,
        o_area_max_notes OUT PLS_INTEGER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL pk_prog_notes_utils.get_area_max_notes';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_area_max_notes(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_episode     => i_id_episode,
                                                      i_area           => i_area,
                                                      o_area_max_notes => o_area_max_notes,
                                                      o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_AREA_MAX_NOTES',
                                              o_error);
        
            RETURN FALSE;
    END get_area_max_notes;

    /********************************************************************************************
    * Gets a summary of PN Notes for a Patient
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PN_AREA            Area Identifier to filter on    
    * @param I_SCOPE                 Scope ID
    *                                     E-Episode ID
    *                                     V-Visit ID
    *                                     P-Patient ID
    * @param I_SCOPE_TYPE            Scope type
    *                                     E-Episode
    *                                     V-Visit
    *                                     P-Patient
    * @param I_FLG_SCOPE             Flag to filter the scope
    *                                     S-Summary 1.st level (last Note)
    *                                     D-Detailed 2.nd level (Last Note by each Area)
    *                                     C-Complete 3.rd level (All Notes for Note Type selected)
    * @param I_INTERVAL             Interval to filter
    *                                     D-Last 24H
    *                                     W-Week
    *                                     M-Month
    *                                     A-All
    * @param O_DATA                  Cursor with PN Data to show
    * @param O_TITLE                 Variable that indicates the title that should appear on viewer
    * @param O_SCREEN_NAME           Variable that indicates the Area SWF Screen Name
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        António Neto
    * @since                         08-Aug-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_viewer_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pn_area      IN pn_area.id_pn_area%TYPE,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_flg_scope       IN VARCHAR2,
        i_interval        IN VARCHAR2,
        i_flg_viewer_type IN pn_note_type.flg_viewer_type%TYPE,
        o_data            OUT pk_types.cursor_type,
        o_title           OUT sys_message.desc_message%TYPE,
        o_screen_name     OUT pn_area.screen_name%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL pk_prog_notes_utils.get_area_max_notes';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_viewer_notes(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_pn_area      => i_id_pn_area,
                                                    i_scope           => i_scope,
                                                    i_scope_type      => i_scope_type,
                                                    i_flg_scope       => i_flg_scope,
                                                    i_interval        => i_interval,
                                                    i_flg_viewer_type => i_flg_viewer_type,
                                                    o_data            => o_data,
                                                    o_title           => o_title,
                                                    o_screen_name     => o_screen_name,
                                                    o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_VIEWER_NOTES',
                                              o_error);
        
            RETURN FALSE;
    END get_viewer_notes;

    /**
    * Get the import detail info: description of the task and signature
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_pn_task_type           Task type id
    * @param i_id_task                Task id
    * @param i_id_episode             Episode id: in which the task was requested
    * @param i_dt_register            Task registration date
    * @param i_prof_register          Professional that performed the request
    * @param i_id_data_block          Data block used to get description info
    * @param i_id_soap_block          Soap block used to get description info
    * @param i_id_note_type           Note type used to get description info
    *
    * @param o_task_desc              Task detailed description
    * @param o_signature              Signature
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          29-Set-2011
    */
    FUNCTION get_task_detailed_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task_type  IN table_number,
        i_id_task       IN table_number,
        i_id_episode    IN table_number,
        i_dt_register   IN table_varchar,
        i_prof_register IN table_number,
        i_id_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        o_description   OUT table_clob,
        o_signature     OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count      PLS_INTEGER := i_id_task.count;
        l_id_episode episode.id_episode%TYPE;
    BEGIN
        --If doesn't exists an id_episode for each array positions read the first one
        IF i_id_episode.count <> l_count
           AND i_id_episode.exists(1)
        THEN
            l_id_episode := i_id_episode(1);
        END IF;
    
        o_description := table_clob();
        o_signature   := table_varchar();
    
        FOR item IN 1 .. l_count
        LOOP
        
            o_description.extend();
            o_signature.extend();
            g_error := 'CALL pk_prog_notes_utils.get_import_detail';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_prog_notes_utils.get_import_detail(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_id_task_type  => i_id_task_type(item),
                                                    i_id_task       => i_id_task(item),
                                                    i_id_episode    => CASE
                                                                           WHEN l_id_episode IS NULL THEN
                                                                            i_id_episode(item)
                                                                           ELSE
                                                                            l_id_episode
                                                                       END,
                                                    i_dt_register   => i_dt_register(item),
                                                    i_prof_register => i_prof_register(item),
                                                    i_id_data_block => i_id_data_block,
                                                    i_id_soap_block => i_id_soap_block,
                                                    i_id_note_type  => i_id_note_type,
                                                    o_task_desc     => o_description(item),
                                                    o_signature     => o_signature(item),
                                                    o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
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
                                              'GET_TASK_DETAILED_DESC',
                                              o_error);
        
            RETURN FALSE;
    END get_task_detailed_desc;

    /**
    * Returns the suggested records for the episode
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_episode                episode identifier
    * @param      i_id_pn_note_type        Note type identifier
    * @param      i_id_epis_pn             Note identifier
    * @param      o_suggested              Texts that compose the note with the suggested records
    *
    * @param      o_error                  error information
    *
    * @return                              false if errors occur, true otherwise
    *
    * @author                              ANTONIO.NETO
    * @version                             2.6.2
    * @since                               08-Mar-2012
    */
    FUNCTION get_work_suggest_records
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN epis_pn.id_pn_note_type%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_suggested       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PK_PROG_NOTES_CORE.GET_WORK_SUGGEST_RECORDS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_core.get_suggest_records(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_episode      => i_id_episode,
                                                      i_id_pn_note_type => i_id_pn_note_type,
                                                      i_id_epis_pn      => i_id_epis_pn,
                                                      o_suggested       => o_suggested,
                                                      o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_suggested);
            RETURN FALSE;
        WHEN OTHERS THEN
            ROLLBACK;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_WORK_SUGGEST_RECORDS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_suggested);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_work_suggest_records;

    /**
    * Returns the suggested records for the episode. 
    * To be used in the discharge screen: only suggestes records to the physician professionals
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_episode                episode identifier
    * @param      i_id_pn_note_type        Note type identifier
    * @param      i_id_epis_pn             Note identifier
    * @param      o_suggested              Texts that compose the note with the suggested records
    *
    * @param      o_error                  error information
    *
    * @return                              false if errors occur, true otherwise
    *
    * @author                              Sofia Mendes
    * @version                             2.6.3.1
    * @since                               17-Jan-2012
    */
    FUNCTION get_suggest_records_disch
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN epis_pn.id_pn_note_type%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_suggested       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pn_note_type t_rec_note_type;
    BEGIN
        g_error := 'CALL PK_PROG_NOTES_CORE.GET_WORK_SUGGEST_RECORDS';
        pk_alertlog.log_debug(g_error);
    
        IF i_id_pn_note_type IS NOT NULL
        THEN
            l_pn_note_type := pk_prog_notes_utils.get_note_type_config(i_lang                => i_lang,
                                                                       i_prof                => i_prof,
                                                                       i_id_episode          => i_id_episode,
                                                                       i_id_profile_template => NULL,
                                                                       i_id_market           => NULL,
                                                                       i_id_department       => NULL,
                                                                       i_id_dep_clin_serv    => NULL,
                                                                       i_id_epis_pn          => NULL,
                                                                       i_id_pn_note_type     => i_id_pn_note_type,
                                                                       i_software            => NULL);
            IF l_pn_note_type.flg_discharge_warning = pk_alert_constant.g_yes
            THEN
        IF NOT pk_prog_notes_core.get_suggest_records_disch(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_id_episode      => i_id_episode,
                                                            i_id_pn_note_type => i_id_pn_note_type,
                                                            i_id_epis_pn      => i_id_epis_pn,
                                                            o_suggested       => o_suggested,
                                                            o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
            ELSE
                pk_types.open_my_cursor(i_cursor => o_suggested);
            END IF;
    
        COMMIT;
        ELSE
            pk_types.open_my_cursor(i_cursor => o_suggested);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_suggested);
            RETURN FALSE;
        WHEN OTHERS THEN
            ROLLBACK;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SUGGEST_RECORDS_DISCH',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_suggested);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_suggest_records_disch;

    /********************************************************************************************
    * get the actions available for a given record.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id     
    * @param       i_id_task_type            Type of the task
    * @param       i_id_task                 Task reference ID    
    * @param       i_flg_review              Y-the review action should be available. N-otherwisse
    * @param       i_flg_remove              Y-the remove action should be available. N-otherwisse
    * @param       i_flg_review_all          Y-the review action should be available. N-otherwisse
    * @param       i_flg_table_origin        Table origin from templates
    * @param       i_flg_write               Y-it is allowed to write in the task data block. N-otherwisse
    * @param       i_flg_actions_available   Y-The area actions are available. N-otherwisse
    * @param       i_flg_editable            A-All editable; N-not editable; T-text editable
    * @param       i_flg_dblock_editable     Y- Tis data block has edition permission. N-Otherwise
    * @param       i_id_pn_note_type         Note type Id
    * @param       i_id_pn_data_block        Data block Id
    * @param       i_id_pn_soap_block        Soap block Id
    * @param       o_actions                 list of actions
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 19-Mar-2012
    ********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_id_task_type          IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        i_flg_review            IN VARCHAR2,
        i_flg_remove            IN VARCHAR2,
        i_flg_review_all        IN pn_note_type_mkt.flg_review_all%TYPE,
        i_flg_table_origin      IN epis_pn_det_task.flg_table_origin%TYPE,
        i_flg_actions_available IN pn_dblock_mkt.flg_actions_available%TYPE,
        i_flg_editable          IN VARCHAR2,
        i_flg_dblock_editable   IN pn_dblock_mkt.flg_editable%TYPE,
        i_id_pn_note_type       IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_data_block      IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block      IN pn_soap_block.id_pn_soap_block%TYPE,
        o_actions               OUT NOCOPY pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PK_PROG_NOTES_CORE.GET_WORK_SUGGEST_RECORDS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_actions(i_lang                  => i_lang,
                                               i_prof                  => i_prof,
                                               i_episode               => i_episode,
                                               i_id_task_type          => i_id_task_type,
                                               i_id_task               => i_id_task,
                                               i_flg_review            => i_flg_review,
                                               i_flg_remove            => i_flg_remove,
                                               i_flg_review_all        => i_flg_review_all,
                                               i_flg_table_origin      => i_flg_table_origin,
                                               i_flg_actions_available => i_flg_actions_available,
                                               i_flg_editable          => i_flg_editable,
                                               i_flg_dblock_editable   => i_flg_dblock_editable,
                                               i_id_pn_note_type       => i_id_pn_note_type,
                                               i_id_pn_data_block      => i_id_pn_data_block,
                                               i_id_pn_soap_block      => i_id_pn_soap_block,
                                               o_actions               => o_actions,
                                               o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_actions);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ACTIONS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions;

    /********************************************************************************************
    * perform an action that does not need to load a screen (only call a BD function).
    * The action to be performed is identified by the id_task_Type and the id_Action.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              episode id
    * @param       i_id_action               action id
    * @param       i_id_task_type            task type ID
    * @param       i_id_task                 task ID    
    * @param       o_flg_validated           validated flag (which indicates if an auxiliary  screen should be loaded or not)
    * @param       o_error                   error message   
    *
    * @value       o_flg_validated           {*} 'Y' validated! no user inputs are needed
    *                                        {*} 'N' not validated! user needs to validare this action
    *
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Sofia Mendes
    * @since                                 23-Mar-2012
    ********************************************************************************************/
    FUNCTION set_action
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_action     IN action.id_action%TYPE,
        i_id_task_type  IN tl_task.id_tl_task%TYPE,
        i_id_task       IN epis_pn_det_task.id_task%TYPE,
        o_flg_validated OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PK_PROG_NOTES_CORE.GET_WORK_SUGGEST_RECORDS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_in.set_action(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_id_episode    => i_id_episode,
                                           i_id_action     => i_id_action,
                                           i_id_task_type  => i_id_task_type,
                                           i_id_task       => i_id_task,
                                           o_flg_validated => o_flg_validated,
                                           o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_ACTION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
    END set_action;

    /********************************************************************************************
    * Gets the flash service name for the multichoice in the comments functionality
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_TL_TASK            Task Type Identifier
    *
    * @param         O_DATA                  Multichoice options list
    * @param         O_ERROR                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                António Neto
    * @since                                 30-Apr-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION get_comment_multichoice
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_tl_task IN tl_task.id_tl_task%TYPE,
        o_data       OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PK_PROG_NOTES_IN.GET_COMMENT_MULTICHOICE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_in.get_comment_multichoice(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_tl_task => i_id_tl_task,
                                                        o_data       => o_data,
                                                        o_error      => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMMENT_MULTICHOICE',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
        
            RETURN FALSE;
    END get_comment_multichoice;

    /**
    * Sets the note history in case the note was automatically saved in the last time.
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note 
    * @param   i_epis_pn      Progress note identifier
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.6.2
    * @since   26-Jul-2012
    */
    FUNCTION set_note_history
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_area    IN VARCHAR2,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_prog_notes_core.set_note_history. i_epis_pn: ' || i_epis_pn;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_core.set_note_history(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_epis_pn => i_epis_pn,
                                                   o_error   => o_error)
        THEN
            RAISE g_exception;
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
                                              i_package  => g_package,
                                              i_function => 'SET_NOTE_HISTORY',
                                              o_error    => o_error);
        
            ROLLBACK;
            RETURN FALSE;
    END set_note_history;

    /********************************************************************************************
    * Gets the flash context screens
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         i_flg_context            flag context
    *
    * @param         O_DATA                  screen list
    * @param         O_ERROR                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                Paulo teixeira
    * @since                                 06-03-2014
    * @version                               2.6.3
    ********************************************************************************************/
    FUNCTION get_swf_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN pn_context.flg_context%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PK_PROG_NOTES_in.get_swf_context';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_in.get_swf_context(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_flg_context => i_flg_context,
                                                o_data        => o_data,
                                                o_error       => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_swf_context',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
        
            RETURN FALSE;
    END get_swf_context;

    /********************************************************************************************
    * Cancel a task type record
    *
    * @param         i_lang                  Language ID for translations
    * @param         i_prof                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         i_id_task_type          Task Type ID
    * @param         i_id_task_refid         Record ID
    * @param         i_id_cancel_reason      Cancel Reason ID
    * @param         i_notes_cancel          Cancel notes
    *
    * @param         o_error                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                Vanessa Barsottelli
    * @since                                 07-07-2014
    * @version                               2.6.4
    ********************************************************************************************/
    FUNCTION cancel_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_task_type     IN tl_task.id_tl_task%TYPE,
        i_id_task_refid    IN task_timeline_ea.id_task_refid%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN cancel_info_det.notes_cancel_long%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PK_PROG_NOTES_IN.CANCEL_TASK';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_in.cancel_task(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            i_id_task_type     => i_id_task_type,
                                            i_id_task_refid    => i_id_task_refid,
                                            i_id_cancel_reason => i_id_cancel_reason,
                                            i_notes_cancel     => i_notes_cancel,
                                            o_error            => o_error)
        THEN
            RAISE g_exception;
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
                                              i_package  => g_package,
                                              i_function => 'CANCEL_TASK',
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
    END cancel_task;

    /********************************************************************************************
    * Get current timetamp when there is a jump out of single page
    *
    * @param         i_lang                  Language ID for translations
    * @param         i_prof                  Professional vector of information (professional ID, institution ID, software ID)
    *
    * @param         o_dt_jump               jump date
    * @param         o_error                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                Vanessa Barsottelli
    * @since                                 15-07-2014
    * @version                               2.6.4
    ********************************************************************************************/
    FUNCTION get_jump_datetime
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_dt_jump OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error   := 'CALL PK_DATE_UTILS.DATE_SEND_TSZ';
        o_dt_jump := pk_date_utils.to_char_insttimezone(i_prof      => i_prof,
                                                        i_timestamp => current_timestamp,
                                                        i_mask      => pk_date_utils.g_dateformat_msec);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_JUMP_DATETIME',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_jump_datetime;

    /********************************************************************************************
    * Get all reason for visit by episode
    *
    * @param         i_lang                  Language ID for translations
    * @param         i_prof                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         i_episode               Episode ID
    *
    * @param         o_rea_visit             All reason for visit
    * @param         o_error                 error information
    *
    * @return                                false if errors occur, true otherwise
    *
    * @author                                Vanessa Barsottelli
    * @since                                 25-07-2014
    * @version                               2.6.4
    ********************************************************************************************/
    FUNCTION get_reason_for_visit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_rea_visit OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL PK_PROGRESS_NOTES.GET_REASON_FOR_VISIT';
        IF NOT pk_progress_notes.get_reason_for_visit(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_episode        => i_episode,
                                                      i_show_block     => pk_alert_constant.get_yes,
                                                      i_show_cancelled => pk_alert_constant.g_no,
                                                      o_rea_visit      => o_rea_visit,
                                                      o_error          => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CANCEL_TASK',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_reason_for_visit;

    /**
    * Returns the last note to the summary grid.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_patient             patient identifier             
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note
    * @param o_addendums              Addendums data
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Paulo Teixeira
    * @version               2.6.4.2
    * @since                2014/07/31
    */
    FUNCTION get_last_prog_notes_res
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        o_data            OUT pk_types.cursor_type,
        o_notes_texts     OUT pk_types.cursor_type,
        o_addendums       OUT pk_types.cursor_type,
        o_id_sys_shortcut OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LAST_PROG_NOTES_RES';
        l_note_info      pk_types.cursor_type;
        l_dummy_vc       VARCHAR2(4000 CHAR);
        l_dummy_dt       viewer_ehr_ea.dt_note%TYPE;
        l_dummy_num      NUMBER;
        l_id_epis_pn     epis_pn.id_epis_pn%TYPE;
        l_area           pn_area.internal_name%TYPE;
        l_comments_dummy pk_types.cursor_type;
    BEGIN
    
        g_error := 'pk_prog_notes_utils.get_viewer_notes with i_id_patient:' || i_id_patient;
        IF NOT pk_prog_notes_utils.get_viewer_notes(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_id_pn_area  => NULL,
                                                    i_scope       => i_id_patient,
                                                    i_scope_type  => 'P',
                                                    i_flg_scope   => pk_prog_notes_constants.g_flg_scope_summary_s,
                                                    i_interval    => NULL,
                                                    o_data        => l_note_info,
                                                    o_title       => l_dummy_vc,
                                                    o_screen_name => l_dummy_vc,
                                                    o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Fetch VS info';
        FETCH l_note_info
            INTO l_dummy_vc,
                 l_dummy_vc,
                 l_dummy_num,
                 l_dummy_vc,
                 l_dummy_vc,
                 l_dummy_vc,
                 l_dummy_dt,
                 l_id_epis_pn,
                 l_dummy_num;
        CLOSE l_note_info;
    
        BEGIN
            g_error := 'get l_area';
            SELECT pa.internal_name, pa.id_sys_shortcut
              INTO l_area, o_id_sys_shortcut
              FROM epis_pn ep
              JOIN pn_area pa
                ON pa.id_pn_area = ep.id_pn_area
             WHERE ep.id_epis_pn = l_id_epis_pn;
        EXCEPTION
            WHEN no_data_found THEN
                l_area            := NULL;
                o_id_sys_shortcut := NULL;
        END;
    
        IF l_area IS NOT NULL
        THEN
            g_error := 'CALL pk_prog_notes_core.get_last_prog_notes_res with i_area:' || l_area || ' i_id_episode:' ||
                       i_id_episode || ' i_id_patient:' || i_id_patient;
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            pk_alertlog.log_debug(g_error);
            IF NOT pk_prog_notes_grids.get_epis_prog_notes(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_id_episode   => i_id_episode,
                                                           i_id_patient   => i_id_patient,
                                                           i_flg_scope    => pk_prog_notes_constants.g_flg_scope_p,
                                                           i_area         => l_area,
                                                           i_start_record => 0,
                                                           i_num_records  => 1,
                                                           i_search       => NULL,
                                                           i_filter       => NULL,
                                                           o_data         => o_data,
                                                           o_notes_texts  => o_notes_texts,
                                                           o_addendums    => o_addendums,
                                                           o_comments     => l_comments_dummy,
                                                           o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_types.open_my_cursor(i_cursor => o_addendums);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_last_prog_notes_res',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            RETURN FALSE;
        
    END get_last_prog_notes_res;
    FUNCTION get_notes_dashboard
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        o_title           OUT pk_types.cursor_type,
        o_note            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_data               pk_types.cursor_type;
        l_text_blocks        pk_types.cursor_type;
        l_text_comments      pk_types.cursor_type;
        l_suggested          pk_types.cursor_type;
        l_configs            pk_types.cursor_type;
        l_data_blocks        pk_types.cursor_type;
        l_buttons            pk_types.cursor_type;
        l_cancelled          pk_types.cursor_type;
        l_doc_reg            pk_types.cursor_type;
        l_doc_val            pk_types.cursor_type;
        l_template_layouts   pk_types.cursor_type;
        l_doc_area_component pk_types.cursor_type;
    
    BEGIN
    
        g_error := 'CALL pk_prog_notes_grids.get_notes_dashboard i_id_episode: ' || i_id_episode ||
                   ' i_id_pn_note_type:' || i_id_pn_note_type;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_notes_dashboard(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_episode      => i_id_episode,
                                                       i_id_pn_note_type => i_id_pn_note_type,
                                                       o_title           => o_title,
                                                       o_note            => o_note,
                                                       o_error           => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NOTES_DASHBOARD',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_notes_dashboard;

    /**
    * Returns the actions to be displayed in the 'ACTIONS' button from prof grids
    *
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_actions      actions data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Vanessa Barsottelli
    * @version              2.6.5
    * @since                26-04-2016
    */
    FUNCTION get_prof_grid_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_actions OUT NOCOPY pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_prog_notes_utils.get_prof_grid_actions';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_prof_grid_actions(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_episode => i_episode,
                                                         o_actions => o_actions,
                                                         o_error   => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PROF_GRID_ACTIONS',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_prof_grid_actions;

    /**
    * Returns the info (labels & sample text) to prof grid popup
    *
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_note_type    note type ID
    * @param o_info         labels for popup
    * @paramo_sample_text   sample text
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Vanessa Barsottelli
    * @version              2.6.5
    * @since                27-04-2016
    */
    FUNCTION get_note_grid_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_note_type   IN pn_note_type.id_pn_note_type%TYPE,
        o_info        OUT pk_types.cursor_type,
        o_data_blocks OUT pk_types.cursor_type,
        o_sample_text OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_prog_notes_utils.get_note_grid_info';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_note_grid_info(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_episode     => i_episode,
                                                      i_note_type   => i_note_type,
                                                      o_info        => o_info,
                                                      o_data_blocks => o_data_blocks,
                                                      o_sample_text => o_sample_text,
                                                      o_error       => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NOTE_GRID_INFO',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_note_grid_info;

    FUNCTION set_pn_free_text
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_pn_area    IN pn_area.internal_name%TYPE,
        i_dt_pn_date IN table_varchar,
        i_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_pn_note    IN table_clob,
        o_id_epis_pn OUT epis_pn.id_epis_pn%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_prog_notes_utils.get_note_grid_info';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_core.set_pn_free_text(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_episode    => i_episode,
                                                   i_dt_pn_date => i_dt_pn_date,
                                                   i_note_type  => i_note_type,
                                                   i_pn_note    => i_pn_note,
                                                   o_id_epis_pn => o_id_epis_pn,
                                                   o_error      => o_error)
        THEN
            RAISE g_exception;
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
                                              i_package  => g_package,
                                              i_function => 'SET_PN_FREE_TEXT',
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
    END set_pn_free_text;

    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        i_viewer_area  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_prog_notes_grids.get_ordered_list';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_ordered_list(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient      => i_patient,
                                                    i_translate    => i_translate,
                                                    i_viewer_area  => i_viewer_area,
                                                    i_episode      => i_episode,
                                                    o_ordered_list => o_ordered_list,
                                                    o_error        => o_error)
        THEN
            RAISE g_exception;
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
                                              i_package  => g_package,
                                              i_function => 'GET_ORDERED_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_ordered_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ordered_list;
    --
    FUNCTION get_ordered_list_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'pk_prog_notes_grids.GET_ORDERED_LIST_DETAIL';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_ordered_list_detail(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_id_epis_pn => i_id_epis_pn,
                                                           o_detail     => o_detail,
                                                           o_error      => o_error)
        THEN
            RAISE g_exception;
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
                                              i_package  => g_package,
                                              i_function => 'GET_ORDERED_LIST_DETAIL',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ordered_list_detail;

    FUNCTION get_doc_status_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DOC_STATUS_LIST';
    BEGIN
        g_error := 'CALL PK_PROG_NOTES_UTILS.GET_DOC_STATUS_LIST';
        IF NOT pk_prog_notes_utils.get_doc_status_list(i_lang  => i_lang,
                                                       i_prof  => i_prof,
                                                       o_list  => o_list,
                                                       o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_doc_status_list;

    FUNCTION get_summ_sections_block
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_sblock    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_doc_area     IN doc_area.id_doc_area%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SUMM_SECTIONS_BLOCK';
    BEGIN
        IF NOT pk_prog_notes_in.get_summ_sections_block(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_summary_page => i_id_summary_page,
                                                        i_patient         => i_patient,
                                                        i_id_episode      => i_id_episode,
                                                        i_id_pn_sblock    => i_id_pn_sblock,
                                                        i_id_pn_note_type => i_id_pn_note_type,
                                                        i_id_doc_area=>i_id_doc_area,
                                                        o_sections        => o_sections,
                                                        o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_sections);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sections);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**
    * Returns a selection list  with the attending physicians names that took patient
    * responsability along the episode.
    *
    * @param i_lang         language identifier
    * @param i_prof         profissional
    * @param i_id_episode   id of current episode
    * @param o_sql          cursor returning list of attending professionals
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Carlos Ferreira
    * @version              2.7.2
    * @since                2017/11/15
    */
    FUNCTION get_epis_att_profs
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN NUMBER,
        o_sql        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_progress_notes.get_epis_att_profs(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_id_episode => i_id_episode,
                                                       o_sql        => o_sql,
                                                       o_error      => o_error);
    
        end_transaction(i_bool => l_bool);
    
        RETURN l_bool;
    
    END get_epis_att_profs;

    /**
    * submit for review of progress note
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_pn                   Progress note identifier
    *
    * @param   o_error                     Error information
    *
    * @return                              Returns TRUE if success, otherwise returns FALSE
    *
    *
    * @author                              Carlos ferreira
    * @version                             2.7.2
    * @since                               2017-11-17
    */
    FUNCTION set_submit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_prog_notes_core.set_submit(i_lang    => i_lang,
                                                i_prof    => i_prof,
                                                i_epis_pn => i_epis_pn,
                                                o_error   => o_error);
    
        end_transaction(i_bool => l_bool);
    
        RETURN l_bool;
    
    END set_submit;

    /****************************************************************************
    ****************************************************************************/
    FUNCTION set_submit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_submit_reason IN epis_pn.id_submit_reason%TYPE,
        i_notes_submit     IN epis_pn.notes_submit%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_prog_notes_core.set_submit(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_epis_pn          => i_epis_pn,
                                                i_id_submit_reason => i_id_submit_reason,
                                                i_notes_submit     => i_notes_submit,
                                                o_error            => o_error);
    
        end_transaction(i_bool => l_bool);
    
        RETURN l_bool;
    
    END set_submit;

    /**
    * function to save a "for review" progress note
    *
    */
    FUNCTION set_for_review
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_review IN NUMBER,
        i_epis_pn     IN epis_pn.id_epis_pn%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_prog_notes_core.set_for_review(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_prof_review => i_prof_review,
                                                    i_epis_pn     => i_epis_pn,
                                                    o_error       => o_error);
    
        end_transaction(i_bool => l_bool);
    
        RETURN l_bool;
    
    END set_for_review;

    /******************************************************************************
    ******************************************************************************/
    FUNCTION get_iss_diag_validation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_pn   IN epis_pn.id_epis_pn%TYPE,
        i_check_origin IN VARCHAR2 DEFAULT 'N', -- N: Submit in note; A: Submit in action
        o_return_flag  OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL pk_prog_notes_out.check_iss_diag_validation';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_out.check_iss_diag_validation(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_id_epis_pn   => i_id_epis_pn,
                                                           i_check_origin => i_check_origin,
                                                           o_return_flag  => o_return_flag,
                                                           o_error        => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_ISS_DIAG_VALIDATION',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_iss_diag_validation;

    /******************************************************************************
    ******************************************************************************/
    FUNCTION get_iss_diag_val_params
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_return_flag     IN VARCHAR2,
        o_msg_box_desc    OUT VARCHAR2,
        o_msg_box_options OUT pk_types.cursor_type,
        o_include_reasons OUT VARCHAR2, -- Y/N
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL pk_prog_notes_out.get_iss_diag_val_params';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_out.get_iss_diag_val_params(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_return_flag     => i_return_flag,
                                                         o_msg_box_desc    => o_msg_box_desc,
                                                         o_msg_box_options => o_msg_box_options,
                                                         o_include_reasons => o_include_reasons,
                                                         o_error           => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ISS_DIAG_VAL_PARAMS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_iss_diag_val_params;

    /***************************************************************************************************************
    * Set the comments for some note
    *
    * @param  i_lang                  IN   language.id_language%TYPE                   Language id
    * @param  i_prof                  IN   profissional                                Professional structure
    * @param  i_id_epis_pn            IN   epis_pn.id_epis_pn%TYPE                     Note id
    * @param  i_id_epis_pn_addendum   IN   epis_pn_addendum.id_epis_pn_addendum%TYPE   Comment id
    * @param  i_pn_addendum           IN   epis_pn_addendum.pn_addendum%TYPE           Comment text
    * @param  o_epis_pn_addendum      OUT  epis_pn_addendum.id_epis_pn_addendum%TYPE   Comment id
    * @param  o_error                 OUT  t_error_out
    *
    * @return   BOOLEAN   TRUE if succeeds, FALSE otherwise
    *
    * @author   rui.mendonca
    * @version  2.7.2.2
    * @since    14/12/2017
    ***************************************************************************************************************/
    FUNCTION set_pn_comments
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        i_pn_addendum         IN epis_pn_addendum.pn_addendum%TYPE,
        o_epis_pn_addendum    OUT epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT user_objects.object_name%TYPE := 'SET_PN_COMMENTS';
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.set_pn_addendum with flg_type "C" (Comments)';
        pk_alertlog.log_info(g_error);
    
        IF NOT pk_prog_notes_core.set_pn_addendum(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_epis_pn          => i_id_epis_pn,
                                                  i_flg_type            => pk_prog_notes_constants.g_epa_flg_type_comment,
                                                  i_id_epis_pn_addendum => i_id_epis_pn_addendum,
                                                  i_pn_addendum         => i_pn_addendum,
                                                  o_epis_pn_addendum    => o_epis_pn_addendum,
                                                  o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        
    END set_pn_comments;

    /*****************************************************************************
    * Get the comments for some note
    * 
    * @param  i_lang        IN   language.id_language%TYPE  Language id
    * @param  i_prof        IN   profissional               Professional structure
    * @param  i_id_epis_pn  IN   epis_pn.id_epis_pn%TYPE    Note id
    * @param  o_pn_comments OUT  pk_types.cursor_type
    * @param  o_error       OUT  t_error_out
    *
    * @return   BOOLEAN   TRUE if succeeds, FALSE otherwise
    *
    * @author   rui.mendonca
    * @version  2.7.2.2
    * @since    14/12/2017
    *****************************************************************************/
    FUNCTION get_pn_comments
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE,
        o_pn_comments OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT user_objects.object_name%TYPE := 'GET_PN_COMMENTS';
    BEGIN
        g_error := 'CALL pk_prog_notes_core.get_pn_comments for id_epis_pn: ' || i_id_epis_pn;
        pk_alertlog.log_info(g_error);
    
        IF NOT pk_prog_notes_core.get_pn_comments(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_id_epis_pn  => i_id_epis_pn,
                                                  o_pn_comments => o_pn_comments,
                                                  o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN g_exception THEN
            pk_types.open_cursor_if_closed(i_cursor => o_pn_comments);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(i_cursor => o_pn_comments);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_pn_comments;

    /******************************************************************************
    ******************************************************************************/
    FUNCTION get_note_review_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_ids_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_current_details  OUT CLOB,
        o_previous_details OUT CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL pk_prog_notes_grids.get_note_review_info';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_grids.get_note_review_info(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_ids_epis_pn      => i_ids_epis_pn,
                                                        o_current_details  => o_current_details,
                                                        o_previous_details => o_previous_details,
                                                        o_error            => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NOTE_REVIEW_INFO',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_note_review_info;

    /**************************************************************************
    * get all note list
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_area                   pn_area
    * @param i_id_episode             Episode ID
    * @param i_begin_date             Get note list begin date
    * @param i_end_date               Get note list end date
    *
    * @param o_note_lists             cursor with all note in current week
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_all_note_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_area       IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE, --CALERT-1265
        i_begin_date IN VARCHAR2, --CALERT-1265
        i_end_date   IN VARCHAR2, --CALERT-1265
        o_note_lists OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(50 CHAR) := 'GET_ALL_NOTE_LIST';
        l_begin_date TIMESTAMP WITH LOCAL TIME ZONE; --CALERT-1265
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE; --CALERT-1265
    BEGIN
        l_begin_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_timestamp => i_begin_date,
                                                      i_timezone  => NULL);
    
        l_end_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_timestamp => i_end_date,
                                                    i_timezone  => NULL);
    
        l_end_date := l_end_date + numtodsinterval(1, 'DAY') - numtodsinterval(1, 'SECOND');
        IF NOT pk_prog_notes_core.get_all_note_list(i_lang               => i_lang,
                                                    i_prof               => i_prof,
                                                    i_pn_area_inter_name => i_area,
                                                    i_id_episode         => i_id_episode, --CALERT-1265
                                                    i_begin_date         => l_begin_date, --CALERT-1265
                                                    i_end_date           => l_end_date, --CALERT-1265
                                                    o_note_lists         => o_note_lists,
                                                    o_error              => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_all_note_list;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_calendar_date_control  UX calendar previous or next
    * @param i_current_date           UX calendar date
    *
    * @param o_calendar_period        calendar period
    * @param o_begin_date             calendar begin date
    * @param o_end_date               calendar end date
    * @param o_current_date_num       calendar current date num
    * @param o_calendar_dates         cursor with all date in current week
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24
    **************************************************************************/
    FUNCTION get_days_in_current_week
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_calendar_date_control IN VARCHAR2 DEFAULT NULL,
        i_current_date          IN VARCHAR2 DEFAULT NULL,
        o_calendar_period       OUT VARCHAR2,
        o_begin_date            OUT VARCHAR2,
        o_end_date              OUT VARCHAR2,
        o_current_date_num      OUT NUMBER,
        o_calendar_dates        OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(50 CHAR) := 'GET_DAYS_IN_CURRENT_WEEK';
        l_current_date TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        IF i_current_date IS NOT NULL
        THEN
            l_current_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_timestamp => i_current_date,
                                                            i_timezone  => NULL);
        
        ELSE
            l_current_date := NULL;
        END IF;
        pk_alertlog.log_info(text            => 'l_current_date: ' || l_current_date || ' i_current_date:' ||
                                                i_current_date,
                             object_name     => g_package,
                             sub_object_name => l_func_name);
        IF NOT pk_prog_notes_utils.get_days_in_current_week(i_lang                  => i_lang,
                                                            i_prof                  => i_prof,
                                                            i_calendar_date_control => i_calendar_date_control,
                                                            i_current_date          => l_current_date,
                                                            o_calendar_period       => o_calendar_period,
                                                            o_begin_date            => o_begin_date,
                                                            o_end_date              => o_end_date,
                                                            o_current_date_num      => o_current_date_num,
                                                            o_calendar_dates        => o_calendar_dates,
                                                            o_error                 => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_calendar_dates);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_days_in_current_week;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_area                   pn_area
    * @param i_id_episode             Episode ID
    * @param i_begin_date             Get note list begin date
    * @param i_end_date               Get note list end date
    *
    * @param o_notes                  All note summary
    * @param o_notes_det              All note detail
    * @param o_area_configs           For cancle reason
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24
    **************************************************************************/
    FUNCTION get_calendar_view_note
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_area         IN VARCHAR2,
        i_id_episode   IN episode.id_episode%TYPE,
        i_begin_date   IN VARCHAR2,
        i_end_date     IN VARCHAR2,
        o_notes        OUT pk_types.cursor_type,
        o_notes_det    OUT pk_types.cursor_type,
        o_area_configs OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(50 CHAR) := 'GET_CALENDAR_VIEW_NOTE';
        l_begin_date TIMESTAMP WITH LOCAL TIME ZONE; --CALERT-1265
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE; --CALERT-1265
    BEGIN
        l_begin_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_timestamp => i_begin_date,
                                                      i_timezone  => NULL);
    
        l_end_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_timestamp => i_end_date,
                                                    i_timezone  => NULL);
    
        l_end_date := l_end_date + numtodsinterval(1, 'DAY') + numtodsinterval(-1, 'SECOND');
    
        IF NOT pk_prog_notes_core.get_calendar_view_note(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_area       => i_area,
                                                         i_id_episode => i_id_episode,
                                                         i_begin_date => l_begin_date,
                                                         i_end_date   => l_end_date,
                                                         o_notes      => o_notes,
                                                         o_notes_det  => o_notes_det,
                                                         o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_prog_notes_utils.get_area_name';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_area_configs(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_area         => i_area,
                                                    i_id_episode   => i_id_episode,
                                                    o_area_configs => o_area_configs,
                                                    o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_notes);
            pk_types.open_my_cursor(i_cursor => o_notes_det);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_calendar_view_note;

    /**
    * Returns the notes to the summary grid.
    * Base on original get_work_notes_core and create one input parameter
    * for calendar view
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_epis_pn_work        Note identifier
    * @param i_id_pn_note_type        Note type id. 3-Progress Note; 4-Prolonged Progress Note; 5-Intensive Care Note; 2-History and Physician Note
    * @param i_flg_definitive         Save PN in the definitive model (Y- YES, N- NO)
    * @param i_id_epis_pn_det_task    Task Ids that have to be syncronized
    * @param i_id_pn_soap_block       Soap block id
    * @param o_data                   notes data
    * @param o_text_blocks            Texts that compose the note
    * @param o_text_comments          Comments cursor
    * @param o_suggested              Texts that compose the note with the suggested records
    * @param o_configs                Dynamic configs: flg_import_available; flg_editable
    * @param o_data_blocks            Dynamic data blocks (date data blocks)
    * @param o_buttons                Dynamic buttons (template records)
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author  Amanda Lee
    * @version 2.7.2
    * @since   12-18-2017
    */
    FUNCTION get_work_notes_core
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_pn_work     IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_note_type     IN epis_pn.id_pn_note_type%TYPE,
        i_flg_definitive      IN VARCHAR2,
        i_id_epis_pn_det_task IN table_number,
        i_id_pn_soap_block    IN table_number,
        i_dt_proposed         IN VARCHAR2,
        o_data                OUT pk_types.cursor_type,
        o_text_blocks         OUT pk_types.cursor_type,
        o_text_comments       OUT pk_types.cursor_type,
        o_suggested           OUT pk_types.cursor_type,
        o_configs             OUT NOCOPY pk_types.cursor_type,
        o_data_blocks         OUT NOCOPY pk_types.cursor_type,
        o_buttons             OUT NOCOPY pk_types.cursor_type,
        o_cancelled           OUT NOCOPY pk_types.cursor_type,
        o_doc_reg             OUT NOCOPY pk_types.cursor_type,
        o_doc_val             OUT NOCOPY pk_types.cursor_type,
        o_template_layouts    OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component  OUT NOCOPY pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_proposed TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        g_error := 'CALL pk_prog_notes_core.get_work_notes_core';
        pk_alertlog.log_debug(g_error);
        IF i_dt_proposed IS NOT NULL
        THEN
            l_dt_proposed := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_timestamp => i_dt_proposed,
                                                           i_timezone  => NULL);
        ELSE
            l_dt_proposed := NULL;
        END IF;
        pk_alertlog.log_info(text            => '[get_work_notes_core]l_dt_proposed: ' || l_dt_proposed ||
                                                ' i_dt_proposed:' || i_dt_proposed,
                             object_name     => g_package,
                             sub_object_name => 'GET_WORK_NOTES_CORE');
    
        IF NOT pk_prog_notes_core.get_notes_core(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_episode          => i_id_episode,
                                                 i_id_epis_pn          => i_id_epis_pn_work,
                                                 i_id_pn_note_type     => i_id_pn_note_type,
                                                 i_id_epis_pn_det_task => i_id_epis_pn_det_task,
                                                 i_id_pn_soap_block    => i_id_pn_soap_block,
                                                 i_dt_proposed         => l_dt_proposed,
                                                 o_data                => o_data,
                                                 o_text_blocks         => o_text_blocks,
                                                 o_text_comments       => o_text_comments,
                                                 o_suggested           => o_suggested,
                                                 o_configs             => o_configs,
                                                 o_data_blocks         => o_data_blocks,
                                                 o_buttons             => o_buttons,
                                                 o_cancelled           => o_cancelled,
                                                 o_doc_reg             => o_doc_reg,
                                                 o_doc_val             => o_doc_val,
                                                 o_template_layouts    => o_template_layouts,
                                                 o_doc_area_component  => o_doc_area_component,
                                                 o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
        
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_text_blocks);
            pk_types.open_my_cursor(i_cursor => o_text_comments);
            pk_types.open_my_cursor(i_cursor => o_suggested);
            pk_types.open_my_cursor(i_cursor => o_doc_reg);
            pk_types.open_my_cursor(i_cursor => o_doc_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_WORK_NOTES_CORE',
                                              o_error    => o_error);
            ROLLBACK;
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_text_blocks);
            pk_types.open_my_cursor(i_cursor => o_text_comments);
            pk_types.open_my_cursor(i_cursor => o_suggested);
            pk_types.open_my_cursor(i_cursor => o_doc_reg);
            pk_types.open_my_cursor(i_cursor => o_doc_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_work_notes_core;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_area                   pn_area internal name
    *
    * @param o_def_viewer_parameter   cursor with the information for timeline
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-27
    **************************************************************************/
    FUNCTION get_calendar_def_viewer
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_area                 IN VARCHAR2,
        o_def_viewer_parameter OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(50 CHAR) := 'GET_CALENDAR_DEF_VIEWER';
    BEGIN
    
        IF NOT pk_prog_notes_utils.get_calendar_def_viewer(i_lang                 => i_lang,
                                                           i_prof                 => i_prof,
                                                           i_area                 => i_area,
                                                           o_def_viewer_parameter => o_def_viewer_parameter,
                                                           o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_def_viewer_parameter);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_calendar_def_viewer;

    /**
    * Update all data block's content for a PN. If the data doesn't exists yet, the record will be created.
    * the IN parameter Type allow for select if append or update should be done to the text.
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_episode              Episode ID
    * @param   i_epis_pn              Progress note ID
    * @param   i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note
    * @param   i_flg_action           C-Create; U-update
    * @param   i_dt_pn_date           Progress Note date Array
    * @param   i_date_type            DH- Date hour; D-Date
    * @param   i_pn_soap_block        SOAP Block ID
    * @param   i_pn_data_block        Data Block ID
    * @param   i_id_task              Array of task IDs
    * @param   i_id_task_type         Array of task type IDs
    * @param   i_dep_clin_serv        Clinical Service ID
    * @param   i_epis_pn_det          Progress note detail ID
    * @param   i_pn_note              Progress note detail text
    * @param   i_flg_add_remove       Add or remove block from note. A R-Removed block is like a canceled one.
    * @param   i_id_pn_note_type      Progress Note type (P-progress note; L-prolonged progress note; CC-intensive care note; H-history and physician note)
    * @param   i_flg_app_upd          Type of operation: A-Append, U-Update
    * @param   i_flg_definitive       Save PN in the definitive model (Y- YES, N- NO)
    * @param   i_epis_pn_det_task     Array of PN task details
    * @param   i_pn_note_task         Array of PN task descriptions
    * @param   i_flg_add_rem_task     Array of task status (A- Active, R- Removed)
    * @param   i_flg_table_origin     Flag origin table for documentation ( D - documentation, A - Anamnesis, S - Review of system)
    * @param   i_id_task_aggregator   For analysis and exam recurrences, an imported registry will only be uniquely
    *                                 Identified by id_task (id_analysis/id_exam) + i_id_task_aggregator
    * @param   i_dt_task              Task dates
    * @param   i_id_task_parent       Parent task identifier for comments functionality
    * @param   i_flg_task_parent      Flag tells where i_id_task_parent is a taskid or id_epis_pn_det_task
    * @param   i_id_multichoice       Array of tasks identifiers for cases that have more than one parameter (multichoice on exam results)
    *
    * @param   o_id_epis_pn           ID of the PN created
    * @param   o_flg_reload           Tells UX layer it It's needed the reload screen or not
    * @param   o_error                Error information
    *
    * @return  Boolean                True: Sucess, False: Fail
    *
    * @value   o_flg_reload           {*} 'Y'- Yes {*} 'N'- No
    * @value   i_flg_task_parent      {*} 'Y'- Passed in i_id_task_parent the id_epis_pn_det_task {*} 'N'- Passed in i_id_task_parent the taskid
    *
    * @author                         RUI.BATISTA
    * @version                        <2.6.0.5>
    * @since                          04-02-2011
    */
    FUNCTION set_all_data_block_work
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_pn            IN epis_pn.id_epis_pn%TYPE,
        i_area               IN VARCHAR2,
        i_flg_action         IN VARCHAR2,
        i_flg_definitive     IN VARCHAR2,
        i_dt_pn_date         IN table_varchar,
        i_date_type          IN table_varchar,
        i_pn_soap_block      IN table_number,
        i_pn_data_block      IN table_number,
        i_id_task            IN table_table_number,
        i_id_task_type       IN table_table_number,
        i_dep_clin_serv      IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_epis_pn_det        IN table_number,
        i_pn_note            IN table_clob,
        i_flg_add_remove     IN table_varchar,
        i_id_pn_note_type    IN epis_pn.id_pn_note_type%TYPE,
        i_flg_app_upd        IN VARCHAR2,
        i_epis_pn_det_task   IN table_table_number,
        i_pn_note_task       IN table_table_clob,
        i_flg_add_rem_task   IN table_table_varchar,
        i_flg_table_origin   IN table_table_varchar DEFAULT NULL,
        i_id_task_aggregator IN table_table_number,
        i_dt_task            IN table_table_varchar,
        i_id_task_parent     IN table_table_number,
        i_flg_task_parent    IN VARCHAR2,
        i_id_multichoice     IN table_table_number,
        i_id_group_table     IN table_table_number,
        i_dt_proposed        IN VARCHAR2 DEFAULT NULL, --CALERT-1265
        o_id_epis_pn         OUT epis_pn.id_epis_pn%TYPE,
        o_flg_reload         OUT VARCHAR2,
        o_dt_finished        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_proposed TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        g_error := 'CALL pk_prog_notes_core.set_all_data_block_work';
        pk_alertlog.log_debug(g_error);
        IF i_dt_proposed IS NOT NULL
        THEN
            l_dt_proposed := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_timestamp => i_dt_proposed,
                                                           i_timezone  => NULL);
        ELSE
            l_dt_proposed := NULL;
        END IF;
        pk_alertlog.log_info(text            => '[set_all_data_block_work]l_dt_proposed: ' || l_dt_proposed ||
                                                ' i_dt_proposed:' || i_dt_proposed,
                             object_name     => g_package,
                             sub_object_name => 'GET_WORK_NOTES_CORE');
        IF NOT pk_prog_notes_core.set_all_data_block(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_episode            => i_episode,
                                                     i_epis_pn            => i_epis_pn,
                                                     i_dt_pn_date         => i_dt_pn_date,
                                                     i_flg_action         => i_flg_action,
                                                     i_date_type          => i_date_type,
                                                     i_pn_soap_block      => i_pn_soap_block,
                                                     i_pn_data_block      => i_pn_data_block,
                                                     i_id_task            => i_id_task,
                                                     i_id_task_type       => i_id_task_type,
                                                     i_dep_clin_serv      => i_dep_clin_serv,
                                                     i_epis_pn_det        => i_epis_pn_det,
                                                     i_pn_note            => i_pn_note,
                                                     i_flg_add_remove     => i_flg_add_remove,
                                                     i_id_pn_note_type    => i_id_pn_note_type,
                                                     i_flg_app_upd        => i_flg_app_upd,
                                                     i_flg_definitive     => i_flg_definitive,
                                                     i_epis_pn_det_task   => i_epis_pn_det_task,
                                                     i_pn_note_task       => i_pn_note_task,
                                                     i_flg_add_rem_task   => i_flg_add_rem_task,
                                                     i_flg_table_origin   => i_flg_table_origin,
                                                     i_id_task_aggregator => i_id_task_aggregator,
                                                     i_dt_task            => i_dt_task,
                                                     i_id_task_parent     => i_id_task_parent,
                                                     i_flg_task_parent    => i_flg_task_parent,
                                                     i_id_multichoice     => i_id_multichoice,
                                                     i_id_group_table     => i_id_group_table,
                                                     i_dt_proposed        => l_dt_proposed, --CALERT-1265
                                                     o_id_epis_pn         => o_id_epis_pn,
                                                     o_flg_reload         => o_flg_reload,
                                                     o_error              => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        g_error := 'CALL GET_JUMP_DATETIME';
        pk_alertlog.log_debug(g_error);
        IF NOT get_jump_datetime(i_lang => i_lang, i_prof => i_prof, o_dt_jump => o_dt_finished, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_ALL_DATA_BLOCK_WORK',
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
    END set_all_data_block_work;

    FUNCTION get_severity_score_block
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_sblock    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_scores          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SEVERITY_SCORE_BLOCK';
    BEGIN
    
        IF NOT pk_prog_notes_in.get_severity_score_block(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_patient         => i_patient,
                                                         i_id_episode      => i_id_episode,
                                                         i_id_pn_sblock    => i_id_pn_sblock,
                                                         i_id_pn_note_type => i_id_pn_note_type,
                                                         o_flg_show        => o_flg_show,
                                                         o_msg_title       => o_msg_title,
                                                         o_msg             => o_msg,
                                                         o_button          => o_button,
                                                         o_scores          => o_scores,
                                                         o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_scores);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_scores);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_summ_sections_exclude
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_doc_category IN doc_category.id_doc_category%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_summ_sections_exclude';
    BEGIN
        IF NOT pk_prog_notes_in.get_summ_sections_exclude(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_summary_page => i_id_summary_page,
                                                          i_patient         => i_patient,
                                                          i_id_episode      => i_id_episode,
                                                          i_id_pn_note_type => i_id_pn_note_type,
                                                          i_id_doc_category => i_id_doc_category,
                                                          o_sections        => o_sections,
                                                          o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_sections);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sections);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_summ_sections_exclude;

    FUNCTION get_epis_prog_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_pn         IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area               IN VARCHAR2,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_scope          IN VARCHAR2,
        i_search             IN VARCHAR2,
        i_filter             IN VARCHAR2,
        i_start_record       IN NUMBER,
        i_num_records        IN NUMBER,
        i_request            IN NUMBER,
        o_data               OUT pk_types.cursor_type,
        o_notes_texts        OUT pk_types.cursor_type,
        o_addendums          OUT pk_types.cursor_type,
        o_comments           OUT pk_types.cursor_type,
        o_area_configs       OUT NOCOPY pk_types.cursor_type,
        o_doc_reg            OUT NOCOPY pk_types.cursor_type,
        o_doc_val            OUT NOCOPY pk_types.cursor_type,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type,
        o_flg_is_arabic_note OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode NUMBER;
    BEGIN
    
        IF i_request IS NOT NULL
        THEN
            l_id_episode := pk_hhc_core.get_id_epis_hhc_by_hhc_req(i_id_hhc_req => i_request);
        
        END IF;
        g_error := 'CALL pk_prog_notes_ux.get_epis_prog_notes l_id_episode:' || l_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_ux_progress_notes.get_epis_prog_notes(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_id_episode         => nvl(l_id_episode, i_id_episode),
                                                        i_id_epis_pn         => i_id_epis_pn,
                                                        i_area               => i_area,
                                                        i_id_patient         => i_id_patient,
                                                        i_flg_scope          => i_flg_scope,
                                                        i_search             => i_search,
                                                        i_filter             => i_filter,
                                                        i_start_record       => i_start_record,
                                                        i_num_records        => i_num_records,
                                                        o_data               => o_data,
                                                        o_notes_texts        => o_notes_texts,
                                                        o_addendums          => o_addendums,
                                                        o_comments           => o_comments,
                                                        o_area_configs       => o_area_configs,
                                                        o_doc_reg            => o_doc_reg,
                                                        o_doc_val            => o_doc_val,
                                                        o_template_layouts   => o_template_layouts,
                                                        o_doc_area_component => o_doc_area_component,
                                                        o_flg_is_arabic_note => o_flg_is_arabic_note,
                                                        o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            pk_types.open_my_cursor(i_cursor => o_doc_reg);
            pk_types.open_my_cursor(i_cursor => o_doc_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_PROG_NOTES',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_types.open_my_cursor(i_cursor => o_doc_reg);
            pk_types.open_my_cursor(i_cursor => o_doc_val);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
            RETURN FALSE;
        
    END get_epis_prog_notes;

    FUNCTION get_epis_prog_notes_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_area        IN pn_area.internal_name%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_flg_scope   IN VARCHAR2,
        i_search      IN VARCHAR2,
        i_filter      IN VARCHAR2,
        i_request     IN NUMBER,
        o_num_epis_pn OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode NUMBER := i_id_episode;
    BEGIN
        g_error := 'CALL pk_prog_notes_core.get_epis_pnotes_count 3 i_request' || i_request;
        pk_alertlog.log_debug(g_error);
        IF i_request IS NOT NULL
        THEN
            l_id_episode := pk_hhc_core.get_id_epis_hhc_by_hhc_req(i_id_hhc_req => i_request);
        
        END IF;
    
        IF NOT pk_ux_progress_notes.get_epis_prog_notes_count(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_id_episode  => l_id_episode,
                                                              i_id_patient  => i_id_patient,
                                                              i_id_epis_pn  => i_id_epis_pn,
                                                              i_flg_scope   => i_flg_scope,
                                                              i_area        => i_area,
                                                              i_search      => i_search,
                                                              i_filter      => i_filter,
                                                              o_num_epis_pn => o_num_epis_pn,
                                                              o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            o_num_epis_pn := 0;
            RETURN FALSE;
        WHEN OTHERS THEN
            o_num_epis_pn := 0;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_PROG_NOTES_COUNT',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_epis_prog_notes_count;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_ux_progress_notes;
/
