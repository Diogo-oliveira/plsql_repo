/*-- Last Change Revision: $Rev: 2028472 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:00 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_interv IS

    -- Author  : JOAO.MARTINS
    -- Created : 20-10-2008 09:58:37
    -- Purpose : Application Programming Interface (API) for Procedures

    FUNCTION create_procedure_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_intervention_content    IN table_varchar, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_diagnosis               IN table_clob, --10
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_laterality              IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar, --15
        i_notes_prn               IN table_varchar,
        i_exec_institution        IN table_number,
        i_supply                  IN table_table_number,
        i_supply_set              IN table_table_number,
        i_supply_qty              IN table_table_number, --20
        i_dt_return               IN table_table_varchar,
        i_not_order_reason        IN table_number,
        i_notes                   IN table_varchar,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar, --25
        i_order_type              IN table_number,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_varchar, --30
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN VARCHAR2 DEFAULT 'I',
        o_interv_presc_array      OUT NOCOPY table_number,
        o_interv_presc_det_array  OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Procedure execution
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_episode             episode id
    * @param     i_interv_presc_det    Procedure's order detail id
    * @param     i_interv_presc_plan   Procedure's execution id
    * @param     i_prof_performed      Professional id
    * @param     i_start_time          Start time
    * @param     i_end_time            End time
    * @param     i_notes               Notes
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    *
    * @author    Teresa Coutinho
    * @version   2.6.3.8.2
    * @since     2013/10/01
    */

    FUNCTION set_procedure_execution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_interv_presc_det  IN interv_presc_plan.id_interv_presc_det%TYPE,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_prof_performed    IN interv_presc_plan.id_prof_performed%TYPE,
        i_start_time        IN VARCHAR2,
        i_end_time          IN VARCHAR2,
        i_notes             IN interv_presc_plan.notes%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_procedure_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN table_number,
        i_dt_cancel        IN VARCHAR2,
        i_cancel_reason    IN interv_presc_det.id_cancel_reason%TYPE,
        i_cancel_notes     IN interv_presc_det.notes_cancel%TYPE,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_procedure_request
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_presc_plan_task IN interv_presc_det.id_presc_plan_task%TYPE,
        i_dt_cancel       IN interv_presc_det.dt_cancel_tstz%TYPE DEFAULT current_timestamp,
        i_cancel_notes    IN interv_presc_det.notes_cancel%TYPE,
        i_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    TYPE t_rec_aux_interv_plan IS RECORD(
        dt_plan_show      VARCHAR2(100),
        dt_plan           VARCHAR2(100),
        dt_plan_edit      VARCHAR2(100),
        prof_resp         professional.name%TYPE,
        id_prof_resp      professional.id_professional%TYPE,
        INTERVAL          VARCHAR2(100),
        desc_intervention pk_translation.t_desc_translation,
        dt_order          VARCHAR2(100),
        dt_start_max      VARCHAR2(100));

    FUNCTION get_procedure_by_id_content
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_content      IN VARCHAR2,
        o_intervention OUT intervention.id_intervention%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_cq_by_id_content
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_content  IN VARCHAR2,
        i_flg_type IN VARCHAR2,
        o_id       OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    TYPE t_coll_aux_interv_plan IS TABLE OF t_rec_aux_interv_plan;
    TYPE t_cur_aux_interv_plan IS REF CURSOR RETURN t_rec_aux_interv_plan;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error VARCHAR2(4000);

END pk_api_interv;
/
