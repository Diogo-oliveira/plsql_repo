-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 15/07/2011
-- CHANGE REASON: ALERT-185868
CREATE OR REPLACE VIEW V_EMB_DEP_CLIN_SERV AS
SELECT edcs.emb_id,
               edcs.vers,
               edcs.flg_type,
               edcs.id_institution,
               edcs.id_software,
               edcs.qty_inst,
               edcs.unit_measure_inst,
               edcs.frequency,
               edcs.unit_measure_freq,
               edcs.duration,
               edcs.unit_measure_dur,
               ------------------------
               mm.med_descr,
               mm.med_descr_formated,
               mm.dci_descr,
               mm.form_farm_descr,
               mm.generico,
               mm.qt_dos_comp,
               mm.n_units,
               mm.qt_per_unit,
               mm.disp_id,
               mm.flg_comerc,
               mm.flg_available
          FROM emb_dep_clin_serv edcs
          JOIN me_med mm
            ON (mm.emb_id = edcs.emb_id AND mm.vers = edcs.vers);
-- CHANGE END: Pedro Teixeira