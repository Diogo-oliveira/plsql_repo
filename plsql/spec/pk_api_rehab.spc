/*-- Last Change Revision: $Rev: 2028494 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:08 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_rehab IS

    /**********************************************************************************************
    * This function can be used to edit a given treatment
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_patient             patient
    * %param i_workflow_type          W, S, other
    * %param i_from_state             current status
    * %param i_to_state               destination status
    * %param i_id_rehab_grid          
    * %param i_id_rehab_presc         prescription
    * %param i_id_epis_origin         origin episode
    * %param i_id_rehab_schedule      schedule
    * %param i_id_cancel_reason       cancel reason
    * %param i_cancel_notes           cancel notes
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2013-03-18
    **********************************************************************************************/
    FUNCTION set_rehab_workflow_change
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        --
        i_workflow_type  IN VARCHAR2,
        i_from_state     IN VARCHAR2,
        i_to_state       IN VARCHAR2,
        i_id_rehab_grid  IN NUMBER,
        i_id_rehab_presc IN rehab_sch_need.id_rehab_sch_need%TYPE,
        --create_visit
        i_id_epis_origin    IN episode.id_episode%TYPE,
        i_id_rehab_schedule IN rehab_schedule.id_rehab_schedule%TYPE,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        --
        i_id_cancel_reason IN rehab_schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN rehab_schedule.notes%TYPE DEFAULT NULL,
        --
        o_id_episode OUT episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

END pk_api_rehab;
/
