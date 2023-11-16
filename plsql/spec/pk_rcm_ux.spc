/*-- Last Change Revision: $Rev: 1291526 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2012-05-08 11:05:55 +0100 (ter, 08 mai 2012) $*/

CREATE OR REPLACE PACKAGE pk_rcm_ux IS

    /**
    * Gets available transitions for a workflow/status recommendation
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_workflow  Recommendation workflow identifier
    * @param   i_id_status    Recommendation status identifier
    * @param   o_transitions  Transitions available
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   09-02-2012
    */
    FUNCTION get_rcm_transitions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_workflow IN pat_rcm_h.id_workflow%TYPE,
        i_id_status   IN pat_rcm_h.id_status%TYPE,
        o_transitions OUT NOCOPY pk_types.cursor_type,
        o_error       OUT NOCOPY t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if this recommendation has transitions available
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_workflow  Recommendation workflow identifier
    * @param   i_id_status    Recommendation status identifier
    *
    * @return  'Y'- if transitions available, 'N'- otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   07-05-2012
    */
    FUNCTION check_transitions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_workflow IN pat_rcm_h.id_workflow%TYPE,
        i_id_status   IN pat_rcm_h.id_status%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets all recommendations data of this patient. Data returned is the latest of all recommendation instances
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_patient   Patient identifier
    *
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   07-02-2012
    */
    FUNCTION get_pat_rcm
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_rcm_data   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets historic data of this recommendation detail (used by flash)
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_patient   Patient identifier
    * @param   i_id_rcm       Recommendation identifier
    * @param   i_id_rcm_det   Recommendation detail identifier
    * @param   o_list_act     Array with actual recommendations info
    * @param   o_list_hist    Array with historic recommendations info
    *
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   22-02-2012
    */
    FUNCTION get_pat_rcm_det_flash
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_rcm_det.id_patient%TYPE,
        i_id_rcm     IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det IN pat_rcm_det.id_rcm_det%TYPE,
        o_list_act   OUT table_table_varchar,
        o_list_hist  OUT table_table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets actual and historic data of this recommendation detail
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_patient   Patient identifier
    * @param   i_id_rcm       Recommendation identifier
    * @param   i_id_rcm_det   Recommendation detail identifier
    * @param   o_rcm_data     Recommendation info
    * @param   o_error        Error information
    *
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   27-04-2012
    */
    FUNCTION get_pat_rcm_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_rcm_det.id_patient%TYPE,
        i_id_rcm     IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det IN pat_rcm_det.id_rcm_det%TYPE,
        o_rcm_data   OUT pk_rcm_constant.t_cur_rcm_info,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates recommendation status
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identifier and its context (institution and software)
    * @param   i_id_patient               Patient identifier
    * @param   i_id_episode               Episode identifier
    * @param   i_id_rcm                   Recommendation identifier
    * @param   i_id_rcm_det               Recomendation detail identifier
    * @param   i_id_workflow              Workflow identifier
    * @param   i_id_workflow_action       Workflow action identifier
    * @param   i_id_status_begin          Reccomendation status begin
    * @param   i_id_status_end            Reccomendation status end
    * @param   i_rcm_notes                Notes associated to this recommendation
    * @param   i_id_category              Professional category identifier
    * @param   i_id_profile_template      Professional profile template identifier
    * @param   i_id_functionality         Professional functionality identifier
    * @param   i_param                    Array of parameters to be processed by workflows
    * @param   o_flg_show                 Flag indicating if o_msg is shown
    * @param   o_msg_title                Message title to be shown to the professional
    * @param   o_msg                      Message to be shown to the professional
    * @param   o_button                   Type of button to show with message
    * @param   o_error                    Error information
    *
    * @value   o_flg_show                 {*} Y - o_msg is shown {*} N - otherwise
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   10-02-2012
    */
    FUNCTION set_pat_rcm
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_rcm             IN pat_rcm_det.id_rcm%TYPE,
        i_id_rcm_det         IN pat_rcm_det.id_rcm_det%TYPE,
        i_id_workflow        IN pat_rcm_h.id_workflow%TYPE,
        i_id_workflow_action IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_status_begin    IN pat_rcm_h.id_status%TYPE,
        i_id_status_end      IN pat_rcm_h.id_status%TYPE,
        i_rcm_notes          IN pat_rcm_h.notes%TYPE,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

END pk_rcm_ux;
/
