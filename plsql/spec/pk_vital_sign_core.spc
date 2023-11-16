/*-- Last Change Revision: $Rev: 2029042 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_vital_sign_core AS

    -- Author  : LUIS.MAIA
    -- Created : 24-11-2011 10:03:58
    -- Purpose : Package that should contain all core functions of Vital Sign functionality

    --
    -- PUBLIC CONSTANTS
    -- 
    g_error VARCHAR2(4000);

    -- unit measure id for <none>
    g_without_um CONSTANT vs_patient_ea.id_unit_measure%TYPE := 25;

    -- Global variables declaration
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_found        BOOLEAN;
    g_exception EXCEPTION;
    -- 
    -- Types
    --

    SUBTYPE st_varchar2_1 IS VARCHAR2(1 CHAR);

    SUBTYPE st_varchar2_1000 IS VARCHAR2(1000 CHAR);

    TYPE t_rec_vs_info IS RECORD(
        id_vital_sign        vs_soft_inst.id_vital_sign%TYPE,
        VALUE                st_varchar2_1000,
        desc_unit_measure    pk_translation.t_desc_translation,
        pain_descr           pk_translation.t_desc_translation,
        name_vs              pk_translation.t_desc_translation,
        short_name_vs        pk_translation.t_desc_translation,
        short_dt_read        st_varchar2_1000,
        prof_read            professional.name%TYPE,
        rank                 vs_soft_inst.rank%TYPE,
        id_vital_sign_read   vital_sign_read.id_vital_sign_read%TYPE,
        flg_view             vs_soft_inst.flg_view%TYPE,
        dt_vital_sign_read   vital_signs_ea.dt_vital_sign_read%TYPE,
        value_detail         st_varchar2_1000,
        id_vital_sign_detail vs_soft_inst.id_vital_sign%TYPE,
        flg_read_only        st_varchar2_1,
        id_unit_measure      unit_measure.id_unit_measure%TYPE,
        color_graph          vital_sign.color_graph%TYPE,
        val_min              vital_sign_unit_measure.val_min%TYPE,
        val_max              vital_sign_unit_measure.val_max%TYPE,
        id_vital_sign_scale  vital_sign_scales.id_vital_sign_scales%TYPE,
        id_vs_scales_element vital_sign_scales_element.id_vs_scales_element%TYPE);

    TYPE t_coll_vs_info IS TABLE OF t_rec_vs_info;

    TYPE t_rec_vs_grid IS RECORD(
        id_vital_sign           vital_sign_read.id_vital_sign%TYPE,
        dt_vital_sign_read      st_varchar2_1000,
        id_vital_sign_read      vital_sign_read.id_vital_sign_read%TYPE,
        value_desc              st_varchar2_1000,
        flg_vs_status           vital_sign_read.flg_state%TYPE,
        id_prof_read            vital_sign_read.id_prof_read%TYPE,
        id_unit_measure         unit_measure.id_unit_measure%TYPE,
        dt_registry             st_varchar2_1000,
        vital_sign_scale        vital_sign_scales.id_vital_sign_scales%TYPE,
        dt_vs_read_str          st_varchar2_1000,
        dt_registry_str         st_varchar2_1000,
        flg_has_hist            st_varchar2_1,
        desc_prof               st_varchar2_1000,
        vs_copy_paste           st_varchar2_1000,
        is_vital_sign_read_only st_varchar2_1,
        desc_unit_measure       st_varchar2_1000,
        desc_unit_measure_sel   st_varchar2_1000,
        l_rank                  vs_soft_inst.rank%TYPE,
        val_min                 vital_sign_unit_measure.val_min%TYPE,
        val_max                 vital_sign_unit_measure.val_max%TYPE,
        color_grafh             vs_soft_inst.color_grafh%TYPE,
        color_text              vs_soft_inst.color_text%TYPE,
        spec_prof               st_varchar2_1000,
        label_triage            st_varchar2_1000,
        dt_vs_read_tstz         vital_sign_read.dt_vital_sign_read_tstz%TYPE);

    TYPE t_coll_vs_grid IS TABLE OF t_rec_vs_grid;

    TYPE t_rec_vs_cda IS RECORD(
        id_content           vital_sign.id_content%TYPE,
        id_vital_sign        vital_sign_read.id_vital_sign%TYPE,
        id_vital_sign_read   vital_sign_read.id_vital_sign_read%TYPE,
        vital_sign_desc      pk_translation.t_desc_translation,
        vital_sign_value     st_varchar2_1000,
        vital_sign_unit_desc st_varchar2_1000,
        dt_value             vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        dt_formatted         st_varchar2_1000,
        dt_serialized        st_varchar2_1000,
        dt_timezone          timezone_region.timezone_region%TYPE,
        id_prof_read         vital_sign_read.id_prof_read%TYPE,
        id_institution_read  vital_sign_read.id_institution_read%TYPE,
        id_software_read     vital_sign_read.id_software_read%TYPE,
        notes                vital_sign_notes.notes%TYPE);

    TYPE t_coll_vs_cda IS TABLE OF t_rec_vs_cda;

    TYPE t_rec_vsum IS RECORD(
        id_vital_sign   vital_sign_unit_measure.id_vital_sign%TYPE,
        id_unit_measure vital_sign_unit_measure.id_unit_measure%TYPE,
        id_institution  vital_sign_unit_measure.id_institution%TYPE,
        id_software     vital_sign_unit_measure.id_software%TYPE,
        age_min         vital_sign_unit_measure.age_min%TYPE,
        age_max         vital_sign_unit_measure.age_max%TYPE,
        val_min         vital_sign_unit_measure.val_min%TYPE,
        val_max         vital_sign_unit_measure.val_max%TYPE,
        decimals        vital_sign_unit_measure.decimals%TYPE,
        format_num      vital_sign_unit_measure.format_num%TYPE);

    TYPE t_coll_vsum IS TABLE OF t_rec_vsum;

    --
    -- PUBLIC FUNCTIONS
    -- 

    /************************************************************************************************************
    * This function returns unit measure description from a vital sign
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_unit_measure              unit measure id
    * @param      i_vital_sign_scales         vital sign scale id
    * @param      i_without_um_no_desc        Is to remove unit measure description from output ('Y' - Yes, 'N' - No)
    * @param      i_short_desc                unit measure description should be short ('Y' - short, 'N' - complete)
    *
    * @return     Returns unit measure description
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/25
    *
    ***********************************************************************************************************/
    FUNCTION get_um_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_unit_measure       IN unit_measure.id_unit_measure%TYPE,
        i_vital_sign_scales  IN vital_sign_scales.id_vital_sign_scales%TYPE DEFAULT NULL,
        i_without_um_no_desc IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_short_desc         IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN pk_translation.t_desc_translation;

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
    * @param      i_patient                   Patient id
    * @param      i_visit                     Visit id
    * @param      o_vs_n_records              Number of collumns of registries
    * @param      o_n_vs                      Number of registries
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/24
    *
    * @dependencies    REPORTS
    ***********************************************************************************************************/
    FUNCTION get_vs_n_records
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_view     IN vs_soft_inst.flg_view%TYPE,
        i_patient      IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        i_visit        IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        o_vs_n_records OUT PLS_INTEGER,
        o_n_vs         OUT PLS_INTEGER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient
    *
    * @param      i_vital_sign                Vital sign id
    * @param      i_patient                   Patient id
    * @param      i_visit                     Visit id
    *
    * @return     Nunber of registries
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/24
    *
    ***********************************************************************************************************/
    FUNCTION get_vs_n_records
    (
        i_vital_sign IN vital_sign_read.id_vital_sign%TYPE,
        i_patient    IN vital_sign_read.id_patient%TYPE,
        i_visit      IN episode.id_visit%TYPE DEFAULT NULL
    ) RETURN PLS_INTEGER;

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
    * @param      i_patient                   Patient id
    * @param      i_visit                     Visit id
    * @param      o_vs_grid                   Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/24
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_vs_short_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_patient  IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        i_visit    IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        o_vs_grid  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
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
    * @param      i_all_details               If all details should be returned ('Y' - yes; 'N' - No)
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
    FUNCTION get_vs_grid
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_view    IN vs_soft_inst.flg_view%TYPE,
        i_all_details IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_scope       IN NUMBER DEFAULT NULL,
        i_scope_type  IN VARCHAR2 DEFAULT NULL,
        i_interval    IN VARCHAR2 DEFAULT NULL,
        i_dt_begin    IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        o_val_vs      OUT table_varchar,
        o_error       OUT t_error_out
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
    * @param      i_interval             Interval to filter
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
    FUNCTION get_vs_grid_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_view          IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen        IN VARCHAR2,
        i_scope             IN NUMBER DEFAULT NULL,
        i_scope_type        IN VARCHAR2 DEFAULT NULL,
        i_interval          IN VARCHAR2 DEFAULT NULL,
        i_dt_begin          IN VARCHAR2 DEFAULT NULL,
        i_dt_end            IN VARCHAR2 DEFAULT NULL,
        i_flg_use_soft_inst IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_time              OUT pk_types.cursor_type,
        o_sign_v            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
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
        i_lang       IN language.id_language%TYPE,
        i_episode    IN vital_sign_read.id_episode%TYPE,
        i_prof       IN profissional,
        i_flg_view   IN vs_soft_inst.flg_view%TYPE,
        i_start_date IN VARCHAR2 DEFAULT NULL,
        i_end_date   IN VARCHAR2 DEFAULT NULL,
        o_notes_vs   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns all cancelled vital sign reads in a visit
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_episode             Vital sign read ID
    * @param        o_vsr_history            History Info
    * @param        o_error                  Error
    *
    * @author                                Sergio Dias
    * @version                               2.6.1.0.1
    * @since                                 27-Apr-2011
    *
    * @dependencies                          REPORTS
    ************************************************************************************************************/
    FUNCTION get_visit_cancelled_vital_sign
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        o_vsr_cancelled OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns history for a vital sign
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_episode             Vital Sign read ID
    * @param        o_vsr_history            History information
    * @param        o_error                  List of changed columns 
    *
    * @author                                Sergio Dias
    * @version                               2.6.1.0.1
    * @since                                 27-Apr-2011
    *
    * @dependencies                          REPORTS
    ************************************************************************************************************/
    FUNCTION get_visit_vital_sign_read_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        o_vsr_history OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * check vital signs conflicts (used to check if predefined tasks can be requested or not) 
    * 
    * @param       i_lang              preferred language id for this professional 
    * @param       i_prof              professional id structure 
    * @param       i_vital_signs       array of vital signs ids
    * @param       o_flg_conflict      array of vital signs conflicts indicators 
    * @param       o_error             error message 
    *
    * @return      boolean             true on success, otherwise false     
    *
    * @author                          António Neto
    * @version                         2.6.2
    * @since                           14-Dez-2011
    *
    * @dependencies                    Order tools
    ********************************************************************************************/
    FUNCTION check_vital_signs_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_vital_signs  IN table_number,
        o_flg_conflict OUT table_table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE l_______________cancel_func__(i_lang IN language.id_language%TYPE);

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

    /*************************************************************************
    * Get list of vital signs reads                                          *
    * Based on pk_vital_sign.get_vital_signs.                                *
    *                                                                        *
    * @param i_lang                   Preferred language ID for this         *
    *                                 professional                           *
    * @param i_prof                   Object (professional ID,               *
    *                                 institution ID, software ID)           *
    * @param i_patient                View mode                              *
    * @param i_visit                  Institution id                         *
    * @param i_flg_view               Software id                            *
    *                                                                        *
    * @return                         Table with vital sign read records     *
    *                                                                        *
    * @author                         Gustavo Serrano                        *
    * @version                        2.6.1                                  *
    * @since                          18-Fev-2011                            *
    * @copied from                    pk_vital_sign  by Rui Teixeira         *
    *************************************************************************/
    FUNCTION tf_get_vital_signs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN vital_signs_ea.id_patient%TYPE,
        i_visit           IN vital_signs_ea.id_visit%TYPE,
        i_flg_view        IN vs_soft_inst.flg_view%TYPE,
        i_flg_show_detail IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_coll_vs_info
        PIPELINED;

    /******************************************************************************************** 
    * Functions which returns labels and configuration for vital signs viewer
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

    /**********************************************************************************************
    * Get all information about interval
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          I_INTERVAL          Interval to filter
    * @param          io_dt_begin         initial date
    * @param          io_dt_end           end date
    * @param          o_nr_records        Number of records - filled in if filter is by nr of records
    * @param          o_id_prof           Id profissional - filled in if filter is by prof
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Anna Kurowska
    * @version                            2.6.3
    * @since                              18-Feb-2013    
    ********************************************************************************************/
    FUNCTION get_interval_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_interval   IN VARCHAR2,
        io_dt_begin  IN OUT TIMESTAMP WITH LOCAL TIME ZONE,
        io_dt_end    IN OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_nr_records OUT PLS_INTEGER,
        o_id_prof    OUT professional.id_professional%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vs_grid_new
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_view          IN vs_soft_inst.flg_view%TYPE,
        i_all_details       IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_scope             IN NUMBER DEFAULT NULL,
        i_scope_type        IN VARCHAR2 DEFAULT NULL,
        i_interval          IN VARCHAR2 DEFAULT NULL,
        i_dt_begin          IN VARCHAR2 DEFAULT NULL,
        i_dt_end            IN VARCHAR2 DEFAULT NULL,
        i_flg_use_soft_inst IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_val_vs            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_vital_sign_grid
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_flg_view                 IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen               IN VARCHAR2,
        i_all_details              IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_scope                    IN NUMBER,
        i_scope_type               IN VARCHAR2,
        i_interval                 IN VARCHAR2 DEFAULT NULL,
        i_dt_begin                 IN VARCHAR2 DEFAULT NULL,
        i_dt_end                   IN VARCHAR2 DEFAULT NULL,
        i_flg_show_previous_values IN VARCHAR2 DEFAULT NULL,
        i_flg_use_soft_inst        IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_show_relations       IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_coll_vs_grid
        PIPELINED;

    /************************************************************************************************************
    * This function returns the table of vital signs record (scheme type)
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  View type
    * @param      i_flg_screen                Screen type
    * @param      i_all_details               View all detail Y/N  
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
    * @return     Table with records t_tbl_vs
    *
    * @author     Anna Kurowska
    * @version    2.7.1
    * @since      2017/03/16
    ***********************************************************************************************************/
    FUNCTION get_vital_sign_records
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_view           IN vs_soft_inst.flg_view%TYPE,
        i_all_details        IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2,
        i_interval           IN VARCHAR2 DEFAULT NULL,
        i_dt_begin           IN VARCHAR2 DEFAULT NULL,
        i_dt_end             IN VARCHAR2 DEFAULT NULL,
        i_flg_use_soft_inst  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_include_fetus  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_relations IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_vs;

    FUNCTION get_vs_grid_time
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_view          IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen        IN VARCHAR2,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        i_flg_use_soft_inst IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_time              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vsr_cancel
    (
        i_id_vital_sign           IN vital_sign_read.id_vital_sign%TYPE,
        i_dt_vital_sign_read_tstz IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_id_patient              IN patient.id_patient%TYPE
    ) RETURN vital_sign_read.id_vital_sign_read%TYPE;
    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    );
    FUNCTION get_has_notes
    (
        i_dt_vital_sign_read_tstz IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_id_patient              IN patient.id_patient%TYPE,
        i_vsr_ids                 IN table_number
    ) RETURN VARCHAR2;
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
    * @dependencies    UX
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
    * @param      i_id_parent       vs_attribute identifier
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
    FUNCTION get_vs_attributes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign.id_vital_sign%TYPE,
        i_id_parent     IN vs_attribute.id_parent%TYPE,
        o_cursor        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function inserts the vital sign attribute 
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign_read       vital_sign_read identifier
    * @param      i_tb_attribute             vs_attribute list identifiers 
    * @param      i_tb_free_text             table free text atributes
    * @param       o_error             error message 
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/11/15
    *
    * @dependencies     BD
    ***********************************************************************************************************/
    FUNCTION set_vs_read_attribute
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_tb_attribute       IN table_number,
        i_tb_free_text       IN table_clob,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function returns the vital sign value converted
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign_read       vital_sign_read identifier
    * @param      i_flg_detail                is detail screen Y/N
    * @param      i_flg_hist                is hist record Y/N
    *
    * @return     vital sign value
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/11/15
    *
    * @dependencies     BD
    ***********************************************************************************************************/
    FUNCTION get_vs_value_converted
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_flg_detail         IN VARCHAR2,
        i_flg_hist           IN VARCHAR2
    ) RETURN VARCHAR2;
    /************************************************************************************************************
    * This function returns the vital sign attribute rank
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign             vital_sign identifier
    * @param      i_id_vs_attribute           id_vs_attribute identifier
    * @param      i_id_market                 market identifier
    *
    * @return     vital sign attribute rank
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/11/18
    *
    * @dependencies     BD
    ***********************************************************************************************************/
    FUNCTION get_vsa_rank
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_read.id_vital_sign%TYPE,
        i_id_vs_attribute IN vs_attribute.id_vs_attribute%TYPE,
        i_id_market       IN market.id_market%TYPE
    ) RETURN vs_attribute_soft_inst.rank%TYPE;
    /************************************************************************************************************
    * This function returns the vital sign value 
    *      
    * @return     vital sign value
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/11/15
    *
    * @dependencies     BD
    ***********************************************************************************************************/

    FUNCTION get_vs_value
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_vital_sign       IN vital_sign.id_vital_sign%TYPE,
        i_id_vital_sign_desc  IN vital_sign_read.id_vital_sign_desc%TYPE,
        i_dt_vital_sign_read  IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_id_unit_measure_vsr IN unit_measure.id_unit_measure%TYPE,
        i_id_unit_measure_vsi IN unit_measure.id_unit_measure%TYPE,
        i_value               IN vital_sign_read.value%TYPE,
        i_decimal_symbol      IN sys_config.value%TYPE,
        i_relation_domain     IN vital_sign_relation.relation_domain%TYPE,
        i_dt_registry         IN vital_sign_read.dt_registry%TYPE DEFAULT NULL,
        i_short_desc          IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;
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
    * This function returns the vital sign detail for the edit screen
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
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
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read %TYPE,
        o_cursor             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*************************************************************************
    * List of vital signs for CDA                                            *
    * Based on pk_vital_sign_core.tf_vital_sign_grid                         *
    *                                                                        *
    * @param i_lang                   language ID                            *
    * @param i_prof                   professional ID                        *
    * @param i_flg_view               View mode                              *
    * @param i_all_details            View all detail Y/N                    *
    * @param i_scope                  ID for scope                           *
    * @param i_scope_type             Scope Type (E)pisode/(V)isit/(P)atient *
    * @param i_interval               Record filter: Null - All, L - Last    *
    * @param i_dt_begin               Begin date                             *
    * @param i_dt_end                 End date                               *
    *                                                                        *
    * @return                         Table with vital sign read records     *
    *                                                                        *
    * @author                         Vanessa Barsottelli                    *
    * @version                        2.6.3                                  *
    * @since                          12-Dez-2013                            *
    *************************************************************************/
    FUNCTION tf_vital_sign_cda
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_view    IN vs_soft_inst.flg_view%TYPE,
        i_all_details IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_scope       IN NUMBER,
        i_scope_type  IN VARCHAR2,
        i_interval    IN VARCHAR2 DEFAULT NULL,
        i_dt_begin    IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_coll_vs_cda
        PIPELINED;

    /*************************************************************************
    * List of vital signs unit measure                                       *
    *                                                                        *
    * @param i_lang                   language ID                            *
    * @param i_prof                   professional ID                        *
    * @param i_id_vital_sign  
    * @param i_id_unit_measure
    * @param i_id_institution 
    * @param i_id_software    
    * @param i_age            
    *                                                                        *
    * @return                         Table with vital sign unit measure     *
    *                                                                        *
    * @author                         Paulo teixeira                         *
    * @version                        2.6.3                                  *
    * @since                          2014 02 03                             *
    *************************************************************************/
    FUNCTION tf_vital_sign_unit_measure
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_unit_measure.id_vital_sign%TYPE,
        i_id_unit_measure IN vital_sign_unit_measure.id_unit_measure%TYPE,
        i_id_institution  IN vital_sign_unit_measure.id_institution%TYPE,
        i_id_software     IN vital_sign_unit_measure.id_software%TYPE,
        i_age             IN vital_sign_unit_measure.age_min%TYPE
    ) RETURN t_coll_vsum
        PIPELINED;

    FUNCTION get_vsum_val_min
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_unit_measure.id_vital_sign%TYPE,
        i_id_unit_measure IN vital_sign_unit_measure.id_unit_measure%TYPE,
        i_id_institution  IN vital_sign_unit_measure.id_institution%TYPE,
        i_id_software     IN vital_sign_unit_measure.id_software%TYPE,
        i_age             IN vital_sign_unit_measure.age_min%TYPE
    ) RETURN vital_sign_unit_measure.val_min%TYPE;

    FUNCTION get_vsum_val_max
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_unit_measure.id_vital_sign%TYPE,
        i_id_unit_measure IN vital_sign_unit_measure.id_unit_measure%TYPE,
        i_id_institution  IN vital_sign_unit_measure.id_institution%TYPE,
        i_id_software     IN vital_sign_unit_measure.id_software%TYPE,
        i_age             IN vital_sign_unit_measure.age_min%TYPE
    ) RETURN vital_sign_unit_measure.val_max%TYPE;

    FUNCTION get_vsum_format_num
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_unit_measure.id_vital_sign%TYPE,
        i_id_unit_measure IN vital_sign_unit_measure.id_unit_measure%TYPE,
        i_id_institution  IN vital_sign_unit_measure.id_institution%TYPE,
        i_id_software     IN vital_sign_unit_measure.id_software%TYPE,
        i_age             IN vital_sign_unit_measure.age_min%TYPE
    ) RETURN vital_sign_unit_measure.format_num%TYPE;

    FUNCTION get_vsum_decimals
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_unit_measure.id_vital_sign%TYPE,
        i_id_unit_measure IN vital_sign_unit_measure.id_unit_measure%TYPE,
        i_id_institution  IN vital_sign_unit_measure.id_institution%TYPE,
        i_id_software     IN vital_sign_unit_measure.id_software%TYPE,
        i_age             IN vital_sign_unit_measure.age_min%TYPE
    ) RETURN vital_sign_unit_measure.decimals%TYPE;
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
        i_screen             IN VARCHAR2,
        i_flg_view           IN vs_soft_inst.flg_view%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION count_scale_elements
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_id_vital_sign_scale IN vital_sign_scales.id_vital_sign_scales%TYPE,
        i_id_triage_type      IN triage_type.id_triage_type%TYPE,
        i_id_vital_sign       IN vital_sign.id_vital_sign%TYPE
    ) RETURN NUMBER;
    /**********************************************************************************************
    * get_viewer_vs_shortcut
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         id_sys_shortcut
    *                        
    * @author                         Paulo Teixeira
    * @version                        2.6.3
    * @since                          2014/03/11
    **********************************************************************************************/
    FUNCTION get_viewer_vs_shortcut
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN profile_templ_access.id_sys_shortcut%TYPE;
    /************************************************************************************************************
    * get_vs_most_recent_value
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign             vital_sign identifier
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_dt_begin               Begin date   
    * @param      i_dt_end                 end date                             
    * @param      o_info                      cursor out
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2014/09/30
    ***********************************************************************************************************/
    FUNCTION get_vs_most_recent_value
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign_read.id_vital_sign%TYPE,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_dt_begin      IN VARCHAR2 DEFAULT NULL,
        i_dt_end        IN VARCHAR2 DEFAULT NULL,
        o_info          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * get_pdms_module_vital_signs
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_patient                   patient identifier
    * @param      i_flg_view                  default view
    * @param      i_tb_vs                     vital sign identifier search table
    * @param      i_tb_view                   flag view search table  
    * @param      o_vs                        cursor out
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2014/11/20
    ***********************************************************************************************************/

    FUNCTION get_pdms_module_vital_signs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_tb_vs   IN table_number DEFAULT NULL,
        i_tb_view IN table_varchar DEFAULT NULL,
        o_vs      OUT pk_types.cursor_type,
        o_um      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * get_vs_value_dt_reg
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign_read        vital sign read identifier
    * @param      i_dt_vs_read                clinical date
    * @param      i_dt_registry               registered date
    *
    * @return     vital sign value
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2014/11/25
    ***********************************************************************************************************/
    FUNCTION get_vs_value_dt_reg
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_dt_vs_read         IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE,
        o_info               OUT pk_types.cursor_type,
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
    * @since                                 2019-03.14
    *
    ************************************************************************************************************/
    FUNCTION get_vs_dates_to_load
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_view          IN vs_soft_inst.flg_view%TYPE,
        i_scope             IN NUMBER DEFAULT NULL,
        i_scope_type        IN VARCHAR2 DEFAULT NULL,
        i_dt_filter         IN VARCHAR2 DEFAULT NULL,
        i_flg_use_soft_inst IN VARCHAR2 DEFAULT pk_alert_constant.g_yes, -- flg inficating if get_vital_sign_records uses vs_soft_inst to retrieve records
        o_has_prev          OUT VARCHAR2,
        o_dt_begin          OUT VARCHAR2,
        o_dt_end            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************/
    FUNCTION get_vs_childs(i_vs IN vital_sign.id_vital_sign%TYPE) RETURN table_number;
    /************************************************************************************************************/
    FUNCTION is_vss_available
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_vital_sign_scales IN vital_sign_scales.id_vital_sign_scales%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_dates_x_records
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER DEFAULT NULL,
        i_scope_type IN VARCHAR2 DEFAULT NULL,
        i_nr_records IN VARCHAR2 DEFAULT NULL,
        o_dt_begin   OUT VARCHAR2,
        o_dt_end     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vital_sign_desc
    (
        i_lang language.id_language%TYPE,
        VALUE  VARCHAR2
    ) RETURN VARCHAR2;

    g_flg_view_cda CONSTANT VARCHAR2(2 CHAR) := 'CD'; -- FLG for CDA view
    g_flg_view_v1  CONSTANT VARCHAR2(2 CHAR) := 'V1';
    g_flg_view_v2  CONSTANT VARCHAR2(2 CHAR) := 'V2';
    g_vs_grid_screen_name sys_button_prop.screen_name%TYPE := 'VitalSignsDetail.swf';
    g_flg_screen_graph CONSTANT VARCHAR2(2 CHAR) := 'G';
    g_flg_screen_d     CONSTANT VARCHAR2(2 CHAR) := 'D';

    FUNCTION get_vsa_has_freetext
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign_read.id_vital_sign%TYPE,
        i_id_vs_attribute IN vs_attribute.id_vs_attribute%TYPE,
        i_id_market       IN market.id_market%TYPE
    ) RETURN vs_attribute.flg_free_text%TYPE;

END pk_vital_sign_core;
/
