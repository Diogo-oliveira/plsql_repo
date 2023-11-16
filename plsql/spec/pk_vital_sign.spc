/*-- Last Change Revision: $Rev: 2055614 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:26:38 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_vital_sign AS

    SUBTYPE st_varchar2_1 IS VARCHAR2(1 CHAR);
    SUBTYPE st_varchar2_200 IS VARCHAR2(200 CHAR);
    SUBTYPE st_varchar2_1000 IS VARCHAR2(1000 CHAR);
    --
    -- PUBLIC CONSTANTS
    --

    -- unit measure id for <none>
    c_without_um CONSTANT vs_patient_ea.id_unit_measure%TYPE := 25;

    --NOTA: Este valores devem ser parametrizados na sys_config
    --TODO...
    g_vs_pain CONSTANT vital_sign.id_vital_sign%TYPE := 11;

    TYPE t_rec_vital_signs IS RECORD(
        vs_description_1     pk_translation.t_desc_translation,
        dt_reg_1             vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        id_professional_1    professional.id_professional%TYPE,
        id_vital_sign_read_1 vital_sign_read.id_vital_sign_read%TYPE,
        id_episode_1         vital_sign_read.id_episode%TYPE,
        vs_description_2     pk_translation.t_desc_translation,
        dt_reg_2             vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        id_professional_2    professional.id_professional%TYPE,
        id_vital_sign_read_2 vital_sign_read.id_vital_sign_read%TYPE,
        id_episode_2         vital_sign_read.id_episode%TYPE,
        vs_description_3     pk_translation.t_desc_translation,
        dt_reg_3             vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        id_professional_3    professional.id_professional%TYPE,
        id_vital_sign_read_3 vital_sign_read.id_vital_sign_read%TYPE,
        id_episode_3         vital_sign_read.id_episode%TYPE,
        id_vital_sign        vital_sign.id_vital_sign%TYPE,
        dt_last_upd_1        vital_sign_read.dt_registry%TYPE,
        dt_last_upd_2        vital_sign_read.dt_registry%TYPE,
        dt_last_upd_3        vital_sign_read.dt_registry%TYPE,
        vs_description_4     pk_translation.t_desc_translation,
        dt_reg_4             vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        id_professional_4    professional.id_professional%TYPE,
        id_vital_sign_read_4 vital_sign_read.id_vital_sign_read%TYPE,
        id_episode_4         vital_sign_read.id_episode%TYPE,
        dt_last_upd_4        vital_sign_read.dt_registry%TYPE,
        vs_desc              pk_translation.t_desc_translation);

    TYPE t_cur_vital_signs IS REF CURSOR RETURN t_rec_vital_signs;

    TYPE t_coll_vital_signs IS TABLE OF t_rec_vital_signs;

    TYPE t_rec_vs_header IS RECORD(
        id_vital_sign        vs_soft_inst.id_vital_sign%TYPE,
        val_min              vital_sign_unit_measure.val_min%TYPE,
        val_max              vital_sign_unit_measure.val_max%TYPE,
        rank                 vs_soft_inst.rank%TYPE,
        rank_conc            vital_sign_relation.rank%TYPE,
        id_vital_sign_parent vital_sign_relation.id_vital_sign_parent%TYPE,
        relation_type        vital_sign_relation.relation_domain%TYPE,
        format_num           vital_sign_unit_measure.format_num%TYPE,
        flg_fill_type        vital_sign.flg_fill_type%TYPE,
        flg_sum              VARCHAR2(1),
        name_vs              pk_translation.t_desc_translation,
        desc_unit_measure    pk_translation.t_desc_translation,
        id_unit_measure      vs_soft_inst.id_unit_measure%TYPE,
        dt_server            VARCHAR2(200),
        flg_view             vs_soft_inst.flg_view%TYPE,
        id_institution       vs_soft_inst.id_institution%TYPE,
        id_software          vs_soft_inst.id_software%TYPE);

    TYPE t_cur_vs_header IS REF CURSOR RETURN t_rec_vs_header;

    TYPE t_coll_vs_header IS TABLE OF t_rec_vs_header;

    TYPE t_rec_vs_info IS RECORD(
        id_vital_sign        vs_soft_inst.id_vital_sign%TYPE,
        VALUE                st_varchar2_1000,
        desc_unit_measure    pk_translation.t_desc_translation,
        pain_descr           pk_translation.t_desc_translation,
        name_vs              pk_translation.t_desc_translation,
        short_name_vs        pk_translation.t_desc_translation,
        short_dt_read        st_varchar2_1000,
        prof_read            professional.name%TYPE,
        rank                 vs_soft_inst.rank%TYPE,
        id_vital_sign_read   vital_sign_read.id_vital_sign_read%TYPE,
        flg_view             vs_soft_inst.flg_view%TYPE,
        dt_vital_sign_read   vital_signs_ea.dt_vital_sign_read%TYPE,
        value_detail         st_varchar2_1000,
        id_vital_sign_detail vs_soft_inst.id_vital_sign%TYPE,
        flg_read_only        st_varchar2_1);

    TYPE t_coll_vs_info IS TABLE OF t_rec_vs_info;

    TYPE t_vs_detail IS RECORD(
        id_vital_sign_read_hist vital_sign_read_hist.id_vital_sign_read_hist%TYPE,
        id_vital_sign_read      vital_sign_read.id_vital_sign_read%TYPE,
        id_vital_sign           vital_sign_read.id_vital_sign%TYPE,
        VALUE                   translation.desc_lang_1%TYPE,
        flg_state               vital_sign_read.flg_state%TYPE,
        id_unit_measure         vital_sign_read.id_unit_measure%TYPE,
        id_prof_read            vital_sign_read.id_prof_read%TYPE,
        dt_vital_sign_read_tstz vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        dt_registry             vital_sign_read.dt_registry%TYPE,
        id_vital_sign_desc      vital_sign_read.id_vital_sign_desc%TYPE,
        id_vital_sign_notes     vital_sign_read.id_vital_sign_notes%TYPE,
        is_glasgow              st_varchar2_1,
        is_hist                 st_varchar2_1,
        edit_reason             CLOB,
        is_triage               st_varchar2_1);

    TYPE t_vs_detail_coll IS TABLE OF t_vs_detail;

    TYPE rec_sign_v IS RECORD(
        id_vital_sign        vital_sign.id_vital_sign%TYPE,
        internal_name        vital_sign.intern_name_vital_sign%TYPE,
        val_min              vital_sign_unit_measure.val_min%TYPE,
        val_max              vital_sign_unit_measure.val_max%TYPE,
        rank_conc            vital_sign_relation.rank%TYPE,
        id_vital_sign_parent vital_sign_relation.id_vital_sign_parent%TYPE,
        vs_parent_int_name   vital_sign.intern_name_vital_sign%TYPE,
        relation_type        vital_sign_relation.relation_domain%TYPE,
        format_num           vital_sign_unit_measure.format_num%TYPE,
        flg_fill_type        VARCHAR2(50 CHAR),
        flg_sum              VARCHAR2(1 CHAR),
        name_vs              pk_translation.t_desc_translation,
        desc_unit_measure    pk_translation.t_desc_translation,
        id_unit_measure      vs_soft_inst.id_vs_soft_inst%TYPE,
        dt_server            VARCHAR(50 CHAR),
        vs_flg_type          vital_sign_relation.relation_domain%TYPE,
        flg_validate         VARCHAR2(1 CHAR),
        flg_save_to_db       VARCHAR2(1 CHAR),
        flg_show_description VARCHAR2(1 CHAR),
        flg_calculate_trts   VARCHAR2(1 CHAR));

    TYPE cursor_sign_v IS REF CURSOR RETURN rec_sign_v;

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_sign_v);

    --
    -- PUBLIC FUNCTIONS
    -- 
    FUNCTION get_vs_um_inst
    (
        i_vital_sign  IN vital_sign.id_vital_sign%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN unit_measure.id_unit_measure%TYPE;

    FUNCTION get_vs_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_vital_sign IN vital_sign.id_vital_sign%TYPE,
        i_short_desc IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN pk_translation.t_desc_translation;

    FUNCTION get_vsd_order_val(i_vital_sign_desc IN vital_sign_desc.id_vital_sign_desc%TYPE)
        RETURN vital_sign_desc.order_val%TYPE;

    FUNCTION get_vsd_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_vital_sign_desc IN vital_sign_desc.code_vital_sign_desc%TYPE,
        i_age             IN patient.age%TYPE,
        i_gender          IN patient.gender%TYPE,
        i_short_desc      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN pk_translation.t_desc_translation;

    FUNCTION get_vsd_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_vital_sign_desc IN vital_sign_desc.id_vital_sign_desc%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_short_desc      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN pk_translation.t_desc_translation;

    FUNCTION get_vsse_value(i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE)
        RETURN vital_sign_scales_element.value%TYPE;

    FUNCTION get_vsse_um
    (
        i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE,
        i_without_um_no_id  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN vital_sign_scales_element.id_unit_measure%TYPE;

    FUNCTION get_vs_parent(i_vital_sign IN vital_sign_relation.id_vital_sign_detail%TYPE)
        RETURN vital_sign_relation.id_vital_sign_parent%TYPE;

    FUNCTION get_vs_parent_triage(i_vital_sign IN vital_sign_relation.id_vital_sign_detail%TYPE)
        RETURN vital_sign_relation.id_vital_sign_parent%TYPE;

    FUNCTION get_vs_relation_domain(i_vital_sign IN vital_sign_relation.id_vital_sign_detail%TYPE)
        RETURN vital_sign_relation.relation_domain%TYPE;

    /************************************************************************************************************
    * This function returns the glasgow total value summing the glasgow eye, motor and verbal values
    *
    * @param      i_vital_sign                Vital sign id (glasgow total id)
    * @param      i_patient                   Patient id
    * @param      i_episode                   Episode id
    * @param      i_dt_vital_sign_read        Vital sign read date
    *
    * @return     Glasgow total value
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2009/08/19
    ************************************************************************************************************/
    FUNCTION get_glasgowtotal_value
    (
        i_vital_sign         vital_sign_read.id_vital_sign%TYPE,
        i_patient            vital_sign_read.id_patient%TYPE,
        i_episode            vital_sign_read.id_episode%TYPE,
        i_dt_vital_sign_read vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN vital_sign_read.value%TYPE;

    /************************************************************************************************************
    * This function returns the glasgow total value summing the glasgow eye, motor and verbal values
    *
    * @param      i_vital_sign                Vital sign id (glasgow total id)
    * @param      i_patient                   Patient id
    * @param      i_episode                   Episode id
    * @param      i_dt_vital_sign_read        Vital sign read date
    *
    * @return     Glasgow total value
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2009/08/19
    ************************************************************************************************************/
    FUNCTION get_glasgowtotal_value_hist
    (
        i_vital_sign         vital_sign_read.id_vital_sign%TYPE,
        i_patient            vital_sign_read.id_patient%TYPE,
        i_episode            vital_sign_read.id_episode%TYPE,
        i_dt_vital_sign_read vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE
    ) RETURN vital_sign_read.value%TYPE;

    /************************************************************************************************************
    * This function returns the blood pressure value concatenating the sistolic and diastolic pressure values
    *
    * @param      i_id_vital_sign             Vital sign id (blood pressure id)
    * @param      i_id_episode                Episode id
    * @param      i_dt_vital_sign_read        Vital sign read date
    * @param      i_decimal_symbol            Decimal symbol
    *
    * @return     Blood pressure value
    *
    * @author     Paulo Fonseca
    * @version    2.5.0.5
    * @since      2009/08/19
    ************************************************************************************************************/
    FUNCTION get_bloodpressure_value
    (
        i_vital_sign         vital_sign_read.id_vital_sign%TYPE,
        i_patient            vital_sign_read.id_patient%TYPE,
        i_episode            vital_sign_read.id_episode%TYPE,
        i_dt_vital_sign_read vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_decimal_symbol     sys_config.value%TYPE,
        i_pat_pregn_fetus    pat_pregn_fetus.id_pat_pregn_fetus%TYPE DEFAULT NULL,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_vsr_inst_um
    (
        i_institution       IN institution.id_institution%TYPE,
        i_vital_sign        IN vital_sign_read.id_vital_sign%TYPE,
        i_unit_measure      IN vital_sign_read.id_unit_measure%TYPE,
        i_vs_scales_element IN vital_sign_read.id_vs_scales_element%TYPE,
        i_software          IN software.id_software%TYPE
    ) RETURN vital_sign_read.id_unit_measure%TYPE;

    FUNCTION get_vsr_row
    (
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_inst_um         IN vital_sign_read.id_unit_measure%TYPE DEFAULT pk_vital_sign.c_without_um
    ) RETURN vital_sign_read%ROWTYPE;

    FUNCTION is_lower
    (
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_inst_um         IN vital_sign_read.id_unit_measure%TYPE,
        i_new_value       IN vital_sign_read.value%TYPE,
        i_new_dt_read     IN vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN BOOLEAN;

    FUNCTION is_greater
    (
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_inst_um         IN vital_sign_read.id_unit_measure%TYPE,
        i_new_value       IN vital_sign_read.value%TYPE,
        i_new_dt_read     IN vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN BOOLEAN;

    FUNCTION is_older
    (
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_inst_um         IN vital_sign_read.id_unit_measure%TYPE,
        i_new_dt_read     IN vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN BOOLEAN;

    FUNCTION has_same_date
    (
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_inst_um         IN vs_patient_ea.id_unit_measure%TYPE,
        i_new_dt_read     IN vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN BOOLEAN;

    FUNCTION get_fst_vsr
    (
        i_vital_sign   IN vital_sign_read.id_vital_sign%TYPE,
        i_unit_measure IN vital_sign_read.id_unit_measure%TYPE,
        i_patient      IN vital_sign_read.id_patient%TYPE,
        i_visit        IN episode.id_visit%TYPE DEFAULT NULL
    ) RETURN vital_sign_read.id_vital_sign_read%TYPE;

    PROCEDURE get_min_max_vsr
    (
        i_vital_sign   IN vital_sign_read.id_vital_sign%TYPE,
        i_unit_measure IN vital_sign_read.id_unit_measure%TYPE,
        i_patient      IN vital_sign_read.id_patient%TYPE,
        i_visit        IN episode.id_visit%TYPE DEFAULT NULL,
        o_min_vsr      OUT vital_sign_read.id_vital_sign_read%TYPE,
        o_max_vsr      OUT vital_sign_read.id_vital_sign_read%TYPE
    );

    PROCEDURE get_lst_vsr
    (
        i_vital_sign   IN vital_sign_read.id_vital_sign%TYPE,
        i_unit_measure IN vital_sign_read.id_unit_measure%TYPE,
        i_patient      IN vital_sign_read.id_patient%TYPE,
        i_visit        IN episode.id_visit%TYPE DEFAULT NULL,
        o_lst3_vsr     OUT vital_sign_read.id_vital_sign_read%TYPE,
        o_lst2_vsr     OUT vital_sign_read.id_vital_sign_read%TYPE,
        o_lst1_vsr     OUT vital_sign_read.id_vital_sign_read%TYPE
    );

    FUNCTION vs_has_notes(i_vital_sign_notes IN vital_sign_notes.id_vital_sign_notes%TYPE) RETURN VARCHAR2;

    FUNCTION check_vs_notes(i_vs_read IN vital_sign_read.id_vital_sign_read%TYPE) RETURN VARCHAR2;

    FUNCTION get_vs_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN vital_sign_read.id_patient%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_vital_sign         IN vital_sign_read.id_vital_sign%TYPE,
        i_value              IN vital_sign_read.value%TYPE,
        i_vs_unit_measure    IN vital_sign_read.id_unit_measure%TYPE,
        i_vital_sign_desc    IN vital_sign_read.id_vital_sign_desc%TYPE,
        i_vs_scales_element  IN vital_sign_read.id_vs_scales_element%TYPE,
        i_dt_vital_sign_read IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_ea_unit_measure    IN vital_sign_read.id_unit_measure%TYPE DEFAULT NULL,
        i_short_desc         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_decimal_symbol     IN sys_config.value%TYPE DEFAULT NULL,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Get list of vital signs configured for instit/soft/flg_view            *
    * Based on pk_vital_sign.get_vs_header.                                  *
    *                                                                        *
    * @param i_lang                   Preferred language ID for this         *
    *                                 professional                           *
    * @param i_prof                   Object (professional ID,               *
    *                                 institution ID, software ID)           *
    * @param i_flg_view               View mode                              *
    * @param i_institution            Institution id                         *
    * @param i_software               Software id                            *
    * @param i_dt_end                 Date end                               *
    *                                                                        *
    * @return                         Table with documentation systems info  *
    *                                                                        *
    * @author                         Gustavo Serrano                        *
    * @version                        2.6.1                                  *
    * @since                          08-Fev-2011                            *
    **************************************************************************/
    FUNCTION tf_get_vs_header
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_view    IN vs_soft_inst.flg_view%TYPE,
        i_institution IN vs_soft_inst.id_institution%TYPE,
        i_software    IN vs_soft_inst.id_software%TYPE,
        i_dt_end      IN st_varchar2_200,
        i_patient     IN vital_sign_read.id_patient%TYPE
    ) RETURN t_coll_vs_header DETERMINISTIC
        PIPELINED;

    /************************************************************************************************************
    * This function returns all the vital signs for a specific view and its details.
    *
    * @param      i_lang            Prefered language
    * @param      i_prof            Profissional, institution and software id's
    * @param      i_patient         Patient id
    * @param      i_episode         Episode id
    * @param      i_flg_view        Vital signs view
    * @param      o_sign_v          Output cursor
    * @param      o_dt_ini          Date from which it is possible to register vital signs
    * @param      o_dt_end          Date as far it is possible to register vital signs
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2010/11/10
    ************************************************************************************************************/
    FUNCTION get_vs_header
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_sign_v   OUT t_cur_vs_header,
        o_dt_ini   OUT VARCHAR2,
        o_dt_end   OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns all the vital signs for a specific view and its details.
    *
    * @param      i_lang            Prefered language
    * @param      i_prof            Profissional, institution and software id's
    * @param      i_flg_view        Vital signs view
    * @param      o_sign_v          Output cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2009/08/27
    ************************************************************************************************************/
    FUNCTION get_vs_header
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_sign_v   OUT t_cur_vs_header,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Obter lista dos profissionais da instituição
    *
    * @param i_lang                   Language id
    * @param i_prof                   professional, software and institution ids
    * @param i_id_vital_sign          vital sign id
    * @param i_patient                patient id
    * @param i_dt_max_reg             Max date that is considered to return results
    * @param o_value_desc             Vital Sign description
    * @param o_dt_vital_sign_read     Date of regestry of this vital sign
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luís Maia
    * @since                          18-Nov-2011
    **********************************************************************************************/
    FUNCTION get_pat_lst_vsr_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign      IN vital_sign.id_vital_sign%TYPE,
        i_patient            IN vital_signs_ea.id_patient%TYPE,
        i_dt_max_reg         IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        o_value_desc         OUT st_varchar2_200,
        o_dt_vital_sign_read OUT vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_pat_vs_value_unit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign.id_vital_sign%TYPE,
        i_patient         IN vital_signs_ea.id_patient%TYPE,
        i_dt_max_reg      IN vital_sign_read.dt_vital_sign_read_tstz%TYPE DEFAULT NULL,
        o_vs_value        OUT VARCHAR2,
        o_vs_unit_measure OUT NUMBER,
        o_vs_um_desc      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Obter lista dos profissionais da instituição
    *
    * @param i_lang                   Language id
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id
    * @param o_lst_imc                Last active values of Weight and Height Vital Signs
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luís Maia
    * @since                          29-Set-2011
    **********************************************************************************************/
    FUNCTION get_pat_lst_imc_values
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN vital_signs_ea.id_patient%TYPE,
        o_lst_imc OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION get_pat_vital_sign
    (
        i_lang     IN language.id_language%TYPE,
        i_patient  IN vital_sign_read.id_patient%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_sign_v   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_pat_vs_grid_list
    (
        i_lang       IN language.id_language%TYPE,
        i_patient    IN vital_sign_read.id_patient%TYPE,
        i_prof       IN profissional,
        i_flg_view   IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen IN VARCHAR2,
        o_time       OUT pk_types.cursor_type,
        o_sign_v     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_biometric_grid_list
    (
        i_lang       IN language.id_language%TYPE,
        i_patient    IN vital_sign_read.id_patient%TYPE,
        i_prof       IN profissional,
        i_flg_screen IN VARCHAR2,
        o_time       OUT pk_types.cursor_type,
        o_bio        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_pat_vs_grid_all
    (
        i_lang     IN language.id_language%TYPE,
        i_patient  IN vital_sign_read.id_patient%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_val_vs   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_biometric_grid_all
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN vital_sign_read.id_patient%TYPE,
        i_prof    IN profissional,
        o_val_bio OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_epis_vs_grid_val
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN vital_sign_read.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_val_vs   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_pat_vs_grid_val
    (
        i_lang     IN language.id_language%TYPE,
        i_patient  IN vital_sign_read.id_patient%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_val_vs   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_biometric_graph
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN vital_sign_read.id_patient%TYPE,
        i_prof    IN profissional,
        o_val_bio OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the vital sign scale id of a vital sign scale element 
    *
    * @param      i_lang                   Prefered language
    * @param      i_vs_scales_element      Vital sign scale element id
    *
    * @return     Vital sign scale id
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2009/08/21
    ************************************************************************************************************/
    FUNCTION get_vs_scale(i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE)
        RETURN vital_sign_scales.id_vital_sign_scales%TYPE;
    /************************************************************************************************************
    * This function returns the maximum value to a vital sign that uses a scale
    *
    * @param      i_vs_scales_element      Vital sign scale element id
    *
    * @return     Vital sign max value
    *
    * @author     José Silva
    * @version    2.5
    * @since      2011/10/07
    ************************************************************************************************************/
    FUNCTION get_vs_scale_max_value(i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE)
        RETURN vital_sign_scales.id_vital_sign_scales%TYPE;

    FUNCTION get_vs_scale_min_value(i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE)
        RETURN vital_sign_scales.id_vital_sign_scales%TYPE;

    /************************************************************************************************************   
    /************************************************************************************************************
    * This function returns the vital sign scale short description of a vital sign scale element 
    *
    * @param      i_lang                   Prefered language
    * @param      i_vs_scales_element      Vital sign scale element id
    *
    * @return     Vital sign scale short description
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2009/08/21
    ************************************************************************************************************/
    FUNCTION get_vs_scale_shortdesc
    (
        i_lang              IN language.id_language%TYPE,
        i_vs_scales_element IN vital_sign_read.id_vs_scales_element%TYPE
    ) RETURN VARCHAR2;

    -------------------------------------------------------------------------------------------------------------

    /*******************************************************************************************************************************************
    *GET_VITAL_SIGN_UNIT_MEASURE Vital sign unit measure                                                                                       *
    *                                                                                                                                          *
    * @param I_LANG                   Language identifier                                                                                      *
    * @param I_PROF                   Professional, institution an software identifiers                                                        *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Return vital sign unit measure                                                                           *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2009/01/08                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_vital_sign_unit_measure
    (
        i_lang              IN language.id_language%TYPE,
        i_unit_measure      IN unit_measure.id_unit_measure%TYPE,
        i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE
    ) RETURN VARCHAR2;

    --
    FUNCTION scale_rank
    (
        t_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        l_clinical_service    IN clinical_service.id_clinical_service%TYPE,
        t_id_institution      IN institution.id_institution%TYPE,
        l_institution         IN institution.id_institution%TYPE,
        t_id_software         IN software.id_software%TYPE,
        l_software            IN software.id_software%TYPE
    ) RETURN INTEGER;
    /*******************************************************************************************************************************************
    *  GET_SCALE_ELEMENTS   This function returns the scales elements available to the episode.  The evaluation of the availability of the scale depends on institution, software and department .*
    *                                                                                                                                          *
    * @param I_LANG                   Language identifier                                                                                      *
    * @param I_PROF                   Profissioanal, institution and software identifiers                                                      *
    * @param I_EPISODE                Episode identifier                                                                                       *
    * @param I_ID_VITAL_SIGN_SCALE    Scale identifier                                                                                       *
    * @param i_id_triage_type         triage type identifier                                                                                        *
    * @param SCALE_ELEMENT_CURSOR     Output cursor                                                                                            *
    * @param VALUE                    Scale value                                                                                              *
    * @param ICON                     Icon name                                                                                                *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         True if no errors found and false otherwise                                                              *
    *                                                                                                                                          *
    * @raises                         No parametrization found                                                                                 *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2009/01/06                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_scale_elements
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_id_vital_sign_scale IN vital_sign_scales.id_vital_sign_scales%TYPE,
        i_id_triage_type      IN triage_type.id_triage_type%TYPE,
        i_id_vital_sign       IN vital_sign.id_vital_sign%TYPE,
        scale_element_cursor  OUT pk_types.cursor_type
    ) RETURN BOOLEAN;
    /*******************************************************************************************************************************************
    *  GET_ALL_SCALES  This function returns the scales available to the episode.  The evaluation of the availability of the scale depends on institution, software and department .*
    *                                                                                                                                          *
    * @param I_LANG                   Language identifier                                                                                      *
    * @param I_PROF                   Profissioanal, institution and software identifiers                                                      *
    * @param I_EPISODE                Episode identifier                                                                                       *
    * @param ID_VITAL_SIGN_SCALE      Scale identifier                                                                                         *
    * @param I_ID_TRIAGE_TYPE         Triage type identifier                                                                                        *
    * @param O_SCALE_CURSOR           Output cursor                                                                                            *
    *                                                                                                                                          *
    * @return                         True if no errors found and false otherwise                                                              *
    *                                                                                                                                          *
    * @raises                         No parametrization found                                                                                 *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2009/01/05                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_all_scales
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_id_vital_sign_scale IN vital_sign_scales.id_vital_sign_scales%TYPE,
        i_id_triage_type      IN triage_type.id_triage_type%TYPE,
        i_id_vital_sign       IN vital_sign.id_vital_sign%TYPE,
        o_scale_cursor        OUT pk_types.cursor_type
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function returns the vital sign alias if exists
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_id_patient                patient id
    * @param      i_code_vital_sign_desc      Vital sign unit description code for translation
    *
    * @return     Vital sign alias or translation
    *
    * @author     Rui Spratley
    * @version    2.4.3
    * @since      2008/05/28
    ***********************************************************************************************************/
    FUNCTION get_vs_alias
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_code_vital_sign_desc IN vital_sign_desc.code_vital_sign_desc%TYPE
    ) RETURN pk_translation.t_desc_translation;
    /************************************************************************************************************
    * This function returns the vital sign alias if exists
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_gender                    patient gender
    * @param      i_age                       patient age
    * @param      i_code_vital_sign_desc      Vital sign unit description code for translation
    *
    * @return     Vital sign alias or translation
    *
    * @author     Alexandre Santos
    * @version    2.5
    * @since      2009/06/30
    ***********************************************************************************************************/
    FUNCTION get_vs_alias
    (
        i_lang                 IN language.id_language%TYPE,
        i_gender               IN patient.gender%TYPE,
        i_age                  IN patient.age%TYPE,
        i_code_vital_sign_desc IN vital_sign_desc.code_vital_sign_desc%TYPE
    ) RETURN pk_translation.t_desc_translation;

    --
    FUNCTION get_graph_menu_name(i_vs_name IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION get_graph_menu_time_period(i_vs_name IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION get_biometric_graph_filters(i_lang IN language.id_language%TYPE) RETURN table_info;

    /**
    * Get axis value in years.
    *
    * @param i_axis_type    axis type
    * @param i_axis_val     axis value
    *
    * @return               axis value (in years)
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.0
    * @since                2009/01/26
    */
    FUNCTION get_year_value
    (
        i_axis_type IN graphic.flg_x_axis_type%TYPE,
        i_axis_val  IN graphic.x_axis_end%TYPE
    ) RETURN graphic.x_axis_end%TYPE;

    FUNCTION get_graphics_by_patient
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_graphs  OUT table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_decode_value_vs
    (
        i_vsr_unit_measure IN vital_sign_read.id_unit_measure%TYPE,
        i_vsi_unit_measure IN vs_soft_inst.id_unit_measure%TYPE,
        i_value            IN vital_sign_read.value%TYPE
    ) RETURN vital_sign_read.value%TYPE;
    FUNCTION get_filter_prof_condition
    (
        i_actual_value IN professional.id_professional%TYPE,
        i_filter_value IN professional.id_professional%TYPE,
        i_id_filter    IN NUMBER
    ) RETURN professional.id_professional%TYPE;
    FUNCTION get_filter_cs_condition
    (
        i_actual_value IN clinical_service.id_clinical_service%TYPE,
        i_filter_value IN clinical_service.id_clinical_service%TYPE,
        i_id_filter    IN NUMBER
    ) RETURN clinical_service.id_clinical_service%TYPE;
    FUNCTION get_patient_clinical_service
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN clinical_service.id_clinical_service%TYPE;
    /********************************************************************************************
    * Registar um conjunto de leituras de SVs de uma só vez. Os arrays são lidos na mesma ordem, correspondendo cada linha de
      I_VS_ID à linha com o mesmo índice de I_VS_VAL
        *
    * @param i_lang             Id do idioma
        * @param i_episode          episode id
    * @param i_prof             professional, software, institution ids
        * @param i_pat              patient id
        * @param i_vs_id            Array de IDs de SVs lidos
        * @param i_vs_val           Array de leituras dos SVs de I_VS_ID ( (valor do sinal vital)
        * @param i_id_monit         ID da monitorização, se for o caso
        * @param i_unit_meas        ID's das unidades de medida dos sinais vitais a inserir
        * @param i_notes            notes
        * @param i_prof_cat_type    category of professional
    * @param o_vital_sign_read
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE if sucess, FALSE otherwise
    *
    * @author                   Emilia Taborda
    * @version                  1.0
    * @since                    2006/09/01
    ********************************************************************************************/
    FUNCTION set_epis_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_id_monit           IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_notes              IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_vs_read         IN table_varchar,
        i_epis_triage        IN epis_triage.id_epis_triage%TYPE,
        i_unit_meas_convert  IN table_number,
        i_vs_val_high        IN table_number DEFAULT table_number(),
        i_vs_val_low         IN table_number DEFAULT table_number(),
        i_fetus_vs           IN NUMBER DEFAULT NULL,
        o_vital_sign_read    OUT table_number,
        o_dt_registry        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_id_monit           IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_notes              IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_vs_read         IN table_varchar,
        i_epis_triage        IN epis_triage.id_epis_triage%TYPE,
        i_unit_meas_convert  IN table_number,
        i_tbtb_attribute     IN table_table_number,
        i_tbtb_free_text     IN table_table_clob,
        i_vs_val_high        IN table_number DEFAULT table_number(),
        i_vs_val_low         IN table_number DEFAULT table_number(),
        i_fetus_vs           IN NUMBER DEFAULT NULL,
        o_vital_sign_read    OUT table_number,
        o_dt_registry        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_vital_sign
    (
        i_lang                  IN language.id_language%TYPE,
        i_episode               IN vital_sign_read.id_episode%TYPE,
        i_prof                  IN profissional,
        i_pat                   IN vital_sign_read.id_patient%TYPE,
        i_vs_id                 IN table_number,
        i_vs_val                IN table_number,
        i_id_monit              IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas             IN table_number,
        i_vs_scales_elements    IN table_number,
        i_notes                 IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_dt_vs_read            IN table_varchar,
        i_epis_triage           IN epis_triage.id_epis_triage%TYPE,
        i_unit_meas_convert     IN table_number,
        i_tbtb_attribute        IN table_table_number,
        i_tbtb_free_text        IN table_table_clob,
        i_id_edit_reason        IN table_number,
        i_notes_edit            IN table_clob,
        i_vs_val_high           IN table_number DEFAULT table_number(),
        i_vs_val_low            IN table_number DEFAULT table_number(),
        i_fetus_vs              IN NUMBER DEFAULT NULL,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_vital_sign_read       OUT table_number,
        o_dt_registry           OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Returns the data of all the required vital signs in a set of discriminators.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_tbl_vital_sign         Table with vital signs IDs
    * @param i_flg_view               Area of the application
    * @param i_relation_domain        Relation domain. 'M'- TRTS; 'T' - Others
    * @param o_sign_v                 Cursor with the vital sign data
    * @param o_error                  Error message
    *
    * @return                         TRUE / FALSE
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          23/11/2009
    **************************************************************************/
    FUNCTION get_vs_triage_header
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tbl_vital_sign  IN table_number,
        i_flg_view        IN vs_soft_inst.flg_view%TYPE,
        i_relation_domain IN vital_sign_relation.relation_domain%TYPE DEFAULT pk_alert_constant.g_vs_rel_group,
        i_patient         IN patient.id_patient%TYPE,
        o_sign_v          OUT cursor_sign_v,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Obter todas as notas dos sinais vitais associadas ao episódio
    *
    * @param i_vs_parent        ID da relação dos sinais vitais da pressão arterial
    * @param i_episode          episode id
    *
    * @return                   description
    *
    * @author                   Emilia Taborda
    * @version                  1.0
    * @since                    2006/08/30
    ********************************************************************************************/
    FUNCTION get_vital_sign_val_bp
    (
        i_vs_parent      IN vital_sign_relation.id_vital_sign_parent%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_decimal_symbol IN VARCHAR2
    ) RETURN VARCHAR2;

    --

    FUNCTION cancel_biometric_read
    (
        i_lang  IN language.id_language%TYPE,
        i_vs    IN vital_sign_read.id_vital_sign_read%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_graph_x_value
    (
        i_dt_read     IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_read_min IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_flg_x       IN graphic.flg_x_axis_type%TYPE
    ) RETURN NUMBER;
    FUNCTION get_biometric_graphs_menu
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_id_vital_sign IN vital_sign.id_vital_sign%TYPE,
        o_menu_title    OUT sys_message.desc_message%TYPE,
        o_menu          OUT pk_types.cursor_type,
        o_menu_filters  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get available graphics. Adapted from GET_BIOMETRIC_GRAPHS_MENU.
    * For reports layer usage only.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param o_menu         available graphics cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.6
    * @since                2011/07/19
    */
    FUNCTION get_biometric_graphs_rep
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_menu    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_biometric_grid_values
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_id_graphic   IN graphic.id_graphic%TYPE,
        i_id_filter    IN NUMBER,
        o_graph_values OUT pk_types.cursor_type,
        o_type         OUT graphic.flg_x_axis_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get graphic values. Adapted from GET_BIOMETRIC_GRID_VALUES.
    * For reports layer usage only.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_graphic      graphic identifier
    * @param o_values       graphic values cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.6
    * @since                2011/07/13
    */
    FUNCTION get_biometric_grid_values_rep
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_graphic IN graphic.id_graphic%TYPE,
        o_values  OUT pk_types.cursor_type,
        o_type    OUT graphic.flg_x_axis_type%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_biometric_graph_grid
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_id_graphic        IN graphic.id_graphic%TYPE,
        o_x_label           OUT VARCHAR2,
        o_y_label           OUT VARCHAR2,
        o_graph_axis_x      OUT table_number,
        o_graph_axis_y      OUT table_number,
        o_graph_lines       OUT pk_types.cursor_type,
        o_graph_line_points OUT pk_types.cursor_type,
        o_graph_values      OUT pk_types.cursor_type,
        o_type              OUT graphic.flg_x_axis_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Verifica se ja foi efectuado algum registo na vista 2 dos sinais vitais e devolve true
    * para o flash, indicando que o flash deve ir directamente para a vista 2.
    *
    * @param i_lang             Id do idioma
    * @param i_episode          episode id
    * @param i_prof             professional, software, institution ids
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE if sucess, FALSE otherwise
    *
    * @author                   Thiago Brito
    * @version                  1.0
    * @since                    15-JUL-2008
    ********************************************************************************************/
    FUNCTION get_has_vital_sign_v2
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN vital_sign_read.id_episode%TYPE,
        i_prof    IN profissional,
        o_return  OUT PLS_INTEGER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns all the vital signs for a specific view and its details.
    *
    * @param      i_lang            Prefered language
    * @param      i_prof            Profissional structure
    * @param      i_patient         Patient ID
    * @param      i_episode         Espisode ID
    * @param      i_vital_sign      Vital Sign ID
    * @param      i_dt_vs_read      Vital Sign ID
    * @param      o_value_exists    Yes - exists; No - not exists 
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Filipe Machado
    * @version    2.5.1.2.1
    * @since      22-Dec-2010
    ************************************************************************************************************/
    FUNCTION srv_exist_vs_date_hour
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN vital_sign_read.id_patient%TYPE,
        i_episode      IN vital_sign_read.id_episode%TYPE,
        i_vital_sign   IN vital_sign_read.value%TYPE,
        i_dt_vs_read   IN VARCHAR2,
        o_value_exists OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function validates if a vital measure has already been entered for this vital sign with same date
    *
    * @param      i_lang            Prefered language
    * @param      i_prof            Profissional structure
    * @param      i_patient         Patient ID
    * @param      i_episode         Espisode ID
    * @param      i_vital_sign      Vital Sign ID
    * @param      i_vital_sign_read List of VSR to exclude from validation and used when editing a measurement. Otherwise NULL.
    * @param      i_dt_vs_read      Vital Sign ID
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Filipe Machado & Ariel Machado
    * @version    2.6.1.0.2
    * @since      17-Mai-2011
    ************************************************************************************************************/
    FUNCTION srv_exist_vs_date_hour
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN vital_sign_read.id_patient%TYPE,
        i_episode         IN vital_sign_read.id_episode%TYPE,
        i_vital_sign      IN vital_sign_read.value%TYPE,
        i_dt_vs_read      IN VARCHAR2,
        i_vital_sign_read IN table_number,
        o_value_exists    OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function validates if a vital measure has already been entered for any of the vital signs with same date
    *
    * @param      i_lang            Prefered language
    * @param      i_prof            Profissional structure
    * @param      i_patient         Patient ID
    * @param      i_episode         Espisode ID
    * @param      i_vital_sign      List of Vital Sign ID
    * @param      i_dt_vs_read      Clinical date
    * @param      i_vital_sign_read List of VSR to exclude from validation and used when editing a measurement. Otherwise NULL.
    * @param      o_value_exists    Flag indicating if value exists
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Anna Kurowska
    * @version    2.6.3.6
    * @since      10-Mai-2013
    ************************************************************************************************************/
    FUNCTION srv_exist_list_vs_dt
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN vital_sign_read.id_patient%TYPE,
        i_episode         IN vital_sign_read.id_episode%TYPE,
        i_vital_sign      IN table_number,
        i_dt_vs_read      IN VARCHAR2,
        i_vital_sign_read IN table_number,
        o_value_exists    OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function returns all the vital signs for a specific view and its details.
    *
    * @param      i_lang            Prefered language
    * @param      i_prof            Profissional structure
    * @param      i_patient         Patient ID
    * @param      i_area            Area calling actions
    * @param      o_actions         Actions cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Rui Duarte
    * @version    2.6.1
    * @since      17-FEV-2011
    ************************************************************************************************************/
    FUNCTION get_biometric_graph_views
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN vital_sign_read.id_patient%TYPE,
        i_area    IN VARCHAR2,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function creates a record in the history table for vital signs read
    *
    * @param        i_lang                        Language id
    * @param        i_prof                        Professional, software and institution ids
    * @param        i_id_vital_sign_read          Vital Sign Read ID
    * @param        i_value                       Vital sign value
    * @param        i_id_unit_measure             Measure unit ID
    * @param        i_dt_vital_sign_read_tstz     Date when vital sign was recorded
    * @param        i_flg_edit_type               Edit type. Values: E-edit, C-cancel
    *
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/
    FUNCTION set_vital_sign_read_hist
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_value                   IN vital_sign_read.value%TYPE,
        i_id_unit_measure         IN vital_sign_read.id_unit_measure%TYPE,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_flg_edit_type           IN VARCHAR2,
        i_value_high              IN vital_sign_read.value_high%TYPE DEFAULT NULL,
        i_value_low               IN vital_sign_read.value_low%TYPE DEFAULT NULL,
        o_id_vital_sign_read_hist OUT vital_sign_read_hist.id_vital_sign_read_hist%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function is called when editing a vital sign
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * @param        id_vital_sign_read         Vital Sign reading ID
    * @param        i_value                    Vital sign value
    * @param        id_unit_measure            Measure unit ID
    * @param        dt_vital_sign_read_tstz    Vital sign read date
    *
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/
    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_value                   IN vital_sign_read.value%TYPE,
        i_id_unit_measure         IN vital_sign_read.id_unit_measure%TYPE,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_dt_registry             IN VARCHAR2 DEFAULT NULL,
        i_id_unit_measure_sel     IN vital_sign_read.id_unit_measure_sel%TYPE,
        i_tb_attribute            IN table_number,
        i_tb_free_text            IN table_clob,
        i_id_edit_reason          IN vital_sign_read.id_edit_reason%TYPE,
        i_notes_edit              IN CLOB,
        i_value_high              IN vital_sign_read.value_high%TYPE DEFAULT NULL,
        i_value_low               IN vital_sign_read.value_low%TYPE DEFAULT NULL,
        i_fetus_vs                IN NUMBER DEFAULT NULL,
        i_id_epis_documentation   IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_value                   IN vital_sign_read.value%TYPE,
        i_id_unit_measure         IN vital_sign_read.id_unit_measure%TYPE,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_dt_registry             IN VARCHAR2 DEFAULT NULL,
        i_id_unit_measure_sel     IN vital_sign_read.id_unit_measure_sel%TYPE,
        i_tb_attribute            IN table_number,
        i_tb_free_text            IN table_clob,
        i_id_edit_reason          IN vital_sign_read.id_edit_reason%TYPE,
        i_notes_edit              IN CLOB,
        i_value_high              IN vital_sign_read.value_high%TYPE DEFAULT NULL,
        i_value_low               IN vital_sign_read.value_low%TYPE DEFAULT NULL,
        i_fetus_vs                IN NUMBER DEFAULT NULL,
        i_update_pdms             IN BOOLEAN,
        i_id_epis_documentation   IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function is called when editing a vital sign
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * @param        id_vital_sign_read         Vital Sign reading ID
    * @param        i_value                    Vital sign value
    * @param        id_unit_measure            Measure unit ID
    * @param        dt_vital_sign_read_tstz    Vital sign read date
    *
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/
    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN table_number,
        i_value                   IN table_number,
        i_id_unit_measure         IN table_number,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_dt_registry             IN VARCHAR2 DEFAULT NULL,
        i_id_unit_measure_sel     IN table_number,
        i_tbtb_attribute          IN table_table_number,
        i_tbtb_free_text          IN table_table_clob,
        i_id_edit_reason          IN vital_sign_read.id_edit_reason%TYPE,
        i_notes_edit              IN CLOB,
        i_value_high              IN table_number DEFAULT table_number(),
        i_value_low               IN table_number DEFAULT table_number(),
        i_fetus_vs                IN NUMBER DEFAULT NULL,
        i_id_epis_documentation   IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN table_number,
        i_value                   IN table_number,
        i_id_unit_measure         IN table_number,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_dt_registry             IN VARCHAR2 DEFAULT NULL,
        i_id_unit_measure_sel     IN table_number,
        i_tbtb_attribute          IN table_table_number,
        i_tbtb_free_text          IN table_table_clob,
        i_id_edit_reason          IN vital_sign_read.id_edit_reason%TYPE,
        i_notes_edit              IN CLOB,
        i_value_high              IN table_number DEFAULT table_number(),
        i_value_low               IN table_number DEFAULT table_number(),
        i_fetus_vs                IN NUMBER DEFAULT NULL,
        i_update_pdms             IN BOOLEAN,
        i_id_epis_documentation   IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function is returns history for a vital sign
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vital_sign_read     Vital sign read ID
    * @param        o_vsr_history            History Info
    * @param        o_error                  Error
    *
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/

    FUNCTION get_vital_sign_read_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_vsr_history        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function is returns details for a vital sign
    * @param        i_lang                  Language id
    * @param        i_prof                  Professional, software and institution ids
    * @param        i_id_vital_sign_read    Vital Sign reading ID
    * @param        i_id_vital_sign         Vital Sign ID
    * @param        i_flg_view              View identifier
    * @param        o_vsr_detail            Vital sign limit 
    * @param        o_vsr_ids               Vital sign Read IDs for editing
    * @param        o_is_monit_record       Indicates if the record comes from a monitorization
    * @param        o_dt_ini                Start date limit
    * @param        o_dt_end                End date limit
    * @param        o_error                 error
    *                
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/

    FUNCTION get_vsr_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_id_vital_sign      IN vital_sign_read.id_vital_sign%TYPE,
        i_flg_view           IN vs_soft_inst.flg_view%TYPE,
        i_id_episode         IN vital_sign_read.id_episode%TYPE,
        o_vsr_detail         OUT pk_types.cursor_type,
        o_vsr_ids            OUT pk_types.cursor_type,
        o_is_monit_record    OUT VARCHAR2,
        o_dt_ini             OUT VARCHAR2,
        o_dt_end             OUT VARCHAR2,
        o_vsr_attrib         OUT pk_types.cursor_type,
        o_edit_info          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function is returns details for a vital sign
    * @param        i_lang                  Language id
    * @param        i_prof                  Professional, software and institution ids
    * @param        i_patient               Patient ID
    * @param        i_episode               Episode ID
    * @param        i_monitorization        Monitorization ID
    * @param        o_dt_ini                Start date limit
    * @param        o_dt_end                End date limit
    * @param        o_error                 error
    *                
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/

    FUNCTION get_vs_date_limits
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        o_dt_ini            OUT VARCHAR2,
        o_dt_end            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get vital signs 
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_scope                     Scope ID (Patient ID, Visit ID)
    * @param    i_scope_type                Scope type (by patient {P}, by visit {V})
    * @param    i_begin_date                Begin date
    * @param    i_end_date                  End date
    * @param    i_flg_view                  Vital signs view to be used to get the vital sign rank
    *
    * @param    o_list                      Cursor with vital signs
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.5
    * @since   2011/02/02
    **********************************************************************************************/
    FUNCTION get_vital_signs_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_scope          IN NUMBER,
        i_scope_type     IN VARCHAR2,
        i_begin_date     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_outside_period IN VARCHAR2,
        i_flg_view       IN VARCHAR2,
        o_list           OUT t_cur_vital_signs,
        o_error          OUT t_error_out
        
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Opens the  t_cur_vital_signs strong cursor
    * 
    * @param    i_cursor                    Cursor
    * 
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   06-Oct-2011
    **********************************************************************************************/
    PROCEDURE open_cur_vital_signs(i_cursor IN OUT t_cur_vital_signs);

    /**********************************************************************************************
    * This functions sets a vital sign as "reviewed"
    * 
    * @param IN   i_lang                  Language ID
    * @param IN   i_prof                  Professional information
    * @param IN   i_episode               Episode ID
    * @param IN   i_id_vital_sign_read    Vital Sign reading ID
    * @param IN   i_review_notes          Review notes
    * @param OUT  o_error                 Error structure
    * 
    * @return                             True on success, false on error
    * 
    * @author  Sergio Dias
    * @version 2.6.1
    * @since   2011/03/10
    **********************************************************************************************/
    FUNCTION set_vital_sign_review
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_review_notes       IN review_detail.review_notes%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * This function sets one or several vital signs as "reviewed"
    * 
    * @param IN   i_lang                  Language ID
    * @param IN   i_prof                  Professional information
    * @param IN   i_episode               Episode ID
    * @param IN   i_id_vital_sign_read    Vital Sign reading ID (multiple)
    * @param IN   i_review_notes          Review notes
    * @param OUT  o_error                 Error structure
    * 
    * @return                             True on success, false on error
    * 
    * @author  Sergio Dias
    * @version 2.6.1
    * @since   2011/03/10
    **********************************************************************************************/
    FUNCTION set_vital_sign_review
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_vital_sign_read IN table_number,
        i_review_notes       IN review_detail.review_notes%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function is returns the new detail screen for a vital sign reading
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vital_sign_read     Vital sign read ID
    * @param        i_flg_screen             Screen modifier
    * @param        o_hist                   History Info
    * @param        o_error                  Error
    *
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      19-Apr-2011
    ************************************************************************************************************/

    FUNCTION get_vs_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_flg_screen         IN VARCHAR2,
        o_hist               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the blood pressure value concatenating the sistolic and diastolic pressure values
    *
    * @param      i_lang                      Language id
    * @param      i_prof                      Professional, software and institution ids
    * @param      i_id_vital_sign             Vital sign id (blood pressure id)
    * @param      i_id_vital_sign_read        Vital sign read id
    * @param      i_dt_vital_sign_read        Vital sign read date
    * @param      i_dt_registry               Registry date
    * @param      i_decimal_symbol            Decimal symbol
    *
    * @return     Blood pressure value
    *
    * @author     Sergio Dias
    * @version    2.6.1.0.1
    * @since      2011-04-30
    ************************************************************************************************************/
    FUNCTION get_bloodpressure_value_hist
    (
        i_vital_sign         IN vital_sign_read.id_vital_sign%TYPE,
        i_vital_sign_read    IN vital_sign_read.id_vital_sign_read%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_dt_vital_sign_read IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE,
        i_decimal_symbol     IN sys_config.value%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets a summary of Vital Signs and Indicators for a Patient
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_SCOPE                 Scope ID
    *                                     E-Episode ID
    *                                     V-Visit ID
    *                                     P-Patient ID
    * @param I_SCOPE_TYPE            Scope type
    *                                     E-Episode
    *                                     V-Visit
    *                                     P-Patient
    * @param I_FLG_SCOPE             Flag to filter the scope
    *                                     S-Summary 1.st level (last Note)
    *                                     D-Detailed 2.nd level (Last Note by each Area) 
    * @param I_INTERVAL              Interval to filter
    *                                     D-Last 24H
    *                                     W-Week
    *                                     M-Month
    *                                     A-All
    * @param O_DATA                  Cursor with VS and Indicators Data to show
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        António Neto
    * @since                         09-Aug-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_viewer_vs_indicators
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_flg_scope  IN VARCHAR2,
        i_interval   IN VARCHAR2,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * Get VS_DESC market id to be used by the given id_vs
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vs                     Vital sign id
    *
    * @return     Market id
    *
    * @author     Alexandre Santos
    * @version    2.5.1.2.1
    * @since      2011/08/25
    ***********************************************************************************************************/
    FUNCTION get_vs_desc_cfg_var
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_id_vs IN vital_sign_desc.id_vital_sign%TYPE
    ) RETURN market.id_market%TYPE;

    /************************************************************************************************************
    * Obter lista de descritivos de um SV cuja leitura não é numérica
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_gender                    patient gender
    * @param      i_age                       patient age
    * @param      i_id_vs                     Vital sign alias or translation
    * @param      o_vs                        descritivos
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Alexandre Santos
    * @version    2.5
    * @since      2009/06/30
    ***********************************************************************************************************/
    FUNCTION get_vs_desc_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_gender IN patient.gender%TYPE,
        i_age    IN patient.age%TYPE,
        i_id_vs  IN vital_sign_desc.id_vital_sign%TYPE,
        o_vs     OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * Obter lista de descritivos de um SV cuja leitura não é numérica
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_patient                   patient id
    * @param      i_id_vs                     Vital sign alias or translation
    * @param      o_vs                        descritivos
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Luís Maia
    * @version    2.5
    * @since      2011/11/15
    ***********************************************************************************************************/
    FUNCTION get_vs_desc_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_id_vs   IN vital_sign_desc.id_vital_sign%TYPE,
        o_vs      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the concatenation of a Vital Sign to be used with copy/paste tool
    *
    * @param      i_lang                      Prefered language from professional
    * @param      i_prof                      professional (identifier, institution, software)
    * @param      i_name_vs                   Vital Sign name
    * @param      i_value_desc                Value Description
    * @param      i_desc_unit_measure         Unit Measure Description
    * @param      i_dt_registry               Registry Date/Time
    *
    * @return                                 String with the format of Vital Signs to copy/paste
    *
    * @author                                 António Neto
    * @version                                2.6.1.2
    * @since                                  02-Aug-2011
    ************************************************************************************************************/
    FUNCTION get_vs_copy_paste
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_name_vs           IN VARCHAR2,
        i_value_desc        IN VARCHAR2,
        i_desc_unit_measure IN VARCHAR2,
        i_dt_registry       IN vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_epis_vital_sign
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN vital_sign_read.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_sign_v   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE open_my_cursor(i_cursor IN OUT t_cur_vs_header);

    FUNCTION merge_vs_visit_ea_dup
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_id_visit       IN visit.id_visit%TYPE,
        i_other_id_visit IN visit.id_visit%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * Get the vital sign date from the vital_sign_read record
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign_read        Vital sign read ID
    * @param      o_dt_vital_sign_read_tstz   Vital sign clinical date
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Sofia Mendes
    * @version    2.6.2
    * @since      24-08-2012
    ***********************************************************************************************************/
    FUNCTION get_vital_sign_date
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        o_dt_vital_sign_read_tstz OUT NOCOPY vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * Get the vital sign ranks to be used on single page. 
    * Rank 1: 1st value
    * Rank 2: penultimate value
    * Rank 3: last value
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign_read        Vital sign read ID
    * @param      i_scope                     Scope ID (Episode ID; Visit ID; Patient ID)
    * @param      i_flg_scope                 Scope (E- Episode, V- Visit, P- Patient)
    * @param      o_id_vital_sign_read        Vital sign read ID
    * @param      o_rank                      Rank
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Sofia Mendes
    * @version    2.6.2
    * @since      24-08-2012
    ***********************************************************************************************************/
    FUNCTION get_vital_signs_ranks
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_scope          IN VARCHAR2,
        i_scope              IN NUMBER,
        i_id_vital_sign_read IN table_number,
        o_id_vital_sign_read OUT NOCOPY table_number,
        o_rank               OUT NOCOPY table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * Get the vital sign rank define for the given view
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign             Vital sign ID
    * @param      i_flg_view                  Vital Signs View
    *
    * @return     Rank
    *
    * @author     Sofia Mendes
    * @version    2.6.2
    * @since      24-08-2012
    ***********************************************************************************************************/
    FUNCTION get_vital_sign_view_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign.id_vital_sign%TYPE,
        i_flg_view      IN VARCHAR2
    ) RETURN vs_soft_inst.rank%TYPE;
    --
    FUNCTION get_full_value
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_vsr         IN vital_sign_read.id_vital_sign_read%TYPE,
        i_vital_sign  IN vital_sign_read.id_vital_sign%TYPE,
        i_value       IN VARCHAR2,
        i_dt_read     IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_registry IN vital_sign_read.dt_registry%TYPE
    ) RETURN VARCHAR2;
    --
    /************************************************************************************************************
    * Get the vital sign type
    *
    * @param      i_vital_sign             Vital sign ID
    *
    * @return     Vital sign type
    *
    * @author     Alexandre Santos
    * @version    2.6.3
    * @since      08-03-2013
    ***********************************************************************************************************/
    FUNCTION get_vital_sign_type(i_vital_sign IN vital_sign.id_vital_sign%TYPE) RETURN VARCHAR2;
    --
    /**************************************************************************
    * Returns the data about a given vital sign, considering the unit measure
    * in use by the institution.
    *   
    * @param i_value                  Value to convert
    * @param i_vital_sign             Vital sign id
    * @param i_um_origin              Origin unit measure (u.m. of i_value)
    * @param i_um_dest                Destination unit measure (i_value will be converted to this u.m.)
    *
    * @return                         Converted value
    *                        
    * @author                         José Brito
    * @version                        2.6
    * @since                          19/01/2010
    **************************************************************************/
    FUNCTION get_unit_mea_conversion
    (
        i_value      IN vital_sign_read.value%TYPE,
        i_vital_sign IN vital_sign.id_vital_sign%TYPE,
        i_um_origin  IN triage_unit_mea_conversion.id_unit_measure_orig%TYPE,
        i_um_dest    IN triage_unit_mea_conversion.id_unit_measure_dest%TYPE
    ) RETURN NUMBER;
    --
    /************************************************************************************************************
    * Get the normal peak flow value for the given patient age, gender and height
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_pat_age                   patient age in years
    * @param      i_pat_gender                patient gender
    * @param      i_pat_height                patient height
    *
    * @return     Peak flow normal value 
    *
    * @author     Alexandre Santos
    * @version    2.6.3.6
    * @since      09-07-2013
    ***********************************************************************************************************/
    FUNCTION get_peak_flow_predict
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_pat_age    IN patient.age%TYPE,
        i_pat_gender IN patient.gender%TYPE,
        i_pat_height IN vital_sign_read.value%TYPE
    ) RETURN vital_sign_read.value%TYPE;
    --
    /************************************************************************************************************
    * Get the last read value for the given vital sign
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_episode                   episode id
    * @param      i_vital_sign                vital signid
    *
    * @return     Vital sign value if exists; Otherwise NULL
    *
    * @author     Alexandre Santos
    * @version    2.6.3.6
    * @since      15-07-2013
    ***********************************************************************************************************/
    FUNCTION get_vs_read_value
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_vital_sign IN vital_sign.id_vital_sign%TYPE
    ) RETURN vital_sign_read.value%TYPE;

    /**************************************************************************
    * Checks if it is possible to edit the vital sign value
    *
    * @param i_lang                    Language ID
    * @param i_prof                   Professional info
    * @param i_id_triage              Triage Identifier
    * @param i_flg_fill_type          Vital sign fill type
    * 
    * @return                         Flag read only two values available(Y/N) 
    * @author                         Sofia Mendes
    * @version                        2.6.3.7.1
    * @since                         14-8-2013
    **************************************************************************/
    FUNCTION is_vital_sign_read_only
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_triage  IN epis_triage.id_epis_triage%TYPE,
        i_flg_fill_type   IN vital_sign.flg_fill_type%TYPE,
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;
    /************************************************************************************************************
    * This function creates a record in the history table for vital signs read attributes
    *
    * @param        i_lang                       Language id
    * @param        i_prof                       Professional, software and institution ids
    * @param        i_id_vital_sign_read         Vital Sign Read ID
    * @param        i_id_vital_sign_read_hist    Vital sign Read hist ID
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013-11-19
    ************************************************************************************************************/
    FUNCTION set_vs_read_hist_atttrib
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_id_vital_sign_read_hist IN vital_sign_read_hist.id_vital_sign_read_hist%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the short description of the scale associated with the given vital sign scale element 
    *
    * @param      i_vs_scales_element      Vital sign scale element id
    *
    * @return     Vital sign scale id
    *
    * @author     Sofia Mendes
    * @version    2.6.3.9
    * @since      04/12/2013
    ************************************************************************************************************/
    FUNCTION get_vs_scale_short_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE
    ) RETURN pk_translation.t_desc_translation;
    /************************************************************************************************************
    * get_vs_value_dt_reg
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign_read        vital sign read identifier
    * @param      i_dt_vs_read                clinical date
    * @param      i_dt_registry               registered date
    *
    * @return     vital sign value
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2014/11/25
    ***********************************************************************************************************/
    FUNCTION get_vs_value_dt_reg
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_dt_vs_read         IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * get_vs_most_recent_value
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign             vital_sign identifier
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_dt_begin               Begin date   
    * @param      i_dt_end                 end date                             
    * @param      o_info                      cursor out
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2014/09/30
    ***********************************************************************************************************/
    FUNCTION get_vs_most_recent_value
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign_read.id_vital_sign%TYPE,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_dt_begin      IN VARCHAR2 DEFAULT NULL,
        i_dt_end        IN VARCHAR2 DEFAULT NULL,
        o_info          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION check_age
    (
        i_lang           IN language.id_language%TYPE,
        l_pat_age_months IN graphic.age_min%TYPE,
        l_pat_age_years  IN graphic.age_min%TYPE,
        i_type           IN graphic.flg_x_axis_type%TYPE,
        i_x_axis_start   IN graphic.x_axis_start%TYPE,
        i_x_axis_end     IN graphic.x_axis_end%TYPE,
        i_age_min        IN graphic.age_min%TYPE,
        i_age_max        IN graphic.age_min%TYPE
    ) RETURN VARCHAR2;
    --
    FUNCTION get_scale
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_vital_sign       IN vital_sign.id_vital_sign%TYPE,
        i_id_vital_sign_scale IN vital_sign_scales.id_vital_sign_scales%TYPE,
        o_scale               OUT pk_types.cursor_type,
        o_scale_elem          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vs_result
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_vs         IN table_number,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_result_value  OUT NUMBER,
        o_result_um     OUT unit_measure.id_unit_measure%TYPE
    ) RETURN BOOLEAN;

    FUNCTION get_vs_result_count
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_vs         IN table_number,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN INTEGER;

    FUNCTION get_vs_result
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_mtos_param IN mtos_param.id_mtos_param%TYPE,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_vs_result_um
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_mtos_param IN mtos_param.id_mtos_param%TYPE,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER;

    /**
    * Set BMI vital sign
    *
    * @param i_lang           Language identifier
    * @param i_prof           Logged professional structure
    * @param i_id_episode     Episode id
    * @param i_id_patient     Patient id
    * @param i_id_vital_sign_read     Vital sign read id
    * @param o_error          Error information 
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @raises                PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.3.5
    * @since                2018-06-18
    */
    FUNCTION set_vs_bmi_auto
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE get_monit_init_parameters
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );
    --
    c_edit_type_cancel CONSTANT VARCHAR2(1 CHAR) := 'C';
    c_edit_type_edit   CONSTANT VARCHAR2(1 CHAR) := 'E';

    c_flg_status_active    CONSTANT VARCHAR2(1 CHAR) := 'A';
    c_flg_status_cancelled CONSTANT VARCHAR2(1 CHAR) := 'C';

    -- type of content to be returned in the detail/history screens
    g_title_t       CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_content_c     CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_signature_s   CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_new_content_n CONSTANT VARCHAR2(1 CHAR) := 'N';

    --detail null value
    g_detail_empty CONSTANT VARCHAR2(3) := '---';

    --FLGS to identify the detail/history screens
    g_detail_screen_d      CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_hist_screen_h        CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_detail_line_screen_l CONSTANT VARCHAR2(1 CHAR) := 'L';

    --FLGS to identify the fill type
    g_fill_type_multichoice CONSTANT VARCHAR2(1 CHAR) := 'V';
    g_fill_type_read_only   CONSTANT VARCHAR2(1 CHAR) := 'R';

    g_vs_height       CONSTANT VARCHAR2(2 CHAR) := 30;
    g_vs_weight       CONSTANT VARCHAR2(2 CHAR) := 29;
    g_vs_bmi          CONSTANT VARCHAR2(4 CHAR) := 1188;
    g_vs_bsa          CONSTANT VARCHAR2(4 CHAR) := 1316;
    g_vs_birth_weight CONSTANT VARCHAR2(5 CHAR) := 10731;
    g_vs_glasgowtotal CONSTANT vital_sign_read.id_vital_sign%TYPE := 18;

    --API's for Viewer
    g_flg_scope_summary_s CONSTANT VARCHAR2(1 CHAR) := 'S'; --Summary 1.st level (last VS or Indicator)
    g_flg_scope_detail_d  CONSTANT VARCHAR2(1 CHAR) := 'D'; --Detailed 2.nd level (Last VS or Indicator by each one)

    g_sm_vs_viewer CONSTANT sys_message.code_message%TYPE := 'VITAL_SIGNS_READ_T020';

    g_interval_last24h_d VARCHAR2(1 CHAR) := 'D';
    g_interval_week_w    VARCHAR2(1 CHAR) := 'W';
    g_interval_month_m   VARCHAR2(1 CHAR) := 'M';
    g_interval_all_a     VARCHAR2(1 CHAR) := 'A';

    g_vs_type_parent VARCHAR2(1 CHAR) := 'P';
    g_vs_type_child  VARCHAR2(1 CHAR) := 'C';
    g_vs_type_normal VARCHAR2(1 CHAR) := 'N';

    g_trs_notes_edit CONSTANT VARCHAR2(50 CHAR) := 'ALERT.VITAL_SIGN_READ.CODE_NOTES_EDIT.';
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
END pk_vital_sign;
/
