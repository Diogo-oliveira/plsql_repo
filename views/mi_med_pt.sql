create or replace view MI_MED_PT as 
--com CHNM
SELECT to_char(d.id_drug) id_drug,
       '<b>' || pk_translation.get_translation(1, d.code_drug) || ' </b>' med_descr_formated,
       pk_translation.get_translation(1, d.code_drug) med_descr,
       pk_translation.get_translation(1, d.code_drug) short_med_descr,    
			 d.flg_type, d.flg_available,d.flg_justify,
			 d.id_drug_brand,                                           
       d.id_drug_pharma dci_id, pk_translation.get_translation(1, dp.code_drug_pharma) dci_descr, 
       to_char(d.id_drug_form) form_farm_id, pk_translation.get_translation(1, 'DRUG_FORM.CODE_DRUG_FORM.' || d.id_drug_form) form_farm_descr, 
			 to_char(d.id_drug_route) route_id, pk_translation.get_translation(1, 'DRUG_ROUTE.CODE_DRUG_ROUTE.' || d.id_drug_route) route_descr,
       d.qty_basis qt_dos_comp, pk_translation.get_translation(1, 'UNIT_MEASURE.CODE_UNIT_MEASURE.'||id_unit_measure) unit_dos_comp, 
       d.qty_basis||' '||pk_translation.get_translation(1, 'UNIT_MEASURE.CODE_UNIT_MEASURE.'||d.id_unit_measure) dosagem, 
			 dr.gender, dr.age_min, dr.age_max,
       d.mdm_coding, d.chnm_id,
	     d.flg_mix_fluid,d.id_unit_measure,d.notes,
       'PT' vers
FROM drug d, drug_pharma dp, drug_route dr    
where dp.id_drug_pharma = d.id_drug_pharma
  and dr.id_drug_route = d.id_drug_route
	and chnm_id is not null
UNION ALL
--sem CHNM 
SELECT to_char(d.id_drug) id_drug,
       decode(d.qty_basis, 
                                               0,
                                                '<b>' || pk_translation.get_translation(1, dp.code_drug_pharma) || ' </b> / ' ||
                                               pk_translation.get_translation(1, 'DRUG_FORM.CODE_DRUG_FORM.' || d.id_drug_form) || ' / ' ||
                                   pk_translation.get_translation(1, 'DRUG_ROUTE.CODE_DRUG_ROUTE.' || d.id_drug_route),
                                               NULL,
                                                '<b>' || pk_translation.get_translation(1, dp.code_drug_pharma) || ' </b> / ' ||
                                               pk_translation.get_translation(1, 'DRUG_FORM.CODE_DRUG_FORM.' || d.id_drug_form) || ' / ' ||
                                   pk_translation.get_translation(1, 'DRUG_ROUTE.CODE_DRUG_ROUTE.' || d.id_drug_route),
                                                '<b>' || pk_translation.get_translation(1, dp.code_drug_pharma) || ' </b> (' || d.qty_basis || d.measure_unit || ') / ' ||
                                               pk_translation.get_translation(1, 'DRUG_FORM.CODE_DRUG_FORM.' || d.id_drug_form) || ' / ' ||
                                   pk_translation.get_translation(1, 'DRUG_ROUTE.CODE_DRUG_ROUTE.' || d.id_drug_route))  med_descr_formated,
       decode(d.qty_basis, 
                                               0,
                                               pk_translation.get_translation(1, dp.code_drug_pharma) || ' / ' ||
                                               pk_translation.get_translation(1, 'DRUG_FORM.CODE_DRUG_FORM.' || d.id_drug_form) || ' / ' ||
                                   pk_translation.get_translation(1, 'DRUG_ROUTE.CODE_DRUG_ROUTE.' || d.id_drug_route),
                                               NULL,
                                               pk_translation.get_translation(1, dp.code_drug_pharma) || ' / ' ||
                                               pk_translation.get_translation(1, 'DRUG_FORM.CODE_DRUG_FORM.' || d.id_drug_form) || ' / ' ||
                                   pk_translation.get_translation(1, 'DRUG_ROUTE.CODE_DRUG_ROUTE.' || d.id_drug_route),
                                               pk_translation.get_translation(1, dp.code_drug_pharma) || ' (' || d.qty_basis || d.measure_unit || ') / ' ||
                                               pk_translation.get_translation(1, 'DRUG_FORM.CODE_DRUG_FORM.' || d.id_drug_form) || ' / ' ||
                                   pk_translation.get_translation(1, 'DRUG_ROUTE.CODE_DRUG_ROUTE.' || d.id_drug_route))  med_descr,
       decode(d.qty_basis, 
                                               0,
                                               pk_translation.get_translation(1, dp.code_drug_pharma),
                                               NULL,
                                               pk_translation.get_translation(1, dp.code_drug_pharma),
                                               pk_translation.get_translation(1, dp.code_drug_pharma) || ' (' || d.qty_basis || d.measure_unit || ')') short_med_descr,																							 
			 d.flg_type, d.flg_available,d.flg_justify,                                          
			 d.id_drug_brand,                                           
       d.id_drug_pharma dci_id, pk_translation.get_translation(1, dp.code_drug_pharma) dci_descr, 
       to_char(d.id_drug_form) form_farm_id, pk_translation.get_translation(1, 'DRUG_FORM.CODE_DRUG_FORM.' || d.id_drug_form) form_farm_descr,
			 to_char(d.id_drug_route) route_id, pk_translation.get_translation(1, 'DRUG_ROUTE.CODE_DRUG_ROUTE.' || d.id_drug_route) route_descr,
       d.qty_basis qt_dos_comp, pk_translation.get_translation(1, 'UNIT_MEASURE.CODE_UNIT_MEASURE.'||id_unit_measure) unit_dos_comp, 
       d.qty_basis||' '||pk_translation.get_translation(1, 'UNIT_MEASURE.CODE_UNIT_MEASURE.'||d.id_unit_measure) dosagem, 
			 dr.gender, dr.age_min, dr.age_max,
       d.mdm_coding, NULL chnm_id,
	     d.flg_mix_fluid,d.id_unit_measure,d.notes,
       'PT' vers
FROM drug d, drug_pharma dp, drug_route dr       
where dp.id_drug_pharma = d.id_drug_pharma
  and dr.id_drug_route = d.id_drug_route
	and chnm_id is null
UNION ALL
SELECT to_char(d.id_drug) id_drug,
			 '<b>' || pk_translation.get_translation(1, d.code_drug) || ' </b>'  med_descr_formated,
pk_translation.get_translation(1, d.code_drug)  med_descr,
pk_translation.get_translation(1, d.code_drug)  short_med_descr,
			 d.flg_type, d.flg_available,d.flg_justify,                                          
			 d.id_drug_brand,                                           
       d.id_drug_pharma dci_id, null as dci_descr, 
       to_char(d.id_drug_form) form_farm_id, null as form_farm_descr,
			 to_char(d.id_drug_route) route_id, null as route_descr,
       d.qty_basis qt_dos_comp, pk_translation.get_translation(1, 'UNIT_MEASURE.CODE_UNIT_MEASURE.'||id_unit_measure) unit_dos_comp, 
       d.qty_basis||' '||pk_translation.get_translation(1, 'UNIT_MEASURE.CODE_UNIT_MEASURE.'||d.id_unit_measure) dosagem, 
			 null as gender, null as age_min, null as age_max,
       d.mdm_coding, NULL chnm_id,
	     d.flg_mix_fluid,d.id_unit_measure,d.notes,
       'PT' vers
FROM drug d       
where flg_type in ('N','V','C')
and chnm_id is null
;