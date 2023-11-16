/*-- Last Change Revision: $Rev: 2028807 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:04 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_nch_pbl IS

    /********************************************************************************************
    * Returns the effective hours of care spent for an episode today
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_id_episode           Episode id
    *
    * @return                       number of minutes actually spent
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION get_nch_effective_for_today
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN nch_effective.id_episode%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns the average nch for a given context
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_flg_context          In what kind of context this hours were spent
    * @param o_average_nch          Average nch for a given context
    * @param o_days_average         Number of days used in calculating the average
    * @param o_error                Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION get_nch_average
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_context  IN VARCHAR2,
        o_average_nch  OUT NUMBER,
        o_days_average OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the effective nch (in minutes) for a given context and institution
    * To be used in SQL
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_flg_context          In what kind of context this hours were spent
    * @param i_id_context           Context id
    * @param i_id_episode           Episode id
    *
    * @return                       Effective nch in minutes
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/19
    ********************************************************************************************/
    FUNCTION get_nch_effective
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN VARCHAR2,
        i_id_context  IN NUMBER,
        i_id_episode  IN nch_effective.id_episode%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns the effective nch (in minutes) for a given context and institution
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_flg_context          In what kind of context this hours were spent
    * @param i_id_context           Context id
    * @param i_id_episode           Episode id
    * @param o_value                Effective nch in minutes
    * @param o_error                Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION get_nch_effective
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN VARCHAR2,
        i_id_context  IN NUMBER,
        i_id_episode  IN nch_effective.id_episode%TYPE,
        o_value       OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets the effective nch (in minutes) for a given context and institution
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_flg_context          In what kind of context this hours were spent
    * @param i_id_context           Context id
    * @param i_id_episode           Episode id
    * @param i_value                Effective nch in minutes
    * @param o_id_nch_effective     ID of inserted row
    * @param o_error                Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION set_nch_effective
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_context      IN VARCHAR2,
        i_id_context       IN NUMBER,
        i_id_episode       IN nch_effective.id_episode%TYPE,
        i_value            IN NUMBER,
        o_id_nch_effective OUT nch_effective.id_nch_effective%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the estimated nch (in minutes) for a given context and institution
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_flg_context          In what kind of context this hours were spent
    * @param i_id_context           Context id
    * @param o_value                Estimated nch in minutes
    * @param o_error                Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION get_nch_estimated
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN VARCHAR2,
        i_id_context  IN NUMBER,
        o_value       OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets the estimated nch (in minutes) for a given context and institution
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_flg_context           In what kind of context this will be used
    * @param i_id_context            Context id
    * @param i_value                 Estimated nch in minutes
    * @param o_id_nch_estimated_inst ID of inserted row
    * @param o_error                 Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION set_nch_estimated
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_flg_context           IN VARCHAR2,
        i_id_context            IN NUMBER,
        i_value                 IN NUMBER,
        o_id_nch_estimated_inst OUT nch_estimated_inst.id_nch_estimated_inst%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns information of the NCH of an episode to be displayed in the viewer. 
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_id_epis              Episode id
    * @param o_data                 Cursor containing the data to be returned to the UX.        
    * @param o_error                Error message
    *
    * @return                       True or false, according to if the execution completes successfully or not.
    *
    * @author                       RicardoNunoAlmeida 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION get_epis_nch_viewer
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_nch_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_sys_shortcut IN sys_shortcut.id_sys_shortcut%TYPE,
        o_nch          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_nch_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_sys_shortcut IN sys_shortcut.id_sys_shortcut%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the total nch value allocated to a patient, at a given date.
    *
    *
    * @param i_lang                          Language ID
    * @param i_prof                          ALERT Professional
    * @param i_epis                          ID of the episode to check the NCH.
    * @param i_date                          Reference date to check the episode's NCH value
    *
    * @return                                Number of NCH hours the episode is allocating, or NULL for error.
    *
    * @author                                RicardoNunoAlmeida
    * @version                               2.5.0.5
    * @since                                 2009/07/30
    **********************************************************************************************/
    FUNCTION get_nch_total
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns the average effective nch spent on a given episode
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_epis                 ID episode
    * @param i_flg_context          In what kind of context this hours were spent
    * @param o_average_nch          Average nch for a given context
    * @param o_days_average         Number of days used in calculating the average
    * @param o_error                Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       RicardoNunoAlmeida 
    * @since                        2010/03/19
    ********************************************************************************************/
    FUNCTION get_epis_nch_avg
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_flg_context  IN VARCHAR2,
        o_average_nch  OUT NUMBER,
        o_days_average OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a formated string with nch information for the provided episode
    *
    * @param i_lang                 Language ID
    * @param i_val                  Value the NCH (in minutes) to be formatted.
    *
    * @return                       True if success, false otherwise
    *
    * @author                       RicardoNunoAlmeida 
    * @version                      2.6.0.1 
    * @since                        2010/03/19
    ********************************************************************************************/
    FUNCTION get_format_nch_info
    (
        i_lang language.id_language%TYPE,
        i_val  nch_effective.value%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************************************************************
    * SET_EPIS_NCH             Function that update an EPISODE NCH information if that exists, otherwise create one new registry
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_EPIS_NCH               EPIS NCH identifier that should be updated or created in this function
    * @param  I_ID_EPISODE                Episode identifier
    * @param  I_ID_PATIENT                Patient identifier
    * @param  I_NCH_VALUE                 Number of NCH associated with current episode
    * @param  I_DT_BEGIN                  Date in which current NCH information starts taking efect
    * @param  I_DT_END                    Date in which current NCH information ends it's validation (if I_FLG_ALLOCATION_NCH = 'U')
    * @param  I_FLG_STATUS                FLG_STATUS for this registry
    * @param  I_FLG_TYPE                  FLG_TYPE for this registry
    * @param  I_DT_CREATION               Date in which current registry was created
    * @param  I_NCH_LEVEL                 NCH_LEVEL associated with current registry, if aplicable
    * @param  O_ID_EPIS_NCH               EPIS_NCH identifier witch was updated or created after execute this function
    * @param  O_ERROR                     If an error accurs, this parameter will have information about the error
    *
    * @value  I_FLG_STATUS                {*} 'A'- Active {*} 'O'- Outdated
    * @value  I_FLG_TYPE                  {*} 'T'- Temporary nch value {*} 'D'- Definitive nch value
    * 
    * @return                             Returns TRUE if success, otherwise returns FALSE
    * @raises                             PL/SQL generic erro "OTHERS"
    *
    * @author                             Luís Maia
    * @version                            2.5.0.5
    * @since                              26-Ago-2009
    *
    *******************************************************************************************************************************************/
    FUNCTION set_epis_nch
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_nch  IN epis_nch.id_epis_nch%TYPE,
        i_id_episode   IN epis_nch.id_episode%TYPE,
        i_id_patient   IN epis_nch.id_patient%TYPE,
        i_nch_value    IN epis_nch.nch_value%TYPE,
        i_dt_begin     IN epis_nch.dt_begin%TYPE,
        i_dt_end       IN epis_nch.dt_end%TYPE,
        i_flg_status   IN epis_nch.flg_status%TYPE,
        i_flg_type     IN epis_nch.flg_type%TYPE,
        i_dt_creation  IN epis_nch.dt_creation%TYPE,
        i_id_nch_level IN epis_nch.id_nch_level%TYPE,
        i_reason_notes IN epis_nch.reason_notes%TYPE,
        o_id_epis_nch  OUT epis_nch.id_epis_nch%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    * Returns the nch value to the day indicated
    *
    * @param i_lang                     Language ID
    * @param i_prof                     Professional's details
    * @param i_id_adm_indication        Admission indication identifier
    * @param i_nr_day                   Nr of the day in the 
    * @param o_nch_value                NCH value   
    * @param o_id_nch_level             NCH identifier   
    * @param o_error                    Error message
    *
    * @return                           TRUE if success, FALSE otherwise         
    * @author     Sofia Mendes
    * @version    2.5.0.5
    * @since      2009/07/30
    */
    FUNCTION get_nch_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_nr_day            IN NUMBER,
        o_nch_value         OUT nch_level.value%TYPE,
        o_id_nch_level      OUT nch_level.id_nch_level%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
    * GET_EPIS_NCH_LEVEL       For current episode and current moment, returns NCH_LEVEL identifier.
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_EPISODE     Episode identifier for getting NCH_LEVEL identifier
    * @param  O_NCH_VALUE      NCH value correspondent to current episode in current moment
    * @param  O_ID_NCH_LEVEL   NCH_LEVEL identifier correspondent to current episode in current moment
    * @param  O_ID_EPIS_NCH    EPIS_NCH identifier
    * @param  O_ERROR          If an error accurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author                  Luís Maia
    * @version                 2.5.0.6
    * @since                   2009/09/11
    *
    *******************************************************************************************************************************************/
    FUNCTION get_epis_nch_level
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        o_nch_value    OUT nch_level.value%TYPE,
        o_id_nch_level OUT nch_level.id_nch_level%TYPE,
        o_id_epis_nch  OUT epis_nch.id_epis_nch%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    * Returns the nch first and second value as well as the nch change.
    *
     * @param i_lang                     Language ID
    * @param i_prof                     Professional's details   
    * @param o_error                    Error message
    * @param o_nch_levels               Output cursor
    * @return                           TRUE if success, FALSE otherwise         
    * @author     Sofia Mendes
    * @version    2.5.0.5
    * @since      2009/07/30
    */
    FUNCTION get_nch_levels
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_nch_levels        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the nch value for the current nch level of an episode.
    *
    *
    * @param i_lang                          Language ID
    * @param i_prof                          ALERT Professional
    * @param i_epis                          ID of the episode to check the NCH.
    * @param i_bmng_allocation_bed           ID of the episode's bed allocation.
    * @param i_date                          Reference date to check the episode's NCH value
    *
    * @return                                Number of NCH hours the episode is allocating, or NULL for error.
    *
    * @author                                RicardoNunoAlmeida
    * @version                               2.5.0.7.5
    * @since                                 2009/07/30
    **********************************************************************************************/
    FUNCTION get_nch_level
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_nch_lvl IN nch_level.id_nch_level%TYPE,
        i_dt_ini  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_ref  IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN nch_level.id_nch_level%TYPE;

    /**********************************************************************************************
    * Returns the total nch value allocated to a patient, at a given date.
    *
    * Note:  currently the function only calculates the NCH for the current time.  The two final arguments are thus useless.
    *        The function is predicted to be complete in version 2.5.0.7.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          ALERT Professional
    * @param i_epis                          ID of the episode to check the NCH.
    * @param i_bmng_allocation_bed           ID of the episode's bed allocation.
    * @param i_date                          Reference date to check the episode's NCH value
    *
    * @return                                Number of NCH hours the episode is allocating, or NULL for error.
    *
    * @author                                Sofia 
    * @version                               2.5.0.7
    * @since                                 2009/11/05
    **********************************************************************************************/
    FUNCTION get_nch_total_past
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis                IN episode.id_episode%TYPE,
        i_bmng_allocation_bed IN bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        i_date                IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Returns the Nursing Care Hours reason notes
    *
    * @param i_lang                          Language ID
    * @param i_prof                          ALERT Professional
    * @param i_episode                       ID of the episode to check the NCH.
    * @param o_error                         Error message
    *
    * @return                                Reason notes
    *
    * @author                                Vanessa Barsottelli 
    * @version                               2.6.4.3
    * @since                                 30/05/2014
    **********************************************************************************************/
    FUNCTION get_nch_reason_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_reason_notes OUT epis_nch.reason_notes%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    -- Constants
    g_flg_context_intervention CONSTANT VARCHAR2(1) := 'I';
    g_flg_context_bed_mgmt     CONSTANT VARCHAR2(1) := 'B';
    g_flg_context_admission    CONSTANT VARCHAR2(1) := 'A';
    g_hour                     CONSTANT PLS_INTEGER := 60;
    g_undefined_nch            CONSTANT VARCHAR2(3 CHAR) := '---';

END pk_nch_pbl;
/
