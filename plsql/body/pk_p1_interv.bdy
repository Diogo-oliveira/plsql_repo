/*-- Last Change Revision: $Rev: 2027437 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:14 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_interv AS

    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_error         VARCHAR2(1000 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;

    /**
    * get common institution based on all required interventions
    *
    * @param    i_lang            preferred language id
    * @param    i_prof            object (id of professional, id of institution, id of software)
    * @param    i_intervs         array of requested interventions
    * @param    o_inst            cursor with institution information
    * @param    o_error           error message structure
    *
    * @return   boolean           false in case of error, otherwise true
    *
    * @author   Carlos Loureiro
    * @version  1.0
    * @since    2009/08/28
    */
    FUNCTION get_interv_inst
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_intervs IN table_number,
        o_inst    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_institution institution.id_institution%TYPE;
    BEGIN
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error          := 'pk_sysconfig.get_config ' || pk_ref_constant.g_ref_external_inst;
        l_id_institution := to_number(pk_sysconfig.get_config(pk_ref_constant.g_ref_external_inst, i_prof));
    
        ----------------------
        -- FUNC
        ----------------------    
        g_error := 'GET CURSOR WITH COMMON INSTITUTIONS';
    
        OPEN o_inst FOR
            SELECT idcs_dest.id_institution,
                   pk_translation.get_translation(i_lang, inst.code_institution) AS institution_name,
                   inst.abbreviation AS institution_abbreviation
              FROM interv_dep_clin_serv idcs_dest
              JOIN intervention i
                ON i.id_intervention = idcs_dest.id_intervention
              JOIN institution inst
                ON inst.id_institution = idcs_dest.id_institution
             WHERE i.flg_status = pk_procedures_constant.g_active
               AND idcs_dest.flg_type = pk_ref_constant.g_interv_exec_w
               AND idcs_dest.flg_execute = pk_alert_constant.g_yes
               AND idcs_dest.id_software = pk_alert_constant.g_soft_referral
               AND idcs_dest.id_interv_dep_clin_serv IN
                   (SELECT riod.id_interv_dcs_dest
                      FROM (SELECT column_value id_interv /*+opt_estimate(table t rows=1)*/
                              FROM TABLE(i_intervs) t) table_id_intervs
                      JOIN interv_dep_clin_serv idcs_orig
                        ON idcs_orig.id_intervention = table_id_intervs.id_interv
                      JOIN ref_interv_orig_dest riod
                        ON riod.id_interv_dcs_orig = idcs_orig.id_interv_dep_clin_serv
                     WHERE riod.flg_available = pk_alert_constant.g_yes
                       AND idcs_orig.flg_type = pk_procedures_constant.g_interv_can_req
                       AND idcs_orig.id_institution = i_prof.institution
                       AND idcs_orig.id_software = i_prof.software)
             GROUP BY idcs_dest.id_institution,
                      pk_translation.get_translation(i_lang, inst.code_institution),
                      inst.abbreviation
            HAVING COUNT(idcs_dest.id_intervention) >= (SELECT COUNT(*) /*+opt_estimate(table t rows=1)*/
                                                          FROM TABLE(i_intervs) t)
            UNION ALL
            SELECT i.id_institution,
                   pk_translation.get_translation(i_lang, i.code_institution) AS institution_name,
                   i.abbreviation AS institution_abbreviation
              FROM institution i
             WHERE i.id_institution = l_id_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_INTERV_INST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_inst);
            RETURN FALSE;
    END get_interv_inst;

    FUNCTION get_interv_inst
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_interventions IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
        l_id_institution institution.id_institution%TYPE;
    
        l_tbl_intervention table_number;
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error          := 'pk_sysconfig.get_config ' || pk_ref_constant.g_ref_external_inst;
        l_id_institution := to_number(pk_sysconfig.get_config(pk_ref_constant.g_ref_external_inst, i_prof));
    
        l_tbl_intervention := pk_utils.str_split_n(i_list => i_interventions, i_delim => '|');
        ----------------------
        -- FUNC
        ----------------------    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT idcs_dest.id_institution AS data,
                               pk_translation.get_translation(i_lang, inst.code_institution) AS label
                          FROM interv_dep_clin_serv idcs_dest
                          JOIN intervention i
                            ON i.id_intervention = idcs_dest.id_intervention
                          JOIN institution inst
                            ON inst.id_institution = idcs_dest.id_institution
                         WHERE i.flg_status = pk_procedures_constant.g_active
                           AND idcs_dest.flg_type = pk_ref_constant.g_interv_exec_w
                           AND idcs_dest.flg_execute = pk_alert_constant.g_yes
                           AND idcs_dest.id_software = pk_alert_constant.g_soft_referral
                           AND idcs_dest.id_interv_dep_clin_serv IN
                               (SELECT riod.id_interv_dcs_dest
                                  FROM (SELECT column_value id_interv /*+opt_estimate(table t rows=1)*/
                                          FROM TABLE(l_tbl_intervention) t) table_id_intervs
                                  JOIN interv_dep_clin_serv idcs_orig
                                    ON idcs_orig.id_intervention = table_id_intervs.id_interv
                                  JOIN ref_interv_orig_dest riod
                                    ON riod.id_interv_dcs_orig = idcs_orig.id_interv_dep_clin_serv
                                 WHERE riod.flg_available = pk_alert_constant.g_yes
                                   AND idcs_orig.flg_type = pk_procedures_constant.g_interv_can_req
                                   AND idcs_orig.id_institution = i_prof.institution
                                   AND idcs_orig.id_software = i_prof.software)
                         GROUP BY idcs_dest.id_institution,
                                  pk_translation.get_translation(i_lang, inst.code_institution),
                                  inst.abbreviation
                        HAVING COUNT(idcs_dest.id_intervention) >= (SELECT COUNT(*) /*+opt_estimate(table t rows=1)*/
                                                                     FROM TABLE(l_tbl_intervention) t)
                        UNION ALL
                        SELECT i.id_institution AS data,
                               pk_translation.get_translation(i_lang, i.code_institution) AS label
                          FROM institution i
                         WHERE i.id_institution = l_id_institution));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_INTERV_INST',
                                              o_error    => l_error);
            RETURN t_tbl_core_domain();
    END get_interv_inst;

    /**
    * get common institution based on all required interventions
    *
    * @param    i_lang            preferred language id
    * @param    i_prof            object (id of professional, id of institution, id of software)
    * @param    i_rehabs          array of requested rehabs (intervention_id)
    * @param    o_inst            cursor with institution information
    * @param    o_error           error message structure
    *
    * @return   boolean           false in case of error, otherwise true
    *
    * @author   Ana Monteiro
    * @version  1.0
    * @since    03-06-2011
    */
    FUNCTION get_rehab_inst
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rehabs IN table_number,
        o_inst   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_institution institution.id_institution%TYPE;
    BEGIN
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error          := 'pk_sysconfig.get_config ' || pk_ref_constant.g_ref_external_inst;
        l_id_institution := to_number(pk_sysconfig.get_config(pk_ref_constant.g_ref_external_inst, i_prof));
    
        ----------------------
        -- FUNC
        ----------------------    
        g_error := 'GET CURSOR WITH COMMON INSTITUTIONS';
        OPEN o_inst FOR
            SELECT i_dest.id_institution,
                   pk_translation.get_translation(i_lang, i_dest.code_institution) AS institution_name,
                   i_dest.abbreviation AS institution_abbreviation
              FROM (SELECT ris.id_rehab_inst_soft,
                           ris.id_rehab_area_interv,
                           ris.id_rehab_session_type,
                           ris.flg_execute,
                           rai.id_intervention
                      FROM rehab_inst_soft ris
                      JOIN rehab_area_interv rai
                        ON (ris.id_rehab_area_interv = rai.id_rehab_area_interv)
                      JOIN TABLE(CAST(i_rehabs AS table_number)) rehabs
                        ON (rehabs.column_value = rai.id_intervention)
                     WHERE ris.id_institution IN (0, i_prof.institution)
                       AND ris.id_software IN (0, i_prof.software)
                       AND ris.flg_add_remove = pk_rehab.g_flg_add
                       AND ris.id_rehab_area_interv NOT IN
                           (SELECT id_rehab_area_interv
                              FROM rehab_inst_soft
                             WHERE id_institution IN (0, i_prof.institution)
                               AND id_software IN (0, i_prof.software)
                               AND flg_add_remove = pk_rehab.g_flg_remove)) orig
              JOIN rehab_inst_soft_ext dest
                ON dest.id_rehab_inst_soft = orig.id_rehab_inst_soft
              JOIN institution i_dest
                ON i_dest.id_institution = dest.id_exec_institution
             GROUP BY i_dest.id_institution,
                      pk_translation.get_translation(i_lang, i_dest.code_institution),
                      i_dest.abbreviation
            HAVING COUNT(orig.id_intervention) >= (SELECT COUNT(*)
                                                     FROM TABLE(i_rehabs))
            UNION ALL
            SELECT i.id_institution,
                   pk_translation.get_translation(i_lang, i.code_institution) AS institution_name,
                   i.abbreviation AS institution_abbreviation
              FROM institution i
             WHERE i.id_institution = l_id_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REHAB_INST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_inst);
            RETURN FALSE;
    END get_rehab_inst;

    FUNCTION get_rehab_inst
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rehabs IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
        l_id_institution institution.id_institution%TYPE;
    
        l_tbl_rehabs table_number;
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error          := 'pk_sysconfig.get_config ' || pk_ref_constant.g_ref_external_inst;
        l_id_institution := to_number(pk_sysconfig.get_config(pk_ref_constant.g_ref_external_inst, i_prof));
    
        l_tbl_rehabs := pk_utils.str_split_n(i_list => i_rehabs, i_delim => '|');
        ----------------------
        -- FUNC
        ----------------------    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => institution_name,
                                         domain_value  => id_institution,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT i_dest.id_institution,
                               pk_translation.get_translation(i_lang, i_dest.code_institution) AS institution_name
                          FROM (SELECT ris.id_rehab_inst_soft,
                                       ris.id_rehab_area_interv,
                                       ris.id_rehab_session_type,
                                       ris.flg_execute,
                                       rai.id_intervention
                                  FROM rehab_inst_soft ris
                                  JOIN rehab_area_interv rai
                                    ON (ris.id_rehab_area_interv = rai.id_rehab_area_interv)
                                  JOIN TABLE(CAST(l_tbl_rehabs AS table_number)) rehabs
                                    ON (rehabs.column_value = rai.id_intervention)
                                 WHERE ris.id_institution IN (0, i_prof.institution)
                                   AND ris.id_software IN (0, i_prof.software)
                                   AND ris.flg_add_remove = pk_rehab.g_flg_add
                                   AND ris.id_rehab_area_interv NOT IN
                                       (SELECT id_rehab_area_interv
                                          FROM rehab_inst_soft
                                         WHERE id_institution IN (0, i_prof.institution)
                                           AND id_software IN (0, i_prof.software)
                                           AND flg_add_remove = pk_rehab.g_flg_remove)) orig
                          JOIN rehab_inst_soft_ext dest
                            ON dest.id_rehab_inst_soft = orig.id_rehab_inst_soft
                          JOIN institution i_dest
                            ON i_dest.id_institution = dest.id_exec_institution
                         GROUP BY i_dest.id_institution,
                                  pk_translation.get_translation(i_lang, i_dest.code_institution),
                                  i_dest.abbreviation
                        HAVING COUNT(orig.id_intervention) >= (SELECT COUNT(*) /*+opt_estimate(table t rows=1)*/
                                                                FROM TABLE(l_tbl_rehabs) t)
                        UNION ALL
                        SELECT i.id_institution,
                               pk_translation.get_translation(i_lang, i.code_institution) AS institution_name
                          FROM institution i
                         WHERE i.id_institution = l_id_institution));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REHAB_INST',
                                              o_error    => l_error);
            RETURN t_tbl_core_domain();
    END get_rehab_inst;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END;
/
