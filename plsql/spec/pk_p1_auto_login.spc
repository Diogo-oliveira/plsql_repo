/*-- Last Change Revision: $Rev: 2028830 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_auto_login AS
    /**
    * Validates if the session is valid. Return professional data.
    *
    * @param   i_id_session    Session identifier
    * @param   i_provider      Provider identifier. {*} REFERRAL {*} P1
    * @param   o_professional  Professional identifier
    * @param   o_user         professional login
    * @param   o_language      Professional language identifier
    * @param   o_institution   Institution identifier
    * @param   o_software      Software identifier
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   10-12-2007
    */
    FUNCTION validate_session
    (
        i_id_session   IN VARCHAR2,
        i_provider     IN VARCHAR2,
        o_professional OUT professional.id_professional%TYPE,
        o_user         OUT ab_user_info.login%TYPE,
        o_language     OUT LANGUAGE.id_language%TYPE,
        o_institution  OUT institution.id_institution%TYPE,
        o_software     OUT software.id_software%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);

    g_retval BOOLEAN;
    g_found  BOOLEAN;
    g_exception EXCEPTION;
    g_error VARCHAR2(4000);

    g_referral_soft_id software.id_software%TYPE;

END pk_p1_auto_login;
/
