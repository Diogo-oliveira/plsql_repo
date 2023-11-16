/*-- Last Change Revision: $Rev: 2028622 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:57 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_doc_macro_mig IS

    -- Author  : ARIEL.MACHADO
    -- Created : 1/28/2013 3:45:15 PM
    -- Purpose : Routines used for migration of prefilled templates

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations
    /**
    * Migration of all prefilled templates that were created by an institution using a specific template whenever the template is replaced by another.
    *
    * @param   i_lang           Language
    * @param   i_institution    Institution where the macros were created and that will be migrated
    * @param   i_from_template  Original template ID that was used in the creation of macros
    * @param   i_to_template    Template ID which replaces the previous one and will be used for the migration of macros
    *
    * @param   o_error          Error information
    *
    * @return  True or False on sucess or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.3.3
    * @since   1/24/2013 5:08:42 PM
    */
    FUNCTION mig_inst_macros
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_from_template IN doc_template.id_doc_template%TYPE,
        i_to_template   IN doc_template.id_doc_template%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

END pk_doc_macro_mig;
/
