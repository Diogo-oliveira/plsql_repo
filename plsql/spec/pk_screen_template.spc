/*-- Last Change Revision: $Rev: 2028963 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:00 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_screen_template IS

    /**
    * Gets xml screen template to patient id screen
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_CONTEXT the screen context
    * @param   O_XML_TEMPLATE the xml code representing the template
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luis Gaspar
    * @version 1.0
    * @since   30-08-2006
    */
    FUNCTION get_screen_template
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_context      IN VARCHAR2,
        o_xml_template OUT sys_screen_template.xml_template%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

END pk_screen_template;
/
