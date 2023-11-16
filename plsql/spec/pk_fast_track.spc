/*-- Last Change Revision: $Rev: 2028695 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:23 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_fast_track IS

    /**********************************************************************************************
    * Checks the permission to disable the fast track
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution IDs
    * @param i_fast_track             fast track ID
    *
    * @return                         Permission to enable/disable the fast track: Y - yes, N - no
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/15
    **********************************************************************************************/
    FUNCTION get_fast_track_permission
    (
        i_prof_cat       IN category.flg_type%TYPE,
        i_flg_permission IN fast_track.flg_permission%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_fast_track_permission
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_fast_track IN fast_track.id_fast_track%TYPE
    ) RETURN VARCHAR2;
    /**********************************************************************************************
    * Checks the permission to disable the fast track
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution IDs
    * @param i_fast_track             fast track ID
    * @param i_flg_activate_disable   'A' - Activate action, 'D' - Disable action
    *
    * @return                         Permission to disable the fast track: Y - yes, N - no
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/15
    **********************************************************************************************/
    FUNCTION get_fast_track_permission
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_triage            IN triage.id_triage%TYPE,
        i_flg_activation_type  IN fast_track_institution.flg_activation_type%TYPE,
        i_eft_id_fast_track    IN epis_fast_track.id_fast_track%TYPE,
        i_eft_flg_status       IN epis_fast_track.flg_status%TYPE,
        i_flg_activate_disable IN VARCHAR2
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Sets the triggered fast track to given episode
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_id_triage              triage ID
    * @param i_id_epis_triage         episode triage id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION set_epis_fast_track
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_triage      IN triage.id_triage%TYPE,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Sets the triggered fast track to given episode
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_id_triage              triage ID
    * @param i_id_epis_triage         episode triage id
    * @param i_flg_epis_ft            Insert in epis_fast_track should be made: Y - yes; N - No
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2008/05/07
    **********************************************************************************************/
    FUNCTION set_epis_fast_track
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_triage      IN triage.id_triage%TYPE,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE,
        i_flg_epis_ft    IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Sets the epis info fast track to columns
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/09/15
    **********************************************************************************************/
    FUNCTION set_epis_info_fast_track
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the fast track icon to place in the patients grid.
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_fast_track             fast track ID   
    * @param i_type                   icon type: F - fast track; T - fast track + transfer institution  
    *
    * @return                         fast track icon
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2008/05/08
    **********************************************************************************************/
    FUNCTION get_fast_track_icon
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_fast_track IN fast_track.id_fast_track%TYPE,
        i_type       IN VARCHAR2
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the fast track icon to place in the patients grid; or, the ESI triage protocol icon.
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_fast_track             fast track ID   
    * @param i_triage_color           triage color ID
    * @param i_type                   icon type: F - fast track; T - fast track + transfer institution  
    *
    * @return                         Fast track icon or ESI protocol icon
    *                        
    * @author                         José Brito
    * @version                        2.6 
    * @since                          2010/01/12
    **********************************************************************************************/
    FUNCTION get_fast_track_icon
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis      IN episode.id_episode%TYPE,
        i_fast_track   IN fast_track.id_fast_track%TYPE,
        i_triage_color IN triage_color.id_triage_color%TYPE,
        i_type         IN VARCHAR2,
        i_has_transfer IN NUMBER
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the fast track title to place in the patients grid.
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                Episode ID   
    * @param i_fast_track             fast track ID   
    * @param i_type                   desc type: H - header; G - grid  
    *
    * @return                         fast track desc
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2008/05/15
    **********************************************************************************************/
    FUNCTION get_fast_track_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_fast_track IN fast_track.id_fast_track%TYPE,
        i_type       IN VARCHAR2
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the fast track title to place in the patients grid.
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_fast_track             fast track ID   
    * @param i_type                   desc type: H - header; G - grid  
    *
    * @return                         fast track desc
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2008/05/15
    **********************************************************************************************/
    FUNCTION get_fast_track_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_fast_track IN fast_track.id_fast_track%TYPE,
        i_type       IN VARCHAR2
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the fast track title to place in the patients grid.
    *   
    * @param i_lang                   language ID
    * @param i_epis_triage            episode triage id   
    * @param i_type                   desc type: H - header; G - grid  
    *
    * @return                         fast track desc
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/12
    **********************************************************************************************/
    FUNCTION get_fast_track_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_epis_triage IN epis_triage.id_epis_triage%TYPE,
        i_type        IN VARCHAR2
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the list of disable reasons
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient ID
    * @param i_id_fast_track          Fast track ID
    * @param o_fast_track_desc        Fast track description
    * @param o_disable_reason         List of disable reasons
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    /*  FUNCTION get_disable_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_id_fast_track   IN fast_track.id_fast_track%TYPE,
        o_fast_track_desc OUT VARCHAR2,
        o_disable_reason  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;*/

    /**********************************************************************************************
    * Gets the description of a disable reason
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_fast_track_disable     Fast track disable reason ID
    *
    * @return                         Disable reason
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/14
    **********************************************************************************************/
    FUNCTION get_disable_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_fast_track_disable IN fast_track_disable.id_fast_track_disable%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Disables the triggered fast track to given episode
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param i_id_epis_triage         Triage made to the episode (it assumes the last one if it is NULL)
    * @param i_fast_track_disable     Disable reason
    * @param i_notes                  Disable notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION set_fast_track_disable
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_triage       IN epis_triage.id_epis_triage%TYPE,
        i_tb_fast_track_reason IN table_number,
        i_notes                IN epis_fast_track.notes_disable%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the current episode fast track
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param o_id_fast_track          Fast track ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION get_epis_fast_track
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        o_id_fast_track OUT fast_track.id_fast_track%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_fast_track_int
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Gets the fast track for a given triage
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_triage              Triage ID
    * @param o_id_fast_track          Fast track ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Nuno Alves
    * @version                        2.5
    * @since                          2015/10/22
    **********************************************************************************************/
    FUNCTION get_triage_fast_track
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_triage     IN triage.id_triage%TYPE,
        o_id_fast_track OUT fast_track.id_fast_track%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the fast track for a given triage
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_triage              Triage ID
    *
    * @return                         id_fast_track          Fast track ID (NULL if none)
    *                        
    * @author                         Nuno Alves
    * @version                        2.5
    * @since                          2015/10/22
    **********************************************************************************************/
    FUNCTION get_triage_fast_track
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_triage IN triage.id_triage%TYPE
    ) RETURN fast_track.id_fast_track%TYPE;

    /**********************************************************************************************
    * Gets fast track configurations
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_triage              Triage ID
    * @param i_flg_activation_type    'M' - Manual activation, 'T' - automatically Triggered
    *
    * @return                         t_coll_fast_track_cfg
    *                        
    * @author                         Nuno Alves
    * @version                        2.5
    * @since                          2015/10/27
    **********************************************************************************************/
    FUNCTION tf_fast_track_cfg
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_triage           IN triage.id_triage%TYPE DEFAULT NULL,
        i_flg_activation_type IN fast_track_institution.flg_activation_type%TYPE DEFAULT 'M',
        i_id_fast_track       IN fast_track.id_fast_track%TYPE DEFAULT NULL
    ) RETURN t_tbl_fast_track_cfg;

    /********************************************************************************************
     * Get the manual fast track activation actions.
     * Based on get_actions function.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)  
     *
     * @return                         True or False on Success or Error
     *
     * @author                          Sofia Mendes
     * @version                         2.6.0.5
     * @since                           27-Jan-2g_fast_track_active011
    **********************************************************************************************/
    FUNCTION get_fast_track_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_epis_triage IN epis_fast_track.id_epis_triage%TYPE,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the fast track reason list
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_fast_track           vital_sign identifier
    * @param      i_flg_add_cancel      add or cancel reasons
    * @param       o_cursor             out cursor
    * @param       o_error             error message 
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.5
    * @since      2016/04/07
    *
    * @dependencies     UX
    ***********************************************************************************************************/
    FUNCTION get_fast_track_reason
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_fast_track  IN fast_track.id_fast_track%TYPE,
        i_flg_add_cancel IN fast_track_reason_si.flg_add_cancel%TYPE,
        o_cursor         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function creates a record in the table fast track reasons
    *
    * @param        i_lang                       Language id
    * @param        i_prof                       Professional, software and institution ids
    * @param        i_id_epis_triage             triage ID
    * @param        i_id_epis_fast_track_hist    epis_fast_track_hist ID
    * @param        i_flg_add_cancel             flg_add_cancel
    *
    * @param       o_error             error message 
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/11/15
    *
    * @dependencies     BD
    ***********************************************************************************************************/

    FUNCTION set_fast_track_reason
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_epis_triage       IN epis_fast_track.id_epis_triage%TYPE,
        i_tb_fast_track_reason IN table_number,
        i_flg_add_cancel       IN fast_track_reason_si.flg_add_cancel%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function creates a record in the history table for fast track reasons
    *
    * @param        i_lang                       Language id
    * @param        i_prof                       Professional, software and institution ids
    * @param        i_id_epis_triage             triage ID
    * @param        i_id_epis_fast_track_hist    epis_fast_track_hist ID
    * @param        i_flg_add_cancel             flg_add_cancel
    *
    * @author     Paulo Teixeira
    * @version    2.5
    * @since      2016/04/07
    ************************************************************************************************************/
    FUNCTION set_fast_track_reason_hist
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_epis_triage          IN epis_fast_track.id_epis_triage%TYPE,
        i_id_epis_fast_track_hist IN epis_ft_reason_hist.id_epis_fast_track_hist%TYPE,
        i_flg_add_cancel          IN fast_track_reason_si.flg_add_cancel%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Gets the description of a fast_track enable/disable reason
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis_fast_track_hist     fast_track hist record
    * @param i_flg_add_cancel         enable/disable reason A/C
    *
    * @return                         Disable reason
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/05/14
    **********************************************************************************************/
    FUNCTION get_fast_track_reasons
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_epis_fast_track_hist IN epis_fast_track_hist.id_epis_fast_track_hist%TYPE,
        i_flg_add_cancel          IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_fast_track_reason_rank
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_fast_track        IN fast_track.id_fast_track%TYPE,
        i_id_fast_track_reason IN fast_track_reason.id_fast_track_reason%TYPE,
        i_flg_add_cancel       IN fast_track_reason_si.flg_add_cancel%TYPE
    ) RETURN fast_track_reason_si.rank%TYPE;

    FUNCTION set_epis_fast_track_auto
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_triage      IN triage.id_triage%TYPE,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Sets a fast track manually to a given episode
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_id_triage              triage ID
    * @param i_id_epis_triage         episode triage id
    * @param i_id_fast_track          Fast track to be activated
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Nuno Alves
    * @version                        1.0 
    * @since                          2015/11/12
    **********************************************************************************************/
    FUNCTION set_epis_fast_track_manual
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_triage       IN epis_triage.id_epis_triage%TYPE,
        i_id_fast_track        IN fast_track.id_fast_track%TYPE,
        i_flg_type             IN epis_fast_track.flg_type%TYPE,
        i_tb_fast_track_reason IN table_number,
        i_notes                IN epis_fast_track.notes_enable%TYPE,
        i_ft_status            IN epis_fast_track.flg_status%TYPE DEFAULT 'A',
        i_ft_dt_activation     IN VARCHAR2 DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the fast track title to place in the patients grid.
    *   
    * @param i_lang                   language ID
    * @param i_episfast_track_hist    ep+is_fast_track hist   
    *
    * @return                         fast track desc
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0 
    * @since                          2016/05/30
    **********************************************************************************************/
    FUNCTION get_fast_track_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_fast_track_hist IN epis_fast_track_hist.id_epis_fast_track_hist%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Change status for fast track to given episode --  EMR-4797
    *   
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param i_id_epis_triage         Triage made to the episode (it assumes the last one if it is NULL)
    * @param i_fast_track             Reasons
    * @param i_notes                  Notes
    * @param i_flg_status             Target status (D - Disable, C - Confirm)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexander Camilo
    * @version                        1.0 
    * @since                          2018/06/15
    **********************************************************************************************/

    FUNCTION set_fast_track_status
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_triage       IN epis_triage.id_epis_triage%TYPE,
        i_tb_fast_track_reason IN table_number,
        i_notes                IN epis_fast_track.notes_disable%TYPE,
        i_flg_status           IN epis_fast_track.flg_status%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_fast_track_to_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN alert.profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_epis_triag OUT epis_triage.id_epis_triage%TYPE,
        o_fast_track OUT fast_track.id_fast_track%TYPE,
        o_ft_descr   OUT translation.desc_lang_1%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Get the limit dates for each fast track admission
    *   
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_episode                 Episode ID
    * @param o_limits                  Cursor with fast_track option and limit dates
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *                        
    * @author                          Alexander Camilo
    * @version                         2.7
    * @since                           30/05/2018
    **************************************************************************/
    FUNCTION get_epis_action_limit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_limits  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(4000);
    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_icon_ft          CONSTANT VARCHAR2(1) := 'F';
    g_icon_ft_transfer CONSTANT VARCHAR2(1) := 'T';

    g_desc_header CONSTANT VARCHAR2(1) := 'H';
    g_desc_grid   CONSTANT VARCHAR2(1) := 'G';

    g_icon_transfer CONSTANT VARCHAR2(50) := 'TransferInstitutionIcon';

    g_fast_track_active          CONSTANT epis_fast_track.flg_status%TYPE := 'A';
    g_fast_track_disabled        CONSTANT epis_fast_track.flg_status%TYPE := 'D';
    g_fast_track_action_disabled CONSTANT action.to_state%TYPE := 'C';
    g_fast_track_action_confirm  CONSTANT action.to_state%TYPE := 'D'; --  EMR-4797
    g_fast_track_reason_active   CONSTANT epis_fast_track_reason.flg_add_cancel%TYPE := 'A';
    g_fast_track_reason_cancel   CONSTANT epis_fast_track_reason.flg_add_cancel%TYPE := 'C';

    g_ft_triggered_activation CONSTANT fast_track_institution.flg_activation_type%TYPE := 'T';
    g_ft_manual_activation    CONSTANT fast_track_institution.flg_activation_type%TYPE := 'M';

    g_eft_flg_type_primary   CONSTANT epis_fast_track.flg_type%TYPE := 'P';
    g_eft_flg_type_secundary CONSTANT epis_fast_track.flg_type%TYPE := 'S';

    /* EMR-4797 */
    g_fast_track_confirm    CONSTANT epis_fast_track.flg_status%TYPE := 'C';
    g_cfg_fasttrack_disch   CONSTANT sys_config.id_sys_config%TYPE := 'FAST_TRACKS_REQ_BEFORE_DSC';
    g_cfg_fasttrack_confirm CONSTANT sys_config.id_sys_config%TYPE := 'FAST_TRACKS_CONFIRM_MKT';
    g_syscfg_ft_confirm     CONSTANT sys_config.id_sys_config%TYPE := 'FAST_TRACKS_CONFIRM_AVAILABLE';
    g_syscfg_ft_ext_limit   CONSTANT sys_config.id_sys_config%TYPE := 'FAST_TRACKS_EXTERNAL_LIMIT';

END pk_fast_track;
/
