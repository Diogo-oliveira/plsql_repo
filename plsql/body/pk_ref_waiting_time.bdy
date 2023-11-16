/*-- Last Change Revision: $Rev: 2027604 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:46 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_ref_waiting_time IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;

    /**
    * Gets domains for waiting line
    *
    * @param   i_lang                     Language associated to the professional executing the request
    * @param   i_prof                     Professional, institution and software ids
    * @param   i_code_domain              Code domain to get values    
    * @param   i_id_inst_orig             Referral origin institution
    * @param   i_id_inst_dest             Referral dest institution    
    * @param   i_flg_default              Indicates if institution is default or not
    * @param   i_flg_type                 Referral type     
    * @param   i_flg_inside_ref_area      Flag indicating if is inside referral area or not
    * @param   i_flg_ref_line             Referral line 1,2,3
    * @param   i_flg_type_ins             Referral network to which it belongs
    * @param   i_id_speciality            Referral speciality
    * @param   i_id_dcs                   Referral clinical service. Also known as Sub-speciality
    * @param   i_external_sys             External system that created referral
    * @param   i_ref_type                 Type of specialities available for referring
    * @param   o_data                     Domains information
    * @param   o_error                    An error message, set when return=false
    *
    * @value   i_flg_default              {*} 'Y' - Default institution {*} 'N' - otherwise
    * @value   i_flg_type                 {*} 'C'- Consultation {*} 'A'- Analysis {*} 'I'- Image {*} 'E'- Exam
    *                                     {*} 'P'- Procedure {*} 'F'- Physiatrics
    * @value   i_flg_inside_ref_area      {*} 'Y' - inside ref area {*} 'N' - otherwise
    * @value   i_ref_type                 {*} 'E' - External specialities {*} 'I' - Internal specialities 
    *                                     {*} 'P' - at Hospital Entrance specialities {*} 'A' - all types of specialities
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 2.6
    * @since   07-10-2010
    */
    FUNCTION get_domains
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_code_domain         IN sys_domain.code_domain%TYPE,
        i_id_inst_orig        IN p1_dest_institution.id_inst_orig%TYPE DEFAULT NULL,
        i_id_inst_dest        IN p1_dest_institution.id_inst_dest%TYPE DEFAULT NULL,
        i_flg_default         IN p1_dest_institution.flg_default%TYPE DEFAULT NULL,
        i_flg_type            IN p1_dest_institution.flg_type%TYPE DEFAULT NULL,
        i_flg_inside_ref_area IN ref_dest_institution_spec.flg_inside_ref_area%TYPE DEFAULT NULL,
        i_flg_ref_line        IN ref_dest_institution_spec.flg_ref_line%TYPE DEFAULT NULL,
        i_flg_type_ins        IN p1_dest_institution.flg_type_ins%TYPE DEFAULT NULL,
        i_id_speciality       IN p1_speciality.id_speciality%TYPE DEFAULT NULL,
        i_id_dcs              IN p1_spec_dep_clin_serv.id_spec_dep_clin_serv%TYPE DEFAULT NULL,
        i_external_sys        IN external_sys.id_external_sys%TYPE,
        i_ref_type            IN p1_spec_dep_clin_serv.flg_availability%TYPE,
        o_data                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_vals_included table_varchar := table_varchar();
        l_params        VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' CODE_DOMAIN=' || i_code_domain || ' ID_INST_ORIG=' ||
                    i_id_inst_orig || ' ID_INST_DEST=' || i_id_inst_dest || ' FLG_DEFAULT=' || i_flg_default ||
                    ' FLG_TYPE=' || i_flg_type || ' FLG_INSIDE_REF_AREA=' || i_flg_inside_ref_area || ' FLG_REF_LINE=' ||
                    i_flg_ref_line || ' FLG_TYPE_INS=' || i_flg_type_ins || ' ID_SPEC=' || i_id_speciality ||
                    ' I_ID_DCS=' || i_id_dcs || ' ID_EXT_SYS=' || i_external_sys || ' REF_TYPE=' || i_ref_type;
        g_error  := 'Init get_domains / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        FOR c1 IN (SELECT DISTINCT CASE
                                        WHEN i_code_domain = 'P1_DEST_INSTITUTION.FLG_DEFAULT' THEN
                                         tab.flg_default_inst
                                        WHEN i_code_domain = 'P1_DEST_INSTITUTION.FLG_TYPE' THEN
                                         tab.flg_type
                                        WHEN i_code_domain = pk_ref_constant.g_ref_inside_ref_area THEN
                                         tab.flg_inside_ref_area
                                        WHEN i_code_domain = pk_ref_constant.g_ref_flg_ref_line THEN
                                         tab.flg_ref_line
                                        WHEN i_code_domain = pk_ref_constant.g_ref_flg_type_ins THEN
                                         tab.flg_type_ins
                                    END val,
                                   CASE
                                        WHEN i_code_domain = 'P1_DEST_INSTITUTION.FLG_DEFAULT' THEN
                                         pk_sysdomain.get_domain('P1_DEST_INSTITUTION.FLG_DEFAULT',
                                                                 tab.flg_default_inst,
                                                                 i_lang)
                                        WHEN i_code_domain = 'P1_DEST_INSTITUTION.FLG_TYPE' THEN
                                         pk_sysdomain.get_domain('P1_DEST_INSTITUTION.FLG_TYPE', tab.flg_type, i_lang)
                                        WHEN i_code_domain = pk_ref_constant.g_ref_inside_ref_area THEN
                                         pk_sysdomain.get_domain(pk_ref_constant.g_ref_inside_ref_area,
                                                                 tab.flg_inside_ref_area,
                                                                 i_lang)
                                        WHEN i_code_domain = pk_ref_constant.g_ref_flg_ref_line THEN
                                         pk_sysdomain.get_domain(pk_ref_constant.g_ref_flg_ref_line,
                                                                 tab.flg_ref_line,
                                                                 i_lang)
                                        WHEN i_code_domain = pk_ref_constant.g_ref_flg_type_ins THEN
                                         pk_sysdomain.get_domain(pk_ref_constant.g_ref_flg_type_ins,
                                                                 tab.flg_type_ins,
                                                                 i_lang)
                                    END desc_val
                     FROM (
                           -- external referrals
                           SELECT v.flg_default_inst, v.flg_type, v.flg_inside_ref_area, v.flg_ref_line, v.flg_type_ins
                             FROM v_ref_network v
                            WHERE (v.id_inst_orig = i_id_inst_orig OR i_id_inst_orig IS NULL)
                              AND (v.id_institution = i_id_inst_dest OR i_id_inst_dest IS NULL)
                              AND (v.flg_default_inst = i_flg_default OR i_flg_default IS NULL)
                              AND (v.flg_type = i_flg_type OR i_flg_type IS NULL)
                              AND (v.flg_inside_ref_area = i_flg_inside_ref_area OR i_flg_inside_ref_area IS NULL)
                              AND (v.flg_ref_line = i_flg_ref_line OR i_flg_ref_line IS NULL)
                              AND (v.flg_type_ins = i_flg_type_ins OR i_flg_type_ins IS NULL)
                              AND (v.id_speciality = i_id_speciality OR i_id_speciality IS NULL)
                              AND (v.id_dep_clin_serv = i_id_dcs OR i_id_dcs IS NULL)
                              AND v.id_external_sys IN (nvl(i_external_sys, 0), 0)
                              AND i_ref_type = pk_ref_constant.g_flg_availability_e
                           UNION ALL
                           -- at hospital entrance referrals
                           SELECT vp.flg_default_inst,
                                   vp.flg_type,
                                   vp.flg_inside_ref_area,
                                   vp.flg_ref_line,
                                   vp.flg_type_ins
                             FROM v_ref_hosp_entrance vp
                            WHERE (vp.id_institution = i_id_inst_dest OR i_id_inst_dest IS NULL)
                              AND (vp.flg_default_inst = i_flg_default OR i_flg_default IS NULL)
                              AND (vp.flg_type = i_flg_type OR i_flg_type IS NULL)
                              AND (vp.flg_inside_ref_area = i_flg_inside_ref_area OR i_flg_inside_ref_area IS NULL)
                              AND (vp.flg_ref_line = i_flg_ref_line OR i_flg_ref_line IS NULL)
                              AND (vp.flg_type_ins = i_flg_type_ins OR i_flg_type_ins IS NULL)
                              AND (vp.id_speciality = i_id_speciality OR i_id_speciality IS NULL)
                              AND (vp.id_dep_clin_serv = i_id_dcs OR i_id_dcs IS NULL)
                              AND vp.id_external_sys IN (nvl(i_external_sys, 0), 0)
                              AND i_ref_type = pk_ref_constant.g_flg_availability_p) tab)
        LOOP
            l_vals_included.extend;
            l_vals_included(l_vals_included.last) := c1.val;
        END LOOP;
    
        g_error  := 'Call pk_sysdomain.get_values_domain / ' || l_params || ' / l_vals_included=' ||
                    pk_utils.to_string(l_vals_included);
        g_retval := pk_sysdomain.get_values_domain(i_lang          => i_lang,
                                                   i_code_dom      => i_code_domain,
                                                   i_vals_included => l_vals_included,
                                                   i_vals_excluded => NULL,
                                                   o_data          => o_data,
                                                   o_error         => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_domains',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_domains;

    /**
    * Get waiting time for institution and speciality
    *
    * @param   i_lang                  Language identifier
    * @param   i_prof                  Professional, institution and software ids     
    * @param   i_ref_adw_column        Adw column name
    * @param   i_id_institution        Referral dest institution
    * @param   i_id_speciality         Referral speciality
    *
    * @RETURN  wating time
    *
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   2011-01-03
    */
    FUNCTION get_waiting_time
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ref_adw_column IN sys_config.desc_sys_config%TYPE,
        i_id_institution IN p1_external_request.id_inst_dest%TYPE,
        i_id_speciality  IN p1_external_request.id_speciality%TYPE
    ) RETURN NUMBER IS
        l_sql               VARCHAR2(1000 CHAR);
        l_cursor            pk_types.cursor_type;
        l_result            NUMBER;
        l_skip_waiting_time sys_config.value%TYPE;
    BEGIN
        g_error             := 'Init get_waiting_time / REF_ADW_COLUMN=' || i_ref_adw_column || ' ID_INSTITUTION=' ||
                               i_id_institution || ' ID_SPECIALITY=' || i_id_speciality;
        l_skip_waiting_time := pk_sysconfig.get_config(i_code_cf => 'P1_SKIP_WAITING_TIME', i_prof => i_prof);
        -- historical data
    
        IF l_skip_waiting_time = pk_alert_constant.g_no
        THEN
        
            BEGIN
            
                IF i_ref_adw_column = pk_ref_constant.g_wait_time_avg_dd
                THEN
                    l_sql := 'SELECT trunc(v.wait_time_avg_dd) wait_time';
                ELSE
                    l_sql := 'SELECT trunc(v.wait_time_median_dd) wait_time';
                END IF;
            
                l_sql := l_sql || ' FROM v_pio_wait_time_hosp_spec v';
                l_sql := l_sql || ' WHERE v.id_l5_hospital = :1';
                l_sql := l_sql || ' AND v.id_p1_sub_speciality = :2';
            
                g_error := 'OPEN l_cursor / REF_ADW_COLUMN=' || i_ref_adw_column || ' ID_INSTITUTION=' ||
                           i_id_institution || ' ID_SPECIALITY=' || i_id_speciality;
                OPEN l_cursor FOR l_sql
                    USING i_id_institution, i_id_speciality;
            
                FETCH l_cursor
                    INTO l_result;
                CLOSE l_cursor;
            
            EXCEPTION
                WHEN OTHERS THEN
                    l_result := NULL; -- problems finding ADW view
            END;
        
        ELSE
            l_result := NULL;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_waiting_time;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);
END pk_ref_waiting_time;
/
