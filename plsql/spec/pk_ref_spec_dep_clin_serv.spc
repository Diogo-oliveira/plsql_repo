/*-- Last Change Revision: $Rev: 1461236 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2013-04-19 10:52:33 +0100 (sex, 19 abr 2013) $*/

CREATE OR REPLACE PACKAGE pk_ref_spec_dep_clin_serv IS

    -- Author  : FILIPE.SOUSA
    -- Created : 22-11-2010 17:26:45
    -- Purpose : functions for REF_SPEC_DEP_CLIN_SERV

    /**
    * Gets referral speciality default related to id_dep_clin_serv
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   id_dep_clin_serv Department and clinical service identifier
    * @param   i_id_patient     Patient identifier
    * @param   i_id_external_sys       External system identifier
    * @param   i_flg_availability      Type of referring available in the institution
    * @param   o_id_speciality  Speciality identifier
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  FILIPE.SOUSA
    * @version 1.0
    * @since   22-11-2010
    */
    FUNCTION get_speciality_for_dcs
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_external_sys  IN p1_spec_dep_clin_serv.id_external_sys%TYPE,
        i_flg_availability IN p1_spec_dep_clin_serv.flg_availability%TYPE,
        o_id_speciality    OUT p1_speciality.id_speciality%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get speciality for dcs
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   id_dep_clin_serv  IN  dep_clin_serv.id_dep_clin_serv%TYPE
    *
    * @param   id_speciality  p1_speciality.id_speciality%type
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   22-11-2010
    */
    FUNCTION speciality_for_dcs_is_ok(i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE) RETURN table_number;

    /**
    * speciality_for_dcs_multi
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   id_dep_clin_serv  IN  dep_clin_serv.id_dep_clin_serv%TYPE
    *
    * @param   id_speciality  p1_speciality.id_speciality%type
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   22-11-2010
    */
    FUNCTION speciality_for_dcs_multi(i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE) RETURN table_number;

    g_exception EXCEPTION;

END pk_ref_spec_dep_clin_serv;
/
