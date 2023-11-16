DECLARE
    l_flg_pat_cond_old CONSTANT discharge_detail.flg_pat_condition%TYPE := 'U';
    l_flg_pat_cond_new CONSTANT discharge_detail.flg_pat_condition%TYPE := 'Y';

    CURSOR c_disch_status IS
        SELECT d.id_discharge
          FROM discharge d
          JOIN episode e ON e.id_episode = d.id_episode
          JOIN discharge_hist dh ON dh.id_discharge = d.id_discharge
          JOIN discharge_detail_hist ddh ON ddh.id_discharge_hist = dh.id_discharge_hist
          JOIN disch_reas_dest drd ON drd.id_disch_reas_dest = dh.id_disch_reas_dest
          JOIN discharge_reason dr ON dr.id_discharge_reason = drd.id_discharge_reason
          JOIN profile_disch_reason pdr ON pdr.id_discharge_reason = drd.id_discharge_reason
                                       AND pdr.id_institution = e.id_institution
                                       AND pdr.id_profile_template = dh.id_profile_template
         WHERE ddh.flg_pat_condition = l_flg_pat_cond_old
         ORDER BY dh.dt_created_hist DESC;

    r_disch_status c_disch_status%ROWTYPE;

    l_total_updated_dd  PLS_INTEGER := 0;
    l_total_updated_ddh PLS_INTEGER := 0;
BEGIN
    OPEN c_disch_status;

    LOOP
        FETCH c_disch_status
            INTO r_disch_status;
        EXIT WHEN c_disch_status%NOTFOUND;
    
        UPDATE discharge_detail dd
           SET dd.flg_pat_condition = l_flg_pat_cond_new
         WHERE dd.id_discharge = r_disch_status.id_discharge
           AND dd.flg_pat_condition = l_flg_pat_cond_old;
    
        l_total_updated_dd := l_total_updated_dd + SQL%ROWCOUNT;
    
        UPDATE discharge_detail_hist ddh
           SET ddh.flg_pat_condition = l_flg_pat_cond_new
         WHERE ddh.id_discharge = r_disch_status.id_discharge
           AND ddh.flg_pat_condition = l_flg_pat_cond_old;
    
        l_total_updated_ddh := l_total_updated_ddh + SQL%ROWCOUNT;
    END LOOP;

    CLOSE c_disch_status;

    dbms_output.put_line('Updated ' || l_total_updated_dd || ' discharge_detail.');
    dbms_output.put_line('Updated ' || l_total_updated_ddh || ' discharge_detail_hist.');

    COMMIT;
END;
/
