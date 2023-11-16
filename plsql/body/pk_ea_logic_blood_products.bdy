/*-- Last Change Revision: $Rev: 2043880 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-08-04 10:37:31 +0100 (qui, 04 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_blood_products IS

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    PROCEDURE get_data_rowid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_table_name IN VARCHAR,
        i_rowids     IN table_varchar,
        o_rowids     OUT table_varchar
    ) IS
        l_error_out t_error_out;
    BEGIN
    
        IF i_table_name = 'BLOOD_PRODUCT_REQ'
        THEN
            SELECT bpd.rowid
              BULK COLLECT
              INTO o_rowids
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_req IN
                   (SELECT bpr.id_blood_product_req
                      FROM blood_product_req bpr
                     WHERE bpr.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                          column_value
                                           FROM TABLE(i_rowids) t));
        
        ELSIF i_table_name = 'BLOOD_PRODUCT_DET'
        THEN
            o_rowids := i_rowids;
        ELSIF i_table_name = 'BLOOD_PRODUCT_DET_ALL'
        THEN
        
            SELECT bpd.rowid
              BULK COLLECT
              INTO o_rowids
              FROM blood_product_det bpd
             WHERE bpd.id_blood_product_req IN
                   (SELECT bpd.id_blood_product_req
                      FROM blood_product_det bpd
                     WHERE bpd.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                          column_value
                                           FROM TABLE(i_rowids) t));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DATA_ROWID',
                                              l_error_out);
        
            o_rowids := table_varchar();
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_data_rowid;

    PROCEDURE get_data_rowid_harvest
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_table_name IN VARCHAR,
        i_rowids     IN table_varchar,
        o_rowids     OUT table_varchar
    ) IS
    
        l_error_out t_error_out;
    
    BEGIN
    
        IF i_table_name = 'ANALYSIS_REQ'
        THEN
            SELECT /*+rule*/
             ard.rowid
              BULK COLLECT
              INTO o_rowids
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req IN (SELECT ar.id_analysis_req
                                             FROM analysis_req ar
                                            WHERE ar.rowid IN (SELECT column_value
                                                                 FROM TABLE(i_rowids)));
        
        ELSIF i_table_name = 'ANALYSIS_REQ_DET'
        THEN
            o_rowids := i_rowids;
        
        ELSIF i_table_name = 'ANALYSIS_HARVEST'
        THEN
            SELECT /*+rule*/
             ard.rowid
              BULK COLLECT
              INTO o_rowids
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det IN (SELECT ah.id_analysis_req_det
                                                 FROM analysis_harvest ah
                                                WHERE ah.rowid IN (SELECT column_value
                                                                     FROM TABLE(i_rowids)));
        ELSIF i_table_name = 'HARVEST'
        THEN
            SELECT /*+rule*/
             ard.id_analysis_req_det
              BULK COLLECT
              INTO o_rowids
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det IN (SELECT ah.id_analysis_req_det
                                                 FROM analysis_harvest ah, harvest h
                                                WHERE ah.id_harvest = h.id_harvest
                                                  AND h.rowid IN (SELECT column_value
                                                                    FROM TABLE(i_rowids)));
        ELSIF i_table_name = 'ANALYSIS_RESULT'
        THEN
            SELECT /*+rule*/
             ard.rowid
              BULK COLLECT
              INTO o_rowids
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det IN
                   (SELECT ares.id_analysis_req_det
                      FROM analysis_result ares
                     WHERE ares.rowid IN (SELECT column_value
                                            FROM TABLE(i_rowids)));
        
        ELSIF i_table_name = 'ANALYSIS_RESULT_PAR'
        THEN
            SELECT /*+rule*/
             ard.rowid
              BULK COLLECT
              INTO o_rowids
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det IN (SELECT ares.id_analysis_req_det
                                                 FROM analysis_result ares, analysis_result_par arp
                                                WHERE ares.id_analysis_result = arp.id_analysis_result
                                                  AND arp.rowid IN (SELECT column_value
                                                                      FROM TABLE(i_rowids)));
        
        ELSIF i_table_name = 'ANALYSIS_MEDIA_ARCHIVE'
        THEN
            SELECT /*+rule*/
             ard.rowid
              BULK COLLECT
              INTO o_rowids
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det IN (SELECT ama.id_analysis_req_det
                                                 FROM analysis_media_archive ama
                                                WHERE ama.rowid IN (SELECT column_value
                                                                      FROM TABLE(i_rowids)));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DATA_ROWID',
                                              l_error_out);
        
            o_rowids := table_varchar();
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_data_rowid_harvest;

    PROCEDURE get_bp_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN blood_products_ea.id_episode%TYPE,
        i_flg_time            IN blood_products_ea.flg_time%TYPE,
        i_flg_status_det      IN blood_products_ea.flg_status_det%TYPE,
        i_dt_blood_product    IN blood_products_ea.dt_blood_product%TYPE,
        i_dt_begin_req        IN blood_products_ea.dt_begin_req%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE,
        i_force_anc           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_status_str          OUT blood_products_ea.status_str%TYPE,
        o_status_msg          OUT blood_products_ea.status_msg%TYPE,
        o_status_icon         OUT blood_products_ea.status_icon%TYPE,
        o_status_flg          OUT blood_products_ea.status_flg%TYPE
    ) IS
    
        l_display_type  VARCHAR2(200) := '';
        l_back_color    VARCHAR2(200) := '';
        l_status_flg    VARCHAR2(200) := '';
        l_message_style VARCHAR2(200) := '';
        l_message_color VARCHAR2(200) := '';
        l_default_color VARCHAR2(200) := '';
        l_icon_color    VARCHAR2(200) := '';
    
        -- text 
        l_text VARCHAR2(200);
        -- icon
        l_aux VARCHAR2(200);
        -- date
        l_date_begin VARCHAR2(200);
    
        l_cat_prof   VARCHAR2(10 CHAR) := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        l_prof_tech  VARCHAR2(1 CHAR) := 'T';
        l_prof_other VARCHAR(1 CHAR) := 'O';
    
    BEGIN
        -- l_date_begin
        l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                           nvl(i_dt_begin_req, i_dt_blood_product),
                                                           pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
    
        l_aux := 'BLOOD_PRODUCT_DET.FLG_STATUS';
    
        l_text := l_aux;
    
        IF i_flg_status_det IN (pk_blood_products_constant.g_status_det_r_cc)
        THEN
            l_display_type := pk_alert_constant.g_display_type_date_icon;
        ELSIF i_flg_status_det = pk_blood_products_constant.g_status_det_r_sc
        THEN
            l_display_type := pk_alert_constant.g_display_type_icon;
        ELSE
            l_display_type := pk_alert_constant.g_display_type_icon;
        END IF;
    
        IF i_flg_status_det IN
           (pk_blood_products_constant.g_status_det_r_sc, pk_blood_products_constant.g_status_det_r_cc)
           AND l_cat_prof = l_prof_tech
           AND i_prof.software = pk_alert_constant.g_soft_labtech
        THEN
            l_display_type := pk_alert_constant.g_display_type_date_icon;
        END IF;
    
        IF (i_flg_status_det = pk_blood_products_constant.g_status_det_wt AND
           (l_cat_prof = l_prof_other OR i_force_anc = pk_alert_constant.g_yes))
           OR i_flg_status_det = pk_blood_products_constant.g_status_det_r_w
        THEN
            l_display_type := pk_alert_constant.g_display_type_date_icon;
        END IF;
    
        -- l_back_color
        IF i_flg_status_det IN
           (pk_blood_products_constant.g_status_det_c,
            pk_blood_products_constant.g_status_det_h,
            pk_blood_products_constant.g_status_det_d,
            pk_blood_products_constant.g_status_det_o,
            pk_blood_products_constant.g_status_det_f,
            pk_blood_products_constant.g_status_det_df,
            pk_blood_products_constant.g_status_det_r_sc,
            pk_blood_products_constant.g_status_det_ot,
            pk_blood_products_constant.g_status_det_br,
            pk_blood_products_constant.g_status_det_wr,
            pk_blood_products_constant.g_status_det_ns,
            pk_blood_products_constant.g_status_det_or,
            pk_blood_products_constant.g_status_det_cr,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_c,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_h,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_d,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_o,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_f,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_df,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_r_sc,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_ot,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_br)
           OR (i_flg_status_det = pk_blood_products_constant.g_status_det_wt AND l_cat_prof != l_prof_other)
        THEN
            l_back_color := pk_alert_constant.g_color_null;
        ELSE
            l_back_color := pk_alert_constant.g_color_red;
        END IF;
    
        IF l_display_type = pk_alert_constant.g_display_type_date_icon
        THEN
            IF nvl(i_dt_begin_req, i_dt_blood_product) <= current_timestamp
            THEN
                l_back_color := pk_alert_constant.g_color_red;
            ELSE
                l_back_color := pk_alert_constant.g_color_green;
            END IF;
        END IF;
    
        -- l_status_flg
    
        IF i_flg_status_det IN
           (pk_blood_products_constant.g_status_det_r_sc, pk_blood_products_constant.g_status_det_r_cc)
           AND l_cat_prof = l_prof_tech
           AND i_prof.software = pk_alert_constant.g_soft_labtech
        THEN
            l_status_flg := pk_blood_products_constant.g_status_det_r_w;
        ELSE
            l_status_flg := i_flg_status_det;
        END IF;
    
        --l_default_color (to allow for the siren to be shown in Red)
        IF i_flg_status_det IN
           (pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_ot,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_rt,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_o,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_h,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_d)
        THEN
            l_default_color := pk_alert_constant.g_yes;
        END IF;
    
        --l_icon_color
        IF i_flg_status_det IN
           (pk_blood_products_constant.g_status_det_rt,
            pk_blood_products_constant.g_status_det_x || pk_blood_products_constant.g_status_det_rt)
        THEN
            l_icon_color := '0xEBEBC8';
        END IF;
    
        pk_utils.build_status_string(i_display_type  => l_display_type,
                                     i_flg_state     => l_status_flg,
                                     i_value_text    => l_aux,
                                     i_value_date    => nvl(l_date_begin, l_aux),
                                     i_value_icon    => l_aux,
                                     i_back_color    => l_back_color,
                                     i_icon_color    => l_icon_color,
                                     i_message_style => l_message_style,
                                     i_message_color => l_message_color,
                                     i_default_color => l_default_color,
                                     o_status_str    => o_status_str,
                                     o_status_msg    => o_status_msg,
                                     o_status_icon   => o_status_icon,
                                     o_status_flg    => o_status_flg);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_bp_status;

    PROCEDURE get_bp_status_req
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN blood_products_ea.id_episode%TYPE,
        i_flg_time            IN blood_products_ea.flg_time%TYPE,
        i_flg_status_det      IN blood_products_ea.flg_status_det%TYPE,
        i_dt_blood_product    IN blood_products_ea.dt_blood_product%TYPE,
        i_dt_begin_req        IN blood_products_ea.dt_begin_req%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE,
        o_status_str          OUT blood_products_ea.status_str%TYPE,
        o_status_msg          OUT blood_products_ea.status_msg%TYPE,
        o_status_icon         OUT blood_products_ea.status_icon%TYPE,
        o_status_flg          OUT blood_products_ea.status_flg%TYPE
    ) IS
    
        l_display_type  VARCHAR2(200) := '';
        l_back_color    VARCHAR2(200) := '';
        l_status_flg    VARCHAR2(200) := '';
        l_message_style VARCHAR2(200) := '';
        l_message_color VARCHAR2(200) := '';
        l_default_color VARCHAR2(200) := '';
    
        -- text 
        l_text VARCHAR2(200);
        -- icon
        l_aux VARCHAR2(200);
        -- date
        l_date_begin VARCHAR2(200);
    
    BEGIN
        -- l_date_begin
        l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                           nvl(i_dt_begin_req, i_dt_blood_product),
                                                           pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
    
        l_aux := 'BLOOD_PRODUCT_REQ.FLG_STATUS';
    
        -- l_text
        l_text := l_aux;
    
        -- l_display_type
    
        l_display_type := pk_alert_constant.g_display_type_icon;
    
        -- l_back_color
    
        l_back_color := pk_alert_constant.g_color_null;
    
        -- l_status_flg
        l_status_flg := i_flg_status_det;
    
        pk_utils.build_status_string(i_display_type  => l_display_type,
                                     i_flg_state     => l_status_flg,
                                     i_value_text    => l_aux,
                                     i_value_date    => nvl(l_date_begin, l_aux),
                                     i_value_icon    => l_aux,
                                     i_back_color    => l_back_color,
                                     i_message_style => l_message_style,
                                     i_message_color => l_message_color,
                                     i_default_color => l_default_color,
                                     o_status_str    => o_status_str,
                                     o_status_msg    => o_status_msg,
                                     o_status_icon   => o_status_icon,
                                     o_status_flg    => o_status_flg);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_bp_status_req;

    FUNCTION get_bp_status_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN blood_products_ea.id_episode%TYPE,
        i_flg_time            IN blood_products_ea.flg_time%TYPE,
        i_flg_status_det      IN blood_products_ea.flg_status_det%TYPE,
        i_dt_blood_product    IN blood_products_ea.dt_blood_product%TYPE,
        i_dt_begin_req        IN blood_products_ea.dt_begin_req%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  procedures_ea.status_str%TYPE;
        l_status_msg  procedures_ea.status_msg%TYPE;
        l_status_icon procedures_ea.status_icon%TYPE;
        l_status_flg  procedures_ea.status_flg%TYPE;
    
    BEGIN
    
        get_bp_status(i_lang                => i_lang,
                      i_prof                => i_prof,
                      i_episode             => i_episode,
                      i_flg_time            => i_flg_time,
                      i_flg_status_det      => i_flg_status_det,
                      i_dt_blood_product    => i_dt_blood_product,
                      i_dt_begin_req        => i_dt_begin_req,
                      i_order_recurr_option => i_order_recurr_option,
                      o_status_str          => l_status_str,
                      o_status_msg          => l_status_msg,
                      o_status_icon         => l_status_icon,
                      o_status_flg          => l_status_flg);
    
        RETURN l_status_str;
    
    END get_bp_status_str;

    FUNCTION get_bp_status_req_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN blood_products_ea.id_episode%TYPE,
        i_flg_time            IN blood_products_ea.flg_time%TYPE,
        i_flg_status_det      IN blood_products_ea.flg_status_det%TYPE,
        i_dt_blood_product    IN blood_products_ea.dt_blood_product%TYPE,
        i_dt_begin_req        IN blood_products_ea.dt_begin_req%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  procedures_ea.status_str%TYPE;
        l_status_msg  procedures_ea.status_msg%TYPE;
        l_status_icon procedures_ea.status_icon%TYPE;
        l_status_flg  procedures_ea.status_flg%TYPE;
    
    BEGIN
    
        get_bp_status_req(i_lang                => i_lang,
                          i_prof                => i_prof,
                          i_episode             => i_episode,
                          i_flg_time            => i_flg_time,
                          i_flg_status_det      => i_flg_status_det,
                          i_dt_blood_product    => i_dt_blood_product,
                          i_dt_begin_req        => i_dt_begin_req,
                          i_order_recurr_option => i_order_recurr_option,
                          o_status_str          => l_status_str,
                          o_status_msg          => l_status_msg,
                          o_status_icon         => l_status_icon,
                          o_status_flg          => l_status_flg);
    
        RETURN l_status_str;
    
    END get_bp_status_req_str;

    FUNCTION get_bp_status_msg
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN blood_products_ea.id_episode%TYPE,
        i_flg_time            IN blood_products_ea.flg_time%TYPE,
        i_flg_status_det      IN blood_products_ea.flg_status_det%TYPE,
        i_dt_blood_product    IN blood_products_ea.dt_blood_product%TYPE,
        i_dt_begin_req        IN blood_products_ea.dt_begin_req%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  blood_products_ea.status_str%TYPE;
        l_status_msg  blood_products_ea.status_msg%TYPE;
        l_status_icon blood_products_ea.status_icon%TYPE;
        l_status_flg  procedures_ea.status_flg%TYPE;
    
    BEGIN
    
        get_bp_status(i_lang                => i_lang,
                      i_prof                => i_prof,
                      i_episode             => i_episode,
                      i_flg_time            => i_flg_time,
                      i_flg_status_det      => i_flg_status_det,
                      i_dt_blood_product    => i_dt_blood_product,
                      i_dt_begin_req        => i_dt_begin_req,
                      i_order_recurr_option => i_order_recurr_option,
                      o_status_str          => l_status_str,
                      o_status_msg          => l_status_msg,
                      o_status_icon         => l_status_icon,
                      o_status_flg          => l_status_flg);
        RETURN l_status_msg;
    
    END get_bp_status_msg;

    FUNCTION get_bp_status_req_msg
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN blood_products_ea.id_episode%TYPE,
        i_flg_time            IN blood_products_ea.flg_time%TYPE,
        i_flg_status_det      IN blood_products_ea.flg_status_det%TYPE,
        i_dt_blood_product    IN blood_products_ea.dt_blood_product%TYPE,
        i_dt_begin_req        IN blood_products_ea.dt_begin_req%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  blood_products_ea.status_str%TYPE;
        l_status_msg  blood_products_ea.status_msg%TYPE;
        l_status_icon blood_products_ea.status_icon%TYPE;
        l_status_flg  procedures_ea.status_flg%TYPE;
    
    BEGIN
    
        get_bp_status_req(i_lang                => i_lang,
                          i_prof                => i_prof,
                          i_episode             => i_episode,
                          i_flg_time            => i_flg_time,
                          i_flg_status_det      => i_flg_status_det,
                          i_dt_blood_product    => i_dt_blood_product,
                          i_dt_begin_req        => i_dt_begin_req,
                          i_order_recurr_option => i_order_recurr_option,
                          o_status_str          => l_status_str,
                          o_status_msg          => l_status_msg,
                          o_status_icon         => l_status_icon,
                          o_status_flg          => l_status_flg);
        RETURN l_status_msg;
    
    END get_bp_status_req_msg;

    FUNCTION get_bp_status_icon
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN blood_products_ea.id_episode%TYPE,
        i_flg_time            IN blood_products_ea.flg_time%TYPE,
        i_flg_status_det      IN blood_products_ea.flg_status_det%TYPE,
        i_dt_blood_product    IN blood_products_ea.dt_blood_product%TYPE,
        i_dt_begin_req        IN blood_products_ea.dt_begin_req%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  blood_products_ea.status_str%TYPE;
        l_status_msg  blood_products_ea.status_msg%TYPE;
        l_status_icon blood_products_ea.status_icon%TYPE;
        l_status_flg  blood_products_ea.status_flg%TYPE;
    
    BEGIN
    
        get_bp_status(i_lang                => i_lang,
                      i_prof                => i_prof,
                      i_episode             => i_episode,
                      i_flg_time            => i_flg_time,
                      i_flg_status_det      => i_flg_status_det,
                      i_dt_blood_product    => i_dt_blood_product,
                      i_dt_begin_req        => i_dt_begin_req,
                      i_order_recurr_option => i_order_recurr_option,
                      o_status_str          => l_status_str,
                      o_status_msg          => l_status_msg,
                      o_status_icon         => l_status_icon,
                      o_status_flg          => l_status_flg);
    
        RETURN l_status_icon;
    
    END get_bp_status_icon;

    FUNCTION get_bp_status_req_icon
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN blood_products_ea.id_episode%TYPE,
        i_flg_time            IN blood_products_ea.flg_time%TYPE,
        i_flg_status_det      IN blood_products_ea.flg_status_det%TYPE,
        i_dt_blood_product    IN blood_products_ea.dt_blood_product%TYPE,
        i_dt_begin_req        IN blood_products_ea.dt_begin_req%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  blood_products_ea.status_str%TYPE;
        l_status_msg  blood_products_ea.status_msg%TYPE;
        l_status_icon blood_products_ea.status_icon%TYPE;
        l_status_flg  blood_products_ea.status_flg%TYPE;
    
    BEGIN
    
        get_bp_status_req(i_lang                => i_lang,
                          i_prof                => i_prof,
                          i_episode             => i_episode,
                          i_flg_time            => i_flg_time,
                          i_flg_status_det      => i_flg_status_det,
                          i_dt_blood_product    => i_dt_blood_product,
                          i_dt_begin_req        => i_dt_begin_req,
                          i_order_recurr_option => i_order_recurr_option,
                          o_status_str          => l_status_str,
                          o_status_msg          => l_status_msg,
                          o_status_icon         => l_status_icon,
                          o_status_flg          => l_status_flg);
    
        RETURN l_status_icon;
    
    END get_bp_status_req_icon;

    FUNCTION get_bp_status_flg
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN blood_products_ea.id_episode%TYPE,
        i_flg_time            IN blood_products_ea.flg_time%TYPE,
        i_flg_status_det      IN blood_products_ea.flg_status_det%TYPE,
        i_dt_blood_product    IN blood_products_ea.dt_blood_product%TYPE,
        i_dt_begin_req        IN blood_products_ea.dt_begin_req%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  blood_products_ea.status_str%TYPE;
        l_status_msg  blood_products_ea.status_msg%TYPE;
        l_status_icon blood_products_ea.status_icon%TYPE;
        l_status_flg  blood_products_ea.status_flg%TYPE;
    
    BEGIN
    
        get_bp_status(i_lang           => i_lang,
                      i_prof           => i_prof,
                      i_episode        => i_episode,
                      i_flg_time       => i_flg_time,
                      i_flg_status_det => i_flg_status_det,
                      
                      i_dt_blood_product    => i_dt_blood_product,
                      i_dt_begin_req        => i_dt_begin_req,
                      i_order_recurr_option => i_order_recurr_option,
                      o_status_str          => l_status_str,
                      o_status_msg          => l_status_msg,
                      o_status_icon         => l_status_icon,
                      o_status_flg          => l_status_flg);
    
        RETURN l_status_flg;
    
    END get_bp_status_flg;

    FUNCTION get_bp_status_req_flg
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN blood_products_ea.id_episode%TYPE,
        i_flg_time            IN blood_products_ea.flg_time%TYPE,
        i_flg_status_det      IN blood_products_ea.flg_status_det%TYPE,
        i_dt_blood_product    IN blood_products_ea.dt_blood_product%TYPE,
        i_dt_begin_req        IN blood_products_ea.dt_begin_req%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  blood_products_ea.status_str%TYPE;
        l_status_msg  blood_products_ea.status_msg%TYPE;
        l_status_icon blood_products_ea.status_icon%TYPE;
        l_status_flg  blood_products_ea.status_flg%TYPE;
    
    BEGIN
    
        get_bp_status_req(i_lang           => i_lang,
                          i_prof           => i_prof,
                          i_episode        => i_episode,
                          i_flg_time       => i_flg_time,
                          i_flg_status_det => i_flg_status_det,
                          
                          i_dt_blood_product    => i_dt_blood_product,
                          i_dt_begin_req        => i_dt_begin_req,
                          i_order_recurr_option => i_order_recurr_option,
                          o_status_str          => l_status_str,
                          o_status_msg          => l_status_msg,
                          o_status_icon         => l_status_icon,
                          o_status_flg          => l_status_flg);
    
        RETURN l_status_flg;
    
    END get_bp_status_req_flg;

    FUNCTION get_bp_status_req_all
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN blood_products_ea.id_episode%TYPE,
        i_flg_time            IN blood_products_ea.flg_time%TYPE,
        i_flg_status_det      IN blood_products_ea.flg_status_det%TYPE,
        i_dt_blood_product    IN blood_products_ea.dt_blood_product%TYPE,
        i_dt_begin_req        IN blood_products_ea.dt_begin_req%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN table_ea_struct IS
        l_status_str  blood_products_ea.status_str%TYPE;
        l_status_msg  blood_products_ea.status_msg%TYPE;
        l_status_icon blood_products_ea.status_icon%TYPE;
        l_status_flg  blood_products_ea.status_flg%TYPE;
    
        l_table_ea_struct table_ea_struct := table_ea_struct(NULL);
    
    BEGIN
        get_bp_status_req(i_lang                => i_lang,
                          i_prof                => i_prof,
                          i_episode             => i_episode,
                          i_flg_time            => i_flg_time,
                          i_flg_status_det      => i_flg_status_det,
                          i_dt_blood_product    => i_dt_blood_product,
                          i_dt_begin_req        => i_dt_begin_req,
                          i_order_recurr_option => i_order_recurr_option,
                          o_status_str          => l_status_str,
                          o_status_msg          => l_status_msg,
                          o_status_icon         => l_status_icon,
                          o_status_flg          => l_status_flg);
    
        SELECT t_ea_struct(l_status_str, l_status_msg, l_status_icon, l_status_flg)
          BULK COLLECT
          INTO l_table_ea_struct
          FROM (SELECT l_status_str, l_status_msg, l_status_icon, l_status_flg
                  FROM dual);
    
        RETURN l_table_ea_struct;
    END get_bp_status_req_all;

    FUNCTION get_bp_status_all
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN blood_products_ea.id_episode%TYPE,
        i_flg_time            IN blood_products_ea.flg_time%TYPE,
        i_flg_status_det      IN blood_products_ea.flg_status_det%TYPE,
        i_dt_blood_product    IN blood_products_ea.dt_blood_product%TYPE,
        i_dt_begin_req        IN blood_products_ea.dt_begin_req%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN table_ea_struct IS
        l_status_str  blood_products_ea.status_str%TYPE;
        l_status_msg  blood_products_ea.status_msg%TYPE;
        l_status_icon blood_products_ea.status_icon%TYPE;
        l_status_flg  blood_products_ea.status_flg%TYPE;
    
        l_table_ea_struct table_ea_struct := table_ea_struct(NULL);
    
    BEGIN
        get_bp_status(i_lang                => i_lang,
                      i_prof                => i_prof,
                      i_episode             => i_episode,
                      i_flg_time            => i_flg_time,
                      i_flg_status_det      => i_flg_status_det,
                      i_dt_blood_product    => i_dt_blood_product,
                      i_dt_begin_req        => i_dt_begin_req,
                      i_order_recurr_option => i_order_recurr_option,
                      o_status_str          => l_status_str,
                      o_status_msg          => l_status_msg,
                      o_status_icon         => l_status_icon,
                      o_status_flg          => l_status_flg);
    
        SELECT t_ea_struct(l_status_str, l_status_msg, l_status_icon, l_status_flg)
          BULK COLLECT
          INTO l_table_ea_struct
          FROM (SELECT l_status_str, l_status_msg, l_status_icon, l_status_flg
                  FROM dual);
    
        RETURN l_table_ea_struct;
    END get_bp_status_all;

    PROCEDURE set_blood_products
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row blood_products_ea%ROWTYPE;
        l_rowids      table_varchar;
    
        l_rows_out table_varchar;
    
    BEGIN
    
        g_error := 'GET PROCEDURES ROWIDS';
        get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => l_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'BLOOD_PRODUCTS_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process insert event
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            -- Loop through changed records
            g_error := 'LOOP INSERTED';
            IF l_rowids IS NOT NULL
               AND l_rowids.count > 0
            THEN
                FOR r_cur IN (SELECT *
                                FROM (SELECT row_number() over(PARTITION BY bpd.id_blood_product_det ORDER BY bpd.dt_begin_tstz DESC) rn,
                                             bpr.id_blood_product_req,
                                             bpd.id_blood_product_det,
                                             bpd.id_hemo_type,
                                             bpr.flg_status flg_status_req,
                                             bpd.flg_status flg_status_det,
                                             bpr.flg_time,
                                             bpr.dt_begin_tstz dt_begin_req,
                                             bpd.dt_begin_tstz dt_begin_det,
                                             bpd.dt_blood_product_det dt_blood_product,
                                             bpr.id_professional,
                                             decode(bpr.notes,
                                                    NULL,
                                                    pk_procedures_constant.g_no,
                                                    pk_procedures_constant.g_yes) flg_notes,
                                             cs.id_prof_ordered_by,
                                             cs.dt_ordered_by,
                                             bpd.flg_priority,
                                             bpr.id_episode_origin,
                                             v.id_visit,
                                             e.id_episode,
                                             e.id_patient,
                                             bpd.dt_blood_product_det,
                                             bpd.id_order_recurrence,
                                             orp.id_order_recurr_option,
                                             bpd.flg_req_origin_module,
                                             bpr.notes,
                                             bpd.notes_tech,
                                             bpr.notes_cancel,
                                             bpd.id_clinical_purpose,
                                             bpd.transfusion_type,
                                             bpd.qty_exec,
                                             bpd.id_unit_mea_qty_exec,
                                             bpd.special_instr,
                                             bpd.barcode_lab,
                                             bpd.qty_received,
                                             bpd.id_unit_mea_qty_received,
                                             bpd.expiration_date,
                                             bpd.blood_group,
                                             bpd.blood_group_rh,
                                             bpd.adverse_reaction,
                                             bpd.qty_given,
                                             bpd.id_unit_mea_qty_given,
                                             bpd.id_special_type,
                                             pk_blood_products_utils.get_bp_adverse_reaction_req(i_lang   => i_lang,
                                                                                                 i_prof   => i_prof,
                                                                                                 i_bp_req => bpr.id_blood_product_req) adverse_reaction_req
                                        FROM blood_product_req bpr
                                        JOIN (SELECT /*+opt_estimate (table erd rows=1)*/
                                              *
                                               FROM blood_product_det bpdi
                                              WHERE bpdi.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                                    *
                                                                     FROM TABLE(l_rowids) t)
                                                AND bpdi.flg_status != pk_blood_products_constant.g_status_det_pd) bpd
                                          ON bpr.id_blood_product_req = bpd.id_blood_product_req
                                        JOIN hemo_type ht
                                          ON bpd.id_hemo_type = ht.id_hemo_type
                                        JOIN episode e
                                          ON e.id_episode = bpr.id_episode
                                        JOIN visit v
                                          ON v.id_visit = e.id_visit
                                        LEFT JOIN episode e_origin
                                          ON e_origin.id_episode = bpr.id_episode_origin
                                        LEFT JOIN order_recurr_plan orp
                                          ON orp.id_order_recurr_plan = bpd.id_order_recurrence
                                        LEFT JOIN co_sign cs
                                          ON cs.id_co_sign = bpd.id_co_sign_order)
                               WHERE rn = 1)
                LOOP
                    g_error := 'GET PROCEDURE STATUS';
                    pk_ea_logic_blood_products.get_bp_status(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_episode             => r_cur.id_episode,
                                                             i_flg_time            => r_cur.flg_time,
                                                             i_flg_status_det      => r_cur.flg_status_det,
                                                             i_dt_blood_product    => r_cur.dt_blood_product,
                                                             i_dt_begin_req        => r_cur.dt_begin_req,
                                                             i_order_recurr_option => r_cur.id_order_recurr_option,
                                                             o_status_str          => l_new_rec_row.status_str,
                                                             o_status_msg          => l_new_rec_row.status_msg,
                                                             o_status_icon         => l_new_rec_row.status_icon,
                                                             o_status_flg          => l_new_rec_row.status_flg);
                
                    pk_ea_logic_blood_products.get_bp_status_req(i_lang                => i_lang,
                                                                 i_prof                => i_prof,
                                                                 i_episode             => r_cur.id_episode,
                                                                 i_flg_time            => r_cur.flg_time,
                                                                 i_flg_status_det      => r_cur.flg_status_req,
                                                                 i_dt_blood_product    => r_cur.dt_blood_product,
                                                                 i_dt_begin_req        => r_cur.dt_begin_req,
                                                                 i_order_recurr_option => r_cur.id_order_recurr_option,
                                                                 o_status_str          => l_new_rec_row.status_str_req,
                                                                 o_status_msg          => l_new_rec_row.status_msg_req,
                                                                 o_status_icon         => l_new_rec_row.status_icon_req,
                                                                 o_status_flg          => l_new_rec_row.status_flg_req);
                
                    g_error                            := 'DEFINE new record for PROCEDURES_EA';
                    l_new_rec_row.id_blood_product_req := r_cur.id_blood_product_req;
                    l_new_rec_row.id_blood_product_det := r_cur.id_blood_product_det;
                    l_new_rec_row.id_hemo_type         := r_cur.id_hemo_type;
                    l_new_rec_row.flg_status_req       := r_cur.flg_status_req;
                    l_new_rec_row.flg_status_det       := r_cur.flg_status_det;
                    l_new_rec_row.flg_time             := r_cur.flg_time;
                    l_new_rec_row.id_order_recurrence  := r_cur.id_order_recurrence;
                    l_new_rec_row.dt_begin_req         := r_cur.dt_begin_req;
                    l_new_rec_row.dt_begin_det         := r_cur.dt_begin_det;
                    l_new_rec_row.flg_priority         := r_cur.flg_priority;
                    l_new_rec_row.dt_blood_product     := r_cur.dt_blood_product;
                    l_new_rec_row.id_professional      := r_cur.id_professional;
                    l_new_rec_row.flg_notes            := r_cur.flg_notes;
                    --l_new_rec_row.flg_doc                 := r_cur.flg_doc;
                    l_new_rec_row.id_clinical_purpose := r_cur.id_clinical_purpose;
                    --l_new_rec_row.other_clin_purp         := r_cur.other_clin_purp;
                    --l_new_rec_row.flg_laterality          := r_cur.flg_laterality;
                    l_new_rec_row.id_prof_order := r_cur.id_prof_ordered_by;
                    --l_new_rec_row.dt_order                := r_cur.dt_ordered_by;
                    --l_new_rec_row.id_task_dependency      := r_cur.id_task_dependency;
                    l_new_rec_row.flg_req_origin_module    := r_cur.flg_req_origin_module;
                    l_new_rec_row.notes                    := r_cur.notes;
                    l_new_rec_row.notes_tech               := r_cur.notes_tech;
                    l_new_rec_row.notes_cancel             := r_cur.notes_cancel;
                    l_new_rec_row.id_patient               := r_cur.id_patient;
                    l_new_rec_row.id_visit                 := r_cur.id_visit;
                    l_new_rec_row.id_episode               := r_cur.id_episode;
                    l_new_rec_row.qty_exec                 := r_cur.qty_exec;
                    l_new_rec_row.id_unit_mea_qty_exec     := r_cur.id_unit_mea_qty_exec;
                    l_new_rec_row.id_episode_origin        := r_cur.id_episode_origin;
                    l_new_rec_row.barcode_lab              := r_cur.barcode_lab;
                    l_new_rec_row.qty_received             := r_cur.qty_received;
                    l_new_rec_row.id_unit_mea_qty_received := r_cur.id_unit_mea_qty_received;
                    l_new_rec_row.expiration_date          := r_cur.expiration_date;
                    l_new_rec_row.blood_group              := r_cur.blood_group;
                    l_new_rec_row.blood_group_rh           := r_cur.blood_group_rh;
                    l_new_rec_row.adverse_reaction         := r_cur.adverse_reaction;
                    l_new_rec_row.adverse_reaction_req     := r_cur.adverse_reaction_req;
                    l_new_rec_row.qty_given                := r_cur.qty_given;
                    l_new_rec_row.id_special_type          := r_cur.id_special_type;
                    l_new_rec_row.id_unit_mea_qty_given    := r_cur.id_unit_mea_qty_given;
                
                    g_error := 'TS_BLOOD_PRODUCTS_EA.UPD';
                    IF i_source_table_name = 'BLOOD_PRODUCT_DET'
                       AND i_event_type = t_data_gov_mnt.g_event_insert
                    THEN
                        ts_blood_products_ea.ins(rec_in => l_new_rec_row, rows_out => l_rows_out);
                    ELSE
                        g_error := 'ts_procedures_ea.upd';
                        ts_blood_products_ea.upd(id_blood_product_det_in => l_new_rec_row.id_blood_product_det,
                                                 id_blood_product_req_in => l_new_rec_row.id_blood_product_req,
                                                 id_hemo_type_in         => l_new_rec_row.id_hemo_type,
                                                 flg_status_req_in       => l_new_rec_row.flg_status_req,
                                                 flg_status_det_in       => l_new_rec_row.flg_status_det,
                                                 flg_time_in             => l_new_rec_row.flg_time,
                                                 id_order_recurrence_in  => l_new_rec_row.id_order_recurrence,
                                                 id_order_recurrence_nin => FALSE,
                                                 dt_begin_req_in         => l_new_rec_row.dt_begin_req,
                                                 dt_begin_det_in         => l_new_rec_row.dt_begin_det,
                                                 dt_blood_product_det_in => l_new_rec_row.dt_blood_product,
                                                 id_professional_in      => l_new_rec_row.id_professional,
                                                 flg_notes_in            => l_new_rec_row.flg_notes,
                                                 id_clinical_purpose_in  => l_new_rec_row.id_clinical_purpose,
                                                 id_clinical_purpose_nin => FALSE,
                                                 
                                                 id_prof_order_in  => l_new_rec_row.id_prof_order,
                                                 id_prof_order_nin => FALSE,
                                                 
                                                 flg_req_origin_module_in     => l_new_rec_row.flg_req_origin_module,
                                                 notes_in                     => l_new_rec_row.notes,
                                                 notes_nin                    => FALSE,
                                                 notes_tech_in                => l_new_rec_row.notes_tech,
                                                 notes_tech_nin               => FALSE,
                                                 notes_cancel_in              => l_new_rec_row.notes_cancel,
                                                 notes_cancel_nin             => FALSE,
                                                 id_patient_in                => l_new_rec_row.id_patient,
                                                 id_visit_in                  => l_new_rec_row.id_visit,
                                                 id_episode_in                => l_new_rec_row.id_episode,
                                                 id_episode_origin_in         => l_new_rec_row.id_episode_origin,
                                                 status_str_in                => l_new_rec_row.status_str,
                                                 status_str_nin               => FALSE,
                                                 status_msg_in                => l_new_rec_row.status_msg,
                                                 status_msg_nin               => FALSE,
                                                 status_icon_in               => l_new_rec_row.status_icon,
                                                 status_icon_nin              => FALSE,
                                                 status_flg_in                => l_new_rec_row.status_flg,
                                                 status_flg_nin               => FALSE,
                                                 status_str_req_in            => l_new_rec_row.status_str_req,
                                                 status_str_req_nin           => FALSE,
                                                 status_msg_req_in            => l_new_rec_row.status_msg_req,
                                                 status_msg_req_nin           => FALSE,
                                                 status_icon_req_in           => l_new_rec_row.status_icon_req,
                                                 status_icon_req_nin          => FALSE,
                                                 status_flg_req_in            => l_new_rec_row.status_flg_req,
                                                 status_flg_req_nin           => FALSE,
                                                 flg_priority_in              => l_new_rec_row.flg_priority,
                                                 flg_priority_nin             => FALSE,
                                                 qty_exec_in                  => l_new_rec_row.qty_exec,
                                                 qty_exec_nin                 => FALSE,
                                                 id_unit_mea_qty_exec_in      => l_new_rec_row.id_unit_mea_qty_exec,
                                                 id_unit_mea_qty_exec_nin     => FALSE,
                                                 barcode_lab_in               => l_new_rec_row.barcode_lab,
                                                 barcode_lab_nin              => FALSE,
                                                 qty_received_in              => l_new_rec_row.qty_received,
                                                 qty_received_nin             => FALSE,
                                                 id_unit_mea_qty_received_in  => l_new_rec_row.id_unit_mea_qty_received,
                                                 id_unit_mea_qty_received_nin => FALSE,
                                                 expiration_date_in           => l_new_rec_row.expiration_date,
                                                 expiration_date_nin          => FALSE,
                                                 blood_group_in               => l_new_rec_row.blood_group,
                                                 blood_group_nin              => FALSE,
                                                 blood_group_rh_in            => l_new_rec_row.blood_group_rh,
                                                 blood_group_rh_nin           => FALSE,
                                                 adverse_reaction_in          => l_new_rec_row.adverse_reaction,
                                                 adverse_reaction_nin         => FALSE,
                                                 adverse_reaction_req_in      => l_new_rec_row.adverse_reaction_req,
                                                 adverse_reaction_req_nin     => FALSE,
                                                 qty_given_in                 => l_new_rec_row.qty_given,
                                                 qty_given_nin                => FALSE,
                                                 id_unit_mea_qty_given_in     => l_new_rec_row.id_unit_mea_qty_given,
                                                 id_unit_mea_qty_given_nin    => FALSE,
                                                 id_special_type_in           => l_new_rec_row.id_special_type,
                                                 id_special_type_nin          => FALSE,
                                                 rows_out                     => l_rows_out);
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            ROLLBACK;
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            -- Unexpected error.
            ROLLBACK;
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_blood_products;

    PROCEDURE ins_grid_task_bp_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN grid_task.id_episode%TYPE
    ) IS
        l_grid_task      grid_task%ROWTYPE;
        l_grid_task_betw grid_task_between%ROWTYPE;
        l_shortcut       sys_shortcut.id_sys_shortcut%TYPE;
        l_dt_str_1       VARCHAR2(200 CHAR);
        l_dt_str_2       VARCHAR2(200 CHAR);
        l_dt_1           VARCHAR2(200 CHAR);
        l_dt_2           VARCHAR2(200 CHAR);
        l_error_out      t_error_out;
        l_prof           profissional := i_prof;
        l_id_institution episode.id_institution%TYPE;
        l_id_software    epis_info.id_software%TYPE;
    BEGIN
        g_error := 'PK_ACCESS.GET_ID_SHORTCUT for GRID_MONITOR';
        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                         i_prof        => l_prof,
                                         i_intern_name => 'BLOOD_PRODUCTS_DEEPNAV',
                                         o_id_shortcut => l_shortcut,
                                         o_error       => l_error_out)
        THEN
            l_shortcut := 0;
        END IF;
    
        UPDATE grid_task
           SET hemo_req = NULL
         WHERE id_episode = i_id_episode;
    
        SELECT MAX(status_string) status_string
          INTO l_grid_task.hemo_req
          FROM (SELECT decode(rank,
                              1,
                              pk_blood_products_utils.get_status_string(i_lang      => i_lang,
                                                                        i_prof      => i_prof,
                                                                        i_episode   => id_episode_origin,
                                                                        i_bp_det    => id_blood_product_det,
                                                                        i_force_anc => pk_alert_constant.g_yes),
                              
                              NULL) status_string
                  FROM (SELECT t.id_blood_product_det,
                               t.id_episode_origin,
                               t.flg_time,
                               t.flg_status,
                               t.flg_status_det,
                               t.dt_begin_tstz,
                               t.dt_blood_product_det,
                               row_number() over(ORDER BY t.rank) rank
                          FROM (SELECT t.*,
                                       row_number() over(ORDER BY pk_sysdomain.get_rank(i_lang, 'BLOOD_PRODUCT_DET.FLG_STATUS', t.flg_status_det), t.dt_begin_tstz) rank
                                  FROM (SELECT bpd.id_blood_product_det,
                                               bpr.id_episode_origin,
                                               bpr.flg_time,
                                               bpr.flg_status,
                                               bpd.flg_status flg_status_det,
                                               bpd.dt_blood_product_det,
                                               bpd.dt_begin_tstz
                                          FROM blood_product_req bpr
                                          JOIN blood_product_det bpd
                                            ON bpr.id_blood_product_req = bpd.id_blood_product_req
                                          JOIN episode e
                                            ON bpr.id_episode = e.id_episode
                                         WHERE e.id_episode = i_id_episode
                                           AND bpd.flg_status IN
                                               (pk_blood_products_constant.g_status_det_wt,
                                                pk_blood_products_constant.g_status_det_ot,
                                                pk_blood_products_constant.g_status_det_r_sc,
                                                pk_blood_products_constant.g_status_det_r_cc,
                                                pk_blood_products_constant.g_status_det_r_w)) t) t) t
                 WHERE rank = 1) t;
    
        g_error := 'GET SHORTCUT - DOCTOR';
    
        l_grid_task.hemo_req   := l_shortcut || l_grid_task.hemo_req;
        l_grid_task.id_episode := i_id_episode;
    
        IF l_grid_task.id_episode IS NOT NULL
        THEN
            g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
            IF NOT pk_grid.update_grid_task(i_lang       => i_lang,
                                            i_prof       => l_prof,
                                            i_episode    => l_grid_task.id_episode,
                                            hemo_req_in  => l_grid_task.hemo_req,
                                            hemo_req_nin => FALSE,
                                            o_error      => l_error_out)
            THEN
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        
            IF l_grid_task.hemo_req IS NULL
            THEN
                g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_episode';
                IF NOT pk_grid.delete_epis_grid_task(i_lang    => i_lang,
                                                     i_episode => l_grid_task.id_episode,
                                                     o_error   => l_error_out)
                THEN
                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END ins_grid_task_bp_epis;

    PROCEDURE ins_grid_task_bp
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rowids IN table_varchar
    ) IS
        l_grid_task      grid_task%ROWTYPE;
        l_grid_task_betw grid_task_between%ROWTYPE;
        l_shortcut       sys_shortcut.id_sys_shortcut%TYPE;
        l_dt_str_1       VARCHAR2(200 CHAR);
        l_dt_str_2       VARCHAR2(200 CHAR);
        l_dt_1           VARCHAR2(200 CHAR);
        l_dt_2           VARCHAR2(200 CHAR);
        l_error_out      t_error_out;
        l_prof           profissional := i_prof;
        l_id_institution episode.id_institution%TYPE;
        l_id_software    epis_info.id_software%TYPE;
    BEGIN
        -- Loop through changed records            
        FOR r_cur IN (SELECT *
                        FROM (SELECT nvl(bpr.id_episode, bpr.id_episode_origin) id_episode,
                                     nvl(bpd.id_prof_last_update, bpr.id_professional) id_professional
                                FROM (SELECT /*+opt_estimate (table mv rows=1)*/
                                       *
                                        FROM blood_product_det bpd
                                       WHERE (bpd.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                             *
                                                              FROM TABLE(i_rowids) t) OR i_rowids IS NULL)
                                         AND bpd.flg_status != pk_blood_products_constant.g_status_det_d) bpd,
                                     blood_product_req bpr
                               WHERE bpr.id_blood_product_req = bpd.id_blood_product_req))
        LOOP
        
            l_grid_task      := NULL;
            l_grid_task_betw := NULL;
        
            IF i_prof IS NULL
            THEN
                BEGIN
                    SELECT e.id_institution, ei.id_software
                      INTO l_id_institution, l_id_software
                      FROM episode e
                      JOIN epis_info ei
                        ON ei.id_episode = e.id_episode
                     WHERE e.id_episode = r_cur.id_episode;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_institution := NULL;
                        l_id_software    := NULL;
                END;
            
                IF r_cur.id_professional IS NULL
                   OR l_id_institution IS NULL
                   OR l_id_software IS NULL
                THEN
                    CONTINUE;
                END IF;
            
                l_prof := profissional(r_cur.id_professional, l_id_institution, l_id_software);
            END IF;
        
            ins_grid_task_bp_epis(i_lang => i_lang, i_prof => l_prof, i_id_episode => r_cur.id_episode);
        END LOOP;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END ins_grid_task_bp;

    PROCEDURE set_grid_task_bp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_rowids    table_varchar;
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'GET BPs ROWIDS';
        get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'GRID_TASK',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process update event
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            -- Loop through changed records
            g_error := 'LOOP UPDATED';
            IF i_rowids IS NOT NULL
               AND i_rowids.count > 0
            THEN
                ins_grid_task_bp(i_lang => i_lang, i_prof => i_prof, i_rowids => l_rowids);
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END set_grid_task_bp;

    PROCEDURE set_blood_products_harvest
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_rowids     table_varchar;
        l_error_out  t_error_out;
        l_tbl_bpds   table_number;
        l_tbl_bpds1  table_varchar;
        l_rows_out   table_varchar;
        l_bpd_status blood_product_det.flg_status%TYPE;
    
        l_sysdate TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
    
        l_num_analysis NUMBER(24);
    
        l_exec_number NUMBER(24);
        l_continue    VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
    
        g_error := 'GET BPs ROWIDS';
        get_data_rowid_harvest(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
    
        IF i_rowids IS NOT NULL
           AND i_rowids.count > 0
           AND l_rowids IS NOT NULL
           AND l_rowids.count > 0
        THEN
        
            BEGIN
                SELECT bpa.id_blood_product_det
                  BULK COLLECT
                  INTO l_tbl_bpds
                  FROM blood_product_analysis bpa
                 INNER JOIN analysis_req_det ard
                    ON bpa.id_analysis_req_det = ard.id_analysis_req_det
                 INNER JOIN analysis_harvest ah
                    ON ah.id_analysis_req_det = ard.id_analysis_req_det
                 INNER JOIN harvest h
                    ON h.id_harvest = ah.id_harvest
                 WHERE bpa.id_analysis_req_det IN (SELECT *
                                                     FROM TABLE(l_rowids))
                   AND h.flg_status = pk_lab_tests_constant.g_analysis_collected;
            EXCEPTION
                WHEN OTHERS THEN
                    l_tbl_bpds := table_number();
            END;
        
            FOR i IN 1 .. l_tbl_bpds.count
            LOOP
            
                --Verify if have others analysis that not collected yet
                SELECT COUNT(*)
                  INTO l_num_analysis
                  FROM blood_product_analysis bpa
                 WHERE bpa.id_blood_product_det = l_tbl_bpds(i);
            
                IF l_num_analysis = 1
                THEN
                    l_continue := pk_alert_constant.g_yes;
                ELSE
                
                    SELECT COUNT(*)
                      INTO l_num_analysis
                      FROM blood_product_analysis bpa
                      JOIN analysis_req_det ard
                        ON ard.id_analysis_req_det = bpa.id_analysis_req_det
                      JOIN analysis_harvest ah
                        ON ard.id_analysis_req_det = ah.id_analysis_req_det
                      JOIN harvest h
                        ON h.id_harvest = ah.id_harvest
                     WHERE bpa.id_blood_product_det = l_tbl_bpds(i)
                       AND h.flg_status IN
                           (pk_lab_tests_constant.g_harvest_pending, pk_lab_tests_constant.g_harvest_waiting);
                
                    IF l_num_analysis > 0
                    THEN
                        l_continue := pk_alert_constant.g_no;
                    ELSE
                        l_continue := pk_alert_constant.g_yes;
                    END IF;
                
                END IF;
            
                IF l_continue = pk_alert_constant.g_yes
                THEN
                
                    SELECT bpd.flg_status
                      INTO l_bpd_status
                      FROM blood_product_det bpd
                     WHERE bpd.id_blood_product_det = l_tbl_bpds(i);
                
                    IF l_bpd_status IN
                       (pk_blood_products_constant.g_status_det_r_sc, pk_blood_products_constant.g_status_det_r_cc)
                    THEN
                        ts_blood_product_det.upd(id_blood_product_det_in => l_tbl_bpds(i),
                                                 flg_status_in           => pk_blood_products_constant.g_status_det_r_w,
                                                 rows_out                => l_rows_out);
                    END IF;
                
                    SELECT COUNT(1)
                      INTO l_exec_number
                      FROM blood_product_execution bpe
                     WHERE bpe.id_blood_product_det = l_tbl_bpds(i);
                
                    ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                                   id_blood_product_det_in       => l_tbl_bpds(i),
                                                   action_in                     => pk_blood_products_constant.g_bp_action_lab_collected,
                                                   id_prof_performed_in          => i_prof.id,
                                                   dt_execution_in               => l_sysdate,
                                                   exec_number_in                => l_exec_number + 1,
                                                   create_user_in                => i_prof.id,
                                                   create_time_in                => l_sysdate,
                                                   create_institution_in         => i_prof.institution);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'BLOOD_PRODUCT_DET',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => l_error_out);
                END IF;
            END LOOP;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ea_logic_blood_products;
/
