/*-- Last Change Revision: $Rev: 2000535 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2021-11-05 10:30:06 +0000 (sex, 05 nov 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_vital_sign_pdms IS

    /* CAN'T TOUCH THIS */
    g_error     VARCHAR2(1000 CHAR);
    g_owner     VARCHAR2(30 CHAR);
    g_package   VARCHAR2(30 CHAR);
    g_function  VARCHAR2(128 CHAR);
    g_exception EXCEPTION;

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
    * @author       Rui Teixeira
    * @version      2.6.2.1
    * @since        2012-03-02
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
    BEGIN
    
        g_function := 'get_visit_vital_signs';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_vital_sign.get_visit_vital_signs(i_lang,
                                                       i_prof,
                                                       i_visit,
                                                       i_id_vs,
                                                       i_dt_begin,
                                                       i_dt_end,
                                                       i_dt_type,
                                                       o_vs,
                                                       o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
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
    * @param        i_validate_rep           Y - Does not insert if the hour has an register
    * @param        o_id_vsr                 Vital signs records ids
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.2.1
    * @since        2012-03-02
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
        i_validate_rep   IN VARCHAR,
        o_id_vsr         OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN set_episode_vital_signs(i_lang           => i_lang,
                                       i_prof           => i_prof,
                                       i_episode        => i_episode,
                                       i_id_vs          => i_id_vs,
                                       i_value_vs       => i_value_vs,
                                       i_id_um          => i_id_um,
                                       i_multichoice_vs => i_multichoice_vs,
                                       i_scales_elem_vs => i_scales_elem_vs,
                                       i_dt_vs          => i_dt_vs,
                                       i_validate_rep   => i_validate_rep,
                                       i_tbtb_attribute => NULL,
                                       i_tbtb_free_text => NULL,
                                       o_id_vsr         => o_id_vsr,
                                       o_error          => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_episode_vital_signs;

    /**********************************************************************************************
    * Set Vital Signs Records with Attributes
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
    * @param        i_validate_rep           Y - Does not insert if the hour has an register
    * @param        i_tbtb_attribute         List of attributes selected
    * @param        i_tbtb_free_text         List of free text for each attribute
    * @param        o_id_vsr                 Vital signs records ids
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Sergio Pereira
    * @version      2.6.3.10
    * @since        2014-01-20
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
        i_validate_rep   IN VARCHAR,
        i_tbtb_attribute IN table_table_number,
        i_tbtb_free_text IN table_table_clob,
        o_id_vsr         OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_allow         VARCHAR(1);
        l_count         NUMBER(10);
        l_exception     EXCEPTION;
        l_patient       vital_sign_read.id_patient%TYPE;
        l_flg_fill_type vital_sign.flg_fill_type%TYPE;
        l_value_vs      table_number := table_number();
        l_prof_cat_type category.flg_type%TYPE;
        PRAGMA EXCEPTION_INIT(l_exception, -900001);
        l_dt_registry VARCHAR2(20 CHAR);
    BEGIN
        l_allow    := 'Y';
        g_function := 'set_episode_vital_signs';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'get patient id';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        SELECT e.id_patient
          INTO l_patient
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        g_error := '...';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
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
    
        g_error := 'call pk_tools.get_prof_cat';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        l_prof_cat_type := pk_tools.get_prof_cat(i_prof => i_prof);
    
        -- Check if a new register exist on existing register
        IF i_validate_rep = 'Y'
        THEN
            FOR idx IN 1 .. i_id_vs.count()
            LOOP
                IF l_allow = 'Y'
                THEN
                    SELECT COUNT(1)
                      INTO l_count
                      FROM vital_sign_read vsr
                     WHERE vsr.id_episode = i_episode
                       AND vsr.dt_vital_sign_read_tstz =
                           pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_vs(idx), NULL)
                       AND vsr.id_vital_sign = i_id_vs(idx)
                       AND vsr.flg_state != pk_alert_constant.g_cancelled
                       AND rownum = 1;
                    IF l_count > 0
                    THEN
                        l_allow := 'N';
                    END IF;
                END IF;
            END LOOP;
        END IF;
        IF l_allow = 'Y'
        THEN
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
                                                     i_tbtb_attribute     => i_tbtb_attribute,
                                                     i_tbtb_free_text     => i_tbtb_free_text,
                                                     o_vital_sign_read    => o_id_vsr,
                                                     o_dt_registry        => l_dt_registry,
                                                     o_error              => o_error)
            THEN
            
                RAISE l_exception;
                RETURN FALSE;
            END IF;
        ELSE
            RAISE l_exception;
            RETURN FALSE;
        END IF;
    
        FOR i IN 1 .. o_id_vsr.count
        LOOP
        
            SELECT COUNT(1)
              INTO l_count
              FROM vital_sign_read vsr
              JOIN vital_sign_relation vrpar
                ON vsr.id_vital_sign = vrpar.id_vital_sign_detail
               AND vrpar.relation_domain = pk_alert_constant.g_vs_rel_sum
               AND vrpar.flg_available = pk_alert_constant.g_yes
               AND vrpar.rank = (SELECT MIN(v.rank)
                                   FROM vital_sign_relation v
                                  WHERE vrpar.id_vital_sign_parent = v.id_vital_sign_parent
                                    AND vrpar.flg_available = pk_alert_constant.g_yes)
             WHERE vsr.id_vital_sign_read = o_id_vsr(i);
        
            IF l_count > 0
            THEN
                o_id_vsr.extend(1);
                o_id_vsr(o_id_vsr.count) := o_id_vsr(i);
                EXIT;
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
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_episode_vital_signs;

    /**********************************************************************************************
    * Edit Vital Signs Records with Attributes
    *
    * @param        i_lang                    Language id
    * @param        i_prof                    Professional, software and institution ids
    * @param        id_vital_sign_read        Vital Sign reading ID
    * @param        i_value                   Vital sign value
    * @param        id_unit_measure           Measure unit ID
    * @param        dt_vital_sign_read_tstz   Date when vital sign was read
    * @param        i_tbtb_attribute          List of attributes selected
    * @param        i_tbtb_free_text          List of free text for each attribute
    * @param        o_error                   Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Sergio Pereira
    * @version      2.6.3.10
    * @since        2014-01-24
    **********************************************************************************************/
    FUNCTION edit_vital_signs
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN table_number,
        i_value                   IN table_number,
        i_id_unit_measure         IN table_number,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_tbtb_attribute          IN table_table_number,
        i_tbtb_free_text          IN table_table_clob,
        o_id_vsr                  OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count NUMBER(10);
    BEGIN
        o_id_vsr := i_id_vital_sign_read;
        g_error  := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        IF NOT pk_vital_sign.edit_vital_sign(i_lang                    => i_lang,
                                             i_prof                    => i_prof,
                                             i_id_vital_sign_read      => i_id_vital_sign_read,
                                             i_value                   => i_value,
                                             i_id_unit_measure         => i_id_unit_measure,
                                             i_dt_vital_sign_read_tstz => i_dt_vital_sign_read_tstz,
                                             i_id_unit_measure_sel     => NULL,
                                             i_tbtb_attribute          => i_tbtb_attribute,
                                             i_tbtb_free_text          => i_tbtb_free_text,
                                             i_id_edit_reason          => NULL,
                                             i_notes_edit              => NULL,
                                             i_update_pdms             => FALSE,
                                             o_error                   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        FOR i IN 1 .. o_id_vsr.count
        LOOP
        
            SELECT COUNT(1)
              INTO l_count
              FROM vital_sign_read vsr
              JOIN vital_sign_relation vrpar
                ON vsr.id_vital_sign = vrpar.id_vital_sign_detail
               AND vrpar.relation_domain = pk_alert_constant.g_vs_rel_sum
               AND vrpar.flg_available = pk_alert_constant.g_yes
               AND vrpar.rank = (SELECT MIN(v.rank)
                                   FROM vital_sign_relation v
                                  WHERE vrpar.id_vital_sign_parent = v.id_vital_sign_parent
                                    AND vrpar.flg_available = pk_alert_constant.g_yes)
             WHERE vsr.id_vital_sign_read = o_id_vsr(i);
        
            IF l_count > 0
            THEN
                o_id_vsr.extend(1);
                o_id_vsr(o_id_vsr.count) := o_id_vsr(i);
                EXIT;
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
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END edit_vital_signs;

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
    * @author       Rui Teixeira
    * @version      2.6.2.1
    * @since        2012-03-02
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
    BEGIN
    
        g_function := 'cancel_vital_signs';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_vital_sign.cancel_vital_signs(i_lang,
                                                    i_prof,
                                                    i_vital_sign_read,
                                                    i_cancel_reason,
                                                    i_notes,
                                                    o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_vital_signs;

    /**********************************************************************************************
    * Gets the PFH vital signs PDMS View
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient identifier
    * @param        o_vital_s                Patient vital signs conf
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.2
    * @since        2012-11-19
    **********************************************************************************************/

    FUNCTION get_pdms_module_vital_signs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_vital_s OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_age vital_sign_unit_measure.age_min%TYPE;
    
    BEGIN
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
    
        g_function := 'get_pdms_module_vital_signs';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        OPEN o_vital_s FOR
            SELECT vs.*, /* pvs.val_min, pvs.val_max, */
                   (SELECT vsr.id_vital_sign_detail
                      FROM vital_sign_relation vsr
                     WHERE vsr.id_vital_sign_parent = vs.id_vital_sign
                       AND vsr.relation_domain = g_relation_blood_pressure
                       AND vsr.rank = g_relation_min_rank) id_vital_sign_min,
                   (SELECT vsr.id_vital_sign_detail
                      FROM vital_sign_relation vsr
                     WHERE vsr.id_vital_sign_parent = vs.id_vital_sign
                       AND vsr.relation_domain = g_relation_blood_pressure
                       AND vsr.rank = g_relation_max_rank) id_vital_sign_max,
                   (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => vs.id_vital_sign,
                                                               i_id_unit_measure => (SELECT pk_vital_sign.get_vs_um_inst(vs.id_vital_sign,
                                                                                                                         i_prof.institution,
                                                                                                                         i_prof.software)
                                                                                       FROM dual),
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => l_age)
                      FROM dual) unit_val_min,
                   (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => vs.id_vital_sign,
                                                               i_id_unit_measure => (SELECT pk_vital_sign.get_vs_um_inst(vs.id_vital_sign,
                                                                                                                         i_prof.institution,
                                                                                                                         i_prof.software)
                                                                                       FROM dual),
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => l_age)
                      FROM dual) unit_val_max,
                   lvs.flg_fill_type,
                   vss.id_vital_sign_scales id_vital_sign_scales,
                   vss.internal_name scale_name,
                   pk_translation.get_translation(i_lang, vss.code_vital_sign_scales_short) scale_short_desc,
                   pk_translation.get_translation(i_lang, vss.code_vital_sign_scales) scale_desc,
                   (SELECT vsse.id_unit_measure
                      FROM vital_sign_scales_element vsse
                     WHERE vsse.id_vital_sign_scales = vss.id_vital_sign_scales
                       AND rownum = 1) id_scale_unit_measure,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          (SELECT um.code_unit_measure
                                                             FROM unit_measure um
                                                            WHERE id_unit_measure IN
                                                                  (SELECT vsse.id_unit_measure
                                                                     FROM vital_sign_scales_element vsse
                                                                    WHERE vsse.id_vital_sign_scales =
                                                                          vss.id_vital_sign_scales
                                                                      AND rownum = 1)))
                      FROM dual) desc_scale_unit_measure,
                   (SELECT vsse.min_value
                      FROM vital_sign_scales_element vsse
                     WHERE vsse.id_vital_sign_scales = vss.id_vital_sign_scales
                       AND rownum = 1) min_scale_value,
                   (SELECT vsse.max_value
                      FROM vital_sign_scales_element vsse
                     WHERE vsse.id_vital_sign_scales = vss.id_vital_sign_scales
                       AND rownum = 1) max_scale_value
              FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang, i_prof, i_patient, NULL, NULL)) vs
              JOIN vital_sign lvs
                ON lvs.id_vital_sign = vs.id_vital_sign
              LEFT JOIN vital_sign_scales vss
                ON (lvs.flg_fill_type = g_vital_sign_type_pain AND vss.id_vital_sign = g_vital_sign_main_pain)
             WHERE vs.flg_view IN (g_view_1, g_view_2, g_view_3)
               AND (vss.id_vital_sign_scales IS NULL OR vss.id_vital_sign_scales = 0 OR EXISTS
                    (SELECT 1
                       FROM (SELECT vssa.id_vital_sign_scales,
                                    row_number() over(PARTITION BY vssa.id_vital_sign_scales ORDER BY vssa.id_institution DESC NULLS LAST, vssa.id_software DESC NULLS LAST) rn
                               FROM vital_sign_scales_access vssa
                              WHERE vssa.id_institution IN (i_prof.institution, 0)
                                AND vssa.id_software IN (i_prof.software, 0)
                                AND vssa.flg_available = pk_alert_constant.g_yes)
                      WHERE id_vital_sign_scales = vss.id_vital_sign_scales
                        AND rn = 1))
             ORDER BY vs.flg_view, vs.rank, vs.id_vital_sign;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pdms_module_vital_signs;

    /**********************************************************************************************
      * Gets the PFH vital signs by identifiers
      *
      * @param        i_lang                   Language id
      * @param        i_prof                   Professional, software and institution ids
      * @param        i_vs_ids                 Vital signs identifiers
      * @param        o_vital_s                Patient vital signs conf
      * @param        o_error                  Error information
      *
      * @return       TRUE if sucess, FALSE otherwise
      *                        
      * @author       Miguel Gomes
      * @version      2.6.3.12
      * @since        2014-03-17
    **********************************************************************************************/

    FUNCTION get_pdms_module_vs_by_ids
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_vs_ids  IN table_number,
        o_vital_s OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_age vital_sign_unit_measure.age_min%TYPE;
    BEGIN
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
    
        g_function := 'get_pdms_module_vs_by_ids';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        OPEN o_vital_s FOR
            SELECT vs.*, /* pvs.val_min, pvs.val_max, */
                   (SELECT vsr.id_vital_sign_detail
                      FROM vital_sign_relation vsr
                     WHERE vsr.id_vital_sign_parent = vs.id_vital_sign
                       AND vsr.relation_domain = g_relation_blood_pressure
                       AND vsr.rank = g_relation_min_rank) id_vital_sign_min,
                   (SELECT vsr.id_vital_sign_detail
                      FROM vital_sign_relation vsr
                     WHERE vsr.id_vital_sign_parent = vs.id_vital_sign
                       AND vsr.relation_domain = g_relation_blood_pressure
                       AND vsr.rank = g_relation_max_rank) id_vital_sign_max,
                   (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => vs.id_vital_sign,
                                                               i_id_unit_measure => (SELECT pk_vital_sign.get_vs_um_inst(vs.id_vital_sign,
                                                                                                                         i_prof.institution,
                                                                                                                         i_prof.software)
                                                                                       FROM dual),
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => l_age)
                      FROM dual) unit_val_min,
                   (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => vs.id_vital_sign,
                                                               i_id_unit_measure => (SELECT pk_vital_sign.get_vs_um_inst(vs.id_vital_sign,
                                                                                                                         i_prof.institution,
                                                                                                                         i_prof.software)
                                                                                       FROM dual),
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => l_age)
                      FROM dual) unit_val_max,
                   lvs.flg_fill_type,
                   vss.id_vital_sign_scales id_vital_sign_scales,
                   vss.internal_name scale_name,
                   pk_translation.get_translation(i_lang, vss.code_vital_sign_scales_short) scale_short_desc,
                   pk_translation.get_translation(i_lang, vss.code_vital_sign_scales) scale_desc,
                   (SELECT vsse.id_unit_measure
                      FROM vital_sign_scales_element vsse
                     WHERE vsse.id_vital_sign_scales = vss.id_vital_sign_scales
                       AND rownum = 1) id_scale_unit_measure,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          (SELECT um.code_unit_measure
                                                             FROM unit_measure um
                                                            WHERE id_unit_measure IN
                                                                  (SELECT vsse.id_unit_measure
                                                                     FROM vital_sign_scales_element vsse
                                                                    WHERE vsse.id_vital_sign_scales =
                                                                          vss.id_vital_sign_scales
                                                                      AND rownum = 1)))
                      FROM dual) desc_scale_unit_measure,
                   (SELECT vsse.min_value
                      FROM vital_sign_scales_element vsse
                     WHERE vsse.id_vital_sign_scales = vss.id_vital_sign_scales
                       AND rownum = 1) min_scale_value,
                   (SELECT vsse.max_value
                      FROM vital_sign_scales_element vsse
                     WHERE vsse.id_vital_sign_scales = vss.id_vital_sign_scales
                       AND rownum = 1) max_scale_value
              FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang, i_prof, i_patient, NULL, NULL)) vs
              JOIN vital_sign lvs
                ON lvs.id_vital_sign = vs.id_vital_sign
              LEFT JOIN vital_sign_scales vss
                ON (lvs.flg_fill_type = g_vital_sign_type_pain AND vss.id_vital_sign = g_vital_sign_main_pain)
             WHERE vs.flg_view IN (g_view_1, g_view_2, g_view_3, g_view_p, g_view_pg, g_view_rg)
               AND (vss.id_vital_sign_scales IS NULL OR vss.id_vital_sign_scales = 0 OR EXISTS
                    (SELECT 1
                       FROM (SELECT vssa.id_vital_sign_scales,
                                    row_number() over(PARTITION BY vssa.id_vital_sign_scales ORDER BY vssa.id_institution DESC NULLS LAST, vssa.id_software DESC NULLS LAST) rn
                               FROM vital_sign_scales_access vssa
                              WHERE vssa.id_institution IN (i_prof.institution, 0)
                                AND vssa.id_software IN (i_prof.software, 0)
                                AND vssa.flg_available = pk_alert_constant.g_yes)
                      WHERE id_vital_sign_scales = vss.id_vital_sign_scales
                        AND rn = 1))
               AND vs.id_vital_sign IN (SELECT *
                                          FROM TABLE(i_vs_ids))
             ORDER BY vs.flg_view, vs.rank, vs.id_vital_sign;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pdms_module_vs_by_ids;

    /**********************************************************************************************
    * Gets the all PFH vital signs views configuration to PDMS
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        o_vital_s                Patient vital signs conf
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.2
    * @since        2012-11-19
    **********************************************************************************************/

    FUNCTION get_all_pdms_views
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_vital_s OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_0 profissional;
    
    BEGIN
    
        g_function := 'get_pdms_module_vital_signs';
    
        l_prof_0 := profissional(i_prof.id, i_prof.institution, 0);
    
        OPEN o_vital_s FOR
            SELECT vs2.id_vital_sign, vs2.name_vs, vs2.id_unit_measure, MIN(vs2.rank) AS rank, vs2.flg_view
              FROM (SELECT vs.*
                      FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang, l_prof_0, NULL, NULL, NULL)) vs
                    UNION
                    SELECT vs.*
                      FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang,
                                                                       profissional(i_prof.id, i_prof.institution, 1),
                                                                       NULL,
                                                                       NULL,
                                                                       NULL)) vs
                    UNION
                    SELECT vs.*
                      FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang,
                                                                       profissional(i_prof.id, i_prof.institution, 2),
                                                                       NULL,
                                                                       NULL,
                                                                       NULL)) vs
                    UNION
                    SELECT vs.*
                      FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang,
                                                                       profissional(i_prof.id, i_prof.institution, 3),
                                                                       NULL,
                                                                       NULL,
                                                                       NULL)) vs
                    UNION
                    SELECT vs.*
                      FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang,
                                                                       profissional(i_prof.id, i_prof.institution, 8),
                                                                       NULL,
                                                                       NULL,
                                                                       NULL)) vs
                    UNION
                    SELECT vs.*
                      FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang,
                                                                       profissional(i_prof.id, i_prof.institution, 11),
                                                                       NULL,
                                                                       NULL,
                                                                       NULL)) vs
                    UNION
                    SELECT vs.*
                      FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang,
                                                                       profissional(i_prof.id, i_prof.institution, 12),
                                                                       NULL,
                                                                       NULL,
                                                                       NULL)) vs) vs2
             GROUP BY vs2.id_vital_sign, vs2.name_vs, vs2.id_unit_measure, vs2.flg_view
             ORDER BY vs2.flg_view, rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_all_pdms_views;

    /**********************************************************************************************
    * Gets the PFH vital signs relation of blood presure parameters to PDMS
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vs                  Children vital signs
    * @param        o_vs_parent              Vital signs
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.2.1
    * @since        2012-03-02
    **********************************************************************************************/

    FUNCTION get_vital_signs_bp_parents
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_vs     IN table_number DEFAULT NULL,
        o_vs_parent OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_function := 'get_vital_signs_bp_parents';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        OPEN o_vs_parent FOR
            SELECT vsr.id_vital_sign_parent, vsr.id_vital_sign_detail, rank
              FROM vital_sign_relation vsr
             WHERE vsr.relation_domain = g_relation_blood_pressure
               AND vsr.id_vital_sign_detail IN (SELECT *
                                                  FROM TABLE(i_id_vs));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_vital_signs_bp_parents;

    /**********************************************************************************************
    * Gets the the most adquate vital sign to register
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient identifier
    * @param        i_vital_signs            Matrix with vital signs
    * @param        o_selected               Selected vital signs from matrix.
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.2.1
    * @since        2012-03-02
    **********************************************************************************************/

    FUNCTION get_pdms_vital_sign_to_reg
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_vital_signs IN table_table_number,
        o_selected    OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_total_vital_signs table_number := NEW table_number();
        l_tmp               table_number;
        l_actual            NUMBER;
        l_vital_s_table     t_coll_vs_views;
        l_vital_s           t_vs_views;
        l_vital_s_cursor    pk_types.cursor_type;
        l_id_vs             NUMBER;
        l_view              NUMBER;
        l_continue          NUMBER;
        l_view_number       NUMBER;
    BEGIN
        g_function := 'get_pdms_vital_sign_to_reg';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        l_actual := 1;
        -- build the complete list of vital_signs
        FOR i IN 1 .. i_vital_signs.count
        LOOP
            l_tmp := i_vital_signs(i);
            FOR i IN 1 .. l_tmp.count
            LOOP
                l_total_vital_signs.extend;
                l_total_vital_signs(l_actual) := l_tmp(i);
                l_actual := l_actual + 1;
            END LOOP;
        END LOOP;
    
        OPEN l_vital_s_cursor FOR
            SELECT v.id_vital_sign, v.flg_view
              FROM (SELECT vs.id_vital_sign,
                           vs.flg_view,
                           row_number() over(PARTITION BY vs.id_vital_sign ORDER BY(CASE
                               WHEN flg_view = g_view_1 THEN
                                1
                               WHEN flg_view = g_view_2 THEN
                                2
                               WHEN flg_view = g_view_3 THEN
                                3
                               ELSE
                                4
                           END)) rn
                      FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang, i_prof, i_patient, NULL, NULL)) vs
                     WHERE vs.id_vital_sign IN (SELECT *
                                                  FROM TABLE(l_total_vital_signs))) v
             WHERE rn = 1;
    
        FETCH l_vital_s_cursor BULK COLLECT
            INTO l_vital_s_table;
        CLOSE l_vital_s_cursor;
    
        l_actual   := 1;
        o_selected := NEW table_number();
    
        dbms_output.put_line('SELECTED : ' || to_char(l_vital_s_table.count));
        dbms_output.put_line('IN : ' || to_char(i_vital_signs.count));
    
        FOR i IN 1 .. i_vital_signs.count
        LOOP
            l_tmp   := i_vital_signs(i);
            l_id_vs := 0;
            l_view  := 99; -- The number should be grater then the amount of considered views
            FOR j IN 1 .. l_vital_s_table.count
            LOOP
                l_vital_s  := l_vital_s_table(j);
                l_continue := 0;
                FOR k IN 1 .. l_tmp.count
                LOOP
                    IF l_vital_s.id_vital_sign = l_tmp(k)
                    THEN
                        l_continue := 1;
                    END IF;
                END LOOP;
            
                IF l_continue = 1
                THEN
                    IF l_vital_s.flg_view = g_view_1
                    THEN
                        l_view_number := 1;
                    ELSIF l_vital_s.flg_view = g_view_2
                    THEN
                        l_view_number := 2;
                    ELSIF l_vital_s.flg_view = g_view_3
                    THEN
                        l_view_number := 3;
                    ELSE
                        l_view_number := 4;
                    END IF;
                
                    IF l_view > l_view_number
                    THEN
                        l_id_vs := l_vital_s.id_vital_sign;
                        l_view  := l_view_number;
                    END IF;
                END IF;
            END LOOP;
            --            select id_vital_sign into l_id_vs from table(l_vital_s_table) t where t.id_vital_sign in (select * from table(l_tmp))
            --                   and rownum = 1 order by case when flg_view = g_view_1 then 1
            --                                                                        when flg_view = g_view_2 then 2
            --                                                                        when flg_view = g_view_3 then 3
            --                                                                        else 4 end asc;
            o_selected.extend;
            o_selected(l_actual) := l_id_vs;
            l_actual := l_actual + 1;
        
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
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pdms_vital_sign_to_reg;

    /**********************************************************************************************
    * Gets the options for vital signs (multi-choice)
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        o_vital_s                Patient vital signs conf
    * @param        i_id_vs                  Vital sign ID
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.2
    * @since        2012-11-19
    **********************************************************************************************/
    FUNCTION get_vs_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_id_vs   IN vital_sign_desc.id_vital_sign%TYPE,
        o_vs      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        i_gender patient.gender%TYPE;
        i_age    patient.age%TYPE;
    BEGIN
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        i_gender := pk_patient.get_pat_gender(i_patient);
        i_age    := pk_patient.get_pat_age_years(i_lang, i_patient);
    
        g_error := 'Calling VS service';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_vital_sign.get_vs_desc_list(i_lang, i_prof, i_gender, i_age, i_id_vs, o_vs, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_vs_options;

    /**********************************************************************************************
    * Gets the options for vital signs (multi-choice)
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vital_sign_read     Read identifier
    * @param        i_flg_screen             ????
    * @param        o_hist                   Histórico do valor
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-01
    **********************************************************************************************/
    FUNCTION get_vs_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_flg_screen         IN VARCHAR2,
        o_hist               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_vital_sign.get_vs_detail(i_lang, i_prof, i_id_vital_sign_read, i_flg_screen, o_hist, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_vs_detail;

    FUNCTION get_vs_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_id_vs IN vital_sign.id_vital_sign%TYPE
    ) RETURN VARCHAR2 IS
        l_type vital_sign.flg_fill_type%TYPE;
    BEGIN
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        SELECT flg_fill_type
          INTO l_type
          FROM vital_sign
         WHERE id_vital_sign = i_id_vs;
    
        g_error := 'Calling VS service';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN l_type;
    
    END get_vs_type;

    /**********************************************************************************************
    * Gets the vital sign attrributes
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vital_sign          Vital sign identifier
    * @param        o_vs_attribute           
    * @param        o_vs_options             
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-01
    **********************************************************************************************/
    FUNCTION get_vs_attribute
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign_read.id_vital_sign_read%TYPE,
        o_vs_attribute  OUT pk_types.cursor_type,
        o_vs_options    OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret    BOOLEAN := TRUE;
        l_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    BEGIN
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        IF pk_sysconfig.get_config(i_code_cf   => 'VITAL_SIGN_ATTRIBUTES',
                                   i_prof_inst => i_prof.institution,
                                   i_prof_soft => i_prof.software) = pk_alert_constant.g_yes
        THEN
        
            l_ret := pk_vital_sign_core.get_vs_attributes(i_lang,
                                                          i_prof,
                                                          i_id_vital_sign,
                                                          NULL,
                                                          o_vs_attribute,
                                                          o_error);
        
            OPEN o_vs_options FOR
                SELECT vsa.id_parent,
                       aux.id_vs_attribute data,
                       pk_translation.get_translation(i_lang, vsa.code_vs_attribute) label,
                       vsa.flg_free_text flg_free_text
                  FROM (SELECT vsasi.id_vs_attribute,
                               vsasi.rank,
                               row_number() over(PARTITION BY vsasi.id_vs_attribute ORDER BY vsasi.id_software DESC, vsasi.id_institution DESC, vsasi.id_market DESC) rn
                          FROM vs_attribute_soft_inst vsasi
                         WHERE vsasi.id_vital_sign = i_id_vital_sign
                           AND vsasi.id_market IN (pk_alert_constant.g_id_market_all, l_market)
                           AND vsasi.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                           AND vsasi.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)) aux
                  JOIN vs_attribute vsa
                    ON vsa.id_vs_attribute = aux.id_vs_attribute
                 WHERE aux.rn = 1
                   AND vsa.id_parent IS NOT NULL
                 ORDER BY vsa.id_parent, aux.rank ASC;
        
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_vs_attribute;

    /**********************************************************************************************
    * Gets the vital sign attrributes
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vital_sign          Vital sign identifier
    * @param        o_vs_attribute           
    * @param        o_vs_options             
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Sergio Pereira
    * @version      2.6.3.10
    * @since        2014-01-24
    **********************************************************************************************/
    FUNCTION get_vs_read_attributes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign      IN vital_sign.id_vital_sign%TYPE,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_vs_attributes      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_vital_sign_core.get_vs_read_attributes(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_vital_sign      => i_id_vital_sign,
                                                         i_id_vital_sign_read => i_id_vital_sign_read,
                                                         o_cursor             => o_vs_attributes,
                                                         o_error              => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_vs_read_attributes;

    /************************************************************************************************************
    * get_pdms_module_vital_signs
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_patient                   patient identifier
    * @param      i_flg_view                  default view
    * @param      i_tb_vs                     vital sign identifier search table
    * @param      i_tb_view                   flag view search table  
    * @param      o_vs                        cursor out
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2014/11/20
    ***********************************************************************************************************/

    FUNCTION get_pdms_module_vital_signs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_tb_vs    IN table_number DEFAULT NULL,
        i_tb_view  IN table_varchar DEFAULT NULL,
        o_vs       OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(30) := 'GET_PDMS_MODULE_VITAL_SIGNS';
        l_um pk_types.cursor_type;
    BEGIN
        g_error := 'call pk_vital_sign_core.get_pdms_module_vital_sign';
        IF NOT pk_vital_sign_core.get_pdms_module_vital_signs(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_patient => i_patient,
                                                              i_tb_vs   => i_tb_vs,
                                                              i_tb_view => i_tb_view,
                                                              o_vs      => o_vs,
                                                              o_um      => l_um,
                                                              o_error   => o_error)
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
                                              c_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_vs);
            pk_types.open_my_cursor(l_um);
            RETURN FALSE;
    END get_pdms_module_vital_signs;
BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_api_vital_sign_pdms;
/
