-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 14/04/2011 
-- CHANGE REASON: [ALERT-173188] 

DECLARE
    TYPE tab_bed_hist IS TABLE OF bed_hist%ROWTYPE;

    l_tab_bed_hist tab_bed_hist;

    l_error     t_error_out;   
BEGIN
    SELECT bh.* BULK COLLECT
      INTO l_tab_bed_hist
      FROM bed_hist bh;

    IF (l_tab_bed_hist.exists(1))
    THEN
        FOR rec IN 1 .. l_tab_bed_hist.count
        LOOP
            IF (l_tab_bed_hist(rec).dcs_ids IS NOT NULL AND l_tab_bed_hist(rec).dcs_ids.exists(1))
            THEN
                FOR i IN 1 .. l_tab_bed_hist(rec).dcs_ids.count
                LOOP
                    INSERT INTO bed_dep_clin_serv_hist (id_bed_hist, id_bed, id_dep_clin_serv, flg_available)
                    VALUES
                        (l_tab_bed_hist(rec).id_bed_hist,
                         l_tab_bed_hist(rec).id_bed,
                         l_tab_bed_hist(rec).dcs_ids(i),
                         l_tab_bed_hist(rec).flg_available);
                END LOOP;
            END IF;
        END LOOP;
    END IF;
END;
/
