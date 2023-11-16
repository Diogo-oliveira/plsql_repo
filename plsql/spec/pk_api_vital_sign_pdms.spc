/*-- Last Change Revision: $Rev: 1735373 $*/
/*-- Last Change by: $Author: paulo.teixeira $*/
/*-- Date of last change: $Date: 2016-05-02 09:32:13 +0100 (seg, 02 mai 2016) $*/

CREATE OR REPLACE PACKAGE pk_api_vital_sign_pdms IS

    -- Author  : Rui Teixeira
    -- Created : 2011-03-02
    -- Purpose : Package that should contain all vital sign functions available to PDMS

    g_relation_blood_pressure CONSTANT vital_sign_relation.relation_domain%TYPE := 'C';
    g_relation_min_rank       CONSTANT vital_sign_relation.rank%TYPE := 1;
    g_relation_max_rank       CONSTANT vital_sign_relation.rank%TYPE := 2;

    g_view_1 CONSTANT VARCHAR(2) := 'V1';
    g_view_2 CONSTANT VARCHAR(2) := 'V2';
    g_view_3 CONSTANT VARCHAR(2) := 'V3';

    g_view_p  CONSTANT VARCHAR(2) := 'P';
    g_view_pt CONSTANT VARCHAR(2) := 'PT';
    g_view_pg CONSTANT VARCHAR(2) := 'PG';
    g_view_rg CONSTANT VARCHAR(2) := 'RG';

    g_vital_sign_main_pain CONSTANT vital_sign.id_vital_sign%TYPE := 11;
    g_vital_sign_type_pain CONSTANT VARCHAR(2) := 'P';

    -- types

    TYPE t_vs_views IS RECORD(
        id_vital_sign vs_soft_inst.id_vital_sign%TYPE,
        flg_view      vs_soft_inst.flg_view%TYPE);

    TYPE t_coll_vs_views IS TABLE OF t_vs_views;

    /**********************************************************************************************
    * Get Vital Signs Records for a visit between a date interval
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_visit                  Visit id
    * @param        i_id_vs                  Vital sign ids to return
    * @param        i_dt_begin               Date from which start to return records
    * @param        i_dt_end                 Date by which to end returning records
    * @param        o_vs                     Vital signs records output cursor
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.2.1
    * @since        2012-03-02
    **********************************************************************************************/
    FUNCTION get_visit_vital_signs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_id_vs    IN table_number,
        i_dt_begin IN VARCHAR2 DEFAULT NULL,
        i_dt_end   IN VARCHAR2 DEFAULT NULL,
        i_dt_type  IN VARCHAR2 DEFAULT 'M',
        o_vs       OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set Vital Signs Records
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_episode                Episode id
    * @param        i_id_vs                  Vital signs ids
    * @param        i_value_vs               Vital signs values
    * @param        i_id_um                  Unit measure ids
    * @param        i_multichoice_vs         Multichoices ids
    * @param        i_scales_elem_vs         Scale elements ids
    * @param        i_dt_vs                  Vital signs monitorization dates
    * @param        i_validate_rep           Y - Does not insert if the hour has an register
    * @param        o_id_vsr                 Vital signs records ids
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.2.1
    * @since        2012-03-02
    **********************************************************************************************/
    FUNCTION set_episode_vital_signs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN vital_sign_read.id_episode%TYPE,
        i_id_vs          IN table_number,
        i_value_vs       IN table_number,
        i_id_um          IN table_number,
        i_multichoice_vs IN table_number,
        i_scales_elem_vs IN table_number,
        i_dt_vs          IN table_varchar,
        i_validate_rep   IN VARCHAR,
        o_id_vsr         OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set Vital Signs Records with Attributes
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_episode                Episode id
    * @param        i_id_vs                  Vital signs ids
    * @param        i_value_vs               Vital signs values
    * @param        i_id_um                  Unit measure ids
    * @param        i_multichoice_vs         Multichoices ids
    * @param        i_scales_elem_vs         Scale elements ids
    * @param        i_dt_vs                  Vital signs monitorization dates
    * @param        i_validate_rep           Y - Does not insert if the hour has an register
    * @param        i_tbtb_attribute         List of attributes selected
    * @param        i_tbtb_free_text         List of free text for each attribute
    * @param        o_id_vsr                 Vital signs records ids
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Sergio Pereira
    * @version      2.6.3.10
    * @since        2014-01-20
    **********************************************************************************************/
    FUNCTION set_episode_vital_signs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN vital_sign_read.id_episode%TYPE,
        i_id_vs          IN table_number,
        i_value_vs       IN table_number,
        i_id_um          IN table_number,
        i_multichoice_vs IN table_number,
        i_scales_elem_vs IN table_number,
        i_dt_vs          IN table_varchar,
        i_validate_rep   IN VARCHAR,
        i_tbtb_attribute IN table_table_number,
        i_tbtb_free_text IN table_table_clob,
        o_id_vsr         OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Edit Vital Signs Records with Attributes
    *
    * @param        i_lang                    Language id
    * @param        i_prof                    Professional, software and institution ids
    * @param        id_vital_sign_read        Vital Sign reading ID
    * @param        i_value                   Vital sign value
    * @param        id_unit_measure           Measure unit ID
    * @param        dt_vital_sign_read_tstz   Date when vital sign was read
    * @param        i_tbtb_attribute          List of attributes selected
    * @param        i_tbtb_free_text          List of free text for each attribute
    * @param        o_error                   Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Sergio Pereira
    * @version      2.6.3.10
    * @since        2014-01-24
    **********************************************************************************************/
    FUNCTION edit_vital_signs
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN table_number,
        i_value                   IN table_number,
        i_id_unit_measure         IN table_number,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_tbtb_attribute          IN table_table_number,
        i_tbtb_free_text          IN table_table_clob,
        o_id_vsr                  OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel Vital Signs Records
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_vital_sign_read        Vital Sign records ids
    * @param        i_cancel_reason          Id cancel reason
    * @param        i_notes                  Cancel notes
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.2.1
    * @since        2012-03-02
    **********************************************************************************************/

    FUNCTION cancel_vital_signs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_vital_sign_read IN table_number,
        i_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE DEFAULT pk_cancel_reason.c_reason_other,
        i_notes           IN vital_sign_read.notes_cancel%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the PFH vital signs PDMS View
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient identifier
    * @param        o_vital_s                Patient vital signs conf
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.2.1
    * @since        2012-03-02
    **********************************************************************************************/

    FUNCTION get_pdms_module_vital_signs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_vital_s OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
      * Gets the PFH vital signs by identifiers
      *
      * @param        i_lang                   Language id
      * @param        i_prof                   Professional, software and institution ids
      * @param        i_vs_ids                 Vital signs identifiers
      * @param        o_vital_s                Patient vital signs conf
      * @param        o_error                  Error information
      *
      * @return       TRUE if sucess, FALSE otherwise
      *                        
      * @author       Miguel Gomes
      * @version      2.6.3.12
      * @since        2014-03-17
    **********************************************************************************************/

    FUNCTION get_pdms_module_vs_by_ids
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_vs_ids  IN table_number,
        o_vital_s OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the PFH vital signs relation of blood presure parameters to PDMS
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vs                  Children vital signs
    * @param        o_vs_parent              Vital signs
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.2.1
    * @since        2012-03-02
    **********************************************************************************************/

    FUNCTION get_vital_signs_bp_parents
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_vs     IN table_number DEFAULT NULL,
        o_vs_parent OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the the most adquate vital sign to register
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient identifier
    * @param        i_vital_signs            Matrix with vital signs
    * @param        o_selected               Selected vital signs from matrix.
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.2.1
    * @since        2012-03-02
    **********************************************************************************************/
    FUNCTION get_pdms_vital_sign_to_reg
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_vital_signs IN table_table_number,
        o_selected    OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the all PFH vital signs views configuration to PDMS
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        o_vital_s                Patient vital signs conf
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    
    * @version      2.6.3.2
    * @since        2012-11-19
    **********************************************************************************************/

    FUNCTION get_all_pdms_views
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_vital_s OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the options for vital signs (multi-choice)
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        o_vital_s                Patient vital signs conf
    * @param        i_id_vs                  Vital sign ID
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.4
    * @since        2013-04-22
    **********************************************************************************************/
    FUNCTION get_vs_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_id_vs   IN vital_sign_desc.id_vital_sign%TYPE,
        o_vs      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the vital sign fill type
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vs                  Vital sign identifier
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.7
    * @since        2013-07-16
    **********************************************************************************************/

    FUNCTION get_vs_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_id_vs IN vital_sign.id_vital_sign%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the options for vital signs (multi-choice)
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vital_sign_read     Read identifier
    * @param        i_flg_screen             ????
    * @param        o_hist                   Histórico do valor
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-01
    **********************************************************************************************/
    FUNCTION get_vs_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_flg_screen         IN VARCHAR2,
        o_hist               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the vital sign attrributes
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vital_sign          Vital sign identifier
    * @param        o_vs_attribute           
    * @param        o_vs_options             
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-01
    **********************************************************************************************/
    FUNCTION get_vs_attribute
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign_read.id_vital_sign_read%TYPE,
        o_vs_attribute  OUT pk_types.cursor_type,
        o_vs_options    OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the vital sign attrributes
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vital_sign          Vital sign identifier
    * @param        i_id_vital_sign_read     Vital sign read identifier
    * @param        o_vs_options             
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Sergio Pereira
    * @version      2.6.3.10
    * @since        2014-01-24
    **********************************************************************************************/
    FUNCTION get_vs_read_attributes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign      IN vital_sign.id_vital_sign%TYPE,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_vs_attributes      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * get_pdms_module_vital_signs
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_patient                   patient identifier
    * @param      i_flg_view                  default view
    * @param      i_tb_vs                     vital sign identifier search table
    * @param      i_tb_view                   flag view search table  
    * @param      o_vs                        cursor out
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2014/11/20
    ***********************************************************************************************************/

    FUNCTION get_pdms_module_vital_signs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_tb_vs    IN table_number DEFAULT NULL,
        i_tb_view  IN table_varchar DEFAULT NULL,
        o_vs       OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
END pk_api_vital_sign_pdms;
/
