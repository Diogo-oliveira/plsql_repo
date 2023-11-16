/*-- Last Change Revision: $Rev: 2028933 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:49 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_rep_death_registry AS

    /**********************************************************************************************
    * Returns the patient death registry id
    *
    * @param        i_lang                   Language id
    * @param        i_patient                Patient id
    * @param        o_death_registry         Death registry id (null if patient has none)
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        08-Jun-2010
    **********************************************************************************************/
    FUNCTION get_pat_death_registry
    (
        i_lang           IN language.id_language%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        o_death_registry OUT death_registry.id_death_registry%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --

    FUNCTION get_dr_section_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        o_section OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns death registry summary
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_component_name         Component internal name
    * @param        o_section                Section components structure
    * @param        o_data_val               Components values
    * @param        o_prof_data              Professional who has made the changes (name,
    *                                        speciality and date of changes)
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        08-Jun-2010
    **********************************************************************************************/
    FUNCTION get_dr_summary
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --

    FUNCTION get_dr_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_record         IN death_registry.id_death_registry%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_dr_wf          OUT table_table_varchar,
        o_sys_list       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_component_desc
    (
        i_lang              IN NUMBER,
        i_ds_component      IN NUMBER,
        o_ds_component_desc OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dr_rep_summary
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_section_name   IN VARCHAR2,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rep_component_desc
    (
        i_lang               IN NUMBER,
        i_section_name       IN VARCHAR2,
        i_id_ds_cmpt_kmt_rel IN NUMBER,
        o_ds_component_desc  OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;



END pk_rep_death_registry;
/
