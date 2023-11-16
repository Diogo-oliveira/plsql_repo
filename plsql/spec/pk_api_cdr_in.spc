/*-- Last Change Revision: $Rev: 1335249 $*/
/*-- Last Change by: $Author: pedro.carneiro $*/
/*-- Date of last change: $Date: 2012-06-27 16:07:01 +0100 (qua, 27 jun 2012) $*/

CREATE OR REPLACE PACKAGE pk_api_cdr_in IS

    /**
    * Get warning answers.
    * Information is retrieved from local workflow engine.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_actions      actions cursor
    * @param o_answers      answers cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/06/26
    */
    FUNCTION get_warning_answers
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_answers OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

END pk_api_cdr_in;
/
