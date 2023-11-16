/*-- Last Change Revision: $Rev: 2028835 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:14 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_external_request IS

    -- Author  : RICARDO.PATROCINIO
    -- Created : 29-10-2009 14:03:10
    -- Purpose : API for table P1_EXTERNAL_REQUEST

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
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_rec        OUT p1_external_request%ROWTYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN p1_external_request.id_external_request%TYPE;
        
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
    ) RETURN BOOLEAN;

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
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        o_flg_status OUT p1_external_request.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_ref        IN p1_external_request.id_external_request%TYPE,
        o_dep_clin_serv OUT p1_external_request.id_dep_clin_serv%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;
    
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
    ) RETURN BOOLEAN;

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
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;

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
    ) RETURN p1_external_request.id_prof_requested%TYPE;

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
    ) RETURN p1_external_request.id_prof_requested%TYPE;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN professional.num_order%TYPE;

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
    ) RETURN PLS_INTEGER;

    g_i_false PLS_INTEGER := 0;
    g_i_true  PLS_INTEGER := 1;

END pk_p1_external_request;
/
