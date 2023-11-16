CREATE OR REPLACE VIEW V_ORDER_SETS_TO_COPY AS
SELECT odst.id_order_set,
       odst.title
              FROM order_set odst
              LEFT OUTER JOIN professional prof
                ON (odst.id_professional = prof.id_professional)
             WHERE odst.flg_status = 'F'
               AND odst.id_institution = alert_context('i_prof_institution');
