/*-- Last Change Revision: $Rev: 2010616 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-03-09 11:34:12 +0000 (qua, 09 mar 2022) $*/

CREATE OR REPLACE PACKAGE pk_summary_page IS
    -- Joana Barroso 2008-11-17 types para a função get_past_hist_medical_internal
    TYPE doc_area_register_rec IS RECORD(
        id_episode               episode.id_episode%TYPE,
        flg_current_episode      VARCHAR2(1),
        nick_name                professional.nick_name%TYPE,
        desc_speciality          VARCHAR2(200),
        dt_register              VARCHAR2(14),
        id_doc_area              doc_area.id_doc_area%TYPE,
        flg_status               VARCHAR2(1),
        dt_register_chr          VARCHAR2(200),
        id_professional          professional.id_professional%TYPE,
        notes                    VARCHAR2(4000),
        id_pat_history_diagnosis diagnosis.id_diagnosis%TYPE,
        flg_detail               VARCHAR2(1),
        flg_external             VARCHAR2(1),
        flg_free_text            VARCHAR2(1),
        flg_reviewed             VARCHAR2(1),
        id_visit                 episode.id_visit%TYPE);

    TYPE doc_area_register_cur IS REF CURSOR RETURN doc_area_register_rec;

    TYPE doc_area_val_past_med_rec IS RECORD(  
        id_episode                    episode.id_episode%TYPE,
        dt_register                   VARCHAR2(14),
        nick_name                     professional.nick_name%TYPE,
        desc_past_hist                VARCHAR2(2000),
        desc_past_hist_all            VARCHAR2(2000),
        flg_status                    VARCHAR2(2),
        desc_status                   VARCHAR2(200),
        flg_nature                    VARCHAR2(2),
        desc_nature                   VARCHAR2(200),
        flg_current_episode           VARCHAR2(2),
        flg_current_professional      VARCHAR2(2),
        flg_last_record               VARCHAR2(2),
        flg_last_record_prof          VARCHAR2(2),
        id_diagnosis                  diagnosis.id_diagnosis%TYPE,
        flg_outdated                  VARCHAR2(2),
        flg_canceled                  VARCHAR2(2),
        day_begin                     NUMBER(2),
        month_begin                   NUMBER(2),
        year_begin                    NUMBER(4),
        onset                         VARCHAR2(200),
        dt_register_chr               VARCHAR2(200),
        desc_flg_status               VARCHAR2(200),
        dt_register_order             VARCHAR2(14),
        dt_pat_history_diagnosis_tstz TIMESTAMP,
        flg_external                  VARCHAR2(2),
        id_pat_history_diagnosis      pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        desc_past_hist_short          VARCHAR2(1000 CHAR),
        id_professional               professional.id_professional%TYPE,
        code_icd                      diagnosis.code_diagnosis%TYPE,
        flg_other                     diagnosis.flg_other%TYPE,
        rank                          sys_domain.rank%TYPE,
        status_diagnosis              epis_diagnosis.flg_status%TYPE,
        icon_status                   sys_domain.img_name%TYPE,
        avail_for_select              VARCHAR2(1),
        default_new_status            epis_diagnosis.flg_status%TYPE,
        default_new_status_desc       sys_domain.desc_val%TYPE,
        id_alert_diagnosis            epis_diagnosis.id_alert_diagnosis%TYPE,
        dt_pat_history_diagnosis_rep  pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        flg_free_text                 VARCHAR2(1));

    TYPE doc_area_val_past_med_cur IS REF CURSOR RETURN doc_area_val_past_med_rec;
    TYPE t_coll_val_past_med IS TABLE OF doc_area_val_past_med_rec;

    -- Joana Barroso 2008-11-17 types para a função get_past_hist_surgical
    TYPE s_doc_area_register_rec IS RECORD(
        id_episode               episode.id_episode%TYPE,
        flg_current_episode      VARCHAR2(1),
        nick_name                professional.nick_name%TYPE,
        desc_speciality          VARCHAR2(200),
        dt_register              VARCHAR2(14),
        id_doc_area              doc_area.id_doc_area%TYPE,
        flg_status               VARCHAR2(1),
        dt_register_chr          VARCHAR2(200),
        id_professional          professional.id_professional%TYPE,
        notes                    VARCHAR2(4000),
        id_pat_history_diagnosis diagnosis.id_diagnosis%TYPE,
        flg_detail               VARCHAR2(1),
        flg_external             VARCHAR2(1),
        flg_free_text            VARCHAR2(1),
        flg_reviewed             VARCHAR2(1),
        id_visit                 episode.id_visit%TYPE);
    TYPE s_doc_area_register_cur IS REF CURSOR RETURN s_doc_area_register_rec;

    TYPE doc_area_val_past_surg_rec IS RECORD(
        id_episode                   episode.id_episode%TYPE,
        dt_register                  VARCHAR2(14),
        nick_name                    professional.nick_name%TYPE,
        desc_past_hist               VARCHAR2(2000),
        desc_past_hist_all           VARCHAR2(2000),
        flg_status                   VARCHAR2(2),
        desc_status                  VARCHAR2(200),
        flg_nature                   VARCHAR2(2),
        desc_nature                  VARCHAR2(200),
        flg_current_episode          VARCHAR2(2),
        flg_current_professional     VARCHAR2(2),
        flg_last_record              VARCHAR2(2),
        flg_last_record_prof         VARCHAR2(2),
        id_diagnosis                 diagnosis.id_diagnosis%TYPE,
        flg_outdated                 VARCHAR2(2),
        flg_canceled                 VARCHAR2(2),
        day_begin                    NUMBER(2),
        month_begin                  NUMBER(2),
        year_begin                   NUMBER(4),
        onset                        VARCHAR2(200),
        dt_register_chr              VARCHAR2(200),
        desc_flg_status              VARCHAR2(200),
        dt_register_order            VARCHAR2(14),
        id_pat_history_diagnosis     pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        id_professional              professional.id_professional%TYPE,
        dt_pat_history_diagnosis_rep pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        flg_other                    diagnosis.flg_other%TYPE,
        flg_free_text                VARCHAR2(1));

    TYPE doc_area_val_past_surg_cur IS REF CURSOR RETURN doc_area_val_past_surg_rec;
    TYPE t_coll_past_surg IS TABLE OF doc_area_val_past_surg_rec;

    TYPE doc_area_val_past_fam_rec IS RECORD(
        id_episode                   episode.id_episode%TYPE,
        dt_register                  VARCHAR2(14),
        nick_name                    professional.nick_name%TYPE,
        desc_past_hist               VARCHAR2(2000),
        desc_past_hist_all           VARCHAR2(2000),
        flg_status                   VARCHAR2(2),
        desc_status                  VARCHAR2(200),
        flg_current_episode          VARCHAR2(2),
        flg_current_professional     VARCHAR2(2),
        flg_last_record              VARCHAR2(2),
        flg_last_record_prof         VARCHAR2(2),
        id_diagnosis                 diagnosis.id_diagnosis%TYPE,
        flg_outdated                 VARCHAR2(2),
        flg_canceled                 VARCHAR2(2),
        day_begin                    NUMBER(2),
        month_begin                  NUMBER(2),
        year_begin                   NUMBER(4),
        onset                        VARCHAR2(200),
        dt_register_chr              VARCHAR2(200),
        desc_flg_status              VARCHAR2(200),
        dt_register_order            VARCHAR2(14),
        id_pat_history_diagnosis     pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        id_professional              professional.id_professional%TYPE,
        dt_pat_history_diagnosis_rep pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        flg_other                    diagnosis.flg_other%TYPE,
        flg_free_text                VARCHAR2(1),
        id_family_relationship       pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        desc_family_relationship     VARCHAR2(200 CHAR),
        flg_death_cause              pat_history_diagnosis.flg_death_cause%TYPE,
        desc_death_cause             VARCHAR2(200 CHAR),
        familiar_age                 pat_history_diagnosis.familiar_age%TYPE,
        desc_familiar_age            VARCHAR2(200 CHAR));

    TYPE doc_area_val_past_fam_cur IS REF CURSOR RETURN doc_area_val_past_fam_rec;
    TYPE t_coll_past_fam IS TABLE OF doc_area_val_past_fam_rec;
    -- Joana Barroso 2008-11-17 types para a função get_past_hist_relev_notes
    TYPE doc_area_reg_rel_notes_rec IS RECORD(
        id_pat_notes             pat_past_hist_free_text.id_pat_ph_ft%TYPE,
        id_episode               episode.id_episode%TYPE,
        flg_current_episode      VARCHAR2(1),
        nick_name                professional.nick_name%TYPE,
        desc_speciality          VARCHAR2(200),
        dt_register              VARCHAR2(14),
        id_doc_area              doc_area.id_doc_area%TYPE,
        flg_status               VARCHAR2(1),
        dt_register_chr          VARCHAR2(200),
        id_professional          professional.id_professional%TYPE,
        flg_detail               VARCHAR2(1),
        id_pat_history_diagnosis diagnosis.id_diagnosis%TYPE);

    TYPE doc_area_reg_rel_notes_cur IS REF CURSOR RETURN doc_area_reg_rel_notes_rec;

    TYPE doc_area_val_rel_notes_rec IS RECORD(
        id_pat_notes             pat_past_hist_free_text.id_pat_ph_ft%TYPE,
        desc_past_hist           VARCHAR2(2000),
        desc_past_hist_all       VARCHAR2(2000),
        flg_current_episode      VARCHAR2(2),
        dt_diag                  VARCHAR2(14),
        flg_current_professional VARCHAR2(2),
        flg_last_record          VARCHAR2(2),
        flg_last_record_prof     VARCHAR2(2),
        dt_register              VARCHAR2(14),
        nick_name                professional.nick_name%TYPE,
        flg_outdated             VARCHAR2(2),
        flg_canceled             VARCHAR2(2),
        desc_flg_status          VARCHAR2(200),
        id_professional          professional.id_professional%TYPE);

    TYPE doc_area_val_rel_notes_cur IS REF CURSOR RETURN doc_area_val_rel_notes_rec;
    TYPE t_coll_rel_notes IS TABLE OF doc_area_val_rel_notes_rec;

    -- Joana Barroso 2008-11-17 types para a função get_summ_page_doc_area_pat
    SUBTYPE doc_area_register_doc_rec IS pk_touch_option.t_rec_doc_area_register;

    SUBTYPE doc_area_register_doc_cur IS pk_touch_option.t_cur_doc_area_register;

    SUBTYPE doc_area_val_doc_rec IS pk_touch_option.t_rec_doc_area_val;

    SUBTYPE doc_area_val_doc_cur IS pk_touch_option.t_cur_doc_area_val;

    TYPE t_rec_section IS RECORD(
        translated_code              pk_translation.t_desc_translation,
        id_doc_area                  summary_page_section.id_doc_area%TYPE,
        screen_name                  summary_page_section.screen_name%TYPE,
        id_sys_shortcut              summary_page_section.id_sys_shortcut%TYPE,
        flg_write                    summary_page_access.flg_write%TYPE,
        flg_search                   summary_page_access.flg_search%TYPE,
        flg_no_changes               summary_page_access.flg_no_changes%TYPE,
        flg_template                 VARCHAR2(1 CHAR),
        height                       summary_page_section.height%TYPE,
        flg_type                     doc_area_inst_soft.flg_type%TYPE,
        screen_name_after_save       summary_page_section.screen_name_after_save%TYPE,
        subtitle                     pk_translation.t_desc_translation,
        intern_name_sample_text_type doc_area.intern_name_sample_text_type%TYPE,
        flg_score                    doc_area.flg_score%TYPE,
        screen_name_free_text        summary_page_section.screen_name_free_text%TYPE,
        flg_scope_type               doc_area_inst_soft.flg_scope_type%TYPE,
        flg_data_paging_enabled      doc_area_inst_soft.flg_data_paging_enabled%TYPE,
        page_size                    doc_area_inst_soft.page_size%TYPE,
        rank                         NUMBER,
        flg_create                   VARCHAR2(1 CHAR));

    TYPE t_coll_section IS TABLE OF t_rec_section;
    TYPE t_cur_section IS REF CURSOR RETURN t_rec_section;

    /********************************************************************************************
    * Returns the sections within a summary page to be presented in reports
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_summary_page        Summary page ID
    * @param o_sections               Cursor containing the sections info                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Tiago Lourenço
    * @version                        v2.5.1.6
    * @since                          08-Jun-2011
    **********************************************************************************************/
    FUNCTION get_summary_page_sections_rep
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_doc_area_by_cat
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_doc_category IN doc_category.id_doc_category%TYPE
    ) RETURN table_number;

    /********************************************************************************************
    * Returns the sections within a summary page
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_summary_page        Summary page ID
    * @param i_pat                    Patient ID
    * @param i_complete_epi_rep       flag that indicates whether it is to return all summary page
    *                                 sections for the complete episode report
    * @param o_sections               Cursor containing the sections info                                      
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Abreu, Luís Gaspar
    * @version                        1.0
    * @since                          2007/05/24
    **********************************************************************************************/
    FUNCTION get_summary_page_sections
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_summary_page  IN summary_page.id_summary_page%TYPE,
        i_pat              IN patient.id_patient%TYPE,
        i_complete_epi_rep IN BOOLEAN,
        i_id_doc_category  IN doc_category.id_doc_category%TYPE DEFAULT NULL,
        o_sections         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_summary_page_sections
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        i_complete_epi_rep IN BOOLEAN,
        i_doc_areas_ex     IN table_number,
        i_doc_areas_in     IN table_number,
        o_sections         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summary_page_sections
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        i_id_doc_category IN doc_category.id_doc_category%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summary_page_sections
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_summary_page  IN summary_page.id_summary_page%TYPE,
        i_pat              IN patient.id_patient%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns documentation data for a given patient (the one referenced on the current episode)
    * Similar to PK_SUMMARY_PAGE.GET_SUMM_PAGE_DOC_AREA_VALUE, but for all patient episodes
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param i_doc_area               Doc area ID
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/06/02
    * Changes:
    *                             Ariel Machado
    *                             version 2.4.4   
    *                             2009/03/20
    *                             Returns layout for each template used
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_pat
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_pat                IN patient.id_patient%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns documentation data for a given patient (the one referenced on the current episode)
    * Similar to PK_SUMMARY_PAGE.GET_SUMM_PAGE_DOC_AREA_VALUE, but for all patient episodes
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param i_doc_area               Doc area ID
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/06/02
    *
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_pat_int
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_pat                IN patient.id_patient%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolve toda a informação registada na Documentation para um episódio
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/05/30
    *
    * Changes:
    *                             Ariel Machado
    *                             version 2.4.4   
    *                             2009/03/20
    *                             Returns layout for each template used
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolve toda a informação registada na Documentation para uma visita
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.5
    * @since                          2010/03/18
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_visit
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolver o profissional que efectou a última alteração e respectiva data. 
    *
    * @param i_lang                   The language ID
    * @param i_prof_id                professional ID
    * @param i_prof_inst              institution ID, 
    * @param i_prof_sw                software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_last_update            Cursor containing the last update register
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Spratley
    * @version                        1.0   
    * @since                          2007/10/12
    *
    * Changes:
    *                             Ariel Machado
    *                             version 2.4.4   
    *                             2009/03/20
    *                             Returns layout for each template used
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_pg_doc_ar_val_reports
    (
        i_lang               IN language.id_language%TYPE,
        i_prof_id            IN professional.id_professional%TYPE,
        i_prof_inst          IN institution.id_institution%TYPE,
        i_prof_sw            IN software.id_software%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolver o profissional que efectou a última alteração e respectiva data. 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_last_update            Cursor containing the last update register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0   
    * @since                          2007/05/30
    **********************************************************************************************/
    FUNCTION get_summ_hist_ill_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_doc_area    IN table_number,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolver para um episódio os componentes e seus respectivos elementos. 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_documentation          Cursor containing the components and the elements for the episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/10/17
    * @alter                          2007/06/20
    **********************************************************************************************/
    FUNCTION get_summ_last_documentation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN table_number,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        o_documentation OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Gets doc_template from a given value (clinical service, doc_area, etc). 
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           episode id
    * @param i_patient           patient id
    * @param i_value             context id
    * @param i_flg_type          C - Complaint; I - Intervention; A - Appointment type; D - Doc area
    * @param o_doc_template      the doc template id
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *    
    * @author                    Ana Matos
    * @version                   1.0
    * @since                     28-08-2007
    **********************************************************************************************/
    FUNCTION get_template
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_value        IN doc_template_context.id_context%TYPE,
        i_flg_type     IN doc_template_context.flg_type%TYPE,
        o_doc_template OUT doc_template.id_doc_template%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Retorna TRUE se  
    *
    * @param i_lang              language id
    * @param i_episode           episode id
    * @param o_flg_status        Y se é true, N se não
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *    
    * @author                    Rita Lopes
    * @version                   1.0
    * @since                     05-09-2007
    **********************************************************************************************/
    FUNCTION get_clin_service_status
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_flg_status OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolver para um episódio os componentes e seus respectivos elementos. 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_pat                    Patient ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_past_hist_med          Cursor containing the components and the elements for the episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/09/07
    **********************************************************************************************/
    FUNCTION get_summ_last_past_hist_med
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_pat           IN patient.id_patient%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        o_past_hist_med OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Concatenar as qualificações / quantificações associadas a um elemento
    *
    * @param i_lang                   The language ID
    * @param i_epis_document_det      the episode documentation detail
    *                        
    * @return                         description
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/09/14
    **********************************************************************************************/
    FUNCTION get_epis_doc_qualif
    (
        i_lang              IN language.id_language%TYPE,
        i_epis_document_det IN epis_documentation_det.id_epis_documentation_det%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Depending on the context defined on the doc_area_inst_soft, returns if the obstetric history
    * should do a shortcut for the woman health deepnav. If the context corresponds to the clinical service,
    * it returns 'Y' if there is a parameterization on the sys_config. Else, it returns if it is in the 
    * context of an episode.
    *
    * @param i_lang              language id
    * @param i_episode           episode id
    * @param i_doc_area          doc area id
    * @param o_flg_status        if it should call the shortcut for the obs history (Y/N)
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *
    * @author                    Rui de Sousa Neves
    * @version                   1.0
    * @since                     28-09-2007
    **********************************************************************************************/
    FUNCTION get_context_status
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_doc_area   IN doc_area.id_doc_area%TYPE,
        i_prof       IN profissional,
        o_flg_status OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolver para um episódio de documentation os componentes e seus respectivos elementos. 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis_documentation     the episode documentation ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_documentation          Cursor containing the components and the elements for the episode documentation
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/10/01
    **********************************************************************************************/
    FUNCTION get_summ_last_doc_area
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_documentation      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolve os últimos registos da história familiar, social e cirúrgica de um paciente 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                the patient ID
    * @param o_last_hist_all          Cursor containing the last information of past history family, social, surgical
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/10/02
    **********************************************************************************************/
    FUNCTION get_summ_last_hist_all
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        o_last_hist_all OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Devolve toda a informação registada na Documentation para um paciente
    *
    * @param i_lang                   Professional preferred language
    * @param i_prof                   Professional identification and its context (institution and software)
    * @param i_episode                Current episode ID
    * @param i_doc_area               Documentation area ID
    * @param o_doc_area_register      Cursor containing information about registers (professional, record date, status, etc.)
    * @param o_doc_area_val           Cursor containing information about data values saved in registers
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2008/05/19
    *
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_pat
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Devolve toda a informação registada na Documentation para um paciente - Para uso nos reports
    *
    * @param i_lang                   The language ID
    * @param i_prof_id                professional ID
    * @param i_prof_inst              institution ID
    * @param i_prof_sw                software ID
    * @param i_episode                the episode ID
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Spratley
    * @version                        2.4.3
    * @since                          2008/08/11
    *                                 Retrieves data from multichoice elements
    
    * Changes:
    *                             Ariel Machado
    *                             version 2.4.4   
    *                             2009/03/20
    *                             Returns layout for each template used
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_pat_rep
    (
        i_lang               IN language.id_language%TYPE,
        i_prof_id            IN professional.id_professional%TYPE,
        i_prof_inst          IN institution.id_institution%TYPE,
        i_prof_sw            IN software.id_software%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**************************************************************************
    * Get doc area name
    *                                                                                 
    * @param i_lang                   Language ID                                     
    * @param i_software               Software ID
    * @param i_doc_area               Doc area ID
    * @param i_use_abbrev_name        Return the abbreviated name or full name. Default: full name
    *
    * @value i_use_abbrev_name       {*} 'Y'  Yes {*} 'N' No
    * return doc area name         
    *                                                                                 
    * @author                         Filipe Silva & Ariel Machado                                   
    * @version                        2.6.0.5                                         
    * @since                          2011/02/16                                       
    **************************************************************************/
    FUNCTION get_doc_area_name
    (
        i_lang            IN language.id_language%TYPE,
        i_software        IN software.id_software%TYPE,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_use_abbrev_name IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 result_cache;
    --
    /**************************************************************************
    * Get doc area name
    *                                                                                 
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Professional identification and its context (institution and software)
    * @param i_doc_area               Doc area ID
    * @param i_use_abbrev_name        Return the abbreviated name or full name. Default: full name
    *
    * @value i_use_abbrev_name       {*} 'Y'  Yes {*} 'N' No
    * return doc area name         
    *                                                                                 
    * @author                         Filipe Silva & Ariel Machado                                   
    * @version                        2.6.0.5                                         
    * @since                          2011/02/16                                       
    **************************************************************************/
    FUNCTION get_doc_area_name
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_use_abbrev_name IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;
    --
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
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Gets the flg_no_change according to a doc_area:
    * if does not exists a summary_page_section to the given id_doc_area returns 'Y'
    * if there is some active flg_no_changes in some summary page access of the given doc_area
    * return 'Y'. Otherwise return 'N'
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)    
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.1
    * @since                          15-Apr-2011
    **********************************************************************************************/
    FUNCTION get_flg_no_changes_by_doc_area
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if this professional has a way to register a complaint other than using "History of Present Illness" area
    * If he has other screens to do it the application can automatically enter create mode for "History of Present Illness".
    * If there isn't another area with this screen the application must remain on the summary page and not enter the HPI creation screen by default
    * 
    *
    * @param   i_lang                   The language ID
    * @param   i_prof                   Object (professional ID, institution ID, software ID)    
    *                
    * @param   o_can_create_hpi         Indicates if the professional should enter create mode by default in the HPI area - Values: Y/N
    *
    * @return  True or False on success or error
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.6
    * @since                          23-Dez-2011
    **********************************************************************************************/
    FUNCTION get_prof_complaint_screens
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_can_create_hpi OUT VARCHAR2
    ) RETURN BOOLEAN;

    /*
    * Checks if a doc_area belongs to a summary page
    *
    * @param     i_lang                       Language id
    * @param     i_prof                       Professional object identifier
    * @param     i_id_doc_area                Documentation Area identifier
    * @param     i_id_summary_page            Summary Page identifier
    
    * @return                                 'Y' - doc area belongs to summary page, 'N' - otherwise No
    *
    * @author                                 António Neto
    * @version                                v2.6.2
    * @since                                  24-Apr-2012
    */
    FUNCTION is_doc_area_in_summary_page
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_doc_area     IN doc_area.id_doc_area%TYPE,
        i_id_summary_page IN summary_page.id_summary_page%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the section within a summary page associated to a doc_area
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_summary_page        Summary page ID
    * @param i_id_doc_area            Doc area ID
    * @param o_section               Cursor containing the sections info                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.3.5
    * @since                          29-Mai-2013
    **********************************************************************************************/
    FUNCTION get_summary_page_section
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_id_doc_area     IN doc_area.id_doc_area%TYPE,
        o_section         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Devolver para um episódio os componentes e seus respectivos elementos. 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_documentation          Cursor containing the components and the elements for the episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Alexander Camilo
    * @version                        1.0
    * @since                          2018/01/30
    * @alter                          2018/01/30
    **********************************************************************************************/
    FUNCTION get_summ_all_documentation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN table_number,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        o_documentation OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_write_exception
    (
        i_lang            language.id_language%TYPE,
        i_prof            profissional,
        i_id_page_summary summary_page_section.id_summary_page_section%TYPE,
        i_flg_write       VARCHAR2,
         i_flg_doc_area_avail VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;

    FUNCTION get_sections_with_category
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        o_cursor_cat      OUT pk_types.cursor_type,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_sections
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_market           IN NUMBER,
        i_gender           IN VARCHAR2,
        i_age              IN NUMBER,
        i_profile_template IN NUMBER,
        i_id_summary_page  IN NUMBER,
        i_doc_areas_ex     IN table_number,
        i_doc_areas_in     IN table_number
    ) RETURN t_coll_sections;

    FUNCTION tf_categories
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_coll_categories;

    FUNCTION tf_categories_permission
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_pat             IN patient.id_patient%TYPE
    ) RETURN t_coll_categories;
    
    --
    /**######################################################
      GLOBAIS
    ######################################################**/
    g_error        VARCHAR2(4000);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_found        BOOLEAN;
    g_pp_found     BOOLEAN;

    g_exception EXCEPTION;
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);
    --
    g_datetime_format_timezone CONSTANT VARCHAR2(20) := 'YYYYMMDDHH24MISS TZR';
    --g_pat_hist_diag_canceled
    g_flg_view_summary CONSTANT doc_element_crit.flg_view%TYPE := 'S';
    --
    g_current_episode_yes      CONSTANT VARCHAR2(1) := 'Y';
    g_current_episode_no       CONSTANT VARCHAR2(1) := 'N';
    g_current_professional_yes CONSTANT VARCHAR2(1) := 'Y';
    g_current_professional_no  CONSTANT VARCHAR2(1) := 'N';
    --
    g_last_record_yes CONSTANT VARCHAR2(1) := 'Y';
    g_last_record_no  CONSTANT VARCHAR2(1) := 'N';
    --
    g_pat_hist_diag_unknown  CONSTANT pat_history_diagnosis.flg_status%TYPE := 'U';
    g_pat_hist_diag_none     CONSTANT pat_history_diagnosis.flg_status%TYPE := 'N';
    g_pat_hist_diag_canceled CONSTANT pat_history_diagnosis.flg_status%TYPE := 'C';
    g_pat_notes_canceled     CONSTANT pat_notes.flg_status%TYPE := 'C';
    --
    g_diag_unknown CONSTANT pat_history_diagnosis.id_diagnosis%TYPE := 0;
    g_diag_none    CONSTANT pat_history_diagnosis.id_diagnosis%TYPE := -1;
    --
    g_active   CONSTANT VARCHAR2(1) := 'A';
    g_inactive CONSTANT VARCHAR2(1) := 'I';
    g_outdated CONSTANT VARCHAR2(1) := 'O';
    --
    g_outdated_yes CONSTANT VARCHAR2(1) := 'Y';
    g_outdated_no  CONSTANT VARCHAR2(1) := 'N';
    --
    g_canceled_yes CONSTANT VARCHAR2(1) := 'Y';
    g_canceled_no  CONSTANT VARCHAR2(1) := 'N';
    --
    g_doc_area_complaint     CONSTANT doc_area.id_doc_area%TYPE := 20; --Complaint
    g_doc_area_hist_ill      CONSTANT doc_area.id_doc_area%TYPE := 21; --History present illness
    g_doc_area_rev_sys       CONSTANT doc_area.id_doc_area%TYPE := 22; --Review of system
    g_doc_area_phy_exam      CONSTANT doc_area.id_doc_area%TYPE := 28; --physical exam   
    g_doc_area_phy_assess    CONSTANT doc_area.id_doc_area%TYPE := 1045; --physical assessment
    g_doc_area_past_med      CONSTANT doc_area.id_doc_area%TYPE := 45; -- Past medical
    g_doc_area_past_surg     CONSTANT doc_area.id_doc_area%TYPE := 46; -- Past surgical
    g_doc_area_past_fam      CONSTANT doc_area.id_doc_area%TYPE := 47; -- Past family
    g_doc_area_past_soc      CONSTANT doc_area.id_doc_area%TYPE := 48; -- Past social
    g_doc_area_relev_notes   CONSTANT doc_area.id_doc_area%TYPE := 49; -- Relevant notes
    g_doc_area_cong_anom     CONSTANT doc_area.id_doc_area%TYPE := 52; -- Congenital anomalies
    g_doc_area_food_hist     CONSTANT doc_area.id_doc_area%TYPE := 1050; -- Food History
    g_doc_area_gyn_hist      CONSTANT doc_area.id_doc_area%TYPE := 1052; -- Gynecology History
    g_doc_area_child_hist    CONSTANT doc_area.id_doc_area%TYPE := 55; -- Child History
    g_doc_area_obs_hist      CONSTANT doc_area.id_doc_area%TYPE := 1049; -- Obstetric History
    g_doc_area_natal_hist    CONSTANT doc_area.id_doc_area%TYPE := 1051; -- Peri-natal and natal History
    g_doc_area_father_data   CONSTANT doc_area.id_doc_area%TYPE := 1098; --Father's data
    g_doc_area_perm_incap    CONSTANT doc_area.id_doc_area%TYPE := 1054; -- Permanent incapacities
    g_doc_area_prg_notes_phy CONSTANT doc_area.id_doc_area%TYPE := 1092; -- Progress notes by physician
    g_doc_area_ophthal_exam  CONSTANT doc_area.id_doc_area%TYPE := 6094; -- Ophthalmological Exam
    g_doc_area_nursing_notes CONSTANT doc_area.id_doc_area%TYPE := 6724; -- Nursing Notes (also referred as Progress notes by nurse)
    g_doc_area_prg_notes_tec CONSTANT doc_area.id_doc_area%TYPE := 6725; -- Progress notes by technician
    g_doc_area_treatments    CONSTANT doc_area.id_doc_area%TYPE := 6753; -- treatments
    g_doc_area_plan          CONSTANT doc_area.id_doc_area%TYPE := 36110; -- treatments
    g_doc_area_pos_val       CONSTANT doc_area.id_doc_area%TYPE := 6702; -- treatments
    g_doc_area_pharm_assess  CONSTANT doc_area.id_doc_area%TYPE := 6701; -- treatments
    g_doc_area_sur_record    CONSTANT doc_area.id_doc_area%TYPE := 16; --Surgery team report

    g_doc_area_act_daily_s    CONSTANT doc_area.id_doc_area%TYPE := 36015; --Activities of daily living score
    g_doc_area_eval_relat_fam CONSTANT doc_area.id_doc_area%TYPE := 36068; --Evaluation of relationships within family
    g_doc_area_instructions   CONSTANT doc_area.id_doc_area%TYPE := 36057; --Instructions
    g_doc_area_disch_notes    CONSTANT doc_area.id_doc_area%TYPE := 36091; --Discharge notes
    g_doc_area_mental_hist    CONSTANT doc_area.id_doc_area%TYPE := 36078; --Mental history
    g_doc_area_ped_nutrit     CONSTANT doc_area.id_doc_area%TYPE := 6775; -- Pediatric nutrition assessment
    g_doc_area_past_psy_hist  CONSTANT doc_area.id_doc_area%TYPE := 36084; --Past psychiatric history
    g_doc_area_personal_hist  CONSTANT doc_area.id_doc_area%TYPE := 36079; --Personal history
    g_doc_area_occup_hist     CONSTANT doc_area.id_doc_area%TYPE := 36054; --Occupational history
    g_doc_area_foren_hist     CONSTANT doc_area.id_doc_area%TYPE := 36085; --Forensic history
    g_doc_area_gener_ped_ass  CONSTANT doc_area.id_doc_area%TYPE := 6778; --General pediatric assessment
    g_doc_area_develop_ass    CONSTANT doc_area.id_doc_area%TYPE := 6774; --Development assessment
    g_doc_area_neur_exam      CONSTANT doc_area.id_doc_area%TYPE := 36076; --Brief neurological examination
    g_doc_area_mental_st_exm  CONSTANT doc_area.id_doc_area%TYPE := 36077; --Mental state examination
    g_doc_area_mini_ment_exm  CONSTANT doc_area.id_doc_area%TYPE := 6592; --Mini-mental state examination (MMSE)
    g_doc_area_nur_init_ass   CONSTANT doc_area.id_doc_area%TYPE := 35; --Initial nursing assessment
    g_doc_area_nurse_assess   CONSTANT doc_area.id_doc_area%TYPE := 5592; --Nursing assessments
    g_doc_area_assessments    CONSTANT doc_area.id_doc_area%TYPE := 5096; --Assessments
    g_doc_area_nutr_assess    CONSTANT doc_area.id_doc_area%TYPE := 6704; --Nutrition assessments
    g_doc_area_nutritional_a  CONSTANT doc_area.id_doc_area%TYPE := 280105; --Nutritional assessment
    g_doc_area_ini_res_the_a  CONSTANT doc_area.id_doc_area%TYPE := 36100; --Initial respiratory therapy assessment
    g_doc_area_orienta_notes  CONSTANT doc_area.id_doc_area%TYPE := 36090; --Orientation notes
    g_doc_area_inten_hc       CONSTANT doc_area.id_doc_area%TYPE := 36064; --Intensity of home care
    g_doc_area_educ_assess    CONSTANT doc_area.id_doc_area%TYPE := 6752; --Educational assessment
    g_doc_area_abuse_history    CONSTANT doc_area.id_doc_area%TYPE := 36140; --Abuse history
    g_doc_area_assessment     CONSTANT doc_area.id_doc_area%TYPE := 36150; -- assessment old epis_recommed (A)

    -- (Evaluation tools)
    g_doc_area_barthel CONSTANT doc_area.id_doc_area%TYPE := 3592; -- Barthel Index 

    --
    g_alert_diag_type_med       CONSTANT alert_diagnosis.flg_type%TYPE := 'M'; -- medical
    g_alert_diag_type_surg      CONSTANT alert_diagnosis.flg_type%TYPE := 'S'; -- surgical
    g_alert_diag_type_cong_anom CONSTANT alert_diagnosis.flg_type%TYPE := 'A'; -- congenital anomaly
    g_alert_diag_type_fam       CONSTANT pat_fam_soc_hist.flg_type%TYPE := 'F'; -- family
    g_alert_diag_type_soc       CONSTANT pat_fam_soc_hist.flg_type%TYPE := 'S'; -- social
    g_alert_diag_type_other     CONSTANT pat_fam_soc_hist.flg_type%TYPE := 'O'; -- social    
    --
    g_recent_diag_yes pat_history_diagnosis.flg_recent_diag%TYPE := 'Y';
    g_recent_diag_no  pat_history_diagnosis.flg_recent_diag%TYPE := 'N';
    --    
    g_other_diagnosis_config    CONSTANT sys_config.desc_sys_config%TYPE := 'PERMISSION_FOR_OTHER_DIAGNOSIS';
    g_past_hist_diag_type_treat CONSTANT sys_config.desc_sys_config%TYPE := 'PAST_HISTORY_TREATMENT_TYPE';

    g_select_yes CONSTANT diagnosis.flg_select%TYPE := 'Y';
    --
    g_epis_complaint_act CONSTANT epis_complaint.flg_status%TYPE := 'A';
    --
    g_flg_temp_h           CONSTANT epis_anamnesis.flg_temp%TYPE := 'H';
    g_flg_temp_d           CONSTANT epis_anamnesis.flg_temp%TYPE := 'D';
    g_flg_temp_t           CONSTANT epis_anamnesis.flg_temp%TYPE := 'T';
    g_epis_anam_flg_type_c CONSTANT epis_anamnesis.flg_type%TYPE := 'C';
    g_epis_anam_flg_type_a CONSTANT epis_anamnesis.flg_type%TYPE := 'A';
    g_epis_obs_flg_type_e  CONSTANT epis_observation.flg_type%TYPE := 'E';
    g_epis_obs_flg_type_a  CONSTANT epis_observation.flg_type%TYPE := 'A';
    --
    g_flg_type_a CONSTANT doc_template_context.flg_type%TYPE := 'A';
    g_flg_type_d CONSTANT doc_template_context.flg_type%TYPE := 'D';
    --
    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';

    g_pat_history_diagnosis_n CONSTANT VARCHAR2(1) := 'N';
    g_pat_history_diagnosis_y CONSTANT VARCHAR2(1) := 'Y';
    --
    g_touch_option CONSTANT VARCHAR2(1) := 'D';
    g_free_text    CONSTANT VARCHAR2(1) := 'N';

    g_flg_status_none CONSTANT pat_history_diagnosis.flg_status%TYPE := 'N';
    g_flg_status_unk  CONSTANT pat_history_diagnosis.flg_status%TYPE := 'U';

    g_flg_cancel CONSTANT VARCHAR2(1) := 'C';
    --
    g_flg_other CONSTANT VARCHAR2(1) := 'Y';
    --
    g_flg_det_yes CONSTANT VARCHAR(1) := 'Y';
    g_flg_det_no  CONSTANT VARCHAR(1) := 'N';
    --
    g_flg_element_domain_template  CONSTANT doc_element.flg_element_domain_type%TYPE := 'T';
    g_flg_element_domain_sysdomain CONSTANT doc_element.flg_element_domain_type%TYPE := 'S';
    g_flg_element_domain_dynamic   CONSTANT doc_element.flg_element_domain_type%TYPE := 'D';
    --
    g_elem_flg_type_mchoice_single CONSTANT doc_element.flg_type%TYPE := 'CO';
    g_elem_flg_type_mchoice_multpl CONSTANT doc_element.flg_type%TYPE := 'CM';
    g_elem_flg_type_comp_datahour  CONSTANT doc_element.flg_type%TYPE := 'CC'; --Comp. element keypad date&hour
    g_elem_flg_type_comp_hour      CONSTANT doc_element.flg_type%TYPE := 'CH'; --Comp. element keypad hour
    g_elem_flg_type_comp_numeric   CONSTANT doc_element.flg_type%TYPE := 'CN'; --Comp. element keypad numeric
    --
    g_scfg_decimal_separator CONSTANT sys_config.id_sys_config%TYPE := 'DECIMAL_SYMBOL';

    g_pbm_session CONSTANT notes_config.notes_code%TYPE := 'PBM';
    g_rds_session CONSTANT notes_config.notes_code%TYPE := 'RDS';

    g_doc_title CONSTANT doc_component.flg_type%TYPE := 'T';

    g_flg_tab_origin_epis_doc      CONSTANT VARCHAR(1 CHAR) := 'D'; --epis_documentation
    g_flg_tab_origin_epis_anamn    CONSTANT VARCHAR(1 CHAR) := 'A'; --epis_anamnesis
    g_flg_tab_origin_epis_rev_sys  CONSTANT VARCHAR(1 CHAR) := 'S'; --epis_review_systems
    g_flg_tab_origin_epis_obs      CONSTANT VARCHAR(1 CHAR) := 'O'; --epis_observation table
    g_flg_tab_origin_epis_recomend CONSTANT VARCHAR(1 CHAR) := 'R'; --epis_recomend table

    g_year_unknown CONSTANT VARCHAR2(2 CHAR) := '-1';

    g_interv_type CONSTANT VARCHAR2(1 CHAR) := 'P';

    g_dt_execution_precision_day   CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_dt_execution_precision_month CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_dt_execution_precision_year  CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_dt_execution_precision_hour  CONSTANT VARCHAR2(1 CHAR) := 'H';

END pk_summary_page;
/
