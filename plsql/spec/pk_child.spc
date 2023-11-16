/*-- Last Change Revision: $Rev: 2028560 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:31 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_child IS
    /***
    * get ped_area_soft_inst.rank rank
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_ped_area_add        ped area add identifier
    * @param i_market                 market identifier
    *
    * @return  ped_area_soft_inst.rank
    *
    * @author   Paulo Teixeira
    * @version  2.5.1.5
    * @since    2011/06/02
    */
    FUNCTION get_pasi_rank
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_ped_area_add IN ped_area_add.id_ped_area_add%TYPE,
        i_market          IN market.id_market%TYPE
    ) RETURN NUMBER;
    /***
    * Checks if a ped_area_add is available
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_ped_area_add        ped area add identifier
    * @param i_market                 market identifier
    *
    * @return  'Y' is available, 'N' otherwise
    *
    * @author   Paulo Teixeira
    * @version  2.5.1.5
    * @since    2011/06/02
    */
    FUNCTION is_pasi_available
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_ped_area_add IN ped_area_add.id_ped_area_add%TYPE,
        i_market          IN market.id_market%TYPE
    ) RETURN VARCHAR2;
    /***
    * get child_feed_dev_inst_soft.rank rank
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_child_feed_dev      child feed dev identifier
    * @param i_market                 market identifier
    *
    * @return  child_feed_dev_inst_soft.rank
    *
    * @author   Paulo Teixeira
    * @version  2.5.1.5
    * @since    2011/06/02
    */
    FUNCTION get_cfd_rank
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_child_feed_dev IN child_feed_dev.id_child_feed_dev%TYPE,
        i_market            IN market.id_market%TYPE
    ) RETURN NUMBER;
    /***
    * Checks if a child_feed_dev is available
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_child_feed_dev      child feed dev identifier
    * @param i_market                 market identifier
    *
    * @return  'Y' is available, 'N' otherwise
    *
    * @author   Paulo Teixeira
    * @version  2.5.1.5
    * @since    2011/06/02
    */

    FUNCTION is_cfd_available
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_child_feed_dev IN child_feed_dev.id_child_feed_dev%TYPE,
        i_market            IN market.id_market%TYPE
    ) RETURN VARCHAR2;
    /**************************************************************************
    * Obtains the patient age
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_patient             patient identifier
    * @param o_gender                 patient gender
    * @param o_year_age               patient age in years
    * @param o_month_age              patient age in months
    * @param o_week_age               patient age in weeks
    * @param o_day_age                patient age in days
    * @param o_error                  error out
    *
    * @return                         true if succeed
    *
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/27
    **************************************************************************/
    FUNCTION get_pat_age
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_gender     OUT patient.gender%TYPE,
        o_year_age   OUT NUMBER,
        o_month_age  OUT NUMBER,
        o_week_age   OUT NUMBER,
        o_day_age    OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * get_sys_shortcut
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_button          sys_button.id_sys_button%TYPE,
    * @param i_id_sys_button_prop     sys_button_prop.id_sys_button_prop%TYPE
    *
    * @return                         id_sys_shortcut
    *
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/07/1
    **********************************************************************************************/
    FUNCTION get_sys_shortcut
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sys_button      IN sys_button.id_sys_button%TYPE,
        i_id_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN NUMBER;
    /**********************************************************************************************
    * Obter detalhe dos alimentos do primeiro ano de um paciente
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_button_prop     sys_button_prop.id_sys_button_prop%TYPE
    * @param o_areas                  ped areas
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/04/27
    **********************************************************************************************/
    FUNCTION get_ped_areas
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        o_areas              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Obter detalhe dos alimentos do primeiro ano de um paciente
        *
        * @param i_lang                   the id language
        * @param i_prof                   professional, software and institution ids
        * @param i_id_patient             id do patient
    * @param i_id_summary_page        summary page identifier
    * @param o_id_doc_template        default ud_doc_template
    * @param o_templates              add button templates
        * @param o_error                  Error message
        *
        * @return                         TRUE if sucess, FALSE otherwise
        *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/04/27
    **********************************************************************************************/
    FUNCTION get_ped_areas_templates
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_summary_page IN ped_area.id_summary_page%TYPE,
        o_id_doc_template OUT ped_area_add.id_doc_template%TYPE,
        o_templates       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * pediatric assessment insert
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_info                   id_alimento/idade em que se verifica
    * @param i_id_episode             id_episode
    * @param i_sys_date               sysdate
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/25
    **********************************************************************************************/
    FUNCTION set_child_info_nc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_info       IN table_table_varchar,
        i_id_episode IN episode.id_episode%TYPE,
        i_sys_date   IN pat_child_feed_dev.dt_pat_child_feed_dev%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * pediatric assessment insert
        *
        * @param i_lang                   the id language
        * @param i_prof                   professional, software and institution ids
        * @param i_id_patient             id do patient
    * @param i_info                   id_alimento/idade em que se verifica
    * @param i_flg_type                   type of content
    * @param i_id_episode                id_episode
        * @param o_error                  Error message
        *
        * @return                         TRUE if sucess, FALSE otherwise
        *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/25
    **********************************************************************************************/
    FUNCTION set_child_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_info       IN table_table_varchar,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * pediatric assessment insert
        *
        * @param i_lang                   the id language
        * @param i_prof                   professional, software and institution ids
        * @param i_id_patient             id do patient
    * @param i_info                   id_alimento/idade em que se verifica
    * @param i_id_episode             id_episode
    * @param i_sys_date               sysdate
        * @param o_error                  Error message
        *
        * @return                         TRUE if sucess, FALSE otherwise
        *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/25
    **********************************************************************************************/
    FUNCTION set_child_info_hist_nc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_info       IN table_table_varchar,
        i_id_episode IN episode.id_episode%TYPE,
        i_sys_date   IN pat_child_feed_dev.dt_pat_child_feed_dev%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * concatenação das milestones
        *
        * @param i_lang                   the id language
        * @param i_prof                   professional, software and institution ids
        * @param i_id_patient             id do patient
        * @param i_child_age              idade do paciente
        * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)
        * @param i_flg_status             status
    * @param i_market                 market identifier
    * @param i_dt                     record date
        *
        * @return                         Varchar2
        *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION concat_content
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_child_feed_dev.id_patient%TYPE,
        i_child_age  IN pat_child_feed_dev.child_age%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_flg_status IN pat_child_feed_dev.flg_status%TYPE,
        i_market     IN market.id_market%TYPE,
        i_dt         IN pat_child_feed_dev.dt_pat_child_feed_dev%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Obter detalhe
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)
    * @param o_det                    Cursor com o detalhe para um paciente
    * @param o_hist                    Cursor com o detalhe para um paciente
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION get_child_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        o_det        OUT pk_types.cursor_type,
        o_hist       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Obter detalhe
        *
        * @param i_lang                   the id language
        * @param i_prof                   professional, software and institution ids
        * @param i_id_patient             id do patient
    * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)
    * @param i_id_episode             episode id
        * @param o_det                    Cursor com o detalhe para um paciente
    * @param o_hist                    Cursor com o detalhe para um paciente
        * @param o_error                  Error message
        *
        * @return                         TRUE if sucess, FALSE otherwise
        *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION get_child_det_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_report     IN VARCHAR2,
        o_det        OUT pk_types.cursor_type,
        o_hist       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Obter detalhe
        *
        * @param i_lang                   the id language
        * @param i_prof                   professional, software and institution ids
        * @param i_id_patient             id do patient
    * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)
    * @param o_det                    Cursor com o detalhe para um paciente
        * @param o_error                  Error message
        *
        * @return                         TRUE if sucess, FALSE otherwise
        *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION get_child_det_summary
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        o_det        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Obter detalhe
        *
        * @param i_lang                   the id language
        * @param i_prof                   professional, software and institution ids
        * @param i_id_patient             id do patient
    * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)
    * @param i_report                 report orientation flag
    * @param i_episode                episode list
    * @param i_market                 market id
    * @param o_det                    Cursor com o detalhe para um paciente
        * @param o_error                  Error message
        *
        * @return                         TRUE if sucess, FALSE otherwise
        *                        
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION get_child_det_summary_aux
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_report     IN VARCHAR2,
        i_episode    IN table_number,
        i_market     IN market.id_market%TYPE,
        o_det        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * get_child_det_hist
    *
        * @param i_lang                   the id language
        * @param i_prof                   professional, software and institution ids
        * @param i_id_patient             id do patient
    * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)
    * @param i_market                 market identifier
    * @param i_dt                     record date
    * @param i_id_episode             episode id
    *
    * @return                         table_varchar
    *
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION get_child_det_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_child_feed_dev.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_market     IN market.id_market%TYPE,
        i_dt         IN pat_child_feed_dev_hist.dt_pat_child_feed_dev%TYPE,
        i_id_episode IN table_number,
        i_report     IN VARCHAR2
    ) RETURN table_varchar;
    /**********************************************************************************************
    * concatenação das milestones
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_child_age              idade do paciente
    * @param i_flg_type               Tipo de registo (Alimentos ou desenvolvimento)
        * @param i_flg_status             status
    * @param i_market                 market identifier
    * @param i_dt                     record date
    *
    * @return                         Varchar2
    *
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/26
    **********************************************************************************************/
    FUNCTION concat_content_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN pat_child_feed_dev.id_patient%TYPE,
        i_child_age  IN pat_child_feed_dev.child_age%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_flg_status IN pat_child_feed_dev.flg_status%TYPE,
        i_market     IN market.id_market%TYPE,
        i_dt         IN pat_child_feed_dev.dt_pat_child_feed_dev%TYPE
    ) RETURN VARCHAR2;
    /**********************************************************************************************
    * grid function
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id do patient
    * @param i_flg_type               pediatric assessment type
    * @param i_id_episode             episode id
    * @param o_content                content cursor
    * @param o_grid                   grid cursor
        * @param o_error                  Error message
        *
        * @return                         TRUE if sucess, FALSE otherwise
        *                        
    * @author                         Paulo teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/27
    **********************************************************************************************/
    FUNCTION get_child_grid_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_report     IN VARCHAR2,
        o_content    OUT pk_types.cursor_type,
        o_grid       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * grid function
        *
        * @param i_lang                   the id language
        * @param i_prof                   professional, software and institution ids
        * @param i_id_patient             id do patient
    * @param i_flg_type               pediatric assessment type
    * @param o_content                content cursor
    * @param o_grid                   grid cursor
        * @param o_error                  Error message
        *
        * @return                         TRUE if sucess, FALSE otherwise
        *                        
    * @author                         Paulo teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/27
    **********************************************************************************************/
    FUNCTION get_child_grid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        o_content    OUT pk_types.cursor_type,
        o_grid       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /**************************************************************************
    * validate input data
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_patient             id do patient
    * @param i_info                   data to validate
    * @param i_flg_type               pediatric assessment type
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Paulo Teixeira
    * @version                        2.5.1.5
    * @since                          2011/05/27
    **************************************************************************/
    FUNCTION validate_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_info       IN table_table_varchar,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a set of records done in a touch-option area based on scope criteria and with paging support
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Documentation area ID
    * @param   i_current_episode    Current episode ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_paging             Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param   i_start_record       First record. Just considered when paging is used. Default 1
    * @param   i_num_records        Number of records to be retrieved. Just considered when paging is used.  Default 2000
    * @param   o_doc_area_register  Cursor containing information about registers (professional, record date, status, etc.)
    * @param   o_doc_area_val       Cursor containing information about data values saved in registers
    * @param   o_template_layouts   Cursor containing the layout for each template used
    * @param   o_doc_area_component Cursor containing the components for each template used 
    * @param   o_doc_template_order order by id_doc_template rank defined on ped_area_add
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param   o_error              Error message
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   11/16/2010
    */
    FUNCTION get_doc_area_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_current_episode    IN episode.id_episode%TYPE,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        o_doc_area_register  OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_doc_template_order OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * get_doc_template_order
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_doc_template_order                   grid cursor
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Paulo teixeira
    * @version                        2.5.1.5 
    * @since                          2011/05/27
    **********************************************************************************************/
    FUNCTION get_doc_template_order
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_template_order OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Get child development/nutrition description by id record
    *
    * Get concated child development/nutrition description by id patientand flg_type
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             id patient
    * @param i_flg_type               Flg type -'P' - development , 'A' - nutrition
    * @param o_desc                   CLOB with the detail about patient dev/nutr
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Anna Kurowska
    * @version                        2.6.3  
    **********************************************************************************************/
    FUNCTION get_child_det_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN child_feed_dev.flg_type%TYPE,
        o_desc       OUT CLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /***
    * Checks if a template is available for the given patient
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_patient             Patient Id
    * @param i_doc_area               Documentation area ID
    * @param i_doc_template           Documentation template ID    
    *
    * @return  'Y' is available, 'N' otherwise
    */    
    FUNCTION is_template_available
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE
    ) RETURN VARCHAR2;

    ---------------------------------------------------------------------
    g_exception EXCEPTION;
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_error         VARCHAR2(4000 CHAR); -- Localização do erro
    g_package_owner VARCHAR2(32 CHAR);
    g_package_name  VARCHAR2(32 CHAR);
    g_found         BOOLEAN;

    g_food      child_feed_dev.flg_type%TYPE := 'A';
    g_dev       child_feed_dev.flg_type%TYPE := 'P';
    g_active    pat_child_feed_dev.flg_status%TYPE := 'A';
    g_cancelled pat_child_feed_dev.flg_status%TYPE := 'C';
    g_verified  pat_child_feed_dev.flg_status%TYPE := 'V';
    g_available ped_area_soft_inst.flg_available%TYPE := 'Y';
    g_year       CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_month      CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_week       CONSTANT VARCHAR2(1 CHAR) := 'W';
    g_day        CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_colon      CONSTANT VARCHAR2(1 CHAR) := ':';
    g_semicolon  CONSTANT VARCHAR2(1 CHAR) := ';';
    g_comma      CONSTANT VARCHAR2(1 CHAR) := ',';
    g_space      CONSTANT VARCHAR2(1 CHAR) := ' ';
    g_open       CONSTANT VARCHAR2(1 CHAR) := '(';
    g_close      CONSTANT VARCHAR2(1 CHAR) := ')';
    g_dot        CONSTANT VARCHAR2(1 CHAR) := '.';
    g_new_line   CONSTANT VARCHAR2(2 CHAR) := chr(10);
    g_tag_bold   CONSTANT VARCHAR2(1 CHAR) := 'B';
    g_tag_normal CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_tag_cancel CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_report_p   CONSTANT VARCHAR2(1) := 'P';
    g_report_v   CONSTANT VARCHAR2(1) := 'V';
    g_report_e   CONSTANT VARCHAR2(1) := 'E';
    g_id_um_year   unit_measure.internal_name%TYPE := 'Year(s)';
    g_id_um_day    unit_measure.internal_name%TYPE := 'Day(s)';
    g_id_um_day2   unit_measure.internal_name%TYPE := 'Dia';
    g_id_um_month  unit_measure.internal_name%TYPE := 'Month(s)';
    g_id_um_month2 unit_measure.internal_name%TYPE := 'Mês';
    g_id_um_week   unit_measure.internal_name%TYPE := 'Week(s)';
    g_id_um_week2  unit_measure.internal_name%TYPE := 'Semana';
END pk_child;
/
