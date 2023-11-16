/*-- Last Change Revision: $Rev: 2027443 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_utils AS
    /**
    * Return last status change data for the request and
    *
    * @param   i_id_ext_req external request id
    * @param   i_flg_status status
    * @param   o_data last record data
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   15-05-2007   
    */
    FUNCTION get_status_data
    (
        i_lang       IN NUMBER,
        i_id_ext_req IN NUMBER,
        i_flg_status IN VARCHAR2,
        o_data       OUT p1_tracking%ROWTYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- Se ha  mais do que um registo neste estado devolve a data do mais recente.
        g_error := 'Init get_status_data / ID_REF=' || i_id_ext_req || ' FLG_STATUS=' || i_flg_status;
        SELECT *
          INTO o_data
          FROM (SELECT *
                  FROM p1_tracking exrt
                 WHERE exrt.id_external_request = i_id_ext_req
                   AND ext_req_status = i_flg_status
                      -- JS: 25-09-08: Correccao para o estado R
                      -- AM: 03-11-08: Retirado g_tracking_type_c
                   AND flg_type IN (pk_ref_constant.g_tracking_type_s, pk_ref_constant.g_tracking_type_p)
                 ORDER BY dt_tracking_tstz DESC)
         WHERE rownum <= 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_STATUS_DATA',
                                                     o_error    => o_error);
    END get_status_data;

    /**
    * Return last status date for the request
    *
    * @param   i_id_ext_req external request id
    * @param   i_flg_status status
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   15-05-2007
    */
    FUNCTION get_status_date
    (
        i_lang       IN NUMBER,
        i_id_ext_req IN NUMBER,
        i_flg_status IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
    
        retval  BOOLEAN;
        l_data  p1_tracking%ROWTYPE;
        l_error t_error_out;
    BEGIN
    
        g_error := 'Call get_status_data / ID_REF=' || i_id_ext_req || ' FLG_STATUS=' || i_flg_status;
        retval  := get_status_data(i_lang, i_id_ext_req, i_flg_status, l_data, l_error);
    
        IF NOT retval
        THEN
            g_error := 'ERROR: ' || g_error;
            pk_alertlog.log_debug(g_error);
        
            RETURN NULL;
        ELSE
            RETURN l_data.dt_tracking_tstz;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_status_date;

    /**
    * Return first status date for the request
    *
    * @param   i_id_ext_req external request id
    * @param   i_flg_status status
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   30-03-2009
    */
    FUNCTION get_first_status_date
    (
        i_lang       IN NUMBER,
        i_id_ext_req IN NUMBER,
        i_flg_status IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
    
        l_dt_tracking_tstz p1_tracking.dt_tracking_tstz%TYPE;
    BEGIN
    
        -- Se ha  mais do que um registo neste estado devolve a data do mais antigo. [ALERT-21459]
        g_error := 'Init get_first_status_date / ID_REF=' || i_id_ext_req || ' FLG_STATUS=' || i_flg_status;
        SELECT dt_tracking_tstz
          INTO l_dt_tracking_tstz
          FROM (SELECT dt_tracking_tstz
                  FROM p1_tracking exrt
                 WHERE exrt.id_external_request = i_id_ext_req
                   AND ext_req_status = i_flg_status
                   AND flg_type IN (pk_ref_constant.g_tracking_type_s, pk_ref_constant.g_tracking_type_p)
                 ORDER BY dt_tracking_tstz ASC)
         WHERE rownum <= 1;
    
        RETURN l_dt_tracking_tstz;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_debug(g_error);
            RETURN NULL;
    END;

    /**
    * Return last triage status (either 'T' or 'R')
    *
    * @param   i_exr_row external request data
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   20-12-2007
    */
    FUNCTION get_last_triage_status(i_exr_row IN p1_external_request%ROWTYPE) RETURN p1_tracking%ROWTYPE IS
        l_track p1_tracking%ROWTYPE;
    BEGIN
    
        -- js, 2008-05-02: Valida id_institution (por causa dos pedidos que mudaram de instituicao)
        g_error := 'Init get_last_triage_status / ID_REF=' || i_exr_row.id_external_request || ' ID_INST_DEST=' ||
                   i_exr_row.id_inst_dest;
        SELECT *
          INTO l_track
          FROM (SELECT *
                  FROM (
                        -- Registos de triagem para os pedidos para a instituicao actual
                        SELECT *
                          FROM p1_tracking exrt
                         WHERE exrt.id_external_request = i_exr_row.id_external_request
                           AND exrt.id_institution = i_exr_row.id_inst_dest
                           AND ext_req_status IN (pk_ref_constant.g_p1_status_t, pk_ref_constant.g_p1_status_r)
                           AND flg_type IN (pk_ref_constant.g_tracking_type_s,
                                            pk_ref_constant.g_tracking_type_p,
                                            pk_ref_constant.g_tracking_type_c)
                        UNION ALL
                        -- Registos de triagem feitos no encaminhamento do pedido para os pedidos para a instituicao actual
                        SELECT *
                          FROM p1_tracking exrt
                         WHERE exrt.id_external_request = i_exr_row.id_external_request
                           AND exrt.id_inst_dest = i_exr_row.id_inst_dest
                           AND exrt.id_institution != i_exr_row.id_inst_dest
                           AND ext_req_status IN (pk_ref_constant.g_p1_status_t, pk_ref_constant.g_p1_status_r)
                           AND flg_type IN (pk_ref_constant.g_tracking_type_s,
                                            pk_ref_constant.g_tracking_type_p,
                                            pk_ref_constant.g_tracking_type_c))
                 ORDER BY dt_tracking_tstz DESC)
         WHERE rownum <= 1;
    
        RETURN l_track;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_last_triage_status;

    /**
    * Return last triage status (either 'T' or 'R')
    *
    * @param   i_id_ext_req external request id
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   20-12-2007
    */
    FUNCTION get_last_triage_status(i_id_ext_req IN NUMBER) RETURN p1_tracking%ROWTYPE IS
        l_exr_row p1_external_request%ROWTYPE;
    
    BEGIN
    
        g_error := 'Init get_last_triage_status / ID_REF=' || i_id_ext_req;
        SELECT *
          INTO l_exr_row
          FROM p1_external_request
         WHERE id_external_request = i_id_ext_req;
    
        RETURN get_last_triage_status(l_exr_row);
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_last_triage_status;

    /**
    * Checks if provided timestamp is today
    *
    * @param   i_prof request id
    *
    * @RETURN  'Y' if TRUE, 'N' otherwise
    * @author  João Sá
    * @version 1.0
    * @since   06-01-2007
    */
    FUNCTION is_today
    (
        i_prof IN profissional,
        dt     IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR IS
    
    BEGIN
    
        IF dt BETWEEN pk_date_utils.trunc_insttimezone(i_prof, current_timestamp) AND
           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp + INTERVAL '1' DAY)
        THEN
            RETURN pk_ref_constant.g_yes;
        ELSE
            RETURN pk_ref_constant.g_no;
        END IF;
    END;

    /**
    * Get id_codification
    *
    * @param i_lang                       professional language
    * @param i_prof                       professional id, institution and software
    * @param i_ref_type                   referral type
    * @param i_mcdt_codification          id from the mcdt codifications
    * @param o_codification               id codifications
    * @param o_error         
    * 
    * @value i_ref_type {*}'A' Analyis {*}'E' Exams {*}'I' Image {*}'P' Interventions {*}'F' fisiatrics
    * @return                             TRUE if sucess, FALSE otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   03-09-2009
    */

    FUNCTION get_codification
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        i_ref_type          IN p1_external_request.flg_type%TYPE,
        i_mcdt_codification IN analysis_codification.id_analysis_codification%TYPE,
        o_codification      OUT codification.id_codification%TYPE,
        o_error             OUT t_error_out
        
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init get_codification / ID_REF_TYPE=' || i_ref_type || ' MCDT_CODIFICATION=' || i_mcdt_codification;
        pk_alertlog.log_debug(g_error);
    
        IF i_mcdt_codification IS NULL
        THEN
            g_error := 'Error: i_mcdt_codification is NULL';
            RAISE g_exception;
        END IF;
    
        IF i_ref_type = pk_ref_constant.g_p1_type_a
        THEN
        
            g_error := 'Get id_codification from analysis_codification';
            pk_alertlog.log_info(g_error);
        
            SELECT id_codification
              INTO o_codification
              FROM analysis_codification
             WHERE id_analysis_codification = i_mcdt_codification;
        
        ELSIF i_ref_type = pk_ref_constant.g_p1_type_i
              OR i_ref_type = pk_ref_constant.g_p1_type_e
        
        THEN
        
            g_error := 'Get id_codification from exam_codification';
            pk_alertlog.log_info(g_error);
        
            SELECT id_codification
              INTO o_codification
              FROM exam_codification
             WHERE id_exam_codification = i_mcdt_codification;
        
        ELSIF i_ref_type = pk_ref_constant.g_p1_type_p
              OR i_ref_type = pk_ref_constant.g_p1_type_f
        
        THEN
        
            g_error := 'Get id_codification from interv_codification';
            pk_alertlog.log_info(g_error);
        
            SELECT id_codification
              INTO o_codification
              FROM interv_codification
             WHERE id_interv_codification = i_mcdt_codification;
        ELSE
        
            g_error := 'Error: Invalid i_ref_type. i_ref_type = ' || i_ref_type;
            RAISE g_exception;
        
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
                                              i_function => 'GET_CODIFICATION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_codification;

    /**
    * Return last status change date for the request except for the update
    *
    * @param   i_lang           Language identifier
    * @param   i_id_ref         Referral identifier
    * @param   i_flg_status     Referral flag status
    * @param   o_date           Last status change date
    * @param   o_error          Error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   13-01-2010 
    */
    FUNCTION get_last_status_date
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_flg_status IN p1_external_request.flg_status%TYPE,
        o_date       OUT p1_tracking.dt_tracking_tstz%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- Se ha  mais do que um registo neste estado devolve a data do mais recente.
        g_error := 'Init get_status_date / ID_REF=' || i_id_ref || ' FLG_STATUS=' || i_flg_status;
        SELECT *
          INTO o_date
          FROM (SELECT exrt.dt_tracking_tstz
                  FROM p1_tracking exrt
                 WHERE exrt.id_external_request = i_id_ref
                   AND ext_req_status = nvl(i_flg_status, ext_req_status)
                   AND flg_type IN (pk_ref_constant.g_tracking_type_s,
                                    pk_ref_constant.g_tracking_type_p,
                        pk_ref_constant.g_tracking_type_c)
                 ORDER BY dt_tracking_tstz DESC)
         WHERE rownum <= 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_LAST_STATUS_DATE',
                                                     o_error    => o_error);
    END get_last_status_date;

BEGIN

    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_p1_utils;
/
