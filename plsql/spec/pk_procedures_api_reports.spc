/*-- Last Change Revision: $Rev: 2028876 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:30 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_procedures_api_reports IS

    FUNCTION get_procedure_listview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN table_number,
        i_scope            IN NUMBER,
        i_flg_scope        IN VARCHAR2,
        i_start_date       IN VARCHAR2,
        i_end_date         IN VARCHAR2,
        i_cancelled        IN VARCHAR2,
        i_crit_type        IN VARCHAR2,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a procedure detail
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_interv_presc_det            Procedure detail order id
    * @param     o_interv_order                Cursor
    * @param     o_interv_execution            Cursor
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/06/21
    */

    FUNCTION get_procedure_orders
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_order     OUT pk_types.cursor_type,
        o_interv_execution OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a procedure detail
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_episode                     Episode id
    * @param     i_interv_presc_det            Procedure detail order id
    * @param     o_interv_order                Cursor
    * @param     o_interv_supplies             Cursor
    * @param     o_interv_co_sign              Cursor
    * @param     o_interv_clinical_questions   Cursor
    * @param     o_interv_execution            Cursor
    * @param     o_interv_execution_images     Cursor
    * @param     o_interv_doc                  Cursor
    * @param     o_interv_review               Cursor
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/06/21
    */

    FUNCTION get_procedure_detail
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_order              OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a procedure detail history
    *
    * @param     i_lang                        Language id
    * @param     i_prof                        Professional
    * @param     i_episode                     Episode id
    * @param     i_interv_presc_det            Procedure detail order id
    * @param     o_interv_order                Cursor
    * @param     o_interv_supplies             Cursor
    * @param     o_interv_co_sign              Cursor
    * @param     o_interv_clinical_questions   Cursor
    * @param     o_interv_execution            Cursor
    * @param     o_interv_execution_images     Cursor
    * @param     o_interv_doc                  Cursor
    * @param     o_interv_review               Cursor
    * @param     o_error                       Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.5.2
    * @since     2016/06/21
    */

    FUNCTION get_procedure_detail_history
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_order              OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_alias_translation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_interv   IN intervention.code_intervention%TYPE,
        i_dep_clin_serv IN intervention_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_user_exception  EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

END pk_procedures_api_reports;
/
