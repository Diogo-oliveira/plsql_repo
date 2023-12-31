/*-- Last Change Revision: $Rev: 2028668 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:13 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_edis_triage_ux IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 15-12-2011 10:40:34
    -- Purpose : Triage API's called by 

    -- Public type declarations
    --type <TypeName> is <Datatype>;
    TYPE rec_anamnesis IS RECORD(
        id_epis_anamnesis   epis_anamnesis.id_epis_anamnesis%TYPE,
        desc_epis_anamnesis pk_translation.t_desc_translation);

    TYPE cursor_anamnesis IS REF CURSOR RETURN rec_anamnesis;
    -- Public constant declarations
    --<ConstantName> constant <Datatype> := <Value>;

    -- Public variable declarations
    --<VariableName> <Datatype>;

    -- Public function and procedure declarations
    --function <FunctionName>(<Parameter> <Datatype>) return <Datatype>;

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

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
    * @param   i_component_name            Component name
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
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_events         OUT pk_types.cursor_type,
        o_items_values   OUT pk_types.cursor_type,
        o_data_val       OUT CLOB,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
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
        i_triage_board         IN triage_board.id_triage_board%TYPE,
        i_triage_discriminator IN triage_discriminator.id_triage_discriminator%TYPE,
        o_section              OUT pk_types.cursor_type,
        o_def_events           OUT pk_types.cursor_type,
        o_events               OUT pk_types.cursor_type,
        o_items_values         OUT pk_types.cursor_type,
        o_data_val             OUT CLOB,
        o_error                OUT t_error_out
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
    * @author                          Jos� Brito
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
    * @author                         Jos� Brito
    * @version                        2.6
    * @since                          11-Dez-2009
    *
    * @author                         Jos� Brito
    * @version                        2.6.1
    * @since                          25-Jan-2012
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

    /**********************************************************************************************
    * Listar os fluxogramas associados � queixa activa, do epis�dio.   
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_epis                   episode id
    * @param o_comp_t                 Listar os fluxogramas associados � queixa, activa, do epis�dio 
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
        o_anamnesis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Listar todos os epis�dios de triagem 
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis                episode id
    * @param o_epis_triage            array com os todos os epis�dios de triagem deste episodio   
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

    /********************************************************************************************
    * Devolver as cores associadas ao tipo de triagem, bem como a cor do epis�dio em an�lise
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_color_triage        array with color triage and color episode
    
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    
    * @author                      Em�lia Taborda
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
        o_epis_triage    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @author                          Jos� Brito
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

    /**********************************************************************************************
    * Listar as descri��es e respectiva rela��o grupo / fluxograma da triagem.
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_patient                patient id
    * @param i_t_board_group          ID do grupo do fluxograma 
    * @param i_flg_view               Tipo de vis�o: V1- Vis�o 1 de manchester
                                                     V2- Vis�o 2 de manchester
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
    * @author                         Jos� Brito
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

    /**************************************************************************
    * Returns the set of child discriminators for the discriminator.
    * This is used in the ESI triage protocol.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_disc                Parent discriminator ID
    * @param o_discrim_child          Discriminator data
    * @param o_error                  Error message
    *
    * @return                         TRUE / FALSE
    *                        
    * @author                         Jos� Brito
    * @version                        2.6
    * @since                          04/01/2010
    **************************************************************************/
    FUNCTION get_triage_discrim_child
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_disc       IN triage_discriminator.id_triage_discriminator%TYPE,
        o_discrim_child OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

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
        o_discrim_child OUT pk_types.cursor_type,
        o_error         OUT t_error_out
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
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Jos� Brito
    * @since                       2009/03/26
    * @version                     1.0
    *
    */
    FUNCTION get_triage_labels
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        o_flowchart        OUT VARCHAR2,
        o_discriminator    OUT VARCHAR2,
        o_reason_for_visit OUT VARCHAR2,
        o_fchart_selection OUT VARCHAR2,
        o_current_prof     OUT VARCHAR2,
        o_protocol         OUT VARCHAR2,
        o_confirmation     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_flg_confirm  IN VARCHAR2,
        o_n_consid     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Calcular o valor total do TRTS (Conjunto de sinais vitais)   
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_triage_discrim         discriminator id
    * @param i_vs_id                  Array de IDs de SVs lidos
    * @param i_vs_val                 Array de leituras dos SVs de I_VS_ID ( (valor do sinal vital) 
    * @param i_flg_view               Posi��o dos sinais vitais:S- Resumo; 
                                                                H- Sa�da de turno; 
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
    * @alter                          Jos� Brito
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

    /**************************************************************************
    * Validates whether the registered values for the discriminator's vital signs
    * are within the limits required to accept it.
    *   
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_episode              Episode ID
    * @param i_id_patient              Patient ID
    * @param i_id_disc                 Discriminator ID
    * @param i_id_triage               Triage ID
    * @param i_vital_signs             Array with the vital sign ID's
    * @param i_values                  Array with the registered values for each vital sign
    * @param i_unit_measures           Array with the unit measure ID's for each vital sign
    * @param i_user_selected_option    Option selected by the user
    * @param o_id_triage_vs_area       First vital sign validation accepted in triage
    * @param o_select_option           Option that must be applied to the discriminator
    * @param o_flg_show                Show message to user? (Y) Yes (N) No
    * @param o_msg_title               Message title
    * @param o_msg                     Message text
    * @param o_button                  Message button
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *                        
    * @author                          Alexandre Santos
    * @version                         2.6.0.4
    * @since                           26/08/2010
    **************************************************************************/
    FUNCTION validate_discrim_vs_esi
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_disc              IN triage_discriminator.id_triage_discriminator%TYPE,
        i_id_triage            IN triage.id_triage%TYPE,
        i_vital_signs          IN table_number,
        i_values               IN table_number,
        i_unit_measures        IN table_number,
        i_user_selected_option IN triage.flg_accepted_option%TYPE,
        i_scales_element_id    IN vital_sign_scales_element.id_vs_scales_element%TYPE DEFAULT NULL,
        o_id_triage_vs_area    OUT triage_vs_area.id_triage_vs_area%TYPE,
        o_select_option        OUT VARCHAR2,
        o_flg_show             OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_msg                  OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Validates whether the registered values for the discriminator's vital signs
    * are within the limits required to accept it.
    *   
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_episode              Episode ID
    * @param i_id_patient              Patient ID
    * @param i_id_disc                 Discriminator ID
    * @param i_id_triage               Triage ID
    * @param i_vital_signs             Array with the vital sign ID's
    * @param i_values                  Array with the registered values for each vital sign
    * @param i_unit_measures           Array with the unit measure ID's for each vital sign
    * @param i_user_selected_option    Option selected by the user
    * @param i_tri_disc_consent        Triage discriminator consent value
    * @param o_id_triage_vs_area       First vital sign validation accepted in triage
    * @param o_select_option           Option that must be applied to the discriminator
    * @param o_flg_show                Show message to user? (Y) Yes (N) No
    * @param o_msg_title               Message title
    * @param o_msg                     Message text
    * @param o_button                  Message button
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *                        
    * @author                          Jos� Brito
    * @version                         2.6
    * @since                           23/11/2009
    **************************************************************************/
    FUNCTION validate_discriminator_vs
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_disc              IN triage_discriminator.id_triage_discriminator%TYPE,
        i_id_triage            IN triage.id_triage%TYPE,
        i_vital_signs          IN table_number,
        i_values               IN table_number,
        i_unit_measures        IN table_number,
        i_user_selected_option IN triage.flg_accepted_option%TYPE,
        i_scales_element_id    IN vital_sign_scales_element.id_vs_scales_element%TYPE DEFAULT NULL,
        i_tri_disc_consent     IN epis_triage_option.id_triage_cons_value%TYPE,
        o_id_triage_vs_area    OUT triage_vs_area.id_triage_vs_area%TYPE,
        o_select_option        OUT VARCHAR2,
        o_flg_show             OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_msg                  OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Validates a set of discriminators, when pressing the buttons 'No' or 'OK', to check
    * if the triage can proceed, if there are remaining vital signs to be registered,
    * or if there are any invalid options.
    *   
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_episode              Episode ID
    * @param i_id_patient              Patient ID
    * @param i_id_disc                 Array with discriminator ID's
    * @param i_id_triage               Array with triage ID's
    * @param i_selected_option         Array with selected options for each discriminator
    * @param i_vital_signs             Array with the vital sign ID's
    * @param i_values                  Array with the registered values for each vital sign
    * @param i_unit_measures           Array with the unit measure ID's for each vital sign
    * @param i_tri_disc_consent        Triage discriminator consent value
    * @param o_flg_show                Show message to user? (Y) Yes (N) No
    * @param o_msg_title               Message title
    * @param o_msg                     Message text
    * @param o_button                  Message button
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *                        
    * @author                          Jos� Brito
    * @version                         2.6
    * @since                           08/01/2010
    **************************************************************************/
    FUNCTION validate_discriminator_vs_all
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_disc           IN table_number,
        i_id_triage         IN table_number,
        i_selected_option   IN table_varchar,
        i_vital_signs       IN table_number,
        i_values            IN table_number,
        i_unit_measures     IN table_number,
        i_scales_element_id IN vital_sign_scales_element.id_vs_scales_element%TYPE DEFAULT NULL,
        i_tri_disc_consent  IN epis_triage_option.id_triage_cons_value%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Used only in ESI protocol. Validates the discriminator to be selected in the
    * Decision Point D (Patient's vital signs).
    *   
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_episode              Episode ID
    * @param i_id_patient              Patient ID
    * @param i_id_disc                 Parent discriminator ID
    * @param i_id_triage               Triage event ID
    * @param i_vital_signs             Array with the vital sign ID's
    * @param i_values                  Array with the registered values for each vital sign
    * @param i_unit_measures           Array with the unit measure ID's for each vital sign
    * @param i_tri_disc_consent        Triage discriminator consent value
    * @param o_id_triage_discrim       Discriminator to be selected
    * @param o_desc_discrim            Discriminator label
    * @param o_id_triage               Triage ID
    * @param o_select_option           Option to be selected in the parent discriminator
    * @param o_flg_accepted_option     Accepted option of the selected discriminator
    * @param o_error                   Error message
    *
    * @return                          TRUE / FALSE
    *                        
    * @author                          Jos� Brito
    * @version                         2.6
    * @since                           12/01/2010
    **************************************************************************/
    FUNCTION validate_discriminator_vs_esi
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_disc             IN triage_discriminator.id_triage_discriminator%TYPE,
        i_id_triage           IN triage.id_triage%TYPE,
        i_vital_signs         IN table_number,
        i_values              IN table_number,
        i_unit_measures       IN table_number,
        i_scales_element_id   IN vital_sign_scales_element.id_vs_scales_element%TYPE DEFAULT NULL,
        i_tri_disc_consent    IN epis_triage_option.id_triage_cons_value%TYPE,
        o_id_triage_discrim   OUT triage_discriminator.id_triage_discriminator%TYPE,
        o_desc_discrim        OUT VARCHAR2,
        o_id_triage           OUT triage.id_triage%TYPE,
        o_select_option       OUT triage.flg_accepted_option%TYPE,
        o_flg_accepted_option OUT triage.flg_accepted_option%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @author                         Jos� Brito
    * @version                        2.6
    * @since                          23/11/2009
    **************************************************************************/
    FUNCTION get_triage_configurations
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_config  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Checks whether the registered values for the vital signs
    * are within the limits, of the context, required to accept it.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_params                 XML with all input parameters (Please consult documentation for more detail)
    * @param o_result                 XML with all output parameters (Please consult documentation for more detail)
    * @param o_error                  Error message
    *
    * @return                         TRUE / FALSE
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          09/01/2013
    **************************************************************************/
    FUNCTION check_triage
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB,
        o_result OUT CLOB,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /*************************************************************************************
    * Returns the set of vital signs that show on the top of the board (EST Triage only)
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_episode                Episode ID
    * @param i_id_triage_board           Board (flowchart) ID
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
    * @author                         Elisabete Bugalho
    * @version                        2.6.5.1
    * @since                          25-05-2016
    ********************************************--*****************************/
    FUNCTION get_epis_triage_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE,
        o_epis_triage    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
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
    * @author                         Elisabete Bugalho
    * @version                        2.6.3.1
    * @since                          10-12-2012
    **************************************************************************/
    FUNCTION get_epis_triage_safeguarding
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_triage IN epis_triage.id_epis_triage%TYPE,
        o_epis_triage    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
END pk_edis_triage_ux;
/
