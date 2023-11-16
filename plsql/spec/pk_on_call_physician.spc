/*-- Last Change Revision: $Rev: 2028817 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:07 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_on_call_physician IS

    -- Author  : JOSE.BRITO
    -- Created : 25-02-2009 14:47:58
    -- Purpose : Manage on-call physician data

    -- Public function and procedure declarations

    /**********************************************************************************************
    * Returns the ID's of the professionals that are currently on-call.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param o_id_profs           Array with the ID's of the professionals that are on-call
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           2.5.0.7
    * @since             2009/10/27
    **********************************************************************************************/
    FUNCTION get_on_call_physician_id_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_id_profs OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the start and end dates of the current on-call period, as well as the 
    * length of the period (number of days).
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param o_default_period     Length of the period (number of days)
    * @param o_start_date         Start date of the period
    * @param o_end_date           End date of the period
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/04/02
    **********************************************************************************************/
    FUNCTION get_on_call_period_dates
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_default_period OUT sys_config.value%TYPE,
        o_start_date     OUT TIMESTAMP WITH TIME ZONE,
        o_end_date       OUT TIMESTAMP WITH TIME ZONE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of on-call physicians.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param o_period_title       Text with the start and end dates of the period
    * @param o_list               List of on-call physicians
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/02
    **********************************************************************************************/
    FUNCTION get_on_call_physician_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_period_title OUT VARCHAR2,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get on-call physician detail
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_on_call         On-call physician - Record ID
    * @param o_detail             Detailed information about the on-call physician
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/02
    **********************************************************************************************/
    FUNCTION get_on_call_physician_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_on_call IN on_call_physician.id_on_call_physician%TYPE,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel on-call physician records.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_on_call         Array of selected record ID's (on-call physician ID's)
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/02
    **********************************************************************************************/
    FUNCTION cancel_on_call_physician
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_on_call IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set on-call physician data. Used for multiple creation of on-call periods.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_prof            On-call physician - Professional ID
    * @param i_dt_start           Array of start dates of on-call shift
    * @param i_dt_end             Array of end dates of on-call shift
    * @param i_notes              Array of notes
    * @param o_flg_show           (Y) Show error message and stay on the current screen
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/30
    **********************************************************************************************/
    FUNCTION set_on_call_physician
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_prof  IN professional.id_professional%TYPE,
        i_dt_start IN table_varchar,
        i_dt_end   IN table_varchar,
        i_notes    IN table_varchar,
        o_flg_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set on-call physician data
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_on_call         On-call physician - Record ID
    * @param i_id_prof            On-call physician - Professional ID
    * @param i_dt_start           Start date of on-call shift
    * @param i_dt_end             End date of on-call shift
    * @param i_notes              Notes
    * @param i_flg_action         (N) New (E) Edit
    * @param i_commit             Commit transaction? (Y) Yes, default; (N) No
    * @param o_flg_show           (Y) Show error message and stay on the current screen
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/02/25
    **********************************************************************************************/
    FUNCTION set_on_call_physician
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_on_call IN on_call_physician.id_on_call_physician%TYPE,
        i_id_prof    IN professional.id_professional%TYPE,
        i_dt_start   IN VARCHAR2,
        i_dt_end     IN VARCHAR2,
        i_notes      IN VARCHAR2,
        i_flg_action IN VARCHAR2,
        i_commit     IN VARCHAR2 DEFAULT 'Y',
        o_flg_show   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of available specialities in the current institution.
    * NOTE: code based on PK_LIST.GET_SPEC_LIST.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param o_list               Speciality list
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/02
    **********************************************************************************************/
    FUNCTION get_speciality_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of professionals (physicians) for a given speciality.
    * Code optimized for Flash layer.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_spec               Speciality ID
    * @param o_list               List of professionals
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/02
    **********************************************************************************************/
    FUNCTION get_speciality_prof
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_spec  IN speciality.id_speciality%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the information related to a professional,
    * when creating a new on-call physician record.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_professional    Professional ID
    * @param o_prof_attr          Professional information
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/19
    **********************************************************************************************/
    FUNCTION get_professional_attributes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        o_prof_attr       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    -- Globals
    g_owner        VARCHAR2(200);
    g_package_name VARCHAR2(200);
    g_error        VARCHAR2(4000);

END pk_on_call_physician;
/
