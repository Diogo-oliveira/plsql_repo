/*-- Last Change Revision: $Rev: 2029017 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_touch_option_ti IS

    -- Author  : ARIEL.MACHADO
    -- Created : 3/10/2011 6:50:25 PM
    -- Purpose : Transference of information in Touch-Option with master areas like vital signs

    -- Public type declarations
    TYPE t_rec_doc_element_vs IS RECORD(
        id_doc_element       doc_element.id_doc_element%TYPE, -- Element ID
        vital_sign_read_list table_number); -- List of transactional vital sign reads

    TYPE t_coll_doc_element_vs IS TABLE OF t_rec_doc_element_vs;

    TYPE t_hash_vital_sign IS TABLE OF VARCHAR2(200) INDEX BY BINARY_INTEGER;

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations
    /**
    * Returns the formatted value of vital sign associated through TOTemplate
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_vsread       ID vital sign read
    * @param   i_dt_creation  Timestamp of template's element that is associated to the vital sign read
    *
    * @return  A formatted string representing the vital sign read  
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/10/2011
    */
    FUNCTION get_formatted_vsread
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_vsread      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_dt_creation IN epis_documentation_det.dt_creation_tstz%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returns the item's description. In case of an element that refers to a value in an external functionallity 
    * (Master area for the transfer of information) returns the description that is used in that area.
    * Otherwise, it returns the translation of code passed as input parameter.
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_flg_type     Element type. It is used to recognize the element in the case of references to a master area
    * @param   i_master_item  ID of an item in a master area that is represented by this element
    * @param   i_code_trans   Code used to retrieve applicable translation when the element is no related with master areas
    *
    * @return  A string to use as element's description
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/17/2011
    */
    FUNCTION get_element_description
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN doc_element.flg_type%TYPE,
        i_master_item IN doc_element.id_master_item%TYPE,
        i_code_trans  IN translation.code_translation%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Get latest reading for a list vital sign identifiers and a patient      *
    * identifier                                                              *
    *                                                                         *
    * @param   i_lang                   Professional preferred language       *
    * @param   i_prof                   Professional identification and its   *
    *                                   context (institution and software)    *
    * @param   i_patient                Patient ID                            *
    * @param   i_episode                Episode ID                            *
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
    FUNCTION get_vs_info
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_episode                  IN episode.id_episode%TYPE,
        i_tbl_vs                   IN table_number,
        i_tbl_aux_vs               IN table_number,
        i_flg_show_previous_values IN VARCHAR2 DEFAULT NULL,
        i_hash_vital_sign          IN table_table_varchar,
        o_vs_info                  OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a list of vital signs that are referenced by elements of this template and area that are applicable to patient
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Area ID
    * @param   i_doc_template       Template ID
    * @param   i_pat_gender         Patient's gender
    * @param   i_pat_age            Patient's age
    * @param   i_include_vs_rel     Include related vital sign (in case it has). Default: Yes
    * @param   o_lst_vs             List of vital signs
    * @param   o_lst_conf_vs        List of configured vital signs for instit/softw
    * @param   o_error              Error information
    *
    * @value i_include_vs_rel       {*} 'Y'  Yes {*} 'N' No
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/21/2011
    */
    FUNCTION get_template_vs_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_doc_template    IN doc_template.id_doc_template%TYPE,
        i_pat_gender      IN patient.gender%TYPE,
        i_pat_age         IN patient.age%TYPE,
        i_flg_view        IN vs_soft_inst.flg_view%TYPE,
        i_include_vs_rel  IN VARCHAR DEFAULT pk_alert_constant.g_yes,
        o_lst_vs          OUT table_number,
        o_lst_aux_vs      OUT table_number,
        o_lst_conf_vs     OUT table_number,
        o_hash_vital_sign OUT table_table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Save vital signs measurement using Touch-option framework
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   i_episode                Episode ID
    * @param   i_pat                    Patient ID
    * @param   i_doc_element_list       List of template's elements ID (id_doc_element)
    * @param   i_save_mode_list         List of flags to indicate the applicable mode to save each vital signs measurement
    * @param   i_vital_sign_list        List of vital signs ID (id_vital_sign)
    * @param   i_vital_sign_value_list  List of vital signs values
    * @param   i_vital_sign_uom_list    List of units of measurement (id_unit_measure)
    * @param   i_vital_sign_scales_list List of scales (id_vs_scales_element)
    * @param   i_vital_sign_date_list   List of measurement date. Values are serialized as strings (YYYYMMDDhh24miss)
    * @param   i_vital_sign_read_list   List of saved vital sign measurement (id_vital_sign_read)
    * @param   i_dt_creation_tstz       Timestamp entry. Default current timestamp    
    *
    * @param   o_doc_element_vs_list    List of template's elements ID and respective collection of saved vital sign measurement
    
    * @param   o_error                  Error information
    *
    * @value i_save_mode_list {*} 'N' Creates a new measurement and associates it with element. {*} 'E' Edits the measurement and associates it with element. {*} 'R' Reviews the measurement and associates it with element. {*} 'A' Associates the measurement with the element but does not perform any operation in referred vital sign    
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/24/2011
    */
    FUNCTION set_epis_vital_sign_touch
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_pat                    IN patient.id_patient%TYPE,
        i_doc_element_list       IN table_number,
        i_save_mode_list         IN table_varchar,
        i_vital_sign_list        IN table_number,
        i_vital_sign_value_list  IN table_number,
        i_vital_sign_uom_list    IN table_number,
        i_vital_sign_scales_list IN table_number,
        i_vital_sign_date_list   IN table_varchar,
        i_vital_sign_read_list   IN table_number,
        i_dt_creation_tstz       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_id_edit_reason         IN table_number DEFAULT NULL,
        i_notes_edit             IN table_clob DEFAULT NULL,
         i_id_epis_documentation  IN epis_documentation.id_epis_documentation%TYPE,
        o_doc_element_vs_list    OUT t_coll_doc_element_vs,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if documentation entry has elements that refers to values in an external functionality 
     (Master area for the transfer of information) that were edited/updated after a specific timestamp
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   i_epis_documentation     Epis documentation ID
    * @param   i_dt_creation            Timestamp to check if related master areas that were associated to entry were edited after this date
    * @param   o_changed                Returns if the entry has or not references to information that was edited after input timestamp
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
    FUNCTION check_ti_info_changed
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_dt_creation        IN epis_documentation.dt_creation_tstz%TYPE,
        o_ref_info_changed   OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;


    FUNCTION cancel_epis_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_cancel_reason   IN epis_documentation.id_cancel_reason%TYPE DEFAULT NULL,
        i_notes              IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    
END pk_touch_option_ti;
/
