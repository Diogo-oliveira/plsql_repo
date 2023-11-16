/*-- Last Change Revision: $Rev: 2028744 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:40 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_inp_episode_ux IS

    /*******************************************************************************************************************************************
    * CREATE_EPISODE                  Function that creates one new INPATIENT episode (episode and visit) and return new episode identifier.
    *                                 NOTE: - This function has transactional control (COMMIT)
    *                                       - This function should only be used when database should guarantee transaction commit
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with this new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with this new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with this new episode
    * @param I_ID_BED                 BED identifier that should be associated with this new episode
    * @param I_DT_BEGIN               Episode start date (begin date) that should be associated with this new episode
    * @param I_DT_DISCHARGE           Episode discharge date that should be associated with this new episode
    * @param I_ANAMNESIS              Anamnesis information that should be associated with this new episode
    * @param I_FLG_SURGERY            Information if new episode should be associated with an cirurgical episode
    * @param I_TYPE                   EPIS_TYPE identifier that should be associated with this new episode
    * @param I_DT_SURGERY             Surgery date that should be associated with ORIS episode associated with this new episode
    * @param I_ID_PREV_EPISODE        EPISODE identifier that represents the parent episode that should be associated with this new episode
    * @param O_ID_INP_EPISODE         INPATIENT episode identifier created for this new patient
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.6.0.3
    * @since                          05/Jul/2010
    *
    *******************************************************************************************************************************************/
    FUNCTION create_episode
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_patient       IN NUMBER,
        i_id_dep_clin_serv IN NUMBER,
        i_id_room          IN NUMBER,
        i_id_bed           IN NUMBER,
        i_dt_begin         IN VARCHAR2,
        i_dt_discharge     IN VARCHAR2,
        i_flg_hour_origin  IN VARCHAR2 DEFAULT pk_discharge.g_disch_flg_hour_dh,
        i_anamnesis        IN VARCHAR2,
        i_flg_surgery      IN VARCHAR2,
        i_type             IN NUMBER,
        i_dt_surgery       IN VARCHAR2,
        i_id_prev_episode  IN episode.id_prev_episode%TYPE,
        o_id_inp_episode   OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_EPIS_DIAGNOSIS              Function that returns diagnosis associated with one episode
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_PROF                Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             EPISODE identifier that should be searched
    * @param O_DIAGNOSIS              Diagnosis associated with episode identifier
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          N.A.
    *
    * @author                         Luís Maia
    * @version                        2.0
    * @since                          2009/05/11
    *
    *******************************************************************************************************************************************/
    FUNCTION get_epis_diagnosis
    (
        i_lang       IN NUMBER,
        i_id_prof    IN profissional,
        i_id_episode IN NUMBER,
        o_diagnosis  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the actions to be shown in the scheduled grid, according to the configuration 
    * that indicates if it is being used the ALERT SCHEDULER in the intitution.
    *
    * @param i_lang                ID language   
    * @param i_prof                Professional
    * @param o_actions             Output cursor
    * @param o_error                         Error object
    *
    * @return                      Y-registered episode; N-not registered episode
    *                        
    * @author                      Sofia Mendes
    * @version                     2.6.0.3
    * @since                       25-Aug-2010
    **********************************************************************************************/
    FUNCTION get_sch_grid_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the actions to be shown in the scheduled grid, according to the configuration 
    * that indicates if it is being used the ALERT SCHEDULER in the intitution.
    *
    * @param i_lang                ID language   
    * @param i_prof                Professional
    * @param i_prof_follow         'Y' if the PROF_FOLLOW subject actions will be returned
    * @param o_actions             Output cursor
    * @param o_error                         Error object
    *
    * @return                      Y-registered episode; N-not registered episode
    *                        
    * @author                      Sofia Mendes
    * @version                     2.6.0.3
    * @since                       25-Aug-2010
    **********************************************************************************************/
    FUNCTION get_sch_grid_actions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_follow IN VARCHAR2,
        o_actions     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    -- ********************************************************************************
    -- *********************************** GLOBALS ************************************
    -- ********************************************************************************   
    g_package_owner VARCHAR2(0050);
    g_package_name  VARCHAR2(0050);
    --

    g_ret   BOOLEAN;
    g_error VARCHAR2(4000);

    -- Private exceptions
    e_call_error EXCEPTION;

    --
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

END;
/
