/*-- Last Change Revision: $Rev: 2027806 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:22 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_touch_option_ti IS

    -- Private type declarations

    -- Private constant declarations
    g_vs_save_mode_new       CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_vs_save_mode_edit      CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_vs_save_mode_review    CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_vs_save_mode_associate CONSTANT VARCHAR2(1 CHAR) := 'A';

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * Returns the formatted value of vital sign associated through TOTemplate
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_vsread       ID vital sign read
    * @param   i_dt_creation  Timestamp of template's element that is associated to the vital sign read
    *
    * @return  A formatted string representing the vital sign read  
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/10/2011
    */
    FUNCTION get_formatted_vsread
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_vsread      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_dt_creation IN epis_documentation_det.dt_creation_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_vsr           VARCHAR2(1000 CHAR);
        l_formatted_vsr VARCHAR2(1000 CHAR);
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_formatted_vsread';
        l_rec_api_vs_read pk_api_vital_sign.t_rec_api_vs_read;
        l_error           t_error_out;
        l_prof_name       professional.name%TYPE;
        l_prof_spec       pk_translation.t_desc_translation;
        l_prof_signature  VARCHAR2(4000 CHAR);
        l_lbl             sys_message.desc_message%TYPE;
        co_vsr_code_state      CONSTANT sys_domain.code_domain%TYPE := 'VITAL_SIGN_READ.FLG_STATE';
        co_vsr_code_msg_edited CONSTANT sys_message.code_message%TYPE := 'VITAL_SIGNS_READ_T019';
    BEGIN
    
        g_error := 'Retrieving vital sign value';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => co_function_name);
    
        IF NOT pk_api_vital_sign.get_vital_sign_read(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_vital_sign_read => i_vsread,
                                                     o_rec_api_vs_read => l_rec_api_vs_read,
                                                     i_dt_registry     => i_dt_creation,
                                                     
                                                     o_error => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'Formating vital sign read';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => co_function_name);
    
        -- Concatenates vital sign value + UoM
        l_vsr := pk_string_utils.concat_if_exists(l_rec_api_vs_read.desc_value,
                                                  l_rec_api_vs_read.desc_unit_measure,
                                                  ' ');
    
        IF l_rec_api_vs_read.flg_state = pk_alert_constant.g_cancelled
        THEN
            l_lbl       := pk_sysdomain.get_domain_cached(i_lang        => i_lang,
                                                          i_value       => l_rec_api_vs_read.flg_state,
                                                          i_code_domain => co_vsr_code_state);
            l_prof_name := pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_prof_id => l_rec_api_vs_read.id_prof_cancel);
            l_prof_spec := pk_prof_utils.get_spec_signature(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_prof_id => l_rec_api_vs_read.id_prof_cancel,
                                                            i_dt_reg  => l_rec_api_vs_read.dt_cancel_tstz,
                                                            i_episode => l_rec_api_vs_read.id_episode);
            IF l_prof_spec IS NOT NULL
            THEN
                l_prof_spec := ' (' || l_prof_spec || ')';
            END IF;
            l_prof_signature := l_prof_name || l_prof_spec;
        
            --Format: <vs_value> (<lbl_cancel>: <dt_cancel> <prof_cancel_signature>)
            l_formatted_vsr := l_vsr || ' (' || l_lbl || ': ' ||
                               pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                           i_date => l_rec_api_vs_read.dt_cancel_tstz,
                                                           i_inst => i_prof.institution,
                                                           i_soft => i_prof.software) || ' ' || l_prof_signature || ')';
        
        ELSIF l_rec_api_vs_read.flg_edit = pk_alert_constant.g_yes
        THEN
            l_lbl := pk_message.get_message(i_lang => i_lang, i_code_mess => co_vsr_code_msg_edited);
        
            l_prof_name := pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_prof_id => l_rec_api_vs_read.id_prof_edit);
            l_prof_spec := pk_prof_utils.get_spec_signature(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_prof_id => l_rec_api_vs_read.id_prof_edit,
                                                            i_dt_reg  => l_rec_api_vs_read.dt_edit,
                                                            i_episode => l_rec_api_vs_read.id_episode);
            IF l_prof_spec IS NOT NULL
            THEN
                l_prof_spec := ' (' || l_prof_spec || ')';
            END IF;
            l_prof_signature := l_prof_name || l_prof_spec;
        
            --Format: <vs_value> (<lbl_edit>: <dt_edit> <prof_edit_signature>)
            l_formatted_vsr := l_vsr || ' (' || l_lbl || ': ' ||
                               pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                           i_date => l_rec_api_vs_read.dt_edit,
                                                           i_inst => i_prof.institution,
                                                           i_soft => i_prof.software) || ' ' || l_prof_signature || ')';
        ELSE
            l_formatted_vsr := l_vsr;
        END IF;
    
        RETURN l_formatted_vsr;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => co_function_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_formatted_vsread;

    /**
    * Returns the item's description. In case of an element that refers to a value in an external functionallity 
    * (Master area for the transfer of information) returns the description that is used in that area.
    * Otherwise, it returns the translation of code passed as input parameter.
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_flg_type     Element type. It is used to recognize the element in the case of references to a master area
    * @param   i_master_item  ID of an item in a master area that is represented by this element
    * @param   i_code_trans   Code used to retrieve applicable translation when the element is no related with master areas
    *
    * @return  A string to use as element's description
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/17/2011
    */
    FUNCTION get_element_description
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN doc_element.flg_type%TYPE,
        i_master_item IN doc_element.id_master_item%TYPE,
        i_code_trans  IN translation.code_translation%TYPE
    ) RETURN VARCHAR2 IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_element_description';
        l_description pk_translation.t_desc_translation;
        l_error       t_error_out;
    BEGIN
    
        CASE i_flg_type
        
            WHEN pk_touch_option.g_elem_flg_type_vital_sign THEN
                --Master Area: Vital Signs
                --Master Item: id_vital_sign
                l_description := pk_vital_sign.get_vs_desc(i_lang       => i_lang,
                                                           i_vital_sign => i_master_item,
                                                           i_short_desc => pk_alert_constant.get_no);
            ELSE
                --Default: Description of element in template
                l_description := pk_translation.get_translation(i_lang => i_lang, i_code_mess => i_code_trans);
        END CASE;
        RETURN l_description;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => co_function_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_element_description;

    /**************************************************************************
    * Get latest reading for a list vital sign identifiers and a patient      *
    * identifier                                                              *
    *                                                                         *
    * @param   i_lang                   Professional preferred language       *
    * @param   i_prof                   Professional identification and its   *
    *                                   context (institution and software)    *
    * @param   i_patient                Patient ID                            *
    * @param   i_episode                Episode ID                            *
    * @param   i_tbl_vs                 Vital Sign list ID                    *
    * @param   o_vs_info                Information about vital sign records  *
    * @param   o_error                  Error information                     *
    *                                                                         *
    * @return  Boolean                                                        *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 2.6.1                                                          *
    * @since   21/3/2011                                                      *
    **************************************************************************/
    FUNCTION get_vs_info
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_episode                  IN episode.id_episode%TYPE,
        i_tbl_vs                   IN table_number,
        i_tbl_aux_vs               IN table_number,
        i_flg_show_previous_values IN VARCHAR2 DEFAULT NULL,
        i_hash_vital_sign          IN table_table_varchar,
        o_vs_info                  OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_vs_info';
    
        l_dt_syscfg    sys_config.value%TYPE;
        l_dt_threshold TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_error t_error_out;
        l_exception EXCEPTION;
        l_dt_begin VARCHAR2(200 CHAR);
        l_dt_end   VARCHAR2(200 CHAR);
        --   L_HASH_VITAL_SIGN T_HASH_VITAL_SIGN; 
    BEGIN
    
        --L_HASH_VITAL_SIGN:= i_hash_vital_sign;
        g_error     := 'Fetch sys_config TO_VS_DAYS_THRESHOLD';
        l_dt_syscfg := pk_sysconfig.get_config(i_code_cf => 'TO_VS_DAYS_THRESHOLD', i_prof => i_prof);
    
        IF (nvl(l_dt_syscfg, 0) != 0)
        THEN
            g_error        := 'Calculate date from threshold - ' || l_dt_syscfg;
            l_dt_threshold := pk_date_utils.add_to_ltstz(i_timestamp => trunc(current_timestamp),
                                                         i_amount    => (l_dt_syscfg * -1),
                                                         i_unit      => 'DAY');
        ELSE
            l_dt_threshold := pk_date_utils.add_to_ltstz(i_timestamp => trunc(current_timestamp),
                                                         i_amount    => 0,
                                                         i_unit      => 'DAY');
        
        END IF;
    
        l_dt_begin := pk_date_utils.date_send_tsz(i_lang, l_dt_threshold, i_prof);
        l_dt_end   := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        g_error := 'Call pk_api_vital_sign.get_latest_vital_sign_read l_dt_begin:' || l_dt_begin || 'l_dt_end:' ||
                   l_dt_end;
    
        IF NOT pk_api_vital_sign.get_latest_vital_sign_read(i_lang                     => i_lang,
                                                            i_prof                     => i_prof,
                                                            i_patient                  => i_patient,
                                                            i_episode                  => i_episode,
                                                            i_flg_view                 => NULL,
                                                            i_dt_threshold             => l_dt_threshold,
                                                            i_tbl_vs                   => i_tbl_vs,
                                                            i_tbl_aux_vs               => i_tbl_aux_vs,
                                                            i_flg_show_previous_values => i_flg_show_previous_values,
                                                            i_dt_begin                 => l_dt_begin,
                                                            i_dt_end                   => l_dt_end,
                                                            i_hash_vital_sign          => i_hash_vital_sign, -- i_hash_vital_sign, 
                                                            i_flg_show_relations       => pk_alert_constant.g_yes,
                                                            o_vs_info                  => o_vs_info,
                                                            o_error                    => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => l_error.ora_sqlcode,
                                              i_sqlerrm  => l_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            pk_types.open_cursor_if_closed(o_vs_info);
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
        
            pk_types.open_cursor_if_closed(o_vs_info);
            RETURN FALSE;
    END get_vs_info;

    /**
    * Returns a list of vital signs that are referenced by elements of this template and area that are applicable to patient
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Area ID
    * @param   i_doc_template       Template ID
    * @param   i_pat_gender         Patient's gender
    * @param   i_pat_age            Patient's age
    * @param   i_include_vs_rel     Include related vital sign (in case it has). Default: Yes
    * @param   o_lst_vs             List of vital signs
    * @param   o_lst_conf_vs        List of configured vital signs for instit/softw
    * @param   o_error              Error information
    *
    * @value i_include_vs_rel       {*} 'Y'  Yes {*} 'N' No
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/21/2011
    */
    FUNCTION get_template_vs_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_doc_template    IN doc_template.id_doc_template%TYPE,
        i_pat_gender      IN patient.gender%TYPE,
        i_pat_age         IN patient.age%TYPE,
        i_flg_view        IN vs_soft_inst.flg_view%TYPE,
        i_include_vs_rel  IN VARCHAR DEFAULT pk_alert_constant.g_yes,
        o_lst_vs          OUT table_number,
        o_lst_aux_vs      OUT table_number,
        o_lst_conf_vs     OUT table_number,
        o_hash_vital_sign OUT table_table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_template_vs_list';
        l_lst_master_vs   table_number;
        l_vs_clinical_dt  table_varchar;
        l_hash_vital_sign table_table_varchar := table_table_varchar();
        l_vital           table_varchar;
    BEGIN
    
        --List of vital signs that are referenced by elements of this template
        SELECT de.id_master_item, de.id_master_item_aux, de.flg_clinical_dt_block
          BULK COLLECT
          INTO l_lst_master_vs, o_lst_aux_vs, l_vs_clinical_dt
          FROM doc_template_area_doc dtad
         INNER JOIN documentation d
            ON dtad.id_documentation = d.id_documentation
         INNER JOIN doc_component dcomp
            ON d.id_doc_component = dcomp.id_doc_component
         INNER JOIN doc_element de
            ON d.id_documentation = de.id_documentation
         WHERE dtad.id_doc_template = i_doc_template
           AND dtad.id_doc_area = i_doc_area
           AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
           AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
           AND de.flg_type = pk_touch_option.g_elem_flg_type_vital_sign
           AND d.flg_available = pk_alert_constant.g_available
           AND dcomp.flg_available = pk_alert_constant.g_available
           AND de.flg_available = pk_alert_constant.g_available
           AND (dcomp.flg_gender IS NULL OR dcomp.flg_gender = i_pat_gender OR
               i_pat_gender = pk_touch_option.g_gender_i)
           AND (nvl(i_pat_age, 0) BETWEEN nvl(dcomp.age_min, 0) AND nvl(dcomp.age_max, nvl(i_pat_age, 0)) OR
               i_pat_age IS NULL)
           AND (de.flg_gender IS NULL OR de.flg_gender = i_pat_gender OR i_pat_gender = pk_touch_option.g_gender_i)
           AND (nvl(i_pat_age, 0) BETWEEN nvl(de.age_min, 0) AND nvl(de.age_max, nvl(i_pat_age, 0)) OR
               i_pat_age IS NULL);
    
        FOR i IN 1 .. l_vs_clinical_dt.count
        LOOP
            l_hash_vital_sign.extend();
            l_vital := table_varchar(l_lst_master_vs(i), nvl(l_vs_clinical_dt(i), pk_alert_constant.g_no));
            l_hash_vital_sign(l_hash_vital_sign.last) := l_vital;
            --            l_hash_vital_sign(l_hash_vital_sign.LAST):= table_varchar(l_lst_master_vs(I), Nvl(l_vs_clinical_dt(i), pk_alert_constant.g_no));
        END LOOP;
    
        IF l_lst_master_vs.count > 0
           AND i_include_vs_rel = pk_alert_constant.g_yes
        THEN
            g_error := 'COUNT VITAL SIGN CONFS FOR SOFTWARE AND INSTITUTION';
            SELECT DISTINCT vsi.id_vital_sign
              BULK COLLECT
              INTO o_lst_conf_vs
              FROM vs_soft_inst vsi
             INNER JOIN vital_sign vs
                ON vsi.id_vital_sign = vs.id_vital_sign
               AND vs.flg_available = pk_alert_constant.g_yes
             WHERE vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND (i_flg_view IS NULL OR vsi.flg_view = i_flg_view);
        
            --List of vital signs (including their children, in case it has) that are referenced by elements of this template
            SELECT DISTINCT id_vital_sign
              BULK COLLECT
              INTO o_lst_vs
              FROM (SELECT vs.id_vital_sign
                      FROM vital_sign vs
                     WHERE vs.id_vital_sign IN (SELECT /*+ opt_estimate(table t rows=2)*/
                                                 t.column_value
                                                  FROM TABLE(l_lst_master_vs) t)
                    UNION ALL
                    SELECT vsr.id_vital_sign_detail id_vital_sign
                      FROM vital_sign_relation vsr
                     WHERE vsr.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                       AND vsr.id_vital_sign_parent IN (SELECT /*+ opt_estimate(table t rows=2)*/
                                                         t.column_value
                                                          FROM TABLE(l_lst_master_vs) t));
        
        ELSE
            o_lst_vs      := l_lst_master_vs;
            o_lst_conf_vs := table_number();
        END IF;
        o_hash_vital_sign := l_hash_vital_sign;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => co_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_template_vs_list;

    /**
    * Save vital signs measurement using Touch-option framework
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   i_episode                Episode ID
    * @param   i_pat                    Patient ID
    * @param   i_doc_element_list       List of template's elements ID (id_doc_element)
    * @param   i_save_mode_list         List of flags to indicate the applicable mode to save each vital signs measurement
    * @param   i_vital_sign_list        List of vital signs ID (id_vital_sign)
    * @param   i_vital_sign_value_list  List of vital signs values
    * @param   i_vital_sign_uom_list    List of units of measurement (id_unit_measure)
    * @param   i_vital_sign_scales_list List of scales (id_vs_scales_element)
    * @param   i_vital_sign_date_list   List of measurement date. Values are serialized as strings (YYYYMMDDhh24miss)
    * @param   i_vital_sign_read_list   List of saved vital sign measurement (id_vital_sign_read)
    * @param   i_dt_creation_tstz       Timestamp entry. Default current timestamp
    *
    * @param   o_doc_element_vs_list    List of template's elements ID and respective collection of saved vital sign measurement
    
    * @param   o_error                  Error information
    *
    * @value i_save_mode_list {*} 'N' Creates a new measurement and associates it with element. {*} 'E' Edits the measurement and associates it with element. {*} 'R' Reviews the measurement and associates it with element. {*} 'A' Associates the measurement with the element but does not perform any operation in referred vital sign    
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/24/2011
    */

    FUNCTION set_epis_vital_sign_touch
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_pat                    IN patient.id_patient%TYPE,
        i_doc_element_list       IN table_number,
        i_save_mode_list         IN table_varchar,
        i_vital_sign_list        IN table_number,
        i_vital_sign_value_list  IN table_number,
        i_vital_sign_uom_list    IN table_number,
        i_vital_sign_scales_list IN table_number,
        i_vital_sign_date_list   IN table_varchar,
        i_vital_sign_read_list   IN table_number,
        i_dt_creation_tstz       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_id_edit_reason         IN table_number DEFAULT NULL,
        i_notes_edit             IN table_clob DEFAULT NULL,
        i_id_epis_documentation  IN epis_documentation.id_epis_documentation%TYPE,
        o_doc_element_vs_list    OUT t_coll_doc_element_vs,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_epis_vital_sign_touch';
        co_failed        CONSTANT VARCHAR2(6 CHAR) := 'FAILED';
        co_passed        CONSTANT VARCHAR2(6 CHAR) := 'passed';
        CURSOR c_data_quality IS
            SELECT x.id_doc_element,
                   x.id_vital_sign_to_save,
                   x.id_vital_sign_to_save_parent,
                   x.flg_type,
                   x.id_vital_sign_element,
                   x.chk_element_pass,
                   x.chk_flg_type_pass,
                   x.chk_vital_sign_pass
              FROM (SELECT de.column_value id_doc_element,
                           vs.column_value id_vital_sign_to_save,
                           pk_vital_sign.get_vs_parent(vs.column_value) id_vital_sign_to_save_parent,
                           dex.flg_type,
                           dex.id_master_item id_vital_sign_element,
                           decode(dex.id_doc_element, NULL, co_failed, co_passed) chk_element_pass,
                           decode(dex.flg_type, pk_touch_option.g_elem_flg_type_vital_sign, co_passed, co_failed) chk_flg_type_pass,
                           decode(vs.column_value,
                                  coalesce(dex.id_master_item, -1),
                                  co_passed,
                                  decode(pk_vital_sign.get_vs_parent(vs.column_value),
                                         coalesce(dex.id_master_item, -1),
                                         co_passed,
                                         co_failed)) chk_vital_sign_pass
                      FROM (SELECT /*+ opt_estimate(table t rows=10)*/
                             rownum rown, t.column_value
                              FROM TABLE(i_doc_element_list) t) de
                      JOIN (SELECT /*+ opt_estimate(table t rows=20)*/
                            rownum rown, t.column_value
                             FROM TABLE(i_vital_sign_list) t) vs
                        ON de.rown = vs.rown
                      LEFT JOIN doc_element dex
                        ON de.column_value = dex.id_doc_element) x
             WHERE x.chk_element_pass = co_failed
                OR x.chk_flg_type_pass = co_failed
                OR x.chk_vital_sign_pass = co_failed;
    
        TYPE t_coll_data_quality IS TABLE OF c_data_quality%ROWTYPE;
    
        e_invalid_array_size EXCEPTION;
        e_invalid_argument   EXCEPTION;
        e_function_call      EXCEPTION;
        e_data_quality_error EXCEPTION;
    
        l_prof_cat_type       category.flg_type%TYPE;
        l_element_vs_tmp_list t_coll_doc_element_vs;
        l_data_quality_list   t_coll_data_quality;
    
        --New measurements
        l_new_element_list   table_number := table_number();
        l_new_vs_list        table_number := table_number();
        l_new_vs_value_list  table_number := table_number();
        l_new_vs_uom_list    table_number := table_number();
        l_new_vs_scales_list table_number := table_number();
        l_new_vs_date_list   table_varchar := table_varchar();
        l_new_vs_read_list   table_number := table_number();
    
        --Review measurements
        l_rev_element_list   table_number := table_number();
        l_rev_vs_list        table_number := table_number();
        l_rev_vs_value_list  table_number := table_number();
        l_rev_vs_uom_list    table_number := table_number();
        l_rev_vs_scales_list table_number := table_number();
        l_rev_vs_date_list   table_varchar := table_varchar();
        l_rev_vs_read_list   table_number := table_number();
        --Edit measurements
        l_edt_element_list   table_number := table_number();
        l_edt_vs_list        table_number := table_number();
        l_edt_vs_value_list  table_number := table_number();
        l_edt_vs_uom_list    table_number := table_number();
        l_edt_vs_scales_list table_number := table_number();
        l_edt_vs_date_list   table_varchar := table_varchar();
        l_edt_vs_read_list   table_number := table_number();
        l_edt_id_edit_reason table_number := table_number();
        l_edt_notes_edit     table_clob := table_clob();
        --Association-only measurements
        l_asc_element_list   table_number := table_number();
        l_asc_vs_list        table_number := table_number();
        l_asc_vs_value_list  table_number := table_number();
        l_asc_vs_uom_list    table_number := table_number();
        l_asc_vs_scales_list table_number := table_number();
        l_asc_vs_date_list   table_varchar := table_varchar();
        l_asc_vs_read_list   table_number := table_number();
        l_dt_registry        VARCHAR2(20 CHAR);
    BEGIN
    
        --Sanity check: all arrays must have same size
        IF i_doc_element_list.count != i_save_mode_list.count
           OR i_doc_element_list.count != i_vital_sign_list.count
           OR i_doc_element_list.count != i_vital_sign_value_list.count
           OR i_doc_element_list.count != i_vital_sign_uom_list.count
           OR i_doc_element_list.count != i_vital_sign_scales_list.count
           OR i_doc_element_list.count != i_vital_sign_date_list.count
           OR i_doc_element_list.count != i_vital_sign_read_list.count
        THEN
            RAISE e_invalid_array_size;
        END IF;
    
        --Sanity checks: data quality
        -- CHK_ELEMENT_PASS: The element must exist
        -- CHK_FLG_TYPE_PASS: The element must be defined as vital sign: flg_type=VS
        -- CHK_VITAL_SIGN_PASS: The vital sign ID to save should be the same as that associated with the element (simple VS) or have it as parent (compound VS like blood pressure).
        OPEN c_data_quality;
        FETCH c_data_quality BULK COLLECT
            INTO l_data_quality_list;
        CLOSE c_data_quality;
    
        IF l_data_quality_list.count > 0
        THEN
            --We have inconsistent data as input arguments
            RAISE e_data_quality_error;
        END IF;
    
        -- Split the arrays according with the save-mode flag (i_save_mode_list) in 4 groups of operations:
        -- (1) Create new VS measurements
        -- (2) Review VS measurements
        -- (3) Edit VS measurements
        -- (4) Associate VS measurements
        -- After all operations done we need to return to each element a array of id_vital_sign_read 
        -- (are arrays because can be 1 or more VSR for vital signs like blood pressure) that will be associated to the element
        -- These association will be done in set_epis_documentation, concatenating each VSR with pipes and filling the field EPIS_DOCUMENTATION_DET.VALUE_PROPERTIES.
    
        --Initializes the output resultset
        o_doc_element_vs_list := t_coll_doc_element_vs();
    
        g_error := 'Split arrays in 4 groups of operations';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => co_function_name);
        FOR x IN 1 .. i_save_mode_list.count
        LOOP
            CASE i_save_mode_list(x)
                WHEN g_vs_save_mode_new THEN
                    l_new_element_list.extend();
                    l_new_element_list(l_new_element_list.last) := i_doc_element_list(x);
                
                    l_new_vs_list.extend();
                    l_new_vs_list(l_new_vs_list.last) := i_vital_sign_list(x);
                
                    l_new_vs_value_list.extend();
                    l_new_vs_value_list(l_new_vs_value_list.last) := i_vital_sign_value_list(x);
                
                    l_new_vs_uom_list.extend();
                    l_new_vs_uom_list(l_new_vs_uom_list.last) := i_vital_sign_uom_list(x);
                
                    l_new_vs_scales_list.extend();
                    l_new_vs_scales_list(l_new_vs_scales_list.last) := i_vital_sign_scales_list(x);
                
                    l_new_vs_date_list.extend();
                    l_new_vs_date_list(l_new_vs_date_list.last) := i_vital_sign_date_list(x);
                
                    l_new_vs_read_list.extend();
                    l_new_vs_read_list(l_new_vs_read_list.last) := i_vital_sign_read_list(x);
                
                WHEN g_vs_save_mode_review THEN
                
                    l_rev_element_list.extend();
                    l_rev_element_list(l_rev_element_list.last) := i_doc_element_list(x);
                
                    l_rev_vs_list.extend();
                    l_rev_vs_list(l_rev_vs_list.last) := i_vital_sign_list(x);
                
                    l_rev_vs_value_list.extend();
                    l_rev_vs_value_list(l_rev_vs_value_list.last) := i_vital_sign_value_list(x);
                
                    l_rev_vs_uom_list.extend();
                    l_rev_vs_uom_list(l_rev_vs_uom_list.last) := i_vital_sign_uom_list(x);
                
                    l_rev_vs_scales_list.extend();
                    l_rev_vs_scales_list(l_rev_vs_scales_list.last) := i_vital_sign_scales_list(x);
                
                    l_rev_vs_date_list.extend();
                    l_rev_vs_date_list(l_rev_vs_date_list.last) := i_vital_sign_date_list(x);
                
                    l_rev_vs_read_list.extend();
                    l_rev_vs_read_list(l_rev_vs_read_list.last) := i_vital_sign_read_list(x);
                
                WHEN g_vs_save_mode_edit THEN
                    l_edt_element_list.extend();
                    l_edt_element_list(l_edt_element_list.last) := i_doc_element_list(x);
                
                    l_edt_vs_list.extend();
                    l_edt_vs_list(l_edt_vs_list.last) := i_vital_sign_list(x);
                
                    l_edt_vs_value_list.extend();
                    l_edt_vs_value_list(l_edt_vs_value_list.last) := i_vital_sign_value_list(x);
                
                    l_edt_vs_uom_list.extend();
                    l_edt_vs_uom_list(l_edt_vs_uom_list.last) := i_vital_sign_uom_list(x);
                
                    l_edt_vs_scales_list.extend();
                    l_edt_vs_scales_list(l_edt_vs_scales_list.last) := i_vital_sign_scales_list(x);
                
                    l_edt_vs_date_list.extend();
                    l_edt_vs_date_list(l_edt_vs_date_list.last) := i_vital_sign_date_list(x);
                
                    l_edt_vs_read_list.extend();
                    l_edt_vs_read_list(l_edt_vs_read_list.last) := i_vital_sign_read_list(x);
                
                    IF i_id_edit_reason.exists(x)
                    THEN
                        l_edt_id_edit_reason.extend();
                        l_edt_id_edit_reason(l_edt_id_edit_reason.last) := i_id_edit_reason(x);
                    ELSE
                        l_edt_id_edit_reason.extend();
                        l_edt_id_edit_reason(l_edt_id_edit_reason.last) := NULL;
                    END IF;
                
                    IF i_notes_edit.exists(x)
                    THEN
                        l_edt_notes_edit.extend();
                        l_edt_notes_edit(l_edt_notes_edit.last) := i_notes_edit(x);
                    ELSE
                        l_edt_notes_edit.extend();
                        l_edt_notes_edit(l_edt_notes_edit.last) := NULL;
                    END IF;
                
                WHEN g_vs_save_mode_associate THEN
                    l_asc_element_list.extend();
                    l_asc_element_list(l_asc_element_list.last) := i_doc_element_list(x);
                
                    l_asc_vs_list.extend();
                    l_asc_vs_list(l_asc_vs_list.last) := i_vital_sign_list(x);
                
                    l_asc_vs_value_list.extend();
                    l_asc_vs_value_list(l_asc_vs_value_list.last) := i_vital_sign_value_list(x);
                
                    l_asc_vs_uom_list.extend();
                    l_asc_vs_uom_list(l_asc_vs_uom_list.last) := i_vital_sign_uom_list(x);
                
                    l_asc_vs_scales_list.extend();
                    l_asc_vs_scales_list(l_asc_vs_scales_list.last) := i_vital_sign_scales_list(x);
                
                    l_asc_vs_date_list.extend();
                    l_asc_vs_date_list(l_asc_vs_date_list.last) := i_vital_sign_date_list(x);
                
                    l_asc_vs_read_list.extend();
                    l_asc_vs_read_list(l_asc_vs_read_list.last) := i_vital_sign_read_list(x);
                
                ELSE
                    RAISE e_invalid_argument;
            END CASE;
        
        END LOOP;
    
        -- Creates VS measurements
        IF l_new_element_list.count > 0
        THEN
            g_error := 'Creating VS measurements';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => co_function_name);
            IF NOT pk_vital_sign.set_epis_vital_sign(i_lang                  => i_lang,
                                                     i_episode               => i_episode,
                                                     i_prof                  => i_prof,
                                                     i_pat                   => i_pat,
                                                     i_vs_id                 => l_new_vs_list,
                                                     i_vs_val                => l_new_vs_value_list,
                                                     i_id_monit              => NULL,
                                                     i_unit_meas             => l_new_vs_uom_list,
                                                     i_vs_scales_elements    => l_new_vs_scales_list,
                                                     i_notes                 => NULL,
                                                     i_prof_cat_type         => l_prof_cat_type,
                                                     i_dt_vs_read            => l_new_vs_date_list,
                                                     i_epis_triage           => NULL,
                                                     i_unit_meas_convert     => l_new_vs_uom_list,
                                                     i_tbtb_attribute        => table_table_number(),
                                                     i_tbtb_free_text        => table_table_clob(),
                                                     i_id_edit_reason        => i_id_edit_reason,
                                                     i_notes_edit            => i_notes_edit,
                                                     i_id_epis_documentation => i_id_epis_documentation,
                                                     o_vital_sign_read       => l_new_vs_read_list,
                                                     o_dt_registry           => l_dt_registry,
                                                     o_error                 => o_error)
            THEN
                g_error := 'The function pk_vital_sign.set_epis_vital_sign returns error';
                RAISE e_function_call;
            END IF;
        
            --Each row has the ID_DOC_ELEMENT and a collection of ID_VITAL_SIGN_READ that are associated
            SELECT de.column_value id_doc_element, CAST(COLLECT(vsr.column_value) AS table_number)
              BULK COLLECT
              INTO l_element_vs_tmp_list
              FROM (SELECT rownum rown, column_value
                      FROM TABLE(l_new_element_list)) de
              JOIN (SELECT rownum rown, column_value
                      FROM TABLE(l_new_vs_read_list)) vsr
                ON de.rown = vsr.rown
             GROUP BY de.column_value;
        
            g_error := 'Creates VS - Number of elements that have been processed: ' || l_element_vs_tmp_list.count;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => co_function_name);
        
            --Append to output resultset the list of vital signs created
            o_doc_element_vs_list := o_doc_element_vs_list MULTISET UNION ALL l_element_vs_tmp_list;
        END IF;
    
        --Reviews VS measurements that have already been made and accepted to be associated to template's elements
        IF l_rev_element_list.count > 0
        THEN
            g_error := 'Reviewing VS measurements';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => co_function_name);
            IF NOT pk_vital_sign.set_vital_sign_review(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_episode            => i_episode,
                                                       i_id_vital_sign_read => l_rev_vs_read_list,
                                                       i_review_notes       => NULL,
                                                       o_error              => o_error)
            THEN
                g_error := 'The function pk_vital_sign.set_vital_sign_review returns error';
                RAISE e_function_call;
            END IF;
        
            --Each row has the ID_DOC_ELEMENT and a collection of ID_VITAL_SIGN_READ that are associated
            SELECT de.column_value id_doc_element, CAST(COLLECT(vsr.column_value) AS table_number)
              BULK COLLECT
              INTO l_element_vs_tmp_list
              FROM (SELECT rownum rown, column_value
                      FROM TABLE(l_rev_element_list)) de
              JOIN (SELECT rownum rown, column_value
                      FROM TABLE(l_rev_vs_read_list)) vsr
                ON de.rown = vsr.rown
             GROUP BY de.column_value;
        
            g_error := 'Reviews VS - Number of elements that have been processed: ' || l_element_vs_tmp_list.count;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => co_function_name);
        
            --Append to output resultset the list of vital signs reviewed
            o_doc_element_vs_list := o_doc_element_vs_list MULTISET UNION ALL l_element_vs_tmp_list;
        END IF;
    
        -- Edits VS measurements that were changed when correct an entry
        IF l_edt_element_list.count > 0
        THEN
            g_error := 'Editing VS measurements';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => co_function_name);
        
            --TODO: Improve this code replacing the loop by a function that accepts arrays (CORE team will build this function)
            FOR x IN 1 .. l_edt_element_list.count
            LOOP
                IF NOT pk_vital_sign.edit_vital_sign(i_lang                    => i_lang,
                                                     i_prof                    => i_prof,
                                                     i_id_vital_sign_read      => l_edt_vs_read_list(x),
                                                     i_value                   => l_edt_vs_value_list(x),
                                                     i_id_unit_measure         => l_edt_vs_uom_list(x),
                                                     i_dt_vital_sign_read_tstz => l_edt_vs_date_list(x),
                                                     i_dt_registry             => pk_date_utils.date_send_tsz(i_lang,
                                                                                                              i_dt_creation_tstz,
                                                                                                              i_prof),
                                                     i_id_unit_measure_sel     => l_edt_vs_uom_list(x),
                                                     i_tb_attribute            => NULL,
                                                     i_tb_free_text            => NULL,
                                                     i_id_edit_reason          => l_edt_id_edit_reason(x),
                                                     i_notes_edit              => l_edt_notes_edit(x),
                                                     -- i_id_epis_documentation=>i_id_epis_documentation,
                                                     o_error => o_error)
                
                THEN
                    g_error := 'The function pk_vital_sign.edit_vital_sign returns error';
                    RAISE e_function_call;
                END IF;
            END LOOP;
        
            --Each row has the ID_DOC_ELEMENT and a collection of ID_VITAL_SIGN_READ that are associated
            SELECT de.column_value id_doc_element, CAST(COLLECT(vsr.column_value) AS table_number)
              BULK COLLECT
              INTO l_element_vs_tmp_list
              FROM (SELECT rownum rown, column_value
                      FROM TABLE(l_edt_element_list)) de
              JOIN (SELECT rownum rown, column_value
                      FROM TABLE(l_edt_vs_read_list)) vsr
                ON de.rown = vsr.rown
             GROUP BY de.column_value;
        
            g_error := 'Edits VS - Number of elements that have been processed: ' || l_element_vs_tmp_list.count;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => co_function_name);
        
            --Append to output resultset the list of vital signs edited
            o_doc_element_vs_list := o_doc_element_vs_list MULTISET UNION ALL l_element_vs_tmp_list;
        END IF;
    
        -- Associates VS measurements to elements
        IF l_asc_element_list.count > 0
        THEN
            g_error := 'Associating VS measurements';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => co_function_name);
        
            --Each row has the ID_DOC_ELEMENT and a collection of ID_VITAL_SIGN_READ that are associated
            SELECT de.column_value id_doc_element, CAST(COLLECT(vsr.column_value) AS table_number)
              BULK COLLECT
              INTO l_element_vs_tmp_list
              FROM (SELECT rownum rown, column_value
                      FROM TABLE(l_asc_element_list)) de
              JOIN (SELECT rownum rown, column_value
                      FROM TABLE(l_asc_vs_read_list)) vsr
                ON de.rown = vsr.rown
             GROUP BY de.column_value;
        
            g_error := 'Associates VS - Number of elements that have been processed: ' || l_element_vs_tmp_list.count;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => co_function_name);
        
            --Append to output resultset the list of vital signs associated
            o_doc_element_vs_list := o_doc_element_vs_list MULTISET UNION ALL l_element_vs_tmp_list;
        
        END IF;
    
        g_error := 'Total number of elements that have been processed: ' || o_doc_element_vs_list.count;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => co_function_name);
    
        --Output resultset filled and ready to returns OK.
        RETURN TRUE;
    EXCEPTION
        WHEN e_invalid_array_size THEN
            g_error := 'Invalid input parameters. Input arrays must have same size';
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Invalid array size',
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => co_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
        WHEN e_function_call THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Error calling internal function',
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => co_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
        
        WHEN e_data_quality_error THEN
            DECLARE
                l_data_quality c_data_quality%ROWTYPE;
            BEGIN
                g_error := 'id_doc_element|id_vital_sign_to_save|id_vital_sign_to_save_parent|flg_type|id_vital_sign_element|chk_element_pass|chk_flg_type_pass|chk_vital_sign_pass';
                pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => co_function_name);
                FOR x IN 1 .. l_data_quality_list.count
                LOOP
                    l_data_quality := l_data_quality_list(x);
                
                    g_error := l_data_quality.id_doc_element || '|' || l_data_quality.id_vital_sign_to_save || '|' ||
                               l_data_quality.id_vital_sign_to_save_parent || '|' || l_data_quality.flg_type || '|' ||
                               l_data_quality.id_vital_sign_element || '|' || l_data_quality.chk_element_pass || '|' ||
                               l_data_quality.chk_flg_type_pass || '|' || l_data_quality.chk_vital_sign_pass;
                
                    pk_alertlog.log_error(text            => g_error,
                                          object_name     => g_package,
                                          sub_object_name => co_function_name);
                END LOOP;
            
                g_error := 'Data quality failed for input arguments. See the error logging table for more information';
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => 'Inconsistent data',
                                                  i_message  => g_error,
                                                  i_owner    => g_owner,
                                                  i_package  => g_package,
                                                  i_function => co_function_name,
                                                  o_error    => o_error);
            
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => co_function_name,
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
    END set_epis_vital_sign_touch;

    /**
    * Check if documentation entry has elements that refers to values in an external functionality 
     (Master area for the transfer of information) that were edited/updated after a specific timestamp
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   i_epis_documentation     Epis documentation ID
    * @param   i_dt_creation            Timestamp to check if related master areas that were associated to entry were edited after this date
    * @param   o_changed                Returns if the entry has or not references to information that was edited after input timestamp
    * @param   o_error                  Error information
    *
    * @value o_changed {*} 'Y' Has info edited. {*} 'N' Has no info changed
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   5/20/2011
    */
    FUNCTION check_ti_info_changed
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_dt_creation        IN epis_documentation.dt_creation_tstz%TYPE,
        o_ref_info_changed   OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'check_ti_info_changed';
        l_exception EXCEPTION;
        l_changed         VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_props_list      table_varchar2 := table_varchar2();
        l_aux             table_varchar2 := table_varchar2();
        l_vsr_list        table_number := table_number();
        l_changed_entries NUMBER(24);
    BEGIN
    
        -- Check related vital signs
        BEGIN
            SELECT edd.value_properties
              BULK COLLECT
              INTO l_props_list
              FROM epis_documentation_det edd
              JOIN doc_element de
                ON de.id_doc_element = edd.id_doc_element
             WHERE edd.id_epis_documentation = i_epis_documentation
               AND de.flg_type = pk_touch_option.g_elem_flg_type_vital_sign;
        EXCEPTION
            WHEN no_data_found THEN
                -- No vital signs were documented
                NULL;
        END;
        IF l_props_list.count > 0
        THEN
        
            FOR i IN 1 .. l_props_list.count
            LOOP
                l_aux := l_aux MULTISET UNION pk_utils.str_split(i_list => l_props_list(i), i_delim => '|');
            END LOOP;
        
            -- varchar2 to number conversion
        
            IF l_aux IS NOT NULL
            THEN
                l_vsr_list.extend(l_aux.count);
                FOR i IN 1 .. l_aux.count
                LOOP
                    l_vsr_list(i) := to_number(l_aux(i));
                END LOOP;
            
                g_error := 'Call pk_api_vital_sign.check_vsr_changed';
                IF NOT pk_api_vital_sign.check_vsr_changed(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_vsr_list         => l_vsr_list,
                                                           i_dt_creation      => i_dt_creation,
                                                           o_ref_info_changed => l_changed,
                                                           o_error            => o_error)
                THEN
                    RAISE l_exception;
                
                END IF;
            END IF;
        END IF;
    
        -- Master areas where exists transfer of information with Toch-option templates must include same type of validation here
    
        o_ref_info_changed := l_changed;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => co_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => co_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END check_ti_info_changed;

    FUNCTION cancel_epis_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_cancel_reason   IN epis_documentation.id_cancel_reason%TYPE DEFAULT NULL,
        i_notes              IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        tbl_id_vital_sign_read table_number;
        l_exception EXCEPTION;
    BEGIN
        SELECT vsr.id_vital_sign_read
          BULK COLLECT
          INTO tbl_id_vital_sign_read
          FROM vital_sign_read vsr
         WHERE vsr.id_epis_documentation = i_epis_documentation
           AND vsr.flg_state <> pk_alert_constant.g_flg_status_c;
        FOR i IN 1 .. tbl_id_vital_sign_read.count
        LOOP
            IF NOT pk_vital_sign_core.cancel_epis_vs_read(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_episode            => i_id_episode,
                                                          i_id_vital_sign_read => tbl_id_vital_sign_read(i),
                                                          i_id_cancel_reason   => i_id_cancel_reason,
                                                          i_notes              => i_notes,
                                                          o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CANCEL_EPIS_VITAL_SIGN',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END cancel_epis_vital_sign;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_touch_option_ti;
/
