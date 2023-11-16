/*-- Last Change Revision: $Rev: 2054039 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2023-01-03 16:16:15 +0000 (ter, 03 jan 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_vital_sign_core AS

    --
    -- PRIVATE CONSTANTS
    --
    SUBTYPE obj_name IS VARCHAR2(32 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);

    /* Package name */
    g_package_name  VARCHAR2(32 CHAR);
    g_package_owner VARCHAR2(32 CHAR);

    --
    -- FUNCTIONS
    --

    /************************************************************************************************************
    * This function returns unit measure description from a vital sign
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_unit_measure              unit measure id
    * @param      i_vital_sign_scales         vital sign scale id
    * @param      i_without_um_no_desc        Is to remove unit measure description from output ('Y' - Yes, 'N' - No)
    * @param      i_short_desc                unit measure description should be short ('Y' - short, 'N' - complete)
    *
    * @return     Returns unit measure description
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/25
    *
    ***********************************************************************************************************/
    FUNCTION get_um_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_unit_measure       IN unit_measure.id_unit_measure%TYPE,
        i_vital_sign_scales  IN vital_sign_scales.id_vital_sign_scales%TYPE DEFAULT NULL,
        i_without_um_no_desc IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_short_desc         IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN pk_translation.t_desc_translation IS
        l_function_name CONSTANT obj_name := 'GET_UM_DESC';
        l_dbg_msg debug_msg;
    
        l_um_desc      pk_translation.t_desc_translation;
        l_vss_desc     pk_translation.t_desc_translation;
        l_um_id        vital_sign_scales_element.id_unit_measure%TYPE;
        l_unit_measure unit_measure.id_unit_measure%TYPE;
    
    BEGIN
        l_dbg_msg := 'get unit measure description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
        IF i_vital_sign_scales IS NOT NULL
        THEN
            SELECT ' ' || pk_translation.get_translation(i_lang,
                                                         CASE i_short_desc
                                                             WHEN pk_alert_constant.g_yes THEN
                                                              vss.code_vital_sign_scales_short
                                                             ELSE
                                                              vss.code_vital_sign_scales
                                                         END),
                   (SELECT a.id_unit_measure
                      FROM vital_sign_scales_element a
                     WHERE a.id_vital_sign_scales = i_vital_sign_scales
                       AND rownum = 1)
              INTO l_vss_desc, l_um_id
              FROM vital_sign_scales vss
             WHERE vss.id_vital_sign_scales = i_vital_sign_scales;
        
        ELSE
            l_vss_desc := NULL;
        
        END IF;
    
        l_unit_measure := nvl(l_um_id, i_unit_measure);
    
        IF l_unit_measure IS NULL
           OR (l_unit_measure = g_without_um AND i_without_um_no_desc = pk_alert_constant.g_yes)
        THEN
            RETURN NULL;
        END IF;
    
        SELECT pk_translation.get_translation(i_lang,
                                              CASE i_short_desc
                                                  WHEN pk_alert_constant.g_yes THEN
                                                   um.code_unit_measure_abrv
                                                  ELSE
                                                   um.code_unit_measure
                                              END)
          INTO l_um_desc
          FROM unit_measure um
         WHERE um.id_unit_measure = l_unit_measure;
    
        RETURN l_um_desc || l_vss_desc;
    
    END get_um_desc;

    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient and number of moments of vital sign registration
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_patient                   Patient id
    * @param      i_visit                     Visit id
    * @param      o_vs_n_records              Number of collumns of registries
    * @param      o_n_vs                      Number of registries
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/24
    *
    * @dependencies    REPORTS
    ***********************************************************************************************************/
    FUNCTION get_vs_n_records
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_view     IN vs_soft_inst.flg_view%TYPE,
        i_patient      IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        i_visit        IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        o_vs_n_records OUT PLS_INTEGER,
        o_n_vs         OUT PLS_INTEGER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_VS_N_RECORDS';
        l_dbg_msg    debug_msg;
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    BEGIN
    
        l_dbg_msg := 'get the number of vital sign records';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
        SELECT COUNT(1)
          INTO o_vs_n_records
          FROM (SELECT 1
                  FROM (SELECT vsrv.id_vital_sign, vsrv.dt_vital_sign_read_tstz
                          FROM vital_sign_read vsrv
                         INNER JOIN episode e
                            ON vsrv.id_episode = e.id_episode
                         WHERE i_visit IS NOT NULL
                           AND e.id_visit = i_visit
                        UNION ALL
                        SELECT vsrp.id_vital_sign, vsrp.dt_vital_sign_read_tstz
                          FROM vital_sign_read vsrp
                         WHERE i_visit IS NULL
                           AND vsrp.id_patient = i_patient) vsr
                 WHERE (i_flg_view IS NULL OR EXISTS
                        (SELECT 1
                           FROM vs_soft_inst vsi
                          WHERE vsi.id_vital_sign = vsr.id_vital_sign
                            AND vsi.flg_view = i_flg_view
                            AND vsi.id_institution = i_prof.institution
                            AND vsi.id_software = i_prof.software))
                 GROUP BY vsr.dt_vital_sign_read_tstz);
    
        l_dbg_msg := 'get the number of vital_signs with records';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
    
        SELECT COUNT(1)
          INTO o_n_vs
          FROM (SELECT 1
                  FROM (SELECT vsea.id_vital_sign, vsea.id_unit_measure
                          FROM vs_visit_ea vsea
                         WHERE i_visit IS NOT NULL
                           AND vsea.id_visit = i_visit
                        UNION ALL
                        SELECT vsea.id_vital_sign, vsea.id_unit_measure
                          FROM vs_patient_ea vsea
                         WHERE i_visit IS NULL
                           AND vsea.id_patient = i_patient) vsea
                 WHERE i_flg_view IS NULL
                    OR EXISTS (SELECT 1
                          FROM vs_soft_inst vsi
                         WHERE vsi.id_vital_sign = vsea.id_vital_sign
                           AND vsi.flg_view = i_flg_view
                           AND vsi.id_institution = i_prof.institution
                           AND vsi.id_software = i_prof.software));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
        
            o_vs_n_records := 0;
            o_n_vs         := 0;
            RETURN FALSE;
        
    END get_vs_n_records;

    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient
    *
    * @param      i_vital_sign                Vital sign id
    * @param      i_patient                   Patient id
    * @param      i_visit                     Visit id
    *
    * @return     Nunber of registries
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/24
    *
    ***********************************************************************************************************/
    FUNCTION get_vs_n_records
    (
        i_vital_sign IN vital_sign_read.id_vital_sign%TYPE,
        i_patient    IN vital_sign_read.id_patient%TYPE,
        i_visit      IN episode.id_visit%TYPE DEFAULT NULL
    ) RETURN PLS_INTEGER IS
        l_function_name CONSTANT obj_name := 'GET_VS_N_RECORDS';
        l_dbg_msg debug_msg;
    
        l_n_records PLS_INTEGER;
    
    BEGIN
        IF i_patient IS NULL
           OR i_vital_sign IS NULL
        THEN
            RETURN 0;
        END IF;
    
        l_dbg_msg := 'get number of vital sign records';
    
        SELECT COUNT(1)
          INTO l_n_records
          FROM (SELECT t.id_vital_sign, t.dt_vital_sign_read_tstz
                  FROM (SELECT nvl(vrel.id_vital_sign_parent, vsr.id_vital_sign) id_vital_sign,
                               vsr.dt_vital_sign_read_tstz,
                               vsr.id_vital_sign_read
                          FROM vital_sign_read vsr
                          LEFT OUTER JOIN vital_sign_relation vrel
                            ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                           AND vrel.relation_domain IN (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                           AND vrel.flg_available = pk_alert_constant.g_yes
                         WHERE nvl(vrel.id_vital_sign_parent, vsr.id_vital_sign) = i_vital_sign
                           AND vsr.id_patient = i_patient
                           AND i_visit IS NULL
                           AND vsr.flg_state = pk_alert_constant.g_active
                        UNION ALL
                        SELECT nvl(vrel.id_vital_sign_parent, vsr.id_vital_sign) id_vital_sign,
                               vsr.dt_vital_sign_read_tstz,
                               vsr.id_vital_sign_read
                          FROM vital_sign_read vsr
                          LEFT OUTER JOIN vital_sign_relation vrel
                            ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                           AND vrel.relation_domain IN (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                           AND vrel.flg_available = pk_alert_constant.g_yes
                         WHERE nvl(vrel.id_vital_sign_parent, vsr.id_vital_sign) = i_vital_sign
                           AND vsr.id_patient = i_patient
                           AND i_visit = (SELECT pk_episode.get_id_visit(vsr.id_episode)
                                            FROM dual)
                           AND vsr.flg_state = pk_alert_constant.g_active
                           AND rownum > 0) t
                 WHERE (SELECT pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read)
                          FROM dual) = 0
                 GROUP BY t.id_vital_sign, t.dt_vital_sign_read_tstz);
    
        RETURN l_n_records;
    
    END get_vs_n_records;

    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient and number of moments of vital sign registration
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_patient                   Patient id
    * @param      i_visit                     Visit id
    * @param      o_vs_grid                   Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/24
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_vs_short_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_patient  IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        i_visit    IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        o_vs_grid  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_VS_SHORT_GRID';
        l_dbg_msg debug_msg;
    
        l_short_desc     VARCHAR2(1);
        l_decimal_symbol sys_config.value%TYPE;
    
    BEGIN
        l_short_desc := CASE i_flg_view
                            WHEN pk_alert_constant.g_vs_view_s THEN
                             pk_alert_constant.g_yes
                            ELSE
                             pk_alert_constant.g_no
                        END;
    
        l_dbg_msg := 'get sysconfig DECIMAL_SYMBOL';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
        l_decimal_symbol := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                    i_prof_inst => i_prof.institution,
                                                    i_prof_soft => i_prof.software);
    
        l_dbg_msg := 'open vs_patient_ea cursor';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
        OPEN o_vs_grid FOR
            SELECT vsi.rank,
                   pk_vital_sign.get_vs_desc(i_lang, ea.id_vital_sign, l_short_desc) AS vs_desc,
                   ea.n_records,
                   --
                   pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_patient            => fst.id_patient,
                                              i_episode            => fst.id_episode,
                                              i_vital_sign         => ea.id_vital_sign,
                                              i_value              => fst.value,
                                              i_vs_unit_measure    => fst.id_unit_measure,
                                              i_vital_sign_desc    => fst.id_vital_sign_desc,
                                              i_vs_scales_element  => fst.id_vs_scales_element,
                                              i_dt_vital_sign_read => fst.dt_vital_sign_read_tstz,
                                              i_ea_unit_measure    => ea.id_unit_measure,
                                              i_short_desc         => l_short_desc,
                                              i_decimal_symbol     => l_decimal_symbol,
                                              i_dt_registry        => fst.dt_registry) AS fst_value,
                   pk_date_utils.date_char_tsz(i_lang, fst.dt_vital_sign_read_tstz, i_prof.institution, i_prof.software) AS fst_dt_str,
                   pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                         fst.dt_vital_sign_read_tstz,
                                                         i_prof.institution,
                                                         i_prof.software) AS fst_day_str,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    fst.dt_vital_sign_read_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) AS fst_hr_str,
                   fst.dt_vital_sign_read_tstz AS fst_dt_tstz,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, fst.id_prof_read) AS fst_prof,
                   pk_vital_sign.vs_has_notes(fst.id_vital_sign_notes) AS fst_has_notes,
                   fstn.notes AS fst_notes_txt,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, fstn.id_professional) AS fst_notes_prof,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    fstn.id_professional,
                                                    fstn.dt_notes_tstz,
                                                    fst.id_episode) AS fst_notes_prof_spec,
                   get_um_desc(i_lang,
                               ea.id_unit_measure,
                               pk_vital_sign.get_vs_scale(fst.id_vs_scales_element),
                               pk_alert_constant.g_yes,
                               l_short_desc) fst_um_desc,
                   --
                   pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_patient            => minv.id_patient,
                                              i_episode            => minv.id_episode,
                                              i_vital_sign         => ea.id_vital_sign,
                                              i_value              => minv.value,
                                              i_vs_unit_measure    => minv.id_unit_measure,
                                              i_vital_sign_desc    => minv.id_vital_sign_desc,
                                              i_vs_scales_element  => minv.id_vs_scales_element,
                                              i_dt_vital_sign_read => minv.dt_vital_sign_read_tstz,
                                              i_ea_unit_measure    => ea.id_unit_measure,
                                              i_short_desc         => l_short_desc,
                                              i_decimal_symbol     => l_decimal_symbol,
                                              i_dt_registry        => minv.dt_registry) AS min_value,
                   pk_date_utils.date_char_tsz(i_lang,
                                               minv.dt_vital_sign_read_tstz,
                                               i_prof.institution,
                                               i_prof.software) AS min_dt_str,
                   pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                         minv.dt_vital_sign_read_tstz,
                                                         i_prof.institution,
                                                         i_prof.software) AS min_day_str,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    minv.dt_vital_sign_read_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) AS min_hr_str,
                   minv.dt_vital_sign_read_tstz AS min_dt_tstz,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, minv.id_prof_read) AS min_prof,
                   pk_vital_sign.vs_has_notes(minv.id_vital_sign_notes) AS min_has_notes,
                   minn.notes AS min_notes_txt,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, minn.id_professional) AS min_notes_prof,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    minn.id_professional,
                                                    minn.dt_notes_tstz,
                                                    minv.id_episode) AS min_notes_prof_spec,
                   get_um_desc(i_lang,
                               ea.id_unit_measure,
                               pk_vital_sign.get_vs_scale(minv.id_vs_scales_element),
                               pk_alert_constant.g_yes,
                               l_short_desc) min_um_desc,
                   --
                   pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_patient            => maxv.id_patient,
                                              i_episode            => maxv.id_episode,
                                              i_vital_sign         => ea.id_vital_sign,
                                              i_value              => maxv.value,
                                              i_vs_unit_measure    => maxv.id_unit_measure,
                                              i_vital_sign_desc    => maxv.id_vital_sign_desc,
                                              i_vs_scales_element  => maxv.id_vs_scales_element,
                                              i_dt_vital_sign_read => maxv.dt_vital_sign_read_tstz,
                                              i_ea_unit_measure    => ea.id_unit_measure,
                                              i_short_desc         => l_short_desc,
                                              i_decimal_symbol     => l_decimal_symbol,
                                              i_dt_registry        => maxv.dt_registry) AS max_value,
                   pk_date_utils.date_char_tsz(i_lang,
                                               maxv.dt_vital_sign_read_tstz,
                                               i_prof.institution,
                                               i_prof.software) AS max_dt_str,
                   pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                         maxv.dt_vital_sign_read_tstz,
                                                         i_prof.institution,
                                                         i_prof.software) AS max_day_str,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    maxv.dt_vital_sign_read_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) AS max_hr_str,
                   maxv.dt_vital_sign_read_tstz AS max_dt_tstz,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, maxv.id_prof_read) AS max_prof,
                   pk_vital_sign.vs_has_notes(maxv.id_vital_sign_notes) AS max_has_notes,
                   maxn.notes AS max_notes_txt,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, maxn.id_professional) AS max_notes_prof,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    maxn.id_professional,
                                                    maxn.dt_notes_tstz,
                                                    maxv.id_episode) AS max_notes_prof_spec,
                   get_um_desc(i_lang,
                               ea.id_unit_measure,
                               pk_vital_sign.get_vs_scale(maxv.id_vs_scales_element),
                               pk_alert_constant.g_yes,
                               l_short_desc) max_um_desc,
                   --
                   pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_patient            => lst3.id_patient,
                                              i_episode            => lst3.id_episode,
                                              i_vital_sign         => ea.id_vital_sign,
                                              i_value              => lst3.value,
                                              i_vs_unit_measure    => lst3.id_unit_measure,
                                              i_vital_sign_desc    => lst3.id_vital_sign_desc,
                                              i_vs_scales_element  => lst3.id_vs_scales_element,
                                              i_dt_vital_sign_read => lst3.dt_vital_sign_read_tstz,
                                              i_ea_unit_measure    => ea.id_unit_measure,
                                              i_short_desc         => l_short_desc,
                                              i_decimal_symbol     => l_decimal_symbol,
                                              i_dt_registry        => lst3.dt_registry) AS lst3_value,
                   pk_date_utils.date_char_tsz(i_lang,
                                               lst3.dt_vital_sign_read_tstz,
                                               i_prof.institution,
                                               i_prof.software) AS lst3_dt_str,
                   pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                         lst3.dt_vital_sign_read_tstz,
                                                         i_prof.institution,
                                                         i_prof.software) AS lst3_day_str,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    lst3.dt_vital_sign_read_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) AS lst3_hr_str,
                   lst3.dt_vital_sign_read_tstz AS lst3_dt_tstz,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lst3.id_prof_read) AS lst3_prof,
                   pk_vital_sign.vs_has_notes(lst3.id_vital_sign_notes) AS lst3_has_notes,
                   lt3n.notes AS lst3_notes_txt,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lt3n.id_professional) AS lst3_notes_prof,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    lt3n.id_professional,
                                                    lt3n.dt_notes_tstz,
                                                    lst3.id_episode) AS lst3_notes_prof_spec,
                   get_um_desc(i_lang,
                               ea.id_unit_measure,
                               pk_vital_sign.get_vs_scale(lst3.id_vs_scales_element),
                               pk_alert_constant.g_yes,
                               l_short_desc) lst3_um_desc,
                   --
                   pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_patient            => lst2.id_patient,
                                              i_episode            => lst2.id_episode,
                                              i_vital_sign         => ea.id_vital_sign,
                                              i_value              => lst2.value,
                                              i_vs_unit_measure    => lst2.id_unit_measure,
                                              i_vital_sign_desc    => lst2.id_vital_sign_desc,
                                              i_vs_scales_element  => lst2.id_vs_scales_element,
                                              i_dt_vital_sign_read => lst2.dt_vital_sign_read_tstz,
                                              i_ea_unit_measure    => ea.id_unit_measure,
                                              i_short_desc         => l_short_desc,
                                              i_decimal_symbol     => l_decimal_symbol,
                                              i_dt_registry        => lst2.dt_registry) AS lst2_value,
                   pk_date_utils.date_char_tsz(i_lang,
                                               lst2.dt_vital_sign_read_tstz,
                                               i_prof.institution,
                                               i_prof.software) AS lst2_dt_str,
                   pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                         lst2.dt_vital_sign_read_tstz,
                                                         i_prof.institution,
                                                         i_prof.software) AS lst2_day_str,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    lst2.dt_vital_sign_read_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) AS lst2_hr_str,
                   lst2.dt_vital_sign_read_tstz AS lst2_dt_tstz,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lst2.id_prof_read) AS lst2_prof,
                   pk_vital_sign.vs_has_notes(lst2.id_vital_sign_notes) AS lst2_has_notes,
                   lt2n.notes AS lst2_notes_txt,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lt2n.id_professional) AS lst2_notes_prof,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    lt2n.id_professional,
                                                    lt2n.dt_notes_tstz,
                                                    lst2.id_episode) AS lst2_notes_prof_spec,
                   get_um_desc(i_lang,
                               ea.id_unit_measure,
                               pk_vital_sign.get_vs_scale(lst2.id_vs_scales_element),
                               pk_alert_constant.g_yes,
                               l_short_desc) lst2_um_desc,
                   --
                   pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_patient            => lst1.id_patient,
                                              i_episode            => lst1.id_episode,
                                              i_vital_sign         => ea.id_vital_sign,
                                              i_value              => lst1.value,
                                              i_vs_unit_measure    => lst1.id_unit_measure,
                                              i_vital_sign_desc    => lst1.id_vital_sign_desc,
                                              i_vs_scales_element  => lst1.id_vs_scales_element,
                                              i_dt_vital_sign_read => lst1.dt_vital_sign_read_tstz,
                                              i_ea_unit_measure    => ea.id_unit_measure,
                                              i_short_desc         => l_short_desc,
                                              i_decimal_symbol     => l_decimal_symbol,
                                              i_dt_registry        => lst1.dt_registry) AS lst1_value,
                   pk_date_utils.date_char_tsz(i_lang,
                                               lst1.dt_vital_sign_read_tstz,
                                               i_prof.institution,
                                               i_prof.software) AS lst1_dt_str,
                   pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                         lst1.dt_vital_sign_read_tstz,
                                                         i_prof.institution,
                                                         i_prof.software) AS lst1_day_str,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    lst1.dt_vital_sign_read_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) AS lst1_hr_str,
                   lst1.dt_vital_sign_read_tstz AS lst1_dt_tstz,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lst1.id_prof_read) AS lst1_prof,
                   pk_vital_sign.vs_has_notes(lst1.id_vital_sign_notes) AS lst1_has_notes,
                   lt1n.notes AS lst1_notes_txt,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lt1n.id_professional) AS lst1_notes_prof,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    lt1n.id_professional,
                                                    lt1n.dt_notes_tstz,
                                                    lst1.id_episode) AS lst1_notes_prof_spec,
                   get_um_desc(i_lang,
                               ea.id_unit_measure,
                               pk_vital_sign.get_vs_scale(lst1.id_vs_scales_element),
                               pk_alert_constant.g_yes,
                               l_short_desc) lst1_um_desc,
                   fst.id_vital_sign_read id_vital_sign_read_fst,
                   minv.id_vital_sign_read id_vital_sign_read_minv,
                   maxv.id_vital_sign_read id_vital_sign_read_maxv,
                   lst3.id_vital_sign_read id_vital_sign_read_lst3,
                   lst2.id_vital_sign_read id_vital_sign_read_lst2,
                   lst1.id_vital_sign_read id_vital_sign_read_lst1
              FROM (SELECT vvea.id_vital_sign,
                           vvea.id_unit_measure,
                           vvea.n_records,
                           vvea.id_first_vsr,
                           vvea.id_min_vsr,
                           vvea.id_max_vsr,
                           vvea.id_last_3_vsr,
                           vvea.id_last_2_vsr,
                           vvea.id_last_1_vsr
                      FROM vs_visit_ea vvea
                     WHERE i_visit IS NOT NULL
                       AND vvea.id_visit = i_visit
                    UNION ALL
                    SELECT vpea.id_vital_sign,
                           vpea.id_unit_measure,
                           vpea.n_records,
                           vpea.id_first_vsr,
                           vpea.id_min_vsr,
                           vpea.id_max_vsr,
                           vpea.id_last_3_vsr,
                           vpea.id_last_2_vsr,
                           vpea.id_last_1_vsr
                      FROM vs_patient_ea vpea
                     WHERE i_visit IS NULL
                       AND vpea.id_patient = i_patient) ea
            
              LEFT OUTER JOIN vs_soft_inst vsi
                ON vsi.id_vital_sign = ea.id_vital_sign
               AND vsi.flg_view = i_flg_view
               AND vsi.id_institution = i_prof.institution
               AND vsi.id_software = i_prof.software
            
             INNER JOIN vital_sign_read fst
                ON ea.id_first_vsr = fst.id_vital_sign_read
              LEFT OUTER JOIN vital_sign_notes fstn
                ON fst.id_vital_sign_notes = fstn.id_vital_sign_notes
            
              LEFT OUTER JOIN vital_sign_read minv
                ON ea.id_min_vsr = minv.id_vital_sign_read
              LEFT OUTER JOIN vital_sign_notes minn
                ON minv.id_vital_sign_notes = minn.id_vital_sign_notes
            
              LEFT OUTER JOIN vital_sign_read maxv
                ON ea.id_max_vsr = maxv.id_vital_sign_read
              LEFT OUTER JOIN vital_sign_notes maxn
                ON maxv.id_vital_sign_notes = maxn.id_vital_sign_notes
            
              LEFT OUTER JOIN vital_sign_read lst3
                ON ea.id_last_3_vsr = lst3.id_vital_sign_read
              LEFT OUTER JOIN vital_sign_notes lt3n
                ON lst3.id_vital_sign_notes = lt3n.id_vital_sign_notes
            
              LEFT OUTER JOIN vital_sign_read lst2
                ON ea.id_last_2_vsr = lst2.id_vital_sign_read
              LEFT OUTER JOIN vital_sign_notes lt2n
                ON lst2.id_vital_sign_notes = lt2n.id_vital_sign_notes
            
             INNER JOIN vital_sign_read lst1
                ON ea.id_last_1_vsr = lst1.id_vital_sign_read
              LEFT OUTER JOIN vital_sign_notes lt1n
                ON lst1.id_vital_sign_notes = lt1n.id_vital_sign_notes
            
             WHERE i_flg_view IS NULL
                OR vsi.id_vital_sign IS NOT NULL
            
             ORDER BY vsi.rank     ASC NULLS LAST,
                      vs_desc      ASC,
                      fst_um_desc  ASC,
                      min_um_desc  ASC,
                      max_um_desc  ASC,
                      lst3_um_desc ASC,
                      lst2_um_desc ASC,
                      lst1_um_desc ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
        
            pk_types.open_my_cursor(i_cursor => o_vs_grid);
            RETURN FALSE;
        
    END get_vs_short_grid;

    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient and number of moments of vital sign registration
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_all_details               If all details should be returned ('Y' - yes; 'N' - No)
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_interval                  Interval to filter
    * @param      i_dt_begin                  Date begin of the interval (Last X records, Last X my records)
    * @param      i_dt_end                    Date end of the interval (Last X records, Last X my records)
    * @param      o_val_vs                    Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/25
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_vs_grid
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_view    IN vs_soft_inst.flg_view%TYPE,
        i_all_details IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_scope       IN NUMBER DEFAULT NULL,
        i_scope_type  IN VARCHAR2 DEFAULT NULL,
        i_interval    IN VARCHAR2 DEFAULT NULL,
        i_dt_begin    IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        o_val_vs      OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_function_name CONSTANT obj_name := 'GET_VS_GRID';
        l_dbg_msg debug_msg;
    
        l_sep            CONSTANT VARCHAR2(1 CHAR) := ';';
        l_decimal_symbol CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software);
        l_array_val CLOB;
    
        l_nr_records PLS_INTEGER := NULL;
        l_id_prof    professional.id_professional%TYPE := NULL;
    
        -- VALUES
        CURSOR c_values
        (
            i_dt_begin   vital_sign_read.dt_vital_sign_read_tstz%TYPE,
            i_dt_end     vital_sign_read.dt_vital_sign_read_tstz%TYPE,
            i_nr_records PLS_INTEGER,
            i_id_prof    professional.id_professional%TYPE
        ) IS
            SELECT d.id_vital_sign,
                   d.vital_sign_scale,
                   (SELECT pk_translation.get_translation(i_lang, d.code_vs_short_desc)
                      FROM dual) name_vs,
                   d.dt_registry,
                   d.dt_vital_sign_read,
                   (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                      FROM unit_measure um
                     WHERE um.id_unit_measure = decode(d.vital_sign_scale,
                                                       NULL,
                                                       d.id_unit_measure_vsr,
                                                       (SELECT vsse.id_unit_measure
                                                          FROM vital_sign_scales_element vsse
                                                         WHERE vsse.id_vital_sign_scales = d.vital_sign_scale
                                                           AND rownum = 1))) AS desc_unit_measure,
                   
                   CASE d.relation_domain
                        WHEN pk_alert_constant.g_vs_rel_conc THEN
                         pk_vital_sign.get_bloodpressure_value(i_vital_sign         => d.id_vital_sign,
                                                               i_patient            => l_id_patient,
                                                               i_episode            => d.id_episode,
                                                               i_dt_vital_sign_read => d.dt_vital_sign_read_tstz,
                                                               i_decimal_symbol     => l_decimal_symbol,
                                                               i_dt_registry        => d.dt_registry)
                        WHEN pk_alert_constant.g_vs_rel_sum THEN
                         to_char(pk_vital_sign.get_glasgowtotal_value(d.id_vital_sign,
                                                                      l_id_patient,
                                                                      d.id_episode,
                                                                      d.dt_vital_sign_read_tstz))
                        ELSE
                         CASE
                             WHEN d.id_vital_sign_desc IS NULL THEN
                              pk_utils.to_str(CASE d.id_unit_measure_vsr
                                                  WHEN d.id_unit_measure_vsi THEN
                                                   d.value
                                                  ELSE
                                                   nvl((SELECT pk_unit_measure.get_unit_mea_conversion(d.value,
                                                                                                      d.id_unit_measure_vsr,
                                                                                                      d.id_unit_measure_vsi)
                                                         FROM dual),
                                                       d.value)
                                              END,
                                              l_decimal_symbol)
                             ELSE
                              (SELECT pk_vital_sign.get_vsd_desc(i_lang, d.id_vital_sign_desc, l_id_patient)
                                 FROM dual)
                         END
                    END AS value_desc,
                   
                   d.value,
                   d.id_vital_sign_read,
                   d.id_unit_measure_vsr id_unit_measure,
                   d.flg_state,
                   decode((SELECT COUNT(1)
                            FROM vital_sign_read_hist vsrh
                           WHERE vsrh.id_vital_sign_read = d.id_vital_sign_read),
                          0,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_has_hist,
                   d.id_prof_read,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, d.id_prof_read)
                      FROM dual) desc_prof,
                   d.id_epis_triage,
                   d.flg_fill_type
              FROM (SELECT row_number() over(PARTITION BY c.rn2 ORDER BY c.dt_vital_sign_read_tstz DESC NULLS LAST) rn,
                           c.rn2,
                           c.id_vital_sign,
                           (SELECT pk_vital_sign.get_vs_scale(c.id_vs_scales_element)
                              FROM dual) vital_sign_scale,
                           c.dt_registry,
                           c.dt_vital_sign_read,
                           c.value,
                           c.id_vital_sign_read,
                           c.id_unit_measure_vsr,
                           c.flg_state,
                           c.id_prof_read,
                           c.dt_vital_sign_read_tstz,
                           c.rank,
                           c.flg_fill_type,
                           c.id_epis_triage,
                           c.id_vital_sign_desc,
                           c.id_unit_measure_vsi,
                           c.relation_domain,
                           c.id_episode,
                           c.code_vs_short_desc
                      FROM (SELECT row_number() over(PARTITION BY a.id_vital_sign ORDER BY a.dt_vital_sign_read_tstz, id_vs_scales_element DESC NULLS LAST) rn2,
                                   a.id_vital_sign,
                                   a.dt_registry,
                                   a.dt_vital_sign_read,
                                   a.value,
                                   a.id_vital_sign_read,
                                   a.id_unit_measure_vsr,
                                   a.flg_state,
                                   a.id_prof_read,
                                   a.dt_vital_sign_read_tstz,
                                   a.rank,
                                   a.flg_fill_type,
                                   a.id_epis_triage,
                                   a.id_vital_sign_desc,
                                   a.id_unit_measure_vsi,
                                   NULL relation_domain,
                                   a.id_episode,
                                   a.id_vs_scales_element,
                                   a.code_vs_short_desc
                              FROM (SELECT vsr.id_vital_sign,
                                           vs.code_vs_short_desc,
                                           vsr.dt_registry,
                                           vsr.dt_vital_sign_read_tstz AS dt_vital_sign_read,
                                           vsr.id_vital_sign_desc,
                                           vsr.id_episode,
                                           vsr.value,
                                           vsr.id_vital_sign_read,
                                           vsr.id_unit_measure         id_unit_measure_vsr,
                                           vsi.id_unit_measure         id_unit_measure_vsi,
                                           vsr.flg_state,
                                           vsr.id_prof_read,
                                           vsr.dt_vital_sign_read_tstz,
                                           vsi.rank,
                                           vs.flg_fill_type,
                                           vsr.id_vs_scales_element,
                                           vsr.id_epis_triage
                                      FROM vital_sign_read vsr
                                     INNER JOIN (SELECT *
                                                  FROM episode e
                                                 WHERE e.id_episode = l_id_episode
                                                   AND e.id_patient = l_id_patient
                                                   AND i_scope_type = pk_alert_constant.g_scope_type_episode
                                                UNION ALL
                                                SELECT *
                                                  FROM episode e
                                                 WHERE e.id_patient = l_id_patient
                                                   AND i_scope_type = pk_alert_constant.g_scope_type_patient
                                                UNION ALL
                                                SELECT *
                                                  FROM episode e
                                                 WHERE e.id_visit = l_id_visit
                                                   AND e.id_patient = l_id_patient
                                                   AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                                        ON vsr.id_episode = epi.id_episode
                                      JOIN vital_sign vs
                                        ON vsr.id_vital_sign = vs.id_vital_sign
                                      JOIN vs_soft_inst vsi
                                        ON vsi.id_vital_sign = vs.id_vital_sign
                                       AND vsi.id_software = (CASE
                                               WHEN i_interval IS NULL THEN
                                                i_prof.software
                                               ELSE
                                                vsr.id_software_read
                                           END)
                                       AND vsi.id_institution = (CASE
                                               WHEN i_interval IS NULL THEN
                                                i_prof.institution
                                               ELSE
                                                vsr.id_institution_read
                                           END)
                                       AND vsi.flg_view = i_flg_view
                                     WHERE vsr.id_prof_read = nvl(i_id_prof, vsr.id_prof_read)
                                       AND vsr.dt_vital_sign_read_tstz BETWEEN
                                           nvl(i_dt_begin, vsr.dt_vital_sign_read_tstz) AND
                                           nvl(i_dt_end, vsr.dt_vital_sign_read_tstz)
                                       AND (CASE
                                               WHEN vsr.flg_state = pk_alert_constant.g_cancelled THEN
                                                (SELECT get_vsr_cancel(vsr.id_vital_sign,
                                                                       vsr.dt_vital_sign_read_tstz,
                                                                       vsr.id_patient)
                                                   FROM dual)
                                               ELSE
                                                vsr.id_vital_sign_read
                                           END) = vsr.id_vital_sign_read
                                       AND NOT EXISTS
                                     (SELECT 1
                                              FROM vital_sign_relation vr
                                             WHERE vsr.id_vital_sign = vr.id_vital_sign_detail
                                               AND vr.relation_domain IN
                                                   (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                                               AND vr.flg_available = pk_alert_constant.g_yes)
                                       AND (((i_all_details = pk_alert_constant.g_yes) AND (i_interval IS NULL)) OR
                                           vsr.flg_state = pk_alert_constant.g_active)
                                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
                                       AND (i_flg_view IS NULL OR vsi.rank IS NOT NULL)) a
                            UNION ALL
                            SELECT row_number() over(PARTITION BY b.id_vital_sign, id_vs_scales_element ORDER BY b.dt_vital_sign_read_tstz DESC NULLS LAST) rn2,
                                   b.id_vital_sign,
                                   b.dt_registry,
                                   b.dt_vital_sign_read,
                                   b.value,
                                   b.id_vital_sign_read,
                                   b.id_unit_measure_vsr,
                                   b.flg_state,
                                   b.id_prof_read,
                                   b.dt_vital_sign_read_tstz,
                                   b.rank,
                                   b.flg_fill_type,
                                   b.id_epis_triage,
                                   b.id_vital_sign_desc,
                                   b.id_unit_measure_vsi,
                                   b.relation_domain,
                                   b.id_episode,
                                   b.id_vs_scales_element,
                                   b.code_vs_short_desc
                              FROM (SELECT vr.id_vital_sign_parent     id_vital_sign,
                                           vs.code_vs_short_desc,
                                           vsr.dt_registry,
                                           vsr.dt_vital_sign_read_tstz AS dt_vital_sign_read,
                                           NULL                        id_vital_sign_desc,
                                           vr.relation_domain,
                                           vsr.id_episode,
                                           NULL                        AS VALUE,
                                           vsr.id_vital_sign_read,
                                           vsr.id_unit_measure         id_unit_measure_vsr,
                                           NULL                        id_unit_measure_vsi,
                                           vsr.flg_state,
                                           vsr.id_prof_read,
                                           vsr.dt_vital_sign_read_tstz,
                                           vsi.rank,
                                           vs.flg_fill_type,
                                           vsr.id_vs_scales_element,
                                           vsr.id_epis_triage
                                      FROM vital_sign_read vsr
                                     INNER JOIN (SELECT *
                                                  FROM episode e
                                                 WHERE e.id_episode = l_id_episode
                                                   AND e.id_patient = l_id_patient
                                                   AND i_scope_type = pk_alert_constant.g_scope_type_episode
                                                UNION ALL
                                                SELECT *
                                                  FROM episode e
                                                 WHERE e.id_patient = l_id_patient
                                                   AND i_scope_type = pk_alert_constant.g_scope_type_patient
                                                UNION ALL
                                                SELECT *
                                                  FROM episode e
                                                 WHERE e.id_visit = l_id_visit
                                                   AND e.id_patient = l_id_patient
                                                   AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                                        ON vsr.id_episode = epi.id_episode
                                      JOIN vital_sign_relation vr
                                        ON vsr.id_vital_sign = vr.id_vital_sign_detail
                                      JOIN vital_sign vs
                                        ON vr.id_vital_sign_parent = vs.id_vital_sign
                                      JOIN vs_soft_inst vsi
                                        ON vsi.id_vital_sign = vs.id_vital_sign
                                       AND vsi.id_software = (CASE
                                               WHEN i_interval IS NULL THEN
                                                i_prof.software
                                               ELSE
                                                vsr.id_software_read
                                           END)
                                       AND vsi.id_institution = (CASE
                                               WHEN i_interval IS NULL THEN
                                                i_prof.institution
                                               ELSE
                                                vsr.id_institution_read
                                           END)
                                       AND vsi.flg_view = i_flg_view
                                     WHERE vsr.id_prof_read = nvl(i_id_prof, vsr.id_prof_read)
                                       AND vsr.dt_vital_sign_read_tstz BETWEEN
                                           nvl(i_dt_begin, vsr.dt_vital_sign_read_tstz) AND
                                           nvl(i_dt_end, vsr.dt_vital_sign_read_tstz)
                                       AND (((i_all_details = pk_alert_constant.g_yes) AND (i_interval IS NULL)) OR
                                           vsr.flg_state = pk_alert_constant.g_active)
                                       AND (CASE
                                               WHEN vsr.flg_state = pk_alert_constant.g_cancelled THEN
                                                (SELECT get_vsr_cancel(vsr.id_vital_sign,
                                                                       vsr.dt_vital_sign_read_tstz,
                                                                       vsr.id_patient)
                                                   FROM dual)
                                               ELSE
                                                vsr.id_vital_sign_read
                                           END) = vsr.id_vital_sign_read
                                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
                                       AND vr.relation_domain IN
                                           (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                                       AND vr.flg_available = pk_alert_constant.g_yes
                                       AND vr.rank =
                                           (SELECT MIN(v.rank)
                                              FROM vital_sign_relation v
                                             WHERE vr.id_vital_sign_parent = v.id_vital_sign_parent
                                               AND vr.flg_available = pk_alert_constant.g_yes
                                               AND vr.relation_domain != pk_alert_constant.g_vs_rel_percentile)) b) c) d
             WHERE (i_nr_records IS NULL OR ((d.rn <= i_nr_records AND d.rn2 = 1) OR d.rn2 != 1))
             ORDER BY CASE
                          WHEN i_interval IS NOT NULL THEN
                           d.dt_vital_sign_read
                          ELSE
                           NULL
                      END DESC NULLS LAST,
                      rank ASC NULLS LAST,
                      d.vital_sign_scale ASC NULLS LAST,
                      d.id_vital_sign ASC,
                      d.dt_vital_sign_read ASC NULLS LAST;
    
        l_dt_registry_str   VARCHAR2(4000 CHAR);
        l_name_vs           VARCHAR2(4000 CHAR);
        l_desc_unit_measure VARCHAR2(4000 CHAR);
        l_value_desc        VARCHAR2(4000 CHAR);
    
        e_invalid_argument EXCEPTION;
    BEGIN
    
        IF (i_scope IS NOT NULL AND i_scope_type IS NOT NULL)
        THEN
            g_error := 'ANALYSING SCOPE TYPE';
            IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_scope      => i_scope,
                                                  i_scope_type => i_scope_type,
                                                  o_patient    => l_id_patient,
                                                  o_visit      => l_id_visit,
                                                  o_episode    => l_id_episode,
                                                  o_error      => o_error)
            THEN
                RAISE e_invalid_argument;
            END IF;
        
            -- Convert start date to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_dt_begin,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dt_begin,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- Convert end date to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_dt_end,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dt_end,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF i_interval IS NOT NULL
            THEN
                g_error := 'CALCULATE THE INTERVAL FOR DATES';
                IF NOT get_interval_data(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_interval   => i_interval,
                                         io_dt_begin  => l_dt_begin,
                                         io_dt_end    => l_dt_end,
                                         o_nr_records => l_nr_records,
                                         o_id_prof    => l_id_prof,
                                         o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            o_val_vs := table_varchar();
        
            l_dbg_msg := 'GET CURSOR C_VITAL';
            FOR r_val IN c_values(i_dt_begin   => l_dt_begin,
                                  i_dt_end     => l_dt_end,
                                  i_nr_records => l_nr_records,
                                  i_id_prof    => l_id_prof)
            LOOP
                l_array_val         := r_val.id_vital_sign || l_sep || r_val.vital_sign_scale || l_sep;
                l_name_vs           := r_val.name_vs;
                l_desc_unit_measure := r_val.desc_unit_measure;
            
                IF i_all_details = pk_alert_constant.g_yes
                THEN
                    l_value_desc      := r_val.value_desc;
                    l_dt_registry_str := pk_date_utils.date_send_tsz(i_lang,
                                                                     r_val.dt_registry,
                                                                     i_prof.institution,
                                                                     i_prof.software);
                    -- Do not change the order in which the values are concatenated.
                    l_array_val := r_val.id_vital_sign || l_sep || --
                                   pk_date_utils.date_send_tsz(i_lang,
                                                               r_val.dt_vital_sign_read,
                                                               i_prof.institution,
                                                               i_prof.software) || l_sep || --
                                   r_val.id_vital_sign_read || l_sep || --
                                   l_value_desc || l_sep || --
                                   r_val.flg_state || l_sep || -- 5
                                   r_val.id_prof_read || l_sep || --
                                   r_val.id_unit_measure || l_sep || --
                                   l_dt_registry_str || l_sep || --
                                   r_val.vital_sign_scale || l_sep || --
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               r_val.dt_vital_sign_read,
                                                               i_prof.institution,
                                                               i_prof.software) || l_sep || -- 10
                                   pk_date_utils.date_char_tsz(i_lang,
                                                               r_val.dt_registry,
                                                               i_prof.institution,
                                                               i_prof.software) || l_sep || --
                                   r_val.flg_has_hist || l_sep || --
                                   r_val.desc_prof || l_sep || -- 13
                                   pk_vital_sign.get_vs_copy_paste(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_name_vs           => l_name_vs,
                                                                   i_value_desc        => l_value_desc,
                                                                   i_desc_unit_measure => l_desc_unit_measure,
                                                                   i_dt_registry       => r_val.dt_vital_sign_read) ||
                                   l_sep || --14
                                   pk_vital_sign.is_vital_sign_read_only(i_lang            => i_lang,
                                                                         i_prof            => i_prof,
                                                                         i_id_epis_triage  => r_val.id_epis_triage,
                                                                         i_flg_fill_type   => r_val.flg_fill_type,
                                                                         i_vital_sign_read => r_val.id_vital_sign_read)
                    -- 15
                     ;
                END IF;
            
                l_array_val := l_array_val || l_sep;
            
                o_val_vs.extend;
                o_val_vs(o_val_vs.last) := l_array_val;
            
            END LOOP;
        
        ELSE
            o_val_vs := table_varchar();
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_invalid_argument THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   'An input parameter has an unexpected value',
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   l_function_name);
            
                o_val_vs := table_varchar();
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            o_val_vs := table_varchar();
            RETURN FALSE;
    END get_vs_grid;

    FUNCTION get_vs_grid_new
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_view          IN vs_soft_inst.flg_view%TYPE,
        i_all_details       IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_scope             IN NUMBER DEFAULT NULL,
        i_scope_type        IN VARCHAR2 DEFAULT NULL,
        i_interval          IN VARCHAR2 DEFAULT NULL,
        i_dt_begin          IN VARCHAR2 DEFAULT NULL,
        i_dt_end            IN VARCHAR2 DEFAULT NULL,
        i_flg_use_soft_inst IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_val_vs            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'get_vs_grid_new';
        l_dbg_msg debug_msg;
    BEGIN
        IF (i_scope IS NOT NULL AND i_scope_type IS NOT NULL)
        THEN
            l_dbg_msg := 'open   o_val_vs';
            OPEN o_val_vs FOR
                SELECT id_vital_sign,
                       dt_vital_sign_read,
                       id_vital_sign_read,
                       value_desc,
                       flg_vs_status,
                       id_prof_read,
                       id_unit_measure,
                       dt_registry,
                       vital_sign_scale,
                       dt_vs_read_str,
                       dt_registry_str,
                       flg_has_hist,
                       desc_prof,
                       vs_copy_paste,
                       is_vital_sign_read_only,
                       desc_unit_measure,
                       desc_unit_measure_sel,
                       spec_prof,
                       label_triage
                  FROM TABLE(tf_vital_sign_grid(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_flg_view          => i_flg_view,
                                                i_flg_screen        => g_flg_screen_d,
                                                i_all_details       => i_all_details,
                                                i_scope             => i_scope,
                                                i_scope_type        => i_scope_type,
                                                i_interval          => i_interval,
                                                i_dt_begin          => i_dt_begin,
                                                i_dt_end            => i_dt_end,
                                                i_flg_use_soft_inst => i_flg_use_soft_inst));
        ELSE
            l_dbg_msg := 'i_scope IS NULL or i_scope_type IS NULL';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_val_vs);
            RETURN FALSE;
    END get_vs_grid_new;

    FUNCTION tf_vital_sign_grid
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_flg_view                 IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen               IN VARCHAR2,
        i_all_details              IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_scope                    IN NUMBER,
        i_scope_type               IN VARCHAR2,
        i_interval                 IN VARCHAR2 DEFAULT NULL,
        i_dt_begin                 IN VARCHAR2 DEFAULT NULL,
        i_dt_end                   IN VARCHAR2 DEFAULT NULL,
        i_flg_show_previous_values IN VARCHAR2 DEFAULT NULL,
        i_flg_use_soft_inst        IN VARCHAR2 DEFAULT pk_alert_constant.g_yes, -- flg inficating if get_vital_sign_records uses vs_soft_inst to retrieve records
        i_flg_show_relations       IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_coll_vs_grid
        PIPELINED IS
        l_rec_vs_grid t_rec_vs_grid;
        l_error       t_error_out;
        l_id_patient  patient.id_patient%TYPE;
        l_id_episode  episode.id_episode%TYPE;
        l_id_visit    visit.id_visit%TYPE;
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_function_name CONSTANT obj_name := 'TF_VITAL_SIGN_GRID';
        l_dbg_msg debug_msg;
    
        l_decimal_symbol CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software);
    
        l_nr_records PLS_INTEGER := NULL;
        l_id_prof    professional.id_professional%TYPE := NULL;
        l_age        vital_sign_unit_measure.age_min%TYPE;
    
        l_triage sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_M017');
    
    BEGIN
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'get age';
        l_age   := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', l_id_patient);
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Convert end date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_interval IS NOT NULL
        THEN
            g_error := 'CALCULATE THE INTERVAL FOR DATES';
            IF NOT get_interval_data(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_interval   => i_interval,
                                     io_dt_begin  => l_dt_begin,
                                     io_dt_end    => l_dt_end,
                                     o_nr_records => l_nr_records,
                                     o_id_prof    => l_id_prof,
                                     o_error      => l_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        FOR l_rec_vs_grid IN (SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK','FALSE') */
                               *
                                FROM (SELECT d.id_vital_sign,
                                             decode(i_flg_show_previous_values,
                                                    pk_alert_constant.g_no,
                                                    (SELECT pk_date_utils.date_send_tsz(i_lang,
                                                                                        current_timestamp,
                                                                                        i_prof.institution,
                                                                                        i_prof.software)
                                                       FROM dual),
                                                    (SELECT pk_date_utils.date_send_tsz(i_lang,
                                                                                        d.dt_vital_sign_read,
                                                                                        i_prof.institution,
                                                                                        i_prof.software)
                                                       FROM dual)) dt_vital_sign_read,
                                             d.id_vital_sign_read,
                                             d.value_desc,
                                             d.flg_state flg_vs_status,
                                             d.id_prof_read,
                                             d.id_unit_measure_vsr id_unit_measure,
                                             (SELECT pk_date_utils.date_send_tsz(i_lang,
                                                                                 d.dt_registry,
                                                                                 i_prof.institution,
                                                                                 i_prof.software)
                                                FROM dual) dt_registry,
                                             d.vital_sign_scale,
                                             (SELECT pk_date_utils.date_char_tsz(i_lang,
                                                                                 d.dt_vital_sign_read,
                                                                                 i_prof.institution,
                                                                                 i_prof.software)
                                                FROM dual) dt_vs_read_str,
                                             (SELECT pk_date_utils.date_char_tsz(i_lang,
                                                                                 d.dt_registry,
                                                                                 i_prof.institution,
                                                                                 i_prof.software)
                                                FROM dual) dt_registry_str,
                                             decode((SELECT COUNT(1)
                                                      FROM vital_sign_read_hist vsrh
                                                     WHERE vsrh.id_vital_sign_read = d.id_vital_sign_read),
                                                    0,
                                                    pk_alert_constant.g_no,
                                                    pk_alert_constant.g_yes) flg_has_hist,
                                             (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, d.id_prof_read)
                                                FROM dual) desc_prof,
                                             (SELECT pk_vital_sign.get_vs_copy_paste(i_lang              => i_lang,
                                                                                     i_prof              => i_prof,
                                                                                     i_name_vs           => (SELECT pk_translation.get_translation(i_lang,
                                                                                                                                                   d.code_vs_short_desc)
                                                                                                               FROM dual),
                                                                                     i_value_desc        => d.value_desc,
                                                                                     i_desc_unit_measure => d.desc_unit_measure,
                                                                                     i_dt_registry       => d.dt_vital_sign_read)
                                                FROM dual) vs_copy_paste,
                                             (SELECT pk_vital_sign.is_vital_sign_read_only(i_lang            => i_lang,
                                                                                           i_prof            => i_prof,
                                                                                           i_id_epis_triage  => d.id_epis_triage,
                                                                                           i_flg_fill_type   => d.flg_fill_type,
                                                                                           i_vital_sign_read => d.id_vital_sign_read)
                                                FROM dual) is_vital_sign_read_only,
                                             d.desc_unit_measure,
                                             get_vs_value_converted(i_lang,
                                                                    i_prof,
                                                                    d.id_vital_sign_read,
                                                                    pk_alert_constant.g_no,
                                                                    pk_alert_constant.g_no) desc_unit_measure_sel,
                                             d.rank l_rank,
                                             nvl(pk_vital_sign.get_vs_scale_min_value(d.id_vs_scales_element),
                                                 (SELECT get_vsum_val_min(i_lang            => i_lang,
                                                                          i_prof            => i_prof,
                                                                          i_id_vital_sign   => d.id_vital_sign,
                                                                          i_id_unit_measure => d.id_unit_measure_vsr,
                                                                          i_id_institution  => d.id_institution,
                                                                          i_id_software     => d.id_software,
                                                                          i_age             => l_age)
                                                    FROM dual)) val_min,
                                             nvl(pk_vital_sign.get_vs_scale_max_value(d.id_vs_scales_element),
                                                 (SELECT get_vsum_val_max(i_lang            => i_lang,
                                                                          i_prof            => i_prof,
                                                                          i_id_vital_sign   => d.id_vital_sign,
                                                                          i_id_unit_measure => d.id_unit_measure_vsr,
                                                                          i_id_institution  => d.id_institution,
                                                                          i_id_software     => d.id_software,
                                                                          i_age             => l_age)
                                                    FROM dual)) val_max,
                                             d.color_grafh,
                                             d.color_text,
                                             (SELECT pk_prof_utils.get_prof_speciality(i_lang,
                                                                                       profissional(d.id_prof_read,
                                                                                                    i_prof.institution,
                                                                                                    i_prof.software))
                                                FROM dual) spec_prof,
                                             CASE
                                                  WHEN d.id_epis_triage IS NOT NULL THEN
                                                   l_triage
                                                  ELSE
                                                   NULL
                                              END label_triage,
                                             d.dt_vital_sign_read dt_vs_read_tstz
                                        FROM (SELECT c.id_vital_sign,
                                                     c.vital_sign_scale,
                                                     (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                                        FROM unit_measure um
                                                       WHERE um.id_unit_measure =
                                                             decode(c.vital_sign_scale,
                                                                    NULL,
                                                                    c.id_unit_measure_vsr,
                                                                    (SELECT vsse.id_unit_measure
                                                                       FROM vital_sign_scales_element vsse
                                                                      WHERE vsse.id_vital_sign_scales = c.vital_sign_scale
                                                                        AND rownum = 1))) AS desc_unit_measure,
                                                     c.dt_registry,
                                                     c.dt_vital_sign_read,
                                                     c.value,
                                                     c.id_vital_sign_read,
                                                     c.id_unit_measure_vsr,
                                                     c.flg_state,
                                                     c.id_prof_read,
                                                     c.rank,
                                                     c.flg_fill_type,
                                                     c.id_epis_triage,
                                                     c.id_vital_sign_desc,
                                                     c.id_unit_measure_vsi,
                                                     c.relation_domain,
                                                     c.id_episode,
                                                     c.code_vs_short_desc,
                                                     decode(i_flg_show_previous_values,
                                                            pk_alert_constant.g_no,
                                                            NULL,
                                                            get_vs_value(i_lang                => i_lang,
                                                                         i_prof                => i_prof,
                                                                         i_id_patient          => l_id_patient,
                                                                         i_id_episode          => c.id_episode,
                                                                         i_id_vital_sign       => c.id_vital_sign,
                                                                         i_id_vital_sign_desc  => c.id_vital_sign_desc,
                                                                         i_dt_vital_sign_read  => c.dt_vital_sign_read,
                                                                         i_id_unit_measure_vsr => c.id_unit_measure_vsr,
                                                                         i_id_unit_measure_vsi => c.id_unit_measure_vsi,
                                                                         i_value               => c.value,
                                                                         i_decimal_symbol      => l_decimal_symbol,
                                                                         i_relation_domain     => c.relation_domain,
                                                                         i_dt_registry         => c.dt_registry)) value_desc,
                                                     c.id_software,
                                                     c.id_institution,
                                                     c.id_vs_scales_element,
                                                     c.color_grafh,
                                                     c.color_text
                                                FROM TABLE(pk_vital_sign_core.get_vital_sign_records(i_lang               => i_lang,
                                                                                                     i_prof               => i_prof,
                                                                                                     i_flg_view           => i_flg_view,
                                                                                                     i_all_details        => i_all_details,
                                                                                                     i_scope              => i_scope,
                                                                                                     i_scope_type         => i_scope_type,
                                                                                                     i_interval           => i_interval,
                                                                                                     i_dt_begin           => i_dt_begin,
                                                                                                     i_dt_end             => i_dt_end,
                                                                                                     i_flg_use_soft_inst  => i_flg_use_soft_inst,
                                                                                                     i_flg_show_relations => i_flg_show_relations)) c) d
                                       ORDER BY CASE
                                                     WHEN i_interval IS NOT NULL THEN
                                                      d.dt_vital_sign_read
                                                     ELSE
                                                      NULL
                                                 END DESC NULLS LAST,
                                                rank ASC NULLS LAST,
                                                d.vital_sign_scale ASC NULLS LAST,
                                                d.id_vital_sign ASC,
                                                d.dt_vital_sign_read ASC NULLS LAST) aux
                               WHERE (CASE
                                         WHEN i_flg_screen = g_flg_screen_graph
                                              AND (aux.val_max IS NULL OR aux.val_min IS NULL --OR aux.color_grafh IS NULL
                                              ) THEN
                                          0
                                         ELSE
                                          1
                                     END) = 1)
        LOOP
            PIPE ROW(l_rec_vs_grid);
        END LOOP;
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN;
    END tf_vital_sign_grid;
    /************************************************************************************************************
    * This function returns the vital signs record scheme type
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  View type
    * @param      i_flg_screen                Screen type
    * @param      i_all_details               View all detail Y/N
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_interval                  Interval to filter
    * @param      i_dt_begin                  Date begin of the interval (Last X records, Last X my records)
    * @param      i_dt_end                    Date end of the interval (Last X records, Last X my records)
    * @return     Table with records t_tbl_vs
    *
    * @author     Anna Kurowska
    * @version    2.7.1
    * @since      2017/03/16
    ***********************************************************************************************************/
    FUNCTION get_vital_sign_records
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_view           IN vs_soft_inst.flg_view%TYPE,
        i_all_details        IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2,
        i_interval           IN VARCHAR2 DEFAULT NULL,
        i_dt_begin           IN VARCHAR2 DEFAULT NULL,
        i_dt_end             IN VARCHAR2 DEFAULT NULL,
        i_flg_use_soft_inst  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes, -- flg inficating if get_vital_sign_records uses vs_soft_inst to retrieve records
        i_flg_include_fetus  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_relations IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_vs IS
        l_tbl_vs     t_tbl_vs;
        l_error      t_error_out;
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_dt_begin   TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_dt_end     TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_function_name CONSTANT obj_name := 'TF_VITAL_SIGN_RECORDS';
        l_dbg_msg    debug_msg;
        l_nr_records PLS_INTEGER := NULL;
        l_id_prof    professional.id_professional%TYPE := NULL;
        l_fetus      NUMBER := 0;
    BEGIN
    
        IF i_flg_include_fetus = pk_alert_constant.g_yes
        THEN
            l_fetus := 1;
        END IF;
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => l_error)
        THEN
            RAISE g_exception;
        END IF;
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => l_error)
        THEN
            RAISE g_exception;
        END IF;
        -- Convert end date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => l_error)
        THEN
            RAISE g_exception;
        END IF;
        IF i_interval IS NOT NULL
        THEN
            g_error := 'CALCULATE THE INTERVAL FOR DATES';
            IF NOT get_interval_data(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_interval   => i_interval,
                                     io_dt_begin  => l_dt_begin,
                                     io_dt_end    => l_dt_end,
                                     o_nr_records => l_nr_records,
                                     o_id_prof    => l_id_prof,
                                     o_error      => l_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
        SELECT t_rec_vs(d.id_vital_sign,
                        d.dt_registry,
                        d.dt_vital_sign_read,
                        d.value,
                        d.id_vital_sign_read,
                        d.id_unit_measure_vsr,
                        d.flg_state,
                        d.id_prof_read,
                        d.rank,
                        d.flg_fill_type,
                        d.id_epis_triage,
                        d.id_vital_sign_desc,
                        d.id_unit_measure_vsi,
                        d.relation_domain,
                        d.id_episode,
                        d.vital_sign_scale,
                        d.code_vs_short_desc,
                        d.id_software,
                        d.id_institution,
                        d.id_vs_scales_element,
                        d.color_grafh,
                        d.color_text,
                        id_fetus_number)
          BULK COLLECT
          INTO l_tbl_vs
          FROM (SELECT row_number() over(PARTITION BY c.rn2 ORDER BY c.dt_vital_sign_read DESC NULLS LAST) rn,
                       row_number() over(PARTITION BY c.id_vital_sign, c.dt_vital_sign_read, c.vital_sign_scale ORDER BY c.dt_registry DESC NULLS LAST) rn3,
                       c.rn2,
                       c.id_vital_sign,
                       c.dt_registry,
                       c.dt_vital_sign_read,
                       c.value,
                       c.id_vital_sign_read,
                       c.id_unit_measure_vsr,
                       c.flg_state,
                       c.id_prof_read,
                       c.rank,
                       c.flg_fill_type,
                       c.id_epis_triage,
                       c.id_vital_sign_desc,
                       c.id_unit_measure_vsi,
                       c.relation_domain,
                       c.id_episode,
                       c.vital_sign_scale,
                       c.code_vs_short_desc,
                       c.id_software,
                       c.id_institution,
                       c.id_vs_scales_element,
                       c.color_grafh,
                       c.color_text,
                       c.id_fetus_number
                  FROM (SELECT row_number() over(PARTITION BY a.id_vital_sign ORDER BY a.dt_vital_sign_read, a.id_vs_scales_element DESC NULLS LAST, id_fetus_number) rn2,
                               a.id_vital_sign,
                               a.dt_registry,
                               a.dt_vital_sign_read,
                               a.value,
                               a.id_vital_sign_read,
                               a.id_unit_measure_vsr,
                               a.flg_state,
                               a.id_prof_read,
                               a.rank,
                               a.flg_fill_type,
                               a.id_epis_triage,
                               a.id_vital_sign_desc,
                               a.id_unit_measure_vsi,
                               NULL relation_domain,
                               a.id_episode,
                               (SELECT pk_vital_sign.get_vs_scale(a.id_vs_scales_element)
                                  FROM dual) vital_sign_scale,
                               a.code_vs_short_desc,
                               a.id_software,
                               a.id_institution,
                               a.id_vs_scales_element,
                               a.color_grafh,
                               a.color_text,
                               id_fetus_number
                          FROM (SELECT *
                                  FROM (SELECT /*+ use_nl(vsr epi)*/
                                         vsr.id_vital_sign,
                                         vs.code_vs_short_desc,
                                         vsr.dt_registry,
                                         vsr.dt_vital_sign_read_tstz AS dt_vital_sign_read,
                                         vsr.id_vital_sign_desc,
                                         vsr.id_episode,
                                         vsr.value,
                                         vsr.id_vital_sign_read,
                                         vsr.id_unit_measure id_unit_measure_vsr,
                                         CASE
                                              WHEN i_flg_use_soft_inst = pk_alert_constant.g_no THEN
                                               vsr.id_unit_measure
                                              ELSE
                                               vsi.id_unit_measure
                                          END id_unit_measure_vsi,
                                         vsr.flg_state,
                                         vsr.id_prof_read,
                                         vsi.rank,
                                         vs.flg_fill_type,
                                         vsr.id_vs_scales_element,
                                         vsr.id_epis_triage,
                                         nvl(vsi.id_software, nvl2(i_interval, vsr.id_software_read, i_prof.software)) id_software,
                                         nvl(vsi.id_institution,
                                             nvl2(i_interval, vsr.id_institution_read, i_prof.institution)) id_institution,
                                         nvl(vsi.color_grafh, vs.color_graph) color_grafh,
                                         nvl(vsi.color_text, pk_alert_constant.g_color_white) color_text,
                                         (SELECT pk_delivery.get_id_fetus_from_vs_read(id_vital_sign_read)
                                            FROM dual
                                           WHERE i_flg_include_fetus = pk_alert_constant.g_yes) id_fetus_number
                                          FROM vital_sign_read vsr
                                         INNER JOIN (SELECT *
                                                      FROM episode e
                                                     WHERE e.id_episode = l_id_episode
                                                       AND e.id_patient = l_id_patient
                                                       AND i_scope_type = pk_alert_constant.g_scope_type_episode
                                                    UNION ALL
                                                    SELECT *
                                                      FROM episode e
                                                     WHERE e.id_patient = l_id_patient
                                                       AND i_scope_type = pk_alert_constant.g_scope_type_patient
                                                    UNION ALL
                                                    SELECT *
                                                      FROM episode e
                                                     WHERE e.id_visit = l_id_visit
                                                       AND e.id_patient = l_id_patient
                                                       AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                                            ON vsr.id_episode = epi.id_episode
                                          JOIN vital_sign vs
                                            ON vsr.id_vital_sign = vs.id_vital_sign
                                          LEFT JOIN vs_soft_inst vsi
                                            ON vsi.id_vital_sign = vs.id_vital_sign
                                           AND vsi.id_software = nvl2(i_interval, vsr.id_software_read, i_prof.software)
                                           AND vsi.id_institution =
                                               nvl2(i_interval, vsr.id_institution_read, i_prof.institution)
                                           AND ((vsi.flg_view = i_flg_view AND i_flg_view IS NOT NULL) OR
                                               ((i_flg_view IS NULL OR vsi.rank IS NOT NULL)))
                                         WHERE ((l_id_prof IS NULL) OR
                                               (l_id_prof IS NOT NULL AND vsr.id_prof_read = l_id_prof))
                                           AND ((l_dt_begin IS NULL) OR
                                               (l_dt_begin IS NOT NULL AND vsr.dt_vital_sign_read_tstz >= l_dt_begin))
                                           AND ((l_dt_end IS NULL) OR
                                               (l_dt_end IS NOT NULL AND vsr.dt_vital_sign_read_tstz <= l_dt_end))
                                           AND NOT EXISTS
                                         (SELECT 1
                                                  FROM vital_sign_relation vr
                                                 WHERE vsr.id_vital_sign = vr.id_vital_sign_detail
                                                   AND vr.relation_domain IN
                                                       (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                                                   AND vr.flg_available = pk_alert_constant.g_yes
                                                   AND i_flg_view != g_flg_view_cda
                                                   AND i_flg_show_relations <> pk_alert_constant.g_yes)
                                           AND (((i_all_details = pk_alert_constant.g_yes) AND (i_interval IS NULL)) OR
                                               vsr.flg_state = pk_alert_constant.g_active)
                                           AND (CASE
                                                   WHEN vsr.flg_state = pk_alert_constant.g_cancelled THEN
                                                    (SELECT get_vsr_cancel(vsr.id_vital_sign,
                                                                           vsr.dt_vital_sign_read_tstz,
                                                                           vsr.id_patient)
                                                       FROM dual)
                                                   ELSE
                                                    vsr.id_vital_sign_read
                                               END) = vsr.id_vital_sign_read
                                           AND (EXISTS (SELECT 1
                                                          FROM vs_soft_inst vsi
                                                         WHERE vsi.id_vital_sign = vs.id_vital_sign
                                                           AND vsi.id_software =
                                                               nvl2(i_interval, vsr.id_software_read, i_prof.software)
                                                           AND vsi.id_institution =
                                                               nvl2(i_interval, vsr.id_institution_read, i_prof.institution)
                                                           AND vsi.flg_view = i_flg_view
                                                           AND (i_flg_use_soft_inst = pk_alert_constant.g_yes)) OR
                                                i_flg_use_soft_inst = pk_alert_constant.g_no OR
                                                i_flg_show_relations = pk_alert_constant.g_yes)
                                           AND rownum > 0) t
                                 WHERE pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read) IN (0, l_fetus)) a
                        
                        UNION ALL
                        SELECT row_number() over(PARTITION BY b.id_vital_sign, id_vs_scales_element ORDER BY b.dt_vital_sign_read DESC NULLS LAST, id_fetus_number) rn2,
                               b.id_vital_sign,
                               b.dt_registry,
                               b.dt_vital_sign_read,
                               b.value,
                               b.id_vital_sign_read,
                               b.id_unit_measure_vsr,
                               b.flg_state,
                               b.id_prof_read,
                               b.rank,
                               b.flg_fill_type,
                               b.id_epis_triage,
                               b.id_vital_sign_desc,
                               b.id_unit_measure_vsi,
                               b.relation_domain,
                               b.id_episode,
                               b.id_vs_scales_element,
                               b.code_vs_short_desc,
                               b.id_software,
                               b.id_institution,
                               b.id_vs_scales_element,
                               b.color_grafh,
                               b.color_text,
                               id_fetus_number
                          FROM (SELECT *
                                  FROM (SELECT /*+ use_nl(vsr epi)*/
                                         vr.id_vital_sign_parent id_vital_sign,
                                         vs.code_vs_short_desc,
                                         vsr.dt_registry,
                                         vsr.dt_vital_sign_read_tstz AS dt_vital_sign_read,
                                         NULL id_vital_sign_desc,
                                         vr.relation_domain,
                                         vsr.id_episode,
                                         NULL AS VALUE,
                                         vsr.id_vital_sign_read,
                                         vsr.id_unit_measure id_unit_measure_vsr,
                                         NULL id_unit_measure_vsi,
                                         vsr.flg_state,
                                         vsr.id_prof_read,
                                         vsi.rank,
                                         vs.flg_fill_type,
                                         vsr.id_vs_scales_element,
                                         vsr.id_epis_triage,
                                         nvl(vsi.id_software, nvl2(i_interval, vsr.id_software_read, i_prof.software)) id_software,
                                         nvl(vsi.id_institution,
                                             nvl2(i_interval, vsr.id_institution_read, i_prof.institution)) id_institution,
                                         nvl(vsi.color_grafh, vs.color_graph) color_grafh,
                                         nvl(vsi.color_text, pk_alert_constant.g_color_white) color_text,
                                         (SELECT pk_delivery.get_id_fetus_from_vs_read(id_vital_sign_read)
                                            FROM dual
                                           WHERE i_flg_include_fetus = pk_alert_constant.g_yes) id_fetus_number
                                          FROM vital_sign_read vsr
                                         INNER JOIN (SELECT *
                                                      FROM episode e
                                                     WHERE e.id_episode = l_id_episode
                                                       AND e.id_patient = l_id_patient
                                                       AND i_scope_type = pk_alert_constant.g_scope_type_episode
                                                    UNION ALL
                                                    SELECT *
                                                      FROM episode e
                                                     WHERE e.id_patient = l_id_patient
                                                       AND i_scope_type = pk_alert_constant.g_scope_type_patient
                                                    UNION ALL
                                                    SELECT *
                                                      FROM episode e
                                                     WHERE e.id_visit = l_id_visit
                                                       AND e.id_patient = l_id_patient
                                                       AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                                            ON vsr.id_episode = epi.id_episode
                                          JOIN vital_sign_relation vr
                                            ON vsr.id_vital_sign = vr.id_vital_sign_detail
                                          JOIN vital_sign vs
                                            ON vr.id_vital_sign_parent = vs.id_vital_sign
                                          LEFT JOIN vs_soft_inst vsi
                                            ON vsi.id_vital_sign = vs.id_vital_sign
                                           AND vsi.id_software = nvl2(i_interval, vsr.id_software_read, i_prof.software)
                                           AND vsi.id_institution =
                                               nvl2(i_interval, vsr.id_institution_read, i_prof.institution)
                                           AND ((vsi.flg_view = i_flg_view AND i_flg_view IS NOT NULL) OR
                                               i_flg_view IS NULL)
                                         WHERE ((l_id_prof IS NULL) OR
                                               (l_id_prof IS NOT NULL AND vsr.id_prof_read = l_id_prof))
                                           AND ((l_dt_begin IS NULL) OR
                                               (l_dt_begin IS NOT NULL AND vsr.dt_vital_sign_read_tstz >= l_dt_begin))
                                           AND ((l_dt_end IS NULL) OR
                                               (l_dt_end IS NOT NULL AND vsr.dt_vital_sign_read_tstz <= l_dt_end))
                                           AND (((i_all_details = pk_alert_constant.g_yes) AND (i_interval IS NULL)) OR
                                               vsr.flg_state = pk_alert_constant.g_active)
                                           AND vr.relation_domain IN
                                               (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                                           AND vr.flg_available = pk_alert_constant.g_yes
                                           AND (CASE
                                                   WHEN vsr.flg_state = pk_alert_constant.g_cancelled THEN
                                                    (SELECT get_vsr_cancel(vsr.id_vital_sign,
                                                                           vsr.dt_vital_sign_read_tstz,
                                                                           vsr.id_patient)
                                                       FROM dual)
                                                   ELSE
                                                    vsr.id_vital_sign_read
                                               END) = vsr.id_vital_sign_read
                                           AND vr.rank =
                                               (SELECT MIN(v.rank)
                                                  FROM vital_sign_relation v
                                                 WHERE vr.id_vital_sign_parent = v.id_vital_sign_parent
                                                   AND vr.flg_available = pk_alert_constant.g_yes
                                                   AND vr.relation_domain != pk_alert_constant.g_vs_rel_percentile)
                                           AND (EXISTS (SELECT 1
                                                          FROM vs_soft_inst vsi
                                                         WHERE vsi.id_vital_sign = vs.id_vital_sign
                                                           AND vsi.id_software =
                                                               nvl2(i_interval, vsr.id_software_read, i_prof.software)
                                                           AND vsi.id_institution =
                                                               nvl2(i_interval, vsr.id_institution_read, i_prof.institution)
                                                           AND vsi.flg_view = i_flg_view
                                                           AND i_flg_use_soft_inst = pk_alert_constant.g_yes) OR
                                                i_flg_use_soft_inst = pk_alert_constant.g_no)
                                           AND rownum > 0) t
                                 WHERE pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read) IN (0, l_fetus)) b) c) d
         WHERE (l_nr_records IS NULL OR ((d.rn <= l_nr_records AND d.rn2 = 1) OR d.rn2 != 1))
           AND d.rn3 = 1;
    
        RETURN l_tbl_vs;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_vital_sign_records;
    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient and number of moments of vital sign registration
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_flg_screen                Screen type
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_interval                  Interval to filter
    * @param      i_dt_begin                  Date begin of the interval (Last X records, Last X my records)
    * @param      i_dt_end                    Date end of the interval (Last X records, Last X my records)
    * @param      o_time                      Returns time collumns
    * @param      o_sign_v                    Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/25
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_vs_grid_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_view          IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen        IN VARCHAR2,
        i_scope             IN NUMBER DEFAULT NULL,
        i_scope_type        IN VARCHAR2 DEFAULT NULL,
        i_interval          IN VARCHAR2 DEFAULT NULL,
        i_dt_begin          IN VARCHAR2 DEFAULT NULL,
        i_dt_end            IN VARCHAR2 DEFAULT NULL,
        i_flg_use_soft_inst IN VARCHAR2 DEFAULT pk_alert_constant.g_yes, -- flg inficating if get_vital_sign_records uses vs_soft_inst to retrieve records
        o_time              OUT pk_types.cursor_type,
        o_sign_v            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_VS_GRID_LIST';
        l_dbg_msg          debug_msg;
        l_val_vs           pk_types.cursor_type;
        l_val_vs_rec       t_rec_vs_grid;
        e_invalid_argument EXCEPTION;
        l_found_time       NUMBER(6);
        l_coll_vs_time     t_coll_vs_time := t_coll_vs_time();
        l_found_sign       NUMBER(6);
        l_coll_vs_sign     t_coll_vs_sign := t_coll_vs_sign();
    BEGIN
    
        IF (i_scope IS NOT NULL AND i_scope_type IS NOT NULL)
        THEN
            l_dbg_msg := 'open   o_val_vs';
            OPEN l_val_vs FOR
                SELECT *
                  FROM TABLE(tf_vital_sign_grid(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_flg_view          => i_flg_view,
                                                 i_flg_screen        => i_flg_screen,
                                                 i_all_details       => CASE
                                                                            WHEN i_flg_screen = g_flg_screen_graph THEN
                                                                             pk_alert_constant.g_no
                                                                            ELSE
                                                                             pk_alert_constant.g_yes
                                                                        END,
                                                 i_scope             => i_scope,
                                                 i_scope_type        => i_scope_type,
                                                 i_interval          => i_interval,
                                                 i_dt_begin          => i_dt_begin,
                                                 i_dt_end            => i_dt_end,
                                                 i_flg_use_soft_inst => i_flg_use_soft_inst));
        
            LOOP
                FETCH l_val_vs
                    INTO l_val_vs_rec;
                EXIT WHEN l_val_vs%NOTFOUND;
            
                -- get o_time
                l_found_time := 0;
                FOR i IN 1 .. l_coll_vs_time.count
                LOOP
                    IF l_coll_vs_time(i).dt_vital_sign_read = l_val_vs_rec.dt_vital_sign_read
                    THEN
                        l_coll_vs_time(i).tb_id_vital_sign_read.extend;
                        l_coll_vs_time(i).tb_id_vital_sign_read(l_coll_vs_time(i).tb_id_vital_sign_read.count) := l_val_vs_rec.id_vital_sign_read;
                        l_found_time := 1;
                        EXIT;
                    END IF;
                END LOOP;
                IF l_found_time = 0
                THEN
                    l_coll_vs_time.extend;
                    l_coll_vs_time(l_coll_vs_time.count) := t_rec_vs_time(l_val_vs_rec.dt_vital_sign_read,
                                                                          table_number(l_val_vs_rec.id_vital_sign_read));
                END IF;
            
                -- get o_sign
                l_found_sign := 0;
                FOR i IN 1 .. l_coll_vs_sign.count
                LOOP
                    IF l_coll_vs_sign(i)
                     .id_vital_sign = l_val_vs_rec.id_vital_sign
                        AND nvl(l_coll_vs_sign(i).id_vital_sign_scale, -1) = nvl(l_val_vs_rec.vital_sign_scale, -1)
                    THEN
                        l_found_sign := 1;
                        EXIT;
                    END IF;
                END LOOP;
                IF l_found_sign = 0
                THEN
                    l_coll_vs_sign.extend;
                    l_coll_vs_sign(l_coll_vs_sign.count) := t_rec_vs_sign(l_val_vs_rec.id_vital_sign,
                                                                          l_val_vs_rec.l_rank,
                                                                          l_val_vs_rec.val_min,
                                                                          l_val_vs_rec.val_max,
                                                                          l_val_vs_rec.color_grafh,
                                                                          l_val_vs_rec.color_text,
                                                                          l_val_vs_rec.desc_unit_measure,
                                                                          l_val_vs_rec.vital_sign_scale);
                END IF;
            
            END LOOP;
            CLOSE l_val_vs;
        
            OPEN o_time FOR
                SELECT aux2.dt_vital_sign_read,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, aux2.dt_vital_sign_read_tstz, i_prof) dt_read,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        aux2.dt_vital_sign_read_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_read,
                       pk_date_utils.date_year_tsz(i_lang,
                                                   aux2.dt_vital_sign_read_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) || '|' ||
                       pk_date_utils.date_daymonth_tsz(i_lang,
                                                       aux2.dt_vital_sign_read_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) || '|' ||
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        aux2.dt_vital_sign_read_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) dt_header_format,
                       get_has_notes(aux2.dt_vital_sign_read_tstz, NULL, aux2.tb_id_vital_sign_read) flg_vital_sign_has_notes
                  FROM (SELECT aux.dt_vital_sign_read,
                               aux.tb_id_vital_sign_read,
                               pk_date_utils.get_string_tstz(i_lang, i_prof, aux.dt_vital_sign_read, NULL) dt_vital_sign_read_tstz
                          FROM TABLE(l_coll_vs_time) aux) aux2
                 ORDER BY aux2.dt_vital_sign_read ASC;
        
            l_dbg_msg := 'OPEN CURSOR O_SIGN_V';
            OPEN o_sign_v FOR
                SELECT t.id_vital_sign,
                       t.name_vs,
                       t.short_name_vs,
                       t.rank,
                       t.val_min,
                       t.val_max,
                       t.color_grafh,
                       t.color_text,
                       t.desc_unit_measure,
                       t.vital_sign_scale,
                       t.vital_sign_scale_desc,
                       t.id_vital_sign         viewer_category,
                       t.name_vs               viewer_category_desc,
                       t.is_read_only
                  FROM (SELECT /*+opt_estimate (table aux rows=1)*/
                         aux.id_vital_sign,
                         pk_translation.get_translation(i_lang, vs.code_vital_sign) AS name_vs,
                         pk_translation.get_translation(i_lang, vs.code_vs_short_desc) AS short_name_vs,
                         aux.l_rank rank,
                         aux.val_min,
                         aux.val_max,
                         aux.color_grafh,
                         aux.color_text,
                         aux.desc_unit_measure,
                         aux.id_vital_sign_scale vital_sign_scale,
                         (SELECT pk_translation.get_translation(i_lang, vss.code_vital_sign_scales)
                            FROM vital_sign_scales vss
                           WHERE aux.id_vital_sign_scale = vss.id_vital_sign_scales) vital_sign_scale_desc,
                         CASE
                              WHEN aux.id_vital_sign IN (1188, 1316) THEN
                               pk_alert_constant.g_yes
                          
                              WHEN aux.id_vital_sign_scale IS NOT NULL
                                   AND count_scale_elements(i_lang,
                                                            i_prof,
                                                            NULL,
                                                            aux.id_vital_sign_scale,
                                                            NULL,
                                                            aux.id_vital_sign) = 0 THEN
                               pk_alert_constant.g_yes
                          -- validar vital_signs assessment scales
                          
                              ELSE
                               pk_alert_constant.g_no
                          END is_read_only
                          FROM TABLE(l_coll_vs_sign) aux
                          JOIN vital_sign vs
                            ON vs.id_vital_sign = aux.id_vital_sign) t
                 ORDER BY t.rank ASC NULLS LAST, t.vital_sign_scale ASC NULLS LAST, t.id_vital_sign ASC;
        
        ELSE
            pk_types.open_my_cursor(i_cursor => o_time);
            pk_types.open_my_cursor(i_cursor => o_sign_v);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_invalid_argument THEN
            BEGIN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => 'An input parameter has an unexpected value',
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_function_name,
                                                  o_error    => o_error);
                /* Open out cursors */
                pk_types.open_my_cursor(i_cursor => o_time);
                pk_types.open_my_cursor(i_cursor => o_sign_v);
            
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            
            END;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_time);
            pk_types.open_my_cursor(i_cursor => o_sign_v);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_vs_grid_list;

    /********************************************************************************************
    * Obter todas as notas dos sinais vitais associadas ao episódio
    *
    * @param i_lang             Id do idioma
    * @param i_episode          episode id
    * @param i_prof             professional, software, institution ids
    * @param i_flg_view         Posição dos sinais vitais:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param o_notes_vs         Lista das notas dos sinais vitais do episódio
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE if sucess, FALSE otherwise
    *
    * @author                   Emilia Taborda
    * @version                  1.0
    * @since                    2006/08/25
    ********************************************************************************************/
    FUNCTION get_epis_vs_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN vital_sign_read.id_episode%TYPE,
        i_prof       IN profissional,
        i_flg_view   IN vs_soft_inst.flg_view%TYPE,
        i_start_date IN VARCHAR2 DEFAULT NULL,
        i_end_date   IN VARCHAR2 DEFAULT NULL,
        o_notes_vs   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_visit CONSTANT episode.id_visit%TYPE := pk_episode.get_id_visit(i_episode => i_episode);
        l_dbg_msg debug_msg;
    
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    BEGIN
    
        IF i_start_date IS NOT NULL
        THEN
            -- Convert start date to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
        IF i_end_date IS NOT NULL
        THEN
            -- Convert end date to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
        l_dbg_msg := 'GET CURSOR O_NOTES_VS';
        OPEN o_notes_vs FOR
            SELECT DISTINCT vsr.id_vital_sign_notes,
                            vsn.notes,
                            vsn.id_professional,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, vsr.id_prof_read) name_prof,
                            pk_prof_utils.get_spec_signature(i_lang,
                                                             i_prof,
                                                             vsr.id_prof_read,
                                                             vsr.dt_vital_sign_read_tstz,
                                                             vsr.id_episode) desc_speciality,
                            pk_date_utils.date_char_tsz(i_lang, vsn.dt_notes_tstz, i_prof.institution, i_prof.software) date_notes,
                            pk_date_utils.date_send_tsz(i_lang, vsn.dt_notes_tstz, i_prof) dt_notes
              FROM vital_sign_read vsr, vital_sign_notes vsn, episode epi
             WHERE epi.id_visit = l_id_visit
               AND vsr.id_episode = epi.id_episode
                  --AND epi.flg_status != pk_alert_constant.g_epis_status_cancel
               AND vsr.id_vital_sign_notes = vsn.id_vital_sign_notes
               AND vsr.flg_state = pk_alert_constant.g_active
               AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
               AND EXISTS (SELECT 1
                      FROM vs_soft_inst vsi
                     WHERE vsi.id_vital_sign = vsr.id_vital_sign
                       AND vsi.id_institution = i_prof.institution
                       AND vsi.id_software = i_prof.software
                       AND vsi.flg_view = i_flg_view)
            UNION -- PRESSãO ARTERIAL
            SELECT DISTINCT vsr.id_vital_sign_notes,
                            vsn.notes,
                            vsn.id_professional,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, vsr.id_prof_read) name_prof,
                            pk_prof_utils.get_spec_signature(i_lang,
                                                             i_prof,
                                                             vsr.id_prof_read,
                                                             vsr.dt_vital_sign_read_tstz,
                                                             vsr.id_episode) desc_speciality,
                            pk_date_utils.date_char_tsz(i_lang, vsn.dt_notes_tstz, i_prof.institution, i_prof.software) date_notes,
                            pk_date_utils.date_send_tsz(i_lang, vsn.dt_notes_tstz, i_prof) dt_notes
              FROM vital_sign_read vsr, vital_sign_relation vsre, vital_sign vs, vital_sign_notes vsn, episode epi
             WHERE epi.id_visit = l_id_visit
               AND vsr.id_episode = epi.id_episode
                  --AND epi.flg_status != pk_alert_constant.g_epis_status_cancel
               AND vsre.id_vital_sign_parent = vs.id_vital_sign
               AND vsr.flg_state = pk_alert_constant.g_active
               AND vsre.id_vital_sign_detail = vsr.id_vital_sign
               AND vsre.relation_domain = pk_alert_constant.g_vs_rel_conc
               AND vsre.flg_available = pk_alert_constant.g_yes
               AND vsr.id_vital_sign_notes = vsn.id_vital_sign_notes
               AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
               AND EXISTS (SELECT 1
                      FROM vs_soft_inst vsi
                     WHERE vsi.id_vital_sign IN (vsr.id_vital_sign, vsre.id_vital_sign_parent)
                       AND vsi.id_institution = i_prof.institution
                       AND vsi.id_software = i_prof.software
                       AND vsi.flg_view = i_flg_view)
            UNION
            SELECT DISTINCT vsr.id_vital_sign_notes,
                            vsn.notes,
                            vsn.id_professional,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, vsr.id_prof_read) name_prof,
                            pk_prof_utils.get_spec_signature(i_lang,
                                                             i_prof,
                                                             vsr.id_prof_read,
                                                             vsr.dt_vital_sign_read_tstz,
                                                             vsr.id_episode) desc_speciality,
                            pk_date_utils.date_char_tsz(i_lang, vsn.dt_notes_tstz, i_prof.institution, i_prof.software) date_notes,
                            pk_date_utils.date_send_tsz(i_lang, vsn.dt_notes_tstz, i_prof) dt_notes
              FROM vital_sign_desc     vsd,
                   vital_sign_relation vr,
                   vital_sign_read     vsr,
                   vital_sign          vs,
                   vital_sign_notes    vsn,
                   episode             epi
             WHERE epi.id_visit = l_id_visit
               AND vsr.id_episode = epi.id_episode
                  --AND epi.flg_status != pk_alert_constant.g_epis_status_cancel
               AND vsr.flg_state = pk_alert_constant.g_active
               AND vr.id_vital_sign_detail = vsr.id_vital_sign
               AND vr.relation_domain = pk_alert_constant.g_vs_rel_sum
               AND vr.flg_available = pk_alert_constant.g_yes
               AND vsd.id_vital_sign_desc = vsr.id_vital_sign_desc
               AND vr.id_vital_sign_parent = vs.id_vital_sign
               AND vr.relation_domain = pk_alert_constant.g_vs_rel_sum
               AND vsr.id_vital_sign_notes = vsn.id_vital_sign_notes
               AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
               AND EXISTS (SELECT 1
                      FROM vs_soft_inst vsi
                     WHERE vsi.id_vital_sign IN (vsr.id_vital_sign, vr.id_vital_sign_parent)
                       AND vsi.id_institution = i_prof.institution
                       AND vsi.id_software = i_prof.software
                       AND vsi.flg_view = i_flg_view)
               AND (l_start_date IS NULL OR vsr.dt_vital_sign_read_tstz >= l_start_date)
               AND (l_end_date IS NULL OR vsr.dt_vital_sign_read_tstz < l_end_date)
             ORDER BY dt_notes DESC;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_VS_NOTES',
                                              o_error);
            pk_types.open_my_cursor(o_notes_vs);
            RETURN FALSE;
    END get_epis_vs_notes;

    /************************************************************************************************************
    * This function returns all cancelled vital sign reads in a visit
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_episode             Vital sign read ID
    * @param        o_vsr_history            History Info
    * @param        o_error                  Error
    *
    * @author                                Sergio Dias
    * @version                               2.6.1.0.1
    * @since                                 27-Apr-2011
    *
    * @dependencies                          REPORTS
    ************************************************************************************************************/
    FUNCTION get_visit_cancelled_vital_sign
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        o_vsr_cancelled OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_VISIT_CANCELLED_VITAL_SIGN';
        l_dbg_msg debug_msg;
        l_decimal_symbol CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software);
    BEGIN
    
        l_dbg_msg := 'get cancelled vital signs for a visit. id_episode = ' || i_id_episode;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
    
        OPEN o_vsr_cancelled FOR
            SELECT id_vital_sign_read,
                   id_episode,
                   pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason,
                   id_prof_cancel,
                   VALUE,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof_cancel) AS prof_cancel_desc,
                   notes_cancel,
                   dt_cancel_tstz data_cancel,
                   pk_date_utils.date_char_tsz(i_lang, dt_cancel_tstz, i_prof.institution, i_prof.software) AS date_cancel_desc
              FROM (
                    -- Simple Vital Signs
                    SELECT vseap.id_vital_sign,
                            vseap.value,
                            vseap.id_vital_sign_read,
                            id_prof_cancel,
                            dt_cancel_tstz,
                            id_cancel_reason,
                            notes_cancel,
                            id_episode
                      FROM (SELECT vsr.id_vital_sign,
                                    nvl2(vsr.id_vital_sign_desc,
                                         pk_vital_sign.get_vsd_desc(i_lang, vsr.id_vital_sign_desc, vsr.id_patient),
                                         pk_utils.to_str(vsr.value, l_decimal_symbol)) AS VALUE,
                                    vsr.id_unit_measure,
                                    vsr.id_vs_scales_element,
                                    vsr.id_prof_read,
                                    vsr.dt_vital_sign_read_tstz,
                                    rank() over(PARTITION BY vsr.id_vital_sign ORDER BY vsr.dt_vital_sign_read_tstz DESC NULLS LAST) AS rank,
                                    vsr.id_vital_sign_read,
                                    vsr.id_prof_cancel,
                                    vsr.dt_cancel_tstz,
                                    vsr.id_cancel_reason,
                                    vsr.notes_cancel,
                                    vsr.id_episode
                               FROM vital_sign_read vsr
                              WHERE (vsr.id_episode = i_id_episode)
                                AND vsr.flg_state = pk_alert_constant.g_cancelled
                                AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
                                AND vsr.id_vital_sign NOT IN
                                    (SELECT vsrel.id_vital_sign_detail
                                       FROM vital_sign_relation vsrel
                                      WHERE vsrel.flg_available = pk_alert_constant.g_yes
                                        AND vsrel.relation_domain != pk_alert_constant.g_vs_rel_percentile)) vseap
                     WHERE vseap.rank = 1
                    
                    UNION ALL
                    
                    -- Composed Vital Signs
                    SELECT veaval.id_vital_sign_parent AS id_vital_sign,
                            CASE veaval.relation_domain
                                WHEN pk_alert_constant.g_vs_rel_conc THEN
                                 pk_vital_sign.get_bloodpressure_value(veaval.id_vital_sign_parent,
                                                                       veaval.id_patient,
                                                                       veaval.id_episode,
                                                                       veaval.dt_vital_sign_read_tstz,
                                                                       l_decimal_symbol)
                                WHEN pk_alert_constant.g_vs_rel_sum THEN
                                 to_char(pk_vital_sign.get_glasgowtotal_value(veaval.id_vital_sign_parent,
                                                                              veaval.id_patient,
                                                                              veaval.id_episode,
                                                                              veaval.dt_vital_sign_read_tstz))
                                ELSE
                                 NULL
                            END AS VALUE,
                            veaval.id_vital_sign_read,
                            veaval.id_prof_cancel,
                            veaval.dt_cancel_tstz,
                            veaval.id_cancel_reason,
                            veaval.notes_cancel,
                            veaval.id_episode
                      FROM (SELECT id_vital_sign_parent,
                                    id_vital_sign_detail,
                                    relation_domain,
                                    id_patient,
                                    id_episode,
                                    id_prof_read,
                                    dt_vital_sign_read_tstz,
                                    rank,
                                    id_vital_sign_read,
                                    value_detail,
                                    id_prof_cancel,
                                    dt_cancel_tstz,
                                    id_cancel_reason,
                                    notes_cancel
                               FROM (SELECT DISTINCT vsrel.id_vital_sign_parent,
                                                     vsrel.id_vital_sign_detail,
                                                     vsrel.relation_domain,
                                                     vsr.id_patient,
                                                     vsr.id_episode,
                                                     vsr.id_prof_read,
                                                     vsr.dt_vital_sign_read_tstz,
                                                     rank() over(PARTITION BY vsrel.id_vital_sign_parent ORDER BY vsr.id_vital_sign_read DESC NULLS LAST) AS rank,
                                                     vsr.id_vital_sign_read,
                                                     vsr.value value_detail,
                                                     vsr.dt_cancel_tstz,
                                                     vsr.id_prof_cancel,
                                                     vsr.id_cancel_reason,
                                                     vsr.notes_cancel
                                       FROM vital_sign_read vsr
                                      INNER JOIN vital_sign_relation vsrel
                                         ON vsr.id_vital_sign = vsrel.id_vital_sign_detail
                                      WHERE vsrel.relation_domain IN
                                            (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                                        AND (vsr.id_episode = i_id_episode)
                                        AND vsr.flg_state = pk_alert_constant.g_cancelled
                                        AND vsrel.flg_available = pk_alert_constant.g_yes
                                        AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0)
                              WHERE (rank = 1)) veaval) vs_info
              LEFT JOIN cancel_reason cr
                ON cr.id_cancel_reason = vs_info.id_cancel_reason;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_visit_cancelled_vital_sign;

    /************************************************************************************************************
    * This function returns history for a vital sign
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_episode             Vital Sign read ID
    * @param        o_vsr_history            History information
    * @param        o_error                  List of changed columns
    *
    * @author                                Sergio Dias
    * @version                               2.6.1.0.1
    * @since                                 27-Apr-2011
    *
    * @dependencies                          REPORTS
    ************************************************************************************************************/
    FUNCTION get_visit_vital_sign_read_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        o_vsr_history OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_VISIT_VITAL_SIGN_READ_HIST';
        l_dbg_msg debug_msg;
        l_decimal_symbol CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software);
    BEGIN
    
        l_dbg_msg := 'get history records for a visit. id_episode = ' || i_id_episode;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
    
        OPEN o_vsr_history FOR
            SELECT id_vital_sign_read,
                   VALUE VALUE,
                   pk_vital_sign.get_vital_sign_unit_measure(i_lang, id_unit_measure, id_vs_scales_element) AS desc_unit_measure,
                   pk_date_utils.date_char_tsz(i_lang, dt_vital_sign_read_tstz, i_prof.institution, i_prof.software) AS date_read,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof_read) AS prof_name,
                   pk_date_utils.date_char_tsz(i_lang, dt_registry, i_prof.institution, i_prof.software) AS dt_registry,
                   flg_value_changed,
                   flg_dt_vs_read_changed,
                   flg_id_prof_changed,
                   flg_id_unit_changed,
                   dt_vital_sign_read_tstz
              FROM (
                    -- Simple Vital Signs
                    SELECT vseap.id_vital_sign,
                            vseap.value,
                            vseap.id_vital_sign_read,
                            id_episode,
                            dt_vital_sign_read_tstz,
                            dt_registry,
                            flg_value_changed,
                            flg_dt_vs_read_changed,
                            flg_id_prof_changed,
                            flg_id_unit_changed,
                            id_prof_read,
                            id_vs_scales_element,
                            id_unit_measure
                      FROM (SELECT vsr.id_vital_sign,
                                    nvl(pk_utils.number_to_char(i_prof, vsrh.value),
                                        pk_vital_sign.get_vsd_desc(i_lang, vsrh.id_vital_sign_desc, vsr.id_patient)) AS VALUE,
                                    vsrh.id_unit_measure,
                                    vsr.id_vs_scales_element,
                                    vsrh.id_prof_read,
                                    vsrh.dt_vital_sign_read_tstz,
                                    rank() over(PARTITION BY vsr.id_vital_sign ORDER BY vsr.dt_vital_sign_read_tstz DESC NULLS LAST) AS rank,
                                    vsrh.id_vital_sign_read,
                                    vsr.id_episode,
                                    vsrh.flg_value_changed,
                                    vsrh.flg_dt_vs_read_changed,
                                    vsrh.flg_id_prof_changed,
                                    vsrh.flg_id_unit_changed,
                                    vsrh.dt_registry
                               FROM vital_sign_read_hist vsrh
                               JOIN vital_sign_read vsr
                                 ON vsr.id_vital_sign_read = vsrh.id_vital_sign_read
                              WHERE vsr.id_episode = i_id_episode
                                AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
                                AND vsr.id_vital_sign NOT IN
                                    (SELECT vsrel.id_vital_sign_detail
                                       FROM vital_sign_relation vsrel
                                      WHERE vsrel.relation_domain IN
                                            (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                                        AND vsrel.flg_available = pk_alert_constant.g_yes)) vseap
                     WHERE vseap.rank = 1
                    
                    UNION ALL
                    
                    -- Composed Vital Signs
                    SELECT veaval.id_vital_sign_parent AS id_vital_sign,
                            CASE veaval.relation_domain
                                WHEN pk_alert_constant.g_vs_rel_conc THEN
                                 pk_vital_sign.get_bloodpressure_value_hist(i_vital_sign         => veaval.id_vital_sign,
                                                                            i_vital_sign_read    => veaval.id_vital_sign_read,
                                                                            i_id_episode         => veaval.id_episode,
                                                                            i_dt_vital_sign_read => veaval.dt_vital_sign_read_tstz,
                                                                            i_dt_registry        => veaval.dt_registry,
                                                                            i_decimal_symbol     => l_decimal_symbol)
                                WHEN pk_alert_constant.g_vs_rel_sum THEN
                                 to_char(pk_vital_sign.get_glasgowtotal_value_hist(veaval.id_vital_sign_parent,
                                                                                   veaval.id_patient,
                                                                                   veaval.id_episode,
                                                                                   veaval.dt_vital_sign_read_tstz,
                                                                                   veaval.dt_registry))
                                ELSE
                                 NULL
                            END AS VALUE,
                            veaval.id_vital_sign_read,
                            veaval.id_episode,
                            dt_vital_sign_read_tstz,
                            dt_registry,
                            flg_value_changed,
                            flg_dt_vs_read_changed,
                            flg_id_prof_changed,
                            flg_id_unit_changed,
                            id_prof_read,
                            id_vs_scales_element,
                            id_unit_measure
                      FROM (SELECT id_episode,
                                    rank,
                                    id_vital_sign_read,
                                    value_detail,
                                    dt_vital_sign_read_tstz,
                                    id_patient,
                                    id_vital_sign_parent,
                                    relation_domain,
                                    flg_value_changed,
                                    flg_dt_vs_read_changed,
                                    flg_id_prof_changed,
                                    flg_id_unit_changed,
                                    dt_registry,
                                    id_prof_read,
                                    id_unit_measure,
                                    id_vs_scales_element,
                                    id_vital_sign
                               FROM (SELECT vsrel.id_vital_sign_parent,
                                            vsrel.relation_domain,
                                            vsr.id_episode,
                                            vsrh.id_unit_measure,
                                            vsrel.rank,
                                            vsr.id_patient,
                                            vsrh.id_vital_sign_read,
                                            vsrh.value value_detail,
                                            vsrh.dt_vital_sign_read_tstz,
                                            vsrh.flg_value_changed,
                                            vsrh.flg_dt_vs_read_changed,
                                            vsrh.flg_id_prof_changed,
                                            vsrh.flg_id_unit_changed,
                                            vsrh.dt_registry,
                                            vsrh.id_prof_read,
                                            vsr.id_vs_scales_element,
                                            vsr.id_vital_sign,
                                            row_number() over(PARTITION BY vsrel.id_vital_sign_parent, vsrh.dt_registry ORDER BY vsrel.rank ASC NULLS LAST) rn
                                       FROM vital_sign_read_hist vsrh
                                       JOIN vital_sign_read vsr
                                         ON vsr.id_vital_sign_read = vsrh.id_vital_sign_read
                                       JOIN vital_sign_relation vsrel
                                         ON vsr.id_vital_sign = vsrel.id_vital_sign_detail
                                      WHERE vsrel.relation_domain IN
                                            (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                                        AND vsrel.flg_available = pk_alert_constant.g_yes
                                        AND (vsr.id_episode = i_id_episode)
                                        AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0)
                              WHERE (rn = 1)) veaval);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_visit_vital_sign_read_hist;

    /********************************************************************************************
    * check vital signs conflicts (used to check if predefined tasks can be requested or not)
    *
    * @param       i_lang              preferred language id for this professional
    * @param       i_prof              professional id structure
    * @param       i_vital_signs       array of vital signs ids
    * @param       o_flg_conflict      array of vital signs conflicts indicators
    * @param       o_error             error message
    *
    * @return      boolean             true on success, otherwise false
    *
    * @author                          António Neto
    * @version                         2.6.2
    * @since                           14-Dez-2011
    *
    * @dependencies                    Order tools
    ********************************************************************************************/
    FUNCTION check_vital_signs_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_vital_signs  IN table_number,
        o_flg_conflict OUT table_table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_vs_view_v2  VARCHAR2(2 CHAR) := pk_alert_constant.g_vs_view_v2;
        l_inactive    VARCHAR2(1 CHAR) := pk_alert_constant.g_inactive;
        l_active      VARCHAR2(1 CHAR) := pk_alert_constant.g_active;
        l_institution institution.id_institution%TYPE := i_prof.institution;
        l_id_software software.id_software%TYPE := i_prof.software;
    BEGIN
        --check if there is Vital Signs defined
        IF i_vital_signs IS NOT NULL
        THEN
            g_error := 'Get vital signs status for this institution and software';
            SELECT table_varchar(vs.id_vital_sign, decode(vsi.id_vital_sign, NULL, l_inactive, l_active))
              BULK COLLECT
              INTO o_flg_conflict
              FROM (SELECT DISTINCT t.column_value id_vital_sign
                      FROM TABLE(i_vital_signs) t) vs
              LEFT OUTER JOIN vs_soft_inst vsi
                ON vs.id_vital_sign = vsi.id_vital_sign
               AND vsi.flg_view = l_vs_view_v2
               AND vsi.id_institution = l_institution
               AND vsi.id_software = l_id_software;
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
                                              i_function => 'CHECK_VITAL_SIGNS_CONFLICT',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_vital_signs_conflict;

    PROCEDURE l_______________cancel_func__(i_lang IN language.id_language%TYPE) IS
    BEGIN
        dbms_output.put_line(i_lang);
    END;

    /********************************************************************************************
    * check vital signs conflicts (used to check if predefined tasks can be requested or not)
    *
    * @param       i_lang                  Preferred language id for this professional
    * @param       i_prof                  Professional id structure
    * @param       i_episode               Episode id
    * @param       i_id_vital_sign_read    Vital sign read that should be cancelled
    * @param       i_id_cancel_reason      Cancel reason identifier
    * @param       i_notes                 Cancel notes
    * @param       o_error                 Error message
    *
    * @return      Boolean                 true on success, otherwise false
    *
    * @author                              Luís Maia
    * @version                             2.6.1.7
    * @since                               04-Jan-2011
    ********************************************************************************************/
    FUNCTION cancel_epis_vs_read
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_id_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        i_notes              IN vital_sign_read.notes_cancel%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_char VARCHAR2(1);
        tb_vsr table_number;
        tb_vs  table_number;
    
        CURSOR c_vs IS
            SELECT 'X'
              FROM vital_sign_read
             WHERE id_vital_sign_read = i_id_vital_sign_read
               AND flg_state = pk_alert_constant.g_cancelled;
    
        -- denormalization variables
        rows_vsr_out    table_varchar := table_varchar();
        e_process_event EXCEPTION;
    
        l_vs         vital_sign_read.id_vital_sign%TYPE;
        l_dt_vs_read vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_id_bmi     vital_sign_read.id_vital_sign_read%TYPE;
        l_id_bsa     vital_sign_read.id_vital_sign_read%TYPE;
    
        PROCEDURE delete_vs
        (
            i_lang                  language.id_language%TYPE,
            i_prof                  profissional,
            i_id_vital_sign_read    vital_sign_read.id_vital_sign_read%TYPE,
            i_dt_cancel_tstz        vital_sign_read.dt_cancel_tstz%TYPE,
            i_flg_state             vital_sign_read.flg_state%TYPE,
            i_id_prof_cancel        vital_sign_read.id_prof_cancel%TYPE,
            i_id_institution_cancel vital_sign_read.id_institution_cancel%TYPE,
            i_id_software_cancel    vital_sign_read.id_software_cancel%TYPE,
            i_id_cancel_reason      vital_sign_read.id_cancel_reason%TYPE,
            i_notes_cancel          vital_sign_read.notes_cancel%TYPE,
            i_notes_cancel_nin      BOOLEAN,
            io_rows_vsr             IN OUT table_varchar
        ) IS
            l_error                   t_error_out;
            l_id_vital_sign_read_hist vital_sign_read_hist.id_vital_sign_read_hist%TYPE;
        BEGIN
        
            g_error := 'CALL TO pk_vital_sign.set_vital_sign_read_hist';
            IF NOT pk_vital_sign.set_vital_sign_read_hist(i_lang                    => i_lang,
                                                          i_prof                    => i_prof,
                                                          i_id_vital_sign_read      => i_id_vital_sign_read,
                                                          i_value                   => NULL,
                                                          i_id_unit_measure         => NULL,
                                                          i_dt_vital_sign_read_tstz => NULL,
                                                          i_flg_edit_type           => pk_vital_sign.c_edit_type_cancel,
                                                          i_value_high              => NULL,
                                                          i_value_low               => NULL,
                                                          o_id_vital_sign_read_hist => l_id_vital_sign_read_hist,
                                                          o_error                   => l_error)
            THEN
                NULL;
            END IF;
        
            g_error := 'CALL TO ts_vital_sign_read.upd';
            ts_vital_sign_read.upd(id_vital_sign_read_in    => i_id_vital_sign_read,
                                   dt_cancel_tstz_in        => i_dt_cancel_tstz,
                                   flg_state_in             => i_flg_state,
                                   id_prof_cancel_in        => i_id_prof_cancel,
                                   id_institution_cancel_in => i_id_institution_cancel,
                                   id_software_cancel_in    => i_id_software_cancel,
                                   id_cancel_reason_in      => i_id_cancel_reason,
                                   notes_cancel_in          => i_notes_cancel,
                                   notes_cancel_nin         => i_notes_cancel_nin,
                                   id_edit_reason_in        => NULL,
                                   id_edit_reason_nin       => FALSE,
                                   rows_out                 => io_rows_vsr);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'VITAL_SIGN_READ',
                                          i_rowids     => io_rows_vsr,
                                          o_error      => o_error);
        
            g_error := 'call pk_api_pdms_core_in.cancel_vs_pdms';
            --notify pdms that a vital sign was cancelled
            IF NOT pk_api_pdms_core_in.cancel_vs_pdms(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_vs      => table_number(l_vs),
                                                      i_id_vs_read => table_number(i_id_vital_sign_read),
                                                      o_error      => l_error)
            THEN
            
                NULL;
            END IF;
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => pk_vital_sign.g_trs_notes_edit || i_id_vital_sign_read,
                                                  i_desc   => '',
                                                  i_module => 'VITAL_SIGN');
        
        END delete_vs;
    
    BEGIN
    
        g_error := 'GET CURSOR C_VS';
        OPEN c_vs;
        FETCH c_vs
            INTO l_char;
        g_found := c_vs%FOUND;
        CLOSE c_vs;
    
        IF g_found
        THEN
            g_error := REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'),
                               '@1',
                               pk_message.get_message(i_lang, 'MONITOR_T006'));
            raise_application_error('20001', g_error);
        END IF;
    
        -- retrieves id_vital_sign and date of registry through id_vital_read
        SELECT vsr.id_vital_sign, vsr.dt_vital_sign_read_tstz
          INTO l_vs, l_dt_vs_read
          FROM vital_sign_read vsr
         WHERE vsr.id_vital_sign_read = i_id_vital_sign_read;
    
        SELECT DISTINCT aux.id_vs
          BULK COLLECT
          INTO tb_vs
          FROM (SELECT DISTINCT id_vital_sign_parent id_vs
                  FROM vital_sign_relation vr
                 WHERE (vr.id_vital_sign_parent = l_vs OR vr.id_vital_sign_detail = l_vs)
                   AND vr.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                UNION
                SELECT DISTINCT id_vital_sign_detail id_vs
                  FROM vital_sign_relation vr
                 WHERE (vr.id_vital_sign_parent = l_vs OR vr.id_vital_sign_detail = l_vs)
                   AND vr.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                UNION
                SELECT DISTINCT vr1.id_vital_sign_detail id_vs
                  FROM vital_sign_relation vr
                  JOIN vital_sign_relation vr1
                    ON vr1.id_vital_sign_parent = vr.id_vital_sign_parent
                 WHERE vr.id_vital_sign_detail = l_vs
                   AND vr.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                   AND vr1.relation_domain != pk_alert_constant.g_vs_rel_percentile
                UNION
                SELECT l_vs id_vs
                  FROM dual) aux;
    
        SELECT vsr2.id_vital_sign_read
          BULK COLLECT
          INTO tb_vsr
          FROM vital_sign_read vsr1
          JOIN vital_sign_read vsr2
            ON vsr1.id_episode = vsr2.id_episode
           AND vsr1.dt_vital_sign_read_tstz = vsr2.dt_vital_sign_read_tstz
           AND vsr1.dt_registry = vsr2.dt_registry
           AND vsr1.id_prof_read = vsr2.id_prof_read
           AND vsr2.id_vital_sign IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       column_value
                                        FROM TABLE(tb_vs) t)
         WHERE vsr1.id_vital_sign_read = i_id_vital_sign_read;
    
        rows_vsr_out.delete;
        rows_vsr_out := table_varchar();
        FOR i IN 1 .. tb_vsr.count
        LOOP
        
            delete_vs(i_lang                  => i_lang,
                      i_prof                  => i_prof,
                      i_id_vital_sign_read    => tb_vsr(i),
                      i_dt_cancel_tstz        => g_sysdate_tstz,
                      i_flg_state             => pk_alert_constant.g_cancelled,
                      i_id_prof_cancel        => i_prof.id,
                      i_id_institution_cancel => i_prof.institution,
                      i_id_software_cancel    => i_prof.software,
                      i_id_cancel_reason      => i_id_cancel_reason,
                      i_notes_cancel          => i_notes,
                      i_notes_cancel_nin      => FALSE,
                      io_rows_vsr             => rows_vsr_out);
        END LOOP;
        -- CHAMAR PROCEDIMENTO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
        /*
         t_data_gov_mnt.process_update(i_lang       => i_lang,
                                       i_prof       => i_prof,
                                       i_table_name => 'VITAL_SIGN_READ',
                                       i_rowids     => rows_vsr_out,
                                       o_error      => o_error);
        */
    
        -----------------------------------------------------------------
        -- try to cancel percentile vital sign (internally it verifies if it exists)
        IF NOT pk_percentile.cancel_percentile_vs(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_id_vital_sign_read => i_id_vital_sign_read,
                                                  o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -----------------------------------------------------------------
        -- if vital sign is Height or Weight
        IF l_vs IN (pk_vital_sign.g_vs_height, pk_vital_sign.g_vs_weight)
        THEN
            BEGIN
                --cancel BMI calculation
                -- retrieves id_vital_read through date of registry
                SELECT vsr.id_vital_sign_read
                  INTO l_id_bmi
                  FROM vital_sign_read vsr
                 WHERE vsr.dt_vital_sign_read_tstz = l_dt_vs_read
                   AND vsr.id_vital_sign = pk_vital_sign.g_vs_bmi
                   AND vsr.flg_state != pk_vital_sign.c_flg_status_cancelled;
            
                rows_vsr_out.delete;
                rows_vsr_out := table_varchar();
                --
                delete_vs(i_lang                  => i_lang,
                          i_prof                  => i_prof,
                          i_id_vital_sign_read    => l_id_bmi,
                          i_dt_cancel_tstz        => g_sysdate_tstz,
                          i_flg_state             => pk_alert_constant.g_cancelled,
                          i_id_prof_cancel        => i_prof.id,
                          i_id_institution_cancel => i_prof.institution,
                          i_id_software_cancel    => i_prof.software,
                          i_id_cancel_reason      => i_id_cancel_reason,
                          i_notes_cancel          => i_notes,
                          i_notes_cancel_nin      => FALSE,
                          io_rows_vsr             => rows_vsr_out);
            
                -- try to cancel percentile bmi (internally it verifies if it exists)
                IF NOT pk_percentile.cancel_percentile_vs(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_id_vital_sign_read => l_id_bmi,
                                                          o_error              => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                --cancel BSA calculation
                SELECT vsr.id_vital_sign_read
                  INTO l_id_bsa
                  FROM vital_sign_read vsr
                 WHERE vsr.dt_vital_sign_read_tstz = l_dt_vs_read
                   AND vsr.id_vital_sign = pk_vital_sign.g_vs_bsa
                   AND vsr.flg_state != pk_vital_sign.c_flg_status_cancelled;
            
                rows_vsr_out.delete;
                rows_vsr_out := table_varchar();
                --
                delete_vs(i_lang                  => i_lang,
                          i_prof                  => i_prof,
                          i_id_vital_sign_read    => l_id_bsa,
                          i_dt_cancel_tstz        => g_sysdate_tstz,
                          i_flg_state             => pk_alert_constant.g_cancelled,
                          i_id_prof_cancel        => i_prof.id,
                          i_id_institution_cancel => i_prof.institution,
                          i_id_software_cancel    => i_prof.software,
                          i_id_cancel_reason      => i_id_cancel_reason,
                          i_notes_cancel          => i_notes,
                          i_notes_cancel_nin      => FALSE,
                          io_rows_vsr             => rows_vsr_out);
                --
                /*
                  -- CHAMAR PROCEDIMENTO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
                  t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_table_name => 'VITAL_SIGN_READ',
                                                i_rowids     => rows_vsr_out,
                                                o_error      => o_error);
                */
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            ROLLBACK;
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
                                              i_function => 'CANCEL_EPIS_VS_READ',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_epis_vs_read;

    /**************************************************************************
     * Get list of vital signs reads                                          *
     * Based on pk_vital_sign.get_vital_signs.                                *
     *                                                                        *
     * @param i_lang                   Preferred language ID for this         *
     *                                 professional                           *
     * @param i_prof                   Object (professional ID,               *
     *                                 institution ID, software ID)           *
     * @param i_patient                View mode                              *
     * @param i_visit                  Institution id                         *
     * @param i_flg_view               Software id                            *
     * @param i_flg_show_detail        Show the detail of composed vital signs*
     *                                                                        *
     * @return                         Table with vital sign read records     *
     *                                                                        *
     * @author                         Gustavo Serrano                        *
     * @version                        2.6.1                                  *
     * @since                          18-Fev-2011                            *
     * @copied from                    pk_vital_sign  by Rui Teixeira         *
    **************************************************************************/
    FUNCTION tf_get_vital_signs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN vital_signs_ea.id_patient%TYPE,
        i_visit           IN vital_signs_ea.id_visit%TYPE,
        i_flg_view        IN vs_soft_inst.flg_view%TYPE,
        i_flg_show_detail IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_coll_vs_info
        PIPELINED IS
        l_function_name CONSTANT VARCHAR2(30) := 'tf_get_vital_signs';
        l_rec_vs_info t_rec_vs_info;
        l_error       t_error_out;
        l_dbg_msg     debug_msg;
        l_age         vital_sign_unit_measure.age_min%TYPE;
        l_decimal_symbol CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software);
    BEGIN
        l_age     := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
        l_dbg_msg := 'GET CURSOR o_vs_header';
        FOR l_rec_vs_info IN (SELECT DISTINCT vsi.id_vital_sign,
                                              vsi.value,
                                              vsi.desc_unit_measure,
                                              vsi.pain_descr,
                                              vsi.name_vs,
                                              vsi.short_name_vs,
                                              vsi.short_dt_read,
                                              vsi.prof_read,
                                              vsi.rank,
                                              vsi.id_vital_sign_read,
                                              vsi.flg_view,
                                              vsi.dt_vital_sign_read,
                                              vsi.value_detail,
                                              vsi.id_vital_sign_detail,
                                              pk_vital_sign.is_vital_sign_read_only(i_lang            => i_lang,
                                                                                    i_prof            => i_prof,
                                                                                    i_id_epis_triage  => vsi.id_epis_triage,
                                                                                    i_flg_fill_type   => vsi.flg_fill_type,
                                                                                    i_vital_sign_read => vsi.id_vital_sign_read) flg_read_only,
                                              vsi.id_unit_measure,
                                              color_graph,
                                              (SELECT get_vsum_val_min(i_lang            => i_lang,
                                                                       i_prof            => i_prof,
                                                                       i_id_vital_sign   => vsi.id_vital_sign,
                                                                       i_id_unit_measure => vsi.id_unit_measure,
                                                                       i_id_institution  => i_prof.institution,
                                                                       i_id_software     => i_prof.software,
                                                                       i_age             => l_age)
                                                 FROM dual) val_min,
                                              (SELECT get_vsum_val_max(i_lang            => i_lang,
                                                                       i_prof            => i_prof,
                                                                       i_id_vital_sign   => vsi.id_vital_sign,
                                                                       i_id_unit_measure => vsi.id_unit_measure,
                                                                       i_id_institution  => i_prof.institution,
                                                                       i_id_software     => i_prof.software,
                                                                       i_age             => l_age)
                                                 FROM dual) val_max,
                                              pk_vital_sign.get_vs_scale(vsi.id_vs_scales_element) id_vital_sign_scale,
                                              vsi.id_vs_scales_element
                                FROM (SELECT vsi.id_vital_sign,
                                             vsea.value,
                                             pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                                       nvl(vsea.id_unit_measure,
                                                                                           vsi.id_unit_measure),
                                                                                       vsea.id_vs_scales_element) AS desc_unit_measure,
                                             pk_vital_sign.get_vs_scale_shortdesc(i_lang, vsea.id_vs_scales_element) AS pain_descr,
                                             pk_translation.get_translation(i_lang, vs.code_vital_sign) AS name_vs,
                                             pk_translation.get_translation(i_lang, vs.code_vs_short_desc) AS short_name_vs,
                                             pk_date_utils.date_send_tsz(i_lang,
                                                                         vsea.dt_vital_sign_read,
                                                                         i_prof.institution,
                                                                         i_prof.software) AS short_dt_read,
                                             pk_prof_utils.get_name_signature(i_lang, i_prof, vsea.id_prof_read) AS prof_read,
                                             vsi.rank,
                                             vsea.id_vital_sign_read,
                                             vsi.flg_view,
                                             vsea.dt_vital_sign_read,
                                             vsea.value_detail,
                                             vsea.id_vital_sign_detail,
                                             vsea.id_vs_scales_element,
                                             vsea.id_epis_triage,
                                             nvl(vsea.id_unit_measure, vsi.id_unit_measure) id_unit_measure,
                                             vs.color_graph color_graph,
                                             vs.flg_fill_type
                                        FROM vs_soft_inst vsi
                                       INNER JOIN vital_sign vs
                                          ON vsi.id_vital_sign = vs.id_vital_sign
                                        LEFT OUTER JOIN ( -- Simple Vital Signs
                                                        SELECT vseap.id_vital_sign,
                                                                vseap.value,
                                                                vseap.id_unit_measure,
                                                                vseap.id_vs_scales_element,
                                                                vseap.id_prof_read,
                                                                vseap.dt_vital_sign_read,
                                                                vseap.id_vital_sign_read,
                                                                to_char(vseap.value) value_detail,
                                                                vseap.id_vital_sign id_vital_sign_detail,
                                                                vseap.id_epis_triage
                                                          FROM (SELECT vsea.id_vital_sign,
                                                                        nvl2(vsea.id_vital_sign_desc,
                                                                             pk_vital_sign.get_vsd_desc(i_lang,
                                                                                                        vsea.id_vital_sign_desc,
                                                                                                        vsea.id_patient),
                                                                             pk_utils.to_str(vsea.value, l_decimal_symbol)) AS VALUE,
                                                                        vsea.id_unit_measure,
                                                                        vsea.id_vs_scales_element,
                                                                        vsea.id_prof_read,
                                                                        vsea.dt_vital_sign_read,
                                                                        rank() over(PARTITION BY vsea.id_vital_sign ORDER BY vsea.dt_vital_sign_read DESC NULLS LAST) AS rank,
                                                                        vsea.id_vital_sign_read,
                                                                        vsea.id_epis_triage
                                                                   FROM vital_signs_ea vsea
                                                                  INNER JOIN episode e
                                                                     ON vsea.id_episode = e.id_episode
                                                                  WHERE (vsea.id_patient = i_patient AND
                                                                        (vsea.id_visit = i_visit OR i_visit IS NULL))
                                                                    AND vsea.flg_state != pk_alert_constant.g_cancelled
                                                                    AND pk_delivery.check_vs_read_from_fetus(vsea.id_vital_sign_read) = 0) vseap
                                                         WHERE vseap.rank = 1
                                                        
                                                        UNION ALL
                                                        
                                                        -- Composed Vital Signs
                                                        SELECT veaval.id_vital_sign_parent AS id_vital_sign,
                                                                CASE veaval.relation_domain
                                                                    WHEN pk_alert_constant.g_vs_rel_conc THEN
                                                                     pk_vital_sign.get_bloodpressure_value(veaval.id_vital_sign_parent,
                                                                                                           veaval.id_patient,
                                                                                                           veaval.id_episode,
                                                                                                           veaval.dt_vital_sign_read,
                                                                                                           l_decimal_symbol)
                                                                    WHEN pk_alert_constant.g_vs_rel_sum THEN
                                                                     to_char(pk_vital_sign.get_glasgowtotal_value(veaval.id_vital_sign_parent,
                                                                                                                  veaval.id_patient,
                                                                                                                  veaval.id_episode,
                                                                                                                  veaval.dt_vital_sign_read))
                                                                    ELSE
                                                                     NULL
                                                                END AS VALUE,
                                                                NULL id_unit_measure,
                                                                NULL id_vs_scales_element,
                                                                veaval.id_prof_read,
                                                                veaval.dt_vital_sign_read,
                                                                veaval.id_vital_sign_read,
                                                                to_char(veaval.value_detail),
                                                                veaval.id_vital_sign_detail,
                                                                veaval.id_epis_triage
                                                          FROM (SELECT id_vital_sign_parent,
                                                                        id_vital_sign_detail,
                                                                        relation_domain,
                                                                        id_patient,
                                                                        id_episode,
                                                                        id_prof_read,
                                                                        dt_vital_sign_read,
                                                                        rank,
                                                                        id_vital_sign_read,
                                                                        value_detail,
                                                                        id_epis_triage
                                                                   FROM (SELECT DISTINCT vsrel.id_vital_sign_parent,
                                                                                         vsrel.id_vital_sign_detail,
                                                                                         vsrel.relation_domain,
                                                                                         vsea.id_patient,
                                                                                         vsea.id_episode,
                                                                                         vsea.id_prof_read,
                                                                                         vsea.dt_vital_sign_read,
                                                                                         rank() over(PARTITION BY vsrel.id_vital_sign_parent ORDER BY vsea.id_vital_sign_read DESC NULLS LAST) AS rank,
                                                                                         rank() over(PARTITION BY vsrel.id_vital_sign_parent ORDER BY vsea.dt_vital_sign_read DESC NULLS LAST) AS rank_dt,
                                                                                         vsea.id_vital_sign_read,
                                                                                         vsea.value value_detail,
                                                                                         vsea.id_epis_triage
                                                                           FROM vital_signs_ea vsea
                                                                          INNER JOIN episode e
                                                                             ON vsea.id_episode = e.id_episode
                                                                          INNER JOIN vital_sign_relation vsrel
                                                                             ON vsea.id_vital_sign =
                                                                                vsrel.id_vital_sign_detail
                                                                            AND vsrel.flg_available = pk_alert_constant.g_yes
                                                                          WHERE vsrel.relation_domain IN
                                                                                (pk_alert_constant.g_vs_rel_conc,
                                                                                 pk_alert_constant.g_vs_rel_sum)
                                                                            AND (vsea.id_patient = i_patient AND
                                                                                (vsea.id_visit = i_visit OR i_visit IS NULL))
                                                                            AND vsea.flg_state !=
                                                                                pk_alert_constant.g_cancelled
                                                                            AND pk_delivery.check_vs_read_from_fetus(vsea.id_vital_sign_read) = 0)
                                                                  WHERE (rank = 1 AND
                                                                        i_flg_show_detail = pk_alert_constant.g_no)
                                                                     OR (i_flg_show_detail = pk_alert_constant.g_yes AND
                                                                        rank_dt = 1)) veaval) vsea
                                          ON vsi.id_vital_sign = vsea.id_vital_sign
                                      
                                       WHERE vs.flg_available = pk_alert_constant.g_yes
                                         AND vsi.id_software = i_prof.software
                                         AND vsi.id_institution = i_prof.institution
                                         AND (i_flg_view IS NULL OR vsi.flg_view = i_flg_view)) vsi
                               ORDER BY vsi.rank ASC)
        LOOP
            PIPE ROW(l_rec_vs_info);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            RETURN;
    END tf_get_vital_signs;

    /********************************************************************************************
    * Functions which returns labels and configuration for vital signs viewer
    *
    * @param       i_lang              preferred language id for this professional
    * @param       i_prof              professional id structure
    * @param       i_episode           episode id
    * @param       o_filters           cursor with filters desc
    * @param       o_title             Variable that indicates the title which should appear on viewer
    * @param       o_error             error message
    *
    * @return      boolean             true on success, otherwise false
    *
    * @author                          Anna Kurowska
    * @version                         2.6.3
    * @since                           13-Feb-2013
    ********************************************************************************************/
    FUNCTION get_viewer_vs_config
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_filters OUT pk_types.cursor_type,
        o_title   OUT sys_message.desc_message%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- Last x records | Past x from this visit | Past x | My last x records
        l_desc_sys_msg table_varchar := table_varchar('EHR_VIEWER_T315',
                                                      'EHR_VIEWER_T318',
                                                      'EHR_VIEWER_T317',
                                                      'EHR_VIEWER_T316');
    
        -- sys message code for singular results Last record | My last record
        l_desc_sys_msg_sing table_varchar := table_varchar('EHR_VIEWER_T228', NULL, NULL, 'EHR_VIEWER_T230');
    
        -- configuration for period time description (H)ours, (D)ays, (W)eeks, (M)onths
        l_config_desc table_varchar := table_varchar(NULL, 'VS_PAST_X_FROM_VISIT', 'VS_PAST_X', NULL);
    
        l_config_nr table_varchar := table_varchar('VS_LAST_X_RECORDS',
                                                   'VS_PAST_X_FROM_VISIT_NUM',
                                                   'VS_PAST_X_NUM',
                                                   'VS_MY_LAST_X_RECORDS');
    
        l_flag table_varchar := table_varchar(pk_alert_constant.g_last_x_records,
                                              pk_alert_constant.g_past_x_from_visit,
                                              pk_alert_constant.g_past_x,
                                              pk_alert_constant.g_my_last_x_recods);
    
        l_scope_type table_varchar := table_varchar(pk_alert_constant.g_scope_type_patient,
                                                    pk_alert_constant.g_scope_type_visit,
                                                    pk_alert_constant.g_scope_type_patient,
                                                    pk_alert_constant.g_scope_type_patient);
    
        l_nr_interv       PLS_INTEGER := NULL;
        l_time_period_flg VARCHAR2(1 CHAR) := NULL;
        l_time_period     VARCHAR2(50 CHAR) := NULL;
        l_filter_msg      VARCHAR2(100 CHAR) := NULL;
    
        l_filter_desc    table_varchar := table_varchar();
        l_default_filter VARCHAR2(1 CHAR) := NULL;
    
    BEGIN
    
        --get filter selected by default
        l_default_filter := pk_sysconfig.get_config('VITAL_SIGNS_VIEWER_FILTER', i_prof);
    
        FOR i IN 1 .. l_desc_sys_msg.count
        LOOP
            l_filter_desc.extend;
        
            l_nr_interv := pk_sysconfig.get_config(l_config_nr(i), i_prof);
        
            IF l_config_desc(i) IS NULL
            THEN
                IF l_nr_interv <= 1
                THEN
                    l_filter_msg := pk_message.get_message(i_lang, l_desc_sys_msg_sing(i));
                ELSE
                    l_filter_msg := REPLACE(pk_message.get_message(i_lang, l_desc_sys_msg(i)), '@1', l_nr_interv);
                END IF;
            ELSE
                l_time_period_flg := pk_sysconfig.get_config(l_config_desc(i), i_prof);
            
                IF l_nr_interv <= 1
                THEN
                    l_filter_msg  := CASE l_time_period_flg
                                         WHEN pk_alert_constant.g_time_interval_hour THEN
                                          CASE l_desc_sys_msg(i)
                                              WHEN 'EHR_VIEWER_T318' THEN
                                               REPLACE(pk_message.get_message(i_lang, 'EHR_VIEWER_T331'), ' @1', '')
                                              WHEN 'EHR_VIEWER_T317' THEN
                                               REPLACE(pk_message.get_message(i_lang, 'EHR_VIEWER_T330'), ' @1', '')
                                              ELSE
                                               REPLACE(pk_message.get_message(i_lang, l_desc_sys_msg(i)), ' @1', '')
                                          END
                                         ELSE
                                          REPLACE(pk_message.get_message(i_lang, l_desc_sys_msg(i)), ' @1', '')
                                     END;
                    l_time_period := CASE l_time_period_flg
                                         WHEN pk_alert_constant.g_time_interval_day -- day
                                          THEN
                                          lower(pk_message.get_message(i_lang, 'COMMON_M019'))
                                         WHEN pk_alert_constant.g_time_interval_week --week
                                          THEN
                                          pk_message.get_message(i_lang, 'COMMON_M120')
                                         WHEN pk_alert_constant.g_time_interval_month --month
                                          THEN
                                          pk_message.get_message(i_lang, 'COMMON_M060')
                                         ELSE --hour
                                          pk_message.get_message(i_lang, 'COMMON_M122')
                                     END;
                ELSE
                    l_filter_msg  := CASE l_time_period_flg
                                         WHEN pk_alert_constant.g_time_interval_hour THEN
                                          CASE l_desc_sys_msg(i)
                                              WHEN 'EHR_VIEWER_T318' THEN
                                               REPLACE(pk_message.get_message(i_lang, 'EHR_VIEWER_T331'),
                                                       '@1',
                                                       l_nr_interv)
                                              WHEN 'EHR_VIEWER_T317' THEN
                                               REPLACE(pk_message.get_message(i_lang, 'EHR_VIEWER_T330'),
                                                       '@1',
                                                       l_nr_interv)
                                              ELSE
                                               REPLACE(pk_message.get_message(i_lang, l_desc_sys_msg(i)),
                                                       '@1',
                                                       l_nr_interv)
                                          END
                                         ELSE
                                          REPLACE(pk_message.get_message(i_lang, l_desc_sys_msg(i)), '@1', l_nr_interv)
                                     END;
                    l_time_period := CASE l_time_period_flg
                                         WHEN pk_alert_constant.g_time_interval_day -- days
                                          THEN
                                          lower(pk_message.get_message(i_lang, 'COMMON_M020'))
                                         WHEN pk_alert_constant.g_time_interval_week --weeks
                                          THEN
                                          pk_message.get_message(i_lang, 'COMMON_M121')
                                         WHEN pk_alert_constant.g_time_interval_month --months
                                          THEN
                                          pk_message.get_message(i_lang, 'COMMON_M061')
                                         ELSE --hours
                                          pk_message.get_message(i_lang, 'COMMON_M123')
                                     END;
                END IF;
            
                l_filter_msg := REPLACE(l_filter_msg, '@2', l_time_period);
            END IF;
        
            l_filter_desc(i) := l_filter_msg;
        
        END LOOP;
    
        OPEN o_filters FOR
        --filter 1
            SELECT 1 pos_id,
                   l_flag(1) interval_flg,
                   l_filter_desc(1) filter_desc,
                   l_scope_type(1) scope_type,
                   decode(l_flag(1), l_default_filter, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM dual
            UNION ALL -- filter 2
            SELECT 2 pos_id,
                   l_flag(2) interval_flg,
                   l_filter_desc(2) filter_desc,
                   l_scope_type(2) scope_type,
                   decode(l_flag(2), l_default_filter, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM dual
            UNION ALL -- filter 3
            SELECT 3 pos_id,
                   l_flag(3) interval_flg,
                   l_filter_desc(3) filter_desc,
                   l_scope_type(3) scope_type,
                   decode(l_flag(3), l_default_filter, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM dual
            UNION ALL -- filter 4
            SELECT 4 pos_id,
                   l_flag(4) interval_flg,
                   l_filter_desc(4) filter_desc,
                   l_scope_type(4) scope_type,
                   decode(l_flag(4), l_default_filter, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM dual;
    
        pk_types.open_cursor_if_closed(i_cursor => o_filters);
    
        g_error := 'Get sys_message for Title';
        o_title := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_vital_sign.g_sm_vs_viewer);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_filters);
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_VIEWER_VS_CONFIG',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_viewer_vs_config;

    /**********************************************************************************************
    * Get all information about interval
    *
    * @param          i_lang              language id
    * @param          i_prof              professional type
    * @param          I_INTERVAL          Interval to filter
    * @param          o_dt_begin          initial date
    * @param          o_dt_end            end date
    * @param          o_nr_records        Number of records - filled in if filter is by nr of records
    * @param          o_id_prof           Id profissional - filled in if filter is by prof
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Anna Kurowska
    * @version                            2.6.3
    * @since                              18-Feb-2013
    ********************************************************************************************/
    FUNCTION get_interval_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_interval   IN VARCHAR2,
        io_dt_begin  IN OUT TIMESTAMP WITH LOCAL TIME ZONE,
        io_dt_end    IN OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_nr_records OUT PLS_INTEGER,
        o_id_prof    OUT professional.id_professional%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_INTERVAL_DATA';
    
        l_interv_type VARCHAR2(1 CHAR) := NULL;
        l_interv_nr   PLS_INTEGER := NULL;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- initialization
        o_nr_records := NULL;
        o_id_prof    := NULL;
    
        g_error := 'CALCULATE THE INTERVAL FOR DATES';
        CASE i_interval
        -- last X records
            WHEN pk_alert_constant.g_last_x_records THEN
                o_nr_records := pk_sysconfig.get_config(i_prof => i_prof, i_code_cf => 'VS_LAST_X_RECORDS');
                io_dt_begin  := io_dt_begin;
                io_dt_end    := io_dt_end;
            
        -- Past N from this visit
            WHEN pk_alert_constant.g_past_x_from_visit THEN
                l_interv_nr   := pk_sysconfig.get_config(i_prof => i_prof, i_code_cf => 'VS_PAST_X_FROM_VISIT_NUM');
                l_interv_type := pk_sysconfig.get_config(i_prof => i_prof, i_code_cf => 'VS_PAST_X_FROM_VISIT');
                io_dt_end     := g_sysdate_tstz;
                IF NOT pk_date_utils.get_period_begin_date(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_interval_nr => l_interv_nr,
                                                           i_interval    => l_interv_type,
                                                           i_dt_end      => io_dt_end,
                                                           o_dt_begin    => io_dt_begin,
                                                           o_error       => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
        --Past N (period of time)
            WHEN pk_alert_constant.g_past_x THEN
                l_interv_nr   := pk_sysconfig.get_config(i_prof => i_prof, i_code_cf => 'VS_PAST_X_NUM');
                l_interv_type := pk_sysconfig.get_config(i_prof => i_prof, i_code_cf => 'VS_PAST_X');
                io_dt_end     := g_sysdate_tstz;
            
                IF NOT pk_date_utils.get_period_begin_date(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_interval_nr => l_interv_nr,
                                                           i_interval    => l_interv_type,
                                                           i_dt_end      => io_dt_end,
                                                           o_dt_begin    => io_dt_begin,
                                                           o_error       => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
        --My last N records
            WHEN pk_alert_constant.g_my_last_x_recods THEN
                o_nr_records := pk_sysconfig.get_config(i_prof => i_prof, i_code_cf => 'VS_MY_LAST_X_RECORDS');
                io_dt_begin  := io_dt_begin;
                io_dt_end    := io_dt_end;
                o_id_prof    := i_prof.id;
                -- other filter / without filters
            ELSE
                IF NOT pk_viewer.get_date_interval(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_interval => i_interval,
                                                   o_dt_begin => io_dt_begin,
                                                   o_dt_end   => io_dt_end,
                                                   o_error    => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            io_dt_begin  := NULL;
            io_dt_end    := NULL;
            o_nr_records := NULL;
            o_id_prof    := NULL;
        
            RETURN FALSE;
    END get_interval_data;

    --
    FUNCTION get_vs_grid_time
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_view          IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen        IN VARCHAR2,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        i_flg_use_soft_inst IN VARCHAR2 DEFAULT pk_alert_constant.g_yes, -- flg inficating if get_vital_sign_records uses vs_soft_inst to retrieve records
        o_time              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'get_vs_grid_time';
        l_dbg_msg debug_msg;
    
        l_date_tn     table_number := table_number();
        l_date_tn_aux table_number := table_number();
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    
        e_invalid_argument EXCEPTION;
    BEGIN
    
        IF (i_scope IS NOT NULL AND i_scope_type IS NOT NULL)
        THEN
            g_error := 'ANALYSING SCOPE TYPE';
            IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_scope      => i_scope,
                                                  i_scope_type => i_scope_type,
                                                  o_patient    => l_id_patient,
                                                  o_visit      => l_id_visit,
                                                  o_episode    => l_id_episode,
                                                  o_error      => o_error)
            THEN
                RAISE e_invalid_argument;
            END IF;
        
            SELECT pk_date_utils.date_send_tsz(i_lang, dt_vital_sign_read_tstz, i_prof.institution, i_prof.software)
              BULK COLLECT
              INTO l_date_tn
              FROM (SELECT dt_vital_sign_read_tstz
                      FROM (SELECT dt_vital_sign_read_tstz,
                                   row_number() over(PARTITION BY to_char(v1.dt_vital_sign_read_tstz, 'YYYYMMDD') ORDER BY dt_vital_sign_read_tstz DESC) rn
                              FROM ((SELECT vsr.id_vital_sign, vsr.dt_vital_sign_read_tstz
                                       FROM vital_sign_read vsr
                                      INNER JOIN (SELECT id_episode
                                                   FROM episode e
                                                  WHERE e.id_episode = l_id_episode
                                                    AND e.id_patient = l_id_patient
                                                    AND i_scope_type = pk_alert_constant.g_scope_type_episode
                                                 UNION ALL
                                                 SELECT id_episode
                                                   FROM episode e
                                                  WHERE e.id_patient = l_id_patient
                                                    AND i_scope_type = pk_alert_constant.g_scope_type_patient
                                                 UNION ALL
                                                 SELECT id_episode
                                                   FROM episode e
                                                  WHERE e.id_visit = l_id_visit
                                                    AND e.id_patient = l_id_patient
                                                    AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                                         ON vsr.id_episode = epi.id_episode
                                       LEFT JOIN vs_soft_inst vsi
                                         ON vsi.id_vital_sign = vsr.id_vital_sign
                                        AND vsi.id_software = i_prof.software
                                        AND vsi.id_institution = i_prof.institution
                                        AND vsi.flg_view = i_flg_view
                                      WHERE NOT EXISTS
                                      (SELECT 1
                                               FROM vital_sign_pregnancy vsp
                                              WHERE vsp.id_vital_sign_read = vsr.id_vital_sign_read
                                                AND vsp.fetus_number > 0)
                                        AND (NOT EXISTS
                                             (SELECT 1
                                                FROM vital_sign_relation vr
                                               WHERE vsr.id_vital_sign = vr.id_vital_sign_detail
                                                 AND vr.relation_domain IN
                                                     (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                                                 AND vr.flg_available = pk_alert_constant.g_yes))
                                        AND (EXISTS (SELECT 1
                                                       FROM vs_soft_inst vsi
                                                      WHERE vsi.id_vital_sign = vsr.id_vital_sign
                                                        AND vsi.id_software = i_prof.software
                                                        AND vsi.id_institution = i_prof.institution
                                                        AND vsi.flg_view = i_flg_view
                                                        AND i_flg_use_soft_inst = pk_alert_constant.g_yes) OR
                                             i_flg_use_soft_inst = pk_alert_constant.g_no)) UNION ALL
                                    (SELECT vr.id_vital_sign_parent, vsr.dt_vital_sign_read_tstz
                                       FROM vital_sign_read vsr
                                      INNER JOIN (SELECT id_episode
                                                   FROM episode e
                                                  WHERE e.id_episode = l_id_episode
                                                    AND e.id_patient = l_id_patient
                                                    AND i_scope_type = pk_alert_constant.g_scope_type_episode
                                                 UNION ALL
                                                 SELECT id_episode
                                                   FROM episode e
                                                  WHERE e.id_patient = l_id_patient
                                                    AND i_scope_type = pk_alert_constant.g_scope_type_patient
                                                 UNION ALL
                                                 SELECT id_episode
                                                   FROM episode e
                                                  WHERE e.id_visit = l_id_visit
                                                    AND e.id_patient = l_id_patient
                                                    AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                                         ON vsr.id_episode = epi.id_episode
                                       JOIN vital_sign_relation vr
                                         ON vsr.id_vital_sign = vr.id_vital_sign_detail
                                       LEFT JOIN vs_soft_inst vsi
                                         ON vsi.id_vital_sign = vsr.id_vital_sign
                                        AND vsi.id_software = i_prof.software
                                        AND vsi.id_institution = i_prof.institution
                                        AND vsi.flg_view = i_flg_view
                                      WHERE vr.relation_domain IN
                                            (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                                        AND vr.flg_available = pk_alert_constant.g_yes
                                        AND vr.rank =
                                            (SELECT MIN(v.rank)
                                               FROM vital_sign_relation v
                                              WHERE vr.id_vital_sign_parent = v.id_vital_sign_parent
                                                AND vr.flg_available = pk_alert_constant.g_yes
                                                AND vr.relation_domain != pk_alert_constant.g_vs_rel_percentile)
                                        AND (EXISTS (SELECT 1
                                                       FROM vs_soft_inst vsi
                                                      WHERE vsi.id_vital_sign = vsr.id_vital_sign
                                                        AND vsi.id_software = i_prof.software
                                                        AND vsi.id_institution = i_prof.institution
                                                        AND vsi.flg_view = i_flg_view
                                                        AND i_flg_use_soft_inst = pk_alert_constant.g_yes) OR
                                             i_flg_use_soft_inst = pk_alert_constant.g_no))) v1)
                     WHERE rn = 1
                     ORDER BY dt_vital_sign_read_tstz DESC);
        
        END IF;
    
        IF l_date_tn.count > 1
        THEN
            l_date_tn_aux.extend;
            l_date_tn_aux(l_date_tn_aux.count) := l_date_tn(1);
        
            FOR i IN 2 .. l_date_tn.count
            LOOP
                IF substr(l_date_tn_aux(l_date_tn_aux.count), 1, 8) <> substr(l_date_tn(i), 1, 8)
                THEN
                    l_date_tn_aux.extend;
                    l_date_tn_aux(l_date_tn_aux.count) := l_date_tn(i);
                END IF;
            END LOOP;
        
        ELSE
            l_date_tn_aux := l_date_tn;
        END IF;
    
        l_dbg_msg := 'open o_time';
        OPEN o_time FOR
            SELECT column_value data,
                   pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                         pk_date_utils.get_string_tstz(i_lang,
                                                                                       i_prof,
                                                                                       column_value,
                                                                                       NULL),
                                                         i_prof) AS label
              FROM TABLE(l_date_tn_aux)
             ORDER BY column_value DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_invalid_argument THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   'An input parameter has an unexpected value',
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   l_function_name);
                pk_types.open_my_cursor(i_cursor => o_time);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_vs_grid_time;

    FUNCTION get_vsr_cancel
    (
        i_id_vital_sign           IN vital_sign_read.id_vital_sign%TYPE,
        i_dt_vital_sign_read_tstz IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_id_patient              IN patient.id_patient%TYPE
    ) RETURN vital_sign_read.id_vital_sign_read%TYPE IS
        l_id_vital_sign_read vital_sign_read.id_vital_sign_read%TYPE;
    BEGIN
        BEGIN
            SELECT vsr.id_vital_sign_read
              INTO l_id_vital_sign_read
              FROM vital_sign_read vsr
             WHERE vsr.id_vital_sign = i_id_vital_sign
               AND vsr.dt_vital_sign_read_tstz = i_dt_vital_sign_read_tstz
               AND vsr.id_patient = i_id_patient
               AND vsr.flg_state = pk_alert_constant.g_active
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                SELECT id_vital_sign_read
                  INTO l_id_vital_sign_read
                  FROM (SELECT vsr.id_vital_sign_read, row_number() over(ORDER BY vsr.dt_registry DESC) rn
                          FROM vital_sign_read vsr
                         WHERE vsr.id_vital_sign = i_id_vital_sign
                           AND vsr.id_patient = i_id_patient
                           AND vsr.dt_vital_sign_read_tstz = i_dt_vital_sign_read_tstz) t
                 WHERE t.rn = 1;
        END;
    
        RETURN l_id_vital_sign_read;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN NULL;
        
    END get_vsr_cancel;
    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
        l_flg_view CONSTANT VARCHAR2(2 CHAR) := 'V2';
    BEGIN
    
        MERGE INTO viewer_ehr_ea d
        USING (SELECT aux.id_patient,
                      'VITAL_SIGN.CODE_VITAL_SIGN.' || aux.id_vital_sign code_vital_sign,
                      aux.l_count num_records,
                      aux.dt_vital_sign_read_tstz date_tstz
                 FROM (SELECT t_vs.id_vital_sign_read,
                              t_vs.id_vital_sign,
                              t_vs.id_patient,
                              t_vs.l_count,
                              t_vs.dt_vital_sign_read_tstz
                         FROM (SELECT t_vs2.id_vital_sign_read,
                                      t_vs2.id_vital_sign,
                                      t_vs2.id_patient,
                                      t_vs2.dt_vital_sign_read_tstz,
                                      t_vs2.rn,
                                      COUNT(1) over(PARTITION BY t_vs2.id_patient) l_count
                                 FROM (SELECT vsr.id_vital_sign_read,
                                              vspea.id_vital_sign,
                                              vspea.id_patient,
                                              vsr.dt_vital_sign_read_tstz,
                                              row_number() over(PARTITION BY vspea.id_patient ORDER BY vsr.dt_vital_sign_read_tstz DESC NULLS LAST, vsi.rank ASC NULLS LAST) rn,
                                              row_number() over(PARTITION BY vspea.id_patient, vspea.id_vital_sign ORDER BY vsr.dt_vital_sign_read_tstz DESC NULLS LAST, vsi.rank ASC NULLS LAST) rn2
                                         FROM vs_patient_ea vspea
                                        INNER JOIN vital_sign_read vsr
                                           ON vspea.id_last_1_vsr = vsr.id_vital_sign_read
                                          AND vsr.flg_state = pk_vital_sign.c_flg_status_active
                                         JOIN vs_soft_inst vsi
                                           ON vsi.id_vital_sign = vspea.id_vital_sign
                                          AND vsi.id_software = vsr.id_software_read
                                          AND vsi.id_institution = vsr.id_institution_read
                                          AND vsi.flg_view = l_flg_view) t_vs2
                                WHERE t_vs2.rn2 = 1) t_vs
                        WHERE t_vs.rn = 1) aux) s
        ON (d.id_patient = s.id_patient)
        WHEN MATCHED THEN
            UPDATE
               SET d.num_vs = s.num_records, d.code_vs = s.code_vital_sign, d.dt_vs = s.date_tstz, d.desc_vs = NULL;
    
    END upd_viewer_ehr_ea;
    FUNCTION get_has_notes
    (
        i_dt_vital_sign_read_tstz IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_id_patient              IN patient.id_patient%TYPE,
        i_vsr_ids                 IN table_number
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1 CHAR);
    BEGIN
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO l_return
              FROM vital_sign_read vsr
             WHERE vsr.dt_vital_sign_read_tstz = i_dt_vital_sign_read_tstz
               AND vsr.id_patient = nvl(i_id_patient, vsr.id_patient)
               AND vsr.id_vital_sign_notes IS NOT NULL
               AND vsr.id_vital_sign_read IN (SELECT /*+opt_estimate (table t rows=0.000001)*/
                                               column_value
                                                FROM TABLE(i_vsr_ids))
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_return := pk_alert_constant.g_no;
        END;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN NULL;
        
    END get_has_notes;

    /************************************************************************************************************
    * This function returns the vital sign unit measure convertion list
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign       vital_sign identifier
    * @param      i_id_unit_measure     unit_measure identifier
    * @param       o_cursor             out cursor
    * @param       o_error             error message
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/09/27
    *
    * @dependencies     UX
    ***********************************************************************************************************/
    FUNCTION get_vs_convert_um
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign.id_vital_sign%TYPE,
        i_id_unit_measure IN unit_measure.id_unit_measure%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        o_cursor          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'get_vs_convert_um';
        l_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
        l_age    vital_sign_unit_measure.age_min%TYPE;
    BEGIN
    
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
    
        g_error := 'get_vs_convert_um: open o_cursor';
        OPEN o_cursor FOR
            SELECT aux2.id_unit_measure   id,
                   aux2.desc_unit_measure label,
                   aux2.val_min           val_min,
                   aux2.val_max           val_max,
                   aux2.format_num        format_num,
                   aux2.flg_default       flg_default
              FROM (SELECT i_id_unit_measure id_unit_measure,
                           pk_unit_measure.get_unit_measure_description(i_lang, i_prof, i_id_unit_measure) desc_unit_measure,
                           (SELECT get_vsum_val_min(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_vital_sign   => i_id_vital_sign,
                                                    i_id_unit_measure => i_id_unit_measure,
                                                    i_id_institution  => i_prof.institution,
                                                    i_id_software     => i_prof.software,
                                                    i_age             => l_age)
                              FROM dual) val_min,
                           (SELECT get_vsum_val_max(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_vital_sign   => i_id_vital_sign,
                                                    i_id_unit_measure => i_id_unit_measure,
                                                    i_id_institution  => i_prof.institution,
                                                    i_id_software     => i_prof.software,
                                                    i_age             => l_age)
                              FROM dual) val_max,
                           (SELECT get_vsum_format_num(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_vital_sign   => i_id_vital_sign,
                                                       i_id_unit_measure => i_id_unit_measure,
                                                       i_id_institution  => i_prof.institution,
                                                       i_id_software     => i_prof.software,
                                                       i_age             => l_age)
                              FROM dual) format_num,
                           pk_alert_constant.g_yes flg_default,
                           -99999999 rank
                      FROM dual
                    UNION ALL
                    SELECT aux.id_unit_measure,
                           pk_unit_measure.get_unit_measure_description(i_lang, i_prof, aux.id_unit_measure) desc_unit_measure,
                           (SELECT get_vsum_val_min(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_vital_sign   => aux.id_vital_sign,
                                                    i_id_unit_measure => aux.id_unit_measure,
                                                    i_id_institution  => i_prof.institution,
                                                    i_id_software     => i_prof.software,
                                                    i_age             => l_age)
                              FROM dual) val_min,
                           (SELECT get_vsum_val_max(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_vital_sign   => aux.id_vital_sign,
                                                    i_id_unit_measure => aux.id_unit_measure,
                                                    i_id_institution  => i_prof.institution,
                                                    i_id_software     => i_prof.software,
                                                    i_age             => l_age)
                              FROM dual) val_max,
                           (SELECT get_vsum_format_num(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_vital_sign   => aux.id_vital_sign,
                                                       i_id_unit_measure => aux.id_unit_measure,
                                                       i_id_institution  => i_prof.institution,
                                                       i_id_software     => i_prof.software,
                                                       i_age             => l_age)
                              FROM dual) format_num,
                           pk_alert_constant.g_no flg_default,
                           aux.rank
                      FROM (SELECT umcsi.id_vital_sign,
                                   umc.id_unit_measure2 id_unit_measure,
                                   row_number() over(PARTITION BY umcsi.id_unit_measure_convert ORDER BY umcsi.id_software DESC, umcsi.id_institution DESC, umcsi.id_market DESC) rn,
                                   umcsi.rank
                              FROM unit_measure_convert umc
                              JOIN unit_mea_conv_soft_inst umcsi
                                ON umc.id_unit_measure_convert = umcsi.id_unit_measure_convert
                               AND umcsi.id_vital_sign = i_id_vital_sign
                               AND umcsi.id_market IN (pk_alert_constant.g_id_market_all, l_market)
                               AND umcsi.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                               AND umcsi.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                             WHERE umc.id_unit_measure1 = i_id_unit_measure) aux
                     WHERE rn = 1) aux2
             ORDER BY aux2.rank ASC NULLS LAST;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
    END get_vs_convert_um;

    /************************************************************************************************************
    * This function returns the vital sign attribute list
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign       vital_sign identifier
    * @param      i_id_parent       vs_attribute identifier
    * @param       o_cursor             out cursor
    * @param       o_error             error message
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/09/27
    *
    * @dependencies     UX
    ***********************************************************************************************************/
    FUNCTION get_vs_attributes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign.id_vital_sign%TYPE,
        i_id_parent     IN vs_attribute.id_parent%TYPE,
        o_cursor        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'get_vs_attributes';
        l_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    BEGIN
        g_error := 'get_vs_attributes: open o_cursor';
        OPEN o_cursor FOR
            SELECT aux.id_vs_attribute data,
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
               AND CASE
                       WHEN i_id_parent IS NULL
                            AND vsa.id_parent IS NULL THEN
                        1
                       WHEN i_id_parent = vsa.id_parent THEN
                        1
                       ELSE
                        0
                   END = 1
             ORDER BY aux.rank ASC;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
    END get_vs_attributes;
    /************************************************************************************************************
    * This function inserts the vital sign attribute
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign_read       vital_sign_read identifier
    * @param      i_tb_attribute             vs_attribute list identifiers
    * @param      i_tb_free_text             table free text atributes
    * @param       o_error             error message
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/11/15
    *
    * @dependencies     BD
    ***********************************************************************************************************/

    FUNCTION set_vs_read_attribute
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_tb_attribute       IN table_number,
        i_tb_free_text       IN table_clob,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'set_vs_read_attribute';
        rows_vsr_out table_varchar;
    BEGIN
    
        g_error := 'set_vs_read_attribute: i_tb_attribute.count <> i_tb_free_text.count';
    
        IF i_tb_attribute.exists(1)
           AND i_tb_free_text.exists(1)
        THEN
            IF i_tb_attribute.count <> i_tb_free_text.count
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'call ts_vs_read_attribute.del_id_vital_sign_read';
        ts_vs_read_attribute.del_id_vital_sign_read(id_vital_sign_read_in => i_id_vital_sign_read,
                                                    rows_out              => rows_vsr_out);
    
        g_error := 'call t_data_gov_mnt.process_insert vs_read_attribute';
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'VS_READ_ATTRIBUTE',
                                      i_rowids     => rows_vsr_out,
                                      o_error      => o_error);
    
        IF i_tb_attribute.exists(1)
        THEN
        
            FOR i IN 1 .. i_tb_attribute.count
            LOOP
                g_error := 'call ts_vs_read_attribute.ins';
                ts_vs_read_attribute.ins(id_vital_sign_read_in => i_id_vital_sign_read,
                                         id_vs_attribute_in    => i_tb_attribute(i),
                                         free_text_in          => i_tb_free_text(i),
                                         rows_out              => rows_vsr_out);
            
                g_error := 'call t_data_gov_mnt.process_insert vs_read_attribute';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'VS_READ_ATTRIBUTE',
                                              i_rowids     => rows_vsr_out,
                                              o_error      => o_error);
            END LOOP;
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
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_vs_read_attribute;
    /************************************************************************************************************
    * This function returns the vital sign value converted
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign_read       vital_sign_read identifier
    * @param      i_flg_detail                is detail screen Y/N
    * @param      i_flg_hist                is hist record Y/N
    *
    * @return     vital sign value
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/11/15
    *
    * @dependencies     BD
    ***********************************************************************************************************/

    FUNCTION get_vs_value_converted
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_flg_detail         IN VARCHAR2,
        i_flg_hist           IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1000 CHAR);
        g_space CONSTANT VARCHAR2(1 CHAR) := ' ';
    BEGIN
    
        IF i_flg_hist = pk_alert_constant.g_yes
        THEN
            SELECT pk_unit_measure.get_unit_mea_conversion(vsr.value, vsr.id_unit_measure, vsr.id_unit_measure_sel) ||
                   g_space || pk_translation.get_translation(i_lang, um.code_unit_measure)
              INTO l_return
              FROM vital_sign_read_hist vsr
              JOIN unit_measure um
                ON um.id_unit_measure = vsr.id_unit_measure_sel
             WHERE vsr.id_vital_sign_read_hist = i_id_vital_sign_read
               AND vsr.value IS NOT NULL
               AND vsr.id_unit_measure_sel <> vsr.id_unit_measure;
        ELSE
            SELECT pk_unit_measure.get_unit_mea_conversion(vsr.value, vsr.id_unit_measure, vsr.id_unit_measure_sel) ||
                   g_space || pk_translation.get_translation(i_lang, um.code_unit_measure)
              INTO l_return
              FROM vital_sign_read vsr
              JOIN unit_measure um
                ON um.id_unit_measure = vsr.id_unit_measure_sel
             WHERE vsr.id_vital_sign_read = i_id_vital_sign_read
               AND vsr.value IS NOT NULL
               AND vsr.id_unit_measure_sel <> vsr.id_unit_measure;
        END IF;
    
        IF i_flg_detail = pk_alert_constant.g_yes
        THEN
            l_return := '; ' || l_return;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_vs_value_converted;
    /************************************************************************************************************
    * This function returns the vital sign attribute rank
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign             vital_sign identifier
    * @param      i_id_vs_attribute           id_vs_attribute identifier
    * @param      i_id_market                 market identifier
    *
    * @return     vital sign attribute rank
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/11/18
    *
    * @dependencies     BD
    ***********************************************************************************************************/
    FUNCTION get_vsa_rank
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_read.id_vital_sign%TYPE,
        i_id_vs_attribute IN vs_attribute.id_vs_attribute%TYPE,
        i_id_market       IN market.id_market%TYPE
    ) RETURN vs_attribute_soft_inst.rank%TYPE IS
        l_return vs_attribute_soft_inst.rank%TYPE;
    BEGIN
    
        SELECT aux.rank
          INTO l_return
          FROM (SELECT vsasi.id_vs_attribute,
                       vsasi.rank,
                       row_number() over(PARTITION BY vsasi.id_vs_attribute ORDER BY vsasi.id_software DESC, vsasi.id_institution DESC, vsasi.id_market DESC) rn
                  FROM vs_attribute_soft_inst vsasi
                 WHERE vsasi.id_vs_attribute = i_id_vs_attribute
                   AND vsasi.id_vital_sign = i_id_vital_sign
                   AND vsasi.id_market IN (pk_alert_constant.g_id_market_all, i_id_market)
                   AND vsasi.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                   AND vsasi.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)) aux
         WHERE aux.rn = 1;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_vsa_rank;

    FUNCTION get_vsa_has_freetext
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_read.id_vital_sign%TYPE,
        i_id_vs_attribute IN vs_attribute.id_vs_attribute%TYPE,
        i_id_market       IN market.id_market%TYPE
    ) RETURN vs_attribute.flg_free_text%TYPE IS
        l_return vs_attribute.flg_free_text%TYPE := pk_alert_constant.g_no;
        l_count  NUMBER;
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT vsasi.id_vs_attribute,
                       vsasi.rank,
                       row_number() over(PARTITION BY vsasi.id_vs_attribute ORDER BY vsasi.id_software DESC, vsasi.id_institution DESC, vsasi.id_market DESC) rn
                  FROM vs_attribute_soft_inst vsasi
                
                 WHERE vsasi.id_vital_sign = i_id_vital_sign
                   AND vsasi.id_market IN (pk_alert_constant.g_id_market_all, i_id_market)
                   AND vsasi.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                   AND vsasi.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)) aux
          JOIN vs_attribute va
            ON va.id_vs_attribute = aux.id_vs_attribute
           AND va.id_parent = i_id_vs_attribute
           AND flg_free_text = pk_alert_constant.g_yes
         WHERE aux.rn = 1;
        IF l_count > 0
        THEN
            l_return := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_vsa_has_freetext;
    /************************************************************************************************************
    * This function returns the vital sign detail for the edit screen
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign           vital_sign identifier
    * @param      i_id_vital_sign_read       vital_sign_read identifier
    * @param       o_cursor             out cursor
    * @param       o_error             error message
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/09/27
    *
    * @dependencies     UX
    ***********************************************************************************************************/
    FUNCTION get_vs_read_attributes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign      IN vital_sign.id_vital_sign%TYPE,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read %TYPE,
        o_cursor             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'get_vs_read_attributes';
        l_id_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    BEGIN
    
        g_error := 'get_vs_read_attributes: open o_cursor';
        OPEN o_cursor FOR
            SELECT aux2.data_parent data_parent,
                   aux2.label_parent label_parent,
                   vsa_s.flg_free_text flg_free_text,
                   vsa_s.id_vs_attribute data,
                   pk_translation.get_translation(i_lang, vsa_s.code_vs_attribute) label,
                   vsra.free_text free_text,
                   get_vsa_has_freetext(i_lang, i_prof, i_id_vital_sign, data_parent, l_id_market) flg_has_free_text
              FROM (SELECT aux.id_vs_attribute data_parent,
                           pk_translation.get_translation(i_lang, vsa_p.code_vs_attribute) label_parent,
                           aux.rank
                      FROM (SELECT vsasi.id_vs_attribute,
                                   vsasi.rank,
                                   row_number() over(PARTITION BY vsasi.id_vs_attribute ORDER BY vsasi.id_software DESC, vsasi.id_institution DESC, vsasi.id_market DESC) rn
                              FROM vs_attribute_soft_inst vsasi
                             WHERE vsasi.id_vital_sign = i_id_vital_sign
                               AND vsasi.id_market IN (pk_alert_constant.g_id_market_all, l_id_market)
                               AND vsasi.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                               AND vsasi.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)) aux
                      JOIN vs_attribute vsa_p
                        ON vsa_p.id_vs_attribute = aux.id_vs_attribute
                     WHERE aux.rn = 1
                       AND vsa_p.id_parent IS NULL) aux2
              LEFT JOIN vs_read_attribute vsra
                ON vsra.id_vs_attribute IN (SELECT id_vs_attribute
                                              FROM vs_attribute vsa
                                             WHERE vsa.id_parent = aux2.data_parent)
               AND vsra.id_vital_sign_read = i_id_vital_sign_read
              LEFT JOIN vs_attribute vsa_s
                ON vsa_s.id_vs_attribute = vsra.id_vs_attribute
             ORDER BY aux2.rank ASC;
    
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
    END get_vs_read_attributes;
    /************************************************************************************************************
    * This function returns the vital sign value
    *
    * @return     vital sign value
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/11/15
    *
    * @dependencies     BD
    ***********************************************************************************************************/

    FUNCTION get_vs_value
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_vital_sign       IN vital_sign.id_vital_sign%TYPE,
        i_id_vital_sign_desc  IN vital_sign_read.id_vital_sign_desc%TYPE,
        i_dt_vital_sign_read  IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_id_unit_measure_vsr IN unit_measure.id_unit_measure%TYPE,
        i_id_unit_measure_vsi IN unit_measure.id_unit_measure%TYPE,
        i_value               IN vital_sign_read.value%TYPE,
        i_decimal_symbol      IN sys_config.value%TYPE,
        i_relation_domain     IN vital_sign_relation.relation_domain%TYPE,
        i_dt_registry         IN vital_sign_read.dt_registry%TYPE DEFAULT NULL,
        i_short_desc          IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1000 CHAR);
    BEGIN
    
        CASE i_relation_domain
            WHEN pk_alert_constant.g_vs_rel_conc THEN
                l_return := pk_vital_sign.get_bloodpressure_value(i_vital_sign         => i_id_vital_sign,
                                                                  i_patient            => i_id_patient,
                                                                  i_episode            => i_id_episode,
                                                                  i_dt_vital_sign_read => i_dt_vital_sign_read,
                                                                  i_decimal_symbol     => i_decimal_symbol,
                                                                  i_dt_registry        => i_dt_registry);
            WHEN pk_alert_constant.g_vs_rel_sum THEN
                IF i_id_vital_sign_desc IS NULL
                THEN
                    l_return := to_char(pk_vital_sign.get_glasgowtotal_value_hist(i_id_vital_sign,
                                                                                  i_id_patient,
                                                                                  i_id_episode,
                                                                                  i_dt_vital_sign_read,
                                                                                  i_dt_registry => i_dt_registry));
                ELSE
                    SELECT pk_translation.get_translation(i_lang, vsd.code_vital_sign_desc)
                      INTO l_return
                      FROM vital_sign_desc vsd
                     WHERE vsd.id_vital_sign_desc = i_id_vital_sign_desc;
                END IF;
            
            ELSE
                CASE
                    WHEN i_id_vital_sign_desc IS NULL THEN
                        SELECT pk_utils.to_str(CASE i_id_unit_measure_vsr
                                                   WHEN i_id_unit_measure_vsi THEN
                                                    i_value
                                                   ELSE
                                                    nvl((SELECT pk_unit_measure.get_unit_mea_conversion(i_value,
                                                                                                       i_id_unit_measure_vsr,
                                                                                                       i_id_unit_measure_vsi)
                                                          FROM dual),
                                                        i_value)
                                               END,
                                               i_decimal_symbol)
                          INTO l_return
                          FROM dual;
                    ELSE
                        SELECT pk_vital_sign.get_vsd_desc(i_lang            => i_lang,
                                                          i_vital_sign_desc => i_id_vital_sign_desc,
                                                          i_patient         => i_id_patient,
                                                          i_short_desc      => i_short_desc)
                          INTO l_return
                          FROM dual;
                END CASE;
        END CASE;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_vs_value;
    /************************************************************************************************************
    * This function returns the vital sign detail for the edit screen
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign_read       vital_sign_read identifier
    * @param       o_cursor             out cursor
    * @param       o_error             error message
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/09/27
    *
    * @dependencies     UX
    ***********************************************************************************************************/
    FUNCTION get_vs_read_attributes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read %TYPE,
        o_cursor             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'get_vs_read_attributes';
        l_id_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    BEGIN
    
        g_error := 'get_vs_read_attributes: open o_cursor';
        OPEN o_cursor FOR
            SELECT vsa_label, vsa_value, flg_free_text, free_text
              FROM (SELECT pk_translation.get_translation(i_lang, vsap.code_vs_attribute) vsa_label,
                           pk_translation.get_translation(i_lang, vsa.code_vs_attribute) vsa_value,
                           vsa.flg_free_text flg_free_text,
                           vsra.free_text free_text,
                           (SELECT pk_vital_sign_core.get_vsa_rank(i_lang,
                                                                   i_prof,
                                                                   vsr.id_vital_sign,
                                                                   vsap.id_vs_attribute,
                                                                   l_id_market)
                              FROM dual) rank
                      FROM vs_read_attribute vsra
                      JOIN vs_attribute vsa
                        ON vsa.id_vs_attribute = vsra.id_vs_attribute
                      JOIN vs_attribute vsap
                        ON vsap.id_vs_attribute = vsa.id_parent
                      JOIN vital_sign_read vsr
                        ON vsr.id_vital_sign_read = vsra.id_vital_sign_read
                     WHERE vsra.id_vital_sign_read = i_id_vital_sign_read) aux
             ORDER BY aux.rank ASC NULLS LAST;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
    END get_vs_read_attributes;

    /*************************************************************************
    * List of vital signs for CDA                                            *
    * Based on pk_vital_sign_core.tf_vital_sign_grid                         *
    *                                                                        *
    * @param i_lang                   language ID                            *
    * @param i_prof                   professional ID                        *
    * @param i_flg_view               View mode                              *
    * @param i_all_details            View all detail Y/N                    *
    * @param i_scope                  ID for scope                           *
    * @param i_scope_type             Scope Type (E)pisode/(V)isit/(P)atient *
    * @param i_interval               Record filter: Null - All, L - Last    *
    * @param i_dt_begin               Begin date                             *
    * @param i_dt_end                 End date                               *
    *                                                                        *
    * @return                         Table with vital sign read records     *
    *                                                                        *
    * @author                         Vanessa Barsottelli                    *
    * @version                        2.6.3                                  *
    * @since                          12-Dez-2013                            *
    *************************************************************************/
    FUNCTION tf_vital_sign_cda
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_view    IN vs_soft_inst.flg_view%TYPE,
        i_all_details IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_scope       IN NUMBER,
        i_scope_type  IN VARCHAR2,
        i_interval    IN VARCHAR2 DEFAULT NULL,
        i_dt_begin    IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_coll_vs_cda
        PIPELINED IS
        l_error        t_error_out;
        l_count_cda_vs NUMBER;
        l_rec_vs_cda   t_rec_vs_cda;
        l_function_name CONSTANT obj_name := 'TF_VITAL_SIGN_CDA';
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count_cda_vs
          FROM vs_soft_inst vsi
         WHERE vsi.flg_view = 'CD';
    
        IF l_count_cda_vs = 0
        THEN
            g_found := FALSE;
            g_error := 'No Vital Sign configured for CDA View (CD).';
            RAISE g_exception;
        END IF;
    
        g_found := TRUE;
        g_error := 'pk_vital_sign_core.tf_vital_sign_grid records';
        FOR l_rec_vs_cda IN (SELECT t.id_content,
                                    t.id_vital_sign,
                                    t.id_vital_sign_read,
                                    t.vital_sign_desc,
                                    t.vital_sign_value,
                                    nvl2(t.vital_sign_scale,
                                         t.vital_sign_scale_desc || ' ' || t.desc_unit_measure,
                                         t.desc_unit_measure) vital_sign_unit_desc,
                                    t.dt_value,
                                    t.dt_formatted,
                                    t.dt_serialized,
                                    t.dt_timezone,
                                    t.id_prof_read,
                                    t.id_institution_read,
                                    t.id_software_read,
                                    (SELECT vsn.notes
                                       FROM vital_sign_notes vsn
                                      WHERE vsn.id_vital_sign_notes = t.id_vital_sign_notes) notes
                               FROM (SELECT /*+opt_estimate (table vs rows=1)*/
                                      (SELECT v.id_content
                                         FROM vital_sign v
                                        WHERE v.id_vital_sign = vs.id_vital_sign) id_content,
                                      vs.id_vital_sign,
                                      vs.id_vital_sign_read,
                                      vsr.id_vital_sign_notes,
                                      (SELECT pk_vital_sign.get_vs_desc(i_lang, vs.id_vital_sign)
                                         FROM dual) vital_sign_desc,
                                      vs.value_desc vital_sign_value,
                                      vs.vital_sign_scale,
                                      (SELECT pk_translation.get_translation(i_lang, vss.code_vital_sign_scales)
                                         FROM vital_sign_scales vss
                                        WHERE vs.vital_sign_scale = vss.id_vital_sign_scales) vital_sign_scale_desc,
                                      vs.id_unit_measure,
                                      vs.desc_unit_measure,
                                      vs.desc_unit_measure_sel,
                                      vs.dt_vs_read_tstz dt_value,
                                      NULL dt_formatted,
                                      NULL dt_serialized,
                                      (SELECT tr.timezone_region
                                         FROM institution i
                                         JOIN timezone_region tr
                                           ON tr.id_timezone_region = i.id_timezone_region
                                        WHERE i.id_institution = vsr.id_institution_read) dt_timezone,
                                      vs.id_prof_read,
                                      vsr.id_institution_read,
                                      vsr.id_software_read,
                                      row_number() over(PARTITION BY vs.id_vital_sign ORDER BY vs.dt_vital_sign_read DESC NULLS LAST) rn
                                       FROM TABLE(tf_vital_sign_grid(i_lang        => i_lang,
                                                                     i_prof        => i_prof,
                                                                     i_flg_view    => i_flg_view,
                                                                     i_flg_screen  => g_flg_screen_d,
                                                                     i_all_details => i_all_details,
                                                                     i_scope       => i_scope,
                                                                     i_scope_type  => i_scope_type,
                                                                     i_interval    => i_interval,
                                                                     i_dt_begin    => i_dt_begin,
                                                                     i_dt_end      => i_dt_end)) vs
                                       JOIN vital_sign_read vsr
                                         ON vsr.id_vital_sign_read = vs.id_vital_sign_read
                                      WHERE vs.flg_vs_status = pk_alert_constant.g_active) t
                              WHERE i_interval IS NULL
                                 OR (i_interval = pk_alert_constant.g_last_x_records AND t.rn = 1))
        LOOP
            PIPE ROW(l_rec_vs_cda);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN;
    END tf_vital_sign_cda;

    /*************************************************************************
    * List of vital signs unit measure                                       *
    *                                                                        *
    * @param i_lang                   language ID                            *
    * @param i_prof                   professional ID                        *
    * @param i_id_vital_sign
    * @param i_id_unit_measure
    * @param i_id_institution
    * @param i_id_software
    * @param i_age
    *                                                                        *
    * @return                         Table with vital sign unit measure     *
    *                                                                        *
    * @author                         Paulo teixeira                         *
    * @version                        2.6.3                                  *
    * @since                          2014 02 03                             *
    *************************************************************************/
    FUNCTION tf_vital_sign_unit_measure
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_unit_measure.id_vital_sign%TYPE,
        i_id_unit_measure IN vital_sign_unit_measure.id_unit_measure%TYPE,
        i_id_institution  IN vital_sign_unit_measure.id_institution%TYPE,
        i_id_software     IN vital_sign_unit_measure.id_software%TYPE,
        i_age             IN vital_sign_unit_measure.age_min%TYPE
    ) RETURN t_coll_vsum
        PIPELINED IS
        l_error    t_error_out;
        l_rec_vsum t_rec_vsum;
        l_function_name CONSTANT obj_name := 'tf_vital_sign_unit_measure';
    BEGIN
    
        g_found := TRUE;
        g_error := 'pk_vital_sign_core.tf_vital_sign_unit_measure records';
        FOR l_rec_vsum IN (SELECT aux.id_vital_sign,
                                  aux.id_unit_measure,
                                  aux.id_institution,
                                  aux.id_software,
                                  aux.age_min,
                                  aux.age_max,
                                  aux.val_min,
                                  aux.val_max,
                                  aux.decimals,
                                  aux.format_num
                             FROM (SELECT *
                                     FROM (SELECT vsum.id_vital_sign,
                                                  vsum.id_unit_measure,
                                                  vsum.id_institution,
                                                  vsum.id_software,
                                                  vsum.age_min,
                                                  vsum.age_max,
                                                  vsum.val_min,
                                                  vsum.val_max,
                                                  vsum.decimals,
                                                  vsum.format_num,
                                                  1 rank
                                             FROM vital_sign_unit_measure vsum
                                            WHERE vsum.id_vital_sign = i_id_vital_sign
                                              AND nvl(vsum.id_unit_measure, 0) = nvl(i_id_unit_measure, 0)
                                              AND vsum.id_institution = i_id_institution
                                              AND vsum.id_software = i_id_software
                                              AND i_age IS NOT NULL
                                              AND i_age BETWEEN vsum.age_min AND vsum.age_max
                                           UNION ALL
                                           SELECT vsum.id_vital_sign,
                                                  vsum.id_unit_measure,
                                                  vsum.id_institution,
                                                  vsum.id_software,
                                                  vsum.age_min,
                                                  vsum.age_max,
                                                  vsum.val_min,
                                                  vsum.val_max,
                                                  vsum.decimals,
                                                  vsum.format_num,
                                                  2 rank
                                             FROM vital_sign_unit_measure vsum
                                            WHERE vsum.id_vital_sign = i_id_vital_sign
                                              AND nvl(vsum.id_unit_measure, 0) = nvl(i_id_unit_measure, 0)
                                              AND vsum.id_institution = i_id_institution
                                              AND vsum.id_software = i_id_software
                                              AND vsum.age_min IS NULL
                                              AND vsum.age_max IS NULL) aux2
                                    ORDER BY aux2.rank ASC) aux
                            WHERE rownum = 1)
        LOOP
            PIPE ROW(l_rec_vsum);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN;
    END tf_vital_sign_unit_measure;

    FUNCTION get_vsum_val_min
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_unit_measure.id_vital_sign%TYPE,
        i_id_unit_measure IN vital_sign_unit_measure.id_unit_measure%TYPE,
        i_id_institution  IN vital_sign_unit_measure.id_institution%TYPE,
        i_id_software     IN vital_sign_unit_measure.id_software%TYPE,
        i_age             IN vital_sign_unit_measure.age_min%TYPE
    ) RETURN vital_sign_unit_measure.val_min%TYPE IS
    
        l_return vital_sign_unit_measure.val_min%TYPE;
    
    BEGIN
    
        SELECT vsum.val_min
          INTO l_return
          FROM TABLE(pk_vital_sign_core.tf_vital_sign_unit_measure(i_lang            => i_lang,
                                                                   i_prof            => i_prof,
                                                                   i_id_vital_sign   => i_id_vital_sign,
                                                                   i_id_unit_measure => i_id_unit_measure,
                                                                   i_id_institution  => i_id_institution,
                                                                   i_id_software     => i_id_software,
                                                                   i_age             => i_age)) vsum;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_vsum_val_min;

    FUNCTION get_vsum_val_max
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_unit_measure.id_vital_sign%TYPE,
        i_id_unit_measure IN vital_sign_unit_measure.id_unit_measure%TYPE,
        i_id_institution  IN vital_sign_unit_measure.id_institution%TYPE,
        i_id_software     IN vital_sign_unit_measure.id_software%TYPE,
        i_age             IN vital_sign_unit_measure.age_min%TYPE
    ) RETURN vital_sign_unit_measure.val_max%TYPE IS
    
        l_return vital_sign_unit_measure.val_max%TYPE;
    
    BEGIN
    
        SELECT vsum.val_max
          INTO l_return
          FROM TABLE(pk_vital_sign_core.tf_vital_sign_unit_measure(i_lang            => i_lang,
                                                                   i_prof            => i_prof,
                                                                   i_id_vital_sign   => i_id_vital_sign,
                                                                   i_id_unit_measure => i_id_unit_measure,
                                                                   i_id_institution  => i_id_institution,
                                                                   i_id_software     => i_id_software,
                                                                   i_age             => i_age)) vsum;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_vsum_val_max;

    FUNCTION get_vsum_format_num
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_unit_measure.id_vital_sign%TYPE,
        i_id_unit_measure IN vital_sign_unit_measure.id_unit_measure%TYPE,
        i_id_institution  IN vital_sign_unit_measure.id_institution%TYPE,
        i_id_software     IN vital_sign_unit_measure.id_software%TYPE,
        i_age             IN vital_sign_unit_measure.age_min%TYPE
    ) RETURN vital_sign_unit_measure.format_num%TYPE IS
    
        l_return vital_sign_unit_measure.format_num%TYPE;
    
    BEGIN
    
        SELECT vsum.format_num
          INTO l_return
          FROM TABLE(pk_vital_sign_core.tf_vital_sign_unit_measure(i_lang            => i_lang,
                                                                   i_prof            => i_prof,
                                                                   i_id_vital_sign   => i_id_vital_sign,
                                                                   i_id_unit_measure => i_id_unit_measure,
                                                                   i_id_institution  => i_id_institution,
                                                                   i_id_software     => i_id_software,
                                                                   i_age             => i_age)) vsum;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_vsum_format_num;

    FUNCTION get_vsum_decimals
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_unit_measure.id_vital_sign%TYPE,
        i_id_unit_measure IN vital_sign_unit_measure.id_unit_measure%TYPE,
        i_id_institution  IN vital_sign_unit_measure.id_institution%TYPE,
        i_id_software     IN vital_sign_unit_measure.id_software%TYPE,
        i_age             IN vital_sign_unit_measure.age_min%TYPE
    ) RETURN vital_sign_unit_measure.decimals%TYPE IS
    
        l_return vital_sign_unit_measure.decimals%TYPE;
    
    BEGIN
    
        SELECT vsum.decimals
          INTO l_return
          FROM TABLE(pk_vital_sign_core.tf_vital_sign_unit_measure(i_lang            => i_lang,
                                                                   i_prof            => i_prof,
                                                                   i_id_vital_sign   => i_id_vital_sign,
                                                                   i_id_unit_measure => i_id_unit_measure,
                                                                   i_id_institution  => i_id_institution,
                                                                   i_id_software     => i_id_software,
                                                                   i_age             => i_age)) vsum;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_vsum_decimals;
    /************************************************************************************************************
    * GET EDIT INFO
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign_read        vsr id
    * @param      o_info                      cursor out
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2013/02/07
    ***********************************************************************************************************/
    FUNCTION get_edit_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_screen             IN VARCHAR2,
        i_flg_view           IN vs_soft_inst.flg_view%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(30) := 'get_edit_info';
        l_documented   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_M015');
        l_label_reason sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_M014');
        l_last_update  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_M016');
        l_space      CONSTANT VARCHAR2(1 CHAR) := ' ';
        l_colon      CONSTANT VARCHAR2(1 CHAR) := ':';
        l_semicolon  CONSTANT VARCHAR2(1 CHAR) := ';';
        l_open       CONSTANT VARCHAR2(1 CHAR) := '(';
        l_close      CONSTANT VARCHAR2(1 CHAR) := ')';
        l_open_bold  CONSTANT VARCHAR2(3 CHAR) := '<b>';
        l_close_bold CONSTANT VARCHAR2(4 CHAR) := '</b>';
        tb_attributes           table_clob;
        l_id_market             market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
        l_attributes            CLOB;
        l_edit_reason           sys_message.desc_message%TYPE;
        l_signature             sys_message.desc_message%TYPE;
        l_flg_mandatory_er      sys_message.desc_message%TYPE;
        l_vs_info               sys_message.desc_message%TYPE;
        l_mandatory_edit_reason sys_config.value%TYPE;
        l_value                 sys_message.desc_message%TYPE := ' - ' ||
                                                                 pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'VITAL_SIGNS_READ_T015');
        l_clin_date             sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'MONITOR_T031');
        l_decimal_symbol CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software);
    BEGIN
    
        IF i_id_vital_sign_read IS NOT NULL
        THEN
        
            l_mandatory_edit_reason := pk_sysconfig.get_config(i_prof    => i_prof,
                                                               i_code_cf => 'VS_MANDATORY_EDIT_REASON');
        
            BEGIN
                SELECT CASE
                            WHEN t.id_edit_reason IS NOT NULL THEN
                             l_label_reason || l_colon || l_space || t.edit_reason
                            ELSE
                             NULL
                        END edit_reason,
                       
                       CASE
                            WHEN t.count_hist > 0 THEN
                             l_last_update
                            ELSE
                             l_documented
                        END || l_colon || l_space || name_signature || l_space || CASE
                            WHEN t.spec_signature IS NULL THEN
                             NULL
                            ELSE
                             l_open || t.spec_signature || l_close
                        END || l_semicolon || l_space || t.dt_reg signature,
                       
                       CASE
                            WHEN i_prof.id <> t.id_prof_read
                                 AND l_mandatory_edit_reason = pk_alert_constant.g_yes THEN
                             pk_alert_constant.g_yes
                            ELSE
                             pk_alert_constant.g_no
                        END flg_mandatory_er,
                       
                       l_open_bold || t.vital_sign_desc || CASE
                            WHEN t.vs_scales_desc IS NOT NULL THEN
                             l_space || l_open || t.vs_scales_desc || l_close
                            ELSE
                             NULL
                        END || l_value || l_close_bold || l_space || t.value_desc || CASE
                            WHEN t.desc_um IS NOT NULL THEN
                             l_space || t.desc_um
                            ELSE
                             NULL
                        END || l_semicolon || l_space || l_open_bold || l_clin_date || l_close_bold || l_space ||
                        t.dt_vital_sign_read vs_info
                
                  INTO l_edit_reason, l_signature, l_flg_mandatory_er, l_vs_info
                
                  FROM (SELECT vsr.id_edit_reason,
                               vsr.id_prof_read,
                               CASE
                                    WHEN cr.flg_notes_mandatory = pk_alert_constant.g_yes THEN
                                     pk_translation.get_translation_trs(vsr.code_notes_edit)
                                    ELSE
                                     to_clob(pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, vsr.id_edit_reason))
                                END edit_reason,
                               (SELECT COUNT(1)
                                  FROM vital_sign_read_hist vsrh
                                 WHERE vsrh.id_vital_sign_read = vsr.id_vital_sign_read) count_hist,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, vsr.id_prof_read) name_signature,
                               pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                vsr.id_prof_read,
                                                                vsr.dt_registry,
                                                                vsr.id_episode) spec_signature,
                               pk_date_utils.date_char_tsz(i_lang, vsr.dt_registry, i_prof.institution, i_prof.software) dt_reg,
                               pk_translation.get_translation(i_lang, nvl(vs_c.code_vital_sign, vs.code_vital_sign)) vital_sign_desc,
                               pk_translation.get_translation(i_lang, vss.code_vital_sign_scales) vs_scales_desc,
                               pk_vital_sign_core.get_vs_value(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_id_patient          => vsr.id_patient,
                                                               i_id_episode          => vsr.id_episode,
                                                               i_id_vital_sign       => nvl(vr.id_vital_sign_parent,
                                                                                            vsr.id_vital_sign),
                                                               i_id_vital_sign_desc  => vsr.id_vital_sign_desc,
                                                               i_dt_vital_sign_read  => vsr.dt_vital_sign_read_tstz,
                                                               i_id_unit_measure_vsr => vsr.id_unit_measure,
                                                               i_id_unit_measure_vsi => vsr.id_unit_measure,
                                                               i_value               => vsr.value,
                                                               i_decimal_symbol      => l_decimal_symbol,
                                                               i_relation_domain     => vr.relation_domain,
                                                               i_dt_registry         => vsr.dt_registry) value_desc,
                               (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                  FROM unit_measure um
                                 WHERE um.id_unit_measure = decode(pk_vital_sign.get_vs_scale(vsr.id_vs_scales_element),
                                                                   NULL,
                                                                   vsr.id_unit_measure,
                                                                   (SELECT vsse.id_unit_measure
                                                                      FROM vital_sign_scales_element vsse
                                                                     WHERE vsse.id_vital_sign_scales =
                                                                           pk_vital_sign.get_vs_scale(vsr.id_vs_scales_element)
                                                                       AND rownum = 1))) desc_um,
                               (SELECT pk_date_utils.date_char_tsz(i_lang,
                                                                   vsr.dt_vital_sign_read_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software)
                                  FROM dual) dt_vital_sign_read
                          FROM vital_sign_read vsr
                        
                          JOIN vital_sign vs
                            ON vs.id_vital_sign = vsr.id_vital_sign
                        
                          LEFT JOIN cancel_reason cr
                            ON cr.id_cancel_reason = vsr.id_edit_reason
                        
                          LEFT JOIN vital_sign_relation vr
                            ON vsr.id_vital_sign = vr.id_vital_sign_detail
                           AND vr.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                           AND vr.flg_available = pk_alert_constant.g_yes
                        
                          LEFT JOIN vital_sign vs_c
                            ON vs_c.id_vital_sign = vr.id_vital_sign_parent
                        
                          LEFT JOIN vital_sign_scales vss
                            ON vss.id_vital_sign_scales = pk_vital_sign.get_vs_scale(vsr.id_vs_scales_element)
                        
                         WHERE vsr.id_vital_sign_read = i_id_vital_sign_read) t;
            
            EXCEPTION
                WHEN OTHERS THEN
                    l_edit_reason      := NULL;
                    l_signature        := NULL;
                    l_flg_mandatory_er := NULL;
                    l_vs_info          := NULL;
            END;
        
            IF i_screen = 'C'
            THEN
            
                BEGIN
                    SELECT l_open_bold || aux.l_vsa_label || l_close_bold || l_colon || l_space || aux.l_vsa_value attributes
                      BULK COLLECT
                      INTO tb_attributes
                      FROM (SELECT pk_translation.get_translation(i_lang, vsap.code_vs_attribute) l_vsa_label,
                                   nvl(htf.escape_sc(ctext => vsra.free_text),
                                       pk_translation.get_translation(i_lang, vsa.code_vs_attribute)) l_vsa_value,
                                   (SELECT pk_vital_sign_core.get_vsa_rank(i_lang,
                                                                           i_prof,
                                                                           vsr.id_vital_sign,
                                                                           vsap.id_vs_attribute,
                                                                           l_id_market)
                                      FROM dual) rank
                              FROM vs_read_attribute vsra
                              JOIN vs_attribute vsa
                                ON vsa.id_vs_attribute = vsra.id_vs_attribute
                              JOIN vs_attribute vsap
                                ON vsap.id_vs_attribute = vsa.id_parent
                              JOIN vital_sign_read vsr
                                ON vsr.id_vital_sign_read = vsra.id_vital_sign_read
                             WHERE vsra.id_vital_sign_read = i_id_vital_sign_read) aux
                     ORDER BY aux.rank ASC NULLS LAST;
                EXCEPTION
                    WHEN no_data_found THEN
                        tb_attributes := table_clob();
                END;
            
                l_attributes := pk_utils.concat_table(tb_attributes, l_semicolon || l_space);
            
                g_error := 'open o_info';
                OPEN o_info FOR
                    SELECT l_attributes attributes, l_signature signature, l_vs_info vs_info
                      FROM dual;
            
            ELSE
            
                g_error := 'open o_info';
                OPEN o_info FOR
                    SELECT l_signature signature, l_flg_mandatory_er flg_mandatory_er
                      FROM dual;
            
            END IF;
        ELSE
            pk_types.open_my_cursor(o_info);
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
                                              c_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_edit_info;
    FUNCTION count_scale_elements
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_id_vital_sign_scale IN vital_sign_scales.id_vital_sign_scales%TYPE,
        i_id_triage_type      IN triage_type.id_triage_type%TYPE,
        i_id_vital_sign       IN vital_sign.id_vital_sign%TYPE
    ) RETURN NUMBER IS
        l_return NUMBER(12) := 0;
        o_cursor pk_types.cursor_type;
    
    BEGIN
        g_error := 'count_scale_elements';
        IF NOT pk_vital_sign.get_scale_elements(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_episode             => i_episode,
                                                i_id_vital_sign_scale => i_id_vital_sign_scale,
                                                i_id_triage_type      => i_id_triage_type,
                                                i_id_vital_sign       => i_id_vital_sign,
                                                scale_element_cursor  => o_cursor)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error  := 'pk_utils.get_rowcount';
        l_return := pk_utils.get_rowcount(o_cursor);
        --o_cursor.
    
        --
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END count_scale_elements;
    /**********************************************************************************************
    * get_viewer_vs_shortcut
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         id_sys_shortcut
    *
    * @author                         Paulo Teixeira
    * @version                        2.6.3
    * @since                          2014/03/11
    **********************************************************************************************/
    FUNCTION get_viewer_vs_shortcut
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN profile_templ_access.id_sys_shortcut%TYPE IS
        l_id_sys_shortcut profile_templ_access.id_sys_shortcut%TYPE;
        l_error           t_error_out;
    BEGIN
    
        IF NOT pk_access.get_sys_shortcut(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_id_sys_button_prop => NULL,
                                          i_screen_name        => g_vs_grid_screen_name,
                                          o_id_sys_shortcut    => l_id_sys_shortcut,
                                          o_error              => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN l_id_sys_shortcut;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_viewer_vs_shortcut;
    /************************************************************************************************************
    * get_vs_most_recent_value
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign             vital_sign identifier
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_dt_begin               Begin date
    * @param      i_dt_end                 end date
    * @param      o_info                      cursor out
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2014/09/30
    ***********************************************************************************************************/
    FUNCTION get_vs_most_recent_value
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign_read.id_vital_sign%TYPE,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_dt_begin      IN VARCHAR2 DEFAULT NULL,
        i_dt_end        IN VARCHAR2 DEFAULT NULL,
        o_info          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(30) := 'GET_VS_MOST_RECENT_VALUE';
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_dt_begin   TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_dt_end     TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_space          CONSTANT VARCHAR2(1 CHAR) := ' ';
        l_decimal_symbol CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software);
    BEGIN
    
        g_error := 'call pk_touch_option.get_scope_vars';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Convert end date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'open o_info';
        OPEN o_info FOR
            SELECT aux.id_vital_sign_read,
                   aux.value,
                   aux.id_unit_measure,
                   aux.dt_vital_sign_read_tstz,
                   aux.id_episode,
                   aux.vital_sign_desc,
                   aux.vs_scales_desc,
                   aux.value_desc || CASE
                        WHEN aux.id_unit_measure IS NOT NULL THEN
                         l_space || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                       FROM unit_measure um
                                      WHERE um.id_unit_measure = aux.id_unit_measure)
                        ELSE
                         NULL
                    END value_desc,
                   aux.dt_registry
              FROM (SELECT t.value,
                           t.dt_vital_sign_read_tstz,
                           t.id_episode,
                           pk_vital_sign_core.get_vs_value(i_lang                => i_lang,
                                                           i_prof                => i_prof,
                                                           i_id_patient          => t.id_patient,
                                                           i_id_episode          => t.id_episode,
                                                           i_id_vital_sign       => nvl(t.id_vital_sign_parent,
                                                                                        t.id_vital_sign),
                                                           i_id_vital_sign_desc  => t.id_vital_sign_desc,
                                                           i_dt_vital_sign_read  => t.dt_vital_sign_read_tstz,
                                                           i_id_unit_measure_vsr => t.id_unit_measure,
                                                           i_id_unit_measure_vsi => t.id_unit_measure,
                                                           i_value               => t.value,
                                                           i_decimal_symbol      => l_decimal_symbol,
                                                           i_relation_domain     => t.relation_domain,
                                                           i_dt_registry         => t.dt_registry) value_desc,
                           pk_translation.get_translation(i_lang, nvl(t.vs_c_code_vital_sign, t.vs_code_vital_sign)) vital_sign_desc,
                           pk_translation.get_translation(i_lang, t.code_vital_sign_scales) vs_scales_desc,
                           CASE
                                WHEN pk_vital_sign.get_vs_scale(t.id_vs_scales_element) IS NULL THEN
                                 t.id_unit_measure
                                ELSE
                                 (SELECT vsse.id_unit_measure
                                    FROM vital_sign_scales_element vsse
                                   WHERE vsse.id_vital_sign_scales = pk_vital_sign.get_vs_scale(t.id_vs_scales_element)
                                     AND rownum = 1)
                            END id_unit_measure,
                           t.dt_registry,
                           t.id_vital_sign_read
                      FROM (SELECT row_number() over(ORDER BY vsr.dt_vital_sign_read_tstz DESC NULLS LAST) rn,
                                   vsr.value,
                                   vsr.dt_vital_sign_read_tstz,
                                   vsr.id_patient,
                                   vsr.id_episode,
                                   vr.id_vital_sign_parent,
                                   vsr.id_vital_sign,
                                   vsr.id_vital_sign_desc,
                                   vsr.id_unit_measure,
                                   vr.relation_domain,
                                   vsr.dt_registry,
                                   vsr.id_vs_scales_element,
                                   vs.code_vital_sign vs_code_vital_sign,
                                   vs_c.code_vital_sign vs_c_code_vital_sign,
                                   vss.code_vital_sign_scales,
                                   vsr.id_vital_sign_read
                              FROM vital_sign_read vsr
                            
                              JOIN (SELECT *
                                     FROM episode e
                                    WHERE e.id_episode = l_id_episode
                                      AND e.id_patient = l_id_patient
                                      AND i_scope_type = pk_alert_constant.g_scope_type_episode
                                   UNION ALL
                                   SELECT *
                                     FROM episode e
                                    WHERE e.id_patient = l_id_patient
                                      AND i_scope_type = pk_alert_constant.g_scope_type_patient
                                   UNION ALL
                                   SELECT *
                                     FROM episode e
                                    WHERE e.id_visit = l_id_visit
                                      AND e.id_patient = l_id_patient
                                      AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                                ON vsr.id_episode = epi.id_episode
                            
                              JOIN vital_sign vs
                                ON vs.id_vital_sign = vsr.id_vital_sign
                            
                              LEFT JOIN vital_sign_relation vr
                                ON vsr.id_vital_sign = vr.id_vital_sign_detail
                               AND vr.relation_domain IN
                                   (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                               AND vr.flg_available = pk_alert_constant.g_yes
                            
                              LEFT JOIN vital_sign vs_c
                                ON vs_c.id_vital_sign = vr.id_vital_sign_parent
                            
                              LEFT JOIN vital_sign_scales vss
                                ON vss.id_vital_sign_scales = pk_vital_sign.get_vs_scale(vsr.id_vs_scales_element)
                            
                             WHERE vsr.flg_state = pk_vital_sign.c_flg_status_active
                               AND (vsr.id_vital_sign = i_id_vital_sign OR vr.id_vital_sign_parent = i_id_vital_sign)
                               AND ((l_dt_begin IS NULL) OR
                                   (l_dt_begin IS NOT NULL AND vsr.dt_vital_sign_read_tstz >= l_dt_begin))
                               AND ((l_dt_end IS NULL) OR
                                   (l_dt_end IS NOT NULL AND vsr.dt_vital_sign_read_tstz <= l_dt_end))) t
                     WHERE t.rn = 1) aux;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_vs_most_recent_value;
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
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_tb_vs   IN table_number DEFAULT NULL,
        i_tb_view IN table_varchar DEFAULT NULL,
        o_vs      OUT pk_types.cursor_type,
        o_um      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(30) := 'GET_PDMS_MODULE_VITAL_SIGNS';
        l_age             vital_sign_unit_measure.age_min%TYPE;
        l_market          market.id_market%TYPE := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        i_tb_vs_isempty   NUMBER(2);
        i_tb_view_isempty NUMBER(2);
    
    BEGIN
        IF i_tb_vs IS NULL
           OR i_tb_vs.count = 0
        THEN
            i_tb_vs_isempty := 1;
        ELSE
            i_tb_vs_isempty := 0;
        END IF;
    
        IF i_tb_view IS NULL
           OR i_tb_view.count = 0
        THEN
            i_tb_view_isempty := 1;
        ELSE
            i_tb_view_isempty := 0;
        END IF;
    
        g_error := 'call pk_patient.get_pat_age';
        l_age   := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
    
        g_error := 'open o_vs';
        OPEN o_vs FOR
            SELECT aux.id_vital_sign,
                   aux.id_vital_sign_scales,
                   aux.flg_view,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) AS name_vs,
                   pk_translation.get_translation(i_lang, vs.code_vs_short_desc) AS short_name_vs,
                   pk_translation.get_translation(i_lang, aux.code_vital_sign_scales) AS pain_descr,
                   pk_translation.get_translation(i_lang, aux.code_vital_sign_scales_short) AS pain_descr_short,
                   aux.color_grafh color_graph,
                   vsr_min.id_vital_sign_detail id_vital_sign_min,
                   vsr_max.id_vital_sign_detail id_vital_sign_max,
                   CASE (SELECT COUNT(1)
                       FROM vital_sign_relation vrpar
                      WHERE aux.id_vital_sign = vrpar.id_vital_sign_parent
                        AND vrpar.relation_domain = pk_alert_constant.g_vs_rel_sum
                        AND vrpar.flg_available = pk_alert_constant.g_yes)
                       WHEN 0 THEN
                        vs.flg_fill_type
                       ELSE
                        'X'
                   END AS flg_fill_type,
                   aux.id_unit_measure,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, aux.id_unit_measure) desc_unit_measure,
                   (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => aux.id_vital_sign,
                                                               i_id_unit_measure => aux.id_unit_measure,
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => l_age)
                      FROM dual) val_min,
                   (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => aux.id_vital_sign,
                                                               i_id_unit_measure => aux.id_unit_measure,
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => l_age)
                      FROM dual) val_max,
                   (SELECT pk_vital_sign_core.get_vsum_format_num(i_lang            => i_lang,
                                                                  i_prof            => i_prof,
                                                                  i_id_vital_sign   => aux.id_vital_sign,
                                                                  i_id_unit_measure => aux.id_unit_measure,
                                                                  i_id_institution  => i_prof.institution,
                                                                  i_id_software     => i_prof.software,
                                                                  i_age             => l_age)
                      FROM dual) format_num,
                   (SELECT pk_vital_sign_core.get_vsum_decimals(i_lang            => i_lang,
                                                                i_prof            => i_prof,
                                                                i_id_vital_sign   => aux.id_vital_sign,
                                                                i_id_unit_measure => aux.id_unit_measure,
                                                                i_id_institution  => i_prof.institution,
                                                                i_id_software     => i_prof.software,
                                                                i_age             => l_age)
                      FROM dual) decimals,
                   aux.internal_name,
                   aux.id_vital_sign_parent,
                   aux.rank,
                   aux.rank_conc,
                   (SELECT get_vs_childs(aux.id_vital_sign)
                      FROM dual) vs_childs
              FROM (SELECT vsi.id_vital_sign,
                           vss.id_vital_sign_scales,
                           vsi.flg_view,
                           vss.code_vital_sign_scales,
                           vss.code_vital_sign_scales_short,
                           vsi.id_unit_measure,
                           vsi.color_grafh,
                           vss.internal_name,
                           vsr.id_vital_sign_parent,
                           vsi.rank,
                           vsr.rank rank_conc
                      FROM vs_soft_inst vsi
                    
                      LEFT JOIN vital_sign_relation vsr
                        ON vsr.id_vital_sign_detail = vsi.id_vital_sign
                       AND vsr.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                    
                      LEFT JOIN vital_sign_scales vss
                        ON vss.id_vital_sign = vsi.id_vital_sign
                    
                     WHERE vsi.id_institution = i_prof.institution
                       AND vsi.id_software = i_prof.software
                       AND (vsi.flg_view IN (SELECT /*+ OPT_ESTIMATE (TABLE d ROWS=1)*/
                                              column_value
                                               FROM TABLE(i_tb_view) d) OR i_tb_view_isempty = 1)
                          
                       AND (vsi.id_vital_sign IN (SELECT /*+ OPT_ESTIMATE (TABLE k ROWS=1)*/
                                                   column_value
                                                    FROM TABLE(i_tb_vs) k) OR i_tb_vs_isempty = 1)
                          
                       AND (NOT EXISTS (SELECT 1
                                          FROM vital_sign_scales_triage vsst
                                         WHERE vsst.id_vital_sign_scales = vss.id_vital_sign_scales
                                           AND vsst.flg_scale_type = pk_edis_triage.g_manchester) OR
                            vss.id_vital_sign_scales IS NULL)
                          
                       AND (((SELECT is_vss_available(i_lang, i_prof, vss.id_vital_sign_scales)
                                FROM dual) = pk_alert_constant.g_yes) OR vss.id_vital_sign_scales IS NULL)) aux
            
              JOIN vital_sign vs
                ON vs.id_vital_sign = aux.id_vital_sign
            
              LEFT JOIN vital_sign_relation vsr_min
                ON vsr_min.id_vital_sign_parent = vs.id_vital_sign
               AND vsr_min.relation_domain IN (pk_alert_constant.g_vs_rel_conc)
               AND vsr_min.rank = 1
            
              LEFT JOIN vital_sign_relation vsr_max
                ON vsr_max.id_vital_sign_parent = vs.id_vital_sign
               AND vsr_max.relation_domain = pk_alert_constant.g_vs_rel_conc
               AND vsr_max.rank = 2
            
             ORDER BY aux.id_vital_sign, aux.id_vital_sign_scales;
    
        g_error := 'open o_um';
        OPEN o_um FOR
            SELECT aux.id_vital_sign,
                   aux.id_unit_measure,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, aux.id_unit_measure) desc_unit_measure,
                   (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => aux.id_vital_sign,
                                                               i_id_unit_measure => aux.id_unit_measure,
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => l_age)
                      FROM dual) val_min,
                   (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => aux.id_vital_sign,
                                                               i_id_unit_measure => aux.id_unit_measure,
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => l_age)
                      FROM dual) val_max,
                   (SELECT pk_vital_sign_core.get_vsum_format_num(i_lang            => i_lang,
                                                                  i_prof            => i_prof,
                                                                  i_id_vital_sign   => aux.id_vital_sign,
                                                                  i_id_unit_measure => aux.id_unit_measure,
                                                                  i_id_institution  => i_prof.institution,
                                                                  i_id_software     => i_prof.software,
                                                                  i_age             => l_age)
                      FROM dual) format_num
              FROM (SELECT umcsi.id_vital_sign,
                           umc.id_unit_measure1 id_unit_measure,
                           row_number() over(PARTITION BY umcsi.id_unit_measure_convert ORDER BY umcsi.id_software DESC, umcsi.id_institution DESC, umcsi.id_market DESC) rn,
                           umcsi.rank
                      FROM unit_measure_convert umc
                      JOIN unit_mea_conv_soft_inst umcsi
                        ON umc.id_unit_measure_convert = umcsi.id_unit_measure_convert
                       AND umcsi.id_market IN (pk_alert_constant.g_id_market_all, l_market)
                       AND umcsi.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND umcsi.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)) aux
             WHERE rn = 1
               AND EXISTS (SELECT 1
                      FROM vs_soft_inst vsi
                     WHERE vsi.id_vital_sign = aux.id_vital_sign
                       AND vsi.id_institution = i_prof.institution
                       AND vsi.id_software = i_prof.software
                       AND (vsi.flg_view IN (SELECT /*+ OPT_ESTIMATE (TABLE d ROWS=1)*/
                                              column_value
                                               FROM TABLE(i_tb_view) d) OR i_tb_view_isempty = 1)
                       AND (vsi.id_vital_sign IN (SELECT /*+ OPT_ESTIMATE (TABLE k ROWS=1)*/
                                                   column_value
                                                    FROM TABLE(i_tb_vs) k) OR i_tb_vs_isempty = 1)
                       AND rownum = 1);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_vs);
            pk_types.open_my_cursor(o_um);
            RETURN FALSE;
    END get_pdms_module_vital_signs;

    /************************************************************************************************************
    * get_vs_value_dt_reg
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign_read        vital sign read identifier
    * @param      i_dt_vs_read                clinical date
    * @param      i_dt_registry               registered date
    *
    * @return     vital sign value
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2014/11/25
    ***********************************************************************************************************/
    FUNCTION get_vs_value_dt_reg
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_dt_vs_read         IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(30) := 'get_vs_value_dt_reg';
    BEGIN
        IF i_id_vital_sign_read IS NULL
           OR i_dt_registry IS NULL
           OR i_dt_vs_read IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        OPEN o_info FOR
            SELECT aux2.id_vital_sign_read id_vital_sign_read,
                   aux2.full_value full_value,
                   aux2.id_unit_measure,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, aux2.id_unit_measure) val_unit_measure,
                   aux2.dt_vital_sign_read_tstz,
                   aux2.dt_registry
              FROM (SELECT aux.full_value,
                           row_number() over(ORDER BY aux.rank ASC, aux.id_vsrh DESC NULLS FIRST) rn,
                           aux.id_vital_sign_read,
                           aux.id_unit_measure,
                           aux.dt_vital_sign_read_tstz,
                           aux.dt_registry
                      FROM (SELECT 1 rank,
                                   NULL id_vsrh,
                                   vsr.id_vital_sign_read,
                                   vsr.id_unit_measure,
                                   vsr.dt_vital_sign_read_tstz,
                                   pk_vital_sign.get_full_value(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_vsr         => vsr.id_vital_sign_read,
                                                                i_vital_sign  => vsr.id_vital_sign,
                                                                i_value       => nvl(pk_utils.number_to_char(i_prof,
                                                                                                             vsr.value),
                                                                                     pk_vital_sign.get_vsd_desc(i_lang,
                                                                                                                vsr.id_vital_sign_desc,
                                                                                                                vsr.id_patient)),
                                                                i_dt_read     => vsr.dt_vital_sign_read_tstz,
                                                                i_dt_registry => vsr.dt_vital_sign_read_tstz) full_value,
                                   vsr.dt_registry
                              FROM (SELECT t.id_vital_sign_read,
                                           t.id_unit_measure,
                                           t.dt_vital_sign_read_tstz,
                                           t.id_vital_sign,
                                           t.value,
                                           t.id_vital_sign_desc,
                                           t.id_patient,
                                           t.dt_registry,
                                           -- Truncate date to the format used in PRESC.
                                           pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                            i_timestamp => t.dt_registry,
                                                                            i_format    => 'SS') dt_registry_converted
                                      FROM vital_sign_read t
                                     WHERE t.id_vital_sign_read = i_id_vital_sign_read
                                       AND t.dt_vital_sign_read_tstz = i_dt_vs_read) vsr
                             WHERE vsr.dt_registry_converted = i_dt_registry -- Match date saved in PRESC.
                            UNION ALL
                            SELECT 2 rank,
                                   vsrh.id_vital_sign_read_hist id_vsrh,
                                   vsr.id_vital_sign_read,
                                   vsrh.id_unit_measure,
                                   vsrh.dt_vital_sign_read_tstz,
                                   pk_vital_sign.get_full_value(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_vsr         => vsrh.id_vital_sign_read,
                                                                i_vital_sign  => vsr.id_vital_sign,
                                                                i_value       => nvl(pk_utils.number_to_char(i_prof,
                                                                                                             vsrh.value),
                                                                                     pk_vital_sign.get_vsd_desc(i_lang,
                                                                                                                vsrh.id_vital_sign_desc,
                                                                                                                vsr.id_patient)),
                                                                i_dt_read     => vsrh.dt_vital_sign_read_tstz,
                                                                i_dt_registry => vsrh.dt_vital_sign_read_tstz) full_value,
                                   vsrh.dt_registry
                              FROM (SELECT t.id_vital_sign_read_hist,
                                           t.id_vital_sign_read,
                                           t.id_unit_measure,
                                           t.dt_vital_sign_read_tstz,
                                           t.value,
                                           t.id_vital_sign_desc,
                                           t.dt_registry,
                                           -- Truncate date to the format used in PRESC.
                                           pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                            i_timestamp => t.dt_registry,
                                                                            i_format    => 'SS') dt_registry_converted
                                      FROM vital_sign_read_hist t
                                     WHERE t.id_vital_sign_read = i_id_vital_sign_read
                                       AND t.dt_vital_sign_read_tstz = i_dt_vs_read) vsrh
                              JOIN vital_sign_read vsr
                                ON vsr.id_vital_sign_read = vsrh.id_vital_sign_read
                            -- Match date saved in PRESC
                             WHERE vsrh.dt_registry_converted = i_dt_registry) aux) aux2
             WHERE aux2.rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_vs_value_dt_reg;
    /************************************************************************************************************/
    FUNCTION get_vs_childs(i_vs IN vital_sign.id_vital_sign%TYPE) RETURN table_number IS
        l_ret table_number;
    BEGIN
        -- returns vs_childs
        SELECT vsr.id_vital_sign_detail
          BULK COLLECT
          INTO l_ret
          FROM vital_sign_relation vsr
         WHERE vsr.id_vital_sign_parent = i_vs
           AND vsr.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum);
    
        RETURN l_ret;
    END;
    /************************************************************************************************************/
    FUNCTION is_vss_available
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_vital_sign_scales IN vital_sign_scales.id_vital_sign_scales%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1 CHAR);
    BEGIN
        SELECT pk_alert_constant.g_yes
          INTO l_ret
          FROM (SELECT vssa.flg_available,
                       row_number() over(PARTITION BY vssa.id_vital_sign_scales ORDER BY vssa.id_institution DESC, vssa.id_software DESC) rn
                  FROM vital_sign_scales_access vssa
                 WHERE vssa.id_vital_sign_scales = i_id_vital_sign_scales
                   AND vssa.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                   AND vssa.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)) t
         WHERE t.rn = 1
           AND t.flg_available = pk_alert_constant.g_yes;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END;

    /** This function returns the dates to filter information in vs grid
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_dt_filter                 Date which we should treat as last date for records
    *
    * @param      o_has_prev                  flag indicating if exist any previously registered values
    * @param      o_dt_begin                  Date begin to be shown in grid
    * @param      o_dt_begin                  Date end to be shown in grid
    * @param      o_error                     error out
    *
    * @author                                Anna Kurowska
    * @version                               2.7.5.2
    * @since                                 2019-03.14
    *
    ************************************************************************************************************/
    FUNCTION get_vs_dates_to_load
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_view          IN vs_soft_inst.flg_view%TYPE,
        i_scope             IN NUMBER DEFAULT NULL,
        i_scope_type        IN VARCHAR2 DEFAULT NULL,
        i_dt_filter         IN VARCHAR2 DEFAULT NULL,
        i_flg_use_soft_inst IN VARCHAR2 DEFAULT pk_alert_constant.g_yes, -- flg inficating if get_vital_sign_records uses vs_soft_inst to retrieve records
        o_has_prev          OUT VARCHAR2,
        o_dt_begin          OUT VARCHAR2,
        o_dt_end            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_VS_DATES_TO_LOAD';
    
        l_date             table_timestamp_tstz := table_timestamp_tstz();
        l_dt_begin         vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_has_prev         BOOLEAN := FALSE;
        l_dt_vs_read       vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_dbg_msg          debug_msg;
        e_invalid_argument EXCEPTION;
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    BEGIN
    
        IF (i_scope IS NOT NULL AND i_scope_type IS NOT NULL)
        THEN
            g_error := 'ANALYSING SCOPE TYPE';
            IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_scope      => i_scope,
                                                  i_scope_type => i_scope_type,
                                                  o_patient    => l_id_patient,
                                                  o_visit      => l_id_visit,
                                                  o_episode    => l_id_episode,
                                                  o_error      => o_error)
            THEN
                RAISE e_invalid_argument;
            END IF;
        
            IF (i_dt_filter IS NOT NULL)
            THEN
                l_dt_vs_read := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => i_dt_filter,
                                                              i_timezone  => NULL);
            ELSE
                l_dt_vs_read := NULL;
            END IF;
        
            l_dbg_msg := 'CALL pk_date_utils.trunc_insttimezone';
            pk_alertlog.log_debug(l_dbg_msg);
            l_dt_vs_read := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                             i_timestamp => l_dt_vs_read,
                                                             i_format    => 'MI');
        
            SELECT dt_vital_sign_read_tstz
              BULK COLLECT
              INTO l_date
              FROM (SELECT dt_vital_sign_read_tstz, rn
                      FROM (SELECT dt_vital_sign_read_tstz,
                                   row_number() over(PARTITION BY v1.dt_vital_sign_read_tstz ORDER BY dt_vital_sign_read_tstz DESC) rn
                              FROM ((SELECT vsr.id_vital_sign, vsr.dt_vital_sign_read_tstz
                                       FROM vital_sign_read vsr
                                      INNER JOIN (SELECT id_episode
                                                   FROM episode e
                                                  WHERE e.id_episode = l_id_episode
                                                    AND e.id_patient = l_id_patient
                                                    AND i_scope_type = pk_alert_constant.g_scope_type_episode
                                                 UNION ALL
                                                 SELECT id_episode
                                                   FROM episode e
                                                  WHERE e.id_patient = l_id_patient
                                                    AND i_scope_type = pk_alert_constant.g_scope_type_patient
                                                 UNION ALL
                                                 SELECT id_episode
                                                   FROM episode e
                                                  WHERE e.id_visit = l_id_visit
                                                    AND e.id_patient = l_id_patient
                                                    AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                                         ON vsr.id_episode = epi.id_episode
                                       LEFT JOIN vs_soft_inst vsi
                                         ON vsi.id_vital_sign = vsr.id_vital_sign
                                        AND vsi.id_software = i_prof.software
                                        AND vsi.id_institution = i_prof.institution
                                        AND vsi.flg_view = i_flg_view
                                      WHERE NOT EXISTS
                                      (SELECT 1
                                               FROM vital_sign_pregnancy vsp
                                              WHERE vsp.id_vital_sign_read = vsr.id_vital_sign_read
                                                AND vsp.fetus_number > 0)
                                        AND (NOT EXISTS
                                             (SELECT 1
                                                FROM vital_sign_relation vr
                                               WHERE vsr.id_vital_sign = vr.id_vital_sign_detail
                                                 AND vr.relation_domain IN
                                                     (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                                                 AND vr.flg_available = pk_alert_constant.g_yes))
                                        AND (EXISTS (SELECT 1
                                                       FROM vs_soft_inst vsi
                                                      WHERE vsi.id_vital_sign = vsr.id_vital_sign
                                                        AND vsi.id_software = i_prof.software
                                                        AND vsi.id_institution = i_prof.institution
                                                        AND vsi.flg_view = i_flg_view
                                                        AND i_flg_use_soft_inst = pk_alert_constant.g_yes) OR
                                             i_flg_use_soft_inst = pk_alert_constant.g_no)
                                        AND ((l_dt_vs_read IS NOT NULL AND vsr.dt_vital_sign_read_tstz < l_dt_vs_read) OR
                                            l_dt_vs_read IS NULL)) UNION ALL
                                    (SELECT vr.id_vital_sign_parent, vsr.dt_vital_sign_read_tstz
                                       FROM vital_sign_read vsr
                                      INNER JOIN (SELECT id_episode
                                                   FROM episode e
                                                  WHERE e.id_episode = l_id_episode
                                                    AND e.id_patient = l_id_patient
                                                    AND i_scope_type = pk_alert_constant.g_scope_type_episode
                                                 UNION ALL
                                                 SELECT id_episode
                                                   FROM episode e
                                                  WHERE e.id_patient = l_id_patient
                                                    AND i_scope_type = pk_alert_constant.g_scope_type_patient
                                                 UNION ALL
                                                 SELECT id_episode
                                                   FROM episode e
                                                  WHERE e.id_visit = l_id_visit
                                                    AND e.id_patient = l_id_patient
                                                    AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                                         ON vsr.id_episode = epi.id_episode
                                       JOIN vital_sign_relation vr
                                         ON vsr.id_vital_sign = vr.id_vital_sign_detail
                                       LEFT JOIN vs_soft_inst vsi
                                         ON vsi.id_vital_sign = vsr.id_vital_sign
                                        AND vsi.id_software = i_prof.software
                                        AND vsi.id_institution = i_prof.institution
                                        AND vsi.flg_view = i_flg_view
                                      WHERE vr.relation_domain IN
                                            (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                                        AND vr.flg_available = pk_alert_constant.g_yes
                                        AND vr.rank =
                                            (SELECT MIN(v.rank)
                                               FROM vital_sign_relation v
                                              WHERE vr.id_vital_sign_parent = v.id_vital_sign_parent
                                                AND vr.flg_available = pk_alert_constant.g_yes
                                                AND vr.relation_domain != pk_alert_constant.g_vs_rel_percentile)
                                        AND (EXISTS (SELECT 1
                                                       FROM vs_soft_inst vsi
                                                      WHERE vsi.id_vital_sign = vsr.id_vital_sign
                                                        AND vsi.id_software = i_prof.software
                                                        AND vsi.id_institution = i_prof.institution
                                                        AND vsi.flg_view = i_flg_view
                                                        AND i_flg_use_soft_inst = pk_alert_constant.g_yes) OR
                                             i_flg_use_soft_inst = pk_alert_constant.g_no)
                                        AND ((l_dt_vs_read IS NOT NULL AND vsr.dt_vital_sign_read_tstz < l_dt_vs_read) OR
                                            l_dt_vs_read IS NULL))) v1)
                     WHERE rn = 1
                     ORDER BY dt_vital_sign_read_tstz DESC)
             WHERE rownum < 11;
        
            IF l_date.count > 0
               AND l_date(1) IS NOT NULL
            THEN
            
                l_has_prev := (l_date.count = 10);
            
                o_dt_end := pk_date_utils.date_send_tsz(i_lang, l_date(1), i_prof.institution, i_prof.software);
            
                IF (l_date.count < 10)
                THEN
                    l_dt_begin := l_date(l_date.count);
                ELSE
                    l_dt_begin := l_date(l_date.count - 1);
                END IF;
                o_dt_begin := pk_date_utils.date_send_tsz(i_lang, l_dt_begin, i_prof.institution, i_prof.software);
            
                IF (l_has_prev = FALSE)
                THEN
                    o_has_prev := pk_alert_constant.get_no;
                ELSE
                    o_has_prev := pk_alert_constant.get_yes;
                END IF;
            ELSE
                o_dt_end   := NULL;
                o_dt_begin := NULL;
                o_has_prev := NULL;
            END IF;
        ELSE
            o_dt_end   := NULL;
            o_dt_begin := NULL;
            o_has_prev := NULL;
        
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            o_dt_end   := NULL;
            o_dt_begin := NULL;
            o_has_prev := NULL;
            RETURN FALSE;
    END get_vs_dates_to_load;

    FUNCTION get_dates_x_records
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER DEFAULT NULL,
        i_scope_type IN VARCHAR2 DEFAULT NULL,
        i_nr_records IN VARCHAR2 DEFAULT NULL,
        o_dt_begin   OUT VARCHAR2,
        o_dt_end     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_VS_DATES_TO_LOAD';
    
        l_date             table_timestamp_tstz := table_timestamp_tstz();
        l_dt_begin         vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_dbg_msg          debug_msg;
        e_invalid_argument EXCEPTION;
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_flg_view CONSTANT VARCHAR2(2 CHAR) := 'V2';
    BEGIN
    
        IF (i_scope IS NOT NULL AND i_scope_type IS NOT NULL)
        THEN
            g_error := 'ANALYSING SCOPE TYPE';
            IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_scope      => i_scope,
                                                  i_scope_type => i_scope_type,
                                                  o_patient    => l_id_patient,
                                                  o_visit      => l_id_visit,
                                                  o_episode    => l_id_episode,
                                                  o_error      => o_error)
            THEN
                RAISE e_invalid_argument;
            END IF;
        
            SELECT dt_vital_sign_read_tstz
              BULK COLLECT
              INTO l_date
              FROM (SELECT dt_vital_sign_read_tstz, rn
                      FROM (SELECT dt_vital_sign_read_tstz,
                                   row_number() over(PARTITION BY id_vital_sign ORDER BY dt_vital_sign_read_tstz DESC) rn
                              FROM (SELECT nvl(vrel.id_vital_sign_parent, vsr.id_vital_sign) id_vital_sign,
                                           vsr.dt_vital_sign_read_tstz
                                      FROM vital_sign_read vsr
                                      LEFT OUTER JOIN vital_sign_relation vrel
                                        ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                                       AND vrel.relation_domain IN
                                           (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                                       AND vrel.flg_available = pk_alert_constant.g_yes
                                     INNER JOIN (SELECT id_episode
                                                  FROM episode e
                                                 WHERE e.id_episode = l_id_episode
                                                   AND e.id_patient = l_id_patient
                                                   AND i_scope_type = pk_alert_constant.g_scope_type_episode
                                                UNION ALL
                                                SELECT id_episode
                                                  FROM episode e
                                                 WHERE e.id_patient = l_id_patient
                                                   AND i_scope_type = pk_alert_constant.g_scope_type_patient
                                                UNION ALL
                                                SELECT id_episode
                                                  FROM episode e
                                                 WHERE e.id_visit = l_id_visit
                                                   AND e.id_patient = l_id_patient
                                                   AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                                        ON vsr.id_episode = epi.id_episode
                                      JOIN (SELECT DISTINCT x.id_vital_sign
                                             FROM vs_soft_inst x
                                            WHERE x.id_software = i_prof.software
                                              AND x.id_institution = i_prof.institution) vsi
                                        ON vsi.id_vital_sign = nvl(vrel.id_vital_sign_parent, vsr.id_vital_sign)
                                     WHERE NOT EXISTS (SELECT 1
                                              FROM vital_sign_pregnancy vsp
                                             WHERE vsp.id_vital_sign_read = vsr.id_vital_sign_read
                                               AND vsp.fetus_number > 0)) v1)
                     WHERE rn = 1
                     ORDER BY dt_vital_sign_read_tstz DESC)
            
             WHERE rownum <= i_nr_records;
        
            IF l_date IS NOT NULL
               AND l_date.exists(1) IS NOT NULL
            THEN
            
                o_dt_end   := pk_date_utils.date_send_tsz(i_lang, l_date(1), i_prof.institution, i_prof.software);
                o_dt_begin := pk_date_utils.date_send_tsz(i_lang,
                                                          l_date(l_date.last),
                                                          i_prof.institution,
                                                          i_prof.software);
            ELSE
                o_dt_end   := NULL;
                o_dt_begin := NULL;
            END IF;
        ELSE
            o_dt_end   := NULL;
            o_dt_begin := NULL;
        
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            o_dt_end   := NULL;
            o_dt_begin := NULL;
            RETURN FALSE;
    END get_dates_x_records;

    FUNCTION get_vital_sign_desc
    (
        i_lang language.id_language%TYPE,
        VALUE  VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_t_vs     table_varchar;
        l_vsr_desc VARCHAR2(100 CHAR);
        l_ret      VARCHAR2(200 CHAR) := '';
        len        NUMBER;
    
    BEGIN
    
        IF VALUE IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_t_vs := pk_string_utils.str_split(i_list => VALUE, i_delim => '|');
        len    := l_t_vs.count;
    
        FOR i IN 1 .. l_t_vs.count
        LOOP
            SELECT vsr.value || ' ' ||
                   decode(i, len, pk_translation.get_translation(i_lang, um.code_unit_measure), '/')
              INTO l_vsr_desc
              FROM vital_sign_read vsr
              LEFT JOIN unit_measure um
                ON vsr.id_unit_measure = um.id_unit_measure
             WHERE vsr.id_vital_sign_read = l_t_vs(i);
        
            l_ret := l_ret || l_vsr_desc;
        END LOOP;
    
        RETURN l_ret;
    
    END get_vital_sign_desc;

--
-- INITIALIZATION SECTION
--

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    -- Initioalization
    g_sysdate_tstz := current_timestamp;

END pk_vital_sign_core;
/
