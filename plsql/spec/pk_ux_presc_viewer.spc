/*-- Last Change Revision: $Rev: 2029035 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:25 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ux_presc_viewer IS

    -- Author  : JOANA.BARROSO
    -- Created : 14-03-2014 15:04:35
    -- Purpose : Funções para o viewer

    /**
    * Get draft RX prescription list for a given episode
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis         Episode identification
    *
    * @return  true or false on success or error
    *
    * @author  JOANA.BARROSO
    * @version 3.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_draft
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN presc.id_epis_create%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get all active RX prescription list for a given episode
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis         Episode identification
    *
    * @return  true or false on success or error
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_epis
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,        
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get all active RX prescription list for a given patient from previous episodes
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_pat          Patient identification
    * @param   i_epis         Episode identification    
    *
    * @return  true or false on success or error
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_all
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_pat   IN patient.id_patient%TYPE,
        i_epis  IN episode.id_episode%TYPE,         
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get detail for a given RX prescription
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id           Prescription identification
    * @param   i_type         Type of prescription list
    *
    * @value   i_type   {*} 'DRAFT' get_rx_prescription_darft 
                        {*} 'ALL' get_rx_prescription_all    
                        {*} 'EPIS' get_rx_prescription_epis    
    *
    * @return  true or false on success or error
    *
    * @author  JOANA.BARROSO
    * @version 2.6.3.14
    * @since   21-03-2014
    */
    FUNCTION get_rx_prescription_detail
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id     IN NUMBER,
        i_type   IN VARCHAR2,
        o_detail OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ux_presc_viewer;
/
