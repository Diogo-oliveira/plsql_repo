/*-- Last Change Revision: $Rev: 1403306 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2012-10-25 14:53:13 +0100 (qui, 25 out 2012) $*/

CREATE OR REPLACE PACKAGE pk_ref_dest_reg AS

    /**
    * Checks if theres a process in the institution that matches the patient
    *
    * ATENTION: This function is used only for simulation purposes.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional id, institution and software
    * @param   I_PAT patient id professional, institution and software ids
    * @param   I_SEQ_NUM external system id
    * @param   I_SNS National Health System number
    * @param   I_NAME patient name
    * @param   I_GENDER patient gender (M, F or I)
    * @param   I_DT_BIRTH patient date of birth                
    * @param   O_DATA_OUT patient data to be returned    
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 3.0
    * @since   30-10-2007
    */
    FUNCTION get_match
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pat      IN patient.id_patient%TYPE,
        i_sns      IN VARCHAR2,
        i_name     IN VARCHAR2,
        i_gender   IN VARCHAR2,
        i_dt_birth IN VARCHAR2,
        o_data_out OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets the connection between the patient id and the hospital process
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional id, institution and software
    * @param   I_PAT patient
    * @param   I_SEQ_NUM external system id
    * @param   I_CLIN_REC patient process number on the institution, if available.
    * @param   O_ID_MATCH P1_MATCH identifier
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao S
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION set_match
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pat      IN patient.id_patient%TYPE,
        i_seq_num  IN p1_match.sequential_number%TYPE,
        i_clin_rec IN clin_record.num_clin_record%TYPE,
        i_epis     IN episode.id_episode%TYPE,
        o_id_match OUT p1_match.id_match%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Inserts/updates patient clinical record
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Professional id, institution and software
    * @param   i_pat          Patient identifier
    * @param   i_num_clin_rec Patient process number on the institution, if available.
    * @param   o_id_clin_rec  Id created/updated        
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-12-2009
    */
    FUNCTION set_clin_record
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat          IN patient.id_patient%TYPE,
        i_num_clin_rec IN clin_record.num_clin_record%TYPE,
        i_epis         IN episode.id_episode%TYPE,
        o_id_clin_rec  OUT clin_record.id_clin_record%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels match
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_pat patient id 
    * @param   i_prof professional id, institution and software
    * @param   i_id not in use
    * @param   i_id_ext_sys not in use    
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Jo∆o S
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION drop_match
    (
        i_lang       IN language.id_language%TYPE,
        i_pat        IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_id         IN patient.id_patient%TYPE,
        i_id_ext_sys IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Validates if the professional is associated to the dcs provided 
    *
    * @param   i_prof Professional id, institution and software
    * @param   i_dcs dep_clin_serv id
    * @param   i_func functionality id (sys_functionality)
    *
    * @RETURN  Y if true, N otherwise
    * @author  Joao Sa
    * @version 4.0
    * @since   24-11-2007
    */
    FUNCTION validate_dcs
    (
        i_prof IN profissional,
        i_dcs  IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets departments available for forwarding the request. 
    *
    * @param   I_LANG          Language associated to the professional executing the request
    * @param   I_PROF          Professional id, institution and software
    * @param   i_ext_req       Referral id
    * @param   o_dep           Department ids and description    
    * @param   O_ERROR         An error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_dep_forward_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_dep     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets clinical_services (the ids are dep_clin_serv) available for forwarding the request. 
    *
    * @param   I_LANG          Language associated to the professional executing the request
    * @param   I_PROF          Professional id, institution and software
    * @param   i_ext_req       Referral id
    * @param   i_dep           Department id    
    * @param   o_clin_serv     Dep_clin_serv ids and clinical services description    
    * @param   O_ERROR         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_clin_serv_forward_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ext_req   IN p1_external_request.id_external_request%TYPE,
        i_dep       IN department.id_department%TYPE,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Check if a professional can create referrals 
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_param         Sys_functionality to validate
    * @param   o_valid         Flag indicating if professional can create referrals  
    * @param   o_error         Error message, set when return=false
    *
    * @value   o_valid         {*} 'Y' if can create referral  {*} 'N' if can't create referral  
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   14-12-2009
    *
    FUNCTION check_ref_creation
    (
        i_lang  IN LANGUAGE.id_language%TYPE,
        i_prof  IN profissional,
        i_param IN sys_functionality.id_functionality%TYPE DEFAULT NULL,
        o_valid OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    */

    /*
    * Returns institutions info 
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   o_inst          Institutions info
    * @param   o_other         Label Other institution
    * @param   o_error         Error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   14-12-2009
    */
    FUNCTION get_instit_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_inst  OUT pk_types.cursor_type,
        o_other OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * Get professional data
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_num_order     Professional NUM ORDER 
    * @param   o_prof         pProfessional data  
    * @param   o_error         Error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   15-12-2009
    */
    FUNCTION get_prof_data
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_num_order IN professional.num_order%TYPE,
        o_prof      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the Sequencial Number of the p1_match table for the specified patient
    * and the num_clin_record for the patient on the specific institution
    *
    * @param   i_lang           Language id
    * @param   i_prof           Professional, institution, software
    * @param   i_old_inst_dest  Id of the old institution
    * @param   i_patient        Department id
    * @param   o_seq_num        Sequencial Number 
    * @param   o_num_clin_rec   Clinical Record Number
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Jo„o Almeida
    * @version 1.0
    * @since   13-07-2010
    */
    FUNCTION check_match
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_old_inst_dest IN institution.id_institution%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        o_seq_num       OUT p1_match.sequential_number%TYPE,
        o_num_clin_rec  OUT clin_record.num_clin_record%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ref_dest_reg;
/
