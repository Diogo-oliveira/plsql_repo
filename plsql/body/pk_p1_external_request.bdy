/*-- Last Change Revision: $Rev: 2027431 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_external_request IS

    g_error VARCHAR2(1000 CHAR);
    --g_sysdate_tstz  TIMESTAMP WITH TIME ZONE;
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    --g_found  BOOLEAN;

    /**
    * Get referral record given an Episode Id
    *
    * @param   i_lang                    language associated to the professional executing the request
    * @param   i_prof                    professional id, institution and software
    * @param   i_id_episode              id episode P1_EXTERNAL_REQUEST record for the given id_episode
    * @param   o_rec                     the 
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  Referral id_external_request if success, return -1 otherwise
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   24-10-2009
    */
    FUNCTION get_rec
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_rec        OUT p1_external_request%ROWTYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_cur IS
            SELECT *
              FROM p1_external_request
             WHERE id_episode = i_id_episode;
    BEGIN
        g_error := 'Init get_rec / I_PROF=' || pk_utils.to_string(i_prof) || ' i_id_episode=' || i_id_episode;
        OPEN c_cur;
        FETCH c_cur
            INTO o_rec;
        CLOSE c_cur;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_rec',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_rec;

    /**
    * Get P1_EXTERNAL_REQUEST PK given an Episode Id
    *
    * @param   i_lang                    language associated to the professional executing the request
    * @param   i_prof                    professional id, institution and software
    * @param   i_id_episode   Episode identifier
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  Referral id_external_request if success, return -1 otherwise
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   24-10-2009
    */

    FUNCTION get_pk
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN p1_external_request.id_external_request%TYPE IS
        l_ref_row p1_external_request%ROWTYPE;
    BEGIN
    
        g_error  := 'Call get_rec / ID_EPISODE=' || i_id_episode;
        g_retval := get_rec(i_lang       => i_lang,
                            i_prof       => i_prof,
                            i_id_episode => i_id_episode,
                            o_rec        => l_ref_row,
                            o_error      => o_error);
    
        -- If no row is returned l_id_external_request remains null
        RETURN l_ref_row.id_external_request;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PK',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN - 1; -- If unsuccess return -1
    END get_pk;

    /**
    * Get referral record of a given Referral
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Professional id, institution and software
    * @param   i_id_ref       Referral identifier 
    * @param   o_rec          Referral record
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-09-2010
    */
    FUNCTION get_ref_row
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        o_rec    OUT p1_external_request%ROWTYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_ref IS
            SELECT *
              INTO o_rec
              FROM p1_external_request
             WHERE id_external_request = i_id_ref;
    BEGIN
        g_error := 'Init get_ref_row / I_PROF=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref;
        OPEN c_ref;
        FETCH c_ref
            INTO o_rec;
        CLOSE c_ref;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_ROW',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_ref_row;

    /**
    * Returns the flg_status of a given Referral
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_id_ref            Referral identifier 
    * @param   o_flg_status        on success returns the flg_status for the given referral
    * @param   O_ERROR             an error message, set when return=false
    *
    * @RETURN  TRUE             
    * @author  Ricardo Patrocínio
    * @version 1.0
    * @since   26-10-2009
    */
    FUNCTION get_flg_status
    (
        i_lang       IN language.id_language%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        o_flg_status OUT p1_external_request.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_row p1_external_request%ROWTYPE;
    BEGIN
    
        -- Get the flg_status for a given referral
        g_error  := 'get_flg_status / ID_REF=' || i_id_ref;
        g_retval := get_ref_row(i_lang   => i_lang,
                                i_prof   => NULL,
                                i_id_ref => i_id_ref,
                                o_rec    => l_ref_row,
                                o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_flg_status := l_ref_row.flg_status;
    
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
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_FLG_STATUS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_flg_status;

    /**
    * Returns referral dep_clin_serv
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_id_ref            Referral identifier 
    * @param   o_dep_clin_serv     Referral dep_clin_serv
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE             
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-10-2010
    */
    FUNCTION get_dep_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_id_ref        IN p1_external_request.id_external_request%TYPE,
        o_dep_clin_serv OUT p1_external_request.id_dep_clin_serv%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_row p1_external_request%ROWTYPE;
    BEGIN
    
        g_error  := 'get_dep_clin_serv / ID_REF=' || i_id_ref;
        g_retval := get_ref_row(i_lang   => i_lang,
                                i_prof   => NULL,
                                i_id_ref => i_id_ref,
                                o_rec    => l_ref_row,
                                o_error  => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_dep_clin_serv := l_ref_row.id_dep_clin_serv;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DEP_CLIN_SERV',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_dep_clin_serv;

    /**
    * Returns referral workflkow identifier
    *
    * @param   i_lang                    language associated to the professional executing the request
    * @param   i_prof                    professional id, institution and software
    * @param   i_id_ref                  Referral identifier 
    * @param   o_id_workflow     Referral workflow identifier
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE             
    * @author  Ana Monteiro
    * @version 1.0
    * @since   09-10-2012
    */
    FUNCTION get_id_workflow
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        o_id_workflow OUT p1_external_request.id_workflow%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_row p1_external_request%ROWTYPE;
    BEGIN
        g_error  := 'Init get_id_workflow / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref;
        g_retval := get_ref_row(i_lang   => i_lang,
                                i_prof   => NULL,
                                i_id_ref => i_id_ref,
                                o_rec    => l_ref_row,
                                o_error  => o_error);
    
        o_id_workflow := l_ref_row.id_workflow;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ID_WORKFLOW',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_id_workflow;

    /**
    * Returns referral patient identifier
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional id, institution and software 
    * @param   i_id_ref          Referral identifier
    * @param   o_id_patient      Referral patient identifier
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE             
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-07-2013
    */
    FUNCTION get_id_patient
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        o_id_patient OUT p1_external_request.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_row p1_external_request%ROWTYPE;
    BEGIN
        g_error  := 'Init get_id_patient / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref;
        g_retval := get_ref_row(i_lang   => i_lang,
                                i_prof   => i_prof,
                                i_id_ref => i_id_ref,
                                o_rec    => l_ref_row,
                                o_error  => o_error);
    
        o_id_patient := l_ref_row.id_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ID_PATIENT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_id_patient;

    /**
    * Returns the professional that created the referral (id_prof_requested)
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional id, institution and software 
    * @param   i_id_ref             Referral identifier
    * @param   o_id_prof_requested  Professional that created the referral
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE             
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-03-2014
    */
    FUNCTION get_id_prof_requested
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_ref            IN p1_external_request.id_external_request%TYPE,
        o_id_prof_requested OUT p1_external_request.id_prof_requested%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_row p1_external_request%ROWTYPE;
    BEGIN
        g_error  := 'Init get_id_prof_requested / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref;
        g_retval := get_ref_row(i_lang   => i_lang,
                                i_prof   => i_prof,
                                i_id_ref => i_id_ref,
                                o_rec    => l_ref_row,
                                o_error  => o_error);
    
        o_id_prof_requested := l_ref_row.id_prof_requested;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ID_PROF_REQUESTED',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_id_prof_requested;

    /**
    * Returns the institution dest identifier
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional id, institution and software 
    * @param   i_id_ref             Referral identifier
    * @param   o_id_inst_dest       Institution dest identifier
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE             
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-04-2014
    */
    FUNCTION get_id_inst_dest
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        o_id_inst_dest OUT p1_external_request.id_inst_dest%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_row p1_external_request%ROWTYPE;
    BEGIN
        g_error  := 'Init get_id_inst_dest / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref;
        g_retval := get_ref_row(i_lang   => i_lang,
                                i_prof   => i_prof,
                                i_id_ref => i_id_ref,
                                o_rec    => l_ref_row,
                                o_error  => o_error);
    
        o_id_inst_dest := l_ref_row.id_inst_dest;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ID_INST_DEST',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_id_inst_dest;

    /**
    * Returns the professional that requested the referral
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software 
    * @param   i_id_ref                  Referral identifier
    *
    * @RETURN  Professional identifier that requested the referral
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-09-2013
    */
    FUNCTION get_prof_req_id
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) RETURN p1_external_request.id_prof_requested%TYPE IS
        l_result            p1_external_request.id_prof_requested%TYPE;
        l_params            VARCHAR2(1000 CHAR);
        l_id_prof_requested p1_external_request.id_prof_requested%TYPE;
        l_id_prof_roda      ref_orig_data.id_professional%TYPE;
    BEGIN
        l_params := 'i_id_ref=' || i_id_ref;
        g_error  := 'Init get_prof_req_name / ' || l_params;
    
        SELECT p.id_prof_requested, r.id_professional
          INTO l_id_prof_requested, l_id_prof_roda
          FROM p1_external_request p
          LEFT JOIN ref_orig_data r
            ON p.id_external_request = r.id_external_request
         WHERE p.id_external_request = i_id_ref;
    
        g_error  := 'Call get_prof_req_id / l_id_prof_requested=' || l_id_prof_requested || ' l_id_prof_roda=' ||
                    l_id_prof_roda || ' / ' || l_params;
        l_result := get_prof_req_id(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_id_prof_requested => l_id_prof_requested,
                                    i_id_prof_roda      => l_id_prof_roda);
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLCODE || ' ' || SQLERRM);
            RETURN NULL;
    END get_prof_req_id;

    /**
    * Returns the professional that requested the referral
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software 
    * @param   i_id_prof_requested       Professional that requested the referral (workflows other than at hospital entrance workflow)
    * @param   i_id_prof_roda            Professional identifier that requested the referral (at hospital entrance workflow)
    *
    * @RETURN  Professional identifier that requested the referral
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-09-2013
    */
    FUNCTION get_prof_req_id
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_id_prof_roda      IN ref_orig_data.id_professional%TYPE
    ) RETURN p1_external_request.id_prof_requested%TYPE IS
        l_result p1_external_request.id_prof_requested%TYPE;
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_id_prof_requested=' || i_id_prof_requested || ' i_id_prof_roda=' || i_id_prof_roda;
        g_error  := 'Init get_prof_req_name / ' || l_params;
    
        IF i_id_prof_roda IS NOT NULL
        THEN
            l_result := i_id_prof_roda;
        ELSE
            l_result := i_id_prof_requested;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLCODE || ' ' || SQLERRM);
            RETURN NULL;
    END get_prof_req_id;

    /**
    * Returns the name of professional that requested the referral
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software 
    * @param   i_id_ref                  Referral identifier
    *
    * @RETURN  Name of the professional that requested the referral
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-09-2013
    */
    FUNCTION get_prof_req_name
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR2 IS
        l_result      VARCHAR2(1000 CHAR);
        l_params      VARCHAR2(1000 CHAR);
        l_id_prof_req p1_external_request.id_prof_requested%TYPE;
    BEGIN
        l_params := 'i_id_ref=' || i_id_ref;
        g_error  := 'Init get_prof_req_name / ' || l_params;
    
        l_id_prof_req := get_prof_req_id(i_lang => i_lang, i_prof => i_prof, i_id_ref => i_id_ref);
    
        l_params := l_params || ' l_id_prof_req=' || l_id_prof_req;
    
        -- getting professional name that requested the referral
        g_error  := 'Call pk_prof_utils.get_name_signature / ' || l_params;
        l_result := pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => l_id_prof_req);
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLCODE || ' ' || SQLERRM);
            RETURN NULL;
    END get_prof_req_name;

    /**
    * Returns the name of professional that requested the referral
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software 
    * @param   i_id_prof_requested       Professional that is responsible for the referral
    * @param   i_id_prof_roda            Professional identifier that requested the referral (at hospital entrance workflow)
    *
    * @RETURN  Name of the professional that requested the referral
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-09-2013
    */
    FUNCTION get_prof_req_name
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_id_prof_roda      IN ref_orig_data.id_professional%TYPE
    ) RETURN VARCHAR2 IS
        l_result      VARCHAR2(1000 CHAR);
        l_params      VARCHAR2(1000 CHAR);
        l_id_prof_req p1_external_request.id_prof_requested%TYPE;
    BEGIN
        l_params := 'i_id_prof_requested=' || i_id_prof_requested || ' i_id_prof_roda=' || i_id_prof_roda;
        g_error  := 'Init get_prof_req_name / ' || l_params;
    
        -- getting professional that requested the referral
        l_id_prof_req := get_prof_req_id(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_id_prof_requested => i_id_prof_requested,
                                         i_id_prof_roda      => i_id_prof_roda);
    
        -- getting professional name that requested the referral
        g_error  := 'Call pk_prof_utils.get_name_signature / ' || l_params;
        l_result := pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => l_id_prof_req);
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLCODE || ' ' || SQLERRM);
            RETURN NULL;
    END get_prof_req_name;

    /**
    * Returns the num_order of professional that requested the referral
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional id, institution and software 
    * @param   i_id_prof_requested       Professional that is responsible for the referral
    * @param   i_id_prof_roda            Professional identifier that requested the referral (at hospital entrance workflow)
    *
    * @RETURN  Name of the professional that requested the referral
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-09-2013
    */
    FUNCTION get_prof_req_num_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_id_prof_roda      IN ref_orig_data.id_professional%TYPE
    ) RETURN professional.num_order%TYPE IS
        l_result      professional.num_order%TYPE;
        l_params      VARCHAR2(1000 CHAR);
        l_id_prof_req p1_external_request.id_prof_requested%TYPE;
        l_error       t_error_out;
    BEGIN
        l_params := 'i_id_prof_requested=' || i_id_prof_requested || ' i_id_prof_roda=' || i_id_prof_roda;
        g_error  := 'Init get_prof_req_name / ' || l_params;
    
        -- getting professional that requested the referral
        l_id_prof_req := get_prof_req_id(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_id_prof_requested => i_id_prof_requested,
                                         i_id_prof_roda      => i_id_prof_roda);
    
        g_error  := 'Call pk_prof_utils.get_num_order / ' || l_params;
        g_retval := pk_prof_utils.get_num_order(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_prof_id   => l_id_prof_req,
                                                o_num_order => l_result,
                                                o_error     => l_error);
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLCODE || ' ' || SQLERRM);
            RETURN NULL;
    END get_prof_req_num_order;

    /**
    * Returns if a professional is the one responsible for the patient or not. 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier
    *
    * @RETURN  1 if sucess, 0 otherwise
    * @author  Joao Almeida
    * @version 1.0
    * @since   08-03-2010   
    */
    FUNCTION check_prof_resp
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) RETURN PLS_INTEGER IS
        l_params       VARCHAR2(1000 CHAR);
        l_id_prof_resp professional.id_professional%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref;
    
        g_error := 'Init check_prof_resp / ' || l_params;
        IF i_id_ref IS NULL
        THEN
            RETURN g_i_false;
        END IF;
    
        g_error        := 'Call get_prof_req_id / ' || l_params;
        l_id_prof_resp := get_prof_req_id(i_lang => i_lang, i_prof => i_prof, i_id_ref => i_id_ref);
    
        g_error := 'l_id_prof_resp=' || l_id_prof_resp || ' / ' || l_params;
        IF l_id_prof_resp = i_prof.id
        THEN
            RETURN g_i_true;
        ELSE
            RETURN g_i_false;
        END IF;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN g_i_false;
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN g_i_false;
    END check_prof_resp;

    /**
    * Returns the flg_type of a given Referral
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_id_ref            Referral identifier 
    * @param   o_flg_type          on success returns the flg_type for the given referral
    * @param   O_ERROR             an error message, set when return=false
    *
    * @RETURN  TRUE             
    * @author  Joana Barroso
    * @version 1.0
    * @since   19-09-2012
    */
    FUNCTION get_flg_type
    (
        i_lang     IN language.id_language%TYPE,
        i_id_ref   IN p1_external_request.id_external_request%TYPE,
        o_flg_type OUT p1_external_request.flg_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_row p1_external_request%ROWTYPE;
    BEGIN
        g_error  := 'Init get_flg_type / ID_REF=' || i_id_ref;
        g_retval := get_ref_row(i_lang   => i_lang,
                                i_prof   => NULL,
                                i_id_ref => i_id_ref,
                                o_rec    => l_ref_row,
                                o_error  => o_error);
    
        o_flg_type := l_ref_row.flg_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_FLG_TYPE',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_flg_type;

BEGIN
    -- Initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_p1_external_request;
/
