/*-- Last Change Revision: $Rev: 2016486 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-06-09 18:15:19 +0100 (qui, 09 jun 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_vital_sign IS

    -- Public type declarations
    SUBTYPE st_varchar2_200 IS VARCHAR2(200 CHAR);

    --Type used to return information about a vital sign entry (vital_sign_read)
    TYPE t_rec_api_vs_read IS RECORD(
        id_vital_sign_read      vital_sign_read.id_vital_sign_read%TYPE,
        id_episode              vital_sign_read.id_episode%TYPE,
        id_vital_sign           vital_sign_read.id_vital_sign%TYPE,
        dt_vital_sign_read_tstz vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        desc_vital_sign         pk_translation.t_desc_translation,
        desc_value              pk_translation.t_desc_translation,
        desc_unit_measure       pk_translation.t_desc_translation,
        id_prof_read            vital_sign_read.id_prof_read%TYPE,
        flg_state               vital_sign_read.flg_state%TYPE,
        id_prof_cancel          vital_sign_read.id_prof_cancel%TYPE,
        dt_cancel_tstz          vital_sign_read.dt_cancel_tstz%TYPE,
        flg_edit                vital_sign_read_hist.flg_value_changed%TYPE,
        id_prof_edit            vital_sign_read_hist.id_prof_read%TYPE,
        dt_edit                 vital_sign_read_hist.dt_registry%TYPE);
    --
    -- PUBLIC FUNCTIONS
    -- 

    /************************************************************************************************************
    * Return all notes from all vital signs of one episode (API for INTER_ALERT)
    *
    * @param i_vs_parent        ID for blood pressure relation for vital sign 
    * @param i_episode          episode id             
    * @param i_institution      institution id             
    * @param i_software         software id             
    *
    * @return                   description
    *
    * @author                   Rui Spratley
    * @version                  2.4.3
    * @since                    2008/05/23 
    ************************************************************************************************************/
    FUNCTION intf_get_vital_sign_val_bp
    (
        i_vs_parent   IN vital_sign_relation.id_vital_sign_parent%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN VARCHAR2;

    /************************************************************************************************************
    * This function writes a set of vital sign reads at once.
    * The arrays are read in the same order according to each line of I_VS_ID.
    *
    * @param i_lang                   Language ID
    * @param i_episode                Episode ID
    * @param i_prof                   Professional, Software and Institution id's
    * @param i_pat                    Patient id
    * @param i_vs_id                  Array of VS id's
    * @param i_vs_val                 Array of VS values
    * @param i_id_monit               Monitorization id
    * @param i_unit_meas              Unit Measures id's
    * @param i_vs_scales_elements     VS Scales Elements id's
    * @param i_notes                  Notes
    * @param i_prof_cat_type          Professional Category
    * @param o_vital_sign_read        Array of vital sign read IDs
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Paulo Fonseca
    * @version                        2.5.0
    * @since                          2010/01/18
    ************************************************************************************************************/
    FUNCTION intf_set_epis_vital_sign
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
        o_vital_sign_read    OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function cancel a VS read
    *
    * @param i_lang                   Language ID
    * @param i_episode                Episode ID
    * @param i_vs                     VS ID
    * @param i_prof                   Professional, Software and Institution id's
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Paulo Fonseca
    * @version                        2.5.0
    * @since                          2010/01/20
    ************************************************************************************************************/
    FUNCTION intf_cancel_epis_vs_read
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN vital_sign_read.id_episode%TYPE,
        i_vs            IN vital_sign_read.id_vital_sign_read%TYPE,
        i_prof          IN profissional,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE DEFAULT pk_cancel_reason.c_reason_other,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    ---------------------------------------------------------------------------------------------------------------

    /**********************************************************************************************
    * Get Vital Signs Records for a visit between a date interval
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_visit                  Visit id
    * @param        i_id_vs                  Vital sign ids to return
    * @param        i_dt_begin               Date from which start to return records
    * @param        i_dt_end                 Date by which to end returning records
    * @param        o_vs                     Vital signs records output cursor
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.4
    * @since        26-Nov-2010
    **********************************************************************************************/
    FUNCTION get_visit_vital_signs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_id_vs    IN table_number,
        i_dt_begin IN VARCHAR2 DEFAULT NULL,
        i_dt_end   IN VARCHAR2 DEFAULT NULL,
        i_dt_type  IN VARCHAR2 DEFAULT 'M',
        o_vs       OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set Vital Signs Records
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_episode                Episode id
    * @param        i_id_vs                  Vital signs ids
    * @param        i_value_vs               Vital signs values
    * @param        i_id_um                  Unit measure ids
    * @param        i_multichoice_vs         Multichoices ids
    * @param        i_scales_elem_vs         Scale elements ids
    * @param        i_dt_vs                  Vital signs monitorization dates
    * @param        o_id_vsr                 Vital signs records ids
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.4
    * @since        26-Nov-2010
    **********************************************************************************************/
    FUNCTION set_episode_vital_signs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN vital_sign_read.id_episode%TYPE,
        i_id_vs          IN table_number,
        i_value_vs       IN table_number,
        i_id_um          IN table_number,
        i_multichoice_vs IN table_number,
        i_scales_elem_vs IN table_number,
        i_dt_vs          IN table_varchar,
        o_id_vsr         OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel Vital Signs Records
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_vital_sign_read        Vital Sign records ids
    * @param        i_cancel_reason          Id cancel reason
    * @param        i_notes                  Cancel notes
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.4
    * @since        26-Nov-2010
    **********************************************************************************************/

    FUNCTION cancel_vital_signs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_vital_sign_read IN table_number,
        i_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE DEFAULT pk_cancel_reason.c_reason_other,
        i_notes           IN vital_sign_read.notes_cancel%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get info about vital sign record
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_vital_sign_read        Vital Sign record ID
    * @param   i_dt_registry            Timestamp to check if the value was edited after that date (Optional)
    * @param   o_rec_api_vs_read        Information about vital sign record
    * @param   o_error                  Error information
    *
    * @return  A formatted string representing the vital sign read  
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/11/2011
    */
    FUNCTION get_vital_sign_read
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_dt_registry     IN vital_sign_read.dt_registry%TYPE := NULL,
        o_rec_api_vs_read OUT t_rec_api_vs_read,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Get latest reading for a list vital sign identifiers and a patient      *
    * identifier                                                              *
    *                                                                         *
    * @param   i_lang                   Professional preferred language       *
    * @param   i_prof                   Professional identification and its   *
    *                                   context (institution and software)    *
    * @param   i_patient                Patient ID                            *
    * @param   i_episode                Episode ID                            *
    * @param   i_flg_view               Flg View Mode                         *
    * @param   i_dt_threshold           Threshold Date                        *
    * @param   i_tbl_vs                 Vital Sign list ID                    *
    * @param   o_vs_info                Information about vital sign records  *
    * @param   o_error                  Error information                     *
    *                                                                         *
    * @return  Boolean                                                        *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 2.6.1                                                          *
    * @since   21/3/2011                                                      *
    **************************************************************************/
    FUNCTION get_latest_vital_sign_read
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_episode                  IN episode.id_episode%TYPE,
        i_flg_view                 IN vs_soft_inst.flg_view%TYPE,
        i_dt_threshold             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_tbl_vs                   IN table_number,
        i_tbl_aux_vs               IN table_number DEFAULT NULL,
        i_flg_show_previous_values IN VARCHAR2 DEFAULT NULL,
        i_dt_begin                 IN VARCHAR2 DEFAULT NULL,
        i_dt_end                   IN VARCHAR2 DEFAULT NULL,
        i_hash_vital_sign          IN table_table_varchar,
        i_flg_show_relations       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_vs_info                  OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_clinical_dt
    (
        i_hash_vital_sign IN table_table_varchar,
        i_id_vital_sign   IN NUMBER
    ) RETURN VARCHAR2;
    /**************************************************************************
    * Get configuration for list vital sign identifiers                       *
    *                                                                         *
    * @param   i_lang                   Professional preferred language       *
    * @param   i_prof                   Professional identification and its   *
    *                                   context (institution and software)    *
    * @param   i_flg_view               Flg View Mode                         *
    * @param   i_dt_end                 Episode end date                      *
    * @param   i_tbl_vs                 Vital Sign list ID                    *
    * @param   o_vs_header              Information about vital sign structure*
    * @param   o_error                  Error information                     *
    *                                                                         *
    * @return  Boolean                                                        *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 2.6.1                                                          *
    * @since   21/3/2011                                                      *
    **************************************************************************/
    FUNCTION get_vs_header
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_view  IN vs_soft_inst.flg_view%TYPE,
        i_dt_end    IN st_varchar2_200,
        i_tbl_vs    IN table_number,
        o_vs_header OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Get information for a list vital sign reads identifiers and a patient   *
    * identifier                                                              *
    *                                                                         *
    * @param   i_lang                   Professional preferred language       *
    * @param   i_prof                   Professional identification and its   *
    *                                   context (institution and software)    *
    * @param   i_patient                Patient ID                            *
    * @param   i_episode                Episode ID                            *
    * @param   i_tbl_vsr                Vital Sign Read list ID               *
    * @param   o_vs_info                Information about vital sign records  *
    * @param   o_error                  Error information                     *
    *                                                                         *
    * @return  Boolean                                                        *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 2.6.1                                                          *
    * @since   21/3/2011                                                      *
    **************************************************************************/
    FUNCTION get_vital_sign_read_info
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_tbl_vsr IN table_varchar,
        o_vs_info OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if vital signs were edited/cancelled after a specific timestamp
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   i_vsr_list               List of saved vital sign measurement (id_vital_sign_read)
    * @param   i_dt_creation            Timestamp to check if measurements were edited after this date
    * @param   o_changed                Returns if some measurement in input list was edited/cancelled after input timestamp
    * @param   o_error                  Error information
    *
    * @value o_changed {*} 'Y' Has info edited. {*} 'N' Has no info changed
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   5/20/2011
    */
    FUNCTION check_vsr_changed
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_vsr_list         IN table_number,
        i_dt_creation      IN epis_documentation.dt_creation_tstz%TYPE,
        o_ref_info_changed OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get current state of vital signs and monitorization for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author   Anna Kurowska                 
    * @version  2.7.1                  
    * @since    07-Mar-2017                         
    **********************************************************************************************/
    FUNCTION get_vwr_vs_monit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Set/Update or Cancel a vital sign according to CCH standards 
    *             
    * @param    i_lang                Language ID
    * @param    i_prof                Logged professional structure
    * @param    i_id_episode          Episode ID
    * @param    i_id_vs               Array if ids of vital signs
    * @param    i_vs_val              Array of values for the vital signs
    * @param    i_id_unit_meas        Array of unit measures for the vital signs    
    * @param    i_vs_scales_elements  Array of scale elements (Multi-choice vital signs)
    * @param    i_notes               Array of notes for vital signs
    * @param    i_dt_vs               Date of vital signs
    * @param    i_flg_stat            Action to be performed (N-New / E-Edit / C-Cancel)
    * @param    i_cancel_reason       ID of cancel reason
    * @param    i_cancel_notes        Cancel notes                                   
    * @return BOOLEAN
    * 
    * @author   Diogo Oliveira                 
    * @version  2.7.1.5                  
    * @since    16-Oct-2017                         
    **********************************************************************************************/
    FUNCTION set_vital_sign_intf
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_vs                   IN table_number,
        i_vs_val                  IN table_number,
        i_id_unit_meas            IN table_number,
        i_vs_scales_elements      IN table_number,
        i_notes                   IN table_varchar,
        i_dt_vs                   IN table_varchar,
        i_vs_attributes           IN table_table_number,
        i_vs_attributes_free_text IN table_table_clob,
        i_flg_stat                IN VARCHAR2,
        i_cancel_reason           IN table_number,
        i_cancel_notes            IN table_varchar,
        o_vital_sign_read         OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

END pk_api_vital_sign;
/
