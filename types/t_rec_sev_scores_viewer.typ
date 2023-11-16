-- CHANGED BY: Mário Mineiro
-- CHANGE DATE: 23/08/2013
-- CHANGE REASON: ALERT_262898 - NEWS / PEWS / PARKLAND
create or replace type t_rec_sev_scores_viewer as object (

        id_mtos_score         number(24),
        id_mtos_param           number(24),
        id_vital_sign           number(24),
        param_desc           varchar2(1000),
        desc_unit_measure      varchar2(1000),
        registered_value      number(24),
        registered_value_desc varchar2(1000),
        score_unit            number(24),
        score_color          varchar2(1000)
        )
/