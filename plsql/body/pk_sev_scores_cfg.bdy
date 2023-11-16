/*-- Last Change Revision: $Rev: 2027716 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:05 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sev_scores_cfg IS

    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- ***********************
    PROCEDURE ins_score(i_row IN mtos_score%ROWTYPE) IS
        l_id VARCHAR2(0200 CHAR);
        xrow mtos_score%ROWTYPE := i_row;
        k_code_mtos_score     CONSTANT VARCHAR2(0200 CHAR) := 'MTOS_SCORE.CODE_MTOS_SCORE.';
        k_code_mtos_score_abb CONSTANT VARCHAR2(0200 CHAR) := 'MTOS_SCORE.CODE_MTOS_SCORE_ABBREV.';
    BEGIN
    
        l_id                        := to_char(xrow.id_mtos_score);
        xrow.code_mtos_score        := k_code_mtos_score || l_id;
        xrow.code_mtos_score_abbrev := k_code_mtos_score_abb || l_id;
        xrow.internal_name          := REPLACE(upper(xrow.internal_name), chr(32), '_');
    
        INSERT INTO mtos_score
            (id_mtos_score,
             code_mtos_score,
             internal_name,
             flg_score_type,
             flg_available,
             rank,
             id_content,
             code_mtos_score_abbrev,
             screen_name,
             flg_viewer)
        VALUES
            (l_id,
             xrow.code_mtos_score,
             xrow.internal_name,
             xrow.flg_score_type,
             xrow.flg_available,
             xrow.rank,
             xrow.id_content,
             xrow.code_mtos_score_abbrev,
             xrow.screen_name,
             xrow.flg_viewer);
    
    END ins_score;

    PROCEDURE ins_score_relation(i_row IN mtos_score_relation%ROWTYPE) IS
    BEGIN
    
        INSERT INTO mtos_score_relation
            (id_mtos_score, id_mtos_score_rel, flg_relation)
        VALUES
            (i_row.id_mtos_score, i_row.id_mtos_score_rel, i_row.flg_relation);
    
    END ins_score_relation;

    PROCEDURE ins_scores_market(i_row IN mtos_score_market%ROWTYPE) IS
    BEGIN
    
        INSERT INTO mtos_score_market
            (id_mtos_score, id_market, gender, age_min, age_max, height, id_software)
        VALUES
            (i_row.id_mtos_score,
             i_row.id_market,
             i_row.gender,
             i_row.age_min,
             i_row.age_max,
             i_row.height,
             i_row.id_software);
    END ins_scores_market;

    PROCEDURE ins_score_group(i_row IN mtos_score_group%ROWTYPE) IS
        l_row mtos_score_group%ROWTYPE := i_row;
        k_code_score_group CONSTANT VARCHAR2(0100 CHAR) := 'MTOS_SCORE_GROUP.CODE_MTOS_SCORE_GROUP.';
    BEGIN
    
        l_row.code_mtos_score_group := k_code_score_group || to_char(l_row.id_mtos_score_group);
    
        INSERT INTO mtos_score_group
            (id_mtos_score_group,
             internal_name,
             code_mtos_score_group,
             id_mtos_score,
             rank,
             flg_mandatory,
             flg_exclusive_parameters)
        VALUES
            (l_row.id_mtos_score_group,
             l_row.internal_name,
             l_row.code_mtos_score_group,
             l_row.id_mtos_score,
             l_row.rank,
             l_row.flg_mandatory,
             l_row.flg_exclusive_parameters);
    
    END ins_score_group;

    PROCEDURE ins_param(i_row IN mtos_param%ROWTYPE) IS
        l_row mtos_param%ROWTYPE := i_row;
        k_code CONSTANT VARCHAR2(0100 CHAR) := 'MTOS_PARAM.CODE_MTOS_PARAM.';
    BEGIN
    
        l_row.code_mtos_param := k_code || i_row.id_mtos_param;
        l_row.internal_name   := REPLACE(upper(i_row.internal_name), chr(32), '_');
    
        INSERT INTO mtos_param
            (id_mtos_param,
             id_mtos_score,
             code_mtos_param,
             internal_name,
             flg_available,
             rank,
             flg_fill_type,
             id_vital_sign,
             id_mtos_relation,
             id_content,
             id_mtos_score_group,
             val_min,
             val_max,
             format_num,
             flg_mandatory,
             flg_param_task_type,
             id_param_task)
        VALUES
            (l_row.id_mtos_param,
             l_row.id_mtos_score,
             l_row.code_mtos_param,
             l_row.internal_name,
             l_row.flg_available,
             l_row.rank,
             l_row.flg_fill_type,
             l_row.id_vital_sign,
             l_row.id_mtos_relation,
             l_row.id_content,
             l_row.id_mtos_score_group,
             l_row.val_min,
             l_row.val_max,
             l_row.format_num,
             l_row.flg_mandatory,
             l_row.flg_param_task_type,
             l_row.id_param_task);
    
    END ins_param;

    PROCEDURE ins_param_value(i_row IN mtos_param_value%ROWTYPE) IS
        l_row  mtos_param_value%ROWTYPE := i_row;
        k_code VARCHAR2(0200 CHAR) := 'MTOS_PARAM_VALUE.CODE_MTOS_PARAM_VALUE.';
    BEGIN
    
        l_row.code_mtos_param_value := k_code || to_char(l_row.id_mtos_param_value);
        l_row.flg_available         := 'Y';
        l_row.internal_name         := REPLACE(upper(i_row.internal_name), chr(32), '_');
    
        INSERT INTO mtos_param_value
            (id_mtos_param_value,
             id_mtos_param,
             code_mtos_param_value,
             VALUE,
             rank,
             flg_available,
             id_vital_sign,
             vs_min_val,
             vs_max_val,
             id_vital_sign_desc,
             id_content,
             id_unit_measure,
             color,
             extra_score,
             flg_param_task_type,
             id_param_task,
             param_task_min_val,
             param_task_max_val,
             age_min,
             age_max,
             internal_name)
        VALUES
            (l_row.id_mtos_param_value,
             l_row.id_mtos_param,
             l_row.code_mtos_param_value,
             l_row.value,
             l_row.rank,
             l_row.flg_available,
             l_row.id_vital_sign,
             l_row.vs_min_val,
             l_row.vs_max_val,
             l_row.id_vital_sign_desc,
             l_row.id_content,
             l_row.id_unit_measure,
             l_row.color,
             l_row.extra_score,
             l_row.flg_param_task_type,
             l_row.id_param_task,
             l_row.param_task_min_val,
             l_row.param_task_max_val,
             l_row.age_min,
             l_row.age_max,
             l_row.internal_name);
    
    END ins_param_value;

    -- *************************************************************
    PROCEDURE initialize IS
    BEGIN
        pk_alertlog.who_am_i(owner => g_owner, name => g_package);
        pk_alertlog.log_init(object_name => g_package);
    END initialize;

BEGIN
    initialize();
END pk_sev_scores_cfg;
/
