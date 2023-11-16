CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_UNIT_MEASURE AS
SELECT "DESC_UNIT_MEASURE", "ABBREVIATION", "ID_UNIT_MEASURE", "ENUMERATED"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), code_unit_measure)
                  FROM dual) desc_unit_measure,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      a.code_unit_measure_abrv)
                  FROM dual) abbreviation,
               a.id_unit_measure,
               a.enumerated
          FROM unit_measure a
          LEFT JOIN unit_measure_type b
            ON b.id_unit_measure_type = a.id_unit_measure_type
           AND b.flg_available = 'Y'
         WHERE a.flg_available = 'Y'
           AND a.id_unit_measure IN
               (SELECT c.id_unit_measure
                  FROM unit_mea_soft_inst c
                 WHERE c.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                   AND c.flg_available = 'Y'
                   AND c.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')))
 WHERE desc_unit_measure IS NOT NULL
 ORDER BY 1;

