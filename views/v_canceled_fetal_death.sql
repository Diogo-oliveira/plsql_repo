CREATE OR REPLACE VIEW v_canceled_fetal_death AS
SELECT
 pk_death_registry.get_death_data_folio_by_id( i_id_death_registry => id_death_registry ) DEFFOLIO
,'UNME' DEFUSU_MOD
,pk_date_utils.date_send_tsz( i_lang => 17, i_date => update_time, i_inst => id_institution, i_soft => 0    ) DEFFEC_MOD
,'3' DEFNIVCAPT
,pk_adt.get_clues_name(i_id_clues => null, i_id_institution => id_institution ) DEFINSTCAPT
,pk_adt.get_rb_reg_classifier_code( id_rb_regional_classifier,  5) DEFEDOCAPT
,pk_adt.get_clues_jurisdiction(i_id_clues => NULL, i_id_institution => id_institution) DEFJURCAPT
,pk_adt.get_rb_reg_classifier_code( id_rb_regional_classifier, 10) DEFMPOCAPT
,pk_adt.get_clues_code(i_id_clues => null, i_id_institution => id_institution ) DEFCLUESCAPT
,ID_ALERT_INSTITUTION
,ID_ALERT_MARKET
from
    (
    select
    dr.id_death_registry     id_death_registry
    ,vis.id_institution         id_institution
    ,pk_adt.get_clues_id_rb_regional(i_id_clues => NULL, i_id_institution => vis.id_institution) id_rb_regional_classifier
    ,dr.update_time update_time
	,inst.id_institution ID_ALERT_INSTITUTION
	,mkt.id_market       ID_ALERT_MARKET
    FROM death_registry dr
    join episode e on e.id_episode = dr.id_episode
    join visit vis on vis.id_visit = e.id_visit
	JOIN institution inst ON inst.id_institution = vis.id_institution
	JOIN market mkt ON inst.id_market = mkt.id_market
    WHERE dr.flg_type = 'F'
    AND dr.flg_status = 'C'
    ) xsql
;