/*-- Last Change Revision: $Rev: 2029045 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:28 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_vital_sign_ux AS

    --
    -- PUBLIC CONSTANTS
    -- 
    g_error VARCHAR2(4000);

    --
    -- PUBLIC FUNCTIONS
    --
    /************************************************************************************************************
    * This function returns the vital sign information registered for one episode VISIT
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_episode                   Episode id
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      o_val_vs                    Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/25
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_epis_vs_grid_all
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN vital_sign_read.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_val_vs   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function returns the vital sign information registered for one episode VISIT
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_interval                  Interval to filter
    * @param      i_dt_begin                  Date begin of the interval (Last X records, Last X my records)
    * @param      i_dt_end                    Date end of the interval (Last X records, Last X my records)   
    * @param      o_val_vs                    Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/25
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_epis_vs_grid_all
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_view   IN vs_soft_inst.flg_view%TYPE,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_interval   IN VARCHAR2,
        i_dt_begin   IN VARCHAR2 DEFAULT NULL,
        i_dt_end     IN VARCHAR2 DEFAULT NULL,
        o_val_vs     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient and number of moments of vital sign registration
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_flg_screen                Screen type
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_interval                  Interval to filter
    * @param      i_dt_begin                  Date begin of the interval (Last X records, Last X my records)
    * @param      i_dt_end                    Date end of the interval (Last X records, Last X my records)   
    * @param      o_time                      Returns time collumns
    * @param      o_sign_v                    Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/25
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_epis_vs_grid_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_view   IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen IN VARCHAR2,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_interval   IN VARCHAR2,
        i_dt_begin   IN VARCHAR2 DEFAULT NULL,
        i_dt_end     IN VARCHAR2 DEFAULT NULL,
        o_time       OUT pk_types.cursor_type,
        o_sign_v     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient and number of moments of vital sign registration
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_episode                   Episode id
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_flg_screen                Screen type
    * @param      o_time                      Returns time collumns
    * @param      o_sign_v                    Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/25
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_epis_vs_grid_list
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN vital_sign_read.id_episode%TYPE,
        i_prof       IN profissional,
        i_flg_view   IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen IN VARCHAR2,
        o_time       OUT pk_types.cursor_type,
        o_sign_v     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Obter todas as notas dos sinais vitais associadas ao episódio
    *
    * @param i_lang             Id do idioma
    * @param i_episode          episode id
    * @param i_prof             professional, software, institution ids
    * @param i_flg_view         Posição dos sinais vitais:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param o_notes_vs         Lista das notas dos sinais vitais do episódio
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE if sucess, FALSE otherwise
    *
    * @author                   Emilia Taborda
    * @version                  1.0
    * @since                    2006/08/25
    ********************************************************************************************/
    FUNCTION get_epis_vs_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN vital_sign_read.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_notes_vs OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * check vital signs conflicts (used to check if predefined tasks can be requested or not) 
    * 
    * @param       i_lang                  Preferred language id for this professional 
    * @param       i_prof                  Professional id structure 
    * @param       i_episode               Episode id  
    * @param       i_id_vital_sign_read    Vital sign read that should be cancelled
    * @param       i_id_cancel_reason      Cancel reason identifier 
    * @param       i_notes                 Cancel notes
    * @param       o_error                 Error message 
    *
    * @return      Boolean                 true on success, otherwise false    
    *
    * @author                              Luís Maia
    * @version                             2.6.1.7
    * @since                               04-Jan-2011
    ********************************************************************************************/
    FUNCTION cancel_epis_vs_read
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_id_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        i_notes              IN vital_sign_read.notes_cancel%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function is called when editing a vital sign
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * @param        id_vital_sign_read         Vital Sign reading ID
    * @param        i_value                    Vital sign value
    * @param        id_unit_measure            Measure unit ID
    * @param        dt_vital_sign_read_tstz    Vital sign read date
    *
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/
    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_value                   IN vital_sign_read.value%TYPE,
        i_id_unit_measure         IN vital_sign_read.id_unit_measure%TYPE,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_dt_registry             IN VARCHAR2 DEFAULT NULL,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_value                   IN vital_sign_read.value%TYPE,
        i_id_unit_measure         IN vital_sign_read.id_unit_measure%TYPE,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_dt_registry             IN VARCHAR2,
        i_id_unit_measure_sel     IN vital_sign_read.id_unit_measure_sel%TYPE,
        i_tb_attribute            IN table_number,
        i_tb_free_text            IN table_clob,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_value                   IN vital_sign_read.value%TYPE,
        i_id_unit_measure         IN vital_sign_read.id_unit_measure%TYPE,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_dt_registry             IN VARCHAR2,
        i_id_unit_measure_sel     IN vital_sign_read.id_unit_measure_sel%TYPE,
        i_tb_attribute            IN table_number,
        i_tb_free_text            IN table_clob,
        i_id_edit_reason          IN vital_sign_read.id_edit_reason%TYPE,
        i_notes_edit              IN CLOB,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function is called when editing a vital sign
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * @param        id_vital_sign_read         Vital Sign reading ID
    * @param        i_value                    Vital sign value
    * @param        id_unit_measure            Measure unit ID
    * @param        dt_vital_sign_read_tstz    Vital sign read date
    *
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/
    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN table_number,
        i_value                   IN table_number,
        i_id_unit_measure         IN table_number,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN table_number,
        i_value                   IN table_number,
        i_id_unit_measure         IN table_number,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_id_unit_measure_sel     IN table_number,
        i_tbtb_attribute          IN table_table_number,
        i_tbtb_free_text          IN table_table_clob,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN table_number,
        i_value                   IN table_number,
        i_id_unit_measure         IN table_number,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_id_unit_measure_sel     IN table_number,
        i_tbtb_attribute          IN table_table_number,
        i_tbtb_free_text          IN table_table_clob,
        i_id_edit_reason          IN vital_sign_read.id_edit_reason%TYPE,
        i_notes_edit              IN CLOB,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************************** 
    * Function which returns labels and configuration for vital signs viewer
    * 
    * @param       i_lang              preferred language id for this professional 
    * @param       i_prof              professional id structure 
    * @param       o_filters           cursor with filters desc
    * @param       o_title             Variable that indicates the title which should appear on viewer
    * @param       o_error             error message 
    *
    * @return      boolean             true on success, otherwise false     
    *
    * @author                          Anna Kurowska
    * @version                         2.6.3
    * @since                           13-Feb-2013
    ********************************************************************************************/
    FUNCTION get_viewer_vs_config
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_filters OUT pk_types.cursor_type,
        o_title   OUT sys_message.desc_message%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient and number of moments of vital sign registration
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_flg_screen                Screen type
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      o_time                      Returns time collumns
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/09/27
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_vs_grid_time
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_view   IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen IN VARCHAR2,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        o_time       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function returns the vital sign unit measure convertion list
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign       vital_sign identifier
    * @param      i_id_unit_measure     unit_measure identifier
    * @param       o_cursor             out cursor
    * @param       o_error             error message 
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/09/27
    *
    * @dependencies     UX
    ***********************************************************************************************************/
    FUNCTION get_vs_convert_um
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign.id_vital_sign%TYPE,
        i_id_unit_measure IN unit_measure.id_unit_measure%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        o_cursor          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function returns the vital sign attribute list
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign       vital_sign identifier
    * @param       o_cursor             out cursor
    * @param       o_error             error message 
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/09/27
    *
    * @dependencies     UX
    ***********************************************************************************************************/
    FUNCTION get_vs_attributes_names
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign.id_vital_sign%TYPE,
        o_cursor        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function returns the vital sign attribute list
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign       vital_sign identifier
    * @param      i_id_vs_attribute       vs_attribute identifier   
    * @param       o_cursor             out cursor
    * @param       o_error             error message 
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/09/27
    *
    * @dependencies     UX
    ***********************************************************************************************************/
    FUNCTION get_vs_attributes_values
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign.id_vital_sign%TYPE,
        i_id_vs_attribute IN vs_attribute.id_vs_attribute%TYPE,
        o_cursor          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function returns the vital sign detail for the edit screen
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign           vital_sign identifier
    * @param      i_id_vital_sign_read       vital_sign_read identifier
    * @param       o_cursor             out cursor
    * @param       o_error             error message 
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/09/27
    *
    * @dependencies     UX
    ***********************************************************************************************************/
    FUNCTION get_vs_read_attributes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign      IN vital_sign.id_vital_sign%TYPE,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read %TYPE,
        o_cursor             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * GET EDIT INFO
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign_read        vsr id
    * @param      o_info                      cursor out
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2013/02/07
    ***********************************************************************************************************/
    FUNCTION get_edit_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_flg_view           IN vs_soft_inst.flg_view%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * get_viewer_vs_shortcut
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_id_sys_shortcut        id_sys_shortcut out
    *
    * @return     True on sucess otherwise false
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.6.3
    * @since                          2014/03/11
    **********************************************************************************************/
    FUNCTION get_viewer_vs_shortcut
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        o_id_sys_shortcut OUT profile_templ_access.id_sys_shortcut%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_id_monit           IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_notes              IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_vs_read         IN table_varchar,
        i_epis_triage        IN epis_triage.id_epis_triage%TYPE,
        i_unit_meas_convert  IN table_number,
        o_vital_sign_read    OUT table_number,
        o_dt_registry        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_id_monit           IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_notes              IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_vs_read         IN table_varchar,
        i_epis_triage        IN epis_triage.id_epis_triage%TYPE,
        i_unit_meas_convert  IN table_number,
        i_tbtb_attribute     IN table_table_number,
        i_tbtb_free_text     IN table_table_clob,
        o_vital_sign_read    OUT table_number,
        o_dt_registry        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_id_monit           IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_notes              IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_vs_read         IN table_varchar,
        i_epis_triage        IN epis_triage.id_epis_triage%TYPE,
        i_unit_meas_convert  IN table_number,
        i_tbtb_attribute     IN table_table_number,
        i_tbtb_free_text     IN table_table_clob,
        i_id_edit_reason     IN table_number,
        i_notes_edit         IN table_clob,
        o_vital_sign_read    OUT table_number,
        o_dt_registry        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /** This function returns the dates to filter information in vs grid
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_dt_filter                 Date which we should treat as last date for records
    *
    * @param      o_has_prev                  flag indicating if exist any previously registered values
    * @param      o_dt_begin                  Date begin to be shown in grid
    * @param      o_dt_begin                  Date end to be shown in grid   
    * @param      o_error                     error out
    *
    * @author                                Anna Kurowska
    * @version                               2.7.5.2
    * @since                                 2019-03-14
    *
    ************************************************************************************************************/
    FUNCTION get_vs_dates_to_load
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_view   IN vs_soft_inst.flg_view%TYPE,
        i_scope      IN NUMBER DEFAULT NULL,
        i_scope_type IN VARCHAR2 DEFAULT NULL,
        i_dt_filter  IN VARCHAR2 DEFAULT NULL,
        o_has_prev   OUT VARCHAR2,
        o_dt_begin   OUT VARCHAR2,
        o_dt_end     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

END pk_vital_sign_ux;
/
