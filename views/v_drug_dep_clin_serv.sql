-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 15/07/2011
-- CHANGE REASON: ALERT-185868
CREATE OR REPLACE VIEW V_DRUG_DEP_CLIN_SERV AS
SELECT ddcs.id_drug,
               ddcs.vers,
               ddcs.id_software,
               ddcs.id_institution,
               ddcs.flg_type,
               ddcs.rank,
               ddcs.flg_take_type,
               ddcs.takes,
               ddcs.interval,
               ddcs.qty_inst,
               ddcs.unit_measure_inst,
               ddcs.frequency,
               ddcs.unit_measure_freq,
               ddcs.duration,
               ddcs.unit_measure_dur,
               ------------------------
               mm.med_descr,
               mm.short_med_descr,
               mm.flg_type mm_flg_type,
               mm.id_drug_brand,
               mm.dci_id,
               mm.dci_descr,
               mm.form_farm_id,
               mm.form_farm_descr,
               mm.qt_dos_comp,
               mm.unit_dos_comp,
               mm.flg_justify,
               mm.route_descr,
							 mm.route_id,
							 mm.med_descr_formated
          FROM drug_dep_clin_serv ddcs
          JOIN mi_med mm
            ON (mm.id_drug = ddcs.id_drug AND mm.vers = ddcs.vers);
-- CHANGE END: Pedro Teixeira