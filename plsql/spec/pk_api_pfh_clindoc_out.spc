/*-- Last Change Revision: $Rev: 2028481 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:03 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_pfh_clindoc_out IS

    -- Author  : Alexandre Santos
    -- Created : 28-07-2011 19:00:00
    -- Purpose : Handle calls of medication to (clinical documentation BU)

    /********************************************************************************************
    * Function that returns diagnosis for an episode
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_id_episode             episode ID
    *
    * @param o_diag                   Cursor with diagnoses' information
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         Alexandre santos
    * @version                        2.6.1.2
    * @since                          2011/08/16
    **********************************************************************************************/
    FUNCTION get_epis_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_diag    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    
    /********************************************************************************************
    * Function that returns the diagnosis description registered in an episode
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_id_episode             episode ID
    * @param i_epis_diagnosis         episode diagnosis ID
    *
    * @param o_desc_diag              Diagnosis description
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2012/05/29
    **********************************************************************************************/
    FUNCTION get_epis_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_desc_diag      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get information on a CDR engine call.
    * The call events are filtered by the input task types.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_call         call identifier
    * @param i_task_types   task type identifiers list
    * @param i_task_reqs    task request identifiers list
    * @param o_icon         cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/12/13
    */
    FUNCTION get_call_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_call       IN cdr_call.id_cdr_call%TYPE,
        i_task_types IN table_number,
        i_task_reqs  IN table_varchar,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    -- logging variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_error         VARCHAR2(4000);

END pk_api_pfh_clindoc_out;
/
