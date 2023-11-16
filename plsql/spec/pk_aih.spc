/*-- Last Change Revision: $Rev: 2028445 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_aih IS
    g_description CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_code        CONSTANT VARCHAR2(1 CHAR) := 'C';

    TYPE rec_aih_section_data_param IS RECORD(
        is_to_fill_with_saved_data VARCHAR2(1),
        tbl_sections               t_table_ds_sections);

    FUNCTION get_section_events_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_component.internal_name%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_section_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ds_component IN ds_component.internal_name%TYPE,
        i_aih_simple   IN aih_simple.id_aih_simple%TYPE,
        i_params       IN CLOB,
        o_section      OUT pk_types.cursor_type,
        o_def_events   OUT pk_types.cursor_type,
        o_events       OUT pk_types.cursor_type,
        o_items_values OUT pk_types.cursor_type,
        o_data_val     OUT CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_section_data_db
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ds_component IN ds_component.internal_name%TYPE,
        i_aih_simple   IN aih_simple.id_aih_simple%TYPE,
        i_params       IN CLOB,
        o_section      OUT t_table_ds_sections,
        o_def_events   OUT t_table_ds_def_events,
        o_events       OUT t_table_ds_events,
        o_items_values OUT t_table_ds_items_values,
        o_data_val     OUT xmltype,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_section_data_db_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ds_component IN ds_component.internal_name%TYPE,
        i_aih_simple   IN aih_simple.id_aih_simple%TYPE,
        i_params       IN rec_aih_section_data_param,
        i_xml          IN CLOB,
        o_section      OUT t_table_ds_sections,
        o_def_events   OUT t_table_ds_def_events,
        o_events       OUT t_table_ds_events,
        o_items_values OUT t_table_ds_items_values,
        o_data_val     OUT xmltype,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_section_data_int
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ds_component IN ds_component.internal_name%TYPE,
        i_aih_simple   IN aih_simple.id_aih_simple%TYPE,
        i_params       IN rec_aih_section_data_param,
        i_xml          IN CLOB,
        o_section      OUT t_table_ds_sections,
        o_def_events   OUT t_table_ds_def_events,
        o_events       OUT t_table_ds_events,
        o_items_values OUT t_table_ds_items_values,
        o_data_val     OUT xmltype,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION parse_val_fill_sect_param
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ds_component IN ds_component.internal_name%TYPE,
        i_params       IN CLOB,
        o_params       OUT rec_aih_section_data_param,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_value_from_xml
    (
        i_lang          language.id_language%TYPE,
        i_xml           IN CLOB,
        i_internal_name ds_component.internal_name%TYPE,
        o_value         OUT VARCHAR,
        o_alt_value     OUT VARCHAR,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_count_proc_special
    (
        i_lang  language.id_language%TYPE,
        i_xml   IN CLOB,
        o_count OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION add_data_val
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name   IN ds_component.internal_name%TYPE,
        i_flg_edit_mode   IN VARCHAR2,
        io_tbl_sections   IN OUT NOCOPY t_table_ds_sections,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events,
        io_data_values    IN OUT NOCOPY xmltype,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE add_default_values
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name   IN ds_component.internal_name%TYPE,
        io_tbl_sections   IN OUT NOCOPY t_table_ds_sections,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events,
        io_data_values    IN OUT NOCOPY xmltype
    );

    FUNCTION add_saved_values
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name   IN ds_component.internal_name%TYPE,
        i_flg_edit_mode   IN VARCHAR2,
        io_tbl_sections   IN OUT NOCOPY t_table_ds_sections,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events,
        io_data_values    IN OUT NOCOPY xmltype,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE set_nls_numeric_characters(i_prof IN profissional);

    PROCEDURE add_to_data_values_obj
    (
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name   IN ds_component.internal_name%TYPE,
        i_value           IN VARCHAR2,
        i_alt_value       IN VARCHAR2,
        i_desc_value      IN VARCHAR2,
        i_xml_value       IN xmltype DEFAULT NULL,
        i_is_saved_value  IN BOOLEAN DEFAULT FALSE,
        io_tbl_sections   IN OUT NOCOPY t_table_ds_sections,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events,
        io_data_values    IN OUT NOCOPY xmltype
    );

    FUNCTION set_aih_simple
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_xml        IN CLOB,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_aih_special
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_xml        IN CLOB,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE add_new_item
    (
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_item_desc          IN pk_translation.t_desc_translation,
        i_item_value         IN sys_list.id_sys_list%TYPE DEFAULT NULL,
        i_item_alt_value     IN sys_list_group_rel.flg_context%TYPE DEFAULT NULL,
        i_item_xml_value     IN CLOB DEFAULT NULL,
        i_item_rank          IN sys_list_group_rel.rank%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values
    );

    PROCEDURE set_tl_aih
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    FUNCTION get_aih_simple_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_aih_simple IN aih_simple.id_aih_simple%TYPE
    ) RETURN CLOB;

    /**
    * Function to cancel a AIH simple record
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_aih_simple   AIH simple identifier
    * @param   i_notes_cancel Cancelation notes
    *
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   01-Set-2017
    */
    FUNCTION set_cancel_aih_simple
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_aih_simple   IN aih_simple.id_aih_simple%TYPE,
        i_notes_cancel IN aih_simple.notes_cancel%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cancel_aih_special
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_aih_special  IN aih_special.id_aih_special%TYPE,
        i_notes_cancel IN aih_special.notes_cancel%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_aih_simple_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_data       OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Function to get the aih special information to the AIH report
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_episode   Episode identifier
    * @param   i_id_patient   Patient identifier
    * @param   i_id_epis_pn   Single Page note id
    *
    * @param   o_data         AIH episode/patient data
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   04-Set-2017
    */
    FUNCTION get_aih_special_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_epis_pn    IN epis_pn.id_epis_pn%TYPE,
        o_data          OUT NOCOPY pk_types.cursor_type,
        o_repeated_data OUT NOCOPY pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Function to get the aih abstract data description. 
    * To be used to get the external causes and the special procedures descriptions.
    * Or other fields that allow the selection of multiple diagnosis 
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_aih_data  Link to the aih_simple or aih special table
    * @param   i_flg_aih_type    Type: Simple or special
    * @param   i_fld_field_type  Identifies the field: f.e. external causes
    * @param   i_id_task_type    Task type to diagnosis descriptions
    * @param   i_flg_return_type D - diagnosis description; C-diagnosis code
    *
    * @param   description of the diagnosis in the abstract field
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   04-Set-2017
    */
    FUNCTION get_abs_data_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_aih_data     IN aih_abs_data.id_aih_data%TYPE,
        i_flg_aih_type    IN aih_abs_data.flg_aih_type%TYPE,
        i_fld_field_type  IN aih_abs_data.flg_field_type%TYPE,
        i_id_task_type    IN task_type.id_task_type%TYPE,
        i_flg_return_type IN VARCHAR2 DEFAULT g_description
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Function to return the description of all fields presented in the AIH special screen.
    * To be used in Single Page
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_aih_simple AIH simple identifier 
    *
    * @param   AIH simple descriptions
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   04-Set-2017
    */
    FUNCTION get_aih_special_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_aih_special IN aih_special.id_aih_special%TYPE
    ) RETURN CLOB;

    /********************************************************************************************
    * Function that updates the id_episode
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param i_episode_temp  Temporary episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Sofia Mendes
    * @version               2.7.1.3
    * @since                 2017/09/15
    ********************************************************************************************/
    FUNCTION match_episode_aih
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that updates the id_episode
    *
    * @param i_lang            Language ID
    * @param i_prof            Professional
    * @param i_id_patient_temp Temporary patient
    * @param i_id_patient      Patient identifier 
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Sofia Mendes
    * @version               2.7.1.3
    * @since                 2017/09/15
    ********************************************************************************************/
    FUNCTION match_patient_aih
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient_temp IN patient.id_patient%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_name       CONSTANT VARCHAR2(6 CHAR) := 'PK_AIH';
    g_package_owner      CONSTANT VARCHAR2(5 CHAR) := 'ALERT';
    g_aih_simple         CONSTANT VARCHAR2(10 CHAR) := 'AIH_SIMPLE';
    g_tk_type_aih_simple CONSTANT VARCHAR2(30 CHAR) := 'TL_TASK.CODE_TL_TASK.62';
    g_tk_type_aih_simple_id NUMBER := 62;

    g_error VARCHAR2(1000 CHAR);

    g_back_nls        VARCHAR2(2) := NULL;
    g_is_to_reset_nls BOOLEAN := FALSE;
    g_nls_num_char CONSTANT VARCHAR2(30) := 'NLS_NUMERIC_CHARACTERS';

    g_xml_value         CONSTANT VARCHAR2(20 CHAR) := 'VALUE';
    g_xml_alt_value     CONSTANT VARCHAR2(20 CHAR) := 'ALT_VALUE';
    g_xml_internal_name CONSTANT VARCHAR2(20 CHAR) := 'INTERNAL_NAME';

    g_aih_diag_first        CONSTANT VARCHAR2(20 CHAR) := 'AIH_DIAG_FIRST';
    g_aih_procedure         CONSTANT VARCHAR2(20 CHAR) := 'AIH_PROCEDURE';
    g_aih_diag_second       CONSTANT VARCHAR2(20 CHAR) := 'AIH_DIAG_SECOND';
    g_aih_diag_cause        CONSTANT VARCHAR2(20 CHAR) := 'AIH_DIAG_CAUSES';
    g_aihs_solic            CONSTANT VARCHAR2(20 CHAR) := 'AIHS_SOLIC';
    g_aihs_inst_exec        CONSTANT VARCHAR2(20 CHAR) := 'AIHS_INST_EXEC';
    g_aihs_inst_exec_oth    CONSTANT VARCHAR2(50 CHAR) := 'AIHS_INST_EXEC_OTH';
    g_aihs_cnes             CONSTANT VARCHAR2(50 CHAR) := 'AIHS_CNES';
    g_aihs_resp_name        CONSTANT VARCHAR2(50 CHAR) := 'AIHS_RESP_NAME';
    g_aihs_phone            CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PHONE';
    g_aihs_proc_old         CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_OLD';
    g_aihs_diag_princ       CONSTANT VARCHAR2(50 CHAR) := 'AIHS_DIAG_PRINC';
    g_aihs_proc_princ       CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_PRINC';
    g_aihs_proc_change      CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_CHANGE';
    g_aihs_diag_sec         CONSTANT VARCHAR2(50 CHAR) := 'AIHS_DIAG_SEC';
    g_aihs_causes           CONSTANT VARCHAR2(50 CHAR) := 'AIHS_CAUSES';
    g_aihs_uti              CONSTANT VARCHAR2(50 CHAR) := 'AIHS_UTI';
    g_aihs_proc_special     CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL';
    g_aihs_proc_special_q   CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q';
    g_aihs_proc_special2    CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL2';
    g_aihs_proc_special_q2  CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q2';
    g_aihs_proc_special3    CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL3';
    g_aihs_proc_special_q3  CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q3';
    g_aihs_proc_special4    CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL4';
    g_aihs_proc_special_q4  CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q4';
    g_aihs_proc_special5    CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL5';
    g_aihs_proc_special_q5  CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q5';
    g_aihs_proc_special6    CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL6';
    g_aihs_proc_special_q6  CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q6';
    g_aihs_proc_special7    CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL7';
    g_aihs_proc_special_q7  CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q7';
    g_aihs_proc_special8    CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL8';
    g_aihs_proc_special_q8  CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q8';
    g_aihs_proc_special9    CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL9';
    g_aihs_proc_special_q9  CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q9';
    g_aihs_proc_special10   CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL10';
    g_aihs_proc_special_q10 CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q10';
    g_aihs_proc_special11   CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL11';
    g_aihs_proc_special_q11 CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q11';
    g_aihs_proc_special12   CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL12';
    g_aihs_proc_special_q12 CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q12';
    g_aihs_proc_special13   CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL13';
    g_aihs_proc_special_q13 CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q13';
    g_aihs_proc_special14   CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL14';
    g_aihs_proc_special_q14 CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q14';
    g_aihs_proc_special15   CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL15';
    g_aihs_proc_special_q15 CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q15';
    g_aihs_proc_special16   CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL16';
    g_aihs_proc_special_q16 CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q16';
    g_aihs_proc_special17   CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL17';
    g_aihs_proc_special_q17 CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q17';
    g_aihs_proc_special18   CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL18';
    g_aihs_proc_special_q18 CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q18';
    g_aihs_proc_special19   CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL19';
    g_aihs_proc_special_q19 CONSTANT VARCHAR2(50 CHAR) := 'AIHS_PROC_SPECIAL_Q19';
    g_aihs_just             CONSTANT VARCHAR2(50 CHAR) := 'AIHS_JUST';

    g_request_aihs CONSTANT VARCHAR2(20 CHAR) := 'REQUEST_AIHS';

    g_domain_solic     CONSTANT VARCHAR2(50 CHAR) := 'AIH_SPECIAL.SOLIC';
    g_domain_inst_exec CONSTANT VARCHAR2(50 CHAR) := 'AIH_SPECIAL.INST_EXEC';
    g_domain_uti       CONSTANT VARCHAR2(50 CHAR) := 'AIH_SPECIAL.UTI';

    g_aih_flg_status_c CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_aih_flg_status_a CONSTANT VARCHAR2(1 CHAR) := 'A';

    c_data_type_md  CONSTANT VARCHAR2(2 CHAR) := 'MD';
    c_data_type_mmd CONSTANT VARCHAR2(3 CHAR) := 'MMD';

    g_solic_mudanca        CONSTANT VARCHAR2(1 CHAR) := '1';
    g_solic_special        CONSTANT VARCHAR2(1 CHAR) := '2';
    g_exec_institution_oth CONSTANT VARCHAR2(3 CHAR) := 'IE0';

    --flg_aih_type
    g_aih_simple_si  CONSTANT VARCHAR2(2 CHAR) := 'SI';
    g_aih_special_sp CONSTANT VARCHAR2(2 CHAR) := 'SP';

    --flg_field_type
    g_aih_external_causes_field_ec CONSTANT VARCHAR2(2 CHAR) := 'EC';
    g_aih_proc_special_field_pc    CONSTANT VARCHAR2(2 CHAR) := 'PC';

    g_flg_status_active CONSTANT VARCHAR2(2 CHAR) := 'A';

    l_exception EXCEPTION;

END pk_aih;
/
