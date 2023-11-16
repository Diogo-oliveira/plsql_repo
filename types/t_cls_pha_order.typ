
create or replace type t_cls_pha_order as object (

	/*
	 * @author		Rui Marante
	 * @since		2011-02-10
	 * @version		ZANOB 0.1
	 * @notes		
	*/


	--PUBLIC PROPERTIES
		class_name				varchar2(30 char),
		--
		G_FLG_PFH				varchar2(10 char),

		db_link					varchar2(200 char),

		lang					number(24),
		inst_id					number(24),
		market_id				number(24),
		software_id				number(24),

		--patient
		pat_is_known			varchar2(1 char),
		pat_id_pha				number(24),
		pat_id					number(24),
		pat_name				varchar2(4000 char),
		pat_gender				varchar2(1 char),
		pat_id_department		number(24),
		pat_id_ward				number(24),
		pat_id_specialty		number(24),

		--professional
		--prescriber
		prof_presc_is_known		varchar2(1 char),
		prof_presc_id_pha		number(24),
		prof_presc_id			number(24),
		prof_presc_name			varchar2(4000 char),
		--prof that did the pharmacy order
		prof_order_is_known		varchar2(1 char),
		prof_order_id_pha		number(24),
		prof_order_id			number(24),
		prof_order_name			varchar2(4000 char),

		--order
		order_type				varchar2(1),
		order_presc_dt			timestamp with local time zone,
		order_request_dt		timestamp with local time zone,
		order_visit_id			number(24),
		order_episode_id		number(24),
		order_therapproto		number(24),
		order_department_id		number(24),
		order_service_id		number(24),
		order_room_id			number(24),
		order_bed_id			number(24),

		--order items
		order_item_count		number(24),
		order_item_presc_id		table_number,
		order_item_qt			table_number,
		order_item_qt_unit		table_number,
		order_item_instr		table_number,
		order_item_flg_generic	table_varchar,
		order_item_product		table_varchar,
		order_item_supplier		table_varchar,
		order_item_prod_desc	table_varchar,
		order_item_instr_desc	table_varchar,
		order_item_dt_due_dt	table_timestamp,

		--
		do_log					varchar2(1 char),


	--CONSTRUCTOR
		constructor function t_cls_pha_order
		(
			i_lang				in	number,
			i_id_market			in	number,
			i_id_institution	in	number,
			i_id_patient		in	number,
			i_id_prof_presc		in	number,
			i_id_prof_order		in	number,
			i_prof_presc_name	in	varchar2 default null,
			i_prof_order_name	in	varchar2 default null,
			i_id_software		in	number default 20 --PHARMACY
		)
		return self as result,

	--METHODS
		member procedure checkPatient,

		member procedure setPatName
		(
			i_pat_name	in	varchar2
		),

		member procedure setPatGender
		(
			i_pat_gender	in	varchar2
		),

		member procedure setPatLocation
		(
			i_pat_department	in	number,
			i_pat_ward			in	number,
			i_pat_specialty		in	number
		),

		--PROFS
		member procedure checkProf
		(
			i_id_prof		in	number,
			o_id_pha_prof	out	number,
			o_is_known		out	varchar2,
			o_prof_name		out	varchar2
		),

		--ORDER
		member procedure setOrderInfo
		(
			i_order_type	in	varchar2,
			i_presc_dt		in	timestamp with local time zone,
			i_request_dt	in	timestamp with local time zone default null,
			i_visit_id		in	number,
			i_episode_id	in	number
		),

		member procedure setOrderExtraInfo
		(
			i_therapeutic_proto	in	number,
			i_department_id		in	number,
			i_service_id		in	number,
			i_room_id			in	number,
			i_bed_id			in	number
		),

		member procedure setOrderItem
		(
			i_product		in	varchar2,
			i_supplier		in	varchar2,
			i_presc_id		in	number,
			i_instr_id		in	number,
			i_flg_generic	in	varchar2 default 'N',
			i_produc_desc	in	varchar2 default null,
			i_instr_desc	in	varchar2 default null,
			i_dt_due_date	in	timestamp with local time zone default null,
			i_flg_urgent	in	varchar2 default 'N'
		),

		member procedure setOrderItemQt
		(
			i_quantity	in	number,
			i_unit		in	number
		),

		--SUBMIT
		member procedure submit

);
/


create or replace type body t_cls_pha_order is

	/*
	 * @author		Rui Marante
	 * @since		2011-02-10
	 * @version		ZANOB 0.1
	 * @notes		
	*/


	--CONSTRUCTOR
		constructor function t_cls_pha_order
		(
			i_lang				in	number,
			i_id_market			in	number,
			i_id_institution	in	number,
			i_id_patient		in	number,
			i_id_prof_presc		in	number,
			i_id_prof_order		in	number,
			i_prof_presc_name	in	varchar2 default null,
			i_prof_order_name	in	varchar2 default null,
			i_id_software		in	number default 20 --PHARMACY
		)
		return self as result
		is
		begin
			self.class_name				:= 'T_CLS_PHA_ORDER';
			self.G_FLG_PFH				:= 'ALERT_PFH';
			--
			--get db-link for remote pharmacy (if null then pharmacy is local (with PFH))
			self.db_link				:= pk_sysconfig.get_config(
												i_code_cf	=> 'PHA__PHARMACY_REMOTE_DB_LINK', 
												i_prof		=> t_rec_pha_prof(id => null, institution => i_id_institution, software => 20));

			self.lang					:= i_lang;
			self.market_id				:= i_id_market;
			self.inst_id				:= i_id_institution;
			self.software_id			:= i_id_software;

			self.pat_is_known			:= 'N';
			self.pat_id_pha				:= null;
			self.pat_id					:= i_id_patient;

			self.prof_presc_is_known	:= 'N';
			self.prof_presc_id_pha		:= null;
			self.prof_presc_id			:= i_id_prof_presc;

			self.prof_order_is_known	:= 'N';
			self.prof_order_id_pha		:= null;
			self.prof_order_id			:= i_id_prof_order;
			--

			self.do_log					:= 'N'; --not in use TBD: LOG!!

			--order items collections
			self.order_item_count		:= 0;
			self.order_item_presc_id	:= table_number();
			self.order_item_qt			:= table_number();
			self.order_item_qt_unit		:= table_number();
			self.order_item_instr		:= table_number();
			self.order_item_flg_generic	:= table_varchar();
			self.order_item_product		:= table_varchar();
			self.order_item_supplier	:= table_varchar();
			self.order_item_prod_desc	:= table_varchar();
			self.order_item_instr_desc	:= table_varchar();
			self.order_item_dt_due_dt	:= table_timestamp();

			--checks
			self.checkPatient;

			self.checkProf(
					i_id_prof		=> self.prof_presc_id, 
					o_id_pha_prof	=> self.prof_presc_id_pha, 
					o_is_known		=> self.prof_presc_is_known,
					o_prof_name		=> self.prof_presc_name);

			if (self.prof_presc_id != self.prof_order_id) then
				self.checkProf(
						i_id_prof		=> self.prof_order_id, 
						o_id_pha_prof	=> self.prof_order_id_pha, 
						o_is_known		=> self.prof_order_is_known,
						o_prof_name		=> self.prof_order_name);
			else
				self.prof_order_is_known	:= self.prof_presc_is_known;
				self.prof_order_id_pha		:= self.prof_presc_id_pha;
				self.prof_order_name		:= self.prof_presc_name;
			end if;

			if (self.prof_presc_is_known = 'N') then
				self.prof_presc_name := i_prof_presc_name;
			end if;

			if (self.prof_order_is_known = 'N') then
				self.prof_order_name := i_prof_order_name;
			end if;

			return;
		end;

	--METHODS
		--PATIENT
		member procedure checkPatient
		is
			l_sql	varchar2(2000 char);
		begin
			l_sql := 
				'begin pk_pha_core.pat_check_existence' || self.db_link
				|| '('
				|| ' i_id_patient		=> :i_id_patient,'
				|| ' i_id_institution	=> :i_id_institution,'
				|| ' i_flg_type			=> :i_flg_type,'
				|| ' o_id_pha_patient	=> :o_id_pha_patient,'
				|| ' o_pat_name			=> :o_pat_name'
				|| '); end;';

			execute immediate l_sql
			using 
				in self.pat_id, in self.inst_id, in self.G_FLG_PFH, 
				out self.pat_id_pha, out self.pat_name;

			if (self.pat_id_pha is not null) then
				self.pat_is_known := 'Y';
			else
				self.pat_is_known := 'N';
			end if;

		end checkPatient;

		member procedure setPatName
		(
			i_pat_name	in	varchar2
		)
		is
		begin
			self.pat_name := i_pat_name;
		end setPatName;

		member procedure setPatGender
		(
			i_pat_gender	in	varchar2
		)
		is
		begin
			self.pat_gender := i_pat_gender;
		end setPatGender;

		member procedure setPatLocation
		(
			i_pat_department	in	number,
			i_pat_ward			in	number,
			i_pat_specialty		in	number
		)
		is
		begin
			self.pat_id_department	:= i_pat_department;
			self.pat_id_ward		:= i_pat_ward;
			self.pat_id_specialty	:= i_pat_specialty;
		end setPatLocation;

		--PROFS
		member procedure checkProf
		(
			i_id_prof		in	number,
			o_id_pha_prof	out	number,
			o_is_known		out	varchar2,
			o_prof_name		out	varchar2
		)
		is
			l_sql	varchar2(2000 char);
		begin
			l_sql := 
				'begin pk_pha_core.prof_check_existence' || self.db_link
				|| '('
				|| ' i_id_professional	=> :i_id_professional,'
				|| ' i_id_institution	=> :i_id_institution,'
				|| ' i_flg_type			=> :i_flg_type,'
				|| ' o_id_pha_prof		=> :o_id_pha_prof,'
				|| ' o_prof_name		=> :o_prof_name'
				|| '); end;';

			execute immediate l_sql
			using 
				in i_id_prof, in self.inst_id, in self.G_FLG_PFH, 
				out o_id_pha_prof, out o_prof_name;

			if (o_id_pha_prof is not null) then
				o_is_known := 'Y';
			else
				o_is_known := 'N';
			end if;

		end checkProf;


		--ORDER
		member procedure setOrderInfo
		(
			i_order_type	in	varchar2,
			i_presc_dt		in	timestamp with local time zone,
			i_request_dt	in	timestamp with local time zone default null,
			i_visit_id		in	number,
			i_episode_id	in	number
		)
		is
		begin
			self.order_type			:= i_order_type;
			self.order_presc_dt		:= i_presc_dt;
			self.order_request_dt	:= nvl(i_request_dt, current_timestamp);
			self.order_visit_id		:= i_visit_id;
			self.order_episode_id	:= i_episode_id;
		end setOrderInfo;

		member procedure setOrderExtraInfo
		(
			i_therapeutic_proto	in	number,
			i_department_id		in	number,
			i_service_id		in	number,
			i_room_id			in	number,
			i_bed_id			in	number
		)
		is
		begin
			self.order_therapproto		:= i_therapeutic_proto;
			self.order_department_id	:= i_department_id;
			self.order_service_id		:= i_service_id;
			self.order_room_id			:= i_room_id;
			self.order_bed_id			:= i_bed_id;
		end setOrderExtraInfo;

		--ORDER ITEMS
		member procedure setOrderItem
		(
			i_product		in	varchar2,
			i_supplier		in	varchar2,
			i_presc_id		in	number,
			i_instr_id		in	number,
			i_flg_generic	in	varchar2 default 'N',
			i_produc_desc	in	varchar2 default null,
			i_instr_desc	in	varchar2 default null,
			i_dt_due_date	in	timestamp with local time zone default null,
			i_flg_urgent	in	varchar2 default 'N'
		)
		is
		begin
			self.order_item_count := self.order_item_count + 1;
			--extend
			self.order_item_presc_id.extend(1);
			self.order_item_qt.extend(1);
			self.order_item_qt_unit.extend(1);
			self.order_item_instr.extend(1);
			self.order_item_flg_generic.extend(1);
			self.order_item_product.extend(1);
			self.order_item_supplier.extend(1);
			self.order_item_prod_desc.extend(1);
			self.order_item_instr_desc.extend(1);
			self.order_item_dt_due_dt.extend(1);

			--set values
			self.order_item_presc_id(self.order_item_count)		:= i_presc_id;
			self.order_item_instr(self.order_item_count)		:= i_instr_id;
			self.order_item_flg_generic(self.order_item_count)	:= i_flg_generic;
			self.order_item_product(self.order_item_count)		:= i_product;
			self.order_item_supplier(self.order_item_count)		:= i_supplier;
			self.order_item_prod_desc(self.order_item_count)	:= nvl(i_produc_desc, pk_api_product.get_product_desc(i_lang => self.lang, i_prof => t_rec_pha_prof(self.prof_presc_id, self.inst_id, self.software_id), i_id_product => i_product, i_id_product_supplier => i_supplier));
			self.order_item_instr_desc(self.order_item_count)	:= nvl(i_instr_desc, pk_api_presc_med.get_presc_directions_str(i_lang => self.lang, i_prof => t_rec_pha_prof(self.prof_presc_id, self.inst_id, self.software_id), i_id_presc => i_presc_id));

			if (i_flg_urgent = 'Y') then
				self.order_item_dt_due_dt(self.order_item_count):= current_timestamp;
			else
				self.order_item_dt_due_dt(self.order_item_count):= i_dt_due_date;
			end if;
		end setOrderItem;

		member procedure setOrderItemQt
		(
			i_quantity	in	number,
			i_unit		in	number
		)
		is
		begin
			self.order_item_qt(self.order_item_count)		:= i_quantity;
			self.order_item_qt_unit(self.order_item_count)	:= i_unit;
		end setOrderItemQt;


		--SUBMIT
		member procedure submit
		is
			l_id_order				number(24);
			l_id_workflow			number(24);
			l_id_state				number(24);
			l_id_order_item			number(24);
			l_id_order_time_line	number(24);
			--
			l_sql					varchar2(2000 char);
			l_id_history_block		number(24);
			l_id_history			number(24);
			l_table_name			varchar2(100 char);
		begin

			if (self.prof_order_is_known = 'N') then
				l_sql := 
					'begin pk_pha_core.prof_create' || self.db_link
					|| '('
					|| ' i_lang					=> :i_lang,'
					|| ' i_id_professional		=> :i_id_professional,'
					|| ' i_id_institution		=> :i_id_institution,'
					|| ' i_flg_type				=> :i_flg_type,'
					|| ' i_professional_name	=> :i_professional_name,'
					|| ' o_id_pha_prof			=> :o_id_pha_prof'
					|| '); end;';

				execute immediate l_sql
				using 
					in self.lang, in self.prof_order_id, in self.inst_id, in self.G_FLG_PFH, in self.prof_order_name,
					out self.prof_order_id_pha;

				self.prof_order_is_known := 'Y';
			end if;

			if (self.prof_presc_is_known = 'N') then
				l_sql := 
					'begin pk_pha_core.prof_create' || self.db_link
					|| '('
					|| ' i_lang					=> :i_lang,'
					|| ' i_id_professional		=> :i_id_professional,'
					|| ' i_id_institution		=> :i_id_institution,'
					|| ' i_flg_type				=> :i_flg_type,'
					|| ' i_professional_name	=> :i_professional_name,'
					|| ' o_id_pha_prof			=> :o_id_pha_prof'
					|| '); end;';

				execute immediate l_sql
				using 
					in self.lang, in self.prof_presc_id, in self.inst_id, in self.G_FLG_PFH, in self.prof_presc_name,
					out self.prof_presc_id_pha;

				self.prof_presc_is_known := 'Y';
			end if;

			if (self.pat_is_known = 'N') then
				l_sql := 
					'begin pk_pha_core.pat_create' || self.db_link
					|| '('
					|| ' i_lang					=> :i_lang,'
					|| ' i_pha_prof_creator		=> :i_pha_prof_creator,'
					|| ' i_id_patient			=> :i_id_patient,'
					|| ' i_id_institution		=> :i_id_institution,'
					|| ' i_flg_type				=> :i_flg_type,'
					|| ' i_patient_name			=> :i_patient_name,'
					|| ' i_patient_gender		=> :i_patient_gender,'
					|| ' i_patient_department	=> :i_patient_department,'
					|| ' i_patient_ward			=> :i_patient_ward,'
					|| ' i_patient_specialty	=> :i_patient_specialty,'
					|| ' o_id_pha_patient		=> :o_id_pha_patient'
					|| '); end;';

				execute immediate l_sql
				using 
					in self.lang, 
					in self.prof_order_id_pha, 
					in self.pat_id, 
					in self.inst_id, 
					in self.G_FLG_PFH, 
					in self.pat_name, 
					in self.pat_gender, 
					in self.pat_id_department, 
					in self.pat_id_ward, 
					in self.pat_id_specialty,
					--
					out self.pat_id_pha;
			end if;


			--HISTORY
			l_table_name := 'PHA_ORDER';
			
			l_sql :=
				'begin pk_pha_core.history_init_hist' || self.db_link
				|| '('
				|| ' i_lang					=> :i_lang,'
				|| ' i_id_pha_prof			=> :i_id_pha_prof,'
				|| ' i_dt_history			=> :i_dt_history,'
				|| ' o_id_history			=> :o_id_history,'
				|| ' io_table_name			=> :io_table_name,'
				|| ' io_id_history_block	=> :io_id_history_block'
				|| '); end;';

			execute immediate l_sql
			using
				in self.lang,
				in self.prof_order_id_pha,
				--
				in self.order_request_dt,
				out l_id_history,
				in out l_table_name,
				in out l_id_history_block;

			--ORDER
			l_sql :=
				'begin pk_pha_core.order_create' || self.db_link
				|| '('
				|| ' i_lang						=> :i_lang,'
				|| ' i_id_pha_prof				=> :i_id_pha_prof,'
				|| ' i_id_pha_patient			=> :i_id_pha_patient,'
				|| ' i_id_institution			=> :i_id_institution,'
				|| ' i_flg_order_type			=> :i_flg_order_type,'
				|| ' i_id_pha_prof_creator		=> :i_id_pha_prof_creator,'
				|| ' i_dt_creation				=> :i_dt_creation,'
				|| ' i_id_pha_prof_prescriber	=> :i_id_pha_prof_prescriber,'
				|| ' i_dt_prescription			=> :i_dt_prescription,'
				|| ' i_id_episode				=> :i_id_episode,'
				|| ' i_id_therapeutic_proto		=> :i_id_therapeutic_proto,'
				|| ' i_id_department			=> :i_id_department,'
				|| ' i_id_clinical_service		=> :i_id_clinical_service,'
				|| ' i_id_room					=> :i_id_room,'
				|| ' i_id_bed					=> :i_id_bed,'
				|| ' i_id_history_block			=> :i_id_history_block,'
				|| ' o_id_order					=> :o_id_order'
				|| '); end;';

			execute immediate l_sql
			using 
				in self.lang, 
				in self.prof_order_id_pha, 
				in self.pat_id_pha, 
				in self.inst_id, 
				in self.order_type, 
				in self.prof_order_id_pha, 
				in self.order_request_dt, 
				in self.prof_presc_id_pha, 
				in self.order_presc_dt, 
				in self.order_episode_id, 
				in self.order_therapproto, 
				in self.order_department_id, 
				in self.order_service_id, 
				in self.order_room_id, 
				in self.order_bed_id, 
				in l_id_history_block,
				--
				out l_id_order;

			--HISTORY UPDATE
			l_sql :=
				'begin pk_pha_core.history_update_field_table' || self.db_link
				|| '('
				|| 'i_id_history	=> :i_id_history,'
				|| 'i_table_name	=> :i_table_name,'
				|| 'i_id_field		=> :i_id_field'
				|| '); end;';

			execute immediate l_sql
			using 
				in l_id_history, 
				in l_table_name,				
				in l_id_order;

			--ORDER ITEMS
			for i in 1 .. self.order_item_count
			loop

				--GET_WORKFLOW_BY_RULE
				l_sql :=
					'begin pk_pha_wfl.get_workflow_by_rule' || self.db_link
					|| '('
					|| ' i_id_market		=> :i_id_market,'
					|| ' i_id_institution	=> :i_id_institution,'
					|| ' i_rule_context		=> :i_rule_context,'
					|| ' i_bind_name		=> :i_bind_name,'  -- *! BIND_NAME
					|| ' i_bind_value		=> :i_bind_value,' -- *! BIND_VALUE
					|| ' o_id_workflow		=> :o_id_workflow,'
					|| ' o_id_state			=> :o_id_state'
					|| '); end;';

				execute immediate l_sql
				using
					in self.market_id, 
					in self.inst_id, 
					in 'PRESC_CREATE',
					--*** isto permite criar regras (WFL_RULE) baseadas na prescricao!
					in 'id_presc_det', 
					in self.order_item_presc_id(i),
					--***
					out l_id_workflow, 
					out l_id_state;

			--HISTORY
			l_table_name := 'PHA_ORDER_ITEM';
			
			l_sql :=
				'begin pk_pha_core.history_init_hist' || self.db_link
				|| '('
				|| ' i_lang					=> :i_lang,'
				|| ' i_id_pha_prof			=> :i_id_pha_prof,'
				|| ' i_dt_history			=> :i_dt_history,'
				|| ' o_id_history			=> :o_id_history,'
				|| ' io_table_name			=> :io_table_name,'
				|| ' io_id_history_block	=> :io_id_history_block'
				|| '); end;';

			execute immediate l_sql
			using
				in self.lang,
				in self.prof_order_id_pha,
				--
				in self.order_request_dt,
				out l_id_history,
				in out l_table_name,
				in out l_id_history_block;

				--PK_PHA_CORE.ORDER_ITEM_CREATE
				l_sql :=
					'begin pk_pha_core.order_item_create' || self.db_link
					|| '('
					|| ' i_lang					=> :i_lang,'
					|| ' i_id_pha_prof_creator	=> :i_id_pha_prof_creator,'
					|| ' i_id_order				=> :i_id_order,'
					|| ' i_id_presc_det			=> :i_id_presc_det,'
					|| ' i_dt_due_date			=> :i_dt_due_date,'
					|| ' i_qt_ordered			=> :i_qt_ordered,'
					|| ' i_id_unit_ordered		=> :i_id_unit_ordered,'
					|| ' i_flg_generic			=> :i_flg_generic,'
					|| ' i_id_workflow			=> :i_id_workflow,'
					|| ' i_id_state				=> :i_id_state,'
					|| ' i_id_history_block		=> :i_id_history_block,'
					|| ' o_id_order_item		=> :o_id_order_item,'
					|| ' o_id_order_time_line	=> :o_id_order_time_line'
					|| '); end;';

				execute immediate l_sql
				using 
					in self.lang, 
					in self.prof_order_id_pha, 
					in l_id_order, 
					in self.order_item_presc_id(i), 
					in self.order_item_dt_due_dt(i), 
					in self.order_item_qt(i), 
					in self.order_item_qt_unit(i), 
					in self.order_item_flg_generic(i), 
					in l_id_workflow, 
					in l_id_state,
					in l_id_history_block,
					--
					out l_id_order_item, 
					out l_id_order_time_line;

				--PK_PHA_CORE.PRODUCT_CREATE
				l_sql :=
					'begin pk_pha_core.product_create' || self.db_link
					|| '('
					|| ' i_lang					=> :i_lang,'
					|| ' i_id_pha_prof_creator	=> :i_id_pha_prof_creator,'
					|| ' i_id_order_time_line	=> :i_id_order_time_line,'
					|| ' i_id_order_item		=> :i_id_order_item,'
					|| ' i_id_product			=> :i_id_product,'
					|| ' i_id_product_supplier	=> :i_id_product_supplier,'
					|| ' i_id_instructions		=> :i_id_instructions,'
					|| ' i_desc_product			=> :i_desc_product,'
					|| ' i_desc_instructions	=> :i_desc_instructions'
					|| '); end;';

				execute immediate l_sql
				using
					in self.lang, 
					in self.prof_order_id_pha, 
					in l_id_order_time_line, 
					in l_id_order_item, 
					in self.order_item_product(i), 
					in self.order_item_supplier(i), 
					in self.order_item_instr(i), 
					in self.order_item_prod_desc(i), 
					in self.order_item_instr_desc(i);


			--HISTORY UPDATE
			l_sql :=
				'begin pk_pha_core.history_update_field_table' || self.db_link
				|| '('
				|| 'i_id_history	=> :i_id_history,'
				|| 'i_table_name	=> :i_table_name,'
				|| 'i_id_field		=> :i_id_field'
				|| '); end;';

			execute immediate l_sql
			using 
				in l_id_history, 
				in l_table_name,				
				in l_id_order_item;

				--HISTORY RESET
				l_sql :=
					'begin pk_pha_core.history_clear_hist_id' || self.db_link
					|| '('
					|| ' i_lang				=> :i_lang,'
					|| ' i_id_pha_prof		=> :i_id_pha_prof,'
					|| ' i_id_order			=> :i_id_order,'
					|| ' i_id_order_item	=> :i_id_order_item'
					|| '); end;';

				execute immediate l_sql
				using
					in self.lang,
					in self.prof_order_id_pha,
					in l_id_order,
					in l_id_order_item;

			end loop;

		end submit;
end;
/
