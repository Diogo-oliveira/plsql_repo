/*-- Last Change Revision: $Rev: 1658137 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:21:37 +0000 (seg, 10 nov 2014) $*/

CREATE OR REPLACE PACKAGE pk_nnn_reset IS

    -- Author  : ARIEL.MACHADO
    -- Created : 1/13/2014 5:01:29 PM
    -- Purpose :  NANDA, NIC and NOC (NNN) - Reset methods for Nursing Care Plans

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations
    /**
    * Resets Patient's Nursing Care Plans (NANDA, NOC NIC) 
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param    i_patient     Collection of Patient ID
    * @param    i_episode     Collection of Episode ID
    * @param   o_error        Error information
    *
    * @return   True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   1/13/2014
    */
    FUNCTION reset_nnn_epis_care_plans
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

END pk_nnn_reset;
/
