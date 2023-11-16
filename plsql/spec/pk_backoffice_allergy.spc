/*-- Last Change Revision: $Rev: 2028509 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:13 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_allergy IS

    -- Author  : ANA.RITA & FABIO.OLIVEIRA
    -- Created : 02-12-2008 16:09:48
    -- Purpose : Configurações de alergias
    -- Public type declarations

    /********************************************************************************************
    * get_allergy_state_list
    *
    * @param i_lang                Prefered language ID
    * @param i_code_domain         Code to obtain Options
    * @param o_list                List of states - allergys
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      ARM
    * @version                     0.1
    * @since                       2008/12/02
    ********************************************************************************************/
    FUNCTION get_allergy_state_list
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_code_domain IN sys_domain.code_domain%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get (Primarys Allergies) Group List
    *
    * @param i_lang                  Prefered language ID
    * @param o_primary_allergy       Primary Allergy Group List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      ARM
    * @version                     1.0
    * @since                       2008/12/09
    ********************************************************************************************/
    FUNCTION get_primary_allergies_list
    (
        i_lang            IN LANGUAGE.id_language%TYPE,
        o_primary_allergy OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get (Secondary Allergies) Group List
    *
    * @param i_allergy_parent        Allergy Parent ID
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param o_g_list                Allergy List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      ARM
    * @version                     1.0
    * @since                       2008/12/10
    ********************************************************************************************/
    FUNCTION get_sec_allergies_list
    (
        i_allergy_parent IN allergy.id_allergy%TYPE,
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        o_g_list         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update an allergy status or a group of allergies statuses
    *
    *
    * @param i_allergy_parent        Allergy Parent ID
    * @param i_software        Software ID
    * @param i_lang            Prefered language ID
    * @param i_institution     Institution ID
    * @param i_allergy         Allergy ID
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      ARM
    * @version                     1.0
    * @since                       2009/01/07
    ********************************************************************************************/
    FUNCTION set_sec_allergies_list
    (
        i_allergy_parent IN allergy.id_allergy%TYPE,
        i_software       IN software.id_software%TYPE,
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_val            IN sys_domain.val%TYPE,
        i_allergy        IN allergy.id_allergy%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Active Allergies List
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution ID
    * @param i_software            Software ID
    * @param o_list                Allergy List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      ARM
    * @version                     1.0
    * @since                       2008/12/10
    ********************************************************************************************/
    FUNCTION get_active_allergies_list
    (
        i_software    IN software.id_software%TYPE,
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Secondary Allergies Group Status List
    *
    * @param i_allergy_parent        Allergy Parent ID
    * @param i_institution           Institution ID
    * @param i_lang                  Prefered language ID
    * @param o_allergy               Allergy List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      ARM
    * @version                     1.0
    * @since                       2008/12/10
    ********************************************************************************************/
    FUNCTION get_allergy_all_flg_type
    (
        i_allergy_parent IN allergy.id_allergy%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_lang           IN LANGUAGE.id_language%TYPE,
        o_allergy        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Parent Allergy Description
    *
    * @param i_lang                  Prefered language ID
    * @param i_allergy_parent        Allergy Parent ID
    *
    *
    * @return                      allergy description
    *
    * @author                      ARM
    * @version                     1.0
    * @since                       2008/12/10
    ********************************************************************************************/
    FUNCTION get_allergy_parent
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_allergy_parent IN allergy.id_allergy%TYPE
    ) RETURN VARCHAR2;

    g_found        BOOLEAN;
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);

END pk_backoffice_allergy;
/
