/*-- Last Change Revision: $Rev: 2028602 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_diagram_new IS

    /********************************************************************************************
    * Gets default diagram layout.
    * Default diagram layout can be obtained from EPIS_INFO, SCHEDULE, PROF_DEP_CLIN_SERV or SYS_CONFIG
    * depending on how the different softwares behave.
    *
    * @param i_lang                   The language id
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                The episode id
    * @param i_flg_type               Diagram layout type
    * @param o_diagram_layout         The default diagram layout id
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    * 
    * @author                         LG
    * @version                        0.1
    * @since                          2007/04/12
    **********************************************************************************************/
 
    FUNCTION get_default_lay
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN diagram_layout.flg_type%TYPE,
        o_diagram_layout OUT diagram_layout.id_diagram_layout%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *   
    *   Retrieves all the icons that will appear on the toolbar
    *   
    *  @param   I_LANG - the language id
    *  @param O_DIAG_TOOLS - cursor with the icons information
    *  @param   O_ERROR - error message
    *   
    * @author Emília Taborda
    * @ since 2006/09/06 
    *
    *********************************************************************************/

    FUNCTION get_diag_tools
    (
        i_lang            IN language.id_language%TYPE,
        i_flg_family_tree IN VARCHAR2,
        o_diag_tools      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
     * Gets a diagram layout image blob with its image.
     *
     * @param i_diagram_image          Diagram image id
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_img                    The image
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         LG
     * @version                        0.1
     * @since                          2007/04/12
    **********************************************************************************************/
    FUNCTION get_diag_lay_imag_blob
    (
        i_diagram_image IN diagram_image.id_diagram_image%TYPE,
        i_prof          IN profissional,
        o_img           OUT BLOB,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_diag_lay_imag_blob_rep
    (
        i_diagram_image IN diagram_image.id_diagram_image%TYPE,
        i_prof          IN profissional,
        o_img           OUT BLOB,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
     * Gets a diagram layout blob with his image.
     *
     * @param i_diagram_image          Diagram image id
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_img                    The image
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         LG
     * @version                        0.1
     * @since                          2007/04/12
    **********************************************************************************************/
    FUNCTION get_diag_lay_blob
    (
        i_diagram_layout IN diagram_layout.id_diagram_layout%TYPE,
        i_prof           IN profissional,
        o_img            OUT BLOB,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *
    * Returns all the notes associated with a diagram's details
    *    
    * @param                     I_LANG - language id
    * @param                     I_PROF - Object (professional ID, institution ID, software ID)
    * @param                     I_DIAGRAM  - diagram id
    * @param                    O_DIAG_DET- cursor containg the notes
    * @param                    O_ERROR - Erro 
    *  
    * @author  ET 
    *  @since 2006/09/05 
    *
    * 
    *********************************************************************************/

    FUNCTION get_diag_det_notes
    
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_diag  IN epis_diagram.id_epis_diagram%TYPE,
        o_diag_det OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
     * Returns info on all the diagrams within a episode ( used on the viewer)
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_epis                   Episode  ID
     * @param o_info                   cursor containg the info  
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         Rui Abreu
     * @since                          2007/04/12
    **********************************************************************************************/
    /* FUNCTION get_epis_diagram_all
    (
        i_lang  IN LANGUAGE.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
            o_diagram_all OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    */

    FUNCTION get_diag_epis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis            IN episode.id_episode%TYPE,
        i_filter          IN VARCHAR2,
        i_flg_family_tree IN VARCHAR2,
        o_info            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Returns info on all the diagrams within a episode ( used on the reports)
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_epis                   Episode  ID
     * @param i_filter                 R - Reports (don't show imagens without Symbols), Y / N - aplication
     * @param o_info                   cursor containg the info  
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         Rui Abreu
     * @since                          2007/04/12
    **********************************************************************************************/

    FUNCTION get_diag_epis_report
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_epis   IN episode.id_episode%TYPE,
        i_filter IN VARCHAR2,
        o_info   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get diagram layout fields for all figures in list of episodes
     *
     * @param i_lang                   The user language id
     * @param i_prof                   The Professional, software and institution executing the request
     * @param i_tbl_episode            Episodes array
     * @param o_diag_lay_desc          A cursor with the diagram layouts description fields
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         Nuno Alves
     * @version                        2.6.3.8.2
     * @since                          2015/05/06
     *
     * Notes:                          based on get_diag_lay_desc from author: LG
    **********************************************************************************************/
    FUNCTION get_epis_diag_lay_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_tbl_episode IN table_number,
        o_diag_layout OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get all images about all diagram layouts belonging to a diagram.
     * If the episode has no diagram the default diagram images are considered.
     * If episode has several diagrams and i_epis_diagram was not provided the last diagram is considered.
     * If i_epis_diagram is provided the i_episode is discarded.
     * i_epis_diagram or i_episode must be provided.
     *
     * @param i_lang                   The user language id
     * @param i_prof                   The professional context
     * @param i_episode                The episode id
     * @param i_epis_diagram           The episode diagram
     * @param i_report                 Flag that indicates if the function is called in the context of a report     
     * @param o_diag_lay_img           A cursor with the details about all images in all diagram layouts belonging to a diagram
     * @param o_diag_desc              A cursor with the diagram description fields
     * @param o_diag_lay_desc          A cursor with the diagram layouts description fields
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         LG
     * @version                        0.1
     * @since                          2007/04/12
    **********************************************************************************************/
    FUNCTION get_diag_lay_imag
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_diagram    IN epis_diagram.id_epis_diagram%TYPE,
        i_report          IN VARCHAR2,
        i_flg_family_tree IN VARCHAR2,
        o_diag_lay_img    OUT pk_types.cursor_type,
        o_diag_desc       OUT pk_types.cursor_type,
        o_diag_lay_desc   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    )
    
     RETURN BOOLEAN;

    /********************************************************************************************
     * Get all images about all diagram layouts belonging to a diagram.
     * If the episode has no diagram the default diagram images are considered.
     * If episode has several diagrams and i_epis_diagram was not provided the last diagram is considered.
     * If i_epis_diagram is provided the i_episode is discarded.
     * i_epis_diagram or i_episode must be provided.
     *
     * @param i_lang                   The user language id
     * @param i_prof                   The professional context
     * @param i_episode                The episode id
     * @param i_epis_diagram           The episode diagram
     * @param i_id_epis_diagram_layout Diagram layout ID
     * @param i_report                 Flag that indicates if the function is called in the context of a report
     * @param i_flg_tmp_diag           Flag that indicates that its a temporary diagram
     * @param i_flg_type               Diagram layout type
     * @param o_diag_lay_img           A cursor with the details about all images in all diagram layouts belonging to a diagram
     * @param o_diag_desc              A cursor with the diagram description fields
     * @param o_diag_lay_desc          A cursor with the diagram layouts description fields
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         LG
     * @version                        0.1
     * @since                          2007/04/12
    **********************************************************************************************/
    FUNCTION get_diag_lay_imag
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_epis_diagram           IN epis_diagram.id_epis_diagram%TYPE,
        i_id_epis_diagram_layout IN epis_diagram_layout.id_epis_diagram_layout%TYPE,
        i_report                 IN VARCHAR2,
        i_flg_tmp_diag           IN pk_types.t_flg_char,
        i_flg_type               IN diagram_layout.flg_type%TYPE,
        i_flg_family_tree        IN VARCHAR2,
        o_diag_lay_img           OUT pk_types.cursor_type,
        o_diag_desc              OUT pk_types.cursor_type,
        o_diag_lay_desc          OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    --

    --
    /********************************************************************************************
     * Creates a new DEFAULT diagram
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_epis                   Episode id
     * @param i_flg_type               Diagram layout type
     * @param o_diag_lay_img           A cursor with the details about all images in all diagram layouts belonging to a diagram
     * @param o_diag_desc              A cursor with the diagram description fields
     * @param o_diag_lay_desc          A cursor with the diagram layouts description fields
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         Rui Abreu
     * @since                          2007/04/11
    **********************************************************************************************/

    FUNCTION create_diag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_flg_type      IN diagram_layout.flg_type%TYPE,
        o_diag_lay_img  OUT pk_types.cursor_type,
        o_diag_desc     OUT pk_types.cursor_type,
        o_diag_lay_desc OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Get diagram layout image url with a diagram layout image url.
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_diagram_image          Diagram image id
    *
    * @return                         The diagram image url
    * 
    * @author                         LG
    * @version                        0.1
    * @since                          2007/04/12
    **********************************************************************************************/
    FUNCTION get_diag_lay_imag_image_url
    (
        i_prof          IN profissional,
        i_diagram_image IN diagram_image.id_diagram_image%TYPE
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
    * Get diagram layout url with a full diagram layout image url.
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_diagram_image          Diagram image id
    *
    * @return                         The diagram image url
    * 
    * @author                         LG
    * @version                        0.1
    * @since                          2007/04/18
    **********************************************************************************************/
    FUNCTION get_diag_lay_image_url
    (
        i_prof           IN profissional,
        i_diagram_layout IN diagram_layout.id_diagram_layout%TYPE
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
     * Returns the information on a particular diagram
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_diag                Diagram ID
     * @param i_id_diag_lay            Layout ID
     * @param o_diagram_layout         Cursor with information on the layout
     * @param o_title                  Cursor with the title
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         Rui Abreu
     * @since                          2007/04/12
    **********************************************************************************************/

    FUNCTION get_diag_lay_det
    
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_diag        IN epis_diagram.id_epis_diagram%TYPE,
        i_id_diag_lay    IN diagram_layout.id_diagram_layout%TYPE,
        o_diagram_layout OUT pk_types.cursor_type,
        o_title          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
        
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
     * Cancels a layout from a diagram
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_epis_diag_lay       Episode diagram layout id
     *    
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         Rui Abreu
     * @since                          2007/04/12
    **********************************************************************************************/

    FUNCTION cancel_diag_lay
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_diag_lay IN epis_diagram_layout.id_epis_diagram_layout%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_diagram_layout
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis_diagram_layout IN epis_diagram_layout.id_epis_diagram_layout%TYPE,
        i_cancel_reason       IN epis_diagram_layout.id_cancel_reason%TYPE,
        i_cancel_notes        IN epis_diagram_layout.notes_cancel%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancels details on a diagram
    * 
    *
    * @param i_lang                    The language id
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_epis                    Episode ID
    * @param i_id_diag                 Diagram id
    * @param i_id_layout               epis_diagram_layout id
    * @param i_id_diag_det             Array with the info being cancelled
    * @param i_notes_cancel            Array with the cancelation cancellation notes
    * @param o_error                   Error message
    *
    * @return                         true or false on success or error
    * 
    * @author                         Rui Abreu
    * @since                          2007/04/17
    **********************************************************************************************/

    FUNCTION cancel_diagram_symbol
    
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_epis_diagram        IN epis_diagram.id_epis_diagram%TYPE,
        i_epis_diagram_layout IN epis_diagram_layout.id_epis_diagram_layout%TYPE,
        i_epis_diagram_detail IN table_varchar,
        i_cancel_reason       IN epis_diagram_detail.id_cancel_reason%TYPE,
        i_notes_cancel        IN epis_diagram_detail.notes_cancel%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /* Records details for a set of layouts in a diagram
    *
    *        
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   Episode ID
    * @param i_id_diag                Diagram ID. Null when ONLY setting a default layout.
    * @param i_id_lay_type            Array with diagram_layout IDs. The ID may be NULL, when the i_id_layout is known
    * @param i_id_layout              Array with epis_diagram_layout IDs. The ID may be NULL. In this case, the id_lay_type must exist
    * @param i_id_imag                Array with diagram_lay_image ID                                                                                                                          
    * @param i_id_diag_det            Array with epis_diagram_detail ID. 
    *                                  The ID he ID may be NULL, which means we are inserting a new record on the layout.                                                                                                                                                                          
    * @param i_id_icon                Array with diagram_tools ID
    * @param i_val_icon               Array with the value of all icons
    * @param i_val_posx               Array with the X position of every icon
    * @param i_val_posy               Array with the Y position of every icon                                                                                                               
    * @param i_notes                  Array with the icons notes
    * @param i_coor_x                 Array with the X position of every dot
    * @param i_coor_y                 Array with the Y position of every dot
    * @param i_color                  Array with the color of pencil symbols (null if other symbol)
    *
    * @param o_error                  Error message
    * @param o_epis_diagram           
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    * 
    * @author                         ET 2006/09/08 
    * @Modified by                    Rui Abreu
    * @since                          2007/04/11
    **********************************************************************************************/
    FUNCTION set_diag_lay_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis                IN episode.id_episode%TYPE,
        i_id_diag             IN epis_diagram.id_epis_diagram%TYPE,
        i_id_lay_type         IN table_varchar,
        i_id_layout           IN table_varchar,
        i_id_imag             IN table_varchar,
        i_id_diag_det         IN table_varchar,
        i_id_icon             IN table_varchar,
        i_val_icon            IN table_varchar,
        i_val_posx            IN table_varchar,
        i_val_posy            IN table_varchar,
        i_notes               IN table_varchar,
        i_coor_x              IN table_varchar,
        i_coor_y              IN table_varchar,
        i_color               IN table_varchar,
        o_epis_diagram        OUT epis_diagram.id_epis_diagram%TYPE,
        o_epis_diagram_layout OUT epis_diagram_layout.id_epis_diagram_layout%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Records and/or deletes details for a set of layouts in a diagram
    *
    *        
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                   Episode ID
    * @param i_id_diag                Diagram ID. Null when ONLY setting a default layout.
    * @param i_flg_action             Array of actions to be performed for each element (A-Add, R-Remove)
    * @param i_id_lay_type            Array with diagram_layout IDs.
    * @param i_id_layout              Array with epis_diagram_layout IDs.
    * @param i_id_imag                Array with diagram_lay_image ID                                                                                                                          
    * @param i_id_diag_det            Array with epis_diagram_detail ID. 
    *                                  The ID he ID may be NULL, which means we are inserting a new record on the layout.                                                                                                                                                                          
    * @param i_id_icon                Array with diagram_tools ID
    * @param i_val_icon               Array with the value of all icons
    * @param i_val_posx               Array with the X position of every icon
    * @param i_val_posy               Array with the Y position of every icon                                                                                                               
    * @param i_notes                  Array with the icons notes and/or the cancelation notes
    * @param i_coor_x                 Array with the X position of every dot
    * @param i_coor_y                 Array with the Y position of every dot
    * @param i_color                  Array with the color of pencil symbols (null if other symbol)
    *
    * @param o_error                  Error message
    * @param o_epis_diagram           
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    * 
    **********************************************************************************************/

    FUNCTION set_diag_lay_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis                IN episode.id_episode%TYPE,
        i_id_diag             IN epis_diagram.id_epis_diagram%TYPE,
        i_flg_action          IN table_varchar,
        i_id_lay_type         IN table_varchar,
        i_id_layout           IN table_varchar,
        i_id_imag             IN table_varchar,
        i_id_diag_det         IN table_varchar,
        i_id_icon             IN table_varchar,
        i_val_icon            IN table_varchar,
        i_val_posx            IN table_varchar,
        i_val_posy            IN table_varchar,
        i_notes               IN table_varchar,
        i_coor_x              IN table_varchar,
        i_coor_y              IN table_varchar,
        i_color               IN table_varchar,
        o_epis_diagram        OUT epis_diagram.id_epis_diagram%TYPE,
        o_epis_diagram_layout OUT epis_diagram_layout.id_epis_diagram_layout%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*****************************************************************************************************************
     * Adds a layout to the diagram given by i_id_epis_diagram. If_ i_id_epis_diagram is null, a new diagram is created
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_epis                    Episode ID
     * @param i_id_epis_diagram         Diagram ID. Can be_ null
     * @param i_id_lay_type             Diagram Layout ID
     * @param o_id_epis_diagram         Diagram in which the insertion was made
     * @param o_id_epis_diagram_layout  epis_diagram_layout in which the insertion was made
     * @param o_figure_tag_plus_number  tag ( example : Figure 3)
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         Rui Abreu
     * @since                          2007/04/12
    **********************************************************************************************/
    FUNCTION add_diag_lay
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_epis                   IN episode.id_episode%TYPE,
        i_id_epis_diagram        IN epis_diagram.id_epis_diagram%TYPE,
        i_id_lay_type            IN diagram_layout.id_diagram_layout%TYPE,
        o_id_epis_diagram        OUT epis_diagram.id_epis_diagram%TYPE,
        o_id_epis_diagram_layout OUT epis_diagram_layout.id_epis_diagram_layout%TYPE,
        o_figure_tag_plus_number OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /********************************************************************************************
    * Get most frequent diagram layouts.
    * Default diagram layouts take in consideration dep_clin_serv defined at prof_dep_clin_serv.
    *
    * @param i_lang                   The language id
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                The patient id
    * @param i_id_episode             Episode id
    * @param i_flg_type               Diagram layout type
    * @param o_diag_lay_img           A cursor with the details about all images in all diagram layouts belonging to a diagram
    * @param o_diag_lay_desc          A cursor with the diagram layouts description fields
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    * 
    * @author                         LG
    * @version                        0.1
    * @since                          2007/04/16
    **********************************************************************************************/
    FUNCTION get_most_freq_diag_lay_imag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_flg_type      IN diagram_layout.flg_type%TYPE,
        o_diag_lay_img  OUT pk_types.cursor_type,
        o_diag_lay_desc OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a diagrams data
    * 
    *
    * @param i_lang                       The language id
    * @param i_prof                       Object (professional ID, institution ID, software ID)
    * @param i_id_diag                    Diagram ID         
    * @param o_title_diag                Cursor with he diagram title
    * @param o_diagram                   Cursor with the data
    * @param o_error                      Error message
    *
    * @return                         true or false on success or error
    * 
    * @author                         Rui Abreu
    * @since                          2007/04/17
    **********************************************************************************************/
    FUNCTION get_diag_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_diag    IN epis_diagram.id_epis_diagram%TYPE,
        i_epis       IN episode.id_episode%TYPE,
        o_title_diag OUT pk_types.cursor_type,
        o_diagram    OUT pk_types.cursor_type,
        o_tblx       OUT table_varchar,
        o_tbly       OUT table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a diagrams data
    * 
    *
    * @param i_lang                       The language id
    * @param i_prof                       Object (professional ID, institution ID, software ID)
    * @param i_id_diag                    Diagram ID
    * @param i_id_epis_diagram_layout     Diagram layout ID
    * @param i_epis                       Episode ID
    * @param i_flg_type                   Diagram layout type
    * @param o_title_diag                 Cursor with he diagram title
    * @param o_diagram                    Cursor with the data
    * @param o_error                      Error message
    *
    * @return                         true or false on success or error
    * 
    * @author                         Rui Abreu
    * @since                          2007/04/17
    **********************************************************************************************/
    FUNCTION get_diag_det
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_diag                IN epis_diagram.id_epis_diagram%TYPE,
        i_id_epis_diagram_layout IN epis_diagram_layout.id_epis_diagram_layout%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_flg_type               IN diagram_layout.flg_type%TYPE,
        o_title_diag             OUT pk_types.cursor_type,
        o_diagram                OUT pk_types.cursor_type,
        o_tblx                   OUT table_varchar,
        o_tbly                   OUT table_varchar,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Get all diagram layouts available to the software, institution executing the request.
    *
    * @param i_lang                   The language id
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                The patient id
    * @param i_flg_type               Diagram layout type
    * @param o_diag_lay_img           A cursor with the details about all images in all diagram layouts
    * @param o_diag_lay_desc          A cursor with the diagram layouts description fields
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    * 
    * @author                         LG
    * @version                        0.1
    * @since                          2007/04/18
    **********************************************************************************************/
    FUNCTION get_all_diag_lay_imag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_flg_type      IN diagram_layout.flg_type%TYPE,
        o_diag_lay_img  OUT pk_types.cursor_type,
        o_diag_lay_desc OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the history of all the modifications ever made to a diagram
    *
    * @param i_lang                   The language id
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_diag                The diagram ID
    * @param o_symbols                A cursor with all the symbols in the diagram
    * @param o_recent_notes           A cursor with the details most recent notes
    * @param o_old_notes              A cursor with all the outdated notes
    * @param o_cancelled              this cursor is only filled if_ the detail is cancelled
    * @param o_figures                A cursor with all the name of the figures in the diagram ( example : Figure 3)
    * @param o_figures_data           A cursor with the figures creation date and name of the professional that created it
    * @param o_figures_data_cancelled   A cursor with the figures creation date and name of the professional that created it + cancellation date and
    *                                    name of the professional that cancelled it
    * @param o_error                  Error message
    * @return                         true or false on success or error
    * 
    * @author                         Rui Abreu
    * @since                          2007/04/18
    **********************************************************************************************/

    FUNCTION get_diag_det_notes_hist
    
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_diag                IN epis_diagram.id_epis_diagram%TYPE,
        o_symbols                OUT table_varchar,
        o_recent_notes           OUT table_varchar,
        o_old_notes              OUT table_varchar,
        o_cancelled              OUT table_varchar,
        o_figures                OUT table_varchar,
        o_figures_data           OUT table_varchar,
        o_figures_data_cancelled OUT table_varchar,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Allows a tree-like navigation to choose one from the available figures
    *
    * @param i_lang                   The language id
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                The patient'sID
    * @param i_layer_values           An array with all the selected items so far
    * @param i_layer_concept          An array with the selected layers so far
    * @param i_flg_type               Diagram layout type
    * @param o_final_layer            1 if the layer is final, 0 otherwise
    *                                      
    * @param o_layers                 Available options to the present selection
    * @param o_layer_name             Layer name corresponding to the present selection
    * @param o_layer_concept          Layer ID correspondig to the present selection
    * @param o_error                  Error message                  
    * @return                         true or false on success or error
    * 
    * @author                         Rui Abreu
    * @since                          2007/05/24
    **********************************************************************************************/

    FUNCTION get_all_available_figures
    
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_layer_values  IN table_varchar,
        i_layer_concept IN table_varchar,
        i_flg_type      IN diagram_layout.flg_type%TYPE,
        o_final_layer   OUT NUMBER,
        o_layers        OUT pk_types.cursor_type,
        o_layer_name    OUT VARCHAR2,
        o_layer_concept OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diag_epis_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_first_run IN VARCHAR2,
        o_info      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
        
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Returns info on all the diagrams of a patient for documents arquive
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_patient                Patient identifier
     * @param o_info                   cursor containg the info  
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
    **********************************************************************************************/
    FUNCTION get_all_pat_diag_doc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Returns the number of diagrams for a given patient
     *
     * @param i_patient                Patient identifier
     *
     * @return                         the Diagram number
    **********************************************************************************************/
    FUNCTION get_pat_num_diagrams(i_patient IN patient.id_patient%TYPE) RETURN NUMBER;

    /*********************************************************************************************
    * Return the structure for the body diagrams grid in the viewer
    *
    * @param   i_lang             IN    language.id_language%TYPE   language id
    * @param   i_prof             IN    profissional                professional type structure
    * @param   i_id_episode       IN    episode.id_episode%TYPE     episode id
    * @param   i_id_patient       IN    patient.id_patient%TYPE     patient id
    * @param   o_diagram_labels   OUT   pk_types.cursor_type        labels cursor
    * @param   o_diagrams_data    OUT   pk_types.cursor_type        diagrams data
    * @param   o_diag_details     OUT   pk_types.cursor_type        diagrams details data
    * @param   o_error            OUT   t_error_out
    *
    * @return  BOOLEAN   TRUE if succeeds, FALSE otherwise
    *
    * @author  rui.mendonca
    * @version 2.7.2.0
    * @since   28/10/2017
    *********************************************************************************************/
    FUNCTION get_pat_diag_grid
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        o_diagram_labels OUT pk_types.cursor_type,
        o_diagrams_data  OUT pk_types.cursor_type,
        o_diag_details   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    * Get the body diagram's actions in single page context
    *
    * @param   i_lang             IN    language.id_language%TYPE            language id
    * @param   i_prof             IN    profissional                         professional type structure
    * @param   i_id_epis_diagram  IN    epis_diagram.id_epis_diagram%TYPE    diagram id
    * @param   o_diag_details     OUT   pk_types.cursor_type                 actions available for a body diagram
    * @param   o_error            OUT   t_error_out
    *
    * @return  BOOLEAN   TRUE if succeeds, FALSE otherwise
    *
    * @author  rui.mendonca
    * @version 2.7.2.0
    * @since   06/11/2017
    ****************************************************************************************************************/
    FUNCTION get_epis_diagram_actions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_diagram IN epis_diagram.id_epis_diagram%TYPE,
        o_actions         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*FUNCTION set_cancel_epis_diagram
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_diagram IN epis_diagram.id_epis_diagram%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;*/

    /*********************************************************************************************
    * Update the last update date of the epis_diagram table to current_timestamp
    *
    * @param   i_lang             IN    language.id_language%TYPE            language id
    * @param   i_prof             IN    profissional                         professional type structure
    * @param   i_id_epis_diagram  IN    epis_diagram.id_epis_diagram%TYPE    diagram id    
    * @param   o_error            OUT   t_error_out
    *
    * @return  BOOLEAN   TRUE if succeeds, FALSE otherwise
    *
    * @author  rui.mendonca
    * @version 2.7.2.0
    * @since   07/11/2017
    *********************************************************************************************/
    FUNCTION upd_epis_diag_dt_last_update
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_diagram IN epis_diagram.id_epis_diagram%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION is_family_tree(i_id_epis_diagram IN NUMBER) RETURN VARCHAR2;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_exception  EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

    g_action_body_diag_subject CONSTANT pk_types.t_low_char := 'BODY_DIAGRAMS';

    g_structure_id NUMBER;
    g_body_part_id NUMBER;
    g_side_id      NUMBER;
    g_layer_id     NUMBER;
    g_system_id    NUMBER;
    g_organ_id     NUMBER;

    g_epis_active episode.flg_status%TYPE;
    g_epis_cancel episode.flg_status%TYPE;

    g_diag_open        epis_diagram.flg_status%TYPE;
    g_diag_lay_avail   diagram_layout.flg_available%TYPE;
    g_diag_imag_avail  diagram_image.flg_available%TYPE;
    g_diag_tools_avail diagram_tools_group.flg_available%TYPE;
    g_flg_status_det_a epis_diagram_detail.flg_status%TYPE;
    g_flg_status_det_c epis_diagram_detail.flg_status%TYPE;

    --Diagram Layout states
    g_diag_lay_removed   CONSTANT epis_diagram_layout.flg_status%TYPE := 'D';
    g_diag_lay_cancelled CONSTANT epis_diagram_layout.flg_status%TYPE := 'C';

    g_flg_type_e VARCHAR2(1);
    g_flg_type_n VARCHAR2(1);

    g_gender_domain sys_domain.code_domain%TYPE;

    g_diagram_single_image_url sys_config.value%TYPE;
    g_diagram_full_image_url   sys_config.value%TYPE;

    g_flg_status_active epis_diagram_layout.flg_status%TYPE;
    g_flg_status_open   epis_diagram.flg_status%TYPE;
    g_flg_status_close  epis_diagram.flg_status%TYPE;

    g_epis_diag_lay_flg_status_dmn sys_domain.code_domain%TYPE;

    g_flg_type_most_freq  diag_lay_dep_clin_serv.flg_type%TYPE;
    g_flg_type_searchable diag_lay_dep_clin_serv.flg_type%TYPE;
    g_flg_type_default    diag_lay_dep_clin_serv.flg_type%TYPE;

    g_url_image sys_config.value%TYPE;

    g_url_layout sys_config.value%TYPE;

    g_bd_ti_log CONSTANT VARCHAR(2) := 'BD';

    -- Diagram layout types
    g_flg_type_neur_assessm CONSTANT diagram_layout.flg_type%TYPE := 'N';
    g_flg_type_drainage     CONSTANT diagram_layout.flg_type%TYPE := 'D';
    g_flg_type_others       CONSTANT diagram_layout.flg_type%TYPE := 'O';

END pk_diagram_new;
/
