-- CHANGED BY:  Nuno Neves
-- CHANGE DATE: 02/03/2012 12:11
-- CHANGE REASON: [ALERT-221432] 
DECLARE
    l_id_icnp_epis_diag_interv table_number;
    l_id_icnp_epis_diag        table_number;
    l_id_icnp_epis_interv      table_number;
    l_flg_status               table_varchar;
    l_dt_inactivation          table_date;
    l_dt_hist                  TIMESTAMP(6)
        WITH LOCAL TIME ZONE;
    l_table                    table_varchar;
    l_count number;

BEGIN

    l_dt_hist := current_timestamp;
    select count(*)
    into l_count
    from icnp_epis_dg_int_hist iedih;

    
    if l_count=0 then
      
    update icnp_epis_diag_interv iedi
    set iedi.flg_moment_assoc='C';

    SELECT i.id_icnp_epis_diag_interv, i.id_icnp_epis_diag, i.id_icnp_epis_interv, i.flg_status, i.dt_inactivation bulk collect
      INTO l_id_icnp_epis_diag_interv, l_id_icnp_epis_diag, l_id_icnp_epis_interv, l_flg_status, l_dt_inactivation
      FROM icnp_epis_diag_interv i;

    FOR i IN 1 .. l_id_icnp_epis_diag_interv.count
    LOOP
        ts_icnp_epis_dg_int_hist.ins(id_icnp_epis_dg_int_hist_in => ts_icnp_epis_dg_int_hist.next_key,
                                     id_icnp_epis_diag_interv_in => l_id_icnp_epis_diag_interv(i),
                                     id_icnp_epis_diag_in        => l_id_icnp_epis_diag(i),
                                     id_icnp_epis_interv_in      => l_id_icnp_epis_interv(i),
                                     flg_status_in               => l_flg_status(i),
                                     dt_inactivation_in          => l_dt_inactivation(i),
                                     dt_hist_in                  => l_dt_hist,
                                     flg_iud_in                  => 'I',
                                     flg_moment_assoc_in         => 'C',
                                     rows_out                    => l_table);
    END LOOP;
    end if;
    commit;
END;
-- CHANGE END:  Nuno Neves

-- CHANGED BY:  Nuno Neves
-- CHANGE DATE: 02/03/2012 14:31
-- CHANGE REASON: [ALERT-221432] 
DECLARE
    l_id_icnp_epis_diag_interv table_number;
    l_id_icnp_epis_diag        table_number;
    l_id_icnp_epis_interv      table_number;
    l_flg_status               table_varchar;
    l_dt_inactivation          table_date;
    l_dt_hist                  TIMESTAMP(6)
        WITH LOCAL TIME ZONE;
    l_table                    table_varchar;
    l_count number;

BEGIN

    l_dt_hist := current_timestamp;
    select count(*)
    into l_count
    from icnp_epis_dg_int_hist iedih;

    
    if l_count=0 then
      
    update icnp_epis_diag_interv iedi
    set iedi.flg_moment_assoc='C';

    SELECT i.id_icnp_epis_diag_interv, i.id_icnp_epis_diag, i.id_icnp_epis_interv, i.flg_status, i.dt_inactivation bulk collect
      INTO l_id_icnp_epis_diag_interv, l_id_icnp_epis_diag, l_id_icnp_epis_interv, l_flg_status, l_dt_inactivation
      FROM icnp_epis_diag_interv i;

    FOR i IN 1 .. l_id_icnp_epis_diag_interv.count
    LOOP
        ts_icnp_epis_dg_int_hist.ins(id_icnp_epis_dg_int_hist_in => ts_icnp_epis_dg_int_hist.next_key,
                                     id_icnp_epis_diag_interv_in => l_id_icnp_epis_diag_interv(i),
                                     id_icnp_epis_diag_in        => l_id_icnp_epis_diag(i),
                                     id_icnp_epis_interv_in      => l_id_icnp_epis_interv(i),
                                     flg_status_in               => l_flg_status(i),
                                     dt_inactivation_in          => l_dt_inactivation(i),
                                     dt_hist_in                  => l_dt_hist,
                                     flg_iud_in                  => 'I',
                                     flg_moment_assoc_in         => 'C',
                                     rows_out                    => l_table);
    END LOOP;
    end if;
    commit;
END;
/
-- CHANGE END:  Nuno Neves