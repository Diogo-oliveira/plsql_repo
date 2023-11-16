create or replace view v_inpgrid_opinion_base as
select distinct o.id_episode
FROM opinion o
JOIN episode e            ON o.id_episode = e.id_episode
join visit v              on v.id_visit = e.id_visit
WHERE o.id_opinion_type IS NULL
and o.flg_state != 'C'
and v.id_institution = alert_context('i_id_institution')
and o.dt_problem_tstz between
            ( pk_date_utils.trunc_insttimezone(
                      profissional( alert_context('i_id_prof'), alert_context('i_id_institution'), alert_context('i_id_software'))
                      , current_timestamp, 'DD') - numtodsinterval( alert_context('l_day_range'), 'DAY') )
            and
            -- until end of today
            (pk_date_utils.trunc_insttimezone(
                      profissional( alert_context('i_id_prof'), alert_context('i_id_institution'), alert_context('i_id_software'))
                      , current_timestamp
                      , 'DD') + numtodsinterval( 24, 'HOUR') + numtodsinterval( -1, 'SECOND'))
and o.dt_problem_tstz >=
            (pk_date_utils.trunc_insttimezone(
                      profissional( alert_context('i_id_prof'), alert_context('i_id_institution'), alert_context('i_id_software'))
                      ,  current_timestamp , 'DD')
                      - numtodsinterval( alert_context('l_day_range'), 'DAY') + numtodsinterval( alert_context('l_hour_range'), 'HOUR')  
            )
;