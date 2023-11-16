-- CHANGED BY: Vanessa Barsottelli
-- CHANGE DATE: 17/01/2017 15:36
-- CHANGE REASON: [ALERT-326926] 
INSERT INTO epis_prognosis(id_epis_prognosis,id_episode,flg_status,prognosis_notes,id_prof_create,dt_create)
SELECT seq_epis_prognosis.nextval, ep.id_episode, epd.flg_status, epd.pn_note, epd.id_professional, epd.dt_pn
  FROM epis_pn ep
  JOIN epis_pn_det epd
    ON epd.id_epis_pn = ep.id_epis_pn
 WHERE ep.flg_status IN ('D', 'F')
   AND epd.id_pn_soap_block = 50
   AND epd.flg_status = 'A'
   AND NOT EXISTS (SELECT 1
          FROM epis_prognosis p
         WHERE p.id_episode = ep.id_episode
           AND p.dt_create = epd.dt_pn);
-- CHANGE END: Vanessa Barsottelli