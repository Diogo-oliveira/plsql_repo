CREATE OR REPLACE VIEW V_NEW_BORN_INFO AS
SELECT t.id_epis_documentation,
       id_episode,
       id_epis_doc_det_name,
       newborn_name,
       id_epis_doc_det_dt_birth,
       dt_birth,
       id_epis_doc_det_weight,
       ppf.weight weight,
       t.id_unit_measure,
       id_epis_doc_det_gender,
       decode(gender, 'Male', 'M', 'Female', 'F', 'U') AS flg_gender,
       gender,
       id_epis_doc_det_status,
       decode(newborn_status, NULL, NULL, 'Liveborn', 'A', 'D') AS flg_status,
       newborn_status AS status,
       birth_type AS delivery_type,
       t.id_pat_preg AS id_pat_pregnancy,
       notes,
       id_cancel_reason,
       notes_cancel,
       edd.child_number AS child_number,
       edd.id_child_episode
  FROM (SELECT ede_n.id_epis_documentation,
               ed.id_episode,
               ede_n.id_epis_documentation_det AS id_epis_doc_det_name,
               ede_n.value AS "NEWBORN_NAME",
               ede_dt.id_epis_documentation_det AS id_epis_doc_det_dt_birth,
               (CAST(to_timestamp(substr(ede_dt.value, 1, 14), substr(ede_dt.value, 16, 17)) AS TIMESTAMP(6) WITH LOCAL TIME ZONE)) AS "DT_BIRTH",
               ede_weight.id_epis_documentation_det AS id_epis_doc_det_weight,
               ede_weight.value AS weight,
               nvl2(ede_weight.value,
                    (SELECT ppf.id_unit_measure
                       FROM pat_pregn_fetus ppf
                      WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                        AND ppf.id_unit_measure IS NOT NULL
                        AND rownum = 1),
                    NULL) AS id_unit_measure,
               ede_gender.id_epis_documentation_det AS id_epis_doc_det_gender,
               (SELECT pk_translation.get_translation(13, c.code_element_open)
                  FROM alert.doc_element_crit c
                 WHERE c.id_doc_element_crit = ede_gender.id_doc_element_crit) AS gender,
               ede_status.id_epis_documentation_det AS id_epis_doc_det_status,
               nvl(ede_status.value,
                   (SELECT pk_translation.get_translation(13, c.code_element_open)
                      FROM alert.doc_element_crit c
                     WHERE c.id_doc_element_crit = ede_status.id_doc_element_crit)) AS newborn_status,
               pp.id_pat_pregnancy AS id_pat_preg,
               ed.notes AS notes,
               ed.id_cancel_reason AS id_cancel_reason,
               ed.notes_cancel AS notes_cancel,
               (SELECT d_ext.flg_value
                  FROM documentation_ext d_ext
                 WHERE d_ext.id_doc_element IN
                       (SELECT d_element.id_doc_element
                          FROM doc_element d_element
                         WHERE d_element.id_documentation = ede_birth_type.id_documentation)
                   AND d_ext.value = ede_birth_type.id_doc_element_crit) AS birth_type,
               row_number() over(PARTITION BY ed.id_episode, pp.id_pat_pregnancy ORDER BY ede_n.id_epis_documentation ASC) AS rn
          FROM epis_documentation_det ede_n
          JOIN documentation d
            ON d.id_documentation = ede_n.id_documentation
          JOIN epis_documentation ed
            ON ed.id_epis_documentation = ede_n.id_epis_documentation
          JOIN epis_documentation_det ede_dt
            ON ede_dt.id_epis_documentation = ede_n.id_epis_documentation
           AND ede_dt.id_documentation IN
               (SELECT id_documentation
                  FROM documentation
                 WHERE id_doc_component IN (SELECT dc.id_doc_component
                                              FROM doc_component dc
                                             WHERE dc.id_content = 'TPT.C.2324') /*ID_DT_BIRTH*/
                )
          LEFT JOIN epis_documentation_det ede_weight
            ON ede_weight.id_epis_documentation = ede_n.id_epis_documentation
           AND ede_weight.id_documentation IN
               (SELECT id_documentation
                  FROM documentation
                 WHERE id_doc_component IN (SELECT dc.id_doc_component
                                              FROM doc_component dc
                                             WHERE dc.id_content = 'TPT.C.2327') /*WEIGHT*/
                )
          LEFT JOIN epis_documentation_det ede_gender
            ON ede_gender.id_epis_documentation = ede_n.id_epis_documentation
           AND ede_gender.id_documentation IN
               (SELECT id_documentation
                  FROM documentation
                 WHERE id_doc_component IN (SELECT dc.id_doc_component
                                              FROM doc_component dc
                                             WHERE dc.id_content = 'TPT.C.15121') /*GENDER*/
                )        
          LEFT JOIN epis_documentation_det ede_status
            ON ede_status.id_epis_documentation = ede_n.id_epis_documentation
           AND ede_status.id_documentation IN
               (SELECT id_documentation
                  FROM documentation
                 WHERE id_doc_component IN (SELECT dc.id_doc_component
                                              FROM doc_component dc
                                             WHERE dc.id_content = 'TPT.C.2325') /*STATUS*/
                )        
          LEFT JOIN epis_documentation_det ede_status
            ON ede_status.id_epis_documentation = ede_n.id_epis_documentation
           AND ede_status.id_documentation IN
               (SELECT id_documentation
                  FROM documentation
                 WHERE id_doc_component IN (SELECT dc.id_doc_component
                                              FROM doc_component dc
                                             WHERE dc.id_content = 'TPT.C.2325') /*STATUS*/
                )        
          LEFT JOIN epis_documentation_det ede_birth_type
            ON ede_birth_type.id_epis_documentation = ede_n.id_epis_documentation
           AND ede_birth_type.id_documentation IN
               (SELECT id_documentation
                  FROM documentation
                 WHERE id_doc_component IN (SELECT dc.id_doc_component
                                              FROM doc_component dc
                                             WHERE dc.id_content = 'TPT.C.134079') /*BIRTH_TYPE*/
                )        
          JOIN pat_pregnancy pp
            ON pp.id_episode = ed.id_episode
           AND pp.flg_status = 'P'
         WHERE d.id_doc_component IN (SELECT dc.id_doc_component
                                        FROM doc_component dc
                                       WHERE dc.id_content = 'TPT.C.2323')
           AND d.flg_available = 'Y'
           AND ed.flg_status = 'A') t
  LEFT JOIN epis_doc_delivery edd
    ON edd.id_epis_documentation = t.id_epis_documentation
  LEFT JOIN pat_pregn_fetus ppf
    ON ppf.id_pat_pregnancy = t.id_pat_preg
   AND ppf.fetus_number = edd.fetus_number;