/*-- Last Change Revision: $Rev: 2028889 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:34 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_progress_cfg AS

    /**************************************************************************
    * set data blocks configurations for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_note_type        Note type ID
    * @param i_id_market              Market id of the original records that will be copied
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/16                                 
    **************************************************************************/

    FUNCTION set_inst_dblock
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN software.id_software%TYPE DEFAULT NULL,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_dblock_mkt.id_pn_note_type%TYPE DEFAULT NULL,
        i_id_market        IN market.id_market%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * set SOAP blocks configurations for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_note_type        Note type ID
    * @param i_id_market              Market id of the original records that will be copied
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/16                                 
    **************************************************************************/
    FUNCTION set_inst_sblock
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN software.id_software%TYPE DEFAULT NULL,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_dblock_mkt.id_pn_note_type%TYPE DEFAULT NULL,
        i_id_market        IN market.id_market%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * set blocks/buttons configurations for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_note_type        Note Type ID
    * @param i_id_market              Market id of the original records that will be copied
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/16                                 
    **************************************************************************/
    FUNCTION set_inst_button
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN software.id_software%TYPE DEFAULT NULL,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_dblock_mkt.id_pn_note_type%TYPE DEFAULT NULL,
        i_id_market        IN market.id_market%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * set profile_template access buttons for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_market              Market id of the original records that will be copied
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/16                                 
    **************************************************************************/
    FUNCTION set_inst_prof_soap_button
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE DEFAULT NULL,
        i_id_market            IN market.id_market%TYPE DEFAULT NULL,
        i_id_profile_templates IN table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * create progress notes (SOAP)  for a specific institution
    * This function will be create the SOAP block, data blocks, buttons,
    * profile access and free text blocks configurations
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_note_type        Note type ID
    * @param i_id_pn_area             Area ID
    * @param i_id_market              Market id of the original records that will be copied
    * @param i_flg_single_page        Y - for single pafe congigs, N- for ambulatory SOAP configs
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/16                                 
    **************************************************************************/
    FUNCTION create_inst_prog_notes
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE DEFAULT NULL,
        i_id_profile_templates IN table_number,
        i_id_department        IN department.id_department%TYPE,
        i_id_dep_clin_serv     IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type      IN pn_dblock_mkt.id_pn_note_type%TYPE DEFAULT NULL,
        i_id_pn_area           IN pn_area_mkt.id_pn_area%TYPE DEFAULT NULL,
        i_id_market            IN market.id_market%TYPE,
        i_flg_single_page      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Associate profile_template access for the buttons and free text for a specific institution
    *                                                  
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_market              Market id of the original records that will be copied
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/16                                 
    **************************************************************************/
    FUNCTION set_inst_prof_temp_association
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE DEFAULT NULL,
        i_id_market            IN market.id_market%TYPE DEFAULT NULL,
        i_id_profile_templates IN table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * set Note Types configurations for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_note_type        Note type ID
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         António Neto
    * @version                        2.6.1.2
    * @since                          12-Aug-2011
    **************************************************************************/
    FUNCTION set_inst_note_type
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE DEFAULT NULL,
        i_id_market            IN market.id_market%TYPE DEFAULT NULL,
        i_id_profile_templates IN table_number,
        i_id_department        IN department.id_department%TYPE,
        i_id_dep_clin_serv     IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type      IN pn_note_type_mkt.id_pn_note_type%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * set Area configurations for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_area             Area ID
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         António Neto
    * @version                        2.6.1.2
    * @since                          12-Aug-2011
    **************************************************************************/
    FUNCTION set_inst_area
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN software.id_software%TYPE DEFAULT NULL,
        i_id_market        IN market.id_market%TYPE DEFAULT NULL,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_area       IN pn_area_mkt.id_pn_area%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * set Note Types configurations for a specific institution to apply configurations for warning screens
    *                                                                         
    * @param   i_lang                          Language Identifier
    * @param   i_prof                          Profissional Identifier
    * @param   i_id_institution                Institution Identifier
    * @param   i_id_software                   Software Identifier
    * @param   i_id_department                 Department Identifier
    * @param   i_id_dep_clin_serv              Department Clinical Service Identifier
    * @param   i_id_pn_area                    Note Area Identifier
    * @param   i_id_pn_note_type               List of Note type Identifier
    * @param   i_flg_discharge_warning         In the discharge should appear an warning indicating the tasks that were not reviewed in the current visit
    * @param   i_flg_disch_warning_option      Indicate whether the options are checked with reMove or reView
    * @param   i_flg_autopop_warning           In the edition screen should appear the warning bar explaning which info is auto-populated
    * @param   i_flg_review_warning            In the review functionality should appear a warning indicating the data selected to be reviewd
    * @param   i_flg_review_warn_option        Indicate whether the options are checked with reMove or reView
    * @param   i_flg_import_warning            In the import functionality should appear a warning indicating the data to review
    *
    * @param   o_error                         Error message
    *
    * @value   i_flg_discharge_warning         {*} 'Y'- Yes {*} 'N'- No
    * @value   i_flg_disch_warning_option      {*} 'M'- Remove {*} 'V'- Review
    * @value   i_flg_autopop_warning           {*} 'Y'- Yes {*} 'N'- No
    * @value   i_flg_review_warning            {*} 'Y'- Yes {*} 'N'- No
    * @value   i_flg_review_warn_option        {*} 'M'- Remove {*} 'V'- Review
    * @value   i_flg_import_warning            {*} 'Y'- Yes {*} 'N'- No
    *
    * @author                         António Neto
    * @version                        2.6.2
    * @since                          01-Mar-2012
    **************************************************************************/
    FUNCTION set_inst_note_warnings
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_institution           IN institution.id_institution%TYPE,
        i_id_software              IN software.id_software%TYPE DEFAULT NULL,
        i_id_department            IN department.id_department%TYPE,
        i_id_dep_clin_serv         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_area               IN pn_note_type_mkt.id_pn_area%TYPE DEFAULT NULL,
        i_id_pn_note_type          IN table_number DEFAULT NULL,
        i_flg_discharge_warning    IN pn_note_type_soft_inst.flg_discharge_warning%TYPE DEFAULT NULL,
        i_flg_disch_warning_option IN pn_note_type_soft_inst.flg_disch_warning_option%TYPE DEFAULT NULL,
        i_flg_autopop_warning      IN pn_note_type_soft_inst.flg_autopop_warning%TYPE DEFAULT NULL,
        i_flg_review_warning       IN pn_note_type_soft_inst.flg_review_warning%TYPE DEFAULT NULL,
        i_flg_review_warn_option   IN pn_note_type_soft_inst.flg_review_warn_option%TYPE DEFAULT NULL,
        i_flg_import_warning       IN pn_note_type_soft_inst.flg_import_warning%TYPE DEFAULT NULL,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;
    
    /**************************************************************************
    * set Task Types configurations for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_note_type        Note type ID
    * @param i_id_market              Market id of the original records that will be copied
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          22-May-2012
    **************************************************************************/
    FUNCTION set_inst_task_types
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN software.id_software%TYPE DEFAULT NULL,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_note_type_mkt.id_pn_note_type%TYPE DEFAULT NULL,
        i_id_market        IN market.id_market%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_error VARCHAR2(4000);

    g_sysdate_tstz TIMESTAMP
        WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);

    g_limit NUMBER := 1000;

END pk_progress_cfg;
/
