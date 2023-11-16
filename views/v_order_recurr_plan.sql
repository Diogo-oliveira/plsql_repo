CREATE OR REPLACE VIEW V_ORDER_RECURR_PLAN
AS
 SELECT
       a.id_order_recurr_plan,
       a.id_order_recurr_area,
			 c.internal_name internal_name_area,
			 c.code_order_recurr_area,
			 a.id_order_recurr_option,
			 b.id_content OPTION_ID_CONTENT,
			 b.code_order_recurr_option, 
			 a.start_date,
       'flg' flg_include_start_dt_in_plan,
			 a.end_date,
			 a.occurrences,
			 a.duration,
			 a.id_unit_meas_duration
   FROM order_recurr_plan a
	   JOIN order_recurr_option b on a.id_order_recurr_option = b.id_order_recurr_option
		 JOIN order_recurr_area c ON c.id_order_recurr_area = a.id_order_recurr_area;
