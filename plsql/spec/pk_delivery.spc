/*-- Last Change Revision: $Rev: 2028594 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_delivery IS

    -- Created : 07-01-2008
    -- Purpose : Partogram developments

    /********************************************************************************************
    * Converts the duration of the drug prescription into hours
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution IDs
    * @param i_duration              take duration
    * @param i_unit_measure          duration measure (minutes, days, hours)   
    * @param i_flg_take_type         flg_take_type: C - continuous
    * 
    * @return number of hours
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         06-05-2008
    * @dependents                    PK_DELIVERY
    ********************************************************************************************/
    FUNCTION get_delivery_duration_hours
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dt_begin      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_multiplier    IN NUMBER,
        i_flg_take_type IN drug_presc_det.flg_take_type%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Gets the number of registered fetus during the labor and delivery documentation
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_pat_pregnancy              pregnancy ID
    * @param o_fetus_number               number of registered fetus        
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              15-04-2008
    **********************************************************************************************/

    FUNCTION get_fetus_number
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_fetus_number  OUT epis_doc_delivery.fetus_number%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the number of registered fetus during the labor and delivery documentation
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_pat_pregnancy              pregnancy ID
    * @param i_type                       date type: S - birth start date, E - birth end date
    * @param i_child_number               Child number    
    * @param o_fetus_number               number of registered fetus        
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              15-04-2008
    **********************************************************************************************/

    FUNCTION get_dt_birth
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_type          IN VARCHAR2,
        i_child_number  IN epis_doc_delivery.child_number%TYPE,
        o_dt_birth      OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the registered value with the struture used in the partogram grid/graph
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_patient                    patient ID
    * @param i_pat_pregnancy              pregnancy ID
    *                    
    * @return                             value string
    *
    * @author                             Jos?Silva
    * @version                            2.6.0.5  
    * @since                              17-03-2011
    **********************************************************************************************/
    FUNCTION get_reg_value
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_pat_pregnancy        IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_vital_sign           IN vital_sign.id_vital_sign%TYPE,
        i_vs_parent            IN vital_sign_relation.id_vital_sign_parent%TYPE,
        i_value                IN vital_sign_read.value%TYPE,
        i_code_abbreviation    IN vital_sign_desc.code_abbreviation%TYPE,
        i_code_vital_sign_desc IN vital_sign_desc.code_vital_sign_desc%TYPE,
        i_icon                 IN vital_sign_desc.icon%TYPE,
        i_value_desc           IN vital_sign_desc.value%TYPE,
        i_grid_type            IN VARCHAR2,
        i_dt_vital_sign_read   IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_fetus_number         IN vital_sign_pregnancy.fetus_number%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the registered value with the struture used in the partogram grid/graph
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_hours                   list of hours that have delivery records
    * @param i_dt_delivery             delivery start date
    * @param i_dt_vital_sign_read      vital sign record date
    *                    
    * @return                             value string
    *
    * @author                             Jos?Silva
    * @version                            2.6.0.5  
    * @since                              17-03-2011
    **********************************************************************************************/
    FUNCTION get_hour_delivery
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_hours              IN table_number,
        i_dt_delivery        IN epis_doc_delivery.dt_delivery_tstz%TYPE,
        i_dt_vital_sign_read IN vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Gets the hexadecimal color for a specific vital sign (depending on the fetus number)
    *
    * @param i_color                      original hexadecimal color
    * @param i_intern_name                vital sign type (patient or fetus)
    * @param i_fetus_number               fetus number
    * @param i_flg_view                   vital sign area (graph main view or graph backgrounf)
    *                    
    * @return                             hexadecimal color
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              17-06-2009
    **********************************************************************************************/
    FUNCTION get_graph_color
    (
        i_color        IN vs_soft_inst.color_grafh%TYPE,
        i_intern_name  IN time_event_group.intern_name%TYPE,
        i_fetus_number IN NUMBER,
        i_total_fetus  IN NUMBER,
        i_flg_view     IN vs_soft_inst.flg_view%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the dynamic elements of the partogram documentation
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_id_doc_area           documentation area
    * @param i_id_doc_template       associated template    
    *
    * @return o_dyn_elements         dynamic elements and their relations
    * @return o_init_values          initial values for the action producing elements
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         24-08-2007
    ********************************************************************************************/
    FUNCTION get_delivery_dynamic_doc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_doc_area        IN doc_area.id_doc_area%TYPE,
        i_id_doc_template    IN doc_template.id_doc_template%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_dyn_elements       OUT pk_types.cursor_type,
        o_init_values        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the episode documentation related to woman health delivery for report purposes
    *
    * @param i_lang                  language id
    * @param i_prof_id               professional id
    * @param i_prof_inst             institution id
    * @param i_prof_sw               software id
    * @param i_episode               episode ID   
    * @param i_pat_pregancy          patient pregnancy id
    * @param i_doc_area              documentation area ID    
    *
    * @return o_doc_area_register    episode documentation IDs related to the i_pat_pregnancy ID
    * @return o_doc_area_val         episode documentation values related to the i_pat_pregnancy ID 
    * @return                        true or false on success or error
    *
    * @author                        Fábio Oliveira
    * @version                       1.0    
    * @since                         12-08-2008
    ********************************************************************************************/
    FUNCTION get_delivery_epis_doc_rep
    (
        i_lang              IN language.id_language%TYPE,
        i_prof_id           IN professional.id_professional%TYPE,
        i_prof_inst         IN institution.id_institution%TYPE,
        i_prof_sw           IN software.id_software%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_pat_pregnancy     IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the episode documentation related to woman health delivery
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_episode               episode ID   
    * @param i_pat_pregancy          patient pregnancy id
    * @param i_doc_area              documentation area ID    
    *
    * @return o_doc_area_register    episode documentation IDs related to the i_pat_pregnancy ID
    * @return o_doc_area_val         episode documentation values related to the i_pat_pregnancy ID 
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         27-08-2007
    ********************************************************************************************/
    FUNCTION get_delivery_epis_doc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_pat_pregnancy     IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the sections presented in the delivery evaluation
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_id_summary_page       summary page ID
    * @param i_id_pat_pregnancy      pregnancy ID       
    *
    * @return o_sections             evaluation sections 
    * @return o_value                the number of fetus documented in the assessment   
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva, Luís Gaspar
    * @version                       1.0    
    * @since                         29-08-2007
    ********************************************************************************************/
    FUNCTION get_delivery_sections
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_summary_page  IN summary_page.id_summary_page%TYPE,
        i_id_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_sections         OUT pk_types.cursor_type,
        o_value            OUT NUMBER,
        o_dt_format        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the axis to fill the monitoring grid
    *
    * @param i_lang                  language id
    * @param i_patient               patient id
    * @param i_episode               episode id
    * @param i_prof                  professional, software and institution ids
    * @param i_pat_pregnancy         pregnancy id
    *
    * @return o_time                 time event axis
    * @return o_sign_v               available vital signs             
    * @return o_dt_ini               minimum vital sign limit
    * @return o_dt_end               maximum vital sign limit
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         31-08-2007
    ********************************************************************************************/

    FUNCTION get_delivery_axis
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_time          OUT pk_types.cursor_type,
        o_sign_v        OUT pk_types.cursor_type,
        o_dt_ini        OUT VARCHAR2,
        o_dt_end        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the values to fill the monitoring grid
    *
    * @param i_lang                  language id
    * @param i_patient               patient id
    * @param i_prof                  professional, software and institution ids
    * @param i_pat_pregnancy         pregnancy id
    * @param i_fetus_number          the number of fetus documented in the assessment   
    *
    * @return o_val_vs               vital sign values             
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         31-08-2007
    ********************************************************************************************/
    FUNCTION get_delivery_time_event
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_fetus_number  IN NUMBER,
        o_val_vs        OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets the delivery vital sign values
    *
    * @param i_lang                  language id
    * @param i_episode               episode id   
    * @param i_prof                  professional, software and institution ids
    * @param i_patient               patient ID   
    * @param i_pat_pregnancy         pregnancy id
    * @param i_flg_type              function call type: 'S' - set ; 'U' - update
    * @param i_vs_id                 vital sign IDs ('S') or vital sign values ID ('U')
    * @param i_vs_val                vital sign values
    * @param i_unit_meas             unit measures
    * @param i_vs_date               registration dates of the given values
    * @param i_fetus_number          the fetus number belonging to the vital sign values
    * @param i_prof_cat_type         professional category                
    *
    * @return o_vital_sign_read      vital sign values ID           
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         31-08-2007
    ********************************************************************************************/
    FUNCTION set_delivery_vital_sign
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN vital_sign_read.id_episode%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_type        IN VARCHAR2,
        i_vs_id           IN table_number,
        i_vs_val          IN table_number,
        i_unit_meas       IN table_number,
        i_vs_date         IN table_varchar,
        i_fetus_number    IN table_number,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_vital_sign_read OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the delivery event axis
    *
    * @param i_lang                  language id
    * @param i_patient               patient ID     
    * @param i_episode               episode ID     
    * @param i_prof                  professional, software and institution IDs 
    * @param i_pat_pregnancy         pregnancy id
    * @param i_flg_type              axis type 'G' - graph ; 'T' - table
    *
    * @return o_time                 time axis (graph type)
    * @return o_time_t               time axis (table type)   
    * @return o_sign_v               vital sign axis    
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         01-09-2007
    ********************************************************************************************/
    FUNCTION get_delivery_event_axis
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_type      IN VARCHAR2,
        o_time          OUT NUMBER,
        o_time_t        OUT pk_types.cursor_type,
        o_sign_v        OUT pk_types.cursor_type,
        o_drug          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all vital sign delivery events
    *
    * @param i_lang                  language id
    * @param i_patient               patient ID     
    * @param i_prof                  professional, software and institution ids 
    * @param i_pat_pregnancy         pregnancy id 
    * @param i_flg_type              axis type 'G' - graph ; 'T' - table                  
    *        
    * @return o_val_vs               vital sign values    
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         03-09-2007
    ********************************************************************************************/
    FUNCTION get_delivery_vs
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_type      IN VARCHAR2,
        o_val_vs        OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all drug prescriptions during delivery period
    *
    * @param i_lang                  language ID
    * @param i_episode               episode ID       
    * @param i_prof                  professional, software and institution ids 
    * @param i_patient               patient ID     
    * @param i_pat_pregnancy         pregnancy id
    * @param i_flg_type              axis type 'G' - graph ; 'T' - table                     
    *        
    * @return o_drug                 drug prescriptions    
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         03-09-2007
    ********************************************************************************************/
    FUNCTION get_delivery_drug
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN vital_sign_read.id_episode%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_type      IN VARCHAR2,
        o_drug          OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if a doc area has registers in a specified delivery associated to a given professional.
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param i_doc_area            doc area id 
    * @param i_pat_pregnancy       pregnancy id 
    * @param i_child_number        child number
    * @param o_last_prof_epis_doc  Last documentation episode ID to profissional      
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *                        
    * @return                      true or false on success or error
    *
    * @author                  Jos?Silva
    * @version                       1.0                      
    * @since                   05-09-2007
    **********************************************************************************************/
    FUNCTION get_prof_doc_delivery_exists
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_child_number       IN epis_doc_delivery.child_number%TYPE,
        o_last_prof_epis_doc OUT epis_documentation.id_epis_documentation%TYPE,
        o_flg_data           OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the professional who registered the last change (and the respective date) 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param i_pat_pregnancy          Pregnancy id    
    * @param o_last_update            Cursor containing the last update register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Jos?Silva
    * @version                        1.0    
    * @since                          05-09-2007
    **********************************************************************************************/
    FUNCTION get_delivery_doc_last_update
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_doc_area      IN table_number,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_last_update   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the statics lines presented in the delivery graph
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID) 
    *                        
    * @return o_lines                 Static lines
    * @return                         true or false on success or error
    * 
    * @author                         Jos?Silva
    * @version                        1.0    
    * @since                          07-09-2007
    **********************************************************************************************/
    FUNCTION get_delivery_graph_lines
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_lines OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets documentation values and partogram registries
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_prof_cat_type              professional category
    * @param i_doc_area                   doc_area id
    * @param i_doc_template               doc_template id
    * @param i_epis_documentation         epis documentation id
    * @param i_flg_type                   A Agree, E edit, N - new 
    * @param i_id_documentation           array with id documentation,
    * @param i_id_doc_element             array with doc elements
    * @param i_id_doc_element_crit        array with doc elements crit
    * @param i_value                      array with values,
    * @param i_notes                      note
    * @param i_id_doc_element_qualif      array with doc elements qualif  
    * @param i_epis_context               episode context id (Ex: id_interv_presc_det,...)
    * @param i_pat_pregnancy              patient pregnancy ID
    * @param i_doc_element_ext            doc_element IDs containing external info
    * @param i_values_ext                 saved doc_element values
    * @param i_child_number               child number associated to saved documentation          
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              24-10-2007
    **********************************************************************************************/

    FUNCTION set_epis_doc_delivery
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation_det.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_pat_pregnancy         IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_doc_element_ext       IN table_number,
        i_values_ext            IN table_number,
        i_child_number          IN epis_doc_delivery.child_number%TYPE,
        i_validate              IN VARCHAR2,
        o_flg_msg               OUT VARCHAR2,
        o_show_warning          OUT VARCHAR2,
        o_flg_type              OUT VARCHAR2,
        o_title                 OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_id_department         OUT dep_clin_serv.id_department%TYPE,
        o_id_clinical_service   OUT dep_clin_serv.id_clinical_service%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_doc_delivery_internal
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation_det.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_pat_pregnancy         IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_doc_element_ext       IN table_number,
        i_values_ext            IN table_number,
        i_child_number          IN epis_doc_delivery.child_number%TYPE,
        i_validate              IN VARCHAR2,
        o_flg_msg               OUT VARCHAR2,
        o_show_warning          OUT VARCHAR2,
        o_flg_type              OUT VARCHAR2,
        o_title                 OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates a temporary episode to the newborn child
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_patient                    patient ID (mother)
    * @param i_pat_pregnancy              pregnancy ID
    * @param i_child_number               child number associated with the current documentation
    * @param i_new_patient                patient ID for the born child
    * @param o_episode                    ID of the created episode
    * @param o_patient                    ID of the created patient
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos?Silva
    * @version                            1.0   
    * @since                              15-04-2008
    
    * @author                             Jos?Silva
    * @version                            2.0   
    * @since                              20-04-2009
    **********************************************************************************************/
    FUNCTION create_child_episode
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_child_number       IN epis_doc_delivery.child_number%TYPE,
        i_new_patient        IN patient.id_patient%TYPE,
        o_episode            OUT episode.id_episode%TYPE,
        o_patient            OUT patient.id_patient%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Cancel an episode documentation associated with labor and delivery assessment
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_epis_doc            the documentation episode ID to cancelled
    * @param i_notes                  Cancel Notes
    * @param i_test                   Shows the confirmation message (Y / N)
    * @param o_flg_show               Shows the confirmation message (Y / N)
    * @param o_msg_title              Message title, if O_FLG_SHOW = Y
    * @param o_msg_text               Message text, if O_FLG_SHOW = Y
    * @param o_button                 Buttons to show: N - No, R - Read, C - Confirmed                            
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Jos?Silva
    * @version                        1.0   
    * @since                          16/04/2008
    **********************************************************************************************/
    FUNCTION cancel_epis_doc_delivery
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_id_epis_doc   IN epis_documentation.id_epis_documentation%TYPE,
        i_notes         IN VARCHAR2,
        i_test          IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Cancels a column or a single vital sign read in the delivery momitoring
    *
    * @param i_lang                  language id
    * @param i_patient               patient id
    * @param i_prof                  professional, software and institution ids
    * @param i_pat_pregnancy         pregnancy id
    * @param i_vs_read               single vital sign read ID
    * @param i_dt_read               column date of vital sign reads
    *         
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         27-05-2008
    ********************************************************************************************/
    FUNCTION cancel_delivery_biometric
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_vs_read       IN vital_sign_read.id_vital_sign_read%TYPE,
        i_dt_read       IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --    
    /********************************************************************************************
    * Gets the graph scales
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param o_graph_scales          all scales to display in the graphic
    * @param o_lines                 Static lines   
    * @param o_error                 Error message    
    *         
    * @return                        true or false on success or error
    *
    * @author                        Jos?Silva
    * @version                       1.0    
    * @since                         30-05-2008
    ********************************************************************************************/
    FUNCTION get_delivery_graph_scales
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_graph_scales OUT pk_types.cursor_type,
        o_lines        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Checks if the vs_read is from the fetus
    *
    * @param i_vs_read               vital sign read id
    *         
    * @return                        1 - if the vs_read is from the fetus; 0 - Otherwise
    *
    * @author                        Alexandre Santos
    * @version                       1.0    
    * @since                         01-10-2009
    ********************************************************************************************/
    FUNCTION check_vs_read_from_fetus(i_vs_read IN vital_sign_read.id_vital_sign_read%TYPE) RETURN NUMBER;

    /********************************************************************************************
    * Get the newborn list
    *
    * @param i_lang           language id
    * @param i_prof           professional, software and institution ids
    * @param i_episode        episode id
    * @param i_patient        patient id
    * @param i_discharge      discharge id
    * @param o_labels         label list
    * @param o_conditions     condition list
    * @param o_newborns       newborn list
    * @param o_newborns       error message
    *         
    * @return                 true or false on success or error                       
    *
    * @author                 Vanessa Barsottelli                       
    * @version                2.7.0
    * @since                  10.11.2016                         
    ********************************************************************************************/
    FUNCTION get_newborns
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_discharge  IN discharge.id_discharge%TYPE,
        o_labels     OUT pk_types.cursor_type,
        o_conditions OUT pk_types.cursor_type,
        o_newborns   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_delivery_value
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE DEFAULT NULL,
        i_pat_pregnancy    IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_child_number     IN epis_doc_delivery.child_number%TYPE,
        i_doc_area         IN doc_area.id_doc_area%TYPE,
        i_doc_template     IN doc_template.id_doc_template%TYPE DEFAULT NULL,
        i_doc_component    IN doc_component.id_doc_component%TYPE DEFAULT NULL,
        i_doc_int_name     IN documentation.internal_name%TYPE DEFAULT NULL,
        i_doc_element      IN doc_element.id_doc_element%TYPE DEFAULT NULL,
        i_mask             IN VARCHAR2 DEFAULT NULL,
        i_check_elemnt     IN VARCHAR2 DEFAULT 'N',
        i_element_int_name IN VARCHAR2 DEFAULT NULL,
        i_show_internal    IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION exists_birth_certificate
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_child_number  IN epis_doc_delivery.child_number%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_birth_certificate_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_child_number  IN epis_doc_delivery.child_number%TYPE,
        i_flg_edition   IN epis_documentation.flg_edition_type%TYPE DEFAULT 'N',
        i_data_show     IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_delivery_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_fetus_number  IN pat_pregn_fetus.fetus_number%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        i_doc_template  IN doc_template.id_doc_template%TYPE
    ) RETURN doc_element_crit.id_content%TYPE;

    FUNCTION is_place_of_birth_inst
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_birth_inst IN pat_birthplace.id_institution%TYPE
    ) RETURN VARCHAR2;

    FUNCTION verify_cancel_born_record
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN BOOLEAN;

    FUNCTION get_born_anomaly_acelrn
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_data_show IN VARCHAR2,
        i_text_show IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_born_anomaly_cve
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_data_show    IN VARCHAR2,
        i_text_show    IN VARCHAR2,
        i_text_na_show IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_cancelled_folios
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_child_number  IN epis_doc_delivery.child_number%TYPE,
        i_dt_cancel     IN epis_documentation.dt_cancel_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_doc_element_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_type          IN doc_element.flg_type%TYPE,
        i_value             IN epis_documentation_det.value%TYPE,
        i_id_content        IN doc_element_crit.id_content%TYPE,
        i_mask              IN VARCHAR2 DEFAULT NULL,
        i_doc_element       IN doc_element.id_doc_element%TYPE DEFAULT NULL,
        i_doc_comp_internal IN documentation.internal_name%TYPE DEFAULT NULL,
        i_doc_elem_internal IN doc_element.internal_name%TYPE DEFAULT NULL,
        i_show_internal     IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_death_folio_cert
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Get newborn gestation age
    *
    * @param i_lang            The language ID
    * @param i_prof            Object (professional ID, institution ID, software ID)
    * @param i_patient         Patient ID
    * @param o_ga_age          gestation age
    * @param o_error           Error message
    *
    * @return                  true or false on success or error
    *
    * @author                  Lillian Lu
    * @version                 2.7.2.6
    * @since                   2018-02-23
    **********************************************************************************************/
    FUNCTION get_newborn_delivery_weeks
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        o_ga_age  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_child_episode
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_child_number       IN epis_doc_delivery.child_number%TYPE,
        i_patient_child      IN patient.id_patient%TYPE,
        i_child_episode      IN episode.id_episode%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_dt_birth
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_type          IN VARCHAR2,
        i_child_number  IN epis_doc_delivery.child_number%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;
    /********************************************************************************************
    * Get patient delivery information
    *
    * @param i_lang             The language ID
    * @param i_prof             Object (professional ID, institution ID, software ID)
    * @param i_patient          Patient ID
    * @param o_info             cursor with all information
    * @param o_error            Error message
    *
    * @return                   true or false on success or error
    *
    * @author                   Elisabete Bugalho
    * @version                  2.7.4.0
    * @since                    2018-09-10
    **********************************************************************************************/
    FUNCTION get_patient_delivery_info
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN ;
    
        /********************************************************************************************
    *  if the vs_read is from the fetus returns te fetus number
    *
    * @param i_vs_read               vital sign read id
    *         
    * @return                        0 or fetus number
    *
    * @author                        Elisabete Bugalho
    * @version                       2.8.4.0   
    * @since                        29-09-2021
    ********************************************************************************************/

        FUNCTION get_id_fetus_from_vs_read(i_vs_read IN vital_sign_read.id_vital_sign_read%TYPE) RETURN NUMBER;
    --
    g_error VARCHAR2(4000);
    g_available CONSTANT VARCHAR2(1) := 'Y';
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_child_status_alive CONSTANT epis_doc_delivery.flg_child_status%TYPE := 'A';
    g_child_status_dead  CONSTANT epis_doc_delivery.flg_child_status%TYPE := 'D';
    g_child_status_err   CONSTANT epis_doc_delivery.flg_child_status%TYPE := 'E';
    g_type_graph         CONSTANT VARCHAR2(1) := 'G';
    g_type_table         CONSTANT VARCHAR2(1) := 'T';
    g_vs_rel_conc        CONSTANT vital_sign_relation.relation_domain%TYPE := 'C';
    g_vs_rel_graph       CONSTANT vital_sign_relation.relation_domain%TYPE := 'G';

    g_epis_cancel        CONSTANT episode.flg_status%TYPE := 'C';
    g_epis_bartchart_out CONSTANT epis_documentation.flg_status%TYPE := 'O';
    g_active             CONSTANT epis_documentation.flg_status%TYPE := 'A';
    g_vs_read_active     CONSTANT vital_sign_read.flg_state%TYPE := 'A';
    g_vs_avail           CONSTANT vital_sign.flg_available%TYPE := 'Y';
    g_yes                CONSTANT VARCHAR2(1) := 'Y';
    g_no                 CONSTANT VARCHAR2(1) := 'N';

    g_grapfic_scale_p CONSTANT graph_scale.flg_type%TYPE := 'P';
    g_grapfic_scale_d CONSTANT graph_scale.flg_type%TYPE := 'D';

    g_min_unit_measure   CONSTANT unit_measure.id_unit_measure%TYPE := 10374;
    g_hours_unit_measure CONSTANT unit_measure.id_unit_measure%TYPE := 1041;
    g_day_unit_measure   CONSTANT unit_measure.id_unit_measure%TYPE := 1039;
    g_week_unit_measure  CONSTANT unit_measure.id_unit_measure%TYPE := 10375;

    g_pregn_fetus_unk CONSTANT pat_pregn_fetus.flg_status%TYPE := 'U';
    g_pregn_fetus_a   CONSTANT pat_pregn_fetus.flg_status%TYPE := 'A';
    g_color_dci_p     CONSTANT dci_color.flg_type%TYPE := 'P';

    g_flg_ehr_n CONSTANT episode.flg_ehr%TYPE := 'N';

    g_type_dt_birth_s CONSTANT VARCHAR2(1) := 'S';
    g_type_dt_birth_e CONSTANT VARCHAR2(1) := 'E';

    g_pat_gender_m CONSTANT patient.gender%TYPE := 'M';
    g_pat_gender_f CONSTANT patient.gender%TYPE := 'F';

    g_intern_name_delivery CONSTANT time_event_group.intern_name%TYPE := 'DELIVERY_MONITORIZATION';
    g_intern_name_fetus    CONSTANT time_event_group.intern_name%TYPE := 'FETUS_MONITORIZATION';
    g_flg_view             CONSTANT vs_soft_inst.flg_view%TYPE := 'PT';
    g_view_delivery        CONSTANT vs_soft_inst.flg_view%TYPE := 'PG';

    g_exception EXCEPTION;

    g_int_name_pregn_num     CONSTANT doc_element.internal_name%TYPE := 'NUM_EMB';
    g_int_name_pregn_num_si  CONSTANT doc_element.internal_name%TYPE := 'SI_NUM_EMB';
    g_int_name_born_alive    CONSTANT doc_element.internal_name%TYPE := 'NAC_VIV';
    g_int_name_born_alive_si CONSTANT doc_element.internal_name%TYPE := 'SI_NAC_VIV';
    g_int_name_born_death    CONSTANT doc_element.internal_name%TYPE := 'NAC_MUE';
    g_int_name_born_death_si CONSTANT doc_element.internal_name%TYPE := 'SI_NAC_MUE';
    g_int_name_survivor      CONSTANT doc_element.internal_name%TYPE := 'SOBREVIV';
    g_int_name_survivor_si   CONSTANT doc_element.internal_name%TYPE := 'SI_SOBREVIV';
    --cond_nac
    g_int_name_prev_cond     CONSTANT doc_element.internal_name%TYPE := 'COND_NAC';
    g_int_name_prev_cond_viv CONSTANT doc_element.internal_name%TYPE := 'VIV';
    g_int_name_prev_cond_si  CONSTANT doc_element.internal_name%TYPE := 'SI_HIJ_ANT';
    g_int_name_prev_cond_no  CONSTANT doc_element.internal_name%TYPE := 'NO_HIJ_ANT';
    g_int_name_prev_cond_ne  CONSTANT doc_element.internal_name%TYPE := 'NE_HIJ_ANT';
    g_int_name_prev_cond_mue CONSTANT doc_element.internal_name%TYPE := 'MUE';
    --viv_aun
    g_int_name_prev_alive    CONSTANT documentation.internal_name%TYPE := 'VIV_AUN';
    g_int_name_prev_alive_y  CONSTANT documentation.internal_name%TYPE := 'S_VIV_AUN';
    g_int_name_prev_alive_n  CONSTANT documentation.internal_name%TYPE := 'N_VIV_AUN';
    g_int_name_prev_alive_si CONSTANT documentation.internal_name%TYPE := 'SI_VIV_AUN';
    g_int_name_prev_alive_ne CONSTANT documentation.internal_name%TYPE := 'NE_VIV_AUN';
    g_int_name_prev_date     CONSTANT doc_element.internal_name%TYPE := 'FECH_NHEA';

    -- newborn
    g_int_name_order_nasc    CONSTANT doc_element.internal_name%TYPE := 'Orden';
    g_int_name_order_nasc_si CONSTANT doc_element.internal_name%TYPE := 'orden_si';

    g_int_name_weight    CONSTANT doc_element.internal_name%TYPE := 'PESO';
    g_int_name_height    CONSTANT doc_element.internal_name%TYPE := 'TALLA';
    g_int_name_weight_si CONSTANT doc_element.internal_name%TYPE := 'SI_PESO';
    g_int_name_height_si CONSTANT doc_element.internal_name%TYPE := 'SI_TALLA';
    g_int_name_gender_f  CONSTANT doc_element.internal_name%TYPE := 'Sexo feminino';
    g_int_name_gender_m  CONSTANT doc_element.internal_name%TYPE := 'Sexo masculino';
    g_int_name_gender_si CONSTANT doc_element.internal_name%TYPE := 'Sexo indefinido';

    g_int_atention           CONSTANT documentation.internal_name%TYPE := 'PERSON_ATEND';
    g_int_name_aten_med      CONSTANT doc_element.internal_name%TYPE := 'medico';
    g_int_name_aten_resident CONSTANT doc_element.internal_name%TYPE := 'med_res';
    g_int_name_aten_general  CONSTANT doc_element.internal_name%TYPE := 'med_gen';
    g_int_name_aten_mpss     CONSTANT doc_element.internal_name%TYPE := 'MPSS';
    g_int_name_aten_gino     CONSTANT doc_element.internal_name%TYPE := 'med_go';
    g_int_name_aten_othspec  CONSTANT doc_element.internal_name%TYPE := 'med_o';
    g_int_name_aten_mip      CONSTANT doc_element.internal_name%TYPE := 'MIP';
    g_int_name_aten_nurse    CONSTANT doc_element.internal_name%TYPE := 'enf';
    g_int_name_aten_sec      CONSTANT doc_element.internal_name%TYPE := 'sec_saud';
    g_int_name_aten_midwife  CONSTANT doc_element.internal_name%TYPE := 'partera';
    g_int_name_aten_other    CONSTANT doc_element.internal_name%TYPE := 'Otro';
    g_int_name_aten_ne       CONSTANT doc_element.internal_name%TYPE := 'No especificado';
    g_int_name_atention      CONSTANT doc_element.internal_name%TYPE := 'O_PERSON_ATEND';
    ------- pregnancy initial data 
    --    Folio del certificado de defunción
    g_int_name_folio    CONSTANT doc_element.internal_name%TYPE := 'FOLIO_DEF';
    g_int_name_folio_si CONSTANT doc_element.internal_name%TYPE := 'SI_FOLIO_DEF';
    --La madre sobrevivi?al parto
    g_int_mother_survivor CONSTANT documentation.internal_name%TYPE := 'MADRE_SOBREVIV';
    g_int_mother_death    CONSTANT doc_element.internal_name%TYPE := 'N_MADRE_SOBREVIV';
    g_int_mother_alive    CONSTANT doc_element.internal_name%TYPE := 'S_MADRE_SOBREVIV';
    g_int_mother_si       CONSTANT doc_element.internal_name%TYPE := 'SI_MADRE_SOBREVIV';
    g_int_mother_ne       CONSTANT doc_element.internal_name%TYPE := 'NE_MADRE_SOBREVIV';

    --La madre recibi?atención prenatal
    g_int_prenatal_aten    CONSTANT documentation.internal_name%TYPE := 'ATEN_PREN';
    g_int_prenatal_aten_si CONSTANT doc_element.internal_name%TYPE := 'SI_ATEN_PREN';
    g_int_prenatal_aten_n  CONSTANT doc_element.internal_name%TYPE := 'N_ATEN_PREN';
    g_int_prenatal_aten_s  CONSTANT doc_element.internal_name%TYPE := 'S_ATEN_PREN';
    g_int_prenatal_aten_ne CONSTANT doc_element.internal_name%TYPE := 'NE_ATEN_PREN';
    --Total de consultas otorgadas durante el embarazo
    g_int_prenatal_total_cons CONSTANT doc_element.internal_name%TYPE := 'TOT_CONS_EMB';
    --Trimestre en el que la madre recibi?la primera consulta prenatal
    g_int_prenatal_trim    CONSTANT documentation.internal_name%TYPE := 'TRIM_ATEN_PREN';
    g_int_prenatal_trim_1  CONSTANT doc_element.internal_name%TYPE := '1_TRIM';
    g_int_prenatal_trim_2  CONSTANT doc_element.internal_name%TYPE := '2_TRIM';
    g_int_prenatal_trim_3  CONSTANT doc_element.internal_name%TYPE := '3_TRIM';
    g_int_prenatal_trim_si CONSTANT doc_element.internal_name%TYPE := 'SI_TRIM';
    g_int_prenatal_trim_ne CONSTANT doc_element.internal_name%TYPE := 'NE_TRIM';
    -- Tipo de nacimiente
    g_int_proc_type    CONSTANT documentation.internal_name%TYPE := 'PROC';
    g_int_proc_type_c  CONSTANT doc_element.internal_name%TYPE := 'proc_ces';
    g_int_proc_type_d  CONSTANT doc_element.internal_name%TYPE := 'proc_dist';
    g_int_proc_type_o  CONSTANT doc_element.internal_name%TYPE := 'proc_o';
    g_int_proc_type_ne CONSTANT doc_element.internal_name%TYPE := 'proc_ne';
    g_int_proc_type_e  CONSTANT doc_element.internal_name%TYPE := 'proc_eut';
    g_int_proc_desc    CONSTANT doc_element.internal_name%TYPE := 'DESC_PROC';
    --Father data
    g_int_father_name CONSTANT doc_element.internal_name%TYPE := 'REP_FatherName';

END pk_delivery;
/
