CREATE OR REPLACE PACKAGE pk_access_cfg IS

    PROCEDURE ins_sbp(i_row IN sys_button_prop%ROWTYPE);

    PROCEDURE ins_btn(i_row IN sys_button%ROWTYPE);

    PROCEDURE ins_pta(i_row IN profile_templ_access%ROWTYPE);

END pk_access_cfg;
