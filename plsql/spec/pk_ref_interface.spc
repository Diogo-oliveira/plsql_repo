/*-- Last Change Revision: $Rev: 2028909 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_interface AS

    /**
    * Sets professional interface
    *
    * @param   I_PROF         Professional institution and software
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-06-2009
    */
    FUNCTION set_prof_interface(i_prof IN profissional) RETURN profissional;

    /**
    * Get Referral short detail (Patient Portal)
      *
    * @param i_lang                Language id
    * @param i_prof                Professional, Institution and Software ids
    * @param i_patient             Patient identifier
    * @param i_id_external_request Referral identifier
    * @param o_detail              Referral short detail
    * @param o_error               An error message, set when return=false
      *
      * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
      * @version 1.0
    * @since   06-10-2010
    */
    FUNCTION get_referral
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        o_detail              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets patient referral list
    *
    * @param i_lang                Language id
    * @param i_prof                Professional, Institution and Software ids
    * @param i_patient             Patient identifier
    * @param o_ref_list            Patient referral list
    * @param o_error               An error message, set when return=false
    *
    * @return  true if sucess, false otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   06-10-2010
    */

    FUNCTION get_referral_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        o_ref_list OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if professional exists. If not, creates him.
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Professional id, institution and software
    * @param   i_num_order    Professional num order for the appointment physician
    * @param   i_prof_name    Professional name for the appointment physician
    * @param   i_profile_templ       Profile template of the professional being created (only if it is being created)
    * @param   i_func                Functionality of the professional
    * @param   i_dcs          Department and Service to which the professional is related
    * @param   o_id_prof      Professional identifier
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-06-2009
    */
    FUNCTION set_professional_num_ord
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_num_order     IN professional.num_order%TYPE,
        i_prof_name     IN professional.name%TYPE,
        i_profile_templ IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_func          IN sys_functionality.id_functionality%TYPE DEFAULT NULL,
        i_dcs           IN prof_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_id_prof       OUT professional.id_professional%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ref_interface;
/
