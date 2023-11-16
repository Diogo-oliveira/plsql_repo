/*-- Last Change Revision: $Rev: 2028573 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:36 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_complication_core IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 18-12-2009 10:25:47
    -- Purpose : Complication logic

    -- Public type declarations
    TYPE epis_comp_rec IS RECORD(
        id_epis_complication epis_complication.id_epis_complication%TYPE,
        id_epis_comp_hist    epis_comp_hist.id_epis_comp_hist%TYPE,
        id_episode           epis_complication.id_episode%TYPE,
        id_episode_origin    epis_complication.id_episode%TYPE,
        desc_episode_origin  VARCHAR2(4000 CHAR),
        id_complication      epis_complication.id_complication%TYPE,
        desc_complication    pk_translation.t_desc_translation,
        description          epis_complication.description%TYPE,
        dt_verif_comp        epis_complication.dt_verif_comp%TYPE,
        dt_verif_comp_desc   VARCHAR2(4000 CHAR),
        dt_verif_req         epis_complication.dt_verif_req%TYPE,
        dt_verif_req_desc    VARCHAR2(4000 CHAR),
        id_clin_serv_dest    epis_complication.id_clin_serv_dest%TYPE,
        desc_clin_serv_dest  pk_translation.t_desc_translation,
        flg_status_comp      epis_complication.flg_status_comp%TYPE,
        desc_flg_stat_comp   sys_domain.desc_val%TYPE,
        flg_status_req       epis_complication.flg_status_req%TYPE,
        desc_flg_stat_req    sys_domain.desc_val%TYPE,
        notes_comp           epis_complication.notes_comp%TYPE,
        notes_req            epis_complication.notes_req%TYPE,
        id_cancel_reason     epis_complication.id_cancel_reason%TYPE,
        desc_cancel_reason   pk_translation.t_desc_translation,
        notes_cancel         epis_complication.notes_cancel%TYPE,
        id_reject_reason     epis_complication.id_reject_reason%TYPE,
        desc_reject_reason   pk_translation.t_desc_translation,
        notes_rejected       epis_complication.notes_rejected%TYPE,
        id_prof_create       epis_complication.id_prof_create%TYPE,
        prof_create_name     professional.name%TYPE,
        id_prof_clin_serv    epis_complication.id_prof_clin_serv%TYPE,
        desc_prof_clin_serv  pk_translation.t_desc_translation,
        dt_epis_complication epis_complication.dt_epis_complication%TYPE,
        dt_epis_comp_desc    VARCHAR2(4000 CHAR));

    TYPE epis_comp_def_rec IS RECORD(
        id_complication comp_config.id_complication%TYPE,
        id_comp_axe     comp_axe.id_comp_axe%TYPE,
        lst_ids         VARCHAR2(32767 CHAR),
        lst_descs       VARCHAR2(32767 CHAR),
        lvl             NUMBER(24),
        flg_is_last_lvl VARCHAR2(1 CHAR));

    TYPE epis_comp_def_cursor IS REF CURSOR RETURN epis_comp_def_rec;

    -- Public variable declarations
    e_action_subj_not_available EXCEPTION;
    e_cfg_vars_not_defined      EXCEPTION;
    e_array_size_dont_match     EXCEPTION;
    e_arrays_size_dont_match    EXCEPTION;
    e_wrong_column_name         EXCEPTION;
    e_not_a_number              EXCEPTION;
    e_not_a_date                EXCEPTION;
    e_not_a_flag                EXCEPTION;
    e_required_field            EXCEPTION;
    e_invalid_flg_state         EXCEPTION;
    e_general_error             EXCEPTION;

    --EPIS_COMPLICATION_TYPE
    g_epis_comp_typ_c CONSTANT VARCHAR2(1 BYTE) := 'C'; --Complication
    g_epis_comp_typ_r CONSTANT VARCHAR2(1 BYTE) := 'R'; --Request

    --LIST GROUPS
    g_lst_grp_axe_types     CONSTANT sys_list_group.internal_name%TYPE := 'COMPLICATION_AXE_TYPES';
    g_lst_grp_axe_at_types  CONSTANT sys_list_group.internal_name%TYPE := 'COMPLICATION_AXE_AT_TYPES';
    g_lst_grp_axe_tp_types  CONSTANT sys_list_group.internal_name%TYPE := 'COMPLICATION_AXE_TP_TYPES';
    g_lst_grp_cols_vis_comp CONSTANT sys_list_group.internal_name%TYPE := 'COMPLICATION_COLUMNS_VISIBILITY';
    g_lst_grp_cols_vis_req  CONSTANT sys_list_group.internal_name%TYPE := 'COMPLICATION_REQUEST_COLUMNS_VISIBILITY';
    g_lst_grp_cfg_type      CONSTANT sys_list_group.internal_name%TYPE := 'COMPLICATION_CONFIG_TYPE';
    g_lst_grp_cfg_dft_type  CONSTANT sys_list_group.internal_name%TYPE := 'COMPLICATION_CONFIG_DFT_TYPE';
    g_lst_grp_ecd_at_types  CONSTANT sys_list_group.internal_name%TYPE := 'COMPLICATION_DETAIL_CONTEXT_TYPE_ASSOC_TASK';
    g_lst_grp_ecd_tp_types  CONSTANT sys_list_group.internal_name%TYPE := 'COMPLICATION_DETAIL_CONTEXT_TYPE_TREAT_PERF';

    --CONFIGURATION TYPEs
    g_flg_cfg_typ_complication CONSTANT sys_list_group_rel.flg_context%TYPE := 'C'; -- Complication
    g_flg_cfg_typ_axe          CONSTANT sys_list_group_rel.flg_context%TYPE := 'A'; -- Axe
    g_flg_cfg_typ_assoc_task   CONSTANT sys_list_group_rel.flg_context%TYPE := 'AT'; -- Associated task 
    g_flg_cfg_typ_treat_perf   CONSTANT sys_list_group_rel.flg_context%TYPE := 'TP'; -- Treatment Performed   
    --DEFAULT
    g_flg_cfg_typ_def_comp_path CONSTANT sys_list_group_rel.flg_context%TYPE := 'DP'; -- Default complication pathology
    g_flg_cfg_typ_def_comp_loc  CONSTANT sys_list_group_rel.flg_context%TYPE := 'DL'; -- Default complication location
    g_flg_cfg_typ_def_comp_et   CONSTANT sys_list_group_rel.flg_context%TYPE := 'DE'; -- Default complication external factor

    --COMP_AXE TYPEs
    g_flg_axe_type_comp_cat      CONSTANT sys_list_group_rel.flg_context%TYPE := 'CC'; -- Complication categories
    g_flg_axe_type_path          CONSTANT sys_list_group_rel.flg_context%TYPE := 'P'; -- Pathology
    g_flg_axe_type_loc           CONSTANT sys_list_group_rel.flg_context%TYPE := 'L'; -- Location
    g_flg_axe_type_ext_fact      CONSTANT sys_list_group_rel.flg_context%TYPE := 'EF'; -- External Factors
    g_flg_axe_type_ext_fact_med  CONSTANT sys_list_group_rel.flg_context%TYPE := 'FM'; -- External Factors
    g_flg_axe_type_ext_fact_tool CONSTANT sys_list_group_rel.flg_context%TYPE := 'FT'; -- External Factors
    g_flg_axe_type_eff           CONSTANT sys_list_group_rel.flg_context%TYPE := 'E'; -- Effect
    -- associated_task
    g_flg_axe_type_at_undefined CONSTANT sys_list_group_rel.flg_context%TYPE := 'TU'; -- undefined
    g_flg_axe_type_at_lab_test  CONSTANT sys_list_group_rel.flg_context%TYPE := 'TA'; -- Lab test
    g_flg_axe_type_at_diet      CONSTANT sys_list_group_rel.flg_context%TYPE := 'TD'; -- Diet
    g_flg_axe_type_at_imaging   CONSTANT sys_list_group_rel.flg_context%TYPE := 'TI'; -- Imaging
    g_flg_axe_type_at_exam      CONSTANT sys_list_group_rel.flg_context%TYPE := 'TE'; -- Exam
    g_flg_axe_type_at_med       CONSTANT sys_list_group_rel.flg_context%TYPE := 'TM'; -- Medication
    g_flg_axe_type_at_pos       CONSTANT sys_list_group_rel.flg_context%TYPE := 'TP'; -- Positioning
    g_flg_axe_type_at_dressing  CONSTANT sys_list_group_rel.flg_context%TYPE := 'TW'; -- Dressing
    g_flg_axe_type_at_proc      CONSTANT sys_list_group_rel.flg_context%TYPE := 'TR'; -- Procedure
    g_flg_axe_type_at_surg_proc CONSTANT sys_list_group_rel.flg_context%TYPE := 'TS'; -- Surgical procedure
    -- treatment performed
    g_flg_axe_type_tp_lab_test    CONSTANT sys_list_group_rel.flg_context%TYPE := 'XA'; -- Lab test
    g_flg_axe_type_tp_imaging     CONSTANT sys_list_group_rel.flg_context%TYPE := 'XI'; -- Imaging
    g_flg_axe_type_tp_exam        CONSTANT sys_list_group_rel.flg_context%TYPE := 'XE'; -- Exam
    g_flg_axe_type_tp_med_grp     CONSTANT sys_list_group_rel.flg_context%TYPE := 'XM'; -- Medication (group)
    g_flg_axe_type_tp_med         CONSTANT sys_list_group_rel.flg_context%TYPE := 'XL'; -- Medication
    g_flg_axe_type_tp_out_med_grp CONSTANT sys_list_group_rel.flg_context%TYPE := 'XG'; -- Outside medication (group)
    g_flg_axe_type_tp_out_med     CONSTANT sys_list_group_rel.flg_context%TYPE := 'XX'; -- Outside medication
    g_flg_axe_type_tp_pos         CONSTANT sys_list_group_rel.flg_context%TYPE := 'XP'; -- Positioning
    g_flg_axe_type_tp_proc        CONSTANT sys_list_group_rel.flg_context%TYPE := 'XR'; -- Procedure
    g_flg_axe_type_tp_surg_proc   CONSTANT sys_list_group_rel.flg_context%TYPE := 'XS'; -- Surgical procedure

    --Other context values
    g_flg_ecd_context_type_med_lcl CONSTANT sys_list_group_rel.flg_context%TYPE := 'TL'; -- Medication (Local)
    g_flg_ecd_context_type_med_ext CONSTANT sys_list_group_rel.flg_context%TYPE := 'TX'; -- Medication (Exterior)
    g_flg_ecd_context_type_pos     CONSTANT sys_list_group_rel.flg_context%TYPE := 'TO'; -- SR positioning

    -- Public function and procedure declarations
    PROCEDURE set_pck_sysdate(i_date TIMESTAMP WITH LOCAL TIME ZONE);
    FUNCTION get_pck_sysdate RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    --CONFIGURATION TYPEs
    FUNCTION get_cfg_typ_complication
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_cfg_typ_axe
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_cfg_typ_def_comp_path
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_cfg_typ_def_comp_loc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_cfg_typ_def_comp_ext_fact
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_cfg_typ_assoc_task
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_cfg_typ_treat_perf
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    --COMP_AXE TYPEs
    FUNCTION get_axe_typ_comp_cat
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_path
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_loc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_ext_fact
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_ext_fact_med
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_ext_fact_tool
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_eff
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    -- associated_task
    FUNCTION get_axe_typ_at_und
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_at_lab_test
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_at_diet
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_at_imaging
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_at_exam
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_at_med
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_at_pos
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_at_dressing
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_at_proc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_at_surg_proc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    -- other context values
    FUNCTION get_ecd_typ_med_lcl
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_ecd_typ_med_ext
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_ecd_typ_pos
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    -- treatment_performed
    FUNCTION get_axe_typ_tp_lab_test
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_tp_imaging
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_tp_exam
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_tp_med_grp
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_tp_med
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_tp_out_med_grp
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_tp_out_med
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_tp_pos
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_tp_proc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    FUNCTION get_axe_typ_tp_surg_proc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_list.id_sys_list%TYPE;

    /**
    * Verifies if the specified column is visible to the current user
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_ec_clin_serv_dest         Episode complication clinical service dest
    * @param   i_ec_prof_clin_serv         Episode complication register prof clinical service
    * @param   i_column_name               Column name
    * @param   i_is_request                'Y' - request; 'N' - complication
    *
    * @return  'Y' if column is visible, 'N' otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION is_column_visible
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ec_clin_serv_dest IN epis_complication.id_clin_serv_dest%TYPE,
        i_ec_prof_clin_serv IN epis_complication.id_prof_clin_serv%TYPE,
        i_column_name       IN VARCHAR2,
        i_is_request        IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * Gets the current user action options for the given epis_complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   i_type                      C - Complication; R - Request
    *
    * @return  Action subject if the user has actions otherwise returns null
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   05-01-2010
    */
    FUNCTION get_action_subject
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_type              IN VARCHAR2
    ) RETURN table_varchar;

    /**
    * Verifies if the user has actions available
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   i_type                      C - Complication; R - Request
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   05-01-2010
    */
    FUNCTION is_action_btn_available
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_type              IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Verifies if the user can edit or cancel the complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   i_type                      C - Complication; R - Request
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   05-01-2010
    */
    FUNCTION is_possible_to_edt_cnc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_type              IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Get the professional name
    *
    * @param   i_lang             language
    * @param   i_prof             professional, institution and software ids
    * @param   i_prof_id          professional id
    *
    * @return  professional name
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-02-2010
    */
    FUNCTION get_prof_name
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN professional.name%TYPE;

    /**
    * Verifies if is to show the code in complications lists
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    *
    * @return  'Y' if is to show, 'N' otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-03-2010
    */
    FUNCTION is_to_show_code
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    /**
    * Gets the list of complications for the given episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_complications             List of complications for the given episode
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-12-2009
    */
    FUNCTION get_epis_complications
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        o_complications OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the names of professionals associated with a request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_comp                 Episode complication id
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   23-12-2009
    */
    FUNCTION get_req_prof_names
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_comp IN epis_comp_prof.id_epis_complication%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get the last request registry date
    *
    * @param   i_epis_comp                 Episode complication id
    *
    * @return  request registry date
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION get_req_registry_dt(i_epis_comp IN epis_complication.id_epis_complication%TYPE)
        RETURN epis_complication.dt_epis_complication%TYPE;

    /**
    * Gets the list of requests for the given episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_requests                  List of requests for the given episode
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since 07 - 12 - 2009 
    */
    FUNCTION get_epis_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the list of complication specific button actions
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   i_type                      C - Complication; R - Request
    * @param   i_subject                   Subject: CREATE - Button create options; ACTION - Button action options
    * @param   o_actions                   List of actions
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   07-12-2009
    */
    FUNCTION get_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_type              IN VARCHAR2,
        i_subject           IN action.subject%TYPE,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the configuration variables: inst, soft and clin serv
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cfg_type                  Configuration type
    * @param   i_axe_type                  Axe type
    * @param   o_inst                      institution id
    * @param   o_soft                      software id
    * @param   o_clin_serv                 clinical service id
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @value   i_cfg_type                  Complication
    *                                      Axe
    *                                      Associated task or Treatment Performed
    *                                      Default complication pathology
    *                                      Default complication location
    *                                      Default complication External factor
    *
    * @value   i_axe_type                  Pathology
    *                                      Location
    *                                      External Factors
    *                                      Effect
    *                           ASSOCIATED TASKS
    *                                      Lab test
    *                                      Diet
    *                                      Imaging
    *                                      Exam
    *                                      Medication
    *                                      Positioning
    *                                      Dressing
    *                                      Procedure
    *                                      Surgical procedure
    *                           TREATMENTS PERFORMED
    *                                      Lab test
    *                                      Imaging
    *                                      Exam
    *                                      Medication (group)
    *                                      Medication
    *                                      Outside medication (group)
    *                                      Outside medication
    *                                      Positioning
    *                                      Procedure
    *                                      Surgical procedure
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   10-12-2009
    */
    FUNCTION get_cfg_vars
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_cfg_type  IN comp_config.id_sys_list%TYPE,
        i_axe_type  IN comp_axe.id_sys_list%TYPE DEFAULT NULL,
        o_inst      OUT comp_config.id_institution%TYPE,
        o_soft      OUT comp_config.id_software%TYPE,
        o_clin_serv OUT comp_config.id_clinical_service%TYPE,
        o_error     OUT NOCOPY t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the specified selection list type
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_type                      Type of list to be returned
    * @param   i_parent_axe                Parent axe id or NULL to get root values
    * @param   o_axes                      List of pathologies/locations/external factors/effects
    * @param   o_max_level                 Maximum level that has this type of lis
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @value   i_type                      P  - Pathology
    *                                      L  - Location
    *                                      EF - External factor
    *                                      E  - Effect
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   09-12-2009
    */
    FUNCTION get_axes_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type       IN sys_list_group_rel.flg_context%TYPE,
        i_parent_axe IN comp_axe.id_comp_axe%TYPE,
        o_axes       OUT pk_types.cursor_type,
        o_max_level  OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets selection list type groups
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_type                      Type of list to be returned
    * @param   o_groups                    List of pathologies/locations/external factors/effects
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @value   i_type                      P  - Pathology
    *                                      L  - Location
    *                                      EF - External factor
    *                                      E  - Effect
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-03-2009
    */
    FUNCTION get_axes_grp_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_type   IN sys_list_group_rel.flg_context%TYPE,
        o_groups OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get list of axe levels
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_prof                     Professional ID
    * @param   i_sys_list                 Type of axe 
    *
    * @RETURN  Axe levels table
    * @author  Alexandre Santos
    * @version 1.0
    * @since   16-03-2010
    *
    */
    FUNCTION tf_comp_axe_lvl
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_sys_list IN comp_axe.id_sys_list%TYPE
    ) RETURN t_table_comp_axe_lvl
        PIPELINED;

    /**
    * Gets the complication selection list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_complications             List of complications
    * @param   o_def_path                  List of default pathologies
    * @param   o_def_loc                   List of default locations
    * @param   o_def_ext_fact              List of default external factors
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   09-12-2009
    */
    FUNCTION get_complication_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_complications OUT pk_types.cursor_type,
        o_def_path      OUT pk_complication_core.epis_comp_def_cursor,
        o_def_loc       OUT pk_complication_core.epis_comp_def_cursor,
        o_def_ext_fact  OUT pk_complication_core.epis_comp_def_cursor,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the complication selection list (Without default values)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_complications             List of complications
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   23-03-2010
    */
    FUNCTION get_complication_lst
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_complications OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the complication default values lists
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_complication              Complication id
    * @param   o_def_path                  List of default pathologies
    * @param   o_def_loc                   List of default locations
    * @param   o_def_ext_fact              List of default external factors
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   23-03-2010
    */
    FUNCTION get_complication_dft_lst
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_complication IN complication.id_complication%TYPE,
        o_def_path     OUT pk_complication_core.epis_comp_def_cursor,
        o_def_loc      OUT pk_complication_core.epis_comp_def_cursor,
        o_def_ext_fact OUT pk_complication_core.epis_comp_def_cursor,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets episode description label
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    *
    * @return  Episode description label
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   05-01-2010
    */
    FUNCTION get_episode_description
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN epis_complication.id_episode_origin%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get complication data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   o_complication              All complication data
    * @param   o_comp_detail               All complication detail data
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-01-2010
    */
    FUNCTION get_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        o_complication      OUT pk_types.cursor_type,
        o_comp_detail       OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets previous record date for the same axe type
    *
    * @param   i_epis_comp                 Epis complication id
    * @param   i_flg_type                  Comp axe type
    * @param   i_cur_date                  Date of the current record
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-03-2010
    */
    FUNCTION get_prev_ecd_dt
    (
        i_epis_comp IN epis_comp_detail.id_epis_complication%TYPE,
        i_flg_type  IN comp_axe.id_sys_list%TYPE,
        i_cur_date  IN epis_comp_detail.dt_epis_comp_detail%TYPE
    ) RETURN epis_comp_detail.dt_epis_comp_detail%TYPE;

    /**
    * Gets previous professional record date
    *
    * @param   i_epis_comp                 Epis complication id
    * @param   i_cur_date                  Date of the current record
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-03-2010
    */
    FUNCTION get_prev_ecp_dt
    (
        i_epis_comp IN epis_comp_prof.id_epis_complication%TYPE,
        i_cur_date  IN epis_comp_prof.dt_epis_comp_prof%TYPE
    ) RETURN epis_comp_prof.dt_epis_comp_prof%TYPE;

    /**
    * Gets complication detail data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   o_complication              All complication data
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-01-2010
    */
    FUNCTION get_complication_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        o_complication      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets request data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   o_request                   All request data
    * @param   o_request_detail            All request detail data
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-01-2010
    */
    FUNCTION get_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        o_request           OUT pk_types.cursor_type,
        o_request_detail    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the epis_comp_detail id's that must go to history
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis_comp_detail ID
    * @param   i_comp_axe                  Comp_axe ID
    * @param   o_epis_comp_detail          Id's that must go to hist
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   26-02-2010
    */
    FUNCTION get_epis_comp_detail_to_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_comp_detail.id_epis_complication%TYPE,
        i_comp_axe          IN epis_comp_detail.id_comp_axe%TYPE,
        i_type              IN sys_list.id_sys_list%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Add/Upd a complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   i_is_ins                    True - Is to insert a new complication, Otherwise is to update a existing complication
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION set_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        i_is_ins            IN BOOLEAN,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Add/Upd a complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   i_is_ins                    True - Is to insert a new complication request, Otherwise is to update a existing complication request
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   23-12-2009
    */
    FUNCTION set_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        i_is_ins            IN BOOLEAN,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of tasks to associate with the complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
    * @param   o_type_tasks                Type of tasks
    * @param   o_tasks                     Tasks list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   04-01-2010
    ********************************************************************************************/
    FUNCTION get_assoc_task_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_type_tasks OUT pk_types.cursor_type,
        o_tasks      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the type of treatments to associate with the complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_treat                     Types of treatment
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   04-01-2010
    ********************************************************************************************/
    FUNCTION get_treat_perf_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_treat OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel a complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis complication id
    * @param   i_cancel_reason             Cancel reason id
    * @param   i_notes_cancel              Cancelation notes
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION cancel_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_cancel_reason     IN epis_complication.id_cancel_reason%TYPE,
        i_notes_cancel      IN epis_complication.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel a complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis complication id
    * @param   i_cancel_reason             Cancel reason id
    * @param   i_notes_cancel              Cancelation notes
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION cancel_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_cancel_reason     IN epis_complication.id_cancel_reason%TYPE,
        i_notes_cancel      IN epis_complication.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Reject a complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis complication id
    * @param   i_reject_reason             Reject reason id
    * @param   i_notes_reject              Reject notes
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION set_reject_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_reject_reason     IN epis_complication.id_reject_reason%TYPE,
        i_notes_reject      IN epis_complication.notes_rejected%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Accept the request and insert complication data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   07-01-2010
    */
    FUNCTION set_accept_request
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_cols  IN table_varchar,
        i_vals  IN table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets discharge confirmation message
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_show                      Y - Confirmation message is to be shown; Otherwise N
    * @param   o_title                     Confirmation title
    * @param   o_quest                     Confirmation question
    * @param   o_msg                       Confirmation message
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-02-2010
    */
    FUNCTION get_disch_conf_msg
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_show    OUT VARCHAR2,
        o_title   OUT VARCHAR2,
        o_quest   OUT VARCHAR2,
        o_msg     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the clinical services list to which the current professional is allocated
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_clin_serv                 Clinical services list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   01-03-2010
    */
    FUNCTION get_prof_clin_serv_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get domain values
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_code_dom                  Element domain
    * @param   i_dep_clin_serv             Dep_clin_serv ID                                                              
    * @param   o_data                      Domain values list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-03-2010
    */
    FUNCTION get_domain_values
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @author                Alexandre Santos
    * @version               2.6
    * @since                 21-04-2010
    ********************************************************************************************/
    FUNCTION match_complications
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets professional that created the request/complication
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_epis_comp     Episode complication ID
    * @param i_type          'R' - Request; 'C' - Complication
    *
    * @return                Table of epis_comp_prof_create
    *
    * @author                Alexandre Santos
    * @version               2.6
    * @since                 06-05-2010
    ********************************************************************************************/
    FUNCTION tf_epis_comp_prof_create
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_comp IN epis_complication.id_epis_complication%TYPE,
        i_type      IN VARCHAR2
    ) RETURN t_table_epis_comp_prof_create
        PIPELINED;
END pk_complication_core;
/
