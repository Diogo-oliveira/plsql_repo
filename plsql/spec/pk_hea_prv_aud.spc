/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_hea_prv_aud IS

    /**
    * Resets all the variables.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE reset_var;

    /**
    * Returns the label for audit trail 'Patient'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_audit_patient
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /**
    * Returns the manchester audit value for the tag given as parameter.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req           Audit request Id (Manchester audit only)
    * @param i_id_audit_req_prof      Audit request professional Id (Manchester audit only)
    * @param i_id_audit_req_prof_epis Audit request professional episode Id (Manchester audit only)
    * @param i_tag                    Tag to be replaced
    * @param o_data_rec               Tag's data    
    *
    * @return                         The manchester audit value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_audit_req           IN audit_req.id_audit_req%TYPE,
        i_id_audit_req_prof      IN audit_req_prof.id_audit_req_prof%TYPE,
        i_id_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        i_tag                    IN header_tag.internal_name%TYPE,
        o_data_rec               OUT t_rec_header_data
    ) RETURN BOOLEAN;

    /**
    * Returns the manchester audit value for the tag given as parameter.
    *
    * @param i_lang                   Language Id
    * @param i_prof                   Professional Id
    * @param i_id_audit_req           Audit request Id (Manchester audit only)
    * @param i_id_audit_req_prof      Audit request professional Id (Manchester audit only)
    * @param i_id_audit_req_prof_epis Audit request professional episode Id (Manchester audit only)
    * @param i_tag                    Tag to be replaced
    *
    * @return                         The manchester audit value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_audit_req           IN audit_req.id_audit_req%TYPE,
        i_id_audit_req_prof      IN audit_req_prof.id_audit_req_prof%TYPE,
        i_id_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        i_tag                    IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2;

    -- Log initialization.
    /* Stores log error messages. */
    g_error VARCHAR2(4000);

    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    g_found BOOLEAN;
    g_exception EXCEPTION;

    g_pat_name               patient.name%TYPE;
    g_id_epis_ext_sys        VARCHAR2(1000);
    g_id_professional        professional.id_professional%TYPE;
    g_id_episode             episode.id_episode%TYPE;
    g_id_audit_req_prof      audit_req_prof.id_audit_req_prof%TYPE;
    g_id_audit_req_prof_epis audit_req_prof_epis.id_audit_req_prof_epis%TYPE;
    g_title_epis_anamnesis   sys_message.desc_message%TYPE;
    g_epis_anamnesis         VARCHAR2(1000);

END;
/
