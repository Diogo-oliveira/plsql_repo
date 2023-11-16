-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 14/04/2011 
-- CHANGE REASON: [ALERT-173188] 

DECLARE
    TYPE tab_adm_ind_hist IS TABLE OF adm_indication_hist%ROWTYPE;

    l_tab_adm_ind_hist tab_adm_ind_hist;

    l_error     t_error_out;
    l_error_msg VARCHAR2(4000);

BEGIN
    SELECT aih.* BULK COLLECT
      INTO l_tab_adm_ind_hist
      FROM adm_indication_hist aih;

    IF (l_tab_adm_ind_hist.exists(1))
    THEN
        FOR rec IN 1 .. l_tab_adm_ind_hist.count
        LOOP
            IF (l_tab_adm_ind_hist(rec).dcs_ids IS NOT NULL AND l_tab_adm_ind_hist(rec).dcs_ids.exists(1))
            THEN
                FOR i IN 1 .. l_tab_adm_ind_hist(rec).dcs_ids.count
                LOOP
                    INSERT INTO adm_ind_dcs_hist
                        (id_adm_indication_hist, id_adm_indication, id_dep_clin_serv, flg_available, flg_pref)
                    VALUES
                        (l_tab_adm_ind_hist(rec).id_adm_indication_hist,
                         l_tab_adm_ind_hist(rec).id_adm_indication,
                         l_tab_adm_ind_hist(rec).dcs_ids(i),
                         l_tab_adm_ind_hist(rec).flg_available,
                         decode(l_tab_adm_ind_hist(rec).preferred_dcs_id, l_tab_adm_ind_hist(rec).dcs_ids(i), 'Y', 'N'));
                END LOOP;
            END IF;
        
            IF (l_tab_adm_ind_hist(rec).escape_dcs_ids IS NOT NULL AND l_tab_adm_ind_hist(rec).escape_dcs_ids.exists(1))
            THEN
                FOR j IN 1 .. l_tab_adm_ind_hist(rec).escape_dcs_ids.count
                LOOP
                    INSERT INTO escape_department_hist
                        (id_adm_indication_hist, id_department, id_adm_indication)
                    VALUES
                        (l_tab_adm_ind_hist(rec).id_adm_indication_hist,
                         l_tab_adm_ind_hist(rec).escape_dcs_ids(j),
                         l_tab_adm_ind_hist(rec).id_adm_indication);
                END LOOP;
            END IF;
        END LOOP;
    END IF;
END;
/
