/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_api_diet IS

    -- Author  : ELISABETE.BUGALHO
    -- Created : 20-08-2009 10:19:29
    -- Purpose : Api for Diets

    /**********************************************************************************************
    * Gets the list of active diets for kitchen(Used on Reports - kitchen)
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_department         ID department
    * @param i_id_dep_serv           ID of department service
    *
    * @param o_diet                  Cursor with all active diets 
    * @param o_diet_totals           Cursor with the totals of diets
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/20
    **********************************************************************************************/

    FUNCTION get_active_diet_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN dept.id_dept%TYPE,
        i_id_dep_serv   IN department.id_department%TYPE,
        o_diet          OUT pk_types.cursor_type,
        o_diet_totals   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the last active diet of a episode(Used on Reports - hand-off)
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_episode            ID episode
    *
    * @param o_diet                  Cursor with the last active diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/09/01
    **********************************************************************************************/
    FUNCTION get_last_active_diet
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_diet       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the active diets as string for handoff
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_episode            ID episode
    *
    * @param o_diet                  Cursor with the last active diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Anna Kurowska
    * @version                       2.7.1
    * @since                         2017/04/03
    **********************************************************************************************/
    FUNCTION get_active_diets_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_diets   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates or updates a Diet request
    * 
    * @param   i_lang                  language associated to the professional
    * @param   i_prof                  Professional id, software and institution
    * @param   i_episode               Episode ID
    * @param   i_id_epis_diet_req      Id_epis_diet_req (NULL for new records)
    * @param   i_id_diet_type          Diet type: 1 - Facility diet (Default Value) 
                                                  2 - Personalized diet
                                                  3 - Most frequent personalized diet
    * @param   i_desc_diet             Diet description, used for free text. (Free text records => Diet type 2)
    * @param   i_id_content            Array of ID_CONTENT
    * @param   i_quantity              Array of quantities
    * @param   i_id_unit               Array of quantity units
    * @param   i_notes_diet            Array of diet notes
    * @param   i_id_diet_schedule      Array of diet_schedule: [MANDATORY]
                                        1 - Breakfast
                                        2 - Lunch
                                        3 - Snack
                                        4 - Dinner
                                        5 - Supper
                                        6 - Light meal
                                        7 - Diet (To be used at least once on every diet)
    * @param   i_dt_hour                Array of execution dates/time of each diet
    * @param   i_dt_begin_str           Request start date 
    * @param   i_dt_end_str             Request end date
    * @param   i_notes                  Request notes        
    *
    * @RETURN  o_id_epis_diet_req
    * @RETURN  o_error              
    **********************************************************************************************/
    FUNCTION create_diet
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_epis_diet_req IN epis_diet_req.id_epis_diet_req%TYPE,
        i_id_diet_type     IN diet_type.id_diet_type%TYPE,
        i_desc_diet        IN epis_diet_req.desc_diet%TYPE,
        i_id_content       IN table_varchar,
        i_quantity         IN table_number,
        i_id_unit          IN table_number,
        i_notes_diet       IN table_varchar,
        i_id_diet_schedule IN table_number,
        i_dt_hour          IN table_varchar,
        i_dt_begin_str     IN VARCHAR2,
        i_dt_end_str       IN VARCHAR2,
        i_notes            IN epis_diet_req.notes%TYPE,
        o_id_epis_diet_req OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancels a Diet request
    * 
    * @param   i_lang                  language associated to the professional
    * @param   i_prof                  Professional id, software and institution
    * @param   i_id_epis_diet_req      Id_epis_diet_req
    * @param   i_cancel_reason         ID of cancelation reason
    * @param   i_cancel_notes          Cancelation notes       
    *
    * @RETURN  o_error              
    **********************************************************************************************/
    FUNCTION cancel_diet
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_diet_req IN epis_diet_req.id_epis_diet_req%TYPE,
        i_cancel_reason    IN epis_diet_req.id_cancel_reason%TYPE,
        i_cancel_notes     IN epis_diet_req.notes_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Suspend a diet 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional id, software and institution    
    * @param i_id_epis_diet_req      ID_diet_req to be suspended
    * @param i_suspension_reason     ID Reason for suspend
    * @param i_suspension_notes      Suspend Notes 
    * @param i_dt_initial            Initial date for suspend
    * @param i_dt_end                End date for suspend
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    **********************************************************************************************/
    FUNCTION suspend_diet
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diet_req  IN epis_diet_req.id_epis_diet_req%TYPE,
        i_suspension_reason IN epis_diet_req.id_cancel_reason%TYPE,
        i_suspension_notes  IN epis_diet_req.notes_cancel%TYPE,
        i_dt_initial_str    IN VARCHAR2,
        i_dt_end_str        IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Resume a diet 
    *
    * @param i_lang                  Language associated to the professional
    * @param i_prof                  Professional id, software and institution
    * @param i_id_epis_diet_req      ID_diet_req to be resumed
    * @param i_notes                 Resume Notes 
    * @param i_dt_initial            Initial date for resume
    * @param i_dt_end                End date for resume
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    **********************************************************************************************/
    FUNCTION resume_diet
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_diet_req IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes            IN epis_diet_req.notes_cancel%TYPE,
        i_dt_initial_str   IN VARCHAR2,
        i_dt_end_str       IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_error        VARCHAR2(4000);

    g_package_owner VARCHAR2(32);
    g_package_name  VARCHAR2(32);

END pk_api_diet;
/
