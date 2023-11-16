/*-- Last Change Revision: $Rev: 2001625 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2021-11-19 16:23:27 +0000 (sex, 19 nov 2021) $*/

CREATE OR REPLACE PACKAGE pk_prog_notes_types IS

    -- Author  : SOFIA.MENDES
    -- Created : 6/18/2012 11:43:44 AM
    -- Purpose : Types definition to be used in the single-pages/notes

    -- Public type declarations
    TYPE t_configs_ctx IS RECORD(
        id_market           market.id_market%TYPE, -- market identifier
        id_profile_template profile_template.id_profile_template%TYPE, -- logged professional profile
        id_category         category.id_category%TYPE, --logged professional category
        id_department       department.id_department%TYPE, -- service identifier
        id_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE, -- service/specialty association identifier
        flg_approach        profile_template.flg_approach%TYPE, -- logged professional profile approach
        id_pn_note_type     pn_note_type.id_pn_note_type%TYPE, -- note type identifier        
        id_episode          episode.id_episode%TYPE, -- Actual Episode Identifier
        id_software         software.id_software%TYPE, -- Episode associated to the note
        id_lang             language.id_language%TYPE, -- Actual Language requested
        prof                profissional, -- Professional who requested
        --
        soap_blocks tab_soap_blocks, -- configured soap blocks ordered collection
        data_blocks t_coll_dblock, -- configured data blocks ordered collection
        buttons     t_coll_button, -- configured button blocks ordered collection
        task_types  t_coll_dblock_task_type, --configured task types
        note_type   t_rec_note_type --note type cfgs        
        );

    TYPE t_rec_tasks IS RECORD(
        id_epis_pn_det_task   epis_pn_det_task.id_epis_pn_det_task%TYPE,
        id_epis_pn_det        epis_pn_det_task.id_epis_pn_det%TYPE,
        flg_status            epis_pn_det_task.flg_status%TYPE,
        id_task               epis_pn_det_task.id_task%TYPE,
        id_task_type          epis_pn_det_task.id_task_type%TYPE,
        id_task_aggregator    epis_pn_det_task.id_task_aggregator%TYPE,
        pn_note               epis_pn_det_task.pn_note%TYPE,
        flg_table_origin      epis_pn_det_task.flg_table_origin%TYPE,
        dt_task               epis_pn_det_task.dt_task%TYPE,
        id_parent             epis_pn_det_task.id_parent%TYPE,
        rank_task             epis_pn_det_task.rank_task%TYPE,
        id_prof_task          epis_pn_det_task.id_prof_task%TYPE,
        flg_create            VARCHAR2(1 CHAR), --Y - new record to be created. N-record to be updated
        id_task_parent        task_timeline_ea.id_parent_comments%TYPE,
        flg_find_parent       VARCHAR2(1 CHAR), --Y - it is necessary to assingn a parent to this record        
        dt_group_import       epis_pn_det_task.dt_group_import%TYPE,
        id_group_import       epis_pn_det_task.id_group_import%TYPE,
        code_desc_group       epis_pn_det_task.code_desc_group%TYPE,
        desc_group            VARCHAR2(200 CHAR),
        id_sub_group_import   epis_pn_det_task.id_sub_group_import%TYPE,
        code_desc_sub_group   epis_pn_det_task.code_desc_sub_group%TYPE,
        id_sample_type        epis_pn_det_task.id_sample_type%TYPE,
        code_desc_sample_type epis_pn_det_task.code_desc_sample_type%TYPE,
        id_group_table        epis_pn_det_task.id_group_table%TYPE,
        table_position        epis_pn_det_task.table_position%TYPE,
        flg_show_sub_title    pn_dblock_mkt.flg_show_sub_title%TYPE,
        id_prof_review        epis_pn_det_task.id_prof_review%TYPE,
        dt_review             epis_pn_det_task.dt_review%TYPE,
        id_task_notes         NUMBER(24),
        flg_action            epis_pn_det_task.flg_action%TYPE,
        dt_req_task            epis_pn_det_task.dt_req_task%TYPE,
        code_desc_group_parent epis_pn_det_task.code_desc_group_parent%TYPE,
        instructions_hash      epis_pn_det_task.instructions_hash%TYPE);

    TYPE t_table_tasks IS TABLE OF t_rec_tasks INDEX BY BINARY_INTEGER; --index: id_epis_pn_det_task

    TYPE t_rec_dblock_det IS RECORD(
        id_epis_pn_det     epis_pn_det.id_epis_pn_det%TYPE,
        id_epis_pn         epis_pn.id_epis_pn%TYPE,
        id_pn_soap_block   pn_soap_block.id_pn_soap_block%TYPE,
        id_pn_data_block   pn_data_block.id_pn_data_block%TYPE,
        flg_status         epis_pn_det.flg_status%TYPE,
        dt_note            epis_pn_det.dt_note%TYPE,
        pn_note            epis_pn_det.pn_note%TYPE,
        id_multichoice     table_number,
        flg_create         VARCHAR2(1 CHAR), --Y - new record to be create. N-record to be updated
        flg_app_upd        VARCHAR2(1char),
        id_professional    epis_pn_det.id_professional%TYPE,
        flg_aggregate_data VARCHAR2(1 CHAR), --Y-the data should be aggregated. N- otherwise
        tbl_tasks          t_table_tasks,
        flg_update_ranks   VARCHAR2(1 CHAR),
        flg_scope          VARCHAR2(1 CHAR),
        flg_group_type    VARCHAR2(1 CHAR));

    TYPE t_table_dblock_det IS TABLE OF t_rec_dblock_det INDEX BY BINARY_INTEGER; --index: id_epis_pn_det

    TYPE t_note_struct IS RECORD(
        id_epis_pn       epis_pn.id_epis_pn%TYPE,
        id_episode       episode.id_episode%TYPE,
        id_professional  professional.id_professional%TYPE,
        dt_pn_date       epis_pn.dt_pn_date%TYPE,
        id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE,
        id_pn_note_type  pn_note_type.id_pn_note_type%TYPE,
        id_pn_area       pn_area.id_pn_area%TYPE,
        flg_auto_saved   epis_pn.flg_auto_saved%TYPE,
        flg_create       VARCHAR2(1 CHAR), --Y - new note to be create. N-note to be updated
        dt_proposed      epis_pn.dt_proposed%TYPE,
        tbl_dblock_det   t_table_dblock_det);

    TYPE t_tasks_groups_by_type IS TABLE OF table_number INDEX BY BINARY_INTEGER; --task group id

    TYPE t_rec_task_desc IS RECORD(
        task_desc      epis_pn_det_task.pn_note%TYPE,
        task_desc_long epis_pn_det_task.pn_note%TYPE,
        task_title     epis_pn_det_task.pn_note%TYPE);

    TYPE t_tasks_descs IS TABLE OF t_rec_task_desc INDEX BY BINARY_INTEGER; --id_task

    TYPE t_tasks_descs_by_type IS TABLE OF t_tasks_descs INDEX BY BINARY_INTEGER;
    -------
    TYPE t_rec_task_action IS RECORD(
        id_task    epis_pn_det_task.id_task%TYPE,
        flg_action epis_pn_det_task.flg_action%TYPE);

    TYPE t_table_task_action IS TABLE OF t_rec_task_action;

    TYPE t_tasks_by_task_type IS TABLE OF t_table_task_action INDEX BY BINARY_INTEGER; --id_task_type

    TYPE t_tasks_by_dblock IS TABLE OF t_tasks_by_task_type INDEX BY BINARY_INTEGER; --id_pn_data_block

    TYPE t_tasks_by_sblock IS TABLE OF t_tasks_by_dblock INDEX BY BINARY_INTEGER; --id_pn_soap_block

    -----
    TYPE t_tab_templ_scores IS TABLE OF VARCHAR2(4000) INDEX BY BINARY_INTEGER; --id_epis_documentation

-- Public constant declarations

-- Public variable declarations

-- Public function and procedure declarations    

END pk_prog_notes_types;
/
