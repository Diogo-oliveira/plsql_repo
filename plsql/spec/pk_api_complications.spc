/*-- Last Change Revision: $Rev: 2028465 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:58 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_complications IS

    -- Author  : JOSE.SILVA
    -- Created : 30-12-2009
    -- Purpose : API to get the tasks associated with complications

    TYPE api_comp_rec IS RECORD(
        id_task        NUMBER(24),
        desc_task      VARCHAR2(1000 CHAR),
        id_episode     episode.id_episode%TYPE,
        flg_type       comp_axe.id_sys_list%TYPE,
        flg_context    epis_comp_detail.id_sys_list%TYPE,
        dt_task        VARCHAR2(200),
        dt_task_send   VARCHAR2(200),
        id_prof_task   professional.id_professional%TYPE,
        name_prof_task professional.name%TYPE,
        id_prof_req    professional.id_professional%TYPE,
        name_prof_req  professional.name%TYPE);

    TYPE api_comp_cur IS REF CURSOR RETURN api_comp_rec;

    -- Public function and procedure declarations

    /********************************************************************************************
    * Gets the list of analysis for a given episode or patient (only the ones with results)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_visit                     Visit id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_analysis                  Analysis list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_analysis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_visit       IN visit.id_visit%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_analysis    OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of imaging exams for a given episode or patient (only the ones with results)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_visit                     Visit id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_exams                     Exams list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_img_exams
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_visit       IN visit.id_visit%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_exams       OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of exams for a given episode or patient (only the ones with results)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_visit                     Visit id
    * @param   i_flg_type                  exam type
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_exams                     Exams list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_exams
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_visit       IN visit.id_visit%TYPE,
        i_flg_type    IN exam.flg_type%TYPE DEFAULT NULL,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_exams       OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of diets for a given episode or patient
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_diet                      Diet list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_diets
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_diet        OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of medication for a given episode or patient (only the ones administered)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_visit                     Visit id
    * @param   i_episode                   Episode id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_medication
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_visit       IN visit.id_visit%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_med         OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of positiongs for a given episode or patient
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_positioning               Positioning list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_positioning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_positioning OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of procedures for a given episode or patient (only the ones finalized)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_visit                     Visit id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_procedures                Procedures list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_procedures
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_visit       IN visit.id_visit%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_procedures  OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of surgical procedures for a given episode or patient (only the ones finalized)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
    * @param   i_type                      'AT' - Associated task; 'TP' - Treatment performed
    * @param   o_procedures                Procedures list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   30-12-2009
    ********************************************************************************************/
    FUNCTION get_surgical_procedures
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_context     IN epis_comp_detail.id_context_new%TYPE DEFAULT NULL,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE DEFAULT NULL,
        i_type        IN VARCHAR2,
        o_procedures  OUT api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Includes a new type of task to the tasks list
    *
    * @param   i_lang       Professional preferred language
    * @param   i_prof       Professional identification and its context (institution and software)
    * @param   i_tasks      New tasks to include
    * @param   i_task       Type of task to include
    * @param   i_type_tasks Type of tasks that were already fetched
    * @param   i_id_task    Tasks that were already fetched (IDs)
    * @param   i_desc_task  Tasks that were already fetched (descriptions)
    * @param   i_id_epis    Tasks that were already fetched (episode ID in which the task occured)
    * @param   i_flg_type   Tasks that were already fetched (type of task)
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   04-01-2010
    ********************************************************************************************/
    FUNCTION merge_tasks
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_tasks          IN api_comp_cur,
        i_task           IN comp_axe.id_sys_list%TYPE,
        i_type_tasks     IN OUT table_varchar,
        i_id_task        IN OUT table_number,
        i_desc_task      IN OUT table_varchar,
        i_id_epis        IN OUT table_number,
        i_flg_type       IN OUT table_number,
        i_flg_context    IN OUT table_number,
        i_dt_task        IN OUT table_varchar,
        i_dt_task_send   IN OUT table_varchar,
        i_id_prof_task   IN OUT table_number,
        i_name_prof_task IN OUT table_varchar,
        i_id_prof_req    IN OUT table_number,
        i_name_prof_req  IN OUT table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Includes a new type of task to the tasks list
    *
    * @param   i_lang        Professional preferred language
    * @param   i_prof        Professional identification and its context (institution and software)
    * @param   i_id_task     Task ID
    * @param   i_flg_context Type of task
    * @param   i_flg_det     Type of detail description: N: task description, D: task date
    * @param   i_type        'AT' - Associated task; 'TP' - Treatment performed
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   07-01-2010
    ********************************************************************************************/
    FUNCTION get_task_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_task     IN epis_comp_detail.id_context_new%TYPE,
        i_flg_context IN epis_comp_detail.id_sys_list%TYPE,
        i_flg_det     IN VARCHAR2,
        i_type        IN VARCHAR2
    ) RETURN VARCHAR2;

END pk_api_complications;
/
