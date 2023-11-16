/*-- Last Change Revision: $Rev: 2026904 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:21 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_core IS

    k_default_code_epis_ext CONSTANT VARCHAR2(0010 CHAR) := 'XXX';

    /** @headcom
    * Private Function. Returns ALERT default market .
    *
    * @return     number
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2010/01/12
    */
    FUNCTION get_default_market RETURN NUMBER IS
    BEGIN
        RETURN 0;
    END get_default_market;

    FUNCTION return_row_n
    (
        i_tbl  IN table_number,
        i_else IN NUMBER DEFAULT NULL
    ) RETURN NUMBER IS
        l_return NUMBER(24);
    BEGIN
    
        IF i_tbl.count > 0
        THEN
            l_return := i_tbl(1);
        ELSE
            IF i_else IS NOT NULL
            THEN
                l_return := i_else;
            END IF;
        END IF;
    
        RETURN l_return;
    
    END return_row_n;

    FUNCTION return_row_v
    (
        i_tbl  IN table_varchar,
        i_else IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        IF i_tbl.count > 0
        THEN
            l_return := i_tbl(1);
        ELSE
            IF i_else IS NOT NULL
            THEN
                l_return := i_else;
            END IF;
        END IF;
    
        RETURN l_return;
    
    END return_row_v;

    /** @headcom
    * Public Function. Returns market for given institution.
    *
    * @param      I_institution              ID of instituition
    *
    * @return     number
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2009/11/04
    */
    FUNCTION get_inst_mkt(i_id_institution IN institution.id_institution%TYPE) RETURN market.id_market%TYPE result_cache relies_on(institution) IS
        l_id_market market.id_market%TYPE;
        tbl_market  table_number;
    BEGIN
    
        -- Get market of institution
        SELECT id_market
          BULK COLLECT
          INTO tbl_market
          FROM institution
         WHERE id_institution = i_id_institution;
    
        l_id_market := return_row_n(tbl_market, get_default_market());
    
        RETURN l_id_market;
    
    END get_inst_mkt;
    -- ######################################################################

    FUNCTION get_string_task
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN VARCHAR2, --NEW: task type
        i_epis_status IN episode.flg_status%TYPE,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP,
        i_dt_req      IN TIMESTAMP,
        i_icon_name   IN VARCHAR2,
        o_error       OUT VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_return    VARCHAR2(0200 CHAR);
        l_scheduled VARCHAR2(0020 CHAR);
        --l_dt_req    VARCHAR2(0200 CHAR);
        l_dt_begin VARCHAR2(0200 CHAR);
    
        k_icon_msg CONSTANT VARCHAR2(0100 CHAR) := 'ICON_T056';
        k_mask     CONSTANT VARCHAR2(0100 CHAR) := 'YYYYMMDDHH24MISS TZR';
        k_xxx      CONSTANT VARCHAR2(0100 CHAR) := 'xxxxxxxxxxxxxx';
    
        k_flg_status_f  CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_flg_status_f; --finished
        k_flg_status_fp CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_flg_status_fp; --partially finished  
        k_flg_status_e  CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_flg_status_e; --in execution  
        k_flg_status_d  CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_flg_status_d; --pending
        --k_flg_status_l     CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_flg_status_l; --result read
        k_flg_status_nexec CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_flg_status_nexec; --not executed
        k_flg_status_r     CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_flg_status_r; -- requested
        k_flg_status_a     CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_flg_status_a; --administred
    
        k_inactive   CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_inactive;
        k_flg_time_b CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_flg_time_b;
        k_flg_time_n CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_flg_time_n;
        k_flg_time_e CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_flg_time_e;
    
        FUNCTION f_no_color_icon(i_icon_name IN VARCHAR2) RETURN VARCHAR2 IS
        BEGIN
            RETURN k_xxx || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
        END f_no_color_icon;
    
        FUNCTION f_dt_begin(i_dt_begin IN VARCHAR2) RETURN VARCHAR2 IS
        BEGIN
            RETURN i_dt_begin || '|' || g_date || '|' || g_no_color;
        END f_dt_begin;
    
        FUNCTION f_scheduled
        (
            i_scheduled IN VARCHAR2,
            i_color     IN VARCHAR2
        ) RETURN VARCHAR2 IS
        BEGIN
            RETURN k_xxx || '|' || g_text || '|' || i_color || '|' || i_scheduled;
        END f_scheduled;
    
    BEGIN
    
        l_scheduled := pk_message.get_message(i_lang, k_icon_msg); --'AGENDADO'
    
        --l_dt_req   := pk_date_utils.to_char_insttimezone(i_prof, i_dt_req, k_mask);
        l_dt_begin := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, k_mask);
    
        g_error := 'GET V_OUT STRING';
        <<case_flg_time>>CASE i_flg_time
            WHEN k_flg_time_e THEN
                -- to be executed in this episode
            
                <<case_inside_1>>CASE
                    WHEN i_flg_status IN
                         (k_flg_status_f, k_flg_status_fp, k_flg_status_e) THEN
                        l_return := f_no_color_icon(i_icon_name);
                    
                    WHEN i_flg_status IN (k_flg_status_r,
                                          k_flg_status_a,
                                          k_flg_status_d,
                                          k_flg_status_nexec) THEN
                        IF i_dt_begin IS NULL --requested in another episode with execution type = next episode
                        THEN
                            l_return := f_scheduled(l_scheduled, g_color_red);
                        ELSE
                            l_return := f_dt_begin(l_dt_begin);
                        END IF;
                    ELSE
                        --i_flg_status = k_flg_status_l --result read
                    
                        l_return := NULL;
                END CASE case_inside_1; -- I_FLG_STATUS
        
            WHEN k_flg_time_n THEN
                --next episode
            
                l_return := f_scheduled(l_scheduled, g_color_green);
                IF i_epis_status = k_inactive --inactive episode
                THEN
                    IF i_dt_begin IS NOT NULL
                    THEN
                        --requested in another episode with execution type = next episode
                        l_return := f_dt_begin(l_dt_begin);
                    END IF;
                END IF;
            
            WHEN k_flg_time_b THEN
                --between episodes
            
                <<case_inside_2>>CASE
                    WHEN i_flg_status IN (k_flg_status_d, k_flg_status_nexec) THEN
                    
                        l_return := f_dt_begin(l_dt_begin);
                        IF i_dt_begin IS NULL --for lab tests and exams (if FLG_TIME=B then DT_BEGIN=NULL)
                        THEN
                            l_return := f_scheduled(l_scheduled,
                                                    g_color_green);
                        END IF;
                    
                    WHEN i_flg_status IN (k_flg_status_r, k_flg_status_a) THEN
                        l_return := f_dt_begin(l_dt_begin);
                    
                    WHEN i_flg_status IN (k_flg_status_f) --finished
                     THEN
                        l_return := f_no_color_icon(i_icon_name);
                    ELSE
                        l_return := NULL;
                END CASE case_inside_2;
            
        END CASE case_flg_time;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || 'PK_GRID.GET_STRING_TASK / ' ||
                       g_error || ' / ' || SQLERRM;
            RETURN NULL;
    END get_string_task;

    /** @headcom
    * Public Function. Returns disclaimer for given market.
    *
    * @param      I_LANG              language configured
    * @param      I_PROF              object (ID of professional, ID of instituition, ID of software)
    * @param      O_txt_disclaimer    disclaimer text returned
    * @param      O_ERROR             erro
    *
    * @return     boolean
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2006/10/16
    */

    FUNCTION get_disclaimer
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_txt_disclaimer      OUT VARCHAR2,
        o_copyright           OUT VARCHAR2,
        o_version             OUT VARCHAR2,
        o_version_label       OUT VARCHAR2,
        o_disclaimer_duration OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        -- Local constants
        l_prescription_sentence_cfg  CONSTANT sys_config.id_sys_config%TYPE := 'PRESCRIPTION_SENTENCE';
        l_market_disclaimer_cfg      CONSTANT sys_config.id_sys_config%TYPE := 'MARKET_DISCLAIMER';
        l_copyright_code_msg         CONSTANT sys_message.code_message%TYPE := 'COPYRIGHT_M001';
        l_version_label_code_msg     CONSTANT sys_message.code_message%TYPE := 'VERSION_LABEL';
        l_disclaimer_duration_config CONSTANT sys_config.id_sys_config%TYPE := 'DISCLAIMER_DURATION';
    
        -- Local variables
        l_function_name       VARCHAR2(50 CHAR);
        l_flg_show_disclaimer sys_config.value%TYPE;
        l_config              VARCHAR2(1000 CHAR);
        e_call EXCEPTION;
    
        l_version VARCHAR2(200 CHAR);
        l_date    VARCHAR2(200 CHAR);
    
    BEGIN
    
        g_error               := 'get flg to show disclaimer';
        l_flg_show_disclaimer := pk_sysconfig.get_config(l_prescription_sentence_cfg, i_prof);
    
        o_txt_disclaimer := NULL;
        IF l_flg_show_disclaimer = pk_alert_constant.g_yes
        THEN
        
            g_error  := 'get disclaimer from market';
            l_config := pk_sysconfig.get_config(i_code_cf => l_market_disclaimer_cfg, i_prof => i_prof);
        
            g_error          := 'get config from market';
            o_txt_disclaimer := pk_message.get_message(i_lang, i_prof, l_config);
        
            --invoke medication function
            pk_api_pfh_in.get_std_version_date(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               o_id_version   => l_version,
                                               o_publish_date => l_date);
        
            --replace variables in function
            o_txt_disclaimer := REPLACE(o_txt_disclaimer, '@version@', l_version);
            o_txt_disclaimer := REPLACE(o_txt_disclaimer, '@date@', l_date);
        
        END IF;
    
        g_error := 'get copyright';
        IF NOT finger_db.pk_login_message.get_copyright(i_lang, l_copyright_code_msg, o_copyright, o_version)
        THEN
            RAISE e_call;
        END IF;
    
        g_error         := 'get version label';
        o_version_label := pk_message.get_message(i_lang, i_prof, l_version_label_code_msg);
    
        g_error               := 'get disclaimer duration config';
        o_disclaimer_duration := to_number(pk_sysconfig.get_config(l_disclaimer_duration_config, i_prof));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              g_error || '-' || SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
        
    END get_disclaimer;

    FUNCTION get_code_epis_ext
    (
        i_lang         IN language.id_language%TYPE,
        i_id_epis_type IN epis_type.id_epis_type%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(0200 CHAR);
        tbl_code table_varchar;
    BEGIN
    
        pk_alertlog.log_debug('1º GET COD_EPIS_TYPE_EXT :' || to_char(i_id_epis_type));
        SELECT cod_epis_type_ext
          BULK COLLECT
          INTO tbl_code
          FROM epis_type
         WHERE id_epis_type = i_id_epis_type;
    
        l_return := return_row_v(tbl_code, get_default_code_epis_ext);
    
        RETURN l_return;
    
    END get_code_epis_ext;

    FUNCTION get_default_code_epis_ext RETURN VARCHAR2 IS
    BEGIN
        RETURN k_default_code_epis_ext;
    END get_default_code_epis_ext;

    FUNCTION get_logtext
    (
        i_prof  IN profissional,
        i_lcall IN NUMBER,
        o_log   OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
        l_prf  profile_template%ROWTYPE;
        l_mkt  market.id_market%TYPE;
        l_text CLOB;
        FUNCTION get_ltext(i_lcall IN NUMBER) RETURN CLOB IS
            tbl_text table_clob;
            --l_text   CLOB;
            k_error_level CONSTANT NUMBER(24) := 30;
        BEGIN
        
            SELECT ltexte
              BULK COLLECT
              INTO tbl_text
              FROM tlog
             WHERE lcall = i_lcall
               AND llevel <= k_error_level
             ORDER BY ldate ASC, lhsecs ASC;
        
            IF tbl_text.count > 0
            THEN
                RETURN tbl_text(1);
            ELSE
                RETURN NULL;
            END IF;
        
        END get_ltext;
    
    BEGIN
    
        l_prf  := pk_access.get_profile(i_prof);
        l_text := get_ltext(i_lcall);
        l_mkt  := get_inst_mkt(i_prof.institution);
    
        OPEN o_log FOR
            SELECT id_profile_template || '/' || intern_name_templ profile, l_text text_error, l_mkt market
              FROM profile_template
             WHERE id_profile_template = l_prf.id_profile_template;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_logtext;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

    g_icon        := 'I';
    g_message     := 'M';
    g_color_red   := 'R';
    g_color_green := 'G';
    g_no_color    := 'X';

    g_text := 'T';
    g_date := 'D';

END pk_core;
/
