/*-- Last Change Revision: $Rev: 2055199 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-10 16:05:23 +0000 (sex, 10 fev 2023) $*/
CREATE OR REPLACE PACKAGE BODY pk_print_tool AS

    -- Local package constants
    SUBTYPE obj_name IS VARCHAR2(30);
    SUBTYPE debug_msg IS VARCHAR2(4000);

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    c_flg_type_n         CONSTANT VARCHAR2(1) := 'N';
    c_flg_type_y         CONSTANT VARCHAR2(1) := 'Y';
    c_exam_type_lab      CONSTANT NUMBER := 1;
    c_exam_type_img      CONSTANT NUMBER := 2;
    c_flg_type_e         CONSTANT VARCHAR2(1) := 'E';
    c_flg_type_i         CONSTANT VARCHAR2(1) := 'I';
    c_separator          CONSTANT VARCHAR2(1) := '|';
    c_flg_add            CONSTANT VARCHAR2(1) := 'A';
    c_flg_remove         CONSTANT VARCHAR2(1) := 'R';
    c_flg_save           CONSTANT VARCHAR2(1) := 'S';
    c_epis_report_domain CONSTANT sys_domain.code_domain%TYPE := 'EPIS_REPORT.FLG_STATUS';

    c_all CONSTANT VARCHAR2(1) := 'A';

    c_task_type_ref                CONSTANT NUMBER := 58;
    c_task_type_med_home           CONSTANT NUMBER := 98;
    c_task_type_med_local          CONSTANT NUMBER := 13;
    c_task_type_med_outsd          CONSTANT NUMBER := 15;
    c_task_type_med_hosp           CONSTANT NUMBER := 16;
    c_task_type_lab_tests          CONSTANT NUMBER := 11;
    c_task_type_img_exams          CONSTANT NUMBER := 7;
    c_task_type_other_exams        CONSTANT NUMBER := 8;
    c_task_type_non_stand_med      CONSTANT NUMBER := 104;
    c_task_type_admission_request  CONSTANT NUMBER := 35;
    c_task_type_controlled_amb_med CONSTANT NUMBER := 132;
    c_task_type_controlled_local   CONSTANT NUMBER := 133;
    c_task_type_narcotic_amb_med   CONSTANT NUMBER := 156;
    c_task_type_narcotic_local     CONSTANT NUMBER := 157;
    c_task_type_blood_prod         CONSTANT NUMBER := 131;
    c_task_type_sr_epis            CONSTANT NUMBER := 27;
    c_task_type_inp_epis           CONSTANT NUMBER := 35;

    g_epis_rep_status_n        CONSTANT epis_report.flg_status%TYPE := 'N';
    g_epis_rep_status_impresso CONSTANT epis_report.flg_status%TYPE := 'I';
    g_epis_rep_status_saved    CONSTANT epis_report.flg_status%TYPE := 'S';
    g_rep_inst_logo_logic      CONSTANT VARCHAR(1) := 'Y';
    g_rep_inst_logo_no_logic   CONSTANT VARCHAR(1) := 'N';
    --
    g_domain_flg_date_filters CONSTANT sys_domain.code_domain%TYPE := 'EPIS_REPORTS.FLG_DATE_FILTERS';
    g_domain_flg_signed       CONSTANT sys_domain.code_domain%TYPE := 'EPIS_REPORT.FLG_SIGNED';

    g_default_rep_profile_id     CONSTANT rep_profile_template.id_rep_profile_template%TYPE := 0;
    g_default_rep_institution_id CONSTANT rep_prof_template.id_institution%TYPE := 0;
    g_default_rep_software_id    CONSTANT rep_prof_template.id_software%TYPE := 0;

    g_flg_tools_n CONSTANT reports.flg_tools%TYPE := 'N';
    g_flg_tools_s CONSTANT reports.flg_tools%TYPE := 'S';

    g_get_rep_prof_id_exception EXCEPTION;

    g_icon_exists_in_print_list CONSTANT VARCHAR2(30 CHAR) := 'OnPrintingListIcon';

    g_id_report_med_list_adm CONSTANT NUMBER := 491;

    FUNCTION set_epis_report_dynamic_code
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_report IN epis_report.id_epis_report%TYPE,
        i_json_params IN epis_report.json_params%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Obt�m a lista de reports dispon�veis para o grupo a que o profissional tenha acesso.
    *
    * @param  I_LANG               L�ngua registada como prefer�ncia do profissional
    * @param  I_PROF               ID do profissional, institui��oo e software
    * @param  I_REPORTS            ID do report que � um grupo
    *
    * @param  O_REPORTS            Array com a lista de reports
    * @param  O_ERROR              Descri��o do erro
    *
    * @return     Boolean
    * @author     RB
    * @version    1.0  2007/01/26
    *
    * @author     Jo�o Reis
    * @version    2.6.1.2       2011/07/21
    * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
    */
    FUNCTION get_reports_group
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_reports IN reports_group.id_reports_master%TYPE,
        o_reports OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rep_prof_template rep_prof_template.id_rep_prof_template%TYPE;
    
    BEGIN
    
        IF NOT
            get_rep_prof_id(i_lang => i_lang, i_prof => i_prof, o_id_profile => l_rep_prof_template, o_error => o_error)
        THEN
            RAISE g_get_rep_prof_id_exception;
        END IF;
    
        --Abre array com os reports que pertecem ao grupo
        g_error := 'OPEN O_REPORTS_ARRAY';
        OPEN o_reports FOR
            SELECT rg.rank,
                   r.id_reports,
                   nvl(pk_translation.get_translation(i_lang, r.code_reports_title),
                       pk_translation.get_translation(i_lang, r.code_reports)) desc_report,
                   r.flg_type,
                   pk_alert_constant.g_active flg_selected
              FROM reports_group rg, reports r, rep_profile_template_det td, rep_profile_template pt
             WHERE rg.id_reports_master = i_reports
               AND r.id_reports = rg.id_reports
               AND nvl(r.flg_available, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
               AND nvl(r.flg_printer, '@') != c_flg_save
               AND td.id_reports = r.id_reports
               AND nvl(td.flg_available, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
               AND td.flg_type = c_flg_add
               AND td.id_rep_profile_template IN (l_rep_prof_template, g_default_rep_profile_id)
               AND td.id_rep_profile_template_det NOT IN
                   (SELECT t.id_rep_profile_template_det
                      FROM rep_profile_template_det t
                     WHERE t.id_rep_profile_template = g_default_rep_profile_id
                       AND t.id_reports IN (SELECT t2.id_reports
                                              FROM rep_profile_template_det t2
                                             WHERE t2.id_rep_profile_template = l_rep_prof_template))
                  --AND pt.id_rep_profile_template = td.id_rep_profile_template
               AND pt.id_software IN (i_prof.software, 0)
               AND pt.id_institution IN (i_prof.institution, 0)
               AND pt.id_rep_profile_template = td.id_rep_profile_template
               AND --O profissional tem acessos especificos ao template de reports
                   (EXISTS (SELECT 1
                              FROM rep_prof_template rpt
                             WHERE rpt.id_professional = i_prof.id
                               AND rpt.id_software IN (i_prof.software, 0)
                               AND rpt.id_institution IN (i_prof.institution, 0)
                               AND rpt.id_rep_profile_template = pt.id_rep_profile_template) OR --o profissional tem um template de acessos atribu�do que est� ligado ao template de reports
                    EXISTS (SELECT 1
                              FROM prof_profile_template ppt, rep_prof_templ_access rpta
                             WHERE ppt.id_software IN (i_prof.software, 0)
                               AND ppt.id_institution IN (i_prof.institution, 0)
                               AND ppt.id_professional = i_prof.id
                               AND rpta.id_profile_template = ppt.id_profile_template
                               AND rpta.id_rep_profile_template = pt.id_rep_profile_template) OR
                   -- OR it is a 'ALL' profile = 0 record. The default profile ID's should be allowed
                    pt.id_rep_profile_template = g_default_rep_profile_id)
                  --Retira excep��es ao template
               AND NOT EXISTS (SELECT 1
                      FROM rep_prof_exception rpe
                     WHERE rpe.id_rep_profile_template_det = td.id_rep_profile_template_det
                       AND rpe.flg_area_report = td.flg_area_report
                       AND nvl(rpe.id_professional, i_prof.id) = i_prof.id
                       AND rpe.id_reports = td.id_reports
                       AND rpe.id_institution IN (i_prof.institution, 0)
                       AND rpe.id_software IN (i_prof.software, 0)
                       AND rpe.flg_type = c_flg_remove)
            UNION ALL
            --O report n�o � um grupo mas sim um relat�rio do menu SAVE
            SELECT rd.rank,
                   i_reports id_reports,
                   pk_translation.get_translation(i_lang, rd.code_rep_destination) desc_report,
                   rd.flg_type,
                   pk_alert_constant.g_inactive flg_selected
              FROM rep_destination rd, reports r
             WHERE r.id_reports = i_reports
               AND nvl(r.flg_available, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
               AND nvl(r.flg_printer, '@') = c_flg_save
             ORDER BY rank, desc_report;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_get_rep_prof_id_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_GROUP',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_GROUP',
                                              o_error);
            pk_types.open_my_cursor(o_reports);
            RETURN FALSE;
    END get_reports_group;
    /**
    * Obt�m a lista de reports dispon�veis para o profissional em determinado ecr�.
    * @param    I_LANG               L�ngua registada como prefer�ncia do profissional
    * @param    I_PROF               objecto com dados do utilizador
    * @param    I_EPISODE            ID do epis�dio actual
    * @param    I_AREA_REPORT        �rea na qual ser� alocado o relat�rio. Valores poss�veis:
    *                                    {*} 'R' Reports
    *                                    {*} 'OD' Ongoing Documents
    *                                    {*} 'C' Consents
    *                                    {*} 'CR' Certificates
    *                                    {*} 'F' Forms
    *                                    {*} 'L' Lables
    *                                    {*} 'SR' Screen Reports
    * @param    I_SCREEN_NAME        Nome do ecr� onde a fun��o � chamada
    * @param    I_SYS_BUTTON_PROP    ID do deepnav selecionado (If this value is null then it will be valid for all screen instances)
    *
    * @param    O_REPORTS            Array com a lista de reports
    * @param    O_ERROR              Descri��o do erro
    *
    * @return     true (tudo ok), false (erro)
    * @author     RB
    * @version    1.0       2007/01/25
    * @change     RS 20100602 allow I_SYS_BUTTON_PROP to be NULL
    *
    * @author     Jo�o Reis
    * @version    2.6.1.2       2011/07/21
    * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
    */
    FUNCTION get_reports_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_area_report     IN rep_profile_template_det.flg_area_report%TYPE,
        i_screen_name     IN rep_screen.screen_name%TYPE,
        i_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        o_reports         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message      debug_msg;
        l_get_rep_list t_table_report_doc_arch;
    
    BEGIN
    
        l_message      := 'GET RESULTS';
        l_get_rep_list := get_reports_list_tf(i_lang,
                                              i_prof,
                                              i_episode,
                                              i_area_report,
                                              i_screen_name,
                                              i_sys_button_prop,
                                              NULL,
                                              o_error);
        l_message      := 'OPEN O_REPORTS CURSOR';
        OPEN o_reports FOR
            SELECT tbl.*
              FROM TABLE(l_get_rep_list) tbl
             ORDER BY rank, desc_report;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_reports);
            RETURN FALSE;
    END get_reports_list;

    /**
    * Obt�m a lista de conte�dos de um relat�rio, aplicando um filtro.
    *
    * @param   I_LANG               L�ngua registada como prefer�ncia do profissional
    * @param   I_PROF               ID do profissional, institui��o e software
    * @param   I_EPISODE            ID do epis�dio
    * @param   I_REPORTS            ID do report que � um grupo
    *
    * @param   O_LIST               Array com a lista
    * @param   O_ERROR              Descri��o do erro
    *
    * @return     Boolean
    * @author     RB
    * @version    1.0  2007/02/01
    */
    FUNCTION get_filter_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_reports IN reports.id_reports%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        c_flg_prof_rec_type CONSTANT epis_prof_rec.flg_type%TYPE := 'R';
        l_sql reports.reports_sql%TYPE;
    
    BEGIN
        --Obt�m o c�digo SQL para obten��o da lista
        l_message := 'GET REPORTS SQL';
        BEGIN
            SELECT reports_sql
              INTO l_sql
              FROM reports
             WHERE id_reports = i_reports;
        
        EXCEPTION
            WHEN no_data_found THEN
                pk_types.open_my_cursor(o_list);
                RETURN FALSE;
        END;
    
        --Substitui vari�veis
        l_sql := REPLACE(l_sql, '@I_LANG', i_lang);
        l_sql := REPLACE(l_sql, '@I_REPORTS', i_reports);
        l_sql := REPLACE(l_sql, '@I_EPISODE', i_episode);
        l_sql := REPLACE(l_sql, '@I_FLG_PROF_REC_TYPE', c_flg_prof_rec_type);
    
        --Executa o c�digo gerado
        l_message := 'OPEN O_LIST ARRAY';
        OPEN o_list FOR l_sql;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FILTER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_filter_list;

    /**
    * Check if a list of reports have sections or not
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode identifier
    * @param   i_patient         Patient identifier
    * @param   i_reports         List of reports to check if have sections
    *
    * @return  VARCHAR2          Y- reports have sections N- otherwise
    *
    * @author  tiago.silva
    * @since   20-10-2014
    */
    FUNCTION check_if_has_sections
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_reports IN table_number
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'CHECK_IF_HAS_SECTIONS';
    
        e_exception EXCEPTION;
        l_error   t_error_out;
        l_dbg_msg debug_msg;
    
        l_result   VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        c_sections p_cnt_section_cur;
        l_section  p_cnt_section_rec;
    
    BEGIN
        l_dbg_msg := 'CALL GET_VISIBLE_SECTION_LIST';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF NOT get_invisible_section_count(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_episode            => i_episode,
                                           i_patient            => i_patient,
                                           i_reports            => i_reports,
                                           i_section_visibility => pk_alert_constant.g_yes,
                                           o_section            => c_sections,
                                           o_error              => l_error)
        THEN
            RAISE e_exception;
        END IF;
    
        FETCH c_sections
            INTO l_section;
    
        IF c_sections%FOUND
        THEN
            l_result := pk_alert_constant.g_yes;
        ELSE
            l_result := pk_alert_constant.g_no;
        END IF;
    
        CLOSE c_sections;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END check_if_has_sections;

    /********************************************************************************************
     * Gets the list of available sections for a specific report
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_reports                Report ID
     *
     * @param o_section                List of sections
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Jos� Silva
     * @version                         2.6
     * @since                           2010/02/22
     *
     * @author     Jo�o Reis
     * @version    2.6.1.2       2011/07/21
     * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
    **********************************************************************************************/
    FUNCTION get_section_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_reports IN reports.id_reports%TYPE,
        o_section OUT p_rep_section_cur,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SECTION_LIST';
        l_error EXCEPTION;
        l_message debug_msg;
    BEGIN
    
        l_message := 'CALL GET_SECTION_LIST';
        pk_alertlog.log_debug(text => l_message, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF NOT get_invisible_section_list_rep(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_reports            => i_reports,
                                              i_section_visibility => pk_alert_constant.g_yes,
                                              o_section            => o_section,
                                              o_error              => o_error)
        THEN
            RAISE l_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_get_rep_prof_id_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_section);
            RETURN FALSE;
    END get_section_list;

    /**
    * Obt�m a lista de sec��es de um report, dispon�veis para impress�o.
    *
    * @param   I_LANG               L�ngua registada como prefer�ncia do profissional
    * @param   I_PROF               ID do profissional, institui��o e software
    * @param   I_EPISODE            ID do epis�dio
    * @param   I_PATIENT            ID do paciente
    * @param   I_REPORTS            ID do report que � um grupo
    *
    * @param   O_SECTION            Array com a lista de sec��es do report
    * @param   O_ERROR              Descri��o do erro
    *
    * @return     Boolean
    * @author     RB
    * @version    1.0   2007/02/01
    */
    FUNCTION get_section_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_reports IN table_number,
        o_section OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SECTION_LIST';
    
        l_error EXCEPTION;
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'CALL GET_VISIBLE_SECTION_LIST';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF NOT get_invisible_section_list(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_episode            => i_episode,
                                          i_patient            => i_patient,
                                          i_reports            => i_reports,
                                          i_section_visibility => pk_alert_constant.g_yes,
                                          o_section            => o_section,
                                          o_error              => o_error)
        THEN
            RAISE l_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_error THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_section_list;
    /**
    * Obt�m a lista de sec��es de um report, dispon�veis para impress�o.
    *
    * @param   I_LANG               L�ngua registada como prefer�ncia do profissional
    * @param   I_PROF               ID do profissional, institui��o e software
    * @param   I_EPISODE            ID do epis�dio
    * @param   I_PATIENT            ID do paciente
    * @param   I_REPORTS            ID do report que � um grupo
    * @param   I_WL_MACHINE_NAME    ID do hostname
    * @param   O_SECTION            Array com a lista de sec��es do report
    * @param   O_ERROR              Descri��o do erro
    *
    * @return     Boolean
    */
    FUNCTION get_section_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_reports         IN table_number,
        i_wl_machine_name IN wl_machine.machine_name%TYPE,
        o_section         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SECTION_LIST';
    
        l_error EXCEPTION;
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'CALL GET_VISIBLE_SECTION_LIST';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF NOT get_invisible_section_list(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_episode            => i_episode,
                                          i_patient            => i_patient,
                                          i_reports            => i_reports,
                                          i_section_visibility => pk_alert_constant.g_yes,
                                          i_wl_machine_name    => i_wl_machine_name,
                                          o_section            => o_section,
                                          o_error              => o_error)
        THEN
            RAISE l_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_error THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_section_list;

    FUNCTION get_invisible_section_count
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_reports            IN table_number,
        i_section_visibility IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_section            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_INVISIBLE_SECTION_LIST';
        IF NOT get_invisible_section_list(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_episode            => i_episode,
                                          i_patient            => i_patient,
                                          i_reports            => i_reports,
                                          i_section_visibility => pk_alert_constant.g_yes,
                                          i_count              => pk_alert_constant.g_yes,
                                          o_section            => o_section,
                                          o_error              => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'GET_INVISIBLE_SECTION_COUNT',
                                              o_error);
            pk_types.open_my_cursor(o_section);
            RETURN FALSE;
    END get_invisible_section_count;

    /**
      * Overload function to allow showing or not the virtual sections.
    * The sections are ordered alphabetically.
      *
      * @param   I_EPISODE            ID do epis�dio
      * @param   I_PATIENT            ID do paciente
      * @param   I_REPORTS            ID do report que � um grupo
      *
      * @param   O_SECTION            Array com a lista de sec��es do report
      * @param   O_ERROR              Descri��o do erro
      *
      * @param i_lang language id
      * @param i_prof professional type
      * @param i_episode episode's ID
      * @param i_reports report's ID array
      * @param i_show_visible flag indicating whether virtual sections should also be returned ('A' = All, 'Y' = Visible, 'N' = Invisible)
      *
      * @param o_section cursor with section information
      * @param o_error error message
      *
      * @return true (success), false (error)
      *
      * @author Gon�alo Almeida, 2011/Feb/15
      * @version 2.6.1
      * @since 2011/Feb/15
      *
      * @author     Jo�o Reis
      * @version    2.6.1.2       2011/07/21
      * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
      */
    FUNCTION get_invisible_section_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_reports            IN table_number,
        i_section_visibility IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_count              IN VARCHAR2 DEFAULT NULL,
        i_wl_machine_name    IN wl_machine.machine_name%TYPE DEFAULT NULL,
        o_section            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message           debug_msg;
        l_sql               CLOB;
        l_first             BOOLEAN;
        l_reports           VARCHAR2(200);
        l_printer           VARCHAR2(2000);
        l_codification_type VARCHAR2(2000);
        l_barcode_pat       VARCHAR2(2000);
        l_barcode_nec       VARCHAR2(2000);
        l_barcode_pat_n     VARCHAR2(2000);
        l_has_ticket_gen    BOOLEAN;
        l_ticket_number     VARCHAR2(4000);
        l_market            market.id_market%TYPE;
        l_error             t_error_out;
        e_user_exception EXCEPTION;
    
        CURSOR c_reports IS
            SELECT id_reports
              FROM reports
             WHERE id_reports IN (SELECT *
                                    FROM TABLE(CAST(i_reports AS table_number)));
    
        CURSOR c_rep(pcur_report reports.id_reports%TYPE) IS
            SELECT id_reports, reports_sql
              FROM reports
             WHERE id_reports = pcur_report
               AND reports_sql IS NOT NULL;
    
        l_rep_prof_template rep_prof_template.id_rep_prof_template%TYPE;
    
    BEGIN
    
        IF NOT
            get_rep_prof_id(i_lang => i_lang, i_prof => i_prof, o_id_profile => l_rep_prof_template, o_error => o_error)
        THEN
            l_message := 'SET l_rep_prof_template with default report profile: ' || g_default_rep_profile_id;
            pk_alertlog.log_debug(l_message);
            -- No exception is handled to be able to generate reports without the report profile.
            l_rep_prof_template := g_default_rep_profile_id;
        END IF;
    
        l_message := 'GET_INSTITUTION_MARKET with institution: ' || i_prof.institution;
        pk_alertlog.log_debug(l_message);
    
        l_market := pk_core.get_inst_mkt(i_prof.institution);
        l_first  := TRUE;
        --Constroi lista de reports solicitados
        FOR i IN c_reports
        LOOP
            IF l_reports IS NULL
            THEN
                l_reports := i.id_reports;
            ELSE
                l_reports := l_reports || ', ' || i.id_reports;
            END IF;
        
            --Constroi o query com os reports cujo c�digo das sec��es est� na BD
            g_error := 'SET BIND VARIABLES';
            pk_context_api.set_parameter('i_count', i_count);
        
            l_message := 'BUILD CURSOR SQL';
            FOR c IN c_rep(i.id_reports)
            LOOP
                IF c.reports_sql IS NOT NULL
                THEN
                    l_has_ticket_gen := (instr(c.reports_sql, '@WL_TICKET') != 0);
                    IF (l_has_ticket_gen AND (i_wl_machine_name IS NOT NULL))
                    THEN
                        l_ticket_number := pk_wlpatient.report_ticket(i_lang            => i_lang,
                                                                      i_prof            => i_prof,
                                                                      i_wl_machine_name => i_wl_machine_name,
                                                                      i_id_episode      => i_episode);
                    END IF;
                END IF;
                IF l_first
                THEN
                    l_sql   := c.reports_sql;
                    l_first := FALSE;
                ELSE
                    l_sql := l_sql || ' UNION ' || c.reports_sql;
                END IF;
            END LOOP;
        
        END LOOP;
    
        IF i_episode IS NOT NULL
           AND i_patient IS NOT NULL
        THEN
            --Obtem os dados do paciente para impress�o do c�digo de barras
            l_message := 'GET PATIENT BARCODE';
            IF NOT pk_patient.get_barcode_print_new(i_lang              => i_lang,
                                                    i_episode           => i_episode,
                                                    i_patient           => i_patient,
                                                    i_prof              => i_prof,
                                                    o_printer           => l_printer,
                                                    o_codification_type => l_codification_type,
                                                    o_barcode_pat       => l_barcode_pat,
                                                    o_barcode_nec       => l_barcode_nec,
                                                    o_barcode_pat_n     => l_barcode_pat_n,
                                                    o_error             => l_error)
            THEN
                o_error := l_error;
                RAISE e_user_exception;
            END IF;
        END IF;
    
        --Constroi o SQL a ser executado
        l_message := 'BUILD COMPLETE QUERY';
        IF l_sql IS NULL
        THEN
            l_sql := 'SELECT t.rank,' || --
                     '       t.id_reports,' || --
                     '       t.id_rep_section,' || --
                     '       t.id_rep_section_det,' || --
                     '       t.desc_section,' || --
                     '       NULL AS desc_section_info,' || --
                     '       NULL AS dt_section,' || --
                     '       ''@FLG_SELECTED'' AS flg_selected,' || --
                     '       NULL AS printer_name,' || --
                     '       NULL AS codification_type,' || --
                     '       NULL AS barcode_pat,' || --
                     '       NULL AS barcode_nec,' || --
                     '       t.flg_num_prints,' || --
                     '       t.flg_default,' || --
                     '       NULL AS flg_task,' || --
                     '       NULL AS cfg_show_previewer' || --
                     '  FROM ( SELECT d.rank,' || --
                     '                d.id_reports,' || --
                     '                s.id_rep_section,' || --
                     '                d.id_rep_section_det,' ||
                     '                pk_message.get_message(@I_LANG, profissional(@I_PROF, @INSTITUTION, @SOFTWARE), s.code_rep_section) AS desc_section, ' || --
                     '                1 AS flg_num_prints,' || --
                     '                nvl(d.flg_default, ''' || pk_alert_constant.g_active || ''') AS flg_default,' || --
                     '                rank() over(PARTITION BY d.id_rep_section ORDER BY d.id_market DESC, d.id_institution DESC, d.id_software DESC, d.id_rep_profile_template DESC) myrank,' || --
                     '                d.flg_visible,' || --
                     '                s.flg_available' || --
                     '          FROM rep_section s' || --
                     '         INNER JOIN rep_section_det d' || --
                     '            ON s.id_rep_section = d.id_rep_section' || ----
                     '         WHERE d.id_reports IN (@I_REPORTS)' || --
                     '           AND d.id_market IN (@ID_MARKET, 0)' || --
                     '           AND d.id_institution IN (@INSTITUTION, 0)' || --
                     '           AND d.id_software IN (@SOFTWARE, 0) ' || --
                     '       AND d.id_rep_profile_template IN (' || l_rep_prof_template || ', 0) ' || --
                     '       AND d.id_rep_section_det NOT IN ' || --
                     '           ( SELECT t.id_rep_section_det ' || --
                     '               FROM rep_section_det t  ' || --
                     '             WHERE t.id_rep_profile_template = 0  ' || --
                     '               AND t.id_rep_section IN  ' || --
                     '                 (SELECT t2.id_rep_section ' || --
                     '                    FROM rep_section_det t2 ' || --
                     '                    WHERE t2.id_rep_profile_template = ' || --
                     '                           decode(' || l_rep_prof_template || ', 0, 1, ' || l_rep_prof_template || ') ' || --
                     '                    AND t2.id_market = t.id_market ' || --
                     '                    AND t2.id_institution = t.id_institution  ' || --
                     '                    AND t2.id_software = t.id_software))) t ' ||
                     '  WHERE nvl(t.flg_available, ''@G_AVAILABLE'') = ''@G_AVAILABLE'' ' || --
                     '  AND (''@I_SHOW_INVISIBLE'' = ''' || c_all || ''' OR ' || --
                     '  ''@I_SHOW_INVISIBLE'' = t.flg_visible) ' || --
                     '  AND t.myrank = 1';
        ELSE
            l_sql := 'SELECT t.rank,' || --
                     '       t.id_reports,' || --
                     '       t.id_rep_section,' || --
                     '       t.id_rep_section_det,' || --
                     '       t.desc_section,' || --
                     '       NULL AS desc_section_info,' || --
                     '       NULL AS dt_section,' || --
                     '       ''@FLG_SELECTED'' AS flg_selected,' || --
                     '       NULL AS printer_name,' || --
                     '       NULL AS codification_type,' || --
                     '       NULL AS barcode_pat,' || --
                     '       NULL AS barcode_nec,' || --
                     '       t.flg_num_prints,' || --
                     '       t.flg_default,' || --
                     '       NULL AS flg_task,' || --
                     '       NULL AS cfg_show_previewer' || --
                     '  FROM ( SELECT d.rank,' || --
                     '                d.id_reports,' || --
                     '                s.id_rep_section,' || --
                     '                d.id_rep_section_det,' ||
                     '                pk_message.get_message(@I_LANG, profissional(@I_PROF, @INSTITUTION, @SOFTWARE), s.code_rep_section) AS desc_section, ' || --
                     '                1 AS flg_num_prints,' || --
                     '                nvl(d.flg_default, ''' || pk_alert_constant.g_active || ''') AS flg_default,' || --
                     '                rank() over(PARTITION BY d.id_rep_section ORDER BY d.id_market DESC, d.id_institution DESC, d.id_software DESC, d.id_rep_profile_template DESC) myrank,' || --
                     '                d.flg_visible,' || --
                     '                s.flg_available' || --
                     '          FROM rep_section s' || --
                     '         INNER JOIN rep_section_det d' || --
                     '            ON s.id_rep_section = d.id_rep_section' || ----
                     '         WHERE d.id_reports IN (@I_REPORTS)' || --
                     '           AND d.id_market IN (@ID_MARKET, 0)' || --
                     '           AND d.id_institution IN (@INSTITUTION, 0)' || --
                     '           AND d.id_software IN (@SOFTWARE, 0) ' || --
                     '       AND d.id_rep_profile_template IN (' || l_rep_prof_template || ', 0) ' || --
                     '       AND d.id_rep_section_det NOT IN ' || --
                     '           ( SELECT t.id_rep_section_det ' || --
                     '               FROM rep_section_det t  ' || --
                     '             WHERE t.id_rep_profile_template = 0  ' || --
                     '               AND t.id_rep_section IN  ' || --
                     '                 (SELECT t2.id_rep_section ' || --
                     '                    FROM rep_section_det t2 ' || --
                     '                    WHERE t2.id_rep_profile_template = ' || --
                     '                           decode(' || l_rep_prof_template || ', 0, 1, ' || l_rep_prof_template || ') ' || --
                     '                    AND t2.id_market = t.id_market ' || --
                     '                    AND t2.id_institution = t.id_institution  ' || --
                     '                    AND t2.id_software = t.id_software))) t ' ||
                     '  WHERE nvl(t.flg_available, ''@G_AVAILABLE'') = ''@G_AVAILABLE'' ' || --
                     '  AND (''@I_SHOW_INVISIBLE'' = ''' || c_all || ''' OR ' || --
                     '  ''@I_SHOW_INVISIBLE'' = t.flg_visible) ' || --
                     '  AND t.myrank = 1' || --
                     'UNION ALL ' || --
                     l_sql;
        END IF;
    
        --Substitui vari�veis do cursor antes da execu��o
        l_message := 'REPLACE VARIABLES';
        l_sql     := REPLACE(l_sql, '@I_LANG', i_lang);
        l_sql     := REPLACE(l_sql, '@I_REPORTS', l_reports);
        l_sql     := REPLACE(l_sql, '@I_PROF', i_prof.id);
        l_sql     := REPLACE(l_sql, '@INSTITUTION', i_prof.institution);
        l_sql     := REPLACE(l_sql, '@SOFTWARE', i_prof.software);
        l_sql     := REPLACE(l_sql, '@EPISODE', i_episode);
        l_sql     := REPLACE(l_sql, '@PATIENT', i_patient);
        l_sql     := REPLACE(l_sql, '@FLG_SELECTED', pk_alert_constant.g_active);
        l_sql     := REPLACE(l_sql, '@I_SHOW_INVISIBLE', i_section_visibility);
        l_sql     := REPLACE(l_sql, '@ID_MARKET', l_market);
        --C�digos de barras da identifca��o do paciente e acompanhante
        l_sql := REPLACE(l_sql, '@BARCODE_PAT', l_barcode_pat);
        l_sql := REPLACE(l_sql, '@BARCODE_NEC', l_barcode_nec);
        l_sql := REPLACE(l_sql, '@G_AVAILABLE', pk_alert_constant.g_yes);
        l_sql := REPLACE(l_sql, '@WL_TICKET', l_ticket_number);
        --Adiciona cl�usula de ordena��o
        IF l_sql IS NOT NULL
        THEN
            IF i_count IS NULL
            THEN
                l_sql := l_sql || ' ORDER BY rank, desc_section ';
            END IF;
            --Abre cursor
            l_message := 'OPEN O_SECTION CURSOR';
            OPEN o_section FOR pk_string_utils.clob_to_plsqlvarchar2(l_sql);
        ELSE
            --N�o foi constru�do nenhum SQL, logo n�o h� cursor para ser executado
            pk_types.open_my_cursor(o_section);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_get_rep_prof_id_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INVISIBLE_SECTION_LIST',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INVISIBLE_SECTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_section);
            RETURN FALSE;
    END get_invisible_section_list;

    /**
    * Overload function to allow showing or not the virtual sections. Used by Reports (java) only.
    *
    * @param   I_EPISODE            ID do epis�dio
    * @param   I_PATIENT            ID do paciente
    * @param   I_REPORTS            ID do report que � um grupo
    *
    * @param   O_SECTION            Array com a lista de sec��es do report
    * @param   O_ERROR              Descri��o do erro
    *
    * @param i_lang language id
    * @param i_prof professional type
    * @param i_episode episode's ID
    * @param i_reports report's ID array
    * @param i_show_visible flag indicating whether virtual sections should also be returned ('A' = All, 'Y' = Visible, 'N' = Invisible)
    *
    * @param o_section cursor with section information
    * @param o_error error message
    *
    * @return true (success), false (error)
    *
    * @author Gon�alo Almeida, 2011/May/19
    * @version 2.6.1.0.2
    * @since 2011/May/19
    **********************************************************************************************/
    FUNCTION get_invisible_section_list_rep
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_reports            IN reports.id_reports%TYPE,
        i_section_visibility IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_section            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message           debug_msg;
        l_market            market.id_market%TYPE;
        l_rep_prof_template rep_prof_template.id_rep_prof_template%TYPE;
    BEGIN
        l_message := 'GET_INSTITUTION_MARKET with institution: ' || i_prof.institution;
        pk_alertlog.log_debug(l_message);
    
        l_market := pk_core.get_inst_mkt(i_prof.institution);
    
        l_message := 'GET_REP_PROF_IF with ID_PROFESSIONAL: ' || i_prof.id || ' ID_INSTITUTION: ' || i_prof.institution ||
                     ' id_software: ' || i_prof.software;
        pk_alertlog.log_debug(l_message);
    
        IF NOT
            get_rep_prof_id(i_lang => i_lang, i_prof => i_prof, o_id_profile => l_rep_prof_template, o_error => o_error)
        THEN
            l_message := 'SET l_rep_prof_template with default report profile: ' || g_default_rep_profile_id;
            pk_alertlog.log_debug(l_message);
            -- No exception is handled to be able to generate reports without the report profile.
            l_rep_prof_template := g_default_rep_profile_id;
        END IF;
    
        l_message := 'OPEN O_SECTION';
        OPEN o_section FOR
            SELECT t.rank,
                   t.id_reports,
                   t.id_rep_section,
                   t.id_rep_section_det,
                   pk_message.get_message(i_lang, i_prof, t.code_rep_section) desc_section,
                   NULL desc_section_info,
                   NULL dt_section,
                   pk_alert_constant.g_active flg_selected,
                   NULL printer_name,
                   NULL barcode_pat,
                   NULL barcode_nec,
                   1 flg_num_prints,
                   nvl(t.flg_default, pk_alert_constant.g_active) flg_default,
                   t.flg_task
              FROM (SELECT d.id_rep_section_det,
                           d.rank,
                           d.id_reports,
                           s.id_rep_section,
                           s.code_rep_section,
                           d.flg_default,
                           (SELECT rs.flg_task
                              FROM rep_notes_section rs
                             WHERE d.id_rep_section = rs.id_rep_section
                               AND rs.flg_available = pk_alert_constant.g_available
                               AND rs.id_reports = d.id_reports) flg_task,
                           rank() over(PARTITION BY d.id_rep_section ORDER BY d.id_market DESC, d.id_institution DESC, d.id_software DESC, d.id_rep_profile_template DESC) myrank
                      FROM rep_section_det d
                     INNER JOIN rep_section s
                        ON s.id_rep_section = d.id_rep_section
                     WHERE d.id_reports = i_reports
                       AND nvl(s.flg_available, pk_alert_constant.g_available) = pk_alert_constant.g_available
                       AND (i_section_visibility = c_all OR i_section_visibility = d.flg_visible)
                       AND d.id_market IN (l_market, pk_alert_constant.g_id_market_all)
                       AND d.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                       AND d.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                          -- JR: add default profile on the condition and the sections which common on profile = 0 should not
                          -- be returned
                       AND d.id_rep_profile_template IN (l_rep_prof_template, g_default_rep_profile_id)
                       AND d.id_rep_section_det NOT IN
                           (SELECT t.id_rep_section_det
                              FROM rep_section_det t
                             WHERE t.id_rep_profile_template = g_default_rep_profile_id
                               AND t.id_rep_section IN
                                   (SELECT t2.id_rep_section
                                      FROM rep_section_det t2
                                     WHERE t2.id_rep_profile_template =
                                           decode(l_rep_prof_template, g_default_rep_profile_id, 1, l_rep_prof_template)
                                          -- Exclude only when l_rep_prof_template <> 0
                                       AND t2.id_market = t.id_market
                                       AND t2.id_institution = t.id_institution
                                       AND t2.id_software = t.id_software))) t
             WHERE myrank = 1
             ORDER BY desc_section;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_get_rep_prof_id_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INVISIBLE_SECTION_LIST_REP',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INVISIBLE_SECTION_LIST_REP',
                                              o_error);
            pk_types.open_my_cursor(o_section);
            RETURN FALSE;
    END get_invisible_section_list_rep;

    /**********************************************************************************************
    * SET_EPIS_REPORT_CTX           Save the creation of one report and it's related information
    *
    * @param   I_LANG               Language identifier
    * @param   I_PROF               Professional (professional identifier, institution and software)
    * @param   I_CONTEXT            Context identifier: episode, audit, parameter generation or other...
    * @param   I_REPORTS            Report identifier
    * @param   I_SECTIONS           Array of reports sections identifiers
    * @param   I_FLG_STATUS         Destiny of report. Possible values:
    *                                   {*} 'I' Printed
    *                                   {*} 'E' Sent by e-mail
    *                                   {*} 'F' Sent by fax
    *                                   {*} 'R' Prescription issued
    *                                   {*} 'N' Not generated
    *                                   {*} 'S' Saved
    * @param   I_FLG_EDIT           Editable report? Possible values:
    *                                   {*} 'Y'- Yes
    *                                   {*} 'N'-No
    * @param   I_REP_BINARY_FILE    Binary data of this report
    * @param   I_FLG_CONFIDENTIAL   Confidential information is present in this report. Possible values:
    *                                   {*} 'Y'- Yes
    *                                   {*} 'N'-No
    * @param   I_DT_BEGIN_REPORT    Date begin (varchar format) of the information printed in one timeframe report
    * @param   I_DT_END_REPORT      Date end (varchar format) of the information printed in one timeframe report
    * @param   I_FLG_DATE_FILTERS   Was this report printed with date filtering?
    *                                   {*} 'Y'- Yes
    *                                   {*} 'N'-No
    *
    * @param i_dt_request                    Date of request
    * @param i_dt_disclosure                 Date of disclosure
    * @param i_disclosure_recipient          Disclosure recipient
    * @param i_recipient_address             Recipient address
    * @param i_sample_text                   Sample text id
    * @param i_free_text_purp_disc           Report purpose for disclosure free text
    * @param i_flg_disc_recipient            Disclosure recipient type
    * @param i_id_professional_req           Professional that requested the report (printing list request)
    * @param   O_ID_EPIS_REPORT     Epis report identifier created
    * @param   O_ERROR              Error description
    *
    * @value   i_flg_disc_recipient 'C' - Courts
    *                               'A' - Attorneys
    *                               'P' - Patients
    *                               'M' - Medical Facilities
    *                               'O' - Other
    *
    * @return                       Boolean - true (success), false (error)
    *
    * @author                       Jo�o Eiras
    * @version                      2.4.0
    * @since                        25-Set-2007
    *
    * @change                       Lu�s Maia
    * @version                      2.6.0.5.1.5
    * @since                        15-Feb-2011
    **********************************************************************************************/
    FUNCTION set_epis_report_ctx_int
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_context             IN epis_report.id_episode%TYPE,
        i_reports             IN reports.id_reports%TYPE,
        i_sections            IN table_number,
        i_flg_status          IN epis_report.flg_status%TYPE,
        i_flg_edit            IN epis_report.flg_edit%TYPE,
        i_rep_binary_file     IN epis_report.rep_binary_file%TYPE,
        i_flg_confidential    IN epis_report.flg_confidential%TYPE,
        i_dt_begin_report     IN VARCHAR2,
        i_dt_end_report       IN VARCHAR2,
        i_flg_date_filters    IN epis_report.flg_date_filters%TYPE,
        i_flg_disclosure      IN epis_report.flg_disclosure%TYPE DEFAULT pk_alert_constant.g_no,
        i_dt_request          IN VARCHAR2,
        i_dt_disclosure       IN VARCHAR2,
        i_disclosure_to       IN epis_report_disclosure.disclosure_recipient%TYPE,
        i_recipient_address   IN epis_report_disclosure.recipient_address%TYPE,
        i_sample_text         IN epis_report_disclosure.id_sample_text%TYPE,
        i_free_text_purp_disc IN epis_report_disclosure.free_text_purp_disc%TYPE,
        i_notes               IN epis_report_disclosure.notes%TYPE,
        i_flg_disc_recipient  IN epis_report_disclosure.flg_disc_recipient%TYPE,
        i_id_professional_req IN professional.id_professional%TYPE,
        i_flg_share_grid      IN VARCHAR2,
        i_flg_report_origin   IN VARCHAR2,
        i_flg_saved_outside   IN VARCHAR2,
        o_id_doc_external     OUT epis_report.id_doc_external%TYPE,
        o_id_epis_report      IN OUT epis_report.id_epis_report%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_context_col reports.flg_context_column%TYPE;
        l_erh         epis_report%ROWTYPE;
        l_message     debug_msg;
    
        l_dt_begin_report TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_dt_end_report   TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_my_exception EXCEPTION;
    
        l_sysdate      CONSTANT DATE := SYSDATE;
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        i_epis_parent epis_report.id_epis_parent%TYPE := NULL;
    
    BEGIN
        l_message := 'GET CONTEXT';
        SELECT flg_context_column
          INTO l_context_col
          FROM reports r
         WHERE r.id_reports = i_reports;
    
        IF i_dt_begin_report IS NOT NULL
        THEN
            l_message         := 'GET L_DT_BEGIN_REPORT';
            l_dt_begin_report := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_timestamp => i_dt_begin_report,
                                                               i_timezone  => NULL);
        END IF;
    
        IF i_dt_end_report IS NOT NULL
        THEN
            l_message       := 'GET L_DT_END_REPORT';
            l_dt_end_report := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_timestamp => i_dt_end_report,
                                                             i_timezone  => NULL);
        END IF;
    
        IF o_id_epis_report IS NULL
           OR o_id_epis_report = 0
        THEN
            SELECT seq_epis_report.nextval
              INTO o_id_epis_report
              FROM dual;
        
            INSERT INTO epis_report
                (id_epis_report,
                 id_reports,
                 id_episode,
                 id_professional,
                 adw_last_update,
                 flg_status,
                 rep_binary_file,
                 flg_edit,
                 dt_creation_tstz,
                 id_audit_req_prof_epis,
                 id_audit_req_prof,
                 id_reports_gen_param,
                 id_social_episode,
                 id_patient,
                 id_external_request,
                 id_visit,
                 id_audit_req,
                 flg_confidential,
                 flg_disclosure,
                 dt_timeframe_begin,
                 dt_timeframe_end,
                 flg_date_filters,
                 id_professional_req,
                 id_epis_parent,
                 flg_type,
                 flg_report_origin,
                 flg_saved_outside)
            VALUES
                (o_id_epis_report,
                 i_reports,
                 decode(l_context_col, 'ID_EPISODE', decode(i_context, 0, NULL, i_context)),
                 i_prof.id,
                 l_sysdate,
                 i_flg_status,
                 i_rep_binary_file,
                 i_flg_edit,
                 l_sysdate_tstz,
                 decode(l_context_col, 'ID_AUDIT_REQ_PROF_EPIS', i_context),
                 decode(l_context_col, 'ID_AUDIT_REQ_PROF', i_context),
                 decode(l_context_col, 'ID_REPORTS_GEN_PARAM', i_context),
                 decode(l_context_col, 'ID_SOCIAL_EPISODE', i_context),
                 decode(l_context_col, 'ID_PATIENT', i_context),
                 decode(l_context_col, 'ID_EXTERNAL_REQUEST', i_context),
                 decode(l_context_col, 'ID_VISIT', i_context),
                 -- José Brito 26/11/2008 ALERT-10540
                 decode(l_context_col, 'ID_AUDIT_REQ', i_context),
                 i_flg_confidential,
                 -- Alexandre Santos 10-02-2011 ALERT-60289
                 i_flg_disclosure,
                 l_dt_begin_report,
                 l_dt_end_report,
                 i_flg_date_filters,
                 i_id_professional_req,
                 i_epis_parent,
                 c_flg_type_current,
                 i_flg_report_origin,
                 i_flg_saved_outside)
            RETURNING id_epis_report INTO o_id_epis_report;
        
        ELSE
        
            SELECT *
              INTO l_erh
              FROM epis_report er
             WHERE er.id_epis_report = o_id_epis_report;
        
            UPDATE epis_report oldepis
               SET oldepis.flg_type = c_flg_type_history, oldepis.id_doc_external = NULL
             WHERE oldepis.id_epis_report = o_id_epis_report;
        
            i_epis_parent    := o_id_epis_report;
            o_id_epis_report := seq_epis_report.nextval;
        
            INSERT INTO epis_report
                (id_epis_report,
                 id_reports,
                 id_episode,
                 id_professional,
                 adw_last_update,
                 flg_status,
                 rep_binary_file,
                 flg_edit,
                 dt_creation_tstz,
                 id_audit_req_prof_epis,
                 id_audit_req_prof,
                 id_reports_gen_param,
                 id_social_episode,
                 id_patient,
                 id_external_request,
                 id_visit,
                 id_audit_req,
                 flg_confidential,
                 flg_disclosure,
                 dt_timeframe_begin,
                 dt_timeframe_end,
                 flg_date_filters,
                 id_professional_req,
                 id_epis_parent,
                 id_doc_external,
                 flg_type,
                 flg_report_origin,
                 flg_saved_outside)
            VALUES
                (o_id_epis_report,
                 i_reports,
                 l_erh.id_episode,
                 i_prof.id,
                 l_sysdate,
                 i_flg_status,
                 l_erh.rep_binary_file,
                 l_erh.flg_edit,
                 l_sysdate,
                 l_erh.id_audit_req_prof_epis,
                 l_erh.id_audit_req_prof,
                 l_erh.id_reports_gen_param,
                 l_erh.id_social_episode,
                 l_erh.id_patient,
                 l_erh.id_external_request,
                 l_erh.id_visit,
                 l_erh.id_audit_req,
                 l_erh.flg_confidential,
                 l_erh.flg_disclosure,
                 l_erh.dt_timeframe_begin,
                 l_erh.dt_timeframe_end,
                 l_erh.flg_date_filters,
                 l_erh.id_professional_req,
                 i_epis_parent,
                 l_erh.id_doc_external,
                 c_flg_type_current,
                 i_flg_report_origin,
                 i_flg_saved_outside)
            RETURNING id_epis_report INTO o_id_epis_report;
        
        END IF;
    
        g_error := 'ERROR CALLING PK_PRINT_TOOL.SET_EPIS_REPORT_DYNAMIC_CODE';
        IF NOT pk_print_tool.set_epis_report_dynamic_code(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_epis_report => o_id_epis_report,
                                                          i_json_params => NULL,
                                                          o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        l_message := 'INSERT EPIS_REPORT_SECTION';
        INSERT INTO epis_report_section
            (id_epis_report_section, id_epis_report, id_rep_section, adw_last_update)
            SELECT seq_epis_report_section.nextval, o_id_epis_report, t.column_value, l_sysdate
              FROM TABLE(i_sections) t
             WHERE t.column_value IS NOT NULL;
    
        IF i_flg_disclosure IS NOT NULL
           AND i_flg_disclosure = pk_alert_constant.g_yes
        THEN
            l_message := 'INSERT DISCLOSURE DATA';
            pk_alertlog.log_debug(text => l_message);
            ts_epis_report_disclosure.ins(id_epis_report_in       => o_id_epis_report,
                                          dt_register_in          => l_sysdate_tstz,
                                          id_prof_disclosure_in   => i_prof.id,
                                          dt_request_in           => pk_date_utils.get_string_tstz(i_lang,
                                                                                                   i_prof,
                                                                                                   i_dt_request,
                                                                                                   NULL),
                                          dt_disclosure_in        => pk_date_utils.get_string_tstz(i_lang,
                                                                                                   i_prof,
                                                                                                   i_dt_disclosure,
                                                                                                   NULL),
                                          disclosure_recipient_in => i_disclosure_to,
                                          recipient_address_in    => i_recipient_address,
                                          id_sample_text_in       => i_sample_text,
                                          free_text_purp_disc_in  => i_free_text_purp_disc,
                                          notes_in                => i_notes,
                                          flg_disc_recipient_in   => i_flg_disc_recipient);
        END IF;
    
        IF i_flg_status = g_epis_rep_status_impresso
           OR i_flg_status = g_epis_rep_status_saved
           OR i_flg_share_grid = 'Y'
        THEN
            l_message := 'Insert report in documents archive';
            IF NOT pk_doc.create_report_document(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_epis_report     => o_id_epis_report,
                                                 i_flg_share_grid  => i_flg_share_grid,
                                                 o_id_doc_external => o_id_doc_external,
                                                 o_error           => o_error)
            
            THEN
                RAISE l_my_exception;
            END IF;
        END IF;
    
        IF i_flg_status = g_epis_rep_status_impresso
           OR i_flg_status = g_epis_rep_status_saved
        THEN
            pk_ia_event_common.report_generated(i_prof.institution, o_id_epis_report);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REPORT_CTX_INT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_report_ctx_int;

    /**********************************************************************************************
     * SET_EPIS_REPORT_CTX           Save the creation of one report and it's related information
     *
     * @param   I_LANG               Language identifier
     * @param   I_PROF               Professional (professional identifier, institution and software)
     * @param   I_CONTEXT            Context identifier: episode, audit, parameter generation or other...
     * @param   I_REPORTS            Report identifier
     * @param   I_SECTIONS           Array of reports sections identifiers
     * @param   I_FLG_STATUS         Destiny of report. Possible values:
     *                                   {*} 'I' Printed
     *                                   {*} 'E' Sent by e-mail
     *                                   {*} 'F' Sent by fax
     *                                   {*} 'R' Prescription issued
     *                                   {*} 'N' Not generated
     *                                   {*} 'S' Saved
     * @param   I_FLG_EDIT           Editable report? Possible values:
     *                                   {*} 'Y'- Yes
     *                                   {*} 'N'-No
     * @param   I_REP_BINARY_FILE    Binary data of this report
     * @param   I_FLG_CONFIDENTIAL   Confidential information is present in this report. Possible values:
     *                                   {*} 'Y'- Yes
     *                                   {*} 'N'-No
     * @param   I_DT_BEGIN_REPORT    Date begin (varchar format) of the information printed in one timeframe report
     * @param   I_DT_END_REPORT      Date end (varchar format) of the information printed in one timeframe report
     * @param   I_FLG_DATE_FILTERS   Was this report printed with date filtering?
     *                                   {*} 'Y'- Yes
     *                                   {*} 'N'-No
     *
     * @param i_lang id da lingua
     * @param i_prof obj do utilizador
     * @param i_context id do episodio, ou auditoria, ou gera��o de parametro ou whatever. � o id que � usado como contexto
     * @param i_reports id do relat�rio
     * @param i_sections id das sec��es do relat�rio
     * @param i_flg_status estado da impress�o
     * @param i_flg_edit flag que indica edi��o
     * @param i_rep_binary_file dados bin�rios do relat�rio
     * @param i_flg_disclosure                Is a disclosure report?
     * @param i_dt_request                    Date of request
     * @param i_dt_disclosure                 Date of disclosure
     * @param i_disclosure_recipient          Disclosure recipient
     * @param i_recipient_address             Recipient address
     * @param i_sample_text                   Sample text id
     * @param i_free_text_purp_disc           Report purpose for disclosure free text
     * @param i_flg_disc_recipient            Disclosure recipient type
     * @param i_id_professional_req           Professional that requested the report (printing list request)
     * @param o_error var com mensagem de erro
     *
     * @value   i_flg_disc_recipient 'C' - Courts
     *                               'A' - Attorneys
     *                               'P' - Patients
     *                               'M' - Medical Facilities
     *                               'O' - Other
     *
    * @return true (successo), false (erro)
     *
     * @author Jo�o Eiras, 25-09-2007
     * @version 1.0
     * @since 2.4.0
     */

    FUNCTION set_epis_report_ctx
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_context             IN epis_report.id_episode%TYPE,
        i_reports             IN reports.id_reports%TYPE,
        i_sections            IN table_number,
        i_flg_status          IN epis_report.flg_status%TYPE,
        i_flg_edit            IN epis_report.flg_edit%TYPE,
        i_rep_binary_file     IN epis_report.rep_binary_file%TYPE,
        i_flg_confidential    IN epis_report.flg_confidential%TYPE,
        i_dt_begin_report     IN VARCHAR2,
        i_dt_end_report       IN VARCHAR2,
        i_flg_date_filters    IN epis_report.flg_date_filters%TYPE,
        i_flg_disclosure      IN epis_report.flg_disclosure%TYPE,
        i_dt_request          IN VARCHAR2,
        i_dt_disclosure       IN VARCHAR2,
        i_disclosure_to       IN epis_report_disclosure.disclosure_recipient%TYPE,
        i_recipient_address   IN epis_report_disclosure.recipient_address%TYPE,
        i_sample_text         IN epis_report_disclosure.id_sample_text%TYPE,
        i_free_text_purp_disc IN epis_report_disclosure.free_text_purp_disc%TYPE,
        i_notes               IN epis_report_disclosure.notes%TYPE,
        i_flg_disc_recipient  IN epis_report_disclosure.flg_disc_recipient%TYPE,
        i_id_professional_req IN professional.id_professional%TYPE,
        i_flg_saved_outside   IN VARCHAR2,
        o_id_epis_report      IN OUT epis_report.id_epis_report%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message       debug_msg;
        id_doc_external epis_report.id_doc_external%TYPE;
    
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL SET_EPIS_REPORT_CTX';
        pk_alertlog.log_debug(l_message);
        IF NOT set_epis_report_ctx_int(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_context             => i_context,
                                       i_reports             => i_reports,
                                       i_sections            => i_sections,
                                       i_flg_status          => i_flg_status,
                                       i_flg_edit            => i_flg_edit,
                                       i_rep_binary_file     => i_rep_binary_file,
                                       i_flg_confidential    => i_flg_confidential,
                                       i_dt_begin_report     => i_dt_begin_report,
                                       i_dt_end_report       => i_dt_end_report,
                                       i_flg_date_filters    => i_flg_date_filters,
                                       i_flg_disclosure      => i_flg_disclosure,
                                       i_dt_request          => i_dt_request,
                                       i_dt_disclosure       => i_dt_disclosure,
                                       i_disclosure_to       => i_disclosure_to,
                                       i_recipient_address   => i_recipient_address,
                                       i_sample_text         => i_sample_text,
                                       i_free_text_purp_disc => i_free_text_purp_disc,
                                       i_notes               => i_notes,
                                       i_flg_disc_recipient  => i_flg_disc_recipient,
                                       i_id_professional_req => i_id_professional_req,
                                       i_flg_share_grid      => 'N',
                                       i_flg_report_origin   => NULL,
                                       i_flg_saved_outside   => i_flg_saved_outside,
                                       o_id_doc_external     => id_doc_external,
                                       o_id_epis_report      => o_id_epis_report,
                                       o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REPORT_CTX',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_report_ctx;

    FUNCTION set_epis_report_ctx_grid
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_context             IN epis_report.id_episode%TYPE,
        i_reports             IN reports.id_reports%TYPE,
        i_sections            IN table_number,
        i_flg_status          IN epis_report.flg_status%TYPE,
        i_flg_edit            IN epis_report.flg_edit%TYPE,
        i_rep_binary_file     IN epis_report.rep_binary_file%TYPE,
        i_flg_confidential    IN epis_report.flg_confidential%TYPE,
        i_dt_begin_report     IN VARCHAR2,
        i_dt_end_report       IN VARCHAR2,
        i_flg_date_filters    IN epis_report.flg_date_filters%TYPE,
        i_flg_disclosure      IN epis_report.flg_disclosure%TYPE,
        i_dt_request          IN VARCHAR2,
        i_dt_disclosure       IN VARCHAR2,
        i_disclosure_to       IN epis_report_disclosure.disclosure_recipient%TYPE,
        i_recipient_address   IN epis_report_disclosure.recipient_address%TYPE,
        i_sample_text         IN epis_report_disclosure.id_sample_text%TYPE,
        i_free_text_purp_disc IN epis_report_disclosure.free_text_purp_disc%TYPE,
        i_notes               IN epis_report_disclosure.notes%TYPE,
        i_flg_disc_recipient  IN epis_report_disclosure.flg_disc_recipient%TYPE,
        i_id_professional_req IN professional.id_professional%TYPE,
        i_flg_share_grid      IN VARCHAR2,
        i_flg_report_origin   IN VARCHAR2,
        i_flg_saved_outside   IN VARCHAR2,
        o_id_doc_external     OUT epis_report.id_doc_external%TYPE,
        o_id_epis_report      IN OUT epis_report.id_epis_report%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'CALL TO FUNCTION INTERNAL SET_EPIS_REPORT_CTX';
        pk_alertlog.log_debug(l_message);
        IF NOT set_epis_report_ctx_int(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_context             => i_context,
                                       i_reports             => i_reports,
                                       i_sections            => i_sections,
                                       i_flg_status          => i_flg_status,
                                       i_flg_edit            => i_flg_edit,
                                       i_rep_binary_file     => i_rep_binary_file,
                                       i_flg_confidential    => i_flg_confidential,
                                       i_dt_begin_report     => i_dt_begin_report,
                                       i_dt_end_report       => i_dt_end_report,
                                       i_flg_date_filters    => i_flg_date_filters,
                                       i_flg_disclosure      => i_flg_disclosure,
                                       i_dt_request          => i_dt_request,
                                       i_dt_disclosure       => i_dt_disclosure,
                                       i_disclosure_to       => i_disclosure_to,
                                       i_recipient_address   => i_recipient_address,
                                       i_sample_text         => i_sample_text,
                                       i_free_text_purp_disc => i_free_text_purp_disc,
                                       i_notes               => i_notes,
                                       i_flg_disc_recipient  => i_flg_disc_recipient,
                                       i_id_professional_req => i_id_professional_req,
                                       i_flg_share_grid      => i_flg_share_grid,
                                       i_flg_report_origin   => i_flg_report_origin,
                                       i_flg_saved_outside   => i_flg_saved_outside,
                                       o_id_doc_external     => o_id_doc_external,
                                       o_id_epis_report      => o_id_epis_report,
                                       o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REPORT_CTX',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_report_ctx_grid;

    /**
    * Modifica os estado de um relat�rio gerado
    *
    * @param i_lang id da lingua
    * @param i_prof obj do utilizador
    * @param i_epis_report id do relat�rio gerado
    * @param i_flg_status estado
    * @param o_error var com mensagem de erro
    *
    * @return true (successo), false (erro)
    *
    * @author Jo�o Eiras, 26-09-2007
    * @version 1.0
    * @since 2.4.0
    */
    FUNCTION set_epis_report_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_report IN epis_report.id_epis_report%TYPE,
        i_flg_status  IN epis_report.flg_status%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret           BOOLEAN;
        l_id_episode    episode.id_episode%TYPE;
        l_id_reports    reports.id_reports%TYPE;
        l_internal_name reports.internal_name%TYPE;
        e_user_exception EXCEPTION;
        id_doc_external epis_report.id_doc_external%TYPE;
        l_message       debug_msg;
        l_my_exception EXCEPTION;
    
    BEGIN
        l_message := 'UPDATE ER';
        UPDATE epis_report
           SET flg_status = i_flg_status
         WHERE id_epis_report = i_epis_report;
    
        l_message := 'Insert report in documents archive';
        IF NOT pk_doc.create_report_document(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_epis_report     => i_epis_report,
                                             i_flg_share_grid  => NULL,
                                             o_id_doc_external => id_doc_external,
                                             o_error           => o_error)
        THEN
            RAISE l_my_exception;
        END IF;
    
        l_message := 'Select';
        SELECT er.id_episode, er.id_reports, rep.internal_name
          INTO l_id_episode, l_id_reports, l_internal_name
          FROM epis_report er, reports rep
         WHERE id_epis_report = i_epis_report
           AND er.id_reports = rep.id_reports;
    
        l_message := l_internal_name;
        IF l_internal_name = 'INTRUCTIONS_FOR_PATIENT'
        THEN
            l_ret := pk_discharge.set_epis_report(i_lang, i_prof, l_id_episode, i_epis_report, o_error);
            IF l_ret = FALSE
            THEN
                RAISE e_user_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REPORT_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_report_status;

    /**
    * Modifica a origem da gera��o de um relat�rio: no momento da alta ou atrave�s da print tool
    *
    * @param i_lang id da lingua
    * @param i_prof obj do utilizador
    * @param i_epis_report id do relat�rio gerado
    * @param i_flg_status estado
    * @param o_error var com mensagem de erro
    *
    * @return true (successo), false (erro)
    *
    * @author Carlos Guilherme, 22-12-2010
    * @version 1.0
    * @since 2.6.0.5
    */

    FUNCTION set_epis_report_origin
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_report       IN epis_report.id_epis_report%TYPE,
        i_flg_report_origin IN epis_report.flg_report_origin%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_doc_external epis_report.id_doc_external%TYPE;
    
    BEGIN
    
        g_error := 'UPDATE ER';
        UPDATE epis_report
           SET flg_report_origin = i_flg_report_origin
         WHERE id_epis_report = i_epis_report;
    
        g_error := 'Insert report in documents archive';
        IF NOT pk_doc.create_report_document(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_epis_report     => i_epis_report,
                                             i_flg_share_grid  => NULL,
                                             o_id_doc_external => l_doc_external,
                                             o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REPORT_ORIGIN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_report_origin;

    /**
    * @usage Guarda o relat�rio assinado neste episodio.
    *
    * @param   I_LANG                  L�ngua registada como prefer�ncia do profissional
    * @param   I_PROF                  ID do profissional, institui��o e software
    * @param   I_ID_EPIS_REPORT        ID do registo na EPIS_REPORT
    * @param   I_SIGNED_BINARY_FILE    Ficheiro do relatorio assinado
    * @param   I_DIG_SIG_TYPE
    * @param   O_ERROR                 Descri��o do erro
    *
    * @return     Boolean
    * @author     Rui Spratley
    * @version    2.4.3
    * @since      2008/06/16
    */

    FUNCTION set_report_bin_signed_file
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_epis_report     IN epis_report.id_epis_report%TYPE,
        i_signed_binary_file IN epis_report.signed_binary_file%TYPE,
        i_dig_sig_type       IN epis_report.dig_sig_type%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'UPDATE EPIS_REPORT';
        UPDATE epis_report er
           SET er.signed_binary_file = i_signed_binary_file, er.flg_signed = 'Y', dig_sig_type = i_dig_sig_type
         WHERE er.id_epis_report = i_id_epis_report;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REPORT_BIN_SIGNED_FILE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_report_bin_signed_file;

    /**
    * @usage Saves an encrypted report (zip)
    *
    * @param   I_LANG                            L�ngua registada como prefer�ncia do profissional
    * @param   I_PROF                            ID do profissional, institui��o e software
    * @param   I_ID_EPIS_REPORT                  ID do registo na EPIS_REPORT
    * @param   I_ENCRYPTED_BINARY_FILE           Ficheiro do relatorio encriptado
    * @param   O_ERROR                           Descri��o do erro
    *
    * @return     Boolean
    * @author     goncalo.almeida
    * @version    2.6.1
    * @since      2012/01/24
    */

    FUNCTION set_report_bin_encrypted_file
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_report        IN epis_report.id_epis_report%TYPE,
        i_encrypted_binary_file IN epis_report.rep_binary_encrypted_file%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'UPDATE EPIS_REPORT';
        UPDATE epis_report er
           SET er.rep_binary_encrypted_file = i_encrypted_binary_file, er.flg_encrypted = 'Y'
         WHERE er.id_epis_report = i_id_epis_report;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REPORT_BIN_ENCRYPTED_FILE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_report_bin_encrypted_file;

    /**
    * @usage Obt�m o valor da flag signed da tabela epis_report e configura��es relativas � assinatura digital.
    *
    * @param   I_ID_EPIS_REPORT     Epis Report identifier
    *
    * @param   I_LANG               L�ngua registada como prefer�ncia do profissional
    * @param   I_PROF               ID do profissional, institui��o e software
    * @param   O_DIG_SIG_TYPE       Tipo de assinatura digital que este report tem (pode n�o ser nenhuma)
    * @param   O_DIG_SIG            epis_report.flg_signed
    * @param   O_SHOW_DIG_SIG       show digital signature? Y for show, N for hide.
    * @param   O_DIG_SIG_PARAMS     digital signature parameters
    * @param   O_ERROR              Descri��o do erro
    *
    * @return     Boolean
    * @author     Thiago Brito, Lu�s Gaspar
    * @version    2.4.3  2008/05/28, 2008/08/12
    */

    FUNCTION get_dig_sig_flg
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_report        IN epis_report.id_epis_report%TYPE,
        o_dig_sig_type          OUT epis_report.dig_sig_type%TYPE,
        o_dig_sig               OUT epis_report.flg_signed%TYPE,
        o_show_dig_sig          OUT reports_inst_soft.flg_digital_signature%TYPE,
        o_dig_sig_param         OUT reports.flg_digital_signature_format%TYPE,
        o_flg_dig_sig_save_file OUT reports_inst_soft.flg_dig_sig_save_file%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR l_c_dig_sig IS
            SELECT er.dig_sig_type,
                   er.flg_signed,
                   nvl(ris.flg_digital_signature, pk_alert_constant.g_no) flg_digital_signature,
                   r.flg_digital_signature_format,
                   nvl(ris.flg_dig_sig_save_file, pk_alert_constant.g_yes) flg_dig_sig_save_file
              FROM epis_report er
              JOIN reports r
                ON r.id_reports = er.id_reports
              LEFT JOIN reports_inst_soft ris
                ON er.id_reports = ris.id_reports
               AND ris.id_institution = i_prof.institution
               AND ris.id_software IN (i_prof.software, 0)
             WHERE er.id_epis_report = i_id_epis_report
            -- we may have records for all softwares and a specific software. In this situation prefer specific software record
             ORDER BY ris.id_software DESC;
    
    BEGIN
    
        OPEN l_c_dig_sig;
        FETCH l_c_dig_sig
            INTO o_dig_sig_type, o_dig_sig, o_show_dig_sig, o_dig_sig_param, o_flg_dig_sig_save_file;
        CLOSE l_c_dig_sig;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DIG_SIG_FLG',
                                              o_error);
            IF l_c_dig_sig%ISOPEN
            THEN
                CLOSE l_c_dig_sig;
            END IF;
        
            RETURN FALSE;
    END get_dig_sig_flg;

    /**
    * @usage Obt�m a lista de relat�rios impressos para um paciente.
    *
    * @param   I_LANG               L�ngua registada como prefer�ncia do profissional
    * @param   I_PROF               ID do profissional, institui��o e software
    * @param   I_EPISODE            ID do epis�dio
    * @param   I_PATIENT            ID do paciente
    *
    * @param   O_ARCHIVE            Array com os dados do Archive
    * @param   O_ERROR              Descri��o do erro
    *
    * @return     Boolean
    * @author     RB
    * @version    1.0  2007/02/17
    */

    FUNCTION get_archive_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_archive OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_visit visit.id_visit%TYPE;
    
        l_episode table_number := table_number();
    
    BEGIN
    
        l_visit := pk_visit.get_visit(i_episode, o_error);
    
        SELECT e.id_episode
          BULK COLLECT
          INTO l_episode
          FROM episode e
         WHERE e.id_visit = l_visit;
    
        OPEN o_archive FOR
            SELECT er.id_epis_report,
                   er.id_reports,
                   er.flg_status,
                   pk_sysdomain.get_domain(c_epis_report_domain, er.flg_status, i_lang) flg_status_desc,
                   (CASE er.flg_date_filters
                       WHEN pk_alert_constant.g_no THEN
                        CASE er.flg_encrypted
                            WHEN pk_alert_constant.g_yes THEN
                             'SaveEncryptedIcon'
                            ELSE
                             CASE er.flg_saved_outside
                                 WHEN pk_alert_constant.g_yes THEN
                                  'SaveDiskIcon'
                                 ELSE
                                  pk_print_tool.get_icon(i_lang, i_prof, er.id_epis_report, er.flg_status)
                             END
                        END
                       ELSE
                        CASE er.flg_saved_outside
                            WHEN pk_alert_constant.g_yes THEN
                             'SaveDiskIcon'
                            ELSE
                             pk_sysdomain.get_img(i_lang, g_domain_flg_date_filters, er.flg_date_filters)
                        END
                   END) img_name,
                   (SELECT coalesce(pk_message.get_message(i_lang, er.code_dynamic_title),
                                    pk_translation.get_translation(i_lang, r.code_reports_title),
                                    pk_translation.get_translation(i_lang, r.code_reports))
                      FROM reports r
                     WHERE er.id_reports = r.id_reports) report_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, er.id_professional) nick_name,
                   (SELECT pk_translation.get_translation(i_lang, et.code_epis_type)
                      FROM epis_type et
                     INNER JOIN episode e
                        ON e.id_epis_type = et.id_epis_type
                     WHERE e.id_episode = er.id_episode) desc_epis_type,
                   pk_date_utils.date_char_hour_tsz(i_lang, er.dt_creation_tstz, i_prof.institution, i_prof.software) hour_creation,
                   pk_date_utils.dt_chr_tsz(i_lang, er.dt_creation_tstz, i_prof.institution, i_prof.software) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, er.dt_creation_tstz, i_prof.institution, i_prof.software) dt_printed,
                   pk_date_utils.dt_chr_tsz(i_lang, er.dt_timeframe_begin, i_prof.institution, i_prof.software) dt_timeframe_begin,
                   pk_date_utils.dt_chr_tsz(i_lang, er.dt_timeframe_end, i_prof.institution, i_prof.software) dt_timeframe_end,
                   er.flg_signed,
                   pk_sysdomain.get_domain(g_domain_flg_signed, er.flg_signed, i_lang) flg_signed_desc,
                   decode((SELECT p.alias
                            FROM episode e
                            JOIN patient p
                              ON (e.id_patient = p.id_patient)
                           WHERE e.id_episode = i_episode),
                          NULL,
                          pk_alert_constant.get_no,
                          decode(pk_patient.get_prof_resp(i_lang, i_prof, er.id_patient, er.id_episode),
                                 1,
                                 pk_alert_constant.get_no,
                                 er.flg_confidential)) flg_confidential,
                   (SELECT r.flg_printer
                      FROM reports r
                     WHERE er.id_reports = r.id_reports) flg_printer,
                   er.flg_encrypted,
                   decode(er.flg_saved_outside,
                          pk_alert_constant.g_no,
                          decode((SELECT COUNT(1)
                                   FROM epis_report e
                                  WHERE e.id_epis_report <> er.id_epis_report
                                    AND e.flg_saved_outside = pk_alert_constant.g_yes
                                  START WITH e.id_epis_report = er.id_epis_report
                                 CONNECT BY PRIOR e.id_epis_parent = e.id_epis_report),
                                 0,
                                 er.flg_saved_outside,
                                 pk_alert_constant.g_flg_status_report_h),
                          er.flg_saved_outside) flg_saved_outside
              FROM epis_report er
             WHERE er.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      *
                                       FROM TABLE(l_episode) t)
                  --Because of documents archive we need to add these new flg_status
               AND (er.flg_status = g_epis_rep_status_impresso OR er.flg_status = g_epis_rep_status_saved OR
                   er.flg_signed = pk_alert_constant.g_yes OR er.flg_background = pk_alert_constant.g_yes OR
                   er.flg_encrypted = pk_alert_constant.g_yes)
               AND er.flg_type = c_flg_type_current
             ORDER BY er.dt_creation_tstz DESC, er.flg_status;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => 'OPEN O_ARCHIVE ARRAY',
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ARCHIVE_DET',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_archive);
            RETURN FALSE;
        
    END get_archive_det;

    FUNCTION set_edit_reports_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_reports         IN reports.id_reports%TYPE,
        i_text            IN CLOB,
        o_rep_edit_report OUT rep_edit_report.id_rep_edit_report%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message debug_msg;
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
        --Guarda o texto editado do relat�rio
        l_message := 'INSERT REP_EDIT_REPORT';
        INSERT INTO rep_edit_report
            (id_rep_edit_report,
             id_reports,
             id_professional,
             dt_report_tstz,
             flg_print,
             flg_status,
             rep_text,
             id_episode)
        VALUES
            (seq_rep_edit_report.nextval,
             i_reports,
             i_prof.id,
             l_sysdate_tstz,
             pk_alert_constant.g_no,
             pk_alert_constant.g_active,
             i_text,
             i_episode)
        RETURNING id_rep_edit_report INTO o_rep_edit_report;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EDIT_REPORTS_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_edit_reports_det;

    /**
    * Retorna o multichoice com os valore possiveis para a coluna REPORTS_GEN_PARAMN.FLG_TIME_FRACTION
    *
    * @param i_lang id_da lingua
    * @param i_prof
    * @param o_mchoice cursor com o mchoice
    * @param o_error mensagem de erro, caso aplic�vel
    * @return true (tudo ok), false (erro)
    *
    * @author Jo�o Eiras, 26-09-2007
    * @since 2.4.0.*
    * @version 1.0
    */

    FUNCTION get_time_fraction_mchoice
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_mchoice OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN O_MCHOICE';
        OPEN o_mchoice FOR
            SELECT s.desc_val, s.val, s.rank, s.img_name
              FROM sys_domain s
             WHERE s.id_language = i_lang
               AND s.code_domain = 'REPORTS_GEN_PARAM.FLG_TIME_FRACTION'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.flg_available = pk_alert_constant.g_yes
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIME_FRACTION_MCHOICE',
                                              o_error);
            pk_types.open_my_cursor(o_mchoice);
            RETURN FALSE;
        
    END get_time_fraction_mchoice;

    /**
    * Retorna a lista de profissionais dispon�veis para a gera��o deste relat�rio
    *
    * @param i_lang id_da lingua
    * @param i_prof objecto do utilizador
    * @param i_reports id do relat�rio
    * @param i_dt_begin data de inicio do per�odo, do qual se podem escolher profissionais
    * @param i_dt_end data de fim do per�odo, do qual se podem escolher profissionais
    * @param o_profs cursor com os profissionais
    * @param o_error mensagem de erro, caso aplic�vel
    * @return true (tudo ok), false (erro)
    *
    * @author Jo�o Eiras, 27-09-2007
    * @since 2.4.0.*
    * @version 1.0
    */

    FUNCTION get_reports_prof_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_reports  IN reports.id_reports%TYPE,
        i_dt_begin IN VARCHAR2,
        i_dt_end   IN VARCHAR2,
        o_profs    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sql CLOB;
    
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET SQL';
        SELECT prof_sql
          INTO l_sql
          FROM reports
         WHERE id_reports = i_reports;
    
        l_message := 'REPLACES';
        l_sql     := REPLACE(l_sql, '%I_INSTITUTION', to_char(i_prof.institution));
        l_sql     := REPLACE(l_sql, '%I_LANG', to_char(i_lang));
        l_sql     := REPLACE(l_sql, '%I_DT_BEGIN', REPLACE(i_dt_begin, '''', ''''''));
        l_sql     := REPLACE(l_sql, '%I_DT_END', REPLACE(i_dt_end, '''', ''''''));
    
        l_message := 'OPEN O_PROFS';
        OPEN o_profs FOR pk_string_utils.clob_to_plsqlvarchar2(l_sql);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
        
    END get_reports_prof_list;

    /**
    * Grava um conjunto de parametros para a gera��o de um relat�rio
    * para possibilitar a gera��o deste
    *
    * @param i_lang id_da lingua
    * @param i_prof objecto do utilizador
    * @param i_dt_begin array com datas de inicio do per�odo, do qual se podem escolher profissionais
    * @param i_dt_end array com datas de fim do per�odo, do qual se podem escolher profissionais
    * @param i_ids_profs array com ids de profissionais
    * @param i_flg_time_fraction frac��o da escala do tempo
    * @param o_id_reports_gen_param id de sa�da da tabela reports_gen_param onde ficaram gravados os parametros
    * @param o_error mensagem de erro, caso aplic�vel
    * @return true (tudo ok), false (erro)
    *
    * @author Jo�o Eiras, 27-09-2007
    * @since 2.4.0.*
    * @version 1.0
    */

    FUNCTION set_reports_gen_parameters
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_dt_begin             IN table_varchar,
        i_dt_end               IN table_varchar,
        i_ids_profs            IN table_number,
        i_flg_time_fraction    IN reports_gen_param.flg_time_fraction%TYPE,
        o_id_reports_gen_param OUT reports_gen_param.id_reports_gen_param%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ranks table_number;
        e_user_exception EXCEPTION;
    
        l_message debug_msg;
    
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
        IF i_dt_begin IS NULL
           OR i_dt_end IS NULL
           OR i_dt_begin.count != i_dt_end.count
        THEN
            l_message := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10);
            RAISE e_user_exception;
        END IF;
    
        l_message := 'INS RGP';
        INSERT INTO reports_gen_param
            (id_reports_gen_param, dt_saved_tstz, id_professional, id_institution, flg_time_fraction)
        VALUES
            (seq_reports_gen_param.nextval, l_sysdate_tstz, i_prof.id, i_prof.institution, i_flg_time_fraction)
        RETURNING id_reports_gen_param INTO o_id_reports_gen_param;
    
        l_message := 'CALC RANKS';
        l_ranks   := table_number();
        l_ranks.extend(i_dt_begin.count);
        FOR idx IN 1 .. i_dt_begin.count
        LOOP
            l_ranks(idx) := idx;
        END LOOP;
    
        l_message := 'INS RGP_D';
        FORALL idx IN 1 .. i_dt_begin.count
            INSERT INTO reports_gen_param_interval
                (id_reports_gen_param_interval, id_reports_gen_param, dt_begin_tstz, dt_end_tstz, rank)
            VALUES
                (seq_reports_gen_param_interval.nextval,
                 o_id_reports_gen_param,
                 pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin(idx), NULL),
                 pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end(idx), NULL),
                 l_ranks(idx));
    
        l_message := 'INS RGP_P';
        FORALL idx IN 1 .. i_ids_profs.count
            INSERT INTO reports_gen_param_profs
                (id_reports_gen_param_profs, id_reports_gen_param, id_professional)
            VALUES
                (seq_reports_gen_param_profs.nextval, o_id_reports_gen_param, i_ids_profs(idx));
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REPORTS_GEN_PARAMETERS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_reports_gen_parameters;

    /********************************************************************************************
    * Devolve o nome do icone a mostrar que indica se o relat�rio j� foi impresso e qual o seu destino.
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do epis�dio
    * @param i_reports          ID do relat�rio
    *
    * @return                   Nome do icone
    *
    * @author                   Rui Batista
    * @since                    2007/12/17
       ********************************************************************************************/

    FUNCTION get_img_name
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_reports IN reports.id_reports%TYPE
    ) RETURN sys_domain.img_name%TYPE IS
    
        CURSOR c_img IS
            SELECT DISTINCT d.img_name
              FROM epis_report er, sys_domain d
             WHERE er.id_episode = i_episode
               AND er.id_reports = i_reports
               AND d.code_domain = c_epis_report_domain
               AND d.domain_owner = pk_sysdomain.k_default_schema
               AND d.id_language = i_lang
               AND nvl(d.val, '@') = nvl(er.flg_status, '@')
               AND er.dt_creation_tstz = (SELECT MAX(dt_creation_tstz)
                                            FROM epis_report er2
                                           WHERE er2.id_episode = er.id_episode
                                             AND er2.id_reports = er.id_reports);
    
        l_img_name sys_domain.img_name%TYPE := NULL;
    
    BEGIN
        --Abre o array e devolve o primeiro valor encontrado
        OPEN c_img;
        FETCH c_img
            INTO l_img_name;
        CLOSE c_img;
    
        RETURN l_img_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_img_name;

    /**********************************************************************************************
    * This function returs the lab description
    *
    * @param i_lang                          Language ID
    * @param i_id_room                       Room ID (Lab ID)
    *
    * @return                                Room description (Lab description)
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/05/25
    **********************************************************************************************/

    FUNCTION get_lab_description
    (
        i_lang    language.id_language%TYPE,
        i_id_room IN room.id_room%TYPE
    ) RETURN VARCHAR2 IS
        l_room_description pk_translation.t_desc_translation;
    
    BEGIN
        IF i_id_room IS NULL
        THEN
            l_room_description := pk_message.get_message(i_lang, 'COMMON_M041');
        ELSE
            SELECT nvl(desc_room, pk_translation.get_translation(i_lang, code_room))
              INTO l_room_description
              FROM room
             WHERE id_room = i_id_room;
        
        END IF;
    
        RETURN l_room_description;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_lab_description;

    /**********************************************************************************************
    * This function returs the report ID for an Exam Type and Lab
    *
    * @param i_lang                          Language ID
    * @param i_id_exam_type                  Exam type ID
    * @param i_id_room                       Room ID (Lab ID)
    *
    * @return                                Report ID
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/05/25
    **********************************************************************************************/

    FUNCTION get_lab_report
    (
        i_id_exam_type IN rep_order_type.id_rep_order_type%TYPE,
        i_id_room      IN room.id_room%TYPE
    ) RETURN NUMBER IS
        l_id_reports reports.id_reports%TYPE;
    
    BEGIN
        SELECT nvl(rotr.id_reports, rot.id_reports_default) id_reports
          INTO l_id_reports
          FROM rep_order_type rot
          LEFT OUTER JOIN rep_order_type_report rotr
            ON rot.id_rep_order_type = rotr.id_rep_order_type
           AND nvl(rotr.id_room, -1) = nvl(i_id_room, -1)
         WHERE rot.id_rep_order_type = i_id_exam_type;
    
        RETURN l_id_reports;
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
        
    END get_lab_report;

    /**********************************************************************************************
    * This function returs the exam types cursor
    *
    * @param i_lang                          Language ID
    * @param i_id_episode                    Episode ID
    * @param o_exam_type_list                Exam type list cursor
    * @param o_error                         Error object
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/05/25
    **********************************************************************************************/

    FUNCTION get_exam_type_list
    (
        i_lang           IN language.id_language%TYPE,
        o_exam_type_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT obj_name := 'GET_EXAM_TYPE_LIST';
        l_message debug_msg;
    
    BEGIN
        l_message := 'OPEN o_exam_type_list CURSOR';
        OPEN o_exam_type_list FOR
            SELECT rot.id_rep_order_type exam_type,
                   pk_translation.get_translation(i_lang, rot.code_rep_order_type) exam_type_description
              FROM rep_order_type rot
             WHERE rot.flg_available = pk_alert_constant.g_yes
             ORDER BY rot.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_exam_type_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_exam_type_list;

    /**********************************************************************************************
    * This function returs the labs for current visit according i_exam_type
    *
    * @param i_lang                          Language ID
    * @param i_id_episode                    Episode ID
    * @param i_id_exam_type                  Exam type ID
    * @param o_lab_list                      Lab list
    * @param o_error                         Error object
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/05/25
    **********************************************************************************************/

    FUNCTION get_lab_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_exam_type IN rep_order_type.id_rep_order_type%TYPE,
        o_lab_list     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT obj_name := 'GET_LAB_LIST';
        l_status_list table_varchar2 := table_varchar2();
        l_id_visit    episode.id_visit%TYPE;
        l_message     debug_msg;
    
    BEGIN
        l_message     := 'GET STATUS FROM SYS_CONFIG';
        l_status_list := pk_utils.str_split(pk_sysconfig.get_config('REPORTS_ORDERS_LABEXAM_STATUS', i_prof),
                                            c_separator);
    
        l_message  := 'GET ID_VISIT BY ID_EPISODE';
        l_id_visit := pk_visit.get_visit(i_id_episode, o_error);
    
        l_message := 'OPEN o_lab_list CURSOR - i_exam_type = ' || i_id_exam_type;
        IF i_id_exam_type = c_exam_type_lab
        THEN
            OPEN o_lab_list FOR
                SELECT sortfield,
                       id_room,
                       lab_description,
                       id_report,
                       decode(pk_print_list_db.check_if_context_exists(i_lang                   => i_lang,
                                                                       i_prof                   => i_prof,
                                                                       i_episode                => i_id_episode,
                                                                       i_print_list_area        => pk_print_list_db.g_print_list_area_orders,
                                                                       i_print_job_context_data => to_clob(id_report)),
                              
                              pk_alert_constant.g_yes,
                              g_icon_exists_in_print_list,
                              NULL) AS flg_status
                  FROM (SELECT DISTINCT nvl2(ltea.id_room_req, 0, 1) sortfield,
                                        ltea.id_room_req id_room,
                                        get_lab_description(i_lang, ltea.id_room_req) lab_description,
                                        get_lab_report(i_id_exam_type, ltea.id_room_req) id_report
                          FROM lab_tests_ea ltea, analysis_req_det ard, episode e
                         WHERE (ltea.id_episode = e.id_episode OR ard.id_episode_origin = e.id_episode)
                           AND e.id_visit = l_id_visit
                           AND ard.id_analysis_req_det = ltea.id_analysis_req_det
                           AND ltea.flg_status_det IN (SELECT column_value
                                                         FROM TABLE(l_status_list))
                           AND nvl(ltea.flg_referral, pk_alert_constant.g_p1_status_a) = pk_alert_constant.g_p1_status_a)
                 ORDER BY sortfield, lab_description;
        ELSE
            OPEN o_lab_list FOR
                SELECT sortfield,
                       id_room,
                       lab_description,
                       id_report,
                       decode(pk_print_list_db.check_if_context_exists(i_lang                   => i_lang,
                                                                       i_prof                   => i_prof,
                                                                       i_episode                => i_id_episode,
                                                                       i_print_list_area        => pk_print_list_db.g_print_list_area_orders,
                                                                       i_print_job_context_data => to_clob(id_report)),
                              
                              pk_alert_constant.g_yes,
                              g_icon_exists_in_print_list,
                              NULL) AS flg_status
                  FROM (SELECT DISTINCT nvl2(eea.id_room, 0, 1) sortfield,
                                        eea.id_room id_room,
                                        get_lab_description(i_lang, eea.id_room) lab_description,
                                        get_lab_report(i_id_exam_type, eea.id_room) id_report
                          FROM exams_ea eea, episode e
                         WHERE (eea.id_episode = e.id_episode OR eea.id_episode_origin = e.id_episode)
                           AND e.id_visit = l_id_visit
                           AND eea.flg_status_det IN (SELECT column_value
                                                        FROM TABLE(l_status_list))
                           AND nvl(eea.flg_referral, pk_alert_constant.g_p1_status_a) = pk_alert_constant.g_p1_status_a
                           AND eea.flg_type = CASE
                                   WHEN i_id_exam_type = c_exam_type_img THEN
                                    c_flg_type_i
                                   ELSE
                                    c_flg_type_e
                               END)
                 ORDER BY sortfield, lab_description;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_lab_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_lab_list;

    /**********************************************************************************************
    * This function returs the tests for current visit and selected lab
    *
    * @param i_lang                          Language ID
    * @param i_id_episode                    Episode ID
    * @param i_id_exam_type                  Exam type ID
    * @param i_id_room                       Romm ID (Lab ID)
    * @param o_exam_list                     Exam list
    * @param o_error                         Error object
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/05/25
    **********************************************************************************************/

    FUNCTION get_exam_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_exam_type IN rep_order_type.id_rep_order_type%TYPE,
        i_id_room      IN room.id_room%TYPE,
        o_exam_list    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT obj_name := 'GET_EXAM_LIST';
        l_status_list table_varchar2 := table_varchar2();
        l_id_visit    episode.id_visit%TYPE;
        l_message     debug_msg;
    
    BEGIN
        l_message     := 'GET STATUS FROM SYS_CONFIG';
        l_status_list := pk_utils.str_split(pk_sysconfig.get_config('REPORTS_ORDERS_LABEXAM_STATUS', i_prof),
                                            c_separator);
    
        l_message  := 'GET ID_VISIT BY ID_EPISODE';
        l_id_visit := pk_visit.get_visit(i_id_episode, o_error);
    
        l_message := 'OPEN o_exam_list CURSOR - i_exam_type = ' || i_id_exam_type || ' - i_id_room = ' || i_id_room;
        IF i_id_exam_type = c_exam_type_lab
        THEN
            OPEN o_exam_list FOR
                SELECT ltea.id_analysis_req_det id_req,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 'A',
                                                                 'ANALYSIS.CODE_ANALYSIS.' || ltea.id_analysis,
                                                                 NULL) exam_description
                  FROM lab_tests_ea ltea, analysis_req_det ard, episode e
                 WHERE (ltea.id_episode = e.id_episode OR ard.id_episode_origin = e.id_episode)
                   AND e.id_visit = l_id_visit
                   AND ard.id_analysis_req_det = ltea.id_analysis_req_det
                   AND ltea.flg_status_det IN (SELECT column_value
                                                 FROM TABLE(l_status_list))
                   AND nvl(ltea.id_room_req, -1) = nvl(i_id_room, -1)
                   AND nvl(ltea.flg_referral, pk_alert_constant.g_p1_status_a) = pk_alert_constant.g_p1_status_a
                 ORDER BY 1;
        ELSE
            OPEN o_exam_list FOR
                SELECT eea.id_exam_req_det id_req,
                       pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) exam_description
                  FROM exams_ea eea, episode e
                 WHERE (eea.id_episode = e.id_episode OR eea.id_episode_origin = e.id_episode)
                   AND e.id_visit = l_id_visit
                   AND eea.flg_status_det IN (SELECT column_value
                                                FROM TABLE(l_status_list))
                   AND nvl(eea.id_room, -1) = nvl(i_id_room, -1)
                   AND nvl(eea.flg_referral, pk_alert_constant.g_p1_status_a) = pk_alert_constant.g_p1_status_a
                   AND eea.flg_type = CASE
                           WHEN i_id_exam_type = c_exam_type_img THEN
                            c_flg_type_i
                           ELSE
                            c_flg_type_e
                       END
                 ORDER BY 1;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_exam_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_exam_list;

    /**
    * Deve retornar um FLG_AUTH e um PRINTER_NAME consoante o profissional e o relat�rio em causa.
    * Deve verificar quais os valores destas flags, associados ao seu perfil (REP_PROFILE_TEMPLATE),
    * assim como poss�veis excep��es.
    *
    * @param i_lang               - identificador da linguagem
    * @param i_prof               - objecto com dados do utilizador
    * @param i_id_reports         - identificador do report
    *
    * @return
    * @author     Marco Freire
    * @since      2009/05/08
    * @version    2.5
    */

    FUNCTION get_rep_auth_print
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_reports IN reports.id_reports%TYPE,
        o_reports    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_REP_AUTH_PRINT';
        l_message debug_msg;
    
        l_id_profile_template     prof_profile_template.id_profile_template%TYPE;
        l_id_rep_profile_template rep_prof_templ_access.id_rep_profile_template%TYPE;
    
    BEGIN
        l_message := 'GET ID PROFILE TEMPLATE';
        BEGIN
            SELECT id_profile_template
              INTO l_id_profile_template
              FROM (SELECT pt.id_profile_template
                      FROM prof_profile_template pt
                     INNER JOIN profile_template prf
                        ON pt.id_profile_template = prf.id_profile_template
                     WHERE pt.id_professional IN (0, i_prof.id)
                       AND pt.id_institution IN (0, i_prof.institution)
                       AND pt.id_software = i_prof.software
                       AND prf.id_templ_assoc IS NOT NULL
                     ORDER BY pt.id_professional DESC, pt.id_institution DESC)
             WHERE rownum < 2;
        
            l_message := 'GET ID REP PROFILE TEMPLATE';
            SELECT rta.id_rep_profile_template
              INTO l_id_rep_profile_template
              FROM rep_prof_templ_access rta
             WHERE rta.id_profile_template = l_id_profile_template;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_profile_template := NULL;
        END;
    
        l_message := 'OPEN CURSOR O_REPORTS';
        OPEN o_reports FOR
            SELECT nvl(res.flg_auth, rep.flg_auth_req) flg_auth,
                   nvl(res.printer_name, rep.printer_name_default) printer_name,
                   nvl(ris.n_copies, rep.n_copies_default) n_copies,
                   nvl(ris.flg_show_dialog, rep.flg_show_dialog_default) flg_show_dialog,
                   nvl(ris.flg_orientation, rep.flg_orientation_default) flg_orientation,
                   nvl(ris.flg_size, rep.flg_size_default) flg_size,
                   nvl(ris.flg_sides, rep.flg_sides_default) flg_sides,
                   nvl(ris.flg_quality, rep.flg_quality_default) flg_quality,
                   nvl(ris.flg_signable, rep.flg_signable) flg_signable
              FROM reports rep,
                   (SELECT re1.*
                      FROM (SELECT nvl(rae.flg_auth, rap.flg_auth) flg_auth, rap.printer_name, rap.id_reports
                              FROM report_auth_print rap
                              LEFT JOIN rep_auth_exception rae
                                ON (rap.id_report_auth_print = rae.id_report_auth_print AND
                                   rae.id_professional = i_prof.id)
                             WHERE rap.id_rep_profile_template = l_id_rep_profile_template
                               AND rap.id_reports = i_id_reports
                               AND rap.id_institution IN (i_prof.institution, 0)
                               AND rap.id_software IN (i_prof.software, 0)
                             ORDER BY rap.id_institution DESC, rap.id_software DESC) re1
                     WHERE rownum = 1) res,
                   (SELECT *
                      FROM (SELECT ris2.id_reports,
                                   ris2.printer_name,
                                   ris2.n_copies,
                                   ris2.flg_show_dialog,
                                   ris2.flg_orientation,
                                   ris2.flg_size,
                                   ris2.flg_sides,
                                   ris2.flg_quality,
                                   ris2.flg_signable
                              FROM reports_inst_soft ris2
                             WHERE ris2.id_reports = i_id_reports
                               AND ris2.id_institution IN (i_prof.institution, 0)
                               AND ris2.id_software IN (i_prof.software, 0)
                             ORDER BY ris2.id_institution DESC, ris2.id_software DESC) ris1
                     WHERE rownum = 1) ris
             WHERE rep.id_reports = i_id_reports
               AND rep.id_reports = res.id_reports(+)
               AND rep.id_reports = ris.id_reports(+);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_reports);
            RETURN FALSE;
        
    END get_rep_auth_print;

    -- GET_REPORT_HEADER
    FUNCTION get_report_header
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_desc_type OUT VARCHAR2,
        o_desc      OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_REPORT_HEADER';
        l_message debug_msg;
    
        l_epis_type episode.id_epis_type%TYPE;
    
        c_complete_surgery_mess  CONSTANT sys_message.code_message%TYPE := 'REP_PERFORMED_SURGERY_001';
        c_scheduled_surgery_mess CONSTANT sys_message.code_message%TYPE := 'SR_LABEL_T153';
    
        l_title_diag sys_message.desc_message%TYPE;
        l_title_pain sys_message.desc_message%TYPE;
        l_compl_diag sys_message.desc_message%TYPE;
        l_compl_pain sys_message.desc_message%TYPE;
        l_info_adic  sys_message.desc_message%TYPE;
    
        --
        -- GET_EPIS_TYPE
        FUNCTION get_epis_type(i_episode IN epis_diagnosis.id_episode%TYPE) RETURN episode.id_epis_type%TYPE IS
            l_epis_type episode.id_epis_type%TYPE;
        
        BEGIN
            SELECT e.id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
        
            RETURN l_epis_type;
        END get_epis_type;
    
        -- GET_SURGERY
        FUNCTION get_surgery
        (
            i_lang      IN language.id_language%TYPE,
            i_prof      IN profissional,
            i_episode   IN sr_surgery_record.id_episode%TYPE,
            o_desc_type OUT VARCHAR2,
            o_desc      OUT VARCHAR2
        ) RETURN BOOLEAN IS
            epi_status episode.flg_status%TYPE;
        
        BEGIN
            SELECT e.flg_status
              INTO epi_status
              FROM episode e
             WHERE e.id_episode = i_episode;
        
            CASE
                WHEN epi_status = pk_alert_constant.g_epis_status_active THEN
                    o_desc_type := pk_message.get_message(i_lang => i_lang, i_code_mess => c_scheduled_surgery_mess);
                
                WHEN epi_status IN (pk_alert_constant.g_epis_status_inactive, pk_alert_constant.g_epis_status_pendent) THEN
                    o_desc_type := pk_message.get_message(i_lang => i_lang, i_code_mess => c_complete_surgery_mess);
                
                ELSE
                    RAISE no_data_found;
                
            END CASE;
        
            o_desc := pk_sr_clinical_info.get_proposed_surgery(i_lang    => i_lang,
                                                               i_episode => i_episode,
                                                               i_prof    => i_prof);
        
            RETURN TRUE;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_desc_type := NULL;
                o_desc      := NULL;
                RETURN FALSE;
            
        END get_surgery;
    
        --
    
    BEGIN
        l_message   := 'GET_EPIS_TYPE';
        l_epis_type := get_epis_type(i_episode => i_episode);
    
        CASE
        ---------------------------------------------------------
            WHEN l_epis_type = pk_alert_constant.g_epis_type_operating THEN
                IF get_surgery(i_lang      => i_lang,
                               i_prof      => i_prof,
                               i_episode   => i_episode,
                               o_desc_type => o_desc_type,
                               o_desc      => o_desc)
                THEN
                    RETURN TRUE;
                END IF;
            
        ---------------------------------------------------------
            ELSE
                l_message := 'CALL TO SET_COMP_DIAG';
                pk_hea_prv_aux.set_comp_diag(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_episode,
                                             i_call_type  => pk_hea_prv_aux.g_call_header_rep,
                                             o_title_diag => l_title_diag,
                                             o_compl_diag => l_compl_diag,
                                             o_title_pain => l_title_pain,
                                             o_compl_pain => l_compl_pain,
                                             o_info_adic  => l_info_adic);
            
                IF l_compl_diag IS NOT NULL
                THEN
                    o_desc      := l_compl_diag;
                    o_desc_type := l_title_diag;
                ELSE
                    o_desc      := l_compl_pain;
                    o_desc_type := l_title_pain;
                
                END IF;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            o_desc_type := NULL;
            o_desc      := NULL;
            RETURN FALSE;
        
    END get_report_header;

    --
    FUNCTION get_prof_presc_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        o_inst_info       OUT pk_types.cursor_type,
        o_prof_info       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_PROF_INST_PRESC_INFO';
        l_message             debug_msg;
        l_prescriber_category prof_accounts.value%TYPE;
    
        TYPE t_inst_info IS RECORD(
            address      institution.address%TYPE,
            location     institution.location%TYPE,
            district     institution.district%TYPE,
            zip_code     institution.zip_code%TYPE,
            phone_number institution.phone_number%TYPE,
            ext_code     institution.ext_code%TYPE,
            fax_number   institution.fax_number%TYPE,
            pct_name     institution_accounts.value%TYPE,
            pct_code     institution_accounts.value%TYPE,
            zi_code      institution_accounts.value%TYPE,
            inst_name    pk_translation.t_desc_translation,
            inst_mail    inst_attributes.email%TYPE,
            inst_cnes    institution_accounts.value%TYPE,
            inst_ufed    institution_accounts.value%TYPE,
            inst_ibge    institution_accounts.value%TYPE,
            inst_aprog   institution_accounts.value%TYPE,
            inst_juris   institution_accounts.value%TYPE);
    
        TYPE t_prof_info IS RECORD(
            name                   professional.name%TYPE,
            pin                    professional.num_order%TYPE,
            prescriber_type        prof_accounts.value%TYPE,
            npi                    prof_accounts.value%TYPE,
            agb_code               institution_accounts.value%TYPE,
            dea                    professional.dea%TYPE,
            num_order              professional.num_order%TYPE,
            upin                   professional.upin%TYPE,
            rut                    prof_accounts.value%TYPE,
            prof_specialty         pk_translation.t_desc_translation,
            am_num                 prof_accounts.value%TYPE,
            cab_id                 prof_accounts.value%TYPE,
            conv_id                prof_accounts.value%TYPE,
            zisd                   prof_accounts.value%TYPE,
            zik                    prof_accounts.value%TYPE,
            spec                   prof_accounts.value%TYPE,
            conv_level             prof_accounts.value%TYPE,
            ment_admin             prof_accounts.value%TYPE,
            adr_cnt_info           prof_accounts.value%TYPE,
            ment_medic             prof_accounts.value%TYPE,
            title                  sys_domain.val%TYPE,
            prof_adress            professional.address%TYPE,
            prof_state             professional.district%TYPE,
            prof_city              professional.city%TYPE,
            prof_zip               professional.zip_code%TYPE,
            prof_country           pk_translation.t_desc_translation,
            prof_phone_off         professional.work_phone%TYPE,
            prof_phone_home        professional.num_contact%TYPE,
            prof_cellphone         professional.cell_phone%TYPE,
            prof_fax               professional.fax%TYPE,
            prof_mail              professional.email%TYPE,
            cbo                    prof_accounts.value%TYPE,
            prof_rfc               prof_accounts.value%TYPE,
            bleep_number           professional.bleep_number%TYPE,
            tin                    professional.taxpayer_number%TYPE,
            clinical_name          professional.clinical_name%TYPE,
            agrupacion_institution VARCHAR2(300 CHAR),
            agrupacion_abbr        VARCHAR2(50 CHAR),
            scholarship            VARCHAR2(200 CHAR));
    
        rec_inst_info t_inst_info;
        rec_prof_info t_prof_info;
    
        c_npi                CONSTANT accounts.id_account%TYPE := 1;
        c_agb_code           CONSTANT accounts.id_account%TYPE := 13;
        c_id_pct_name        CONSTANT accounts.id_account%TYPE := 14;
        c_id_pct_code        CONSTANT accounts.id_account%TYPE := 15;
        c_id_prescriber_type CONSTANT accounts.id_account%TYPE := 16;
        c_zi_code            CONSTANT accounts.id_account%TYPE := 17;
        c_prescriber_rut     CONSTANT accounts.id_account%TYPE := 61;
        c_cnes               CONSTANT accounts.id_account%TYPE := 55;
        c_ibge               CONSTANT accounts.id_account%TYPE := 54;
        c_ufed               CONSTANT accounts.id_account%TYPE := 53;
        c_aprog              CONSTANT accounts.id_account%TYPE := 57;
        c_cbo                CONSTANT accounts.id_account%TYPE := 55;
        c_rfc                CONSTANT accounts.id_account%TYPE := 82;
        c_prescriber_cat     CONSTANT accounts.id_account%TYPE := 19;
    
        -- FR
        c_prescriber_am       CONSTANT accounts.id_account%TYPE := 68;
        c_prescriber_cab      CONSTANT accounts.id_account%TYPE := 69;
        c_prescriber_conv_lvl CONSTANT accounts.id_account%TYPE := 70;
        c_prescriber_cnt_adr  CONSTANT accounts.id_account%TYPE := 72;
        c_prescriber_ment1    CONSTANT accounts.id_account%TYPE := 71;
        c_prescriber_ment2    CONSTANT accounts.id_account%TYPE := 73;
        c_prescriber_conv     CONSTANT accounts.id_account%TYPE := 74;
        c_prescriber_zisd     CONSTANT accounts.id_account%TYPE := 75;
        c_prescriber_zik      CONSTANT accounts.id_account%TYPE := 76;
        c_prescriber_spec     CONSTANT accounts.id_account%TYPE := 77;
        c_prescriber_juris    CONSTANT accounts.id_account%TYPE := 83;
    
        c_multichoice      CONSTANT accounts.fill_type%TYPE := 'M';
        c_multimultichoice CONSTANT accounts.fill_type%TYPE := 'MM';
    
        l_prof profissional;
    
        FUNCTION get_affiliate_value
        (
            i_lang    IN language.id_language%TYPE,
            i_account IN accounts.id_account%TYPE,
            i_value   IN institution_accounts.value%TYPE
        ) RETURN VARCHAR2 IS
            l_value VARCHAR2(1000 CHAR);
        
        BEGIN
            BEGIN
                SELECT decode(a.fill_type,
                              c_multichoice,
                              pk_sysdomain.get_domain(a.sys_domain_identifier, i_value, i_lang),
                              c_multimultichoice,
                              nvl(pk_backoffice.get_domain_desc_str(a.sys_domain_identifier, i_value, i_lang), NULL),
                              i_value)
                  INTO l_value
                  FROM accounts a
                 WHERE a.id_account = i_account;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_value := NULL;
                
            END;
        
            RETURN l_value;
        
        END get_affiliate_value;
    
        FUNCTION get_inst_affiliate_value
        (
            i_lang        IN language.id_language%TYPE,
            i_account     IN accounts.id_account%TYPE,
            i_institution IN institution.id_institution%TYPE
        ) RETURN VARCHAR2 IS
            l_value VARCHAR2(1000 CHAR);
        
        BEGIN
            BEGIN
                SELECT ia.value
                  INTO l_value
                  FROM institution_accounts ia
                 WHERE ia.id_account = i_account
                   AND ia.id_institution = i_institution;
            
                l_value := get_affiliate_value(i_lang => i_lang, i_account => i_account, i_value => l_value);
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_value := NULL;
                
            END;
        
            RETURN l_value;
        
        END get_inst_affiliate_value;
    
        FUNCTION get_prof_affiliate_value
        (
            i_lang    IN language.id_language%TYPE,
            i_account IN accounts.id_account%TYPE,
            i_prof    IN profissional
        ) RETURN VARCHAR2 IS
            l_flg_institution accounts_category.flg_institution%TYPE;
            l_value           VARCHAR2(1000 CHAR);
        
        BEGIN
            BEGIN
                SELECT ac.flg_institution
                  INTO l_flg_institution
                  FROM accounts_category ac
                 WHERE ac.id_account = i_account
                   AND ac.id_category = pk_prof_utils.get_id_category(i_lang, i_prof);
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_flg_institution := pk_alert_constant.g_no;
                
            END;
        
            BEGIN
                SELECT pa.value
                  INTO l_value
                  FROM prof_accounts pa
                 WHERE pa.id_account = i_account
                   AND pa.id_professional = i_prof.id
                   AND pa.id_institution = decode(l_flg_institution,
                                                  pk_alert_constant.g_yes,
                                                  i_prof.institution,
                                                  pk_alert_constant.g_inst_all);
            
                l_value := get_affiliate_value(i_lang => i_lang, i_account => i_account, i_value => l_value);
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_value := NULL;
                
            END;
        
            RETURN l_value;
        
        END get_prof_affiliate_value;
    
    BEGIN
        l_message := 'GET INSTITUTION ADDRESS AND PHONE';
    
        l_prof := i_prof;
        IF i_id_professional IS NOT NULL
        THEN
            l_prof.id := i_id_professional;
        END IF;
    
        SELECT i.address,
               i.location,
               i.district,
               i.zip_code,
               i.phone_number,
               i.ext_code,
               i.fax_number,
               pk_translation.get_translation(i_lang, i.code_institution) AS inst_name,
               (SELECT ia.email
                  FROM inst_attributes ia
                 WHERE ia.id_institution = i.id_institution
                   AND ia.flg_available = pk_alert_constant.g_yes) inst_email
          INTO rec_inst_info.address,
               rec_inst_info.location,
               rec_inst_info.district,
               rec_inst_info.zip_code,
               rec_inst_info.phone_number,
               rec_inst_info.ext_code,
               rec_inst_info.fax_number,
               rec_inst_info.inst_name,
               rec_inst_info.inst_mail
          FROM institution i
         WHERE id_institution = l_prof.institution;
    
        l_message              := 'GET INSTITUTION AFFILIATION - CPT_NAME';
        rec_inst_info.pct_name := get_inst_affiliate_value(i_lang        => i_lang,
                                                           i_account     => c_id_pct_name,
                                                           i_institution => l_prof.institution);
    
        l_message              := 'GET INSTITUTION AFFILIATION - CPT_CODE';
        rec_inst_info.pct_code := get_inst_affiliate_value(i_lang        => i_lang,
                                                           i_account     => c_id_pct_code,
                                                           i_institution => l_prof.institution);
    
        l_message         := 'GET PROFESSIONAL AFFILIATION - RUT';
        rec_prof_info.rut := get_prof_affiliate_value(i_lang => i_lang, i_account => c_prescriber_rut, i_prof => l_prof);
    
        l_message         := 'GET NATIONAL PROVIDER IDENTITY - NPI';
        rec_prof_info.npi := get_prof_affiliate_value(i_lang => i_lang, i_account => c_npi, i_prof => l_prof);
    
        l_message              := 'GET INSTITUTION AFFILIATION - CPT_CODE';
        rec_prof_info.agb_code := get_prof_affiliate_value(i_lang => i_lang, i_account => c_agb_code, i_prof => l_prof);
    
        l_message := 'CALL pk_api_backoffice.get_prof_prescriber_cat';
        IF NOT pk_api_backoffice.get_prof_prescriber_cat(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         o_prescriber_cat => l_prescriber_category,
                                                         o_error          => o_error)
        THEN
            l_prescriber_category := NULL;
        END IF;
    
        l_message             := 'GET INSTITUTION AFFILIATION - CPT_CODE';
        rec_inst_info.zi_code := get_inst_affiliate_value(i_lang        => i_lang,
                                                          i_account     => c_zi_code,
                                                          i_institution => l_prof.institution);
    
        l_message               := 'GET INSTITUTION CNES';
        rec_inst_info.inst_cnes := get_inst_affiliate_value(i_lang        => i_lang,
                                                            i_account     => c_cnes,
                                                            i_institution => l_prof.institution);
    
        l_message                := 'GET INSTITUTION UF';
        rec_inst_info.inst_ufed  := get_inst_affiliate_value(i_lang        => i_lang,
                                                             i_account     => c_ufed,
                                                             i_institution => l_prof.institution);
        l_message                := 'GET INSTITUTION IBGE';
        rec_inst_info.inst_ibge  := get_inst_affiliate_value(i_lang        => i_lang,
                                                             i_account     => c_ibge,
                                                             i_institution => l_prof.institution);
        l_message                := 'GET INSTITUTION AP';
        rec_inst_info.inst_aprog := get_inst_affiliate_value(i_lang        => i_lang,
                                                             i_account     => c_aprog,
                                                             i_institution => l_prof.institution);
    
        l_message                := 'GET INSTITUTION Jurisdiccion';
        rec_inst_info.inst_juris := get_inst_affiliate_value(i_lang        => i_lang,
                                                             i_account     => c_prescriber_juris,
                                                             i_institution => l_prof.institution);
        --
    
        l_message          := 'GET PROFESSIONAL NAME';
        rec_prof_info.name := pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                               i_prof    => l_prof,
                                                               i_prof_id => l_prof.id);
    
        l_message := 'GET PROFESSIONAL PIN (NUM ORDER)';
        IF NOT pk_prof_utils.get_num_order(i_lang      => i_lang,
                                           i_prof      => l_prof,
                                           i_prof_id   => l_prof.id,
                                           o_num_order => rec_prof_info.pin,
                                           o_error     => o_error)
        THEN
            pk_alert_exceptions.raise_error(error_code_in => o_error.ora_sqlcode, text_in => o_error.ora_sqlerrm);
        END IF;
    
        l_message                     := 'GET PROFESSIONAL PRESCRIBER TYPE';
        rec_prof_info.prescriber_type := get_prof_affiliate_value(i_lang    => i_lang,
                                                                  i_account => c_id_prescriber_type,
                                                                  i_prof    => l_prof);
    
        l_message                    := 'GET PROFESSIONAL SPECIALTY';
        rec_prof_info.prof_specialty := pk_prof_utils.get_prof_speciality(i_lang => i_lang, i_prof => l_prof);
    
        l_message := 'GET PROFESSIONAL NUM ORDER';
        IF NOT pk_prof_utils.get_num_order(i_lang      => i_lang,
                                           i_prof      => l_prof,
                                           i_prof_id   => l_prof.id,
                                           o_num_order => rec_prof_info.num_order,
                                           o_error     => o_error)
        THEN
            pk_alert_exceptions.raise_error(error_code_in => o_error.ora_sqlcode, text_in => o_error.ora_sqlerrm);
        END IF;
    
        l_message := 'GET PROFESSIONAL DEA';
        IF NOT pk_prof_utils.get_dea(i_lang    => i_lang,
                                     i_prof    => l_prof,
                                     i_prof_id => l_prof.id,
                                     o_dea     => rec_prof_info.dea,
                                     o_error   => o_error)
        THEN
            pk_alert_exceptions.raise_error(error_code_in => o_error.ora_sqlcode, text_in => o_error.ora_sqlerrm);
        END IF;
    
        l_message := 'GET PROFESSIONAL UPIN';
        IF NOT pk_prof_utils.get_upin(i_lang    => i_lang,
                                      i_prof    => l_prof,
                                      i_prof_id => l_prof.id,
                                      o_upin    => rec_prof_info.upin,
                                      o_error   => o_error)
        THEN
            pk_alert_exceptions.raise_error(error_code_in => o_error.ora_sqlcode, text_in => o_error.ora_sqlerrm);
        END IF;
    
        l_message                  := 'GET PROFESSIONAL Bleep Number';
        rec_prof_info.bleep_number := pk_prof_utils.get_bleep_num(i_lang    => i_lang,
                                                                  i_prof    => l_prof,
                                                                  i_prof_id => l_prof.id);
    
        l_message         := 'GET PROFESSIONAL CBO';
        rec_prof_info.cbo := get_prof_affiliate_value(i_lang => i_lang, i_account => c_cbo, i_prof => l_prof);
    
        -- FR
        l_message                  := 'GET PROFESSIONAL AFFILIATION - AM ID';
        rec_prof_info.am_num       := get_prof_affiliate_value(i_lang    => i_lang,
                                                               i_account => c_prescriber_am,
                                                               i_prof    => l_prof);
        l_message                  := 'GET PROFESSIONAL AFFILIATION - CAB ID';
        rec_prof_info.cab_id       := get_prof_affiliate_value(i_lang    => i_lang,
                                                               i_account => c_prescriber_cab,
                                                               i_prof    => l_prof);
        l_message                  := 'GET PROFESSIONAL AFFILIATION - CONV ID';
        rec_prof_info.conv_id      := get_prof_affiliate_value(i_lang    => i_lang,
                                                               i_account => c_prescriber_conv,
                                                               i_prof    => l_prof);
        l_message                  := 'GET PROFESSIONAL AFFILIATION - ZISD ID';
        rec_prof_info.zisd         := get_prof_affiliate_value(i_lang    => i_lang,
                                                               i_account => c_prescriber_zisd,
                                                               i_prof    => l_prof);
        l_message                  := 'GET PROFESSIONAL AFFILIATION - ZIK ID';
        rec_prof_info.zik          := get_prof_affiliate_value(i_lang    => i_lang,
                                                               i_account => c_prescriber_zik,
                                                               i_prof    => l_prof);
        l_message                  := 'GET PROFESSIONAL AFFILIATION - SPEC ID';
        rec_prof_info.spec         := get_prof_affiliate_value(i_lang    => i_lang,
                                                               i_account => c_prescriber_spec,
                                                               i_prof    => l_prof);
        l_message                  := 'GET PROFESSIONAL AFFILIATION - CONVENTION LEVEL';
        rec_prof_info.conv_level   := get_prof_affiliate_value(i_lang    => i_lang,
                                                               i_account => c_prescriber_conv_lvl,
                                                               i_prof    => l_prof);
        l_message                  := 'GET PROFESSIONAL AFFILIATION - ADMINISTRATIVE MENTIONS';
        rec_prof_info.ment_admin   := get_prof_affiliate_value(i_lang    => i_lang,
                                                               i_account => c_prescriber_ment1,
                                                               i_prof    => l_prof);
        l_message                  := 'GET PROFESSIONAL AFFILIATION - LOCAL ADRESS AND CONTACT';
        rec_prof_info.adr_cnt_info := get_prof_affiliate_value(i_lang    => i_lang,
                                                               i_account => c_prescriber_cnt_adr,
                                                               i_prof    => l_prof);
        l_message                  := 'GET PROFESSIONAL AFFILIATION - MEDIC MENTIONS';
        rec_prof_info.ment_medic   := get_prof_affiliate_value(i_lang    => i_lang,
                                                               i_account => c_prescriber_ment2,
                                                               i_prof    => l_prof);
    
        l_message              := 'GET PROFESSIONAL AFFILIATION - MEDIC MENTIONS';
        rec_prof_info.prof_rfc := get_prof_affiliate_value(i_lang => i_lang, i_account => c_rfc, i_prof => l_prof);
    
        l_message              := 'GET PROFESSIONAL AFFILIATION - MEDIC MENTIONS';
        rec_prof_info.prof_rfc := get_prof_affiliate_value(i_lang => i_lang, i_account => c_rfc, i_prof => l_prof);
    
        IF NOT pk_prof_utils.get_prof_presc_details(i_lang,
                                                    l_prof,
                                                    rec_prof_info.title,
                                                    rec_prof_info.prof_adress,
                                                    rec_prof_info.prof_state,
                                                    rec_prof_info.prof_city,
                                                    rec_prof_info.prof_zip,
                                                    rec_prof_info.prof_country,
                                                    rec_prof_info.prof_phone_off,
                                                    rec_prof_info.prof_phone_home,
                                                    rec_prof_info.prof_cellphone,
                                                    rec_prof_info.prof_fax,
                                                    rec_prof_info.prof_mail,
                                                    rec_prof_info.tin,
                                                    rec_prof_info.clinical_name,
                                                    rec_prof_info.agrupacion_institution,
                                                    rec_prof_info.agrupacion_abbr,
                                                    rec_prof_info.scholarship,
                                                    o_error)
        THEN
            l_message := 'GET PROFESSIONAL DETAILS (ADRESS + CONTACTS) ';
            pk_alert_exceptions.raise_error(error_code_in => o_error.ora_sqlcode, text_in => o_error.ora_sqlerrm);
        END IF;
    
        --
    
        l_message := 'OPEN CURSOR O_INST_INFO';
        OPEN o_inst_info FOR
            SELECT rec_inst_info.address      AS address,
                   rec_inst_info.location     AS location,
                   rec_inst_info.district     AS district,
                   rec_inst_info.zip_code     AS zip_code,
                   rec_inst_info.phone_number AS phone_number,
                   rec_inst_info.ext_code     AS ext_code,
                   rec_inst_info.fax_number   AS fax_number,
                   rec_inst_info.pct_name     AS pct_name,
                   rec_inst_info.pct_code     AS pct_code,
                   rec_inst_info.zi_code      AS zi_code,
                   rec_inst_info.inst_name    AS inst_name,
                   rec_inst_info.inst_mail    AS email,
                   rec_inst_info.inst_cnes    AS inst_cnes,
                   rec_inst_info.inst_ufed    AS inst_ufed,
                   rec_inst_info.inst_ibge    AS inst_ibge,
                   rec_inst_info.inst_aprog   AS inst_aprog,
                   rec_inst_info.inst_juris   AS inst_juris
              FROM dual;
    
        l_message := 'OPEN CURSOR O_PROF_INFO';
        OPEN o_prof_info FOR
            SELECT rec_prof_info.name                   AS name,
                   rec_prof_info.pin                    AS pin,
                   rec_prof_info.npi                    AS npi,
                   rec_prof_info.prescriber_type        AS prescriber_type,
                   rec_prof_info.agb_code               AS agb_code,
                   rec_prof_info.num_order              AS num_order,
                   rec_prof_info.dea                    AS dea,
                   rec_prof_info.upin                   AS upin,
                   rec_prof_info.rut                    AS rut,
                   rec_prof_info.prof_specialty         AS prof_specialty,
                   rec_prof_info.am_num                 AS am,
                   rec_prof_info.cab_id                 AS cab,
                   rec_prof_info.conv_id                AS conv,
                   rec_prof_info.zisd                   AS zisd,
                   rec_prof_info.zik                    AS zik,
                   rec_prof_info.spec                   AS spec,
                   rec_prof_info.conv_level             AS conv_lvl,
                   rec_prof_info.ment_admin             AS admin_ment,
                   rec_prof_info.adr_cnt_info           AS local_cnt_adr,
                   rec_prof_info.ment_medic             AS medic_mention,
                   rec_prof_info.title                  AS title,
                   rec_prof_info.prof_adress            AS adress,
                   rec_prof_info.prof_state             AS state,
                   rec_prof_info.prof_city              AS city,
                   rec_prof_info.prof_zip               AS zip,
                   rec_prof_info.prof_country           AS country,
                   rec_prof_info.prof_phone_off         AS phone_off,
                   rec_prof_info.prof_phone_home        AS phone_home,
                   rec_prof_info.prof_cellphone         AS cellphone,
                   rec_prof_info.prof_fax               AS fax,
                   rec_prof_info.prof_mail              AS email,
                   rec_prof_info.cbo                    AS occupation,
                   rec_prof_info.prof_rfc               AS rfc,
                   rec_prof_info.bleep_number           AS bleep_number,
                   l_prescriber_category                AS prescriber_category,
                   rec_prof_info.tin                    AS taxpayer_number,
                   rec_prof_info.clinical_name          AS clinical_name,
                   rec_prof_info.agrupacion_institution AS agrupacion_institution,
                   rec_prof_info.agrupacion_abbr        AS agrupacion_abbr,
                   rec_prof_info.scholarship            AS scholarship
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_inst_info);
            pk_types.open_my_cursor(i_cursor => o_prof_info);
            RETURN FALSE;
        
    END get_prof_presc_info;

    FUNCTION get_institution_img_logo
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_inst_logo OUT institution_logo.img_logo%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_dep_clin_serv NUMBER;
        c_function_name CONSTANT obj_name := 'GET_INSTITUTION_IMG_LOGO';
        l_message debug_msg;
    
    BEGIN
    
        l_message := 'GET ID_DEP_CLIN_SERV FOR EPISODE';
        pk_alertlog.log_debug(l_message);
    
        BEGIN
            IF i_episode IS NOT NULL
            THEN
                SELECT ei.id_dep_clin_serv
                  INTO l_id_dep_clin_serv
                  FROM epis_info ei
                 WHERE ei.id_episode = i_episode;
            
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_id_dep_clin_serv := NULL;
            
        END;
    
        BEGIN
            SELECT il.img_logo
              INTO o_inst_logo
              FROM institution i
              JOIN institution_logo il
                ON i.id_institution = il.id_institution
             WHERE i.id_institution = i_prof.institution
               AND (il.id_dep_clin_serv = l_id_dep_clin_serv OR il.id_dep_clin_serv IS NULL)
               AND rownum = 1
             ORDER BY il.id_dep_clin_serv ASC;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_inst_logo := NULL;
            
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_institution_img_logo;

    FUNCTION get_institution_img_banners
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        o_inst_logo           OUT institution_logo.img_logo%TYPE,
        o_inst_banner         OUT institution_logo.img_banner%TYPE,
        o_inst_banner_small   OUT institution_logo.img_banner_small%TYPE,
        o_inst_name           OUT VARCHAR2,
        o_id_institution_logo OUT institution_logo.id_institution_logo%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_dep_clin_serv NUMBER;
        c_function_name CONSTANT obj_name := 'GET_INSTITUTION_IMG_BANNERS';
        l_message        debug_msg;
        l_id_institution NUMBER;
    
    BEGIN
    
        l_message := 'GET ID_DEP_CLIN_SERV FOR EPISODE';
        pk_alertlog.log_debug(l_message);
    
        BEGIN
            IF i_episode IS NOT NULL
            THEN
                SELECT ei.id_dep_clin_serv
                  INTO l_id_dep_clin_serv
                  FROM epis_info ei
                 WHERE ei.id_episode = i_episode;
            
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_id_dep_clin_serv := NULL;
            
        END;
    
        IF i_episode IS NOT NULL
        THEN
            SELECT e.id_institution
              INTO l_id_institution
              FROM episode e
             WHERE e.id_episode = i_episode;
        END IF;
    
        IF l_id_institution IS NULL
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        BEGIN
            SELECT inst_name, img_logo, img_banner, img_banner_small, id_institution_logo
              INTO o_inst_name, o_inst_logo, o_inst_banner, o_inst_banner_small, o_id_institution_logo
              FROM (SELECT pk_translation.get_translation(i_lang, i.code_institution) inst_name,
                           il.img_logo,
                           il.img_banner,
                           il.img_banner_small,
                           il.id_institution_logo
                      FROM institution i
                      LEFT JOIN institution_logo il
                        ON i.id_institution = il.id_institution
                     WHERE i.id_institution = l_id_institution
                       AND (il.id_dep_clin_serv = l_id_dep_clin_serv OR il.id_dep_clin_serv IS NULL)
                     ORDER BY il.id_dep_clin_serv NULLS LAST)
             WHERE rownum = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_inst_logo         := pk_tech_utils.set_empty_blob(o_inst_logo);
                o_inst_banner       := pk_tech_utils.set_empty_blob(o_inst_banner);
                o_inst_banner_small := pk_tech_utils.set_empty_blob(o_inst_banner_small);
                o_inst_name         := NULL;
            
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_institution_img_banners;

    FUNCTION get_epis_report
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_id_epis_report               IN epis_report.id_epis_report%TYPE,
        o_epis_report                  OUT pk_types.cursor_type,
        o_rep_binary_file              OUT BLOB,
        o_signed_binary_file           OUT BLOB,
        o_temporary_signed_binary_file OUT BLOB,
        o_epis_report_thumbnail        OUT BLOB,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
        CURSOR c_blobs IS
            SELECT rep_binary_file, signed_binary_file, temporary_signed_binary_file, epis_report_thumbnail
              FROM epis_report er
             WHERE er.id_epis_report = i_id_epis_report;
    
    BEGIN
        l_message := 'Open cursor';
        OPEN o_epis_report FOR
            SELECT id_epis_report,
                   id_reports,
                   id_episode,
                   id_professional,
                   adw_last_update,
                   flg_status,
                   flg_edit,
                   dt_creation_tstz,
                   id_audit_req_prof_epis,
                   id_audit_req_prof,
                   id_reports_gen_param,
                   flg_signed,
                   id_social_episode,
                   id_patient,
                   id_external_request,
                   id_visit,
                   dig_sig_type,
                   id_audit_req,
                   flg_confidential,
                   id_doc_external
              FROM epis_report er
             WHERE er.id_epis_report = i_id_epis_report;
    
        OPEN c_blobs;
        FETCH c_blobs
            INTO o_rep_binary_file, o_signed_binary_file, o_temporary_signed_binary_file, o_epis_report_thumbnail;
        CLOSE c_blobs;
    
        o_rep_binary_file              := pk_tech_utils.set_empty_blob(o_rep_binary_file);
        o_signed_binary_file           := pk_tech_utils.set_empty_blob(o_signed_binary_file);
        o_temporary_signed_binary_file := pk_tech_utils.set_empty_blob(o_temporary_signed_binary_file);
        o_epis_report_thumbnail        := pk_tech_utils.set_empty_blob(o_epis_report_thumbnail);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EPIS_REPORT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_epis_report);
            RETURN FALSE;
        
    END get_epis_report;

    FUNCTION set_epis_report_thumbnail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_report        IN epis_report.id_epis_report%TYPE,
        i_epis_report_thumbnail IN epis_report.epis_report_thumbnail%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'update epis_report';
        UPDATE epis_report er
           SET er.epis_report_thumbnail = i_epis_report_thumbnail
         WHERE er.id_epis_report = i_id_epis_report;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_EPIS_REPORT_THUMBNAIL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_epis_report_thumbnail;

    /**
    * Verifica se um relat�rio � para ser gerado localmente ou remotamente
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Professional
    * @param i_id_reports                    Report ID
    *
    * @return                                Report will be generated in local instance (TRUE) or remote instance (FALSE)
    *
    * @author                                Tiago Louren�o
    * @version                               2.6.1
    * @since                                 1-Feb-2011
    */

    FUNCTION is_local_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_reports IN reports.id_reports%TYPE
    ) RETURN BOOLEAN IS
        l_message   debug_msg;
        l_error     t_error_out;
        l_flg_local reports_inst_soft.flg_local%TYPE;
        -- By default the Report will be generated in the local instance
        o_flg_local BOOLEAN := TRUE;
    
    BEGIN
        l_message := 'GET FLG_LOCAL FROM REPORTS_INST_SOFT';
    
        SELECT flg_local
          INTO l_flg_local
          FROM reports_inst_soft ris
         WHERE ris.id_reports = i_id_reports
           AND ris.id_institution = i_prof.institution
           AND ris.id_software IN (i_prof.software, 0)
         ORDER BY ris.id_software DESC;
    
        IF l_flg_local != pk_alert_constant.g_yes
        THEN
            o_flg_local := FALSE;
        END IF;
    
        RETURN o_flg_local;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN o_flg_local;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_FLG_LOCAL',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN o_flg_local;
        
    END is_local_report;

    /**
    * Sets some metadata about the report.
    *
    * @param i_lang language id
    * @param i_prof professional type
    * @param i_epis_report generated report id
    * @param i_json_params service call params
    * @param i_elapsed_time elapsed time
    * @param o_error error message
    *
    * @return true (success), false (error)
    *
    * @author Gon�alo Almeida, 2011/Feb/04
    * @version 2.6.0.5
    * @since 2011/Feb/04
    */

    FUNCTION set_epis_report_metadata
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_report  IN epis_report.id_epis_report%TYPE,
        i_json_params  IN epis_report.json_params%TYPE,
        i_elapsed_time IN epis_report.elapsed_time%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'update epis_report';
        UPDATE epis_report er
           SET er.json_params = i_json_params, er.elapsed_time = i_elapsed_time
         WHERE er.id_epis_report = i_epis_report;
    
        g_error := 'ERROR CALLING PK_PRINT_TOOL.SET_EPIS_REPORT_DYNAMIC_CODE';
        IF NOT pk_print_tool.set_epis_report_dynamic_code(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_epis_report => i_epis_report,
                                                          i_json_params => i_json_params,
                                                          o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_EPIS_REPORT_METADATA',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_epis_report_metadata;

    /**
    * Sets some metadata about the report sections.
    *
    * @param i_lang language id
    * @param i_prof professional type
    * @param i_epis_report generated report id
    * @param i_id_rep_section table of section id
    * @param i_cardinality section table of records number
    * @param i_flg_scope table of section orientation
    * @param i_id_rep_layout table of section layout
    * @param i_elapsed_time table of elapsed time
    * @param i_java_time table of java time
    * @param i_database_time table of database time
    * @param i_remote_service_time table of remote service time
    * @param i_database_requests table of database requests
    * @param i_remote_service_requests table of remote service requests
    * @param i_jasper_time table of jasper time
    * @param o_error error message
    *
    * @return true (success), false (error)
    *
    * @author Jorge Matos, 2011/Jun/06
    * @version 2.6.1.1
    * @since 2011/Jun/06
    */

    FUNCTION set_epis_rep_sections_metadata
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_epis_report             IN epis_report_section.id_epis_report%TYPE,
        i_id_rep_section          IN table_number,
        i_cardinality             IN table_number,
        i_flg_scope               IN table_varchar,
        i_id_rep_layout           IN table_varchar,
        i_elapsed_time            IN table_number,
        i_java_time               IN table_number,
        i_database_time           IN table_number,
        i_remote_service_time     IN table_number,
        i_database_requests       IN table_number,
        i_remote_service_requests IN table_number,
        i_jasper_time             IN table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_error   t_error_out;
        e_user_exception EXCEPTION;
    
    BEGIN
        l_message := 'calling set_epis_rep_sections_metadata';
    
        FOR i IN 1 .. i_id_rep_section.count
        LOOP
            IF NOT pk_print_tool.set_epis_rep_section_metadata(i_lang                    => i_lang,
                                                               i_prof                    => i_prof,
                                                               i_epis_report             => i_epis_report,
                                                               i_id_rep_section          => i_id_rep_section(i),
                                                               i_cardinality             => i_cardinality(i),
                                                               i_flg_scope               => i_flg_scope(i),
                                                               i_id_rep_layout           => i_id_rep_layout(i),
                                                               i_elapsed_time            => i_elapsed_time(i),
                                                               i_java_time               => i_java_time(i),
                                                               i_database_time           => i_database_time(i),
                                                               i_remote_service_time     => i_remote_service_time(i),
                                                               i_database_requests       => i_database_requests(i),
                                                               i_remote_service_requests => i_remote_service_requests(i),
                                                               i_jasper_time             => i_jasper_time(i),
                                                               o_error                   => l_error)
            THEN
                o_error := l_error;
                RAISE e_user_exception;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_EPIS_REP_SECTIONS_METADATA',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_epis_rep_sections_metadata;

    /**
    * Sets some metadata about the report section.
    *
    * @param i_lang language id
    * @param i_prof professional type
    * @param i_epis_report generated report id
    * @param i_id_rep_section section id
    * @param i_cardinality section records number
    * @param i_flg_scope section orientation
    * @param i_id_rep_layout section layout
    * @param i_elapsed_time section layout
    * @param i_java_time java time
    * @param i_database_time database time
    * @param i_remote_service_time remote service time
    * @param i_database_requests database requests
    * @param i_remote_service_requests remote service requests
    * @param i_jasper_time jasper time
    * @param o_error error message
    *
    * @return true (success), false (error)
    *
    * @author Jorge Matos, 2011/Jun/06
    * @version 2.6.1.1
    * @since 2011/Jun/06
    */

    FUNCTION set_epis_rep_section_metadata
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_epis_report             IN epis_report_section.id_epis_report%TYPE,
        i_id_rep_section          IN epis_report_section.id_rep_section%TYPE,
        i_cardinality             IN epis_report_section.cardinality%TYPE,
        i_flg_scope               IN epis_report_section.flg_scope%TYPE,
        i_id_rep_layout           IN epis_report_section.id_rep_layout%TYPE,
        i_elapsed_time            IN epis_report_section.elapsed_time%TYPE,
        i_java_time               IN epis_report_section.java_time%TYPE,
        i_database_time           IN epis_report_section.database_time%TYPE,
        i_remote_service_time     IN epis_report_section.remote_service_time%TYPE,
        i_database_requests       IN epis_report_section.database_requests%TYPE,
        i_remote_service_requests IN epis_report_section.remote_service_requests%TYPE,
        i_jasper_time             IN epis_report_section.jasper_time%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'update epis_report_section';
        UPDATE epis_report_section ers
           SET ers.cardinality             = i_cardinality,
               ers.flg_scope               = i_flg_scope,
               ers.id_rep_layout           = i_id_rep_layout,
               ers.elapsed_time            = i_elapsed_time,
               ers.java_time               = i_java_time,
               ers.database_time           = i_database_time,
               ers.remote_service_time     = i_remote_service_time,
               ers.database_requests       = i_database_requests,
               ers.remote_service_requests = i_remote_service_requests,
               ers.jasper_time             = i_jasper_time
         WHERE ers.id_epis_report = i_epis_report
           AND ers.id_rep_section = i_id_rep_section;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_EPIS_REP_SECTION_METADATA',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_epis_rep_section_metadata;

    /**********************************************************************************************
    * GET_TIMEFRAME_SCREEN_REP        Returns necessary information for loading timeframe report screen
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param i_id_report              Report ID
    * @param o_title                  Returns the lable for current report
    * @param o_rep_options            Returns all information for available optins in this screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Lu�s Maia
    * @version                        2.6.0.5.1.4
    * @since                          07-Feb-2011
    **********************************************************************************************/

    FUNCTION get_timeframe_screen_rep
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_report   IN timeframe_rep.id_report%TYPE,
        o_title       OUT VARCHAR2,
        o_rep_options OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
        l_id_software          timefr_rep_grp_soft_inst.id_software%TYPE;
        l_id_institution       timefr_rep_grp_soft_inst.id_institution%TYPE;
        l_prof_id_market       market.id_market%TYPE;
        l_default_param        VARCHAR2(1);
        l_epis_dt_begin_str    VARCHAR2(200);
        l_sys_config_value     sys_config.value%TYPE;
        l_sys_config_def_value sys_config.value%TYPE;
    
        l_curr_min_date_trunc          VARCHAR2(4000);
        l_curr_min_date_last_week      VARCHAR2(4000);
        l_curr_max_date_next_four_days VARCHAR2(4000);
        l_curr_min_date_next_day       VARCHAR2(4000);
        l_curr_max_date_next_x_day     VARCHAR2(4000);
        l_curr_def_date_next_x_day     VARCHAR2(4000);
    
    BEGIN
    
        l_message := 'GET TIMEFRAME SCREEN TITLE';
        pk_alertlog.log_debug(l_message);
        SELECT pk_translation.get_translation(i_lang, tr.code_timeframe_title)
          INTO o_title
          FROM timeframe_rep tr
         WHERE tr.id_report = i_id_report;
    
        l_message := 'GET IF THERE ARE TIMEFRAME SCREEN LOCAL PARAMETRIZATIONS';
        pk_alertlog.log_debug(l_message);
        BEGIN
            SELECT local_param.id_software, local_param.id_institution
              INTO l_id_software, l_id_institution
              FROM (SELECT tri.*
                      FROM timefr_rep_grp_soft_inst tri
                     WHERE tri.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND tri.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND tri.flg_available = pk_alert_constant.g_yes
                     ORDER BY tri.id_software DESC, tri.id_institution DESC) local_param
             WHERE rownum = 1;
        
            l_default_param := pk_alert_constant.g_no;
        EXCEPTION
            WHEN no_data_found THEN
                l_default_param := pk_alert_constant.g_yes;
            
        END;
    
        IF l_default_param = pk_alert_constant.g_yes
        THEN
            l_message := 'GET PROFESSIONAL MARKET';
            pk_alertlog.log_debug(l_message);
            l_prof_id_market := pk_core.get_inst_mkt(i_prof.institution);
        
            IF i_id_episode IS NOT NULL
            THEN
            
                IF NOT pk_episode.get_epis_dt_begin(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_episode => i_id_episode,
                                                    o_dt_begin   => l_epis_dt_begin_str,
                                                    o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            ELSE
                l_epis_dt_begin_str := pk_date_utils.trunc_insttimezone_str(i_prof, current_timestamp, NULL);
            END IF;
        
            l_sys_config_value     := pk_sysconfig.get_config('REPORT_TIMEFRAME_MAX_DAYS_' || i_id_report, i_prof);
            l_sys_config_def_value := pk_sysconfig.get_config('REPORT_TIMEFRAME_DEFAULT_DAYS_' || i_id_report, i_prof);
            l_message              := 'CALL pk_date_utils.trunc_insttimezone_str ';
            pk_alertlog.log_debug(l_message);
            l_curr_min_date_trunc     := pk_date_utils.trunc_insttimezone_str(i_prof, current_timestamp, NULL);
            l_curr_min_date_last_week := pk_date_utils.trunc_insttimezone_str(i_prof, (current_timestamp - 7), NULL);
            l_curr_min_date_next_day  := pk_date_utils.trunc_insttimezone_str(i_prof, (current_timestamp + 1), NULL);
        
            l_curr_max_date_next_four_days := pk_date_utils.trunc_insttimezone_str(i_prof,
                                                                                   (pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                     current_timestamp,
                                                                                                                     'DD') +
                                                                                   numtodsinterval(5, 'DAY') -
                                                                                   numtodsinterval(1, 'MINUTE')),
                                                                                   'MI');
        
            IF l_sys_config_value IS NOT NULL
            THEN
                l_curr_max_date_next_x_day := pk_date_utils.trunc_insttimezone_str(i_prof,
                                                                                   (pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                     current_timestamp,
                                                                                                                     'DD') +
                                                                                   numtodsinterval(l_sys_config_value,
                                                                                                    'DAY') +
                                                                                   numtodsinterval(1, 'DAY') -
                                                                                   numtodsinterval(1, 'MINUTE')),
                                                                                   'MI');
            ELSE
                l_curr_max_date_next_x_day := pk_date_utils.trunc_insttimezone_str(i_prof, current_timestamp, 'MI');
            END IF;
        
            IF l_sys_config_def_value IS NOT NULL
            THEN
            
                l_curr_def_date_next_x_day := pk_date_utils.trunc_insttimezone_str(i_prof,
                                                                                   (pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                     current_timestamp,
                                                                                                                     'DD') +
                                                                                   numtodsinterval(l_sys_config_def_value,
                                                                                                    'DAY') +
                                                                                   numtodsinterval(1, 'DAY') -
                                                                                   numtodsinterval(1, 'MINUTE')),
                                                                                   'MI');
            
                IF l_sys_config_value IS NOT NULL
                THEN
                    l_curr_max_date_next_x_day := pk_date_utils.trunc_insttimezone_str(i_prof,
                                                                                       (pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                         current_timestamp,
                                                                                                                         'DD') +
                                                                                       numtodsinterval(l_sys_config_value,
                                                                                                        'DAY') +
                                                                                       numtodsinterval(1, 'DAY') -
                                                                                       numtodsinterval(1, 'MINUTE')),
                                                                                       'MI');
                END IF;
            ELSE
                l_curr_def_date_next_x_day := pk_date_utils.trunc_insttimezone_str(i_prof, current_timestamp, 'MI');
            END IF;
        
            l_message := 'GET TIMEFRAME SCREEN DEFAULT PARAMETRIZATIONS';
            pk_alertlog.log_debug(l_message);
            OPEN o_rep_options FOR
                SELECT tr.id_report,
                       tr.id_timeframe_rep,
                       tg.id_timeframe_group id_group,
                       pk_translation.get_translation(i_lang, tg.code_timeframe_rep_group) name_group,
                       tg.flg_type flg_type_group,
                       ton.id_timeframe_group id_option_parent,
                       ton.id_timeframe_option id_option,
                       pk_translation.get_translation(i_lang, ton.code_timeframe_rep_option) name_option,
                       ton.flg_type flg_type_option,
                       ton.flg_date_type flg_type_date,
                       decode(upper(ton.dt_begin_code),
                              'CURRENT_TIMESTAMP',
                              l_curr_min_date_trunc,
                              'EPIS_BEGIN',
                              l_epis_dt_begin_str,
                              'NEXT_DAY',
                              l_curr_min_date_next_day,
                              'LAST_WEEK',
                              l_curr_min_date_last_week,
                              'ALL_DATES',
                              NULL,
                              'TODAY_TILL_NOW',
                              l_curr_min_date_trunc,
                              pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof)) dt_begin,
                       decode(upper(ton.dt_end_code),
                              'CURRENT_TIMESTAMP',
                              l_curr_min_date_trunc,
                              'EPIS_BEGIN',
                              l_epis_dt_begin_str,
                              'NEXT_FOUR_DAYS',
                              l_curr_max_date_next_four_days,
                              'ALL_DATES',
                              NULL,
                              'NEXT_X_DAYS',
                              l_curr_max_date_next_x_day,
                              pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof)) dt_end,
                       decode(upper(ton.dt_default_code),
                              'CURRENT_TIMESTAMP',
                              l_curr_min_date_trunc,
                              'EPIS_BEGIN',
                              l_epis_dt_begin_str,
                              'NEXT_FOUR_DAYS',
                              l_curr_max_date_next_four_days,
                              'ALL_DATES',
                              NULL,
                              'NEXT_X_DAYS',
                              l_curr_def_date_next_x_day,
                              pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof)) dt_default,
                       decode(upper(ton.dt_begin_code),
                              'TODAY_TILL_NOW',
                              pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof),
                              NULL) dt_begin_max
                  FROM timeframe_rep tr
                 INNER JOIN timeframe_rep_grp_mkt trg
                    ON (trg.id_timeframe_rep = tr.id_timeframe_rep)
                 INNER JOIN timeframe_group tg
                    ON (tg.id_timeframe_group = trg.id_timeframe_group)
                 INNER JOIN timeframe_option ton
                    ON (ton.id_timeframe_group = tg.id_timeframe_group)
                 WHERE tr.id_report = i_id_report
                   AND tr.flg_available = pk_alert_constant.g_yes
                   AND trg.flg_available = pk_alert_constant.g_yes
                   AND trg.id_market IN (0, l_prof_id_market)
                 ORDER BY ton.rank ASC;
        
        ELSE
            l_message := 'GET TIMEFRAME SCREEN LOCAL PARAMETRIZATIONS';
            pk_alertlog.log_debug(l_message);
            OPEN o_rep_options FOR
                SELECT tr.id_report,
                       tr.id_timeframe_rep,
                       tg.id_timeframe_group id_group,
                       pk_translation.get_translation(i_lang, tg.code_timeframe_rep_group) name_group,
                       tg.flg_type flg_type_group,
                       ton.id_timeframe_group id_option_parent,
                       ton.id_timeframe_option id_option,
                       pk_translation.get_translation(i_lang, ton.code_timeframe_rep_option) name_option,
                       ton.flg_type flg_type_option,
                       ton.flg_date_type flg_type_date,
                       NULL dt_begin,
                       NULL dt_end,
                       NULL dt_default
                  FROM timeframe_rep tr
                 INNER JOIN timefr_rep_grp_soft_inst tri
                    ON (tri.id_timeframe_rep = tr.id_timeframe_rep)
                 INNER JOIN timeframe_group tg
                    ON (tg.id_timeframe_group = tri.id_timeframe_group)
                 INNER JOIN timeframe_option ton
                    ON (ton.id_timeframe_group = tg.id_timeframe_group)
                 WHERE tr.id_report = i_id_report
                   AND tr.flg_available = pk_alert_constant.g_yes
                   AND tri.flg_available = pk_alert_constant.g_yes
                   AND tri.id_institution = l_id_institution
                   AND tri.id_software = l_id_software
                 ORDER BY ton.rank ASC;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMEFRAME_SCREEN_REP',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_rep_options);
            RETURN FALSE;
        
    END get_timeframe_screen_rep;

    FUNCTION get_timeframe_screen_rep_option
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_report   IN timeframe_rep.id_report%TYPE,
        i_id_option   IN timeframe_option.id_timeframe_option%TYPE,
        i_param       IN VARCHAR2,
        o_option_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dummy                 pk_types.cursor_type;
        l_patient               patient.id_patient%TYPE;
        l_visit                 visit.id_visit%TYPE;
        c_list                  pk_types.cursor_type;
        l_tbl_lab_tests_results t_tbl_lab_tests_results;
        l_flg_type              sys_config.value%TYPE;
    BEGIN
    
        IF i_id_report = 601
        THEN
            IF i_id_option = 18
            THEN
                l_flg_type := pk_sysconfig.get_config('LAB_TESTS_RESULT_TABLE_DATE', i_prof);
                OPEN o_option_list FOR
                    SELECT /*+opt_estimate (table t rows=1)*/
                     t.desc_val label,
                     t.val id,
                     decode(t.val, l_flg_type, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
                      FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang          => i_lang,
                                                                          i_prof          => i_prof,
                                                                          i_code_dom      => 'LAB_TESTS_RESULT_TABLE_OPTIONS.DATE',
                                                                          i_dep_clin_serv => NULL)) t;
            ELSIF i_id_option = 19
            THEN
                IF i_id_episode IS NOT NULL
                THEN
                    l_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
                
                    l_visit := pk_visit.get_visit(i_episode => i_id_episode, o_error => o_error);
                END IF;
            
                IF NOT pk_lab_tests_core.get_lab_test_resultsview(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_patient          => l_patient,
                                                                  i_analysis_req_det => NULL,
                                                                  i_flg_type         => i_param,
                                                                  i_dt_min           => NULL,
                                                                  i_dt_max           => NULL,
                                                                  o_list             => l_tbl_lab_tests_results,
                                                                  o_error            => o_error)
                
                THEN
                    RAISE g_other_exception;
                END IF;
            
                OPEN o_option_list FOR
                    SELECT DISTINCT (id), label, pk_alert_constant.g_no flg_default
                      FROM (SELECT decode(upper(i_param), 'H', lb.dt_harvest, lb.dt_result) label,
                                   decode(upper(i_param), 'H', lb.dt_harvest_ord, lb.dt_result_ord) id
                              FROM TABLE(l_tbl_lab_tests_results) lb
                             WHERE (lb.dt_harvest IS NOT NULL AND upper(i_param) = 'H')
                                OR (lb.dt_result IS NOT NULL AND upper(i_param) <> 'H')) t
                     ORDER BY t.id DESC;
            END IF;
        
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
                                              'GET_TIMEFRAME_SCREEN_REP_OPTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_option_list);
            RETURN FALSE;
    END get_timeframe_screen_rep_option;

    /********************************************************************************************
    * Checks if profile template of the current logged user has access to disclosure reports
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Professional
    * @param i_screen_name                   Screen name
    * @param o_has_disc_report               Has at least one disclosure report?
    *
    * @value o_has_disc_report   {*} 'Y' Yes {*} 'N' No
    *
    * @return                Return TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               2.6.1
    * @since                 2011/02/10
    ***********************************************************************************************/

    FUNCTION check_disclosure_report
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_screen_name     IN rep_screen.screen_name%TYPE,
        i_flg_area_report IN rep_profile_template_det.flg_area_report%TYPE,
        o_has_disc_report OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CHECK_DISCLOSURE_REPORT';
        --
        l_dbg_msg debug_msg;
        --
        l_zero CONSTANT PLS_INTEGER := 0;
        l_tbl_rep_disc table_number := NULL;
    
    BEGIN
        l_dbg_msg := 'CALL PK_API_BACKOFFICE.GET_PROF_HAS_REP_DISCLOSURE';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
        l_tbl_rep_disc := pk_api_backoffice.get_prof_has_rep_disclosure(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_screen_name     => i_screen_name,
                                                                        i_flg_area_report => i_flg_area_report);
    
        IF l_tbl_rep_disc IS NOT NULL
           AND l_tbl_rep_disc.count > l_zero
        THEN
            o_has_disc_report := pk_alert_constant.g_yes;
        ELSE
            o_has_disc_report := pk_alert_constant.g_no;
        
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
    END check_disclosure_report;

    /********************************************************************************************
    * Returns the professional name used when creating a new disclosure report
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Professional
    * @param o_prof_name                     Professional name
    * @param o_error                         error message
    *
    * @return                Return TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               2.6.1
    * @since                 2011/02/10
    **********************************************************************************************/

    FUNCTION get_prof_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_name OUT professional.name%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PROF_NAME';
        --
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'CALL PK_PROF_UTILS.GET_NAME_SIGNATURE';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
        o_prof_name := pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => i_prof.id);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
    END get_prof_name;

    /********************************************************************************************
    * Returns the professional reports profile as defined on the REPORTS table rep_profile_template
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Professional
    * @param o_id_profile                    Professional reports profile ID
    *
    * @return                Return TRUE if sucess, FALSE otherwise
    *
    * @author                Jo�o Reis
    * @version               2.6.1.2
    * @since                 2011/07/21
    **********************************************************************************************/

    FUNCTION get_rep_prof_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_id_profile OUT rep_prof_template.id_rep_prof_template%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REP_PROF_ID';
    
        l_dbg_msg debug_msg;
    
    BEGIN
    
        l_dbg_msg := 'GET PROFILE ID FROM REP_PROF_TEMPLATE TABLE';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
    
        SELECT id_rep_profile_template
          INTO o_id_profile
          FROM (SELECT rpta.id_rep_profile_template
                  FROM rep_prof_templ_access rpta
                 INNER JOIN prof_profile_template ppt
                    ON ppt.id_profile_template = rpta.id_profile_template
                   AND rpta.id_profile_template = ppt.id_profile_template
                   AND ppt.id_professional IN (0, i_prof.id)
                   AND ppt.id_institution IN (0, i_prof.institution)
                   AND ppt.id_software = i_prof.software
                 ORDER BY ppt.id_professional DESC, ppt.id_institution DESC)
         WHERE rownum < 2;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
    END get_rep_prof_id;

    /********************************************************************************************
    * Returns the disclosure print icon or sys_domain icon correspondent to the current status
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Professional
    * @param i_epis_report                   Epis report id
    * @param i_val                           Epis report status flag value
    *
    * @return                Name of the icon
    *
    * @author                Alexandre Santos
    * @version               2.6.1
    * @since                 2011/02/10
    **********************************************************************************************/

    FUNCTION get_icon
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_report IN epis_report.id_epis_report%TYPE,
        i_val         IN sys_domain.val%TYPE
    ) RETURN sys_domain.img_name%TYPE IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ICON';
        --
        l_disclosure_print_icon CONSTANT sys_domain.img_name%TYPE := 'DisclosurePrintIcon';
        l_zero                  CONSTANT PLS_INTEGER := 0;
        l_er_flg_status_i       CONSTANT epis_report.flg_status%TYPE := 'I';
        --
        l_dbg_msg   debug_msg;
        l_count     PLS_INTEGER;
        l_icon_name sys_domain.img_name%TYPE;
    
    BEGIN
        l_dbg_msg := 'VERIFY IF ID_EPIS_REPORT: ' || i_epis_report || ' IS A DISCLOSURE REPORT';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT COUNT(*)
          INTO l_count
          FROM epis_report_disclosure erd
         WHERE erd.id_epis_report = i_epis_report;
    
        l_dbg_msg := 'IF IT IS THEN VERIFY IF EPIS_REPORT STATUS IS EQUAL TO ''I''. FLG_STATUS: ' || i_val || ';';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
        IF l_count > l_zero
           AND i_val = l_er_flg_status_i
        THEN
            l_icon_name := l_disclosure_print_icon;
        ELSE
            l_icon_name := pk_sysdomain.get_img(i_lang => i_lang, i_code_dom => c_epis_report_domain, i_val => i_val);
        
        END IF;
    
        RETURN l_icon_name;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_icon;

    /********************************************************************************************
     * Gets the list of selected sections for a specific epis_report
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_epis_reports           Epis Report ID
     *
     * @param o_section                List of selected sections
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Alexandre Santos
     * @version                         2.6
     * @since                           2011/02/15
    **********************************************************************************************/

    FUNCTION get_epis_rep_section_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_reports IN epis_report_section.id_epis_report%TYPE,
        o_section      OUT pk_print_tool.p_rep_section_cur,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EPIS_REP_SECTION_LIST';
        --
        l_one CONSTANT PLS_INTEGER := '1';
        --
        l_dbg_msg debug_msg;
        --
        l_reports rep_section_det.id_reports%TYPE;
        --
        PROCEDURE open_my_cursor(i_cursor IN OUT pk_print_tool.p_rep_section_cur) IS
        BEGIN
            IF i_cursor%ISOPEN
            THEN
                CLOSE i_cursor;
            END IF;
        
            OPEN i_cursor FOR
                SELECT NULL rank,
                       NULL id_reports,
                       NULL id_rep_section,
                       NULL id_rep_section_det,
                       NULL desc_section,
                       NULL desc_section_info,
                       NULL dt_section,
                       NULL flg_selected,
                       NULL printer_name,
                       NULL barcode_pat,
                       NULL barcode_nec,
                       NULL flg_num_prints,
                       NULL flg_default,
                       NULL flg_task
                  FROM dual
                 WHERE 1 = 0;
        END open_my_cursor;
    
    BEGIN
        l_dbg_msg := 'GET CFG_VARS';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
        BEGIN
            SELECT er.id_reports
              INTO l_reports
              FROM epis_report er
             WHERE er.id_epis_report = i_epis_reports;
        
        EXCEPTION
            WHEN no_data_found THEN
                raise_application_error(-20101, 'ERROR GETTING ID_REPORTS FOR ID_EPIS_REPORTS: ' || i_epis_reports);
            
        END;
    
        l_dbg_msg := 'OPEN O_SECTION';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_section FOR
            SELECT rsd.rank rank,
                   NULL id_reports,
                   ers.id_rep_section, --id_rep_section_det
                   ers.id_rep_section_det, --id_rep_section_det
                   pk_message.get_message(i_lang, i_prof, rs.code_rep_section) desc_section,
                   NULL desc_section_info,
                   NULL dt_section,
                   pk_alert_constant.g_active flg_selected,
                   NULL printer_name,
                   NULL barcode_pat,
                   NULL barcode_nec,
                   l_one flg_num_prints,
                   NULL flg_default,
                   rns.flg_task
              FROM epis_report_section ers
              JOIN epis_report er
                ON er.id_epis_report = ers.id_epis_report
              JOIN rep_section rs
                ON rs.id_rep_section = ers.id_rep_section
              JOIN rep_section_det rsd
                ON rsd.id_rep_section = rs.id_rep_section
               AND rsd.id_reports = er.id_reports
              LEFT JOIN rep_notes_section rns
                ON rns.id_rep_section = rs.id_rep_section
               AND rns.flg_available = pk_alert_constant.g_available
               AND rns.id_reports = rsd.id_reports
             WHERE ers.id_epis_report = i_epis_reports
               AND rsd.id_institution = decode((SELECT 1
                                                 FROM rep_section_det b
                                                WHERE b.id_reports = rsd.id_reports
                                                  AND b.id_institution = i_prof.institution
                                                  AND b.id_software IN (i_prof.software, 0)
                                                  AND b.id_rep_section = rsd.id_rep_section
                                                  AND b.id_rep_profile_template = rsd.id_rep_profile_template),
                                               1,
                                               i_prof.institution,
                                               0)
               AND rsd.id_software = decode((SELECT 1
                                              FROM rep_section_det b
                                             WHERE b.id_reports = rsd.id_reports
                                               AND b.id_institution = i_prof.institution
                                               AND b.id_software = i_prof.software
                                               AND b.id_rep_section = rsd.id_rep_section
                                               AND b.id_rep_profile_template = rsd.id_rep_profile_template),
                                            1,
                                            i_prof.software,
                                            decode((SELECT 1
                                                     FROM rep_section_det b
                                                    WHERE b.id_reports = rsd.id_reports
                                                      AND b.id_institution = 0
                                                      AND b.id_software = i_prof.software
                                                      AND b.id_rep_section = rsd.id_rep_section
                                                      AND b.id_rep_profile_template = rsd.id_rep_profile_template),
                                                   1,
                                                   i_prof.software,
                                                   0))
               AND rsd.flg_visible = pk_alert_constant.g_yes
             ORDER BY desc_section;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            open_my_cursor(o_section);
            RETURN FALSE;
        
    END get_epis_rep_section_list;

    /********************************************************************************************
    * Get epis report detail data
    *
    * NOTE: If only i_epis_report is filled (i_reports is null and i_episode is null) means that we only want the current record
    *       to display in "Current information detail" tab
    *       If all the these three fields are filled means that we want all the reports for the given i_reports and i_episode
    *       to be displayed in "History changes" tab
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Professional
    * @param i_epis_report                   Epis report id
    * @param i_reports                       Report id
    * @param i_episode                       Episode id
    * @param o_report_detail                 Epis report detail data
    * @param o_error                         error message
    *
    * @return                Return TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               2.6.1
    * @since                 2011/02/10
    **********************************************************************************************/

    FUNCTION get_epis_rep_det_int
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_report   IN epis_report.id_epis_report%TYPE,
        i_reports       IN epis_report.id_reports%TYPE,
        i_episode       IN epis_report.id_episode%TYPE,
        i_flg_type      IN epis_report.flg_type%TYPE,
        o_report_detail OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_separator CONSTANT VARCHAR2(2) := '; ';
        l_space     CONSTANT VARCHAR2(1) := ' ';
        l_zero      CONSTANT PLS_INTEGER := '0';
        l_one       CONSTANT PLS_INTEGER := '1';
    
        --Print section
        l_section_type_p         CONSTANT VARCHAR2(1) := 'P';
        l_code_msg_print         CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M001'; --Print
        l_code_msg_save          CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M028'; --Save
        l_code_msg_save_outside  CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M033'; --Save / Save to disk
        l_code_msg_save_local    CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M032'; --Save to disk:
        l_code_msg_rep_name      CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M017'; --Name of report:
        l_code_msg_rep_sect      CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M009'; --Report sections:
        l_code_msg_rep_dt        CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M014'; --Report printed:
        l_code_msg_rep_dt_save   CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M029'; --Report saved:
        l_code_msg_rep_prof      CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M015'; --Report printed by:
        l_code_msg_rep_prof_save CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M030'; --Report save by:
        l_desc_msg_print         sys_message.desc_message%TYPE;
        l_desc_msg_save          sys_message.desc_message%TYPE;
        l_desc_msg_save_outside  sys_message.desc_message%TYPE;
        l_desc_msg_save_local    sys_message.desc_message%TYPE;
        l_desc_msg_rep_name      sys_message.desc_message%TYPE;
        l_desc_msg_rep_sect      sys_message.desc_message%TYPE;
        l_desc_msg_rep_dt        sys_message.desc_message%TYPE;
        l_desc_msg_rep_dt_save   sys_message.desc_message%TYPE;
        l_desc_msg_rep_prof      sys_message.desc_message%TYPE;
        l_desc_msg_rep_prof_save sys_message.desc_message%TYPE;
    
        --Disclosure information section
        l_section_type_d     CONSTANT VARCHAR2(1) := 'D';
        l_code_msg_disc_info CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M016'; --Disclosure information
        l_code_msg_dt_req    CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M004'; --Date of request:
        l_code_msg_dt_disc   CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M005'; --Date of disclosure:
        l_code_msg_disc_prof CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M006'; --Name of person making the disclosure:
        l_code_msg_disc_to   CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M027'; --Disclosure to:
        l_code_msg_disc_rec  CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M007'; --Disclosure recipient:
        l_code_msg_rec_addr  CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M008'; --Recipient address:
        l_code_msg_notes     CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M010'; --Notes regarding information disclosed:
        l_code_msg_entered   CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M021'; --Entered:
        l_code_msg_purp_disc CONSTANT sys_message.code_message%TYPE := 'REPORT_DISCLOSURE_M025'; --Purpose of disclosure:
        --REPORT_DISCLOSURE_M027
        l_desc_msg_disc_info sys_message.desc_message%TYPE;
        l_desc_msg_dt_req    sys_message.desc_message%TYPE;
        l_desc_msg_dt_disc   sys_message.desc_message%TYPE;
        l_desc_msg_disc_prof sys_message.desc_message%TYPE;
        l_desc_msg_disc_to   sys_message.desc_message%TYPE;
        l_desc_msg_disc_rec  sys_message.desc_message%TYPE;
        l_desc_msg_rec_addr  sys_message.desc_message%TYPE;
        l_desc_msg_notes     sys_message.desc_message%TYPE;
        l_desc_msg_entered   sys_message.desc_message%TYPE;
        l_desc_msg_purp_disc sys_message.desc_message%TYPE;
    
        l_dom_saved_outside  CONSTANT sys_domain.code_domain%TYPE := 'EPIS_REPORT.FLG_SAVED_OUTSIDE';
        l_dom_disc_recipient CONSTANT sys_domain.code_domain%TYPE := 'EPIS_REPORT_DISCLOSURE.FLG_DISC_RECIPIENT';
    
        c_section pk_print_tool.p_rep_section_cur;
        r_section pk_print_tool.p_rep_section_rec;
        l_section CLOB := NULL;
    
        l_error EXCEPTION;
    
    BEGIN
    
        g_error                  := 'GET MESSAGES';
        l_desc_msg_print         := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_print);
        l_desc_msg_save          := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_save);
        l_desc_msg_save_outside  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_save_outside);
        l_desc_msg_save_local    := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_save_local);
        l_desc_msg_rep_name      := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_rep_name);
        l_desc_msg_rep_sect      := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_rep_sect);
        l_desc_msg_rep_dt        := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_rep_dt);
        l_desc_msg_rep_dt_save   := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_rep_dt_save);
        l_desc_msg_rep_prof      := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_rep_prof);
        l_desc_msg_rep_prof_save := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_rep_prof_save);
    
        l_desc_msg_disc_info := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_disc_info);
        l_desc_msg_dt_req    := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_dt_req);
        l_desc_msg_dt_disc   := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_dt_disc);
        l_desc_msg_disc_prof := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_disc_prof);
        l_desc_msg_disc_to   := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_disc_to);
        l_desc_msg_disc_rec  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_disc_rec);
        l_desc_msg_rec_addr  := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_rec_addr);
        l_desc_msg_notes     := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_notes);
        l_desc_msg_entered   := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_entered);
        l_desc_msg_purp_disc := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_purp_disc);
    
        g_error := 'GET REPORT SECTIONS CURSOR';
        IF NOT pk_print_tool.get_epis_rep_section_list(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_epis_reports => i_epis_report,
                                                       o_section      => c_section,
                                                       o_error        => o_error)
        THEN
            g_error := 'ERROR WHEN CALLING GET_SECTION_LIST';
            RAISE l_error;
        END IF;
    
        g_error := 'CONCATENATE SECTIONS';
        LOOP
            FETCH c_section
                INTO r_section;
            EXIT WHEN c_section%NOTFOUND;
        
            IF r_section.desc_section IS NOT NULL
            THEN
                l_section := l_section || r_section.desc_section || l_separator;
            END IF;
        END LOOP;
    
        CLOSE c_section;
    
        g_error := 'REMOVE LAST SEPARATOR';
        IF length(l_section) > l_zero
        THEN
            l_section := substr(l_section, l_one, length(l_section) - length(l_separator));
        END IF;
    
        g_error := 'GET REPORT DETAIL DATA (OPEN CURSOR)';
        OPEN o_report_detail FOR
            SELECT l_section_type_p section_type,
                   decode(er.flg_saved_outside,
                          pk_alert_constant.g_no,
                          decode(er.flg_status, g_epis_rep_status_saved, l_desc_msg_save, l_desc_msg_print),
                          l_desc_msg_save_outside) section_label,
                   CAST(MULTISET
                        (SELECT l_desc_msg_rep_name lbl -- Name of report:
                           FROM dual
                         UNION ALL
                         SELECT l_desc_msg_rep_sect lbl -- Report sections:
                           FROM dual
                         UNION ALL
                         SELECT decode(er.flg_status, g_epis_rep_status_saved, l_desc_msg_rep_dt_save, l_desc_msg_rep_dt) lbl -- Report printed:
                           FROM dual
                         UNION ALL
                         SELECT decode(er.flg_status,
                                       g_epis_rep_status_saved,
                                       l_desc_msg_rep_prof_save,
                                       l_desc_msg_rep_prof) lbl -- Report printed by:
                           FROM dual
                         UNION ALL
                         SELECT decode(er.flg_saved_outside, pk_alert_constant.g_no, NULL, l_desc_msg_save_local) lbl -- Saved locally:
                           FROM dual) AS table_varchar) tbl_labels,
                   CAST(MULTISET
                        (SELECT to_clob(coalesce(pk_message.get_message(i_lang, er.code_dynamic_title),
                                                 pk_translation.get_translation(i_lang,
                                                                                (SELECT r.code_reports_title
                                                                                   FROM reports r
                                                                                  WHERE r.id_reports = er1.id_reports)),
                                                 pk_translation.get_translation(i_lang,
                                                                                (SELECT r.code_reports
                                                                                   FROM reports r
                                                                                  WHERE r.id_reports = er1.id_reports)))) val -- Name of report
                           FROM epis_report er1
                          WHERE er1.id_epis_report = er.id_epis_report
                         UNION ALL
                         SELECT l_section val -- Report sections
                           FROM dual
                         UNION ALL
                         SELECT to_clob(pk_date_utils.date_char_tsz(i_lang,
                                                                    er1.dt_creation_tstz,
                                                                    i_prof.institution,
                                                                    i_prof.software)) val -- Report printed
                           FROM epis_report er1
                          WHERE er1.id_epis_report = er.id_epis_report
                         UNION ALL
                         SELECT to_clob(pk_prof_utils.get_name_signature(i_lang, i_prof, er1.id_professional)) val -- Report printed by
                           FROM epis_report er1
                          WHERE er1.id_epis_report = er.id_epis_report
                         UNION ALL
                         SELECT decode(er.flg_saved_outside,
                                       pk_alert_constant.g_no,
                                       empty_clob(),
                                       to_clob(pk_sysdomain.get_domain(l_dom_saved_outside, er1.flg_saved_outside, i_lang))) val -- Saved locally
                           FROM epis_report er1
                          WHERE er1.id_epis_report = er.id_epis_report) AS table_varchar) tbl_values,
                   l_desc_msg_entered || l_space ||
                   pk_prof_utils.get_name_signature(i_lang, i_prof, er.id_professional) || l_separator ||
                   pk_date_utils.date_char_tsz(i_lang, er.dt_creation_tstz, i_prof.institution, i_prof.software) signature,
                   er.dt_creation_tstz dt_order
              FROM (SELECT er.id_epis_report,
                           er.flg_saved_outside,
                           er.flg_status,
                           er.id_professional,
                           er.dt_creation_tstz,
                           er.code_dynamic_title
                      FROM epis_report er
                     WHERE er.id_epis_report = i_epis_report
                       AND er.flg_type = i_flg_type
                       AND er.id_reports = i_reports
                       AND er.flg_status <> g_epis_rep_status_n
                    UNION
                    SELECT er.id_epis_report,
                           er.flg_saved_outside,
                           er.flg_status,
                           er.id_professional,
                           er.dt_creation_tstz,
                           er.code_dynamic_title
                      FROM epis_report er
                     WHERE er.flg_type IN (i_flg_type, c_flg_type_current)
                       AND er.id_epis_parent IN
                           (SELECT e.id_epis_report
                              FROM epis_report e
                             WHERE e.id_epis_report <> i_epis_report
                             START WITH e.id_epis_report = i_epis_report
                            CONNECT BY PRIOR e.id_epis_parent = e.id_epis_report)
                       AND er.flg_status <> g_epis_rep_status_n
                    UNION
                    SELECT er.id_epis_report,
                           er.flg_saved_outside,
                           er.flg_status,
                           er.id_professional,
                           er.dt_creation_tstz,
                           er.code_dynamic_title
                      FROM epis_report er
                     WHERE er.id_epis_report = i_epis_report
                       AND er.flg_type = c_flg_type_current
                       AND er.id_reports = i_reports
                       AND er.flg_status <> g_epis_rep_status_n) er
            UNION ALL
            SELECT l_section_type_d section_type,
                   l_desc_msg_disc_info section_label,
                   table_varchar(l_desc_msg_dt_req, -- Date of request:
                                 l_desc_msg_dt_disc, -- Date of disclosure:
                                 l_desc_msg_disc_prof, -- Name of person making the disclosure:
                                 l_desc_msg_disc_rec, -- Disclosure recipient:
                                 l_desc_msg_disc_to, -- Disclosure to:
                                 l_desc_msg_rec_addr, -- Recipient address:
                                 l_desc_msg_purp_disc, -- Purpose of disclosure:
                                 l_desc_msg_notes -- Notes regarding information disclosed:
                                 ) tbl_labels,
                   table_varchar(pk_date_utils.date_char_tsz(i_lang,
                                                             erd.dt_request,
                                                             i_prof.institution,
                                                             i_prof.software), -- Date of request:
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             erd.dt_disclosure,
                                                             i_prof.institution,
                                                             i_prof.software), -- Date of disclosure:
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, erd.id_prof_disclosure), --Name of person making the disclosure:
                                 pk_sysdomain.get_domain(l_dom_disc_recipient, erd.flg_disc_recipient, i_lang), -- Disclosure recipient:
                                 erd.disclosure_recipient, -- Disclosure to:
                                 erd.recipient_address, -- Recipient address:
                                 (nvl(erd.free_text_purp_disc,
                                      decode(erd.id_sample_text,
                                             NULL,
                                             NULL,
                                             (SELECT pk_translation.get_translation(i_lang, st.code_desc_sample_text)
                                                FROM sample_text st
                                               WHERE st.id_sample_text = erd.id_sample_text)))), -- Purpose of disclosure:
                                 erd.notes -- Notes regarding information disclosed:
                                 ) tbl_values,
                   l_desc_msg_entered || l_space ||
                   pk_prof_utils.get_name_signature(i_lang, i_prof, erd.id_prof_disclosure) || l_separator ||
                   pk_date_utils.date_char_tsz(i_lang, erd.dt_register, i_prof.institution, i_prof.software) signature,
                   erd.dt_register dt_order
              FROM epis_report_disclosure erd
             WHERE erd.id_epis_report = i_epis_report
             ORDER BY dt_order DESC, section_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_error THEN
            pk_types.open_my_cursor(o_report_detail);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_REP_DET_INT',
                                              o_error);
            pk_types.open_my_cursor(o_report_detail);
            RETURN FALSE;
    END get_epis_rep_det_int;

    /********************************************************************************************
    * Get current epis report detail data
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Professional
    * @param i_epis_report                   Epis report id
    * @param o_report_detail                 Epis report detail data
    * @param o_error                         error message
    *
    * @return                Return TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               2.6.1
    * @since                 2011/02/10
    **********************************************************************************************/

    FUNCTION get_epis_rep_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_report   IN epis_report.id_epis_report%TYPE,
        o_report_detail OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EPIS_REP_DET';
    
        l_dbg_msg debug_msg;
        l_error EXCEPTION;
    
        l_reports epis_report.id_reports%TYPE;
        l_episode epis_report.id_episode%TYPE;
    
    BEGIN
        l_dbg_msg := 'CALL GET_EPIS_REP_DET_INT';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
    
        SELECT er.id_reports, er.id_episode
          INTO l_reports, l_episode
          FROM epis_report er
         WHERE er.id_epis_report = i_epis_report;
    
        IF NOT get_epis_rep_det_int(i_lang          => i_lang,
                                    i_prof          => i_prof,
                                    i_epis_report   => i_epis_report,
                                    i_reports       => l_reports,
                                    i_episode       => l_episode,
                                    i_flg_type      => c_flg_type_current,
                                    o_report_detail => o_report_detail,
                                    o_error         => o_error)
        THEN
            l_dbg_msg := 'ERROR WHEN CALLING GET_EPIS_REP_DET_INT';
            RAISE l_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_error THEN
            pk_types.open_my_cursor(o_report_detail);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_report_detail);
            RETURN FALSE;
        
    END get_epis_rep_det;

    /********************************************************************************************
    * Get epis report history data
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Professional
    * @param i_epis_report                   Epis report id
    * @param o_report_detail                 Epis report detail data
    * @param o_error                         error message
    *
    * @return                Return TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               2.6.1
    * @since                 2011/02/10
    **********************************************************************************************/

    FUNCTION get_epis_rep_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_report   IN epis_report.id_epis_report%TYPE,
        o_report_detail OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EPIS_REP_HIST';
    
        l_dbg_msg debug_msg;
        l_error EXCEPTION;
    
        l_reports epis_report.id_reports%TYPE;
        l_episode epis_report.id_episode%TYPE;
    
    BEGIN
        l_dbg_msg := 'GET ID_REPORTS AND IS_EPISODE';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT er.id_reports, er.id_episode
          INTO l_reports, l_episode
          FROM epis_report er
         WHERE er.id_epis_report = i_epis_report;
    
        l_dbg_msg := 'CALL GET_EPIS_REP_DET_INT';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT get_epis_rep_det_int(i_lang          => i_lang,
                                    i_prof          => i_prof,
                                    i_epis_report   => i_epis_report,
                                    i_reports       => l_reports,
                                    i_episode       => l_episode,
                                    i_flg_type      => c_flg_type_history,
                                    o_report_detail => o_report_detail,
                                    o_error         => o_error)
        THEN
            l_dbg_msg := 'ERROR WHEN CALLING GET_EPIS_REP_DET_INT';
            RAISE l_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_error THEN
            pk_types.open_my_cursor(o_report_detail);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_report_detail);
            RETURN FALSE;
        
    END get_epis_rep_hist;

    /********************************************************************************************
    * Insert the request of a report generation in the intf_alert queue
    *
    * @param i_id_episode                       Episode id
    * @param i_id_patient                       Patient id
    * @param i_id_institution                   Institution id
    * @param i_id_language                      Language id
    * @param i_id_report_type                   Report type id
    * @param i_id_professional                  Professional id
    * @param i_id_software                      Software id
    * @param i_flag_report_origin               Flag report origin
    *
    * @author PEDRO.MAIA
    * @version 1.0
    * @since 05-01-2011
    ********************************************************************************************/

    FUNCTION request_gen_report
    (
        i_id_episode         IN v_episode.id_episode%TYPE,
        i_id_patient         IN v_patient.id_patient%TYPE,
        i_id_institution     IN v_episode.id_institution%TYPE,
        i_id_language        IN v_institution.id_institution_language%TYPE,
        i_id_report_type     IN NUMBER,
        i_id_sections        IN VARCHAR2,
        i_id_professional    IN v_episode.id_professional%TYPE,
        i_id_software        IN v_episode.id_software%TYPE,
        i_flag_report_origin IN VARCHAR2
    ) RETURN BOOLEAN IS
    
        error_create_event EXCEPTION;
    
    BEGIN
    
        RETURN pk_ia_event_common.request_gen_report(i_id_episode         => i_id_episode,
                                                     i_id_patient         => i_id_patient,
                                                     i_id_institution     => i_id_institution,
                                                     i_id_language        => i_id_language,
                                                     i_id_report_type     => i_id_report_type,
                                                     i_id_sections        => i_id_sections,
                                                     i_id_professional    => i_id_professional,
                                                     i_id_software        => i_id_software,
                                                     i_flag_report_origin => i_flag_report_origin);
    END request_gen_report;

    /********************************************************************************************
    * Insert the request via printing list of a report generation in the intf_alert queue
    *
    * @param i_id_episode                       Episode id
    * @param i_id_patient                       Patient id
    * @param i_id_institution                   Institution id
    * @param i_id_language                      Language id
    * @param i_id_report_type                   Report type id
    * @param i_id_professional                  Professional id
    * @param i_id_software                      Software id
    * @param i_flag_report_origin               Flag report origin
    *
    * @author ricardo.pires
    * @version 1.0
    * @since 22-10-2011
    ********************************************************************************************/

    FUNCTION request_gen_report
    (
        i_id_institution    IN v_episode.id_institution%TYPE,
        i_id_professional   IN v_episode.id_professional%TYPE,
        i_id_software       IN v_episode.id_software%TYPE,
        i_id_language       IN v_institution.id_institution_language%TYPE,
        i_id_print_list_job IN NUMBER
    ) RETURN BOOLEAN IS
    
        error_create_event EXCEPTION;
    
    BEGIN
    
        RETURN pk_ia_event_common.request_gen_report(i_id_institution    => i_id_institution,
                                                     i_id_professional   => i_id_professional,
                                                     i_id_software       => i_id_software,
                                                     i_id_language       => i_id_language,
                                                     i_id_print_list_job => i_id_print_list_job);
    END request_gen_report;

    /**
    * Get the patient name (considering VIP alias)
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_pat_name     Patient name
    * @param o_error        error message
    *
    * @return                Return TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               2.6.1
    * @since                 2011/02/10
    **********************************************************************************************/

    FUNCTION get_pat_name
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_pat_name OUT patient.name%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EPIS_REP_HIST';
    
        l_dbg_msg debug_msg;
        l_error EXCEPTION;
    
        l_reports epis_report.id_reports%TYPE;
        l_episode epis_report.id_episode%TYPE;
    
    BEGIN
        l_dbg_msg := 'CALL PK_PATIENT.GET_PAT_NAME';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
        o_pat_name := pk_patient.get_pat_name(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_patient  => i_patient,
                                              i_episode  => i_episode,
                                              i_schedule => NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_error THEN
            o_pat_name := NULL;
            RETURN FALSE;
        WHEN OTHERS THEN
            o_pat_name := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
    END get_pat_name;

    FUNCTION get_next_id_epis_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_id_epis_report OUT epis_report.id_epis_report%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET NEXT ID_EPIS_REPORT';
        SELECT seq_epis_report.nextval
          INTO o_id_epis_report
          FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NEXT_ID_EPIS_REPORT',
                                              o_error);
            RETURN FALSE;
    END get_next_id_epis_report;

    /**
    * Gets reports list for a specific institution/software
    *
    * @param      i_lang                  Language
    * @param      i_prof                  Profissional
    * @param      i_rep_profile_template  Rep_profile_template ID
    * @param      i_flg_area_report       rep_profile_template_det.flg_area_report
    * @param      o_reports               cursor with reports list
    * @param      o_error                 error
    *
    * @return     boolean
    *
    * @author     Gustavo Serrano
    * @since      2011/05/27
    * @version    2.6.1.2
    */

    FUNCTION get_reports_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_rep_profile_template IN table_number,
        i_flg_area_report      IN rep_profile_template_det.flg_area_report%TYPE,
        o_reports              OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'get_reports_list';
        l_message debug_msg;
    
    BEGIN
    
        l_message := 'OPEN CURSOR O_REPORTS';
        OPEN o_reports FOR
            SELECT t.id_reports, t.flg_context_column flg_context, t.id_software
              FROM (SELECT rptd.id_reports,
                           r.flg_context_column,
                           rpt.id_software,
                           rptd.flg_available rptd_avail,
                           r.flg_available r_avail,
                           rank() over(PARTITION BY rptd.id_reports ORDER BY rpt.id_institution DESC) rec_rank
                      FROM rep_profile_template_det rptd
                     INNER JOIN rep_profile_template rpt
                        ON rpt.id_rep_profile_template = rptd.id_rep_profile_template
                     INNER JOIN rep_prof_templ_access rpta
                        ON rpta.id_rep_profile_template = rpt.id_rep_profile_template
                     INNER JOIN reports r
                        ON r.id_reports = rptd.id_reports
                     WHERE rptd.flg_area_report = i_flg_area_report
                       AND rptd.flg_type = c_flg_add
                       AND rpt.id_institution IN (0, i_prof.institution)
                       AND (i_prof.software = 0 OR rpt.id_software = i_prof.software)
                       AND rptd.id_rep_profile_template IN
                           (SELECT /*+ opt_estimate(table t rows=5)*/
                             column_value
                              FROM TABLE(i_rep_profile_template))) t
             WHERE t.rec_rank = 1
               AND nvl(t.rptd_avail, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
               AND nvl(t.r_avail, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
             ORDER BY t.id_software;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_reports);
            RETURN FALSE;
        
    END get_reports_list;

    /**********************************************************************************************
    * GET_TIMEFRAME_SECTIONS          Returns sections time frame filter availability
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_report              Report to be verified
    * @param i_sections               Sections to be verified
    * @param o_sections_date_filter   Sections and time frame filter availability
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    **********************************************************************************************/

    FUNCTION get_timeframe_sections
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_report            IN reports.id_reports%TYPE,
        i_sections             IN table_number,
        o_sections_date_filter OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
        l_message := 'GET TIMEFRAME SECTIONS';
        pk_alertlog.log_debug(l_message);
    
        OPEN o_sections_date_filter FOR
            SELECT rsd.id_reports, rsd.id_rep_section, rsd.flg_date_filters
              FROM TABLE(i_sections) t
              JOIN rep_section_det rsd
                ON rsd.id_reports = i_id_report
               AND rsd.id_rep_section = t.column_value;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMEFRAME_SECTIONS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_sections_date_filter);
            RETURN FALSE;
        
    END get_timeframe_sections;

    /**
    * Obt�m a lista de reports dispon�veis para o profissional em determinado ecr� e os reports do epis�dio seleccionado.
    * @param    I_LANG               Idioma
    * @param    I_PROF               objecto com dados do utilizador
    * @param    I_EPISODE            ID do epis�dio actual
    * @param    I_AREA_REPORT        �rea na qual ser� alocado o relat�rio
    * @param    I_SCREEN_NAME        Nome do ecr� onde a fun��o � chamada
    * @param    I_SYS_BUTTON_PROP    ID do deepnav selecionado (If this value is null then it will be valid for all screen instances)
    * @param    I_ID_REPORT_EPISODE  ID do epis�dio seleccionado
    * @param    I_ID_SOFTWARE        ID do software do epis�dio seleccionado
    *
    * @param    O_REPORTS            Array com a lista de reports
    * @param    O_ERROR              Descri��o do erro
    *
    * @return     true (tudo ok), false (erro)
    * @author     T�rcio Soares
    * @version    2.6.3.7       2013/07/09
    */

    FUNCTION get_rep_prev_epis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_area_report       IN rep_profile_template_det.flg_area_report%TYPE,
        i_screen_name       IN rep_screen.screen_name%TYPE,
        i_sys_button_prop   IN sys_button_prop.id_sys_button_prop%TYPE,
        i_id_report_episode IN episode.id_episode%TYPE,
        i_id_software       IN software.id_software%TYPE,
        o_reports           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_error   t_error_out;
        l_exception EXCEPTION;
    
        l_prev_reports table_number := table_number();
    
        l_rep_prof_template rep_prof_template.id_rep_prof_template%TYPE;
        l_get_rep_list      t_table_report_doc_arch;
    
    BEGIN
    
        l_message      := 'GET ACTUAL EPISODE REPORTS LIST';
        l_get_rep_list := get_reports_list_tf(i_lang,
                                              i_prof,
                                              i_episode,
                                              i_area_report,
                                              i_screen_name,
                                              i_sys_button_prop,
                                              NULL,
                                              l_error);
    
        IF i_id_report_episode IS NULL
        THEN
        
            OPEN o_reports FOR
                SELECT tbl.id_reports,
                       tbl.desc_report,
                       tbl.id_parent,
                       NULL                       AS "DEFAULT",
                       tbl.flg_tools,
                       pk_alert_constant.g_active flg_active,
                       tbl.rank,
                       NULL                       id_episode_report
                  FROM TABLE(l_get_rep_list) tbl
                UNION
                SELECT 0 id_reports,
                       pk_message.get_message(i_lang, 'PREV_EPISODE_T1105') desc_report, --action's description
                       NULL id_parent,
                       NULL AS "DEFAULT",
                       NULL flg_tools,
                       pk_alert_constant.g_inactive flg_active,
                       10000 rank,
                       NULL id_episode_report
                  FROM dual
                 ORDER BY rank;
        ELSE
        
            l_message := 'GET PROFESSIONAL REPORTS PROFILE';
            IF NOT pk_print_tool.get_rep_prof_id(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 o_id_profile => l_rep_prof_template,
                                                 o_error      => l_error)
            THEN
                RAISE g_get_rep_prof_id_exception;
            END IF;
        
            OPEN o_reports FOR
                SELECT tbl.id_reports,
                       tbl.desc_report,
                       tbl.id_parent,
                       NULL                       "DEFAULT",
                       tbl.flg_tools,
                       pk_alert_constant.g_active flg_active,
                       tbl.rank,
                       NULL                       id_episode_report
                  FROM TABLE(l_get_rep_list) tbl
                UNION
                SELECT 0 id_reports,
                       pk_message.get_message(i_lang, 'PREV_EPISODE_T1105') desc_report, --action's description
                       NULL id_parent,
                       NULL "DEFAULT",
                       NULL flg_tools,
                       pk_alert_constant.g_active flg_active,
                       10000 rank,
                       i_id_report_episode id_episode_report
                  FROM dual
                UNION
                SELECT rpe.id_reports,
                       pk_translation.get_translation(i_lang, r.code_reports) desc_report, --action's description
                       0 id_parent,
                       NULL "DEFAULT",
                       NULL flg_tools,
                       pk_alert_constant.g_active flg_active,
                       NULL rank,
                       i_id_report_episode id_episode_report
                  FROM rep_prev_epis rpe
                  JOIN reports r
                    ON r.id_reports = rpe.id_reports
                 WHERE rpe.id_institution IN (i_prof.institution, 0)
                   AND rpe.id_rep_profile_template IN (l_rep_prof_template, g_default_rep_profile_id)
                   AND rpe.id_software = i_id_software
                 ORDER BY rank;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_get_rep_prof_id_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REP_PREV_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_reports);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REP_PREV_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_reports);
            RETURN FALSE;
        
    END get_rep_prev_epis;

    /**
    * Obt�m a lista de reports dispon�veis para o profissional em determinado ecr�.
    * @param    I_LANG               L�ngua registada como prefer�ncia do profissional
    * @param    I_PROF               objecto com dados do utilizador
    * @param    I_EPISODE            ID do epis�dio actual
    * @param    I_AREA_REPORT        �rea na qual ser� alocado o relat�rio. Valores poss�veis:
    *                                    {*} 'R' Reports
    *                                    {*} 'OD' Ongoing Documents
    *                                    {*} 'C' Consents
    *                                    {*} 'CR' Certificates
    *                                    {*} 'F' Forms
    *                                    {*} 'L' Lables
    *                                    {*} 'SR' Screen Reports
    * @param    I_SCREEN_NAME        Nome do ecr� onde a fun��o � chamada
    * @param    I_SYS_BUTTON_PROP    ID do deepnav selecionado (If this value is null then it will be valid for all screen instances)
    *
    * @param    O_REPORTS            Array com a lista de reports
    * @param    O_ERROR              Descri��o do erro
    *
    * @return     true (tudo ok), false (erro)
    * @author     T�rcio Soares
    * @version    1.0       2013/07/09
    */

    FUNCTION get_reports_list_tf
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_area_report     IN rep_profile_template_det.flg_area_report%TYPE,
        i_screen_name     IN rep_screen.screen_name%TYPE,
        i_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        i_context         IN table_varchar DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN t_table_report_doc_arch IS
    
        l_sys_config_value  sys_config.value%TYPE;
        l_rep_prof_template rep_prof_template.id_rep_prof_template%TYPE;
    
        l_get_rep_list t_table_report_doc_arch;
        l_get_rep_rec  t_rec_report_doc_arch;
    
        l_market     market.id_market%TYPE;
        l_id_patient patient.id_patient%TYPE;
    
        l_rep_screen rep_screen.id_rep_screen%TYPE;
        l_cnt_c      NUMBER := 0;
    
        l_epis_type epis_type.id_epis_type%TYPE;
    
        l_area_report table_varchar;
    
    BEGIN
    
        g_error := 'GET AREA_REPORT';
        SELECT t.flg_area_report
          INTO l_area_report
          FROM (SELECT table_varchar('C', 'CR') flg_area_report
                  FROM dual
                 WHERE i_area_report IN ('C', 'CR')
                UNION ALL
                SELECT table_varchar(i_area_report) flg_area_report
                  FROM dual
                 WHERE i_area_report NOT IN ('C', 'CR')) t;
    
        IF i_context IS NOT NULL
        THEN
            l_cnt_c := i_context.count;
        END IF;
    
        g_error := 'GET REP_SCREEN ID';
        BEGIN
            SELECT r.id_rep_screen
              INTO l_rep_screen
              FROM rep_screen r
             WHERE (r.id_sys_button_prop = i_sys_button_prop OR r.id_sys_button_prop IS NULL)
               AND r.screen_name = i_screen_name;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_rep_screen := NULL;
        END;
    
        g_error := 'GET PROFESSIONAL REPORTS PROFILE';
        IF NOT pk_print_tool.get_rep_prof_id(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             o_id_profile => l_rep_prof_template,
                                             o_error      => o_error)
        THEN
            RAISE g_get_rep_prof_id_exception;
        END IF;
    
        g_error  := 'get market id';
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        g_error := 'get patient id';
        IF i_episode IS NOT NULL
        THEN
            l_id_patient := pk_episode.get_epis_patient(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        
            g_error := 'GET_EPIS_TYPE';
            IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                            i_id_epis   => i_episode,
                                            o_epis_type => l_epis_type,
                                            o_error     => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSE
            l_id_patient := NULL;
            l_epis_type  := NULL;
        END IF;
    
        g_error            := 'REPORT_ASYNCHRONOUS_ID';
        l_sys_config_value := pk_sysconfig.get_config('REPORT_ASYNCHRONOUS_ID', i_prof);
    
        g_error := 'OPEN O_REPORTS CURSOR';
        SELECT t_rec_report_doc_arch(tbl_res.rank,
                                      tbl_res.id_reports,
                                      tbl_res.desc_report,
                                      tbl_res.flg_type,
                                      tbl_res.flg_tools,
                                      tbl_res.flg_filter,
                                      tbl_res.flg_printer,
                                      tbl_res.flg_auth_req,
                                      tbl_res.flg_action,
                                      tbl_res.det_screen_name,
                                      decode(flg_exists_in_print_list,
                                             pk_alert_constant.g_yes,
                                             g_icon_exists_in_print_list,
                                             tbl_res.flg_status),
                                      tbl_res.flg_time_fraction,
                                      tbl_res.flg_param_profs,
                                      tbl_res.max_prof_count,
                                      tbl_res.interval_count,
                                      tbl_res.id_parent,
                                      (CASE
                                          WHEN (tbl_res.flg_date_filters = c_flg_type_y)
                                               AND EXISTS (SELECT m.id_timeframe_rep
                                                  FROM timeframe_rep_grp_mkt m
                                                  JOIN timeframe_rep tr
                                                    ON tr.id_timeframe_rep = m.id_timeframe_rep
                                                 WHERE m.id_market IN (l_market, 0)
                                                   AND tr.id_report = tbl_res.id_reports
                                                   AND rownum = 1) THEN
                                           c_flg_type_y
                                      
                                          WHEN (tbl_res.flg_date_filters = c_flg_type_y)
                                               AND NOT EXISTS (SELECT m.id_timeframe_rep
                                                  FROM timeframe_rep_grp_mkt m
                                                  JOIN timeframe_rep tr
                                                    ON tr.id_timeframe_rep = m.id_timeframe_rep
                                                 WHERE tr.id_report = tbl_res.id_reports
                                                   AND rownum = 1) THEN
                                           c_flg_type_y
                                          ELSE
                                           c_flg_type_n
                                      END),
                                      tbl_res.level_rank,
                                      tbl_res.flg_disclosure,
                                      (SELECT pk_print_tool.check_if_has_sections(i_lang    => i_lang,
                                                                                  i_prof    => i_prof,
                                                                                  i_episode => i_episode,
                                                                                  i_patient => l_id_patient,
                                                                                  i_reports => table_number(tbl_res.id_reports))
                                         FROM dual),
                                      tbl_res.id_task_type,
                                      tbl_res.flg_date_filters_context,
                                      table_varchar(),
                                      CASE tbl_res.id_task_type
                                          WHEN 35 THEN
                                           decode(l_cnt_c, 0, 'I', NULL)
                                          ELSE
                                           NULL
                                      END)
          BULK COLLECT
          INTO l_get_rep_list
          FROM (SELECT rank,
                       id_reports,
                       desc_report,
                       flg_type,
                       flg_tools,
                       flg_filter,
                       flg_printer,
                       flg_auth_req,
                       flg_action,
                       det_screen_name,
                       flg_status,
                       flg_time_fraction,
                       flg_param_profs,
                       max_prof_count,
                       interval_count,
                       id_parent,
                       flg_date_filters,
                       level_rank,
                       flg_disclosure,
                       (SELECT pk_print_list_db.check_if_context_exists(i_lang                   => i_lang,
                                                                         i_prof                   => i_prof,
                                                                         i_episode                => i_episode,
                                                                         i_print_list_area        => (CASE
                                                                                                     -- automated reports
                                                                                                         WHEN i_area_report = 'R' THEN
                                                                                                          pk_print_list_db.g_print_list_area_auto_r
                                                                                                     -- editable reports
                                                                                                         WHEN i_area_report = 'E' THEN
                                                                                                          pk_print_list_db.g_print_list_area_edit_r
                                                                                                     -- consents
                                                                                                         WHEN i_area_report = 'C' THEN
                                                                                                          pk_print_list_db.g_print_list_area_consent
                                                                                                     -- certificates
                                                                                                         WHEN i_area_report = 'CR' THEN
                                                                                                          pk_print_list_db.g_print_list_area_certif
                                                                                                     END),
                                                                         i_print_job_context_data => to_clob(id_reports))
                          FROM dual) flg_exists_in_print_list,
                       id_task_type,
                       flg_date_filters_context
                  FROM (SELECT td.rank,
                               CASE
                                    WHEN r.flg_tools = g_flg_tools_s THEN
                                     to_number(l_sys_config_value)
                                    ELSE
                                     r.id_reports
                                END id_reports,
                               pk_translation.get_translation(i_lang, r.code_reports) desc_report,
                               r.flg_type,
                               nvl(r.flg_tools, g_flg_tools_n) flg_tools,
                               nvl(r.flg_filter, g_flg_tools_n) flg_filter,
                               r.flg_printer,
                               r.flg_auth_req,
                               r.flg_action,
                               r.det_screen_name,
                               (SELECT pk_print_tool.get_img_name(i_lang, i_episode, r.id_reports)
                                  FROM dual) flg_status,
                               r.flg_time_fraction,
                               r.flg_param_profs,
                               r.max_prof_count,
                               r.interval_count,
                               r.id_parent,
                               r.flg_date_filters,
                               r.level_rank,
                               nvl(td.flg_disclosure, pk_alert_constant.g_no) flg_disclosure,
                               r.id_task_type,
                               r.flg_date_filters_context
                          FROM rep_profile_template pt, rep_profile_template_det td
                          JOIN (SELECT LEVEL level_rank, a.*
                                 FROM reports a
                                START WITH a.id_parent IS NULL
                               CONNECT BY nocycle PRIOR a.id_reports = a.id_parent
                                ORDER BY LEVEL) r
                            ON r.id_reports = td.id_reports
                         INNER JOIN rep_report_mkt rpm
                            ON rpm.id_reports = r.id_reports
                         WHERE td.flg_area_report IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                       *
                                                        FROM TABLE(l_area_report) t)
                           AND rpm.id_market = decode((SELECT COUNT(*) num
                                                        FROM rep_report_mkt rrm2
                                                       WHERE rrm2.id_market = l_market
                                                         AND rrm2.id_reports = r.id_reports),
                                                      0,
                                                      pk_alert_constant.g_id_market_all,
                                                      l_market)
                           AND td.id_rep_profile_template IN (l_rep_prof_template, g_default_rep_profile_id)
                           AND td.id_rep_profile_template_det NOT IN
                               (SELECT t.id_rep_profile_template_det
                                  FROM rep_profile_template_det t
                                 WHERE t.id_rep_profile_template = g_default_rep_profile_id
                                   AND t.id_reports IN
                                       (SELECT t2.id_reports
                                          FROM rep_profile_template_det t2
                                         WHERE t2.id_rep_profile_template = l_rep_prof_template))
                           AND td.flg_type = c_flg_add
                           AND nvl(td.flg_available, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
                           AND nvl(r.flg_available, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
                           AND pt.id_rep_profile_template = td.id_rep_profile_template
                           AND pt.id_software IN (i_prof.software, g_default_rep_software_id)
                           AND pt.id_institution IN (i_prof.institution, g_default_rep_institution_id)
                              ------------------ ACCESS RULES - Does profile choosed has access ? ---------------------
                              -- The next condition verifies if the profile select as permissions to access the templates
                              -- reports by checking two things:
                              -- 1. if there are configurations on the rep_prof_template that allow the current profile to
                              -- access them. There might be cases were a profile ONLY exists on the reports side and not on ALERT
                              -- 2. OR if there is a relation between the profile on ALERT and the profile on the reports and that
                              -- relation is present on the rep_prof_templ_access
                              --
                           AND --O profissional tem acessos especificos ao template de reports
                               (EXISTS (SELECT 1
                                          FROM rep_prof_template rpt
                                         WHERE rpt.id_professional = i_prof.id
                                           AND rpt.id_software IN (i_prof.software, g_default_rep_software_id)
                                           AND rpt.id_institution IN (i_prof.institution, g_default_rep_institution_id)
                                           AND rpt.id_rep_profile_template = pt.id_rep_profile_template) OR
                               -- ou o profissional tem um template de acessos atribuido que esta ligado ao template de reports
                                EXISTS (SELECT 1
                                          FROM prof_profile_template ppt, rep_prof_templ_access rpta
                                         WHERE ppt.id_software IN (i_prof.software, g_default_rep_software_id)
                                           AND ppt.id_institution IN (i_prof.institution, g_default_rep_institution_id)
                                           AND ppt.id_professional = i_prof.id
                                           AND rpta.id_profile_template = ppt.id_profile_template
                                           AND rpta.id_rep_profile_template IN
                                               (pt.id_rep_profile_template, g_default_rep_profile_id)) OR
                               -- OR it is a 'ALL' profile = 0 record. The default profile ID's should be allowed
                                  pt.id_rep_profile_template = g_default_rep_profile_id)
                                ------------------ SCREEN RULES ---------------------
                                --verifica relatorios especificos para o ecra actual a adicionar
                             AND (td.id_rep_screen IS NULL AND NOT EXISTS
                                 -- check if the current screen can't accept rep_profile_template_det records with null id_rep_screen columns
                                (SELECT 1 -- if so, consider only rep_screen record configurations in below queries
                                   FROM (SELECT flg_enable
                                           FROM (SELECT rse.flg_enable
                                                   FROM rep_screen_excl rse
                                                  WHERE rse.screen_name = i_screen_name
                                                    AND rse.id_sys_button_prop = i_sys_button_prop
                                                    AND rse.id_institution IN
                                                        (i_prof.institution, g_default_rep_institution_id)
                                                  ORDER BY rse.id_institution DESC)
                                          WHERE rownum = 1)
                                  WHERE flg_enable = pk_alert_constant.g_yes) OR EXISTS
                                (SELECT 1
                                   FROM rep_screen s
                                  WHERE nvl(s.id_rep_screen, -1) = nvl(td.id_rep_screen, -1)
                                    AND s.flg_type = c_flg_add
                                    AND s.screen_name = i_screen_name
                                    AND (s.id_sys_button_prop = i_sys_button_prop OR s.id_sys_button_prop IS NULL)))
                              --verifica relat�rios espec�ficos para o ecr� actual a retirar
                           AND NOT EXISTS
                         (SELECT 1
                                  FROM rep_screen s1
                                 WHERE nvl(s1.id_rep_screen, -1) = nvl(td.id_rep_screen, -1)
                                   AND s1.flg_type = c_flg_remove
                                   AND s1.screen_name = i_screen_name
                                   AND (s1.id_sys_button_prop = i_sys_button_prop OR s1.id_sys_button_prop IS NULL))
                              ------------------ EXCEPTIONS RULES ---------------------
                              --Retira excep��es ao template
                           AND NOT EXISTS
                         (SELECT 1
                                  FROM rep_prof_exception rpe
                                 WHERE rpe.id_rep_profile_template_det = td.id_rep_profile_template_det
                                   AND rpe.flg_area_report = td.flg_area_report
                                   AND rpe.id_reports = td.id_reports
                                   AND nvl(rpe.id_professional, i_prof.id) = i_prof.id
                                   AND rpe.id_institution IN (i_prof.institution, g_default_rep_institution_id)
                                   AND rpe.id_software IN (i_prof.software, g_default_rep_software_id))
                           AND NOT EXISTS
                         (SELECT 1
                                  FROM rep_screen s1, rep_prof_exception rpe
                                 WHERE s1.id_rep_screen = rpe.id_rep_screen
                                   AND rpe.flg_type = c_flg_remove
                                   AND s1.screen_name = i_screen_name
                                   AND (s1.id_sys_button_prop = i_sys_button_prop OR s1.id_sys_button_prop IS NULL)
                                   AND s1.id_rep_screen = rpe.id_rep_screen
                                   AND rpe.id_rep_profile_template_det = td.id_rep_profile_template_det)
                              -- Add only reports active for i_prof.institution
                           AND EXISTS
                         (SELECT 1
                                  FROM rep_profile_template_det rptd
                                 WHERE rptd.id_rep_profile_template = td.id_rep_profile_template
                                   AND rptd.id_reports = td.id_reports
                                   AND rptd.flg_area_report = td.flg_area_report
                                   AND rptd.flg_available = pk_alert_constant.g_yes)
                           AND (i_prof.software <> pk_alert_constant.g_soft_adt OR EXISTS
                                (SELECT 1
                                   FROM epis_type_reports etr
                                  WHERE etr.id_reports = td.id_reports
                                    AND ((l_epis_type IS NULL AND etr.id_epis_type = -1) OR
                                        (l_epis_type IS NOT NULL AND etr.id_epis_type IN (0, l_epis_type)))))
                        UNION ALL
                        SELECT rpe.rank,
                               CASE
                                   WHEN r.flg_tools = 'S' THEN
                                    to_number(l_sys_config_value)
                                   ELSE
                                    r.id_reports
                               END id_reports,
                               pk_translation.get_translation(i_lang, r.code_reports) desc_report,
                               r.flg_type,
                               nvl(r.flg_tools, 'N') flg_tools,
                               nvl(r.flg_filter, 'N') flg_filter,
                               flg_printer,
                               r.flg_auth_req,
                               r.flg_action,
                               r.det_screen_name,
                               (SELECT pk_print_tool.get_img_name(i_lang, i_episode, r.id_reports)
                                  FROM dual) flg_status,
                               r.flg_time_fraction,
                               r.flg_param_profs,
                               r.max_prof_count,
                               r.interval_count,
                               NULL id_parent,
                               r.flg_date_filters,
                               NULL level_rank,
                               coalesce(rpe.flg_disclosure,
                                        (SELECT pk_api_backoffice.get_prof_rep_disclosure(i_lang,
                                                                                          i_prof,
                                                                                          r.id_reports,
                                                                                          i_screen_name,
                                                                                          i_area_report)
                                           FROM dual),
                                        pk_alert_constant.g_no) flg_disclosure,
                               r.id_task_type,
                               r.flg_date_filters_context
                          FROM rep_prof_exception rpe, reports r
                         WHERE rpe.flg_area_report IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                        *
                                                         FROM TABLE(l_area_report) t)
                           AND rpe.id_rep_profile_template = l_rep_prof_template
                           AND (rpe.id_rep_screen IS NULL OR rpe.id_rep_screen = l_rep_screen)
                           AND nvl(rpe.id_professional, i_prof.id) = i_prof.id
                           AND rpe.flg_type = c_flg_add
                           AND rpe.id_software IN (i_prof.software, 0)
                           AND rpe.id_institution IN (i_prof.institution, 0)
                           AND r.id_reports = rpe.id_reports
                           AND nvl(r.flg_available, pk_alert_constant.g_yes) = pk_alert_constant.g_yes)) tbl_res
         ORDER BY tbl_res.rank;
    
        RETURN l_get_rep_list;
    
    END get_reports_list_tf;

    /**
    * Modifica o conte�do do CLOB de um report
    *
    * @param i_lang id da lingua
    * @param i_prof obj do utilizador
    * @param i_epis_report id do relat�rio gerado
    * @param i_binary_file blob do report
    * @param o_error var com mensagem de erro
    *
    * @return true (successo), false (erro)
    *
    * @author Jorge Costa, 12-12-2013
    * @since 2.6.3
    */

    FUNCTION set_epis_report_binary_file
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_report IN epis_report.id_epis_report%TYPE,
        i_binary_file IN epis_report.rep_binary_file%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
        l_my_exception EXCEPTION;
        l_message debug_msg;
    
    BEGIN
        l_message := 'UPDATE ER CLOB';
        UPDATE epis_report
           SET rep_binary_file = i_binary_file
         WHERE id_epis_report = i_epis_report
           AND flg_status = 'N';
    
        IF (SQL%ROWCOUNT = 1)
        THEN
        
            l_message := 'UPDATE ER STATUS';
            l_ret     := pk_print_tool.set_epis_report_status(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_epis_report => i_epis_report,
                                                              i_flg_status  => 'S',
                                                              o_error       => o_error);
        
            IF l_ret = FALSE
            THEN
                RAISE l_my_exception;
            END IF;
        
        ELSE
            RAISE l_my_exception;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_REPORT_BINARY_FILE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_epis_report_binary_file;

    /**
    * Get information for a specific professional
    *
    * @param i_lang id of the language
    * @param i_prof obj of the user
    * @param id_prof id of the professional
    * @param o_inst_info data of the institution
    * @param o_prof_info data of the professional
    * @param o_error var error message
    *
    * @return true (successo), false (erro)
    *
    * @author Ricardo Pires, 22-02-2014
    * @since 2.6.4.2
    */

    FUNCTION get_prof_presc_rep_info
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        id_prof     IN professional.id_professional%TYPE,
        o_inst_info OUT pk_types.cursor_type,
        o_prof_info OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        i_prof_presc profissional;
    
    BEGIN
        i_prof_presc := profissional(id_prof, i_prof.institution, i_prof.software);
    
        RETURN get_prof_presc_info(i_lang            => i_lang,
                                   i_prof            => i_prof_presc,
                                   i_id_professional => NULL,
                                   o_inst_info       => o_inst_info,
                                   o_prof_info       => o_prof_info,
                                   o_error           => o_error);
    END get_prof_presc_rep_info;

    /**
    * Adds the report to the printing list
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_patient            Patient identifier
    * @param   i_episode            Episode identifier
    * @param   i_print_list_areas   Print list area id
    * @param   i_report             List of report ids
    * @param   i_print_arguments    List of print arguments necessary to print the jobs
    * @param   o_print_list_jobs    Cursor with the print job ids
    * @param   o_error              An error message, set when return=false
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   07-10-2014
    */

    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_print_list_area IN print_list_area.id_print_list_area%TYPE,
        i_report          IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_jobs OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'add_print_list_jobs';
        l_params           VARCHAR2(4000);
        l_context_data     table_clob;
        l_print_list_areas table_number;
        l_exception_np EXCEPTION;
        l_retval BOOLEAN;
    
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_episode=' || i_episode ||
                    ' i_print_list_area=' || i_print_list_area;
    
        -- init
        l_context_data     := table_clob();
        l_print_list_areas := table_number();
        l_message          := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => l_message, object_name => g_package_name, sub_object_name => l_func_name);
        END IF;
    
        -- getting context data
        l_context_data.extend(i_report.count);
        l_print_list_areas.extend(i_report.count);
        FOR i IN 1 .. i_report.count
        LOOP
            l_context_data(i) := to_clob(i_report(i));
            l_print_list_areas(i) := i_print_list_area;
        END LOOP;
    
        -- call function to add jobs to the printing list
        l_message := 'Call pk_print_list_db.add_print_jobs / ' || l_params;
        l_retval  := pk_print_list_db.add_print_jobs(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_patient          => i_patient,
                                                     i_episode          => i_episode,
                                                     i_print_list_areas => l_print_list_areas,
                                                     i_context_data     => l_context_data,
                                                     i_print_arguments  => i_print_arguments,
                                                     o_print_list_jobs  => o_print_list_jobs,
                                                     o_error            => o_error);
    
        IF NOT l_retval
        THEN
            RAISE l_exception_np;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception_np THEN
            pk_alertlog.log_warn(l_message);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END add_print_list_jobs;

    /**
    * Gets information about print list job related to the referral
    * Used by print list
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_print_list_job  Print list job identifier, related to the referral
    *
    * @return  t_rec_print_list_job Print list job information
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   30-09-2014
    */

    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job IS
        l_message debug_msg;
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'tf_get_print_job_info';
        l_params       VARCHAR2(1000 CHAR);
        l_result       t_rec_print_list_job;
        l_context_data print_list_job.context_data%TYPE;
        l_id_report    reports.id_reports%TYPE;
    
    BEGIN
        l_params  := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' || i_id_print_list_job;
        l_message := 'Init ' || l_func_name || ' / ' || l_params;
    
        l_result := t_rec_print_list_job();
    
        -- getting contex data of this print list job
        SELECT v.context_data
          INTO l_context_data
          FROM v_print_list_context_data v
         WHERE v.id_print_list_job = i_id_print_list_job;
    
        -- getting information of this report
        l_message   := 'l_id_report / ' || l_params;
        l_id_report := to_number(l_context_data);
    
        l_params := l_params || ' id_report=' || l_id_report;
    
        l_result.id_print_list_job := i_id_print_list_job;
    
        SELECT pk_translation.get_translation(i_lang, r.code_reports) title_desc, NULL subtitle_desc
          INTO l_result.title_desc, l_result.subtitle_desc
          FROM reports r
         WHERE r.id_reports = l_id_report;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLERRM || ' / ' || l_message);
            RETURN t_rec_print_list_job();
        
    END tf_get_print_job_info;

    /**
    * Compares if a print list job context data is similar to the array of print list jobs
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_print_job_context_data     Print list job context data
    * @param   i_print_list_jobs            Array of print list job identifiers
    *
    * @return  table_number                 Array of print list jobs that are similar
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   07-10-2014
    */

    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_print_list_jobs        IN table_number
    ) RETURN table_number IS
        l_message debug_msg;
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'tf_compare_print_jobs';
        l_params VARCHAR2(1000 CHAR);
        l_result table_number;
    
    BEGIN
        l_params  := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_print_job_context_data=' ||
                     i_print_job_context_data || ' i_print_list_jobs=' || pk_utils.to_string(i_print_list_jobs);
        l_message := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- getting all id_print_list_jobs from i_print_list_jobs that have the same context_data (id_report) as i_print_job_context_data
        SELECT t.id_print_list_job
          BULK COLLECT
          INTO l_result
          FROM (SELECT /*+opt_estimate (table t rows=1)*/
                 v2.id_print_list_job
                  FROM v_print_list_context_data v2
                  JOIN TABLE(CAST(i_print_list_jobs AS table_number)) t
                    ON t.column_value = v2.id_print_list_job
                 WHERE dbms_lob.compare(v2.context_data, i_print_job_context_data) = 0) t;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLERRM || ' / ' || l_message);
            RETURN table_number();
        
    END tf_compare_print_jobs;

    FUNCTION get_reports_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_area_report     IN rep_profile_template_det.flg_area_report%TYPE,
        i_screen_name     IN rep_screen.screen_name%TYPE,
        i_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        i_task_type       IN table_number,
        i_context         IN table_varchar,
        o_reports         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message             debug_msg;
        l_coll_print_report   t_coll_print_report;
        l_get_rep_list        t_table_report_doc_arch;
        l_get_rep_list_pl     t_table_report_doc_arch;
        l_get_rep_list_p      t_table_report_doc_arch;
        l_get_rep_list_p_aux1 t_table_report_doc_arch;
        l_get_rep_list_p_aux2 t_table_report_doc_arch;
        l_get_rep_list_cpoe1  t_table_report_doc_arch := t_table_report_doc_arch();
        l_tbl                 t_table_report_doc_arch;
        l_tbl_p               t_table_report_doc_arch;
        l_nr_reports          NUMBER := 1;
    BEGIN
        l_message := 'VALIDATE i_task_type and i_context';
        IF i_task_type IS NOT NULL
           AND i_context IS NOT NULL
           AND i_task_type.count = i_context.count
           AND i_task_type.count > 0
        THEN
        
            --get specific reports for options "Add to Print List" and "Print"
            l_message         := 'CALL GET_REPORTS_LIST_PL with screen_area=PL';
            l_get_rep_list_pl := get_reports_list_pl(i_lang,
                                                     i_prof,
                                                     i_episode,
                                                     'PL',
                                                     i_screen_name,
                                                     i_sys_button_prop,
                                                     i_task_type,
                                                     i_context,
                                                     o_error);
        
            l_message        := 'CALL GET_REPORTS_LIST_PL with screen_area=P';
            l_get_rep_list_p := get_reports_list_pl(i_lang,
                                                    i_prof,
                                                    i_episode,
                                                    'P',
                                                    i_screen_name,
                                                    i_sys_button_prop,
                                                    i_task_type,
                                                    i_context,
                                                    o_error);
        ELSIF i_task_type IS NOT NULL
              AND i_context IS NOT NULL
              AND i_task_type.count > i_context.count
              AND i_task_type.count > 0
        THEN
            FOR i IN 1 .. i_task_type.count
            LOOP
                IF i_task_type(i) IS NOT NULL
                THEN
                    --get specific reports for options "Add to Print List" and "Print"
                    l_message         := 'CALL GET_REPORTS_LIST_PL with screen_area=PL';
                    l_get_rep_list_pl := get_reports_list_pl(i_lang,
                                                             i_prof,
                                                             i_episode,
                                                             'PL',
                                                             i_screen_name,
                                                             i_sys_button_prop,
                                                             table_number(i_task_type(i)),
                                                             i_context,
                                                             o_error);
                    l_message         := 'CALL GET_REPORTS_LIST_PL with screen_area=P';
                    IF i = 1
                    THEN
                        l_get_rep_list_p_aux1 := get_reports_list_pl(i_lang,
                                                                     i_prof,
                                                                     i_episode,
                                                                     'P',
                                                                     i_screen_name,
                                                                     i_sys_button_prop,
                                                                     table_number(i_task_type(i)),
                                                                     i_context,
                                                                     o_error);
                    ELSIF i = 2
                    THEN
                        l_nr_reports          := 2;
                        l_get_rep_list_p_aux2 := get_reports_list_pl(i_lang,
                                                                     i_prof,
                                                                     i_episode,
                                                                     'P',
                                                                     i_screen_name,
                                                                     i_sys_button_prop,
                                                                     table_number(i_task_type(i)),
                                                                     i_context,
                                                                     o_error);
                    END IF;
                END IF;
            END LOOP;
            l_get_rep_list_p := l_get_rep_list_p_aux1 MULTISET UNION l_get_rep_list_p_aux2;
        ELSE
            l_get_rep_list_pl := t_table_report_doc_arch();
            l_get_rep_list_p  := t_table_report_doc_arch();
        END IF;
    
        l_message      := 'CALL GET_REPORTS_LIST_TF';
        l_get_rep_list := get_reports_list_tf(i_lang,
                                              i_prof,
                                              i_episode,
                                              i_area_report,
                                              i_screen_name,
                                              i_sys_button_prop,
                                              i_context,
                                              o_error);
    
        /**OBTAINS THE LIST OF REPORTS ONLY FOR CPOE SCREEN AND IN CASE OF ONE OR MORE TASKS ARE SPECIFICALlY SELECTED TO PRINT**/
        l_message := 'VERIFY IF CPOE AND SELECTED TASK';
        IF i_screen_name = 'CpoeGrid.swf'
           AND cardinality(i_task_type) != 0
           AND cardinality(i_context) != 0
        THEN
            l_message            := 'CALL GET_REPORTS_LIST_CPOE1';
            l_get_rep_list_cpoe1 := get_reports_list_tf(i_lang,
                                                        i_prof,
                                                        i_episode,
                                                        'PL',
                                                        i_screen_name,
                                                        i_sys_button_prop,
                                                        NULL,
                                                        o_error);
        
        END IF;
    
        l_message := 'OPEN O_REPORTS CURSOR';
        pk_alertlog.log_info('adsd count:' || l_get_rep_list.count);
        l_tbl_p := l_get_rep_list_pl MULTISET UNION l_get_rep_list_p;
        l_tbl_p := l_tbl_p MULTISET UNION l_get_rep_list_cpoe1;
        l_tbl   := l_tbl_p MULTISET UNION l_get_rep_list;
    
        IF l_nr_reports = 2
        THEN
            OPEN o_reports FOR
                SELECT rank,
                       id_reports,
                       desc_report,
                       flg_type,
                       flg_tools,
                       flg_filter,
                       flg_printer,
                       flg_auth_req,
                       flg_action,
                       det_screen_name,
                       flg_status,
                       flg_time_fraction,
                       flg_param_profs,
                       max_prof_count,
                       interval_count,
                       id_parent,
                       flg_date_filters,
                       level_rank,
                       flg_disclosure,
                       has_sections,
                       id_task_type,
                       flg_date_filters_context,
                       --column_values,
                       flg_active
                  FROM (SELECT DISTINCT tbl.*
                          FROM (TABLE(l_tbl)) tbl)
                 GROUP BY rank,
                          id_reports,
                          desc_report,
                          flg_type,
                          flg_tools,
                          flg_filter,
                          flg_printer,
                          flg_auth_req,
                          flg_action,
                          det_screen_name,
                          flg_status,
                          flg_time_fraction,
                          flg_param_profs,
                          max_prof_count,
                          interval_count,
                          id_parent,
                          flg_date_filters,
                          level_rank,
                          flg_disclosure,
                          has_sections,
                          id_task_type,
                          flg_date_filters_context,
                          --column_values,
                          flg_active
                 ORDER BY rank, desc_report;
        ELSE
            OPEN o_reports FOR
                SELECT tbl.*
                  FROM (TABLE(l_tbl)) tbl
                 ORDER BY rank, desc_report;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORTS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_reports);
            RETURN FALSE;
        
    END get_reports_list;

    FUNCTION get_main_pl_report
    (
        i_rep_prof_template IN rep_prof_template.id_rep_prof_template%TYPE,
        i_area_report       IN rep_profile_template_det.flg_area_report%TYPE,
        i_screen_name       IN rep_screen.screen_name%TYPE,
        i_sys_button_prop   IN sys_button_prop.id_sys_button_prop%TYPE,
        i_market            IN market.id_market%TYPE
    ) RETURN NUMBER IS
        l_id_reports_tlb table_number;
        l_id_reports_pl  NUMBER;
    
    BEGIN
        -- get add to printing list option
        l_id_reports_tlb := get_main_pl_reports(i_rep_prof_template => i_rep_prof_template,
                                                i_area_report       => i_area_report,
                                                i_screen_name       => i_screen_name,
                                                i_sys_button_prop   => i_sys_button_prop,
                                                i_market            => i_market);
        IF (l_id_reports_tlb.count > 0)
        THEN
            l_id_reports_pl := l_id_reports_tlb(1);
        END IF;
    
        RETURN l_id_reports_pl;
    END get_main_pl_report;

    FUNCTION get_main_pl_reports
    (
        i_rep_prof_template IN rep_prof_template.id_rep_prof_template%TYPE,
        i_area_report       IN rep_profile_template_det.flg_area_report%TYPE,
        i_screen_name       IN rep_screen.screen_name%TYPE,
        i_sys_button_prop   IN sys_button_prop.id_sys_button_prop%TYPE,
        i_market            IN market.id_market%TYPE
    ) RETURN table_number IS
    
        l_id_reports_tlb table_number;
    
    BEGIN
    
        -- get add to printing list option
        SELECT r.id_reports
          BULK COLLECT
          INTO l_id_reports_tlb
          FROM reports r, rep_profile_template_det rptd, rep_screen rs, rep_report_mkt rpm
         WHERE r.flg_action = i_area_report
           AND r.id_reports = rptd.id_reports
           AND rptd.flg_area_report = i_area_report
           AND rs.screen_name = i_screen_name
           AND rptd.id_rep_screen = rs.id_rep_screen
           AND (rs.id_sys_button_prop = i_sys_button_prop OR rs.id_sys_button_prop IS NULL)
           AND rpm.id_reports = r.id_reports
           AND rpm.id_market = decode((SELECT COUNT(*) num
                                        FROM rep_report_mkt rrm2
                                       WHERE rrm2.id_market = i_market
                                         AND rrm2.id_reports = r.id_reports),
                                      0,
                                      pk_alert_constant.g_id_market_all,
                                      i_market)
           AND rptd.id_rep_profile_template IN (i_rep_prof_template, g_default_rep_profile_id);
    
        RETURN l_id_reports_tlb;
    
    END get_main_pl_reports;

    FUNCTION check_has_reports_by_area
    (
        i_rep_prof_template IN rep_prof_template.id_rep_prof_template%TYPE,
        i_area_report       IN rep_profile_template_det.flg_area_report%TYPE,
        i_screen_name       IN rep_screen.screen_name%TYPE,
        i_sys_button_prop   IN sys_button_prop.id_sys_button_prop%TYPE,
        i_market            IN market.id_market%TYPE,
        i_reports           IN table_number
    ) RETURN VARCHAR2 IS
        l_id_reports_tlb table_number;
        l_result         VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_count          NUMBER;
        l_market         market.id_market%TYPE;
    BEGIN
    
        --check id_market
        SELECT COUNT(*) num
          INTO l_count
          FROM rep_report_mkt rrm
          JOIN (SELECT /*+opt_estimate(table tbl rows=1)*/
                DISTINCT column_value id_reports
                  FROM TABLE(i_reports) tbl) r1
            ON r1.id_reports = rrm.id_reports
         WHERE rrm.id_market = i_market;
    
        IF l_count = 0
        THEN
            l_market := pk_alert_constant.g_id_market_all;
        ELSE
            l_market := i_market;
        END IF;
    
        --check if report is in area (ignore main reports - flg_action P or PL)
        SELECT id_reports
          BULK COLLECT
          INTO l_id_reports_tlb
          FROM (SELECT r.id_reports
                  FROM reports r
                  JOIN rep_profile_template_det rptd
                    ON r.id_reports = rptd.id_reports
                  JOIN rep_screen rs
                    ON rptd.id_rep_screen = rs.id_rep_screen
                  JOIN rep_report_mkt rpm
                    ON rpm.id_reports = r.id_reports
                  JOIN (SELECT /*+opt_estimate(table tbl rows=1)*/
                       DISTINCT column_value id_reports
                         FROM TABLE(i_reports) tbl) r1
                    ON r1.id_reports = r.id_reports
                 WHERE r.flg_action IS NULL
                   AND rptd.flg_area_report = i_area_report
                   AND rs.screen_name = i_screen_name
                   AND rs.id_sys_button_prop = i_sys_button_prop
                   AND rpm.id_market = l_market
                   AND rptd.id_rep_profile_template IN (i_rep_prof_template, g_default_rep_profile_id)
                UNION ALL
                SELECT r.id_reports
                  FROM reports r
                  JOIN rep_profile_template_det rptd
                    ON r.id_reports = rptd.id_reports
                  JOIN rep_screen rs
                    ON rptd.id_rep_screen = rs.id_rep_screen
                  JOIN rep_report_mkt rpm
                    ON rpm.id_reports = r.id_reports
                  JOIN (SELECT /*+opt_estimate(table tbl rows=1)*/
                       DISTINCT column_value id_reports
                         FROM TABLE(i_reports) tbl) r1
                    ON r1.id_reports = r.id_reports
                 WHERE rptd.flg_area_report = i_area_report
                   AND rs.screen_name = i_screen_name
                   AND rs.id_sys_button_prop IS NULL
                   AND rpm.id_market = l_market
                   AND rptd.id_rep_profile_template IN (i_rep_prof_template, g_default_rep_profile_id)
                   AND rptd.flg_available = 'Y');
    
        IF (l_id_reports_tlb.count > 0)
        THEN
            l_result := pk_alert_constant.g_yes;
        ELSE
            l_result := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_result;
    END check_has_reports_by_area;

    FUNCTION get_reports_list_pl
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_area_report     IN rep_profile_template_det.flg_area_report%TYPE,
        i_screen_name     IN rep_screen.screen_name%TYPE,
        i_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        i_task_type       IN table_number,
        i_context         IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN t_table_report_doc_arch IS
    
        l_message           debug_msg;
        l_sys_config_value  sys_config.value%TYPE;
        l_rep_prof_template rep_prof_template.id_rep_prof_template%TYPE;
    
        l_get_rep_list t_table_report_doc_arch;
    
        l_market     market.id_market%TYPE;
        l_id_patient patient.id_patient%TYPE;
    
        l_coll_print_report   t_coll_print_report;
        l_cnt_tt              NUMBER;
        l_cnt_c               NUMBER;
        l_id_reports_pl       NUMBER;
        l_id_reports_pl_list  table_number;
        l_id_reports_list     table_number;
        l_id_reports_list_aux table_number;
        l_id_req_det          table_varchar;
    
        l_id_reports_list2 pk_types.cursor_type;
    
        l_id_product          table_varchar;
        l_id_product_supplier table_varchar;
        l_presc_type          table_varchar;
        l_task_type           table_number;
    
        l_ret BOOLEAN;
    
        l_ref_flg_active    table_varchar;
        l_ref_column_values table_varchar;
    
        l_info_type VARCHAR2(20);
    
        l_in_area VARCHAR2(1 CHAR);
    
    BEGIN
    
        l_cnt_tt              := i_task_type.count;
        l_cnt_c               := i_context.count;
        l_id_reports_list     := table_number();
        l_id_reports_list_aux := table_number();
    
        l_message := 'GET PROFESSIONAL REPORTS PROFILE';
        IF NOT pk_print_tool.get_rep_prof_id(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             o_id_profile => l_rep_prof_template,
                                             o_error      => o_error)
        THEN
            RAISE g_get_rep_prof_id_exception;
        END IF;
    
        l_message := 'get market id';
        pk_alertlog.log_info(text => l_message, object_name => g_package_name, sub_object_name => 'GET_REPORTS_LIST');
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        IF l_cnt_tt > 0
           AND l_cnt_tt = l_cnt_c
        THEN
        
            -- VALIDATE the type of task type so that we can call the rigth function;
            --if ref, no need to run all the table_varchar
            IF i_task_type(1) = c_task_type_ref
            THEN
                l_coll_print_report := pk_ref_ext_sys.tf_get_print_reports(i_lang, i_prof, i_context);
                pk_alertlog.log_info('pk_ref_ext_sys.tf_get_print_reports count:' || l_coll_print_report.count);
            
                FOR i IN 1 .. l_coll_print_report.count
                LOOP
                    l_id_reports_list.extend;
                    l_id_reports_list(l_id_reports_list.last) := l_coll_print_report(i).id_reports;
                
                    --indicate type of call processed
                    l_info_type := 'REF';
                END LOOP;
            
                l_in_area := check_has_reports_by_area(i_rep_prof_template => l_rep_prof_template,
                                                       i_area_report       => i_area_report,
                                                       i_screen_name       => i_screen_name,
                                                       i_sys_button_prop   => i_sys_button_prop,
                                                       i_market            => l_market,
                                                       i_reports           => l_id_reports_list);
            
                IF l_in_area = pk_alert_constant.g_no
                THEN
                    l_id_reports_list     := table_number();
                    l_id_product          := table_varchar();
                    l_id_product_supplier := table_varchar();
                    l_presc_type          := table_varchar();
                    l_task_type           := table_number();
                ELSE
                
                    l_id_reports_list_aux := l_id_reports_list;
                END IF;
            
                --if medication, multiple task_types are sent
            ELSIF (i_task_type(1) = c_task_type_med_home OR i_task_type(1) = c_task_type_med_hosp OR
                  i_task_type(1) = c_task_type_med_local OR i_task_type(1) = c_task_type_med_outsd OR
                  i_task_type(1) = c_task_type_non_stand_med OR i_task_type(1) = c_task_type_narcotic_amb_med OR
                  i_task_type(1) = c_task_type_narcotic_local OR i_task_type(1) = c_task_type_controlled_amb_med OR
                  i_task_type(1) = c_task_type_controlled_local)
            THEN
                --indicate type of call processed
                l_info_type := 'MED';
                --on this case i_context return multiple info: id_product and id_supplier
                l_ret := pk_reports_medication_api.get_rep_prescription_match(i_lang                => i_lang,
                                                                              i_prof                => i_prof,
                                                                              i_task_type           => i_task_type,
                                                                              i_id_product          => i_context,
                                                                              i_id_product_supplier => i_context,
                                                                              o_id_reports          => l_id_reports_list2,
                                                                              o_error               => o_error);
                IF l_id_reports_list2 IS NULL
                THEN
                    pk_alertlog.log_info('pk_reports_medication_api.get_rep_prescription_match.o_id_reports is null');
                ELSE
                    FETCH l_id_reports_list2 BULK COLLECT
                        INTO l_id_reports_list, l_presc_type, l_task_type, l_id_product, l_id_product_supplier;
                
                    l_in_area := check_has_reports_by_area(i_rep_prof_template => l_rep_prof_template,
                                                           i_area_report       => i_area_report,
                                                           i_screen_name       => i_screen_name,
                                                           i_sys_button_prop   => i_sys_button_prop,
                                                           i_market            => l_market,
                                                           i_reports           => l_id_reports_list);
                
                    IF (l_in_area = pk_alert_constant.g_no)
                    THEN
                        l_id_reports_list     := table_number();
                        l_id_product          := table_varchar();
                        l_id_product_supplier := table_varchar();
                        l_presc_type          := table_varchar();
                        l_task_type           := table_number();
                        pk_alertlog.log_info('pk_reports_medication_api.get_rep_prescription_match.o_id_reports returned result but not found in report area');
                    ELSE
                    
                        l_id_reports_list_aux := l_id_reports_list;
                    
                        pk_alertlog.log_info('pk_reports_medication_api.get_rep_prescription_match.o_id_reports count:' ||
                                             l_id_reports_list.count);
                    END IF;
                END IF;
            END IF;
        END IF;
    
        l_message := 'get patient id';
        pk_alertlog.log_info(text => l_message, object_name => g_package_name, sub_object_name => 'GET_REPORTS_LIST');
        l_id_patient := pk_episode.get_epis_patient(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        l_message := 'REPORT_ASYNCHRONOUS_ID';
        pk_alertlog.log_info(text => l_message, object_name => g_package_name, sub_object_name => 'GET_REPORTS_LIST');
        l_sys_config_value := pk_sysconfig.get_config('REPORT_ASYNCHRONOUS_ID', i_prof);
    
        --IF IS NOT RETURNED ANY REPORTS FOR THAT TASKS TYPES AND THE RESPECTIVE VALUES, SO THERE IS NO REPORTS CHILD
        --AND FOR THAT REASON THE OPTION IS NOT SHOWN FOR MED AND REF CASE.
        IF ((i_task_type(1) = c_task_type_ref OR i_task_type(1) = c_task_type_med_home OR
           i_task_type(1) = c_task_type_med_hosp OR i_task_type(1) = c_task_type_med_local OR
           i_task_type(1) = c_task_type_med_outsd OR i_task_type(1) = c_task_type_narcotic_amb_med OR
           i_task_type(1) = c_task_type_narcotic_local OR i_task_type(1) = c_task_type_controlled_amb_med OR
           i_task_type(1) = c_task_type_controlled_local) AND l_id_reports_list.count > 0)
        THEN
            l_message := 'get_main_pl_report';
            -- get the main add to printing list option
            l_id_reports_pl := get_main_pl_report(i_rep_prof_template => l_rep_prof_template,
                                                  i_area_report       => i_area_report,
                                                  i_screen_name       => i_screen_name,
                                                  i_sys_button_prop   => i_sys_button_prop,
                                                  i_market            => l_market);
            l_id_reports_list.extend;
            l_id_reports_list(l_id_reports_list.last) := l_id_reports_pl;
        ELSE
        
            CASE i_task_type(1)
                WHEN c_task_type_lab_tests THEN
                    l_id_req_det := pk_lab_tests_external_api_db.tf_get_lab_test_to_print(i_lang             => i_lang,
                                                                                          i_prof             => i_prof,
                                                                                          i_analysis_req_det => i_context);
                
                WHEN c_task_type_img_exams THEN
                    l_id_req_det := pk_exams_external_api_db.tf_get_exam_to_print(i_lang         => i_lang,
                                                                                  i_prof         => i_prof,
                                                                                  i_exam_req_det => i_context);
                
                WHEN c_task_type_other_exams THEN
                    l_id_req_det := pk_exams_external_api_db.tf_get_exam_to_print(i_lang         => i_lang,
                                                                                  i_prof         => i_prof,
                                                                                  i_exam_req_det => i_context);
                WHEN c_task_type_blood_prod THEN
                    l_id_req_det := i_context;
                WHEN c_task_type_sr_epis THEN
                    l_id_req_det := i_context;
                WHEN c_task_type_inp_epis THEN
                    l_id_req_det := i_context;
                ELSE
                    l_id_req_det := NULL;
            END CASE;
        
            IF l_id_req_det IS NOT NULL
               AND l_id_req_det.count > 0
            THEN
            
                l_id_reports_pl_list := get_main_pl_reports(i_rep_prof_template => l_rep_prof_template,
                                                            i_area_report       => i_area_report,
                                                            i_screen_name       => i_screen_name,
                                                            i_sys_button_prop   => i_sys_button_prop,
                                                            i_market            => l_market);
            
                FOR i IN 1 .. l_id_reports_pl_list.count
                LOOP
                    l_id_reports_list.extend;
                    l_id_reports_list(l_id_reports_list.last) := l_id_reports_pl_list(i);
                
                END LOOP;
            END IF;
        END IF;
    
        l_message := 'OPEN O_REPORTS CURSOR';
        SELECT t_rec_report_doc_arch(tbl_res.rank,
                                      tbl_res.id_reports,
                                      tbl_res.desc_report,
                                      tbl_res.flg_type,
                                      tbl_res.flg_tools,
                                      tbl_res.flg_filter,
                                      tbl_res.flg_printer,
                                      tbl_res.flg_auth_req,
                                      CASE
                                          WHEN (l_info_type = 'MED' AND tbl_res.id_parent IS NOT NULL) THEN
                                           pk_reports_medication_api.get_report_presc_type(i_lang            => i_lang,
                                                                                           i_prof            => i_prof,
                                                                                           i_id_reports      => tbl_res.id_reports,
                                                                                           i_id_reports_list => l_id_reports_list_aux,
                                                                                           i_presc_type      => l_presc_type)
                                          ELSE
                                           tbl_res.flg_action
                                      END,
                                      tbl_res.det_screen_name,
                                      decode(flg_exists_in_print_list,
                                             pk_alert_constant.g_yes,
                                             g_icon_exists_in_print_list,
                                             tbl_res.flg_status),
                                      tbl_res.flg_time_fraction,
                                      tbl_res.flg_param_profs,
                                      tbl_res.max_prof_count,
                                      tbl_res.interval_count,
                                      tbl_res.id_parent,
                                      (CASE
                                          WHEN (tbl_res.flg_date_filters = c_flg_type_y)
                                               AND EXISTS (SELECT m.id_timeframe_rep
                                                  FROM timeframe_rep_grp_mkt m
                                                  JOIN timeframe_rep tr
                                                    ON tr.id_timeframe_rep = m.id_timeframe_rep
                                                 WHERE m.id_market IN (l_market, 0)
                                                   AND tr.id_report = tbl_res.id_reports
                                                   AND rownum = 1) THEN
                                           c_flg_type_y
                                      
                                          WHEN (tbl_res.flg_date_filters = c_flg_type_y)
                                               AND NOT EXISTS (SELECT m.id_timeframe_rep
                                                  FROM timeframe_rep_grp_mkt m
                                                  JOIN timeframe_rep tr
                                                    ON tr.id_timeframe_rep = m.id_timeframe_rep
                                                 WHERE tr.id_report = tbl_res.id_reports
                                                   AND rownum = 1) THEN
                                           c_flg_type_y
                                          ELSE
                                           c_flg_type_n
                                      END),
                                      tbl_res.level_rank,
                                      tbl_res.flg_disclosure,
                                      NULL,
                                      CASE
                                          WHEN (l_info_type = 'MED' AND tbl_res.id_parent IS NOT NULL) THEN
                                           pk_reports_medication_api.get_report_task_type(i_lang            => i_lang,
                                                                                          i_prof            => i_prof,
                                                                                          i_id_reports      => tbl_res.id_reports,
                                                                                          i_id_reports_list => l_id_reports_list_aux,
                                                                                          i_task_type       => l_task_type)
                                          ELSE
                                           tbl_res.id_task_type || ''
                                      END,
                                      tbl_res.flg_date_filters_context,
                                      (CASE
                                      -- get extra info for refs tasks
                                          WHEN i_task_type(1) = c_task_type_ref THEN
                                           pk_ref_ext_sys.tf_get_print_report(i_lang => i_lang, i_prof => i_prof, i_id_tasks => i_context, i_id_report => tbl_res.id_reports).get_column_values()
                                      -- get extra info for meds tasks
                                          ELSE
                                           table_varchar()
                                      END),
                                      CASE tbl_res.id_task_type
                                          WHEN 35 THEN
                                           decode(l_cnt_c, 0, 'I', NULL)
                                          ELSE
                                           NULL
                                      END)
          BULK COLLECT
          INTO l_get_rep_list
          FROM (SELECT DISTINCT rank,
                                id_reports,
                                desc_report,
                                flg_type,
                                flg_tools,
                                flg_filter,
                                flg_printer,
                                flg_auth_req,
                                flg_action,
                                det_screen_name,
                                flg_status,
                                flg_time_fraction,
                                flg_param_profs,
                                max_prof_count,
                                interval_count,
                                id_parent,
                                flg_date_filters,
                                level_rank,
                                flg_disclosure,
                                NULL flg_exists_in_print_list,
                                id_task_type,
                                flg_date_filters_context
                  FROM (SELECT td.rank,
                               CASE
                                    WHEN r.flg_tools = g_flg_tools_s THEN
                                     to_number(l_sys_config_value)
                                    ELSE
                                     r.id_reports
                                END id_reports,
                               pk_translation.get_translation(i_lang, r.code_reports) desc_report,
                               r.flg_type,
                               nvl(r.flg_tools, g_flg_tools_n) flg_tools,
                               nvl(r.flg_filter, g_flg_tools_n) flg_filter,
                               r.flg_printer,
                               r.flg_auth_req,
                               r.flg_action flg_action,
                               r.det_screen_name,
                               pk_print_tool.get_img_name(i_lang, i_episode, r.id_reports) flg_status,
                               r.flg_time_fraction,
                               r.flg_param_profs,
                               r.max_prof_count,
                               r.interval_count,
                               decode(r.id_reports, l_id_reports_pl, NULL, l_id_reports_pl) id_parent,
                               r.flg_date_filters,
                               r.level_rank,
                               nvl(td.flg_disclosure, pk_alert_constant.g_no) flg_disclosure,
                               r.id_task_type,
                               r.flg_date_filters_context
                          FROM rep_profile_template pt, rep_profile_template_det td
                          JOIN (SELECT LEVEL level_rank,
                                      pk_translation.get_translation(i_lang, a.code_reports) desc_report,
                                      a.*,
                                      first_value(LEVEL) over(PARTITION BY LEVEL ORDER BY pk_translation.get_translation(i_lang, a.code_reports)) rank1
                                 FROM reports a
                                WHERE a.id_reports IN (SELECT column_value
                                                         FROM TABLE(l_id_reports_list) tbl)
                                START WITH a.id_parent IS NULL
                               CONNECT BY nocycle PRIOR a.id_reports = a.id_parent
                                ORDER BY LEVEL) r
                            ON r.id_reports = td.id_reports
                         INNER JOIN rep_report_mkt rpm
                            ON rpm.id_reports = r.id_reports
                         WHERE td.flg_area_report = i_area_report
                           AND rpm.id_market = decode((SELECT COUNT(*) num
                                                        FROM rep_report_mkt rrm2
                                                       WHERE rrm2.id_market = l_market
                                                         AND rrm2.id_reports = r.id_reports),
                                                      0,
                                                      pk_alert_constant.g_id_market_all,
                                                      l_market)
                           AND td.id_rep_profile_template IN (l_rep_prof_template, g_default_rep_profile_id)
                           AND td.id_rep_profile_template_det NOT IN
                               (SELECT t.id_rep_profile_template_det
                                  FROM rep_profile_template_det t
                                 WHERE t.id_rep_profile_template = g_default_rep_profile_id
                                   AND t.id_reports IN
                                       (SELECT t2.id_reports
                                          FROM rep_profile_template_det t2
                                         WHERE t2.id_rep_profile_template = l_rep_prof_template))
                           AND td.flg_type = c_flg_add
                           AND nvl(td.flg_available, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
                           AND nvl(r.flg_available, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
                           AND pt.id_rep_profile_template = td.id_rep_profile_template
                           AND pt.id_software IN (i_prof.software, g_default_rep_software_id)
                           AND pt.id_institution IN (i_prof.institution, g_default_rep_institution_id)
                              ------------------ ACCESS RULES - Does profile choosed has access ? ---------------------
                              -- The next condition verifies if the profile select as permissions to access the templates
                              -- reports by checking two things:
                              -- 1. if there are configurations on the rep_prof_template that allow the current profile to
                              -- access them. There might be cases were a profile ONLY exists on the reports side and not on ALERT
                              -- 2. OR if there is a relation between the profile on ALERT and the profile on the reports and that
                              -- relation is present on the rep_prof_templ_access
                              --
                           AND --O profissional tem acessos especificos ao template de reports
                               (EXISTS (SELECT 1
                                          FROM rep_prof_template rpt
                                         WHERE rpt.id_professional = i_prof.id
                                           AND rpt.id_software IN (i_prof.software, g_default_rep_software_id)
                                           AND rpt.id_institution IN (i_prof.institution, g_default_rep_institution_id)
                                           AND rpt.id_rep_profile_template = pt.id_rep_profile_template) OR
                               -- ou o profissional tem um template de acessos atribuido que esta ligado ao template de reports
                                EXISTS (SELECT 1
                                          FROM prof_profile_template ppt, rep_prof_templ_access rpta
                                         WHERE ppt.id_software IN (i_prof.software, g_default_rep_software_id)
                                           AND ppt.id_institution IN (i_prof.institution, g_default_rep_institution_id)
                                           AND ppt.id_professional = i_prof.id
                                           AND rpta.id_profile_template = ppt.id_profile_template
                                           AND rpta.id_rep_profile_template IN
                                               (pt.id_rep_profile_template, g_default_rep_profile_id)) OR
                               -- OR it is a 'ALL' profile = 0 record. The default profile ID's should be allowed
                                  pt.id_rep_profile_template = g_default_rep_profile_id)
                                ------------------ SCREEN RULES ---------------------
                                --verifica relatorios especificos para o ecra actual a adicionar
                             AND (td.id_rep_screen IS NULL AND NOT EXISTS
                                 -- check if the current screen can't accept rep_profile_template_det records with null id_rep_screen columns
                                (SELECT 1 -- if so, consider only rep_screen record configurations in below queries
                                   FROM (SELECT flg_enable
                                           FROM (SELECT rse.flg_enable
                                                   FROM rep_screen_excl rse
                                                  WHERE rse.screen_name = i_screen_name
                                                    AND rse.id_sys_button_prop = i_sys_button_prop
                                                    AND rse.id_institution IN
                                                        (i_prof.institution, g_default_rep_institution_id)
                                                  ORDER BY rse.id_institution DESC)
                                          WHERE rownum = 1)
                                  WHERE flg_enable = pk_alert_constant.g_yes) OR EXISTS
                                (SELECT 1
                                   FROM rep_screen s
                                  WHERE nvl(s.id_rep_screen, -1) = nvl(td.id_rep_screen, -1)
                                    AND s.flg_type = c_flg_add
                                    AND s.screen_name = i_screen_name
                                    AND (s.id_sys_button_prop = i_sys_button_prop OR s.id_sys_button_prop IS NULL)))
                              --verifica relat�rios espec�ficos para o ecr� actual a retirar
                           AND NOT EXISTS
                         (SELECT 1
                                  FROM rep_screen s1
                                 WHERE nvl(s1.id_rep_screen, -1) = nvl(td.id_rep_screen, -1)
                                   AND s1.flg_type = c_flg_remove
                                   AND s1.screen_name = i_screen_name
                                   AND (s1.id_sys_button_prop = i_sys_button_prop OR s1.id_sys_button_prop IS NULL)))) tbl_res
         ORDER BY tbl_res.rank;
    
        --close this cursor since it is no longer needed
        IF l_id_reports_list2%ISOPEN
        THEN
            CLOSE l_id_reports_list2;
        END IF;
    
        RETURN l_get_rep_list;
    
    END get_reports_list_pl;

    /********************************************************************************************
    * Get the identification of the report available on a specific are and for a specific action
    *
    * @param i_lang                       Language id
    * @param i_prof                       Professional id
    * @param i_flg_action                 Action to filter
    * @param i_screen_name                Name of the screen
    *
    * @return id of the report
    * @author ricardo.pires
    * @version 1.0
    * @since 22-10-2011
    ********************************************************************************************/

    FUNCTION get_id_report
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_action  IN reports.flg_action%TYPE,
        i_screen_name IN rep_screen.screen_name%TYPE
    ) RETURN NUMBER IS
        l_message           debug_msg;
        l_rep_prof_template rep_prof_template.id_rep_prof_template%TYPE;
        l_market            market.id_market%TYPE;
        l_id_reports        reports.id_reports%TYPE;
    
        l_config t_config;
    
    BEGIN
        l_message := 'get market id';
        pk_alertlog.log_info(text => l_message, object_name => g_package_name, sub_object_name => 'GET_REPORTS_LIST');
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        l_message := 'get reports id';
        SELECT DISTINCT rptd.id_reports
          INTO l_id_reports
          FROM rep_screen rs, rep_profile_template_det rptd, reports r
         WHERE rs.screen_name = i_screen_name
           AND rptd.id_rep_screen = rs.id_rep_screen
           AND rptd.id_reports = r.id_reports
           AND r.flg_action = i_flg_action;
    
        RETURN l_id_reports;
    EXCEPTION
        WHEN too_many_rows THEN
            l_config := pk_core_config.get_config(i_area             => pk_blood_products_constant.g_bp_special_type_area,
                                                  i_prof             => i_prof,
                                                  i_market           => l_market,
                                                  i_category         => pk_prof_utils.get_id_category(i_lang => i_lang,
                                                                                                      i_prof => i_prof),
                                                  i_profile_template => pk_prof_utils.get_prof_profile_template(i_prof => i_prof),
                                                  i_prof_dcs         => NULL,
                                                  i_episode_dcs      => NULL);
        
            SELECT DISTINCT rptd.id_reports
              INTO l_id_reports
              FROM rep_screen rs
              JOIN rep_profile_template_det rptd
                ON rptd.id_rep_screen = rs.id_rep_screen
              JOIN reports r
                ON rptd.id_reports = r.id_reports
              JOIN v_automatic_report t
                ON t.id_reports = r.id_reports
               AND t.screen_name = rs.screen_name
               AND t.flg_action = r.flg_action
             WHERE rs.screen_name = i_screen_name
               AND r.flg_action = i_flg_action;
        
            RETURN l_id_reports;
        
    END get_id_report;

    /**
    * Get new print arguments to the reports that need to be regenerated
    *
    * @param   i_lang                      Preferred language id for this professional
    * @param   i_prof                      Professional id structure
    * @param   i_print_list_job            Array of print list job identifiers
    * @param   i_print_list_area           Array of print list area identifiers
    * @param   i_epis_report               Array of epis report identifiers
    * @param   i_print_arguments           Array of print arguments
    * @param   o_print_list_job            Array of print list job identifiers
    * @param   o_print_list_area           Array of print list area identifiers
    * @param   o_epis_report               Array of epis report identifiers
    * @param   o_print_arguments           Array of print arguments
    * @param   o_flg_regenerate_report     Array of flags indicating if the reports need to be regenerated or not
    * @param   o_error                     Error information
    *
    * @value   o_flg_regenerate_report     {*} Y- report needs to be regenerated {*} N- otherwise
    *
    * @return  boolean                     True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @since   27-10-2014
    */

    FUNCTION get_print_args_to_regen_report
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_print_list_job        IN table_number,
        i_print_list_area       IN table_number,
        i_epis_report           IN table_number,
        i_print_arguments       IN table_varchar,
        o_print_list_job        OUT table_number,
        o_print_list_area       OUT table_number,
        o_epis_report           OUT table_number,
        o_print_arguments       OUT table_varchar,
        o_flg_regenerate_report OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'get_print_args_to_regen_report';
        l_params   VARCHAR2(4000);
        l_num_jobs NUMBER;
        l_exception_np EXCEPTION;
        l_retval BOOLEAN;
    
    BEGIN
    
        l_params := 'i_lang=' || i_lang || 'i_prof=' || pk_utils.to_string(i_prof) || ' i_print_list_job=' ||
                    pk_utils.to_string(i_print_list_job) || ' i_print_list_area=' ||
                    pk_utils.to_string(i_print_list_area) || ' i_epis_report=' || pk_utils.to_string(i_epis_report) ||
                    ' i_print_arguments.count=' || i_print_arguments.count;
    
        -- init
        l_message := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => l_message, object_name => g_package_name, sub_object_name => l_func_name);
        END IF;
    
        --
        l_num_jobs := i_print_list_job.count;
        --
        o_print_list_job        := i_print_list_job;
        o_print_list_area       := i_print_list_area;
        o_epis_report           := i_epis_report;
        o_print_arguments       := i_print_arguments;
        o_flg_regenerate_report := table_varchar();
        o_flg_regenerate_report.extend(l_num_jobs);
    
        -- func
        FOR i IN 1 .. l_num_jobs
        LOOP
        
            -- check if report needs to be regenerated according to the area to which belongs to
            CASE i_print_list_area(i)
                WHEN pk_print_list_db.g_print_list_area_ref THEN
                    -- this report needs to be regenerated
                    l_retval := pk_ref_ext_sys.get_print_args_to_regen_report(i_lang                  => i_lang,
                                                                              i_prof                  => i_prof,
                                                                              io_print_arguments      => o_print_arguments(i),
                                                                              o_flg_regenerate_report => o_flg_regenerate_report(i),
                                                                              o_error                 => o_error);
                    IF NOT l_retval
                    THEN
                        RAISE l_exception_np;
                    END IF;
                
                WHEN pk_print_list_db.g_print_list_area_med THEN
                    -- this report needs to be regenerated
                    l_retval := pk_ea_logic_medication.get_print_args_to_regen_report(i_lang                  => i_lang,
                                                                                      i_prof                  => i_prof,
                                                                                      io_print_arguments      => o_print_arguments(i),
                                                                                      o_flg_regenerate_report => o_flg_regenerate_report(i),
                                                                                      o_error                 => o_error);
                    IF NOT l_retval
                    THEN
                        RAISE l_exception_np;
                    END IF;
                
                ELSE
                    -- this report doesn't need to be regenerated
                    o_flg_regenerate_report(i) := pk_alert_constant.g_no;
                
            END CASE;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception_np THEN
            pk_alertlog.log_warn(l_message);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
    END get_print_args_to_regen_report;

    /**
    * Set a list of print jobs as completed
    *
    * @param   i_lang                      Preferred language id for this professional
    * @param   i_prof                      Professional id structure
    * @param   i_print_list_job            Array of print list job identifiers
    * @param   i_print_list_area           Array of print list area identifiers
    * @param   i_epis_report               Array of epis report identifiers
    * @param   o_print_list_job            Array of print list job identifiers
    * @param   o_error                     Error information
    *
    * @return  boolean                     True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @since   29-10-2014
    */

    FUNCTION set_print_jobs_complete
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_print_list_job  IN table_number,
        i_print_list_area IN table_number,
        i_epis_report     IN table_number,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'set_print_jobs_complete';
        l_params VARCHAR2(4000);
    
        l_count_jobs      NUMBER;
        l_print_list_jobs table_number;
    
        l_exception_np EXCEPTION;
        l_retval BOOLEAN;
    
    BEGIN
    
        l_params := 'i_lang=' || i_lang || 'i_prof=' || pk_utils.to_string(i_prof) || ' i_print_list_job=' ||
                    pk_utils.to_string(i_print_list_job) || ' i_print_list_area=' ||
                    pk_utils.to_string(i_print_list_area) || ' i_epis_report=' || pk_utils.to_string(i_epis_report);
    
        -- init
        l_message := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => l_message, object_name => g_package_name, sub_object_name => l_func_name);
        END IF;
    
        o_print_list_job := table_number();
        l_count_jobs     := i_print_list_job.count;
        o_print_list_job.extend(l_count_jobs);
    
        -- func
        FOR i IN 1 .. l_count_jobs
        LOOP
        
            CASE i_print_list_area(i)
                WHEN pk_print_list_db.g_print_list_area_ref THEN
                
                    -- Referral doesn't need to be notified
                    -- It was already done in PK_P1_MED_CS.SPLIT_MCDT_REQUEST_BY_GROUP()
                    NULL;
                
                ELSE
                    -- Set list jobs status to completed
                    l_retval := pk_print_list_db.set_print_jobs_complete(i_lang              => i_lang,
                                                                         i_prof              => i_prof,
                                                                         i_id_print_list_job => table_number(i_print_list_job(i)),
                                                                         o_id_print_list_job => l_print_list_jobs,
                                                                         o_error             => o_error);
                
                    IF NOT l_retval
                    THEN
                        RAISE l_exception_np;
                    END IF;
                
                    o_print_list_job(i) := l_print_list_jobs(1);
                
            END CASE;
        
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception_np THEN
            pk_alertlog.log_warn(l_message);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_print_jobs_complete;

    /**
    * Notify print jobs error
    *
    * @param   i_lang                      Preferred language id for this professional
    * @param   i_prof                      Professional id structure
    * @param   i_print_list_job            Array of print list job identifiers
    * @param   i_print_list_area           Array of print list area identifiers
    * @param   i_epis_report               Array of epis report identifiers
    * @param   o_print_list_job            Array of print list job identifiers
    * @param   o_error                     Error information
    *
    * @return  boolean                     True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @since   29-10-2014
    */

    FUNCTION set_print_jobs_error
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_print_list_job  IN table_number,
        i_print_list_area IN table_number,
        i_epis_report     IN table_number,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'set_print_jobs_error';
        l_params VARCHAR2(4000);
        l_exception_np EXCEPTION;
        l_retval BOOLEAN;
    
    BEGIN
    
        l_params := 'i_lang=' || i_lang || 'i_prof=' || pk_utils.to_string(i_prof) || ' i_print_list_job=' ||
                    pk_utils.to_string(i_print_list_job) || ' i_print_list_area=' ||
                    pk_utils.to_string(i_print_list_area) || ' i_epis_report=' || pk_utils.to_string(i_epis_report);
    
        -- init
        l_message := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => l_message, object_name => g_package_name, sub_object_name => l_func_name);
        END IF;
    
        -- func
    
        -- Set list jobs status to completed
        l_retval := pk_print_list_db.set_print_jobs_error(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_id_print_list_job => i_print_list_job,
                                                          o_id_print_list_job => o_print_list_job,
                                                          o_error             => o_error);
    
        IF NOT l_retval
        THEN
            RAISE l_exception_np;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception_np THEN
            pk_alertlog.log_warn(l_message);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_print_jobs_error;

    /**
    * Get the report logos for a market, institution and software
    *
    * @param   i_lang                      The id language
    * @param   i_professional              The professional identifier(id,institution,software)
    * @param   i_episode                   The id episode
    * @param   i_id_report                 The id reports
    * @param   i_id_institution_logo       The id of institution logo in institution_logo table
    * @param   i_id_institution_owner      The id of insitution, if is configured from alert have the value 0 other situations the id_institution
    * @param   i_id_institution            The id of institution
    * @param   o_logos                     Cursor with the logos for that market,institution,softoware and report
    * @param   o_result                    Returns if the report has been printed or not
    *
    * @return  boolean                     True on sucess, otherwise false
    *
    * @author  25-02-2015
    
    */

    FUNCTION get_report_logos
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN profissional,
        i_id_reports   IN reports.id_reports%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_logos        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market                NUMBER;
        l_config                   alert_core_tech.t_config;
        l_id_config                NUMBER;
        l_id_prof_cat              NUMBER;
        l_id_prof_profile_template NUMBER;
        l_prof_dcs                 table_number;
        i_episode_dcs              NUMBER;
        l_area                     VARCHAR2(200);
        l_message                  VARCHAR2(100);
        l_id_inst_owner            NUMBER;
        l_id_records               table_number;
        config_values              t_tbl_config_table;
        l_number_records           NUMBER := 0;
        l_id_institution           NUMBER;
    
        c_function_name VARCHAR2(20) := 'GET_REPORT_LOGOS';
    
    BEGIN
        l_area    := 'REP_GROUP_LOGOS';
        l_message := ' INIT GET_REPORT_LOGOS';
    
        pk_alertlog.log_debug(l_message);
    
        i_episode_dcs := NULL; /*Says that ignore this field*/
    
        l_id_prof_cat := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_professional);
    
        l_id_prof_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_professional);
    
        l_prof_dcs := pk_prof_utils.get_prof_dcs_list(i_lang => i_lang, i_prof => i_professional);
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_professional.institution);
    
        IF i_episode IS NOT NULL
        THEN
            SELECT e.id_institution
              INTO l_id_institution
              FROM episode e
             WHERE e.id_episode = i_episode;
        END IF;
    
        IF l_id_institution IS NULL
        THEN
            l_id_institution := i_professional.institution;
        END IF;
    
        l_config := pk_core_config.get_config(i_area             => l_area,
                                              i_prof             => i_professional,
                                              i_market           => l_id_market,
                                              i_category         => l_id_prof_cat,
                                              i_profile_template => l_id_prof_profile_template,
                                              i_prof_dcs         => l_prof_dcs,
                                              i_episode_dcs      => i_episode_dcs);
    
        IF l_config IS NOT NULL
        THEN
            l_id_config     := l_config.id_config;
            l_id_inst_owner := l_config.id_inst_owner;
        
            SELECT cfg_tbl.id_record
              BULK COLLECT
              INTO l_id_records
              FROM v_config_table cfg_tbl
             WHERE cfg_tbl.id_config = l_id_config
               AND cfg_tbl.id_inst_owner IN (l_id_inst_owner, 0) --alterar e colocar constante
             ORDER BY cfg_tbl.id_config DESC, cfg_tbl.id_inst_owner DESC;
        
            IF l_id_records IS NOT NULL
               AND l_id_records.count > 0
            THEN
            
                config_values := pk_core_config.get_values(i_record           => l_id_records(1),
                                                           i_area             => l_area,
                                                           i_prof             => i_professional,
                                                           i_market           => l_id_market,
                                                           i_category         => l_id_prof_cat,
                                                           i_profile_template => l_id_prof_profile_template,
                                                           i_prof_dcs         => l_prof_dcs,
                                                           i_episode_dcs      => i_episode_dcs);
            END IF;
        
            IF config_values IS NOT NULL
               AND config_values.count > 0
            THEN
            
                SELECT COUNT(*)
                  INTO l_number_records
                  FROM TABLE(config_values) cv1
                 INNER JOIN rep_group_logos ril
                    ON cv1.field_01 = ril.id_rep_group_logos
                 INNER JOIN rep_logos rl
                    ON ril.id_rep_group_logos = rl.id_rep_group_logos
                 WHERE cv1.config_table = l_area
                   AND cv1.id_record = i_id_reports;
            
                IF (l_number_records = 0)
                THEN
                    o_logos := NULL;
                    pk_alertlog.log_debug(text => 'NO CONFIGURATIONS SET WITH REP_INSTITUTION_LOGO');
                ELSE
                
                    OPEN o_logos FOR
                        SELECT rl.id_rep_logos,
                               pk_translation.get_translation(i_lang => i_lang, i_code_mess => l_id_institution) AS inst_name,
                               rl.internal_name,
                               g_rep_inst_logo_logic AS config_logic,
                               rl.id_rep_logos AS id_institution_logo
                          FROM TABLE(config_values) cv1
                         INNER JOIN rep_group_logos ril
                            ON cv1.field_01 = ril.id_rep_group_logos
                         INNER JOIN rep_logos rl
                            ON ril.id_rep_group_logos = rl.id_rep_group_logos
                         WHERE cv1.config_table = l_area
                           AND cv1.id_record = i_id_reports
                           AND rl.flg_available = pk_alert_constant.get_yes
                         ORDER BY rl.internal_name;
                
                END IF;
            
            ELSE
                pk_alertlog.log_debug(text => 'MISSING CONFIG TABLE CONFIGURATION');
                o_logos := NULL;
                RETURN TRUE;
            
            END IF;
        
        ELSE
            pk_alertlog.log_debug(text => 'MISSING CONFIG TABLE CONFIGURATION');
            o_logos := NULL;
            RETURN TRUE;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_logos);
            RETURN FALSE;
        
    END get_report_logos;

    /**
    * Get the report configurations for a market, institution and software
    *
    * @param   i_lang                      The id language
    * @param   i_professional              The professional identifier(id,institution,software)
    * @param   i_episode                   The id episode
    * @param   i_id_report                 The id reports
    * @param   o_logos                     Cursor with the logos for that market,institution,softoware and report
    * @param   o_result                    Returns if the report has been printed or not
    *
    * @return  boolean                     True on sucess, otherwise false
    *
    * @author  25-02-2015
    
    */

    FUNCTION get_institution_logos
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN profissional,
        i_id_reports   IN reports.id_reports%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_logos        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        ret_val               BOOLEAN;
        l_result_img_banners  BOOLEAN;
        l_inst_logo           institution_logo.img_logo%TYPE;
        l_inst_banner         institution_logo.img_banner%TYPE;
        l_inst_banner_small   institution_logo.img_banner_small%TYPE;
        l_institution_name    VARCHAR2(300);
        l_cursor_logos        pk_types.cursor_type;
        l_message             VARCHAR2(100);
        c_function_name       VARCHAR(30) := 'GET_INSTITUTION_LOGOS';
        l_id_institution_logo institution_logo.id_institution_logo%TYPE;
    
    BEGIN
        l_message := ' INIT GET_INSTITUTION_LOGOS';
    
        pk_alertlog.log_debug(l_message);
    
        ret_val := get_report_logos(i_lang         => i_lang,
                                    i_professional => i_professional,
                                    i_id_reports   => i_id_reports,
                                    i_episode      => i_episode,
                                    o_logos        => l_cursor_logos,
                                    o_error        => o_error);
    
        IF l_cursor_logos IS NOT NULL
        THEN
            l_message := ' l_cursor_logos has' || l_cursor_logos%ROWCOUNT || 'logos';
            pk_alertlog.log_debug(l_message);
            o_logos := l_cursor_logos;
            RETURN ret_val;
        ELSE
            l_message := ' l_cursor_logos is null';
            pk_alertlog.log_debug(l_message);
        
            l_result_img_banners := get_institution_img_banners(i_lang                => i_lang,
                                                                i_prof                => i_professional,
                                                                i_episode             => i_episode,
                                                                o_inst_logo           => l_inst_logo,
                                                                o_inst_banner         => l_inst_banner,
                                                                o_inst_banner_small   => l_inst_banner_small,
                                                                o_inst_name           => l_institution_name,
                                                                o_id_institution_logo => l_id_institution_logo,
                                                                o_error               => o_error);
        
            OPEN o_logos FOR
                SELECT l_id_institution_logo AS id_institution_logo,
                       l_institution_name AS inst_name,
                       'DEFAULT' AS internal_name,
                       g_rep_inst_logo_no_logic AS config_logic
                  FROM dual;
        
            RETURN l_result_img_banners;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_logos);
            RETURN FALSE;
        
    END get_institution_logos;

    /**
    * Get the report logos for a market, institution and software by default method
    *
    * @param   i_lang                      The id language
    * @param   i_professional              The professional identifier(id,institution,software)
    * @param   i_episode                   The id episode
    * @param   i_id_report                 The id reports
    * @param   o_logos                     Cursor with the logos for that market,institution,softoware and report
    * @param   o_result                    Returns if the report has been printed or not
    *
    * @return  boolean                     True on sucess, otherwise false
    *
    * @author  25-02-2015
    
    */

    FUNCTION get_institution_logos_det
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution_logo IN institution_logo.id_institution_logo%TYPE,
        o_inst_logo           OUT institution_logo.img_logo%TYPE,
        o_inst_banner         OUT institution_logo.img_banner%TYPE,
        o_inst_banner_small   OUT institution_logo.img_banner_small%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message       VARCHAR2(100);
        c_function_name VARCHAR(30) := 'get_institution_logos_det';
    
    BEGIN
        IF i_id_institution_logo IS NOT NULL
        THEN
            SELECT il.img_banner, il.img_banner_small, il.img_logo
              INTO o_inst_banner, o_inst_banner_small, o_inst_logo
              FROM institution_logo il
             WHERE il.id_institution_logo = i_id_institution_logo;
        
            o_inst_banner       := pk_tech_utils.set_empty_blob(o_inst_banner);
            o_inst_banner_small := pk_tech_utils.set_empty_blob(o_inst_banner_small);
            o_inst_logo         := pk_tech_utils.set_empty_blob(o_inst_logo);
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_institution_logos_det;

    /**
    * Get the report logos for a market, institution and software by configuration table�s method
    *
    * @param   i_lang                      The id language
    * @param   i_professional              The professional identifier(id,institution,software)
    * @param   i_episode                   The id episode
    * @param   i_id_report                 The id reports
    * @param   o_logos                     Cursor with the logos for that market,institution,softoware and report
    * @param   o_result                    Returns if the report has been printed or not
    *
    * @return  boolean                     True on sucess, otherwise false
    *
    * @author  25-02-2015
    
    */

    FUNCTION get_inst_logos_by_config_table
    (
        i_lang        IN language.id_language%TYPE,
        i_id_rep_logo IN rep_logos.id_rep_logos%TYPE,
        o_logo        OUT rep_logos.image_logo%TYPE,
        o_error       OUT t_error_out
    )
    
     RETURN BOOLEAN IS
        l_message       VARCHAR2(100);
        c_function_name VARCHAR(30) := 'get_inst_logos_by_config_table';
    
    BEGIN
        IF i_id_rep_logo IS NOT NULL
        THEN
        
            SELECT rl.image_logo
              INTO o_logo
              FROM rep_logos rl
             WHERE rl.id_rep_logos = i_id_rep_logo;
        
            o_logo := pk_tech_utils.set_empty_blob(o_logo);
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_inst_logos_by_config_table;

    /********************************************************************************************
     * Gets the parameters for HIE
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_id_report              ID REPORT
     *
     * @param o_parameters             List of parameters
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Ruben Araujo
     * @version                         1.0
     * @since                           2016/05/18
    **********************************************************************************************/

    FUNCTION get_hie_parameters
    (
        i_lang       IN language.id_language%TYPE,
        i_id_report  IN NUMBER,
        o_parameters OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
    
    BEGIN
    
        l_message := 'GET HIE PARAMETERS';
        pk_alertlog.log_debug(l_message);
        OPEN o_parameters FOR
            SELECT r.id_reports,
                   nvl(pk_translation.get_translation(i_lang, r.code_reports_title),
                       pk_translation.get_translation(i_lang, r.code_reports)) id_reports_desc,
                   dt.id_doc_type,
                   pk_translation.get_translation(i_lang, dt.code_doc_type) id_doc_type_desc,
                   dot.id_doc_ori_type,
                   pk_translation.get_translation(i_lang, dot.code_doc_ori_type) id_doc_ori_type_desc
              FROM reports r
              JOIN rep_ins_soft_doc_type sdt
                ON r.id_reports = sdt.id_reports
              JOIN doc_type dt
                ON dt.id_doc_type = sdt.id_doc_type
              JOIN doc_ori_type dot
                ON dot.id_doc_ori_type = sdt.id_doc_ori_type
             WHERE r.id_reports = i_id_report
               AND sdt.flg_print_type = 'D';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HIE_PARAMETERS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_parameters);
            RETURN FALSE;
        
    END get_hie_parameters;

    FUNCTION get_date_for_reports
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN alert.profissional,
        o_dt_begin OUT VARCHAR2,
        o_dt_end   OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_current TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_num_days NUMBER := pk_sysconfig.get_config('MEDICATION_INPATIENT_REPORT_MAX_DAYS', i_prof);
    BEGIN
    
        l_dt_current := current_timestamp;
        g_error      := 'get_dates';
    
        o_dt_begin := pk_date_utils.date_send_tsz(i_lang, l_dt_current, i_prof);
        o_dt_end   := pk_date_utils.date_send_tsz(i_lang, (l_dt_current + l_num_days), i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DATE_FOR_REPORTS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_date_for_reports;

    FUNCTION get_services_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_reports    IN reports.id_reports%TYPE,
        o_info_services OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_PATIENTS_LIST';
    BEGIN
        IF i_id_reports = g_id_report_med_list_adm
        THEN
            -- Medication - list of services with prescriptions to be administered
            g_error := 'CALL pk_reports_medication_api.get_admin_services';
            IF NOT pk_reports_medication_api.get_admin_services(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                o_info_services => o_info_services,
                                                                o_error         => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_other_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_info_services);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_info_services);
            RETURN FALSE;
    END get_services_list;

    FUNCTION get_patients_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_reports    IN reports.id_reports%TYPE,
        i_id_department IN table_number,
        o_info_patients OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_PATIENTS_LIST';
    BEGIN
        IF i_id_reports = g_id_report_med_list_adm
        THEN
            -- Medication - list of patients with prescriptions to be administered by service
            g_error := 'CALL pk_reports_medication_api.get_admin_patients';
            IF NOT pk_reports_medication_api.get_admin_patients(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                i_id_department => i_id_department,
                                                                o_info_patients => o_info_patients,
                                                                o_error         => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_other_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_info_patients);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_info_patients);
            RETURN FALSE;
    END get_patients_list;

    FUNCTION set_epis_report_dynamic_code
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_report IN epis_report.id_epis_report%TYPE,
        i_json_params IN epis_report.json_params%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_dynamic_title reports.flg_dynamic_title%TYPE;
        l_json_parmeter     epis_report.json_params%TYPE;
    
        l_id_aux NUMBER(24);
    
        l_code_dynamic_title epis_report.code_dynamic_title%TYPE := NULL;
    BEGIN
    
        g_error := 'ERROR GETTING FLG_DYNAMIC_TITLE';
        BEGIN
            SELECT r.flg_dynamic_title
              INTO l_flg_dynamic_title
              FROM epis_report er
              JOIN reports r
                ON r.id_reports = er.id_reports
             WHERE er.id_epis_report = i_epis_report;
        EXCEPTION
            WHEN OTHERS THEN
                l_flg_dynamic_title := NULL;
        END;
    
        IF l_flg_dynamic_title = 'S'
        THEN
            IF i_json_params IS NOT NULL
            THEN
                l_json_parmeter := i_json_params;
            ELSE
                BEGIN
                    SELECT er_parent.json_params
                      INTO l_json_parmeter
                      FROM epis_report er
                      JOIN epis_report er_parent
                        ON er_parent.id_epis_report = er.id_epis_parent
                     WHERE er.id_epis_report = i_epis_report;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_json_parmeter := NULL;
                END;
            END IF;
        
            IF l_json_parmeter IS NOT NULL
            THEN
                g_error := 'ERROR GETTING NOTE_ID';
                BEGIN
                    SELECT note_id
                      INTO l_id_aux
                      FROM json_table(l_json_parmeter, '$' columns note_id NUMBER(24) path '$.NOTE_ID');
                EXCEPTION
                    WHEN OTHERS THEN
                        l_id_aux := NULL;
                END;
            
                IF l_id_aux IS NOT NULL
                THEN
                    BEGIN
                        SELECT pnt.code_pn_note_type
                          INTO l_code_dynamic_title
                          FROM epis_pn ep
                          JOIN pn_note_type pnt
                            ON pnt.id_pn_note_type = ep.id_pn_note_type
                         WHERE ep.id_epis_pn = l_id_aux;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_code_dynamic_title := NULL;
                    END;
                END IF;
            END IF;
        END IF;
    
        IF l_code_dynamic_title IS NOT NULL
        THEN
            UPDATE epis_report er
               SET er.code_dynamic_title = l_code_dynamic_title
             WHERE er.id_epis_report = i_epis_report;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_EPIS_REPORT_DYNAMIC_CODE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_report_dynamic_code;
BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_print_tool;
/
