/*-- Last Change Revision: $Rev: 2028838 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_interv AS

    /**
    * get common institution based on all required interventions
    *
    * @param    i_lang            preferred language id
    * @param    i_prof            object (id of professional, id of institution, id of software)
    * @param    i_intervs         array of requested interventions
    * @param    o_inst            cursor with institution information
    * @param    o_error           error message structure
    *
    * @return   boolean           false in case of error, otherwise true
    *
    * @author   Carlos Loureiro
    * @version  1.0
    * @since    2009/08/28
    */
    FUNCTION get_interv_inst
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_intervs IN table_number,
        o_inst    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_interv_inst
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_interventions IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    /**
    * get common institution based on all required interventions
    *
    * @param    i_lang            preferred language id
    * @param    i_prof            object (id of professional, id of institution, id of software)
    * @param    i_rehabs          array of requested rehabs (intervention_id)
    * @param    o_inst            cursor with institution information
    * @param    o_error           error message structure
    *
    * @return   boolean           false in case of error, otherwise true
    *
    * @author   Ana Monteiro
    * @version  1.0
    * @since    03-06-2011
    */
    FUNCTION get_rehab_inst
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rehabs IN table_number,
        o_inst   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_inst
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rehabs IN VARCHAR2
    ) RETURN t_tbl_core_domain;    
END;
/
