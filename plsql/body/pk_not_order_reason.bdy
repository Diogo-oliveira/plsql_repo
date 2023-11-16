/*-- Last Change Revision: $Rev: 2001300 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2021-11-12 12:27:39 +0000 (sex, 12 nov 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_not_order_reason IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- debug mode enabled/disabled
    g_retval BOOLEAN;
    g_exception EXCEPTION;

    -- Function and procedure implementations
    PROCEDURE get_not_order_reason_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN task_type.id_task_type%TYPE,
        o_list      OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_not_order_reason_list';
        l_market      market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
        l_prof_cat_id category.id_category%TYPE := pk_prof_utils.get_id_category(i_lang, i_prof);
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_task_type = ' || coalesce(to_char(i_task_type), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        OPEN o_list FOR
            SELECT DISTINCT id_not_order_reason_ea AS data,
                            pk_translation.get_translation(i_lang, code_concept_term) AS label,
                            rank
              FROM (SELECT norea.id_not_order_reason_ea,
                           norea.code_concept_term,
                           norea.rank,
                           rank() over(PARTITION BY norea.code_concept_term ORDER BY norea.id_market DESC, norea.id_institution_conc_term DESC, norea.id_institution_term_vers DESC, norea.id_software_conc_term DESC, norea.id_software_term_vers DESC, norea.id_category_cncpt_term DESC, norea.id_category_cncpt_vers DESC) precedence_level
                      FROM not_order_reason_ea norea
                     WHERE norea.id_task_type_conc_term = i_task_type
                       AND norea.id_market IN (pk_alert_constant.g_id_market_all, l_market)
                       AND norea.id_institution_term_vers IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND norea.id_institution_conc_term IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND norea.id_software_term_vers IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND norea.id_software_conc_term IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND norea.id_category_cncpt_vers IN
                           (pk_ea_logic_not_order_reason.k_category_minus_one, l_prof_cat_id)
                       AND norea.id_category_cncpt_term IN
                           (pk_ea_logic_not_order_reason.k_category_minus_one, l_prof_cat_id)
                       AND norea.flg_active_term_vers = pk_alert_constant.g_yes) t
             WHERE t.precedence_level = 1
               AND pk_translation.get_translation(i_lang, code_concept_term) IS NOT NULL
             ORDER BY rank, upper(label);
    
    END get_not_order_reason_list;

    FUNCTION get_not_order_reason_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN task_type.id_task_type%TYPE
    ) RETURN t_tbl_core_domain IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_not_order_reason_list';
        l_market      market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
        l_prof_cat_id category.id_category%TYPE := pk_prof_utils.get_id_category(i_lang, i_prof);
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_task_type = ' || coalesce(to_char(i_task_type), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'open l_ret';
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => t.label,
                                 domain_value  => t.data,
                                 order_rank    => NULL,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT DISTINCT id_not_order_reason_ea AS data,
                                pk_translation.get_translation(i_lang, code_concept_term) AS label,
                                rank
                  FROM (SELECT norea.id_not_order_reason_ea,
                               norea.code_concept_term,
                               norea.rank,
                               rank() over(PARTITION BY norea.code_concept_term ORDER BY norea.id_market DESC, norea.id_institution_conc_term DESC, norea.id_institution_term_vers DESC, norea.id_software_conc_term DESC, norea.id_software_term_vers DESC, norea.id_category_cncpt_term DESC, norea.id_category_cncpt_vers DESC) precedence_level
                          FROM not_order_reason_ea norea
                         WHERE norea.id_task_type_conc_term = i_task_type
                           AND norea.id_market IN (pk_alert_constant.g_id_market_all, l_market)
                           AND norea.id_institution_term_vers IN (pk_alert_constant.g_inst_all, i_prof.institution)
                           AND norea.id_institution_conc_term IN (pk_alert_constant.g_inst_all, i_prof.institution)
                           AND norea.id_software_term_vers IN (pk_alert_constant.g_soft_all, i_prof.software)
                           AND norea.id_software_conc_term IN (pk_alert_constant.g_soft_all, i_prof.software)
                           AND norea.id_category_cncpt_vers IN
                               (pk_ea_logic_not_order_reason.k_category_minus_one, l_prof_cat_id)
                           AND norea.id_category_cncpt_term IN
                               (pk_ea_logic_not_order_reason.k_category_minus_one, l_prof_cat_id)
                           AND norea.flg_active_term_vers = pk_alert_constant.g_yes) t
                 WHERE t.precedence_level = 1
                   AND pk_translation.get_translation(i_lang, code_concept_term) IS NOT NULL
                 ORDER BY rank, upper(label)) t;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NOT_ORDER_REASON_LIST',
                                              l_error);
            RETURN l_ret;
    END get_not_order_reason_list;

    FUNCTION get_not_order_reason_key
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_not_order_reason_ea     IN not_order_reason_ea.id_not_order_reason_ea%TYPE,
        o_id_concept_type         OUT not_order_reason.id_concept_type%TYPE,
        o_id_concept_version      OUT not_order_reason_ea.id_concept_version%TYPE,
        o_id_cncpt_vrs_inst_owner OUT not_order_reason_ea.id_cncpt_vrs_inst_owner%TYPE,
        o_id_concept_term         OUT not_order_reason_ea.id_concept_term%TYPE,
        o_id_cncpt_trm_inst_owner OUT not_order_reason_ea.id_cncpt_trm_inst_owner%TYPE,
        o_id_task_type            OUT not_order_reason_ea.id_task_type_conc_term%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_not_order_reason_key';
    
        CURSOR nor_ea IS
            SELECT norea.id_concept_type,
                   norea.id_concept_version,
                   norea.id_cncpt_vrs_inst_owner,
                   norea.id_concept_term,
                   norea.id_cncpt_trm_inst_owner,
                   norea.id_task_type_conc_term
              FROM not_order_reason_ea norea
             WHERE norea.id_not_order_reason_ea = i_not_order_reason_ea
               AND norea.id_software_term_vers IN (pk_alert_constant.g_soft_all, i_prof.software)
               AND norea.id_software_conc_term IN (pk_alert_constant.g_soft_all, i_prof.software)
               AND rownum = 1
             ORDER BY norea.id_software_conc_term DESC, norea.id_software_term_vers DESC;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_not_order_reason_ea = ' || coalesce(to_char(i_not_order_reason_ea), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        OPEN nor_ea;
        FETCH nor_ea
            INTO o_id_concept_type,
                 o_id_concept_version,
                 o_id_cncpt_vrs_inst_owner,
                 o_id_concept_term,
                 o_id_cncpt_trm_inst_owner,
                 o_id_task_type;
        CLOSE nor_ea;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_not_order_reason_key;

    FUNCTION get_not_order_reason_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_id_not_order_reason IN not_order_reason.id_not_order_reason%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        k_function_name           pk_types.t_internal_name_byte := 'get_not_order_reason_desc';
        l_desc                    pk_translation.t_desc_translation;
        l_id_task_type            not_order_reason.id_task_type%TYPE;
        l_id_concept_term         not_order_reason.id_concept_term%TYPE;
        l_id_cncpt_trm_inst_owner not_order_reason.id_cncpt_trm_inst_owner%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_id_not_order_reason = ' || coalesce(to_char(i_id_not_order_reason), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        BEGIN
            SELECT nor.id_task_type, nor.id_concept_term, nor.id_cncpt_trm_inst_owner
              INTO l_id_task_type, l_id_concept_term, l_id_cncpt_trm_inst_owner
              FROM not_order_reason nor
             WHERE nor.id_not_order_reason = i_id_not_order_reason;
        EXCEPTION
            WHEN no_data_found THEN
                l_desc := NULL;
        END;
    
        IF l_id_task_type IS NOT NULL
           AND l_id_concept_term IS NOT NULL
           AND l_id_cncpt_trm_inst_owner IS NOT NULL
        THEN
            g_error := 'Call pk_api_termin_server_func.get_concept_term_desc';
            g_error := g_error || ' id_task_type = ' || coalesce(to_char(l_id_task_type), '<null>');
            g_error := g_error || ' id_concept_term = ' || coalesce(to_char(l_id_concept_term), '<null>');
            g_error := g_error || ' id_cncpt_trm_inst_owner = ' ||
                       coalesce(to_char(l_id_cncpt_trm_inst_owner), '<null>');
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_desc := pk_api_termin_server_func.get_concept_term_desc(i_lang                    => i_lang,
                                                                      i_id_task_type            => l_id_task_type,
                                                                      i_id_concept_term         => l_id_concept_term,
                                                                      i_id_cncpt_trm_inst_owner => l_id_cncpt_trm_inst_owner);
        END IF;
    
        RETURN l_desc;
    END get_not_order_reason_desc;

    FUNCTION get_not_order_reason_id
    (
        i_lang                IN language.id_language%TYPE,
        i_id_not_order_reason IN not_order_reason.id_not_order_reason%TYPE
    ) RETURN not_order_reason_ea.id_not_order_reason_ea%TYPE IS
        k_function_name           pk_types.t_internal_name_byte := 'get_not_order_reason_id';
        l_id                      not_order_reason_ea.id_not_order_reason_ea%TYPE;
        l_id_task_type            not_order_reason.id_task_type%TYPE;
        l_id_concept_term         not_order_reason.id_concept_term%TYPE;
        l_id_concept_type         not_order_reason.id_concept_type%TYPE;
        l_id_concept_version      not_order_reason_ea.id_concept_version%TYPE;
        l_id_cncpt_vrs_inst_owner not_order_reason_ea.id_cncpt_vrs_inst_owner%TYPE;
        l_id_cncpt_trm_inst_owner not_order_reason.id_cncpt_trm_inst_owner%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_id_not_order_reason = ' || coalesce(to_char(i_id_not_order_reason), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT nor.id_task_type,
               nor.id_concept_term,
               nor.id_concept_type,
               nor.id_concept_version,
               nor.id_cncpt_vrs_inst_owner,
               nor.id_cncpt_trm_inst_owner
          INTO l_id_task_type,
               l_id_concept_term,
               l_id_concept_type,
               l_id_concept_version,
               l_id_cncpt_vrs_inst_owner,
               l_id_cncpt_trm_inst_owner
          FROM not_order_reason nor
         WHERE nor.id_not_order_reason = i_id_not_order_reason;
    
        BEGIN
            SELECT norea.id_not_order_reason_ea
              INTO l_id
              FROM not_order_reason_ea norea
             WHERE norea.id_task_type_conc_term = l_id_task_type
               AND norea.id_task_type_term_vers = l_id_task_type
               AND norea.id_concept_term = l_id_concept_term
               AND norea.id_concept_type = l_id_concept_type
               AND norea.id_concept_version = l_id_concept_version
               AND norea.id_cncpt_vrs_inst_owner = l_id_cncpt_vrs_inst_owner
               AND norea.id_cncpt_trm_inst_owner = l_id_cncpt_trm_inst_owner
               AND rownum = 1
             ORDER BY norea.dt_version_start DESC;
        EXCEPTION
            WHEN no_data_found THEN
                l_id := NULL;
        END;
    
        RETURN l_id;
    END get_not_order_reason_id;

    FUNCTION set_not_order_reason
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_not_order_reason_ea IN not_order_reason_ea.id_not_order_reason_ea%TYPE
    ) RETURN not_order_reason.id_not_order_reason%TYPE IS
        k_function_name    pk_types.t_internal_name_byte := 'set_not_order_reason';
        l_error            t_error_out;
        l_rec              not_order_reason%ROWTYPE;
        l_not_order_reason not_order_reason.id_not_order_reason%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_not_order_reason_ea = ' || coalesce(to_char(i_not_order_reason_ea), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- convert hash key
        g_error := 'Call get_not_order_reason_key';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        g_retval := get_not_order_reason_key(i_lang                    => i_lang,
                                             i_prof                    => i_prof,
                                             i_not_order_reason_ea     => i_not_order_reason_ea,
                                             o_id_concept_type         => l_rec.id_concept_type,
                                             o_id_concept_version      => l_rec.id_concept_version,
                                             o_id_cncpt_vrs_inst_owner => l_rec.id_cncpt_vrs_inst_owner,
                                             o_id_concept_term         => l_rec.id_concept_term,
                                             o_id_cncpt_trm_inst_owner => l_rec.id_cncpt_trm_inst_owner,
                                             o_id_task_type            => l_rec.id_task_type,
                                             o_error                   => l_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        -- verify if key (id_concept_type,id_concept_version,id_cncpt_vrs_inst_owner,id_concept_term,id_cncpt_trm_inst_owner,id_task_type) exist
        BEGIN
            SELECT nor.id_not_order_reason
              INTO l_not_order_reason
              FROM not_order_reason nor
             WHERE nor.id_concept_type = l_rec.id_concept_type
               AND nor.id_concept_version = l_rec.id_concept_version
               AND nor.id_cncpt_vrs_inst_owner = l_rec.id_cncpt_vrs_inst_owner
               AND nor.id_concept_term = l_rec.id_concept_term
               AND nor.id_cncpt_trm_inst_owner = l_rec.id_cncpt_trm_inst_owner
               AND nor.id_task_type = l_rec.id_task_type;
        EXCEPTION
            WHEN no_data_found THEN
                l_not_order_reason := NULL;
        END;
    
        IF l_not_order_reason IS NULL
        THEN
            -- insert in table not_order_reason, return new id
            g_error := 'Call ts_not_order_reason.ins:';
            g_error := g_error || ' id_concept_type = ' || coalesce(to_char(l_rec.id_concept_type), '<null>');
            g_error := g_error || ' id_concept_version = ' || coalesce(to_char(l_rec.id_concept_version), '<null>');
            g_error := g_error || ' id_cncpt_vrs_inst_owner = ' ||
                       coalesce(to_char(l_rec.id_cncpt_vrs_inst_owner), '<null>');
            g_error := g_error || ' id_concept_term = ' || coalesce(to_char(l_rec.id_concept_term), '<null>');
            g_error := g_error || ' id_cncpt_trm_inst_owner = ' ||
                       coalesce(to_char(l_rec.id_cncpt_trm_inst_owner), '<null>');
            g_error := g_error || ' id_task_type = ' || coalesce(to_char(l_rec.id_task_type), '<null>');
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_rec.id_institution      := i_prof.institution;
            l_rec.id_not_order_reason := ts_not_order_reason.next_key();
            ts_not_order_reason.ins(rec_in => l_rec);
        ELSE
            -- returns existing id 
            l_rec.id_not_order_reason := l_not_order_reason;
        END IF;
    
        RETURN l_rec.id_not_order_reason;
    
    END set_not_order_reason;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_not_order_reason;
/
