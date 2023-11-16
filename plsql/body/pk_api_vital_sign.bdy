/*-- Last Change Revision: $Rev: 2016487 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-06-09 18:15:44 +0100 (qui, 09 jun 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_vital_sign IS

    --
    -- PRIVATE SUBTYPES
    -- 

    SUBTYPE obj_name IS VARCHAR2(32 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);

    --
    -- PRIVATE CONSTANTS
    -- 
    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    /* CAN'T TOUCH THIS */
    -- Package info
    c_package_owner CONSTANT obj_name := 'ALERT';
    c_package_name  CONSTANT obj_name := pk_alertlog.who_am_i();

    g_vs_gcs_eye    CONSTANT vital_sign.id_vital_sign%TYPE := 12;
    g_vs_gcs_motor  CONSTANT vital_sign.id_vital_sign%TYPE := 13;
    g_vs_gcs_verbal CONSTANT vital_sign.id_vital_sign%TYPE := 14;

    --
    -- PUBLIC FUNCTIONS
    -- 

    /************************************************************************************************************
    * Return all notes from all vital signs of one episode (API for INTER_ALERT)
    *
    * @param i_vs_parent        ID for blood pressure relation for vital sign 
    * @param i_episode          episode id             
    * @param i_institution      institution id             
    * @param i_software         software id             
    *
    * @return                   description
    *
    * @author                   Rui Spratley
    * @version                  2.4.3
    * @since                    2008/05/23 
    ************************************************************************************************************/
    FUNCTION intf_get_vital_sign_val_bp
    (
        i_vs_parent   IN vital_sign_relation.id_vital_sign_parent%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        c_function_name CONSTANT obj_name := 'INTF_GET_VITAL_SIGN_VAL_BP';
        l_dbg_msg debug_msg;
    
        l_decimal_symbol sys_config.value%TYPE;
    
    BEGIN
        l_dbg_msg := 'get the decimal symbol to use';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package, sub_object_name => c_function_name);
        l_decimal_symbol := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                    i_prof_inst => i_institution,
                                                    i_prof_soft => i_software);
    
        l_dbg_msg := 'call pk_vital_sign.get_vital_sign_val_bp';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package, sub_object_name => c_function_name);
        RETURN pk_vital_sign.get_vital_sign_val_bp(i_vs_parent      => i_vs_parent,
                                                   i_episode        => i_episode,
                                                   i_decimal_symbol => l_decimal_symbol);
    
    END intf_get_vital_sign_val_bp;

    /************************************************************************************************************
    * This function writes a set of vital sign reads at once.
    * The arrays are read in the same order according to each line of I_VS_ID.
    *
    * @param i_lang                   Language ID
    * @param i_episode                Episode ID
    * @param i_prof                   Professional, Software and Institution id's
    * @param i_pat                    Patient id
    * @param i_vs_id                  Array of VS id's
    * @param i_vs_val                 Array of VS values
    * @param i_id_monit               Monitorization id
    * @param i_unit_meas              Unit Measures id's
    * @param i_vs_scales_elements     VS Scales Elements id's
    * @param i_notes                  Notes
    * @param i_prof_cat_type          Professional Category
    * @param o_vital_sign_read        Array of vital sign read IDs
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Paulo Fonseca
    * @version                        2.5.0
    * @since                          2010/01/18
    ************************************************************************************************************/
    FUNCTION intf_set_epis_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_id_monit           IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_notes              IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        o_vital_sign_read    OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'INTF_SET_EPIS_VITAL_SIGN';
        l_dbg_msg     debug_msg;
        l_dt_registry VARCHAR2(20 CHAR);
    BEGIN
        l_dbg_msg := 'call pk_vital_sign.set_epis_vital_sign';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package, sub_object_name => c_function_name);
        RETURN pk_vital_sign.set_epis_vital_sign(i_lang               => i_lang,
                                                 i_episode            => i_episode,
                                                 i_prof               => i_prof,
                                                 i_pat                => i_pat,
                                                 i_vs_id              => i_vs_id,
                                                 i_vs_val             => i_vs_val,
                                                 i_id_monit           => i_id_monit,
                                                 i_unit_meas          => i_unit_meas,
                                                 i_vs_scales_elements => i_vs_scales_elements,
                                                 i_notes              => i_notes,
                                                 i_prof_cat_type      => i_prof_cat_type,
                                                 i_dt_vs_read         => NULL,
                                                 i_epis_triage        => NULL,
                                                 i_unit_meas_convert  => i_unit_meas,
                                                 o_vital_sign_read    => o_vital_sign_read,
                                                 o_dt_registry        => l_dt_registry,
                                                 o_error              => o_error);
    
    END intf_set_epis_vital_sign;

    /************************************************************************************************************
    * This function cancel a VS read
    *
    * @param i_lang                   Language ID
    * @param i_episode                Episode ID
    * @param i_vs                     VS ID
    * @param i_prof                   Professional, Software and Institution id's
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Paulo Fonseca
    * @version                        2.5.0
    * @since                          2010/01/20
    ************************************************************************************************************/
    FUNCTION intf_cancel_epis_vs_read
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN vital_sign_read.id_episode%TYPE,
        i_vs            IN vital_sign_read.id_vital_sign_read%TYPE,
        i_prof          IN profissional,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE DEFAULT pk_cancel_reason.c_reason_other,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'INTF_CANCEL_EPIS_VS_READ';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'call pk_vital_sign_core.cancel_epis_vs_read';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package, sub_object_name => c_function_name);
        RETURN pk_vital_sign_core.cancel_epis_vs_read(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_episode            => i_episode,
                                                      i_id_vital_sign_read => i_vs,
                                                      i_id_cancel_reason   => i_cancel_reason,
                                                      o_error              => o_error);
    
    END intf_cancel_epis_vs_read;

    ---------------------------------------------------------------------------------------------------------------

    /**********************************************************************************************
    * Get Vital Signs Records for a visit between a date interval
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_visit                  Visit id
    * @param        i_id_vs                  Vital sign ids to return
    * @param        i_dt_begin               Date from which start to return records
    * @param        i_dt_end                 Date by which to end returning records
    * @param        o_vs                     Vital signs records output cursor
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.4
    * @since        26-Nov-2010
    **********************************************************************************************/
    FUNCTION get_visit_vital_signs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_id_vs    IN table_number,
        i_dt_begin IN VARCHAR2 DEFAULT NULL,
        i_dt_end   IN VARCHAR2 DEFAULT NULL,
        i_dt_type  IN VARCHAR2 DEFAULT 'M',
        o_vs       OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_VISIT_VITAL_SIGNS';
        l_dbg_msg debug_msg;
    
        l_dt_begin vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_dt_end   vital_sign_read.dt_vital_sign_read_tstz%TYPE;
    
    BEGIN
        l_dbg_msg := 'convert string dates into timestamps';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package, sub_object_name => c_function_name);
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_timestamp => i_dt_begin,
                                                    i_timezone  => NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_timestamp => i_dt_end,
                                                    i_timezone  => NULL);
    
        l_dbg_msg := 'get vital signs records for a visit between a date interval';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package, sub_object_name => c_function_name);
        OPEN o_vs FOR
            SELECT vsr.id_vital_sign_read,
                   vsr.id_patient,
                   vsr.id_episode,
                   vsr.id_prof_read,
                   pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) AS dt_vital_sign_read_tstz,
                   pk_date_utils.date_send_tsz(i_lang, vsr.dt_registry, i_prof) AS dt_registry,
                   vsr.id_vital_sign,
                   pk_vital_sign.get_vs_desc(i_lang, vsr.id_vital_sign) AS vs_desc,
                   vsr.flg_state,
                   vsr.value AS VALUE,
                   vsr.id_unit_measure AS id_unit_measure,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, vsr.id_unit_measure) AS um_desc,
                   vsr.id_vital_sign_desc,
                   (SELECT vsd.value
                      FROM vital_sign_desc vsd
                     WHERE vsr.id_vital_sign_desc = vsd.id_vital_sign_desc) AS vsd_value,
                   pk_vital_sign.get_vsd_desc(i_lang, vsr.id_vital_sign_desc, vsr.id_patient) AS vsd_desc,
                   vsr.id_vs_scales_element,
                   vsse.value AS vsse_value,
                   vsse.id_unit_measure AS vsse_id_unit_measure,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, vsse.id_unit_measure) AS vsse_um_desc,
                   vsse.id_vital_sign_scales,
                   (SELECT pk_translation.get_translation(i_lang, vss.code_vital_sign_scales)
                      FROM vital_sign_scales vss
                     WHERE vsse.id_vital_sign_scales = vss.id_vital_sign_scales) AS vss_desc
              FROM vital_sign_read vsr
             INNER JOIN episode e
                ON vsr.id_episode = e.id_episode
              LEFT JOIN vital_sign_scales_element vsse
                ON vsr.id_vs_scales_element = vsse.id_vs_scales_element
             WHERE vsr.flg_state != pk_alert_constant.g_cancelled
               AND e.flg_status != pk_alert_constant.g_cancelled
               AND e.id_visit = i_visit
               AND EXISTS
             (SELECT 1
                      FROM TABLE(i_id_vs) t
                     WHERE t.column_value = vsr.id_vital_sign)
               AND ((i_dt_type = 'M' AND vsr.dt_vital_sign_read_tstz >= nvl(l_dt_begin, vsr.dt_vital_sign_read_tstz) AND
                   vsr.dt_vital_sign_read_tstz <= nvl(l_dt_end, vsr.dt_vital_sign_read_tstz)) OR
                   (i_dt_type = 'R' AND vsr.dt_registry >= nvl(l_dt_begin, vsr.dt_registry) AND
                   vsr.dt_registry <= nvl(l_dt_end, vsr.dt_registry)))
            
            UNION ALL
            SELECT vsr.id_vital_sign_read id_vital_sign_read,
                   vsr.id_patient,
                   vsr.id_episode,
                   vsr.id_prof_read,
                   pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) AS dt_vital_sign_read_tstz,
                   pk_date_utils.date_send_tsz(i_lang, vsr.dt_registry, i_prof) AS dt_registry,
                   vr.id_vital_sign_parent id_vital_sign,
                   pk_vital_sign.get_vs_desc(i_lang, vr.id_vital_sign_parent) AS vs_desc,
                   vsr.flg_state,
                   NULL VALUE,
                   NULL id_unit_measure,
                   NULL um_desc,
                   NULL id_vital_sign_desc,
                   (SELECT to_char(pk_vital_sign.get_glasgowtotal_value(vr.id_vital_sign_parent,
                                                                        vsr.id_patient,
                                                                        vsr.id_episode,
                                                                        vsr.dt_vital_sign_read_tstz))
                      FROM dual) vsd_value,
                   (SELECT to_char(pk_vital_sign.get_glasgowtotal_value(vr.id_vital_sign_parent,
                                                                        vsr.id_patient,
                                                                        vsr.id_episode,
                                                                        vsr.dt_vital_sign_read_tstz))
                      FROM dual) vsd_desc,
                   NULL id_vs_scales_element,
                   NULL vsse_value,
                   NULL vsse_id_unit_measure,
                   NULL vsse_um_desc,
                   NULL id_vital_sign_scales,
                   NULL vss_desc
              FROM vital_sign_read vsr
              JOIN episode e
                ON vsr.id_episode = e.id_episode
              JOIN vital_sign_relation vr
                ON vsr.id_vital_sign = vr.id_vital_sign_detail
               AND vr.relation_domain IN (pk_alert_constant.g_vs_rel_sum)
               AND vr.flg_available = pk_alert_constant.g_yes
               AND vr.rank = (SELECT MIN(v.rank)
                                FROM vital_sign_relation v
                               WHERE vr.id_vital_sign_parent = v.id_vital_sign_parent
                                 AND vr.flg_available = pk_alert_constant.g_yes
                                 AND vr.relation_domain != pk_alert_constant.g_vs_rel_percentile)
              JOIN vital_sign vs
                ON vr.id_vital_sign_parent = vs.id_vital_sign
             WHERE vsr.flg_state != pk_alert_constant.g_cancelled
               AND e.flg_status != pk_alert_constant.g_cancelled
               AND e.id_visit = i_visit
               AND EXISTS
             (SELECT 1
                      FROM TABLE(i_id_vs) t
                     WHERE t.column_value = vsr.id_vital_sign)
               AND ((i_dt_type = 'M' AND vsr.dt_vital_sign_read_tstz >= nvl(l_dt_begin, vsr.dt_vital_sign_read_tstz) AND
                   vsr.dt_vital_sign_read_tstz <= nvl(l_dt_end, vsr.dt_vital_sign_read_tstz)) OR
                   (i_dt_type = 'R' AND vsr.dt_registry >= nvl(l_dt_begin, vsr.dt_registry) AND
                   vsr.dt_registry <= nvl(l_dt_end, vsr.dt_registry)));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_vs);
            RETURN FALSE;
        
    END get_visit_vital_signs;

    /**********************************************************************************************
    * Set Vital Signs Records
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_episode                Episode id
    * @param        i_id_vs                  Vital signs ids
    * @param        i_value_vs               Vital signs values
    * @param        i_id_um                  Unit measure ids
    * @param        i_multichoice_vs         Multichoices ids
    * @param        i_scales_elem_vs         Scale elements ids
    * @param        i_dt_vs                  Vital signs monitorization dates
    * @param        o_id_vsr                 Vital signs records ids
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.4
    * @since        26-Nov-2010
    **********************************************************************************************/
    FUNCTION set_episode_vital_signs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN vital_sign_read.id_episode%TYPE,
        i_id_vs          IN table_number,
        i_value_vs       IN table_number,
        i_id_um          IN table_number,
        i_multichoice_vs IN table_number,
        i_scales_elem_vs IN table_number,
        i_dt_vs          IN table_varchar,
        o_id_vsr         OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_EPISODE_VITAL_SIGNS';
        l_dbg_msg debug_msg;
    
        l_patient       vital_sign_read.id_patient%TYPE;
        l_flg_fill_type vital_sign.flg_fill_type%TYPE;
        l_value_vs      table_number := table_number();
        l_prof_cat_type category.flg_type%TYPE;
        l_dt_registry   VARCHAR2(20 CHAR);
    BEGIN
        l_dbg_msg := 'get patient id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package, sub_object_name => c_function_name);
        SELECT e.id_patient
          INTO l_patient
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        l_dbg_msg := '...';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package, sub_object_name => c_function_name);
        l_value_vs.extend(i_id_vs.count());
        FOR idx IN 1 .. i_id_vs.count()
        LOOP
            SELECT vs.flg_fill_type
              INTO l_flg_fill_type
              FROM vital_sign vs
             WHERE vs.id_vital_sign = i_id_vs(idx);
        
            l_value_vs(idx) := CASE l_flg_fill_type
                                   WHEN pk_alert_constant.g_vs_ft_multichoice THEN
                                    i_multichoice_vs(idx)
                                   ELSE
                                    i_value_vs(idx)
                               END;
        END LOOP;
    
        l_dbg_msg := 'call pk_tools.get_prof_cat';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package, sub_object_name => c_function_name);
        l_prof_cat_type := pk_tools.get_prof_cat(i_prof => i_prof);
    
        l_dbg_msg := 'call pk_vital_sign.set_epis_vital_sign';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package, sub_object_name => c_function_name);
        IF NOT pk_vital_sign.set_epis_vital_sign(i_lang               => i_lang,
                                                 i_episode            => i_episode,
                                                 i_prof               => i_prof,
                                                 i_pat                => l_patient,
                                                 i_vs_id              => i_id_vs,
                                                 i_vs_val             => l_value_vs,
                                                 i_id_monit           => NULL,
                                                 i_unit_meas          => i_id_um,
                                                 i_vs_scales_elements => i_scales_elem_vs,
                                                 i_notes              => NULL,
                                                 i_prof_cat_type      => l_prof_cat_type,
                                                 i_dt_vs_read         => i_dt_vs,
                                                 i_epis_triage        => NULL,
                                                 i_unit_meas_convert  => i_id_um,
                                                 o_vital_sign_read    => o_id_vsr,
                                                 o_dt_registry        => l_dt_registry,
                                                 o_error              => o_error)
        THEN
            pk_utils.undo_changes;
            o_id_vsr := table_number();
            RETURN FALSE;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            o_id_vsr := table_number();
            RETURN FALSE;
        
    END set_episode_vital_signs;

    /**********************************************************************************************
    * Cancel Vital Signs Records
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_vital_sign_read        Vital Sign records ids
    * @param        i_cancel_reason          Id cancel reason
    * @param        i_notes                  Cancel notes
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.4
    * @since        26-Nov-2010
    **********************************************************************************************/

    FUNCTION cancel_vital_signs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_vital_sign_read IN table_number,
        i_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE DEFAULT pk_cancel_reason.c_reason_other,
        i_notes           IN vital_sign_read.notes_cancel%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'CANCEL_VITAL_SIGNS';
        l_dbg_msg debug_msg;
    
        l_episode vital_sign_read.id_episode%TYPE;
    
    BEGIN
        l_dbg_msg := 'cancel vital signs records';
        --   pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        FOR idx IN 1 .. i_vital_sign_read.count()
        LOOP
            l_dbg_msg := 'get episode id';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            SELECT vsr.id_episode
              INTO l_episode
              FROM vital_sign_read vsr
             WHERE vsr.id_vital_sign_read = i_vital_sign_read(idx);
        
            l_dbg_msg := 'call pk_vital_sign_core.cancel_epis_vs_read';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            IF NOT pk_vital_sign_core.cancel_epis_vs_read(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_episode            => l_episode,
                                                          i_id_vital_sign_read => i_vital_sign_read(idx),
                                                          i_id_cancel_reason   => i_cancel_reason,
                                                          i_notes              => i_notes,
                                                          o_error              => o_error)
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END cancel_vital_signs;

    /**
    * Get info about vital sign record
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_vital_sign_read        Vital Sign record ID
    * @param   i_dt_registry            Timestamp to check if the vital sign was edited after that date (Optional)
    * @param   o_rec_api_vs_read        Information about vital sign record
    * @param   o_error                  Error information
    *
    * @return  A formatted string representing the vital sign read  
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/11/2011
    */
    FUNCTION get_vital_sign_read
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_dt_registry     IN vital_sign_read.dt_registry%TYPE := NULL,
        o_rec_api_vs_read OUT t_rec_api_vs_read,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_vital_sign_read';
        l_flg_edit      VARCHAR2(1 CHAR);
        l_prof_edit     vital_sign_read.id_prof_read%TYPE;
        l_dt_edit       vital_sign_read.dt_registry%TYPE;
        l_value         vital_sign_read_hist.value%TYPE;
        l_id_vital_sign vital_sign_read.id_vital_sign%TYPE;
    BEGIN
    
        l_flg_edit  := pk_alert_constant.g_no;
        l_prof_edit := NULL;
        l_dt_edit   := NULL;
    
        IF i_dt_registry IS NOT NULL
        THEN
            -- Check if the vital sign read was edited after an especific date (ie. date when this vs was associated to a entry for documentation)
            BEGIN
                SELECT pk_alert_constant.g_yes flg_edit, vsr.id_prof_read, vsr.dt_registry, vsr.id_vital_sign
                  INTO l_flg_edit, l_prof_edit, l_dt_edit, l_id_vital_sign
                  FROM vital_sign_read vsr
                 WHERE vsr.id_vital_sign_read = i_vital_sign_read
                   AND vsr.dt_registry > i_dt_registry
                   AND EXISTS (SELECT 1
                          FROM vital_sign_read_hist vsrh
                         WHERE vsrh.id_vital_sign_read = vsr.id_vital_sign_read);
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            BEGIN
                SELECT vsrh.value
                  INTO l_value
                  FROM vital_sign_read_hist vsrh
                 WHERE vsrh.id_vital_sign_read = i_vital_sign_read
                   AND to_char(vsrh.dt_registry, 'dd-mm-yyyy hh24:mi:ss') =
                       to_char(i_dt_registry, 'dd-mm-yyyy hh24:mi:ss');
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
        END IF;
    
        SELECT vsr.id_vital_sign
          INTO l_id_vital_sign
          FROM vital_sign_read vsr
         WHERE vsr.id_vital_sign_read = i_vital_sign_read;
    
        IF l_id_vital_sign NOT IN (g_vs_gcs_eye, g_vs_gcs_motor, g_vs_gcs_verbal)
        THEN
            l_id_vital_sign := nvl(pk_vital_sign.get_vs_parent(l_id_vital_sign), l_id_vital_sign);
        END IF;
    
        SELECT vsr.id_vital_sign_read,
               vsr.id_episode,
               vsr.id_vital_sign,
               vsr.dt_vital_sign_read_tstz,
               pk_vital_sign.get_vs_desc(i_lang, l_id_vital_sign, pk_alert_constant.get_no) AS desc_vital_sign,
               pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_patient            => vsr.id_patient,
                                          i_episode            => vsr.id_episode,
                                          i_vital_sign         => l_id_vital_sign,
                                          i_value              => decode(l_flg_edit,
                                                                         pk_alert_constant.g_yes,
                                                                         nvl(l_value, vsr.value),
                                                                         vsr.value),
                                          i_vs_unit_measure    => vsr.id_unit_measure,
                                          i_vital_sign_desc    => vsr.id_vital_sign_desc,
                                          i_vs_scales_element  => vsr.id_vs_scales_element,
                                          i_dt_vital_sign_read => vsr.dt_vital_sign_read_tstz,
                                          i_ea_unit_measure    => vsr.id_unit_measure,
                                          i_dt_registry        => vsr.dt_registry) AS desc_value,
               pk_vital_sign_core.get_um_desc(i_lang,
                                              vsr.id_unit_measure,
                                              pk_vital_sign.get_vs_scale(vsr.id_vs_scales_element)) AS desc_unit_measure,
               vsr.id_prof_read,
               vsr.flg_state,
               vsr.id_prof_cancel,
               vsr.dt_cancel_tstz,
               l_flg_edit flg_edit,
               l_prof_edit id_prof_edit,
               l_dt_edit dt_edit
          INTO o_rec_api_vs_read
          FROM vital_sign_read vsr
         WHERE vsr.id_vital_sign_read = i_vital_sign_read;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_vital_sign_read;

    FUNCTION get_flg_clinical_dt
    (
        i_hash_vital_sign IN table_table_varchar,
        i_id_vital_sign   IN NUMBER
    ) RETURN VARCHAR2 IS
        l_flg_clinical_dt VARCHAR2(1 CHAR);
    BEGIN
        FOR i IN 1 .. i_hash_vital_sign.count
        LOOP
            IF i_hash_vital_sign(i) (1) = i_id_vital_sign
            THEN
                l_flg_clinical_dt := i_hash_vital_sign(i) (2);
            END IF;
        END LOOP;
        --  l_flg_clinical_dt := i_hash_vital_sign(i_id_vital_sign);
        RETURN l_flg_clinical_dt;
    END get_flg_clinical_dt;
    /**************************************************************************
    * Get latest reading for a list vital sign identifiers and a patient      *
    * identifier                                                              *
    *                                                                         *
    * @param   i_lang                   Professional preferred language       *
    * @param   i_prof                   Professional identification and its   *
    *                                   context (institution and software)    *
    * @param   i_patient                Patient ID                            *
    * @param   i_episode                Episode ID                            *
    * @param   i_flg_view               Flg View Mode                         *
    * @param   i_dt_threshold           Threshold Date                        *
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
    FUNCTION get_latest_vital_sign_read
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_episode                  IN episode.id_episode%TYPE,
        i_flg_view                 IN vs_soft_inst.flg_view%TYPE,
        i_dt_threshold             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_tbl_vs                   IN table_number,
        i_tbl_aux_vs               IN table_number DEFAULT NULL,
        i_flg_show_previous_values IN VARCHAR2 DEFAULT NULL,
        i_dt_begin                 IN VARCHAR2 DEFAULT NULL,
        i_dt_end                   IN VARCHAR2 DEFAULT NULL,
        i_hash_vital_sign          IN table_table_varchar,
        i_flg_show_relations       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_vs_info                  OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_latest_vital_sign_read';
    
        l_dt_end       VARCHAR2(4000);
        l_dt_ini       VARCHAR2(4000);
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_confs       PLS_INTEGER;
        l_software    vs_soft_inst.id_software%TYPE := pk_alert_constant.g_soft_all;
        l_institution vs_soft_inst.id_institution%TYPE := pk_alert_constant.g_inst_all;
    
        l_error t_error_out;
        l_exception EXCEPTION;
        l_id_visit visit.id_visit%TYPE := pk_episode.get_id_visit(i_episode => i_episode);
    
        l_tbl       table_number := table_number();
        l_tbl2      table_number := table_number(NULL);
        l_tbl_count NUMBER(12);
    
    BEGIN
        l_sysdate_tstz := current_timestamp;
    
        g_error := 'COUNT VITAL SIGN CONFS FOR SOFTWARE AND INSTITUTION i_dt_begin:' || i_dt_begin || 'i_dt_end:' ||
                   i_dt_end;
        pk_alertlog.log_info(g_error);
    
        SELECT COUNT(1)
          INTO l_confs
          FROM vs_soft_inst vsi
         INNER JOIN vital_sign vs
            ON vsi.id_vital_sign = vs.id_vital_sign
           AND vs.flg_available = pk_alert_constant.g_yes
         WHERE vsi.id_software = i_prof.software
           AND vsi.id_institution = i_prof.institution
           AND (i_flg_view IS NULL OR vsi.flg_view = i_flg_view);
    
        IF l_confs > 0
        THEN
            l_software    := i_prof.software;
            l_institution := i_prof.institution;
        END IF;
    
        g_error := 'CALCULATE DATE LIMITS';
        IF NOT pk_vital_sign.get_vs_date_limits(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_patient           => i_patient,
                                                i_episode           => i_episode,
                                                i_id_monitorization => NULL,
                                                o_dt_ini            => l_dt_ini,
                                                o_dt_end            => l_dt_end,
                                                o_error             => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        l_tbl       := l_tbl MULTISET UNION DISTINCT i_tbl_aux_vs;
        l_tbl       := l_tbl MULTISET except DISTINCT l_tbl2;
        l_tbl_count := l_tbl.count;
    
        g_error := 'GET CURSOR O_VS_INFO';
        OPEN o_vs_info FOR
            SELECT vsh.id_vital_sign,
                   nvl(vsr.val_min, vsh.val_min) val_min,
                   nvl(vsr.val_max, vsh.val_max) val_max,
                   vsh.rank,
                   vsh.rank_conc,
                   CASE
                        WHEN vsh.relation_type = pk_alert_constant.g_vs_rel_sum THEN
                         NULL
                        ELSE
                         vsh.id_vital_sign_parent
                    END id_vital_sign_parent,
                   vsh.relation_type,
                   vsh.format_num,
                   vsh.flg_fill_type,
                   vsh.flg_sum,
                   vsh.name_vs,
                   nvl(vsr.desc_unit_measure, vsh.desc_unit_measure) desc_unit_measure,
                   nvl(vsr.id_unit_measure, vsh.id_unit_measure) id_unit_measure,
                   vsh.dt_server,
                   vsh.flg_view,
                   vsh.id_institution,
                   vsh.id_software,
                   rank_vs,
                   vsr.value_desc VALUE,
                   (SELECT pk_translation.get_translation(i_lang, vss.code_vital_sign_scales_short)
                      FROM vital_sign_scales vss
                     WHERE vss.id_vital_sign_scales = vsr.vital_sign_scale) pain_descr,
                   (SELECT pk_translation.get_translation(i_lang, vs.code_vs_short_desc)
                      FROM vital_sign vs
                     WHERE vs.id_vital_sign = vsr.id_vital_sign) short_name_vs,
                   vsr.dt_vital_sign_read_send short_dt_read,
                   vsr.desc_prof prof_read,
                   vsr.id_vital_sign_read,
                   l_dt_ini dt_vs_init,
                   vsr.vital_sign_scale id_vital_sign_scale,
                   get_flg_clinical_dt(i_hash_vital_sign, vsh.id_vital_sign) flg_clinical_dt_block
              FROM (SELECT /*+ opt_estimate (table vs rows=10) */
                     vs.*,
                     row_number() over(PARTITION BY vs.id_vital_sign ORDER BY decode(vs.flg_view, pk_alert_constant.g_vs_view_v2, 0, 1)) rank_vs
                      FROM TABLE(pk_vital_sign.tf_get_vs_header(i_lang,
                                                                i_prof,
                                                                NULL,
                                                                l_institution,
                                                                l_software,
                                                                l_dt_end,
                                                                i_patient)) vs
                     WHERE (i_tbl_vs IS NULL OR
                           vs.id_vital_sign IN (SELECT /*+ opt_estimate (table t rows=10) */
                                                  column_value
                                                   FROM TABLE(i_tbl_vs) t))) vsh
              LEFT JOIN (SELECT aux.rn,
                                aux.dt_vs_read_tstz    dt_vital_sign_read,
                                aux.dt_vital_sign_read dt_vital_sign_read_send,
                                aux.id_vital_sign,
                                aux.vital_sign_scale,
                                aux.id_vital_sign_read,
                                aux.desc_prof,
                                aux.dt_registry,
                                aux.value_desc,
                                aux.id_unit_measure,
                                aux.desc_unit_measure,
                                aux.val_max,
                                aux.val_min
                           FROM (SELECT /*+ opt_estimate (table tf rows=10) */
                                  row_number() over(PARTITION BY tf.id_vital_sign /*, tf.vital_sign_scale*/ ORDER BY tf.dt_vital_sign_read DESC NULLS LAST, tf.dt_registry DESC NULLS LAST) rn,
                                  tf.*
                                   FROM TABLE(pk_vital_sign_core.tf_vital_sign_grid(i_lang                     => i_lang,
                                                                                    i_prof                     => i_prof,
                                                                                    i_flg_view                 => pk_alert_constant.g_vs_view_v2,
                                                                                    i_flg_screen               => pk_vital_sign_core.g_flg_screen_d,
                                                                                    i_all_details              => pk_alert_constant.g_no,
                                                                                    i_scope                    => l_id_visit,
                                                                                    i_scope_type               => pk_alert_constant.g_scope_type_visit,
                                                                                    i_interval                 => NULL,
                                                                                    i_dt_begin                 => i_dt_begin,
                                                                                    i_dt_end                   => i_dt_end,
                                                                                    i_flg_show_previous_values => i_flg_show_previous_values,
                                                                                    i_flg_show_relations       => i_flg_show_relations)) tf
                                  WHERE (l_tbl_count = 0 OR
                                        tf.vital_sign_scale IN (SELECT /*+ opt_estimate (table t1 rows=10) */
                                                                  column_value
                                                                   FROM TABLE(l_tbl) t1))) aux
                          WHERE aux.rn = 1) vsr
                ON (vsr.id_vital_sign = vsh.id_vital_sign AND
                   nvl(vsr.dt_vital_sign_read, l_sysdate_tstz) >=
                   nvl(i_dt_threshold, nvl(vsr.dt_vital_sign_read, l_sysdate_tstz)))
             WHERE vsh.rank_vs = 1;
    
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
    END get_latest_vital_sign_read;

    /**************************************************************************
    * Get configuration for list vital sign identifiers                       *
    *                                                                         *
    * @param   i_lang                   Professional preferred language       *
    * @param   i_prof                   Professional identification and its   *
    *                                   context (institution and software)    *
    * @param   i_flg_view               Flg View Mode                         *
    * @param   i_dt_end                 Episode end date                      *
    * @param   i_tbl_vs                 Vital Sign list ID                    *
    * @param   o_vs_header              Information about vital sign structure*
    * @param   o_error                  Error information                     *
    *                                                                         *
    * @return  Boolean                                                        *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 2.6.1                                                          *
    * @since   21/3/2011                                                      *
    **************************************************************************/
    FUNCTION get_vs_header
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_view  IN vs_soft_inst.flg_view%TYPE,
        i_dt_end    IN st_varchar2_200,
        i_tbl_vs    IN table_number,
        o_vs_header OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_vs_header';
    
        l_confs       PLS_INTEGER;
        l_software    vs_soft_inst.id_software%TYPE := pk_alert_constant.g_soft_all;
        l_institution vs_soft_inst.id_institution%TYPE := pk_alert_constant.g_inst_all;
    
    BEGIN
    
        g_error := 'COUNT VITAL SIGN CONFS FOR SOFTWARE AND INSTITUTION';
        SELECT COUNT(1)
          INTO l_confs
          FROM vs_soft_inst vsi
         INNER JOIN vital_sign vs
            ON vsi.id_vital_sign = vs.id_vital_sign
           AND vs.flg_available = pk_alert_constant.g_yes
         WHERE vsi.id_software = i_prof.software
           AND vsi.id_institution = i_prof.institution
           AND (i_flg_view IS NULL OR vsi.flg_view = i_flg_view);
    
        IF l_confs > 0
        THEN
            l_software    := i_prof.software;
            l_institution := i_prof.institution;
        END IF;
    
        g_error := 'OPEN o_vs_header';
        OPEN o_vs_header FOR
            SELECT *
              FROM (SELECT vs.*,
                           row_number() over(PARTITION BY vs.id_vital_sign ORDER BY decode(vs.flg_view, pk_alert_constant.g_vs_view_v2, 0, 1)) rank_vs
                      FROM TABLE(pk_vital_sign.tf_get_vs_header(i_lang,
                                                                i_prof,
                                                                i_flg_view,
                                                                l_institution,
                                                                l_software,
                                                                i_dt_end,
                                                                NULL)) vs
                     WHERE (i_tbl_vs IS NULL OR
                           vs.id_vital_sign IN (SELECT /*+ cardinality(c 10) */
                                                  column_value
                                                   FROM TABLE(i_tbl_vs))))
             WHERE rank_vs = 1;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            pk_types.open_cursor_if_closed(o_vs_header);
            RETURN FALSE;
    END get_vs_header;

    /**************************************************************************
    * Get information for a list vital sign reads identifiers and a patient   *
    * identifier                                                              *
    *                                                                         *
    * @param   i_lang                   Professional preferred language       *
    * @param   i_prof                   Professional identification and its   *
    *                                   context (institution and software)    *
    * @param   i_patient                Patient ID                            *
    * @param   i_episode                Episode ID                            *
    * @param   i_tbl_vsr                Vital Sign Read list ID               *
    * @param   o_vs_info                Information about vital sign records  *
    * @param   o_error                  Error information                     *
    *                                                                         *
    * @return  Boolean                                                        *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 2.6.1                                                          *
    * @since   21/3/2011                                                      *
    **************************************************************************/
    FUNCTION get_vital_sign_read_info
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_tbl_vsr IN table_varchar,
        o_vs_info OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_vital_sign_read_info';
    
        l_dt_end VARCHAR2(4000);
        l_dummy  VARCHAR2(4000);
    
        l_confs       PLS_INTEGER;
        l_software    vs_soft_inst.id_software%TYPE := pk_alert_constant.g_soft_all;
        l_institution vs_soft_inst.id_institution%TYPE := pk_alert_constant.g_inst_all;
    
        l_error t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'COUNT VITAL SIGN CONFS FOR SOFTWARE AND INSTITUTION';
        SELECT COUNT(1)
          INTO l_confs
          FROM vs_soft_inst vsi
         INNER JOIN vital_sign vs
            ON vsi.id_vital_sign = vs.id_vital_sign
           AND vs.flg_available = pk_alert_constant.g_yes
         WHERE vsi.id_software = i_prof.software
           AND vsi.id_institution = i_prof.institution;
    
        IF l_confs > 0
        THEN
            l_software    := i_prof.software;
            l_institution := i_prof.institution;
        END IF;
    
        g_error := 'CALCULATE DATE LIMITS';
        IF NOT pk_vital_sign.get_vs_date_limits(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_patient           => i_patient,
                                                i_episode           => i_episode,
                                                i_id_monitorization => NULL,
                                                o_dt_ini            => l_dummy,
                                                o_dt_end            => l_dt_end,
                                                o_error             => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET CURSOR O_VS_INFO';
        OPEN o_vs_info FOR
            SELECT vsh.*,
                   vsr.value,
                   vsr.pain_descr,
                   vsr.short_name_vs,
                   vsr.short_dt_read,
                   vsr.prof_read,
                   vsr.id_vital_sign_read,
                   vsr.flg_state
              FROM (SELECT vs.*,
                           row_number() over(PARTITION BY vs.id_vital_sign ORDER BY decode(vs.flg_view, pk_alert_constant.g_vs_view_v2, 0, 1)) rank_vs
                      FROM TABLE(pk_vital_sign.tf_get_vs_header(i_lang,
                                                                i_prof,
                                                                NULL,
                                                                l_institution,
                                                                l_software,
                                                                l_dt_end,
                                                                i_patient)) vs) vsh
             INNER JOIN (SELECT t.id_vital_sign_read,
                                t.vsr2,
                                t.id_vs,
                                pk_vital_sign.get_vs_desc(i_lang, t.id_vs) short_name_vs,
                                pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_patient            => t.id_patient,
                                                           i_episode            => t.id_episode,
                                                           i_vital_sign         => t.id_vs,
                                                           i_value              => t.value,
                                                           i_vs_unit_measure    => t.id_unit_measure,
                                                           i_vital_sign_desc    => t.id_vital_sign_desc,
                                                           i_vs_scales_element  => t.id_vs_scales_element,
                                                           i_dt_vital_sign_read => t.dt_vital_sign_read_tstz,
                                                           i_ea_unit_measure    => t.id_unit_measure,
                                                           i_dt_registry        => t.dt_registry) VALUE,
                                pk_vital_sign_core.get_um_desc(i_lang,
                                                               t.id_unit_measure,
                                                               (SELECT vsse.id_vital_sign_scales
                                                                  FROM vital_sign_scales_element vsse
                                                                 WHERE vsse.id_vs_scales_element = t.id_vs_scales_element)),
                                t.tree_lvl,
                                t.vs_rank,
                                t.flg_state,
                                pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_read) AS prof_read,
                                pk_date_utils.date_send_tsz(i_lang,
                                                            t.dt_vital_sign_read_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) AS short_dt_read,
                                pk_vital_sign.get_vs_scale_shortdesc(i_lang, t.id_vs_scales_element) AS pain_descr
                           FROM (SELECT pk_vital_sign.get_vs_parent(nvl(vsr_f.id_vital_sign, vsr.id_vital_sign)) id_vs_parent,
                                        nvl(vsr_f.id_vital_sign, vsr.id_vital_sign) id_vs,
                                        pk_vital_sign.get_vs_relation_domain(nvl(pk_vital_sign.get_vs_parent(vsr_f.id_vital_sign),
                                                                                 vsr_f.id_vital_sign)) vs_relation_domain,
                                        nvl(vsr.id_patient, vsr_f.id_patient) id_patient,
                                        nvl(vsr.id_episode, vsr_f.id_episode) id_episode,
                                        vsr.value,
                                        nvl(vsr.id_unit_measure, vsr_f.id_unit_measure) id_unit_measure,
                                        nvl(vsr.id_vital_sign_desc, vsr_f.id_vital_sign_desc) id_vital_sign_desc,
                                        nvl(vsr.id_vs_scales_element, vsr_f.id_vs_scales_element) id_vs_scales_element,
                                        vsr_f.dt_vital_sign_read_tstz,
                                        pk_vital_sign.get_vs_um_inst(nvl(vsr_f.id_vital_sign, vsr.id_vital_sign),
                                                                     i_prof.institution,
                                                                     i_prof.software) vs_um_inst,
                                        vsr_f.tree_lvl,
                                        vsr_f.id_vital_sign_read,
                                        vsr.id_vital_sign_read vsr2,
                                        vsr_f.id_prof_read,
                                        vsr_f.flg_state,
                                        (SELECT rank
                                           FROM vital_sign
                                          WHERE id_vital_sign = nvl(vsr_f.id_vital_sign, vsr.id_vital_sign)) vs_rank,
                                        vsr_f.dt_registry
                                   FROM (SELECT vs_full.dt_vital_sign_read_tstz,
                                                vs_full.id_vital_sign,
                                                vs_full.tree_lvl,
                                                vs_full.id_vital_sign_parent,
                                                vs_full.id_patient,
                                                vs_full.id_episode,
                                                vs_full.id_unit_measure,
                                                vs_full.id_vital_sign_desc,
                                                vs_full.id_vs_scales_element,
                                                vs_full.id_vital_sign_read,
                                                vs_full.id_prof_read,
                                                vs_full.flg_state,
                                                vs_full.dt_registry
                                           FROM (SELECT vsr_d.dt_vital_sign_read_tstz,
                                                        nvl(vsr_d.id_vital_sign, vrel.id_vital_sign) id_vital_sign,
                                                        nvl(vrel.tree_lvl, 1) tree_lvl,
                                                        CASE nvl(vrel.tree_lvl, 1)
                                                            WHEN 1 THEN
                                                             nvl(vsr_d.id_vital_sign, vrel.id_vital_sign)
                                                            ELSE
                                                             vrel.id_vital_sign_parent
                                                        END id_vital_sign_parent,
                                                        vsr_d.id_patient,
                                                        vsr_d.id_episode,
                                                        vsr_d.id_unit_measure,
                                                        vsr_d.id_vital_sign_desc,
                                                        vsr_d.id_vs_scales_element,
                                                        vsr_d.id_vital_sign_read,
                                                        vsr_d.id_prof_read,
                                                        vsr_d.flg_state,
                                                        vsr_d.dt_registry
                                                   FROM (SELECT id_vital_sign,
                                                                dt_vital_sign_read_tstz,
                                                                id_patient,
                                                                id_episode,
                                                                VALUE,
                                                                id_unit_measure,
                                                                id_vital_sign_desc,
                                                                id_vs_scales_element,
                                                                id_vital_sign_read,
                                                                id_prof_read,
                                                                flg_state,
                                                                dt_registry
                                                           FROM vital_sign_read
                                                          WHERE id_vital_sign_read IN
                                                                (SELECT /*+ opt_estimate(table t rows=10)*/
                                                                  t.column_value
                                                                   FROM TABLE(i_tbl_vsr) t)) vsr_d
                                                   FULL OUTER JOIN (SELECT vrel_aux.id_vital_sign_detail id_vital_sign,
                                                                          LEVEL                         tree_lvl,
                                                                          vrel_aux.id_vital_sign_parent
                                                                     FROM vital_sign_relation vrel_aux
                                                                   CONNECT BY PRIOR vrel_aux.id_vital_sign_detail =
                                                                               vrel_aux.id_vital_sign_parent
                                                                    START WITH vrel_aux.id_vital_sign_detail IN
                                                                               (SELECT vrel_par.id_vital_sign_parent
                                                                                  FROM vital_sign_relation vrel_par
                                                                                 WHERE vrel_par.relation_domain !=
                                                                                       pk_alert_constant.g_vs_rel_percentile
                                                                                   AND vrel_par.id_vital_sign_detail IN
                                                                                       (SELECT id_vital_sign
                                                                                          FROM vital_sign_read
                                                                                         WHERE id_vital_sign_read IN
                                                                                               (SELECT /*+ opt_estimate(table t rows=10)*/
                                                                                                 t.column_value
                                                                                                  FROM TABLE(i_tbl_vsr) t)))) vrel
                                                     ON vrel.id_vital_sign = vsr_d.id_vital_sign) vs_full) vsr_f
                                   LEFT JOIN vital_sign_read vsr
                                     ON vsr.id_vital_sign = vsr_f.id_vital_sign
                                    AND vsr.dt_registry = vsr_f.dt_registry
                                    AND vsr.id_vital_sign_read = vsr_f.id_vital_sign_read
                                    AND vsr.id_patient = vsr_f.id_patient
                                    AND vsr.id_episode = vsr_f.id_episode) t) vsr
                ON vsr.id_vs = vsh.id_vital_sign
             WHERE rank_vs = 1;
    
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
    END get_vital_sign_read_info;

    /**
    * Check if vital signs were edited/cancelled after a specific timestamp
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   i_vsr_list               List of saved vital sign measurement (id_vital_sign_read)
    * @param   i_dt_creation            Timestamp to check if measurements were edited after this date
    * @param   o_changed                Returns if some measurement in input list was edited/cancelled after input timestamp
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
    FUNCTION check_vsr_changed
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_vsr_list         IN table_number,
        i_dt_creation      IN epis_documentation.dt_creation_tstz%TYPE,
        o_ref_info_changed OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'check_vsr_changed';
        l_changed         VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_changed_entries NUMBER(24);
    BEGIN
    
        SELECT COUNT(*)
          INTO l_changed_entries
          FROM vital_sign_read vsr
         WHERE vsr.id_vital_sign_read IN (SELECT /*+ opt_estimate(table t rows=2)*/
                                           t.column_value
                                            FROM TABLE(i_vsr_list) t)
           AND ((vsr.dt_registry > i_dt_creation AND EXISTS
                (SELECT 1
                    FROM vital_sign_read_hist vsrh
                   WHERE vsrh.id_vital_sign_read IN (SELECT /*+ opt_estimate(table t rows=2)*/
                                                      t.column_value
                                                       FROM TABLE(i_vsr_list) t))) OR
               vsr.flg_state = pk_alert_constant.g_cancelled);
    
        IF l_changed_entries > 0
        THEN
            l_changed := pk_alert_constant.g_yes;
        END IF;
        o_ref_info_changed := l_changed;
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
    END check_vsr_changed;
    --
    /********************************************************************************************
    *  Get current state of vital signs and monitorization for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author   Anna Kurowska                 
    * @version  2.7.1                  
    * @since    07-Mar-2017                         
    **********************************************************************************************/
    FUNCTION get_vwr_vs_monit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'get_vwr_vs_monit';
        l_episodes      table_number := table_number();
        l_scope         NUMBER;
        l_cnt_ongoing   NUMBER(24);
        l_cnt_completed NUMBER(24);
        l_flg_checklist VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => c_package_name, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
        -- count all ongoing items - monitorization
        SELECT COUNT(*) cnt
          INTO l_cnt_ongoing
          FROM monitorization m
         WHERE m.id_episode IN (SELECT *
                                  FROM TABLE(l_episodes))
           AND m.flg_status IN (pk_alert_constant.g_monitor_vs_exec, pk_alert_constant.g_monitor_vs_pend);
        IF (l_cnt_ongoing > 0)
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_ongoing;
        ELSE
            -- count all completed monitorization
            SELECT COUNT(*) cnt
              INTO l_cnt_completed
              FROM monitorization m
             WHERE m.id_episode IN (SELECT *
                                      FROM TABLE(l_episodes))
               AND m.flg_status = pk_alert_constant.g_monitor_vs_fini;
            IF (l_cnt_completed > 0)
            THEN
                l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
            ELSE
                -- count registered vital signs
                CASE i_scope_type
                    WHEN pk_alert_constant.g_scope_type_patient THEN
                        l_scope := i_patient;
                    WHEN pk_alert_constant.g_scope_type_visit THEN
                        SELECT e.id_visit
                          INTO l_scope
                          FROM episode e
                         WHERE e.id_episode = i_episode;
                    ELSE
                        l_scope := i_episode;
                END CASE;
                SELECT COUNT(*) cnt
                  INTO l_cnt_completed
                  FROM TABLE(pk_vital_sign_core.get_vital_sign_records(i_lang       => i_lang,
                                                                       i_prof       => i_prof,
                                                                       i_flg_view   => pk_alert_constant.g_vs_view_v2,
                                                                       i_scope      => l_scope,
                                                                       i_scope_type => i_scope_type)) vs
                 WHERE vs.flg_state <> pk_alert_constant.g_cancelled;
                IF (l_cnt_completed > 0)
                THEN
                    l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
                ELSE
                    l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
                END IF;
            END IF;
        END IF;
        RETURN l_flg_checklist;
    END get_vwr_vs_monit;

    /********************************************************************************************
    *  Set/Update or Cancel a vital sign according to CCH standards 
    *             
    * @param    i_lang                Language ID
    * @param    i_prof                Logged professional structure
    * @param    i_id_episode          Episode ID
    * @param    i_id_vs               Array if ids of vital signs
    * @param    i_vs_val              Array of values for the vital signs
    * @param    i_id_unit_meas        Array of unit measures for the vital signs    
    * @param    i_vs_scales_elements  Array of scale elements (Multi-choice vital signs)
    * @param    i_notes               Array of notes for vital signs
    * @param    i_dt_vs               Date of vital signs
    * @param    i_flg_stat            Action to be performed (N-New / E-Edit / C-Cancel)
    * @param    i_cancel_reason       ID of cancel reason
    * @param    i_cancel_notes        Cancel notes                                   
    * @return BOOLEAN
    * 
    * @author   Diogo Oliveira                 
    * @version  2.7.1.5                  
    * @since    16-Oct-2017                         
    **********************************************************************************************/
    FUNCTION set_vital_sign_intf
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_vs                   IN table_number,
        i_vs_val                  IN table_number,
        i_id_unit_meas            IN table_number,
        i_vs_scales_elements      IN table_number,
        i_notes                   IN table_varchar,
        i_dt_vs                   IN table_varchar,
        i_vs_attributes           IN table_table_number,
        i_vs_attributes_free_text IN table_table_clob,
        i_flg_stat                IN VARCHAR2,
        i_cancel_reason           IN table_number,
        i_cancel_notes            IN table_varchar,
        o_vital_sign_read         OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_vs_read      vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_vs_read         table_number;
        l_patient         patient.id_patient%TYPE;
        l_dt_registry     VARCHAR2(1000);
        l_val_high        table_number := table_number();
        l_val_low         table_number := table_number();
        l_vital_sign_read table_number := table_number();
        l_default_um      vs_soft_inst.id_unit_measure%TYPE := NULL;
    
    BEGIN
    
        IF i_flg_stat IN (pk_vital_sign.g_new_content_n, pk_vital_sign.c_edit_type_edit)
        THEN
        
            FOR i IN i_id_vs.first .. i_id_vs.last
            LOOP
            
                SELECT e.id_patient
                  INTO l_patient
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            
                l_val_high.extend;
                l_val_high(i) := NULL;
            
                l_val_low.extend;
                l_val_low(i) := NULL;
            
                ---- IF i_id_unit_meas is null => Check default um for insitution/software
                IF i_id_unit_meas(i) IS NULL
                   AND i_vs_scales_elements(i) IS NULL
                THEN
                    BEGIN
                        SELECT DISTINCT vsi.id_unit_measure
                          INTO l_default_um
                          FROM vs_soft_inst vsi
                         WHERE vsi.id_vital_sign = i_id_vs(i)
                           AND vsi.id_software = i_prof.software
                           AND vsi.id_institution = i_prof.institution;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_default_um := NULL;
                    END;
                END IF;
            
                IF NOT pk_vital_sign.set_epis_vital_sign(i_lang               => i_lang,
                                                    i_episode            => i_id_episode,
                                                    i_prof               => i_prof,
                                                    i_pat                => l_patient,
                                                    i_vs_id              => table_number(i_id_vs(i)),
                                                    i_vs_val             => table_number(i_vs_val(i)),
                                                    i_id_monit           => NULL,
                                                    i_unit_meas          => CASE
                                                                                WHEN i_id_unit_meas(i) IS NULL
                                                                                     AND i_vs_scales_elements(i) IS NULL THEN
                                                                                 table_number(l_default_um)
                                                                                ELSE
                                                                                 table_number(i_id_unit_meas(i))
                                                                            END,
                                                    i_vs_scales_elements => table_number(i_vs_scales_elements(i)),
                                                    i_notes              => i_notes(i),
                                                    i_prof_cat_type      => NULL,
                                                    i_dt_vs_read         => table_varchar(i_dt_vs(i)),
                                                    i_epis_triage        => NULL,
                                                    i_unit_meas_convert  => table_number(NULL),
                                                    i_tbtb_attribute     => i_vs_attributes,
                                                    i_tbtb_free_text     => i_vs_attributes_free_text,
                                                    i_id_edit_reason     => table_number(NULL),
                                                    i_notes_edit         => table_clob(NULL),
                                                    i_vs_val_high        => l_val_high,
                                                    i_vs_val_low         => l_val_low,
                                                    o_vital_sign_read    => o_vital_sign_read,
                                                    o_dt_registry        => l_dt_registry,
                                                    o_error              => o_error)
                THEN
                    RETURN FALSE;
                ELSE
                    l_vital_sign_read.extend;
                    l_vital_sign_read(i) := o_vital_sign_read(1);
                END IF;
            
                l_default_um := NULL;
            
            END LOOP;
        
            o_vital_sign_read := l_vital_sign_read;
        
        ELSIF i_flg_stat = pk_vital_sign.c_edit_type_cancel
        THEN
            FOR i IN i_id_vs.first .. i_id_vs.last
            LOOP
            
                IF i_dt_vs(i) IS NOT NULL
                THEN
                
                    l_dt_vs_read := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_timestamp => i_dt_vs(i),
                                                                  i_timezone  => NULL);
                
                    l_dt_vs_read := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                     i_timestamp => l_dt_vs_read,
                                                                     i_format    => 'MI');
                
                    SELECT vsr.id_vital_sign_read
                      BULK COLLECT
                      INTO l_vs_read
                      FROM vital_sign_read vsr
                     WHERE vsr.id_vital_sign = i_id_vs(i)
                       AND vsr.id_episode = i_id_episode
                       AND vsr.flg_state = 'A'
                       AND vsr.dt_vital_sign_read_tstz IN (l_dt_vs_read);
                
                    IF NOT cancel_vital_signs(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_vital_sign_read => l_vs_read,
                                              i_cancel_reason   => i_cancel_reason(i),
                                              i_notes           => i_cancel_notes(i),
                                              o_error           => o_error)
                    THEN
                    
                        RETURN FALSE;
                    
                    END IF;
                
                END IF;
            
            END LOOP;
        ELSE
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END set_vital_sign_intf;

-- INITIALIZATION SECTION
-- 

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(g_owner, g_package);
    /* Log init */
    pk_alertlog.log_init(g_package);

END pk_api_vital_sign;
/
