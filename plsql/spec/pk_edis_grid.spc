/*-- Last Change Revision: $Rev: 2028660 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:10 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_edis_grid AS
    TYPE p_action_rec IS RECORD(
        id_action     action.id_action%TYPE,
        id_parent     action.id_parent%TYPE,
        LEVEL         NUMBER,
        from_state    action.from_state%TYPE,
        to_state      action.to_state%TYPE,
        desc_action   pk_translation.t_desc_translation,
        icon          action.icon%TYPE,
        flg_default   action.flg_default%TYPE,
        flg_status    action.flg_status%TYPE,
        internal_name action.internal_name%TYPE);

    TYPE p_action_cur IS REF CURSOR RETURN p_action_rec;

    /**********************************************************************************************
    * Grelha do médico, para visualizar os seus pacientes
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all episodes - c/ ou s/ alta médica, sem alta administrativa ou com alta administrativa
                                                                 se ainda tiverem workflow pendente.
    * @param o_flg_disch_pend         flag que determina se a alta pendente aparece ou nao na grelha
                                               N- aparece tranportes Y- pararece a alta pendente
    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/05/30
    **********************************************************************************************/
    FUNCTION get_grid_my_pat_doc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_grid           OUT pk_types.cursor_type,
        o_flg_disch_pend OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Grelha do médico, para visualizar todos os pacientes alocados ás suas salas
      Nesta grelha visualizam-se todos os episódios : - c/ ou s/ alta médica,
      sem alta administrativa ou com alta administrativa se ainda tiverem workflow pendente.
    
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all episodes - cursor with all episodes - c/ ou s/ alta médica, sem alta administrativa ou com alta administrativa
                                                                 se ainda tiverem workflow pendente.
    * @param o_flg_disch_pend         flag que determina se a alta pendente aparece ou nao na grelha
                                               N- aparece tranportes Y- pararece a alta pendente
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/05/30
    **********************************************************************************************/
    FUNCTION get_grid_all_pat_doc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_grid           OUT pk_types.cursor_type,
        o_flg_disch_pend OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Grelha do médico, para visualizar todos os pacientes alocados á sala seleccionada
    *
    * @param i_lang                   the id language
    * @param i_room                   room id
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/05/31
    **********************************************************************************************/
    FUNCTION get_grid_room_pat_doc
    (
        i_lang  IN language.id_language%TYPE,
        i_room  IN room.id_room%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Grelha para visualizar todas as salas e para cada sala todos os:
                         - pacientes (masculino)
                         - pacientes (Feminino)
                         - profissionais
                         - enfermeiros
                         - auxiliares
                         e respectivo total de pacientes (H e M) por sala, caso exista.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all rooms
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/05/31
    **********************************************************************************************/
    FUNCTION get_grid_all_rooms
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    *  Listagem gráfica de todas as salas onde para cada uma se visualiza:
                         - Total de pacientes
                         - Capacidade máxima da sala
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all rooms
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/06/01
    **********************************************************************************************/
    FUNCTION get_chart_all_rooms
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    *  Listagem gráfica para um dado profissional de todos os seus pacientes
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/06/22
    **********************************************************************************************/
    FUNCTION get_chart_my_pat_doc
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    *  Listagem gráfica de todos os pacientes alocados ás salas de um médico
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/06/19
    **********************************************************************************************/
    FUNCTION get_chart_all_pat_doc
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listagem gráfica de todos os pacientes alocados numa sala
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_room                   room id
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/06/19
    **********************************************************************************************/
    FUNCTION get_chart_room_pat_doc
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN room.id_room%TYPE,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Grelha do enfermeiro para visualizar os seus pacientes
      Nesta grelha visualizam-se todos os episódios : - c/ ou s/ alta médica, sem alta administrativa ou com alta administrativa se ainda tiverem workflow pendente.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/09/12
    **********************************************************************************************/
    FUNCTION get_grid_my_pat_nurse
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_grid           OUT pk_types.cursor_type,
        o_flg_disch_pend OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Grelha do auxiliar para visualizar os seus pacientes
      Nesta grelha visualizam-se todos os episódios : - c/ ou s/ alta médica,
      sem alta administrativa ou com alta administrativa se ainda tiverem workflow pendente.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/10/02
    **********************************************************************************************/
    FUNCTION get_grid_all_pat_aux
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Grelha do auxiliar para visualizar todos os pacientes alocados á sala seleccionada
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_room                   room id
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/05/31
    **********************************************************************************************/
    FUNCTION get_grid_room_aux_doc
    (
        i_lang  IN language.id_language%TYPE,
        i_room  IN room.id_room%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter a última queixa do episódio tendo em conta se estamos perante a documentation ou não.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_epis                   episode id
    *
    * @return                         description
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/10/10
    **********************************************************************************************/
    FUNCTION get_complaint_grid
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE,
        i_sep  IN VARCHAR2 DEFAULT ', '
    ) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Obter a última queixa do episódio tendo em conta se estamos perante a documentation ou não.
    *
    * @param i_lang                   the id language
    * @param i_inst                   institution id
    * @param i_soft                   software id
    * @param i_epis                   episode id
    *
    * @return                         description
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/10/23
    **********************************************************************************************/
    FUNCTION get_complaint_grid
    (
        i_lang IN language.id_language%TYPE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE,
        i_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Grelha do triador, para visualizar todos os pacientes alocados ás suas salas
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/01/27
    **********************************************************************************************/
    FUNCTION get_grid_all_pat_triage
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * This function picks up an id_disch_reas_dest from a patient's discharge and
    * returns the destination description if the discharge was a service transfer of an
    * inpatient admission. Theis description is shown in the administrative's grid.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_disch_reas_dest        id of the record of discharge destination for a given patient
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         João Eiras
    * @version                        1.0
    * @since                          2008/01/16
    **********************************************************************************************/
    FUNCTION get_label_follow_up_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_disch_reas_dest IN discharge.id_disch_reas_dest%TYPE,
        i_prof_cat        IN category.flg_type%TYPE
    ) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Returns the destination description if the discharge was a service transfer of an
    * inpatient admission. This description is shown in the administrative's grid.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        2.5.1.2
    * @since                          17/02/2011
    **********************************************************************************************/
    FUNCTION get_label_follow_up
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN discharge.id_disch_reas_dest%TYPE,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Grelha do administrativo, para visualizar todos os pacientes alocados ás suas salas
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_grid                   cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luis Gaspar
    * @version                        1.0
    * @since                          2007/02/14
    **********************************************************************************************/
    FUNCTION get_grid_all_pat_admin
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Verify if flg_letter is to be used in the ORDER BY clause.
    *
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         'Y' is to be used, 'N' otherwise
    *
    * @author                         Alexandre Santos
    * @version                        1.0
    * @since                          2009/05/14
    **********************************************************************************************/
    FUNCTION orderby_flg_letter(i_prof IN profissional) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Gets all configs that affect the patients grid
    *
    * @param i_lang                   language ID
    * @param i_code_cf                configurations code array
    * @param i_prof                   professional, software and institution ids
    * @param o_msg_cf                 grid configurations
    * @param o_label_tb_name_col      Tracking view: label for the patient's name column showing origin or chief complaint
    * @param o_label_responsibles     Label for the patient's responsibles, showing medical teams or the resident physician
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2009/11/12
    **********************************************************************************************/
    FUNCTION get_grid_config
    (
        i_lang               IN language.id_language%TYPE,
        i_code_cf            IN table_varchar,
        i_prof               IN profissional,
        o_msg_cf             OUT pk_types.cursor_type,
        o_label_tb_name_col  OUT VARCHAR2,
        o_label_responsibles OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the header labels for the patient grids for the patients and responsibles columns.
    *
    * @param i_lang                   language ID
    * @param i_prof                   professional, software and institution ids
    * @param o_label_tb_name_col      Tracking view: label for the patient's name column showing origin or chief complaint
    * @param o_label_responsibles     Label for the patient's responsibles, showing medical teams or the resident physician
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Brito
    * @version                        2.6.0.5
    * @since                          2011/01/26
    **********************************************************************************************/
    FUNCTION get_grid_labels
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_label_tb_name_col  OUT VARCHAR2,
        o_label_responsibles OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /**********************************************************************************************
    * Difference between current date and beging of episode
    *
    * @param i_lang                   Language ID
    * @param i_dt_begin_epis          Episode begin date
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        1.0
    * @since                          2010/09/03
    **********************************************************************************************/
    FUNCTION get_los
    (
        i_lang          IN language.id_language%TYPE,
        i_dt_begin_epis IN episode.dt_begin_tstz%TYPE
    ) RETURN NUMBER;
    --
    /**********************************************************************************************
    * Gets either the EDIS or OBS id_episode depending on configurations
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             EDIS id_episode
    * @param i_id_episode_obs         OBS id_episode
    *
    * @return                         the episode ID that must be shown in the admin grid
    *
    * @author                         José Silva
    * @version                        2.5.1.2.1
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION get_admin_id_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_episode_obs IN episode.id_episode%TYPE
    ) RETURN episode.id_episode%TYPE;

    PROCEDURE initialize_params
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**********************************************************************************************
    * Gets the actions for the EDIS grids
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution Ids
    * @param i_subject                Actions Subject
    * @param i_from_state             OBS State
    *
    * @param o_actions                Actions cursor
    *
    * @return                         true/false
    *
    * @author                         Sergio Dias
    * @version                        2.6.3.5.1
    * @since                          6/6/2013
    **********************************************************************************************/
    FUNCTION get_actions_edis_grids
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT p_action_cur,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_length_of_stay_color
    (
        i_prof  IN profissional,
        i_hours IN NUMBER
        
    ) RETURN VARCHAR2;

    FUNCTION get_grid_origin
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_origin IN origin.id_origin%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the abbrevieted description of origin
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_origin          origin id
    *
    * @return                  origin abbreviation
    *
    * @author                  Anna Kurowska
    * @version                 1.0
    * @since                   06-09-2016
     **********************************************************************************************/
    FUNCTION get_grid_origin_abbrev
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_origin IN origin.id_origin%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the full description about patient origin and cheif complaint to be used in tooltip
    * Consists of origin, chief complain
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_visit           visit ID
    * @param i_episode         episode ID
    *
    * @return                  information to be displayed in tooltip over column with patient name representing second line
    *
    * @author                  Anna Kurowska
    * @version                 1.0
    * @since                   24-08-2016
     **********************************************************************************************/
    FUNCTION get_orig_anamn_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_visit   IN visit.id_visit%TYPE,
        i_episode IN episode.id_episode%TYPE DEFAULT NULL,
        i_sep     IN VARCHAR2 DEFAULT ', '
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the time in minutes for breach
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution Ids
    *
    * @return                         Time in minutes
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.4
    * @since                          30/01/2018
    **********************************************************************************************/
    FUNCTION get_los_breach
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER;

    /*EMR-437*/
    FUNCTION get_prof_cat(i_prof IN profissional) RETURN VARCHAR2;

    /*EMR-437*/
    k_lf VARCHAR2(0010 CHAR) := chr(10);
    PROCEDURE setsql(i_sql IN VARCHAR2);

    g_sql VARCHAR2(32000) := 'SELECT acuity acuity,' || k_lf || ' color_text color_text,' || k_lf ||
                             ' rank_acuity rank_acuity,' || k_lf || ' acuity_desc acuity_desc,' || k_lf ||
                             ' id_episode id_episode,' || k_lf || ' dt_begin dt_begin,' || k_lf ||
                             ' dt_efectiv dt_efectiv,' || k_lf || ' order_time order_time,' || k_lf ||
                             ' date_send date_send,' || k_lf || ' date_send_sort date_send_sort,' || k_lf ||
                             ' desc_room desc_room,' || k_lf || ' id_patient id_patient,' || k_lf ||
                             ' name_pat name_pat,' || k_lf || ' name_pat_sort name_pat_sort,' || k_lf ||
                             ' pat_ndo pat_ndo,' || k_lf || ' pat_nd_icon pat_nd_icon,' || k_lf || ' gender gender,' || k_lf ||
                             ' name_prof name_prof,' || k_lf || ' name_nurse name_nurse,' || k_lf ||
                             ' prof_team prof_team,' || k_lf || ' name_prof_tooltip name_prof_tooltip,' || k_lf ||
                             ' name_nurse_tooltip name_nurse_tooltip,' || k_lf ||
                             ' prof_team_tooltip prof_team_tooltip,' || k_lf || ' pat_age pat_age,' || k_lf ||
                             ' pat_age_for_order_by pat_age_for_order_by,' || k_lf || ' dt_first_obs dt_first_obs,' || k_lf ||
                             ' img_transp img_transp,' || k_lf || ' photo photo,' || k_lf || ' care_stage care_stage,' || k_lf ||
                             ' care_stage_rank care_stage_rank,' || k_lf || ' flg_temp flg_temp,' || k_lf ||
                             ' dt_server dt_server,' || k_lf || ' desc_temp desc_temp,' || k_lf ||
                             ' desc_drug_presc desc_drug_presc,' || k_lf ||
                             ' desc_monit_interv_presc desc_monit_interv_presc,' || k_lf ||
                             ' desc_movement desc_movement,' || k_lf || ' desc_analysis_req desc_analysis_req,' || k_lf ||
                             ' desc_exam_req desc_exam_req,' || k_lf || ' desc_epis_anamnesis desc_epis_anamnesis,' || k_lf ||
                             ' desc_disch_pend_time desc_disch_pend_time,' || k_lf ||
                             ' disch_pend_time disch_pend_time,' || k_lf || ' flg_cancel flg_cancel,' || k_lf ||
                             ' fast_track_icon fast_track_icon,' || k_lf || ' fast_track_color fast_track_color,' || k_lf ||
                             ' fast_track_status fast_track_status,' || k_lf || ' fast_track_desc fast_track_desc,' || k_lf ||
                             ' esi_level esi_level,' || k_lf || ' resp_icons resp_icons,' || k_lf ||
                             ' prof_follow_add prof_follow_add,' || k_lf || ' prof_follow_remove prof_follow_remove,' || k_lf ||
                             ' pat_major_inc_icon pat_major_inc_icon,' || k_lf ||
                             ' desc_oth_exam_req desc_oth_exam_req,' || k_lf || ' desc_img_exam_req desc_img_exam_req,' || k_lf ||
                             ' length_of_stay_bg_color length_of_stay_bg_color,' || k_lf ||
                             ' desc_opinion desc_opinion,' || k_lf || ' desc_opinion_popup desc_opinion_popup,' || k_lf ||
                             ' rank_triage rank_triage,' || k_lf || ' origin_anamn_full_desc origin_anamn_full_desc' || k_lf ||
                             ' FROM v_edisgridpatients t' || k_lf ||
                             ' JOIN (SELECT /*+ OPT_ESTIMATE(TABLE p ROWS=1) */' || k_lf ||
                             '  p.id_patient, p.position' || k_lf ||
                             '  FROM TABLE(pk_adt.get_patients(:i_lang, profissional(:i_prof_id, :i_prof_institution, :i_prof_software), :VALUE_01)) p' || k_lf ||
                             '  ) ps ON ps.id_patient = t.id_patient';

    /**
    * Initialize parameters to be used in the grid query of ORIS
    *
    * @param i_context_ids  identifier used in array of context
    * @param i_context_keys Content of the array context
    * @param i_context_vals Values  of the array context
    * @param i_name         variable for bind in the query
    * @param o_vc2          returned value if varchar
    * @param o_num          returned value if number
    * @param o_id           returned value if ID
    * @param o_tstz         returned value if date
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/04/19
    */
    PROCEDURE init_params_patient_grids
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_keys IN table_varchar DEFAULT NULL,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    --
    /*
      Globals
    */
    g_error        VARCHAR2(4000);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_exception EXCEPTION;

    g_yes CONSTANT VARCHAR2(1) := 'Y';

    g_soft_edis   CONSTANT software.id_software%TYPE := 8;
    g_soft_inp    CONSTANT software.id_software%TYPE := 11;
    g_soft_triage CONSTANT software.id_software%TYPE := 35;
    g_soft_ubu    CONSTANT software.id_software%TYPE := 29;

    g_epis_type_urg CONSTANT episode.id_epis_type%TYPE := 2;
    g_epis_type_obs CONSTANT episode.id_epis_type%TYPE := 5;
    g_epis_type_ubu CONSTANT episode.id_epis_type%TYPE := 9;

    g_inst_type_h CONSTANT institution.flg_type%TYPE := 'H';

    g_profile_edis_aux CONSTANT profile_template.id_profile_template%TYPE := 402;

    g_epis_active    CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_inactive  CONSTANT episode.flg_status%TYPE := 'I';
    g_epis_pending   CONSTANT episode.flg_status%TYPE := 'P';
    g_epis_cancelled CONSTANT episode.flg_status%TYPE := 'C';

    g_episode_flg_type_temp CONSTANT episode.flg_type%TYPE := 'T';

    g_admin_inp_episodes     CONSTANT sys_config.id_sys_config%TYPE := 'ADMIN_INP_EPISODES';
    g_admin_inp_episodes_all CONSTANT sys_config.value%TYPE := 'ALL';

    g_cat_doctor  CONSTANT category.flg_type%TYPE := 'D';
    g_cat_nurse   CONSTANT category.flg_type%TYPE := 'N';
    g_cat_is_prof CONSTANT category.flg_prof%TYPE := 'Y';

    g_color_rank           CONSTANT epis_info.triage_rank_acuity%TYPE := '999';
    g_no_triage_color      CONSTANT triage_color.color%TYPE := '0x787864';
    g_ubu_color            CONSTANT triage_color.color%TYPE := '0xE78284';
    g_no_triage_color_text CONSTANT triage_color.color_text%TYPE := '0xFFFFFF';

    g_complaint_active            CONSTANT epis_complaint.flg_status%TYPE := 'A';
    g_discharge_flg_status_active CONSTANT discharge.flg_status%TYPE := 'A';
    g_discharge_flg_status_pend   CONSTANT discharge.flg_status%TYPE := 'P';
    g_discharge_flg_status_reopen CONSTANT discharge.flg_status%TYPE := 'R';
    g_discharge_flg_type_pend     CONSTANT discharge.flg_type%TYPE := 'D';

    --this one needs to be global so it can be shared between diferent
    --calls of the same function inside an sql query
    g_disch_reason_inp_clin_serv sys_config.value%TYPE;

    g_task_analysis CONSTANT VARCHAR2(1) := 'A';
    g_task_exam     CONSTANT VARCHAR2(1) := 'E';
    g_task_harvest  CONSTANT VARCHAR2(1) := 'H';

    g_task_oth_exam CONSTANT VARCHAR2(1) := 'O';
    g_task_img_exam CONSTANT VARCHAR2(1) := 'G'; -- as to be G because I used on interv

    g_domain_nurse_act     CONSTANT sys_domain.code_domain%TYPE := 'NURSE_ACTIVITY_REQ.FLG_STATUS';
    g_transfer_inst_transp CONSTANT transfer_institution.flg_status%TYPE := 'T';
    g_transfer_inst_req    CONSTANT transfer_institution.flg_status%TYPE := 'R';
    g_transfer_inst_fin    CONSTANT transfer_institution.flg_status%TYPE := 'F';

    g_icon_ft          CONSTANT VARCHAR2(1) := 'F';
    g_icon_ft_transfer CONSTANT VARCHAR2(1) := 'T';
    g_desc_header      CONSTANT VARCHAR2(1) := 'H';
    g_desc_grid        CONSTANT VARCHAR2(1) := 'G';
    g_ft_color         CONSTANT VARCHAR2(200) := '0xFFFFFF';
    g_ft_triage_white  CONSTANT VARCHAR2(200) := '0x787864';
    g_ft_status        CONSTANT VARCHAR2(1) := 'A';

    g_flg_ehr_normal CONSTANT VARCHAR2(1) := 'N';

    g_selected CONSTANT VARCHAR2(1) := 'S';

    g_care_stage_wrg CONSTANT care_stage.flg_stage%TYPE := 'WRG';

    g_syscfg_los           CONSTANT sys_config.id_sys_config%TYPE := 'TRACKINGVIEW_GRAPHVIEW_ORDER_BY_LOS';
    g_cf_pat_gender_abbr   CONSTANT sys_config.id_sys_config%TYPE := 'PATIENT.GENDER.ABBR';
    g_config_grid_aux      CONSTANT sys_config.id_sys_config%TYPE := 'SHOW_ALL_PATIENTS_AUX_GRID';
    g_config_soft_inp      CONSTANT sys_config.id_sys_config%TYPE := 'SOFTWARE_ID_INP';
    g_config_show_inp_epis CONSTANT sys_config.id_sys_config%TYPE := 'INP_EPIS_IN_ANCILLARY_EDIS';
    g_conf_flg_triage_res_grids triage_configuration.flg_triage_res_grids%TYPE;

    g_grid_origins     sys_config.value%TYPE;
    g_tab_grid_origins table_varchar;

END pk_edis_grid;
/
