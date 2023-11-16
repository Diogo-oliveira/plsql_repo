/*-- Last Change Revision: $Rev: 1920261 $*/
/*-- Last Change by: $Author: luis.fernandes $*/
/*-- Date of last change: $Date: 2019-10-11 15:45:30 +0100 (sex, 11 out 2019) $*/

CREATE OR REPLACE PACKAGE pk_apex_template_context IS

    /********************************************************************************************
    * Checks if there is a null value in collection 
    *
    * @param i_table                Collection
    *
    * @result                      1 if true, 0 if false
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/

    FUNCTION is_null_in_collection(i_table IN table_number) RETURN NUMBER;
    /********************************************************************************************
    * Get doc_template_context contexts based on flag type 
    *
    * @param i_flg_type           Flag type
    * @param i_dep_clin_serv      Dep_clin_servs
    * @param i_complaint          Complaints
    * @param i_doc_area           Doc_areas
    * @param i_exam               Exams
    * @param i_intervention       Interventions
    * @param i_rehab              Rehabs
    * @param i_sp                 Surgical procedures
    * @param o_context            Return for id_context
    * @param o_context_2          Return for id_context 2
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/

    PROCEDURE get_dtc_contexts
    (
        i_flg_type      IN doc_template_context.flg_type%TYPE,
        i_dep_clin_serv IN VARCHAR2,
        i_complaint     IN VARCHAR2,
        i_doc_area      IN VARCHAR2,
        i_exam          IN VARCHAR2,
        i_intervention  IN VARCHAR2,
        i_rehab         IN VARCHAR2,
        i_sp            IN VARCHAR2,
        o_context       OUT VARCHAR2,
        o_context_2     OUT VARCHAR2
    );

    /********************************************************************************************
    * Get doc_template_context ids for given filters
    *
    * @param i_institution              Institution id
    * @param i_softwares                Softwares id array
    * @param i_profile_templates        Profile templates array
    * @param i_doc_templates            Doc templates array
    * @param i_dep_clin_serv            Dep clin serv array
    * @param i_flg_type                 Flag type
    * @param i_context1                 id_context 1
    * @param i_context2                 id_context 2
    
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/

    FUNCTION get_dtc_ids
    (
        i_institution       IN institution.id_institution%TYPE,
        i_softwares         IN table_number,
        i_profile_templates IN table_number,
        i_doc_templates     IN table_number,
        i_dep_clin_serv     IN table_number,
        i_flg_type          IN doc_template_context.flg_type%TYPE,
        i_context1          IN table_number,
        i_context2          IN table_number
    ) RETURN table_number;

    /********************************************************************************************
    * Clones doc_template_context records from a facility to another,
    * allowing software specification
    * The origin and destination facility can be the same (to clone configurations from a software to another) 
    *
    * @param i_lang                Log Language ID
    * @param i_destination_inst    Destination facility
    * @param i_destination_soft    Destination software
    * @param i_dtc                 Doc template context id array
    * @param o_error               Error output   
    *
    * @result                      true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION clone_dtc_to_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_destination_inst IN institution.id_institution%TYPE,
        i_destination_soft IN software.id_software%TYPE,
        i_dtc              IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert multiple records in doc_template_context using selected filters
    *
    * @param i_lang              Language id
    * @param i_id_doc_template   Doc templates
    * @param i_id_institution    id_institution
    * @param i_id_software       Softwares
    * @param i_id_profile        Profile templates
    * @param i_id_context        id_contexts 
    * @param i_id_dep_clin_serv  id_dep_clin_servs
    * @param i_flg_type          Flag type 
    * @param i_sch_event         Sch_event
    * @param i_id_context_2      Id contexts 2
    * @param o_error             Error output
    *
    * @result                      true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION set_template_context
    (
        i_lang             IN language.id_language%TYPE,
        i_id_doc_template  VARCHAR2,
        i_id_institution   VARCHAR2,
        i_id_software      VARCHAR2,
        i_id_profile       VARCHAR2 DEFAULT NULL,
        i_id_context       VARCHAR2,
        i_id_dep_clin_serv VARCHAR2 DEFAULT NULL,
        i_flg_type         VARCHAR2,
        i_sch_event        VARCHAR2 DEFAULT NULL,
        i_id_context_2     VARCHAR2 DEFAULT NULL,
        o_error            OUT t_error_out
        
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Delete doc_template_context records
    *
    * @param i_lang              Language id
    * @param id_dtc_array        Doc template context id array
    * @param o_error             Error output
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION del_multiple_values_dtc
    (
        i_lang       IN language.id_language%TYPE,
        id_dtc_array IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get doc_area_inst_soft ids for given filters
    *
    * @param i_institution              Institution id
    * @param i_softwares                Softwares id array
    * @param i_doc_areas                Doc area id array
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION get_dais_ids
    (
        i_institution institution.id_institution%TYPE,
        i_softwares   table_number,
        i_doc_areas   table_number
    ) RETURN table_number;

    /********************************************************************************************
    * Clones doc_area_soft_inst records from a facility to another,
    * allowing software specification
    * The origin and destination facility can be the same (to clone configurations from a software to another) 
    *
    * @param i_lang                Log Language ID
    * @param i_destination_inst    Destination facility
    * @param i_destination_soft    Destination software
    * @param i_dais                Doc_area_inst_soft id array
    * @param o_error               Error output   
    *
    * @result                      true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION clone_dais_to_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_destination_inst IN institution.id_institution%TYPE,
        i_destination_soft IN software.id_software%TYPE,
        i_dais             IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Delete doc_area_inst_soft records
    *
    * @param i_lang              Language id
    * @param id_dais_array       doc_area_inst_soft id array
    * @param o_error             Error output
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/

    FUNCTION del_multiple_values_dais
    (
        i_lang        IN language.id_language%TYPE,
        id_dais_array IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Delete doc_area_inst_soft records
    *
    * @param i_lang                Log Language ID
    * @param i_destination_inst    Destination facility
    * @param i_dais                Doc_area_inst_soft id array
    * @param o_error               Error output   
    *
    * @result                      true if successful
    *
    * @author                      LFSF
    * @version                     2.8.0.1
    * @since                       2019/10/11
    ********************************************************************************************/
    FUNCTION del_multiple_dais
    (
        i_lang             IN language.id_language%TYPE,
        i_destination_inst IN institution.id_institution%TYPE,
        i_dais             IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert multiple records in doc_area_inst_soft using selected filters
    *
    * @param i_lang                  Language id
    * @param i_institution           Institution id 
    * @param i_software_list         Software id array
    * @param i_doc_area_array        Doc area id array
    * @param i_flg_mode              Flag mode
    * @param i_flg_switch_mode       Flag switch mode
    * @param i_flg_type              Flag type
    * @param i_flg_multiple          Flag multiple
    * @param i_sys_shortcut_error    Sys_shortcut_error id
    * @param i_flg_scope_type        Flag scope type
    * @param i_flg_data_paging_en    Flag data paging
    * @param i_page_size             Page size
    * @param i_market                Market id
    * @param o_error                 Error output
    *
    * @result                        true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION insert_multiple_values_dais
    (
        i_lang               IN language.id_language%TYPE,
        i_institution        IN institution.id_institution%TYPE,
        i_software_list      IN table_number,
        i_doc_area_array     IN table_number,
        i_flg_mode           IN doc_area_inst_soft.flg_mode%TYPE,
        i_flg_switch_mode    IN doc_area_inst_soft.flg_switch_mode%TYPE,
        i_flg_type           IN doc_area_inst_soft.flg_type%TYPE,
        i_flg_multiple       IN doc_area_inst_soft.flg_multiple%TYPE,
        i_sys_shortcut_error IN doc_area_inst_soft.id_sys_shortcut_error%TYPE,
        i_flg_scope_type     IN doc_area_inst_soft.flg_scope_type%TYPE,
        i_flg_data_paging_en IN doc_area_inst_soft.flg_data_paging_enabled%TYPE,
        i_page_size          IN doc_area_inst_soft.page_size%TYPE,
        -- i_market             IN doc_area_inst_soft.id_market%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Edit doc_area_inst_soft records in bulk, sending editable values for update
    *
    * @param i_lang                Log Language ID   
    * @param id_vssa_array         Selected records array
    * @param i_flg_mode           flg_mode
    * @param o_error               Error output   
    *
    * @result                      true if successful
    *
    * @author                      LCRS 
    * @version                     2.6.4.3
    * @since                       2015/01/22
    ********************************************************************************************/
    FUNCTION edit_multiple_records_dais
    (
        i_lang               IN language.id_language%TYPE,
        i_dais_array         IN table_number,
        i_flg_mode           IN VARCHAR2,
        i_flg_switch_mode    IN VARCHAR2,
        i_flg_type           IN VARCHAR2,
        i_flg_multiple       IN VARCHAR2,
        i_sys_shortcut_error IN VARCHAR2,
        i_flg_scope_type     IN VARCHAR2,
        i_flg_data_paging    IN VARCHAR2,
        i_page_size          IN VARCHAR2,
        i_market             IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get ped_area_soft_inst ids for given filters
    *
    * @param i_institution              Institution id
    * @param i_softwares                Softwares id array
    * @param i_ped_areas                Ped area id array
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION get_pasi_ids
    (
        i_institution institution.id_institution%TYPE,
        i_softwares   table_number,
        i_ped_areas   table_number
    ) RETURN table_varchar;

    /********************************************************************************************
    * Clones ped_area_soft_inst records from a facility to another,
    * allowing software specification
    * The origin and destination facility can be the same (to clone configurations from a software to another) 
    *
    * @param i_lang                Log Language ID
    * @param i_origin_inst         Origin facility
    * @param i_destination_inst    Destination facility
    * @param i_software            Origin software
    * @param i_destination_soft    Destination software
    * @param i_unit_measure        Unit measure id
    * @param o_error               Error output   
    *
    * @result                      true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION clone_pasi_to_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_destination_inst IN institution.id_institution%TYPE,
        i_destination_soft IN software.id_software%TYPE,
        i_rowid            IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Delete ped_area_soft_inst records
    *
    * @param i_lang              Language id
    * @param id_pasi_array       ped_area_soft_inst id array
    * @param o_error             Error output
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/

    FUNCTION del_multiple_values_pasi
    (
        i_lang        IN language.id_language%TYPE,
        id_pasi_array IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert multiple records in ped_area_soft_inst using selected filters
    *
    * @param i_lang               Language id
    * @param i_institution        Institution id
    * @param i_software_list      Software id array
    * @param i_ped_area_add_array Ped_area_add id array
    * @param i_market             Market id
    * @param i_flg_available      Flg available
    * @param o_error              Error output
    *
    * @result                     true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/

    FUNCTION insert_multiple_values_pasi
    (
        i_lang               IN language.id_language%TYPE,
        i_institution        IN institution.id_institution%TYPE,
        i_software_list      IN table_number,
        i_ped_area_add_array IN table_number,
        i_flg_available      IN ped_area_soft_inst.flg_available%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Edit ped_area_soft_inst records in bulk, sending editable values for update
    *
    * @param i_lang                Log Language ID   
    * @param id_ped_area_array     Selected records array of ped_areas
    * @param i_institution_array   Selected records array of institutions
    * @param i_software_array      Selected records array of softwares
    * @param i_market_array        Selected records array of markets
    * @param i_rank                Rank
    * @param i_available           Available
    * @param o_error               Error output   
    *
    * @result                      true if successful
    *
    * @author                      LCRS
    * @version                     2.6.3
    * @since                       2013/04/10
    ********************************************************************************************/
    FUNCTION edit_multiple_records_pasi
    (
        i_lang              IN language.id_language%TYPE,
        i_ped_area_array    IN table_number,
        i_institution_array IN table_number,
        i_software_array    IN table_number,
        i_market_array      IN table_number,
        i_rank              IN VARCHAR2,
        i_available         IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

END pk_apex_template_context;
/
