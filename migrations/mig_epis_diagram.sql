-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 11/11/2017 15:30
-- CHANGE REASON: [CALERT_33] Body diagrams improvements
UPDATE epis_diagram ed1
   SET ed1.dt_last_update_tstz =
       (SELECT MAX(eddn.dt_notes_tstz)
          FROM epis_diagram ed2
          JOIN epis_diagram_layout edl
            ON ed2.id_epis_diagram = edl.id_epis_diagram
          LEFT JOIN epis_diagram_detail edd
            ON edl.id_epis_diagram_layout = edd.id_epis_diagram_layout
          LEFT JOIN epis_diagram_detail_notes eddn
            ON edd.id_epis_diagram_detail = eddn.id_epis_diagram_detail
         WHERE edl.flg_status <> 'D'
           AND ed2.id_epis_diagram = ed1.id_epis_diagram)
 WHERE ed1.flg_status = 'C';
-- CHANGE END: rui.mendonca
