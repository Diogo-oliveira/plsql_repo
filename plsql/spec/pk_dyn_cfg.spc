CREATE OR REPLACE PACKAGE pk_dyn_cfg AS

    PROCEDURE ins_mkt_rel
    (
        i_row      IN ds_cmpt_mkt_rel%ROWTYPE,
        i_validate IN BOOLEAN DEFAULT TRUE
    );

    PROCEDURE ins_comp
    (
        i_row      IN ds_component%ROWTYPE,
        i_validate IN BOOLEAN DEFAULT TRUE
    );

    PROCEDURE ins_event_target
    (
        i_row      IN ds_event_target%ROWTYPE,
        i_validate IN BOOLEAN DEFAULT TRUE
    );

    PROCEDURE ins_event
    (
        i_row      IN ds_event%ROWTYPE,
        i_validate IN BOOLEAN DEFAULT TRUE
    );

    PROCEDURE ins_def_event
    (
        i_row      IN ds_def_event%ROWTYPE,
        i_validate IN BOOLEAN DEFAULT TRUE
    );

END pk_dyn_cfg;
/
