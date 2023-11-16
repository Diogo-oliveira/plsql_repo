/*-- Last Change Revision: $Rev: 2028972 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:03 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sev_scores_cfg IS

    -- ***********************
    PROCEDURE ins_score(i_row IN mtos_score%ROWTYPE);

    PROCEDURE ins_score_relation(i_row IN mtos_score_relation%ROWTYPE);

    PROCEDURE ins_scores_market(i_row IN mtos_score_market%ROWTYPE);

    PROCEDURE ins_score_group(i_row IN mtos_score_group%ROWTYPE);

    PROCEDURE ins_param(i_row IN mtos_param%ROWTYPE);

    PROCEDURE ins_param_value(i_row IN mtos_param_value%ROWTYPE);

    PROCEDURE initialize;

END pk_sev_scores_cfg;

/


