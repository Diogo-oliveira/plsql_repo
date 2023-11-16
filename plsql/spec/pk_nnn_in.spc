/*-- Last Change Revision: $Rev: 1658137 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:21:37 +0000 (seg, 10 nov 2014) $*/

CREATE OR REPLACE PACKAGE pk_nnn_in IS

    -- Author  : ARIEL.MACHADO
    -- Created : 7/9/2014 3:18:38 PM
    -- Purpose : Package for Nursing Care Plan (NANDA/NIC/NOC) functionality that contains functions which consume API from other modules

    -- Public type declarations
    SUBTYPE t_terminology_info_rec IS pk_api_termin_server_func.t_terminology_info_rec;

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Get terminology information
    *
    * @param   i_terminology_version      Terminology version ID
    *
    * @return  Terminology information
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   7/9/2014
    */
    FUNCTION get_terminology_information(i_terminology_version IN terminology_version.id_terminology_version%TYPE)
        RETURN t_terminology_info_rec;

END pk_nnn_in;
/
