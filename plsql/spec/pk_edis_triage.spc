/*-- Last Change Revision: $Rev: 2028666 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_edis_triage AS

    TYPE rec_triage_conf IS RECORD(
        id_institution         triage_configuration.id_institution%TYPE,
        id_software            triage_configuration.id_software%TYPE,
        id_triage_type         triage_configuration.id_triage_type%TYPE,
        id_triage_ds_component triage_configuration.id_triage_ds_component%TYPE,
        ds_comp_int_name       ds_component.internal_name%TYPE,
        ds_comp_flg_comp       ds_component.flg_component_type%TYPE,
        flg_buttons            triage_configuration.flg_buttons%TYPE,
        flg_considerations     triage_configuration.flg_considerations%TYPE,
        num_epis_triage_audit  triage_configuration.num_epis_triage_audit%TYPE,
        id_reports             triage_configuration.id_reports%TYPE,
        flg_auto_print_tag     triage_configuration.flg_auto_print_tag%TYPE,
        flg_change_color       triage_configuration.flg_change_color%TYPE,
        flg_complaint          triage_configuration.flg_complaint%TYPE,
        flg_default_view       triage_configuration.flg_default_view%TYPE,
        flg_check_vital_sign   triage_configuration.flg_check_vital_sign%TYPE,
        flg_id_board           triage_configuration.flg_id_board%TYPE,
        flg_check_age_limits   triage_configuration.flg_check_age_limits%TYPE,
        flg_filter_flowchart   triage_configuration.flg_filter_flowchart%TYPE,
        flg_triage_res_grids   triage_configuration.flg_triage_res_grids%TYPE,
        flg_show_color_desc    triage_configuration.flg_show_color_desc%TYPE,
        flg_show_detail_viewer VARCHAR2(1 CHAR),
        detail_schema          CLOB);

    TYPE cursor_triage_conf IS REF CURSOR RETURN rec_triage_conf;

    TYPE rec_anamnesis IS RECORD(
        id_epis_anamnesis   epis_anamnesis.id_epis_anamnesis%TYPE,
        desc_epis_anamnesis pk_translation.t_desc_translation);

    TYPE cursor_anamnesis IS REF CURSOR RETURN rec_anamnesis;

    TYPE table_anamnesis IS TABLE OF rec_anamnesis;

    g_null_value CONSTANT PLS_INTEGER := -99;

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_anamnesis);

    --
    /**********************************************************************************************
    * Registar os sinais vitais da triagem
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          Professional category
    * @param i_id_epis                id do episódio clinico
    * @param i_dt_triage_begin        Triage begin date
    * @param i_vs_id                  Array de IDs de SVs lidos 
    * @param i_vs_val                 Array de leituras dos SVs de I_VS_ID ( (valor do sinal vital) 
    * @param i_unit_meas              ID's das unidades de medida dos sinais vitais a inserir
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/06/19 
    **********************************************************************************************/
    FUNCTION set_triage_vs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_id_epis           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_epis_triage       IN epis_triage.id_epis_triage%TYPE,
        i_dt_triage_begin   IN epis_triage.dt_begin_tstz%TYPE,
        i_vs_id             IN table_number,
        i_vs_val            IN table_number,
        i_unit_meas         IN table_number,
        i_scales_element_id IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**********************************************************************************************
    * Determines if the patient age is within the limits defined to the flowchart or
    * flowchart group, while taking into account the configurations defined by the institution.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_pat_age                Patient age
    * @param i_age_limit              Limit to check (minimum or maximum)
    * @param i_limit_type             (MIN) Check minimum; (MAX) Check maximum;
    * @param i_flg_check_age_limits   Value of TRIAGE_CONFIGURATION.FLG_CHECK_AGE_LIMITS
    * @param i_override_config        Value of TRIAGE_BOARD.FLG_OVERRIDE_CONFIG, if available
    *
    * @return                         Y - Value within the limits; N - Value not within the limits.
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          2010/02/11 
    **********************************************************************************************/
    FUNCTION check_age_limits
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_pat_age              IN NUMBER,
        i_age_limit            IN NUMBER,
        i_limit_type           IN VARCHAR2,
        i_flg_check_age_limits IN triage_configuration.flg_check_age_limits%TYPE,
        i_override_config      IN triage_board.flg_override_config%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Listar os grupos de fluxograma da triagem
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_patient                patient id
    * @param i_urgency_level          Display flowcharts that support this urgency level (when applicable)
    * @param o_triage_board_g         Cursor with all group triage board
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/13 
    **********************************************************************************************/
    FUNCTION get_triage_board_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_urgency_level  IN NUMBER,
        o_triage_board_g OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar as descrições e respectiva relação grupo / fluxograma da triagem.
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_patient                patient id
    * @param i_t_board_group          ID do grupo do fluxograma 
    * @param i_flg_view               Tipo de visão: V1- Visão 1 de manchester
                                                     V2- Visão 2 de manchester
    * @param i_urgency_level          Display flowcharts that support this urgency level (when applicable)
    * @param o_triage_board           Cursor with all triage board
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/13 
    **********************************************************************************************/
    FUNCTION get_triage_board_grouping
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_t_board_group IN triage_board_group.id_triage_board_group%TYPE,
        i_flg_view      IN VARCHAR2,
        i_urgency_level IN NUMBER,
        o_triage_board  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    FUNCTION get_triage_board_grouping
        (
            i_lang          IN language.id_language%TYPE,
            i_prof          IN profissional,
            i_episode       IN episode.id_episode%TYPE,
            i_patient       IN patient.id_patient%TYPE,
            i_t_board_group IN triage_board_group.id_triage_board_group%TYPE,
            i_flg_view      IN VARCHAR2,
            o_triage_board  OUT pk_types.cursor_type,
            o_error         OUT t_error_out
        ) RETURN BOOLEAN;
    */
    --
    /**********************************************************************************************
    * Listar os conteudos de: - Grupo do fluxograma da triagem - Fluxograma da triagem
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_t_board_group          ID do grupo do fluxograma
    * @param i_triage_board           ID do fluxograma    
    * @param i_discrimin              discriminator id
    * @param o_title_triage           Cursor with all title triage
    * @param o_help_triage            Cursor with all help triage   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/14
    **********************************************************************************************/
    FUNCTION get_help_triage
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_t_board_group IN triage_board_group.id_triage_board_group%TYPE,
        i_triage_board  IN triage_board.id_triage_board%TYPE,
        i_discrimin     IN triage_discriminator.id_triage_discriminator%TYPE,
        o_title_triage  OUT pk_types.cursor_type,
        o_help_triage   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**************************************************************************
    * Returns the set of discriminators for the current box, in a given board (flowchart).
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_patient                Patient ID
    * @param i_episode                Episode ID
    * @param i_tbl_triage             Triage table id's
    * @param i_triage_board           Triage board id
    * @param i_triage_color           Triage color id
    * @param i_triage_check_age       Is to check the patient age?
    * @param i_pat_gender             Patient gender
    * @param i_age                    Patient age
    * @param i_age_str                Patient age
    *
    * @return                         Triage discriminators table
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.3
    * @since                          07/10/2013
    **************************************************************************/
    FUNCTION tf_triage_discrim
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_tbl_triage       IN table_number DEFAULT table_number(),
        i_triage_board     IN triage_board.id_triage_board%TYPE DEFAULT NULL,
        i_triage_color     IN triage_color.id_triage_color%TYPE DEFAULT NULL,
        i_triage_check_age IN triage_configuration.flg_check_age_limits%TYPE DEFAULT NULL,
        i_pat_gender       IN patient.gender%TYPE DEFAULT NULL,
        i_age              IN NUMBER DEFAULT NULL,
        i_age_str          IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_triage_discrim;
    --
    /**************************************************************************
    * Returns the set of discriminators for the current box, in a given board (flowchart).
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_episode                Episode ID
    * @param i_patient                Patient ID
    * @param i_triage_board           Board (flowchart) ID
    * @param i_box                    Current box identifier
    * @param i_triage_type            Triage type ID
    * @param o_id_box                 Next box identifier
    * @param o_flg_last               Last box of the flowchart? (Y) Yes (N) No
    * @param o_vital_sign             Vital sign data
    * @param o_triage_discrim         Discriminator data
    * @param o_triage_disc_consent    When applicable has the multichoice consent values of each discriminator
    * @param o_error                  Error message
    *
    * @return                         TRUE / FALSE
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          23/11/2009
    **************************************************************************/
    FUNCTION get_triage_discrim
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_triage_board   IN triage_board.id_triage_board%TYPE,
        i_box            IN triage.box%TYPE,
        i_triage_type    IN triage_type.id_triage_type%TYPE,
        o_id_box         OUT triage.box%TYPE,
        o_flg_last       OUT VARCHAR2,
        o_vital_sign     OUT pk_types.cursor_type,
        o_triage_discrim OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar todos os episódios de triagem 
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis                episode id
    * @param o_epis_triage            array com os todos os episódios de triagem deste episodio   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/15
    **********************************************************************************************/
    FUNCTION get_epis_triage
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis     IN episode.id_episode%TYPE,
        o_epis_triage OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Returns the available reasons for non-triaged patients ("white" triage),
    * configured in the institution.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_episode                Episode ID
    * @param o_white_reason           Configured reasons for "white" triages 
    * @param o_error                  Error message
    *
    * @return                         TRUE/FALSE
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/15
    *
    * @alter                          José Brito
    * @version                        2.6
    * @since                          2009/12/17
    **********************************************************************************************/
    FUNCTION get_triage_white_reason
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_white_reason OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar todos os cuidados de enfermagem associadas ao Fluxograma/discriminador/cor   
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_triage_board           triage board id
    * @param i_discrim                discriminator id                   
    * @param i_triage_color           triage color id
    * @param o_n_consid               Listar todos os cuidados de enfermagem associadas ao Fluxograma/discriminador/cor 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/06
    **********************************************************************************************/
    FUNCTION get_triage_n_consid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_triage_board IN triage_board.id_triage_board%TYPE,
        i_discrim      IN triage_discriminator.id_triage_discriminator%TYPE,
        i_triage_color IN triage_color.id_triage_color%TYPE,
        i_flg_confirm  in varchar2 default null, 
        o_n_consid     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar os fluxogramas associados à queixa activa, do episódio.   
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_epis                   episode id
    * @param o_comp_t                 Listar os fluxogramas associados à queixa, activa, do episódio 
    * @param o_anamnesis              Anamnesis list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/06
    **********************************************************************************************/
    FUNCTION get_complaint_triage
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN episode.id_episode%TYPE,
        o_comp_t    OUT pk_types.cursor_type,
        o_anamnesis OUT cursor_anamnesis,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Calcular o valor total do TRTS (Conjunto de sinais vitais)   
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_triage_discrim         discriminator id
    * @param i_vs_id                  Array de IDs de SVs lidos
    * @param i_vs_val                 Array de leituras dos SVs de I_VS_ID ( (valor do sinal vital) 
    * @param i_flg_view               Posição dos sinais vitais:S- Resumo; 
                                                                H- Saída de turno; 
                                                                V1- Grelha completa; 
                                                                V2- Grelha reduzida;
                                                                V3 - Biometria 
                                                                T- Triagem;
    * @param o_trts                   Resultado do conjunto dos sinais vitais   
    * @param o_vs                     ID do sinal vital a ser calculado
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/01/25
    **********************************************************************************************/
    FUNCTION get_triage_trts
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_triage_discrim IN triage.id_triage_discriminator%TYPE,
        i_vs_id          IN table_number,
        i_vs_val         IN table_number,
        i_flg_view       IN vs_soft_inst.flg_view%TYPE,
        o_trts           OUT NUMBER,
        o_vs             OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolver as cores associadas ao tipo de triagem, bem como a cor do episódio em análise
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_color_triage        array with color triage and color episode
    
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    
    * @author                      Emília Taborda
    * @since                       2007/06/06
    **********************************************************************************************/
    FUNCTION get_epis_triage_color
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_epis_color OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * This function returns the id_movement of the movement made right after a triage
    *
    * @param i_lang                language id
    * @param i_epis_triage         triage id
    *
    * @return                      id_movement of the movement we wan't
    
    * @author                      João Eiras
    * @since                       2007/03/26
    **********************************************************************************************/
    FUNCTION get_epis_triage_dest_room(i_epis_triage IN epis_triage.id_epis_triage%TYPE) RETURN room.id_room%TYPE;

    /**
    *
    * Function to insert or delete triage alerts
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_id_episode          Episode ID
    * @param i_dt_req_det          Record date
    * @param i_alert_type          Alert type: D - doctor, N - nurse    
    * @param i_type                Operation type: A - add, R- remove        
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      José Silva
    * @since                       2008/05/22
    * @version                     1.0
    *
    */

    FUNCTION set_alert_triage
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_req_det IN sys_alert_event.dt_record%TYPE,
        i_alert_type IN VARCHAR2,
        i_type       IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *
    * Function to insert or delete triage alerts
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_id_episode          Episode ID
    * @param i_dt_req_det          Record date
    * @param i_alert_type          Alert type: D - doctor, N - nurse    
    * @param i_type                Operation type: A - add, R- remove        
    * @param i_is_transfer_inst    Calling method from transfer institution: (Y) Yes (N) No       
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      José Silva
    * @since                       2008/05/22
    * @version                     1.0
    *
    */

    FUNCTION set_alert_triage
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_dt_req_det       IN sys_alert_event.dt_record%TYPE,
        i_alert_type       IN VARCHAR2,
        i_type             IN VARCHAR2,
        i_is_transfer_inst IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return the correct labels for "Flowchart" and "Discriminator",
    * according to the triage protocol used in the institution.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_episode             Episode Id    
    * @param o_flowchart           Label for "Flowchart"    
    * @param o_discriminator       Label for "Discriminator"        
    * @param o_reason_for_visit    Label for "Reason for visit"
    * @param o_fchart_selection    Label for "Flowchart selection"
    * @param o_current_prof        Label for professional name
    * @param o_protocol            Label for the protocol title, when applicable
    * @param o_confirmation        Label for the confirmation of triage (e.g. "Confirming Emergency Severity Index triage")
    * @param o_other_discrim       Label for "Other answers" (usually "No" answers)
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      José Brito
    * @since                       2009/03/26
    * @version                     1.0
    *
    */
    FUNCTION get_triage_labels
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_triage_acronym   IN triage_type.acronym%TYPE,
        o_flowchart        OUT VARCHAR2,
        o_discriminator    OUT VARCHAR2,
        o_reason_for_visit OUT VARCHAR2,
        o_fchart_selection OUT VARCHAR2,
        o_protocol         OUT VARCHAR2,
        o_confirmation     OUT VARCHAR2,
        o_current_prof     OUT VARCHAR2,
        o_other_discrim    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the triage type and acronym for the given professional institution and episode department.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_episode             Episode Id    
    * @param o_triage_type         Triage type        
    * @param o_triage_acronym      Triage acronym
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Alexandre Santos
    * @since                       2009/08/19
    * @version                     1.0
    *
    */
    FUNCTION get_triage_type_int
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_department     IN department.id_department%TYPE DEFAULT NULL,
        o_triage_type    OUT triage_type.id_triage_type%TYPE,
        o_triage_acronym OUT triage_type.acronym%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return the institution default triage type
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param o_triage_type         Triage type        
    * @param o_triage_acronym      Triage acronym
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Alexandre Santos
    * @version                     1.0
    * @since                       21-08-2009
    **********************************************************************************************/
    FUNCTION get_default_triage_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_triage_type    OUT triage_type.id_triage_type%TYPE,
        o_triage_acronym OUT triage_type.acronym%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns all available triage types for the given institution
    *
    * @param i_institution         institution id
    *    
    * @return                      list of all institution triage types
    *
    * @author                      Alexandre Santos
    * @version                     1.0
    * @since                       21-08-2009
    **********************************************************************************************/
    FUNCTION tf_get_inst_triag_types(i_institution IN institution_group.id_institution%TYPE) RETURN table_number;

    /**
    * Returns the triage type for the given professional institution and department.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_department          Department Id    
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Alexandre Santos
    * @since                       2009/08/20
    * @version                     1.0
    *
    */
    FUNCTION get_triage_type_by_dep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE
    ) RETURN triage_type.id_triage_type%TYPE;

    /**
    * Returns the triage type for the given professional institution and episode department.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_episode             Episode Id    
    *
    * @return                      Triage type
    *
    * @author                      Alexandre Santos
    * @since                       2009/08/19
    * @version                     1.0
    *
    */
    FUNCTION get_triage_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN triage_type.id_triage_type%TYPE;

    /**
    * Returns the triage acronym for the given professional institution and episode department.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_episode             Episode Id    
    *
    * @return                      Triage acronym
    *
    * @author                      Alexandre Santos
    * @since                       2009/08/19
    * @version                     1.0
    *
    */
    FUNCTION get_triage_acronym
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN triage_type.acronym%TYPE;

    /**************************************************************************
    * Load the configurations for the triage in use.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_episode                Episode id
    * @param o_config                 Cursor with configurations
    * @param o_error                  Error message
    *
    * @return                         TRUE / FALSE
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          23/11/2009
    **************************************************************************/
    FUNCTION get_triage_configurations
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_show_additional_info IN BOOLEAN DEFAULT TRUE,
        o_config               OUT cursor_triage_conf,
        o_row_triage_config    OUT triage_configuration%ROWTYPE,
        o_section              OUT t_table_ds_sections,
        o_def_events           OUT t_table_ds_def_events,
        o_tbl_detail_schema    OUT t_table_ds_sections,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_triage_configurations
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_show_additional_info IN BOOLEAN DEFAULT TRUE,
        o_config               OUT cursor_triage_conf,
        o_section              OUT t_table_ds_sections,
        o_def_events           OUT t_table_ds_def_events,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Used to return the data about a "hidden" discriminator.
    * These discriminators can be accepted by answering the opposite of the acceptance option
    * in the last discriminator of the last box, in some flowcharts.
    * Only supported by some protocols, such as Manchester 2 NL.
    *   
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_triage_type          Triage type ID
    * @param i_id_triage_color         Triage color ID
    * @param i_id_triage_board         Triage board ID
    * @param o_disc                    Discriminator data
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *                        
    * @author                          José Brito
    * @version                         2.6
    * @since                           20/01/2010
    **************************************************************************/
    FUNCTION get_hidden_discriminator
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_triage_type  IN triage_type.id_triage_type%TYPE,
        i_id_triage_color IN triage_color.id_triage_color%TYPE,
        i_id_triage_board IN triage_board.id_triage_board%TYPE,
        o_disc            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Converts a serialized date string to the appropriate date format.
    *   
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_date_str                Date to convert
    * @param o_date                    Converted date
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *                        
    * @author                          José Brito
    * @version                         2.6
    * @since                           20/05/2010
    **************************************************************************/
    FUNCTION convert_triage_date
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_date_str IN VARCHAR2,
        o_date     OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Get the institution's triage type for auditing reports.
    *   
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param o_audit_type              Audit type ID
    * @param o_id_triage_type          Triage type ID
    * @param o_triage_acronym          Triage acronym 
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *                        
    * @author                          José Brito
    * @version                         2.6
    * @since                           07/12/2010
    **************************************************************************/
    FUNCTION get_instit_audit_triage_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_audit_type     OUT audit_type.id_audit_type%TYPE,
        o_id_triage_type OUT triage_type.id_triage_type%TYPE,
        o_triage_acronym OUT triage_type.acronym%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_section                   Section cursor
    * @param   o_def_events                Def events cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   15-12-2011
    */
    FUNCTION get_section_events_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_section    OUT pk_types.cursor_type,
        o_def_events OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_defining_criteria_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_triage IN epis_triage.id_epis_triage%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Returns the set of child discriminators for the discriminator.
    * This is used in the ESI triage protocol.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_disc                Parent discriminator ID
    * @param i_id_patient             Patient ID used to filter by age
    * @param o_discrim_child          Discriminator data
    * @param o_error                  Error message
    *
    * @return                         TRUE / FALSE
    *                        
    * @author                         Sergio Dias
    * @version                        2.6.2.1.6
    * @since                          21-8-2012
    **************************************************************************/
    FUNCTION get_triage_discrim_child
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_disc       IN triage_discriminator.id_triage_discriminator%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        o_discrim_child OUT pk_edis_types.cursor_discrim_child,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
    * @param   i_component_name            Component name
    * @param   i_component_type            Component type
    * @param   i_triage_board              Triage board id
    * @param   i_triage_discriminator      Triage discriminator id
    * @param   o_section                   Section cursor
    * @param   o_def_events                Default events cursor
    * @param   o_events                    Events cursor
    * @param   o_items_values              Item values for multichoices of single choice
    * @param   o_data_val                  Default data or previous saved data
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   15-12-2011
    */
    FUNCTION get_section_data
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_component_name       IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type       IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        i_triage_board         IN triage_board.id_triage_board%TYPE DEFAULT NULL,
        i_triage_discriminator IN triage_discriminator.id_triage_discriminator%TYPE DEFAULT NULL,
        o_section              OUT pk_types.cursor_type,
        o_def_events           OUT pk_types.cursor_type,
        o_events               OUT pk_types.cursor_type,
        o_items_values         OUT pk_types.cursor_type,
        o_data_val             OUT CLOB,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Set patient's complaint, registered during triage.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_epis                Episode ID
    * @param i_id_patient             Patient ID
    * @param i_desc_anamnesis         Complaint text
    * @param i_dt_end                 Triage end date
    * @param i_flg_complaint          Availability of the complaint screen
    * @param o_id_epis_anamnesis      Complaint record ID
    * @param o_error                  Error message
    *
    * @return                         -
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          07/12/2009
    **************************************************************************/
    PROCEDURE set_anamnesis_complaint
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis           IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_desc_anamnesis    IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_end            IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE,
        i_flg_complaint     IN sys_config.value%TYPE,
        o_id_epis_anamnesis OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error             OUT t_error_out
    );

    /**************************************************************************
    * Set data of GRID_TASK_* tables.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_epis                Episode ID
    * @param o_error                  Error message
    *
    * @return                         -
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          07/12/2009
    **************************************************************************/
    PROCEDURE set_grid_task
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    );

    /**************************************************************************
    * Set triage alerts.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_epis                Episode ID
    * @param i_epis_dt_begin          Episode begin date
    * @param o_error                  Error message
    *
    * @return                         -
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          07/12/2009
    **************************************************************************/
    PROCEDURE set_triage_alerts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis       IN episode.id_episode%TYPE,
        i_epis_dt_begin IN episode.dt_begin_tstz%TYPE,
        i_dt_triage_end IN epis_triage.dt_end_tstz%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    );

    /**************************************************************************
    * Returns the value for a given triage configuration.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_episode                Episode id
    * @param i_triage_type            Triage type ID
    * @param i_config                 Configuration name
    *
    * @return                         The value for the configuration; NULL on error.
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          04/12/2009
    **************************************************************************/
    FUNCTION get_triage_config_by_name
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_triage_type IN triage_type.id_triage_type%TYPE,
        i_config      IN VARCHAR2
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Returns a string with the vital signs to be assessed 
    * in the current discriminator.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_disc                   Discriminator ID
    * @param i_field                  Type of data to return in the list (ID_VITAL_SIGN; FLG_MANDATORY)
    *
    * @return                         String with the vital sign data
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          14/12/2009
    **************************************************************************/
    FUNCTION get_vs_list_by_field
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_disc  IN triage_discriminator.id_triage_discriminator%TYPE,
        i_field IN VARCHAR2
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Obtains the market ID of the current institution.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    *
    * @return                         Market ID
    *                        
    * @author                         José Brito
    * @version                        2.5.0.7.8
    * @since                          18/03/2010
    **************************************************************************/
    FUNCTION get_market
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER;

    /**************************************************************************
    * Returns a string with the full description for the current decision point,
    * for the ESI triage protocol.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_decision_point      Decision point ID
    * @param i_type                   (L) Long or (S) Short title
    *
    * @return                         String with description
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          23/12/2009
    **************************************************************************/
    FUNCTION get_esi_decision_point_title
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_decision_point IN triage_decision_point.id_triage_decision_point%TYPE,
        i_type              IN VARCHAR2
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Returns a label with the flowchart description, according to the
    * type of triage.
    *   
    * @param i_lang                       Language ID
    * @param i_prof                       Professional info
    * @param i_id_triage_board            Flowchart ID
    * @param i_id_triage_decision_point   Decision point ID, if applicable (ESI triage only)
    * @param i_id_triage_type             Triage type ID
    *
    * @return                         Label with the flowchart description
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          22/02/2010
    **************************************************************************/
    FUNCTION get_board_label
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_triage_board          IN triage_board.id_triage_board%TYPE,
        i_id_triage_decision_point IN triage_decision_point.id_triage_decision_point%TYPE,
        i_id_triage_type           IN triage_type.id_triage_type%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Returns the discriminator description, according to the
    * type of triage.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_triage_type         Triage type ID
    * @param i_acronym                Triage type acronym
    * @param i_id_disc                Discriminator ID
    * @param i_id_disc_parent         Discriminator parent ID
    * @param i_code_disc              Code for translation: discriminator
    * @param i_selected_option        Option selected by user to confirm discriminator (Yes/No)
    * @param i_id_epis_triage         Epis Triage ID
    * @param i_id_triage              Triage ID
    *
    * @return                         Label with the discriminator description
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          22/12/2009
    **************************************************************************/
    FUNCTION get_discriminator_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_triage_type  IN triage_type.id_triage_type%TYPE,
        i_acronym         IN triage_type.acronym%TYPE,
        i_id_disc         IN triage_discriminator.id_triage_discriminator%TYPE,
        i_id_disc_parent  IN triage_discriminator.id_parent%TYPE,
        i_code_disc       IN triage_discriminator.code_triage_discriminator%TYPE,
        i_selected_option IN epis_triage.flg_selected_option%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Returns a label with the discriminator description, according to the
    * type of triage.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_triage_type         Triage type ID
    * @param i_acronym                Triage type acronym
    * @param i_id_disc                Discriminator ID
    * @param i_id_disc_parent         Discriminator parent ID
    * @param i_code_disc              Code for translation: discriminator
    * @param i_selected_option        Option selected by user to confirm discriminator (Yes/No)
    * @param i_id_epis_triage         Epis Triage ID
    * @param i_id_triage              Triage ID
    *
    * @return                         Label with the discriminator description
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          22/12/2009
    **************************************************************************/
    FUNCTION get_discriminator_label
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_triage_type  IN triage_type.id_triage_type%TYPE,
        i_acronym         IN triage_type.acronym%TYPE,
        i_id_disc         IN triage_discriminator.id_triage_discriminator%TYPE,
        i_id_disc_parent  IN triage_discriminator.id_parent%TYPE,
        i_code_disc       IN triage_discriminator.code_triage_discriminator%TYPE,
        i_selected_option IN epis_triage.flg_selected_option%TYPE,
        i_id_epis_triage  IN epis_triage.id_epis_triage%TYPE,
        i_id_triage       IN triage.id_triage%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Returns the ESI level if patient was triaged with ESI protocol.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_epis                   Episode ID
    * @param i_triage_color           Triage color ID
    *
    * @return                         ESI level number
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          12/01/2010
    **************************************************************************/
    FUNCTION get_epis_esi_level
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_triage_color IN triage_color.id_triage_color%TYPE,
        i_type         IN VARCHAR2 DEFAULT 'S'
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Get the triage color information to display in the detail
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_type                   Info type: T - title, V - value
    * @param i_triage_type            Triage type ID
    * @param i_triage_color           Triage color ID
    * @param i_format                 L - long (default), S - short (just "Degré 1")
    *
    * @return                         Triage color description
    *                        
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          04/11/2010
    **************************************************************************/
    FUNCTION get_triage_color_orig
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_type         IN VARCHAR2,
        i_triage_type  IN triage_type.id_triage_type%TYPE,
        i_triage_color IN triage_color.id_triage_color%TYPE,
        i_format       IN VARCHAR2 DEFAULT 'L'
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Returns the identifier for the "no triage" color, according to the
    * type of triage.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_triage_type         Triage type ID
    *
    * @return                         Color ID
    *                        
    * @author                         Pedro Fernandes
    * @version                        2.6
    * @since                          05/09/2016
    **************************************************************************/
    FUNCTION get_flag_no_color
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_no_color_id IN triage_color.id_triage_color%TYPE
    ) RETURN VARCHAR;

    /**************************************************************************
    * Returns the identifier for the "no triage" color, according to the
    * type of triage.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_triage_type         Triage type ID
    *
    * @return                         Color ID
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          23/12/2009
    **************************************************************************/
    FUNCTION get_id_no_color
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_triage_type IN triage_type.id_triage_type%TYPE
    ) RETURN NUMBER;

    /**************************************************************************
    * Parse XML parameter to database pl/sql record types
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_params                 XML with all input parameters
    * @param o_rec_triage             Triage record with all input parameters
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.3
    * @since                          03/12/2012
    **************************************************************************/
    FUNCTION parse_triage_parameters
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_params     IN CLOB,
        o_rec_triage OUT pk_edis_types.rec_triage,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get vital signs by triage type and context
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional info
    * @param i_id_episode          Context PK's, it can be the id_triage_board, id_triage_discriminator or NULL
    * @param i_id_context          Context PK's, it can be the id_triage_board, id_triage_discriminator or NULL
    * @param i_flg_context         Context flag
    * @param i_id_triage_type      Triage type id
    * @param i_pat_gender          Patient gender
    *    
    * @values i_flg_context        B - Triage Board
    *                              D - Triage Discriminator
    *                              F - Triage Form
    *    
    * @return                      Vital signs id's
    *
    * @author                      Alexandre Santos
    * @version                     2.6.3
    * @since                       07-12-2012
    **********************************************************************************************/
    FUNCTION tf_triage_vital_signs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_tbl_id_context IN table_number,
        i_flg_context    IN triage_vs_area.flg_context%TYPE,
        i_id_triage_type IN triage_type.id_triage_type%TYPE DEFAULT NULL,
        i_pat_gender     IN patient.gender%TYPE DEFAULT NULL
    ) RETURN table_number;

    /**************************************************************************
    * Detailed information about a triage event.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_epis_triage         Triage event ID
    * @param o_epis_triage            Triage Info
    * @param o_error                  Error message
    *
    * @return                         TRUE / FALSE
    *                        
    * @author                         Sergio Dias
    * @version                        2.6.3.1
    * @since                          10-12-2012
    **************************************************************************/
    FUNCTION get_epis_triage_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE,
        i_flg_call       IN VARCHAR2 DEFAULT pk_edis_hist.g_call_detail,
        o_epis_triage    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the presentation structure to be shown in the detail screen 
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   i_epis_triage               Epis triage id
    * @param   i_triage_type               Triage type id
    * @param   i_ds_component              Dynamic screen root component in use by this triage type
    * @param   i_ds_comp_type              Dynamic screen root component type in use by this triage type
    * @param   i_ds_tbl_nodes              Dynamic screen nodes table
    *
    * @return  Presentation schema for the detail screen
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   26-12-2011
    */
    FUNCTION tf_detail_schema
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_epis_triage          IN epis_triage.id_epis_triage%TYPE DEFAULT NULL,
        i_triage_type          IN triage_type.id_triage_type%TYPE DEFAULT NULL,
        i_ds_component         IN ds_component.internal_name%TYPE DEFAULT NULL,
        i_ds_comp_type         IN ds_component.flg_component_type%TYPE DEFAULT NULL,
        i_ds_tbl_nodes         IN t_table_ds_sections DEFAULT NULL,
        i_show_additional_info IN BOOLEAN DEFAULT TRUE,
        i_flg_call             IN VARCHAR2 DEFAULT pk_edis_hist.g_call_detail
    ) RETURN t_table_ds_sections;

    /**
    * Returns the id_context based on the area to be validated
    *
    * @param   i_flg_type                  F - Form; B - Triage board; D - Triage discriminator
    * @param   i_triage_board              Triage board pk
    * @param   i_triage_discriminator      Triage discriminator pk
    * @param   i_null_value                Value used when flg_type = F
    *
    * @return  If the area is F returns the i_null_value, if it's B returns the id_triage_board, 
    *          if it's D returns the id_triage_discriminator otherwise returns NULL
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   28-12-2011
    */
    FUNCTION get_vs_area_id_cxt
    (
        i_flg_type             IN triage_vs_area.flg_context%TYPE,
        i_triage_board         IN triage_vs_area.id_context%TYPE,
        i_triage_discriminator IN triage_vs_area.id_context%TYPE,
        i_null_value           IN PLS_INTEGER DEFAULT g_null_value
    ) RETURN triage_vs_area.id_context%TYPE;

    /**************************************************************************
    * Register triage event.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_params                 Method parameters (XML format)
    * @param o_epis_triage            Triage event ID
    * @param o_epis_anamnesis         Patient complaint ID
    * @param o_shortcut               Shortcut to follow after end of triage
    * @param o_error                  Error message
    *
    * @return                         TRUE/FALSE
    *                        
    * @author                         Sergio Dias
    * @version                        2.6.3.1
    * @since                          21-12-2012
    *
    **************************************************************************/
    FUNCTION create_epis_triage
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_params         IN CLOB,
        o_epis_triage    OUT epis_triage.id_epis_triage%TYPE,
        o_epis_anamnesis OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_shortcut       OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Register triage event.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_params                 Triage info
    * @param o_epis_triage            Triage event ID
    * @param o_epis_anamnesis         Patient complaint ID
    * @param o_shortcut               Shortcut to follow after end of triage
    * @param o_error                  Error message
    *
    * @return                         TRUE/FALSE
    *                        
    * @author                         Sergio Dias
    * @version                        2.6.3.1
    * @since                          21-12-2012
    *
    **************************************************************************/
    FUNCTION create_epis_triage
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_triage         IN pk_edis_types.rec_triage,
        o_epis_triage    OUT epis_triage.id_epis_triage%TYPE,
        o_epis_anamnesis OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_shortcut       OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*************************************************************************************
    * Returns the set of vital signs that show on the top of the board (EST Triage only)
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_episode                Episode ID
    * @param i_triage_board           Board (flowchart) ID
    * @param o_vital_sign             Vital sign data
    * @param o_error                  Error message
    *
    * @return                         TRUE / FALSE
    *                        
    * @author                         Sergio Dias
    * @version                        2.6.3.2
    * @since                          23/11/2009
    ***************************************************************************************/
    FUNCTION get_triage_board_vital_signs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_triage_board IN triage_board.id_triage_board%TYPE,
        i_id_triage_type  IN triage_type.id_triage_type%TYPE,
        o_vital_sign      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_est_additional_attrib
    (
        i_triage_type         IN triage_type.id_triage_type%TYPE,
        i_vs_value            IN vital_sign_read.value%TYPE,
        i_vital_sign_desc     IN vital_sign_desc.id_vital_sign_desc%TYPE,
        i_vsd_value           IN vital_sign_desc.value%TYPE,
        i_pat_age             IN patient.age%TYPE,
        i_flg_pregnant        IN epis_triage.flg_pregnant%TYPE,
        i_pregnancy_weeks     IN epis_triage.preg_weeks%TYPE,
        i_flg_postpartum      IN epis_triage.flg_postpartum%TYPE,
        i_ttv_vs_min          IN triage_type_vs.val_min%TYPE,
        i_ttv_vs_max          IN triage_type_vs.val_max%TYPE,
        i_ttv_vs_desc_related IN triage_type_vs.id_vs_desc_related%TYPE,
        i_ttv_age_min         IN triage_type_vs.age_min%TYPE,
        i_ttv_age_max         IN triage_type_vs.age_max%TYPE,
        i_ttv_flg_pregnant    IN triage_type_vs.flg_pregnant%TYPE,
        i_ttv_min_preg_weeks  IN triage_type_vs.min_preg_weeks%TYPE,
        i_ttv_max_preg_weeks  IN triage_type_vs.max_preg_weeks%TYPE,
        i_ttv_flg_postpartum  IN triage_type_vs.flg_postpartum%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Returns the data about a given vital sign, considering the unit measure
    * in use by the institution.
    * Also returns the vital sign data related with the current discriminator.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_triage_type            Triage type id
    * @param i_pat_age                Patient age
    * @param i_check_type             This function only handles with type F, B and D. The origin of the validation is A
    *                                 validate if it's a type B or D before calling it and send this value instead of A 
    * @param i_rec_check_vs           Record with the information needed to get the correct configuration 
    * @param i_rec_preg               Record with the pregnancy data
    * @param io_rec_vs                Vital sign data
    * @param o_error                  Error message
    *
    * @return                         TRUE / FALSE
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          28/12/2012
    **************************************************************************/
    FUNCTION get_vital_sign_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_triage_type  IN triage_type.id_triage_type%TYPE,
        i_pat_age      IN NUMBER,
        i_check_type   IN VARCHAR2,
        i_rec_check_vs IN pk_edis_types.rec_check_option,
        i_rec_preg     IN pk_edis_types.rec_pregnant,
        io_rec_vs      IN OUT pk_edis_types.rec_vital_sign,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_triage
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB,
        o_result OUT CLOB,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Get triage description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_id_epis_triage    id_epis_triage identifier
    * @param i_desc_type         desc_type S-short/L-long
    *
    * @return               Triage description
    *
    * @author               Sergio Dias
    * @version              2.6.3.5
    * @since                24/05/2013
    */
    FUNCTION get_task_description
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE,
        i_desc_type      IN VARCHAR2
    ) RETURN CLOB;

    /*************************************************************************************
    * Returns a flag that indicates if the '+' button is active in the Triage screen
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_episode             Episode ID
    * @param i_id_triage_type         Triage Type ID
    * @param o_can_create_triage      Variable that tells if this institution can repeat the triage. Values Y/N
    * @param o_error                  Error message
    *
    * @return                         TRUE / FALSE
    *                        
    * @author                         Sergio Dias
    * @version                        2.6.3.6
    * @since                          8/7/2013
    ***************************************************************************************/
    FUNCTION get_can_create_triage
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_triage_type    IN triage_type.id_triage_type%TYPE DEFAULT NULL,
        o_can_create_triage OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /*************************************************************************************
    * Returns the fields to be displayed in the Safeguarding alert popup
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_sys_alert_event     Sys_alert_event identifier
    * @param o_msg_title              Title message to be displayed in the alert popup
    * @param o_msg_text               Title message to be displayed in the alert popup
    * @param o_error                  Error message
    *
    * @return                         TRUE / FALSE
    *                        
    * @author                         Sergio Dias
    * @version                        2.6.3.8.5
    * @since                          Nov-25-2013
    ***************************************************************************************/
    FUNCTION get_safeguard_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sys_alert_event IN sys_alert_event.id_sys_alert_event%TYPE,
        o_msg_title          OUT VARCHAR2,
        o_msg_text           OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * This function returns a string with all read vital signs during a triage, and is to be used in reports
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis_triage         episode triage id 
    * @param i_sep                    new line separator
    *
    * @return                         Stirng with vital sign data
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2014/08/18
    **********************************************************************************************/
    FUNCTION get_epis_triage_vs_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE,
        i_sep            IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Detailed information about a triage safeguarding
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_epis_triage         Triage event ID
    * @param o_epis_triage            Triage Info
    * @param o_error                  Error message
    *
    * @return                         TRUE / FALSE
    *                        
    * @author                         Elisabete Bugalho
    * @version                        2.6.5.2.1
    * @since                          2016/09/09
    **************************************************************************/
    FUNCTION get_epis_triage_safeguarding
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE,
        o_epis_triage    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /**************************************************************************
    * Returns the triage acronym for the most actual triage in given eisode.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_epis                   Episode ID
    * @return                         triage acronym
    *                        
    * @author                         Anna Kurowska
    * @version                        2.7.1
    * @since                          10/03/2017
    **************************************************************************/
    FUNCTION get_epis_triage_acronym
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN triage_type.acronym%TYPE;

    /* *******************************************************************************************
    *  Get current state of Triage for viewer checlist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_triage
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_board_level_msg
    (
        i_id_triage_board IN triage_board.id_triage_board%TYPE,
        i_urgency_level   IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_critical_look_str
    (
        i_lang              IN language.id_language%TYPE,
        i_epis_triage       IN epis_triage.id_epis_triage%TYPE,
        i_flg_critical_look IN epis_triage.flg_critical_look%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_critical_look_desc_str
    (
        i_lang                IN language.id_language%TYPE,
        i_epis_triage         IN epis_triage.id_epis_triage%TYPE,
        i_flg_critical_look   IN epis_triage.flg_critical_look%TYPE,
        i_flg_selected_option IN epis_triage_option.flg_selected_option%TYPE DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;

    /*
      Globals
    */
    g_owner CONSTANT VARCHAR2(32) := 'ALERT';

    g_error        VARCHAR2(4000);
    g_sysdate      DATE;
    g_found        BOOLEAN;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_date_mask    VARCHAR2(16) := 'YYYYMMDDHH24MISS';

    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';

    g_soft_edis        CONSTANT software.id_software%TYPE := 8;
    g_soft_inp         CONSTANT software.id_software%TYPE := 11;
    g_epis_type_urg    CONSTANT episode.id_epis_type%TYPE := 2;
    g_epis_type_intern CONSTANT episode.id_epis_type%TYPE := 5;
    g_epis_type_obs    CONSTANT episode.id_epis_type%TYPE := 6;

    g_epis_active   CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_inactive CONSTANT episode.flg_status%TYPE := 'I';
    g_epis_pending  CONSTANT episode.flg_status%TYPE := 'P';

    g_complaint_act       CONSTANT epis_complaint.flg_status%TYPE := 'A';
    g_flg_available       CONSTANT triage_type_vs.flg_available%TYPE := 'Y';
    g_flg_anam_def        CONSTANT epis_anamnesis.flg_temp%TYPE := 'D';
    g_flg_anam_temp       CONSTANT epis_anamnesis.flg_temp%TYPE := 'T';
    g_flg_type_anam_compl CONSTANT epis_anamnesis.flg_type%TYPE := 'C';

    g_patient_active CONSTANT patient.flg_status%TYPE := 'A';
    g_flg_view_t     CONSTANT VARCHAR2(4) := 'T';
    g_flg_view_v1    CONSTANT VARCHAR2(4) := 'V1';
    g_flg_view_v2    CONSTANT VARCHAR2(4) := 'V2';

    g_vs_avail       CONSTANT vital_sign.flg_available%TYPE := 'Y';
    g_vs_fill_char   CONSTANT vital_sign.flg_fill_type%TYPE := 'V';
    g_vs_read_active CONSTANT vital_sign_read.flg_state%TYPE := 'A';
    g_vs_rel_conc    CONSTANT vital_sign_relation.relation_domain%TYPE := 'C';
    g_vs_rel_man     CONSTANT vital_sign_relation.relation_domain%TYPE := 'M';
    g_vs_rel_sum     CONSTANT vital_sign_relation.relation_domain%TYPE := 'S';

    g_triage_id_manchester    CONSTANT triage_type.id_triage_type%TYPE := 1;
    g_triage_id_nts           CONSTANT triage_type.id_triage_type%TYPE := 3;
    g_triage_id_t3            CONSTANT triage_type.id_triage_type%TYPE := 2;
    g_triage_id_t5            CONSTANT triage_type.id_triage_type%TYPE := 4;
    g_triage_id_mac           CONSTANT triage_type.id_triage_type%TYPE := 5;
    g_triage_id_esi           CONSTANT triage_type.id_triage_type%TYPE := 6;
    g_triage_id_manchester_nl CONSTANT triage_type.id_triage_type%TYPE := 7;
    g_triage_id_hgo           CONSTANT triage_type.id_triage_type%TYPE := 8;
    g_triage_id_est           CONSTANT triage_type.id_triage_type%TYPE := 16;
    g_triage_id_latour        CONSTANT triage_type.id_triage_type%TYPE := 17;
    g_triage_id_ppau          CONSTANT triage_type.id_triage_type%TYPE := 18;
    g_triage_id_sa            CONSTANT triage_type.id_triage_type%TYPE := 19;
    g_triage_id_ctas_p        CONSTANT triage_type.id_triage_type%TYPE := 20;
    g_triage_id_ctas_a        CONSTANT triage_type.id_triage_type%TYPE := 21;
    g_triage_id_atas          CONSTANT triage_type.id_triage_type%TYPE := 23;

    g_no_triage_color_id_m   CONSTANT triage_color.id_triage_color%TYPE := 9;
    g_no_triage_color_id_nts CONSTANT triage_color.id_triage_color%TYPE := 24;
    g_no_triage_color_id_t3  CONSTANT triage_color.id_triage_color%TYPE := 14;
    g_no_triage_color_id_t5  CONSTANT triage_color.id_triage_color%TYPE := 33;

    g_flg_type_color       CONSTANT triage_color.flg_type%TYPE := 'S';
    g_flg_type_color_white CONSTANT triage_color.flg_type%TYPE := 'W';
    g_flg_show_tr_color    CONSTANT triage_color.flg_show%TYPE := 'Y';

    g_movement_finish CONSTANT movement.flg_status%TYPE := 'F';

    g_alert_doc      CONSTANT VARCHAR2(1) := 'D';
    g_alert_nurse    CONSTANT VARCHAR2(1) := 'N';
    g_alert_waiting  CONSTANT VARCHAR2(1) := 'W';
    g_alert_reassess CONSTANT VARCHAR2(1) := 'R';

    g_type_add   CONSTANT VARCHAR2(1) := 'A';
    g_type_rem   CONSTANT VARCHAR2(1) := 'R';
    g_type_match CONSTANT VARCHAR2(1) := 'M';

    g_triage_no_color CONSTANT triage_color.color%TYPE := '0xC3C3A5';

    g_default_view_v5 CONSTANT VARCHAR2(10 CHAR) := 'V5';

    g_rank_highest_importance CONSTANT NUMBER(6) := 999;
    g_rank_very_important     CONSTANT NUMBER(6) := 200;
    g_rank_important          CONSTANT NUMBER(6) := 100;
    g_rank_less_important     CONSTANT NUMBER(6) := -999;

    g_manchester    CONSTANT triage_type.acronym%TYPE := 'M';
    g_manchester_nl CONSTANT triage_type.acronym%TYPE := 'M2NL';
    g_manchester_uk CONSTANT triage_type.acronym%TYPE := 'M2UK';
    g_t5            CONSTANT triage_type.acronym%TYPE := 'T5';
    g_mac           CONSTANT triage_type.acronym%TYPE := 'MAC';
    g_esi           CONSTANT triage_type.acronym%TYPE := 'ESI';
    g_hgo           CONSTANT triage_type.acronym%TYPE := 'HGO';
    g_vic           CONSTANT triage_type.acronym%TYPE := 'VIC';
    g_latour        CONSTANT triage_type.acronym%TYPE := 'LATOUR';
    g_est           CONSTANT triage_type.acronym%TYPE := 'EST';
    g_ctas_ped      CONSTANT triage_type.acronym%TYPE := 'CTAS_PED';
    g_ctas_adult    CONSTANT triage_type.acronym%TYPE := 'CTAS_ADULT';
    g_atas_mental   CONSTANT triage_type.acronym%TYPE := 'ATAS_MENTAL_TOOL';

    g_type_color_title CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_type_color_value CONSTANT VARCHAR2(1 CHAR) := 'V';

    g_last_box_yes   CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_last_box_no    CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_last_box_other CONSTANT VARCHAR2(1 CHAR) := 'O';

    g_flg_context_id_triage_disc  CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_flg_context_id_triage_board CONSTANT VARCHAR2(1 CHAR) := 'B';
    g_flg_context_id_ds_component CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_flg_context_check_all       CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_flg_context_check_critical  CONSTANT VARCHAR2(1 CHAR) := 'C';

    g_flg_reassess_secondary CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_flg_reassess_yes       CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_flg_reassess_no        CONSTANT VARCHAR2(1 CHAR) := 'N';

    g_ds_comp_lst_yes_no CONSTANT pk_translation.t_desc_translation := 'TRI_EST_YES_NO';

    g_ds_comp_triage         CONSTANT ds_component.internal_name%TYPE := 'TRIAGE';
    g_ds_comp_triage_general CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_GENERAL_DATA';

    g_ds_comp_origin        CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_ORIGIN';
    g_ds_comp_desc_origin   CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_DESC_ORIGIN';
    g_ds_comp_letter        CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_LETTER';
    g_ds_comp_needs         CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_NEEDS';
    g_ds_comp_arrived_by    CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_ARRIVED_BY';
    g_ds_comp_emerg_cont    CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_EMERGENCY_CONTACT';
    g_ds_comp_chief_comp    CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_CHIEF_COMPLAINT';
    g_ds_comp_accident_desc CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_ACCIDENT_DESC';
    g_ds_comp_cause         CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_CAUSE';
    g_ds_comp_comments      CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_COMMENTS';

    g_ds_comp_triage_est  CONSTANT ds_component.internal_name%TYPE := 'TRI_EST';
    g_ds_comp_triage_sa   CONSTANT ds_component.internal_name%TYPE := 'TRI_SA';
    g_ds_comp_triage_ctas CONSTANT ds_component.internal_name%TYPE := 'TRI_CTAS';

    g_ds_comp_est_vsigns CONSTANT ds_component.internal_name%TYPE := 'TRI_EST_PARAMETRES_VITAUX';
    g_ds_comp_vsigns     CONSTANT ds_component.internal_name%TYPE := 'TRI_VITAL_SIGNS';

    g_ds_comp_est_entourage       CONSTANT ds_component.internal_name%TYPE := 'TRI_EST_ENTOURAGE';
    g_ds_comp_est_motif_entree    CONSTANT ds_component.internal_name%TYPE := 'TRI_EST_MOTIF_ENTREE';
    g_ds_comp_est_femme_enc_fr    CONSTANT ds_component.internal_name%TYPE := 'TRI_EST_FEMME_ENCEINTE_FR';
    g_ds_comp_est_femme_enceinte  CONSTANT ds_component.internal_name%TYPE := 'TRI_EST_FEMME_ENCEINTE';
    g_ds_comp_est_femme_encnt_wks CONSTANT ds_component.internal_name%TYPE := 'TRI_EST_FEMME_ENCEINTE_WEEKS';
    g_ds_comp_est_femme_1mois_pp  CONSTANT ds_component.internal_name%TYPE := 'TRI_EST_FEMME_1MOIS_PP';
    g_ds_comp_est_traitement      CONSTANT ds_component.internal_name%TYPE := 'TRI_EST_TRAITEMENT';
    g_ds_comp_est_notes           CONSTANT ds_component.internal_name%TYPE := 'TRI_EST_NOTES';
    g_ds_comp_est_needs           CONSTANT ds_component.internal_name%TYPE := 'TRI_EST_NEEDS';
    g_ds_comp_est_arrived_by      CONSTANT ds_component.internal_name%TYPE := 'TRI_EST_ARRIVED_BY';

    g_ds_comp_vital_signs_form CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_VITAL_SIGNS';
    g_ds_comp_vital_signs_node CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_VITAL_SIGNS_NODE';

    g_sample_text_entourage     CONSTANT sample_text_type.intern_name_sample_text_type%TYPE := 'TRI_EST_ENTOURAGE';
    g_sample_text_chief_comp    CONSTANT sample_text_type.intern_name_sample_text_type%TYPE := 'QUEIXA';
    g_sample_text_traitment     CONSTANT sample_text_type.intern_name_sample_text_type%TYPE := 'TRI_EST_TRAITEMENT';
    g_sample_text_autres_signes CONSTANT sample_text_type.intern_name_sample_text_type%TYPE := 'TRI_EST_AUTRES_SIGNES_CLIN_OBSERV';
    g_sample_text_desc_origin   CONSTANT sample_text_type.intern_name_sample_text_type%TYPE := 'TRIAGE_DESC_ORIGIN';
    g_sample_text_accident_desc CONSTANT sample_text_type.intern_name_sample_text_type%TYPE := 'TRIAGE_ACCIDENT_DESC';

    g_vs_peak_flow_parent     CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'EST_PARENT_PeakFlow'; --Parent Peak flow
    g_vs_peak_flow_expiratory CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'Peak_Flow'; --Peak expiratory flow
    g_vs_peak_flow_expected   CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'Peak_flow_predite'; --Peak-flow normal expected value
    g_vs_shock_index_subform  CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'Index_Choc_SUBFORM'; --Shock index SUBFORM
    g_vs_shock_index          CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'Index_Choc'; --Shock index
    g_vs_shock_index_ign_res  CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'Index_Choc_IGNORE_RESULT'; --Shock index ignore result
    g_vs_heart_rate           CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'HEART_RATE'; --Heart rate
    g_vs_blood_pressure       CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'BLOOD_PRESSURE'; --Blood pressure; Parent of Systolic and Diastolic blood pressure
    g_vs_blood_pressure_s     CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'BLOOD_PRESSURE_S'; --Systolic blood pressure
    g_vs_blood_pressure_d     CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'BLOOD_PRESSURE_D'; --Diastolic blood pressure
    g_vs_pain                 CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'PAIN';
    g_vs_pulse_rythm          CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'PULSE_RYTHM';
    g_vs_rythm_pulse          CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'RYTHM_PULSE';
    g_vs_glasgow              CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'GLASGOW';
    g_vs_pulse                CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'PULSE';
    g_vs_trts                 CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'TRTS';
    g_vs_proteinuria          CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'PROTEINURIA';
    g_vs_height               CONSTANT vital_sign.intern_name_vital_sign%TYPE := 'HEIGHT';

    g_triage_conf_chk_vs_o   CONSTANT triage_configuration.flg_check_vital_sign%TYPE := 'O'; --No and never show warning
    g_triage_conf_chk_vs_yes CONSTANT triage_configuration.flg_check_vital_sign%TYPE := 'Y'; --Yes.
    g_triage_conf_chk_vs_no  CONSTANT triage_configuration.flg_check_vital_sign%TYPE := 'N'; --No, but warn user

    g_colon       CONSTANT VARCHAR2(1 CHAR) := ':';
    g_space       CONSTANT VARCHAR2(1 CHAR) := ' ';
    g_desc_type_s CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_desc_type_l CONSTANT VARCHAR2(1 CHAR) := 'L';

    g_cfg_can_repeat_triage      CONSTANT sys_config.id_sys_config%TYPE := 'TRIAGE_ALLOW_REPEAT_TRIAGE';
    g_cfg_alert_triage_safeguard CONSTANT sys_config.id_sys_config%TYPE := 'TRIAGE_GENERATE_SAFEGUARD_ALERT';

    g_age_min CONSTANT VARCHAR2(3) := 'MIN';
    g_age_max CONSTANT VARCHAR2(3) := 'MAX';

    g_ds_safeguard                 CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING';
    g_ds_safeguard_under_two_years CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_UNDER_TWO_YEARS';
    g_ds_safeguard_immobile        CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_IMMOBILE';
    g_ds_safeguard_injury          CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_UNEXPLAINED_INJURY';
    g_ds_safeguard_protection_plan CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_PROTECTION_PLAN';
    g_ds_safeguard_attend_delay    CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_ATTENDANCE_DELAY';
    g_ds_safeguard_domestic_abuse  CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_DOMESTIC_ABUSE';
    g_ds_safeguard_expl_injury     CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_EXPLAINED_INJURY';
    g_ds_safeguard_has_social_w    CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_HAS_SOCIAL_WORKER';
    g_ds_safeguard_social_name     CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_SOCIAL_WORKER_NAME';
    g_ds_safeguard_social_add      CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_SOCIAL_WORKER_ADD';
    g_ds_safeguard_social_services CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_SOCIAL_SERVICES';
    g_ds_safeguard_social_reason   CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_SOCIAL_REASON';
    g_ds_safeguard_social_consent  CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_SOCIAL_CONSENT';
    g_ds_safeguard_social_infor    CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_SOCIAL_INFORMATION';
    g_ds_safeguard_social_dt       CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_SOCIAL_DATE';
    g_ds_safeguard_social_info_req CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_SOCIAL_INFO_REQ';
    g_ds_safeguard_abuse_sign      CONSTANT ds_component.internal_name%TYPE := 'TRIAGE_SAFEGUARDING_ABUSE_SIGN';
END pk_edis_triage;
/
