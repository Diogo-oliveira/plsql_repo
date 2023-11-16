/*-- Last Change Revision: $Rev: 1935663 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2020-02-10 11:46:30 +0000 (seg, 10 fev 2020) $*/
CREATE OR REPLACE PACKAGE BODY pk_hibernate_intf IS

    /********************************************************************************************
    * Encodes a string into base64 encoding.
    *
    * @param i_source        string to encode
    *
    * @return                string encoded in base64
    *
    * @author                Rui Baeta
    * @version               1.0
    * @since                 2009/03/25
    ********************************************************************************************/
    FUNCTION base64_encode(i_source IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(i_source)));
    END;

    /********************************************************************************************
    * Decodes a string into base64 encoding.
    *
    * @param i_source        string to decode
    *
    * @return                string decoded from base64
    *
    * @author                Rui Baeta
    * @version               1.0
    * @since                 2009/03/25
    ********************************************************************************************/
    FUNCTION base64_decode(i_source IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(i_source)));
    END;

    /********************************************************************************************
    * Encodes a t_error_out object into an unique string. Each object attribute is
    * appended into a string, using a newline as separator.
    *
    * @param i_source        string to decode
    *
    * @return                string decoded from base64
    *
    * @author                Rui Baeta
    * @version               1.0
    * @since                 2009/03/25
    ********************************************************************************************/
    FUNCTION t_error_encode(i_error IN t_error_out) RETURN VARCHAR2 IS
        l_error_table table_varchar;
        l_separator   VARCHAR2(1) := chr(10);
    BEGIN
        l_error_table := table_varchar(i_error.ora_sqlcode,
                                       i_error.ora_sqlerrm,
                                       i_error.err_desc,
                                       i_error.err_action,
                                       i_error.log_id,
                                       i_error.err_instance_id_out,
                                       i_error.msg_title,
                                       i_error.flg_msg_type);
    
        RETURN pk_utils.concat_table(i_tab => l_error_table, i_delim => l_separator);
    END;

    FUNCTION get_ordered_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof_id     IN professional.id_professional%TYPE,
        i_prof_inst   IN institution.id_institution%TYPE,
        i_prof_soft   IN software.id_software%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_package     IN VARCHAR2,
        i_viewer_area IN VARCHAR2
    ) RETURN pk_types.cursor_type IS
    
        l_ordered_list pk_types.cursor_type;
    
        l_ret BOOLEAN := FALSE;
    
        l_error_out t_error_out;
    
        l_opinion_consults VARCHAR2(20) := 'OPINION_CONSULTS';
    
    BEGIN
    
        CASE i_package
            WHEN 'rehab_treatments' THEN
                l_ret := pk_rehab_external_api_db.get_ordered_list(i_lang         => i_lang,
                                                                   i_prof         => profissional(i_prof_id,
                                                                                                  i_prof_inst,
                                                                                                  i_prof_soft),
                                                                   i_patient      => i_id_patient,
                                                                   i_episode      => i_episode,
                                                                   i_viewer_area  => i_viewer_area,
                                                                   o_ordered_list => l_ordered_list,
                                                                   o_error        => l_error_out);
            
            WHEN 'interv' THEN
                l_ret := pk_procedures_external_api_db.get_ordered_list(i_lang         => i_lang,
                                                                        i_prof         => profissional(i_prof_id,
                                                                                                       i_prof_inst,
                                                                                                       i_prof_soft),
                                                                        i_patient      => i_id_patient,
                                                                        i_episode      => i_episode,
                                                                        i_viewer_area  => i_viewer_area,
                                                                        o_ordered_list => l_ordered_list,
                                                                        o_error        => l_error_out);
            WHEN 'BP' THEN
                l_ret := pk_bp_external_api_db.get_ordered_list(i_lang         => i_lang,
                                                                i_prof         => profissional(i_prof_id,
                                                                                               i_prof_inst,
                                                                                               i_prof_soft),
                                                                i_patient      => i_id_patient,
                                                                i_episode      => i_episode,
                                                                i_viewer_area  => i_viewer_area,
                                                                o_ordered_list => l_ordered_list,
                                                                o_error        => l_error_out);
            WHEN 'exam' THEN
                l_ret := pk_exams_external_api_db.get_ordered_list(i_lang         => i_lang,
                                                                   i_prof         => profissional(i_prof_id,
                                                                                                  i_prof_inst,
                                                                                                  i_prof_soft),
                                                                   i_patient      => i_id_patient,
                                                                   i_viewer_area  => i_viewer_area,
                                                                   i_episode      => i_episode,
                                                                   o_ordered_list => l_ordered_list,
                                                                   o_error        => l_error_out);
            WHEN 'analysis' THEN
                l_ret := pk_lab_tests_external_api_db.get_ordered_list(i_lang         => i_lang,
                                                                       i_prof         => profissional(i_prof_id,
                                                                                                      i_prof_inst,
                                                                                                      i_prof_soft),
                                                                       i_patient      => i_id_patient,
                                                                       i_viewer_area  => i_viewer_area,
                                                                       i_episode      => i_episode,
                                                                       o_ordered_list => l_ordered_list,
                                                                       o_error        => l_error_out);
            WHEN 'allergy' THEN
                l_ret := pk_allergy.get_ordered_list(i_lang         => i_lang,
                                                     i_prof         => profissional(i_prof_id, i_prof_inst, i_prof_soft),
                                                     i_patient      => i_id_patient,
                                                     o_ordered_list => l_ordered_list,
                                                     o_error        => l_error_out);
            WHEN 'icnp' THEN
                l_ret := pk_icnp.get_ordered_list(i_lang         => i_lang,
                                                  i_prof         => profissional(i_prof_id, i_prof_inst, i_prof_soft),
                                                  i_patient      => i_id_patient,
                                                  i_viewer_area  => i_viewer_area,
                                                  i_episode      => i_episode,
                                                  o_ordered_list => l_ordered_list,
                                                  o_error        => l_error_out);
            WHEN 'medication' THEN
                l_ret := pk_rt_med_pfh.get_ordered_list(i_lang         => i_lang,
                                                        i_prof         => profissional(i_prof_id,
                                                                                       i_prof_inst,
                                                                                       i_prof_soft),
                                                        i_id_patient   => i_id_patient,
                                                        i_viewer_area  => i_viewer_area,
                                                        i_id_episode   => i_episode,
                                                        o_ordered_list => l_ordered_list,
                                                        o_error        => l_error_out);
            
                pk_types.open_cursor_if_closed(l_ordered_list);
            WHEN 'problem' THEN
                l_ret := pk_problems.get_ordered_list(i_lang         => i_lang,
                                                      i_prof         => profissional(i_prof_id, i_prof_inst, i_prof_soft),
                                                      i_patient      => i_id_patient,
                                                      o_ordered_list => l_ordered_list);
            
            WHEN 'mcdt' THEN
                l_ret := pk_mcdt.get_ordered_list(i_lang        => i_lang,
                                                  i_prof        => profissional(i_prof_id, i_prof_inst, i_prof_soft),
                                                  i_id_patient  => i_id_patient,
                                                  i_viewer_area => i_viewer_area,
                                                  i_episode     => i_episode,
                                                  o_list        => l_ordered_list,
                                                  o_error       => l_error_out);
            
            WHEN pk_alert_constant.g_viewer_filter_comm_orders THEN
                l_ret := pk_comm_orders_db.get_comm_order_viewer_list(i_lang        => i_lang,
                                                                      i_prof        => profissional(i_prof_id,
                                                                                                    i_prof_inst,
                                                                                                    i_prof_soft),
                                                                      i_patient     => i_id_patient,
                                                                      i_viewer_area => i_viewer_area,
                                                                      i_episode     => i_episode,
                                                                      o_list        => l_ordered_list,
                                                                      o_error       => l_error_out);
            WHEN l_opinion_consults THEN
                l_ret := pk_opinion.get_ordered_list_opinion(i_lang         => i_lang,
                                                             i_prof         => profissional(i_prof_id,
                                                                                            i_prof_inst,
                                                                                            i_prof_soft),
                                                             i_patient      => i_id_patient,
                                                             i_viewer_area  => i_viewer_area,
                                                             i_episode      => i_episode,
                                                             o_ordered_list => l_ordered_list,
                                                             o_error        => l_error_out);
            
            WHEN pk_prog_notes_constants.g_shift_summary_notes THEN
                l_ret := pk_ux_progress_notes.get_ordered_list(i_lang         => i_lang,
                                                               i_prof         => profissional(i_prof_id,
                                                                                              i_prof_inst,
                                                                                              i_prof_soft),
                                                               i_patient      => i_id_patient,
                                                               i_viewer_area  => i_viewer_area,
                                                               i_episode      => i_episode,
                                                               o_ordered_list => l_ordered_list,
                                                               o_error        => l_error_out);
            
            ELSE
                raise_application_error(g_undefined_error_id,
                                        t_error_encode(t_error_out(g_undefined_error_id,
                                                                   'Invalid argument i_package: ' || i_package,
                                                                   NULL,
                                                                   NULL,
                                                                   NULL,
                                                                   NULL,
                                                                   NULL,
                                                                   NULL)));
        END CASE;
    
        IF l_ret
        THEN
            RETURN l_ordered_list;
        ELSE
            raise_application_error(g_undefined_error_id, t_error_encode(l_error_out));
        END IF;
    
    END get_ordered_list;

    FUNCTION get_ordered_list_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof_id   IN professional.id_professional%TYPE,
        i_prof_inst IN institution.id_institution%TYPE,
        i_prof_soft IN software.id_software%TYPE,
        i_package   IN VARCHAR2,
        i_item      IN NUMBER
    ) RETURN pk_types.cursor_type IS
    
        l_ordered_list_det pk_types.cursor_type;
    
        l_ret BOOLEAN := FALSE;
    
        l_error_out t_error_out;
    
    BEGIN
    
        CASE i_package
            WHEN 'rehab_treatments' THEN
                l_ret := TRUE;
                pk_types.open_my_cursor(l_ordered_list_det);
            
            WHEN 'interv' THEN
                l_ret := pk_procedures_external_api_db.get_ordered_list_det(i_lang             => i_lang,
                                                                            i_prof             => profissional(i_prof_id,
                                                                                                               i_prof_inst,
                                                                                                               i_prof_soft),
                                                                            i_interv_presc_det => i_item,
                                                                            o_ordered_list_det => l_ordered_list_det,
                                                                            o_error            => l_error_out);
            WHEN 'BP' THEN
                l_ret := pk_bp_external_api_db.get_ordered_list_det(i_lang              => i_lang,
                                                                    i_prof              => profissional(i_prof_id,
                                                                                                        i_prof_inst,
                                                                                                        i_prof_soft),
                                                                    i_blood_product_det => i_item,
                                                                    o_ordered_list_det  => l_ordered_list_det,
                                                                    o_error             => l_error_out);
            WHEN 'exam' THEN
                l_ret := pk_exams_external_api_db.get_ordered_list_det(i_lang             => i_lang,
                                                                       i_prof             => profissional(i_prof_id,
                                                                                                          i_prof_inst,
                                                                                                          i_prof_soft),
                                                                       i_exam_req_det     => i_item,
                                                                       o_ordered_list_det => l_ordered_list_det,
                                                                       o_error            => l_error_out);
            WHEN 'analysis' THEN
                l_ret := pk_lab_tests_external_api_db.get_ordered_list_det(i_lang             => i_lang,
                                                                           i_prof             => profissional(i_prof_id,
                                                                                                              i_prof_inst,
                                                                                                              i_prof_soft),
                                                                           i_analysis_req_det => i_item,
                                                                           o_ordered_list_det => l_ordered_list_det,
                                                                           o_error            => l_error_out);
            WHEN 'medication' THEN
                l_ret := TRUE;
            ELSE
                raise_application_error(g_undefined_error_id,
                                        t_error_encode(t_error_out(g_undefined_error_id,
                                                                   'Invalid argument i_package: ' || i_package,
                                                                   NULL,
                                                                   NULL,
                                                                   NULL,
                                                                   NULL,
                                                                   NULL,
                                                                   NULL)));
        END CASE;
    
        IF l_ret
        THEN
            RETURN l_ordered_list_det;
        ELSE
            raise_application_error(g_undefined_error_id, t_error_encode(l_error_out));
        END IF;
    
    END get_ordered_list_det;

    FUNCTION get_lab_test_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_type         IN VARCHAR2 DEFAULT 'A',
        i_code_translation IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_codes apex_application_global.vc_arr2 := apex_util.string_to_table(i_code_translation, '|');
    
        l_result VARCHAR2(4000);
    
    BEGIN
    
        IF i_code_translation IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        IF l_codes(1) IS NOT NULL
           OR l_codes(2) IS NOT NULL
        THEN
            l_result := pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                  i_prof,
                                                                  i_flg_type,
                                                                  l_codes(1),
                                                                  l_codes(2),
                                                                  NULL);
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_desc;

    FUNCTION get_ordered_list_mobile
    (
        i_lang        IN language.id_language%TYPE,
        i_prof_id     IN professional.id_professional%TYPE,
        i_prof_inst   IN institution.id_institution%TYPE,
        i_prof_soft   IN software.id_software%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_package     IN VARCHAR2,
        i_viewer_area IN VARCHAR2,
        o_list        OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_list := get_ordered_list(i_lang        => i_lang,
                                   i_prof_id     => i_prof_id,
                                   i_prof_inst   => i_prof_inst,
                                   i_prof_soft   => i_prof_soft,
                                   i_id_patient  => i_id_patient,
                                   i_episode     => i_episode,
                                   i_package     => i_package,
                                   i_viewer_area => i_viewer_area);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        
    END get_ordered_list_mobile;
 
    FUNCTION has_patient_access
    (
        i_lang       IN language.id_language%TYPE,
        i_prof_id    IN professional.id_professional%TYPE,
        i_prof_inst  IN institution.id_institution%TYPE,
        i_prof_soft  IN software.id_software%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_access     OUT VARCHAR2
        --o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error t_error_out;
        v_error VARCHAR(4000);
        l_bool  BOOLEAN;
        l_prof  profissional := profissional(i_prof_id, i_prof_inst, i_prof_soft);
        k_access_break_the_glass CONSTANT VARCHAR2(0010 CHAR) := pk_ehr_access.g_rule_break_the_glass_access; --'F';
        k_access_not_allowed     CONSTANT VARCHAR2(0010 CHAR) := pk_ehr_access.g_rule_access_not_allowed; --'N';
        k_access_full            CONSTANT VARCHAR2(0010 CHAR) := pk_ehr_access.g_rule_free_access; --'B';
        l_access_type VARCHAR2(0010 CHAR) := k_access_full;
        k_no  CONSTANT VARCHAR2(0010 CHAR) := 'N';
        k_yes CONSTANT VARCHAR2(0010 CHAR) := 'Y';
    BEGIN
    
        l_bool := pk_ehr_access.check_ehr_access(i_lang        => i_lang,
                                                 i_prof        => l_prof,
                                                 i_id_patient  => i_id_patient,
                                                 i_id_episode  => i_episode,
                                                 o_access_type => l_access_type,
                                                 o_error       => v_error);
    
        IF NOT l_bool
        THEN
            RETURN l_bool;
        END IF;
    
        o_access := k_no;
        IF l_access_type NOT IN (k_access_break_the_glass, k_access_not_allowed)
        THEN
            o_access := k_yes;
        END IF;
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_HIBERNATE_INTF',
                                              i_function => 'HAS_PATIENT_ACCESS',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END has_patient_access;

BEGIN
    NULL;
END pk_hibernate_intf;
/
