/*-- Last Change Revision: $Rev: 2055313 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2023-02-17 12:48:57 +0000 (sex, 17 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_progress_notes_upd IS

    g_error         VARCHAR2(1000 CHAR);
    g_package_owner VARCHAR2(30 CHAR);
    g_package_name  VARCHAR2(30 CHAR);
    g_found         BOOLEAN;
    g_exception EXCEPTION;
    g_fault     EXCEPTION;

    -- session context variables
    -- (calculated once per session)
    g_ctx pk_prog_notes_types.t_configs_ctx;

    -- documentation origins (epis_documentation or free text)
    g_doc_orig_ed CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_doc_orig_ft CONSTANT VARCHAR2(1 CHAR) := 'F';

    -- assessment tools summary pages
    g_risk_fact_summ_page CONSTANT summary_page.id_summary_page%TYPE := 5;
    g_func_eval_summ_page CONSTANT summary_page.id_summary_page%TYPE := 34;

    -- standard screen height (pixels)
    g_screen_height CONSTANT PLS_INTEGER := 576;

    -- reason for visit soap block identifier
    g_soap_block_rea_vis CONSTANT pn_soap_block.id_pn_soap_block%TYPE := 1;

    -- data block identifiers
    g_data_block_local     CONSTANT pn_data_block.id_pn_data_block%TYPE := 82; -- local data block identifier
    g_data_block_dictation CONSTANT pn_data_block.id_pn_data_block%TYPE := 46; -- dictation data block identifier

    g_dictation_hist BOOLEAN := FALSE;

    g_exam_code CONSTANT translation.code_translation%TYPE := 'EXAM.CODE_EXAM.';

    g_star CONSTANT VARCHAR2(1 CHAR) := '*';

    CURSOR c_exam
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN exams_ea.flg_type%TYPE
    ) IS
        SELECT pk_exams_api_db.get_alias_translation(i_lang, i_prof, g_exam_code || ex.id_exam, NULL) desc_info
          FROM (SELECT ee.id_exam, ee.flg_status_req, ee.flg_type, ee.id_exam_result
                  FROM exams_ea ee
                 WHERE ee.id_episode = i_episode
                UNION ALL
                SELECT ee.id_exam, ee.flg_status_req, ee.flg_type, ee.id_exam_result
                  FROM exams_ea ee
                 WHERE ee.id_episode_origin = i_episode) ex
         WHERE ex.flg_type = i_flg_type
           AND ex.id_exam_result IS NULL
           AND ex.flg_status_req != pk_alert_constant.g_exam_req_canc
         ORDER BY desc_info;

    -- union distinct between two collections of templates
    FUNCTION union_distinct_coll_template
    (
        i_tbl1 IN t_coll_template,
        i_tbl2 IN t_coll_template
    ) RETURN t_coll_template IS
        tbl_template t_coll_template;
    BEGIN
    
        SELECT t_rec_template(id_doc_template, desc_template, id_doc_area, flg_type)
          BULK COLLECT
          INTO tbl_template
          FROM (SELECT t1.id_doc_template, t1.desc_template, t1.id_doc_area, t1.flg_type
                  FROM TABLE(i_tbl1) t1
                UNION
                SELECT t2.id_doc_template, t2.desc_template, t2.id_doc_area, t2.flg_type
                  FROM TABLE(i_tbl2) t2) xunion;
    
        RETURN tbl_template;
    
    END union_distinct_coll_template;

    /**
    * Get the soap note's current DEP_CLIN_SERV identifier.
    * If no soap note is specified, it gets the episode's.
    *
    * @param i_episode      episode identifier
    * @param i_epis_pn      soap note identifier
    *
    * @return               DEP_CLIN_SERV identifier
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/02/21
    */
    FUNCTION get_dep_clin_serv
    (
        i_episode IN epis_info.id_episode%TYPE,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN epis_info.id_dep_clin_serv%TYPE IS
        l_id_dcs epis_info.id_dep_clin_serv%TYPE;
        l_error  t_error_out;
    BEGIN
    
        g_error := 'CALL pk_prog_notes_utils.get_dep_clin_serv';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_dep_clin_serv(i_lang             => NULL,
                                                     i_prof             => NULL,
                                                     i_id_episode       => i_episode,
                                                     i_id_epis_pn       => i_epis_pn,
                                                     o_id_dep_clin_serv => l_id_dcs,
                                                     o_error            => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN l_id_dcs;
    END get_dep_clin_serv;

    /**
    * Get the episode's current DEPARTMENT identifier (service).
    *
    * @param i_episode      episode identifier
    * @param i_epis_pn      note id
    *
    * @return               DEPARTMENT identifier (service).
    *
    * @author               Pedro Teixeira
    * @version               2.6.0.4
    * @since                2010/10/01
    */
    FUNCTION get_department
    (
        i_episode IN episode.id_episode%TYPE,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN episode.id_department%TYPE IS
        l_department episode.id_department%TYPE;
    BEGIN
        BEGIN
            IF i_epis_pn IS NULL
            THEN
                g_error := 'SELECT from episode';
                SELECT e.id_department
                  INTO l_department
                  FROM episode e
                 WHERE e.id_episode = i_episode;
            ELSE
                g_error := 'SELECT from dep_clin_serv';
                SELECT dcs.id_department
                  INTO l_department
                  FROM dep_clin_serv dcs
                 WHERE dcs.id_dep_clin_serv = g_ctx.id_dep_clin_serv;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                l_department := NULL;
        END;
    
        RETURN l_department;
    END get_department;

    /**
    * Reset session context variables.
    *
    * @param i_prof             logged professional structure
    * @param i_episode          episode identifier
    * @param i_id_pn_note_type  soap note type
    * @param i_epis_pn          soap note identifier
    * @param i_id_dep_clin_serv Dep clin serv id
    *
    * @author                   Sofia Mendes
    * @version                  2.6.2.2
    * @since                    18-Jun-2012
    */
    FUNCTION reset_ctx
    (
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN pk_prog_notes_types.t_configs_ctx IS
    BEGIN
        IF i_id_pn_note_type IS NULL
        THEN
            g_error := 'ID Note type cannot be null!';
            RAISE g_fault;
        END IF;
    
        g_ctx.id_market           := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        g_ctx.id_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
        g_ctx.id_category         := pk_prof_utils.get_id_category(i_lang => NULL, i_prof => i_prof);
        g_ctx.id_dep_clin_serv := CASE
                                      WHEN i_id_dep_clin_serv IS NULL THEN
                                       get_dep_clin_serv(i_episode => i_episode, i_epis_pn => i_epis_pn)
                                      ELSE
                                       i_id_dep_clin_serv
                                  END;
        g_ctx.id_department       := get_department(i_episode => i_episode, i_epis_pn => i_epis_pn);
        g_ctx.flg_approach        := get_prof_approach(i_prof => i_prof);
        g_ctx.id_pn_note_type     := i_id_pn_note_type;
        g_ctx.soap_blocks         := tab_soap_blocks();
        g_ctx.data_blocks         := t_coll_dblock();
        g_ctx.buttons             := t_coll_button();
        g_ctx.task_types          := t_coll_dblock_task_type();
        g_ctx.id_episode          := i_episode;
        g_ctx.prof                := i_prof;
    
        IF i_epis_pn IS NOT NULL
        THEN
            SELECT ep.id_software
              INTO g_ctx.id_software
              FROM epis_pn ep
             WHERE ep.id_epis_pn = i_epis_pn;
        ELSE
            g_ctx.id_software := i_prof.software;
        END IF;
    
        RETURN g_ctx;
    
    END reset_ctx;

    /**
    * Reset session context variables.
    *
    * @param i_prof             logged professional structure
    * @param i_episode          episode identifier
    * @param i_id_pn_note_type  soap note type
    * @param i_epis_pn          soap note identifier
    *
    * @author                   Pedro Carneiro
    * @version                  2.6.0.5.2
    * @since                    2011/02/03
    */
    PROCEDURE reset_context
    (
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_epis_pn         IN epis_pn.id_epis_pn%TYPE
    ) IS
    BEGIN
        g_ctx := reset_ctx(i_prof            => i_prof,
                           i_episode         => i_episode,
                           i_id_pn_note_type => i_id_pn_note_type,
                           i_epis_pn         => i_epis_pn);
    
    END reset_context;

    /********************************************************************************************
    * returns profile_template permissions for a given area
    *
    * @param IN   i_lang           Language ID
    * @param IN   i_prof           Professional ID
    * @param IN   i_doc_area       Doc Area
    *
    * @param OUT  o_flg_write      Flg Write
    * @param OUT  o_flg_no_changes Flg No Changes
    *
    * @author                      Pedro Teixeira
    * @since                       01/10/2010
    ********************************************************************************************/
    FUNCTION get_doc_area_permissions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        o_flg_write      OUT summary_page_access.flg_write%TYPE,
        o_flg_no_changes OUT summary_page_access.flg_no_changes%TYPE
    ) RETURN BOOLEAN IS
    
        l_profile_template profile_template.id_profile_template%TYPE;
        l_flg_write        table_varchar := table_varchar();
        l_flg_no_changes   table_varchar := table_varchar();
    
    BEGIN
        IF i_prof IS NULL
           OR i_doc_area IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        -- check context
        IF g_ctx.id_profile_template IS NULL
        THEN
            l_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
        ELSE
            l_profile_template := g_ctx.id_profile_template;
        END IF;
    
        -- get l_flg_write, l_flg_no_changes
        SELECT spa.flg_write, spa.flg_no_changes
          BULK COLLECT
          INTO l_flg_write, l_flg_no_changes
          FROM summary_page_section sps, summary_page_access spa
         WHERE sps.id_doc_area = i_doc_area
           AND spa.id_summary_page_section = sps.id_summary_page_section
           AND spa.id_profile_template = l_profile_template;
    
        IF l_flg_write IS NULL
           OR l_flg_write.count < 1
        THEN
            o_flg_write      := pk_alert_constant.g_no;
            o_flg_no_changes := pk_alert_constant.g_no;
        ELSIF l_flg_write.count = 1
        THEN
            o_flg_write      := l_flg_write(l_flg_write.first);
            o_flg_no_changes := l_flg_no_changes(l_flg_no_changes.first);
        ELSE
            -- if we'll use the flg_write = 'N' then use the same index to pick the flg_no_changes
            FOR i IN l_flg_write.first .. l_flg_write.last
            LOOP
                o_flg_write      := l_flg_write(i);
                o_flg_no_changes := l_flg_no_changes(i);
            
                IF l_flg_write(i) = g_no
                THEN
                    EXIT;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;

    /********************************************************************************************
    * calculate flag values
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_doc_area        Doc Area
    * @param IN   i_flg_status      Flag Status
    * @param IN   i_professional    Record Professional
    * @param IN   i_data_area       Data Area
    *
    * @param OUT  o_flg_write       flg write
    * @param OUT  o_flg_cancel      flg cancel
    * @param OUT  o_flg_no_changes  flg no changes
    * @param OUT  o_flg_mode        flg mode
    * @param OUT  o_flg_switch_mode flg switch mode
    *
    * @author                       Pedro Teixeira
    * @since                        01/10/2010
    ********************************************************************************************/
    FUNCTION get_flags_permission
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_flg_status      IN epis_documentation.flg_status%TYPE,
        i_professional    IN professional.id_professional%TYPE,
        i_flg_origin      IN VARCHAR2,
        i_data_area       IN pn_data_block.data_area%TYPE,
        o_flg_write       OUT summary_page_access.flg_write%TYPE,
        o_flg_cancel      OUT summary_page_access.flg_write%TYPE,
        o_flg_no_changes  OUT summary_page_access.flg_no_changes%TYPE,
        o_flg_mode        OUT VARCHAR2,
        o_flg_switch_mode OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_error t_error_out;
    
    BEGIN
        -- get doc_area permissions
        g_error := 'CALL get_doc_area_permissions';
        IF NOT get_doc_area_permissions(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_doc_area       => i_doc_area,
                                        o_flg_write      => o_flg_write,
                                        o_flg_no_changes => o_flg_no_changes)
        THEN
            RETURN FALSE;
        END IF;
    
        -- flg_write and flg_cancel
        IF i_flg_status = pk_alert_constant.g_cancelled
        THEN
            o_flg_write  := g_no;
            o_flg_cancel := g_no;
        ELSE
            IF i_data_area IN (g_documentation_gpa, g_documentation_at)
            THEN
                o_flg_write := g_no;
            END IF;
        
            -- calculate flg_cancel value
            IF i_prof.id != i_professional
            THEN
                o_flg_cancel := g_no;
            ELSE
                IF o_flg_write = g_no
                THEN
                    o_flg_cancel := g_no;
                ELSE
                    IF i_flg_origin = g_doc_orig_ft
                    THEN
                        o_flg_cancel := g_no;
                    ELSE
                        o_flg_cancel := g_yes;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        -- get doc_area modes
        g_error := 'CALL pk_touch_option.get_touch_option_mode';
        IF NOT pk_touch_option.get_touch_option_mode(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_doc_area        => i_doc_area,
                                                     o_flg_mode        => o_flg_mode,
                                                     o_flg_switch_mode => o_flg_switch_mode,
                                                     o_error           => l_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Retrieve documentations for episode. Adapted from
    * PK_SUMMARY_PAGE.GET_SUMM_PAGE_DOC_AREA_VALUE.
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure   
    * @param i_episode           episode identifier
    * @param i_doc_area          set of documentation areas identifiers
    * @param i_doc_area_desc     documentation area internal description
    * @param o_doc_area_register cursor
    * @param o_doc_area_val      cursor
    * @param o_error             error
    *
    * @return                    false if errors occur, true otherwise
    *
    * @author                    Pedro Carneiro
    * @version                    2.5.0.7.3
    * @since                     2009/11/24
    ********************************************************************************************/
    PROCEDURE get_doc_area_val
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN table_number,
        i_doc_area_desc      IN VARCHAR2,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type
    ) IS
        l_msg_free_text       sys_message.desc_message%TYPE;
        l_msg_risk_lvl        sys_message.desc_message%TYPE;
        l_doc_area_hist_ill   VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_doc_area_rev_sys    VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_doc_area_phy_exam   VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_doc_area_phy_assess VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_id_epis_doc table_number := table_number();
    BEGIN
        l_msg_free_text := pk_message.get_message(i_lang, i_prof, 'PROGRESS_NOTES_M001');
        l_msg_risk_lvl  := pk_message.get_message(i_lang, i_prof, 'RISK_FACTORS_T011');
    
        -- check if any doc area defined
        IF i_doc_area.count = 0
        THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN;
        END IF;
    
        FOR i IN i_doc_area.first .. i_doc_area.last
        LOOP
            IF i_doc_area(i) = pk_summary_page.g_doc_area_hist_ill
            THEN
                l_doc_area_hist_ill := pk_alert_constant.g_yes;
            ELSIF i_doc_area(i) = pk_summary_page.g_doc_area_rev_sys
            THEN
                l_doc_area_rev_sys := pk_alert_constant.g_yes;
            ELSIF i_doc_area(i) = pk_summary_page.g_doc_area_phy_exam
            THEN
                l_doc_area_phy_exam := pk_alert_constant.g_yes;
            ELSIF i_doc_area(i) = pk_summary_page.g_doc_area_phy_assess
            THEN
                l_doc_area_phy_assess := pk_alert_constant.g_yes;
            END IF;
        END LOOP;
    
        --REGISTER: dt_creation, dt_register, dt_last_update, nick_name, desc_speciality
        g_error := 'OPEN o_doc_area_register';
        OPEN o_doc_area_register FOR
            SELECT ed.id_epis_documentation,
                   ed.id_epis_documentation_parent PARENT,
                   ed.id_doc_template,
                   pk_translation.get_translation(i_lang, dt.code_doc_template) template_desc,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, ed.dt_last_update_tstz, i_prof.institution, i_prof.software) dt_register,
                   ed.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ed.id_professional,
                                                    ed.dt_creation_tstz,
                                                    ed.id_episode) desc_speciality,
                   ed.id_doc_area,
                   ed.flg_status,
                   pk_string_utils.clob_to_sqlvarchar2(ed.notes) notes,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
                   decode((SELECT 0
                            FROM epis_documentation_det edd
                           WHERE edd.id_epis_documentation = ed.id_epis_documentation
                             AND rownum < 2),
                          NULL,
                          pk_summary_page.g_free_text,
                          pk_summary_page.g_touch_option) flg_type_register,
                   g_doc_orig_ed flg_origin,
                   decode(ed.id_doc_template,
                          NULL,
                          l_msg_free_text,
                          decode(i_doc_area_desc,
                                 g_documentation_at,
                                 -- for assessment tools, get section title first
                                 nvl((SELECT pk_translation.get_translation(i_lang, sps.code_summary_page_section)
                                       FROM summary_page_section sps
                                      WHERE sps.id_doc_area = ed.id_doc_area
                                        AND rownum < 2),
                                     pk_translation.get_translation(i_lang, dt.code_doc_template)),
                                 -- for others, get template title first
                                 nvl(pk_translation.get_translation(i_lang, dt.code_doc_template),
                                     (SELECT pk_translation.get_translation(i_lang, sps.code_summary_page_section)
                                        FROM summary_page_section sps
                                       WHERE sps.id_doc_area = ed.id_doc_area
                                         AND rownum < 2)))) title,
                   ed.dt_last_update_tstz dt_order,
                   pk_touch_option.g_flg_tab_origin_epis_doc flg_table_origin, -- Record has its origin in the epis_documentation table
                   decode(ed.flg_status,
                          pk_alert_constant.g_active,
                          NULL,
                          pk_sysdomain.get_domain('EPIS_DOCUMENTATION.FLG_STATUS', ed.flg_status, i_lang)) desc_status,
                   pk_progress_notes.get_signature(i_lang,
                                                   i_prof,
                                                   ed.id_professional,
                                                   ed.dt_last_update_tstz,
                                                   i_episode) prof_desc
              FROM (SELECT ed1.id_epis_documentation,
                           ed1.id_epis_documentation_parent,
                           ed1.id_doc_template,
                           ed1.dt_creation_tstz,
                           ed1.dt_last_update_tstz,
                           ed1.id_professional,
                           ed1.id_episode,
                           ed1.id_doc_area,
                           ed1.flg_status,
                           ed1.notes
                      FROM epis_documentation ed1
                     WHERE ed1.id_episode = i_episode
                    UNION ALL
                    SELECT ed2.id_epis_documentation,
                           ed2.id_epis_documentation_parent,
                           ed2.id_doc_template,
                           ed2.dt_creation_tstz,
                           ed2.dt_last_update_tstz,
                           ed2.id_professional,
                           ed2.id_episode,
                           ed2.id_doc_area,
                           ed2.flg_status,
                           ed2.notes
                      FROM epis_documentation ed2
                     WHERE ed2.id_episode_context = i_episode) ed
              LEFT JOIN doc_template dt
                ON ed.id_doc_template = dt.id_doc_template
             WHERE ed.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)
               AND ed.id_doc_area IN (SELECT t.column_value
                                        FROM TABLE(i_doc_area) t)
            UNION ALL
            -- History of present illness - free text
            SELECT ea.id_epis_anamnesis id_epis_documentation,
                   ea.id_epis_anamnesis_parent PARENT,
                   NULL id_doc_template,
                   NULL template_desc,
                   pk_date_utils.date_send_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof.institution, i_prof.software) dt_register,
                   ea.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ea.id_professional,
                                                    ea.dt_epis_anamnesis_tstz,
                                                    ea.id_episode) desc_speciality,
                   pk_summary_page.g_doc_area_hist_ill id_doc_area,
                   ea.flg_status,
                   pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) notes,
                   pk_date_utils.date_send_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof) dt_last_update,
                   pk_summary_page.g_free_text flg_type_register,
                   g_doc_orig_ft flg_origin,
                   l_msg_free_text title,
                   ea.dt_epis_anamnesis_tstz dt_order,
                   pk_touch_option.g_flg_tab_origin_epis_anamn flg_table_origin, -- Record has its origin in the epis_anamnesis table
                   decode(ea.flg_status,
                          pk_alert_constant.g_active,
                          NULL,
                          pk_sysdomain.get_domain('EPIS_ANAMNESIS.FLG_STATUS', ea.flg_status, i_lang)) desc_status,
                   pk_progress_notes.get_signature(i_lang,
                                                   i_prof,
                                                   ea.id_professional,
                                                   ea.dt_epis_anamnesis_tstz,
                                                   i_episode) prof_desc
              FROM (SELECT ea.id_epis_anamnesis,
                           ea.id_epis_anamnesis_parent,
                           ea.dt_epis_anamnesis_tstz,
                           ea.id_professional,
                           ea.id_episode,
                           ea.flg_status,
                           ea.desc_epis_anamnesis,
                           row_number() over(PARTITION BY ea.id_epis_anamnesis ORDER BY ea.dt_epis_anamnesis_tstz DESC) rn
                      FROM epis_anamnesis ea
                     WHERE ea.id_episode = i_episode
                       AND ea.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)
                       AND ea.flg_type = pk_clinical_info.g_flg_type_a
                       AND l_doc_area_hist_ill = pk_alert_constant.g_yes
                       AND ea.flg_temp != pk_clinical_info.g_flg_hist) ea
             WHERE ea.rn = 1
            UNION ALL
            -- Review of systems - free text
            SELECT ers.id_epis_review_systems id_epis_documentation,
                   ers.id_epis_review_systems_parent PARENT,
                   NULL id_doc_template,
                   NULL template_desc,
                   pk_date_utils.date_send_tsz(i_lang, ers.dt_creation_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, ers.dt_creation_tstz, i_prof.institution, i_prof.software) dt_register,
                   ers.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ers.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ers.id_professional,
                                                    ers.dt_creation_tstz,
                                                    ers.id_episode) desc_speciality,
                   pk_summary_page.g_doc_area_rev_sys id_doc_area,
                   ers.flg_status,
                   ers.desc_review_systems notes,
                   pk_date_utils.date_send_tsz(i_lang, ers.dt_creation_tstz, i_prof) dt_last_update,
                   pk_summary_page.g_free_text flg_type_register,
                   g_doc_orig_ft flg_origin,
                   l_msg_free_text title,
                   ers.dt_creation_tstz dt_order,
                   pk_touch_option.g_flg_tab_origin_epis_rev_sys flg_table_origin, -- Record has its origin in the epis_review_systems table
                   decode(ers.flg_status,
                          pk_alert_constant.g_active,
                          NULL,
                          pk_sysdomain.get_domain('EPIS_REVIEW_SYSTEMS.FLG_STATUS', ers.flg_status, i_lang)) desc_status,
                   pk_progress_notes.get_signature(i_lang, i_prof, ers.id_professional, ers.dt_creation_tstz, i_episode) prof_desc
              FROM epis_review_systems ers
             WHERE ers.id_episode = i_episode
               AND ers.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)
               AND l_doc_area_rev_sys = pk_alert_constant.g_yes
            UNION ALL
            -- Physical exam/assessment - free text
            SELECT eo.id_epis_observation id_epis_documentation,
                   eo.id_epis_observation_parent PARENT,
                   NULL id_doc_template,
                   NULL template_desc,
                   pk_date_utils.date_send_tsz(i_lang, eo.dt_epis_observation_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, eo.dt_epis_observation_tstz, i_prof.institution, i_prof.software) dt_register,
                   eo.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eo.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    eo.id_professional,
                                                    eo.dt_epis_observation_tstz,
                                                    eo.id_episode) desc_speciality,
                   decode(eo.flg_type,
                          pk_summary_page.g_epis_obs_flg_type_e,
                          pk_summary_page.g_doc_area_phy_exam,
                          pk_summary_page.g_epis_obs_flg_type_a,
                          pk_summary_page.g_doc_area_phy_assess) id_doc_area,
                   eo.flg_status,
                   eo.desc_epis_observation notes,
                   pk_date_utils.date_send_tsz(i_lang, eo.dt_epis_observation_tstz, i_prof) dt_last_update,
                   pk_summary_page.g_free_text flg_type_register,
                   g_doc_orig_ft flg_origin,
                   l_msg_free_text title,
                   eo.dt_epis_observation_tstz dt_order,
                   pk_touch_option.g_flg_tab_origin_epis_obs flg_table_origin, -- Record has its origin in the epis_observation table
                   decode(eo.flg_status,
                          pk_alert_constant.g_active,
                          NULL,
                          pk_sysdomain.get_domain('EPIS_OBSERVATION.FLG_STATUS', eo.flg_status, i_lang)) desc_status,
                   pk_progress_notes.get_signature(i_lang,
                                                   i_prof,
                                                   eo.id_professional,
                                                   eo.dt_epis_observation_tstz,
                                                   i_episode) prof_desc
              FROM epis_observation eo
             WHERE eo.id_episode = i_episode
               AND eo.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)
               AND eo.flg_temp != pk_clinical_info.g_flg_hist
               AND ((eo.flg_type = pk_summary_page.g_epis_obs_flg_type_e AND
                   l_doc_area_phy_exam = pk_alert_constant.g_yes) OR
                   (eo.flg_type = pk_summary_page.g_epis_obs_flg_type_a AND
                   l_doc_area_phy_assess = pk_alert_constant.g_yes))
             ORDER BY flg_status, dt_order DESC;
    
        --VAL: dt_reg
        g_error := 'OPEN o_doc_area_val';
        OPEN o_doc_area_val FOR
            SELECT ed.id_epis_documentation,
                   ed.id_doc_template,
                   d.id_documentation,
                   d.id_doc_component,
                   decr.id_doc_element_crit,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_reg,
                   pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                   dc.flg_type,
                   decode(sdv.value,
                          NULL,
                          pk_touch_option.get_element_description(i_lang,
                                                                  i_prof,
                                                                  de.flg_type,
                                                                  edd.value,
                                                                  edd.value_properties,
                                                                  decr.id_doc_element_crit,
                                                                  de.id_unit_measure_reference,
                                                                  de.id_master_item,
                                                                  decr.code_element_close),
                          '(' || pk_translation.get_translation(i_lang, s.code_scale_score) || ' - ' || sdv.value ||
                          ') - ' || pk_touch_option.get_element_description(i_lang,
                                                                            i_prof,
                                                                            de.flg_type,
                                                                            edd.value,
                                                                            edd.value_properties,
                                                                            decr.id_doc_element_crit,
                                                                            de.id_unit_measure_reference,
                                                                            de.id_master_item,
                                                                            decr.code_element_close)) desc_element,
                   pk_touch_option.get_formatted_value(i_lang,
                                                       i_prof,
                                                       de.flg_type,
                                                       edd.value,
                                                       edd.value_properties,
                                                       de.input_mask,
                                                       de.flg_optional_value,
                                                       de.flg_element_domain_type,
                                                       de.code_element_domain) VALUE,
                   ed.id_doc_area,
                   dtad.rank rank_component,
                   de.rank rank_element,
                   pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
                   pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
                   pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
                   de.display_format,
                   de.separator,
                   de.internal_name
              FROM (SELECT ed.id_epis_documentation, ed.id_doc_area, ed.id_doc_template, ed.dt_creation_tstz
                      FROM epis_documentation ed
                     WHERE ed.id_episode = i_episode
                    UNION ALL
                    SELECT ed.id_epis_documentation, ed.id_doc_area, ed.id_doc_template, ed.dt_creation_tstz
                      FROM epis_documentation ed
                     WHERE ed.id_episode_context = i_episode) ed
             INNER JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
             INNER JOIN documentation d
                ON edd.id_documentation = d.id_documentation
               AND d.flg_available = pk_alert_constant.g_yes
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_doc_template = ed.id_doc_template
               AND dtad.id_doc_area = ed.id_doc_area
               AND dtad.id_documentation = d.id_documentation
             INNER JOIN doc_component dc
                ON d.id_doc_component = dc.id_doc_component
               AND dc.flg_available = pk_alert_constant.g_yes
             INNER JOIN doc_element_crit decr
                ON edd.id_doc_element_crit = decr.id_doc_element_crit
             INNER JOIN doc_element de
                ON decr.id_doc_element = de.id_doc_element
              LEFT JOIN scales_doc_value sdv
                ON de.id_doc_element = sdv.id_doc_element
              LEFT JOIN scales s
                ON sdv.id_scales = s.id_scales
             WHERE ed.id_doc_area IN (SELECT /*+opt_estimate(table t rows=1)*/
                                       t.column_value id_doc_area
                                        FROM TABLE(i_doc_area) t)
            UNION ALL
            SELECT epis_d.id_epis_documentation,
                   NULL id_doc_template,
                   d.id_documentation,
                   dc.id_doc_component,
                   NULL id_doc_element_crit,
                   NULL dt_reg,
                   TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                   dc.flg_type,
                   NULL desc_element,
                   NULL VALUE,
                   d.id_doc_area,
                   d.rank rank_component,
                   NULL rank_element,
                   NULL desc_quantifier,
                   NULL desc_quantification,
                   NULL desc_qualification,
                   NULL display_format,
                   NULL separator,
                   NULL internal_name
              FROM documentation d
             INNER JOIN doc_component dc
                ON d.id_doc_component = dc.id_doc_component
             INNER JOIN (SELECT DISTINCT ed.id_epis_documentation, d.id_documentation_parent
                           FROM documentation d
                          INNER JOIN epis_documentation_det edd
                             ON d.id_documentation = edd.id_documentation
                          INNER JOIN epis_documentation ed
                             ON edd.id_epis_documentation = ed.id_epis_documentation
                          INNER JOIN doc_element_crit decr
                             ON edd.id_doc_element_crit = decr.id_doc_element_crit
                          WHERE (ed.id_episode = i_episode OR ed.id_episode_context = i_episode)
                            AND ed.id_doc_area IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                    t.column_value id_doc_area
                                                     FROM TABLE(i_doc_area) t)
                            AND d.flg_available = pk_alert_constant.g_yes
                            AND decr.flg_view = pk_summary_page.g_flg_view_summary
                            AND d.id_documentation_parent IS NOT NULL) epis_d
                ON d.id_documentation = epis_d.id_documentation_parent
             WHERE dc.flg_type = pk_summary_page.g_doc_title
               AND dc.flg_available = pk_alert_constant.g_available
               AND d.flg_available = pk_alert_constant.g_available
            UNION ALL
            SELECT ed.id_epis_documentation,
                   NULL id_doc_template,
                   NULL id_documentation,
                   NULL id_doc_component,
                   NULL id_doc_element_crit,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_reg,
                   decode(erf.desc_result, NULL, NULL, l_msg_risk_lvl) desc_doc_component,
                   NULL flg_type,
                   decode(erf.desc_result, NULL, NULL, pk_message.get_message(i_lang, i_prof, erf.desc_result)) desc_element,
                   NULL VALUE,
                   ed.id_doc_area,
                   NULL rank_component,
                   NULL rank_element,
                   NULL desc_quantifier,
                   NULL desc_quantification,
                   NULL desc_qualification,
                   NULL display_format,
                   NULL separator,
                   NULL internal_name
              FROM epis_risk_factor erf
              JOIN epis_documentation ed
                ON erf.id_epis_documentation = ed.id_epis_documentation
               AND erf.id_episode = ed.id_episode
              JOIN doc_area da
                ON ed.id_doc_area = da.id_doc_area
             WHERE erf.id_episode = i_episode
               AND ed.id_doc_area IN (SELECT t.column_value id_doc_area
                                        FROM TABLE(i_doc_area) t)
               AND da.flg_score = pk_alert_constant.g_yes
             ORDER BY id_epis_documentation, rank_component, rank_element;
    
        g_error := 'GET id_epis_documentation. i_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        SELECT ed.id_epis_documentation
          BULK COLLECT
          INTO l_id_epis_doc
          FROM epis_documentation ed
         WHERE ed.id_episode = i_episode
           AND ed.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_cancelled)
           AND ed.id_doc_area IN (SELECT t.column_value
                                    FROM TABLE(i_doc_area) t);
    
        g_error := 'GET CURSOR O_TEMPLATE_LAYOUTS';
        pk_alertlog.log_debug(g_error);
        OPEN o_template_layouts FOR
            SELECT dt.id_doc_template,
                   xmlquery('declare namespace tlyt="http://www.alert-online.com/2009/TemplateLayout"; $layout/tlyt:TemplateLayout[@idDocTemplate=$id_doc_template]/tlyt:DocArea[@idDocArea=$id_doc_area]' passing dt.template_layout AS "layout", CAST(d.id_doc_area AS NUMBER) AS "id_doc_area", CAST(dt.id_doc_template AS NUMBER) AS "id_doc_template" RETURNING content).getclobval() layout,
                   d.id_doc_area
              FROM doc_template dt
              JOIN (SELECT DISTINCT ed.id_doc_template, ed.id_doc_area
                      FROM epis_documentation ed
                     WHERE ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                         t.column_value
                                                          FROM TABLE(l_id_epis_doc) t)) d
                ON d.id_doc_template = dt.id_doc_template
             WHERE xmlexists('declare namespace tlyt="http://www.alert-online.com/2009/TemplateLayout"; $layout/tlyt:TemplateLayout[@idDocTemplate=$id_doc_template]/tlyt:DocArea[@idDocArea=$id_doc_area]'
                             passing dt.template_layout AS "layout",
                             CAST(d.id_doc_area AS NUMBER) AS "id_doc_area",
                             CAST(dt.id_doc_template AS NUMBER) AS "id_doc_template");
    
        g_error := 'GET CURSOR O_DOC_AREA_COMPONENT';
        pk_alertlog.log_debug(g_error);
        OPEN o_doc_area_component FOR
            SELECT d.id_documentation,
                   dc.flg_type,
                   TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                   d.id_doc_area
              FROM documentation d
             INNER JOIN doc_component dc
                ON d.id_doc_component = dc.id_doc_component
             WHERE d.flg_available = pk_alert_constant.g_available
               AND dc.flg_available = pk_alert_constant.g_available
               AND (d.id_doc_area, d.id_doc_template) IN
                   (SELECT DISTINCT ed.id_doc_area, ed.id_doc_template
                      FROM epis_documentation ed
                     WHERE ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                                         t.column_value
                                                          FROM TABLE(l_id_epis_doc) t));
    END get_doc_area_val;

    /********************************************************************************************
    * Internal function for template retrieval.
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_patient           patient identifier
    * @param i_episode           episode identifier
    * @param i_doc_area_desc     documentation area internal description
    * @param o_doc_reg           documentation register data
    * @param o_doc_val           documentation values
    * @param o_error             error
    *
    * @author                    Pedro Carneiro
    * @version                    2.5.0.7
    * @since                     2009/11/03
    ********************************************************************************************/
    PROCEDURE get_templates
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area_desc      IN VARCHAR2,
        o_doc_reg            OUT pk_types.cursor_type,
        o_doc_val            OUT pk_types.cursor_type,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type,
        o_error              OUT t_error_out
    ) IS
        l_summ_pages pk_types.cursor_type;
        l_sp_param   table_table_varchar := table_table_varchar();
        l_doc_areas  table_number := table_number();
    BEGIN
        -- "switch" i_doc_area_desc to find out which doc_areas are we getting data from
        IF i_doc_area_desc = g_documentation_hpi
        THEN
            l_doc_areas := table_number(pk_summary_page.g_doc_area_hist_ill);
        ELSIF i_doc_area_desc = g_documentation_rs
        THEN
            l_doc_areas := table_number(pk_summary_page.g_doc_area_rev_sys);
        ELSIF i_doc_area_desc = g_documentation_pe
        THEN
            l_doc_areas := table_number(pk_summary_page.g_doc_area_phy_exam);
        ELSIF i_doc_area_desc = g_documentation_oe
        THEN
            l_doc_areas := table_number(pk_summary_page.g_doc_area_ophthal_exam);
        ELSIF i_doc_area_desc = g_documentation_pa
        THEN
            l_doc_areas := table_number(pk_summary_page.g_doc_area_phy_assess);
        ELSIF i_doc_area_desc = g_documentation_pl
        THEN
            l_doc_areas := table_number(pk_summary_page.g_doc_area_plan);
        
        ELSIF i_doc_area_desc = g_documentation_gpa
        THEN
            l_doc_areas := table_number(1063,
                                        1064,
                                        1065,
                                        1066,
                                        1067,
                                        1068,
                                        1069,
                                        1070,
                                        1071,
                                        1072,
                                        1073,
                                        1074,
                                        1075,
                                        1076,
                                        1077,
                                        1078);
        ELSIF i_doc_area_desc = g_documentation_at
        THEN
            l_sp_param.extend(20);
        
            -- documentation areas for risk factors
            g_error := 'CALL pk_summary_page.get_summary_page_sections (RF)';
            IF NOT pk_summary_page.get_summary_page_sections(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_id_summary_page => g_risk_fact_summ_page,
                                                             i_pat             => i_patient,
                                                             o_sections        => l_summ_pages,
                                                             o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'FETCH l_summ_pages (RF)';
            FETCH l_summ_pages BULK COLLECT
                INTO l_sp_param(1),
                     l_sp_param(2),
                     l_sp_param(3),
                     l_sp_param(4),
                     l_sp_param(5),
                     l_sp_param(6),
                     l_sp_param(7),
                     l_sp_param(8),
                     l_sp_param(9),
                     l_sp_param(10),
                     l_sp_param(11),
                     l_sp_param(12),
                     l_sp_param(13),
                     l_sp_param(14),
                     l_sp_param(15),
                     l_sp_param(16),
                     l_sp_param(17),
                     l_sp_param(18),
                     l_sp_param(19),
                     l_sp_param(20);
        
            FOR i IN 1 .. l_sp_param(2).count
            LOOP
                l_doc_areas.extend;
                l_doc_areas(l_doc_areas.last) := l_sp_param(2) (i);
            END LOOP;
        
            -- documentation areas for functional evaluations
            g_error := 'CALL pk_summary_page.get_summary_page_sections (FE)';
            IF NOT pk_summary_page.get_summary_page_sections(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_id_summary_page => g_func_eval_summ_page,
                                                             i_pat             => i_patient,
                                                             o_sections        => l_summ_pages,
                                                             o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'FETCH l_summ_pages (FE)';
            FETCH l_summ_pages BULK COLLECT
                INTO l_sp_param(1),
                     l_sp_param(2),
                     l_sp_param(3),
                     l_sp_param(4),
                     l_sp_param(5),
                     l_sp_param(6),
                     l_sp_param(7),
                     l_sp_param(8),
                     l_sp_param(9),
                     l_sp_param(10),
                     l_sp_param(11),
                     l_sp_param(12),
                     l_sp_param(13),
                     l_sp_param(14),
                     l_sp_param(15),
                     l_sp_param(16),
                     l_sp_param(17),
                     l_sp_param(18),
                     l_sp_param(19),
                     l_sp_param(20);
        
            FOR i IN 1 .. l_sp_param(2).count
            LOOP
                l_doc_areas.extend;
                l_doc_areas(l_doc_areas.last) := l_sp_param(2) (i);
            END LOOP;
        END IF;
    
        g_error := 'CALL get_doc_area_val';
        get_doc_area_val(i_lang               => i_lang,
                         i_prof               => i_prof,
                         i_episode            => i_episode,
                         i_doc_area           => l_doc_areas,
                         i_doc_area_desc      => i_doc_area_desc,
                         o_doc_area_register  => o_doc_reg,
                         o_doc_area_val       => o_doc_val,
                         o_template_layouts   => o_template_layouts,
                         o_doc_area_component => o_doc_area_component);
    END get_templates;

    /**
    * Get application file name.
    *
    * @param i_app_file     application file identifier
    *
    * @return               file name (with extension)
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/25
    */
    FUNCTION get_app_file(i_app_file IN application_file.id_application_file%TYPE) RETURN application_file.file_name%TYPE IS
        l_app_file application_file.file_name%TYPE;
    BEGIN
        IF i_app_file IS NULL
        THEN
            l_app_file := NULL;
        ELSE
            g_error := 'SELECT l_app_file';
            BEGIN
                SELECT af.file_name || decode(af.file_extension, NULL, NULL, '.' || af.file_extension)
                  INTO l_app_file
                  FROM application_file af
                 WHERE af.id_application_file = i_app_file
                   AND af.flg_available = pk_alert_constant.g_yes;
            EXCEPTION
                WHEN no_data_found THEN
                    l_app_file := NULL;
            END;
        END IF;
    
        RETURN l_app_file;
    END get_app_file;

    /**
    * Get configured template search mode.
    *
    * @param i_prof         logged professional structure
    *
    * @return               template search mode
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5
    * @since                2011/01/24
    */
    FUNCTION get_dtc_search_mode(i_prof IN profissional) RETURN doc_area_inst_soft.flg_type%TYPE IS
        l_flg_type doc_area_inst_soft.flg_type%TYPE;
    BEGIN
        g_error    := 'CALL pk_touch_option.get_touch_option_type (g_doc_area_hist_ill)';
        l_flg_type := pk_touch_option.get_touch_option_type(i_prof     => i_prof,
                                                            i_doc_area => pk_summary_page.g_doc_area_hist_ill);
        IF l_flg_type IS NULL
        THEN
            g_error    := 'CALL pk_touch_option.get_touch_option_type (g_doc_area_rev_sys)';
            l_flg_type := pk_touch_option.get_touch_option_type(i_prof     => i_prof,
                                                                i_doc_area => pk_summary_page.g_doc_area_rev_sys);
            IF l_flg_type IS NULL
            THEN
                g_error    := 'CALL pk_touch_option.get_touch_option_type (g_doc_area_phy_exam)';
                l_flg_type := pk_touch_option.get_touch_option_type(i_prof     => i_prof,
                                                                    i_doc_area => pk_summary_page.g_doc_area_phy_exam);
                IF l_flg_type IS NULL
                THEN
                    g_error    := 'CALL pk_touch_option.get_touch_option_type (g_doc_area_phy_assess)';
                    l_flg_type := pk_touch_option.get_touch_option_type(i_prof     => i_prof,
                                                                        i_doc_area => pk_summary_page.g_doc_area_phy_assess);
                END IF;
            END IF;
        END IF;
    
        pk_alertlog.log_debug(text            => pk_utils.to_string(i_input => i_prof) || '|l_flg_type: ' || l_flg_type,
                              object_name     => g_package_name,
                              sub_object_name => 'GET_DTC_SEARCH_MODE');
    
        RETURN l_flg_type;
    END get_dtc_search_mode;

    /**
    * Get free text data blocks information.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_soap_blocks  free text data block identifiers
    *
    * @return               free text data block info
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/13
    */
    FUNCTION get_freetext_block_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_soap_blocks IN table_number
    ) RETURN t_coll_soap_block IS
    
        l_coll_soap_block t_coll_soap_block;
    
    BEGIN
        IF i_soap_blocks IS NULL
           OR i_soap_blocks.count < 1
        THEN
            l_coll_soap_block := t_coll_soap_block();
        ELSE
            g_error := 'SELECT t_rec_soap_block';
            SELECT t_rec_soap_block(id_pn_soap_block, desc_block, flg_type, rank)
              BULK COLLECT
              INTO l_coll_soap_block
              FROM (SELECT psb.id_pn_soap_block,
                           pk_message.get_message(i_lang, i_prof, psb.code_message_ti) desc_block,
                           psb.flg_type,
                           sb.rank
                      FROM pn_soap_block psb
                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                            t.column_value id_pn_soap_block, rownum rank
                             FROM TABLE(i_soap_blocks) t) sb
                        ON psb.id_pn_soap_block = sb.id_pn_soap_block)
             ORDER BY rank;
        END IF;
    
        RETURN l_coll_soap_block;
    END get_freetext_block_info;

    /**
    * Get free text data blocks information.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_soap_blocks  free text data block identifiers
    *
    * @return               free text data block info
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since                14-10-2011
    */
    FUNCTION get_freetext_block_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_soap_blocks_t IN tab_soap_blocks
    ) RETURN t_coll_soap_block IS
    
        l_coll_soap_block t_coll_soap_block;
    
    BEGIN
        IF i_soap_blocks_t IS NULL
           OR i_soap_blocks_t.count < 1
        THEN
            l_coll_soap_block := t_coll_soap_block();
        ELSE
            g_error := 'SELECT t_rec_soap_block';
            SELECT t_rec_soap_block(id_pn_soap_block, desc_block, flg_type, rank)
              BULK COLLECT
              INTO l_coll_soap_block
              FROM (SELECT psb.id_pn_soap_block,
                           pk_message.get_message(i_lang, i_prof, psb.code_message_ti) desc_block,
                           psb.flg_type,
                           sb.rank
                      FROM pn_soap_block psb
                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                            t.id_pn_soap_block id_pn_soap_block, rownum rank
                             FROM TABLE(i_soap_blocks_t) t) sb
                        ON psb.id_pn_soap_block = sb.id_pn_soap_block)
             ORDER BY rank;
        END IF;
    
        RETURN l_coll_soap_block;
    END get_freetext_block_info;

    /**
    * Get free text data block information.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_soap_block   free text data block identifier
    *
    * @return               free text data block info
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/10/13
    */
    FUNCTION get_freetext_block_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN t_rec_soap_block IS
    
        l_rec_soap_block  t_rec_soap_block;
        l_coll_soap_block t_coll_soap_block;
    
    BEGIN
        IF i_soap_block IS NULL
        THEN
            l_rec_soap_block := t_rec_soap_block(NULL, NULL, NULL, NULL);
        ELSE
            g_error           := 'CALL get_freetext_block_info';
            l_coll_soap_block := get_freetext_block_info(i_lang, i_prof, i_soap_blocks => table_number(i_soap_block));
            l_rec_soap_block  := l_coll_soap_block(l_coll_soap_block.last);
        END IF;
    
        RETURN l_rec_soap_block;
    END get_freetext_block_info;

    /**
    * Get free text data block information.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_soap_block   free text data block info
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Teixeira
    * @version               2.6.0.4
    * @since                2010/10/26
    */
    FUNCTION get_freetext_block_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_soap_block OUT t_coll_soap_block,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sblocks tab_soap_blocks := tab_soap_blocks();
    BEGIN
        g_error := 'CALL reset_context';
        reset_context(i_prof            => i_prof,
                      i_episode         => i_episode,
                      i_id_pn_note_type => pk_prog_notes_constants.g_note_type_id_amb_1,
                      i_epis_pn         => NULL);
    
        g_error   := 'CALL tf_sblock';
        l_sblocks := tf_sblock(i_prof            => i_prof,
                               i_id_episode      => g_ctx.id_episode,
                               i_market          => g_ctx.id_market,
                               i_department      => g_ctx.id_department,
                               i_dcs             => g_ctx.id_dep_clin_serv,
                               i_id_pn_note_type => g_ctx.id_pn_note_type,
                               i_software        => g_ctx.id_software);
    
        g_error      := 'CALL get_freetext_block_info';
        o_soap_block := get_freetext_block_info(i_lang => i_lang, i_prof => i_prof, i_soap_blocks_t => l_sblocks);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_FREETEXT_BLOCK_INFO',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_freetext_block_info;

    /********************************************************************************************
    * Get block sample text
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_sample_text Code sample text
    *
    * @return                   table with sample text structure
    *
    * @author                   Pedro Teixeira
    * @since                    19/10/2010
    ********************************************************************************************/
    FUNCTION get_block_sample_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_sample_text IN pn_soap_block.sample_text_code%TYPE
    ) RETURN table_varchar IS
    
        l_sample_text  table_varchar := table_varchar();
        l_cursor_param table_table_varchar := table_table_varchar();
        l_error        t_error_out;
        c_sample_text  pk_types.cursor_type;
    
    BEGIN
        -- basic input check
        IF i_sample_text IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        -- inits
        l_cursor_param.extend(6);
    
        -- call pk_sample_text.get_sample_text
        IF NOT pk_sample_text.get_sample_text(i_lang             => i_lang,
                                              i_sample_text_type => i_sample_text,
                                              i_patient          => i_patient,
                                              i_prof             => i_prof,
                                              o_sample_text      => c_sample_text,
                                              o_error            => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        -- fetch c_sample_text
        g_error := 'FETCH c_sample_text';
        FETCH c_sample_text BULK COLLECT
            INTO l_cursor_param(1), --
                 l_cursor_param(2), --
                 l_cursor_param(3), --
                 l_cursor_param(4), --
                 l_cursor_param(5), --
                 l_cursor_param(6);
        CLOSE c_sample_text;
    
        -- loop through c_sample_text records
        IF l_cursor_param(2) IS NOT NULL
           AND l_cursor_param(2).count > 0
        THEN
            FOR idx IN l_cursor_param(2).first .. l_cursor_param(2).last
            LOOP
                l_sample_text.extend;
                l_sample_text(l_sample_text.last) := l_cursor_param(2) (idx);
                l_sample_text.extend;
                l_sample_text(l_sample_text.last) := l_cursor_param(3) (idx);
            END LOOP;
        END IF;
    
        RETURN l_sample_text;
    END get_block_sample_text;

    /**
    * Can this profile edit the free text field? Y/N
    *
    * @param i_prof         logged professional structure
    * @param i_profile      logged professional profile
    * @param i_category     logged professional category
    * @param i_market       market identifier
    * @param i_data_block   data block identifier
    *
    * @return               'Y' has write access, 'N' doesn't
    *
    * @author               Pedro Teixeira
    * @version               2.6.0.4
    * @since                2010/11/26
    */
    FUNCTION get_prof_freetext_permission
    (
        i_prof       IN profissional,
        i_profile    IN profile_template.id_profile_template%TYPE,
        i_category   IN category.id_category%TYPE,
        i_market     IN market.id_market%TYPE,
        i_data_block IN pn_data_block.id_pn_data_block%TYPE
    ) RETURN pn_free_text_mkt.flg_write%TYPE IS
        l_ret pn_free_text_mkt.flg_write%TYPE;
    
        -- cursor objects are used to avoid throwing no_data_found        
        CURSOR c_ft_inst IS
            SELECT i.flg_write
              FROM pn_free_text_inst i
             WHERE i.id_institution = i_prof.institution
                  --AND i.id_profile_template = i_profile
               AND i.id_pn_data_block = i_data_block
                  
               AND ((nvl(i.id_software, 0) IN (0, i_prof.software) AND
                   i.flg_config_type = pk_prog_notes_constants.g_flg_config_type_software_s) OR
                   i.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_software_s)
               AND ((nvl(i.id_profile_template, 0) IN (0, i_profile) AND
                   i.flg_config_type = pk_prog_notes_constants.g_flg_config_type_proftempl_p) OR
                   i.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_proftempl_p)
               AND ((nvl(i.id_category, -1) IN (-1, i_category) AND
                   i.flg_config_type = pk_prog_notes_constants.g_flg_config_type_category_c) OR
                   i.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_category_c)
             ORDER BY i.id_software DESC, i.id_profile_template DESC, i.id_category DESC;
    
        CURSOR c_ft_mkt IS
            SELECT m.flg_write
              FROM pn_free_text_mkt m
             WHERE m.id_market IN (0, i_market)
                  --AND m.id_profile_template = i_profile
               AND m.id_pn_data_block = i_data_block
                  
               AND ((nvl(m.id_software, 0) IN (0, i_prof.software) AND
                   m.flg_config_type = pk_prog_notes_constants.g_flg_config_type_software_s) OR
                   m.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_software_s)
               AND ((nvl(m.id_profile_template, 0) IN (0, i_profile) AND
                   m.flg_config_type = pk_prog_notes_constants.g_flg_config_type_proftempl_p) OR
                   m.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_proftempl_p)
               AND ((nvl(m.id_category, -1) IN (-1, i_category) AND
                   m.flg_config_type = pk_prog_notes_constants.g_flg_config_type_category_c) OR
                   m.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_category_c)
             ORDER BY m.id_market DESC, m.id_software DESC, m.id_profile_template DESC, m.id_category DESC;
    
        l_check_functionality VARCHAR2(1 CHAR);
    BEGIN
    
        l_check_functionality := pk_prof_utils.check_has_functionality(i_lang        => NULL,
                                                                       i_prof        => i_prof,
                                                                       i_intern_name => pk_access.g_view_only_profile);
    
        IF l_check_functionality = pk_alert_constant.g_yes
        THEN
            RETURN pk_alert_constant.g_no;
        END IF;
    
        g_error := 'OPEN c_ft_inst';
        OPEN c_ft_inst;
        FETCH c_ft_inst
            INTO l_ret;
        g_found := c_ft_inst%FOUND;
        CLOSE c_ft_inst;
    
        IF g_found
        THEN
            NULL;
        ELSE
            g_error := 'OPEN c_ft_mkt';
            OPEN c_ft_mkt;
            FETCH c_ft_mkt
                INTO l_ret;
            CLOSE c_ft_mkt;
        END IF;
    
        RETURN l_ret;
    END get_prof_freetext_permission;

    /********************************************************************************************
    * get professional approach (S: SOAP; D: Default) -> to be passed to PK_ACCESS
    *
    * @param IN   i_prof        Professional ID
    *
    * @return                   Flag Approach
    *
    * @author                   Pedro Teixeira
    * @since                    30/11/2010
    ********************************************************************************************/
    FUNCTION get_prof_approach(i_prof IN profissional) RETURN profile_template.flg_approach%TYPE IS
        l_profile_template profile_template.id_profile_template%TYPE;
        l_flg_approach     profile_template.flg_approach%TYPE;
    BEGIN
        -- check context
        IF g_ctx.id_profile_template IS NULL
        THEN
            l_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
        ELSE
            l_profile_template := g_ctx.id_profile_template;
        END IF;
    
        -- get approach
        BEGIN
            SELECT pt.flg_approach
              INTO l_flg_approach
              FROM profile_template pt
             WHERE pt.id_profile_template = l_profile_template;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_approach := NULL;
        END;
    
        RETURN l_flg_approach;
    END get_prof_approach;

    /**
    * Get data block "mandatory" description.
    *
    * @param flg_mandatory     data block mandatory flag
    *
    * @return               data block "mandatory" description
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/02/15
    */
    FUNCTION get_mandatory_desc(i_flg_mandatory IN pn_dblock_mkt.flg_mandatory%TYPE) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1 CHAR);
    BEGIN
        IF i_flg_mandatory = pk_alert_constant.g_yes
        THEN
            IF g_ctx.id_pn_note_type <> pk_prog_notes_constants.g_note_type_id_amb_1
            THEN
                l_ret := g_star;
            ELSE
                l_ret := NULL;
            END IF;
        ELSE
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    END get_mandatory_desc;

    /**
    * Get the current soap note ID_CONTEXT_2 identifier.
    * This is to be used as an additional filter when searching for templates.
    *
    * @return               current soap note ID_CONTEXT_2 identifier
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/02/16
    */
    FUNCTION get_soap_note RETURN doc_template_context.id_context_2%TYPE IS
    BEGIN
        RETURN g_ctx.id_pn_note_type;
    END get_soap_note;

    /**
    * Get the number of immediate children of a button.
    *
    * @param i_button         button identifier
    * @param i_pn_soap_block soap block identifier
    *
    * @return               number of children
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/02/24
    */
    FUNCTION get_child_count
    (
        i_button        IN conf_button_block.id_conf_button_block%TYPE,
        i_pn_soap_block pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN PLS_INTEGER IS
        l_ret PLS_INTEGER;
    BEGIN
        g_error := 'Count child i_button: ' || i_button || ' i_pn_soap_block: ' || i_pn_soap_block;
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(*)
          INTO l_ret
          FROM TABLE(g_ctx.buttons) cbb
         WHERE cbb.id_parent = i_button
           AND cbb.id_pn_soap_block = i_pn_soap_block
           AND cbb.icon IS NOT NULL;
    
        RETURN l_ret;
    END get_child_count;

    -----------------------------------------------------------
    -----------------------------------------------------------
    PROCEDURE l_______________(i_lang IN language.id_language%TYPE) IS
    BEGIN
        dbms_output.put_line(i_lang);
    END;

    /**
    * Get configured soap and data blocks ordered collections,
    * and set them in context.
    *
    * @param i_prof         logged professional structure
    *
    * @author               Sofia Mendes
    * @version               2.6.2
    * @since                2011/01/27
    */
    PROCEDURE get_sblocks_dblocks
    (
        i_prof         IN profissional,
        io_configs_ctx IN OUT pk_prog_notes_types.t_configs_ctx
    ) IS
        l_dblocks_tmp   t_coll_dblock := t_coll_dblock();
        l_sblocks_tmp   tab_soap_blocks := tab_soap_blocks();
        l_sd_blocks_tmp tab_soap_blocks := tab_soap_blocks();
        l_search_res    PLS_INTEGER;
    BEGIN
        -- get configured soap blocks
        g_error                    := 'CALL tf_sblock';
        io_configs_ctx.soap_blocks := tf_sblock(i_prof            => i_prof,
                                                i_id_episode      => io_configs_ctx.id_episode,
                                                i_market          => io_configs_ctx.id_market,
                                                i_department      => io_configs_ctx.id_department,
                                                i_dcs             => io_configs_ctx.id_dep_clin_serv,
                                                i_id_pn_note_type => io_configs_ctx.id_pn_note_type,
                                                i_software        => io_configs_ctx.id_software);
    
        -- check profile approach
        IF io_configs_ctx.flg_approach != g_soap_approach
           AND io_configs_ctx.id_pn_note_type = 1
           AND i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_private_practice)
        THEN
            -- logic for ambulatory default approach:
            -- show only reason for visit block (when configured)
            IF search_tab_soap_blocks(i_table => io_configs_ctx.soap_blocks, i_search => g_soap_block_rea_vis) > 0
            THEN
                io_configs_ctx.soap_blocks := tab_soap_blocks(t_rec_soap_blocks(g_soap_block_rea_vis,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL));
            ELSE
                io_configs_ctx.soap_blocks := tab_soap_blocks();
            END IF;
        END IF;
    
        -- get configured data blocks
        g_error                    := 'CALL tf_data_blocks';
        io_configs_ctx.data_blocks := tf_data_blocks(i_prof            => i_prof,
                                                     i_market          => io_configs_ctx.id_market,
                                                     i_department      => io_configs_ctx.id_department,
                                                     i_dcs             => io_configs_ctx.id_dep_clin_serv,
                                                     i_id_pn_note_type => io_configs_ctx.id_pn_note_type,
                                                     i_software        => io_configs_ctx.id_software);
    
        /*for i in 1 .. io_configs_ctx.data_blocks.count loop
        dbms_output.put_line('..soapdblcok ' || io_configs_ctx.data_blocks(i).id_pn_soap_block);
        end loop;*/
    
        -- filter data blocks
        IF io_configs_ctx.data_blocks.count > 0
        THEN
            FOR i IN io_configs_ctx.data_blocks.first .. io_configs_ctx.data_blocks.last
            LOOP
                l_search_res := search_tab_soap_blocks(i_table  => io_configs_ctx.soap_blocks,
                                                       i_search => io_configs_ctx.data_blocks(i).id_pn_soap_block);
                -- put only those associated with a configured soap block
                IF l_search_res > 0
                THEN
                    l_dblocks_tmp.extend;
                    l_dblocks_tmp(l_dblocks_tmp.last) := io_configs_ctx.data_blocks(i);
                
                    l_sd_blocks_tmp.extend;
                    l_sd_blocks_tmp(l_sd_blocks_tmp.last) := io_configs_ctx.soap_blocks(l_search_res);
                END IF;
            END LOOP;
        
            io_configs_ctx.data_blocks := l_dblocks_tmp;
        END IF;
    
        -- filter soap blocks
        IF io_configs_ctx.soap_blocks.count > 0
        THEN
            FOR i IN io_configs_ctx.soap_blocks.first .. io_configs_ctx.soap_blocks.last
            LOOP
                -- put only those associated with at least one data block
                IF search_tab_soap_blocks(i_table  => l_sd_blocks_tmp,
                                          i_search => io_configs_ctx.soap_blocks(i).id_pn_soap_block) > 0
                THEN
                    l_sblocks_tmp.extend;
                    l_sblocks_tmp(l_sblocks_tmp.last) := io_configs_ctx.soap_blocks(i);
                END IF;
            END LOOP;
        
            io_configs_ctx.soap_blocks := l_sblocks_tmp;
        END IF;
    
    END get_sblocks_dblocks;

    /**
    * Get configured soap, data and button blocks ordered collections,
    * and set them in context.
    *
    * @param i_prof         logged professional structure
    * @param io_configs_ctx configs strcuture
    * @param i_soap_blocks  Soap blocks list to be considered
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/01/27
    */
    PROCEDURE get_all_blocks
    (
        i_prof         IN profissional,
        io_configs_ctx IN OUT pk_prog_notes_types.t_configs_ctx
    ) IS
        l_buttons_tmp t_coll_button := t_coll_button();
        l_func_name CONSTANT VARCHAR2(14 CHAR) := 'GET_ALL_BLOCKS';
    BEGIN
        g_error := 'CALL get_sblocks_dblocks';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        get_sblocks_dblocks(i_prof => i_prof, io_configs_ctx => io_configs_ctx);
    
        /*for i in 1 .. io_configs_ctx.soap_blocks.count loop
        dbms_output.put_line('..2 ' || io_configs_ctx.soap_blocks(i).id_pn_soap_block);
        end loop;*/
        -- get configured button blocks
        g_error := 'CALL tf_button_blocks';
        SELECT t_rec_button(t.id_pn_soap_block,
                            t.id_conf_button_block,
                            t.id_doc_area,
                            t.id_pn_task_type,
                            t.action,
                            t.id_parent,
                            t.icon,
                            t.flg_visible,
                            t.id_type,
                            t.rank,
                            t.flg_activation)
          BULK COLLECT
          INTO io_configs_ctx.buttons
          FROM TABLE(pk_progress_notes_upd.tf_button_blocks(i_prof,
                                                            g_ctx.id_profile_template,
                                                            g_ctx.id_category,
                                                            g_ctx.id_market,
                                                            g_ctx.id_department,
                                                            g_ctx.id_dep_clin_serv,
                                                            g_ctx.id_pn_note_type,
                                                            g_ctx.id_software)) t;
    
        -- filter button blocks
        IF io_configs_ctx.buttons.count > 0
        THEN
            FOR i IN io_configs_ctx.buttons.first .. io_configs_ctx.buttons.last
            LOOP
                -- put only those associated with a configured soap block
                IF search_tab_soap_blocks(i_table  => io_configs_ctx.soap_blocks,
                                          i_search => io_configs_ctx.buttons(i).id_pn_soap_block) > 0
                THEN
                    l_buttons_tmp.extend;
                    l_buttons_tmp(l_buttons_tmp.last) := io_configs_ctx.buttons(i);
                END IF;
            END LOOP;
        
            io_configs_ctx.buttons := l_buttons_tmp;
        END IF;
    
        -- get configured task_types
        g_error                   := 'CALL tf_sblock';
        io_configs_ctx.task_types := tf_dblock_task_type(i_lang             => NULL,
                                                         i_prof             => i_prof,
                                                         i_id_episode       => io_configs_ctx.id_episode,
                                                         i_id_market        => io_configs_ctx.id_market,
                                                         i_id_department    => io_configs_ctx.id_department,
                                                         i_id_dep_clin_serv => io_configs_ctx.id_dep_clin_serv,
                                                         i_id_pn_note_type  => io_configs_ctx.id_pn_note_type,
                                                         i_software         => io_configs_ctx.id_software);
    
    END get_all_blocks;

    /**
    * Checks if a data block is a leaf in the block structure.
    *
    * @param i_data_block   data block identifier
    *
    * @return               number of children
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/02/08
    */
    FUNCTION get_leaf(i_data_block IN pn_data_block.id_pn_data_block%TYPE) RETURN PLS_INTEGER IS
        l_ret PLS_INTEGER := 0;
    BEGIN
        g_error := 'SELECT l_ret';
        SELECT COUNT(*)
          INTO l_ret
          FROM TABLE(g_ctx.data_blocks) pdb
         WHERE pdb.id_pndb_parent = i_data_block;
    
        RETURN l_ret;
    END get_leaf;

    /********************************************************************************************
    * returns the soap block information for reports
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_soap_blocks Main cursor with SOAP Blocks
    * @param OUT  o_free_text   Free text records cursor
    * @param OUT  o_rea_visit   Reason for visit records cursor
    * @param OUT  o_app_type    Appointment type records cursor
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    03/11/2010
    ********************************************************************************************/
    FUNCTION get_rep_prog_notes_blocks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_soap_blocks OUT pk_types.cursor_type,
        o_free_text   OUT pk_types.cursor_type,
        o_rea_visit   OUT pk_types.cursor_type,
        o_app_type    OUT pk_types.cursor_type,
        o_prof_rec    OUT pk_translation.t_desc_translation,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_REP_PROG_NOTES_BLOCKS';
    BEGIN
        g_error := 'CALL reset_context';
        reset_context(i_prof            => i_prof,
                      i_episode         => i_episode,
                      i_id_pn_note_type => pk_prog_notes_constants.g_note_type_id_amb_1,
                      i_epis_pn         => NULL);
    
        IF g_ctx.flg_approach IS NULL
        THEN
            -- reports of episodes from other institutions, are retrieved changing the i_prof institution,
            -- and this can cause the user to be unregistered; assume soap approach in such cases
            g_ctx.flg_approach := g_soap_approach;
        END IF;
    
        g_error := 'CALL get_all_blocks';
        get_all_blocks(i_prof => i_prof, io_configs_ctx => g_ctx);
    
        -- get SOAP Blocks
        g_error := 'CALL get_soap_blocks : o_soap_blocks';
        IF NOT get_soap_blocks(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_patient     => i_patient,
                               i_retrieve_st => pk_alert_constant.g_no,
                               i_trans_dn    => pk_alert_constant.g_no,
                               o_blocks      => o_soap_blocks,
                               o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------------------------------------
        -- get assoc Blocks
        g_error := 'CALL get_assoc_blocks';
        IF NOT get_assoc_blocks(i_lang      => i_lang,
                                i_prof      => i_prof,
                                i_patient   => i_patient,
                                i_episode   => i_episode,
                                i_soap_list => g_ctx.soap_blocks,
                                o_free_text => o_free_text,
                                o_rea_visit => o_rea_visit,
                                o_app_type  => o_app_type,
                                o_prof_rec  => o_prof_rec,
                                o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns the soap block associated with the institution / software / clinical_service
    *
    * @param IN   i_lang          Language ID
    * @param IN   i_prof          Professional ID
    * @param IN   i_patient       Patient ID
    * @param IN   i_episode       Espisode ID
    * @param OUT  o_soap_blocks   Main cursor with SOAP Blocks
    * @param OUT  o_data_blocks   Data blocks
    * @param OUT  o_button_blocks Button Blocks with button configuration
    * @param OUT  o_simple_text   Simple Text blocks structure
    * @param OUT  o_doc_reg       Doccumentation registers
    * @param OUT  o_doc_val       Doccumentation registers values
    * @param OUT  o_free_text     Free text records cursor
    * @param OUT  o_rea_visit     Reason for visit records cursor
    * @param OUT  o_app_type      Appointment type records cursor
    * @param OUT  o_prof_rec      Author and date of last change
    * @param OUT  o_error         Error structure
    *
    * @author                     Pedro Teixeira
    * @since                      21/09/2010
    ********************************************************************************************/
    FUNCTION get_prog_notes_blocks
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_soap_blocks        OUT pk_types.cursor_type,
        o_data_blocks        OUT pk_types.cursor_type,
        o_button_blocks      OUT pk_types.cursor_type,
        o_simple_text        OUT pk_types.cursor_type,
        o_doc_reg            OUT pk_types.cursor_type,
        o_doc_val            OUT pk_types.cursor_type,
        o_free_text          OUT pk_types.cursor_type,
        o_rea_visit          OUT pk_types.cursor_type,
        o_app_type           OUT pk_types.cursor_type,
        o_screen_det         OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_rec   pk_translation.t_desc_translation;
        l_title_code sys_message.code_message%TYPE;
    BEGIN
        g_error := 'CALL reset_context';
        reset_context(i_prof            => i_prof,
                      i_episode         => i_episode,
                      i_id_pn_note_type => pk_prog_notes_constants.g_note_type_id_amb_1,
                      i_epis_pn         => NULL);
    
        g_error := 'CALL get_all_blocks';
        get_all_blocks(i_prof => i_prof, io_configs_ctx => g_ctx);
    
        -- get SOAP Blocks
        g_error := 'CALL get_soap_blocks : o_soap_blocks';
        IF NOT get_soap_blocks(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_patient     => i_patient,
                               i_retrieve_st => pk_alert_constant.g_yes,
                               i_trans_dn    => pk_alert_constant.g_yes,
                               o_blocks      => o_soap_blocks,
                               o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- get assoc Blocks
        g_error := 'CALL get_assoc_blocks';
        IF NOT get_assoc_blocks(i_lang      => i_lang,
                                i_prof      => i_prof,
                                i_patient   => i_patient,
                                i_episode   => i_episode,
                                i_soap_list => g_ctx.soap_blocks,
                                o_free_text => o_free_text,
                                o_rea_visit => o_rea_visit,
                                o_app_type  => o_app_type,
                                o_prof_rec  => l_prof_rec,
                                o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF g_ctx.flg_approach != g_soap_approach
           AND i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_private_practice)
        THEN
            -- when in ambulatory default approach
            -- show no data nor button blocks
            l_title_code := 'PREV_ENCOUNTER_T001';
            pk_types.open_my_cursor(i_cursor => o_data_blocks);
            pk_types.open_my_cursor(i_cursor => o_simple_text);
            pk_types.open_my_cursor(i_cursor => o_doc_reg);
            pk_types.open_my_cursor(i_cursor => o_doc_val);
            pk_types.open_my_cursor(i_cursor => o_button_blocks);
            pk_types.open_my_cursor(i_cursor => o_template_layouts);
            pk_types.open_my_cursor(i_cursor => o_doc_area_component);
        ELSE
            l_title_code := 'PROGRESS_NOTES_T001';
        
            -- get Data Blocks
            g_error := 'CALL get_data_blocks';
            IF NOT get_data_blocks(i_lang               => i_lang,
                                   i_prof               => i_prof,
                                   i_patient            => i_patient,
                                   i_episode            => i_episode,
                                   i_soap_list          => g_ctx.soap_blocks,
                                   o_data_blocks        => o_data_blocks,
                                   o_simple_text        => o_simple_text,
                                   o_doc_reg            => o_doc_reg,
                                   o_doc_val            => o_doc_val,
                                   o_template_layouts   => o_template_layouts,
                                   o_doc_area_component => o_doc_area_component,
                                   o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- get Button Blocks
            g_error := 'CALL get_button_blocks';
            IF NOT get_button_blocks(i_lang          => i_lang,
                                     i_prof          => i_prof,
                                     i_patient       => i_patient,
                                     i_episode       => i_episode,
                                     i_soap_list     => g_ctx.soap_blocks,
                                     o_button_blocks => o_button_blocks,
                                     o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        -- open output cursor: o_screen_det
        g_error := 'OPEN o_screen_det';
        OPEN o_screen_det FOR
            SELECT l_prof_rec prof_rec, pk_message.get_message(i_lang, i_prof, l_title_code) title
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_data_blocks);
            pk_types.open_my_cursor(o_button_blocks);
            pk_types.open_my_cursor(o_simple_text);
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            pk_types.open_my_cursor(o_screen_det);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROG_NOTES_BLOCKS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_data_blocks);
            pk_types.open_my_cursor(o_button_blocks);
            pk_types.open_my_cursor(o_simple_text);
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            pk_types.open_my_cursor(o_screen_det);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns the soap block associated with the institution / software / clinical_service, without buttons
    *
    * @param IN   i_lang          Language ID
    * @param IN   i_prof          Professional ID
    * @param IN   i_patient       Patient ID
    * @param IN   i_episode       Espisode ID
    * @param OUT  o_soap_blocks   Main cursor with SOAP Blocks
    * @param OUT  o_data_blocks   Data blocks
    * @param OUT  o_simple_text   Simple Text blocks structure
    * @param OUT  o_doc_reg       Doccumentation registers
    * @param OUT  o_doc_val       Doccumentation registers values
    * @param OUT  o_free_text     Free text records cursor
    * @param OUT  o_rea_visit     Reason for visit records cursor
    * @param OUT  o_app_type      Appointment type records cursor
    * @param OUT  o_prof_rec      Author and date of last change
    * @param OUT  o_error         Error structure
    *
    * @author                     Pedro Carneiro
    * @since                      20/12/2010
    ********************************************************************************************/
    FUNCTION get_prog_notes_blocks_no_btn
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_soap_blocks OUT pk_types.cursor_type,
        o_data_blocks OUT pk_types.cursor_type,
        o_simple_text OUT pk_types.cursor_type,
        o_doc_reg     OUT pk_types.cursor_type,
        o_doc_val     OUT pk_types.cursor_type,
        o_free_text   OUT pk_types.cursor_type,
        o_rea_visit   OUT pk_types.cursor_type,
        o_app_type    OUT pk_types.cursor_type,
        o_prof_rec    OUT pk_translation.t_desc_translation,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_template_layouts   pk_types.cursor_type;
        l_doc_area_component pk_types.cursor_type;
    BEGIN
        g_error := 'CALL reset_context';
        reset_context(i_prof            => i_prof,
                      i_episode         => i_episode,
                      i_id_pn_note_type => pk_prog_notes_constants.g_note_type_id_amb_1,
                      i_epis_pn         => NULL);
    
        -- inits
        g_dictation_hist := TRUE;
    
        g_error := 'CALL get_all_blocks';
        get_all_blocks(i_prof => i_prof, io_configs_ctx => g_ctx);
    
        -- get SOAP Blocks
        g_error := 'CALL get_soap_blocks : o_soap_blocks';
        IF NOT get_soap_blocks(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_patient     => i_patient,
                               i_retrieve_st => pk_alert_constant.g_no,
                               i_trans_dn    => pk_alert_constant.g_no,
                               o_blocks      => o_soap_blocks,
                               o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------------------------------------
        -- get Data Blocks
        g_error := 'CALL get_data_blocks';
        IF NOT get_data_blocks(i_lang               => i_lang,
                               i_prof               => i_prof,
                               i_patient            => i_patient,
                               i_episode            => i_episode,
                               i_soap_list          => g_ctx.soap_blocks,
                               o_data_blocks        => o_data_blocks,
                               o_simple_text        => o_simple_text,
                               o_doc_reg            => o_doc_reg,
                               o_doc_val            => o_doc_val,
                               o_template_layouts   => l_template_layouts,
                               o_doc_area_component => l_doc_area_component,
                               o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------------------------------------
        -- get assoc Blocks
        g_error := 'CALL get_assoc_blocks';
        IF NOT get_assoc_blocks(i_lang      => i_lang,
                                i_prof      => i_prof,
                                i_patient   => i_patient,
                                i_episode   => i_episode,
                                i_soap_list => g_ctx.soap_blocks,
                                o_free_text => o_free_text,
                                o_rea_visit => o_rea_visit,
                                o_app_type  => o_app_type,
                                o_prof_rec  => o_prof_rec,
                                o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_data_blocks);
            pk_types.open_my_cursor(o_simple_text);
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROG_NOTES_BLOCKS_NO_BTN',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_soap_blocks);
            pk_types.open_my_cursor(o_data_blocks);
            pk_types.open_my_cursor(o_simple_text);
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            RETURN FALSE;
    END get_prog_notes_blocks_no_btn;

    /********************************************************************************************
    * returns SOAP Blocks
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     patient identifier
    * @param IN   i_retrieve_st retrieve predefined texts? Y/N
    * @param IN   i_trans_dn    translate deepnav titles? Y/N
    * @param OUT  o_soap_blocks Main cursor with SOAP Blocks
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_soap_blocks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_retrieve_st   IN VARCHAR2,
        i_trans_dn      IN VARCHAR2,
        i_filter_search IN table_varchar DEFAULT NULL,
        o_blocks        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_filter_search NUMBER;
    BEGIN
    
        IF i_filter_search IS NULL
        THEN
            l_filter_search := 0;
        ELSE
            l_filter_search := i_filter_search.count();
        END IF;
    
        IF g_ctx.id_pn_note_type = pk_prog_notes_constants.g_note_type_id_amb_1
        THEN
            g_error := 'OPEN o_blocks (ambulatory)';
            OPEN o_blocks FOR
                SELECT block_id,
                       block_name,
                       block_full_name,
                       (g_screen_height / COUNT(*) over() - 1) block_height,
                       block_write_flg,
                       decode(i_retrieve_st,
                              pk_alert_constant.g_yes,
                              decode(block_write_flg,
                                     pk_alert_constant.g_yes,
                                     get_block_sample_text(i_lang, i_prof, i_patient, sample_text_code))) block_sample_text,
                       get_soap_shortcuts_available(i_lang => i_lang, i_prof => i_prof, i_pn_soap_block => block_id) flg_shortcuts_available,
                       pk_prog_notes_utils.has_soap_mandatory_block(i_prof            => i_prof,
                                                                    i_soap_block      => block_id,
                                                                    i_id_pn_note_type => g_ctx.id_pn_note_type,
                                                                    i_market          => g_ctx.id_market,
                                                                    i_department      => g_ctx.id_department,
                                                                    i_dcs             => g_ctx.id_dep_clin_serv,
                                                                    i_id_episode      => g_ctx.id_episode,
                                                                    i_software        => g_ctx.id_software) flg_mandatory
                  FROM (SELECT psb.id_pn_soap_block block_id,
                               pk_message.get_message(i_lang,
                                                      i_prof,
                                                      decode(i_trans_dn,
                                                             pk_alert_constant.g_yes,
                                                             psb.code_message_dn,
                                                             psb.code_message_ti)) block_name,
                               pk_message.get_message(i_lang, i_prof, psb.code_message_ti) block_full_name,
                               sb.rank,
                               get_prof_freetext_permission(i_prof,
                                                            g_ctx.id_profile_template,
                                                            g_ctx.id_category,
                                                            g_ctx.id_market,
                                                            db.id_pn_data_block) block_write_flg,
                               pdb.sample_text_code
                          FROM pn_soap_block psb
                          JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                t.id_pn_soap_block, rownum rank
                                 FROM TABLE(g_ctx.soap_blocks) t) sb
                            ON psb.id_pn_soap_block = sb.id_pn_soap_block
                          JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                t.id_pn_soap_block, t.id_pn_data_block
                                 FROM TABLE(g_ctx.data_blocks) t
                                WHERE t.flg_type = pk_prog_notes_constants.g_data_block_free_text) db
                            ON psb.id_pn_soap_block = db.id_pn_soap_block
                          JOIN pn_data_block pdb
                            ON db.id_pn_data_block = pdb.id_pn_data_block)
                 ORDER BY rank;
        ELSIF l_filter_search > 0
        THEN
            g_error := 'OPEN o_blocks ';
            OPEN o_blocks FOR
                SELECT psb.id_pn_soap_block block_id,
                       decode(sb.flg_show_title,
                              pk_prog_notes_constants.g_yes,
                              pk_message.get_message(i_lang, i_prof, psb.code_message_dn),
                              NULL) block_name,
                       sb.flg_execute_import,
                       psb.id_sys_button_viewer,
                       --af.file_name,
                       sb.file_name,
                       sb.file_extension,
                       sb.value_viewer,
                       psb.flg_wf_viewer,
                       get_soap_shortcuts_available(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_pn_soap_block => psb.id_pn_soap_block) flg_shortcuts_available,
                       pk_prog_notes_utils.has_soap_mandatory_block(i_prof            => i_prof,
                                                                    i_soap_block      => psb.id_pn_soap_block,
                                                                    i_id_pn_note_type => g_ctx.id_pn_note_type,
                                                                    i_market          => g_ctx.id_market,
                                                                    i_department      => g_ctx.id_department,
                                                                    i_dcs             => g_ctx.id_dep_clin_serv,
                                                                    i_id_episode      => g_ctx.id_episode,
                                                                    i_software        => g_ctx.id_software) flg_mandatory
                  FROM pn_soap_block psb
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                         t.id_pn_soap_block,
                         t.flg_execute_import,
                         t.flg_show_title,
                         rownum rank,
                         t.value_viewer,
                         file_name,
                         file_extension
                          FROM TABLE(g_ctx.soap_blocks) t) sb
                    ON psb.id_pn_soap_block = sb.id_pn_soap_block
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                         t.id_pn_soap_block, t.id_pn_data_block
                          FROM TABLE(g_ctx.data_blocks) t
                         WHERE t.flg_type IN (SELECT *
                                                FROM TABLE(i_filter_search))) db
                    ON psb.id_pn_soap_block = db.id_pn_soap_block
                
                 ORDER BY sb.rank;
        ELSE
            g_error := 'OPEN o_blocks';
            OPEN o_blocks FOR
                SELECT psb.id_pn_soap_block block_id,
                       decode(sb.flg_show_title,
                              pk_prog_notes_constants.g_yes,
                              pk_message.get_message(i_lang, i_prof, psb.code_message_dn),
                              NULL) block_name,
                       sb.flg_execute_import,
                       psb.id_sys_button_viewer,
                       --af.file_name,
                       sb.file_name,
                       sb.file_extension,
                       sb.value_viewer,
                       psb.flg_wf_viewer,
                       get_soap_shortcuts_available(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_pn_soap_block => psb.id_pn_soap_block) flg_shortcuts_available,
                       pk_prog_notes_utils.has_soap_mandatory_block(i_prof            => i_prof,
                                                                    i_soap_block      => psb.id_pn_soap_block,
                                                                    i_id_pn_note_type => g_ctx.id_pn_note_type,
                                                                    i_market          => g_ctx.id_market,
                                                                    i_department      => g_ctx.id_department,
                                                                    i_dcs             => g_ctx.id_dep_clin_serv,
                                                                    i_id_episode      => g_ctx.id_episode,
                                                                    i_software        => g_ctx.id_software) flg_mandatory
                  FROM pn_soap_block psb
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                         t.id_pn_soap_block,
                         t.flg_execute_import,
                         t.flg_show_title,
                         rownum rank,
                         t.value_viewer,
                         file_name,
                         file_extension
                          FROM TABLE(g_ctx.soap_blocks) t) sb
                    ON psb.id_pn_soap_block = sb.id_pn_soap_block
                 ORDER BY sb.rank;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SOAP_BLOCKS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_blocks);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_datepad_param
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_value   IN VARCHAR2,
        i_days_period IN NUMBER,
        i_id_episode  IN NUMBER,
        i_dt_purposed IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_format      OUT VARCHAR2,
        o_value       OUT VARCHAR2
    ) RETURN BOOLEAN IS
        l_value      VARCHAR2(30 CHAR);
        l_error      t_error_out;
        l_dt_tstz    TIMESTAMP WITH LOCAL TIME ZONE;
        l_format     VARCHAR2(30 CHAR);
        l_dt_tstz_2  TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_min     TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_max     TIMESTAMP WITH LOCAL TIME ZONE;
        l_in_icu     VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_func_name  VARCHAR2(30 CHAR) := 'GET_DATEPAD_PARAM';
        l_dt_birth   patient.dt_birth%TYPE;
        l_id_patient patient.id_patient%TYPE;
    
        l_flg_disch_status discharge.flg_status%TYPE;
        l_discharge_adm    discharge.dt_admin_tstz%TYPE;
        l_discharge_med    discharge.dt_med_tstz%TYPE;
        l_discharge_pend   discharge.dt_pend_tstz%TYPE;
    BEGIN
        g_error := '[get_datepad_param]i_flg_value:' || i_flg_value;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        CASE i_flg_value
            WHEN pk_prog_notes_constants.g_flg_value_a THEN
                -- Admission date
                IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_id_episode    => i_id_episode,
                                                         o_dt_begin_tstz => l_dt_tstz,
                                                         o_error         => l_error)
                THEN
                    RETURN TRUE;
                END IF;
            
                IF i_days_period IS NOT NULL
                THEN
                    l_dt_tstz := pk_date_utils.add_to_ltstz(l_dt_tstz, i_days_period, 'DAY');
                END IF;
                l_value := pk_date_utils.get_timestamp_str(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_timestamp => l_dt_tstz,
                                                           i_timezone  => NULL);
            
            WHEN pk_prog_notes_constants.g_flg_value_c THEN
                -- current timestamp
                l_dt_tstz := current_timestamp;
                IF i_days_period IS NOT NULL
                THEN
                    l_dt_tstz := pk_date_utils.add_to_ltstz(l_dt_tstz, i_days_period, 'DAY');
                END IF;
                l_value := pk_date_utils.date_send_tsz(i_lang, l_dt_tstz, i_prof);
            
            WHEN pk_prog_notes_constants.g_flg_value_e THEN
                -- expected discharge date
                IF NOT pk_discharge.get_discharge_schedule_date(i_lang            => i_lang,
                                                                i_prof            => i_prof,
                                                                i_id_episode      => i_id_episode,
                                                                o_discharge_date  => l_dt_tstz,
                                                                o_flg_hour_origin => l_format,
                                                                o_error           => l_error)
                THEN
                    RETURN FALSE;
                END IF;
                IF i_days_period IS NOT NULL
                THEN
                    l_dt_tstz := pk_date_utils.add_to_ltstz(l_dt_tstz, i_days_period, 'DAY');
                END IF;
                l_value := pk_date_utils.date_send_tsz(i_lang, l_dt_tstz, i_prof);
            WHEN pk_prog_notes_constants.g_flg_value_s THEN
                -- Service transfer date
                l_dt_tstz := pk_hand_off_core.get_last_trans_service_date(i_lang    => i_lang,
                                                                          i_prof    => i_prof,
                                                                          i_episode => i_id_episode);
                l_value   := pk_date_utils.date_send_tsz(i_lang, l_dt_tstz, i_prof);
            WHEN pk_prog_notes_constants.g_flg_value_p THEN
                IF i_dt_purposed IS NULL
                THEN
                    l_dt_tstz := current_timestamp;
                ELSE
                    -- Proposed date
                    l_dt_tstz := i_dt_purposed;
                END IF;
                IF i_days_period IS NOT NULL
                THEN
                    l_dt_tstz := pk_date_utils.add_to_ltstz(l_dt_tstz, i_days_period, 'DAY');
                END IF;
                l_value := pk_date_utils.date_send_tsz(i_lang, l_dt_tstz, i_prof);
            WHEN pk_prog_notes_constants.g_flg_value_icu_a THEN
                l_in_icu := pk_bmng.check_patient_in_icu(i_lang => i_lang, i_prof => i_prof, i_episode => i_id_episode);
                g_error  := '[get_datepad_param]l_in_icu:' || l_in_icu;
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                IF l_in_icu = pk_alert_constant.g_yes
                THEN
                    l_dt_tstz := pk_bmng.get_last_icu_in_date(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_id_episode);
                    IF i_days_period IS NOT NULL
                    THEN
                        l_dt_tstz := pk_date_utils.add_to_ltstz(l_dt_tstz, i_days_period, 'DAY');
                    END IF;
                    l_value := pk_date_utils.date_send_tsz(i_lang, l_dt_tstz, i_prof);
                ELSE
                    l_dt_tstz := NULL;
                    l_value   := NULL;
                END IF;
            WHEN pk_prog_notes_constants.g_flg_value_icu_d THEN
                -- last ICU pateint service transfer date
                l_dt_tstz := pk_bmng.get_last_icu_out_date(i_lang    => i_lang,
                                                           i_prof    => i_prof,
                                                           i_episode => i_id_episode);
                IF i_days_period IS NOT NULL
                THEN
                    l_dt_tstz := pk_date_utils.add_to_ltstz(l_dt_tstz, i_days_period, 'DAY');
                END IF;
                l_value := pk_date_utils.date_send_tsz(i_lang, l_dt_tstz, i_prof);
            WHEN pk_prog_notes_constants.g_flg_value_d THEN
                -- Discharge date
                IF NOT pk_discharge.get_discharge_dates(i_lang                 => i_lang,
                                                        i_prof                 => i_prof,
                                                        i_id_episode           => i_id_episode,
                                                        o_discharge_adm        => l_discharge_adm,
                                                        o_discharge_med        => l_discharge_med,
                                                        o_discharge_pend       => l_discharge_pend,
                                                        o_flg_discharge_status => l_flg_disch_status,
                                                        o_error                => l_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                l_dt_tstz := nvl(nvl(l_discharge_pend, l_discharge_med), l_discharge_adm);
                IF i_days_period IS NOT NULL
                THEN
                    l_dt_tstz := pk_date_utils.add_to_ltstz(l_dt_tstz, i_days_period, 'DAY');
                END IF;
                l_value := pk_date_utils.date_send_tsz(i_lang, l_dt_tstz, i_prof);
            WHEN pk_prog_notes_constants. g_flg_value_b THEN
                SELECT id_patient
                  INTO l_id_patient
                  FROM episode
                 WHERE id_episode = i_id_episode;
            
                l_dt_birth := pk_patient.get_pat_dt_birth(i_lang, i_prof, l_id_patient);
                l_value    := pk_date_utils.date_send(i_lang, l_dt_birth, i_prof);
        END CASE;
        o_value  := l_value;
        o_format := l_format;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_datepad_param;

    /********************************************************************************************
    * Get values parametrizations for a Data Block Area Type to define on KeyPad's
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_SCOPE                 Scope Identifier (for E-Episode Identifier, for V-Visit Identifier and for P-Patient Identifier
    * @param         I_SCOPE_TYPE            Scope type
    * @param         I_DBLOCKS               Data Blocks structure
    *
    * @value         I_SCOPE_TYPE            {*} 'E'- Episode {*} 'V'- Visit {*} 'P'- Patient
    *
    * @return                                A table function with the parametrizations by Data Block Area Type
    *
    * @author                                António Neto
    * @since                                 13-Feb-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION tf_keypad_param
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_scope       IN NUMBER,
        i_scope_type  IN VARCHAR2,
        i_dblocks     IN t_coll_dblock,
        i_task_types  IN t_coll_dblock_task_type,
        i_dt_purposed IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN t_coll_keypad_param IS
        l_error t_error_out;
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    
        e_invalid_argument  EXCEPTION;
        e_epis_start_date   EXCEPTION;
        e_arrival_date_time EXCEPTION;
        e_discharge_date    EXCEPTION;
    
        l_dt_cur     TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_dt_arrival TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_dt_min     TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_dt_max     TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_dt_birth   patient.dt_birth%TYPE;
    
        l_dt_val TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
        l_keypad_param      t_keypad_param;
        l_coll_keypad_param t_coll_keypad_param := t_coll_keypad_param();
        l_cd  CONSTANT pn_data_block.data_area%TYPE := pk_prog_notes_constants.g_data_block_cdate_cd;
        l_edd CONSTANT pn_data_block.data_area%TYPE := pk_prog_notes_constants.g_data_block_eddate_edd;
        l_adt CONSTANT pn_data_block.data_area%TYPE := pk_prog_notes_constants.g_data_block_arrivaldt_adt;
        l_ddt CONSTANT pn_data_block.data_area%TYPE := pk_prog_notes_constants.g_data_block_cdate_ddt;
    
        CURSOR dblocks_cur IS
            SELECT DISTINCT db.data_area,
                            db.flg_mandatory,
                            db.flg_min_value,
                            db.flg_max_value,
                            db.flg_default_value,
                            db.flg_format,
                            db.flg_validation,
                            db.min_days_period,
                            db.max_days_period,
                            db.default_days_period
              FROM TABLE(i_dblocks) db
             WHERE db.data_area IN (l_cd, l_edd, l_adt, l_ddt);
    
        CURSOR dbtask_types_cur IS
            SELECT DISTINCT db.id_task_type, db.flg_auto_populated
              FROM TABLE(i_task_types) db
             WHERE db.id_pn_data_block = pk_prog_notes_constants.g_dblock_eddate_93;
        l_num_param PLS_INTEGER := 0;
        l_format    VARCHAR2(24 CHAR);
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => l_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        FOR rec IN dblocks_cur
        LOOP
            l_keypad_param := t_keypad_param(rec.data_area, NULL, NULL, NULL, NULL, NULL, NULL);
        
            g_error := 'CALCULATE KEYPAD PARAMETERS';
            IF rec.flg_min_value IS NOT NULL
               OR rec.flg_max_value IS NOT NULL
               OR rec.flg_default_value IS NOT NULL
            THEN
                -- min value
                IF NOT get_datepad_param(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_flg_value   => rec.flg_min_value,
                                         i_days_period => rec.min_days_period,
                                         i_id_episode  => l_id_episode,
                                         i_dt_purposed => i_dt_purposed,
                                         o_format      => l_format,
                                         o_value       => l_keypad_param.min_value)
                THEN
                    NULL;
                END IF;
                -- max value 
                IF NOT get_datepad_param(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_flg_value   => rec.flg_max_value,
                                         i_days_period => rec.max_days_period,
                                         i_id_episode  => l_id_episode,
                                         i_dt_purposed => i_dt_purposed,
                                         o_format      => l_format,
                                         o_value       => l_keypad_param.max_value)
                THEN
                    NULL;
                END IF;
                -- default value 
                IF NOT get_datepad_param(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_flg_value   => rec.flg_default_value,
                                         i_days_period => rec.default_days_period,
                                         i_id_episode  => l_id_episode,
                                         i_dt_purposed => i_dt_purposed,
                                         o_format      => l_keypad_param.flg_format,
                                         o_value       => l_keypad_param.cur_value)
                THEN
                    NULL;
                END IF;
                IF l_keypad_param.flg_format IS NULL
                THEN
                    l_keypad_param.flg_format := nvl(rec.flg_format, pk_prog_notes_constants.g_format_datetime_dh);
                END IF;
                l_keypad_param.flg_validation := nvl(rec.flg_validation,
                                                     pk_prog_notes_constants.g_validation_datetime_dt);
            
                l_keypad_param.flg_may_clean := CASE
                                                    WHEN rec.flg_mandatory = pk_alert_constant.g_yes THEN
                                                     pk_alert_constant.g_no
                                                    ELSE
                                                     pk_alert_constant.g_yes
                                                END;
            ELSE
                CASE l_keypad_param.data_area
                    WHEN l_cd THEN
                    
                        --Current Date
                        g_error := 'CALL pk_episode.get_epis_dt_begin';
                        pk_alertlog.log_debug(g_error);
                    
                        IF NOT pk_episode.get_epis_dt_begin(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_episode => l_id_episode,
                                                            o_dt_begin   => l_keypad_param.min_value,
                                                            o_error      => l_error)
                        THEN
                            RAISE e_epis_start_date;
                        END IF;
                    
                        l_keypad_param.flg_format     := pk_prog_notes_constants.g_format_datetime_dh;
                        l_keypad_param.cur_value      := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
                        l_keypad_param.max_value      := l_keypad_param.cur_value;
                        l_keypad_param.flg_may_clean := CASE
                                                            WHEN rec.flg_mandatory = pk_alert_constant.g_yes THEN
                                                             pk_alert_constant.g_no
                                                            ELSE
                                                             pk_alert_constant.g_yes
                                                        END;
                        l_keypad_param.flg_validation := pk_prog_notes_constants.g_validation_datetime_dt;
                    
                    WHEN l_edd THEN
                        --Expected Discharge Date
                    
                        FOR r_task IN dbtask_types_cur
                        LOOP
                            IF r_task.flg_auto_populated = pk_alert_constant.g_yes
                            THEN
                            
                                g_error := 'CALL pk_discharge.get_discharge_schedule_date';
                                pk_alertlog.log_debug(g_error);
                                IF NOT pk_discharge.get_discharge_schedule_date(i_lang            => i_lang,
                                                                                i_prof            => i_prof,
                                                                                i_id_episode      => l_id_episode,
                                                                                o_discharge_date  => l_dt_cur,
                                                                                o_flg_hour_origin => l_keypad_param.flg_format,
                                                                                o_error           => l_error)
                                THEN
                                    RAISE e_discharge_date;
                                END IF;
                                l_keypad_param.cur_value := pk_date_utils.date_send_tsz(i_lang, l_dt_cur, i_prof);
                            
                            END IF;
                        END LOOP;
                        l_keypad_param.flg_format := CASE
                                                         WHEN l_keypad_param.flg_format IS NULL THEN
                                                          pk_prog_notes_constants.g_format_datetime_dh
                                                         ELSE
                                                          l_keypad_param.flg_format
                                                     END;
                        l_keypad_param.max_value      := NULL;
                        l_keypad_param.min_value      := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
                        l_keypad_param.flg_may_clean  := pk_alert_constant.g_no;
                        l_keypad_param.flg_validation := pk_prog_notes_constants.g_validation_date_partial_dtp;
                        --   END LOOP;
                    WHEN l_adt THEN
                        --Arrival Date Time
                    
                        g_error := 'CALL pk_episode.get_intake_time_lim. l_id_episode: ' || l_id_episode;
                        pk_alertlog.log_debug(g_error);

                        IF NOT pk_episode.get_intake_time_lim(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_episode    => l_id_episode,
                                                              o_dt_cur     => l_dt_cur,
                                                              o_dt_arrival => l_dt_arrival,
                                                              o_dt_min     => l_dt_min,
                                                              o_dt_max     => l_dt_max,
                                                              o_error      => l_error)
                        THEN
                            RAISE e_arrival_date_time;
                        END IF;

                        l_keypad_param.flg_format     := pk_prog_notes_constants.g_format_datetime_dh;
                        l_keypad_param.cur_value      := pk_date_utils.date_send_tsz(i_lang,
                                                                                     nvl(l_dt_arrival, l_dt_cur),
                                                                                     i_prof);
                        l_keypad_param.max_value      := pk_date_utils.date_send_tsz(i_lang, l_dt_max, i_prof);
                        l_keypad_param.min_value      := pk_date_utils.date_send_tsz(i_lang, l_dt_min, i_prof);
                        l_keypad_param.flg_may_clean  := pk_alert_constant.g_no;
                        l_keypad_param.flg_validation := pk_prog_notes_constants.g_validation_datetime_dt;
                    WHEN l_ddt THEN
                        --Dissease Date Time
                        l_dt_birth                    := pk_patient.get_pat_dt_birth(i_lang, i_prof, l_id_patient);
                        l_keypad_param.flg_format     := pk_prog_notes_constants.g_format_datetime_dh;
                        l_keypad_param.cur_value      := NULL;
                        l_keypad_param.max_value      := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
                        l_keypad_param.min_value      := pk_date_utils.date_send(i_lang, l_dt_birth, i_prof);
                        l_keypad_param.flg_may_clean  := pk_alert_constant.g_yes;
                        l_keypad_param.flg_validation := pk_prog_notes_constants.g_validation_datetime_dt;
                    ELSE
                        --Others return for all positions null
                        l_keypad_param.flg_format     := NULL;
                        l_keypad_param.cur_value      := NULL;
                        l_keypad_param.max_value      := NULL;
                        l_keypad_param.min_value      := NULL;
                        l_keypad_param.flg_may_clean  := NULL;
                        l_keypad_param.flg_validation := NULL;
                END CASE;
            END IF;
            l_coll_keypad_param.extend;
            l_num_param := l_num_param + 1;
            l_coll_keypad_param(l_num_param) := l_keypad_param;
        END LOOP;
    
        RETURN l_coll_keypad_param;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'TF_KEYPAD_PARAM',
                                              o_error    => l_error);
        
            RETURN NULL;
    END tf_keypad_param;

    /**
    * Open the soap data blocks cursor.
    * Considers data block parenting.
    *
    * @param    i_lang          Language ID
    * @param    i_prof          Professional structure identifiers
    * @param    i_patient       Patient Identifier
    * @param    i_episode       Espisode Identifier
    * @param    o_data_blocks   soap data blocks cursor
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5.2
    * @since                2011/02/08
    */
    PROCEDURE get_data_blocks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_data_blocks OUT pk_types.cursor_type
    ) IS
        l_scope_type          VARCHAR2(1 CHAR) := pk_alert_constant.g_scope_type_episode;
        l_coll_keypad_param   t_coll_keypad_param;
        l_check_functionality VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'CALL tf_keypad_param';
        pk_alertlog.log_debug(g_error);
        l_coll_keypad_param := tf_keypad_param(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_scope      => i_episode,
                                               i_scope_type => l_scope_type,
                                               i_dblocks    => g_ctx.data_blocks,
                                               i_task_types => g_ctx.task_types);
    
        l_check_functionality := pk_prof_utils.check_has_functionality(i_lang        => NULL,
                                                                       i_prof        => i_prof,
                                                                       i_intern_name => pk_access.g_view_only_profile);
    
        g_error := 'OPEN o_data_blocks';
        pk_alertlog.log_debug(g_error);
        OPEN o_data_blocks FOR
            SELECT db3.id_pn_soap_block block_id,
                   db3.id_pn_data_block,
                   db3.data_area,
                   db3.id_doc_area,
                   db3.area_name || db3.mandatory_desc area_name,
                   db3.parent_name,
                   decode(db3.mandatory_desc,
                          NULL,
                          decode(db3.dblock_count, 1, NULL, nvl(db3.parent_name, db3.root)),
                          nvl(db3.parent_name, db3.root)) root_name,
                   db3.flg_type,
                   db3.flg_import,
                   db3.flg_select,
                   db3.flg_scope,
                   db3.flg_write,
                   db3.sample_text_code,
                   CASE
                        WHEN db3.flg_type IN (pk_prog_notes_constants.g_data_block_free_text,
                                              pk_prog_notes_constants.g_dblock_free_text_w_save) THEN
                         decode(db3.flg_write,
                                pk_alert_constant.g_yes,
                                get_block_sample_text(i_lang, i_prof, i_patient, db3.sample_text_code))
                        ELSE
                         NULL
                    END predefined_text,
                   decode(db3.id_pn_data_block, g_data_block_dictation, g_di_shortcut) shortcut,
                   CASE
                        WHEN db3.id_doc_area IS NOT NULL THEN
                         pk_summary_page.get_flg_no_changes_by_doc_area(i_lang, i_prof, db3.id_doc_area)
                        ELSE
                         pk_alert_constant.g_no
                    END flg_no_changes,
                   db3.flg_actions_available,
                   db3.flg_line_on_boxes,
                   db3.gender,
                   db3.age_min,
                   db3.age_max,
                   db3.flg_pregnant,
                   db3.flg_mandatory,
                   db3.id_sys_button_viewer,
                   db3.file_name,
                   db3.file_extension,
                   db3.flg_wf_viewer,
                   t_keypad.flg_may_clean,
                   t_keypad.flg_format,
                   t_keypad.cur_value,
                   t_keypad.min_value,
                   t_keypad.max_value,
                   t_keypad.flg_validation flg_input_type,
                   db3.flg_show_sub_title,
                   pk_prog_notes_utils.get_flg_synch_area(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_coll_dblock_task_type => g_ctx.task_types,
                                                          i_id_pn_data_block      => db3.id_pn_data_block) flg_synch_area,
                   db3.id_task_type id_pn_task_type,
                   db3.sample_text_comment,
                   db3.flg_focus,
                   db3.flg_editable
              FROM (SELECT db2.id_pn_soap_block,
                           db2.id_pn_data_block,
                           db2.data_area,
                           db2.id_doc_area,
                           db2.area_name,
                           pk_utils.str_token(db2.path, db2.depth, '|') parent_name,
                           get_mandatory_desc(db2.flg_mandatory) mandatory_desc,
                           db2.root,
                           db2.flg_type,
                           db2.sample_text_code,
                           db2.flg_import,
                           db2.flg_select,
                           db2.flg_scope,
                           decode(l_check_functionality,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no,
                                  decode(db2.flg_editable,
                                         pk_alert_constant.g_no,
                                         pk_alert_constant.g_no,
                                         decode(db2.flg_type,
                                                pk_prog_notes_constants.g_data_block_free_text,
                                                get_prof_freetext_permission(i_prof,
                                                                             g_ctx.id_profile_template,
                                                                             g_ctx.id_category,
                                                                             g_ctx.id_market,
                                                                             db2.id_pn_data_block),
                                                pk_prog_notes_constants.g_dblock_free_text_w_save,
                                                pk_alert_constant.g_yes,
                                                pk_prog_notes_constants.g_data_block_cdate,
                                                pk_alert_constant.g_yes,
                                                decode(db2.flg_import,
                                                       pk_prog_notes_constants.g_import_text,
                                                       pk_alert_constant.g_yes,
                                                       pk_prog_notes_constants.g_import_block,
                                                       pk_alert_constant.g_no,
                                                       decode(db2.flg_type,
                                                              pk_prog_notes_constants.g_data_block_doc,
                                                              pk_alert_constant.g_no,
                                                              pk_alert_constant.g_yes))))) flg_write,
                           db2.rn_rank,
                           db2.dblock_count,
                           db2.flg_actions_available,
                           db2.flg_line_on_boxes,
                           db2.gender,
                           db2.age_min,
                           db2.age_max,
                           db2.flg_pregnant,
                           db2.flg_mandatory,
                           db2.id_sys_button_viewer,
                           db2.file_name,
                           db2.file_extension,
                           db2.flg_wf_viewer,
                           db2.flg_show_sub_title,
                           db2.sample_text_comment,
                           db2.flg_focus,
                           db2.flg_editable,
                           db2.id_task_type
                      FROM (SELECT db.id_pn_soap_block,
                                   db.id_pn_data_block,
                                   db.id_pndb_parent,
                                   db.data_area,
                                   db.id_doc_area,
                                   db.area_name,
                                   db.flg_type,
                                   db.sample_text_code,
                                   db.flg_import,
                                   db.flg_select,
                                   db.flg_scope,
                                   db.rn_rank,
                                   db.dblock_count,
                                   db.flg_actions_available,
                                   db.flg_line_on_boxes,
                                   db.gender,
                                   db.age_min,
                                   db.age_max,
                                   db.flg_pregnant,
                                   db.flg_mandatory,
                                   sys_connect_by_path(db.area_name, '|') path,
                                   connect_by_root db.area_name root,
                                   LEVEL depth,
                                   connect_by_isleaf leaf,
                                   db.id_sys_button_viewer,
                                   db.file_name,
                                   db.file_extension,
                                   db.flg_wf_viewer,
                                   db.flg_show_sub_title,
                                   db.sample_text_comment,
                                   db.flg_focus,
                                   db.flg_editable,
                                   db.id_task_type
                              FROM (SELECT db.id_pn_soap_block,
                                           db.id_pn_data_block,
                                           db.id_pndb_parent,
                                           pdb.data_area,
                                           pdb.id_doc_area,
                                           decode(pdb.id_pn_data_block,
                                                  g_data_block_local,
                                                  pk_message.get_message(i_lang, i_prof, db.code_pn_data_block),
                                                  decode(db.desc_function,
                                                         NULL,
                                                         --Change translation to sys_message Start--
                                                         --pk_translation.get_translation(i_lang, db.code_pn_data_block)) area_name,
                                                         pk_message.get_message(i_lang, i_prof, db.code_pn_data_block),
                                                         pk_prog_notes_utils.get_dblock_description(i_lang,
                                                                                                    i_prof,
                                                                                                    db.desc_function,
                                                                                                    i_episode))) area_name,
                                           --Change translation to sys_message Start--
                                           pdb.flg_type,
                                           pdb.sample_text_code,
                                           db.flg_import,
                                           db.flg_select,
                                           db.flg_scope,
                                           row_number() over(ORDER BY sb.rank, db.rank) rn_rank,
                                           COUNT(*) over(PARTITION BY db.id_pn_soap_block) dblock_count,
                                           db.flg_actions_available,
                                           db.flg_line_on_boxes,
                                           db.gender,
                                           db.age_min,
                                           db.age_max,
                                           db.flg_pregnant,
                                           db.flg_mandatory,
                                           db.id_sys_button_viewer,
                                           af.file_name,
                                           af.file_extension,
                                           db.flg_wf_viewer,
                                           db.flg_show_sub_title,
                                           pdb.sample_text_comment,
                                           db.flg_focus,
                                           db.flg_editable,
                                           pdb.id_task_type
                                      FROM pn_data_block pdb
                                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                            t.id_pn_soap_block,
                                            t.id_pn_data_block,
                                            t.code_pn_data_block,
                                            t.flg_import,
                                            t.flg_select,
                                            t.flg_scope,
                                            t.rank,
                                            t.flg_actions_available,
                                            t.id_swf_file_viewer,
                                            t.flg_line_on_boxes,
                                            t.gender,
                                            t.age_min,
                                            t.age_max,
                                            t.flg_pregnant,
                                            t.flg_mandatory,
                                            t.id_sys_button_viewer,
                                            t.flg_wf_viewer,
                                            t.id_pndb_parent,
                                            t.flg_struct_type,
                                            t.flg_show_sub_title,
                                            t.flg_show_title,
                                            t.flg_focus,
                                            t.flg_editable,
                                            t.desc_function
                                             FROM TABLE(g_ctx.data_blocks) t) db
                                        ON pdb.id_pn_data_block = db.id_pn_data_block
                                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                            t.id_pn_soap_block, t.rank
                                             FROM TABLE(g_ctx.soap_blocks) t) sb
                                        ON db.id_pn_soap_block = sb.id_pn_soap_block
                                      LEFT OUTER JOIN application_file af
                                        ON af.id_application_file = db.id_swf_file_viewer
                                     WHERE pdb.flg_type NOT IN
                                           (pk_prog_notes_constants.g_dblock_strut_date,
                                            pk_prog_notes_constants.g_dblock_strut_group,
                                            pk_prog_notes_constants.g_dblock_strut_subgroup)
                                       AND db.flg_struct_type != pk_prog_notes_constants.g_struct_type_import_i) db
                            CONNECT BY PRIOR db.id_pn_data_block = db.id_pndb_parent
                             START WITH db.id_pndb_parent IS NULL) db2
                     WHERE db2.leaf = 1
                       AND db2.flg_type != pk_prog_notes_constants.g_data_block_strut
                          -- return no free text data blocks in ambulatory soap notes
                       AND (g_ctx.id_pn_note_type = pk_prog_notes_constants.g_note_type_id_amb_1 AND
                           db2.flg_type != pk_prog_notes_constants.g_data_block_free_text OR
                           g_ctx.id_pn_note_type != pk_prog_notes_constants.g_note_type_id_amb_1)) db3
              LEFT OUTER JOIN TABLE(l_coll_keypad_param) t_keypad
                ON db3.data_area = t_keypad.data_area
             ORDER BY db3.rn_rank;
    END get_data_blocks;

    /**
    * Open the soap data blocks cursor.
    * Considers data block parenting.
    * Returns the static data blocks only, by performance reasons.
    *
    * @param    i_lang          Language ID
    * @param    i_prof          Professional structure identifiers
    * @param    i_patient       Patient Identifier
    * @param    i_episode       Espisode Identifier
    * @param    i_data_blocks   Data blocks list
    * @param    i_soap_blocks   Soap blocks list
    * @param    i_task_types    Task types list
    * @param    o_data_blocks   soap data blocks cursor
    *
    * @author               Sofia Mendes
    * @version               2.6.2
    * @since                01-Oct-2012
    */
    PROCEDURE get_static_data_blocks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_data_blocks IN t_coll_dblock,
        i_soap_blocks IN tab_soap_blocks,
        i_task_types  IN t_coll_dblock_task_type,
        i_episode     IN episode.id_episode%TYPE,
        o_data_blocks OUT pk_types.cursor_type
    ) IS
    BEGIN
    
        g_error := 'OPEN o_data_blocks static';
        pk_alertlog.log_debug(g_error);
        OPEN o_data_blocks FOR
            SELECT *
              FROM (SELECT db3.id_pn_soap_block block_id,
                           db3.id_pn_data_block,
                           db3.id_parent,
                           db3.flg_mandatory_parent,
                           db3.data_area,
                           db3.id_doc_area,
                           db3.area_name || db3.mandatory_desc area_name,
                           db3.parent_name,
                           nvl(db3.parent_name, db3.root) root_name,
                           /*CASE
                           WHEN id_task_type_ftxt IS NOT NULL THEN
                            pk_prog_notes_constants.g_dblock_free_text_w_save
                           ELSE*/
                           --  db3.flg_type
                           /*END*/
                           flg_type,
                           db3.flg_import,
                           db3.flg_select,
                           db3.flg_scope,
                           db3.flg_write,
                           db3.sample_text_code,
                           CASE
                                WHEN db3.id_doc_area IS NOT NULL THEN
                                 pk_summary_page.get_flg_no_changes_by_doc_area(i_lang, i_prof, db3.id_doc_area)
                                ELSE
                                 pk_alert_constant.g_no
                            END flg_no_changes,
                           db3.flg_actions_available,
                           db3.flg_line_on_boxes,
                           db3.gender,
                           db3.age_min,
                           db3.age_max,
                           db3.flg_pregnant,
                           db3.flg_mandatory,
                           db3.id_sys_button_viewer,
                           db3.file_name,
                           db3.file_extension,
                           db3.flg_wf_viewer,
                           db3.flg_show_sub_title,
                           (SELECT pk_prog_notes_utils.get_flg_synch_area(i_lang                  => i_lang,
                                                                          i_prof                  => i_prof,
                                                                          i_coll_dblock_task_type => i_task_types,
                                                                          i_id_pn_data_block      => db3.id_pn_data_block)
                              FROM dual) flg_synch_area,
                           nvl(db3.id_task_type_ftxt, db3.id_task_type) id_pn_task_type,
                           db3.sample_text_comment,
                           db3.flg_focus,
                           db3.flg_editable,
                           db3.rn_rank,
                           db3.flg_show_title,
                           get_app_file(db3.id_swf_file_detail) swf_file_detail,
                           db3.id_summary_page,
                           db3.cancel_reason_area,
                           db3.value_viewer,
                           db3.sample_text_cancel,
                           multi_option_column,
                           db3.id_mtos_score
                      FROM (SELECT db2.id_pn_soap_block,
                                   db2.id_pn_data_block,
                                   db2.id_pndb_parent id_parent,
                                   db2.flg_mandatory_parent,
                                   db2.data_area,
                                   db2.id_doc_area,
                                   db2.area_name,
                                   pk_utils.str_token(db2.path, db2.depth, '|') parent_name,
                                   get_mandatory_desc(db2.flg_mandatory) mandatory_desc,
                                   db2.root,
                                   db2.flg_type,
                                   db2.sample_text_code,
                                   db2.flg_import,
                                   db2.flg_select,
                                   db2.flg_scope,
                                   decode(db2.flg_editable,
                                          pk_alert_constant.g_no,
                                          pk_alert_constant.g_no,
                                          pk_alert_constant.g_yes) flg_write,
                                   db2.rn_rank,
                                   db2.flg_actions_available,
                                   db2.flg_line_on_boxes,
                                   db2.gender,
                                   db2.age_min,
                                   db2.age_max,
                                   db2.flg_pregnant,
                                   db2.flg_mandatory,
                                   db2.id_sys_button_viewer,
                                   db2.file_name,
                                   db2.file_extension,
                                   db2.flg_wf_viewer,
                                   db2.flg_show_sub_title,
                                   db2.sample_text_comment,
                                   db2.flg_focus,
                                   db2.flg_editable,
                                   db2.flg_show_title,
                                   db2.id_task_type,
                                   db2.id_task_type_ftxt,
                                   db2.id_swf_file_detail,
                                   db2.id_summary_page,
                                   db2.cancel_reason_area,
                                   db2.value_viewer,
                                   db2.sample_text_cancel,
                                   multi_option_column,
                                   db2.id_mtos_score
                              FROM (SELECT db.id_pn_soap_block,
                                           db.id_pn_data_block,
                                           db.id_pndb_parent,
                                           CASE
                                                WHEN db.id_pndb_parent IS NOT NULL THEN
                                                 connect_by_root db.flg_mandatory
                                                ELSE
                                                 pk_alert_constant.g_no
                                            END flg_mandatory_parent,
                                           db.data_area,
                                           db.id_doc_area,
                                           db.area_name,
                                           db.flg_type,
                                           db.sample_text_code,
                                           db.flg_import,
                                           db.flg_select,
                                           db.flg_scope,
                                           db.rn_rank,
                                           db.flg_actions_available,
                                           db.flg_line_on_boxes,
                                           db.gender,
                                           db.age_min,
                                           db.age_max,
                                           db.flg_pregnant,
                                           db.flg_mandatory,
                                           sys_connect_by_path(decode(flg_show_title,
                                                                      pk_alert_constant.g_yes,
                                                                      db.area_name,
                                                                      NULL),
                                                               '|') path,
                                           connect_by_root decode(flg_show_title, pk_alert_constant.g_yes, db.area_name, NULL) root,
                                           LEVEL depth,
                                           connect_by_isleaf leaf,
                                           db.id_sys_button_viewer,
                                           db.file_name,
                                           db.file_extension,
                                           db.flg_wf_viewer,
                                           db.flg_show_sub_title,
                                           db.sample_text_comment,
                                           db.flg_focus,
                                           db.flg_editable,
                                           db.flg_show_title,
                                           db.id_task_type,
                                           db.id_task_type_ftxt,
                                           db.id_swf_file_detail,
                                           db.id_summary_page,
                                           db.cancel_reason_area,
                                           db.value_viewer,
                                           db.sample_text_cancel,
                                           multi_option_column,
                                           db.id_mtos_score
                                      FROM (SELECT db.id_pn_soap_block,
                                                   db.id_pn_data_block,
                                                   db.id_pndb_parent,
                                                   pdb.data_area,
                                                   pdb.id_doc_area,
                                                   db.flg_show_title,
                                                   --Change translation to sys_message Start--
                                                   --pk_translation.get_translation(i_lang, db.code_pn_data_block) area_name,
                                                   decode(db.desc_function,
                                                          NULL,
                                                          pk_message.get_message(i_lang, i_prof, db.code_pn_data_block),
                                                          pk_prog_notes_utils.get_dblock_description(i_lang,
                                                                                                     i_prof,
                                                                                                     desc_function,
                                                                                                     i_episode)) area_name,
                                                   --Change translation to sys_message Start--
                                                   db.flg_type,
                                                   pdb.sample_text_code,
                                                   db.flg_import,
                                                   db.flg_select,
                                                   db.flg_scope,
                                                   row_number() over(ORDER BY sb.rank, db.rank) rn_rank,
                                                   db.flg_actions_available,
                                                   db.flg_line_on_boxes,
                                                   db.gender,
                                                   db.age_min,
                                                   db.age_max,
                                                   db.flg_pregnant,
                                                   db.flg_mandatory,
                                                   db.id_sys_button_viewer,
                                                   db.file_name,
                                                   db.file_extension,
                                                   db.flg_wf_viewer,
                                                   db.flg_show_sub_title,
                                                   pdb.sample_text_comment,
                                                   db.flg_focus,
                                                   db.flg_editable,
                                                   pdb.id_task_type,
                                                   db.id_task_type_ftxt,
                                                   pdb.id_swf_file_detail,
                                                   db.id_summary_page,
                                                   pdb.cancel_reason_area,
                                                   db.value_viewer,
                                                   pdb.sample_text_cancel,
                                                   pdb.multi_option_column,
                                                   pdb.id_mtos_score,
                                                   db.desc_function
                                              FROM pn_data_block pdb
                                              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                                    t.id_pn_soap_block,
                                                    t.id_pn_data_block,
                                                    t.code_pn_data_block,
                                                    t.flg_import,
                                                    t.flg_select,
                                                    t.flg_scope,
                                                    t.rank,
                                                    t.flg_actions_available,
                                                    t.id_swf_file_viewer,
                                                    t.flg_line_on_boxes,
                                                    t.gender,
                                                    t.age_min,
                                                    t.age_max,
                                                    t.flg_pregnant,
                                                    t.flg_mandatory,
                                                    t.id_sys_button_viewer,
                                                    t.flg_wf_viewer,
                                                    t.id_pndb_parent,
                                                    t.flg_struct_type,
                                                    t.flg_show_sub_title,
                                                    t.flg_show_title,
                                                    t.flg_focus,
                                                    t.flg_editable,
                                                    t.id_task_type_ftxt,
                                                    t.id_summary_page,
                                                    t.flg_type,
                                                    value_viewer,
                                                    file_name,
                                                    file_extension,
                                                    t.id_mtos_score,
                                                    t.desc_function
                                                     FROM TABLE(i_data_blocks) t) db
                                                ON pdb.id_pn_data_block = db.id_pn_data_block
                                              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                                    t.id_pn_soap_block, t.rank
                                                     FROM TABLE(i_soap_blocks) t) sb
                                                ON db.id_pn_soap_block = sb.id_pn_soap_block
                                             WHERE pdb.flg_type NOT IN
                                                   (pk_prog_notes_constants.g_dblock_strut_date,
                                                    pk_prog_notes_constants.g_dblock_strut_group,
                                                    pk_prog_notes_constants.g_dblock_strut_subgroup)
                                               AND db.flg_struct_type != pk_prog_notes_constants.g_struct_type_import_i) db
                                    CONNECT BY PRIOR db.id_pn_data_block = db.id_pndb_parent
                                     START WITH db.id_pndb_parent IS NULL) db2
                             WHERE db2.leaf = 1
                               AND db2.flg_type != pk_prog_notes_constants.g_data_block_strut) db3) db4
             WHERE (data_area NOT IN (pk_prog_notes_constants.g_data_block_cdate_cd,
                                      pk_prog_notes_constants.g_data_block_eddate_edd,
                                      pk_prog_notes_constants.g_data_block_arrivaldt_adt,
                                      pk_prog_notes_constants.g_data_block_cdate_ddt))
             ORDER BY db4.rn_rank;
    END get_static_data_blocks;

    /**
    * Open the soap data blocks cursor.    
    * Returns the dynamic data blocks only.
    *
    * @param    i_lang          Language ID
    * @param    i_prof          Professional structure identifiers
    * @param    i_episode       Espisode Identifier
    * @param    i_data_blocks   Data blocks list
    * @param    i_task_types    Task types list
    * @param    o_data_blocks   soap data blocks cursor
    *
    * @author               Sofia Mendes
    * @version               2.6.2
    * @since                01-Ock-2012
    */
    PROCEDURE get_dynamic_data_blocks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_data_blocks IN t_coll_dblock,
        i_task_types  IN t_coll_dblock_task_type,
        i_dt_purposed IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_data_blocks OUT pk_types.cursor_type
    ) IS
        l_scope_type        VARCHAR2(1 CHAR) := pk_alert_constant.g_scope_type_episode;
        l_coll_keypad_param t_coll_keypad_param;
    BEGIN
        g_error := 'CALL tf_keypad_param';
        pk_alertlog.log_debug(g_error);
        l_coll_keypad_param := tf_keypad_param(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_scope       => i_episode,
                                               i_scope_type  => l_scope_type,
                                               i_dblocks     => i_data_blocks,
                                               i_dt_purposed => i_dt_purposed,
                                               i_task_types  => i_task_types);
    
        g_error := 'OPEN o_data_blocks static';
        pk_alertlog.log_debug(g_error);
        OPEN o_data_blocks FOR
            SELECT db.*
              FROM (SELECT db3.id_pn_soap_block block_id,
                           db3.id_pn_data_block,
                           db3.id_pndb_parent id_parent,
                           pk_alert_constant.g_no flg_mandatory_parent,
                           db3.data_area,
                           db3.id_doc_area,
                           db3.area_name area_name,
                           NULL parent_name,
                           db3.area_name root_name,
                           db3.flg_type,
                           db3.flg_import,
                           db3.flg_select,
                           db3.flg_scope,
                           decode(db3.flg_editable,
                                  pk_alert_constant.g_no,
                                  pk_alert_constant.g_no,
                                  pk_alert_constant.g_yes) flg_write,
                           db3.sample_text_code,
                           CASE
                                WHEN db3.id_doc_area IS NOT NULL THEN
                                 pk_summary_page.get_flg_no_changes_by_doc_area(i_lang, i_prof, db3.id_doc_area)
                                ELSE
                                 pk_alert_constant.g_no
                            END flg_no_changes,
                           db3.flg_actions_available,
                           db3.flg_line_on_boxes,
                           db3.gender,
                           db3.age_min,
                           db3.age_max,
                           db3.flg_pregnant,
                           db3.flg_mandatory,
                           db3.id_sys_button_viewer,
                           db3.file_name,
                           db3.file_extension,
                           db3.flg_wf_viewer,
                           t_keypad.flg_may_clean,
                           t_keypad.flg_format,
                           t_keypad.cur_value,
                           t_keypad.min_value,
                           t_keypad.max_value,
                           t_keypad.flg_validation flg_input_type,
                           db3.flg_show_sub_title,
                           --db3.flg_synchronized, --TODO
                           pk_prog_notes_utils.get_flg_synch_area(i_lang                  => i_lang,
                                                                  i_prof                  => i_prof,
                                                                  i_coll_dblock_task_type => i_task_types,
                                                                  i_id_pn_data_block      => db3.id_pn_data_block) flg_synch_area,
                           
                           db3.sample_text_comment,
                           db3.flg_focus,
                           db3.flg_editable,
                           db3.flg_show_title,
                           db3.id_task_type        id_pn_task_type, 
                           rn_rank
                      FROM (SELECT db.id_pn_soap_block,
                                   db.id_pn_data_block,
                                   db.id_pndb_parent,
                                   pdb.data_area,
                                   decode(db.flg_show_title,
                                           pk_alert_constant.g_yes,
                                           decode(db.desc_function,
                                                  NULL,
                                                  pk_message.get_message(i_lang, i_prof, db.code_pn_data_block),
                                                  pk_prog_notes_utils.get_dblock_description(i_lang,
                                                                                             i_prof,
                                                                                             db.desc_function,
                                                                                             i_episode))) ||
                                   --Change translation to sys_message End
                                    get_mandatory_desc(db.flg_mandatory) area_name,
                                   pdb.id_doc_area,
                                   pdb.code_pn_data_block,
                                   db.flg_show_title,
                                   pdb.flg_type,
                                   pdb.sample_text_code,
                                   db.flg_import,
                                   db.flg_select,
                                   db.flg_scope,
                                   db.flg_actions_available,
                                   db.flg_line_on_boxes,
                                   db.gender,
                                   db.age_min,
                                   db.age_max,
                                   db.flg_pregnant,
                                   db.flg_mandatory,
                                   db.id_sys_button_viewer,
                                   af.file_name,
                                   af.file_extension,
                                   db.flg_wf_viewer,
                                   db.flg_show_sub_title,
                                   pdb.sample_text_comment,
                                   db.flg_focus,
                                   db.flg_editable,
                                   pdb.id_task_type, 
                                   row_number() over(partition by db.id_pn_soap_block ORDER BY  db.rank) rn_rank
                              FROM pn_data_block pdb
                              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                    t.id_pn_soap_block,
                                    t.id_pn_data_block,
                                    t.code_pn_data_block,
                                    t.flg_import,--
                                    t.flg_select,
                                    t.flg_scope,
                                    t.rank,
                                    t.flg_actions_available,
                                    t.id_swf_file_viewer,
                                    t.flg_line_on_boxes,
                                    t.gender,
                                    t.age_min,
                                    t.age_max,
                                    t.flg_pregnant,
                                    t.flg_mandatory,
                                    t.id_sys_button_viewer,
                                    t.flg_wf_viewer,
                                    t.id_pndb_parent,
                                    t.flg_struct_type,
                                    t.flg_show_sub_title,
                                    t.flg_show_title,
                                    t.flg_focus,
                                    t.flg_editable,
                                    t.desc_function
                                     FROM TABLE(i_data_blocks) t) db
                                ON pdb.id_pn_data_block = db.id_pn_data_block
                              LEFT OUTER JOIN application_file af
                                ON af.id_application_file = db.id_swf_file_viewer
                             WHERE pdb.flg_type NOT IN (pk_prog_notes_constants.g_dblock_strut_date,
                                                        pk_prog_notes_constants.g_dblock_strut_group,
                                                        pk_prog_notes_constants.g_dblock_strut_subgroup,
                                                        pk_prog_notes_constants.g_data_block_strut)
                               AND db.flg_struct_type != pk_prog_notes_constants.g_struct_type_import_i) db3
                      LEFT OUTER JOIN TABLE(l_coll_keypad_param) t_keypad
                        ON db3.data_area = t_keypad.data_area) db
             WHERE data_area IN (pk_prog_notes_constants.g_data_block_cdate_cd,
                                 pk_prog_notes_constants.g_data_block_eddate_edd,
                                 pk_prog_notes_constants.g_data_block_arrivaldt_adt,
                                 pk_prog_notes_constants.g_data_block_cdate_ddt);
    END get_dynamic_data_blocks;

    /********************************************************************************************
    * returns data blocks
    *
    * @param IN   i_lang          Language ID
    * @param IN   i_prof          Professional ID
    * @param IN   i_patient       Patient ID
    * @param IN   i_episode       Espisode ID
    * @param OUT  o_data_blocks   Data blocks
    * @param OUT  o_simple_text   Simple Text blocks structure
    * @param OUT  o_doc_reg       Doccumentation registers
    * @param OUT  o_doc_val       Doccumentation registers values
    * @param OUT  o_error         Error structure
    *
    * @author                     Pedro Teixeira
    * @since                      17/09/2010
    ********************************************************************************************/
    FUNCTION get_data_blocks
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_soap_list          IN tab_soap_blocks,
        o_data_blocks        OUT pk_types.cursor_type,
        o_simple_text        OUT pk_types.cursor_type,
        o_doc_reg            OUT pk_types.cursor_type,
        o_doc_val            OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return_exception   BOOLEAN := TRUE;
        l_dblocks            t_coll_dblock := t_coll_dblock();
        l_simple_text_area   table_varchar := table_varchar();
        l_documentation_area table_varchar := table_varchar();
    BEGIN
        l_dblocks := g_ctx.data_blocks;
    
        IF l_dblocks.count > 0
        THEN
            FOR i IN l_dblocks.first .. l_dblocks.last
            LOOP
                -- separate data areas
                IF l_dblocks(i).flg_type = pk_prog_notes_constants.g_data_block_text
                THEN
                    l_simple_text_area.extend;
                    l_simple_text_area(l_simple_text_area.last) := l_dblocks(i).data_area;
                ELSIF l_dblocks(i).flg_type = pk_prog_notes_constants.g_data_block_doc
                THEN
                    l_documentation_area.extend;
                    l_documentation_area(l_documentation_area.last) := l_dblocks(i).data_area;
                END IF;
            END LOOP;
        ELSE
            -- if block not found then exit without error
            l_return_exception := TRUE;
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_data_blocks';
        get_data_blocks(i_lang        => i_lang,
                        i_prof        => i_prof,
                        i_patient     => i_patient,
                        i_episode     => i_episode,
                        o_data_blocks => o_data_blocks);
    
        -- get simple text block
        IF l_simple_text_area.count > 0
        THEN
            g_error := 'CALL get_block_simple_text';
            IF NOT get_block_simple_text(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_patient     => i_patient,
                                         i_episode     => i_episode,
                                         i_data_area   => l_simple_text_area,
                                         o_simple_text => o_simple_text,
                                         o_error       => o_error)
            THEN
                l_return_exception := FALSE;
                RAISE g_exception;
            END IF;
        
        ELSE
            pk_types.open_my_cursor(o_simple_text);
        END IF;
    
        -- get documentation block
        IF l_documentation_area.count > 0
        THEN
            g_error := 'CALL get_block_documentation';
            IF NOT get_block_documentation(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_patient            => i_patient,
                                           i_episode            => i_episode,
                                           i_data_area          => l_documentation_area,
                                           o_doc_reg            => o_doc_reg,
                                           o_doc_val            => o_doc_val,
                                           o_template_layouts   => o_template_layouts,
                                           o_doc_area_component => o_doc_area_component,
                                           o_error              => o_error)
            THEN
                l_return_exception := FALSE;
                RAISE g_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_data_blocks);
            pk_types.open_my_cursor(o_simple_text);
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            RETURN l_return_exception;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DATA_BLOCKS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data_blocks);
            pk_types.open_my_cursor(o_simple_text);
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns associated blocks
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_free_text   Free text records cursor
    * @param OUT  o_rea_visit   Reason for visit records cursor
    * @param OUT  o_app_type    Appointment type records cursor
    * @param OUT  o_prof_rec    Author and date of last change
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_assoc_blocks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_soap_list IN tab_soap_blocks,
        o_free_text OUT pk_types.cursor_type,
        o_rea_visit OUT pk_types.cursor_type,
        o_app_type  OUT pk_types.cursor_type,
        o_prof_rec  OUT pk_translation.t_desc_translation,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_return_exception BOOLEAN := TRUE;
    
        l_coll_soap_block t_coll_soap_block := t_coll_soap_block();
    
    BEGIN
        --inits
        pk_types.open_my_cursor(o_free_text);
        pk_types.open_my_cursor(o_rea_visit);
        pk_types.open_my_cursor(o_app_type);
    
        -- check if any block is to be retrieved
        IF i_soap_list.count = 0
        THEN
            l_return_exception := TRUE;
            RAISE g_exception;
        END IF;
    
        -- get table_info with
        g_error           := 'CALL get_freetext_block_info';
        l_coll_soap_block := get_freetext_block_info(i_lang, i_prof, i_soap_list);
    
        -- get reason for visit
        g_error := 'CALL pk_progress_notes.get_reason_for_visit';
        IF NOT pk_progress_notes.get_reason_for_visit(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_episode   => i_episode,
                                                      i_blk_info  => l_coll_soap_block,
                                                      o_rea_visit => o_rea_visit,
                                                      o_app_type  => o_app_type,
                                                      o_prof_rec  => o_prof_rec,
                                                      o_error     => o_error)
        THEN
            l_return_exception := FALSE;
            RAISE g_exception;
        END IF;
    
        -- get free text records
        g_error := 'CALL pk_progress_notes.get_free_text';
        IF NOT pk_progress_notes.get_free_text(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               i_episode   => i_episode,
                                               i_blk_info  => l_coll_soap_block,
                                               o_free_text => o_free_text,
                                               o_error     => o_error)
        THEN
            l_return_exception := FALSE;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            RETURN l_return_exception;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ASSOC_BLOCKS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_free_text);
            pk_types.open_my_cursor(o_rea_visit);
            pk_types.open_my_cursor(o_app_type);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Returns the button blocks associated with SOAP Blocks List
    *
    * @param IN   i_lang          Language ID
    * @param IN   i_prof          Professional ID
    * @param IN   i_patient       Patient ID
    * @param IN   i_episode       Espisode ID
    * @param IN   i_soap_list     List of SOAP Block ID's
    *
    * @param OUT  o_button_blocks Button blocks structure
    * @param OUT  o_error         Error structure
    *
    * @author                     Pedro Teixeira
    * @since                      17/09/2010
    ********************************************************************************************/
    FUNCTION get_button_blocks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_soap_list     IN tab_soap_blocks,
        o_button_blocks OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_BUTTON_BLOCKS';
        c_templates          pk_types.cursor_type;
        l_daas               table_number := table_number();
        l_search_daas        table_number := table_number();
        l_search_types       table_varchar := table_varchar();
        l_last_search_type   doc_template_context.flg_type%TYPE;
        l_last_id_doc_area   doc_area.id_doc_area%TYPE;
        l_templ_ids          table_number := table_number();
        l_templ_descs        table_varchar := table_varchar();
        l_flg_multiple       table_varchar := table_varchar();
        l_templates          t_coll_template := t_coll_template();
        l_no_templates       PLS_INTEGER := 0;
        l_not_multiple_areas table_number := table_number();
        l_found              PLS_INTEGER;
    
        CURSOR c_search IS
            SELECT t.id_doc_area, t.flg_type, t.flg_multiple
              FROM (SELECT dais.id_doc_area,
                           dais.flg_type,
                           dais.flg_multiple,
                           row_number() over(PARTITION BY dais.id_doc_area ORDER BY dais.id_institution DESC, dais.id_market DESC, dais.id_software DESC) rn
                      FROM doc_area_inst_soft dais
                     WHERE dais.id_institution IN (0, i_prof.institution)
                       AND dais.id_software IN (0, i_prof.software)
                       AND (dais.id_market IN (0, g_ctx.id_market) OR dais.id_market IS NULL)
                       AND dais.id_doc_area IN (SELECT /*+opt_estimate(table daa rows=1)*/
                                                 daa.column_value id_doc_area
                                                  FROM TABLE(l_daas) daa)) t
             WHERE t.rn = 1
             ORDER BY t.flg_type;
    
        PROCEDURE set_templ_to_list
        (
            i_templ_ids   IN table_number,
            i_templ_descs IN table_varchar,
            i_search_daas IN NUMBER,
            i_search_type IN VARCHAR2
        ) IS
        BEGIN
            FOR j IN 1 .. l_templ_ids.count
            LOOP
                -- append each template found to the templates collection
                l_templates.extend;
                l_templates(l_templates.last) := t_rec_template(id_doc_template => i_templ_ids(j),
                                                                desc_template   => i_templ_descs(j),
                                                                id_doc_area     => i_search_daas,
                                                                flg_type        => i_search_type);
            END LOOP;
        
        END set_templ_to_list;
    
    BEGIN
        FOR i IN 1 .. g_ctx.buttons.count
        LOOP
            -- get list of doc_areas
            IF g_ctx.buttons(i)
             .id_doc_area IS NOT NULL
                AND g_ctx.buttons(i)
               .action IN (g_button_action_document, g_button_action_shortcut, g_button_action_search_templ)
            THEN
                l_daas.extend;
                l_daas(l_daas.last) := g_ctx.buttons(i).id_doc_area;
            END IF;
        END LOOP;
    
        -- removed multiple occurences of doc_area
        l_daas := l_daas MULTISET UNION DISTINCT table_number();
    
        pk_alertlog.log_debug(text            => 'documentable areas: ' || pk_utils.to_string(i_input => l_daas),
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
    
        -- get templates search mode for doc_areas
        g_error := 'OPEN c_search';
        OPEN c_search;
        FETCH c_search BULK COLLECT
            INTO l_search_daas, l_search_types, l_flg_multiple;
        CLOSE c_search;
    
        FOR i IN 1 .. l_search_types.count
        LOOP
            l_no_templates := 0;
        
            IF l_search_types(i) = l_last_search_type
               AND l_search_types(i) IN (pk_touch_option.g_flg_type_complaint_sch_evnt,
                                         pk_touch_option.g_flg_type_appointment,
                                         pk_touch_option.g_flg_type_clin_serv)
            THEN
                -- do not repeat the search for these three search modes:
                -- they yield the same results every time                
                IF (l_search_daas(i) <> l_last_id_doc_area AND l_templ_ids.count > 0)
                THEN
                    g_error := 'CALL set_templ_to_list. doc_area: ' || l_search_daas(i) || ' type: ' ||
                               l_search_types(i) || ' flg_multiple: ' || l_flg_multiple(i);
                    pk_alertlog.log_debug(g_error);
                    set_templ_to_list(i_templ_ids   => l_templ_ids,
                                      i_templ_descs => l_templ_descs,
                                      i_search_daas => l_search_daas(i),
                                      i_search_type => l_search_types(i));
                END IF;
            
            ELSE
                -- get available templates
                g_error := 'CALL pk_touch_option.get_doc_template (doc_area: ' || l_search_daas(i) || ')';
                IF NOT pk_touch_option.get_doc_template(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_patient   => i_patient,
                                                        i_episode   => i_episode,
                                                        i_doc_area  => l_search_daas(i),
                                                        i_context   => NULL,
                                                        i_flg_type  => l_search_types(i),
                                                        o_templates => c_templates,
                                                        o_error     => o_error)
                THEN
                    l_no_templates := 1;
                END IF;
            
                -- clear template collections
                l_templ_ids   := table_number();
                l_templ_descs := table_varchar();
            
                IF (l_no_templates = 0)
                THEN
                    IF c_templates%ISOPEN
                    THEN
                        g_error := 'FETCH c_templates';
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        FETCH c_templates BULK COLLECT
                            INTO l_templ_ids, l_templ_descs;
                        CLOSE c_templates;
                    END IF;
                END IF;
            
                g_error := 'CALL set_templ_to_list. doc_area: ' || l_search_daas(i) || ' type: ' || l_search_types(i) ||
                           ' flg_multiple: ' || l_flg_multiple(i);
                pk_alertlog.log_debug(g_error);
                set_templ_to_list(i_templ_ids   => l_templ_ids,
                                  i_templ_descs => l_templ_descs,
                                  i_search_daas => l_search_daas(i),
                                  i_search_type => l_search_types(i));
            END IF;
            -- save last type searched
            l_last_search_type := l_search_types(i);
            l_last_id_doc_area := l_search_daas(i);
        
            --save the areas that does not support multiple templates
            IF (l_flg_multiple(i) = pk_alert_constant.g_no)
            THEN
                l_not_multiple_areas.extend(1);
                l_not_multiple_areas(l_not_multiple_areas.last) := l_search_daas(i);
            END IF;
        
        END LOOP;
    
        --when a doc_area is configured with flg_multiple='N' (does not allow multiple templates), the 'Activate Others' 
        --option does not work. Therefore, this option will not be shown in this case, even though the button 'Activate Others' is 
        -- configured in the area                
        IF (l_not_multiple_areas.count > 0)
        THEN
            g_error := 'LOOP TROUGHT buttons';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            FOR i IN 1 .. g_ctx.buttons.count
            LOOP
                IF (g_ctx.buttons(i).action = g_button_action_search_templ)
                THEN
                    l_found := 0;
                    --check if the button Activate Others is configured as a child of the button associated to the current doc_area
                    BEGIN
                        SELECT 1
                          INTO l_found
                          FROM TABLE(g_ctx.buttons) btn
                         WHERE btn.id_conf_button_block = g_ctx.buttons(i).id_parent
                           AND btn.id_pn_soap_block = g_ctx.buttons(i).id_pn_soap_block
                           AND btn.id_doc_area IN (SELECT column_value
                                                     FROM TABLE(l_not_multiple_areas));
                    
                        IF (l_found = 1)
                        THEN
                            g_ctx.buttons(i).flg_visible := pk_alert_constant.g_no;
                        END IF;
                    
                    EXCEPTION
                        WHEN OTHERS THEN
                            NULL;
                    END;
                END IF;
            END LOOP;
        END IF;
    
        -- open output cursor o_button_blocks
        g_error := 'OPEN o_button_blocks';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_button_blocks FOR
            SELECT block_id,
                   id_conf_button_block,
                   id_parent,
                   unq_btn_id,
                   unq_btn_id_parent,
                   button_name,
                   icon,
                   action,
                   VALUE,
                   rank,
                   block_level,
                   title_code,
                   sample_text_code,
                   id_pn_data_block,
                   decode(block_level,
                          0,
                          
                          decode(get_child_count(id_conf_button_block, block_id),
                                 0,
                                 pk_alert_constant.g_no,
                                 pk_alert_constant.g_yes),
                          
                          pk_alert_constant.g_yes) show_header,
                   id_doc_area,
                   id_pn_task_type,
                   (SELECT CASE
                               WHEN id_pn_task_type IS NULL
                                    AND id_pn_group IS NULL THEN
                                NULL
                               ELSE
                                get_ehr_access_area(i_lang, i_prof, i_episode, id_pn_task_type, NULL, id_pn_group)
                           END
                      FROM dual) flg_status,
                   id_type id_type,
                   internal_task_type,
                   id_pn_group,
                   id_pn_task_type_parent
              FROM (SELECT btn.block_id,
                           btn.id_conf_button_block,
                           btn.id_parent,
                           btn.unq_btn_id,
                           btn.unq_btn_id_parent,
                           nvl(btn.desc_template,
                               --Change translation to sys_message start
                               --(SELECT pk_translation.get_translation(i_lang, btn.code_conf_button_block)
                               (SELECT pk_message.get_message(i_lang, i_prof, btn.code_conf_button_block)
                                --Change translation to sys_message end
                                  FROM dual)) button_name,
                           btn.icon,
                           btn.action,
                           btn.value,
                           btn.rank,
                           LEVEL - 1 block_level,
                           btn.title_code,
                           btn.sample_text_code,
                           btn.id_pn_data_block,
                           btn.id_doc_area,
                           btn.id_pn_task_type,
                           btn.id_type,
                           btn.internal_task_type,
                           btn.id_pn_group,
                           btn.id_pn_task_type_parent
                      FROM (SELECT btn_int.id_pn_soap_block block_id,
                                   btn_int.id_conf_button_block,
                                   btn_int.id_parent,
                                   --the following 2 fileds are required because it is possible to reuse the same button in different data blocks, 
                                   -- and the flash needs an unique id for the button in a block
                                   btn_int.id_pn_soap_block || '0' || btn_int.id_conf_button_block unq_btn_id,
                                   CASE
                                        WHEN btn_int.id_parent IS NOT NULL THEN
                                         btn_int.id_pn_soap_block || '0' || btn_int.id_parent
                                        ELSE
                                         NULL
                                    END unq_btn_id_parent,
                                   nvl(btn_int.desc_template,
                                       --Change translation to sys_message start
                                       --(SELECT pk_translation.get_translation(i_lang, btn_int.code_conf_button_block)
                                       (SELECT pk_message.get_message(i_lang, i_prof, btn_int.code_conf_button_block)
                                        --Change translation to sys_message end
                                          FROM dual)) button_name,
                                   btn_int.icon,
                                   btn_int.action,
                                   btn_int.value,
                                   btn_int.rank,
                                   
                                   btn_int.title_code,
                                   btn_int.sample_text_code,
                                   btn_int.id_pn_data_block,
                                   btn_int.id_doc_area,
                                   btn_int.id_task_type           id_pn_task_type,
                                   btn_int.desc_template,
                                   btn_int.code_conf_button_block,
                                   btn_int.id_type,
                                   btn_int.internal_task_type,
                                   btn_int.id_pn_group,
                                   btn_int.id_pn_task_type_parent
                              FROM (SELECT bb.id_pn_soap_block,
                                           decode(cbb.action,
                                                  g_button_action_new_templ,
                                                  to_number(dt.id_doc_template || cbb.id_conf_button_block),
                                                  cbb.id_conf_button_block) id_conf_button_block,
                                           bb.id_parent,
                                           --
                                           cbb.code_conf_button_block,
                                           cbb.icon,
                                           cbb.action,
                                           decode(cbb.action,
                                                  g_button_action_load_screen,
                                                  get_app_file(cbb.id_swf_file),
                                                  g_button_action_screen_tmpl,
                                                  get_app_file(cbb.id_swf_file),
                                                  g_button_action_new_templ,
                                                  dt.id_doc_template,
                                                  g_button_action_search_templ,
                                                  get_app_file(cbb.id_swf_file),
                                                  g_button_action_shortcut,
                                                  cbb.id_sys_shortcut,
                                                  g_button_action_codification,
                                                  get_app_file(cbb.id_swf_file),
                                                  g_button_action_document,
                                                  cbb.id_doc_area,
                                                  g_button_action_external_app,
                                                  cbb.domain) VALUE,
                                           dt.desc_template,
                                           bb.rank,
                                           pdb.title_code,
                                           pdb.sample_text_code,
                                           cbb.id_pn_data_block,
                                           cbb.id_doc_area,
                                           cbb.id_task_type,
                                           cbb.id_type,
                                           cbb.internal_task_type,
                                           cbb.id_pn_group,
                                           tt.id_parent id_pn_task_type_parent
                                      FROM conf_button_block cbb
                                      LEFT JOIN tl_task tt
                                        ON cbb.id_task_type = tt.id_tl_task
                                    
                                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                            t.id_pn_soap_block, t.id_conf_button_block, t.rank, t.id_parent, t.flg_visible
                                             FROM TABLE(g_ctx.buttons) t) bb
                                        ON cbb.id_conf_button_block = bb.id_conf_button_block
                                    
                                      LEFT JOIN pn_data_block pdb
                                        ON cbb.id_pn_data_block = pdb.id_pn_data_block
                                    
                                      LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                                 t.id_doc_area, t.id_doc_template, t.desc_template
                                                  FROM TABLE(l_templates) t) dt
                                        ON cbb.action = g_button_action_new_templ
                                       AND dt.id_doc_area = pdb.id_doc_area
                                    
                                     WHERE (cbb.action != g_button_action_new_templ OR
                                           (cbb.action = g_button_action_new_templ AND dt.id_doc_template IS NOT NULL))
                                       AND bb.flg_visible = pk_alert_constant.g_yes
                                     ORDER BY bb.rank) btn_int) btn
                    CONNECT BY PRIOR btn.unq_btn_id = btn.unq_btn_id_parent
                     START WITH btn.unq_btn_id_parent IS NULL
                     ORDER SIBLINGS BY btn.rank, btn.desc_template);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_button_blocks);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_button_blocks);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Returns the button blocks associated with SOAP Blocks List
    *
    * @param IN   i_lang          Language ID
    * @param IN   i_prof          Professional ID
    * @param IN   i_patient       Patient ID
    * @param IN   i_episode       Espisode ID
    * @param IN   i_soap_list     List of SOAP Block ID's
    *
    * @param OUT  o_button_blocks Button blocks structure
    * @param OUT  o_error         Error structure
    *
    * @author                     Sofia Mendes
    * @since                      01-Oct-2012
    ********************************************************************************************/
    FUNCTION get_static_buttons
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_buttons       IN t_coll_button,
        o_button_blocks OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_STATIC_BUTTONS';
    BEGIN
    
        -- open output cursor o_button_blocks
        g_error := 'OPEN o_button_blocks';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_button_blocks FOR
            SELECT *
              FROM (SELECT block_id,
                           id_conf_button_block,
                           id_parent,
                           unq_btn_id,
                           unq_btn_id_parent,
                           button_name,
                           icon,
                           action,
                           VALUE,
                           swf_name,
                           rank,
                           id_pn_data_block,
                           decode(get_child_count(id_conf_button_block, block_id),
                                  0,
                                  pk_alert_constant.g_no,
                                  pk_alert_constant.g_yes) show_header,
                           id_doc_area,
                           id_pn_task_type,
                           (SELECT CASE
                                       WHEN id_pn_task_type IS NULL
                                            AND id_pn_group IS NULL THEN
                                        NULL
                                       ELSE
                                        get_ehr_access_area(i_lang, i_prof, i_episode, id_pn_task_type, NULL, id_pn_group)
                                   END
                              FROM dual) flg_status,
                           id_type id_type,
                           internal_task_type,
                           id_pn_group,
                           id_pn_task_type_parent
                      FROM (SELECT btn.block_id,
                                   btn.id_conf_button_block,
                                   btn.id_parent,
                                   btn.unq_btn_id,
                                   btn.unq_btn_id_parent,
                                   --Change translation to sys_message start
                                   --(SELECT pk_translation.get_translation(i_lang, btn.code_conf_button_block)
                                   (SELECT pk_message.get_message(i_lang, i_prof, btn.code_conf_button_block)
                                    --Change translation to sys_message end
                                      FROM dual) button_name,
                                   btn.icon,
                                   btn.action,
                                   btn.value,
                                   btn.swf_name,
                                   btn.rank,
                                   btn.id_pn_data_block,
                                   btn.id_doc_area,
                                   btn.id_pn_task_type,
                                   btn.id_type,
                                   btn.internal_task_type,
                                   btn.id_pn_group,
                                   btn.id_pn_task_type_parent
                              FROM (SELECT btn_int.id_pn_soap_block block_id,
                                           btn_int.id_conf_button_block,
                                           btn_int.id_parent,
                                           --the following 2 fileds are required because it is possible to reuse the same button in different data blocks, 
                                           -- and the flash needs an unique id for the button in a block
                                           btn_int.id_pn_soap_block || '0' || btn_int.id_conf_button_block unq_btn_id,
                                           CASE
                                                WHEN btn_int.id_parent IS NOT NULL THEN
                                                 btn_int.id_pn_soap_block || '0' || btn_int.id_parent
                                                ELSE
                                                 NULL
                                            END unq_btn_id_parent,
                                           --Change translation to sys_message start
                                           --(SELECT pk_translation.get_translation(i_lang, btn_int.code_conf_button_block)
                                           (SELECT pk_message.get_message(i_lang, i_prof, btn_int.code_conf_button_block)
                                            --Change translation to sys_message end
                                              FROM dual) button_name,
                                           btn_int.icon,
                                           btn_int.action,
                                           btn_int.value,
                                           btn_int.swf_name,
                                           btn_int.rank,
                                           btn_int.id_pn_data_block,
                                           btn_int.id_doc_area,
                                           btn_int.id_task_type id_pn_task_type,
                                           btn_int.code_conf_button_block,
                                           btn_int.id_type,
                                           btn_int.internal_task_type,
                                           btn_int.id_pn_group,
                                           btn_int.id_pn_task_type_parent
                                      FROM (SELECT bb.id_pn_soap_block,
                                                   cbb.id_conf_button_block id_conf_button_block,
                                                   bb.id_parent,
                                                   --
                                                   cbb.code_conf_button_block,
                                                   cbb.icon,
                                                   cbb.action,
                                                   decode(cbb.action,
                                                          /*g_button_action_load_screen,
                                                          get_app_file(cbb.id_swf_file),
                                                          g_button_action_screen_tmpl,
                                                          get_app_file(cbb.id_swf_file),
                                                          g_button_action_search_templ,
                                                          get_app_file(cbb.id_swf_file),*/
                                                          g_button_action_shortcut,
                                                          cbb.id_sys_shortcut,
                                                          /*g_button_action_codification,
                                                          get_app_file(cbb.id_swf_file),*/
                                                          g_button_action_document,
                                                          cbb.id_doc_area,
                                                          g_button_action_external_app,
                                                          cbb.domain,
                                                          g_button_action_static_templ,
                                                          cbb.id_type) VALUE,
                                                   get_app_file(cbb.id_swf_file) swf_name,
                                                   bb.rank,
                                                   cbb.id_pn_data_block,
                                                   cbb.id_doc_area,
                                                   cbb.id_task_type,
                                                   cbb.id_type,
                                                   cbb.internal_task_type,
                                                   cbb.id_pn_group,
                                                   tt.id_parent id_pn_task_type_parent
                                              FROM conf_button_block cbb
                                              LEFT JOIN tl_task tt
                                                ON cbb.id_task_type = tt.id_tl_task
                                            
                                              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                                    t.id_pn_soap_block,
                                                    t.id_conf_button_block,
                                                    t.rank,
                                                    t.id_parent,
                                                    t.flg_visible,
                                                    t.flg_activation
                                                     FROM TABLE(i_buttons) t) bb
                                                ON cbb.id_conf_button_block = bb.id_conf_button_block
                                               AND cbb.action NOT IN (g_button_action_new_templ, 'SC')
                                               AND bb.flg_visible = pk_alert_constant.g_yes
                                               AND bb.flg_activation = pk_alert_constant.g_no) btn_int) btn)) aux
             ORDER BY aux.rank ASC, aux.button_name ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_button_blocks);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_button_blocks);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_static_buttons;

    /********************************************************************************************
    * Returns the button blocks associated with SOAP Blocks List
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode       Espisode ID
    * @param IN   i_buttons       Buttons list
    *
    * @param OUT  o_button_blocks Button blocks structure
    * @param OUT  o_error       Error structure
    *
    * @author                     Sofia Mendes
    * @since                      01-Oct-2012
    ********************************************************************************************/
    FUNCTION get_dynamic_buttons
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_market     IN market.id_market%TYPE,
        io_buttons      IN OUT t_coll_button,
        i_id_epis_pn    IN NUMBER DEFAULT NULL,
        o_button_blocks OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DYNAMIC_BUTTONS';
        c_templates          pk_types.cursor_type;
        l_daas               table_number := table_number();
        l_search_daas        table_number := table_number();
        l_search_types       table_varchar := table_varchar();
        l_last_search_type   doc_template_context.flg_type%TYPE;
        l_last_id_doc_area   doc_area.id_doc_area%TYPE;
        l_templ_ids          table_number := table_number();
        l_templ_descs        table_varchar := table_varchar();
        l_flg_multiple       table_varchar := table_varchar();
        l_templates          t_coll_template := t_coll_template();
        l_no_templates       PLS_INTEGER := 0;
        l_not_multiple_areas table_number := table_number();
        l_found              PLS_INTEGER;
    
        l_id_visit visit.id_visit%TYPE;
    
        l_id_type_assess_scales CONSTANT NUMBER(2) := 34;
        l_doc_category t_coll_categories := t_coll_categories();
    
        l_coll_macro t_coll_macro := t_coll_macro();
    
        CURSOR c_search IS
            SELECT t.id_doc_area, t.flg_type, t.flg_multiple
              FROM (SELECT dais.id_doc_area,
                           dais.flg_type,
                           dais.flg_multiple,
                           row_number() over(PARTITION BY dais.id_doc_area ORDER BY dais.id_institution DESC, dais.id_market DESC, dais.id_software DESC) rn
                      FROM doc_area_inst_soft dais
                     WHERE dais.id_institution IN (0, i_prof.institution)
                       AND dais.id_software IN (0, i_prof.software)
                       AND (dais.id_market IN (0, i_id_market) OR dais.id_market IS NULL)
                       AND dais.id_doc_area IN (SELECT /*+opt_estimate(table daa rows=1)*/
                                                 daa.column_value id_doc_area
                                                  FROM TABLE(l_daas) daa)) t
             WHERE t.rn = 1
             ORDER BY t.flg_type;
    
        PROCEDURE set_templ_to_list
        (
            i_templ_ids    IN table_number,
            i_templ_descs  IN table_varchar,
            i_search_daas  IN NUMBER,
            i_search_type  IN VARCHAR2,
            i_flg_multiple IN VARCHAR2
        ) IS
        BEGIN
            FOR j IN 1 .. l_templ_ids.count
            LOOP
                -- append each template found to the templates collection
                l_templates.extend;
                l_templates(l_templates.last) := t_rec_template(id_doc_template => i_templ_ids(j),
                                                                desc_template   => i_templ_descs(j),
                                                                id_doc_area     => i_search_daas,
                                                                flg_type        => i_search_type);
            END LOOP;
        
        END set_templ_to_list;
    
    BEGIN
        g_error := 'call pk_episode.get_id_visit. i_episode: ' || i_episode;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_id_visit := pk_episode.get_id_visit(i_episode => i_episode);
    
        FOR i IN 1 .. io_buttons.count
        LOOP
            -- get list of doc_areas
            IF io_buttons(i)
             .id_doc_area IS NOT NULL
                AND io_buttons(i)
               .action IN (g_button_action_document, g_button_action_shortcut, g_button_action_search_templ)
            THEN
                l_daas.extend;
                l_daas(l_daas.last) := io_buttons(i).id_doc_area;
            END IF;
        END LOOP;
    
        -- removed multiple occurences of doc_area
        l_daas := l_daas MULTISET UNION DISTINCT table_number();
    
        pk_alertlog.log_debug(text            => 'documentable areas: ' || pk_utils.to_string(i_input => l_daas),
                              object_name     => g_package_name,
                              sub_object_name => l_func_name);
    
        -- get templates search mode for doc_areas
        g_error := 'OPEN c_search';
        OPEN c_search;
        FETCH c_search BULK COLLECT
            INTO l_search_daas, l_search_types, l_flg_multiple;
        CLOSE c_search;
    
        FOR i IN 1 .. l_search_types.count
        LOOP
            l_no_templates := 0;
        
            IF l_search_types(i) = l_last_search_type
               AND l_search_types(i) IN (pk_touch_option.g_flg_type_complaint_sch_evnt,
                                         pk_touch_option.g_flg_type_appointment,
                                         pk_touch_option.g_flg_type_clin_serv)
            THEN
                -- do not repeat the search for these three search modes:
                -- they yield the same results every time                
                IF (l_search_daas(i) <> l_last_id_doc_area AND l_templ_ids.count > 0)
                THEN
                    g_error := 'CALL set_templ_to_list. doc_area: ' || l_search_daas(i) || ' type: ' ||
                               l_search_types(i) || ' flg_multiple: ' || l_flg_multiple(i);
                    pk_alertlog.log_debug(g_error);
                    set_templ_to_list(i_templ_ids    => l_templ_ids,
                                      i_templ_descs  => l_templ_descs,
                                      i_search_daas  => l_search_daas(i),
                                      i_search_type  => l_search_types(i),
                                      i_flg_multiple => l_flg_multiple(i));
                END IF;
            
            ELSE
                -- get available templates
                g_error := 'CALL pk_touch_option.get_doc_template (doc_area: ' || l_search_daas(i) || ')';
                IF NOT pk_touch_option.get_doc_template(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_patient   => i_patient,
                                                        i_episode   => i_episode,
                                                        i_doc_area  => l_search_daas(i),
                                                        i_context   => NULL,
                                                        i_flg_type  => l_search_types(i),
                                                        o_templates => c_templates,
                                                        o_error     => o_error)
                THEN
                    l_no_templates := 1;
                END IF;
            
                -- clear template collections
                l_templ_ids   := table_number();
                l_templ_descs := table_varchar();
            
                IF (l_no_templates = 0)
                THEN
                    IF c_templates%ISOPEN
                    THEN
                        g_error := 'FETCH c_templates';
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package_name,
                                                      sub_object_name => l_func_name);
                        FETCH c_templates BULK COLLECT
                            INTO l_templ_ids, l_templ_descs;
                        CLOSE c_templates;
                    END IF;
                END IF;
            
                g_error := 'CALL set_templ_to_list. doc_area: ' || l_search_daas(i) || ' type: ' || l_search_types(i) ||
                           ' flg_multiple: ' || l_flg_multiple(i);
                pk_alertlog.log_debug(g_error);
                set_templ_to_list(i_templ_ids    => l_templ_ids,
                                  i_templ_descs  => l_templ_descs,
                                  i_search_daas  => l_search_daas(i),
                                  i_search_type  => l_search_types(i),
                                  i_flg_multiple => l_flg_multiple(i));
            END IF;
            -- save last type searched
            l_last_search_type := l_search_types(i);
            l_last_id_doc_area := l_search_daas(i);
        
            --save the areas that does not support multiple templates
            IF (l_flg_multiple(i) = pk_alert_constant.g_no)
            THEN
                l_not_multiple_areas.extend(1);
                l_not_multiple_areas(l_not_multiple_areas.last) := l_search_daas(i);
            END IF;
        
        END LOOP;
    
        --when a doc_area is configured with flg_multiple='N' (does not allow multiple templates), the 'Activate Others' 
        --option does not work. Therefore, this option will not be shown in this case, even though the button 'Activate Others' is 
        -- configured in the area                
        IF (l_not_multiple_areas.count > 0)
        THEN
            g_error := 'LOOP TROUGHT buttons';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            FOR i IN 1 .. io_buttons.count
            LOOP
                IF (io_buttons(i).action = g_button_action_search_templ)
                THEN
                    l_found := 0;
                    --check if the button Activate Others is configured as a child of the button associated to the current doc_area
                    BEGIN
                        SELECT 1
                          INTO l_found
                          FROM TABLE(io_buttons) btn
                         WHERE btn.id_conf_button_block = io_buttons(i).id_parent
                           AND btn.id_pn_soap_block = io_buttons(i).id_pn_soap_block
                           AND btn.id_doc_area IN (SELECT column_value
                                                     FROM TABLE(l_not_multiple_areas));
                    
                        IF (l_found = 1)
                        THEN
                            io_buttons(i).flg_visible := pk_alert_constant.g_no;
                        END IF;
                    
                    EXCEPTION
                        WHEN OTHERS THEN
                            NULL;
                    END;
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'CALL PK_PROG_NOTES_IN.GET_DOC_AREA_MACROS';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_prog_notes_in.get_doc_area_macros(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_templates   => l_templates,
                                                    io_coll_macro => l_coll_macro,
                                                    o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- removed multiple occurences of doc_area
        DECLARE
            l_tmp t_coll_template := t_coll_template();
        BEGIN
            l_tmp       := get_epis_pn_doc_template(i_lang, i_prof, i_id_epis_pn);
            l_templates := union_distinct_coll_template(i_tbl1 => l_templates, i_tbl2 => l_tmp);
        END;
    
        -- get all doc_categories for institution and software
    
        l_doc_category := pk_summary_page.tf_categories_permission(i_lang => i_lang,
                                                                   i_prof => i_prof,
                                                                   i_pat  => i_patient);
    
        -- open output cursor o_button_blocks
        g_error := 'OPEN o_button_blocks';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_button_blocks FOR
            WITH buttons AS
             (SELECT bb.id_pn_soap_block,
                     cbb.id_conf_button_block,
                     bb.id_parent,
                     cbb.code_conf_button_block,
                     cbb.icon,
                     cbb.action,
                     dt.id_doc_template         id_value,
                     dt.desc_template           desc_value,
                     bb.rank,
                     cbb.id_pn_data_block,
                     pdb.id_doc_area,
                     cbb.id_task_type,
                     cbb.id_type,
                     cbb.internal_task_type,
                     cbb.id_pn_group,
                     bb.flg_activation,
                     cbb.id_swf_file,
                     da.flg_score
                FROM conf_button_block cbb
                JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                      t.id_pn_soap_block, t.id_conf_button_block, t.rank, t.id_parent, t.flg_visible, t.flg_activation
                       FROM TABLE(io_buttons) t) bb
                  ON cbb.id_conf_button_block = bb.id_conf_button_block
                LEFT JOIN pn_data_block pdb
                  ON cbb.id_pn_data_block = pdb.id_pn_data_block
                JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                      t.id_doc_area, t.id_doc_template, t.desc_template
                       FROM TABLE(l_templates) t) dt
                  ON cbb.action = g_button_action_new_templ
                 AND dt.id_doc_area = pdb.id_doc_area
                LEFT JOIN doc_area da
                  ON da.id_doc_area = pdb.id_doc_area
               WHERE (cbb.action = g_button_action_new_templ)
                 AND bb.flg_visible = pk_alert_constant.g_yes
              
              UNION ALL
              SELECT bb.id_pn_soap_block,
                     cbb.id_conf_button_block,
                     bb.id_parent,
                     cbb.code_conf_button_block,
                     cbb.icon,
                     cbb.action,
                     dc.id_doc_category         id_value,
                     dc.translated_code         desc_value,
                     dc.rank,
                     cbb.id_pn_data_block,
                     pdb.id_doc_area,
                     cbb.id_task_type,
                     cbb.id_type,
                     cbb.internal_task_type,
                     cbb.id_pn_group,
                     bb.flg_activation,
                     cbb.id_swf_file,
                     NULL                       flg_score
                FROM conf_button_block cbb
                JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                      t.id_pn_soap_block, t.id_conf_button_block, t.rank, t.id_parent, t.flg_visible, t.flg_activation
                       FROM TABLE(io_buttons) t) bb
                  ON cbb.id_conf_button_block = bb.id_conf_button_block
                 AND cbb.id_task_type = pk_prog_notes_constants.g_task_templates
                 AND cbb.id_swf_file IS NOT NULL
                LEFT JOIN pn_data_block pdb
                  ON cbb.id_pn_data_block = pdb.id_pn_data_block
                JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                      t.id_doc_category, t.translated_code, rank
                       FROM TABLE(l_doc_category) t) dc
                  ON cbb.action = g_button_action_static_doc_cat
                 AND cbb.id_type = l_id_type_assess_scales
              -- JOIN doc_category_area_inst_soft dcais
              --   ON dcais.id_doc_category = dc.id_doc_category
              --  AND dcais.id_software = i_prof.software
              --   AND dcais.id_institution = i_prof.institution
               WHERE bb.flg_visible = pk_alert_constant.g_yes
                 AND cbb.action = g_button_action_static_doc_cat
                 AND cbb.id_type = l_id_type_assess_scales)
            
            SELECT *
              FROM (SELECT block_id,
                           id_conf_button_block,
                           id_parent,
                           unq_btn_id,
                           unq_btn_id_parent,
                           button_name,
                           icon,
                           action,
                           VALUE,
                           swf_name,
                           rank,
                           id_pn_data_block,
                           decode(get_child_count(id_conf_button_block, block_id),
                                  0,
                                  pk_alert_constant.g_no,
                                  pk_alert_constant.g_yes) show_header,
                           id_doc_area,
                           id_pn_task_type,
                           check_button_active(i_lang,
                                               i_prof,
                                               i_episode,
                                               l_id_visit,
                                               i_patient,
                                               id_pn_task_type,
                                               flg_activation,
                                               id_doc_area) flg_status,
                           id_type id_type,
                           internal_task_type,
                           id_pn_group,
                           id_macro_documentation,
                           flg_score
                      FROM (SELECT btn_int.id_pn_soap_block block_id,
                                   btn_int.id_conf_button_block,
                                   btn_int.id_parent,
                                   --the following 2 fileds are required because it is possible to reuse the same button in different data blocks, 
                                   -- and the flash needs an unique id for the button in a block
                                   btn_int.id_pn_soap_block || '0' || btn_int.id_conf_button_block unq_btn_id,
                                   CASE
                                        WHEN btn_int.id_parent IS NOT NULL THEN
                                         btn_int.id_pn_soap_block || '0' || btn_int.id_parent
                                        ELSE
                                         NULL
                                    END unq_btn_id_parent,
                                   btn_int.desc_value button_name,
                                   btn_int.icon,
                                   btn_int.action,
                                   btn_int.value,
                                   btn_int.swf_name,
                                   btn_int.rank,
                                   btn_int.id_pn_data_block,
                                   btn_int.id_doc_area,
                                   btn_int.id_task_type id_pn_task_type,
                                   btn_int.id_type,
                                   btn_int.internal_task_type,
                                   btn_int.id_pn_group,
                                   btn_int.id_macro_documentation,
                                   btn_int.flg_activation,
                                   btn_int.flg_score
                              FROM (
                                    --parent template
                                    SELECT b.id_pn_soap_block,
                                            to_number(b.id_value || b.id_conf_button_block) id_conf_button_block,
                                            b.id_parent,
                                            --
                                            b.icon,
                                            b.action,
                                            b.id_value VALUE,
                                            get_app_file(b.id_swf_file) swf_name,
                                            b.desc_value,
                                            b.rank,
                                            b.id_pn_data_block,
                                            b.id_doc_area,
                                            b.id_task_type,
                                            b.id_type,
                                            b.internal_task_type,
                                            b.id_pn_group,
                                            NULL id_macro_documentation,
                                            b.flg_activation,
                                            da.flg_score
                                      FROM buttons b
                                      LEFT JOIN doc_area da
                                        ON da.id_doc_area = b.id_doc_area
                                    --child template: the selectable one
                                    UNION ALL
                                    SELECT b.id_pn_soap_block,
                                            to_number(b.id_value || '0' || b.id_value || b.id_conf_button_block) id_conf_button_block,
                                            to_number(b.id_value || b.id_conf_button_block) id_parent,
                                            --
                                            b.icon,
                                            b.action,
                                            b.id_value VALUE,
                                            get_app_file(b.id_swf_file) swf_name,
                                            b.desc_value,
                                            1 rank,
                                            b.id_pn_data_block,
                                            b.id_doc_area,
                                            b.id_task_type,
                                            b.id_type,
                                            b.internal_task_type,
                                            b.id_pn_group,
                                            NULL id_macro_documentation,
                                            b.flg_activation,
                                            da.flg_score
                                      FROM buttons b
                                      LEFT JOIN doc_area da
                                        ON da.id_doc_area = b.id_doc_area
                                    --if a macro exists we should create a child button with the template, otherwise it is not needed
                                    -- the child template button
                                     WHERE EXISTS
                                     (SELECT /*+opt_estimate(table dtm rows=1)*/
                                             dtm.id_doc_area
                                              FROM TABLE(l_coll_macro) dtm
                                             WHERE (dtm.id_doc_area = b.id_doc_area AND dtm.id_doc_template = b.id_value))
                                    -----
                                    UNION ALL
                                    --Macros
                                    SELECT b.id_pn_soap_block,
                                            to_number(dtm.id_doc_macro_version || '0' || b.id_value ||
                                                      b.id_conf_button_block) id_conf_button_block,
                                            to_number(b.id_value || b.id_conf_button_block) id_parent,
                                            --
                                            b.icon,
                                            b.action,
                                            b.id_value VALUE,
                                            get_app_file(b.id_swf_file) swf_name,
                                            dtm.desc_macro desc_value,
                                            2 rank,
                                            b.id_pn_data_block,
                                            b.id_doc_area,
                                            b.id_task_type,
                                            dtm.id_doc_macro id_type,
                                            dtm.flg_status internal_task_type,
                                            b.id_pn_group,
                                            dtm.id_doc_macro_version id_macro_documentation,
                                            b.flg_activation,
                                            da.flg_score
                                      FROM buttons b
                                      LEFT JOIN doc_area da
                                        ON da.id_doc_area = b.id_doc_area
                                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                             rownum rn,
                                             t.id_doc_area,
                                             t.id_doc_template,
                                             t.desc_macro,
                                             t.id_doc_macro_version,
                                             t.id_doc_macro,
                                             t.flg_status
                                              FROM TABLE(l_coll_macro) t) dtm
                                        ON (dtm.id_doc_area = b.id_doc_area AND dtm.id_doc_template = b.id_value)
                                    UNION ALL
                                    --other dynamic buttons: buttons that depends on validations dependent of episode data
                                    -- when the button is only active when there is no active data in the episode
                                    SELECT bb.id_pn_soap_block,
                                            cbb.id_conf_button_block,
                                            bb.id_parent,
                                            cbb.icon,
                                            cbb.action,
                                            decode(cbb.action,
                                                   g_button_action_shortcut,
                                                   cbb.id_sys_shortcut,
                                                   g_button_action_document,
                                                   cbb.id_doc_area,
                                                   g_button_action_static_templ,
                                                   cbb.id_type) VALUE,
                                            get_app_file(cbb.id_swf_file) swf_name,
                                            --Change translation to sys_message start
                                            --(SELECT pk_translation.get_translation(i_lang, cbb.code_conf_button_block)
                                            (SELECT pk_message.get_message(i_lang, i_prof, cbb.code_conf_button_block)
                                             --Change translation to sys_message end
                                               FROM dual) desc_value,
                                            bb.rank,
                                            cbb.id_pn_data_block,
                                            cbb.id_doc_area,
                                            cbb.id_task_type,
                                            cbb.id_type,
                                            cbb.internal_task_type,
                                            cbb.id_pn_group,
                                            NULL id_macro_documentation,
                                            bb.flg_activation,
                                            da.flg_score
                                      FROM conf_button_block cbb
                                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                             t.id_pn_soap_block,
                                             t.id_conf_button_block,
                                             t.rank,
                                             t.id_parent,
                                             t.flg_visible,
                                             t.flg_activation
                                              FROM TABLE(io_buttons) t) bb
                                        ON cbb.id_conf_button_block = bb.id_conf_button_block
                                      LEFT JOIN pn_data_block pdb
                                        ON cbb.id_pn_data_block = pdb.id_pn_data_block
                                      LEFT JOIN doc_area da
                                        ON da.id_doc_area = cbb.id_doc_area
                                     WHERE bb.flg_visible = pk_alert_constant.g_yes
                                       AND bb.flg_activation <> pk_alert_constant.g_no) btn_int)) aux
             ORDER BY aux.rank ASC, aux.button_name ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_button_blocks);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_button_blocks);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_dynamic_buttons;

    -----------------------------------------------------------
    -----------------------------------------------------------
    PROCEDURE l______________(i_lang IN language.id_language%TYPE) IS
    BEGIN
        dbms_output.put_line(i_lang);
    END;

    /********************************************************************************************
    * returns simple text blocks based on the data_area
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Episode ID
    * @param IN   i_data_area   Data Area list to retrieve associated simple text blocks
    *
    * @param OUT  o_simple_text Simple Text blocks structure
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_block_simple_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_data_area   IN table_varchar,
        o_simple_text OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- simple text block components
        l_data_area table_varchar := table_varchar();
        l_desc_info table_varchar := table_varchar();
        -- general lists
        l_simple_text    table_varchar := table_varchar();
        l_dist_data_area table_varchar := table_varchar();
    
    BEGIN
        -- inits
        pk_types.open_my_cursor(o_simple_text);
    
        IF i_data_area.count = 0
        THEN
            RAISE g_exception;
        END IF;
    
        -- because one data area may be assigned to more than one SOAP block
        l_dist_data_area := table_varchar() MULTISET UNION DISTINCT i_data_area;
    
        -- loop through the data areas
        FOR idx IN l_dist_data_area.first .. l_dist_data_area.last
        LOOP
            CASE l_dist_data_area(idx)
            --------------------  Reported Medication
                WHEN g_simpletext_rm THEN
                    IF NOT get_simpletext_rm(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_patient     => i_patient,
                                             i_episode     => i_episode,
                                             o_simple_text => l_simple_text,
                                             o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    --------------------  Vital Signs
                WHEN g_simpletext_vs THEN
                    IF NOT get_simpletext_vs(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_patient     => i_patient,
                                             i_episode     => i_episode,
                                             o_simple_text => l_simple_text,
                                             o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    -------------------- Exams
                WHEN g_simpletext_e THEN
                    IF NOT get_simpletext_e(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_patient     => i_patient,
                                            i_episode     => i_episode,
                                            o_simple_text => l_simple_text,
                                            o_error       => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                    -------------------- Analysis
                WHEN g_simpletext_a THEN
                    IF NOT get_simpletext_a(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_patient     => i_patient,
                                            i_episode     => i_episode,
                                            o_simple_text => l_simple_text,
                                            o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    -------------------- Problems
                WHEN g_simpletext_p THEN
                    IF NOT get_simpletext_p(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_patient     => i_patient,
                                            i_episode     => i_episode,
                                            o_simple_text => l_simple_text,
                                            o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    -------------------- Diagnósticos
                WHEN g_simpletext_d THEN
                    IF NOT get_simpletext_d(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_patient     => i_patient,
                                            i_episode     => i_episode,
                                            o_simple_text => l_simple_text,
                                            o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    --------------------
                WHEN g_simpletext_mce THEN
                    IF NOT get_simpletext_mce(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_patient     => i_patient,
                                              i_episode     => i_episode,
                                              o_simple_text => l_simple_text,
                                              o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    --------------------
                WHEN g_simpletext_me THEN
                    IF NOT get_simpletext_me(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_patient     => i_patient,
                                             i_episode     => i_episode,
                                             o_simple_text => l_simple_text,
                                             o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    --------------------
                WHEN g_simpletext_gp THEN
                    IF NOT get_simpletext_gp(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_patient     => i_patient,
                                             i_episode     => i_episode,
                                             o_simple_text => l_simple_text,
                                             o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    --------------------
                WHEN g_simpletext_pi THEN
                    IF NOT get_simpletext_pi(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_patient     => i_patient,
                                             i_episode     => i_episode,
                                             o_simple_text => l_simple_text,
                                             o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    --------------------
                WHEN g_simpletext_mcd THEN
                    IF NOT get_simpletext_mcd(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_patient     => i_patient,
                                              i_episode     => i_episode,
                                              o_simple_text => l_simple_text,
                                              o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                WHEN g_simpletext_di THEN
                    IF g_dictation_hist
                    THEN
                        IF NOT get_simpletext_dih(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_patient     => i_patient,
                                                  i_episode     => i_episode,
                                                  o_simple_text => l_simple_text,
                                                  o_error       => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    ELSE
                        IF NOT get_simpletext_di(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_patient     => i_patient,
                                                 i_episode     => i_episode,
                                                 o_simple_text => l_simple_text,
                                                 o_error       => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                WHEN g_simpletext_sr THEN
                    IF NOT get_simpletext_sr(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_patient     => i_patient,
                                             i_episode     => i_episode,
                                             o_simple_text => l_simple_text,
                                             o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                WHEN g_simpletext_gn THEN
                    IF NOT get_simpletext_gn(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_patient     => i_patient,
                                             i_episode     => i_episode,
                                             o_simple_text => l_simple_text,
                                             o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                WHEN g_simpletext_ct THEN
                    IF NOT get_simpletext_ct(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_patient     => i_patient,
                                             i_episode     => i_episode,
                                             o_simple_text => l_simple_text,
                                             o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSE
                    l_simple_text := table_varchar();
            END CASE;
        
            -- union the output data from simple text functions
            IF l_simple_text.count != 0
            THEN
                FOR i IN l_simple_text.first .. l_simple_text.last
                LOOP
                    l_data_area.extend;
                    l_data_area(l_data_area.last) := l_dist_data_area(idx);
                
                    l_desc_info.extend;
                    l_desc_info(l_desc_info.last) := l_simple_text(i);
                END LOOP;
            END IF;
        
            l_simple_text := table_varchar();
        END LOOP;
    
        -- open output cursor: o_data_blocks
        g_error := 'OPEN o_data_blocks';
        OPEN o_simple_text FOR
        --SELECT a.name data_area, b.name desc_info
            SELECT a.name data_area, b.name desc_info, decode(a.name, g_simpletext_di, g_yes, g_no) desc_info_html_flg
              FROM (SELECT rownum rnum, column_value name
                      FROM TABLE(l_data_area)) a,
                   (SELECT rownum rnum, column_value name
                      FROM TABLE(l_desc_info)) b
             WHERE a.rnum = b.rnum;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_block_simple_text',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_simple_text);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_block_simple_text',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_simple_text);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns documentation blocks based on the data_area
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    * @param IN   i_data_area   Data Area list to retrieve associated documentation blocks
    *
    * @param OUT  o_doc_reg     Doccumentation registers
    * @param OUT  o_doc_val     Doccumentation registers values
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_block_documentation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_data_area          IN table_varchar,
        o_doc_reg            OUT pk_types.cursor_type,
        o_doc_val            OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dist_data_area table_varchar := table_varchar();
        l_desc_area      sys_message.desc_message%TYPE;
    
        -- template/documentation cursors
        c_doc_reg            pk_types.cursor_type;
        c_doc_val            pk_types.cursor_type;
        c_template_layouts   pk_types.cursor_type;
        c_doc_area_component pk_types.cursor_type;
    
        -- template/documentation param arrays
        l_doc_reg_param      table_table_varchar := table_table_varchar();
        l_doc_val_param      table_table_varchar := table_table_varchar();
        l_doc_area_component table_table_varchar := table_table_varchar();
        l_template_layouts   table_table_clob := table_table_clob();
    
        -- new variables
        l_doc_reg_all            table_table_varchar := table_table_varchar();
        l_doc_val_all            table_table_varchar := table_table_varchar();
        l_template_layouts_all   table_table_clob := table_table_clob();
        l_doc_area_component_all table_table_varchar := table_table_varchar();
    
        --
        l_flg_write       summary_page_access.flg_write%TYPE;
        l_flg_cancel      summary_page_access.flg_write%TYPE;
        l_flg_no_changes  summary_page_access.flg_no_changes%TYPE;
        l_flg_mode        doc_area_inst_soft.flg_mode%TYPE;
        l_flg_switch_mode doc_area_inst_soft.flg_switch_mode%TYPE;
    
        --
    
    BEGIN
        -- inits
        pk_types.open_my_cursor(o_doc_reg);
        pk_types.open_my_cursor(o_doc_val);
        pk_types.open_my_cursor(o_template_layouts);
        pk_types.open_my_cursor(o_doc_area_component);
        l_doc_reg_param.extend(20);
        l_doc_val_param.extend(19);
        l_doc_area_component.extend(4);
        l_template_layouts.extend(3);
        l_dist_data_area := table_varchar() MULTISET UNION DISTINCT i_data_area;
    
        -- new inits
        l_doc_reg_all.extend(27);
        l_doc_val_all.extend(21);
        l_doc_area_component_all.extend(4);
        l_template_layouts_all.extend(3);
        FOR idx1 IN l_doc_reg_all.first .. l_doc_reg_all.last
        LOOP
            l_doc_reg_all(idx1) := table_varchar();
        END LOOP;
        FOR idx2 IN l_doc_val_all.first .. l_doc_val_all.last
        LOOP
            l_doc_val_all(idx2) := table_varchar();
        END LOOP;
        FOR idx3 IN l_doc_area_component_all.first .. l_doc_area_component_all.last
        LOOP
            l_doc_area_component_all(idx3) := table_varchar();
        END LOOP;
        FOR idx4 IN l_template_layouts_all.first .. l_template_layouts_all.last
        LOOP
            l_template_layouts_all(idx4) := table_clob();
        END LOOP;
    
        -- loop through the data areas
        FOR idx IN l_dist_data_area.first .. l_dist_data_area.last
        LOOP
            -- decode template type
            CASE l_dist_data_area(idx)
                WHEN g_documentation_hpi THEN
                    l_desc_area := pk_message.get_message(i_lang, i_prof, 'PROGRESS_NOTES_T032');
                WHEN g_documentation_rs THEN
                    l_desc_area := pk_message.get_message(i_lang, i_prof, 'PROGRESS_NOTES_T033');
                WHEN g_documentation_pe THEN
                    l_desc_area := pk_message.get_message(i_lang, i_prof, 'PROGRESS_NOTES_T034');
                WHEN g_documentation_pa THEN
                    l_desc_area := pk_message.get_message(i_lang, i_prof, 'PROGRESS_NOTES_T082');
                WHEN g_documentation_oe THEN
                    l_desc_area := pk_message.get_message(i_lang, i_prof, 'PROGRESS_NOTES_T139');
                WHEN g_documentation_gpa THEN
                    l_desc_area := pk_message.get_message(i_lang, i_prof, 'PROGRESS_NOTES_T049');
                WHEN g_documentation_at THEN
                    l_desc_area := pk_message.get_message(i_lang, i_prof, 'PROGRESS_NOTES_T063');
                WHEN g_documentation_pl THEN
                    l_desc_area := pk_message.get_message(i_lang, i_prof, 'PROGRESS_NOTES_T008');
                ELSE
                    NULL;
            END CASE;
        
            -- get template/documentation data
            g_error := 'CALL get_templates ' || l_dist_data_area(idx);
            get_templates(i_lang               => i_lang,
                          i_prof               => i_prof,
                          i_patient            => i_patient,
                          i_episode            => i_episode,
                          i_doc_area_desc      => l_dist_data_area(idx),
                          o_doc_reg            => c_doc_reg,
                          o_doc_val            => c_doc_val,
                          o_template_layouts   => c_template_layouts,
                          o_doc_area_component => c_doc_area_component,
                          o_error              => o_error);
        
            ----------------------------------------------------------
            -- fetch o_doc_reg
            BEGIN
            
                g_error := 'FETCH c_doc_reg';
                FETCH c_doc_reg BULK COLLECT
                    INTO --
                         l_doc_reg_param(1), -- id_epis_documentation
                         l_doc_reg_param(2), -- id_epis_documentation_parent
                         l_doc_reg_param(3), -- id_doc_template
                         l_doc_reg_param(4), -- template_desc
                         l_doc_reg_param(5), -- dt_creation
                         l_doc_reg_param(6), -- dt_register
                         l_doc_reg_param(7), -- id_professional
                         l_doc_reg_param(8), -- nick_name
                         l_doc_reg_param(9), -- desc_speciality
                         l_doc_reg_param(10), -- id_doc_area
                         l_doc_reg_param(11), -- flg_status
                         l_doc_reg_param(12), -- notes
                         l_doc_reg_param(13), -- dt_last_update
                         l_doc_reg_param(14), -- flg_type_register
                         l_doc_reg_param(15), -- flg_origin
                         l_doc_reg_param(16), -- title
                         l_doc_reg_param(17), -- dt_order
                         l_doc_reg_param(18), -- flg_table_origin
                         l_doc_reg_param(19), -- desc_status
                         l_doc_reg_param(20); -- prof_desc
                CLOSE c_doc_reg;
            EXCEPTION
                WHEN OTHERS THEN
                    l_doc_reg_param(1) := table_varchar();
            END;
        
            ----------------------------------------------------------
            -- fetch o_doc_val
            BEGIN
                g_error := 'FETCH c_doc_val';
                FETCH c_doc_val BULK COLLECT
                    INTO --
                         l_doc_val_param(1), -- id_epis_documentation
                         l_doc_val_param(2), -- id_doc_template
                         l_doc_val_param(3), -- id_documentation
                         l_doc_val_param(4), -- id_doc_component
                         l_doc_val_param(5), -- id_doc_element_crit
                         l_doc_val_param(6), -- dt_register
                         l_doc_val_param(7), -- desc_doc_component
                         l_doc_val_param(8), -- flg_type
                         l_doc_val_param(9), -- desc_element
                         l_doc_val_param(10), -- VALUE
                         l_doc_val_param(11), -- id_doc_area
                         l_doc_val_param(12), -- rank_component
                         l_doc_val_param(13), -- rank_element
                         l_doc_val_param(14), -- desc_quantifier
                         l_doc_val_param(15), -- desc_quantification               
                         l_doc_val_param(16), -- desc_qualification
                         l_doc_val_param(17), -- display_format
                         l_doc_val_param(18), -- separator,
                         l_doc_val_param(19); -- internal_name
                CLOSE c_doc_val;
            EXCEPTION
                WHEN OTHERS THEN
                    l_doc_val_param(1) := table_varchar();
            END;
        
            -- fetch c_template_layouts
            BEGIN
                g_error := 'FETCH c_doc_val';
                FETCH c_template_layouts BULK COLLECT
                    INTO --
                         l_template_layouts(1), -- id_doc_template
                         l_template_layouts(2), -- layout
                         l_template_layouts(3); --id_doc_area                       
                CLOSE c_template_layouts;
            EXCEPTION
                WHEN OTHERS THEN
                    l_template_layouts(1) := table_clob();
            END;
        
            -- fetch c_doc_area_component
            BEGIN
                g_error := 'FETCH c_doc_val';
                FETCH c_doc_area_component BULK COLLECT
                    INTO --
                         l_doc_area_component(1), -- id_documentation
                         l_doc_area_component(2), -- flg_type
                         l_doc_area_component(3), -- desc_doc_component                         
                         l_doc_area_component(4); -- id_doc_area
                CLOSE c_doc_area_component;
            EXCEPTION
                WHEN OTHERS THEN
                    l_doc_area_component(1) := table_varchar();
            END;
        
            ----------------------------------------------------------
            -- fill l_doc_reg_all collection
            IF l_doc_reg_param(1).count != 0
            THEN
                FOR n IN l_doc_reg_all.first .. l_doc_reg_param.last --l_doc_reg_all.LAST [1 .. 20] not [1 .. 27]
                LOOP
                    -- insert all fetched records into l_doc_reg_all collection
                    FOR m IN l_doc_reg_param(1).first .. l_doc_reg_param(1).last
                    LOOP
                        l_doc_reg_all(n).extend;
                        l_doc_reg_all(n)(l_doc_reg_all(n).last) := l_doc_reg_param(n) (m);
                    
                        -- if last record index then add extra flags
                        IF n = l_doc_reg_param.last
                        THEN
                            IF NOT get_flags_permission(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_doc_area        => l_doc_reg_param(10) (m),
                                                        i_flg_status      => l_doc_reg_param(11) (m),
                                                        i_professional    => l_doc_reg_param(7) (m),
                                                        i_flg_origin      => l_doc_reg_param(15) (m),
                                                        i_data_area       => l_dist_data_area(idx),
                                                        o_flg_write       => l_flg_write,
                                                        o_flg_cancel      => l_flg_cancel,
                                                        o_flg_no_changes  => l_flg_no_changes,
                                                        o_flg_mode        => l_flg_mode,
                                                        o_flg_switch_mode => l_flg_switch_mode)
                            THEN
                                l_flg_write       := NULL;
                                l_flg_cancel      := NULL;
                                l_flg_no_changes  := NULL;
                                l_flg_mode        := NULL;
                                l_flg_switch_mode := NULL;
                            END IF;
                        
                            l_doc_reg_all(21).extend;
                            l_doc_reg_all(21)(l_doc_reg_all(21).last) := l_desc_area;
                            l_doc_reg_all(22).extend;
                            l_doc_reg_all(22)(l_doc_reg_all(22).last) := l_dist_data_area(idx);
                            l_doc_reg_all(23).extend;
                            l_doc_reg_all(23)(l_doc_reg_all(23).last) := l_flg_write;
                            l_doc_reg_all(24).extend;
                            l_doc_reg_all(24)(l_doc_reg_all(24).last) := l_flg_cancel;
                            l_doc_reg_all(25).extend;
                            l_doc_reg_all(25)(l_doc_reg_all(25).last) := l_flg_no_changes;
                            l_doc_reg_all(26).extend;
                            l_doc_reg_all(26)(l_doc_reg_all(26).last) := l_flg_mode;
                            l_doc_reg_all(27).extend;
                            l_doc_reg_all(27)(l_doc_reg_all(27).last) := l_flg_switch_mode;
                        END IF;
                    END LOOP;
                END LOOP;
            END IF;
            ----------------------------------------------------------
        
            -- fill l_doc_val_all collection
            IF l_doc_val_param(1).count != 0
            THEN
                FOR i IN l_doc_val_all.first .. l_doc_val_param.last --l_doc_val_all.LAST [1 .. 15] not [1 .. 17]
                LOOP
                    -- insert all fetched records into l_doc_val_all collection
                    FOR j IN l_doc_val_param(1).first .. l_doc_val_param(1).last
                    LOOP
                        l_doc_val_all(i).extend;
                        l_doc_val_all(i)(l_doc_val_all(i).last) := l_doc_val_param(i) (j);
                    
                        -- if last record index then add extra flags
                        IF i = l_doc_val_param.last
                        THEN
                            l_doc_val_all(20).extend;
                            l_doc_val_all(20)(l_doc_val_all(20).last) := l_desc_area;
                            l_doc_val_all(21).extend;
                            l_doc_val_all(21)(l_doc_val_all(21).last) := l_dist_data_area(idx);
                        END IF;
                    END LOOP;
                END LOOP;
            END IF;
        
            -- fill l_doc_area_component_all collection
            IF l_doc_area_component(1).count != 0
            THEN
                FOR i IN l_doc_area_component.first .. l_doc_area_component.last --l_doc_val_all.LAST [1 .. 15] not [1 .. 17]
                LOOP
                    -- insert all fetched records into l_doc_val_all collection
                    FOR j IN l_doc_area_component(1).first .. l_doc_area_component(1).last
                    LOOP
                        l_doc_area_component_all(i).extend;
                        l_doc_area_component_all(i)(l_doc_area_component_all(i).last) := l_doc_area_component(i) (j);
                    
                    END LOOP;
                END LOOP;
            END IF;
        
            -- fill l_template_layouts_all collection
            IF l_template_layouts(1).count != 0
            THEN
                FOR i IN l_template_layouts.first .. l_template_layouts.last --l_doc_val_all.LAST [1 .. 15] not [1 .. 17]
                LOOP
                    -- insert all fetched records into l_doc_val_all collection
                    FOR j IN l_template_layouts(1).first .. l_template_layouts(1).last
                    LOOP
                        l_template_layouts_all(i).extend;
                        l_template_layouts_all(i)(l_template_layouts_all(i).last) := l_template_layouts(i) (j);
                    
                    END LOOP;
                END LOOP;
            END IF;
            ----------------------------------------------------------
        END LOOP;
    
        -- open o_doc_reg
        OPEN o_doc_reg FOR
            SELECT t23.column_value flg_write,
                   t24.column_value flg_cancel,
                   t25.column_value flg_no_changes,
                   t26.column_value flg_mode,
                   t27.column_value flg_switch_mode,
                   (SELECT title_code
                      FROM pn_data_block p
                     WHERE p.id_pn_data_block = db1.id_pn_db) title_code, -- EMR-14
                   (SELECT sample_text_code
                      FROM pn_data_block p
                     WHERE p.id_pn_data_block = db1.id_pn_db) sample_text_code, -- EMR-14
                   t21.column_value desc_area,
                   t22.column_value data_area,
                   CAST(t1.column_value AS NUMBER) id_epis_documentation,
                   CAST(t2.column_value AS NUMBER) PARENT,
                   CAST(t3.column_value AS NUMBER) id_doc_template,
                   nvl(t4.column_value, t16.column_value) template_desc,
                   t5.column_value dt_creation,
                   t6.column_value dt_register,
                   CAST(t7.column_value AS NUMBER) id_professional,
                   t8.column_value nick_name,
                   t9.column_value desc_speciality,
                   CAST(t10.column_value AS NUMBER) id_doc_area,
                   t11.column_value flg_status,
                   t19.column_value desc_status,
                   t12.column_value notes,
                   t13.column_value dt_last_update,
                   t14.column_value flg_type_register,
                   t15.column_value flg_origin,
                   t16.column_value title,
                   t17.column_value dt_order,
                   t18.column_value flg_table_origin,
                   t20.column_value prof_desc
              FROM (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(1))) t1,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(2))) t2,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(3))) t3,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(4))) t4,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(5))) t5,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(6))) t6,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(7))) t7,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(8))) t8,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(9))) t9,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(10))) t10,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(11))) t11,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(12))) t12,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(13))) t13,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(14))) t14,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(15))) t15,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(16))) t16,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(17))) t17,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(18))) t18,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(19))) t19,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(20))) t20,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(21))) t21,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(22))) t22,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(23))) t23,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(24))) t24,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(25))) t25,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(26))) t26,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_reg_all(27))) t27,
                   (SELECT id_pn_data_block id_pn_db, data_area, id_doc_area
                      FROM TABLE(g_ctx.data_blocks)) db1 -- EMR-14
            --pn_data_block pdb -- EMR-14 List all data_block duplicate records
             WHERE t1.rnum = t2.rnum
               AND t1.rnum = t3.rnum
               AND t1.rnum = t4.rnum
               AND t1.rnum = t5.rnum
               AND t1.rnum = t6.rnum
               AND t1.rnum = t7.rnum
               AND t1.rnum = t8.rnum
               AND t1.rnum = t9.rnum
               AND t1.rnum = t10.rnum
               AND t1.rnum = t11.rnum
               AND t1.rnum = t12.rnum
               AND t1.rnum = t13.rnum
               AND t1.rnum = t14.rnum
               AND t1.rnum = t15.rnum
               AND t1.rnum = t16.rnum
               AND t1.rnum = t17.rnum
               AND t1.rnum = t18.rnum
               AND t1.rnum = t19.rnum
               AND t1.rnum = t20.rnum
               AND t1.rnum = t21.rnum
               AND t1.rnum = t22.rnum
               AND t1.rnum = t23.rnum
               AND t1.rnum = t24.rnum
               AND t1.rnum = t25.rnum
               AND t1.rnum = t26.rnum
               AND t1.rnum = t27.rnum
               AND db1.data_area = t22.column_value
               AND db1.id_doc_area = t10.column_value
            --AND pdb.data_area = t22.column_value
            --AND pdb.flg_available = g_yes
             ORDER BY t1.rnum;
    
        -- open o_doc_val
        OPEN o_doc_val FOR
            SELECT t21.column_value data_area,
                   CAST(t1.column_value AS NUMBER) id_epis_documentation,
                   CAST(t2.column_value AS NUMBER) id_doc_template,
                   CAST(t3.column_value AS NUMBER) id_documentation,
                   CAST(t4.column_value AS NUMBER) id_doc_component,
                   CAST(t5.column_value AS NUMBER) id_doc_element_crit,
                   t6.column_value dt_reg,
                   t7.column_value desc_doc_component,
                   t8.column_value flg_type,
                   t9.column_value desc_element,
                   t10.column_value VALUE,
                   CAST(t11.column_value AS NUMBER) id_doc_area,
                   CAST(t12.column_value AS NUMBER) rank_component,
                   CAST(t13.column_value AS NUMBER) rank_element,
                   t14.column_value desc_quantifier,
                   t15.column_value desc_quantification,
                   t16.column_value desc_qualification,
                   t17.column_value display_format,
                   t18.column_value separator,
                   t19.column_value internal_name
              FROM (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(1))) t1,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(2))) t2,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(3))) t3,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(4))) t4,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(5))) t5,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(6))) t6,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(7))) t7,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(8))) t8,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(9))) t9,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(10))) t10,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(11))) t11,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(12))) t12,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(13))) t13,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(14))) t14,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(15))) t15,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(16))) t16,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(17))) t17,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(18))) t18,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(19))) t19,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(20))) t20,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_val_all(21))) t21
             WHERE t1.rnum = t2.rnum
               AND t1.rnum = t3.rnum
               AND t1.rnum = t4.rnum
               AND t1.rnum = t5.rnum
               AND t1.rnum = t6.rnum
               AND t1.rnum = t7.rnum
               AND t1.rnum = t8.rnum
               AND t1.rnum = t9.rnum
               AND t1.rnum = t10.rnum
               AND t1.rnum = t11.rnum
               AND t1.rnum = t12.rnum
               AND t1.rnum = t13.rnum
               AND t1.rnum = t14.rnum
               AND t1.rnum = t15.rnum
               AND t1.rnum = t16.rnum
               AND t1.rnum = t17.rnum
               AND t1.rnum = t18.rnum
               AND t1.rnum = t19.rnum
               AND t1.rnum = t20.rnum
               AND t1.rnum = t21.rnum;
    
        -- open o_template_layouts
        OPEN o_template_layouts FOR
            SELECT to_number(t1.column_value) id_doc_template,
                   t2.column_value layout,
                   to_number(t3.column_value) id_doc_area
              FROM (SELECT rownum rnum, column_value
                      FROM TABLE(l_template_layouts_all(1))) t1,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_template_layouts_all(2))) t2,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_template_layouts_all(3))) t3
             WHERE t1.rnum = t2.rnum
               AND t1.rnum = t3.rnum;
    
        -- open o_doc_area_component
        OPEN o_doc_area_component FOR
            SELECT CAST(t1.column_value AS NUMBER) id_documentation,
                   t2.column_value flg_type,
                   t3.column_value desc_doc_component,
                   CAST(t4.column_value AS NUMBER) id_doc_area
              FROM (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_area_component_all(1))) t1,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_area_component_all(2))) t2,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_area_component_all(3))) t3,
                   (SELECT rownum rnum, column_value
                      FROM TABLE(l_doc_area_component_all(4))) t4
             WHERE t1.rnum = t2.rnum
               AND t1.rnum = t3.rnum
               AND t1.rnum = t4.rnum;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_BLOCK_DOCUMENTATION',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_doc_reg);
            pk_types.open_my_cursor(o_doc_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
    END;

    -----------------------------------------------------------
    -----------------------------------------------------------
    PROCEDURE l_____________(i_lang IN language.id_language%TYPE) IS
    BEGIN
        dbms_output.put_line(i_lang);
    END;

    /********************************************************************************************
    * returns simple text blocks for medication
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_rm -- Reported Medication
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error       := 'CALL pk_api_pfh_clindoc_in.get_cur_med_desc';
        o_simple_text := pk_api_pfh_clindoc_in.get_cur_med_desc(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_patient     => i_patient,
                                                                i_episode     => i_episode,
                                                                i_id_workflow => table_number_id(pk_api_pfh_clindoc_in.wf_report));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_RM',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns simple text blocks for Vital Signs
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_vs -- Vital Signs
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cursor_param table_table_varchar := table_table_varchar();
        c_out_data     pk_types.cursor_type;
    
    BEGIN
        o_simple_text := table_varchar();
        l_cursor_param.extend(3);
    
        -- get area data
        g_error := 'CALL get_epis_vs_all';
        IF NOT pk_progress_notes.get_epis_vs_all(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_episode => i_episode,
                                                 i_order   => 'N',
                                                 o_vs_data => c_out_data,
                                                 o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- fetch c_out_data
        g_error := 'FETCH c_out_data';
        FETCH c_out_data BULK COLLECT
            INTO l_cursor_param(1), l_cursor_param(2), l_cursor_param(3);
        CLOSE c_out_data;
    
        IF l_cursor_param(1).count != 0
        THEN
            FOR idx IN l_cursor_param(1).first .. l_cursor_param(1).last
            LOOP
                o_simple_text.extend;
                o_simple_text(o_simple_text.last) := l_cursor_param(1) (idx);
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_VS',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns simple text blocks for Exams
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_e -- Exams
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cursor_param table_table_varchar := table_table_varchar();
        c_out_data     pk_types.cursor_type;
    
    BEGIN
        o_simple_text := table_varchar();
        l_cursor_param.extend(8);
    
        -- get area data
        g_error := 'CALL pk_exams_external_api_db.get_exam_result_list';
        IF NOT pk_exams_external_api_db.get_exam_result_list(i_lang    => i_lang,
                                                             i_prof    => i_prof,
                                                             i_patient => i_patient,
                                                             i_episode => i_episode,
                                                             o_list    => c_out_data,
                                                             o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- fetch c_out_data
        g_error := 'FETCH c_out_data';
        FETCH c_out_data BULK COLLECT
            INTO l_cursor_param(1),
                 l_cursor_param(2),
                 l_cursor_param(3),
                 l_cursor_param(4), --
                 l_cursor_param(5),
                 l_cursor_param(6),
                 l_cursor_param(7),
                 l_cursor_param(8);
        CLOSE c_out_data;
    
        IF l_cursor_param(1).count != 0
        THEN
            FOR idx IN l_cursor_param(1).first .. l_cursor_param(1).last
            LOOP
                o_simple_text.extend;
                o_simple_text(o_simple_text.last) := l_cursor_param(5) (idx) --
                                                     || ': ' || nvl(l_cursor_param(6) (idx), '--');
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_E',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns simple text blocks for Analysis
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_a -- Analysis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_data table_varchar := table_varchar();
    
    BEGIN
        o_simple_text := table_varchar();
    
        -- get area data
        g_error := 'Analysis - pk_lab_tests_external_api_db.get_lab_test_result_list';
        l_data  := pk_lab_tests_external_api_db.get_lab_test_result_list(i_lang    => i_lang,
                                                                         i_prof    => i_prof,
                                                                         i_episode => i_episode);
    
        IF l_data IS NOT NULL
           AND l_data.count > 0
        THEN
            o_simple_text.extend(l_data.count);
        
            FOR i IN l_data.first .. l_data.last
            LOOP
                o_simple_text(i) := pk_string_utils.clob_to_sqlvarchar2(i_clob => to_clob(l_data(i)));
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_A',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns simple text blocks for Problems
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_p -- Problems
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cursor_param table_table_varchar := table_table_varchar();
    
        c_problem_allergy pk_types.cursor_type;
        c_problem_habit   pk_types.cursor_type;
        c_problem_relev   pk_types.cursor_type;
        c_problem_diag    pk_types.cursor_type;
        c_problem_problem pk_types.cursor_type;
        l_new_problem     VARCHAR2(1 CHAR);
        l_edited_problem  VARCHAR2(1 CHAR);
    
    BEGIN
        o_simple_text := table_varchar();
        l_cursor_param.extend(11);
    
        -- get area data
        g_error := 'Problems pk_problems.get_pat_problem_epis_stat';
        IF NOT pk_problems.get_pat_problem_epis_stat(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_episode      => i_episode,
                                                     o_problem_allergy => c_problem_allergy,
                                                     o_problem_habit   => c_problem_habit,
                                                     o_problem_relev   => c_problem_relev,
                                                     o_problem_diag    => c_problem_diag,
                                                     o_problem_problem => c_problem_problem,
                                                     o_new_problem     => l_new_problem,
                                                     o_edited_problem  => l_edited_problem,
                                                     o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        ------ allergy
        FETCH c_problem_allergy BULK COLLECT
            INTO l_cursor_param(1),
                 l_cursor_param(2),
                 l_cursor_param(3),
                 l_cursor_param(4), --
                 l_cursor_param(5),
                 l_cursor_param(6),
                 l_cursor_param(7),
                 l_cursor_param(8), --
                 l_cursor_param(9),
                 l_cursor_param(10),
                 l_cursor_param(11);
        CLOSE c_problem_allergy;
    
        o_simple_text := o_simple_text MULTISET UNION DISTINCT l_cursor_param(11);
    
        ------ habit
        FETCH c_problem_habit BULK COLLECT
            INTO l_cursor_param(1),
                 l_cursor_param(2),
                 l_cursor_param(3),
                 l_cursor_param(4), --
                 l_cursor_param(5),
                 l_cursor_param(6),
                 l_cursor_param(7),
                 l_cursor_param(8), --
                 l_cursor_param(9),
                 l_cursor_param(10),
                 l_cursor_param(11);
        CLOSE c_problem_habit;
    
        o_simple_text := o_simple_text MULTISET UNION DISTINCT l_cursor_param(11);
    
        ------ relev
        FETCH c_problem_relev BULK COLLECT
            INTO l_cursor_param(1),
                 l_cursor_param(2),
                 l_cursor_param(3),
                 l_cursor_param(4), --
                 l_cursor_param(5),
                 l_cursor_param(6),
                 l_cursor_param(7),
                 l_cursor_param(8), --
                 l_cursor_param(9),
                 l_cursor_param(10),
                 l_cursor_param(11);
        CLOSE c_problem_relev;
    
        o_simple_text := o_simple_text MULTISET UNION DISTINCT l_cursor_param(11);
    
        ------ diag
        FETCH c_problem_diag BULK COLLECT
            INTO l_cursor_param(1),
                 l_cursor_param(2),
                 l_cursor_param(3),
                 l_cursor_param(4), --
                 l_cursor_param(5),
                 l_cursor_param(6),
                 l_cursor_param(7),
                 l_cursor_param(8), --
                 l_cursor_param(9),
                 l_cursor_param(10),
                 l_cursor_param(11);
        CLOSE c_problem_diag;
    
        o_simple_text := o_simple_text MULTISET UNION DISTINCT l_cursor_param(11);
    
        ------ problem
        FETCH c_problem_problem BULK COLLECT
            INTO l_cursor_param(1),
                 l_cursor_param(2),
                 l_cursor_param(3),
                 l_cursor_param(4), --
                 l_cursor_param(5),
                 l_cursor_param(6),
                 l_cursor_param(7),
                 l_cursor_param(8), --
                 l_cursor_param(9),
                 l_cursor_param(10),
                 l_cursor_param(11);
        CLOSE c_problem_problem;
    
        o_simple_text := o_simple_text MULTISET UNION DISTINCT l_cursor_param(11);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_P',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns simple text blocks for Diagnosis
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_d -- Diagnosis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cursor       pk_edis_types.diagnosis_cur;
        l_data         pk_edis_types.t_coll_diagnosis;
        l_gen_nt_title sys_message.desc_message%TYPE;
    BEGIN
        o_simple_text := table_varchar();
    
        -- get area data
        g_error := 'CALL pk_diagnosis.get_epis_diagnosis_list';
        IF NOT pk_diagnosis.get_epis_diagnosis_list(i_lang     => i_lang,
                                                    i_prof     => i_prof,
                                                    i_episode  => i_episode,
                                                    i_flg_type => pk_diagnosis.g_diag_type_p,
                                                    o_list     => l_cursor,
                                                    o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH l_cursor';
        FETCH l_cursor BULK COLLECT
            INTO l_data;
        CLOSE l_cursor;
    
        IF l_data IS NULL
           OR l_data.count < 1
        THEN
            NULL;
        ELSE
            FOR i IN l_data.first .. l_data.last
            LOOP
                IF l_data(i).status_diagnosis IN
                    (pk_alert_constant.g_epis_diag_flg_status_f, pk_alert_constant.g_epis_diag_flg_status_d)
                THEN
                    o_simple_text.extend;
                    o_simple_text(o_simple_text.last) := '<b>' || l_data(i).desc_diagnosis || '</b>' || ': ' || l_data(i).desc_status || '.';
                
                    -- add general notes
                    IF l_data(i).general_notes IS NOT NULL
                    THEN
                        -- retrieve title only once, if needed
                        IF l_gen_nt_title IS NULL
                        THEN
                            l_gen_nt_title := pk_message.get_message(i_lang      => i_lang,
                                                                     i_prof      => i_prof,
                                                                     i_code_mess => 'PN_M030') || ' ';
                        END IF;
                        o_simple_text(o_simple_text.last) := o_simple_text(o_simple_text.last) || ' ' || l_gen_nt_title || l_data(i).general_notes || '.';
                    END IF;
                
                    -- add specific notes
                    IF l_data(i).notes IS NOT NULL
                    THEN
                        o_simple_text(o_simple_text.last) := o_simple_text(o_simple_text.last) || ' ' || l_data(i).notes || '.';
                    END IF;
                END IF;
            
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_D',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns simple text blocks for Medication for Current Episode
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_mce -- Medication for Current Episode
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error       := 'CALL pk_api_pfh_clindoc_in.get_cur_med_desc';
        o_simple_text := pk_api_pfh_clindoc_in.get_cur_med_desc(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_patient     => i_patient,
                                                                i_episode     => i_episode,
                                                                i_id_workflow => table_number_id(pk_api_pfh_clindoc_in.wf_institution,
                                                                                                 pk_api_pfh_in.g_wf_iv));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_MCE',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns simple text blocks for Medication for Exterior
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    17/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_me -- Medication for Exterior
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error       := 'CALL pk_api_pfh_clindoc_in.get_cur_med_desc';
        o_simple_text := pk_api_pfh_clindoc_in.get_cur_med_desc(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_patient     => i_patient,
                                                                i_episode     => i_episode,
                                                                i_id_workflow => table_number_id(pk_api_pfh_clindoc_in.wf_ambulatory));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_ME',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns simple text blocks for Guidelines and Protocols
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_gp -- Guidelines and Protocols
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cursor_param table_varchar := table_varchar();
        c_out_data     pk_types.cursor_type;
    
    BEGIN
        o_simple_text := table_varchar();
    
        -- get area data
        g_error := 'CALL pk_api_guidelines.get_guidprot_progress_notes';
        IF NOT pk_api_guidelines.get_guidprot_progress_notes(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_patient  => i_patient,
                                                             i_episode  => i_episode,
                                                             o_guidprot => c_out_data,
                                                             o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- fetch c_out_data
        g_error := 'FETCH c_out_data';
        FETCH c_out_data BULK COLLECT
            INTO l_cursor_param;
        CLOSE c_out_data;
    
        IF l_cursor_param.count != 0
        THEN
            o_simple_text := l_cursor_param;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_GP',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns simple text blocks for Care Plans
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_cp -- Care Plans
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cursor_param table_table_varchar := table_table_varchar();
        c_out_data     pk_types.cursor_type;
    
    BEGIN
        o_simple_text := table_varchar();
        l_cursor_param.extend(3);
    
        -- get area data
        g_error := 'Care Plans - pk_care_plans_api_db.get_care_plan_summary';
        IF NOT pk_care_plans_api_db.get_care_plan_summary(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_patient   => i_patient,
                                                          o_care_plan => c_out_data,
                                                          o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- fetch c_out_data
        g_error := 'FETCH c_out_data';
        FETCH c_out_data BULK COLLECT
            INTO l_cursor_param(1), l_cursor_param(2), l_cursor_param(3);
        CLOSE c_out_data;
    
        IF l_cursor_param(1).count != 0
        THEN
            FOR idx IN l_cursor_param(1).first .. l_cursor_param(1).last
            LOOP
                o_simple_text.extend;
                o_simple_text(o_simple_text.last) := l_cursor_param(2) (idx) || ' (' || l_cursor_param(3) (idx) || ')';
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_CP',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns simple text blocks for Patient Instructions
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_pi -- Patient Instructions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cursor_param table_varchar := table_varchar();
        c_out_data     pk_types.cursor_type;
    
    BEGIN
        o_simple_text := table_varchar();
    
        -- get area data
        g_error := 'Patient instructions - pk_discharge.get_printed_dis_notes';
        IF NOT pk_discharge.get_printed_dis_notes(i_lang  => i_lang,
                                                  i_prof  => i_prof,
                                                  i_epis  => i_episode,
                                                  o_notes => c_out_data,
                                                  o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- fetch c_out_data
        g_error := 'FETCH c_out_data';
        FETCH c_out_data BULK COLLECT
            INTO l_cursor_param;
        CLOSE c_out_data;
    
        IF l_cursor_param.count != 0
        THEN
            o_simple_text := l_cursor_param;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_PI',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /**
    * Get data for lab tests requests simple text block.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_simple_text  procedures data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/12
    */
    FUNCTION get_simpletext_lab_req
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_lab_code CONSTANT translation.code_translation%TYPE := 'ANALYSIS.CODE_ANALYSIS.';
        l_desc table_varchar := table_varchar();
    BEGIN
        -- inits
        o_simple_text := table_varchar();
    
        g_error := 'SELECT l_desc';
        SELECT pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', l_lab_code || lab.id_analysis, NULL) desc_info
          BULK COLLECT
          INTO l_desc
          FROM (SELECT DISTINCT id_analysis
                  FROM (SELECT lte.id_analysis
                          FROM lab_tests_ea lte
                          JOIN analysis_req_det ard
                            ON lte.id_analysis_req_det = ard.id_analysis_req_det
                         WHERE ard.id_episode_origin = i_episode
                           AND lte.id_analysis_result IS NULL
                           AND lte.flg_status_det != pk_lab_tests_constant.g_analysis_cancel
                        UNION ALL
                        SELECT lte.id_analysis
                          FROM lab_tests_ea lte
                         WHERE lte.id_episode = i_episode
                           AND lte.id_analysis_result IS NULL
                           AND lte.flg_status_det != pk_lab_tests_constant.g_analysis_cancel)) lab
         ORDER BY desc_info;
    
        IF l_desc IS NOT NULL
           AND l_desc.count > 0
        THEN
            o_simple_text := table_varchar('<br><b>' ||
                                           pk_message.get_message(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_code_mess => 'PROGRESS_NOTES_T069') || '</b>');
            o_simple_text := o_simple_text MULTISET UNION DISTINCT l_desc;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_LAB_REQ',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_simpletext_lab_req;

    /**
    * Get data for imaging exam requests simple text block.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_simple_text  imaging exam requests data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/15
    */
    FUNCTION get_simpletext_img_exam
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc table_varchar := table_varchar();
    BEGIN
        -- inits
        o_simple_text := table_varchar();
    
        g_error := 'OPEN c_exam';
        OPEN c_exam(i_lang     => i_lang,
                    i_prof     => i_prof,
                    i_episode  => i_episode,
                    i_flg_type => pk_exam_constant.g_type_img);
        FETCH c_exam BULK COLLECT
            INTO l_desc;
        CLOSE c_exam;
    
        IF l_desc IS NOT NULL
           AND l_desc.count > 0
        THEN
            o_simple_text := table_varchar('<br><b>' ||
                                           pk_message.get_message(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_code_mess => 'PROGRESS_NOTES_T070') || '</b>');
            o_simple_text := o_simple_text MULTISET UNION DISTINCT l_desc;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_IMG_EXAM',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_simpletext_img_exam;

    /**
    * Get data for other exam requests simple text block.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_simple_text  other exam requests data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/15
    */
    FUNCTION get_simpletext_oth_exam
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc table_varchar := table_varchar();
    BEGIN
        -- inits
        o_simple_text := table_varchar();
    
        g_error := 'OPEN c_exam';
        OPEN c_exam(i_lang     => i_lang,
                    i_prof     => i_prof,
                    i_episode  => i_episode,
                    i_flg_type => pk_exam_constant.g_type_exm);
        FETCH c_exam BULK COLLECT
            INTO l_desc;
        CLOSE c_exam;
    
        IF l_desc IS NOT NULL
           AND l_desc.count > 0
        THEN
            o_simple_text := table_varchar('<br><b>' ||
                                           pk_message.get_message(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_code_mess => 'PROGRESS_NOTES_T071') || '</b>');
            o_simple_text := o_simple_text MULTISET UNION DISTINCT l_desc;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_OTH_EXAM',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_simpletext_oth_exam;

    /**
    * Get data for procedures simple text block
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_simple_text  procedures data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/04
    */
    FUNCTION get_simpletext_proc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_proc_cursor pk_types.cursor_type;
        l_desc        table_varchar := table_varchar();
        l_prof        table_number := table_number();
        l_date        table_timestamp_tz := table_timestamp_tz();
    BEGIN
        -- inits
        o_simple_text := table_varchar();
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.GET_PROCEDURE_IN_EPISODE';
        IF NOT pk_procedures_external_api_db.get_procedure_in_episode(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_episode => i_episode,
                                                                      i_order   => 'N',
                                                                      o_list    => l_proc_cursor,
                                                                      o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH l_proc_cursor';
        FETCH l_proc_cursor BULK COLLECT
            INTO l_desc, l_prof, l_date;
        CLOSE l_proc_cursor;
    
        IF l_desc.count > 0
        THEN
            o_simple_text := table_varchar('<br><b>' ||
                                           pk_message.get_message(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_code_mess => 'PROGRESS_NOTES_T072') || '</b>');
            o_simple_text := o_simple_text MULTISET UNION DISTINCT l_desc;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_PROC',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_simpletext_proc;

    /**
    * Get data for patient education simple text block.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_simple_text  patient education data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/15
    */
    FUNCTION get_simpletext_pat_edu
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc table_varchar := table_varchar();
    BEGIN
        -- inits
        o_simple_text := table_varchar();
    
        g_error := 'SELECT l_desc';
        SELECT pk_translation.get_translation(i_lang, ntt.code_nurse_tea_topic) desc_info
          BULK COLLECT
          INTO l_desc
          FROM nurse_tea_req ntr
          JOIN nurse_tea_topic ntt
            ON ntr.id_nurse_tea_topic = ntt.id_nurse_tea_topic
         WHERE ntr.id_episode = i_episode
           AND ntr.flg_status NOT IN
               (pk_patient_education_constant.g_nurse_tea_req_canc, pk_patient_education_constant.g_nurse_tea_req_sug)
         ORDER BY desc_info;
    
        IF l_desc IS NOT NULL
           AND l_desc.count > 0
        THEN
            o_simple_text := table_varchar('<br><b>' ||
                                           pk_message.get_message(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_code_mess => 'PROGRESS_NOTES_T075') || '</b>');
            o_simple_text := o_simple_text MULTISET UNION DISTINCT l_desc;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_PAT_EDU',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_simpletext_pat_edu;

    /********************************************************************************************
    * returns simple text blocks for Means for Complementary Diagnosis
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_mcd -- Means for Complementary Diagnosis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cursor_param table_varchar := table_varchar();
    BEGIN
        o_simple_text := table_varchar();
    
        ------ ANALYSIS
        l_cursor_param := table_varchar();
    
        g_error := 'CALL get_simpletext_lab_req';
        IF NOT get_simpletext_lab_req(i_lang        => i_lang,
                                      i_prof        => i_prof,
                                      i_episode     => i_episode,
                                      o_simple_text => l_cursor_param,
                                      o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_cursor_param.count != 0
        THEN
            o_simple_text := o_simple_text MULTISET UNION DISTINCT l_cursor_param;
        END IF;
    
        ------ EXAMS
        l_cursor_param := table_varchar();
    
        g_error := 'CALL get_simpletext_img_exam';
        IF NOT get_simpletext_img_exam(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       i_episode     => i_episode,
                                       o_simple_text => l_cursor_param,
                                       o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_cursor_param.count != 0
        THEN
            o_simple_text := o_simple_text MULTISET UNION DISTINCT l_cursor_param;
        END IF;
    
        ------ OTHER EXAMS
        l_cursor_param := table_varchar();
    
        g_error := 'CALL get_simpletext_oth_exam';
        IF NOT get_simpletext_oth_exam(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       i_episode     => i_episode,
                                       o_simple_text => l_cursor_param,
                                       o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_cursor_param.count != 0
        THEN
            o_simple_text := o_simple_text MULTISET UNION DISTINCT l_cursor_param;
        END IF;
    
        ------ PROCEDURES
        l_cursor_param := table_varchar();
    
        g_error := 'CALL get_simpletext_proc';
        IF NOT get_simpletext_proc(i_lang        => i_lang,
                                   i_prof        => i_prof,
                                   i_episode     => i_episode,
                                   o_simple_text => l_cursor_param,
                                   o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_cursor_param.count != 0
        THEN
            o_simple_text := o_simple_text MULTISET UNION DISTINCT l_cursor_param;
        END IF;
    
        ------ NURSE
        l_cursor_param := table_varchar();
    
        g_error := 'CALL get_simpletext_pat_edu';
        IF NOT get_simpletext_pat_edu(i_lang        => i_lang,
                                      i_prof        => i_prof,
                                      i_episode     => i_episode,
                                      o_simple_text => l_cursor_param,
                                      o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_cursor_param.count != 0
        THEN
            o_simple_text := o_simple_text MULTISET UNION DISTINCT l_cursor_param;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_MCD',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns simple text blocks for Dictaphone
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_prof        Professional ID
    * @param IN   i_patient     Patient ID
    * @param IN   i_episode     Espisode ID
    *
    * @param OUT  o_simple_text Corresponding Simple Text block
    * @param OUT  o_error       Error structure
    *
    * @author                   Pedro Teixeira
    * @since                    20/09/2010
    ********************************************************************************************/
    FUNCTION get_simpletext_di -- Dictaphone
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cursor_param table_varchar := table_varchar();
        c_out_data     pk_types.cursor_type;
    
        l_size_text  VARCHAR2(4 CHAR) := '"17"';
        l_size_prof  VARCHAR2(4 CHAR) := '"15"';
        l_color_prof VARCHAR2(6 CHAR) := '3c3c32';
    
    BEGIN
        o_simple_text := table_varchar();
    
        -- get area data
        g_error := 'GET CURSOR c_out_data';
        OPEN c_out_data FOR
            SELECT '<br><FONT size=' || l_size_text || '><b>' ||
                   nvl2(pk_translation.get_translation(i_lang, wt.code_work_type),
                        pk_translation.get_translation(i_lang, wt.code_work_type) || ' - ',
                        '') || pk_sysdomain.get_domain('DICTATION_REPORT.REPORT_STATUS', dr.report_status, i_lang) ||
                   '</b>' || --<br>' || REPLACE(REPLACE(dr.report_information, '<', chr(38) || 'lt;'), '>', chr(38) || 'gt;') ||
                    '</FONT>' || --<br>' ||
                   nvl2(dr.id_prof_dictated,
                        '<br><FONT size=' || l_size_prof || ' COLOR="#' || l_color_prof || '"><i>' ||
                        pk_message.get_message(i_lang, 'DICTATION_REPORT_001') || ': ' ||
                        nvl2(dr.dictated_date,
                             pk_date_utils.date_char_tsz(i_lang, dr.dictated_date, i_prof.institution, i_prof.software) ||
                             ' / ',
                             '') || pk_prof_utils.get_name_signature(i_lang, i_prof, dr.id_prof_dictated) ||
                        nvl2(pk_prof_utils.get_spec_signature(i_lang,
                                                              i_prof,
                                                              dr.id_prof_dictated,
                                                              dr.last_update_date,
                                                              dr.id_episode),
                             ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      dr.id_prof_dictated,
                                                                      dr.last_update_date,
                                                                      dr.id_episode) || ')',
                             '') || '</i></FONT>',
                        '') ||
                   nvl2(dr.id_prof_transcribed,
                        '<br><FONT size=' || l_size_prof || ' COLOR="#' || l_color_prof || '"><i>' ||
                        pk_message.get_message(i_lang, 'DICTATION_REPORT_002') || ': ' ||
                        nvl2(dr.transcribed_date,
                             pk_date_utils.date_char_tsz(i_lang, dr.transcribed_date, i_prof.institution, i_prof.software) ||
                             ' / ',
                             '') || pk_prof_utils.get_name_signature(i_lang, i_prof, dr.id_prof_transcribed) ||
                        nvl2(pk_prof_utils.get_spec_signature(i_lang,
                                                              i_prof,
                                                              dr.id_prof_transcribed,
                                                              dr.last_update_date,
                                                              dr.id_episode),
                             ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      dr.id_prof_transcribed,
                                                                      dr.last_update_date,
                                                                      dr.id_episode) || ')',
                             '') || '</i></FONT>',
                        '') ||
                   nvl2(dr.id_prof_signoff,
                        '<br><FONT size=' || l_size_prof || ' COLOR="#' || l_color_prof || '"><i>' ||
                        pk_message.get_message(i_lang, 'DICTATION_REPORT_003') || ': ' ||
                        nvl2(dr.signoff_date,
                             pk_date_utils.date_char_tsz(i_lang, dr.signoff_date, i_prof.institution, i_prof.software) ||
                             ' / ',
                             '') || pk_prof_utils.get_name_signature(i_lang, i_prof, dr.id_prof_signoff) ||
                        nvl2(pk_prof_utils.get_spec_signature(i_lang,
                                                              i_prof,
                                                              dr.id_prof_signoff,
                                                              dr.last_update_date,
                                                              dr.id_episode),
                             ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      dr.id_prof_signoff,
                                                                      dr.last_update_date,
                                                                      dr.id_episode) || ')',
                             '') || '</i></FONT>',
                        '') desc_info
              FROM dictation_report dr, work_type wt
             WHERE dr.id_episode = i_episode
               AND wt.id_work_type(+) = dr.id_work_type
               AND dr.id_work_type = pk_progress_notes.g_dictation_area_plan
             ORDER BY last_update_date DESC;
    
        -- fetch c_out_data
        g_error := 'FETCH c_out_data';
        FETCH c_out_data BULK COLLECT
            INTO l_cursor_param;
        CLOSE c_out_data;
    
        IF l_cursor_param.count != 0
        THEN
            o_simple_text := l_cursor_param;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_PI',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /**
    * Returns dictaphone simple text block data (long version).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_simple_text  block data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/11
    */
    FUNCTION get_simpletext_dih
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cursor_param table_varchar := table_varchar();
        c_out_data     pk_types.cursor_type;
    
        l_size_text  VARCHAR2(4 CHAR) := '"17"';
        l_size_prof  VARCHAR2(4 CHAR) := '"15"';
        l_color_prof VARCHAR2(6 CHAR) := '3c3c32';
    BEGIN
        o_simple_text := table_varchar();
    
        -- get area data
        g_error := 'GET CURSOR c_out_data';
        OPEN c_out_data FOR
            SELECT '<br><FONT size=' || l_size_text || '><b>' ||
                   nvl2(pk_translation.get_translation(i_lang, wt.code_work_type),
                        pk_translation.get_translation(i_lang, wt.code_work_type) || ' - ',
                        '') || pk_sysdomain.get_domain('DICTATION_REPORT.REPORT_STATUS', dr.report_status, i_lang) ||
                   '</b><br>' || REPLACE(REPLACE(dr.report_information, '<', chr(38) || 'lt;'), '>', chr(38) || 'gt;') ||
                   '</FONT><br>' ||
                   nvl2(dr.id_prof_dictated,
                        '<br><FONT size=' || l_size_prof || ' COLOR="#' || l_color_prof || '"><i>' ||
                        pk_message.get_message(i_lang, 'DICTATION_REPORT_001') || ': ' ||
                        nvl2(dr.dictated_date,
                             pk_date_utils.date_char_tsz(i_lang, dr.dictated_date, i_prof.institution, i_prof.software) ||
                             ' / ',
                             '') || pk_prof_utils.get_name_signature(i_lang, i_prof, dr.id_prof_dictated) ||
                        nvl2(pk_prof_utils.get_spec_signature(i_lang,
                                                              i_prof,
                                                              dr.id_prof_dictated,
                                                              dr.last_update_date,
                                                              dr.id_episode),
                             ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      dr.id_prof_dictated,
                                                                      dr.last_update_date,
                                                                      dr.id_episode) || ')',
                             '') || '</i></FONT>',
                        '') ||
                   nvl2(dr.id_prof_transcribed,
                        '<br><FONT size=' || l_size_prof || ' COLOR="#' || l_color_prof || '"><i>' ||
                        pk_message.get_message(i_lang, 'DICTATION_REPORT_002') || ': ' ||
                        nvl2(dr.transcribed_date,
                             pk_date_utils.date_char_tsz(i_lang, dr.transcribed_date, i_prof.institution, i_prof.software) ||
                             ' / ',
                             '') || pk_prof_utils.get_name_signature(i_lang, i_prof, dr.id_prof_transcribed) ||
                        nvl2(pk_prof_utils.get_spec_signature(i_lang,
                                                              i_prof,
                                                              dr.id_prof_transcribed,
                                                              dr.last_update_date,
                                                              dr.id_episode),
                             ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      dr.id_prof_transcribed,
                                                                      dr.last_update_date,
                                                                      dr.id_episode) || ')',
                             '') || '</i></FONT>',
                        '') ||
                   nvl2(dr.id_prof_signoff,
                        '<br><FONT size=' || l_size_prof || ' COLOR="#' || l_color_prof || '"><i>' ||
                        pk_message.get_message(i_lang, 'DICTATION_REPORT_003') || ': ' ||
                        nvl2(dr.signoff_date,
                             pk_date_utils.date_char_tsz(i_lang, dr.signoff_date, i_prof.institution, i_prof.software) ||
                             ' / ',
                             '') || pk_prof_utils.get_name_signature(i_lang, i_prof, dr.id_prof_signoff) ||
                        nvl2(pk_prof_utils.get_spec_signature(i_lang,
                                                              i_prof,
                                                              dr.id_prof_signoff,
                                                              dr.last_update_date,
                                                              dr.id_episode),
                             ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      dr.id_prof_signoff,
                                                                      dr.last_update_date,
                                                                      dr.id_episode) || ')',
                             '') || '</i></FONT>',
                        '') desc_info
              FROM dictation_report dr, work_type wt
             WHERE dr.id_episode = i_episode
               AND wt.id_work_type(+) = dr.id_work_type
               AND dr.id_work_type = pk_progress_notes.g_dictation_area_plan
             ORDER BY last_update_date DESC;
    
        -- fetch c_out_data
        g_error := 'FETCH c_out_data';
        FETCH c_out_data BULK COLLECT
            INTO l_cursor_param;
        CLOSE c_out_data;
    
        IF l_cursor_param.count != 0
        THEN
            o_simple_text := l_cursor_param;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_DIH',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_simpletext_dih;

    /**
    * Returns schedule reason simple text block data.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_simple_text  block data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.8.4
    * @since                2012/06/11
    */
    FUNCTION get_simpletext_sr
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_schedule epis_info.id_schedule%TYPE;
        l_reason   schedule.reason_notes%TYPE;
    
        CURSOR c_sched IS
            SELECT ei.id_schedule
              FROM epis_info ei
             WHERE ei.id_episode = i_episode;
    BEGIN
        OPEN c_sched;
        FETCH c_sched
            INTO l_schedule;
        CLOSE c_sched;
    
        -- null is passed as episode, as only schedule reason is needed
        g_error  := 'CALL pk_clinical_info.get_epis_reason_for_visit';
        l_reason := pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang        => i_lang,
                                                                                                i_prof        => i_prof,
                                                                                                i_id_episode  => NULL,
                                                                                                i_id_schedule => l_schedule),
                                                     4000);
    
        IF l_reason IS NULL
        THEN
            o_simple_text := table_varchar();
        ELSE
            o_simple_text := table_varchar(l_reason);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_SR',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_simpletext_sr;
    /**
    * Returns schedule reason simple text block data.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_simple_text  block data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.8.4
    * @since                2012/06/11
    */
    FUNCTION get_simpletext_gn
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_notes table_varchar := table_varchar();
    BEGIN
        g_error := 'get group notes';
        SELECT gn.notes desc_info
          BULK COLLECT
          INTO l_notes
          FROM group_note gn
          JOIN pat_group_note pgn
            ON pgn.id_group_note = gn.id_group_note
         WHERE pgn.id_patient = i_patient
           AND pgn.id_episode = i_episode
           AND pgn.flg_active = pk_alert_constant.g_yes;
    
        o_simple_text := l_notes;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_GN',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_simpletext_gn;

    /**
    * Returns the CITS: Medical disability certificate information.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_simple_text  block data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.3.6
    * @since                01-06-2013
    */
    FUNCTION get_simpletext_ct
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_simple_text OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_notes table_varchar := table_varchar();
        l_dummy table_varchar := table_varchar();
    BEGIN
        g_error := 'CALL get_cits_by_patient';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_cit.get_cits_by_patient(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_id_patient      => i_patient,
                                          i_id_episode      => i_episode,
                                          i_excluded_status => table_varchar(pk_cit.g_flg_status_canceled,
                                                                             pk_cit.g_flg_status_concluded,
                                                                             pk_cit.g_flg_status_expired),
                                          i_use_html_format => pk_alert_constant.g_yes,
                                          o_cit_desc        => l_notes,
                                          o_cit_title       => l_dummy,
                                          o_signature       => l_dummy,
                                          o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        o_simple_text := l_notes;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SIMPLETEXT_CT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_simpletext_ct;

    /**
    * Get configured soap and data blocks ordered collection.
    *
    * @param i_prof                logged professional structure
    * @param i_market              market identifier
    * @param i_department          service identifier
    * @param i_dcs                 service/specialty identifier
    * @param i_id_pn_note_type     Note type identifier
    * @param i_id_episode          Episode identifier
    * @param i_id_pn_data_block    Data Block Identifier
    * @param i_software            Software ID
    *
    * @return                      configured soap and data blocks ordered collection
    *
    * @author                      Pedro Carneiro
    * @version                     2.6.0.5.2
    * @since                       2011/01/27
    */
    FUNCTION tf_data_blocks
    (
        i_prof             IN profissional,
        i_market           IN market.id_market%TYPE,
        i_department       IN department.id_department%TYPE,
        i_dcs              IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE DEFAULT NULL,
        i_software         IN software.id_software%TYPE,
        i_flg_search       IN table_varchar DEFAULT NULL
    ) RETURN t_coll_dblock IS
        l_dblocks t_coll_dblock := t_coll_dblock();
    
        l_pat_age    patient.age%TYPE := NULL;
        l_pat_gender patient.gender%TYPE := NULL;
    
        l_general_exception EXCEPTION;
    
        l_id_market        market.id_market%TYPE := i_market;
        l_id_department    department.id_department%TYPE := i_department;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE := i_dcs;
    
        l_id_software_from_prof software.id_software%TYPE := i_software;
    
        l_id_software_cfg      software.id_software%TYPE;
        l_id_department_cfg    department.id_department%TYPE;
        l_id_dep_clin_serv_cfg dep_clin_serv.id_dep_clin_serv%TYPE;
        l_search               VARCHAR2(1 CHAR);
        l_pat_age_months       NUMBER;
        l_id_patient           patient.id_patient%TYPE;
    BEGIN
    
        --get patient age and gender and episode software
        IF g_ctx.id_episode IS NULL
           AND i_id_episode IS NULL
        THEN
            g_error := 'It''s mandatory to have an Episode Identifier';
            RAISE l_general_exception;
        ELSE
            IF (i_software IS NULL)
            THEN
                l_id_software_from_prof := i_prof.software;
            END IF;
        
            g_error := 'Call PK_PATIENT.GET_PAT_INFO_BY_EPISODE';
            IF NOT pk_patient.get_pat_info_by_episode(i_lang    => g_ctx.id_lang,
                                                      i_episode => nvl(g_ctx.id_episode, i_id_episode),
                                                      o_gender  => l_pat_gender,
                                                      o_age     => l_pat_age)
            THEN
                RAISE l_general_exception;
            END IF;
            SELECT id_patient
              INTO l_id_patient
              FROM episode
             WHERE id_episode = nvl(g_ctx.id_episode, i_id_episode);
        
            l_pat_age_months := pk_patient.get_pat_age(l_pat_age_months, NULL, NULL, NULL, 'MONTHS', l_id_patient);
        END IF;
    
        IF l_id_department IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            l_id_department := pk_progress_notes_upd.get_department(i_episode => nvl(g_ctx.id_episode, i_id_episode),
                                                                    i_epis_pn => NULL);
        END IF;
    
        IF l_id_dep_clin_serv IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            l_id_dep_clin_serv := pk_progress_notes_upd.get_dep_clin_serv(i_episode => nvl(g_ctx.id_episode,
                                                                                           i_id_episode),
                                                                          i_epis_pn => NULL);
        END IF;
    
        IF (i_flg_search IS NULL OR NOT i_flg_search.exists(1))
        THEN
            l_search := NULL;
        ELSE
            l_search := pk_alert_constant.g_yes;
        END IF;
        BEGIN
            --check the software that should be used to get the data (prof/note software or zero)            
            g_error := 'Get market to filter sblocks id_software: ' || l_id_software_from_prof;
            pk_alertlog.log_debug(g_error);
            SELECT t.id_software, t.id_department, t.id_dep_clin_serv
              INTO l_id_software_cfg, l_id_department_cfg, l_id_dep_clin_serv_cfg
              FROM (SELECT pdsi.id_software,
                           pdsi.id_department,
                           pdsi.id_dep_clin_serv,
                           row_number() over(ORDER BY decode(pdsi.id_software, l_id_software_from_prof, 1, 2), decode(pdsi.id_department, l_id_department, 1, 2), decode(pdsi.id_dep_clin_serv, l_id_dep_clin_serv, 1, 2)) line_number
                      FROM pn_dblock_soft_inst pdsi
                     WHERE pdsi.id_software IN (0, l_id_software_from_prof)
                       AND pdsi.id_department IN (0, l_id_department)
                       AND pdsi.id_dep_clin_serv IN (0, -1, l_id_dep_clin_serv)
                       AND pdsi.id_pn_note_type = nvl(i_id_pn_note_type, pdsi.id_pn_note_type)
                       AND pdsi.flg_available = pk_alert_constant.g_yes
                       AND pdsi.id_institution = i_prof.institution) t
             WHERE line_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_software_cfg      := 0;
                l_id_department_cfg    := 0;
                l_id_dep_clin_serv_cfg := -1;
        END;
    
        g_error := 'SELECT l_dblocks si';
        SELECT t_rec_dblock(t.id_pn_soap_block,
                            t.id_pn_data_block,
                            t.flg_type,
                            t.data_area,
                            t.id_doc_area,
                            t.code_pn_data_block,
                            t.id_department,
                            t.id_dep_clin_serv,
                            t.flg_import,
                            t.flg_select,
                            t.flg_scope,
                            0,
                            flg_actions_available,
                            id_swf_file_viewer,
                            flg_line_on_boxes,
                            gender,
                            age_min,
                            age_max,
                            flg_pregnant,
                            flg_outside_period,
                            days_available_period,
                            flg_mandatory,
                            flg_cp_no_changes_import,
                            flg_import_date,
                            id_sys_button_viewer,
                            flg_group_on_import,
                            rank,
                            flg_wf_viewer,
                            id_pndb_parent,
                            flg_struct_type,
                            flg_show_title,
                            flg_show_sub_title,
                            flg_data_removable,
                            auto_pop_exec_prof_cat,
                            id_summary_page,
                            flg_focus,
                            flg_editable,
                            flg_group_select_filter,
                            id_task_type,
                            t.flg_order_type,
                            t.flg_signature,
                            t.flg_min_value,
                            t.flg_default_value,
                            t.flg_max_value,
                            t.flg_format,
                            t.flg_validation,
                            t.id_pndb_related,
                            t.value_viewer,
                            file_name,
                            file_extension,
                            id_mtos_score,
                            t.min_days_period,
                            t.max_days_period,
                            t.default_days_period,
                            t.flg_exc_sum_page_da,
                            t.flg_group_type,
                            t.desc_function)
          BULK COLLECT
          INTO l_dblocks
          FROM (SELECT si.id_pn_soap_block,
                       pdb.id_pn_data_block,
                       CASE
                            WHEN /*nvl(*/
                             si.id_task_type /*, pdb.id_task_type)*/
                             IS NOT NULL
                             AND pdb.id_pn_data_block NOT IN (pk_prog_notes_constants.g_dblock_handoff_194, 204, 1131) THEN
                             pk_prog_notes_constants.g_dblock_free_text_w_save
                            ELSE
                             pdb.flg_type
                        END flg_type,
                       pdb.data_area,
                       pdb.id_doc_area,
                       decode(pdb.id_pn_data_block, g_data_block_local, si.code_message_title, pdb.code_pn_data_block) code_pn_data_block,
                       si.id_department,
                       si.id_dep_clin_serv,
                       si.flg_import,
                       si.flg_select,
                       si.flg_scope,
                       si.rank,
                       row_number() over(PARTITION BY si.id_pn_soap_block, si.id_pn_data_block ORDER BY si.id_software DESC) rn,
                       si.flg_actions_available,
                       pdb.id_swf_file_viewer,
                       si.flg_line_on_boxes,
                       si.gender,
                       si.age_min,
                       si.age_max,
                       si.flg_pregnant,
                       si.flg_outside_period,
                       si.days_available_period,
                       si.flg_mandatory,
                       si.flg_cp_no_changes_import,
                       si.flg_import_date,
                       pdb.id_sys_button_viewer,
                       si.flg_group_on_import,
                       pdb.flg_wf_viewer,
                       nvl(si.id_pndb_parent, pdb.id_pndb_parent) id_pndb_parent,
                       si.flg_struct_type,
                       si.flg_show_title,
                       si.flg_show_sub_title,
                       si.flg_data_removable,
                       si.auto_pop_exec_prof_cat,
                       pdb.id_summary_page,
                       si.flg_focus,
                       si.flg_editable,
                       si.flg_group_select_filter,
                       si.id_task_type,
                       si.flg_order_type,
                       si.flg_signature,
                       si.flg_min_value,
                       si.flg_default_value,
                       si.flg_max_value,
                       si.flg_format,
                       si.flg_validation,
                       si.id_pndb_related,
                       decode(afm.file_extension, NULL, NULL, si.value_viewer) value_viewer,
                       coalesce(afm.file_name, af.file_name) file_name,
                       af.file_extension,
                       pdb.id_mtos_score,
                       si.min_days_period,
                       si.max_days_period,
                       si.default_days_period,
                       si.flg_exc_sum_page_da,
                       flg_group_type,
                       desc_function
                  FROM pn_data_block pdb
                  JOIN pn_dblock_soft_inst si
                    ON pdb.id_pn_data_block = si.id_pn_data_block
                  LEFT OUTER JOIN application_file afm
                    ON afm.id_application_file = si.id_swf_file_viewer
                  LEFT OUTER JOIN application_file af
                    ON af.id_application_file = pdb.id_swf_file_viewer
                 WHERE pdb.flg_available = pk_alert_constant.g_yes
                   AND si.id_institution = i_prof.institution
                   AND si.id_software = l_id_software_cfg
                   AND si.id_department = l_id_department_cfg
                   AND si.id_dep_clin_serv = l_id_dep_clin_serv_cfg
                   AND si.id_pn_note_type = nvl(i_id_pn_note_type, si.id_pn_note_type)
                   AND si.flg_available = pk_alert_constant.g_yes
                   AND si.id_pn_data_block = nvl(i_id_pn_data_block, si.id_pn_data_block)
                   AND pk_prog_notes_utils.check_pn_with_patient_info(g_ctx.id_lang,
                                                                      si.age_min,
                                                                      si.age_max,
                                                                      si.gender,
                                                                      l_pat_age_months,
                                                                      l_pat_gender) = pk_alert_constant.g_yes
                   AND (l_search IS NULL OR
                       (pk_prog_notes_constants.g_search_template IN
                       (SELECT column_value
                            FROM TABLE(i_flg_search)) AND pdb.flg_type = pk_prog_notes_constants.g_search_template AND
                       (pdb.id_doc_area IS NOT NULL OR pdb.id_summary_page IS NOT NULL) AND
                       l_search = pk_alert_constant.g_yes) OR
                       (pk_prog_notes_constants.g_search_free_text IN
                       (SELECT column_value
                            FROM TABLE(i_flg_search)) AND pdb.flg_type = pk_prog_notes_constants.g_search_free_text AND
                       l_search = pk_alert_constant.g_yes))) t
         WHERE t.rn = 1
         ORDER BY t.id_pn_soap_block, t.rank;
    
        IF l_dblocks.count < 1
        THEN
            IF l_id_market IS NULL
            THEN
                l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
            END IF;
        
            --check the market that should be used to get the data (institution market or zero)
            g_error := 'Get market to filter dblocks l_id_market: ' || l_id_market || ' l_id_software_from_prof: ' ||
                       l_id_software_from_prof || ' i_id_pn_note_type: ' || i_id_pn_note_type;
            pk_alertlog.log_debug(g_error);
            SELECT t.id_market, t.id_software
              INTO l_id_market, l_id_software_cfg
              FROM (SELECT m.id_market,
                           m.id_software,
                           row_number() over(ORDER BY decode(nvl(m.id_market, 0), l_id_market, 1, 2), decode(m.id_software, l_id_software_from_prof, 1, 2)) line_number
                      FROM pn_dblock_mkt m
                     WHERE m.id_software IN (0, l_id_software_from_prof)
                       AND m.id_market IN (0, l_id_market)
                       AND m.id_pn_note_type = nvl(i_id_pn_note_type, m.id_pn_note_type)
                       AND m.id_pn_data_block = nvl(NULL, m.id_pn_data_block)) t
             WHERE line_number = 1;
        
            g_error := 'SELECT l_dblocks m';
            SELECT t_rec_dblock(m.id_pn_soap_block,
                                 pdb.id_pn_data_block,
                                 --pdb.flg_type,
                                 CASE
                                     WHEN /*nvl(*/
                                      m.id_task_type /*, pdb.id_task_type)*/
                                      IS NOT NULL
                                      AND m.id_pn_data_block NOT IN (pk_prog_notes_constants.g_dblock_handoff_194, 204, 1131) THEN
                                      pk_prog_notes_constants.g_dblock_free_text_w_save
                                     ELSE
                                      pdb.flg_type
                                 END,
                                 pdb.data_area,
                                 pdb.id_doc_area,
                                 pdb.code_pn_data_block,
                                 0,
                                 0,
                                 m.flg_import,
                                 m.flg_select,
                                 m.flg_scope,
                                 0,
                                 m.flg_actions_available,
                                 pdb.id_swf_file_viewer,
                                 m.flg_line_on_boxes,
                                 m.gender,
                                 m.age_min,
                                 m.age_max,
                                 m.flg_pregnant,
                                 m.flg_outside_period,
                                 m.days_available_period,
                                 m.flg_mandatory,
                                 m.flg_cp_no_changes_import,
                                 m.flg_import_date,
                                 pdb.id_sys_button_viewer,
                                 m.flg_group_on_import,
                                 m.rank,
                                 pdb.flg_wf_viewer,
                                 nvl(m.id_pndb_parent, pdb.id_pndb_parent),
                                 m.flg_struct_type,
                                 m.flg_show_title,
                                 m.flg_show_sub_title,
                                 m.flg_data_removable,
                                 m.auto_pop_exec_prof_cat,
                                 pdb.id_summary_page,
                                 m.flg_focus,
                                 m.flg_editable,
                                 m.flg_group_select_filter,
                                 m.id_task_type,
                                 m.flg_order_type,
                                 m.flg_signature,
                                 m.flg_min_value,
                                 m.flg_default_value,
                                 m.flg_max_value,
                                 m.flg_format,
                                 m.flg_validation,
                                 m.id_pndb_related,
                                 decode(afm.file_extension, NULL, NULL, m.value_viewer),
                                 coalesce(afm.file_name, af.file_name),
                                 af.file_extension,
                                 pdb.id_mtos_score,
                                 m.min_days_period,
                                 m.max_days_period,
                                 m.default_days_period,
                                 m.flg_exc_sum_page_da,
                                 m.flg_group_type,
                                 m.desc_function)
              BULK COLLECT
              INTO l_dblocks
              FROM pn_data_block pdb
              JOIN pn_dblock_mkt m
                ON pdb.id_pn_data_block = m.id_pn_data_block
              LEFT OUTER JOIN application_file afm
                ON afm.id_application_file = m.id_swf_file_viewer
              LEFT OUTER JOIN application_file af
                ON af.id_application_file = pdb.id_swf_file_viewer
             WHERE pdb.flg_available = pk_alert_constant.g_yes
               AND m.id_software = l_id_software_cfg
               AND m.id_market = l_id_market
               AND m.id_pn_note_type = nvl(i_id_pn_note_type, m.id_pn_note_type)
               AND m.id_pn_data_block = nvl(i_id_pn_data_block, m.id_pn_data_block)
               AND pk_prog_notes_utils.check_pn_with_patient_info(g_ctx.id_lang,
                                                                  m.age_min,
                                                                  m.age_max,
                                                                  m.gender,
                                                                  l_pat_age_months,
                                                                  l_pat_gender) = pk_alert_constant.g_yes
               AND (l_search IS NULL OR
                   (pk_prog_notes_constants.g_search_template IN
                   (SELECT column_value
                        FROM TABLE(i_flg_search)) AND pdb.flg_type = pk_prog_notes_constants.g_search_template AND
                   (pdb.id_doc_area IS NOT NULL OR pdb.id_summary_page IS NOT NULL) AND
                   l_search = pk_alert_constant.g_yes) OR
                   (pk_prog_notes_constants.g_search_free_text IN
                   (SELECT column_value
                        FROM TABLE(i_flg_search)) AND pdb.flg_type = pk_prog_notes_constants.g_search_free_text AND
                   l_search = pk_alert_constant.g_yes))
             ORDER BY m.id_pn_soap_block, m.rank;
        END IF;
    
        RETURN l_dblocks;
    END tf_data_blocks;

    /**
    * Get configured soap and button blocks ordered collection.
    *
    * @param i_prof                logged professional structure
    * @param i_profile             logged professional profile
    * @param i_category            logged professional category
    * @param i_market              market identifier
    * @param i_department          service identifier
    * @param i_dcs                 service/specialty identifier
    * @param i_id_pn_note_type     soap note type identifier
    * @param i_software            Software ID
    *
    * @return                      configured soap and button blocks ordered collection
    *
    * @author                      Pedro Carneiro
    * @version                     2.6.0.5.2
    * @since                       2011/01/27
    */
    FUNCTION tf_button_blocks
    (
        i_prof            IN profissional,
        i_profile         IN profile_template.id_profile_template%TYPE,
        i_category        IN category.id_category%TYPE,
        i_market          IN market.id_market%TYPE,
        i_department      IN department.id_department%TYPE,
        i_dcs             IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_software        IN software.id_software%TYPE
    ) RETURN t_coll_button IS
        l_buttons             t_coll_button := t_coll_button();
        l_check_functionality VARCHAR2(1 CHAR);
        l_id_market           market.id_market%TYPE;
    
        l_general_exception EXCEPTION;
    
        l_id_software_from_prof software.id_software%TYPE := i_software;
    
        l_id_software_cfg      software.id_software%TYPE;
        l_id_department_cfg    department.id_department%TYPE;
        l_id_dep_clin_serv_cfg dep_clin_serv.id_dep_clin_serv%TYPE;
    
        l_pat_age        patient.age%TYPE := NULL;
        l_pat_gender     patient.gender%TYPE := NULL;
        l_pat_age_months NUMBER;
        l_id_patient     patient.id_patient%TYPE;
    BEGIN
        --the buttons should only be returned if the profile is not a read only profile    
        g_error := 'call check_has_functionality function';
        pk_alertlog.log_debug(g_error);
        l_check_functionality := pk_prof_utils.check_has_functionality(i_lang        => NULL,
                                                                       i_prof        => i_prof,
                                                                       i_intern_name => pk_access.g_view_only_profile);
    
        IF (l_check_functionality = pk_alert_constant.g_no)
        THEN
        
            --get software id
            IF i_software IS NULL
            THEN
                l_id_software_from_prof := i_prof.software;
            END IF;
        
            g_error := 'Call PK_PATIENT.GET_PAT_INFO_BY_EPISODE';
            IF NOT pk_patient.get_pat_info_by_episode(i_lang    => g_ctx.id_lang,
                                                      i_episode => g_ctx.id_episode,
                                                      o_gender  => l_pat_gender,
                                                      o_age     => l_pat_age)
            THEN
                RAISE l_general_exception;
            END IF;
            SELECT id_patient
              INTO l_id_patient
              FROM episode
             WHERE id_episode = g_ctx.id_episode;
            l_pat_age_months := pk_patient.get_pat_age(g_ctx.id_lang, NULL, NULL, NULL, 'MONTHS', l_id_patient);
        
            BEGIN
                --check the software that should be used to get the data (prof/note software or zero)            
                g_error := 'Get market to filter sblocks id_software: ' || l_id_software_from_prof;
                pk_alertlog.log_debug(g_error);
                SELECT t.id_software, t.id_department, t.id_dep_clin_serv
                  INTO l_id_software_cfg, l_id_department_cfg, l_id_dep_clin_serv_cfg
                  FROM (SELECT pbsi.id_software,
                               pbsi.id_department,
                               pbsi.id_dep_clin_serv,
                               row_number() over(ORDER BY decode(pbsi.id_software, l_id_software_from_prof, 1, 2), decode(pbsi.id_department, i_department, 1, 2), decode(pbsi.id_dep_clin_serv, i_dcs, 1, 2)) line_number
                          FROM pn_button_soft_inst pbsi
                         WHERE pbsi.id_software IN (0, l_id_software_from_prof)
                           AND pbsi.id_department IN (0, i_department)
                           AND pbsi.id_dep_clin_serv IN (0, -1, i_dcs)
                           AND pbsi.id_pn_note_type = i_id_pn_note_type
                           AND pbsi.flg_available = pk_alert_constant.g_yes
                           AND pbsi.id_institution = i_prof.institution) t
                 WHERE line_number = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_software_cfg      := 0;
                    l_id_department_cfg    := 0;
                    l_id_dep_clin_serv_cfg := -1;
            END;
        
            g_error := 'SELECT l_buttons si';
            pk_alertlog.log_debug(g_error);
            SELECT t_rec_button(t.id_pn_soap_block,
                                t.id_conf_button_block,
                                t.id_doc_area,
                                t.id_task_type,
                                t.action,
                                t.id_parent,
                                t.icon,
                                pk_alert_constant.g_yes,
                                t.id_type,
                                t.rank,
                                t.flg_activation)
              BULK COLLECT
              INTO l_buttons
              FROM (SELECT si.id_pn_soap_block,
                           cbb.id_conf_button_block,
                           cbb.id_doc_area,
                           nvl(si.rank, cbb.rank) rank,
                           cbb.id_task_type,
                           cbb.action,
                           cbb.icon,
                           nvl(si.id_parent, cbb.id_parent) id_parent,
                           cbb.id_type,
                           row_number() over(PARTITION BY si.id_pn_soap_block, si.id_conf_button_block ORDER BY si.id_software DESC) rn,
                           si.flg_activation
                      FROM conf_button_block cbb
                      JOIN pn_button_soft_inst si
                        ON cbb.id_conf_button_block = si.id_conf_button_block
                      JOIN pn_prof_soap_button p
                        ON cbb.id_conf_button_block = p.id_conf_button_block
                     WHERE cbb.flg_available = pk_alert_constant.g_yes
                       AND si.id_institution = i_prof.institution
                       AND si.id_software = l_id_software_cfg
                       AND si.id_department IN (0, l_id_department_cfg)
                       AND si.id_dep_clin_serv IN (-1, l_id_dep_clin_serv_cfg)
                       AND si.id_pn_note_type = i_id_pn_note_type
                       AND si.flg_available = pk_alert_constant.g_yes
                       AND p.id_institution = i_prof.institution
                          
                       AND ((nvl(p.id_software, 0) IN (0, l_id_software_from_prof) AND
                           p.flg_config_type = pk_prog_notes_constants.g_flg_config_type_software_s) OR
                           p.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_software_s)
                       AND ((nvl(p.id_profile_template, 0) IN (0, i_profile) AND
                           p.flg_config_type = pk_prog_notes_constants.g_flg_config_type_proftempl_p) OR
                           p.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_proftempl_p)
                       AND ((nvl(p.id_category, -1) IN (-1, i_category) AND
                           p.flg_config_type = pk_prog_notes_constants.g_flg_config_type_category_c) OR
                           p.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_category_c)
                       AND pk_prog_notes_utils.check_pn_with_patient_info(g_ctx.id_lang,
                                                                          si.age_min,
                                                                          si.age_max,
                                                                          si.gender,
                                                                          l_pat_age_months,
                                                                          l_pat_gender) = pk_alert_constant.g_yes
                    
                    ) t
             WHERE t.rn = 1;
        
            IF l_buttons.count < 1
            THEN
            
                --check the market that should be used to get the data (institution market or zero)            
                g_error := 'Get market to filter buttons i_market: ' || i_market;
                pk_alertlog.log_debug(g_error);
                SELECT t.id_market, t.id_software
                  INTO l_id_market, l_id_software_cfg
                  FROM (SELECT m.id_market,
                               m.id_software,
                               row_number() over(ORDER BY decode(nvl(m.id_market, 0), i_market, 1, 2), decode(m.id_software, l_id_software_from_prof, 1, 2)) line_number
                          FROM pn_button_mkt m
                         WHERE m.id_software IN (0, l_id_software_from_prof)
                           AND m.id_pn_note_type = i_id_pn_note_type
                           AND m.id_market IN (0, i_market)) t
                 WHERE line_number = 1;
            
                g_error := 'SELECT l_buttons m';
                pk_alertlog.log_debug(g_error);
                SELECT t_rec_button(m.id_pn_soap_block,
                                    cbb.id_conf_button_block,
                                    cbb.id_doc_area,
                                    cbb.id_task_type,
                                    cbb.action,
                                    nvl(m.id_parent, cbb.id_parent),
                                    cbb.icon,
                                    pk_alert_constant.g_yes,
                                    cbb.id_type,
                                    nvl(m.rank, cbb.rank),
                                    m.flg_activation)
                  BULK COLLECT
                  INTO l_buttons
                  FROM conf_button_block cbb
                  JOIN pn_button_mkt m
                    ON cbb.id_conf_button_block = m.id_conf_button_block
                  JOIN prof_conf_button_block p
                    ON cbb.id_conf_button_block = p.id_conf_button_block
                 WHERE cbb.flg_available = pk_alert_constant.g_yes
                   AND m.id_software = l_id_software_cfg
                   AND m.id_market = l_id_market
                   AND m.id_pn_note_type = i_id_pn_note_type
                   AND p.id_market IN (l_id_market, i_market, 0)
                   AND ((p.id_software IN (0, l_id_software_from_prof) AND
                       p.flg_config_type = pk_prog_notes_constants.g_flg_config_type_software_s) OR
                       p.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_software_s)
                   AND ((nvl(p.id_profile_template, 0) IN (0, i_profile) AND
                       p.flg_config_type = pk_prog_notes_constants.g_flg_config_type_proftempl_p) OR
                       p.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_proftempl_p)
                   AND ((nvl(p.id_category, -1) IN (-1, i_category) AND
                       p.flg_config_type = pk_prog_notes_constants.g_flg_config_type_category_c) OR
                       p.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_category_c)
                   AND pk_prog_notes_utils.check_pn_with_patient_info(g_ctx.id_lang,
                                                                      m.age_min,
                                                                      m.age_max,
                                                                      m.gender,
                                                                      l_pat_age_months,
                                                                      l_pat_gender) = pk_alert_constant.g_yes
                
                ;
            END IF;
        END IF;
    
        RETURN l_buttons;
    END tf_button_blocks;

    /**
    * Get configured soap blocks ordered collection.
    * Based on tf_soap_blocks, filtering by id_department and id_dep_clin_serv
    *
    * @param i_prof            logged professional structure
    * @param i_id_episode      episode identifier
    * @param i_market          market identifier
    * @param i_department      service identifier
    * @param i_dcs             service/specialty identifier
    * @param i_id_pn_note_type Note type ID
    * @param i_software        Software ID
    *
    * @return               configured soap blocks ordered collection
    *
    * @author               António Neto
    * @version              2.6.1.2
    * @since                03-Aug-2011
    */
    FUNCTION tf_sblock
    (
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_market          IN market.id_market%TYPE,
        i_department      IN department.id_department%TYPE DEFAULT NULL,
        i_dcs             IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_software        IN software.id_software%TYPE
    ) RETURN tab_soap_blocks IS
        l_blocks           tab_soap_blocks := tab_soap_blocks();
        l_id_department    department.id_department%TYPE := i_department;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE := i_dcs;
        l_id_market        market.id_market%TYPE;
    
        l_id_software_from_prof software.id_software%TYPE := i_software;
        l_id_software_cfg       software.id_software%TYPE;
        l_id_department_cfg     department.id_department%TYPE;
        l_id_dep_clin_serv_cfg  dep_clin_serv.id_dep_clin_serv%TYPE;
    
        l_pat_age        patient.age%TYPE := NULL;
        l_pat_gender     patient.gender%TYPE := NULL;
        l_pat_age_months NUMBER;
        l_general_exception EXCEPTION;
        l_id_patient patient.id_patient%TYPE;
    
    BEGIN
    
        IF g_ctx.id_episode IS NULL
           AND i_id_episode IS NULL
        THEN
            g_error := 'It''s mandatory to have an Episode Identifier';
            RAISE l_general_exception;
        ELSE
            IF (i_software IS NULL)
            THEN
                l_id_software_from_prof := i_prof.software;
            END IF;
        
            g_error := 'Call PK_PATIENT.GET_PAT_INFO_BY_EPISODE';
            IF NOT pk_patient.get_pat_info_by_episode(i_lang    => g_ctx.id_lang,
                                                      i_episode => nvl(g_ctx.id_episode, i_id_episode),
                                                      o_gender  => l_pat_gender,
                                                      o_age     => l_pat_age)
            THEN
                RAISE l_general_exception;
            END IF;
        
            SELECT id_patient
              INTO l_id_patient
              FROM episode
             WHERE id_episode = nvl(g_ctx.id_episode, i_id_episode);
            l_pat_age_months := pk_patient.get_pat_age(g_ctx.id_lang, NULL, NULL, NULL, 'MONTHS', l_id_patient);
        
        END IF;
    
        IF l_id_department IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            l_id_department := pk_progress_notes_upd.get_department(i_episode => nvl(g_ctx.id_episode, i_id_episode),
                                                                    i_epis_pn => NULL);
        END IF;
    
        IF l_id_dep_clin_serv IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            l_id_dep_clin_serv := pk_progress_notes_upd.get_dep_clin_serv(i_episode => nvl(g_ctx.id_episode,
                                                                                           i_id_episode),
                                                                          i_epis_pn => NULL);
        END IF;
    
        BEGIN
            --check the software that should be used to get the data (prof/note software or zero)            
            g_error := 'Get market to filter sblocks i_market: ' || i_market || ' i_id_pn_note_type: ' ||
                       i_id_pn_note_type || ' l_id_software_from_prof: ' || l_id_software_from_prof ||
                       ' l_id_department: ' || l_id_department || ' l_id_dep_clin_serv: ' || l_id_dep_clin_serv;
            pk_alertlog.log_debug(g_error);
            SELECT t.id_software, t.id_department, t.id_dep_clin_serv
              INTO l_id_software_cfg, l_id_department_cfg, l_id_dep_clin_serv_cfg
              FROM (SELECT pssi.id_software,
                           pssi.id_department,
                           pssi.id_dep_clin_serv,
                           row_number() over(ORDER BY decode(pssi.id_software, l_id_software_from_prof, 1, 2), decode(pssi.id_department, l_id_department, 1, 2), decode(pssi.id_dep_clin_serv, l_id_dep_clin_serv, 1, 2)) line_number
                      FROM pn_sblock_soft_inst pssi
                     WHERE pssi.id_software IN (0, l_id_software_from_prof)
                       AND pssi.id_pn_note_type = i_id_pn_note_type
                       AND pssi.id_department IN (0, l_id_department)
                       AND pssi.id_dep_clin_serv IN (0, -1, l_id_dep_clin_serv)
                       AND pssi.id_institution = i_prof.institution) t
             WHERE line_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_software_cfg      := 0;
                l_id_department_cfg    := 0;
                l_id_dep_clin_serv_cfg := -1;
        END;
    
        g_error := 'SELECT l_blocks si';
        SELECT t_rec_soap_blocks(t.id_pn_soap_block,
                                 t.id_institution,
                                 t.id_software,
                                 t.id_department,
                                 t.id_dep_clin_serv,
                                 t.rank,
                                 t.flg_execute_import,
                                 t.flg_show_title,
                                 value_viewer,
                                 file_name,
                                 file_extension)
          BULK COLLECT
          INTO l_blocks
          FROM (SELECT psb.id_pn_soap_block,
                       si.id_institution,
                       si.id_software,
                       si.id_department,
                       si.id_dep_clin_serv,
                       si.flg_execute_import,
                       nvl(si.rank, psb.rank) rank,
                       row_number() over(PARTITION BY psb.id_pn_soap_block --
                       ORDER BY si.id_department DESC, si.id_dep_clin_serv DESC, si.id_software DESC) rn,
                       si.flg_show_title,
                       decode(afm.file_extension, NULL, NULL, si.value_viewer) value_viewer,
                       coalesce(afm.file_name, af.file_name) file_name,
                       af.file_extension
                  FROM pn_soap_block psb
                  JOIN pn_sblock_soft_inst si
                    ON psb.id_pn_soap_block = si.id_pn_soap_block
                  LEFT OUTER JOIN application_file af
                    ON af.id_application_file = psb.id_swf_file_viewer
                  LEFT OUTER JOIN application_file afm
                    ON afm.id_application_file = si.id_swf_file_viewer
                 WHERE si.id_institution = i_prof.institution
                   AND si.id_software = l_id_software_cfg
                   AND si.id_pn_note_type = i_id_pn_note_type
                   AND (si.id_department = l_id_department_cfg)
                   AND (si.id_dep_clin_serv = l_id_dep_clin_serv_cfg)) t
         WHERE t.rn = 1
         ORDER BY t.rank;
    
        IF l_blocks.count < 1
        THEN
        
            --check the market that should be used to get the data (institution market or zero)            
            g_error := 'Get market to filter sblocks i_market: ' || i_market || ' i_id_pn_note_type: ' ||
                       i_id_pn_note_type || ' l_id_software_from_prof: ' || l_id_software_from_prof;
            pk_alertlog.log_debug(g_error);
            SELECT t.id_market, t.id_software
              INTO l_id_market, l_id_software_cfg
              FROM (SELECT m.id_market,
                           m.id_software,
                           row_number() over(ORDER BY decode(nvl(m.id_market, 0), i_market, 1, 2), decode(m.id_software, l_id_software_from_prof, 1, 2)) line_number
                      FROM pn_sblock_mkt m
                     WHERE m.id_software IN (0, l_id_software_from_prof)
                       AND m.id_pn_note_type = i_id_pn_note_type
                       AND m.id_market IN (0, i_market)) t
             WHERE line_number = 1;
        
            g_error := 'SELECT l_blocks m';
            pk_alertlog.log_debug(g_error);
            SELECT t_rec_soap_blocks(psb.id_pn_soap_block,
                                     0,
                                     0,
                                     0,
                                     0,
                                     nvl(m.rank, psb.rank),
                                     m.flg_execute_import,
                                     m.flg_show_title,
                                     decode(afm.file_extension, NULL, NULL, m.value_viewer),
                                     coalesce(afm.file_name, af.file_name),
                                     af.file_extension)
              BULK COLLECT
              INTO l_blocks
              FROM pn_soap_block psb
              JOIN pn_sblock_mkt m
                ON psb.id_pn_soap_block = m.id_pn_soap_block
              LEFT OUTER JOIN application_file af
                ON af.id_application_file = psb.id_swf_file_viewer
              LEFT OUTER JOIN application_file afm
                ON afm.id_application_file = m.id_swf_file_viewer
             WHERE m.id_software = l_id_software_cfg
               AND m.id_market = l_id_market
               AND m.id_pn_note_type = i_id_pn_note_type
               AND pk_prog_notes_utils.check_pn_with_patient_info(g_ctx.id_lang,
                                                                  m.age_min,
                                                                  m.age_max,
                                                                  NULL,
                                                                  l_pat_age_months,
                                                                  l_pat_gender) = pk_alert_constant.g_yes
             ORDER BY nvl(m.rank, psb.rank) ASC;
        
        END IF;
    
        RETURN l_blocks;
    END tf_sblock;

    /**
    * Get soap note blocks.
    *
    * @param i_lang                language identifier
    * @param i_prof                logged professional structure
    * @param i_patient             patient identifier
    * @param i_episode             episode identifier
    * @param i_id_pn_note_type     note type identifier
    * @param i_epis_pn_work        soap note identifier
    * @param o_soap_block          soap blocks cursor
    * @param o_data_block          data blocks cursor
    * @param o_button_block        button blocks cursor
    * @param o_error               error
    *
    * @return                      false if errors occur, true otherwise
    *
    * @author                      Pedro Carneiro
    * @version                     2.6.0.5.2
    * @since                       2011/02/14
    */
    FUNCTION get_soap_note_blocks
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_epis_pn_work    IN epis_pn.id_epis_pn%TYPE,
        i_filter_search   IN table_varchar DEFAULT NULL,
        o_soap_block      OUT pk_types.cursor_type,
        o_data_block      OUT pk_types.cursor_type,
        o_button_block    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SOAP_NOTE_BLOCKS';
        l_id_epis_pn epis_pn.id_epis_pn%TYPE := i_epis_pn_work;
    BEGIN
    
        IF pk_prog_notes_utils.check_epis_pn(i_id_epis_pn => l_id_epis_pn) = pk_alert_constant.g_yes
        THEN
            l_id_epis_pn := i_epis_pn_work;
        ELSE
            l_id_epis_pn := NULL;
        END IF;
    
        g_error := 'CALL reset_context';
        pk_alertlog.log_debug(g_error);
        reset_context(i_prof            => i_prof,
                      i_episode         => i_episode,
                      i_id_pn_note_type => i_id_pn_note_type,
                      i_epis_pn         => l_id_epis_pn);
    
        g_error := 'CALL get_all_blocks';
        pk_alertlog.log_debug(g_error);
        get_all_blocks(i_prof => i_prof, io_configs_ctx => g_ctx);
    
        g_error := 'CALL get_soap_blocks';
        pk_alertlog.log_debug(g_error);
        IF NOT get_soap_blocks(i_lang          => i_lang,
                               i_prof          => i_prof,
                               i_patient       => i_patient,
                               i_retrieve_st   => pk_alert_constant.g_no,
                               i_trans_dn      => pk_alert_constant.g_yes,
                               i_filter_search => i_filter_search,
                               o_blocks        => o_soap_block,
                               o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_static_data_blocks';
        pk_alertlog.log_debug(g_error);
        get_static_data_blocks(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_data_blocks => g_ctx.data_blocks,
                               i_soap_blocks => g_ctx.soap_blocks,
                               i_task_types  => g_ctx.task_types,
                               i_episode     => i_episode,
                               o_data_blocks => o_data_block);
    
        g_error := 'CALL get_button_blocks';
        pk_alertlog.log_debug(g_error);
        IF NOT get_static_buttons(i_lang          => i_lang,
                                  i_prof          => i_prof,
                                  i_episode       => i_episode,
                                  i_buttons       => g_ctx.buttons,
                                  o_button_blocks => o_button_block,
                                  o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_soap_block);
            pk_types.open_my_cursor(o_data_block);
            pk_types.open_my_cursor(o_button_block);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_soap_block);
            pk_types.open_my_cursor(o_data_block);
            pk_types.open_my_cursor(o_button_block);
            RETURN FALSE;
    END get_soap_note_blocks;

    /**
    * Get importable data blocks.
    *
    * @param i_lang                language identifier
    * @param i_prof                logged professional structure
    * @param i_id_pn_note_type     note type identifier
    * @param i_flg_search          Specify the type of search: 
    *                              I: importable dta blocks
    *                              A: auto-populated and auto-syncronizable data blocks
    * @param i_dblocks_list        List of data blocks to be considered in the auto-syncronizable data blocks
    * @param i_sblocks_list        List of soap blocks to be considered in the auto-syncronizable soap blocks
    * @param i_confgs_ctx             Configs context structure  
    * @param i_id_pn_soap_block       Soap blocks ID
    * @param o_data_block          data blocks collection
    * @param o_error               error
    *
    * @return                      false if errors occur, true otherwise
    *
    * @author                      Pedro Carneiro
    * @version                     2.6.0.5.2
    * @since                       2011/02/07
    */
    FUNCTION get_import_dblocks
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_flg_search       IN VARCHAR2 DEFAULT pk_prog_notes_constants.g_importable_dblocks_i,
        i_dblocks_list     IN table_number DEFAULT table_number(),
        i_sblocks_list     IN table_number DEFAULT table_number(),
        i_configs_ctx      IN pk_prog_notes_types.t_configs_ctx DEFAULT NULL,
        i_id_pn_soap_block IN table_number,
        o_data_block       OUT t_coll_data_blocks,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IMPORT_DBLOCKS';
        l_id_pn_soap_block table_number;
    BEGIN
    
        IF (i_id_pn_soap_block IS NULL OR NOT i_id_pn_soap_block.exists(1))
        THEN
            l_id_pn_soap_block := NULL;
        ELSE
            l_id_pn_soap_block := i_id_pn_soap_block;
        END IF;
    
        g_error := 'SELECT o_data_block';
        SELECT t_rec_data_blocks(db2.id_pn_soap_block,
                                 db2.id_pn_data_block,
                                 db2.id_pndb_parent,
                                 db2.data_area,
                                 db2.id_doc_area,
                                 --Change translation to sys_message Start
                                 --pk_translation.get_translation(i_lang, db2.code_pn_data_block),
                                 pk_message.get_message(i_lang, i_prof, db2.code_pn_data_block),
                                 --Change translation to sys_message End
                                 db2.flg_type,
                                 db2.flg_import,
                                 db2.area_level,
                                 db2.flg_scope,
                                 ptt.flg_selected,
                                 db2.flg_actions_available,
                                 db2.id_swf_file_viewer,
                                 db2.flg_line_on_boxes,
                                 db2.gender,
                                 db2.age_min,
                                 db2.age_max,
                                 db2.flg_pregnant,
                                 ptt.flg_auto_populated,
                                 db2.flg_cp_no_changes_import,
                                 NULL,
                                 ptt.id_task_type,
                                 db2.flg_import_date,
                                 db2.flg_outside_period,
                                 db2.days_available_period,
                                 ptt.task_type_id_parent,
                                 ptt.review_context,
                                 db2.flg_group_on_import,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 db2.flg_show_sub_title,
                                 ptt.flg_synchronized,
                                 db2.flg_data_removable,
                                 db2.auto_pop_exec_prof_cat,
                                 db2.id_summary_page,
                                 db2.flg_focus,
                                 db2.flg_editable,
                                 ptt.flg_import_filter,
                                 ptt.flg_ea,
                                 ptt.last_n_records_nr,
                                 db2.flg_group_select_filter,
                                 ptt.flg_synch_area,
                                 ptt.flg_shortcut_filter,
                                 ptt.review_cat,
                                 ptt.flg_review_avail,
                                 ptt.flg_description,
                                 ptt.description_condition,
                                 db2.id_mtos_score,
                                 ptt.flg_dt_task,
                                 flg_exc_sum_page_da,
                                 flg_group_type)
          BULK COLLECT
          INTO o_data_block
          FROM (SELECT db.id_pn_soap_block,
                       db.id_pn_data_block,
                       db.id_pndb_parent,
                       db.data_area,
                       db.id_doc_area,
                       db.code_pn_data_block,
                       db.flg_type,
                       db.flg_import,
                       db.rn_rank,
                       connect_by_isleaf           leaf,
                       LEVEL                       area_level,
                       db.flg_scope,
                       db.flg_actions_available,
                       db.id_swf_file_viewer,
                       db.flg_line_on_boxes,
                       db.gender,
                       db.age_min,
                       db.age_max,
                       db.flg_pregnant,
                       db.flg_cp_no_changes_import,
                       db.flg_import_date,
                       db.flg_outside_period,
                       db.days_available_period,
                       db.flg_group_on_import,
                       db.flg_struct_type,
                       db.flg_show_sub_title,
                       db.flg_data_removable,
                       db.auto_pop_exec_prof_cat,
                       db.id_summary_page,
                       db.flg_focus,
                       db.flg_editable,
                       db.flg_group_select_filter,
                       db.id_mtos_score,
                       db.flg_exc_sum_page_da,
                       db.flg_group_type
                  FROM (SELECT db.id_pn_soap_block,
                               pdb.id_pn_data_block,
                               db.id_pndb_parent,
                               pdb.data_area,
                               pdb.id_doc_area,
                               pdb.code_pn_data_block,
                               pdb.flg_type,
                               db.flg_import,
                               db.flg_scope,
                               row_number() over(ORDER BY sb.rank, db.rank) rn_rank,
                               db.flg_actions_available,
                               db.id_swf_file_viewer,
                               db.flg_line_on_boxes,
                               db.gender,
                               db.age_min,
                               db.age_max,
                               db.flg_pregnant,
                               db.flg_cp_no_changes_import,
                               db.flg_import_date,
                               db.flg_outside_period,
                               db.days_available_period,
                               db.flg_group_on_import,
                               db.flg_struct_type,
                               db.id_pn_soap_block || '0' || db.id_pn_data_block unq_dblock_id,
                               CASE
                                    WHEN db.id_pndb_parent IS NOT NULL THEN
                                     db.id_pn_soap_block || '0' || db.id_pndb_parent
                                    ELSE
                                     NULL
                                END unq_dblock_parent_id,
                               db.flg_show_sub_title,
                               db.flg_data_removable,
                               db.auto_pop_exec_prof_cat,
                               pdb.id_summary_page,
                               db.flg_focus,
                               db.flg_editable,
                               db.flg_group_select_filter,
                               pdb.id_mtos_score,
                               db.flg_exc_sum_page_da,
                               db.flg_group_type
                          FROM pn_data_block pdb
                          JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                t.id_pn_soap_block,
                                t.id_pn_data_block,
                                t.flg_import,
                                t.flg_select,
                                t.flg_scope,
                                rownum rank,
                                t.flg_actions_available,
                                t.id_swf_file_viewer,
                                t.flg_line_on_boxes,
                                t.gender,
                                t.age_min,
                                t.age_max,
                                t.flg_pregnant,
                                t.flg_cp_no_changes_import,
                                t.flg_import_date,
                                t.flg_outside_period,
                                t.days_available_period,
                                t.flg_group_on_import,
                                t.id_pndb_parent,
                                t.flg_struct_type,
                                t.flg_show_sub_title,
                                t.flg_data_removable,
                                t.auto_pop_exec_prof_cat,
                                t.flg_focus,
                                t.flg_editable,
                                t.flg_group_select_filter,
                                t.flg_exc_sum_page_da,
                                t.flg_group_type
                                 FROM TABLE(i_configs_ctx.data_blocks) t) db
                            ON pdb.id_pn_data_block = db.id_pn_data_block
                          JOIN (SELECT /*+opt_estimate(table t rows=1)*/ /*+opt_estimate(table sbl rows=1)*/
                                t.id_pn_soap_block, rownum rank
                                 FROM TABLE(i_configs_ctx.soap_blocks) t
                                WHERE (l_id_pn_soap_block IS NULL OR
                                      t.id_pn_soap_block IN
                                      (SELECT /*+opt_estimate(table tsb rows=1)*/
                                         column_value
                                          FROM TABLE(l_id_pn_soap_block) tsb))) sb
                            ON db.id_pn_soap_block = sb.id_pn_soap_block) db
                 WHERE ((i_flg_search = pk_prog_notes_constants.g_importable_dblocks_i AND
                       db.flg_struct_type != pk_prog_notes_constants.g_struct_type_note_n) OR
                       i_flg_search <> pk_prog_notes_constants.g_importable_dblocks_i)
                CONNECT BY PRIOR db.unq_dblock_id = db.unq_dblock_parent_id
                 START WITH db.unq_dblock_parent_id IS NULL) db2
          LEFT JOIN (SELECT /*+opt_estimate(table ptt rows=1)*/
                      t.id_pn_data_block,
                      t.id_pn_soap_block,
                      t.id_task_type,
                      t.review_context,
                      t.task_type_id_parent,
                      t.flg_auto_populated,
                      t.flg_selected,
                      t.flg_import_filter,
                      t.flg_ea,
                      t.last_n_records_nr,
                      t.flg_synch_area,
                      t.flg_shortcut_filter,
                      t.flg_synchronized,
                      t.review_cat,
                      t.flg_review_avail,
                      t.flg_description,
                      t.description_condition,
                      t.flg_dt_task
                       FROM TABLE(i_configs_ctx.task_types) t) ptt
            ON ptt.id_pn_data_block = db2.id_pn_data_block
           AND ptt.id_pn_soap_block = db2.id_pn_soap_block
         WHERE ((i_flg_search = pk_prog_notes_constants.g_importable_dblocks_i AND
               (db2.leaf = 1 AND
               (db2.flg_struct_type IN
               (pk_prog_notes_constants.g_struct_type_both_b, pk_prog_notes_constants.g_struct_type_import_i)) OR
               db2.leaf = 0))
               --
               OR
               --
               (i_flg_search = pk_prog_notes_constants.g_auto_pop_dblocks_a AND
               /*(ptt.flg_auto_populated <> pk_alert_constant.g_no OR
               (ptt.flg_synchronized <> pk_alert_constant.g_no AND*/
               ((pk_utils.str_token_find(i_string => ptt.flg_auto_populated,
                                           i_token  => pk_alert_constant.g_no,
                                           i_sep    => pk_prog_notes_constants.g_sep) = 'N') OR
               ((pk_utils.str_token_find(i_string => ptt.flg_synchronized,
                                            i_token  => pk_alert_constant.g_no,
                                            i_sep    => pk_prog_notes_constants.g_sep) = 'N') AND
               db2.id_pn_data_block IN (SELECT /*+DYNAMIC_SAMPLING (t 2)*/
                                             column_value
                                              FROM TABLE(i_dblocks_list) t) AND
               db2.id_pn_soap_block IN (SELECT /*+DYNAMIC_SAMPLING (ts 2)*/
                                             column_value
                                              FROM TABLE(i_sblocks_list) ts))
               
               ))
               --
               OR (i_flg_search = pk_prog_notes_constants.g_synch_dblocks_c AND
               --amanda modify start
               --ptt.flg_synchronized <> pk_alert_constant.g_no AND
               (pk_utils.str_token_find(i_string => ptt.flg_synchronized,
                                             i_token  => pk_alert_constant.g_no,
                                             i_sep    => pk_prog_notes_constants.g_sep) = 'N') AND
               --amanda modify end
               db2.id_pn_data_block IN (SELECT /*+DYNAMIC_SAMPLING (t 2)*/
                                              column_value
                                               FROM TABLE(i_dblocks_list) t) AND
               db2.id_pn_soap_block IN (SELECT /*+DYNAMIC_SAMPLING (ts 2)*/
                                              column_value
                                               FROM TABLE(i_sblocks_list) ts))
               --
               OR (i_flg_search = pk_prog_notes_constants.g_synch_dblocks_r AND
               db2.id_pn_data_block IN (SELECT /*+DYNAMIC_SAMPLING (t 2)*/
                                              column_value
                                               FROM TABLE(i_dblocks_list) t) AND
               db2.id_pn_soap_block IN (SELECT /*+DYNAMIC_SAMPLING (ts 2)*/
                                              column_value
                                               FROM TABLE(i_sblocks_list) ts)))
        
         ORDER BY db2.rn_rank, db2.id_pn_data_block;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_import_dblocks;

    /**
    * Get soap note blocks.
    *
    * @param i_lang                language identifier
    * @param i_prof                logged professional structure
    * @param i_episode             episode identifier
    * @param i_id_pn_note_type     note type identifier    
    * @param i_id_epis_pn          note id
    * @param o_soap_blocks         soap blocks cursor
    * @param o_error               error
    *
    * @return                      false if errors occur, true otherwise
    *
    * @author                      Sofia Mendes
    * @version                     2.6.0.5.2
    * @since                       21-Feb-2011
    */
    FUNCTION get_soap_blocks_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_soap_blocks     OUT tab_soap_blocks,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SOAP_BLOCKS_LIST';
    BEGIN
        g_error := 'CALL reset_context';
        reset_context(i_prof            => i_prof,
                      i_episode         => i_episode,
                      i_id_pn_note_type => i_id_pn_note_type,
                      i_epis_pn         => i_id_epis_pn);
    
        g_error := 'CALL get_all_blocks';
        get_all_blocks(i_prof => i_prof, io_configs_ctx => g_ctx);
    
        o_soap_blocks := g_ctx.soap_blocks;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_soap_blocks_list;

    /**************************************************************************
    * get data block type for a soap block ID
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_episode             Episode ID
    * @param i_id_pn_note_type        Note Type Identifier
    * @param i_id_pn_soap_block       Soap block ID
    * 
    * return  data block flg_type                       
    *                                                                        
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/23                               
    **************************************************************************/

    FUNCTION get_soap_blocks_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN table_varchar IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SOAP_BLOCKS_TYPE';
        l_flg_type  table_varchar;
        l_error_out t_error_out;
    BEGIN
        g_error := 'CALL reset_context';
        reset_context(i_prof            => i_prof,
                      i_episode         => i_episode,
                      i_id_pn_note_type => i_id_pn_note_type,
                      i_epis_pn         => NULL);
    
        g_error := 'CALL get_all_blocks';
        get_all_blocks(i_prof => i_prof, io_configs_ctx => g_ctx);
    
        SELECT t.flg_type
          BULK COLLECT
          INTO l_flg_type
          FROM TABLE(g_ctx.data_blocks) t
         WHERE t.id_pn_soap_block = i_id_pn_soap_block;
    
        RETURN l_flg_type;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error_out);
            RETURN NULL;
    END get_soap_blocks_type;

    /**
    * Returns the description of a soap block.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pn_soap_block       soap block identifier  
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_soap_block_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_error      t_error_out;
        l_desc_block pk_translation.t_desc_translation;
    BEGIN
        g_error := 'GET soap block description';
        pk_alertlog.log_debug(g_error);
        SELECT pk_message.get_message(i_lang, i_prof, psb.code_message_ti)
          INTO l_desc_block
          FROM pn_soap_block psb
         WHERE psb.id_pn_soap_block = i_id_pn_soap_block;
    
        RETURN l_desc_block;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SOAP_BLOCK_DESC',
                                              l_error);
        
            RETURN NULL;
    END get_soap_block_desc;

    /**
    * Returns the description of a soap block to the history screen: Ex. New Assessment.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pn_soap_block       soap block identifier  
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_soap_block_desc_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_error      t_error_out;
        l_desc_block pk_translation.t_desc_translation;
    BEGIN
        g_error := 'GET soap block description';
        pk_alertlog.log_debug(g_error);
        SELECT pk_message.get_message(i_lang, i_prof, code_pn_soap_block_hist)
        --        pk_translation.get_translation(i_lang, psb.code_pn_soap_block_hist)
          INTO l_desc_block
          FROM pn_soap_block psb
         WHERE psb.id_pn_soap_block = i_id_pn_soap_block;
    
        RETURN l_desc_block;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SOAP_BLOCK_DESC_HIST',
                                              l_error);
        
            RETURN NULL;
    END get_soap_block_desc_hist;

    /**
    * Returns the description of a data area.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pn_data_block       data block identifier  
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                11-Feb-2011
    */
    FUNCTION get_block_area_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_error       t_error_out;
        l_desc_dblock pk_translation.t_desc_translation;
    BEGIN
        g_error := 'GET block area translation';
        pk_alertlog.log_debug(g_error);
        --Change translation to sys_message start
        --SELECT pk_translation.get_translation(i_lang, db.code_pn_data_block)
        SELECT pk_message.get_message(i_lang, i_prof, db.code_pn_data_block)
        --Change translation to sys_message end
          INTO l_desc_dblock
          FROM pn_data_block db
         WHERE db.id_pn_data_block = i_id_pn_data_block;
    
        RETURN l_desc_dblock;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BLOCK_AREA_DESC',
                                              l_error);
        
            RETURN NULL;
    END get_block_area_desc;

    /**
    * Returns the description of a data area to the history. Ex. New diagnosis
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pn_data_block       data block identifier  
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                11-Feb-2011
    */
    FUNCTION get_block_area_desc_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_error       t_error_out;
        l_desc_dblock pk_translation.t_desc_translation;
    BEGIN
        g_error := 'GET block area translation hist';
        pk_alertlog.log_debug(g_error);
        --Change translation to sys_message start
        --SELECT pk_translation.get_translation(i_lang, db.code_pn_data_block_hist)
        SELECT pk_message.get_message(i_lang, i_prof, db.code_pn_data_block_hist)
        --Change translation to sys_message end
          INTO l_desc_dblock
          FROM pn_data_block db
         WHERE db.id_pn_data_block = i_id_pn_data_block;
    
        RETURN l_desc_dblock;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BLOCK_AREA_DESC_HIST',
                                              l_error);
        
            RETURN NULL;
    END get_block_area_desc_hist;

    /**
    * Returns the doc_areas list associated to the notes buttons or areas
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pn_data_block       data block identifier 
    *
    * @param OUT  o_doc_areas         Doc areas list
    * @param OUT  o_error             Error structure 
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                11-Feb-2011
    */
    FUNCTION get_doc_areas
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_doc_areas OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET block area translation hist';
        pk_alertlog.log_debug(g_error);
        SELECT cbb.id_doc_area
          BULK COLLECT
          INTO o_doc_areas
          FROM conf_button_block cbb
        UNION ALL
        SELECT pdb.id_doc_area
          FROM pn_data_block pdb;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_AREAS',
                                              o_error);
        
            RETURN FALSE;
    END get_doc_areas;

    /**
    * Checks if the id_soap_block (i_search) exists in the list of soap blocks
    *
    * @param i_table                  Soap blocks info list
    * @param i_search                 Soap block id to be searched
    * @param i_id_pn_data_block       data block identifier 
    *    
    *
    * @return                        -1: soap block not found; Otherwise: index of the soap block in the given list
    *
    * @author               Sofia Mendes
    * @version               2.6.1.3
    * @since                14-Oct-2011
    */
    FUNCTION search_tab_soap_blocks
    (
        i_table  IN tab_soap_blocks,
        i_search IN NUMBER
    ) RETURN NUMBER IS
        l_indice   NUMBER;
        l_nr_elems PLS_INTEGER;
    BEGIN
    
        l_indice := -1;
    
        l_nr_elems := i_table.count;
    
        FOR i IN 1 .. l_nr_elems
        LOOP
            IF i_table(i).id_pn_soap_block = i_search
            THEN
                l_indice := i;
                EXIT;
            END IF;
        END LOOP;
    
        RETURN l_indice;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /********************************************************************************************
    * Gets the permission from EHR Access Rules
    *
    * @param         I_LANG                  Language ID for translations
    * @param         I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param         I_ID_EPISODE            Episode Identifier
    * @param         I_ID_TL_TASK            Task Type Identifier
    * @param         I_EHR_ACCESS_AREA       EHR Access Area code
    *
    * @return                                Active (A) when having permissions to change the area. Inactive (I) otherwise
    *
    * @author                                António Neto
    * @since                                 29-Feb-2012
    * @version                               2.6.2
    ********************************************************************************************/
    FUNCTION get_ttype_by_pn_group(i_id_pn_group IN NUMBER) RETURN table_number IS
        tbl_return table_number;
    BEGIN
    
        SELECT id_task_type
          BULK COLLECT
          INTO tbl_return
          FROM alert.pn_group_task_types x
         WHERE x.id_pn_group = 1;
    
        RETURN tbl_return;
    
    END get_ttype_by_pn_group;

    FUNCTION get_tt_area_by_ttype(i_tbl_type IN table_number) RETURN table_varchar IS
        tbl_return table_varchar;
    BEGIN
    
        SELECT tlt.ehr_access_area
          BULK COLLECT
          INTO tbl_return
          FROM tl_task tlt
         WHERE tlt.id_tl_task IN (SELECT column_value id_tl_task
                                    FROM TABLE(i_tbl_type));
    
        RETURN tbl_return;
    
    END get_tt_area_by_ttype;

    FUNCTION get_ehr_access_area
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_tl_task      IN tl_task.id_tl_task%TYPE,
        i_ehr_access_area IN tl_task.ehr_access_area%TYPE,
        i_pn_group        IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_permission      VARCHAR2(1 CHAR) := pk_alert_constant.g_active;
        l_error           t_error_out;
        l_ehr_access_area tl_task.ehr_access_area%TYPE := i_ehr_access_area;
        l_id_patient      patient.id_patient%TYPE;
        tbl_ttype         table_number := table_number();
        tbl_tt_area       table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'Check Access Area l_ehr_access_area: ''' || l_ehr_access_area || '''; i_id_tl_task: ' ||
                   i_id_tl_task;
        IF l_ehr_access_area IS NULL
           AND i_id_tl_task IS NOT NULL
           AND i_pn_group IS NULL
        THEN
        
            tbl_tt_area := get_tt_area_by_ttype(table_number(i_id_tl_task));
        
        ELSIF l_ehr_access_area IS NULL
              AND i_id_tl_task IS NULL
              AND i_pn_group IS NOT NULL
        THEN
        
            tbl_ttype   := get_ttype_by_pn_group(i_pn_group);
            tbl_tt_area := get_tt_area_by_ttype(tbl_ttype);
        
        ELSIF l_ehr_access_area IS NULL
              AND i_id_tl_task IS NULL
              AND i_pn_group IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        <<lup_check_permission>>
        FOR i IN 1 .. tbl_tt_area.count
        LOOP
        
            l_ehr_access_area := tbl_tt_area(i);
        
            IF l_ehr_access_area IS NOT NULL
            THEN
                g_error := 'CALL pk_ehr_access.check_area_create_permission';
                IF NOT pk_ehr_access.check_area_create_permission(i_lang    => i_lang,
                                                                  i_prof    => i_prof,
                                                                  i_episode => i_id_episode,
                                                                  i_area    => l_ehr_access_area,
                                                                  o_val     => l_permission,
                                                                  o_error   => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        
            IF l_permission = pk_alert_constant.g_no
            THEN
                EXIT lup_check_permission;
            END IF;
        
        END LOOP lup_check_permission;
    
        IF l_permission = pk_alert_constant.g_no
        THEN
            l_permission := pk_alert_constant.g_inactive;
        ELSE
            CASE
                WHEN i_id_tl_task = pk_prog_notes_constants.g_task_no_known_prob THEN
                    BEGIN
                        SELECT e.id_patient
                          INTO l_id_patient
                          FROM episode e
                         WHERE e.id_episode = i_id_episode;
                    EXCEPTION
                        WHEN no_data_found THEN
                            RAISE g_exception;
                    END;
                    g_error      := 'CALL pk_problems.get_validate_add_button';
                    l_permission := pk_problems.get_validate_add_button(i_lang    => i_lang,
                                                                        i_prof    => i_prof,
                                                                        i_patient => l_id_patient,
                                                                        i_episode => i_id_episode);
                
                WHEN i_id_tl_task IN (pk_prog_notes_constants.g_task_problems,
                                      pk_prog_notes_constants.g_task_ph_surgical_hist,
                                      pk_prog_notes_constants.g_task_ph_medical_hist) THEN
                    g_error      := 'CALL pk_problems.get_validate_button_areas';
                    l_permission := pk_problems.get_validate_button_areas(i_prof       => i_prof,
                                                                          i_id_tl_task => i_id_tl_task);
                
                WHEN i_id_tl_task IN (pk_prog_notes_constants.g_task_inp_surg,
                                      pk_prog_notes_constants.g_task_medical_appointment,
                                      pk_prog_notes_constants.g_task_nutrition_appointment,
                                      pk_prog_notes_constants.g_task_social_service,
                                      pk_prog_notes_constants.g_task_nursing_appointment,
                                      pk_prog_notes_constants.g_task_psychology) THEN
                    BEGIN
                        SELECT e.id_patient
                          INTO l_id_patient
                          FROM episode e
                         WHERE e.id_episode = i_id_episode;
                    EXCEPTION
                        WHEN no_data_found THEN
                            RAISE g_exception;
                    END;
                    IF (pk_patient.get_pat_has_inactive(i_lang, i_prof, l_id_patient) = pk_alert_constant.g_yes)
                    THEN
                        l_permission := pk_alert_constant.g_no;
                    ELSE
                        l_permission := pk_alert_constant.g_yes;
                    END IF;
                WHEN i_id_tl_task IN (pk_prog_notes_constants.g_task_triage) THEN
                    IF NOT pk_edis_triage.get_can_create_triage(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_id_episode        => i_id_episode,
                                                                i_id_triage_type    => NULL,
                                                                o_can_create_triage => l_permission,
                                                                o_error             => l_error)
                    THEN
                        l_permission := pk_alert_constant.g_yes;
                    END IF;
                ELSE
                    l_permission := pk_alert_constant.g_yes;
            END CASE;
        
            IF l_permission = pk_alert_constant.g_yes
            THEN
                l_permission := pk_alert_constant.g_active;
            ELSE
                l_permission := pk_alert_constant.g_inactive;
            END IF;
        END IF;
    
        RETURN l_permission;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EHR_ACCESS_AREA',
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_inactive;
    END get_ehr_access_area;

    /********************************************************************************************
    * Gets the Configurations of a task type in a data block
    *
    * @param   i_lang                      Language identifier
    * @param   i_prof                      Professional Identification
    * @param   i_episode                   Episode identifier
    * @param   i_id_market                 Market identifier
    * @param   i_id_department             Service identifier
    * @param   i_id_dep_clin_serv          Service/specialty identifier
    * @param   i_id_pn_note_type           Note type ID
    * @param   i_software                  Software ID
    * @param   i_id_task_type              Task type ID
    * @param   i_id_pn_data_block          Data block ID
    * @param   i_id_pn_soap_block          Soap block ID
    *                        
    * @return                              Returns the Area Configurations related to the specified profile
    * 
    * @author                              Sofia Mendes
    * @version                             2.6.2.1
    * @since                               18-Mai-2012
    **********************************************************************************************/
    FUNCTION tf_dblock_task_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_market        IN market.id_market%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_software         IN software.id_software%TYPE,
        i_id_task_type     IN pn_dblock_ttp_mkt.id_task_type%TYPE DEFAULT NULL,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE DEFAULT NULL,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE DEFAULT NULL
    ) RETURN t_coll_dblock_task_type IS
        l_pn_db_task_type t_coll_dblock_task_type;
    
        l_id_market        market.id_market%TYPE := i_id_market;
        l_id_department    department.id_department%TYPE := i_id_department;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE := i_id_dep_clin_serv;
    
        l_id_software_from_prof software.id_software%TYPE := i_software;
        e_general_exception EXCEPTION;
    
        l_id_software_cfg      software.id_software%TYPE;
        l_id_department_cfg    department.id_department%TYPE;
        l_id_dep_clin_serv_cfg dep_clin_serv.id_dep_clin_serv%TYPE;
    
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'TF_DBLOCK_TASK_TYPE';
    BEGIN
    
        IF l_id_department IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            g_error := 'Call pk_progress_notes_upd.get_department. i_id_episode: ' || i_id_episode;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            l_id_department := pk_progress_notes_upd.get_department(i_episode => i_id_episode, i_epis_pn => NULL);
        END IF;
    
        IF l_id_dep_clin_serv IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            g_error := 'Call pk_progress_notes_upd.get_dep_clin_serv. i_id_episode: ' || i_id_episode;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            l_id_dep_clin_serv := pk_progress_notes_upd.get_dep_clin_serv(i_episode => i_id_episode, i_epis_pn => NULL);
        END IF;
    
        --get episode software
        IF i_software IS NULL
        THEN
            l_id_software_from_prof := i_prof.software;
        END IF;
    
        BEGIN
            --check the software that should be used to get the data (prof/note software or zero)            
            g_error := 'Get market to filter sblocks id_software: ' || l_id_software_from_prof;
            pk_alertlog.log_debug(g_error);
            SELECT t.id_software, t.id_department, t.id_dep_clin_serv
              INTO l_id_software_cfg, l_id_department_cfg, l_id_dep_clin_serv_cfg
              FROM (SELECT pdsi.id_software,
                           pdsi.id_department,
                           pdsi.id_dep_clin_serv,
                           row_number() over(ORDER BY decode(pdsi.id_software, l_id_software_from_prof, 1, 2), decode(pdsi.id_department, l_id_department, 1, 2), decode(pdsi.id_dep_clin_serv, l_id_dep_clin_serv, 1, 2)) line_number
                      FROM pn_dblock_ttp_soft_inst pdsi
                     WHERE pdsi.id_software IN (0, l_id_software_from_prof)
                       AND pdsi.id_department IN (0, l_id_department)
                       AND pdsi.id_dep_clin_serv IN (0, -1, l_id_dep_clin_serv)
                       AND pdsi.id_pn_note_type = i_id_pn_note_type
                       AND pdsi.id_institution = i_prof.institution) t
             WHERE line_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_software_cfg      := 0;
                l_id_department_cfg    := 0;
                l_id_dep_clin_serv_cfg := -1;
        END;
    
        g_error := 'GET data block task types from soft inst table';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT t_rec_dblock_task_type(pdtsi.id_pn_data_block,
                                      pdtsi.id_pn_soap_block,
                                      pdtsi.id_pn_note_type,
                                      pdtsi.id_task_type,
                                      pdtsi.id_department,
                                      pdtsi.id_dep_clin_serv,
                                      pdtsi.flg_auto_populated,
                                      tt.id_parent,
                                      tt.flg_synch_area,
                                      tt.review_context,
                                      pdtsi.flg_selected,
                                      pdtsi.flg_import_filter,
                                      tt.flg_ea,
                                      pdtsi.last_n_records_nr,
                                      pdtsi.flg_shortcut_filter,
                                      pdtsi.flg_synchronized,
                                      pdtsi.review_cat,
                                      pdtsi.flg_review_avail,
                                      pdtsi.flg_description,
                                      pdtsi.description_condition,
                                      pdtsi.flg_dt_task)
          BULK COLLECT
          INTO l_pn_db_task_type
          FROM pn_dblock_ttp_soft_inst pdtsi
          JOIN tl_task tt
            ON tt.id_tl_task = pdtsi.id_task_type
         WHERE pdtsi.id_institution = i_prof.institution
           AND pdtsi.id_software = l_id_software_cfg
           AND (pdtsi.id_department = l_id_department_cfg)
           AND (pdtsi.id_dep_clin_serv = l_id_dep_clin_serv_cfg)
           AND pdtsi.flg_available = pk_alert_constant.g_yes
           AND pdtsi.id_pn_note_type = i_id_pn_note_type
           AND (pdtsi.id_task_type = i_id_task_type OR i_id_task_type IS NULL)
           AND (pdtsi.id_pn_data_block = i_id_pn_data_block OR i_id_pn_data_block IS NULL)
           AND (pdtsi.id_pn_soap_block = i_id_pn_soap_block OR i_id_pn_soap_block IS NULL);
    
        IF (l_pn_db_task_type.count < 1)
        THEN
        
            IF l_id_market IS NULL
            THEN
                g_error := 'CALL pk_core.get_inst_mkt';
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
            END IF;
        
            --check the market that should be used to get the data (institution market or zero)
            BEGIN
                g_error := 'Get market to filter dblocks l_id_market: ' || l_id_market;
                pk_alertlog.log_debug(g_error);
                SELECT t.id_market, t.id_software
                  INTO l_id_market, l_id_software_cfg
                  FROM (SELECT m.id_market,
                               m.id_software,
                               row_number() over(ORDER BY decode(nvl(m.id_market, 0), l_id_market, 1, 2), decode(m.id_software, l_id_software_from_prof, 1, 2)) line_number
                          FROM pn_dblock_ttp_mkt m
                         WHERE m.id_software IN (0, l_id_software_from_prof)
                           AND m.id_market IN (0, l_id_market)
                           AND m.id_pn_note_type = nvl(i_id_pn_note_type, m.id_pn_note_type)
                           AND m.id_pn_data_block = nvl(NULL, m.id_pn_data_block)) t
                 WHERE line_number = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_software_cfg := 0;
                    l_id_market       := 0;
            END;
        
            BEGIN
                g_error := 'GET data block task types from mkt table';
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                SELECT t_rec_dblock_task_type(pdttm.id_pn_data_block,
                                              pdttm.id_pn_soap_block,
                                              pdttm.id_pn_note_type,
                                              pdttm.id_task_type,
                                              0,
                                              0,
                                              pdttm.flg_auto_populated,
                                              tt.id_parent,
                                              tt.flg_synch_area,
                                              tt.review_context,
                                              pdttm.flg_selected,
                                              pdttm.flg_import_filter,
                                              tt.flg_ea,
                                              pdttm.last_n_records_nr,
                                              pdttm.flg_shortcut_filter,
                                              pdttm.flg_synchronized,
                                              pdttm.review_cat,
                                              pdttm.flg_review_avail,
                                              pdttm.flg_description,
                                              pdttm.description_condition,
                                              pdttm.flg_dt_task)
                  BULK COLLECT
                  INTO l_pn_db_task_type
                  FROM pn_dblock_ttp_mkt pdttm
                  JOIN tl_task tt
                    ON tt.id_tl_task = pdttm.id_task_type
                 WHERE pdttm.id_software = l_id_software_cfg
                   AND pdttm.id_market = l_id_market
                   AND pdttm.id_pn_note_type = i_id_pn_note_type
                   AND (pdttm.id_task_type = i_id_task_type OR i_id_task_type IS NULL)
                   AND (pdttm.id_pn_data_block = i_id_pn_data_block OR i_id_pn_data_block IS NULL)
                   AND (pdttm.id_pn_soap_block = i_id_pn_soap_block OR i_id_pn_soap_block IS NULL);
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_pn_db_task_type := NULL;
            END;
        END IF;
    
        RETURN l_pn_db_task_type;
    END tf_dblock_task_type;

    /********************************************************************************************
    * Gets the Configurations of a task type in a data block
    *
    * @param   i_lang                      Language identifier
    * @param   i_prof                      Professional Identification
    * @param   i_episode                   Episode identifier
    * @param   io_id_department            Service identifier
    * @param   io_id_dep_clin_serv         Service/specialty identifier
    * @param   io_episode_software         Software ID associated to the episode
    *                        
    * @return                              Returns the Area Configurations related to the specified profile
    * 
    * @author                              Sofia Mendes
    * @version                             2.6.2.1
    * @since                               18-Mai-2012
    **********************************************************************************************/
    FUNCTION get_epis_vars
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        io_id_department    IN OUT department.id_department%TYPE,
        io_id_dep_clin_serv IN OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        io_episode_software IN OUT software.id_software%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'GET_EPIS_VARS';
    BEGIN
    
        IF io_id_department IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            g_error := 'Call pk_progress_notes_upd.get_department. i_id_episode: ' || i_id_episode;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            io_id_department := pk_progress_notes_upd.get_department(i_episode => i_id_episode, i_epis_pn => NULL);
        END IF;
    
        IF io_id_dep_clin_serv IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            g_error := 'Call pk_progress_notes_upd.get_dep_clin_serv. i_id_episode: ' || i_id_episode;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            io_id_dep_clin_serv := pk_progress_notes_upd.get_dep_clin_serv(i_episode => i_id_episode, i_epis_pn => NULL);
        END IF;
    
        --get episode software
        IF i_id_episode IS NOT NULL
           AND io_episode_software IS NULL
        THEN
            g_error := 'Call PK_EPISODE.GET_EPISODE_SOFTWARE. i_id_episode: ' || i_id_episode;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_episode.get_episode_software(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_id_episode  => i_id_episode,
                                                   o_id_software => io_episode_software,
                                                   o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_epis_vars;

    /**
    * Check if a button should be active or inactive
    *
    * @param i_lang               language ID
    * @param i_prof               professional info
    * @param i_id_episode         episode ID
    * @param i_id_visit           visit ID
    * @param i_id_patient         patient ID
    * @param i_id_pn_task_type    Task type ID
    * @param i_flg_activation      Flag to indicate if some rule should be applied
    *
    * @return                         id_prof_signoff
    *
    * @author               Sofia Mendes
    * @version               2.6.3.6
    * @since               8-Jul-2013
    */
    FUNCTION check_button_active
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_visit        IN visit.id_visit%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_pn_task_type IN tl_task.id_tl_task%TYPE,
        i_flg_activation  IN pn_button_mkt.flg_activation%TYPE,
        i_doc_area        IN doc_area.id_doc_area%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(19 CHAR) := 'CHECK_BUTTON_ACTIVE';
        l_permission VARCHAR2(1 CHAR) := pk_alert_constant.g_active;
    BEGIN
        g_error := 'Input parameters: i_id_episode: ' || i_id_episode || ' i_id_visit: ' || i_id_visit ||
                   ' i_id_patient: ' || i_id_patient || ' i_id_pn_task_type: ' || i_id_pn_task_type ||
                   ' i_flg_activation: ' || i_flg_activation;
        pk_alertlog.log_debug(g_error);
    
        IF (i_id_pn_task_type IS NOT NULL)
        THEN
            g_error := 'CALL pk_progress_notes_upd.get_ehr_access_area';
            pk_alertlog.log_debug(g_error);
            l_permission := pk_progress_notes_upd.get_ehr_access_area(i_lang,
                                                                      i_prof,
                                                                      i_id_episode,
                                                                      i_id_pn_task_type,
                                                                      NULL);
        END IF;
    
        IF (l_permission = pk_alert_constant.g_active AND i_flg_activation = pk_prog_notes_constants.g_flg_activation_o)
        THEN
            --the button is active if there is not some ongoing record yet
            BEGIN
                g_error := 'Check if there is ongoing records';
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                SELECT pk_alert_constant.g_inactive
                  INTO l_permission
                  FROM (SELECT flg_ongoing, id_tl_task, id_doc_area
                          FROM v_pn_tasks
                         WHERE id_episode = i_id_episode
                           AND flg_show_method = pk_prog_notes_constants.g_flg_scope_e
                        UNION
                        SELECT flg_ongoing, id_tl_task, id_doc_area
                          FROM v_pn_tasks
                         WHERE id_visit = i_id_visit
                           AND flg_show_method = pk_prog_notes_constants.g_flg_scope_v
                        UNION
                        SELECT flg_ongoing, id_tl_task, id_doc_area
                          FROM v_pn_tasks
                         WHERE id_patient = i_id_patient
                           AND flg_show_method = pk_prog_notes_constants.g_flg_scope_p) v
                 WHERE v.flg_ongoing = pk_prog_notes_constants.g_task_ongoing_o
                   AND v.id_tl_task = i_id_pn_task_type
                   AND (v.id_doc_area = i_doc_area OR i_doc_area IS NULL)
                   AND rownum = 1;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END IF;
    
        RETURN l_permission;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_button_active;

    /**
    * Check if shortcuts button shoud be available for the soap block
    *
    * @param i_lang             language ID
    * @param i_prof             professional
    * @param i_pn_soap_block    Task type ID
    *
    * @return                   Y/N
    *
    * @author                   Vanessa Barsottelli
    * @version                  2.6.4,1
    * @since                    01-Jul-2014
    */
    FUNCTION get_soap_shortcuts_available
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SOAP_SHORTCUTS_AVAILABLE';
        l_available VARCHAR2(1 CHAR);
    BEGIN
    
        g_error := 'check if shortcuts button shoud be available for the soap block';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        BEGIN
            SELECT shortcuts_available
              INTO l_available
              FROM (SELECT /*+opt_estimate(table t rows=1)*/
                     pk_alert_constant.get_yes shortcuts_available,
                     row_number() over(PARTITION BY t.id_pn_soap_block ORDER BY t.id_pn_soap_block) rn
                      FROM TABLE(g_ctx.buttons) t
                     WHERE t.id_pn_soap_block = i_pn_soap_block
                       AND t.id_parent IS NOT NULL)
             WHERE rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_available := pk_alert_constant.g_no;
        END;
    
        RETURN l_available;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_soap_shortcuts_available;

    -- get specific template for an intervention via progress notes
    FUNCTION get_interv_template
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_epis_pn IN NUMBER
    ) RETURN t_coll_template IS
        tbl_template t_coll_template;
        k_interv_task CONSTANT NUMBER := 8;
        k_exam_task   CONSTANT NUMBER := 101;
    BEGIN
    
        IF i_id_epis_pn IS NOT NULL
        THEN
        
            SELECT t_rec_template(id_doc_template, desc_template, id_doc_area, flg_type)
              BULK COLLECT
              INTO tbl_template
              FROM (SELECT templ.id_doc_template,
                           pk_translation.get_translation(i_lang, dt.code_doc_template) desc_template,
                           id_doc_area,
                           NULL flg_type -- documentation templates search mode
                      FROM (SELECT pk_touch_option.get_doc_template_internal(i_lang,
                                                                             i_prof,
                                                                             NULL,
                                                                             xpn.id_episode,
                                                                             pk_procedures_constant.g_doc_area_intervention,
                                                                             ipd.id_intervention) id_doc_template,
                                   pk_procedures_constant.g_doc_area_intervention id_doc_area
                              FROM interv_presc_det ipd
                              JOIN epis_pn_det_task xtask
                                ON xtask.id_task = ipd.id_interv_presc_det
                              JOIN epis_pn_det xdet
                                ON xdet.id_epis_pn_det = xtask.id_epis_pn_det
                              JOIN epis_pn xpn
                                ON xpn.id_epis_pn = xdet.id_epis_pn
                             WHERE xpn.id_epis_pn = i_id_epis_pn
                               AND xtask.id_task_type = k_interv_task
                            UNION
                            SELECT pk_touch_option.get_doc_template_internal(i_lang,
                                                                             i_prof,
                                                                             NULL,
                                                                             xpn.id_episode,
                                                                             pk_exam_constant.g_doc_area_exam,
                                                                             erd.id_exam) id_doc_template,
                                   pk_exam_constant.g_doc_area_exam id_doc_area
                              FROM exam_req_det erd
                              JOIN epis_pn_det_task xtask
                                ON xtask.id_task = erd.id_exam_req_det
                              JOIN epis_pn_det xdet
                                ON xdet.id_epis_pn_det = xtask.id_epis_pn_det
                              JOIN epis_pn xpn
                                ON xpn.id_epis_pn = xdet.id_epis_pn
                             WHERE xpn.id_epis_pn = i_id_epis_pn
                               AND xtask.id_task_type = k_exam_task) templ
                      JOIN doc_template dt
                        ON dt.id_doc_template = templ.id_doc_template) xtemplate;
        
        END IF;
    
        RETURN tbl_template;
    
    END get_interv_template;

    -- ********************************************
    -- get templates of areas via progress notes
    FUNCTION get_epis_pn_doc_template
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_epis_pn IN NUMBER
    ) RETURN t_coll_template IS
        tbl_template t_coll_template := t_coll_template();
    BEGIN
    
        tbl_template := get_interv_template(i_lang, i_prof, i_id_epis_pn);
    
        RETURN tbl_template;
    
    END get_epis_pn_doc_template;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_progress_notes_upd;
/
