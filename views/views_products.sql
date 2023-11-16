CREATE OR REPLACE VIEW SAEH_PRODUCTS
AS
SELECT pk_adt.get_clues_code(i_id_clues => NULL, i_id_institution => ia.id_institution) clues,
       e.id_episode folio,
       e.dt_end_tstz egreso,
       ppf.fetus_number numproducto,
       pk_delivery.get_delivery_value(i_lang          => 17,
                                      i_prof          => NULL,
                                      i_patient       => pp.id_patient,
                                      i_pat_pregnancy => pp.id_pat_pregnancy,
                                      i_child_number  => edd.child_number,
                                      i_doc_area      => 1048,
                                      i_doc_int_name  => 'PESO',
                                      i_show_internal => 'Y') pesoprod,
       --  ppf.weight pesoprod,
       ppf.flg_gender sexprod,
       pk_delivery.get_delivery_value(i_lang          => 17,
                                      i_prof          => NULL,
                                      i_patient       => pp.id_patient,
                                      i_pat_pregnancy => pp.id_pat_pregnancy,
                                      i_child_number  => edd.child_number,
                                      i_doc_area      => 1048,
                                      i_doc_int_name  => 'ESTADO',
                                      i_show_internal => 'Y') condnac,
       pc.code_birth_certificate certificado,
       decode(ppf.flg_status, 'D', ppf.flg_status,'SI','U', dn.flg_condition) condegre, -- CASO MORTE FETAL VIA PARTAGORAMA OU ABORTO PREENCHE COM D 
       pk_delivery.get_delivery_value(i_lang          => 17,
                                      i_prof          => NULL,
                                      i_patient       => pc.id_patient,
                                      i_pat_pregnancy => NULL,
                                      i_child_number  => NULL,
                                      i_doc_area      => 52,
                                      i_doc_int_name  => 'APGAR',
                                      i_show_internal => 'Y') naviapag,
       pk_delivery.get_delivery_value(i_lang          => 17,
                                      i_prof          => NULL,
                                      i_patient       => pc.id_patient,
                                      i_pat_pregnancy => NULL,
                                      i_child_number  => NULL,
                                      i_doc_area      => 52,
                                      i_doc_int_name  => 'REANIM_NEO',
                                      i_show_internal => 'Y') naviarean,
       pk_delivery.get_delivery_value(i_lang          => 17,
                                      i_prof          => NULL,
                                      i_patient       => pc.id_patient,
                                      i_pat_pregnancy => NULL,
                                      i_child_number  => NULL,
                                      i_doc_area      => 52,
                                      i_doc_int_name  => 'CUN') navicune,
       pk_delivery.get_delivery_value(i_lang          => 17,
                                      i_prof          => NULL,
                                      i_patient       => pp.id_patient,
                                      i_pat_pregnancy => pp.id_pat_pregnancy,
                                      i_child_number  => edd.child_number,
                                      i_doc_area      => 1048,
                                      i_doc_int_name  => 'TIPO_NAC',
                                      i_show_internal => 'Y') tipnaci,
       e.id_institution
  FROM pat_pregn_fetus ppf
 INNER JOIN pat_pregnancy pp
    ON ppf.id_pat_pregnancy = pp.id_pat_pregnancy
 INNER JOIN episode e
    ON pp.id_patient = e.id_patient
 INNER JOIN episode epp
    ON pp.id_episode = epp.id_episode
 INNER JOIN institution ia
    ON e.id_institution = ia.id_institution
  JOIN (SELECT edd.id_epis_documentation,
               edd.id_pat_pregnancy,
               edd.child_number,
               id_child_episode,
               row_number() over(PARTITION BY edd.id_pat_pregnancy, edd.child_number ORDER BY edd.child_number, edd.id_child_episode DESC NULLS LAST) rn
          FROM epis_doc_delivery edd
         WHERE edd.child_number IS NOT NULL) edd
    ON edd.id_pat_pregnancy = pp.id_pat_pregnancy
   AND edd.child_number = ppf.fetus_number
   AND edd.rn = 1
  JOIN epis_documentation ed
    ON edd.id_epis_documentation = ed.id_epis_documentation
  LEFT JOIN episode ec
    ON ec.id_episode = edd.id_child_episode
  LEFT JOIN patient pc
    ON ec.id_patient = pc.id_patient
  LEFT JOIN alert.discharge_newborn dn
    ON dn.id_pat_pregnancy = pp.id_pat_pregnancy
   AND dn.id_episode = ec.id_episode
 WHERE pp.flg_type <> 'R'
   AND pp.flg_status NOT IN ('A', 'C')
   AND ed.flg_status <> 'C'
   AND e.id_epis_type = 5
   AND epp.id_visit = e.id_visit
   AND e.dt_end_tstz IS NOT NULL
UNION
SELECT pk_adt.get_clues_code(i_id_clues => NULL, i_id_institution => ia.id_institution) clues,
       e.id_episode folio,
       e.dt_end_tstz egreso,
       ppf.fetus_number numproducto,
       to_char(ppf.weight) pesoprod,
       ppf.flg_gender sexprod,
       CASE
           WHEN pp.flg_preg_out_type = 'AB' THEN
            'D'
           ELSE
            NULL
       END condnac,
       NULL certificado,
       NULL condegre,
       NULL naviapag,
       NULL naviarean,
       NULL navicune,
       NULL tipnaci,
       e.id_institution
  FROM pat_pregn_fetus ppf
 INNER JOIN pat_pregnancy pp
    ON ppf.id_pat_pregnancy = pp.id_pat_pregnancy
 INNER JOIN episode e
    ON pp.id_patient = e.id_patient
 INNER JOIN episode epp
    ON pp.id_episode = epp.id_episode
 INNER JOIN institution ia
    ON e.id_institution = ia.id_institution
 WHERE pp.flg_type <> 'R'
   AND pp.flg_status NOT IN ('A', 'C')
   AND e.id_epis_type = 5
   AND e.dt_end_tstz IS NOT NULL
   AND NOT EXISTS (SELECT 1
          FROM epis_doc_delivery ed
         WHERE ed.id_pat_pregnancy = pp.id_pat_pregnancy)
   AND epp.id_visit = e.id_visit;
